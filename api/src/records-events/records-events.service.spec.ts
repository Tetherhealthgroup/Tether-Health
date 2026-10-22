import { randomUUID } from "node:crypto";
import {
  fakeClients,
  seedEnrolment,
  syntheticMember,
} from "../../test/support/fake-member";
import { ProgrammeDataException } from "../programme-data/programme-data-errors";
import { NoFocusProgrammeException } from "./records-errors";
import {
  RecordsEventsService,
  checkInReplayMatches,
  checkInRows,
} from "./records-events.service";

const NOW = "2026-10-22T09:00:00.000Z";
const SUBMISSION = "0123abcd-0123-4abc-8def-0123456789ab";

/** The coded refusal a promise rejects with. */
async function refusal(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (
      error instanceof ProgrammeDataException ||
      error instanceof NoFocusProgrammeException
    ) {
      return `${error.getStatus()} ${error.code}`;
    }
    throw error;
  }
  throw new Error("expected a refusal");
}

describe("checkInRows (the split)", () => {
  const targets = [
    { enrolmentId: "e-bf", programmeCode: "bf" },
    { enrolmentId: "e-sf", programmeCode: "sf" },
    { enrolmentId: "e-ea", programmeCode: "ea" },
  ];

  it("one row per target, each with feel, stress and only its own answer", () => {
    const rows = checkInRows(
      { feel: "low", stress: "some", answers: { bf: "no", sf: "better" } },
      targets,
      "u",
      SUBMISSION,
      NOW,
    );
    expect(rows.map((row) => [row.enrolment_id, row.payload])).toEqual([
      ["e-bf", { feel: "low", stress: "some", answer: "no" }],
      ["e-sf", { feel: "low", stress: "some", answer: "better" }],
      ["e-ea", { feel: "low", stress: "some" }],
    ]);
    for (const row of rows) {
      expect(row).toMatchObject({
        user_id: "u",
        kind: "checkin",
        submission_id: SUBMISSION,
        occurred_at: NOW,
      });
    }
  });

  it("a target whose row would be empty gets none", () => {
    const rows = checkInRows(
      { answers: { sf: "same" } },
      targets,
      "u",
      SUBMISSION,
      NOW,
    );
    expect(rows.map((row) => row.programme_code)).toEqual(["sf"]);
    expect(rows[0]?.payload).toEqual({ answer: "same" });
  });

  it("the client's time is used when sent", () => {
    const at = "2026-10-22T08:00:00+02:00";
    expect(
      checkInRows(
        { feel: "okay", occurredAt: at },
        targets,
        "u",
        SUBMISSION,
        NOW,
      )[0]?.occurred_at,
    ).toBe(at);
  });
});

describe("checkInReplayMatches", () => {
  const row = (enrolment: string, payload: object, at = NOW) => ({
    user_id: "U",
    enrolment_id: enrolment,
    programme_code: "bf",
    kind: "checkin",
    payload,
    occurred_at: at,
  });

  it("equal compared fields match; times are not compared", () => {
    expect(
      checkInReplayMatches(
        [row("E1", { feel: "low" }, "2026-01-01T00:00:00Z")],
        [row("e1", { feel: "low" })],
      ),
    ).toBe(true);
  });

  it("other content does not match", () => {
    expect(
      checkInReplayMatches(
        [row("e1", { feel: "low" })],
        [row("e1", { feel: "good" })],
      ),
    ).toBe(false);
  });

  it("stored rows of enrolments that no longer qualify are not compared", () => {
    expect(
      checkInReplayMatches(
        [row("e1", { feel: "low" }), row("e2", { feel: "low" })],
        [row("e2", { feel: "low" })],
      ),
    ).toBe(true);
  });

  it("no stored row (the key was used for another kind of row) does not match", () => {
    expect(checkInReplayMatches([], [row("e1", { feel: "low" })])).toBe(false);
  });
});

