import { ConfigService } from "@nestjs/config";
import { NestFactory } from "@nestjs/core";
import {
  FastifyAdapter,
  NestFastifyApplication,
} from "@nestjs/platform-fastify";
import { AppModule } from "./app.module";
import { configureApp } from "./configure-app";
import { environmentSchema, fastifyTrustProxy } from "./config/environment";

async function bootstrap(): Promise<void> {
  // The adapter is built before ConfigModule runs, so validate the environment
  // here too; invalid values (including TRUST_PROXY) abort startup.
  const { error, value } = environmentSchema.validate(process.env, {
    allowUnknown: true,
    abortEarly: false,
  }) as { error?: Error; value: { TRUST_PROXY: number } };
  if (error) throw new Error(`Config validation error: ${error.message}`);
  const trustProxyHops = value.TRUST_PROXY;
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({
      bodyLimit: Number(process.env.REQUEST_BODY_LIMIT_BYTES ?? 65536),
      trustProxy: fastifyTrustProxy(trustProxyHops),
    }),
  );
  await configureApp(app);
  app.enableShutdownHooks();
  const config = app.get(ConfigService);
  await app.listen(config.getOrThrow<number>("PORT"), "0.0.0.0");
}

void bootstrap();
