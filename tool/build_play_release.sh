#!/usr/bin/env bash
# Builds a signed Google Play release bundle (AAB). Never uploads anything.
#
# Usage: bash tool/build_play_release.sh --dart-define-from-file=<path>
#          [--min-version-code N] [--build-number N]
#        bash tool/build_play_release.sh --check-version-only
#          [--min-version-code N] [--build-number N]
#        bash tool/build_play_release.sh --verify-aab=<path>
#          [--min-version-code N]
#
# --min-version-code N  Lowest versionCode Play will accept (default 2: Play
#                       already holds 1.0.0 (1), uploaded 2026-10-12). Raise it
#                       after each upload. The build fails before any build
#                       step if the pubspec build number or --build-number is
#                       below it, and after the build if the AAB's versionCode
#                       is below it.
# --build-number N      Passed to flutter build; overrides the pubspec number.
# --check-version-only  Run only the pre-build version check, then exit. Needs
#                       no define file and never builds.
# --verify-aab=<path>   Run only the post-build versionCode read-back on an
#                       existing AAB, then exit. Never builds.
#
# Requires android/key.properties (see docs/PLAY_RELEASE.md). The Gradle build
# fails if it is missing or incomplete; the debug key is never used.
set -euo pipefail

# A store build must never inherit the CI-only unsigned-release opt-in.
unset TETHER_ALLOW_UNSIGNED_RELEASE

max_version_code=2100000000 # Play's upper limit
env_file=""
min_version_code=2
build_number=""
build_number_given=0
check_version_only=0
verify_aab=""
verify_aab_given=0

# Succeeds if $1 is a positive integer no larger than Play's limit. Checks the
# digit length first so a huge value never reaches shell arithmetic.
is_valid_version_code() {
  local value="$1"
  case "$value" in
    "" | *[!0-9]*) return 1 ;;
  esac
  value="${value#"${value%%[!0]*}"}" # strip leading zeros (0099 is not octal)
  [ -n "$value" ] && [ "${#value}" -le 10 ] && [ "$value" -le "$max_version_code" ]
}

# Accepts a positive integer within Play's range; exits 2 otherwise.
require_version_code() {
  local name="$1" value="$2"
  case "$value" in
    "" | *[!0-9]*)
      echo "build_play_release: $name must be a positive integer, got: $value" >&2
      exit 2
      ;;
  esac
  if ! is_valid_version_code "$value"; then
    echo "build_play_release: $name must be between 1 and $max_version_code" >&2
    exit 2
  fi
}

# Normalises a validated integer (no leading zeros).
normalise_int() {
  local value="$1"
  echo $((10#$value))
}

while [ "$#" -gt 0 ]; do
  arg="$1"
  case "$arg" in
    --dart-define-from-file=*) env_file="${arg#--dart-define-from-file=}" ;;
    --min-version-code=*) min_version_code="${arg#--min-version-code=}" ;;
    --min-version-code | --build-number)
      if [ "$#" -lt 2 ]; then
        echo "build_play_release: $arg requires a value" >&2
        exit 2
      fi
      shift
      if [ "$arg" = "--build-number" ]; then
        build_number="$1"
        build_number_given=1
      else
        min_version_code="$1"
      fi
      ;;
    --build-number=*)
      build_number="${arg#--build-number=}"
      build_number_given=1
      ;;
    --check-version-only) check_version_only=1 ;;
    --verify-aab=*)
      verify_aab="${arg#--verify-aab=}"
      verify_aab_given=1
      ;;
    # Never echo the value: a key typed on the command line must not reach
    # terminal or CI logs. Show only the option name before the first '='.
    ?*=*)
      echo "build_play_release: unknown argument: ${arg%%=*}=<value not shown>" >&2
      exit 2
      ;;
    *)
      echo "build_play_release: unknown argument (not shown; see the usage at the top of this script)" >&2
      exit 2
      ;;
  esac
  shift
done

require_version_code "--min-version-code" "$min_version_code"
min_version_code="$(normalise_int "$min_version_code")"
if [ "$build_number_given" -eq 1 ]; then
  require_version_code "--build-number" "$build_number"
  build_number="$(normalise_int "$build_number")"
