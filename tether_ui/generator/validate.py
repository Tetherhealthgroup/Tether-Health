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
    # A rule may also read a keyed checklist or tile set (ob.age reads the
    # "I’m 18 or older" checklist).
    rulekeys = allkeys | {f"{sid}.{n['key']}" for sid, s in SCREENS.items() for part in ('body', 'footer') for n, p in walk(s[part], part) if n.get('key') and n['t'] in KEYED}
    for r, spec in RULES.items():
        for k in spec['inputs']:
            if k not in rulekeys: errors.append(f'rule {r}: input {k} not on any screen')
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
    errors += check_age_gate(SCREENS, list(SCREENS), PRE_AGE_SIGN_IN)
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

# ---------------------------------------------------------------- sign-up age check (P-68, P-72, P-73)
# The checks fail closed. sign_up_age_route_test.dart carries the same two
# tables and runs the same checks on the emitted spec.
#  - Every submit to supabase /auth/ creates an account unless
#    AUTH_NOT_CREATING lists it, with the reason. Each account-creating submit
#    sits inside the ob.age rule's "Age confirmed" case on its own screen.
#  - Every native sign-in branch outside "Age confirmed" is listed in
#    PRE_AGE_SIGN_IN with exactly its outcome labels. Each only signs in,
#    links or re-confirms an existing account; any change to the set or to a
#    label needs the same review.
#  - A "… no Tether account" outcome enters the normal sign-up at its start
#    (ob_programs, as welcome "Get started" does) and creates nothing itself.
# validate() walks from every screen, so a screen no route reaches yet is
# checked too.
AUTH_NOT_CREATING = {
    'POST supabase /auth/v1/recover': 'sends a reset link for an existing account',
    'POST supabase /auth/v1/token': 'password grant: signs in an existing account',
    'POST supabase /auth/v1/user/identities (linkIdentity)': 'links an identity to the signed-in account',
    'PUT supabase /auth/v1/user': 'sets a new password on the signed-in account',
}
PRE_AGE_SIGN_IN = {
    ('auth_signin', 'body[1].items[0]'): [('Success', 'Success · guest plan on phone', 'New Apple ID, no Tether account', 'Cancelled', 'Error')],
    ('auth_signin', 'body[1].items[1]'): [('Success', 'Success · guest plan on phone', 'New Google account, no Tether account', 'Cancelled', 'Error')],
    ('auth_signin_error', 'body[2].items[0]'): [('Success', 'Success · guest plan on phone', 'New Apple ID, no Tether account', 'Cancelled', 'Error')],
    ('auth_signin_error', 'body[2].items[1]'): [('Success', 'Success · guest plan on phone', 'New Google account, no Tether account', 'Cancelled', 'Error')],
    ('auth_social_error', 'footer[0]'): [('Success', 'Error')],
    ('account_signin_methods', 'body[1].rows[1]'): [('Success', 'Email already has a Tether account', 'Cancelled', 'Error')],
    ('account_delete_apple', 'footer[0]'): [('Success', 'Different account', 'Cancelled', 'Error')],
    ('account_delete_google', 'footer[0]'): [('Success', 'Different account', 'Cancelled', 'Error')],
    ('auth_session_apple', 'footer[0].items[0]'): [('Success', 'Cancelled', 'Error')],
    ('auth_session_google', 'footer[0].items[0]'): [('Success', 'Cancelled', 'Error')],
}
AGE_RULE, AGE_CONFIRMED, SIGN_UP, NEW_IDENTITY = 'ob.age', 'Age confirmed', 'ob_programs', 'no Tether account'
NAVIGATIONS = ('push', 'replace', 'tab', 'sheet', 'reset', 'popto')

def creates_account(endpoint, allow=AUTH_NOT_CREATING):
    """True for a submit endpoint on supabase /auth/ that `allow` does not list."""
    return is_auth_endpoint(endpoint) and endpoint not in allow

