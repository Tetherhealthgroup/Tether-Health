import {
  BadGatewayException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import type { ProfileResponse, UpdateProfileDto } from "./profile.dto";

interface ProfileRow {
  id: string;
  display_name: string | null;
  locale: "en" | "es";
  time_zone: string;
  onboarding_completed: boolean;
  avatar_path: string | null;
  created_at: string;
  updated_at: string;
}

@Injectable()
export class ProfileService {
  constructor(private readonly config: ConfigService) {}

  async get(user: AuthUser): Promise<ProfileResponse> {
    const { data, error } = await this.client(user)
      .from("profiles")
      .select("*")
      .eq("id", user.id)
      .maybeSingle<ProfileRow>();
    if (error) throw new BadGatewayException("Profile data is unavailable");
    if (!data) throw new NotFoundException("Profile not found");
    return this.toResponse(data);
  }

  async update(
    user: AuthUser,
    update: UpdateProfileDto,
  ): Promise<ProfileResponse> {
    const row = {
      ...(update.displayName !== undefined && {
        display_name: update.displayName,
      }),
      ...(update.locale !== undefined && { locale: update.locale }),
      ...(update.timeZone !== undefined && { time_zone: update.timeZone }),
      ...(update.onboardingCompleted !== undefined && {
        onboarding_completed: update.onboardingCompleted,
      }),
      ...(update.avatarPath !== undefined && {
        avatar_path: update.avatarPath,
      }),
    };
    const { data, error } = await this.client(user)
      .from("profiles")
      .update(row)
      .eq("id", user.id)
      .select("*")
      .single<ProfileRow>();
    if (error) throw new BadGatewayException("Profile update failed");
    return this.toResponse(data);
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

  private toResponse(row: ProfileRow): ProfileResponse {
    return {
      id: row.id,
      displayName: row.display_name,
      locale: row.locale,
      timeZone: row.time_zone,
      onboardingCompleted: row.onboarding_completed,
      avatarPath: row.avatar_path,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}
