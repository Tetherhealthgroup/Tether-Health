import { Body, Controller, Get, Put } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { PutQuitPlanDto } from "./quit-plan.dto";
import { QuitPlanService } from "./quit-plan.service";

@Controller("v1/quit-plan")
export class QuitPlanController {
  constructor(private readonly quitPlans: QuitPlanService) {}

  @Get()
  get(@RequestUser() user: AuthUser) {
    return this.quitPlans.get(user);
  }

  @Put()
  put(@RequestUser() user: AuthUser, @Body() dto: PutQuitPlanDto) {
    return this.quitPlans.put(user, dto);
  }
}
