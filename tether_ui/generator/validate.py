import json, os, re
from dsl import *

def load():
    import screens_shared, screens_prog_a, screens_prog_b, screens_records, screens_additions
    if not SCREENS:
        screens_shared.shared(); screens_prog_a.programs_a(); screens_prog_b.programs_b(); screens_records.records(); screens_additions.additions()
    return SCREENS

# Consent checklists and their session keys (TH-907). Each screen has exactly
# one checklist, and it must carry this key.
CONSENT_CHECKLISTS = {
    'ob_account': 'age_18_or_older',
    'records_consent': 'resources',
    'records_consent_bb': 'resources',
    'records_consent_device': 'data_types',
    'sd_caregiver': 'caregiver_can_see',
    'sf_buddy': 'buddy_can_see',
}

def validate():
    load()
    errors, warns = [], []
    routes = {}
    edges = []  # (from, label, type, to)
    for sid, s in SCREENS.items():
        if s['route'] in routes: errors.append(f'{sid}: route {s["route"]} duplicates {routes[s["route"]]}')
        routes[s['route']] = sid
        if s['variantOf'] and s['variantOf'] not in SCREENS: errors.append(f'{sid}: variantOf {s["variantOf"]} missing')
        acts = actions_of(s)
        exits = False
        for label, path, a in acts:
            if a is None:
                nodes = list(walk(s['body'], 'body')) + list(walk(s['footer'], 'footer'))
                if not any(n.get('state') == 'disabled' for n, p in nodes if p == path):
                    errors.append(f'{sid}: "{label}" at {path} has no action (loose end)')
                continue
            for t in targets(a):
                if t not in SCREENS and t not in TABS:
                    errors.append(f'{sid}: "{label}" → unknown target {t}')
                edges.append((sid, label, a['type'], t))
            if leaves(a): exits = True
            if a['type'] == 'branch' and len(a['cases']) < 2: errors.append(f'{sid}: branch "{label}" has <2 cases')
        if not exits: errors.append(f'{sid}: no way to leave this screen (dead end)')
        if s['kind'] == 'sheet' and not any(a and a['type'] in ('close', 'replace', 'reset', 'tab', 'branch', 'submit', 'toast') for _, _, a in acts):
            warns.append(f'{sid}: sheet without explicit close/cancel')
        for n, p in walk(s['body'] + s['footer']):
            if n['t'] == 'button' and not n.get('label'): errors.append(f'{sid}: unlabeled button at {p}')
    # decision keys / rules
    from rules import RULES, SCENARIOS
    allkeys = {f"{sid}.{n['key']}" for sid, s in SCREENS.items() for part in ('body', 'footer') for n, p in walk(s[part], part) if n.get('key') and n['t'] in INPUTS}
    def chk(sid, a):
        if not a: return
        d = a.get('decide')
        if d:
            if d.startswith('choice:'):
                if d[7:] not in allkeys: errors.append(f'{sid}: decide {d} references a missing input')
            elif d not in RULES: errors.append(f'{sid}: unknown rule {d}')
            else:
                outs = set(RULES[d]['outcomes'].values()); labels = {c['label'] for c in a['cases']}
                if not labels <= outs: errors.append(f'{sid}: branch cases {labels - outs} not produced by rule {d}')
        for c in a.get('cases', []): chk(sid, c['action'])
        chk(sid, a.get('then'))
    for sid, s in SCREENS.items():
        for l, p, a in actions_of(s): chk(sid, a)
        for part in ('body', 'footer'):
            for n, p in walk(s[part], part):
                if n['t'] == 'zone' and n.get('rule') and n['rule'] not in RULES: errors.append(f'{sid}: zone rule missing')
    for r, spec in RULES.items():
        for k in spec['inputs']:
            if k not in allkeys: errors.append(f'rule {r}: input {k} not on any screen')
    # Production inputs (TH-907). Session keys the API adapters map must be
    # explicit and stable, and no field may start with a value that would be
    # submitted if the member never types (P-31).
    for sid, p, k in AUTO_KEYS:
        errors.append(f'{sid}: input at {p} has no explicit key= (label slug {k!r}). Give it a stable key in the generator.')
    for sid, s in SCREENS.items():
        for part in ('body', 'footer'):
            for n, p in walk(s[part], part):
                if n['t'] == 'field' and n.get('value') is not None:
                    errors.append(f'{sid}: field {n.get("key")} at {p} starts with a value. P-31: an example is placeholder text only.')
                if n['t'] == 'tiles' and not n.get('key') and any(not it.get('action') for it in n['items']):
                    errors.append(f'{sid}: selection tiles at {p} have no key=, so the choice never reaches the session.')
    for sid, key in CONSENT_CHECKLISTS.items():
        found = [n for part in ('body', 'footer') for n, p in walk(SCREENS[sid][part], part) if n['t'] == 'checklist'] if sid in SCREENS else []
        if [n.get('key') for n in found] != [key]:
            errors.append(f'{sid}: consent checklist must have key={key!r} (found {[n.get("key") for n in found]}).')
    for scn in SCENARIOS:
        for x in [scn['start'], scn['expect']] + [st[1] for st in scn['steps'] if st[0] == 'expect']:
            if x not in SCREENS: errors.append(f'scenario {scn["id"]}: unknown screen {x}')
        for st in scn['steps']:
            if st[0] == 'enter' and st[1] not in allkeys: errors.append(f'scenario {scn["id"]}: unknown input {st[1]}')
    # Decision sources (R-31): V1-V5 on the spec, V6 on the catalogues.
    errors += check_branches(SCREENS)
    errors += check_catalogues(SCREENS)
    # tab roots
    for t in TABS:
        if t not in SCREENS: errors.append(f'tab root {t} missing')
    # reachability
    adj = {}
    for f, l, ty, t in edges: adj.setdefault(f, set()).add(t)
    for sid, s in SCREENS.items():
        if s['tab']: adj.setdefault(sid, set()).update(TABS)
    for sid, s in SCREENS.items():
        if s['variantOf']: adj.setdefault(s['variantOf'], set()).add(sid)
    start = [e['screen'] for e in ENTRIES]
    seen, stack = set(), list(start)
    while stack:
        x = stack.pop()
        if x in seen: continue
        seen.add(x)
        stack += list(adj.get(x, ()))
    for sid, s in SCREENS.items():
        base = s['variantOf']
        if sid not in seen and not (base and base in seen):
            errors.append(f'{sid}: unreachable from any entry point')
    inbound = {}
    for f, l, ty, t in edges: inbound.setdefault(t, set()).add(f)
    for sid, s in SCREENS.items():
        h = s.get('header') or {}
        if h.get('left') == 'back' and not inbound.get(sid) and not s['variantOf']:
            warns.append(f'{sid}: has Back but no inbound navigation')
    # phase coverage per program
    for p in ORDER:
        ph = {s['phase'] for s in SCREENS.values() if s['program'] == p}
        missing = [x for x in PHASES if x not in ph and x not in ('account',)]
        # account phase is covered by shared program_settings for every program
        if missing: warns.append(f'INFO {p}: phases without a program-specific screen: {", ".join(missing)} (covered by shared screens)')
    return errors, warns, edges

