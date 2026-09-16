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

### Live and simulated, and why both exist

`UnplugPlatform.attach` probes the channel at startup. When a platform layer answers, the
module forwards every state change that the intercept must respect and folds the
platform's callbacks back into `UnplugModuleState`. When nothing answers — web, desktop,
a widget test, an iOS build whose entitlement has not been granted — the same methods run
against the state object alone.

Both modes exist because the module must be reviewable on a machine that cannot run it.
What makes that safe rather than misleading is `UnplugModuleState.isLive`, rendered as a
banner on every screen in the module. Do not remove it, and do not let a screen imply a
number is a measurement when it is not.

Every mutation applies locally first and reconciles afterwards, so the UI behaves
identically in both modes and no screen has to branch on which it is in.

### What is still not real

- The Observe Week figures on screen E are sample data when `liveUsage` is null, and the
  screen says so. On iOS they will stay sample-shaped: `DeviceActivityReport` computes
  usage inside an extension with no network access that cannot return values to its host,
  so there is no API that hands the app a number of minutes. `opensAreApproximate` is
  true there for the same reason.
- The Apple `FamilyControls` distribution entitlement has not been applied for, so
  `requestAuthorization` fails on a real iPhone.
- Nothing syncs. There is no server.

Two rules in the state are policy rather than UI, and should move to the server when one
exists: a loosening of a limit always costs a reviewer or a 24-hour cool-off (§4), and a
run of distress tags opens an escalation route that never terminates at a coach (§4.1).

### The child-profile lockdown

Pairing a child profile (§3.2) removes every free-text field in the module: group names
become a pick-from-list, the strict-session reason becomes a pick-from-list, and the
typed-commitment gate is withdrawn — a sentence someone types is a free-text field
whatever it is called. The gate change is written to the shared container rather than
applied at render time, because the intercept is a different process and would otherwise
keep offering it.

`test/no_third_party_sdks_test.dart` enforces the other half of §3.2: no analytics, no
crash reporter that collects identifiers, no session replay, including transitively. The
runtime dependency tree is Flutter SDK packages only; the single native dependency is
kotlinx-coroutines, which Pigeon's generated Kotlin requires.

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
