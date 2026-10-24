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

/**
 * The replay rule for a check-in whose submission already has rows: for
 * EVERY stored row, the row the new body would write into that row's
 * enrolment is computed (whether or not the enrolment still qualifies) and
 * compared on the compared fields (times excluded). True only when every
 * stored row has an equal expected row; an expected row that differs or
 * is absent (the body would write nothing there) is a conflict. Enrolments
 * that qualify now but hold no stored row are ignored; nothing new is
 * inserted.
 */
export function checkInReplayMatches(
  stored: readonly Row[],
  body: CheckInDto,
  userId: string,
  submissionId: string,
): boolean {
  if (stored.length === 0) return false;
  const expected = checkInRows(
    body,
    stored.map((row) => ({
      enrolmentId: String(row.enrolment_id),
      programmeCode: String(row.programme_code),
    })),
    userId,
    submissionId,
    "",
  );
  return (
    expected.length === stored.length &&
    sameRows(stored, expected, ENTRY_COMPARED)
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

  /**
   * Order: the body, then replay detection (any stored check-in row of
   * this submission makes the request a replay, answered 200 or 409 and
   * never refused by the checks below), then the deletion barrier, the
   * qualifying enrolments (none → 409 `no_focus_programme`), the answers
   * (one for a programme that does not qualify → 422), and the insert.
   */
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
    let stored = await this.storedCheckIns(
      client,
      user.id,
      submissionId,
      requestId,
    );
    if (stored.length > 0) {
      return this.checkInReplay(stored, body, user.id, submissionId);
    }

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
    // A concurrent request stored the submission first.
    stored = await this.storedCheckIns(
      client,
      user.id,
      submissionId,
      requestId,
    );
    return this.checkInReplay(stored, body, user.id, submissionId);
  }

  private checkInReplay(
    stored: Row[],
    body: CheckInDto,
    userId: string,
    submissionId: string,
  ): CheckInResult {
    if (!checkInReplayMatches(stored, body, userId, submissionId)) {
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
   * no enrolment. The programme is never inferred. A stored rescue under
   * this submission is detected first: a replay is answered 200 or 409
   * whatever the enrolment's state now.
   */
  async rescue(
    user: AuthUser,
    rawBody: unknown,
    submissionId: string,
    requestId: string,
  ): Promise<SubmitResult> {
    const body = await parseBody(rawBody, RescueDto, RESCUE_FIELDS);
    const client = this.clients.forUser(user);
    const rowFor = (enrolmentId: string | null): Row => ({
      user_id: user.id,
      enrolment_id: enrolmentId,
      programme_code: body.programme === "bf" ? "bf" : null,
      submission_id: submissionId,
      tool: body.tool,
      opened_at: body.openedAt ?? new Date().toISOString(),
      intensity_before: body.intensityBefore ?? null,
      intensity_after: body.intensityAfter ?? null,
      helped: body.helped ?? null,
      escalated: body.escalated ?? false,
    });
    const replay = async (stored: Row[]): Promise<SubmitResult> => {
      // The bf enrolment in any state (a left enrolment keeps its rows).
      const enrolmentId =
        body.programme === "bf"
          ? await this.anyEnrolmentId(client, user.id, "bf")
          : null;
      if (!sameRows(stored, [rowFor(enrolmentId)], RESCUE_COMPARED)) {
        throw conflict("idempotency_key_conflict");
      }
      return { status: 200, body: { submissionId, replayed: true } };
    };

    const stored = await this.storedRescues(
      client,
      user.id,
      submissionId,
      requestId,
    );
    if (stored.length > 0) return replay(stored);

    await requireBarrierOpen(client);
    const row = rowFor(
      body.programme === "bf"
        ? await requireWritableEnrolment(client, user.id, "bf")
        : null,
    );
    const { error } = await client.from("rescue_events").insert([row]);
    if (!error) return { status: 201, body: { submissionId } };
    if (error.code !== DatabaseErrorCode.uniqueViolation) {
      throw this.insertFailure(error.code, requestId, RESCUE_ROUTE);
    }
    return replay(
      await this.storedRescues(client, user.id, submissionId, requestId),
    );
  }

  /**
   * A completed lesson. The lesson is the identity: a lesson already
   * completed is a 200 replay whatever the key, detected before the
   * pre-checks (so also after the enrolment was left).
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
    const replayed = {
      status: 200,
      body: { submissionId, replayed: true },
    } as const;
    const done = await client
      .from("lesson_progress")
      .select("lesson_id")
      .eq("user_id", user.id)
      .eq("programme_code", body.programme)
      .eq("lesson_id", body.lessonId)
      .limit(1)
      .returns<Row[]>();
    if (done.error || done.data === null) {
      return unavailable(
        this.logger,
        requestId,
        LESSON_ROUTE,
        done.error?.code,
      );
    }
    if (done.data.length > 0) return replayed;

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
    if (error.code === DatabaseErrorCode.uniqueViolation) return replayed;
    throw this.insertFailure(error.code, requestId, LESSON_ROUTE);
  }

  /** The caller's enrolment id in `programmeCode`, in any state, or null. */
  private async anyEnrolmentId(
    client: UserSupabaseClient,
    userId: string,
    programmeCode: string,
  ): Promise<string | null> {
    const { data, error } = await client
      .from("enrolments")
      .select("id")
      .eq("user_id", userId)
      .eq("programme_code", programmeCode)
      .maybeSingle<{ id: string }>();
    if (error) throw new BadGatewayException("Records unavailable");
    return data?.id ?? null;
  }

  /** The caller's rescue stored under this submission (at most one). */
  private async storedRescues(
    client: UserSupabaseClient,
    userId: string,
    submissionId: string,
    requestId: string,
  ): Promise<Row[]> {
    const { data, error } = await client
      .from("rescue_events")
      .select(RESCUE_COMPARED.join(","))
      .eq("user_id", userId)
      .eq("submission_id", submissionId)
      .returns<Row[]>();
    if (error || data === null) {
      unavailable(this.logger, requestId, RESCUE_ROUTE, error?.code);
    }
    return data;
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
