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

Supabase Auth is the identity provider and token issuer. Flutter uses the
publishable/anonymous key only and sends its short-lived access token to the API.
NestJS validates signature, issuer, audience, expiry, and subject against
Supabase JWKS, then accesses Supabase with that caller token. PostgreSQL RLS is
the final authorization boundary. Service-role credentials must never ship in
Flutter and are not required by the profile API.

## Trust boundaries

- **Flutter:** presentation, Keychain/secure-platform Supabase session persistence,
  testable data abstractions, and explicit consent. Configuration comes from
  `--dart-define`.
- **NestJS:** JWT and DTO validation, business rules, versioned HTTP contracts,
  and future audit/rate-limit integration points.
- **Supabase:** identity, relational constraints, private storage, grants, RLS,
  backups, and key rotation.

## Clinical and privacy boundary

The first increment stores identity-linked profile preferences only: display
name, locale, time zone, onboarding status, and an optional private avatar path.
It does not store tobacco use, cravings, symptoms, medications, pregnancy,
mental-health information, quit plans, contacts, free text, or exports.

Future health domains require separate clinical/privacy review, purpose and
consent mapping, retention/deletion rules, audit design, minimum-necessary DTOs,
and tests proving user/clinician separation. Health payloads must not enter logs,
analytics, crash reports, push notifications, or object names.

## Incremental Flutter migration

The approved 28-screen catalog and integer routing contract remain unchanged.
Authentication and profiles sit behind interfaces with fakes for tests. Screens
can migrate one bounded domain at a time without coupling widgets to Supabase or
HTTP.
