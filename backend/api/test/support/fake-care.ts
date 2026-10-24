import { createHash, randomUUID } from "node:crypto";
import type { DatabaseErrorHint } from "./database-errors";

/**
 * The care tables of supabase/migrations/202610180011_care.sql for the fake
 * PostgREST (fake-postgrest.ts owns the request handling, the state and the
 * rollback). What is emulated, per table, as the member's own token sees it:
 *
 * - care_orgs: select of id and name for clinics the member is or was
 *   connected to; no write. care_invites: no client path at all.
 * - care_connections: select own; update of revoked_at only (revoke-only,
 *   TH023 on an already revoked row); created only by redeem_care_invite().
 * - care_shares: select own; insert (column grants; policy: own user_id, the
 *   member's enrolment not left, a live connection of the member,
 *   has_consent(enrolment, 'share_care_team', connection), deletion barrier;
 *   then the care_lock_live_consent trigger: the named consent must be that
 *   live consent, TH022); the snapshot and expiry checks; update of
 *   revoked_at only.
 * - care_messages: select own; insert (policy: own user_id, a live
 *   connection of the member, for a programme message the enrolment not
 *   left and has_consent for that connection, for an attachment a live,
 *   unexpired message_attachment share of the same connection and
 *   enrolment, deletion barrier); topic and body length checks; append-only.
 * - caregivers: select own; insert (policy: own user_id, the member's Stride
 *   enrolment not left, deletion barrier); name, phone and scope checks;
 *   update of invite_status (pending to sent) and revoked_at only.
 * - supporters: select own; insert and update (policy: own user_id, codes
 *   only of the member's bf and sf enrolments that are not left, deletion
 *   barrier on insert); name, phone, codes and help phrase checks; delete
 *   own (the only member delete).
 * - redeem_care_invite(p_code): in the function's order, TH006 once account
 *   deletion has started; the code normalised (spaces and hyphens removed,
 *   upper case), 12 to 64 characters, its SHA-256 matched to an invite whose
 *   clinic is verified and not disabled, else TH025; an existing live
 *   connection to that clinic returned with no use consumed; an expired or
 *   used-up invite TH025; otherwise one use consumed and a connection
 *   created. The sync session refusal (TH010) is not emulated.
 * - The consent recipient check (TH021) on a share consent insert, and the
 *   revocation cascades: a revoked share_care_team consent revokes its
 *   shares; a revoked connection revokes the consents naming it and its
 *   shares; a revoked caregiver revokes the consents naming it. They run at
 *   the end of the request (the database runs them inside the statement;
 *   the API cannot tell the difference).
 *
 * Not emulated: care_share_access and caregiver_events (no API path writes
 * them), the truncate guards, and the care rows in the account and "Delete
 * now" receipts (the API reads only its own receipt keys).
 */

type Row = Record<string, unknown>;

export const CARE_TABLES = [
  "care_orgs",
  "care_connections",
  "care_shares",
  "care_messages",
  "caregivers",
  "supporters",
] as const;
export type CareTable = (typeof CARE_TABLES)[number];

export interface CareState {
  enrolments: Row[];
  programme_consents: Row[];
  care_orgs: Row[];
  care_invites: Row[];
  care_connections: Row[];
  care_shares: Row[];
  care_messages: Row[];
  caregivers: Row[];
  supporters: Row[];
}

/** What the care tables need from the fake PostgREST. */
export interface CareContext {
  state(): CareState;
  barrierOpen(uid: string): boolean;
  hasConsent(
    uid: string,
    enrolmentId: string,
    purpose: string,
    recipient: string | null,
  ): boolean;
  now(): string;
  /** Wall-clock milliseconds of the fake's clock. */
  clockMs(): number;
  fail(status: number, code: string, message: string): never;
  raise(hint: DatabaseErrorHint, messageIndex?: number): never;
}

