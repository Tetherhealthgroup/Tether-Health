# Production release checklist

`[x]` means repository-contained technical work is implemented and covered by
local/CI checks. `[ ]` means external approval, infrastructure, credentials,
vendor work, or physical-device evidence is still required. This project must
not be described as production-ready while any release requirement remains open.

## Repository-contained technical MVP

- [x] Email/password signup, confirmation resend, sign-in, secure session
  restoration, sign-out, recovery email, and native recovery deep-link handling.
- [x] Recent-password verification before JSON export or app-data deletion.
- [x] Explicit `DELETE` confirmation, caller-scoped profile/plan/avatar deletion,
  and payload-free deletion receipt logging.
- [x] Owner-only RLS contracts and static/local migration checks.
- [x] API JWT validation, DTO whitelisting, 64 KiB default request limit,
  security headers, configurable rate limiting, CORS allowlisting, and redacted
  5xx handling.
- [x] Flutter uncaught-error boundaries that do not log exception messages,
  widget diagnostics, route arguments, or health payloads.
- [x] Native-screen semantic labels/headings, 200% text-scaling tests, and
  system/user reduced-motion propagation.
- [x] CI gates for Flutter format/analyze/test, unsigned Android release bundle,
  macOS iOS simulator and no-codesign release builds, NestJS
  format/lint/typecheck/unit/e2e/build, and Supabase migration reset/lint/static
  checks.
- [x] Android release builds no longer fall back to debug signing.
- [x] Release configuration rejects HTTP/placeholder endpoints and privileged
  Supabase keys in Flutter; API production config requires HTTPS.

## Product, clinical, legal, and privacy — external

- [ ] Confirm intended use and whether any feature is regulated as a medical
  device.
- [ ] Complete clinician review of medication, withdrawal, pregnancy, urgent
  symptom, quitline, and emergency content for every launch jurisdiction.
- [ ] Complete data-flow mapping, threat modeling, privacy impact assessment,
  retention policy, consent/purpose mapping, and incident-response procedures.
- [ ] Approve terms, privacy policy, store disclosures, and support process.
- [ ] Professionally translate and clinically review Spanish and any additional
  languages. Existing Spanish strings are not a professional translation.
- [ ] Run usability research with people who smoke, including low-literacy and
  disability cohorts.

## Infrastructure and identity — external

- [ ] Provision production Supabase and API environments through approved
  account/credential channels; configure backups, monitoring, key rotation,
  HTTPS, and exact CORS origins.
- [ ] Allowlist `io.breathefree.patient://login-callback` for confirmation and
  password recovery in production Supabase Auth.
- [ ] Implement and approve a privileged Supabase Auth identity-deletion path.
  The MVP deletes all app-owned profile/plan/avatar data and returns
  `authIdentityDeleted: false`; it cannot delete `auth.users` with a publishable
  caller token.
- [ ] Commission independent mobile/API/cloud penetration testing and remediate
  findings.
- [ ] Approve production telemetry/crash service and verify by policy/test that
  health payloads never enter it. No remote crash vendor is configured now.

## Accessibility and device validation — external

- [ ] Replace bitmap screen bodies where dynamic text reflow is required. Bitmap
  artwork cannot reflow even though native screens support device text scaling.
- [ ] Validate VoiceOver, TalkBack, keyboard-only navigation, switch control,
  200% text, contrast, color-independent meaning, and reduced motion on the
  supported physical-device matrix.
- [ ] Provide reviewed captions/transcripts for all production audio/video.

## iOS and Android distribution — external

- [ ] Choose final bundle/application identifiers and minimum OS matrix.
- [ ] Configure protected Apple signing, App Store Connect, privacy nutrition
  labels, age rating, reviewed permission purpose strings, and TestFlight.
- [ ] Configure a protected Android upload keystore, Play Console Data safety,
  content rating, reviewed permissions/notification channels, and internal
  sharing.
- [ ] Produce signed store artifacts only in the approved external release
  environment. Repository CI intentionally builds unsigned/no-codesign outputs.

## Final release gates

- [x] `flutter analyze`, `flutter test`, API lint/typecheck/unit/e2e/build, and
  migration policy scripts are automated.
- [ ] Physical iOS/Android integration tests pass, including offline retry and
  accessibility checks.
- [ ] Production environment smoke tests prove export, app-data deletion,
  recovery links, rate limits, alerting, backup/restore, and Auth identity
  deletion.
- [ ] Clinical, legal, privacy, security, accessibility, and store owners sign
  off on the exact release candidate.
