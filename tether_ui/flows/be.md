# Beacon

Cancer · Prevent. Four journey paths: lowering risk, in treatment, after treatment, caregiver. Fever rule on the treatment path.

```mermaid
flowchart LR
  be_intro["Beacon intro"]
  be_q1["Journey stage"]
  be_q2["Family history"]
  be_home["Beacon home"]
  be_tx["Treatment support"]
  be_diary["Treatment diary"]
  be_questions["Visit questions"]
  be_survivor["Survivorship"]
  be_intro -->|"Set up Beacon"| be_q1
  be_intro -->|"Add as Learn only"| plans
  be_q1 -->|"Next"| be_q2
  be_q1 -->|"Next"| be_tx
  be_q1 -->|"Next"| ob_setup
  be_q1 -->|"Next"| be_survivor
  be_q1 -->|"Next"| learn
  be_q2 -->|"See my plan"| be_home
  be_q2 -->|"See my plan"| ob_setup
  be_home -->|"Avatar · Account"| account
  be_home -->|"Quitting smoking"| bf_home
  be_home -->|"Monthly skin self-check"| learn_lesson
  be_home -->|"Ask about genetic counseling"| support_message_care
  be_home -->|"Open Checkup"| ck_list
  be_home -->|"Change my journey stage"| be_q1
  be_home -->|"Program settings"| program_settings
  be_tx -->|"Avatar · Account"| account
  be_tx -->|"Questions"| be_questions
  be_tx -->|"Today’s side-effect diary"| be_diary
  be_tx -->|"Feeling worried?"| ea_intro
  be_tx -->|"Program settings"| program_settings
  be_questions -->|"Share with my care team"| support_message_care
  be_survivor -->|"Avatar · Account"| account
  be_survivor -->|"Open Ease"| ea_intro
  be_survivor -->|"Program settings"| program_settings
  account>"Account ↗"]
  class account ext
  bf_home>"BreatheFree home ↗"]
  class bf_home ext
  ck_list>"Due list ↗"]
  class ck_list ext
  ea_intro>"Ease intro ↗"]
  class ea_intro ext
  learn>"Learn ↗"]
  class learn ext
  learn_lesson>"Lesson ↗"]
  class learn_lesson ext
  ob_setup>"Set up focus programs ↗"]
  class ob_setup ext
  plans>"My plans ↗"]
  class plans ext
  program_settings>"Program settings ↗"]
  class program_settings ext
  support_message_care>"Message care team ↗"]
  class support_message_care ext
  classDef ext fill:#FFFDF7,stroke:#B6C8C2,stroke-dasharray: 4 3
```

![Flow board](png/be.png)

## Screens

| Screen | Route | Kind / state | Phase |
|---|---|---|---|
| [Beacon intro](../screens/png/be/be_intro.png) | `/p/be` | screen | welcome |
| [Journey stage](../screens/png/be/be_q1.png) | `/p/be/onboarding/1` | screen | onboarding |
| [Family history](../screens/png/be/be_q2.png) | `/p/be/onboarding/2` | screen | onboarding |
| [Beacon home](../screens/png/be/be_home.png) | `/p/be/home` | screen | daily |
| [Treatment support](../screens/png/be/be_tx.png) | `/p/be/treatment` | screen | daily |
| [Treatment diary](../screens/png/be/be_diary.png) | `/p/be/diary` | screen | daily |
| [Visit questions](../screens/png/be/be_questions.png) | `/p/be/questions` | screen | milestone |
| [Survivorship](../screens/png/be/be_survivor.png) | `/p/be/survivorship` | screen | milestone |

## Button & action map

| Screen | Element | Action |
|---|---|---|
| Beacon intro | Back | `back` |
| Beacon intro | Set up Beacon | `push → be_q1` |
| Beacon intro | Add as Learn only | `toast “Beacon added as Learn only” then tab → plans` |
| Journey stage | Back | `back` |
| Journey stage | Next | `decide choice:be_q1.stage: Journey stage → Lowering my risk: push → be_q2 | Going through treatment: replace → be_tx (onboarding: ob_setup) | After treatment: replace → be_survivor (onboarding: ob_setup) | Supporting someone: tab → learn` |
| Family history | Back | `back` |
| Family history | See my plan | `PUT /v1/program-data/be/profile then replace → be_home (onboarding: ob_setup)` |
| Beacon home | Back | `back` |
| Beacon home | Avatar · Account | `push → account` |
| Beacon home | Quitting smoking | `push → bf_home` |
| Beacon home | Monthly skin self-check | `push → learn_lesson` |
| Beacon home | Ask about genetic counseling | `push → support_message_care` |
| Beacon home | Open Checkup | `push → ck_list` |
| Beacon home | Change my journey stage | `push → be_q1` |
| Beacon home | Program settings | `push → program_settings` |
| Beacon home | Tab · Today | `tab → today` |
| Beacon home | Tab · Progress | `tab → progress` |
| Beacon home | Tab · Learn | `tab → learn` |
| Beacon home | Tab · Support | `tab → support` |
| Treatment support | Back | `back` |
| Treatment support | Avatar · Account | `push → account` |
| Treatment support | Questions | `push → be_questions` |
| Treatment support | Call | `call (555) 010-7000` |
| Treatment support | Today’s side-effect diary | `push → be_diary` |
| Treatment support | Feeling worried? | `push → ea_intro` |
| Treatment support | Program settings | `push → program_settings` |
| Treatment support | Tab · Today | `tab → today` |
| Treatment support | Tab · Progress | `tab → progress` |
| Treatment support | Tab · Learn | `tab → learn` |
| Treatment support | Tab · Support | `tab → support` |
| Treatment diary | Back | `back` |
| Treatment diary | Call | `call (555) 010-7000` |
| Treatment diary | Save | `POST /v1/program-data/be/diary then toast “Saved” then back` |
| Visit questions | Back | `back` |
| Visit questions | Share with my care team | `push → support_message_care` |
| Visit questions | Done | `back` |
| Survivorship | Back | `back` |
| Survivorship | Avatar · Account | `push → account` |
| Survivorship | Open Ease | `push → ea_intro` |
| Survivorship | Program settings | `push → program_settings` |
| Survivorship | Save check-in | `POST /v1/program-data/be/survivorship then toast “Saved”` |
| Survivorship | Tab · Today | `tab → today` |
| Survivorship | Tab · Progress | `tab → progress` |
| Survivorship | Tab · Learn | `tab → learn` |
| Survivorship | Tab · Support | `tab → support` |
