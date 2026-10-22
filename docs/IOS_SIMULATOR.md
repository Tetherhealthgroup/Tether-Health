# iOS Simulator smoke check

`tool/ios_sim_smoke.sh` builds a debug app for the iOS Simulator, runs it on
one simulator, checks that it stays up, and saves screenshots. It is a local
development check on a Mac with Xcode. It runs no signing tool and passes no
signing option (Xcode's simulator build step may add its own local signature
to `Runner.app`), never builds for a phone, and sends nothing off the Mac.
Store builds are covered by [IOS_RELEASE.md](IOS_RELEASE.md).

## Run it

```sh
xcrun simctl list devices available       # pick an iOS Simulator
sh tool/ios_sim_smoke.sh --device="iPhone 17 Pro" --out=$HOME/sim-shots
sh tool/ios_sim_smoke.sh --device=<UDID> --out=$HOME/sim-shots --tether-ui
```

| Option | Meaning |
|---|---|
| `--device=<name\|UDID>` | Required. An available iOS Simulator from `xcrun simctl list devices available`. A name that matches several simulators picks the newest iOS runtime; if that runtime has several, pass the UDID. Anything else, including a phone's identifier, is refused before the build starts. |
| `--out=<dir>` | Required. Folder for the screenshots, outside the repository: the script refuses it if the repository root is the folder itself or any existing folder above it, compared by file identity (symlinks followed), before anything is created. If it does not exist, its parent must; the folder is then created. |
| `--tether-ui` | Builds with `--dart-define=TETHER_UI=true`, the debug-only tether_ui shell. No other define is accepted. |
| `--alive-seconds=<N>` | How long the app must stay up after launch, 5 to 600 (default 20). |
| `--keep-booted` | Leaves the simulator running. Without it, a simulator the script booted is shut down at the end; one that was already running is left running. |

## What it does

1. `flutter build ios --simulator --debug` (plus the TETHER_UI define with
   `--tether-ui`), then checks that `build/ios/iphonesimulator/Runner.app` is
   an iOS Simulator build with the bundle ID `com.TetherHealthLLC.tetherhealth`.
2. Boots the simulator with `xcrun simctl boot` if it is not running, and
   waits for it with `xcrun simctl bootstatus`.
3. Installs and launches the app with `xcrun simctl install` and
   `xcrun simctl launch`, waits `--alive-seconds`, and checks that the launched
   process is still running.
4. Saves four screenshots with `xcrun simctl io screenshot`, switching
   `xcrun simctl ui appearance` (light, dark) and `xcrun simctl ui
   content_size` (`large`, the default, and `accessibility-extra-large`):
   `<mode>-light-default-text.png`, `<mode>-light-ax-xl-text.png`,
   `<mode>-dark-default-text.png`, `<mode>-dark-ax-xl-text.png`, where
   `<mode>` is `legacy` or `tether_ui`. Each setting is read back before the
   screenshot, and the status bar clock is fixed at 9:41
   (`xcrun simctl status_bar override`) so screenshots differ only where the
   app does.
5. Checks the process again, reads the app's log with
   `xcrun simctl spawn <UDID> log show`, filtered to the launched process ID,
   and counts crash reports for the bundle ID written since launch.
6. On every exit, including a failed step or an interrupt: terminates the
   app, restores the simulator's status bar, appearance and text size, and
   shuts the simulator down only if the script booted it.

The text size changes while the app runs, so the screenshots show how the
current screen reflows; they do not replace the widget tests for large text.

## Output

The script prints the mode, the simulator UDID, whether the process was alive
after the wait and after the screenshots, the number of app log lines, the
number of native crash markers and Dart error markers in them, the number of
crash reports, and the screenshot file names. If the light and dark
default-text screenshots are byte-identical it says so: the screen on show
does not follow the dark appearance. It never prints log lines: they
can hold health data once someone signs in. Screenshots show whatever is on
screen, so use synthetic accounts only.

Exit codes: 0 the app stayed up; 1 a step failed, the process exited, a native
crash marker was logged, or a crash report was written; 2 usage error. Dart
error markers are reported but do not fail the run.

## Limits

- The simulator has no telephony: `tel:` and `sms:` links do not open, so the
  in-app call fallback is the expected path there. The script does not tap
  through screens, so it does not check that path.
- The simulator is not a phone: dialling, messaging, the Settings app link and
  mail links still need a check on a real device.
- `test/tool/ios_sim_smoke_test.dart` pins the script's safety rules and runs
  its argument and device checks with fake tools; it does not boot a simulator.
