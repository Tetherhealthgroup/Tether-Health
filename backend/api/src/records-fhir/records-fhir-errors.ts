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
 * Stable, client-facing codes of the health record routes. A code names the
 * rule that refused the request; it never carries a value, a code, a name
 * or an identifier.
 */
export const healthRecordErrorCodes = [
  "invalid_request",
  "value_out_of_range",
  "record_duplicate",
  "item_not_found",
  "item_not_reviewable",
  "account_deletion_in_progress",
] as const;
export type HealthRecordErrorCode = (typeof healthRecordErrorCodes)[number];

const STATUS: Record<HealthRecordErrorCode, HttpStatus> = {
  invalid_request: HttpStatus.BAD_REQUEST,
  value_out_of_range: HttpStatus.UNPROCESSABLE_ENTITY,
  record_duplicate: HttpStatus.CONFLICT,
  item_not_found: HttpStatus.NOT_FOUND,
  item_not_reviewable: HttpStatus.CONFLICT,
  account_deletion_in_progress: HttpStatus.CONFLICT,
};

export class HealthRecordException extends HttpException {
  constructor(readonly code: HealthRecordErrorCode) {
    super(code, STATUS[code]);
  }
}

export const recordError = (code: HealthRecordErrorCode) =>
  new HealthRecordException(code);

const SQLSTATE = /^[0-9A-Z]{5}$/;

/**
 * Logs the request id, the route template, the status and the SQLSTATE only
 * (never a member, value, code or name), then fails closed with 502.
 */
export function recordsUnavailable(
  logger: Logger,
  requestId: string,
  route: string,
  code: string | undefined,
): never {
  logger.error(
    `health_records_failed requestId=${requestId} route=${route} status=502 code=${code && SQLSTATE.test(code) ? code : "none"}`,
  );
  throw new BadGatewayException("Health records unavailable");
}

/**
 * Coded errors get the stable `code`; a body or query that fails validation
 * is `invalid_request`; everything else goes to the global privacy filter.
 */
@Catch()
export class HealthRecordsExceptionFilter implements ExceptionFilter {
  private readonly fallback = new PrivacyExceptionFilter();

  catch(exception: unknown, host: ArgumentsHost): void {
    const coded =
      exception instanceof HealthRecordException
        ? exception
        : exception instanceof BadRequestException
          ? recordError("invalid_request")
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
