import { Injectable, Logger } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import {
  UserSupabaseClientFactory,
  type UserSupabaseClient,
} from "../enrolments/user-supabase-client";
import { invalidRequest } from "../programme-data/programme-data-errors";
import {
  PROGRAMME_CODE,
  readAll,
  requireEnrolment,
  unavailable,
  type PageResult,
} from "../records-events/records-access";
import { dayWindow } from "./day-window";
import { PROGRAMME_FIELDS } from "./programme-blocks";
import { HELPFUL, ProgrammeReader } from "./programme-reader";

/** The routes as logged: templates only. */
export const TODAY_ROUTE = "/v1/today";
export const SUMMARY_ROUTE = "/v1/records/summary";

/** The windows a summary may cover, in days. */
export const SUMMARY_DAYS = [7, 30, 90] as const;
/** Programmes whose lapses are recorded (sync_lapse). */
export const LAPSE_PROGRAMMES = ["bf", "sf"] as const;
/** The only programme whose rescues are its own (the rest are shared). */
export const RESCUE_PROGRAMME = "bf";

const DAY_MS = 24 * 60 * 60 * 1000;

type Row = Record<string, unknown>;

interface EnrolmentRow {
  id: string;
  programme_code: string;
  status: string;
  mode: string | null;
}

/**
 * The member's day and one programme's summary. Reads only, as the caller
 * (row-level security has the last word). Each programme block and each
 * summary is built only from that programme's rows.
 */
@Injectable()
export class TodayService {
  private readonly logger = new Logger(TodayService.name);

  constructor(private readonly clients: UserSupabaseClientFactory) {}

  async today(user: AuthUser, requestId: string, now = Date.now()) {
    const fail = (code: string | undefined): never =>
      unavailable(this.logger, requestId, TODAY_ROUTE, code);
    const client = this.clients.forUser(user);

    const profile = await client
      .from("profiles")
      .select("time_zone")
      .eq("id", user.id)
      .maybeSingle<{ time_zone: string | null }>();
    if (profile.error) fail(profile.error.code);
    const window = dayWindow(profile.data?.time_zone ?? null, now);

    const enrolments = await client
      .from("enrolments")
      .select("id,programme_code,status,mode")
      .eq("user_id", user.id)
      .order("programme_code", { ascending: true })
      .returns<EnrolmentRow[]>();
    if (enrolments.error || enrolments.data === null) {
      return fail(enrolments.error?.code);
    }

    const [doneToday, accountRescue, programmes] = await Promise.all([
      this.checkInDoneToday(client, user.id, window, fail),
      this.accountHelpfulRescue(client, user.id, fail),
      Promise.all(
        enrolments.data
          .filter((enrolment) => enrolment.status !== "left")
          .map((enrolment) =>
            this.block(
              new ProgrammeReader(
                client,
                user.id,
                enrolment.id,
                enrolment.programme_code,
                fail,
              ),
              enrolment,
              window,
            ),
          ),
      ),
    ]);
    return {
      date: window.date,
      checkin: { doneToday },
      account: { lastHelpfulRescue: accountRescue },
      programmes,
    };
  }

  /** One programme's block: common fields, then its own fixed fields. */
  private async block(
    reader: ProgrammeReader,
    enrolment: EnrolmentRow,
    window: ReturnType<typeof dayWindow>,
  ) {
    const fields = PROGRAMME_FIELDS[enrolment.programme_code];
    const [reminderAt, lessonsCompleted, own] = await Promise.all([
      reader.reminderAt(),
      reader.lessonsCompleted(),
      fields ? fields(reader, window) : Promise.resolve({}),
    ]);
    return {
      code: enrolment.programme_code,
      status: enrolment.status,
      mode: enrolment.mode,
      reminderAt,
      lessonsCompleted,
      ...own,
    };
  }

