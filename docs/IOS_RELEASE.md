# iOS App Store readiness runbook (owner)

Bundle ID: `com.TetherHealthLLC.tetherhealth`. This is the iOS counterpart to
`docs/PLAY_RELEASE.md`. Agents and CI never sign, upload, submit or touch App
Store Connect, the Apple Developer portal or Firebase; every console step below
is performed by the owner.

How this was produced (TH-099): a read-only static audit of commit `f06b7c7`
using `git show` and `git grep`. Hosted plugin sources were read from the local
pub cache (`~/.pub-cache/hosted/pub.dev/<package>-<version>/`) at the versions
pinned in `pubspec.lock`; they are not in the repo. Nothing was built: no
`flutter build ios`, `flutter build ipa`, `xcodebuild`, `pod` or
`flutter pub get` was run and no simulator was booted. So nothing here proves
the app builds, signs or passes App Store processing.

Labels: **Observed** = seen in the file cited. **Inferred** = reasoned from
what was seen, not proven. **Assumed** = an Apple rule stated from memory, with
the guideline or document to confirm it against. **Unknown** = not visible from
the repo. Wording about privacy or legal matters is **needs-counsel** and is
never final here.

## 1. Already satisfied (Observed at `f06b7c7`)

### Bundle identifier, per build configuration

| Target / configuration | `PRODUCT_BUNDLE_IDENTIFIER` | Citation |
|---|---|---|
| Runner / Debug | `com.TetherHealthLLC.tetherhealth` | `ios/Runner.xcodeproj/project.pbxproj:579` (config named at `:586`) |
| Runner / Release | `com.TetherHealthLLC.tetherhealth` | `ios/Runner.xcodeproj/project.pbxproj:603` (`:609`) |
| Runner / Profile | `com.TetherHealthLLC.tetherhealth` | `ios/Runner.xcodeproj/project.pbxproj:396` (`:402`) |
| RunnerTests / Debug | `com.TetherHealthLLC.tetherhealth.RunnerTests` | `ios/Runner.xcodeproj/project.pbxproj:412` (`:419`) |
| RunnerTests / Release | `com.TetherHealthLLC.tetherhealth.RunnerTests` | `ios/Runner.xcodeproj/project.pbxproj:429` (`:434`) |
| RunnerTests / Profile | `com.TetherHealthLLC.tetherhealth.RunnerTests` | `ios/Runner.xcodeproj/project.pbxproj:444` (`:449`) |

All three Runner configurations match the Android application ID and the
Firebase Android package in `tether-health-llc` (BASELINE.md:104). The
Archive action in the shared scheme uses `Release`
(`ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme:116`).

### Deployment target and devices

- `IPHONEOS_DEPLOYMENT_TARGET = 15.0` at project level for Profile, Debug and
  Release (`ios/Runner.xcodeproj/project.pbxproj:371`, `:500`, `:552`). The
  Runner target does not override it (`:380-402`, `:564-610`).
- `TARGETED_DEVICE_FAMILY = "1,2"`, so iPhone **and iPad**
  (`project.pbxproj:376`, `:505`, `:559`). See gap G-6.
- The vendored `flutter_tts` package declares iOS 13.0
  (`third_party/flutter_tts/ios/flutter_tts/Package.swift:7-9`), below 15.0.

### `ios/Runner/Info.plist`

- Display name: `CFBundleDisplayName` = `Tether Health`
  (`ios/Runner/Info.plist:11-12`); `CFBundleName` = `Tether Health` (`:19-20`).
- Version keys come from Flutter: `CFBundleShortVersionString` =
  `$(FLUTTER_BUILD_NAME)` (`:23-24`), `CFBundleVersion` =
  `$(FLUTTER_BUILD_NUMBER)` (`:27-28`). `pubspec.yaml:4` is `1.0.0+2`, so a
  build from this commit would be version 1.0.0, build 2 (Inferred). The
  Runner configurations set `CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)"`
  (`project.pbxproj:388`, `:571`, `:595`).
- Usage descriptions: `NSPhotoLibraryUsageDescription` is present
  (`Info.plist:5-6`). Its text is user-facing privacy wording:
  **needs-counsel** before release.
