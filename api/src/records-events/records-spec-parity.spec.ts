import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import {
  AGE_RANGES,
  SLEEP_BANDS,
  STRESS_BANDS,
} from "../baseline/baseline.dto";
import { NOTIFICATION_DEFAULTS } from "../notifications/notifications.dto";
import { slug } from "../programme-data/option-codes";
import { ANSWERS, FEEL, HELPED, STRESS } from "./records-events.dto";

/**
 * Parity with the app spec (specs-and-design/tether_ui/spec) and the migrations
 * (supabase/migrations): every option list of the check-in, rescue result
 * and basics screens, the endpoints, the age bands of the latest
 * wellbeing_baseline_age_range_check and the stored notification defaults.
 * A change on either side fails here until the API follows it.
 */
const ROOT = join(__dirname, "..", "..", "..");
const SPEC = join(ROOT, "specs-and-design", "tether_ui", "spec");
const MIGRATIONS = join(ROOT, "supabase", "migrations");
const read = <T>(name: string): T =>
  JSON.parse(readFileSync(join(SPEC, name), "utf8")) as T;

interface Control {
  t?: string;
  key?: string;
  tag?: string;
  options?: string[];
  min?: number;
  max?: number;
  children?: unknown;
  [other: string]: unknown;
}

const screens =
  read<Record<string, { body?: unknown; footer?: unknown }>>("screens.json");
const endpoints =
  read<{ endpoint: string; screens: string[] }[]>("endpoints.json");

/** Every input control of a screen, with the programme tag of its card. */
function inputsOf(screenId: string): (Control & { card?: string })[] {
  const screen = screens[screenId];
  if (!screen) throw new Error(`screens.json has no ${screenId}`);
  const found: (Control & { card?: string })[] = [];
  const walk = (node: unknown, card?: string) => {
    if (Array.isArray(node)) node.forEach((child) => walk(child, card));
    else if (node !== null && typeof node === "object") {
      const control = node as Control;
      const tag = control.t === "card" ? control.tag : card;
      if (typeof control.t === "string" && typeof control.key === "string") {
        found.push({ ...control, card: tag });
      }
      Object.values(control).forEach((child) => walk(child, tag));
    }
  };
  walk([screen.body, screen.footer]);
  return found;
}

const codesOf = (options: string[] | undefined) =>
  (options ?? []).filter((label) => label !== "Skip").map(slug);

describe("records routes and the spec", () => {
  it("the spec's endpoints for these routes exist on the screens the API expects", () => {
    const wanted: Record<string, string[]> = {
      "POST /v1/records/check-ins": ["checkin"],
      "POST /v1/records/rescues": ["rescue_result"],
      "POST /v1/records/lessons": ["learn_lesson"],
      "PATCH /v1/notifications/preferences": ["account_notifications"],
    };
    for (const [endpoint, onScreens] of Object.entries(wanted)) {
      expect(
        endpoints.find((entry) => entry.endpoint === endpoint)?.screens,
      ).toEqual(onScreens);
    }
  });

  describe("checkin", () => {
    const inputs = inputsOf("checkin");

    it("has exactly the shared questions and one card per answer programme", () => {
      expect(
        inputs.map((control) => [control.key, control.card ?? null]),
      ).toEqual([
        ["how_do_you_feel_today", null],
        ["stress_today", null],
        ["value", "bf"],
        ["value_2", "sf"],
      ]);
    });

    it("feel and stress are the spec's options", () => {
      expect(codesOf(inputs[0]?.options)).toEqual([...FEEL]);
      expect(codesOf(inputs[1]?.options)).toEqual([...STRESS]);
    });

    it("each card's answers are that programme's codes, and only those programmes have answers", () => {
      const cards = inputs.filter((control) => control.card !== undefined);
      expect(cards.map((control) => control.card).sort()).toEqual(
        Object.keys(ANSWERS).sort(),
      );
      for (const card of cards) {
        expect(codesOf(card.options)).toEqual([
          ...ANSWERS[card.card as keyof typeof ANSWERS],
        ]);
      }
    });
  });

  describe("rescue_result", () => {
    const inputs = inputsOf("rescue_result");

    it("did_it_help is slug(label), with 'Not this time' as no", () => {
      const help = inputs.find((control) => control.key === "did_it_help");
      expect(help?.options).toEqual(["Yes", "A little", "Not this time"]);
      expect(
        (help?.options ?? []).map((label) =>
          label === "Not this time" ? "no" : slug(label),
        ),
      ).toEqual([...HELPED]);
    });

    it("the intensity slider is 0 to 10, as the API's bound", () => {
      const slider = inputs.find((control) => control.t === "slider");
      expect([slider?.min, slider?.max]).toEqual([0, 10]);
    });
  });

  describe("ob_basics", () => {
    const inputs = inputsOf("ob_basics");

    it("sleep labels map to the stored sleep bands", () => {
      const sleep = inputs.find(
        (control) => control.key === "sleep_on_a_typical_night",
      );
      expect(sleep?.options).toEqual(Object.keys(SLEEP_BANDS));
    });

    it("usual stress is slug(label)", () => {
      const stress = inputs.find((control) => control.key === "usual_stress");
      expect(codesOf(stress?.options)).toEqual([...STRESS_BANDS]);
    });
  });
});

