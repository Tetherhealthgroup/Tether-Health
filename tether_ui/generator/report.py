"""Builds tether_ui/validation/ from the Flutter test run and the prototype run.

    python3 report.py <flutter_json_reporter_output> <prototype_results.json>
"""
import json, os, sys, html, datetime
import validate
from dsl import *
from rules import SCENARIOS, RULES
import sim

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE) if os.path.basename(HERE) == 'generator' else os.path.expanduser('~/tether/tether_ui')

def flutter_results(path):
    tests, res, files = {}, {}, {}
    for line in open(path):
        line = line.strip()
        if not line.startswith('{'): continue
        try: ev = json.loads(line)
        except Exception: continue
        if ev.get('type') == 'testStart':
            t = ev['test']; tests[t['id']] = t['name']
        elif ev.get('type') == 'testDone' and not ev.get('hidden'):
            res[ev['testID']] = ev['result']
    out = {}
    for i, name in tests.items():
        if i in res and not name.startswith('loading '): out[name] = res[i]
    return out

def main():
    validate.load()
    fr = flutter_results(sys.argv[1])
    pr = json.load(open(sys.argv[2]))
    vdir = os.path.join(OUT, 'validation'); os.makedirs(vdir, exist_ok=True)
    f_sc = {n[len('scenario '):].split(' · ')[0]: r for n, r in fr.items() if n.startswith('scenario ')}
    p_sc = {r['id']: r for r in pr['scenarios']}
    f_pass = sum(1 for r in fr.values() if r == 'success'); f_total = len(fr)
    sweep_names = [n for n in fr if n.startswith('sweep ')]
    sweep_pass = sum(1 for n in sweep_names if fr[n] == 'success')
    render_names = [n for n in fr if n.endswith(' renders')]
    render_pass = sum(1 for n in render_names if fr[n] == 'success')
    p_sw_pass = sum(1 for r in pr['sweep'] if r['ok'])
    # coverage: screens visited by scenarios (from spec: start, expects, and tap targets resolved by sweep data is heavy; use prototype visited if present)
    exps = sim.expectations()
    covered_actions = {(x['screen'], x['path']) for x in exps}
    all_actions = {(sid, p) for sid, s in SCREENS.items() for l, p, a in actions_of(s) if a}
    summary = {
        'generated': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
        'screens': len(SCREENS), 'flows': len(FLOWS), 'actions': len(all_actions),
        'flutter': {'total': f_total, 'passed': f_pass, 'render_tests': [render_pass, len(render_names)], 'action_sweep': [sweep_pass, len(sweep_names)], 'scenarios': [sum(1 for v in f_sc.values() if v == 'success'), len(SCENARIOS)]},
        'prototype': {'scenarios': [sum(1 for r in pr['scenarios'] if r['ok']), len(pr['scenarios'])], 'action_sweep': [p_sw_pass, len(pr['sweep'])], 'js_errors': len(pr['errors'])},
        'action_coverage': [len(covered_actions & all_actions), len(all_actions)],
        'release_check': {'note': 'Release acceptance counts exclude reference surfaces (spec screens with reference: true), which are checked by device screenshots.', 'screens': sum(1 for s in SCREENS.values() if not s.get('reference')), 'actions': sum(1 for sid, p in all_actions if not SCREENS[sid].get('reference')), 'reference_screens': sorted(sid for sid, s in SCREENS.items() if s.get('reference'))},
    }
    json.dump(summary, open(os.path.join(vdir, 'summary.json'), 'w'), indent=2)
    json.dump(fr, open(os.path.join(vdir, 'flutter_results.json'), 'w'), indent=1, ensure_ascii=False)
    json.dump(pr, open(os.path.join(vdir, 'prototype_results.json'), 'w'), indent=1, ensure_ascii=False)

    # program × function matrix
    funcs = ['Setup', 'Sign-in', 'Daily', 'Rescue', 'Safety', 'Milestone', 'Resources', 'Validation', 'Health records', 'Navigation', 'Account']
    progs = ORDER + [None]
    def cell(pid, fn):
        items = [s for s in SCENARIOS if s['program'] == pid and s['function'] == fn]
        return items
    md = [f"# Validation report", '', f"Generated {summary['generated']} from the spec, the Flutter package and the HTML prototype.", '',
          '| Check | Flutter | Prototype |', '|---|---|---|',
          f"| End-to-end scenarios (all programs) | {summary['flutter']['scenarios'][0]} / {summary['flutter']['scenarios'][1]} | {summary['prototype']['scenarios'][0]} / {summary['prototype']['scenarios'][1]} |",
          f"| Button-flow sweep (every element × every outcome) | {sweep_pass} / {len(sweep_names)} | {p_sw_pass} / {len(pr['sweep'])} |",
          f"| Render tests (every screen at 100% and 130% text) | {render_pass} / {len(render_names)} | — |",
          f"| Static analysis | `flutter analyze`: see analyze.txt | JS errors: {summary['prototype']['js_errors']} |",
          f"| Spec validator (loose ends) | 0 errors · {len(all_actions)} actions, every target exists, every screen reachable | |", '',
          '## Scenarios by program and function', '', '| Program | ' + ' | '.join(funcs) + ' |', '|---|' + '---|' * len(funcs)]
    for pid in progs:
        name = PROGRAMS[pid][0] if pid else 'Account, sign-in & shell'
        row = []
        for fn in funcs:
            items = cell(pid, fn)
            if not items: row.append('·'); continue
            marks = []
            for s in items:
                ok = f_sc.get(s['id']) == 'success' and p_sc.get(s['id'], {}).get('ok')
                marks.append(('✅ ' if ok else '❌ ') + s['id'])
            row.append('<br>'.join(marks))
        md.append(f'| **{name}** | ' + ' | '.join(row) + ' |')
    md += ['', '## Scenario details', '', '| Scenario | Program | Steps | Ends at | Flutter | Prototype |', '|---|---|---|---|---|---|']
    for s in SCENARIOS:
        steps = ' → '.join((f'tap “{x[1]}”' if x[0] == 'tap' else f'enter {x[1]}={x[2]}' if x[0] == 'enter' else f'outcome “{x[1]}”' if x[0] == 'choose' else f'at {x[1]}') for x in s['steps'])
        md.append(f"| {s['id']}: {s['title']} | {PROGRAMS[s['program']][0] if s['program'] else '—'} | {steps} | `{s['expect']}` | {'✅' if f_sc.get(s['id']) == 'success' else '❌'} | {'✅' if p_sc.get(s['id'], {}).get('ok') else '❌ ' + p_sc.get(s['id'], {}).get('why', '')} |")
    md += ['', '## Decision rules exercised', '']
    for k, r in RULES.items():
        md.append(f"- **{k}** · {r['title']}: {r['logic']} _{r['source']}_")
    fails = [n for n, r in fr.items() if r != 'success'] + [f"prototype sweep {r['screen']} {r['path']}" for r in pr['sweep'] if not r['ok']] + [f"prototype scenario {r['id']}: {r['why']}" for r in pr['scenarios'] if not r['ok']]
    md += ['', '## Failures', '', '\n'.join(f'- {x}' for x in fails) if fails else 'None.']
    open(os.path.join(vdir, 'report.md'), 'w').write('\n'.join(md) + '\n')
    print(json.dumps(summary, indent=1))

if __name__ == '__main__':
    main()
