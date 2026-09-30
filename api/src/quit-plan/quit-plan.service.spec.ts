import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import type { PutQuitPlanDto } from "./quit-plan.dto";
import { QuitPlanService } from "./quit-plan.service";

jest.mock("@supabase/supabase-js", () => ({
  createClient: jest.fn(),
}));

const mockedCreateClient = jest.mocked(createClient);

const plan: PutQuitPlanDto = {
  dailyCigaretteUse: "tenOrFewer",
  smokingTriggers: ["stress", "afterMeals"],
  customSmokingTrigger: null,
  readinessPath: "prepare",
  quitPlanPath: "setQuitDate",
  quitDate: "2026-10-01",
  quitDayCheckIn: true,
  quitReasons: ["family", "breatheEasier"],
  customQuitReason: null,
  topQuitReason: "family",
  supportPeople: [
    {
      id: "test-friend",
      name: "Test Friend",
      relationship: "Friend",
      channel: "text",
      checkIn: "Check in the evening before my quit date",
      enabled: true,
    },
  ],
  preparationTasks: ["removeSupplies"],
  treatmentSupport: true,
  careTeamReminder: true,
};

const row = {
  user_id: "00000000-0000-0000-0000-000000000001",
  daily_cigarette_use: plan.dailyCigaretteUse,
  smoking_triggers: plan.smokingTriggers,
  custom_smoking_trigger: plan.customSmokingTrigger,
  readiness_path: plan.readinessPath,
  quit_plan_path: plan.quitPlanPath,
  quit_date: plan.quitDate,
  quit_day_check_in: plan.quitDayCheckIn,
  quit_reasons: plan.quitReasons,
  custom_quit_reason: plan.customQuitReason,
  top_quit_reason: plan.topQuitReason,
  support_people: plan.supportPeople,
  preparation_tasks: plan.preparationTasks,
  treatment_support: plan.treatmentSupport,
  care_team_reminder: plan.careTeamReminder,
  created_at: "2026-09-15T00:00:00.000Z",
  updated_at: "2026-09-15T00:00:00.000Z",
};

const config = {
  getOrThrow: jest.fn((key: string) =>
    key === "SUPABASE_URL"
      ? "https://project.supabase.co"
      : "publishable-test-key-with-safe-placeholder",
  ),
} as unknown as ConfigService;

const user: AuthUser = {
  id: row.user_id,
  accessToken: "caller-access-token",
  authenticatedAt: 1700000000,
};

describe("QuitPlanService", () => {
  beforeEach(() => jest.clearAllMocks());

  it("loads only the authenticated caller's plan through RLS", async () => {
    const maybeSingle = jest.fn().mockResolvedValue({ data: row, error: null });
    const eq = jest.fn().mockReturnValue({ maybeSingle });
    const select = jest.fn().mockReturnValue({ eq });
    const from = jest.fn().mockReturnValue({ select });
    mockedCreateClient.mockReturnValue({ from } as never);

    const service = new QuitPlanService(config);
    await expect(service.get(user)).resolves.toMatchObject({
      userId: user.id,
      quitDate: "2026-10-01",
      topQuitReason: "family",
    });
    expect(eq).toHaveBeenCalledWith("user_id", user.id);
    expect(mockedCreateClient).toHaveBeenCalledWith(
      "https://project.supabase.co",
      "publishable-test-key-with-safe-placeholder",
      expect.objectContaining({
        global: { headers: { Authorization: "Bearer caller-access-token" } },
      }),
    );
  });

  it("upserts a complete snapshot under the authenticated caller id", async () => {
    const single = jest.fn().mockResolvedValue({ data: row, error: null });
    const selectAfterUpsert = jest.fn().mockReturnValue({ single });
    const upsert = jest.fn().mockReturnValue({ select: selectAfterUpsert });
    const from = jest.fn().mockReturnValue({ upsert });
    mockedCreateClient.mockReturnValue({ from } as never);

    const service = new QuitPlanService(config);
    await expect(service.put(user, plan)).resolves.toMatchObject({
      userId: user.id,
      smokingTriggers: ["stress", "afterMeals"],
    });
    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({ user_id: user.id, quit_date: "2026-10-01" }),
      { onConflict: "user_id" },
    );
  });

  it("creates a guest import only when no caller plan exists", async () => {
    const single = jest.fn().mockResolvedValue({ data: row, error: null });
    const selectAfterInsert = jest.fn().mockReturnValue({ single });
    const insert = jest.fn().mockReturnValue({ select: selectAfterInsert });
    const from = jest.fn().mockReturnValue({ insert });
    mockedCreateClient.mockReturnValue({ from } as never);

    const service = new QuitPlanService(config);
    await expect(service.create(user, plan)).resolves.toMatchObject({
      userId: user.id,
      topQuitReason: "family",
    });
    expect(insert).toHaveBeenCalledWith(
      expect.objectContaining({ user_id: user.id, quit_date: "2026-10-01" }),
    );
  });

  it("returns conflict instead of overwriting an existing guest import", async () => {
    const single = jest.fn().mockResolvedValue({
      data: null,
      error: { code: "23505" },
    });
    const selectAfterInsert = jest.fn().mockReturnValue({ single });
    const insert = jest.fn().mockReturnValue({ select: selectAfterInsert });
    const from = jest.fn().mockReturnValue({ insert });
    mockedCreateClient.mockReturnValue({ from } as never);

    const service = new QuitPlanService(config);
    await expect(service.create(user, plan)).rejects.toMatchObject({
      status: 409,
    });
  });

  it("rejects a top reason outside the selected reasons", async () => {
    const service = new QuitPlanService(config);
    await expect(
      service.put(user, { ...plan, topQuitReason: "future" }),
    ).rejects.toMatchObject({ status: 400 });
  });
});