describe("RecordsEventsService", () => {
  const setup = () => {
    const { fake, clients } = fakeClients();
    return { fake, service: new RecordsEventsService(clients) };
  };

  describe("check-ins", () => {
    it("only focus enrolments with live core consent get a row", async () => {
      const { fake, service } = setup();
      const user = syntheticMember(fake);
      seedEnrolment(fake, user, "bf", { status: "focus" });
      seedEnrolment(fake, user, "sf", { status: "focus", core: false });
      seedEnrolment(fake, user, "hw", { status: "learn_only" });
      seedEnrolment(fake, user, "st", { status: "paused" });
      const result = await service.checkIn(
        user,
        { feel: "okay" },
        randomUUID(),
        "r",
      );
      expect(result.status).toBe(201);
      expect(result.body.entries).toEqual(["bf"]);
      expect(
        fake.table("programme_entries").map((row) => row.programme_code),
      ).toEqual(["bf"]);
    });

    it("an answer for a programme that does not qualify → 422 invalid_record", async () => {
      const { fake, service } = setup();
      const user = syntheticMember(fake);
      seedEnrolment(fake, user, "bf", { status: "focus" });
      seedEnrolment(fake, user, "sf", { status: "focus", core: false });
      expect(
        await refusal(
          service.checkIn(user, { answers: { sf: "same" } }, randomUUID(), "r"),
        ),
      ).toBe("422 invalid_record");
      expect(fake.table("programme_entries")).toHaveLength(0);
    });

    it("no qualifying enrolment → 409 no_focus_programme", async () => {
      const { fake, service } = setup();
      const user = syntheticMember(fake);
      seedEnrolment(fake, user, "bf", { status: "paused" });
      expect(
        await refusal(
          service.checkIn(user, { feel: "okay" }, randomUUID(), "r"),
        ),
      ).toBe("409 no_focus_programme");
    });
  });

  describe("rescues: a BreatheFree rescue always carries the BreatheFree enrolment", () => {
    it.each([
      ["missing", null, 404, "enrolment_not_found"],
      ["left", { status: "left" }, 409, "enrolment_left"],
      ["without core consent", { core: false }, 409, "core_consent_required"],
    ] as const)(
      "bf %s → refused, nothing written (never a shared rescue)",
      async (_state, enrolment, status, code) => {
        const { fake, service } = setup();
        const user = syntheticMember(fake);
        if (enrolment !== null) seedEnrolment(fake, user, "bf", enrolment);
        expect(
          await refusal(
            service.rescue(
              user,
              { tool: "walk", programme: "bf" },
              randomUUID(),
              "r",
            ),
          ),
        ).toBe(`${status} ${code}`);
        expect(fake.table("rescue_events")).toHaveLength(0);
      },
    );

    it("bf with deletion started → 409, nothing written", async () => {
      const { fake, service } = setup();
      const user = syntheticMember(fake);
      seedEnrolment(fake, user, "bf");
      fake.startAccountDeletion(user.id);
      expect(
        await refusal(
          service.rescue(
            user,
            { tool: "walk", programme: "bf" },
            randomUUID(),
            "r",
          ),
        ),
      ).toBe("409 account_deletion_in_progress");
      expect(fake.table("rescue_events")).toHaveLength(0);
    });

    it("bf → the row names the bf enrolment; absent → no enrolment, even for a bf-only member", async () => {
      const { fake, service } = setup();
      const user = syntheticMember(fake);
      const bf = seedEnrolment(fake, user, "bf", { status: "focus" });
      await service.rescue(
        user,
        { tool: "walk", programme: "bf" },
        randomUUID(),
        "r",
      );
      await service.rescue(user, { tool: "walk" }, randomUUID(), "r");
      expect(
        fake
          .table("rescue_events")
          .map((row) => [row.enrolment_id, row.programme_code]),
      ).toEqual([
        [bf, "bf"],
        [null, null],
      ]);
    });

    it("any other programme value → 400", async () => {
      const { fake, service } = setup();
      const user = syntheticMember(fake);
      seedEnrolment(fake, user, "sf");
      for (const programme of ["sf", null, "BF", ""]) {
        expect(
          await refusal(
            service.rescue(
              user,
              { tool: "walk", programme },
              randomUUID(),
              "r",
            ),
          ),
        ).toBe("400 invalid_request");
      }
    });
  });

  describe("lessons", () => {
    it("the lesson is the identity: a repeat is 200 replayed", async () => {
      const { fake, service } = setup();
      const user = syntheticMember(fake);
      seedEnrolment(fake, user, "ck");
      const body = { programme: "ck", lessonId: "ck.flu-shot" };
      expect((await service.lesson(user, body, randomUUID(), "r")).status).toBe(
        201,
      );
      expect((await service.lesson(user, body, randomUUID(), "r")).status).toBe(
        200,
      );
      expect(fake.table("lesson_progress")).toHaveLength(1);
    });

    it("a lesson id must start with its programme", async () => {
      const { fake, service } = setup();
      const user = syntheticMember(fake);
      seedEnrolment(fake, user, "ck");
      expect(
        await refusal(
          service.lesson(
            user,
            { programme: "ck", lessonId: "be.x" },
            randomUUID(),
            "r",
          ),
        ),
      ).toBe("400 invalid_request");
    });
  });
});