const INSERT_GRANTS: Record<string, string[]> = {
  care_shares: [
    "user_id",
    "enrolment_id",
    "connection_id",
    "consent_id",
    "kind",
    "snapshot",
    "expires_at",
  ],
  care_messages: [
    "user_id",
    "connection_id",
    "enrolment_id",
    "topic",
    "body",
    "share_id",
  ],
  caregivers: ["user_id", "enrolment_id", "name", "phone", "scope"],
  supporters: ["user_id", "name", "phone", "programme_codes", "help_phrase"],
};
const UPDATE_GRANTS: Record<string, string[]> = {
  care_connections: ["revoked_at"],
  care_shares: ["revoked_at"],
  caregivers: ["invite_status", "revoked_at"],
  supporters: ["name", "phone", "programme_codes", "help_phrase"],
};
const PHONE = /^\+[1-9][0-9]{6,14}$/;
const LOWER_UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const SCOPES = ["sd.session_finished", "sd.fall_logged"];
const DAY_MS = 24 * 60 * 60 * 1000;

const check = (ctx: CareContext, table: string, name: string): never =>
  ctx.fail(
    400,
    "23514",
    `new row for relation "${table}" violates check constraint "${name}"`,
  );
const rls = (ctx: CareContext, table: string): never =>
  ctx.fail(
    403,
    "42501",
    `new row violates row-level security policy for table "${table}"`,
  );
const denied = (ctx: CareContext, table: string): never =>
  ctx.fail(403, "42501", `permission denied for table ${table}`);
const trimmed = (value: unknown, min: number, max: number) =>
  typeof value === "string" &&
  value === value.trim() &&
  value.length >= min &&
  value.length <= max;
const uniqueTexts = (value: unknown): value is string[] =>
  Array.isArray(value) &&
  value.every((item) => typeof item === "string") &&
  new Set(value).size === value.length;

export class FakeCare {
  constructor(private readonly ctx: CareContext) {}

  /** Superuser seed of a clinic and an invite code for it. */
  addInvite(
    code: string,
    {
      clinicName = "Synthetic Clinic",
      verified = true,
      disabled = false,
      expiresInMs = DAY_MS,
      maxUses = 1,
    } = {},
  ): { orgId: string; inviteId: string } {
    const state = this.ctx.state();
    const existing = state.care_orgs.find((org) => org.name === clinicName);
    const orgId = (existing?.id as string | undefined) ?? randomUUID();
    if (!existing) {
      state.care_orgs.push({
        id: orgId,
        name: clinicName,
        verified_at: verified ? this.ctx.now() : null,
        disabled_at: disabled ? this.ctx.now() : null,
      });
    }
    const inviteId = randomUUID();
    state.care_invites.push({
      id: inviteId,
      org_id: orgId,
      code_hash: createHash("sha256")
        .update(code.replace(/[\s-]/g, "").toUpperCase(), "utf8")
        .digest("hex"),
      expires_at: new Date(this.ctx.clockMs() + expiresInMs).toISOString(),
      max_uses: maxUses,
      uses: 0,
    });
    return { orgId, inviteId };
  }

  visible(uid: string, table: CareTable): Row[] {
    const state = this.ctx.state();
    if (table === "care_orgs") {
      return state.care_orgs
        .filter((org) =>
          state.care_connections.some(
            (connection) =>
              connection.org_id === org.id && connection.user_id === uid,
          ),
        )
        .map((org) => ({ id: org.id, name: org.name }));
    }
    return state[table].filter((row) => row.user_id === uid);
  }

