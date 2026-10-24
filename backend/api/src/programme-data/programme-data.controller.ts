import {
  Body,
  Controller,
  Headers,
  NotFoundException,
  Param,
  Post,
  Req,
  Res,
  UseFilters,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { submissionIdFrom } from "./idempotency";
import { ProgrammeDataExceptionFilter } from "./programme-data-errors";
import { programmeRoute } from "./programme-data.routes";
import { ProgrammeDataService } from "./programme-data.service";

/**
 * Programme event routes: `POST /v1/program-data/:code/:kind` for the
 * fifteen pairs in PROGRAMME_ROUTES only. One parameterised route, so
 * anything that logs the route logs the template, never a programme. The
 * legacy `GET|PUT|DELETE /v1/program-data/:programId` is a separate
 * controller.
 *
 * Order of checks: authentication (global guard, 401), the pair (404),
 * `Idempotency-Key` (400), the body (400, then 422 for a spec range), then
 * the service's pre-checks.
 */
@Controller("v1/program-data")
@UseFilters(ProgrammeDataExceptionFilter)
export class ProgrammeDataController {
  constructor(private readonly records: ProgrammeDataService) {}

  @Post(":code/:kind")
  async submit(
    @RequestUser() user: AuthUser,
    @Param("code") code: string,
    @Param("kind") kind: string,
    @Headers("idempotency-key") key: unknown,
    @Body() body: unknown,
    @Req() request: FastifyRequest,
    @Res({ passthrough: true }) reply: FastifyReply,
  ) {
    const route = programmeRoute(code, kind);
    if (!route) throw new NotFoundException();
    const submissionId = submissionIdFrom(key);
    const result = await this.records.submit(
      user,
      route,
      body,
      submissionId,
      request.id,
    );
    void reply.status(result.status);
    return result.body;
  }
}
