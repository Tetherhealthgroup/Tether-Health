import { BadGatewayException, Injectable, Logger } from "@nestjs/common";
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
} from "../programme-data/programme-data.dto";
import {
  conflict,
  insertErrorFor,
  invalidRequest,
  unprocessable,
} from "../programme-data/programme-data-errors";
import {
  ENTRY_COMPARED,
  present,
  sameRows,
  type Row,
} from "../programme-data/programme-records";
import {
  parseBody,
  requireBarrierOpen,
  requireWritableEnrolment,
  unavailable,
} from "./records-access";
import {
  ANSWER_PROGRAMMES,
  CHECK_IN_FIELDS,
  CheckInDto,
  LESSON_FIELDS,
  LessonDto,
  RESCUE_FIELDS,
  RescueDto,
  type AnswerProgramme,
  type CheckInCreated,
  type CheckInReplayed,
} from "./records-events.dto";
import { NoFocusProgrammeException } from "./records-errors";

/** The routes as logged: templates only. */
export const CHECK_IN_ROUTE = "/v1/records/check-ins";
export const RESCUE_ROUTE = "/v1/records/rescues";
export const LESSON_ROUTE = "/v1/records/lessons";

/**
 * The stored fields a rescue replay compares. Never compared: opened_at,
 * created_at, id and submission_id; the first stored time wins.
 */
export const RESCUE_COMPARED = [
  "user_id",
  "enrolment_id",
  "programme_code",
  "tool",
  "intensity_before",
  "intensity_after",
  "helped",
  "escalated",
] as const;

/** An enrolment a check-in is written into. */
export interface CheckInTarget {
  enrolmentId: string;
  programmeCode: string;
}

/**
 * The check-in rows: one per target (each a focus enrolment with a live
 * core consent), each holding `feel` and `stress` and only its own
 * programme's answer. A target whose row would hold nothing (no shared
 * value and no answer of its own) gets no row: the database refuses an
 * empty check-in.
 */
export function checkInRows(
  body: CheckInDto,
  targets: readonly CheckInTarget[],
  userId: string,
  submissionId: string,
  now: string,
): Row[] {
  const answers = body.answers ?? {};
  return targets
    .map((target) => ({
      target,
      payload: present({
        feel: body.feel,
        stress: body.stress,
        answer: (ANSWER_PROGRAMMES as string[]).includes(target.programmeCode)
          ? answers[target.programmeCode as AnswerProgramme]
          : undefined,
      }),
    }))
    .filter(({ payload }) => Object.keys(payload).length > 0)
    .map(({ target, payload }) => ({
      user_id: userId,
      enrolment_id: target.enrolmentId,
      programme_code: target.programmeCode,
      submission_id: submissionId,
      kind: "checkin",
      occurred_at: body.occurredAt ?? now,
      payload,
    }));
}

const lower = (value: unknown) =>
  typeof value === "string" ? value.toLowerCase() : value;

/**
 * The replay rule for a check-in whose submission already has rows: the
 * stored rows are compared with the computed rows of the same enrolments;
 * a stored row whose enrolment no longer qualifies is not compared, and
 * nothing new is inserted. True when every compared row is equal.
 */
export function checkInReplayMatches(
  stored: readonly Row[],
  computed: readonly Row[],
): boolean {
  if (stored.length === 0) return false;
  const byEnrolment = new Map(
    computed.map((row) => [lower(row.enrolment_id), row]),
  );
  const pairs = stored.filter((row) =>
    byEnrolment.has(lower(row.enrolment_id)),
  );
  return sameRows(
    pairs,
    pairs.map((row) => byEnrolment.get(lower(row.enrolment_id)) as Row),
    ENTRY_COMPARED,
  );
}

export type CheckInResult =
  | { status: 201; body: CheckInCreated }
  | { status: 200; body: CheckInReplayed };
export type SubmitResult =
  | { status: 201; body: ProgrammeRecordCreated }
  | { status: 200; body: ProgrammeRecordReplayed };

/**
 * Check-ins, rescues and lessons. Every query runs as the caller (anon key
 * plus the caller's JWT), so row-level security has the last word; the
 * pre-checks answer the common refusals with a precise code first.
 */
@Injectable()
export class RecordsEventsService {
  private readonly logger = new Logger(RecordsEventsService.name);

  constructor(private readonly clients: UserSupabaseClientFactory) {}

  async checkIn(
    user: AuthUser,
    rawBody: unknown,
    submissionId: string,
    requestId: string,
  ): Promise<CheckInResult> {
    const body = await parseBody(rawBody, CheckInDto, CHECK_IN_FIELDS);
    const answers = Object.keys(body.answers ?? {});
    if (
      body.feel === undefined &&
      body.stress === undefined &&
      answers.length === 0
    ) {
      throw invalidRequest();
    }
    const client = this.clients.forUser(user);
    await requireBarrierOpen(client);
    const targets = await this.focusWithCore(client, user.id);
    if (targets.length === 0) throw new NoFocusProgrammeException();
    // An answer belongs only to its own programme's row; a programme that
    // is not a qualifying enrolment cannot take one.
    if (
      answers.some(
        (code) => !targets.some((target) => target.programmeCode === code),
      )
    ) {
      throw unprocessable("invalid_record");
    }
    const rows = checkInRows(
      body,
      targets,
      user.id,
      submissionId,
      new Date().toISOString(),
    );

    // Any stored row of this submission makes the request a replay.
    let stored = await this.storedCheckIns(
      client,
      user.id,
      submissionId,
      requestId,
    );
    if (stored.length === 0) {
      const { error } = await client.from("programme_entries").insert(rows);
      if (!error) {
        return {
          status: 201,
          body: { submissionId, entries: programmesOf(rows) },
        };
      }
      if (error.code !== DatabaseErrorCode.uniqueViolation) {
        throw this.insertFailure(error.code, requestId, CHECK_IN_ROUTE);
      }
      stored = await this.storedCheckIns(
        client,
        user.id,
        submissionId,
        requestId,
      );
    }
    if (!checkInReplayMatches(stored, rows)) {
      throw conflict("idempotency_key_conflict");
    }
    return {
      status: 200,
      body: { submissionId, replayed: true, entries: programmesOf(stored) },
    };
  }

