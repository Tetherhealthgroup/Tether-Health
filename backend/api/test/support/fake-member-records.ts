/**
 * The checks of public.rescue_events, public.lesson_progress,
 * public.programme_reminders, public.notification_preferences and
 * public.wellbeing_baseline (supabase/migrations/202610180013_programme_records.sql,
 * with the age-band list of 202610180014_baseline_age_bands.sql) for the
 * fake PostgREST. Each returns the name of the first failing CHECK
 * constraint, in the order the migration declares them, or null.
 */

type Row = Record<string, unknown>;

const CODE = /^[a-z0-9_]{1,40}$/;
const LESSON_ID = /^[a-z0-9][a-z0-9_.-]{0,79}$/;
const FIVE_MINUTES = 5 * 60 * 1000;
const instant = (value: unknown) =>
  typeof value === "string" ? Date.parse(value) : Number.NaN;
/** A smallint between 0 and 10, or null (a CHECK passes on null). */
const scoreOrNull = (value: unknown) =>
  value === null ||
  (typeof value === "number" &&
    Number.isInteger(value) &&
    value >= 0 &&
    value <= 10);

/** 202610180014: the age bands. */
export const AGE_BANDS = [
  "18_24",
  "25_34",
  "35_44",
  "45_54",
  "55_64",
  "65_74",
  "75_plus",
];
const SLEEP_BANDS = ["lt5", "5_6", "7_8", "9plus"];
const STRESS_BANDS = ["low", "some", "high"];

export function rescueCheckFails(row: Row): string | null {
  if ((row.enrolment_id === null) !== (row.programme_code === null)) {
    return "rescue_events_enrolment_check";
  }
  if (row.programme_code !== null && row.programme_code !== "bf") {
    return "rescue_events_programme_check";
  }
  if (typeof row.tool !== "string" || !CODE.test(row.tool)) {
    return "rescue_events_tool_check";
  }
  const opened = instant(row.opened_at);
  if (!(
    opened >= Date.parse("2000-01-01T00:00:00Z") &&
    opened <= instant(row.created_at) + FIVE_MINUTES
  )) {
    return "rescue_events_opened_at_check";
  }
  if (!scoreOrNull(row.intensity_before)) {
    return "rescue_events_intensity_before_check";
  }
  if (!scoreOrNull(row.intensity_after)) {
    return "rescue_events_intensity_after_check";
  }
  if (
    row.helped !== null &&
    !["yes", "a_little", "no"].includes(row.helped as string)
  ) {
    return "rescue_events_helped_check";
  }
  return null;
}

export function lessonCheckFails(row: Row): string | null {
  return typeof row.lesson_id === "string" && LESSON_ID.test(row.lesson_id)
    ? null
    : "lesson_progress_lesson_id_check";
}

export function baselineCheckFails(row: Row): string | null {
  if (row.age_range !== null && !AGE_BANDS.includes(row.age_range as string)) {
    return "wellbeing_baseline_age_range_check";
  }
  if (
    row.sleep_band !== null &&
    !SLEEP_BANDS.includes(row.sleep_band as string)
  ) {
    return "wellbeing_baseline_sleep_band_check";
  }
  if (
    row.stress_band !== null &&
    !STRESS_BANDS.includes(row.stress_band as string)
  ) {
    return "wellbeing_baseline_stress_band_check";
  }
  return null;
}

/**
 * A value cast to `time` as Postgres prints it (HH:MM:SS), or null when
 * the cast fails (22007).
 */
export function timeValue(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const match = /^([01][0-9]|2[0-3]):([0-5][0-9])(?::([0-5][0-9]))?$/.exec(
    value,
  );
  return match ? `${match[1]}:${match[2]}:${match[3] ?? "00"}` : null;
}
