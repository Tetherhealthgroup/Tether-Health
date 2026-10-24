import type { PostgrestError } from "@supabase/supabase-js";
import type { UserSupabaseClient } from "../enrolments/user-supabase-client";

type Row = Record<string, unknown>;

/** A rescue that helped: "Yes" or "A little". */
export const HELPFUL = ["yes", "a_little"] as const;

/**
 * Reads of ONE programme's rows for the caller: every query is filtered by
 * the caller, the enrolment and its programme, so a block built through a
 * reader cannot hold another programme's row. Lapses come from sync_lapse
 * by the caller and the programme (counts and the last time only); nothing
 * else of the sync tables is read. `fail` is called with the SQLSTATE of
 * any read error and must throw.
 */
export class ProgrammeReader {
  constructor(
    private readonly client: UserSupabaseClient,
    private readonly userId: string,
    readonly enrolmentId: string,
    readonly programmeCode: string,
    private readonly fail: (code: string | undefined) => never,
  ) {}

  private own(table: string, columns: string) {
    return this.client
      .from(table)
      .select(columns)
      .eq("user_id", this.userId)
      .eq("enrolment_id", this.enrolmentId)
      .eq("programme_code", this.programmeCode);
  }

  private one(result: {
    data: unknown;
    error: PostgrestError | null;
  }): Row | null {
    if (result.error) this.fail(result.error.code);
    const rows = result.data as Row[] | null;
    if (rows === null) this.fail(undefined);
    return rows[0] ?? null;
  }

  private counted(result: {
    error: PostgrestError | null;
    count: number | null;
  }): number {
    if (result.error) this.fail(result.error.code);
    if (result.count === null) this.fail(undefined);
    return result.count;
  }

  /** The newest observation of `metric` (by its effective time). */
  async latestObservation(metric: string): Promise<Row | null> {
    return this.one(
      await this.own("observations", "value,effective_at,submission_id")
        .eq("metric", metric)
        .order("effective_at", { ascending: false })
        .limit(1),
    );
  }

  /** The observation of `metric` written by one submission. */
  async observationOf(
    metric: string,
    submissionId: string,
  ): Promise<Row | null> {
    return this.one(
      await this.own("observations", "value")
        .eq("metric", metric)
        .eq("submission_id", submissionId)
        .limit(1),
    );
  }

  /** The newest programme entry of `kind` (by when it happened). */
  async latestEntry(kind: string): Promise<Row | null> {
    return this.one(
      await this.own("programme_entries", "payload,occurred_at")
        .eq("kind", kind)
        .order("occurred_at", { ascending: false })
        .limit(1),
    );
  }

  /** Entries of `kind` that happened from `from` (inclusive) to `until`. */
  async countEntries(
    kind: string,
    from: string,
    until?: string,
  ): Promise<number> {
    let query = this.client
      .from("programme_entries")
      .select("kind", { count: "exact", head: true })
      .eq("user_id", this.userId)
      .eq("enrolment_id", this.enrolmentId)
      .eq("programme_code", this.programmeCode)
      .eq("kind", kind)
      .gte("occurred_at", from);
    if (until !== undefined) query = query.lt("occurred_at", until);
    return this.counted(await query);
  }

  /** Lessons completed in this enrolment. */
  async lessonsCompleted(): Promise<number> {
    return this.counted(
      await this.client
        .from("lesson_progress")
        .select("lesson_id", { count: "exact", head: true })
        .eq("user_id", this.userId)
        .eq("enrolment_id", this.enrolmentId)
        .eq("programme_code", this.programmeCode),
    );
  }

  /** The reminder time as HH:MM, or null when none is stored. */
  async reminderAt(): Promise<string | null> {
    const row = this.one(
      await this.own("programme_reminders", "remind_at").limit(1),
    );
    return row === null ? null : String(row.remind_at).slice(0, 5);
  }

  /** The newest rescue of this enrolment that helped. */
  async lastHelpfulRescue(): Promise<Row | null> {
    return this.one(
      await this.own("rescue_events", "tool,opened_at")
        .in("helped", [...HELPFUL])
        .order("opened_at", { ascending: false })
        .limit(1),
    );
  }

  /** Lapses recorded by sync for this programme since `from`. */
  async countLapses(from: string): Promise<number> {
    return this.counted(
      await this.client
        .from("sync_lapse")
        .select("ordinal", { count: "exact", head: true })
        .eq("user_id", this.userId)
        .eq("programme_code", this.programmeCode)
        .gte("at", from),
    );
  }

  /** The time of the newest lapse recorded by sync for this programme. */
  async lastLapseAt(): Promise<string | null> {
    const row = this.one(
      await this.client
        .from("sync_lapse")
        .select("at")
        .eq("user_id", this.userId)
        .eq("programme_code", this.programmeCode)
        .order("at", { ascending: false })
        .limit(1),
    );
    return row === null ? null : String(row.at);
  }
}
