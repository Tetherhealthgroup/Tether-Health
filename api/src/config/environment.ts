import * as Joi from "joi";

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
      const normalized = value.toLowerCase();
      if (
        normalized.includes("service_role") ||
        normalized.startsWith("sb_secret_")
      ) {
        return helpers.error("any.invalid");
      }
      return value;
    })
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
  CORS_ALLOWED_ORIGINS: Joi.string().allow("").default(""),
});
