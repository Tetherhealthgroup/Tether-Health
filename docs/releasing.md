# Releasing Tether Health

Fastlane configuration for App Store and Google Play deployment.

| | |
|---|---|
| iOS lanes | `ios/fastlane/Fastfile` |
| iOS signing | `ios/fastlane/Matchfile`, `ios/fastlane/Appfile` |
| Android lanes | `android/fastlane/Fastfile` |
| Android app | `android/fastlane/Appfile` |

No fastlane plugins are used. Every action these lanes call (`match`, `gym`/`build_app`,
`pilot`/`upload_to_testflight`, `deliver`/`upload_to_app_store`, `supply`/`upload_to_play_store`)
ships with fastlane itself, so there is no `Pluginfile`.

---

## Read this first: the app cannot currently be shipped to the App Store

Two things in `ios/Runner.xcodeproj/project.pbxproj` block iOS distribution today.
Neither is something the lanes can fix for you, because the fix belongs in the Xcode
project, and the project file is deliberately left alone by this configuration.

`fastlane preflight` (run it from `ios/`) detects both and refuses to build. That is
intentional — the alternative is a 20-minute archive that fails at the export step with
a message that does not name the cause.

### Blocker 1 — no development team

No `DEVELOPMENT_TEAM` appears anywhere in the project. Without it, the archive step
cannot choose a signing identity.

### Blocker 2 — the three extensions are configured not to be signed

All three app extensions carry these settings in **every** build configuration
(Debug, Release and Profile — nine occurrences in total):

```
CODE_SIGNING_ALLOWED = NO;
CODE_SIGNING_REQUIRED = NO;
```

An app extension that is not code-signed cannot be embedded in a distributable archive.
The archive itself may succeed; the export or the upload is what fails, and Apple's
error names the extension rather than the setting.

### The four targets that need signing

Verified from the pbxproj. This is the detail that most often gets a Flutter release
wrong: there are **four** signable targets, not one.

| Target | Product type | Bundle identifier |
|---|---|---|
| `Runner` | application | `com.TetherHealthLLC.tetherhealth` |
| `UnplugMonitor` | app-extension | `com.TetherHealthLLC.tetherhealth.unplugmonitor` |
| `UnplugShield` | app-extension | `com.TetherHealthLLC.tetherhealth.unplugshield` |
| `UnplugShieldAction` | app-extension | `com.TetherHealthLLC.tetherhealth.unplugshieldaction` |

`RunnerTests` (`com.TetherHealthLLC.tetherhealth.RunnerTests`) is a unit-test bundle. It
is never distributed and is deliberately excluded from the Matchfile.

Each of the four needs its own App ID in the Developer Portal and its own provisioning
profile. A missing profile for any one of them fails the whole export.

### Xcode project prerequisites (manual, one-time)

Do this in Xcode, or by hand in the pbxproj, before the first release build.

1. **Set the team on all four targets.** Open `ios/Runner.xcworkspace`, then for
   `Runner`, `UnplugMonitor`, `UnplugShield` and `UnplugShieldAction`:
   Signing & Capabilities → Team.

2. **Delete the nine `CODE_SIGNING_ALLOWED = NO;` / `CODE_SIGNING_REQUIRED = NO;`
   lines** from the three extension targets' build configurations. They exist so the
   project builds without a signing identity; that convenience is exactly what must not
   survive into a release.

3. **Switch the Release configuration of all four targets to manual signing**, which is
   what `match` expects:

   ```
   CODE_SIGN_STYLE = Manual;
   CODE_SIGN_IDENTITY = "Apple Distribution";
   PROVISIONING_PROFILE_SPECIFIER = "match AppStore <the target's bundle id>";
   ```

   The lanes pass the same mapping through an export options plist, so step 3 is
   belt-and-braces for the archive step rather than the export step. If you would
   rather keep automatic signing, that works too, but the archive then needs
   `-allowProvisioningUpdates` and an interactive Apple login, which defeats the point
   in CI.

