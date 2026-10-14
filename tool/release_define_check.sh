# shellcheck shell=sh
# Shared pre-build check of a release define file (--dart-define-from-file).
# Sourced by tool/build_play_release.sh and tool/build_ios_release.sh; not run
# directly. POSIX sh, so both bash and sh can source it.
#
# check_release_define_file <prefix> <path>
#   Succeeds if <path> is a JSON object whose SUPABASE_URL and API_BASE_URL are
#   absolute https URLs, whose SUPABASE_ANON_KEY is a non-privileged key, and
#   in which no define key holds a privileged-looking value (R-055, R-076,
#   TH-123). Every top-level key is checked, and so are all nested strings and
#   all key names at any depth. Privileged means:
#     - sb_secret_, after removing whitespace and zero-width/format characters
#       (case-insensitive, anywhere in the value);
#     - for SUPABASE_ANON_KEY only, the literal service_role;
#     - a JWT-shaped value (three or more dot-separated segments, any header,
#       padded or not, also after a prefix such as "Bearer ") in which any
#       segment after the first decodes to JSON that has a "role" key, at any
#       depth, matched case-insensitively, whose value is not "anon". Every
#       duplicate role key counts.
#   A key that appears twice in the define file (at any depth) is rejected,
#   because the later one would hide the earlier one.
#   SUPABASE_ANON_KEY must also be decodable if it has three or more segments,
#   and its payload must carry role "anon". Other keys need not carry a role.
#   Trade-off: a non-anon role on ANY JWT-shaped value is rejected, including
#   a third-party JWT that has nothing to do with Supabase.
#   Documented residual (N4): invisible characters outside Unicode categories
#   Cf and Cc (such as U+034F) are not removed before matching.
#   Otherwise prints "<prefix>: <problems>" to stderr and returns 1; an
#   unexpected internal error also returns 1 ("cannot check define file").
#   Values are never printed. A define key name is printed only if it is
#   upper-case ([A-Z][A-Z0-9_]{0,63}) and carries no privileged marker or
#   JWT shape; otherwise "a define key" stands in. Needs python3.
check_release_define_file() {
  python3 -I - "$1" "$2" <<'PY'
import base64, json, re, sys, unicodedata
from urllib.parse import urlparse

prefix = sys.argv[1]
ANON = "SUPABASE_ANON_KEY"
duplicates = []


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
    run = r"[A-Za-z0-9_=+/-]"
    pattern = rf"(?<!{run}){run}+(?:\.{run}+){{2,}}"
    for source in (text, squeezed):
        found.update(re.findall(pattern, source))
    return found


def roles_of(segment):
    """None if the segment is not a base64(url) JSON object, else the list of
    every value of a "role" key at any depth (duplicates included)."""
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


def squash(text):
    return "".join(drop_invisible(text).split()).lower()


def has_marker(text):
    plain = squash(text).replace("_", "")
    return "sbsecret" in plain or "servicerole" in plain or jwt_findings(text)[0]


def label(key):
    """The key name if it is safe to print, else a stand-in."""
    if re.fullmatch(r"[A-Z][A-Z0-9_]{0,63}", key) and not has_marker(key):
        return key
    return "a define key"


def texts(node):
    """(text, is_key_name) for every string and every dict key inside node,
    iteratively so that nesting depth cannot exhaust the stack."""
    stack = [node]
    while stack:
        item = stack.pop()
        if isinstance(item, str):
            yield item, False
        elif isinstance(item, dict):
            for name, child in item.items():
                yield name, True
                stack.append(child)
        elif isinstance(item, list):
            stack.extend(item)


def load_object(pairs):
    seen = set()
    for name, _ in pairs:
        if name in seen:
            duplicates.append(name)
        seen.add(name)
    return dict(pairs)


def check():
    try:
        with open(sys.argv[2], encoding="utf-8") as fh:
            data = json.load(fh, object_pairs_hook=load_object)
    except (OSError, ValueError) as exc:
        sys.exit(f"{prefix}: cannot read define file as JSON: {type(exc).__name__}")
    if not isinstance(data, dict):
        sys.exit(f"{prefix}: define file must be a JSON object")
    bad = []
    for name in dict.fromkeys(duplicates):
        bad.append(f"{label(name)} appears more than once in the define file")
    for key in ("SUPABASE_URL", "API_BASE_URL"):
        value = data.get(key)
        if not isinstance(value, str) or not value.strip():
            bad.append(f"{key} is missing or empty")
            continue
        parsed = urlparse(value.strip())
        if parsed.scheme != "https" or not parsed.netloc:
            bad.append(f"{key} must be an absolute https URL")
    key_value = data.get(ANON)
    if not isinstance(key_value, str) or not key_value.strip():
        bad.append(f"{ANON} is missing or empty")
    for key, value in data.items():
        is_anon = key == ANON
        privileged = role_bad = undecodable = False
        for text, is_name in [(key, True), *texts(value)]:
            strict = is_anon and not is_name
            cleaned = squash(text)
            if "sb_secret_" in cleaned or (strict and "service_role" in cleaned):
                privileged = True
            shape, decoded, roles = jwt_findings(text)
            if any(role != "anon" for role in roles):
                role_bad = True
            elif strict and shape:
                if not decoded:
                    undecodable = True
                elif not roles:
                    role_bad = True
        name = label(key)
        verb = "is" if is_anon else "holds"
        if privileged:
            bad.append(f"{name} {verb} a privileged key")
        if undecodable:
            bad.append(f"{name} looks like a JWT but cannot be decoded")
        if role_bad:
            bad.append(f'{name} {verb} a JWT whose role is not "anon"')
    if bad:
        sys.exit(f"{prefix}: " + "; ".join(dict.fromkeys(bad)))


try:
    check()
except Exception as exc:
    sys.exit(f"{prefix}: cannot check define file: {type(exc).__name__}")
PY
}
