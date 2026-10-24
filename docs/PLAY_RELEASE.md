# Google Play release runbook (owner)

App ID: `com.TetherHealthLLC.tetherhealth`. Agents and CI never sign, upload or
publish; every step below is performed by the owner.

## 1. Create the upload key (once, outside the repo)

> **The first AAB is already uploaded** (1.0.0 (1), 2026-10-12). Play already
> has an upload certificate on file. Before generating any key, the owner must
> check Play Console > Test and release > App integrity for the registered
> upload certificate, and compare its SHA-256 with the key you intend to use.
> A newly generated key would be rejected. This runbook does not choose a key.
> Only generate a new one if the owner decides to, via a Play upload-key reset.

```sh
mkdir -p ~/secure/tether-health && chmod 700 ~/secure/tether-health
keytool -genkeypair -v -storetype PKCS12 \
  -keystore ~/secure/tether-health/upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Back the keystore and both passwords up in a password manager. Never commit
them. `android/key.properties`, `*.jks`, `*.keystore`, `*.p12` and `*.hprof`
are gitignored (`android/.gitignore` and the root `.gitignore`).

For a PKCS12 keystore (the default above) `keyPassword` must equal
`storePassword`; use the same value for both when prompted.

## 2. `android/key.properties`

```properties
storeFile=/Users/<you>/secure/tether-health/upload-keystore.jks
storePassword=<keystore password>
keyAlias=upload
keyPassword=<key password>
```

Use an absolute `storeFile` (a relative path resolves against `android/app/`).
Run `chmod 600 android/key.properties` (and the same for the release define
file in step 3). If the file is missing, any field is empty or `storeFile` does
not exist, every `:app` Gradle task whose name contains `Release`
(`bundleRelease`, `signReleaseBundle`, `packageReleaseBundle`,
`installRelease`, ...) fails with "Release signing is not configured". The debug key is never used for release. Debug builds do not need
this file. CI builds an intentionally unsigned bundle by setting
`TETHER_ALLOW_UNSIGNED_RELEASE=1`; do not set that for store builds.

## 3. Release configuration file

Create a JSON file outside the repo, for example
`~/secure/tether-health/release.json`:

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "API_BASE_URL": "https://<production api host>",
  "SUPABASE_ANON_KEY": "<publishable/anon key only, never service_role>"
}
```

Run `chmod 600` on this file. Before any build step the script checks it and
stops if any rule fails:

- The file holds only the three keys above (`SUPABASE_URL`, `API_BASE_URL`,
  `SUPABASE_ANON_KEY`). Any other top-level key is rejected, whatever its
  value; keep server-side keys out of this file entirely.
- `SUPABASE_ANON_KEY` must be a publishable key (`sb_publishable_` followed by
  letters, digits, `_` or `-`) or an anon JWT (three segments whose payload has
  role `anon`), with no surrounding spaces or prefix. Anything else, including
  `sb_secret_` and `service_role` keys, is rejected.
- Both URLs must be absolute `https` URLs without user info, a query or a
  fragment, and a `.invalid` placeholder host (as in
  `config/dart_defines.example.json`) is rejected. `SUPABASE_URL` is the
  scheme and host only (an optional port and a trailing `/` are allowed).
- `NaN`, `Infinity` and `-Infinity` are not accepted as JSON.
- Error messages name the failing key (or its position) and never print a
  value from the file.

The app applies the same `SUPABASE_ANON_KEY` rule at startup, and a release
build refuses to start (shows a configuration message) if either URL is
missing, not https or a `.invalid` host. Debug runs also reject placeholder
anon keys: use the anon key from a local `supabase start` or an
`sb_publishable_` key. Which production API host to use depends on decision
D2 (the app currently calls the NestJS `backend/api/`); confirm before building.
D2 was decided 2026-10-12 (production is `Tether-Health-Backend`), but the app
still calls `backend/api/`, so the app has not yet been moved onto the decided backend.

## 4. Build

