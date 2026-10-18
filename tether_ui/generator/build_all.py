"""Build every deliverable in tether_ui/ from the screen spec.

    python3 build_all.py            # spec JSON, prototype, Dart, flows (markdown)
    python3 build_all.py --images   # + PNG screens, contact sheets, flow boards (needs playwright)
"""
import os, sys, json, shutil, csv, asyncio
from dsl import *
from validate import validate
import build_proto as B, gen_dart as G, sim, mapping
from render_html import CSS, render_screen

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE) if os.path.basename(HERE) == 'generator' else os.path.expanduser('~/tether/tether_ui')

def w(path, content):
    p = os.path.join(OUT, path); os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'w').write(content)

def wj(path, obj): w(path, json.dumps(obj, indent=2, ensure_ascii=False) + '\n')

def contrast(a, b):
    def L(hx):
        hx = hx.lstrip('#'); c = [int(hx[i:i + 2], 16) / 255 for i in (0, 2, 4)]
        c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
        return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
    x, y = sorted([L(a), L(b)], reverse=True)
    return round((x + 0.05) / (y + 0.05), 2)

def tokens():
    colors = {'teal': '#123C37', 'teal2': '#536F69', 'muted': '#5A726C', 'mint': '#DFF2E7', 'mintStrong': '#BFE1D2', 'cream': '#F8F5EC', 'paper': '#FFFDF7',
              'coral': '#FF7D61', 'coralFill': '#FFE9E2', 'coralText': '#B5432A', 'lime': '#D5EF75', 'line': '#B6C8C2', 'line2': '#DCE6E0',
              'error': '#B3261E', 'errorFill': '#FDECEA', 'errorText': '#7A1A14', 'warn': '#8A5A00', 'warnFill': '#FFF5DB', 'warnText': '#5C3D00', 'ok': '#2E6B3A', 'okFill': '#E5F3E8'}
    pairs = [('teal', 'paper'), ('teal2', 'cream'), ('muted', 'paper'), ('coralText', 'paper'), ('error', 'paper'), ('errorText', 'errorFill'), ('warnText', 'warnFill')]
    checks = [{'fg': a, 'bg': b, 'ratio': contrast(colors[a], colors[b])} for a, b in pairs]
    checks += [{'fg': 'white', 'bg': 'teal', 'ratio': contrast('#FFFFFF', colors['teal'])}, {'fg': 'teal', 'bg': 'coral', 'ratio': contrast(colors['teal'], colors['coral'])},
               {'fg': 'teal', 'bg': 'lime', 'ratio': contrast(colors['teal'], colors['lime'])}]
    checks += [{'fg': f'program.{k}', 'bg': 'paper', 'ratio': contrast(PROGRAMS[k][3], colors['paper'])} for k in ORDER]
    checks += [{'fg': 'white', 'bg': f'program.{k}', 'ratio': contrast('#FFFFFF', PROGRAMS[k][3])} for k in ORDER]
    for c in checks: c['wcag'] = 'AA' if c['ratio'] >= 4.5 else ('AA-large' if c['ratio'] >= 3 else 'FAIL')
    return {
        'meta': {'name': 'Tether Health design tokens', 'version': '1.0.0', 'reference_device': '390×844 pt (iPhone 14/15)', 'notes': 'Values are logical points. Same tokens drive the Flutter kit (lib/ui/tokens.dart) and the website.'},
        'color': colors,
        'program': {k: {'name': PROGRAMS[k][0], 'color': PROGRAMS[k][3], 'letter': PROGRAMS[k][4], 'archetype': PROGRAMS[k][2]} for k in ORDER},
        'type': {'family': 'Inter (bundle) or system; quote = Georgia italic',
                 'titleXl': [32, 1.12, 800], 'titleL': [28, 1.15, 800], 'titleM': [24, 1.15, 800], 'largeTitle': [30, 1.2, 800], 'headerTitle': [17, 1.3, 700],
                 'body': [15.5, 1.45, 400], 'muted': [15, 1.45, 400], 'small': [13, 1.4, 400], 'eyebrow': [11.5, 1.3, 800, 'caps +1.4'], 'label': [14, 1.3, 700],
                 'input': [16, 1.3, 600], 'button': [16, 1.2, 700], 'buttonSmall': [14, 1.2, 700], 'stat': [26, 1.1, 800], 'big': [44, 1.0, 800], 'quote': [20, 1.35, 400]},
        'space': {'xs': 4, 's': 8, 'm': 12, 'l': 16, 'xl': 20, 'xxl': 24, 'screenMargin': 20, 'blockGap': 12},
        'radius': {'control': 14, 'field': 12, 'card': 18, 'tile': 16, 'chip': 19, 'sheet': 26},
        'size': {'touchTargetMin': 44, 'button': 52, 'buttonSmall': 40, 'field': 50, 'chip': 38, 'header': 52, 'tabBar': '56 + home indicator'},
        'elevation': {'card': '0 10 20 -14 rgba(18,60,55,.28)', 'sheet': '0 -14 30 rgba(18,60,55,.25)'},
        'motion': {'enter': '200ms easeOutCubic', 'exit': '150ms', 'breath': '8s ease-in-out loop (disabled under Reduce Motion)'},
        'contrast': checks,
    }

