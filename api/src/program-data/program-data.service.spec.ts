import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import { ProgramDataService } from "./program-data.service";

jest.mock("@supabase/supabase-js", () => ({ createClient: jest.fn() }));
const mockedCreateClient = jest.mocked(createClient);
const user: AuthUser = {
  id: "00000000-0000-0000-0000-000000000001",
  accessToken: "caller-token",
  authenticatedAt: 1,
};
const config = {
  getOrThrow: jest.fn((key: string) =>
    key === "SUPABASE_URL"
      ? "https://project.supabase.co"
      : "publishable-placeholder-key",
  ),
} as unknown as ConfigService;

describe("ProgramDataService", () => {
  beforeEach(() => jest.clearAllMocks());

  it("writes the verified caller id and forwards the caller token", async () => {
    const row = {
      program_id: "steady",
      payload: { readings: [] },
      revision: 3,
      updated_at: "2026-09-26T00:00:00Z",
    };
    const single = jest.fn().mockResolvedValue({ data: row, error: null });
    const select = jest.fn().mockReturnValue({ single });
    const upsert = jest.fn().mockReturnValue({ select });
    const from = jest.fn().mockReturnValue({ upsert });
    mockedCreateClient.mockReturnValue({ from } as never);

    const result = await new ProgramDataService(config).put(user, "steady", {
      payload: { readings: [] },
      revision: 3,
    });

    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({ user_id: user.id, program_id: "steady" }),
      { onConflict: "user_id,program_id" },
    );
    expect(result).toMatchObject({ programId: "steady", revision: 3 });
    expect(mockedCreateClient).toHaveBeenCalledWith(
      expect.any(String),
      expect.any(String),
      expect.objectContaining({
        global: { headers: { Authorization: "Bearer caller-token" } },
      }),
    );
  });

  it("rejects an encoded payload larger than 32 KiB before storage", async () => {
    const service = new ProgramDataService(config);
    await expect(
      service.put(user, "heartwise", {
        payload: { note: "x".repeat(33000) },
        revision: 1,
      }),
    ).rejects.toMatchObject({ status: 400 });
    expect(mockedCreateClient).not.toHaveBeenCalled();
  });
});
