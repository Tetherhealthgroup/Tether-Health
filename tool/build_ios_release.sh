#!/bin/sh
# Builds an iOS App Store IPA. Never signs with repo secrets, uploads or
# submits anything. iOS counterpart of tool/build_play_release.sh.
#
# Usage: sh tool/build_ios_release.sh --dart-define-from-file=<path>
#          [--build-number N] [--check-only]
#        sh tool/build_ios_release.sh --inspect-ipa=<path>
#
# --dart-define-from-file=<path>
#                   Release define file (see docs/PLAY_RELEASE.md section 3).
#                   Required unless --inspect-ipa is given. A relative path is
#                   resolved against the caller's working directory. Before any
#                   build step the file must be a JSON object holding only
#                   https SUPABASE_URL and API_BASE_URL (no .invalid host, user
#                   info, query or fragment; SUPABASE_URL without a path) and
#                   a SUPABASE_ANON_KEY that is an sb_publishable_ key or an
#                   anon JWT (allowlist, TH-904); the rules live in
#                   tool/release_define_check.sh, shared with the Play script.
#                   No value from the file is ever printed.
# --build-number N  Build number (CFBundleVersion) of the IPA, passed to
#                   flutter build ipa; overrides the pubspec.yaml number. Each
#                   TestFlight upload needs a higher number than the last. N
#                   must be a positive integer (at most 2100000000, the Play
#                   limit, so one number can serve both stores) and not below
#                   the pubspec.yaml build number; either failure stops the
#                   script before any build step. After the build, the IPA's
#                   CFBundleVersion must equal N. Without it, the pubspec.yaml
#                   number is used as before.
# --check-only      Run every pre-build check (arguments, CocoaPods, define
#                   file, and with --build-number the build number, which it
#                   prints), then exit 0 if all pass or non-zero if any fails.
#                   Never runs flutter and never builds.
# --inspect-ipa=<path>
#                   Print CFBundleShortVersionString and CFBundleVersion of an
#                   existing IPA, then exit. Never builds.
#
# The project uses Swift Package Manager: the script refuses to run if
# ios/Podfile exists or ios/Runner.xcodeproj/project.pbxproj or
# ios/Flutter/*.xcconfig reference CocoaPods. Discard such files, never commit
# them.
#
# Without --check-only it runs sh tool/check_format.sh, flutter analyze and
# flutter test, then flutter build ipa --release with the define file, and
# prints the IPA path and its version fields. Signing uses the Xcode project's
# Automatic signing (the DEVELOPMENT_TEAM in project.pbxproj) on the build Mac;
# this script adds no certificate, provisioning profile or export options.
#
# Errors never print an argument value or a path given as an argument (it may
# hold a pasted secret or terminal control bytes); they name the option. Only
# values validated as numbers are echoed.
#
# Exit codes: 0 success, 1 a check or build step failed, 2 usage error.
set -eu
# A set CDPATH makes cd print the directory and corrupt resolved paths.
unset CDPATH

env_file=""
env_file_given=0
check_only=0
inspect_ipa=""
inspect_ipa_given=0
build_number=""
build_number_given=0
max_build_number=2100000000 # the Play limit (tool/build_play_release.sh)

fail() {
  echo "build_ios_release: $1" >&2
  exit "${2:-1}"
}

# Rejects an unknown argument (exit 2) without echoing its value: a key typed
# on the command line must not reach terminal or CI logs. Only an option-shaped
# name (--letters, digits, dashes) before the first '=' is shown.
unknown_argument() {
  case "$1" in
    --[A-Za-z0-9]*=*)
      case "${1%%=*}" in
        *[!A-Za-z0-9-]*) ;;
        *) fail "unknown argument: ${1%%=*}=<value not shown>" 2 ;;
      esac
      ;;
  esac
  fail "unknown argument (not shown; see the usage at the top of tool/build_ios_release.sh)" 2
}

# Prints $1 without leading zeros (0099 is 99, not octal); empty if all zeros.
strip_zeros() {
  printf '%s\n' "${1#"${1%%[!0]*}"}"
}

# Succeeds if $1 is a positive integer no larger than $max_build_number. Checks
# the digit length first so a huge value never reaches shell arithmetic.
is_valid_build_number() {
  case "$1" in
    "" | *[!0-9]*) return 1 ;;
  esac
  ivb_value="$(strip_zeros "$1")"
  [ -n "$ivb_value" ] && [ "${#ivb_value}" -le 10 ] && [ "$ivb_value" -le "$max_build_number" ]
}

