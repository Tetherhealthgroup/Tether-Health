#!/bin/sh
# Uploads an existing, verified iOS IPA to App Store Connect for TestFlight,
# or only validates it, with an App Store Connect API key kept outside the
# repository. Run by the owner only, never by CI. iOS counterpart of the Play
# upload lanes in android/fastlane/Fastfile.
#
# It never builds, signs or archives, and sends nothing but the IPA: no
# metadata, screenshots, tester changes or review submission.
#
# Usage: sh tool/upload_ios_testflight.sh --ipa=<path> [--validate]
#
# --ipa=<path>   The .ipa built by tool/build_ios_release.sh. A relative path
#                is resolved against the caller's working directory.
# --validate     Validate the IPA with App Store Connect instead of uploading
#                it (xcrun altool --validate-app). Nothing is uploaded.
#
# Environment (all three are required):
#   TETHER_ASC_KEY_PATH   The App Store Connect API key file (.p8). Its real
#                         path (symbolic links resolved) must be outside this
#                         repository and outside every folder altool searches
#                         for keys: ./private_keys (the repository root, where
#                         altool runs), ~/private_keys, ~/.private_keys and
#                         ~/.appstoreconnect/private_keys. Only its owner may
#                         have access to it (chmod 600).
#   TETHER_ASC_KEY_ID     The key ID: 10 upper-case letters or digits.
#   TETHER_ASC_ISSUER_ID  The issuer ID: a UUID.
#
# Before any xcrun call it refuses to run if CI, GITHUB_ACTIONS or DEBUG is
# set to a non-empty value, if API_PRIVATE_KEYS_DIR is set, if
# ~/Library/Preferences/com.apple.itunes.altool.plist exists, if a file named
# AuthKey_<key ID>.p8 is in one of the key search folders above, if the key
# file is not a PEM private key, or if the IPA's bundle identifier is not the
# app's. It prints the IPA's version fields with
# tool/build_ios_release.sh --inspect-ipa.
#
# altool runs exactly once, from the repository root, with an argument list.
# Its standard output and standard error are merged and shown with the key's
# path and file name replaced by "<key path not shown>"; its exit code is kept.
# Errors from this script never print an argument, an environment value or a
# path; they name the option or variable.
#
# Exit codes: 0 success, 1 a check failed, 2 usage error, otherwise altool's
# exit code.
set -eu
# A set CDPATH makes cd print the directory and corrupt resolved paths.
unset CDPATH

expected_bundle_id="com.TetherHealthLLC.tetherhealth"
ipa=""
ipa_given=0
validate=0

fail() {
  echo "upload_ios_testflight: $1" >&2
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
  fail "unknown argument (not shown; see the usage at the top of tool/upload_ios_testflight.sh)" 2
}

if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
  fail "refusing to run: CI or GITHUB_ACTIONS is set. TestFlight uploads are run by the owner only, never by CI."
fi
if [ -n "${DEBUG:-}" ]; then
  fail "refusing to run: DEBUG is set. Debug output can expose credential details."
fi
if [ -n "${API_PRIVATE_KEYS_DIR+set}" ]; then
  fail "refusing to run: API_PRIVATE_KEYS_DIR is set. Unset it; the key is passed to altool by TETHER_ASC_KEY_PATH only."
fi
[ -n "${HOME:-}" ] || fail "HOME is not set."
altool_preferences="$HOME/Library/Preferences/com.apple.itunes.altool.plist"
if [ -e "$altool_preferences" ] || [ -L "$altool_preferences" ]; then
  fail "refusing to run: ~/Library/Preferences/com.apple.itunes.altool.plist exists. It can change how altool runs; move it out of that folder first."
fi

for arg in "$@"; do
  case "$arg" in
    --ipa=*)
      [ "$ipa_given" -eq 0 ] || fail "--ipa given more than once" 2
      ipa="${arg#--ipa=}"
      ipa_given=1
      ;;
    --validate)
      [ "$validate" -eq 0 ] || fail "--validate given more than once" 2
      validate=1
      ;;
    *) unknown_argument "$arg" ;;
  esac
done

# Paths are made absolute by prefixing $PWD only (no cd, dirname or $(...)),
# so the file used is exactly the one `[ -f ]` checked.
[ "$ipa_given" -eq 1 ] || fail "--ipa=<path> is required" 2
[ -n "$ipa" ] || fail "--ipa requires a path" 2
case "$ipa" in
  *.[iI][pP][aA]) ;;
  *) fail "--ipa must name a .ipa file (path not shown)" 2 ;;