- The app's only image source is the photo library:
  `ImageSource.gallery` (`lib/widgets/profile_editor_dialog.dart:55`), and
  `git grep "ImageSource\."` in `lib/` finds no other source. No camera,
  microphone, location, contacts, Bluetooth, HealthKit, motion or speech
  recognition use was found, and `Info.plist` declares no other `NS*` usage
  key. `flutter_tts` is text-to-speech only and needs no usage key (Inferred
  from `pubspec.yaml:13-15` and the plugin sources listed in section 1, privacy
  manifests). Possible upload warning for camera/microphone: gap G-3.

### iOS plugins from `pubspec.lock` and their own privacy manifests

| Plugin (version, `pubspec.lock` line) | Ships `PrivacyInfo.xcprivacy`? | Evidence |
|---|---|---|
| `flutter_tts` 4.2.5, vendored (`:262-268`) | Yes, empty, `NSPrivacyTracking` false | `third_party/flutter_tts/ios/flutter_tts/Sources/flutter_tts/PrivacyInfo.xcprivacy:5-12`, bundled by `Package.swift:22-24` |
| `app_links` 7.2.1 (`:4`, `:11`) | Yes | pub cache `ios/app_links/Sources/app_links/PrivacyInfo.xcprivacy` |
| `flutter_secure_storage_darwin` 0.4.3 (`:217`, `:224`) | Yes | pub cache `darwin/flutter_secure_storage_darwin/Sources/flutter_secure_storage_darwin/Resources/PrivacyInfo.xcprivacy` |
| `image_picker_ios` 0.8.13+8 (`:346`, `:353`) | Yes | pub cache `ios/image_picker_ios/Sources/image_picker_ios/Resources/PrivacyInfo.xcprivacy` |
| `shared_preferences_foundation` 2.5.7 (`:642`, `:649`) | Yes; declares `NSPrivacyAccessedAPICategoryUserDefaults`, reason `1C8F.1` | pub cache `darwin/shared_preferences_foundation/Sources/shared_preferences_foundation/Resources/PrivacyInfo.xcprivacy` |
| `url_launcher_ios` 6.4.2 (`:791`, `:798`) | Yes | pub cache `ios/url_launcher_ios/Sources/url_launcher_ios/Resources/PrivacyInfo.xcprivacy` |
| `path_provider_foundation` 2.6.0 (`:538`, `:545`) | No native plugin: Dart FFI (`dartPluginClass` only) over `objective_c` 9.6.0 (`:490`, `:497`), whose native-assets hook ships no privacy manifest | pub cache `path_provider_foundation-2.6.0/pubspec.yaml:11-18`; `objective_c-9.6.0/hook/build.dart` |

The pub-cache rows are Observed on this Mac only; they are not pinned in git
beyond the version and hash in `pubspec.lock`.

### Swift Package Manager, not CocoaPods

- The project links the local package `FlutterGeneratedPluginSwiftPackage`
  (`project.pbxproj:15`, `:646-651`, `:653-658`).
- No `ios/Podfile` or `Podfile.lock` is tracked (`git ls-tree -r f06b7c7 ios`),
  and `ios/.gitignore:13` ignores `**/Pods/`. `ios/Flutter/Debug.xcconfig:1` and
  `ios/Flutter/Release.xcconfig:1` include only `Generated.xcconfig` (no
  `Pods` include).
- Every native iOS plugin above ships a `Package.swift` (Observed in the pub
  cache, and `third_party/flutter_tts/ios/flutter_tts/Package.swift` in git).
- Per `tether-health-ai-office/AGENTS.md` (iOS builds section): if a build adds
  `Pods` entries to `project.pbxproj`, an `ios/Podfile` or `#include?` lines to
  `ios/Flutter/*.xcconfig`, that is tooling noise; never commit it.

### Signing settings present in the repo

- `DEVELOPMENT_TEAM = GJH79955Q7` on Runner Profile, Debug and Release
  (`project.pbxproj:389`, `:572`, `:596`), first added in commit `fcb6307`
  (2026-08-23, "Configure iOS signing and bundle identifier"). **Which Apple
  team this is, and whether it belongs to Tether Health LLC, is Unknown.** See
  owner item O-2.
