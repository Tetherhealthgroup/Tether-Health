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
| `crisis` | `body[5].text` | drops "Works offline." | 10 |
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
