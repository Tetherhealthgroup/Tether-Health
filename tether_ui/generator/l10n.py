"""Localized strings for the generated app.

Every literal in the spec belongs to exactly one class (`classify`):

- `text`: member-visible copy. It gets a stable key, goes into the generated
  English catalog `spec/l10n/en.arb`, and generated screens read it from
  `TStrings` instead of a literal.
- everything else stays a literal: `identifier` (keys, routes, branch and
  case labels, rule outcomes, endpoints), `designer` (screen names, notes,
  preview questions), `unit`, `data` (numbers, initials, glyphs), `brand`,
  `phone`, `url`, `autonym` (a language named in itself) and `option-ref`
  (a `selected` that names an option).

Keys are `<screen id>.<path>.<prop>`, the element paths the generator
already uses for widget keys (`body[2]`, `footer[0].items[1]`, `header`),
or `<screen id>.<sid>.<prop>` when the node names an explicit `sid`, so a
node that moves can keep its key. Kit strings use `kit.<name>`.

Translations live in hand-maintained `spec/l10n/<locale>.arb` files. Each
entry records its `status` (draft-machine, draft-human or reviewed) and the
`sourceHash` of the English it was translated from; a translation whose hash
differs from the current English is stale and counts as missing. A locale is
a release locale only when every key is present, fresh and reviewed; any
other locale is a draft, available in debug builds only.

Messages may use a small ICU subset: `{name}` placeholders and
`{n, plural, =0{...} one{...} other{...}}` with `#` for the number. There is
no apostrophe quoting, and a literal brace is not allowed.
"""
import hashlib, json, os, re

from dsl import PROGRAMS

TEXT = 'text'
CLASSES = ('text', 'identifier', 'designer', 'unit', 'data', 'brand', 'phone', 'url', 'autonym', 'option-ref')
STATUSES = ('draft-machine', 'draft-human', 'reviewed')
PSEUDO = 'en-XA'
SOURCE = 'en'

# Plural categories per language (one = n == 1 for both). A locale whose
# language is not here cannot be generated until its rule is added.
PLURAL_RULES = {'en': 'n == 1', 'es': 'n == 1'}

# Names that stay as they are in every language, when a whole string is one.
BRANDS = frozenset([p[0] for p in PROGRAMS.values()] + [
    'Tether', 'Tether Health', 'Unplug', 'Apple', 'Google', 'Medicare', 'Epic MyChart',
    'Apple Health Records', 'Health Connect', 'Oracle Health (Cerner)'])

# Languages named in themselves (the welcome language choice).
AUTONYMS = frozenset(['English', 'Español'])

SID = re.compile(r'^[a-z][a-z0-9_]*$')
_PHONE = re.compile(r'^(911|988|\+?(1[ -])?(\(?[0-9]{3}\)?[ -])?[0-9]{3}-[0-9]{4})$')
_URL = re.compile(r'^(https?://|mailto:|tel:)')
_LETTER = re.compile(r'[^\W\d_]', re.UNICODE)

# Literal classes by owner and property. An owner is a node type (`t`), an
# action (`action:<type>`), a list item (`<node>.items`, `list.rows`, ...),
# `header` or `screen`. COMMON applies to every owner.
COMMON = {'t': 'identifier', 'type': 'identifier', 'key': 'identifier', 'bind': 'identifier', 'sid': 'identifier',
          'align': 'identifier', 'tone': 'identifier', 'size': 'identifier', 'variant': 'identifier', 'kind': 'identifier',
          'color': 'identifier', 'program': 'identifier', 'state': 'identifier', 'palette': 'identifier', 'platform': 'identifier'}