4. **Update the legacy signing identity.** The project-level `Profile` configuration
   still sets `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer"`. That identity
   name is long-deprecated; it should be `Apple Development` (or `Apple Distribution`
   for a distribution build).

5. **Register the capabilities in the Developer Portal**, or `match` cannot create
   profiles. Taken from the four `.entitlements` files:

   | Capability | Required by |
   |---|---|
   | App Group `group.com.TetherHealthLLC.tetherhealth.unplug` | all four targets |
   | Family Controls (`com.apple.developer.family-controls`) | `Runner`, `UnplugMonitor` |

### Family Controls needs Apple's approval — plan for weeks, not days

`Runner` and `UnplugMonitor` request `com.apple.developer.family-controls`. The
**distribution** form of this entitlement is not self-service. You must request it from
Apple and wait for approval:

<https://developer.apple.com/contact/request/family-controls-distribution>

Until it is granted, `match` cannot create an App Store profile for those two
identifiers, and the App Store build cannot be produced at all. Development and local
testing work without it. **Start this request before you need it.** It is the longest
lead-time item in the entire release process.

---

## Prerequisites

| Tool | Notes |
|---|---|
| macOS + Xcode | iOS lanes only. Command Line Tools selected via `xcode-select`. |
| Flutter | Must be on `PATH`, or set `FLUTTER_BIN` to its absolute path. Lanes fail immediately if it is missing. |
| Ruby ≥ 2.6 | fastlane's requirement. |
| fastlane | `gem install fastlane`, or via a `Gemfile`. |

A `Gemfile` at the repository root is recommended so every machine and CI runner uses
the same fastlane version. It is not included here because it sits outside the paths
this configuration owns. To add one:

```ruby
# Gemfile
source "https://rubygems.org"
gem "fastlane"
```

then `bundle install`, and prefix every command below with `bundle exec`.

---

## One-time setup

### 1. App Store Connect API key (iOS)

Apple ID + password is not usable here: 2FA cannot be automated and the session expires
after roughly a month. Use an API key.

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**.
2. Create a key with the **App Manager** role.
3. Download the `.p8`. **Apple allows this exactly once.** Store it in your password
   manager immediately.
4. Note the **Key ID** and the **Issuer ID** from the same page.

```bash
export ASC_KEY_ID=XXXXXXXXXX
export ASC_ISSUER_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
export ASC_KEY_P8_PATH="$HOME/.appstoreconnect/AuthKey_XXXXXXXXXX.p8"
```

For CI, most secret stores handle single-line values best, so pass the key's contents
base64-encoded instead of a path:

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy     # store this as a CI secret
export ASC_KEY_P8_BASE64="<the base64 blob>"
```

Set one of `ASC_KEY_P8_PATH` or `ASC_KEY_P8_BASE64`, not both.

### 2. match (iOS certificates and profiles)

`match` keeps one distribution certificate and the four provisioning profiles in an
encrypted store, so every machine and CI runner signs with the same identity.

Create a **private** git repository for them — it holds your distribution private key:

```bash
export MATCH_GIT_URL=git@github.com:TetherHealthLLC/ios-certificates.git
export MATCH_PASSWORD='<the passphrase that encrypts the repo contents>'
export FASTLANE_TEAM_ID=ABCDE12345
```

Then bootstrap once, from a machine with Developer Portal access:

```bash
cd ios
MATCH_READONLY=false fastlane match_bootstrap
```

This creates or fetches App Store profiles for **all four** identifiers and prints the
mapping. If it fails for one identifier specifically, that App ID either does not exist
in the portal yet or is missing a capability from the table above.

On CI, always set `MATCH_READONLY=true`. A team has a hard cap on distribution
certificates, and a runner that silently revokes and recreates one breaks every other
machine.

Google Cloud Storage or S3 work instead of git — set `MATCH_STORAGE_MODE` to
`google_cloud` or `s3` plus the matching bucket variable.

### 3. Android upload keystore

Already documented in the **Release signing** section of `README.md`; repeated here for
completeness. `android/app/build.gradle.kts` reads `android/key.properties`, which is
gitignored, and falls back to the debug key when it is absent. The Gradle task
`verifyReleaseSigning` — a dependency of `bundleRelease` — fails the build rather than
letting a debug-signed bundle reach Play.

```properties
# android/key.properties  (never committed)
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

