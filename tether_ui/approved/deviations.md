# Approved deviations

Approved screens whose `spec/screens/<screen>.json` is allowed to differ from
the owner's snapshot (`manifest.json`). Each one has an owner decision and
the ticket that made the change. `deviations.json` is the machine-readable
copy. It also pins the sha256 of the reviewed content, so any further change
to these screens fails `test/tether_ui/approved_design_parity_test.dart`.

Each entry was checked as a field-by-field JSON diff between the snapshot and
the current file:
- TH-942 rows change string values only. Every changed field is a row of
  `generator/copy_review_TH-942.md` (row numbers below), with the same old and
  new text. Keys, components, actions and line count are unchanged.
- `sf_home` and `sf_screentime` match the "Changed approved screens" table in
  `generator/review_TH-953.md`.
- TH-907 rows change only input attributes. Each changed field either loses
  `value` and gains `placeholder` with the same text (P-31), or a node gains
  or changes only its `key` (TH-902). With those attributes removed, the old
  and new files are equal.
- TH-1001 rows move designer-only text to the screen's `notes`, which are
  not rendered: `crisis` and `catalog` lose one text node from `body`, and
  `sf_intro` loses one sentence from one text value. Each removed text is
  added to `notes` unchanged. Nothing else changes, apart from the later
  action paths that move up by one on `catalog`.
- TH-986a rows add decision-source metadata only: a branch gains `id`,
  `ask` and `when` (TH-902), or the email sign-in branch is wrapped in its
  `POST supabase /auth/v1/token` submit (TH-902; the action summary then
  names the endpoint). With those removed, the old and new files are equal,
  except the one case P-51 adds on `auth_signin_error` (TH-986b).
- TH-907b rows change only a starting state (P-52): on `ob_consent` the
  "Private reminders" toggle's `on` goes from `true` to `false`; on
  `ob_account` the "I’m 18 or older" checklist item loses `"done": true`.
  With that attribute restored, `ob_consent` then equals the snapshot and
  `ob_account` its TH-907 state.
- The TH-907c row (P-68 as amended by P-72) wraps the actions of the four
  sign-up routes on `ob_account` in a branch decided by rule `ob.age`. With
  each branch replaced by its "Age confirmed" action, the file equals its
  TH-907b state, except the four generated action summaries.
- TH-907d rows (P-73) change only actions, and one description. On
  `auth_signin` and `auth_signin_error` the two new-identity outcomes replace
  the sheet with `ob_programs` instead of pushing `auth_social_new`. On
  `auth_social_new`, "Create my account" pushes `ob_programs` without
  submitting first, its `api` list empties
  and its `desc` says it is not routed. With those values restored, each file
  equals its earlier state, except the generated action summaries.
- TH-1008a rows (P-71) add only `bind` to input controls on settings
  screens. With `bind` removed, each file equals its earlier state: no label,
  starting value, layout or action changes.

All replacement copy still needs clinical/legal review before release.

Additions (new screens, not deviations) are in `additions.json`. One of them,
`sf_home_unplug_android` (decision N3, TH-971), has
`"status": "owner prototype check pending"`: the guard allows it, but the
owner has not yet checked it in the prototype.

## P-22: "works offline" copy removed (TH-942)

| Screen | Field | Change | Copy review row |
|---|---|---|---|
| `auth_session` | `body[1].text` | drops "Anything you logged offline is kept and syncs after you sign in." | 13 |
| `bf_home` | `body[1].text` | "One tap · works offline" → "One tap · no typing" | 3 |
| `bf_home_quitday` | `body[3].text` | "One tap · no typing · offline" → "One tap · no typing" | 4 |
| `bf_intro` | `body[2].rows[0][1]` | "one tap, offline" → "one tap, no typing" | 2 |
| `ca_home` | `body[2].text` | "Open it fast, even offline" → "Open it fast" | 8 |
| `ca_red` | `body[4].text` | drops "Works offline." | 9 |
| `checkin` | `footer[1].text` | "Private · works offline · skip anything" → "Skip any program question" | 7 |
| `crisis` | `body[5].text` | drops "Works offline." (the whole line is no longer shown since P-58, below) | 10 |
| `ea_plan` | `desc` | drops "; available offline" (developer description) | 12 |
| `rescue_pick` | `desc` | drops "Works offline." (developer description) | 11 |
| `today` | `body[3].text` | drops " · works offline" | 5 |
| `today_loading` | `body[1].text`, `body[4].text` | "Always available" → "One tap · no typing"; on-device cache note → "The rest of Today is still loading." | 20, 21 |
| `today_offline` | `body[2].text` | "Works offline" → "One tap · no typing" | 6 |
| `welcome` | `body[5].rows[1][1]` | "Works offline" → "No typing needed" | 1 |

