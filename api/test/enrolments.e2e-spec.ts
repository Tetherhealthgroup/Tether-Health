import { randomUUID } from "node:crypto";
import { Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import {
  FastifyAdapter,
  NestFastifyApplication,
} from "@nestjs/platform-fastify";
import { Test } from "@nestjs/testing";
import { AppModule } from "../src/app.module";
import { TokenVerifier } from "../src/auth/token-verifier";
import { configureApp } from "../src/configure-app";
import { CURRENT_CORE_CONSENT_VERSION } from "../src/enrolments/consent-versions";
import { UserSupabaseClientFactory } from "../src/enrolments/user-supabase-client";
import {
  DATABASE_ERRORS,
  databaseError,
  type DatabaseErrorHint,
} from "./support/database-errors";
import {
  DB_CANARY,
  FakePostgrest,
  registryError,
  type PgError,
} from "./support/fake-postgrest";

/**
 * Enrolments and consents, end to end through the real Nest app, the real
 * auth guard, validation pipe and filters, the real services and the real
 * supabase-js client. Mocked: TokenVerifier (synthetic tokens map to
 * synthetic user ids) and the network below supabase-js, which is a fake
 * PostgREST (test/support/fake-postgrest.ts) that derives the user from the
 * request's bearer token and applies the TH-913 RLS policies, grants,
 * constraints and triggers.
 *
 * Stand-in fidelity (th-qa D1, D2, D4):
 * - D1: the fake evaluates check, foreign-key and RLS insert checks in a
 *   fixed order of its own (Postgres runs RLS WITH CHECK before
 *   constraints, and unique/foreign-key checks later). No test relies on it.
 * - D2: the fake's clock advances by 1 ms on every timestamp, so rows
 *   written in one request get distinct, strictly increasing times where
 *   Postgres's now() would give them the same value. Ordering by
 *   granted_at/created_at is therefore never tied in the fake. No test
 *   relies on it.
 * - D4: the database's own errors (focus cap, consent revoke-only rules)
 *   carry the registry's TH codes, messages and hints
 *   (test/support/database-errors.ts, checked against
 *   docs/contracts/database.md by test/database-errors.e2e-spec.ts). The
 *   fake answers them with HTTP 400, as PostgREST does for SQLSTATEs it does
 *   not know; that the real deferred focus-cap error at COMMIT arrives the
 *   same way is unverified until a local database run. The API matches the
 *   code only, so the status and message do not affect the mapping.
 */

type Method = "DELETE" | "GET" | "PATCH" | "POST";

interface Caller {
  token: string;
  id: string;
  /** Own documentation-range address, so the per-IP rate limit is per caller. */
  address: string;
}

const CANARY = "synthetic-canary-7c1e";
const TOKEN_CANARY = "synthetic-bearer-canary";
const DELETE_BODY = { confirmation: "DELETE" };
const CORE_TEXT =
  "  Synthetic core wording, línea dos —\n kept exactly (tabs\tand trailing space) ";

describe("Enrolments and consents API (e2e)", () => {
  let app: NestFastifyApplication;
  let fake: FakePostgrest;
  const users = new Map<string, { sub: string; authTime: number }>();
  const logged: string[] = [];

  beforeAll(async () => {
    fake = new FakePostgrest();
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(TokenVerifier)
      .useValue({
        verify: (token: string) => {
          const user = users.get(token);
          return user
            ? Promise.resolve(user)
            : Promise.reject(new Error("invalid token"));
        },
      })
      .overrideProvider(UserSupabaseClientFactory)
      .useFactory({
        factory: (config: ConfigService) =>
          new UserSupabaseClientFactory(config, fake.fetch),
        inject: [ConfigService],
      })
      .compile();
    app = module.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter({ bodyLimit: 65536 }),
    );
    await configureApp(app);
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
    for (const level of ["log", "warn", "error", "debug", "verbose"] as const) {
      jest
        .spyOn(Logger.prototype, level)
        .mockImplementation((...args: unknown[]) => {
          logged.push(JSON.stringify(args));
        });
    }
  });

  // A failure injected but never consumed would break an unrelated later
  // test: clear it first, then fail the test that left it.
  afterEach(() => {
    const pending = fake.pendingFailures;
    fake.clearFailures();
    expect(pending).toBe(0);
  });

  afterAll(async () => {
    jest.restoreAllMocks();
    await app.close();
  });

  let counter = 0;
  /** authAgeSeconds: how long ago the synthetic sign-in happened. */
  const newCaller = (authAgeSeconds = 0): Caller => {
    counter += 1;
    const caller = {
      token: `${TOKEN_CANARY}-${counter}`,
      id: randomUUID(),
      address: `${counter <= 250 ? "198.51.100" : "203.0.113"}.${counter % 250}`,
    };
    users.set(caller.token, {
      sub: caller.id,
      authTime: Math.floor(Date.now() / 1000) - authAgeSeconds,
    });
    fake.addUser(caller.token, caller.id);
    return caller;
  };

  /**
   * Every response is checked: it never contains a bearer token or the
   * database's error details (submitted values + DB_CANARY).
   */
  const call = async (
    caller: Caller | null,
    method: Method,
    url: string,
    payload?: unknown,
  ) => {
    const response = await app.inject({
      method,
      url,
      remoteAddress: caller?.address ?? "192.0.2.1",
      headers: caller ? { authorization: `Bearer ${caller.token}` } : {},
      ...(payload === undefined ? {} : { payload: payload as object }),
    });
    expect(response.body).not.toContain(TOKEN_CANARY);
    expect(response.body).not.toContain(DB_CANARY);
    expect(response.body).not.toContain("Failing row contains");
    return response;
  };

  const enrol = async (
    caller: Caller,
    programmeCode: string,
    status = "focus",
    mode?: string,
  ) => {
    const response = await call(caller, "POST", "/v1/enrolments", {
      programmeCode,
      status,
      ...(mode ? { mode } : {}),
    });
    expect(response.statusCode).toBe(201);
    return response.json<{ id: string }>().id;
  };

  const grant = async (
    caller: Caller,
    enrolmentId: string,
    purpose: string,
    extra: Record<string, unknown> = {},
  ) => {
    const response = await call(caller, "POST", "/v1/enrolments/consents", {
      enrolmentId,
      purpose,
      consentVersion: CURRENT_CORE_CONSENT_VERSION,
      consentText: `Synthetic ${purpose} wording`,
      ...extra,
    });
    expect(response.statusCode).toBe(201);
    return response.json<{ id: string }>().id;
  };

  const expectCoded = (
    response: { statusCode: number; json: () => unknown; body: string },
    status: number,
    code: string,
  ) => {
    expect(response.statusCode).toBe(status);
    const body = response.json() as Record<string, unknown>;
    expect(Object.keys(body).sort()).toEqual(
      ["code", "error", "requestId", "statusCode"].sort(),
    );
    expect(body).toMatchObject({
      statusCode: status,
      error: "Request rejected",
      code,
    });
  };

  const expectUncoded = (
    response: { statusCode: number; json: () => unknown },
    status: number,
  ) => {
    expect(response.statusCode).toBe(status);
    const body = response.json() as Record<string, unknown>;
    expect(Object.keys(body).sort()).toEqual(
      ["error", "requestId", "statusCode"].sort(),
    );
    expect(body.statusCode).toBe(status);
    expect(body.error).toBe(
      status >= 500 ? "Service unavailable" : "Request rejected",
    );
  };

  describe("authentication", () => {
    const id = "00000000-0000-4000-8000-000000000001";
    it.each([
      ["GET", "/v1/enrolments", undefined],
      ["POST", "/v1/enrolments", { programmeCode: "bf", status: "focus" }],
      ["PATCH", `/v1/enrolments/${id}`, { status: "paused" }],
      ["DELETE", `/v1/enrolments/${id}`, DELETE_BODY],
      ["POST", "/v1/enrolments/consents", {}],
      ["PATCH", `/v1/enrolments/consents/${id}`, { revoked: true }],
      ["GET", "/v1/catalogue/programmes", undefined],
    ])("%s %s requires a token", async (method, url, payload) => {
      const response = await call(null, method as Method, url, payload);
      expect(response.statusCode).toBe(401);
    });
  });

  it("GET /v1/catalogue/programmes returns the 11 programmes", async () => {
    const response = await call(newCaller(), "GET", "/v1/catalogue/programmes");
    expect(response.statusCode).toBe(200);
    const { programmes } = response.json<{
      programmes: { code: string; receivesResources: string[] }[];
    }>();
    expect(programmes.map((programme) => programme.code)).toEqual([
      "be",
      "bf",
      "ca",
      "ck",
      "ea",
      "hw",
      "nu",
      "re",
      "sd",
      "sf",
      "st",
    ]);
    expect(programmes.find((p) => p.code === "hw")).toEqual({
      code: "hw",
      slug: "heartwise",
      name: "Heartwise",
      area: "Cardiovascular health",
      archetype: "Manage",
      receivesResources: ["blood_pressure", "lipids"],
    });
  });

  describe("enrolments", () => {
    it("creates, lists and returns the caller's enrolment", async () => {
      const a = newCaller();
      const created = await call(a, "POST", "/v1/enrolments", {
        programmeCode: "bf",
        status: "focus",
        mode: "quit",
      });
      expect(created.statusCode).toBe(201);
      expect(created.json()).toMatchObject({
        programmeCode: "bf",
        status: "focus",
        mode: "quit",
        leftAt: null,
        consents: [],
        reconsentRequired: false,
      });

      const listed = await call(a, "GET", "/v1/enrolments");
      expect(listed.statusCode).toBe(200);
      expect(listed.json()).toEqual({
        currentCoreConsentVersion: CURRENT_CORE_CONSENT_VERSION,
        enrolments: [created.json()],
      });
    });

    it.each([
      ["an unknown field", { programmeCode: "bf", status: "focus", extra: 1 }],
      [
        "a user id",
        {
          programmeCode: "bf",
          status: "focus",
          userId: "00000000-0000-4000-8000-000000000002",
        },
      ],
      ["status left", { programmeCode: "bf", status: "left" }],
      ["a malformed code", { programmeCode: "BF1", status: "focus" }],
      ["a missing status", { programmeCode: "bf" }],
      ["an unknown mode", { programmeCode: "bf", status: "focus", mode: "x" }],
    ])("POST refuses %s (DTO whitelist)", async (_label, payload) => {
      const a = newCaller();
      expectUncoded(await call(a, "POST", "/v1/enrolments", payload), 400);
      expect(fake.table("enrolments").some((r) => r.user_id === a.id)).toBe(
        false,
      );
    });

    it("POST maps refusals to codes", async () => {
      const a = newCaller();
      expectCoded(
        await call(a, "POST", "/v1/enrolments", {
          programmeCode: "hw",
          status: "focus",
          mode: "quit",
        }),
        400,
        "mode_not_allowed",
      );
      expectCoded(
        await call(a, "POST", "/v1/enrolments", {
          programmeCode: "zz",
          status: "focus",
        }),
        404,
        "programme_not_found",
      );
      await enrol(a, "hw");
      expectCoded(
        await call(a, "POST", "/v1/enrolments", {
          programmeCode: "hw",
          status: "learn_only",
        }),
        409,
        "already_enrolled",
      );
    });

    it("enforces the focus cap of two and allows a two-step swap", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      await enrol(a, "hw");
      expectCoded(
        await call(a, "POST", "/v1/enrolments", {
          programmeCode: "st",
          status: "focus",
        }),
        409,
        "focus_cap_reached",
      );
      // The refused insert was rolled back.
      expect(
        fake
          .table("enrolments")
          .filter((r) => r.user_id === a.id)
          .map((r) => r.programme_code),
      ).toEqual(["bf", "hw"]);

      const st = await enrol(a, "st", "learn_only");
      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/${st}`, { status: "focus" }),
        409,
        "focus_cap_reached",
      );
      // Swap: demote first, then promote (each request is valid on its own).
      const demoted = await call(a, "PATCH", `/v1/enrolments/${bf}`, {
        status: "learn_only",
      });
      expect(demoted.statusCode).toBe(200);
      const promoted = await call(a, "PATCH", `/v1/enrolments/${st}`, {
        status: "focus",
      });
      expect(promoted.statusCode).toBe(200);
      expect(promoted.json()).toMatchObject({ id: st, status: "focus" });
    });

    it("leaving keeps the row and core consent, revokes optional consents; rejoin reuses the row", async () => {
      const a = newCaller();
      const id = await enrol(a, "bf", "focus", "reduce");
      const core = await grant(a, id, "core");
      const reminders = await grant(a, id, "reminders");

      const left = await call(a, "PATCH", `/v1/enrolments/${id}`, {
        status: "left",
      });
      expect(left.statusCode).toBe(200);
      const leftBody = left.json<{
        leftAt: string | null;
        consents: { id: string; revokedAt: string | null }[];
      }>();
      expect(leftBody.leftAt).not.toBeNull();
      // The response lists live consents only: core stays, reminders went.
      expect(leftBody.consents.map((c) => c.id)).toEqual([core]);
      expect(leftBody.consents[0]?.revokedAt).toBeNull();

      // Consents cannot be granted on a left enrolment.
      expectCoded(
        await call(a, "POST", "/v1/enrolments/consents", {
          enrolmentId: id,
          purpose: "research",
          consentVersion: "v1",
          consentText: "Synthetic research wording",
        }),
        409,
        "enrolment_left",
      );

      const rejoined = await call(a, "PATCH", `/v1/enrolments/${id}`, {
        status: "learn_only",
      });
      expect(rejoined.statusCode).toBe(200);
      expect(rejoined.json()).toMatchObject({
        id,
        status: "learn_only",
        mode: "reduce",
        leftAt: null,
      });
      const rows = fake
        .table("enrolments")
        .filter((r) => r.user_id === a.id && r.programme_code === "bf");
      expect(rows).toHaveLength(1);
      // Optional consents stay off after rejoining; core is still live.
      const consents = fake
        .table("programme_consents")
        .filter((r) => r.enrolment_id === id);
      expect(
        consents.find((c) => c.id === reminders)?.revoked_at,
      ).not.toBeNull();
      expect(consents.find((c) => c.id === core)?.revoked_at).toBeNull();
    });

    it("PATCH validates the body and the mode", async () => {
      const a = newCaller();
      const hw = await enrol(a, "hw");
      expectUncoded(await call(a, "PATCH", `/v1/enrolments/${hw}`, {}), 400);
      expectUncoded(
        await call(a, "PATCH", `/v1/enrolments/${hw}`, { status: null }),
        400,
      );
      expectUncoded(
        await call(a, "PATCH", `/v1/enrolments/${hw}`, {
          status: "paused",
          programmeCode: "bf",
        }),
        400,
      );
      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/${hw}`, { mode: "quit" }),
        400,
        "mode_not_allowed",
      );
      expectUncoded(
        await call(a, "PATCH", "/v1/enrolments/not-a-uuid", {
          status: "paused",
        }),
        400,
      );
      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/${randomUUID()}`, {
          status: "paused",
        }),
        404,
        "enrolment_not_found",
      );
    });

    it("DELETE removes the enrolment and its consents (delete now)", async () => {
      const a = newCaller();
      const id = await enrol(a, "ea", "learn_only");
      await grant(a, id, "core");
      const response = await call(
        a,
        "DELETE",
        `/v1/enrolments/${id}`,
        DELETE_BODY,
      );
      expect(response.statusCode).toBe(204);
      expect(response.body).toBe("");
      expect(fake.table("enrolments").some((r) => r.id === id)).toBe(false);
      expect(
        fake.table("programme_consents").some((r) => r.enrolment_id === id),
      ).toBe(false);
      expectCoded(
        await call(a, "DELETE", `/v1/enrolments/${id}`, DELETE_BODY),
        404,
        "enrolment_not_found",
      );
    });

    it.each([
      ["no body", undefined],
      ["an empty body", {}],
      ["a lower-case confirmation", { confirmation: "delete" }],
      ["a non-string confirmation", { confirmation: true }],
    ])("DELETE refuses %s with confirmation_required", async (_l, payload) => {
      const a = newCaller();
      const id = await enrol(a, "ck", "learn_only");
      expectCoded(
        await call(a, "DELETE", `/v1/enrolments/${id}`, payload),
        400,
        "confirmation_required",
      );
      expect(fake.table("enrolments").some((r) => r.id === id)).toBe(true);
    });

    it("DELETE refuses unknown body fields", async () => {
      const a = newCaller();
      const id = await enrol(a, "ck", "learn_only");
      expectUncoded(
        await call(a, "DELETE", `/v1/enrolments/${id}`, {
          ...DELETE_BODY,
          userId: randomUUID(),
        }),
        400,
      );
      expect(fake.table("enrolments").some((r) => r.id === id)).toBe(true);
    });

    it.each([
      ["stale", 3600],
      ["in the future", -120],
    ])(
      "DELETE needs a recent sign-in (%s auth time)",
      async (_label, authAgeSeconds) => {
        const a = newCaller(authAgeSeconds);
        const id = await enrol(a, "ck", "learn_only");
        expectCoded(
          await call(a, "DELETE", `/v1/enrolments/${id}`, DELETE_BODY),
          401,
          "recent_authentication_required",
        );
        expect(fake.table("enrolments").some((r) => r.id === id)).toBe(true);
      },
    );

    it("refuses new enrolments and rejoining once account deletion started", async () => {
      const c = newCaller();
      const id = await enrol(c, "sd");
      expect(
        (await call(c, "PATCH", `/v1/enrolments/${id}`, { status: "left" }))
          .statusCode,
      ).toBe(200);
      fake.startAccountDeletion(c.id);
      expectCoded(
        await call(c, "PATCH", `/v1/enrolments/${id}`, { status: "focus" }),
        409,
        "account_deletion_in_progress",
      );
      expectCoded(
        await call(c, "POST", "/v1/enrolments", {
          programmeCode: "nu",
          status: "learn_only",
        }),
        409,
        "account_deletion_in_progress",
      );
      expect(fake.table("enrolments").find((r) => r.id === id)?.status).toBe(
        "left",
      );
    });
  });

  describe("consents", () => {
    it("stores and returns version and text exactly as supplied", async () => {
      const a = newCaller();
      const id = await enrol(a, "ca");
      const response = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: id,
        purpose: "core",
        consentVersion: "2026-10.core_v1",
        consentText: CORE_TEXT,
      });
      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        enrolmentId: id,
        purpose: "core",
        recipientRef: null,
        consentVersion: "2026-10.core_v1",
        consentText: CORE_TEXT,
        revokedAt: null,
      });
      const stored = fake
        .table("programme_consents")
        .find((r) => r.enrolment_id === id);
      expect(stored?.consent_version).toBe("2026-10.core_v1");
      expect(stored?.consent_text).toBe(CORE_TEXT);
    });

    it("treats a second live grant as already granted (409), keeping the first", async () => {
      const a = newCaller();
      const id = await enrol(a, "st");
      const first = await grant(a, id, "core");
      const second = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: id,
        purpose: "core",
        consentVersion: "v2",
        consentText: `Different wording ${CANARY}`,
      });
      expectCoded(second, 409, "consent_already_granted");
      expect(second.body).not.toContain(CANARY);
      const live = fake
        .table("programme_consents")
        .filter((r) => r.enrolment_id === id && r.revoked_at === null);
      expect(live.map((r) => r.id)).toEqual([first]);
    });

    it("requires a live core consent before optional consents", async () => {
      const a = newCaller();
      const id = await enrol(a, "re");
      expectCoded(
        await call(a, "POST", "/v1/enrolments/consents", {
          enrolmentId: id,
          purpose: "records_import",
          consentVersion: "v1",
          consentText: "Synthetic records wording",
        }),
        409,
        "core_consent_required",
      );
      await grant(a, id, "core");
      await grant(a, id, "records_import");
    });

    it.each([
      [
        "a recipient on a non-share purpose",
        { purpose: "core", recipientRef: randomUUID() },
      ],
      [
        "a recipient that is not a UUID",
        { purpose: "share_care_team", recipientRef: "synthetic-clinic-01" },
      ],
      ["a null recipient", { purpose: "core", recipientRef: null }],
      ["a bad version", { purpose: "core", consentVersion: "v 1" }],
      ["empty text", { purpose: "core", consentText: "" }],
      ["text over 8000", { purpose: "core", consentText: "x".repeat(8001) }],
      ["an unknown purpose", { purpose: "marketing" }],
      ["an unknown field", { purpose: "core", grantedAt: "2020-01-01" }],
      ["a revoked_at", { purpose: "core", revokedAt: "2020-01-01" }],
    ])("POST refuses %s", async (_label, overrides) => {
      const a = newCaller();
      const id = await enrol(a, "nu");
      const response = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: id,
        consentVersion: "v1",
        consentText: "Synthetic wording",
        ...overrides,
      });
      expectUncoded(response, 400);
      expect(
        fake.table("programme_consents").some((r) => r.enrolment_id === id),
      ).toBe(false);
    });

    it.each([
      ["share_care_team", { recipientRef: randomUUID() }],
      ["share_caregiver", { recipientRef: randomUUID() }],
      ["share_care_team", {}],
      ["share_caregiver", {}],
    ])(
      "refuses %s with sharing_not_available until care connections exist",
      async (purpose, extra) => {
        const a = newCaller();
        const id = await enrol(a, "hw");
        await grant(a, id, "core");
        expectCoded(
          await call(a, "POST", "/v1/enrolments/consents", {
            enrolmentId: id,
            purpose,
            consentVersion: "v1",
            consentText: "Synthetic sharing wording",
            ...extra,
          }),
          409,
          "sharing_not_available",
        );
        expect(
          fake
            .table("programme_consents")
            .filter((r) => r.enrolment_id === id)
            .map((r) => r.purpose),
        ).toEqual(["core"]);
      },
    );

    it("refuses grants once account deletion started (consent_not_permitted)", async () => {
      const a = newCaller();
      const withCore = await enrol(a, "re", "learn_only");
      const withoutCore = await enrol(a, "nu", "learn_only");
      await grant(a, withCore, "core");
      fake.startAccountDeletion(a.id);
      for (const [enrolmentId, purpose] of [
        [withoutCore, "core"],
        [withCore, "research"],
      ]) {
        expectCoded(
          await call(a, "POST", "/v1/enrolments/consents", {
            enrolmentId,
            purpose,
            consentVersion: "v1",
            consentText: `Synthetic wording ${CANARY}`,
          }),
          409,
          "consent_not_permitted",
        );
      }
      expect(
        fake
          .table("programme_consents")
          .filter((r) =>
            [withCore, withoutCore].includes(r.enrolment_id as string),
          )
          .map((r) => r.purpose),
      ).toEqual(["core"]);
    });

    it("GET lists every live consent and no revoked ones", async () => {
      const a = newCaller();
      const id = await enrol(a, "bf", "focus", "quit");
      const optional = [
        "reminders",
        "records_import",
        "research",
        "screen_time",
      ];
      const core = await grant(a, id, "core");
      const granted = [core];
      for (const purpose of optional) granted.push(await grant(a, id, purpose));
      const research = granted[optional.indexOf("research") + 1] as string;
      const revoked = await call(
        a,
        "PATCH",
        `/v1/enrolments/consents/${research}`,
        { revoked: true },
      );
      expect(revoked.statusCode).toBe(200);

      const listed = await call(a, "GET", "/v1/enrolments");
      const [enrolment] = listed.json<{
        enrolments: { consents: { id: string; revokedAt: unknown }[] }[];
      }>().enrolments;
      expect(enrolment?.consents.map((c) => c.id)).toEqual(
        granted.filter((consentId) => consentId !== research),
      );
      expect(enrolment?.consents.every((c) => c.revokedAt === null)).toBe(true);
    });

    it("GET fails rather than returning a list cut short by a server row limit", async () => {
      const a = newCaller();
      const id = await enrol(a, "ca", "learn_only");
      await grant(a, id, "core");
      await grant(a, id, "reminders");
      fake.maxRows = 1;
      try {
        expectUncoded(await call(a, "GET", "/v1/enrolments"), 502);
      } finally {
        fake.maxRows = null;
      }
      expect((await call(a, "GET", "/v1/enrolments")).statusCode).toBe(200);
    });

    it("revokes only, once; revoking core revokes the rest", async () => {
      const a = newCaller();
      const id = await enrol(a, "ck");
      const core = await grant(a, id, "core");
      const research = await grant(a, id, "research");

      expectUncoded(
        await call(a, "PATCH", `/v1/enrolments/consents/${research}`, {
          revoked: false,
        }),
        400,
      );
      expectUncoded(
        await call(a, "PATCH", `/v1/enrolments/consents/${research}`, {
          revoked: true,
          consentText: "rewritten",
        }),
        400,
      );

      const revoked = await call(
        a,
        "PATCH",
        `/v1/enrolments/consents/${core}`,
        {
          revoked: true,
        },
      );
      expect(revoked.statusCode).toBe(200);
      expect(revoked.json()).toMatchObject({ id: core, purpose: "core" });
      expect(
        revoked.json<{ revokedAt: string | null }>().revokedAt,
      ).not.toBeNull();
      expect(
        fake.table("programme_consents").find((r) => r.id === research)
          ?.revoked_at,
      ).not.toBeNull();

      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/consents/${core}`, {
          revoked: true,
        }),
        409,
        "consent_already_revoked",
      );
      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/consents/${randomUUID()}`, {
          revoked: true,
        }),
        404,
        "consent_not_found",
      );
      // A fresh core grant after revocation is a new row; history stays.
      await grant(a, id, "core");
      expect(
        fake.table("programme_consents").filter((r) => r.enrolment_id === id),
      ).toHaveLength(3);
    });

    it("reports reconsentRequired when the live core version is not current", async () => {
      const a = newCaller();
      const old = await enrol(a, "sf", "learn_only");
      const current = await enrol(a, "be", "learn_only");
      const none = await enrol(a, "ea", "learn_only");
      await grant(a, old, "core", { consentVersion: "v0" });
      await grant(a, current, "core");
      const listed = await call(a, "GET", "/v1/enrolments");
      const byId = new Map(
        listed
          .json<{
            enrolments: { id: string; reconsentRequired: boolean }[];
          }>()
          .enrolments.map((e) => [e.id, e.reconsentRequired]),
      );
      expect(byId.get(old)).toBe(true);
      expect(byId.get(current)).toBe(false);
      expect(byId.get(none)).toBe(false);
    });
  });

  describe("database error codes", () => {
    /** An enrolment with a live core consent, ready for every route. */
    const prepared = async () => {
      const a = newCaller();
      const id = await enrol(a, "hw", "learn_only");
      const core = await grant(a, id, "core");
      return { a, id, core };
    };
    /**
     * Logged since `since`: only the global filter's request_failed line per
     * 502, never the database error's code, message or hint.
     */
    const expectNotLogged = (since: number, error: PgError, failures = 1) => {
      const lines = logged.slice(since);
      expect(
        lines.filter((line) =>
          /request_failed .*type=BadGatewayException/.test(line),
        ),
      ).toHaveLength(failures);
      for (const detail of [error.code, error.message, error.hint]) {
        expect(lines.join("\n")).not.toContain(detail);
      }
    };
    /** Every injected failure was consumed and nothing was written. */
    const expectRolledBack = (id: string, core: string) => {
      expect(fake.pendingFailures).toBe(0);
      expect(fake.table("enrolments").find((r) => r.id === id)).toMatchObject({
        status: "learn_only",
      });
      expect(
        fake.table("programme_consents").find((r) => r.id === core),
      ).toMatchObject({ revoked_at: null });
    };

    it("revoke maps TH002 to consent_already_revoked", async () => {
      const { a, id, core } = await prepared();
      fake.failNext(
        "PATCH",
        "programme_consents",
        registryError("consent_already_revoked"),
      );
      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/consents/${core}`, {
          revoked: true,
        }),
        409,
        "consent_already_revoked",
      );
      expectRolledBack(id, core);
    });

    // The trigger refused the change, so the consent is still live: it is
    // never reported as revoked.
    it.each([0, 1])(
      "revoke fails closed on TH003 (message %d), never reporting it as revoked",
      async (messageIndex) => {
        const { a, id, core } = await prepared();
        const error = registryError("consent_immutable", messageIndex);
        const since = logged.length;
        fake.failNext("PATCH", "programme_consents", error);
        const response = await call(
          a,
          "PATCH",
          `/v1/enrolments/consents/${core}`,
          { revoked: true },
        );
        expectUncoded(response, 502);
        for (const detail of [error.code, error.message, error.hint]) {
          expect(response.body).not.toContain(detail);
        }
        expectRolledBack(id, core);
        expectNotLogged(since, error);
      },
    );

    it.each([
      ["consent_already_revoked", 0],
      ["consent_immutable", 0],
      ["consent_immutable", 1],
    ] as [DatabaseErrorHint, number][])(
      "enrolment update maps %s (message %d) to enrolment_conflict",
      async (hint, messageIndex) => {
        const { a, id, core } = await prepared();
        fake.failNext("PATCH", "enrolments", registryError(hint, messageIndex));
        expectCoded(
          await call(a, "PATCH", `/v1/enrolments/${id}`, { status: "left" }),
          409,
          "enrolment_conflict",
        );
        expectRolledBack(id, core);
      },
    );

    it("create and update map TH001 to focus_cap_reached", async () => {
      const { a, id, core } = await prepared();
      fake.failNext("POST", "enrolments", registryError("focus_cap_reached"));
      expectCoded(
        await call(a, "POST", "/v1/enrolments", {
          programmeCode: "st",
          status: "focus",
        }),
        409,
        "focus_cap_reached",
      );
      fake.failNext("PATCH", "enrolments", registryError("focus_cap_reached"));
      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/${id}`, { status: "focus" }),
        409,
        "focus_cap_reached",
      );
      expectRolledBack(id, core);
    });

    // Every other TH code, raised or reserved, and one not in the registry.
    const unmapped: PgError[] = [
      ...DATABASE_ERRORS.filter(
        (entry) =>
          !["TH001", "TH002", "TH003"].includes(entry.code) &&
          entry.messages.length > 0,
      ).map((entry) => registryError(entry.hint)),
      ...DATABASE_ERRORS.filter((entry) => entry.messages.length === 0).map(
        (entry) => ({
          status: 400,
          code: entry.code,
          message: `Synthetic ${entry.hint} message`,
          hint: entry.hint,
        }),
      ),
      {
        status: 400,
        code: "TH999",
        message: "Synthetic unregistered rule",
        hint: "synthetic_unregistered",
      },
    ];

    it.each(unmapped.map((error) => [error.code, error] as const))(
      "every route fails closed on %s without echoing it",
      async (_code, error) => {
        const { a, id, core } = await prepared();
        const routes: [Method, string, string, unknown][] = [
          [
            "POST",
            "enrolments",
            "/v1/enrolments",
            { programmeCode: "st", status: "focus" },
          ],
          ["PATCH", "enrolments", `/v1/enrolments/${id}`, { status: "paused" }],
          [
            "POST",
            "programme_consents",
            "/v1/enrolments/consents",
            {
              enrolmentId: id,
              purpose: "research",
              consentVersion: "v1",
              consentText: "Synthetic research wording",
            },
          ],
          [
            "PATCH",
            "programme_consents",
            `/v1/enrolments/consents/${core}`,
            { revoked: true },
          ],
          ["DELETE", "enrolments", `/v1/enrolments/${id}`, DELETE_BODY],
        ];
        const since = logged.length;
        for (const [method, table, url, payload] of routes) {
          fake.failNext(method, table, error);
          const response = await call(a, method, url, payload);
          expectUncoded(response, 502);
          expect(fake.pendingFailures).toBe(0);
          for (const detail of [error.code, error.message, error.hint]) {
            expect(response.body).not.toContain(detail);
          }
        }
        expectRolledBack(id, core);
        expectNotLogged(since, error, routes.length);
      },
    );

    it("does not take message text or hint under another code for a TH rule", async () => {
      const { a, id, core } = await prepared();
      const lookalike = (code: string, hint: DatabaseErrorHint): PgError => ({
        status: 400,
        code,
        message: databaseError(hint).messages[0] as string,
        hint,
      });
      // Focus-cap text under the generic check-violation code: create has no
      // mapping for 23514, update treats it as an ordinary check constraint.
      fake.failNext(
        "POST",
        "enrolments",
        lookalike("23514", "focus_cap_reached"),
      );
      expectUncoded(
        await call(a, "POST", "/v1/enrolments", {
          programmeCode: "st",
          status: "focus",
        }),
        502,
      );
      fake.failNext(
        "PATCH",
        "enrolments",
        lookalike("23514", "focus_cap_reached"),
      );
      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/${id}`, { status: "focus" }),
        409,
        "enrolment_conflict",
      );
      // The same text under raise's default code P0001.
      fake.failNext(
        "PATCH",
        "enrolments",
        lookalike("P0001", "focus_cap_reached"),
      );
      expectUncoded(
        await call(a, "PATCH", `/v1/enrolments/${id}`, { status: "focus" }),
        502,
      );
      // Already-revoked text under 23514 is no longer the revoke-only rule.
      fake.failNext(
        "PATCH",
        "programme_consents",
        lookalike("23514", "consent_already_revoked"),
      );
      expectUncoded(
        await call(a, "PATCH", `/v1/enrolments/consents/${core}`, {
          revoked: true,
        }),
        502,
      );
      expectRolledBack(id, core);
    });
  });

  describe("cross-user isolation", () => {
    it("user B cannot read, change or delete user A's enrolment or consents", async () => {
      const a = newCaller();
      const b = newCaller();
      const enrolment = await enrol(a, "ea", "focus");
      const core = await grant(a, enrolment, "core");
      const before = fake.table("enrolments").find((r) => r.id === enrolment);
      const firstRequest = fake.requests.length;

      // Read: B's list has none of A's rows.
      const listed = await call(b, "GET", "/v1/enrolments");
      expect(listed.statusCode).toBe(200);
      expect(listed.json()).toEqual({
        currentCoreConsentVersion: CURRENT_CORE_CONSENT_VERSION,
        enrolments: [],
      });
      expect(listed.body).not.toContain(enrolment);
      expect(listed.body).not.toContain(core);

      // Change: status, mode and leaving are all not found for B.
      for (const change of [{ status: "left" }, { status: "paused" }]) {
        expectCoded(
          await call(b, "PATCH", `/v1/enrolments/${enrolment}`, change),
          404,
          "enrolment_not_found",
        );
      }
      // Delete now.
      expectCoded(
        await call(b, "DELETE", `/v1/enrolments/${enrolment}`, DELETE_BODY),
        404,
        "enrolment_not_found",
      );
      // Consents: B can neither add to A's enrolment nor revoke A's consent.
      expectCoded(
        await call(b, "POST", "/v1/enrolments/consents", {
          enrolmentId: enrolment,
          purpose: "core",
          consentVersion: "v1",
          consentText: "Synthetic core wording",
        }),
        404,
        "enrolment_not_found",
      );
      expectCoded(
        await call(b, "PATCH", `/v1/enrolments/consents/${core}`, {
          revoked: true,
        }),
        404,
        "consent_not_found",
      );

      // A's data is unchanged.
      expect(fake.table("enrolments").find((r) => r.id === enrolment)).toEqual(
        before,
      );
      const consents = fake
        .table("programme_consents")
        .filter((r) => r.enrolment_id === enrolment);
      expect(consents).toHaveLength(1);
      expect(consents[0]?.revoked_at).toBeNull();

      // Every database request made for B carried B's own token.
      const forB = fake.requests.slice(firstRequest);
      expect(forB.length).toBeGreaterThan(0);
      expect(forB.every((request) => request.token === b.token)).toBe(true);

      // A still sees everything.
      const own = await call(a, "GET", "/v1/enrolments");
      expect(own.json()).toMatchObject({
        enrolments: [{ id: enrolment, consents: [{ id: core }] }],
      });
    });
  });

  it("never logs or echoes submitted health data", async () => {
    const a = newCaller();
    const id = await enrol(a, "bf");
    await call(a, "POST", "/v1/enrolments/consents", {
      enrolmentId: id,
      purpose: "core",
      consentVersion: "v1",
      consentText: CANARY,
      note: CANARY,
    });
    await call(a, "PATCH", `/v1/enrolments/${id}`, { mode: CANARY });
    expect(logged.join("\n")).not.toContain(CANARY);
  });

  it("never logs a bearer token or database error details", async () => {
    const a = newCaller();
    const id = await enrol(a, "sd", "learn_only");
    await grant(a, id, "core");
    // A database constraint error (details carry DB_CANARY) ...
    expectCoded(
      await call(a, "POST", "/v1/enrolments", {
        programmeCode: "sd",
        status: "learn_only",
      }),
      409,
      "already_enrolled",
    );
    // ... and a logged 5xx.
    const before = logged.length;
    fake.maxRows = 0;
    try {
      expectUncoded(await call(a, "GET", "/v1/enrolments"), 502);
    } finally {
      fake.maxRows = null;
    }
    expect(logged.length).toBeGreaterThan(before);
    const lines = logged.join("\n");
    expect(lines).not.toContain(TOKEN_CANARY);
    expect(lines).not.toContain(a.token);
    expect(lines).not.toContain(DB_CANARY);
  });
});
