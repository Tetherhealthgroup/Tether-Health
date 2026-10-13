import {
  ArgumentsHost,
  BadGatewayException,
  BadRequestException,
  Logger,
} from "@nestjs/common";
import { PrivacyExceptionFilter } from "./privacy-exception.filter";

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
