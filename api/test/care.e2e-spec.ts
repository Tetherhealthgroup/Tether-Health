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
import { careErrorCodes } from "../src/care/care-errors";
import { configureApp } from "../src/configure-app";
import { UserSupabaseClientFactory } from "../src/enrolments/user-supabase-client";
import {
  DB_CANARY,
  FakePostgrest,
  registryError,
} from "./support/fake-postgrest";
import {
  openApiDocument,
  openApiErrors,
  openApiSchema,
} from "./support/openapi";

/**
 * The member's care team (/v1/care) end to end through the real app,
 * guard, filters and services and the real supabase-js client, over the
 * fake PostgREST's emulation of 202610180011 (RLS, grants, checks, the
 * consent recipient check, redemption and the revocation cascades).
 * Synthetic identities, clinics, names and numbers only.
 */

type Method = "GET" | "POST" | "PATCH" | "DELETE";

interface Caller {
  token: string;
  id: string;
  address: string;
}

const TOKEN_CANARY = "synthetic-bearer-canary-care";
const NAME_CANARY = "Synthetic Rosa Canary";
const PHONE_TYPED = "(555) 010-2244";
const PHONE_E164 = "+15550102244";
const MESSAGE_CANARY = "synthetic message canary 7f3e";
const SHOWN = { consentVersion: "v1-draft", locale: "en" };
const SNAPSHOT = {
  dates: "Sep 17 – Oct 17",
  bpAverage: "132/82 (48 readings)",
  latestPanel: "LDL 138 · Sep 30",
};

