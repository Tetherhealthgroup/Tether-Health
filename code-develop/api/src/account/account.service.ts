import {
  BadGatewayException,
  Injectable,
  Logger,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import { randomUUID } from "node:crypto";
import type { AuthUser } from "../auth/auth-user";
import type {
  AccountDataExportResponse,
  AccountDeletionReceipt,
} from "./account.dto";

interface DeleteCounts {
  profiles: number;
  quit_plans: number;
}

@Injectable()
export class AccountService {
  private readonly logger = new Logger(AccountService.name);

  constructor(private readonly config: ConfigService) {}

  async export(user: AuthUser): Promise<AccountDataExportResponse> {
    this.requireRecentAuthentication(user);
    const client = this.client(user);
    const [profileResult, planResult] = await Promise.all([
      client.from("profiles").select("*").eq("id", user.id).single(),
      client
        .from("quit_plans")
        .select("*")
        .eq("user_id", user.id)
        .maybeSingle(),
    ]);
    if (profileResult.error || planResult.error) {
      throw new BadGatewayException("Account data export is unavailable");
    }
    return {
      schemaVersion: "1.0",
      generatedAt: new Date().toISOString(),
      profile: profileResult.data as Record<string, unknown>,
      quitPlan: planResult.data as Record<string, unknown> | null,
    };
  }

  async deleteData(
    user: AuthUser,
    confirmation: "DELETE",
  ): Promise<AccountDeletionReceipt> {
    this.requireRecentAuthentication(user);
    const client = this.client(user);
    const profile = await client
      .from("profiles")
      .select("avatar_path")
      .eq("id", user.id)
      .single<{ avatar_path: string | null }>();
    if (profile.error) {
      throw new BadGatewayException("Account deletion could not start");
    }

    let avatarObjects = 0;
    if (profile.data.avatar_path) {
      const removal = await client.storage
        .from("avatars")
        .remove([profile.data.avatar_path]);
      if (removal.error) {
        throw new BadGatewayException("Account deletion could not start");
      }
      avatarObjects = removal.data.length;
    }

    const result = await client.rpc("delete_my_app_data", {
      p_confirmation: confirmation,
    });
    if (result.error || !result.data) {
      throw new BadGatewayException("Account data was not deleted");
    }
    const counts = result.data as unknown as DeleteCounts;
    const receipt: AccountDeletionReceipt = {
      requestId: randomUUID(),
      completedAt: new Date().toISOString(),
      deleted: {
        profiles: counts.profiles,
        quitPlans: counts.quit_plans,
        avatarObjects,
      },
      authIdentityDeleted: false,
      authIdentityStatus: "external-action-required",
    };
    this.logger.log(
      `account_data_deleted requestId=${receipt.requestId} status=completed`,
    );
    return receipt;
  }

  private requireRecentAuthentication(user: AuthUser): void {
    const maxAge = this.config.getOrThrow<number>(
      "RECENT_AUTH_MAX_AGE_SECONDS",
    );
    const age = Math.floor(Date.now() / 1000) - user.authenticatedAt;
    if (age < 0 || age > maxAge) {
      throw new UnauthorizedException("Recent authentication is required");
    }
  }

  private client(user: AuthUser) {
    return createClient(
      this.config.getOrThrow<string>("SUPABASE_URL"),
      this.config.getOrThrow<string>("SUPABASE_ANON_KEY"),
      {
        global: { headers: { Authorization: `Bearer ${user.accessToken}` } },
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );
  }
}
