import { ArgumentsHost, BadRequestException } from "@nestjs/common";
import {
  EnrolmentsExceptionFilter,
  conflict,
  registryErrorFor,
} from "./enrolment-errors";

function run(exception: unknown): { status: number; body: unknown } {
  const result = { status: 0, body: undefined as unknown };
  const reply = {
    status(code: number) {
      result.status = code;
      return this;
    },
    send(body: unknown) {
      result.body = body;
    },
  };
  const request = {
    id: "req-1",
    method: "POST",
    url: "/v1/enrolments/consents",
    body: { consentText: "synthetic-canary" },
    routeOptions: {},
  };
  const host = {
    switchToHttp: () => ({
      getRequest: () => request,
      getResponse: () => reply,
    }),
  } as unknown as ArgumentsHost;
  new EnrolmentsExceptionFilter().catch(exception, host);
  return result;
}

describe("EnrolmentsExceptionFilter", () => {
  it("adds only the stable code to coded errors", () => {
    expect(run(conflict("focus_cap_reached"))).toEqual({
      status: 409,
      body: {
        statusCode: 409,
        error: "Request rejected",
        code: "focus_cap_reached",
        requestId: "req-1",
      },
    });
  });

  it("answers other errors exactly like the global privacy filter", () => {
    expect(run(new BadRequestException("synthetic-canary detail"))).toEqual({
      status: 400,
      body: { statusCode: 400, error: "Request rejected", requestId: "req-1" },
    });
  });
});

describe("registryErrorFor", () => {
  it.each([
    ["TH001", 409, "focus_cap_reached"],
    ["TH004", 409, "core_consent_required"],
    ["TH005", 409, "enrolment_left"],
    ["TH006", 409, "account_deletion_in_progress"],
    ["TH011", 409, "consent_document_unavailable"],
    ["TH012", 404, "enrolment_not_found"],
    ["TH013", 409, "focus_swap_invalid"],
    ["TH014", 409, "consent_version_unchanged"],
  ])("maps %s to %d %s", (code, status, token) => {
    const error = registryErrorFor(code);
    expect({ status: error?.getStatus(), code: error?.code }).toEqual({
      status,
      code: token,
    });
  });

  // Not the caller's to fix, or not a registry code: the call site answers
  // 502. TH002/TH003 are mapped only where they can occur (revoke, update).
  it.each([
    "TH002",
    "TH003",
    "TH007",
    "TH008",
    "TH009",
    "TH010",
    "TH015",
    "TH999",
    "23505",
    "constructor",
    "__proto__",
    undefined,
  ])("has no response for %s", (code) => {
    expect(registryErrorFor(code)).toBeUndefined();
  });
});