fi
if [ "$verify_aab_given" -eq 1 ] && [ "$check_version_only" -eq 1 ]; then
  echo "build_play_release: --verify-aab and --check-version-only are exclusive" >&2
  exit 2
fi

# Resolve file arguments against the caller's working directory, then make them
# absolute before changing directory (a relative path must never be silently
# re-read against the repo root).
abs_path() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }
if [ "$check_version_only" -eq 0 ]; then
  if [ "$verify_aab_given" -eq 1 ]; then
    if [ -z "$verify_aab" ]; then
      echo "build_play_release: --verify-aab requires a path" >&2
      exit 2
    fi
    if [ ! -f "$verify_aab" ]; then
      echo "build_play_release: AAB not found: $verify_aab" >&2
      exit 2
    fi
    verify_aab="$(abs_path "$verify_aab")"
  else
    if [ -z "$env_file" ]; then
      echo "build_play_release: --dart-define-from-file=<path> is required" >&2
      exit 2
    fi
    if [ ! -f "$env_file" ]; then
      echo "build_play_release: define file not found: $env_file" >&2
      exit 2
    fi
    env_file="$(abs_path "$env_file")"
  fi
fi
# Run from the repo root (the script's parent directory) for pubspec.yaml.
cd "$(dirname "$0")/.."

# Fails (exit 1) unless the versionCode that would be built is >= the minimum.
# Checks the pubspec build number and, when given, --build-number.
check_version_code() {
  local pubspec_version pubspec_code
  pubspec_version="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1 | tr -d '[:space:]\r')"
  case "$pubspec_version" in
    *+[0-9]*) pubspec_code="${pubspec_version##*+}" ;;
    *)
      echo "FAIL: pubspec.yaml version '$pubspec_version' has no +<buildNumber>; Flutter would default versionCode to 1." >&2
      exit 1
      ;;
  esac
  case "$pubspec_code" in
    *[!0-9]*)
      echo "FAIL: pubspec.yaml build number '$pubspec_code' is not an integer." >&2
      exit 1
      ;;
  esac
  if ! is_valid_version_code "$pubspec_code"; then
    echo "FAIL: pubspec.yaml build number '$pubspec_code' must be between 1 and $max_version_code (Play's limit)." >&2
    exit 1
  fi
  pubspec_code="$(normalise_int "$pubspec_code")"
  echo "pubspec.yaml version: $pubspec_version (versionCode $pubspec_code); minimum $min_version_code"
  if [ "$pubspec_code" -lt "$min_version_code" ]; then
    echo "FAIL: pubspec.yaml versionCode $pubspec_code is below the minimum $min_version_code. Play already holds versionCode 1; bump the number after '+' and commit it." >&2
    exit 1
  fi
  if [ -n "$build_number" ]; then
    echo "--build-number: $build_number (overrides the pubspec number)"
    if [ "$build_number" -lt "$min_version_code" ]; then
      echo "FAIL: --build-number $build_number is below the minimum $min_version_code." >&2
      exit 1
    fi
  fi
}

# aapt2 cannot open an AAB (manifest is at base/manifest/, resources at
# base/resources.pb). Repackage those two entries as a minimal APK with both at
# the root, then dump its manifest. Prints the versionCode, or nothing on error.
read_version_code_with_aapt2() {
  local aab_path="$1" tmp_dir
  tmp_dir="$(mktemp -d)" || return 1
  # shellcheck disable=SC2064 # expand tmp_dir now so cleanup survives scope exit
  trap "rm -f '$tmp_dir/manifest.apk'; rmdir '$tmp_dir'" RETURN
  python3 -I - "$aab_path" "$tmp_dir/manifest.apk" <<'PY' || return 1
import sys, zipfile
src, dst = sys.argv[1:3]
try:
    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, "w") as zout:
        zout.writestr("AndroidManifest.xml", zin.read("base/manifest/AndroidManifest.xml"))
        zout.writestr("resources.pb", zin.read("base/resources.pb"))
except (OSError, KeyError, zipfile.BadZipFile):
    sys.exit(1)
PY
  aapt2 dump xmltree --file AndroidManifest.xml "$tmp_dir/manifest.apk" 2>/dev/null |
    sed -n 's/.*android:versionCode([^)]*)=\([0-9][0-9]*\).*/\1/p' | head -n 1
}

