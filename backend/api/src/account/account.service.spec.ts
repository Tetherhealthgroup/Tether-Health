import { Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { UserSupabaseClientFactory } from "../enrolments/user-supabase-client";
import {
  AccountService,
  DELETION_SIGN_IN_MARGIN_SECONDS,
} from "./account.service";

jest.mock("@supabase/supabase-js", () => ({ createClient: jest.fn() }));

const mockedCreateClient = jest.mocked(createClient);
const userId = "00000000-0000-4000-8000-000000000001";
const user = (authenticatedAt: number): AuthUser => ({
  id: userId,
  accessToken: "caller-token",
  authenticatedAt,
});
const recentUser = (): AuthUser => user(Math.floor(Date.now() / 1000));
const config = {
  getOrThrow: jest.fn((key: string) => {
    if (key === "SUPABASE_URL") return "https://project.supabase.co";
    if (key === "SUPABASE_ANON_KEY") return "publishable-placeholder-key";
    if (key === "RECENT_AUTH_MAX_AGE_SECONDS") return 600;
    throw new Error(`Unexpected config key ${key}`);
  }),
} as unknown as ConfigService;
const newService = () =>
  new AccountService(config, new UserSupabaseClientFactory(config));

type RpcResult = { data: unknown; error: unknown };
const COUNTS = { profiles: 1, quit_plans: 1, program_data: 2 };
const ALL_COUNTS = {
  ...COUNTS,
  enrolments: 2,
  programme_consents: 3,
  account_consents: 0,
  sync_answers: 0,
  sync_lapses: 0,
  sync_areas: 0,
  sync_accounts: 0,
};
const ZERO_COUNTS = Object.fromEntries(
  Object.keys(ALL_COUNTS).map((key) => [key, 0]),
);
const dbError = (code: string, message = "Synthetic database message") => ({
  code,
  message,
  details: null,
  hint: "synthetic_hint",
});

/**
 * A member-scoped client whose RPCs answer from `answers` (by function name,
 * in call order) and whose avatar bucket holds `avatarPaths`.
 */
function memberClient(
  answers: Record<string, RpcResult[]>,
  avatarPaths: string[] = [],
) {
  const rpc = jest.fn((name: string) => {
    const next = answers[name]?.shift();
    return Promise.resolve(
      next ?? { data: null, error: dbError("PGRST202", "unknown function") },
    );
  });
  const listV2 = jest.fn(() =>
    Promise.resolve({
      data: {
        objects: avatarPaths.map((key) => ({ key, name: key })),
        folders: [],
        hasNext: false,
      },
      error: null,
    }),
  );
  const remove = jest.fn((paths: string[]) =>
    Promise.resolve({ data: paths.map((name) => ({ name })), error: null }),
  );
  const storageFrom = jest.fn(() => ({ listV2, remove }));
  mockedCreateClient.mockReturnValue({
    rpc,
    storage: { from: storageFrom },
  } as never);
  return { rpc, listV2, remove, storageFrom };
}
const begun = (): RpcResult => ({ data: true, error: null });
const deleted = (counts: unknown = ALL_COUNTS): RpcResult => ({
  data: counts,
  error: null,
});
const failed = (code: string, message?: string): RpcResult => ({
  data: null,
  error: dbError(code, message),
});

describe("AccountService", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("rejects export when authentication is not recent", async () => {
    await expect(newService().export(user(1))).rejects.toMatchObject({
      status: 401,
    });
    expect(mockedCreateClient).not.toHaveBeenCalled();
  });

  it("rejects deletion before any database or storage call when authentication is stale", async () => {
    await expect(
      newService().deleteData(user(1), "DELETE"),
    ).rejects.toMatchObject({ status: 401 });

    expect(mockedCreateClient).not.toHaveBeenCalled();
  });

  it("exports only caller-scoped profile, quit-plan, and program rows", async () => {
    const profileSingle = jest.fn().mockResolvedValue({
      data: { id: userId, display_name: "Alex" },
      error: null,
    });
    const planSingle = jest.fn().mockResolvedValue({
      data: { user_id: userId, readiness_path: "prepare" },
      error: null,
    });
    const profileEq = jest.fn().mockReturnValue({ single: profileSingle });
    const planEq = jest.fn().mockReturnValue({ maybeSingle: planSingle });
    const programReturns = jest.fn().mockResolvedValue({
      data: [{ program_id: "steady", payload: {}, revision: 1 }],
      error: null,
    });
    const profileSelect = jest.fn().mockReturnValue({ eq: profileEq });
    const programEq = jest.fn().mockReturnValue({ returns: programReturns });
    const from = jest
      .fn()
      .mockReturnValueOnce({ select: profileSelect })
      .mockReturnValueOnce({ select: () => ({ eq: planEq }) })
      .mockReturnValueOnce({ select: () => ({ eq: programEq }) });
    mockedCreateClient.mockReturnValue({ from } as never);

    const result = await newService().export(recentUser());
    expect(result).toMatchObject({
      schemaVersion: "1.0",
      profile: { display_name: "Alex" },
      quitPlan: { readiness_path: "prepare" },
      programData: [{ programId: "steady", revision: 1 }],
    });
    expect(profileEq).toHaveBeenCalledWith("id", userId);
    expect(planEq).toHaveBeenCalledWith("user_id", userId);
    expect(programEq).toHaveBeenCalledWith("user_id", userId);
    expect(profileSelect).toHaveBeenCalledWith(
      "id,display_name,locale,time_zone,onboarding_completed,avatar_path,created_at,updated_at",
    );
  });

  it("deletes with the member's token: barrier, then avatars, then delete_my_account", async () => {
    const avatarPaths = [`${userId}/avatar`, `${userId}/history/1.webp`];
    const { rpc, listV2, remove, storageFrom } = memberClient(
      {
        begin_account_deletion: [begun()],
        delete_my_account: [deleted()],
      },
      [...avatarPaths, `${userId}/history/2.webp`],
    );

    const result = await newService().deleteData(recentUser(), "DELETE");

    expect(mockedCreateClient).toHaveBeenCalledTimes(1);
    expect(mockedCreateClient).toHaveBeenCalledWith(
      "https://project.supabase.co",
      "publishable-placeholder-key",
      {
        global: { headers: { Authorization: "Bearer caller-token" } },
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );
    expect(rpc.mock.calls).toEqual([
      ["begin_account_deletion", { p_confirmation: "DELETE" }],
      ["delete_my_account", { p_confirmation: "DELETE" }],
    ]);
    expect(storageFrom).toHaveBeenCalledWith("avatars");
    expect(listV2).toHaveBeenCalledWith(
      expect.objectContaining({ prefix: `${userId}/` }),
    );
    expect(remove).toHaveBeenCalledTimes(1);
    const [beginOrder, accountOrder] = rpc.mock.invocationCallOrder as [
      number,
      number,
    ];
    expect(beginOrder).toBeLessThan(listV2.mock.invocationCallOrder[0]!);
    expect(remove.mock.invocationCallOrder[0]).toBeLessThan(accountOrder);
    expect(result).toEqual({
      requestId: expect.stringMatching(/^[0-9a-f-]{36}$/) as unknown,
      completedAt: expect.any(String) as unknown,
      deleted: {
        profiles: 1,
        quitPlans: 1,
        avatarObjects: 3,
        programData: 2,
      },
      authIdentityDeleted: true,
      authIdentityStatus: "deleted",
    });
  });

  it("maps TH017 from begin_account_deletion to 401 before any storage call or further RPC", async () => {
    const { rpc, storageFrom } = memberClient({
      begin_account_deletion: [failed("TH017")],
    });

    await expect(
      newService().deleteData(recentUser(), "DELETE"),
    ).rejects.toMatchObject({
      status: 401,
      message: "Recent authentication is required",
    });
    expect(rpc).toHaveBeenCalledTimes(1);
    expect(storageFrom).not.toHaveBeenCalled();
  });

  it("maps TH017 from delete_my_account to 401", async () => {
    const { rpc } = memberClient({
      begin_account_deletion: [begun()],
      delete_my_account: [failed("TH017")],
    });

    await expect(
      newService().deleteData(recentUser(), "DELETE"),
    ).rejects.toMatchObject({
      status: 401,
      message: "Recent authentication is required",
    });
    expect(rpc).toHaveBeenCalledTimes(2);
  });

  it.each([
    ["TH016", "avatar objects remain"],
    ["TH020", "the function owner does not bypass row-level security"],
    ["TH018", "the identity was not deleted"],
    ["TH010", "a sync session"],
    ["23514", "deletion was not started"],
    ["42501", "no caller"],
    ["PGRST202", "the function is missing"],
    ["", "a transport failure"],
  ])(
    "fails closed with 502 when delete_my_account raises %p (%s)",
    async (code) => {
      const { rpc } = memberClient({
        begin_account_deletion: [begun()],
        delete_my_account: [failed(code)],
      });

      await expect(
        newService().deleteData(recentUser(), "DELETE"),
      ).rejects.toMatchObject({ status: 502 });
      expect(rpc).toHaveBeenCalledTimes(2);
    },
  );

  it.each([
    null,
    {},
    { profiles: 1, quit_plans: 1 },
    { ...COUNTS, profiles: -1 },
  ])(
    "fails closed with 502 when delete_my_account returns unusable counts %p",
    async (data) => {
      memberClient({
        begin_account_deletion: [begun()],
        delete_my_account: [deleted(data)],
      });

      await expect(
        newService().deleteData(recentUser(), "DELETE"),
      ).rejects.toMatchObject({ status: 502 });
    },
  );

  it("keeps the barrier and never calls delete_my_account when avatar cleanup fails", async () => {
    const { rpc, listV2 } = memberClient({
      begin_account_deletion: [begun()],
      delete_my_account: [deleted()],
    });
    listV2.mockResolvedValueOnce({
      data: null as never,
      error: { message: "storage unavailable" } as never,
    });

    await expect(
      newService().deleteData(recentUser(), "DELETE"),
    ).rejects.toMatchObject({ status: 502 });
    expect(rpc.mock.calls).toEqual([
      ["begin_account_deletion", { p_confirmation: "DELETE" }],
    ]);
  });

  it("does not touch storage when the write barrier cannot start", async () => {
    const { rpc, storageFrom } = memberClient({
      begin_account_deletion: [failed("08006", "database unavailable")],
    });

    await expect(
      newService().deleteData(recentUser(), "DELETE"),
    ).rejects.toMatchObject({ status: 502 });
    expect(rpc).toHaveBeenCalledTimes(1);
    expect(storageFrom).not.toHaveBeenCalled();
  });

  // TH009 is raised only in a sync service session, which the API never
  // uses; if it ever arrives it fails closed like any database error.
  it("fails closed without echoing the database when begin_account_deletion raises TH009", async () => {
    const { storageFrom } = memberClient({
      begin_account_deletion: [
        failed("TH009", "Account deletion goes through the API"),
      ],
    });

    const error: unknown = await newService()
      .deleteData(recentUser(), "DELETE")
      .catch((reason: unknown) => reason);
    expect(error).toMatchObject({ status: 502 });
    expect(JSON.stringify(error)).not.toContain("TH009");
    expect(JSON.stringify(error)).not.toContain("goes through the API");
    expect(storageFrom).not.toHaveBeenCalled();
  });

  it("safely retries after delete_my_account succeeds but its response is lost", async () => {
    const { rpc, remove } = memberClient({
      begin_account_deletion: [begun(), begun()],
      delete_my_account: [failed("", "fetch failed"), deleted(ZERO_COUNTS)],
    });

    await expect(
      newService().deleteData(recentUser(), "DELETE"),
    ).rejects.toMatchObject({ status: 502 });
    await expect(
      newService().deleteData(recentUser(), "DELETE"),
    ).resolves.toMatchObject({
      deleted: {
        profiles: 0,
        quitPlans: 0,
        avatarObjects: 0,
        programData: 0,
      },
      authIdentityDeleted: true,
      authIdentityStatus: "deleted",
    });
    expect(rpc.mock.calls.map(([name]) => name)).toEqual([
      "begin_account_deletion",
      "delete_my_account",
      "begin_account_deletion",
      "delete_my_account",
    ]);
    expect(remove).not.toHaveBeenCalled();
  });
});

describe("AccountService logging", () => {
  const SYNTHETIC_EMAIL = "synthetic.patient@example.test";
  const SYNTHETIC_NOTE = "SYNTHETIC-HEALTH-NOTE-7f3a";
  const FAILURE_LINE =
    /^account_deletion_failed requestId=[0-9a-f-]{36} status=[a-z_]+( code=([0-9A-Z]{5}|none))?$/;
  const methods = [
    "log",
    "error",
    "warn",
    "debug",
    "verbose",
    "fatal",
  ] as const;
  let spies: Record<(typeof methods)[number], jest.SpyInstance>;

  const captured = (): string =>
    JSON.stringify(methods.map((m): unknown[] => spies[m].mock.calls));
  const totalLogCalls = (): number =>
    methods.reduce((n, m) => n + spies[m].mock.calls.length, 0);
  const expectNoLeak = (): void => {
    for (const value of [
      userId,
      "caller-token",
      SYNTHETIC_EMAIL,
      SYNTHETIC_NOTE,
      "synthetic_hint",
    ]) {
      expect(captured()).not.toContain(value);
    }
  };
  const onlyErrorLine = (): string => {
    expect(spies.error).toHaveBeenCalledTimes(1);
    expect(spies.error.mock.calls[0]).toHaveLength(1);
    expect(totalLogCalls()).toBe(1);
    const [line] = spies.error.mock.calls[0] as [string];
    expect(line).toMatch(FAILURE_LINE);
    return line;
  };

  beforeEach(() => {
    jest.clearAllMocks();
    spies = Object.fromEntries(
      methods.map((m) => [
        m,
        jest.spyOn(Logger.prototype, m).mockImplementation(() => undefined),
      ]),
    ) as typeof spies;
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("logs only a request id and status when avatar cleanup fails", async () => {
    const { listV2 } = memberClient({ begin_account_deletion: [begun()] });
    listV2.mockRejectedValueOnce(
      new Error(`storage failed ${SYNTHETIC_EMAIL} ${SYNTHETIC_NOTE}`),
    );

    await expect(
      newService().deleteData(recentUser(), "DELETE"),
    ).rejects.toMatchObject({ status: 502 });

    expect(onlyErrorLine()).toMatch(/ status=avatar_cleanup_failed$/);
    expectNoLeak();
  });

  it.each([
    ["TH016", "avatar_objects_remain", "TH016"],
    ["TH020", "account_delete_failed", "TH020"],
    ["TH018", "account_delete_failed", "TH018"],
    ["23514", "account_delete_failed", "23514"],
    ["PGRST202", "account_delete_failed", "none"],
    ["", "account_delete_failed", "none"],
  ])(
    "logs only request id, status and SQLSTATE when delete_my_account raises %p",
    async (code, status, logged) => {
      memberClient({
        begin_account_deletion: [begun()],
        delete_my_account: [
          failed(code, `${SYNTHETIC_NOTE} ${SYNTHETIC_EMAIL} ${userId}`),
        ],
      });

      await expect(
        newService().deleteData(recentUser(), "DELETE"),
      ).rejects.toMatchObject({ status: 502 });

      expect(onlyErrorLine().endsWith(` status=${status} code=${logged}`)).toBe(
        true,
      );
      expectNoLeak();
    },
  );

  it("logs nothing for a refused recent sign-in", async () => {
    memberClient({
      begin_account_deletion: [begun()],
      delete_my_account: [failed("TH017", SYNTHETIC_NOTE)],
    });

    await expect(
      newService().deleteData(recentUser(), "DELETE"),
    ).rejects.toMatchObject({ status: 401 });

    expect(totalLogCalls()).toBe(0);
  });

  it("logs a single completion line without user id or token on success", async () => {
    memberClient({
      begin_account_deletion: [begun()],
      delete_my_account: [deleted()],
    });

    const result = await newService().deleteData(recentUser(), "DELETE");

    expect(spies.log.mock.calls).toEqual([
      [`account_deleted requestId=${result.requestId} status=completed`],
    ]);
    expect(totalLogCalls()).toBe(1);
    expectNoLeak();
  });

  it("makes no logger calls when exporting data", async () => {
    const profileSingle = jest.fn().mockResolvedValue({
      data: { id: userId, display_name: "Synthetic Name" },
      error: null,
    });
    const planSingle = jest.fn().mockResolvedValue({ data: null, error: null });
    const programReturns = jest.fn().mockResolvedValue({
      data: [
        {
          program_id: "steady",
          payload: { note: SYNTHETIC_NOTE },
          revision: 1,
        },
      ],
      error: null,
    });
    const from = jest
      .fn()
      .mockReturnValueOnce({
        select: () => ({ eq: () => ({ single: profileSingle }) }),
      })
      .mockReturnValueOnce({
        select: () => ({ eq: () => ({ maybeSingle: planSingle }) }),
      })
      .mockReturnValueOnce({
        select: () => ({ eq: () => ({ returns: programReturns }) }),
      });
    mockedCreateClient.mockReturnValue({ from } as never);

    await newService().export(recentUser());

    expect(totalLogCalls()).toBe(0);
  });
});

describe("AccountService recent sign-in", () => {
  // A whole second, so ages below are exact.
  const NOW_SECONDS = 1_800_000_000;
  const at = (ageSeconds: number) => {
    jest
      .spyOn(Date, "now")
      .mockReturnValue(Math.round((NOW_SECONDS + ageSeconds) * 1000));
    return user(NOW_SECONDS);
  };

  beforeEach(() => {
    jest.clearAllMocks();
    jest.spyOn(Logger.prototype, "error").mockImplementation(() => undefined);
    jest.spyOn(Logger.prototype, "log").mockImplementation(() => undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("deletion uses a 30-second margin below the configured maximum", () => {
    expect(DELETION_SIGN_IN_MARGIN_SECONDS).toBe(30);
  });

  it.each([569, 570])(
    "starts deletion for a sign-in %p seconds old (maximum minus the margin or less)",
    async (age) => {
      const { rpc } = memberClient({
        begin_account_deletion: [begun()],
        delete_my_account: [deleted()],
      });

      await expect(
        newService().deleteData(at(age), "DELETE"),
      ).resolves.toMatchObject({ authIdentityDeleted: true });
      expect(rpc).toHaveBeenCalledTimes(2);
    },
  );

  it.each([570.9, 571, 600])(
    "refuses deletion before any call for a sign-in %p seconds old",
    async (age) => {
      await expect(
        newService().deleteData(at(age), "DELETE"),
      ).rejects.toMatchObject({ status: 401 });
      expect(mockedCreateClient).not.toHaveBeenCalled();
    },
  );

  it.each([-3, -0.5])(
    "refuses deletion and export for a sign-in %p seconds in the future",
    async (age) => {
      await expect(
        newService().deleteData(at(age), "DELETE"),
      ).rejects.toMatchObject({ status: 401 });
      await expect(newService().export(at(age))).rejects.toMatchObject({
        status: 401,
      });
      expect(mockedCreateClient).not.toHaveBeenCalled();
    },
  );

  it("export allows the full configured maximum, to the fraction of a second", async () => {
    await expect(newService().export(at(600.5))).rejects.toMatchObject({
      status: 401,
    });
    expect(mockedCreateClient).not.toHaveBeenCalled();

    const single = jest.fn().mockResolvedValue({ data: {}, error: null });
    const maybeSingle = jest
      .fn()
      .mockResolvedValue({ data: null, error: null });
    const returns = jest.fn().mockResolvedValue({ data: [], error: null });
    mockedCreateClient.mockReturnValue({
      from: jest
        .fn()
        .mockReturnValueOnce({ select: () => ({ eq: () => ({ single }) }) })
        .mockReturnValueOnce({
          select: () => ({ eq: () => ({ maybeSingle }) }),
        })
        .mockReturnValueOnce({ select: () => ({ eq: () => ({ returns }) }) }),
    } as never);
    await expect(newService().export(at(600))).resolves.toMatchObject({
      schemaVersion: "1.0",
    });
  });
});

describe("AccountService begin_account_deletion failures", () => {
  let errors: jest.SpyInstance;

  beforeEach(() => {
    jest.clearAllMocks();
    errors = jest
      .spyOn(Logger.prototype, "error")
      .mockImplementation(() => undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it.each([
    ["no error and false", { data: false, error: null }],
    ["no error and null", { data: null, error: null }],
    ["no error and a non-boolean", { data: "true", error: null }],
  ])(
    "fails with 502 when begin returns %s, before storage or any further RPC",
    async (_, answer) => {
      const { rpc, storageFrom } = memberClient({
        begin_account_deletion: [answer],
        delete_my_account: [deleted()],
      });

      await expect(
        newService().deleteData(recentUser(), "DELETE"),
      ).rejects.toMatchObject({ status: 502 });
      expect(rpc).toHaveBeenCalledTimes(1);
      expect(storageFrom).not.toHaveBeenCalled();
      expect(errors.mock.calls).toEqual([
        [
          expect.stringMatching(
            /^account_deletion_failed requestId=[0-9a-f-]{36} status=begin_failed code=none$/,
          ),
        ],
      ]);
    },
  );

  it.each([
    ["08006", "08006"],
    ["TH009", "TH009"],
    ["PGRST202", "none"],
    ["", "none"],
  ])(
    "logs only request id, status and SQLSTATE when begin raises %p",
    async (code, logged) => {
      memberClient({
        begin_account_deletion: [
          failed(code, `SYNTHETIC-HEALTH-NOTE ${userId} caller-token`),
        ],
      });

      await expect(
        newService().deleteData(recentUser(), "DELETE"),
      ).rejects.toMatchObject({ status: 502 });
      expect(errors).toHaveBeenCalledTimes(1);
      const [line] = errors.mock.calls[0] as [string];
      expect(line).toMatch(
        new RegExp(
          `^account_deletion_failed requestId=[0-9a-f-]{36} status=begin_failed code=${logged}$`,
        ),
      );
      for (const leak of [
        "SYNTHETIC-HEALTH-NOTE",
        userId,
        "caller-token",
        "synthetic_hint",
      ]) {
        expect(JSON.stringify(errors.mock.calls)).not.toContain(leak);
      }
    },
  );
});
