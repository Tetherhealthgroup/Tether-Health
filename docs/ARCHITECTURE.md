# Tether Health application architecture

## Confirmed stack

```text
iPhone / Android Flutter app
          | HTTPS + Supabase access token
          v
NestJS API (TypeScript / Node.js)
          | caller-scoped client (normal data)
          | server-only admin client (Auth deletion)
          v
Supabase (PostgreSQL + Auth + Storage)
```

Supabase Auth is the identity provider and token issuer. Flutter supports
email/password registration, email-confirmation-aware onboarding, confirmation
resend, sign-in, password recovery/deep-link password update, secure session
restoration, recent-password verification, and sign-out through an auth
boundary that is replaceable in tests. Flutter uses the publishable/anonymous
key only and sends its short-lived access token to the API.
NestJS validates signature, issuer, audience, expiry, and subject against
Supabase JWKS, then accesses normal data with that caller token. PostgreSQL RLS
is the final authorization boundary for app-owned data. Only complete account
deletion uses a separate server-only service-role client. It recursively cleans
the exact avatar prefix and deletes only the identity selected from the verified
JWT subject. Service-role credentials must never ship in Flutter.

## Trust boundaries

- **Flutter:** presentation, Keychain/secure-platform Supabase session persistence,
  encrypted device-only guest-plan and program persistence, testable data abstractions, and
  explicit consent. Guest plans never use the cloud until the user signs in;
  configuration comes from `--dart-define`.
- **NestJS:** JWT and DTO validation, business rules, versioned HTTP contracts,
and privacy-safe deletion receipt boundaries. Requests have a 64 KiB default
body limit, security headers, configurable per-IP rate limits, allowlisted CORS,
and payload-free 5xx logging.
- **Supabase:** identity, relational constraints, private storage, grants, RLS,
  backups, and key rotation.

## Clinical and privacy boundary

The cloud development environment stores identity-linked profile preferences and
one bounded quit-plan snapshot so persistence, API contracts, and user-isolation
controls can be proven end to end. The quit-plan slice includes a baseline range,
selected triggers/reasons, quit path/date, preparation preferences, and bounded
support-person placeholders.

Only synthetic test data is permitted in `breathefree-dev`. Real tobacco use,
cravings, symptoms, medications, pregnancy, mental-health information, contacts,
free text, or other patient information must not be entered. Production use
requires separate clinical/privacy review, purpose and consent mapping,
retention/deletion rules, audit design, minimum-necessary DTOs, provider BAAs,
and tests proving user/clinician separation. Health payloads must not enter logs,
analytics, crash reports, push notifications, or object names.

## Incremental Flutter migration

The approved 28-screen BreatheFree catalog and integer routing contract remain
unchanged and isolated from Heartwise, Steady, and ClearAir content. A shared
program picker switches modules while preserving the authenticated account
context. Module snapshots are encrypted locally per account and use
caller-scoped API/RLS synchronization with offline fallback.
Authentication, registration, and profiles sit behind interfaces with fakes for
tests. Registration does not claim an authenticated session when Supabase
requires email confirmation; the user confirms externally and then returns to
sign in. A signed-out user can explicitly save an encrypted plan on one device.
After sign-in, the app asks for explicit consent before uploading a device plan.
The API uses an atomic create-only import so a concurrently created cloud plan
returns a conflict instead of being overwritten; conflicts preserve both plans
and require an explicit choice before any overwrite. Sign-out recreates the journey widget tree so cloud plan state cannot
remain visible in a later guest session. Password recovery remains a later
slice. Screens can migrate one bounded domain at a time without coupling
widgets to Supabase or HTTP.

## Technical MVP boundary

The repository-contained MVP includes profiles, one bounded quit-plan snapshot,
encrypted device guest-plan storage, authenticated JSON export, app-owned data
deletion, password recovery, API abuse controls, privacy-safe error boundaries,
native-screen text scaling/reduced motion, migration policy checks, and
unsigned/no-codesign release builds.

Deletion crosses the trust boundary only inside the API. A caller-scoped RPC
first sets a durable profile-row barrier. Storage insert/update authorization
locks that same row, so deletion drains uploads already in flight and blocks new
ones before cleanup starts. The server-only client then flat-lists every nested
object under the verified subject's exact prefix with cursor pagination and
removes bounded batches. Only then does `delete_my_app_data` remove database
rows and the administrator delete the Auth identity. The ordered cleanup is
idempotent; failures return 502 and retries repeat cleanup safely. An
already-absent identity is success. No health payload or user identifier is
written to application logs.

Before the destructive request, Flutter persists an encrypted deletion-intent
tombstone; failure or timeout aborts before the API call. After a 2xx confirms
the endpoint ran, observable session invalidation, remote sign-out, encrypted
program-snapshot cleanup, and in-memory/persisted quit-plan cleanup start
independently of the receipt write and are time-bounded at the coordinator.
The receipt is written to a separate encrypted key, leaving the tombstone as a
fallback until **Done**. A throwing or stalled receipt write therefore cannot
defer local cleanup. On restart either record suppresses a stale session and
retries idempotent local cleanup. A valid receipt preserves its exact request ID;
an intent-only recovery makes no claim that a receipt was restored. Unusable 2xx
deletion bodies are retried once with the same recent token, then fall back to
the tombstone and local cleanup. Only explicit acknowledgement clears both keys.

External release dependencies remain: production infrastructure and redirect
allowlisting, service-role provisioning and identity-retention policy, final
identifiers and signing, clinical/legal/privacy approval, professional localization,
vendor penetration testing, store review, and physical-device validation.
