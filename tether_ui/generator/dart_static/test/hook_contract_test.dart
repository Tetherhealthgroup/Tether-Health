// Production hook contract: TApi.submit → TResult (with the submitting
// screen), how TNav.submit handles each result, and the replaceable branch
// resolver with its fail-closed production implementation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/hw/hw_lipids_screen.dart';
import 'package:tether_ui/screens/records/records_consent_device_screen.dart';
import 'package:tether_ui/screens/records/records_hub_screen.dart';
import 'package:tether_ui/screens/records/records_importing_screen.dart';
import 'package:tether_ui/screens/records/records_manual_error_screen.dart';
import 'package:tether_ui/screens/records/records_manual_screen.dart';
import 'package:tether_ui/ui/ui.dart';

class _ScriptedApi implements TApi {
  _ScriptedApi(this.result);
  final TResult result;
  final List<(String, String)> calls = [];
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async {
    calls.add((endpoint, screenId));
    return result;
  }
}

const _host = '/__host';

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
    key: UniqueKey(), // a fresh navigator each time
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

void main() {
  setUp(() {
    TSession.clear();
    TFlow.onboarding = false;
  });
  tearDown(() {
    TApi.instance = PreviewApi();
    TNav.branchResolver = TNav.previewResolver;
    TSession.clear();
  });

  group('TResult', () {
    test('is sealed with ok, failed(code), outcome(label) and queued', () {
      String name(TResult r) => switch (r) {
            TOk() => 'ok',
            TFailed(:final code) => 'failed $code',
            TOutcome(:final label) => 'outcome $label',
            TQueued() => 'queued',
          };
      expect(name(const TResult.ok()), 'ok');
      expect(name(const TResult.failed('net_timeout')), 'failed net_timeout');
      expect(name(const TResult.outcome('Valid')), 'outcome Valid');
      expect(name(const TResult.queued()), 'queued');
    });

    test('has value equality', () {
      expect(const TResult.failed('a'), const TFailed('a'));
      expect(const TResult.failed('a'), isNot(const TResult.failed('b')));
      expect(const TResult.outcome('x'), const TOutcome('x'));
      expect(const TResult.ok(), isNot(const TResult.queued()));
    });
  });

  group('PreviewApi', () {
    test('is the default, records the endpoint and returns ok', () async {
      expect(TApi.instance, isA<PreviewApi>());
      final before = PreviewApi.calls.length;
      final r = await PreviewApi().submit('POST /v1/example', screenId: 'example_screen');
      expect(r, const TResult.ok());
      expect(PreviewApi.calls.length, before + 1);
      expect(PreviewApi.calls.last, 'POST /v1/example');
    });
  });

  group('TNav.submit', () {
    testWidgets('generated screens pass their own screen id', (tester) async {
      final api = _ScriptedApi(const TResult.ok());
      TApi.instance = api;
      await _open(tester, Routes.hwLipids);
      await _tapKey(tester, 'footer[0]');
      expect(api.calls, [('POST /v1/program-data/hw/lipids', 'hw_lipids')]);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('ok runs then', (tester) async {
      TApi.instance = _ScriptedApi(const TResult.ok());
      await _open(tester, Routes.hwLipids);
      await _tapKey(tester, 'footer[0]');
      expect(find.text('Panel saved'), findsOneWidget);
      expect(find.byType(HwLipidsScreen), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('queued runs then', (tester) async {
      TApi.instance = _ScriptedApi(const TResult.queued());
      await _open(tester, Routes.hwLipids);
      await _tapKey(tester, 'footer[0]');
      expect(find.text('Panel saved'), findsOneWidget);
      expect(find.byType(HwLipidsScreen), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('failed keeps the screen, shows the save error and never shows the code', (tester) async {
      TApi.instance = _ScriptedApi(const TResult.failed('synthetic_code_42'));
      await _open(tester, Routes.hwLipids);
      await _tapKey(tester, 'footer[0]');
      expect(find.text('Couldn’t save. Your entry is kept on this phone.'), findsOneWidget);
      expect(find.text('Panel saved'), findsNothing);
      expect(find.textContaining('synthetic_code_42'), findsNothing);
      expect(find.byType(HwLipidsScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('outcome decides the branch that no rule decides', (tester) async {
      TApi.instance = _ScriptedApi(const TResult.outcome('Matches an imported value'));
      var asked = false;
      TNav.branchResolver = (context, question, outcomes) async {
        asked = true;
        return null;
      };
      await _open(tester, Routes.recordsManual);
      await _tapKey(tester, 'footer[0]'); // nothing typed: rec.manual is undecided
      expect(asked, isFalse);
      expect(find.text('Already in your records from Epic. Not added twice.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('an on-device rule wins over the server outcome', (tester) async {
      TApi.instance = _ScriptedApi(const TResult.outcome('Valid'));
      await _open(tester, Routes.recordsManual);
      await tester.enterText(find.byKey(const ValueKey('field:records_manual.value')), '99'); // A1C 99 is outside 3–20
      await _settle(tester);
      await _tapKey(tester, 'footer[0]');
      expect(find.byType(RecordsManualErrorScreen), findsOneWidget);
      expect(find.byType(RecordsHubScreen), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('an outcome that matches no case falls through to the resolver', (tester) async {
      TApi.instance = _ScriptedApi(const TResult.outcome('Not a case label'));
      final asked = <String>[];
      TNav.branchResolver = (context, question, outcomes) async {
        asked.add(question);
        return null;
      };
      await _open(tester, Routes.recordsManual);
      await _tapKey(tester, 'footer[0]');
      expect(asked, ['Validation']);
      expect(find.byType(RecordsManualScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('the server outcome reaches only the branch inside then', (tester) async {
      TApi.instance = _ScriptedApi(const TResult.outcome('Allowed'));
      await _open(tester, Routes.hwLipids);
      await _tapKey(tester, 'footer[0]'); // submit with no branch in then
      await tester.pump(const Duration(seconds: 3));
      final asked = <String>[];
      TNav.branchResolver = (context, question, outcomes) async {
        asked.add(question);
        return null;
      };
      await _open(tester, Routes.recordsConsentDevice);
      await _tapKey(tester, 'footer[0]'); // later branch with the same label: must not take it
      expect(asked, ['System permission result']);
      expect(find.byType(RecordsImportingScreen), findsNothing);
    });
  });

  group('branch resolver', () {
    test('preview chooser is the default', () {
      expect(TNav.branchResolver, same(TNav.previewResolver));
    });

    testWidgets('preview default shows the "Preview: …" chooser', (tester) async {
      await _open(tester, Routes.recordsConsentDevice);
      await _tapKey(tester, 'footer[0]');
      expect(find.text('Preview: System permission result'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Allowed'));
      await _settle(tester);
      expect(find.byType(RecordsImportingScreen), findsOneWidget);
    });

    testWidgets('fail-closed: undecided branch takes no outcome, shows a generic error, records a code', (tester) async {
      final codes = <String>[];
      final resolver = TFailClosedResolver(onCode: codes.add);
      TNav.branchResolver = resolver.resolve;
      await _open(tester, Routes.recordsConsentDevice);
      await _tapKey(tester, 'footer[0]');
      expect(find.textContaining('Preview:'), findsNothing);
      expect(find.text('Real logic decides this in production.'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(TFailClosedResolver.message), findsOneWidget);
      expect(find.byType(RecordsConsentDeviceScreen), findsOneWidget);
      expect(find.byType(RecordsImportingScreen), findsNothing);
      expect(codes, [TFailClosedResolver.code]);
      expect(resolver.recorded, [TFailClosedResolver.code]);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('fail-closed: the code carries no question or outcome text', (tester) async {
      final codes = <String>[];
      TNav.branchResolver = TFailClosedResolver(onCode: codes.add).resolve;
      await _open(tester, Routes.recordsConsentDevice);
      await _tapKey(tester, 'footer[0]');
      expect(codes, hasLength(1));
      for (final word in ['System', 'permission', 'Allowed', 'Not allowed']) {
        expect(codes.single.contains(word), isFalse, reason: word);
      }
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('fail-closed: the app can show its own error', (tester) async {
      var shown = 0;
      TNav.branchResolver = TFailClosedResolver(showError: (_) => shown++).resolve;
      await _open(tester, Routes.recordsConsentDevice);
      await _tapKey(tester, 'footer[0]');
      expect(shown, 1);
      expect(find.text(TFailClosedResolver.message), findsNothing);
      expect(find.textContaining('Preview:'), findsNothing);
      expect(find.byType(RecordsImportingScreen), findsNothing);
    });

    testWidgets('fail-closed: rules still decide before the resolver', (tester) async {
      final resolver = TFailClosedResolver();
      TNav.branchResolver = resolver.resolve;
      TApi.instance = _ScriptedApi(const TResult.ok());
      await _open(tester, Routes.recordsManual);
      await tester.enterText(find.byKey(const ValueKey('field:records_manual.value')), '99');
      await _settle(tester);
      await _tapKey(tester, 'footer[0]');
      expect(find.byType(RecordsManualErrorScreen), findsOneWidget);
      expect(resolver.recorded, isEmpty);
    });

    testWidgets('fail-closed: returns no outcome and keeps at most 20 recorded codes', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      final resolver = TFailClosedResolver(showError: (_) {});
      for (var i = 0; i < 25; i++) {
        expect(await resolver.resolve(ctx, 'q', const ['a', 'b']), isNull);
      }
      expect(resolver.recorded, List<String>.filled(20, TFailClosedResolver.code));
    });
  });
}
