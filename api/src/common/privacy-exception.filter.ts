import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";

/**
 * Fastify plugins (e.g. @fastify/rate-limit's 429) throw plain errors that
 * carry a numeric `statusCode` instead of Nest's HttpException. Honour 4xx
 * codes so a rate-limited client sees 429, not a masked 500.
 */
function statusOf(exception: unknown): number {
  if (exception instanceof HttpException) return exception.getStatus();
  const candidate =
    typeof exception === "object" && exception !== null
      ? (exception as { statusCode?: unknown }).statusCode
      : undefined;
  if (
    typeof candidate === "number" &&
    Number.isInteger(candidate) &&
    candidate >= 400 &&
    candidate <= 499
  ) {
    return candidate;
  }
  return HttpStatus.INTERNAL_SERVER_ERROR;
}

@Catch()
export class PrivacyExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrivacyExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const request = context.getRequest<FastifyRequest>();
    const reply = context.getResponse<FastifyReply>();
    const status = statusOf(exception);
    const route = request.routeOptions.url ?? request.url.split("?", 1)[0];
    const errorType =
      exception instanceof Error ? exception.constructor.name : "UnknownError";

    if (status >= 500) {
      this.logger.error(
        `request_failed requestId=${request.id} method=${request.method} route=${route} status=${status} type=${errorType}`,
      );
    }

    void reply.status(status).send({
      statusCode: status,
      error: status >= 500 ? "Service unavailable" : "Request rejected",
      requestId: request.id,
    });
  }
}