PROPS = {
    'screen': {'id': 'identifier', 'name': 'designer', 'route': 'identifier', 'flow': 'identifier', 'phase': 'identifier',
               'tab': 'identifier', 'variantOf': 'identifier', 'state': 'designer', 'bg': 'identifier', 'desc': 'designer',
               'notes': 'designer', 'over': 'designer', 'api': 'identifier'},
    'header': {'title': TEXT, 'left': 'identifier', 'pill': TEXT, 'avatar': 'data'},
    'eyebrow': {'text': TEXT},
    'title': {'text': TEXT},
    'text': {'text': TEXT},
    'quote': {'text': TEXT, 'caption': TEXT},
    'banner': {'text': TEXT, 'actionLabel': TEXT},
    'card': {'eyebrow': TEXT, 'title': TEXT, 'text': TEXT, 'tag': 'identifier', 'tagExtra': TEXT, 'accent': 'identifier', 'follows': 'identifier'},
    'kv': {'rows': TEXT},
    'list': {'title': TEXT},
    'list.rows': {'label': TEXT, 'sub': TEXT, 'value': TEXT, 'pill': TEXT},
    'list.rows.lead': {'avatar': 'data', 'icon': 'data'},
    'tiles.items': {'label': TEXT, 'sub': TEXT, 'glyph': 'data'},
    'stats.items': {'label': TEXT, 'value': TEXT, 'sub': TEXT},
    'chart': {'title': TEXT, 'caption': TEXT, 'unit': 'unit', 'tag': 'identifier', 'labels': TEXT},
    'big': {'value': TEXT, 'unit': 'unit', 'caption': TEXT},
    'timer': {'value': 'data', 'label': TEXT},
    'ring': {'value': 'data', 'label': TEXT},
    'calendar': {'month': TEXT, 'ym': 'identifier'},
    'field': {'label': TEXT, 'hint': TEXT, 'error': TEXT, 'placeholder': TEXT, 'unit': 'unit', 'value': TEXT, 'options': TEXT, 'values': 'identifier'},
    'slider': {'label': TEXT, 'minLabel': TEXT, 'maxLabel': TEXT, 'suffix': 'unit'},
    'toggle': {'label': TEXT, 'sub': TEXT},
    'checklist': {'label': TEXT},
    'checklist.items': {'label': TEXT, 'sub': TEXT},
    'chips': {'label': TEXT, 'options': TEXT, 'selected': 'option-ref', 'dots': 'identifier'},
    'segmented': {'label': TEXT, 'options': TEXT, 'values': 'identifier', 'selected': 'option-ref'},
    'radio': {'label': TEXT},
    'radio.items': {'label': TEXT, 'sub': TEXT, 'badge': TEXT},
    'button': {'label': TEXT, 'countLabel': TEXT, 'emptyLabel': TEXT, 'needs': 'identifier'},
    'link': {'label': TEXT},
    'authbtn': {'label': TEXT, 'provider': 'identifier', 'platforms': 'identifier'},
    'emergency': {'text': TEXT},
    'nativeslot': {'id': 'identifier', 'label': TEXT, 'caption': TEXT},
    'progtag': {'extra': TEXT},
    'illus': {'glyph': 'data'},
    'zone': {'selected': 'identifier', 'rule': 'identifier'},
    'action:push': {'to': 'identifier', 'arg': 'identifier'}, 'action:replace': {'to': 'identifier'}, 'action:tab': {'to': 'identifier'},
    'action:sheet': {'to': 'identifier'}, 'action:reset': {'to': 'identifier'}, 'action:popto': {'to': 'identifier'},
    'action:replace.context': {'onboarding': 'identifier'}, 'action:push.context': {'onboarding': 'identifier'},
    'action:toast': {'value': TEXT},
    'action:call': {'value': 'phone', 'label': 'phone'},
    'action:sms': {'value': 'phone'},
    'action:external': {'value': 'url'},
    'action:submit': {'api': 'identifier'},
    'action:branch': {'question': 'designer', 'decide': 'identifier', 'on': 'identifier', 'ask': 'identifier',
                      'id': 'identifier', 'provider': 'identifier'},
    'action:branch.cases': {'label': 'identifier'},
    'action:branch.when': {'*': 'identifier'},
}


def content_class(value, prop_class, options_with_values=False):
    """The class of a `text`-class literal after looking at its content."""
    if prop_class != TEXT: return prop_class
    if options_with_values and value in AUTONYMS: return 'autonym'
    if _PHONE.match(value): return 'phone'
    if not value or not _LETTER.search(value): return 'data'
    if value in BRANDS: return 'brand'
    if _URL.match(value): return 'url'
    return TEXT


def prop_class(owner, prop):
    """The class for `prop` on `owner`, or None when the pair is unclassified."""
    if owner.startswith('action:branch.when.'): owner = 'action:branch.when'  # per-platform answer maps
    if owner.endswith('.data'): return 'identifier'  # member-data bind keys ({property: key}, bindings.py)
    table = PROPS.get(owner, {})
    if prop in table: return table[prop]
    if '*' in table: return table['*']
    return COMMON.get(prop)


