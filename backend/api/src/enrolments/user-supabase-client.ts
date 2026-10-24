import { Inject, Injectable, Optional } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";

/** Untyped schema, as the other API services use it. */
export type UserSupabaseClient = SupabaseClient<any, any, "public">;

/**
 * Optional fetch implementation for the caller-scoped client. Not provided in
 * production (the platform fetch is used); end-to-end tests construct the
 * factory with a fake PostgREST so the real supabase-js request path runs.
 */
export const USER_SUPABASE_FETCH = Symbol("USER_SUPABASE_FETCH");

/**
 * Builds a Supabase client that acts as the caller: the anon key plus the
 * caller's own access token, so every query runs under that user's RLS.
 * Never uses the service role.
 */
@Injectable()
export class UserSupabaseClientFactory {
  constructor(
    private readonly config: ConfigService,
    @Optional()
    @Inject(USER_SUPABASE_FETCH)
    private readonly fetchImpl?: typeof fetch,
  ) {}

  forUser(user: AuthUser): UserSupabaseClient {
    return createClient(
      this.config.getOrThrow<string>("SUPABASE_URL"),
      this.config.getOrThrow<string>("SUPABASE_ANON_KEY"),
      {
        global: {
          headers: { Authorization: `Bearer ${user.accessToken}` },
          ...(this.fetchImpl ? { fetch: this.fetchImpl } : {}),
        },
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );
  }
}
