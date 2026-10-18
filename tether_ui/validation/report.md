# Validation report

Generated 2026-10-18T21:49:45+00:00 from the spec, the Flutter package and the HTML prototype.

| Check | Flutter | Prototype |
|---|---|---|
| End-to-end scenarios (all programs) | 75 / 75 | 75 / 75 |
| Button-flow sweep (every element × every outcome) | 1036 / 1036 | 1036 / 1036 |
| Render tests (every screen at 100% and 130% text) | 456 / 456 | — |
| Static analysis | `flutter analyze`: see analyze.txt | JS errors: 0 |
| Spec validator (loose ends) | 0 errors · 924 actions, every target exists, every screen reachable | |

## Scenarios by program and function

| Program | Setup | Sign-in | Daily | Rescue | Safety | Milestone | Resources | Validation | Health records | Navigation | Account |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **BreatheFree** | ✅ bf-date<br>✅ bf-today<br>✅ bf-reduce<br>✅ bf-explore | · | ✅ bf-meds | ✅ bf-rescue | · | ✅ bf-slip<br>✅ bf-slip-newdate | · | · | · | · | · |
| **ScrollFree** | ✅ sf-setup<br>✅ sf-denied | · | · | ✅ sf-pause | · | ✅ sf-slip | · | · | · | · | · |
| **ClearAir** | ✅ ca-setup<br>✅ ca-noplan | · | ✅ ca-green<br>✅ ca-yellow | · | ✅ ca-red<br>✅ ca-red-symptom | · | · | ✅ ca-invalid | · | · | · |
| **Heartwise** | ✅ hw-setup<br>✅ hw-learn | · | ✅ hw-normal | · | ✅ hw-crisis | · | ✅ hw-summary | ✅ hw-invalid | · | · | · |
| **Steady** | ✅ st-setup | · | ✅ st-normal | · | ✅ st-low<br>✅ st-low-custom | · | · | ✅ st-invalid | · | · | · |
| **Renew** | ✅ re-setup | · | · | · | ✅ re-symptom | ✅ re-labs | · | · | ✅ re-import | · | · |
| **Nourish** | ✅ nu-setup | · | · | ✅ nu-reset | ✅ nu-protect | · | · | · | · | · | · |
| **Stride** | ✅ sd-setup | · | ✅ sd-session | · | ✅ sd-fell | · | · | · | · | · | · |
| **Ease** | ✅ ea-setup<br>✅ ea-skip | · | ✅ ea-mood | · | ✅ ea-crisis | · | · | · | · | · | · |
| **Checkup** | ✅ ck-setup | · | · | · | · | ✅ ck-done | · | · | · | · | · |
| **Beacon** | ✅ be-risk<br>✅ be-tx<br>✅ be-survivor | · | ✅ be-diary | · | · | · | · | · | · | · | · |
| **Account, sign-in & shell** | ✅ onboarding | ✅ auth-email<br>✅ auth-apple<br>✅ auth-google<br>✅ auth-apple-new<br>✅ auth-google-link<br>✅ auth-google-error<br>✅ auth-wrong-password | ✅ checkin | · | · | · | · | · | ✅ fhir-epic<br>✅ fhir-bluebutton<br>✅ fhir-denied<br>✅ fhir-custom<br>✅ fhir-manual-ok<br>✅ fhir-manual-range<br>✅ fhir-disconnect | ✅ today-tabs | ✅ delete |

## Scenario details

