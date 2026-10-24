# Tether Health — Flutter patient app

Tether Health is the cross-platform patient app for iOS and Android. It is a
host shell with health programs inside it, covering all eleven areas published
at [tetherhealthgroup.com/programs](https://www.tetherhealthgroup.com/programs).

## The shell

The app renders the design bundle in `assets/design/` at runtime rather than
transcribing it into Dart. That bundle is the same one in
`files/tether-design.zip`, and its README is blunt about which artefact is the
asset: *the prototype is disposable; the JSON is the asset.*

Three layers, kept separate:

| Layer | File | What it decides |
|---|---|---|
| Catalogue | `areas.json` | The eleven areas, their 45 service lines, status, measures, safeguards — and each area's own screen list |
| Machinery | `archetypes.json` | 29 reusable screen archetypes. Improve the lapse screen once and every area with lapses inherits it |
| Products | `product.*.json` | Thin. An area, a vocabulary, a screen list, some helplines |
| Constraints | `safeguards.json` | 20 rules a screen cannot ship in violation of |
| Host | `shell.json` | The six screens built once and identical in every area |

Because every area already declares the archetypes it draws on, **a program is
derivable for all eleven areas, not only the two with a product file.** That is
236 screens in total. `lib/tether/journey/journey.dart` is where an area becomes
a program.

Each screen is in one of three honest states, and the app says which:

- **authored** — archetype and copy both exist; the real screen renders
- **awaiting copy** — the archetype exists, nobody wrote the words. Renders the
  archetype's slot list, its design notes and its safeguards, so a writer can
  see exactly what the screen owes
- **awaiting archetype** — the archetype itself has not been built. Says so, and
  does not fake a UI for it

LookUp is complete: all 34 screens render. Twenty-four came from the bundle;
ten were written in this repository to close the gap, along with the two
archetypes they needed (`age_gate`, `environment`). Those ten live in
`assets/design/supplement.*.json`, never override anything the bundle ships,
and **render with a "not clinically reviewed" notice on every screen** — a
health product that cannot tell a reader which of its sentences were signed off
is worse than one that is visibly incomplete.

BreatheFree's 23 screens render as the approved 1290 × 2796 artwork, inside the
shell, with their invisible tap targets intact. They are not "awaiting copy":
the design *is* the image, it has already been signed off, and transcribing it
into slots would produce a second, unreviewed version of it.

The eight planned areas generate journeys but no copy, because `shell.json`
says planned areas have no implementation and the app is required to say so
rather than invent one.

So every screen is in one of four honest states — authored, approved artwork,
awaiting copy, or awaiting archetype — and the renderer for each is chosen by
an exhaustive switch, so a fifth cannot be added without the compiler naming
every place that has to handle it.

## What it remembers

Program enrolment, per-program sharing, every answer and every lapse survive a
relaunch. No package was added to do it: `pigeons/tether_store_api.dart`
generates a four-method key/value contract backed by `UserDefaults` on iOS and
`SharedPreferences` on Android. Writes are debounced and flushed when the app
is backgrounded, and deleting everything clears the stored copy too — the
`export_and_delete` safeguard asks for deletion "completed rather than hidden",
and a delete that leaves the document on disk is the hidden kind.

`tool/verification/` holds an on-device test for this, and explains why it is
not a permanent dev dependency.

## Release signing

`android/key.properties` supplies the release keystore and is never committed.
Without it the release build falls back to the debug key so that
`flutter run --release` and CI keep working — and `./gradlew
verifyReleaseSigning`, which `bundleRelease` depends on, fails the build rather
than letting a debug-signed bundle reach Play.

## Copy that has not been reviewed

`design/copy-review.md` lists every unreviewed string in the app, split by the
kind of reviewer it needs: 223 programme strings across the ten screens written
here, and 82 shell-chrome sites. Regenerate it with
`python3 tool/extract_copy_review.py` after changing either source.

## Entry points

    flutter run                                      # the shell (default)
    flutter run --dart-define=TETHER_ENTRY=prototype # the BreatheFree artwork

The 28 approved 1290 × 2796 screens are the signed-off reference for the
cessation programme, so the bitmap prototype is kept whole and reachable rather
than replaced. It is also at `/dev/prototype` inside the shell.

## What is included

- The host shell: eleven areas, per-program enrolment, per-program sharing, one
  global crisis route, export and deletion
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

## Build, release and test

Everything below is a copy-paste command. Run them from the repository root.

### 1 · Start clean

```bash
flutter clean
flutter pub get
```

### 2 · Check before you build

Both must be clean. CI runs the same two, and the third command is the gate that
catches a channel contract edited without being regenerated.

```bash
flutter analyze                 # expect: No issues found!
flutter test                    # expect: All tests passed!  (160 tests)

./tool/generate_pigeon.sh       # regenerates both Pigeon contracts
git diff --exit-code -- \
  lib/unplug/platform/unplug_api.g.dart \
  lib/tether/platform/tether_store_api.g.dart \
  ios/Runner/Unplug/UnplugApi.g.swift \
  ios/Runner/Store/TetherStoreApi.g.swift \
  android/app/src/main/kotlin/com/TetherHealthLLC/tetherhealth/unplug/UnplugApi.g.kt \
  android/app/src/main/kotlin/com/TetherHealthLLC/tetherhealth/store/TetherStoreApi.g.kt
```

### 3 · Build a release artifact

```bash
flutter build apk --release        # Android APK  → build/app/outputs/flutter-apk/
flutter build appbundle --release  # Play bundle  → build/app/outputs/bundle/
flutter build ipa --release        # iOS archive  → build/ios/ipa/
```

`appbundle --release` will **fail on purpose** until `android/key.properties`
exists, because without it the bundle would be signed with the debug key. See
[Release signing](#release-signing). APK and iOS builds are unaffected.

Confirm an iOS release bundle carries no test scaffolding — it should list
`App.framework` and `Flutter.framework` and nothing else:

```bash
flutter build ios --release --no-codesign
ls build/ios/iphoneos/Runner.app/Frameworks/
```

### 4 · Run it on a simulator or emulator

```bash
flutter devices                                    # list what is attached
flutter run                                        # the shell, on the only device
flutter run -d <device-id>                         # pick one
flutter run -d <device-id> --route=/today          # open straight at a screen
flutter run --dart-define=TETHER_ENTRY=prototype   # the BreatheFree artwork instead
```

**iOS simulator.** Only debug builds run on a simulator — Apple's simulator
cannot execute an AOT binary, so `--release` and `--profile` are rejected there.
The first frame takes about ten seconds while the JIT warms up and the design
bundle parses; a white screen during that window is expected, not a hang.

```bash
open -a Simulator
flutter build ios --simulator --debug
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch  booted com.TetherHealthLLC.tetherhealth
xcrun simctl launch  booted com.TetherHealthLLC.tetherhealth --route=/support
```

Simulator builds are pinned to `arm64` in `ios/Flutter/Debug.xcconfig` and
`ios/Flutter/Release.xcconfig`. Without that pin, current Xcode fails the build
before it compiles anything, with an error that contradicts itself:

```
Target debug_unpack_ios failed: Exception: Binary .../Flutter.framework/Flutter
does not contain architectures "arm64 x86_64".
lipo -info: ... are: x86_64 arm64
```

Flutter verifies the engine with `lipo <binary> -verify_arch arm64 x86_64`, and
the `lipo` in current Xcode reads the second architecture as a second input
file (`-verify_arch requires exactly one input file`). One architecture keeps
that call valid. On an Intel Mac, swap the pin to `x86_64`. Device, `ipa` and
`apk` builds were never affected — they are arm64-only already.

**Android emulator.** A debug APK is ~155 MB and a streamed `adb install` can
time out on it; push then install instead.

```bash
$ANDROID_HOME/emulator/emulator -avd Pixel_8_API_34 &
adb devices                                        # note the emulator id

adb -s emulator-5554 push build/app/outputs/flutter-apk/app-debug.apk /data/local/tmp/t.apk
adb -s emulator-5554 shell pm install -r -t /data/local/tmp/t.apk
adb -s emulator-5554 shell am start -n com.TetherHealthLLC.tetherhealth/.MainActivity
```

Pass `-s <id>` to every `adb` command when more than one device is attached,
or an install lands on whichever it picks — including a phone plugged into USB.

### 5 · Routes worth opening directly

| Route | Screen |
|---|---|
| `/programs` | Your programs — the home screen |
| `/areas` | All eleven health areas, with honest status |
| `/today` | LookUp's daily home |
| `/rescue/start` | The urge-rescue flow |
| `/support` | Support hub, including the live "Call 988" control |
| `/intercept` | The dark shield screen and its eight-second breath |
| `/help-now` | The one global crisis route |
| `/progress` | A screen whose copy was written here — carries its review banner |
| `/program/tobacco/S05` | BreatheFree's approved artwork, inside the shell |
| `/program/cancer` | A generated program: unwritten screens, labelled as such |

`/program/<areaId>` opens any of the eleven programs; `/program/<areaId>/<screenId>`
opens one screen inside it. Plain product paths such as `/progress` resolve to
whichever program can actually draw them.

### 6 · On-device persistence

Persistence crosses a platform channel, which `flutter test` stubs out — so a
green unit test there proves the Dart and nothing else. `tool/verification/`
holds a test that proves the rest, and explains why it is not a permanent dev
dependency.

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
  --org com.TetherHealthLLC \
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
6. Change the bundle identifier from `com.TetherHealthLLC.tetherhealth` if needed.
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

The same script also generates the shell's own contract from
`pigeons/tether_store_api.dart` — a four-method key/value store backed by
`UserDefaults` on iOS and `SharedPreferences` on Android. It is what makes the
shell remember a program between launches without adding a package: the app has
exactly one runtime dependency and `test/no_third_party_sdks_test.dart` fails
the build if a second appears. CI regenerates both contracts and fails on any
difference.

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

- `lib/main.dart` — the entry point; picks the shell or the bitmap prototype
- `lib/tether/tether_app.dart` — the shell app, its theme and bundle loading
- `lib/tether/data/` — the design bundle parsed: areas, archetypes, safeguards, shell, products, content
- `lib/tether/journey/journey.dart` — turns any of the eleven areas into a program
- `lib/tether/state/` — enrolment, per-program sharing, answers, lapses, export and deletion
- `lib/tether/router/tether_router.dart` — routes for the shell and every program in it
- `lib/tether/screens/shell/` — the six host screens, SH1–SH6
- `lib/tether/screens/` — the three journey renderers and the per-program coverage index
- `lib/tether/widgets/` — page chrome, action buttons and the ten content blocks
- `lib/tether/theme/tether_tokens.dart` — colours, type, radii and spacing from the prototype CSS
- `assets/design/` — the design bundle the app renders
- `lib/prototype/prototype_app.dart` — the BreatheFree artwork player, kept reachable
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
- `android/app/src/main/kotlin/com/TetherHealthLLC/tetherhealth/unplug/` — the Android layer
- `assets/screens/` — runtime 1290 × 2796 approved PNGs
- `assets/unplug/intercept_tokens.json` — colours and copy shared by all three intercepts
- `design/approved/` — editable approved SVG sources
- `design/unplug-v2.1-integration-addendum.md` — the specification screens A–L implement
- `design/unplug-platform-submissions.md` — the drafted Apple entitlement and Play declarations
- `test/` — catalog and navigation tests
- `tool/` — platform setup and run scripts

## Important production boundary

This archive is a complete, compilable Flutter implementation of the approved 28-screen user experience. It is intentionally safe as a source prototype: phone dialing, authentication, protected health-data storage, clinician/EHR connections, secure messaging, remote notifications, analytics, exports and server-side deletion are represented by consent-aware demo actions and interfaces.

The production foundation uses Flutter on iPhone/Android, a NestJS API
(TypeScript/Node.js), and Supabase (PostgreSQL, Auth and Storage). Before an App
Store clinical production release, complete security/privacy testing, obtain
clinical/legal review, finish professional Spanish localization and replace the
prototype application identifier/signing configuration. See
`docs/ARCHITECTURE.md`, `docs/contracts/` and `PRODUCTION_RELEASE_CHECKLIST.md`.

For a configured development build, copy `config/dart_defines.example.json` to
an ignored local file, replace placeholders through an approved secret/config
channel, and run Flutter with `--dart-define-from-file=<local-file>`. Only the
Supabase publishable/anonymous key belongs in a client build; never use a
service-role key in Flutter.
