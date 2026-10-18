import { ArgumentsHost, BadRequestException } from "@nestjs/common";
import { EnrolmentsExceptionFilter, conflict } from "./enrolment-errors";

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