| Scenario | Program | Steps | Ends at | Flutter | Prototype |
|---|---|---|---|---|---|
| auth-email: Create account with email, verify, keep both plans | — | tap “Create account” → at auth_verify → tap “I’ve confirmed my email” → at auth_merge → tap “Continue” | `today` | ✅ | ✅ |
| auth-apple: Sign in with Apple (iPhone) | — | tap “I already have an account” → outcome “Success” → tap “Continue with Apple” | `today` | ✅ | ✅ |
| auth-google: Sign in with Google (Android) | — | tap “I already have an account” → outcome “Success” → tap “Continue with Google” | `today` | ✅ | ✅ |
| auth-apple-new: New Apple ID starts onboarding with an account | — | tap “I already have an account” → outcome “New Apple ID, no Tether account” → tap “Continue with Apple” → at auth_social_new → tap “Create my account” | `ob_programs` | ✅ | ✅ |
| auth-google-link: Google email already used → link accounts | — | outcome “Email already has a Tether account” → tap “Continue with Google” → at auth_link → tap “Link and sign in” | `today` | ✅ | ✅ |
| auth-google-error: Google sign-in fails → error with email fallback | — | outcome “Error” → tap “Continue with Google” → at auth_social_error → tap “Use email instead” | `auth_signin` | ✅ | ✅ |
| auth-wrong-password: Wrong password shows inline error | — | tap “I already have an account” → outcome “Wrong password” → tap “Sign in” | `auth_signin_error` | ✅ | ✅ |
| onboarding: First run: 2 programs, consent, BreatheFree plan, guest | — | tap “Get started” → tap “Continue with 2 programs” → tap “Continue” → tap “Agree and continue” → tap “Continue” → at ob_setup → tap “BreatheFree” → tap “Next” → tap “Next” → tap “Save my reasons” → tap “Continue with this path” → tap “Confirm this date” → tap “Review my plan” → tap “Start my plan” → at ob_setup → tap “Continue” → outcome “Allowed” → tap “Turn on reminders” → tap “Continue on this phone only” | `today` | ✅ | ✅ |
| fhir-epic: Connect Epic MyChart, review, resolve conflict, add to programs | — | tap “Add a source” → tap “Hospital or clinic” → tap “Patel Family Medicine” → outcome “Approved” → tap “Continue to MyChart” → at records_importing → tap “Review imported data” → at records_review → tap “Review conflicts first” → tap “From Patel Family Medicine (Epic): 7.6%” → tap “Save choices” → at records_review → tap “Add 21 items to my programs” | `records_hub` | ✅ | ✅ |
| fhir-bluebutton: Connect Medicare Blue Button 2.0 | — | tap “Medicare · Blue Button 2.0” → outcome “Approved” → tap “Continue to Medicare.gov” → tap “Review imported data” | `records_review` | ✅ | ✅ |
| fhir-denied: Provider sign-in denied → error with options | — | tap “Hospital or clinic” → tap “Patel Family Medicine” → outcome “Denied or error” → tap “Continue to MyChart” → at records_error → tap “Enter manually instead” | `records_manual` | ✅ | ✅ |
| fhir-custom: Other FHIR server: capability check fails | — | tap “Other FHIR server” → outcome “Not a FHIR R4 server” → tap “Check and continue” | `records_error` | ✅ | ✅ |
| fhir-manual-ok: Manual A1C within range is saved | — | enter records_manual.value=7.4 → tap “Save” | `records_hub` | ✅ | ✅ |
| fhir-manual-range: Manual A1C 74 is held as out of range | — | enter records_manual.value=74 → tap “Save” | `records_manual_error` | ✅ | ✅ |
| fhir-disconnect: Disconnect a source and delete its data | — | tap “Patel Family Medicine” → tap “Disconnect” → tap “Delete data imported from this source” → tap “Disconnect source” | `records_hub` | ✅ | ✅ |
| bf-date: Set a quit date path | BreatheFree | tap “Set up BreatheFree” → tap “Next” → tap “Next” → tap “Save my reasons” → tap “Continue with this path” → at bf_date → tap “Confirm this date” → tap “Review my plan” → tap “Start my plan” | `bf_home` | ✅ | ✅ |
| bf-today: Quit today path skips the calendar | BreatheFree | tap “Set up BreatheFree” → tap “Next” → tap “Next” → tap “Save my reasons” → tap “Quit today” → tap “Continue with this path” → at bf_support | `bf_support` | ✅ | ✅ |
| bf-reduce: Reduce gradually path → step-down schedule | BreatheFree | tap “Set up BreatheFree” → tap “Next” → tap “Next” → tap “Save my reasons” → tap “Reduce gradually” → tap “Continue with this path” → at bf_stepdown → tap “Save schedule” | `bf_support` | ✅ | ✅ |
| bf-explore: Explore first path never asks for a date | BreatheFree | tap “Set up BreatheFree” → tap “Next” → tap “Next” → tap “Save my reasons” → tap “Explore first” → tap “Continue with this path” | `bf_home_explore` | ✅ | ✅ |
| bf-rescue: Craving rescue from BreatheFree home | BreatheFree | tap “Rescue” → tap “A cigarette” → tap “I’m done” → tap “Back to Today” | `today` | ✅ | ✅ |
| bf-slip: Slip recovery keeps the plan and starts a rescue | BreatheFree | tap “I smoked or had a slip” → tap “Save and start a 2-min Rescue” | `rescue_active` | ✅ | ✅ |
| bf-slip-newdate: Slip recovery → choose a new quit time | BreatheFree | tap “Choose a new quit time” → tap “Save and start a 2-min Rescue” | `bf_date` | ✅ | ✅ |
| bf-meds: Record nicotine patch taken | BreatheFree | tap “Taken today” → tap “Add or update recorded plan” → tap “Save plan” | `bf_meds` | ✅ | ✅ |
| sf-setup: ScrollFree setup with Screen Time allowed | ScrollFree | tap “Set up ScrollFree” → tap “Next” → tap “Next” → tap “Connect Screen Time” → outcome “Allowed” → tap “Allow access” → at sf_goal → tap “Save my goal” → tap “Save and finish” | `sf_home` | ✅ | ✅ |
| sf-denied: Screen Time denied → self-report fallback | ScrollFree | tap “Connect Screen Time” → outcome “Not allowed” → tap “Allow access” | `sf_screentime_denied` | ✅ | ✅ |
| sf-pause: Pause 60 → put the phone down | ScrollFree | tap “Pause 60” → tap “I’m good, put it down” | `today` | ✅ | ✅ |
| sf-slip: Long-scroll recovery | ScrollFree | tap “Had a long scroll?” → tap “Save” | `sf_home` | ✅ | ✅ |
| ca-setup: ClearAir setup with a written plan | ClearAir | tap “Set up ClearAir” → tap “Next” → at ca_plan → tap “Save plan” | `ca_home` | ✅ | ✅ |
| ca-noplan: No action plan → learn route | ClearAir | tap “Set up ClearAir” → tap “No” → tap “Next” | `ca_noplan` | ✅ | ✅ |
| ca-green: Peak flow 420, no symptoms → green | ClearAir | enter ca_zone.peak_flow=420 → tap “Wheezing” → tap “Save and see my steps” | `ca_home` | ✅ | ✅ |
| ca-yellow: Peak flow 310 → yellow steps | ClearAir | enter ca_zone.peak_flow=310 → tap “Save and see my steps” | `ca_yellow` | ✅ | ✅ |
| ca-red: Peak flow 150 → red zone | ClearAir | enter ca_zone.peak_flow=150 → tap “Save and see my steps” | `ca_red` | ✅ | ✅ |
| ca-red-symptom: Can’t speak in full sentences → red regardless of peak flow | ClearAir | enter ca_zone.peak_flow=420 → tap “Can’t speak in full sentences” → tap “Save and see my steps” | `ca_red` | ✅ | ✅ |
| ca-invalid: Peak flow 2000 is rejected | ClearAir | enter ca_zone.peak_flow=2000 → tap “Save and see my steps” | `ca_zone` | ✅ | ✅ |
| hw-setup: Add Heartwise by swapping a focus slot | Heartwise | tap “Set up Heartwise” → tap “Swap with ScrollFree” → tap “Continue” → at hw_q1 → tap “Next” → tap “Save targets” | `hw_home` | ✅ | ✅ |
| hw-learn: Add Heartwise as Learn only | Heartwise | tap “Set up Heartwise” → tap “Continue” | `plans` | ✅ | ✅ |
| hw-normal: Two readings 138/86 + 132/84 → saved | Heartwise | tap “Log blood pressure” → tap “Next reading” → tap “Save readings” | `hw_result` | ✅ | ✅ |
| hw-crisis: Reading 186/122 → symptom check → re-check | Heartwise | tap “Log blood pressure” → enter hw_log.systolic=186 → enter hw_log.diastolic=122 → tap “Next reading” → tap “Save readings” → at hw_crisis → tap “No symptoms · re-check in 5 min” | `hw_recheck` | ✅ | ✅ |
| hw-invalid: Diastolic 310 → fix-it message | Heartwise | tap “Next reading” → enter hw_log2.diastolic=310 → tap “Save readings” | `hw_log_error` | ✅ | ✅ |
| hw-summary: Visit summary sent to care team | Heartwise | tap “Visit summary” → tap “Send summary” | `hw_home` | ✅ | ✅ |
| st-setup: Steady setup with range and low plan | Steady | tap “Set up Steady” → tap “Next” → tap “Save range” | `st_home` | ✅ | ✅ |
| st-normal: Reading 142 → saved | Steady | tap “Log a reading” → enter st_log.reading=142 → tap “Save reading” | `st_home` | ✅ | ✅ |
| st-low: Reading 62 → low plan with timer | Steady | tap “Log a reading” → enter st_log.reading=62 → tap “Save reading” | `st_low` | ✅ | ✅ |
| st-low-custom: Clinician low of 80: reading 75 → low plan | Steady | enter st_range.low=80 → tap “Save range” → tap “Log a reading” → enter st_log.reading=75 → tap “Save reading” | `st_low` | ✅ | ✅ |
| st-invalid: Reading 900 is rejected | Steady | enter st_log.reading=900 → tap “Save reading” | `st_log` | ✅ | ✅ |
| re-setup: Renew risk check and plan | Renew | tap “Set up Renew” → tap “See what this means” → tap “Save my plan” | `re_home` | ✅ | ✅ |
| re-labs: Add labs → history | Renew | tap “Add lab results” → tap “Save results” | `re_history` | ✅ | ✅ |
| re-import: Import labs from health record | Renew | tap “Import from my health record” | `records_add` | ✅ | ✅ |
| re-symptom: Yellow eyes → care team today | Renew | tap “Check symptoms” → tap “Contact my care team” | `support_message_care` | ✅ | ✅ |
| nu-setup: Nourish weekly habit | Nourish | tap “Set up Nourish” → tap “Next” → tap “Start this habit” | `nu_home` | ✅ | ✅ |
| nu-protect: Eating-history yes → protective mode | Nourish | tap “Set up Nourish” → tap “Yes” → tap “Next” | `nu_protect` | ✅ | ✅ |
| nu-reset: Off track → make it smaller | Nourish | tap “Busy week?” → tap “Make it smaller” → tap “Continue” | `nu_home` | ✅ | ✅ |
| sd-setup: Stride falls check and plan | Stride | tap “Set up Stride” → tap “Next” → tap “Start plan” | `sd_home` | ✅ | ✅ |
| sd-session: Complete a session | Stride | tap “Start” → tap “Finish session” | `sd_home` | ✅ | ✅ |
| sd-fell: I fell → okay → fall logged | Stride | tap “I fell” → tap “I’m okay, log this fall” | `sd_home` | ✅ | ✅ |
| ea-setup: Ease screener → result | Ease | tap “Set up Ease” → tap “Next” | `ea_result` | ✅ | ✅ |
| ea-skip: Skip screener → safety plan → home | Ease | tap “Set up Ease” → tap “Skip the check” → tap “Save plan” | `ea_home` | ✅ | ✅ |
| ea-mood: Mood check-in without self-harm → saved | Ease | tap “Start” → tap “Save” | `ea_home` | ✅ | ✅ |
| ea-crisis: Self-harm option → crisis screen | Ease | tap “Start” → tap “Thoughts of harming myself” → tap “Save” | `crisis` | ✅ | ✅ |
| ck-setup: Checkup builds a due list | Checkup | tap “Set up Checkup” → tap “Build my list” | `ck_list` | ✅ | ✅ |
| ck-done: Mark flu vaccine done | Checkup | tap “I got it” → tap “Save” | `ck_list` | ✅ | ✅ |
| be-risk: Beacon: lowering my risk | Beacon | tap “Set up Beacon” → tap “Next” → tap “See my plan” | `be_home` | ✅ | ✅ |
| be-tx: Beacon: going through treatment | Beacon | tap “Set up Beacon” → tap “Going through treatment” → tap “Next” | `be_tx` | ✅ | ✅ |
| be-survivor: Beacon: after treatment | Beacon | tap “Set up Beacon” → tap “After treatment” → tap “Next” | `be_survivor` | ✅ | ✅ |
| be-diary: Treatment diary saved | Beacon | tap “Today’s side-effect diary” → tap “Save” | `be_tx` | ✅ | ✅ |
| today-tabs: Every tab from Today | — | tap “Plans” → at plans → tap “Progress” → at progress → tap “Learn” → at learn → tap “Support” → at support → tap “Today” | `today` | ✅ | ✅ |
| checkin: Combined check-in → one step per program | — | tap “Start” → tap “Save check-in” → at checkin_done → tap “Back to Today” | `today` | ✅ | ✅ |
| delete: Delete account with receipt | — | tap “Your data” → tap “Delete account and all data” → tap “Delete everything” → at account_deleted → tap “Done” | `welcome` | ✅ | ✅ |
| sf_unplug_strict_end: Strict session needs a reason to end early | ScrollFree | tap “End early” → at sf_unplug_session_end → tap “End session” → at sf_unplug_session_end → tap “Expecting a message” → tap “End session” | `sf_unplug_session_done_early` | ✅ | ✅ |
| sf_unplug_gate_sum: Quick sum must be right before the app opens | ScrollFree | tap “Open it for 10 minutes” → at sf_unplug_gate_sum → enter sf_unplug_gate_sum.answer=9 → tap “Open it for 10 minutes” → at sf_unplug_gate_sum → enter sf_unplug_gate_sum.answer=12 → tap “Open it for 10 minutes” | `sf_home` | ✅ | ✅ |
| sf_unplug_gate_sentence: Sentence must be typed in full before the app opens | ScrollFree | tap “Open it for 10 minutes” → at sf_unplug_gate_commit → enter sf_unplug_gate_commit.sentence=I can come back → tap “Open it for 10 minutes” → at sf_unplug_gate_commit → enter sf_unplug_gate_commit.sentence=i can come back to this later. → tap “Open it for 10 minutes” | `sf_home` | ✅ | ✅ |
| sf_unplug_overlay_support: Android pause screen reaches Rescue and Emergency | ScrollFree | tap “Get support” → at rescue_pick → tap “Emergency” | `crisis` | ✅ | ✅ |
| sf_unplug_shield_support: iPhone shield reaches Rescue without the small step | ScrollFree | outcome “Get support” → tap “Take a breath” | `rescue_pick` | ✅ | ✅ |
| sf_unplug_shield_firm_support: Firm iPhone shield reaches Rescue | ScrollFree | tap “Get support” | `rescue_pick` | ✅ | ✅ |
| sf_unplug_notifications_off: Notifications off during setup → fix and continue | ScrollFree | outcome “Approved · notifications off” → tap “Continue” → at sf_unplug_auth_notifications → outcome “On (iPhone)” → tap “Check again” | `sf_unplug_apps` | ✅ | ✅ |

