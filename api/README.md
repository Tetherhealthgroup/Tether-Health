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

Rate limiting is keyed on the client IP (`request.ip`). `TRUST_PROXY` sets how
many reverse-proxy hops are trusted when deriving it from `X-Forwarded-For`,
and `TRUST_PROXY_CIDRS` lists the proxy addresses those hops may come from.

- **Default: `0`, in every environment including production.** No proxy is
  trusted and `X-Forwarded-For` is ignored, so the key is the socket peer
  address. Behind a proxy this means all clients share the proxy's bucket (a
  safe, over-restrictive failure) rather than being spoofable.
- **Meaning of the hop count.** `N` trusts at most the `N` nearest proxies.
  The client IP is the first untrusted address, counting from the socket peer
  and then `X-Forwarded-For` from the right; entries to its left are
  client-controlled and ignored. Accepted values: `false`, `0`, or an integer
  up to 10. `true` and anything else is rejected and aborts startup.
- **Proxy allowlist.** A non-zero `TRUST_PROXY` requires `TRUST_PROXY_CIDRS`:
  a comma-separated list of IPv4/IPv6 addresses or CIDR ranges, for example
  `10.0.0.0/8, 2001:db8::/32`. Startup fails if it is missing, empty, or has an
  invalid entry (including a `/0` range). A hop is trusted only if it is within
  the hop count **and** its address is in the list, so a peer outside the list
  (for example, a client connecting to the service directly) keeps its own
  socket address and its `X-Forwarded-*` headers are ignored. With more than
  one hop, every proxy in the chain must be listed. Use the narrowest ranges
  that cover the proxies. The list is ignored when `TRUST_PROXY` is `0`.
- **Spoofing risk.** If the hop count is higher than the real number of
  proxies, or the allowlist covers addresses that clients can connect from, a
  client can forge its own IP. That lets it evade its rate limit or exhaust
  the bucket of a chosen victim address.
- **Owner action required.** The owner must confirm Render's proxy topology
  (how many proxies sit in front of the service and which addresses they
  connect from) before setting a non-zero value. Until then leave it at the
  default of `0`. No Render documentation has been verified by this change.

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
