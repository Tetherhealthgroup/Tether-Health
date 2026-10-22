import { Injectable, Logger } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { DatabaseErrorCode } from "../common/database-errors";
import {
  UserSupabaseClientFactory,
  type UserSupabaseClient,
} from "../enrolments/user-supabase-client";
import { insertErrorFor } from "../programme-data/programme-data-errors";
import type { Row } from "../programme-data/programme-records";
import {
  parseBody,
  requireBarrierOpen,
  unavailable,
} from "../records-events/records-access";
import { BASELINE_FIELDS, PutBaselineDto, type Baseline } from "./baseline.dto";

/** The route as logged. */
export const BASELINE_ROUTE = "/v1/profile/baseline";

/**
 * The member's onboarding baseline (age band, sleep and stress bands):
 * account-level, kept apart from the identity profile, never shared.
 */
@Injectable()
export class BaselineService {
  private readonly logger = new Logger(BaselineService.name);

  constructor(private readonly clients: UserSupabaseClientFactory) {}

  /** The stored values, or all null when none were saved. */
  async get(
    user: AuthUser,
    requestId: string,
    client: UserSupabaseClient = this.clients.forUser(user),
  ): Promise<Baseline> {
    const { data, error } = await client
      .from("wellbeing_baseline")
      .select("age_range,sleep_band,stress_band")
      .eq("user_id", user.id)
      .maybeSingle<Row>();
    if (error) unavailable(this.logger, requestId, BASELINE_ROUTE, error.code);
    const text = (value: unknown) => (typeof value === "string" ? value : null);
    return {
      ageRange: text(data?.age_range),
      sleepBand: text(data?.sleep_band),
      stressBand: text(data?.stress_band),
    };
  }

  /** Replaces all three values (absent → null): update, else insert. */
  async put(
    user: AuthUser,
    rawBody: unknown,
    requestId: string,
  ): Promise<Baseline> {
    const body = await parseBody(rawBody, PutBaselineDto, BASELINE_FIELDS);
    const client = this.clients.forUser(user);
    await requireBarrierOpen(client);
    const values = {
      age_range: body.ageRange ?? null,
      sleep_band: body.sleepBand ?? null,
      stress_band: body.stressBand ?? null,
    };
    const update = async (): Promise<boolean> => {
      const { data, error } = await client
        .from("wellbeing_baseline")
        .update(values)
        .eq("user_id", user.id)
        .select("user_id");
      if (error) this.refused(requestId, error.code);
      return Array.isArray(data) && data.length > 0;
    };
    if (!(await update())) {
      const { error } = await client
        .from("wellbeing_baseline")
        .insert([{ user_id: user.id, ...values }]);
      if (
        error &&
        !(error.code === DatabaseErrorCode.uniqueViolation && (await update()))
      ) {
        this.refused(requestId, error.code);
      }
    }
    return this.get(user, requestId, client);
  }

  private refused(requestId: string, code: string | undefined): never {
    const mapped =
      code === DatabaseErrorCode.uniqueViolation ? null : insertErrorFor(code);
    if (mapped) throw mapped;
    return unavailable(this.logger, requestId, BASELINE_ROUTE, code);
  }
}