## P-08: no "30 days" retention promise (TH-942)

| Screen | Field | Change | Copy review row |
|---|---|---|---|
| `account_leave` | `body[2].items[0].label`, `.sub` | "Keep my data for 30 days" / "Rejoin anytime and pick up where you left off" → "Keep my data" / "Kept until you delete it or delete your account. Rejoin anytime." | 18, 19 |
| `program_settings` | `body[3].rows[1].sub` | "Keep data 30 days or delete now" → "Keep your data or delete it now" | 16 |

## P-47: owner prototype decisions (TH-953)

| Screen | Decision | Change |
|---|---|---|
| `sf_home` | P-47 decision 1 | New Unplug entry card between the Urge card and Today's step: "Want firmer limits?" / "Unplug can pause apps you choose, after limits you set. Optional." with **Set up** → `sf_unplug_intro`. One new action; the later action paths move from `body[3]` to `body[4]`. Nothing else changes. |
| `sf_screentime` | P-47 decision 3 | iPhone copy says Apple's Screen Time "shows" the totals instead of Tether "reading" them: `body[1].text`, `body[2].text`, and the row `body[3].rows[0]` ("Reads: Minutes per category" → "Shows: Minutes per category, on this phone"). Layout and actions are unchanged. |

## P-58: designer notes are not shown to members (TH-1001)

A designer annotation that the approved design rendered as body text no
longer renders in the app. Its text moves to the screen's `notes` in the
spec, so the design intent is kept. The other elements and their action
paths are unchanged.

| Screen | Field | Change |
|---|---|---|
| `crisis` | `body[5]` (text, small) | "Shown whenever someone chooses “thoughts of harming myself” or types similar words anywhere. 988 is US-only; localize per region." is removed from `body` and kept in `notes`. Also P-22 (TH-942). |

The same decision covers `surface_shortcuts_android`: "Shown when someone
long-presses the Tether icon." (`body[0]`, muted text) is removed from `body`
and kept in `notes`. The two shortcut rows move from `body[1]` to `body[0]`.
That screen is an addition (`additions.json`, TH-953), not one of the
approved screens in `manifest.json`, so it has no entry in
`deviations.json`; the parity test accepts deviation entries for approved
screens only.

## P-62: other designer notes are not shown to members (TH-1001)

The same treatment as P-58: designer-only text no longer renders, and each
removed text is kept unchanged in the screen's `notes` in the spec.

| Screen | Field | Change |
|---|---|---|
| `catalog` | `body[1]` (text, muted) | "Mirrors tetherhealthgroup.com. Status shows what’s available today." is removed from `body` and kept in `notes`. The program lists move from `body[2]`, `body[3]` to `body[1]`, `body[2]`, so their action paths move up by one. |
| `sf_intro` | `body[3].text` | Drops the last sentence, "Never called “addiction”.", which is kept in `notes`. The rest of the text is unchanged: "Notice what pulls you in, set a goal that feels doable, and pause for 60 seconds when the urge hits." |

P-62 also changes these additions (`additions.json` lists P-62 and TH-1001
on each). They are not approved screens, so they have no entry in
`deviations.json`. The removed text is kept in each screen's `notes`.

- `surface_widget_ios`, `surface_widget_android`: the header pill
  "Reference", the eyebrow "Home screen · small widget" / "Home screen ·
  2×1 widget" and the key-value rows (Label, Shows, Tap, and Data or Built
  with) are removed. The header and the Rescue card stay; the card moves
  from `body[1]` to `body[0]`.
