// TData hook and TBound slots.
//
// TH-902a: binding changes data, never layout or visuals. On 10
// representative screens every text, big number, chart, list and stat grid
// is replaced by a bound slot that carries the same value, and the result
// must be pixel-identical (and render-tree identical) to the generated
// screen, both with PreviewData (fallback path) and with a real TData that
// returns the same values (data path). The spec screens themselves are not
// annotated here (that is TH-909); these are demo usages in tests only.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

/// A TData backed by fixed values, standing in for the app's real one.
class _MapData implements TData {
  _MapData(this.values);
  final Map<String, Object?> values;
  final Map<String, ValueNotifier<Object?>> notifiers = {};
  @override
  ValueListenable<Object?> watch(String bindKey) => notifiers.putIfAbsent(bindKey, () => ValueNotifier<Object?>(values[bindKey]));
}

/// Replaces every bindable component in [w] by a bound slot carrying the
/// same value, and records that value under its bind key in [values].
Widget _bind(Widget w, Map<String, Object?> values, String path) {
  List<Widget> all(List<Widget> ws, String p) => [for (var i = 0; i < ws.length; i++) _bind(ws[i], values, '$p.$i')];
  String key(Object? value) {
    final k = 'demo.$path';
    values[k] = value;
    return k;
  }

  return switch (w) {
    TScreen() => TScreen(key: w.key, header: w.header, tab: w.tab, background: w.background, children: all(w.children, '${path}b'), footer: all(w.footer, '${path}f')),
    TSheet() => TSheet(key: w.key, children: all(w.children, '${path}b'), footer: all(w.footer, '${path}f')),
    TCard() => TCard(
        key: w.key,
        variant: w.variant,
        tag: w.tag,
        tagExtra: w.tagExtra,
        eyebrow: w.eyebrow,
        title: w.title,
        text: w.text,
        accent: w.accent,
        onTap: w.onTap,
        cta: w.cta,
        children: all(w.children, '${path}c'),
      ),
    TBody() => TBound.text(key(w.text), fallback: w.text, builder: (c, v) => TBody(v, key: w.key, tone: w.tone, center: w.center)),
    TTitle() => TBound.text(key(w.text), fallback: w.text, builder: (c, v) => TTitle(v, key: w.key, size: w.size, center: w.center)),
    TBigNumber() => TBound.text(key(w.value), fallback: w.value, builder: (c, v) => TBigNumber(key: w.key, value: v, unit: w.unit, caption: w.caption, center: w.center)),
    TBarChart() => TBound.series(key(w.values), fallback: w.values,
        builder: (c, v) => TBarChart(key: w.key, values: v, color: w.color, title: w.title, unit: w.unit, missing: w.missing, target: w.target, labels: w.labels, caption: w.caption, tag: w.tag, onTap: w.onTap)),
    TLineChart() => TBound.series(key(w.values), fallback: w.values,
        builder: (c, v) => TLineChart(key: w.key, values: v, color: w.color, title: w.title, unit: w.unit, band: w.band, caption: w.caption, tag: w.tag, onTap: w.onTap)),
    TListGroup() => TBound.list<TListRow>(key(w.rows), fallback: w.rows, builder: (c, v) => TListGroup(key: w.key, title: w.title, rows: v, flat: w.flat)),
    TStatGrid() => TBound.list<TStat>(key(w.stats), fallback: w.stats, builder: (c, v) => TStatGrid(key: w.key, stats: v, columns: w.columns)),
    _ => w,
  };
}

const _frame = ValueKey('parity-frame');

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    home: RepaintBoundary(key: _frame, child: child),
  ));
  await tester.pump(const Duration(milliseconds: 50));
}

/// Render tree under the frame: every render object with its type, layout
/// and paint properties. Removed: object ids, dirty flags, repaint-boundary
/// usage counters, and the creator chains (they name the widgets that built
/// each render object, so they name TBoundSlot by design).
String _renderTree(WidgetTester tester) {
  // Creator chains are debug-level properties; info level keeps layout and
  // paint properties.
  final dump = tester.renderObject(find.byKey(_frame)).toStringDeep(minLevel: DiagnosticLevel.info);
  return dump
      .split('\n')
      .where((l) => !l.contains('metrics:') && !l.contains('diagnosis:'))
      .map((l) => l.replaceAll(RegExp(r'SemanticsNode#\d+'), 'SemanticsNode#').replaceAll(RegExp(r'#[0-9a-f]{5}'), '#').replaceAll(RegExp(r' NEEDS-[A-Z-]+'), ''))
      .join('\n');
}

Future<ui.Image> _capture(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_frame));
  return (await tester.runAsync(() => boundary.toImage()))!;
}

int _slots(WidgetTester tester) => tester.widgetList(find.byWidgetPredicate((w) => w is TBoundSlot, skipOffstage: false)).length;

/// Ten representative screens: charts (bar and line), stat grids, lists,
/// big numbers, titles and text, light and dark cards.
const _screens = <(String, String)>[
  ('today', Routes.today),
  ('progress', Routes.progress),
  ('bf_progress', Routes.bfProgress),
  ('hw_trends', Routes.hwTrends),
  ('hw_home', Routes.hwHome),
  ('st_patterns', Routes.stPatterns),
  ('ca_progress', Routes.caProgress),
  ('sf_week', Routes.sfWeek),
  ('records_item', Routes.recordsItem),
  ('account', Routes.account),
];

