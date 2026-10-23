# Data safety and App Privacy: draft answers

**Status: draft for owner, clinical and legal review. Not submitted.**

These are draft answers for the Google Play **Data safety** form and the Apple
**App Privacy** label (App Store Connect), derived from the code in this
repository. Every answer cites the code it comes from. Items marked
**Unknown** cannot be answered from the repository and need the owner.
`ios/Runner/PrivacyInfo.xcprivacy` declares the same collected data types.

## What build these answers describe

Release and profile builds run the BreatheFree app with the Heartwise, Steady
and ClearAir programs. The newer multi-program screens (`tether_ui`) run only
in a debug build started with `--dart-define=TETHER_UI=true`
(`lib/app/ui_selection.dart:15-26`, `lib/main.dart:127-141`). So these
answers cover the released features only. Sign in with Apple or Google, health
record import (FHIR, Apple Health, Health Connect), care-team sharing and
Unplug are **not** in release builds and are not declared here. Before they
ship, these answers must be redone.

## Summary of collection

| Data | When | Where it goes | Evidence |
|---|---|---|---|
| Email address, password | Creating an account or signing in (optional; guests skip it) | Supabase Auth | `lib/auth/auth_gateway.dart:129-132` (sign in), `:150-154` (sign up), `:180-184` (password reset email) |
| User ID (account UUID), session tokens | Signed in | Held on the device in the Keychain/Keystore-backed secure store; sent to the API as a bearer token | `lib/auth/auth_gateway.dart:6-16`, `lib/auth/secure_session_storage.dart:9,22-23`, `lib/auth/auth_deep_link.dart:49-56` |
| Display name | Member edits their profile | API `PATCH /v1/profile` | `lib/profile/profile_api_client.dart:41`, `lib/auth/account_controller.dart:110`; limit 80 characters `api/src/profile/profile.dto.ts:12-20` |
| Profile photo | Member picks one (optional) | Private Supabase Storage bucket `avatars`, path `<userId>/avatar` | Gallery only: `lib/widgets/profile_editor_dialog.dart:54-59`; upload: `lib/profile/avatar_storage.dart:26-34`; bucket is private: `supabase/migrations/202609110001_profiles.sql:87-88` |
| Quit plan (BreatheFree): daily cigarette use, triggers, reasons, quit date, readiness, preparation tasks, support-option choices, free-text custom reason and trigger | Signed-in member saves the plan | API `GET`/`PUT /v1/quit-plan`, `POST /v1/quit-plan/guest-import` | `lib/quit_plan/quit_plan.dart:107-123`, `lib/quit_plan/quit_plan_api_client.dart:35-55` |
| Names of support people, their relationship and preferred channel (text or call; no phone numbers) | Signed-in member adds them to the quit plan | API, inside the quit plan | `api/src/quit-plan/quit-plan.dto.ts:78-93` |
| Heartwise: blood pressure (systolic, diastolic, time, note), cholesterol panels | Signed-in member logs them | API `PUT /v1/program-data/heartwise` | `lib/programs/heartwise/models/bp_reading.dart:29-34`, `lib/programs/heartwise/models/cholesterol_panel.dart:41-48`, `lib/programs/program_data_api_client.dart:42,69` |
| Steady: glucose readings (mg/dL, context, time, note), target range | Signed-in member logs them | API `PUT /v1/program-data/steady` | `lib/programs/steady/models/glucose_reading.dart:44-49`, `lib/programs/steady/models/target_range.dart:29-33` |
| ClearAir: action-plan zone, symptom logs, peak flow | Signed-in member logs them | API `PUT /v1/program-data/clearair` | `lib/programs/clearair/models/action_plan.dart:40-44`, `lib/programs/clearair/models/symptom_log.dart:34-39` |

Program data is saved automatically shortly after each change for signed-in
members (`lib/programs/program_navigator.dart:182-218`). Guests make no
network call: their program data and quit plan stay in encrypted storage on
the device (`lib/programs/secure_program_store.dart:40,154-156`,
`lib/quit_plan/guest_quit_plan_store.dart:43-57`).

### Not collected (searched, not found)

- **Location, phone number, date of birth, gender, address, contacts list.**
  No such fields or permissions in `lib/`, `AndroidManifest.xml` or
  `Info.plist`.
- **Analytics, crash reporting, advertising.** No such packages in
  `pubspec.yaml:10-28`. The error reporter only prints the error type in debug
  builds and sends nothing (`lib/error/privacy_safe_error_reporter.dart:14-18`).
  No advertising ID permission and no App Tracking Transparency prompt.
- **Daily check-ins, craving rescues, slip recovery.** These are kept in
  memory only and are not sent (`lib/screens/approved_screen_player.dart`,
  around lines 1166-1222 and 1333-1339). The API has routes for them, but the
  release app does not call them.
- **Health records, Apple Health, Health Connect.** No HealthKit entitlement
  (`ios/Runner/Release.entitlements`), no Health Connect permission, no health
  plugin, no FHIR route in `api/src`.
- **Push or local notifications.** No notification plugin, no `aps-environment`
  entitlement, no `POST_NOTIFICATIONS` permission.

### Permissions

- Android: `INTERNET` only (`android/app/src/main/AndroidManifest.xml:2`);
  backups disabled, `android:allowBackup="false"` (`:6`).
- iOS: photo library usage description only, for the profile photo
  (`ios/Runner/Info.plist:5-6`).

## Security

- **Encrypted in transit: Yes.** Release builds refuse service URLs that are
  not https (`lib/config/app_config.dart:53-54`, `:415-420`), and the release
  build scripts check the same (`tool/release_define_check.sh`). Android blocks
  cleartext by default at the app's target SDK and no
  `usesCleartextTraffic` or network security config is set; iOS App Transport
  Security defaults apply (no `NSAppTransportSecurity` key in `Info.plist`).
