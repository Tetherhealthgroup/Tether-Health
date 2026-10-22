import { randomBytes, randomUUID } from "node:crypto";
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
import { programmeDataErrorCodes } from "../src/programme-data/programme-data-errors";
import { recordsErrorCodes } from "../src/records-events/records-errors";
import {
  addDays,
  dayWindow,
  localDate,
  startOfLocalDate,
} from "../src/today/day-window";
import { DB_CANARY, FakePostgrest } from "./support/fake-postgrest";
import {
  openApiDocument,
  openApiErrors,
  openApiSchema,
} from "./support/openapi";

/**
 * Check-ins, rescues, lessons, Today, the records summary, notification
 * preferences, the wellbeing baseline and the app config, end to end
 * through the real Nest app, guard, filters and services and the real
 * supabase-js client, over the fake PostgREST's emulation of migrations
 * 202610180013 and 202610180014 (RLS, grants, checks, unique keys and the
 * composite enrolment foreign key) and of sync_lapse. Synthetic
 * identities only.
 */

type Method = "GET" | "POST" | "PATCH" | "PUT" | "DELETE";

interface Caller {
  token: string;
  id: string;
  address: string;
}

const TOKEN_CANARY = "synthetic-bearer-canary-rt";
const newKey = () => randomBytes(16).toString("hex");
const asUuid = (key: string) =>
  `${key.slice(0, 8)}-${key.slice(8, 12)}-${key.slice(12, 16)}-${key.slice(16, 20)}-${key.slice(20)}`;
const minutesAgo = (minutes: number) =>
  new Date(Date.now() - minutes * 60_000).toISOString();
const LAB_DATE = "2026-09-30";
const anyString: unknown = expect.any(String);

