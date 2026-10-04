# Tether Health API

NestJS v1 API for Supabase-authenticated profiles, private avatar URLs,
synthetic quit plans, bounded Heartwise/Steady/ClearAir snapshots, account
export, and app-owned data deletion.
Copy `.env.example` to an ignored `.env` and provide deployment-managed values.
Normal data access forwards each caller's token so RLS applies. Complete account
deletion additionally requires a deployment-managed `SUPABASE_SERVICE_ROLE_KEY`
for the server-only Auth Admin operation; this credential must never enter
Flutter, source control, logs, or client configuration.

Commands: `npm run lint`, `npm run typecheck`, `npm test`, `npm run test:e2e`,
and `npm run build`.

Export and deletion require a timestamped Supabase JWT authentication-method
reference (`amr`) no older than
`RECENT_AUTH_MAX_AGE_SECONDS` (10 minutes by default). The Flutter client obtains
a fresh token by re-entering the account password. Deletion returns a request ID
and counts but never logs user identifiers, profile, quit-plan, or program payloads.
Deletion first sets a durable database write barrier that drains in-flight avatar
uploads and rejects later writes. The server-only client recursively enumerates
the verified caller's exact Storage prefix with cursor pagination, removes all
objects in bounded batches, deletes app rows, and finally deletes that caller's
Supabase Auth identity. Cleanup is idempotent; a 502, transport failure, or
unusable 2xx receipt body can be retried once safely with the same recent token.

Default protections are a 64 KiB body limit, 120 requests/minute/IP, Helmet
headers, optional explicit CORS allowlisting, DTO whitelisting, and redacted
error responses. Tune limits with deployment-managed environment values.

## Development deployment

The repository-root `render.yaml` defines a free Render web service for the
`develop` branch. During Blueprint creation, enter only the cloud Supabase
publishable key for `SUPABASE_ANON_KEY`. Enter the service-role credential only
in the server-side `SUPABASE_SERVICE_ROLE_KEY` secret field; never place it in
Flutter configuration. Automatic deployments are disabled, so later releases
remain deliberate.

This free development service is not approved for real patient, support-person,
or clinical data. Use synthetic quit-plan values only. Production hosting
requires a separate security/compliance review and appropriate contractual
safeguards.
