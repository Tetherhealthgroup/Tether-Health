#!/bin/sh
# iOS Simulator smoke check for local development. Builds a debug app for the
# simulator, runs it on one iOS Simulator and saves screenshots. It runs no
# signing tool and passes no signing option (Xcode's simulator build step may
# add its own local signature), never builds for a phone, and sends nothing
# off this Mac.
#
# Usage: sh tool/ios_sim_smoke.sh --device=<name|UDID> --out=<dir>
#                                 [--tether-ui] [--alive-seconds=<N>]
#                                 [--keep-booted]
#
# --device=<name|UDID>
#                   An available iOS Simulator listed by
#                   `xcrun simctl list devices available`, by UDID or by name
#                   (for example "iPhone 17 Pro"). A name matching several
#                   simulators picks the newest iOS runtime; if that runtime
#                   still has several, pass the UDID. Anything not in that list
#                   (a phone's identifier, a typo) is refused before any build.
# --out=<dir>       Folder for the screenshots. It must be outside this
#                   repository. If it does not exist, its parent must, and the
#                   folder itself is created.
# --tether-ui       Build with --dart-define=TETHER_UI=true (the debug-only
#                   tether_ui shell). No other define is accepted.
# --alive-seconds=<N>
#                   How long the app must stay running after launch before the
#                   screenshots (5 to 600, default 20).
# --keep-booted     Leave the simulator running at the end. Without it a
#                   simulator this script booted is shut down again; one that
#                   was already running is left running.
#
# Steps: flutter build ios --simulator --debug, boot the simulator if needed,
# install and launch com.TetherHealthLLC.tetherhealth, wait, check the process
# is still alive, save four screenshots (light and dark appearance, each at the
# default text size and at accessibility-extra-large), check the process
# again, and count the app's log lines. The simulator's appearance and text
# size are restored afterwards.
#
# Log lines are filtered to the app's process ID and never printed: they can
# hold health data once someone signs in. Only counts are shown: total lines,
# native crash markers and Dart error markers. Screenshots show whatever is on
# screen; use synthetic accounts only.
#
# Errors never print an argument value or a path given as an argument.
#
# Exit codes: 0 the app stayed up, 1 a step failed or the app crashed,
# 2 usage error.
set -eu
# A set CDPATH makes cd print the directory and corrupt resolved paths.
unset CDPATH

bundle_id="com.TetherHealthLLC.tetherhealth"

device=""
device_given=0
out=""
out_given=0
tether_ui=0
alive_seconds=20
alive_given=0
keep_booted=0

fail() {
  echo "ios_sim_smoke: $1" >&2
  exit "${2:-1}"
}

# Rejects an unknown argument (exit 2) without echoing its value. Only an
# option-shaped name (--letters, digits, dashes) before the first '=' is shown.
unknown_argument() {
  case "$1" in
    --[A-Za-z0-9]*=*)
      case "${1%%=*}" in
        *[!A-Za-z0-9-]*) ;;
        *) fail "unknown argument: ${1%%=*}=<value not shown>" 2 ;;
      esac
      ;;
  esac
  fail "unknown argument (not shown; see the usage at the top of tool/ios_sim_smoke.sh)" 2
}

for arg in "$@"; do
  case "$arg" in
    --device=*)
      [ "$device_given" -eq 0 ] || fail "--device given more than once" 2
      device="${arg#--device=}"
      device_given=1
      ;;
    --out=*)
      [ "$out_given" -eq 0 ] || fail "--out given more than once" 2
      out="${arg#--out=}"
      out_given=1
      ;;
    --alive-seconds=*)
      [ "$alive_given" -eq 0 ] || fail "--alive-seconds given more than once" 2
      alive_seconds="${arg#--alive-seconds=}"
      alive_given=1
      ;;
    --tether-ui) tether_ui=1 ;;
    --keep-booted) keep_booted=1 ;;
    *) unknown_argument "$arg" ;;
  esac
done

[ "$device_given" -eq 1 ] || fail "--device=<name|UDID> is required" 2
[ -n "$device" ] || fail "--device requires a simulator name or UDID" 2
case "$device" in
  *[!A-Za-z0-9\ ._\(\)-]*) fail "--device may hold only letters, digits, spaces and . _ ( ) - (value not shown)" 2 ;;
