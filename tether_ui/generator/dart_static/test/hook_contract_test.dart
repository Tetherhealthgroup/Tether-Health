// Production hook contract: TApi.submit → TResult (with the submitting
// screen), how TNav.submit handles each result, and the replaceable branch
// resolver with its fail-closed production implementation.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/hw/hw_lipids_screen.dart';
import 'package:tether_ui/screens/rescue/crisis_screen.dart';
import 'package:tether_ui/screens/records/records_consent_device_screen.dart';
import 'package:tether_ui/screens/records/records_hub_screen.dart';
import 'package:tether_ui/screens/records/records_importing_screen.dart';
import 'package:tether_ui/screens/records/records_manual_error_screen.dart';
import 'package:tether_ui/screens/records/records_manual_screen.dart';
import 'package:tether_ui/ui/ui.dart';

class _ThrowingApi implements TApi {
  _ThrowingApi(this.error);
  final Object error;
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async => throw error;
}

class _ScriptedAuth implements TAuth {
  _ScriptedAuth(this.answer);
  final Future<String?> Function() answer;
  @override
  Future<String?> signIn(String provider, List<String> outcomes) => answer();
}

/// Synthetic payload that must never reach the UI or a recorded code.
const _canary = 'canary-synthetic-user-01-bp-187-121';

/// A bare host screen; [_hostContext] is a context under a Navigator.
late BuildContext _hostContext;

Future<void> _hostPage(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    home: Scaffold(body: Builder(builder: (c) {
      _hostContext = c;
      return const SizedBox();
    })),
  ));
}

