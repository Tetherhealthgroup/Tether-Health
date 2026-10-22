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
    # Settings binding and first-run consents (P-71, P-52).
    errors += check_settings(SCREENS)
    errors += check_program_context(SCREENS)
    errors += check_endpoint_classes(SCREENS)
    errors += check_plan_controls(SCREENS)
    errors += check_consent_starts(SCREENS)
    errors += check_unselected(SCREENS)
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


# ---------------------------------------------------------------- settings binding (P-71, P-52; TH-1008)
# A settings screen is any screen whose submit updates existing state: a
# PATCH or PUT, or a POST that changes an existing sharing grant
# (SETTINGS_POSTS). Each one is in exactly one of three pinned lists:
#  - CONSENT_SCREENS: controls that create, keep or end a consent, share,
#    caregiver alert, buddy message or cross-programme setting, and the
#    notification switches. They start from the stored value only; "nothing
#    stored" and "not loaded" both show the empty (off) state and write
#    nothing, and a save sends only what the member changed.
#  - PLAN_SCREENS: plans and profiles. A stored value seeds the control;
#    "nothing stored" seeds the designed starting value; "not loaded" writes
#    nothing. A save sends the whole screen state.
#  - NOT_BOUND_SCREENS: not bound, with the reason. On a settings screen in
#    this list every control that writes the session is in BIND_EXEMPT.
# The generator emits the first two lists for the app
# (lib/router/settings_screens.dart) and tells each bound control its class.
SETTINGS_POSTS = ('POST /v1/care/caregivers',)
CONSENT_SCREENS = ('account_notifications', 'account_privacy', 'program_settings', 'program_settings_sf', 'sd_caregiver', 'sf_buddy')
PLAN_SCREENS = ('be_q2', 'bf_meds_edit', 'bf_review', 'ca_plan', 'ck_q1', 'ea_plan', 'hw_targets', 'nu_habit', 're_result', 'sd_plan', 'sd_safety', 'st_range')
NOT_BOUND_SCREENS = {
    'auth_newpass': 'a new password: secret, and there is no stored state to show',
    'ob_consent': 'the first consents, in onboarding: the consent starting-state rule governs it',
    'sf_unplug_off': 'its only control is an action choice (BIND_EXEMPT)',
}
BIND_EXEMPT = {
    ('sf_unplug_off', 'scope'): 'action choice: what to turn off now, not stored state; either option only turns something off, so it keeps its designed start',
}
# A bind segment ":program" is replaced by the programme the screen was
# opened for (a route with ":program"); without one the control shows
# nothing and writes nothing.
PROGRAM_SEGMENT = ':program'
# A per-programme screen that stands for one programme only: whatever opens
# it must pass that programme. No route opens program_settings_sf today (it
# is a state of program_settings); without a programme its controls show
# nothing and write nothing.
PROGRAM_FIXED = {'program_settings_sf': 'sf'}

