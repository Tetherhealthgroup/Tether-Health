/**
 * The database's own error codes, as the migrations raise them:
 * `raise exception using errcode = <code>, message = <one of messages>,
 * hint = <hint>`. Copied from the "Error codes" registry in
 * docs/contracts/database.md (checked by test/database-errors.e2e-spec.ts)
 * and used by the fake PostgREST, so tests see exactly what PostgREST passes
 * through from the real database. Reserved codes are never raised and have
 * no message yet.
 */
export interface DatabaseErrorEntry {
  readonly code: string;
  readonly hint: string;
  readonly messages: readonly string[];
}

// Messages are typed as plain string lists, so code that asks whether an
// entry has no message (a reserved code) still type-checks when none is
// reserved.
export const DATABASE_ERRORS = [
  {
    code: "TH001",
    hint: "focus_cap_reached",
    messages: ["At most two programmes can be in focus"] as readonly string[],
  },
  {
    code: "TH002",
    hint: "consent_already_revoked",
    messages: ["Consent is already revoked"] as readonly string[],
  },
  {
    code: "TH003",
    hint: "consent_immutable",
    messages: [
      "Consent can only be revoked",
      "Consent records are immutable",
    ] as readonly string[],
  },
  {
    code: "TH004",
    hint: "consent_requires_core",
    messages: ["A live core consent is required"] as readonly string[],
  },
  {
    code: "TH005",
    hint: "enrolment_left",
    messages: ["The programme has been left"] as readonly string[],
  },
  {
    code: "TH006",
    hint: "deletion_in_progress",
    messages: ["Account deletion has started"] as readonly string[],
  },
  {
    code: "TH007",
    hint: "sync_area_mismatch",
    messages: ["Sync area must match its enrolment"] as readonly string[],
  },
  {
    code: "TH008",
    hint: "lapses_append_only",
    messages: ["Lapses are append-only"] as readonly string[],
  },
  {
    code: "TH009",
    hint: "deletion_via_api_only",
    messages: ["Account deletion goes through the API"] as readonly string[],
  },
  {
    code: "TH010",
    hint: "sync_session_refused",
    messages: ["The sync service writes only sync tables"] as readonly string[],
  },
  {
    code: "TH011",
    hint: "consent_document_unavailable",
    messages: [
      "No consent document is available for this purpose, version and locale",
    ] as readonly string[],
  },
  {
    code: "TH012",
    hint: "enrolment_not_found",
    messages: ["Enrolment not found"] as readonly string[],
  },
  {
    code: "TH013",
    hint: "focus_swap_invalid",
    messages: [
      "A swap needs one programme in focus and another not in focus",
    ] as readonly string[],
  },
  {
    code: "TH014",
    hint: "consent_version_unchanged",
    messages: [
      "The core consent is already on this version or a later one",
    ] as readonly string[],
  },
  {
    code: "TH015",
    hint: "consent_document_immutable",
    messages: [
      "Consent documents are immutable, publish a new version",
      "A consent document version takes effect at the same time in every locale",
      "Consent documents are changed only by a role that bypasses row-level security",
    ] as readonly string[],
  },
  {
    code: "TH016",
    hint: "avatar_objects_remain",
    messages: [
      "Avatar objects must be removed before the account is deleted",
    ] as readonly string[],
  },
  {
    code: "TH017",
    hint: "recent_authentication_required",
    messages: ["Recent authentication is required"] as readonly string[],
  },
  {
    code: "TH018",
    hint: "auth_identity_not_deleted",
    messages: ["The account identity was not deleted"] as readonly string[],
  },
  {
    code: "TH019",
    hint: "sync_rows_delete_only",
    messages: [
      "Sync rows are removed only with their enrolment or account",
    ] as readonly string[],
  },
  {
    code: "TH020",
    hint: "rls_bypass_required",
    messages: [
      "Account deletion requires a function owner that bypasses row-level security",
    ] as readonly string[],
  },
  {
    code: "TH021",
    hint: "consent_recipient_invalid",
    messages: [
      "A sharing consent must name a live connection or caregiver of the same member",
    ] as readonly string[],
  },
  {
    code: "TH022",
    hint: "care_consent_required",
    messages: [
      "A live sharing consent for this recipient is required",
    ] as readonly string[],
  },
  {
    code: "TH023",
    hint: "care_record_immutable",
    messages: ["Care records can only be revoked"] as readonly string[],
  },
  {
    code: "TH024",
    hint: "care_rows_delete_only",
    messages: [
      "Care rows are removed only with their programme or account",
    ] as readonly string[],
  },
  {
    code: "TH025",
    hint: "care_invite_invalid",
    messages: ["Invite code is not valid"] as readonly string[],
  },
  {
    code: "TH026",
    hint: "programme_records_append_only",
    messages: ["Programme records are append-only"] as readonly string[],
  },
  {
    code: "TH027",
    hint: "programme_rows_delete_only",
    messages: [
      "Programme records are removed only with their programme or account",
    ] as readonly string[],
  },
  {
    code: "TH028",
    hint: "record_rows_delete_only",
    messages: [
      "Health records are removed only with their source or account",
    ] as readonly string[],
  },
  {
    code: "TH029",
    hint: "record_source_not_found",
    messages: ["Record source not found"] as readonly string[],
  },
] as const satisfies readonly DatabaseErrorEntry[];

export type DatabaseErrorHint = (typeof DATABASE_ERRORS)[number]["hint"];

/** The registry entry with this hint name. */
export const databaseError = (hint: DatabaseErrorHint): DatabaseErrorEntry => {
  const entry = DATABASE_ERRORS.find((candidate) => candidate.hint === hint);
  if (!entry) throw new Error(`Unknown database error ${hint}`);
  return entry;
};
