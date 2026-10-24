import { readdirSync, readFileSync } from "node:fs";
import { join, relative, sep } from "node:path";

/**
 * The API holds no Supabase service key and makes no Auth admin call:
 * account deletion runs with the member's own token. Scans every file under
 * backend/api/src. The searched names are assembled from fragments so that this file
 * does not contain them literally.
 */
const SRC = join(__dirname, "..");
const KEY_NAME = ["SUPABASE", "SERVICE", "ROLE", "KEY"].join("_");
const ADMIN_CALL = new RegExp(
  [
    String.raw`\bauth\s*\??\.\s*admin\b`,
    String.raw`\bauth\s*\[\s*["'\x60]admin`,
  ].join("|"),
);
/** The one line that declares the variable forbidden at startup. */
const FORBIDDEN_DECLARATION = `${KEY_NAME}: Joi.any().forbidden(),`;
/** The test of that refusal, which must name the variable. */
const REFUSAL_TESTS = "config/environment.spec.ts";

function sourceFiles(dir: string): string[] {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    return entry.isDirectory() ? sourceFiles(path) : [path];
  });
}

const files = sourceFiles(SRC).map((path) => ({
  path: relative(SRC, path).split(sep).join("/"),
  text: readFileSync(path, "utf8"),
}));

describe("no Supabase service key in the API", () => {
  it("scans the source tree", () => {
    expect(files.map((file) => file.path)).toEqual(
      expect.arrayContaining([
        "account/account.service.ts",
        "account/avatar-objects.ts",
        "config/environment.ts",
        "app.module.ts",
      ]),
    );
  });

  it("no file makes an Auth admin call", () => {
    expect(
      files.filter((file) => ADMIN_CALL.test(file.text)).map((f) => f.path),
    ).toEqual([]);
  });

  it("no file reads the service key variable; the configuration only forbids it", () => {
    const mentions = files.flatMap((file) =>
      file.text
        .split("\n")
        .filter((line) => line.includes(KEY_NAME))
        .map((line) => ({ path: file.path, line: line.trim() })),
    );
    const outsideRefusalTests = mentions.filter(
      (mention) => mention.path !== REFUSAL_TESTS,
    );

    expect(outsideRefusalTests).toEqual([
      { path: "config/environment.ts", line: FORBIDDEN_DECLARATION },
    ]);
  });

  it("the patterns find what they look for", () => {
    expect(ADMIN_CALL.test(`client.auth.${"admin"}.deleteUser(id)`)).toBe(true);
    expect(ADMIN_CALL.test(`client.auth?.${"admin"}`)).toBe(true);
    expect(ADMIN_CALL.test(`client.auth["${"admin"}"]`)).toBe(true);
    expect(ADMIN_CALL.test("client.auth.getUser()")).toBe(false);
  });
});