# Consent starting states (P-52 made mechanical, extended to every screen
# that creates a consent). On a screen that submits to a consent-creating
# endpoint (is_consent_creating), or carries a consent checklist
# (CONSENT_CHECKLISTS), an optional consent, sharing or import selection
# starts off: no toggle on, no item ticked, no chip, tile, radio item,
# segment or select value chosen. Bound controls are exempt (the consent
# class above governs them). CONSENT_START_ON is the permanent allowlist;
# CONSENT_START_PENDING lists selections that wait for an owner decision,
# and those screens must not be mapped to their endpoints until it is made.
# An allowlist entry is (screen, key), or (screen, path) for a control
# without a key.
#
# Endpoints are classified fail-closed: a write is consent-creating when it
# matches CONSENT_PATTERNS or is in CONSENT_CREATING_ALSO; every other submit
# endpoint must be in NOT_CONSENT_CREATING with a reason.
CONSENT_PATTERNS = (
    ('consent writes', lambda m, path: '/consents' in path),
    ('care writes', lambda m, path: path.startswith('/v1/care/')),
    ('records import and accept', lambda m, path: m == 'POST' and path.startswith('/v1/records/fhir/')),
)
CONSENT_CREATING_ALSO = {
    'PATCH /v1/enrolments/:id': 'sets care-team sharing and research for a programme',
    'PUT /v1/program-data/sf/plan': 'carries what the ScrollFree buddy may see',
}
_OWN = 'saves the member\'s own entry; shares nothing'
_PLAN = 'saves the member\'s own plan or profile; shares nothing'
_DEVICE = 'runs on the phone only; sends nothing'
_AUTH = 'account sign-in or recovery; creates no consent or share'
NOT_CONSENT_CREATING = {
    'CALL device:unplug/endSession': _DEVICE,
    'CALL device:unplug/liftShield+purgeLocalData': _DEVICE,
    'CALL device:unplug/setThresholds+applyShield': _DEVICE,
    'CALL device:unplug/startSession': _DEVICE,
    'PUT device:encrypted/ea/safety-plan': _DEVICE,
    'DELETE /v1/account/data': 'deletes the member\'s data; ends every share',
    'DELETE /v1/enrolments/:id': 'leaves a programme; ends its shares',
    'DELETE /v1/records/fhir/sources/:id': 'disconnects a records source; ends the import',
    'PATCH /v1/notifications/preferences': 'notification switches on this account; shares nothing',
    'POST /v1/account/export': 'sends the member a copy of their own data',
    'POST /v1/quit-plan/guest-import': 'moves the member\'s own guest plan into their account',
    'POST /v1/records/check-ins': _OWN, 'POST /v1/records/lapses': _OWN, 'POST /v1/records/lessons': _OWN,
    'POST /v1/records/manual': _OWN, 'POST /v1/records/rescues': _OWN,
    'POST /v1/program-data/be/diary': _OWN, 'POST /v1/program-data/be/survivorship': _OWN, 'POST /v1/program-data/ca/symptoms': _OWN,
    'POST /v1/program-data/ca/zone-checks': _OWN, 'POST /v1/program-data/ck/done': _OWN, 'POST /v1/program-data/ea/check-backs': _OWN,
    'POST /v1/program-data/ea/moods': _OWN, 'POST /v1/program-data/hw/lipids': _OWN, 'POST /v1/program-data/hw/readings': _OWN,
    'POST /v1/program-data/re/labs': _OWN, 'POST /v1/program-data/sd/falls': _OWN, 'POST /v1/program-data/sd/sessions': _OWN,
    'POST /v1/program-data/sf/pauses': _OWN, 'POST /v1/program-data/st/a1c': _OWN, 'POST /v1/program-data/st/readings': _OWN,
    'PUT /v1/program-data/be/profile': _PLAN, 'PUT /v1/program-data/bf/meds': _PLAN, 'PUT /v1/program-data/ca/plan': _PLAN,
    'PUT /v1/program-data/ck/profile': _PLAN, 'PUT /v1/program-data/hw/targets': _PLAN, 'PUT /v1/program-data/nu/habit': _PLAN,
    'PUT /v1/program-data/re/plan': _PLAN, 'PUT /v1/program-data/sd/plan': _PLAN, 'PUT /v1/program-data/sd/safety': _PLAN,
    'PUT /v1/program-data/st/range': _PLAN, 'PUT /v1/quit-plan': _PLAN,
    'POST supabase /auth/v1/recover': _AUTH, 'POST supabase /auth/v1/signup': _AUTH, 'POST supabase /auth/v1/token': _AUTH,
    'POST supabase /auth/v1/user/identities (linkIdentity)': _AUTH, 'PUT supabase /auth/v1/user': _AUTH,
}
CONSENT_START_ON = {
    ('ob_consent', 'essential_app_data'): 'Essential app data: required for the app to work, not optional',
    ('sf_unplug_off', 'scope'): 'action choice: either option only turns something off (BIND_EXEMPT)',
}
# Empty: P-78 and P-79 decided the starting selections it used to list.
CONSENT_START_PENDING = {}
# Selections pinned unselected (P-78, P-79): each must exist under this key
# on its screen, unbound, on a screen that submits to a consent-creating
# endpoint, and start off. The general rule above already fails a control
# that starts on; the pin also fails a renamed key, a dropped key or a
# screen whose submit is no longer classified as consent-creating.
CONSENT_START_UNSELECTED = {
    ('support_add_person', 'which_programs'): 'P-78',
    ('records_consent', 'resources'): 'P-78',
    ('records_consent_bb', 'resources'): 'P-78',
    ('records_consent_device', 'data_types'): 'P-78',
    ('records_review', 'keep_hw'): 'P-78, P-79',
    ('records_review', 'keep_st'): 'P-78, P-79',
    ('records_review', 'keep_ck'): 'P-78, P-79',
    ('records_review', 'keep_bf'): 'P-78, P-79',
    ('records_review', 'keep_re'): 'P-78, P-79',
    ('records_conflict', 'a1c'): 'as P-78',
    ('records_conflict', 'bp'): 'as P-78',
}
# Plan-class controls must not look like consents: a key, label or option
# with one of these words fails unless PLAN_CONSENT_WORDS_ALLOWED lists it
# ((screen, key), or (screen, path) for a control without a key).
PLAN_CONSENT_WORDS = re.compile(r'(?i)\b(shar(e|es|ed|ing)|research|caregivers?|consents?|care[ _]team|supporters?|buddy|clinician sees)\b')
PLAN_CONSENT_WORDS_ALLOWED = {
    ('sd_plan', 'body[2].children[0]'): 'to-do list without a key: writes nothing to the session and is never submitted; caregiver alerts are set on sd_caregiver',
}

def endpoint_parts(endpoint):
    """(method, path) of a submit endpoint ('supabase' and 'device:' paths too)."""
    method, _, rest = endpoint.partition(' ')
    if rest.startswith('supabase '): rest = rest[len('supabase '):]
    return method, rest.split(' ')[0]

def consent_category(endpoint, also=None):
    """The consent-creating category of `endpoint`, or None."""
    also = CONSENT_CREATING_ALSO if also is None else also
    if endpoint in also: return 'listed'
    method, path = endpoint_parts(endpoint)
    if method not in ('POST', 'PUT', 'PATCH', 'DELETE'): return None
    return next((name for name, match in CONSENT_PATTERNS if match(method, path)), None)

def is_consent_creating(endpoint, also=None): return consent_category(endpoint, also) is not None

def check_endpoint_classes(screens, not_creating=None, also=None):
    """Every submit endpoint is consent-creating (pattern or
    CONSENT_CREATING_ALSO) or listed in NOT_CONSENT_CREATING; no endpoint is
    both; every list entry is submitted somewhere."""
    not_creating = NOT_CONSENT_CREATING if not_creating is None else not_creating
    also = CONSENT_CREATING_ALSO if also is None else also
    errors, used = [], submit_endpoints(screens)
    for e in sorted(used):
        creating = is_consent_creating(e, also)
        if creating and e in not_creating:
            errors.append(f'endpoint {e!r} is consent-creating ({consent_category(e, also)}) but validate.NOT_CONSENT_CREATING lists it.')
        if not creating and e not in not_creating:
            errors.append(f'endpoint {e!r} is not classified: list it in validate.NOT_CONSENT_CREATING with a reason, or in CONSENT_CREATING_ALSO.')
    for e in sorted(set(not_creating) | set(also)):
        if e not in used: errors.append(f'endpoint {e!r} is classified in validate.py but no screen submits it: remove it.')
    return errors

