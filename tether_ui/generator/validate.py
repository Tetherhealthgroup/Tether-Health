import json
from dsl import *

def load():
    import screens_shared, screens_prog_a, screens_prog_b, screens_records, screens_additions
    if not SCREENS:
        screens_shared.shared(); screens_prog_a.programs_a(); screens_prog_b.programs_b(); screens_records.records(); screens_additions.additions()
    return SCREENS

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
    for scn in SCENARIOS:
        for x in [scn['start'], scn['expect']] + [st[1] for st in scn['steps'] if st[0] == 'expect']:
            if x not in SCREENS: errors.append(f'scenario {scn["id"]}: unknown screen {x}')
        for st in scn['steps']:
            if st[0] == 'enter' and st[1] not in allkeys: errors.append(f'scenario {scn["id"]}: unknown input {st[1]}')
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

if __name__ == '__main__':
    e, w, edges = validate()
    print(len(SCREENS), 'screens', len(edges), 'edges', len(e), 'errors', len(w), 'warnings')
    for x in e: print('ERR', x)
    for x in w: print('WARN', x)