describe("Care team (e2e)", () => {
  let app: NestFastifyApplication;
  let fake: FakePostgrest;
  const users = new Map<string, { sub: string; authTime: number }>();
  const logged: string[] = [];
  const secrets: string[] = [];

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
  const newCaller = (): Caller => {
    counter += 1;
    const caller = {
      token: `${TOKEN_CANARY}-${counter}`,
      id: randomUUID(),
      address: `${counter <= 250 ? "198.51.100" : "203.0.113"}.${counter % 250}`,
    };
    users.set(caller.token, {
      sub: caller.id,
      authTime: Math.floor(Date.now() / 1000),
    });
    fake.addUser(caller.token, caller.id);
    secrets.push(caller.id);
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
    expect(response.body).not.toContain("Failing row contains");
    return response;
  };

  const expectCoded = (
    response: { statusCode: number; json: () => unknown },
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
    expect(openApiErrors("CareRequestRejected", body)).toEqual([]);
  };

  const expectSchema = (response: { json: () => unknown }, name: string) => {
    expect(openApiErrors(name, response.json())).toEqual([]);
  };

  const enrol = async (caller: Caller, programmeCode: string) => {
    const response = await call(caller, "POST", "/v1/enrolments", {
      programmeCode,
      status: programmeCode === "sd" ? "learn_only" : "focus",
      ...(["bf", "sf"].includes(programmeCode) ? { mode: "quit" } : {}),
    });
    expect(response.statusCode).toBe(201);
    return response.json<{ id: string }>().id;
  };

  const grant = async (
    caller: Caller,
    enrolmentId: string,
    purpose: string,
    recipientRef?: string,
  ) => {
    const response = await call(caller, "POST", "/v1/enrolments/consents", {
      enrolmentId,
      purpose,
      ...SHOWN,
      ...(recipientRef === undefined ? {} : { recipientRef }),
    });
    expect(response.statusCode).toBe(201);
    return response.json<{ id: string }>().id;
  };

  let inviteCounter = 0;
  /** A fresh invite code for a (new or named) synthetic clinic. */
  const invite = (
    options: Parameters<FakePostgrest["care"]["addInvite"]>[1] = {},
  ) => {
    inviteCounter += 1;
    const code = `SYNTH-${String(inviteCounter).padStart(4, "0")}-CLINIC`;
    fake.care.addInvite(code, {
      clinicName: `Synthetic Clinic ${inviteCounter}`,
      ...options,
    });
    return code;
  };

  const connect = async (caller: Caller, code = invite()) => {
    const response = await call(caller, "POST", "/v1/care/connections", {
      inviteCode: code,
    });
    expect(response.statusCode).toBe(201);
    return response.json<{ id: string; clinicName: string }>();
  };

  /** A member with a Heartwise enrolment (core consent) and a connection. */
  const heartwiseWithClinic = async (withConsent = true) => {
    const a = newCaller();
    const hw = await enrol(a, "hw");
    await grant(a, hw, "core");
    const connection = await connect(a);
    const consent = withConsent
      ? await grant(a, hw, "share_care_team", connection.id)
      : null;
    return { a, hw, connection, consent };
  };

  // ---- authentication --------------------------------------------------------

  describe("authentication", () => {
    const id = randomUUID();
    it.each([
      ["POST", "/v1/care/connections", { inviteCode: "SYNTH-0000-CLINIC" }],
      ["GET", "/v1/care/connections", undefined],
      ["DELETE", `/v1/care/connections/${id}`, undefined],
      [
        "POST",
        "/v1/care/summaries",
        { programmeCode: "hw", snapshot: SNAPSHOT },
      ],
      ["POST", "/v1/care/messages", { topic: "Plan", message: "Hello" }],
      [
        "POST",
        "/v1/care/supporters",
        { name: "Jordan", phone: PHONE_TYPED, programmes: ["bf"] },
      ],
      ["GET", "/v1/care/supporters", undefined],
      ["DELETE", `/v1/care/supporters/${id}`, undefined],
      ["POST", "/v1/care/caregivers", { name: "Rosa", phone: PHONE_TYPED }],
      ["GET", "/v1/care/caregivers", undefined],
      ["DELETE", `/v1/care/caregivers/${id}`, undefined],
    ])("%s %s requires a token", async (method, url, payload) => {
      const since = fake.requests.length;
      const response = await call(null, method as Method, url, payload);
      expect(response.statusCode).toBe(401);
      expect(fake.requests.length).toBe(since);
    });
  });

  // ---- connections -------------------------------------------------------------

  describe("POST /v1/care/connections", () => {
    it("redeems a code, ignoring case, spaces and hyphens, and names the clinic", async () => {
      const a = newCaller();
      const code = invite({ clinicName: "Synthetic Patel Clinic" });
      const response = await call(a, "POST", "/v1/care/connections", {
        inviteCode: ` ${code.toLowerCase().replace(/-/g, " ")} `,
      });
      expect(response.statusCode).toBe(201);
      expectSchema(response, "CareConnection");
      expect(response.json()).toMatchObject({
        clinicName: "Synthetic Patel Clinic",
        revokedAt: null,
      });
      expect(
        fake.table("care_connections").filter((row) => row.user_id === a.id),
      ).toHaveLength(1);
    });

    it("a member already connected gets the same connection and uses nothing", async () => {
      const a = newCaller();
      const code = invite({ maxUses: 1 });
      const first = await connect(a, code);
      const again = await call(a, "POST", "/v1/care/connections", {
        inviteCode: code,
      });
      expect(again.statusCode).toBe(201);
      expect(again.json<{ id: string }>().id).toBe(first.id);
      const used = fake
        .table("care_invites")
        .find(
          (row) => row.org_id === again.json<{ clinicId: string }>().clinicId,
        );
      expect(used?.uses).toBe(1);
    });

    it.each([
      ["an unknown code", () => "SYNTH-UNKNOWN-CODE"],
      ["a code too short", () => "SHORT"],
      ["an expired code", () => invite({ expiresInMs: -1000 })],
      ["a used-up code", () => invite({ maxUses: 1 })],
      ["an unverified clinic", () => invite({ verified: false })],
      ["a disabled clinic", () => invite({ disabled: true })],
    ])(
      "%s → 400 care_invite_invalid (one answer for all)",
      async (label, make) => {
        const code = make();
        if (label === "a used-up code") await connect(newCaller(), code);
        const a = newCaller();
        expectCoded(
          await call(a, "POST", "/v1/care/connections", { inviteCode: code }),
          400,
          "care_invite_invalid",
        );
        expect(
          fake.table("care_connections").filter((row) => row.user_id === a.id),
        ).toEqual([]);
      },
    );

    it("refuses once account deletion started (account_deletion_in_progress)", async () => {
      const a = newCaller();
      fake.startAccountDeletion(a.id);
      expectCoded(
        await call(a, "POST", "/v1/care/connections", { inviteCode: invite() }),
        409,
        "account_deletion_in_progress",
      );
    });

    it("a sync service session refusal (TH010) fails closed as 502", async () => {
      fake.failNext(
        "POST",
        "rpc/redeem_care_invite",
        registryError("sync_session_refused"),
      );
      const response = await call(newCaller(), "POST", "/v1/care/connections", {
        inviteCode: invite(),
      });
      expect(response.statusCode).toBe(502);
      expect(response.json()).not.toHaveProperty("code");
    });

    it.each([
      [{}],
      [{ inviteCode: "" }],
      [{ inviteCode: 12345678901234 }],
      [{ inviteCode: "X".repeat(81) }],
      [{ inviteCode: "SYNTH-0000-CLINIC", orgId: randomUUID() }],
    ])("refuses the body %p with invalid_request", async (body) => {
      const since = fake.requests.length;
      expectCoded(
        await call(newCaller(), "POST", "/v1/care/connections", body),
        400,
        "invalid_request",
      );
      expect(fake.requests.length).toBe(since);
    });

    it("is rate limited per client below the global limit, with the generic body", async () => {
      const a = newCaller();
      const statuses: number[] = [];
      for (let attempt = 0; attempt < 11; attempt += 1) {
        statuses.push(
          (
            await call(a, "POST", "/v1/care/connections", {
              inviteCode: `SYNTH-GUESS-${attempt}-XXXX`,
            })
          ).statusCode,
        );
      }
      expect(statuses.slice(0, 10).every((status) => status === 400)).toBe(
        true,
      );
      const limited = await call(a, "POST", "/v1/care/connections", {
        inviteCode: invite(),
      });
      expect(limited.statusCode).toBe(429);
      expect(openApiErrors("RequestRejected", limited.json())).toEqual([]);
      expect(statuses[10]).toBe(429);
      // Other routes keep the global limit.
      expect((await call(a, "GET", "/v1/care/connections")).statusCode).toBe(
        200,
      );
    });
  });

  describe("GET and DELETE /v1/care/connections", () => {
    it("lists only the caller's connections, with clinic names", async () => {
      const a = newCaller();
      const b = newCaller();
      const mine = await connect(a);
      await connect(b);
      const response = await call(a, "GET", "/v1/care/connections");
      expect(response.statusCode).toBe(200);
      expectSchema(response, "CareConnectionList");
      const { connections } = response.json<{
        connections: { id: string; clinicName: string }[];
      }>();
      expect(connections.map((c) => c.id)).toEqual([mine.id]);
      expect(connections[0]?.clinicName).toBe(mine.clinicName);
    });

    it("revokes a connection, its care-team consents and its shares", async () => {
      const { a, hw, connection, consent } = await heartwiseWithClinic();
      const share = await call(a, "POST", "/v1/care/summaries", {
        programmeCode: "hw",
        snapshot: SNAPSHOT,
      });
      expect(share.statusCode).toBe(201);
      const response = await call(
        a,
        "DELETE",
        `/v1/care/connections/${connection.id}`,
      );
      expect(response.statusCode).toBe(200);
      expectSchema(response, "CareConnection");
      expect(response.json<{ revokedAt: string | null }>().revokedAt).not.toBe(
        null,
      );
      expect(
        fake.table("programme_consents").find((row) => row.id === consent)
          ?.revoked_at,
      ).not.toBe(null);
      expect(
        fake
          .table("care_shares")
          .filter((row) => row.enrolment_id === hw)
          .every((row) => row.revoked_at !== null),
      ).toBe(true);
      // Revoked: no more summaries for it.
      expectCoded(
        await call(a, "POST", "/v1/care/summaries", {
          programmeCode: "hw",
          connectionId: connection.id,
          snapshot: SNAPSHOT,
        }),
        404,
        "connection_not_found",
      );
    });

    it("another member's, an unknown or a revoked connection → 404", async () => {
      const a = newCaller();
      const b = newCaller();
      const theirs = await connect(b);
      expectCoded(
        await call(a, "DELETE", `/v1/care/connections/${theirs.id}`),
        404,
        "connection_not_found",
      );
      expect(
        fake.table("care_connections").find((row) => row.id === theirs.id)
          ?.revoked_at,
      ).toBe(null);
      expectCoded(
        await call(a, "DELETE", `/v1/care/connections/${randomUUID()}`),
        404,
        "connection_not_found",
      );
      const mine = await connect(a);
      expect(
        (await call(a, "DELETE", `/v1/care/connections/${mine.id}`)).statusCode,
      ).toBe(200);
      expectCoded(
        await call(a, "DELETE", `/v1/care/connections/${mine.id}`),
        404,
        "connection_not_found",
      );
    });

    it("a path id that is not a UUID → 400 invalid_request", async () => {
      expectCoded(
        await call(newCaller(), "DELETE", "/v1/care/connections/not-a-uuid"),
        400,
        "invalid_request",
      );
    });
  });

  // ---- share consents (the lifted refusal) --------------------------------------

  describe("share consents", () => {
    it("a care-team consent names one of the member's live connections", async () => {
      const a = newCaller();
      const b = newCaller();
      const hw = await enrol(a, "hw");
      await grant(a, hw, "core");
      const theirs = await connect(b);
      const response = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: hw,
        purpose: "share_care_team",
        recipientRef: theirs.id,
        ...SHOWN,
      });
      expect(response.statusCode).toBe(409);
      expect(response.json()).toMatchObject({
        code: "consent_recipient_invalid",
      });
      const mine = await connect(a);
      const granted = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: hw,
        purpose: "share_care_team",
        recipientRef: mine.id.toUpperCase(),
        ...SHOWN,
      });
      expect(granted.statusCode).toBe(201);
      expect(granted.json()).toMatchObject({
        purpose: "share_care_team",
        recipientRef: mine.id.toLowerCase(),
      });
    });

    it("revoking the care-team consent revokes its shares", async () => {
      const { a, hw, consent } = await heartwiseWithClinic();
      expect(
        (
          await call(a, "POST", "/v1/care/summaries", {
            programmeCode: "hw",
            snapshot: SNAPSHOT,
          })
        ).statusCode,
      ).toBe(201);
      expect(
        (
          await call(a, "PATCH", `/v1/enrolments/consents/${consent}`, {
            revoked: true,
          })
        ).statusCode,
      ).toBe(200);
      expect(
        fake
          .table("care_shares")
          .filter((row) => row.enrolment_id === hw)
          .every((row) => row.revoked_at !== null),
      ).toBe(true);
    });
  });

  // ---- summaries -------------------------------------------------------------------

  describe("POST /v1/care/summaries", () => {
    it("stores the previewed snapshot unchanged under the programme's consent", async () => {
      const { a, hw, connection, consent } = await heartwiseWithClinic();
      const response = await call(a, "POST", "/v1/care/summaries", {
        programmeCode: "hw",
        snapshot: SNAPSHOT,
      });
      expect(response.statusCode).toBe(201);
      expectSchema(response, "CareShare");
      expect(response.json()).toMatchObject({
        programmeCode: "hw",
        connectionId: connection.id,
        kind: "visit_summary",
        delivery: "stored",
      });
      expect(response.body).not.toContain(SNAPSHOT.bpAverage);
      const stored = fake
        .table("care_shares")
        .find((row) => row.id === response.json<{ id: string }>().id);
      expect(stored).toMatchObject({
        user_id: a.id,
        enrolment_id: hw,
        connection_id: connection.id,
        consent_id: consent,
        snapshot: SNAPSHOT,
      });
      const created = Date.parse(stored?.created_at as string);
      const expires = Date.parse(stored?.expires_at as string);
      expect(expires - created).toBeLessThanOrEqual(30 * 24 * 3600 * 1000);
    });

    it("without the care-team consent → 409 care_consent_required, nothing stored", async () => {
      const { a, connection } = await heartwiseWithClinic(false);
      for (const body of [
        { programmeCode: "hw", snapshot: SNAPSHOT },
        {
          programmeCode: "hw",
          connectionId: connection.id,
          snapshot: SNAPSHOT,
        },
      ]) {
        expectCoded(
          await call(a, "POST", "/v1/care/summaries", body),
          409,
          "care_consent_required",
        );
      }
      expect(
        fake.table("care_shares").filter((row) => row.user_id === a.id),
      ).toEqual([]);
    });

    it("a consent on another programme does not share this one", async () => {
      const { a, connection } = await heartwiseWithClinic();
      const st = await enrol(a, "st");
      await grant(a, st, "core");
      expectCoded(
        await call(a, "POST", "/v1/care/summaries", {
          programmeCode: "st",
          connectionId: connection.id,
          snapshot: SNAPSHOT,
        }),
        409,
        "care_consent_required",
      );
    });

    it("two connections with consent and none named → 409 connection_required", async () => {
      const { a, hw } = await heartwiseWithClinic();
      const second = await connect(a);
      await grant(a, hw, "share_care_team", second.id);
      expectCoded(
        await call(a, "POST", "/v1/care/summaries", {
          programmeCode: "hw",
          snapshot: SNAPSHOT,
        }),
        409,
        "connection_required",
      );
      expect(
        (
          await call(a, "POST", "/v1/care/summaries", {
            programmeCode: "hw",
            connectionId: second.id,
            snapshot: SNAPSHOT,
          })
        ).statusCode,
      ).toBe(201);
    });

    it("another member's connection → 404 connection_not_found", async () => {
      const { a } = await heartwiseWithClinic();
      const b = newCaller();
      const theirs = await connect(b);
      expectCoded(
        await call(a, "POST", "/v1/care/summaries", {
          programmeCode: "hw",
          connectionId: theirs.id,
          snapshot: SNAPSHOT,
        }),
        404,
        "connection_not_found",
      );
    });

    it("no enrolment → 404; a left programme → 409", async () => {
      const a = newCaller();
      expectCoded(
        await call(a, "POST", "/v1/care/summaries", {
          programmeCode: "hw",
          snapshot: SNAPSHOT,
        }),
        404,
        "enrolment_not_found",
      );
      const { a: b, hw } = await heartwiseWithClinic();
      expect(
        (await call(b, "PATCH", `/v1/enrolments/${hw}`, { status: "left" }))
          .statusCode,
      ).toBe(200);
      expectCoded(
        await call(b, "POST", "/v1/care/summaries", {
          programmeCode: "hw",
          snapshot: SNAPSHOT,
        }),
        409,
        "enrolment_left",
      );
    });

    it("refuses once account deletion started", async () => {
      const { a } = await heartwiseWithClinic();
      fake.startAccountDeletion(a.id);
      expectCoded(
        await call(a, "POST", "/v1/care/summaries", {
          programmeCode: "hw",
          snapshot: SNAPSHOT,
        }),
        409,
        "account_deletion_in_progress",
      );
    });

    it("a consent revoked during the request (TH022) → 409 care_consent_required", async () => {
      const { a } = await heartwiseWithClinic();
      fake.failNext(
        "POST",
        "care_shares",
        registryError("care_consent_required"),
      );
      expectCoded(
        await call(a, "POST", "/v1/care/summaries", {
          programmeCode: "hw",
          snapshot: SNAPSHOT,
        }),
        409,
        "care_consent_required",
      );
    });

    it("a sync service session refusal (TH010) fails closed as 502, logging only the code", async () => {
      const { a } = await heartwiseWithClinic();
      fake.failNext(
        "POST",
        "care_shares",
        registryError("sync_session_refused"),
      );
      const response = await call(a, "POST", "/v1/care/summaries", {
        programmeCode: "hw",
        snapshot: SNAPSHOT,
      });
      expect(response.statusCode).toBe(502);
      expect(
        logged.some(
          (line) =>
            line.includes("route=/v1/care/summaries") &&
            line.includes("code=TH010"),
        ),
      ).toBe(true);
    });

    it.each([
      [{ snapshot: SNAPSHOT }],
      [{ programmeCode: "hw" }],
      [{ programmeCode: "hw", snapshot: "text" }],
      [{ programmeCode: "hw", snapshot: [1, 2] }],
      [{ programmeCode: "HW", snapshot: SNAPSHOT }],
      [{ programmeCode: "hw", snapshot: SNAPSHOT, connectionId: "x" }],
      [{ programmeCode: "hw", snapshot: SNAPSHOT, enrolmentId: randomUUID() }],
      [{ programmeCode: "hw", snapshot: { big: "x".repeat(50_000) } }],
    ])(
      "refuses the body %# with invalid_request, storing nothing",
      async (body) => {
        const { a } = await heartwiseWithClinic();
        expectCoded(
          await call(a, "POST", "/v1/care/summaries", body),
          400,
          "invalid_request",
        );
        expect(
          fake.table("care_shares").filter((row) => row.user_id === a.id),
        ).toEqual([]);
      },
    );
  });

  // ---- messages ------------------------------------------------------------------------

  describe("POST /v1/care/messages", () => {
    it("stores a message to the only connection, trimmed, without a programme", async () => {
      const a = newCaller();
      const connection = await connect(a);
      const response = await call(a, "POST", "/v1/care/messages", {
        topic: "  Question about my plan ",
        message: ` ${MESSAGE_CANARY} `,
      });
      expect(response.statusCode).toBe(201);
      expectSchema(response, "CareMessage");
      expect(response.json()).toMatchObject({
        connectionId: connection.id,
        programmeCode: null,
        shareId: null,
        delivery: "stored",
      });
      expect(response.body).not.toContain(MESSAGE_CANARY);
      expect(
        fake.table("care_messages").find((row) => row.user_id === a.id),
      ).toMatchObject({
        topic: "Question about my plan",
        body: MESSAGE_CANARY,
        enrolment_id: null,
      });
    });

    it("a message about a programme with an attached summary needs the consent", async () => {
      const { a, hw, connection } = await heartwiseWithClinic();
      const response = await call(a, "POST", "/v1/care/messages", {
        topic: "Dizzy mornings",
        message: "Since the patch",
        programmeCode: "hw",
        attachment: { snapshot: SNAPSHOT },
      });
      expect(response.statusCode).toBe(201);
      const { shareId } = response.json<{ shareId: string }>();
      expect(shareId).toEqual(expect.any(String));
      expect(
        fake.table("care_shares").find((row) => row.id === shareId),
      ).toMatchObject({
        kind: "message_attachment",
        enrolment_id: hw,
        connection_id: connection.id,
        snapshot: SNAPSHOT,
      });

      const { a: b } = await heartwiseWithClinic(false);
      expectCoded(
        await call(b, "POST", "/v1/care/messages", {
          topic: "Plan",
          message: "Hello",
          programmeCode: "hw",
        }),
        409,
        "care_consent_required",
      );
    });

    it("no connection, or two and none named → 409 connection_required", async () => {
      const a = newCaller();
      expectCoded(
        await call(a, "POST", "/v1/care/messages", {
          topic: "Plan",
          message: "Hello",
        }),
        409,
        "connection_required",
      );
      const first = await connect(a);
      await connect(a);
      expectCoded(
        await call(a, "POST", "/v1/care/messages", {
          topic: "Plan",
          message: "Hello",
        }),
        409,
        "connection_required",
      );
      expect(
        (
          await call(a, "POST", "/v1/care/messages", {
            connectionId: first.id,
            topic: "Plan",
            message: "Hello",
          })
        ).statusCode,
      ).toBe(201);
    });

    it("another member's connection → 404 connection_not_found", async () => {
      const a = newCaller();
      await connect(a);
      const theirs = await connect(newCaller());
      expectCoded(
        await call(a, "POST", "/v1/care/messages", {
          connectionId: theirs.id,
          topic: "Plan",
          message: "Hello",
        }),
        404,
        "connection_not_found",
      );
      expect(
        fake.table("care_messages").filter((row) => row.user_id === a.id),
      ).toEqual([]);
    });

    it("a failed message withdraws its attachment", async () => {
      const { a, hw } = await heartwiseWithClinic();
      fake.failNext("POST", "care_messages", {
        status: 500,
        code: "XX000",
        message: `internal ${DB_CANARY}`,
        hint: null,
      });
      const response = await call(a, "POST", "/v1/care/messages", {
        topic: "Plan",
        message: "Hello",
        programmeCode: "hw",
        attachment: { snapshot: SNAPSHOT },
      });
      expect(response.statusCode).toBe(502);
      expect(
        fake
          .table("care_shares")
          .filter((row) => row.enrolment_id === hw)
          .every((row) => row.revoked_at !== null),
      ).toBe(true);
    });

    it("refuses once account deletion started", async () => {
      const a = newCaller();
      await connect(a);
      fake.startAccountDeletion(a.id);
      expectCoded(
        await call(a, "POST", "/v1/care/messages", {
          topic: "Plan",
          message: "Hello",
        }),
        409,
        "account_deletion_in_progress",
      );
    });

    it("a sync service session refusal (TH010) fails closed as 502", async () => {
      const a = newCaller();
      await connect(a);
      fake.failNext(
        "POST",
        "care_messages",
        registryError("sync_session_refused"),
      );
      expect(
        (
          await call(a, "POST", "/v1/care/messages", {
            topic: "Plan",
            message: "Hello",
          })
        ).statusCode,
      ).toBe(502);
    });

    it.each([
      [{ message: "Hello" }],
      [{ topic: "Plan" }],
      [{ topic: "   ", message: "Hello" }],
      [{ topic: "Plan", message: "   " }],
      [{ topic: "x".repeat(81), message: "Hello" }],
      [{ topic: "Plan", message: "x".repeat(2001) }],
      [{ topic: "Plan", message: "Hello", attachment: { snapshot: SNAPSHOT } }],
      [
        {
          topic: "Plan",
          message: "Hello",
          programmeCode: "hw",
          attachment: {},
        },
      ],
      [{ topic: "Plan", message: "Hello", urgent: true }],
    ])("refuses the body %# with invalid_request", async (body) => {
      const a = newCaller();
      await connect(a);
      expectCoded(
        await call(a, "POST", "/v1/care/messages", body),
        400,
        "invalid_request",
      );
    });
  });

  // ---- supporters -------------------------------------------------------------------------

  describe("supporters", () => {
    it("stores, lists and deletes a supporter, phone in E.164", async () => {
      const a = newCaller();
      await enrol(a, "bf");
      await enrol(a, "sf");
      const created = await call(a, "POST", "/v1/care/supporters", {
        name: ` ${NAME_CANARY} `,
        phone: PHONE_TYPED,
        programmes: ["bf", "sf"],
        helpPhrase: "Can you stay with me for the next 10 minutes?",
      });
      expect(created.statusCode).toBe(201);
      expectSchema(created, "Supporter");
      expect(created.json()).toMatchObject({
        name: NAME_CANARY,
        phone: PHONE_E164,
        programmes: ["bf", "sf"],
      });
      const listed = await call(a, "GET", "/v1/care/supporters");
      expect(listed.statusCode).toBe(200);
      expectSchema(listed, "SupporterList");
      expect(listed.json<{ supporters: unknown[] }>().supporters).toHaveLength(
        1,
      );
      const id = created.json<{ id: string }>().id;
      const deleted = await call(a, "DELETE", `/v1/care/supporters/${id}`);
      expect(deleted.statusCode).toBe(204);
      expect(fake.table("supporters").some((row) => row.id === id)).toBe(false);
      expectCoded(
        await call(a, "DELETE", `/v1/care/supporters/${id}`),
        404,
        "supporter_not_found",
      );
    });

    it("a programme the caller is not in (or left) → 409 programme_not_enrolled", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      expectCoded(
        await call(a, "POST", "/v1/care/supporters", {
          name: "Jordan",
          phone: PHONE_TYPED,
          programmes: ["sf"],
        }),
        409,
        "programme_not_enrolled",
      );
      await call(a, "PATCH", `/v1/enrolments/${bf}`, { status: "left" });
      expectCoded(
        await call(a, "POST", "/v1/care/supporters", {
          name: "Jordan",
          phone: PHONE_TYPED,
          programmes: ["bf"],
        }),
        409,
        "programme_not_enrolled",
      );
    });

    it("lists and deletes only the caller's supporters", async () => {
      const a = newCaller();
      const b = newCaller();
      await enrol(b, "bf");
      const theirs = await call(b, "POST", "/v1/care/supporters", {
        name: "Jordan",
        phone: PHONE_TYPED,
        programmes: ["bf"],
      });
      const id = theirs.json<{ id: string }>().id;
      expect(
        (await call(a, "GET", "/v1/care/supporters")).json<{
          supporters: unknown[];
        }>().supporters,
      ).toEqual([]);
      expectCoded(
        await call(a, "DELETE", `/v1/care/supporters/${id}`),
        404,
        "supporter_not_found",
      );
      expect(fake.table("supporters").some((row) => row.id === id)).toBe(true);
    });

    it("refuses once account deletion started", async () => {
      const a = newCaller();
      await enrol(a, "bf");
      fake.startAccountDeletion(a.id);
      expectCoded(
        await call(a, "POST", "/v1/care/supporters", {
          name: "Jordan",
          phone: PHONE_TYPED,
          programmes: ["bf"],
        }),
        409,
        "account_deletion_in_progress",
      );
    });

    it("a sync service session refusal (TH010) fails closed as 502", async () => {
      const a = newCaller();
      await enrol(a, "bf");
      fake.failNext(
        "POST",
        "supporters",
        registryError("sync_session_refused"),
      );
      expect(
        (
          await call(a, "POST", "/v1/care/supporters", {
            name: "Jordan",
            phone: PHONE_TYPED,
            programmes: ["bf"],
          })
        ).statusCode,
      ).toBe(502);
    });

    it.each([
      [{ phone: PHONE_TYPED, programmes: ["bf"] }],
      [{ name: "   ", phone: PHONE_TYPED, programmes: ["bf"] }],
      [{ name: "Jordan", phone: "call me", programmes: ["bf"] }],
      [{ name: "Jordan", phone: "555-0102", programmes: ["bf"] }],
      [{ name: "Jordan", phone: PHONE_TYPED, programmes: [] }],
      [{ name: "Jordan", phone: PHONE_TYPED, programmes: ["hw"] }],
      [{ name: "Jordan", phone: PHONE_TYPED, programmes: ["bf", "bf"] }],
      [
        {
          name: "Jordan",
          phone: PHONE_TYPED,
          programmes: ["bf"],
          helpPhrase: " ",
        },
      ],
      [
        {
          name: "Jordan",
          phone: PHONE_TYPED,
          programmes: ["bf"],
          userId: randomUUID(),
        },
      ],
    ])("refuses the body %# with invalid_request", async (body) => {
      const a = newCaller();
      await enrol(a, "bf");
      expectCoded(
        await call(a, "POST", "/v1/care/supporters", body),
        400,
        "invalid_request",
      );
      expect(
        fake.table("supporters").filter((row) => row.user_id === a.id),
      ).toEqual([]);
    });
  });

  // ---- caregivers -----------------------------------------------------------------------------

  describe("caregivers", () => {
    it("stores a pending caregiver on Stride with the default scope, lists and revokes", async () => {
      const a = newCaller();
      const sd = await enrol(a, "sd");
      await grant(a, sd, "core");
      const created = await call(a, "POST", "/v1/care/caregivers", {
        name: NAME_CANARY,
        phone: PHONE_TYPED,
      });
      expect(created.statusCode).toBe(201);
      expectSchema(created, "Caregiver");
      expect(created.json()).toMatchObject({
        programmeCode: "sd",
        name: NAME_CANARY,
        phone: PHONE_E164,
        scope: ["sd.session_finished", "sd.fall_logged"],
        inviteStatus: "pending",
        revokedAt: null,
      });
      const id = created.json<{ id: string }>().id;
      // The caregiver consent can now name them.
      const consent = await grant(a, sd, "share_caregiver", id);
      const listed = await call(a, "GET", "/v1/care/caregivers");
      expectSchema(listed, "CaregiverList");
      expect(listed.json<{ caregivers: unknown[] }>().caregivers).toHaveLength(
        1,
      );
      const revoked = await call(a, "DELETE", `/v1/care/caregivers/${id}`);
      expect(revoked.statusCode).toBe(200);
      expect(revoked.json<{ revokedAt: string | null }>().revokedAt).not.toBe(
        null,
      );
      expect(
        fake.table("programme_consents").find((row) => row.id === consent)
          ?.revoked_at,
      ).not.toBe(null);
      expectCoded(
        await call(a, "DELETE", `/v1/care/caregivers/${id}`),
        404,
        "caregiver_not_found",
      );
    });

    it("keeps a narrower scope", async () => {
      const a = newCaller();
      await enrol(a, "sd");
      const created = await call(a, "POST", "/v1/care/caregivers", {
        name: "Rosa",
        phone: PHONE_TYPED,
        scope: ["sd.fall_logged"],
      });
      expect(created.json()).toMatchObject({ scope: ["sd.fall_logged"] });
    });

    it("no Stride enrolment → 404; left → 409", async () => {
      const a = newCaller();
      await enrol(a, "hw");
      expectCoded(
        await call(a, "POST", "/v1/care/caregivers", {
          name: "Rosa",
          phone: PHONE_TYPED,
        }),
        404,
        "enrolment_not_found",
      );
      const sd = await enrol(a, "sd");
      await call(a, "PATCH", `/v1/enrolments/${sd}`, { status: "left" });
      expectCoded(
        await call(a, "POST", "/v1/care/caregivers", {
          name: "Rosa",
          phone: PHONE_TYPED,
        }),
        409,
        "enrolment_left",
      );
    });

    it("another member's caregiver cannot be listed, revoked or named in a consent", async () => {
      const a = newCaller();
      const b = newCaller();
      const aSd = await enrol(a, "sd");
      await grant(a, aSd, "core");
      await enrol(b, "sd");
      const theirs = await call(b, "POST", "/v1/care/caregivers", {
        name: "Rosa",
        phone: PHONE_TYPED,
      });
      const id = theirs.json<{ id: string }>().id;
      expect(
        (await call(a, "GET", "/v1/care/caregivers")).json<{
          caregivers: unknown[];
        }>().caregivers,
      ).toEqual([]);
      expectCoded(
        await call(a, "DELETE", `/v1/care/caregivers/${id}`),
        404,
        "caregiver_not_found",
      );
      const consent = await call(a, "POST", "/v1/enrolments/consents", {
        enrolmentId: aSd,
        purpose: "share_caregiver",
        recipientRef: id,
        ...SHOWN,
      });
      expect(consent.statusCode).toBe(409);
      expect(consent.json()).toMatchObject({
        code: "consent_recipient_invalid",
      });
    });

    it("refuses once account deletion started", async () => {
      const a = newCaller();
      await enrol(a, "sd");
      fake.startAccountDeletion(a.id);
      expectCoded(
        await call(a, "POST", "/v1/care/caregivers", {
          name: "Rosa",
          phone: PHONE_TYPED,
        }),
        409,
        "account_deletion_in_progress",
      );
    });

    it("a sync service session refusal (TH010) fails closed as 502", async () => {
      const a = newCaller();
      await enrol(a, "sd");
      fake.failNext(
        "POST",
        "caregivers",
        registryError("sync_session_refused"),
      );
      expect(
        (
          await call(a, "POST", "/v1/care/caregivers", {
            name: "Rosa",
            phone: PHONE_TYPED,
          })
        ).statusCode,
      ).toBe(502);
    });

    it.each([
      [{ phone: PHONE_TYPED }],
      [{ name: "Rosa" }],
      [{ name: "Rosa", phone: "nope" }],
      [{ name: "Rosa", phone: PHONE_TYPED, scope: [] }],
      [{ name: "Rosa", phone: PHONE_TYPED, scope: ["hw.readings"] }],
      [
        {
          name: "Rosa",
          phone: PHONE_TYPED,
          scope: ["sd.fall_logged", "sd.fall_logged"],
        },
      ],
      [{ name: "Rosa", phone: PHONE_TYPED, enrolmentId: randomUUID() }],
    ])("refuses the body %# with invalid_request", async (body) => {
      const a = newCaller();
      await enrol(a, "sd");
      expectCoded(
        await call(a, "POST", "/v1/care/caregivers", body),
        400,
        "invalid_request",
      );
    });
  });

  // ---- deletion -----------------------------------------------------------------------------------

  it("Delete now on Stride removes its caregivers; connections and supporters stay", async () => {
    const a = newCaller();
    const sd = await enrol(a, "sd");
    await enrol(a, "bf");
    await call(a, "POST", "/v1/care/caregivers", {
      name: "Rosa",
      phone: PHONE_TYPED,
    });
    await call(a, "POST", "/v1/care/supporters", {
      name: "Jordan",
      phone: PHONE_TYPED,
      programmes: ["bf"],
    });
    await connect(a);
    const response = await call(a, "DELETE", `/v1/enrolments/${sd}`, {
      confirmation: "DELETE",
    });
    expect(response.statusCode).toBe(204);
    expect(fake.table("caregivers").filter((r) => r.user_id === a.id)).toEqual(
      [],
    );
    expect(
      fake.table("supporters").filter((r) => r.user_id === a.id),
    ).toHaveLength(1);
    expect(
      fake.table("care_connections").filter((r) => r.user_id === a.id),
    ).toHaveLength(1);
  });

  // ---- contract ------------------------------------------------------------------------------------

  describe("contract (docs/contracts/openapi.yaml)", () => {
    const document = openApiDocument();
    it.each([
      ["/v1/care/connections", "post", true],
      ["/v1/care/connections", "get", false],
      ["/v1/care/connections/{connectionId}", "delete", false],
      ["/v1/care/summaries", "post", true],
      ["/v1/care/messages", "post", true],
      ["/v1/care/supporters", "post", true],
      ["/v1/care/supporters", "get", false],
      ["/v1/care/supporters/{supporterId}", "delete", false],
      ["/v1/care/caregivers", "post", true],
      ["/v1/care/caregivers", "get", false],
      ["/v1/care/caregivers/{caregiverId}", "delete", false],
    ])("documents %s %s (app use: %s)", (path, method, appUse) => {
      const operation = document.paths[path]?.[method] as
        Record<string, unknown> | undefined;
      expect(operation).toBeDefined();
      expect(operation?.["x-app-use"] === true).toBe(appUse);
      expect(operation?.responses).toHaveProperty("401");
    });

    it("the error enum is careErrorCodes", () => {
      const schema = openApiSchema("CareRequestRejected") as {
        properties: { code: { enum: unknown } };
      };
      expect(schema.properties.code.enum).toEqual([...careErrorCodes]);
    });

    it("the version is bumped for these routes", () => {
      expect(document.info.version).toBe("1.10.0");
    });
  });

  // ---- logging ------------------------------------------------------------------------------------

  it("no log line holds a member id, name, phone, message or token", () => {
    expect(logged.length).toBeGreaterThan(0);
    for (const line of logged) {
      expect(line).not.toContain(TOKEN_CANARY);
      expect(line).not.toContain(DB_CANARY);
      expect(line).not.toContain(NAME_CANARY);
      expect(line).not.toContain(PHONE_E164);
      expect(line).not.toContain(MESSAGE_CANARY);
      for (const secret of secrets) expect(line).not.toContain(secret);
    }
  });
});