def check_plan_controls(screens, plan=PLAN_SCREENS, allowed=None, also=None):
    """A plan-class screen submits to no consent-creating endpoint, and no
    plan control's key, label or option reads like a consent, share,
    research or caregiver choice (unless PLAN_CONSENT_WORDS_ALLOWED lists it)."""
    allowed = PLAN_CONSENT_WORDS_ALLOWED if allowed is None else allowed
    errors, used = [], set()
    for sid in plan:
        s = screens.get(sid)
        if s is None: continue
        for e in submits_of(s):
            if is_consent_creating(e, also):
                errors.append(f'{sid}: plan-class screen submits to consent-creating {e!r}; move it to validate.CONSENT_SCREENS.')
        for part in ('body', 'footer'):
            for n, p in walk(s[part], part):
                if n['t'] not in INPUTS + KEYED: continue
                texts = [n.get('key'), n.get('label'), n.get('sub')] + list(n.get('options') or [])
                texts += [x for i in n.get('items') or [] for x in (i.get('label'), i.get('sub'))]
                hits = sorted({m.group(0) for t in texts if t for m in [PLAN_CONSENT_WORDS.search(str(t).replace('_', ' '))] if m})
                if not hits: continue
                k = next((k for k in ((sid, n.get('key')), (sid, p)) if k in allowed and k[1] is not None), None)
                if k:
                    used.add(k); continue
                errors.append(f'{sid}: plan-class {n["t"]} {n.get("key")!r} at {p} reads like a consent ({", ".join(hits)}); make the screen consent-class or list it in validate.PLAN_CONSENT_WORDS_ALLOWED.')
    for k in allowed:
        if k not in used: errors.append(f'validate.PLAN_CONSENT_WORDS_ALLOWED entry {k} matches no plan control: remove it.')
    return errors

def _submits(a, out):
    if not a: return
    if a['type'] == 'submit': out.append(a['api'])
    for c in a.get('cases', []): _submits(c['action'], out)
    _submits(a.get('then'), out)

def submits_of(s):
    """Every submit endpoint on screen `s`, in order."""
    out = []
    for _, _, a in actions_of(s): _submits(a, out)
    return out

def is_settings(s):
    return any(e.split(' ', 1)[0] in ('PATCH', 'PUT') or e in SETTINGS_POSTS for e in submits_of(s))

def is_first_run(s): return s.get('flow') == 'onboarding' or s.get('phase') == 'onboarding'

def bind_class(sid, consent=CONSENT_SCREENS, plan=PLAN_SCREENS):
    """'consent', 'plan' or None for screen `sid`."""
    return 'consent' if sid in consent else 'plan' if sid in plan else None

def needs_bind(n):
    """True for a control that writes the session and so must be bound on a
    settings screen: every keyed input except text-like fields (P-31 already
    keeps them empty), keyed checklists and tiles, and select fields."""
    t = n['t']
    if not n.get('key'): return False
    if t == 'field': return n.get('kind') == 'select'
    return t in INPUTS or t in KEYED

def check_settings(screens, consent=CONSENT_SCREENS, plan=PLAN_SCREENS, not_bound=None, exempt=None):
    """Every settings screen is classified once; every control that writes
    the session on a consent or plan screen is bound (Rule 1) unless exempt,
    with a well-formed bind key; bind appears only on bindable controls of
    consent or plan screens; every exemption is used."""
    not_bound = NOT_BOUND_SCREENS if not_bound is None else not_bound
    exempt = BIND_EXEMPT if exempt is None else exempt
    errors, used = [], set()
    lists = {'CONSENT_SCREENS': set(consent), 'PLAN_SCREENS': set(plan), 'NOT_BOUND_SCREENS': set(not_bound)}
    for a, b in (('CONSENT_SCREENS', 'PLAN_SCREENS'), ('CONSENT_SCREENS', 'NOT_BOUND_SCREENS'), ('PLAN_SCREENS', 'NOT_BOUND_SCREENS')):
        for sid in sorted(lists[a] & lists[b]): errors.append(f'{sid} is in both validate.{a} and validate.{b}.')
    for name, ids in lists.items():
        for sid in sorted(ids):
            if sid not in screens: errors.append(f'validate.{name} lists {sid}, which is not a screen.')
            elif name != 'NOT_BOUND_SCREENS' and not is_settings(screens[sid]):
                errors.append(f'validate.{name} lists {sid}, which no longer updates existing state (PATCH, PUT or a sharing POST).')
    for sid, s in screens.items():
        if is_settings(s) and not any(sid in ids for ids in lists.values()):
            errors.append(f'{sid} updates existing state but is not classified: add it to validate.CONSENT_SCREENS, PLAN_SCREENS or NOT_BOUND_SCREENS (and bind its controls).')
    for sid, s in screens.items():
        cls, seen = bind_class(sid, consent, plan), {}
        for part in ('body', 'footer'):
            for n, p in walk(s[part], part):
                b, k = n.get('bind'), (sid, n.get('key'))
                if needs_bind(n) and b is None and (cls or (sid in not_bound and is_settings(s))):
                    if k in exempt: used.add(k)
                    elif cls:
                        errors.append(f'{sid}: {n["t"]} {n.get("key")!r} at {p} on a {cls}-class settings screen has no bind= (P-71: it must start from the member\'s stored state).')
                    else:
                        errors.append(f'{sid}: {n["t"]} {n.get("key")!r} at {p} writes the session on a screen listed as not bound: classify the screen, or list the control in validate.BIND_EXEMPT with a reason.')
                if b is None: continue
                if k in exempt:
                    errors.append(f'{sid}: {n.get("key")!r} at {p} is in validate.BIND_EXEMPT but has bind {b!r}.')
                if not cls:
                    errors.append(f'{sid}: bind {b!r} at {p} is not on a consent- or plan-class settings screen.')
                if n['t'] not in BINDABLE or (n['t'] == 'field' and n.get('kind') != 'select'):
                    errors.append(f'{sid}: bind {b!r} at {p} is on a {n["t"]}{" " + n.get("kind", "") if n["t"] == "field" else ""}; the kit binds only {", ".join(BINDABLE)} (select fields).')
                if not n.get('key'):
                    errors.append(f'{sid}: bind {b!r} at {p} is on a control with no key=.')
                if not isinstance(b, str) or not BIND_KEY.match(b):
                    errors.append(f'{sid}: bind {b!r} at {p} must be dot-separated lower-case segments or {PROGRAM_SEGMENT} (for example notifications.quiet_hours).')
                    continue
                per_program = PROGRAM_SEGMENT in s.get('route', '')
                if per_program and PROGRAM_SEGMENT not in b.split('.'):
                    errors.append(f'{sid}: bind {b!r} at {p} needs a {PROGRAM_SEGMENT} segment: the screen is opened per programme.')
                if not per_program and PROGRAM_SEGMENT in b.split('.'):
                    errors.append(f'{sid}: bind {b!r} at {p} has a {PROGRAM_SEGMENT} segment, but the screen\'s route has none.')
                if b in seen:
                    errors.append(f'{sid}: bind {b!r} at {p} is also used at {seen[b]}.')
                seen[b] = p
    for k in exempt:
        if k not in used:
            errors.append(f'validate.BIND_EXEMPT entry {k} matches no unbound control that writes the session on a settings screen: remove it.')
    return errors

