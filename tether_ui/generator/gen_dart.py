import os, shutil, json
from dsl import *
from rules import RULES

def dstr(s):
    if s is None: return 'null'
    s = str(s).replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n')
    return f"'{s}'"

def dcolor(c):
    if c in PROGRAMS: return f"TColors.program('{c}')"
    return {'coral': 'TColors.coral', 'teal': 'TColors.teal'}.get(c, 'TColors.teal')

def rconst(sid): return f'Routes.{camel(sid)}'

def act(a):
    """Dart expression performing action `a` (context in scope)."""
    t = a['type']
    if t == 'popto': return f"TNav.popTo(context, {rconst(a['to'])})"
    if t in ('push', 'replace', 'tab', 'sheet', 'reset'):
        target = rconst(a['to'])
        if a.get('context'):
            target = f"(TFlow.onboarding ? {rconst(a['context']['onboarding'])} : {target})"
        fn = {'push': 'push', 'replace': 'replace', 'tab': 'tab', 'sheet': 'sheet', 'reset': 'reset'}[t]
        return f'TNav.{fn}(context, {target})'
    if t == 'back': return 'TNav.back(context)'
    if t == 'close': return 'TNav.close(context)'
    if t == 'call': return f"TNav.call(context, {dstr(a['value'])}, label: {dstr(a.get('label'))})"
    if t == 'sms': return f"TNav.sms(context, {dstr(a['value'])})"
    if t == 'external': return f"TNav.external(context, {dstr(a['value'])})"
    if t == 'os_settings': return 'TNav.osSettings(context)'
    if t == 'toast':
        then = f", then: () => {act(a['then'])}" if a.get('then') else ''
        return f"TNav.toast(context, {dstr(a['value'])}{then})"
    if t == 'submit':
        then = f", then: () => {act(a['then'])}" if a.get('then') else ''
        return f"TNav.submit(context, {dstr(a['api'])}, screenId: {dstr(CUR['sid'])}{then}{safety_routes(a.get('then'))})"
    if t == 'branch':
        safety_cases(a)  # raises if a safety outcome has no case
        cases = ', '.join(f"{dstr(c['label'])}: () => {act(c['action'])}" for c in a['cases'])
        extra = ''
        if a.get('decide'): extra += f", decide: {dstr(a['decide'])}"
        if a.get('provider'): extra += f", provider: {dstr(a['provider'])}"
        return f"TNav.branch(context, {dstr(a['question'])}, <String, VoidCallback>{{{cases}}}{extra})"
    raise ValueError(t)

def cb(a): return f'() => {act(a)}' if a else 'null'

def safety_labels(rule_id):
    """Outcome labels that rules.py marks as safety for `rule_id` (none if unmarked)."""
    rule = RULES.get(rule_id) or {}
    ids = rule.get('safety', [])
    unknown = [i for i in ids if i not in rule.get('outcomes', {})]
    if unknown: raise ValueError(f'{rule_id}: safety ids {unknown} are not outcomes')
    return [rule['outcomes'][i] for i in ids]

def safety_cases(a):
    """The cases of branch `a` for its rule's safety outcomes, in safety order.
    Raises when the rule marks a safety outcome that has no case with exactly
    that label: a safety outcome must never be dropped silently."""
    if not a.get('decide') or a['decide'].startswith('choice:'): return []
    by_label = {c['label']: c for c in a['cases']}
    labels = safety_labels(a['decide'])
    missing = [l for l in labels if l not in by_label]
    if missing:
        raise ValueError(f"{CUR['sid']}: branch {a['question']!r} is decided by {a['decide']}, whose safety outcomes {missing} have no case with that exact label")
    return [by_label[l] for l in labels]

def safety_routes(then):
    """`, safety: TSafetyRoutes(...)` for a submit whose `then` (through toasts)
    is a branch decided by an on-device rule with safety outcomes; '' when the
    branch's rule has no safety outcome (or `then` has no rule-decided branch)."""
    a = then
    while a and a['type'] == 'toast': a = a.get('then')
    if not a or a['type'] != 'branch': return ''
    cases = safety_cases(a)
    if not cases: return ''
    routes = ', '.join(f"{dstr(c['label'])}: () => {act(c['action'])}" for c in cases)
    return f", safety: TSafetyRoutes({dstr(a['decide'])}, <String, VoidCallback>{{{routes}}})"

