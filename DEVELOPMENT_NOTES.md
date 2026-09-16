# Development notes

## Rendering strategy

The 28 screens were approved individually as 1290 × 2796 App Store images. The Flutter application treats those approved files as immutable view assets and places accessible Flutter interaction targets over them. This guarantees visual parity while the native service layer is implemented independently.

Reference viewport: 430 × 932 logical points at a 3× device pixel ratio.

`ApprovedScreenViewport` uses a contain transform and applies the same transform to normalized interaction rectangles. This keeps the artwork and touch targets aligned on iPhone, Android, web and desktop window sizes.

## Interaction behavior

- Onboarding and guided flows advance linearly.
- Mobile views support horizontal swipe navigation as a nonvisual fallback.
- Bottom-tab targets connect Home, Plan, Progress, Learn and Support.
- The profile/avatar target opens Settings & Privacy.
- Quitline, callback request, data export and deletion demonstrate consent or safety confirmation without performing an external side effect.
- Desktop mode can display normalized tap targets for developer inspection.

## Accessibility

- Every image has a screen-level semantic label.
- Every mapped interaction has an explicit semantic button label.
- The desktop shell supports keyboard navigation.
- The approved visual system was designed for 44 pt iOS / 48 dp Android touch targets.
- Production native forms must continue to support VoiceOver, TalkBack and 200% dynamic text; bitmap text itself cannot dynamically reflow.

## Recommended production migration

The approved bitmap renderer is ideal for design acceptance and regression comparison. During backend integration, replace each screen body incrementally with native responsive widgets while retaining the approved images as golden-test references. Keep the same `ScreenSpec` numbers and route contracts so rollout can happen screen by screen.

## Server integration boundary

Confirmed production architecture:

- iPhone/Android Flutter client: UI, offline queue, encrypted local cache and platform notifications
- NestJS API (TypeScript/Node.js): Supabase JWT validation, consent enforcement, business rules and audit boundaries
- Supabase PostgreSQL: authentication-linked data, constraints and row-level security
- Supabase Storage: private user objects and reviewed educational media
- FHIR adapter: optional clinician/EHR interoperability
- APNs/FCM: generic private notification copy by default

The current cloud-development slice implements Supabase Auth, profile
preferences, and a complete quit-plan snapshot behind NestJS and owner-only RLS.
Use synthetic values only; this does not authorize real patient or support-person
data.

Do not place API secrets, service credentials or production signing certificates in this repository.
See `docs/ARCHITECTURE.md` and `docs/contracts/` for versioned boundaries.
