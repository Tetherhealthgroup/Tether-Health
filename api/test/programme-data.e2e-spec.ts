import { randomBytes, randomUUID } from "node:crypto";
import { Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import {
  FastifyAdapter,
  NestFastifyApplication,
} from "@nestjs/platform-fastify";
import { Test } from "@nestjs/testing";
import { getMetadataStorage } from "class-validator";
import { AppModule } from "../src/app.module";
import { TokenVerifier } from "../src/auth/token-verifier";
import { configureApp } from "../src/configure-app";
import { UserSupabaseClientFactory } from "../src/enrolments/user-supabase-client";
import { programmeDataErrorCodes } from "../src/programme-data/programme-data-errors";
import {
  PROGRAMME_ROUTES,
  routeName,
} from "../src/programme-data/programme-data.routes";
import { DB_CANARY, FakePostgrest } from "./support/fake-postgrest";
import {
  openApiDocument,
  openApiErrors,
  openApiSchema,
} from "./support/openapi";

/**
 * Programme event routes (POST /v1/program-data/:code/:kind), end to end
 * through the real Nest app, guard, filters and service and the real
 * supabase-js client, over the fake PostgREST's emulation of the
 * observations and programme_entries tables of migration
 * 202610180013_programme_records.sql (RLS insert check, grants, payload
 * and attribute triggers, CHECK constraints, submission unique keys and the
 * composite enrolment foreign key). Synthetic identities only.
 */

type Method = "GET" | "POST" | "PATCH" | "PUT" | "DELETE";

interface Caller {
  token: string;
  id: string;
  address: string;
}

const TOKEN_CANARY = "synthetic-bearer-canary-pd";
const NOTE_CANARY = "synthetic-note-canary-41f";
const PLACE_CANARY = "Synthetic Place Canary";
const LAB_DATE = "2026-09-30";
const newKey = () => randomBytes(16).toString("hex");
const asUuid = (key: string) =>
  `${key.slice(0, 8)}-${key.slice(8, 12)}-${key.slice(12, 16)}-${key.slice(16, 20)}-${key.slice(20)}`;
const minutesFromNow = (minutes: number) =>
  new Date(Date.now() + minutes * 60_000).toISOString();

/** A valid body per route (every field present where it can be). */
const VALID: Record<string, Record<string, unknown>> = {
  "hw/readings": { systolic: 132, diastolic: 84, pulse: 70 },
  "hw/lipids": {
    total: 212,
    ldl: 138.5,
    hdl: 46,
    triglycerides: 150,
    labDate: LAB_DATE,
  },
  "st/readings": {
    reading: 142,
    when: "2_h_after_meal",
    feelings: ["fine", "tired"],
    note: NOTE_CANARY,
  },
  "st/a1c": { a1c: 7.4, labDate: LAB_DATE },
  "re/labs": { egfr: 58, urineAcr: 42, alt: 31.25, labDate: LAB_DATE },
  "ca/zone-checks": {
    zone: "yellow",
    symptoms: ["wheezing", "can_t_speak_in_full_sentences"],
    peakFlow: 310,
  },
  "ca/symptoms": {
    symptoms: ["wheezing", "woke_at_night"],
    severity: "mild",
    triggers: ["cold_air"],
    note: NOTE_CANARY,
  },
  "ea/moods": { mood: "low", topics: ["work", "sleep"] },
  "ea/check-backs": { change: "same", reachedOut: "i_don_t_want_to" },
  "sd/sessions": { settings: ["audio_on", "large_text", "captions"] },
  "sd/falls": {},
  "sf/pauses": { reason: "can_t_sleep" },
  "ck/done": {
    item: "flu_vaccine",
    doneOn: "2026-10-12",
    place: PLACE_CANARY,
  },
  "be/diary": { fatigue: 6, symptoms: ["nausea"] },
  "be/survivorship": { feeling: "mixed" },
};

/** What each valid body writes: [table, kind or metric][]. */
const WRITES: Record<string, [string, string][]> = {
  "hw/readings": [
    ["observations", "bp_systolic"],
    ["observations", "bp_diastolic"],
    ["observations", "heart_rate"],
  ],
  "hw/lipids": [
    ["observations", "chol_total"],
    ["observations", "chol_ldl"],
    ["observations", "chol_hdl"],
    ["observations", "triglycerides"],
  ],
  "st/readings": [["observations", "glucose"]],
  "st/a1c": [["observations", "a1c"]],
  "re/labs": [
    ["observations", "egfr"],
    ["observations", "urine_acr"],
    ["observations", "alt"],
  ],
  "ca/zone-checks": [
    ["programme_entries", "ca.zone_check"],
    ["observations", "peak_flow"],
  ],
  "ca/symptoms": [["programme_entries", "ca.symptom"]],
  "ea/moods": [["programme_entries", "ea.mood"]],
  "ea/check-backs": [["programme_entries", "ea.check_back"]],
  "sd/sessions": [["programme_entries", "sd.session"]],
  "sd/falls": [["programme_entries", "sd.fall"]],
  "sf/pauses": [["programme_entries", "sf.pause"]],
  "ck/done": [["programme_entries", "ck.done"]],
  "be/diary": [["programme_entries", "be.diary"]],
  "be/survivorship": [["programme_entries", "be.survivorship"]],
};

const PROGRAMMES = ["hw", "st", "re", "ca", "ea", "sd", "sf", "ck", "be"];
const schemaName = (name: string) =>
  `Submit${name
    .split(/[/-]/)
    .map((part) => part[0]!.toUpperCase() + part.slice(1))
    .join("")}`;

describe("Programme event routes (e2e)", () => {
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
    expect(response.body).not.toContain(NOTE_CANARY);
    expect(response.body).not.toContain("Failing row contains");
    return response;
  };

  const submit = (
    caller: Caller | null,
    name: string,
    body: unknown,
    key: string | null = newKey(),
  ) =>
    call(
      caller,
      "POST",
      `/v1/program-data/${name}`,
      body,
      key === null ? {} : { "idempotency-key": key },
    );

  /** Enrols `caller` in `code` (learn_only: no focus cap) with live core. */
  const enrol = async (caller: Caller, code: string, core = true) => {
    const created = await call(caller, "POST", "/v1/enrolments", {
      programmeCode: code,
      status: "learn_only",
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
    expect(typeof body.requestId).toBe("string");
    expect(
      openApiErrors("ProgrammeDataRequestRejected", response.json()),
    ).toEqual([]);
  };

  const rowsOf = (caller: Caller) => ({
    observations: fake
      .table("observations")
      .filter((row) => row.user_id === caller.id),
    entries: fake
      .table("programme_entries")
      .filter((row) => row.user_id === caller.id),
  });
  const countOf = (caller: Caller) => {
    const rows = rowsOf(caller);
    return rows.observations.length + rows.entries.length;
  };

  describe("one valid submit per route", () => {
    let a: Caller;
    const enrolments = new Map<string, string>();

    beforeAll(async () => {
      a = newCaller();
      for (const code of PROGRAMMES) enrolments.set(code, await enrol(a, code));
    });

    it("the table covers all 15 routes", () => {
      expect(Object.keys(VALID).sort()).toEqual(
        PROGRAMME_ROUTES.map(routeName).sort(),
      );
    });

    it.each(Object.keys(VALID))(
      "%s → 201 and writes its rows into the caller's enrolment",
      async (name) => {
        const key = newKey();
        const before = rowsOf(a);
        const response = await submit(a, name, VALID[name], key);
        expect(response.statusCode).toBe(201);
        expect(response.json()).toEqual({ submissionId: asUuid(key) });
        expect(
          openApiErrors("ProgrammeRecordCreated", response.json()),
        ).toEqual([]);
        // The body is valid under the route's documented request schema.
        expect(openApiErrors(schemaName(name), VALID[name])).toEqual([]);
        const code = name.split("/")[0] as string;
        const after = rowsOf(a);
        const newRows = [
          ...after.observations
            .filter((row) => !before.observations.some((o) => o.id === row.id))
            .map((row) => ["observations", row] as const),
          ...after.entries
            .filter((row) => !before.entries.some((e) => e.id === row.id))
            .map((row) => ["programme_entries", row] as const),
        ];
        expect(
          newRows.map(([table, row]) => [table, row.metric ?? row.kind]).sort(),
        ).toEqual([...(WRITES[name] ?? [])].sort());
        for (const [, row] of newRows) {
          expect(row).toMatchObject({
            user_id: a.id,
            enrolment_id: enrolments.get(code),
            programme_code: code,
            submission_id: asUuid(key),
          });
        }
      },
    );

    it("stores the mapped payloads, units, attributes and times", () => {
      const rows = rowsOf(a);
      const metric = (name: string) =>
        rows.observations.find((row) => row.metric === name);
      const kind = (name: string) =>
        rows.entries.find((row) => row.kind === name);
      expect(metric("bp_systolic")).toMatchObject({
        value: 132,
        unit_ucum: "mm[Hg]",
      });
      expect(metric("heart_rate")).toMatchObject({
        value: 70,
        unit_ucum: "/min",
      });
      expect(metric("chol_ldl")).toMatchObject({
        value: 138.5,
        unit_ucum: "mg/dL",
        effective_at: `${LAB_DATE}T00:00:00Z`,
      });
      expect(metric("glucose")).toMatchObject({
        unit_ucum: "mg/dL",
        attributes: {
          timing: "2_h_after_meal",
          feelings: ["fine", "tired"],
          note: NOTE_CANARY,
        },
      });
      expect(metric("egfr")).toMatchObject({ unit_ucum: "mL/min/{1.73_m2}" });
      expect(metric("alt")).toMatchObject({ value: 31.25, unit_ucum: "U/L" });
      expect(metric("peak_flow")).toMatchObject({
        value: 310,
        unit_ucum: "L/min",
      });
      expect(kind("ca.zone_check")?.payload).toEqual({
        zone: "yellow",
        symptoms: ["wheezing", "can_t_speak_in_full_sentences"],
      });
      expect(kind("ea.check_back")?.payload).toEqual({
        change: "same",
        reached_out: "i_don_t_want_to",
      });
      expect(kind("ck.done")?.payload).toEqual({
        item: "flu_vaccine",
        done_on: "2026-10-12",
        place: PLACE_CANARY,
      });
      expect(kind("sd.fall")?.payload).toEqual({});
      expect(kind("be.diary")?.payload).toEqual({
        fatigue: 6,
        symptoms: ["nausea"],
      });
    });

    it("uses a sent time; the server's time otherwise", async () => {
      const at = minutesFromNow(-90);
      const checked = minutesFromNow(-30);
      const key = newKey();
      expect(
        (await submit(a, "sf/pauses", { reason: "bored", occurredAt: at }))
          .statusCode,
      ).toBe(201);
      expect(
        (
          await submit(
            a,
            "ca/zone-checks",
            { zone: "green", peakFlow: 400, checkedAt: checked },
            key,
          )
        ).statusCode,
      ).toBe(201);
      const rows = rowsOf(a);
      expect(
        rows.entries.find(
          (row) =>
            row.payload &&
            (row.payload as { reason?: string }).reason === "bored",
        )?.occurred_at,
      ).toBe(at);
      const submission = asUuid(key);
      expect(
        rows.entries.find((row) => row.submission_id === submission)
          ?.occurred_at,
      ).toBe(checked);
      expect(
        rows.observations.find((row) => row.submission_id === submission)
          ?.effective_at,
      ).toBe(checked);
      const before = Date.now();
      expect((await submit(a, "sd/falls", {})).statusCode).toBe(201);
      const fall = rowsOf(a)
        .entries.filter((row) => row.kind === "sd.fall")
        .pop();
      expect(Date.parse(fall?.occurred_at as string)).toBeGreaterThanOrEqual(
        before - 1000,
      );
    });
  });

  describe("Idempotency-Key and replay", () => {
    let a: Caller;
    beforeAll(async () => {
      a = newCaller();
      for (const code of ["hw", "ca", "ck", "ea"]) await enrol(a, code);
    });

    it("a repeat with the same key and body → 200 replayed, nothing written", async () => {
      const key = newKey();
      expect(
        (await submit(a, "hw/readings", VALID["hw/readings"], key)).statusCode,
      ).toBe(201);
      const before = countOf(a);
      const replay = await submit(a, "hw/readings", VALID["hw/readings"], key);
      expect(replay.statusCode).toBe(200);
      expect(replay.json()).toEqual({
        submissionId: asUuid(key),
        replayed: true,
      });
      expect(openApiErrors("ProgrammeRecordReplayed", replay.json())).toEqual(
        [],
      );
      expect(countOf(a)).toBe(before);
    });

    it("the UUID form of a key is the same submission", async () => {
      const key = newKey();
      expect(
        (await submit(a, "ea/moods", { mood: "okay" }, key)).statusCode,
      ).toBe(201);
      const replay = await submit(
        a,
        "ea/moods",
        { mood: "okay" },
        asUuid(key).toUpperCase(),
      );
      expect(replay.statusCode).toBe(200);
    });

    it("times are never compared: a later or omitted time is still a replay, first time wins", async () => {
      const key = newKey();
      const first = minutesFromNow(-60);
      expect(
        (
          await submit(
            a,
            "hw/readings",
            { systolic: 121, diastolic: 81, measuredAt: first },
            key,
          )
        ).statusCode,
      ).toBe(201);
      for (const measuredAt of [minutesFromNow(-1), undefined]) {
        const replay = await submit(
          a,
          "hw/readings",
          { systolic: 121, diastolic: 81, measuredAt },
          key,
        );
        expect(replay.statusCode).toBe(200);
      }
      const entryKey = newKey();
      expect(
        (
          await submit(
            a,
            "ea/moods",
            { mood: "good", occurredAt: first },
            entryKey,
          )
        ).statusCode,
      ).toBe(201);
      expect(
        (await submit(a, "ea/moods", { mood: "good" }, entryKey)).statusCode,
      ).toBe(200);
      const stored = rowsOf(a).observations.filter(
        (row) => row.submission_id === asUuid(key),
      );
      expect(stored.map((row) => row.effective_at)).toEqual([first, first]);
    });

    it.each([
      ["a different value", { systolic: 122, diastolic: 81 }],
      ["a missing optional value", { systolic: 121 + 100, diastolic: 81 }],
      ["an added optional value", { systolic: 121, diastolic: 81, pulse: 60 }],
    ])(
      "the same key with %s → 409 idempotency_key_conflict, nothing written",
      async (_name, body) => {
        const key = newKey();
        expect(
          (
            await submit(
              a,
              "hw/readings",
              { systolic: 121, diastolic: 81 },
              key,
            )
          ).statusCode,
        ).toBe(201);
        const before = countOf(a);
        expectCoded(
          await submit(a, "hw/readings", body, key),
          409,
          "idempotency_key_conflict",
        );
        expect(countOf(a)).toBe(before);
      },
    );

    it("the same key with a different entry payload → 409", async () => {
      const key = newKey();
      const body = { item: "flu_vaccine", doneOn: "2026-10-01" };
      expect((await submit(a, "ck/done", body, key)).statusCode).toBe(201);
      expectCoded(
        await submit(a, "ck/done", { ...body, doneOn: "2026-10-02" }, key),
        409,
        "idempotency_key_conflict",
      );
    });

    describe("ca/zone-checks: entry first, then the observation", () => {
      it("a key already used for another entry → 409 and no peak flow is written", async () => {
        const key = newKey();
        expect(
          (await submit(a, "ca/symptoms", { symptoms: ["coughing"] }, key))
            .statusCode,
        ).toBe(201);
        const before = rowsOf(a).observations.length;
        expectCoded(
          await submit(
            a,
            "ca/zone-checks",
            { zone: "red", peakFlow: 120 },
            key,
          ),
          409,
          "idempotency_key_conflict",
        );
        expect(rowsOf(a).observations.length).toBe(before);
        const inserts = fake.requests.filter(
          (request) =>
            request.method === "POST" && request.search.includes("columns"),
        );
        expect(inserts.at(-1)?.path).toBe("/rest/v1/programme_entries");
      });

      it("a lost peak flow is completed by a retry (201), then the retry replays (200)", async () => {
        const key = newKey();
        const body = { zone: "yellow", symptoms: ["coughing"], peakFlow: 280 };
        fake.failNext("POST", "observations", {
          status: 503,
          code: "57P01",
          message: "synthetic termination",
          hint: null,
        });
        expect((await submit(a, "ca/zone-checks", body, key)).statusCode).toBe(
          502,
        );
        const submission = asUuid(key);
        expect(
          rowsOf(a).entries.filter((row) => row.submission_id === submission),
        ).toHaveLength(1);
        expect(
          rowsOf(a).observations.filter(
            (row) => row.submission_id === submission,
          ),
        ).toHaveLength(0);
        expect((await submit(a, "ca/zone-checks", body, key)).statusCode).toBe(
          201,
        );
        expect(
          rowsOf(a).observations.filter(
            (row) => row.submission_id === submission,
          ),
        ).toHaveLength(1);
        expect((await submit(a, "ca/zone-checks", body, key)).statusCode).toBe(
          200,
        );
        expectCoded(
          await submit(a, "ca/zone-checks", { ...body, peakFlow: 281 }, key),
          409,
          "idempotency_key_conflict",
        );
      });

      it("the entry is written before the observation", async () => {
        const start = fake.requests.length;
        expect(
          (await submit(a, "ca/zone-checks", VALID["ca/zone-checks"]))
            .statusCode,
        ).toBe(201);
        const writes = fake.requests
          .slice(start)
          .filter(
            (request) =>
              request.method === "POST" && !request.path.includes("/rpc/"),
          )
          .map((request) => request.path);
        expect(writes).toEqual([
          "/rest/v1/programme_entries",
          "/rest/v1/observations",
        ]);
      });
    });

    it("missing key → 400 idempotency_key_required, nothing written", async () => {
      const before = countOf(a);
      expectCoded(
        await submit(a, "hw/readings", VALID["hw/readings"], null),
        400,
        "idempotency_key_required",
      );
      expect(countOf(a)).toBe(before);
    });

    it.each(["", "not-a-key", newKey().toUpperCase(), `${newKey()}0`])(
      "key %j → 400 idempotency_key_invalid",
      async (key) => {
        expectCoded(
          await submit(a, "hw/readings", VALID["hw/readings"], key),
          400,
          "idempotency_key_invalid",
        );
      },
    );

    it("check order: 401, then the key, then the body", async () => {
      const bad = { systolic: "high", extra: true };
      expect(
        (await submit(null, "hw/readings", bad, "bad-key")).statusCode,
      ).toBe(401);
      expectCoded(
        await submit(a, "hw/readings", bad, "bad-key"),
        400,
        "idempotency_key_invalid",
      );
      expectCoded(
        await submit(a, "hw/readings", bad, null),
        400,
        "idempotency_key_required",
      );
      expectCoded(await submit(a, "hw/readings", bad), 400, "invalid_request");
    });

    it("the key is checked before the pre-checks (not enrolled)", async () => {
      expectCoded(
        await submit(a, "st/a1c", VALID["st/a1c"], null),
        400,
        "idempotency_key_required",
      );
      expectCoded(
        await submit(a, "st/a1c", VALID["st/a1c"]),
        404,
        "enrolment_not_found",
      );
    });
  });

  describe("body validation (400 invalid_request, 422 value_out_of_range)", () => {
    let a: Caller;
    beforeAll(async () => {
      a = newCaller();
      for (const code of PROGRAMMES) await enrol(a, code);
    });

    it.each([
      ["hw/readings", { ...VALID["hw/readings"], arm: "left" }, "unknown key"],
      ["sd/falls", { note: "x" }, "unknown key on an empty body"],
      ["hw/readings", { diastolic: 80 }, "missing required"],
      [
        "hw/readings",
        { systolic: 120.5, diastolic: 80 },
        "fraction in an integer",
      ],
      ["hw/readings", { systolic: "120", diastolic: 80 }, "string number"],
      ["hw/readings", { systolic: null, diastolic: 80 }, "null required"],
      [
        "hw/readings",
        { systolic: 120, diastolic: 80, pulse: null },
        "null optional",
      ],
      ["st/a1c", { a1c: 7.4125, labDate: LAB_DATE }, "four decimal places"],
      ["st/a1c", { labDate: LAB_DATE }, "a1c missing"],
      ["st/a1c", { a1c: 7.4 }, "labDate missing"],
      ["hw/lipids", { labDate: LAB_DATE }, "no lipid value"],
      ["re/labs", { labDate: LAB_DATE }, "no lab value"],
      ["hw/lipids", { hdl: 50, labDate: "1899-12-31" }, "lab date before 1900"],
      [
        "hw/lipids",
        {
          hdl: 50,
          labDate: new Date(Date.now() + 3 * 86_400_000)
            .toISOString()
            .slice(0, 10),
        },
        "lab date after tomorrow",
      ],
      ["hw/lipids", { hdl: 50, labDate: "2026-02-30" }, "impossible lab date"],
      ["ck/done", { item: "flu_vaccine" }, "doneOn missing"],
      [
        "ck/done",
        { item: "Flu vaccine", doneOn: "2026-10-12" },
        "item not a code",
      ],
      [
        "ck/done",
        { item: "flu_vaccine", doneOn: "12/10/2026" },
        "doneOn not a date",
      ],
      ["ea/moods", { mood: "Low" }, "label instead of code"],
      ["ea/moods", { mood: "low", topics: ["work", "work"] }, "repeated code"],
      ["ea/moods", { mood: "low", topics: "work" }, "code instead of list"],
      ["ca/symptoms", { symptoms: [] }, "empty required list"],
      ["ca/zone-checks", { zone: "orange" }, "zone not in list"],
      ["be/diary", { fatigue: 11 }, "fatigue above 10"],
      ["be/diary", { fatigue: 5.5 }, "fractional fatigue"],
      [
        "sf/pauses",
        { reason: "bored", occurredAt: minutesFromNow(6) },
        "time over 5 minutes ahead",
      ],
      [
        "sf/pauses",
        { reason: "bored", occurredAt: "2026-10-22T10:00:00" },
        "time without offset",
      ],
      [
        "hw/readings",
        { systolic: 120, diastolic: 80, measuredAt: minutesFromNow(10) },
        "future reading",
      ],
      ["sf/pauses", [{ reason: "bored" }], "array body"],
    ] as [string, unknown, string][])(
      "%s %j (%s) → 400, nothing written",
      async (name, body) => {
        const before = countOf(a);
        expectCoded(await submit(a, name, body), 400, "invalid_request");
        expect(countOf(a)).toBe(before);
      },
    );

    it("a time within the 5-minute tolerance is accepted", async () => {
      expect(
        (
          await submit(a, "sf/pauses", {
            reason: "bored",
            occurredAt: minutesFromNow(4),
          })
        ).statusCode,
      ).toBe(201);
    });

    it("tomorrow's UTC date is an accepted lab date", async () => {
      const tomorrow = new Date(Date.now() + 86_400_000)
        .toISOString()
        .slice(0, 10);
      expect(
        (await submit(a, "st/a1c", { a1c: 6.1, labDate: tomorrow })).statusCode,
      ).toBe(201);
    });

    it.each([
      ["hw/readings", { systolic: 251, diastolic: 80 }],
      ["hw/readings", { systolic: 69, diastolic: 80 }],
      ["hw/readings", { systolic: 120, diastolic: 151 }],
      ["hw/readings", { systolic: 120, diastolic: 39 }],
      ["st/readings", { reading: 19.999 }],
      ["st/readings", { reading: 600.001 }],
      ["ca/zone-checks", { zone: "green", peakFlow: 49 }],
      ["ca/zone-checks", { zone: "green", peakFlow: 901 }],
    ])(
      "%s %j → 422 value_out_of_range, nothing written",
      async (name, body) => {
        const before = countOf(a);
        expectCoded(await submit(a, name, body), 422, "value_out_of_range");
        expect(countOf(a)).toBe(before);
      },
    );

    it.each([
      ["hw/readings", { systolic: 70, diastolic: 40 }],
      ["hw/readings", { systolic: 250, diastolic: 150 }],
      ["st/readings", { reading: 20 }],
      ["ca/zone-checks", { zone: "green", peakFlow: 900 }],
    ])("%s %j at the range bound → 201", async (name, body) => {
      expect((await submit(a, name, body)).statusCode).toBe(201);
    });

    it.each([
      ["hw/readings", { systolic: 120, diastolic: 80, pulse: -1 }],
      ["hw/lipids", { total: 10000.001, labDate: LAB_DATE }],
      ["hw/lipids", { total: 1e7, labDate: LAB_DATE }],
      ["st/readings", { reading: 100, note: " padded " }],
      ["ca/symptoms", { symptoms: ["coughing"], note: "x".repeat(501) }],
      ["ck/done", { item: "flu_vaccine", doneOn: "2026-10-12", place: "" }],
      ["sf/pauses", { reason: "bored", occurredAt: "1999-12-31T23:59:59Z" }],
    ])(
      "%s %j → 422 invalid_record (database bound), nothing written",
      async (name, body) => {
        const before = countOf(a);
        expectCoded(await submit(a, name, body), 422, "invalid_record");
        expect(countOf(a)).toBe(before);
      },
    );
  });

  describe("pre-checks and programme separation", () => {
    it("not enrolled → 404 enrolment_not_found", async () => {
      const a = newCaller();
      expectCoded(
        await submit(a, "hw/readings", VALID["hw/readings"]),
        404,
        "enrolment_not_found",
      );
    });

    it("left → 409 enrolment_left, nothing written", async () => {
      const a = newCaller();
      const id = await enrol(a, "ea");
      expect(
        (await call(a, "PATCH", `/v1/enrolments/${id}`, { status: "left" }))
          .statusCode,
      ).toBe(200);
      expectCoded(
        await submit(a, "ea/moods", { mood: "low" }),
        409,
        "enrolment_left",
      );
      expect(countOf(a)).toBe(0);
    });

    it("no live core consent → 409 core_consent_required, nothing written", async () => {
      const a = newCaller();
      await enrol(a, "sd", false);
      expectCoded(
        await submit(a, "sd/falls", {}),
        409,
        "core_consent_required",
      );
      expect(countOf(a)).toBe(0);
    });

    it("account deletion started → 409 account_deletion_in_progress, nothing written", async () => {
      const a = newCaller();
      await enrol(a, "sf");
      fake.startAccountDeletion(a.id);
      expectCoded(
        await submit(a, "sf/pauses", { reason: "bored" }),
        409,
        "account_deletion_in_progress",
      );
      expect(countOf(a)).toBe(0);
    });

    it("B cannot write into A's enrolment: B is not enrolled → 404 and A's rows are unchanged", async () => {
      const a = newCaller();
      const b = newCaller();
      await enrol(a, "hw");
      expect(
        (await submit(a, "hw/readings", VALID["hw/readings"])).statusCode,
      ).toBe(201);
      const aRows = fake
        .table("observations")
        .filter((row) => row.user_id === a.id).length;
      expectCoded(
        await submit(b, "hw/readings", VALID["hw/readings"]),
        404,
        "enrolment_not_found",
      );
      expect(
        fake.table("observations").filter((row) => row.user_id === a.id),
      ).toHaveLength(aRows);
      expect(countOf(b)).toBe(0);
    });

    it("B's same key as A's is B's own submission (keys include the enrolment)", async () => {
      const a = newCaller();
      const b = newCaller();
      const aEnrolment = await enrol(a, "be");
      const bEnrolment = await enrol(b, "be");
      const key = newKey();
      expect(
        (await submit(a, "be/survivorship", { feeling: "good" }, key))
          .statusCode,
      ).toBe(201);
      expect(
        (await submit(b, "be/survivorship", { feeling: "hard" }, key))
          .statusCode,
      ).toBe(201);
      expect(rowsOf(a).entries.map((row) => row.enrolment_id)).toEqual([
        aEnrolment,
      ]);
      expect(rowsOf(b).entries.map((row) => row.enrolment_id)).toEqual([
        bEnrolment,
      ]);
    });

    it("a submit writes only into the path's programme, never another of the caller's", async () => {
      const a = newCaller();
      const hw = await enrol(a, "hw");
      await enrol(a, "st");
      expect(
        (await submit(a, "hw/lipids", { hdl: 55, labDate: LAB_DATE }))
          .statusCode,
      ).toBe(201);
      expect(
        rowsOf(a).observations.map((row) => [
          row.enrolment_id,
          row.programme_code,
        ]),
      ).toEqual([[hw, "hw"]]);
    });

    it("the RLS insert check refuses a direct write into another member's enrolment (fake model)", async () => {
      const a = newCaller();
      const b = newCaller();
      const aEnrolment = await enrol(a, "sf");
      const response = await fake.fetch(
        "https://project.example.com/rest/v1/programme_entries",
        {
          method: "POST",
          headers: {
            authorization: `Bearer ${b.token}`,
            "content-type": "application/json",
          },
          body: JSON.stringify([
            {
              user_id: b.id,
              enrolment_id: aEnrolment,
              programme_code: "sf",
              submission_id: randomUUID(),
              kind: "sf.pause",
              occurred_at: new Date().toISOString(),
              payload: { reason: "bored" },
            },
          ]),
        },
      );
      expect(response.status).toBe(403);
      expect(((await response.json()) as { code: string }).code).toBe("42501");
      expect(countOf(a) + countOf(b)).toBe(0);
    });

    it("leaving between the pre-checks and the insert → 409 record_not_allowed, nothing written", async () => {
      const a = newCaller();
      const id = await enrol(a, "ck");
      fake.interleave("POST", "programme_entries", () =>
        fake.forceEnrolmentStatus(id, "left"),
      );
      expectCoded(
        await submit(a, "ck/done", VALID["ck/done"]),
        409,
        "record_not_allowed",
      );
      expect(countOf(a)).toBe(0);
    });

    it("the enrolment deleted meanwhile (23503) → 404 enrolment_not_found", async () => {
      const a = newCaller();
      await enrol(a, "st");
      fake.failNext("POST", "observations", {
        status: 409,
        code: "23503",
        message: "synthetic foreign key violation",
        hint: null,
      });
      expectCoded(
        await submit(a, "st/a1c", VALID["st/a1c"]),
        404,
        "enrolment_not_found",
      );
    });

    it.each(["TH026", "TH027", "XX000"])(
      "an unhandled %s → 502 without detail; the log has the route template and SQLSTATE only",
      async (code) => {
        const a = newCaller();
        await enrol(a, "re");
        fake.failNext("POST", "observations", {
          status: 400,
          code,
          message: "synthetic failure",
          hint: null,
        });
        const start = logged.length;
        const response = await submit(a, "re/labs", VALID["re/labs"]);
        expect(response.statusCode).toBe(502);
        const body = response.json<Record<string, unknown>>();
        expect(Object.keys(body).sort()).toEqual(
          ["error", "requestId", "statusCode"].sort(),
        );
        expect(body).toMatchObject({
          statusCode: 502,
          error: "Service unavailable",
        });
        const lines = logged.slice(start);
        expect(lines.some((line) => line.includes(`code=${code}`))).toBe(true);
        for (const line of lines) {
          expect(line).toContain("route=/v1/program-data/:code/:kind");
        }
      },
    );
  });

  describe("routes", () => {
    it.each([
      ["POST", "/v1/program-data/hw/moods"],
      ["POST", "/v1/program-data/bf/readings"],
      ["POST", "/v1/program-data/nu/habit"],
      ["POST", "/v1/program-data/HW/readings"],
      ["PUT", "/v1/program-data/hw/targets"],
      ["PUT", "/v1/program-data/sd/safety"],
      ["GET", "/v1/program-data/hw/readings"],
    ])("%s %s is not a route → 404, nothing written", async (method, url) => {
      const a = newCaller();
      await enrol(a, "hw");
      const response = await call(
        a,
        method as Method,
        url,
        method === "GET" ? undefined : {},
        {
          "idempotency-key": newKey(),
        },
      );
      expect(response.statusCode).toBe(404);
      expect(countOf(a)).toBe(0);
    });

    it("requires a token on every route", async () => {
      for (const route of PROGRAMME_ROUTES) {
        expect(
          (await submit(null, routeName(route), VALID[routeName(route)]))
            .statusCode,
        ).toBe(401);
      }
    });
  });

  describe("contract (docs/contracts/openapi.yaml)", () => {
    const document = openApiDocument();

    it("documents each of the 15 routes for app use, with the key and every code", () => {
      for (const route of PROGRAMME_ROUTES) {
        const operation = document.paths[`/v1/program-data/${routeName(route)}`]
          ?.post as Record<string, unknown> | undefined;
        expect(operation).toBeDefined();
        expect(operation?.["x-app-use"]).toBe(true);
        expect(operation?.parameters).toEqual([
          { $ref: "#/components/parameters/IdempotencyKey" },
        ]);
        expect(Object.keys(operation?.responses as object).sort()).toEqual(
          ["200", "201", "400", "401", "404", "409", "422", "502"].sort(),
        );
      }
      const others = Object.keys(document.paths).filter((path) =>
        /^\/v1\/program-data\/[^/]+\/[^/]+$/.test(path),
      );
      expect(others).toHaveLength(15);
      expect(document.info.version).toBe("1.7.0");
    });

    it("each request schema has the DTO's fields, required set and option codes", () => {
      for (const route of PROGRAMME_ROUTES) {
        const schema = openApiSchema(schemaName(routeName(route))) as {
          required?: string[];
          properties: Record<
            string,
            { enum?: string[]; items?: { enum?: string[] } }
          >;
        };
        expect(Object.keys(schema.properties).sort()).toEqual(
          Object.keys(route.fields).sort(),
        );
        const metadata = getMetadataStorage().getTargetValidationMetadatas(
          route.dto,
          "",
          true,
          false,
        );
        const optional = new Set(
          metadata
            .filter((entry) => entry.type === "conditionalValidation")
            .map((entry) => entry.propertyName),
        );
        expect([...(schema.required ?? [])].sort()).toEqual(
          Object.keys(route.fields)
            .filter((field) => !optional.has(field))
            .sort(),
        );
        for (const [field, codes] of Object.entries(route.options)) {
          const property = schema.properties[field];
          expect(property?.enum ?? property?.items?.enum).toEqual([...codes]);
        }
      }
    });

    it("the error code enum is programmeDataErrorCodes; the enrolment enum is unchanged", () => {
      const schema = openApiSchema("ProgrammeDataRequestRejected") as {
        properties: { code: { enum: unknown } };
      };
      expect(schema.properties.code.enum).toEqual([...programmeDataErrorCodes]);
    });

    it("an unknown key fails the documented request schema too", () => {
      expect(
        openApiErrors("SubmitHwReadings", {
          systolic: 120,
          diastolic: 80,
          arm: "left",
        }),
      ).not.toEqual([]);
      expect(
        openApiErrors("SubmitHwLipids", { labDate: LAB_DATE }),
      ).not.toEqual([]);
    });
  });

  describe("logging", () => {
    it("no log line holds a member or enrolment id, a concrete path, a value or a token", () => {
      expect(logged.length).toBeGreaterThan(0);
      for (const line of logged) {
        expect(line).not.toMatch(/\/v1\/program-data\/[a-z]{2}\//i);
        expect(line).not.toContain(TOKEN_CANARY);
        expect(line).not.toContain(NOTE_CANARY);
        expect(line).not.toContain(PLACE_CANARY);
        expect(line).not.toContain(DB_CANARY);
        for (const secret of secrets) expect(line).not.toContain(secret);
      }
    });
  });
});