- **On the device:** sessions, the guest quit plan and program data are kept in
  `flutter_secure_storage` (iOS Keychain; Android encrypted storage).
- **Server side:** the API requires an https Supabase URL in production
  (`api/src/config/environment.ts:209-217`), verifies tokens against Supabase
  (`api/src/auth/token-verifier.ts:40-48`) and logs no request bodies or IP
  addresses (`api/src/common/privacy-exception.filter.ts:42-54`).

## Deletion and export

- **In the app:** Home, profile avatar, Settings & privacy, Your data, Delete
  account and data. The member re-enters their password and types DELETE
  (`lib/screens/settings_privacy_screen.dart:550`,
  `lib/screens/approved_screen_player.dart:737-760`,
  `lib/widgets/account_data_dialogs.dart`). The app calls
  `DELETE /v1/account/data` (`lib/account/account_data_api_client.dart:106-125`).
- **On the server:** a recent sign-in is required, avatar files are removed,
  then all app data rows and the sign-in identity are deleted in one
  transaction (`api/src/account/account.service.ts:114-181`,
  `supabase/migrations/202610180008_delete_my_account.sql:96-103`).
- **On the device:** local program data, guest plan and language choice are
  wiped (`lib/main.dart:429-448`).
- **Export:** `GET /v1/account/export` after re-entering the password returns
  profile, quit plan and program data, shown as JSON that can be copied
  (`lib/account/account_data_api_client.dart:100-103`,
  `api/src/account/account.service.ts:69-106`).
- **Web deletion URL (Play requires one): not published.** A draft page exists
  in the website repository but is excluded from the build until counsel signs
  off. **Blocker.**

## Google Play: Data safety form (draft answers)

**Does your app collect or share any of the required user data types?** Yes.

**Is all of the user data collected by your app encrypted in transit?** Yes.

**Do you provide a way for users to request that their data is deleted?** Yes:
in the app, and a web URL is required (**blocker**, see above).

**Data shared with third parties:** None. Supabase (authentication, database,
file storage) and Render (API hosting) process data on our behalf as service
providers, which Play does not count as sharing. **Owner to confirm** the
production providers.

| Play category | Data type | Collected | Shared | Optional? | Purpose |
|---|---|---|---|---|---|
| Personal info | Name | Yes | No | Optional | App functionality, Account management |
| Personal info | Email address | Yes | No | Optional (needed only for an account) | App functionality, Account management |
| Personal info | User IDs | Yes | No | Optional (account) | App functionality, Account management |
| Health and fitness | Health info | Yes | No | Optional | App functionality |
| Photos and videos | Photos | Yes | No | Optional | App functionality (profile photo) |
| App activity | Other user-generated content | Yes | No | Optional | App functionality (free-text reasons, triggers, notes, support people's names) |

Everything else (location, financial info, messages, contacts, audio, files,
calendar, app activity other than the above, web browsing, app info and
performance, device or other IDs): **Not collected.**

"Processed ephemerally": No. Data a signed-in member saves is stored until they
delete it.

## Apple App Privacy label (draft answers)

**Do you or your third-party partners collect data from this app?** Yes.

**Tracking:** No. The app does not track users and has no tracking domains
(`NSPrivacyTracking` false in `ios/Runner/PrivacyInfo.xcprivacy`).

| Apple data type | Linked to the user | Used for tracking | Purpose |
|---|---|---|---|
| Contact Info: Email Address | Yes | No | App Functionality |
| Contact Info: Name | Yes | No | App Functionality |
| Identifiers: User ID | Yes | No | App Functionality |
| Health & Fitness: Health | Yes | No | App Functionality |
| User Content: Photos or Videos | Yes | No | App Functionality |
| User Content: Other User Content | Yes | No | App Functionality |

Not collected: location, financial info, sensitive info (other than health),
contacts, browsing or search history, purchases, usage data, diagnostics,
device ID, other data.

## Open questions and unknowns

1. **Production hosts.** Only a development Supabase project and a development
   Render API service appear in `render.yaml:1-21`. The production Supabase
   project, its region and the production API host are not in the repository.
2. **Privacy policy URL.** `https://www.tetherhealthgroup.com/privacy` exists
   but states it covers the website only. An app privacy policy covering health
   and account data must be published before submission (a draft exists in the
   website repository, not built). **Blocker for both stores.**
3. **Web account deletion URL.** Not published (see above). **Blocker for
   Play.**
4. **Email delivery.** Supabase Auth sends confirmation and password-reset
   emails; the production email (SMTP) provider is not in the repository.
5. **Retention.** No retention or backup policy is in the code. Supabase backup
   retention and Render log retention are unknown.
6. **Support people's names.** Declared above as Other User Content. Counsel to
   confirm this is the right category rather than Contacts.
7. **Password.** Handled by Supabase Auth and never stored by the app; neither
   store has a separate password category. Counsel to confirm.
8. **In-app copy that the code does not back yet.** The "anonymous app
   diagnostics", "help improve" research, "share with my care team" and
   "helpful reminders" toggles change in-memory state only
   (`lib/screens/settings_privacy_screen.dart:487-498`,
   `lib/screens/approved_screen_player.dart:113-115`). If any of them starts
   sending data, these answers must change first.
9. **In-app privacy links.** The Settings "Privacy policy, terms and help" row
   still shows a placeholder message (`lib/screens/settings_privacy_screen.dart:633-645`).
10. **Code comment out of date.** `lib/programs/program.dart:4-13` says program
    data stays on the device; for signed-in members it is uploaded (see table).
