import { Controller, Get, Query, Req, UseFilters } from "@nestjs/common";
import type { FastifyRequest } from "fastify";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { RecordsExceptionFilter } from "../records-events/records-errors";
import { TodayService } from "./today.service";

/** The member's day: `GET /v1/today`. */
@Controller("v1/today")
@UseFilters(RecordsExceptionFilter)
export class TodayController {
  constructor(private readonly today: TodayService) {}

  @Get()
  get(@RequestUser() user: AuthUser, @Req() request: FastifyRequest) {
    return this.today.today(user, request.id);
  }
}

/**
 * One programme's records: `GET /v1/records/summary?programme=&days=`.
 * One programme per call, so a response never mixes programmes.
 */
@Controller("v1/records")
@UseFilters(RecordsExceptionFilter)
export class RecordsSummaryController {
  constructor(private readonly today: TodayService) {}

  @Get("summary")
  summary(
    @RequestUser() user: AuthUser,
    @Query() query: unknown,
    @Req() request: FastifyRequest,
  ) {
    return this.today.summary(user, query, request.id);
  }
}