def element_programs(s):
    """(path, action, programme) for every interactive element of screen
    `s`: a list row or tile takes its own programme (its lead or `program`),
    anything else the screen's."""
    out = []
    for part in ('body', 'footer'):
        for n, p in walk(s[part], part):
            if n['t'] == 'list':
                out += [(f'{p}.rows[{j}]', r['action'], (r.get('lead') or {}).get('program') or s.get('program')) for j, r in enumerate(n['rows']) if r.get('action')]
            elif n['t'] == 'tiles':
                out += [(f'{p}.items[{j}]', r['action'], r.get('program') or s.get('program')) for j, r in enumerate(n['items']) if r.get('action')]
            elif n.get('action') and n['t'] in ('button', 'link', 'authbtn', 'card', 'chart', 'banner'):
                out.append((p, n['action'], s.get('program')))
    return out

def check_program_context(screens, fixed=None):
    """A screen opened per programme (route with :program) is only pushed,
    from an element whose programme is known, so the kit can pass it on; a
    screen in PROGRAM_FIXED is opened only with its own programme."""
    fixed = PROGRAM_FIXED if fixed is None else fixed
    errors = []
    per = {sid for sid, s in screens.items() if PROGRAM_SEGMENT in s.get('route', '')}
    def visit(sid, p, a, prog):
        if not a: return
        if a.get('to') in per or any(v in per for v in (a.get('context') or {}).values()):
            if a['type'] != 'push': errors.append(f'{sid}: {p} opens {a.get("to")} with {a["type"]}; a per-programme screen is opened with a push only.')
            elif not prog: errors.append(f'{sid}: {p} opens {a["to"]} but no programme is known there (row lead, tile programme or screen programme).')
            elif a['to'] in fixed and prog != fixed[a['to']]: errors.append(f'{sid}: {p} opens {a["to"]} for programme {prog!r}; it stands for {fixed[a["to"]]!r} only (validate.PROGRAM_FIXED).')
        for c in a.get('cases', []): visit(sid, p, c['action'], prog)
        visit(sid, p, a.get('then'), prog)
    for sid, s in screens.items():
        for p, a, prog in element_programs(s): visit(sid, p, a, prog)
    return errors

def starts_on(n):
    """Whether selection control `n` starts with something selected."""
    t = n['t']
    if t == 'toggle': return bool(n.get('on'))
    if t == 'checklist': return any(i.get('done') for i in n['items'])
    if t == 'chips': return bool(n.get('selected'))
    if t == 'tiles': return any(i.get('selected') for i in n['items'] if not i.get('action'))
    if t == 'radio': return isinstance(n.get('selected'), int) and 0 <= n['selected'] < len(n['items'])
    if t == 'segmented': return n.get('selected') is not None
    if t == 'field' and n.get('kind') == 'select': return n.get('value') is not None
    return False

def check_unselected(screens, pinned=None, also=None, checklists=None):
    """Each CONSENT_START_UNSELECTED control exists under its key, is not
    bound, starts off, and its screen submits to a consent-creating endpoint
    or carries it as its consent checklist (CONSENT_CHECKLISTS).
    On a consent-creating screen, every checklist has a key, so each ticked
    item reaches the submit (P-79); a keyless one would show a choice that is
    never sent."""
    pinned = CONSENT_START_UNSELECTED if pinned is None else pinned
    checklists = CONSENT_CHECKLISTS if checklists is None else checklists
    errors = []
    for (sid, key), why in pinned.items():
        s = screens.get(sid)
        found = [n for part in ('body', 'footer') for n, p in walk(s[part], part) if n.get('key') == key] if s else []
        if len(found) != 1:
            errors.append(f'{sid}: pinned unselected control {key!r} ({why}) not found once (found {len(found)}); validate.CONSENT_START_UNSELECTED.'); continue
        n = found[0]
        if n.get('bind') is not None: errors.append(f'{sid}: pinned unselected control {key!r} ({why}) is bound; a bound control is not checked by its starting value.')
        if starts_on(n): errors.append(f'{sid}: {n["t"]} {key!r} starts selected ({why}): consent-creating selections start unselected, so the screen shows exactly what will be sent.')
        if not any(is_consent_creating(e, also) for e in submits_of(s)) and checklists.get(sid) != key:
            errors.append(f'{sid}: pinned unselected control {key!r} ({why}) but the screen submits to no consent-creating endpoint and it is not the screen\'s consent checklist.')
    for sid, s in screens.items():
        if not any(is_consent_creating(e, also) for e in submits_of(s)): continue
        for part in ('body', 'footer'):
            for n, p in walk(s[part], part):
                if n['t'] == 'checklist' and not n.get('key') and n.get('bind') is None:
                    errors.append(f'{sid}: checklist at {p} has no key= on a consent-creating screen, so the member\'s choices never reach the submit (P-79).')
    return errors

