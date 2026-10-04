import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import { SupabaseAdminService } from "./supabase-admin.service";

jest.mock("@supabase/supabase-js", () => ({ createClient: jest.fn() }));

const mockedCreateClient = jest.mocked(createClient);
const verifiedUserId = "00000000-0000-4000-8000-000000000001";
const config = {
  getOrThrow: jest.fn((key: string) => {
    if (key === "SUPABASE_URL") return "https://project.supabase.co";
    if (key === "SUPABASE_SERVICE_ROLE_KEY") return "server-only-secret-key";
    throw new Error(`Unexpected config key ${key}`);
  }),
} as unknown as ConfigService;

describe("SupabaseAdminService", () => {
  const deleteUser = jest.fn();
  const listV2 = jest.fn();
  const remove = jest.fn();
  const storageFrom = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    mockedCreateClient.mockReturnValue({
      auth: { admin: { deleteUser } },
      storage: { from: storageFrom },
    } as never);
    storageFrom.mockReturnValue({ listV2, remove });
  });

  it("uses the server-only credential and deletes only the supplied verified subject", async () => {
    deleteUser.mockResolvedValue({ data: {}, error: null });
    const service = new SupabaseAdminService(config);

    await service.deleteAuthIdentity(verifiedUserId);

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
    expect(deleteUser).toHaveBeenCalledWith(verifiedUserId, false);
  });

  it("treats an already-absent identity as a successful retry", async () => {
    deleteUser.mockResolvedValue({
      data: null,
      error: { code: "user_not_found" },
    });
    const service = new SupabaseAdminService(config);

    await expect(
      service.deleteAuthIdentity(verifiedUserId),
    ).resolves.toBeUndefined();
  });

  it("surfaces privileged deletion failures", async () => {
    const failure = { code: "unexpected_failure" };
    deleteUser.mockResolvedValue({ data: null, error: failure });
    const service = new SupabaseAdminService(config);

    await expect(service.deleteAuthIdentity(verifiedUserId)).rejects.toBe(
      failure,
    );
  });

  it("deletes nested avatar objects through every cursor page", async () => {
    const userId = "00000000-0000-4000-8000-000000000001";
    const firstPage = Array.from({ length: 100 }, (_, index) => ({
      key: `${userId}/history/${index.toString().padStart(3, "0")}/avatar.webp`,
      name: "avatar.webp",
    }));
    const secondPage = [
      { key: `${userId}/avatar`, name: "avatar" },
      { name: "nested/deeper/avatar.png" },
    ];
    listV2
      .mockResolvedValueOnce({
        data: {
          objects: firstPage,
          folders: [],
          hasNext: true,
          nextCursor: "page-2",
        },
        error: null,
      })
      .mockResolvedValueOnce({
        data: { objects: secondPage, folders: [], hasNext: false },
        error: null,
      });
    remove.mockImplementation((paths: string[]) =>
      Promise.resolve({
        data: paths.map((name) => ({ name })),
        error: null,
      }),
    );
    const service = new SupabaseAdminService(config);

    await expect(service.deleteAvatarObjects(userId)).resolves.toBe(102);

    expect(storageFrom).toHaveBeenCalledWith("avatars");
    expect(listV2).toHaveBeenNthCalledWith(1, {
      prefix: `${userId}/`,
      cursor: undefined,
      limit: 100,
      with_delimiter: false,
      sortBy: { column: "name", order: "asc" },
    });
    expect(listV2).toHaveBeenNthCalledWith(2, {
      prefix: `${userId}/`,
      cursor: "page-2",
      limit: 100,
      with_delimiter: false,
      sortBy: { column: "name", order: "asc" },
    });
    expect(remove).toHaveBeenCalledTimes(2);
    expect(remove).toHaveBeenNthCalledWith(2, [
      `${userId}/avatar`,
      `${userId}/nested/deeper/avatar.png`,
    ]);
  });

  it("refuses a storage result outside the verified user's exact prefix", async () => {
    const userId = "00000000-0000-4000-8000-000000000001";
    listV2.mockResolvedValue({
      data: {
        objects: [
          {
            key: "00000000-0000-4000-8000-000000000002/avatar",
            name: "avatar",
          },
        ],
        folders: [],
        hasNext: false,
      },
      error: null,
    });
    const service = new SupabaseAdminService(config);

    await expect(service.deleteAvatarObjects(userId)).rejects.toThrow(
      "outside the user prefix",
    );
    expect(remove).not.toHaveBeenCalled();
  });

  it("rejects non-UUID subjects before accessing privileged storage", async () => {
    const service = new SupabaseAdminService(config);

    await expect(
      service.deleteAvatarObjects("another-user/../victim"),
    ).rejects.toThrow("not a UUID");
    expect(storageFrom).not.toHaveBeenCalled();
  });

  it("surfaces list, pagination, and incomplete removal failures", async () => {
    const userId = "00000000-0000-4000-8000-000000000001";
    const service = new SupabaseAdminService(config);
    const listFailure = { message: "list unavailable" };
    listV2.mockResolvedValueOnce({ data: null, error: listFailure });
    await expect(service.deleteAvatarObjects(userId)).rejects.toBe(listFailure);

    listV2.mockResolvedValueOnce({
      data: { objects: [], folders: [], hasNext: true },
      error: null,
    });
    await expect(service.deleteAvatarObjects(userId)).rejects.toThrow(
      "cursor is missing",
    );

    listV2.mockResolvedValueOnce({
      data: {
        objects: [{ key: `${userId}/avatar`, name: "avatar" }],
        folders: [],
        hasNext: false,
      },
      error: null,
    });
    remove.mockResolvedValueOnce({ data: [], error: null });
    await expect(service.deleteAvatarObjects(userId)).rejects.toThrow(
      "incomplete batch",
    );
  });

  it("rejects a repeated pagination cursor without deleting a page twice", async () => {
    const userId = "00000000-0000-4000-8000-000000000001";
    listV2
      .mockResolvedValueOnce({
        data: {
          objects: [],
          folders: [],
          hasNext: true,
          nextCursor: "same-cursor",
        },
        error: null,
      })
      .mockResolvedValueOnce({
        data: {
          objects: [],
          folders: [],
          hasNext: true,
          nextCursor: "same-cursor",
        },
        error: null,
      });
    const service = new SupabaseAdminService(config);

    await expect(service.deleteAvatarObjects(userId)).rejects.toThrow(
      "did not advance",
    );
    expect(listV2).toHaveBeenCalledTimes(2);
    expect(remove).not.toHaveBeenCalled();
  });

  it("surfaces Storage removal errors", async () => {
    const userId = "00000000-0000-4000-8000-000000000001";
    const removalFailure = { message: "remove unavailable" };
    listV2.mockResolvedValueOnce({
      data: {
        objects: [{ key: `${userId}/nested/avatar`, name: "avatar" }],
        folders: [],
        hasNext: false,
      },
      error: null,
    });
    remove.mockResolvedValueOnce({ data: null, error: removalFailure });
    const service = new SupabaseAdminService(config);

    await expect(service.deleteAvatarObjects(userId)).rejects.toBe(
      removalFailure,
    );
  });
});
