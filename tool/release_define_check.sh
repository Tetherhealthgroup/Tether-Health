# shellcheck shell=sh
# Shared pre-build check of a release define file (--dart-define-from-file).
# Sourced by tool/build_play_release.sh and tool/build_ios_release.sh; not run
# directly. POSIX sh, so both bash and sh can source it.
#
# check_release_define_file <prefix> <path>
#   Succeeds if <path> is a JSON object whose SUPABASE_URL and API_BASE_URL are
#   absolute https URLs and whose SUPABASE_ANON_KEY is a non-privileged key:
#   not sb_secret_, no literal service_role, and, if it is a JWT, role "anon"
#   (R-055, R-076). Otherwise prints "<prefix>: <problems>" to stderr and
#   returns 1. Values are never printed. Needs python3.
check_release_define_file() {
  python3 -I - "$1" "$2" <<'PY'
import base64, json, sys
from urllib.parse import urlparse

prefix = sys.argv[1]
try:
    with open(sys.argv[2], encoding="utf-8") as fh:
        data = json.load(fh)
except (OSError, ValueError) as exc:
    sys.exit(f"{prefix}: cannot read define file as JSON: {type(exc).__name__}")
if not isinstance(data, dict):
    sys.exit(f"{prefix}: define file must be a JSON object")
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
    sys.exit(f"{prefix}: " + "; ".join(bad))
PY
}