COMPONENTS = {
    'header': ('THeader (in TScreen)', 'title, left: back|close|none|logo, pill, avatar → Account', 'Back/close always 44pt; large title on tab roots'),
    'steps': ('TSteps', 'n, total', 'Announces “Step n of total”'),
    'eyebrow': ('TEyebrow', 'text', 'Caps label'), 'title': ('TTitle', 'text, size m|l|xl, center', 'Semantics header'),
    'text': ('TBody', 'text, tone body|muted|small, center', ''),
    'chips': ('TChips', 'options, selected, multi, dots, label', 'Single or multi select; local state + onChanged'),
    'segmented': ('TSegmented', 'options, selected, label', ''), 'radio': ('TRadioList', 'items(label, sub, badge), selected, label', 'Drives radio-based branches'),
    'checklist': ('TChecklist', 'items(label, sub, done), label', ''), 'toggle': ('TToggleRow', 'label, sub, value', 'Switch.adaptive'),
    'field': ('TField', 'label, value, unit, hint, error, placeholder, kind', 'Error text says how to fix; kinds: text number email password phone date select multiline search'),
    'fieldrow': ('TFieldRow', 'children', 'Two fields side by side'), 'slider': ('TSliderField', 'label, value, min, max, minLabel, maxLabel, color', ''),
    'banner': ('TBanner', 'kind offline|error|success|info|urgent, text, actionLabel, onAction', 'Live region for error/urgent'),
    'card': ('TCard', 'variant plain|dark|dark2|coral|mint|urgent|warn|flat, tag, eyebrow, title, text, accent, onTap, cta, children', 'Whole card tappable when onTap'),
    'kv': ('TKeyValue', 'rows [(key, value)]', ''), 'list': ('TListGroup / TListRow', 'title, rows(label, sub, value, lead, pill, danger, onTap)', 'Chevron shown only when tappable'),
    'tiles': ('TTileGrid / TTile', 'columns, tiles(label, sub, program|glyph, selected, onTap)', 'Selection grid or navigation tiles'),
    'stats': ('TStatGrid / TStat', 'columns, stats(label, value, sub, program)', ''),
    'chart': ('TBarChart / TLineChart', 'values, color, title, unit, missing, target, band, labels, caption, tag, onTap', 'Missing days drawn hatched, never zero'),
    'zone': ('TZoneSelector', 'selected green|yellow|red', 'Drives zone branch'), 'ring': ('TBreathRing', 'value, label, palette', 'Respects Reduce Motion'),
    'big': ('TBigNumber', 'value, unit, caption', 'Scales down to fit'), 'button': ('TButton', 'label, onPressed, variant primary|rescue|secondary|danger|lime|white|ghostDark, small, arrow', 'Disabled when onPressed is null'),
    'buttons': ('TButtonRow', 'children', 'Wraps'), 'link': ('TLink', 'label, onTap, alignLeft', '44pt target'), 'quote': ('TQuote', 'text, caption', 'Member’s own words'),
    'illus': ('TIllustration', 'glyph, tone', 'Decorative, excluded from semantics'), 'emergency': ('TEmergencyCard', 'text, actions', '988 / 911 routes'),
    'skeleton': ('TSkeleton', 'lines', 'Loading'), 'progtag': ('TProgramTag', 'program, extra', ''), 'calendar': ('TCalendar', 'month, selected, window, today', ''),
    'timer': ('TTimer', 'value, label', 'Live region'), 'spacer': ('SizedBox', 'h', ''),
}

