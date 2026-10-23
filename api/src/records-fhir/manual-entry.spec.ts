import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  BP_RANGES,
  LAB_CODES,
  MANUAL_RANGES,
  dedupeKey,
  effectiveFor,
  normaliseManual,
  plausibleRange,
} from "./manual-entry";
import { parseItemsQuery } from "./records-fhir.service";

const NOW = Date.parse("2026-10-22T10:00:00.000Z");
const SPEC = join(__dirname, "..", "..", "..", "tether_ui", "spec");
const rules = JSON.parse(
  readFileSync(join(SPEC, "rules.json"), "utf8"),
) as Record<string, { inputs: string[]; params: Record<string, unknown> }>;

describe("parity with tether_ui/spec/rules.json", () => {
  it("the manual ranges are rec.manual's", () => {
    expect(rules["rec.manual"]?.params.ranges).toEqual(MANUAL_RANGES);
    expect(rules["rec.manual"]?.inputs).toEqual([
      "records_manual.test",
      "records_manual.value",
    ]);
  });

  it("blood pressure uses hw.bp's ranges", () => {
    const params = rules["hw.bp"]?.params as Record<string, number>;
    expect(BP_RANGES).toEqual({
      systolic: [params.sys_min, params.sys_max],
      diastolic: [params.dia_min, params.dia_max],
    });
  });

  it("every rec.manual test has a code", () => {
    const keys = Object.values(LAB_CODES)
      .map((spec) => spec.ruleKey)
      .sort();
    expect(keys).toEqual(Object.keys(MANUAL_RANGES).sort());
  });
});

describe("normaliseManual", () => {
  it("stores an A1C at noon UTC of the entered day with its LOINC code", () => {
    expect(
      normaliseManual(
        { type: "lab_result", test: "a1c", value: 7.4, date: "2026-10-01" },
        NOW,
      ),
    ).toEqual({
      ok: true,
      items: [
        {
          resourceType: "Observation",
          category: "a1c",
          codeSystem: "http://loinc.org",
          code: "4548-4",
          display: "Hemoglobin A1c",
          valueNum: 7.4,
          valueText: null,
          unit: "%",
          effectiveAt: "2026-10-01T12:00:00.000Z",
          dedupeKey: "http://loinc.org|4548-4|2026-10-01|7.4",
        },
      ],
    });
  });

  it.each([
    [{ type: "glucose", value: 5.5, unit: "mmol/L" }, 99.088, "mg/dL"],
    [
      { type: "lab_result", test: "ldl", value: 3.5, unit: "mmol/L" },
      135.345,
      "mg/dL",
    ],
    [
      { type: "lab_result", test: "a1c", value: 53, unit: "mmol/mol" },
      7.0004,
      "%",
    ],
    [
      { type: "lab_result", test: "egfr", value: 58, unit: "mL/min/1.73m2" },
      58,
      "mL/min/{1.73_m2}",
    ],
  ] as const)("converts %p to the stored unit", (input, value, unit) => {
    const result = normaliseManual({ ...input, date: "2026-10-01" }, NOW);
    expect(result).toMatchObject({
      ok: true,
      items: [{ valueNum: value, unit }],
    });
  });

  it.each([
    [{ type: "lab_result", test: "a1c", value: 2.9 }],
    [{ type: "lab_result", test: "a1c", value: 20.1 }],
    [{ type: "lab_result", test: "ldl", value: 401 }],
    [{ type: "lab_result", test: "egfr", value: 0.5 }],
    [{ type: "glucose", value: 19 }],
    [{ type: "glucose", value: 34, unit: "mmol/L" }],
    [{ type: "blood_pressure", systolic: 251, diastolic: 80 }],
    [{ type: "blood_pressure", systolic: 120, diastolic: 39 }],
    [{ type: "blood_pressure", systolic: 90, diastolic: 90 }],
  ] as const)("%p is out of range", (input) => {
    expect(normaliseManual({ ...input, date: "2026-10-01" }, NOW)).toEqual({
      ok: false,
      reason: "out_of_range",
    });
  });

  it.each([
    [{ type: "lab_result", test: "a1c", value: 3 }],
    [{ type: "lab_result", test: "a1c", value: 20 }],
    [{ type: "blood_pressure", systolic: 250, diastolic: 40 }],
    [{ type: "blood_pressure", systolic: 70, diastolic: 40 }],
  ] as const)("the bounds themselves are accepted: %p", (input) => {
    expect(normaliseManual({ ...input, date: "2026-10-01" }, NOW).ok).toBe(
      true,
    );
  });

  it.each([
    [{ type: "glucose", date: "2026-10-01" }],
    [{ type: "glucose", value: 100, unit: "mg/L", date: "2026-10-01" }],
    [{ type: "glucose", value: 100, test: "a1c", date: "2026-10-01" }],
    [{ type: "lab_result", value: 7, date: "2026-10-01" }],
    [{ type: "blood_pressure", systolic: 120, date: "2026-10-01" }],
    [
      {
        type: "blood_pressure",
        systolic: 120,
        diastolic: 80,
        value: 1,
        date: "2026-10-01",
      },
    ],
    [{ type: "vaccine", name: " ", date: "2026-10-01" }],
    [{ type: "vaccine", name: "x".repeat(201), date: "2026-10-01" }],
    [{ type: "condition", name: "Synthetic", unit: "%", date: "2026-10-01" }],
    [{ type: "glucose", value: 100, date: "2026-02-29" }],
    [{ type: "glucose", value: 100, date: "2026-10-24" }],
    [{ type: "glucose", value: 100, date: "1899-12-31" }],
  ] as const)("%p is invalid", (input) => {
    expect(normaliseManual(input, NOW)).toEqual({
      ok: false,
      reason: "invalid",
    });
  });

  it("ignores fields that are present but undefined (DTO instances)", () => {
    expect(
      normaliseManual(
        {
          type: "glucose",
          value: 100,
          date: "2026-10-01",
          name: undefined,
          systolic: undefined,
        },
        NOW,
      ).ok,
    ).toBe(true);
  });

  it("blood pressure gives two readings; free-text types carry the name", () => {
    const bp = normaliseManual(
      {
        type: "blood_pressure",
        systolic: 129,
        diastolic: 80,
        date: "2026-08-04",
      },
      NOW,
    );
    expect(bp).toMatchObject({
      ok: true,
      items: [
        {
          code: "8480-6",
          valueNum: 129,
          unit: "mm[Hg]",
          category: "blood_pressure",
        },
        {
          code: "8462-4",
          valueNum: 80,
          unit: "mm[Hg]",
          category: "blood_pressure",
        },
      ],
    });
    expect(
      normaliseManual(
        {
          type: "condition",
          name: " Synthetic condition ",
          date: "2026-08-04",
        },
        NOW,
      ),
    ).toMatchObject({
      ok: true,
      items: [
        {
          resourceType: "Condition",
          category: null,
          display: "Synthetic condition",
          dedupeKey:
            "urn:tether:manual|condition|2026-08-04|synthetic condition",
        },
      ],
    });
  });
});

