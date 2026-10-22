// Production hook contract: TApi.submit → TResult (with the submitting
// screen), how TNav.submit handles each result, and the replaceable branch
// resolver with its fail-closed production implementation.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/ca/ca_red_screen.dart';
import 'package:tether_ui/screens/ca/ca_zone_screen.dart';
import 'package:tether_ui/screens/ea/ea_mood_screen.dart';
import 'package:tether_ui/screens/hw/hw_crisis_screen.dart';
import 'package:tether_ui/screens/hw/hw_lipids_screen.dart';
import 'package:tether_ui/screens/hw/hw_log2_screen.dart';
import 'package:tether_ui/screens/st/st_log_screen.dart';
import 'package:tether_ui/screens/st/st_low_screen.dart';
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

/// A save that completes only when the test says so (or never).
class _GatedApi implements TApi {
  final Completer<TResult> gate = Completer<TResult>();
  int calls = 0;
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) {
    calls++;
    return gate.future;
  }
}

/// A save per call, each completing only when the test says so.
class _EachCallApi implements TApi {
  _EachCallApi(this.gates);
  final List<Completer<TResult>> gates;
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) {
    final gate = Completer<TResult>();
    gates.add(gate);
    return gate.future;
  }
}

/// Every route name pushed or put in place by a replace, in order.
class _Arrivals extends NavigatorObserver {
  final List<String?> names = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => names.add(route.settings.name);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => names.add(newRoute?.settings.name);
}

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

/// Opens records_consent_device with "Blood pressure" selected, so Continue
/// reaches the permission request (P-78: nothing starts selected).
Future<void> _openDeviceConsent(WidgetTester tester) async {
  await _open(tester, Routes.recordsConsentDevice);
  final item = find.text('Blood pressure');
  await tester.ensureVisible(item);
  await tester.tap(item);
  await _settle(tester);
}