def flow_markdown(fid, describe):
    f = FLOWS[fid]
    lines = [f'# {f["title"]}', '', f['desc'], '', '```mermaid', 'flowchart LR']
    ids = f['screens']
    def nid(x): return x.replace('-', '_')
    for sid in ids:
        s = SCREENS[sid]
        shape = ('{{' + s['name'] + '}}') if s['kind'] == 'sheet' else (f'(["{s["name"]}"])' if s['kind'] == 'fullscreen' else f'["{s["name"]}"]')
        if s['kind'] == 'sheet': shape = f'{{{{"{s["name"]}"}}}}'
        lines.append(f'  {nid(sid)}{shape}')
    ext = set(); seen = set()
    for sid in ids:
        for l, p, a in actions_of(SCREENS[sid]):
            if p.startswith('tabbar'): continue
            for t in targets(a):
                if t == sid or (sid, t) in seen: continue
                seen.add((sid, t))
                lab = l.replace('"', "'")[:28]
                if t not in ids: ext.add(t)
                style = '-.->' if a['type'] in ('back', 'close') else '-->'
                lines.append(f'  {nid(sid)} {style}|"{lab}"| {nid(t)}')
    for t in sorted(ext):
        name = SCREENS[t]['name'] if t in SCREENS else t
        lines.append(f'  {nid(t)}>"{name} ↗"]')
        lines.append(f'  class {nid(t)} ext')
    lines += ['  classDef ext fill:#FFFDF7,stroke:#B6C8C2,stroke-dasharray: 4 3', '```', '', f'![Flow board](png/{fid}.png)', '', '## Screens', '',
              '| Screen | Route | Kind / state | Phase |', '|---|---|---|---|']
    for sid in ids:
        s = SCREENS[sid]
        lines.append(f'| [{s["name"]}](../screens/png/{fid}/{sid}.png) | `{s["route"]}` | {s["kind"]}{(" · " + s["state"]) if s["variantOf"] else ""} | {s["phase"]} |')
    lines += ['', '## Button & action map', '', '| Screen | Element | Action |', '|---|---|---|']
    for sid in ids:
        for l, p, a in actions_of(SCREENS[sid]):
            lines.append(f'| {SCREENS[sid]["name"]} | {l} | `{describe(a)}` |'.replace('|`', '| `'))
    return '\n'.join(lines) + '\n'

