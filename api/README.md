# BreatheFree API

NestJS v1 API for Supabase-authenticated profile and synthetic quit-plan access.
Copy `.env.example` to an ignored `.env` and provide deployment-managed values.
Never use the Supabase service-role key here; the API forwards each caller's
token so RLS applies.

Commands: `npm run lint`, `npm run typecheck`, `npm test`, `npm run test:e2e`,
and `npm run build`.

## Development deployment

The repository-root `render.yaml` defines a free Render web service for the
`develop` branch. During Blueprint creation, enter only the cloud Supabase
publishable key for `SUPABASE_ANON_KEY`; never enter a service-role or secret
key. Automatic deployments are disabled, so later releases remain deliberate.

This free development service is not approved for real patient, support-person,
or clinical data. Use synthetic quit-plan values only. Production hosting
requires a separate security/compliance review and appropriate contractual
safeguards.
