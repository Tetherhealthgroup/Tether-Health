# Testing — BreatheFree

The ten-category matrix, one directory per category under `test/`, plus
`integration_test/` for e2e. The verification gate discovers categories by
directory name: use these names and the gate runs them, use different ones and
it reports the category NOT RUN because it found no runner.

| # | Category | Path | What belongs here |
|---|---|---|---|
| 1 | Unit | `test/unit/` | Pure functions and data. The 28-screen catalog, the approved contact routes, and tap-target geometry. No widgets, no I/O. |
| 2 | Integration | `test/integration/` | Choices crossing the screen/state boundary and surviving navigation away and back. |
| 3 | Functional | `test/functional/` | Each screen through the API a screen actually calls, including the contact dialogs and what they copy. |
| 4 | Smoke | `test/smoke/` | Does the app boot and reach its first and last surfaces. Runs first. |
| 5 | Regression | `test/regression/` | One case per defect actually fixed. Nothing speculative. |
| 6 | Acceptance | `test/acceptance/` | One case per user-facing outcome — principally that every control the approved artwork draws is reachable. |
| 7 | Security | `test/security/` | What the protected and safety-critical controls must never do: dial by themselves, write arbitrary text to the clipboard, or act on first tap. |
| 8 | UI | `test/ui/` | Rendered output across every supported phone size. |
| 9 | E2E | `integration_test/` | The whole app on a device, with real platform channels and real `MaterialLocalizations`. |
| 10 | Performance | `test/performance/` | Budgets for the work that repeats — tap-target resolution runs inside `build()`. |

## Running it

```bash
flutter test test/unit            # one category
flutter test test/                # every category except e2e

# E2E needs an attached device; there is no headless fallback.
flutter emulators --launch <avd>
flutter test integration_test/app_e2e_test.dart -d emulator-5554
```

## What the regression cases record

Each is a defect that shipped, with the mechanism that made it invisible.

- **`dead_dialog_controls_test.dart`** — `_BreatheFreeAppState` builds the
  `MaterialApp`, so its own `context` sits *above* it and carries neither a
  `Navigator` nor `MaterialLocalizations`. Every `showDialog` used that
  context and threw `No MaterialLocalizations found` instead of opening. Five
  controls looked live and did nothing: both quitlines, the call-back consent,
  the data export, the account deletion and sign-out. The test taps each and
  asserts a dialog is actually on screen.

- **`tab_bar_hit_test_test.dart`** — on screens 13-21 the Continue target ran
  to 0.89 while the tab bar starts at 0.875. The tab bar is added to the Stack
  later and so won the hit test, silently taking the lowest 0.015 of the
  primary action. Nothing looked wrong: the control was drawn in full, and a
  tap near its bottom edge navigated somewhere else. Both now read one
  `_tabBarTop` constant, and the test asserts the relationship rather than the
  constant.

The general "no two targets overlap" invariant lives in `test/unit/` instead,
because it applies to every screen and is pure geometry. It deflates each
rectangle before comparing: adjacent tabs share an edge, and `0.40 + 0.20`
evaluates to `0.6000000000000001` in binary floating point.

## Rules

- A test that cannot fail is not a test. Confirm it fails before the fix and
  passes after — every regression case above was run against the defect first.
- One case per acceptance criterion, minimum.
- Time budgets are set from a measurement, with the measured value recorded
  next to them, and deliberately loose. A tight budget on a shared runner
  fails for reasons unrelated to the code, and a suite that fails spuriously
  gets ignored.
- A category that genuinely cannot run is reported NOT RUN with the reason,
  never PASS and never dropped from the report.
