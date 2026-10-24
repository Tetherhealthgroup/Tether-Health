import { BadGatewayException } from "@nestjs/common";
import { DatabaseErrorCode } from "../common/database-errors";
import { conflict, notFound, registryErrorFor } from "./enrolment-errors";
import type { GrantConsentDto, GrantConsentResponse } from "./enrolments.dto";
import {
  CONSENT_COLUMNS,
  liveCore,
  toConsent,
  type ConsentRow,
  type RpcResult,
} from "./consent-rows";
import type { UserSupabaseClient } from "./user-supabase-client";

// Raised by public.supersede_core_consent() when the enrolment has no live
// core consent, including when a concurrent supersession or revocation
// replaced it while this call waited for its row lock.
const CONSENT_REQUIRES_CORE = DatabaseErrorCode.consentRequiresCore;

/** Whether a consent is for the version and locale the request names. */
export function isFor(consent: ConsentRow, dto: GrantConsentDto): boolean {
  return (
    consent.consent_version === dto.consentVersion &&
    consent.locale === dto.locale
  );
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
 * supersession is tried once more (at most two calls in all). If that
 * also loses a race, the live core is read once more: the requested
 * version and locale is the success it is; no live core is
 * core_consent_required; anything else (the same version in another
 * locale, an earlier or a later version, a row stored before documents
 * existed) is consent_conflict_retry, so the client reads the enrolment
 * again and decides. It does not guess what the database would answer (a
 * locale-only move to the same version is allowed, R-29), and nothing is
 * written.
 */
export function supersedeCore(
  client: UserSupabaseClient,
  enrolmentId: string,
  dto: GrantConsentDto,
): Promise<GrantConsentResponse> {
  return attemptSupersession(client, enrolmentId, dto, true);
}

async function attemptSupersession(
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
    const live = await liveCore(client, enrolmentId);
    if (live === null) throw conflict("core_consent_required");
    if (isFor(live, dto)) return answerAsDone(client, live);
    if (mayRetry) return attemptSupersession(client, enrolmentId, dto, false);
    throw conflict("consent_conflict_retry");
  }
  if (data === null) {
    throw new BadGatewayException("Consent could not be recorded");
  }
  // The function returns the old row, then the new one; identify them by
  // content rather than position.
  const replacement = data.find((row) => row.revoked_at === null);
  const superseded = data.find(
    (row) => replacement !== undefined && row.superseded_by === replacement.id,
  );
  if (data.length !== 2 || !replacement || !superseded) {
    throw new BadGatewayException("Consent could not be recorded");
  }
  return { ...toConsent(replacement), supersededId: superseded.id };
}

/** A live core that is already what was asked for: the request is done. */
async function answerAsDone(
  client: UserSupabaseClient,
  live: ConsentRow,
): Promise<GrantConsentResponse> {
  return {
    ...toConsent(live),
    supersededId: await supersededId(client, live.id),
  };
}

/** The core consent that `id` replaced, if any. */
async function supersededId(
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

/**
 * Why a consent could not be revoked: it is not visible (not found), it
 * was superseded by a core consent that is still live (consent_superseded:
 * the member's consent is live under the newer row, so "already revoked"
 * would be wrong), or it is revoked.
 */
export async function explainNotLive(
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
    (await liveCore(client, existing.data.enrolment_id)) !== null
  ) {
    throw conflict("consent_superseded");
  }
  throw conflict("consent_already_revoked");
}
