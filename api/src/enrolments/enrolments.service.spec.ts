import { BadGatewayException, HttpStatus } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { CodedHttpException } from "./enrolment-errors";
import { EnrolmentsService } from "./enrolments.service";
import type { UserSupabaseClientFactory } from "./user-supabase-client";

type Result = { data: unknown; error: unknown };

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
  return { service: new EnrolmentsService(factory), calls, forUser };
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
      { data: [enrolmentRow()], error: null },
      { data: [], error: null },
    );
    await service.list(user);
    expect(forUser).toHaveBeenCalledWith(user);
    expect(calls).toContainEqual(["eq", '"user_id"', JSON.stringify(user.id)]);
  });

  it.each([
    [
      { code: "23514", message: "At most two programmes can be in focus" },
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

  it("maps a non-cap check violation on update to enrolment_conflict", async () => {
    const { service } = setup(
      { data: enrolmentRow(), error: null },
      { data: null, error: { code: "23514", message: "other check" } },
    );
    expect(
      await codeOf(service.update(user, ENROLMENT_ID, { status: "paused" })),
    ).toEqual({ status: HttpStatus.CONFLICT, code: "enrolment_conflict" });
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
      { data: [], error: null },
    );
    await pause.service.update(user, ENROLMENT_ID, { status: "paused" });
    expect(pause.calls.some((call) => call[0] === "rpc")).toBe(false);
  });

  it("deletes now with the caller-scoped client and reports missing rows", async () => {
    const { service, calls } = setup({ data: [], error: null });
    expect(await codeOf(service.deleteNow(user, ENROLMENT_ID))).toEqual({
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