esac
[ -f "$ipa" ] || fail "IPA not found (path given to --ipa not shown)" 2
case "$ipa" in /*) ;; *) ipa="$PWD/$ipa" ;; esac

key_id="${TETHER_ASC_KEY_ID:-}"
[ -n "$key_id" ] || fail "TETHER_ASC_KEY_ID is not set."
case "$key_id" in
  *[!ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789]*)
    fail "TETHER_ASC_KEY_ID must be 10 upper-case letters or digits (value not shown)."
    ;;
esac
[ "${#key_id}" -eq 10 ] ||
  fail "TETHER_ASC_KEY_ID must be 10 upper-case letters or digits (value not shown)."

issuer_id="${TETHER_ASC_ISSUER_ID:-}"
[ -n "$issuer_id" ] || fail "TETHER_ASC_ISSUER_ID is not set."
h='[0123456789abcdefABCDEF]'
uuid_pattern="$h$h$h$h$h$h$h$h-$h$h$h$h-$h$h$h$h-$h$h$h$h-$h$h$h$h$h$h$h$h$h$h$h$h"
# shellcheck disable=SC2254 # the pattern is meant to be expanded
case "$issuer_id" in
  $uuid_pattern) ;;
  *) fail "TETHER_ASC_ISSUER_ID must be a UUID (value not shown)." ;;
esac

key="${TETHER_ASC_KEY_PATH:-}"
[ -n "$key" ] || fail "TETHER_ASC_KEY_PATH is not set."
[ -f "$key" ] || fail "TETHER_ASC_KEY_PATH does not point to an existing file (path not shown)."
case "$key" in /*) ;; *) key="$PWD/$key" ;; esac

# Run from the repo root (the script's parent directory). altool runs here.
cd "$(dirname "$0")/.."

# Prints the real path of $1 (symbolic links resolved) followed by '/', so a
# path ending in a newline survives $(...). Prints nothing else.
real_path() {
  python3 -I -c 'import os, sys; sys.stdout.write(os.path.realpath(sys.argv[1]) + "/")' "$1" 2>/dev/null ||
    fail "cannot resolve a path (not shown)"
}

# Exits 0 if the real path $1 is outside the real path of every later
# argument, 3 if it is the same as or inside one of them. Compared
# case-insensitively (the default macOS file system is case-insensitive).
# Any other status means the check failed.
outside_all() {
  python3 -I - "$@" 2>/dev/null <<'PY'
import os, sys

path = sys.argv[1].lower()
for folder in sys.argv[2:]:
    folder = os.path.realpath(folder).lower().rstrip("/")
    if path == folder or path.startswith(folder + "/"):
        sys.exit(3)
sys.exit(0)
PY
}

key_real=$(real_path "$key") || exit 1
key_real="${key_real%/}"
repo_root=$(real_path .) || exit 1
repo_root="${repo_root%/}"
newline='
'
case "$key_real" in
  *"$newline"*) fail "TETHER_ASC_KEY_PATH contains a line break (path not shown)." ;;
esac
[ -f "$key_real" ] || fail "TETHER_ASC_KEY_PATH does not point to an existing file (path not shown)."

# The folders altool searches for AuthKey_<key ID>.p8 files.
set -- "$repo_root/private_keys" "$HOME/private_keys" "$HOME/.private_keys" "$HOME/.appstoreconnect/private_keys"

check_status=0
outside_all "$key_real" "$repo_root" || check_status=$?
case "$check_status" in
  0) ;;
  3) fail "TETHER_ASC_KEY_PATH points inside the repository. Keep the key outside it." ;;
  *) fail "cannot check where TETHER_ASC_KEY_PATH points (path not shown)." ;;
esac
check_status=0
outside_all "$key_real" "$@" || check_status=$?
case "$check_status" in
  0) ;;
  3) fail "TETHER_ASC_KEY_PATH points inside a folder altool searches for keys. Keep the key in a folder of its own." ;;
  *) fail "cannot check where TETHER_ASC_KEY_PATH points (path not shown)." ;;
esac

# The key file is checked without printing any of it: a regular file with no
# group or other access, at most 4096 bytes, holding one PEM private key.
check_status=0
python3 -I - "$key_real" 2>/dev/null <<'PY' || check_status=$?
import os, re, stat, sys

try:
    info = os.stat(sys.argv[1])
    if not stat.S_ISREG(info.st_mode) or info.st_size > 4096:
        sys.exit(4)
    if info.st_mode & 0o077:
        sys.exit(3)
    with open(sys.argv[1], "rb") as key_file:
        data = key_file.read(4097)
except Exception:
    sys.exit(5)
lines = data.split(b"\n")
if lines and lines[-1] == b"":
    lines.pop()
body = re.compile(rb"[A-Za-z0-9+/]{1,76}={0,2}")
pem = (
    len(lines) >= 3
    and lines[0] == b"-----BEGIN " + b"PRIVATE KEY-----"
    and lines[-1] == b"-----END " + b"PRIVATE KEY-----"
    and all(body.fullmatch(line) for line in lines[1:-1])
)
sys.exit(0 if pem else 4)
PY
case "$check_status" in
  0) ;;
  3) fail "TETHER_ASC_KEY_PATH is accessible to group or others. Run chmod 600 on the key file." ;;
  4) fail "TETHER_ASC_KEY_PATH does not point to a PEM private key file (.p8). Its contents are not shown." ;;
  *) fail "cannot read the file TETHER_ASC_KEY_PATH points to (path not shown)." ;;
esac

for folder in "$@"; do
  stray="$folder/AuthKey_$key_id.p8"
  if [ -e "$stray" ] || [ -L "$stray" ]; then
    fail "refusing to run: a file named AuthKey_<TETHER_ASC_KEY_ID>.p8 is in a folder altool searches for keys (not shown). Move it out."
  fi
done

echo "== IPA version (tool/build_ios_release.sh --inspect-ipa)"
sh tool/build_ios_release.sh "--inspect-ipa=$ipa" ||
  fail "tool/build_ios_release.sh --inspect-ipa failed. Nothing was sent to App Store Connect."

check_status=0
python3 -I - "$ipa" "$expected_bundle_id" 2>/dev/null <<'PY' || check_status=$?
import plistlib, re, sys, zipfile

try:
    with zipfile.ZipFile(sys.argv[1]) as ipa:
        names = [n for n in ipa.namelist() if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", n)]
        if len(names) != 1:
            sys.exit(4)
        info = plistlib.loads(ipa.read(names[0]))
except Exception:
    sys.exit(4)
sys.exit(0 if isinstance(info, dict) and info.get("CFBundleIdentifier") == sys.argv[2] else 3)
PY
case "$check_status" in
  0) ;;
  3) fail "the IPA's bundle identifier is not $expected_bundle_id. Nothing was sent to App Store Connect." ;;
  *) fail "cannot read the bundle identifier from the IPA. Nothing was sent to App Store Connect." ;;
esac

command -v xcrun >/dev/null 2>&1 || fail "xcrun not found on PATH (Xcode is required)."

# Copies standard input to standard output, line by line, with every
# occurrence of the key's path and file name replaced.
redact_key() {
  REDACT_KEY_REAL="$key_real" REDACT_KEY_GIVEN="$key" \
    REDACT_KEY_REAL_NAME="${key_real##*/}" REDACT_KEY_GIVEN_NAME="${key##*/}" \
    LC_ALL=C awk '
function hide(line, needle,    out, at) {
  if (needle == "") return line
  out = ""
  while ((at = index(line, needle)) > 0) {
    out = out substr(line, 1, at - 1) "<key path not shown>"
    line = substr(line, at + length(needle))
  }
  return out line
}
{
  line = hide($0, ENVIRON["REDACT_KEY_REAL"])
  line = hide(line, ENVIRON["REDACT_KEY_GIVEN"])
  line = hide(line, ENVIRON["REDACT_KEY_REAL_NAME"])
  line = hide(line, ENVIRON["REDACT_KEY_GIVEN_NAME"])
  print line
  fflush()
}'
}

# Runs xcrun altool once with the given arguments and no standard input,
# its output merged and passed through redact_key, then exits with altool's
# exit code if it is not 0.
run_altool() {
  exec 4>&1
  altool_status=$(
    {
      {
        status=0
        xcrun altool "$@" </dev/null 2>&1 || status=$?
        echo "$status" >&3
      } | redact_key >&4
    } 3>&1
  )
  exec 4>&-
  case "$altool_status" in
    0) ;;
    '' | *[!0-9]*) fail "altool did not report an exit code." ;;
    *) exit "$altool_status" ;;
  esac
}

if [ "$validate" -eq 1 ]; then
  echo "== xcrun altool --validate-app"
  run_altool --validate-app "$ipa" --api-key "$key_id" --api-issuer "$issuer_id" --p8-file-path "$key_real"
  echo "Validation finished. Nothing was uploaded."
else
  echo "== xcrun altool --upload-package"
  run_altool --upload-package "$ipa" --api-key "$key_id" --api-issuer "$issuer_id" --p8-file-path "$key_real"
  echo "Upload finished. After processing, the build is listed under TestFlight in App Store Connect."
fi