The Android lanes check for this file before starting a build, so you get the error in
two seconds rather than after a full Gradle run. It is the same check Gradle makes; it
just arrives sooner.

### 4. Google Play service account

1. Play Console → **Setup** → **API access** → link or create a Google Cloud project.
2. Create a service account, then grant it access under
   **Users and permissions** with the *Release manager* role (or at minimum: release to
   testing tracks, release to production).
3. Create and download a **JSON** key for that service account.

```bash
export PLAY_STORE_JSON_KEY_PATH="$HOME/.playstore/play-service-account.json"
```

Verify it before you rely on it:

```bash
cd android && fastlane run validate_play_store_json_key json_key:"$PLAY_STORE_JSON_KEY_PATH"
```

> The very first release of an application ID cannot be made over the API. Upload one
> AAB manually through the Play Console, then these lanes work for every release after
> that.

---

## Cutting a build

All commands assume the environment variables above are exported.

### iOS

```bash
cd ios

fastlane preflight              # verify the machine and project are ready
fastlane build                  # signed IPA, no upload
fastlane beta                   # signed IPA -> TestFlight
fastlane release                # signed IPA -> App Store Connect
```

`fastlane release` uploads the binary but does **not** submit it for review unless you
ask:

```bash
TETHER_SUBMIT_FOR_REVIEW=true fastlane release
```

Store metadata and screenshots are never uploaded by these lanes. Copy for this app goes
through clinical and legal review, and a release lane that can silently overwrite it is
a hazard rather than a convenience. Manage the listing in App Store Connect.

Overriding the version, which otherwise comes from `version: 1.0.0+1` in `pubspec.yaml`:

```bash
TETHER_BUILD_NAME=1.1.0 TETHER_BUILD_NUMBER=42 fastlane beta
```

The IPA lands at `build/ios/ipa/*.ipa`.

### Android

```bash
cd android

fastlane preflight              # verify flutter, keystore and Play key
fastlane build                  # AAB, no upload
fastlane beta                   # AAB -> internal testing track
fastlane release                # AAB -> production track
```

Staged rollout to production, and promotion without rebuilding:

```bash
TETHER_PLAY_ROLLOUT=0.1 fastlane release            # 10% of users
fastlane promote version_code:42 from:internal to:production
```

Dry-run any Play upload — Google validates the request and changes nothing:

```bash
TETHER_PLAY_DRY_RUN=true fastlane beta
```

The AAB lands at `build/app/outputs/bundle/release/app-release.aab`.

---

## Environment variables

### iOS