  insert(uid: string, table: CareTable, value: Row): Row {
    const granted = INSERT_GRANTS[table];
    if (
      !granted ||
      Object.keys(value).some((column) => !granted.includes(column))
    ) {
      return denied(this.ctx, table);
    }
    const state = this.ctx.state();
    const now = this.ctx.now();
    if (table === "care_shares") {
      const row: Row = {
        id: randomUUID(),
        user_id: value.user_id,
        enrolment_id: value.enrolment_id,
        connection_id: value.connection_id,
        consent_id: value.consent_id,
        kind: value.kind,
        snapshot: value.snapshot,
        created_at: now,
        expires_at:
          value.expires_at ??
          new Date(Date.parse(now) + 30 * DAY_MS).toISOString(),
        revoked_at: null,
      };
      // care_lock_live_consent (before insert) runs first.
      const consent = state.programme_consents.find(
        (c) =>
          c.id === row.consent_id &&
          c.purpose === "share_care_team" &&
          c.enrolment_id === row.enrolment_id &&
          c.recipient_ref === row.connection_id &&
          c.revoked_at === null,
      );
      if (!consent || !this.liveConnection(row.connection_id as string)) {
        this.ctx.raise("care_consent_required");
      }
      if (
        row.user_id !== uid ||
        !this.ownLiveEnrolment(uid, row.enrolment_id as string) ||
        !this.liveConnection(row.connection_id as string, uid) ||
        !this.ctx.hasConsent(
          uid,
          row.enrolment_id as string,
          "share_care_team",
          row.connection_id as string,
        ) ||
        !this.ctx.barrierOpen(uid)
      ) {
        rls(this.ctx, table);
      }
      if (!["visit_summary", "message_attachment"].includes(row.kind as string))
        check(this.ctx, table, "care_shares_kind_check");
      const snapshot = row.snapshot;
      if (
        snapshot === null ||
        typeof snapshot !== "object" ||
        Array.isArray(snapshot) ||
        // jsonb::text adds a space after every ':' and ','; JSON.stringify
        // does not, so this is a lower bound of the stored length.
        Buffer.byteLength(JSON.stringify(snapshot), "utf8") > 65536
      ) {
        check(this.ctx, table, "care_shares_snapshot_check");
      }
      state.care_shares.push(row);
      return row;
    }
    if (table === "care_messages") {
      const row: Row = {
        id: randomUUID(),
        user_id: value.user_id,
        connection_id: value.connection_id,
        enrolment_id: value.enrolment_id ?? null,
        topic: value.topic,
        body: value.body,
        share_id: value.share_id ?? null,
        created_at: now,
      };
      const share =
        row.share_id === null
          ? null
          : state.care_shares.find((s) => s.id === row.share_id);
      if (
        row.user_id !== uid ||
        !this.liveConnection(row.connection_id as string, uid) ||
        (row.enrolment_id !== null &&
          (!this.ownLiveEnrolment(uid, row.enrolment_id as string) ||
            !this.ctx.hasConsent(
              uid,
              row.enrolment_id as string,
              "share_care_team",
              row.connection_id as string,
            ))) ||
        (row.share_id !== null &&
          (!share ||
            share.user_id !== uid ||
            share.connection_id !== row.connection_id ||
            share.enrolment_id !== row.enrolment_id ||
            share.kind !== "message_attachment" ||
            share.revoked_at !== null ||
            Date.parse(share.expires_at as string) <= this.ctx.clockMs())) ||
        !this.ctx.barrierOpen(uid)
      ) {
        rls(this.ctx, table);
      }
      if (
        typeof row.topic !== "string" ||
        row.topic.length < 1 ||
        row.topic.length > 80
      )
        check(this.ctx, table, "care_messages_topic_check");
      if (
        typeof row.body !== "string" ||
        row.body.length < 1 ||
        row.body.length > 2000
      )
        check(this.ctx, table, "care_messages_body_check");
      if (row.share_id !== null && row.enrolment_id === null)
        check(this.ctx, table, "care_messages_share_enrolment_check");
      state.care_messages.push(row);
      return row;
    }
    if (table === "caregivers") {
      const row: Row = {
        id: randomUUID(),
        user_id: value.user_id,
        enrolment_id: value.enrolment_id,
        name: value.name,
        phone: value.phone,
        scope: value.scope ?? [...SCOPES],
        invite_status: "pending",
        created_at: now,
        revoked_at: null,
      };
      const enrolment = state.enrolments.find((e) => e.id === row.enrolment_id);
      if (
        row.user_id !== uid ||
        !enrolment ||
        enrolment.user_id !== uid ||
        enrolment.programme_code !== "sd" ||
        enrolment.status === "left" ||
        !this.ctx.barrierOpen(uid)
      ) {
        rls(this.ctx, table);
      }
      if (!trimmed(row.name, 1, 80))
        check(this.ctx, table, "caregivers_name_check");
      if (typeof row.phone !== "string" || !PHONE.test(row.phone))
        check(this.ctx, table, "caregivers_phone_check");
      if (
        !uniqueTexts(row.scope) ||
        row.scope.length < 1 ||
        row.scope.some((item) => !SCOPES.includes(item))
      )
        check(this.ctx, table, "caregivers_scope_check");
      state.caregivers.push(row);
      return row;
    }
    // supporters
    const row: Row = {
      id: randomUUID(),
      user_id: value.user_id,
      name: value.name,
      phone: value.phone,
      programme_codes: value.programme_codes ?? [],
      help_phrase: value.help_phrase ?? null,
      created_at: now,
      updated_at: now,
    };
    if (
      row.user_id !== uid ||
      !this.codesAllowed(uid, row.programme_codes) ||
      !this.ctx.barrierOpen(uid)
    ) {
      rls(this.ctx, table);
    }
    this.checkSupporter(row);
    state.supporters.push(row);
    return row;
  }

