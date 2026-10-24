import {
  IsBoolean,
  IsIn,
  IsInt,
  IsString,
  Matches,
  Max,
  Min,
  ValidateBy,
} from "class-validator";
import { CODE_PATTERN } from "../programme-data/option-codes";
import { IsEventTime, IsPresentOptional } from "../programme-data/validators";
import { PROGRAMME_CODE } from "./records-access";

// Request bodies of the records event routes. Unknown keys are refused (400
// invalid_request). Option values are slug(label) of the spec's labels; the
// parity test derives each list from specs-and-design/tether_ui/spec/screens.json.

/** `checkin` "How do you feel today?" */
export const FEEL = ["low", "not_great", "okay", "good", "great"] as const;
/** `checkin` "Stress today" */
export const STRESS = ["low", "some", "high"] as const;
/**
 * The programme cards of `checkin`, by the card's programme: BreatheFree
 * "Since your last check-in, did you smoke?" and ScrollFree "How did you
 * feel after scrolling yesterday?". "Skip" means the key is omitted.
 */
export const ANSWERS = {
  bf: ["no", "a_puff", "one_or_more"],
  sf: ["better", "same", "drained"],
} as const satisfies Record<string, readonly string[]>;
export type AnswerProgramme = keyof typeof ANSWERS;
export const ANSWER_PROGRAMMES = Object.keys(ANSWERS) as AnswerProgramme[];

/**
 * `rescue_result` "Did it help?": slug of each label, except "Not this
 * time", which is `no` (the database's list is yes, a_little, no).
 */
export const HELPED = ["yes", "a_little", "no"] as const;

/** lesson_progress_lesson_id_check. */
export const LESSON_ID = /^[a-z0-9][a-z0-9_.-]{0,79}$/;

/** An object whose own keys are card programmes, each with one of its codes. */
export function isCheckInAnswers(value: unknown): boolean {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  return Reflect.ownKeys(value).every((key) => {
    if (typeof key !== "string" || !Object.hasOwn(ANSWERS, key)) return false;
    const codes: readonly string[] = ANSWERS[key as AnswerProgramme];
    const answer = (value as Record<string, unknown>)[key];
    return typeof answer === "string" && codes.includes(answer);
  });
}

export class CheckInDto {
  @IsPresentOptional()
  @IsIn(FEEL)
  feel?: string;

  @IsPresentOptional()
  @IsIn(STRESS)
  stress?: string;

  @IsPresentOptional()
  @ValidateBy({
    name: "isCheckInAnswers",
    validator: { validate: (value: unknown) => isCheckInAnswers(value) },
  })
  answers?: Partial<Record<AnswerProgramme, string>>;

  @IsPresentOptional()
  @IsEventTime()
  occurredAt?: string;
}
export const CHECK_IN_FIELDS = ["feel", "stress", "answers", "occurredAt"];

export class RescueDto {
  /** Only BreatheFree; absent means a shared (account-level) rescue. */
  @IsPresentOptional()
  @IsIn(["bf"])
  programme?: "bf";

  @IsString()
  @Matches(CODE_PATTERN)
  tool!: string;

  @IsPresentOptional()
  @IsEventTime()
  openedAt?: string;

  @IsPresentOptional()
  @IsInt()
  @Min(0)
  @Max(10)
  intensityBefore?: number;

  @IsPresentOptional()
  @IsInt()
  @Min(0)
  @Max(10)
  intensityAfter?: number;

  @IsPresentOptional()
  @IsIn(HELPED)
  helped?: string;

  @IsPresentOptional()
  @IsBoolean()
  escalated?: boolean;
}
export const RESCUE_FIELDS = [
  "programme",
  "tool",
  "openedAt",
  "intensityBefore",
  "intensityAfter",
  "helped",
  "escalated",
];

export class LessonDto {
  @IsString()
  @Matches(PROGRAMME_CODE)
  programme!: string;

  /** The database pattern, starting with `<programme>.` (checked by the service). */
  @IsString()
  @Matches(LESSON_ID)
  lessonId!: string;
}
export const LESSON_FIELDS = ["programme", "lessonId"];

export interface CheckInCreated {
  submissionId: string;
  /** The programmes that hold a row of this check-in, sorted. */
  entries: string[];
}
export interface CheckInReplayed extends CheckInCreated {
  replayed: true;
}
