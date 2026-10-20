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
- The TH-1001 row removes one text node from `body` and adds the same text
  to the screen's `notes`, which are not rendered. Nothing else changes.

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
| `ob_account` | `body[5]` Email: "alex@example.com"; `body[6]` Password: "••••••••••••". Also TH-902 (key, below). |
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
as `program_settings_sf`. Checklist and tile on/off states are unchanged,
including the ticked "I’m 18 or older" on `ob_account`.

| Screen | Node | Change |
|---|---|---|
| `ob_account` | `body[7]` (checklist) | gets key `age_18_or_older`. Also P-31 (above). |
| `ob_programs` | `body[3]` (tiles) | gets key `programs`. |
| `program_settings` | `body[2].children[0]` (toggle) | key `care_team_dr_patel_s_clinic` → `care_team_sharing`. Also P-08 (TH-942). |
| `records_consent` | `body[2]` (checklist) | gets key `resources`. |
| `records_consent_bb` | `body[2]` (checklist) | gets key `resources`. |
| `records_consent_device` | `body[2]` (checklist) | gets key `data_types`. |
| `sd_caregiver` | `body[3]` (checklist) | gets key `caregiver_can_see`. Also P-31 (above). |
| `sf_buddy` | `body[3]` (checklist) | gets key `buddy_can_see`. Also P-31 (above). |

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
