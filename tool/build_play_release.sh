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

# Accepts a positive integer within Play's range; exits 2 otherwise.
require_version_code() {
  local name="$1" value="$2"
  case "$value" in
    "" | *[!0-9]*)
      echo "build_play_release: $name must be a positive integer, got: $value" >&2
      exit 2
      ;;
  esac
  # Strip leading zeros so 0099 is not read as octal; length guard avoids overflow.
  value="${value#"${value%%[!0]*}"}"
  if [ -z "$value" ] || [ "${#value}" -gt 10 ] || [ "$value" -gt "$max_version_code" ]; then
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
    --verify-aab=*) verify_aab="${arg#--verify-aab=}" ;;
    *)
      echo "build_play_release: unknown argument: $arg" >&2
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
if [ -n "$verify_aab" ] && [ "$check_version_only" -eq 1 ]; then
  echo "build_play_release: --verify-aab and --check-version-only are exclusive" >&2
  exit 2
fi

# Resolve file arguments to absolute paths before changing directory.
abs_path() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; }
[ -n "$env_file" ] && [ -f "$env_file" ] && env_file="$(abs_path "$env_file")"
[ -n "$verify_aab" ] && [ -f "$verify_aab" ] && verify_aab="$(abs_path "$verify_aab")"
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

# Reads versionCode from an AAB with bundletool, else aapt2, and fails (exit 1)
# if neither is installed, the read fails, or the value is below the minimum.
verify_aab_version_code() {
  local aab_path="$1" code=""
  if command -v bundletool >/dev/null 2>&1; then
    code="$(bundletool dump manifest --bundle="$aab_path" --xpath=/manifest/@android:versionCode 2>/dev/null)" || code=""
  elif command -v aapt2 >/dev/null 2>&1; then
    code="$(aapt2 dump xmltree --file base/manifest/AndroidManifest.xml "$aab_path" 2>/dev/null |
      sed -n 's/.*android:versionCode([^)]*)=\([0-9][0-9]*\).*/\1/p' | head -n 1)" || code=""
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

if [ "$check_version_only" -eq 1 ]; then
  check_version_code
  echo "Version check passed (no build was run)."
  exit 0
fi
if [ -n "$verify_aab" ]; then
  if [ ! -f "$verify_aab" ]; then
    echo "build_play_release: AAB not found: $verify_aab" >&2
    exit 2
  fi
  verify_aab_version_code "$verify_aab"
  exit 0
fi

if [ -z "$env_file" ]; then
  echo "build_play_release: --dart-define-from-file=<path> is required" >&2
  exit 2
fi
if [ ! -f "$env_file" ]; then
  echo "build_play_release: define file not found: $env_file" >&2
  exit 2
fi
# Fail before any build step if the version would be rejected by Play.
check_version_code

# Pre-validate the two endpoints (JSON object of strings). Values are never printed.
python3 -I - "$env_file" <<'PY'
import base64, json, sys
from urllib.parse import urlparse

try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        data = json.load(fh)
except (OSError, ValueError) as exc:
    sys.exit(f"build_play_release: cannot read define file as JSON: {type(exc).__name__}")
if not isinstance(data, dict):
    sys.exit("build_play_release: define file must be a JSON object")
bad = []
for key in ("SUPABASE_URL", "API_BASE_URL"):
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        bad.append(f"{key} is missing or empty")
        continue
    parsed = urlparse(value.strip())
    if parsed.scheme != "https" or not parsed.netloc:
        bad.append(f"{key} must be an absolute https URL")
key_value = data.get("SUPABASE_ANON_KEY")
if not isinstance(key_value, str) or not key_value.strip():
    bad.append("SUPABASE_ANON_KEY is missing or empty")
else:
    key_value = key_value.strip()
    if "service_role" in key_value.lower() or key_value.lower().startswith("sb_secret_"):
        bad.append("SUPABASE_ANON_KEY is a privileged key")
    parts = key_value.split(".")
    if len(parts) == 3 and parts[0].startswith("eyJ"):
        try:
            segment = parts[1] + "=" * (-len(parts[1]) % 4)
            role = json.loads(base64.urlsafe_b64decode(segment)).get("role")
        except Exception:
            role = None
            bad.append("SUPABASE_ANON_KEY looks like a JWT but cannot be decoded")
        else:
            if role != "anon":
                bad.append('SUPABASE_ANON_KEY is a JWT whose role is not "anon"')
if bad:
    sys.exit("build_play_release: " + "; ".join(bad))
PY

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

# Read back versionCode from the bundle (bundletool, else aapt2). Fails if
# neither is installed or the value is below the minimum.
if command -v bundletool >/dev/null 2>&1; then
  echo "package:     $(bundletool dump manifest --bundle="$aab" --xpath=/manifest/@package)"
fi
verify_aab_version_code "$aab"

# Signing certificate. Flag the Android debug certificate.
if ! command -v keytool >/dev/null 2>&1; then
  echo "FAIL: keytool not found on PATH; cannot verify the signing certificate." >&2
  exit 1
fi
cert="$(keytool -printcert -jarfile "$aab" 2>&1 || true)"
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
