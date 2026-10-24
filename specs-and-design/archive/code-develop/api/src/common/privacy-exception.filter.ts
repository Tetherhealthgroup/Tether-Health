import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import type { FastifyReply, FastifyRequest } from "fastify";

@Catch()
export class PrivacyExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrivacyExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const request = context.getRequest<FastifyRequest>();
    const reply = context.getResponse<FastifyReply>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
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
