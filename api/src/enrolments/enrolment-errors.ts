import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";
import { DatabaseErrorCode } from "../common/database-errors";
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
  "consent_superseded",
  "consent_not_permitted",
  "consent_document_unavailable",
  "consent_version_unchanged",
  "focus_swap_invalid",
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
 * The database's own rules (registry codes) as they reach the focus swap and
 * the consent grant, including core supersession. Matched by `code` only.
 * A code not listed here (TH010 sync session, TH015 document guard, any
 * unknown code) is not the caller's to fix: it fails closed as a 502.
 */
const registryResponses: Readonly<Record<string, () => CodedHttpException>> = {
  [DatabaseErrorCode.focusCapReached]: () => conflict("focus_cap_reached"),
  [DatabaseErrorCode.consentRequiresCore]: () =>
    conflict("core_consent_required"),
  [DatabaseErrorCode.enrolmentLeft]: () => conflict("enrolment_left"),
  [DatabaseErrorCode.deletionInProgress]: () =>
    conflict("account_deletion_in_progress"),
  [DatabaseErrorCode.consentDocumentUnavailable]: () =>
    conflict("consent_document_unavailable"),
  [DatabaseErrorCode.enrolmentNotFound]: () => notFound("enrolment_not_found"),
  [DatabaseErrorCode.focusSwapInvalid]: () => conflict("focus_swap_invalid"),
  [DatabaseErrorCode.consentVersionUnchanged]: () =>
    conflict("consent_version_unchanged"),
};

/** The client error for a registry code, or undefined when it has none. */
export const registryErrorFor = (
  code: string | undefined,
): CodedHttpException | undefined =>
  code !== undefined && Object.hasOwn(registryResponses, code)
    ? registryResponses[code]?.()
    : undefined;

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
