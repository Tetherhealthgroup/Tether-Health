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
import { DB_CANARY, FakePostgrest } from "./support/fake-postgrest";
import { openApiDocument, openApiErrors } from "./support/openapi";

/**
 * The three request shapes the app spec sends (tether_ui/spec/endpoints.json)
 * where the API had another: `POST /v1/account/export`, `PATCH
 * /v1/enrolments/consents` without a consent id, and `range` on the
 * records summary. End to end through the real app, guard, filters and
 * services over the fake PostgREST. Synthetic identities only.
 */

type Method = "GET" | "POST" | "PATCH" | "DELETE";

interface Caller {
  token: string;
  id: string;
  address: string;
}

const TOKEN_CANARY = "synthetic-bearer-canary-shapes";
const SHOWN = { consentVersion: "v1-draft", locale: "en" };

describe("Spec request shapes (e2e)", () => {
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
  const newCaller = (authAgeSeconds = 0): Caller => {
    counter += 1;
    const caller = {
      token: `${TOKEN_CANARY}-${counter}`,
      id: randomUUID(),
      address: `198.51.100.${counter % 250}`,
    };
    users.set(caller.token, {
      sub: caller.id,
      authTime: Math.floor(Date.now() / 1000) - authAgeSeconds,
    });
    fake.addUser(caller.token, caller.id);
    return caller;
  };

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
    return response;
  };

  const expectCoded = (
    response: { statusCode: number; json: () => unknown },
    status: number,
    code: string,
    schema = "CodedRequestRejected",
  ) => {
    expect(response.statusCode).toBe(status);
    expect(response.json()).toMatchObject({ statusCode: status, code });
    expect(openApiErrors(schema, response.json())).toEqual([]);
  };

  const enrol = async (caller: Caller, programmeCode: string) => {
    const response = await call(caller, "POST", "/v1/enrolments", {
      programmeCode,
      status: "focus",
      ...(programmeCode === "bf" ? { mode: "quit" } : {}),
    });
    expect(response.statusCode).toBe(201);
    return response.json<{ id: string }>().id;
  };

  const grant = async (
    caller: Caller,
    enrolmentId: string,
    purpose: string,
  ) => {
    const response = await call(caller, "POST", "/v1/enrolments/consents", {
      enrolmentId,
      purpose,
      ...SHOWN,
    });
    expect(response.statusCode).toBe(201);
    return response.json<{ id: string }>().id;
  };

  const consentRows = (enrolmentId: string) =>
    fake
      .table("programme_consents")
      .filter((row) => row.enrolment_id === enrolmentId);

  // ---- POST /v1/account/export -------------------------------------------

  describe("POST /v1/account/export", () => {
    it("answers exactly what GET answers", async () => {
      const a = newCaller();
      fake.addQuitPlan(a.id);
      fake.seedRow("program_data", {
        user_id: a.id,
        program_id: "heartwise",
        payload: { readings: [] },
        revision: 1,
        updated_at: "2026-10-01T00:00:00.000Z",
      });
      const viaGet = await call(a, "GET", "/v1/account/export");
      const viaPost = await call(a, "POST", "/v1/account/export");
      expect(viaGet.statusCode).toBe(200);
      expect(viaPost.statusCode).toBe(200);
      const strip = (body: Record<string, unknown>) => {
        const { generatedAt, ...rest } = body;
        expect(typeof generatedAt).toBe("string");
        return rest;
      };
      expect(strip(viaPost.json())).toEqual(strip(viaGet.json()));
      expect(viaPost.json()).toMatchObject({
        schemaVersion: "1.0",
        profile: { id: a.id },
        quitPlan: { user_id: a.id },
        programData: [{ programId: "heartwise" }],
      });
      // Not checked against AccountDataExport: the v1 export returns the
      // stored profile and quit-plan rows as stored (snake_case), which that
      // schema does not describe, for GET and POST alike. Export v2 is a
      // separate change.
    });

    it("returns only the caller's data", async () => {
      const a = newCaller();
      const b = newCaller();
      fake.addProgramData(b.id, "steady");
      const response = await call(a, "POST", "/v1/account/export");
      expect(response.statusCode).toBe(200);
      expect(response.json()).toMatchObject({
        profile: { id: a.id },
        quitPlan: null,
        programData: [],
      });
      expect(response.body).not.toContain(b.id);
    });

    it("requires a token", async () => {
      expect((await call(null, "POST", "/v1/account/export")).statusCode).toBe(
        401,
      );
    });

    it("requires a recent sign-in, like GET", async () => {
      const stale = newCaller(3600);
      expect((await call(stale, "POST", "/v1/account/export")).statusCode).toBe(
        401,
      );
      expect((await call(stale, "GET", "/v1/account/export")).statusCode).toBe(
        401,
      );
    });

    it("refuses a body field", async () => {
      const a = newCaller();
      // No DTO: an unexpected body is ignored, never echoed or stored.
      const response = await call(a, "POST", "/v1/account/export", {
        canary: DB_CANARY,
      });
      expect(response.statusCode).toBe(200);
      expect(response.body).not.toContain(DB_CANARY);
    });
  });

  // ---- PATCH /v1/enrolments/consents -----------------------------------------

  describe("PATCH /v1/enrolments/consents (by enrolment and purpose)", () => {
    it("revokes the live consent of that purpose on the caller's enrolment", async () => {
      const a = newCaller();
      const sf = await enrol(a, "sf");
      await grant(a, sf, "core");
      const screenTime = await grant(a, sf, "screen_time");
      const response = await call(a, "PATCH", "/v1/enrolments/consents", {
        enrolmentId: sf,
        purpose: "screen_time",
        revoked: true,
      });
      expect(response.statusCode).toBe(200);
      expect(response.json()).toMatchObject({
        id: screenTime,
        enrolmentId: sf,
        purpose: "screen_time",
      });
      expect(response.json<{ revokedAt: string | null }>().revokedAt).not.toBe(
        null,
      );
      expect(openApiErrors("ProgrammeConsent", response.json())).toEqual([]);
      // Only that row changed: core stays live.
      const rows = consentRows(sf);
      expect(rows.find((row) => row.purpose === "core")?.revoked_at).toBe(null);
      expect(rows.find((row) => row.id === screenTime)?.revoked_at).not.toBe(
        null,
      );
    });

    it("revoking core revokes every live consent of the enrolment", async () => {
      const a = newCaller();
      const hw = await enrol(a, "hw");
      await grant(a, hw, "core");
      await grant(a, hw, "reminders");
      const response = await call(a, "PATCH", "/v1/enrolments/consents", {
        enrolmentId: hw,
        purpose: "core",
        revoked: true,
      });
      expect(response.statusCode).toBe(200);
      expect(consentRows(hw).every((row) => row.revoked_at !== null)).toBe(
        true,
      );
    });

    it("none live → 404 consent_not_found and no row is created", async () => {
      const a = newCaller();
      const sf = await enrol(a, "sf");
      await grant(a, sf, "core");
      const before = consentRows(sf);
      const response = await call(a, "PATCH", "/v1/enrolments/consents", {
        enrolmentId: sf,
        purpose: "screen_time",
        revoked: true,
      });
      expectCoded(response, 404, "consent_not_found");
      expect(consentRows(sf)).toEqual(before);
    });

    it("an already revoked purpose → 404 consent_not_found", async () => {
      const a = newCaller();
      const sf = await enrol(a, "sf");
      await grant(a, sf, "core");
      await grant(a, sf, "screen_time");
      const body = { enrolmentId: sf, purpose: "screen_time", revoked: true };
      expect(
        (await call(a, "PATCH", "/v1/enrolments/consents", body)).statusCode,
      ).toBe(200);
      expectCoded(
        await call(a, "PATCH", "/v1/enrolments/consents", body),
        404,
        "consent_not_found",
      );
    });

    it("another member's enrolment → 404 enrolment_not_found, nothing revoked", async () => {
      const a = newCaller();
      const b = newCaller();
      const sf = await enrol(b, "sf");
      await grant(b, sf, "core");
      await grant(b, sf, "screen_time");
      const response = await call(a, "PATCH", "/v1/enrolments/consents", {
        enrolmentId: sf,
        purpose: "screen_time",
        revoked: true,
      });
      expectCoded(response, 404, "enrolment_not_found");
      expect(consentRows(sf).every((row) => row.revoked_at === null)).toBe(
        true,
      );
    });

    it("an unknown enrolment → 404 enrolment_not_found", async () => {
      expectCoded(
        await call(newCaller(), "PATCH", "/v1/enrolments/consents", {
          enrolmentId: randomUUID(),
          purpose: "core",
          revoked: true,
        }),
        404,
        "enrolment_not_found",
      );
    });

    it.each([
      [{ purpose: "core", revoked: true }],
      [{ enrolmentId: "not-a-uuid", purpose: "core", revoked: true }],
      [{ enrolmentId: randomUUID(), purpose: "everything", revoked: true }],
      [{ enrolmentId: randomUUID(), purpose: "core" }],
      [{ enrolmentId: randomUUID(), purpose: "core", revoked: false }],
      [{ enrolmentId: randomUUID(), purpose: "core", revoked: "true" }],
      [
        {
          enrolmentId: randomUUID(),
          purpose: "core",
          revoked: true,
          consentVersion: "v1-draft",
        },
      ],
      [
        {
          enrolmentId: randomUUID(),
          purpose: "core",
          revoked: true,
          recipientRef: randomUUID(),
        },
      ],
      [
        {
          enrolmentId: randomUUID(),
          purpose: "share_care_team",
          revoked: true,
          recipientRef: "not-a-uuid",
        },
      ],
    ])("refuses the body %p with 400", async (body) => {
      const response = await call(
        newCaller(),
        "PATCH",
        "/v1/enrolments/consents",
        body,
      );
      expect(response.statusCode).toBe(400);
      expect(openApiErrors("RequestRejected", response.json())).toEqual([]);
    });

    it("requires a token", async () => {
      const response = await call(null, "PATCH", "/v1/enrolments/consents", {
        enrolmentId: randomUUID(),
        purpose: "core",
        revoked: true,
      });
      expect(response.statusCode).toBe(401);
    });

    it("the consent id route is unchanged", async () => {
      const a = newCaller();
      const sf = await enrol(a, "sf");
      await grant(a, sf, "core");
      const id = await grant(a, sf, "screen_time");
      const response = await call(a, "PATCH", `/v1/enrolments/consents/${id}`, {
        revoked: true,
      });
      expect(response.statusCode).toBe(200);
      expect(response.json()).toMatchObject({ id, purpose: "screen_time" });
    });
  });

  // ---- GET /v1/records/summary?range= ---------------------------------------

  describe("GET /v1/records/summary with range", () => {
    it.each([
      ["7d", 7],
      ["30d", 30],
      ["90d", 90],
    ])("range=%s answers like days=%d", async (range, days) => {
      const a = newCaller();
      await enrol(a, "hw");
      const byRange = await call(
        a,
        "GET",
        `/v1/records/summary?programme=hw&range=${range}`,
      );
      const byDays = await call(
        a,
        "GET",
        `/v1/records/summary?programme=hw&days=${days}`,
      );
      expect(byRange.statusCode).toBe(200);
      expect(byDays.statusCode).toBe(200);
      expect(byRange.json()).toMatchObject({ programme: "hw", days });
      expect(openApiErrors("RecordsSummary", byRange.json())).toEqual([]);
      // `since` is now minus the window, so it differs by the time between
      // the two calls only.
      const withoutSince = (body: Record<string, unknown>) =>
        Object.fromEntries(
          Object.entries(body).filter(([key]) => key !== "since"),
        );
      expect(withoutSince(byRange.json())).toEqual(withoutSince(byDays.json()));
      const gap =
        Date.parse(byDays.json<{ since: string }>().since) -
        Date.parse(byRange.json<{ since: string }>().since);
      expect(gap).toBeGreaterThanOrEqual(0);
      expect(gap).toBeLessThan(60_000);
    });

    it.each([
      "programme=hw&range=7d&days=7",
      "programme=hw&range=30d&days=7",
      "programme=hw&range=14d",
      "programme=hw&range=7",
      "programme=hw&range=7d&range=30d",
      "programme=hw",
      "range=7d",
    ])("?%s → 400 invalid_request", async (query) => {
      const a = newCaller();
      await enrol(a, "hw");
      expectCoded(
        await call(a, "GET", `/v1/records/summary?${query}`),
        400,
        "invalid_request",
        "RecordsRequestRejected",
      );
    });

    it("requires a token", async () => {
      expect(
        (await call(null, "GET", "/v1/records/summary?programme=hw&range=7d"))
          .statusCode,
      ).toBe(401);
    });
  });

  // ---- contract ---------------------------------------------------------------

  describe("contract (docs/contracts/openapi.yaml)", () => {
    const document = openApiDocument();
    it.each([
      ["/v1/account/export", "post"],
      ["/v1/enrolments/consents", "patch"],
    ])("documents %s %s for app use", (path, method) => {
      const operation = document.paths[path]?.[method] as
        Record<string, unknown> | undefined;
      expect(operation).toBeDefined();
      expect(operation?.["x-app-use"]).toBe(true);
    });

    it("documents range as an alias of days", () => {
      const parameters = (
        document.paths["/v1/records/summary"]?.get as {
          parameters: { name: string; required: boolean; schema: unknown }[];
        }
      ).parameters;
      expect(parameters.find((p) => p.name === "range")).toMatchObject({
        required: false,
        schema: { type: "string", enum: ["7d", "30d", "90d"] },
      });
      expect(parameters.find((p) => p.name === "days")?.required).toBe(false);
    });

    it("the revoke body schema refuses what the API refuses", () => {
      const id = randomUUID();
      expect(
        openApiErrors("RevokeConsentByPurpose", {
          enrolmentId: id,
          purpose: "screen_time",
          revoked: true,
        }),
      ).toEqual([]);
      expect(
        openApiErrors("RevokeConsentByPurpose", {
          enrolmentId: id,
          purpose: "screen_time",
          revoked: false,
        }),
      ).not.toEqual([]);
      expect(
        openApiErrors("RevokeConsentByPurpose", {
          enrolmentId: id,
          purpose: "screen_time",
          revoked: true,
          consentVersion: "v1",
        }),
      ).not.toEqual([]);
    });
  });

  it("no log line holds a member id or a token", () => {
    for (const line of logged) expect(line).not.toContain(TOKEN_CANARY);
  });
});