- The Runner target sets no `CODE_SIGN_STYLE`, so Xcode's default applies
  (Automatic, Assumed). RunnerTests sets `CODE_SIGN_STYLE = Automatic`
  (`project.pbxproj:408`, `:425`, `:440`). Project level sets
  `"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer"` (`:357`, `:480`,
  `:538`).
- Entitlements: Debug uses `Runner/DebugProfile.entitlements`, Profile and
  Release use `Runner/Release.entitlements` (`project.pbxproj:570`, `:387`,
  `:594`). Both contain only `keychain-access-groups` =
  `$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`
  (`ios/Runner/DebugProfile.entitlements:5-8`,
  `ios/Runner/Release.entitlements:5-8`). No `aps-environment` (push),
  associated domains, HealthKit or Sign in with Apple entitlement.
- No certificate, provisioning profile, `ExportOptions.plist` or App Store
  Connect API key is in the repo (`git ls-tree -r f06b7c7 ios`). That is
  correct; they must stay out.

### Session storage and transport

- The Supabase session is stored with `flutter_secure_storage` (Keychain on
  iOS): `localStorage: SecureSessionStorage()` (`lib/main.dart:85`,
  `lib/auth/secure_session_storage.dart:6-10`).
- Configured hosts must be `https` (`lib/config/app_config.dart:50-51`, and for
  production `:102`). `Info.plist` has no `NSAppTransportSecurity` exception,
  so App Transport Security defaults apply (Inferred).

### Sign-in: no third-party login, so Sign in with Apple is not triggered

- Sign-in is email and password through Supabase Auth only:
  `signInWithPassword` (`lib/auth/auth_gateway.dart:85-88`) and `signUp`
  (`:101-105`).
- `git grep -i` over `lib/` and `pubspec.yaml` for `signInWithOAuth`,
  `OAuthProvider`, `signInWithIdToken`, `google_sign_in`, `sign_in_with_apple`,
  `facebook`, `signInWithOtp` and `passkey` finds nothing.
- Rule (Assumed, confirm against App Review Guideline **4.8 Login Services**):
  an app that offers a third-party or social login must also offer an
  equivalent privacy-focused option such as Sign in with Apple; an app using
  only its own account system is not required to. On that reading, 4.8 does
  not apply today. Adding any Google/Facebook/other OAuth later reopens it.

### In-app account deletion path

- Settings has a "Delete account and data" tile
  (`lib/screens/settings_privacy_screen.dart:549-560`, handler `:123-126`).
  The approved-screen flow also maps a "Delete account and data" tap target to
  `TapAction.deleteAccount` (`lib/models/tap_target.dart:119-123`,
  `lib/main.dart:356-357`).
- Both routes open the deletion dialog
  (`lib/screens/approved_screen_player.dart:709-732`, `lib/main.dart:393-404`),
  which calls `DELETE /v1/account/data` with `{"confirmation": "DELETE"}`
  (`lib/account/account_data_api_client.dart:106-113`).
- Server: `api/src/account/account.controller.ts:16-19` →
  `AccountService.deleteData` (`api/src/account/account.service.ts:78-132`):
  deletion barrier RPC (`:85`), avatar purge (`:94`), `delete_my_app_data`
  RPC (`:102`), then `deleteAuthIdentity` (`:110`), which hard-deletes the
  Supabase Auth user (`api/src/auth/supabase-admin.service.ts:25-32`).
- Rule (Assumed, confirm against App Review Guideline **5.1.1(v)** Account
  Sign-In): an app that supports account creation must let users start
  account deletion inside the app. The code path exists. Whether it works
  against production depends on the deployed API (gap G-8, owner item O-8).
  What deletion leaves behind is recorded in the office risk register R-066
  (guest-scope data on the device, server logs and backups).

## 2. Gaps an engineer can fix later (proposed tickets, not done in TH-099)

Each is a proposed ticket for th-lead to file. None was changed here.

