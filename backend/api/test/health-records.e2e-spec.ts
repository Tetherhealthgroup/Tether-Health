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
import { healthRecordErrorCodes } from "../src/records-fhir/records-fhir-errors";
import { DB_CANARY, FakePostgrest } from "./support/fake-postgrest";
import {
  openApiDocument,
  openApiErrors,
  openApiSchema,
} from "./support/openapi";

/**
 * Health records (manual values, review, conflicts and the records reads)
 * end to end through the real app, guard, filters and services and the real
 * supabase-js client, over the fake PostgREST's emulation of 202610180015
 * (RLS, grants, keys and the routing rule). Synthetic identities and values
 * only; no network.
 */

type Method = "GET" | "POST" | "PATCH" | "DELETE";

interface Caller {
  token: string;
  id: string;
  address: string;
}

const TOKEN_CANARY = "synthetic-bearer-canary-records";
const NAME_CANARY = "Synthetic Vaccine Canary";
const SHOWN = { consentVersion: "v1-draft", locale: "en" };
const LOINC = "http://loinc.org";
const DAY = "2026-10-01";
const AT = `${DAY}T12:00:00.000Z`;

describe("Health records (e2e)", () => {
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
    return response;
  };

  const expectCoded = (
    response: { statusCode: number; json: () => unknown },
    status: number,
    code: string,
  ) => {
    expect(response.statusCode).toBe(status);
    expect(response.json()).toMatchObject({
      statusCode: status,
      error: "Request rejected",
      code,
    });
    expect(
      openApiErrors("HealthRecordRequestRejected", response.json()),
    ).toEqual([]);
  };

  /** Enrols `caller` in each programme with core and, unless excluded, records_import. */
  const enrol = async (
    caller: Caller,
    codes: string[],
    { withoutImport = [] as string[] } = {},
  ) => {
    const ids: Record<string, string> = {};
    for (const code of codes) {
      const created = await call(caller, "POST", "/v1/enrolments", {
        programmeCode: code,
        status: "learn_only",
        ...(["bf", "sf"].includes(code) ? { mode: "quit" } : {}),
      });
      expect(created.statusCode).toBe(201);
      const id = created.json<{ id: string }>().id;
      ids[code] = id;
      for (const purpose of withoutImport.includes(code)
        ? ["core"]
        : ["core", "records_import"]) {
        const granted = await call(caller, "POST", "/v1/enrolments/consents", {
          enrolmentId: id,
          purpose,
          ...SHOWN,
        });
        expect(granted.statusCode).toBe(201);
      }
    }
    return ids;
  };

  const rows = (
    table: "record_items" | "record_routes" | "record_sources",
    who: Caller,
  ) => fake.table(table).filter((row) => row.user_id === who.id);

  const importedSource = (who: Caller) =>
    fake.records.seedSource({
      user_id: who.id,
      kind: "smart",
      fhir_base_url: "https://fhir.synthetic.example/r4",
      display_name: "Synthetic Clinic",
      status: "connected",
    });

  const importedItem = (
    who: Caller,
    sourceId: string,
    overrides: Record<string, unknown> = {},
  ) =>
    fake.records.seedItem({
      user_id: who.id,
      source_id: sourceId,
      resource_type: "Observation",
      category: "blood_pressure",
      code_system: LOINC,
      code: "8480-6",
      display: "Systolic blood pressure",
      value_num: 128,
      unit_ucum: "mm[Hg]",
      effective_at: AT,
      status: "pending_review",
      dedupe_key: `${LOINC}|8480-6|${DAY}|${randomUUID()}`,
      ...overrides,
    });

  // ---- authentication ----------------------------------------------------------

  it.each([
    ["POST", "/v1/records/manual", { type: "glucose", value: 100, date: DAY }],
    ["POST", "/v1/records/fhir/accept", { itemIds: [randomUUID()] }],
    [
      "POST",
      "/v1/records/fhir/conflicts",
      { resolutions: [{ itemId: randomUUID(), choice: "discard" }] },
    ],
    ["GET", "/v1/records/fhir/sources", undefined],
    ["GET", "/v1/records/fhir/items", undefined],
    ["GET", "/v1/records/fhir/summary", undefined],
  ])("%s %s requires a token", async (method, url, payload) => {
    const since = fake.requests.length;
    expect((await call(null, method as Method, url, payload)).statusCode).toBe(
      401,
    );
    expect(fake.requests.length).toBe(since);
  });

  // ---- manual entry -----------------------------------------------------------------

  describe("POST /v1/records/manual", () => {
    it("stores an A1C as entered by the member and shares it with Steady only", async () => {
      const a = newCaller();
      await enrol(a, ["st", "hw", "sf"]);
      const response = await call(a, "POST", "/v1/records/manual", {
        type: "lab_result",
        test: "a1c",
        value: 7.4,
        date: DAY,
      });
      expect(response.statusCode).toBe(201);
      expect(openApiErrors("ManualEntryResult", response.json())).toEqual([]);
      expect(response.json()).toMatchObject({
        items: [
          {
            enteredByYou: true,
            category: "a1c",
            code: "4548-4",
            value: 7.4,
            unit: "%",
            status: "accepted",
            effectiveAt: AT,
          },
        ],
        routedTo: [{ programmeCode: "st", items: 1 }],
      });
      expect(rows("record_routes", a).map((r) => r.programme_code)).toEqual([
        "st",
      ]);
      expect(rows("record_sources", a)).toMatchObject([
        { kind: "manual", display_name: "Entered by you" },
      ]);
    });

    it("converts mmol/L glucose to mg/dL before the range check", async () => {
      const a = newCaller();
      await enrol(a, ["st"]);
      const response = await call(a, "POST", "/v1/records/manual", {
        type: "glucose",
        value: 5.5,
        unit: "mmol/L",
        date: DAY,
      });
      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({
        items: [{ value: 99.088, unit: "mg/dL", category: "glucose" }],
      });
    });

    it("stores blood pressure as two readings for Heartwise", async () => {
      const a = newCaller();
      await enrol(a, ["hw"]);
      const response = await call(a, "POST", "/v1/records/manual", {
        type: "blood_pressure",
        systolic: 135,
        diastolic: 85,
        date: DAY,
      });
      expect(response.statusCode).toBe(201);
      expect(
        response
          .json<{ items: { code: string; value: number }[] }>()
          .items.map((i) => [i.code, i.value]),
      ).toEqual([
        ["8480-6", 135],
        ["8462-4", 85],
      ]);
      expect(response.json()).toMatchObject({
        routedTo: [{ programmeCode: "hw", items: 2 }],
      });
    });

    it("a vaccine goes to Checkup; a medication is kept for reference only", async () => {
      const a = newCaller();
      await enrol(a, ["ck", "hw"]);
      const vaccine = await call(a, "POST", "/v1/records/manual", {
        type: "vaccine",
        name: ` ${NAME_CANARY} `,
        date: DAY,
      });
      expect(vaccine.statusCode).toBe(201);
      expect(vaccine.json()).toMatchObject({
        items: [
          {
            resourceType: "Immunization",
            category: "immunizations",
            display: NAME_CANARY,
          },
        ],
        routedTo: [{ programmeCode: "ck", items: 1 }],
      });
      const medication = await call(a, "POST", "/v1/records/manual", {
        type: "medication",
        name: "Synthetic patch",
        date: DAY,
      });
      expect(medication.statusCode).toBe(201);
      expect(medication.json()).toMatchObject({
        items: [{ resourceType: "MedicationRequest", category: null }],
        routedTo: [],
      });
    });

    it("without records_import consent it is stored but reaches no programme", async () => {
      const a = newCaller();
      await enrol(a, ["st"], { withoutImport: ["st"] });
      const response = await call(a, "POST", "/v1/records/manual", {
        type: "lab_result",
        test: "a1c",
        value: 6.9,
        date: DAY,
      });
      expect(response.statusCode).toBe(201);
      expect(response.json()).toMatchObject({ routedTo: [] });
      expect(rows("record_routes", a)).toEqual([]);
      expect(rows("record_items", a)).toHaveLength(1);
    });

    it("Ease and ScrollFree never receive records", async () => {
      const a = newCaller();
      await enrol(a, ["ea", "sf"]);
      for (const body of [
        { type: "blood_pressure", systolic: 120, diastolic: 80, date: DAY },
        { type: "glucose", value: 100, date: DAY },
        { type: "vaccine", name: "Synthetic flu", date: DAY },
      ]) {
        const response = await call(a, "POST", "/v1/records/manual", body);
        expect(response.statusCode).toBe(201);
        expect(response.json()).toMatchObject({ routedTo: [] });
      }
      expect(rows("record_routes", a)).toEqual([]);
    });

    it.each([
      [{ type: "lab_result", test: "a1c", value: 74, date: DAY }],
      [{ type: "lab_result", test: "ldl", value: 2, date: DAY }],
      [{ type: "lab_result", test: "egfr", value: 151, date: DAY }],
      [{ type: "glucose", value: 40, unit: "mmol/L", date: DAY }],
      [{ type: "blood_pressure", systolic: 1290, diastolic: 80, date: DAY }],
      [{ type: "blood_pressure", systolic: 80, diastolic: 90, date: DAY }],
    ])(
      "outside the plausible range → 422 value_out_of_range, nothing stored (%#)",
      async (body) => {
        const a = newCaller();
        await enrol(a, ["st", "hw", "re"]);
        expectCoded(
          await call(a, "POST", "/v1/records/manual", body),
          422,
          "value_out_of_range",
        );
        expect(rows("record_items", a)).toEqual([]);
      },
    );

    it("the same value twice, or one already imported, → 409 record_duplicate", async () => {
      const a = newCaller();
      await enrol(a, ["st"]);
      const body = { type: "lab_result", test: "a1c", value: 7.4, date: DAY };
      expect(
        (await call(a, "POST", "/v1/records/manual", body)).statusCode,
      ).toBe(201);
      expectCoded(
        await call(a, "POST", "/v1/records/manual", body),
        409,
        "record_duplicate",
      );
      const source = importedSource(a);
      importedItem(a, source.id as string, {
        category: "a1c",
        code: "4548-4",
        value_num: 7.6,
        status: "accepted",
        dedupe_key: `${LOINC}|4548-4|2026-09-30|7.6`,
      });
      expectCoded(
        await call(a, "POST", "/v1/records/manual", {
          type: "lab_result",
          test: "a1c",
          value: 7.6,
          date: "2026-09-30",
        }),
        409,
        "record_duplicate",
      );
      expect(rows("record_items", a)).toHaveLength(2);
    });

    it.each([
      [{ type: "weight", value: 80, date: DAY }],
      [{ type: "glucose", date: DAY }],
      [{ type: "glucose", value: 100, unit: "g/L", date: DAY }],
      [{ type: "glucose", value: 100, test: "a1c", date: DAY }],
      [{ type: "lab_result", value: 7, date: DAY }],
      [{ type: "lab_result", test: "hdl", value: 50, date: DAY }],
      [{ type: "blood_pressure", systolic: 120.5, diastolic: 80, date: DAY }],
      [{ type: "blood_pressure", systolic: 120, date: DAY }],
      [{ type: "vaccine", date: DAY }],
      [{ type: "vaccine", name: "   ", date: DAY }],
      [{ type: "vaccine", name: "Flu", value: 1, date: DAY }],
      [{ type: "glucose", value: 100, date: "2026-02-30" }],
      [{ type: "glucose", value: 100, date: "2099-01-01" }],
      [{ type: "glucose", value: 100, date: "1899-12-31" }],
      [{ type: "glucose", value: 100, date: "10/01/2026" }],
      [{ type: "glucose", value: 100, date: DAY, enteredBy: "clinic" }],
      [{ type: "glucose", value: 100.00001, date: DAY }],
    ])("refuses %p with 400 invalid_request", async (body) => {
      const a = newCaller();
      await enrol(a, ["st"]);
      expectCoded(
        await call(a, "POST", "/v1/records/manual", body),
        400,
        "invalid_request",
      );
      expect(rows("record_items", a)).toEqual([]);
    });

    it("refuses once account deletion started", async () => {
      const a = newCaller();
      await enrol(a, ["st"]);
      fake.startAccountDeletion(a.id);
      expectCoded(
        await call(a, "POST", "/v1/records/manual", {
          type: "glucose",
          value: 100,
          date: DAY,
        }),
        409,
        "account_deletion_in_progress",
      );
      expect(rows("record_items", a)).toEqual([]);
    });

    it("an unknown database error fails closed as 502, logging only the code", async () => {
      const a = newCaller();
      await enrol(a, ["st"]);
      fake.failNext("POST", "record_items", {
        status: 500,
        code: "XX000",
        message: `internal ${DB_CANARY}`,
        hint: null,
      });
      const response = await call(a, "POST", "/v1/records/manual", {
        type: "glucose",
        value: 100,
        date: DAY,
      });
      expect(response.statusCode).toBe(502);
      expect(
        logged.some(
          (line) =>
            line.includes("route=/v1/records/manual") &&
            line.includes("code=XX000"),
        ),
      ).toBe(true);
    });
  });

  // ---- accept ------------------------------------------------------------------------

  describe("POST /v1/records/fhir/accept", () => {
    it("accepts items waiting for review and routes them by category and consent", async () => {
      const a = newCaller();
      await enrol(a, ["hw", "st"], { withoutImport: ["st"] });
      const source = importedSource(a);
      const bp = importedItem(a, source.id as string);
      const a1c = importedItem(a, source.id as string, {
        category: "a1c",
        code: "4548-4",
        value_num: 7.6,
        unit_ucum: "%",
      });
      const response = await call(a, "POST", "/v1/records/fhir/accept", {
        itemIds: [bp.id, (a1c.id as string).toUpperCase()],
      });
      expect(response.statusCode).toBe(200);
      expect(openApiErrors("AcceptResult", response.json())).toEqual([]);
      expect(response.json()).toEqual({
        accepted: 2,
        routedTo: [{ programmeCode: "hw", items: 1 }],
      });
      expect(
        rows("record_items", a).every((r) => r.status === "accepted"),
      ).toBe(true);
      expect(rows("record_routes", a)).toMatchObject([
        { record_item_id: bp.id, programme_code: "hw" },
      ]);
    });

    it("another member's or an unknown item → 404 item_not_found, nothing changed", async () => {
      const a = newCaller();
      const b = newCaller();
      const theirs = importedItem(b, importedSource(b).id as string);
      const mine = importedItem(a, importedSource(a).id as string);
      for (const ids of [[theirs.id], [mine.id, randomUUID()]]) {
        expectCoded(
          await call(a, "POST", "/v1/records/fhir/accept", { itemIds: ids }),
          404,
          "item_not_found",
        );
      }
      expect(
        fake
          .table("record_items")
          .filter((r) => r.id === theirs.id || r.id === mine.id)
          .map((r) => r.status),
      ).toEqual(["pending_review", "pending_review"]);
    });

    it("an item not waiting for review → 409 item_not_reviewable", async () => {
      const a = newCaller();
      const source = importedSource(a);
      for (const status of ["accepted", "rejected", "conflict"]) {
        const item = importedItem(a, source.id as string, { status });
        expectCoded(
          await call(a, "POST", "/v1/records/fhir/accept", {
            itemIds: [item.id],
          }),
          409,
          "item_not_reviewable",
        );
      }
    });

    it("refuses once account deletion started", async () => {
      const a = newCaller();
      const item = importedItem(a, importedSource(a).id as string);
      fake.startAccountDeletion(a.id);
      expectCoded(
        await call(a, "POST", "/v1/records/fhir/accept", {
          itemIds: [item.id],
        }),
        409,
        "account_deletion_in_progress",
      );
      expect(rows("record_items", a)[0]?.status).toBe("pending_review");
    });

    it.each([
      [{}],
      [{ itemIds: [] }],
      [{ itemIds: ["not-a-uuid"] }],
      [{ itemIds: Array.from({ length: 201 }, () => randomUUID()) }],
      [{ itemIds: [randomUUID()], programmes: ["hw"] }],
    ])("refuses the body %# with invalid_request", async (body) => {
      expectCoded(
        await call(newCaller(), "POST", "/v1/records/fhir/accept", body),
        400,
        "invalid_request",
      );
    });
  });

  // ---- conflicts ---------------------------------------------------------------------

  describe("POST /v1/records/fhir/conflicts", () => {
    /** An imported A1C in conflict with the member's own entry for the day. */
    const conflict = async () => {
      const a = newCaller();
      await enrol(a, ["st"]);
      const entered = await call(a, "POST", "/v1/records/manual", {
        type: "lab_result",
        test: "a1c",
        value: 7.4,
        date: DAY,
      });
      expect(entered.statusCode).toBe(201);
      const mine = entered.json<{ items: { id: string }[] }>().items[0]?.id;
      const imported = importedItem(a, importedSource(a).id as string, {
        category: "a1c",
        code: "4548-4",
        display: "Hemoglobin A1c",
        value_num: 7.6,
        unit_ucum: "%",
        status: "conflict",
      });
      return { a, mine: mine as string, imported: imported.id as string };
    };
    const statusOf = (id: string) =>
      fake.table("record_items").find((r) => r.id === id)?.status;

    it("use_imported accepts the clinic's value and rejects the member's entry", async () => {
      const { a, mine, imported } = await conflict();
      const response = await call(a, "POST", "/v1/records/fhir/conflicts", {
        resolutions: [{ itemId: imported, choice: "use_imported" }],
      });
      expect(response.statusCode).toBe(200);
      expect(openApiErrors("ConflictsResult", response.json())).toEqual([]);
      expect(response.json()).toMatchObject({
        accepted: [imported],
        rejected: [],
        created: [],
        routedTo: [{ programmeCode: "st", items: 1 }],
      });
      expect(statusOf(imported)).toBe("accepted");
      expect(statusOf(mine)).toBe("rejected");
    });

    it("keep_both accepts it and keeps the entry; keep_mine rejects it", async () => {
      const first = await conflict();
      expect(
        (
          await call(first.a, "POST", "/v1/records/fhir/conflicts", {
            resolutions: [{ itemId: first.imported, choice: "keep_both" }],
          })
        ).statusCode,
      ).toBe(200);
      expect(statusOf(first.imported)).toBe("accepted");
      expect(statusOf(first.mine)).toBe("accepted");
      const second = await conflict();
      expect(
        (
          await call(second.a, "POST", "/v1/records/fhir/conflicts", {
            resolutions: [{ itemId: second.imported, choice: "keep_mine" }],
          })
        ).statusCode,
      ).toBe(200);
      expect(statusOf(second.imported)).toBe("rejected");
      expect(statusOf(second.mine)).toBe("accepted");
    });

    it("correct stores the corrected value as the member's own and rejects the import", async () => {
      const a = newCaller();
      await enrol(a, ["hw"]);
      const typo = importedItem(a, importedSource(a).id as string, {
        value_num: 1290,
        status: "conflict",
      });
      const response = await call(a, "POST", "/v1/records/fhir/conflicts", {
        resolutions: [
          { itemId: typo.id, choice: "correct", correctedValue: 129 },
        ],
      });
      expect(response.statusCode).toBe(200);
      const { created } = response.json<{ created: string[] }>();
      expect(created).toHaveLength(1);
      expect(statusOf(typo.id as string)).toBe("rejected");
      const stored = fake
        .table("record_items")
        .find((r) => r.id === created[0]);
      expect(stored).toMatchObject({
        value_num: 129,
        code: "8480-6",
        status: "accepted",
      });
      expect(
        fake.table("record_sources").find((s) => s.id === stored?.source_id)
          ?.kind,
      ).toBe("manual");
      expect(response.json()).toMatchObject({
        routedTo: [{ programmeCode: "hw", items: 1 }],
      });
    });

    it("a correction outside the range → 422, nothing changed", async () => {
      const a = newCaller();
      const typo = importedItem(a, importedSource(a).id as string, {
        value_num: 1290,
        status: "conflict",
      });
      expectCoded(
        await call(a, "POST", "/v1/records/fhir/conflicts", {
          resolutions: [
            { itemId: typo.id, choice: "correct", correctedValue: 1290 },
          ],
        }),
        422,
        "value_out_of_range",
      );
      expect(statusOf(typo.id as string)).toBe("conflict");
    });

    it("an item not in conflict → 409; another member's → 404", async () => {
      const { a } = await conflict();
      const pending = importedItem(a, importedSource(a).id as string);
      expectCoded(
        await call(a, "POST", "/v1/records/fhir/conflicts", {
          resolutions: [{ itemId: pending.id, choice: "discard" }],
        }),
        409,
        "item_not_reviewable",
      );
      const b = newCaller();
      const theirs = importedItem(b, importedSource(b).id as string, {
        status: "conflict",
      });
      expectCoded(
        await call(a, "POST", "/v1/records/fhir/conflicts", {
          resolutions: [{ itemId: theirs.id, choice: "discard" }],
        }),
        404,
        "item_not_found",
      );
      expect(statusOf(theirs.id as string)).toBe("conflict");
    });

    it.each([
      [{ resolutions: [] }],
      [{ resolutions: [{ itemId: randomUUID(), choice: "ask_care_team" }] }],
      [{ resolutions: [{ itemId: randomUUID(), choice: "correct" }] }],
      [
        {
          resolutions: [
            { itemId: randomUUID(), choice: "discard", correctedValue: 1 },
          ],
        },
      ],
      [
        {
          resolutions: [
            {
              itemId: "11111111-1111-4111-8111-111111111111",
              choice: "discard",
            },
            {
              itemId: "11111111-1111-4111-8111-111111111111",
              choice: "keep_mine",
            },
          ],
        },
      ],
      [
        {
          resolutions: [{ itemId: randomUUID(), choice: "discard", note: "x" }],
        },
      ],
    ])("refuses the body %# with invalid_request", async (body) => {
      expectCoded(
        await call(newCaller(), "POST", "/v1/records/fhir/conflicts", body),
        400,
        "invalid_request",
      );
    });
  });

  // ---- reads ---------------------------------------------------------------------------

  describe("reads", () => {
    it("sources, items and the summary show only the caller's records", async () => {
      const a = newCaller();
      const b = newCaller();
      await enrol(a, ["hw"]);
      const source = importedSource(a);
      importedItem(a, source.id as string);
      importedItem(a, source.id as string, { status: "conflict" });
      await call(a, "POST", "/v1/records/manual", {
        type: "blood_pressure",
        systolic: 130,
        diastolic: 80,
        date: DAY,
      });
      importedItem(b, importedSource(b).id as string);

      const sources = await call(a, "GET", "/v1/records/fhir/sources");
      expect(sources.statusCode).toBe(200);
      expect(openApiErrors("RecordSourceList", sources.json())).toEqual([]);
      expect(
        sources
          .json<{ sources: { kind: string }[] }>()
          .sources.map((s) => s.kind),
      ).toEqual(["smart", "manual"]);

      const review = await call(a, "GET", "/v1/records/fhir/items");
      expect(review.statusCode).toBe(200);
      expect(openApiErrors("RecordItemList", review.json())).toEqual([]);
      expect(
        review
          .json<{ items: { status: string }[] }>()
          .items.map((i) => i.status)
          .sort(),
      ).toEqual(["conflict", "pending_review"]);

      const accepted = await call(
        a,
        "GET",
        "/v1/records/fhir/items?status=accepted",
      );
      expect(
        accepted.json<{ items: { enteredByYou: boolean }[] }>().items,
      ).toMatchObject([{ enteredByYou: true }, { enteredByYou: true }]);

      const summary = await call(a, "GET", "/v1/records/fhir/summary");
      expect(summary.statusCode).toBe(200);
      expect(openApiErrors("HealthRecordsSummary", summary.json())).toEqual([]);
      expect(summary.json()).toEqual({
        sources: 2,
        needsReview: 2,
        categories: [
          { category: "blood_pressure", items: 2, programmes: ["hw"] },
        ],
      });
      for (const response of [sources, review, accepted, summary]) {
        expect(response.body).not.toContain(b.id);
      }
    });

    it.each([
      "status=archived",
      "status=accepted&status=rejected",
      "programme=hw",
    ])("GET items?%s → 400 invalid_request", async (query) => {
      expectCoded(
        await call(newCaller(), "GET", `/v1/records/fhir/items?${query}`),
        400,
        "invalid_request",
      );
    });

    it("a member with no records gets empty answers", async () => {
      const a = newCaller();
      expect((await call(a, "GET", "/v1/records/fhir/summary")).json()).toEqual(
        {
          sources: 0,
          needsReview: 0,
          categories: [],
        },
      );
      expect((await call(a, "GET", "/v1/records/fhir/sources")).json()).toEqual(
        {
          sources: [],
        },
      );
    });
  });

  it("Delete now removes the programme's routes; the items stay with the account", async () => {
    const a = newCaller();
    const { hw } = await enrol(a, ["hw"]);
    await call(a, "POST", "/v1/records/manual", {
      type: "blood_pressure",
      systolic: 130,
      diastolic: 80,
      date: DAY,
    });
    expect(rows("record_routes", a)).toHaveLength(2);
    expect(
      (
        await call(a, "DELETE", `/v1/enrolments/${hw}`, {
          confirmation: "DELETE",
        })
      ).statusCode,
    ).toBe(204);
    expect(rows("record_routes", a)).toEqual([]);
    expect(rows("record_items", a)).toHaveLength(2);
  });

  // ---- contract ------------------------------------------------------------------------

  describe("contract (docs/contracts/openapi.yaml)", () => {
    const document = openApiDocument();
    it.each([
      ["/v1/records/manual", "post", true],
      ["/v1/records/fhir/accept", "post", true],
      ["/v1/records/fhir/conflicts", "post", true],
      ["/v1/records/fhir/sources", "get", true],
      ["/v1/records/fhir/items", "get", true],
      ["/v1/records/fhir/summary", "get", true],
    ])("documents %s %s (app use: %s)", (path, method, appUse) => {
      const operation = document.paths[path]?.[method] as
        Record<string, unknown> | undefined;
      expect(operation).toBeDefined();
      expect(operation?.["x-app-use"] === true).toBe(appUse);
      expect(operation?.responses).toHaveProperty("401");
    });

    it("the error enum is healthRecordErrorCodes", () => {
      const schema = openApiSchema("HealthRecordRequestRejected") as {
        properties: { code: { enum: unknown } };
      };
      expect(schema.properties.code.enum).toEqual([...healthRecordErrorCodes]);
    });

    it("the version is bumped for these routes", () => {
      expect(document.info.version).toBe("1.11.0");
    });
  });

  it("no log line holds a member id, a value name or a token", () => {
    for (const line of logged) {
      expect(line).not.toContain(TOKEN_CANARY);
      expect(line).not.toContain(DB_CANARY);
      expect(line).not.toContain(NAME_CANARY);
      for (const secret of secrets) expect(line).not.toContain(secret);
    }
  });
});
