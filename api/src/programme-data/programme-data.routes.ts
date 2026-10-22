import {
  BeDiaryDto,
  BeSurvivorshipDto,
  CaSymptomsDto,
  CaZoneChecksDto,
  CkDoneDto,
  EaCheckBacksDto,
  EaMoodsDto,
  HwLipidsDto,
  HwReadingsDto,
  ReLabsDto,
  SdFallsDto,
  SdSessionsDto,
  SfPausesDto,
  StA1cDto,
  StReadingsDto,
} from "./programme-data.dto";
import { OPTION_CODES, ZONES } from "./option-codes";
import {
  labDateTime,
  present,
  type Draft,
  type Metric,
  type ObservationDraft,
} from "./programme-records";

/**
 * The fifteen programme event routes, `POST /v1/program-data/:code/:kind`.
 * Any other pair is not a route (404). The programme is the route's, never
 * the body's: each submit writes only into the caller's enrolment in that
 * programme.
 */
export interface ProgrammeRoute<T extends object = any> {
  code: string;
  kind: string;
  dto: new () => T;
  /** The spec screen that submits to this route (endpoints.json). */
  screen: string;
  /**
   * Every body field, with the screen input it carries (`<key>` on
   * `screen`), or null for a field that is not a screen input.
   */
  fields: Readonly<Record<string, string | null>>;
  /** Body fields whose values are option codes, with their codes. */
  options: Readonly<Record<string, readonly string[]>>;
  /** At least one of these fields must be present. */
  atLeastOne?: readonly string[];
  build(body: T): Draft;
}

const observations = (
  values: Partial<Record<Metric, number | undefined>>,
  effectiveAt: string | null,
): ObservationDraft[] =>
  Object.entries(values)
    .filter((entry): entry is [Metric, number] => entry[1] !== undefined)
    .map(([metric, value]) => ({
      metric,
      value,
      attributes: {},
      effectiveAt,
    }));

const entry = (
  kind: string,
  payload: Record<string, unknown>,
  occurredAt: string | undefined,
): Draft => ({
  entry: { kind, payload: present(payload), occurredAt: occurredAt ?? null },
  observations: [],
});

const route = <T extends object>(spec: ProgrammeRoute<T>) => spec;

