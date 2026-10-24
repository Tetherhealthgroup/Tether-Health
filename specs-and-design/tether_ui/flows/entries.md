# Home screen, Siri & shortcuts

How Tether looks outside the app: the home-screen widget, Siri and App Shortcuts on iPhone, and launcher shortcuts and the widget on Android. Labels are generic by default; program names appear only when Show sensitive details is on. These are reference surfaces for the native widget and shortcut work, not app routes, and are excluded from release-check counts.

```mermaid
flowchart LR
  surface_widget_ios(["Home-screen widget (iPhone)"])
  surface_widget_android(["Home-screen widget (Android)"])
  surface_shortcuts_ios["Siri & App Shortcuts (iPhone)"]
  surface_shortcuts_ios_named["Siri & App Shortcuts (sensitive details on)"]
  surface_shortcuts_android["Launcher shortcuts (Android)"]
  surface_shortcuts_android_named["Launcher shortcuts (sensitive details on)"]
  surface_widget_ios -->|"Rescue"| rescue_pick
  surface_widget_android -->|"Rescue"| rescue_pick
  surface_shortcuts_ios -->|"Rescue"| rescue_pick
  surface_shortcuts_ios -->|"My plan"| ca_red
  surface_shortcuts_ios_named -->|"Rescue"| rescue_pick
  surface_shortcuts_ios_named -->|"ClearAir red-zone plan"| ca_red
  surface_shortcuts_android -->|"Rescue"| rescue_pick
  surface_shortcuts_android -->|"My plan"| ca_red
  surface_shortcuts_android_named -->|"Rescue"| rescue_pick
  surface_shortcuts_android_named -->|"ClearAir red-zone plan"| ca_red
  ca_red>"Red zone ↗"]
  class ca_red ext
  rescue_pick>"Rescue ↗"]
  class rescue_pick ext
  classDef ext fill:#FFFDF7,stroke:#B6C8C2,stroke-dasharray: 4 3
```

![Flow board](png/entries.png)

## Screens

| Screen | Route | Kind / state | Phase |
|---|---|---|---|
| [Home-screen widget (iPhone)](../screens/png/entries/surface_widget_ios.png) | `/surface/widget/ios` | fullscreen | rescue |
| [Home-screen widget (Android)](../screens/png/entries/surface_widget_android.png) | `/surface/widget/android` | fullscreen | rescue |
| [Siri & App Shortcuts (iPhone)](../screens/png/entries/surface_shortcuts_ios.png) | `/surface/shortcuts/ios` | screen | rescue |
| [Siri & App Shortcuts (sensitive details on)](../screens/png/entries/surface_shortcuts_ios_named.png) | `/surface/shortcuts/ios?state=named` | screen · Show sensitive details on | rescue |
| [Launcher shortcuts (Android)](../screens/png/entries/surface_shortcuts_android.png) | `/surface/shortcuts/android` | screen | rescue |
| [Launcher shortcuts (sensitive details on)](../screens/png/entries/surface_shortcuts_android_named.png) | `/surface/shortcuts/android?state=named` | screen · Show sensitive details on | rescue |

## Button & action map

| Screen | Element | Action |
|---|---|---|
| Home-screen widget (iPhone) | Close | `close` |
| Home-screen widget (iPhone) | Rescue | `sheet → rescue_pick` |
| Home-screen widget (Android) | Close | `close` |
| Home-screen widget (Android) | Rescue | `sheet → rescue_pick` |
| Siri & App Shortcuts (iPhone) | Close | `close` |
| Siri & App Shortcuts (iPhone) | Rescue | `sheet → rescue_pick` |
| Siri & App Shortcuts (iPhone) | My plan | `push → ca_red` |
| Siri & App Shortcuts (sensitive details on) | Close | `close` |
| Siri & App Shortcuts (sensitive details on) | Rescue | `sheet → rescue_pick` |
| Siri & App Shortcuts (sensitive details on) | ClearAir red-zone plan | `push → ca_red` |
| Launcher shortcuts (Android) | Close | `close` |
| Launcher shortcuts (Android) | Rescue | `sheet → rescue_pick` |
| Launcher shortcuts (Android) | My plan | `push → ca_red` |
| Launcher shortcuts (sensitive details on) | Close | `close` |
| Launcher shortcuts (sensitive details on) | Rescue | `sheet → rescue_pick` |
| Launcher shortcuts (sensitive details on) | ClearAir red-zone plan | `push → ca_red` |
