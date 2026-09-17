# BreatheFree Flutter

BreatheFree is a cross-platform smoking-cessation patient app prototype containing all 28 approved screens. The mobile view uses the exact approved 1290 × 2796 App Store artwork. The desktop view places the same experience inside an iPhone-sized preview with screen navigation and developer interaction overlays.

## What is included

- All 28 approved iPhone screens and editable SVG design sources
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
  --project-name breathefree_patient \
  --org com.breathefree \
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
6. Change the bundle identifier from `com.breathefree.breathefreePatient` if needed.
7. Select the iPhone and press Run, or use `flutter run -d <device-id>`.

A free Apple ID can install a development build on a personal device. Publishing through TestFlight or the App Store requires the Apple Developer Program and App Store Connect.

## Navigation

- Phone/tablet: tap the approved controls or swipe left/right.
- Desktop: use the screen list, Previous/Next buttons, arrow keys or swipe the preview.
- Enable **Show tap areas** in desktop mode to inspect the interaction map.

## Project structure

- `lib/main.dart` — app bootstrap, navigation history and protected demo actions
- `lib/models/screen_spec.dart` — the canonical 28-screen catalog
- `lib/models/tap_target.dart` — accessible interaction map and routing
- `lib/screens/approved_screen_player.dart` — mobile/desktop responsive shell
- `lib/widgets/approved_screen_viewport.dart` — pixel-accurate artwork renderer
- `assets/screens/` — runtime 1290 × 2796 approved PNGs
- `design/approved/` — editable approved SVG sources
- `test/` — catalog and navigation tests
- `tool/` — platform setup and run scripts

## Important production boundary

This archive is a complete, compilable Flutter implementation of the approved
28-screen user experience. Cloud development email/password registration,
email-confirmation-aware authentication, profile preferences, and a bounded
quit-plan snapshot are implemented through Flutter, NestJS, and Supabase. Only synthetic quit-plan and support-person data is permitted. Phone
dialing, clinician/EHR connections, secure messaging, remote notifications,
analytics, exports, server-side deletion, and later health domains remain
consent-aware prototype actions or interfaces.

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
