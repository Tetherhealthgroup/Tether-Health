import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Patch,
} from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { ProfileService } from "./profile.service";
import { UpdateProfileDto } from "./profile.dto";

@Controller("v1/profile")
export class ProfileController {
  constructor(private readonly profiles: ProfileService) {}

  @Get()
  get(@RequestUser() user: AuthUser) {
    return this.profiles.get(user);
  }

  @Patch()
  update(@RequestUser() user: AuthUser, @Body() dto: UpdateProfileDto) {
    if (Object.keys(dto).length === 0)
      throw new BadRequestException("At least one profile field is required");
    return this.profiles.update(user, dto);
  }
}
