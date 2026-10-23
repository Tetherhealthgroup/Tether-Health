import { Injectable, Logger } from "@nestjs/common";
import type { PostgrestError } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { DatabaseErrorCode } from "../common/database-errors";
import { normalisePhone } from "../common/phone";
import {
  UserSupabaseClientFactory,
  type UserSupabaseClient,
} from "../enrolments/user-supabase-client";
import { careError, careUnavailable } from "./care-errors";
import {
  SNAPSHOT_MAX_BYTES,
  caregiverScopes,
  type CareConnectionResponse,
  type CareMessageResponse,
  type CareShareResponse,
  type CaregiverResponse,
  type CaregiverScope,
  type CreateCaregiverDto,
  type CreateMessageDto,
  type CreateSummaryDto,
  type CreateSupporterDto,
  type RedeemInviteDto,
  type SupporterProgramme,
  type SupporterResponse,
} from "./care.dto";

/** The routes as logged: templates only. */
export const CARE_ROUTES = {
  connections: "/v1/care/connections",
  connection: "/v1/care/connections/:id",
  summaries: "/v1/care/summaries",
  messages: "/v1/care/messages",
  supporters: "/v1/care/supporters",
  supporter: "/v1/care/supporters/:id",
  caregivers: "/v1/care/caregivers",
  caregiver: "/v1/care/caregivers/:id",
} as const;

const {
  checkViolation: CHECK_VIOLATION,
  foreignKeyViolation: FOREIGN_KEY_VIOLATION,
  insufficientPrivilege: INSUFFICIENT_PRIVILEGE,
  deletionInProgress: DELETION_IN_PROGRESS,
  careConsentRequired: CARE_CONSENT_REQUIRED,
  careInviteInvalid: CARE_INVITE_INVALID,
} = DatabaseErrorCode;

interface ConnectionRow {
  id: string;
  org_id: string;
  connected_at: string;
  revoked_at: string | null;
}
interface ShareRow {
  id: string;
  enrolment_id: string;
  connection_id: string;
  kind: "visit_summary" | "message_attachment";
  created_at: string;
  expires_at: string;
}
interface MessageRow {
  id: string;
  connection_id: string;
  enrolment_id: string | null;
  share_id: string | null;
  created_at: string;
}
interface SupporterRow {
  id: string;
  name: string;
  phone: string;
  programme_codes: SupporterProgramme[];
  help_phrase: string | null;
  created_at: string;
  updated_at: string;
}
interface CaregiverRow {
  id: string;
  name: string;
  phone: string;
  scope: CaregiverScope[];
  invite_status: "pending" | "sent";
  created_at: string;
  revoked_at: string | null;
}
interface EnrolmentRef {
  id: string;
  programme_code: string;
  status: string;
}

const CONNECTION_COLUMNS = "id,org_id,connected_at,revoked_at";
const SHARE_COLUMNS =
  "id,enrolment_id,connection_id,kind,created_at,expires_at";
const MESSAGE_COLUMNS = "id,connection_id,enrolment_id,share_id,created_at";
const SUPPORTER_COLUMNS =
  "id,name,phone,programme_codes,help_phrase,created_at,updated_at";
const CAREGIVER_COLUMNS =
  "id,name,phone,scope,invite_status,created_at,revoked_at";

/**
 * The member's side of the care team: clinic connections (redeemed invite
 * codes), shared summaries, one-way messages, supporters and Stride
 * caregivers. Every query runs as the caller (anon key + the caller's JWT),
 * so row-level security decides what exists; rows are also filtered on the
 * caller's id. Rows the caller cannot see are not found, never forbidden.
 * Nothing is sent to a clinic, caregiver or supporter from here: the server
 * stores what the member chose to share.
 */
@Injectable()
export class CareService {
  private readonly logger = new Logger(CareService.name);

  constructor(private readonly clients: UserSupabaseClientFactory) {}

  // ---- connections ---------------------------------------------------------

