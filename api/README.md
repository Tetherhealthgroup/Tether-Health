# BreatheFree API

NestJS v1 API for Supabase-authenticated profile, synthetic quit-plan, bounded
account export, and app-owned data deletion access.
Copy `.env.example` to an ignored `.env` and provide deployment-managed values.
Never use the Supabase service-role key here; the API forwards each caller's
token so RLS applies.

Commands: `npm run lint`, `npm run typecheck`, `npm test`, `npm run test:e2e`,
and `npm run build`.

Export and deletion require a timestamped Supabase JWT authentication-method
reference (`amr`) no older than
`RECENT_AUTH_MAX_AGE_SECONDS` (10 minutes by default). The Flutter client obtains
a fresh token by re-entering the account password. Deletion returns a request ID
and counts but never logs profile or quit-plan payloads. Supabase Auth identity
deletion is intentionally outside this publishable-key service.

Default protections are a 64 KiB body limit, 120 requests/minute/IP, Helmet
headers, optional explicit CORS allowlisting, DTO whitelisting, and redacted
error responses. Tune limits with deployment-managed environment values.

## Development deployment

The repository-root `render.yaml` defines a free Render web service for the
`develop` branch. During Blueprint creation, enter only the cloud Supabase
publishable key for `SUPABASE_ANON_KEY`; never enter a service-role or secret
key. Automatic deployments are disabled, so later releases remain deliberate.

This free development service is not approved for real patient, support-person,
or clinical data. Use synthetic quit-plan values only. Production hosting
requires a separate security/compliance review and appropriate contractual
safeguards.
