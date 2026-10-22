import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";
import {
  ProgrammeDataExceptionFilter,
  programmeDataErrorCodes,
} from "../programme-data/programme-data-errors";

/**
 * Stable, client-facing codes of the records, Today, notification
 * preference and baseline routes: the programme event routes' codes plus
 * `no_focus_programme`. A code names the refused rule; it never carries a
 * value, a field's content or an identifier.
 */
export const recordsErrorCodes = [
  ...programmeDataErrorCodes,
  "no_focus_programme",
] as const;
export type RecordsErrorCode = (typeof recordsErrorCodes)[number];

/** A check-in found no focus programme with a live core consent. */
export class NoFocusProgrammeException extends HttpException {
  readonly code = "no_focus_programme";

  constructor() {
    super("no_focus_programme", HttpStatus.CONFLICT);
  }
}

/**
 * The programme event routes' filter, plus `no_focus_programme`: coded
 * errors get the stable `code`, a body Nest itself refuses is
 * `invalid_request`, and everything else goes to the global privacy filter.
 */
@Catch()
export class RecordsExceptionFilter implements ExceptionFilter {
  private readonly programmeData = new ProgrammeDataExceptionFilter();

  catch(exception: unknown, host: ArgumentsHost): void {
    if (!(exception instanceof NoFocusProgrammeException)) {
      this.programmeData.catch(exception, host);
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
