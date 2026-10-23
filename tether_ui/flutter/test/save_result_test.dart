// What a member is told after a save (R-164). No outbox keeps a failed
// save, so no failure message may say the entry was kept: every failure
// shows the kit's generic error, `kit.generic_error`. A queued save
// continues the flow with no message. Safety screens still open before the
// save is awaited, whatever the result.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/auth/auth_signin_screen.dart';
import 'package:tether_ui/screens/hw/hw_lipids_screen.dart';
import 'package:tether_ui/screens/rescue/crisis_screen.dart';
import 'package:tether_ui/ui/ui.dart';

const _host = '/__host';

class _Api implements TApi {
  _Api(this.answer);
  final Future<TResult> Function() answer;
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) => answer();
}

/// Every way a save can fail, as an adapter answer.
final _failures = <(String, Future<TResult> Function())>[
  ('failed', () async => const TResult.failed('synthetic_code')),
  ('adapter throws', () async => throw StateError('synthetic')),
  ('not configured', () async => const TResult.failed(TUnconfiguredApi.code)),
  ('timeout', () => Completer<TResult>().future),
];

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _open(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: (s) => s.name == _host ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: _host)),
      AppRouter.onGenerateRoute(RouteSettings(name: route))!,
    ],
  ));
  await _settle(tester);
}

Future<void> _tapKey(WidgetTester tester, String path) async {
  final finder = find.byKey(ValueKey('a:$path'));
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester);
}

List<String> _texts(WidgetTester tester) => [for (final t in tester.widgetList<Text>(find.byType(Text, skipOffstage: false))) t.data ?? t.textSpan?.toPlainText() ?? ''];

/// Texts shown since [before] that say an entry was kept.
List<String> _keptClaims(WidgetTester tester, List<String> before) => [
      for (final t in _texts(tester))
        if (!before.contains(t) && t.toLowerCase().contains('kept')) t,
    ];

/// Runs past [TNav.submitTimeout]; the toast it brings shows for 1.8 s.
Future<void> _finishTimeout(WidgetTester tester) async {
  await tester.pump(TNav.submitTimeout);
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    TSession.clear();
    TFlow.onboarding = false;
    TNav.submitTimeout = const Duration(seconds: 2);
  });
  tearDown(() {
    TApi.instance = PreviewApi();
    TNav.submitTimeout = const Duration(seconds: 30);
    TSession.clear();
  });

  test('the save failure message is the generic error and claims nothing was kept', () {
    expect(TNav.saveFailed, TFailClosedResolver.message);
    expect(TStrings.english.kitGenericError, TNav.saveFailed);
    expect(TNav.saveFailed.toLowerCase().contains('kept'), isFalse);
  });

  for (final (how, answer) in _failures) {
    testWidgets('a save that ends "$how" on the submitting screen shows the generic error and stays', (tester) async {
      await _open(tester, Routes.hwLipids);
      TApi.instance = _Api(answer);
      final before = _texts(tester);
      await _tapKey(tester, 'footer[0]');
      if (how == 'timeout') await _finishTimeout(tester);
      expect(find.text(TNav.saveFailed), findsOneWidget);
      expect(_keptClaims(tester, before), isEmpty);
      expect(find.byType(HwLipidsScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a save that ends "$how" after a safety choice: the crisis screen opened first; the message is the generic error', (tester) async {
      await _open(tester, Routes.eaMood);
      TApi.instance = _Api(answer);
      await tester.ensureVisible(find.text('Thoughts of harming myself'));
      await tester.tap(find.text('Thoughts of harming myself'), warnIfMissed: false);
      await _settle(tester);
      final before = _texts(tester);
      await _tapKey(tester, 'footer[0]');
      expect(find.byType(CrisisScreen), findsOneWidget, reason: 'the safety screen opens before the save is awaited');
      if (how == 'timeout') {
        // By then the crisis screen has replaced the submitting screen, so
        // nothing is shown over it (TNav.submit: only while it is mounted).
        await _finishTimeout(tester);
        expect(find.text(TNav.saveFailed), findsNothing);
      } else {
        expect(find.text(TNav.saveFailed), findsOneWidget);
      }
      expect(_keptClaims(tester, before), isEmpty);
      await tester.pump(const Duration(seconds: 3));
    });
  }

  testWidgets('a queued sign-in (not queueable) is a failure with the generic error', (tester) async {
    await _open(tester, Routes.authSignin);
    TApi.instance = _Api(() async => const TResult.queued());
    final before = _texts(tester);
    await _tapKey(tester, 'footer[0]');
    expect(find.text(TNav.saveFailed), findsOneWidget);
    expect(_keptClaims(tester, before), isEmpty);
    expect(find.byType(AuthSigninScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a queued save continues the flow and shows no message of its own', (tester) async {
    await _open(tester, Routes.hwLipids);
    TApi.instance = _Api(() async => const TResult.queued());
    final before = _texts(tester);
    await _tapKey(tester, 'footer[0]');
    expect(find.byType(HwLipidsScreen), findsNothing, reason: 'the flow continued (back)');
    expect(find.text('Panel saved'), findsOneWidget, reason: 'the designed confirmation runs as for a save');
    expect(find.text(TNav.saveFailed), findsNothing);
    expect(_keptClaims(tester, before), isEmpty);
    await tester.pump(const Duration(seconds: 3));
  });
}
