import {
  ArgumentsHost,
  BadGatewayException,
  BadRequestException,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";
import { PrivacyExceptionFilter } from "../common/privacy-exception.filter";

/**
 * Stable, client-facing codes of the care routes. A code names the rule
 * that refused the request; it never carries a value, a name, a phone
 * number, a message or an identifier.
 */
export const careErrorCodes = [
  "invalid_request",
  "care_invite_invalid",
  "connection_not_found",
  "connection_required",
  "care_consent_required",
  "enrolment_not_found",
  "enrolment_left",
  "programme_not_enrolled",
  "caregiver_not_found",
  "supporter_not_found",
  "account_deletion_in_progress",
] as const;
export type CareErrorCode = (typeof careErrorCodes)[number];

const STATUS: Record<CareErrorCode, HttpStatus> = {
  invalid_request: HttpStatus.BAD_REQUEST,
  care_invite_invalid: HttpStatus.BAD_REQUEST,
  connection_not_found: HttpStatus.NOT_FOUND,
  connection_required: HttpStatus.CONFLICT,
  care_consent_required: HttpStatus.CONFLICT,
  enrolment_not_found: HttpStatus.NOT_FOUND,
  enrolment_left: HttpStatus.CONFLICT,
  programme_not_enrolled: HttpStatus.CONFLICT,
  caregiver_not_found: HttpStatus.NOT_FOUND,
  supporter_not_found: HttpStatus.NOT_FOUND,
  account_deletion_in_progress: HttpStatus.CONFLICT,
};

export class CareException extends HttpException {
  constructor(readonly code: CareErrorCode) {
    super(code, STATUS[code]);
  }
}

export const careError = (code: CareErrorCode) => new CareException(code);

const SQLSTATE = /^[0-9A-Z]{5}$/;

/**
 * Logs the request id, the route template, the status and the SQLSTATE only
 * (never a member, clinic, programme, name, phone, message or snapshot),
 * then fails closed with 502.
 */
export function careUnavailable(
  logger: Logger,
  requestId: string,
  route: string,
  code: string | undefined,
): never {
  logger.error(
    `care_failed requestId=${requestId} route=${route} status=502 code=${code && SQLSTATE.test(code) ? code : "none"}`,
  );
  throw new BadGatewayException("Care data unavailable");
}

/**
 * Coded errors get the stable `code`; a body that fails validation (a
 * BadRequestException raised by Nest itself) is `invalid_request`; every
 * other error, rate limiting included, is answered by the global
 * PrivacyExceptionFilter unchanged.
 */
@Catch()
export class CareExceptionFilter implements ExceptionFilter {
  private readonly fallback = new PrivacyExceptionFilter();

  catch(exception: unknown, host: ArgumentsHost): void {
    const coded =
      exception instanceof CareException
        ? exception
        : exception instanceof BadRequestException
          ? careError("invalid_request")
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
