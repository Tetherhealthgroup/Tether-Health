import { BadGatewayException, Injectable, Logger } from "@nestjs/common";
import type { PostgrestError } from "@supabase/supabase-js";
import { plainToInstance } from "class-transformer";
import { validate } from "class-validator";
import type { AuthUser } from "../auth/auth-user";
import { DatabaseErrorCode } from "../common/database-errors";
import { liveCore } from "../enrolments/consent-rows";
import {
  UserSupabaseClientFactory,
  type UserSupabaseClient,
} from "../enrolments/user-supabase-client";
import type {
  ProgrammeRecordCreated,
  ProgrammeRecordReplayed,
} from "./programme-data.dto";
import {
  conflict,
  insertErrorFor,
  invalidRequest,
  notFound,
  unprocessable,
} from "./programme-data-errors";
import { routeName, type ProgrammeRoute } from "./programme-data.routes";
import {
  ENTRY_COMPARED,
  OBSERVATION_COMPARED,
  VALUE_MAX,
  VALUE_MIN,
  entryRow,
  observationRow,
  sameRows,
  type Row,
  type SubmissionContext,
} from "./programme-records";
import { rangesFor } from "./ranges";

/**
 * The route as logged. Never the concrete path: it names a programme.
 */
export const ROUTE_TEMPLATE = "/v1/program-data/:code/:kind";

const SQLSTATE = /^[0-9A-Z]{5}$/;
const loggedCode = (code: string | undefined): string =>
  code && SQLSTATE.test(code) ? code : "none";

type Table = "programme_entries" | "observations";
const COMPARED: Record<Table, readonly string[]> = {
  programme_entries: ENTRY_COMPARED,
  observations: OBSERVATION_COMPARED,
};

export type SubmitResult =
  | { status: 201; body: ProgrammeRecordCreated }
  | { status: 200; body: ProgrammeRecordReplayed };

/**
 * Programme event submits. Every query runs as the caller (anon key + the
 * caller's JWT), so row-level security has the last word; the pre-checks
 * only answer the common refusals with a precise code first.
 */
@Injectable()
export class ProgrammeDataService {
  private readonly logger = new Logger(ProgrammeDataService.name);

  constructor(private readonly clients: UserSupabaseClientFactory) {}

  /**
   * Validates the body, runs the pre-checks and writes the submission: one
   * bulk insert per table (one statement each), the programme entry before
   * its observations. A unique violation on a submission key is a replay.
   */
  async submit(
    user: AuthUser,
    route: ProgrammeRoute,
    rawBody: unknown,
    submissionId: string,
    requestId: string,
  ): Promise<SubmitResult> {
    const body = await this.parseBody(route, rawBody);
    const draft = route.build(body);
    const client = this.clients.forUser(user);
    const enrolmentId = await this.preCheck(client, user, route.code);

    const context: SubmissionContext = {
      userId: user.id,
      enrolmentId,
      programmeCode: route.code,
      submissionId,
      now: new Date().toISOString(),
    };
    const entries = draft.entry ? [entryRow(draft.entry, context)] : [];
    const observations = draft.observations.map((observation) =>
      observationRow(observation, context),
    );
    // The database's value bound, answered as the database would answer it
    // (a value past numeric(9,3)'s precision would otherwise be a 502).
    if (
      draft.observations.some(
        ({ value }) => value < VALUE_MIN || value > VALUE_MAX,
      )
    ) {
      throw unprocessable("invalid_record");
    }

    let written = false;
    if (entries.length > 0) {
      written =
        (await this.insert(
          client,
          "programme_entries",
          entries,
          context,
          requestId,
        )) || written;
    }
    if (observations.length > 0) {
      written =
        (await this.insert(
          client,
          "observations",
          observations,
          context,
          requestId,
        )) || written;
    }
    return written
      ? { status: 201, body: { submissionId } }
      : { status: 200, body: { submissionId, replayed: true } };
  }

