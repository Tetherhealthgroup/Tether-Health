import {
  ArgumentsHost,
  BadGatewayException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
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
    expect(logged).toContain("route=unmatched");
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

const SYNTHETIC_EMAIL = "synthetic.patient@example.test";
const SYNTHETIC_NOTE = "SYNTHETIC-HEALTH-NOTE-7f3a";
const SYNTHETIC_TOKEN = "synthetic-bearer-token-0000";
const SYNTHETIC_USER_ID = "00000000-0000-4000-8000-000000000001";
const FORBIDDEN = [
  SYNTHETIC_EMAIL,
  SYNTHETIC_NOTE,
  SYNTHETIC_TOKEN,
  SYNTHETIC_USER_ID,
  "systolic",
  "payload",
  "email",
];

const LOGGER_METHODS = [
  "log",
  "error",
  "warn",
  "debug",
  "verbose",
  "fatal",
] as const;

type Spies = Record<(typeof LOGGER_METHODS)[number], jest.SpyInstance>;

describe("PrivacyExceptionFilter logging", () => {
  let spies: Spies;
  const reply = {
    status: jest.fn().mockReturnThis(),
    send: jest.fn().mockReturnThis(),
  };

  const captured = (): string =>
    JSON.stringify(LOGGER_METHODS.map((m): unknown[] => spies[m].mock.calls));
  const totalLogCalls = (): number =>
    LOGGER_METHODS.reduce((n, m) => n + spies[m].mock.calls.length, 0);
  const host = (request: unknown): ArgumentsHost =>
    ({
      switchToHttp: () => ({
        getRequest: () => request,
        getResponse: () => reply,
      }),
    }) as unknown as ArgumentsHost;
  const request = (overrides: Record<string, unknown> = {}) => ({
    id: "req-synthetic-1",
    method: "PUT",
    url: `/v1/program-data/heartwise?email=${encodeURIComponent(SYNTHETIC_EMAIL)}`,
    routeOptions: { url: "/v1/program-data/:programId" },
    headers: { authorization: `Bearer ${SYNTHETIC_TOKEN}` },
    query: { email: SYNTHETIC_EMAIL },
    body: {
      email: SYNTHETIC_EMAIL,
      payload: { note: SYNTHETIC_NOTE, systolic: 182 },
      userId: SYNTHETIC_USER_ID,
    },
    ...overrides,
  });
  const expectNoForbidden = (text: string): void => {
    for (const value of FORBIDDEN) expect(text).not.toContain(value);
  };

  beforeEach(() => {
    reply.status.mockClear();
    reply.send.mockClear();
    spies = Object.fromEntries(
      LOGGER_METHODS.map((m) => [
        m,
        jest.spyOn(Logger.prototype, m).mockImplementation(() => undefined),
      ]),
    ) as Spies;
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("logs only ids, verb, route template, status and type for a 500", () => {
    new PrivacyExceptionFilter().catch(
      new Error(`db failed for ${SYNTHETIC_EMAIL}: ${SYNTHETIC_NOTE}`),
      host(request()),
    );

    expect(spies.error.mock.calls).toEqual([
      [
        "request_failed requestId=req-synthetic-1 method=PUT route=/v1/program-data/:programId status=500 type=Error",
      ],
    ]);
    expectNoForbidden(captured());
    expect(reply.send).toHaveBeenCalledWith({
      statusCode: 500,
      error: "Service unavailable",
      requestId: "req-synthetic-1",
    });
    expectNoForbidden(JSON.stringify(reply.send.mock.calls));
  });

  it("does not log 4xx rejections and keeps their messages out of the reply", () => {
    new PrivacyExceptionFilter().catch(
      new BadRequestException({
        message: [`email ${SYNTHETIC_EMAIL} invalid`, SYNTHETIC_NOTE],
      }),
      host(request()),
    );

    expect(totalLogCalls()).toBe(0);
    expect(reply.send).toHaveBeenCalledWith({
      statusCode: 400,
      error: "Request rejected",
      requestId: "req-synthetic-1",
    });
    expectNoForbidden(JSON.stringify(reply.send.mock.calls));
  });

  it("logs the type but not the message of a 502 HttpException", () => {
    new PrivacyExceptionFilter().catch(
      new BadGatewayException(SYNTHETIC_NOTE),
      host(request()),
    );

    expect(spies.error).toHaveBeenCalledTimes(1);
    const [line] = spies.error.mock.calls[0] as [string];
    expect(line.endsWith("status=502 type=BadGatewayException")).toBe(true);
    expectNoForbidden(captured());
  });

  it("never logs the caller-controlled path when no route matched", () => {
    new PrivacyExceptionFilter().catch(
      new Error("x"),
      host(
        request({
          routeOptions: {},
          url: `/v1/${SYNTHETIC_EMAIL}/${SYNTHETIC_NOTE}?q=${SYNTHETIC_TOKEN}`,
        }),
      ),
    );

    expect(spies.error).toHaveBeenCalledTimes(1);
    expect(captured()).toContain("route=unmatched");
    expectNoForbidden(captured());
  });

  it("logs a generic type for a thrown non-Error value", () => {
    new PrivacyExceptionFilter().catch(
      { email: SYNTHETIC_EMAIL, payload: SYNTHETIC_NOTE },
      host(request()),
    );

    expect(spies.error).toHaveBeenCalledTimes(1);
    expect(captured()).toContain("type=UnknownError");
    expectNoForbidden(captured());
  });
});