# ---------------------------------------------------------------- decision sources (R-31)
HERE = os.path.dirname(os.path.abspath(__file__))
KIT_NAV = os.path.join(HERE, 'dart_static', 'lib', 'ui', 'nav.dart')
SOURCES = ('rule', 'choice', 'server', 'auth', 'device', 'reference')

def branches(screens):
    """Every branch in `screens`, in screen and action order: a dict with
    screen, path (the element's action path), at (where inside that action,
    '' for the action itself), the branch itself, its declared deciders and
    the submit it sits directly under (through toasts only), if any, and the
    nearest submit it sits under at any depth (`outer`)."""
    out = []
    def visit(sid, path, at, a, submit, outer=None):
        if not a: return
        t = a['type']
        if t == 'branch':
            declared = []
            d = a.get('decide')
            if d: declared.append('choice' if d.startswith('choice:') else 'rule')
            if a.get('provider'): declared.append('auth')
            if a.get('ask') is not None or a.get('id') is not None:
                declared.append('reference' if a.get('ask') == 'reference' else 'device')
            out.append({'screen': sid, 'path': path, 'at': at, 'branch': a, 'declared': declared, 'submit': submit, 'outer': outer})
            for i, c in enumerate(a.get('cases', [])):
                visit(sid, path, f'{at}.cases[{i}].action'.lstrip('.'), c['action'], None, outer)
        elif t == 'submit':
            visit(sid, path, f'{at}.then'.lstrip('.'), a.get('then'), a, a)
        elif t == 'toast':
            visit(sid, path, f'{at}.then'.lstrip('.'), a.get('then'), submit, outer)
    for sid, s in screens.items():
        for _, path, a in actions_of(s):
            visit(sid, path, '', a, None)
    return out

