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
- TH-1008c rows (P-78, P-79) change starting selections, add session keys to
  the `records_review` checklists, and wrap each screen's primary action in a
  branch decided by a "chosen" rule. With the starting selections and keys
  restored and each branch replaced by its "Chosen" action, each file equals
  its earlier state, except the `records_review` button label and toast and
  the generated action summaries.

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

## P-78 / P-79: consent-creating selections start unselected (TH-1008c)

P-78: a selection that creates a consent, share or import starts unselected,
so the screen shows exactly what will be sent. P-79: on `records_review`
each item's keep/skip choice reaches `POST /v1/records/fhir/accept`, and only
kept items are added. Each screen's primary action is wrapped in a branch
decided by an on-device "chosen" rule (`spec/rules.json`; chosen when any of
the screen's own selection keys holds a selection), built the way the
sign-up age check is (P-72): "Chosen" runs the action exactly as before;
"Nothing chosen" shows a short message and sends nothing. The kit has no
disabled-until-selected button, so the buttons keep their normal look.

`records_conflict` has no owner decision of its own. It follows P-78 (no
option starts chosen) until the owner decides otherwise; a conflict left
unanswered is sent as null.

Draft wording, all needing clinical/legal copy review (kept together in
`generator/screens_shared.py`, `SELECTION_COPY`):

- "Select at least one program." (`support_add_person`)
- "Select at least one item to continue." (`records_consent`,
  `records_consent_bb`, `records_consent_device`)
- "Select the items you want to add." (`records_review`)
- "Add selected items to my programs" (`records_review` button, was "Add 21
  items to my programs") and "Added to your programs" (its toast, was "Added
  to Heartwise, Steady, Checkup, BreatheFree and Renew"): the count and the
  programme list would no longer match what is sent.
- "Choose an option for at least one item." (`records_conflict`)

| Screen | Node | Change |
|---|---|---|
| `support_add_person` | `body[3]` chips "Which programs?" (key `which_programs`) | "BreatheFree" no longer starts selected. Also P-31 (TH-907). |
| `support_add_person` | `footer[0]` "Save supporter" | the `POST /v1/care/supporters` submit is wrapped in a `sup.programs` branch. |
| `records_consent` | `body[2]` checklist "What Tether will read" (key `resources`) | Conditions, Vital signs, Lab results, Medications, Immunizations and Smoking status no longer start ticked. Also TH-902 (TH-907, TH-986a). |
| `records_consent` | `footer[0]` "Continue to MyChart" | the MyChart sign-in branch (`records.connect.mychart`) is wrapped in a `rec.consent.epic` branch. |
| `records_consent_bb` | `body[2]` checklist "What Tether will read" (key `resources`) | as `records_consent`. |
| `records_consent_bb` | `footer[0]` "Continue to Medicare.gov" | the Medicare sign-in branch (`records.connect.medicare`) is wrapped in a `rec.consent.medicare` branch. |
| `records_consent_device` | `body[2]` checklist "What Tether will ask for" (key `data_types`) | Blood pressure, Blood glucose and Clinical records (iPhone) no longer start ticked. |
| `records_consent_device` | `footer[0]` "Continue" | the permission branch (`records.device.health_records_request`) is wrapped in a `rec.consent.device` branch. |
| `records_review` | `body[3]`–`body[7]` card checklists | get keys `keep_hw`, `keep_st`, `keep_ck`, `keep_bf`, `keep_re`; no item starts ticked (A1C 7.6% already did not). |
| `records_review` | `footer[0]` | label and toast as above; the `POST /v1/records/fhir/accept` submit is wrapped in a `rec.review` branch. |
| `records_conflict` | `body[0].children[0]` radio `a1c`, `body[1].children[0]` radio `bp` | `selected` 0 and 1 → -1 (no option chosen). |
| `records_conflict` | `footer[0]` "Save choices" | the `POST /v1/records/fhir/conflicts` submit is wrapped in a `rec.conflict` branch. |

`records_source` "What we read" opened `records_consent`, which then showed
no category ticked rather than the connected source's categories; TH-1008d
(below) replaces it.

## As P-78: "Not requested" items and "What we read" (TH-1008d)

An item marked "Not requested" could be ticked: it counted as a selection
for the screen's "chosen" rule and was sent with the selection. It is now a
read-only list row (the kit's list row with no action) right below the
checklist, so it cannot be ticked, never counts for the rule and is never
sent. `validate.py` fails any selectable item (checklist, radio, chip or
selection tile) labelled or marked "Not requested".

`records_source` no longer opens the consent checklist from "What we read":
that checklist starts unticked (P-78) and under-reported what the source
reads. The screen lists the six categories the source reads as read-only
rows under "What we read", matching its "Read-only · 6 categories". They are
the consent checklist's categories and subtitles, from one list in
`generator/screens_records.py`. No new wording.

| Screen | Node | Change |
|---|---|---|
| `records_consent` | `body[2]` checklist "What Tether will read" (key `resources`), new `body[3]` | "Clinical notes" ("Not requested") leaves the checklist and becomes a flat read-only list row at `body[3]`; the card moves to `body[4]`. |
| `records_consent_bb` | `body[2]` checklist, new `body[3]` | as `records_consent`. |
| `records_consent_device` | `body[2]` checklist "What Tether will ask for" (key `data_types`), new `body[3]` | "Steps and sleep" ("Not requested") leaves the checklist and becomes a flat read-only list row at `body[3]`. |
| `records_source` | `body[1]` list, new `body[2]` | the "What we read" row (push to `records_consent`) is removed; a new list titled "What we read" shows Conditions, Vital signs, Lab results, Medications, Immunizations and Smoking status as rows with no action. |

## P-80: the language choice stores the language code (TH-1014c)

The app offers English and Spanish (P-80). The welcome language selector's
options get stable values, so the stored choice is the language code, not
the label shown: the labels stay "English" and "Español", each written in
its own language and never translated. Nothing visible changes.

| Screen | Node | Change |
|---|---|---|
| `welcome` | `body[0]` segmented "English" / "Español" (key `value`) | gains `values` `["en", "es"]`; the starting selection "English" now stores `en`. |

Translated text is not part of `spec/screens`: the generator keys every
member-visible string by screen, element path and property, and writes the
keys only to `spec/l10n/en.arb` and the generated Dart. So adding or
changing a translation never changes a screen file or its sha256.

## P-89: member values are bound; examples carry an "Example" tag (TH-909)

The design's example values (a blood pressure of 128/82, "Good morning,
Alex.", a quit date of Aug 28) are member data. Each one now names the TData
key of the member's value: the element gains `data`, a map from the bound
property to its key. This changes data only: no label, starting value,
layout or action in `spec/screens` changes, and in the preview, the
prototype and the screenshots every screen looks exactly as before.

In the app (from the shared kit, not from `spec/screens`, so the sha256
guard cannot see it): a bound element shows the member's value when there
is one. Without one (not loaded, or loaded with no value) it shows the
design's example with a small "Example" tag: after a text or a number, or
above the top trailing corner of a card, chart, list, stat grid or banner,
one tag per card. Screen readers read "Example" before the value. The
preview answer shows no tag. Bound values are never written to the session,
so an example never reaches a payload or a decision rule.

What is bound, and what stays static copy, is set out in
`generator/bindings.py`, which also pins each example value. Every bound
value is listed, with its key, type, kind and example, in
`spec/bindings.json` for the app to fill. Examples that could read as
clinical advice are listed for the clinical lead in
`spec/review_TH-909.md`. "Example" is the owner's word; its Spanish needs
translation (kit string `kit.example`).

| Screen | Bound property and key |
|---|---|
| `account` | `body[0].rows[0].label` `profile.name`; `body[0].rows[0].sub` `profile.email`; `body[1].rows[0].sub` `records.sources_summary`; `body[1].rows[1].sub` `account.signin_methods_summary`; `body[2].rows[0].sub` `account.programs_summary`; `body[2].rows[1].sub` `notifications.summary`; `body[2].rows[2].sub` `consents.reviewed_summary` |
| `account_delete` | `body[1].rows[0][1]` `account.data.programs`; `body[1].rows[1][1]` `account.data.check_ins`; `body[1].rows[2][1]` `account.data.readings`; `body[1].rows[3][1]` `account.data.shared_summaries` |
| `account_deleted` | `body[2].rows[0][1]` `account.deletion.receipt`; `body[2].rows[1][1]` `account.deletion.completed_at` |
| `account_notifications` | `body[1].rows[0].sub` `notifications.bf.summary`; `body[1].rows[1].sub` `notifications.sf.summary` |
| `account_privacy` | `body[1].rows[1].sub` `consents.history_summary` |
| `account_programs` | `body[0].text` `account.focus_slots`; `body[1].rows[0].sub` `enrolment.bf.summary`; `body[1].rows[1].sub` `enrolment.sf.summary`; `body[1].rows[2].sub` `enrolment.ca.summary`; `body[1].rows[3].sub` `enrolment.hw.summary` |
| `auth_merge` | `body[2].rows[0].sub` `auth.merge.guest_plan`; `body[3].text` `auth.merge.account_plan` |
| `auth_social_new` | `body[3].rows[0][1]` `auth.social.name` |
| `be_survivor` | `body[3].rows[0][1]` `be.next_follow_up` |
| `be_tx` | `body[0].title` `be.next_appointment` |
| `bf_estimates` | `body[1].rows[0][1]` `bf.estimates.baseline`; `body[1].rows[1][1]` `bf.estimates.price`; `body[1].rows[2][1]` `bf.estimates.time_per_cigarette` |
| `bf_home` | `body[0].children[0].value` `bf.days_to_quit_day`; `body[0].children[0].caption` `bf.quit_date_caption`; `body[3].children[0].text` `bf.top_reason`; `body[4].rows[1].sub` `bf.meds.summary`; `body[4].rows[2].sub` `bf.saved_summary` |
| `bf_home_quitday` | `body[0].text` `bf.quit_day_heading`; `body[2].children[0].value` `bf.time_since_quit`; `body[2].children[0].caption` `bf.quit_time_caption`; `body[6].rows[1].sub` `bf.meds.today_summary` |
| `bf_meds` | `body[1].title` `bf.meds.recorded_plan` |
| `bf_progress` | `body[1].values` `bf.cigarettes_week`; `body[2].items[0].value` `bf.avoided`; `body[2].items[1].value` `bf.saved`; `body[2].items[1].sub` `bf.price_per_pack`; `body[2].items[2].value` `bf.cravings_eased`; `body[2].items[3].value` `bf.most_helpful_tool`; `body[2].items[3].sub` `bf.most_helpful_count`; `body[3].rows[0].sub` `bf.estimates_summary` |
| `bf_review` | `body[2].rows[0].sub` `bf.review.approach`; `body[2].rows[1].sub` `bf.review.quit_date`; `body[2].rows[2].sub` `bf.review.top_reason`; `body[2].rows[3].sub` `bf.review.support`; `body[2].rows[4].sub` `bf.review.space` |
| `bf_slip` | `body[2].rows[0][1]` `bf.smoke_free_days` |
| `bf_stepdown` | `body[1].text` `bf.stepdown.baseline_line`; `body[2].rows[0][1]` `bf.stepdown.week_1`; `body[2].rows[1][1]` `bf.stepdown.week_2`; `body[2].rows[2][1]` `bf.stepdown.week_3`; `body[2].rows[3][1]` `bf.stepdown.week_4`; `body[2].rows[4][0]` `bf.stepdown.quit_day_label` |
| `bf_support` | `body[1].rows[0].label` `bf.supporter_name`; `body[1].rows[0].sub` `bf.supporter_detail` |
| `ca_home` | `body[0].title` `ca.zone_today`; `body[0].text` `ca.zone_checked`; `body[3].rows[1].sub` `ca.zone_counts`; `body[3].rows[2].sub` `ca.plan_entered` |
| `ca_progress` | `body[0].values` `ca.peak_flow_series`; `body[1].items[0].value` `ca.days_green`; `body[1].items[1].value` `ca.days_yellow`; `body[1].items[2].value` `ca.days_red`; `body[2].title` `ca.top_symptom` |
| `ca_red` | `body[3].rows[0].label` `ca.emergency_contact_action` |
| `ca_yellow` | `body[0].text` `ca.plan_entered_line` |
| `ca_zone` | `body[5].text` `ca.zone_thresholds_line` |
| `checkin_done` | `body[1].text` `checkin.thanks` |
| `ck_day` | `body[0].text` `ck.appointment_title` |
| `ck_list` | `body[0].text` `ck.due_summary` |
| `ck_uptodate` | `body[2].text` `ck.next_due_line` |
| `crisis` | `body[4].title` `ea.plan.things_that_help_line`; `body[4].text` `ea.plan.reach_out_line` |
| `ea_home` | `body[1].rows[0].sub` `ea.plan_updated`; `body[1].rows[1].sub` `ea.check_back_due` |
| `hw_crisis` | `body[0].text` `hw.crisis_banner` |
| `hw_home` | `body[0].eyebrow` `hw.last_reading_time`; `body[0].children[0].value` `hw.last_bp`; `body[0].children[0].caption` `hw.last_bp_caption`; `body[2].rows[0].sub` `hw.avg_30d_summary`; `body[2].rows[1].sub` `hw.lipids_summary`; `body[2].rows[3].sub` `hw.records_summary`; `body[2].rows[4].sub` `hw.targets_summary` |
| `hw_log2` | `body[4].rows[0][1]` `hw.log.reading_1`; `body[4].rows[1][1]` `hw.log.average` |
| `hw_result` | `body[1].text` `hw.result_title`; `body[2].text` `hw.result_text` |
| `hw_summary` | `body[0].text` `hw.summary.title`; `body[1].rows[0][1]` `hw.summary.dates`; `body[1].rows[1][1]` `hw.summary.bp_average`; `body[1].rows[2][1]` `hw.summary.highest`; `body[1].rows[3][1]` `hw.summary.latest_panel` |
| `hw_trends` | `body[1].values` `hw.systolic_series`; `body[2].items[0].value` `hw.avg_30d`; `body[2].items[1].value` `hw.readings_30d`; `body[2].items[1].sub` `hw.days_missed_30d` |
| `nu_home` | `body[0].eyebrow` `nu.habit_week`; `body[0].title` `nu.habit_name`; `body[0].text` `nu.habit_progress`; `body[3].rows[1].sub` `nu.milestone_due` |
| `nu_week4` | `body[2].rows[0][1]` `nu.habits_tried`; `body[2].rows[1][1]` `nu.days_done`; `body[2].rows[2][1]` `nu.favorite_habit` |
| `plans` | `body[0].title` `plans.focus_heading`; `body[0].rows[0].sub` `bf.plan_summary`; `body[0].rows[1].sub` `sf.plan_summary`; `body[2].rows[0].sub` `plans.medication_summary` |
| `program_settings` | `body[0].rows[0].sub` `enrolment.:program.since` |
| `progress` | `body[2].values` `bf.cigarettes_week`; `body[2].caption` `bf.progress_caption`; `body[3].values` `sf.minutes_week`; `body[3].caption` `sf.progress_caption`; `body[4].title` `insights.cross_program` |
| `re_history` | `body[0].values` `re.egfr_series`; `body[1].rows[0][1]` `re.egfr_latest_summary`; `body[1].rows[1][1]` `re.acr_latest`; `body[1].rows[2][1]` `re.next_check` |
| `re_home` | `body[0].eyebrow` `re.egfr_latest_date`; `body[0].children[0].value` `re.egfr_latest`; `body[0].children[0].caption` `re.next_check_caption`; `body[2].rows[1].sub` `re.history_span` |
| `records_conflict` | `body[0].eyebrow` `records.conflict_1.heading`; `body[1].eyebrow` `records.conflict_2.heading`; `body[1].title` `records.conflict_2.title` |
| `records_consent` | `body[0].text` `records.connect_title` |
| `records_disconnect` | `body[0].text` `records.disconnect_title` |
| `records_hub` | `body[1].rows[0].label` `records.source_1.name`; `body[1].rows[0].sub` `records.source_1.status`; `body[1].rows[1].label` `records.source_2.name`; `body[1].rows[1].sub` `records.source_2.status`; `body[2].rows[0].sub` `records.imported.blood_pressure`; `body[2].rows[1].sub` `records.imported.labs`; `body[2].rows[2].sub` `records.imported.immunizations`; `body[2].rows[3].sub` `records.imported.smoking_status`; `body[3].title` `records.review_count` |
| `records_item` | `body[0].values` `records.item.series`; `body[1].rows[0].label` `records.item.latest_1`; `body[1].rows[0].sub` `records.item.latest_1_source`; `body[1].rows[1].label` `records.item.latest_2`; `body[1].rows[1].sub` `records.item.latest_2_source`; `body[1].rows[2].label` `records.item.latest_3`; `body[1].rows[2].sub` `records.item.latest_3_source` |
| `records_review` | `body[2].text` `records.review_banner`; `body[9].rows[0][1]` `records.review.units_converted`; `body[9].rows[1][1]` `records.review.duplicates_skipped`; `body[9].rows[2][1]` `records.review.held_as_typo`; `body[9].rows[3][1]` `records.review.future_dates_rejected` |
| `records_source` | `body[0].rows[0][1]` `records.source.connection`; `body[0].rows[1][1]` `records.source.last_sync`; `body[0].rows[2][1]` `records.source.next_sync`; `body[0].rows[3][1]` `records.source.access`; `body[0].rows[4][1]` `records.source.connected_on` |
| `rescue_escalate` | `body[3].rows[0].label` `support.contact_text_action`; `body[3].rows[0].sub` `support.help_phrase_short` |
| `rescue_pick` | `body[4].eyebrow` `rescue.last_helpful_result`; `body[4].title` `rescue.last_helpful_tool` |
| `rescue_result` | `body[2].items[0].value` `rescue.rating_before`; `body[2].items[1].value` `rescue.rating_now` |
| `sd_fell` | `body[2].rows[0].label` `sd.caregiver_call_action` |
| `sd_home` | `body[0].eyebrow` `sd.today_heading`; `body[0].title` `sd.today_session`; `body[2].rows[0].sub` `sd.safety_progress`; `body[2].rows[1].sub` `sd.caregiver_summary`; `body[2].rows[2].sub` `sd.plan_summary`; `body[3].items[0].value` `sd.sessions_this_week`; `body[3].items[1].value` `sd.falls_30d` |
| `sd_plan` | `body[1].rows[0][0]` `sd.plan.day_1`; `body[1].rows[0][1]` `sd.plan.session_1`; `body[1].rows[1][0]` `sd.plan.day_2`; `body[1].rows[1][1]` `sd.plan.session_2`; `body[1].rows[2][0]` `sd.plan.day_3`; `body[1].rows[2][1]` `sd.plan.session_3` |
| `sd_safety` | `body[2].text` `sd.safety_progress` |
| `sf_buddy` | `body[4].children[0].text` `sf.buddy.preview_message` |
| `sf_goal` | `body[1].text` `sf.baseline_line` |
| `sf_home` | `body[0].children[0].value` `sf.minutes_yesterday`; `body[0].children[0].caption` `sf.goal_caption`; `body[4].rows[0].sub` `sf.phone_free_nights_summary`; `body[4].rows[2].sub` `sf.goal_summary`; `body[4].rows[3].sub` `sf.buddy.summary` |
| `sf_week` | `body[1].values` `sf.minutes_week`; `body[2].items[0].value` `sf.phone_free_nights`; `body[2].items[1].value` `sf.urges_paused`; `body[2].items[1].sub` `sf.urges_put_down`; `body[3].text` `sf.insight`; `body[3].children[0].text` `sf.you_said`; `body[4].title` `sf.next_week_suggestion` |
| `st_a1c` | `body[3].rows[0][1]` `st.a1c_previous`; `body[3].rows[1][1]` `st.a1c_change` |
| `st_home` | `body[0].eyebrow` `st.last_reading_context`; `body[0].children[0].value` `st.last_glucose`; `body[0].children[0].caption` `st.last_glucose_caption`; `body[2].rows[1].sub` `st.in_range_summary`; `body[2].rows[2].sub` `st.a1c_latest` |
| `st_low` | `body[0].text` `st.low_banner` |
| `st_patterns` | `body[1].values` `st.after_meal_series`; `body[2].items[0].value` `st.in_range`; `body[2].items[0].sub` `st.in_range_count`; `body[2].items[1].value` `st.lows`; `body[2].items[1].sub` `st.last_low`; `body[3].title` `st.pattern_insight` |
| `support` | `body[1].rows[0].label` `support.supporter_name`; `body[2].rows[0].label` `support.care_team_name`; `body[2].rows[0].sub` `support.care_team_programs` |
| `support_message` | `body[0].text` `support.message_title`; `body[1].title` `support.help_phrase_quoted` |
| `today` | `body[0].text` `today.date`; `body[1].text` `today.greeting`; `body[4].eyebrow` `today.steps_heading`; `body[6].items[0].value` `bf.days_to_quit_day`; `body[6].items[0].sub` `bf.quit_date_short`; `body[6].items[1].value` `sf.minutes_yesterday`; `body[6].items[1].sub` `sf.goal_short` |
| `today_empty` | `body[0].text` `today.greeting` |
| `today_offline` | `body[0].text` `today.offline_banner`; `body[1].text` `today.greeting` |
| `today_safety` | `body[1].text` `hw.crisis_reading_source` |

The same keys are added to these additions (`additions.json` lists P-89 and
TH-909 on each; they are not hash-pinned): `account_delete_apple`, `account_delete_google`, `program_settings_sf`, `sf_home_unplug`, `sf_home_unplug_android`, `sf_unplug_apps_chosen`, `sf_unplug_home`, `sf_unplug_session_done`, `sf_unplug_session_done_early`, `sf_week_unplug`.

Not bound, for the app lane: header titles (`support_message_care`,
`records_source`, `sf_week`, `sf_week_unplug`), header and row avatars,
input controls and their labels, the structure of member-specific lists,
running timers and breathing rings, and the `bf_date` picker card.

## P-88: "Add as Learn only" creates the enrolment (TH-1031f)

On the 11 programme intros (`bf_intro`, `sf_intro`, `ca_intro`, `hw_intro`,
`st_intro`, `re_intro`, `nu_intro`, `sd_intro`, `ea_intro`, `ck_intro`,
`be_intro`), `footer[1]` "Add as Learn only" was a toast and a tab that
saved nothing. It now submits `POST /v1/enrolments`, which is never queued,
and the same toast and tab follow a successful save only. A failed save
shows the generic error and stays on the intro. Each intro's `api` lists the
endpoint. Label, layout and the other actions are unchanged. The
`focus_full` "Learn only" option and `ob_third` still save nothing.

## P-31 / P-78: the programmes start unselected (TH-1031h)

| Screen | Node | Change |
|---|---|---|
| `ob_programs` | `body[3]` tiles (key `programs`) | BreatheFree and ScrollFree no longer start selected; nothing does. Also TH-902 (TH-907). |

The member's choice becomes enrolments and consents, so nothing is chosen
for them. The footer label "Continue with 2 programs" no longer matched a
starting selection; it now follows the number chosen (next section).

## P-85: quit date, age range and program count are captured (TH-1031h)

Screens that showed a choice the app never recorded. In the preview and the
prototype each screen looks as designed; the changes below are what the app
does with them.

| Screen | Node | Change |
|---|---|---|
| `bf_date` | `body[2]` (calendar) | gets key `quit_date` and `ym` `2026-08` (the design's month). In the app it is a real month calendar: it opens on the current month, has previous and next month, a tap chooses a day, each day has an accessible label (weekday, month, day, year), and the chosen day is the session value `bf_date.quit_date` as `yyyy-MM-dd`. Days run from tomorrow to 90 days ahead (the earlier app's range); the 7th to 14th day ahead is marked recommended, as the screen's "7–14 days away" says. With preview data it draws the design (August 2026, the 28th) and writes that day to the session, as other controls write their starting values. |
| `bf_date` | `body[3]` (card) | gets `follows` `quit_date`: in the app it shows the chosen date and the days left to prepare, and nothing until a day is chosen (the design's "Friday, August 28, 2026" and "Pacific Time" are an example, not the member's date). Unchanged in the preview. |
| `bf_date` | `footer[0]` "Confirm this date" | gets `needs` `quit_date`: disabled until a day is chosen. |
| `ob_basics` | `body[4]` Age range | gets `options` and `values`: the member picks a decade band from a list (P-74); the session holds the band (`18_24` … `75_plus`). The name and the sleep and stress bands already wrote their keys (`ob_basics.what_should_we_call_you`, `ob_basics.sleep_on_a_typical_night`, `ob_basics.usual_stress`). |
| `ob_programs` | `footer[0]` "Continue with 2 programs" | gets `needs` `programs`, `countLabel` ("Continue with 1 program", "Continue with N programs") and `emptyLabel` ("Choose at least one program"): the label follows the number chosen and the button is disabled with none. The scenarios and journeys choose two programs before tapping it. |

## Kit messages with no spec change (TH-1030, TH-909)

- **Failed saves (P-85, P-88).** "Couldn’t save. Your entry is kept on this
  phone." is removed: nothing kept the entry. Every failed save now shows
  the kit's existing generic error, "Something went wrong. Please try
  again." A save the app's outbox keeps (queued) continues the flow with no
  message. Safety screens still open before the save is awaited.
- **"Example" tag (P-89).** New kit string `kit.example`, "Example", as
  described above.
- **Environment badge (TH-1031h).** `TEnvironment.badge` (null by default) is
  set by the app shell. When it has text, every screen and sheet shows it as a
  small pill at the top trailing edge, read by screen readers as
  "Environment: <text>"; with no badge nothing is drawn. The kit never chooses
  the text. New kit strings: `kit.environment`, the calendar's month and
  weekday names, title, previous and next month, recommended day and
  full-date format, and `kit.days_to_prepare`.

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