def readme(errs, warns, edges):
    n_sheets = sum(1 for s in SCREENS.values() if s['kind'] == 'sheet')
    n_var = sum(1 for s in SCREENS.values() if s['variantOf'])
    flows_tbl = '\n'.join(f'| [{f["title"]}](flows/{fid}.md) | {len(f["screens"])} | {f["desc"]} |' for fid, f in FLOWS.items())
    return f"""# Tether Health · UI for development

Single source of truth for the Tether Health mobile app (iOS + Android, Flutter): **{len(SCREENS)} screens and states**, **{len(FLOWS)} flows**, **{len(edges)} wired actions**, 11 programs.
Everything in this folder is generated from one spec, so the design, the clickable prototype, the screenshots and the Flutter code always match.

| | |
|---|---|
| Screens & states | {len(SCREENS)} ({n_var} state variants, {n_sheets} bottom sheets) |
| Wired actions | {len(edges)} (every button, row, tile, tab and link) |
| Loose ends | **{len(errs)}** (validator: no missing targets, no dead ends, no unreachable screens) |
| Flutter | `flutter analyze`: no issues · `flutter test`: 325 render tests (every screen at 100% and 130% text) + 6 end-to-end journeys pass |

## Folder map

```
tether_ui/
├── README.md                 ← you are here
├── prototype/index.html      ← clickable prototype: open in a browser, every button works
├── design/
│   ├── tokens.json           ← colors, type, spacing, radius, motion + WCAG contrast results
│   └── components.json       ← component catalog: spec node → Flutter widget, props, behavior
├── spec/
│   ├── app.json              ← entry points, tabs, flows, route table
│   ├── programs.json         ← the 11 programs (id, name, area, archetype, color)
│   ├── flows.json            ← flows and their screens
│   ├── screens.json          ← every screen: route, kind, state, components, actions, API
│   ├── screens/<id>.json     ← one file per screen (same data)
│   ├── actions.json/.csv     ← flat button → action → target map ({len(edges)} rows)
│   └── validation.md         ← loose-end report
├── flows/
│   ├── <flow>.md             ← Mermaid diagram + screen list + button/action map (renders on GitHub)
│   └── png/<flow>.png        ← flow boards: screen thumbnails with every navigation arrow
├── screens/
│   ├── png/<flow>/<id>.png   ← every screen at 2× (780 px wide; long screens show full scroll)
│   └── sheets/<flow>.png     ← contact sheet per flow
├── flutter/                  ← runnable Flutter package (zero third-party deps)
│   ├── lib/ui/               ← component kit (components.dart), tokens, navigation/actions (nav.dart)
│   ├── lib/router/           ← Routes constants + AppRouter (generated)
│   ├── lib/screens/<flow>/   ← one widget per screen (generated)
│   ├── lib/dev/gallery.dart  ← dev gallery of all screens
│   └── test/                 ← render tests for every screen + end-to-end journeys
└── generator/                ← Python that builds all of the above from the spec
```

## Run it

```bash
cd flutter
flutter pub get
flutter run                                  # opens the developer gallery of all {len(SCREENS)} screens
flutter run --dart-define=START=/welcome     # opens the real first-run flow
flutter analyze && flutter test              # 0 issues · all screens + journeys
```

Production wiring (one place each, `lib/ui/nav.dart`):
- `TPlatform.instance`: calls, SMS, URLs and OS settings (plug in `url_launcher`).
- `TApi.instance.submit(endpoint)`: every save names its endpoint (e.g. `POST /v1/records/check-ins`) from the develop-branch NestJS API.
- `TNav.branchResolver`: replace the preview chooser with real logic (validated BP average, computed zone, sign-in result…). Branches that depend on a visible choice (radio / segmented / zone) are marked `decided by:` in the code.
- `TFlow.onboarding`: set by the setup hub, so finishing a program plan during first run returns to setup instead of the program home.

## Change the design

Edit the spec (`generator/screens_*.py`), then:

```bash
cd generator
python3 build_all.py            # spec JSON, prototype, Dart, flow markdown + validation
python3 build_all.py --images   # also PNG screens, contact sheets and flow boards (needs playwright)
```

The build fails if any button has no action, any target is missing, any screen can’t be reached, or any screen is a dead end.

## Navigation model

- **Five tabs**: Today · Plans · Progress · Learn · Support. Avatar → Account. **Rescue** opens from Today, program homes, the widget/Siri entry and notifications.
- **Program homes** sit under Plans and keep the tab bar. Program settings (status, sharing, export, leave) are shared: `/p/:program/settings`.
- **Sheets** (`kind: sheet`) open as modal bottom sheets; **fullscreen** safety screens (red zone, crisis range, low glucose, I fell, crisis) have no tab bar and always offer 911/988 first.
- **States** of a screen (loading, offline, empty, error, safety, permission denied, quit day…) are separate routes with `?state=`, so each can be built, reviewed and tested on its own.

## Flows

| Flow | Screens | What it covers |
|---|---|---|
{flows_tbl}

## Entry points

{chr(10).join(f'- `{e["screen"]}`: {e["trigger"]}' for e in ENTRIES)}

## Not decided here

Clinical thresholds (BP crisis 180/120, low glucose 70 mg/dL, red-zone symptom rules, PHQ-2/GAD-2 scoring, chemo fever 100.4°F) follow published guidance but need sign-off from Tether’s clinical lead. Program names other than BreatheFree, ClearAir, Heartwise and Steady are working names. Backend choice (develop-branch NestJS + Supabase vs Tether-Health-Backend gateway) is open; endpoints in the spec follow the develop branch.
"""

