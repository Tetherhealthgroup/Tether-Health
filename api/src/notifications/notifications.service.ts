import { Injectable, Logger } from "@nestjs/common";
import type { PostgrestError } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { DatabaseErrorCode } from "../common/database-errors";
import {
  UserSupabaseClientFactory,
  type UserSupabaseClient,
} from "../enrolments/user-supabase-client";
import { insertErrorFor } from "../programme-data/programme-data-errors";
import { present, type Row } from "../programme-data/programme-records";
import {
  parseBody,
  requireBarrierOpen,
  requireWritableEnrolment,
  unavailable,
} from "../records-events/records-access";
import {
  NOTIFICATION_DEFAULTS,
  PREFERENCE_FIELDS,
  PatchNotificationPreferencesDto,
  type NotificationPreferences,
} from "./notifications.dto";

/** The route as logged. */
export const PREFERENCES_ROUTE = "/v1/notifications/preferences";

type Write = PromiseLike<{ data: unknown; error: PostgrestError | null }>;

/**
 * Notification preferences. Account switches live in
 * notification_preferences; each programme's reminder time in
 * programme_reminders. Whether a reminder fires is that programme's
 * reminders consent, not these rows. Last write wins.
 */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private readonly clients: UserSupabaseClientFactory) {}

  /** The stored state, or the stored defaults with `persisted: false`. */
  async get(
    user: AuthUser,
    requestId: string,
    client: UserSupabaseClient = this.clients.forUser(user),
  ): Promise<NotificationPreferences> {
    const fail = (code: string | undefined): never =>
      unavailable(this.logger, requestId, PREFERENCES_ROUTE, code);
    const [switches, reminders] = await Promise.all([
      client
        .from("notification_preferences")
        .select("reminders_enabled,sensitive_details,quiet_hours_enabled")
        .eq("user_id", user.id)
        .maybeSingle<Row>(),
      client
        .from("programme_reminders")
        .select("programme_code,remind_at")
        .eq("user_id", user.id)
        .order("programme_code", { ascending: true })
        .returns<Row[]>(),
    ]);
    if (switches.error) fail(switches.error.code);
    if (reminders.error || reminders.data === null) {
      return fail(reminders.error?.code);
    }
    const stored = switches.data;
    return {
      ...(stored === null
        ? { ...NOTIFICATION_DEFAULTS, persisted: false }
        : {
            remindersEnabled: stored.reminders_enabled === true,
            sensitiveDetails: stored.sensitive_details === true,
            quietHoursEnabled: stored.quiet_hours_enabled === true,
            persisted: true,
          }),
      programmeReminders: reminders.data.map((row) => ({
        programme: String(row.programme_code),
        remindAt: String(row.remind_at).slice(0, 5),
      })),
    };
  }

  /**
   * Changes only the fields present: the account switches are written
   * together (update, else insert); each reminder is written for the
   * caller's enrolment in its programme after the write pre-checks (not
   * enrolled 404, left 409, no live core consent 409). A reminder time can
   * be changed, never cleared. Returns the state after the writes.
   */
  async patch(
    user: AuthUser,
    rawBody: unknown,
    requestId: string,
  ): Promise<NotificationPreferences> {
    const body = await parseBody(
      rawBody,
      PatchNotificationPreferencesDto,
      PREFERENCE_FIELDS,
    );
    const client = this.clients.forUser(user);
    await requireBarrierOpen(client);
    const reminders = [];
    for (const reminder of body.programmeReminders ?? []) {
      reminders.push({
        ...reminder,
        enrolmentId: await requireWritableEnrolment(
          client,
          user.id,
          reminder.programme,
        ),
      });
    }

    const switches = present({
      reminders_enabled: body.remindersEnabled,
      sensitive_details: body.sensitiveDetails,
      quiet_hours_enabled: body.quietHoursEnabled,
    });
    if (Object.keys(switches).length > 0) {
      await this.save(
        requestId,
        () =>
          client
            .from("notification_preferences")
            .update(switches)
            .eq("user_id", user.id)
            .select("user_id"),
        () =>
          client
            .from("notification_preferences")
            .insert([{ user_id: user.id, ...switches }]),
      );
    }
    for (const reminder of reminders) {
      const remindAt = `${reminder.remindAt}:00`;
      await this.save(
        requestId,
        () =>
          client
            .from("programme_reminders")
            .update({ remind_at: remindAt })
            .eq("user_id", user.id)
            .eq("enrolment_id", reminder.enrolmentId)
            .select("enrolment_id"),
        () =>
          client.from("programme_reminders").insert([
            {
              user_id: user.id,
              enrolment_id: reminder.enrolmentId,
              programme_code: reminder.programme,
              remind_at: remindAt,
            },
          ]),
      );
    }
    return this.get(user, requestId, client);
  }

  /**
   * Update the caller's row; when none exists, insert it; when a
   * concurrent insert won (23505), update once more.
   */
  private async save(
    requestId: string,
    update: () => Write,
    insert: () => Write,
  ): Promise<void> {
    const updated = async (): Promise<boolean> => {
      const { data, error } = await update();
      if (error) this.refused(requestId, error.code);
      return Array.isArray(data) && data.length > 0;
    };
    if (await updated()) return;
    const { error } = await insert();
    if (!error) return;
    if (error.code === DatabaseErrorCode.uniqueViolation && (await updated())) {
      return;
    }
    this.refused(requestId, error.code);
  }

  private refused(requestId: string, code: string | undefined): never {
    const mapped =
      code === DatabaseErrorCode.uniqueViolation ? null : insertErrorFor(code);
    if (mapped) throw mapped;
    return unavailable(this.logger, requestId, PREFERENCES_ROUTE, code);
  }
}
