# TH-953 — spec additions, approved by the owner (P-47, H32)

These are internal traceability notes for reviewers. The file sits in
`generator/` and is not part of the shipped app. The generated spec,
prototype and Flutter code contain no internal review IDs. Their notes say only
"Copy needs clinical/legal review."

Status: the owner **approved the prototype as proposed** (the owner's decision
record, "P-47 (H32)", decisions 1–14). All new copy still needs clinical/legal review.

Source: `screens_additions.py`. The two approved screens that the decisions
change are edited in place in `screens_prog_a.py`.

## Changed approved screens (decisions 1 and 3)

Every other approved screen is byte-identical: spec JSON, Flutter screen file
and prototype template.

| Screen | Before | After |
|---|---|---|
| `sf_home` | Urge card → Today's step → rows | A new card between the Urge card and Today's step: "Want firmer limits?" / "Unplug can pause apps you choose, after limits you set. Optional." with a **Set up** button → `sf_unplug_intro`. The paths of later actions shift from `body[3].rows[n]` to `body[4].rows[n]`. |
| `sf_screentime` (iPhone base) | "See real totals, if you want." · "Tether reads daily totals by category only. Never apps' content, messages or contacts." · row "Reads: Minutes per category" | "See your Screen Time here, if you want." · "Apple's Screen Time shows your daily totals by category inside Tether. Tether can't read, store or share those minutes." · row "Shows: Minutes per category, on this phone". Layout and actions are unchanged. The Android variant `sf_screentime_android` keeps "reads" (true on Android). |

Proposal states removed because they are now redundant:
- `sf_home_unplug_offer` was folded into `sf_home`.
- `sf_screentime_report` was folded into `sf_screentime`.

State kept: `program_settings_sf`. The base `program_settings` is
parameterized and shown with BreatheFree data. Only ScrollFree has the
Screen Time & Unplug section, so the ScrollFree instance is a genuinely
different state. It is renamed to state "ScrollFree".

State kept: `sf_home_unplug`. "Unplug on (iPhone)" is a different state. It
adds Apple's minutes view (native slot), labels yesterday's figure "your
estimate", and replaces the offer card with the Unplug status card.

## How the owner reviews it

Open `tether_ui/prototype/index.html`.
- Flows: **ScrollFree · Unplug** and **Home screen, Siri & shortcuts**.
- States of existing screens are under **States** in the right panel.
- The **Simulator** tab has 7 Unplug scenarios: strict reason, sentence,
  sum, Rescue from the overlay, shield and firm shield, and notifications
  off.

## Added screens (44)

"Ref" = `reference: true` (decision 12): excluded from release-check counts,
checked by device screenshots, render tests kept.