## Decision rules exercised

- **hw.bp** · Blood pressure reading check: Each reading must be sys 70–250, dia 40–150, dia < sys, else Invalid. If either reading has sys ≥ 180 or dia ≥ 120 → Crisis (symptom check). Otherwise the average is saved. _ACC/AHA hypertensive crisis threshold (≥180/≥120). Needs clinical sign-off._
- **st.glucose** · Glucose reading check: Outside 20–600 mg/dL → Invalid. Below the member’s low (from their clinician, default 70) → Low plan with 15-min timer. Otherwise saved neutrally. _ADA level 1 hypoglycemia < 70 mg/dL. Needs clinical sign-off._
- **ca.zone** · Asthma/COPD zone from action plan: Peak flow outside 50–900 → Invalid. A red symptom or peak flow below the plan’s red threshold → Red. Peak flow below the green threshold or any symptom → Yellow. Otherwise Green. Thresholds come only from the member’s plan. _NAEPP asthma action plan zones. Needs pulmonology sign-off._
- **ea.selfharm** · Self-harm signal: If the member selects a self-harm option the crisis screen opens immediately (988/911). _Safe messaging guidance. Needs psychiatry sign-off._
- **rec.manual** · Manual health value check: Value must be within the plausible range for the chosen test, else held for review. Duplicates of an imported FHIR value (same LOINC, date, value) are not added twice. _Plausibility ranges, not clinical targets._
- **sf.unplug.reason** · Strict session: reason before ending early: A strict session ends early only when a reason chip is selected or a note is typed. _endSession(overrideReason) in pigeons/unplug_api.dart. Product rule, not clinical._
- **sf.unplug.sentence** · Small step: typed sentence: Done when the typed text equals the sentence, ignoring case, extra spaces and a final full stop. _PlatformEffortGate.commitment. Product rule, not clinical._
- **sf.unplug.sum** · Small step: quick sum: Done when the answer equals a + b. _PlatformEffortGate.puzzle. Product rule, not clinical._

## Failures

None.
