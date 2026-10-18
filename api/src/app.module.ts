import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { APP_GUARD } from "@nestjs/core";
import { AuthGuard } from "./auth/auth.guard";
import { AccountController } from "./account/account.controller";
import { AccountService } from "./account/account.service";
import { TokenVerifier } from "./auth/token-verifier";
import { SupabaseAdminService } from "./auth/supabase-admin.service";
import { environmentSchema } from "./config/environment";
import { HealthController } from "./health/health.controller";
import { ProfileController } from "./profile/profile.controller";
import { ProfileService } from "./profile/profile.service";
import { QuitPlanController } from "./quit-plan/quit-plan.controller";
import { QuitPlanService } from "./quit-plan/quit-plan.service";
import { ProgramDataController } from "./program-data/program-data.controller";
import { ProgramDataService } from "./program-data/program-data.service";
import { CatalogueController } from "./catalogue/catalogue.controller";
import { CatalogueService } from "./catalogue/catalogue.service";
import { ConsentsController } from "./enrolments/consents.controller";
import { EnrolmentsController } from "./enrolments/enrolments.controller";
import { EnrolmentsService } from "./enrolments/enrolments.service";
import { UserSupabaseClientFactory } from "./enrolments/user-supabase-client";

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validationSchema: environmentSchema,
    }),
  ],
  controllers: [
    HealthController,
    ProfileController,
    QuitPlanController,
    AccountController,
    ProgramDataController,
    EnrolmentsController,
    ConsentsController,
    CatalogueController,
  ],
  providers: [
    TokenVerifier,
    SupabaseAdminService,
    ProfileService,
    QuitPlanService,
    AccountService,
    ProgramDataService,
    UserSupabaseClientFactory,
    EnrolmentsService,
    CatalogueService,
    { provide: APP_GUARD, useClass: AuthGuard },
  ],
})
export class AppModule {}
