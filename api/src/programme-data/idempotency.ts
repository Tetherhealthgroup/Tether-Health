import { badRequest } from "./programme-data-errors";

/** The app's form: 16 random bytes as 32 lowercase hex characters. */
const APP_KEY = /^[0-9a-f]{32}$/;
/** A canonical (hyphenated) UUID, either case. */
const UUID_KEY =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

/**
 * The submission id for an `Idempotency-Key` header value: the key's
 * 128-bit value written as a lowercase UUID, without hashing. Every unique
 * key it is stored under includes the enrolment, so two members can never
 * collide. Missing → 400 `idempotency_key_required`; any other form (empty,
 * repeated header, wrong length or alphabet) → 400 `idempotency_key_invalid`.
 */
export function submissionIdFrom(header: unknown): string {
  if (header === undefined) throw badRequest("idempotency_key_required");
  if (typeof header !== "string") throw badRequest("idempotency_key_invalid");
  if (APP_KEY.test(header)) {
    return [
      header.slice(0, 8),
      header.slice(8, 12),
      header.slice(12, 16),
      header.slice(16, 20),
      header.slice(20),
    ].join("-");
  }
  if (UUID_KEY.test(header)) return header.toLowerCase();
  throw badRequest("idempotency_key_invalid");
}