esac
[ "$out_given" -eq 1 ] || fail "--out=<dir> is required" 2
[ -n "$out" ] || fail "--out requires a folder path" 2
case "$alive_seconds" in
  '' | *[!0-9]*) fail "--alive-seconds must be a whole number from 5 to 600" 2 ;;
esac
if [ "${#alive_seconds}" -gt 3 ] || [ "$alive_seconds" -lt 5 ] || [ "$alive_seconds" -gt 600 ]; then
  fail "--alive-seconds must be a whole number from 5 to 600" 2
fi

repo_root=$(cd "$(dirname "$0")/.." && pwd -P) || fail "cannot resolve the repository root"

# The output folder must be outside the repository, checked on the resolved
# path (symlinks followed) before anything is created.
case "$out" in
  *'
'*) fail "--out contains a line break (path not shown)" 2 ;;
esac
if [ -d "$out" ]; then
  out_real=$(cd "$out" && pwd -P) || fail "cannot resolve --out (path not shown)" 2
else
  out_parent=$(dirname "$out")
  [ -d "$out_parent" ] || fail "the parent folder of --out does not exist (path not shown)" 2
  out_parent_real=$(cd "$out_parent" && pwd -P) || fail "cannot resolve --out (path not shown)" 2
  out_real="${out_parent_real%/}/$(basename "$out")"
