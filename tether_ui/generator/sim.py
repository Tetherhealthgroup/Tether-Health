"""Simulation & validation: expected effects for every action (button flow
sweep) and end-to-end scenarios for every program. Generates Flutter tests
and data for the prototype simulator."""
import os, json
from dsl import *
from rules import RULES, SCENARIOS
from gen_dart import dstr, camel, pascal

HOST = '/__host'

def route_of(sid): return SCREENS[sid]['route']

def has_context(a):
    if not a: return False
    if a.get('context'): return True
    if a['type'] == 'branch': return any(has_context(c['action']) for c in a['cases'])
    return has_context(a.get('then'))

def first_branch(a):
    if not a: return None
    if a['type'] == 'branch': return a
    return first_branch(a.get('then'))

def resolve(a, force, onboarding):
    t = a['type']
    if t in ('push', 'replace', 'tab', 'sheet', 'reset', 'popto'):
        to = a['context']['onboarding'] if (a.get('context') and onboarding) else a['to']
        return {'kind': 'route', 'route': route_of(to), 'screen': to}
    if t in ('back', 'close'): return {'kind': 'pop'}
    if t == 'toast': return resolve(a['then'], force, onboarding) if a.get('then') else {'kind': 'toast', 'text': a['value']}
    if t == 'submit': return resolve(a['then'], force, onboarding)
    if t == 'branch':
        case = next(c for c in a['cases'] if c['label'] == force)
        return resolve(case['action'], None, onboarding)
    if t in ('call', 'sms', 'external'): return {'kind': 'platform', 'value': f"{t}:{a['value']}"}
    if t == 'os_settings': return {'kind': 'platform', 'value': 'os_settings:'}
    raise ValueError(t)

def expectations():
    out = []
    for sid, s in SCREENS.items():
        for label, path, a in actions_of(s):
            if not a: continue
            node = None
            for part in ('body', 'footer'):
                for n, p in walk(s[part], part):
                    if p == path: node = n
            platform = 'ios' if node and node.get('t') == 'authbtn' and 'android' not in node.get('platforms', []) else 'android'
            br = first_branch(a)
            forces = [c['label'] for c in br['cases']] if br else [None]
            for f in forces:
                onbs = [False, True] if has_context(a) else [False]
                for onb in onbs:
                    eff = resolve(a, f, onb)
                    if eff['kind'] == 'route' and eff['screen'] == sid and a['type'] in ('replace',):
                        pass
                    out.append({'screen': sid, 'element': label, 'path': path, 'force': f, 'onboarding': onb, 'platform': platform, 'expect': eff})
    return out

