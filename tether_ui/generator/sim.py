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

def resolve(a, force, onboarding, queue=None):
    """Effect of action `a` when its first branch takes `force` and a branch
    inside the chosen case takes `queue` (a nested branch is decided by the
    simulation queue, as TSim.queue / QUEUE do)."""
    t = a['type']
    if t in ('push', 'replace', 'tab', 'sheet', 'reset', 'popto'):
        to = a['context']['onboarding'] if (a.get('context') and onboarding) else a['to']
        return {'kind': 'route', 'route': route_of(to), 'screen': to}
    if t in ('back', 'close'): return {'kind': 'pop'}
    if t == 'toast': return resolve(a['then'], force, onboarding, queue) if a.get('then') else {'kind': 'toast', 'text': a['value']}
    if t == 'submit': return resolve(a['then'], force, onboarding, queue)
    if t == 'branch':
        case = next(c for c in a['cases'] if c['label'] == force)
        return resolve(case['action'], queue, onboarding)
    if t in ('call', 'sms', 'external'): return {'kind': 'platform', 'value': f"{t}:{a['value']}"}
    if t == 'os_settings': return {'kind': 'platform', 'value': 'os_settings:'}
    raise ValueError(t)

def submits_under(a, force):
    """True if action `a` reaches a submit when branches take `force` (or their first outcome)."""
    if not a: return False
    t = a['type']
    if t == 'submit': return True
    if t == 'toast': return submits_under(a.get('then'), force)
    if t == 'branch':
        case = next((c for c in a['cases'] if c['label'] == force), a['cases'][0])
        return submits_under(case['action'], force)
    return False

def placeholder_cases():
    """P-31 cases: every screen with text fields, tapped without typing.

    Each element whose action can reach a submit is tapped once per branch
    outcome that submits. Screens without a submit tap their forward footer
    buttons ("Next", "Continue"). Returns (screen, path, element, force,
    must submit, [(session key, placeholder)])."""
    out = []
    for sid, s in SCREENS.items():
        fields = [(f"{sid}.{n['key']}", n.get('placeholder')) for part in ('body', 'footer') for n, p in walk(s[part], part) if n['t'] == 'field']
        if not fields: continue
        acts = [(l, p, a) for l, p, a in actions_of(s) if a and not p.startswith(('tabbar', 'header'))]
        picked = []
        for l, p, a in acts:
            br = first_branch(a)
            forces = [c['label'] for c in br['cases']] if br else [None]
            for f in forces:
                if submits_under(a, f): picked.append((l, p, f, True))
        if not picked:
            picked = [(l, p, None, False) for l, p, a in acts if p.startswith('footer') and leaves(a) and a['type'] not in ('back', 'close')]
        if not picked:  # search fields: nothing to save, check the empty start only
            picked = [('opened, nothing tapped', '', None, False)]
        for l, p, f, must in picked:
            out.append((sid, p, l, f, must, fields))
    return out

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
            # (force, queue): every outcome of the first branch, and for a case
            # that holds another branch, every outcome of that one too.
            picks = []
            for c in (br['cases'] if br else [None]):
                inner = first_branch(c['action']) if c else None
                picks += [(c['label'], i['label']) for i in inner['cases']] if inner else [(c['label'] if c else None, None)]
            for f, q in picks:
                onbs = [False, True] if has_context(a) else [False]
                for onb in onbs:
                    eff = resolve(a, f, onb, q)
                    if eff['kind'] == 'route' and eff['screen'] == sid and a['type'] in ('replace',):
                        pass
                    row = {'screen': sid, 'element': label, 'path': path, 'force': f, 'onboarding': onb, 'platform': platform, 'expect': eff}
                    if q is not None: row['queue'] = q
                    out.append(row)
    return out