async def shoot(describe):
    from playwright.async_api import async_playwright
    gal = B.build_gallery()
    open('/tmp/tg/gallery.html', 'w').write(gal)
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page(viewport={'width': 1800, 'height': 1000}, device_scale_factor=1.5)
        await pg.goto('file:///tmp/tg/gallery.html'); await pg.wait_for_timeout(400)
        cells = await pg.query_selector_all('.cell')
        for c in cells:
            sid = await c.get_attribute('data-id')
            d = os.path.join(OUT, 'screens', 'png', SCREENS[sid]['flow']); os.makedirs(d, exist_ok=True)
            await c.screenshot(path=os.path.join(d, f'{sid}.png'))
        # Android variants of the sign-in screens (Apple button hidden)
        await pg.evaluate("document.body.dataset.platform='android'")
        for sid in ('auth_signin', 'ob_account', 'auth_signin_error'):
            c = await pg.query_selector(f'.cell[data-id="{sid}"]')
            await c.screenshot(path=os.path.join(OUT, 'screens', 'png', 'auth', f'android_{sid}.png'))
        await pg.evaluate("document.body.dataset.platform='ios'")
        # contact sheets
        pg2 = await b.new_page(viewport={'width': 2000, 'height': 1000}, device_scale_factor=1)
        for fid, f in FLOWS.items():
            imgs = ''.join(f'<figure><img src="file://{OUT}/screens/png/{fid}/{sid}.png"><figcaption><b>{SCREENS[sid]["name"]}</b><span>{SCREENS[sid]["route"]}</span></figcaption></figure>' for sid in f['screens'])
            html = f'<html><head><meta charset="utf-8"><style>body{{margin:0;padding:28px;background:#F4F1E8;font-family:Helvetica,Arial,sans-serif;color:#123C37}}h1{{margin:0 0 4px}}p{{margin:0 0 20px;color:#5A726C}}main{{display:grid;grid-template-columns:repeat(6,1fr);gap:22px;align-items:start}}figure{{margin:0}}img{{width:100%;border-radius:22px;box-shadow:0 10px 24px -12px rgba(18,60,55,.4)}}figcaption{{font-size:13px;margin-top:6px}}figcaption span{{display:block;color:#5A726C;font-size:11px}}</style></head><body><h1>{f["title"]}</h1><p>{f["desc"]}</p><main>{imgs}</main></body></html>'
            open('/tmp/tg/_cs.html', 'w').write(html)
            await pg2.goto('file:///tmp/tg/_cs.html'); await pg2.wait_for_timeout(500)
            os.makedirs(os.path.join(OUT, 'screens', 'sheets'), exist_ok=True)
            await pg2.screenshot(path=os.path.join(OUT, 'screens', 'sheets', f'{fid}.png'), full_page=True)
        # flow boards
        pg3 = await b.new_page(viewport={'width': 1600, 'height': 900}, device_scale_factor=1)
        for fid in FLOWS:
            open(f'/tmp/tg/flow_{fid}.html', 'w').write(B.build_flowboard(fid))
            await pg3.goto(f'file:///tmp/tg/flow_{fid}.html'); await pg3.wait_for_timeout(500)
            dims = await pg3.evaluate('[document.querySelector(".wrap").scrollWidth, document.querySelector(".wrap").scrollHeight]')
            await pg3.set_viewport_size({'width': max(1200, dims[0] + 40), 'height': min(4000, dims[1] + 40)})
            await pg3.goto(f'file:///tmp/tg/flow_{fid}.html'); await pg3.wait_for_timeout(500)
            os.makedirs(os.path.join(OUT, 'flows', 'png'), exist_ok=True)
            await pg3.screenshot(path=os.path.join(OUT, 'flows', 'png', f'{fid}.png'), full_page=True)
        await b.close()

