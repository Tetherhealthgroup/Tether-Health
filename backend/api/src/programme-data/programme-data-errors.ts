import {
  ArgumentsHost,
  BadRequestException,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";
import { DatabaseErrorCode } from "../common/database-errors";
import { PrivacyExceptionFilter } from "../common/privacy-exception.filter";

/**
 * Stable, client-facing codes of the programme event routes. A code names
 * the rule that refused the request; it never carries a value, a field's
 * content or an identifier.
 */
export const programmeDataErrorCodes = [
  "invalid_request",
  "idempotency_key_required",
  "idempotency_key_invalid",
  "idempotency_key_conflict",
  "value_out_of_range",
  "invalid_record",
  "enrolment_not_found",
  "enrolment_left",
  "core_consent_required",
  "account_deletion_in_progress",
  "record_not_allowed",
] as const;
export type ProgrammeDataErrorCode = (typeof programmeDataErrorCodes)[number];

export class ProgrammeDataException extends HttpException {
  constructor(
    readonly code: ProgrammeDataErrorCode,
    status: HttpStatus,
  ) {
    super(code, status);
  }
}

export const invalidRequest = () =>
  new ProgrammeDataException("invalid_request", HttpStatus.BAD_REQUEST);
export const badRequest = (code: ProgrammeDataErrorCode) =>
  new ProgrammeDataException(code, HttpStatus.BAD_REQUEST);
export const notFound = (code: ProgrammeDataErrorCode) =>
  new ProgrammeDataException(code, HttpStatus.NOT_FOUND);
export const conflict = (code: ProgrammeDataErrorCode) =>
  new ProgrammeDataException(code, HttpStatus.CONFLICT);
export const unprocessable = (code: ProgrammeDataErrorCode) =>
  new ProgrammeDataException(code, HttpStatus.UNPROCESSABLE_ENTITY);

/**
 * The client error for an insert's SQLSTATE, matched by code only; null
 * for the unique violation (the replay rule decides) and for every code
 * the caller cannot fix (registry `TH` codes and anything else), which
 * fail closed as a 502.
 */
export function insertErrorFor(
  code: string | undefined,
): ProgrammeDataException | null {
  switch (code) {
    case DatabaseErrorCode.checkViolation:
      return unprocessable("invalid_record");
    // The enrolment was deleted between the pre-checks and the insert.
    case DatabaseErrorCode.foreignKeyViolation:
      return notFound("enrolment_not_found");
    // A race with leaving, a consent revocation or account deletion.
    case DatabaseErrorCode.insufficientPrivilege:
      return conflict("record_not_allowed");
    default:
      return null;
  }
}

/**
 * Coded errors get the stable `code`; a body that fails validation (a
 * BadRequestException raised by Nest itself) is `invalid_request`; every
 * other error is answered by the global PrivacyExceptionFilter unchanged.
 */
@Catch()
export class ProgrammeDataExceptionFilter implements ExceptionFilter {
  private readonly fallback = new PrivacyExceptionFilter();

  catch(exception: unknown, host: ArgumentsHost): void {
    const coded =
      exception instanceof ProgrammeDataException
        ? exception
        : exception instanceof BadRequestException
          ? invalidRequest()
          : null;
    if (coded === null) {
      this.fallback.catch(exception, host);
      return;
    }
    const context = host.switchToHttp();
    const request = context.getRequest<FastifyRequest>();
    const reply = context.getResponse<FastifyReply>();
    const status = coded.getStatus();
    void reply.status(status).send({
      statusCode: status,
      error: "Request rejected",
      code: coded.code,
      requestId: request.id,
    });
  }
}
