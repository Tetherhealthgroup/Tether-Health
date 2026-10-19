import {
  BadGatewayException,
  BadRequestException,
  Injectable,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import type { PostgrestError } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { DatabaseErrorCode } from "../common/database-errors";
import {
  badRequest,
  conflict,
  notFound,
  registryErrorFor,
  unauthorized,
} from "./enrolment-errors";
import {
  consentLocales,
  modeProgrammeCodes,
  sharePurposes,
  type ConsentLocale,
  type ConsentPurpose,
  type ConsentResponse,
  type CoreConsentVersions,
  type CreateEnrolmentDto,
  type EnrolmentListResponse,
  type EnrolmentMode,
  type EnrolmentResponse,
  type EnrolmentStatus,
  type FocusSwapResponse,
  type GrantConsentDto,
  type GrantConsentResponse,
  type SwapFocusDto,
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
  /** Null only on rows stored before consent documents existed. */
  locale: ConsentLocale | null;
  consent_text: string;
  granted_at: string;
  revoked_at: string | null;
  /** Set on a core consent replaced through supersede_core_consent. */
  superseded_by: string | null;
}

interface ConsentDocumentRow {
  purpose: string;
  version: string;
  locale: string;
}

/** The untyped client's result of a set-returning function call. */
interface RpcResult<T> {
  data: T | null;
  error: PostgrestError | null;
}

const ENROLMENT_COLUMNS =
  "id,user_id,programme_code,status,mode,joined_at,left_at,created_at,updated_at";
const CONSENT_COLUMNS =
  "id,enrolment_id,purpose,recipient_ref,consent_version,locale,consent_text,granted_at,revoked_at,superseded_by";
/** For an enrolment answered without consents (no version is needed). */
const NO_CURRENT_VERSIONS: CoreConsentVersions = { en: null, es: null };

/** What deciding the current core version of an enrolment needs. */
interface VersionContext {
  versions: CoreConsentVersions;
  /**
   * The member's profile locale, read only when a live core consent has no
   * locale (stored before consent documents existed); otherwise null.
   */
  memberLocale: ConsentLocale | null;
}

// Database errors are told apart by SQLSTATE code only, never by message.
const {
  uniqueViolation: UNIQUE_VIOLATION,
  foreignKeyViolation: FOREIGN_KEY_VIOLATION,
  checkViolation: CHECK_VIOLATION,
  insufficientPrivilege: INSUFFICIENT_PRIVILEGE,
  // Raised by public.enrolments_focus_cap(), deferred, so it surfaces at commit.
  focusCapReached: FOCUS_CAP_REACHED,
  // Raised by public.consent_revoke_only() on programme_consents updates,
  // including the revocations that leaving an enrolment cascades into.
  consentAlreadyRevoked: CONSENT_ALREADY_REVOKED,
  consentImmutable: CONSENT_IMMUTABLE,
  // Raised by public.supersede_core_consent() when the enrolment has no live
  // core consent, including when a concurrent supersession or revocation
  // replaced it while this call waited for its row lock.
  consentRequiresCore: CONSENT_REQUIRES_CORE,
} = DatabaseErrorCode;

/**
 * The consent revoke-only rules (one trigger, two registry codes), as they
 * reach an enrolment update through the revocations leaving cascades into.
 */
const isConsentRevokeOnly = (error: PostgrestError) =>
  error.code === CONSENT_ALREADY_REVOKED || error.code === CONSENT_IMMUTABLE;

/**
 * Enrolments and per-programme consents. Every query runs as the caller
 * (anon key + the caller's JWT), so row-level security decides what exists;
 * enrolment queries also filter on the caller's id as a second guard. Rows
 * the caller cannot see are reported as not found, never as forbidden.
 */
@Injectable()
export class EnrolmentsService {
  constructor(
    private readonly clients: UserSupabaseClientFactory,
    private readonly config: ConfigService,
  ) {}

  async list(user: AuthUser): Promise<EnrolmentListResponse> {
    const client = this.clients.forUser(user);
    const versions = await this.currentCoreVersions(client);
    const { data, error, count } = await client
      .from("enrolments")
      .select(ENROLMENT_COLUMNS, { count: "exact" })
      .eq("user_id", user.id)
      .order("created_at", { ascending: true })
      .returns<EnrolmentRow[]>();
    if (error) throw new BadGatewayException("Enrolments are unavailable");
    this.requireComplete(data.length, count);
    const consents = await this.consentsFor(
      client,
      data.map((row) => row.id),
    );
    const context = await this.versionContext(client, user, versions, consents);
    return {
      currentCoreConsentVersions: versions,
      enrolments: data.map((row) =>
        this.toEnrolment(
          row,
          consents.filter((consent) => consent.enrolment_id === row.id),
          context,
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
      if (error.code === FOCUS_CAP_REACHED) throw conflict("focus_cap_reached");
      // The insert policy pins user_id to the caller, so a refusal here is
      // the deletion barrier.
      if (error.code === INSUFFICIENT_PRIVILEGE) {
        throw conflict("account_deletion_in_progress");
      }
      throw new BadGatewayException("Enrolment could not be created");
    }
    return this.toEnrolment(data, [], {
      versions: NO_CURRENT_VERSIONS,
      memberLocale: null,
    });
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
    // Read before the write, so that failing here changes nothing.
    const versions = await this.currentCoreVersions(client);

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
      if (error.code === FOCUS_CAP_REACHED) throw conflict("focus_cap_reached");
      // A check constraint on enrolments, or a consent rule refusing the
      // revocations that leaving cascades into: the change conflicts with the
      // row's current state.
      if (error.code === CHECK_VIOLATION || isConsentRevokeOnly(error)) {
        throw conflict("enrolment_conflict");
      }
      throw new BadGatewayException("Enrolment could not be updated");
    }
    if (!data) throw notFound("enrolment_not_found");
    const consents = await this.consentsFor(client, [data.id]);
    return this.toEnrolment(
      data,
      consents,
      await this.versionContext(client, user, versions, consents),
    );
  }

  /**
   * Moves one enrolment out of focus (to paused, its data kept) and another
   * into focus in one database transaction (public.swap_focus). The focus
   * cap is checked inside the call, so TH001 arrives as the call's error.
   */
  async swapFocus(
    user: AuthUser,
    dto: SwapFocusDto,
  ): Promise<FocusSwapResponse> {
    const client = this.clients.forUser(user);
    const versions = await this.currentCoreVersions(client);
    const { data, error } = (await client
      .rpc("swap_focus", { p_demote: dto.demoteId, p_promote: dto.promoteId })
      .select(ENROLMENT_COLUMNS)) as RpcResult<EnrolmentRow[]>;
    if (error || data === null) {
      throw (
        registryErrorFor(error?.code) ??
        new BadGatewayException("Focus could not be swapped")
      );
    }
    const demoted = data.find((row) => row.id === dto.demoteId);
    const promoted = data.find((row) => row.id === dto.promoteId);
    if (data.length !== 2 || !demoted || !promoted) {
      throw new BadGatewayException("Focus could not be swapped");
    }
    const consents = await this.consentsFor(client, [demoted.id, promoted.id]);
    const context = await this.versionContext(client, user, versions, consents);
    const of = (row: EnrolmentRow) =>
      this.toEnrolment(
        row,
        consents.filter((consent) => consent.enrolment_id === row.id),
        context,
      );
    return { demoted: of(demoted), promoted: of(promoted) };
  }

  /**
   * "Delete now": removes the enrolment and every row that references it with
   * on delete cascade (today its programme consents). Needs an explicit
   * confirmation and a recent sign-in, like account deletion.
   */
  async deleteNow(
    user: AuthUser,
    id: string,
    confirmation: unknown,
  ): Promise<void> {
    if (confirmation !== "DELETE") throw badRequest("confirmation_required");
    this.requireRecentAuthentication(user);
    const deleted = await this.deleteEnrolmentNow(
      this.clients.forUser(user),
      user,
      id,
    );
    if (!deleted) throw notFound("enrolment_not_found");
  }

  /**
   * Records a consent for the document version and locale the app showed;
   * the database fills in the text. A core grant on an enrolment whose live
   * core consent is for another version or locale supersedes it
   * (public.supersede_core_consent); it is never a revoke and a new insert.
   */
  async grantConsent(
    user: AuthUser,
    dto: GrantConsentDto,
  ): Promise<GrantConsentResponse> {
    // Sharing needs a validated care connection or caregiver as recipient;
    // until those exist, share purposes are not accepted.
    if (sharePurposes.includes(dto.purpose)) {
      throw conflict("sharing_not_available");
    }
    if (dto.recipientRef !== undefined) {
      throw new BadRequestException("recipientRef does not match purpose");
    }
    const client = this.clients.forUser(user);
    const enrolment = await this.ownEnrolment(client, user, dto.enrolmentId);
    if (enrolment.status === "left") throw conflict("enrolment_left");
    if (dto.purpose === "core") {
      const live = await this.liveCore(client, enrolment.id);
      if (live !== null) {
        if (this.isFor(live, dto)) throw conflict("consent_already_granted");
        return this.supersedeCore(client, enrolment.id, dto, true);
      }
    } else if ((await this.liveCore(client, enrolment.id)) === null) {
      throw conflict("core_consent_required");
    }
    // A plain insert, never an upsert: the one-live-row keys make a second
    // live grant of the same purpose and recipient fail, and it is reported
    // as such. consent_text is never sent: the database copies it from the
    // document (TH011 when there is no grantable document).
    const { data, error } = await client
      .from("programme_consents")
      .insert({
        enrolment_id: enrolment.id,
        purpose: dto.purpose,
        recipient_ref: null,
        consent_version: dto.consentVersion,
        locale: dto.locale,
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
      throw (
        registryErrorFor(error.code) ??
        new BadGatewayException("Consent could not be recorded")
      );
    }
    return { ...this.toConsent(data), supersededId: null };
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
      // Already revoked: a concurrent revocation or supersession got there
      // first. TH003 (not a pure revocation) leaves the consent live, so it
      // is never reported as revoked; it fails closed like any other error.
      if (error.code === CONSENT_ALREADY_REVOKED) {
        return this.explainNotLive(client, id);
      }
      throw new BadGatewayException("Consent could not be revoked");
    }
    if (data) return this.toConsent(data);
    return this.explainNotLive(client, id);
  }

  /**
   * Why a consent could not be revoked: it is not visible (not found), it
   * was superseded by a core consent that is still live (consent_superseded:
   * the member's consent is live under the newer row, so "already revoked"
   * would be wrong), or it is revoked.
   */
  private async explainNotLive(
    client: UserSupabaseClient,
    id: string,
  ): Promise<never> {
    const existing = await client
      .from("programme_consents")
      .select("id,enrolment_id,revoked_at,superseded_by")
      .eq("id", id)
      .maybeSingle<
        Pick<ConsentRow, "id" | "enrolment_id" | "revoked_at" | "superseded_by">
      >();
    if (existing.error) {
      throw new BadGatewayException("Consent could not be revoked");
    }
    if (!existing.data) throw notFound("consent_not_found");
    if (
      existing.data.superseded_by !== null &&
      (await this.liveCore(client, existing.data.enrolment_id)) !== null
    ) {
      throw conflict("consent_superseded");
    }
    throw conflict("consent_already_revoked");
  }

  /**
   * Core re-consent: one call that inserts the new core row (text from the
   * document) and revokes the old one with superseded_by set, leaving the
   * optional consents live unless the document says otherwise.
   *
   * A second identical request racing the first (a double tap) waits for the
   * first's row lock and then finds no live core row to replace (TH004). The
   * live core is read again: if it is already the requested version and
   * locale, the request succeeded and is answered as such; if no core is
   * live, core consent is required; if another version became live, the
   * supersession is tried once more and the database decides.
   */
  private async supersedeCore(
    client: UserSupabaseClient,
    enrolmentId: string,
    dto: GrantConsentDto,
    mayRetry: boolean,
  ): Promise<GrantConsentResponse> {
    const { data, error } = (await client
      .rpc("supersede_core_consent", {
        p_enrolment: enrolmentId,
        p_version: dto.consentVersion,
        p_locale: dto.locale,
      })
      .select(CONSENT_COLUMNS)) as RpcResult<ConsentRow[]>;
    if (error) {
      if (error.code !== CONSENT_REQUIRES_CORE) {
        throw (
          registryErrorFor(error.code) ??
          new BadGatewayException("Consent could not be recorded")
        );
      }
      const live = await this.liveCore(client, enrolmentId);
      if (live === null) throw conflict("core_consent_required");
      if (this.isFor(live, dto)) {
        return {
          ...this.toConsent(live),
          supersededId: await this.supersededId(client, live.id),
        };
      }
      if (mayRetry) return this.supersedeCore(client, enrolmentId, dto, false);
      throw conflict("core_consent_required");
    }
    if (data === null) {
      throw new BadGatewayException("Consent could not be recorded");
    }
    // The function returns the old row, then the new one; identify them by
    // content rather than position.
    const replacement = data.find((row) => row.revoked_at === null);
    const superseded = data.find(
      (row) =>
        replacement !== undefined && row.superseded_by === replacement.id,
    );
    if (data.length !== 2 || !replacement || !superseded) {
      throw new BadGatewayException("Consent could not be recorded");
    }
    return { ...this.toConsent(replacement), supersededId: superseded.id };
  }

  /** The core consent that `id` replaced, if any. */
  private async supersededId(
    client: UserSupabaseClient,
    id: string,
  ): Promise<string | null> {
    const { data, error } = await client
      .from("programme_consents")
      .select("id")
      .eq("superseded_by", id)
      .maybeSingle<Pick<ConsentRow, "id">>();
    if (error) throw new BadGatewayException("Consents are unavailable");
    return data?.id ?? null;
  }

  private isFor(consent: ConsentRow, dto: GrantConsentDto): boolean {
    return (
      consent.consent_version === dto.consentVersion &&
      consent.locale === dto.locale
    );
  }

  /**
   * The current core document version per locale, from
   * public.current_consent_documents(). Never used to choose the version a
   * consent is recorded for: that is the version the app showed.
   */
  private async currentCoreVersions(
    client: UserSupabaseClient,
  ): Promise<CoreConsentVersions> {
    const { data, error } = (await client
      .rpc("current_consent_documents", {}, { get: true })
      .select("purpose,version,locale")
      .eq("purpose", "core")) as RpcResult<ConsentDocumentRow[]>;
    if (error || data === null) {
      throw new BadGatewayException("Consent documents are unavailable");
    }
    const versions: CoreConsentVersions = { ...NO_CURRENT_VERSIONS };
    for (const document of data) {
      const locale = consentLocales.find((known) => known === document.locale);
      if (document.purpose === "core" && locale !== undefined) {
        versions[locale] = document.version;
      }
    }
    return versions;
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

  /** The enrolment's live core consent (at most one exists), or null. */
  private async liveCore(
    client: UserSupabaseClient,
    enrolmentId: string,
  ): Promise<ConsentRow | null> {
    const { data, error } = await client
      .from("programme_consents")
      .select(CONSENT_COLUMNS)
      .eq("enrolment_id", enrolmentId)
      .eq("purpose", "core")
      .is("revoked_at", null)
      .maybeSingle<ConsentRow>();
    if (error) throw new BadGatewayException("Consents are unavailable");
    return data;
  }

  private async consentsFor(
    client: UserSupabaseClient,
    enrolmentIds: string[],
  ): Promise<ConsentRow[]> {
    if (enrolmentIds.length === 0) return [];
    // Live rows only: bounded by the one-live-row-per-purpose index.
    const { data, error, count } = await client
      .from("programme_consents")
      .select(CONSENT_COLUMNS, { count: "exact" })
      .in("enrolment_id", enrolmentIds)
      .is("revoked_at", null)
      .order("granted_at", { ascending: true })
      .returns<ConsentRow[]>();
    if (error) throw new BadGatewayException("Consents are unavailable");
    this.requireComplete(data.length, count);
    return data;
  }

  /** Refuses to answer with a partial list (e.g. a server row limit). */
  private requireComplete(received: number, total: number | null) {
    if (total === null || received !== total) {
      throw new BadGatewayException("Incomplete result");
    }
  }

  // Same rule as account export and deletion: the sign-in behind the token
  // must be recent (RECENT_AUTH_MAX_AGE_SECONDS).
  private requireRecentAuthentication(user: AuthUser): void {
    const maxAge = this.config.getOrThrow<number>(
      "RECENT_AUTH_MAX_AGE_SECONDS",
    );
    const age = Math.floor(Date.now() / 1000) - user.authenticatedAt;
    if (age < 0 || age > maxAge) {
      throw unauthorized("recent_authentication_required");
    }
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

  /**
   * The member's locale matters only for a live core consent stored before
   * consent documents existed (no locale): re-consent is offered in the
   * profile's locale. The profile is read only then.
   */
  private async versionContext(
    client: UserSupabaseClient,
    user: AuthUser,
    versions: CoreConsentVersions,
    consents: ConsentRow[],
  ): Promise<VersionContext> {
    const legacy = consents.some(
      (consent) =>
        consent.purpose === "core" &&
        consent.revoked_at === null &&
        consent.locale === null,
    );
    if (!legacy) return { versions, memberLocale: null };
    const { data, error } = await client
      .from("profiles")
      .select("locale")
      .eq("id", user.id)
      .maybeSingle<{ locale: string }>();
    if (error) throw new BadGatewayException("Profile data is unavailable");
    const memberLocale =
      consentLocales.find((known) => known === data?.locale) ?? null;
    return { versions, memberLocale };
  }

  private toEnrolment(
    row: EnrolmentRow,
    consents: ConsentRow[],
    { versions, memberLocale }: VersionContext,
  ): EnrolmentResponse {
    const liveCore = consents.find(
      (consent) => consent.purpose === "core" && consent.revoked_at === null,
    );
    // The locale re-consent would be in: the consent's own, or for a
    // consent stored before documents existed, the member's profile locale.
    const locale = liveCore ? (liveCore.locale ?? memberLocale) : null;
    const current = locale !== null ? versions[locale] : null;
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
      currentCoreConsentVersion: current,
      // Only when the member can complete it: a current core document exists
      // for that locale, and the consent is not on it (a consent stored
      // before documents existed is never on a document).
      reconsentRequired:
        row.status !== "left" &&
        liveCore !== undefined &&
        current !== null &&
        (liveCore.locale === null || liveCore.consent_version !== current),
    };
  }

  private toConsent(row: ConsentRow): ConsentResponse {
    return {
      id: row.id,
      enrolmentId: row.enrolment_id,
      purpose: row.purpose,
      recipientRef: row.recipient_ref,
      consentVersion: row.consent_version,
      locale: row.locale,
      consentText: row.consent_text,
      grantedAt: row.granted_at,
      revokedAt: row.revoked_at,
    };
  }
}
