/**
 * The member's calendar day in their time zone (profiles.time_zone).
 * A missing or unknown zone is UTC.
 */

const DAY_MS = 24 * 60 * 60 * 1000;

/** The zone if the runtime knows it, else UTC. */
export function effectiveTimeZone(zone: unknown): string {
  if (typeof zone !== "string" || zone === "") return "UTC";
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: zone });
    return zone;
  } catch {
    return "UTC";
  }
}

interface Parts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

function partsIn(zone: string, instant: number): Parts {
  const formatted = new Intl.DateTimeFormat("en-US", {
    timeZone: zone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(new Date(instant));
  const get = (type: string) =>
    Number(formatted.find((part) => part.type === type)?.value);
  return {
    year: get("year"),
    month: get("month"),
    day: get("day"),
    hour: get("hour"),
    minute: get("minute"),
    second: get("second"),
  };
}

/** The zone's offset from UTC at `instant`, in milliseconds. */
function offsetAt(zone: string, instant: number): number {
  const p = partsIn(zone, instant);
  const asUtc = Date.UTC(
    p.year,
    p.month - 1,
    p.day,
    p.hour,
    p.minute,
    p.second,
  );
  return asUtc - Math.floor(instant / 1000) * 1000;
}

/** The local date (YYYY-MM-DD) in `zone` at `instant`. */
export function localDate(zone: string, instant: number): string {
  const p = partsIn(zone, instant);
  return `${String(p.year).padStart(4, "0")}-${String(p.month).padStart(2, "0")}-${String(p.day).padStart(2, "0")}`;
}

/** The instant the local date `date` (YYYY-MM-DD) begins in `zone`. */
export function startOfLocalDate(zone: string, date: string): number {
  const [year, month, day] = date.split("-").map(Number) as [
    number,
    number,
    number,
  ];
  const midnightUtc = Date.UTC(year, month - 1, day);
  // Two passes settle the offset across a daylight-saving change.
  let instant = midnightUtc - offsetAt(zone, midnightUtc);
  instant = midnightUtc - offsetAt(zone, instant);
  return instant;
}

/** `date` plus `days` calendar days. */
export function addDays(date: string, days: number): string {
  const [year, month, day] = date.split("-").map(Number) as [
    number,
    number,
    number,
  ];
  return new Date(Date.UTC(year, month - 1, day) + days * DAY_MS)
    .toISOString()
    .slice(0, 10);
}

export interface DayWindow {
  zone: string;
  /** Today's local date. */
  date: string;
  /** Start of today (inclusive), RFC 3339 UTC. */
  todayStart: string;
  /** Start of tomorrow (exclusive), RFC 3339 UTC. */
  tomorrowStart: string;
  /** Start of the local day six days before today: the last 7 days. */
  last7Start: string;
}

export function dayWindow(zone: unknown, now = Date.now()): DayWindow {
  const effective = effectiveTimeZone(zone);
  const date = localDate(effective, now);
  const iso = (day: string) =>
    new Date(startOfLocalDate(effective, day)).toISOString();
  return {
    zone: effective,
    date,
    todayStart: iso(date),
    tomorrowStart: iso(addDays(date, 1)),
    last7Start: iso(addDays(date, -6)),
  };
}
