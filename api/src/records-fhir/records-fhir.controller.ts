import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Query,
  Req,
  UseFilters,
} from "@nestjs/common";
import type { FastifyRequest } from "fastify";
import type { AuthUser } from "../auth/auth-user";
import { RequestUser } from "../auth/request-user.decorator";
import { HealthRecordsExceptionFilter } from "./records-fhir-errors";
import {
  AcceptItemsDto,
  ManualEntryDto,
  ResolveConflictsDto,
} from "./records-fhir.dto";
import { RecordsFhirService } from "./records-fhir.service";

/**
 * Health records: manual values, review of imported items, conflicts, and
 * the reads of the records screens. Order of checks: authentication
 * (global guard, 401), the body or query (400 `invalid_request`), then the
 * service's checks.
 */
@Controller("v1/records")
@UseFilters(HealthRecordsExceptionFilter)
export class RecordsFhirController {
  constructor(private readonly records: RecordsFhirService) {}

  @Post("manual")
  @HttpCode(201)
  manual(
    @RequestUser() user: AuthUser,
    @Body() dto: ManualEntryDto,
    @Req() request: FastifyRequest,
  ) {
    return this.records.manual(user, dto, request.id);
  }

  @Post("fhir/accept")
  @HttpCode(200)
  accept(
    @RequestUser() user: AuthUser,
    @Body() dto: AcceptItemsDto,
    @Req() request: FastifyRequest,
  ) {
    return this.records.accept(user, dto, request.id);
  }

  @Post("fhir/conflicts")
  @HttpCode(200)
  conflicts(
    @RequestUser() user: AuthUser,
    @Body() dto: ResolveConflictsDto,
    @Req() request: FastifyRequest,
  ) {
    return this.records.resolveConflicts(user, dto, request.id);
  }

  @Get("fhir/sources")
  sources(@RequestUser() user: AuthUser, @Req() request: FastifyRequest) {
    return this.records.sources(user, request.id);
  }

  @Get("fhir/items")
  items(
    @RequestUser() user: AuthUser,
    @Query() query: unknown,
    @Req() request: FastifyRequest,
  ) {
    return this.records.items(user, query, request.id);
  }

  @Get("fhir/summary")
  summary(@RequestUser() user: AuthUser, @Req() request: FastifyRequest) {
    return this.records.summary(user, request.id);
  }
}
