import { BadGatewayException, Logger } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import type { UserSupabaseClientFactory } from "../enrolments/user-supabase-client";
import { CareException } from "./care-errors";
import { CareService } from "./care.service";

type Result = { data: unknown; error: unknown };

/** A chainable stand-in for one supabase-js query (see enrolments spec). */
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
    rpc: jest.fn((name: string, ...args: unknown[]) => {
      calls.push(["rpc", name, ...args.map((arg) => JSON.stringify(arg))]);
      return chain(results.shift() ?? { data: null, error: null }, calls);
    }),
  };
  const forUser = jest.fn(() => client);
  const factory = { forUser } as unknown as UserSupabaseClientFactory;
  return { service: new CareService(factory), calls, forUser };
}

const user: AuthUser = {
  id: "00000000-0000-4000-8000-0000000000a1",
  accessToken: "synthetic-access-token",
  authenticatedAt: 1700000000,
};
const CONNECTION = "00000000-0000-4000-8000-0000000000c1";
const OTHER_CONNECTION = "00000000-0000-4000-8000-0000000000c2";
const ENROLMENT = "00000000-0000-4000-8000-0000000000e1";
const CONSENT = "00000000-0000-4000-8000-0000000000f1";
const ORG = "00000000-0000-4000-8000-0000000000d1";
const REQUEST_ID = "req-synthetic-care";
const barrierOpen: Result = { data: true, error: null };
const barrierClosed: Result = { data: false, error: null };
const hwEnrolment: Result = {
  data: { id: ENROLMENT, programme_code: "hw", status: "focus" },
  error: null,
};
const liveConnections = (...ids: string[]): Result => ({
  data: ids.map((id) => ({ id })),
  error: null,
});
const shareConsents = (...recipients: string[]): Result => ({
  data: recipients.map((recipient, index) => ({
    id: index === 0 ? CONSENT : `${CONSENT.slice(0, -1)}${index}`,
    recipient_ref: recipient,
  })),
  error: null,
});
const shareRow: Result = {
  data: {
    id: "00000000-0000-4000-8000-000000000051",
    enrolment_id: ENROLMENT,
    connection_id: CONNECTION,
    kind: "visit_summary",
    created_at: "2026-10-22T10:00:00.000Z",
    expires_at: "2026-11-21T10:00:00.000Z",
  },
  error: null,
};
const pg = (code: string) => ({ data: null, error: { code, message: "x" } });

async function codeOf(promise: Promise<unknown>) {
  const error = await promise.then(
    () => undefined,
    (reason: unknown) => reason,
  );
  return error instanceof CareException
    ? { status: error.getStatus(), code: error.code }
    : error;
}

