# Bound examples for clinical review (P-89)

Generated from `generator/bindings.py` (`CLINICAL_REVIEW`); do not edit.

In the app these example values show, with an "Example" tag, until the member has their own value.
Each could read as clinical advice or a clinical judgement if taken as the member's own.
For the clinical lead: keep, reword or replace each example.

| Screen | Element | Example | Why it is listed |
|---|---|---|---|
| `ca_home` | `body[0].title` | Green · 410 L/min | states a peak-flow zone ("Green") for a reading |
| `ca_zone` | `body[5].text` | Worked out only from the plan you entered (green from 400, red below 200). | states zone thresholds from an action plan |
| `ca_yellow` | `body[0].text` | From the plan you entered on Sep 3 | points to a dated action plan |
| `ca_progress` | `body[2].title` | Wheezing at night (3×) | names a most common symptom |
| `hw_home` | `body[0].children[0].caption` | Average of 2 · target below 130/80 | states a blood-pressure target |
| `hw_home` | `body[2].rows[4].sub` | 130/80 from Dr. Patel | states a clinician-set target |
| `hw_result` | `body[2].text` | Average of 2 readings. Your clinician’s target is below 130/80. | compares a reading with a target |
| `hw_crisis` | `body[0].text` | 186/122 is in a range that needs attention now. | says a reading needs attention now |
| `hw_summary` | `body[1].rows[2][1]` | 186/122 · Oct 2 · re-checked 144/90 | reports a crisis-range reading and its re-check |
| `today_safety` | `body[1].text` | Heartwise · from your 8:10 AM reading | refers to a crisis-range reading |
| `st_home` | `body[0].children[0].caption` | Within your after-meal range (below 180) | says a glucose reading is within range |
| `st_low` | `body[0].text` | 62 mg/dL is below your low of 70. | says a glucose reading is below the member's low |
| `st_patterns` | `body[3].title` | Readings were higher on nights with less than 6 h sleep. | links glucose readings to sleep |
| `st_a1c` | `body[3].rows[1][1]` | −0.5 points | reports an A1C change |
| `re_home` | `body[0].children[0].caption` | Next check Apr 2027 · from your clinician | states the next kidney check |
| `re_history` | `body[1].rows[2][1]` | Apr 2027 (from your clinician) | states the next kidney check |
| `bf_stepdown` | `body[2].rows[0][1]` | 15 → 12 a day | a cigarette reduction schedule |
| `bf_meds` | `body[1].title` | Nicotine patch · morning | a recorded quit-medicine plan |
| `records_conflict` | `body[1].title` | 1290/80 is outside the possible range | judges a value outside the possible range |
| `ck_list` | `body[0].text` | 3 due, 1 to ask about | counts screenings due |
| `ck_uptodate` | `body[2].text` | Next: flu vaccine in Sep 2027. We’ll remind you a month before. | states the next vaccine due date |
| `progress` | `body[4].title` | Late scrolling came before 3 of your 4 strongest cravings. | links scrolling to cravings |
| `sf_week` | `body[4].title` | Step down to 75 min? | suggests a lower daily goal |
