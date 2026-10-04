import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import { SupabaseAdminService } from "./supabase-admin.service";

jest.mock("@supabase/supabase-js", () => ({ createClient: jest.fn() }));

const mockedCreateClient = jest.mocked(createClient);
const config = {
  getOrThrow: jest.fn((key: string) => {
    if (key === "SUPABASE_URL") return "https://project.supabase.co";
    if (key === "SUPABASE_SERVICE_ROLE_KEY") return "server-only-secret-key";
    throw new Error(`Unexpected config key ${key}`);
  }),
} as unknown as ConfigService;

describe("SupabaseAdminService", () => {
  const deleteUser = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    mockedCreateClient.mockReturnValue({
      auth: { admin: { deleteUser } },
    } as never);
  });

  it("uses the server-only credential and deletes only the supplied verified subject", async () => {
    deleteUser.mockResolvedValue({ data: {}, error: null });
    const service = new SupabaseAdminService(config);

    await service.deleteAuthIdentity("verified-user-id");

    expect(mockedCreateClient).toHaveBeenCalledWith(
      "https://project.supabase.co",
      "server-only-secret-key",
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
          detectSessionInUrl: false,
        },
      },
    );
    expect(deleteUser).toHaveBeenCalledWith("verified-user-id", false);
  });

  it("treats an already-absent identity as a successful retry", async () => {
    deleteUser.mockResolvedValue({
      data: null,
      error: { code: "user_not_found" },
    });
    const service = new SupabaseAdminService(config);

    await expect(
      service.deleteAuthIdentity("verified-user-id"),
    ).resolves.toBeUndefined();
  });

  it("surfaces privileged deletion failures", async () => {
    const failure = { code: "unexpected_failure" };
    deleteUser.mockResolvedValue({ data: null, error: failure });
    const service = new SupabaseAdminService(config);

    await expect(service.deleteAuthIdentity("verified-user-id")).rejects.toBe(
      failure,
    );
  });
});
