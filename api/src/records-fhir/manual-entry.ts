import { rangesFor } from "../programme-data/ranges";

/**
 * Manual health values: what the member typed on records_manual, checked
 * and normalised the way imported values are (code, UCUM unit, plausibility,
 * duplicate key) before they are stored as accepted items.
 *
 * The code list is a curated subset (LOINC for the measured values). It is
 * an assumption until clinical and informatics sign-off; the plausibility
 * ranges are tether_ui/spec/rules.json `rec.manual` (lab values) and `hw.bp`
 * (blood pressure), checked by records-fhir-spec-parity.spec.ts. They are
 * plausibility ranges, not clinical targets.
 */

export const manualTypes = [
  "blood_pressure",
  "glucose",
  "lab_result",
  "vaccine",
  "medication",
  "condition",
] as const;
export type ManualType = (typeof manualTypes)[number];

export const labTests = ["a1c", "ldl", "egfr", "glucose"] as const;
export type LabTest = (typeof labTests)[number];

export const LOINC = "http://loinc.org";
/** Free-text entries (vaccine, medication, condition) carry no standard code. */
export const MANUAL_CODE_SYSTEM = "urn:tether:manual";

export interface MeasuredCode {
  /** The rules.json `rec.manual` range key. */
  ruleKey: "A1C" | "LDL" | "eGFR" | "Glucose";
  code: string;
  display: string;
  category: "a1c" | "lipids" | "egfr" | "glucose";
  /** The canonical UCUM unit the value is stored in. */
  unit: string;
  /** Accepted input units and the factor to the canonical unit. */
  conversions: Readonly<Record<string, (value: number) => number>>;
}

/** Plausibility ranges from rules.json `rec.manual` (canonical units). */
export const MANUAL_RANGES: Readonly<
  Record<MeasuredCode["ruleKey"], readonly [number, number]>
> = {
  A1C: [3, 20],
  LDL: [10, 400],
  eGFR: [1, 150],
  Glucose: [20, 600],
};

const identity = (value: number) => value;

export const LAB_CODES: Readonly<Record<LabTest, MeasuredCode>> = {
  a1c: {
    ruleKey: "A1C",
    code: "4548-4",
    display: "Hemoglobin A1c",
    category: "a1c",
    unit: "%",
    conversions: {
      "%": identity,
      // IFCC mmol/mol to NGSP %: 0.09148 × IFCC + 2.152.
      "mmol/mol": (value) => 0.09148 * value + 2.152,
    },
  },
  ldl: {
    ruleKey: "LDL",
    code: "13457-7",
    display: "LDL cholesterol",
    category: "lipids",
    unit: "mg/dL",
    conversions: { "mg/dL": identity, "mmol/L": (value) => value * 38.67 },
  },
  egfr: {
    ruleKey: "eGFR",
    code: "33914-3",
    display: "eGFR",
    category: "egfr",
    unit: "mL/min/{1.73_m2}",
    conversions: {
      "mL/min/{1.73_m2}": identity,
      "mL/min/1.73m2": identity,
    },
  },
  glucose: {
    ruleKey: "Glucose",
    code: "2345-7",
    display: "Glucose",
    category: "glucose",
    unit: "mg/dL",
    conversions: { "mg/dL": identity, "mmol/L": (value) => value * 18.016 },
  },
};

const bpRange = (
  field: "systolic" | "diastolic",
): readonly [number, number] => {
  const range = rangesFor("hw/readings").find((r) => r.field === field);
  if (!range) throw new Error(`hw.bp has no ${field} range`);
  return [range.min, range.max];
};
export const BP_RANGES = {
  systolic: bpRange("systolic"),
  diastolic: bpRange("diastolic"),
} as const;

/** One item to store, before the database adds ids and times. */
export interface ManualItem {
  resourceType:
    "Observation" | "Immunization" | "MedicationRequest" | "Condition";
  category: string | null;
  codeSystem: string;
  code: string;
  display: string;
  valueNum: number | null;
  valueText: string | null;
  unit: string | null;
  /** UTC noon of the entered date, so the day never shifts by time zone. */
  effectiveAt: string;
  dedupeKey: string;
}

export interface ManualInput {
  type: ManualType;
  test?: LabTest;
  value?: number;
  unit?: string;
  systolic?: number;
  diastolic?: number;
  name?: string;
  /** YYYY-MM-DD. */
  date: string;
}

export type ManualResult =
  | { ok: true; items: ManualItem[] }
  | { ok: false; reason: "invalid" | "out_of_range" };

const DATE = /^(\d{4})-(\d{2})-(\d{2})$/;
const DAY_MS = 24 * 60 * 60 * 1000;

/** Four decimal places, as record_items.value_num stores them. */
const round4 = (value: number) => Math.round(value * 10_000) / 10_000;

/** The duplicate key: code, date and value (or text), as the import uses. */
export function dedupeKey(
  codeSystem: string,
  code: string,
  date: string,
  value: number | string,
): string {
  const shown =
    typeof value === "number" ? String(round4(value)) : value.toLowerCase();
  return `${codeSystem}|${code}|${date}|${shown}`.slice(0, 300);
}