def dart_tests(out_dir):
    exps = expectations()
    rows = []
    for x in exps:
        e = x['expect']
        exp = {'route': f"('route', {dstr(e.get('route'))})", 'pop': "('pop', null)", 'toast': f"('toast', {dstr(e.get('text'))})", 'platform': f"('platform', {dstr(e.get('value'))})"}[e['kind']]
        rows.append(f"  ({dstr(x['screen'])}, Routes.{camel(x['screen'])}, {dstr(x['path'])}, {dstr(x['element'])}, {dstr(x['force'])}, {'true' if x['onboarding'] else 'false'}, {'true' if x['platform'] == 'ios' else 'false'}, {exp}),")
    sweep = f"""// GENERATED — button-flow sweep: taps every interactive element on every
// screen (every branch outcome, with and without the onboarding context)
// and checks it lands exactly where spec/actions.json says.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

class _Obs extends NavigatorObserver {{
  final List<String?> stack = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => stack.add(route.settings.name);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {{ if (stack.isNotEmpty) stack.removeLast(); }}
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {{ stack.remove(route.settings.name); }}
  @override
  void didReplace({{Route<dynamic>? newRoute, Route<dynamic>? oldRoute}}) {{
    final i = stack.lastIndexOf(oldRoute?.settings.name);
    if (i >= 0) {{ stack[i] = newRoute?.settings.name; }} else {{ stack.add(newRoute?.settings.name); }}
  }}
  String? get top => stack.isEmpty ? null : stack.last;
}}

const _cases = <(String, String, String, String, String?, bool, bool, (String, String?))>[
{chr(10).join(rows)}
];

void main() {{
  for (final c in _cases) {{
    final name = 'sweep ${{c.$1}} · ${{c.$4}}${{c.$5 != null ? ' → ${{c.$5}}' : ''}}${{c.$6 ? ' (onboarding)' : ''}}';
    testWidgets(name, (tester) async {{
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      TSession.clear();
      TFlow.onboarding = c.$6;
      TSim.force = c.$5;
      PreviewPlatform.last = null;
      if (c.$7) debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {{
        final obs = _Obs();
        await tester.pumpWidget(MaterialApp(
          theme: tetherTheme(),
          navigatorObservers: [obs],
          onGenerateRoute: (s) => s.name == '{HOST}' ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: '{HOST}')),
            AppRouter.onGenerateRoute(RouteSettings(name: c.$2))!,
          ],
        ));
        await tester.pump(const Duration(milliseconds: 400));
        TFlow.onboarding = c.$6; // screens such as the setup hub set this while building
        final finder = find.byKey(ValueKey('a:${{c.$3}}'));
        expect(finder, findsOneWidget, reason: 'element ${{c.$3}} on ${{c.$1}}');
        await tester.ensureVisible(finder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(finder, warnIfMissed: false);
        for (var i = 0; i < 6; i++) {{
          await tester.pump(const Duration(milliseconds: 120));
        }}
        final e = c.$8;
        switch (e.$1) {{
          case 'route':
            expect(obs.top, e.$2, reason: 'expected route ${{e.$2}}');
          case 'pop':
            expect(obs.top, '{HOST}');
          case 'toast':
            expect(find.text(e.$2!), findsWidgets);
          case 'platform':
            expect(PreviewPlatform.last, e.$2);
        }}
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      }} finally {{
        debugDefaultTargetPlatformOverride = null;
        TSim.reset();
        TFlow.onboarding = false;
      }}
    }});
  }}
}}
"""
    open(os.path.join(out_dir, 'test', 'action_sweep_test.dart'), 'w').write(sweep)

    # scenarios
    cases = []
    for scn in SCENARIOS:
        lines = []
        for st in scn['steps']:
            if st[0] == 'tap': lines.append(f"        await _tap(tester, {dstr(st[1])});")
            elif st[0] == 'enter': lines.append(f"        await _enter(tester, {dstr(st[1])}, {dstr(st[2])});")
            elif st[0] == 'choose': lines.append(f"        TSim.queue.add({dstr(st[1])});")
            elif st[0] == 'expect': lines.append(f"        expect(find.byType({pascal(st[1])}Screen), findsOneWidget, reason: 'expected {st[1]}');")
        ios = any(st[0] == 'tap' and 'Apple' in st[1] for st in scn['steps']) or scn.get('platform') == 'ios'
        cases.append(f"""  testWidgets({dstr('scenario ' + scn['id'] + ' · ' + scn['title'])}, (tester) async {{
    await _start(tester, Routes.{camel(scn['start'])}, ios: {'true' if ios else 'false'});
    try {{
{chr(10).join(lines)}
        expect(find.byType({pascal(scn['expect'])}Screen), findsOneWidget, reason: 'expected {scn['expect']}');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    }} finally {{
      debugDefaultTargetPlatformOverride = null;
    }}
  }});""")
    used = sorted({x for scn in SCENARIOS for x in [scn['expect']] + [st[1] for st in scn['steps'] if st[0] == 'expect']})
    imports = '\n'.join(f"import 'package:tether_ui/screens/{SCREENS[x]['flow']}/{x}_screen.dart';" for x in used)
    code = f"""// GENERATED from generator/rules.py → SCENARIOS: end-to-end setups and
// functions for every program, with simulated data entered into real
// fields. Decisions use the same rules as the app (lib/logic/rules.dart).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';
{imports}

Future<void> _settle(WidgetTester tester) async {{
  for (var i = 0; i < 8; i++) {{
    await tester.pump(const Duration(milliseconds: 120));
  }}
}}

Future<void> _start(WidgetTester tester, String route, {{bool ios = false}}) async {{
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  TSession.clear();
  TFlow.onboarding = false;
  if (ios) debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  TNav.branchResolver = (context, question, outcomes) async => outcomes.first;
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    onGenerateRoute: (s) => s.name == '{HOST}' ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: '{HOST}')),
      AppRouter.onGenerateRoute(RouteSettings(name: route))!,
    ],
  ));
  await _settle(tester);
}}

Future<void> _tap(WidgetTester tester, String label) async {{
  final finder = find.text(label, skipOffstage: true);
  expect(finder, findsWidgets, reason: 'No visible "$label"');
  await tester.ensureVisible(finder.last);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder.last, warnIfMissed: false);
  await _settle(tester);
}}

Future<void> _enter(WidgetTester tester, String key, String value) async {{
  final finder = find.byKey(ValueKey('field:$key'));
  expect(finder, findsOneWidget, reason: 'No field $key');
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await _settle(tester);
}}

void main() {{
{chr(10).join(cases)}
}}
"""
    open(os.path.join(out_dir, 'test', 'scenarios_test.dart'), 'w').write(code)
    return len(exps), len(SCENARIOS)