def args(**kw):
    parts = []
    for k, v in kw.items():
        if v is None: continue
        parts.append(f'{k}: {v}' if k != '_' else v)
    return ', '.join(parts)

def lst(items): return '[' + ', '.join(items) + ']'

CUR = {'sid': ''}

def K(path): return f"const ValueKey('a:{path}')"

def FK(n): return dstr(f"{CUR['sid']}.{n['key']}") if n.get('key') else None

def node(n, top=False, path=''):
    t = n['t']
    S_ = dstr
    if t == 'eyebrow': return f"TEyebrow({S_(n['text'])})"
    if t == 'title':
        return f"TTitle({args(_=S_(n['text']), size='TTitleSize.' + n.get('size', 'm') if n.get('size', 'm') != 'm' else None, center='true' if n.get('align') == 'center' else None)})"
    if t == 'text':
        tone = n.get('tone', 'body')
        return f"TBody({args(_=S_(n['text']), tone='TTextTone.' + tone if tone != 'body' else None, center='true' if n.get('align') == 'center' else None)})"
    if t == 'steps': return f"TSteps(n: {n['n']}, total: {n['total']})"
    if t == 'chips':
        dots = n.get('dots')
        d = '{' + ', '.join(f"{S_(k)}: {dcolor(v)}" for k, v in dots.items()) + '}' if dots else None
        return f"TChips({args(fieldKey=FK(n), options=lst([S_(o) for o in n['options']]), selected=lst([S_(o) for o in n['selected']]) if n['selected'] else None, multi='false' if not n.get('multi') else None, dots=d, label=S_(n['label']) if n.get('label') else None)})"
    if t == 'segmented':
        return f"TSegmented({args(fieldKey=FK(n), options=lst([S_(o) for o in n['options']]), selected=S_(n['selected']), label=S_(n['label']) if n.get('label') else None)})"
    if t == 'radio':
        items = [f"TRadioItem({args(_=S_(i['label']), sub=S_(i['sub']) if i.get('sub') else None, badge=S_(i['badge']) if i.get('badge') else None)})" for i in n['items']]
        return f"TRadioList({args(fieldKey=FK(n), items=lst(items), selected=str(n['selected']), label=S_(n['label']) if n.get('label') else None)})"
    if t == 'checklist':
        items = [f"TCheckItem({args(_=S_(i['label']), sub=S_(i['sub']) if i.get('sub') else None, done='true' if i.get('done') else None)})" for i in n['items']]
        return f"TChecklist({args(fieldKey=FK(n), items=lst(items), label=S_(n['label']) if n.get('label') else None)})"
    if t == 'toggle': return f"TToggleRow({args(fieldKey=FK(n), label=S_(n['label']), sub=S_(n['sub']) if n.get('sub') else None, value='true' if n.get('on') else None)})"
    if t == 'field':
        kind = n.get('kind', 'text')
        return f"TField({args(fieldKey=FK(n), label=S_(n['label']), value=S_(n.get('value')) if n.get('value') else None, unit=S_(n.get('unit')) if n.get('unit') else None, hint=S_(n.get('hint')) if n.get('hint') else None, error=S_(n.get('error')) if n.get('error') else None, placeholder=S_(n.get('placeholder')) if n.get('placeholder') else None, kind='TFieldKind.' + kind if kind != 'text' else None)})"
    if t == 'fieldrow': return f"TFieldRow(children: {lst([node(x, path=f'{path}.fields[{i}]') for i, x in enumerate(n['fields'])])})"
    if t == 'slider':
        return f"TSliderField({args(fieldKey=FK(n), label=S_(n['label']), value=str(float(n['value'])), min=str(float(n['min'])), max=str(float(n['max'])), minLabel=S_(n['minLabel']), maxLabel=S_(n['maxLabel']), color=dcolor(n.get('color', 'coral')), suffix=S_(n['suffix']) if n.get('suffix') else None)})"
    if t == 'banner':
        return f"TBanner({args(kind='TBannerKind.' + n['kind'], text=S_(n['text']), actionLabel=S_(n['actionLabel']) if n.get('actionLabel') else None, onAction=cb(n['action']) if n.get('action') else None, actionKey=K(path) if n.get('action') else None)})"
    if t == 'card':
        v = n.get('variant', 'plain')
        return f"TCard({args(key=K(path) if n.get('action') else None, variant='TCardVariant.' + v if v != 'plain' else None, tag=S_(n['tag']) if n.get('tag') else None, tagExtra=S_(n['tagExtra']) if n.get('tagExtra') else None, eyebrow=S_(n['eyebrow']) if n.get('eyebrow') else None, title=S_(n['title']) if n.get('title') else None, text=S_(n['text']) if n.get('text') else None, accent=S_(n['accent']) if n.get('accent') else None, onTap=cb(n['action']) if n.get('action') else None, cta=node(n['cta'], path=path + '.cta[0]') if n.get('cta') else None, children=lst([node(c, path=f'{path}.children[{i}]') for i, c in enumerate(n['children'])]) if n.get('children') else None)})"
    if t == 'kv': return f"TKeyValue(rows: {lst([f'({S_(k)}, {S_(v)})' for k, v in n['rows']])})"
    if t == 'list':
        rows = []
        for j, r in enumerate(n['rows']):
            L = r.get('lead') or {}
            lead = None
            if 'program' in L: lead = f"TLead.program({S_(L['program'])})"
            elif 'avatar' in L: lead = f"TLead.avatar({S_(L['avatar'])})"
            elif 'icon' in L: lead = f"TLead.icon({S_(L['icon'])})"
            rows.append(f"TListRow({args(key=K(f'{path}.rows[{j}]') if r.get('action') else None, label=S_(r['label']), sub=S_(r['sub']) if r.get('sub') else None, value=S_(r['value']) if r.get('value') else None, lead=lead, pill=S_(r['pill']) if r.get('pill') else None, danger='true' if r.get('danger') else None, onTap=cb(r['action']) if r.get('action') else None)})")
        return f"TListGroup({args(title=S_(n['title']) if n.get('title') else None, flat='true' if n.get('flat') else None, rows=lst(rows))})"
    if t == 'tiles':
        tiles = [f"TTile({args(key=K(f'{path}.items[{j}]') if i.get('action') else None, label=S_(i['label']), sub=S_(i['sub']) if i.get('sub') else None, program=S_(i['program']) if i.get('program') else None, glyph=S_(i['glyph']) if i.get('glyph') else None, selected='true' if i.get('selected') else None, onTap=cb(i['action']) if i.get('action') else None)})" for j, i in enumerate(n['items'])]
        return f"TTileGrid({args(fieldKey=FK(n), columns=str(n.get('cols', 2)) if n.get('cols', 2) != 2 else None, tiles=lst(tiles))})"
    if t == 'stats':
        st_ = [f"TStat({args(label=S_(i['label']), value=S_(i['value']), sub=S_(i['sub']) if i.get('sub') else None, program=S_(i['program']) if i.get('program') else None)})" for i in n['items']]
        return f"TStatGrid({args(columns=str(n.get('cols', 2)) if n.get('cols', 2) != 2 else None, stats=lst(st_))})"
    if t == 'chart':
        common = dict(key=K(path) if n.get('action') else None, title=S_(n['title']) if n.get('title') else None, unit=S_(n['unit']) if n.get('unit') else None, caption=S_(n['caption']) if n.get('caption') else None, tag=S_(n['tag']) if n.get('tag') else None, onTap=cb(n['action']) if n.get('action') else None)
        vals = lst([str(float(v)) for v in n['values']])
        if n['kind'] == 'bars':
            return f"TBarChart({args(values=vals, color=dcolor(n['color']), missing=lst([str(m) for m in n['missing']]) if n.get('missing') else None, target=str(float(n['target'])) if n.get('target') else None, labels=lst([S_(l) for l in n['labels']]) if n.get('labels') else None, **common)})"
        return f"TLineChart({args(values=vals, color=dcolor(n['color']), band=lst([str(float(b)) for b in n['band']]) if n.get('band') else None, **common)})"
    if t == 'zone': return f"TZoneSelector({args(selected=S_(n['selected']), rule=S_(n['rule']) if n.get('rule') else None)})"
    if t == 'ring': return f"TBreathRing({args(value=S_(n['value']), label=S_(n['label']) if n.get('label') != 'SECONDS' else None, palette='TRingPalette.indigo' if n.get('palette') == 'indigo' else None)})"
    if t == 'big': return f"TBigNumber({args(value=S_(n['value']), unit=S_(n['unit']) if n.get('unit') else None, caption=S_(n['caption']) if n.get('caption') else None, center='true' if top else None)})"
    if t == 'button':
        v = {'ghostdark': 'ghostDark'}.get(n.get('variant', 'primary'), n.get('variant', 'primary'))
        on = 'null' if n.get('state') == 'disabled' or not n.get('action') else cb(n['action'])
        return f"TButton({args(key=K(path) if on != 'null' else None, label=S_(n['label']), onPressed=on, variant='TButtonVariant.' + v if v != 'primary' else None, small='true' if n.get('small') else None, arrow='true' if n.get('arrow') else None)})"
    if t == 'buttons': return f"TButtonRow(children: {lst([node(b, path=f'{path}.items[{i}]') for i, b in enumerate(n['items'])])})"
    if t == 'authbuttons':
        return f"TAuthButtons(children: {lst([node(b, path=f'{path}.items[{i}]') for i, b in enumerate(n['items'])])})"
    if t == 'authbtn':
        return f"TAuthButton({args(key=K(path), provider=S_(n['provider']), label=S_(n['label']), onPressed=cb(n['action']), platforms=lst([S_(p) for p in n['platforms']]))})"
    if t == 'link': return f"TLink({args(key=K(path), label=S_(n['label']), onTap=cb(n['action']), alignLeft='true' if n.get('align') == 'left' else None)})"
    if t == 'quote': return f"TQuote({args(_=S_(n['text']), caption=S_(n['caption']) if n.get('caption') else None)})"
    if t == 'illus': return f"TIllustration({args(glyph=S_(n['glyph']), tone='TTone.' + n.get('tone', 'mint') if n.get('tone', 'mint') != 'mint' else None)})"
    if t == 'emergency': return f"TEmergencyCard(text: {S_(n['text'])}, actions: {lst([node(b, path=f'{path}.actions[{i}]') for i, b in enumerate(n['actions'])])})"
    if t == 'skeleton': return f"TSkeleton(lines: {n['lines']})"
    if t == 'spacer': return f"SizedBox(height: {float(n['h'])})"
    if t == 'progtag': return f"TProgramTag({args(program=S_(n['program']), extra=S_(n['extra']) if n.get('extra') else None)})"
    if t == 'calendar': return f"TCalendar({args(month=S_(n['month']), selected=str(n['selected']), window=lst([str(w) for w in n['window']]), today=str(n['today']) if n.get('today') else None)})"
    if t == 'timer': return f"TTimer(value: {S_(n['value'])}, label: {S_(n['label'])})"
    if t == 'nativeslot': return f"TNativeSlot({args(id=S_(n['id']), label=S_(n['label']), caption=S_(n['caption']) if n.get('caption') else None, platform=S_(n['platform']) if n.get('platform', 'ios') != 'ios' else None, height=str(float(n['height'])) if n.get('height', 120) != 120 else None)})"
    raise ValueError(t)

