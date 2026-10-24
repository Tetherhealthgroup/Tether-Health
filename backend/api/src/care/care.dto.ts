import { Type } from "class-transformer";
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsIn,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  ValidateNested,
} from "class-validator";

// Mirrors supabase/migrations/202610180011_care.sql. The database stays the
// authority; these checks only refuse bad input before it is sent.

/** Programmes a supporter may be linked to (supporters.programme_codes). */
export const supporterProgrammes = ["bf", "sf"] as const;
export type SupporterProgramme = (typeof supporterProgrammes)[number];

/** What a caregiver may see (caregivers.scope). */
export const caregiverScopes = [
  "sd.session_finished",
  "sd.fall_logged",
] as const;
export type CaregiverScope = (typeof caregiverScopes)[number];

/**
 * Bytes a snapshot may take as JSON text. The database allows 65536 bytes of
 * its own jsonb text, which adds a space after every ':' and ','; this
 * bound leaves room for that.
 */
export const SNAPSHOT_MAX_BYTES = 49152;

export class RedeemInviteDto {
  /** The clinic's invite code, as typed (spaces and hyphens allowed). */
  @IsString()
  @Length(1, 80)
  inviteCode!: string;
}

export class CreateSummaryDto {
  @IsString()
  @Matches(/^[a-z]{2}$/)
  programmeCode!: string;

  /**
   * The clinic connection to share with. Optional when exactly one live
   * connection holds a live care-team consent on this programme.
   */
  @IsOptional()
  @IsUUID()
  connectionId?: string;

  /** Exactly what the member previewed; stored as sent, never recomputed. */
  @IsObject()
  snapshot!: Record<string, unknown>;
}

export class MessageAttachmentDto {
  /** The summary the member previewed for this message. */
  @IsObject()
  snapshot!: Record<string, unknown>;
}

export class CreateMessageDto {
  /** Optional when the member has exactly one live clinic connection. */
  @IsOptional()
  @IsUUID()
  connectionId?: string;

  @IsString()
  @Length(1, 80)
  topic!: string;

  @IsString()
  @Length(1, 2000)
  message!: string;

  /** The programme the message is about; needed for an attachment. */
  @IsOptional()
  @IsString()
  @Matches(/^[a-z]{2}$/)
  programmeCode?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => MessageAttachmentDto)
  attachment?: MessageAttachmentDto;
}

export class CreateSupporterDto {
  @IsString()
  @Length(1, 80)
  name!: string;

  /** As typed; stored in E.164 (a number without "+" is read as +1). */
  @IsString()
  @Length(1, 32)
  phone!: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(2)
  @ArrayUnique()
  @IsIn(supporterProgrammes, { each: true })
  programmes!: SupporterProgramme[];

  @IsOptional()
  @IsString()
  @Length(1, 200)
  helpPhrase?: string;
}

export class CreateCaregiverDto {
  @IsString()
  @Length(1, 80)
  name!: string;

  /** As typed; stored in E.164 (a number without "+" is read as +1). */
  @IsString()
  @Length(1, 32)
  phone!: string;

  /** Defaults to both kinds. Other programmes are never available. */
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(2)
  @ArrayUnique()
  @IsIn(caregiverScopes, { each: true })
  scope?: CaregiverScope[];
}

export interface CareConnectionResponse {
  id: string;
  clinicId: string;
  /** Null only if the clinic's name cannot be read. */
  clinicName: string | null;
  connectedAt: string;
  revokedAt: string | null;
}

/**
 * The server stores what the member shared; it sends nothing on its own.
 * Outbound delivery to the clinic is a later change.
 */
export type Delivery = "stored";

export interface CareShareResponse {
  id: string;
  programmeCode: string;
  connectionId: string;
  kind: "visit_summary" | "message_attachment";
  createdAt: string;
  expiresAt: string;
  delivery: Delivery;
}

export interface CareMessageResponse {
  id: string;
  connectionId: string;
  programmeCode: string | null;
  shareId: string | null;
  createdAt: string;
  delivery: Delivery;
}

export interface SupporterResponse {
  id: string;
  name: string;
  phone: string;
  programmes: SupporterProgramme[];
  helpPhrase: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CaregiverResponse {
  id: string;
  programmeCode: "sd";
  name: string;
  phone: string;
  scope: CaregiverScope[];
  /** pending until the member's own message app sends the invite. */
  inviteStatus: "pending" | "sent";
  createdAt: string;
  revokedAt: string | null;
}