export const PROGRAMME_ROUTES: readonly ProgrammeRoute[] = [
  route({
    code: "hw",
    kind: "readings",
    dto: HwReadingsDto,
    screen: "hw_log2",
    fields: {
      systolic: "systolic",
      diastolic: "diastolic",
      pulse: "pulse_optional",
      measuredAt: null,
    },
    options: {},
    build: (body) => ({
      entry: null,
      observations: observations(
        {
          bp_systolic: body.systolic,
          bp_diastolic: body.diastolic,
          heart_rate: body.pulse,
        },
        body.measuredAt ?? null,
      ),
    }),
  }),
  route({
    code: "hw",
    kind: "lipids",
    dto: HwLipidsDto,
    screen: "hw_lipids",
    fields: {
      total: "total",
      ldl: "ldl",
      hdl: "hdl",
      triglycerides: "triglycerides",
      labDate: "lab_date",
    },
    options: {},
    atLeastOne: ["total", "ldl", "hdl", "triglycerides"],
    build: (body) => ({
      entry: null,
      observations: observations(
        {
          chol_total: body.total,
          chol_ldl: body.ldl,
          chol_hdl: body.hdl,
          triglycerides: body.triglycerides,
        },
        labDateTime(body.labDate),
      ),
    }),
  }),
  route({
    code: "st",
    kind: "readings",
    dto: StReadingsDto,
    screen: "st_log",
    fields: {
      reading: "reading",
      when: "when",
      feelings: "how_do_you_feel",
      note: "note_optional",
      measuredAt: null,
    },
    options: {
      when: OPTION_CODES.glucoseTiming,
      feelings: OPTION_CODES.glucoseFeelings,
    },
    build: (body) => ({
      entry: null,
      observations: [
        {
          metric: "glucose",
          value: body.reading,
          attributes: present({
            timing: body.when,
            feelings: body.feelings,
            note: body.note,
          }),
          effectiveAt: body.measuredAt ?? null,
        },
      ],
    }),
  }),
  route({
    code: "st",
    kind: "a1c",
    dto: StA1cDto,
    screen: "st_a1c",
    fields: { a1c: "a1c", labDate: "lab_date" },
    options: {},
    build: (body) => ({
      entry: null,
      observations: observations({ a1c: body.a1c }, labDateTime(body.labDate)),
    }),
  }),
  route({
    code: "re",
    kind: "labs",
    dto: ReLabsDto,
    screen: "re_labs",
    fields: {
      egfr: "egfr",
      urineAcr: "urine_acr",
      alt: "alt_liver",
      labDate: "lab_date",
    },
    options: {},
    atLeastOne: ["egfr", "urineAcr", "alt"],
    build: (body) => ({
      entry: null,
      observations: observations(
        { egfr: body.egfr, urine_acr: body.urineAcr, alt: body.alt },
        labDateTime(body.labDate),
      ),
    }),
  }),
  route({
    code: "ca",
    kind: "zone-checks",
    dto: CaZoneChecksDto,
    screen: "ca_zone",
    fields: {
      zone: null,
      symptoms: "symptoms",
      peakFlow: "peak_flow",
      checkedAt: null,
    },
    options: { zone: ZONES, symptoms: OPTION_CODES.zoneSymptoms },
    build: (body) => ({
      entry: {
        kind: "ca.zone_check",
        payload: present({ zone: body.zone, symptoms: body.symptoms }),
        occurredAt: body.checkedAt ?? null,
      },
      observations: observations(
        { peak_flow: body.peakFlow },
        body.checkedAt ?? null,
      ),
    }),
  }),
  route({
    code: "ca",
    kind: "symptoms",
    dto: CaSymptomsDto,
    screen: "ca_symptoms",
    fields: {
      symptoms: "value",
      severity: "how_bad",
      triggers: "possible_trigger",
      note: "note_optional",
      occurredAt: null,
    },
    options: {
      symptoms: OPTION_CODES.caSymptoms,
      severity: OPTION_CODES.caSeverity,
      triggers: OPTION_CODES.caTriggers,
    },
    build: (body) =>
      entry(
        "ca.symptom",
        {
          symptoms: body.symptoms,
          severity: body.severity,
          triggers: body.triggers,
          note: body.note,
        },
        body.occurredAt,
      ),
  }),
  route({
    code: "ea",
    kind: "moods",
    dto: EaMoodsDto,
    screen: "ea_mood",
    fields: {
      mood: "how_are_you_right_now",
      topics: "going_on",
      occurredAt: null,
    },
    options: { mood: OPTION_CODES.mood, topics: OPTION_CODES.moodTopics },
    build: (body) =>
      entry(
        "ea.mood",
        { mood: body.mood, topics: body.topics },
        body.occurredAt,
      ),
  }),
  route({
    code: "ea",
    kind: "check-backs",
    dto: EaCheckBacksDto,
    screen: "ea_checkback",
    fields: {
      change: "value",
      reachedOut: "did_you_reach_out_to_someone",
      occurredAt: null,
    },
    options: {
      change: OPTION_CODES.checkBackChange,
      reachedOut: OPTION_CODES.reachedOut,
    },
    build: (body) =>
      entry(
        "ea.check_back",
        { change: body.change, reached_out: body.reachedOut },
        body.occurredAt,
      ),
  }),
  route({
    code: "sd",
    kind: "sessions",
    dto: SdSessionsDto,
    screen: "sd_session",
    fields: { settings: "value", occurredAt: null },
    options: { settings: OPTION_CODES.sessionSettings },
    build: (body) =>
      entry("sd.session", { settings: body.settings }, body.occurredAt),
  }),
  route({
    code: "sd",
    kind: "falls",
    dto: SdFallsDto,
    screen: "sd_fell",
    fields: { occurredAt: null },
    options: {},
    build: (body) => entry("sd.fall", {}, body.occurredAt),
  }),
  route({
    code: "sf",
    kind: "pauses",
    dto: SfPausesDto,
    screen: "sf_pause",
    fields: { reason: "value", occurredAt: null },
    options: { reason: OPTION_CODES.pauseReason },
    build: (body) =>
      entry("sf.pause", { reason: body.reason }, body.occurredAt),
  }),
  route({
    code: "ck",
    kind: "done",
    dto: CkDoneDto,
    screen: "ck_done",
    fields: {
      item: "what",
      doneOn: "date",
      place: "where_optional",
      occurredAt: null,
    },
    options: {},
    build: (body) =>
      entry(
        "ck.done",
        { item: body.item, done_on: body.doneOn, place: body.place },
        body.occurredAt,
      ),
  }),
  route({
    code: "be",
    kind: "diary",
    dto: BeDiaryDto,
    screen: "be_diary",
    fields: { fatigue: "fatigue", symptoms: "anything_else", occurredAt: null },
    options: { symptoms: OPTION_CODES.diarySymptoms },
    build: (body) =>
      entry(
        "be.diary",
        { fatigue: body.fatigue, symptoms: body.symptoms },
        body.occurredAt,
      ),
  }),
  route({
    code: "be",
    kind: "survivorship",
    dto: BeSurvivorshipDto,
    screen: "be_survivor",
    fields: { feeling: "value", occurredAt: null },
    options: { feeling: OPTION_CODES.survivorshipFeeling },
    build: (body) =>
      entry("be.survivorship", { feeling: body.feeling }, body.occurredAt),
  }),
];

/** The route for a `:code/:kind` pair, or undefined when there is none. */
export function programmeRoute(
  code: string,
  kind: string,
): ProgrammeRoute | undefined {
  return PROGRAMME_ROUTES.find(
    (candidate) => candidate.code === code && candidate.kind === kind,
  );
}

/** `code/kind`, as the spec's endpoint names a route. */
export const routeName = (route: ProgrammeRoute) =>
  `${route.code}/${route.kind}`;
