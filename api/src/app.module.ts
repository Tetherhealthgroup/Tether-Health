import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { APP_GUARD } from "@nestjs/core";
import { AuthGuard } from "./auth/auth.guard";
import { AccountController } from "./account/account.controller";
import { AccountService } from "./account/account.service";
import { TokenVerifier } from "./auth/token-verifier";
import { environmentSchema } from "./config/environment";
import { HealthController } from "./health/health.controller";
import { ProfileController } from "./profile/profile.controller";
import { ProfileService } from "./profile/profile.service";
import { QuitPlanController } from "./quit-plan/quit-plan.controller";
import { QuitPlanService } from "./quit-plan/quit-plan.service";
import { ProgramDataController } from "./program-data/program-data.controller";
import { ProgramDataService } from "./program-data/program-data.service";
import { ProgrammeDataController } from "./programme-data/programme-data.controller";
import { ProgrammeDataService } from "./programme-data/programme-data.service";
import { CatalogueController } from "./catalogue/catalogue.controller";
import { CatalogueService } from "./catalogue/catalogue.service";
import { ConsentsController } from "./enrolments/consents.controller";
import { EnrolmentsController } from "./enrolments/enrolments.controller";
import { EnrolmentsService } from "./enrolments/enrolments.service";
import { UserSupabaseClientFactory } from "./enrolments/user-supabase-client";
import { RecordsEventsController } from "./records-events/records-events.controller";
import { RecordsEventsService } from "./records-events/records-events.service";
import {
  RecordsSummaryController,
  TodayController,
} from "./today/today.controller";
import { TodayService } from "./today/today.service";
import { NotificationsController } from "./notifications/notifications.controller";
import { NotificationsService } from "./notifications/notifications.service";
import { BaselineController } from "./baseline/baseline.controller";
import { BaselineService } from "./baseline/baseline.service";
import { AppConfigController } from "./app-config/app-config.controller";

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
    ProgrammeDataController,
    EnrolmentsController,
    ConsentsController,
    CatalogueController,
    RecordsEventsController,
    TodayController,
    RecordsSummaryController,
    NotificationsController,
    BaselineController,
    AppConfigController,
  ],
  providers: [
    TokenVerifier,
    ProfileService,
    QuitPlanService,
    AccountService,
    ProgramDataService,
    ProgrammeDataService,
    UserSupabaseClientFactory,
    EnrolmentsService,
    CatalogueService,
    RecordsEventsService,
    TodayService,
    NotificationsService,
    BaselineService,
    { provide: APP_GUARD, useClass: AuthGuard },
  ],
})
export class AppModule {}
