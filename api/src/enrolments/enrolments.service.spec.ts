import { BadGatewayException, HttpStatus } from "@nestjs/common";
import type { ConfigService } from "@nestjs/config";
import type { AuthUser } from "../auth/auth-user";
import { CodedHttpException } from "./enrolment-errors";
import { EnrolmentsService } from "./enrolments.service";
import type { UserSupabaseClientFactory } from "./user-supabase-client";

type Result = { data: unknown; error: unknown; count?: number | null };

/**
 * A chainable stand-in for one supabase-js query: every builder method
 * returns the chain, and awaiting it yields the next queued result.
 */
function chain(result: Result, calls: string[][]) {
  const target: Record<string, unknown> = {
    then: (resolve: (value: Result) => unknown) => resolve(result),
  };
  const proxy: unknown = new Proxy(target, {
    get(object, property: string) {
      if (property in object) return object[property];
      return (...args: unknown[]) => {
        calls.push([property, ...args.map((arg) => JSON.stringify(arg))]);
        return proxy;
      };
    },
  });
  return proxy;
}

function setup(...results: Result[]) {
  const calls: string[][] = [];
  const client = {
    from: jest.fn((table: string) => {
      calls.push(["from", table]);
      return chain(results.shift() ?? { data: null, error: null }, calls);
    }),
    rpc: jest.fn((name: string) => {
      calls.push(["rpc", name]);
      return chain(results.shift() ?? { data: null, error: null }, calls);
    }),
  };
  const forUser = jest.fn(() => client);
  const factory = { forUser } as unknown as UserSupabaseClientFactory;
  const config = {
    getOrThrow: jest.fn(() => 600),
  } as unknown as ConfigService;
  return { service: new EnrolmentsService(factory, config), calls, forUser };
}

const user: AuthUser = {
  id: "00000000-0000-4000-8000-0000000000a1",
  accessToken: "synthetic-access-token",
  authenticatedAt: 1700000000,
};
const ENROLMENT_ID = "00000000-0000-4000-8000-0000000000e1";
const enrolmentRow = (status = "focus") => ({
  id: ENROLMENT_ID,
  user_id: user.id,
  programme_code: "bf",
  status,
  mode: null,
  joined_at: "2026-10-18T00:00:00.000Z",
  left_at: status === "left" ? "2026-10-18T01:00:00.000Z" : null,
  created_at: "2026-10-18T00:00:00.000Z",
  updated_at: "2026-10-18T00:00:00.000Z",
});

async function codeOf(promise: Promise<unknown>) {
  const error = await promise.then(
    () => undefined,
    (reason: unknown) => reason,
  );
  if (error instanceof CodedHttpException) {
    return { status: error.getStatus(), code: error.code };
  }
  return error;
}