def source_of(b):
    """The branch's one production decision source, or None when it has none
    or more than one (V1)."""
    if len(b['declared']) > 1: return None
    if b['declared']: return b['declared'][0]
    return 'server' if b['submit'] else None

def check_branches(screens):
    """V1-V5. Returns error messages."""
    errors = []
    seen_ids = {}
    for b in branches(screens):
        a, sid = b['branch'], b['screen']
        where = f"{sid}: branch at {b['path']}{(' ' + b['at']) if b['at'] else ''}"
        labels = [c['label'] for c in a.get('cases', [])]
        src = source_of(b)
        # V1: exactly one production decision source.
        if len(b['declared']) > 1:
            errors.append(f"V1 {where} has more than one decision source: {', '.join(b['declared'])}")
        elif src is None and b['outer']:
            # V4: the server outcome reaches only the branch right after its submit.
            errors.append(f"V4 {where} sits under the submit {b['outer']['api']} but not directly (only toasts may sit between), "
                          f"so that submit's server outcome cannot decide it")
        elif src is None:
            errors.append(f"V1 {where} has no production decision source: give it a rule or visible choice (decide), "
                          f"put it directly under the submit whose server outcome decides it, or a device hook (id, ask, when)")
        # V4: hook branches never sit directly under a submit.
        if b['submit'] and b['declared'] and b['declared'][0] in ('auth', 'device', 'reference'):
            errors.append(f"V4 {where}: a {b['declared'][0]} branch must not sit directly under a submit "
                          f"({b['submit']['api']}), whose server outcome would be a second source")
        if 'device' in b['declared'] or 'reference' in b['declared']:
            bid, ask, when = a.get('id'), a.get('ask'), a.get('when')
            # V2: ids required, unique, in the stable format.
            if not isinstance(bid, str) or not BRANCH_ID.match(bid):
                errors.append(f'V2 {where}: id {bid!r} must match {BRANCH_ID.pattern}')
            elif bid in seen_ids:
                errors.append(f'V2 {where}: id {bid!r} is also used by {seen_ids[bid]}')
            else:
                seen_ids[bid] = where
            if ask not in ASKS:
                errors.append(f'V3 {where}: ask {ask!r} is not one of {sorted(ASKS)}')
                continue
            if ask == 'reference':
                # V5: reference only on reference surfaces, and never decided in the app.
                if not screens[sid].get('reference'):
                    errors.append(f'V5 {where}: ask "reference" is allowed only on a reference surface (reference: true)')
                if when is not None:
                    errors.append(f'V3 {where}: a reference branch has no when map')
                continue
            # V3: when is total over the ask's answers, maps to existing cases, reaches every case.
            if not isinstance(when, dict):
                errors.append(f'V3 {where}: when must map every answer of {ask} to a case label')
                continue
            answers = ASKS[ask]
            missing = [x for x in answers if x not in when]
            extra = [x for x in when if x not in answers]
            if missing: errors.append(f'V3 {where}: when has no case for answers {missing} of {ask}')
            if extra: errors.append(f'V3 {where}: when has answers {extra} that {ask} never gives')
            reached = set()
            for ans, target in when.items():
                targets = list(target.values()) if isinstance(target, dict) else [target]
                if isinstance(target, dict):
                    pm = [x for x in ASKS['platform'] if x not in target]
                    px = [x for x in target if x not in ASKS['platform']]
                    if pm or px:
                        errors.append(f'V3 {where}: when[{ans!r}] per-platform map must have exactly {list(ASKS["platform"])}')
                for t in targets:
                    if t not in labels: errors.append(f'V3 {where}: when[{ans!r}] → {t!r} is not a case label')
                    reached.add(t)
            unreached = [l for l in labels if l not in reached]
            if unreached: errors.append(f'V3 {where}: cases {unreached} are never reached by when')
        elif a.get('when') is not None:
            errors.append(f'V3 {where}: when without a device ask')
    return errors

