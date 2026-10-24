import { fakeClients, syntheticMember } from "../../test/support/fake-member";
import { AGE_RANGES } from "./baseline.dto";
import { BaselineService } from "./baseline.service";

describe("BaselineService", () => {
  const setup = () => {
    const { fake, clients } = fakeClients();
    return { fake, service: new BaselineService(clients) };
  };

  it.each([...AGE_RANGES])("accepts the band %s", async (ageRange) => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    expect(await service.put(user, { ageRange }, "r")).toEqual({
      ageRange,
      sleepBand: null,
      stressBand: null,
    });
  });

  it.each(["35_35", "95_99", "35-44", "18_29", "75plus", "", 40])(
    "refuses %p (not a band) before any write",
    async (ageRange) => {
      const { fake, service } = setup();
      const user = syntheticMember(fake);
      await expect(service.put(user, { ageRange }, "r")).rejects.toMatchObject({
        code: "invalid_request",
      });
      expect(fake.table("wellbeing_baseline")).toHaveLength(0);
    },
  );

  it("PUT replaces every value (absent → null) and keeps one row", async () => {
    const { fake, service } = setup();
    const user = syntheticMember(fake);
    await service.put(
      user,
      { ageRange: "25_34", sleepBand: "lt5", stressBand: "some" },
      "r",
    );
    await service.put(user, { stressBand: "low" }, "r");
    expect(await service.get(user, "r")).toEqual({
      ageRange: null,
      sleepBand: null,
      stressBand: "low",
    });
    expect(fake.table("wellbeing_baseline")).toHaveLength(1);
  });
});
