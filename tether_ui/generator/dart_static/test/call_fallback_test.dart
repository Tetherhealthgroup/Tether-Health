// When a call or text cannot be placed (TInertPlatform, a TPlatform that
// returns false, throws or does not answer in time), TNav.call / TNav.sms
// show TCallFallback with the number the action passed. The fallback is an
// entry in the root overlay, not a route: late submit results, safety
// actions and branch outcomes do not remove or cover it; TSession.clear
// does. The screen beneath stays usable. A safety action that throws does
// not stop the save.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/hw/hw_crisis_screen.dart';
import 'package:tether_ui/screens/rescue/crisis_screen.dart';
import 'package:tether_ui/screens/tabs/support_message_care_screen.dart';
import 'package:tether_ui/ui/ui.dart';

const _host = '/__host';

/// Synthetic payload that must never reach the UI or a reported error.
const _canary = 'canary-synthetic-user-01-bp-187-121';

const _fallback = ValueKey('call_fallback');
const _number = ValueKey('call_fallback.number');
const _copy = ValueKey('call_fallback.copy');
const _close = ValueKey('call_fallback.close');

/// A [TPlatform] whose call and text answer with [answer].
class _ScriptedPlatform implements TPlatform {
  _ScriptedPlatform(this.answer);
  final Future<bool> Function() answer;
  final List<String> attempts = [];
  @override
  Future<bool> call(BuildContext context, String number, String label) {
    attempts.add('call:$number');
    return answer();
  }

  @override
  Future<bool> sms(BuildContext context, String recipient) {
    attempts.add('sms:$recipient');
    return answer();
  }

  @override
  Future<void> openUrl(BuildContext context, String url) async {}
  @override
  Future<void> openOsSettings(BuildContext context) async {}
}

/// A save per call, each completing only when the test says so.
class _EachCallApi implements TApi {
  final List<Completer<TResult>> gates = [];
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) {
    final gate = Completer<TResult>();
    gates.add(gate);
    return gate.future;
  }
}

class _GatedAuth implements TAuth {
  final Completer<String?> gate = Completer<String?>();
  @override
  Future<String?> signIn(String provider, List<String> outcomes) => gate.future;
}

late BuildContext _hostContext;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Opens [route] (when given) above a bare host screen.
Future<void> _open(WidgetTester tester, {String? route, Size size = const Size(390, 844), double textScale = 1}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  Widget hostPage(BuildContext c) {
    _hostContext = c;
    return const Scaffold();
  }

  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: (s) => s.name == _host ? MaterialPageRoute<void>(builder: hostPage, settings: s) : AppRouter.onGenerateRoute(s),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: hostPage, settings: const RouteSettings(name: _host)),
      if (route != null) AppRouter.onGenerateRoute(RouteSettings(name: route))!,
    ],
  ));
  await _settle(tester);
}

Future<void> _tapKey(WidgetTester tester, String path) async {
  final finder = find.byKey(ValueKey('a:$path'));
  expect(finder, findsOneWidget, reason: 'a:$path');
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester);
}

/// The fallback is on screen with [kind]'s message for [value], shows
/// [value] as its number, and can be reached by a tap (nothing covers it).
void _expectFallback(TFallbackKind kind, String value) {
  expect(find.byKey(_fallback), findsOneWidget);
  expect(find.text(TCallFallbackCopy.message(kind, value)), findsOneWidget);
  final number = find.byKey(_number);
  expect(number, findsOneWidget);
  expect((number.evaluate().single.widget as Text).data, value);
  expect(find.byKey(_close).hitTestable(), findsOneWidget, reason: 'nothing covers the fallback');
  expect(find.byKey(_copy).hitTestable(), findsOneWidget);
}

void _expectNoFallback() => expect(find.byKey(_fallback), findsNothing);

/// Index of the overlay entry that holds [finder] in the root overlay's
/// paint order (higher paints above).
int _paintIndex(WidgetTester tester, Finder finder) {
  RenderObject? child = tester.renderObject(finder);
  RenderObject? parent = child.parent;
  while (parent != null && parent.runtimeType.toString() != '_RenderTheater') {
    child = parent;
    parent = parent.parent;
  }
  expect(parent, isNotNull);
  final order = <RenderObject>[];
  parent!.visitChildren(order.add);
  final i = order.indexOf(child!);
  expect(i, isNot(-1));
  return i;
}

/// Codes received by [TNav.reporter] during the test.
final List<String> _codes = [];

/// [code] was reported through [TNav.report], and no report carried payload.
void _expectReported(WidgetTester tester, String code) {
  expect(_codes, contains(code));
  expect(_codes.join(' '), isNot(contains(_canary)));
}

/// Ends the test after the toasts have gone.
Future<void> _drain(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pump(const Duration(seconds: 3));
}

Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  expect(root, isNotNull, reason: 'FLUTTER_ROOT is not set; run with flutter test');
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    final file = File('$root/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
    expect(file.existsSync(), isTrue, reason: '${file.path} is missing (flutter precache)');
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer)));
  }
  await loader.load();
}

