import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";

@Injectable()
export class SupabaseAdminService {
  private static readonly avatarPageSize = 100;
  private static readonly avatarRemovalBatchSize = 100;
  private readonly client: ReturnType<typeof createClient>;

  constructor(config: ConfigService) {
    this.client = createClient(
      config.getOrThrow<string>("SUPABASE_URL"),
      config.getOrThrow<string>("SUPABASE_SERVICE_ROLE_KEY"),
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
          detectSessionInUrl: false,
        },
      },
    );
  }

  async deleteAuthIdentity(userId: string): Promise<void> {
    const { error } = await this.client.auth.admin.deleteUser(
      this.requireUuid(userId),
      false,
    );
    if (!error || error.code === "user_not_found") return;
    throw error;
  }

  async deleteAvatarObjects(userId: string): Promise<number> {
    const prefix = `${this.requireUuid(userId)}/`;
    const avatars = this.client.storage.from("avatars");
    const seenCursors = new Set<string>();
    let cursor: string | undefined;
    let deleted = 0;

    do {
      const listed = await avatars.listV2({
        prefix,
        cursor,
        limit: SupabaseAdminService.avatarPageSize,
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
        offset += SupabaseAdminService.avatarRemovalBatchSize
      ) {
        const batch = paths.slice(
          offset,
          offset + SupabaseAdminService.avatarRemovalBatchSize,
        );
        const removal = await avatars.remove(batch);
        if (removal.error || removal.data.length !== batch.length) {
          throw (
            removal.error ?? new Error("Storage removed an incomplete batch")
          );
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

  private requireUuid(userId: string): string {
    if (
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        userId,
      )
    ) {
      throw new Error("Verified user subject is not a UUID");
    }
    return userId;
  }
}
