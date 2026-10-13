#!/usr/bin/env bash
# Builds a signed Google Play release bundle (AAB). Never uploads anything.
#
# Usage: bash tool/build_play_release.sh --dart-define-from-file=<path>
#
# Requires android/key.properties (see docs/PLAY_RELEASE.md). The Gradle build
# fails if it is missing or incomplete; the debug key is never used.
set -euo pipefail

cd "$(dirname "$0")/.."

env_file=""
for arg in "$@"; do
  case "$arg" in
    --dart-define-from-file=*) env_file="${arg#--dart-define-from-file=}" ;;
    *)
      echo "build_play_release: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

if [ -z "$env_file" ]; then
  echo "build_play_release: --dart-define-from-file=<path> is required" >&2
  exit 2
fi
if [ ! -f "$env_file" ]; then
  echo "build_play_release: define file not found: $env_file" >&2
  exit 2
fi
# Gradle runs from android/, so hand Flutter an absolute path.
env_file="$(cd "$(dirname "$env_file")" && pwd)/$(basename "$env_file")"

# Pre-validate the two endpoints (JSON object of strings). Values are never printed.
python3 -I - "$env_file" <<'PY'
import json, sys
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
echo "== flutter build appbundle --release"
flutter build appbundle --release "--dart-define-from-file=$env_file"

aab="build/app/outputs/bundle/release/app-release.aab"
if [ ! -f "$aab" ]; then
  echo "build_play_release: expected bundle not found at $aab" >&2
  exit 1
fi
echo
echo "AAB: $(pwd)/$aab"

# Read back package and versionCode from the bundle's base manifest.
if command -v bundletool >/dev/null 2>&1; then
  manifest="$(bundletool dump manifest --bundle="$aab")"
  echo "package:     $(printf '%s' "$manifest" | sed -n 's/.*package="\([^"]*\)".*/\1/p' | head -n 1)"
  echo "versionCode: $(printf '%s' "$manifest" | sed -n 's/.*android:versionCode="\([^"]*\)".*/\1/p' | head -n 1)"
elif command -v aapt2 >/dev/null 2>&1; then
  badging="$(aapt2 dump badging "$aab" 2>/dev/null || true)"
  if [ -n "$badging" ]; then
    printf '%s\n' "$badging" | sed -n "s/^package: name='\([^']*\)' versionCode='\([^']*\)'.*/package:     \1\nversionCode: \2/p"
  else
    echo "package/versionCode read-back unavailable (aapt2 could not read an AAB; install bundletool)"
  fi
else
  echo "package/versionCode read-back unavailable (neither bundletool nor aapt2 on PATH)"
fi

# Signing certificate. Flag the Android debug certificate.
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
