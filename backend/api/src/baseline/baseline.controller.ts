import { Body, Controller, Get, Put, Req, UseFilters } from "@nestjs/common";
import type { FastifyRequest } from "fastify";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { RecordsExceptionFilter } from "../records-events/records-errors";
import { BaselineService } from "./baseline.service";

/**
 * `GET` and `PUT /v1/profile/baseline`: a module of its own, apart from the
 * identity profile (`/v1/profile`), which holds no health data.
 */
@Controller("v1/profile/baseline")
@UseFilters(RecordsExceptionFilter)
export class BaselineController {
  constructor(private readonly baseline: BaselineService) {}

  @Get()
  get(@RequestUser() user: AuthUser, @Req() request: FastifyRequest) {
    return this.baseline.get(user, request.id);
  }

  @Put()
  put(
    @RequestUser() user: AuthUser,
    @Body() body: unknown,
    @Req() request: FastifyRequest,
  ) {
    return this.baseline.put(user, body, request.id);
  }
}
