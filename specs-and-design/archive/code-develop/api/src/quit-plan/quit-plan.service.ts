import {
  BadGatewayException,
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createClient } from "@supabase/supabase-js";
import type { AuthUser } from "../auth/auth-user";
import type {
  DailyCigaretteUse,
  PreparationTask,
  PutQuitPlanDto,
  QuitPlanPath,
  QuitPlanResponse,
  QuitReason,
  ReadinessPath,
  SmokingTrigger,
  SupportPersonDto,
} from "./quit-plan.dto";

interface QuitPlanRow {
  user_id: string;
  daily_cigarette_use: DailyCigaretteUse | null;
  smoking_triggers: SmokingTrigger[];
  custom_smoking_trigger: string | null;
  readiness_path: ReadinessPath;
  quit_plan_path: QuitPlanPath;
  quit_date: string;
  quit_day_check_in: boolean;
  quit_reasons: QuitReason[];
  custom_quit_reason: string | null;
  top_quit_reason: QuitReason | null;
  support_people: SupportPersonDto[];
  preparation_tasks: PreparationTask[];
  treatment_support: boolean;
  care_team_reminder: boolean;
  created_at: string;
  updated_at: string;
}

@Injectable()
export class QuitPlanService {
  constructor(private readonly config: ConfigService) {}

  async get(user: AuthUser): Promise<QuitPlanResponse> {
    const { data, error } = await this.client(user)
      .from("quit_plans")
      .select("*")
      .eq("user_id", user.id)
      .maybeSingle<QuitPlanRow>();
    if (error) throw new BadGatewayException("Quit plan data is unavailable");
    if (!data) throw new NotFoundException("Quit plan not found");
    return this.toResponse(data);
  }

  async put(user: AuthUser, plan: PutQuitPlanDto): Promise<QuitPlanResponse> {
    this.validate(plan);
    const row = this.toRow(user, plan);
    const { data, error } = await this.client(user)
      .from("quit_plans")
      .upsert(row, { onConflict: "user_id" })
      .select("*")
      .single<QuitPlanRow>();
    if (error) throw new BadGatewayException("Quit plan could not be saved");
    return this.toResponse(data);
  }

  async create(
    user: AuthUser,
    plan: PutQuitPlanDto,
  ): Promise<QuitPlanResponse> {
    this.validate(plan);
    const { data, error } = await this.client(user)
      .from("quit_plans")
      .insert(this.toRow(user, plan))
      .select("*")
      .single<QuitPlanRow>();
    if (error?.code === "23505") {
      throw new ConflictException("Quit plan already exists");
    }
    if (error) throw new BadGatewayException("Quit plan could not be created");
    return this.toResponse(data);
  }

  private validate(plan: PutQuitPlanDto) {
    if (
      plan.topQuitReason !== null &&
      !plan.quitReasons.includes(plan.topQuitReason)
    ) {
      throw new BadRequestException("topQuitReason must be one of quitReasons");
    }
    if (
      plan.quitReasons.includes("custom") !==
      (plan.customQuitReason !== null)
    ) {
      throw new BadRequestException(
        "customQuitReason is required only when custom is selected",
      );
    }
  }

  private toRow(user: AuthUser, plan: PutQuitPlanDto) {
    return {
      user_id: user.id,
      daily_cigarette_use: plan.dailyCigaretteUse,
      smoking_triggers: plan.smokingTriggers,
      custom_smoking_trigger: plan.customSmokingTrigger,
      readiness_path: plan.readinessPath,
      quit_plan_path: plan.quitPlanPath,
      quit_date: plan.quitDate,
      quit_day_check_in: plan.quitDayCheckIn,
      quit_reasons: plan.quitReasons,
      custom_quit_reason: plan.customQuitReason,
      top_quit_reason: plan.topQuitReason,
      support_people: plan.supportPeople,
      preparation_tasks: plan.preparationTasks,
      treatment_support: plan.treatmentSupport,
      care_team_reminder: plan.careTeamReminder,
    };
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

  private toResponse(row: QuitPlanRow): QuitPlanResponse {
    return {
      userId: row.user_id,
      dailyCigaretteUse: row.daily_cigarette_use,
      smokingTriggers: row.smoking_triggers,
      customSmokingTrigger: row.custom_smoking_trigger,
      readinessPath: row.readiness_path,
      quitPlanPath: row.quit_plan_path,
      quitDate: row.quit_date,
      quitDayCheckIn: row.quit_day_check_in,
      quitReasons: row.quit_reasons,
      customQuitReason: row.custom_quit_reason,
      topQuitReason: row.top_quit_reason,
      supportPeople: row.support_people,
      preparationTasks: row.preparation_tasks,
      treatmentSupport: row.treatment_support,
      careTeamReminder: row.care_team_reminder,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}