def literals(screens):
    """Yield (screen id, owner, prop, value, where, node) for every string in
    the spec, with `where` a readable location."""
    def visit(obj, owner, sid, where, node=None):
        if isinstance(obj, dict):
            for k, v in obj.items():
                yield from field(v, owner, k, sid, f'{where}.{k}', obj)
        elif isinstance(obj, list):
            for i, x in enumerate(obj):
                if isinstance(x, dict):
                    yield from visit(x, child_owner(owner, '', x), sid, f'{where}[{i}]', x)

    def field(v, owner, k, sid, where, node):
        if isinstance(v, str):
            yield sid, owner, k, v, where, node
        elif isinstance(v, list):
            for i, x in enumerate(v):
                if isinstance(x, str):
                    yield sid, owner, k, x, f'{where}[{i}]', node
                elif isinstance(x, list):  # kv rows
                    for j, y in enumerate(x):
                        if isinstance(y, str): yield sid, owner, k, y, f'{where}[{i}][{j}]', node
                elif isinstance(x, dict):
                    yield from visit(x, child_owner(owner, k, x), sid, f'{where}[{i}]', x)
        elif isinstance(v, dict):
            yield from visit(v, child_owner(owner, k, v), sid, where, v)

    def child_owner(owner, k, d):
        if 't' in d: return d['t']
        if 'type' in d: return 'action:' + d['type']
        if k in ('action', 'then', 'avatarAction'): return 'action:' + d.get('type', '?')
        if k == 'dots': return owner + '.dots'
        return f'{owner}.{k}'

    for sid, s in screens.items():
        for k, v in s.items():
            if k in ('header',) and v:
                yield from visit(v, 'header', sid, 'header', v)
            elif k in ('body', 'footer'):
                yield from visit(v, 'node', sid, k)
            elif k == 'actions':
                continue  # written by build_all from the nodes
            else:
                yield from field(v, 'screen', k, sid, k, s)


def check_literals(screens):
    """Every literal must be in exactly one class; returns error strings."""
    errs = []
    for sid, owner, prop, value, where, node in literals(screens):
        if owner == 'node': continue
        if owner.endswith('.dots'):
            continue  # option labels (keys) and program ids (values) of a chips' dots
        cls = prop_class(owner, prop)
        if cls is None:
            errs.append(f'{sid}: {where} ({owner}.{prop}) {value[:40]!r} has no literal class (l10n.PROPS)')
    return errs


# ---------------------------------------------------------------- ICU subset

class IcuError(ValueError):
    pass


def icu_parse(msg):
    """Parse the ICU subset into a list of parts: str, ('arg', name) or
    ('plural', name, {selector: parts}). Raises IcuError."""
    pos = 0

    def message(depth, in_plural):
        nonlocal pos
        out, buf = [], []
        while pos < len(msg):
            c = msg[pos]
            if c == '{':
                if buf: out.append(''.join(buf)); buf = []
                out.append(argument(depth))
            elif c == '}':
                if depth == 0: raise IcuError(f'unmatched }} at {pos} in {msg!r}')
                break
            elif c == '#' and in_plural:
                if buf: out.append(''.join(buf)); buf = []
                out.append(('#',))
                pos += 1
            else:
                buf.append(c); pos += 1
        if buf: out.append(''.join(buf))
        return out

    def name():
        nonlocal pos
        m = re.compile(r'\s*([A-Za-z][A-Za-z0-9_]*)\s*').match(msg, pos)
        if not m: raise IcuError(f'expected a name at {pos} in {msg!r}')
        pos = m.end()
        return m.group(1)

    def argument(depth):
        nonlocal pos
        pos += 1
        n = name()
        if pos < len(msg) and msg[pos] == '}':
            pos += 1
            return ('arg', n)
        if pos >= len(msg) or msg[pos] != ',': raise IcuError(f'expected , or }} after {n!r} in {msg!r}')
        pos += 1
        kind = name()
        if kind != 'plural': raise IcuError(f'only plural is supported, not {kind!r}, in {msg!r}')
        if pos >= len(msg) or msg[pos] != ',': raise IcuError(f'expected , after plural in {msg!r}')
        pos += 1
        cases = {}
        while True:
            m = re.compile(r'\s*(=\d+|zero|one|two|few|many|other)\s*').match(msg, pos)
            if not m:
                break
            sel = m.group(1)
            pos = m.end()
            if pos >= len(msg) or msg[pos] != '{': raise IcuError(f'expected {{ after {sel!r} in {msg!r}')
            pos += 1
            if sel in cases: raise IcuError(f'duplicate selector {sel!r} in {msg!r}')
            cases[sel] = message(depth + 1, True)
            if pos >= len(msg) or msg[pos] != '}': raise IcuError(f'unterminated {sel!r} case in {msg!r}')
            pos += 1
        while pos < len(msg) and msg[pos] == ' ': pos += 1
        if pos >= len(msg) or msg[pos] != '}': raise IcuError(f'unterminated plural in {msg!r}')
        pos += 1
        if 'other' not in cases: raise IcuError(f'plural {n!r} has no other case in {msg!r}')
        bad = [s for s in cases if s not in ('one', 'other') and not s.startswith('=')]
        if bad: raise IcuError(f'plural {n!r} uses {bad}: only =N, one and other are supported in {msg!r}')
        return ('plural', n, cases)

    parts = message(0, False)
    if pos != len(msg): raise IcuError(f'unexpected }} at {pos} in {msg!r}')
    return parts