def dart_tests(out_dir):
    exps = expectations()
    rows = []
    for x in exps:
        e = x['expect']
        exp = {'route': f"('route', {dstr(e.get('route'))})", 'pop': "('pop', null)", 'toast': f"('toast', {dstr(e.get('text'))})", 'platform': f"('platform', {dstr(e.get('value'))})"}[e['kind']]
        rows.append(f"  ({dstr(x['screen'])}, Routes.{camel(x['screen'])}, {dstr(x['path'])}, {dstr(x['element'])}, {dstr(x['force'])}, {'true' if x['onboarding'] else 'false'}, {'true' if x['platform'] == 'ios' else 'false'}, {exp}, {dstr(x.get('queue'))}),")
    sweep = f"""// GENERATED — button-flow sweep: taps every interactive element on every
// screen (every branch outcome, with and without the onboarding context)
// and checks it lands exactly where spec/actions.json says. A branch inside a
// case is decided by the simulation queue (the last field).
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

const _cases = <(String, String, String, String, String?, bool, bool, (String, String?), String?)>[
{chr(10).join(rows)}
];

void main() {{
  for (final c in _cases) {{
    final name = 'sweep ${{c.$1}} · ${{c.$4}}${{c.$5 != null ? ' → ${{c.$5}}' : ''}}${{c.$9 != null ? ' → ${{c.$9}}' : ''}}${{c.$6 ? ' (onboarding)' : ''}}';
    testWidgets(name, (tester) async {{
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      TSession.clear();
      TFlow.onboarding = c.$6;
      TSim.force = c.$5;
      if (c.$9 != null) TSim.queue.add(c.$9!);
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
    open(os.path.join(out_dir, 'test', 'action_sweep_test.dart'), 'w', newline='\n').write(sweep)

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
    open(os.path.join(out_dir, 'test', 'scenarios_test.dart'), 'w', newline='\n').write(code)
    placeholders_test(out_dir)
    large_text_test(out_dir)
    return len(exps), len(SCENARIOS)

def large_text_cases():
    """Screens with unit fields (blood pressure, labs, ranges): (screen, [(session key, unit, example)])."""
    out = []
    for sid, s in SCREENS.items():
        fields = [(f"{sid}.{n['key']}", n['unit'], n.get('placeholder') or '') for part in ('body', 'footer') for n, p in walk(s[part], part)
                  if n['t'] == 'field' and n.get('unit') and n.get('kind') not in ('select', 'date')]
        if fields: out.append((sid, fields))
    return out

def large_text_test(out_dir):
    rows = [f"  ({dstr(sid)}, Routes.{camel(sid)}, {lst_d([f'({dstr(k)}, {dstr(u)}, {dstr(x)})' for k, u, x in fields])})," for sid, fields in large_text_cases()]
    code = f"""// GENERATED — unit fields at 200% text. On every screen with a unit field
// (mmHg, mg/dL, %...) the unit must be visible while the field is empty, the
// example hint must not be cut, and a typed value of the example's length
// must fit in full next to its unit. Text is measured with Roboto from the
// Flutter SDK (the test font draws every glyph 1 em wide).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

const _cases = <(String, String, List<(String, String, String)>)>[
{chr(10).join(rows)}
];

/// The unit's text exists inside [field] and no ancestor fades it out.
void _expectUnitVisible(WidgetTester tester, Finder field, String unit, String state) {{
  final f = find.descendant(of: field, matching: find.text(unit));
  expect(f, findsOneWidget, reason: 'unit "$unit" missing ($state)');
  RenderObject? r = tester.renderObject(f);
  final stop = tester.renderObject(field);
  while (r != null && r != stop) {{
    if (r is RenderOpacity) expect(r.opacity, greaterThan(0), reason: 'unit "$unit" hidden ($state)');
    if (r is RenderAnimatedOpacity) expect(r.opacity.value, greaterThan(0), reason: 'unit "$unit" hidden ($state)');
    r = r.parent;
  }}
}}

Future<void> _loadRoboto() async {{
  final root = Platform.environment['FLUTTER_ROOT'];
  expect(root, isNotNull, reason: 'FLUTTER_ROOT is not set; run with flutter test');
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {{
    final file = File('$root/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
    expect(file.existsSync(), isTrue, reason: '${{file.path}} is missing (flutter precache)');
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer)));
  }}
  await loader.load();
}}

