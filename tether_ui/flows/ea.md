# Ease

Mental & behavioral · Support. Optional PHQ-2/GAD-2, never a diagnosis, safety plan, mood check-in, crisis route, check-back day.

```mermaid
flowchart LR
  ea_intro["Ease intro"]
  ea_q1["Optional screener"]
  ea_result["Screener result"]
  ea_plan["Safety plan"]
  ea_home["Ease home"]
  ea_mood["Mood check-in"]
  ea_checkback["Check-back day"]
  ea_intro -->|"Set up Ease"| ea_q1
  ea_intro -->|"Add as Learn only"| plans
  ea_q1 -->|"Next"| ea_result
  ea_q1 -->|"Skip the check"| ea_plan
  ea_result -->|"Talk to my primary care doct"| support_message_care
  ea_result -->|"Not now"| ea_plan
  ea_result -->|"Call or text 988"| crisis
  ea_plan -->|"Save plan"| ea_home
  ea_plan -->|"Save plan"| ob_setup
  ea_home -->|"Avatar · Account"| account
  ea_home -->|"Start"| ea_mood
  ea_home -->|"My safety plan"| ea_plan
  ea_home -->|"Check-back"| ea_checkback
  ea_home -->|"Find a professional"| ea_result
  ea_home -->|"Program settings"| program_settings
  ea_home -->|"Sleep and mood: 3 small chan"| learn_lesson
  ea_home -->|"Call or text 988"| crisis
  ea_mood -->|"Start"| rescue_active
  ea_mood -->|"Save"| crisis
  ea_checkback -->|"Show me"| learn_lesson
  account>"Account ↗"]
  class account ext
  crisis>"Crisis support ↗"]
  class crisis ext
  learn_lesson>"Lesson ↗"]
  class learn_lesson ext
  ob_setup>"Set up focus programs ↗"]
  class ob_setup ext
  plans>"My plans ↗"]
  class plans ext
  program_settings>"Program settings ↗"]
  class program_settings ext
  rescue_active>"Active tool ↗"]
  class rescue_active ext
  support_message_care>"Message care team ↗"]
  class support_message_care ext
  classDef ext fill:#FFFDF7,stroke:#B6C8C2,stroke-dasharray: 4 3
```

![Flow board](png/ea.png)

## Screens

| Screen | Route | Kind / state | Phase |
|---|---|---|---|
| [Ease intro](../screens/png/ea/ea_intro.png) | `/p/ea` | screen | welcome |
| [Optional screener](../screens/png/ea/ea_q1.png) | `/p/ea/onboarding/1` | screen | onboarding |
| [Screener result](../screens/png/ea/ea_result.png) | `/p/ea/result` | screen | onboarding |
| [Safety plan](../screens/png/ea/ea_plan.png) | `/p/ea/plan` | screen | plan |
| [Ease home](../screens/png/ea/ea_home.png) | `/p/ea/home` | screen | daily |
| [Mood check-in](../screens/png/ea/ea_mood.png) | `/p/ea/mood` | screen | daily |
| [Check-back day](../screens/png/ea/ea_checkback.png) | `/p/ea/check-back` | screen | milestone |

## Button & action map

| Screen | Element | Action |
|---|---|---|
| Ease intro | Back | `back` |
| Ease intro | Set up Ease | `push → ea_q1` |
| Ease intro | Add as Learn only | `POST /v1/enrolments then toast “Ease added as Learn only” then tab → plans` |
| Optional screener | Back | `back` |
| Optional screener | Next | `push → ea_result` |
| Optional screener | Skip the check | `push → ea_plan` |
| Screener result | Back | `back` |
| Screener result | Find a therapist near me | `external https://findtreatment.gov` |
| Screener result | Talk to my primary care doctor | `push → support_message_care` |
| Screener result | Not now | `push → ea_plan` |
| Screener result | Call or text 988 | `push → crisis` |
| Screener result | Call 911 | `call 911` |
| Safety plan | Back | `back` |
| Safety plan | Save plan | `PUT device:encrypted/ea/safety-plan then replace → ea_home (onboarding: ob_setup)` |
| Ease home | Back | `back` |
| Ease home | Avatar · Account | `push → account` |
| Ease home | Start | `push → ea_mood` |
| Ease home | My safety plan | `push → ea_plan` |
| Ease home | Check-back | `push → ea_checkback` |
| Ease home | Find a professional | `push → ea_result` |
| Ease home | Program settings | `push → program_settings` |
| Ease home | Sleep and mood: 3 small changes | `push → learn_lesson` |
| Ease home | Call or text 988 | `push → crisis` |
| Ease home | Call 911 | `call 911` |
| Ease home | Tab · Today | `tab → today` |
| Ease home | Tab · Progress | `tab → progress` |
| Ease home | Tab · Learn | `tab → learn` |
| Ease home | Tab · Support | `tab → support` |
| Mood check-in | Back | `back` |
| Mood check-in | Start | `push → rescue_active` |
| Mood check-in | Save | `POST /v1/program-data/ea/moods then decide ea.selfharm: Self-harm option selected? → No: toast “Saved” then back | Yes: replace → crisis` |
| Check-back day | Back | `back` |
| Check-back day | Show me | `push → learn_lesson` |
| Check-back day | Save | `POST /v1/program-data/ea/check-backs then toast “Saved” then back` |
