import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { SupabaseAdminService } from "../auth/supabase-admin.service";
import { AccountService } from "./account.service";

jest.mock("@supabase/supabase-js", () => ({ createClient: jest.fn() }));

const mockedCreateClient = jest.mocked(createClient);
const user = (authenticatedAt: number): AuthUser => ({
  id: "00000000-0000-4000-8000-000000000001",
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
const deleteAuthIdentity = jest.fn();
const deleteAvatarObjects = jest.fn();
const admin = {
  deleteAuthIdentity,
  deleteAvatarObjects,
} as unknown as SupabaseAdminService;

describe("AccountService", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    deleteAuthIdentity.mockResolvedValue(undefined);
    deleteAvatarObjects.mockResolvedValue(0);
  });

  it("rejects export when authentication is not recent", async () => {
    const service = new AccountService(config, admin);
    await expect(service.export(user(1))).rejects.toMatchObject({
      status: 401,
    });
    expect(mockedCreateClient).not.toHaveBeenCalled();
  });

  it("rejects deletion before any barrier or privileged action when authentication is stale", async () => {
    const service = new AccountService(config, admin);

    await expect(service.deleteData(user(1), "DELETE")).rejects.toMatchObject({
      status: 401,
    });

    expect(mockedCreateClient).not.toHaveBeenCalled();
    expect(deleteAvatarObjects).not.toHaveBeenCalled();
    expect(deleteAuthIdentity).not.toHaveBeenCalled();
  });

  it("exports only caller-scoped profile, quit-plan, and program rows", async () => {
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
    const programReturns = jest.fn().mockResolvedValue({
      data: [{ program_id: "steady", payload: {}, revision: 1 }],
      error: null,
    });
    const profileSelect = jest.fn().mockReturnValue({ eq: profileEq });
    const programEq = jest.fn().mockReturnValue({ returns: programReturns });
    const from = jest
      .fn()
      .mockReturnValueOnce({ select: profileSelect })
      .mockReturnValueOnce({ select: () => ({ eq: planEq }) })
      .mockReturnValueOnce({ select: () => ({ eq: programEq }) });
    mockedCreateClient.mockReturnValue({ from } as never);

    const service = new AccountService(config, admin);
    const result = await service.export(user(Math.floor(Date.now() / 1000)));
    expect(result).toMatchObject({
      schemaVersion: "1.0",
      profile: { display_name: "Alex" },
      quitPlan: { readiness_path: "prepare" },
      programData: [{ programId: "steady", revision: 1 }],
    });
    expect(profileEq).toHaveBeenCalledWith("id", user(0).id);
    expect(planEq).toHaveBeenCalledWith("user_id", user(0).id);
    expect(programEq).toHaveBeenCalledWith("user_id", user(0).id);
    expect(profileSelect).toHaveBeenCalledWith(
      "id,display_name,locale,time_zone,onboarding_completed,avatar_path,created_at,updated_at",
    );
  });

  it("deletes app rows through the caller-scoped RPC and returns a receipt", async () => {
    deleteAvatarObjects.mockResolvedValue(3);
    const rpc = jest.fn((name: string) =>
      Promise.resolve(
        name === "begin_account_deletion"
          ? { data: true, error: null }
          : {
              data: { profiles: 1, quit_plans: 1, program_data: 2 },
              error: null,
            },
      ),
    );
    mockedCreateClient.mockReturnValue({ rpc } as never);

    const service = new AccountService(config, admin);
    const result = await service.deleteData(
      user(Math.floor(Date.now() / 1000)),
      "DELETE",
    );
    expect(rpc.mock.calls).toEqual([
      ["begin_account_deletion", { p_confirmation: "DELETE" }],
      ["delete_my_app_data", { p_confirmation: "DELETE" }],
    ]);
    expect(deleteAvatarObjects).toHaveBeenCalledWith(user(0).id);
    expect(deleteAuthIdentity).toHaveBeenCalledWith(user(0).id);
    expect(rpc.mock.invocationCallOrder[0]).toBeLessThan(
      deleteAvatarObjects.mock.invocationCallOrder[0]!,
    );
    expect(deleteAvatarObjects.mock.invocationCallOrder[0]).toBeLessThan(
      rpc.mock.invocationCallOrder[1]!,
    );
    expect(rpc.mock.invocationCallOrder[1]).toBeLessThan(
      deleteAuthIdentity.mock.invocationCallOrder[0]!,
    );
    expect(result).toMatchObject({
      deleted: {
        profiles: 1,
        quitPlans: 1,
        avatarObjects: 3,
        programData: 2,
      },
      authIdentityDeleted: true,
      authIdentityStatus: "deleted",
    });
  });

  it("fails safely after app-data cleanup when Auth deletion is unavailable", async () => {
    const rpc = jest
      .fn()
      .mockResolvedValueOnce({ data: true, error: null })
      .mockResolvedValueOnce({
        data: { profiles: 1, quit_plans: 1, program_data: 0 },
        error: null,
      });
    mockedCreateClient.mockReturnValue({ rpc } as never);
    deleteAuthIdentity.mockRejectedValueOnce(new Error("admin unavailable"));

    const service = new AccountService(config, admin);
    await expect(
      service.deleteData(user(Math.floor(Date.now() / 1000)), "DELETE"),
    ).rejects.toMatchObject({ status: 502 });
    expect(rpc).toHaveBeenCalledTimes(2);
    expect(deleteAuthIdentity).toHaveBeenCalledWith(user(0).id);
  });

  it("keeps the durable write barrier in place when avatar cleanup fails", async () => {
    const rpc = jest.fn().mockResolvedValue({ data: true, error: null });
    mockedCreateClient.mockReturnValue({ rpc } as never);
    deleteAvatarObjects.mockRejectedValueOnce(new Error("storage unavailable"));
    const service = new AccountService(config, admin);
    await expect(
      service.deleteData(user(Math.floor(Date.now() / 1000)), "DELETE"),
    ).rejects.toMatchObject({ status: 502 });

    expect(rpc).toHaveBeenCalledTimes(1);
    expect(rpc).toHaveBeenCalledWith("begin_account_deletion", {
      p_confirmation: "DELETE",
    });
    expect(deleteAuthIdentity).not.toHaveBeenCalled();
  });

  it("does not run privileged cleanup when the write barrier cannot start", async () => {
    const rpc = jest.fn().mockResolvedValue({
      data: null,
      error: { message: "database unavailable" },
    });
    mockedCreateClient.mockReturnValue({ rpc } as never);

    const service = new AccountService(config, admin);
    await expect(
      service.deleteData(user(Math.floor(Date.now() / 1000)), "DELETE"),
    ).rejects.toMatchObject({ status: 502 });

    expect(deleteAvatarObjects).not.toHaveBeenCalled();
    expect(deleteAuthIdentity).not.toHaveBeenCalled();
  });

  it("safely retries after Auth deletion succeeds but its response is lost", async () => {
    const rpc = jest
      .fn()
      .mockResolvedValueOnce({ data: true, error: null })
      .mockResolvedValueOnce({
        data: { profiles: 1, quit_plans: 1, program_data: 2 },
        error: null,
      })
      .mockResolvedValueOnce({ data: true, error: null })
      .mockResolvedValueOnce({
        data: { profiles: 0, quit_plans: 0, program_data: 0 },
        error: null,
      });
    mockedCreateClient.mockReturnValue({ rpc } as never);
    deleteAvatarObjects.mockResolvedValueOnce(2).mockResolvedValueOnce(0);
    deleteAuthIdentity
      .mockRejectedValueOnce(new Error("response lost"))
      .mockResolvedValueOnce(undefined);
    const service = new AccountService(config, admin);
    const recentUser = user(Math.floor(Date.now() / 1000));

    await expect(
      service.deleteData(recentUser, "DELETE"),
    ).rejects.toMatchObject({ status: 502 });
    await expect(
      service.deleteData(recentUser, "DELETE"),
    ).resolves.toMatchObject({
      deleted: {
        profiles: 0,
        quitPlans: 0,
        avatarObjects: 0,
        programData: 0,
      },
      authIdentityDeleted: true,
    });

    expect(rpc).toHaveBeenCalledTimes(4);
    expect(deleteAvatarObjects).toHaveBeenCalledTimes(2);
    expect(deleteAuthIdentity).toHaveBeenCalledTimes(2);
  });
});