  /**
   * A rescue. `programme: "bf"` writes into the caller's BreatheFree
   * enrolment after its pre-checks, and is refused (never written as a
   * shared rescue) when they fail; no `programme` is a shared rescue with
   * no enrolment. The programme is never inferred.
   */
  async rescue(
    user: AuthUser,
    rawBody: unknown,
    submissionId: string,
    requestId: string,
  ): Promise<SubmitResult> {
    const body = await parseBody(rawBody, RescueDto, RESCUE_FIELDS);
    const client = this.clients.forUser(user);
    await requireBarrierOpen(client);
    const enrolmentId =
      body.programme === "bf"
        ? await requireWritableEnrolment(client, user.id, "bf")
        : null;
    const row: Row = {
      user_id: user.id,
      enrolment_id: enrolmentId,
      programme_code: enrolmentId === null ? null : "bf",
      submission_id: submissionId,
      tool: body.tool,
      opened_at: body.openedAt ?? new Date().toISOString(),
      intensity_before: body.intensityBefore ?? null,
      intensity_after: body.intensityAfter ?? null,
      helped: body.helped ?? null,
      escalated: body.escalated ?? false,
    };
    const { error } = await client.from("rescue_events").insert([row]);
    if (!error) return { status: 201, body: { submissionId } };
    if (error.code !== DatabaseErrorCode.uniqueViolation) {
      throw this.insertFailure(error.code, requestId, RESCUE_ROUTE);
    }
    const stored = await client
      .from("rescue_events")
      .select(RESCUE_COMPARED.join(","))
      .eq("user_id", user.id)
      .eq("submission_id", submissionId)
      .returns<Row[]>();
    if (stored.error || stored.data === null) {
      unavailable(this.logger, requestId, RESCUE_ROUTE, stored.error?.code);
    }
    if (!sameRows(stored.data, [row], RESCUE_COMPARED)) {
      throw conflict("idempotency_key_conflict");
    }
    return { status: 200, body: { submissionId, replayed: true } };
  }

  /**
   * A completed lesson. The lesson is the identity: completing it again is
   * a 200 replay whatever the key.
   */
  async lesson(
    user: AuthUser,
    rawBody: unknown,
    submissionId: string,
    requestId: string,
  ): Promise<SubmitResult> {
    const body = await parseBody(rawBody, LessonDto, LESSON_FIELDS);
    if (!body.lessonId.startsWith(`${body.programme}.`)) {
      throw invalidRequest();
    }
    const client = this.clients.forUser(user);
    await requireBarrierOpen(client);
    const enrolmentId = await requireWritableEnrolment(
      client,
      user.id,
      body.programme,
    );
    const { error } = await client.from("lesson_progress").insert([
      {
        user_id: user.id,
        enrolment_id: enrolmentId,
        programme_code: body.programme,
        lesson_id: body.lessonId,
      },
    ]);
    if (!error) return { status: 201, body: { submissionId } };
    if (error.code === DatabaseErrorCode.uniqueViolation) {
      return { status: 200, body: { submissionId, replayed: true } };
    }
    throw this.insertFailure(error.code, requestId, LESSON_ROUTE);
  }

  /** The caller's focus enrolments that hold a live core consent. */
  private async focusWithCore(
    client: UserSupabaseClient,
    userId: string,
  ): Promise<CheckInTarget[]> {
    const { data, error } = await client
      .from("enrolments")
      .select("id,programme_code")
      .eq("user_id", userId)
      .eq("status", "focus")
      .returns<{ id: string; programme_code: string }[]>();
    if (error || data === null) {
      throw new BadGatewayException("Records unavailable");
    }
    const targets: CheckInTarget[] = [];
    for (const enrolment of data) {
      if ((await liveCore(client, enrolment.id)) !== null) {
        targets.push({
          enrolmentId: enrolment.id,
          programmeCode: enrolment.programme_code,
        });
      }
    }
    return targets;
  }

  /** The caller's check-in rows stored under this submission. */
  private async storedCheckIns(
    client: UserSupabaseClient,
    userId: string,
    submissionId: string,
    requestId: string,
  ): Promise<Row[]> {
    const { data, error } = await client
      .from("programme_entries")
      .select(ENTRY_COMPARED.join(","))
      .eq("user_id", userId)
      .eq("submission_id", submissionId)
      .eq("kind", "checkin")
      .returns<Row[]>();
    if (error || data === null) {
      unavailable(this.logger, requestId, CHECK_IN_ROUTE, error?.code);
    }
    return data;
  }

  /** The client error for an insert's SQLSTATE, or a logged 502. */
  private insertFailure(
    code: string | undefined,
    requestId: string,
    route: string,
  ): Error {
    const mapped = insertErrorFor(code);
    if (mapped) return mapped;
    return unavailable(this.logger, requestId, route, code);
  }
}

function programmesOf(rows: readonly Row[]): string[] {
  return [...new Set(rows.map((row) => String(row.programme_code)))].sort();
}
