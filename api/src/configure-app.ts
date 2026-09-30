import { ValidationPipe } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import type { NestFastifyApplication } from "@nestjs/platform-fastify";
import { PrivacyExceptionFilter } from "./common/privacy-exception.filter";

export async function configureApp(app: NestFastifyApplication): Promise<void> {
  const config = app.get(ConfigService);
  await app.register(helmet, {
    contentSecurityPolicy: false,
    referrerPolicy: { policy: "no-referrer" },
  });
  await app.register(rateLimit, {
    max: config.getOrThrow<number>("RATE_LIMIT_MAX"),
    timeWindow: config.getOrThrow<number>("RATE_LIMIT_WINDOW_MS"),
  });
  const origins = config
    .getOrThrow<string>("CORS_ALLOWED_ORIGINS")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  if (origins.length > 0) {
    app.enableCors({ origin: origins, credentials: false });
  }
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new PrivacyExceptionFilter());
}