# Reads versionCode from an AAB with bundletool, else aapt2, and fails (exit 1)
# if neither is installed, the read fails, or the value is below the minimum.
verify_aab_version_code() {
  local aab_path="$1" code=""
  if command -v bundletool >/dev/null 2>&1; then
    code="$(bundletool dump manifest --bundle="$aab_path" --xpath=/manifest/@android:versionCode 2>/dev/null)" || code=""
  elif command -v aapt2 >/dev/null 2>&1; then
    code="$(read_version_code_with_aapt2 "$aab_path")" || code=""
  else
    echo "FAIL: neither bundletool nor aapt2 is installed; cannot read versionCode from the AAB. Install one and re-run with --verify-aab=$aab_path before uploading." >&2
    exit 1
  fi
  case "$code" in
    "" | *[!0-9]*)
      echo "FAIL: could not read a numeric versionCode from $aab_path (got: '$code')." >&2
      exit 1
      ;;
  esac
  code="$(normalise_int "$code")"
  echo "versionCode: $code (read from the AAB); minimum $min_version_code"
  if [ "$code" -lt "$min_version_code" ]; then
    echo "FAIL: AAB versionCode $code is below the minimum $min_version_code; Play would reject it." >&2
    exit 1
  fi
}

# Fails (exit 1) if keytool is missing, the bundle has no signing certificate,
# or it is signed with the Android Debug certificate.
check_signing_certificate() {
  local aab_path="$1" cert
  if ! command -v keytool >/dev/null 2>&1; then
    echo "FAIL: keytool not found on PATH; cannot verify the signing certificate." >&2
    exit 1
  fi
  cert="$(keytool -printcert -jarfile "$aab_path" 2>&1 || true)"
  echo
  echo "== signing certificate"
  printf '%s\n' "$cert" | grep -E "Owner:|Issuer:|SHA256:|Valid from:|no signature|not signed" || echo "no certificate found: $cert"
  if printf '%s' "$cert" | grep -q "CN=Android Debug"; then
    echo "FAIL: bundle is signed with the Android Debug certificate; do not upload." >&2
    exit 1
  fi
  if ! printf '%s' "$cert" | grep -q "Owner:"; then
    echo "FAIL: bundle carries no signing certificate." >&2
    exit 1
  fi
  echo "Signing certificate is not the Android Debug certificate."
}

if [ "$check_version_only" -eq 1 ]; then
  check_version_code
  echo "Version check passed (no build was run)."
  exit 0
fi
if [ "$verify_aab_given" -eq 1 ]; then
  check_signing_certificate "$verify_aab"
  verify_aab_version_code "$verify_aab"
  exit 0
fi

# Fail before any build step if the version would be rejected by Play.
check_version_code

# Pre-validate the endpoints and the key (shared with the iOS script). Values
# are never printed. Sourced here, not at the top, so the version-only and
# read-back modes keep working from a copy of this script alone.
# shellcheck source=tool/release_define_check.sh
. tool/release_define_check.sh
check_release_define_file build_play_release "$env_file"

if [ ! -f android/key.properties ]; then
  echo "build_play_release: android/key.properties not found (see docs/PLAY_RELEASE.md)" >&2
  exit 2
fi

echo "== flutter pub get"
flutter pub get
echo "== format check"
sh tool/check_format.sh
echo "== flutter analyze"
flutter analyze
echo "== flutter test"
flutter test
aab="build/app/outputs/bundle/release/app-release.aab"
rm -f "$aab" # never report a stale bundle from an earlier build
echo "== flutter build appbundle --release"
build_args=(--release "--dart-define-from-file=$env_file")
if [ -n "$build_number" ]; then
  build_args+=("--build-number=$build_number")
fi
flutter build appbundle "${build_args[@]}"

if [ ! -f "$aab" ]; then
  echo "build_play_release: expected bundle not found at $aab" >&2
  exit 1
fi
echo
echo "AAB: $(pwd)/$aab"

# Certificate first, so a failed read-back can never skip it; then read back
# versionCode (bundletool, else aapt2).
check_signing_certificate "$aab"
echo
if command -v bundletool >/dev/null 2>&1; then
  echo "package:     $(bundletool dump manifest --bundle="$aab" --xpath=/manifest/@package)"
fi
verify_aab_version_code "$aab"
