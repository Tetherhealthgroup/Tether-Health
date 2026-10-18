# Tether Health · UI for development

Single source of truth for the Tether Health mobile app (iOS + Android, Flutter): **227 screens and states**, **22 flows**, **911 wired actions**, 11 programs, sign-in with **email, Apple and Google**, and **health records** from Epic, Medicare Blue Button and any SMART on FHIR server, or entered by hand.
Everything here is generated from one spec, so the design, the clickable prototype + simulator, the screenshots and the Flutter code always match.

## Validation (latest run)

| Check | Flutter | Prototype |
|---|---|---|
| End-to-end scenarios: setup and functions of every program, sign-in, health records | 75 / 75 | 75 / 75 |
| Button-flow sweep: every element × every outcome lands where the spec says | 1023 / 1023 | 1023 / 1023 |
| Render tests: every screen at 100% and 130% text, no overflow | 454 / 454 | — |
| Static analysis | `flutter analyze`: no issues | JS errors: 0 |
| Spec validator | 0 loose ends: every target exists, every screen reachable, no dead ends | |

Details per program and scenario: [validation/report.md](validation/report.md). Re-run everything with `generator/validate_all.sh`.

## Folder map

```
tether_ui/
├── README.md
├── prototype/index.html      ← clickable prototype + Simulator tab (run every scenario, iPhone/Android toggle)
├── validation/               ← report.md, summary.json, Flutter + prototype results, analyze.txt
├── design/                   ← tokens.json (WCAG contrast results), components.json
├── spec/
│   ├── screens.json, screens/<id>.json   ← every screen: route, kind, state, inputs (keys), actions, API
│   ├── flows.json · programs.json · app.json (entries, tabs, routes, action types)
│   ├── rules.json            ← decision rules (BP, glucose, zones, self-harm, manual values) with thresholds
│   ├── scenarios.json        ← 75 end-to-end scenarios with simulated data
│   ├── actions.json/.csv     ← flat button → action → target map
│   ├── develop_mapping.json  ← develop-branch file for each screen + logic to keep
│   └── validation.md         ← spec validator output
├── flows/                    ← <flow>.md (Mermaid + button map) and png/ flow boards
├── screens/                  ← png/<flow>/<id>.png (1.5×), png/auth/android_*.png, sheets/<flow>.png
├── flutter/                  ← runnable package, zero third-party deps
│   ├── lib/ui/               ← components.dart, tokens.dart, nav.dart (all actions; TPlatform/TApi/TAuth hooks)
│   ├── lib/logic/rules.dart  ← session values + decision rules (same as spec/rules.json)
│   ├── lib/router/           ← Routes + AppRouter (generated)
│   ├── lib/screens/<flow>/   ← one widget per screen (generated)
│   └── test/                 ← screens_test, action_sweep_test, scenarios_test (generated)
└── generator/                ← Python spec + builders (build_all.py, validate_all.sh)
```

## Run it

```bash
cd flutter
flutter pub get
flutter run                                  # developer gallery of all 227 screens
flutter run --dart-define=START=/welcome     # real first-run flow
flutter analyze && flutter test              # render tests + action sweep + scenarios
```

## Sign-in: email, Apple, Google

- **iPhone** shows *Continue with Apple* first, then Google, then email (App Store guideline 4.8 requires Sign in with Apple when Google is offered). **Android** shows *Continue with Google* and email.
- Screens: Save your progress, Sign in (sheet), New account from Apple/Google, Link accounts (same email already registered), Apple/Google error, Sign-in methods (Account), plus email verify / reset / session expiry.
- Production wiring: implement `TAuth.instance.signIn(provider, outcomes)` with `sign_in_with_apple` / `google_sign_in`, then Supabase `signInWithIdToken(provider, idToken, nonce)`. Return the outcome label (`Success`, `Cancelled`, `Error`, `Email already has a Tether account`, …). Supabase Apple/Google providers and the iOS/Android client IDs must be configured.

## Health records: FHIR and manual entry

- Sources: **Epic MyChart** (patient-facing SMART on FHIR R4 endpoints), **Oracle Health (Cerner)**, **Medicare Blue Button 2.0**, **Apple Health Records** (iPhone), **Health Connect** (Android), **any other SMART on FHIR R4 server** (capability check on `/.well-known/smart-configuration`), or **manual entry**.
- Flow: Add a source → find provider → consent (read-only, exact resources, which program receives what) → provider sign-in in the system browser (OAuth 2.0 + PKCE) → importing → **review before adding** → resolve conflicts → added to programs. Source details, sync now, disconnect (keep or delete imported data).
- Validation pipeline (records-service): FHIR R4 schema → code mapping (LOINC, SNOMED CT, CVX, RxNorm) → unit normalisation (UCUM, e.g. mmol/L → mg/dL) → plausibility ranges → duplicate detection (code + date + value) → conflict with manual entries → member review. Manual values are checked by `rec.manual` and labelled “Entered by you”. Imported values show their source everywhere.
- Tokens: the authorization code is exchanged by the backend; refresh tokens are stored encrypted server-side and never on the phone. Programs receive only their resources (Ease and ScrollFree receive none).
- “BLuZONE” in the request was read as Blue Button (CMS). Any other FHIR R4 server is covered by *Other FHIR server*; add named sources to the provider directory.

## Simulation and end-to-end validation