  update(uid: string, table: CareTable, targets: Row[], change: Row): Row[] {
    const granted = UPDATE_GRANTS[table];
    if (
      !granted ||
      Object.keys(change).some((column) => !granted.includes(column))
    ) {
      return denied(this.ctx, table);
    }
    for (const row of targets) {
      if (table === "supporters") {
        Object.assign(row, change);
        row.updated_at = this.ctx.now();
        if (row.user_id !== uid || !this.codesAllowed(uid, row.programme_codes))
          rls(this.ctx, table);
        this.checkSupporter(row);
        continue;
      }
      // care_revoke_only
      if (row.revoked_at !== null) this.ctx.raise("care_record_immutable");
      if (change.invite_status !== undefined) {
        if (
          change.invite_status !== row.invite_status &&
          !(row.invite_status === "pending" && change.invite_status === "sent")
        ) {
          this.ctx.raise("care_record_immutable");
        }
        row.invite_status = change.invite_status;
      }
      if (change.revoked_at !== undefined) {
        if (change.revoked_at === null) this.ctx.raise("care_record_immutable");
        row.revoked_at = this.ctx.now();
      }
    }
    return targets;
  }

  /** Members may delete supporters only. */
  remove(uid: string, table: CareTable, targets: Row[]): Row[] {
    if (table !== "supporters") return denied(this.ctx, table);
    const state = this.ctx.state();
    const ids = new Set(targets.map((row) => row.id));
    state.supporters = state.supporters.filter(
      (row) => !(ids.has(row.id) && row.user_id === uid),
    );
    return targets;
  }

  /** public.redeem_care_invite(p_code), as the caller. */
  redeem(uid: string, args: Row): Row {
    const state = this.ctx.state();
    if (!this.ctx.barrierOpen(uid)) this.ctx.raise("deletion_in_progress");
    const normalised = (typeof args.p_code === "string" ? args.p_code : "")
      .replace(/[\s-]/g, "")
      .toUpperCase();
    if (normalised.length < 12 || normalised.length > 64) {
      this.ctx.raise("care_invite_invalid");
    }
    const hash = createHash("sha256").update(normalised, "utf8").digest("hex");
    const invite = state.care_invites.find((i) => i.code_hash === hash);
    const clinic = invite
      ? state.care_orgs.find((org) => org.id === invite.org_id)
      : undefined;
    if (
      !invite ||
      !clinic ||
      clinic.verified_at === null ||
      clinic.disabled_at !== null
    ) {
      this.ctx.raise("care_invite_invalid");
    }
    const live = state.care_connections.find(
      (c) =>
        c.user_id === uid &&
        c.org_id === invite?.org_id &&
        c.revoked_at === null,
    );
    if (live) return live;
    if (
      Date.parse(invite?.expires_at as string) <= this.ctx.clockMs() ||
      (invite?.uses as number) >= (invite?.max_uses as number)
    ) {
      this.ctx.raise("care_invite_invalid");
    }
    if (invite) invite.uses = (invite.uses as number) + 1;
    const connectedAt = this.ctx.now();
    const row: Row = {
      id: randomUUID(),
      user_id: uid,
      org_id: invite?.org_id,
      invite_id: invite?.id,
      connected_at: connectedAt,
      revoked_at: null,
      created_at: connectedAt,
    };
    state.care_connections.push(row);
    return row;
  }

  /**
   * care_check_consent_recipient (insert trigger on programme_consents): a
   * share consent names, by its lowercase id, a live connection of the
   * enrolment's member, or a live caregiver of the same enrolment.
   */
  checkConsentRecipient(
    enrolment: Row,
    purpose: string,
    recipient: string | null,
  ): void {
    if (purpose !== "share_care_team" && purpose !== "share_caregiver") return;
    if (recipient === null) return;
    const state = this.ctx.state();
    const ok =
      LOWER_UUID.test(recipient) &&
      (purpose === "share_care_team"
        ? state.care_connections.some(
            (c) =>
              c.id === recipient &&
              c.user_id === enrolment.user_id &&
              c.revoked_at === null,
          )
        : state.caregivers.some(
            (g) =>
              g.id === recipient &&
              g.enrolment_id === enrolment.id &&
              g.user_id === enrolment.user_id &&
              g.revoked_at === null,
          ));
    if (!ok) this.ctx.raise("consent_recipient_invalid");
  }

