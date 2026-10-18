import { ArgumentsHost, BadRequestException, Logger } from "@nestjs/common";
import { PrivacyExceptionFilter } from "./privacy-exception.filter";

const CLIENT_IP = "198.51.100.77";

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
    method: "GET",
    url: "/x?token=secret-query",
    ip: CLIENT_IP,
    ips: [CLIENT_IP],
    headers: { "x-forwarded-for": CLIENT_IP },
    body: { note: "synthetic-body" },
    routeOptions: {},
  };
  const host = {
    switchToHttp: () => ({
      getRequest: () => request,
      getResponse: () => reply,
    }),
  } as unknown as ArgumentsHost;
  new PrivacyExceptionFilter().catch(exception, host);
  return result;
}

describe("PrivacyExceptionFilter", () => {
  it("keeps HttpException statuses", () => {
    expect(run(new BadRequestException("secret detail")).status).toBe(400);
  });

  afterEach(() => jest.restoreAllMocks());

  it("passes the rate limiter's 429 through with a constant body", () => {
    const result = run(
      Object.assign(new Error("slow down: secret detail"), {
        statusCode: 429,
      }),
    );
    expect(result.status).toBe(429);
    expect(result.body).toEqual({
      statusCode: 429,
      error: "Request rejected",
      requestId: "req-1",
    });
    expect(JSON.stringify(result.body)).not.toContain("secret detail");
  });

  it.each([401, 403, 404, 409])(
    "masks a stray non-HttpException with statusCode %i as a 500 and logs it",
    (statusCode) => {
      const errorLog = jest
        .spyOn(Logger.prototype, "error")
        .mockImplementation();
      const result = run(
        Object.assign(new Error("leaky detail"), { statusCode }),
      );
      expect(result.status).toBe(500);
      expect(result.body).toEqual({
        statusCode: 500,
        error: "Service unavailable",
        requestId: "req-1",
      });
      expect(JSON.stringify(result.body)).not.toContain("leaky detail");
      expect(errorLog).toHaveBeenCalledTimes(1);
    },
  );

  it.each([500, 302, 99, 429.5, "429", 428, 430])(
    "masks unexpected statusCode %p as 500",
    (statusCode) => {
      jest.spyOn(Logger.prototype, "error").mockImplementation();
      const result = run(Object.assign(new Error("boom"), { statusCode }));
      expect(result.status).toBe(500);
      expect(JSON.stringify(result.body)).not.toContain("boom");
    },
  );

  it("logs a 429 at warn level without IP, query string, headers or body", () => {
    const warn = jest.spyOn(Logger.prototype, "warn").mockImplementation();
    const error = jest.spyOn(Logger.prototype, "error").mockImplementation();
    run(Object.assign(new Error("slow down"), { statusCode: 429 }));
    expect(error).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledTimes(1);
    const logged = JSON.stringify(warn.mock.calls);
    expect(logged).toContain("rate_limit_exceeded");
    expect(logged).toContain("method=GET");
    expect(logged).toContain("route=/x");
    expect(logged).not.toContain(CLIENT_IP);
    expect(logged).not.toContain("secret-query");
    expect(logged).not.toContain("synthetic-body");
  });

  it("masks errors without a status as 500", () => {
    jest.spyOn(Logger.prototype, "error").mockImplementation();
    expect(run(new Error("boom")).status).toBe(500);
    expect(run(undefined).status).toBe(500);
  });
});