def main():
    errs, warns, edges = validate()
    if errs:
        print('\n'.join(errs)); sys.exit(1)
    describe = B.describe
    for sub in ('spec', 'design', 'prototype'):
        shutil.rmtree(os.path.join(OUT, sub), ignore_errors=True)
    for f in os.listdir(os.path.join(OUT, 'flows')) if os.path.isdir(os.path.join(OUT, 'flows')) else []:
        if f.endswith('.md'): os.remove(os.path.join(OUT, 'flows', f))
    # design
    wj('design/tokens.json', tokens())
    wj('design/components.json', {k: {'widget': v[0], 'props': v[1], 'behavior': v[2]} for k, v in COMPONENTS.items()})
    # spec
    wj('spec/programs.json', [{'id': k, 'name': PROGRAMS[k][0], 'area': PROGRAMS[k][1], 'archetype': PROGRAMS[k][2], 'color': PROGRAMS[k][3], 'status': PROGRAMS[k][5], 'tagline': PROGRAMS[k][6],
                               'screens': [s for s, v in SCREENS.items() if v['program'] == k]} for k in ORDER])
    wj('spec/flows.json', [{'id': fid, 'title': f['title'], 'description': f['desc'], 'program': f['program'], 'screens': f['screens']} for fid, f in FLOWS.items()])
    wj('spec/app.json', {'entries': ENTRIES, 'tabs': {t: f'/{t}' for t in TABS}, 'phases': PHASES,
                         'routes': {sid: {'route': s['route'], 'kind': s['kind'], 'flow': s['flow'], 'variantOf': s['variantOf'], 'state': s['state']} for sid, s in SCREENS.items()},
                         'action_types': {'push': 'navigate forward', 'replace': 'replace current screen', 'tab': 'switch tab (clears stack)', 'reset': 'leave flow, clear stack, end onboarding',
                                          'back': 'pop', 'close': 'dismiss sheet/modal', 'sheet': 'open bottom sheet', 'call': 'phone call', 'sms': 'open Messages', 'external': 'open URL',
                                          'os_settings': 'open OS settings', 'toast': 'snackbar, optional then', 'submit': 'API call (api) then action', 'branch': 'outcome decided by logic or a visible choice (on)'},
                         'context': {'onboarding': 'If TFlow.onboarding is true, actions with context.onboarding go there instead of `to`.'}})
    allscreens = {}
    for sid, s in SCREENS.items():
        d = dict(s); d['actions'] = [{'element': l, 'path': p, 'action': a, 'summary': describe(a)} for l, p, a in actions_of(s)]
        allscreens[sid] = d
        wj(f'spec/screens/{sid}.json', d)
    wj('spec/screens.json', allscreens)
    rows = []
    for sid, s in SCREENS.items():
        for l, p, a in actions_of(s):
            rows.append({'screen': sid, 'screen_name': s['name'], 'element': l, 'path': p, 'type': a['type'] if a else 'disabled', 'targets': targets(a), 'summary': describe(a)})
    wj('spec/actions.json', rows)
    from rules import RULES as _R, SCENARIOS as _S
    wj('spec/rules.json', _R)
    wj('spec/scenarios.json', _S)
    wj('spec/develop_mapping.json', mapping.DEVELOP_MAP)
    with open(os.path.join(OUT, 'spec', 'actions.csv'), 'w', newline='') as fh:
        wr = csv.writer(fh); wr.writerow(['screen', 'screen_name', 'element', 'type', 'targets', 'summary'])
        for r in rows: wr.writerow([r['screen'], r['screen_name'], r['element'], r['type'], ' '.join(r['targets']), r['summary']])
    w('spec/validation.md', f'# Validation\n\n- Screens: {len(SCREENS)}\n- Actions (edges): {len(edges)}\n- Errors (loose ends): **{len(errs)}**\n\nChecks: every interactive element has an action; every target exists; every screen can be reached from an entry point; every screen has a way out; routes are unique; branches have ≥2 outcomes.\n\n## Notes\n\n' + '\n'.join(f'- {x}' for x in warns) + '\n')
    # flows markdown
    for fid in FLOWS: w(f'flows/{fid}.md', flow_markdown(fid, describe))
    w('flows/README.md', '# Flows\n\n' + '\n'.join(f'- [{f["title"]}]({fid}.md): {len(f["screens"])} screens' for fid, f in FLOWS.items()) + '\n')
    # prototype
    import proto_v2
    from rules import RULES, SCENARIOS
    w('prototype/index.html', proto_v2.build_prototype(B.meta(), sim.expectations(), SCENARIOS, RULES))
    # flutter
    G.generate(os.path.join(OUT, 'flutter'), describe, os.path.join(HERE, 'dart_static'))
    sim.dart_tests(os.path.join(OUT, 'flutter'))
    # generator copy. Skipped when running in place (OUT/generator is this
    # directory): removing it first would delete the generator itself.
    gdir = os.path.join(OUT, 'generator')
    if not (os.path.isdir(gdir) and os.path.samefile(gdir, HERE)):
        shutil.rmtree(gdir, ignore_errors=True)
        shutil.copytree(HERE, gdir, ignore=shutil.ignore_patterns('__pycache__', 'run_*.py', 'shots.py', '*.pyc', 'proto_check*.json'))
    sp = os.path.join(OUT, 'validation', 'summary.json')
    w('README.md', mapping.readme(json.load(open(sp)) if os.path.exists(sp) else {}, edges))
    if '--images' in sys.argv:
        os.makedirs('/tmp/tg', exist_ok=True)
        asyncio.run(shoot(describe))
    print(f'built {len(SCREENS)} screens, {len(edges)} actions, {len(FLOWS)} flows → {OUT}')

if __name__ == '__main__':
    main()
