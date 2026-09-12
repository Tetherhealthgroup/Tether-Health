# Tether Health — Flutter patient app

Tether Health is the cross-platform patient app. It carries two modules: the BreatheFree smoking-cessation programme, whose 28 screens are approved artwork, and Unplug v2.1, a digital-wellbeing module built as native responsive views. The mobile view uses the exact approved 1290 × 2796 App Store artwork. The desktop view places the same experience inside an iPhone-sized preview with screen navigation and developer interaction overlays.

## What is included

- All 28 approved iPhone screens and editable SVG design sources
- The Unplug v2.1 digital-wellbeing module, screens A–L, built as native responsive Flutter views
- Flutter/Dart application source
- Mobile swipe navigation and accessible invisible tap targets
- Home, Plan, Progress, Learn, Support and Settings routing
- Quitline, callback-consent, data-export and deletion safety dialogs
- Responsive native desktop review mode
- Keyboard navigation with Left/Right or Page Up/Page Down
- Widget and catalog tests
- CI workflow for analysis, tests, web and Android builds
- Setup scripts for Windows, macOS and Linux
- iOS/App Store, Android and desktop release checklist

## Requirements

- Flutter stable 3.22 or newer (Dart 3.4 or newer)
- Git
- Windows 10/11 with Visual Studio 2022 Desktop development with C++ for a Windows build
- macOS with Xcode for an iPhone/iPad or macOS build
- Android Studio for an Android build

Run `flutter doctor -v` after installing Flutter and resolve the items for the platform you want to build.

## Fast setup

### Windows laptop

Open Command Prompt inside the project folder:

```bat
tool\setup_windows.bat
tool\run_windows.bat
```

To run in Chrome instead:

```bat
flutter run -d chrome
```

### macOS or Linux

```bash
chmod +x tool/*.sh
./tool/setup_macos_linux.sh
```

On macOS, run the iPhone Simulator:

```bash
./tool/run_iphone_simulator.sh
```

On Linux, run the desktop app:

```bash
flutter run -d linux
```

## Manual setup

Flutter creates machine-specific runner folders without changing the approved application source:

```bash
flutter create . \
  --project-name tether_health \
  --org com.tetherhealthgroup \
  --platforms android,ios,web,windows,macos,linux
flutter pub get
flutter analyze
flutter test
```

Then choose a device from `flutter devices`:

```bash
flutter run -d windows
flutter run -d chrome
flutter run -d ios
flutter run -d android
```

## Run on a physical iPhone

An iPhone build must be created on a Mac because Apple requires Xcode:

1. Install Flutter and Xcode on the Mac.
2. Run `./tool/setup_macos_linux.sh`.
3. Connect the unlocked iPhone and tap **Trust This Computer**.
4. Open `ios/Runner.xcworkspace` in Xcode.
5. Select **Runner → Signing & Capabilities** and choose your Apple Development Team.
6. Change the bundle identifier from `com.tetherhealthgroup.tetherhealth` if needed.
7. Select the iPhone and press Run, or use `flutter run -d <device-id>`.

A free Apple ID can install a development build on a personal device. Publishing through TestFlight or the App Store requires the Apple Developer Program and App Store Connect.

## Navigation

- Phone/tablet: tap the approved controls or swipe left/right.
- Desktop: use the screen list, Previous/Next buttons, arrow keys or swipe the preview.
- Enable **Show tap areas** in desktop mode to inspect the interaction map.

The prototype walks one list: approved screens 1–28, then Unplug screens A–L. On a
phone, swiping right from screen 28 continues into the Unplug module, and each Unplug
screen carries its own Previous/Next footer. On desktop, the sidebar lists both
sections. Tap-area overlays apply to the approved screens only — the Unplug screens are
real widgets, so their controls are the interaction map.

## The Unplug v2.1 module

`design/unplug-v2.1-integration-addendum.md` specifies a digital-wellbeing module that
sits alongside cessation. Screens A–L implement it as native responsive Flutter views:

| | Screen | Addendum |
|---|---|---|
| A | What this can see — the platform data ceiling | §1 |
| B | Apps and authorization | §1, §2.3, §3.1 |
| C | Intercept preview | §2.1 |
| D | Effort gate | §2.1 |
| E | Observe Week report | §1, §5 |
| F | Tier and limits | §4 |
| G | Focus session | §2.3 |
| H | Urge SOS and distress routing | §4.1, §5 |
| I | Tracking health | §2.2, §5 |
| J | Guardian zone and Family Sharing | §3 |
| K | Care team and the role matrix | §4, §4.1 |
| L | Program templates | §4.2 |

