import { BadGatewayException, HttpStatus, Logger } from "@nestjs/common";
import type { ConfigService } from "@nestjs/config";
import type { AuthUser } from "../auth/auth-user";
import { CodedHttpException } from "./enrolment-errors";
import { EnrolmentsService } from "./enrolments.service";
import type { UserSupabaseClientFactory } from "./user-supabase-client";

type Result = { data: unknown; error: unknown; count?: number | null };

/**
 * A chainable stand-in for one supabase-js query: every builder method
 * returns the chain, and awaiting it yields the next queued result.
 */
function chain(result: Result, calls: string[][]) {
  const target: Record<string, unknown> = {
    then: (resolve: (value: Result) => unknown) => resolve(result),
  };
  const proxy: unknown = new Proxy(target, {
    get(object, property: string) {
      if (property in object) return object[property];
      return (...args: unknown[]) => {
        calls.push([property, ...args.map((arg) => JSON.stringify(arg))]);
        return proxy;
      };
    },
  });
  return proxy;
}

function setup(...results: Result[]) {
  const calls: string[][] = [];
  const client = {
    from: jest.fn((table: string) => {
      calls.push(["from", table]);
      return chain(results.shift() ?? { data: null, error: null }, calls);
    }),
    rpc: jest.fn((name: string, ...args: unknown[]) => {
      calls.push(["rpc", name, ...args.map((arg) => JSON.stringify(arg))]);
      return chain(results.shift() ?? { data: null, error: null }, calls);
    }),
  };
  const forUser = jest.fn(() => client);
  const factory = { forUser } as unknown as UserSupabaseClientFactory;
  const config = {
    getOrThrow: jest.fn(() => 600),
  } as unknown as ConfigService;
  return { service: new EnrolmentsService(factory, config), calls, forUser };
}

const user: AuthUser = {
  id: "00000000-0000-4000-8000-0000000000a1",
  accessToken: "synthetic-access-token",
  authenticatedAt: 1700000000,
};
const ENROLMENT_ID = "00000000-0000-4000-8000-0000000000e1";
const OTHER_ID = "00000000-0000-4000-8000-0000000000e2";
const CORE_ID = "00000000-0000-4000-8000-0000000000c1";
const NEW_CORE_ID = "00000000-0000-4000-8000-0000000000c2";
/** current_consent_documents() filtered to core: the current core versions. */
const currentDocs = (en = "v2", es = "v2"): Result => ({
  data: [
    { purpose: "core", version: en, locale: "en" },
    { purpose: "core", version: es, locale: "es" },
  ],
  error: null,
});
/** deletion_barrier_open(): account deletion has not started. */
const barrierOpen: Result = { data: true, error: null };
const REQUEST_ID = "req-synthetic-1";
const consentRow = (overrides: Record<string, unknown> = {}) => ({
  id: CORE_ID,
  enrolment_id: ENROLMENT_ID,
  purpose: "core",
  recipient_ref: null,
  consent_version: "v1",
  locale: "en",
  consent_text: "Synthetic document text",
  granted_at: "2026-10-18T00:00:00.000Z",
  revoked_at: null,
  superseded_by: null,
  ...overrides,
});
const grantDto = (overrides: Record<string, unknown> = {}) => ({
  enrolmentId: ENROLMENT_ID,
  purpose: "core" as const,
  consentVersion: "v2",
  locale: "en" as const,
  ...overrides,
});
const enrolmentRow = (status = "focus") => ({
  id: ENROLMENT_ID,
  user_id: user.id,
  programme_code: "bf",
  status,
  mode: null,
  joined_at: "2026-10-18T00:00:00.000Z",
  left_at: status === "left" ? "2026-10-18T01:00:00.000Z" : null,
  created_at: "2026-10-18T00:00:00.000Z",
  updated_at: "2026-10-18T00:00:00.000Z",
});

async function codeOf(promise: Promise<unknown>) {
  const error = await promise.then(
    () => undefined,
    (reason: unknown) => reason,
  );
  if (error instanceof CodedHttpException) {
    return { status: error.getStatus(), code: error.code };
  }
  return error;
}

