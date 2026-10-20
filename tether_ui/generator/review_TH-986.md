# TH-986a / TH-986b — a production decision source for every branch (R-31, P-51)

These are internal traceability notes for reviewers. The file sits in
`generator/` and is not part of the shipped app.

Rule (R-31): every branch has exactly one production decision source:

| Source | Declared by | Decided by |
|---|---|---|
| `rule` | `decide='<rule id>'` | `TRules.decide` on the session values |
| `choice` | `decide='choice:<screen>.<key>'` (visible radio, chips, zone) | the member's selection |
| `server` | no decider; the branch sits directly under a submit (only toasts between) | the `TResult.outcome(label)` that submit returns |
| `auth` | `provider='apple' \| 'google'` | `TAuth.signIn` |
| `device` | `id`, `ask`, `when` | `TDevice.ask` (answer → case through `when`) |
| `reference` | `id`, `ask='reference'` | preview only, on reference surfaces (`reference: true`) |

Order in `TNav.branch`: forced (tests) → rule / choice → server outcome →
simulation queue → `TAuth` → `TDevice` → resolver. The resolver fails closed
in release builds and receives `''` as the question there
(`TNav.redactQuestion`). A late `TAuth`, `TDevice` or resolver answer acts
only while the screen that asked is still the top route.

`spec/branches.json` lists all 49 branches with screen, path, source,
labels and, for device branches, id, ask and when. It never carries question
text. Counts: rule 9, choice 8, auth 12, device 16, server 2, reference 2.

## R-7 mapping (device and reference branches)

Ids follow `^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2}$` and are chosen by hand,
never derived from the screen or the element path.

| Screen · element | id | ask | when (answer → case) |
|---|---|---|---|
| `ob_reminders` · `footer[0]` | `onboarding.reminders.notifications_request` | `notificationsRequest` | granted → Allowed; denied, unavailable → Not allowed |
| `records_fhir_url` · `footer[0]` | `records.fhir_url.server_check` | `fhirServerCheck` (address in session key `records_fhir_url.base_url`; HTTPS only; a transport failure is no answer, never "Not a FHIR R4 server") | supported → SMART on FHIR R4 supported; unsupported → Not a FHIR R4 server |
| `records_consent` · `footer[0]` | `records.connect.mychart` | `smartConnect` | approved → Approved; cancelled → Cancelled; failed → Denied or error |
| `records_consent_bb` · `footer[0]` | `records.connect.medicare` | `smartConnect` | approved → Approved; cancelled → Cancelled; failed → Denied or error |
| `records_consent_device` · `footer[0]` | `records.device.health_records_request` | `healthRecordsRequest` | granted → Allowed; denied, unavailable → Not allowed |
| `sf_screentime` · `footer[0]` | `sf.screentime.ios_request` | `screenTimeRequest` | granted → Allowed; denied, unavailable → Not allowed |
| `sf_screentime_android` · `footer[0]` | `sf.screentime.android_usage_access` | `usageAccessSettings` | granted → Allowed; denied → Not allowed |
| `sf_unplug_intro` · `footer[0]` | `unplug.intro.platform` | `platform` | ios → iPhone; android → Android |
| `sf_unplug_home` · `body[2].rows[2]` | `unplug.home.preview_platform` | `platform` | ios → iPhone; android → Android |
| `sf_unplug_auth_notifications` · `footer[2]` | `unplug.setup.continue_platform` | `platform` | ios → iPhone; android → Android |
| `sf_unplug_auth` · `footer[0]` | `unplug.setup.ios_authorization` | `unplugAuthIos` | granted → Approved; grantedNotificationsOff → Approved · notifications off; denied → Denied; unavailable → Unavailable |
| `sf_unplug_auth_denied` · `footer[0]` | `unplug.setup.ios_authorization_retry` | `unplugAuthIos` | granted, grantedNotificationsOff → Approved; denied, unavailable → Denied |
| `sf_unplug_auth_notifications` · `footer[1]` | `unplug.setup.notifications_check` | `notificationsCheck` | granted → per platform {ios: On (iPhone), android: On (Android)}; denied → Still off |
| `sf_unplug_auth_android` · `footer[2]` | `unplug.setup.android_check` | `unplugAndroidCheck` | allOn → All on; notificationsOff → Notifications off; missing → Missing |
| `sf_unplug_health_notifications` · `footer[1]` | `unplug.health.notifications_check` | `notificationsCheck` | granted → On; denied → Still off |
| `sf_unplug_health_stopped` · `footer[1]` | `unplug.health.tracking_check` | `unplugTrackingCheck` | healthy → All pass; failing → Still failing |
| `sf_unplug_picker_ios` · `footer[0]` | `unplug.picker.ios` | `reference` | — (preview only) |
| `sf_unplug_shield` · `footer[0]` then | `unplug.shield.notification_action` | `reference` | — (preview only) |

The answer sets are `dsl.ASKS`, mirrored by `TAsk` / `TAnswer` in
`dart_static/lib/ui/nav.dart`. A per-platform `when` value is resolved with a
second `TDevice` question (`TAsk.platform`, same id). No answer, an answer
outside the ask, an unmapped answer or a throwing `TDevice` decides nothing:
the resolver runs. Release default `TInertDevice` never answers and records
`device_not_configured`; preview default `PreviewDevice` never answers, so
the preview chooser runs as before. While a device branch is being decided,
another activation of the same branch on the same screen is ignored.

## Email sign-in (R-1) and non-queueable auth submits (R-6)

`auth_signin` and `auth_signin_error` footer "Sign in" / "Try again" are
`submit('POST supabase /auth/v1/token', branch('Sign-in result', …))`
(ARCH-TH-902 §2.1). The adapter returns `TResult.outcome(label)` on success,
"Wrong password" only for invalid credentials, and `TFailed(code)` otherwise;
a plain `TOk` decides nothing and fails closed in release.

P-51 (TH-986b): the `auth_signin_error` retry gains "Success · guest plan on
phone" → push `auth_merge`, the same case as normal sign-in.

`dsl.NOT_QUEUEABLE` (emitted to `spec/endpoints.json`): the six
`supabase /auth/` endpoints. Their generated submits pass `queueable: false`:
a `TQueued` result counts as `failed('not_queueable')`, and every failure
shows `TFailClosedResolver.message` instead of the save error.

## Validator checks (`validate.py`, self-tests in `validate._self_test`)

| Check | Rule |
|---|---|
| V1 | Each branch has exactly one source: at most one of `decide`, `provider`, `ask`/`id`; with none, it must sit directly under a submit. |
| V2 | Device and reference branches have an id in the format above, unique across the spec. |
| V3 | `ask` is known; `when` is total over the ask's answers, has no other answers, maps only to case labels, reaches every case, and a per-platform value has exactly ios and android; reference branches have no `when`; no `when` without an ask. |
| V4 | A branch with no decider under a submit sits directly under it (toasts only); an auth, device or reference branch never sits directly under a submit. |
| V5 | `ask='reference'` only on reference surfaces. |
| V6 | `dsl.ASKS` equals the kit's `TAsk`/`TAnswer`; every `supabase /auth/` submit endpoint is in `dsl.NOT_QUEUEABLE` and every entry is used; `spec/branches.json` and `spec/endpoints.json` match `spec/screens.json` and carry no question text (run by `build_all.py` after writing, and by `python3 validate.py`). |

## Changed approved screens

Eight approved screens change spec JSON only by the metadata above (and the
P-51 case); `approved/deviations.json` / `deviations.md` record each with
decision TH-902 (and P-51 for `auth_signin_error`). No screen renders
differently.
