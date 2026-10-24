import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";

const RATE_LIMITED_STATUS: number = 429;

/**
 * @fastify/rate-limit throws a plain error carrying statusCode 429 instead of
 * Nest's HttpException. That is the only non-HttpException status honoured;
 * any other stray error (even one carrying a 4xx statusCode) is masked as 500.
 */
function statusOf(exception: unknown): number {
  if (exception instanceof HttpException) return exception.getStatus();
  const candidate =
    typeof exception === "object" && exception !== null
      ? (exception as { statusCode?: unknown }).statusCode
      : undefined;
  return candidate === RATE_LIMITED_STATUS
    ? RATE_LIMITED_STATUS
    : HttpStatus.INTERNAL_SERVER_ERROR;
}

@Catch()
export class PrivacyExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrivacyExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const request = context.getRequest<FastifyRequest>();
    const reply = context.getResponse<FastifyReply>();
    const status = statusOf(exception);
    const route = request.routeOptions.url ?? "unmatched";
    const errorType =
      exception instanceof Error ? exception.constructor.name : "UnknownError";

    if (status >= 500) {
      this.logger.error(
        `request_failed requestId=${request.id} method=${request.method} route=${route} status=${status} type=${errorType}`,
      );
    }

    if (status === RATE_LIMITED_STATUS) {
      // No IP, query string, headers or body: rate-limit keys are client
      // identifiers and requests may carry health data.
      this.logger.warn(
        `rate_limit_exceeded requestId=${request.id} method=${request.method} route=${route}`,
      );
    }

    void reply.status(status).send({
      statusCode: status,
      error: status >= 500 ? "Service unavailable" : "Request rejected",
      requestId: request.id,
    });
  }
}
