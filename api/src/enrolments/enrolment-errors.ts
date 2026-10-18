import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";
import { PrivacyExceptionFilter } from "../common/privacy-exception.filter";

/**
 * Stable, client-facing error codes. A code names the rule that refused the
 * request; it never carries input values or health data.
 */
export const enrolmentErrorCodes = [
  "enrolment_not_found",
  "already_enrolled",
  "programme_not_found",
  "mode_not_allowed",
  "focus_cap_reached",
  "enrolment_conflict",
  "enrolment_left",
  "account_deletion_in_progress",
  "core_consent_required",
  "consent_already_granted",
  "consent_not_found",
  "consent_already_revoked",
  "consent_not_permitted",
  "sharing_not_available",
  "confirmation_required",
  "recent_authentication_required",
] as const;
export type EnrolmentErrorCode = (typeof enrolmentErrorCodes)[number];

export class CodedHttpException extends HttpException {
  constructor(
    readonly code: EnrolmentErrorCode,
    status: HttpStatus,
  ) {
    super(code, status);
  }
}

export const notFound = (code: EnrolmentErrorCode) =>
  new CodedHttpException(code, HttpStatus.NOT_FOUND);
export const conflict = (code: EnrolmentErrorCode) =>
  new CodedHttpException(code, HttpStatus.CONFLICT);
export const badRequest = (code: EnrolmentErrorCode) =>
  new CodedHttpException(code, HttpStatus.BAD_REQUEST);
export const unauthorized = (code: EnrolmentErrorCode) =>
  new CodedHttpException(code, HttpStatus.UNAUTHORIZED);

/**
 * Adds the stable `code` to coded errors; every other error is answered by
 * the global PrivacyExceptionFilter unchanged. The body is otherwise the same
 * constant shape: status, a generic label and the request id.
 */
@Catch()
export class EnrolmentsExceptionFilter implements ExceptionFilter {
  private readonly fallback = new PrivacyExceptionFilter();

  catch(exception: unknown, host: ArgumentsHost): void {
    if (!(exception instanceof CodedHttpException)) {
      this.fallback.catch(exception, host);
      return;
    }
    const context = host.switchToHttp();
    const request = context.getRequest<FastifyRequest>();
    const reply = context.getResponse<FastifyReply>();
    const status = exception.getStatus();
    void reply.status(status).send({
      statusCode: status,
      error: "Request rejected",
      code: exception.code,
      requestId: request.id,
    });
  }
}