  /** The revocation cascades, run once the request's writes are done. */
  cascade(): void {
    const state = this.ctx.state();
    for (let changed = true; changed;) {
      changed = false;
      for (const consent of state.programme_consents) {
        if (consent.revoked_at !== null) continue;
        const recipient = consent.recipient_ref as string | null;
        const gone =
          (consent.purpose === "share_care_team" &&
            state.care_connections.some(
              (c) => c.id === recipient && c.revoked_at !== null,
            )) ||
          (consent.purpose === "share_caregiver" &&
            state.caregivers.some(
              (g) =>
                g.id === recipient &&
                g.enrolment_id === consent.enrolment_id &&
                g.revoked_at !== null,
            ));
        if (gone) {
          consent.revoked_at = this.ctx.now();
          changed = true;
        }
      }
      for (const share of state.care_shares) {
        if (share.revoked_at !== null) continue;
        const consent = state.programme_consents.find(
          (c) => c.id === share.consent_id,
        );
        const connection = state.care_connections.find(
          (c) => c.id === share.connection_id,
        );
        if (
          (consent && consent.revoked_at !== null) ||
          (connection && connection.revoked_at !== null)
        ) {
          share.revoked_at = this.ctx.now();
          changed = true;
        }
      }
    }
  }

  /** Rows that go with an enrolment ("Delete now", on delete cascade). */
  dropEnrolment(enrolmentId: string): void {
    const state = this.ctx.state();
    const shares = new Set(
      state.care_shares
        .filter((s) => s.enrolment_id === enrolmentId)
        .map((s) => s.id),
    );
    state.care_messages = state.care_messages.filter(
      (m) => m.enrolment_id !== enrolmentId && !shares.has(m.share_id),
    );
    state.care_shares = state.care_shares.filter(
      (s) => s.enrolment_id !== enrolmentId,
    );
    state.caregivers = state.caregivers.filter(
      (g) => g.enrolment_id !== enrolmentId,
    );
  }

  /** Rows that go with a member (on delete cascade from auth.users). */
  dropMember(uid: string): void {
    const state = this.ctx.state();
    for (const table of [
      "care_connections",
      "care_shares",
      "care_messages",
      "caregivers",
      "supporters",
    ] as const) {
      state[table] = state[table].filter((row) => row.user_id !== uid);
    }
  }

  private liveConnection(id: string, uid?: string): boolean {
    return this.ctx
      .state()
      .care_connections.some(
        (c) =>
          c.id === id &&
          c.revoked_at === null &&
          (uid === undefined || c.user_id === uid),
      );
  }

  private ownLiveEnrolment(uid: string, id: string): boolean {
    return this.ctx
      .state()
      .enrolments.some(
        (e) => e.id === id && e.user_id === uid && e.status !== "left",
      );
  }

  private codesAllowed(uid: string, codes: unknown): boolean {
    if (!Array.isArray(codes)) return false;
    const allowed = this.ctx
      .state()
      .enrolments.filter(
        (e) =>
          e.user_id === uid &&
          ["bf", "sf"].includes(e.programme_code as string) &&
          e.status !== "left",
      )
      .map((e) => e.programme_code);
    return codes.every((code) => allowed.includes(code));
  }

  private checkSupporter(row: Row): void {
    if (!trimmed(row.name, 1, 80))
      check(this.ctx, "supporters", "supporters_name_check");
    if (typeof row.phone !== "string" || !PHONE.test(row.phone))
      check(this.ctx, "supporters", "supporters_phone_check");
    if (
      !uniqueTexts(row.programme_codes) ||
      row.programme_codes.some((code) => !["bf", "sf"].includes(code))
    )
      check(this.ctx, "supporters", "supporters_programme_codes_check");
    if (
      row.help_phrase !== null &&
      (typeof row.help_phrase !== "string" ||
        row.help_phrase.length < 1 ||
        row.help_phrase.length > 200)
    )
      check(this.ctx, "supporters", "supporters_help_phrase_check");
  }
}