| ID | Name | Route | Flow | Kind / state | Ref | Serves |
|---|---|---|---|---|---|---|
| `sf_unplug_intro` | Unplug intro | `/p/sf/unplug` | ScrollFree · Unplug | screen |  | P-30, B.4 |
| `sf_unplug_auth` | Allow Screen Time | `/p/sf/unplug/permission` | ScrollFree · Unplug | screen |  | P-30, B.4 |
| `sf_unplug_auth_denied` | Screen Time not allowed | `/p/sf/unplug/permission?state=denied` | ScrollFree · Unplug | permission denied of `sf_unplug_auth` |  | P-30, B.4 |
| `sf_unplug_auth_unavailable` | Screen Time unavailable | `/p/sf/unplug/permission?state=unavailable` | ScrollFree · Unplug | unavailable of `sf_unplug_auth` |  | P-30, B.4 |
| `sf_unplug_auth_notifications` | Notifications off | `/p/sf/unplug/permission?state=notifications` | ScrollFree · Unplug | notifications off of `sf_unplug_auth` |  | P-47 decision 13 |
| `sf_unplug_auth_android` | Android permissions for Unplug | `/p/sf/unplug/permission?state=android` | ScrollFree · Unplug | android of `sf_unplug_auth` |  | P-30, B.4 |
| `sf_unplug_apps` | Choose apps | `/p/sf/unplug/apps` | ScrollFree · Unplug | screen |  | P-30, B.4 item 1 |
| `sf_unplug_picker_ios` | Apple app picker | `/p/sf/unplug/apps/picker` | ScrollFree · Unplug | sheet | yes | P-30, B.4 item 1 |
| `sf_unplug_apps_android` | Choose apps (Android) | `/p/sf/unplug/apps?state=android` | ScrollFree · Unplug | android of `sf_unplug_apps` | yes | P-30, B.4 item 1, TH-969 |
| `sf_unplug_apps_chosen` | Name your groups | `/p/sf/unplug/apps?state=chosen` | ScrollFree · Unplug | apps chosen of `sf_unplug_apps` |  | P-30, B.4 item 1 |
| `sf_unplug_limits` | Limits & pause screen | `/p/sf/unplug/limits` | ScrollFree · Unplug | screen |  | P-30, B.4 items 2-3 |
| `sf_unplug_home` | Unplug | `/p/sf/unplug/home` | ScrollFree · Unplug | screen |  | P-30, B.4 item 8 |
| `sf_unplug_session` | Start a focus session | `/p/sf/unplug/session` | ScrollFree · Unplug | screen |  | P-30, B.4 item 4 |
| `sf_unplug_session_active` | Focus session running | `/p/sf/unplug/session/active` | ScrollFree · Unplug | fullscreen |  | P-30, B.4 item 4 |
| `sf_unplug_session_end` | End session early | `/p/sf/unplug/session/end` | ScrollFree · Unplug | sheet |  | P-30, B.4 item 4 |
| `sf_unplug_session_done` | Session complete | `/p/sf/unplug/session/done` | ScrollFree · Unplug | screen |  | P-30, B.4 item 4 |
| `sf_unplug_session_done_early` | Session ended early | `/p/sf/unplug/session/done?state=early` | ScrollFree · Unplug | ended early of `sf_unplug_session_done` |  | P-30, B.4 item 4 |
| `sf_unplug_shield` | Pause screen (iPhone shield) | `/system/unplug/shield` | ScrollFree · Unplug | fullscreen | yes | P-30, B.4 item 5 |
| `sf_unplug_shield_firm` | Pause screen (iPhone shield, firm) | `/system/unplug/shield?state=firm` | ScrollFree · Unplug | no “open anyway” left of `sf_unplug_shield` | yes | P-30, B.4 item 5 |
| `sf_unplug_overlay` | Pause screen (Android overlay) | `/system/unplug/overlay` | ScrollFree · Unplug | fullscreen | yes | P-30, B.4 item 6, TH-969 |
| `sf_unplug_gate` | Small step: one breath | `/p/sf/unplug/step` | ScrollFree · Unplug | fullscreen |  | P-30, B.4 item 2 |
| `sf_unplug_gate_commit` | Small step: type a sentence | `/p/sf/unplug/step?state=sentence` | ScrollFree · Unplug | typed sentence of `sf_unplug_gate` |  | P-30, B.4 item 2 |
| `sf_unplug_gate_sum` | Small step: quick sum | `/p/sf/unplug/step?state=sum` | ScrollFree · Unplug | quick sum of `sf_unplug_gate` |  | P-30, B.4 item 2 |
| `sf_unplug_health` | Tracking check | `/p/sf/unplug/health` | ScrollFree · Unplug | screen |  | P-30, B.4 item 7 |
| `sf_unplug_health_notifications` | Tracking check · notifications off | `/p/sf/unplug/health?state=notifications` | ScrollFree · Unplug | notifications off of `sf_unplug_health` |  | P-47 decision 13 |
| `sf_unplug_health_stopped` | Tracking stopped | `/p/sf/unplug/health?state=stopped` | ScrollFree · Unplug | tracking stopped of `sf_unplug_health` |  | P-30, B.4 item 7 |
| `sf_unplug_health_android` | Tracking check (Android) | `/p/sf/unplug/health?state=android` | ScrollFree · Unplug | android of `sf_unplug_health` |  | P-30, B.4 item 7 |
| `sf_unplug_off` | Turn off Unplug | `/p/sf/unplug/off` | ScrollFree · Unplug | sheet |  | P-30, B.4 item 8 |
| `sf_home_unplug` | ScrollFree home · Unplug on (iPhone) | `/p/sf/home?state=unplug` | ScrollFree | Unplug on · iPhone of `sf_home` |  | P-30, B.4 item 9, B.4 |
| `sf_week_unplug` | Weekly reflection · Unplug on (iPhone) | `/p/sf/week?state=unplug` | ScrollFree | Unplug on · iPhone of `sf_week` |  | P-30, B.4 item 9 |
| `program_settings_sf` | Program settings · ScrollFree with Unplug | `/p/:program/settings?state=sf-unplug` | Plans & programs | ScrollFree of `program_settings` |  | P-30, B.4 item 8 |
| `account_delete_apple` | Delete account · Apple account | `/account/delete?state=apple` | Account & data | Apple account of `account_delete` |  | P-36, TH-935 |
| `account_delete_google` | Delete account · Google account | `/account/delete?state=google` | Account & data | Google account of `account_delete` |  | P-36, TH-935 |
| `auth_session_apple` | Session expired · Apple account | `/auth/session?state=apple` | Account & sign-in | Apple account of `auth_session` |  | P-36, TH-935 |
| `auth_session_google` | Session expired · Google account | `/auth/session?state=google` | Account & sign-in | Google account of `auth_session` |  | P-36, TH-935 |
| `sf_screentime_android` | Connect usage access (Android) | `/p/sf/screen-time?state=android` | ScrollFree | android of `sf_screentime` |  | P-36 |
| `sf_screentime_android_denied` | Usage access off (Android) | `/p/sf/screen-time?state=android-denied` | ScrollFree | android · not allowed of `sf_screentime` |  | P-36 |
| `sys_update_android` | Update required (Android) | `/system/update?state=android` | System states | android of `sys_update` |  | P-36 |
| `surface_widget_ios` | Home-screen widget (iPhone) | `/surface/widget/ios` | Home screen, Siri & shortcuts | fullscreen | yes | P-32, P-48, B.5 |
| `surface_widget_android` | Home-screen widget (Android) | `/surface/widget/android` | Home screen, Siri & shortcuts | fullscreen | yes | P-32, P-48, B.5 |
| `surface_shortcuts_ios` | Siri & App Shortcuts (iPhone) | `/surface/shortcuts/ios` | Home screen, Siri & shortcuts | screen | yes | P-32, P-48, B.5 |
| `surface_shortcuts_ios_named` | Siri & App Shortcuts (sensitive details on) | `/surface/shortcuts/ios?state=named` | Home screen, Siri & shortcuts | Show sensitive details on of `surface_shortcuts_ios` | yes | P-48 |
| `surface_shortcuts_android` | Launcher shortcuts (Android) | `/surface/shortcuts/android` | Home screen, Siri & shortcuts | screen | yes | P-32, P-48, B.5 |
| `surface_shortcuts_android_named` | Launcher shortcuts (sensitive details on) | `/surface/shortcuts/android?state=named` | Home screen, Siri & shortcuts | Show sensitive details on of `surface_shortcuts_android` | yes | P-48 |

