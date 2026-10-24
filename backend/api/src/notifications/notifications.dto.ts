import { IsBoolean, ValidateBy } from "class-validator";
import { IsPresentOptional } from "../programme-data/validators";
import { PROGRAMME_CODE } from "../records-events/records-access";

/**
 * The stored defaults of public.notification_preferences (migration
 * 202610180013): a member who never saved sees these, with reminders off
 * until they turn them on. The parity test reads them from the migration.
 */
export const NOTIFICATION_DEFAULTS = {
  remindersEnabled: false,
  sensitiveDetails: false,
  quietHoursEnabled: true,
} as const;

/** A daily time, 00:00 to 23:59. */
export const REMIND_AT = /^([01][0-9]|2[0-3]):[0-5][0-9]$/;
/** At most one reminder per programme; there are eleven programmes. */
export const MAX_REMINDERS = 11;

export interface ProgrammeReminder {
  programme: string;
  remindAt: string;
}

/**
 * A list of `{programme, remindAt}` objects with exactly those two keys,
 * each programme at most once.
 */
export function isProgrammeReminders(value: unknown): boolean {
  if (!Array.isArray(value) || value.length > MAX_REMINDERS) return false;
  const seen = new Set<string>();
  return value.every((item: unknown) => {
    if (item === null || typeof item !== "object" || Array.isArray(item)) {
      return false;
    }
    const keys = Reflect.ownKeys(item);
    if (
      keys.length !== 2 ||
      !keys.includes("programme") ||
      !keys.includes("remindAt")
    ) {
      return false;
    }
    const { programme, remindAt } = item as Record<string, unknown>;
    if (
      typeof programme !== "string" ||
      !PROGRAMME_CODE.test(programme) ||
      typeof remindAt !== "string" ||
      !REMIND_AT.test(remindAt) ||
      seen.has(programme)
    ) {
      return false;
    }
    seen.add(programme);
    return true;
  });
}

/** Only the fields present change. */
export class PatchNotificationPreferencesDto {
  @IsPresentOptional()
  @IsBoolean()
  remindersEnabled?: boolean;

  @IsPresentOptional()
  @IsBoolean()
  sensitiveDetails?: boolean;

  @IsPresentOptional()
  @IsBoolean()
  quietHoursEnabled?: boolean;

  @IsPresentOptional()
  @ValidateBy({
    name: "isProgrammeReminders",
    validator: { validate: (value: unknown) => isProgrammeReminders(value) },
  })
  programmeReminders?: ProgrammeReminder[];
}
export const PREFERENCE_FIELDS = [
  "remindersEnabled",
  "sensitiveDetails",
  "quietHoursEnabled",
  "programmeReminders",
];

export interface NotificationPreferences {
  remindersEnabled: boolean;
  sensitiveDetails: boolean;
  quietHoursEnabled: boolean;
  /** False when the member never saved (the values are the defaults). */
  persisted: boolean;
  programmeReminders: ProgrammeReminder[];
}
