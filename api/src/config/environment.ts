import * as Joi from "joi";

export const environmentSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid("development", "test", "production")
    .default("development"),
  PORT: Joi.number().port().default(3000),
  SUPABASE_URL: Joi.string()
    .uri({ scheme: ["https", "http"] })
    .required(),
  SUPABASE_ANON_KEY: Joi.string().min(20).required(),
  SUPABASE_JWT_AUDIENCE: Joi.string().default("authenticated"),
});
