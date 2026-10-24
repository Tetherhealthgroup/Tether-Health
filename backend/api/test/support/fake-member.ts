import { randomUUID } from "node:crypto";
import type { ConfigService } from "@nestjs/config";
import type { AuthUser } from "../../src/auth/auth-user";
import { UserSupabaseClientFactory } from "../../src/enrolments/user-supabase-client";
import { FakePostgrest } from "./fake-postgrest";

/**
 * Unit-test wiring: the real supabase-js client over a FakePostgrest, and
 * synthetic members whose enrolments and consents are seeded directly (as
 * a superuser would), without going through the enrolment routes.
 */
export function fakeClients(): {
  fake: FakePostgrest;
  clients: UserSupabaseClientFactory;
} {
  const fake = new FakePostgrest();
  const config = {
    getOrThrow: (key: string) =>
      ({
        SUPABASE_URL: "https://project.example.com",
        SUPABASE_ANON_KEY: "placeholder-key-that-is-long-enough",
      })[key],
  } as unknown as ConfigService;
  return { fake, clients: new UserSupabaseClientFactory(config, fake.fetch) };
}

let counter = 0;

/** A synthetic member with a profile and identity. */
export function syntheticMember(fake: FakePostgrest): AuthUser {
  counter += 1;
  const token = `synthetic-unit-token-${counter}`;
  const id = randomUUID();
  fake.addUser(token, id);
  return { id, accessToken: token, authenticatedAt: Date.now() };
}

/** Seeds an enrolment (and a live core consent unless `core` is false). */
export function seedEnrolment(
  fake: FakePostgrest,
  user: AuthUser,
  code: string,
  { status = "learn_only", core = true } = {},
): string {
  const id = randomUUID();
  const now = new Date().toISOString();
  fake.seedRow("enrolments", {
    id,
    user_id: user.id,
    programme_code: code,
    status,
    mode: null,
    joined_at: now,
    left_at: status === "left" ? now : null,
    created_at: now,
    updated_at: now,
  });
  if (core) {
    fake.seedRow("programme_consents", {
      id: randomUUID(),
      enrolment_id: id,
      purpose: "core",
      recipient_ref: null,
      consent_version: "v1-draft",
      locale: "en",
      consent_text: "Synthetic core wording",
      granted_at: now,
      revoked_at: null,
      superseded_by: null,
    });
  }
  return id;
}
