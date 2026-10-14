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
#   Values are never printed. A define key name is printed only if it is in
#   the KNOWN_KEYS allowlist below (exact, case-sensitive match); any other
#   key is shown by position, because an arbitrary key name may itself be a
#   secret pasted into the wrong slot (R-085, TH-130). Position labels:
#     define key #3          the 3rd key of the top-level object (1-based, in
#                            file order)
#     define key #4>#2       the 2nd key of the object under top-level key #4;
#                            ">" descends one level, "[n]" is the n-th element
#                            (1-based) of an array, so #4>[1]>#2 is the 2nd key
#                            of the object in the first element of the array
#                            under key #4
#     define key #3 (also #5)   the same name occurs again at the listed
#                            positions of the same object (duplicates)
#   A flagged non-duplicate key under a top-level key is reported as that
#   top-level key. Needs python3.
check_release_define_file() {
  python3 -I - "$1" "$2" <<'PY'
import base64, json, re, sys, unicodedata
from urllib.parse import urlparse

prefix = sys.argv[1]
ANON = "SUPABASE_ANON_KEY"

# Define keys that may be printed by name. Every entry is a fixed constant of
# this project, never taken from the file. Sources (file:line at TH-130):
#   SUPABASE_URL, API_BASE_URL   lib/config/app_config.dart:12-13 and
#                                checked below in check() (this file)
#   SUPABASE_ANON_KEY            lib/config/app_config.dart:14 and ANON above
#   SUPABASE_SERVICE_ROLE_KEY    not read by the release scripts or app_config.
#                                It is the server-only key name in render.yaml:20
#                                and api/src/config/environment.ts:46. Listed
#                                so that the mistake this check exists to catch
#                                (an sb_secret_ value pasted under that name)
#                                is reported by its name (R1). The name is a
#                                public identifier, not a secret.
# The release scripts (tool/build_play_release.sh, tool/build_ios_release.sh)
# only pass the file through (--dart-define-from-file=, :94/:309 and :69/:178)
# and read no key by name.
KNOWN_KEYS = frozenset((
    "SUPABASE_URL",
    "API_BASE_URL",
    "SUPABASE_ANON_KEY",
    "SUPABASE_SERVICE_ROLE_KEY",
))


class Obj(dict):
    """A JSON object that remembers every key in file order, duplicates
    included (a plain dict keeps only the last)."""

    names = ()


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


def step(kind, number):
    return "#%d" % number if kind == "key" else "[%d]" % number


def label(name, path, spots):
    """The name if it is allowlisted, else its position: path is the steps
    down to the object holding the key, spots the 1-based positions of the
    key in that object (more than one for a duplicate)."""
    if name in KNOWN_KEYS:
        return name
    first, *more = spots
    text = "define key " + ">".join([*(step(*s) for s in path), step("key", first)])
    if more:
        text += " (also " + ", ".join(step("key", n) for n in more) + ")"
    return text


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
    obj = Obj(pairs)
    obj.names = [name for name, _ in pairs]
    return obj


def positions(obj):
    """name -> 1-based positions of that name in obj, in file order."""
    found = {}
    for number, name in enumerate(obj.names, 1):
        found.setdefault(name, []).append(number)
    return found


def duplicate_labels(root):
    """Labels of every key that occurs twice in one object, at any depth,
    iteratively so that nesting depth cannot exhaust the stack."""
    found = []
    stack = [(root, ())]
    while stack:
        node, path = stack.pop()
        if isinstance(node, Obj):
            spots = positions(node)
            for name, at in spots.items():
                if len(at) > 1:
                    found.append((path, at[0], label(name, path, at)))
            for name, child in node.items():
                stack.append((child, path + (("key", spots[name][-1]),)))
        elif isinstance(node, list):
            for number, child in enumerate(node, 1):
                stack.append((child, path + (("item", number),)))
    return [text for _, _, text in sorted(found, key=lambda f: f[:2])]


def check():
    try:
        with open(sys.argv[2], encoding="utf-8") as fh:
            data = json.load(fh, object_pairs_hook=load_object)
    except (OSError, ValueError) as exc:
        sys.exit(f"{prefix}: cannot read define file as JSON: {type(exc).__name__}")
    if not isinstance(data, dict):
        sys.exit(f"{prefix}: define file must be a JSON object")
    bad = []
    for text in duplicate_labels(data):
        bad.append(f"{text} appears more than once in the define file")
    top = positions(data)
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
        name = label(key, (), top[key][-1:])
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