Future<void> _open(WidgetTester tester, String route, {List<NavigatorObserver> observers = const []}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(), // a fresh navigator each time
    theme: tetherTheme(),
    navigatorObservers: observers,
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
    TNav.submitTimeout = const Duration(seconds: 30);
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
      await _openDeviceConsent(tester);
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
      await _openDeviceConsent(tester);
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
      await _openDeviceConsent(tester);
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
      await _openDeviceConsent(tester);
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
      await _openDeviceConsent(tester);
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

    testWidgets('a then that throws still clears the outcome and ends the submit', (tester) async {
      await _hostPage(tester);
      final api = _ScriptedApi(const TResult.outcome('A'));
      TApi.instance = api;
      await expectLater(TNav.submit(_hostContext, 'POST /x', screenId: 's', then: () => throw StateError('synthetic')), throwsStateError);
      final took = <String>[];
      await TNav.branch(_hostContext, 'Later', {'A': () => took.add('A')});
      expect(took, isEmpty);
      expect(asked, ['Later']);
      expect(await TNav.submit(_hostContext, 'POST /x', screenId: 's'), const TResult.outcome('A'));
      expect(api.calls, hasLength(2), reason: 'the submit is no longer in flight');
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
      await _openDeviceConsent(tester);
      await _tapKey(tester, 'footer[0]');
      expect(find.textContaining('Preview:'), findsNothing);
      expect(find.text(TFailClosedResolver.message), findsOneWidget);
      expect(find.byType(RecordsImportingScreen), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('release defaults: a crisis call button shows only the call fallback with the number, and records a code without it', (tester) async {
      TDefaults.forRelease();
      final codes = <String>[];
      TNav.reporter = (code, _) => codes.add(code);
      addTearDown(() => TNav.reporter = TNav.reportToFlutterError);
      final platform = TPlatform.instance as TInertPlatform;
      await _open(tester, Routes.crisis);
      expect(find.byType(CrisisScreen), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('a:body[1]')));
      await _settle(tester);
      final before = _texts(tester).toList();
      await _tapKey(tester, 'body[1]'); // Call 988
      expect(find.textContaining('Would call'), findsNothing);
      expect(find.textContaining('Would '), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(_texts(tester).toList(), [...before, TCallFallbackCopy.callMessage('988'), '988', TCallFallbackCopy.copy, TCallFallbackCopy.close], reason: 'the only new text is the call fallback');
      expect(platform.recorded, [TInertPlatform.code]);
      expect(platform.recorded.single.contains('988'), isFalse);
      expect(codes, [TCallFallback.shownCode]);
      TCallFallback.dismiss();
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

  group('failed save and safety outcomes', () {
    // (name, screen, the screen's type, entry, the rule's result, the safety
    // screen's type or null when the result is not a safety outcome).
    Future<void> enter(WidgetTester tester, String key, String value) async {
      await tester.enterText(find.byKey(ValueKey('field:$key')), value);
      await _settle(tester);
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text), warnIfMissed: false);
      await _settle(tester);
    }

    final cases = <(String, String, Type, Future<void> Function(WidgetTester), String, Type?)>[
      ('ca_zone', Routes.caZone, CaZoneScreen, (t) => enter(t, 'ca_zone.peak_flow', '150'), 'Red', CaRedScreen),
      ('ca_zone', Routes.caZone, CaZoneScreen, (t) => enter(t, 'ca_zone.peak_flow', '310'), 'Yellow', null),
      ('ca_zone', Routes.caZone, CaZoneScreen, (t) => enter(t, 'ca_zone.peak_flow', '2000'), 'Invalid peak flow', null),
      ('ea_mood', Routes.eaMood, EaMoodScreen, (t) => tapText(t, 'Thoughts of harming myself'), 'Yes', CrisisScreen),
      ('ea_mood', Routes.eaMood, EaMoodScreen, (t) async {}, 'No', null),
      ('hw_log2', Routes.hwLog2, HwLog2Screen, (t) async {
        await enter(t, 'hw_log2.systolic', '186');
        await enter(t, 'hw_log2.diastolic', '122');
      }, '≥180 top or ≥120 bottom', HwCrisisScreen),
      ('hw_log2', Routes.hwLog2, HwLog2Screen, (t) async {
        await enter(t, 'hw_log2.systolic', '132');
        await enter(t, 'hw_log2.diastolic', '84');
      }, 'Valid · below crisis range', null),
      ('hw_log2', Routes.hwLog2, HwLog2Screen, (t) async {
        await enter(t, 'hw_log2.systolic', '132');
        await enter(t, 'hw_log2.diastolic', '310');
      }, 'Invalid value', null),
      ('st_log', Routes.stLog, StLogScreen, (t) => enter(t, 'st_log.reading', '62'), 'Below your low', StLowScreen),
      ('st_log', Routes.stLog, StLogScreen, (t) => enter(t, 'st_log.reading', '142'), 'In or above range', null),
      ('records_manual', Routes.recordsManual, RecordsManualScreen, (t) => enter(t, 'records_manual.value', '99'), 'Outside expected range', null),
      ('records_manual', Routes.recordsManual, RecordsManualScreen, (t) => enter(t, 'records_manual.value', '6'), 'Valid', null),
    ];

    final failures = <(String, void Function())>[
      ('failed', () => TApi.instance = _ScriptedApi(const TResult.failed('synthetic_code'))),
      ('adapter error', () => TApi.instance = _ThrowingApi(Exception(_canary))),
      ('release defaults', TDefaults.forRelease),
    ];

    for (final (sid, route, screenType, entry, result, safetyType) in cases) {
      for (final (how, install) in failures) {
        final expectation = safetyType == null ? 'stays on $sid' : 'opens ${safetyType.toString()}';
        testWidgets('$how save · $sid · $result → $expectation', (tester) async {
          install();
          await _open(tester, route);
          await entry(tester);
          expect(TRules.decide({'ca_zone': 'ca.zone', 'ea_mood': 'ea.selfharm', 'hw_log2': 'hw.bp', 'st_log': 'st.glucose', 'records_manual': 'rec.manual'}[sid]!, TSession.values), result);
          await _tapKey(tester, 'footer[0]');
          expect(tester.takeException(), isNull);
          expect(find.text('Couldn’t save. Your entry is kept on this phone.'), findsOneWidget);
          if (safetyType == null) {
            expect(find.byType(screenType), findsOneWidget);
            expect(find.text('Saved'), findsNothing);
          } else {
            expect(find.byType(safetyType), findsOneWidget);
            expect(find.byType(screenType), findsNothing);
          }
          for (final t in _texts(tester)) {
            expect(t.contains('canary'), isFalse, reason: t);
          }
          await tester.pump(const Duration(seconds: 3));
        });
      }
    }

    testWidgets('a successful save with a non-safety value follows the branch', (tester) async {
      TApi.instance = _ScriptedApi(const TResult.ok());
      await _open(tester, Routes.stLog);
      await enter(tester, 'st_log.reading', '142');
      await _tapKey(tester, 'footer[0]');
      expect(find.byType(StLogScreen), findsNothing);
      expect(find.text('Couldn’t save. Your entry is kept on this phone.'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('safety outcome before the save', () {
    Future<void> selfHarm(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Thoughts of harming myself'));
      await tester.tap(find.text('Thoughts of harming myself'), warnIfMissed: false);
      await _settle(tester);
    }

    testWidgets('a save that never completes: the crisis screen opens at once', (tester) async {
      final api = _GatedApi();
      TApi.instance = api;
      await _open(tester, Routes.eaMood);
      await selfHarm(tester);
      await tester.tap(find.byKey(const ValueKey('a:footer[0]')), warnIfMissed: false);
      await tester.pump(); // one frame: no waiting for the save
      await tester.pump(const Duration(milliseconds: 400)); // route transition
      expect(api.calls, 1);
      expect(api.gate.isCompleted, isFalse);
      expect(find.byType(CrisisScreen), findsOneWidget);
      // The save times out in the background; nothing navigates again.
      await tester.pump(const Duration(seconds: 31));
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(find.byType(EaMoodScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('leaving while the save is pending: the crisis screen was already shown, and a later failure navigates nowhere', (tester) async {
      final api = _GatedApi();
      final arrivals = _Arrivals();
      TApi.instance = api;
      await _open(tester, Routes.eaMood, observers: [arrivals]);
      await selfHarm(tester);
      await tester.tap(find.byKey(const ValueKey('a:footer[0]')), warnIfMissed: false);
      await tester.pump();
      expect(arrivals.names.last, Routes.crisis, reason: 'crisis opened on the tap, before any back');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CrisisScreen), findsOneWidget);
      await tester.binding.handlePopRoute(); // the member presses back
      await _settle(tester);
      final seen = arrivals.names.length;
      api.gate.complete(const TResult.failed('synthetic_code'));
      await _settle(tester);
      expect(arrivals.names.length, seen, reason: 'no navigation after the save finished');
      expect(arrivals.names.where((n) => n == Routes.crisis), hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    });

    for (final (how, result) in <(String, TResult)>[('ok', const TResult.ok()), ('queued', const TResult.queued()), ('outcome', const TResult.outcome('Yes'))]) {
      testWidgets('a save that succeeds ($how): exactly one navigation to the crisis screen', (tester) async {
        final arrivals = _Arrivals();
        TApi.instance = _ScriptedApi(result);
        await _open(tester, Routes.eaMood, observers: [arrivals]);
        await selfHarm(tester);
        await _tapKey(tester, 'footer[0]');
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(CrisisScreen), findsOneWidget);
        expect(arrivals.names.where((n) => n == Routes.crisis), hasLength(1));
        expect(find.text('Couldn’t save. Your entry is kept on this phone.'), findsNothing);
        await tester.pump(const Duration(seconds: 3));
      });
    }

    testWidgets('hw_log2 crisis reading with a successful save: one navigation to hw_crisis', (tester) async {
      final arrivals = _Arrivals();
      TApi.instance = _ScriptedApi(const TResult.ok());
      await _open(tester, Routes.hwLog2, observers: [arrivals]);
      await tester.enterText(find.byKey(const ValueKey('field:hw_log2.systolic')), '186');
      await tester.enterText(find.byKey(const ValueKey('field:hw_log2.diastolic')), '122');
      await _settle(tester);
      await _tapKey(tester, 'footer[0]');
      expect(find.byType(HwCrisisScreen), findsOneWidget);
      expect(arrivals.names.where((n) => n == Routes.hwCrisis), hasLength(1));
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a non-safety value waits for the save, then follows the branch', (tester) async {
      final api = _GatedApi();
      final arrivals = _Arrivals();
      TApi.instance = api;
      await _open(tester, Routes.eaMood, observers: [arrivals]);
      final seen = arrivals.names.length;
      await tester.tap(find.byKey(const ValueKey('a:footer[0]')), warnIfMissed: false);
      await _settle(tester);
      expect(arrivals.names.length, seen, reason: 'nothing happens before the save finishes');
      expect(find.byType(EaMoodScreen), findsOneWidget);
      api.gate.complete(const TResult.ok());
      await _settle(tester);
      expect(find.text('Saved'), findsOneWidget); // the "No" outcome: toast, then back
      expect(find.byType(EaMoodScreen), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    test('pick() reads only the session: TSim.force and TSim.queue do not affect it', () {
      var ran = '';
      final routes = TSafetyRoutes('ea.selfharm', {'Yes': () => ran = 'crisis'});
      TSession.set('ea_mood.going_on', ['Work']);
      TSim.force = 'Yes';
      TSim.queue.add('Yes');
      expect(routes.pick(), isNull);
      TSession.set('ea_mood.going_on', ['Thoughts of harming myself']);
      TSim.force = 'No';
      TSim.queue
        ..clear()
        ..add('No');
      routes.pick()!();
      expect(ran, 'crisis');
      TSim.reset();
    });
  });

  group('in-flight guard', () {
    const saveError = 'Couldn’t save. Your entry is kept on this phone.';

    Future<void> selfHarm(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Thoughts of harming myself'));
      await tester.tap(find.text('Thoughts of harming myself'), warnIfMissed: false);
      await _settle(tester);
    }

    testWidgets('two pointer taps 150 ms apart during a slow save: one submit, then runs once', (tester) async {
      final api = _GatedApi();
      TApi.instance = api;
      await _open(tester, Routes.hwLipids);
      final button = find.byKey(const ValueKey('a:footer[0]'));
      await tester.ensureVisible(button);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 150));
      expect(api.calls, 1);
      api.gate.complete(const TResult.ok());
      await tester.pump();
      expect(find.text('Panel saved'), findsOneWidget);
      await _settle(tester);
      expect(find.byType(HwLipidsScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('assistive-technology double activation (semantics tap twice): one submit', (tester) async {
      final semantics = tester.ensureSemantics();
      final api = _GatedApi();
      TApi.instance = api;
      await _open(tester, Routes.hwLipids);
      await tester.ensureVisible(find.byKey(const ValueKey('a:footer[0]')));
      await _settle(tester);
      final node = find.semantics.byLabel('Save panel');
      tester.semantics.tap(node);
      tester.semantics.tap(node);
      await tester.pump();
      expect(api.calls, 1);
      api.gate.complete(const TResult.ok());
      await _settle(tester);
      expect(find.byType(HwLipidsScreen), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      semantics.dispose();
    });

    for (final (how, finish) in <(String, Future<void> Function(WidgetTester, Completer<TResult>))>[
      ('failed', (t, gate) async => gate.complete(const TResult.failed('synthetic_code'))),
      ('adapter_error', (t, gate) async => gate.completeError(Exception(_canary))),
      ('timeout', (t, gate) => t.pump(const Duration(seconds: 30))), // submitTimeout passes during this pump
    ]) {
      testWidgets('after a $how save, a new tap submits again', (tester) async {
        final gates = <Completer<TResult>>[];
        TApi.instance = _EachCallApi(gates);
        await _open(tester, Routes.hwLipids);
        await _tapKey(tester, 'footer[0]');
        await tester.tap(find.byKey(const ValueKey('a:footer[0]')), warnIfMissed: false); // in flight: ignored
        await tester.pump(const Duration(milliseconds: 150));
        expect(gates, hasLength(1));
        await finish(tester, gates.single);
        await tester.pump();
        expect(find.text(saveError), findsOneWidget);
        expect(find.byType(HwLipidsScreen), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        await _tapKey(tester, 'footer[0]'); // the retry
        expect(gates, hasLength(2));
        gates.last.complete(const TResult.ok());
        await _settle(tester);
        expect(find.text('Panel saved'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
      });
    }

    testWidgets('the guard is per screen and submit', (tester) async {
      await _hostPage(tester);
      final gates = <Completer<TResult>>[];
      TApi.instance = _EachCallApi(gates);
      final first = TNav.submit(_hostContext, 'POST /x', screenId: 'a');
      final again = TNav.submit(_hostContext, 'POST /x', screenId: 'a');
      final otherScreen = TNav.submit(_hostContext, 'POST /x', screenId: 'b');
      final otherSubmit = TNav.submit(_hostContext, 'POST /y', screenId: 'a');
      expect(gates, hasLength(3), reason: 'same screen and submit: ignored; another screen or submit: sent');
      for (final g in gates) {
        g.complete(const TResult.ok());
      }
      expect(await again, isNull);
      expect(await first, const TResult.ok());
      expect(await otherScreen, const TResult.ok());
      expect(await otherSubmit, const TResult.ok());
    });

    // Protects the safety path, not the guard: the first tap replaces the
    // screen with the crisis screen, and the Navigator absorbs the second
    // pointer, so this passes with or without the guard. The semantics test
    // below is the guard test for the safety path.
    testWidgets('safety path: a second pointer tap during the transition opens nothing more (one crisis screen, one submit)', (tester) async {
      final api = _GatedApi();
      final arrivals = _Arrivals();
      TApi.instance = api;
      await _open(tester, Routes.eaMood, observers: [arrivals]);
      await selfHarm(tester);
      final button = find.byKey(const ValueKey('a:footer[0]'));
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(api.calls, 1);
      expect(find.byType(CrisisScreen), findsOneWidget);
      api.gate.complete(const TResult.ok());
      await _settle(tester);
      expect(arrivals.names.where((n) => n == Routes.crisis), hasLength(1));
      expect(find.text('Saved'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('safety path: semantics double activation opens the crisis screen exactly once, with one submit', (tester) async {
      final semantics = tester.ensureSemantics();
      final api = _GatedApi();
      final arrivals = _Arrivals();
      TApi.instance = api;
      await _open(tester, Routes.eaMood, observers: [arrivals]);
      await selfHarm(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('a:footer[0]')));
      await _settle(tester);
      final node = find.semantics.byLabel('Save');
      tester.semantics.tap(node);
      tester.semantics.tap(node);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(api.calls, 1);
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(arrivals.names.where((n) => n == Routes.crisis), hasLength(1));
      api.gate.complete(const TResult.ok());
      await _settle(tester);
      expect(arrivals.names.where((n) => n == Routes.crisis), hasLength(1));
      await tester.pump(const Duration(seconds: 3));
      semantics.dispose();
    });

    testWidgets('a safety value chosen during a slow save opens the crisis screen at once, once, with one submit', (tester) async {
      final api = _GatedApi();
      final arrivals = _Arrivals();
      TApi.instance = api;
      await _open(tester, Routes.eaMood, observers: [arrivals]);
      await _tapKey(tester, 'footer[0]'); // "No": waits for the save
      expect(find.byType(EaMoodScreen), findsOneWidget);
      await selfHarm(tester);
      await tester.tap(find.byKey(const ValueKey('a:footer[0]')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(api.calls, 1, reason: 'the second tap sends no second save');
      expect(find.byType(CrisisScreen), findsOneWidget);
      api.gate.complete(const TResult.ok());
      await _settle(tester);
      expect(arrivals.names.where((n) => n == Routes.crisis), hasLength(1));
      expect(find.text('Saved'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('in-flight guard belongs to the screen instance', () {
    late BuildContext host;

    Future<void> openHost(WidgetTester tester, _Arrivals arrivals) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      Widget hostPage(BuildContext c) {
        host = c;
        return const Scaffold();
      }

      await tester.pumpWidget(MaterialApp(
        key: UniqueKey(),
        theme: tetherTheme(),
        navigatorObservers: [arrivals],
        onGenerateRoute: (s) => s.name == _host ? MaterialPageRoute<void>(builder: hostPage, settings: s) : AppRouter.onGenerateRoute(s),
        onGenerateInitialRoutes: (_) => [MaterialPageRoute<void>(builder: hostPage, settings: const RouteSettings(name: _host))],
      ));
      await _settle(tester);
    }

    Future<void> openMood(WidgetTester tester, {int expected = 1}) async {
      unawaited(Navigator.of(host).pushNamed(Routes.eaMood));
      await _settle(tester);
      expect(find.byType(EaMoodScreen, skipOffstage: false), findsNWidgets(expected));
    }

    Future<void> selfHarm(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Thoughts of harming myself'));
      await tester.tap(find.text('Thoughts of harming myself'), warnIfMissed: false);
      await _settle(tester);
    }

    Future<void> save(WidgetTester tester) async {
      final button = find.byKey(const ValueKey('a:footer[0]'));
      await tester.ensureVisible(button);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(button, warnIfMissed: false);
      await _settle(tester);
    }

    void leave() => Navigator.of(host).popUntil((r) => r.settings.name == _host);

    int crisisArrivals(_Arrivals a) => a.names.where((n) => n == Routes.crisis).length;

    Future<void> finish(WidgetTester tester, List<Completer<TResult>> gates) async {
      for (final g in gates) {
        if (!g.isCompleted) g.complete(const TResult.ok());
      }
      await _settle(tester);
      await tester.pump(const Duration(seconds: 3));
    }

    testWidgets('re-opened during a slow safety save, a safety value opens the crisis screen again and is saved', (tester) async {
      final gates = <Completer<TResult>>[];
      TApi.instance = _EachCallApi(gates);
      final arrivals = _Arrivals();
      await openHost(tester, arrivals);
      await openMood(tester);
      await selfHarm(tester);
      await save(tester);
      expect(find.byType(CrisisScreen), findsOneWidget);
      leave(); // the member leaves the crisis screen; the first save is still in flight
      await _settle(tester);
      await openMood(tester);
      await selfHarm(tester);
      await save(tester);
      expect(crisisArrivals(arrivals), 2);
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(gates, hasLength(2), reason: 'the second entry is sent');
      await finish(tester, gates);
      expect(crisisArrivals(arrivals), 2, reason: 'nothing navigates when the saves finish');
    });

    testWidgets('re-opened during a slow non-safety save, a safety value opens the crisis screen and is saved', (tester) async {
      final gates = <Completer<TResult>>[];
      TApi.instance = _EachCallApi(gates);
      final arrivals = _Arrivals();
      await openHost(tester, arrivals);
      await openMood(tester);
      await save(tester); // "No": waits for the save
      expect(find.byType(EaMoodScreen), findsOneWidget);
      leave(); // the screen is disposed while its save is in flight
      await _settle(tester);
      await openMood(tester);
      await selfHarm(tester);
      await save(tester);
      expect(crisisArrivals(arrivals), 1);
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(gates, hasLength(2), reason: 'the safety entry is sent');
      await finish(tester, gates);
      expect(crisisArrivals(arrivals), 1);
    });

    testWidgets('after TSession.clear (sign-out) during a slow safety save, the next safety value opens the crisis screen and is saved', (tester) async {
      final gates = <Completer<TResult>>[];
      TApi.instance = _EachCallApi(gates);
      final arrivals = _Arrivals();
      await openHost(tester, arrivals);
      await openMood(tester);
      await selfHarm(tester);
      await save(tester);
      leave();
      await _settle(tester);
      TSession.clear(); // sign-out or account switch
      await openMood(tester);
      await selfHarm(tester);
      await save(tester);
      expect(crisisArrivals(arrivals), 2);
      expect(gates, hasLength(2));
      await finish(tester, gates);
    });

    testWidgets('TSession.clear ends the guard on a screen that stays open: the next tap sends its own save', (tester) async {
      final gates = <Completer<TResult>>[];
      TApi.instance = _EachCallApi(gates);
      final arrivals = _Arrivals();
      await openHost(tester, arrivals);
      await openMood(tester);
      await save(tester); // "No": waits for the save
      expect(gates, hasLength(1));
      TSession.clear();
      await tester.pump();
      await selfHarm(tester);
      await save(tester);
      expect(gates, hasLength(2), reason: 'the next session’s tap is not blocked by the earlier save');
      expect(crisisArrivals(arrivals), 1);
      await finish(tester, gates);
    });

    testWidgets('a second instance pushed on top of one with a save in flight sends its own save and opens its own crisis screen', (tester) async {
      final gates = <Completer<TResult>>[];
      TApi.instance = _EachCallApi(gates);
      final arrivals = _Arrivals();
      await openHost(tester, arrivals);
      await openMood(tester);
      await save(tester); // "No": waits for the save
      expect(gates, hasLength(1));
      await openMood(tester, expected: 2); // the same screen again, on top
      await selfHarm(tester);
      await save(tester);
      expect(gates, hasLength(2));
      expect(crisisArrivals(arrivals), 1);
      expect(find.byType(CrisisScreen), findsOneWidget);
      await finish(tester, gates);
    });
  });

  group('save timeout', () {
    testWidgets('safety path: the background save gives failed(timeout) after submitTimeout, and nothing navigates again', (tester) async {
      TNav.submitTimeout = const Duration(seconds: 5);
      final api = _GatedApi();
      final arrivals = _Arrivals();
      TApi.instance = api;
      await _open(tester, Routes.eaMood, observers: [arrivals]);
      await tester.ensureVisible(find.text('Thoughts of harming myself'));
      await tester.tap(find.text('Thoughts of harming myself'), warnIfMissed: false);
      await _settle(tester);
      final context = tester.element(find.byType(EaMoodScreen));
      var ran = 0;
      TResult? result;
      var done = false;
      unawaited(TNav.submit(context, 'POST /v1/program-data/ea/moods', screenId: 'ea_mood', then: () => fail('then must not run on the safety path'), safety: TSafetyRoutes('ea.selfharm', {
        'Yes': () {
          ran++;
          TNav.push(context, Routes.crisis);
        },
      })).then((r) {
        result = r;
        done = true;
      }));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(ran, 1);
      expect(find.byType(CrisisScreen), findsOneWidget);
      final seen = arrivals.names.length;
      await tester.pump(const Duration(seconds: 4));
      expect(done, isFalse, reason: 'still waiting for the save before submitTimeout');
      await tester.pump(const Duration(seconds: 2));
      expect(done, isTrue);
      expect(result, const TResult.failed(TNav.timeoutCode));
      expect(api.calls, 1);
      await _settle(tester);
      expect(ran, 1);
      expect(arrivals.names.length, seen, reason: 'no navigation after the timeout');
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a save that never completes gives failed(timeout) after submitTimeout', (tester) async {
      final api = _GatedApi();
      TApi.instance = api;
      TResult? result;
      unawaited(TNav.safeSubmit('POST /v1/example', screenId: 'example').then((r) => result = r));
      await tester.pump(const Duration(seconds: 29));
      expect(result, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(result, const TResult.failed(TNav.timeoutCode));
    });

    testWidgets('the timeout is configurable', (tester) async {
      TNav.submitTimeout = const Duration(seconds: 5);
      TApi.instance = _GatedApi();
      TResult? result;
      unawaited(TNav.safeSubmit('POST /v1/example', screenId: 'example').then((r) => result = r));
      await tester.pump(const Duration(seconds: 4));
      expect(result, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(result, const TResult.failed(TNav.timeoutCode));
    });

    testWidgets('a save that times out keeps the screen and shows the save error', (tester) async {
      TApi.instance = _GatedApi();
      await _open(tester, Routes.hwLipids);
      await _tapKey(tester, 'footer[0]');
      expect(find.text('Couldn’t save. Your entry is kept on this phone.'), findsNothing);
      await tester.pump(const Duration(seconds: 30));
      await tester.pump();
      expect(find.text('Couldn’t save. Your entry is kept on this phone.'), findsOneWidget);
      expect(find.byType(HwLipidsScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