/// Every call and text action in spec/screens/*.json, relative to the
/// package root (the flutter test cwd): (screen id, route, path, kind, value).
List<(String, String, String, TFallbackKind, String)> _specActions() {
  final out = <(String, String, String, TFallbackKind, String)>[];
  final files = Directory('../spec/screens').listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final screen = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    for (final a in (screen['actions'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final action = a['action'] as Map<String, dynamic>?;
      final type = action?['type'];
      if (type != 'call' && type != 'sms') continue;
      out.add((screen['id'] as String, screen['route'] as String, a['path'] as String, type == 'call' ? TFallbackKind.call : TFallbackKind.sms, action!['value'] as String));
    }
  }
  return out;
}

/// How a pending save finishes.
typedef _Finish = Future<void> Function(WidgetTester tester, Completer<TResult> gate);

final _finishes = <(String, _Finish)>[
  ('ok', (t, g) async => g.complete(const TResult.ok())),
  ('queued', (t, g) async => g.complete(const TResult.queued())),
  ('outcome', (t, g) async => g.complete(const TResult.outcome('No'))),
  ('failed', (t, g) async => g.complete(const TResult.failed('synthetic_code'))),
  ('adapter_error', (t, g) async => g.completeError(Exception('synthetic'))),
  ('timeout', (t, g) => t.pump(const Duration(seconds: 30))), // submitTimeout passes during this pump
];

void main() {
  setUp(() {
    TSession.clear();
    TFlow.onboarding = false;
    _codes.clear();
    TNav.reporter = (code, _) => _codes.add(code);
  });
  tearDown(() {
    TCallFallback.dismiss();
    TNav.reporter = TNav.reportToFlutterError;
    TNav.platformTimeout = const Duration(seconds: 8);
    TDefaults.forPreview();
    TAuth.instance = null;
    TNav.submitTimeout = const Duration(seconds: 30);
    TSession.clear();
  });

  group('release defaults (TInertPlatform)', () {
    final actions = _specActions();

    test('the spec has call and text actions, and the generated screens have exactly those', () {
      expect(actions, isNotEmpty);
      expect(actions.where((a) => a.$1 == 'crisis').map((a) => (a.$4, a.$5)), [(TFallbackKind.call, '988'), (TFallbackKind.sms, '988'), (TFallbackKind.call, '911')]);
      final generated = Directory('lib/screens')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => RegExp(r'TNav\.(call|sms)\(').allMatches(f.readAsStringSync()).length)
          .fold<int>(0, (a, b) => a + b);
      expect(generated, actions.length, reason: 'every generated call or text is in the list below');
    });

    for (final (sid, route, path, kind, value) in actions) {
      testWidgets('$sid · $path: shows "${TCallFallbackCopy.message(kind, value)}"', (tester) async {
        TDefaults.forRelease();
        final platform = TPlatform.instance as TInertPlatform;
        await _open(tester, route: route);
        _expectNoFallback();
        await _tapKey(tester, path);
        _expectFallback(kind, value);
        expect(platform.recorded, [TInertPlatform.code]);
        expect(_codes, [TCallFallback.shownCode], reason: 'the fallback is reported, without the number');
        expect(find.textContaining('Would '), findsNothing);
        await _drain(tester);
      });
    }
  });

  group('platform result', () {
    testWidgets('returns false: the fallback shows the number', (tester) async {
      final platform = _ScriptedPlatform(() async => false);
      TPlatform.instance = platform;
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]'); // Call 988
      expect(platform.attempts, ['call:988']);
      _expectFallback(TFallbackKind.call, '988');
      await _drain(tester);
    });

    testWidgets('a text that returns false: the fallback shows the short code', (tester) async {
      TPlatform.instance = _ScriptedPlatform(() async => false);
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[2]'); // Text 988
      _expectFallback(TFallbackKind.sms, '988');
      await _drain(tester);
    });

    testWidgets('throws asynchronously: the fallback shows the number and only a code is reported', (tester) async {
      TPlatform.instance = _ScriptedPlatform(() async => throw StateError(_canary));
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      _expectReported(tester, TNav.platformErrorCode);
      _expectFallback(TFallbackKind.call, '988');
      expect(find.textContaining(_canary), findsNothing);
      await _drain(tester);
    });

    testWidgets('throws synchronously: the fallback shows the number and only a code is reported', (tester) async {
      TPlatform.instance = _ScriptedPlatform(() => throw StateError(_canary));
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[3]'); // Call 911
      _expectReported(tester, TNav.platformErrorCode);
      _expectFallback(TFallbackKind.call, '911');
      await _drain(tester);
    });

    testWidgets('a text that throws: the fallback shows the short code', (tester) async {
      TPlatform.instance = _ScriptedPlatform(() => throw StateError(_canary));
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[2]');
      _expectReported(tester, TNav.platformErrorCode);
      _expectFallback(TFallbackKind.sms, '988');
      await _drain(tester);
    });

    for (final path in ['body[1]', 'body[2]', 'body[3]']) {
      testWidgets('succeeds ($path): no fallback', (tester) async {
        final platform = _ScriptedPlatform(() async => true);
        TPlatform.instance = platform;
        await _open(tester, route: Routes.crisis);
        await _tapKey(tester, path);
        expect(platform.attempts, hasLength(1));
        _expectNoFallback();
        await _drain(tester);
      });
    }

    testWidgets('preview platform (debug default): no fallback', (tester) async {
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      expect(PreviewPlatform.last, 'call:988');
      _expectNoFallback();
      await _drain(tester);
    });

    testWidgets('the platform answers false after the calling screen has closed: the fallback still shows', (tester) async {
      final answer = Completer<bool>();
      TPlatform.instance = _ScriptedPlatform(() => answer.future);
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      await tester.binding.handlePopRoute(); // the crisis screen closes
      await _settle(tester);
      expect(find.byType(CrisisScreen), findsNothing);
      answer.complete(false);
      await _settle(tester);
      _expectFallback(TFallbackKind.call, '988');
      await _drain(tester);
    });

    testWidgets('a later failed call replaces the fallback; Close removes it', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      await _tapKey(tester, 'body[3]');
      _expectFallback(TFallbackKind.call, '911');
      await tester.tap(find.byKey(_close));
      await _settle(tester);
      _expectNoFallback();
      expect(find.byType(CrisisScreen), findsOneWidget, reason: 'Close removes only the fallback');
      await _drain(tester);
    });
  });

  group('screen reader', () {
    testWidgets('the fallback is a live region labelled with the message and number, is announced, takes focus, and its number is selectable and copyable', (tester) async {
      final semantics = tester.ensureSemantics();
      final clipboard = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') clipboard.add((call.arguments as Map<Object?, Object?>)['text']);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis);
      tester.takeAnnouncements();
      await _tapKey(tester, 'body[1]');
      final message = TCallFallbackCopy.callMessage('988');

      final node = tester.getSemantics(find.byKey(_fallback));
      expect(node.label, message);
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      expect(find.descendant(of: find.byKey(_fallback), matching: find.bySemanticsLabel(message)), findsNothing, reason: 'the message is read once, from the region');
      expect(find.descendant(of: find.byKey(_fallback), matching: find.bySemanticsLabel('988')), findsOneWidget, reason: 'the number is read on its own');

      final announcements = tester.takeAnnouncements();
      expect(announcements.map((a) => a.message), contains(message));
      expect(announcements.firstWhere((a) => a.message == message).assertiveness, Assertiveness.assertive);

      expect(Focus.of(tester.element(find.byKey(_fallback))).hasFocus, isTrue);

      expect(find.ancestor(of: find.byKey(_number), matching: find.byType(SelectionArea)), findsOneWidget);
      for (final label in [TCallFallbackCopy.copy, TCallFallbackCopy.close]) {
        final button = tester.getSemantics(find.descendant(of: find.byKey(_fallback), matching: find.bySemanticsLabel(label)));
        expect(button.getSemanticsData().hasAction(SemanticsAction.tap), isTrue, reason: label);
      }

      await tester.tap(find.byKey(_copy));
      await _settle(tester);
      expect(clipboard, ['988']);
      expect(find.descendant(of: find.byKey(_copy), matching: find.text(TCallFallbackCopy.copied)), findsOneWidget, reason: 'confirmed on the button, inside the card');
      expect(find.text(TCallFallbackCopy.copied), findsOneWidget, reason: 'no toast under the card');
      final copied = tester.takeAnnouncements().where((a) => a.message == TCallFallbackCopy.copied).toList();
      expect(copied, hasLength(1));
      expect(copied.single.assertiveness, Assertiveness.polite);
      _expectFallback(TFallbackKind.call, '988');
      await tester.pump(const Duration(seconds: 2));
      expect(find.descendant(of: find.byKey(_copy), matching: find.text(TCallFallbackCopy.copy)), findsOneWidget, reason: 'reads Copy again');
      await _drain(tester);
      semantics.dispose();
    });
  });

  group('200% text', () {
    // Measured with Roboto from the Flutter SDK, as in large_text_test.dart
    // (the default test font draws every glyph 1 em wide).
    setUpAll(_loadRoboto);
    // (screen, route, path, kind, value) — the shortest and the longest numbers.
    final cases = <(String, String, String, TFallbackKind, String)>[
      ('crisis', Routes.crisis, 'body[1]', TFallbackKind.call, '988'),
      ('crisis', Routes.crisis, 'body[2]', TFallbackKind.sms, '988'),
      ('rescue_escalate', Routes.rescueEscalate, 'body[2].cta[0]', TFallbackKind.call, '1-800-784-8669'),
      ('sd_fell', Routes.sdFell, 'body[2].rows[0]', TFallbackKind.call, '(555) 010-2244'),
    ];
    for (final (sid, route, path, kind, value) in cases) {
      testWidgets('$sid · $path on a 320×568 screen: the whole fallback fits, nothing overflows', (tester) async {
        TDefaults.forRelease();
        await _open(tester, route: route, size: const Size(320, 568), textScale: 2);
        await _tapKey(tester, path);
        _expectFallback(kind, value);
        final screen = Offset.zero & const Size(320, 568);
        for (final key in [_fallback, _number, _copy, _close]) {
          final r = tester.getRect(find.byKey(key));
          expect(screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(0.01, 0.01)), isTrue, reason: '$key at $r');
        }
        final message = tester.getRect(find.text(TCallFallbackCopy.message(kind, value)));
        expect(screen.contains(message.topLeft) && screen.contains(message.bottomRight - const Offset(0.01, 0.01)), isTrue);
        await _drain(tester); // an overflow would be a reported exception
      });
    }
  });

  group('a late submit result does not remove or cover the fallback', () {
    late _EachCallApi api;
    setUp(() {
      TDefaults.forRelease();
      api = _EachCallApi();
      TApi.instance = api;
    });

    for (final (how, finish) in _finishes) {
      testWidgets('support_message_care: slow send, the member opens the crisis screen and taps Call 988, the save ends ($how)', (tester) async {
        await _open(tester, route: Routes.supportMessageCare);
        await _tapKey(tester, 'footer[0]'); // Send message: the save is in flight
        expect(api.gates, hasLength(1));
        await _tapKey(tester, 'body[4].actions[0]'); // Call or text 988
        await _tapKey(tester, 'body[1]'); // Call 988
        _expectFallback(TFallbackKind.call, '988');
        await finish(tester, api.gates.single);
        await _settle(tester);
        _expectFallback(TFallbackKind.call, '988');
        expect(ModalRoute.of(tester.element(find.byType(CrisisScreen)))!.isCurrent, isTrue);
        await _drain(tester);
      });
    }

    testWidgets('on the submitting screen itself: then shows its toast and goes back, the fallback stays above both', (tester) async {
      await _open(tester, route: Routes.supportMessageCare);
      await _tapKey(tester, 'footer[0]');
      await _tapKey(tester, 'body[4].actions[1]'); // Call 911 on the same screen
      _expectFallback(TFallbackKind.call, '911');
      api.gates.single.complete(const TResult.ok());
      await tester.pump();
      await tester.pump();
      expect(find.text('Message sent'), findsOneWidget);
      expect(_paintIndex(tester, find.byKey(_fallback)), greaterThan(_paintIndex(tester, find.text('Message sent'))), reason: 'the toast is below the fallback');
      await _settle(tester);
      expect(find.byType(SupportMessageCareScreen), findsNothing, reason: 'then ran as before');
      _expectFallback(TFallbackKind.call, '911');
      await _drain(tester);
    });

    testWidgets('a save error toast is inserted below the fallback', (tester) async {
      await _open(tester, route: Routes.supportMessageCare);
      await _tapKey(tester, 'footer[0]');
      await _tapKey(tester, 'body[4].actions[1]');
      api.gates.single.complete(const TResult.failed('synthetic_code'));
      await tester.pump();
      await tester.pump();
      const saveError = 'Couldn’t save. Your entry is kept on this phone.';
      expect(find.text(saveError), findsOneWidget);
      expect(_paintIndex(tester, find.byKey(_fallback)), greaterThan(_paintIndex(tester, find.text(saveError))));
      _expectFallback(TFallbackKind.call, '911');
      await _drain(tester);
    });

    testWidgets('hw_log2: a value edited to a crisis reading after the tap, the member opens the crisis screen and taps Call 988, the save succeeds: hw_crisis opens below the fallback', (tester) async {
      Future<void> enter(String key, String value) async {
        await tester.enterText(find.byKey(ValueKey('field:$key')), value);
        await _settle(tester);
      }

      await _open(tester, route: Routes.hwLog2);
      await enter('hw_log2.systolic', '132');
      await enter('hw_log2.diastolic', '84');
      await _tapKey(tester, 'footer[0]'); // not a safety value: the save is in flight
      await enter('hw_log2.systolic', '186');
      await enter('hw_log2.diastolic', '122');
      unawaited(Navigator.of(_hostContext).pushNamed(Routes.crisis));
      await _settle(tester);
      await _tapKey(tester, 'body[1]'); // Call 988
      _expectFallback(TFallbackKind.call, '988');
      api.gates.single.complete(const TResult.ok());
      await _settle(tester);
      expect(ModalRoute.of(tester.element(find.byType(HwCrisisScreen)))!.isCurrent, isTrue, reason: 'the safety screen opened on top');
      expect(_paintIndex(tester, find.byKey(_fallback)), greaterThan(_paintIndex(tester, find.byType(HwCrisisScreen))));
      _expectFallback(TFallbackKind.call, '988');
      await _drain(tester);
    });
  });

  group('a late branch outcome does not remove the fallback', () {
    for (final (name, action) in <(String, Future<void> Function(BuildContext))>[('close', TNav.close), ('back', TNav.back)]) {
      testWidgets('a sign-in branch started on the screen below ends with $name after the member opened the crisis screen and tapped Call 988', (tester) async {
        TDefaults.forRelease();
        final auth = _GatedAuth();
        TAuth.instance = auth;
        await _open(tester);
        final took = <String>[];
        unawaited(TNav.branch(_hostContext, 'Sign-in result', {
          'Cancelled': () {
            took.add('Cancelled');
            action(_hostContext);
          },
        }, provider: 'apple'));
        unawaited(Navigator.of(_hostContext).pushNamed(Routes.crisis));
        await _settle(tester);
        await _tapKey(tester, 'body[1]');
        _expectFallback(TFallbackKind.call, '988');
        auth.gate.complete('Cancelled');
        await _settle(tester);
        // The screen that asked is covered by the crisis screen, so the late
        // outcome is dropped (TNav.branch route scope) and nothing is popped.
        expect(took, isEmpty);
        expect(find.byType(CrisisScreen), findsOneWidget);
        _expectFallback(TFallbackKind.call, '988');
        await _drain(tester);
      });
    }

    testWidgets('the member’s own back leaves the fallback in place', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.byType(CrisisScreen), findsNothing);
      _expectFallback(TFallbackKind.call, '988');
      await _drain(tester);
    });
  });

  group('a cleared session removes the fallback', () {
    testWidgets('TSession.clear (sign-out) removes it and stops listening', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.beTx);
      await _tapKey(tester, 'body[1].cta[0]'); // Call oncology team
      _expectFallback(TFallbackKind.call, '(555) 010-7000');
      expect(TCallFallback.debugListensToSession, isTrue);
      TSession.clear();
      await _settle(tester);
      _expectNoFallback();
      expect(find.textContaining('(555) 010-7000'), findsNothing);
      expect(TCallFallback.debugListensToSession, isFalse, reason: 'no listener left on TSession.changes');
      expect(TCallFallback.inset.value, 0);
      await _drain(tester);
    });

    testWidgets('other session changes and TNav.reset leave it in place', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      TSession.set('crisis.synthetic', 'x');
      await _settle(tester);
      _expectFallback(TFallbackKind.call, '988');
      unawaited(TNav.reset(tester.element(find.byType(CrisisScreen)), Routes.today));
      await _settle(tester);
      _expectFallback(TFallbackKind.call, '988');
      await _drain(tester);
    });

    testWidgets('Close also stops listening', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      await tester.tap(find.byKey(_close));
      await _settle(tester);
      expect(TCallFallback.debugListensToSession, isFalse);
      expect(TCallFallback.inset.value, 0);
      await _drain(tester);
    });

    testWidgets('a platform that answers false after a sign-out shows nothing', (tester) async {
      final answer = Completer<bool>();
      TPlatform.instance = _ScriptedPlatform(() => answer.future);
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      TSession.clear();
      answer.complete(false);
      await _settle(tester);
      _expectNoFallback();
      expect(_codes, isEmpty);
      await _drain(tester);
    });
  });

  group('a platform that does not answer', () {
    testWidgets('never completes: the fallback shows after platformTimeout and platform_timeout is reported', (tester) async {
      final answer = Completer<bool>();
      TPlatform.instance = _ScriptedPlatform(() => answer.future);
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      await tester.pump(TNav.platformTimeout - const Duration(seconds: 2));
      _expectNoFallback();
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester);
      _expectFallback(TFallbackKind.call, '988');
      expect(_codes, [TNav.platformTimeoutCode, TCallFallback.shownCode]);
      await _drain(tester);
    });

    for (final late in [true, false]) {
      testWidgets('a late $late after the timeout changes nothing', (tester) async {
        final answer = Completer<bool>();
        TPlatform.instance = _ScriptedPlatform(() => answer.future);
        await _open(tester, route: Routes.crisis);
        await _tapKey(tester, 'body[1]');
        await tester.pump(TNav.platformTimeout);
        await _settle(tester);
        _expectFallback(TFallbackKind.call, '988');
        answer.complete(late);
        await _settle(tester);
        _expectFallback(TFallbackKind.call, '988');
        expect(_codes, [TNav.platformTimeoutCode, TCallFallback.shownCode], reason: 'no second fallback');
        await _drain(tester);
      });
    }

    test('the default wait is 8 seconds', () => expect(TNav.platformTimeout, const Duration(seconds: 8)));
  });

  group('the screen beneath stays usable at 200% text on 320×568', () {
    setUpAll(_loadRoboto);
    final byScreen = <String, List<(String, String, String, TFallbackKind, String)>>{};
    for (final a in _specActions()) {
      (byScreen[a.$1] ??= []).add(a);
    }
    for (final MapEntry(key: sid, value: actions) in byScreen.entries) {
      for (final (_, route, path, kind, value) in actions) {
        final others = actions.where((o) => o.$3 != path).toList();
        testWidgets('$sid · $path: the card covers at most ${(TCallFallback.maxHeightFraction * 100).round()}% and ${others.isEmpty ? 'nothing overflows' : 'every other call or text button can be scrolled to and tapped'}', (tester) async {
          TDefaults.forRelease();
          await _open(tester, route: route, size: const Size(320, 568), textScale: 2);
          await _tapKey(tester, path);
          _expectFallback(kind, value);
          final card = tester.getRect(find.byKey(_fallback));
          expect(card.height, lessThanOrEqualTo(568 * TCallFallback.maxHeightFraction + 0.5));
          for (final (_, _, other, _, _) in others) {
            final button = find.byKey(ValueKey('a:$other'));
            await tester.ensureVisible(button);
            await _settle(tester);
            expect(button.hitTestable(), findsOneWidget, reason: '$other is reachable');
            expect(tester.getRect(button).top, lessThan(card.top), reason: '$other is above the card');
          }
          _expectFallback(kind, value);
          await _drain(tester); // an overflow would be a reported exception
        });
      }
    }
  });

  group('the number stays whole', () {
    setUpAll(_loadRoboto);
    testWidgets('1-800-784-8669 at 200% on 320×568 is on one line inside the card, and Copy copies it unchanged', (tester) async {
      final clipboard = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') clipboard.add((call.arguments as Map<Object?, Object?>)['text']);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      TDefaults.forRelease();
      await _open(tester, route: Routes.rescueEscalate, size: const Size(320, 568), textScale: 2);
      await _tapKey(tester, 'body[2].cta[0]');
      _expectFallback(TFallbackKind.call, '1-800-784-8669');
      final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.byKey(_number), matching: find.byType(RichText)));
      final boxes = paragraph.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 14));
      expect(boxes.map((b) => b.top).toSet(), hasLength(1), reason: 'one line');
      final card = tester.getRect(find.byKey(_fallback));
      final number = tester.getRect(find.byKey(_number));
      expect(number.left, greaterThanOrEqualTo(card.left));
      expect(number.right, lessThanOrEqualTo(card.right));
      await tester.tap(find.byKey(_copy));
      await _settle(tester);
      expect(clipboard, ['1-800-784-8669']);
      await _drain(tester);
    });
  });

  group('root overlay', () {
    testWidgets('from a screen inside a nested navigator, a route pushed later on the root navigator stays below the fallback', (tester) async {
      TDefaults.forRelease();
      late BuildContext rootContext;
      await tester.pumpWidget(MaterialApp(
        theme: tetherTheme(),
        home: Builder(builder: (c) {
          rootContext = c;
          return Navigator(onGenerateRoute: (_) => AppRouter.onGenerateRoute(const RouteSettings(name: Routes.crisis)));
        }),
      ));
      await _settle(tester);
      await _tapKey(tester, 'body[1]');
      _expectFallback(TFallbackKind.call, '988');
      unawaited(Navigator.of(rootContext, rootNavigator: true).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: SizedBox.expand()))));
      await _settle(tester);
      expect(find.byType(CrisisScreen), findsNothing, reason: 'the nested navigator is covered');
      _expectFallback(TFallbackKind.call, '988');
      await _drain(tester);
    });
  });

  group('reporting', () {
    testWidgets('a clipboard error reports a code and keeps the card', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') throw PlatformException(code: _canary);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      await tester.tap(find.byKey(_copy));
      await _settle(tester);
      expect(_codes, [TCallFallback.shownCode, TCallFallback.clipboardErrorCode]);
      _expectReported(tester, TCallFallback.clipboardErrorCode);
      expect(find.text(TCallFallbackCopy.copied), findsNothing);
      _expectFallback(TFallbackKind.call, '988');
      await _drain(tester);
    });

    testWidgets('the default reporter drops the informational shown code: a fallback raises no error', (tester) async {
      TNav.reporter = TNav.reportToFlutterError;
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      _expectFallback(TFallbackKind.call, '988');
      expect(tester.takeException(), isNull);
      expect(TNav.errorCodes, isNot(contains(TCallFallback.shownCode)));
      await _drain(tester);
    });

    testWidgets('the default reporter forwards a failure once: a throwing platform raises only platform_error', (tester) async {
      TNav.reporter = TNav.reportToFlutterError;
      TPlatform.instance = _ScriptedPlatform(() => throw StateError(_canary));
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      _expectFallback(TFallbackKind.call, '988');
      final error = tester.takeException();
      expect(error, isA<TUiError>());
      expect((error as TUiError).code, TNav.platformErrorCode);
      expect(error.toString(), isNot(contains(_canary)));
      await _drain(tester);
    });

    test('every error code is forwarded by the default reporter', () {
      expect(TNav.errorCodes, {TNav.platformErrorCode, TNav.platformTimeoutCode, TCallFallback.clipboardErrorCode, TNav.safetyActionErrorCode, TNav.fallbackUnavailableCode});
    });

    test('an installed reporter gets the stack trace unchanged', () {
      final stacks = <StackTrace?>[];
      TNav.reporter = (_, stack) => stacks.add(stack);
      final stack = StackTrace.current;
      TNav.report(TNav.platformErrorCode, stack);
      TNav.report(TCallFallback.shownCode);
      expect(stacks, hasLength(2));
      expect(identical(stacks.first, stack), isTrue);
      expect(stacks.last, isNull);
    });

    testWidgets('the default reporter sends a TUiError with the code only to FlutterError', (tester) async {
      TNav.reporter = TNav.reportToFlutterError;
      TNav.report(TNav.platformErrorCode, StackTrace.current);
      final error = tester.takeException();
      expect(error, isA<TUiError>());
      expect((error as TUiError).code, TNav.platformErrorCode);
      expect(error.toString(), 'TUiError(platform_error)');
    });

    testWidgets('a reporter that throws does not stop the fallback', (tester) async {
      TNav.reporter = (_, __) => throw StateError('synthetic');
      TPlatform.instance = _ScriptedPlatform(() => throw StateError(_canary));
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      _expectFallback(TFallbackKind.call, '988');
      await _drain(tester);
    });
  });

  group('the keyboard and rebuilds', () {
    testWidgets('hw_log2: a keyboard that opens while the card shows moves the card and the screen above it; Save stays reachable above the card', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.hwLog2);
      final field = find.byKey(const ValueKey('field:hw_log2.systolic'));
      await TNav.call(tester.element(field), '988');
      await _settle(tester);
      _expectFallback(TFallbackKind.call, '988');
      final before = TCallFallback.inset.value;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      addTearDown(tester.view.resetViewInsets);
      await _settle(tester);
      final card = tester.getRect(find.byKey(_fallback));
      expect(card.bottom, lessThanOrEqualTo(844 - 300), reason: 'the card sits above the keyboard');
      expect(TCallFallback.inset.value, greaterThanOrEqualTo(844 - card.top), reason: 'inset $before → ${TCallFallback.inset.value}');
      final save = find.byKey(const ValueKey('a:footer[0]'));
      await tester.ensureVisible(save);
      await _settle(tester);
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(card.top), reason: 'Save is above the card');
      tester.view.resetViewInsets();
      await _settle(tester);
      expect(TCallFallback.inset.value, before, reason: 'the inset follows the keyboard back down');
      await _drain(tester);
    });

    testWidgets('a rebuilt app (new MaterialApp) leaves no inset, listener or fallback behind', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      _expectFallback(TFallbackKind.call, '988');
      expect(TCallFallback.inset.value, greaterThan(0));
      await _open(tester, route: Routes.crisis); // a new MaterialApp key
      _expectNoFallback();
      expect(TCallFallback.inset.value, 0);
      expect(TCallFallback.debugListensToSession, isFalse);
      final scaffold = find.descendant(of: find.byType(CrisisScreen), matching: find.byType(Scaffold));
      expect(MediaQuery.viewInsetsOf(tester.element(scaffold)).bottom, 0, reason: 'the screen is laid out full height');
      await _drain(tester);
    });
  });

  group('fields and focus', () {
    // (name, route, field key, size, text scale)
    final cases = <(String, String, String, Size, double)>[
      ('screen 390×844 at 1.0', Routes.supportMessageCare, 'support_message_care.message', const Size(390, 844), 1),
      ('screen 320×568 at 2.0 (footer moves into the body)', Routes.supportMessageCare, 'support_message_care.message', const Size(320, 568), 2),
      ('sheet 390×844 at 1.0', Routes.sfUnplugSessionEnd, 'sf_unplug_session_end.note', const Size(390, 844), 1),
      ('sheet 320×568 at 2.0', Routes.sfUnplugSessionEnd, 'sf_unplug_session_end.note', const Size(320, 568), 2),
    ];
    for (final (name, route, key, size, scale) in cases) {
      testWidgets('$name: a focused field keeps its state and text while the card shows, and gets focus back on Close', (tester) async {
        TDefaults.forRelease();
        await _open(tester, route: route, size: size, textScale: scale);
        final field = find.byKey(ValueKey('field:$key'));
        await tester.ensureVisible(field);
        await _settle(tester);
        await tester.enterText(field, 'synthetic note 01');
        await _settle(tester);
        EditableTextState editable() => tester.state<EditableTextState>(find.descendant(of: field, matching: find.byType(EditableText)));
        State tfield() => tester.state(find.ancestor(of: find.byType(EditableText), matching: find.byType(TField)).first);
        final editState = editable();
        final fieldState = tfield();
        expect(editState.widget.focusNode.hasFocus, isTrue);
        await TNav.call(tester.element(field), '988');
        await _settle(tester);
        _expectFallback(TFallbackKind.call, '988');
        expect(identical(editable(), editState) && identical(tfield(), fieldState), isTrue, reason: 'no state recreated when the card shows');
        expect(editable().textEditingValue.text, 'synthetic note 01');
        expect(editState.widget.focusNode.hasFocus, isFalse, reason: 'the card took focus');
        await tester.tap(find.byKey(_close));
        await _settle(tester);
        _expectNoFallback();
        expect(identical(editable(), editState) && identical(tfield(), fieldState), isTrue, reason: 'no state recreated when it closes');
        expect(editable().textEditingValue.text, 'synthetic note 01');
        expect(TSession.values[key], 'synthetic note 01');
        expect(editState.widget.focusNode.hasFocus, isTrue, reason: 'focus is back in the field');
        await _drain(tester);
      });
    }

    final closes = <String, Future<void> Function(WidgetTester)>{
      'the keyboard (Tab to Close, Enter)': (tester) async {
        for (var i = 0; i < 8; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final p = FocusManager.instance.primaryFocus?.context;
          if (p != null && find.ancestor(of: find.byElementPredicate((e) => identical(e, p)), matching: find.byKey(_close)).evaluate().isNotEmpty) break;
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      },
      'a screen-reader activation': (tester) async {
        final node = tester.getSemantics(find.descendant(of: find.byKey(_fallback), matching: find.bySemanticsLabel(TCallFallbackCopy.close)));
        node.owner!.performAction(node.id, SemanticsAction.tap);
      },
      'Copy, then Close': (tester) async {
        await tester.tap(find.byKey(_copy));
        await _settle(tester);
        await tester.tap(find.byKey(_close));
      },
    };
    for (final MapEntry(key: how, value: close) in closes.entries) {
      testWidgets('closed with $how: focus is back in the field', (tester) async {
        final semantics = tester.ensureSemantics();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
        addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
        TDefaults.forRelease();
        await _open(tester, route: Routes.supportMessageCare);
        final field = find.byKey(const ValueKey('field:support_message_care.message'));
        await tester.enterText(field, 'synthetic note 01');
        await _settle(tester);
        final node = tester.state<EditableTextState>(find.descendant(of: field, matching: find.byType(EditableText))).widget.focusNode;
        await TNav.call(tester.element(field), '988');
        await _settle(tester);
        await close(tester);
        await _settle(tester);
        _expectNoFallback();
        expect(node.hasFocus, isTrue);
        await _drain(tester);
        semantics.dispose();
      });
    }
  });

  group('a sheet stays usable', () {
    setUpAll(_loadRoboto);
    for (final (id, route) in [('rescue_pick', Routes.rescuePick), ('auth_signin', Routes.authSignin), ('auth_signin_error', Routes.authSigninError), ('support_callback', Routes.supportCallback), ('sf_unplug_session_end', Routes.sfUnplugSessionEnd)]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$id at ${scale == 1 ? 100 : 200}% on 320×568: every action can be scrolled to and tapped above the card', (tester) async {
          TDefaults.forRelease();
          await _open(tester, size: const Size(320, 568), textScale: scale);
          unawaited(TNav.sheet(_hostContext, route));
          await _settle(tester);
          final keys = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('a:')).evaluate().map((e) => (e.widget.key! as ValueKey<String>).value).toSet().toList();
          expect(keys, isNotEmpty);
          await TNav.call(tester.element(find.byKey(ValueKey(keys.first))), '988');
          await _settle(tester);
          _expectFallback(TFallbackKind.call, '988');
          final card = tester.getRect(find.byKey(_fallback));
          for (final k in keys) {
            final f = find.byKey(ValueKey(k));
            await tester.ensureVisible(f);
            await _settle(tester);
            expect(f.hitTestable(), findsOneWidget, reason: '$k is reachable');
            expect(tester.getRect(f).top, lessThan(card.top), reason: '$k is above the card');
          }
          await _drain(tester);
        });
      }
    }
  });

  group('a cut message', () {
    setUpAll(_loadRoboto);
    const top = ValueKey('call_fallback.fade_top'), bottom = ValueKey('call_fallback.fade_bottom');
    Finder scrollbar() => find.descendant(of: find.byKey(_fallback), matching: find.byWidgetPredicate((w) => w is Scrollbar && w.thumbVisibility == true));

    testWidgets('at 200% on 320×568 it fades at the cut edge and keeps its scrollbar visible; scrolled to the end, the fade moves to the top', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis, size: const Size(320, 568), textScale: 2);
      await _tapKey(tester, 'body[1]');
      expect(find.byKey(bottom), findsOneWidget);
      expect(find.byKey(top), findsNothing);
      expect(scrollbar(), findsOneWidget);
      final scrollable = find.descendant(of: find.byKey(_fallback), matching: find.byType(Scrollable));
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0), reason: 'the message is cut');
      position.jumpTo(position.maxScrollExtent);
      await _settle(tester);
      expect(find.byKey(top), findsOneWidget);
      expect(find.byKey(bottom), findsNothing);
      _expectFallback(TFallbackKind.call, '988');
      await _drain(tester);
    });

    testWidgets('when the whole message fits there is no fade', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.crisis);
      await _tapKey(tester, 'body[1]');
      expect(find.byKey(top), findsNothing);
      expect(find.byKey(bottom), findsNothing);
      final position = tester.state<ScrollableState>(find.descendant(of: find.byKey(_fallback), matching: find.byType(Scrollable))).position;
      expect(position.maxScrollExtent, 0);
      await _drain(tester);
    });
  });

  group('a safety action that throws', () {
    late _EachCallApi api;
    setUp(() {
      api = _EachCallApi();
      TApi.instance = api;
    });

    void selfHarmValue() => TSession.set('ea_mood.going_on', ['Thoughts of harming myself']);

    testWidgets('after opening the safety screen: the save is still sent, the safety screen stays, then does not run, a code is reported', (tester) async {
      await _open(tester);
      selfHarmValue();
      var thenRan = 0;
      final safety = TSafetyRoutes('ea.selfharm', {
        'Yes': () {
          TNav.push(_hostContext, Routes.crisis);
          throw StateError(_canary);
        },
      });
      final done = TNav.submit(_hostContext, 'POST /x', screenId: 's', then: () => thenRan++, safety: safety);
      await _settle(tester);
      expect(api.gates, hasLength(1), reason: 'the save is sent');
      _expectReported(tester, TNav.safetyActionErrorCode);
      expect(find.byType(CrisisScreen), findsOneWidget);
      api.gates.single.complete(const TResult.ok());
      expect(await done, const TResult.ok());
      await _settle(tester);
      expect(thenRan, 0);
      expect(find.byType(CrisisScreen), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('before opening anything, always throwing: the save is still sent, the rule is tried again on failure, and the save error shows', (tester) async {
      await _open(tester);
      selfHarmValue();
      final done = TNav.submit(_hostContext, 'POST /x', screenId: 's', safety: TSafetyRoutes('ea.selfharm', {'Yes': () => throw StateError(_canary)}));
      await _settle(tester);
      expect(api.gates, hasLength(1), reason: 'the save is sent');
      expect(_codes, [TNav.safetyActionErrorCode]);
      api.gates.single.complete(const TResult.failed('synthetic_code'));
      expect(await done, const TResult.failed('synthetic_code'));
      await tester.pump();
      expect(_codes, [TNav.safetyActionErrorCode, TNav.safetyActionErrorCode], reason: 'nothing opened, so the completion check ran the action again');
      expect(find.text('Couldn’t save. Your entry is kept on this phone.'), findsOneWidget);
      expect(find.textContaining(_canary), findsNothing);
      await _drain(tester);
    });

    // An action that throws on its first run, before navigating, and pushes
    // the crisis screen on later runs. [then] is the generated form: a branch
    // decided by the same rule, whose case runs the same action.
    (VoidCallback, int Function()) throwOnceThenPush() {
      var runs = 0;
      void action() {
        runs++;
        if (runs == 1) throw StateError(_canary);
        TNav.push(_hostContext, Routes.crisis);
      }

      return (action, () => runs);
    }

    for (final (how, result) in <(String, TResult)>[('succeeds', const TResult.ok()), ('fails', const TResult.failed('synthetic_code'))]) {
      testWidgets('throws before navigating, the save $how while the screen is on top: the safety screen opens once', (tester) async {
        await _open(tester);
        selfHarmValue();
        final (action, runs) = throwOnceThenPush();
        final then = () => TNav.branch(_hostContext, 'Q', {'Yes': action, 'No': () {}}, decide: 'ea.selfharm');
        final done = TNav.submit(_hostContext, 'POST /x', screenId: 's', then: then, safety: TSafetyRoutes('ea.selfharm', {'Yes': action}));
        await _settle(tester);
        expect(api.gates, hasLength(1));
        expect(find.byType(CrisisScreen), findsNothing);
        _expectReported(tester, TNav.safetyActionErrorCode);
        api.gates.single.complete(result);
        await done;
        await _settle(tester);
        expect(find.byType(CrisisScreen), findsOneWidget);
        expect(runs(), 2);
        await _drain(tester);
      });
    }

    testWidgets('throws after pushing, the save fails: no second safety screen', (tester) async {
      await _open(tester);
      selfHarmValue();
      var runs = 0;
      final safety = TSafetyRoutes('ea.selfharm', {
        'Yes': () {
          runs++;
          TNav.push(_hostContext, Routes.crisis);
          throw StateError(_canary);
        },
      });
      final done = TNav.submit(_hostContext, 'POST /x', screenId: 's', safety: safety);
      await _settle(tester);
      api.gates.single.complete(const TResult.failed('synthetic_code'));
      await done;
      await _settle(tester);
      expect(runs, 1);
      expect(find.byType(CrisisScreen, skipOffstage: false), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('a safety action that calls through a throwing platform: the save is sent and the fallback shows the number', (tester) async {
      TPlatform.instance = _ScriptedPlatform(() => throw StateError(_canary));
      await _open(tester);
      selfHarmValue();
      unawaited(TNav.submit(_hostContext, 'POST /x', screenId: 's', safety: TSafetyRoutes('ea.selfharm', {'Yes': () => TNav.call(_hostContext, '988')})));
      await _settle(tester);
      expect(api.gates, hasLength(1), reason: 'the save is sent');
      _expectReported(tester, TNav.platformErrorCode);
      _expectFallback(TFallbackKind.call, '988');
      api.gates.single.complete(const TResult.ok());
      await _drain(tester);
    });

    testWidgets('on an ignored activation during the save: nothing is thrown, no second save', (tester) async {
      await _open(tester);
      final safety = TSafetyRoutes('ea.selfharm', {'Yes': () => throw StateError(_canary)});
      unawaited(TNav.submit(_hostContext, 'POST /x', screenId: 's', safety: safety)); // no safety value yet
      await _settle(tester);
      selfHarmValue();
      expect(await TNav.submit(_hostContext, 'POST /x', screenId: 's', safety: safety), isNull);
      _expectReported(tester, TNav.safetyActionErrorCode);
      expect(api.gates, hasLength(1));
      api.gates.single.complete(const TResult.ok());
      await _drain(tester);
    });
  });

  group('a keyboard that leaves little room', () {
    setUpAll(_loadRoboto);
    // (size, text scale, keyboard height)
    final cases = <(Size, double, double)>[
      (const Size(320, 568), 1, 260),
      (const Size(320, 568), 2, 260),
      (const Size(390, 844), 2, 300),
    ];
    for (final (size, scale, keyboard) in cases) {
      testWidgets('crisis · Call 988 on ${size.width.toInt()}×${size.height.toInt()} at ${(scale * 100).round()}% with a ${keyboard.toInt()} pt keyboard: nothing overflows, the number shows whole, Copy and Close are fully tappable', (tester) async {
        TDefaults.forRelease();
        await _open(tester, route: Routes.crisis, size: size, textScale: scale);
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
        addTearDown(tester.view.resetViewInsets);
        await _settle(tester);
        await _tapKey(tester, 'body[1]');
        expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow in the card');
        _expectFallback(TFallbackKind.call, '988');
        final above = Offset.zero & Size(size.width, size.height - keyboard);
        final card = tester.getRect(find.byKey(_fallback));
        expect(above.contains(card.topLeft) && above.contains(card.bottomRight - const Offset(0.01, 0.01)), isTrue, reason: 'the card $card is on screen above the keyboard');
        for (final key in [_number, _copy, _close]) {
          final r = tester.getRect(find.byKey(key));
          expect(r.height, greaterThan(0), reason: '$key');
          expect(card.contains(r.topLeft) && card.contains(r.bottomRight - const Offset(0.01, 0.01)), isTrue, reason: '$key at $r is inside the card $card');
        }
        for (final key in [_copy, _close]) {
          _expectFullyHitTestable(tester, find.byKey(key));
        }
        expect(tester.getSemantics(find.byKey(_fallback)).label, contains(TCallFallbackCopy.message(TFallbackKind.call, '988')), reason: 'the message is still read');
        await tester.tap(find.byKey(_close));
        await _settle(tester);
        _expectNoFallback();
        await _drain(tester); // an overflow would be a reported exception
      });
    }
  });

  group('focus after Close', () {
    setUpAll(_loadRoboto); // as in the other 200% groups
    // (screen, route, action path, where the button is, kind, value)
    final cases = <(String, String, String, String, TFallbackKind, String)>[
      ('re_symptoms', Routes.reSymptoms, 'footer[1]', 'screen footer', TFallbackKind.call, '911'),
      ('support_message', Routes.supportMessage, 'footer[0]', 'sheet footer', TFallbackKind.sms, 'Jordan'),
      ('crisis', Routes.crisis, 'body[1]', 'body', TFallbackKind.call, '988'),
    ];
    final sizes = <(Size, double)>[(const Size(390, 844), 1), (const Size(320, 568), 2)];
    final closes = <String, Future<void> Function(WidgetTester)>{
      'Tab to Close, Enter': (tester) async {
        expect(await _tabTo(tester, find.byKey(_close), 8), isTrue, reason: 'Tab reaches Close');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      },
      'a tap on Close': (tester) => tester.tap(find.byKey(_close)),
    };
    for (final (sid, route, path, where, kind, value) in cases) {
      for (final (size, scale) in sizes) {
        for (final MapEntry(key: how, value: close) in closes.entries) {
          testWidgets('$sid · $path ($where) on ${size.width.toInt()}×${size.height.toInt()} at ${(scale * 100).round()}%: Tab to it, Enter, $how: focus is back on it', (tester) async {
            TDefaults.forRelease();
            await _open(tester, route: route, size: size, textScale: scale);
            final button = find.byKey(ValueKey('a:$path'));
            expect(await _tabTo(tester, button, 60), isTrue, reason: 'Tab reaches $path');
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await _settle(tester);
            _expectFallback(kind, value);
            final focused = FocusManager.instance.primaryFocus?.context;
            expect(focused != null && find.descendant(of: find.byElementPredicate((e) => identical(e, focused)), matching: find.byKey(_fallback)).evaluate().isNotEmpty, isTrue, reason: 'the card took focus');
            if (where.endsWith('footer')) {
              expect(find.ancestor(of: button, matching: find.byType(SingleChildScrollView)), findsOneWidget, reason: 'the footer moved into the scrolling body');
            }
            await close(tester);
            await _settle(tester);
            _expectNoFallback();
            expect(_hasFocus(button), isTrue, reason: 'focus is back on $path');
            await _drain(tester);
          });
        }
      }
    }
  });

  group('a fallback that replaces another', () {
    testWidgets('support_message: the screen stays laid out above a card the whole time (the inset never drops to 0), and the footer keeps its element', (tester) async {
      TDefaults.forRelease();
      await _open(tester, route: Routes.supportMessage);
      await _tapKey(tester, 'footer[0]');
      _expectFallback(TFallbackKind.sms, 'Jordan');
      final footer = find.byKey(const ValueKey('a:footer[0]'));
      final element = footer.evaluate().single;
      final insets = <double>[];
      void record() => insets.add(TCallFallback.inset.value);
      TCallFallback.inset.addListener(record);
      addTearDown(() => TCallFallback.inset.removeListener(record));
      await TNav.call(tester.element(footer), '988');
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(TCallFallback.inset.value, greaterThan(0), reason: 'frame $i');
      }
      _expectFallback(TFallbackKind.call, '988');
      expect(insets, isNot(contains(0)), reason: 'insets $insets');
      expect(identical(footer.evaluate().single, element), isTrue, reason: 'the footer kept its element');
      TCallFallback.dismiss();
      expect(TCallFallback.inset.value, 0);
      await _drain(tester);
    });
  });
}

/// Presses Tab up to [max] times until the primary focus is inside [target].
Future<bool> _tabTo(WidgetTester tester, Finder target, int max) async {
  for (var i = 0; i < max; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (_hasFocus(target)) {
      await _settle(tester); // let a scroll into view finish
      return true;
    }
  }
  return false;
}

/// The primary focus is [target] or inside it.
bool _hasFocus(Finder target) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final targets = target.evaluate().toSet();
  var found = false;
  if (targets.contains(focused)) return true;
  focused.visitAncestorElements((e) {
    found = targets.contains(e);
    return !found;
  });
  return found;
}

/// The topmost hit at the middle of every edge (1 px in), at every corner
/// (inside the rounded corner) and at the centre of [finder] is [finder] or
/// inside it, so no part of it is covered or cut off.
void _expectFullyHitTestable(WidgetTester tester, Finder finder) {
  final edges = tester.getRect(finder).deflate(1);
  final corners = tester.getRect(finder).deflate(12);
  final target = tester.renderObject(finder);
  for (final p in [edges.topCenter, edges.bottomCenter, edges.centerLeft, edges.centerRight, corners.topLeft, corners.topRight, corners.bottomLeft, corners.bottomRight, edges.center]) {
    final result = HitTestResult();
    tester.binding.hitTestInView(result, p, tester.view.viewId);
    final first = result.path.map((e) => e.target).whereType<RenderObject>().firstOrNull; // a TextSpan is not a RenderObject
    var inside = false;
    for (RenderObject? o = first; o != null && !inside; o = o.parent) {
      inside = identical(o, target);
    }
    expect(inside, isTrue, reason: '$finder is hit at $p (topmost: $first)');
  }
}
