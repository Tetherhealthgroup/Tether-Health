import { BadGatewayException } from "@nestjs/common";
import type { PostgrestError } from "@supabase/supabase-js";
import type {
  ConsentLocale,
  ConsentPurpose,
  ConsentResponse,
} from "./enrolments.dto";
import type { UserSupabaseClient } from "./user-supabase-client";

/** A programme_consents row as the API selects it (CONSENT_COLUMNS). */
export interface ConsentRow {
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

/** The untyped client's result of a set-returning function call. */
export interface RpcResult<T> {
  data: T | null;
  error: PostgrestError | null;
}

export const CONSENT_COLUMNS =
  "id,enrolment_id,purpose,recipient_ref,consent_version,locale,consent_text,granted_at,revoked_at,superseded_by";

/** The enrolment's live core consent (at most one exists), or null. */
export async function liveCore(
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

export function toConsent(row: ConsentRow): ConsentResponse {
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