- **G-1 App-level privacy manifest.** No `ios/Runner/PrivacyInfo.xcprivacy`
  exists (absent from `git ls-tree -r f06b7c7 ios`). Add one that declares
  `NSPrivacyTracking` false and the `NSPrivacyCollectedDataTypes` the app
  actually collects (email, name, photo, health-program entries, per R-054 and
  R-066), matching the App Privacy answers in O-7. The data-type list is
  **needs-counsel**. Also decide whether any required-reason API is used by
  app code or by the `objective_c` native asset, which ships no manifest
  (Unknown). Rule (Assumed, confirm against Apple's "Privacy manifest files"
  and "Describing use of required reason API" documentation): uploads that use
  required-reason APIs without a declared reason are rejected.
- **G-2 Export compliance key.** `ITSAppUsesNonExemptEncryption` is absent from
  `Info.plist`, so App Store Connect asks the export-compliance question on
  every build (Assumed). The app's encryption visible here is HTTPS and the
  system Keychain (Inferred from `app_config.dart:50-51` and
  `secure_session_storage.dart`). After the owner confirms the answer (O-6),
  add `ITSAppUsesNonExemptEncryption` = `false` if it applies. Rule (Assumed,
  confirm against Apple's "Complying with Encryption Export Regulations").
- **G-3 Purpose strings for linked-but-unused APIs.** `image_picker_ios`
  contains camera and video capture code even though the app uses only
  `ImageSource.gallery`. App Store processing may warn about a missing
  `NSCameraUsageDescription` or `NSMicrophoneUsageDescription` (Assumed,
  confirm from the first TestFlight upload's processing email, ITMS-90683).
  Add them only if Apple flags them; their wording is **needs-counsel**.
- **G-4 Auth redirect URL scheme.** The only URL scheme is
  `io.breathefree.patient` (`Info.plist:29-39`), used as the Supabase email
  redirect `io.breathefree.patient://login-callback`
  (`lib/auth/auth_gateway.dart:66-67`; Android
  `android/app/src/main/AndroidManifest.xml:34-35`). It carries the old
  BreatheFree name, and any app can claim a custom scheme (Inferred). Option:
  move to Universal Links on a Tether Health domain (associated-domains
  entitlement plus an `apple-app-site-association` file on the website), or
  rename the scheme on both platforms. Needs th-security review; touches auth.
- **G-5 iOS release build script.** Android has
  `tool/build_play_release.sh`, which validates the release define file,
  version and certificate. No iOS equivalent exists (`git ls-tree f06b7c7
  tool/`). Propose `tool/build_ios_release.sh` that reuses the same
  `--dart-define-from-file` validation and runs `flutter build ipa`, with no
  signing secrets in the repo.
- **G-6 Device family and orientation.** The app targets iPad
  (`TARGETED_DEVICE_FAMILY = "1,2"`) and allows iPhone landscape
  (`Info.plist:69-74`), while the approved design is portrait phone artwork
  (`README.md:3`). Decide iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) or keep
  iPad and test its layouts. Rule (Assumed, confirm in App Store Connect
  screenshot specifications): an iPad-capable app needs iPad screenshots.
  Landscape behaviour on iPhone is Unknown.
- **G-7 CI toolchain vs Apple's SDK minimum.** CI builds iOS on `macos-15`
  with Flutter 3.47.1, unsigned (`.github/workflows/flutter-ci.yml:39-51`).
  The Xcode/SDK version on that runner is Unknown here. Rule (Assumed, confirm
  against Apple's current "Upcoming requirements" page): App Store uploads
  must be built with a minimum Xcode and iOS SDK. Pin and record the Xcode
  version used for the store build.
- **G-8 Deletion against production.** The client deletion path depends on
  the NestJS API at the production `API_BASE_URL` (Unknown) having the
  Supabase service-role credential to delete the Auth user. Add a smoke test
  on a synthetic account against the production stack once it exists (owner
  runs it; links to R-066 and BE-047).
- **G-9 Release checklist.** `PRODUCTION_RELEASE_CHECKLIST.md:75-79` lists the
  iOS items as one line each; link them to this runbook once TH-099 merges.

## 3. Owner-only items

None of these were started by any agent. Do them in roughly this order.

- **O-1 Apple Developer Program enrolment for Tether Health LLC** as an
  organization. Status Unknown. Organization enrolment needs a D-U-N-S number
  for the legal entity and someone with legal authority to accept the
  agreements (Assumed, confirm on Apple's enrolment page).
- **O-2 Confirm the team ID.** In the Apple Developer account, compare the
  Tether Health LLC Team ID with `GJH79955Q7` in `project.pbxproj:389,572,596`.
  If it differs, tell th-release; a one-line ticket changes it. Do not sign
  store builds with a personal team.
- **O-3 Register the App ID** `com.TetherHealthLLC.tetherhealth` (explicit, not
  wildcard) under the LLC team. Capabilities needed today: none beyond the
  default; Keychain Sharing comes from the entitlements file. Add Associated
  Domains only if G-4 chooses Universal Links, and Push Notifications only if
  O-4 applies.
- **O-4 Firebase iOS app (conditional).** `tether-health-llc` has only the
  Android app (BASELINE.md:104). The Flutter app has no Firebase SDK
  (BASELINE.md:106). Register an iOS app with bundle ID
  `com.TetherHealthLLC.tetherhealth` only if you will send FCM push to iOS
  (that also needs an APNs key uploaded to Firebase and an `aps-environment`
  entitlement, which the app does not have) or use Firebase App Distribution
  for iOS. Otherwise TestFlight alone is enough.
- **O-5 Certificates and profiles.** Create an Apple Distribution certificate
  and an App Store provisioning profile for the App ID, or let Xcode automatic
  signing manage them under the LLC team. Keep the private key and any
  `.p12` in a password manager or `~/secure/`, never in the repo.
- **O-6 App Store Connect record.** New app: platform iOS, name (availability
  Unknown), primary language, bundle ID `com.TetherHealthLLC.tetherhealth`,
  SKU. Then category, age rating questionnaire, support URL, and the export
  compliance answer that feeds G-2.
- **O-7 App Privacy answers, with counsel.** Base them on code evidence:
  email and name for the account, photo (avatar), health-program entries,
  processors Supabase and the API host (R-054, R-066, R-072). Tracking: none
  found in code (no ad or analytics SDK in `pubspec.yaml:9-19`). Every answer
  is **needs-counsel**. Also review the claims rules for a health app (Assumed,
  confirm against Guidelines **1.4.1** and **5.1.3**): no medical-device or
  clinical-validation claims (**needs-clinician** for any clinical wording).
- **O-8 Privacy policy URL and deletion page (R-054).** App Store Connect needs
  a privacy policy URL for the app (Assumed, Guideline **5.1.1(i)**). The
  website notice today covers the website only (R-054). Publish an app privacy
  policy and a public account-deletion page that says what is deleted and what
  remains and for how long (R-066). Both are **needs-counsel**. Confirm the
  production API that performs deletion is deployed with its service-role
  credential (G-8). No URL is invented here.
- **O-9 Supabase Auth redirect allow-list.** Confirm that
  `io.breathefree.patient://login-callback` (or its G-4 replacement) is in the
  production project's redirect URLs. Current setting Unknown.
- **O-10 Build and upload.** On a Mac signed in to the LLC team, with the same
  release define file as Android (`docs/PLAY_RELEASE.md` section 3):
  `flutter build ipa --release --dart-define-from-file=$HOME/secure/tether-health/release.json`,
  then upload the `.ipa` with Xcode Organizer or Transporter. **This command
  was not run by any agent (NOT RUN)**; its output path and signing behaviour
  are Unknown here. Discard any `Pods` noise it creates (section 1, SPM).
  Each upload needs a new `CFBundleVersion` (build number) for the same
  version (Assumed).
- **O-11 TestFlight.** Internal testers first. External testers require Beta
  App Review (Assumed, confirm in TestFlight documentation). For App Review,
  give a demo account in the review notes (Assumed, Guideline **2.1**): use a
  synthetic test account, enter its password only in App Store Connect, never
  in a file or repo.
- **O-12 Submit for review.** Tier 4 owner action
  (`tether-health-ai-office/AGENTS.md`, Approval gates). Not before O-7 and O-8
  are signed off by counsel.