Toolchain: build with Flutter 3.47.1, the version CI pins
(`.github/workflows/flutter-ci.yml`); its `pub get` leaves `pubspec.lock` unchanged.
Older SDKs (3.44.2 was tested) downgrade some packages in `pubspec.lock` on
`pub get`, so the bundle would not match CI. The Android project uses AGP
9.1.0, Kotlin Gradle plugin 2.4.0, Gradle 9.3.1 and JDK 17, with
`android.builtInKotlin=false` and `android.newDsl=false` (the Flutter template
values). With `builtInKotlin=true`, Flutter 3.44.2 fails in the `app_links`
plugin ("The 'org.jetbrains.kotlin.android' plugin is no longer required");
3.47.1 builds either way.

```sh
bash tool/build_play_release.sh --dart-define-from-file=$HOME/secure/tether-health/release.json
```

It validates the file, checks the version, runs format check, analyze and
tests, builds the AAB (`build/app/outputs/bundle/release/app-release.aab`),
reads the versionCode back from the AAB and prints the signing certificate.
It fails if the certificate is `CN=Android Debug`.

After the build the script checks the signing certificate first, then reads
the package and the versionCode from the AAB, so a failed read-back never
skips the certificate check. It fails unless the package is
`com.TetherHealthLLC.tetherhealth`. Both are read with `bundletool` (tried first) or,
if that is not installed, `aapt2`. aapt2 cannot open an AAB directly, so the
script repackages the AAB's `base/manifest/AndroidManifest.xml` and
`base/resources.pb` into a temporary APK (needs `python3`) and dumps that.
If neither tool is on `PATH` the script fails; it does not pass silently.
aapt2 lives in the Android SDK (`$ANDROID_HOME/build-tools/<version>/`) and
is usually not on `PATH`; add that directory. To re-run the certificate and
read-back checks on an existing bundle without building:
`bash tool/build_play_release.sh --verify-aab=build/app/outputs/bundle/release/app-release.aab`.

Options: `--min-version-code N` (default 2) and `--build-number N`. The build
fails before any build step if the pubspec build number, or `--build-number`,
is below the minimum, and after the build if the AAB's versionCode is.
`bash tool/build_play_release.sh --check-version-only` runs just the
pre-build check.

The default of `--min-version-code` is the `min_version_code=2` line near the
top of `tool/build_play_release.sh`. After each upload, raise that default to
the next acceptable versionCode in the same commit as the `pubspec.yaml` bump,
so the guard always sits at the last uploaded code plus one.

## 5. Version codes

`pubspec.yaml` `version: 1.0.0+2` means versionName `1.0.0`, versionCode `2`.

- versionCode `1` (1.0.0 (1)) was uploaded to Play on 2026-10-12.
- The next versionCode must be 2 or higher. Play rejects a versionCode it has
  already seen, so bump the number after `+` for every upload.
- The bump is committed on the release branch before building (currently
  `1.0.0+2`).
- `tool/build_play_release.sh` enforces this (`--min-version-code`, default 2).
  After each upload, record the versionCode read back from the AAB.

## 6. Play Console (owner)

1. The app already exists (package `com.TetherHealthLLC.tetherhealth`, bound
   on first upload; it cannot change). The first AAB (1.0.0 (1)) is already
   uploaded and an Internal testing release is active (2026-10-12).
2. Setup, App signing: check Test and release > App integrity for the upload
   certificate Play registered. The owner confirms it before generating any
   key (see step 1 of this runbook). Google holds the app signing key; the
   upload key is the one Play has on file. If the upload key is lost, request
   a reset through Play support.
3. Testing, Internal testing: create a release, upload the AAB, add testers,
   roll out to internal testing first.
4. Store listing: title, short and full description, icon, feature graphic,
   phone screenshots. Use synthetic data only in screenshots. Copy about health
   claims needs clinician review (`needs-clinician`).
5. Privacy policy URL: `https://www.tetherhealthgroup.com/privacy` (the URL
   the owner specified). **Blocker:** that page currently states it covers
   www.tetherhealthgroup.com only and says BreatheFree will have its own
   in-product privacy notice (`privacy.astro`, `scopeNote`). Before submission
   the owner and counsel must provide an app privacy policy (at that URL or
   another) that covers the app's health and account data. No policy text is
   supplied here (`needs-counsel`).
