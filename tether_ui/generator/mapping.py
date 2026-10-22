"""develop-branch → tether_ui mapping and the README."""
import json, os
from dsl import *

DEV = 'Tether-Health@develop'
DEVELOP_MAP = {
    'note': 'How the working prototype on the develop branch maps to these screens. Keep develop logic (controllers, API clients, secure storage); replace widget bodies with the generated screen + components, one screen at a time.',
    'screens': {
        'welcome': ['lib/screens/welcome_screen.dart'], 'bf_intro': ['lib/screens/why_breathefree_screen.dart'], 'ob_consent': ['lib/screens/consent_privacy_screen.dart'],
        'bf_q1': ['lib/screens/baseline_assessment_screen.dart'], 'bf_q2': ['lib/screens/trigger_map_screen.dart'], 'bf_q3': ['lib/screens/my_reasons_screen.dart'],
        'bf_path': ['lib/screens/readiness_result_screen.dart', 'lib/screens/choose_quit_path_screen.dart'], 'bf_date': ['lib/screens/select_quit_date_screen.dart'],
        'bf_support': ['lib/screens/support_preparation_screen.dart'], 'bf_review': ['lib/screens/review_quit_plan_screen.dart'], 'bf_home': ['lib/screens/home_preparation_screen.dart'],
        'checkin': ['lib/screens/daily_check_in_screen.dart'], 'checkin_done': ['lib/screens/personalized_next_step_screen.dart'],
        'rescue_pick': ['lib/screens/craving_rescue_start_screen.dart'], 'rescue_tools': ['lib/screens/recommended_rescue_tool_screen.dart'],
        'rescue_active': ['lib/screens/guided_stress_reset_screen.dart', 'lib/screens/active_craving_rescue_screen.dart'],
        'rescue_result': ['lib/screens/exercise_complete_recheck_screen.dart', 'lib/screens/craving_recheck_screen.dart', 'lib/screens/rescue_result_next_step_screen.dart'],
        'bf_home_quitday': ['lib/screens/quit_day_home_screen.dart'], 'bf_slip': ['lib/screens/slip_recovery_screen.dart'], 'bf_meds': ['lib/screens/medication_center_screen.dart'],
        'learn': ['lib/screens/learn_library_screen.dart'], 'progress': ['lib/screens/progress_dashboard_screen.dart'], 'bf_progress': ['lib/screens/progress_dashboard_screen.dart'],
        'support': ['lib/screens/support_hub_screen.dart'], 'account': ['lib/screens/settings_privacy_screen.dart'], 'account_privacy': ['lib/screens/settings_privacy_screen.dart'],
        'auth_signin': ['lib/widgets/sign_in_dialog.dart', 'lib/auth/auth_gateway.dart'], 'auth_forgot': ['lib/auth/password_recovery_screen.dart'], 'auth_newpass': ['lib/auth/password_recovery_screen.dart'],
        'auth_merge': ['lib/main.dart (_AccountConnectionScreen)', 'lib/quit_plan/guest_quit_plan_store.dart'], 'account_data': ['lib/widgets/account_data_dialogs.dart', 'lib/account/account_data_api_client.dart'],
        'account_delete': ['lib/widgets/account_data_dialogs.dart'], 'account_deleted': ['lib/account/account_deletion_receipt_store.dart'],
        'catalog': ['lib/programs/program_navigator.dart (ProgramSelectionScreen)'], 'program_settings': ['lib/programs/program_navigator.dart', 'lib/programs/secure_program_store.dart'],
        'ca_home': ['lib/programs/clearair/screens/clearair_home_screen.dart'], 'ca_zone': ['lib/programs/clearair/screens/zone_check_screen.dart'], 'ca_red': ['lib/programs/clearair/screens/red_zone_screen.dart'],
        'hw_home': ['lib/programs/heartwise/screens/heartwise_home_screen.dart'], 'hw_log': ['lib/programs/heartwise/screens/log_bp_screen.dart'], 'hw_lipids': ['lib/programs/heartwise/screens/cholesterol_panel_screen.dart'],
        'hw_crisis': ['lib/programs/heartwise/widgets/emergency_card.dart', 'lib/programs/heartwise/heartwise_safety.dart'],
        'st_home': ['lib/programs/steady/screens/steady_home_screen.dart'], 'st_log': ['lib/programs/steady/screens/log_reading_screen.dart'], 'st_reset': ['lib/programs/steady/screens/meal_energy_reset_screen.dart'],
    },
    'logic_kept': {
        'Auth (Supabase email, recovery, secure session)': 'lib/auth/account_controller.dart, auth_gateway.dart, secure_session_storage.dart → add Apple/Google via signInWithIdToken behind TAuth',
        'Quit plan + guest plan + merge': 'lib/quit_plan/*',
        'Program data, encrypted per account': 'lib/programs/secure_program_store.dart, program_data_api_client.dart',
        'Account export / deletion receipt': 'lib/account/*',
        'Safety copy (ClearAir, Heartwise, Steady)': 'lib/programs/*/*_safety.dart → spec text and rules.json',
        'NestJS API': 'api/src (profile, quit-plan, program-data, account) → endpoints named in spec actions; add enrolments, records/fhir',
    },
}