There is no approved 1290 × 2796 artwork for these screens, so they are widgets rather
than bitmaps and each states the addendum section it implements. Screen K also opens a
read-only **care-team view**, the Phase 1 deliverable in §5.

### The native layer

The module is not Dart-only. `pigeons/unplug_api.dart` defines the channel contract from
§2.3, and `tool/generate_pigeon.sh` generates the Dart, Swift and Kotlin sides of it.
Never edit a generated `.g.dart`, `.g.swift` or `.g.kt`.

**iOS** (`ios/Runner/Unplug/`, plus three extension targets):

| Piece | Where |
|---|---|
| `FamilyControls` authorization and picker | `Runner/Unplug/UnplugHost.swift` |
| `ManagedSettings` shielding, `DeviceActivity` schedule | same |
| App Group shared container | `Runner/Unplug/UnplugSharedState.swift` |
| `DeviceActivityMonitor` extension | `ios/UnplugMonitor/` |
| `ShieldConfiguration` extension | `ios/UnplugShield/` |
| `ShieldAction` extension | `ios/UnplugShieldAction/` |

**Android** (`android/app/src/main/kotlin/.../unplug/`): `UnplugHost` implements the
contract, `UsageReader` reads `UsageStatsManager`, `UnplugWatchService` is the polling
foreground service, `InterceptOverlay` draws the intercept, `AppPickerActivity` is the
picker Android has no system equivalent for, and `UnplugStore` is the shared state the
three of them agree through.

`assets/unplug/intercept_tokens.json` holds the intercept colours and copy. §2.1
requires the intercept to exist three times — Dart, SwiftUI and an Android overlay — and
all three read that one file so they cannot drift apart. Change a colour or a string
there and nowhere else.

### Live or simulated

Every Unplug screen carries a banner saying which it is. When the platform layer answers
`isSupported()`, the module is **live** and the numbers come from the device; otherwise
it runs its own simulation and says so. A prototype that looks identical either way is a
prototype that eventually gets demonstrated as though it were connected.

### What still blocks a real device

The Apple `FamilyControls` distribution entitlement has **not been granted** — it has
not yet been applied for. Until it is, `requestAuthorization` fails on a real iPhone and
screen I reports exactly that. The drafted submissions for Apple and for Google Play are
in `design/unplug-platform-submissions.md`.

## Project structure

- `lib/main.dart` — app bootstrap, navigation history and protected demo actions
- `lib/models/screen_spec.dart` — the canonical 28-screen catalog
- `lib/models/prototype_catalog.dart` — the approved screens and the Unplug screens as one list
- `lib/models/tap_target.dart` — accessible interaction map and routing
- `lib/screens/approved_screen_player.dart` — mobile/desktop responsive shell
- `lib/widgets/approved_screen_viewport.dart` — pixel-accurate artwork renderer
- `lib/unplug/models/` — the module's state, role matrix, templates and platform ceiling
- `lib/unplug/platform/` — the generated channel and the binding that makes it live
- `lib/unplug/screens/` — Unplug screens A–L, their host, and the care-team view
- `lib/unplug/widgets/` — the module's shared page chrome and scope
- `pigeons/unplug_api.dart` — the §2.3 channel contract, the source of the generated code
- `ios/Runner/Unplug/`, `ios/UnplugMonitor/`, `ios/UnplugShield/`, `ios/UnplugShieldAction/` — the iOS layer and its three extensions
- `android/app/src/main/kotlin/com/tetherhealthgroup/tetherhealth/unplug/` — the Android layer
- `assets/screens/` — runtime 1290 × 2796 approved PNGs
- `assets/unplug/intercept_tokens.json` — colours and copy shared by all three intercepts
- `design/approved/` — editable approved SVG sources
- `design/unplug-v2.1-integration-addendum.md` — the specification screens A–L implement
- `design/unplug-platform-submissions.md` — the drafted Apple entitlement and Play declarations
- `test/` — catalog and navigation tests
- `tool/` — platform setup and run scripts

## Important production boundary

This archive is a complete, compilable Flutter implementation of the approved 28-screen user experience. It is intentionally safe as a source prototype: phone dialing, authentication, protected health-data storage, clinician/EHR connections, secure messaging, remote notifications, analytics, exports and server-side deletion are represented by consent-aware demo actions and interfaces.

Before an App Store clinical production release, connect those interfaces to a reviewed ASP.NET Core API and compliant data services, complete security/privacy testing, obtain clinical/legal review, finish professional Spanish localization and replace the prototype application identifier/signing configuration. See `PRODUCTION_RELEASE_CHECKLIST.md`.