def kit_asks(nav_path=KIT_NAV):
    """TAsk values and their answers as declared in the Flutter kit:
    `name(<TAnswer>{TAnswer.a, TAnswer.b})` inside `enum TAsk { ... }`."""
    src = open(nav_path, encoding='utf-8').read()
    m = re.search(r'enum TAsk \{(.*?)\n\s*const TAsk\(', src, re.S)
    if not m: return None
    body = re.sub(r'//[^\n]*', '', m.group(1))
    return {name: tuple(re.findall(r'TAnswer\.(\w+)', ans)) for name, ans in re.findall(r'(\w+)\(<TAnswer>\{([^}]*)\}\)', body)}

def submit_endpoints(screens):
    """endpoint -> [screen ids] for every submit in `screens`, in order."""
    eps = {}
    def visit(sid, a):
        if not a: return
        if a['type'] == 'submit' and sid not in eps.setdefault(a['api'], []): eps[a['api']].append(sid)
        for c in a.get('cases', []): visit(sid, c['action'])
        visit(sid, a.get('then'))
    for sid, s in screens.items():
        for _, _, a in actions_of(s): visit(sid, a)
    return eps

def check_catalogues(screens, nav_path=KIT_NAV, not_queueable=None):
    """V6 (spec side): the generator's ask table matches the kit's TAsk /
    TAnswer, and the endpoint table classifies every submit endpoint."""
    errors = []
    kit = kit_asks(nav_path)
    nq = NOT_QUEUEABLE if not_queueable is None else not_queueable
    if kit is None:
        errors.append('V6 the Flutter kit declares no enum TAsk')
    elif kit != {k: tuple(v) for k, v in ASKS.items()}:
        diff = sorted(set(kit.items()) ^ set((k, tuple(v)) for k, v in ASKS.items()))
        errors.append(f'V6 dsl.ASKS and the kit TAsk differ: {diff}')
    eps = submit_endpoints(screens)
    for e in eps:
        if is_auth_endpoint(e) and e not in nq:
            errors.append(f'V6 auth endpoint {e!r} is not in dsl.NOT_QUEUEABLE (auth submits are never queued)')
    for e in nq:
        if e not in eps: errors.append(f'V6 dsl.NOT_QUEUEABLE lists {e!r}, which no screen submits')
    return errors

def branch_catalogue(screens):
    """spec/branches.json: every branch with its screen, path, source and
    labels; device branches add id, ask and when. Never the question text."""
    out = []
    for b in branches(screens):
        a = b['branch']
        r = {'screen': b['screen'], 'path': b['path'], 'at': b['at'], 'source': source_of(b), 'labels': [c['label'] for c in a['cases']]}
        if a.get('decide'): r['decide'] = a['decide']
        if a.get('provider'): r['provider'] = a['provider']
        if b['submit'] and not b['declared']: r['endpoint'] = b['submit']['api']
        for k in ('id', 'ask', 'when'):
            if a.get(k) is not None: r[k] = a[k]
        out.append(r)
    return out

def endpoint_catalogue(screens):
    """spec/endpoints.json: every submit endpoint, whether its result may be
    queued, and the screens that submit it."""
    return [{'endpoint': e, 'queueable': queueable(e), 'screens': sids} for e, sids in sorted(submit_endpoints(screens).items())]

def check_emitted(spec_dir):
    """V6 (emitted side): spec/branches.json and spec/endpoints.json match
    spec/screens.json on disk, and carry no question text."""
    errors = []
    try:
        screens = json.load(open(os.path.join(spec_dir, 'screens.json'), encoding='utf-8'))
        cat = json.load(open(os.path.join(spec_dir, 'branches.json'), encoding='utf-8'))
        eps = json.load(open(os.path.join(spec_dir, 'endpoints.json'), encoding='utf-8'))
    except (OSError, ValueError) as e:
        return [f'V6 cannot read the spec catalogues: {e}']
    if cat != branch_catalogue(screens):
        errors.append('V6 spec/branches.json does not match spec/screens.json: regenerate with build_all.py')
    if eps != endpoint_catalogue(screens):
        errors.append('V6 spec/endpoints.json does not match spec/screens.json: regenerate with build_all.py')
    questions = {b['branch']['question'] for b in branches(screens)}
    text = json.dumps(cat, ensure_ascii=False)
    for r in cat:
        if 'question' in r: errors.append(f"V6 spec/branches.json carries question text ({r['screen']} {r['path']})")
    for q in sorted(questions):
        if q not in {l for r in cat for l in r['labels']} and json.dumps(q, ensure_ascii=False) in text:
            errors.append(f'V6 spec/branches.json carries the question text {q!r}')
    return errors


