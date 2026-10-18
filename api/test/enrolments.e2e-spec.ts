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
import { FakePostgrest } from "./support/fake-postgrest";

/**
 * Enrolments and consents, end to end through the real Nest app, the real
 * auth guard, validation pipe and filters, the real services and the real
 * supabase-js client. Mocked: TokenVerifier (synthetic tokens map to
 * synthetic user ids) and the network below supabase-js, which is a fake
 * PostgREST (test/support/fake-postgrest.ts) that derives the user from the
 * request's bearer token and applies the TH-913 RLS policies, grants,
 * constraints and triggers.
 */

type Method = "DELETE" | "GET" | "PATCH" | "POST";

interface Caller {
  token: string;
  id: string;
}

const CANARY = "synthetic-canary-7c1e";
const CORE_TEXT =
  "  Synthetic core wording, línea dos —\n kept exactly (tabs\tand trailing space) ";

describe("Enrolments and consents API (e2e)", () => {
  let app: NestFastifyApplication;
  let fake: FakePostgrest;
  const users = new Map<string, string>();
  const logged: string[] = [];

  beforeAll(async () => {
    fake = new FakePostgrest();
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(TokenVerifier)
      .useValue({
        verify: (token: string) => {
          const sub = users.get(token);
          return sub
            ? Promise.resolve({ sub, authTime: Math.floor(Date.now() / 1000) })
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

  afterAll(async () => {
    jest.restoreAllMocks();
    await app.close();
  });

  let counter = 0;
  const newCaller = (): Caller => {
    counter += 1;
    const caller = {
      token: `synthetic-token-${counter}`,
      id: randomUUID(),
    };
    users.set(caller.token, caller.id);
    fake.addUser(caller.token, caller.id);
    return caller;
  };

  const call = (
    caller: Caller | null,
    method: Method,
    url: string,
    payload?: unknown,
  ) =>
    app.inject({
      method,
      url,
      headers: caller ? { authorization: `Bearer ${caller.token}` } : {},
      ...(payload === undefined ? {} : { payload: payload as object }),
    });

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
    expect(body).toMatchObject({ statusCode: status, code });
  };

  const expectUncoded = (
    response: { statusCode: number; json: () => unknown },
    status: number,
  ) => {
    expect(response.statusCode).toBe(status);
    expect(Object.keys(response.json() as object).sort()).toEqual(
      ["error", "requestId", "statusCode"].sort(),
    );
  };

  describe("authentication", () => {
    const id = "00000000-0000-4000-8000-000000000001";
    it.each([
      ["GET", "/v1/enrolments", undefined],
      ["POST", "/v1/enrolments", { programmeCode: "bf", status: "focus" }],
      ["PATCH", `/v1/enrolments/${id}`, { status: "paused" }],
      ["DELETE", `/v1/enrolments/${id}`, undefined],
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
      expect(
        leftBody.consents.find((c) => c.id === core)?.revokedAt,
      ).toBeNull();
      expect(
        leftBody.consents.find((c) => c.id === reminders)?.revokedAt,
      ).not.toBeNull();

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
      const response = await call(a, "DELETE", `/v1/enrolments/${id}`);
      expect(response.statusCode).toBe(204);
      expect(response.body).toBe("");
      expect(fake.table("enrolments").some((r) => r.id === id)).toBe(false);
      expect(
        fake.table("programme_consents").some((r) => r.enrolment_id === id),
      ).toBe(false);
      expectCoded(
        await call(a, "DELETE", `/v1/enrolments/${id}`),
        404,
        "enrolment_not_found",
      );
    });

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
      ["share without recipient", { purpose: "share_care_team" }],
      [
        "recipient on a non-share purpose",
        { purpose: "research", recipientRef: "synthetic-clinic-01" },
      ],
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

    it("grants a share consent with a recipient", async () => {
      const a = newCaller();
      const id = await enrol(a, "hw");
      await grant(a, id, "core");
      const response = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: id,
        purpose: "share_care_team",
        recipientRef: "synthetic-connection-01",
        consentVersion: "v1",
        consentText: "Synthetic sharing wording",
      });
      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        recipientRef: "synthetic-connection-01",
      });
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
        await call(b, "DELETE", `/v1/enrolments/${enrolment}`),
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
});
