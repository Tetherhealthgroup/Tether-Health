# TH-953 — spec additions for owner review (H32 / P-47)

Source of these screens: `screens_additions.py` (this folder). Everything is a
**proposal**. No approved screen was changed. A change to an existing screen is
shown as a new **state** of that screen, so you can compare the current and the
proposed versions side by side.

**All new copy needs clinical/legal review before it ships (HEALTH_DATA #8).**
Every new screen says so in its description (prototype inspector panel) and in
`notes` in `spec/screens/<id>.json`. The copy makes no medical or efficacy
claims.

## How to review in the prototype

Open `tether_ui/prototype/index.html` in a browser.
- New flows in the left sidebar: **ScrollFree · Unplug (TH-953 proposal)** and
  **Home screen, Siri & shortcuts (TH-953 proposal)**.
- New states of existing screens show in the right panel under **States**.
  Open the base screen from the sidebar, then click the state chip. You will
  find them on ScrollFree home, Weekly reflection, Connect Screen Time,
  Program settings, Delete account, Session expired and Update required.
- Use the iPhone / Android selector to see the Apple and Google buttons swap.

## New screens (44)

| ID | Name | Route | Flow | Kind / state | Serves |
|---|---|---|---|---|---|
| `sf_unplug_intro` | Unplug intro | `/p/sf/unplug` | ScrollFree · Unplug (TH-953 proposal) | screen | P-30 · B.4 (what Unplug can and cannot see; screen A "What this can see") |
| `sf_unplug_auth` | Allow Screen Time | `/p/sf/unplug/permission` | ScrollFree · Unplug (TH-953 proposal) | screen | P-30 · B.4 permission states |
| `sf_unplug_auth_denied` | Screen Time not allowed | `/p/sf/unplug/permission?state=denied` | ScrollFree · Unplug (TH-953 proposal) | permission denied of `sf_unplug_auth` | P-30 · B.4 permission states |
| `sf_unplug_auth_unavailable` | Screen Time unavailable | `/p/sf/unplug/permission?state=unavailable` | ScrollFree · Unplug (TH-953 proposal) | unavailable of `sf_unplug_auth` | P-30 · B.4 permission states |
| `sf_unplug_auth_android` | Android permissions for Unplug | `/p/sf/unplug/permission?state=android` | ScrollFree · Unplug (TH-953 proposal) | android of `sf_unplug_auth` | P-30 · B.4 permission states (Android) |
| `sf_unplug_apps` | Choose apps | `/p/sf/unplug/apps` | ScrollFree · Unplug (TH-953 proposal) | screen | P-30 · B.4 item 1 (app selection host) |
| `sf_unplug_picker_ios` | Apple app picker | `/p/sf/unplug/apps/picker` | ScrollFree · Unplug (TH-953 proposal) | sheet | P-30 · B.4 item 1, TNativeSlot |
| `sf_unplug_apps_android` | Choose apps (Android) | `/p/sf/unplug/apps?state=android` | ScrollFree · Unplug (TH-953 proposal) | android of `sf_unplug_apps` | P-30 · B.4 item 1 (Android picker; TH-969 layout must match) |
| `sf_unplug_apps_chosen` | Name your groups | `/p/sf/unplug/apps?state=chosen` | ScrollFree · Unplug (TH-953 proposal) | apps chosen of `sf_unplug_apps` | P-30 · B.4 item 1 |
| `sf_unplug_limits` | Limits & pause screen | `/p/sf/unplug/limits` | ScrollFree · Unplug (TH-953 proposal) | screen | P-30 · B.4 items 2-3 (shield/effort-gate configuration, thresholds) |
| `sf_unplug_home` | Unplug | `/p/sf/unplug/home` | ScrollFree · Unplug (TH-953 proposal) | screen | P-30 · B.4 item 8 (Unplug settings) |
| `sf_unplug_session` | Start a focus session | `/p/sf/unplug/session` | ScrollFree · Unplug (TH-953 proposal) | screen | P-30 · B.4 item 4 (session start) |
| `sf_unplug_session_active` | Focus session running | `/p/sf/unplug/session/active` | ScrollFree · Unplug (TH-953 proposal) | fullscreen | P-30 · B.4 item 4 (active session) |
| `sf_unplug_session_end` | End session early | `/p/sf/unplug/session/end` | ScrollFree · Unplug (TH-953 proposal) | sheet | P-30 · B.4 item 4 (end with override reason) |
| `sf_unplug_session_done` | Session complete | `/p/sf/unplug/session/done` | ScrollFree · Unplug (TH-953 proposal) | screen | P-30 · B.4 item 4 (session end) |
| `sf_unplug_session_done_early` | Session ended early | `/p/sf/unplug/session/done?state=early` | ScrollFree · Unplug (TH-953 proposal) | ended early of `sf_unplug_session_done` | P-30 · B.4 item 4 (session end with override) |
| `sf_unplug_shield` | Pause screen (iPhone shield) | `/system/unplug/shield` | ScrollFree · Unplug (TH-953 proposal) | fullscreen | P-30 · B.4 item 5 (iOS shield appearance) |
| `sf_unplug_shield_firm` | Pause screen (iPhone shield, firm) | `/system/unplug/shield?state=firm` | ScrollFree · Unplug (TH-953 proposal) | no “open anyway” left of `sf_unplug_shield` | P-30 · B.4 item 5 (iOS shield, Firm level or overrides used up) |
| `sf_unplug_overlay` | Pause screen (Android overlay) | `/system/unplug/overlay` | ScrollFree · Unplug (TH-953 proposal) | fullscreen | P-30 · B.4 item 6 (Android intercept overlay; TH-969 layout must match) |
| `sf_unplug_gate` | Small step: one breath | `/p/sf/unplug/step` | ScrollFree · Unplug (TH-953 proposal) | fullscreen | P-30 · B.4 item 2 (effort gate: breath) |
| `sf_unplug_gate_commit` | Small step: type a sentence | `/p/sf/unplug/step?state=sentence` | ScrollFree · Unplug (TH-953 proposal) | typed sentence of `sf_unplug_gate` | P-30 · B.4 item 2 (effort gate: commitment) |
| `sf_unplug_gate_sum` | Small step: quick sum | `/p/sf/unplug/step?state=sum` | ScrollFree · Unplug (TH-953 proposal) | quick sum of `sf_unplug_gate` | P-30 · B.4 item 2 (effort gate: puzzle) |
| `sf_unplug_health` | Tracking check | `/p/sf/unplug/health` | ScrollFree · Unplug (TH-953 proposal) | screen | P-30 · B.4 item 7 (tracking health) |
| `sf_unplug_health_stopped` | Tracking stopped | `/p/sf/unplug/health?state=stopped` | ScrollFree · Unplug (TH-953 proposal) | tracking stopped of `sf_unplug_health` | P-30 · B.4 item 7 ("tracking stopped", onTrackingStopped) |
| `sf_unplug_health_android` | Tracking check (Android) | `/p/sf/unplug/health?state=android` | ScrollFree · Unplug (TH-953 proposal) | android of `sf_unplug_health` | P-30 · B.4 item 7 (Android) |
| `sf_unplug_off` | Turn off Unplug | `/p/sf/unplug/off` | ScrollFree · Unplug (TH-953 proposal) | sheet | P-30 · B.4 item 8 ("turn off") |
| `sf_home_unplug_offer` | ScrollFree home · Unplug offer | `/p/sf/home?state=unplug-offer` | ScrollFree | Unplug not set up (proposal) of `sf_home` | P-30 · entry point to Unplug from ScrollFree |
| `sf_home_unplug` | ScrollFree home · Unplug on (iPhone) | `/p/sf/home?state=unplug` | ScrollFree | Unplug on · iPhone (proposal) of `sf_home` | P-30 · B.4 item 9 (TNativeSlot for the iOS DeviceActivityReport minutes) and B.4 "label server figures as self-report" |
| `sf_week_unplug` | Weekly reflection · Unplug on (iPhone) | `/p/sf/week?state=unplug` | ScrollFree | Unplug on · iPhone (proposal) of `sf_week` | P-30 · B.4 item 9 (TNativeSlot on sf_week) |
| `program_settings_sf` | Program settings · ScrollFree with Unplug | `/p/:program/settings?state=sf-unplug` | Plans & programs | ScrollFree with Unplug (proposal) of `program_settings` | P-30 · B.4 item 8 (Unplug settings and "turn off" in Account → ScrollFree) |
| `sf_screentime_report` | Connect Screen Time · iPhone report wording | `/p/sf/screen-time?state=ios-report` | ScrollFree | iPhone report wording (proposal) of `sf_screentime` | P-30 / B.4 copy contradiction: sf_screentime says Tether "reads" totals; on iPhone the report extension only shows them |
| `account_delete_apple` | Delete account · Apple account | `/account/delete?state=apple` | Account & data | Apple account of `account_delete` | P-36 (social-user account_delete) · TH-935 social re-auth |
| `account_delete_google` | Delete account · Google account | `/account/delete?state=google` | Account & data | Google account of `account_delete` | P-36 (social-user account_delete) · TH-935 social re-auth |
| `auth_session_apple` | Session expired · Apple account | `/auth/session?state=apple` | Account & sign-in | Apple account of `auth_session` | P-36 (social-user auth_session) · TH-935 |
| `auth_session_google` | Session expired · Google account | `/auth/session?state=google` | Account & sign-in | Google account of `auth_session` | P-36 (social-user auth_session) · TH-935 |
| `sf_screentime_android` | Connect usage access (Android) | `/p/sf/screen-time?state=android` | ScrollFree | android of `sf_screentime` | P-36 (Android variant of sf_screentime) |
| `sf_screentime_android_denied` | Usage access off (Android) | `/p/sf/screen-time?state=android-denied` | ScrollFree | android · not allowed of `sf_screentime` | P-36 (Android variant of sf_screentime_denied) |
| `sys_update_android` | Update required (Android) | `/system/update?state=android` | System states | android of `sys_update` | P-36 (sys_update Play Store URL per platform) |
| `surface_widget_ios` | Home-screen widget (iPhone) | `/surface/widget/ios` | Home screen, Siri & shortcuts (TH-953 proposal) | fullscreen | P-32 / P-48 · B.5 (rescue_pick entry: "Home-screen widget / Siri: Rescue") |
| `surface_widget_android` | Home-screen widget (Android) | `/surface/widget/android` | Home screen, Siri & shortcuts (TH-953 proposal) | fullscreen | P-32 / P-48 · B.5 (rescue_pick entry) |
| `surface_shortcuts_ios` | Siri & App Shortcuts (iPhone) | `/surface/shortcuts/ios` | Home screen, Siri & shortcuts (TH-953 proposal) | screen | P-32 / P-48 · B.5 (rescue_pick Siri entry; ca_red "Shortcut: ClearAir red-zone plan") |
| `surface_shortcuts_ios_named` | Siri & App Shortcuts (sensitive details on) | `/surface/shortcuts/ios?state=named` | Home screen, Siri & shortcuts (TH-953 proposal) | Show sensitive details on of `surface_shortcuts_ios` | P-48 (program names only with sensitive_details) |
| `surface_shortcuts_android` | Launcher shortcuts (Android) | `/surface/shortcuts/android` | Home screen, Siri & shortcuts (TH-953 proposal) | screen | P-32 / P-48 · B.5 (rescue_pick, ca_red entries) |
| `surface_shortcuts_android_named` | Launcher shortcuts (sensitive details on) | `/surface/shortcuts/android?state=named` | Home screen, Siri & shortcuts (TH-953 proposal) | Show sensitive details on of `surface_shortcuts_android` | P-48 (program names only with sensitive_details) |

## Decisions the owner makes in this review

1. **Where Unplug starts.** Proposed: one optional card on ScrollFree home
   (`sf_home_unplug_offer`), plus a row in ScrollFree settings
   (`program_settings_sf`). Choosing this changes the approved `sf_home` and
   the ScrollFree view of `program_settings`.
2. **"Not a lock" (`sf_intro`, `sf_pause`).** Proposed: keep the wording.
   Pause 60 stays an intent check, and Unplug is presented as the separate,
   optional lock (`sf_unplug_intro`).
3. **"Reads" vs "shows" (`sf_screentime`).** On iPhone, Tether cannot read
   Screen Time minutes. Apple's report view only shows them. Either adopt
   `sf_screentime_report` ("shows") or have legal accept "reads".
4. **Native minutes slot on iPhone** (`sf_home_unplug`, `sf_week_unplug`,
   TNativeSlot). If you reject it, the iPhone copy must be reworded instead.
   Either way, figures Tether stores on iPhone are labelled as your own
   estimate.
5. **Group names stay on the phone** (`sf_unplug_apps_chosen`). Proposed: not
   synced.
6. **Looser limits start tomorrow** (`sf_unplug_limits`). This comes from the
   feat branch tier model and is a proposal.
7. **Sessions never pause Tether or phone calls** (`sf_unplug_session`), so
   Rescue and 988 stay reachable.
8. **The iPhone shield's "Take a breath"** cannot open Tether directly. The
   proposal is a local notification that opens the small step
   (`sf_unplug_gate`). This needs device validation (H39).
9. **Shortcut label "My plan"** for the ClearAir red-zone plan (P-48 generic
   default). Program names appear only when Show sensitive details is on
   (`*_named` states).
10. **Widget / shield / overlay / shortcut screens are references for native
    work** (TH-966 to TH-969), not app routes. Decide whether release
    acceptance (TH-952) checks them with the screenshot checklist (H39)
    instead of Flutter goldens.

## Copy for clinical/legal review

All visible text on the 44 screens above. Text that is new in wording, not
copied from an approved screen:

- Unplug intro, permission, picker, limits, session, shield, overlay, small
  step, tracking check and turn-off screens (`sf_unplug_*`): every string.
- `sf_home_unplug_offer`: "Want firmer limits? Unplug can pause apps you
  choose, after limits you set. Optional."
- `sf_home_unplug` / `sf_week_unplug`: "Yesterday · your estimate", "Your
  estimates · minutes / day", and the slot caption "Shown by Apple's Screen
  Time on this phone. Tether can't read, store or share these minutes."
- `sf_screentime_report`: the title, body and "Shows" row.
- `sf_screentime_android(_denied)`: the Settings steps and "Usage access is
  still off."
- `program_settings_sf`: the "Screen Time & Unplug" rows.
- `account_delete_apple|google`: the "Confirm it's you" card and the outcome
  toasts.
- `auth_session_apple|google`: "You signed in with Apple/Google, so there's no
  password to type." and "Still signed out. Rescue works without signing in."
- `sys_update_android`: the Play Store URL uses app ID
  `com.TetherHealthLLC.tetherhealth` (P-28). The base screen's App Store URL
  `https://apps.apple.com/app/tether-health` still needs the real App Store
  ID.
- `surface_*`: the shortcut labels, Siri phrases and widget text.

## Generator changes (every line touched outside this file)

- `validate.py` `load()`: 2 lines. Import `screens_additions` and call
  `screens_additions.additions()` after the existing four modules.
- `render_html.py`: 1 line added. The `nativeslot` node renders as a labelled
  placeholder.
- `gen_dart.py`: 1 line added. The `nativeslot` node becomes `TNativeSlot(...)`.
- `build_all.py`: 1 line added to `COMPONENTS`. This documents `nativeslot`
  in `design/components.json`.
- `dart_static/lib/ui/components.dart`: the `TNativeSlot` widget was appended
  at the end of the file.

This file lives in `generator/` rather than `spec/` because `build_all.py`
deletes and rewrites `spec/` on every run.