def icu_args(parts, out=None):
    """{name: 'plural' | 'arg'} used by parsed `parts`."""
    out = {} if out is None else out
    for p in parts:
        if isinstance(p, tuple) and p[0] == 'arg':
            out.setdefault(p[1], 'arg')
        elif isinstance(p, tuple) and p[0] == 'plural':
            out[p[1]] = 'plural'
            for c in p[2].values(): icu_args(c, out)
    return out


def icu_map_text(parts, f):
    """`parts` back to a message string, with every literal text run passed
    through `f` (placeholders and plural syntax are kept)."""
    out = []
    for p in parts:
        if isinstance(p, str): out.append(f(p))
        elif p[0] == '#': out.append('#')
        elif p[0] == 'arg': out.append('{' + p[1] + '}')
        else:
            out.append('{' + p[1] + ', plural, ' + ' '.join(f'{s}{{{icu_map_text(c, f)}}}' for s, c in p[2].items()) + '}')
    return ''.join(out)


def icu_format(msg, args, lang='en'):
    """Formats `msg` like the kit does (for tests and the self-test)."""
    def run(parts, n=None):
        out = []
        for p in parts:
            if isinstance(p, str): out.append(p)
            elif p[0] == '#': out.append(str(n))
            elif p[0] == 'arg': out.append(str(args[p[1]]))
            else:
                v = args[p[1]]
                cases = p[2]
                sel = f'={v}' if f'={v}' in cases else ('one' if v == 1 and 'one' in cases else 'other')
                out.append(run(cases[sel], v))
        return ''.join(out)
    return run(icu_parse(msg))


# ---------------------------------------------------------------- pseudo-locale

_ACCENTS = dict(zip('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
                    'àƀçðéƒĝĥîĵķļɱñöþǫŕšţûṽŵẋýžÀƁÇÐÉƑĜĤÎĴĶĻṀÑÖÞǪŔŠŢÛṼŴẊÝŽ'))
PSEUDO_OPEN, PSEUDO_CLOSE = '⟦', '⟧'