describe("helpers", () => {
  it("dedupeKey rounds to four decimals and bounds the length", () => {
    expect(dedupeKey("s", "c", "2026-10-01", 7.123456)).toBe(
      "s|c|2026-10-01|7.1235",
    );
    expect(dedupeKey("s".repeat(400), "c", "d", 1)).toHaveLength(300);
  });

  it("effectiveFor keeps noon UTC within a day of now, as the database checks", () => {
    expect(effectiveFor("2026-10-22", NOW)).toBe("2026-10-22T12:00:00.000Z");
    // Tomorrow's noon is more than a day after 10:00 today; after noon it is not.
    expect(effectiveFor("2026-10-23", NOW)).toBeNull();
    expect(
      effectiveFor("2026-10-23", Date.parse("2026-10-22T13:00:00.000Z")),
    ).toBe("2026-10-23T12:00:00.000Z");
    expect(effectiveFor("2026-10-24", NOW)).toBeNull();
    expect(effectiveFor("2026-13-01", NOW)).toBeNull();
  });

  it("plausibleRange knows the measured codes only", () => {
    expect(plausibleRange("http://loinc.org", "8480-6")).toEqual([70, 250]);
    expect(plausibleRange("http://loinc.org", "4548-4")).toEqual([3, 20]);
    expect(plausibleRange("http://loinc.org", "72166-2")).toBeNull();
    expect(plausibleRange("urn:tether:manual", "vaccine")).toBeNull();
  });

  it("parseItemsQuery accepts one status or none", () => {
    expect(parseItemsQuery({})).toEqual(["pending_review", "conflict"]);
    expect(parseItemsQuery({ status: "accepted" })).toEqual(["accepted"]);
    for (const query of [
      { status: "archived" },
      { status: ["a", "b"] },
      { other: "1" },
      null,
    ]) {
      expect(() => parseItemsQuery(query)).toThrow();
    }
  });
});