describe("records routes and the migrations", () => {
  const files = readdirSync(MIGRATIONS)
    .filter((name) => name.endsWith(".sql"))
    .sort();
  const text = (name: string) => readFileSync(join(MIGRATIONS, name), "utf8");

  it("the age bands are the latest wellbeing_baseline_age_range_check list", () => {
    const definitions = files.flatMap((name) =>
      [
        ...text(name).matchAll(
          /add constraint wellbeing_baseline_age_range_check check \(age_range in \(([^)]*)\)\)/g,
        ),
      ].map((match) => match[1] as string),
    );
    const latest = definitions.at(-1);
    expect(latest).toBeDefined();
    const bands = [...(latest ?? "").matchAll(/'([^']*)'/g)].map(
      (match) => match[1],
    );
    expect([...AGE_RANGES]).toEqual(bands);
    // The latest migration that names the constraint defines the list.
    const naming = files.filter((name) =>
      text(name).includes("wellbeing_baseline_age_range_check"),
    );
    expect(
      text(naming.at(-1) as string).includes(
        "add constraint wellbeing_baseline_age_range_check check (age_range in (",
      ),
    ).toBe(true);
  });

  it("the notification defaults are the stored column defaults (reminders off)", () => {
    const table = files
      .map(text)
      .map((sql) =>
        /create table public\.notification_preferences \(([\s\S]*?)\n\);/.exec(
          sql,
        ),
      )
      .find((match) => match !== null)?.[1];
    expect(table).toBeDefined();
    const defaultOf = (column: string) =>
      new RegExp(`${column} boolean not null default (true|false)`).exec(
        table ?? "",
      )?.[1];
    expect({
      remindersEnabled: defaultOf("reminders_enabled") === "true",
      sensitiveDetails: defaultOf("sensitive_details") === "true",
      quietHoursEnabled: defaultOf("quiet_hours_enabled") === "true",
    }).toEqual(NOTIFICATION_DEFAULTS);
    expect(NOTIFICATION_DEFAULTS.remindersEnabled).toBe(false);
  });

  it("the stored sleep and stress bands are the API's", () => {
    const sql = files.map(text).join("\n");
    expect(sql).toContain(
      `sleep_band in (${Object.values(SLEEP_BANDS)
        .map((band) => `'${band}'`)
        .join(", ")})`,
    );
    expect(sql).toContain(
      `stress_band in (${STRESS_BANDS.map((band) => `'${band}'`).join(", ")})`,
    );
  });
});

describe("the read side touches no other synced data", () => {
  it("no new module reads a sync table other than sync_lapse", () => {
    const sources = ["today", "records-events", "notifications", "baseline"]
      .flatMap((dir) =>
        readdirSync(join(__dirname, "..", dir))
          .filter((name) => name.endsWith(".ts") && !name.endsWith(".spec.ts"))
          .map((name) =>
            readFileSync(join(__dirname, "..", dir, name), "utf8"),
          ),
      )
      .join("\n");
    expect(sources).not.toMatch(/sync_(answer|area|account)/);
    expect(sources).toContain('"sync_lapse"');
  });
});
