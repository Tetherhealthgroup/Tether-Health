import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseFilters,
} from "@nestjs/common";
import { RouteConfig } from "@nestjs/platform-fastify";
import type { FastifyRequest } from "fastify";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { CareExceptionFilter } from "./care-errors";
import {
  CreateCaregiverDto,
  CreateMessageDto,
  CreateSummaryDto,
  CreateSupporterDto,
  RedeemInviteDto,
} from "./care.dto";
import { CareService } from "./care.service";

/**
 * Invite redemptions per client address and minute, below the global
 * limit, so codes cannot be guessed at the API's general rate. Every
 * refused code gets the same answer.
 */
export const REDEEM_RATE_LIMIT = { max: 10, timeWindow: 60_000 };

/**
 * The member's care team. Order of checks: authentication (global guard,
 * 401), the body (400 `invalid_request`), then the service's checks.
 */
@Controller("v1/care")
@UseFilters(CareExceptionFilter)
export class CareController {
  constructor(private readonly care: CareService) {}

  @Post("connections")
  @HttpCode(201)
  @RouteConfig({ rateLimit: REDEEM_RATE_LIMIT })
  redeem(
    @RequestUser() user: AuthUser,
    @Body() dto: RedeemInviteDto,
    @Req() request: FastifyRequest,
  ) {
    return this.care.redeem(user, dto, request.id);
  }

  @Get("connections")
  listConnections(
    @RequestUser() user: AuthUser,
    @Req() request: FastifyRequest,
  ) {
    return this.care.listConnections(user, request.id);
  }

  @Delete("connections/:id")
  revokeConnection(
    @RequestUser() user: AuthUser,
    @Param("id", ParseUUIDPipe) id: string,
    @Req() request: FastifyRequest,
  ) {
    return this.care.revokeConnection(user, id, request.id);
  }

  @Post("summaries")
  @HttpCode(201)
  createSummary(
    @RequestUser() user: AuthUser,
    @Body() dto: CreateSummaryDto,
    @Req() request: FastifyRequest,
  ) {
    return this.care.createSummary(user, dto, request.id);
  }

  @Post("messages")
  @HttpCode(201)
  createMessage(
    @RequestUser() user: AuthUser,
    @Body() dto: CreateMessageDto,
    @Req() request: FastifyRequest,
  ) {
    return this.care.createMessage(user, dto, request.id);
  }

  @Post("supporters")
  @HttpCode(201)
  createSupporter(
    @RequestUser() user: AuthUser,
    @Body() dto: CreateSupporterDto,
    @Req() request: FastifyRequest,
  ) {
    return this.care.createSupporter(user, dto, request.id);
  }

  @Get("supporters")
  listSupporters(
    @RequestUser() user: AuthUser,
    @Req() request: FastifyRequest,
  ) {
    return this.care.listSupporters(user, request.id);
  }

  @Delete("supporters/:id")
  @HttpCode(204)
  async deleteSupporter(
    @RequestUser() user: AuthUser,
    @Param("id", ParseUUIDPipe) id: string,
    @Req() request: FastifyRequest,
  ) {
    await this.care.deleteSupporter(user, id, request.id);
  }

  @Post("caregivers")
  @HttpCode(201)
  createCaregiver(
    @RequestUser() user: AuthUser,
    @Body() dto: CreateCaregiverDto,
    @Req() request: FastifyRequest,
  ) {
    return this.care.createCaregiver(user, dto, request.id);
  }

  @Get("caregivers")
  listCaregivers(
    @RequestUser() user: AuthUser,
    @Req() request: FastifyRequest,
  ) {
    return this.care.listCaregivers(user, request.id);
  }

  @Delete("caregivers/:id")
  revokeCaregiver(
    @RequestUser() user: AuthUser,
    @Param("id", ParseUUIDPipe) id: string,
    @Req() request: FastifyRequest,
  ) {
    return this.care.revokeCaregiver(user, id, request.id);
  }
}