6. Data safety form: declare what the app collects. From the code
   (Observed): account email and authentication through the Supabase service;
   Name (`displayName` in the profile); Photos (avatar upload to Supabase
   Storage, `lib/profile/avatar_storage.dart`); profile, quit-plan and program
   data sent to the backend API; encrypted on-device storage; in-app data
   export and deletion. Declare health-related data collected.
   - Processors/recipients: Supabase (Observed) and the API host. `render.yaml`
     defines the API as a Render web service (Inferred; the production host is
     not confirmed, see D2 above).
   - Encryption in transit: yes, backed by https enforcement in release builds
     (`AppConfig.validate`, `tool/build_play_release.sh`). Verify that the
     production hosts actually serve TLS.
   - All answers `needs-counsel`; confirm each item before submitting.
7. Health apps declaration (App content, Health apps): complete the form. The
   app is a smoking-cessation program; answer per the actual features and do
   not claim medical-device or clinical-validation status.
8. Other App content forms: target audience, content rating, ads declaration.

## 7. Account deletion requirement

Play requires an in-app deletion path AND a public web URL where a user can
request deletion of the account and data.

- In-app: Observed. Settings has "Delete account and data"
  (`lib/screens/settings_privacy_screen.dart`, wired to
  `_deleteAccountData` in `lib/screens/approved_screen_player.dart`), backed by
  `DELETE /v1/account/data` in `backend/api/src/account/account.controller.ts`.
- Web URL: **Not found.** No dedicated deletion page exists in the website
  repo (`project/src/pages/` on `master`: privacy, support, terms, ...);
  `privacy.astro` only says deletion can be requested.
  **OWNER TODO / BLOCKER:** publish a page that explains how to request account
  and data deletion (name the app, the steps, what is deleted and retained,
  timelines) and enter its URL in the Data safety form. The wording is legal
  text and needs counsel. No URL is invented here.

## 8. Optional: Firebase App Distribution for tester builds

Existing Firebase Android app `1:1059577957003:android:7c85b4035ca824da32a28e`
in project `tether-health-llc`. No Firebase SDK or `google-services.json` is
needed for distribution. The owner runs:

```sh
firebase appdistribution:distribute build/app/outputs/bundle/release/app-release.aab \
  --app 1:1059577957003:android:7c85b4035ca824da32a28e \
  --project tether-health-llc \
  --groups "<tester-group>" \
  --release-notes "<notes>"
```

Distributing an AAB requires the Firebase project to be linked to Google Play.
If it is not, distribute an APK build instead. This command has not been run
by any agent.

## Uploading with fastlane (owner)

`android/fastlane/Fastfile` sends an AAB that `tool/build_play_release.sh`
already built to the Internal testing track as a draft. The owner runs it on
their own Mac with their own Play service-account key. CI never uploads.

### Prerequisites (once)

- Ruby 3.3 or newer (some gems in `android/Gemfile.lock` need it), for example
  through rbenv: `rbenv install 3.3.9 && rbenv shell 3.3.9`.
- Install the pinned gems into `android/vendor/bundle` (gitignored), with the
  lockfile frozen. `android/Gemfile.lock` pins every gem with its checksum,
  and Bundler checks them on install. All three `bundle` commands are
  required:

  ```sh
  cd android
  bundle config set --local path vendor/bundle
  bundle config set --local frozen true
  bundle install
  ```

- The tools that `tool/build_play_release.sh --verify-aab` needs: `keytool`,
  and `bundletool` or `aapt2` on `PATH` (see section 4).
- Turn off fastlane's update check in the shell you upload from. It runs
  before the Fastfile is read, so the Fastfile cannot turn it off:

  ```sh
  export FASTLANE_SKIP_UPDATE_CHECK=1
  ```

### Play service account (once)

1. In Google Cloud, in a project you control, enable the Google Play Android
   Developer API and create a service account. Give it no IAM roles in the
   project. Create a JSON key for it.
2. In Play Console, Users and permissions, invite the service account's email.
   Under App permissions add only `com.TetherHealthLLC.tetherhealth`, and grant
   only "Release apps to testing tracks". Grant no account permissions, no
   production release, no store presence and no admin rights.
