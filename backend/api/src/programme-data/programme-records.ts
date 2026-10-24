/**
 * The rows one submission writes, and the replay comparison. Mirrors
 * supabase/migrations/202610180013_programme_records.sql (observations and
 * programme_entries); the database stays the authority.
 */

export type JsonObject = Record<string, unknown>;

/** A programme_entries row before its member, enrolment and submission. */
export interface EntryDraft {
  kind: string;
  payload: JsonObject;
  /** RFC 3339, or null for the server's time of the request. */
  occurredAt: string | null;
}

/** An observations row before its member, enrolment and submission. */
export interface ObservationDraft {
  metric: Metric;
  value: number;
  attributes: JsonObject;
  /** RFC 3339, or null for the server's time of the request. */
  effectiveAt: string | null;
}

/**
 * What one submit writes: at most one programme entry, then its
 * observations. The entry is inserted first (a conflicting entry stops the
 * submit before any observation is written).
 */
export interface Draft {
  entry: EntryDraft | null;
  observations: ObservationDraft[];
}

/** Each metric's fixed UCUM unit and programme (observations_metric_check). */
export const METRICS = {
  bp_systolic: { unit: "mm[Hg]", programme: "hw" },
  bp_diastolic: { unit: "mm[Hg]", programme: "hw" },
  heart_rate: { unit: "/min", programme: "hw" },
  chol_total: { unit: "mg/dL", programme: "hw" },
  chol_ldl: { unit: "mg/dL", programme: "hw" },
  chol_hdl: { unit: "mg/dL", programme: "hw" },
  triglycerides: { unit: "mg/dL", programme: "hw" },
  glucose: { unit: "mg/dL", programme: "st" },
  a1c: { unit: "%", programme: "st" },
  egfr: { unit: "mL/min/{1.73_m2}", programme: "re" },
  urine_acr: { unit: "mg/g", programme: "re" },
  alt: { unit: "U/L", programme: "re" },
  peak_flow: { unit: "L/min", programme: "ca" },
} as const;
export type Metric = keyof typeof METRICS;

/** observations_value_check: the only bound on a value without a spec range. */
export const VALUE_MIN = 0;
export const VALUE_MAX = 10000;

export type Row = Record<string, unknown>;

export interface SubmissionContext {
  userId: string;
  enrolmentId: string;
  programmeCode: string;
  submissionId: string;
  /** The server's time of the request, for times the client did not send. */
  now: string;
}

/** A lab date as stored: midnight UTC of that date. */
export const labDateTime = (date: string) => `${date}T00:00:00Z`;

/** Drops keys whose value is undefined (an omitted optional field). */
export function present(object: JsonObject): JsonObject {
  return Object.fromEntries(
    Object.entries(object).filter(([, value]) => value !== undefined),
  );
}

export function entryRow(entry: EntryDraft, context: SubmissionContext): Row {
  return {
    user_id: context.userId,
    enrolment_id: context.enrolmentId,
    programme_code: context.programmeCode,
    submission_id: context.submissionId,
    kind: entry.kind,
    occurred_at: entry.occurredAt ?? context.now,
    payload: entry.payload,
  };
}

export function observationRow(
  observation: ObservationDraft,
  context: SubmissionContext,
): Row {
  return {
    user_id: context.userId,
    enrolment_id: context.enrolmentId,
    programme_code: context.programmeCode,
    submission_id: context.submissionId,
    metric: observation.metric,
    value: observation.value,
    unit_ucum: METRICS[observation.metric].unit,
    effective_at: observation.effectiveAt ?? context.now,
    attributes: observation.attributes,
  };
}

/**
 * The stored fields a replay compares. Never compared: the time columns
 * (occurred_at, effective_at, created_at), id and submission_id; the first
 * stored time wins.
 */
export const ENTRY_COMPARED = [
  "user_id",
  "enrolment_id",
  "programme_code",
  "kind",
  "payload",
] as const;
export const OBSERVATION_COMPARED = [
  "user_id",
  "enrolment_id",
  "programme_code",
  "metric",
  "value",
  "unit_ucum",
  "attributes",
] as const;

/** A canonical text of a JSON value: object keys sorted, as jsonb does. */
function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`;
  if (value !== null && typeof value === "object") {
    return `{${Object.keys(value)
      .sort()
      .map(
        (key) =>
          `${JSON.stringify(key)}:${canonical((value as JsonObject)[key])}`,
      )
      .join(",")}}`;
  }
  return JSON.stringify(value);
}

/** One row's compared fields; numbers by value, uuids case-insensitively. */
function comparable(row: Row, fields: readonly string[]): string {
  return canonical(
    Object.fromEntries(
      fields.map((field) => {
        const value = row[field];
        if (field === "value") return [field, Number(value)];
        if (field === "user_id" || field === "enrolment_id") {
          return [
            field,
            typeof value === "string" ? value.toLowerCase() : value,
          ];
        }
        return [field, value];
      }),
    ),
  );
}

/**
 * Whether the stored rows of a submission are exactly the computed rows,
 * compared on `fields` only, as multisets (order does not matter).
 */
export function sameRows(
  stored: readonly Row[],
  computed: readonly Row[],
  fields: readonly string[],
): boolean {
  if (stored.length !== computed.length) return false;
  const a = stored.map((row) => comparable(row, fields)).sort();
  const b = computed.map((row) => comparable(row, fields)).sort();
  return a.every((value, index) => value === b[index]);
}