def check_age_gate(screens, entries, pinned=None, allow=AUTH_NOT_CREATING):
    """Walk every route from `entries`, remembering whether it has passed
    "Age confirmed". Back and close are not followed: they return to a screen
    the walk already reached. A variant counts as reachable from its base,
    as in the reachability check. With `pinned`, the native sign-in branches
    reached before "Age confirmed" must equal it, and every `allow` entry
    must be submitted somewhere."""
    errors, via, todo, native = [], {}, [], {}
    def reach(state, prev, label):
        if state[0] in screens and state not in via:
            via[state] = (prev, label); todo.append(state)
    def route(state):
        out = []
        while state:
            prev, label = via[state]
            out.append((f'"{label}" → ' if label else '') + state[0])
            state = prev
        return ' '.join(reversed(out))
    def visit(state, label, path, a, ok):
        if not a: return
        t = a['type']
        if t == 'submit' and creates_account(a['api'], allow) and not ok:
            errors.append(f'age gate: {state[0]} "{label}" submits {a["api"]} outside {AGE_RULE} "{AGE_CONFIRMED}" '
                          f'(an auth endpoint creates an account unless AUTH_NOT_CREATING lists it); route: {route(state)}')
        if t in ('submit', 'toast'): visit(state, label, path, a.get('then'), ok)
        if t == 'branch':
            if a.get('provider') and not ok:
                native.setdefault((state[0], path), set()).add(tuple(c['label'] for c in a['cases']))
            for c in a['cases']:
                nxt = c['action']
                if a.get('provider') and NEW_IDENTITY in c['label'] and not (nxt['type'] in NAVIGATIONS and nxt['to'] == SIGN_UP):
                    errors.append(f'age gate: {state[0]} "{label}" outcome "{c["label"]}" must enter the normal sign-up ({SIGN_UP}) (P-73)')
                visit(state, label, path, nxt, ok or (a.get('decide') == AGE_RULE and c['label'] == AGE_CONFIRMED))
        if t in NAVIGATIONS:
            for to in (a['to'], (a.get('context') or {}).get('onboarding')):
                if to: reach((to, ok), state, label)
    for sid in entries: reach((sid, False), None, None)
    while todo:
        state = todo.pop(0)
        for label, path, a in actions_of(screens[state[0]]): visit(state, label, path, a, state[1])
        for vid, v in screens.items():
            if v.get('variantOf') == state[0]: reach((vid, state[1]), state, None)
    if pinned is not None:
        want = {k: set(v) for k, v in pinned.items()}
        for k in sorted(set(native) | set(want)):
            if native.get(k) != want.get(k):
                errors.append(f'age gate: native sign-in at {k[0]} {k[1]} outside "{AGE_CONFIRMED}" has outcomes {sorted(native.get(k, ()))}, '
                              f'PRE_AGE_SIGN_IN pins {sorted(want.get(k, ()))}')
        used = submit_endpoints(screens)
        for e in allow:
            if e not in used: errors.append(f'age gate: AUTH_NOT_CREATING lists {e!r}, which no screen submits')
    return list(dict.fromkeys(errors))

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
    _age_gate_self_test(scr)
    print('validate self-test: ok')