void main() {
  setUp(TSession.clear);
  tearDown(() {
    TData.instance = PreviewData();
    TSession.clear();
  });

  group('TData', () {
    test('PreviewData is the default and answers the example marker', () {
      expect(TData.instance, isA<PreviewData>());
      expect(TData.instance.watch('hw.last_bp').value, same(TData.example));
    });

    test('PreviewData can carry explicit values', () {
      final d = PreviewData({'hw.last_bp': '131/84', 'x.none': null});
      expect(d.watch('hw.last_bp').value, '131/84');
      expect(d.watch('x.none').value, isNull);
      expect(d.watch('other').value, same(TData.example));
      expect(d.watch('hw.last_bp'), same(d.watch('hw.last_bp')));
    });

    test('conversions accept only usable values', () {
      expect(TBound.textOf('128/82'), '128/82');
      expect(TBound.textOf(42), '42');
      expect(TBound.textOf(''), isNull);
      expect(TBound.textOf(null), isNull);
      expect(TBound.textOf(const ['a']), isNull);
      expect(TBound.seriesOf(const [1, 2.5]), [1.0, 2.5]);
      expect(TBound.seriesOf(const <num>[]), isNull);
      expect(TBound.seriesOf(const [1, 'x']), isNull);
      expect(TBound.seriesOf('1,2'), isNull);
      expect(TBound.listOf<String>(const ['a', 'b']), ['a', 'b']);
      expect(TBound.listOf<String>(const ['a', 1]), isNull);
      expect(TBound.listOf<String>(const <String>[]), isNull);
    });
  });

  group('TBound slots', () {
    testWidgets('text: preview shows the fallback; data shows the value and updates', (tester) async {
      await _pump(tester, TBound.text('demo.bp', fallback: '128/82', builder: (c, v) => TBigNumber(value: v, unit: 'mmHg')));
      expect(find.text('128/82'), findsOneWidget);
      final data = _MapData({'demo.bp': '131/84'});
      TData.instance = data;
      await _pump(tester, TBound.text('demo.bp', fallback: '128/82', builder: (c, v) => TBigNumber(value: v, unit: 'mmHg')));
      expect(find.text('131/84'), findsOneWidget);
      expect(find.text('128/82'), findsNothing);
      data.notifiers['demo.bp']!.value = 119;
      await tester.pump();
      expect(find.text('119'), findsOneWidget);
    });

    testWidgets('a real TData with no value never shows the fallback', (tester) async {
      TData.instance = _MapData({});
      await _pump(
          tester,
          Column(children: [
            TBound.text('demo.bp', fallback: '128/82'),
            TBound.series('demo.week', fallback: const [128, 131], builder: (c, v) => TBarChart(values: v, color: TColors.teal, title: 'Week')),
            TBound.list<TListRow>('demo.rows', fallback: const [TListRow(label: 'Synthetic row')], builder: (c, v) => TListGroup(rows: v)),
            TBound.text('demo.empty', fallback: '—', empty: (c) => const Text('No readings yet')),
          ]));
      expect(find.text('128/82'), findsNothing);
      expect(find.text('Week'), findsNothing);
      expect(find.text('Synthetic row'), findsNothing);
      expect(find.text('—'), findsNothing);
      expect(find.text('No readings yet'), findsOneWidget);
    });

    testWidgets('a value of the wrong type counts as no value', (tester) async {
      TData.instance = _MapData({'demo.week': 'not a series', 'demo.rows': const ['not a row']});
      await _pump(
          tester,
          Column(children: [
            TBound.series('demo.week', fallback: const [128, 131], builder: (c, v) => TBarChart(values: v, color: TColors.teal, title: 'Week')),
            TBound.list<TListRow>('demo.rows', fallback: const [TListRow(label: 'Synthetic row')], builder: (c, v) => TListGroup(rows: v)),
          ]));
      expect(find.text('Week'), findsNothing);
      expect(find.text('Synthetic row'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('default text builder is TBody', (tester) async {
      await _pump(tester, TBound.text('demo.t', fallback: 'Synthetic text'));
      expect(find.widgetWithText(TBody, 'Synthetic text'), findsOneWidget);
    });
  });

  group('pixel parity', () {
    for (final (sid, route) in _screens) {
      for (final mode in ['preview data', 'real data']) {
        testWidgets('bound parity · $sid · $mode', (tester) async {
          tester.view.physicalSize = const Size(1170, 2532);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await _pump(tester, Builder(builder: (c) => AppRouter.screens[route]!(c)));
          final staticTree = _renderTree(tester);
          final staticImage = await _capture(tester);
          final screen = tester.widget<TScreen>(find.byType(TScreen));
          final values = <String, Object?>{};
          final bound = _bind(screen, values, sid);
          if (mode == 'real data') TData.instance = _MapData(values);
          TSession.clear();
          await _pump(tester, bound);
          expect(_slots(tester), values.length, reason: 'every bindable component became a slot');
          expect(values, isNotEmpty);
          expect(_renderTree(tester), staticTree, reason: '$sid: render tree differs');
          await expectLater(find.byKey(_frame), matchesReferenceImage(staticImage));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 3));
        });
      }
    }

    testWidgets('the ten screens cover text, number, series and list slots', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final kinds = <Type>{};
      for (final (_, route) in _screens) {
        await _pump(tester, Builder(builder: (c) => AppRouter.screens[route]!(c)));
        for (final t in [TBody, TTitle, TBigNumber, TBarChart, TLineChart, TListGroup, TStatGrid]) {
          if (find.byType(t, skipOffstage: false).evaluate().isNotEmpty) kinds.add(t);
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(kinds, containsAll(<Type>[TBody, TTitle, TBigNumber, TBarChart, TLineChart, TListGroup, TStatGrid]));
    });
  });
}
