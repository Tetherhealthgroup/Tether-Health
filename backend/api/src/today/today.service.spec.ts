import { randomUUID } from "node:crypto";
import {
  fakeClients,
  seedEnrolment,
  syntheticMember,
} from "../../test/support/fake-member";
import { ProgrammeDataException } from "../programme-data/programme-data-errors";
import {
  addDays,
  dayWindow,
  effectiveTimeZone,
  localDate,
  startOfLocalDate,
} from "./day-window";
import { TodayService, parseSummaryQuery } from "./today.service";

describe("day window", () => {
  it("an unknown or missing zone is UTC", () => {
    expect(effectiveTimeZone(null)).toBe("UTC");
    expect(effectiveTimeZone("")).toBe("UTC");
    expect(effectiveTimeZone("Nowhere/Synthetic")).toBe("UTC");
    expect(effectiveTimeZone("America/New_York")).toBe("America/New_York");
  });

  it("the date and its bounds follow the member's zone across the UTC day", () => {
    // 2026-10-22T02:30Z is still the 21st in New York and already the 22nd in Kolkata.
    const now = Date.parse("2026-10-22T02:30:00Z");
    expect(dayWindow("America/New_York", now)).toEqual({
      zone: "America/New_York",
      date: "2026-10-21",
      todayStart: "2026-10-21T04:00:00.000Z",
      tomorrowStart: "2026-10-22T04:00:00.000Z",
      last7Start: "2026-10-15T04:00:00.000Z",
    });
    expect(dayWindow("Asia/Kolkata", now)).toMatchObject({
      date: "2026-10-22",
      todayStart: "2026-10-21T18:30:00.000Z",
      tomorrowStart: "2026-10-22T18:30:00.000Z",
    });
    expect(dayWindow(null, now)).toMatchObject({
      zone: "UTC",
      date: "2026-10-22",
      todayStart: "2026-10-22T00:00:00.000Z",
    });
  });

  it("a day with a daylight-saving change is 23 or 25 hours long", () => {
    // New York leaves daylight saving on 2026-11-01.
    const start = startOfLocalDate("America/New_York", "2026-11-01");
    const end = startOfLocalDate("America/New_York", "2026-11-02");
    expect(new Date(start).toISOString()).toBe("2026-11-01T04:00:00.000Z");
    expect((end - start) / 3_600_000).toBe(25);
    expect(localDate("America/New_York", end - 1)).toBe("2026-11-01");
  });

  it("adds calendar days across months", () => {
    expect(addDays("2026-10-28", 6)).toBe("2026-11-03");
    expect(addDays("2026-03-01", -1)).toBe("2026-02-28");
  });
});

describe("parseSummaryQuery", () => {
  it.each([
    [
      { programme: "hw", days: "7" },
      { programme: "hw", days: 7 },
    ],
    [
      { programme: "bf", days: "90" },
      { programme: "bf", days: 90 },
    ],
    [
      { programme: "hw", range: "7d" },
      { programme: "hw", days: 7 },
    ],
    [
      { programme: "st", range: "30d" },
      { programme: "st", days: 30 },
    ],
    [
      { programme: "bf", range: "90d" },
      { programme: "bf", days: 90 },
    ],
  ])("%p → %p", (query, parsed) => {
    expect(parseSummaryQuery(query)).toEqual(parsed);
  });

  it.each([
    {},
    { programme: "hw" },
    { days: "7" },
    { programme: "hw", days: "14" },
    { programme: "hw", days: ["7", "30"] },
    { programme: ["hw", "st"], days: "7" },
    { programme: "hw", days: "7", extra: "1" },
    { programme: "hw", range: "7" },
    { programme: "hw", range: "14d" },
    { programme: "hw", range: "7D" },
    { programme: "hw", range: ["7d", "30d"] },
    { programme: "hw", range: "constructor" },
    { programme: "hw", range: "7d", days: "7" },
    { programme: "hw", range: "7d", days: "30" },
  ])("%p → 400", (query) => {
    expect(() => parseSummaryQuery(query)).toThrow(ProgrammeDataException);
  });
});

