import * as Joi from "joi";

function decodedSupabaseRole(value: string): string | undefined {
  const segments = value.split(".");
  if (segments.length !== 3) return undefined;
  const payloadSegment = segments[1];
  if (!payloadSegment) return undefined;
  try {
    const payload = JSON.parse(
      Buffer.from(payloadSegment, "base64url").toString("utf8"),
    ) as Record<string, unknown>;
    return typeof payload.role === "string" ? payload.role : undefined;
  } catch {
    return undefined;
  }
}

function isPrivilegedSupabaseKey(value: string): boolean {
  if (value.startsWith("sb_secret_")) return true;
  return decodedSupabaseRole(value) === "service_role";
}

export const MAX_TRUSTED_PROXY_HOPS = 10;

/**
 * Normalises TRUST_PROXY to a trusted-hop count. Accepts "false" (no proxy)
 * or a non-negative integer string up to MAX_TRUSTED_PROXY_HOPS. "true" is
 * rejected on purpose: trusting every hop lets clients spoof X-Forwarded-For.
 */
function trustedProxyHops(
  value: unknown,
  helpers: Joi.CustomHelpers,
): number | Joi.ErrorReport {
  if (typeof value === "number" && Number.isInteger(value) && value >= 0) {
    return value <= MAX_TRUSTED_PROXY_HOPS
      ? value
      : helpers.error("any.invalid");
  }
  if (typeof value !== "string") return helpers.error("any.invalid");
  if (value === "false") return 0;
  if (!/^(0|[1-9][0-9]*)$/.test(value)) return helpers.error("any.invalid");
  const hops = Number(value);
  return hops <= MAX_TRUSTED_PROXY_HOPS ? hops : helpers.error("any.invalid");
}

/**
 * Fastify `trustProxy` option for a validated hop count (0 disables it).
 *
 * Fastify 5.12 deliberately ignores a bare numeric `trustProxy` (it fails
 * closed and trusts nothing), so the hop count is expressed as a trust
 * function: hop 0 is the socket peer (the reverse proxy) and hops below
 * `hops` are trusted, so the client IP is the first untrusted
 * X-Forwarded-For entry counting from the right, i.e. the address the
 * outermost trusted proxy appended. Entries to its left are client-controlled
 * and ignored.
 */
export function fastifyTrustProxy(
  hops: number,
): false | ((address: string, hop: number) => boolean) {
  return hops > 0 ? (_address, hop) => hop < hops : false;
}

export const environmentSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid("development", "test", "production")
    .default("development"),
  PORT: Joi.number().port().default(3000),
  SUPABASE_URL: Joi.when("NODE_ENV", {
    is: "production",
    then: Joi.string()
      .uri({ scheme: ["https"] })
      .required(),
    otherwise: Joi.string()
      .uri({ scheme: ["https", "http"] })
      .required(),
  }),
  SUPABASE_ANON_KEY: Joi.string()
    .min(20)
    .custom((value: string, helpers) => {
      if (isPrivilegedSupabaseKey(value)) {
        return helpers.error("any.invalid");
      }
      return value;
    })
    .required(),
  SUPABASE_SERVICE_ROLE_KEY: Joi.string()
    .min(20)
    .custom((value: string, helpers) =>
      isPrivilegedSupabaseKey(value) ? value : helpers.error("any.invalid"),
    )
    .required(),
  SUPABASE_JWT_AUDIENCE: Joi.string().default("authenticated"),
  RECENT_AUTH_MAX_AGE_SECONDS: Joi.number()
    .integer()
    .min(60)
    .max(3600)
    .default(600),
  REQUEST_BODY_LIMIT_BYTES: Joi.number()
    .integer()
    .min(1024)
    .max(1048576)
    .default(65536),
  RATE_LIMIT_MAX: Joi.number().integer().min(10).max(10000).default(120),
  RATE_LIMIT_WINDOW_MS: Joi.number()
    .integer()
    .min(1000)
    .max(3600000)
    .default(60000),
  // Number of reverse-proxy hops whose X-Forwarded-For entry is trusted when
  // deriving the client IP (used by rate limiting). Production defaults to 1
  // (Render's single edge proxy); other environments default to 0 (no proxy).
  TRUST_PROXY: Joi.custom(trustedProxyHops, "trusted proxy hop count").default(
    Joi.ref("NODE_ENV", {
      adjust: (nodeEnv: string) => (nodeEnv === "production" ? 1 : 0),
    }),
  ),
  CORS_ALLOWED_ORIGINS: Joi.string().allow("").default(""),
});