  /**
   * Redeems a clinic invite code (public.redeem_care_invite). Every invalid
   * code — malformed, unknown, expired, used up, or a clinic that is not
   * verified or is disabled — gets the same `care_invite_invalid`. A member
   * already connected to that clinic gets the live connection back.
   */
  async redeem(
    user: AuthUser,
    dto: RedeemInviteDto,
    requestId: string,
  ): Promise<CareConnectionResponse> {
    const client = this.clients.forUser(user);
    const { data, error } = (await client.rpc("redeem_care_invite", {
      p_code: dto.inviteCode,
    })) as { data: ConnectionRow | null; error: PostgrestError | null };
    if (error) {
      if (error.code === CARE_INVITE_INVALID) {
        throw careError("care_invite_invalid");
      }
      if (error.code === DELETION_IN_PROGRESS) {
        throw careError("account_deletion_in_progress");
      }
      return careUnavailable(
        this.logger,
        requestId,
        CARE_ROUTES.connections,
        error.code,
      );
    }
    if (data === null || typeof data.id !== "string") {
      return careUnavailable(
        this.logger,
        requestId,
        CARE_ROUTES.connections,
        undefined,
      );
    }
    const names = await this.clinicNames(client, [data.org_id], requestId);
    return toConnection(data, names);
  }

  async listConnections(
    user: AuthUser,
    requestId: string,
  ): Promise<{ connections: CareConnectionResponse[] }> {
    const client = this.clients.forUser(user);
    const { data, error } = await client
      .from("care_connections")
      .select(CONNECTION_COLUMNS)
      .eq("user_id", user.id)
      .order("connected_at", { ascending: true })
      .returns<ConnectionRow[]>();
    if (error) {
      return careUnavailable(
        this.logger,
        requestId,
        CARE_ROUTES.connections,
        error.code,
      );
    }
    const names = await this.clinicNames(
      client,
      [...new Set(data.map((row) => row.org_id))],
      requestId,
    );
    return { connections: data.map((row) => toConnection(row, names)) };
  }

  /**
   * Revokes a live connection. The database also revokes the consents that
   * name it and its shares.
   */
  async revokeConnection(
    user: AuthUser,
    id: string,
    requestId: string,
  ): Promise<CareConnectionResponse> {
    const client = this.clients.forUser(user);
    // The database sets the actual revocation time.
    const { data, error } = await client
      .from("care_connections")
      .update({ revoked_at: new Date().toISOString() })
      .eq("id", id)
      .eq("user_id", user.id)
      .is("revoked_at", null)
      .select(CONNECTION_COLUMNS)
      .maybeSingle<ConnectionRow>();
    if (error) {
      return careUnavailable(
        this.logger,
        requestId,
        CARE_ROUTES.connection,
        error.code,
      );
    }
    if (!data) throw careError("connection_not_found");
    const names = await this.clinicNames(client, [data.org_id], requestId);
    return toConnection(data, names);
  }

  // ---- summaries --------------------------------------------------------------

  /**
   * Stores the summary exactly as the member previewed it, for one clinic
   * connection, under the programme's live care-team consent naming that
   * connection. Nothing is recomputed or sent.
   */
  async createSummary(
    user: AuthUser,
    dto: CreateSummaryDto,
    requestId: string,
  ): Promise<CareShareResponse> {
    requireSnapshotSize(dto.snapshot);
    const route = CARE_ROUTES.summaries;
    const client = this.clients.forUser(user);
    await this.requireBarrierOpen(client, requestId, route);
    const enrolment = await this.liveEnrolment(
      client,
      user,
      dto.programmeCode,
      requestId,
      route,
    );
    const { connectionId, consentId } = await this.sharingConsent(
      client,
      user,
      enrolment.id,
      dto.connectionId,
      requestId,
      route,
    );
    const share = await this.insertShare(
      client,
      user,
      enrolment.id,
      connectionId,
      consentId,
      "visit_summary",
      dto.snapshot,
      requestId,
      route,
    );
    return toShare(share, enrolment.programme_code);
  }

  // ---- messages ----------------------------------------------------------------

