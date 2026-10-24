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
  ],
  providers: [
    TokenVerifier,
    ProfileService,
    QuitPlanService,
    AccountService,
    { provide: APP_GUARD, useClass: AuthGuard },
  ],
})
export class AppModule {}
