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

Run `chmod 600` on this file. The script rejects a `SUPABASE_ANON_KEY` that
contains `service_role`, starts with `sb_secret_`, or is a JWT whose role is not
`anon`; the app applies the same check at startup. A release build refuses to
start (shows a configuration message) if either URL is missing or not https. Which production API host to use depends on decision
D2 (the app currently calls the NestJS `api/`); confirm before building.
D2 was decided 2026-10-12 (production is `Tether-Health-Backend`), but the app
still calls `api/`, so the app has not yet been moved onto the decided backend.

## 4. Build

```sh
bash tool/build_play_release.sh --dart-define-from-file=$HOME/secure/tether-health/release.json
```

It validates the file, checks the version, runs format check, analyze and
tests, builds the AAB (`build/app/outputs/bundle/release/app-release.aab`),
reads the versionCode back from the AAB and prints the signing certificate.
It fails if the certificate is `CN=Android Debug`.

After the build the script checks the signing certificate first, then reads
the versionCode from the AAB, so a failed read-back never skips the
certificate check. The versionCode is read with `bundletool` (tried first) or,
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
  `DELETE /v1/account/data` in `api/src/account/account.controller.ts`.
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
