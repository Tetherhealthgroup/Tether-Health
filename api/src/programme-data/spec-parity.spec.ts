import { readFileSync } from "node:fs";
import { join } from "node:path";
import { getMetadataStorage } from "class-validator";
import { slug } from "./option-codes";
import { PROGRAMME_ROUTES, routeName } from "./programme-data.routes";
import { SPEC_RULES } from "./ranges";

/**
 * Parity with the app spec (tether_ui/spec): the routes and their screens
 * (endpoints.json), every option list and every screen input
 * (screens.json), and every range (rules.json). A spec change fails here
 * until the API follows it.
 */
const SPEC = join(__dirname, "..", "..", "..", "tether_ui", "spec");
const read = <T>(name: string): T =>
  JSON.parse(readFileSync(join(SPEC, name), "utf8")) as T;

interface Endpoint {
  endpoint: string;
  screens: string[];
}
interface Control {
  t?: string;
  key?: string;
  options?: string[];
  [other: string]: unknown;
}
interface Rule {
  inputs: string[];
  params: Record<string, unknown>;
}

const endpoints = read<Endpoint[]>("endpoints.json");
const screens =
  read<Record<string, { body?: unknown; footer?: unknown }>>("screens.json");
const rules = read<Record<string, Rule>>("rules.json");

/** Every input control (an element with `t` and `key`) of a screen. */
function inputsOf(screenId: string): Control[] {
  const screen = screens[screenId];
  if (!screen) throw new Error(`screens.json has no ${screenId}`);
  const found: Control[] = [];
  const walk = (node: unknown) => {
    if (Array.isArray(node)) node.forEach(walk);
    else if (node !== null && typeof node === "object") {
      const control = node as Control;
      if (typeof control.t === "string" && typeof control.key === "string") {
        found.push(control);
      }
      Object.values(control).forEach(walk);
    }
  };
  walk([screen.body, screen.footer]);
  return found;
}

/** The API's codes for a spec option list: "Skip" means the key is omitted. */
const codesOf = (options: string[]) =>
  options.filter((label) => label !== "Skip").map(slug);

describe("programme event routes and the spec", () => {
  const specRoutes = endpoints
    .map((entry) => ({
      ...entry,
      match: /^POST \/v1\/program-data\/([a-z]{2})\/([a-z0-9-]+)$/.exec(
        entry.endpoint,
      ),
    }))
    .filter((entry) => entry.match !== null);

  it("are exactly the spec's POST /v1/program-data/<code>/<kind> endpoints", () => {
    expect(specRoutes.map((entry) => entry.endpoint).sort()).toEqual(
      PROGRAMME_ROUTES.map(
        (route) => `POST /v1/program-data/${routeName(route)}`,
      ).sort(),
    );
    expect(PROGRAMME_ROUTES).toHaveLength(15);
  });

  it.each(PROGRAMME_ROUTES.map((route) => [routeName(route), route] as const))(
    "%s: screen, inputs and DTO fields match",
    (_name, route) => {
      const spec = specRoutes.find(
        (entry) =>
          entry.endpoint === `POST /v1/program-data/${routeName(route)}`,
      );
      expect(spec?.screens).toEqual([route.screen]);
      // Every input on the screen is carried by exactly one body field.
      const keys = inputsOf(route.screen).map((control) => control.key);
      const carried = Object.values(route.fields).filter(
        (input): input is string => input !== null,
      );
      expect([...carried].sort()).toEqual([...keys].sort());
      // The route's field list is the DTO's property list.
      const properties = new Set(
        getMetadataStorage()
          .getTargetValidationMetadatas(route.dto, "", true, false)
          .map((metadata) => metadata.propertyName),
      );
      expect([...properties].sort()).toEqual(Object.keys(route.fields).sort());
    },
  );

  it.each(PROGRAMME_ROUTES.map((route) => [routeName(route), route] as const))(
    "%s: every option list is the spec's",
    (_name, route) => {
      const controls = inputsOf(route.screen);
      for (const control of controls) {
        const field = Object.entries(route.fields).find(
          ([, input]) => input === control.key,
        )?.[0];
        if (control.options === undefined) {
          expect(field && route.options[field]).toBeFalsy();
          continue;
        }
        expect(field).toBeDefined();
        expect(route.options[field as string]).toEqual(
          codesOf(control.options),
        );
      }
      // An option field not backed by a spec list: only the device-decided zone.
      const unbacked = Object.keys(route.options).filter(
        (field) => route.fields[field] === null,
      );
      expect(unbacked).toEqual(
        routeName(route) === "ca/zone-checks" ? ["zone"] : [],
      );
    },
  );

  describe("rules.json", () => {
    const routeScreens = new Set(PROGRAMME_ROUTES.map((route) => route.screen));
    const readingRules = Object.entries(rules)
      .filter(([, rule]) =>
        rule.inputs.some((input) =>
          routeScreens.has(input.split(".")[0] ?? ""),
        ),
      )
      .map(([name]) => name)
      .sort();

    it("every rule reading one of these screens is in the API's table", () => {
      expect(SPEC_RULES.map((rule) => rule.rule).sort()).toEqual(readingRules);
    });

    it.each(SPEC_RULES.map((rule) => [rule.rule, rule] as const))(
      "%s: inputs and ranges match",
      (name, rule) => {
        const spec = rules[name];
        expect(spec?.inputs).toEqual(rule.inputs);
        for (const range of rule.ranges) {
          expect(spec?.params[range.minParam]).toBe(range.min);
          expect(spec?.params[range.maxParam]).toBe(range.max);
          expect(rule.inputs).toContain(range.input);
          const route = PROGRAMME_ROUTES.find(
            (candidate) => routeName(candidate) === range.route,
          );
          expect(route).toBeDefined();
          expect(`${route?.screen}.${route?.fields[range.field]}`).toBe(
            range.input,
          );
        }
      },
    );

    it("a range applies only where a rule's inputs name the field's input", () => {
      const ranged = new Set(
        SPEC_RULES.flatMap((rule) => rule.ranges.map((range) => range.input)),
      );
      for (const rule of SPEC_RULES) {
        for (const range of rule.ranges) {
          expect(ranged.has(range.input)).toBe(true);
        }
      }
      // hw_log (the first reading) does not submit; only hw_log2 does.
      expect([...ranged].sort()).toEqual([
        "ca_zone.peak_flow",
        "hw_log2.diastolic",
        "hw_log2.systolic",
        "st_log.reading",
      ]);
    });
  });
});