  /** Whether any check-in row of the caller happened today. */
  private async checkInDoneToday(
    client: UserSupabaseClient,
    userId: string,
    window: ReturnType<typeof dayWindow>,
    fail: (code: string | undefined) => never,
  ): Promise<boolean> {
    const { error, count } = await client
      .from("programme_entries")
      .select("kind", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("kind", "checkin")
      .gte("occurred_at", window.todayStart)
      .lt("occurred_at", window.tomorrowStart);
    if (error) fail(error.code);
    if (count === null) fail(undefined);
    return count > 0;
  }

  /** The newest shared (account-level) rescue that helped. */
  private async accountHelpfulRescue(
    client: UserSupabaseClient,
    userId: string,
    fail: (code: string | undefined) => never,
  ): Promise<{ tool: string; at: string } | null> {
    const { data, error } = await client
      .from("rescue_events")
      .select("tool,opened_at")
      .eq("user_id", userId)
      .is("enrolment_id", null)
      .in("helped", [...HELPFUL])
      .order("opened_at", { ascending: false })
      .limit(1)
      .returns<Row[]>();
    if (error || data === null) fail(error?.code);
    const row = data[0];
    return row === undefined
      ? null
      : { tool: String(row.tool), at: String(row.opened_at) };
  }

  /**
   * One programme's rows over the last `days` days: its observations,
   * entries and lessons, its lapses (bf, sf) and its rescues (bf). A left
   * enrolment is summarised too (its data is kept); not enrolled → 404.
   */
  async summary(
    user: AuthUser,
    query: unknown,
    requestId: string,
    now = Date.now(),
  ) {
    const { programme, days } = parseSummaryQuery(query);
    const fail = (code: string | undefined): never =>
      unavailable(this.logger, requestId, SUMMARY_ROUTE, code);
    const client = this.clients.forUser(user);
    const enrolment = await requireEnrolment(client, user.id, programme, {
      allowLeft: true,
    });
    const since = new Date(now - days * DAY_MS).toISOString();
    const own = (table: string, columns: string, time: string) =>
      readOwn(
        (from, to) =>
          client
            .from(table)
            .select(columns, { count: "exact" })
            .eq("user_id", user.id)
            .eq("enrolment_id", enrolment.id)
            .eq("programme_code", programme)
            .gte(time, since)
            .order(time, { ascending: false })
            .range(from, to)
            .returns<Row[]>(),
        fail,
      );

    const [observations, entries, lessons, lapses, rescues] = await Promise.all(
      [
        own(
          "observations",
          "metric,value,unit_ucum,effective_at,attributes",
          "effective_at",
        ),
        own("programme_entries", "kind,occurred_at,payload", "occurred_at"),
        own("lesson_progress", "lesson_id,completed_at", "completed_at"),
        (LAPSE_PROGRAMMES as readonly string[]).includes(programme)
          ? readOwn(
              (from, to) =>
                client
                  .from("sync_lapse")
                  .select("at", { count: "exact" })
                  .eq("user_id", user.id)
                  .eq("programme_code", programme)
                  .gte("at", since)
                  .order("at", { ascending: false })
                  .range(from, to)
                  .returns<Row[]>(),
              fail,
            )
          : null,
        programme === RESCUE_PROGRAMME
          ? own(
              "rescue_events",
              "tool,opened_at,intensity_before,intensity_after,helped,escalated",
              "opened_at",
            )
          : null,
      ],
    );

    return {
      programme,
      days,
      since,
      status: enrolment.status,
      observations: observations.map((row) => ({
        metric: row.metric,
        value: Number(row.value),
        unit: row.unit_ucum,
        at: row.effective_at,
        attributes: row.attributes,
      })),
      entries: entries.map((row) => ({
        kind: row.kind,
        at: row.occurred_at,
        payload: row.payload,
      })),
      lessons: lessons.map((row) => ({
        lessonId: row.lesson_id,
        completedAt: row.completed_at,
      })),
      ...(lapses === null
        ? {}
        : { lapses: lapses.map((row) => ({ at: row.at })) }),
      ...(rescues === null
        ? {}
        : {
            rescues: rescues.map((row) => ({
              tool: row.tool,
              openedAt: row.opened_at,
              intensityBefore: row.intensity_before,
              intensityAfter: row.intensity_after,
              helped: row.helped,
              escalated: row.escalated,
            })),
          }),
    };
  }
}

async function readOwn(
  page: (from: number, to: number) => PromiseLike<PageResult<Row>>,
  fail: (code: string | undefined) => never,
): Promise<Row[]> {
  const result = await readAll(page);
  if ("error" in result) return fail(result.error);
  return result.rows;
}

/**
 * `programme` (a programme code) and `days` (7, 30 or 90), nothing else;
 * any other key, a repeated key or another value → 400 `invalid_request`.
 */
export function parseSummaryQuery(query: unknown): {
  programme: string;
  days: (typeof SUMMARY_DAYS)[number];
} {
  if (query === null || typeof query !== "object") throw invalidRequest();
  const values = query as Record<string, unknown>;
  if (
    Reflect.ownKeys(values).some((key) => key !== "programme" && key !== "days")
  ) {
    throw invalidRequest();
  }
  const { programme, days } = values;
  if (typeof programme !== "string" || !PROGRAMME_CODE.test(programme)) {
    throw invalidRequest();
  }
  const parsed = SUMMARY_DAYS.find((value) => String(value) === days);
  if (parsed === undefined) throw invalidRequest();
  return { programme, days: parsed };
}
