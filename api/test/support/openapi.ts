import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { join } from "node:path";

/**
 * Validates API responses against the schemas in docs/contracts/openapi.yaml
 * (OpenAPI 3.1, JSON Schema 2020-12), so the contract and the real responses
 * cannot drift apart.
 *
 * No new dependency: Ajv 8 (with its 2020-12 build and ajv-formats) comes
 * with Fastify's own schema compiler, @fastify/ajv-compiler, so it is
 * resolved from there; js-yaml is already in the tree (eslint).
 */
const fromAjvCompiler = createRequire(require.resolve("@fastify/ajv-compiler"));
const Ajv2020 = (fromAjvCompiler("ajv/dist/2020") as { default: AjvClass })
  .default;
const addFormats = (
  fromAjvCompiler("ajv-formats") as { default: (ajv: AjvInstance) => void }
).default;
// eslint-disable-next-line @typescript-eslint/no-require-imports
const yaml = require("js-yaml") as { load: (text: string) => unknown };

// Local shapes: the top-level "ajv" package in the tree is Ajv 6 (eslint),
// whose types do not describe Ajv 8.
export interface ErrorObject {
  instancePath: string;
  keyword: string;
  message?: string;
  params: Record<string, unknown>;
}
interface ValidateFunction {
  (data: unknown): boolean;
  errors?: ErrorObject[] | null;
}
interface AjvInstance {
  addSchema(schema: object, key: string): AjvInstance;
  getSchema(ref: string): ValidateFunction | undefined;
}
type AjvClass = new (options: object) => AjvInstance;

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
