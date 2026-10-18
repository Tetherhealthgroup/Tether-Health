import {
  Equals,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  ValidateIf,
} from "class-validator";

// Mirrors supabase/migrations/202610170002_enrolments.sql. The database stays
// the authority; these checks only refuse bad input before it is sent.
export const programmeCodePattern = /^[a-z]{2}$/;
export const modeProgrammeCodes = ["bf", "sf"] as const;

export const enrolmentStatuses = [
  "focus",
  "learn_only",
  "paused",
  "left",
] as const;
export type EnrolmentStatus = (typeof enrolmentStatuses)[number];
/** An enrolment is never created as left (enrolments_left_state_check). */
export const newEnrolmentStatuses = ["focus", "learn_only", "paused"] as const;
export type NewEnrolmentStatus = (typeof newEnrolmentStatuses)[number];

export const enrolmentModes = ["quit", "reduce"] as const;
export type EnrolmentMode = (typeof enrolmentModes)[number];

export const consentPurposes = [
  "core",
  "reminders",
  "records_import",
  "share_care_team",
  "share_caregiver",
  "research",
  "screen_time",
] as const;
export type ConsentPurpose = (typeof consentPurposes)[number];
export const sharePurposes: readonly ConsentPurpose[] = [
  "share_care_team",
  "share_caregiver",
];
export const consentVersionPattern = /^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$/;

export class CreateEnrolmentDto {
  @IsString()
  @Matches(programmeCodePattern)
  programmeCode!: string;

  @IsIn(newEnrolmentStatuses)
  status!: NewEnrolmentStatus;

  /** Only BreatheFree (bf) and ScrollFree (sf) take a mode; null otherwise. */
  @IsOptional()
  @IsIn(enrolmentModes)
  mode?: EnrolmentMode | null;
}

export class UpdateEnrolmentDto {
  /** Omit to leave unchanged; null is refused. */
  @ValidateIf((_dto, value) => value !== undefined)
  @IsIn(enrolmentStatuses)
  status?: EnrolmentStatus;

  /** null clears the mode; omit to leave it unchanged. */
  @IsOptional()
  @IsIn(enrolmentModes)
  mode?: EnrolmentMode | null;
}

export class GrantConsentDto {
  @IsUUID()
  enrolmentId!: string;

  @IsIn(consentPurposes)
  purpose!: ConsentPurpose;

  /** Required for share purposes and refused for every other purpose. */
  @ValidateIf(
    (dto: GrantConsentDto) =>
      sharePurposes.includes(dto.purpose) || dto.recipientRef !== undefined,
  )
  @IsString()
  @Length(1, 200)
  recipientRef?: string;

  @IsString()
  @Matches(consentVersionPattern)
  consentVersion!: string;

  /** Stored exactly as supplied: the wording the member was shown. */
  @IsString()
  @Length(1, 8000)
  consentText!: string;
}

export class RevokeConsentDto {
  @Equals(true)
  revoked!: true;
}

export interface ConsentResponse {
  id: string;
  enrolmentId: string;
  purpose: ConsentPurpose;
  recipientRef: string | null;
  consentVersion: string;
  consentText: string;
  grantedAt: string;
  revokedAt: string | null;
}

export interface EnrolmentResponse {
  id: string;
  programmeCode: string;
  status: EnrolmentStatus;
  mode: EnrolmentMode | null;
  joinedAt: string;
  leftAt: string | null;
  createdAt: string;
  updatedAt: string;
  /** Live and revoked consents of this enrolment, oldest first. */
  consents: ConsentResponse[];
  /**
   * True when the enrolment is not left and its live core consent was given
   * to a version other than the current core consent version.
   */
  reconsentRequired: boolean;
}

export interface EnrolmentListResponse {
  currentCoreConsentVersion: string;
  enrolments: EnrolmentResponse[];
}
