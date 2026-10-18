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

export const DATABASE_ERRORS = [
  {
    code: "TH001",
    hint: "focus_cap_reached",
    messages: ["At most two programmes can be in focus"],
  },
  {
    code: "TH002",
    hint: "consent_already_revoked",
    messages: ["Consent is already revoked"],
  },
  {
    code: "TH003",
    hint: "consent_immutable",
    messages: ["Consent can only be revoked", "Consent records are immutable"],
  },
  { code: "TH004", hint: "consent_requires_core", messages: [] },
  { code: "TH005", hint: "enrolment_left", messages: [] },
  { code: "TH006", hint: "deletion_in_progress", messages: [] },
  {
    code: "TH007",
    hint: "sync_area_mismatch",
    messages: ["Sync area must match its enrolment"],
  },
  {
    code: "TH008",
    hint: "lapses_append_only",
    messages: ["Lapses are append-only"],
  },
  {
    code: "TH009",
    hint: "deletion_via_api_only",
    messages: ["Account deletion goes through the API"],
  },
  {
    code: "TH010",
    hint: "sync_session_refused",
    messages: ["The sync service writes only sync tables"],
  },
] as const satisfies readonly DatabaseErrorEntry[];

export type DatabaseErrorHint = (typeof DATABASE_ERRORS)[number]["hint"];

/** The registry entry with this hint name. */
export const databaseError = (hint: DatabaseErrorHint): DatabaseErrorEntry => {
  const entry = DATABASE_ERRORS.find((candidate) => candidate.hint === hint);
  if (!entry) throw new Error(`Unknown database error ${hint}`);
  return entry;
};
