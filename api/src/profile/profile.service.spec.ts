import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { ProfileService } from "./profile.service";

jest.mock("@supabase/supabase-js", () => ({
  createClient: jest.fn(),
}));

const mockedCreateClient = jest.mocked(createClient);

describe("ProfileService", () => {
  beforeEach(() => jest.clearAllMocks());

  it("forwards the authenticated caller token so Supabase RLS evaluates the caller", async () => {
    const row = {
      id: "00000000-0000-0000-0000-000000000001",
      display_name: "Alex",
      locale: "en" as const,
      time_zone: "UTC",
      onboarding_completed: false,
      avatar_path: null,
      created_at: "2026-09-11T00:00:00.000Z",
      updated_at: "2026-09-11T00:00:00.000Z",
    };
    const maybeSingle = jest.fn().mockResolvedValue({ data: row, error: null });
    const eq = jest.fn().mockReturnValue({ maybeSingle });
    const select = jest.fn().mockReturnValue({ eq });
    const from = jest.fn().mockReturnValue({ select });
    mockedCreateClient.mockReturnValue({ from } as never);

    const config = {
      getOrThrow: jest.fn((key: string) =>
        key === "SUPABASE_URL"
          ? "https://project.supabase.co"
          : "publishable-test-key-with-safe-placeholder",
      ),
    } as unknown as ConfigService;
    const service = new ProfileService(config);
    const user: AuthUser = {
      id: row.id,
      accessToken: "caller-access-token",
      authenticatedAt: 1700000000,
    };

    await expect(service.get(user)).resolves.toMatchObject({
      id: row.id,
      displayName: "Alex",
    });
    expect(mockedCreateClient).toHaveBeenCalledWith(
      "https://project.supabase.co",
      "publishable-test-key-with-safe-placeholder",
      expect.objectContaining({
        global: {
          headers: { Authorization: "Bearer caller-access-token" },
        },
      }),
    );
  });
});
