# System states

App-wide events: forced update.

```mermaid
flowchart LR
  sys_update(["Update required"])
  sys_update_android(["Update required (Android)"])
  sys_update -->|"Open Rescue"| rescue_pick
  sys_update_android -->|"Open Rescue"| rescue_pick
  rescue_pick>"Rescue ↗"]
  class rescue_pick ext
  classDef ext fill:#FFFDF7,stroke:#B6C8C2,stroke-dasharray: 4 3
```

![Flow board](png/system.png)

## Screens

| Screen | Route | Kind / state | Phase |
|---|---|---|---|
| [Update required](../screens/png/system/sys_update.png) | `/system/update` | fullscreen | account |
| [Update required (Android)](../screens/png/system/sys_update_android.png) | `/system/update?state=android` | fullscreen · android | account |

## Button & action map

| Screen | Element | Action |
|---|---|---|
| Update required | Update now | `external https://apps.apple.com/app/tether-health` |
| Update required | Open Rescue | `sheet → rescue_pick` |
| Update required (Android) | Update now | `external https://play.google.com/store/apps/details?id=com.TetherHealthLLC.tetherhealth` |
| Update required (Android) | Open Rescue | `sheet → rescue_pick` |
