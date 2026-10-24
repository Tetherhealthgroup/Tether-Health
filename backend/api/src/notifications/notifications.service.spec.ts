import {
  fakeClients,
  seedEnrolment,
  syntheticMember,
} from "../../test/support/fake-member";
import { ProgrammeDataException } from "../programme-data/programme-data-errors";
import {
  NOTIFICATION_DEFAULTS,
  isProgrammeReminders,
} from "./notifications.dto";
import { NotificationsService } from "./notifications.service";

describe("NotificationsService", () => {
  const setup = () => {
    const { fake, clients } = fakeClients();
    return { fake, service: new NotificationsService(clients) };
  };

  it("never saved → stored defaults: reminders off, persisted false", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    expect(await service.get(user, "r")).toEqual({
      remindersEnabled: false,
      sensitiveDetails: false,
      quietHoursEnabled: true,
      persisted: false,
      programmeReminders: [],
    });
    expect(NOTIFICATION_DEFAULTS.remindersEnabled).toBe(false);
  });

  it("a partial patch writes only the fields present", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    await service.patch(user, { quietHoursEnabled: false }, "r");
    expect(fake.table("notification_preferences")).toEqual([
      expect.objectContaining({
        reminders_enabled: false,
        sensitive_details: false,
        quiet_hours_enabled: false,
      }),
    ]);
    const update = fake.requests.filter(
      (request) =>
        request.method === "PATCH" &&
        request.path.endsWith("/notification_preferences"),
    );
    expect(update.map((request) => request.body)).toEqual([
      { quiet_hours_enabled: false },
    ]);
    await service.patch(user, { remindersEnabled: true }, "r");
    expect(await service.get(user, "r")).toMatchObject({
      remindersEnabled: true,
      quietHoursEnabled: false,
      persisted: true,
    });
  });

  it("only reminders → no settings row is created", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    seedEnrolment(fake, user, "sf");
    const result = await service.patch(
      user,
      { programmeReminders: [{ programme: "sf", remindAt: "21:30" }] },
      "r",
    );
    expect(result).toMatchObject({
      persisted: false,
      programmeReminders: [{ programme: "sf", remindAt: "21:30" }],
    });
    expect(fake.table("notification_preferences")).toHaveLength(0);
  });

  it("a reminder without live core consent is refused before any write", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    seedEnrolment(fake, user, "sf", { core: false });
    await expect(
      service.patch(
        user,
        {
          remindersEnabled: true,
          programmeReminders: [{ programme: "sf", remindAt: "07:00" }],
        },
        "r",
      ),
    ).rejects.toMatchObject({ code: "core_consent_required" });
    expect(fake.table("notification_preferences")).toHaveLength(0);
  });

  it("an unknown key is refused", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    await expect(
      service.patch(user, { reminders: true }, "r"),
    ).rejects.toBeInstanceOf(ProgrammeDataException);
  });
});

describe("isProgrammeReminders", () => {
  it.each([
    [[], true],
    [[{ programme: "bf", remindAt: "00:00" }], true],
    [[{ programme: "bf", remindAt: "23:59" }], true],
    [[{ programme: "bf", remindAt: "7:00" }], false],
    [[{ programme: "bf", remindAt: null }], false],
    [[{ programme: "bf" }], false],
    [
      [
        { programme: "bf", remindAt: "08:00" },
        { programme: "bf", remindAt: "09:00" },
      ],
      false,
    ],
    [{ programme: "bf", remindAt: "08:00" }, false],
  ])("%p → %p", (value, valid) => {
    expect(isProgrammeReminders(value)).toBe(valid);
  });
});
