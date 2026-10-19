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

const HEADER = "| Code | Name | Raised by | Message |";
const SEPARATOR = /^\|(?:-+\|)+$/;
const ROW = /^\| `(TH\d{3})` \| `([a-z_]+)` \| .* \| (.+) \|$/;

/** The registry table's rows, raw: header, separator, then the body. */
function readTable(): string[] {
  const doc = readFileSync(
    join(__dirname, "..", "..", "docs", "contracts", "database.md"),
    "utf8",
  );
  const section = doc.split(/^## Error codes$/m)[1]?.split(/^## /m)[0] ?? "";
  return section
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.startsWith("|"));
}

function parseRow(line: string): RegistryRow | null {
  const match = ROW.exec(line);
  if (!match) return null;
  const [, code, hint, message] = match as unknown as [
    string,
    string,
    string,
    string,
  ];
  return {
    code,
    hint,
    messages: message === "—" ? [] : message.split("; "),
  };
}

const snakeCase = (name: string) =>
  name.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);

describe("database error registry", () => {
  const table = readTable();
  const body = table.slice(2);
  const registry = body
    .map(parseRow)
    .filter((row): row is RegistryRow => row !== null);
  const row = (code: string) => {
    const found = registry.find((entry) => entry.code === code);
    if (!found) throw new Error(`${code} is not in the registry`);
    return found;
  };

  it("parses every row of the registry table", () => {
    expect(table[0]).toBe(HEADER);
    expect(table[1]).toMatch(SEPARATOR);
    // A row the parser cannot read fails here instead of being dropped.
    expect(body.filter((line) => parseRow(line) === null)).toEqual([]);
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

    // A failure injected but never consumed would break an unrelated later
    // test: clear it first, then fail the test that left it.
    afterEach(() => {
      const pending = fake.pendingFailures;
      fake.clearFailures();
      expect(pending).toBe(0);
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
        consent_version: "v1-draft",
        locale: "en",
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

    const enrolmentId = async (programme: string, status = "focus") => {
      const response = await send("POST", "enrolments", {
        user_id: userId,
        programme_code: programme,
        status,
      });
      return (response.body as unknown as [{ id: string }])[0].id;
    };
    const core = (enrolment: string, version = "v1-draft", locale = "en") =>
      send("POST", "programme_consents", {
        enrolment_id: enrolment,
        purpose: "core",
        consent_version: version,
        locale,
      });
    const supersede = (enrolment: string, version: string, locale = "en") =>
      send("POST", "rpc/supersede_core_consent", {
        p_enrolment: enrolment,
        p_version: version,
        p_locale: locale,
      });
    const swap = (demote: string, promote: string) =>
      send("POST", "rpc/swap_focus", { p_demote: demote, p_promote: promote });

    it("TH001 from swap_focus, inside the call", async () => {
      const bf = await enrolmentId("bf");
      await enrolmentId("hw");
      const st = await enrolmentId("st", "paused");
      const ca = await enrolmentId("ca", "paused");
      // A third programme reaches focus outside the cap (a superuser write),
      // so the swap's own cap check refuses it and changes nothing.
      fake.interleave("POST", "rpc/swap_focus", () =>
        fake.forceEnrolmentStatus(ca, "focus"),
      );
      expect(raised(await swap(bf, st))).toEqual(expected("TH001"));
      const status = (id: string) =>
        fake.table("enrolments").find((r) => r.id === id)?.status;
      expect([status(bf), status(st)]).toEqual(["focus", "paused"]);
    });

    it("TH004, TH011 and TH014 from supersede_core_consent", async () => {
      const id = await enrolmentId("ca");
      expect(raised(await supersede(id, "v2-synthetic"))).toEqual(
        expected("TH004"),
      );
      expect((await core(id)).status).toBe(201);
      expect(raised(await supersede(id, "v9-future"))).toEqual(
        expected("TH011"),
      );
      expect(raised(await supersede(id, "v1-draft"))).toEqual(
        expected("TH014"),
      );
      expect((await supersede(id, "v2-synthetic")).status).toBe(200);
      expect(raised(await supersede(id, "v1-draft", "es"))).toEqual(
        expected("TH014"),
      );
    });

    it("TH011 from a consent insert without a grantable document", async () => {
      const id = await enrolmentId("re");
      for (const [version, locale] of [
        ["v0-retired", "en"],
        ["v9-future", "en"],
        ["v1-draft", "fr"],
        ["v1", "en"],
      ]) {
        expect(raised(await core(id, version, locale))).toEqual(
          expected("TH011"),
        );
      }
    });

    it("TH005, TH012 and TH013 from swap_focus", async () => {
      const focus = await enrolmentId("bf");
      const paused = await enrolmentId("sf", "paused");
      const left = await enrolmentId("ea", "paused");
      await send("PATCH", `enrolments?id=eq.${left}`, { status: "left" });
      expect(raised(await swap(focus, left))).toEqual(expected("TH005"));
      expect(
        raised(await swap(focus, "00000000-0000-4000-8000-00000000ffff")),
      ).toEqual(expected("TH012"));
      expect(raised(await swap(focus, focus))).toEqual(expected("TH013"));
      expect(raised(await swap(paused, focus))).toEqual(expected("TH013"));
    });

    it("TH005, TH006 and TH012 from supersede_core_consent", async () => {
      const left = await enrolmentId("nu", "paused");
      expect((await core(left)).status).toBe(201);
      await send("PATCH", `enrolments?id=eq.${left}`, { status: "left" });
      expect(raised(await supersede(left, "v2-synthetic"))).toEqual(
        expected("TH005"),
      );
      expect(
        raised(
          await supersede(
            "00000000-0000-4000-8000-00000000ffff",
            "v2-synthetic",
          ),
        ),
      ).toEqual(expected("TH012"));
      const live = await enrolmentId("sd", "paused");
      expect((await core(live)).status).toBe(201);
      fake.startAccountDeletion(userId);
      expect(raised(await supersede(live, "v2-synthetic"))).toEqual(
        expected("TH006"),
      );
    });

    it("refuses consent_text on insert with 42501", async () => {
      const id = await enrolmentId("ck", "paused");
      const response = await send("POST", "programme_consents", {
        enrolment_id: id,
        purpose: "core",
        consent_version: "v1-draft",
        locale: "en",
        consent_text: "Synthetic wording the caller may not write",
      });
      expect(response.status).toBe(403);
      expect(response.body.code).toBe("42501");
      expect(fake.table("programme_consents")).toEqual([]);
    });
  });
});
