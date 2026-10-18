import {
  Body,
  Controller,
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
import { GrantConsentDto, RevokeConsentDto } from "./enrolments.dto";
import { EnrolmentsService } from "./enrolments.service";

@Controller("v1/enrolments/consents")
@UseFilters(EnrolmentsExceptionFilter)
export class ConsentsController {
  constructor(private readonly enrolments: EnrolmentsService) {}

  @Post()
  @HttpCode(201)
  grant(@RequestUser() user: AuthUser, @Body() dto: GrantConsentDto) {
    return this.enrolments.grantConsent(user, dto);
  }

  /** Revoke only: consent rows are never edited otherwise. */
  @Patch(":id")
  revoke(
    @RequestUser() user: AuthUser,
    @Param("id", ParseUUIDPipe) id: string,
    // Validated to be exactly { revoked: true }.
    @Body() body: RevokeConsentDto,
  ) {
    return body.revoked && this.enrolments.revokeConsent(user, id);
  }
}
