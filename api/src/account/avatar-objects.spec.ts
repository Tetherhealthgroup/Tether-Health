import type { UserSupabaseClient } from "../enrolments/user-supabase-client";
import { deleteAvatarObjects } from "./avatar-objects";

const userId = "00000000-0000-4000-8000-000000000001";

describe("deleteAvatarObjects", () => {
  const listV2 = jest.fn();
  const remove = jest.fn();
  const storageFrom = jest.fn();
  const client = {
    storage: { from: storageFrom },
  } as unknown as UserSupabaseClient;

  beforeEach(() => {
    jest.clearAllMocks();
    storageFrom.mockReturnValue({ listV2, remove });
  });

  it("deletes nested avatar objects through every cursor page", async () => {
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

    await expect(deleteAvatarObjects(client, userId)).resolves.toBe(102);

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

    await expect(deleteAvatarObjects(client, userId)).rejects.toThrow(
      "outside the user prefix",
    );
    expect(remove).not.toHaveBeenCalled();
  });

  it("rejects non-UUID subjects before accessing storage", async () => {
    await expect(
      deleteAvatarObjects(client, "another-user/../victim"),
    ).rejects.toThrow("not a UUID");
    expect(storageFrom).not.toHaveBeenCalled();
  });

  it("surfaces list, pagination, and incomplete removal failures", async () => {
    const listFailure = { message: "list unavailable" };
    listV2.mockResolvedValueOnce({ data: null, error: listFailure });
    await expect(deleteAvatarObjects(client, userId)).rejects.toBe(listFailure);

    listV2.mockResolvedValueOnce({
      data: { objects: [], folders: [], hasNext: true },
      error: null,
    });
    await expect(deleteAvatarObjects(client, userId)).rejects.toThrow(
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
    await expect(deleteAvatarObjects(client, userId)).rejects.toThrow(
      "incomplete batch",
    );
  });

  it("rejects a repeated pagination cursor without deleting a page twice", async () => {
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

    await expect(deleteAvatarObjects(client, userId)).rejects.toThrow(
      "did not advance",
    );
    expect(listV2).toHaveBeenCalledTimes(2);
    expect(remove).not.toHaveBeenCalled();
  });

  it("surfaces Storage removal errors", async () => {
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

    await expect(deleteAvatarObjects(client, userId)).rejects.toBe(
      removalFailure,
    );
  });
});