fi
case "$out_real/" in
  "$repo_root"/*) fail "--out is inside the repository. Use a folder outside it." 2 ;;
esac
# The same check by file identity, so that another spelling of a folder in the
# repository is refused too: no existing folder on the path to --out may be
# the repository root.
out_ancestor="$out_real"
while :; do
  if [ -e "$out_ancestor" ] && [ "$out_ancestor" -ef "$repo_root" ]; then
    fail "--out is inside the repository. Use a folder outside it." 2
  fi
  [ "$out_ancestor" != "/" ] || break
  out_ancestor=$(dirname "$out_ancestor")
done

[ "$(uname -s)" = "Darwin" ] || fail "the iOS Simulator needs macOS with Xcode."
command -v xcrun >/dev/null 2>&1 || fail "xcrun not found on PATH (Xcode is required)."
command -v flutter >/dev/null 2>&1 || fail "flutter not found on PATH."
command -v python3 >/dev/null 2>&1 || fail "python3 not found on PATH."

# Resolves --device against the available iOS Simulators only. Prints
# "<UDID> <state>" or exits 3 (no match) or 4 (ambiguous name).
resolve_device() {
  SMOKE_DEVICE="$device" python3 -I -c '
import json, os, re, sys
want = os.environ["SMOKE_DEVICE"]
rows = []
for runtime, devices in json.load(sys.stdin).get("devices", {}).items():
    m = re.fullmatch(r"com\.apple\.CoreSimulator\.SimRuntime\.iOS-(\d+)-(\d+)(?:-(\d+))?", runtime)
    if not m:
        continue
    version = tuple(int(x or 0) for x in m.groups())
    for d in devices:
        if d.get("isAvailable") is True:
            rows.append((version, d.get("udid", ""), d.get("state", ""), d.get("name", "")))
by_udid = [r for r in rows if r[1] == want]
if not by_udid:
    by_name = [r for r in rows if r[3] == want]
    if not by_name:
        sys.exit(3)
    newest = max(r[0] for r in by_name)
    by_udid = [r for r in by_name if r[0] == newest]
    if len(by_udid) > 1:
        sys.exit(4)
udid, state = by_udid[0][1], by_udid[0][2]
if not re.fullmatch(r"[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}", udid):
    sys.exit(3)
print(udid + " " + state)
'
}

simulators=$(xcrun simctl list devices available -j) || fail "xcrun simctl list devices available failed."
resolve_status=0
resolved=$(printf '%s' "$simulators" | resolve_device) || resolve_status=$?
case "$resolve_status" in
  0) ;;
  3) fail "--device is not an available iOS Simulator listed by 'xcrun simctl list devices available' (value not shown). Physical devices are never used." 2 ;;
  4) fail "--device names several simulators on the newest iOS runtime; pass the UDID instead." 2 ;;
  *) fail "cannot read the simulator list." ;;
esac
udid="${resolved%% *}"
state="${resolved#* }"

[ -d "$out_real" ] || mkdir "$out_real" || fail "cannot create the --out folder (path not shown)."

tmp=$(mktemp -d) || fail "cannot create a temporary folder."
chmod 700 "$tmp"
log_file="$tmp/app.log"
booted_here=0
launched=0
saved_appearance=""
saved_content_size=""
status_bar_set=0

# Runs on every exit, including a failed step, INT and TERM: stops the app,
# restores the simulator's settings, then shuts down only a simulator this
# script booted.
cleanup() {
  status=$?
  if [ "$launched" -eq 1 ]; then
    xcrun simctl terminate "$udid" "$bundle_id" >/dev/null 2>&1 || true
  fi
  if [ "$status_bar_set" -eq 1 ]; then
    xcrun simctl status_bar "$udid" clear >/dev/null 2>&1 || true
  fi
  if [ -n "$saved_appearance" ]; then
    xcrun simctl ui "$udid" appearance "$saved_appearance" >/dev/null 2>&1 || true
  fi
  if [ -n "$saved_content_size" ]; then
    xcrun simctl ui "$udid" content_size "$saved_content_size" >/dev/null 2>&1 || true
  fi
  if [ "$booted_here" -eq 1 ] && [ "$keep_booted" -eq 0 ]; then
    xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cd "$repo_root"
if [ "$tether_ui" -eq 1 ]; then
  mode="tether_ui"
  echo "== flutter build ios --simulator --debug --dart-define=TETHER_UI=true"
  flutter build ios --simulator --debug --dart-define=TETHER_UI=true || fail "flutter build failed."
else
  mode="legacy"
  echo "== flutter build ios --simulator --debug"
  flutter build ios --simulator --debug || fail "flutter build failed."
fi

app="$repo_root/build/ios/iphonesimulator/Runner.app"
[ -d "$app" ] || fail "the simulator build did not produce build/ios/iphonesimulator/Runner.app."
# Prints one value from the built app's Info.plist: a string, or the first
# item of an array. Exits non-zero if it is missing or not a string.
plist_value() {
  python3 -I -c '
import plistlib, sys
try:
    with open(sys.argv[1], "rb") as f:
        value = plistlib.load(f).get(sys.argv[2])
except Exception:
    sys.exit(1)
if isinstance(value, list):
    value = value[0] if value else None
if not isinstance(value, str):
    sys.exit(1)
print(value)
' "$app/Info.plist" "$1"
}
[ "$(plist_value CFBundleIdentifier 2>/dev/null)" = "$bundle_id" ] ||
  fail "the built app's bundle identifier is not $bundle_id."
[ "$(plist_value CFBundleSupportedPlatforms 2>/dev/null)" = "iPhoneSimulator" ] ||
  fail "the built app is not an iOS Simulator build."

if [ "$state" != "Booted" ]; then
  echo "== xcrun simctl boot"
  xcrun simctl boot "$udid" || fail "xcrun simctl boot failed."
  booted_here=1
fi
xcrun simctl bootstatus "$udid" -b >/dev/null || fail "the simulator did not finish booting."

saved_appearance=$(xcrun simctl ui "$udid" appearance 2>/dev/null) || saved_appearance=""
case "$saved_appearance" in light | dark) ;; *) saved_appearance="" ;; esac
saved_content_size=$(xcrun simctl ui "$udid" content_size 2>/dev/null) || saved_content_size=""
case "$saved_content_size" in *[!a-z-]* | '') saved_content_size="" ;; esac

echo "== xcrun simctl install"
xcrun simctl install "$udid" "$app" || fail "xcrun simctl install failed."
xcrun simctl ui "$udid" appearance light || fail "cannot set the simulator appearance."
xcrun simctl ui "$udid" content_size large || fail "cannot set the simulator text size."
# A fixed status bar clock, so screenshots differ only where the app does.
status_bar_set=1
xcrun simctl status_bar "$udid" override --time 9:41 || fail "cannot set the simulator status bar."

marker="$tmp/launched"
: >"$marker"
log_start=$(date '+%Y-%m-%d %H:%M:%S')
echo "== xcrun simctl launch $bundle_id"
launched=1
launch_output=$(xcrun simctl launch --terminate-running-process "$udid" "$bundle_id") ||
  fail "xcrun simctl launch failed."
pid="${launch_output##*: }"
case "$pid" in
  '' | *[!0-9]*) fail "xcrun simctl launch did not report a process ID." ;;
esac

# The app is alive while its launch PID still runs the built Runner binary.
app_alive() {
  case "$(ps -p "$pid" -o comm= 2>/dev/null)" in
    */Runner.app/Runner) return 0 ;;
    *) return 1 ;;
  esac
}