  /**
   * A one-way message to a connected clinic, optionally about one programme
   * and with a summary the member previewed attached. A message about a
   * programme needs that programme's live care-team consent for the
   * connection, like a summary.
   */
  async createMessage(
    user: AuthUser,
    dto: CreateMessageDto,
    requestId: string,
  ): Promise<CareMessageResponse> {
    const route = CARE_ROUTES.messages;
    const topic = dto.topic.trim();
    const body = dto.message.trim();
    if (topic.length === 0 || body.length === 0) {
      throw careError("invalid_request");
    }
    if (dto.attachment !== undefined) {
      if (dto.programmeCode === undefined) throw careError("invalid_request");
      requireSnapshotSize(dto.attachment.snapshot);
    }
    const client = this.clients.forUser(user);
    await this.requireBarrierOpen(client, requestId, route);
    const connectionId = await this.messageConnection(
      client,
      user,
      dto.connectionId,
      requestId,
      route,
    );
    let enrolment: EnrolmentRef | null = null;
    let consentId: string | null = null;
    if (dto.programmeCode !== undefined) {
      enrolment = await this.liveEnrolment(
        client,
        user,
        dto.programmeCode,
        requestId,
        route,
      );
      consentId = (
        await this.sharingConsent(
          client,
          user,
          enrolment.id,
          connectionId,
          requestId,
          route,
        )
      ).consentId;
    }
    let share: ShareRow | null = null;
    if (dto.attachment !== undefined && enrolment && consentId) {
      share = await this.insertShare(
        client,
        user,
        enrolment.id,
        connectionId,
        consentId,
        "message_attachment",
        dto.attachment.snapshot,
        requestId,
        route,
      );
    }
    const { data, error } = await client
      .from("care_messages")
      .insert({
        user_id: user.id,
        connection_id: connectionId,
        enrolment_id: enrolment?.id ?? null,
        topic,
        body,
        share_id: share?.id ?? null,
      })
      .select(MESSAGE_COLUMNS)
      .single<MessageRow>();
    if (error) {
      // The attachment is only meaningful with its message: withdraw it.
      if (share) await this.withdrawShare(client, user, share.id);
      throw await this.insertRefusal(client, error, requestId, route, () =>
        careError(enrolment ? "care_consent_required" : "connection_not_found"),
      );
    }
    return {
      id: data.id,
      connectionId: data.connection_id,
      programmeCode: enrolment?.programme_code ?? null,
      shareId: data.share_id,
      createdAt: data.created_at,
      delivery: "stored",
    };
  }

  // ---- supporters -----------------------------------------------------------------

  async createSupporter(
    user: AuthUser,
    dto: CreateSupporterDto,
    requestId: string,
  ): Promise<SupporterResponse> {
    const route = CARE_ROUTES.supporters;
    const name = dto.name.trim();
    const phone = normalisePhone(dto.phone);
    const helpPhrase =
      dto.helpPhrase === undefined ? null : dto.helpPhrase.trim();
    if (name.length === 0 || phone === null || helpPhrase === "") {
      throw careError("invalid_request");
    }
    const client = this.clients.forUser(user);
    await this.requireBarrierOpen(client, requestId, route);
    const { data: enrolments, error: readError } = await client
      .from("enrolments")
      .select("programme_code,status")
      .eq("user_id", user.id)
      .in("programme_code", [...dto.programmes])
      .returns<{ programme_code: string; status: string }[]>();
    if (readError) {
      return careUnavailable(this.logger, requestId, route, readError.code);
    }
    const allowed = enrolments
      .filter((row) => row.status !== "left")
      .map((row) => row.programme_code);
    if (dto.programmes.some((code) => !allowed.includes(code))) {
      throw careError("programme_not_enrolled");
    }
    const { data, error } = await client
      .from("supporters")
      .insert({
        user_id: user.id,
        name,
        phone,
        programme_codes: dto.programmes,
        help_phrase: helpPhrase,
      })
      .select(SUPPORTER_COLUMNS)
      .single<SupporterRow>();
    if (error) {
      throw await this.insertRefusal(client, error, requestId, route, () =>
        careError("programme_not_enrolled"),
      );
    }
    return toSupporter(data);
  }

