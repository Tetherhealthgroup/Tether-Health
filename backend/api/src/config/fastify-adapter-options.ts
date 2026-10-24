import type { FastifyServerOptions } from "fastify";
import {
  environmentSchema,
  fastifyTrustProxy,
  type TrustedProxyRange,
} from "./environment";

type AdapterOptions = Pick<FastifyServerOptions, "bodyLimit" | "trustProxy">;

/**
 * Builds the Fastify adapter options from the process environment. The
 * adapter is constructed before ConfigModule runs, so the environment is
 * validated here too: invalid values (including TRUST_PROXY, or a non-zero
 * TRUST_PROXY without TRUST_PROXY_CIDRS) throw and abort startup. Shared by
 * main.ts and the e2e bootstrap so they cannot drift.
 */
export function buildFastifyAdapterOptions(
  env: NodeJS.ProcessEnv = process.env,
): AdapterOptions {
  const { error, value } = environmentSchema.validate(env, {
    allowUnknown: true,
    abortEarly: false,
  }) as {
    error?: Error;
    value: {
      TRUST_PROXY: number;
      TRUST_PROXY_CIDRS: TrustedProxyRange[];
      REQUEST_BODY_LIMIT_BYTES: number;
    };
  };
  if (error) throw new Error(`Config validation error: ${error.message}`);
  return {
    bodyLimit: value.REQUEST_BODY_LIMIT_BYTES,
    trustProxy: fastifyTrustProxy(value.TRUST_PROXY, value.TRUST_PROXY_CIDRS),
  };
}
