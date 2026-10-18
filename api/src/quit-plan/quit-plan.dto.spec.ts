import "reflect-metadata";
import { plainToInstance } from "class-transformer";
import { validate } from "class-validator";
import {
  dailyCigaretteUseValues,
  preparationTaskValues,
  PutQuitPlanDto,
  quitPlanPathValues,
  quitReasonValues,
  readinessPathValues,
  smokingTriggerValues,
} from "./quit-plan.dto";

// Options shown by the BreatheFree onboarding screens, mapped to the stored
// values. Each table lists every option the screen offers.
const spec = {
  // bf_q1 "On a typical day, how many cigarettes?"
  dailyCigaretteUse: {
    "I don’t smoke every day": "notEveryDay",
    "10 or fewer": "tenOrFewer",
    "11–20": "elevenToTwenty",
    "21–30": "twentyOneToThirty",
    "31 or more": "thirtyOneOrMore",
  },
  // bf_q2 "When do you most want a cigarette?"
  smokingTriggers: {
    Stress: "stress",
    "After meals": "afterMeals",
    Driving: "driving",
    "With coffee": "coffee",
    Social: "socialSettings",
    "Work breaks": "workBreaks",
    Alcohol: "alcohol",
    Boredom: "boredom",
    Morning: "morning",
    Scrolling: "scrolling",
  },
  // bf_q3 "What are you quitting for?"
  quitReasons: {
    "Protect my family": "family",
    "Breathe easier": "breatheEasier",
    "Save money": "saveMoney",
    "Feel in control": "control",
    "My health": "improveHealth",
    "Be there for my future": "future",
  },
  // bf_path "What feels possible right now?"
  quitPlanPath: {
    "Set a quit date": "setQuitDate",
    "Quit today": "quitToday",
    "Reduce gradually": "reduceGradually",
    "Explore first": "exploreFirst",
  },
  // bf_support "Prepare your space" checklist
  preparationTasks: {
    "Remove cigarettes, lighters, ashtrays": "removeSupplies",
    "Make home and car smoke-free": "smokeFreeSpaces",
    "Stock gum, water or snacks": "stockAlternatives",
  },
} as const;

const basePlan = () => ({
  dailyCigaretteUse: "tenOrFewer",
  smokingTriggers: ["stress"],
  customSmokingTrigger: null,
  readinessPath: "prepare",
  quitPlanPath: "setQuitDate",
  quitDate: "2026-10-01",
  quitDayCheckIn: true,
  quitReasons: ["family"],
  customQuitReason: null,
  topQuitReason: "family",
  supportPeople: [],
  preparationTasks: [],
  treatmentSupport: true,
  careTeamReminder: true,
});

async function errorsFor(input: Record<string, unknown>) {
  const dto = plainToInstance(PutQuitPlanDto, input);
  const errors = await validate(dto, {
    whitelist: true,
    forbidNonWhitelisted: true,
  });
  return errors.map((error) => error.property);
}

describe("PutQuitPlanDto option validation", () => {
  it("maps every onboarding option to an accepted value", () => {
    const accepted: Record<keyof typeof spec, readonly string[]> = {
      dailyCigaretteUse: dailyCigaretteUseValues,
      smokingTriggers: smokingTriggerValues,
      quitReasons: quitReasonValues,
      quitPlanPath: quitPlanPathValues,
      preparationTasks: preparationTaskValues,
    };
    for (const [field, mapping] of Object.entries(spec)) {
      for (const value of Object.values(mapping)) {
        expect(accepted[field as keyof typeof spec]).toContain(value);
      }
    }
  });

  it.each(Object.entries(spec.dailyCigaretteUse))(
    "accepts bf_q1 %s",
    async (_label, value) => {
      await expect(
        errorsFor({ ...basePlan(), dailyCigaretteUse: value }),
      ).resolves.toEqual([]);
    },
  );

  it.each(Object.entries(spec.smokingTriggers))(
    "accepts bf_q2 %s",
    async (_label, value) => {
      await expect(
        errorsFor({ ...basePlan(), smokingTriggers: [value] }),
      ).resolves.toEqual([]);
    },
  );

  it("accepts every bf_q2 trigger selected at once", async () => {
    await expect(
      errorsFor({
        ...basePlan(),
        smokingTriggers: Object.values(spec.smokingTriggers),
      }),
    ).resolves.toEqual([]);
  });

  it("keeps the legacy beforeBed trigger valid, alone or with scrolling", async () => {
    await expect(
      errorsFor({ ...basePlan(), smokingTriggers: ["beforeBed"] }),
    ).resolves.toEqual([]);
    await expect(
      errorsFor({ ...basePlan(), smokingTriggers: [...smokingTriggerValues] }),
    ).resolves.toEqual([]);
  });

  it("rejects unknown or duplicate triggers", async () => {
    await expect(
      errorsFor({ ...basePlan(), smokingTriggers: ["Scrolling"] }),
    ).resolves.toEqual(["smokingTriggers"]);
    await expect(
      errorsFor({ ...basePlan(), smokingTriggers: ["scrolling", "scrolling"] }),
    ).resolves.toEqual(["smokingTriggers"]);
  });

  it.each(Object.entries(spec.quitReasons))(
    "accepts bf_q3 %s",
    async (_label, value) => {
      await expect(
        errorsFor({
          ...basePlan(),
          quitReasons: [value],
          topQuitReason: value,
        }),
      ).resolves.toEqual([]);
    },
  );

  it.each(Object.entries(spec.quitPlanPath))(
    "accepts bf_path %s",
    async (_label, value) => {
      await expect(
        errorsFor({
          ...basePlan(),
          quitPlanPath: value,
          readinessPath: value === "exploreFirst" ? "explore" : "prepare",
        }),
      ).resolves.toEqual([]);
    },
  );

  it.each(readinessPathValues)(
    "keeps readinessPath %s valid",
    async (value) => {
      await expect(
        errorsFor({ ...basePlan(), readinessPath: value }),
      ).resolves.toEqual([]);
    },
  );

  it("rejects an unknown quit path", async () => {
    await expect(
      errorsFor({ ...basePlan(), quitPlanPath: "explore" }),
    ).resolves.toEqual(["quitPlanPath"]);
  });

  it("accepts every bf_support preparation task", async () => {
    await expect(
      errorsFor({
        ...basePlan(),
        preparationTasks: Object.values(spec.preparationTasks),
      }),
    ).resolves.toEqual([]);
  });
});
