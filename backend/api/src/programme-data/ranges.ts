/**
 * Ranges from specs-and-design/tether_ui/spec/rules.json. A rule's range applies to an API
 * field only where the rule's `inputs` name the screen input that field
 * carries; every other numeric field has only the database's bound. The API
 * invents no clinical range. The parity test reads rules.json and fails if a
 * range, a parameter or an input list here differs from it, or if a rule
 * that reads one of these routes' screens is missing.
 */
export interface FieldRange {
  /** `code/kind` of the route. */
  route: string;
  field: string;
  /** The `<screen>.<key>` input the field carries. */
  input: string;
  minParam: string;
  maxParam: string;
  min: number;
  max: number;
}

export interface SpecRule {
  rule: string;
  inputs: readonly string[];
  ranges: readonly FieldRange[];
}

export const SPEC_RULES: readonly SpecRule[] = [
  {
    rule: "hw.bp",
    inputs: [
      "hw_log.systolic",
      "hw_log.diastolic",
      "hw_log2.systolic",
      "hw_log2.diastolic",
    ],
    ranges: [
      {
        route: "hw/readings",
        field: "systolic",
        input: "hw_log2.systolic",
        minParam: "sys_min",
        maxParam: "sys_max",
        min: 70,
        max: 250,
      },
      {
        route: "hw/readings",
        field: "diastolic",
        input: "hw_log2.diastolic",
        minParam: "dia_min",
        maxParam: "dia_max",
        min: 40,
        max: 150,
      },
    ],
  },
  {
    rule: "st.glucose",
    inputs: ["st_log.reading", "st_range.low"],
    ranges: [
      {
        route: "st/readings",
        field: "reading",
        input: "st_log.reading",
        minParam: "min",
        maxParam: "max",
        min: 20,
        max: 600,
      },
    ],
  },
  {
    rule: "ca.zone",
    inputs: [
      "ca_zone.peak_flow",
      "ca_zone.symptoms",
      "ca_plan.green_from",
      "ca_plan.red_below",
    ],
    ranges: [
      {
        route: "ca/zone-checks",
        field: "peakFlow",
        input: "ca_zone.peak_flow",
        minParam: "pef_min",
        maxParam: "pef_max",
        min: 50,
        max: 900,
      },
    ],
  },
  // Reads the mood topics; decides a branch on the device, no range.
  { rule: "ea.selfharm", inputs: ["ea_mood.going_on"], ranges: [] },
];

/** The ranges that apply to `route` (`code/kind`). */
export const rangesFor = (route: string): FieldRange[] =>
  SPEC_RULES.flatMap((rule) => rule.ranges).filter(
    (range) => range.route === route,
  );