/** The entered date as UTC noon, or null when it is not a real past date. */
export function effectiveFor(date: string, now = Date.now()): string | null {
  const match = DATE.exec(date);
  if (!match) return null;
  const at = Date.UTC(
    Number(match[1]),
    Number(match[2]) - 1,
    Number(match[3]),
    12,
  );
  const parsed = new Date(at);
  if (
    parsed.getUTCFullYear() !== Number(match[1]) ||
    parsed.getUTCMonth() !== Number(match[2]) - 1 ||
    parsed.getUTCDate() !== Number(match[3]) ||
    Number(match[1]) < 1900 ||
    at > now + DAY_MS
  ) {
    return null;
  }
  return parsed.toISOString();
}

const within = (value: number, [min, max]: readonly [number, number]) =>
  Number.isFinite(value) && value >= min && value <= max;

/**
 * Checks and normalises one manual entry. Only the fields of its type may
 * be present; anything missing, extra or malformed is `invalid`; a value
 * outside its plausibility range (after unit conversion) is `out_of_range`.
 */
export function normaliseManual(
  input: ManualInput,
  now = Date.now(),
): ManualResult {
  const effectiveAt = effectiveFor(input.date, now);
  if (effectiveAt === null) return { ok: false, reason: "invalid" };
  // Only the fields of the entry's type may carry a value.
  const present = (keys: (keyof ManualInput)[]) =>
    (Object.keys(input) as (keyof ManualInput)[]).every(
      (key) =>
        key === "type" ||
        key === "date" ||
        input[key] === undefined ||
        keys.includes(key),
    );
  if (input.type === "blood_pressure") {
    const { systolic, diastolic } = input;
    if (
      !present(["systolic", "diastolic"]) ||
      !Number.isInteger(systolic) ||
      !Number.isInteger(diastolic)
    ) {
      return { ok: false, reason: "invalid" };
    }
    if (
      !within(systolic as number, BP_RANGES.systolic) ||
      !within(diastolic as number, BP_RANGES.diastolic) ||
      (systolic as number) <= (diastolic as number)
    ) {
      return { ok: false, reason: "out_of_range" };
    }
    const item = (
      code: string,
      display: string,
      value: number,
    ): ManualItem => ({
      resourceType: "Observation",
      category: "blood_pressure",
      codeSystem: LOINC,
      code,
      display,
      valueNum: value,
      valueText: null,
      unit: "mm[Hg]",
      effectiveAt,
      dedupeKey: dedupeKey(LOINC, code, input.date, value),
    });
    return {
      ok: true,
      items: [
        item("8480-6", "Systolic blood pressure", systolic as number),
        item("8462-4", "Diastolic blood pressure", diastolic as number),
      ],
    };
  }
  if (input.type === "glucose" || input.type === "lab_result") {
    const test: LabTest | undefined =
      input.type === "glucose" ? "glucose" : input.test;
    const allowed: (keyof ManualInput)[] =
      input.type === "glucose" ? ["value", "unit"] : ["test", "value", "unit"];
    if (test === undefined || !present(allowed)) {
      return { ok: false, reason: "invalid" };
    }
    const spec = LAB_CODES[test];
    const unit = input.unit ?? spec.unit;
    const convert = Object.hasOwn(spec.conversions, unit)
      ? spec.conversions[unit]
      : undefined;
    if (
      convert === undefined ||
      typeof input.value !== "number" ||
      !Number.isFinite(input.value)
    ) {
      return { ok: false, reason: "invalid" };
    }
    const value = round4(convert(input.value));
    if (!within(value, MANUAL_RANGES[spec.ruleKey])) {
      return { ok: false, reason: "out_of_range" };
    }
    return {
      ok: true,
      items: [
        {
          resourceType: "Observation",
          category: spec.category,
          codeSystem: LOINC,
          code: spec.code,
          display: spec.display,
          valueNum: value,
          valueText: null,
          unit: spec.unit,
          effectiveAt,
          dedupeKey: dedupeKey(LOINC, spec.code, input.date, value),
        },
      ],
    };
  }
  // Vaccine, medication, condition: a name only.
  const name = input.name?.trim();
  if (!present(["name"]) || !name || name.length > 200) {
    return { ok: false, reason: "invalid" };
  }
  const shape = {
    vaccine: { resourceType: "Immunization", category: "immunizations" },
    medication: { resourceType: "MedicationRequest", category: null },
    condition: { resourceType: "Condition", category: null },
  } as const;
  const { resourceType, category } = shape[input.type];
  return {
    ok: true,
    items: [
      {
        resourceType,
        category,
        codeSystem: MANUAL_CODE_SYSTEM,
        code: input.type,
        display: name,
        valueNum: null,
        valueText: null,
        unit: null,
        effectiveAt,
        dedupeKey: dedupeKey(MANUAL_CODE_SYSTEM, input.type, input.date, name),
      },
    ],
  };
}

/**
 * The plausibility range of a stored value by its code (canonical unit), or
 * null for a code without one. Used when the member corrects a value.
 */
export function plausibleRange(
  codeSystem: string,
  code: string,
): readonly [number, number] | null {
  if (codeSystem !== LOINC) return null;
  if (code === "8480-6") return BP_RANGES.systolic;
  if (code === "8462-4") return BP_RANGES.diastolic;
  const lab = Object.values(LAB_CODES).find((spec) => spec.code === code);
  return lab ? MANUAL_RANGES[lab.ruleKey] : null;
}