# Records the --build-number value; exits 2 if repeated, not a positive
# integer or out of range. The value is never echoed here.
set_build_number() {
  [ "$build_number_given" -eq 0 ] || fail "--build-number given more than once" 2
  build_number_given=1
  case "$1" in
    "" | *[!0-9]*) fail "--build-number must be a positive integer (value not shown)" 2 ;;
  esac
  is_valid_build_number "$1" || fail "--build-number must be between 1 and $max_build_number" 2
  build_number="$(strip_zeros "$1")"
}

while [ "$#" -gt 0 ]; do
  arg="$1"
  case "$arg" in
    --dart-define-from-file=*)
      [ "$env_file_given" -eq 0 ] || fail "--dart-define-from-file given more than once" 2
      env_file="${arg#--dart-define-from-file=}"
      env_file_given=1
      ;;
    --build-number)
      [ "$#" -ge 2 ] || fail "--build-number requires a value" 2
      shift
      set_build_number "$1"
      ;;
    --build-number=*) set_build_number "${arg#--build-number=}" ;;
    --check-only) check_only=1 ;;
    --inspect-ipa=*)
      inspect_ipa="${arg#--inspect-ipa=}"
      inspect_ipa_given=1
      ;;
    *) unknown_argument "$arg" ;;
  esac
  shift
done

# Resolve file arguments against the caller's working directory, then make them
# absolute before changing directory (a relative path must never be silently
# re-read against the repo root). The path is only prefixed with $PWD: no cd,
# dirname or basename, so the file used is exactly the one `[ -f ]` checked (cd
# would resolve `link/..` logically, treat a directory named -P or - as an
# option, and `$(...)` would strip a trailing newline) and no argument byte is
# echoed in a tool's error message.