## Decisions as approved (P-47) and where they are applied

1. Unplug entry card on ScrollFree home, plus a settings row. Done:
   `sf_home` and `program_settings_sf`.
2. Keep "not a lock" for Pause 60. `sf_intro` and `sf_pause` are unchanged;
   `sf_unplug_intro` says it.
3. iPhone copy "shows", not "reads". Done: `sf_screentime`.
4. Embed Apple's minutes view; Tether figures labelled "your estimate".
   Done: `sf_home_unplug`, `sf_week_unplug`, TNativeSlot.
5. Group names stay on the device. Done: `sf_unplug_apps_chosen`.
6. Looser limits take effect the next day. Done: `sf_unplug_limits`.
7. Tether, the dialer and emergency calling can never be paused. Done: copy
   plus native-requirement notes (TH-968, TH-969).
8. Shield actions go through a notification. Needs device validation (H39).
9. Generic "My plan" label. Done: `surface_shortcuts_*`.
10. Reference surfaces are checked by device screenshots (H39).
11. Keep the pre-selected defaults. The "Suggested" badge on
    `sf_unplug_limits` goes to clinical review.
12. Reference screens are excluded from release-check counts. Done:
    `reference: true` on 11 screens (9 named in the decision plus the 2 app
    pickers); `validation/summary.json` → `release_check` (screens 216,
    actions 883, plus the list). TH-952
    should use these counts.
