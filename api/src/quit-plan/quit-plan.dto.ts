import { Type } from "class-transformer";
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsString,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
  ValidateNested,
} from "class-validator";

export const dailyCigaretteUseValues = [
  "notEveryDay",
  "tenOrFewer",
  "elevenToTwenty",
  "twentyOneToThirty",
  "thirtyOneOrMore",
] as const;

export const smokingTriggerValues = [
  "stress",
  "afterMeals",
  "driving",
  "coffee",
  "socialSettings",
  "workBreaks",
  "alcohol",
  "boredom",
  "morning",
  "beforeBed",
] as const;

export const readinessPathValues = ["prepare", "explore", "connect"] as const;
export const quitPlanPathValues = [
  "setQuitDate",
  "quitToday",
  "reduceGradually",
] as const;
export const quitReasonValues = [
  "family",
  "breatheEasier",
  "improveHealth",
  "saveMoney",
  "control",
  "future",
  "custom",
] as const;
export const preparationTaskValues = [
  "removeSupplies",
  "smokeFreeSpaces",
  "stockAlternatives",
] as const;

export type DailyCigaretteUse = (typeof dailyCigaretteUseValues)[number];
export type SmokingTrigger = (typeof smokingTriggerValues)[number];
export type ReadinessPath = (typeof readinessPathValues)[number];
export type QuitPlanPath = (typeof quitPlanPathValues)[number];
export type QuitReason = (typeof quitReasonValues)[number];
export type PreparationTask = (typeof preparationTaskValues)[number];
export type SupportChannel = "text" | "call";

export class SupportPersonDto {
  @IsString()
  @Matches(/^[A-Za-z0-9_-]{1,80}$/)
  id!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(80)
  @Matches(/^\S(?:.*\S)?$/)
  name!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(80)
  @Matches(/^\S(?:.*\S)?$/)
  relationship!: string;

  @IsIn(["text", "call"])
  channel!: SupportChannel;

  @IsString()
  @MinLength(1)
  @MaxLength(160)
  @Matches(/^\S(?:.*\S)?$/)
  checkIn!: string;

  @IsBoolean()
  enabled!: boolean;
}

export class PutQuitPlanDto {
  @ValidateIf((_object, value) => value !== null)
  @IsIn(dailyCigaretteUseValues)
  dailyCigaretteUse!: DailyCigaretteUse | null;

  @IsArray()
  @ArrayMaxSize(10)
  @ArrayUnique()
  @IsIn(smokingTriggerValues, { each: true })
  smokingTriggers!: SmokingTrigger[];

  @ValidateIf((_object, value) => value !== null)
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  @Matches(/^\S(?:.*\S)?$/)
  customSmokingTrigger!: string | null;

  @IsIn(readinessPathValues)
  readinessPath!: ReadinessPath;

  @IsIn(quitPlanPathValues)
  quitPlanPath!: QuitPlanPath;

  @IsDateString({ strict: true })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  quitDate!: string;

  @IsBoolean()
  quitDayCheckIn!: boolean;

  @IsArray()
  @ArrayMaxSize(7)
  @ArrayUnique()
  @IsIn(quitReasonValues, { each: true })
  quitReasons!: QuitReason[];

  @ValidateIf((_object, value) => value !== null)
  @IsString()
  @MinLength(1)
  @MaxLength(160)
  @Matches(/^\S(?:.*\S)?$/)
  customQuitReason!: string | null;

  @ValidateIf((_object, value) => value !== null)
  @IsIn(quitReasonValues)
  topQuitReason!: QuitReason | null;

  @IsArray()
  @ArrayMaxSize(10)
  @ArrayUnique((person: SupportPersonDto) => person.id)
  @ValidateNested({ each: true })
  @Type(() => SupportPersonDto)
  supportPeople!: SupportPersonDto[];

  @IsArray()
  @ArrayMaxSize(3)
  @ArrayUnique()
  @IsIn(preparationTaskValues, { each: true })
  preparationTasks!: PreparationTask[];

  @IsBoolean()
  treatmentSupport!: boolean;

  @IsBoolean()
  careTeamReminder!: boolean;
}

export interface QuitPlanResponse extends PutQuitPlanDto {
  userId: string;
  createdAt: string;
  updatedAt: string;
}