def ind(code, level=3):
    return code

def screen_file(s, describe):
    cls = pascal(s['id']) + 'Screen'
    CUR['sid'] = s['id']
    kids = ',\n        '.join(node(n, top=True, path=f'body[{i}]') for i, n in enumerate(s['body']))
    foot = ',\n        '.join(node(n, path=f'footer[{i}]') for i, n in enumerate(s['footer']))
    acts = '\n'.join(f'///   • {l} → {describe(a)}' for l, p, a in actions_of(s))
    doc = f"""/// {s['name']}  ·  route `{s['route']}`  ·  flow `{s['flow']}`  ·  kind `{s['kind']}`
/// {('State: ' + s['state'] + ' of ' + s['variantOf']) if s['variantOf'] else 'Default state'}{(' · program ' + s['program']) if s['program'] else ''} · phase {s['phase']}
/// {s['desc']}
///
/// Actions (generated from spec/screens/{s['id']}.json):
{acts}
/// API: {', '.join(s['api']) or '—'}"""
    if s['kind'] == 'sheet':
        body = f"""    return TSheet(
      children: [
        {kids},
      ],
      footer: [
        {foot}{',' if foot else ''}
      ],
    );"""
    else:
        h = s.get('header')
        hdr = ''
        if h:
            left = {'back': 'THeaderLeft.back', 'close': 'THeaderLeft.close', 'none': 'THeaderLeft.none', 'logo': 'THeaderLeft.logo'}[h.get('left', 'back')]
            hdr = f"      header: THeader({args(title=dstr(h.get('title') or ''), left=left if left != 'THeaderLeft.back' else None, pill=dstr(h['pill']) if h.get('pill') else None, avatar=dstr(h['avatar']) if h.get('avatar') else None, onAvatar=cb(h['avatarAction']) if h.get('avatarAction') else None)}),\n"
        bg = ''
        if s.get('bg') == 'indigo': bg = '      background: TBackground.indigo,\n'
        elif s['dark']: bg = '      background: TBackground.dark,\n'
        tabl = f"      tab: '{s['tab']}',\n" if s.get('tab') else ''
        footer = f"      footer: [\n        {foot},\n      ],\n" if foot else ''
        body = f"""    return TScreen(
{hdr}{bg}{tabl}      children: [
        {kids},
      ],
{footer}    );"""
    routes_imp = "import '../../router/routes.dart';\n" if 'Routes.' in body else ''
    hook = "    TFlow.onboarding = true; // program setups now return here\n" if s['id'] == 'ob_setup' else ''
    return f"""// GENERATED from spec/screens/{s['id']}.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

{routes_imp}import '../../ui/ui.dart';

{doc}
class {cls} extends StatelessWidget {{
  const {cls}({{super.key}});

  @override
  Widget build(BuildContext context) {{
{hook}{body}
  }}
}}
"""