  async listSupporters(
    user: AuthUser,
    requestId: string,
  ): Promise<{ supporters: SupporterResponse[] }> {
    const { data, error } = await this.clients
      .forUser(user)
      .from("supporters")
      .select(SUPPORTER_COLUMNS)
      .eq("user_id", user.id)
      .order("created_at", { ascending: true })
      .returns<SupporterRow[]>();
    if (error) {
      return careUnavailable(
        this.logger,
        requestId,
        CARE_ROUTES.supporters,
        error.code,
      );
    }
    return { supporters: data.map(toSupporter) };
  }

  /** Supporters are the one care record a member deletes outright. */
  async deleteSupporter(
    user: AuthUser,
    id: string,
    requestId: string,
  ): Promise<void> {
    const { data, error } = await this.clients
      .forUser(user)
      .from("supporters")
      .delete()
      .eq("id", id)
      .eq("user_id", user.id)
      .select("id")
      .returns<{ id: string }[]>();
    if (error) {
      return careUnavailable(
        this.logger,
        requestId,
        CARE_ROUTES.supporter,
        error.code,
      );
    }
    if (data.length === 0) throw careError("supporter_not_found");
  }

  // ---- caregivers ------------------------------------------------------------------

  /**
   * A caregiver on the member's Stride enrolment, who may see only the
   * event kinds in scope. The invite stays pending: the member sends it
   * from their own phone; the server contacts nobody.
   */
  async createCaregiver(
    user: AuthUser,
    dto: CreateCaregiverDto,
    requestId: string,
  ): Promise<CaregiverResponse> {
    const route = CARE_ROUTES.caregivers;
    const name = dto.name.trim();
    const phone = normalisePhone(dto.phone);
    if (name.length === 0 || phone === null) throw careError("invalid_request");
    const client = this.clients.forUser(user);
    await this.requireBarrierOpen(client, requestId, route);
    const enrolment = await this.liveEnrolment(
      client,
      user,
      "sd",
      requestId,
      route,
    );
    const { data, error } = await client
      .from("caregivers")
      .insert({
        user_id: user.id,
        enrolment_id: enrolment.id,
        name,
        phone,
        scope: dto.scope ?? [...caregiverScopes],
      })
      .select(CAREGIVER_COLUMNS)
      .single<CaregiverRow>();
    if (error) {
      throw await this.insertRefusal(client, error, requestId, route, () =>
        careError("enrolment_left"),
      );
    }
    return toCaregiver(data);
  }

  async listCaregivers(
    user: AuthUser,
    requestId: string,
  ): Promise<{ caregivers: CaregiverResponse[] }> {
    const { data, error } = await this.clients
      .forUser(user)
      .from("caregivers")
      .select(CAREGIVER_COLUMNS)
      .eq("user_id", user.id)
      .order("created_at", { ascending: true })
      .returns<CaregiverRow[]>();
    if (error) {
      return careUnavailable(
        this.logger,
        requestId,
        CARE_ROUTES.caregivers,
        error.code,
      );
    }
    return { caregivers: data.map(toCaregiver) };
  }

  /**
   * Revokes a live caregiver; the database also revokes the consent that
   * names them.
   */
  async revokeCaregiver(
    user: AuthUser,
    id: string,
    requestId: string,
  ): Promise<CaregiverResponse> {
    const { data, error } = await this.clients
      .forUser(user)
      .from("caregivers")
      .update({ revoked_at: new Date().toISOString() })
      .eq("id", id)
      .eq("user_id", user.id)
      .is("revoked_at", null)
      .select(CAREGIVER_COLUMNS)
      .maybeSingle<CaregiverRow>();
    if (error) {
      return careUnavailable(
        this.logger,
        requestId,
        CARE_ROUTES.caregiver,
        error.code,
      );
    }
    if (!data) throw careError("caregiver_not_found");
    return toCaregiver(data);
  }

  // ---- helpers -----------------------------------------------------------------------

  /** deletion_barrier_open() false → 409 `account_deletion_in_progress`. */
  private async requireBarrierOpen(
    client: UserSupabaseClient,
    requestId: string,
    route: string,
  ): Promise<void> {
    if (!(await this.barrierOpen(client, requestId, route))) {
      throw careError("account_deletion_in_progress");
    }
  }

