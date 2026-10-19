# TH-942 copy corrections: review list

Owner decisions:
- **P-22:** remove the "works offline" claim from the spec.
- **P-08:** no automatic purge. After someone leaves a program, its data is kept
  until they delete it ("delete now") or delete their account, so no copy may
  promise "30 days".

Every replacement below is a **draft**. It must not make an offline,
privacy-strength or clinical claim, and it contains none of the phrases
banned by the app's privacy-copy regression test. Nothing ships until a
clinician and counsel approve it.

Source: `screens_shared.py`, `screens_prog_a.py`, `screens_prog_b.py`,
`screens_additions.py`. `review_TH-953.md` was also touched: it adds
`sf_home_unplug_android` to its clinical/legal review list (a reviewer
note on TH-971). Only string contents changed. Components, keys,
actions, routes and screen order are unchanged, and `spec/actions.json` is
byte-identical.

## Changed strings

Field paths are the ones in `spec/screens/<id>.json`. A `desc` is the
developer description; it appears in the spec and as the doc comment of the
generated screen, not on the screen itself.

### P-22: "works offline" and close variants

| # | Screen id | Field | Old | New | Review |
|---|---|---|---|---|---|
| 1 | `welcome` | `body[5].rows[1][1]` (value for "Help in one tap") | Works offline | No typing needed | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 2 | `bf_intro` | `body[2].rows[0][1]` (value for "Help when cravings hit") | one tap, offline | one tap, no typing | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 3 | `bf_home` | `body[1].text` (card "Craving now?") | One tap · works offline | One tap · no typing | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 4 | `bf_home_quitday` | `body[3].text` (card "I have a craving") | One tap · no typing · offline | One tap · no typing | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 5 | `today` | `body[3].text` (card "Craving or urge to scroll?") | Help for the next few minutes · works offline | Help for the next few minutes | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 6 | `today_offline` | `body[2].text` (card "Craving or urge?") | Works offline | One tap · no typing | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 7 | `checkin` | `footer[1].text` | Private · works offline · skip anything | Skip any program question | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 8 | `ca_home` | `body[2].text` (card "Red-zone plan") | Open it fast, even offline | Open it fast | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 9 | `ca_red` | `body[4].text` | Stays open until you close it. Works offline. | Stays open until you close it. | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 10 | `crisis` | `body[5].text` | Shown whenever someone chooses “thoughts of harming myself” or types similar words anywhere. Works offline. 988 is US-only; localize per region. | Shown whenever someone chooses “thoughts of harming myself” or types similar words anywhere. 988 is US-only; localize per region. | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 11 | `rescue_pick` | `desc` | Works offline. With one Quit program, the app skips this screen and opens the last helpful tool. | With one Quit program, the app skips this screen and opens the last helpful tool. | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 12 | `ea_plan` | `desc` | Stored encrypted on the device only; available offline. | Stored encrypted on the device only. | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 13 | `auth_session` | `body[1].text` | For your security, sessions end after 30 days. Anything you logged offline is kept and syncs after you sign in. | For your security, sessions end after 30 days. | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 14 | `auth_session_apple` | `body[1].text` | (same as 13) | (same as 13) | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 15 | `auth_session_google` | `body[1].text` | (same as 13) | (same as 13) | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 20 | `today_loading` | `body[1].text` (card "Craving or urge?") | Always available | One tap · no typing | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 21 | `today_loading` | `body[4].text` | Rescue renders first from the on-device cache, before anything else loads. | The rest of Today is still loading. | **CLINICAL/LEGAL REVIEW REQUIRED** |

Rows 1, 3, 5, 6, 7, 9, 10 and 11 cover the 8 screens first identified for
P-22 (`rescue_pick` carried the claim in its `desc`, row 11). Rows 2, 4, 8,
12–15, 20 and 21 are close variants found by scanning every generator source,
including `screens_additions.py`. Rows 20 and 21 are stronger forms of the
same claim: "always available", and a visible note saying Rescue loads from an
on-device cache.

Row 7: "Skip any question" was not accurate, because the two shared
check-in questions (feeling, stress) have no skip option. Only the
per-program questions offer "Skip".

### P-08: "keep 30 days"