- `surface_shortcuts_ios`, `surface_shortcuts_ios_named`: the header pill
  "Reference" and the first text ("What people see in the Shortcuts app and
  Spotlight, and can say to Siri." / "With Show sensitive details on
  (Account → Notifications), shortcuts use program names.") are removed.
  The shortcut rows move from `body[1]` to `body[0]`; their subtitles stay.
- `surface_shortcuts_android`, `surface_shortcuts_android_named`: the header
  pill "Reference" and the row subtitles ("Static shortcut · always there",
  "Dynamic shortcut · only while ClearAir is a focus program", "Dynamic
  shortcut") are removed. On the named variant the first text ("With Show
  sensitive details on …") is removed too, and its rows move from `body[1]`
  to `body[0]`.
- `sf_unplug_picker_ios`: the native-view caption "System sheet drawn by
  iOS (FamilyActivityPicker). Tether can’t style it or read the app names."
  is removed. The native view and its label stay.

## P-31: example values become placeholders (TH-907)

Each listed field no longer starts with a value. The same text is now its
`placeholder`, shown as hint text, and the field writes nothing until the
member types. The field's look changes from entered text to hint text; layout,
copy, keys and actions are unchanged.

| Screen | Fields (`path` label: example) |
|---|---|
| `account_delete` | `body[4]` Type DELETE to confirm: "DELETE"; `body[5]` Password: "••••••••••••". |
| `auth_forgot` | `body[2]` Email: "alex@example.com". |
| `auth_link` | `body[3]` Password: "••••••••••••". |
| `auth_newpass` | `body[1]` New password: "••••••••••••"; `body[2]` Confirm password: "••••••••••••". |
| `auth_signin` | `body[3]` Email: "alex@example.com"; `body[4]` Password: "••••••••". |
| `auth_signin_error` | `body[4]` Email: "alex@example.com"; `body[5]` Password: "••••••••". |
| `be_q2` | `body[3]` Relative’s age at diagnosis (if known): "44". |
| `bf_meds_edit` | `body[1]` Medicine: "Nicotine patch"; `body[2]` Strength: "21 mg / 24 h"; `body[3]` When: "Every morning". |
| `ca_plan` | `body[3].children[0]` Peak flow from: "400"; `body[3].children[1]` Daily medicine: "Controller inhaler · 2 puffs AM/PM"; `body[4].children[0]` Peak flow: "200–399"; `body[5].children[0]` Below: "200". |
| `ca_zone` | `body[1]` Peak flow (optional): "310". |
| `ck_done` | `body[0]` What: "Flu vaccine"; `body[1]` Date: "Oct 12, 2026"; `body[2]` Where (optional): "Main St Pharmacy". |
| `ck_q1` | `body[2]` Age: "52". |
| `ea_plan` | `body[2]` My warning signs: "Not sleeping, pulling away from friends"; `body[3]` Things that help me: "Walk the dog, shower, music"; `body[4]` People I can reach: "Sam · (555) 010-3311". Also P-22 (TH-942). |
| `hw_lipids` | `body[2].fields[0]` Total: "212"; `body[2].fields[1]` LDL: "138"; `body[3].fields[0]` HDL: "46"; `body[4]` Lab date: "Sep 30, 2026". |
| `hw_log` | `body[1].fields[0]` Top (systolic): "138"; `body[1].fields[1]` Bottom (diastolic): "86"; `body[2]` Pulse (optional): "72". |
| `hw_log2` | `body[2].fields[0]` Top (systolic): "132"; `body[2].fields[1]` Bottom (diastolic): "84"; `body[3]` Pulse (optional): "70". |
| `hw_log_error` | `body[1].fields[0]` Top (systolic): "128"; `body[1].fields[1]` Bottom (diastolic): "310". |
| `hw_targets` | `body[2].fields[0]` Top below: "130"; `body[2].fields[1]` Bottom below: "80". |
| `ob_account` | `body[5]` Email: "alex@example.com"; `body[6]` Password: "••••••••••••". Also TH-902 (key, below) and P-52 (starts unticked, below). |
| `ob_basics` | `body[3]` What should we call you?: "Alex"; `body[4]` Age range: "35–44". |
| `re_labs` | `body[0]` eGFR: "58"; `body[1]` Urine ACR: "42"; `body[3]` Lab date: "Oct 3, 2026". |
| `records_fhir_url` | `body[1]` FHIR server address: "https://fhir.example-health.org/r4". |
| `records_manual` | `body[2]` Test: "A1C"; `body[3]` Value: "7.4"; `body[4]` Date: "Oct 1, 2026". |
| `records_manual_error` | `body[1]` Test: "A1C"; `body[2]` Value: "74"; `body[3]` Date: "Oct 1, 2026". |
| `records_search` | `body[0]` Search: "Patel" (dropped: the field keeps its own placeholder). |
| `sd_caregiver` | `body[1]` Name: "Rosa"; `body[2]` Phone: "(555) 010-2244". Also TH-902 (key, below). |
| `sf_buddy` | `body[2]` Name: "Sam". Also TH-902 (key, below). |
| `st_a1c` | `body[1]` A1C: "7.4"; `body[2]` Lab date: "Oct 1, 2026". |
| `st_log` | `body[0]` Reading: "142"; `body[3]` Note (optional): "Pasta lunch". |
| `st_range` | `body[3].fields[0]` Before meals from: "80"; `body[3].fields[1]` to: "130"; `body[4]` 2 h after meals below: "180"; `body[5].children[0]` Low below: "70"; `body[5].children[1]` My low steps: "15 g fast sugar, re-check in 15 min". |
| `support_add_person` | `body[1]` Name: "Jordan"; `body[2]` Phone: "(555) 010-4421"; `body[4]` Help phrase: "Can you stay with me for the next 10 minutes?". |
| `support_callback` | `body[3]` Best time to call: "Weekdays after 5 PM". |
| `support_connect` | `body[1]` Invite code: "PATEL-4821". |
| `support_message_care` | `body[1]` Topic: "Question about my plan"; `body[2]` Message: "I’ve been feeling dizzy in the mornings since starting the patch.". |

## TH-902: session keys only, no visual change (TH-907)

Stable keys for inputs the API reads (decision TH-902, the owner's approval of
the ARCH-TH-902 design). The consent checklists and the program picker get a
key so their state reaches the session. The `program_settings` care-team
toggle had a key made from the example clinic name; it now uses the same key
as `program_settings_sf`. Checklist and tile on/off states are unchanged by
this change. The "I’m 18 or older" item on `ob_account`, ticked here, starts
unticked since P-52 (below).

| Screen | Node | Change |
|---|---|---|
| `ob_account` | `body[7]` (checklist) | gets key `age_18_or_older`. Also P-31 (above) and P-52 (below). |
| `ob_programs` | `body[3]` (tiles) | gets key `programs`. |
| `program_settings` | `body[2].children[0]` (toggle) | key `care_team_dr_patel_s_clinic` → `care_team_sharing`. Also P-08 (TH-942). |
| `records_consent` | `body[2]` (checklist) | gets key `resources`. |
| `records_consent_bb` | `body[2]` (checklist) | gets key `resources`. |
| `records_consent_device` | `body[2]` (checklist) | gets key `data_types`. |
| `sd_caregiver` | `body[3]` (checklist) | gets key `caregiver_can_see`. Also P-31 (above). |
| `sf_buddy` | `body[3]` (checklist) | gets key `buddy_can_see`. Also P-31 (above). |

## TH-902: decision sources, no visual change (TH-986a)

Every branch has exactly one production decision source (`spec/branches.json`).
The branches that had none get one without any visible change: a device
answer keyed by a stable id (`id`, `ask`, and `when`, which maps each answer
to an existing case), or, for email sign-in, the server outcome of a
`POST supabase /auth/v1/token` submit (the endpoint `auth_signin` already
lists in its `api`; the `api` list of `auth_signin_error` stays empty, so the
approved JSON keeps its other fields). Labels, targets, copy and layout are
unchanged.

| Screen | Node | Change |
|---|---|---|
| `auth_signin` | `footer[0]` "Sign in" | branch "Sign-in result" is wrapped in submit `POST supabase /auth/v1/token`. Also P-31 (TH-907) and P-73 (TH-907d). |
| `auth_signin_error` | `footer[0]` "Try again" | branch "Sign-in result" is wrapped in submit `POST supabase /auth/v1/token`. Also P-51 (below), P-31 (TH-907) and P-73 (TH-907d). |
| `ob_reminders` | `footer[0]` "Turn on reminders" | id `onboarding.reminders.notifications_request`, ask `notificationsRequest`: granted → Allowed; denied, unavailable → Not allowed. |
| `records_consent` | `footer[0]` "Continue to MyChart" | id `records.connect.mychart`, ask `smartConnect`: approved → Approved; cancelled → Cancelled; failed → Denied or error. Also TH-902 key (TH-907). |
| `records_consent_bb` | `footer[0]` "Continue to Medicare.gov" | id `records.connect.medicare`, ask `smartConnect`: as above. Also TH-902 key (TH-907). |
| `records_consent_device` | `footer[0]` "Continue" | id `records.device.health_records_request`, ask `healthRecordsRequest`: granted → Allowed; denied, unavailable → Not allowed. Also TH-902 key (TH-907). |
| `records_fhir_url` | `footer[0]` "Check and continue" | id `records.fhir_url.server_check`, ask `fhirServerCheck`: supported → SMART on FHIR R4 supported; unsupported → Not a FHIR R4 server. Also P-31 (TH-907). |
| `sf_screentime` | `footer[0]` "Allow access" | id `sf.screentime.ios_request`, ask `screenTimeRequest`: granted → Allowed; denied, unavailable → Not allowed. Also P-47 decision 3 (TH-953). |

The same metadata is added to these additions (`additions.json`, not
hash-pinned, so they have no entry in `deviations.json`): `sf_screentime_android`,
`sf_unplug_intro`, `sf_unplug_auth`, `sf_unplug_auth_denied`,
`sf_unplug_auth_notifications` (two branches), `sf_unplug_auth_android`,
`sf_unplug_home`, `sf_unplug_health_notifications`, `sf_unplug_health_stopped`,
and, as preview-only reference branches (ask `reference`), `sf_unplug_picker_ios`
and `sf_unplug_shield`.

## P-51: the sign-in retry offers the guest-plan case (TH-986b)

| Screen | Node | Change |
|---|---|---|
| `auth_signin_error` | `footer[0]` "Try again", branch "Sign-in result" | gains the case "Success · guest plan on phone" → push `auth_merge`, the same case and target as "Sign in" on `auth_signin`. No visible element changes. |

## P-52: optional consent and age attestation start unticked (TH-907b)

A choice the member makes starts off, so the member makes it: a pre-ticked
consent is not freely given. The label, copy, keys, layout and actions are
unchanged; only the starting state differs. Until the member changes it,
the session holds `false` for the toggle and an empty list for the
checklist.

| Screen | Node | Change |
|---|---|---|
| `ob_consent` | `body[4].children[0]` (toggle "Private reminders", key `private_reminders`) | `on`: `true` → `false`. "Agree and continue" still submits and opens `ob_basics` with it off; it is optional. "Essential app data" (required) stays on. |
| `ob_account` | `body[7]` (checklist "I’m 18 or older", key `age_18_or_older`) | the item no longer starts ticked (`"done": true` removed). Since P-68 / P-72 (below), no sign-up route proceeds until the member ticks it. Also P-31 and TH-902 (above). |

## P-72: sign-up asks for "I’m 18 or older" first (TH-907c)

P-68 requires the age item before any sign-up route proceeds. P-72 amends how:
the routes keep their normal look, and tapping one while the item is unticked
shows a short message and goes nowhere. Each route's action is wrapped in a
branch decided by the on-device rule `ob.age` (`spec/rules.json`: confirmed
when "I’m 18 or older" is ticked). "Age confirmed" runs the action exactly as
before; "Age not confirmed" shows the toast below, which screen readers
announce. The rule decides before anything else runs, so an unticked
"Create account" sends no `POST supabase /auth/v1/signup` and an unticked
Apple or Google button never starts native sign-in. No visible element, label
or layout changes.

Draft message, needs clinical/legal copy review: "You need to be 18 or
older to continue." No existing spec copy states the age requirement; the
wording follows the checklist label.

| Screen | Node | Change |
|---|---|---|
| `ob_account` | `body[2].items[0]` "Continue with Apple" | the "Sign in with Apple result" branch is wrapped in an `ob.age` branch. |
| `ob_account` | `body[2].items[1]` "Continue with Google" | the "Sign in with Google result" branch is wrapped in an `ob.age` branch. |
| `ob_account` | `footer[0]` "Create account" | the `POST supabase /auth/v1/signup` submit is wrapped in an `ob.age` branch. |
| `ob_account` | `footer[1]` "Continue on this phone only" | the reset to `today` is wrapped in an `ob.age` branch. |

## P-73: new Apple and Google accounts go through the normal sign-up (TH-907d)

On "I already have an account", an Apple ID or Google account that has no
Tether account now enters the normal sign-up at its start, `ob_programs`, the
screen welcome "Get started" opens. The member chooses programmes and gives
consent as every new member does, and the account is created on `ob_account`,
which asks for "I’m 18 or older" first (P-72), not on `auth_social_new`. The
sign-in sheet is replaced by `ob_programs`, as other sheets that lead into a
flow are (`rescue_pick`, `focus_full`, `checkin`). Outcome labels are
unchanged. No visible element, label or layout changes.

`auth_social_new` is no longer opened from any screen. Removing an approved
screen needs an owner snapshot change, so it stays in the spec as the approved
design and is listed in `spec/app.json` as a reference entry point (the
validator requires every screen to be reachable from one). Its "Create my
account" opens `ob_programs` and submits nothing, so the screen cannot create
an account even if it is opened. `POST supabase /auth/v1/token?grant_type=id_token`
is no longer a screen submit and leaves `spec/endpoints.json` and the app's
endpoint registry; native Apple and Google sign-in still use it inside the
sign-in adapter.

| Screen | Node | Change |
|---|---|---|
| `auth_signin` | `body[1].items[0]` "Continue with Apple" | outcome "New Apple ID, no Tether account": push `auth_social_new` → replace with `ob_programs`. Also P-31 (TH-907) and TH-902 (TH-986a). |
| `auth_signin` | `body[1].items[1]` "Continue with Google" | outcome "New Google account, no Tether account": push `auth_social_new` → replace with `ob_programs`. |
| `auth_signin_error` | `body[2].items[0]` "Continue with Apple" | outcome "New Apple ID, no Tether account": push `auth_social_new` → replace with `ob_programs`. Also P-31 (TH-907), TH-902 (TH-986a) and P-51 (TH-986b). |
| `auth_signin_error` | `body[2].items[1]` "Continue with Google" | outcome "New Google account, no Tether account": push `auth_social_new` → replace with `ob_programs`. |
| `auth_social_new` | `footer[0]` "Create my account" | submit `POST supabase /auth/v1/token?grant_type=id_token` then push `ob_programs` → push `ob_programs` (no submit). `api`: that endpoint → empty. `desc` says the screen is not routed. |

The other sign-in steps were checked for the same route. "Try again" on
`auth_social_error`, Google on `account_signin_methods`, and Apple or Google on
`auth_session_apple`, `auth_session_google`, `account_delete_apple` and
`account_delete_google` only sign in, link or re-confirm an existing account:
none has an outcome that creates one, and the sign-in adapter contract
(`TAuth`) says so. `POST supabase /auth/v1/signup` is submitted only from
`ob_account`, after the age check.

The age-gate checks fail closed. `tether_ui/flutter/test/sign_up_age_route_test.dart`
and the validator carry the same two tables and walk every route from every
screen. A submit to `supabase /auth/` counts as creating an account unless it
is listed as one that does not (recover, the password token, setting a new
password, linking an identity), and each account-creating submit must sit
inside "Age confirmed" on its own screen. Every native sign-in branch outside
"Age confirmed" must match a pinned list of branches and their exact outcome
labels. A new-identity outcome must enter the normal sign-up at `ob_programs`.

## P-71: settings controls start from the member's stored state (TH-1008a)

The owner kept the designed starting states on the sharing screens (P-71)
on the condition that a settings screen shows the member's stored state and
never submits a starting value. Each input control on a settings screen now
names the data key of that stored state (`bind`). This changes data only: in
the preview and in screenshots the controls show the designed starting value,
as before. `program_settings_sf` gains the same keys as `program_settings`;
it is an addition, which has no sha256 pin. `:program` stands for the
programme the screen was opened for.

| Screen | Field | `bind` |
|---|---|---|
| `account_notifications` | `body[0].children[0]` toggle, `body[0].children[1]` toggle, `body[0].children[2]` toggle | `notifications.check_ins_and_plan_reminders`, `notifications.show_sensitive_details`, `notifications.quiet_hours` |
| `account_privacy` | `body[0].children[0]` toggle, `body[0].children[1]` toggle, `body[0].children[2]` toggle | `consents.cross_program_insights`, `consents.de_identified_research`, `consents.anonymous_app_diagnostics` |
| `be_q2` | `body[2]` chips | `be.profile.family_cancers` |
| `bf_meds_edit` | `body[1]` field, `body[3]` field, `body[4]` toggle | `bf.meds.medicine`, `bf.meds.when`, `bf.meds.private_reminder` |
| `ck_q1` | `body[3]` segmented, `body[4]` chips | `ck.profile.sex_assigned_at_birth`, `ck.profile.any_of_these` |
| `hw_targets` | `body[3]` radio, `body[4]` chips | `hw.targets.no_target_yet`, `hw.targets.reminder_time` |
| `nu_habit` | `body[1]` radio, `body[2].children[0]` toggle | `nu.habit.habit`, `nu.habit.track_weight` |
| `program_settings` | `body[1]` radio, `body[2].children[0]` toggle, `body[2].children[1]` toggle | `enrolment.:program.status`, `enrolment.:program.care_team_sharing`, `enrolment.:program.de_identified_research` |
| `sd_caregiver` | `body[3]` checklist | `sd.caregiver.can_see` |
| `sf_buddy` | `body[3]` checklist | `sf.buddy.can_see` |
| `st_range` | `body[2]` segmented | `st.range.unit` |

In the app a bound control shows the stored value. While the value is not
loaded it shows its empty state (off, nothing selected) and writes nothing.
When the member has nothing stored, controls on the sharing and
notification screens (`account_notifications`, `account_privacy`,
`program_settings`, `program_settings_sf`, `sd_caregiver`, `sf_buddy`) stay
off, and plan and
profile screens show their designed starting value. That comes from the
shared input components, not from `spec/screens`.

## Rendering changes with no spec change (TH-907)

These come from the shared field component, not from `spec/screens`, so the
sha256 guard cannot see them. They follow from P-31 (fields start empty).

- **Units on empty fields.** A field's unit (mmHg, mg/dL, L/min, %) stays
  visible while the field is empty. Before, Flutter showed the unit only next
  to a value. This shows new units on two optional fields that the approved
  design left empty: `hw_lipids` Triglycerides "mg/dL" and `re_labs` ALT
  (liver) "U/L". Rendering change, no spec change; it matches the base
  prototype, which always shows units.
- **Large text.** With text enlarged, the unit grows at most to 150%, and a
  hint beside a unit may use a second line, so a typed value or a hint is
  never cut. At 100% text, a field with a typed value renders exactly as in
  the approved design.
- **Validation report.** For this change, `validation/` was regenerated from
  the Flutter test run only. The prototype column still comes from the
  earlier browser run, before TH-907, and was not re-run in a browser.