  private async barrierOpen(
    client: UserSupabaseClient,
    requestId: string,
    route: string,
  ): Promise<boolean> {
    const { data, error } = (await client.rpc("deletion_barrier_open")) as {
      data: unknown;
      error: PostgrestError | null;
    };
    if (error)
      return careUnavailable(this.logger, requestId, route, error.code);
    return data === true;
  }

  /**
   * The caller's enrolment in `programmeCode`: missing → 404
   * `enrolment_not_found`; left → 409 `enrolment_left`.
   */
  private async liveEnrolment(
    client: UserSupabaseClient,
    user: AuthUser,
    programmeCode: string,
    requestId: string,
    route: string,
  ): Promise<EnrolmentRef> {
    const { data, error } = await client
      .from("enrolments")
      .select("id,programme_code,status")
      .eq("user_id", user.id)
      .eq("programme_code", programmeCode)
      .maybeSingle<EnrolmentRef>();
    if (error)
      return careUnavailable(this.logger, requestId, route, error.code);
    if (!data) throw careError("enrolment_not_found");
    if (data.status === "left") throw careError("enrolment_left");
    return data;
  }

  private async liveConnections(
    client: UserSupabaseClient,
    user: AuthUser,
    requestId: string,
    route: string,
  ): Promise<string[]> {
    const { data, error } = await client
      .from("care_connections")
      .select("id")
      .eq("user_id", user.id)
      .is("revoked_at", null)
      .returns<{ id: string }[]>();
    if (error)
      return careUnavailable(this.logger, requestId, route, error.code);
    return data.map((row) => row.id.toLowerCase());
  }

  /**
   * The connection a message goes to: the one named (it must be the
   * caller's and live, else `connection_not_found`), or the caller's only
   * live connection (none or several → `connection_required`).
   */
  private async messageConnection(
    client: UserSupabaseClient,
    user: AuthUser,
    named: string | undefined,
    requestId: string,
    route: string,
  ): Promise<string> {
    const live = await this.liveConnections(client, user, requestId, route);
    if (named !== undefined) {
      const id = named.toLowerCase();
      if (!live.includes(id)) throw careError("connection_not_found");
      return id;
    }
    const [only, ...others] = live;
    if (only === undefined || others.length > 0) {
      throw careError("connection_required");
    }
    return only;
  }

  /**
   * The live share_care_team consent on this enrolment that names the
   * connection. With a connection named, it must be the caller's and live
   * (`connection_not_found`), and the consent must exist
   * (`care_consent_required`). With none named, the one live connection
   * that holds such a consent is used: none → `care_consent_required`,
   * several → `connection_required`.
   */
  private async sharingConsent(
    client: UserSupabaseClient,
    user: AuthUser,
    enrolmentId: string,
    named: string | undefined,
    requestId: string,
    route: string,
  ): Promise<{ connectionId: string; consentId: string }> {
    const live = await this.liveConnections(client, user, requestId, route);
    if (named !== undefined && !live.includes(named.toLowerCase())) {
      throw careError("connection_not_found");
    }
    const { data, error } = await client
      .from("programme_consents")
      .select("id,recipient_ref")
      .eq("enrolment_id", enrolmentId)
      .eq("purpose", "share_care_team")
      .is("revoked_at", null)
      .returns<{ id: string; recipient_ref: string | null }[]>();
    if (error)
      return careUnavailable(this.logger, requestId, route, error.code);
    const usable = data.filter(
      (row) =>
        row.recipient_ref !== null &&
        live.includes(row.recipient_ref) &&
        (named === undefined || row.recipient_ref === named.toLowerCase()),
    );
    const [only, ...others] = usable;
    if (only === undefined) throw careError("care_consent_required");
    if (others.length > 0) throw careError("connection_required");
    return { connectionId: only.recipient_ref as string, consentId: only.id };
  }

  private async insertShare(
    client: UserSupabaseClient,
    user: AuthUser,
    enrolmentId: string,
    connectionId: string,
    consentId: string,
    kind: "visit_summary" | "message_attachment",
    snapshot: Record<string, unknown>,
    requestId: string,
    route: string,
  ): Promise<ShareRow> {
    const { data, error } = await client
      .from("care_shares")
      .insert({
        user_id: user.id,
        enrolment_id: enrolmentId,
        connection_id: connectionId,
        consent_id: consentId,
        kind,
        snapshot,
      })
      .select(SHARE_COLUMNS)
      .single<ShareRow>();
    if (error) {
      throw await this.insertRefusal(client, error, requestId, route, () =>
        careError("care_consent_required"),
      );
    }
    return data;
  }

