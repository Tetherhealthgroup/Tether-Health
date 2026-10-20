import {
  BadGatewayException,
  Injectable,
  Logger,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { randomUUID } from "node:crypto";
import type { AuthUser } from "../auth/auth-user";
import { UserSupabaseClientFactory } from "../enrolments/user-supabase-client";
import type {
  AccountDataExportResponse,
  AccountDeletionReceipt,
} from "./account.dto";
import { deleteAvatarObjects } from "./avatar-objects";

/**
 * Registry codes (docs/contracts/database.md, "Error codes") that the
 * account deletion maps to its own responses. Matched by code only, never by
 * message. Any other error from the deletion functions, including TH020
 * (rls_bypass_required) and TH018 (auth_identity_not_deleted), fails closed
 * as a 502 whose log line carries the code.
 */
export const AccountDeletionErrorCode = {
  avatarObjectsRemain: "TH016",
  recentAuthenticationRequired: "TH017",
} as const;

const SQLSTATE = /^[0-9A-Z]{5}$/;

/**
 * Seconds by which account deletion is stricter than
 * RECENT_AUTH_MAX_AGE_SECONDS. The database checks the sign-in again when
 * the deletion completes, after the barrier and the avatar removal, against
 * its own window of 600 seconds. Refusing at the start once the sign-in is
 * older than the maximum minus this margin leaves the rest of the request
 * that much time, so a sign-in the API accepts is not refused by the
 * database part-way through. A sign-in exactly the maximum minus the margin
 * old is still accepted.
 */
export const DELETION_SIGN_IN_MARGIN_SECONDS = 30;

/** The value logged as `code=`: a SQLSTATE, or "none". */
const loggedCode = (code: string | undefined): string =>
  code && SQLSTATE.test(code) ? code : "none";

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

  constructor(
    private readonly config: ConfigService,
    private readonly clients: UserSupabaseClientFactory,
  ) {}

  async export(user: AuthUser): Promise<AccountDataExportResponse> {
    this.requireRecentAuthentication(user);
    const client = this.clients.forUser(user);
    const [profileResult, planResult, programResult] = await Promise.all([
      client
        .from("profiles")
        .select(
          "id,display_name,locale,time_zone,onboarding_completed,avatar_path,created_at,updated_at",
        )
        .eq("id", user.id)
        .single(),
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
      profile: profileResult.data,
      quitPlan: planResult.data as Record<string, unknown> | null,
      programData: programResult.data.map((row) => ({
        programId: row.program_id,
        payload: row.payload,
        revision: row.revision,
        updatedAt: row.updated_at,
      })),
    };
  }

  /**
   * Deletes the caller's account with the caller's own token: the deletion
   * barrier, then the avatar objects through Storage, then the app data and
   * the identity in one database call (delete_my_account). Each step is safe
   * to repeat, so a retry after a lost response returns zero counts.
   */
  async deleteData(
    user: AuthUser,
    confirmation: "DELETE",
  ): Promise<AccountDeletionReceipt> {
    this.requireRecentAuthentication(user, DELETION_SIGN_IN_MARGIN_SECONDS);
    const requestId = randomUUID();
    const client = this.clients.forUser(user);
    const begun = await client.rpc("begin_account_deletion", {
      p_confirmation: confirmation,
    });
    if (
      begun.error?.code ===
      AccountDeletionErrorCode.recentAuthenticationRequired
    ) {
      throw new UnauthorizedException("Recent authentication is required");
    }
    if (begun.error || begun.data !== true) {
      this.logger.error(
        `account_deletion_failed requestId=${requestId} status=begin_failed code=${loggedCode(begun.error?.code)}`,
      );
      throw new BadGatewayException("Account deletion could not start");
    }

    let avatarObjects: number;
    try {
      avatarObjects = await deleteAvatarObjects(client, user.id);
    } catch {
      this.logger.error(
        `account_deletion_failed requestId=${requestId} status=avatar_cleanup_failed`,
      );
      throw new BadGatewayException("Account deletion could not complete");
    }

    const result = await client.rpc("delete_my_account", {
      p_confirmation: confirmation,
    });
    const code = result.error?.code;
    if (code === AccountDeletionErrorCode.recentAuthenticationRequired) {
      throw new UnauthorizedException("Recent authentication is required");
    }
    const counts = result.error ? null : deleteCounts(result.data);
    if (!counts) {
      const status =
        code === AccountDeletionErrorCode.avatarObjectsRemain
          ? "avatar_objects_remain"
          : "account_delete_failed";
      this.logger.error(
        `account_deletion_failed requestId=${requestId} status=${status} code=${loggedCode(code)}`,
      );
      throw new BadGatewayException("Account deletion could not complete");
    }
    const receipt: AccountDeletionReceipt = {
      requestId,
      completedAt: new Date().toISOString(),
      deleted: {
        profiles: counts.profiles,
        quitPlans: counts.quit_plans,
        avatarObjects,
        programData: counts.program_data,
      },
      authIdentityDeleted: true,
      authIdentityStatus: "deleted",
    };
    this.logger.log(
      `account_deleted requestId=${receipt.requestId} status=completed`,
    );
    return receipt;
  }

  /**
   * Refuses a sign-in in the future or older than
   * RECENT_AUTH_MAX_AGE_SECONDS minus `marginSeconds`. The age keeps its
   * fraction of a second, as the database's own check does.
   */
  private requireRecentAuthentication(user: AuthUser, marginSeconds = 0): void {
    const maxAge = this.config.getOrThrow<number>(
      "RECENT_AUTH_MAX_AGE_SECONDS",
    );
    const age = Date.now() / 1000 - user.authenticatedAt;
    if (age < 0 || age > maxAge - marginSeconds) {
      throw new UnauthorizedException("Recent authentication is required");
    }
  }
}

/** The receipt's counts from delete_my_account's result, or null if absent. */
function deleteCounts(data: unknown): DeleteCounts | null {
  if (typeof data !== "object" || data === null) return null;
  const row = data as Record<string, unknown>;
  const count = (key: keyof DeleteCounts) => {
    const value = row[key];
    return Number.isInteger(value) && (value as number) >= 0
      ? (value as number)
      : null;
  };
  const profiles = count("profiles");
  const quitPlans = count("quit_plans");
  const programData = count("program_data");
  if (profiles === null || quitPlans === null || programData === null) {
    return null;
  }
  return { profiles, quit_plans: quitPlans, program_data: programData };
}