def pseudo(msg):
    """The pseudo-locale form of an English message: accented letters, about
    40 % longer, in ⟦ ⟧ brackets. Placeholders and plural syntax are kept."""
    def run(t):
        acc = ''.join(_ACCENTS.get(c, c) for c in t)
        letters = sum(1 for c in t if c.isalpha())
        pad = '~' * ((letters * 2 + 4) // 5)
        return acc + pad if t.strip() else acc
    return PSEUDO_OPEN + icu_map_text(icu_parse(msg), run) + PSEUDO_CLOSE


# ---------------------------------------------------------------- catalogs

def source_hash(text): return hashlib.sha256(text.encode('utf-8')).hexdigest()


def accessor(key):
    """Dart getter name for `key`: lowerCamel words, numbers as N<digits>."""
    out = []
    for tok in re.findall(r'[A-Za-z][A-Za-z0-9]*|[0-9]+', key):
        if tok.isdigit(): out.append('N' + tok)
        else:
            parts = [p for p in re.split(r'(?<=[a-z0-9])(?=[A-Z])', tok) if p]
            for p in parts: out.append(p[:1].upper() + p[1:])
    name = ''.join(out)
    return name[:1].lower() + name[1:]


class Catalog:
    """The English catalog collected while generating: key -> entry."""

    def __init__(self):
        self.entries = {}       # key -> dict(text, screen, path, prop, description)
        self.untranslated = set()  # member-visible literals left as they are

    def add(self, key, text, screen, path, prop, description):
        old = self.entries.get(key)
        if old:
            if old['text'] != text: raise ValueError(f'{key}: two different English texts {old["text"]!r} and {text!r}')
            return
        icu_parse(text)
        self.entries[key] = {'text': text, 'screen': screen, 'path': path, 'prop': prop, 'description': description}

    def arb(self):
        out = {'@@locale': SOURCE}
        for k, e in self.entries.items():
            out[k] = e['text']
            meta = {'description': e['description'], 'screen': e['screen'], 'path': e['path'], 'prop': e['prop'],
                    'sourceHash': source_hash(e['text'])}
            ph = icu_args(icu_parse(e['text']))
            if ph: meta['placeholders'] = {n: {'type': 'num' if t == 'plural' else 'Object'} for n, t in sorted(ph.items())}
            out['@' + k] = meta
        return out


def read_locale(path, en):
    """Reads a hand-maintained <locale>.arb against the English entries `en`
    (key -> text). Returns (locale, translations {key: text} of fresh valid
    entries, problems [str], counts dict)."""
    data = json.load(open(path, encoding='utf-8'))
    name = os.path.basename(path)[:-4]
    problems = []
    loc = data.get('@@locale')
    if loc != name: problems.append(f'{name}.arb: @@locale is {loc!r}, expected {name!r}')
    lang = name.split('-')[0].split('_')[0]
    if lang not in PLURAL_RULES: problems.append(f'{name}.arb: no plural rule for {lang!r} (l10n.PLURAL_RULES)')
    fresh, counts = {}, {'stale': 0, 'draft': 0, 'reviewed': 0, 'invalid': 0}
    for k, v in data.items():
        if k.startswith('@'): continue
        if k not in en:
            problems.append(f'{name}.arb: {k} is not an English key'); counts['invalid'] += 1; continue
        meta = data.get('@' + k) or {}
        st = meta.get('status')
        if st not in STATUSES:
            problems.append(f'{name}.arb: {k} has status {st!r}, expected one of {STATUSES}'); counts['invalid'] += 1; continue
        if st == 'reviewed' and not (meta.get('reviewer') and meta.get('reviewDate') and meta.get('record')):
            problems.append(f'{name}.arb: {k} is reviewed without reviewer, reviewDate and record'); counts['invalid'] += 1; continue
        if not isinstance(v, str):
            problems.append(f'{name}.arb: {k} is not a string'); counts['invalid'] += 1; continue
        try:
            if icu_args(icu_parse(v)) != icu_args(icu_parse(en[k])):
                problems.append(f'{name}.arb: {k} placeholders differ from English'); counts['invalid'] += 1; continue
        except IcuError as e:
            problems.append(f'{name}.arb: {k}: {e}'); counts['invalid'] += 1; continue
        if meta.get('sourceHash') != source_hash(en[k]):
            counts['stale'] += 1; continue
        counts['reviewed' if st == 'reviewed' else 'draft'] += 1
        fresh[k] = (v, st)
    return name, fresh, problems, counts


def locale_status(en, fresh):
    """'release' when every English key has a fresh reviewed translation,
    else 'draft'; and the number of missing keys (absent or stale)."""
    missing = [k for k in en if k not in fresh]
    reviewed = all(st == 'reviewed' for _, st in fresh.values())
    return ('release' if not missing and reviewed else 'draft'), len(missing)


def load_locales(l10n_dir, en):
    """All hand-maintained locales: [(locale, status, {key: text}, missing, problems)]."""
    out = []
    if not os.path.isdir(l10n_dir): return out
    for f in sorted(os.listdir(l10n_dir)):
        if not f.endswith('.arb') or f in (SOURCE + '.arb',): continue
        loc, fresh, problems, _ = read_locale(os.path.join(l10n_dir, f), en)
        if loc in (SOURCE, PSEUDO): problems.append(f'{f}: {loc} is generated, not hand-maintained')
        status, missing = locale_status(en, fresh)
        out.append((loc, status, {k: v for k, (v, _) in fresh.items()}, missing, problems))
    return out


def dart_str(s):
    s = str(s).replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n')
    return f"'{s}'"


def strings_dart(cat, locales):
    """lib/l10n/strings.g.dart: per-locale const maps, the release and draft
    locale lists, the plural rule and typed accessors on TStrings."""
    en = {k: e['text'] for k, e in cat.entries.items()}
    release = [SOURCE] + [l for l, st, *_ in locales if st == 'release']
    drafts = [l for l, st, *_ in locales if st != 'release']
    names = {}
    for k in en:
        a = accessor(k)
        if a in names: raise ValueError(f'accessor {a} for {k} collides with {names[a]}')
        names[a] = k

    def table(name, m):
        return f'const Map<String, String> {name} = <String, String>{{\n' + ''.join(f'  {dart_str(k)}: {dart_str(v)},\n' for k, v in m.items()) + '};\n'

    var = {l: '_' + re.sub(r'[^A-Za-z0-9]', '', l) for l in [l for l, *_ in locales]}
    cases = [f"    case {dart_str(SOURCE)}:\n      return _en;"]
    for l, st, *_ in locales:
        cases.append(f"    case {dart_str(l)}:\n      return {'' if st == 'release' else 'release ? null : '}{var[l]};")
    cases.append(f"    case {dart_str(PSEUDO)}:\n      return release ? null : _pseudo;")
    rules = {}
    for lang, rule in PLURAL_RULES.items(): rules.setdefault(rule, []).append(lang)
    plural = ''.join(''.join(f"    case {dart_str(l)}:\n" for l in langs) + f"      return {rule} ? 'one' : 'other';\n" for rule, langs in rules.items())
    acc = []
    for a, k in names.items():
        args = icu_args(icu_parse(en[k]))
        if args:
            ps = ', '.join(f'required {"num" if t == "plural" else "Object"} {n}' for n, t in sorted(args.items()))
            ms = ', '.join(f"{dart_str(n)}: {n}" for n in sorted(args))
            acc.append(f'  String {a}({{{ps}}}) => format({dart_str(k)}, {{{ms}}});\n')
        else:
            acc.append(f'  String get {a} => get({dart_str(k)});\n')
    out = [f"""// GENERATED from the spec (spec/l10n/en.arb) and the hand-maintained
// translations in spec/l10n/<locale>.arb. Do not edit: re-run the generator.
// ignore_for_file: lines_longer_than_80_chars
import '../ui/strings.dart';

/// Locales a release build offers: every key present, fresh and reviewed.
const List<String> tReleaseLocales = <String>[{', '.join(dart_str(l) for l in release)}];

/// Locales offered in debug builds only (incomplete, stale or unreviewed).
const List<String> tDraftLocales = <String>[{', '.join(dart_str(l) for l in drafts)}];

/// The pseudo-locale (debug builds and tests only).
const String tPseudoLocale = {dart_str(PSEUDO)};

/// The catalog for [tag], or null when [release] builds do not include it.
Map<String, String>? tCatalog(String tag, {{required bool release}}) {{
  switch (tag) {{
{chr(10).join(cases)}
  }}
  return null;
}}

/// The plural category of [n] in [language].
String tPluralCategory(String language, num n) {{
  switch (language) {{
{plural}  }}
  return 'other';
}}

/// Typed accessors, one per key.
extension TStringsKeys on TStrings {{
{''.join(acc)}}}

""", table('_en', en), '\n', table('_pseudo', {k: pseudo(v) for k, v in en.items()})]
    for l, st, tr, *_ in locales:
        out += ['\n', table(var[l], tr)]
    return ''.join(out)


def write_outputs(cat, l10n_dir, flutter_lib, extra=''):
    """Writes spec/l10n/en.arb and lib/l10n/strings.g.dart. Hand-maintained
    locale files are read, never written. Returns the locale summary."""
    os.makedirs(l10n_dir, exist_ok=True)
    with open(os.path.join(l10n_dir, 'en.arb'), 'w', newline='\n', encoding='utf-8') as fh:
        fh.write(json.dumps(cat.arb(), indent=2, ensure_ascii=False) + '\n')
    en = {k: e['text'] for k, e in cat.entries.items()}
    locales = load_locales(l10n_dir, en)
    problems = [p for *_, ps in locales for p in ps]
    if problems: raise ValueError('\n'.join(problems))
    os.makedirs(os.path.join(flutter_lib, 'l10n'), exist_ok=True)
    with open(os.path.join(flutter_lib, 'l10n', 'strings.g.dart'), 'w', newline='\n', encoding='utf-8') as fh:
        fh.write(strings_dart(cat, locales) + extra)
    return [(l, st, missing) for l, st, _, missing, _ in locales]


# ---------------------------------------------------------------- kit strings

# Member-visible text the kit draws itself (tab bar, accessibility labels,
# fallback and error messages). Key -> (English, description).
KIT = {
    'kit.back': ('Back', 'Accessibility label of the header back button'),
    'kit.close': ('Close', 'Accessibility label of the header close button, and the close button of the call fallback'),
    'kit.account': ('Account', 'Accessibility label of the header avatar that opens Account'),
    'kit.tab_today': ('Today', 'Tab bar: the Today tab'),
    'kit.tab_plans': ('Plans', 'Tab bar: the Plans tab'),
    'kit.tab_progress': ('Progress', 'Tab bar: the Progress tab'),
    'kit.tab_learn': ('Learn', 'Tab bar: the Learn tab'),
    'kit.tab_support': ('Support', 'Tab bar: the Support tab'),
    'kit.tab_semantics': ('{tab} tab', 'Accessibility label of a tab bar item; {tab} is the tab name'),
    'kit.step_of': ('Step {n} of {total}', 'Accessibility label of the step dots'),
    'kit.zone_green': ('Green', 'Zone selector: green zone'),
    'kit.zone_yellow': ('Yellow', 'Zone selector: yellow zone'),
    'kit.zone_red': ('Red', 'Zone selector: red zone'),
    'kit.zone_semantics': ('{zone} zone', 'Accessibility label of a zone; {zone} is the zone name'),
    'kit.chart': ('Chart', 'Accessibility label of a chart without a title'),
    'kit.chart_semantics': ('{title}: {values}', 'Accessibility label of a chart: its title and its values'),
    'kit.chart_no_entry': ('no entry', 'Accessibility: a day without a value in a bar chart'),
    'kit.seconds': ('SECONDS', 'Breathing ring: default label under the number'),
    'kit.ring_semantics': ('{value} {label}', 'Accessibility label of the breathing ring: the number and its label'),
    'kit.timer_semantics': ('{value} {label}', 'Accessibility label of a timer: the time and its label'),
    'kit.weekday_initials': ('S M T W T F S', 'Calendar: initials of the days of the week, Sunday first, separated by spaces'),
    'kit.calendar_day': ('{month} {day}', 'Accessibility label of a calendar day: the month and the day number'),
    'kit.month_names': ('January|February|March|April|May|June|July|August|September|October|November|December', 'Calendar: names of the months, January first, separated by |'),
    'kit.weekday_names': ('Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday', 'Calendar: names of the days of the week, Sunday first, separated by |'),
    'kit.calendar_title': ('{month} {year}', 'Heading of a calendar: the month name and the year'),
    'kit.date_full': ('{weekday}, {month} {day}, {year}', 'A date in full: weekday, month name, day and year; also the accessibility label of a calendar day'),
    'kit.calendar_prev': ('Previous month', 'Accessibility label of the calendar button that shows the previous month'),
    'kit.calendar_next': ('Next month', 'Accessibility label of the calendar button that shows the next month'),
    'kit.calendar_recommended': ('Recommended', 'Accessibility hint of a calendar day inside the recommended window'),
    'kit.days_to_prepare': ('{n, plural, one{# day to prepare} other{# days to prepare}}', 'Under a chosen date: how many days are left to prepare; # is the number'),
    'kit.environment': ('Environment: {name}', 'Accessibility label of the environment badge (for example a test environment); {name} is the badge text'),
    'kit.quote': ('“{text}”', 'A quotation, in the quotation marks of the language'),
    'kit.emergency_help': ('Emergency help', 'Accessibility label of the emergency card'),
    'kit.loading': ('Loading', 'Accessibility label of a loading placeholder'),
    'kit.generic_error': ('Something went wrong. Please try again.', 'Message when an action cannot be completed'),
    # The tag on a design example value shown while the member has no value
    # of their own (P-89; "Example" is the owner's word). Screen readers
    # read it before the value.
    'kit.example': ('Example', 'Tag on a value that is a design example, not the member’s own data; read before the value'),
    'kit.call_fallback': ('Calling isn’t available here. Dial {number} now.', 'Shown when the phone cannot place a call; {number} is the number to dial'),
    'kit.sms_fallback': ('Texting isn’t available here. Text {number} now.', 'Shown when the phone cannot open Messages; {number} is the number to text'),
    'kit.copy': ('Copy', 'Button that copies the number in the call fallback'),
    'kit.copied': ('Copied', 'Confirmation after copying the number'),
}


def add_kit(cat):
    for k, (text, desc) in KIT.items():
        cat.add(k, text, 'kit', '', k[4:], desc)


# ---------------------------------------------------------------- self-test

def _expect(ok, message):
    if not ok: raise AssertionError(message)


def _self_test():
    """python3 gen_dart.py runs this: ICU parsing, pseudo, accessors, the
    locale status rules and the literal classes."""
    # ICU subset
    _expect(icu_format('Step {n} of {total}', {'n': 2, 'total': 5}) == 'Step 2 of 5', 'placeholder')
    p = '{n, plural, =0{No days} one{# day} other{# days}}'
    _expect([icu_format(p, {'n': n}) for n in (0, 1, 2, 21)] == ['No days', '1 day', '2 days', '21 days'], 'plural')
    _expect(icu_args(icu_parse('{a} and {n, plural, one{# {b}} other{#}}')) == {'a': 'arg', 'n': 'plural', 'b': 'arg'}, 'args')
    for bad in ('{', '}', '{n, plural, one{x}}', '{n, select, a{x} other{y}}', '{n, plural, few{x} other{y}}', 'a {b', '{1}'):
        try:
            icu_parse(bad)
        except IcuError:
            pass
        else:
            raise AssertionError(f'{bad!r} parsed')
    # pseudo keeps placeholders and syntax, brackets and lengthens text
    ps = pseudo('Step {n} of {total}')
    _expect(ps.startswith(PSEUDO_OPEN) and ps.endswith(PSEUDO_CLOSE) and '{n}' in ps and '{total}' in ps, ps)
    _expect(icu_args(icu_parse(pseudo(p)[1:-1])) == {'n': 'plural'}, pseudo(p))
    _expect(len(pseudo('Continue')) >= len('Continue') * 1.4, pseudo('Continue'))
    # accessors
    _expect(accessor('welcome.footer[0].label') == 'welcomeFooterN0Label', accessor('welcome.footer[0].label'))
    _expect(accessor('ob_programs.body[1].rows[10].label') != accessor('ob_programs.body[1].rows[1][0].label'), 'accessor collision')
    _expect(accessor('kit.tab_today') == 'kitTabToday', accessor('kit.tab_today'))
    # classes
    _expect(content_class('BreatheFree', TEXT) == 'brand', 'brand')
    _expect(content_class('988', TEXT) == 'phone' and content_class('1-855-335-3569', TEXT) == 'phone', 'phone')
    _expect(content_class('120', TEXT) == 'data' and content_class('4:12', TEXT) == 'data', 'data')
    _expect(content_class('https://x.test/', TEXT) == 'url', 'url')
    _expect(content_class('Español', TEXT, options_with_values=True) == 'autonym' and content_class('Español', TEXT) == TEXT, 'autonym')
    _expect(content_class('Call 988', TEXT) == TEXT and content_class('mmHg', 'unit') == 'unit', 'text')
    _expect(prop_class('button', 'label') == TEXT and prop_class('action:branch.cases', 'label') == 'identifier', 'props')
    _expect(prop_class('button', 'nope') is None, 'unclassified prop')
    errs = check_literals({'x': {'id': 'x', 'header': None, 'body': [{'t': 'button', 'label': 'Go', 'mystery': 'y'}], 'footer': []}})
    _expect(len(errs) == 1 and 'mystery' in errs[0], errs)
    # locale status: complete + fresh + reviewed = release; otherwise draft
    import tempfile
    en = {'a.x': 'Hello', 'a.y': 'Bye'}
    with tempfile.TemporaryDirectory() as d:
        def arb(name, entries):
            data = {'@@locale': name}
            for k, (v, meta) in entries.items():
                data[k] = v
                data['@' + k] = meta
            open(os.path.join(d, name + '.arb'), 'w', encoding='utf-8').write(json.dumps(data))
            return read_locale(os.path.join(d, name + '.arb'), en)
        rev = {'status': 'reviewed', 'reviewer': 'r', 'reviewDate': '2026-10-22', 'record': 'rec-1'}
        h = {k: source_hash(v) for k, v in en.items()}
        _, fresh, probs, _ = arb('es', {'a.x': ('Hola', dict(rev, sourceHash=h['a.x'])), 'a.y': ('Adiós', dict(rev, sourceHash=h['a.y']))})
        _expect(not probs and locale_status(en, fresh) == ('release', 0), (probs, locale_status(en, fresh)))
        _, fresh, probs, c = arb('es', {'a.x': ('Hola', dict(rev, sourceHash=h['a.x'])), 'a.y': ('Adiós', dict(rev, sourceHash='0' * 64))})
        _expect(locale_status(en, fresh) == ('draft', 1) and c['stale'] == 1, 'stale counts as missing')
        _, fresh, probs, _ = arb('es', {'a.x': ('Hola', dict(rev, sourceHash=h['a.x']))})
        _expect(locale_status(en, fresh) == ('draft', 1), 'missing key')
        _, fresh, probs, _ = arb('es', {'a.x': ('Hola', {'status': 'draft-human', 'sourceHash': h['a.x']}),
                                        'a.y': ('Adiós', dict(rev, sourceHash=h['a.y']))})
        _expect(locale_status(en, fresh) == ('draft', 0), 'a draft entry keeps the locale a draft')
        _, fresh, probs, _ = arb('es', {'a.x': ('Hola', {'status': 'reviewed', 'sourceHash': h['a.x']})})
        _expect(probs and 'reviewed without' in probs[0], probs)
        _, fresh, probs, _ = arb('es', {'a.z': ('?', dict(rev, sourceHash='x'))})
        _expect(probs and 'not an English key' in probs[0], probs)
        _, fresh, probs, _ = arb('fr', {})
        _expect(any('no plural rule' in p for p in probs), probs)
        en2 = {'a.x': 'Step {n}'}
        open(os.path.join(d, 'es.arb'), 'w').write(json.dumps({'@@locale': 'es', 'a.x': 'Paso', '@a.x': dict(rev, sourceHash=source_hash('Step {n}'))}))
        _, fresh, probs, _ = read_locale(os.path.join(d, 'es.arb'), en2)
        _expect(probs and 'placeholders' in probs[0], probs)
    print('l10n self-test: ok')


if __name__ == '__main__':
    _self_test()
