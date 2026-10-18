# TH-953 — spec additions for owner review (H32, P-47)

This is internal traceability for the reviewers. It lives in `generator/`
and is not part of the shipped app. The generated spec, prototype and Flutter
code carry no office IDs. Their notes say only "Proposal for owner review.
Copy needs clinical/legal review."

Source: `screens_additions.py`. No approved screen changed. Each change to an
existing screen is a new state of it.

## How the owner reviews it

Open `tether_ui/prototype/index.html` in a browser.
- Two new flows in the sidebar: **ScrollFree · Unplug (proposal)** and
  **Home screen, Siri & shortcuts (proposal)**.
- New states of existing screens appear under **States** in the right panel,
  on ScrollFree home, Weekly reflection, Connect Screen Time, Program
  settings, Delete account, Session expired and Update required.
- The iPhone / Android selector switches between the platform variants.
- The **Simulator** tab has 6 Unplug scenarios: strict-session reason,
  sentence step, sum step, and Rescue from the overlay, the shield and the
  firm shield.

## New screens (44)

| ID | Name | Route | Flow | Kind / state | Serves |
|---|---|---|---|---|---|
| `sf_unplug_intro` | Unplug intro | `/p/sf/unplug` | ScrollFree · Unplug (proposal) | screen | P-30, B.4 |
| `sf_unplug_auth` | Allow Screen Time | `/p/sf/unplug/permission` | ScrollFree · Unplug (proposal) | screen | P-30, B.4 |
| `sf_unplug_auth_denied` | Screen Time not allowed | `/p/sf/unplug/permission?state=denied` | ScrollFree · Unplug (proposal) | permission denied of `sf_unplug_auth` | P-30, B.4 |
| `sf_unplug_auth_unavailable` | Screen Time unavailable | `/p/sf/unplug/permission?state=unavailable` | ScrollFree · Unplug (proposal) | unavailable of `sf_unplug_auth` | P-30, B.4 |
| `sf_unplug_auth_android` | Android permissions for Unplug | `/p/sf/unplug/permission?state=android` | ScrollFree · Unplug (proposal) | android of `sf_unplug_auth` | P-30, B.4 |
| `sf_unplug_apps` | Choose apps | `/p/sf/unplug/apps` | ScrollFree · Unplug (proposal) | screen | P-30, B.4 item 1 |
| `sf_unplug_picker_ios` | Apple app picker | `/p/sf/unplug/apps/picker` | ScrollFree · Unplug (proposal) | sheet | P-30, B.4 item 1 |
| `sf_unplug_apps_android` | Choose apps (Android) | `/p/sf/unplug/apps?state=android` | ScrollFree · Unplug (proposal) | android of `sf_unplug_apps` | P-30, B.4 item 1, TH-969 |
| `sf_unplug_apps_chosen` | Name your groups | `/p/sf/unplug/apps?state=chosen` | ScrollFree · Unplug (proposal) | apps chosen of `sf_unplug_apps` | P-30, B.4 item 1 |
| `sf_unplug_limits` | Limits & pause screen | `/p/sf/unplug/limits` | ScrollFree · Unplug (proposal) | screen | P-30, B.4 items 2-3 |
| `sf_unplug_home` | Unplug | `/p/sf/unplug/home` | ScrollFree · Unplug (proposal) | screen | P-30, B.4 item 8 |
| `sf_unplug_session` | Start a focus session | `/p/sf/unplug/session` | ScrollFree · Unplug (proposal) | screen | P-30, B.4 item 4 |
| `sf_unplug_session_active` | Focus session running | `/p/sf/unplug/session/active` | ScrollFree · Unplug (proposal) | fullscreen | P-30, B.4 item 4 |
| `sf_unplug_session_end` | End session early | `/p/sf/unplug/session/end` | ScrollFree · Unplug (proposal) | sheet | P-30, B.4 item 4 |
| `sf_unplug_session_done` | Session complete | `/p/sf/unplug/session/done` | ScrollFree · Unplug (proposal) | screen | P-30, B.4 item 4 |
| `sf_unplug_session_done_early` | Session ended early | `/p/sf/unplug/session/done?state=early` | ScrollFree · Unplug (proposal) | ended early of `sf_unplug_session_done` | P-30, B.4 item 4 |
| `sf_unplug_shield` | Pause screen (iPhone shield) | `/system/unplug/shield` | ScrollFree · Unplug (proposal) | fullscreen | P-30, B.4 item 5 |
| `sf_unplug_shield_firm` | Pause screen (iPhone shield, firm) | `/system/unplug/shield?state=firm` | ScrollFree · Unplug (proposal) | no “open anyway” left of `sf_unplug_shield` | P-30, B.4 item 5 |
| `sf_unplug_overlay` | Pause screen (Android overlay) | `/system/unplug/overlay` | ScrollFree · Unplug (proposal) | fullscreen | P-30, B.4 item 6, TH-969 |
| `sf_unplug_gate` | Small step: one breath | `/p/sf/unplug/step` | ScrollFree · Unplug (proposal) | fullscreen | P-30, B.4 item 2 |
| `sf_unplug_gate_commit` | Small step: type a sentence | `/p/sf/unplug/step?state=sentence` | ScrollFree · Unplug (proposal) | typed sentence of `sf_unplug_gate` | P-30, B.4 item 2 |
| `sf_unplug_gate_sum` | Small step: quick sum | `/p/sf/unplug/step?state=sum` | ScrollFree · Unplug (proposal) | quick sum of `sf_unplug_gate` | P-30, B.4 item 2 |
| `sf_unplug_health` | Tracking check | `/p/sf/unplug/health` | ScrollFree · Unplug (proposal) | screen | P-30, B.4 item 7 |
| `sf_unplug_health_stopped` | Tracking stopped | `/p/sf/unplug/health?state=stopped` | ScrollFree · Unplug (proposal) | tracking stopped of `sf_unplug_health` | P-30, B.4 item 7 |
| `sf_unplug_health_android` | Tracking check (Android) | `/p/sf/unplug/health?state=android` | ScrollFree · Unplug (proposal) | android of `sf_unplug_health` | P-30, B.4 item 7 |
| `sf_unplug_off` | Turn off Unplug | `/p/sf/unplug/off` | ScrollFree · Unplug (proposal) | sheet | P-30, B.4 item 8 |
| `sf_home_unplug_offer` | ScrollFree home · Unplug offer | `/p/sf/home?state=unplug-offer` | ScrollFree | Unplug not set up (proposal) of `sf_home` | P-30 |
| `sf_home_unplug` | ScrollFree home · Unplug on (iPhone) | `/p/sf/home?state=unplug` | ScrollFree | Unplug on · iPhone (proposal) of `sf_home` | P-30, B.4 item 9, B.4 |
| `sf_week_unplug` | Weekly reflection · Unplug on (iPhone) | `/p/sf/week?state=unplug` | ScrollFree | Unplug on · iPhone (proposal) of `sf_week` | P-30, B.4 item 9 |
| `program_settings_sf` | Program settings · ScrollFree with Unplug | `/p/:program/settings?state=sf-unplug` | Plans & programs | ScrollFree with Unplug (proposal) of `program_settings` | P-30, B.4 item 8 |
| `sf_screentime_report` | Connect Screen Time · iPhone report wording | `/p/sf/screen-time?state=ios-report` | ScrollFree | iPhone report wording (proposal) of `sf_screentime` | P-30, B.4 |
| `account_delete_apple` | Delete account · Apple account | `/account/delete?state=apple` | Account & data | Apple account of `account_delete` | P-36, TH-935 |
| `account_delete_google` | Delete account · Google account | `/account/delete?state=google` | Account & data | Google account of `account_delete` | P-36, TH-935 |
| `auth_session_apple` | Session expired · Apple account | `/auth/session?state=apple` | Account & sign-in | Apple account of `auth_session` | P-36, TH-935 |
| `auth_session_google` | Session expired · Google account | `/auth/session?state=google` | Account & sign-in | Google account of `auth_session` | P-36, TH-935 |
| `sf_screentime_android` | Connect usage access (Android) | `/p/sf/screen-time?state=android` | ScrollFree | android of `sf_screentime` | P-36 |
| `sf_screentime_android_denied` | Usage access off (Android) | `/p/sf/screen-time?state=android-denied` | ScrollFree | android · not allowed of `sf_screentime` | P-36 |
| `sys_update_android` | Update required (Android) | `/system/update?state=android` | System states | android of `sys_update` | P-36 |
| `surface_widget_ios` | Home-screen widget (iPhone) | `/surface/widget/ios` | Home screen, Siri & shortcuts (proposal) | fullscreen | P-32, P-48, B.5 |
| `surface_widget_android` | Home-screen widget (Android) | `/surface/widget/android` | Home screen, Siri & shortcuts (proposal) | fullscreen | P-32, P-48, B.5 |
| `surface_shortcuts_ios` | Siri & App Shortcuts (iPhone) | `/surface/shortcuts/ios` | Home screen, Siri & shortcuts (proposal) | screen | P-32, P-48, B.5 |
| `surface_shortcuts_ios_named` | Siri & App Shortcuts (sensitive details on) | `/surface/shortcuts/ios?state=named` | Home screen, Siri & shortcuts (proposal) | Show sensitive details on of `surface_shortcuts_ios` | P-48 |
| `surface_shortcuts_android` | Launcher shortcuts (Android) | `/surface/shortcuts/android` | Home screen, Siri & shortcuts (proposal) | screen | P-32, P-48, B.5 |
| `surface_shortcuts_android_named` | Launcher shortcuts (sensitive details on) | `/surface/shortcuts/android?state=named` | Home screen, Siri & shortcuts (proposal) | Show sensitive details on of `surface_shortcuts_android` | P-48 |

