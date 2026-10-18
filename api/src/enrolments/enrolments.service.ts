import {
  BadGatewayException,
  BadRequestException,
  Injectable,
} from "@nestjs/common";
import type { PostgrestError } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { CURRENT_CORE_CONSENT_VERSION } from "./consent-versions";
import { badRequest, conflict, notFound } from "./enrolment-errors";
import {
  modeProgrammeCodes,
  sharePurposes,
  type ConsentPurpose,
  type ConsentResponse,
  type CreateEnrolmentDto,
  type EnrolmentListResponse,
  type EnrolmentMode,
  type EnrolmentResponse,
  type EnrolmentStatus,
  type GrantConsentDto,
  type UpdateEnrolmentDto,
} from "./enrolments.dto";
import {
  UserSupabaseClientFactory,
  type UserSupabaseClient,
} from "./user-supabase-client";

interface EnrolmentRow {
  id: string;
  user_id: string;
  programme_code: string;
  status: EnrolmentStatus;
  mode: EnrolmentMode | null;
  joined_at: string;
  left_at: string | null;
  created_at: string;
  updated_at: string;
}

interface ConsentRow {
  id: string;
  enrolment_id: string;
  purpose: ConsentPurpose;
  recipient_ref: string | null;
  consent_version: string;
  consent_text: string;
  granted_at: string;
  revoked_at: string | null;
}

const ENROLMENT_COLUMNS =
  "id,user_id,programme_code,status,mode,joined_at,left_at,created_at,updated_at";
const CONSENT_COLUMNS =
  "id,enrolment_id,purpose,recipient_ref,consent_version,consent_text,granted_at,revoked_at";

// Raised by public.enrolments_focus_cap() (deferred, so it surfaces at commit).
const FOCUS_CAP_MESSAGE = "At most two programmes can be in focus";

const UNIQUE_VIOLATION = "23505";
const FOREIGN_KEY_VIOLATION = "23503";
const CHECK_VIOLATION = "23514";
const INSUFFICIENT_PRIVILEGE = "42501";

const isFocusCap = (error: PostgrestError) =>
  error.code === CHECK_VIOLATION && error.message === FOCUS_CAP_MESSAGE;

/**
 * Enrolments and per-programme consents. Every query runs as the caller
 * (anon key + the caller's JWT), so row-level security decides what exists;
 * enrolment queries also filter on the caller's id as a second guard. Rows
 * the caller cannot see are reported as not found, never as forbidden.
 */
@Injectable()
export class EnrolmentsService {
  constructor(private readonly clients: UserSupabaseClientFactory) {}

  async list(user: AuthUser): Promise<EnrolmentListResponse> {
    const client = this.clients.forUser(user);
    const { data, error } = await client
      .from("enrolments")
      .select(ENROLMENT_COLUMNS)
      .eq("user_id", user.id)
      .order("created_at", { ascending: true })
      .returns<EnrolmentRow[]>();
    if (error) throw new BadGatewayException("Enrolments are unavailable");
    const consents = await this.consentsFor(
      client,
      data.map((row) => row.id),
    );
    return {
      currentCoreConsentVersion: CURRENT_CORE_CONSENT_VERSION,
      enrolments: data.map((row) =>
        this.toEnrolment(
          row,
          consents.filter((consent) => consent.enrolment_id === row.id),
        ),
      ),
    };
  }

  async create(
    user: AuthUser,
    dto: CreateEnrolmentDto,
  ): Promise<EnrolmentResponse> {
    const mode = dto.mode ?? null;
    this.checkMode(dto.programmeCode, mode);
    const { data, error } = await this.clients
      .forUser(user)
      .from("enrolments")
      .insert({
        user_id: user.id,
        programme_code: dto.programmeCode,
        status: dto.status,
        mode,
      })
      .select(ENROLMENT_COLUMNS)
      .single<EnrolmentRow>();
    if (error) {
      // One row per user and programme: rejoining is a PATCH, never an insert.
      if (error.code === UNIQUE_VIOLATION) throw conflict("already_enrolled");
      if (error.code === FOREIGN_KEY_VIOLATION) {
        throw notFound("programme_not_found");
      }
      if (isFocusCap(error)) throw conflict("focus_cap_reached");
      // The insert policy pins user_id to the caller, so a refusal here is
      // the deletion barrier.
      if (error.code === INSUFFICIENT_PRIVILEGE) {
        throw conflict("account_deletion_in_progress");
      }
      throw new BadGatewayException("Enrolment could not be created");
    }
    return this.toEnrolment(data, []);
  }