/// Every text on screen, including toasts in the overlay.
Iterable<String> _texts(WidgetTester tester) => tester.widgetList<Text>(find.byType(Text, skipOffstage: false)).map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');

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
    TDefaults.forPreview();
    TAuth.instance = null;
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

    test('an outcome never prints its label', () {
      const r = TResult.outcome('Thoughts of harming myself');
      expect(r.toString(), 'TResult.outcome(<redacted>)');
      expect('$r'.contains('harming'), isFalse);
      expect(const TResult.failed('net_timeout').toString(), 'TResult.failed(net_timeout)');
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

  group('server outcome scope', () {
    late List<String> asked;
    setUp(() {
      asked = <String>[];
      TNav.branchResolver = (c, q, o) async {
        asked.add(q);
        return null;
      };
    });

    testWidgets('a branch nested inside the chosen outcome does not get the server outcome', (tester) async {
      await _hostPage(tester);
      TApi.instance = _ScriptedApi(const TResult.outcome('A'));
      final took = <String>[];
      await TNav.submit(_hostContext, 'POST /x', screenId: 's', then: () => TNav.branch(_hostContext, 'Q1', {
            'A': () {
              took.add('Q1:A');
              TNav.branch(_hostContext, 'Q2', {'A': () => took.add('Q2:A'), 'B': () => took.add('Q2:B')});
            },
            'B': () => took.add('Q1:B'),
          }));
      await tester.pump();
      expect(took, ['Q1:A']);
      expect(asked, ['Q2']);
    });

    testWidgets('a then that throws still clears the outcome', (tester) async {
      await _hostPage(tester);
      TApi.instance = _ScriptedApi(const TResult.outcome('A'));
      await expectLater(TNav.submit(_hostContext, 'POST /x', screenId: 's', then: () => throw StateError('synthetic')), throwsStateError);
      final took = <String>[];
      await TNav.branch(_hostContext, 'Later', {'A': () => took.add('A')});
      expect(took, isEmpty);
      expect(asked, ['Later']);
    });
  });

  group('adapter exceptions', () {
    for (final error in <Object>[Exception(_canary), StateError(_canary), _canary]) {
      testWidgets('safeSubmit maps a thrown ${error.runtimeType} to failed(adapter_error)', (tester) async {
        TApi.instance = _ThrowingApi(error);
        final r = await TNav.safeSubmit('POST /v1/example', screenId: 'example');
        expect(r, const TResult.failed(TNav.adapterErrorCode));
        expect('$r'.contains('canary'), isFalse);
      });
    }

    testWidgets('a throwing adapter keeps the screen, shows the save error, and shows or records no payload', (tester) async {
      TApi.instance = _ThrowingApi(Exception(_canary));
      final codes = <String>[];
      TNav.branchResolver = TFailClosedResolver(onCode: codes.add).resolve;
      await _open(tester, Routes.hwLipids);
      await _tapKey(tester, 'footer[0]');
      expect(tester.takeException(), isNull);
      expect(find.byType(HwLipidsScreen), findsOneWidget);
      expect(find.text('Couldn’t save. Your entry is kept on this phone.'), findsOneWidget);
      expect(find.text('Panel saved'), findsNothing);
      for (final t in _texts(tester)) {
        expect(t.contains('canary'), isFalse, reason: t);
      }
      expect(codes.where((c) => c.contains('canary')), isEmpty);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a throwing sign-in adapter decides nothing: the fail-closed resolver runs', (tester) async {
      await _hostPage(tester);
      TAuth.instance = _ScriptedAuth(() async => throw Exception(_canary));
      final codes = <String>[];
      TNav.branchResolver = TFailClosedResolver(onCode: codes.add).resolve;
      final took = <String>[];
      await TNav.branch(_hostContext, 'Sign-in result', {'Success': () => took.add('Success'), 'Error': () => took.add('Error')}, provider: 'apple');
      await tester.pump();
      expect(took, isEmpty);
      expect(codes, [TFailClosedResolver.code]);
      expect(find.text(TFailClosedResolver.message), findsOneWidget);
      for (final t in _texts(tester)) {
        expect(t.contains('canary'), isFalse, reason: t);
      }
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a sign-in label that is not a case decides nothing: the fail-closed resolver runs', (tester) async {
      await _hostPage(tester);
      TAuth.instance = _ScriptedAuth(() async => 'Not a case label');
      final codes = <String>[];
      TNav.branchResolver = TFailClosedResolver(onCode: codes.add).resolve;
      final took = <String>[];
      await TNav.branch(_hostContext, 'Sign-in result', {'Success': () => took.add('Success'), 'Error': () => took.add('Error')}, provider: 'apple');
      await tester.pump();
      expect(took, isEmpty);
      expect(codes, [TFailClosedResolver.code]);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a sign-in label that is a case is taken', (tester) async {
      await _hostPage(tester);
      TAuth.instance = _ScriptedAuth(() async => 'Error');
      final resolver = TFailClosedResolver();
      TNav.branchResolver = resolver.resolve;
      final took = <String>[];
      await TNav.branch(_hostContext, 'Sign-in result', {'Success': () => took.add('Success'), 'Error': () => took.add('Error')}, provider: 'apple');
      expect(took, ['Error']);
      expect(resolver.recorded, isEmpty);
    });
  });

  group('defaults', () {
    test('debug and test builds start with the preview defaults', () {
      expect(kReleaseMode, isFalse);
      expect(TDefaults.api(), isA<PreviewApi>());
      expect(TDefaults.data(), isA<PreviewData>());
      expect(TDefaults.platform(), isA<PreviewPlatform>());
      expect(TDefaults.branchResolver(), same(TNav.previewResolver));
    });

    testWidgets('release defaults fail closed', (tester) async {
      TDefaults.forRelease();
      expect(TApi.instance, isA<TUnconfiguredApi>());
      expect(await TApi.instance.submit('POST /v1/example', screenId: 'example'), const TResult.failed('not_configured'));
      expect(TData.instance, isA<TEmptyData>());
      expect(TData.instance.watch('hw.last_bp').value, isNull);
      expect(TPlatform.instance, isA<TInertPlatform>());
      expect(TNav.branchResolver, isNot(same(TNav.previewResolver)));
    });

    testWidgets('release defaults: an undecided branch never shows the preview chooser', (tester) async {
      TDefaults.forRelease();
      await _open(tester, Routes.recordsConsentDevice);
      await _tapKey(tester, 'footer[0]');
      expect(find.textContaining('Preview:'), findsNothing);
      expect(find.text(TFailClosedResolver.message), findsOneWidget);
      expect(find.byType(RecordsImportingScreen), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('release defaults: a crisis call button shows nothing and records a code', (tester) async {
      TDefaults.forRelease();
      final platform = TPlatform.instance as TInertPlatform;
      await _open(tester, Routes.crisis);
      expect(find.byType(CrisisScreen), findsOneWidget);
      await _tapKey(tester, 'body[1]'); // Call 988
      expect(find.textContaining('Would call'), findsNothing);
      expect(find.textContaining('Would '), findsNothing);
      expect(platform.recorded, [TInertPlatform.code]);
      expect(platform.recorded.single.contains('988'), isFalse);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('release defaults: a save fails, keeps the screen and shows the save error', (tester) async {
      TDefaults.forRelease();
      await _open(tester, Routes.hwLipids);
      await _tapKey(tester, 'footer[0]');
      expect(find.byType(HwLipidsScreen), findsOneWidget);
      expect(find.text('Couldn’t save. Your entry is kept on this phone.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('release defaults: bound slots show no fallback', (tester) async {
      TDefaults.forRelease();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: TBound.text('hw.last_bp', fallback: '128/82'))));
      expect(find.text('128/82'), findsNothing);
    });

    test('forPreview restores the preview defaults', () {
      TDefaults.forRelease();
      TDefaults.forPreview();
      expect(TApi.instance, isA<PreviewApi>());
      expect(TData.instance, isA<PreviewData>());
      expect(TPlatform.instance, isA<PreviewPlatform>());
      expect(TNav.branchResolver, same(TNav.previewResolver));
    });
  });
}
