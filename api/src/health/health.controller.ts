import { Controller, Get } from "@nestjs/common";
import { Public } from "../common/public.decorator";

@Controller("health")
export class HealthController {
  @Public()
  @Get()
  getHealth() {
    return {
      status: "ok",
      service: "breathefree-api",
      version: "1.0.0",
    } as const;
  }
}