def check_consent_starts(screens, allowed=None, checklists=None, plan=PLAN_SCREENS, also=None):
    """P-52, extended: an optional consent, sharing or import selection on a
    consent-creating screen starts off, except the entries of `allowed`
    (CONSENT_START_ON and CONSENT_START_PENDING). Bound controls and
    plan-class screens are not checked. Every `allowed` entry must be used."""
    allowed = {**CONSENT_START_ON, **CONSENT_START_PENDING} if allowed is None else allowed
    checklists = CONSENT_CHECKLISTS if checklists is None else checklists
    errors, used = [], set()
    for sid, s in screens.items():
        if sid in plan: continue
        creating = any(is_consent_creating(e, also) for e in submits_of(s))
        for part in ('body', 'footer'):
            for n, p in walk(s[part], part):
                if n.get('bind') is not None: continue
                t = n['t']
                if t == 'toggle' and creating: on = bool(n.get('on'))
                elif t == 'checklist' and (creating or (n.get('key') is not None and checklists.get(sid) == n.get('key'))): on = any(i.get('done') for i in n['items'])
                elif t == 'chips' and creating: on = bool(n.get('selected'))
                elif t == 'tiles' and creating and n.get('key'): on = any(i.get('selected') for i in n['items'] if not i.get('action'))
                elif t == 'radio' and creating: on = isinstance(n.get('selected'), int) and 0 <= n['selected'] < len(n['items'])
                elif t == 'segmented' and creating: on = n.get('selected') is not None
                elif t == 'field' and n.get('kind') == 'select' and creating: on = n.get('value') is not None
                else: continue
                if not on: continue
                k = next((k for k in ((sid, n.get('key')), (sid, p)) if k in allowed and k[1] is not None), None)
                if k:
                    used.add(k); continue
                errors.append(f'{sid}: optional consent {t} {n.get("key")!r} at {p} starts on. P-52: the member chooses it; a starting value is never a consent (allowlists: validate.CONSENT_START_ON, CONSENT_START_PENDING).')
    for k in allowed:
        if k not in used:
            errors.append(f'consent allowlist entry {k} matches no consent control that starts on: remove it from validate.CONSENT_START_ON or CONSENT_START_PENDING.')
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
    _settings_self_test()
    print('validate self-test: ok')