  /**
   * Unknown keys (on the raw body), the DTO, then at-least-one, then spec
   * ranges.
   */
  private async parseBody(
    route: ProgrammeRoute,
    rawBody: unknown,
  ): Promise<object> {
    if (
      rawBody === null ||
      typeof rawBody !== "object" ||
      Array.isArray(rawBody)
    ) {
      throw invalidRequest();
    }
    // Unknown keys are refused on the raw body's own keys, so that names
    // the transform would skip or treat specially (`constructor`,
    // `prototype`, `__proto__`) are refused too, never silently dropped.
    if (
      Reflect.ownKeys(rawBody).some(
        (key) => typeof key !== "string" || !Object.hasOwn(route.fields, key),
      )
    ) {
      throw invalidRequest();
    }
    const body = plainToInstance(route.dto, rawBody) as object;
    const errors = await validate(body, {
      whitelist: true,
      forbidNonWhitelisted: true,
      forbidUnknownValues: true,
    });
    if (errors.length > 0) throw invalidRequest();
    const values = body as Record<string, unknown>;
    if (
      route.atLeastOne &&
      !route.atLeastOne.some((field) => values[field] !== undefined)
    ) {
      throw invalidRequest();
    }
    for (const range of rangesFor(routeName(route))) {
      const value = values[range.field];
      if (
        typeof value === "number" &&
        (value < range.min || value > range.max)
      ) {
        throw unprocessable("value_out_of_range");
      }
    }
    return body;
  }

  /**
   * In order: the deletion barrier, the caller's enrolment in the
   * programme (not left), its live core consent. Returns the enrolment id.
   */
  private async preCheck(
    client: UserSupabaseClient,
    user: AuthUser,
    programmeCode: string,
  ): Promise<string> {
    const barrier = (await client.rpc("deletion_barrier_open")) as {
      data: unknown;
      error: PostgrestError | null;
    };
    if (barrier.error) throw new BadGatewayException("Records unavailable");
    if (barrier.data !== true) throw conflict("account_deletion_in_progress");

    const { data, error } = await client
      .from("enrolments")
      .select("id,status")
      .eq("user_id", user.id)
      .eq("programme_code", programmeCode)
      .maybeSingle<{ id: string; status: string }>();
    if (error) throw new BadGatewayException("Records unavailable");
    if (!data) throw notFound("enrolment_not_found");
    if (data.status === "left") throw conflict("enrolment_left");

    if ((await liveCore(client, data.id)) === null) {
      throw conflict("core_consent_required");
    }
    return data.id;
  }

  /**
   * One bulk insert. Returns true when the rows were written, false when
   * they were all already stored with equal compared fields (a replay);
   * stored rows that differ are a 409.
   */
  private async insert(
    client: UserSupabaseClient,
    table: Table,
    rows: Row[],
    context: SubmissionContext,
    requestId: string,
  ): Promise<boolean> {
    const { error } = await client.from(table).insert(rows);
    if (!error) return true;
    if (error.code === DatabaseErrorCode.uniqueViolation) {
      const stored = await this.storedRows(client, table, context, requestId);
      if (sameRows(stored, rows, COMPARED[table])) return false;
      throw conflict("idempotency_key_conflict");
    }
    const mapped = insertErrorFor(error.code);
    if (mapped) throw mapped;
    this.failed(requestId, error.code);
  }

  /** The caller's rows of this submission in this enrolment. */
  private async storedRows(
    client: UserSupabaseClient,
    table: Table,
    context: SubmissionContext,
    requestId: string,
  ): Promise<Row[]> {
    const { data, error, count } = await client
      .from(table)
      .select(COMPARED[table].join(","), { count: "exact" })
      .eq("user_id", context.userId)
      .eq("enrolment_id", context.enrolmentId)
      .eq("submission_id", context.submissionId)
      .returns<Row[]>();
    if (error) this.failed(requestId, error.code);
    if (count === null || data.length !== count) {
      this.failed(requestId, undefined);
    }
    return data;
  }

  /** Logs the request id, route template, status and SQLSTATE only. */
  private failed(requestId: string, code: string | undefined): never {
    this.logger.error(
      `programme_record_failed requestId=${requestId} route=${ROUTE_TEMPLATE} status=502 code=${loggedCode(code)}`,
    );
    throw new BadGatewayException("Records unavailable");
  }
}
