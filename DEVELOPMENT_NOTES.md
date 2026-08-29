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

## Contact and safety routing

`lib/config/contact_info.dart` is the single source of truth for every way the
app puts a person in touch with help: both approved quitlines, the emergency
number, and the product-support address `support@tetherhealthgroup.com`.

Previously the English quitline's name lived in `tap_target.dart` and its
number in `main.dart`, with nothing connecting them — a correctness risk for a
safety route, because one could be corrected and the other left stale. Nothing
should hard-code a number or address again; read it from `ContactInfo`.

The support address is deliberately kept distinct from the clinical routes. It
reaches the people who build the app, and its dialog says so and points urgent
symptoms at the emergency number and the quitline instead.

### Fixed: dialogs could never open

`_BreatheFreeAppState` builds the `MaterialApp`, so its own `context` sits
*above* it and has neither a `Navigator` nor `MaterialLocalizations`. Every
dialog was shown with that context and therefore threw "No MaterialLocalizations
found" instead of opening — the quitline, call-back consent, data-export and
account-deletion dialogs included. The app now holds a `navigatorKey` and shows
dialogs from `_navigatorKey.currentContext`. Covered by
`test/contact_info_test.dart`.

### Fixed: the primary action ran underneath the tab bar

On screens 13-21 the "Continue" target ran from 0.72 to 0.89 while the tab bar
starts at 0.875. The tab bar is added to the `Stack` later and so won the hit
test, silently taking the lowest strip of the primary action. Targets above the
tab bar now stop at `_tabBarTop`, and a test asserts that no two targets on any
screen overlap.

### Reachable now

The approved artwork drew these controls, but no tap target covered them:
the Spanish quitline on the Support hub, the supporter and quit-coach rows, and
the accessibility card in Settings & privacy.

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
