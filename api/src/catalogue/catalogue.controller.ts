import { Controller, Get } from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { CatalogueService } from "./catalogue.service";

@Controller("v1/catalogue")
export class CatalogueController {
  constructor(private readonly catalogue: CatalogueService) {}

  @Get("programmes")
  programmes(@RequestUser() user: AuthUser) {
    return this.catalogue.programmes(user);
  }
}
