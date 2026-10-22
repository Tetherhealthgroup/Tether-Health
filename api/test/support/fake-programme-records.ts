/**
 * The checks of public.observations and public.programme_entries
 * (supabase/migrations/202610180013_programme_records.sql) for the fake
 * PostgREST: the before-insert payload and attribute triggers and the CHECK
 * constraints. Each returns the name of the failed check, or null. The
 * fake raises them as 23514, in Postgres executor order.
 */

type Row = Record<string, unknown>;

const CODE = /^[a-z0-9_]{1,40}$/;
const DATE = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;

const isCode = (value: unknown) =>
  typeof value === "string" && CODE.test(value);
const isCodes = (value: unknown) =>
  Array.isArray(value) &&
  value.length <= 12 &&
  value.every(isCode) &&
  new Set(value).size === value.length;
/** jsonb number whose text is 0..10 (an integer score). */
const isScore = (value: unknown) =>
  typeof value === "number" && /^([0-9]|10)$/.test(String(value));
const isText = (value: unknown) =>
  typeof value === "string" &&
  value === value.trim() &&
  [...value].length >= 1 &&
  [...value].length <= 500;
const isDate = (value: unknown) => {
  if (typeof value !== "string" || !DATE.test(value)) return false;
  const date = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().startsWith(value);
};
const CHECKS: Record<string, (value: unknown) => boolean> = {
  code: isCode,
  codes: isCodes,
  score: isScore,
  text: isText,
  date: isDate,
};

/** programme_entries_check_payload: key list and types per kind. */
const PAYLOADS: Record<
  string,
  { spec: Record<string, string>; required: string[] }
> = {
  checkin: {
    spec: { feel: "code", stress: "code", answer: "code" },
    required: [],
  },
  "ca.zone_check": {
    spec: { zone: "code", symptoms: "codes" },
    required: ["zone"],
  },
  "ca.symptom": {
    spec: {
      symptoms: "codes",
      severity: "code",
      triggers: "codes",
      note: "text",
    },
    required: ["symptoms"],
  },
  "ea.mood": { spec: { mood: "code", topics: "codes" }, required: ["mood"] },
  "ea.check_back": {
    spec: { change: "code", reached_out: "code" },
    required: ["change"],
  },
  "sd.session": { spec: { settings: "codes" }, required: [] },
  "sd.fall": { spec: {}, required: [] },
  "sf.pause": { spec: { reason: "code" }, required: ["reason"] },
  "ck.done": {
    spec: { item: "code", done_on: "date", place: "text" },
    required: ["item", "done_on"],
  },
  "be.diary": {
    spec: { fatigue: "score", symptoms: "codes" },
    required: ["fatigue"],
  },
  "be.survivorship": { spec: { feeling: "code" }, required: ["feeling"] },
};

const isObject = (value: unknown): value is Row =>
  value !== null && typeof value === "object" && !Array.isArray(value);

/** The trigger raised before any constraint; an unknown kind passes it. */
export function payloadTriggerFails(kind: unknown, payload: unknown): boolean {
  if (!isObject(payload)) return true;
  const entry = typeof kind === "string" ? PAYLOADS[kind] : undefined;
  if (!entry) return false;
  if (
    kind === "checkin" &&
    !["feel", "stress", "answer"].some((k) => k in payload)
  ) {
    return true;
  }
  if (!entry.required.every((key) => key in payload)) return true;
  return !Object.entries(payload).every(([key, value]) => {
    const type = entry.spec[key];
    return type !== undefined && CHECKS[type]!(value);
  });
}

const OBSERVATION_METRICS = [
  "bp_systolic",
  "bp_diastolic",
  "heart_rate",
  "chol_total",
  "chol_ldl",
  "chol_hdl",
  "triglycerides",
  "a1c",
  "egfr",
  "urine_acr",
  "alt",
  "peak_flow",
];

/** observations_check_attributes; an unknown metric passes it. */
export function attributesTriggerFails(
  metric: unknown,
  attributes: unknown,
): boolean {
  if (!isObject(attributes)) return true;
  if (metric === "glucose") {
    return !Object.entries(attributes).every(([key, value]) =>
      key === "timing"
        ? isCode(value)
        : key === "feelings"
          ? isCodes(value)
          : key === "note"
            ? isText(value)
            : false,
    );
  }
  if (OBSERVATION_METRICS.includes(metric as string)) {
    return Object.keys(attributes).length > 0;
  }
  return false;
}

/** The text of a jsonb value as Postgres prints it (for octet_length). */
export function jsonbText(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(jsonbText).join(", ")}]`;
  if (isObject(value)) {
    return `{${Object.entries(value)
      .map(([key, inner]) => `${JSON.stringify(key)}: ${jsonbText(inner)}`)
      .join(", ")}}`;
  }
  return JSON.stringify(value);
}
const octets = (value: unknown) => Buffer.byteLength(jsonbText(value), "utf8");

const METRIC_RULES: [string[], string, string][] = [
  [["bp_systolic", "bp_diastolic"], "mm[Hg]", "hw"],
  [["heart_rate"], "/min", "hw"],
  [["chol_total", "chol_ldl", "chol_hdl", "triglycerides"], "mg/dL", "hw"],
  [["glucose"], "mg/dL", "st"],
  [["a1c"], "%", "st"],
  [["egfr"], "mL/min/{1.73_m2}", "re"],
  [["urine_acr"], "mg/g", "re"],
  [["alt"], "U/L", "re"],
  [["peak_flow"], "L/min", "ca"],
];

const DAY = 24 * 60 * 60 * 1000;
const FIVE_MINUTES = 5 * 60 * 1000;
const instant = (value: unknown) =>
  typeof value === "string" ? Date.parse(value) : Number.NaN;

/** The first failing CHECK constraint of an observations row, or null. */
export function observationCheckFails(row: Row): string | null {
  const value = row.value as number;
  if (!(value >= 0 && value <= 10000)) return "observations_value_check";
  const effective = instant(row.effective_at);
  const created = instant(row.created_at);
  if (!(
    effective >= Date.parse("1900-01-01T00:00:00Z") &&
    effective <= created + DAY
  )) {
    return "observations_effective_at_check";
  }
  if (!isObject(row.attributes) || octets(row.attributes) > 2048) {
    return "observations_attributes_check";
  }
  const allowed = METRIC_RULES.some(
    ([metrics, unit, programme]) =>
      metrics.includes(row.metric as string) &&
      row.unit_ucum === unit &&
      row.programme_code === programme,
  );
  return allowed ? null : "observations_metric_check";
}

const KINDS = Object.keys(PAYLOADS);

/** The first failing CHECK constraint of a programme_entries row, or null. */
export function entryCheckFails(row: Row): string | null {
  const kind = row.kind as string;
  if (!KINDS.includes(kind)) return "programme_entries_kind_check";
  if (kind !== "checkin" && kind.split(".")[0] !== row.programme_code) {
    return "programme_entries_kind_programme_check";
  }
  const occurred = instant(row.occurred_at);
  const created = instant(row.created_at);
  if (!(
    occurred >= Date.parse("2000-01-01T00:00:00Z") &&
    occurred <= created + FIVE_MINUTES
  )) {
    return "programme_entries_occurred_at_check";
  }
  if (!isObject(row.payload) || octets(row.payload) > 4096) {
    return "programme_entries_payload_check";
  }
  return null;
}
