# shellcheck shell=sh
# Shared pre-build check of a release define file (--dart-define-from-file).
# Sourced by tool/build_play_release.sh and tool/build_ios_release.sh; not run
# directly. POSIX sh, so both bash and sh can source it.
#
# check_release_define_file <prefix> <path>
#   Succeeds if <path> is a JSON object whose SUPABASE_URL and API_BASE_URL are
#   absolute https URLs, whose SUPABASE_ANON_KEY is a non-privileged key, and
#   in which no define key (every key, at any nesting depth) holds a
#   privileged-looking value (R-055, R-076, TH-123). Privileged means:
#     - sb_secret_, after removing whitespace and zero-width/format characters
#       (case-insensitive, anywhere in the value);
#     - for SUPABASE_ANON_KEY only, the literal service_role;
#     - a JWT-shaped value (three or more dot-separated segments, any header,
#       padded or not, also after a prefix such as "Bearer ") in which any
#       decodable payload segment has a "role" key whose value is not "anon".
#       Every duplicate role key is considered.
#   SUPABASE_ANON_KEY must also be decodable if it has three or more segments,
#   and its payload must carry role "anon". Other keys need not carry a role.
#   Otherwise prints "<prefix>: <problems>" to stderr and returns 1. Values
#   are never printed; define key names are, if they look like identifiers.
#   Needs python3.
check_release_define_file() {
  python3 -I - "$1" "$2" <<'PY'
import base64, json, re, sys, unicodedata
from urllib.parse import urlparse

prefix = sys.argv[1]
ANON = "SUPABASE_ANON_KEY"
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


def strings(node):
    """Every string inside a JSON value."""
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for item in node.values():
            yield from strings(item)
    elif isinstance(node, list):
        for item in node:
            yield from strings(item)


def drop_invisible(text):
    """Remove zero-width, format and control characters (not whitespace)."""
    return "".join(
        c for c in text
        if c.isspace() or unicodedata.category(c) not in ("Cf", "Cc")
    )


def pieces(value):
    """Candidate tokens: the value with and without whitespace, its
    whitespace-separated words, and any dotted run of base64url characters."""
    text = drop_invisible(value)
    squeezed = "".join(text.split())
    found = {squeezed, text.strip(), *text.split()}
    for source in (text, squeezed):
        found.update(re.findall(r"[A-Za-z0-9_=+/-]+(?:\.[A-Za-z0-9_=+/-]+){2,}", source))
    return found


def roles_of(segment):
    """None if the segment is not a base64(url) JSON object, else the list of
    every value of a "role" key (duplicates included)."""
    if not re.fullmatch(r"[A-Za-z0-9_+/-]*={0,2}", segment):
        return None
    body = segment.rstrip("=").replace("+", "-").replace("/", "_")
    pairs = []

    def collect(items):
        pairs.extend(items)
        return dict(items)

    try:
        body += "=" * (-len(body) % 4)
        obj = json.loads(base64.urlsafe_b64decode(body), object_pairs_hook=collect)
    except Exception:
        return None
    if not isinstance(obj, dict):
        return None
    return [v for k, v in pairs if isinstance(k, str) and k.lower() == "role"]


def jwt_findings(value):
    """(has JWT shape, a payload decoded, every role value) over all pieces."""
    shape = decoded = False
    roles = []
    for piece in pieces(value):
        segments = piece.split(".")
        if len(segments) < 3:
            continue
        shape = True
        for segment in segments[1:]:
            found = roles_of(segment)
            if found is not None:
                decoded = True
                roles.extend(found)
    return shape, decoded, roles


def label(key):
    return key if re.fullmatch(r"[A-Za-z0-9_]{1,64}", key) else "a define key"


key_value = data.get(ANON)
if not isinstance(key_value, str) or not key_value.strip():
    bad.append(f"{ANON} is missing or empty")
for key, value in data.items():
    is_anon = key == ANON
    name = label(key)
    privileged = role_bad = undecodable = False
    for text in strings(value):
        cleaned = "".join(drop_invisible(text).split()).lower()
        if "sb_secret_" in cleaned or (is_anon and "service_role" in cleaned):
            privileged = True
        shape, decoded, roles = jwt_findings(text)
        if any(role != "anon" for role in roles):
            role_bad = True
        elif is_anon and shape:
            if not decoded:
                undecodable = True
            elif not roles:
                role_bad = True
    if privileged:
        bad.append(f"{name} is a privileged key" if is_anon else f"{name} holds a privileged key")
    if undecodable:
        bad.append(f"{name} looks like a JWT but cannot be decoded")
    if role_bad:
        bad.append(f'{name} is a JWT whose role is not "anon"' if is_anon
                   else f'{name} holds a JWT whose role is not "anon"')
if bad:
    sys.exit(f"{prefix}: " + "; ".join(bad))
PY
}
