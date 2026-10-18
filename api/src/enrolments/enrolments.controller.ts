import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseFilters,
} from "@nestjs/common";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { EnrolmentsExceptionFilter } from "./enrolment-errors";
import {
  CreateEnrolmentDto,
  DeleteEnrolmentDto,
  UpdateEnrolmentDto,
} from "./enrolments.dto";
import { EnrolmentsService } from "./enrolments.service";

@Controller("v1/enrolments")
@UseFilters(EnrolmentsExceptionFilter)
export class EnrolmentsController {
  constructor(private readonly enrolments: EnrolmentsService) {}

  @Get()
  list(@RequestUser() user: AuthUser) {
    return this.enrolments.list(user);
  }

  @Post()
  @HttpCode(201)
  create(@RequestUser() user: AuthUser, @Body() dto: CreateEnrolmentDto) {
    return this.enrolments.create(user, dto);
  }

  @Patch(":id")
  update(
    @RequestUser() user: AuthUser,
    @Param("id", ParseUUIDPipe) id: string,
    @Body() dto: UpdateEnrolmentDto,
  ) {
    return this.enrolments.update(user, id, dto);
  }

  @Delete(":id")
  @HttpCode(204)
  async deleteNow(
    @RequestUser() user: AuthUser,
    @Param("id", ParseUUIDPipe) id: string,
    @Body() dto: DeleteEnrolmentDto,
  ) {
    await this.enrolments.deleteNow(user, id, dto.confirmation);
  }
}