if [ "$inspect_ipa_given" -eq 1 ]; then
  if [ "$env_file_given" -eq 1 ] || [ "$check_only" -eq 1 ] || [ "$build_number_given" -eq 1 ]; then
    fail "--inspect-ipa cannot be combined with other arguments" 2
  fi
  [ -n "$inspect_ipa" ] || fail "--inspect-ipa requires a path" 2
  [ -f "$inspect_ipa" ] || fail "IPA not found (path given to --inspect-ipa not shown)" 2
  case "$inspect_ipa" in /*) ;; *) inspect_ipa="$PWD/$inspect_ipa" ;; esac
else
  [ -n "$env_file" ] || fail "--dart-define-from-file=<path> is required" 2
  [ -f "$env_file" ] || fail "define file not found (path given to --dart-define-from-file not shown)" 2
  case "$env_file" in /*) ;; *) env_file="$PWD/$env_file" ;; esac
fi

# Run from the repo root (the script's parent directory).
cd "$(dirname "$0")/.."

# Prints CFBundleShortVersionString and CFBundleVersion from the app's own
# Info.plist (Payload/<app>.app/Info.plist, not a framework's) inside an IPA.
# Fails (exit 1) if the IPA or either value cannot be read, or if $2 is given
# and CFBundleVersion is not exactly $2.
print_ipa_version() {
  python3 -I - "$@" <<'PY' || exit 1
import plistlib, re, sys, zipfile
import xml.parsers.expat

path = sys.argv[1]
expected = sys.argv[2] if len(sys.argv) > 2 else None
try:
    with zipfile.ZipFile(path) as ipa:
        names = [n for n in ipa.namelist() if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", n)]
        if len(names) != 1:
            sys.exit(f"build_ios_release: expected one Payload/<app>.app/Info.plist in the IPA, found {len(names)}")
        info = plistlib.loads(ipa.read(names[0]))
except (OSError, zipfile.BadZipFile, plistlib.InvalidFileException, ValueError, xml.parsers.expat.ExpatError) as exc:
    sys.exit(f"build_ios_release: cannot read the IPA's Info.plist: {type(exc).__name__}")
values = [info.get(k) if isinstance(info, dict) else None for k in ("CFBundleShortVersionString", "CFBundleVersion")]
if not all(isinstance(v, str) and v.strip() for v in values):
    sys.exit("build_ios_release: CFBundleShortVersionString or CFBundleVersion missing in the IPA")
print(f"CFBundleShortVersionString: {values[0]}")
print(f"CFBundleVersion: {values[1]}")
if expected is not None and values[1] != expected:
    sys.exit(f"build_ios_release: the IPA's CFBundleVersion is not {expected} (the --build-number given); do not upload it")
PY
}

# With --build-number, prints the build number (CFBundleVersion) the IPA will
# get and fails (exit 1) unless pubspec.yaml has a +<build number> and the
# given number is not below it. Without it, does nothing (output unchanged).
check_build_number() {
  [ -n "$build_number" ] || return 0
  pubspec_build=""
  if [ -f pubspec.yaml ]; then
    pubspec_version="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1 | tr -d '[:space:]')"
    case "$pubspec_version" in
      *+*) pubspec_build="${pubspec_version##*+}" ;;
    esac
  fi
  if ! is_valid_build_number "$pubspec_build"; then
    fail "pubspec.yaml version has no +<build number> between 1 and $max_build_number; cannot check --build-number against it."
  fi
  pubspec_build="$(strip_zeros "$pubspec_build")"
  echo "CFBundleVersion: $build_number (from --build-number; overrides pubspec.yaml); minimum $pubspec_build (the pubspec.yaml build number)"
  if [ "$build_number" -lt "$pubspec_build" ]; then
    fail "--build-number $build_number is below the minimum $pubspec_build (the pubspec.yaml build number)."
  fi
}

# Succeeds if file $2 matches extended regex $1, returns 1 if not, and fails
# (exit 1) if the file cannot be read, so a grep error never passes the guard.
file_matches() {
  grep_status=0
  grep -qE "$1" "$2" || grep_status=$?
  [ "$grep_status" -le 1 ] || fail "cannot read $2"
  return "$grep_status"
}

# Fails (exit 1) if any CocoaPods integration is present (SPM-only project).
check_no_cocoapods() {
  if [ -e ios/Podfile ]; then
    fail "ios/Podfile exists; this project uses Swift Package Manager. Remove it (do not commit it)."
  fi
  if [ -f ios/Runner.xcodeproj/project.pbxproj ] &&
    file_matches '(^|[^A-Za-z])Pods[-_/.]|\[CP\]' ios/Runner.xcodeproj/project.pbxproj; then
    fail "ios/Runner.xcodeproj/project.pbxproj references CocoaPods; discard those changes (do not commit them)."
  fi
  for xcconfig in ios/Flutter/*.xcconfig; do
    if [ -f "$xcconfig" ] && file_matches '^[[:space:]]*#include.*Pods' "$xcconfig"; then
      fail "$xcconfig includes a CocoaPods file; discard that change (do not commit it)."
    fi
  done
}

if [ "$inspect_ipa_given" -eq 1 ]; then
  print_ipa_version "$inspect_ipa"
  exit 0
fi

check_no_cocoapods
# shellcheck source=tool/release_define_check.sh
. tool/release_define_check.sh
check_release_define_file build_ios_release "$env_file" || exit 1
check_build_number

if [ "$check_only" -eq 1 ]; then
  echo "All pre-build checks passed (no build was run)."
  exit 0
fi

command -v flutter >/dev/null 2>&1 || fail "flutter not found on PATH"
echo "== format check"
sh tool/check_format.sh
echo "== flutter analyze"
flutter analyze
echo "== flutter test"
flutter test
ipa_dir="build/ios/ipa"
rm -f "$ipa_dir"/*.ipa # never report a stale IPA from an earlier build
if [ -n "$build_number" ]; then
  echo "== flutter build ipa --release --build-number $build_number"
  flutter build ipa --release "--dart-define-from-file=$env_file" --build-number "$build_number"
else
  echo "== flutter build ipa --release"
  flutter build ipa --release "--dart-define-from-file=$env_file"
fi
# The build itself can add CocoaPods noise; refuse to report success over it.
check_no_cocoapods

set -- "$ipa_dir"/*.ipa
if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  fail "expected exactly one IPA in $ipa_dir"
fi
echo
echo "IPA: $(pwd)/$1"
if [ -n "$build_number" ]; then
  print_ipa_version "$1" "$build_number"
else
  print_ipa_version "$1"
fi
