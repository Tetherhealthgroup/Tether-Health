import {
  BadGatewayException,
  BadRequestException,
  Injectable,
  Logger,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import type { PostgrestError } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { DatabaseErrorCode } from "../common/database-errors";
import {
  CONSENT_COLUMNS,
  liveCore,
  toConsent,
  type ConsentRow,
  type RpcResult,
} from "./consent-rows";
import { explainNotLive, isFor, supersedeCore } from "./consent-supersession";
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

interface ConsentDocumentRow {
  purpose: string;
  version: string;
  locale: string;
}

const ENROLMENT_COLUMNS =
  "id,user_id,programme_code,status,mode,joined_at,left_at,created_at,updated_at";
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
  enrolmentNotFound: ENROLMENT_NOT_FOUND,
} = DatabaseErrorCode;

/**
 * Raised by public.delete_enrolment_now() when the sign-in behind the token
 * is not recent (registry hint recent_authentication_required).
 */
const RECENT_AUTHENTICATION_REQUIRED = "TH017";

const SQLSTATE = /^[0-9A-Z]{5}$/;

/** The value logged as `code=`: a SQLSTATE, or "none". */
const loggedCode = (code: string | undefined): string =>
  code && SQLSTATE.test(code) ? code : "none";

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
  private readonly logger = new Logger(EnrolmentsService.name);

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
    // Every change, not only a rejoin: the update policy refuses them all
    // once account deletion has started.
    await this.requireDeletionBarrierOpen(client);
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
   *
   * Everything the response needs besides the two rows is read before the
   * call, so once the swap has committed nothing can turn it into an error.
   * The consents read beforehand are still the consents afterwards: the swap
   * changes status between states that are not `left`, and no trigger
   * touches consents on such a change (only leaving revokes them).
   */
  async swapFocus(
    user: AuthUser,
    dto: SwapFocusDto,
  ): Promise<FocusSwapResponse> {
    const client = this.clients.forUser(user);
    // The swap updates both rows as the caller, which the update policy
    // refuses once account deletion has started.
    await this.requireDeletionBarrierOpen(client);
    // Postgres returns UUIDs in lower case; compare in the same form.
    const demoteId = dto.demoteId.toLowerCase();
    const promoteId = dto.promoteId.toLowerCase();
    const versions = await this.currentCoreVersions(client);
    const consents = await this.consentsFor(client, [demoteId, promoteId]);
    const context = await this.versionContext(client, user, versions, consents);
    const { data, error } = (await client
      .rpc("swap_focus", { p_demote: demoteId, p_promote: promoteId })
      .select(ENROLMENT_COLUMNS)) as RpcResult<EnrolmentRow[]>;
    if (error || data === null) {
      throw (
        registryErrorFor(error?.code) ??
        new BadGatewayException("Focus could not be swapped")
      );
    }
    // Only a result that contradicts the function's contract (both rows,
    // demoted first) can fail here; no read follows the commit.
    const demoted = data.find((row) => row.id.toLowerCase() === demoteId);
    const promoted = data.find((row) => row.id.toLowerCase() === promoteId);
    if (data.length !== 2 || !demoted || !promoted) {
      throw new BadGatewayException("Focus could not be swapped");
    }
    const of = (row: EnrolmentRow) =>
      this.toEnrolment(
        row,
        consents.filter((consent) => consent.enrolment_id === row.id),
        context,
      );
    return { demoted: of(demoted), promoted: of(promoted) };
  }

  /**
   * "Delete now": removes the enrolment and that programme's data
   * (public.delete_enrolment_now). Needs an explicit confirmation and a
   * recent sign-in, like account deletion; both are checked here first, and
   * the database checks them again. `requestId` is the only identifier
   * logged.
   */
  async deleteNow(
    user: AuthUser,
    id: string,
    confirmation: unknown,
    requestId: string,
  ): Promise<void> {
    if (confirmation !== "DELETE") throw badRequest("confirmation_required");
    this.requireRecentAuthentication(user);
    const error = await this.deleteEnrolmentNow(this.clients.forUser(user), id);
    if (error) {
      // No such enrolment for the caller, including another member's.
      if (error.code === ENROLMENT_NOT_FOUND) {
        throw notFound("enrolment_not_found");
      }
      if (error.code === RECENT_AUTHENTICATION_REQUIRED) {
        throw unauthorized("recent_authentication_required");
      }
      this.logger.error(
        `enrolment_deletion_failed requestId=${requestId} status=enrolment_delete_failed code=${loggedCode(error.code)}`,
      );
      throw new BadGatewayException("Enrolment could not be deleted");
    }
    this.logger.log(
      `enrolment_deleted requestId=${requestId} status=completed`,
    );
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
      const live = await liveCore(client, enrolment.id);
      if (live !== null) {
        if (isFor(live, dto)) throw conflict("consent_already_granted");
        return supersedeCore(client, enrolment.id, dto);
      }
    } else if ((await liveCore(client, enrolment.id)) === null) {
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
      // The insert policy refused the row. One of its checks is the deletion
      // barrier; it is told apart from the others (enrolment left, no live
      // core) by asking the barrier itself, never by the message. The
      // barrier only ever closes, so a barrier refusal always reads as
      // closed here.
      if (error.code === INSUFFICIENT_PRIVILEGE) {
        throw (await this.deletionBarrierOpen(
          client,
          "Consent could not be recorded",
        ))
          ? conflict("consent_not_permitted")
          : conflict("account_deletion_in_progress");
      }
      if (error.code === CHECK_VIOLATION) {
        throw new BadRequestException("Consent rejected");
      }
      throw (
        registryErrorFor(error.code) ??
        new BadGatewayException("Consent could not be recorded")
      );
    }
    return { ...toConsent(data), supersededId: null };
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
        return explainNotLive(client, id);
      }
      throw new BadGatewayException("Consent could not be revoked");
    }
    if (data) return toConsent(data);
    return explainNotLive(client, id);
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
   * The single call behind "Delete now", as the caller. Members cannot
   * delete enrolments directly; the function checks ownership, the
   * confirmation and the sign-in itself, and returns counts only, which the
   * API does not use. Returns the call's error, or null once it has deleted.
   */
  private async deleteEnrolmentNow(
    client: UserSupabaseClient,
    id: string,
  ): Promise<PostgrestError | null> {
    const { error } = await client.rpc("delete_enrolment_now", {
      p_enrolment_id: id,
      p_confirmation: "DELETE",
    });
    return error;
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

  // Enrolment changes (status, mode, focus swap) are refused once account
  // deletion has started.
  private async requireDeletionBarrierOpen(
    client: UserSupabaseClient,
  ): Promise<void> {
    if (
      !(await this.deletionBarrierOpen(
        client,
        "Enrolment could not be updated",
      ))
    ) {
      throw conflict("account_deletion_in_progress");
    }
  }

  /**
   * public.deletion_barrier_open() as the caller: false once account
   * deletion has started or the profile is gone. A failed call is a 502
   * with `failure` as its (never sent) message.
   */
  private async deletionBarrierOpen(
    client: UserSupabaseClient,
    failure: string,
  ): Promise<boolean> {
    const { data, error } = (await client.rpc("deletion_barrier_open")) as {
      data: unknown;
      error: PostgrestError | null;
    };
    if (error) throw new BadGatewayException(failure);
    return data === true;
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
    const liveCoreRow = consents.find(
      (consent) => consent.purpose === "core" && consent.revoked_at === null,
    );
    // The locale re-consent would be in: the consent's own, or for a
    // consent stored before documents existed, the member's profile locale.
    const locale = liveCoreRow ? (liveCoreRow.locale ?? memberLocale) : null;
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
      consents: consents.map((consent) => toConsent(consent)),
      currentCoreConsentVersion: current,
      // Only when the member can complete it: a current core document exists
      // for that locale, and the consent is not on it (a consent stored
      // before documents existed is never on a document).
      reconsentRequired:
        row.status !== "left" &&
        liveCoreRow !== undefined &&
        current !== null &&
        (liveCoreRow.locale === null ||
          liveCoreRow.consent_version !== current),
    };
  }
}
