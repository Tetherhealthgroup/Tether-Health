import { Type } from "class-transformer";
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  ValidateNested,
} from "class-validator";
import {
  labTests,
  manualTypes,
  type LabTest,
  type ManualType,
} from "./manual-entry";

export class ManualEntryDto {
  @IsIn(manualTypes)
  type!: ManualType;

  /** lab_result only. */
  @IsOptional()
  @IsIn(labTests)
  test?: LabTest;

  /** glucose and lab_result. */
  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false, maxDecimalPlaces: 4 })
  value?: number;

  /** glucose and lab_result; the test's canonical unit when omitted. */
  @IsOptional()
  @IsString()
  @Length(1, 32)
  unit?: string;

  /** blood_pressure only (mm[Hg]). */
  @IsOptional()
  @IsInt()
  systolic?: number;

  @IsOptional()
  @IsInt()
  diastolic?: number;

  /** vaccine, medication and condition only. */
  @IsOptional()
  @IsString()
  @Length(1, 200)
  name?: string;

  /** The date on the report, YYYY-MM-DD; not in the future. */
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  date!: string;
}

export class AcceptItemsDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(200)
  @ArrayUnique()
  @IsUUID("all", { each: true })
  itemIds!: string[];
}

export const conflictChoices = [
  "use_imported",
  "keep_both",
  "keep_mine",
  "discard",
  "correct",
] as const;
export type ConflictChoice = (typeof conflictChoices)[number];

export class ConflictResolutionDto {
  @IsUUID()
  itemId!: string;

  @IsIn(conflictChoices)
  choice!: ConflictChoice;

  /** `correct` only: the value the member says is right, in the item's unit. */
  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false, maxDecimalPlaces: 4 })
  correctedValue?: number;
}

export class ResolveConflictsDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => ConflictResolutionDto)
  resolutions!: ConflictResolutionDto[];
}

export const itemStatuses = [
  "pending_review",
  "accepted",
  "rejected",
  "conflict",
] as const;
export type ItemStatus = (typeof itemStatuses)[number];

export interface RecordItemResponse {
  id: string;
  sourceId: string;
  /** True for values the member typed ("Entered by you"). */
  enteredByYou: boolean;
  resourceType:
    "Observation" | "Condition" | "MedicationRequest" | "Immunization";
  category: string | null;
  codeSystem: string;
  code: string;
  display: string;
  value: number | null;
  valueText: string | null;
  unit: string | null;
  effectiveAt: string | null;
  status: ItemStatus;
}

export interface ProgrammeRouteCount {
  programmeCode: string;
  items: number;
}

export interface ManualEntryResponse {
  items: RecordItemResponse[];
  /** Programmes that received the value (records_import consent, category). */
  routedTo: ProgrammeRouteCount[];
}

export interface AcceptResponse {
  accepted: number;
  routedTo: ProgrammeRouteCount[];
}

export interface ConflictsResponse {
  accepted: string[];
  rejected: string[];
  /** Corrected values stored as new items entered by the member. */
  created: string[];
  routedTo: ProgrammeRouteCount[];
}

export interface RecordSourceResponse {
  id: string;
  kind: string;
  displayName: string;
  status: "connected" | "needs_reauth" | "disconnected";
  lastSyncedAt: string | null;
  createdAt: string;
}

export interface RecordsSummaryResponse {
  sources: number;
  /** Items waiting for the member (pending review or in conflict). */
  needsReview: number;
  categories: { category: string; items: number; programmes: string[] }[];
}
