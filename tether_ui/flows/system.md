# System states

App-wide events: forced update.

```mermaid
flowchart LR
  sys_update(["Update required"])
  sys_update -->|"Open Rescue"| rescue_pick
  rescue_pick>"Rescue ↗"]
  class rescue_pick ext
  classDef ext fill:#FFFDF7,stroke:#B6C8C2,stroke-dasharray: 4 3
```

![Flow board](png/system.png)

## Screens

| Screen | Route | Kind / state | Phase |
|---|---|---|---|
| [Update required](../screens/png/system/sys_update.png) | `/system/update` | fullscreen | account |

## Button & action map

| Screen | Element | Action |
|---|---|---|
| Update required | Update now | `external https://apps.apple.com/app/tether-health` |
| Update required | Open Rescue | `sheet → rescue_pick` |
