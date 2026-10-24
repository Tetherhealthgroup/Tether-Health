import { readFileSync } from "node:fs";
import { join } from "node:path";
import { CODE_PATTERN, OPTION_CODES, slug } from "./option-codes";
import { programmeRoute, PROGRAMME_ROUTES } from "./programme-data.routes";
import {
  ENTRY_COMPARED,
  METRICS,
  OBSERVATION_COMPARED,
  type Draft,
} from "./programme-records";

const MIGRATION = readFileSync(
  join(
    __dirname,
    "..",
    "..",
    "..",
    "..",
    "supabase",
    "migrations",
    "202610180013_programme_records.sql",
  ),
  "utf8",
);

const AT = "2026-10-22T08:30:00Z";

/** Every route with a full body and the draft it must produce. */
const cases: [string, object, Draft][] = [
  [
    "hw/readings",
    { systolic: 132, diastolic: 84, pulse: 70, measuredAt: AT },
    {
      entry: null,
      observations: [
        { metric: "bp_systolic", value: 132, attributes: {}, effectiveAt: AT },
        { metric: "bp_diastolic", value: 84, attributes: {}, effectiveAt: AT },
        { metric: "heart_rate", value: 70, attributes: {}, effectiveAt: AT },
      ],
    },
  ],
  [
    "hw/lipids",
    {
      total: 212,
      ldl: 138.5,
      hdl: 46,
      triglycerides: 150,
      labDate: "2026-09-30",
    },
    {
      entry: null,
      observations: [
        ["chol_total", 212],
        ["chol_ldl", 138.5],
        ["chol_hdl", 46],
        ["triglycerides", 150],
      ].map(([metric, value]) => ({
        metric: metric as never,
        value: value as number,
        attributes: {},
        effectiveAt: "2026-09-30T00:00:00Z",
      })),
    },
  ],
  [
    "st/readings",
    {
      reading: 142,
      when: "2_h_after_meal",
      feelings: ["fine"],
      note: "Synthetic note",
    },
    {
      entry: null,
      observations: [
        {
          metric: "glucose",
          value: 142,
          attributes: {
            timing: "2_h_after_meal",
            feelings: ["fine"],
            note: "Synthetic note",
          },
          effectiveAt: null,
        },
      ],
    },
  ],
  [
    "st/a1c",
    { a1c: 7.4, labDate: "2026-10-01" },
    {
      entry: null,
      observations: [
        {
          metric: "a1c",
          value: 7.4,
          attributes: {},
          effectiveAt: "2026-10-01T00:00:00Z",
        },
      ],
    },
  ],
  [
    "re/labs",
    { egfr: 58, urineAcr: 42, alt: 30, labDate: "2026-10-03" },
    {
      entry: null,
      observations: [
        ["egfr", 58],
        ["urine_acr", 42],
        ["alt", 30],
      ].map(([metric, value]) => ({
        metric: metric as never,
        value: value as number,
        attributes: {},
        effectiveAt: "2026-10-03T00:00:00Z",
      })),
    },
  ],
  [
    "ca/zone-checks",
    { zone: "yellow", symptoms: ["wheezing"], peakFlow: 310, checkedAt: AT },
    {
      entry: {
        kind: "ca.zone_check",
        payload: { zone: "yellow", symptoms: ["wheezing"] },
        occurredAt: AT,
      },
      observations: [
        { metric: "peak_flow", value: 310, attributes: {}, effectiveAt: AT },
      ],
    },
  ],
  [
    "ca/symptoms",
    {
      symptoms: ["wheezing"],
      severity: "mild",
      triggers: ["cold_air"],
      note: "Synthetic",
      occurredAt: AT,
    },
    {
      entry: {
        kind: "ca.symptom",
        payload: {
          symptoms: ["wheezing"],
          severity: "mild",
          triggers: ["cold_air"],
          note: "Synthetic",
        },
        occurredAt: AT,
      },
      observations: [],
    },
  ],
  [
    "ea/moods",
    { mood: "low", topics: ["work", "sleep"] },
    {
      entry: {
        kind: "ea.mood",
        payload: { mood: "low", topics: ["work", "sleep"] },
        occurredAt: null,
      },
      observations: [],
    },
  ],
  [
    "ea/check-backs",
    { change: "same", reachedOut: "not_yet" },
    {
      entry: {
        kind: "ea.check_back",
        payload: { change: "same", reached_out: "not_yet" },
        occurredAt: null,
      },
      observations: [],
    },
  ],
  [
    "sd/sessions",
    { settings: ["audio_on"] },
    {
      entry: {
        kind: "sd.session",
        payload: { settings: ["audio_on"] },
        occurredAt: null,
      },
      observations: [],
    },
  ],
  [
    "sd/falls",
    {},
    {
      entry: { kind: "sd.fall", payload: {}, occurredAt: null },
      observations: [],
    },
  ],
  [
    "sf/pauses",
    { reason: "bored" },
    {
      entry: {
        kind: "sf.pause",
        payload: { reason: "bored" },
        occurredAt: null,
      },
      observations: [],
    },
  ],
  [
    "ck/done",
    { item: "flu_vaccine", doneOn: "2026-10-12", place: "Synthetic Pharmacy" },
    {
      entry: {
        kind: "ck.done",
        payload: {
          item: "flu_vaccine",
          done_on: "2026-10-12",
          place: "Synthetic Pharmacy",
        },
        occurredAt: null,
      },
      observations: [],
    },
  ],
  [
    "be/diary",
    { fatigue: 6, symptoms: ["nausea"] },
    {
      entry: {
        kind: "be.diary",
        payload: { fatigue: 6, symptoms: ["nausea"] },
        occurredAt: null,
      },
      observations: [],
    },
  ],
  [
    "be/survivorship",
    { feeling: "mixed" },
    {
      entry: {
        kind: "be.survivorship",
        payload: { feeling: "mixed" },
        occurredAt: null,
      },
      observations: [],
    },
  ],
];