def readme(summary, edges):
    n = len(SCREENS)
    n_sheets = sum(1 for s in SCREENS.values() if s['kind'] == 'sheet')
    n_var = sum(1 for s in SCREENS.values() if s['variantOf'])
    fl = summary.get('flutter', {}); pr = summary.get('prototype', {})
    def frac(x): return f'{x[0]} / {x[1]}' if x else 'run validate_all.sh'
    flows_tbl = '\n'.join(f'| [{f["title"]}](flows/{fid}.md) | {len(f["screens"])} | {f["desc"]} |' for fid, f in FLOWS.items())
    return f"""# Tether Health · UI for development

Single source of truth for the Tether Health mobile app (iOS + Android, Flutter): **{n} screens and states**, **{len(FLOWS)} flows**, **{summary.get('actions', len(edges))} wired actions**, 11 programs, sign-in with **email, Apple and Google**, and **health records** from Epic, Medicare Blue Button and any SMART on FHIR server, or entered by hand.
Everything here is generated from one spec, so the design, the clickable prototype + simulator, the screenshots and the Flutter code always match.

## Validation (latest run)

| Check | Flutter | Prototype |
|---|---|---|
| End-to-end scenarios: setup and functions of every program, sign-in, health records | {frac(fl.get('scenarios'))} | {frac(pr.get('scenarios'))} |
| Button-flow sweep: every element × every outcome lands where the spec says | {frac(fl.get('action_sweep'))} | {frac(pr.get('action_sweep'))} |
| Render tests: every screen at 100% and 130% text, no overflow | {frac(fl.get('render_tests'))} | — |
| Static analysis | `flutter analyze`: no issues | JS errors: {pr.get('js_errors', '—')} |
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
│   ├── scenarios.json        ← {len(__import__('rules').SCENARIOS)} end-to-end scenarios with simulated data
│   ├── actions.json/.csv     ← flat button → action → target map
│   ├── develop_mapping.json  ← develop-branch file for each screen + logic to keep
│   ├── l10n/                 ← en.arb (generated English catalog, one key per visible string) + <locale>.arb (hand-maintained translations)
│   └── validation.md         ← spec validator output
├── flows/                    ← <flow>.md (Mermaid + button map) and png/ flow boards
├── screens/                  ← png/<flow>/<id>.png (1.5×), png/auth/android_*.png, sheets/<flow>.png
├── flutter/                  ← runnable package, zero third-party deps
│   ├── lib/ui/               ← components.dart, tokens.dart, nav.dart (all actions; TPlatform/TApi/TAuth hooks), strings.dart (TStrings)
│   ├── lib/l10n/             ← strings.g.dart: catalogs, release/draft locales, typed accessors (generated)
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
flutter run                                  # developer gallery of all {n} screens
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
{flows_tbl}

## Not decided here

Clinical thresholds in `rules.json` follow published guidance but need sign-off from Tether’s clinical lead. Epic and Blue Button need app registration (open.epic / CMS sandbox, then production). Program names other than BreatheFree, ClearAir, Heartwise and Steady are working names. Backend choice is still open (develop-branch NestJS + Supabase vs Tether-Health-Backend); endpoints follow the develop branch plus new `records/fhir` routes.
"""