| # | Screen id | Field | Old | New | Review |
|---|---|---|---|---|---|
| 16 | `program_settings` | `body[3].rows[1].sub` (row "Leave BreatheFree") | Keep data 30 days or delete now | Keep your data or delete it now | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 17 | `program_settings_sf` | `body[4].rows[1].sub` (row "Leave ScrollFree") | Keep data 30 days or delete now | Keep your data or delete it now | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 18 | `account_leave` | `body[2].items[0].label` (radio option 1) | Keep my data for 30 days | Keep my data | **CLINICAL/LEGAL REVIEW REQUIRED** |
| 19 | `account_leave` | `body[2].items[0].sub` (radio option 1) | Rejoin anytime and pick up where you left off | Kept until you delete it or delete your account. Rejoin anytime. | **CLINICAL/LEGAL REVIEW REQUIRED** |

The second `account_leave` option ("Delete BreatheFree data now") is
unchanged.

## Not changed, kept on purpose

Offline-related copy left in place. **Each item is for H31 review** and
depends on launch scope:
- `today_offline` banner: "Offline · 3 entries will sync when you reconnect."
  **H31.** True only if the saved-entries outbox (TH-927) ships, so that
  entries made offline are queued and synced.
- `today_offline` checklist subtitle: "Saved on this phone". **H31.** Depends on
  the TH-927 outbox, which stores the entry on the device until it syncs.
- `today_offline` note: "Lessons not downloaded load when you’re back online."
  **H31.** Implies that downloaded lessons can be read offline. This becomes
  true with lesson downloads at launch (owner decision, TH-975). It still goes
  to H31 for wording.
- `learn_error` body text: "Check your connection. Downloaded lessons still
  work." **H31.** Becomes true with TH-975. Still goes to H31 for wording.
- `learn_error` button: "Open downloads". **H31.** Becomes true with TH-975.
  Still goes to H31 for wording.
- `learn` `body[2]` card text: "4 min read · 3:12 audio · downloaded".
  **H31.** Becomes true with TH-975. Still goes to H31 for wording.
- `learn_lesson` link "Save for offline" and its toast "Saved for offline".
  **H31.** Becomes true with TH-975. Still goes to H31 for wording.
- `today_loading` rows 20 and 21 above: these replace the "always available"
  and "on-device cache" claims. **H31.**
- Not copy: the `today_offline` screen id, route and state name, and the
  banner style kind `offline` (also used on `records_review`, whose text is
  "2 items need your review.").

Local-storage claims outside P-22's literal scope. These don't claim the
app works offline, but they do describe on-device storage, so they are
**flagged for H31**:
- `progress_error` `body[2]`: "Your data is safe on this phone. Try again in a
  moment." **H31.**
- `auth_verify` `body[3]`: "Your plan is saved on this phone while you wait.
  Nothing is lost if you close the app." **H31.**

Every remaining standalone "30" in the spec, with the reason it stays:
- `auth_session`, `auth_session_apple`, `auth_session_google`: "sessions end
  after 30 days" describes how long a sign-in session lasts, not how long data is kept.
- `progress`, `bf_progress`, `hw_trends`, `st_patterns`: "30 days" chart range
  options. `hw_home` "30-day average", `hw_trends` "30-day avg" and `sd_home`
  "last 30 days" are display windows.
- `support_callback`: "Consent expires · 30 days" is how long the call-back
  consent lasts, not data retention.
- `account_deleted`: "Backups are purged within 30 days." This concerns backup
  copies after account deletion, not program data kept after leaving (P-08).
  It is still a time promise whose truth depends on the backup configuration,
  so it is **listed for counsel and the owner to confirm or reword**.
- Other values are not durations of data retention: "21–30" (cigarettes per day), "30 min",
  "Move bedtime window 30 min earlier", "Sep 30" dates, "30 seconds",
  "30-second mood check-in", and the Unplug counter value 30.

## Notes for H31 (clinical lead and counsel)

- **Deleting a program's data after leaving (owner decision, TH-976).** The
  owner decided to add a "Programs you left" screen (Account → Programs) with
  a per-program "Delete data". It uses the delete-now route from TH-916.
  The P-08 retention copy (rows 16–19: "Keep your data or delete it now" on
  `program_settings` and `program_settings_sf`, and "Kept until you delete it
  or delete your account" on `account_leave`) becomes true once TH-976 and
  TH-914 ship. Until then, the only per-program deletion is "delete now" on
  `account_leave`, plus full account deletion.
- **`account_leave` option 2 label (pre-existing, for TH-976).** The second
  option always reads "Delete BreatheFree data now", even when the sheet is
  opened from `program_settings_sf` (ScrollFree). This predates TH-942 and is
  not changed here.
- **`account_deleted`: "Backups are purged within 30 days."** Unchanged.
  Counsel must confirm it against the actual backup configuration (retention
  of database backups and point-in-time recovery) before release, or reword it.
