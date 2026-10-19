import { BadGatewayException, HttpStatus } from "@nestjs/common";
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
      const { service } = setup({ data: null, error });
      expectHidden(
        await codeOf(service.deleteNow(recent(), ENROLMENT_ID, "DELETE")),
      );
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

  it("checks the deletion barrier only when rejoining", async () => {
    const rejoin = setup(
      { data: enrolmentRow("left"), error: null },
      { data: false, error: null },
    );
    expect(
      await codeOf(
        rejoin.service.update(user, ENROLMENT_ID, { status: "focus" }),
      ),
    ).toEqual({
      status: HttpStatus.CONFLICT,
      code: "account_deletion_in_progress",
    });
    expect(rejoin.calls).toContainEqual(["rpc", "deletion_barrier_open"]);

    const pause = setup(
      { data: enrolmentRow("focus"), error: null },
      currentDocs(),
      { data: enrolmentRow("paused"), error: null },
      { data: [], error: null, count: 0 },
    );
    await pause.service.update(user, ENROLMENT_ID, { status: "paused" });
    expect(
      pause.calls.some(
        (call) => call[0] === "rpc" && call[1] === "deletion_barrier_open",
      ),
    ).toBe(false);
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
      await codeOf(wrong.service.deleteNow(recent, ENROLMENT_ID, "delete")),
    ).toEqual({
      status: HttpStatus.BAD_REQUEST,
      code: "confirmation_required",
    });
    const stale = setup();
    expect(
      await codeOf(stale.service.deleteNow(user, ENROLMENT_ID, "DELETE")),
    ).toEqual({
      status: HttpStatus.UNAUTHORIZED,
      code: "recent_authentication_required",
    });
    expect(wrong.calls).toEqual([]);
    expect(stale.calls).toEqual([]);
  });

  it("deletes now with the caller-scoped client and reports missing rows", async () => {
    const { service, calls } = setup({ data: [], error: null });
    const recent = { ...user, authenticatedAt: Math.floor(Date.now() / 1000) };
    expect(
      await codeOf(service.deleteNow(recent, ENROLMENT_ID, "DELETE")),
    ).toEqual({
      status: HttpStatus.NOT_FOUND,
      code: "enrolment_not_found",
    });
    expect(calls).toEqual(
      expect.arrayContaining([
        ["from", "enrolments"],
        ["delete"],
        ["eq", '"id"', JSON.stringify(ENROLMENT_ID)],
        ["eq", '"user_id"', JSON.stringify(user.id)],
      ]),
    );
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
      ["TH006", HttpStatus.CONFLICT, "deletion_in_progress"],
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

      it("tries once more when another version became live, then gives up", async () => {
        const other = consentRow({ id: NEW_CORE_ID, locale: "es" });
        const retried = setup(
          { data: enrolmentRow(), error: null },
          { data: consentRow(), error: null },
          th004,
          { data: other, error: null },
          th004,
          { data: other, error: null },
        );
        expect(
          await codeOf(retried.service.grantConsent(user, grantDto())),
        ).toEqual({
          status: HttpStatus.CONFLICT,
          code: "core_consent_required",
        });
        expect(
          retried.calls.filter((call) => call[1] === "supersede_core_consent"),
        ).toHaveLength(2);
      });
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
      const { service, calls } = setup(currentDocs(), swapped, {
        data: [consentRow({ enrolment_id: OTHER_ID, consent_version: "v2" })],
        error: null,
        count: 1,
      });
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
    });

    it.each([
      ["TH001", HttpStatus.CONFLICT, "focus_cap_reached"],
      ["TH004", HttpStatus.CONFLICT, "core_consent_required"],
      ["TH005", HttpStatus.CONFLICT, "enrolment_left"],
      ["TH006", HttpStatus.CONFLICT, "deletion_in_progress"],
      ["TH011", HttpStatus.CONFLICT, "consent_document_unavailable"],
      ["TH012", HttpStatus.NOT_FOUND, "enrolment_not_found"],
      ["TH013", HttpStatus.CONFLICT, "focus_swap_invalid"],
      ["TH014", HttpStatus.CONFLICT, "consent_version_unchanged"],
    ])("maps %s to %d %s", async (code, status, token) => {
      const { service } = setup(currentDocs(), {
        data: null,
        error: { code, message: "synthetic", hint: "synthetic" },
      });
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
        const { service } = setup(currentDocs(), {
          data: null,
          error: { code, message: "synthetic detail" },
        });
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
      const { service } = setup(currentDocs(), {
        data: [swapped.data[0]],
        error: null,
      });
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
    ) => {
      const { service, calls } = setup(
        docs,
        { data: [enrolmentRow(status)], error: null, count: 1 },
        { data: consents, error: null, count: consents.length },
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
        "a stored row without locale",
        "focus",
        { consent_version: "v2", locale: null },
        null,
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
        const { enrolment } = await listWith(status, [consentRow(live)]);
        expect(enrolment).toMatchObject({
          currentCoreConsentVersion: current,
          reconsentRequired: reconsent,
        });
      },
    );

    it("needs re-consent when no core document is current for the locale", async () => {
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
        reconsentRequired: true,
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
