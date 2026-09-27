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
  program_data: number;
}

interface ProgramExportRow {
  program_id: "heartwise" | "steady" | "clearair";
  payload: Record<string, unknown>;
  revision: number;
  updated_at: string;
}

@Injectable()
export class AccountService {
  private readonly logger = new Logger(AccountService.name);

  constructor(private readonly config: ConfigService) {}

  async export(user: AuthUser): Promise<AccountDataExportResponse> {
    this.requireRecentAuthentication(user);
    const client = this.client(user);
    const [profileResult, planResult, programResult] = await Promise.all([
      client.from("profiles").select("*").eq("id", user.id).single(),
      client
        .from("quit_plans")
        .select("*")
        .eq("user_id", user.id)
        .maybeSingle(),
      client
        .from("program_data")
        .select("program_id,payload,revision,updated_at")
        .eq("user_id", user.id)
        .returns<ProgramExportRow[]>(),
    ]);
    if (profileResult.error || planResult.error || programResult.error) {
      throw new BadGatewayException("Account data export is unavailable");
    }
    return {
      schemaVersion: "1.0",
      generatedAt: new Date().toISOString(),
      profile: profileResult.data as Record<string, unknown>,
      quitPlan: planResult.data as Record<string, unknown> | null,
      programData: programResult.data.map((row) => ({
        programId: row.program_id,
        payload: row.payload,
        revision: row.revision,
        updatedAt: row.updated_at,
      })),
    };
  }

  async deleteData(
    user: AuthUser,
    confirmation: "DELETE",
  ): Promise<AccountDeletionReceipt> {
    this.requireRecentAuthentication(user);
    const client = this.client(user);
    const avatars = client.storage.from("avatars");
    let avatarObjects = 0;
    while (true) {
      const listed = await avatars.list(user.id, {
        limit: 100,
        offset: 0,
        sortBy: { column: "name", order: "asc" },
      });
      if (listed.error) {
        throw new BadGatewayException("Account deletion could not start");
      }
      if (listed.data.length === 0) break;

      const paths = listed.data.map((object) => `${user.id}/${object.name}`);
      const removal = await avatars.remove(paths);
      if (removal.error || removal.data.length !== paths.length) {
        throw new BadGatewayException("Account deletion could not start");
      }
      avatarObjects += removal.data.length;
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
        programData: counts.program_data,
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