describe("EnrolmentsService", () => {
  it("acts as the caller and filters enrolments on the caller id", async () => {
    const { service, calls, forUser } = setup(
      currentDocs(),
      { data: [enrolmentRow()], error: null, count: 1 },
      { data: [], error: null, count: 0 },
    );
    await service.list(user);
    expect(forUser).toHaveBeenCalledWith(user);
    expect(calls).toContainEqual(["eq", '"user_id"', JSON.stringify(user.id)]);
  });

  it.each([
    [
      { code: "TH001", message: "synthetic", hint: "focus_cap_reached" },
      { status: HttpStatus.CONFLICT, code: "focus_cap_reached" },
    ],
    [
      { code: "23505", message: "duplicate key" },
      { status: HttpStatus.CONFLICT, code: "already_enrolled" },
    ],
    [
      { code: "23503", message: "foreign key" },
      { status: HttpStatus.NOT_FOUND, code: "programme_not_found" },
    ],
    [
      { code: "42501", message: "row-level security" },
      { status: HttpStatus.CONFLICT, code: "account_deletion_in_progress" },
    ],
  ])("maps create error %j", async (error, expected) => {
    const { service } = setup({ data: null, error });
    expect(
      await codeOf(
        service.create(user, { programmeCode: "bf", status: "focus" }),
      ),
    ).toEqual(expected);
  });

  it("reports unknown database errors as 502 without detail", async () => {
    const { service } = setup({
      data: null,
      error: { code: "XX000", message: "synthetic internal detail" },
    });
    const error = await codeOf(
      service.create(user, { programmeCode: "bf", status: "focus" }),
    );
    expect(error).toBeInstanceOf(BadGatewayException);
  });

  it.each([
    [
      { code: "TH001" },
      { status: HttpStatus.CONFLICT, code: "focus_cap_reached" },
    ],
    [
      { code: "23514" },
      { status: HttpStatus.CONFLICT, code: "enrolment_conflict" },
    ],
    [
      { code: "TH002" },
      { status: HttpStatus.CONFLICT, code: "enrolment_conflict" },
    ],
    [
      { code: "TH003" },
      { status: HttpStatus.CONFLICT, code: "enrolment_conflict" },
    ],
  ])("maps update error %j", async (error, expected) => {
    const { service } = setup(
      { data: enrolmentRow(), error: null },
      barrierOpen,
      currentDocs(),
      { data: null, error: { ...error, message: "synthetic" } },
    );
    expect(
      await codeOf(service.update(user, ENROLMENT_ID, { status: "paused" })),
    ).toEqual(expected);
  });

  it("maps revoke error TH002 to consent_already_revoked", async () => {
    const { service } = setup(
      { data: null, error: { code: "TH002", message: "synthetic" } },
      {
        data: consentRow({ revoked_at: "2026-10-18T01:00:00.000Z" }),
        error: null,
      },
    );
    expect(await codeOf(service.revokeConsent(user, "c1"))).toEqual({
      status: HttpStatus.CONFLICT,
      code: "consent_already_revoked",
    });
  });

  it("revokes only a live row (the update filters on revoked_at is null)", async () => {
    const { service, calls } = setup({ data: consentRow(), error: null });
    await service.revokeConsent(user, CORE_ID);
    const updateAt = calls.findIndex((call) => call[0] === "update");
    expect(updateAt).toBeGreaterThanOrEqual(0);
    expect(calls.slice(updateAt)).toEqual(
      expect.arrayContaining([
        ["eq", '"id"', JSON.stringify(CORE_ID)],
        ["is", '"revoked_at"', "null"],
      ]),
    );
  });

  // TH003 leaves the consent live: it must never be reported as revoked.
  it("does not report revoke error TH003 as revoked", async () => {
    const { service } = setup({
      data: null,
      error: { code: "TH003", message: "synthetic" },
    });
    expect(await codeOf(service.revokeConsent(user, "c1"))).toBeInstanceOf(
      BadGatewayException,
    );
  });

  // Message text and hint never decide: only the SQLSTATE code does.
  describe("does not match message text", () => {
    const capText = {
      message: "At most two programmes can be in focus",
      hint: "focus_cap_reached",
    };

    it.each(["23514", "P0001", "XX000"])(
      "create: focus-cap text under %s is not the focus cap",
      async (code) => {
        const { service } = setup({ data: null, error: { code, ...capText } });
        expect(
          await codeOf(
            service.create(user, { programmeCode: "bf", status: "focus" }),
          ),
        ).toBeInstanceOf(BadGatewayException);
      },
    );

    it("update: focus-cap text under 23514 is an ordinary check violation", async () => {
      const { service } = setup(
        { data: enrolmentRow(), error: null },
        barrierOpen,
        currentDocs(),
        { data: null, error: { code: "23514", ...capText } },
      );
      expect(
        await codeOf(service.update(user, ENROLMENT_ID, { status: "focus" })),
      ).toEqual({ status: HttpStatus.CONFLICT, code: "enrolment_conflict" });
    });

    it("revoke: already-revoked text under 23514 is not the revoke-only rule", async () => {
      const { service } = setup({
        data: null,
        error: {
          code: "23514",
          message: "Consent is already revoked",
          hint: "consent_already_revoked",
        },
      });
      expect(await codeOf(service.revokeConsent(user, "c1"))).toBeInstanceOf(
        BadGatewayException,
      );
    });
  });

  // Unmapped TH codes (including TH009/TH010, which a member session never
  // sees) fail closed on every route, with a fixed message.
  describe.each([
    "TH001",
    "TH002",
    "TH003",
    "TH007",
    "TH009",
    "TH010",
    "TH015",
    "TH999",
  ])("fails closed on %s where it is not mapped", (code) => {
    const error = { code, message: "synthetic detail", hint: "synthetic_hint" };
    const recent = () => ({
      ...user,
      authenticatedAt: Math.floor(Date.now() / 1000),
    });
    const expectHidden = (result: unknown) => {
      expect(result).toBeInstanceOf(BadGatewayException);
      const response = JSON.stringify(
        (result as BadGatewayException).getResponse(),
      );
      expect(response).not.toContain("synthetic");
      expect(response).not.toContain(code);
    };

    // The consent grant maps the database-function codes, TH001 included.
    if (code !== "TH001")
      it("grant consent", async () => {
        const { service } = setup(
          { data: enrolmentRow(), error: null },
          { data: null, error: null },
          { data: null, error },
        );
        expectHidden(await codeOf(service.grantConsent(user, grantDto())));
      });

    it("current consent documents (enrolment list)", async () => {
      const { service } = setup({ data: null, error });
      expectHidden(await codeOf(service.list(user)));
    });

    it("delete now", async () => {
      // Its failure log line (the code only) is tested on its own below.
      const quiet = jest
        .spyOn(Logger.prototype, "error")
        .mockImplementation(() => undefined);
      const { service } = setup({ data: null, error });
      expectHidden(
        await codeOf(
          service.deleteNow(recent(), ENROLMENT_ID, "DELETE", REQUEST_ID),
        ),
      );
      quiet.mockRestore();
    });

    if (!["TH001"].includes(code)) {
      it("create", async () => {
        const { service } = setup({ data: null, error });
        expectHidden(
          await codeOf(
            service.create(user, { programmeCode: "bf", status: "focus" }),
          ),
        );
      });
    }

    if (!["TH001", "TH002", "TH003"].includes(code)) {
      it("update", async () => {
        const { service } = setup(
          { data: enrolmentRow(), error: null },
          barrierOpen,
          currentDocs(),
          { data: null, error },
        );
        expectHidden(
          await codeOf(
            service.update(user, ENROLMENT_ID, { status: "paused" }),
          ),
        );
      });
    }

    if (code !== "TH002") {
      it("revoke consent", async () => {
        const { service } = setup({ data: null, error });
        expectHidden(await codeOf(service.revokeConsent(user, "c1")));
      });
    }
  });

  // The update policy refuses every enrolment change once account deletion
  // has started; the API asks the barrier first and changes nothing.
  describe("the deletion barrier before an enrolment change", () => {
    const changes: [string, string, Record<string, unknown>][] = [
      ["pause", "focus", { status: "paused" }],
      ["leave", "focus", { status: "left" }],
      ["rejoin", "left", { status: "focus" }],
      ["mode change", "focus", { mode: "reduce" }],
      ["mode cleared", "focus", { mode: null }],
    ];

    it.each(changes)(
      "%s: refused with account_deletion_in_progress, nothing written",
      async (_label, status, dto) => {
        const { service, calls } = setup(
          { data: enrolmentRow(status), error: null },
          { data: false, error: null },
        );
        expect(await codeOf(service.update(user, ENROLMENT_ID, dto))).toEqual({
          status: HttpStatus.CONFLICT,
          code: "account_deletion_in_progress",
        });
        expect(calls).toContainEqual(["rpc", "deletion_barrier_open"]);
        expect(calls.some((call) => call[0] === "update")).toBe(false);
      },
    );

    it.each(changes)(
      "%s: asked before the update when the barrier is open",
      async (_label, status, dto) => {
        const { service, calls } = setup(
          { data: enrolmentRow(status), error: null },
          barrierOpen,
          currentDocs(),
          { data: enrolmentRow("paused"), error: null },
          { data: [], error: null, count: 0 },
        );
        await service.update(user, ENROLMENT_ID, dto);
        const barrierAt = calls.findIndex(
          (call) => call[0] === "rpc" && call[1] === "deletion_barrier_open",
        );
        const updateAt = calls.findIndex((call) => call[0] === "update");
        expect(barrierAt).toBeGreaterThanOrEqual(0);
        expect(updateAt).toBeGreaterThan(barrierAt);
      },
    );

    it("fails closed when the barrier cannot be read", async () => {
      // Every later step would succeed, so only the barrier failure can
      // produce the 502.
      const { service, calls } = setup(
        { data: enrolmentRow(), error: null },
        { data: null, error: { code: "XX000", message: "synthetic detail" } },
        currentDocs(),
        { data: enrolmentRow("paused"), error: null },
        { data: [], error: null, count: 0 },
      );
      expect(
        await codeOf(service.update(user, ENROLMENT_ID, { status: "paused" })),
      ).toBeInstanceOf(BadGatewayException);
      expect(calls.at(-1)).toEqual(["rpc", "deletion_barrier_open"]);
      expect(calls.some((call) => call[0] === "update")).toBe(false);
    });

    it("focus swap: refused before any read or the swap", async () => {
      const { service, calls } = setup({ data: false, error: null });
      expect(
        await codeOf(
          service.swapFocus(user, {
            demoteId: ENROLMENT_ID,
            promoteId: OTHER_ID,
          }),
        ),
      ).toEqual({
        status: HttpStatus.CONFLICT,
        code: "account_deletion_in_progress",
      });
      expect(calls).toEqual([["rpc", "deletion_barrier_open"]]);
    });

    it("focus swap: fails closed when the barrier cannot be read", async () => {
      // Every later step would succeed, so only the barrier failure can
      // produce the 502.
      const { service, calls } = setup(
        { data: null, error: { code: "XX000", message: "synthetic detail" } },
        currentDocs(),
        { data: [], error: null, count: 0 },
        {
          data: [
            { ...enrolmentRow("paused"), id: ENROLMENT_ID },
            { ...enrolmentRow("focus"), id: OTHER_ID },
          ],
          error: null,
        },
      );
      expect(
        await codeOf(
          service.swapFocus(user, {
            demoteId: ENROLMENT_ID,
            promoteId: OTHER_ID,
          }),
        ),
      ).toBeInstanceOf(BadGatewayException);
      expect(calls).toEqual([["rpc", "deletion_barrier_open"]]);
    });
  });

  it("refuses a partial list (server row limit) instead of dropping rows", async () => {
    const { service } = setup(
      currentDocs(),
      { data: [enrolmentRow()], error: null, count: 1 },
      { data: [], error: null, count: 3 },
    );
    expect(await codeOf(service.list(user))).toBeInstanceOf(
      BadGatewayException,
    );
  });

  it("asks only for live consents", async () => {
    const { service, calls } = setup(
      currentDocs(),
      { data: [enrolmentRow()], error: null, count: 1 },
      { data: [], error: null, count: 0 },
    );
    await service.list(user);
    expect(calls).toContainEqual(["is", '"revoked_at"', "null"]);
  });

  it("delete now needs the confirmation and a recent sign-in", async () => {
    const recent = { ...user, authenticatedAt: Math.floor(Date.now() / 1000) };
    const wrong = setup();
    expect(
      await codeOf(
        wrong.service.deleteNow(recent, ENROLMENT_ID, "delete", REQUEST_ID),
      ),
    ).toEqual({
      status: HttpStatus.BAD_REQUEST,
      code: "confirmation_required",
    });
    const stale = setup();
    expect(
      await codeOf(
        stale.service.deleteNow(user, ENROLMENT_ID, "DELETE", REQUEST_ID),
      ),
    ).toEqual({
      status: HttpStatus.UNAUTHORIZED,
      code: "recent_authentication_required",
    });
    expect(wrong.calls).toEqual([]);
    expect(stale.calls).toEqual([]);
  });

  describe("delete now through delete_enrolment_now", () => {
    const recent = () => ({
      ...user,
      authenticatedAt: Math.floor(Date.now() / 1000),
    });
    let logged: string[];
    beforeEach(() => {
      logged = [];
      for (const level of ["log", "error", "warn", "debug", "verbose"] as const)
        jest
          .spyOn(Logger.prototype, level)
          .mockImplementation((...args: unknown[]) => {
            logged.push(JSON.stringify(args));
          });
    });
    afterEach(() => jest.restoreAllMocks());

    /** No user id, enrolment id, token or database text in any log line. */
    const expectNoIdentifiers = () => {
      const lines = logged.join("\n");
      for (const value of [
        user.id,
        ENROLMENT_ID,
        user.accessToken,
        "synthetic detail",
        "synthetic_hint",
        "bf",
      ]) {
        expect(lines).not.toContain(value);
      }
    };

    it("calls the function once as the caller, after its own checks, with no table write", async () => {
      const { service, calls, forUser } = setup({
        data: { enrolments: 1, programme_consents: 2 },
        error: null,
      });
      const caller = recent();
      await service.deleteNow(caller, ENROLMENT_ID, "DELETE", REQUEST_ID);
      expect(forUser).toHaveBeenCalledWith(caller);
      expect(calls).toEqual([
        [
          "rpc",
          "delete_enrolment_now",
          JSON.stringify({
            p_enrolment_id: ENROLMENT_ID,
            p_confirmation: "DELETE",
          }),
        ],
      ]);
      expect(logged).toEqual([
        JSON.stringify([
          `enrolment_deleted requestId=${REQUEST_ID} status=completed`,
        ]),
      ]);
      expectNoIdentifiers();
    });

    it.each([
      ["TH012", HttpStatus.NOT_FOUND, "enrolment_not_found"],
      ["TH017", HttpStatus.UNAUTHORIZED, "recent_authentication_required"],
    ] as const)("maps %s to %d %s", async (code, status, token) => {
      const { service } = setup({
        data: null,
        error: { code, message: "synthetic detail", hint: "synthetic_hint" },
      });
      expect(
        await codeOf(
          service.deleteNow(recent(), ENROLMENT_ID, "DELETE", REQUEST_ID),
        ),
      ).toEqual({ status, code: token });
      // A refusal the caller can act on is not a failure: nothing is logged.
      expect(logged).toEqual([]);
    });

    it.each([
      ["TH010", "TH010"],
      ["TH020", "TH020"],
      ["TH006", "TH006"],
      ["TH999", "TH999"],
      ["42501", "42501"],
      ["23514", "23514"],
      ["22P02", "22P02"],
      ["XX000", "XX000"],
      ["PGRST202", "none"],
      ["th012", "none"],
    ])("fails closed on %s, logging the code only", async (code, loggedAs) => {
      const { service } = setup({
        data: null,
        error: { code, message: "synthetic detail", hint: "synthetic_hint" },
      });
      const error = await codeOf(
        service.deleteNow(recent(), ENROLMENT_ID, "DELETE", REQUEST_ID),
      );
      expect(error).toBeInstanceOf(BadGatewayException);
      expect(
        JSON.stringify((error as BadGatewayException).getResponse()),
      ).not.toContain(code);
      expect(logged).toEqual([
        JSON.stringify([
          `enrolment_deletion_failed requestId=${REQUEST_ID} status=enrolment_delete_failed code=${loggedAs}`,
        ]),
      ]);
      expectNoIdentifiers();
    });

    it("message text and hint never decide: TH012 text under another code is a 502", async () => {
      const { service } = setup({
        data: null,
        error: {
          code: "P0001",
          message: "Enrolment not found",
          hint: "enrolment_not_found",
        },
      });
      expect(
        await codeOf(
          service.deleteNow(recent(), ENROLMENT_ID, "DELETE", REQUEST_ID),
        ),
      ).toBeInstanceOf(BadGatewayException);
    });
  });

  it.each(["share_care_team", "share_caregiver"] as const)(
    "refuses %s before touching the database",
    async (purpose) => {
      const { service, calls } = setup();
      expect(
        await codeOf(
          service.grantConsent(
            user,
            grantDto({
              purpose,
              recipientRef: "00000000-0000-4000-8000-0000000000c1",
            }),
          ),
        ),
      ).toEqual({ status: HttpStatus.CONFLICT, code: "sharing_not_available" });
      expect(calls).toEqual([]);
    },
  );

  it("inserts consents plainly (never upsert) and maps a duplicate", async () => {
    const { service, calls } = setup(
      { data: enrolmentRow(), error: null },
      { data: null, error: null },
      { data: null, error: { code: "23505", message: "duplicate key" } },
    );
    expect(await codeOf(service.grantConsent(user, grantDto()))).toEqual({
      status: HttpStatus.CONFLICT,
      code: "consent_already_granted",
    });
    expect(calls.some((call) => call[0] === "insert")).toBe(true);
    expect(calls.some((call) => call[0] === "upsert")).toBe(false);
  });

  describe("a consent insert refused by the insert policy (42501)", () => {
    // The deletion barrier is told apart by asking it, never by the text:
    // each case carries the barrier's own wording.
    const refused = {
      data: null,
      error: { code: "42501", message: "Account deletion has started" },
    };

    it.each([
      [false, HttpStatus.CONFLICT, "account_deletion_in_progress"],
      [true, HttpStatus.CONFLICT, "consent_not_permitted"],
      [null, HttpStatus.CONFLICT, "account_deletion_in_progress"],
    ])(
      "barrier open = %j answers %d %s",
      async (barrierOpen, status, token) => {
        const { service, calls } = setup(
          { data: enrolmentRow(), error: null },
          { data: null, error: null },
          refused,
          { data: barrierOpen, error: null },
        );
        expect(await codeOf(service.grantConsent(user, grantDto()))).toEqual({
          status,
          code: token,
        });
        expect(calls).toContainEqual(["rpc", "deletion_barrier_open"]);
      },
    );

    it("fails closed when the barrier cannot be read", async () => {
      const { service } = setup(
        { data: enrolmentRow(), error: null },
        { data: null, error: null },
        refused,
        { data: null, error: { code: "XX000", message: "synthetic" } },
      );
      expect(
        await codeOf(service.grantConsent(user, grantDto())),
      ).toBeInstanceOf(BadGatewayException);
    });

    it("asks the barrier only after a 42501", async () => {
      const { service, calls } = setup(
        { data: enrolmentRow(), error: null },
        { data: null, error: null },
        { data: null, error: { code: "23505", message: "duplicate key" } },
      );
      await codeOf(service.grantConsent(user, grantDto()));
      expect(calls.some((call) => call[1] === "deletion_barrier_open")).toBe(
        false,
      );
    });
  });

  it("reports a missing consent as not found and a revoked one as conflict", async () => {
    const missing = setup(
      { data: null, error: null },
      { data: null, error: null },
    );
    expect(await codeOf(missing.service.revokeConsent(user, "c1"))).toEqual({
      status: HttpStatus.NOT_FOUND,
      code: "consent_not_found",
    });
    const revoked = setup(
      { data: null, error: null },
      {
        data: consentRow({ revoked_at: "2026-10-18T00:00:00Z" }),
        error: null,
      },
    );
    expect(await codeOf(revoked.service.revokeConsent(user, "c1"))).toEqual({
      status: HttpStatus.CONFLICT,
      code: "consent_already_revoked",
    });
  });

  describe("revoking a superseded core id", () => {
    const superseded = consentRow({
      revoked_at: "2026-10-18T01:00:00.000Z",
      superseded_by: NEW_CORE_ID,
    });

    it.each([
      ["no row matched", { data: null, error: null }],
      [
        "TH002 (revoked concurrently)",
        { data: null, error: { code: "TH002", message: "synthetic" } },
      ],
    ])(
      "answers consent_superseded while a newer core is live (%s)",
      async (_label, update) => {
        const { service } = setup(
          update,
          { data: superseded, error: null },
          { data: consentRow({ id: NEW_CORE_ID }), error: null },
        );
        expect(await codeOf(service.revokeConsent(user, CORE_ID))).toEqual({
          status: HttpStatus.CONFLICT,
          code: "consent_superseded",
        });
      },
    );

    it("answers consent_already_revoked once no core is live", async () => {
      const { service } = setup(
        { data: null, error: null },
        { data: superseded, error: null },
        { data: null, error: null },
      );
      expect(await codeOf(service.revokeConsent(user, CORE_ID))).toEqual({
        status: HttpStatus.CONFLICT,
        code: "consent_already_revoked",
      });
    });
  });

  describe("consent grant", () => {
    it("sends the shown version and locale, never consent_text", async () => {
      const { service, calls } = setup(
        { data: enrolmentRow(), error: null },
        { data: null, error: null },
        { data: consentRow({ consent_version: "v1" }), error: null },
      );
      const granted = await service.grantConsent(
        user,
        grantDto({ consentVersion: "v1" }),
      );
      const insert = calls.find((call) => call[0] === "insert");
      expect(insert).toEqual([
        "insert",
        JSON.stringify({
          enrolment_id: ENROLMENT_ID,
          purpose: "core",
          recipient_ref: null,
          consent_version: "v1",
          locale: "en",
        }),
      ]);
      expect(insert?.[1]).not.toContain("consent_text");
      // The version is the client's; the current documents are not read.
      expect(
        calls.some(
          (call) =>
            call[0] === "rpc" && call[1] === "current_consent_documents",
        ),
      ).toBe(false);
      expect(granted).toMatchObject({
        consentVersion: "v1",
        locale: "en",
        consentText: "Synthetic document text",
        supersededId: null,
      });
    });

    it("refuses a second grant of the live core document without calling the database function", async () => {
      const { service, calls } = setup(
        { data: enrolmentRow(), error: null },
        { data: consentRow({ consent_version: "v2" }), error: null },
      );
      expect(await codeOf(service.grantConsent(user, grantDto()))).toEqual({
        status: HttpStatus.CONFLICT,
        code: "consent_already_granted",
      });
      expect(calls.some((call) => call[0] === "rpc")).toBe(false);
    });

    it.each([
      ["another version", { consent_version: "v1" }],
      ["another locale", { consent_version: "v2", locale: "es" }],
      ["a stored row without locale", { consent_version: "v2", locale: null }],
    ])(
      "supersedes a live core of %s through supersede_core_consent",
      async (_label, live) => {
        const { service, calls } = setup(
          { data: enrolmentRow(), error: null },
          { data: consentRow(live), error: null },
          {
            data: [
              consentRow({
                ...live,
                revoked_at: "2026-10-18T01:00:00.000Z",
                superseded_by: NEW_CORE_ID,
              }),
              consentRow({ id: NEW_CORE_ID, consent_version: "v2" }),
            ],
            error: null,
          },
        );
        expect(await service.grantConsent(user, grantDto())).toMatchObject({
          id: NEW_CORE_ID,
          consentVersion: "v2",
          supersededId: CORE_ID,
        });
        expect(calls).toContainEqual([
          "rpc",
          "supersede_core_consent",
          JSON.stringify({
            p_enrolment: ENROLMENT_ID,
            p_version: "v2",
            p_locale: "en",
          }),
        ]);
        // Never revoke-then-insert, never an upsert.
        for (const method of ["insert", "update", "upsert"]) {
          expect(calls.some((call) => call[0] === method)).toBe(false);
        }
      },
    );

    const supersedeFails = (code: string) =>
      setup(
        { data: enrolmentRow(), error: null },
        { data: consentRow(), error: null },
        { data: null, error: { code, message: "synthetic", hint: "x" } },
      );

    it.each([
      ["TH001", HttpStatus.CONFLICT, "focus_cap_reached"],
      ["TH005", HttpStatus.CONFLICT, "enrolment_left"],
      ["TH006", HttpStatus.CONFLICT, "account_deletion_in_progress"],
      ["TH011", HttpStatus.CONFLICT, "consent_document_unavailable"],
      ["TH012", HttpStatus.NOT_FOUND, "enrolment_not_found"],
      ["TH013", HttpStatus.CONFLICT, "focus_swap_invalid"],
      ["TH014", HttpStatus.CONFLICT, "consent_version_unchanged"],
    ])("supersession maps %s to %d %s", async (code, status, token) => {
      expect(
        await codeOf(
          supersedeFails(code).service.grantConsent(user, grantDto()),
        ),
      ).toEqual({ status, code: token });
    });

    it.each(["TH010", "TH015", "TH002", "TH003", "TH999", "XX000"])(
      "supersession fails closed on %s",
      async (code) => {
        expect(
          await codeOf(
            supersedeFails(code).service.grantConsent(user, grantDto()),
          ),
        ).toBeInstanceOf(BadGatewayException);
      },
    );

    it("insert maps TH011 to consent_document_unavailable", async () => {
      const { service } = setup(
        { data: enrolmentRow(), error: null },
        { data: null, error: null },
        { data: null, error: { code: "TH011", message: "synthetic" } },
      );
      expect(await codeOf(service.grantConsent(user, grantDto()))).toEqual({
        status: HttpStatus.CONFLICT,
        code: "consent_document_unavailable",
      });
    });

    describe("TH004 from the supersession (a lost race)", () => {
      const th004 = { data: null, error: { code: "TH004", message: "x" } };

      it("answers success when the live core is already the requested one", async () => {
        const { service, calls } = setup(
          { data: enrolmentRow(), error: null },
          { data: consentRow(), error: null },
          th004,
          {
            data: consentRow({ id: NEW_CORE_ID, consent_version: "v2" }),
            error: null,
          },
          { data: { id: CORE_ID }, error: null },
        );
        expect(await service.grantConsent(user, grantDto())).toMatchObject({
          id: NEW_CORE_ID,
          consentVersion: "v2",
          supersededId: CORE_ID,
        });
        expect(calls).toContainEqual([
          "eq",
          '"superseded_by"',
          JSON.stringify(NEW_CORE_ID),
        ]);
      });

      it("answers core_consent_required when no core is live", async () => {
        const { service } = setup(
          { data: enrolmentRow(), error: null },
          { data: consentRow(), error: null },
          th004,
          { data: null, error: null },
        );
        expect(await codeOf(service.grantConsent(user, grantDto()))).toEqual({
          status: HttpStatus.CONFLICT,
          code: "core_consent_required",
        });
      });

      // After the retry also hits TH004, the live core is read once more and
      // decides; the function is never called a third time. Anything but the
      // requested row or no row is one fail-closed conflict: the database
      // allows a locale-only move to the same version (R-29), so
      // consent_version_unchanged would be wrong for it.
      it.each([
        [
          "the requested one",
          consentRow({ id: NEW_CORE_ID, consent_version: "v2" }),
          "done",
        ],
        [
          "a later version",
          consentRow({ id: NEW_CORE_ID, consent_version: "v3", locale: "es" }),
          "consent_conflict_retry",
        ],
        [
          "the same version in another locale",
          consentRow({ id: NEW_CORE_ID, consent_version: "v2", locale: "es" }),
          "consent_conflict_retry",
        ],
        [
          "an earlier version",
          consentRow({ id: NEW_CORE_ID, consent_version: "v1", locale: "es" }),
          "consent_conflict_retry",
        ],
        [
          "a row stored before documents existed",
          consentRow({ id: NEW_CORE_ID, consent_version: "v9", locale: null }),
          "consent_conflict_retry",
        ],
        ["nothing", null, "core_consent_required"],
      ])(
        "after the retry loses too, answers from a live core that is %s",
        async (_label, finalLive, expected) => {
          const other = consentRow({ id: OTHER_ID, locale: "es" });
          const { service, calls } = setup(
            { data: enrolmentRow(), error: null },
            { data: consentRow(), error: null },
            th004,
            { data: other, error: null },
            th004,
            { data: finalLive, error: null },
            ...(expected === "done"
              ? [{ data: { id: OTHER_ID }, error: null }]
              : []),
          );
          const result = await codeOf(service.grantConsent(user, grantDto()));
          if (expected === "done") {
            expect(result).toBeUndefined();
          } else {
            expect(result).toEqual({
              status: HttpStatus.CONFLICT,
              code: expected,
            });
          }
          expect(
            calls.filter((call) => call[1] === "supersede_core_consent"),
          ).toHaveLength(2);
          // Decided from the live row alone: no document is read.
          expect(calls).not.toContainEqual(["from", "consent_documents"]);
        },
      );
    });
  });

  describe("revoke by enrolment and purpose", () => {
    const revokeDto = (overrides: Record<string, unknown> = {}) => ({
      enrolmentId: ENROLMENT_ID,
      purpose: "screen_time" as const,
      revoked: true as const,
      ...overrides,
    });

    it("finds the live row of that purpose on the caller's enrolment and revokes it by id", async () => {
      const live = consentRow({ id: OTHER_ID, purpose: "screen_time" });
      const { service, calls } = setup(
        { data: enrolmentRow(), error: null },
        { data: [live], error: null },
        {
          data: { ...live, revoked_at: "2026-10-18T02:00:00.000Z" },
          error: null,
        },
      );
      const result = await service.revokeConsentByPurpose(user, revokeDto());
      expect(result).toMatchObject({ id: OTHER_ID, purpose: "screen_time" });
      expect(calls).toContainEqual([
        "eq",
        '"user_id"',
        JSON.stringify(user.id),
      ]);
      expect(calls).toContainEqual(["eq", '"purpose"', '"screen_time"']);
      expect(calls).toContainEqual(["is", '"revoked_at"', "null"]);
      expect(calls).toContainEqual(["eq", '"id"', JSON.stringify(OTHER_ID)]);
      expect(calls.filter(([name]) => name === "insert")).toEqual([]);
    });

    it("another member's or an unknown enrolment is enrolment_not_found", async () => {
      const { service, calls } = setup({ data: null, error: null });
      expect(
        await codeOf(service.revokeConsentByPurpose(user, revokeDto())),
      ).toEqual({
        status: HttpStatus.NOT_FOUND,
        code: "enrolment_not_found",
      });
      expect(calls.filter(([name]) => name === "update")).toEqual([]);
    });

    it("none live is consent_not_found and nothing is written", async () => {
      const { service, calls } = setup(
        { data: enrolmentRow(), error: null },
        { data: [], error: null },
      );
      expect(
        await codeOf(service.revokeConsentByPurpose(user, revokeDto())),
      ).toEqual({
        status: HttpStatus.NOT_FOUND,
        code: "consent_not_found",
      });
      expect(
        calls.filter(([name]) => name === "update" || name === "insert"),
      ).toEqual([]);
    });

    it("two live share consents without a recipient need recipientRef", async () => {
      const { service, calls } = setup(
        { data: enrolmentRow(), error: null },
        {
          data: [
            consentRow({
              id: OTHER_ID,
              purpose: "share_care_team",
              recipient_ref: CORE_ID,
            }),
            consentRow({
              id: NEW_CORE_ID,
              purpose: "share_care_team",
              recipient_ref: ENROLMENT_ID,
            }),
          ],
          error: null,
        },
      );
      expect(
        await codeOf(
          service.revokeConsentByPurpose(
            user,
            revokeDto({ purpose: "share_care_team" }),
          ),
        ),
      ).toEqual({
        status: HttpStatus.CONFLICT,
        code: "consent_recipient_required",
      });
      expect(calls.filter(([name]) => name === "update")).toEqual([]);
    });

    it("matches a recipient by its lowercase id", async () => {
      const live = consentRow({
        id: OTHER_ID,
        purpose: "share_care_team",
        recipient_ref: CORE_ID,
      });
      const { service, calls } = setup(
        { data: enrolmentRow(), error: null },
        { data: [live], error: null },
        {
          data: { ...live, revoked_at: "2026-10-18T02:00:00.000Z" },
          error: null,
        },
      );
      await service.revokeConsentByPurpose(
        user,
        revokeDto({
          purpose: "share_care_team",
          recipientRef: CORE_ID.toUpperCase(),
        }),
      );
      expect(calls).toContainEqual([
        "eq",
        '"recipient_ref"',
        JSON.stringify(CORE_ID),
      ]);
    });

    it("refuses a recipient for a purpose that is not shared, before any read", async () => {
      const { service, forUser } = setup();
      await expect(
        service.revokeConsentByPurpose(
          user,
          revokeDto({ recipientRef: CORE_ID }),
        ),
      ).rejects.toThrow("recipientRef does not match purpose");
      expect(forUser).not.toHaveBeenCalled();
    });

    it("a failed read is a 502", async () => {
      const { service } = setup(
        { data: enrolmentRow(), error: null },
        { data: null, error: { code: "XX000", message: "synthetic" } },
      );
      await expect(
        service.revokeConsentByPurpose(user, revokeDto()),
      ).rejects.toBeInstanceOf(BadGatewayException);
    });
  });

  describe("focus swap", () => {
    const swapped = {
      data: [
        { ...enrolmentRow("paused"), id: ENROLMENT_ID },
        { ...enrolmentRow("focus"), id: OTHER_ID },
      ],
      error: null,
    };

    it("calls swap_focus once and returns both enrolments with consents", async () => {
      const { service, calls } = setup(
        barrierOpen,
        currentDocs(),
        {
          data: [consentRow({ enrolment_id: OTHER_ID, consent_version: "v2" })],
          error: null,
          count: 1,
        },
        swapped,
      );
      const result = await service.swapFocus(user, {
        demoteId: ENROLMENT_ID,
        promoteId: OTHER_ID,
      });
      expect(calls).toContainEqual([
        "rpc",
        "swap_focus",
        JSON.stringify({ p_demote: ENROLMENT_ID, p_promote: OTHER_ID }),
      ]);
      expect(result.demoted).toMatchObject({
        id: ENROLMENT_ID,
        status: "paused",
        consents: [],
      });
      expect(result.promoted).toMatchObject({
        id: OTHER_ID,
        status: "focus",
        consents: [{ id: CORE_ID }],
        reconsentRequired: false,
      });
      for (const method of ["update", "insert", "upsert"]) {
        expect(calls.some((call) => call[0] === method)).toBe(false);
      }
      // Nothing is read after the swap: no failure can follow its commit.
      const rpcAt = calls.findIndex((call) => call[1] === "swap_focus");
      expect(calls.slice(rpcAt + 1).some((call) => call[0] === "from")).toBe(
        false,
      );
      expect(calls.filter((call) => call[0] === "from")).toHaveLength(1);
    });

    it("compares ids in lower case (Postgres returns them so)", async () => {
      const { service, calls } = setup(
        barrierOpen,
        currentDocs(),
        { data: [], error: null, count: 0 },
        swapped,
      );
      const result = await service.swapFocus(user, {
        demoteId: ENROLMENT_ID.toUpperCase(),
        promoteId: OTHER_ID.toUpperCase(),
      });
      expect(calls).toContainEqual([
        "rpc",
        "swap_focus",
        JSON.stringify({ p_demote: ENROLMENT_ID, p_promote: OTHER_ID }),
      ]);
      expect([result.demoted.id, result.promoted.id]).toEqual([
        ENROLMENT_ID,
        OTHER_ID,
      ]);
    });

    it("a failed read before the swap is a 502 and the swap is not called", async () => {
      const { service, calls } = setup(barrierOpen, currentDocs(), {
        data: null,
        error: { code: "XX000", message: "synthetic" },
      });
      expect(
        await codeOf(
          service.swapFocus(user, {
            demoteId: ENROLMENT_ID,
            promoteId: OTHER_ID,
          }),
        ),
      ).toBeInstanceOf(BadGatewayException);
      expect(calls.some((call) => call[1] === "swap_focus")).toBe(false);
    });

    it.each([
      ["TH001", HttpStatus.CONFLICT, "focus_cap_reached"],
      ["TH004", HttpStatus.CONFLICT, "core_consent_required"],
      ["TH005", HttpStatus.CONFLICT, "enrolment_left"],
      ["TH006", HttpStatus.CONFLICT, "account_deletion_in_progress"],
      ["TH011", HttpStatus.CONFLICT, "consent_document_unavailable"],
      ["TH012", HttpStatus.NOT_FOUND, "enrolment_not_found"],
      ["TH013", HttpStatus.CONFLICT, "focus_swap_invalid"],
      ["TH014", HttpStatus.CONFLICT, "consent_version_unchanged"],
    ])("maps %s to %d %s", async (code, status, token) => {
      const { service } = setup(
        barrierOpen,
        currentDocs(),
        { data: [], error: null, count: 0 },
        {
          data: null,
          error: { code, message: "synthetic", hint: "synthetic" },
        },
      );
      expect(
        await codeOf(
          service.swapFocus(user, {
            demoteId: ENROLMENT_ID,
            promoteId: OTHER_ID,
          }),
        ),
      ).toEqual({ status, code: token });
    });

    it.each(["TH010", "TH015", "TH002", "TH003", "TH999", "42501", "XX000"])(
      "fails closed on %s",
      async (code) => {
        const { service } = setup(
          barrierOpen,
          currentDocs(),
          { data: [], error: null, count: 0 },
          { data: null, error: { code, message: "synthetic detail" } },
        );
        const error = await codeOf(
          service.swapFocus(user, {
            demoteId: ENROLMENT_ID,
            promoteId: OTHER_ID,
          }),
        );
        expect(error).toBeInstanceOf(BadGatewayException);
        expect(
          JSON.stringify((error as BadGatewayException).getResponse()),
        ).not.toContain("synthetic");
      },
    );

    it("fails closed when the function does not return both rows", async () => {
      const { service } = setup(
        barrierOpen,
        currentDocs(),
        { data: [], error: null, count: 0 },
        { data: [swapped.data[0]], error: null },
      );
      expect(
        await codeOf(
          service.swapFocus(user, {
            demoteId: ENROLMENT_ID,
            promoteId: OTHER_ID,
          }),
        ),
      ).toBeInstanceOf(BadGatewayException);
    });
  });

  describe("current core consent version", () => {
    const listWith = async (
      status: string,
      consents: Record<string, unknown>[],
      docs: Result = currentDocs("v2", "v3"),
      profile?: Result,
    ) => {
      const { service, calls } = setup(
        docs,
        { data: [enrolmentRow(status)], error: null, count: 1 },
        { data: consents, error: null, count: consents.length },
        ...(profile ? [profile] : []),
      );
      const result = await service.list(user);
      return { result, calls, enrolment: result.enrolments[0] };
    };

    it("reads core documents from current_consent_documents()", async () => {
      const { result, calls } = await listWith("focus", []);
      expect(result.currentCoreConsentVersions).toEqual({ en: "v2", es: "v3" });
      expect(calls).toContainEqual([
        "rpc",
        "current_consent_documents",
        JSON.stringify({}),
        JSON.stringify({ get: true }),
      ]);
      expect(calls).toContainEqual(["eq", '"purpose"', '"core"']);
    });

    it.each([
      [
        "the current en version",
        "focus",
        { consent_version: "v2" },
        "v2",
        false,
      ],
      [
        "the current es version",
        "focus",
        { consent_version: "v3", locale: "es" },
        "v3",
        false,
      ],
      ["an older version", "focus", { consent_version: "v1" }, "v2", true],
      [
        "the en version in es",
        "focus",
        { consent_version: "v2", locale: "es" },
        "v3",
        true,
      ],
      [
        "an older version, left",
        "left",
        { consent_version: "v1" },
        "v2",
        false,
      ],
    ])(
      "a live core on %s",
      async (_label, status, live, current, reconsent) => {
        const { enrolment, calls } = await listWith(status, [consentRow(live)]);
        expect(enrolment).toMatchObject({
          currentCoreConsentVersion: current,
          reconsentRequired: reconsent,
        });
        // The profile is read only for a consent stored without locale.
        expect(calls).not.toContainEqual(["from", "profiles"]);
      },
    );

    describe("a live core stored before documents existed (no locale)", () => {
      const legacy = [consentRow({ consent_version: "v2", locale: null })];

      it.each([
        ["en", "v2"],
        ["es", "v3"],
      ])(
        "uses the profile locale %s and needs re-consent to %s",
        async (locale, current) => {
          const { enrolment, calls } = await listWith(
            "focus",
            legacy,
            undefined,
            { data: { locale }, error: null },
          );
          expect(enrolment).toMatchObject({
            currentCoreConsentVersion: current,
            reconsentRequired: true,
          });
          expect(calls).toContainEqual(["from", "profiles"]);
          expect(calls).toContainEqual(["eq", '"id"', JSON.stringify(user.id)]);
        },
      );

      it("no re-consent when the profile locale has no current core document", async () => {
        const { enrolment } = await listWith(
          "focus",
          legacy,
          {
            data: [{ purpose: "core", version: "v2", locale: "en" }],
            error: null,
          },
          { data: { locale: "es" }, error: null },
        );
        expect(enrolment).toMatchObject({
          currentCoreConsentVersion: null,
          reconsentRequired: false,
        });
      });

      it("no re-consent without a profile (no locale to offer it in)", async () => {
        const { enrolment } = await listWith("focus", legacy, undefined, {
          data: null,
          error: null,
        });
        expect(enrolment).toMatchObject({
          currentCoreConsentVersion: null,
          reconsentRequired: false,
        });
      });

      it("fails closed when the profile cannot be read", async () => {
        const { service } = setup(
          currentDocs(),
          { data: [enrolmentRow()], error: null, count: 1 },
          { data: legacy, error: null, count: 1 },
          { data: null, error: { code: "XX000", message: "synthetic" } },
        );
        expect(await codeOf(service.list(user))).toBeInstanceOf(
          BadGatewayException,
        );
      });
    });

    it("no re-consent when no core document is current for the locale", async () => {
      const { enrolment, result } = await listWith(
        "focus",
        [consentRow({ consent_version: "v1", locale: "es" })],
        {
          data: [{ purpose: "core", version: "v2", locale: "en" }],
          error: null,
        },
      );
      expect(result.currentCoreConsentVersions).toEqual({ en: "v2", es: null });
      expect(enrolment).toMatchObject({
        currentCoreConsentVersion: null,
        reconsentRequired: false,
      });
    });

    it("no live core consent: no version, no re-consent", async () => {
      const { enrolment } = await listWith("focus", []);
      expect(enrolment).toMatchObject({
        currentCoreConsentVersion: null,
        reconsentRequired: false,
      });
    });
  });
});
