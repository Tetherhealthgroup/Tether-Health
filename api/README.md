# BreatheFree API

NestJS v1 API for Supabase-authenticated profile access. Copy `.env.example` to
an ignored `.env` and provide deployment-managed values. Never use the Supabase
service-role key here; the API forwards each caller's token so RLS applies.

Commands: `npm run lint`, `npm run typecheck`, `npm test`, `npm run test:e2e`,
and `npm run build`.