void main() {{
  setUpAll(_loadRoboto);
  for (final c in _cases) {{
    testWidgets('200% text · ${{c.$1}}', (tester) async {{
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      TSession.clear();
      await tester.pumpWidget(MaterialApp(
        theme: tetherTheme(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        onGenerateInitialRoutes: (_) => [AppRouter.onGenerateRoute(RouteSettings(name: c.$2))!],
      ));
      await tester.pump(const Duration(milliseconds: 400));
      for (final (key, unit, example) in c.$3) {{
        final field = find.byKey(ValueKey('field:$key'));
        expect(field, findsOneWidget, reason: 'field $key');
        await tester.ensureVisible(field);
        await tester.pump();
        _expectUnitVisible(tester, field, unit, '$key empty');
        if (example.isNotEmpty) {{
          final hint = tester.renderObject<RenderParagraph>(find.descendant(of: field, matching: find.text(example)));
          expect(hint.didExceedMaxLines, isFalse, reason: '$key: hint "$example" is cut at 200% text');
        }}
        final value = example.contains(RegExp(r'\\d')) ? example : '123';
        await tester.enterText(field, value);
        await tester.pump(const Duration(milliseconds: 300));
        _expectUnitVisible(tester, field, unit, '$key with "$value"');
        final editable = tester.state<EditableTextState>(find.descendant(of: field, matching: find.byType(EditableText))).renderEditable;
        expect(editable.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(editable.size.width + 0.5),
            reason: '$key: "$value" does not fit at 200% text (needs ${{editable.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}}, has ${{editable.size.width.toStringAsFixed(1)}})');
      }}
      expect(tester.takeException(), isNull);
    }});
  }}
}}
"""
    open(os.path.join(out_dir, 'test', 'large_text_test.dart'), 'w', newline='\n').write(code)
    return len(rows)


def placeholders_test(out_dir):
    rows = []
    for sid, path, label, force, must, fields in placeholder_cases():
        keys = lst_d([dstr(k) for k, _ in fields])
        hints = lst_d([f"({dstr(k)}, {dstr(ph)})" for k, ph in fields if ph])
        rows.append(f"  ({dstr(sid)}, Routes.{camel(sid)}, {dstr(path)}, {dstr(label)}, {dstr(force)}, {'true' if must else 'false'}, {keys}, {hints}),")
    bound = sorted(f"{sid}.{n['key']}" for sid, s in SCREENS.items() for part in ('body', 'footer') for n, p in walk(s[part], part) if n['t'] == 'field' and n.get('bind'))
    code = f"""// GENERATED — P-31: example values are placeholder (hint) text. Every
// screen with text fields is opened and its Save / Continue elements are
// tapped without typing. Each field must start empty, show its example only
// as hint text and hold null in the session (a bound field on a settings
// screen, P-71, writes nothing at all). Whatever is submitted must hold null
// for these fields and never an example value.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

class _RecordingApi implements TApi {{
  final List<(String, Map<String, Object?>)> calls = [];
  @override
  Future<TResult> submit(String endpoint, {{required String screenId}}) async {{
    calls.add((endpoint, Map<String, Object?>.of(TSession.values)));
    return const TResult.ok();
  }}
}}

bool _holds(Object? value, String example) => value == example || (value is List && value.contains(example));

/// Bound fields (spec `bind`, P-71): no session write until the member types.
const _bound = <String>{{{', '.join(dstr(k) for k in bound)}}};

const _cases = <(String, String, String, String, String?, bool, List<String>, List<(String, String)>)>[
{chr(10).join(rows)}
];

void main() {{
  for (final c in _cases) {{
    final name = 'no example submitted · ${{c.$1}} · ${{c.$4}}${{c.$5 != null ? ' → ${{c.$5}}' : ''}}';
    testWidgets(name, (tester) async {{
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      TSession.clear();
      TFlow.onboarding = false;
      TSim.force = c.$5;
      TNav.branchResolver = (context, question, outcomes) async => outcomes.first;
      final api = _RecordingApi();
      TApi.instance = api;
      try {{
        await tester.pumpWidget(MaterialApp(
          theme: tetherTheme(),
          onGenerateRoute: (s) => s.name == '{HOST}' ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: '{HOST}')),
            AppRouter.onGenerateRoute(RouteSettings(name: c.$2))!,
          ],
        ));
        await tester.pump(const Duration(milliseconds: 400));
        for (final key in c.$7) {{
          final field = find.byKey(ValueKey('field:$key'));
          expect(field, findsOneWidget, reason: 'field $key');
          final editable = tester.widget<EditableText>(find.descendant(of: field, matching: find.byType(EditableText)));
          expect(editable.controller.text, isEmpty, reason: '$key must start empty');
          expect(TSession.values.containsKey(key), !_bound.contains(key), reason: _bound.contains(key) ? '$key is bound: nothing is written until the member types' : '$key writes to the session');
          expect(TSession.values[key], isNull, reason: '$key must be null until the member types');
        }}
        for (final (key, hint) in c.$8) {{
          expect(find.descendant(of: find.byKey(ValueKey('field:$key')), matching: find.text(hint)), findsOneWidget, reason: '$key shows "$hint" as hint text');
        }}
        if (c.$3.isNotEmpty) {{
          final finder = find.byKey(ValueKey('a:${{c.$3}}'));
          expect(finder, findsOneWidget, reason: 'element ${{c.$3}} on ${{c.$1}}');
          await tester.ensureVisible(finder);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(finder, warnIfMissed: false);
          for (var i = 0; i < 6; i++) {{
            await tester.pump(const Duration(milliseconds: 120));
          }}
        }}
        if (c.$6) expect(api.calls, isNotEmpty, reason: '${{c.$4}} submits');
        final sent = api.calls.isEmpty ? [Map<String, Object?>.of(TSession.values)] : [for (final call in api.calls) call.$2];
        for (final values in sent) {{
          for (final key in c.$7) {{
            expect(values[key], isNull, reason: '$key was not typed, so nothing may be sent for it');
          }}
          for (final (_, hint) in c.$8) {{
            for (final e in values.entries) {{
              expect(_holds(e.value, hint), isFalse, reason: 'example "$hint" reached the session as ${{e.key}}');
            }}
          }}
        }}
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      }} finally {{
        TSim.reset();
        TApi.instance = PreviewApi();
      }}
    }});
  }}
}}
"""
    open(os.path.join(out_dir, 'test', 'placeholders_test.dart'), 'w', newline='\n').write(code)
    return len(rows)

def lst_d(items): return '[' + ', '.join(items) + ']'

