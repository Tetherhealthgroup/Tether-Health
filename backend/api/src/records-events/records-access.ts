import { BadGatewayException, Logger } from "@nestjs/common";
import type { PostgrestError } from "@supabase/supabase-js";
import { plainToInstance } from "class-transformer";
import { validate } from "class-validator";
import { liveCore } from "../enrolments/consent-rows";
import type { UserSupabaseClient } from "../enrolments/user-supabase-client";
import {
  conflict,
  invalidRequest,
  notFound,
} from "../programme-data/programme-data-errors";

/** A programme code as the path, query or body carries it. */
export const PROGRAMME_CODE = /^[a-z]{2}$/;

const SQLSTATE = /^[0-9A-Z]{5}$/;
const loggedCode = (code: string | undefined): string =>
  code && SQLSTATE.test(code) ? code : "none";

/**
 * Logs the request id, the route template, the status and the SQLSTATE
 * only (never a member, enrolment, programme, value or count), then fails
 * closed with 502.
 */
export function unavailable(
  logger: Logger,
  requestId: string,
  route: string,
  code: string | undefined,
): never {
  logger.error(
    `records_failed requestId=${requestId} route=${route} status=502 code=${loggedCode(code)}`,
  );
  throw new BadGatewayException("Records unavailable");
}

/**
 * A JSON object body: unknown keys are refused on the raw body's own keys
 * (so `constructor` and `prototype` are refused, never dropped), then the
 * DTO's validators run. Any failure is 400 `invalid_request`.
 */
export async function parseBody<T extends object>(
  rawBody: unknown,
  dto: new () => T,
  fields: readonly string[],
): Promise<T> {
  if (
    rawBody === null ||
    typeof rawBody !== "object" ||
    Array.isArray(rawBody)
  ) {
    throw invalidRequest();
  }
  if (
    Reflect.ownKeys(rawBody).some(
      (key) => typeof key !== "string" || !fields.includes(key),
    )
  ) {
    throw invalidRequest();
  }
  const body = plainToInstance(dto, rawBody);
  const errors = await validate(body, {
    whitelist: true,
    forbidNonWhitelisted: true,
    forbidUnknownValues: true,
  });
  if (errors.length > 0) throw invalidRequest();
  return body;
}

/** deletion_barrier_open() false → 409 `account_deletion_in_progress`. */
export async function requireBarrierOpen(
  client: UserSupabaseClient,
): Promise<void> {
  const barrier = (await client.rpc("deletion_barrier_open")) as {
    data: unknown;
    error: PostgrestError | null;
  };
  if (barrier.error) throw new BadGatewayException("Records unavailable");
  if (barrier.data !== true) throw conflict("account_deletion_in_progress");
}

export interface EnrolmentRef {
  id: string;
  status: string;
  mode: string | null;
}

/**
 * The caller's enrolment in `programmeCode`: missing → 404
 * `enrolment_not_found`; left → 409 `enrolment_left` unless `allowLeft`.
 */
export async function requireEnrolment(
  client: UserSupabaseClient,
  userId: string,
  programmeCode: string,
  { allowLeft = false } = {},
): Promise<EnrolmentRef> {
  const { data, error } = await client
    .from("enrolments")
    .select("id,status,mode")
    .eq("user_id", userId)
    .eq("programme_code", programmeCode)
    .maybeSingle<EnrolmentRef>();
  if (error) throw new BadGatewayException("Records unavailable");
  if (!data) throw notFound("enrolment_not_found");
  if (!allowLeft && data.status === "left") throw conflict("enrolment_left");
  return data;
}

/**
 * The write pre-checks after the barrier: the caller's enrolment (not
 * left) and its live core consent (none → 409 `core_consent_required`).
 * Returns the enrolment id.
 */
export async function requireWritableEnrolment(
  client: UserSupabaseClient,
  userId: string,
  programmeCode: string,
): Promise<string> {
  const enrolment = await requireEnrolment(client, userId, programmeCode);
  if ((await liveCore(client, enrolment.id)) === null) {
    throw conflict("core_consent_required");
  }
  return enrolment.id;
}

/** Rows per page when reading a list (below PostgREST's usual row cap). */
export const PAGE_SIZE = 500;

export interface PageResult<T> {
  data: T[] | null;
  error: PostgrestError | null;
  count: number | null;
}

/**
 * Reads every row of a query page by page, with an exact count per page so
 * that a server-side row cap can never truncate the list silently. `page`
 * builds the query for rows `from`..`to` (inclusive). Returns null on any
 * read error or inconsistent count (the caller fails closed).
 */
export async function readAll<T>(
  page: (from: number, to: number) => PromiseLike<PageResult<T>>,
): Promise<{ rows: T[] } | { error: string | undefined }> {
  const rows: T[] = [];
  for (;;) {
    const { data, error, count } = await page(
      rows.length,
      rows.length + PAGE_SIZE - 1,
    );
    if (error) return { error: error.code };
    if (data === null || count === null) return { error: undefined };
    rows.push(...data);
    if (rows.length >= count) return { rows };
    if (data.length === 0) return { error: undefined };
  }
}
