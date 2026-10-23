// A screen opened for one item (a lesson, a records source) is pushed with the
// item's identifier, which the app reads with TNav.argumentOf; without it a
// save on the screen cannot say which lesson or source it acts on.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

class _Pushes extends NavigatorObserver {
  final List<RouteSettings> settings = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => settings.add(route.settings);
}

Map<String, dynamic> _screens() => jsonDecode(File('../spec/screens.json').readAsStringSync()) as Map<String, dynamic>;

/// Every action in the spec, nested ones included.
Iterable<(String, Map<String, dynamic>)> _actions() sync* {
  Iterable<Map<String, dynamic>> walk(Map<String, dynamic>? a) sync* {
    if (a == null) return;
    yield a;
    for (final c in (a['cases'] as List<dynamic>? ?? const [])) {
      yield* walk((c as Map<String, dynamic>)['action'] as Map<String, dynamic>?);
    }
    yield* walk(a['then'] as Map<String, dynamic>?);
  }

  for (final e in _screens().entries) {
    for (final x in (e.value as Map<String, dynamic>)['actions'] as List<dynamic>) {
      for (final a in walk((x as Map<String, dynamic>)['action'] as Map<String, dynamic>?)) {
        yield (e.key, a);
      }
    }
  }
}

Future<_Pushes> _open(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final observer = _Pushes();
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    navigatorObservers: [observer],
    onGenerateRoute: (s) => s.name == '/__host' ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: '/__host')),
      AppRouter.onGenerateRoute(RouteSettings(name: route))!,
    ],
  ));
  await tester.pump(const Duration(milliseconds: 200));
  observer.settings.clear();
  return observer;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsOneWidget, reason: text);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder, warnIfMissed: false);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  tearDown(() {
    TData.instance = PreviewData();
    TSession.clear();
  });

  group('spec', () {
    test('every push to learn_lesson carries a <programme>.<slug> lesson id', () {
      var n = 0;
      for (final (sid, a) in _actions()) {
        if (a['to'] != 'learn_lesson') continue;
        n++;
        expect(a['type'], 'push', reason: sid);
        expect(a['arg'], matches(RegExp(r'^[a-z]{2}\.[a-z0-9]+(-[a-z0-9]+)*$')), reason: sid);
      }
      expect(n, greaterThan(10), reason: 'the lesson pushes were found');
    });

    test('every push to records_source carries a source id, and the disconnect sheet inherits it', () {
      var sources = 0, sheets = 0;
      for (final (sid, a) in _actions()) {
        if (a['to'] == 'records_source') {
          sources++;
          expect(a['arg'], matches(RegExp(r'^source_[0-9]+$')), reason: sid);
        }
        if (a['to'] == 'records_disconnect') {
          sheets++;
          expect(sid, 'records_source');
          expect(a['type'], 'sheet');
          expect(a['argInherit'], isTrue);
        }
      }
      expect(sources, 2);
      expect(sheets, 1);
    });
  });

  group('kit', () {
    testWidgets('push and sheet pass the argument, and argumentOf reads it', (tester) async {
      String? seen, seenProgram;
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (s) => MaterialPageRoute<void>(
          settings: s,
          builder: (c) => Builder(builder: (c) {
            if (s.name == '/item') {
              seen = TNav.argumentOf(c);
              seenProgram = TNav.programOf(c);
            }
            return const SizedBox();
          }),
        ),
        onGenerateInitialRoutes: (_) => [MaterialPageRoute<void>(settings: const RouteSettings(name: '/'), builder: (_) => const SizedBox())],
      ));
      final context = tester.element(find.byType(SizedBox));
      expect(TNav.argumentOf(context), isNull);
      unawaited(TNav.push(context, '/item', argument: 'bf.cravings-today'));
      await tester.pumpAndSettle();
      expect(seen, 'bf.cravings-today');
      expect(seenProgram, isNull);
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      unawaited(TNav.push(context, '/item', program: 'sf', argument: 'x'));
      await tester.pumpAndSettle();
      expect((seen, seenProgram), ('x', 'sf'));
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      unawaited(TNav.push(context, '/item'));
      await tester.pumpAndSettle();
      expect(seen, isNull, reason: 'no argument given');
    });
  });

  group('screens', () {
    testWidgets('Learn: a lesson card opens learn_lesson with its lesson id', (tester) async {
      final pushes = await _open(tester, Routes.learn);
      await _tapText(tester, 'Why “one more video” never feels like enough');
      expect(pushes.settings.single.name, Routes.learnLesson);
      expect(pushes.settings.single.arguments, const TRouteArgs(argument: 'sf.one-more-video'));
    });

    testWidgets('Health records: each source row opens records_source with its source id', (tester) async {
      final pushes = await _open(tester, Routes.recordsHub);
      await _tapText(tester, 'Patel Family Medicine');
      expect(pushes.settings.single.name, Routes.recordsSource);
      expect(pushes.settings.single.arguments, const TRouteArgs(argument: 'source_1'));
      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pumpAndSettle();
      pushes.settings.clear();
      await _tapText(tester, 'Medicare');
      expect(pushes.settings.single.arguments, const TRouteArgs(argument: 'source_2'));
    });

    testWidgets('Source details: Disconnect opens the sheet for the same source', (tester) async {
      final pushes = await _open(tester, Routes.recordsHub);
      await _tapText(tester, 'Medicare');
      pushes.settings.clear();
      await _tapText(tester, 'Disconnect');
      expect(pushes.settings.single.name, Routes.recordsDisconnect);
      expect(pushes.settings.single.arguments, const TRouteArgs(argument: 'source_2'));
    });
  });
}