3. Keep the JSON outside the repository and readable only by you:

   ```sh
   mkdir -p -m 700 ~/secure/tether-health
   mv ~/Downloads/<downloaded key>.json ~/secure/tether-health/play-service-account.json
   chmod 600 ~/secure/tether-health/play-service-account.json
   export TETHER_PLAY_JSON_KEY=$HOME/secure/tether-health/play-service-account.json
   ```

The lanes read the key path only from `TETHER_PLAY_JSON_KEY` and pass it to
the upload explicitly; the Appfile does not name a key. They refuse to run if
the variable is unset, does not point to a readable service-account JSON key,
or resolves inside the repository. Common key file names (`play-key*.json`,
`*-play-store-key*.json`, `*service-account*.json`, ...) are gitignored as a
backstop, and a test fails if a tracked file contains service-account or
private-key content; do not rely on either.

### Each upload

Start from a fresh terminal. Apart from selecting Ruby as in Prerequisites
(`rbenv shell 3.3.9`, which lasts only for that terminal), add only the two
variables shown below. From the repository root, first check the working tree
and the fastlane folder:

```sh
git status --porcelain
ls -A android/fastlane
```

`git status --porcelain` must print nothing. `ls -A android/fastlane` must show
only `Appfile` and `Fastfile`, plus the `README.md` and `report.xml` that
fastlane writes on each run. Then, in the same terminal:

```sh
rbenv shell 3.3.9
export TETHER_PLAY_JSON_KEY=$HOME/secure/tether-health/play-service-account.json
export FASTLANE_SKIP_UPDATE_CHECK=1
bash tool/build_play_release.sh --dart-define-from-file=$HOME/secure/tether-health/release.json
cd android
bundle exec fastlane android validate aab:build/app/outputs/bundle/release/app-release.aab
bundle exec fastlane android internal aab:build/app/outputs/bundle/release/app-release.aab
```

A relative `aab:` path is read from the repository root. Both lanes first run
`bash tool/build_play_release.sh --verify-aab=<aab>` (signing certificate,
package and versionCode) and stop if it fails. Pass `min_version_code:N` to
either lane to forward `--min-version-code N`.

- `validate` uploads the whole AAB into a Play edit, asks Play to validate it,
  and never commits the edit, so no release is created.
- `internal` uploads the AAB and commits a draft release on the Internal
  testing track. It replaces any existing draft on that track; check the track
  in Play Console first.

The release lands as a **draft** in Internal testing. Review it in Play
Console (Test and release > Testing > Internal testing), then roll it out
there. Promotion to any other track also stays in Play Console.

After each upload, raise the `min_version_code` default in
`tool/build_play_release.sh` to the uploaded versionCode plus one, in the same
commit as the next `pubspec.yaml` bump (section 4), and record the uploaded
versionCode (section 5).

### What leaves the machine

- During `internal` and `validate`: calls to the Google Play Developer API
  (Google's OAuth token endpoint and the Android Publisher API), carrying the
  AAB.
- fastlane's update check to rubygems.org and, when a newer fastlane exists,
  its changelog from api.github.com. Neither happens when
  `FASTLANE_SKIP_UPDATE_CHECK=1` is set.
- `bundle install` fetches the pinned gems from rubygems.org.

fastlane's other outbound calls are turned off at the top of the Fastfile,
before any action runs: usage metrics (`FASTLANE_OPT_OUT_USAGE`) and the
GitHub issue search it runs on errors (`FASTLANE_HIDE_GITHUB_ISSUES`).

### What the lanes never do

- Build, sign or change a version number.
- Upload or change the store listing, metadata, images, screenshots or
  changelogs, or upload APKs.
- Use any track other than Internal testing, any status other than draft, or
  promote or roll out a release. These are fixed in the Fastfile, not lane
  options.
- Run under CI: they stop when `CI` or `GITHUB_ACTIONS` is set. They also stop
  when any `SUPPLY_*` variable is set (those would change the upload
  settings), and when an env file was loaded with `--env` (it could
  override these checks).
- Support verbose-style flags (`--verbose`, `--troubleshoot`,
  `--capture_output`): verbose output can expose credential details. Do not
  use them with these lanes.
- Print the key path or its contents (fastlane's settings table, which
  would show the path, is turned off).