| Variable | Required | Purpose |
|---|---|---|
| `ASC_KEY_ID` | yes | App Store Connect API key id |
| `ASC_ISSUER_ID` | yes | App Store Connect issuer id |
| `ASC_KEY_P8_PATH` | one of | Absolute path to the `.p8` |
| `ASC_KEY_P8_BASE64` | one of | Base64 of the `.p8`, for CI secret stores |
| `ASC_KEY_IN_HOUSE` | no | `true` only for an Enterprise Program key |
| `FASTLANE_TEAM_ID` | yes | 10-character Developer Portal team id |
| `FASTLANE_ITC_TEAM_ID` | no | Only if the account has several App Store Connect teams |
| `MATCH_GIT_URL` | yes* | Private repo holding encrypted certs and profiles |
| `MATCH_PASSWORD` | yes | Passphrase that decrypts the match store |
| `MATCH_GIT_BRANCH` | no | Defaults to the repo default branch |
| `MATCH_READONLY` | no | Set `true` on CI. Never creates or revokes. |
| `MATCH_STORAGE_MODE` | no | `git` (default), `google_cloud`, `s3` |
| `MATCH_GOOGLE_CLOUD_BUCKET_NAME` / `MATCH_S3_BUCKET` | no | For non-git storage |
| `FLUTTER_BIN` | no | Absolute path to `flutter` if not on `PATH` |
| `TETHER_BUILD_NAME` / `TETHER_BUILD_NUMBER` | no | Override the version from `pubspec.yaml` |
| `TETHER_SUBMIT_FOR_REVIEW` | no | `true` submits to App Review |
| `TETHER_CHANGELOG` | no | TestFlight "What to Test". Defaults to the short commit SHA. |
| `TETHER_TF_WAIT` | no | `false` skips waiting for TestFlight processing |
| `TETHER_EXPORT_METHOD` | no | Defaults to `app-store` |
| `TETHER_IOS_BUILDER` | no | `gym` to archive with gym instead of `flutter build ipa` |
| `TETHER_SKIP_PREFLIGHT` | no | `true` bypasses the project-readiness check |
| `TETHER_IOS_APP_IDENTIFIER` | no | Override the host bundle id |

\* Unless using `google_cloud` or `s3` storage.

### Android

| Variable | Required | Purpose |
|---|---|---|
| `PLAY_STORE_JSON_KEY_PATH` | yes | Absolute path to the Play service-account JSON |
| `SUPPLY_JSON_KEY` | — | Honoured as an alias for the above |
| `FLUTTER_BIN` | no | Absolute path to `flutter` if not on `PATH` |
| `TETHER_BUILD_NAME` / `TETHER_BUILD_NUMBER` | no | Override the version from `pubspec.yaml` |
| `TETHER_PLAY_ROLLOUT` | no | Production rollout fraction, e.g. `0.1` |
| `TETHER_PLAY_RELEASE_STATUS` | no | Defaults to `completed` |
| `TETHER_PLAY_DRY_RUN` | no | `true` validates without publishing |
| `TETHER_PLAY_FROM_TRACK` / `TETHER_PLAY_TO_TRACK` / `TETHER_PLAY_VERSION_CODE` | no | Defaults for `promote` |
| `TETHER_ANDROID_PACKAGE_NAME` | no | Override the application id |

### Secrets

Nothing secret is stored in this repository. Every credential is an environment variable
or a gitignored file:

- `android/key.properties` and the `.jks`/`.keystore` — gitignored (pre-existing rules)
- `AuthKey_*.p8` / any `*.p8` — gitignored
- `play-service-account*.json` — gitignored
- `*.mobileprovision`, `*.cer`, `*.certSigningRequest` — gitignored
- `fastlane/.env*` in all three locations — gitignored
- `MATCH_PASSWORD`, `ASC_*` — environment only, never written to a file in the repo

If you keep credentials in a local `.env`, put it at `ios/fastlane/.env` or
`android/fastlane/.env`; both are ignored.

---

## Two ways to build the iOS app

The default path runs `flutter build ipa --release` and hands it an export options plist
generated from what `match` installed. Flutter does pub get, code generation, asset
assembly, the `xcodebuild` archive and the export. None of it is reimplemented here.

Setting `TETHER_IOS_BUILDER=gym` switches to `flutter build ios --release --no-codesign`
followed by `gym` (`build_app`). Flutter still does the Flutter part; gym owns archive
and export. Use it when you need a gym-only knob such as custom `xcargs`.

Both paths use the same match profiles and the same export options plist. To see exactly
what would be handed to `xcodebuild`, run this in the same shell as a `match` invocation:

```bash
cd ios && fastlane print_export_options
```

### About the `arm64` pin in the xcconfigs

`ios/Flutter/Debug.xcconfig` and `Release.xcconfig` both set `ARCHS = arm64` and
`EXCLUDED_ARCHS = i386 x86_64`, unconditionally, to work around a `lipo` incompatibility
in the simulator build. **This does not affect release lanes.** iOS device and archive
builds are arm64-only regardless, so the pin is a no-op there. The three extension
targets have no `baseConfigurationReference` at all and therefore never see these
xcconfigs; only `Runner` does.