def _age_gate_self_test(scr):
    """check_age_gate fails closed: an account-creating or unknown auth submit
    outside "Age confirmed", a new-identity outcome that does not enter the
    normal sign-up, and a native sign-in branch that differs from the pinned
    table are each reported; the gated spec passes."""
    def sc(sid, *actions): return dict(scr(*actions), id=sid)
    new = 'New Apple ID, no Tether account'
    def social(to, *more): return branch('Apple', [(new, go(to)), ('Cancelled', back())] + list(more)) | {'provider': 'apple', 'decide': None}
    gate = lambda a: branch('Age', [('Age confirmed', a), ('Age not confirmed', toast('x'))], decide='ob.age')
    pin = {('si', 'footer[0]'): [(new, 'Cancelled')]}
    allow = {'POST supabase /auth/v1/token': 'signs in'}
    fixed = {'w': sc('w', sheet('si')), 'si': sc('si', social('ob_programs'), submit('POST supabase /auth/v1/token', back())),
             'ob_programs': sc('ob_programs', go('ob_account')),
             'ob_account': sc('ob_account', gate(submit('POST supabase /auth/v1/signup', back())), gate(social('ob_programs')))}
    def run(spec, entries=None): return check_age_gate(spec, list(spec) if entries is None else entries, pin, allow)
    _expect(run(fixed) == [], run(fixed))
    def has(spec, text, why, entries=None):
        got = run(spec, entries)
        _expect(any(text in e for e in got), f'{why} not reported; got {got}')
    old = dict(fixed, si=sc('si', social('sn'), submit('POST supabase /auth/v1/token', back())),
               sn=sc('sn', submit('POST supabase /auth/v1/token?grant_type=id_token', go('w'))))
    got = check_age_gate(old, ['w'], None, allow)
    _expect('age gate: sn "B0" submits POST supabase /auth/v1/token?grant_type=id_token outside ob.age "Age confirmed" '
            '(an auth endpoint creates an account unless AUTH_NOT_CREATING lists it); route: w "B0" → si "B0" → sn' in got, got)
    has(old, 'must enter the normal sign-up (ob_programs) (P-73)', 'new identity not entering the normal sign-up')
    has(dict(fixed, si=sc('si', social('ob_account'), submit('POST supabase /auth/v1/token', back()))), 'must enter the normal sign-up', 'new identity straight to ob_account')
    has(dict(fixed, ob_account=sc('ob_account', submit('POST supabase /auth/v1/signup', back()), gate(social('ob_programs')))), 'submits POST supabase /auth/v1/signup outside', 'ungated sign-up')
    has(dict(fixed, w=sc('w', sheet('si'), submit('POST supabase /auth/v1/otp', back()))), 'submits POST supabase /auth/v1/otp outside', 'unlisted auth endpoint')
    has(dict(fixed, x=sc('x', submit('POST supabase /auth/v1/signup', back()))), 'age gate: x ', 'screen no route reaches')
    has(dict(fixed, si=sc('si', social('ob_programs', ('Success', reset('today'))), submit('POST supabase /auth/v1/token', back()))), 'PRE_AGE_SIGN_IN pins', 'changed outcome labels')
    has(dict(fixed, w=sc('w', sheet('si'), social('ob_programs'))), 'native sign-in at w footer[1]', 'unpinned native sign-in')
    has(dict(fixed, ob_account=sc('ob_account', gate(submit('POST supabase /auth/v1/signup', back())), social('ob_programs'))), 'native sign-in at ob_account footer[1]', 'native sign-in before the age check')
    has({k: v for k, v in fixed.items() if k != 'si'} | {'w': sc('w', back())}, 'at si footer[0] outside "Age confirmed" has outcomes []', 'stale pinned entry')
    has(dict(fixed, si=sc('si', social('ob_programs'))), "AUTH_NOT_CREATING lists 'POST supabase /auth/v1/token'", 'unused allowlist entry')
    onb = {'w': sc('w', {'type': 'replace', 'to': 'x', 'context': {'onboarding': 'sn'}}), 'x': sc('x', back()), 'sn': old['sn']}
    _expect(any(e.startswith('age gate: sn ') for e in check_age_gate(onb, ['w'], None, allow)), 'onboarding-context route not followed')
    var = {'w': sc('w', back()), 'v': dict(sc('v', submit('POST supabase /auth/v1/signup', back())), variantOf='w')}
    _expect(any(e.startswith('age gate: v ') for e in check_age_gate(var, ['w'], None, allow)), 'variant of a reached screen not walked')

if __name__ == '__main__':
    _self_test()
    e, w, edges = validate()
    e += check_emitted(os.path.join(os.path.dirname(HERE), 'spec'))
    print(len(SCREENS), 'screens', len(edges), 'edges', len(e), 'errors', len(w), 'warnings')
    for x in e: print('ERR', x)
    for x in w: print('WARN', x)
    raise SystemExit(1 if e else 0)