13. Notifications-off fallback. Done:
    - Both shield subtitles add "Open Tether for support."
    - `sf_unplug_auth` checks notification permission (outcome "Approved ·
      notifications off") and `sf_unplug_auth_android` does too ("Notifications
      off"). Both lead to `sf_unplug_auth_notifications`, which offers Open
      phone settings, Check again, and Continue without notifications.
    - The tracking checks now have 4 items, including Notifications; the new
      state `sf_unplug_health_notifications` handles the off case.
    - Scenario: `sf_unplug_notifications_off`.
14. The three Unplug rules (`sf.unplug.reason`, `.sentence`, `.sum`) are
    product rules, not clinical. The `source` field in rules.json says so.

App pickers (coordinator decision under decision 12, owner may override):
`sf_unplug_picker_ios` (Apple's system sheet) and `sf_unplug_apps_android`
(a native Activity) are marked `reference: true`. Decision 12's principle is
that native surfaces Flutter goldens cannot capture are checked by device
screenshots. That makes 11 reference screens.

## Notes for implementation tickets

- TH-949: native sync sends only per-category daily totals. It never sends
  Unplug group names, package names, or per-group figures (P-47 decision 5,
  and the privacy line on `sf_home_unplug_android`).

## Safety requirements (from review)

- Every pause surface reaches Rescue, and Rescue reaches Emergency:
  - overlay: Get support
  - firm shield: second button, Get support
  - shield: the notification's Get support action
  - small steps: the Get support card
- With notifications off, the shield subtitle says "Open Tether for support"
  (decision 13).
- Never paused: Tether, the phone dialer and emergency calling (decision 7).
- The gates are real: the strict-session reason, the full sentence, the
  correct sum.

## Copy for clinical/legal review

All visible text on the 44 added screens, plus the new copy on `sf_home`
(the Unplug card) and `sf_screentime` ("shows" wording). Of note:
- the Get support card and button
- the never-paused sentences
- the gate and strict-session messages
- the notifications-off screens and "Open Tether for support"
- the "Suggested" badge (decision 11)
- the "Confirm it's you" card
- the Play URL (the base App Store URL still lacks the real App Store ID)
- the shortcut labels and Siri phrases
- `sf_home_unplug_android` (TH-971): the measured-usage stats, the
  "Measured by Tether on this phone" line and the Unplug status card

## Generator changes outside the screen modules

- `validate.py` `load()`: 2 lines (load `screens_additions`).
- `render_html.py`, `gen_dart.py`: +1 line each (`nativeslot`).
- `build_all.py`: +1 line in `COMPONENTS`.
- `dart_static/lib/ui/components.dart`: `TNativeSlot` appended.
- `proto_v2.py`: +3 lines (prototype rules).
- `dart_static/lib/logic/rules.dart`: +10 lines (the same 3 rules).
- `report.py`: +1 line (`release_check` in `validation/summary.json`).
- `screens_prog_a.py`: the `sf_home` card and the `sf_screentime` copy
  (decisions 1 and 3).
- The rule specs and the 7 scenarios are registered from
  `screens_additions.py`; `rules.py` is unchanged.
- TH-971: `dart_static/analysis_options.yaml` now includes the `analyzer:
  exclude:` block that Flutter 3.47.1 writes on `pub get`, so the generated
  `tether_ui/flutter/analysis_options.yaml` stays unchanged across gate runs.
- TH-971: `screens_additions.py` adds `sf_home_unplug_android` (Unplug on,
  Android). It uses category labels only ("Short video and Feeds"), and opens
  are marked as on this phone only.

This file is in `generator/` because `build_all.py` rewrites `spec/` on
every run.
