# BreatheFree production architecture

## Confirmed stack

```text
iPhone / Android Flutter app
          | HTTPS + Supabase access token
          v
NestJS API (TypeScript / Node.js)
          | caller-scoped Supabase client
          v
Supabase (PostgreSQL + Auth + Storage)
```

Supabase Auth is the identity provider and token issuer. Flutter supports
email/password registration, email-confirmation-aware onboarding, confirmation
resend, sign-in, secure session restoration, and sign-out through an auth
boundary that is replaceable in tests. Flutter uses the publishable/anonymous
key only and sends its short-lived access token to the API.
NestJS validates signature, issuer, audience, expiry, and subject against
Supabase JWKS, then accesses Supabase with that caller token. PostgreSQL RLS is
the final authorization boundary. Service-role credentials must never ship in
Flutter and are not required by the profile API.

## Trust boundaries

- **Flutter:** presentation, Keychain/secure-platform Supabase session persistence,
  encrypted device-only guest-plan persistence, testable data abstractions, and
  explicit consent. Guest plans never use the cloud until the user signs in;
  configuration comes from `--dart-define`.
- **NestJS:** JWT and DTO validation, business rules, versioned HTTP contracts,
  and future audit/rate-limit integration points.
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

The approved 28-screen catalog and integer routing contract remain unchanged.
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
