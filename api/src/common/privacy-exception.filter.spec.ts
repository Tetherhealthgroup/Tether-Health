import { ArgumentsHost, BadRequestException } from "@nestjs/common";
import { PrivacyExceptionFilter } from "./privacy-exception.filter";

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
  const request = { id: "req-1", method: "GET", url: "/x", routeOptions: {} };
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

  it("preserves a 4xx statusCode from plugin errors such as rate limiting", () => {
    const result = run(
      Object.assign(new Error("slow down"), { statusCode: 429 }),
    );
    expect(result.status).toBe(429);
    expect(result.body).toEqual({
      statusCode: 429,
      error: "Request rejected",
      requestId: "req-1",
    });
  });

  it.each([500, 302, 99, 429.5, "429"])(
    "masks unexpected statusCode %p as 500",
    (statusCode) => {
      const result = run(Object.assign(new Error("boom"), { statusCode }));
      expect(result.status).toBe(500);
      expect(JSON.stringify(result.body)).not.toContain("boom");
    },
  );

  it("masks errors without a status as 500", () => {
    expect(run(new Error("boom")).status).toBe(500);
    expect(run(undefined).status).toBe(500);
  });
});
