import {
  ArrayMinSize,
  IsIn,
  IsInt,
  IsString,
  Matches,
  Max,
  Min,
} from "class-validator";
import { CODE_PATTERN, OPTION_CODES, ZONES } from "./option-codes";
import {
  IsCodes,
  IsDecimal3,
  IsEventTime,
  IsPresentOptional,
  IsRecordDate,
} from "./validators";

// Request bodies of the programme event routes. Unknown keys are refused
// (400 invalid_request). Option values are the spec's codes; the database
// stays the authority on shapes and bounds and checks them again.

/** Every programme entry route: an optional time the event happened. */
class EntryBody {
  @IsPresentOptional()
  @IsEventTime()
  occurredAt?: string;
}

export class HwReadingsDto {
  @IsInt()
  systolic!: number;

  @IsInt()
  diastolic!: number;

  @IsPresentOptional()
  @IsInt()
  pulse?: number;

  @IsPresentOptional()
  @IsEventTime()
  measuredAt?: string;
}

export class HwLipidsDto {
  @IsPresentOptional()
  @IsDecimal3()
  total?: number;

  @IsPresentOptional()
  @IsDecimal3()
  ldl?: number;

  @IsPresentOptional()
  @IsDecimal3()
  hdl?: number;

  @IsPresentOptional()
  @IsDecimal3()
  triglycerides?: number;

  /** Required; 1900-01-01 to tomorrow's UTC date, no 5-minute rule. */
  @IsRecordDate()
  labDate!: string;
}

export class StReadingsDto {
  @IsDecimal3()
  reading!: number;

  @IsPresentOptional()
  @IsIn(OPTION_CODES.glucoseTiming)
  when?: string;

  @IsPresentOptional()
  @IsCodes(OPTION_CODES.glucoseFeelings)
  feelings?: string[];

  @IsPresentOptional()
  @IsString()
  note?: string;

  @IsPresentOptional()
  @IsEventTime()
  measuredAt?: string;
}

export class StA1cDto {
  @IsDecimal3()
  a1c!: number;

  /** Required; 1900-01-01 to tomorrow's UTC date, no 5-minute rule. */
  @IsRecordDate()
  labDate!: string;
}

export class ReLabsDto {
  @IsPresentOptional()
  @IsDecimal3()
  egfr?: number;

  @IsPresentOptional()
  @IsDecimal3()
  urineAcr?: number;

  @IsPresentOptional()
  @IsDecimal3()
  alt?: number;

  /** Required; 1900-01-01 to tomorrow's UTC date, no 5-minute rule. */
  @IsRecordDate()
  labDate!: string;
}

export class CaZoneChecksDto {
  @IsIn(ZONES)
  zone!: string;

  @IsPresentOptional()
  @IsCodes(OPTION_CODES.zoneSymptoms)
  symptoms?: string[];

  @IsPresentOptional()
  @IsDecimal3()
  peakFlow?: number;

  /** The time of the check, for the entry and the peak-flow reading. */
  @IsPresentOptional()
  @IsEventTime()
  checkedAt?: string;
}

export class CaSymptomsDto extends EntryBody {
  @IsCodes(OPTION_CODES.caSymptoms)
  @ArrayMinSize(1)
  symptoms!: string[];

  @IsPresentOptional()
  @IsIn(OPTION_CODES.caSeverity)
  severity?: string;

  @IsPresentOptional()
  @IsCodes(OPTION_CODES.caTriggers)
  triggers?: string[];

  @IsPresentOptional()
  @IsString()
  note?: string;
}

export class EaMoodsDto extends EntryBody {
  @IsIn(OPTION_CODES.mood)
  mood!: string;

  @IsPresentOptional()
  @IsCodes(OPTION_CODES.moodTopics)
  topics?: string[];
}

export class EaCheckBacksDto extends EntryBody {
  @IsIn(OPTION_CODES.checkBackChange)
  change!: string;

  @IsPresentOptional()
  @IsIn(OPTION_CODES.reachedOut)
  reachedOut?: string;
}

export class SdSessionsDto extends EntryBody {
  @IsPresentOptional()
  @IsCodes(OPTION_CODES.sessionSettings)
  settings?: string[];
}

export class SdFallsDto extends EntryBody {}

export class SfPausesDto extends EntryBody {
  @IsIn(OPTION_CODES.pauseReason)
  reason!: string;
}

export class CkDoneDto extends EntryBody {
  /** No spec option list yet: the code pattern only. */
  @IsString()
  @Matches(CODE_PATTERN)
  item!: string;

  /** Required; a real date from 1900-01-01 to tomorrow's UTC date. */
  @IsRecordDate()
  doneOn!: string;

  @IsPresentOptional()
  @IsString()
  place?: string;
}

export class BeDiaryDto extends EntryBody {
  @IsInt()
  @Min(0)
  @Max(10)
  fatigue!: number;

  @IsPresentOptional()
  @IsCodes(OPTION_CODES.diarySymptoms)
  symptoms?: string[];
}

export class BeSurvivorshipDto extends EntryBody {
  @IsIn(OPTION_CODES.survivorshipFeeling)
  feeling!: string;
}

/** 201: the submission was written. */
export interface ProgrammeRecordCreated {
  submissionId: string;
}

/** 200: every row of the submission was already stored, unchanged. */
export interface ProgrammeRecordReplayed {
  submissionId: string;
  replayed: true;
}
