#!/bin/sh
# Builds an iOS App Store IPA. Never signs with repo secrets, uploads or
# submits anything. iOS counterpart of tool/build_play_release.sh.
#
# Usage: sh tool/build_ios_release.sh --dart-define-from-file=<path> [--check-only]
#        sh tool/build_ios_release.sh --inspect-ipa=<path>
#
# --dart-define-from-file=<path>
#                   Release define file (see docs/PLAY_RELEASE.md section 3).
#                   Required unless --inspect-ipa is given. A relative path is
#                   resolved against the caller's working directory. Before any
#                   build step the file must be a JSON object with https
#                   SUPABASE_URL and API_BASE_URL and a non-privileged
#                   SUPABASE_ANON_KEY (no sb_secret_, no service_role, JWTs must
#                   have role "anon"); the rules live in
#                   tool/release_define_check.sh, shared with the Play script.
#                   No value from the file is ever printed.
# --check-only      Run every pre-build check (arguments, CocoaPods, define
#                   file), then exit 0 if all pass or non-zero if any fails.
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
# own settings on the build Mac; no team ID, certificate, provisioning profile
# or export options are kept in this repo.
#
# Exit codes: 0 success, 1 a check or build step failed, 2 usage error.
set -eu

env_file=""
env_file_given=0
check_only=0
inspect_ipa=""
inspect_ipa_given=0

fail() {
  echo "build_ios_release: $1" >&2
  exit "${2:-1}"
}

for arg in "$@"; do
  case "$arg" in
    --dart-define-from-file=*)
      env_file="${arg#--dart-define-from-file=}"
      env_file_given=1
      ;;
    --check-only) check_only=1 ;;
    --inspect-ipa=*)
      inspect_ipa="${arg#--inspect-ipa=}"
      inspect_ipa_given=1
      ;;
    *) fail "unknown argument: $arg" 2 ;;
  esac
done

# Resolve file arguments against the caller's working directory, then make them
# absolute before changing directory (a relative path must never be silently
# re-read against the repo root).
abs_path() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }

if [ "$inspect_ipa_given" -eq 1 ]; then
  if [ "$env_file_given" -eq 1 ] || [ "$check_only" -eq 1 ]; then
    fail "--inspect-ipa cannot be combined with other arguments" 2
  fi
  [ -n "$inspect_ipa" ] || fail "--inspect-ipa requires a path" 2
  [ -f "$inspect_ipa" ] || fail "IPA not found: $inspect_ipa" 2
  inspect_ipa="$(abs_path "$inspect_ipa")"
else
  [ -n "$env_file" ] || fail "--dart-define-from-file=<path> is required" 2
  [ -f "$env_file" ] || fail "define file not found: $env_file" 2
  env_file="$(abs_path "$env_file")"
fi

# Run from the repo root (the script's parent directory).
cd "$(dirname "$0")/.."

# Prints CFBundleShortVersionString and CFBundleVersion from the app's own
# Info.plist (Payload/<app>.app/Info.plist, not a framework's) inside an IPA.
# Fails (exit 1) if the IPA or either value cannot be read.
print_ipa_version() {
  python3 -I - "$1" <<'PY' || exit 1
import plistlib, re, sys, zipfile

path = sys.argv[1]
try:
    with zipfile.ZipFile(path) as ipa:
        names = [n for n in ipa.namelist() if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", n)]
        if len(names) != 1:
            sys.exit(f"build_ios_release: expected one Payload/<app>.app/Info.plist in {path}, found {len(names)}")
        info = plistlib.loads(ipa.read(names[0]))
except (OSError, zipfile.BadZipFile, plistlib.InvalidFileException, ValueError) as exc:
    sys.exit(f"build_ios_release: cannot read the IPA's Info.plist: {type(exc).__name__}")
values = [info.get(k) if isinstance(info, dict) else None for k in ("CFBundleShortVersionString", "CFBundleVersion")]
if not all(isinstance(v, str) and v.strip() for v in values):
    sys.exit(f"build_ios_release: CFBundleShortVersionString or CFBundleVersion missing in {path}")
print(f"CFBundleShortVersionString: {values[0]}")
print(f"CFBundleVersion: {values[1]}")
PY
}

# Fails (exit 1) if any CocoaPods integration is present (SPM-only project).
check_no_cocoapods() {
  if [ -e ios/Podfile ]; then
    fail "ios/Podfile exists; this project uses Swift Package Manager. Remove it (do not commit it)."
  fi
  if [ -f ios/Runner.xcodeproj/project.pbxproj ] &&
    grep -qE 'Pods[-_/.]|\[CP\]' ios/Runner.xcodeproj/project.pbxproj; then
    fail "ios/Runner.xcodeproj/project.pbxproj references CocoaPods; discard those changes (do not commit them)."
  fi
  for xcconfig in ios/Flutter/*.xcconfig; do
    if [ -f "$xcconfig" ] && grep -qE '^[[:space:]]*#include.*Pods' "$xcconfig"; then
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
echo "== flutter build ipa --release"
flutter build ipa --release "--dart-define-from-file=$env_file"
# The build itself can add CocoaPods noise; refuse to report success over it.
check_no_cocoapods

set -- "$ipa_dir"/*.ipa
if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  fail "expected exactly one IPA in $ipa_dir"
fi
echo
echo "IPA: $(pwd)/$1"
print_ipa_version "$1"
