# Renew

Kidney & liver · Manage. Risk check, plain-language result, labs and trends, reminders, warning-symptom route.

```mermaid
flowchart LR
  re_intro["Renew intro"]
  re_q1["Risk check"]
  re_result["Risk result"]
  re_home["Renew home"]
  re_labs["Add labs"]
  re_history["Lab history"]
  re_symptoms["Symptom check"]
  re_intro -->|"Set up Renew"| re_q1
  re_intro -->|"Add as Learn only"| plans
  re_q1 -->|"See what this means"| re_result
  re_result -->|"Also see Heartwise and Stead"| catalog
  re_result -->|"Save my plan"| re_home
  re_result -->|"Save my plan"| ob_setup
  re_home -->|"Avatar · Account"| account
  re_home -->|"Add lab results"| re_labs
  re_home -->|"Lab history"| re_history
  re_home -->|"Check symptoms"| re_symptoms
  re_home -->|"Program settings"| program_settings
  re_labs -->|"Import from my health record"| records_add
  re_labs -->|"Save results"| re_history
  re_history -->|"Create visit summary"| hw_summary
  re_symptoms -->|"Contact my care team"| support_message_care
  account>"Account ↗"]
  class account ext
  catalog>"Add a program ↗"]
  class catalog ext
  hw_summary>"Visit summary ↗"]
  class hw_summary ext
  ob_setup>"Set up focus programs ↗"]
  class ob_setup ext
  plans>"My plans ↗"]
  class plans ext
  program_settings>"Program settings ↗"]
  class program_settings ext
  records_add>"Add a source ↗"]
  class records_add ext
  support_message_care>"Message care team ↗"]
  class support_message_care ext
  classDef ext fill:#FFFDF7,stroke:#B6C8C2,stroke-dasharray: 4 3
```

![Flow board](png/re.png)

## Screens

| Screen | Route | Kind / state | Phase |
|---|---|---|---|
| [Renew intro](../screens/png/re/re_intro.png) | `/p/re` | screen | welcome |
| [Risk check](../screens/png/re/re_q1.png) | `/p/re/onboarding/1` | screen | onboarding |
| [Risk result](../screens/png/re/re_result.png) | `/p/re/plan` | screen | plan |
| [Renew home](../screens/png/re/re_home.png) | `/p/re/home` | screen | daily |
| [Add labs](../screens/png/re/re_labs.png) | `/p/re/labs` | screen | milestone |
| [Lab history](../screens/png/re/re_history.png) | `/p/re/history` | screen | resources |
| [Symptom check](../screens/png/re/re_symptoms.png) | `/p/re/symptoms` | screen | rescue |

## Button & action map

| Screen | Element | Action |
|---|---|---|
| Renew intro | Back | `back` |
| Renew intro | Set up Renew | `push → re_q1` |
| Renew intro | Add as Learn only | `toast “Renew added as Learn only” then tab → plans` |
| Risk check | Back | `back` |
| Risk check | See what this means | `push → re_result` |
| Risk result | Back | `back` |
| Risk result | Also see Heartwise and Steady | `push → catalog` |
| Risk result | Save my plan | `PUT /v1/program-data/re/plan then replace → re_home (onboarding: ob_setup)` |
| Renew home | Back | `back` |
| Renew home | Avatar · Account | `push → account` |
| Renew home | Add lab results | `push → re_labs` |
| Renew home | Lab history | `push → re_history` |
| Renew home | Check symptoms | `push → re_symptoms` |
| Renew home | Program settings | `push → program_settings` |
| Renew home | Tab · Today | `tab → today` |
| Renew home | Tab · Progress | `tab → progress` |
| Renew home | Tab · Learn | `tab → learn` |
| Renew home | Tab · Support | `tab → support` |
| Add labs | Back | `back` |
| Add labs | Import from my health record | `push → records_add` |
| Add labs | Save results | `POST /v1/program-data/re/labs then toast “Saved” then replace → re_history` |
| Lab history | Back | `back` |
| Lab history | Create visit summary | `push → hw_summary` |
| Symptom check | Close | `close` |
| Symptom check | Contact my care team | `push → support_message_care` |
| Symptom check | Vomiting blood or confused? Call 911 | `call 911` |
