# Plans & programs

My plans hub, program catalog (the 11 programs from tetherhealthgroup.com), focus-slot rules and per-program settings.

```mermaid
flowchart LR
  plans["My plans"]
  catalog["Add a program"]
  focus_full{{"Focus slots full"}}
  program_settings["Program settings"]
  plans -->|"Avatar · Account"| account
  plans -->|"BreatheFree"| bf_home
  plans -->|"ScrollFree"| sf_home
  plans -->|"ClearAir"| ca_intro
  plans -->|"Medication center"| bf_meds
  plans -->|"Programs & sharing"| account_programs
  plans -->|"Add a program"| catalog
  catalog -->|"BreatheFree"| bf_intro
  catalog -->|"ScrollFree"| sf_intro
  catalog -->|"ClearAir"| ca_intro
  catalog -->|"Heartwise"| hw_intro
  catalog -->|"Steady"| st_intro
  catalog -->|"Renew"| re_intro
  catalog -->|"Nourish"| nu_intro
  catalog -->|"Stride"| sd_intro
  catalog -->|"Ease"| ea_intro
  catalog -->|"Checkup"| ck_intro
  catalog -->|"Beacon"| be_intro
  focus_full -->|"Continue"| plans
  focus_full -->|"Continue"| hw_q1
  program_settings -->|"Leave BreatheFree"| account_leave
  account>"Account ↗"]
  class account ext
  account_leave>"Leave a program ↗"]
  class account_leave ext
  account_programs>"Programs & sharing ↗"]
  class account_programs ext
  be_intro>"Beacon intro ↗"]
  class be_intro ext
  bf_home>"BreatheFree home ↗"]
  class bf_home ext
  bf_intro>"BreatheFree intro ↗"]
  class bf_intro ext
  bf_meds>"Medication center ↗"]
  class bf_meds ext
  ca_intro>"ClearAir intro ↗"]
  class ca_intro ext
  ck_intro>"Checkup intro ↗"]
  class ck_intro ext
  ea_intro>"Ease intro ↗"]
  class ea_intro ext
  hw_intro>"Heartwise intro ↗"]
  class hw_intro ext
  hw_q1>"Baseline ↗"]
  class hw_q1 ext
  nu_intro>"Nourish intro ↗"]
  class nu_intro ext
  re_intro>"Renew intro ↗"]
  class re_intro ext
  sd_intro>"Stride intro ↗"]
  class sd_intro ext
  sf_home>"ScrollFree home ↗"]
  class sf_home ext
  sf_intro>"ScrollFree intro ↗"]
  class sf_intro ext
  st_intro>"Steady intro ↗"]
  class st_intro ext
  classDef ext fill:#FFFDF7,stroke:#B6C8C2,stroke-dasharray: 4 3
```

![Flow board](png/plans.png)

## Screens

| Screen | Route | Kind / state | Phase |
|---|---|---|---|
| [My plans](../screens/png/plans/plans.png) | `/plans` | screen | plan |
| [Add a program](../screens/png/plans/catalog.png) | `/programs` | screen | welcome |
| [Focus slots full](../screens/png/plans/focus_full.png) | `/programs/focus-full` | sheet | plan |
| [Program settings](../screens/png/plans/program_settings.png) | `/p/:program/settings` | screen | account |

## Button & action map

| Screen | Element | Action |
|---|---|---|
| My plans | Avatar · Account | `push → account` |
| My plans | BreatheFree | `push → bf_home` |
| My plans | ScrollFree | `push → sf_home` |
| My plans | ClearAir | `push → ca_intro` |
| My plans | Medication center | `push → bf_meds` |
| My plans | Programs & sharing | `push → account_programs` |
| My plans | Add a program | `push → catalog` |
| My plans | Tab · Today | `tab → today` |
| My plans | Tab · Progress | `tab → progress` |
| My plans | Tab · Learn | `tab → learn` |
| My plans | Tab · Support | `tab → support` |
| Add a program | Back | `back` |
| Add a program | BreatheFree | `push → bf_intro` |
| Add a program | ScrollFree | `push → sf_intro` |
| Add a program | ClearAir | `push → ca_intro` |
| Add a program | Heartwise | `push → hw_intro` |
| Add a program | Steady | `push → st_intro` |
| Add a program | Renew | `push → re_intro` |
| Add a program | Nourish | `push → nu_intro` |
| Add a program | Stride | `push → sd_intro` |
| Add a program | Ease | `push → ea_intro` |
| Add a program | Checkup | `push → ck_intro` |
| Add a program | Beacon | `push → be_intro` |
| Focus slots full | Continue | `decide choice:focus_full.option: Chosen option → Learn only: toast “Heartwise added as Learn only” then tab → plans | Swap: replace → hw_q1` |
| Focus slots full | Cancel | `close` |
| Program settings | Back | `back` |
| Program settings | Export BreatheFree data | `toast “Export is being prepared. We’ll notify you.”` |
| Program settings | Leave BreatheFree | `sheet → account_leave` |
| Program settings | Save changes | `PATCH /v1/enrolments/:id then toast “Saved” then back` |
