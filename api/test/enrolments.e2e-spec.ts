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
import { UserSupabaseClientFactory } from "../src/enrolments/user-supabase-client";
import {
  DATABASE_ERRORS,
  databaseError,
  type DatabaseErrorHint,
} from "./support/database-errors";
import {
  CONSENT_DOCUMENTS,
  DB_CANARY,
  FakePostgrest,
  registryError,
  type PgError,
} from "./support/fake-postgrest";
import { openApiErrors, openApiSchemaNames } from "./support/openapi";

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
 * - D1: the fake evaluates writes in Postgres executor order: before-row
 *   triggers, RLS WITH CHECK, CHECK constraints, unique keys, then foreign
 *   keys.
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
 * - Consent documents are the fake's seeded CONSENT_DOCUMENTS: the current
 *   core version is v2-synthetic in both locales; v1-draft is grantable for
 *   every purpose. One test retires the es core documents and restores
 *   the seed in a finally block. A race that Postgres resolves after a
 *   lock wait is emulated with interleave (the other transaction commits)
 *   plus failNext (the error this request then gets).
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
/** Every seeded version is synthetic; v1-draft exists for every purpose. */
const SHOWN = { consentVersion: "v1-draft", locale: "en" };
/** The current core version in en; es has a later one of its own. */
const CURRENT_CORE = "v2-synthetic";
const CURRENT_CORE_ES = "v3-synthetic";
const CURRENT_VERSIONS = { en: CURRENT_CORE, es: CURRENT_CORE_ES };
const documentBody = (purpose: string, version: string, locale: string) => {
  const found = CONSENT_DOCUMENTS.find(
    (doc) =>
      doc.purpose === purpose &&
      doc.version === version &&
      doc.locale === locale,
  );
  if (!found) throw new Error(`no document ${purpose}/${version}/${locale}`);
  return found.body;
};

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
      ...SHOWN,
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
    expect(openApiErrors("CodedRequestRejected", body)).toEqual([]);
  };

  /** The response body matches components.schemas[name] in openapi.yaml. */
  const expectSchema = (response: { json: () => unknown }, name: string) => {
    expect(openApiErrors(name, response.json())).toEqual([]);
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
    expect(openApiErrors("RequestRejected", body)).toEqual([]);
  };

  describe("authentication", () => {
    const id = "00000000-0000-4000-8000-000000000001";
    it.each([
      ["GET", "/v1/enrolments", undefined],
      ["POST", "/v1/enrolments", { programmeCode: "bf", status: "focus" }],
      ["PATCH", `/v1/enrolments/${id}`, { status: "paused" }],
      ["DELETE", `/v1/enrolments/${id}`, DELETE_BODY],
      ["POST", "/v1/enrolments/consents", {}],
      [
        "POST",
        "/v1/enrolments/focus-swap",
        { demoteId: id, promoteId: randomUUID() },
      ],
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
        currentCoreConsentVersions: CURRENT_VERSIONS,
        enrolments: [created.json()],
      });
      expect(created.json()).toMatchObject({ currentCoreConsentVersion: null });
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
          ...SHOWN,
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
    it("records the version and locale shown; the database fills the text", async () => {
      const a = newCaller();
      const id = await enrol(a, "ca");
      const since = fake.requests.length;
      // v1-draft is not the current core version: the API records what the
      // app showed and never substitutes the current one.
      const response = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: id,
        purpose: "core",
        consentVersion: "v1-draft",
        locale: "es",
      });
      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        enrolmentId: id,
        purpose: "core",
        recipientRef: null,
        consentVersion: "v1-draft",
        locale: "es",
        consentText: documentBody("core", "v1-draft", "es"),
        revokedAt: null,
        supersededId: null,
      });
      // The outgoing insert carries the version and locale, never the text.
      const inserts = fake.requests
        .slice(since)
        .filter(
          (r) =>
            r.method === "POST" &&
            r.path.endsWith("/rest/v1/programme_consents"),
        );
      expect(inserts.map((r) => r.body)).toEqual([
        {
          enrolment_id: id,
          purpose: "core",
          recipient_ref: null,
          consent_version: "v1-draft",
          locale: "es",
        },
      ]);
      const stored = fake
        .table("programme_consents")
        .find((r) => r.enrolment_id === id);
      expect(stored).toMatchObject({
        consent_version: "v1-draft",
        locale: "es",
        consent_text: documentBody("core", "v1-draft", "es"),
      });
    });

    it.each([
      ["an unknown version", "core", "v1", "en"],
      ["a retired version", "core", "v0-retired", "en"],
      ["a version not yet in effect", "core", "v9-future", "en"],
      ["a version that lacks this locale", "core", "v9-future", "es"],
      ["a version of another purpose", "reminders", "v2-synthetic", "en"],
    ])(
      "maps %s to consent_document_unavailable (TH011)",
      async (_label, purpose, consentVersion, locale) => {
        const a = newCaller();
        const id = await enrol(a, "sd", "learn_only");
        if (purpose !== "core") await grant(a, id, "core");
        expectCoded(
          await call(a, "POST", "/v1/enrolments/consents", {
            enrolmentId: id,
            purpose,
            consentVersion,
            locale,
          }),
          409,
          "consent_document_unavailable",
        );
        expect(
          fake
            .table("programme_consents")
            .filter((r) => r.enrolment_id === id && r.purpose === purpose),
        ).toHaveLength(0);
      },
    );

    it("treats a second live grant of the same document as already granted (409), keeping the first", async () => {
      const a = newCaller();
      const id = await enrol(a, "st");
      const first = await grant(a, id, "core");
      const reminders = await grant(a, id, "reminders");
      for (const purpose of ["core", "reminders"]) {
        const second = await call(a, "POST", "/v1/enrolments/consents", {
          enrolmentId: id,
          purpose,
          ...SHOWN,
        });
        expectCoded(second, 409, "consent_already_granted");
      }
      const live = fake
        .table("programme_consents")
        .filter((r) => r.enrolment_id === id && r.revoked_at === null);
      expect(live.map((r) => r.id)).toEqual([first, reminders]);
    });

    it("requires a live core consent before optional consents", async () => {
      const a = newCaller();
      const id = await enrol(a, "re");
      expectCoded(
        await call(a, "POST", "/v1/enrolments/consents", {
          enrolmentId: id,
          purpose: "records_import",
          ...SHOWN,
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
      ["a missing version", { purpose: "core", consentVersion: undefined }],
      // The database fills the text; a client-supplied text is refused.
      [
        "consentText",
        {
          purpose: "core",
          consentText: "Synthetic wording the API must not send",
        },
      ],
      ["a missing locale", { purpose: "core", locale: undefined }],
      ["a null locale", { purpose: "core", locale: null }],
      ["an unknown locale", { purpose: "core", locale: "fr" }],
      ["an unknown purpose", { purpose: "marketing" }],
      ["an unknown field", { purpose: "core", grantedAt: "2020-01-01" }],
      ["a revoked_at", { purpose: "core", revokedAt: "2020-01-01" }],
    ])("POST refuses %s", async (_label, overrides) => {
      const a = newCaller();
      const id = await enrol(a, "nu");
      const since = fake.requests.length;
      const response = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: id,
        ...SHOWN,
        ...overrides,
      });
      expectUncoded(response, 400);
      expect(fake.requests.length).toBe(since);
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
            ...SHOWN,
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

    it("refuses grants once account deletion started (account_deletion_in_progress)", async () => {
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
            ...SHOWN,
          }),
          409,
          "account_deletion_in_progress",
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

    // The same 42501 for another of the insert policy's checks (here the
    // enrolment was left by a concurrent request) is not the barrier.
    it("answers consent_not_permitted when the insert policy refuses for another reason", async () => {
      const a = newCaller();
      const id = await enrol(a, "sd", "learn_only");
      await grant(a, id, "core");
      fake.interleave("POST", "programme_consents", () => {
        fake.forceEnrolmentStatus(id, "left");
      });
      const since = fake.requests.length;
      expectCoded(
        await call(a, "POST", "/v1/enrolments/consents", {
          enrolmentId: id,
          purpose: "research",
          ...SHOWN,
        }),
        409,
        "consent_not_permitted",
      );
      expect(
        fake.requests
          .slice(since)
          .some((r) => r.path.endsWith("/rpc/deletion_barrier_open")),
      ).toBe(true);
      expect(
        fake
          .table("programme_consents")
          .filter((r) => r.enrolment_id === id)
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
      // Only a live row may match the revoking update.
      const patch = fake.requests.findLast(
        (r) => r.method === "PATCH" && r.path.endsWith("/programme_consents"),
      );
      const filters = new URLSearchParams(patch?.search);
      expect(filters.get("id")).toBe(`eq.${core}`);
      expect(filters.get("revoked_at")).toBe("is.null");
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

    it("reports the current core version per locale and reconsentRequired", async () => {
      const a = newCaller();
      const old = await enrol(a, "sf", "learn_only");
      const current = await enrol(a, "be", "learn_only");
      const currentEs = await enrol(a, "ck", "learn_only");
      const none = await enrol(a, "ea", "learn_only");
      const legacy = await enrol(a, "nu", "learn_only");
      const left = await enrol(a, "re", "learn_only");
      await grant(a, old, "core");
      await grant(a, current, "core", { consentVersion: CURRENT_CORE });
      await grant(a, currentEs, "core", {
        consentVersion: CURRENT_CORE_ES,
        locale: "es",
      });
      // The en current version given in es is not current there.
      const enVersionInEs = await enrol(a, "hw", "learn_only");
      await grant(a, enVersionInEs, "core", {
        consentVersion: CURRENT_CORE,
        locale: "es",
      });
      fake.addLegacyCoreConsent(legacy, CURRENT_CORE);
      await grant(a, left, "core");
      expect(
        (await call(a, "PATCH", `/v1/enrolments/${left}`, { status: "left" }))
          .statusCode,
      ).toBe(200);

      const listed = await call(a, "GET", "/v1/enrolments");
      const body = listed.json<{
        currentCoreConsentVersions: unknown;
        enrolments: {
          id: string;
          currentCoreConsentVersion: string | null;
          reconsentRequired: boolean;
        }[];
      }>();
      expect(body.currentCoreConsentVersions).toEqual(CURRENT_VERSIONS);
      const byId = new Map(
        body.enrolments.map((e) => [
          e.id,
          [e.currentCoreConsentVersion, e.reconsentRequired],
        ]),
      );
      expect(byId.get(old)).toEqual([CURRENT_CORE, true]);
      expect(byId.get(current)).toEqual([CURRENT_CORE, false]);
      expect(byId.get(currentEs)).toEqual([CURRENT_CORE_ES, false]);
      expect(byId.get(enVersionInEs)).toEqual([CURRENT_CORE_ES, true]);
      expect(byId.get(none)).toEqual([null, false]);
      // Stored before consent documents existed (no locale): re-consent is
      // offered in the member's profile locale, which has a current document.
      expect(byId.get(legacy)).toEqual([CURRENT_CORE, true]);
      fake.setProfileLocale(a.id, "es");
      const since = fake.requests.length;
      const relisted = await call(a, "GET", "/v1/enrolments");
      expect(
        relisted
          .json<{
            enrolments: { id: string; currentCoreConsentVersion: unknown }[];
          }>()
          .enrolments.find((e) => e.id === legacy)?.currentCoreConsentVersion,
      ).toBe(CURRENT_CORE_ES);
      expect(
        fake.requests
          .slice(since)
          .some((r) => r.method === "GET" && r.path.endsWith("/profiles")),
      ).toBe(true);
      expect(byId.get(left)).toEqual([CURRENT_CORE, false]);
    });
    // Seeded for this case only: every core document in es is retired, so
    // es has no current core version (en keeps its own).
    it("offers no re-consent when no current core document exists for the member's locale", async () => {
      const a = newCaller();
      const inEs = await enrol(a, "ea", "learn_only");
      const inEn = await enrol(a, "sd", "learn_only");
      const core = await grant(a, inEs, "core", { locale: "es" });
      await grant(a, inEn, "core");
      fake.retireConsentDocuments("core", "es");
      try {
        const listed = await call(a, "GET", "/v1/enrolments");
        expect(listed.statusCode).toBe(200);
        expectSchema(listed, "EnrolmentList");
        const body = listed.json<{
          currentCoreConsentVersions: unknown;
          enrolments: { id: string }[];
        }>();
        expect(body.currentCoreConsentVersions).toEqual({
          en: CURRENT_CORE,
          es: null,
        });
        expect(body.enrolments.find((e) => e.id === inEs)).toMatchObject({
          currentCoreConsentVersion: null,
          reconsentRequired: false,
        });
        // The en enrolment still has a current document to re-consent to.
        expect(body.enrolments.find((e) => e.id === inEn)).toMatchObject({
          currentCoreConsentVersion: CURRENT_CORE,
          reconsentRequired: true,
        });
        expectCoded(
          await call(a, "POST", "/v1/enrolments/consents", {
            enrolmentId: inEs,
            purpose: "core",
            consentVersion: CURRENT_CORE_ES,
            locale: "es",
          }),
          409,
          "consent_document_unavailable",
        );
        const live = fake
          .table("programme_consents")
          .filter((r) => r.enrolment_id === inEs && r.revoked_at === null);
        expect(live.map((r) => r.id)).toEqual([core]);
      } finally {
        fake.resetConsentDocuments();
      }
    });
  });

  describe("core re-consent (supersession)", () => {
    /** An enrolment with a live core consent on v1-draft/en and reminders. */
    const onDraft = async () => {
      const a = newCaller();
      const id = await enrol(a, "hw", "learn_only");
      const core = await grant(a, id, "core");
      const reminders = await grant(a, id, "reminders");
      return { a, id, core, reminders };
    };
    const reconsent = (a: Caller, id: string, version: string, locale = "en") =>
      call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: id,
        purpose: "core",
        consentVersion: version,
        locale,
      });
    const rows = (id: string) =>
      fake.table("programme_consents").filter((r) => r.enrolment_id === id);

    it("supersedes the live core through supersede_core_consent, keeping optional consents", async () => {
      const { a, id, core, reminders } = await onDraft();
      const since = fake.requests.length;
      const response = await reconsent(a, id, CURRENT_CORE);
      expect(response.statusCode).toBe(201);
      const body = response.json<{ id: string }>();
      expect(body).toMatchObject({
        enrolmentId: id,
        purpose: "core",
        consentVersion: CURRENT_CORE,
        locale: "en",
        consentText: documentBody("core", CURRENT_CORE, "en"),
        revokedAt: null,
        supersededId: core,
      });
      // One function call; no direct revoke (PATCH) or insert (POST) of rows.
      const writes = fake.requests
        .slice(since)
        .filter((r) => r.method !== "GET")
        .map((r) => `${r.method} ${r.path.replace("/rest/v1/", "")}`);
      expect(writes).toEqual(["POST rpc/supersede_core_consent"]);
      expect(fake.requests.slice(since).at(-1)?.body).toEqual({
        p_enrolment: id,
        p_version: CURRENT_CORE,
        p_locale: "en",
      });
      const old = rows(id).find((r) => r.id === core);
      expect(old?.revoked_at).not.toBeNull();
      expect(old?.superseded_by).toBe(body.id);
      expect(rows(id).find((r) => r.id === reminders)?.revoked_at).toBeNull();

      const listed = await call(a, "GET", "/v1/enrolments");
      expect(listed.json()).toMatchObject({
        enrolments: [
          {
            id,
            currentCoreConsentVersion: CURRENT_CORE,
            reconsentRequired: false,
            consents: [{ id: reminders }, { id: body.id }],
          },
        ],
      });
    });

    it("moves to another locale of the same version", async () => {
      const { a, id, core } = await onDraft();
      const response = await reconsent(a, id, "v1-draft", "es");
      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        consentVersion: "v1-draft",
        locale: "es",
        consentText: documentBody("core", "v1-draft", "es"),
        supersededId: core,
      });
    });

    it("maps TH014 to consent_version_unchanged (not later than the live one)", async () => {
      const { a, id } = await onDraft();
      const current = await reconsent(a, id, CURRENT_CORE);
      expect(current.statusCode).toBe(201);
      const before = rows(id);
      for (const [version, locale] of [
        ["v1-draft", "en"],
        ["v1-draft", "es"],
      ]) {
        expectCoded(
          await reconsent(a, id, version as string, locale),
          409,
          "consent_version_unchanged",
        );
      }
      expect(rows(id)).toEqual(before);
    });

    it("maps TH011 and TH006 from the function", async () => {
      const { a, id, core } = await onDraft();
      expectCoded(
        await reconsent(a, id, "v9-future"),
        409,
        "consent_document_unavailable",
      );
      fake.startAccountDeletion(a.id);
      expectCoded(
        await reconsent(a, id, CURRENT_CORE),
        409,
        "account_deletion_in_progress",
      );
      expect(rows(id).find((r) => r.id === core)?.revoked_at).toBeNull();
    });

    it("answers a double tap as the success it was, not core_consent_required", async () => {
      const { a, id, core, reminders } = await onDraft();
      let firstTap: { id: string } | undefined;
      // The first tap commits while the second waits for the row lock; the
      // second then finds no live core row to replace (TH004).
      fake.interleave("POST", "rpc/supersede_core_consent", () => {
        const [, created] = fake.supersedeCoreConsent(
          a.id,
          id,
          CURRENT_CORE,
          "en",
        );
        firstTap = created as { id: string };
      });
      fake.failNext(
        "POST",
        "rpc/supersede_core_consent",
        registryError("consent_requires_core"),
      );
      const response = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: id,
        purpose: "core",
        consentVersion: CURRENT_CORE,
        locale: "en",
      });
      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        id: firstTap?.id,
        consentVersion: CURRENT_CORE,
        locale: "en",
        supersededId: core,
      });
      // Exactly one supersession happened.
      const live = rows(id).filter((r) => r.revoked_at === null);
      expect(live.map((r) => r.id).sort()).toEqual(
        [firstTap?.id, reminders].sort(),
      );
      expect(rows(id).filter((r) => r.purpose === "core")).toHaveLength(2);
    });

    it("tries once more when another version became live meanwhile", async () => {
      const { a, id } = await onDraft();
      let meanwhile: { id: string } | undefined;
      fake.interleave("POST", "rpc/supersede_core_consent", () => {
        const [, created] = fake.supersedeCoreConsent(
          a.id,
          id,
          "v1-draft",
          "es",
        );
        meanwhile = created as { id: string };
      });
      fake.failNext(
        "POST",
        "rpc/supersede_core_consent",
        registryError("consent_requires_core"),
      );
      const response = await reconsent(a, id, CURRENT_CORE);
      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        consentVersion: CURRENT_CORE,
        locale: "en",
        supersededId: meanwhile?.id,
      });
    });

    // Not what was asked for after two lost races: one fail-closed conflict,
    // whatever is live. consent_version_unchanged would be wrong for a
    // locale-only move to the same version, which the database allows (R-29).
    it.each([
      ["a later version", [CURRENT_CORE, "en"], [CURRENT_CORE_ES, "es"]],
      [
        "the same version in another locale",
        [CURRENT_CORE, "en"],
        [CURRENT_CORE, "es"],
      ],
      ["an earlier version", [CURRENT_CORE_ES, "es"], [CURRENT_CORE, "en"]],
    ] as const)(
      "after the retry also loses a race to %s, answers consent_conflict_retry (two calls at most)",
      async (_label, [version, locale], [liveVersion, liveLocale]) => {
        const { a, id } = await onDraft();
        const since = fake.requests.length;
        // Meanwhile the live core moves to v1-draft/es (first call: TH004),
        // then to the final live version and locale (retry: TH004).
        fake.interleave("POST", "rpc/supersede_core_consent", () => {
          fake.supersedeCoreConsent(a.id, id, "v1-draft", "es");
        });
        fake.failNext(
          "POST",
          "rpc/supersede_core_consent",
          registryError("consent_requires_core"),
        );
        fake.interleave("POST", "rpc/supersede_core_consent", () => {
          fake.supersedeCoreConsent(a.id, id, liveVersion, liveLocale);
        });
        fake.failNext(
          "POST",
          "rpc/supersede_core_consent",
          registryError("consent_requires_core"),
        );
        expectCoded(
          await reconsent(a, id, version, locale),
          409,
          "consent_conflict_retry",
        );
        const sent = fake.requests.slice(since);
        expect(
          sent.filter((r) => r.path.endsWith("/rpc/supersede_core_consent")),
        ).toHaveLength(2);
        // Decided from the live row alone: no document is read.
        expect(sent.some((r) => r.path.endsWith("/consent_documents"))).toBe(
          false,
        );
        const live = rows(id).filter(
          (r) => r.purpose === "core" && r.revoked_at === null,
        );
        expect(live.map((r) => [r.consent_version, r.locale])).toEqual([
          [liveVersion, liveLocale],
        ]);
      },
    );

    it("refuses to revoke a superseded core id while a newer core is live", async () => {
      const { a, id, core, reminders } = await onDraft();
      const replacement = (await reconsent(a, id, CURRENT_CORE)).json<{
        id: string;
      }>().id;
      const before = rows(id);
      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/consents/${core}`, {
          revoked: true,
        }),
        409,
        "consent_superseded",
      );
      // Nothing changed: the newer core and the optional consents stay live.
      expect(rows(id)).toEqual(before);
      expect(
        rows(id)
          .filter((r) => r.revoked_at === null)
          .map((r) => r.id)
          .sort(),
      ).toEqual([replacement, reminders].sort());
      // Once the live core is revoked, the old id is simply revoked.
      expect(
        (
          await call(a, "PATCH", `/v1/enrolments/consents/${replacement}`, {
            revoked: true,
          })
        ).statusCode,
      ).toBe(200);
      expectCoded(
        await call(a, "PATCH", `/v1/enrolments/consents/${core}`, {
          revoked: true,
        }),
        409,
        "consent_already_revoked",
      );
    });
  });

  describe("focus swap", () => {
    const swap = (a: Caller, demoteId: string, promoteId: string) =>
      call(a, "POST", "/v1/enrolments/focus-swap", { demoteId, promoteId });
    const status = (id: string) =>
      fake.table("enrolments").find((r) => r.id === id)?.status;

    it("pauses the demoted programme and focuses the promoted one in one call", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf", "focus", "quit");
      const hw = await enrol(a, "hw");
      const st = await enrol(a, "st", "learn_only");
      const core = await grant(a, st, "core");
      const since = fake.requests.length;
      const response = await swap(a, bf, st);
      expect(response.statusCode).toBe(200);
      expect(response.json()).toMatchObject({
        demoted: { id: bf, status: "paused", mode: "quit", consents: [] },
        promoted: {
          id: st,
          status: "focus",
          consents: [{ id: core, purpose: "core" }],
          currentCoreConsentVersion: CURRENT_CORE,
          reconsentRequired: true,
        },
      });
      const writes = fake.requests
        .slice(since)
        .filter((r) => r.method !== "GET")
        .map((r) => `${r.method} ${r.path.replace("/rest/v1/", "")}`);
      expect(writes).toEqual(["POST rpc/swap_focus"]);
      expect(
        fake.requests.slice(since).find((r) => r.method === "POST")?.body,
      ).toEqual({ p_demote: bf, p_promote: st });
      expect([status(bf), status(hw), status(st)]).toEqual([
        "paused",
        "focus",
        "focus",
      ]);
    });

    it("maps TH013 to focus_swap_invalid and changes nothing", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      const hw = await enrol(a, "hw");
      const st = await enrol(a, "st", "paused");
      for (const [demote, promote] of [
        [st, bf], // demoted is not in focus
        [bf, hw], // promoted is already in focus
        [bf, bf], // the same enrolment
      ]) {
        expectCoded(
          await swap(a, demote as string, promote as string),
          409,
          "focus_swap_invalid",
        );
      }
      expect([status(bf), status(hw), status(st)]).toEqual([
        "focus",
        "focus",
        "paused",
      ]);
    });

    it("maps TH001, raised inside the call, to focus_cap_reached", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      await enrol(a, "hw");
      const st = await enrol(a, "st", "paused");
      const ca = await enrol(a, "ca", "paused");
      fake.failNext(
        "POST",
        "rpc/swap_focus",
        registryError("focus_cap_reached"),
      );
      expectCoded(await swap(a, bf, st), 409, "focus_cap_reached");
      // The fake's own swap_focus raising it: a third programme reached focus
      // concurrently (outside the cap), so the swap's cap check refuses.
      fake.interleave("POST", "rpc/swap_focus", () =>
        fake.forceEnrolmentStatus(ca, "focus"),
      );
      expectCoded(await swap(a, bf, st), 409, "focus_cap_reached");
      expect([status(bf), status(st)]).toEqual(["focus", "paused"]);
      fake.forceEnrolmentStatus(ca, "paused");
    });

    it("maps TH012 (not the caller's) and TH005 (promoting a left programme)", async () => {
      const a = newCaller();
      const b = newCaller();
      const bf = await enrol(a, "bf");
      const theirs = await enrol(b, "sf", "paused");
      expectCoded(await swap(a, bf, theirs), 404, "enrolment_not_found");
      expectCoded(await swap(a, bf, randomUUID()), 404, "enrolment_not_found");
      const left = await enrol(a, "ea", "paused");
      await call(a, "PATCH", `/v1/enrolments/${left}`, { status: "left" });
      expectCoded(await swap(a, bf, left), 409, "enrolment_left");
      expect([status(bf), status(theirs), status(left)]).toEqual([
        "focus",
        "paused",
        "left",
      ]);
    });

    it("accepts upper-case ids and returns both enrolments", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      await enrol(a, "hw");
      const st = await enrol(a, "st", "paused");
      const response = await swap(a, bf.toUpperCase(), st.toUpperCase());
      expect(response.statusCode).toBe(200);
      expectSchema(response, "FocusSwap");
      expect(response.json()).toMatchObject({
        demoted: { id: bf, status: "paused" },
        promoted: { id: st, status: "focus" },
      });
      expect([status(bf), status(st)]).toEqual(["paused", "focus"]);
    });

    it("reads everything before the swap: a failed read changes nothing, and nothing is read after it", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      await enrol(a, "hw");
      const st = await enrol(a, "st", "paused");
      await grant(a, st, "core");
      // (Not 503: supabase-js retries a GET on 503.)
      fake.failNext("GET", "programme_consents", {
        status: 500,
        code: "XX000",
        message: "Synthetic internal error",
        hint: null,
      });
      expectUncoded(await swap(a, bf, st), 502);
      expect([status(bf), status(st)]).toEqual(["focus", "paused"]);

      const since = fake.requests.length;
      expect((await swap(a, bf, st)).statusCode).toBe(200);
      const requests = fake.requests.slice(since);
      expect(requests.at(-1)?.path).toMatch(/\/rpc\/swap_focus$/);
      expect(
        requests.filter((r) => r.path.endsWith("/rpc/swap_focus")),
      ).toHaveLength(1);
    });

    it.each([
      ["a missing promoteId", { demoteId: randomUUID() }],
      ["a non-UUID id", { demoteId: randomUUID(), promoteId: "bf" }],
      [
        "an unknown field",
        { demoteId: randomUUID(), promoteId: randomUUID(), status: "focus" },
      ],
    ])("refuses %s (DTO whitelist)", async (_label, payload) => {
      const a = newCaller();
      const since = fake.requests.length;
      expectUncoded(
        await call(a, "POST", "/v1/enrolments/focus-swap", payload),
        400,
      );
      expect(fake.requests.length).toBe(since);
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

    // The codes the routes that call database functions (the consent grant,
    // including supersession, and the focus swap) map; see registryErrorFor.
    const FUNCTION_CODES = [
      "TH001",
      "TH004",
      "TH005",
      "TH006",
      "TH011",
      "TH012",
      "TH013",
      "TH014",
    ];

    it.each([
      ["TH001", 409, "focus_cap_reached"],
      ["TH004", 409, "core_consent_required"],
      ["TH005", 409, "enrolment_left"],
      ["TH006", 409, "account_deletion_in_progress"],
      ["TH011", 409, "consent_document_unavailable"],
      ["TH012", 404, "enrolment_not_found"],
      ["TH013", 409, "focus_swap_invalid"],
      ["TH014", 409, "consent_version_unchanged"],
    ] as const)(
      "the consent grant and the focus swap map %s to %d %s",
      async (code, status, token) => {
        const { a, id, core } = await prepared();
        const error = registryError(
          DATABASE_ERRORS.find((entry) => entry.code === code)
            ?.hint as DatabaseErrorHint,
        );
        const routes: [string, string, unknown][] = [
          [
            "programme_consents",
            "/v1/enrolments/consents",
            { enrolmentId: id, purpose: "research", ...SHOWN },
          ],
          [
            "rpc/swap_focus",
            "/v1/enrolments/focus-swap",
            { demoteId: id, promoteId: randomUUID() },
          ],
        ];
        // TH004 from the supersession is a lost race, handled by its own
        // tests (core re-consent); the others map like any function error.
        if (code !== "TH004") {
          routes.push([
            "rpc/supersede_core_consent",
            "/v1/enrolments/consents",
            {
              enrolmentId: id,
              purpose: "core",
              consentVersion: CURRENT_CORE,
              locale: "en",
            },
          ]);
        }
        for (const [path, url, payload] of routes) {
          fake.failNext("POST", path, error);
          expectCoded(await call(a, "POST", url, payload), status, token);
          expect(fake.pendingFailures).toBe(0);
        }
        expectRolledBack(id, core);
      },
    );

    // Every registry code, raised or reserved, and one not in the registry,
    // on every route that does not map it.
    const everyCode: PgError[] = [
      ...DATABASE_ERRORS.filter((entry) => entry.messages.length > 0).map(
        (entry) => registryError(entry.hint),
      ),
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

    it.each(everyCode.map((error) => [error.code, error] as const))(
      "every route that does not map %s fails closed without echoing it",
      async (code, error) => {
        const { a, id, core } = await prepared();
        // [method, path the error is injected on, route, body, codes mapped]
        const routes: [Method, string, Method, string, unknown, string[]][] = [
          [
            "GET",
            "rpc/current_consent_documents",
            "GET",
            "/v1/enrolments",
            undefined,
            [],
          ],
          [
            "POST",
            "enrolments",
            "POST",
            "/v1/enrolments",
            { programmeCode: "st", status: "focus" },
            ["TH001"],
          ],
          [
            "PATCH",
            "enrolments",
            "PATCH",
            `/v1/enrolments/${id}`,
            { status: "paused" },
            ["TH001", "TH002", "TH003"],
          ],
          [
            "POST",
            "programme_consents",
            "POST",
            "/v1/enrolments/consents",
            { enrolmentId: id, purpose: "research", ...SHOWN },
            FUNCTION_CODES,
          ],
          [
            "POST",
            "rpc/supersede_core_consent",
            "POST",
            "/v1/enrolments/consents",
            {
              enrolmentId: id,
              purpose: "core",
              consentVersion: CURRENT_CORE,
              locale: "en",
            },
            FUNCTION_CODES,
          ],
          [
            "POST",
            "rpc/swap_focus",
            "POST",
            "/v1/enrolments/focus-swap",
            { demoteId: id, promoteId: randomUUID() },
            FUNCTION_CODES,
          ],
          [
            "PATCH",
            "programme_consents",
            "PATCH",
            `/v1/enrolments/consents/${core}`,
            { revoked: true },
            ["TH002"],
          ],
          [
            "DELETE",
            "enrolments",
            "DELETE",
            `/v1/enrolments/${id}`,
            DELETE_BODY,
            [],
          ],
        ];
        const failing = routes.filter(
          ([, , , , , mapped]) => !mapped.includes(code),
        );
        const since = logged.length;
        for (const [method, path, routeMethod, url, payload] of failing) {
          fake.failNext(method, path, error);
          const response = await call(a, routeMethod, url, payload);
          expectUncoded(response, 502);
          expect(fake.pendingFailures).toBe(0);
          for (const detail of [error.code, error.message, error.hint]) {
            expect(response.body).not.toContain(detail);
          }
        }
        expectRolledBack(id, core);
        expectNotLogged(since, error, failing.length);
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

  describe("responses match docs/contracts/openapi.yaml", () => {
    it("every schema compiles under strict JSON Schema 2020-12", () => {
      expect(openApiSchemaNames.length).toBeGreaterThan(10);
      for (const name of openApiSchemaNames) {
        expect(() => openApiErrors(name, null)).not.toThrow();
      }
    });

    it("create, list, update, grant, supersede, swap and revoke", async () => {
      const a = newCaller();
      const created = await call(a, "POST", "/v1/enrolments", {
        programmeCode: "bf",
        status: "focus",
        mode: "quit",
      });
      expect(created.statusCode).toBe(201);
      expectSchema(created, "Enrolment");
      const bf = created.json<{ id: string }>().id;
      const st = await enrol(a, "st", "paused");

      const granted = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: st,
        purpose: "core",
        ...SHOWN,
      });
      expect(granted.statusCode).toBe(201);
      expectSchema(granted, "GrantedProgrammeConsent");
      const reminders = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: st,
        purpose: "reminders",
        ...SHOWN,
      });
      expectSchema(reminders, "GrantedProgrammeConsent");

      const superseded = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: st,
        purpose: "core",
        consentVersion: CURRENT_CORE,
        locale: "en",
      });
      expect(superseded.statusCode).toBe(201);
      expect(superseded.json()).toMatchObject({
        supersededId: granted.json<{ id: string }>().id,
      });
      expectSchema(superseded, "GrantedProgrammeConsent");

      const swapped = await call(a, "POST", "/v1/enrolments/focus-swap", {
        demoteId: bf,
        promoteId: st,
      });
      expect(swapped.statusCode).toBe(200);
      expectSchema(swapped, "FocusSwap");

      const updated = await call(a, "PATCH", `/v1/enrolments/${st}`, {
        mode: null,
      });
      expect(updated.statusCode).toBe(200);
      expectSchema(updated, "Enrolment");

      fake.addLegacyCoreConsent(bf, "v0");
      const listed = await call(a, "GET", "/v1/enrolments");
      expect(listed.statusCode).toBe(200);
      expectSchema(listed, "EnrolmentList");

      const revoked = await call(
        a,
        "PATCH",
        `/v1/enrolments/consents/${reminders.json<{ id: string }>().id}`,
        { revoked: true },
      );
      expect(revoked.statusCode).toBe(200);
      expectSchema(revoked, "ProgrammeConsent");
    });

    it("error bodies", async () => {
      const a = newCaller();
      const coded = await call(a, "PATCH", `/v1/enrolments/${randomUUID()}`, {
        status: "paused",
      });
      expect(coded.statusCode).toBe(404);
      expectSchema(coded, "CodedRequestRejected");
      const invalid = await call(a, "POST", "/v1/enrolments/focus-swap", {});
      expect(invalid.statusCode).toBe(400);
      expectSchema(invalid, "RequestRejected");
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
        currentCoreConsentVersions: CURRENT_VERSIONS,
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
          ...SHOWN,
        }),
        404,
        "enrolment_not_found",
      );
      // Nor supersede A's core consent, nor swap A's enrolment.
      expectCoded(
        await call(b, "POST", "/v1/enrolments/consents", {
          enrolmentId: enrolment,
          purpose: "core",
          consentVersion: CURRENT_CORE,
          locale: "en",
        }),
        404,
        "enrolment_not_found",
      );
      const own = await enrol(b, "bf", "paused");
      expectCoded(
        await call(b, "POST", "/v1/enrolments/focus-swap", {
          demoteId: enrolment,
          promoteId: own,
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
      const aList = await call(a, "GET", "/v1/enrolments");
      expect(aList.json()).toMatchObject({
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
      ...SHOWN,
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