def _settings_self_test():
    """check_settings, check_program_context and check_consent_starts (P-71,
    P-52) report each error on a synthetic spec, and a correct spec passes."""
    def sc(sid, body, api=None, flow='account', phase='account', route=None, program=None, footer=None):
        footer = footer if footer is not None else ([button('Save', submit(api, back()))] if api else [button('Done', back())])
        return {'id': sid, 'flow': flow, 'phase': phase, 'route': route or f'/{sid}', 'program': program, 'header': None, 'body': body, 'footer': footer, 'tab': None}
    def settings(*body, api='PATCH /v1/x', sid='set'): return sc(sid, list(body), api)
    def run(screens, consent=('set',), plan=(), not_bound=None, exempt=None): return check_settings(screens, consent, plan, not_bound or {}, exempt or {})
    def has(screens, text, why, **kw):
        got = run(screens, **kw)
        _expect(any(text in e for e in got), f'{why} not reported; got {got}')
    ok = {'set': settings(toggle('A', key='a', bind='x.a'), field('Name', key='name'), checklist(['One']), field('Pick', kind='select', key='pick', bind='x.pick')),
          'pl': settings(seg(['A', 'B'], 'A', key='u', bind='p.u'), api='PUT /v1/p', sid='pl'),
          'off': settings(radio(['Now', 'Later'], key='scope'), sid='off'),
          'pw': settings(field('Password', kind='password', key='password'), api='PUT /v1/pw', sid='pw'),
          'per': dict(settings(toggle('S', key='s', bind='e.:program.s'), sid='per'), route='/p/:program/settings'),
          'other': sc('other', [toggle('B', on=True, key='b')], 'POST /v1/x')}
    good = dict(consent=('set', 'per'), plan=('pl',), not_bound={'off': 'action', 'pw': 'secret'}, exempt={('off', 'scope'): 'action choice'})
    _expect(run(ok, **good) == [], f'a correct spec reports {run(ok, **good)}')
    has({'set': settings(toggle('A', key='a'))}, "toggle 'a' at body[0] on a consent-class settings screen has no bind=", 'unbound consent toggle')
    has({'pl': settings(toggle('A', key='a'), api='PUT /v1/p', sid='pl')}, "toggle 'a' at body[0] on a plan-class settings screen has no bind=", 'unbound plan toggle', consent=(), plan=('pl',))
    has({'set': settings(field('Pick', kind='select', key='pick'))}, "field 'pick'", 'unbound select field')
    has({'set': settings(checklist(['One'], key='c'))}, "checklist 'c'", 'unbound keyed checklist')
    has({'set': settings(chips(['A'], key='c'))}, "chips 'c'", 'unbound chips')
    has({'set': settings(seg(['A', 'B'], 'A', key='c'))}, "segmented 'c'", 'unbound segmented')
    has({'set': settings(radio(['A'], key='c'))}, "radio 'c'", 'unbound radio')
    has({'set': settings(slider('S', 1, key='s'))}, "slider 's'", 'unbound slider')
    has({'set': sc('set', [toggle('A', key='a')], 'POST /v1/care/caregivers')}, "toggle 'a'", 'unbound control on a sharing POST screen')
    # Classification.
    has({'set': settings(toggle('A', key='a', bind='x.a')), 'new': settings(sid='new')}, 'new updates existing state but is not classified', 'unclassified settings screen')
    has({'set': sc('set', [], 'POST /v1/x')}, 'validate.CONSENT_SCREENS lists set, which no longer updates existing state', 'stale consent entry')
    has({'pl': sc('pl', [], 'POST /v1/x')}, 'validate.PLAN_SCREENS lists pl', 'stale plan entry', consent=(), plan=('pl',))
    has({'set': settings(toggle('A', key='a', bind='x.a'))}, 'set is in both validate.CONSENT_SCREENS and validate.PLAN_SCREENS', 'screen in two classes', plan=('set',))
    has({'set': settings(toggle('A', key='a', bind='x.a'))}, 'validate.NOT_BOUND_SCREENS lists gone, which is not a screen', 'missing not-bound screen', not_bound={'gone': 'x'})
    # Exemptions.
    has({'set': settings(toggle('A', key='a', bind='x.a')), 'off': settings(radio(['Now'], key='scope'), sid='off')}, 'off: radio \'scope\' at body[0] writes the session on a screen listed as not bound', 'unexempt control on a not-bound screen', not_bound={'off': 'x'})
    has({'set': settings(toggle('A', key='a', bind='x.a'))}, "validate.BIND_EXEMPT entry ('set', 'gone') matches no unbound control", 'stale exemption', exempt={('set', 'gone'): 'x'})
    has({'set': settings(toggle('A', key='a', bind='x.a'))}, "is in validate.BIND_EXEMPT but has bind", 'exempt control that is bound', exempt={('set', 'a'): 'x'})
    _expect(run({'set': settings(toggle('A', key='a'))}, exempt={('set', 'a'): 'action choice'}) == [], 'an exempt consent-screen control is reported')
    # Bind placement and form.
    has({'set': settings(toggle('A', key='a', bind='x.a')), 'other': sc('other', [toggle('B', key='b', bind='x.b')], 'POST /v1/x')}, "other: bind 'x.b' at body[0] is not on a consent- or plan-class settings screen", 'bind outside settings')
    has({'set': settings(field('Name', key='name', bind='x.name'))}, 'is on a field text', 'bind on a text field')
    has({'set': settings(dict(slider('S', 1, key='s'), bind='x.s'))}, 'is on a slider', 'bind on a slider')
    has({'set': settings(checklist(['One'], bind='x.c'))}, 'is on a control with no key=', 'bind without key')
    has({'set': settings(toggle('A', key='a', bind='X.a'))}, 'must be dot-separated', 'bad bind format')
    has({'set': settings(toggle('A', key='a', bind='single'))}, 'must be dot-separated', 'one-segment bind')
    has({'set': settings(toggle('A', key='a', bind='x.a'), toggle('B', key='b', bind='x.a'))}, 'is also used at body[0]', 'duplicate bind')
    has({'set': dict(settings(toggle('A', key='a', bind='x.a')), route='/p/:program/s')}, 'needs a :program segment', 'per-programme screen without :program')
    has({'set': settings(toggle('A', key='a', bind='x.:program.a'))}, "has a :program segment, but the screen's route has none", ':program on a plain screen')
    # Programme context.
    per = dict(sc('ps', [], route='/p/:program/settings'))
    pc = lambda **s: check_program_context(dict(s, ps=per))
    _expect(pc(home=sc('home', [button('Settings', go('ps'))], program='bf'), acct=sc('acct', [rows([row('BreatheFree', lead=L_prog('bf'), action=go('ps'))])])) == [], 'a known programme is reported')
    _expect(any('no programme is known there' in e for e in pc(acct=sc('acct', [rows([row('Any', action=go('ps'))])]))), 'a push without a programme not reported')
    _expect(any('a per-programme screen is opened with a push only' in e for e in pc(home=sc('home', [button('Settings', rep('ps'))], program='bf'))), 'a replace to a per-programme screen not reported')
    _expect(any('no programme is known there' in e for e in pc(home=sc('home', [button('Settings', toast('x', go('ps')))]))), 'a nested push without a programme not reported')
    # Consent starting states (first run and every consent-creating screen).
    def fr(sid, body, api='POST /v1/enrolments/consents', flow='onboarding', phase='onboarding'): return sc(sid, body, api, flow, phase)
    allow = {('ob', 'req'): 'required'}
    def run5(screens, allowed=allow, checklists=None, plan=()): return check_consent_starts(screens, allowed, checklists or {}, plan)
    def has5(screens, text, why, allowed=allow, checklists=None, plan=()):
        got = run5(screens, allowed, checklists, plan)
        _expect(any(text in e for e in got), f'{why} not reported; got {got}')
    good5 = {'ob': fr('ob', [toggle('Required', on=True, key='req'), toggle('Optional', key='opt')]),
             'acct': sc('acct', [checklist(['Me'], key='age')], None, 'onboarding', 'account'),
             'pref': fr('pref', [toggle('Quiet hours', on=True, key='quiet')], None),
             'sup': sc('sup', [chips(['A', 'B'], key='progs'), field('Name', key='name')], 'POST /v1/care/supporters'),
             'set': sc('set', [toggle('Share', on=True, key='share', bind='x.share')], 'PATCH /v1/enrolments/consents'),
             'pl': sc('pl', [toggle('Remind', on=True, key='r')], 'POST /v1/enrolments/consents'),
             'todo': sc('todo', [checklist([ci('Walk', done=True)])], 'POST /v1/records/x')}
    _expect(run5(good5, checklists={'acct': 'age'}, plan=('pl',)) == [], f'a correct consent spec reports {run5(good5, checklists={"acct": "age"}, plan=("pl",))}')
    has5(dict(good5, ob=fr('ob', [toggle('Required', on=True, key='req'), toggle('Optional', on=True, key='opt')])), "ob: optional consent toggle 'opt' at body[1] starts on", 'optional consent starting on', plan=('pl',))
    has5(dict(good5, acct=sc('acct', [checklist([ci('Me', done=True)], key='age')], None, 'onboarding', 'account')), "acct: optional consent checklist 'age'", 'consent checklist ticked', checklists={'acct': 'age'}, plan=('pl',))
    has5(dict(good5, ob=fr('ob', [toggle('Required', on=True, key='req'), checklist([ci('One', done=True)], key='c')])), "checklist 'c'", 'ticked checklist on a consent screen', plan=('pl',))
    has5(dict(good5, sup=sc('sup', [chips(['A', 'B'], ['A'], key='progs')], 'POST /v1/care/supporters')), "sup: optional consent chips 'progs' at body[0] starts on", 'preselected programme on a supporter screen (not first run)', plan=('pl',))
    has5(dict(good5, rc=sc('rc', [checklist([ci('Labs', done=True)], key='res')], None, 'records', 'resources')), "rc: optional consent checklist 'res'", 'ticked records-import checklist', checklists={'acct': 'age', 'rc': 'res'}, plan=('pl',))
    has5(dict(good5, t=sc('t', [tiles([tl('Bf', selected=True), tl('Sf')], key='who')], 'POST /v1/care/summaries')), "t: optional consent tiles 'who'", 'preselected tile on a sharing screen', plan=('pl',))
    has5(good5, "pl: optional consent toggle 'r'", 'a plan-class exemption leaking to other screens')
    has5(dict(good5, ob=fr('ob', [toggle('Required', key='req'), toggle('Optional', key='opt')])), "('ob', 'req') matches no consent control", 'stale allowlist entry', plan=('pl',))
    _expect(any('starts on' in e for e in run5(good5, allowed={}, plan=('pl',))), 'the required control is not reported without its allowlist entry')
    pend = dict(good5, sup=sc('sup', [chips(['A', 'B'], ['A'], key='progs')], 'POST /v1/care/supporters'))
    _expect(run5(pend, allowed=dict(allow, **{}) | {('sup', 'progs'): 'pending owner decision'}, plan=('pl',)) == [], 'a pending allowlist entry does not pass its screen')
    # Starting states of radio, segmented and select controls on consent-creating screens.
    has5(dict(good5, r=sc('r', [radio(['Share', 'Do not share'], 0, key='who')], 'POST /v1/care/connections')), "r: optional consent radio 'who'", 'preselected radio on a connections screen', plan=('pl',))
    has5(dict(good5, r=sc('r', [seg(['Weekly', 'Daily'], 'Weekly', key='freq')], 'POST /v1/care/caregivers')), "r: optional consent segmented 'freq'", 'preselected segment on a caregiver screen', plan=('pl',))
    has5(dict(good5, r=sc('r', [dict(field('Topic', kind='select', key='topic'), value='Plan')], 'POST /v1/care/messages')), "r: optional consent field 'topic'", 'preselected select on a care message screen', plan=('pl',))
    has5(dict(good5, r=sc('r', [radio(['Keep', 'Drop'], 0, key='keep')], 'POST /v1/records/fhir/conflicts')), "r: optional consent radio 'keep'", 'preselected radio on a records import screen', plan=('pl',))
    _expect(run5(dict(good5, r=sc('r', [radio(['Keep', 'Drop'], -1, key='keep')], 'POST /v1/records/fhir/conflicts')), checklists={'acct': 'age'}, plan=('pl',)) == [], 'an unselected radio is reported')
    _expect(run5(dict(good5, r=sc('r', [checklist([ci('Labs', done=True)])], 'POST /v1/records/fhir/accept')), allowed=dict(allow) | {('r', 'body[0]'): 'x'}, checklists={'acct': 'age'}, plan=('pl',)) == [], 'a path allowlist entry for a keyless control does not pass')
    # Pinned unselected controls (P-78, P-79) and keyed checklists on consent-creating screens.
    cu = lambda screens, pinned, checklists=None: check_unselected(screens, pinned, {}, checklists or {})
    sup = lambda *body: {'sup': sc('sup', list(body), 'POST /v1/care/supporters')}
    pin = {('sup', 'progs'): 'P-78'}
    _expect(cu(sup(chips(['A', 'B'], key='progs')), pin) == [], 'an unselected pinned control is reported')
    _expect(any("chips 'progs' starts selected" in x for x in cu(sup(chips(['A', 'B'], ['A'], key='progs')), pin)), 'a pinned control starting selected not reported')
    _expect(any('not found once' in x for x in cu(sup(chips(['A', 'B'], key='programs')), pin)), 'a renamed pinned key not reported')
    _expect(any('is bound' in x for x in cu(sup(chips(['A', 'B'], key='progs', bind='x.p')), pin)), 'a bound pinned control not reported')
    _expect(any('submits to no consent-creating endpoint' in x for x in cu({'sup': sc('sup', [chips(['A'], key='progs')], 'PUT /v1/program-data/x')}, pin)), 'a pinned control off a consent screen not reported')
    _expect(cu({'rc': sc('rc', [checklist(['Labs'], key='res')], None)}, {('rc', 'res'): 'P-78'}, {'rc': 'res'}) == [], 'a pinned consent checklist without a submit is reported')
    _expect(any('starts selected' in x for x in cu({'r': sc('r', [radio(['Keep', 'Drop'], 1, key='keep')], 'POST /v1/records/fhir/conflicts')}, {('r', 'keep'): 'x'})), 'a pinned radio starting on a choice not reported')
    _expect(any('has no key= on a consent-creating screen' in x for x in cu({'r': sc('r', [checklist([ci('Labs')])], 'POST /v1/records/fhir/accept')}, {})), 'a keyless checklist on a consent-creating screen not reported')
    _expect(cu({'r': sc('r', [checklist([ci('Labs')])], 'PUT /v1/program-data/x')}, {}) == [], 'a keyless checklist off consent screens is reported')
    # Endpoint classes: each pattern category, the extra list, and fail-closed.
    for e, cat in (('POST /v1/enrolments/consents', 'consent writes'), ('PATCH /v1/enrolments/consents', 'consent writes'), ('POST /v1/care/caregivers', 'care writes'),
                   ('POST /v1/care/connections', 'care writes'), ('POST /v1/care/messages', 'care writes'), ('DELETE /v1/care/supporters/:id', 'care writes'),
                   ('POST /v1/records/fhir/accept', 'records import and accept'), ('POST /v1/records/fhir/sources/:id/sync', 'records import and accept')):
        _expect(consent_category(e, {}) == cat, f'{e} is {consent_category(e, {})}, not {cat}')
    for e in ('GET /v1/care/messages', 'DELETE /v1/records/fhir/sources/:id', 'POST /v1/records/manual', 'PUT /v1/program-data/st/range', 'CALL device:unplug/startSession'):
        _expect(consent_category(e, {}) is None, f'{e} is consent-creating')
    _expect(consent_category('PATCH /v1/x', {'PATCH /v1/x': 'shares'}) == 'listed', 'CONSENT_CREATING_ALSO not used')
    ec = lambda screens, nc=None, also=None: check_endpoint_classes(screens, nc or {}, also or {})
    one = lambda e: {'s': sc('s', [], e)}
    _expect(ec(one('POST /v1/care/connections')) == [], 'a care write needs listing')
    _expect(any('is not classified' in x for x in ec(one('POST /v1/new/thing'))), 'an unclassified write not reported')
    _expect(any('is not classified' in x for x in ec(one('CALL device:x'))), 'an unclassified device call not reported')
    _expect(ec(one('POST /v1/new/thing'), {'POST /v1/new/thing': 'own entry'}) == [], 'a listed write is reported')
    _expect(any('but validate.NOT_CONSENT_CREATING lists it' in x for x in ec(one('POST /v1/care/caregivers'), {'POST /v1/care/caregivers': 'x'})), 'a consent write listed as not consent-creating not reported')
    _expect(any('no screen submits it' in x for x in ec(one('POST /v1/care/caregivers'), {'POST /v1/gone': 'x'})), 'a stale not-consent entry not reported')
    _expect(any('no screen submits it' in x for x in ec(one('POST /v1/care/caregivers'), None, {'PATCH /v1/gone': 'x'})), 'a stale extra entry not reported')
    # Plan-class controls.
    pcs = lambda screens, allowed=None: check_plan_controls(screens, ('pl',), allowed or {}, {})
    _expect(pcs({'pl': sc('pl', [toggle('Private reminder', key='r', bind='p.r')], 'PUT /v1/p')}) == [], 'a plain plan control is reported')
    _expect(any('plan-class screen submits to consent-creating' in x for x in pcs({'pl': sc('pl', [], 'POST /v1/care/caregivers')})), 'a plan screen with a care write not reported')
    for label, key in (('Share with my care team', 'share'), ('De-identified research', 'r'), ('Caregiver alerts', 'c'), ('Reminder', 'consent_x'), ('Tell my buddy', 'b')):
        _expect(any('reads like a consent' in x for x in pcs({'pl': sc('pl', [toggle(label, on=True, key=key, bind='p.x')], 'PUT /v1/p')})), f'plan control {label!r} not reported')
    _expect(any('reads like a consent' in x for x in pcs({'pl': sc('pl', [checklist([ci('Walk'), ci('Share my steps')])], 'PUT /v1/p')})), 'a plan checklist item not reported')
    _expect(pcs({'pl': sc('pl', [checklist([ci('Share my steps')])], 'PUT /v1/p')}, {('pl', 'body[0]'): 'to-do'}) == [], 'an allowlisted plan control is reported')
    _expect(any('matches no plan control' in x for x in pcs({'pl': sc('pl', [], 'PUT /v1/p')}, {('pl', 'gone'): 'x'})), 'a stale plan allowlist entry not reported')
    # A fixed-programme screen opens only with its programme.
    fx = {'ps': sc('ps', [], route='/p/:program/sf')}
    _expect(check_program_context(dict(fx, h=sc('h', [button('S', go('ps'))], program='sf')), {'ps': 'sf'}) == [], 'the fixed programme is reported')
    _expect(any("it stands for 'sf' only" in x for x in check_program_context(dict(fx, h=sc('h', [button('S', go('ps'))], program='bf')), {'ps': 'sf'})), 'a fixed screen opened for another programme not reported')

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