describe("CareService", () => {
  let logged: string[];
  beforeEach(() => {
    logged = [];
    jest.spyOn(Logger.prototype, "error").mockImplementation((message) => {
      logged.push(String(message));
    });
  });
  afterEach(() => jest.restoreAllMocks());

  describe("redeem", () => {
    it("redeems as the caller with the code as typed and names the clinic", async () => {
      const { service, calls, forUser } = setup(
        {
          data: {
            id: CONNECTION,
            org_id: ORG,
            connected_at: "2026-10-22T10:00:00.000Z",
            revoked_at: null,
          },
          error: null,
        },
        { data: [{ id: ORG, name: "Synthetic Clinic" }], error: null },
      );
      const result = await service.redeem(
        user,
        { inviteCode: "synth 0001 clinic" },
        REQUEST_ID,
      );
      expect(forUser).toHaveBeenCalledWith(user);
      expect(calls[0]).toEqual([
        "rpc",
        "redeem_care_invite",
        JSON.stringify({ p_code: "synth 0001 clinic" }),
      ]);
      expect(result).toEqual({
        id: CONNECTION,
        clinicId: ORG,
        clinicName: "Synthetic Clinic",
        connectedAt: "2026-10-22T10:00:00.000Z",
        revokedAt: null,
      });
    });

    it.each([
      ["TH025", { status: 400, code: "care_invite_invalid" }],
      ["TH006", { status: 409, code: "account_deletion_in_progress" }],
    ])("maps %s by code only", async (code, expected) => {
      const { service } = setup(pg(code));
      expect(
        await codeOf(
          service.redeem(user, { inviteCode: "SYNTH-CODE-0001" }, REQUEST_ID),
        ),
      ).toEqual(expected);
    });

    it("fails closed on TH010 and anything else, logging only the code", async () => {
      for (const code of ["TH010", "XX000", "TH025x"]) {
        const { service } = setup(pg(code));
        await expect(
          service.redeem(user, { inviteCode: "SYNTH-CODE-0001" }, REQUEST_ID),
        ).rejects.toBeInstanceOf(BadGatewayException);
      }
      expect(logged).toEqual([
        `care_failed requestId=${REQUEST_ID} route=/v1/care/connections status=502 code=TH010`,
        `care_failed requestId=${REQUEST_ID} route=/v1/care/connections status=502 code=XX000`,
        `care_failed requestId=${REQUEST_ID} route=/v1/care/connections status=502 code=none`,
      ]);
    });
  });

  describe("createSummary", () => {
    const dto = {
      programmeCode: "hw",
      snapshot: { bpAverage: "132/82" },
    };

    it("uses the one live connection holding the consent and stores the snapshot as sent", async () => {
      const { service, calls } = setup(
        barrierOpen,
        hwEnrolment,
        liveConnections(CONNECTION, OTHER_CONNECTION),
        shareConsents(CONNECTION),
        shareRow,
      );
      const result = await service.createSummary(user, dto, REQUEST_ID);
      expect(result).toMatchObject({
        programmeCode: "hw",
        connectionId: CONNECTION,
        delivery: "stored",
      });
      const insert = calls.find(([name]) => name === "insert");
      expect(JSON.parse(insert?.[1] ?? "{}")).toEqual({
        user_id: user.id,
        enrolment_id: ENROLMENT,
        connection_id: CONNECTION,
        consent_id: CONSENT,
        kind: "visit_summary",
        snapshot: dto.snapshot,
      });
    });

    it("ignores consents naming revoked connections", async () => {
      const { service } = setup(
        barrierOpen,
        hwEnrolment,
        liveConnections(OTHER_CONNECTION),
        shareConsents(CONNECTION),
      );
      expect(
        await codeOf(service.createSummary(user, dto, REQUEST_ID)),
      ).toEqual({ status: 409, code: "care_consent_required" });
    });

    it("several usable connections and none named → connection_required", async () => {
      const { service, calls } = setup(
        barrierOpen,
        hwEnrolment,
        liveConnections(CONNECTION, OTHER_CONNECTION),
        shareConsents(CONNECTION, OTHER_CONNECTION),
      );
      expect(
        await codeOf(service.createSummary(user, dto, REQUEST_ID)),
      ).toEqual({ status: 409, code: "connection_required" });
      expect(calls.some(([name]) => name === "insert")).toBe(false);
    });

    it("a named connection that is not live and the caller's → connection_not_found", async () => {
      const { service } = setup(
        barrierOpen,
        hwEnrolment,
        liveConnections(CONNECTION),
      );
      expect(
        await codeOf(
          service.createSummary(
            user,
            { ...dto, connectionId: OTHER_CONNECTION },
            REQUEST_ID,
          ),
        ),
      ).toEqual({ status: 404, code: "connection_not_found" });
    });

    it("refuses a snapshot over the limit before any read", async () => {
      const { service, forUser } = setup();
      expect(
        await codeOf(
          service.createSummary(
            user,
            { programmeCode: "hw", snapshot: { big: "x".repeat(49_200) } },
            REQUEST_ID,
          ),
        ),
      ).toEqual({ status: 400, code: "invalid_request" });
      expect(forUser).not.toHaveBeenCalled();
    });

    it("the deletion barrier is checked first", async () => {
      const { service, calls } = setup(barrierClosed);
      expect(
        await codeOf(service.createSummary(user, dto, REQUEST_ID)),
      ).toEqual({ status: 409, code: "account_deletion_in_progress" });
      expect(calls.filter(([name]) => name === "from")).toEqual([]);
    });

    it.each([
      ["TH022", [], { status: 409, code: "care_consent_required" }],
      ["23514", [], { status: 400, code: "invalid_request" }],
      ["23503", [], { status: 404, code: "enrolment_not_found" }],
      [
        "42501",
        [barrierClosed],
        { status: 409, code: "account_deletion_in_progress" },
      ],
      ["42501", [barrierOpen], { status: 409, code: "care_consent_required" }],
    ])("maps an insert refusal %s", async (code, after: Result[], expected) => {
      const { service } = setup(
        barrierOpen,
        hwEnrolment,
        liveConnections(CONNECTION),
        shareConsents(CONNECTION),
        pg(code),
        ...after,
      );
      expect(
        await codeOf(service.createSummary(user, dto, REQUEST_ID)),
      ).toEqual(expected);
    });

    it("TH010 on insert fails closed", async () => {
      const { service } = setup(
        barrierOpen,
        hwEnrolment,
        liveConnections(CONNECTION),
        shareConsents(CONNECTION),
        pg("TH010"),
      );
      await expect(
        service.createSummary(user, dto, REQUEST_ID),
      ).rejects.toBeInstanceOf(BadGatewayException);
    });
  });

  describe("createMessage", () => {
    it("refuses an attachment without a programme before any read", async () => {
      const { service, forUser } = setup();
      expect(
        await codeOf(
          service.createMessage(
            user,
            { topic: "Plan", message: "Hi", attachment: { snapshot: {} } },
            REQUEST_ID,
          ),
        ),
      ).toEqual({ status: 400, code: "invalid_request" });
      expect(forUser).not.toHaveBeenCalled();
    });

    it("refuses a blank topic or message after trimming", async () => {
      const { service, forUser } = setup();
      for (const dto of [
        { topic: "  ", message: "Hi" },
        { topic: "Plan", message: " \n " },
      ]) {
        expect(
          await codeOf(service.createMessage(user, dto, REQUEST_ID)),
        ).toEqual({ status: 400, code: "invalid_request" });
      }
      expect(forUser).not.toHaveBeenCalled();
    });

    it("sends trimmed text to the only live connection", async () => {
      const { service, calls } = setup(
        barrierOpen,
        liveConnections(CONNECTION),
        {
          data: {
            id: "00000000-0000-4000-8000-000000000061",
            connection_id: CONNECTION,
            enrolment_id: null,
            share_id: null,
            created_at: "2026-10-22T10:00:00.000Z",
          },
          error: null,
        },
      );
      await service.createMessage(
        user,
        { topic: " Plan ", message: " Hello " },
        REQUEST_ID,
      );
      const insert = calls.find(([name]) => name === "insert");
      expect(JSON.parse(insert?.[1] ?? "{}")).toEqual({
        user_id: user.id,
        connection_id: CONNECTION,
        enrolment_id: null,
        topic: "Plan",
        body: "Hello",
        share_id: null,
      });
    });
  });

  describe("supporters and caregivers", () => {
    it("refuses a phone that cannot be read before any read", async () => {
      const { service, forUser } = setup();
      expect(
        await codeOf(
          service.createSupporter(
            user,
            { name: "Jordan", phone: "call me", programmes: ["bf"] },
            REQUEST_ID,
          ),
        ),
      ).toEqual({ status: 400, code: "invalid_request" });
      expect(forUser).not.toHaveBeenCalled();
    });

    it("checks the programmes against the caller's live bf/sf enrolments", async () => {
      const { service, calls } = setup(barrierOpen, {
        data: [{ programme_code: "bf", status: "left" }],
        error: null,
      });
      expect(
        await codeOf(
          service.createSupporter(
            user,
            { name: "Jordan", phone: "(555) 010-4421", programmes: ["bf"] },
            REQUEST_ID,
          ),
        ),
      ).toEqual({ status: 409, code: "programme_not_enrolled" });
      expect(calls.some(([name]) => name === "insert")).toBe(false);
    });

    it("stores the phone in E.164", async () => {
      const { service, calls } = setup(
        barrierOpen,
        { data: [{ programme_code: "sf", status: "focus" }], error: null },
        {
          data: {
            id: "00000000-0000-4000-8000-000000000071",
            name: "Jordan",
            phone: "+15550104421",
            programme_codes: ["sf"],
            help_phrase: null,
            created_at: "2026-10-22T10:00:00.000Z",
            updated_at: "2026-10-22T10:00:00.000Z",
          },
          error: null,
        },
      );
      await service.createSupporter(
        user,
        { name: "Jordan", phone: "555.010.4421", programmes: ["sf"] },
        REQUEST_ID,
      );
      const insert = calls.find(([name]) => name === "insert");
      expect(JSON.parse(insert?.[1] ?? "{}")).toMatchObject({
        phone: "+15550104421",
        programme_codes: ["sf"],
        help_phrase: null,
      });
    });

    it("deleting a supporter that matched nothing is supporter_not_found", async () => {
      const { service } = setup({ data: [], error: null });
      expect(
        await codeOf(service.deleteSupporter(user, CONNECTION, REQUEST_ID)),
      ).toEqual({ status: 404, code: "supporter_not_found" });
    });

    it("a caregiver gets both event kinds by default", async () => {
      const { service, calls } = setup(
        barrierOpen,
        {
          data: { id: ENROLMENT, programme_code: "sd", status: "learn_only" },
          error: null,
        },
        {
          data: {
            id: "00000000-0000-4000-8000-000000000081",
            name: "Rosa",
            phone: "+15550102244",
            scope: ["sd.session_finished", "sd.fall_logged"],
            invite_status: "pending",
            created_at: "2026-10-22T10:00:00.000Z",
            revoked_at: null,
          },
          error: null,
        },
      );
      const result = await service.createCaregiver(
        user,
        { name: "Rosa", phone: "(555) 010-2244" },
        REQUEST_ID,
      );
      expect(result.programmeCode).toBe("sd");
      const insert = calls.find(([name]) => name === "insert");
      expect(JSON.parse(insert?.[1] ?? "{}")).toEqual({
        user_id: user.id,
        enrolment_id: ENROLMENT,
        name: "Rosa",
        phone: "+15550102244",
        scope: ["sd.session_finished", "sd.fall_logged"],
      });
    });
  });
});
