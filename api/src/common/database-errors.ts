/**
 * SQLSTATE codes the API maps to its own responses. Errors raised by our own
 * database functions and triggers use the custom class `TH`; the registry
 * (code, hint name, message) is the "Error codes" table in
 * docs/contracts/database.md. Match the `code` only, never the message text:
 * messages are for people and may be reworded. A code not handled at a call
 * site, including any other `TH` code, fails closed as a 502 without echoing
 * database detail.
 */
export const DatabaseErrorCode = {
  // Standard PostgreSQL conditions.
  uniqueViolation: "23505",
  foreignKeyViolation: "23503",
  checkViolation: "23514",
  insufficientPrivilege: "42501",
  // Registry codes; each key is the camelCase form of the registry hint name.
  focusCapReached: "TH001",
  consentAlreadyRevoked: "TH002",
  consentImmutable: "TH003",
  consentRequiresCore: "TH004",
  enrolmentLeft: "TH005",
  deletionInProgress: "TH006",
  syncSessionRefused: "TH010",
  consentDocumentUnavailable: "TH011",
  enrolmentNotFound: "TH012",
  focusSwapInvalid: "TH013",
  consentVersionUnchanged: "TH014",
  consentDocumentImmutable: "TH015",
  consentRecipientInvalid: "TH021",
  careConsentRequired: "TH022",
  careRecordImmutable: "TH023",
  careInviteInvalid: "TH025",
} as const;