def _spec_self_test(screens):
    """On the real spec: each CONSENT_START_UNSELECTED control set back to
    a starting selection fails both the general starting-state rule and the
    pin. Uses no assert, so it survives `python -O`."""
    import copy
    for (sid, key) in CONSENT_START_UNSELECTED:
        spec = copy.deepcopy(screens)
        n = next((n for part in ('body', 'footer') for n, p in walk(spec[sid][part], part) if n.get('key') == key), None)
        if n is None: continue  # check_unselected reports the missing key
        if n['t'] == 'checklist': n['items'][0]['done'] = True
        elif n['t'] == 'chips': n['selected'] = [n['options'][0]]
        elif n['t'] == 'radio': n['selected'] = 0
        else: raise ValueError(f'{sid}.{key}: no mutation for {n["t"]}')
        _expect(any(f'{sid}: optional consent' in x and repr(key) in x for x in check_consent_starts(spec)), f'{sid}.{key} starting selected passes check_consent_starts')
        _expect(any(f'{sid}: ' in x and 'starts selected' in x for x in check_unselected(spec)), f'{sid}.{key} starting selected passes check_unselected')
    print('validate spec self-test: ok')

if __name__ == '__main__':
    _self_test()
    e, w, edges = validate()
    e += check_emitted(os.path.join(os.path.dirname(HERE), 'spec'))
    print(len(SCREENS), 'screens', len(edges), 'edges', len(e), 'errors', len(w), 'warnings')
    for x in e: print('ERR', x)
    for x in w: print('WARN', x)
    _spec_self_test(SCREENS)
    raise SystemExit(1 if e else 0)
