import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";

@Injectable()
export class SupabaseAdminService {
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
    const { error } = await this.client.auth.admin.deleteUser(userId, false);
    if (!error || error.code === "user_not_found") return;
    throw error;
  }
}