def generate(out_dir, describe, static_dir):
    lib = os.path.join(out_dir, 'lib')
    if os.path.exists(out_dir): shutil.rmtree(out_dir)
    shutil.copytree(static_dir, out_dir)
    # barrel
    open(os.path.join(lib, 'ui', 'ui.dart'), 'w', newline='\n').write("export '../logic/rules.dart';\nexport 'components.dart';\nexport 'data.dart';\nexport 'nav.dart';\nexport 'tokens.dart';\n")
    # routes
    lines = ['// GENERATED — route names for every screen and state in spec/screens.json.', 'abstract final class Routes {']
    for sid, s in SCREENS.items():
        lines.append(f"  /// {s['name']}{' (' + s['state'] + ')' if s['variantOf'] else ''}")
        lines.append(f"  static const {camel(sid)} = {dstr(s['route'])};")
    lines.append('}')
    os.makedirs(os.path.join(lib, 'router'), exist_ok=True)
    open(os.path.join(lib, 'router', 'routes.dart'), 'w', newline='\n').write('\n'.join(lines) + '\n')
    # screens
    imports = []
    for sid, s in SCREENS.items():
        d = os.path.join(lib, 'screens', s['flow'])
        os.makedirs(d, exist_ok=True)
        open(os.path.join(d, f'{sid}_screen.dart'), 'w', newline='\n').write(screen_file(s, describe))
        imports.append(f"import '../screens/{s['flow']}/{sid}_screen.dart';")
    builders = '\n'.join(f"    Routes.{camel(sid)}: (_) => const {pascal(sid)}Screen()," for sid in SCREENS)
    sheets = ', '.join(f'Routes.{camel(sid)}' for sid, s in SCREENS.items() if s['kind'] == 'sheet')
    catalog = '\n'.join(f"    ({dstr(sid)}, {dstr(s['name'] + (' · ' + s['state'] if s['variantOf'] else ''))}, {dstr(FLOWS[s['flow']]['title'])}, Routes.{camel(sid)})," for sid, s in SCREENS.items())
    tabs = ', '.join(f"'{t}': Routes.{camel(t)}" for t in TABS)
    router = f"""// GENERATED — every screen in spec/screens.json, registered by route name.
import 'package:flutter/material.dart';

import 'routes.dart';
{chr(10).join(imports)}

abstract final class AppRouter {{
  static final Map<String, WidgetBuilder> screens = <String, WidgetBuilder>{{
{builders}
  }};

  /// Routes presented as modal bottom sheets.
  static const Set<String> sheets = {{{sheets}}};

  static const Map<String, String> tabRoutes = {{{tabs}}};

  /// (id, name, flow title, route) — drives the dev gallery and tests.
  static const List<(String, String, String, String)> catalog = [
{catalog}
  ];

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {{
    final builder = screens[settings.name];
    if (builder == null) return null;
    if (sheets.contains(settings.name)) {{
      return ModalBottomSheetRoute<void>(
        builder: builder,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        settings: settings,
      );
    }}
    return MaterialPageRoute<void>(builder: builder, settings: settings);
  }}
}}
"""
    open(os.path.join(lib, 'router', 'app_router.dart'), 'w', newline='\n').write(router)
    return len(SCREENS)


