import type { UserSupabaseClient } from "../enrolments/user-supabase-client";

const AVATAR_PAGE_SIZE = 100;
const AVATAR_REMOVAL_BATCH_SIZE = 100;

/**
 * Removes every object under `<userId>/` in the `avatars` bucket through the
 * Storage API and returns how many were removed. `client` acts as the member
 * (their own access token), so Storage applies the member's own select and
 * delete policies; an object those policies do not let the member remove
 * comes back as a short batch, which is an error. Lists with cursor
 * pagination, refuses any listed object outside the exact prefix, and fails
 * if a cursor is missing or does not advance.
 */
export async function deleteAvatarObjects(
  client: UserSupabaseClient,
  userId: string,
): Promise<number> {
  const prefix = `${requireUuid(userId)}/`;
  const avatars = client.storage.from("avatars");
  const seenCursors = new Set<string>();
  let cursor: string | undefined;
  let deleted = 0;

  do {
    const listed = await avatars.listV2({
      prefix,
      cursor,
      limit: AVATAR_PAGE_SIZE,
      with_delimiter: false,
      sortBy: { column: "name", order: "asc" },
    });
    if (listed.error) throw listed.error;

    const paths = listed.data.objects.map((object) => {
      const path =
        object.key ??
        (object.name.startsWith(prefix)
          ? object.name
          : `${prefix}${object.name}`);
      if (!path.startsWith(prefix)) {
        throw new Error("Storage returned an object outside the user prefix");
      }
      return path;
    });

    for (
      let offset = 0;
      offset < paths.length;
      offset += AVATAR_REMOVAL_BATCH_SIZE
    ) {
      const batch = paths.slice(offset, offset + AVATAR_REMOVAL_BATCH_SIZE);
      const removal = await avatars.remove(batch);
      if (removal.error || removal.data.length !== batch.length) {
        throw removal.error ?? new Error("Storage removed an incomplete batch");
      }
      deleted += removal.data.length;
    }

    if (listed.data.hasNext && !listed.data.nextCursor) {
      throw new Error("Storage pagination cursor is missing");
    }
    cursor = listed.data.hasNext ? listed.data.nextCursor : undefined;
    if (cursor && seenCursors.has(cursor)) {
      throw new Error("Storage pagination cursor did not advance");
    }
    if (cursor) seenCursors.add(cursor);
  } while (cursor);

  return deleted;
}

function requireUuid(userId: string): string {
  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
      userId,
    )
  ) {
    throw new Error("Verified user subject is not a UUID");
  }
  return userId;
}
