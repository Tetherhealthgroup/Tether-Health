import type { DayWindow } from "./day-window";
import type { ProgrammeReader } from "./programme-reader";

type Row = Record<string, unknown>;

/** A measurement as Today shows it. */
export interface Measurement {
  value: number;
  at: string;
}

const measurement = (row: Row | null): Measurement | null =>
  row === null
    ? null
    : { value: Number(row.value), at: String(row.effective_at) };

const payloadOf = (row: Row): Row => (row.payload ?? {}) as Row;

/**
 * The fixed fields of each programme's Today block, built only through
 * that programme's reader. A programme not listed has no extra fields.
 */
export const PROGRAMME_FIELDS: Record<
  string,
  (reader: ProgrammeReader, window: DayWindow) => Promise<Row>
> = {
  hw: async (reader) => {
    const systolic = await reader.latestObservation("bp_systolic");
    if (systolic === null) return { lastBp: null };
    const submission = String(systolic.submission_id);
    const [diastolic, pulse] = await Promise.all([
      reader.observationOf("bp_diastolic", submission),
      reader.observationOf("heart_rate", submission),
    ]);
    return {
      lastBp: {
        systolic: Number(systolic.value),
        diastolic: diastolic === null ? null : Number(diastolic.value),
        pulse: pulse === null ? null : Number(pulse.value),
        at: String(systolic.effective_at),
      },
    };
  },
  st: async (reader) => {
    const [glucose, a1c] = await Promise.all([
      reader.latestObservation("glucose"),
      reader.latestObservation("a1c"),
    ]);
    return { lastGlucose: measurement(glucose), lastA1c: measurement(a1c) };
  },
  re: async (reader) => {
    const [egfr, urineAcr, alt] = await Promise.all([
      reader.latestObservation("egfr"),
      reader.latestObservation("urine_acr"),
      reader.latestObservation("alt"),
    ]);
    return {
      lastLabs: {
        egfr: measurement(egfr),
        urineAcr: measurement(urineAcr),
        alt: measurement(alt),
      },
    };
  },
  ca: async (reader) => {
    const entry = await reader.latestEntry("ca.zone_check");
    return {
      lastZoneCheck:
        entry === null
          ? null
          : { zone: payloadOf(entry).zone, at: String(entry.occurred_at) },
    };
  },
  ea: async (reader) => {
    const entry = await reader.latestEntry("ea.mood");
    return {
      lastMood:
        entry === null
          ? null
          : { mood: payloadOf(entry).mood, at: String(entry.occurred_at) },
    };
  },
  sd: async (reader, window) => {
    const [sessions, fall] = await Promise.all([
      reader.countEntries("sd.session", window.last7Start),
      reader.latestEntry("sd.fall"),
    ]);
    return {
      sessionsLast7Days: sessions,
      lastFallAt: fall === null ? null : String(fall.occurred_at),
    };
  },
  sf: async (reader, window) => {
    const [pauses, lapses] = await Promise.all([
      reader.countEntries("sf.pause", window.todayStart, window.tomorrowStart),
      reader.countLapses(window.last7Start),
    ]);
    return { pausesToday: pauses, lapsesLast7Days: lapses };
  },
  ck: async (reader) => {
    const entry = await reader.latestEntry("ck.done");
    return {
      lastDone:
        entry === null
          ? null
          : {
              item: payloadOf(entry).item,
              doneOn: payloadOf(entry).done_on,
              at: String(entry.occurred_at),
            },
    };
  },
  be: async (reader) => {
    const entry = await reader.latestEntry("be.diary");
    return {
      lastDiary:
        entry === null
          ? null
          : {
              fatigue: payloadOf(entry).fatigue,
              at: String(entry.occurred_at),
            },
    };
  },
  bf: async (reader, window) => {
    const [lapses, lastLapseAt, rescue] = await Promise.all([
      reader.countLapses(window.last7Start),
      reader.lastLapseAt(),
      reader.lastHelpfulRescue(),
    ]);
    return {
      lapsesLast7Days: lapses,
      lastLapseAt,
      lastHelpfulRescue:
        rescue === null
          ? null
          : { tool: String(rescue.tool), at: String(rescue.opened_at) },
    };
  },
};