JOURNEYS = [
    ('first run: choose programs, set up BreatheFree, continue as guest', 'welcome',
     ['Get started', 'Continue with 2 programs', 'Continue', 'Agree and continue', 'Continue', 'BreatheFree', 'Next', 'Next', 'Save my reasons',
      'Continue with this path', 'Confirm this date', 'Review my plan', 'Start my plan', 'Continue', 'Not now', 'Continue on this phone only'], 'today'),
    ('craving rescue from Today', 'today', ['Rescue', 'A cigarette', 'I’m done', 'Back to Today'], 'today'),
    ('Heartwise: log two readings, see trends', 'hw_home', ['Log blood pressure', 'Next reading', 'Save readings', 'See trends'], 'hw_trends'),
    ('ClearAir: zone check routes by computed zone', 'ca_home', ['Check my zone', 'Save and see my steps'], 'ca_home'),
    ('delete account with receipt', 'account', ['Your data', 'Delete account and all data', 'Delete everything', 'Done'], 'welcome'),
    ('switch tabs from Today', 'today', ['Plans', 'Progress', 'Learn', 'Support', 'Today'], 'today'),
]

def journeys_test(out_dir):
    cases = []
    for name, start, taps, end in JOURNEYS:
        steps = '\n'.join(f"      await _tap(tester, {dstr(t)});" for t in taps)
        cases.append(f"""  testWidgets({dstr(name)}, (tester) async {{
    await _start(tester, Routes.{camel(start)});
{steps}
    expect(find.byType({pascal(end)}Screen), findsOneWidget);
    expect(tester.takeException(), isNull);
  }});""")
    imports = sorted({f"import 'package:tether_ui/screens/{SCREENS[e]['flow']}/{e}_screen.dart';" for _, _, _, e in JOURNEYS})
    code = f"""// GENERATED — end-to-end journeys that tap real buttons through the app.
// Branches pick their first outcome (TNav.branchResolver), so each journey
// follows the main path defined in spec/flows.json.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';
{chr(10).join(imports)}

Future<void> _settle(WidgetTester tester) async {{
  for (var i = 0; i < 8; i++) {{
    await tester.pump(const Duration(milliseconds: 120));
  }}
}}

Future<void> _start(WidgetTester tester, String route) async {{
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  TFlow.onboarding = false;
  TNav.branchResolver = (context, question, outcomes) async => outcomes.first;
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    onGenerateInitialRoutes: (_) => [AppRouter.onGenerateRoute(RouteSettings(name: route))!],
  ));
  await _settle(tester);
}}

Future<void> _tap(WidgetTester tester, String label) async {{
  final finder = find.text(label, skipOffstage: true);
  expect(finder, findsWidgets, reason: 'No visible "$label"');
  await tester.ensureVisible(finder.last);
  await tester.tap(finder.last);
  await _settle(tester);
}}

void main() {{
{chr(10).join(cases)}
}}
"""
    open(os.path.join(out_dir, 'test', 'journeys_test.dart'), 'w', newline='\n').write(code)


