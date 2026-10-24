import { IsIn, ValidateIf } from "class-validator";

/**
 * Age bands of public.wellbeing_baseline.age_range: no exact ages, and
 * everyone 75 and over is one band. Must equal the list in the latest
 * wellbeing_baseline_age_range_check migration (the parity test reads it).
 */
export const AGE_RANGES = [
  "18_24",
  "25_34",
  "35_44",
  "45_54",
  "55_64",
  "65_74",
  "75_plus",
] as const;

/**
 * `ob_basics` "Sleep on a typical night": each spec label and its stored
 * code (wellbeing_baseline_sleep_band_check).
 */
export const SLEEP_BANDS = {
  "< 5 h": "lt5",
  "5–6 h": "5_6",
  "7–8 h": "7_8",
  "9+ h": "9plus",
} as const;

/** `ob_basics` "Usual stress": slug of each label. */
export const STRESS_BANDS = ["low", "some", "high"] as const;

/** Absent or null both mean "not given". */
const IsNullable = () =>
  ValidateIf(
    (_object: object, value: unknown) => value !== undefined && value !== null,
  );

/** PUT replaces all three; a field that is absent or null is stored as null. */
export class PutBaselineDto {
  @IsNullable()
  @IsIn(AGE_RANGES)
  ageRange?: string | null;

  @IsNullable()
  @IsIn(Object.values(SLEEP_BANDS))
  sleepBand?: string | null;

  @IsNullable()
  @IsIn(STRESS_BANDS)
  stressBand?: string | null;
}
export const BASELINE_FIELDS = ["ageRange", "sleepBand", "stressBand"];

export interface Baseline {
  ageRange: string | null;
  sleepBand: string | null;
  stressBand: string | null;
}