  async update(
    user: AuthUser,
    id: string,
    dto: UpdateEnrolmentDto,
  ): Promise<EnrolmentResponse> {
    if (dto.status === undefined && dto.mode === undefined) {
      throw new BadRequestException("Nothing to update");
    }
    const client = this.clients.forUser(user);
    const current = await this.ownEnrolment(client, user, id);
    if (dto.mode !== undefined) {
      this.checkMode(current.programme_code, dto.mode);
    }
    const rejoining =
      current.status === "left" &&
      dto.status !== undefined &&
      dto.status !== "left";
    if (rejoining) await this.requireDeletionBarrierOpen(client);

    const change: { status?: EnrolmentStatus; mode?: EnrolmentMode | null } =
      {};
    if (dto.status !== undefined) change.status = dto.status;
    if (dto.mode !== undefined) change.mode = dto.mode;
    const { data, error } = await client
      .from("enrolments")
      .update(change)
      .eq("id", id)
      .eq("user_id", user.id)
      .select(ENROLMENT_COLUMNS)
      .maybeSingle<EnrolmentRow>();
    if (error) {
      if (isFocusCap(error)) throw conflict("focus_cap_reached");
      if (error.code === CHECK_VIOLATION) throw conflict("enrolment_conflict");
      throw new BadGatewayException("Enrolment could not be updated");
    }
    if (!data) throw notFound("enrolment_not_found");
    return this.toEnrolment(data, await this.consentsFor(client, [data.id]));
  }

  /** "Delete now": removes the enrolment and everything cascaded from it. */
  async deleteNow(user: AuthUser, id: string): Promise<void> {
    const deleted = await this.deleteEnrolmentNow(
      this.clients.forUser(user),
      user,
      id,
    );
    if (!deleted) throw notFound("enrolment_not_found");
  }

  async grantConsent(
    user: AuthUser,
    dto: GrantConsentDto,
  ): Promise<ConsentResponse> {
    if (
      sharePurposes.includes(dto.purpose) !==
      (dto.recipientRef !== undefined)
    ) {
      throw new BadRequestException("recipientRef does not match purpose");
    }
    const client = this.clients.forUser(user);
    const enrolment = await this.ownEnrolment(client, user, dto.enrolmentId);
    if (enrolment.status === "left") throw conflict("enrolment_left");
    if (
      dto.purpose !== "core" &&
      !(await this.hasLiveCore(client, enrolment))
    ) {
      throw conflict("core_consent_required");
    }
    // A plain insert: the live-row unique index makes a second live grant of
    // the same purpose and recipient fail, and it is reported as such.
    const { data, error } = await client
      .from("programme_consents")
      .insert({
        enrolment_id: enrolment.id,
        purpose: dto.purpose,
        recipient_ref: dto.recipientRef ?? null,
        consent_version: dto.consentVersion,
        consent_text: dto.consentText,
      })
      .select(CONSENT_COLUMNS)
      .single<ConsentRow>();
    if (error) {
      if (error.code === UNIQUE_VIOLATION) {
        throw conflict("consent_already_granted");
      }
      if (error.code === INSUFFICIENT_PRIVILEGE) {
        throw conflict("consent_not_permitted");
      }
      if (error.code === CHECK_VIOLATION) {
        throw new BadRequestException("Consent rejected");
      }
      throw new BadGatewayException("Consent could not be recorded");
    }
    return this.toConsent(data);
  }

  async revokeConsent(user: AuthUser, id: string): Promise<ConsentResponse> {
    const client = this.clients.forUser(user);
    // The database sets the actual revocation time; this value only marks the
    // row as revoked. Only a live row matches.
    const { data, error } = await client
      .from("programme_consents")
      .update({ revoked_at: new Date().toISOString() })
      .eq("id", id)
      .is("revoked_at", null)
      .select(CONSENT_COLUMNS)
      .maybeSingle<ConsentRow>();
    if (error) {
      if (error.code === CHECK_VIOLATION) {
        throw conflict("consent_already_revoked");
      }
      throw new BadGatewayException("Consent could not be revoked");
    }
    if (data) return this.toConsent(data);

    const existing = await client
      .from("programme_consents")
      .select("id,revoked_at")
      .eq("id", id)
      .maybeSingle<Pick<ConsentRow, "id" | "revoked_at">>();
    if (existing.error) {
      throw new BadGatewayException("Consent could not be revoked");
    }
    if (!existing.data) throw notFound("consent_not_found");
    throw conflict("consent_already_revoked");
  }