def _self_test():
    """python3 gen_dart.py: the safety checks raise on a missing safety case."""
    rule = {'outcomes': {'ok': 'Fine', 'bad': 'Danger'}, 'safety': ['bad']}
    RULES['selftest.rule'] = rule
    CUR['sid'] = 'selftest'
    try:
        good = {'type': 'branch', 'question': 'Q', 'decide': 'selftest.rule', 'cases': [{'label': 'Fine', 'action': {'type': 'back'}}, {'label': 'Danger', 'action': {'type': 'close'}}]}
        assert 'TSafetyRoutes' in safety_routes(good)
        bad = dict(good, cases=[{'label': 'Fine', 'action': {'type': 'back'}}, {'label': 'Danger zone', 'action': {'type': 'close'}}])
        for f in (safety_routes, act):
            try:
                f(bad)
            except ValueError as e:
                assert 'Danger' in str(e)
            else:
                raise AssertionError(f'{f.__name__} did not raise for a missing safety case')
        rule['safety'] = ['nope']
        try:
            safety_routes(good)
        except ValueError:
            pass
        else:
            raise AssertionError('an unknown safety id did not raise')
    finally:
        del RULES['selftest.rule']
    print('gen_dart self-test: ok')


if __name__ == '__main__':
    _self_test()
    import dsl
    dsl._self_test()