alive_first=0
alive_last=0
shots=""
echo "== waiting ${alive_seconds}s"
sleep "$alive_seconds"
if app_alive; then
  alive_first=1
  for appearance in light dark; do
    for size in large accessibility-extra-large; do
      xcrun simctl ui "$udid" appearance "$appearance" || fail "cannot set the simulator appearance."
      xcrun simctl ui "$udid" content_size "$size" || fail "cannot set the simulator text size."
      [ "$(xcrun simctl ui "$udid" appearance)" = "$appearance" ] ||
        fail "the simulator does not report the requested appearance."
      [ "$(xcrun simctl ui "$udid" content_size)" = "$size" ] ||
        fail "the simulator does not report the requested text size."
      sleep 3
      case "$size" in large) size_label="default-text" ;; *) size_label="ax-xl-text" ;; esac
      shot="$mode-$appearance-$size_label.png"
      xcrun simctl io "$udid" screenshot --type=png "$out_real/$shot" >/dev/null 2>&1 ||
        fail "xcrun simctl io screenshot failed."
      shots="$shots $shot"
    done
  done
  sleep 2
  if app_alive; then alive_last=1; fi
fi

# Count the app process's log lines; the lines themselves are never printed.
xcrun simctl spawn "$udid" log show --style ndjson --start "$log_start" \
  --predicate "processIdentifier == $pid" >"$log_file" 2>/dev/null || : >"$log_file"
log_lines=$(grep -c '^{' "$log_file" || true)
fatal_markers=$(grep -c -e 'Terminating app due to uncaught exception' -e 'EXC_BAD_ACCESS' \
  -e 'EXC_CRASH' -e 'SIGABRT' -e 'SIGSEGV' -e 'Fatal error' "$log_file" || true)
dart_markers=$(grep -c -e 'Unhandled Exception' -e 'EXCEPTION CAUGHT BY' "$log_file" || true)
rm -f "$log_file"

# Crash reports written since launch whose header names the app's bundle ID.
crash_reports=0
reports_dir="$HOME/Library/Logs/DiagnosticReports"
if [ -d "$reports_dir" ]; then
  crash_reports=$(find "$reports_dir" -maxdepth 1 -type f -name '*.ips' -newer "$marker" \
    -exec head -n 1 {} \; 2>/dev/null | grep -c "\"bundleID\":\"$bundle_id\"" || true)
fi

echo "mode: $mode"
echo "simulator: $udid"
echo "process $pid alive after ${alive_seconds}s: $([ "$alive_first" -eq 1 ] && echo yes || echo no)"
echo "process $pid alive after screenshots: $([ "$alive_last" -eq 1 ] && echo yes || echo no)"
echo "app log lines: $log_lines; native crash markers: $fatal_markers; Dart error markers: $dart_markers (lines not shown)"
echo "crash reports for $bundle_id since launch: $crash_reports"
echo "screenshots in the --out folder:${shots:- none}"
if [ -n "$shots" ] && cmp -s "$out_real/$mode-light-default-text.png" "$out_real/$mode-dark-default-text.png"; then
  echo "note: the light and dark screenshots are identical; the screen does not follow the dark appearance."
fi

if [ "$alive_first" -ne 1 ] || [ "$alive_last" -ne 1 ] || [ "$fatal_markers" -ne 0 ] || [ "$crash_reports" -ne 0 ]; then
  fail "FAIL: the app crashed or exited."
fi
echo "PASS: the app stayed up."