## Safety requirements (th-qa round 1: Q1–Q3, Q8)

- **Every pause surface reaches Rescue, and Rescue reaches Emergency (988 / 911).**
  - `sf_unplug_overlay`: a Get support button opens Rescue. It is always
    shown on Android.
  - `sf_unplug_shield_firm`: Apple allows a second shield button. Here it
    is Get support, which posts a local notification that opens Rescue.
  - `sf_unplug_shield`: Take a breath posts a notification with two
    actions. Get support opens Rescue without the small step; Take my
    breath opens the small step.
  - `sf_unplug_gate*`: a Get support card opens Rescue without doing the
    step.
  - The shield → notification → Tether hand-off needs device validation
    (H39).
- **Never paused.** Tether, the phone dialer and emergency calling can never
  be chosen or paused.
  - User-visible copy on `sf_unplug_intro`, `sf_unplug_apps`,
    `sf_unplug_apps_android`, `sf_unplug_limits` and `sf_unplug_session`.
  - A "Native requirement" note for the native shield, picker, overlay and
    service tickets (TH-968, TH-969).
  - On iOS, whether Apple's picker can select the Phone app or Tether itself
    is unverified (H39). If it can, the native layer must exclude them.
- **The gates are real** (rules in `spec/rules.json`, the same logic in the
  app and the prototype, covered by scenarios):
  - `sf.unplug.reason`: End session on a strict session needs a reason chip
    or a typed note.
  - `sf.unplug.sentence`: "Open it for 10 minutes" needs the sentence typed
    in full. Case, extra spaces and a final full stop are ignored.
  - `sf.unplug.sum`: "Open it for 10 minutes" needs the right answer.

