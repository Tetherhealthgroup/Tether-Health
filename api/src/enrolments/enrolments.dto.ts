import {
  Equals,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
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
/** Locales of the consent documents (consent_documents.locale). */
export const consentLocales = ["en", "es"] as const;
export type ConsentLocale = (typeof consentLocales)[number];

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

  /**
   * A care connection or caregiver id (UUID) for share purposes only. Share
   * purposes are refused until care connections exist, so today any value is
   * refused; a value that is not a UUID is invalid input.
   */
  @ValidateIf((dto: GrantConsentDto) => dto.recipientRef !== undefined)
  @IsUUID()
  recipientRef?: string;

  /**
   * The version of the consent document the app showed. The database copies
   * that document's text into the consent; the API never substitutes a
   * version of its own.
   */
  @IsString()
  @Matches(consentVersionPattern)
  consentVersion!: string;

  /** The locale of the document the app showed. */
  @IsIn(consentLocales)
  locale!: ConsentLocale;
}

export class SwapFocusDto {
  /** The enrolment leaving focus; it becomes paused (its data is kept). */
  @IsUUID()
  demoteId!: string;

  /** The enrolment entering focus. */
  @IsUUID()
  promoteId!: string;
}

/**
 * Body of "Delete now". The value is checked by the service so that a
 * missing or wrong confirmation gets a stable code.
 */
export class DeleteEnrolmentDto {
  @IsOptional()
  confirmation?: unknown;
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
  /** Null only on consents stored before consent documents existed. */
  locale: ConsentLocale | null;
  /** The document text the database stored with the consent. */
  consentText: string;
  grantedAt: string;
  revokedAt: string | null;
}

export interface GrantConsentResponse extends ConsentResponse {
  /**
   * The id of the core consent this grant superseded (a core re-consent to a
   * later version or another locale), otherwise null.
   */
  supersededId: string | null;
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
  /**
   * Live consents of this enrolment (revoked_at is null), oldest first.
   * Revoked history is not part of this response.
   */
  consents: ConsentResponse[];
  /**
   * The current core document version (current_consent_documents()) for the
   * locale of the live core consent. Null without a live core consent, for
   * a consent stored before documents existed (no locale), or when no core
   * document is current for that locale.
   */
  currentCoreConsentVersion: string | null;
  /**
   * True when the enrolment is not left, has a live core consent, and that
   * consent's version differs from currentCoreConsentVersion (always true
   * for a consent stored before documents existed).
   */
  reconsentRequired: boolean;
}

/** The current core document version per locale; null when there is none. */
export type CoreConsentVersions = Record<ConsentLocale, string | null>;

export interface EnrolmentListResponse {
  currentCoreConsentVersions: CoreConsentVersions;
  enrolments: EnrolmentResponse[];
}

export interface FocusSwapResponse {
  /** The enrolment that left focus, now paused. */
  demoted: EnrolmentResponse;
  /** The enrolment now in focus. */
  promoted: EnrolmentResponse;
}
