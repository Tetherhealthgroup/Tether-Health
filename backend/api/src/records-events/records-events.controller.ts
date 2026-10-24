import {
  Body,
  Controller,
  Headers,
  Post,
  Req,
  Res,
  UseFilters,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { submissionIdFrom } from "../programme-data/idempotency";
import { RecordsExceptionFilter } from "./records-errors";
import { RecordsEventsService } from "./records-events.service";

/**
 * Check-ins, rescues and lessons. Order of checks: authentication (global
 * guard, 401), `Idempotency-Key` (400), the body (400), then the
 * service's pre-checks.
 */
@Controller("v1/records")
@UseFilters(RecordsExceptionFilter)
export class RecordsEventsController {
  constructor(private readonly records: RecordsEventsService) {}

  @Post("check-ins")
  async checkIn(
    @RequestUser() user: AuthUser,
    @Headers("idempotency-key") key: unknown,
    @Body() body: unknown,
    @Req() request: FastifyRequest,
    @Res({ passthrough: true }) reply: FastifyReply,
  ) {
    const submissionId = submissionIdFrom(key);
    const result = await this.records.checkIn(
      user,
      body,
      submissionId,
      request.id,
    );
    void reply.status(result.status);
    return result.body;
  }

  @Post("rescues")
  async rescue(
    @RequestUser() user: AuthUser,
    @Headers("idempotency-key") key: unknown,
    @Body() body: unknown,
    @Req() request: FastifyRequest,
    @Res({ passthrough: true }) reply: FastifyReply,
  ) {
    const submissionId = submissionIdFrom(key);
    const result = await this.records.rescue(
      user,
      body,
      submissionId,
      request.id,
    );
    void reply.status(result.status);
    return result.body;
  }

  @Post("lessons")
  async lesson(
    @RequestUser() user: AuthUser,
    @Headers("idempotency-key") key: unknown,
    @Body() body: unknown,
    @Req() request: FastifyRequest,
    @Res({ passthrough: true }) reply: FastifyReply,
  ) {
    const submissionId = submissionIdFrom(key);
    const result = await this.records.lesson(
      user,
      body,
      submissionId,
      request.id,
    );
    void reply.status(result.status);
    return result.body;
  }
}