## Decisions the owner makes in this review

1. **Where Unplug starts.** Proposed: an optional card on ScrollFree home
   (`sf_home_unplug_offer`) and a row in ScrollFree settings
   (`program_settings_sf`). Choosing this changes the approved `sf_home`.
2. **"Not a lock"** (`sf_intro`, `sf_pause`). Proposed: keep it. Pause 60
   stays an intent check, and Unplug is the separate optional lock.
3. **"Reads" vs "shows"** (`sf_screentime`). Either adopt
   `sf_screentime_report`, or legal accepts "reads".
4. **Native minutes slot on iPhone** (`sf_home_unplug`, `sf_week_unplug`).
   If rejected, the iPhone copy must be reworded instead. Figures Tether
   stores on iPhone are labelled as the person's own estimate.
5. **Group names stay on the phone** (`sf_unplug_apps_chosen`).
6. **Looser limits start tomorrow** (`sf_unplug_limits`).
7. **Never paused: Tether, the phone dialer and emergency calling.** This is
   a spec requirement (see Safety).
8. **Shield hand-off via local notification**, with Get support as an action
   (needs H39).
9. **"Get support" on every pause surface**, including the second button of
   the firm iPhone shield.
10. **Shortcut label "My plan"** for the ClearAir red-zone plan. Program
    names appear only with Show sensitive details on (`*_named`). P-48.
11. **Reference surfaces** (widget, shield, overlay, shortcuts) are not app
    routes. Decide whether TH-952 checks them with the H39 screenshot
    checklist.

## Copy for clinical/legal review

All visible text on the 44 screens. Text that is new in wording:
- `sf_unplug_*`: every string, including the Get support card and button,
  the never-paused sentences, and the gate and strict-session messages.
- `sf_home_unplug_offer`: the "Want firmer limits?" card.
- `sf_home_unplug`, `sf_week_unplug`: "your estimate" / "Your estimates"
  and the native slot caption.
- `sf_screentime_report`: the title, body and "Shows" row.
- `sf_screentime_android(_denied)`: the Settings steps and the banner.
- `program_settings_sf`: the Screen Time & Unplug rows.
- `account_delete_apple|google`: the "Confirm it's you" card and the toasts.
- `auth_session_apple|google`: the provider line and the Cancelled toast.
- `sys_update_android`: the Play URL. The base `sys_update` App Store URL
  has no real App Store ID yet.
- `surface_*`: the labels, Siri phrases and widget text.

## Generator changes outside `screens_additions.py`

- `validate.py` `load()`: 2 lines. Import and call
  `screens_additions.additions()`.
- `render_html.py`: +1 line, the `nativeslot` placeholder.
- `gen_dart.py`: +1 line, `nativeslot` becomes `TNativeSlot`.
- `build_all.py`: +1 line in `COMPONENTS`.
- `dart_static/lib/ui/components.dart`: `TNativeSlot` appended.
- Round 1: `proto_v2.py` +3 lines (prototype `RULES` entries
  `sf.unplug.reason`, `sf.unplug.sentence`, `sf.unplug.sum`).
- Round 1: `dart_static/lib/logic/rules.dart` +10 lines (2 constants and 3
  `case`s, same logic).
- The rule specs and the 6 scenarios are registered from
  `screens_additions.py` into `rules.RULES` / `rules.SCENARIOS`, so
  `rules.py` is unchanged.

This file is in `generator/` because `build_all.py` rewrites `spec/` on
every run.
