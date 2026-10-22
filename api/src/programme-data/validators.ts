import { applyDecorators } from "@nestjs/common";
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsIn,
  ValidateBy,
  ValidateIf,
} from "class-validator";

/** How far in the future an event time may be (clock skew). */
export const FUTURE_TOLERANCE_MS = 5 * 60 * 1000;
/** Earliest lab or done date. */
export const EARLIEST_DATE = "1900-01-01";
/** Most codes in one list (the database's limit). */
export const MAX_CODES = 12;

const TIMESTAMP =
  /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,6}))?(Z|[+-](\d{2}):(\d{2}))$/;
const DATE = /^(\d{4})-(\d{2})-(\d{2})$/;

/** Whether y-m-d is a real calendar date (no rollover). */
function isCalendarDate(year: number, month: number, day: number): boolean {
  const date = new Date(Date.UTC(year, month - 1, day));
  return (
    date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day
  );
}

/**
 * The instant of an RFC 3339 timestamp with an explicit offset, or null when
 * it is not one (including impossible dates such as 2026-02-30).
 */
export function parseTimestamp(value: unknown): number | null {
  if (typeof value !== "string") return null;
  const match = TIMESTAMP.exec(value);
  if (!match) return null;
  const [year, month, day, hour, minute, second] = match
    .slice(1, 7)
    .map(Number) as [number, number, number, number, number, number];
  const offsetHours = match[9] === undefined ? 0 : Number(match[9]);
  const offsetMinutes = match[10] === undefined ? 0 : Number(match[10]);
  if (
    !isCalendarDate(year, month, day) ||
    hour > 23 ||
    minute > 59 ||
    second > 59 ||
    offsetHours > 23 ||
    offsetMinutes > 59
  ) {
    return null;
  }
  const instant = Date.parse(value);
  return Number.isNaN(instant) ? null : instant;
}

/** An event time: RFC 3339, at most five minutes in the future. */
export function isEventTime(value: unknown, now = Date.now()): boolean {
  const instant = parseTimestamp(value);
  return instant !== null && instant <= now + FUTURE_TOLERANCE_MS;
}

/** Tomorrow's UTC date as YYYY-MM-DD. */
export function tomorrowUtc(now = Date.now()): string {
  return new Date(now + 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
}

/**
 * A lab or done date: a real YYYY-MM-DD date from 1900-01-01 up to
 * tomorrow's UTC date (so "today" anywhere on Earth is accepted).
 */
export function isRecordDate(value: unknown, now = Date.now()): boolean {
  if (typeof value !== "string") return false;
  const match = DATE.exec(value);
  if (!match) return false;
  const [year, month, day] = match.slice(1, 4).map(Number) as [
    number,
    number,
    number,
  ];
  // Fixed-width strings compare in date order.
  return (
    isCalendarDate(year, month, day) &&
    value >= EARLIEST_DATE &&
    value <= tomorrowUtc(now)
  );
}

/**
 * A finite number with at most three decimal places (the scale of
 * numeric(9,3)); more is refused, never rounded.
 */
export function isDecimal3(value: unknown): boolean {
  return (
    typeof value === "number" &&
    Number.isFinite(value) &&
    Number(value.toFixed(3)) === value
  );
}

/** Optional, but null is not absent: a present key must be valid. */
export const IsPresentOptional = () =>
  ValidateIf((_object: object, value: unknown) => value !== undefined);

export const IsEventTime = () =>
  ValidateBy({
    name: "isEventTime",
    validator: { validate: (value: unknown) => isEventTime(value) },
  });

export const IsRecordDate = () =>
  ValidateBy({
    name: "isRecordDate",
    validator: { validate: (value: unknown) => isRecordDate(value) },
  });

export const IsDecimal3 = () =>
  ValidateBy({
    name: "isDecimal3",
    validator: { validate: (value: unknown) => isDecimal3(value) },
  });

/** A list of distinct option codes from `options`. */
export const IsCodes = (options: readonly string[]) =>
  applyDecorators(
    IsArray(),
    ArrayMaxSize(MAX_CODES),
    ArrayUnique(),
    IsIn(options, { each: true }),
  );