describe("TodayService", () => {
  const setup = () => {
    const { fake, clients } = fakeClients();
    return { fake, service: new TodayService(clients) };
  };
  const at = (minutesAgo: number) =>
    new Date(Date.now() - minutesAgo * 60_000).toISOString();
  const observation = (
    user: string,
    enrolment: string,
    code: string,
    metric: string,
    value: number,
    unit: string,
    minutesAgo: number,
    submission = randomUUID(),
  ) => ({
    id: randomUUID(),
    user_id: user,
    enrolment_id: enrolment,
    programme_code: code,
    submission_id: submission,
    metric,
    value,
    unit_ucum: unit,
    effective_at: at(minutesAgo),
    attributes: {},
    created_at: at(0),
  });
  const entry = (
    user: string,
    enrolment: string,
    code: string,
    kind: string,
    payload: object,
    minutesAgo: number,
  ) => ({
    id: randomUUID(),
    user_id: user,
    enrolment_id: enrolment,
    programme_code: code,
    submission_id: randomUUID(),
    kind,
    occurred_at: at(minutesAgo),
    payload,
    created_at: at(0),
  });

  it("each block is built only from its own programme's rows", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    const hw = seedEnrolment(fake, user, "hw");
    const st = seedEnrolment(fake, user, "st");
    const ea = seedEnrolment(fake, user, "ea");
    const ca = seedEnrolment(fake, user, "ca");
    const sd = seedEnrolment(fake, user, "sd");
    const bf = seedEnrolment(fake, user, "bf");
    const sf = seedEnrolment(fake, user, "sf");
    const submission = randomUUID();
    fake.seedRow(
      "observations",
      observation(
        user.id,
        hw,
        "hw",
        "bp_systolic",
        135,
        "mm[Hg]",
        5,
        submission,
      ),
    );
    fake.seedRow(
      "observations",
      observation(
        user.id,
        hw,
        "hw",
        "bp_diastolic",
        88,
        "mm[Hg]",
        5,
        submission,
      ),
    );
    fake.seedRow(
      "observations",
      observation(user.id, st, "st", "glucose", 101, "mg/dL", 1),
    );
    fake.seedRow(
      "programme_entries",
      entry(user.id, ea, "ea", "ea.mood", { mood: "low", topics: ["work"] }, 2),
    );
    fake.seedRow(
      "programme_entries",
      entry(user.id, ca, "ca", "ca.zone_check", { zone: "yellow" }, 3),
    );
    fake.seedRow(
      "programme_entries",
      entry(user.id, sd, "sd", "sd.session", {}, 60),
    );
    fake.seedRow(
      "programme_entries",
      entry(user.id, sd, "sd", "sd.session", {}, 8 * 24 * 60),
    );
    fake.seedRow(
      "programme_entries",
      entry(user.id, sf, "sf", "sf.pause", { reason: "bored" }, 1),
    );
    fake.seedRow("rescue_events", {
      id: randomUUID(),
      user_id: user.id,
      enrolment_id: bf,
      programme_code: "bf",
      submission_id: randomUUID(),
      tool: "walk",
      opened_at: at(4),
      intensity_before: null,
      intensity_after: null,
      helped: "yes",
      escalated: false,
      created_at: at(0),
    });
    fake.addSyncLapse(user.id, "sf", at(10));

    const body = await service.today(user, "r");
    const blocks = Object.fromEntries(
      body.programmes.map((block) => [block.code, block]),
    );
    expect(blocks.hw).toMatchObject({
      lastBp: { systolic: 135, diastolic: 88, pulse: null },
    });
    expect(blocks.st).toMatchObject({
      lastGlucose: { value: 101 },
      lastA1c: null,
    });
    expect(blocks.ea).toMatchObject({ lastMood: { mood: "low" } });
    expect(JSON.stringify(blocks.ea)).not.toContain("work");
    expect(blocks.ca).toMatchObject({ lastZoneCheck: { zone: "yellow" } });
    expect(blocks.sd).toMatchObject({ sessionsLast7Days: 1, lastFallAt: null });
    expect(blocks.sf).toMatchObject({ pausesToday: 1, lapsesLast7Days: 1 });
    expect(blocks.bf).toMatchObject({
      lapsesLast7Days: 0,
      lastLapseAt: null,
      lastHelpfulRescue: { tool: "walk" },
    });
    // A bf rescue is not the account's.
    expect(body.account.lastHelpfulRescue).toBeNull();
    expect(body.checkin.doneToday).toBe(false);
  });

  it("a row whose programme does not match its enrolment is never shown", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    const hw = seedEnrolment(fake, user, "hw");
    seedEnrolment(fake, user, "st");
    // Written by a superuser against the schema's key; the reader still filters by programme.
    fake.seedRow(
      "observations",
      observation(user.id, hw, "st", "glucose", 222, "mg/dL", 1),
    );
    const body = await service.today(user, "r");
    expect(JSON.stringify(body)).not.toContain("222");
  });

  it("left enrolments are omitted; another member's rows never appear", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    const other = syntheticMember(fake);
    seedEnrolment(fake, user, "ea", { status: "left" });
    const otherHw = seedEnrolment(fake, other, "hw");
    seedEnrolment(fake, user, "hw");
    fake.seedRow(
      "observations",
      observation(other.id, otherHw, "hw", "bp_systolic", 160, "mm[Hg]", 1),
    );
    const body = await service.today(user, "r");
    expect(body.programmes.map((block) => block.code)).toEqual(["hw"]);
    expect(body.programmes[0]).toMatchObject({ lastBp: null });
  });

  it("summary covers one programme and its window only", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    const hw = seedEnrolment(fake, user, "hw");
    const st = seedEnrolment(fake, user, "st");
    fake.seedRow(
      "observations",
      observation(user.id, hw, "hw", "chol_ldl", 120, "mg/dL", 60),
    );
    fake.seedRow(
      "observations",
      observation(user.id, hw, "hw", "chol_ldl", 130, "mg/dL", 10 * 24 * 60),
    );
    fake.seedRow(
      "observations",
      observation(user.id, st, "st", "glucose", 99, "mg/dL", 60),
    );
    const week = await service.summary(
      user,
      { programme: "hw", days: "7" },
      "r",
    );
    expect(week.observations.map((row) => row.value)).toEqual([120]);
    const month = await service.summary(
      user,
      { programme: "hw", days: "30" },
      "r",
    );
    expect(month.observations.map((row) => row.value)).toEqual([120, 130]);
    expect(JSON.stringify(month)).not.toContain("glucose");
  });
});
