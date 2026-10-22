import { HttpStatus } from "@nestjs/common";
import { submissionIdFrom } from "./idempotency";
import {
  insertErrorFor,
  ProgrammeDataException,
} from "./programme-data-errors";
import { sameRows, type Row } from "./programme-records";
import {
  isDecimal3,
  isEventTime,
  isRecordDate,
  parseTimestamp,
  tomorrowUtc,
} from "./validators";

const coded = (run: () => unknown) => {
  try {
    run();
  } catch (error) {
    if (error instanceof ProgrammeDataException) {
      return [error.getStatus(), error.code];
    }
    throw error;
  }
  throw new Error("did not throw");
};

describe("Idempotency-Key", () => {
  it("maps the app's 32 hex characters to the same 128-bit value as a UUID", () => {
    expect(submissionIdFrom("0123456789abcdef0123456789abcdef")).toBe(
      "01234567-89ab-cdef-0123-456789abcdef",
    );
  });

  it("accepts a canonical UUID in either case, as lowercase", () => {
    expect(submissionIdFrom("01234567-89AB-CDEF-0123-456789ABCDEF")).toBe(
      "01234567-89ab-cdef-0123-456789abcdef",
    );
  });

  it("missing is idempotency_key_required", () => {
    expect(coded(() => submissionIdFrom(undefined))).toEqual([
      HttpStatus.BAD_REQUEST,
      "idempotency_key_required",
    ]);
  });

  it.each([
    "",
    "0123456789ABCDEF0123456789ABCDEF",
    "0123456789abcdef0123456789abcde",
    "0123456789abcdef0123456789abcdef0",
    "0123456789abcdeg0123456789abcdef",
    "{01234567-89ab-cdef-0123-456789abcdef}",
    "0123456789abcdef0123456789abcdef, 0123456789abcdef0123456789abcdef",
    ["0123456789abcdef0123456789abcdef"],
  ])("%j is idempotency_key_invalid", (header) => {
    expect(coded(() => submissionIdFrom(header))).toEqual([
      HttpStatus.BAD_REQUEST,
      "idempotency_key_invalid",
    ]);
  });
});

describe("insert error map (by SQLSTATE only)", () => {
  it.each([
    ["23514", HttpStatus.UNPROCESSABLE_ENTITY, "invalid_record"],
    ["23503", HttpStatus.NOT_FOUND, "enrolment_not_found"],
    ["42501", HttpStatus.CONFLICT, "record_not_allowed"],
  ])("%s -> %i %s", (code, status, name) => {
    const error = insertErrorFor(code);
    expect(error?.getStatus()).toBe(status);
    expect(error?.code).toBe(name);
  });

  it.each([
    "23505",
    "TH026",
    "TH027",
    "TH006",
    "22003",
    "23502",
    "PGRST205",
    undefined,
  ])("%s has no client error (replay rule or 502)", (code) => {
    expect(insertErrorFor(code)).toBeNull();
  });
});

describe("replay comparison", () => {
  const base: Row = {
    user_id: "AAAAAAAA-0000-4000-8000-000000000001",
    enrolment_id: "bbbbbbbb-0000-4000-8000-000000000002",
    programme_code: "hw",
    submission_id: "cccccccc-0000-4000-8000-000000000003",
    metric: "bp_systolic",
    value: 132,
    unit_ucum: "mm[Hg]",
    effective_at: "2026-10-22T08:00:00Z",
    attributes: { feelings: ["fine"], timing: "fasting" },
  };
  const fields = [
    "user_id",
    "enrolment_id",
    "programme_code",
    "metric",
    "value",
    "unit_ucum",
    "attributes",
  ];

  it("equal rows are a replay, whatever the times, ids or row order", () => {
    const other = {
      ...base,
      metric: "bp_diastolic",
      value: 84,
    };
    const stored = [
      {
        ...other,
        id: "x",
        created_at: "2026-10-22T08:01:00Z",
        effective_at: "2026-10-22T07:00:00Z",
      },
      {
        ...base,
        user_id: (base.user_id as string).toLowerCase(),
        value: "132.000",
        attributes: { timing: "fasting", feelings: ["fine"] },
        submission_id: "different",
        effective_at: "2026-10-21T00:00:00Z",
      },
    ];
    expect(sameRows(stored, [base, other], fields)).toBe(true);
  });

  it.each([
    ["value", { value: 133 }],
    ["metric", { metric: "heart_rate" }],
    ["enrolment", { enrolment_id: "bbbbbbbb-0000-4000-8000-000000000009" }],
    ["attributes", { attributes: { timing: "bedtime", feelings: ["fine"] } }],
    [
      "array order",
      { attributes: { timing: "fasting", feelings: ["fine", "shaky"] } },
    ],
  ])("a different %s is a conflict", (_name, change) => {
    expect(sameRows([{ ...base, ...change }], [base], fields)).toBe(false);
  });

  it("a different number of rows is a conflict", () => {
    expect(
      sameRows([base], [base, { ...base, metric: "heart_rate" }], fields),
    ).toBe(false);
    expect(sameRows([base, base], [base], fields)).toBe(false);
  });
});

describe("times, dates and numbers", () => {
  const now = Date.parse("2026-10-22T12:00:00Z");

  it.each([
    ["2026-10-22T12:05:00Z", true],
    ["2026-10-22T12:05:00.001Z", false],
    ["2026-10-22T17:34:59+05:30", true],
    ["2026-10-22T17:35:01+05:30", false],
    ["1999-01-01T00:00:00Z", true],
    ["2026-10-22T12:00:00.123456Z", true],
    ["2026-10-22T12:00:00", false],
    ["2026-10-22 12:00:00Z", false],
    ["2026-02-30T00:00:00Z", false],
    ["2026-10-22T24:00:00Z", false],
    ["2026-10-22", false],
    [1761134400000, false],
    [null, false],
  ])("event time %j -> %s", (value, ok) => {
    expect(isEventTime(value, now)).toBe(ok);
  });

  it("parses offsets to the instant", () => {
    expect(parseTimestamp("2026-10-22T17:30:00+05:30")).toBe(now);
  });

  it.each([
    ["1900-01-01", true],
    ["1899-12-31", false],
    ["2026-10-23", true],
    ["2026-10-24", false],
    ["2026-02-29", false],
    ["2024-02-29", true],
    ["2026-1-02", false],
    ["2026-10-22T00:00:00Z", false],
    [20261022, false],
  ])("record date %j -> %s", (value, ok) => {
    expect(isRecordDate(value, now)).toBe(ok);
  });

  it("tomorrow is the next UTC date", () => {
    expect(tomorrowUtc(Date.parse("2026-12-31T23:59:59Z"))).toBe("2027-01-01");
  });

  it.each([
    [7.4, true],
    [7.125, true],
    [0, true],
    [7.1255, false],
    [1e-7, false],
    [Number.NaN, false],
    [Number.POSITIVE_INFINITY, false],
    ["7.4", false],
  ])("decimal %j -> %s", (value, ok) => {
    expect(isDecimal3(value)).toBe(ok);
  });
});