const routeFor = (name: string) => {
  const [code, kind] = name.split("/") as [string, string];
  const route = programmeRoute(code, kind);
  if (!route) throw new Error(`no route ${name}`);
  return route;
};

describe("programme event mapping", () => {
  it("covers every route once", () => {
    expect(cases.map(([name]) => name).sort()).toEqual(
      PROGRAMME_ROUTES.map((route) => `${route.code}/${route.kind}`).sort(),
    );
  });

  it.each(cases)("%s writes the tabled rows", (name, body, expected) => {
    expect(routeFor(name).build(body)).toEqual(expected);
  });

  it("omits optional fields that are absent (no null, no empty key)", () => {
    expect(
      routeFor("hw/readings").build({ systolic: 120, diastolic: 80 }),
    ).toEqual({
      entry: null,
      observations: [
        {
          metric: "bp_systolic",
          value: 120,
          attributes: {},
          effectiveAt: null,
        },
        {
          metric: "bp_diastolic",
          value: 80,
          attributes: {},
          effectiveAt: null,
        },
      ],
    });
    expect(routeFor("ca/zone-checks").build({ zone: "green" })).toEqual({
      entry: {
        kind: "ca.zone_check",
        payload: { zone: "green" },
        occurredAt: null,
      },
      observations: [],
    });
    expect(
      routeFor("hw/lipids").build({ hdl: 50, labDate: "2026-01-02" }),
    ).toEqual({
      entry: null,
      observations: [
        {
          metric: "chol_hdl",
          value: 50,
          attributes: {},
          effectiveAt: "2026-01-02T00:00:00Z",
        },
      ],
    });
  });

  it("an unknown pair has no route", () => {
    expect(programmeRoute("hw", "moods")).toBeUndefined();
    expect(programmeRoute("bf", "readings")).toBeUndefined();
    expect(programmeRoute("hw", "targets")).toBeUndefined();
  });

  describe("parity with migration 202610180013", () => {
    it("each metric's unit and programme are allowed by observations_metric_check", () => {
      const check =
        /constraint observations_metric_check check \(([\s\S]*?)\n\s*\)\n\);/.exec(
          MIGRATION,
        )?.[1];
      expect(check).toBeDefined();
      const clauses = [
        ...(check ?? "").matchAll(
          /\(metric (?:in \(([^)]*)\)|= '([^']+)')\s+and unit_ucum = '([^']+)' and programme_code = '([^']+)'\)/g,
        ),
      ];
      const allowed = new Map<string, string>();
      for (const [, list, single, unit, programme] of clauses) {
        const metrics = list
          ? [...list.matchAll(/'([^']+)'/g)].map((m) => m[1])
          : [single];
        for (const metric of metrics)
          allowed.set(metric as string, `${unit} ${programme}`);
      }
      expect(Object.fromEntries(allowed)).toEqual(
        Object.fromEntries(
          Object.entries(METRICS).map(([metric, { unit, programme }]) => [
            metric,
            `${unit} ${programme}`,
          ]),
        ),
      );
    });

    it("every entry payload uses only the trigger's keys and has its required keys", () => {
      const specs = new Map<string, { keys: string[]; required: string[] }>();
      for (const match of MIGRATION.matchAll(
        /when '([a-z._]+)' then\s+spec := '(\{[^']*\})';(?:\s+required := array\[([^\]]*)\];)?/g,
      )) {
        specs.set(match[1] as string, {
          keys: Object.keys(JSON.parse(match[2] as string) as object),
          required: [...(match[3] ?? "").matchAll(/'([^']+)'/g)].map(
            (m) => m[1] as string,
          ),
        });
      }
      for (const [name, body] of cases) {
        const draft = routeFor(name).build(body);
        if (!draft.entry) continue;
        const spec = specs.get(draft.entry.kind);
        expect(spec).toBeDefined();
        const keys = Object.keys(draft.entry.payload);
        expect(spec?.keys).toEqual(expect.arrayContaining(keys));
        expect(keys).toEqual(expect.arrayContaining(spec?.required ?? []));
      }
    });

    /** The column names of `table` in the migration, in order. */
    const columnsOf = (table: string) => {
      const block = new RegExp(
        `create table public\\.${table} \\(\\n([\\s\\S]*?)\\n\\);`,
      ).exec(MIGRATION)?.[1];
      expect(block).toBeDefined();
      return (block ?? "")
        .split("\n")
        .map((line) => /^ {2}([a-z_]+) [a-z]/.exec(line)?.[1])
        .filter(
          (name): name is string => name !== undefined && name !== "constraint",
        );
    };

    it.each([
      ["programme_entries", ENTRY_COMPARED, ["occurred_at"]],
      ["observations", OBSERVATION_COMPARED, ["effective_at"]],
    ] as const)(
      "%s: a replay compares every column except times, id and submission_id",
      (table, compared, times) => {
        const columns = columnsOf(table);
        expect(columns).toEqual(
          expect.arrayContaining([
            "id",
            "submission_id",
            "created_at",
            ...times,
          ]),
        );
        const excluded = new Set<string>([
          "id",
          "submission_id",
          "created_at",
          ...times,
        ]);
        expect([...compared].sort()).toEqual(
          columns.filter((column) => !excluded.has(column)).sort(),
        );
      },
    );

    it("every option code matches the database's code pattern", () => {
      for (const codes of Object.values(OPTION_CODES)) {
        for (const code of codes) expect(code).toMatch(CODE_PATTERN);
      }
    });
  });
});

describe("slug", () => {
  it.each([
    ["Very low", "very_low"],
    ["2 h after meal", "2_h_after_meal"],
    ["Can’t sleep", "can_t_sleep"],
    ["I don’t want to", "i_don_t_want_to"],
    ["Yes, I have an appointment", "yes_i_have_an_appointment"],
    ["  --Spaced -- out!! ", "spaced_out"],
    ["Café au lait", "caf_au_lait"],
    ["a".repeat(39) + " b c", "a".repeat(39)],
    ["x".repeat(45), "x".repeat(40)],
  ])("%j -> %j", (label, code) => {
    expect(slug(label)).toBe(code);
  });
});
