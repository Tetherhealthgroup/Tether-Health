import { readFileSync } from "node:fs";
import { join } from "node:path";
import { DatabaseErrorCode } from "../src/common/database-errors";
import { DATABASE_ERRORS } from "./support/database-errors";
import { FakePostgrest } from "./support/fake-postgrest";

/**
 * Keeps the API's error codes and the fake PostgREST in step with the
 * database's error-code registry, the "Error codes" table in
 * docs/contracts/database.md (one row per code: code, hint name, raised by,
 * message; several messages are separated by "; ", none is "—").
 */
interface RegistryRow {
  code: string;
  hint: string;
  messages: string[];
}

function readRegistry(): RegistryRow[] {
  const doc = readFileSync(
    join(__dirname, "..", "..", "docs", "contracts", "database.md"),
    "utf8",
  );
  const section = doc.split(/^## Error codes$/m)[1]?.split(/^## /m)[0] ?? "";
  return section
    .split("\n")
    .map((line) =>
      /^\| `(TH\d{3})` \| `([a-z_]+)` \| .* \| (.+) \|$/.exec(line.trim()),
    )
    .filter((match) => match !== null)
    .map(([, code, hint, message]) => ({
      code: code as string,
      hint: hint as string,
      messages: message === "—" ? [] : (message as string).split("; "),
    }));
}

const snakeCase = (name: string) =>
  name.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);

describe("database error registry", () => {
  const registry = readRegistry();
  const row = (code: string) => {
    const found = registry.find((entry) => entry.code === code);
    if (!found) throw new Error(`${code} is not in the registry`);
    return found;
  };

  it("parses the registry table", () => {
    expect(registry.length).toBeGreaterThanOrEqual(10);
    expect(new Set(registry.map((entry) => entry.code)).size).toBe(
      registry.length,
    );
  });

  it("the tests' code, hint and message table matches the registry", () => {
    expect(
      DATABASE_ERRORS.map(({ code, hint, messages }) => ({
        code,
        hint,
        messages: [...messages],
      })),
    ).toEqual(registry);
  });

  it("every TH code the API maps is in the registry under the same name", () => {
    const mapped = Object.entries(DatabaseErrorCode).filter(([, code]) =>
      code.startsWith("TH"),
    );
    expect(mapped.length).toBeGreaterThan(0);
    for (const [name, code] of mapped) {
      expect({ code, hint: snakeCase(name) }).toEqual({
        code,
        hint: row(code).hint,
      });
    }
  });

  describe("the fake PostgREST raises exactly the registry's codes", () => {
    const token = "synthetic-registry-token";
    const userId = "00000000-0000-4000-8000-000000000f01";
    let fake: FakePostgrest;
    const send = async (method: string, path: string, body?: unknown) => {
      const response = await fake.fetch(
        `http://fake.example.test/rest/v1/${path}`,
        {
          method,
          headers: {
            authorization: `Bearer ${token}`,
            "content-type": "application/json",
            prefer: "return=representation",
          },
          ...(body === undefined ? {} : { body: JSON.stringify(body) }),
        },
      );
      return {
        status: response.status,
        body: (await response.json()) as Record<string, unknown>,
      };
    };
    const raised = (response: { status: number; body: unknown }) => {
      const { code, message, hint } = response.body as RegistryRow & {
        message: string;
      };
      return { status: response.status, code, message, hint };
    };
    const expected = (code: string, messageIndex = 0) => ({
      status: 400,
      code,
      message: row(code).messages[messageIndex],
      hint: row(code).hint,
    });

    beforeEach(() => {
      fake = new FakePostgrest();
      fake.addUser(token, userId);
    });

    const enrol = (programme: string) =>
      send("POST", "enrolments", {
        user_id: userId,
        programme_code: programme,
        status: "focus",
      });

    it("TH001 for the focus cap", async () => {
      expect((await enrol("bf")).status).toBe(201);
      expect((await enrol("hw")).status).toBe(201);
      expect(raised(await enrol("st"))).toEqual(expected("TH001"));
    });

    it("TH002 and TH003 for the consent revoke-only rules", async () => {
      const enrolment = (await enrol("ck")).body as unknown as [{ id: string }];
      const granted = await send("POST", "programme_consents", {
        enrolment_id: enrolment[0].id,
        purpose: "core",
        recipient_ref: null,
        consent_version: "v1",
        consent_text: "Synthetic core wording",
      });
      const [{ id }] = granted.body as unknown as [{ id: string }];
      expect(
        raised(
          await send("PATCH", `programme_consents?id=eq.${id}`, {
            revoked_at: null,
          }),
        ),
      ).toEqual(expected("TH003", 0));
      const revoke = { revoked_at: "2026-10-18T10:00:00.000Z" };
      expect(
        (await send("PATCH", `programme_consents?id=eq.${id}`, revoke)).status,
      ).toBe(200);
      expect(
        raised(await send("PATCH", `programme_consents?id=eq.${id}`, revoke)),
      ).toEqual(expected("TH002"));
    });
  });
});