  /** Best effort: a failure here leaves a share that expires on its own. */
  private async withdrawShare(
    client: UserSupabaseClient,
    user: AuthUser,
    shareId: string,
  ): Promise<void> {
    await client
      .from("care_shares")
      .update({ revoked_at: new Date().toISOString() })
      .eq("id", shareId)
      .eq("user_id", user.id)
      .is("revoked_at", null);
  }

  /**
   * The client error for a refused care insert, matched by code only. A
   * row-level security refusal (42501) is told apart by asking the deletion
   * barrier, never by the message: closed → `account_deletion_in_progress`;
   * open → `policyRefusal()` (a race with a revocation or leaving), or a
   * 502 when the caller cannot cause one. TH022 is a consent revoked
   * meanwhile; a check violation is input the API's own checks let through;
   * a foreign-key violation is an enrolment deleted meanwhile. Anything else
   * (TH010 included) fails closed as a 502.
   */
  private async insertRefusal(
    client: UserSupabaseClient,
    error: PostgrestError,
    requestId: string,
    route: string,
    policyRefusal: () => Error | null,
  ): Promise<Error> {
    switch (error.code) {
      case CARE_CONSENT_REQUIRED:
        return careError("care_consent_required");
      case CHECK_VIOLATION:
        return careError("invalid_request");
      case FOREIGN_KEY_VIOLATION:
        return careError("enrolment_not_found");
      case INSUFFICIENT_PRIVILEGE: {
        if (!(await this.barrierOpen(client, requestId, route))) {
          return careError("account_deletion_in_progress");
        }
        const refusal = policyRefusal();
        if (refusal) return refusal;
        break;
      }
    }
    return careUnavailable(this.logger, requestId, route, error.code);
  }

  /** Clinic names by id, for the connections the caller can see. */
  private async clinicNames(
    client: UserSupabaseClient,
    orgIds: string[],
    requestId: string,
  ): Promise<Map<string, string>> {
    if (orgIds.length === 0) return new Map();
    const { data, error } = await client
      .from("care_orgs")
      .select("id,name")
      .in("id", orgIds)
      .returns<{ id: string; name: string }[]>();
    if (error) {
      return careUnavailable(
        this.logger,
        requestId,
        CARE_ROUTES.connections,
        error.code,
      );
    }
    return new Map(data.map((row) => [row.id, row.name]));
  }
}

/** A snapshot over SNAPSHOT_MAX_BYTES of JSON is refused before any read. */
function requireSnapshotSize(snapshot: Record<string, unknown>): void {
  if (
    Buffer.byteLength(JSON.stringify(snapshot), "utf8") > SNAPSHOT_MAX_BYTES
  ) {
    throw careError("invalid_request");
  }
}

function toConnection(
  row: ConnectionRow,
  names: Map<string, string>,
): CareConnectionResponse {
  return {
    id: row.id,
    clinicId: row.org_id,
    clinicName: names.get(row.org_id) ?? null,
    connectedAt: row.connected_at,
    revokedAt: row.revoked_at,
  };
}

function toShare(row: ShareRow, programmeCode: string): CareShareResponse {
  return {
    id: row.id,
    programmeCode,
    connectionId: row.connection_id,
    kind: row.kind,
    createdAt: row.created_at,
    expiresAt: row.expires_at,
    delivery: "stored",
  };
}

function toSupporter(row: SupporterRow): SupporterResponse {
  return {
    id: row.id,
    name: row.name,
    phone: row.phone,
    programmes: row.programme_codes,
    helpPhrase: row.help_phrase,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function toCaregiver(row: CaregiverRow): CaregiverResponse {
  return {
    id: row.id,
    programmeCode: "sd",
    name: row.name,
    phone: row.phone,
    scope: row.scope,
    inviteStatus: row.invite_status,
    createdAt: row.created_at,
    revokedAt: row.revoked_at,
  };
}