- `spec/scenarios.json` drives every program end to end: setup (every path and branch), daily function, rescue/safety routes with simulated readings (BP 186/122 → crisis, glucose 62 → low plan, peak flow 150 → red zone, “can’t speak in full sentences” → red, self-harm option → crisis), milestones, validation errors, sign-in variants and health-record flows.
- The **same scenarios** run in Flutter (`test/scenarios_test.dart`, real widgets, text typed into real fields) and in the prototype (**Simulator** tab: watch each one play, or run all).
- Decisions come from `rules.json`, implemented identically in `lib/logic/rules.dart` and the prototype. Visible choices (radio, segmented) decide their branch; external outcomes (permission prompts, OAuth, sign-in) are simulated.
- The **action sweep** taps every interactive element on every screen for every outcome (and with/without the onboarding context) and checks the destination, toast or platform call.

## Build from the develop branch

`spec/develop_mapping.json` lists the develop-branch file behind each screen and the logic to keep (Supabase auth, quit-plan + guest merge, encrypted program store, export/deletion receipt, safety copy, NestJS API). Swap widget bodies for the generated screens one at a time; keep controllers and API clients and connect them through `TApi`, `TAuth`, `TPlatform` and the session keys.

## Flows

| Flow | Screens | What it covers |
|---|---|---|
| [First run](flows/onboarding.md) | 10 | Welcome → choose programs → focus → consent → basics → set up each focus program → reminders → save progress → Today. |
| [Account & sign-in](flows/auth.md) | 13 | Sign up, verify email, sign in (with error), password reset, guest-plan merge, session expiry. |
| [Today](flows/today.md) | 7 | The shared home: Rescue first, one step per focus program, combined check-in, milestones and Learn-only lessons. Every state is specified. |
| [Universal Rescue](flows/rescue.md) | 6 | One entry for every Quit program. Opens the last helpful tool; offers a person when intensity stays high; distress always routes to 988. |
| [Plans & programs](flows/plans.md) | 5 | My plans hub, program catalog (the 11 programs from tetherhealthgroup.com), focus-slot rules and per-program settings. |
| [Progress, Learn & Support](flows/tabs.md) | 13 | Shared tabs that read every enrolment. |
| [Account & data](flows/account.md) | 12 | Settings, programs & sharing, notifications, privacy, export, deletion with receipt, sign out. |
| [System states](flows/system.md) | 2 | App-wide events: forced update. |
| [BreatheFree](flows/bf.md) | 17 | Tobacco & nicotine · Quit / Reduce. Four real quit paths, craving rescue, slip recovery, medication education. |
| [ScrollFree](flows/sf.md) | 15 | Social media use · Quit / Reduce. Self-report first, minute goal + app-free windows, Pause 60, buddy, weekly reflection. |
| [ClearAir](flows/ca.md) | 10 | Respiratory · Manage. Clinician action plan, zone check, yellow-zone steps with re-check, red-zone route, progress against own zones. |
| [Heartwise](flows/hw.md) | 13 | Cardiovascular · Manage. Clinician targets, two-reading BP log, validation, symptom-gated crisis route, trends, lipid panel, previewed visit summary. |
| [Steady](flows/st.md) | 9 | Diabetes & metabolic · Manage. Clinician range + own low plan, reading log, low route with 15-min timer, meal reset, patterns, A1C. |
| [Renew](flows/re.md) | 7 | Kidney & liver · Manage. Risk check, plain-language result, labs and trends, reminders, warning-symptom route. |
| [Nourish](flows/nu.md) | 7 | Obesity & nutrition · Build habits. Weight-neutral weekly habits, off-track reset, week-4 milestone, protective mode. |
| [Stride](flows/sd.md) | 8 | Healthy aging · Build habits. Falls check, weekly movement plan, audio-first sessions, I-fell route, home safety, scoped caregiver access. |
| [Ease](flows/ea.md) | 7 | Mental & behavioral · Support. Optional PHQ-2/GAD-2, never a diagnosis, safety plan, mood check-in, crisis route, check-back day. |
| [Checkup](flows/ck.md) | 7 | Preventive · Prevent. Personal due list from USPSTF/CDC guidance, item detail with options and cost, mark done, screening-day prep. |
| [Beacon](flows/be.md) | 8 | Cancer · Prevent. Four journey paths: lowering risk, in treatment, after treatment, caregiver. Fever rule on the treatment path. |
| [Health records (FHIR & manual)](flows/records.md) | 17 | Connect Epic MyChart, Oracle Health, Medicare Blue Button 2.0, Apple Health Records / Health Connect or any SMART on FHIR R4 server, or enter values by hand. Every value is validated (units, plausibility, duplicates, conflicts) and reviewed before it reaches a program. |
| [ScrollFree · Unplug](flows/unplug.md) | 28 | Optional app limits for ScrollFree: what Unplug can see, Screen Time / Android permissions, choosing apps, limits and the pause screen, focus sessions, the iPhone shield and Android overlay, the small-step gate, tracking check and turning it off. Every pause surface reaches Rescue. Entry: the Unplug card on ScrollFree home. Related states elsewhere: ScrollFree home (Unplug on), Weekly reflection (Unplug on), Program settings (ScrollFree), Connect Screen Time (Android). |
| [Home screen, Siri & shortcuts](flows/entries.md) | 6 | How Tether looks outside the app: the home-screen widget, Siri and App Shortcuts on iPhone, and launcher shortcuts and the widget on Android. Labels are generic by default; program names appear only when Show sensitive details is on. These are reference surfaces for the native widget and shortcut work, not app routes, and are excluded from release-check counts. |

## Not decided here

Clinical thresholds in `rules.json` follow published guidance but need sign-off from Tether’s clinical lead. Epic and Blue Button need app registration (open.epic / CMS sandbox, then production). Program names other than BreatheFree, ClearAir, Heartwise and Steady are working names. Backend choice is still open (develop-branch NestJS + Supabase vs Tether-Health-Backend); endpoints follow the develop branch plus new `records/fhir` routes.
