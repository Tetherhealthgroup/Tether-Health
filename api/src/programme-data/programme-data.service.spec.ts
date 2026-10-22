import { BadGatewayException, Logger } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import type { UserSupabaseClientFactory } from "../enrolments/user-supabase-client";
import { ProgrammeDataException } from "./programme-data-errors";
import { programmeRoute } from "./programme-data.routes";
import { ProgrammeDataService, ROUTE_TEMPLATE } from "./programme-data.service";

const USER_ID = "5a1e0000-0000-4000-8000-00000000c0de";
const ENROLMENT_ID = "e1e10000-0000-4000-8000-00000000c0de";
const SUBMISSION_ID = "51b00000-0000-4000-8000-00000000c0de";
const VALUE_CANARY = 187;
const user: AuthUser = {
  id: USER_ID,
  accessToken: "synthetic-token-canary",
  authenticatedAt: 1,
};

/** A chain that ignores filters and resolves to `result`. */
const chain = (result: unknown) => {
  const node: Record<string, unknown> = {};
  for (const name of ["select", "eq", "is", "returns"]) {
    node[name] = () => node;
  }
  node.maybeSingle = () => Promise.resolve(result);
  node.then = (resolve: (value: unknown) => unknown) => resolve(result);
  return node;
};

function serviceWith(insertError: { code: string } | null, inserts: unknown[]) {
  const client = {
    rpc: () => Promise.resolve({ data: true, error: null }),
    from: (table: string) => {
      if (table === "enrolments") {
        return chain({
          data: { id: ENROLMENT_ID, status: "focus" },
          error: null,
        });
      }
      if (table === "programme_consents") {
        return chain({ data: { id: "consent" }, error: null });
      }
      return {
        insert: (rows: unknown) => {
          inserts.push(rows);
          return Promise.resolve({ error: insertError });
        },
      };
    },
  };
  const factory = {
    forUser: () => client,
  } as unknown as UserSupabaseClientFactory;
  return new ProgrammeDataService(factory);
}

describe("ProgrammeDataService", () => {
  const route = programmeRoute("hw", "readings")!;
  const body = { systolic: VALUE_CANARY, diastolic: 99, pulse: 71 };
  let logged: string[];

  beforeEach(() => {
    logged = [];
    for (const level of ["log", "warn", "error", "debug", "verbose"] as const) {
      jest
        .spyOn(Logger.prototype, level)
        .mockImplementation((...args: unknown[]) => {
          logged.push(JSON.stringify(args));
        });
    }
  });
  afterEach(() => jest.restoreAllMocks());

  it("writes one bulk insert as the caller, with the route's programme", async () => {
    const inserts: unknown[] = [];
    const result = await serviceWith(null, inserts).submit(
      user,
      route,
      body,
      SUBMISSION_ID,
      "req-1",
    );
    expect(result).toEqual({
      status: 201,
      body: { submissionId: SUBMISSION_ID },
    });
    expect(inserts).toHaveLength(1);
    expect(inserts[0]).toEqual([
      expect.objectContaining({
        user_id: USER_ID,
        enrolment_id: ENROLMENT_ID,
        programme_code: "hw",
        submission_id: SUBMISSION_ID,
        metric: "bp_systolic",
        value: VALUE_CANARY,
        unit_ucum: "mm[Hg]",
      }),
      expect.objectContaining({ metric: "bp_diastolic", value: 99 }),
      expect.objectContaining({
        metric: "heart_rate",
        value: 71,
        unit_ucum: "/min",
      }),
    ]);
    expect(logged).toEqual([]);
  });

  it.each(["TH026", "TH027", "XX000", "22003", "not-a-code"])(
    "an unhandled %s fails closed and logs the template and SQLSTATE only",
    async (code) => {
      await expect(
        serviceWith({ code }, []).submit(
          user,
          route,
          body,
          SUBMISSION_ID,
          "req-2",
        ),
      ).rejects.toBeInstanceOf(BadGatewayException);
      expect(logged).toHaveLength(1);
      const line = logged[0] as string;
      expect(line).toContain(`route=${ROUTE_TEMPLATE}`);
      expect(line).toContain("requestId=req-2");
      expect(line).toContain("status=502");
      expect(line).toContain(
        `code=${/^[0-9A-Z]{5}$/.test(code) ? code : "none"}`,
      );
      for (const secret of [
        USER_ID,
        ENROLMENT_ID,
        SUBMISSION_ID,
        String(VALUE_CANARY),
        "hw",
        "readings",
        "synthetic-token-canary",
        "bp_systolic",
      ]) {
        expect(line).not.toContain(secret);
      }
    },
  );

  it("a mapped SQLSTATE is answered with its code and not logged", async () => {
    await expect(
      serviceWith({ code: "42501" }, []).submit(
        user,
        route,
        body,
        SUBMISSION_ID,
        "r",
      ),
    ).rejects.toMatchObject({ code: "record_not_allowed" });
    await expect(
      serviceWith({ code: "23514" }, []).submit(
        user,
        route,
        body,
        SUBMISSION_ID,
        "r",
      ),
    ).rejects.toBeInstanceOf(ProgrammeDataException);
    expect(logged).toEqual([]);
  });

  it("refuses a value past the database bound before writing", async () => {
    const inserts: unknown[] = [];
    await expect(
      serviceWith(null, inserts).submit(
        user,
        programmeRoute("hw", "lipids")!,
        { total: 10000.001, labDate: "2026-01-01" },
        SUBMISSION_ID,
        "r",
      ),
    ).rejects.toMatchObject({ code: "invalid_record" });
    expect(inserts).toEqual([]);
  });
});
