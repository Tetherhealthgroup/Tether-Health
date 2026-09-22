import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { AccountService } from "./account.service";

jest.mock("@supabase/supabase-js", () => ({ createClient: jest.fn() }));

const mockedCreateClient = jest.mocked(createClient);
const user = (authenticatedAt: number): AuthUser => ({
  id: "00000000-0000-0000-0000-000000000001",
  accessToken: "caller-token",
  authenticatedAt,
});
const config = {
  getOrThrow: jest.fn((key: string) => {
    if (key === "SUPABASE_URL") return "https://project.supabase.co";
    if (key === "SUPABASE_ANON_KEY") return "publishable-placeholder-key";
    if (key === "RECENT_AUTH_MAX_AGE_SECONDS") return 600;
    throw new Error(`Unexpected config key ${key}`);
  }),
} as unknown as ConfigService;

describe("AccountService", () => {
  beforeEach(() => jest.clearAllMocks());

  it("rejects export when authentication is not recent", async () => {
    const service = new AccountService(config);
    await expect(service.export(user(1))).rejects.toMatchObject({
      status: 401,
    });
    expect(mockedCreateClient).not.toHaveBeenCalled();
  });

  it("exports only caller-scoped profile and quit-plan rows", async () => {
    const profileSingle = jest.fn().mockResolvedValue({
      data: { id: user(0).id, display_name: "Alex" },
      error: null,
    });
    const planSingle = jest.fn().mockResolvedValue({
      data: { user_id: user(0).id, readiness_path: "prepare" },
      error: null,
    });
    const profileEq = jest.fn().mockReturnValue({ single: profileSingle });
    const planEq = jest.fn().mockReturnValue({ maybeSingle: planSingle });
    const from = jest
      .fn()
      .mockReturnValueOnce({ select: () => ({ eq: profileEq }) })
      .mockReturnValueOnce({ select: () => ({ eq: planEq }) });
    mockedCreateClient.mockReturnValue({ from } as never);

    const service = new AccountService(config);
    const result = await service.export(user(Math.floor(Date.now() / 1000)));
    expect(result).toMatchObject({
      schemaVersion: "1.0",
      profile: { display_name: "Alex" },
      quitPlan: { readiness_path: "prepare" },
    });
    expect(profileEq).toHaveBeenCalledWith("id", user(0).id);
    expect(planEq).toHaveBeenCalledWith("user_id", user(0).id);
  });

  it("deletes app rows through the caller-scoped RPC and returns a receipt", async () => {
    const single = jest.fn().mockResolvedValue({
      data: { avatar_path: null },
      error: null,
    });
    const eq = jest.fn().mockReturnValue({ single });
    const from = jest.fn().mockReturnValue({ select: () => ({ eq }) });
    const rpc = jest.fn().mockResolvedValue({
      data: { profiles: 1, quit_plans: 1 },
      error: null,
    });
    mockedCreateClient.mockReturnValue({ from, rpc } as never);

    const service = new AccountService(config);
    const result = await service.deleteData(
      user(Math.floor(Date.now() / 1000)),
      "DELETE",
    );
    expect(rpc).toHaveBeenCalledWith("delete_my_app_data", {
      p_confirmation: "DELETE",
    });
    expect(result).toMatchObject({
      deleted: { profiles: 1, quitPlans: 1, avatarObjects: 0 },
      authIdentityDeleted: false,
      authIdentityStatus: "external-action-required",
    });
  });
});
