import { Body, Controller, Get, Patch, Req, UseFilters } from "@nestjs/common";
import type { FastifyRequest } from "fastify";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { RecordsExceptionFilter } from "../records-events/records-errors";
import { NotificationsService } from "./notifications.service";

/**
 * `GET` and `PATCH /v1/notifications/preferences`. An `Idempotency-Key`
 * header is accepted and ignored (last write wins).
 */
@Controller("v1/notifications/preferences")
@UseFilters(RecordsExceptionFilter)
export class NotificationsController {
  constructor(private readonly preferences: NotificationsService) {}

  @Get()
  get(@RequestUser() user: AuthUser, @Req() request: FastifyRequest) {
    return this.preferences.get(user, request.id);
  }

  @Patch()
  patch(
    @RequestUser() user: AuthUser,
    @Body() body: unknown,
    @Req() request: FastifyRequest,
  ) {
    return this.preferences.patch(user, body, request.id);
  }
}