describe("Records, Today, preferences, baseline and app config (e2e)", () => {
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
      address: `198.51.100.${counter % 250}`,
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
    headers: Record<string, string> = {},
  ) => {
    const response = await app.inject({
      method,
      url,
      remoteAddress: caller?.address ?? "192.0.2.1",
      headers: {
        ...(caller ? { authorization: `Bearer ${caller.token}` } : {}),
        ...headers,
      },
      ...(payload === undefined ? {} : { payload: payload as object }),
    });
    expect(response.body).not.toContain(TOKEN_CANARY);
    expect(response.body).not.toContain(DB_CANARY);
    expect(response.body).not.toContain("Failing row contains");
    return response;
  };

  const post = (
    caller: Caller | null,
    path: string,
    body: unknown,
    key: string | null = newKey(),
  ) =>
    call(
      caller,
      "POST",
      path,
      body,
      key === null ? {} : { "idempotency-key": key },
    );

  /** Enrols `caller` in `code` with a live core consent unless `core` is false. */
  const enrol = async (
    caller: Caller,
    code: string,
    { status = "learn_only", core = true } = {},
  ) => {
    const created = await call(caller, "POST", "/v1/enrolments", {
      programmeCode: code,
      status,
      ...(code === "bf" || code === "sf" ? { mode: "quit" } : {}),
    });
    expect(created.statusCode).toBe(201);
    const id = created.json<{ id: string }>().id;
    secrets.push(id);
    if (core) {
      const granted = await call(caller, "POST", "/v1/enrolments/consents", {
        enrolmentId: id,
        purpose: "core",
        consentVersion: "v1-draft",
        locale: "en",
      });
      expect(granted.statusCode).toBe(201);
    }
    return id;
  };

  const leave = async (caller: Caller, id: string) =>
    expect(
      (await call(caller, "PATCH", `/v1/enrolments/${id}`, { status: "left" }))
        .statusCode,
    ).toBe(200);

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
    expect(openApiErrors("RecordsRequestRejected", body)).toEqual([]);
  };

  const expectSchema = (name: string, body: unknown) =>
    expect(openApiErrors(name, body)).toEqual([]);

  const rows = (table: Parameters<FakePostgrest["table"]>[0], caller: Caller) =>
    fake.table(table).filter((row) => row.user_id === caller.id);

  // ---- check-ins ----------------------------------------------------------

  describe("POST /v1/records/check-ins", () => {
    const path = "/v1/records/check-ins";

    it("writes one row per focus enrolment with live core consent, each with only its own answer", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf", { status: "focus" });
      const sf = await enrol(a, "sf", { status: "focus" });
      await enrol(a, "hw"); // learn_only with core: no row
      const key = newKey();
      const response = await post(
        a,
        path,
        {
          feel: "not_great",
          stress: "high",
          answers: { bf: "a_puff", sf: "drained" },
        },
        key,
      );
      expect(response.statusCode).toBe(201);
      expect(response.json()).toEqual({
        submissionId: asUuid(key),
        entries: ["bf", "sf"],
      });
      expectSchema("CheckInCreated", response.json());
      const stored = rows("programme_entries", a);
      expect(stored).toHaveLength(2);
      const byProgramme = Object.fromEntries(
        stored.map((row) => [String(row.programme_code), row]),
      );
      expect(byProgramme.bf).toMatchObject({
        enrolment_id: bf,
        kind: "checkin",
        submission_id: asUuid(key),
        payload: { feel: "not_great", stress: "high", answer: "a_puff" },
      });
      expect(byProgramme.sf).toMatchObject({
        enrolment_id: sf,
        kind: "checkin",
        payload: { feel: "not_great", stress: "high", answer: "drained" },
      });
      // Exact payloads: no row carries another card's answer.
      expect(byProgramme.bf?.payload).toEqual({
        feel: "not_great",
        stress: "high",
        answer: "a_puff",
      });
      expect(byProgramme.sf?.payload).toEqual({
        feel: "not_great",
        stress: "high",
        answer: "drained",
      });
    });

    it("bf and a programme without a card: bf's row has its answer, the other row only the shared values", async () => {
      const a = newCaller();
      await enrol(a, "bf", { status: "focus" });
      await enrol(a, "ea", { status: "focus" });
      const response = await post(a, path, {
        feel: "good",
        answers: { bf: "a_puff" },
      });
      expect(response.statusCode).toBe(201);
      expect(response.json<{ entries: string[] }>().entries).toEqual([
        "bf",
        "ea",
      ]);
      const payloads = Object.fromEntries(
        rows("programme_entries", a).map((row) => [
          String(row.programme_code),
          row.payload,
        ]),
      );
      expect(payloads).toEqual({
        bf: { feel: "good", answer: "a_puff" },
        ea: { feel: "good" },
      });
    });

    it("a focus enrolment without live core consent gets no row", async () => {
      const a = newCaller();
      await enrol(a, "bf", { status: "focus" });
      await enrol(a, "ea", { status: "focus", core: false });
      const response = await post(a, path, { feel: "okay" });
      expect(response.statusCode).toBe(201);
      expect(response.json<{ entries: string[] }>().entries).toEqual(["bf"]);
      expect(
        rows("programme_entries", a).map((row) => [
          row.programme_code,
          row.payload,
        ]),
      ).toEqual([["bf", { feel: "okay" }]]);
    });

    it("a programme whose row would hold nothing gets none (answer only for another card)", async () => {
      const a = newCaller();
      await enrol(a, "bf", { status: "focus" });
      await enrol(a, "sf", { status: "focus" });
      const response = await post(a, path, { answers: { bf: "no" } });
      expect(response.statusCode).toBe(201);
      expect(response.json<{ entries: string[] }>().entries).toEqual(["bf"]);
      expect(rows("programme_entries", a)).toEqual([
        expect.objectContaining({
          programme_code: "bf",
          payload: { answer: "no" },
        }),
      ]);
    });

    it("an answer for a programme that is not a qualifying enrolment → 422 invalid_record, nothing written", async () => {
      const a = newCaller();
      await enrol(a, "bf", { status: "focus" });
      await enrol(a, "sf"); // learn_only: not focus
      expectCoded(
        await post(a, path, { feel: "good", answers: { sf: "better" } }),
        422,
        "invalid_record",
      );
      expect(rows("programme_entries", a)).toHaveLength(0);
    });

    it("no qualifying enrolment → 409 no_focus_programme, nothing written", async () => {
      const a = newCaller();
      await enrol(a, "hw");
      await enrol(a, "bf", { status: "focus", core: false });
      expectCoded(
        await post(a, path, { feel: "good" }),
        409,
        "no_focus_programme",
      );
      expect(rows("programme_entries", a)).toHaveLength(0);
    });

    it.each([
      ["no value at all", {}],
      ["only empty answers", { answers: {} }],
      ["an unknown key", { feel: "good", mood: "good" }],
      ["an answer for a programme without a card", { answers: { hw: "no" } }],
      ["an answer code of another card", { answers: { bf: "drained" } }],
      ["a feel code not in the list", { feel: "fine" }],
      ["a null value", { feel: null }],
      ["answers as a list", { answers: ["no"] }],
      [
        "a time more than 5 minutes ahead",
        {
          feel: "good",
          occurredAt: new Date(Date.now() + 3_600_000).toISOString(),
        },
      ],
    ])("%s → 400 invalid_request", async (_name, body) => {
      const a = newCaller();
      await enrol(a, "bf", { status: "focus" });
      expectCoded(await post(a, path, body), 400, "invalid_request");
      expect(rows("programme_entries", a)).toHaveLength(0);
    });

    it("the key is required and checked before the body and the pre-checks", async () => {
      const a = newCaller();
      expectCoded(
        await post(a, path, {}, null),
        400,
        "idempotency_key_required",
      );
      expectCoded(
        await post(a, path, { bad: 1 }, "x"),
        400,
        "idempotency_key_invalid",
      );
    });

    it("replay: same key and content → 200 replayed, times not compared; other content → 409", async () => {
      const a = newCaller();
      await enrol(a, "bf", { status: "focus" });
      await enrol(a, "sf", { status: "focus" });
      const key = newKey();
      const body = { feel: "good", answers: { sf: "same" } };
      expect((await post(a, path, body, key)).statusCode).toBe(201);
      const replay = await post(
        a,
        path,
        { ...body, occurredAt: minutesAgo(30) },
        key,
      );
      expect(replay.statusCode).toBe(200);
      expect(replay.json()).toEqual({
        submissionId: asUuid(key),
        replayed: true,
        entries: ["bf", "sf"],
      });
      expectSchema("CheckInReplayed", replay.json());
      expectCoded(
        await post(a, path, { feel: "great", answers: { sf: "same" } }, key),
        409,
        "idempotency_key_conflict",
      );
      expect(rows("programme_entries", a)).toHaveLength(2);
    });

    it("replay after an enrolment stopped qualifying compares the rest and inserts nothing new", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf", { status: "focus" });
      await enrol(a, "sf", { status: "focus" });
      const key = newKey();
      expect((await post(a, path, { stress: "low" }, key)).statusCode).toBe(
        201,
      );
      await leave(a, bf);
      const replay = await post(a, path, { stress: "low" }, key);
      expect(replay.statusCode).toBe(200);
      expect(rows("programme_entries", a)).toHaveLength(2);
    });

    it("a replay whose rows exist only for an enrolment that no longer qualifies inserts nothing for the new one", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf", { status: "focus" });
      const key = newKey();
      expect((await post(a, path, { stress: "low" }, key)).statusCode).toBe(
        201,
      );
      await leave(a, bf);
      await enrol(a, "sf", { status: "focus" });
      expect((await post(a, path, { stress: "low" }, key)).statusCode).toBe(
        200,
      );
      expect(
        rows("programme_entries", a).map((row) => row.programme_code),
      ).toEqual(["bf"]);
    });

    it("account deletion started → 409 account_deletion_in_progress", async () => {
      const a = newCaller();
      await enrol(a, "bf", { status: "focus" });
      fake.startAccountDeletion(a.id);
      expectCoded(
        await post(a, path, { feel: "okay" }),
        409,
        "account_deletion_in_progress",
      );
      expect(rows("programme_entries", a)).toHaveLength(0);
    });

    it("B's check-in never lands in A's enrolments", async () => {
      const a = newCaller();
      const b = newCaller();
      await enrol(a, "bf", { status: "focus" });
      expectCoded(
        await post(b, path, { feel: "okay" }),
        409,
        "no_focus_programme",
      );
      expect(rows("programme_entries", a)).toHaveLength(0);
    });
  });

  // ---- rescues ------------------------------------------------------------

  describe("POST /v1/records/rescues", () => {
    const path = "/v1/records/rescues";
    const rescue = {
      tool: "slow_breathing",
      intensityBefore: 8,
      intensityAfter: 3,
      helped: "yes",
    };

    it("programme bf → written with the caller's BreatheFree enrolment", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      const key = newKey();
      const response = await post(a, path, { ...rescue, programme: "bf" }, key);
      expect(response.statusCode).toBe(201);
      expect(response.json()).toEqual({ submissionId: asUuid(key) });
      expect(rows("rescue_events", a)).toEqual([
        expect.objectContaining({
          enrolment_id: bf,
          programme_code: "bf",
          tool: "slow_breathing",
          intensity_before: 8,
          intensity_after: 3,
          helped: "yes",
          escalated: false,
          submission_id: asUuid(key),
        }),
      ]);
    });

    it("no programme → a shared rescue with no enrolment, never inferred from the member's enrolments", async () => {
      const a = newCaller();
      await enrol(a, "bf", { status: "focus" });
      const response = await post(a, path, { tool: "slow_breathing" });
      expect(response.statusCode).toBe(201);
      expect(rows("rescue_events", a)).toEqual([
        expect.objectContaining({
          enrolment_id: null,
          programme_code: null,
          escalated: false,
        }),
      ]);
    });

    it.each([
      ["not enrolled", 404, "enrolment_not_found"],
      ["left", 409, "enrolment_left"],
      ["no live core consent", 409, "core_consent_required"],
      ["account deletion started", 409, "account_deletion_in_progress"],
    ])(
      "bf %s → %i %s, and no rescue is written (no fall back to a shared rescue)",
      async (state, status, code) => {
        const a = newCaller();
        if (state === "left") await leave(a, await enrol(a, "bf"));
        if (state === "no live core consent") {
          await enrol(a, "bf", { core: false });
        }
        if (state === "account deletion started") {
          await enrol(a, "bf");
          fake.startAccountDeletion(a.id);
        }
        expectCoded(
          await post(a, path, { ...rescue, programme: "bf" }),
          status,
          code,
        );
        expect(rows("rescue_events", a)).toHaveLength(0);
      },
    );

    it.each([
      ["another programme", { tool: "walk", programme: "sf" }],
      ["a null programme", { tool: "walk", programme: null }],
      ["no tool", { helped: "yes" }],
      ["a tool that is not a code", { tool: "Slow breathing" }],
      ["intensity above 10", { tool: "walk", intensityAfter: 11 }],
      ["a fractional intensity", { tool: "walk", intensityBefore: 2.5 }],
      [
        "the spec label instead of the code",
        { tool: "walk", helped: "not_this_time" },
      ],
      ["escalated as text", { tool: "walk", escalated: "yes" }],
      ["an unknown key", { tool: "walk", enrolmentId: randomUUID() }],
    ])("%s → 400 invalid_request", async (_name, body) => {
      const a = newCaller();
      await enrol(a, "bf");
      expectCoded(await post(a, path, body), 400, "invalid_request");
      expect(rows("rescue_events", a)).toHaveLength(0);
    });

    it("replay → 200 (opened time not compared); other content → 409", async () => {
      const a = newCaller();
      await enrol(a, "bf");
      const key = newKey();
      const body = { ...rescue, programme: "bf", openedAt: minutesAgo(10) };
      expect((await post(a, path, body, key)).statusCode).toBe(201);
      const replay = await post(
        a,
        path,
        { ...body, openedAt: minutesAgo(5) },
        key,
      );
      expect(replay.statusCode).toBe(200);
      expect(replay.json()).toEqual({
        submissionId: asUuid(key),
        replayed: true,
      });
      expectCoded(
        await post(a, path, { ...body, helped: "no" }, key),
        409,
        "idempotency_key_conflict",
      );
      // The same key as a shared rescue is other content too.
      expectCoded(
        await post(a, path, { ...rescue, openedAt: minutesAgo(10) }, key),
        409,
        "idempotency_key_conflict",
      );
      expect(rows("rescue_events", a)).toHaveLength(1);
    });
  });

  // ---- lessons ------------------------------------------------------------

  describe("POST /v1/records/lessons", () => {
    const path = "/v1/records/lessons";

    it("completes a lesson; completing it again is a 200 replay whatever the key", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      const key = newKey();
      const first = await post(
        a,
        path,
        { programme: "bf", lessonId: "bf.cravings-1" },
        key,
      );
      expect(first.statusCode).toBe(201);
      expect(first.json()).toEqual({ submissionId: asUuid(key) });
      const again = await post(a, path, {
        programme: "bf",
        lessonId: "bf.cravings-1",
      });
      expect(again.statusCode).toBe(200);
      expect(again.json<{ replayed: boolean }>().replayed).toBe(true);
      expect(rows("lesson_progress", a)).toEqual([
        expect.objectContaining({
          enrolment_id: bf,
          programme_code: "bf",
          lesson_id: "bf.cravings-1",
        }),
      ]);
    });

    it.each([
      [
        "a lesson of another programme",
        { programme: "bf", lessonId: "sf.unplug" },
      ],
      ["no programme prefix", { programme: "bf", lessonId: "cravings" }],
      [
        "an id outside the database pattern",
        { programme: "bf", lessonId: "bf.Cravings" },
      ],
      ["a programme that is not a code", { programme: "BF", lessonId: "bf.x" }],
      ["an unknown key", { programme: "bf", lessonId: "bf.x", done: true }],
    ])("%s → 400 invalid_request", async (_name, body) => {
      const a = newCaller();
      await enrol(a, "bf");
      expectCoded(await post(a, path, body), 400, "invalid_request");
      expect(rows("lesson_progress", a)).toHaveLength(0);
    });

    it("not enrolled → 404; no core consent → 409; key required", async () => {
      const a = newCaller();
      expectCoded(
        await post(a, path, { programme: "hw", lessonId: "hw.salt" }),
        404,
        "enrolment_not_found",
      );
      await enrol(a, "hw", { core: false });
      expectCoded(
        await post(a, path, { programme: "hw", lessonId: "hw.salt" }),
        409,
        "core_consent_required",
      );
      expectCoded(
        await post(a, path, { programme: "hw", lessonId: "hw.salt" }, null),
        400,
        "idempotency_key_required",
      );
      expect(rows("lesson_progress", a)).toHaveLength(0);
    });
  });

  // ---- Today --------------------------------------------------------------

  describe("GET /v1/today", () => {
    interface Block {
      code: string;
      [field: string]: unknown;
    }
    const today = async (caller: Caller) => {
      const response = await call(caller, "GET", "/v1/today");
      expect(response.statusCode).toBe(200);
      expectSchema("Today", response.json());
      return response.json<{
        date: string;
        checkin: { doneToday: boolean };
        account: { lastHelpfulRescue: unknown };
        programmes: Block[];
      }>();
    };
    const block = (body: { programmes: Block[] }, code: string) =>
      body.programmes.find((entry) => entry.code === code);

    it("a member with nothing has an empty day in their time zone", async () => {
      const a = newCaller();
      fake.setProfileTimeZone(a.id, "Pacific/Kiritimati");
      const body = await today(a);
      expect(body).toEqual({
        date: localDate("Pacific/Kiritimati", Date.now()),
        checkin: { doneToday: false },
        account: { lastHelpfulRescue: null },
        programmes: [],
      });
    });

    it("each block holds only its programme's rows; left programmes are omitted", async () => {
      const a = newCaller();
      const hw = await enrol(a, "hw");
      await enrol(a, "st");
      await enrol(a, "bf", { status: "focus" });
      await enrol(a, "sf", { status: "focus" });
      await enrol(a, "nu");
      const ea = await enrol(a, "ea");
      const submit = async (route: string, body: object) =>
        expect(
          (await post(a, `/v1/program-data/${route}`, body)).statusCode,
        ).toBe(201);
      await submit("hw/readings", {
        systolic: 131,
        diastolic: 85,
        pulse: 66,
        measuredAt: minutesAgo(30),
      });
      await submit("hw/readings", {
        systolic: 128,
        diastolic: 82,
        measuredAt: minutesAgo(10),
      });
      await submit("st/readings", { reading: 141, measuredAt: minutesAgo(20) });
      await submit("st/a1c", { a1c: 6.9, labDate: LAB_DATE });
      await submit("sf/pauses", { reason: "bored" });
      await submit("ea/moods", { mood: "low" });
      await leave(a, ea);
      expect(
        (
          await post(a, "/v1/records/rescues", {
            tool: "move",
            helped: "a_little",
            openedAt: minutesAgo(9),
          })
        ).statusCode,
      ).toBe(201);
      expect(
        (
          await post(a, "/v1/records/rescues", {
            tool: "slow_breathing",
            programme: "bf",
            helped: "yes",
            openedAt: minutesAgo(8),
          })
        ).statusCode,
      ).toBe(201);
      expect(
        (
          await post(a, "/v1/records/rescues", {
            tool: "urge_surfing",
            programme: "bf",
            helped: "no",
            openedAt: minutesAgo(1),
          })
        ).statusCode,
      ).toBe(201);
      expect(
        (await post(a, "/v1/records/check-ins", { feel: "okay" })).statusCode,
      ).toBe(201);
      expect(
        (
          await post(a, "/v1/records/lessons", {
            programme: "hw",
            lessonId: "hw.salt",
          })
        ).statusCode,
      ).toBe(201);
      expect(
        (
          await call(a, "PATCH", "/v1/notifications/preferences", {
            programmeReminders: [{ programme: "hw", remindAt: "08:15" }],
          })
        ).statusCode,
      ).toBe(200);
      fake.addSyncLapse(a.id, "bf", minutesAgo(60));
      fake.addSyncLapse(a.id, "bf", minutesAgo(30));
      fake.addSyncLapse(a.id, "sf", minutesAgo(45));
      fake.addSyncLapse(
        a.id,
        "bf",
        new Date(Date.now() - 10 * 86_400_000).toISOString(),
      );

      const body = await today(a);
      expect(body.checkin).toEqual({ doneToday: true });
      expect(body.account).toEqual({
        lastHelpfulRescue: { tool: "move", at: anyString },
      });
      expect(body.programmes.map((entry) => entry.code)).toEqual([
        "bf",
        "hw",
        "nu",
        "sf",
        "st",
      ]);
      expect(block(body, "hw")).toEqual({
        code: "hw",
        status: "learn_only",
        mode: null,
        reminderAt: "08:15",
        lessonsCompleted: 1,
        lastBp: {
          systolic: 128,
          diastolic: 82,
          pulse: null,
          at: anyString,
        },
      });
      expect(block(body, "st")).toEqual({
        code: "st",
        status: "learn_only",
        mode: null,
        reminderAt: null,
        lessonsCompleted: 0,
        lastGlucose: { value: 141, at: anyString },
        lastA1c: { value: 6.9, at: `${LAB_DATE}T00:00:00Z` },
      });
      expect(block(body, "nu")).toEqual({
        code: "nu",
        status: "learn_only",
        mode: null,
        reminderAt: null,
        lessonsCompleted: 0,
      });
      expect(block(body, "sf")).toMatchObject({
        status: "focus",
        mode: "quit",
        pausesToday: 1,
        lapsesLast7Days: 1,
      });
      expect(block(body, "bf")).toMatchObject({
        status: "focus",
        lapsesLast7Days: 2,
        lastLapseAt: anyString,
        lastHelpfulRescue: { tool: "slow_breathing", at: anyString },
      });
      // No block carries another programme's field.
      const owned: Record<string, string[]> = {
        hw: ["lastBp"],
        st: ["lastGlucose", "lastA1c"],
        nu: [],
        sf: ["pausesToday", "lapsesLast7Days"],
        bf: ["lapsesLast7Days", "lastLapseAt", "lastHelpfulRescue"],
      };
      for (const entry of body.programmes) {
        expect(Object.keys(entry).sort()).toEqual(
          [
            "code",
            "status",
            "mode",
            "reminderAt",
            "lessonsCompleted",
            ...owned[entry.code]!,
          ].sort(),
        );
      }
      expect(JSON.stringify(block(body, "st"))).not.toContain("128");
      expect(hw).toBeDefined();
    });

    it("B's day holds none of A's rows", async () => {
      const a = newCaller();
      const b = newCaller();
      await enrol(a, "hw");
      await enrol(b, "hw");
      expect(
        (
          await post(a, "/v1/program-data/hw/readings", {
            systolic: 150,
            diastolic: 95,
          })
        ).statusCode,
      ).toBe(201);
      expect(
        (await post(a, "/v1/records/rescues", { tool: "move", helped: "yes" }))
          .statusCode,
      ).toBe(201);
      const body = await today(b);
      expect(block(body, "hw")).toMatchObject({ lastBp: null });
      expect(body.account.lastHelpfulRescue).toBeNull();
    });

    it("requires a token", async () => {
      expect((await call(null, "GET", "/v1/today")).statusCode).toBe(401);
    });
  });

  // ---- summary ------------------------------------------------------------

  describe("GET /v1/records/summary", () => {
    const summary = (caller: Caller, query: string) =>
      call(caller, "GET", `/v1/records/summary?${query}`);

    it("one programme's rows only, within the window", async () => {
      const a = newCaller();
      const hwId = await enrol(a, "hw");
      await enrol(a, "st");
      const bf = await enrol(a, "bf");
      await enrol(a, "sf");
      expect(
        (
          await post(a, "/v1/program-data/hw/readings", {
            systolic: 140,
            diastolic: 90,
          })
        ).statusCode,
      ).toBe(201);
      expect(
        (await post(a, "/v1/program-data/st/readings", { reading: 99 }))
          .statusCode,
      ).toBe(201);
      expect(
        (
          await post(a, "/v1/records/rescues", {
            tool: "move",
            programme: "bf",
          })
        ).statusCode,
      ).toBe(201);
      expect(
        (await post(a, "/v1/records/rescues", { tool: "walk" })).statusCode,
      ).toBe(201);
      fake.addSyncLapse(a.id, "bf", minutesAgo(5));
      fake.addSyncLapse(a.id, "sf", minutesAgo(5));
      fake.seedRow("observations", {
        id: randomUUID(),
        user_id: a.id,
        enrolment_id: hwId,
        programme_code: "hw",
        submission_id: randomUUID(),
        metric: "bp_systolic",
        value: 170,
        unit_ucum: "mm[Hg]",
        effective_at: new Date(Date.now() - 20 * 86_400_000).toISOString(),
        attributes: {},
        created_at: new Date().toISOString(),
      });

      const hw = await summary(a, "programme=hw&days=7");
      expect(hw.statusCode).toBe(200);
      expectSchema("RecordsSummary", hw.json());
      const hwBody = hw.json<
        Record<string, unknown> & {
          observations: { metric: string; value: number }[];
        }
      >();
      expect(hwBody).toMatchObject({
        programme: "hw",
        days: 7,
        status: "learn_only",
        entries: [],
        lessons: [],
      });
      expect(
        hwBody.observations.map((o) => [o.metric, o.value]).sort(),
      ).toEqual([
        ["bp_diastolic", 90],
        ["bp_systolic", 140],
      ]);
      expect(hwBody).not.toHaveProperty("lapses");
      expect(hwBody).not.toHaveProperty("rescues");
      const month = (await summary(a, "programme=hw&days=30")).json<{
        observations: unknown[];
      }>();
      expect(month.observations).toHaveLength(3);

      const bfBody = (await summary(a, "days=90&programme=bf")).json<{
        rescues: { tool: string }[];
        lapses: unknown[];
        observations: unknown[];
      }>();
      expect(bfBody.rescues.map((r) => r.tool)).toEqual(["move"]);
      expect(bfBody.lapses).toHaveLength(1);
      expect(bfBody.observations).toEqual([]);
      const sfBody = (await summary(a, "programme=sf&days=7")).json<
        Record<string, unknown>
      >();
      expect(sfBody.lapses).toHaveLength(1);
      expect(sfBody).not.toHaveProperty("rescues");
      expect(bf).toBeDefined();
    });

    it("a left programme is summarised; not enrolled → 404", async () => {
      const a = newCaller();
      const ea = await enrol(a, "ea");
      expect(
        (await post(a, "/v1/program-data/ea/moods", { mood: "okay" }))
          .statusCode,
      ).toBe(201);
      await leave(a, ea);
      const left = await summary(a, "programme=ea&days=7");
      expect(left.statusCode).toBe(200);
      expect(left.json()).toMatchObject({
        status: "left",
        entries: [expect.objectContaining({ kind: "ea.mood" })],
      });
      expectCoded(
        await summary(a, "programme=hw&days=7"),
        404,
        "enrolment_not_found",
      );
      const b = newCaller();
      expectCoded(
        await summary(b, "programme=ea&days=7"),
        404,
        "enrolment_not_found",
      );
    });

    it.each([
      "programme=hw",
      "days=7",
      "programme=hw&days=14",
      "programme=hw&days=7&other=1",
      "programme=hw&programme=st&days=7",
      "programme=HW&days=7",
    ])("%s → 400 invalid_request", async (query) => {
      const a = newCaller();
      await enrol(a, "hw");
      expectCoded(await summary(a, query), 400, "invalid_request");
    });

    it("reads every page past the server's row cap", async () => {
      const a = newCaller();
      const enrolmentId = await enrol(a, "sd");
      for (let i = 0; i < 7; i += 1) {
        fake.seedRow("programme_entries", {
          id: randomUUID(),
          user_id: a.id,
          enrolment_id: enrolmentId,
          programme_code: "sd",
          submission_id: randomUUID(),
          kind: "sd.fall",
          occurred_at: minutesAgo(i + 1),
          payload: {},
          created_at: new Date().toISOString(),
        });
      }
      fake.maxRows = 3;
      try {
        const body = (await summary(a, "programme=sd&days=7")).json<{
          entries: unknown[];
        }>();
        expect(body.entries).toHaveLength(7);
      } finally {
        fake.maxRows = null;
      }
    });
  });

  // ---- notification preferences -------------------------------------------

  describe("/v1/notifications/preferences", () => {
    const path = "/v1/notifications/preferences";

    it("never saved → the stored defaults with reminders off and persisted false", async () => {
      const a = newCaller();
      const response = await call(a, "GET", path);
      expect(response.statusCode).toBe(200);
      expect(response.json()).toEqual({
        remindersEnabled: false,
        sensitiveDetails: false,
        quietHoursEnabled: true,
        persisted: false,
        programmeReminders: [],
      });
      expectSchema("NotificationPreferences", response.json());
      expect(rows("notification_preferences", a)).toHaveLength(0);
    });

    it("PATCH changes only the fields present", async () => {
      const a = newCaller();
      const first = await call(a, "PATCH", path, { sensitiveDetails: true });
      expect(first.statusCode).toBe(200);
      expect(first.json()).toEqual({
        remindersEnabled: false,
        sensitiveDetails: true,
        quietHoursEnabled: true,
        persisted: true,
        programmeReminders: [],
      });
      const second = await call(a, "PATCH", path, { remindersEnabled: true });
      expect(second.json()).toMatchObject({
        remindersEnabled: true,
        sensitiveDetails: true,
        quietHoursEnabled: true,
      });
      const third = await call(a, "PATCH", path, { quietHoursEnabled: false });
      expect(third.json()).toMatchObject({
        remindersEnabled: true,
        sensitiveDetails: true,
        quietHoursEnabled: false,
      });
      expect(rows("notification_preferences", a)).toHaveLength(1);
      // An empty PATCH changes nothing.
      expect((await call(a, "PATCH", path, {})).json()).toEqual(third.json());
    });

    it("a reminder time is stored per enrolment and can be changed", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      const set = await call(a, "PATCH", path, {
        programmeReminders: [{ programme: "bf", remindAt: "08:00" }],
      });
      expect(set.statusCode).toBe(200);
      expect(
        set.json<{ programmeReminders: unknown }>().programmeReminders,
      ).toEqual([{ programme: "bf", remindAt: "08:00" }]);
      // Only the reminder was sent: no settings row was created.
      expect(set.json<{ persisted: boolean }>().persisted).toBe(false);
      const changed = await call(a, "PATCH", path, {
        programmeReminders: [{ programme: "bf", remindAt: "21:30" }],
      });
      expect(
        changed.json<{ programmeReminders: unknown }>().programmeReminders,
      ).toEqual([{ programme: "bf", remindAt: "21:30" }]);
      expect(rows("programme_reminders", a)).toEqual([
        expect.objectContaining({
          enrolment_id: bf,
          programme_code: "bf",
          remind_at: "21:30:00",
        }),
      ]);
    });

    it.each([
      ["not enrolled", 404, "enrolment_not_found"],
      ["left", 409, "enrolment_left"],
      ["no live core consent", 409, "core_consent_required"],
    ])(
      "a reminder for a programme %s → %i %s, nothing written",
      async (state, status, code) => {
        const a = newCaller();
        if (state === "left") await leave(a, await enrol(a, "sf"));
        if (state === "no live core consent")
          await enrol(a, "sf", { core: false });
        expectCoded(
          await call(a, "PATCH", path, {
            remindersEnabled: true,
            programmeReminders: [{ programme: "sf", remindAt: "07:00" }],
          }),
          status,
          code,
        );
        expect(rows("programme_reminders", a)).toHaveLength(0);
        expect(rows("notification_preferences", a)).toHaveLength(0);
      },
    );

    it("account deletion started → 409", async () => {
      const a = newCaller();
      fake.startAccountDeletion(a.id);
      expectCoded(
        await call(a, "PATCH", path, { remindersEnabled: true }),
        409,
        "account_deletion_in_progress",
      );
      expect(rows("notification_preferences", a)).toHaveLength(0);
    });

    it.each([
      [
        "a cleared time",
        { programmeReminders: [{ programme: "bf", remindAt: null }] },
      ],
      [
        "a time out of range",
        { programmeReminders: [{ programme: "bf", remindAt: "24:00" }] },
      ],
      [
        "seconds",
        { programmeReminders: [{ programme: "bf", remindAt: "08:00:00" }] },
      ],
      [
        "one programme twice",
        {
          programmeReminders: [
            { programme: "bf", remindAt: "08:00" },
            { programme: "bf", remindAt: "09:00" },
          ],
        },
      ],
      [
        "an extra reminder key",
        {
          programmeReminders: [
            { programme: "bf", remindAt: "08:00", enabled: true },
          ],
        },
      ],
      ["a switch as text", { remindersEnabled: "true" }],
      ["a null switch", { remindersEnabled: null }],
      ["an unknown key", { quietHoursStart: "21:00" }],
    ])("%s → 400 invalid_request", async (_name, body) => {
      const a = newCaller();
      await enrol(a, "bf");
      expectCoded(await call(a, "PATCH", path, body), 400, "invalid_request");
      expect(rows("programme_reminders", a)).toHaveLength(0);
    });

    it("an Idempotency-Key header is accepted and ignored", async () => {
      const a = newCaller();
      const response = await call(
        a,
        "PATCH",
        path,
        { remindersEnabled: true },
        { "idempotency-key": "not-a-valid-key" },
      );
      expect(response.statusCode).toBe(200);
    });

    it("B never sees A's preferences", async () => {
      const a = newCaller();
      const b = newCaller();
      await enrol(a, "bf");
      await call(a, "PATCH", path, {
        remindersEnabled: true,
        programmeReminders: [{ programme: "bf", remindAt: "08:00" }],
      });
      expect((await call(b, "GET", path)).json()).toMatchObject({
        persisted: false,
        remindersEnabled: false,
        programmeReminders: [],
      });
    });
  });

  // ---- baseline -----------------------------------------------------------

  describe("/v1/profile/baseline", () => {
    const path = "/v1/profile/baseline";

    it("GET before any save → all null", async () => {
      const a = newCaller();
      const response = await call(a, "GET", path);
      expect(response.statusCode).toBe(200);
      expect(response.json()).toEqual({
        ageRange: null,
        sleepBand: null,
        stressBand: null,
      });
      expectSchema("Baseline", response.json());
    });

    it("PUT replaces all three; an absent field becomes null", async () => {
      const a = newCaller();
      const first = await call(a, "PUT", path, {
        ageRange: "35_44",
        sleepBand: "5_6",
        stressBand: "high",
      });
      expect(first.statusCode).toBe(200);
      expect(first.json()).toEqual({
        ageRange: "35_44",
        sleepBand: "5_6",
        stressBand: "high",
      });
      const second = await call(a, "PUT", path, { sleepBand: "7_8" });
      expect(second.json()).toEqual({
        ageRange: null,
        sleepBand: "7_8",
        stressBand: null,
      });
      expect(rows("wellbeing_baseline", a)).toHaveLength(1);
      expect((await call(a, "GET", path)).json()).toEqual(second.json());
      // The identity profile is a different resource.
      const profile = fake.table("profiles").find((row) => row.id === a.id);
      expect(profile).toBeDefined();
      expect(profile).not.toHaveProperty("age_range");
    });

    it.each(["35_35", "95_99", "35-44", "17_24", "90_plus", 35])(
      "age %p (not a band) → 400 invalid_request, nothing written",
      async (ageRange) => {
        const a = newCaller();
        expectCoded(
          await call(a, "PUT", path, { ageRange }),
          400,
          "invalid_request",
        );
        expect(rows("wellbeing_baseline", a)).toHaveLength(0);
      },
    );

    it.each([
      ["a sleep label", { sleepBand: "< 5 h" }],
      ["a stress code of another list", { stressBand: "drained" }],
      ["an unknown key", { name: "Alex" }],
    ])("%s → 400 invalid_request", async (_name, body) => {
      const a = newCaller();
      expectCoded(await call(a, "PUT", path, body), 400, "invalid_request");
    });

    it("account deletion started → 409", async () => {
      const a = newCaller();
      fake.startAccountDeletion(a.id);
      expectCoded(
        await call(a, "PUT", path, { ageRange: "75_plus" }),
        409,
        "account_deletion_in_progress",
      );
    });
  });

  // ---- app config -----------------------------------------------------------

  describe("GET /v1/app/config", () => {
    it("is public and returns only the minimum versions", async () => {
      const response = await call(null, "GET", "/v1/app/config");
      expect(response.statusCode).toBe(200);
      expect(response.json()).toEqual({
        minimumVersion: { ios: "0.0.0", android: "0.0.0" },
      });
      expectSchema("AppConfig", response.json());
    });
  });

  // ---- boundaries, Today fields, replay before pre-checks -------------------

  describe("time windows (boundaries)", () => {
    const seedEntry = (
      caller: Caller,
      enrolmentId: string,
      code: string,
      kind: string,
      payload: object,
      occurredAt: string,
    ) =>
      fake.seedRow("programme_entries", {
        id: randomUUID(),
        user_id: caller.id,
        enrolment_id: enrolmentId,
        programme_code: code,
        submission_id: randomUUID(),
        kind,
        occurred_at: occurredAt,
        payload,
        created_at: new Date().toISOString(),
      });

    it("a check-in one minute before today's start (UTC) is not today's", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf", { status: "focus" });
      const window = dayWindow("UTC");
      seedEntry(
        a,
        bf,
        "bf",
        "checkin",
        { feel: "okay" },
        new Date(Date.parse(window.todayStart) - 60_000).toISOString(),
      );
      const body = (await call(a, "GET", "/v1/today")).json<{
        checkin: { doneToday: boolean };
      }>();
      expect(body.checkin.doneToday).toBe(false);
      seedEntry(a, bf, "bf", "checkin", { feel: "okay" }, window.todayStart);
      expect(
        (await call(a, "GET", "/v1/today")).json<{
          checkin: { doneToday: boolean };
        }>().checkin.doneToday,
      ).toBe(true);
    });

    it("the 7-day window starts at the local start of day −6 in the member's zone", async () => {
      const a = newCaller();
      fake.setProfileTimeZone(a.id, "Asia/Kolkata");
      const sd = await enrol(a, "sd");
      const start = Date.parse(dayWindow("Asia/Kolkata").last7Start);
      expect(start).toBe(
        startOfLocalDate(
          "Asia/Kolkata",
          addDays(localDate("Asia/Kolkata", Date.now()), -6),
        ),
      );
      seedEntry(
        a,
        sd,
        "sd",
        "sd.session",
        {},
        new Date(start + 60_000).toISOString(),
      );
      seedEntry(
        a,
        sd,
        "sd",
        "sd.session",
        {},
        new Date(start - 60_000).toISOString(),
      );
      const body = (await call(a, "GET", "/v1/today")).json<{
        programmes: { code: string; sessionsLast7Days?: number }[];
      }>();
      expect(body.programmes[0]?.sessionsLast7Days).toBe(1);
    });

    it("summary days=7 excludes a row 7 days and 1 hour old and keeps one 6 days 23 hours old", async () => {
      const a = newCaller();
      const ea = await enrol(a, "ea");
      const hour = 3_600_000;
      seedEntry(
        a,
        ea,
        "ea",
        "ea.mood",
        { mood: "low" },
        new Date(Date.now() - 7 * 24 * hour - hour).toISOString(),
      );
      seedEntry(
        a,
        ea,
        "ea",
        "ea.mood",
        { mood: "good" },
        new Date(Date.now() - 7 * 24 * hour + hour).toISOString(),
      );
      const body = (
        await call(a, "GET", "/v1/records/summary?programme=ea&days=7")
      ).json<{ entries: { payload: { mood: string } }[] }>();
      expect(body.entries.map((entry) => entry.payload.mood)).toEqual(["good"]);
    });
  });

  describe("Today fields of re, ck, be and sd", () => {
    it("each field holds its own metric or kind, with its values", async () => {
      const a = newCaller();
      for (const code of ["re", "ck", "be", "sd"]) await enrol(a, code);
      const submit = async (route: string, body: object) =>
        expect(
          (await post(a, `/v1/program-data/${route}`, body)).statusCode,
        ).toBe(201);
      await submit("re/labs", {
        egfr: 58,
        urineAcr: 42,
        alt: 31.25,
        labDate: LAB_DATE,
      });
      await submit("re/labs", { egfr: 61, labDate: "2026-10-01" });
      await submit("ck/done", { item: "flu_vaccine", doneOn: "2026-10-12" });
      await submit("be/diary", { fatigue: 6, symptoms: ["nausea"] });
      await submit("sd/falls", { occurredAt: minutesAgo(3) });
      await submit("sd/sessions", { settings: ["audio_on"] });
      const body = (await call(a, "GET", "/v1/today")).json<{
        programmes: Record<string, unknown>[];
      }>();
      expectSchema("Today", body);
      const block = (code: string) =>
        body.programmes.find((entry) => entry.code === code);
      expect(block("re")?.lastLabs).toEqual({
        egfr: { value: 61, at: "2026-10-01T00:00:00Z" },
        urineAcr: { value: 42, at: `${LAB_DATE}T00:00:00Z` },
        alt: { value: 31.25, at: `${LAB_DATE}T00:00:00Z` },
      });
      expect(block("ck")?.lastDone).toEqual({
        item: "flu_vaccine",
        doneOn: "2026-10-12",
        at: anyString,
      });
      expect(block("be")?.lastDiary).toEqual({ fatigue: 6, at: anyString });
      expect(block("sd")).toMatchObject({ sessionsLast7Days: 1 });
      const fallAt = block("sd")?.lastFallAt;
      expect(typeof fallAt).toBe("string");
      expect(
        Math.abs(Date.parse(fallAt as string) - Date.parse(minutesAgo(3))),
      ).toBeLessThan(60_000);
    });
  });

  describe("replay is detected before the pre-checks", () => {
    it("check-in: replay after leaving bf, with a bf answer → 200; other content → 409; never 422", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf", { status: "focus" });
      await enrol(a, "sf", { status: "focus" });
      const key = newKey();
      const body = { feel: "low", answers: { bf: "no" } };
      expect(
        (await post(a, "/v1/records/check-ins", body, key)).statusCode,
      ).toBe(201);
      await leave(a, bf);
      const replay = await post(a, "/v1/records/check-ins", body, key);
      expect(replay.statusCode).toBe(200);
      expect(replay.json<{ replayed: boolean }>().replayed).toBe(true);
      expectCoded(
        await post(
          a,
          "/v1/records/check-ins",
          { feel: "great", answers: { bf: "no" } },
          key,
        ),
        409,
        "idempotency_key_conflict",
      );
      expect(rows("programme_entries", a)).toHaveLength(2);
    });

    it("check-in: replay after leaving the only focus programme → 200, not no_focus_programme", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf", { status: "focus" });
      const key = newKey();
      const body = { stress: "some", answers: { bf: "one_or_more" } };
      expect(
        (await post(a, "/v1/records/check-ins", body, key)).statusCode,
      ).toBe(201);
      await leave(a, bf);
      expect(
        (await post(a, "/v1/records/check-ins", body, key)).statusCode,
      ).toBe(200);
      // A new submission is refused as before.
      expectCoded(
        await post(a, "/v1/records/check-ins", body),
        409,
        "no_focus_programme",
      );
      expect(rows("programme_entries", a)).toHaveLength(1);
    });

    it("rescue: a bf rescue replayed after leaving bf → 200; other content → 409", async () => {
      const a = newCaller();
      const bf = await enrol(a, "bf");
      const key = newKey();
      const body = { tool: "walk", programme: "bf", helped: "yes" };
      expect((await post(a, "/v1/records/rescues", body, key)).statusCode).toBe(
        201,
      );
      await leave(a, bf);
      expect((await post(a, "/v1/records/rescues", body, key)).statusCode).toBe(
        200,
      );
      expectCoded(
        await post(a, "/v1/records/rescues", { ...body, helped: "no" }, key),
        409,
        "idempotency_key_conflict",
      );
      expectCoded(
        await post(a, "/v1/records/rescues", body),
        409,
        "enrolment_left",
      );
      expect(rows("rescue_events", a)).toHaveLength(1);
    });

    it("lesson: a completed lesson replayed after leaving → 200; a new one → 409 enrolment_left", async () => {
      const a = newCaller();
      const ck = await enrol(a, "ck");
      expect(
        (
          await post(a, "/v1/records/lessons", {
            programme: "ck",
            lessonId: "ck.flu",
          })
        ).statusCode,
      ).toBe(201);
      await leave(a, ck);
      expect(
        (
          await post(a, "/v1/records/lessons", {
            programme: "ck",
            lessonId: "ck.flu",
          })
        ).statusCode,
      ).toBe(200);
      expectCoded(
        await post(a, "/v1/records/lessons", {
          programme: "ck",
          lessonId: "ck.salt",
        }),
        409,
        "enrolment_left",
      );
      expect(rows("lesson_progress", a)).toHaveLength(1);
    });
  });

  describe("rescue and lesson refusals", () => {
    it("rescue: missing key → 400 required; invalid key → 400 invalid; the key is checked before the body", async () => {
      const a = newCaller();
      expectCoded(
        await post(a, "/v1/records/rescues", { tool: "walk" }, null),
        400,
        "idempotency_key_required",
      );
      expectCoded(
        await post(a, "/v1/records/rescues", { tool: "walk" }, "ABC"),
        400,
        "idempotency_key_invalid",
      );
      expectCoded(
        await post(a, "/v1/records/rescues", { bad: true }, "ABC"),
        400,
        "idempotency_key_invalid",
      );
      expectCoded(
        await post(a, "/v1/records/lessons", { bad: true }, null),
        400,
        "idempotency_key_required",
      );
      expect(rows("rescue_events", a)).toHaveLength(0);
    });

    it("rescue: a shared rescue after account deletion started → 409, nothing written", async () => {
      const a = newCaller();
      fake.startAccountDeletion(a.id);
      expectCoded(
        await post(a, "/v1/records/rescues", { tool: "walk" }),
        409,
        "account_deletion_in_progress",
      );
      expect(rows("rescue_events", a)).toHaveLength(0);
    });

    it("lesson: left → 409 enrolment_left; deletion started → 409", async () => {
      const a = newCaller();
      await leave(a, await enrol(a, "be"));
      expectCoded(
        await post(a, "/v1/records/lessons", {
          programme: "be",
          lessonId: "be.sleep",
        }),
        409,
        "enrolment_left",
      );
      const b = newCaller();
      await enrol(b, "be");
      fake.startAccountDeletion(b.id);
      expectCoded(
        await post(b, "/v1/records/lessons", {
          programme: "be",
          lessonId: "be.sleep",
        }),
        409,
        "account_deletion_in_progress",
      );
      expect([
        ...rows("lesson_progress", a),
        ...rows("lesson_progress", b),
      ]).toHaveLength(0);
    });
  });

  // ---- contract -------------------------------------------------------------

  describe("contract (docs/contracts/openapi.yaml)", () => {
    const document = openApiDocument();
    const ROUTES: [string, string, string[]][] = [
      [
        "/v1/records/check-ins",
        "post",
        ["200", "201", "400", "401", "409", "413", "415", "422", "429", "502"],
      ],
      [
        "/v1/records/rescues",
        "post",
        [
          "200",
          "201",
          "400",
          "401",
          "404",
          "409",
          "413",
          "415",
          "422",
          "429",
          "502",
        ],
      ],
      [
        "/v1/records/lessons",
        "post",
        [
          "200",
          "201",
          "400",
          "401",
          "404",
          "409",
          "413",
          "415",
          "422",
          "429",
          "502",
        ],
      ],
      ["/v1/today", "get", ["200", "401", "429", "502"]],
      [
        "/v1/records/summary",
        "get",
        ["200", "400", "401", "404", "429", "502"],
      ],
      ["/v1/notifications/preferences", "get", ["200", "401", "429", "502"]],
      [
        "/v1/notifications/preferences",
        "patch",
        ["200", "400", "401", "404", "409", "413", "415", "422", "429", "502"],
      ],
      ["/v1/profile/baseline", "get", ["200", "401", "429", "502"]],
      [
        "/v1/profile/baseline",
        "put",
        ["200", "400", "401", "409", "413", "415", "422", "429", "502"],
      ],
      ["/v1/app/config", "get", ["200", "429"]],
    ];

    it.each(ROUTES)(
      "documents %s %s for app use with every status",
      (path, method, statuses) => {
        const operation = document.paths[path]?.[method] as
          Record<string, unknown> | undefined;
        expect(operation).toBeDefined();
        expect(operation?.["x-app-use"]).toBe(true);
        expect(Object.keys(operation?.responses as object).sort()).toEqual(
          [...statuses].sort(),
        );
        if (method === "post") {
          expect(operation?.parameters).toEqual([
            { $ref: "#/components/parameters/IdempotencyKey" },
          ]);
        }
      },
    );

    it("the version is bumped once for these routes", () => {
      expect(document.info.version).toBe("1.8.0");
    });

    it("the error enum is the programme event enum plus no_focus_programme", () => {
      const schema = openApiSchema("RecordsRequestRejected") as {
        properties: { code: { enum: unknown } };
      };
      expect(schema.properties.code.enum).toEqual([...recordsErrorCodes]);
      expect([...recordsErrorCodes]).toEqual([
        ...programmeDataErrorCodes,
        "no_focus_programme",
      ]);
      const programme = openApiSchema("ProgrammeDataRequestRejected") as {
        properties: { code: { enum: unknown } };
      };
      expect(programme.properties.code.enum).toEqual([
        ...programmeDataErrorCodes,
      ]);
    });

    it("the request schemas refuse what the API refuses", () => {
      expect(
        openApiErrors("CheckIn", { feel: "okay", answers: { bf: "no" } }),
      ).toEqual([]);
      expect(openApiErrors("CheckIn", { answers: { hw: "no" } })).not.toEqual(
        [],
      );
      expect(
        openApiErrors("Rescue", { tool: "walk", programme: "sf" }),
      ).not.toEqual([]);
      expect(
        openApiErrors("Rescue", {
          tool: "walk",
          programme: "bf",
          helped: "a_little",
        }),
      ).toEqual([]);
      expect(openApiErrors("PutBaseline", { ageRange: "35_35" })).not.toEqual(
        [],
      );
      expect(
        openApiErrors("PutBaseline", { ageRange: "75_plus", sleepBand: null }),
      ).toEqual([]);
      expect(
        openApiErrors("PatchNotificationPreferences", {
          programmeReminders: [{ programme: "bf", remindAt: "24:00" }],
        }),
      ).not.toEqual([]);
    });
  });

  // ---- logging --------------------------------------------------------------

  describe("logging", () => {
    it("no log line holds a member or enrolment id, a programme path or a token", async () => {
      const a = newCaller();
      await enrol(a, "bf");
      fake.failNext("POST", "rescue_events", {
        status: 500,
        code: "XX000",
        message: `internal ${DB_CANARY}`,
        hint: null,
      });
      expect(
        (
          await post(a, "/v1/records/rescues", {
            tool: "walk",
            programme: "bf",
          })
        ).statusCode,
      ).toBe(502);
      expect(
        logged.some((line) => line.includes("route=/v1/records/rescues")),
      ).toBe(true);
      for (const line of logged) {
        expect(line).not.toContain(TOKEN_CANARY);
        expect(line).not.toContain(DB_CANARY);
        expect(line).not.toMatch(/programme=[a-z]{2}/);
        for (const secret of secrets) expect(line).not.toContain(secret);
      }
    });
  });
});
