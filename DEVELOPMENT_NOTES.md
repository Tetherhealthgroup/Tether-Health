# Development notes

## Rendering strategy

The 28 screens were approved individually as 1290 × 2796 App Store images. The Flutter application treats those approved files as immutable view assets and places accessible Flutter interaction targets over them. This guarantees visual parity while the native service layer is implemented independently.

Reference viewport: 430 × 932 logical points at a 3× device pixel ratio.

`ApprovedScreenViewport` uses a contain transform and applies the same transform to normalized interaction rectangles. This keeps the artwork and touch targets aligned on iPhone, Android, web and desktop window sizes.

## Unplug v2.1 rendering strategy

The approved screens are bitmaps because they were approved as bitmaps. The Unplug
screens have no approved artwork, so they take the migration path this file recommends
below: native responsive widgets from the start.

Both live in one list, `lib/models/prototype_catalog.dart`, so navigation, keyboard
shortcuts and the desktop sidebar never branch on which module they are in. The player
switches on the entry type once, in `_buildScreen`.

The Unplug screens do not bind a horizontal swipe. They contain sliders and scrolling
content, and their page footer carries explicit Previous/Next controls; the keyboard
shortcuts stay because the desktop shell relies on them.

`assets/unplug/intercept_tokens.json` is the one file the Dart, SwiftUI and Android
intercepts all read (addendum §2.1). `InterceptTokens` parses it strictly and
substitutes nothing on failure — a default here would hide the same broken file from the
two native implementations, which is the drift the shared file exists to prevent.

### What is simulated

`UnplugModuleState` is an in-memory simulation of what the native layer would report.
Nothing is persisted, nothing is synced, and no platform API is called. Specifically not
implemented: the iOS `DeviceActivityMonitor`, `ShieldConfiguration` and `ShieldAction`
extensions, the App Group container, the Android foreground service and overlay, and the
Pigeon channel listed on screen G. The Observe Week figures on screen E are sample data,
labelled as such on the screen and in `lib/unplug/models/observe_week.dart`.

Two rules in the state are policy rather than UI, and should move to the server when one
exists: a loosening of a limit always costs a reviewer or a 24-hour cool-off (§4), and a
run of distress tags opens an escalation route that never terminates at a coach (§4.1).

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

Recommended production architecture:

- Flutter client: UI, offline queue, encrypted local cache and platform notifications
- ASP.NET Core API: authentication, consent enforcement, business rules and audit trails
- PostgreSQL or SQL Server: encrypted clinical and application data
- Object storage: reviewed educational media and export packages
- FHIR adapter: optional clinician/EHR interoperability
- APNs/FCM: generic private notification copy by default

Do not place API secrets, service credentials or production signing certificates in this repository.
