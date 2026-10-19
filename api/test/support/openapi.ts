import { readFileSync } from "node:fs";
import { join } from "node:path";
import Ajv2020, { type ErrorObject } from "ajv8/dist/2020";
import addFormats from "ajv-formats";

/**
 * Validates API responses against the schemas in docs/contracts/openapi.yaml
 * (OpenAPI 3.1, JSON Schema 2020-12), so the contract and the real responses
 * cannot drift apart.
 *
 * Test-only devDependencies: Ajv 8 is installed under the alias "ajv8",
 * because the top-level "ajv" package is Ajv 6 (eslint); ajv-formats and
 * js-yaml are declared directly.
 */
// eslint-disable-next-line @typescript-eslint/no-require-imports
const yaml = require("js-yaml") as { load: (text: string) => unknown };

export type { ErrorObject };

interface OpenApiDocument {
  info: { version: string };
  components: { schemas: Record<string, object> };
}

const document = yaml.load(
  readFileSync(
    join(__dirname, "..", "..", "..", "docs", "contracts", "openapi.yaml"),
    "utf8",
  ),
) as OpenApiDocument;

// Strict about unknown keywords and formats. strictTypes is off: the
// contract's composites (allOf + unevaluatedProperties) carry no `type`,
// which is valid JSON Schema that strictTypes would refuse.
const ajv = new Ajv2020({ strict: true, strictTypes: false, allErrors: true });
addFormats(ajv);
// Only the schemas (paths and info are not JSON Schema), as $defs of one
// schema so that their "#/components/schemas/<name>" references resolve.
const asDefs = (value: unknown): unknown => {
  if (Array.isArray(value)) return value.map(asDefs);
  if (value === null || typeof value !== "object") return value;
  return Object.fromEntries(
    Object.entries(value).map(([key, inner]) => [
      key,
      key === "$ref" && typeof inner === "string"
        ? inner.replace(/^#\/components\/schemas\//, "#/$defs/")
        : asDefs(inner),
    ]),
  );
};
ajv.addSchema({ $defs: asDefs(document.components.schemas) }, "openapi");

/** The names of every schema in components.schemas. */
export const openApiSchemaNames = Object.keys(document.components.schemas);

/** components.schemas[`name`] as written in openapi.yaml (read-only). */
export function openApiSchema(name: string): Readonly<Record<string, unknown>> {
  const schema = document.components.schemas[name];
  if (schema === undefined) {
    throw new Error(`openapi.yaml has no schema ${name}`);
  }
  return structuredClone(schema) as Record<string, unknown>;
}

/**
 * Validation errors of `body` against components.schemas[`name`]; an empty
 * list means it matches.
 */
export function openApiErrors(name: string, body: unknown): ErrorObject[] {
  if (!openApiSchemaNames.includes(name)) {
    throw new Error(`openapi.yaml has no schema ${name}`);
  }
  const validate = ajv.getSchema(`openapi#/$defs/${name}`);
  if (!validate) throw new Error(`schema ${name} did not compile`);
  return validate(body) ? [] : [...(validate.errors ?? [])];
}