  /**
   * The single statement behind "Delete now". TH-914 (R-7) replaces it with
   * the audited definer function:
   *   client.rpc("delete_enrolment_now", { p_enrolment_id: id })
   * which checks ownership itself and writes a counts-only deletion audit.
   */
  private async deleteEnrolmentNow(
    client: UserSupabaseClient,
    user: AuthUser,
    id: string,
  ): Promise<boolean> {
    const { data, error } = await client
      .from("enrolments")
      .delete()
      .eq("id", id)
      .eq("user_id", user.id)
      .select("id");
    if (error) throw new BadGatewayException("Enrolment could not be deleted");
    return data.length > 0;
  }

  private async ownEnrolment(
    client: UserSupabaseClient,
    user: AuthUser,
    id: string,
  ): Promise<EnrolmentRow> {
    const { data, error } = await client
      .from("enrolments")
      .select(ENROLMENT_COLUMNS)
      .eq("id", id)
      .eq("user_id", user.id)
      .maybeSingle<EnrolmentRow>();
    if (error) throw new BadGatewayException("Enrolments are unavailable");
    if (!data) throw notFound("enrolment_not_found");
    return data;
  }

  private async hasLiveCore(
    client: UserSupabaseClient,
    enrolment: EnrolmentRow,
  ): Promise<boolean> {
    const { data, error } = await client
      .from("programme_consents")
      .select("id")
      .eq("enrolment_id", enrolment.id)
      .eq("purpose", "core")
      .is("revoked_at", null)
      .limit(1);
    if (error) throw new BadGatewayException("Consents are unavailable");
    return data.length > 0;
  }

  private async consentsFor(
    client: UserSupabaseClient,
    enrolmentIds: string[],
  ): Promise<ConsentRow[]> {
    if (enrolmentIds.length === 0) return [];
    const { data, error } = await client
      .from("programme_consents")
      .select(CONSENT_COLUMNS)
      .in("enrolment_id", enrolmentIds)
      .order("granted_at", { ascending: true })
      .returns<ConsentRow[]>();
    if (error) throw new BadGatewayException("Consents are unavailable");
    return data;
  }

  // Rejoining is refused once account deletion has started.
  private async requireDeletionBarrierOpen(
    client: UserSupabaseClient,
  ): Promise<void> {
    const { data, error } = (await client.rpc("deletion_barrier_open")) as {
      data: unknown;
      error: PostgrestError | null;
    };
    if (error) throw new BadGatewayException("Enrolment could not be updated");
    if (data !== true) throw conflict("account_deletion_in_progress");
  }

  private checkMode(programmeCode: string, mode: EnrolmentMode | null) {
    if (
      mode !== null &&
      !(modeProgrammeCodes as readonly string[]).includes(programmeCode)
    ) {
      throw badRequest("mode_not_allowed");
    }
  }

  private toEnrolment(
    row: EnrolmentRow,
    consents: ConsentRow[],
  ): EnrolmentResponse {
    const liveCore = consents.find(
      (consent) => consent.purpose === "core" && consent.revoked_at === null,
    );
    return {
      id: row.id,
      programmeCode: row.programme_code,
      status: row.status,
      mode: row.mode,
      joinedAt: row.joined_at,
      leftAt: row.left_at,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      consents: consents.map((consent) => this.toConsent(consent)),
      reconsentRequired:
        row.status !== "left" &&
        liveCore !== undefined &&
        liveCore.consent_version !== CURRENT_CORE_CONSENT_VERSION,
    };
  }

  private toConsent(row: ConsentRow): ConsentResponse {
    return {
      id: row.id,
      enrolmentId: row.enrolment_id,
      purpose: row.purpose,
      recipientRef: row.recipient_ref,
      consentVersion: row.consent_version,
      consentText: row.consent_text,
      grantedAt: row.granted_at,
      revokedAt: row.revoked_at,
    };
  }
}