---

## Troubleshooting

**`flutter was not found on PATH`**
The lanes print the `PATH` they searched. On CI, a `PATH` exported in one step is
usually invisible to the next; set `FLUTTER_BIN` to an absolute path instead.

**`The Xcode project is not ready for distribution`**
`preflight` found one of the two blockers at the top of this document. Fix the project;
do not reach for `TETHER_SKIP_PREFLIGHT=true` unless you have configured signing in a
way the check does not recognise.

**`match did not produce a 'appstore' profile for <id>`**
That App ID does not exist in the Developer Portal, or it is missing a capability.
Check the capability table above — Family Controls is the usual culprit, and it needs
Apple's approval.

**`No profiles for 'com.TetherHealthLLC.tetherhealth.unplugX' were found` during export**
An extension profile is missing or expired. Re-run `MATCH_READONLY=false fastlane
match_bootstrap` on a machine with portal access. This is the single most common way a
multi-extension Flutter release fails.

**Archive succeeds, export fails**
Almost always an extension signing problem rather than a host-app one. Read the
`xcodebuild` export log that `flutter build ipa` prints; the flutter tool's own summary
does not surface the cause.

**`Provisioning profile ... doesn't include the com.apple.developer.family-controls entitlement`**
The distribution entitlement has not been granted yet. See the Family Controls section.

**`Authentication credentials are missing or invalid` (Apple)**
The `.p8`, key id and issuer id do not agree, or the key was revoked. Issuer id is a
UUID; key id is 10 characters. If using `ASC_KEY_P8_BASE64`, confirm no newline was
introduced when the secret was stored.

**`This build would be signed with the debug key`**
`android/key.properties` is missing. See *Android upload keystore*.

**Play rejects the upload with a version code conflict**
That version code was already used. Bump `version:` in `pubspec.yaml`, or pass
`TETHER_BUILD_NUMBER`. Play never allows a version code to be reused, even for a
deleted release.

**Play: "Only releases with status draft may be created on draft app"**
The application has never had a release. Upload one AAB manually through the Play
Console first.

**TestFlight processing never completes**
An app with three extensions can take well over 20 minutes. Set `TETHER_TF_WAIT=false`
to return as soon as the upload finishes.

---

## Verification status of this configuration

Honesty matters more here than looking finished.

**Verified on this machine** (fastlane 2.239.0, Ruby 3.3.9):

- Both Fastfiles, both Appfiles and the Matchfile parse; `fastlane lanes` enumerates
  every lane in `ios/` and `android/`.
- `fastlane preflight` runs for real on both platforms and correctly detects the missing
  `DEVELOPMENT_TEAM`, the nine `CODE_SIGNING_ALLOWED = NO` occurrences, and the missing
  `android/key.properties`.
- The `flutter`-missing guard fires and prints the searched `PATH`.
- The export options plist generator produces all four provisioning-profile entries and
  the output passes `plutil -lint`.
- Every option key passed to `match`, `build_app`, `upload_to_testflight`,
  `upload_to_app_store`, `upload_to_play_store` and `app_store_connect_api_key` was
  checked against those actions' real definitions in the installed fastlane.

**Not verified — needs real credentials and a configured project:**

- No `match` run, no Apple or Google API call, no archive, no upload. There are no store
  credentials on this machine.
- No iOS or Android build has been produced, so the output paths
  (`build/ios/ipa/*.ipa`, `build/app/outputs/bundle/release/app-release.aab`) are
  asserted from Flutter's documented layout, not observed.
- The Family Controls distribution entitlement, the App Group registration and the four
  App IDs have not been confirmed to exist in the Developer Portal.

A configuration that parses is not a configuration that ships an app. Expect to iterate
on the first real run, and do the Family Controls request early.