describe("EnrolmentsService", () => {
  it("acts as the caller and filters enrolments on the caller id", async () => {
    const { service, calls, forUser } = setup(
      { data: [enrolmentRow()], error: null, count: 1 },
      { data: [], error: null, count: 0 },
    );
    await service.list(user);
    expect(forUser).toHaveBeenCalledWith(user);
    expect(calls).toContainEqual(["eq", '"user_id"', JSON.stringify(user.id)]);
  });

  it.each([
    [
      { code: "TH001", message: "synthetic", hint: "focus_cap_reached" },
      { status: HttpStatus.CONFLICT, code: "focus_cap_reached" },
    ],
    [
      { code: "23505", message: "duplicate key" },
      { status: HttpStatus.CONFLICT, code: "already_enrolled" },
    ],
    [
      { code: "23503", message: "foreign key" },
      { status: HttpStatus.NOT_FOUND, code: "programme_not_found" },
    ],
    [
      { code: "42501", message: "row-level security" },
      { status: HttpStatus.CONFLICT, code: "account_deletion_in_progress" },
    ],
  ])("maps create error %j", async (error, expected) => {
    const { service } = setup({ data: null, error });
    expect(
      await codeOf(
        service.create(user, { programmeCode: "bf", status: "focus" }),
      ),
    ).toEqual(expected);
  });

  it("reports unknown database errors as 502 without detail", async () => {
    const { service } = setup({
      data: null,
      error: { code: "XX000", message: "synthetic internal detail" },
    });
    const error = await codeOf(
      service.create(user, { programmeCode: "bf", status: "focus" }),
    );
    expect(error).toBeInstanceOf(BadGatewayException);
  });

  it.each([
    [
      { code: "TH001" },
      { status: HttpStatus.CONFLICT, code: "focus_cap_reached" },
    ],
    [
      { code: "23514" },
      { status: HttpStatus.CONFLICT, code: "enrolment_conflict" },
    ],
    [
      { code: "TH002" },
      { status: HttpStatus.CONFLICT, code: "enrolment_conflict" },
    ],
    [
      { code: "TH003" },
      { status: HttpStatus.CONFLICT, code: "enrolment_conflict" },
    ],
  ])("maps update error %j", async (error, expected) => {
    const { service } = setup(
      { data: enrolmentRow(), error: null },
      { data: null, error: { ...error, message: "synthetic" } },
    );
    expect(
      await codeOf(service.update(user, ENROLMENT_ID, { status: "paused" })),
    ).toEqual(expected);
  });

  it.each(["TH002", "TH003"])(
    "maps revoke error %s to consent_already_revoked",
    async (code) => {
      const { service } = setup({
        data: null,
        error: { code, message: "synthetic" },
      });
      expect(await codeOf(service.revokeConsent(user, "c1"))).toEqual({
        status: HttpStatus.CONFLICT,
        code: "consent_already_revoked",
      });
    },
  );

  // Message text and hint never decide: only the SQLSTATE code does.
  describe("does not match message text", () => {
    const capText = {
      message: "At most two programmes can be in focus",
      hint: "focus_cap_reached",
    };

    it.each(["23514", "P0001", "XX000"])(
      "create: focus-cap text under %s is not the focus cap",
      async (code) => {
        const { service } = setup({ data: null, error: { code, ...capText } });
        expect(
          await codeOf(
            service.create(user, { programmeCode: "bf", status: "focus" }),
          ),
        ).toBeInstanceOf(BadGatewayException);
      },
    );

    it("update: focus-cap text under 23514 is an ordinary check violation", async () => {
      const { service } = setup(
        { data: enrolmentRow(), error: null },
        { data: null, error: { code: "23514", ...capText } },
      );
      expect(
        await codeOf(service.update(user, ENROLMENT_ID, { status: "focus" })),
      ).toEqual({ status: HttpStatus.CONFLICT, code: "enrolment_conflict" });
    });

    it("revoke: already-revoked text under 23514 is not the revoke-only rule", async () => {
      const { service } = setup({
        data: null,
        error: {
          code: "23514",
          message: "Consent is already revoked",
          hint: "consent_already_revoked",
        },
      });
      expect(await codeOf(service.revokeConsent(user, "c1"))).toBeInstanceOf(
        BadGatewayException,
      );
    });
  });

  // Unmapped TH codes (including TH009/TH010, which a member session never
  // sees) fail closed on every route, with a fixed message.
  describe.each([
    "TH001",
    "TH002",
    "TH003",
    "TH007",
    "TH009",
    "TH010",
    "TH999",
  ])("fails closed on %s where it is not mapped", (code) => {
    const error = { code, message: "synthetic detail", hint: "synthetic_hint" };
    const recent = () => ({
      ...user,
      authenticatedAt: Math.floor(Date.now() / 1000),
    });
    const expectHidden = (result: unknown) => {
      expect(result).toBeInstanceOf(BadGatewayException);
      const response = JSON.stringify(
        (result as BadGatewayException).getResponse(),
      );
      expect(response).not.toContain("synthetic");
      expect(response).not.toContain(code);
    };

    it("grant consent", async () => {
      const { service } = setup(
        { data: enrolmentRow(), error: null },
        { data: null, error },
      );
      expectHidden(
        await codeOf(
          service.grantConsent(user, {
            enrolmentId: ENROLMENT_ID,
            purpose: "core",
            consentVersion: "v1",
            consentText: "Synthetic wording",
          }),
        ),
      );
    });

    it("delete now", async () => {
      const { service } = setup({ data: null, error });
      expectHidden(
        await codeOf(service.deleteNow(recent(), ENROLMENT_ID, "DELETE")),
      );
    });

    if (!["TH001"].includes(code)) {
      it("create", async () => {
        const { service } = setup({ data: null, error });
        expectHidden(
          await codeOf(
            service.create(user, { programmeCode: "bf", status: "focus" }),
          ),
        );
      });
    }

    if (!["TH001", "TH002", "TH003"].includes(code)) {
      it("update", async () => {
        const { service } = setup(
          { data: enrolmentRow(), error: null },
          { data: null, error },
        );
        expectHidden(
          await codeOf(
            service.update(user, ENROLMENT_ID, { status: "paused" }),
          ),
        );
      });
    }

    if (!["TH002", "TH003"].includes(code)) {
      it("revoke consent", async () => {
        const { service } = setup({ data: null, error });
        expectHidden(await codeOf(service.revokeConsent(user, "c1")));
      });
    }
  });

  it("checks the deletion barrier only when rejoining", async () => {
    const rejoin = setup(
      { data: enrolmentRow("left"), error: null },
      { data: false, error: null },
    );
    expect(
      await codeOf(
        rejoin.service.update(user, ENROLMENT_ID, { status: "focus" }),
      ),
    ).toEqual({
      status: HttpStatus.CONFLICT,
      code: "account_deletion_in_progress",
    });
    expect(rejoin.calls).toContainEqual(["rpc", "deletion_barrier_open"]);

    const pause = setup(
      { data: enrolmentRow("focus"), error: null },
      { data: enrolmentRow("paused"), error: null },
      { data: [], error: null, count: 0 },
    );
    await pause.service.update(user, ENROLMENT_ID, { status: "paused" });
    expect(pause.calls.some((call) => call[0] === "rpc")).toBe(false);
  });

  it("refuses a partial list (server row limit) instead of dropping rows", async () => {
    const { service } = setup(
      { data: [enrolmentRow()], error: null, count: 1 },
      { data: [], error: null, count: 3 },
    );
    expect(await codeOf(service.list(user))).toBeInstanceOf(
      BadGatewayException,
    );
  });

  it("asks only for live consents", async () => {
    const { service, calls } = setup(
      { data: [enrolmentRow()], error: null, count: 1 },
      { data: [], error: null, count: 0 },
    );
    await service.list(user);
    expect(calls).toContainEqual(["is", '"revoked_at"', "null"]);
  });

  it("delete now needs the confirmation and a recent sign-in", async () => {
    const recent = { ...user, authenticatedAt: Math.floor(Date.now() / 1000) };
    const wrong = setup();
    expect(
      await codeOf(wrong.service.deleteNow(recent, ENROLMENT_ID, "delete")),
    ).toEqual({
      status: HttpStatus.BAD_REQUEST,
      code: "confirmation_required",
    });
    const stale = setup();
    expect(
      await codeOf(stale.service.deleteNow(user, ENROLMENT_ID, "DELETE")),
    ).toEqual({
      status: HttpStatus.UNAUTHORIZED,
      code: "recent_authentication_required",
    });
    expect(wrong.calls).toEqual([]);
    expect(stale.calls).toEqual([]);
  });

  it("deletes now with the caller-scoped client and reports missing rows", async () => {
    const { service, calls } = setup({ data: [], error: null });
    const recent = { ...user, authenticatedAt: Math.floor(Date.now() / 1000) };
    expect(
      await codeOf(service.deleteNow(recent, ENROLMENT_ID, "DELETE")),
    ).toEqual({
      status: HttpStatus.NOT_FOUND,
      code: "enrolment_not_found",
    });
    expect(calls).toEqual(
      expect.arrayContaining([
        ["from", "enrolments"],
        ["delete"],
        ["eq", '"id"', JSON.stringify(ENROLMENT_ID)],
        ["eq", '"user_id"', JSON.stringify(user.id)],
      ]),
    );
  });

  it.each(["share_care_team", "share_caregiver"] as const)(
    "refuses %s before touching the database",
    async (purpose) => {
      const { service, calls } = setup();
      expect(
        await codeOf(
          service.grantConsent(user, {
            enrolmentId: ENROLMENT_ID,
            purpose,
            recipientRef: "00000000-0000-4000-8000-0000000000c1",
            consentVersion: "v1",
            consentText: "Synthetic wording",
          }),
        ),
      ).toEqual({ status: HttpStatus.CONFLICT, code: "sharing_not_available" });
      expect(calls).toEqual([]);
    },
  );

  it("inserts consents plainly (never upsert) and maps a duplicate", async () => {
    const { service, calls } = setup(
      { data: enrolmentRow(), error: null },
      { data: null, error: { code: "23505", message: "duplicate key" } },
    );
    expect(
      await codeOf(
        service.grantConsent(user, {
          enrolmentId: ENROLMENT_ID,
          purpose: "core",
          consentVersion: "v1",
          consentText: "Synthetic wording",
        }),
      ),
    ).toEqual({ status: HttpStatus.CONFLICT, code: "consent_already_granted" });
    expect(calls.some((call) => call[0] === "insert")).toBe(true);
    expect(calls.some((call) => call[0] === "upsert")).toBe(false);
  });

  it("reports a missing consent as not found and a revoked one as conflict", async () => {
    const missing = setup(
      { data: null, error: null },
      { data: null, error: null },
    );
    expect(await codeOf(missing.service.revokeConsent(user, "c1"))).toEqual({
      status: HttpStatus.NOT_FOUND,
      code: "consent_not_found",
    });
    const revoked = setup(
      { data: null, error: null },
      { data: { id: "c1", revoked_at: "2026-10-18T00:00:00Z" }, error: null },
    );
    expect(await codeOf(revoked.service.revokeConsent(user, "c1"))).toEqual({
      status: HttpStatus.CONFLICT,
      code: "consent_already_revoked",
    });
  });
});
