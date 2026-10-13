#!/usr/bin/env bash
# Builds a signed Google Play release bundle (AAB). Never uploads anything.
#
# Usage: bash tool/build_play_release.sh --dart-define-from-file=<path>
#
# Requires android/key.properties (see docs/PLAY_RELEASE.md). The Gradle build
# fails if it is missing or incomplete; the debug key is never used.
set -euo pipefail

# A store build must never inherit the CI-only unsigned-release opt-in.
unset TETHER_ALLOW_UNSIGNED_RELEASE

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
# Resolve to an absolute path before changing directory (Gradle runs elsewhere).
env_file="$(cd "$(dirname "$env_file")" && pwd)/$(basename "$env_file")"
cd "$(dirname "$0")/.."

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
flutter build appbundle --release "--dart-define-from-file=$env_file"

if [ ! -f "$aab" ]; then
  echo "build_play_release: expected bundle not found at $aab" >&2
  exit 1
fi
echo
echo "AAB: $(pwd)/$aab"

# Read back package and versionCode from the bundle manifest (needs bundletool).
if command -v bundletool >/dev/null 2>&1; then
  echo "package:     $(bundletool dump manifest --bundle="$aab" --xpath=/manifest/@package)"
  echo "versionCode: $(bundletool dump manifest --bundle="$aab" --xpath=/manifest/@android:versionCode)"
else
  pubspec_version="$(sed -n 's/^version: *//p' pubspec.yaml | head -n 1)"
  echo "package/versionCode read-back unavailable (bundletool not on PATH)."
  echo "versionCode expected from pubspec.yaml (NOT read from the AAB): version $pubspec_version"
fi

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