def _expect(ok, message):
    """An explicit error, not an assert: `python -O` must not skip the check."""
    if not ok: raise AssertionError(message)

def _self_test():
    """python3 validate.py (also run by gen_dart.py): each decision-source
    check V1-V6 reports its error on a synthetic spec, and a correct spec
    passes. Uses no assert, so it survives `python -O`."""
    def scr(*actions, reference=False):
        s = {'id': 'st', 'header': None, 'body': [], 'footer': [button(f'B{i}', a) for i, a in enumerate(actions)], 'tab': None}
        if reference: s['reference'] = True
        return s
    two = [('Yes', back()), ('No', close())]
    dev = lambda **kw: branch('Q', [('Yes', back()), ('No', close())], **dict({'id': 'st.screen.check', 'ask': 'notificationsCheck', 'when': {'granted': 'Yes', 'denied': 'No'}}, **kw))
    def errs(screens): return check_branches(screens)
    def has(code, screens, text=''):
        found = [e for e in errs(screens) if e.startswith(code + ' ') and text in e]
        _expect(found, f'{code} {text!r} not reported; got {errs(screens)}')
    good = {'st': scr(dev(), submit('POST /x', toast('Saved', branch('Q', two))), branch('Q', two, decide='choice:st.k'),
                      branch('Q', [('iPhone', back()), ('Android', close())], id='st.screen.platform', ask='platform', when={'ios': 'iPhone', 'android': 'Android'}),
                      branch('Q', [('On A', back()), ('On B', close()), ('Off', back())], id='st.screen.per_platform', ask='notificationsCheck',
                             when={'granted': {'ios': 'On A', 'android': 'On B'}, 'denied': 'Off'})),
            'sr': dict(scr(branch('Q', two, id='st.screen.ref', ask='reference'), reference=True), id='sr')}
    _expect(errs(good) == [], f'a correct spec reports {errs(good)}')
    # V1: none, or more than one.
    has('V1', {'st': scr(branch('Q', two))}, 'no production decision source')
    has('V1', {'st': scr(dev(decide='hw.bp'))}, 'more than one')
    has('V1', {'st': scr(branch('Q', two, decide='hw.bp', id='st.screen.x', ask='reference'))}, 'more than one')
    # V2: id required, format, unique.
    has('V2', {'st': scr(dev(id=None))}, 'must match')
    has('V2', {'st': scr(dev(id='Screen.Check'))}, 'must match')
    has('V2', {'st': scr(dev(id='st.check'))}, 'must match')
    has('V2', {'st': scr(dev(), dev())}, 'also used by')
    # V3: known ask, total, existing cases, every case reached, per-platform total.
    has('V3', {'st': scr(dev(ask='nope'))}, 'is not one of')
    has('V3', {'st': scr(dev(when={'granted': 'Yes'}))}, 'no case for answers')
    has('V3', {'st': scr(dev(when={'granted': 'Yes', 'denied': 'No', 'unavailable': 'No'}))}, 'never gives')
    has('V3', {'st': scr(dev(when={'granted': 'Yes', 'denied': 'Maybe'}))}, 'is not a case label')
    has('V3', {'st': scr(dev(when={'granted': 'Yes', 'denied': 'Yes'}))}, 'never reached')
    has('V3', {'st': scr(dev(when={'granted': {'ios': 'Yes'}, 'denied': 'No'}))}, 'per-platform')
    has('V3', {'st': scr(dev(when=None))}, 'must map every answer')
    has('V3', {'st': scr(dict(branch('Q', two, decide='hw.bp'), when={'granted': 'Yes'}))}, 'without a device ask')
    has('V3', {'st': scr(dev(ask='reference'), reference=True)}, 'no when map')
    # V4: a server branch directly under its submit; no hook branch under a submit.
    has('V4', {'st': scr(submit('POST /x', branch('Q', [('Yes', branch('Q2', two)), ('No', back())], decide='choice:st.k')))}, 'not directly')
    has('V4', {'st': scr(submit('POST /x', dev()))}, 'must not sit directly under a submit')
    has('V4', {'st': scr(submit('POST /x', toast('Saved', branch('Q', two, ask=None) | {'provider': 'apple'})))}, 'must not sit directly under a submit')
    # V5: reference only on reference surfaces.
    has('V5', {'st': scr(branch('Q', two, id='st.screen.ref', ask='reference'))}, 'reference surface')
    # V6: kit parity, endpoint table, emitted catalogues.
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        def nav(text):
            path = os.path.join(d, 'nav.dart')
            open(path, 'w', encoding='utf-8').write(text)
            return path
        def enum(asks):
            values = ',\n'.join(f"  {k}(<TAnswer>{{{', '.join('TAnswer.' + x for x in v)}}})" for k, v in asks.items())
            return f'enum TAsk {{\n  /// doc; with a semicolon\n{values};\n\n  const TAsk(this.answers);\n}}\n'
        _expect(check_catalogues({}, nav(enum(ASKS)), ()) == [], f'V6 reports a matching kit: {check_catalogues({}, nav(enum(ASKS)), ())}')
        _expect(check_catalogues({}, KIT_NAV, ()) == [], 'V6 reports the real kit')
        _expect(any(e.startswith('V6 dsl.ASKS and the kit TAsk differ') for e in check_catalogues({}, nav(enum(dict(ASKS, platform=('ios',)))), ())), 'V6 kit answer mismatch not reported')
        _expect(any(e.startswith('V6 dsl.ASKS and the kit TAsk differ') for e in check_catalogues({}, nav(enum({k: v for k, v in ASKS.items() if k != 'reference'})), ())), 'V6 missing kit ask not reported')
        _expect(any(e.startswith('V6 the Flutter kit declares no enum TAsk') for e in check_catalogues({}, nav('class X {}'), ())), 'V6 missing enum not reported')
        auth = {'st': scr(submit('POST supabase /auth/v1/token', back()))}
        _expect(any('is not in dsl.NOT_QUEUEABLE' in e for e in check_catalogues(auth, KIT_NAV, ())), 'V6 unlisted auth endpoint not reported')
        _expect(check_catalogues(auth, KIT_NAV, ('POST supabase /auth/v1/token',)) == [], 'V6 reports a listed auth endpoint')
        _expect(any('which no screen submits' in e for e in check_catalogues({}, KIT_NAV, ('POST supabase /auth/v1/gone',))), 'V6 unused table entry not reported')
    with tempfile.TemporaryDirectory() as d:
        spec = {'st': dict(good['st'], actions=[{'action': a} for _, _, a in actions_of(good['st'])])}
        def write(cat, eps, screens=None):
            json.dump(screens or spec, open(os.path.join(d, 'screens.json'), 'w'))
            json.dump(cat, open(os.path.join(d, 'branches.json'), 'w'))
            json.dump(eps, open(os.path.join(d, 'endpoints.json'), 'w'))
            return check_emitted(d)
        cat, eps = branch_catalogue(spec), endpoint_catalogue(spec)
        _expect(write(cat, eps) == [], f'V6 reports matching catalogues: {write(cat, eps)}')
        _expect(any('branches.json does not match' in e for e in write(cat[1:], eps)), 'V6 stale branches.json not reported')
        _expect(any('endpoints.json does not match' in e for e in write(cat, [])), 'V6 stale endpoints.json not reported')
        leaked = [dict(cat[0], question='Q')] + cat[1:]
        _expect(any('carries question text' in e for e in write(leaked, eps)), 'V6 question text not reported')
        _expect(any('cannot read' in e for e in check_emitted(os.path.join(d, 'missing'))), 'V6 missing catalogue not reported')
    print('validate self-test: ok')

if __name__ == '__main__':
    _self_test()
    e, w, edges = validate()
    e += check_emitted(os.path.join(os.path.dirname(HERE), 'spec'))
    print(len(SCREENS), 'screens', len(edges), 'edges', len(e), 'errors', len(w), 'warnings')
    for x in e: print('ERR', x)
    for x in w: print('WARN', x)
    raise SystemExit(1 if e else 0)
