// A submit's delayed result acts only on the screen that submitted it, and a
// safety action always opens its safety screen on top without dismissing a
// screen the member opened (TNav.submit, TNav.replace).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/ca/ca_red_screen.dart';
import 'package:tether_ui/screens/ea/ea_mood_screen.dart';
import 'package:tether_ui/screens/hw/hw_crisis_screen.dart';
import 'package:tether_ui/screens/records/records_manual_error_screen.dart';
import 'package:tether_ui/screens/rescue/crisis_screen.dart';
import 'package:tether_ui/screens/rescue/rescue_active_screen.dart';
import 'package:tether_ui/screens/st/st_low_screen.dart';
import 'package:tether_ui/screens/tabs/support_message_care_screen.dart';
import 'package:tether_ui/ui/ui.dart';

const _host = '/__host';
const _saveError = 'Couldn’t save. Your entry is kept on this phone.';

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

/// Every navigator event, in order: "push <name>", "pop <name>",
/// "remove <name>" and "replace <old> -> <new>".
class _NavLog extends NavigatorObserver {
  final List<String> events = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('push ${route.settings.name}');
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('pop ${route.settings.name}');
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('remove ${route.settings.name}');
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => events.add('replace ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');

  /// Events that took [name] off the screen: a pop, a remove, or a replace
  /// of it.
  List<String> dismissed(String name) => events.where((e) => e == 'pop $name' || e == 'remove $name' || e.startsWith('replace $name -> ')).toList();

  /// Events that opened [name]: a push of it or a replace by it.
  int opened(String name) => events.where((e) => e == 'push $name' || (e.startsWith('replace ') && e.endsWith(' -> $name'))).length;
}

late BuildContext _hostContext;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Opens [route] (when given) above a bare host screen.
Future<void> _open(WidgetTester tester, _NavLog log, {String? route}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  Widget hostPage(BuildContext c) {
    _hostContext = c;
    return const Scaffold();
  }

  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    navigatorObservers: [log],
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
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester);
}

Future<void> _selfHarm(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Thoughts of harming myself'));
  await tester.tap(find.text('Thoughts of harming myself'), warnIfMissed: false);
  await _settle(tester);
}

/// Two frames: a toast inserted when a save completes is built by the
/// second frame at the latest.
Future<void> _nextFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Whether the screen of type [type] is the navigator's top route.
bool _onTop(WidgetTester tester, Type type) => ModalRoute.of(tester.element(find.byType(type)))!.isCurrent;

/// Ends the test after the toasts have gone.
Future<void> _drain(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pump(const Duration(seconds: 3));
}

/// How a pending save finishes.
typedef _Finish = Future<void> Function(WidgetTester tester, Completer<TResult> gate);

final _successes = <(String, _Finish)>[
  ('ok', (t, g) async => g.complete(const TResult.ok())),
  ('queued', (t, g) async => g.complete(const TResult.queued())),
  ('outcome', (t, g) async => g.complete(const TResult.outcome('No'))),
];

final _failures = <(String, _Finish)>[
  ('failed', (t, g) async => g.complete(const TResult.failed('synthetic_code'))),
  ('adapter_error', (t, g) async => g.completeError(Exception('synthetic'))),
  ('timeout', (t, g) => t.pump(const Duration(seconds: 30))), // submitTimeout passes during this pump
];

void main() {
  late _EachCallApi api;
  late _NavLog log;

  setUp(() {
    TSession.clear();
    TFlow.onboarding = false;
    api = _EachCallApi();
    TApi.instance = api;
    log = _NavLog();
  });
  tearDown(() {
    TDefaults.forPreview();
    TNav.submitTimeout = const Duration(seconds: 30);
    TSession.clear();
  });

  group('a delayed result does not act on another screen', () {
    for (final (how, finish) in [..._successes, ..._failures]) {
      testWidgets('support_message_care: a slow send that ends ($how) after the member opens the crisis screen leaves the crisis screen in place', (tester) async {
        await _open(tester, log, route: Routes.supportMessageCare);
        await _tapKey(tester, 'footer[0]'); // Send message: the save is in flight
        expect(api.gates, hasLength(1));
        await _tapKey(tester, 'body[4].actions[0]'); // Call or text 988
        expect(find.byType(CrisisScreen), findsOneWidget);
        await finish(tester, api.gates.single);
        await _settle(tester);
        expect(find.byType(CrisisScreen), findsOneWidget);
        expect(_onTop(tester, CrisisScreen), isTrue);
        expect(log.dismissed(Routes.crisis), isEmpty);
        expect(log.dismissed(Routes.supportMessageCare), isEmpty);
        expect(find.byType(SupportMessageCareScreen, skipOffstage: false), findsOneWidget);
        expect(find.text('Message sent'), findsNothing);
        expect(find.text(_saveError), findsNothing, reason: 'a save error over the crisis screen would read as its result');
        await _drain(tester);
      });

      testWidgets('ea_mood: a slow "No" save that ends ($how) after the member starts the breathing exercise leaves the exercise in place', (tester) async {
        await _open(tester, log, route: Routes.eaMood);
        await _tapKey(tester, 'footer[0]'); // Save with "No": the save is in flight
        expect(api.gates, hasLength(1));
        await _tapKey(tester, 'body[2].cta[0]'); // Start the grounding exercise
        expect(find.byType(RescueActiveScreen), findsOneWidget);
        await finish(tester, api.gates.single);
        await _settle(tester);
        expect(find.byType(RescueActiveScreen), findsOneWidget);
        expect(_onTop(tester, RescueActiveScreen), isTrue);
        expect(log.dismissed(Routes.rescueActive), isEmpty);
        expect(log.dismissed(Routes.eaMood), isEmpty);
        expect(find.byType(CrisisScreen, skipOffstage: false), findsNothing);
        expect(find.text('Saved'), findsNothing);
        expect(find.text(_saveError), findsNothing);
        await _drain(tester);
      });
    }

    for (final (how, finish) in [..._successes, ..._failures]) {
      testWidgets('two ea_mood instances: the lower instance’s late result ($how) does not replace the crisis screen the upper one opened', (tester) async {
        await _open(tester, log);
        unawaited(Navigator.of(_hostContext).pushNamed(Routes.eaMood));
        await _settle(tester);
        await _tapKey(tester, 'footer[0]'); // lower instance: "No", the save is in flight
        unawaited(Navigator.of(_hostContext).pushNamed(Routes.eaMood));
        await _settle(tester);
        expect(find.byType(EaMoodScreen, skipOffstage: false), findsNWidgets(2));
        await _selfHarm(tester); // the shared session value now decides "Yes"
        await _tapKey(tester, 'footer[0]'); // upper instance: the crisis screen opens at once
        expect(api.gates, hasLength(2));
        expect(find.byType(CrisisScreen), findsOneWidget);
        expect(log.opened(Routes.crisis), 1);
        await finish(tester, api.gates.first);
        await _settle(tester);
        if (!api.gates.last.isCompleted) api.gates.last.complete(const TResult.ok());
        await _settle(tester);
        expect(find.byType(CrisisScreen, skipOffstage: false), findsOneWidget);
        expect(_onTop(tester, CrisisScreen), isTrue);
        expect(log.opened(Routes.crisis), 1, reason: 'the crisis screen is not opened again');
        expect(log.dismissed(Routes.crisis), isEmpty);
        expect(find.text('Saved'), findsNothing);
        expect(find.text(_saveError), findsNothing);
        await _drain(tester);
      });
    }

    testWidgets('back on the submitting screen before the save ends: then runs as usual', (tester) async {
      await _open(tester, log, route: Routes.supportMessageCare);
      await _tapKey(tester, 'footer[0]');
      await _tapKey(tester, 'body[4].actions[0]'); // Call or text 988
      await tester.binding.handlePopRoute(); // the member closes the crisis screen
      await _settle(tester);
      expect(_onTop(tester, SupportMessageCareScreen), isTrue);
      api.gates.single.complete(const TResult.ok());
      await _nextFrames(tester);
      expect(find.text('Message sent'), findsOneWidget);
      await _settle(tester);
      expect(find.byType(SupportMessageCareScreen), findsNothing);
      expect(log.events.last, 'pop ${Routes.supportMessageCare}');
      await _drain(tester);
    });
  });

  group('on top, a delayed result runs then as before', () {
    testWidgets('support_message_care: a slow send that succeeds shows the toast and goes back', (tester) async {
      await _open(tester, log, route: Routes.supportMessageCare);
      await _tapKey(tester, 'footer[0]');
      expect(find.byType(SupportMessageCareScreen), findsOneWidget);
      api.gates.single.complete(const TResult.ok());
      await _nextFrames(tester);
      expect(find.text('Message sent'), findsOneWidget);
      await _settle(tester);
      expect(find.byType(SupportMessageCareScreen), findsNothing);
      expect(log.events.last, 'pop ${Routes.supportMessageCare}');
      await _drain(tester);
    });

    testWidgets('records_manual: a slow save that succeeds follows the branch to its screen', (tester) async {
      await _open(tester, log, route: Routes.recordsManual);
      await tester.enterText(find.byKey(const ValueKey('field:records_manual.value')), '99'); // outside 3–20
      await _settle(tester);
      await _tapKey(tester, 'footer[0]');
      expect(find.byType(RecordsManualErrorScreen), findsNothing);
      api.gates.single.complete(const TResult.ok());
      await _settle(tester);
      expect(find.byType(RecordsManualErrorScreen), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('a slow save that fails shows the save error on the screen', (tester) async {
      await _open(tester, log, route: Routes.supportMessageCare);
      await _tapKey(tester, 'footer[0]');
      api.gates.single.complete(const TResult.failed('synthetic_code'));
      await _nextFrames(tester);
      expect(find.text(_saveError), findsOneWidget);
      expect(find.byType(SupportMessageCareScreen), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('a safety value at the tap still replaces the screen with the crisis screen at once', (tester) async {
      await _open(tester, log, route: Routes.eaMood);
      await _selfHarm(tester);
      await tester.tap(find.byKey(const ValueKey('a:footer[0]')), warnIfMissed: false);
      await tester.pump(); // one frame: no waiting for the save
      expect(log.events.last, 'replace ${Routes.eaMood} -> ${Routes.crisis}');
      await _settle(tester);
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(find.byType(EaMoodScreen, skipOffstage: false), findsNothing);
      api.gates.single.complete(const TResult.ok());
      await _settle(tester);
      expect(log.opened(Routes.crisis), 1);
      await _drain(tester);
    });
  });

  group('a safety action when the submitting screen is not on top', () {
    for (final (how, finish) in _failures) {
      testWidgets('the save ends ($how) after the member chose a safety value and opened the breathing exercise: the crisis screen opens on top with the save error, nothing is dismissed', (tester) async {
        await _open(tester, log, route: Routes.eaMood);
        await _tapKey(tester, 'footer[0]'); // "No": the save is in flight
        await _selfHarm(tester); // chosen after the tap, not saved
        await _tapKey(tester, 'body[2].cta[0]'); // Start the grounding exercise
        expect(find.byType(CrisisScreen, skipOffstage: false), findsNothing);
        final before = log.events.length;
        await finish(tester, api.gates.single);
        await _settle(tester);
        expect(find.byType(CrisisScreen), findsOneWidget);
        expect(_onTop(tester, CrisisScreen), isTrue);
        expect(log.events.sublist(before), ['push ${Routes.crisis}']);
        expect(find.byType(RescueActiveScreen, skipOffstage: false), findsOneWidget);
        expect(find.byType(EaMoodScreen, skipOffstage: false), findsOneWidget);
        expect(log.dismissed(Routes.rescueActive), isEmpty);
        expect(log.dismissed(Routes.eaMood), isEmpty);
        expect(find.text(_saveError), findsOneWidget, reason: 'shown with the safety screen this submit opened');
        await _drain(tester);
      });
    }

    for (final (how, finish) in _successes) {
      testWidgets('the save ends ($how) after the member chose a safety value and opened the breathing exercise: the crisis screen opens on top, nothing is dismissed', (tester) async {
        await _open(tester, log, route: Routes.eaMood);
        await _tapKey(tester, 'footer[0]'); // "No": the save is in flight
        await _selfHarm(tester); // chosen after the tap
        await _tapKey(tester, 'body[2].cta[0]'); // Start the grounding exercise
        expect(find.byType(CrisisScreen, skipOffstage: false), findsNothing);
        final before = log.events.length;
        await finish(tester, api.gates.single);
        await _settle(tester);
        expect(find.byType(CrisisScreen), findsOneWidget);
        expect(_onTop(tester, CrisisScreen), isTrue);
        expect(log.events.sublist(before), ['push ${Routes.crisis}']);
        expect(find.byType(RescueActiveScreen, skipOffstage: false), findsOneWidget);
        expect(find.byType(EaMoodScreen, skipOffstage: false), findsOneWidget);
        expect(log.dismissed(Routes.rescueActive), isEmpty);
        expect(log.dismissed(Routes.eaMood), isEmpty);
        expect(find.text('Saved'), findsNothing);
        expect(find.text(_saveError), findsNothing);
        await _drain(tester);
      });
    }

    Future<void> enter(WidgetTester tester, String key, String value) async {
      await tester.enterText(find.byKey(ValueKey('field:$key')), value);
      await _settle(tester);
    }

    // (screen, route, non-safety entry, safety entry, safety screen type and route)
    final edited = <(String, String, Future<void> Function(WidgetTester), Future<void> Function(WidgetTester), Type, String)>[
      ('hw_log2', Routes.hwLog2, (t) async {
        await enter(t, 'hw_log2.systolic', '132');
        await enter(t, 'hw_log2.diastolic', '84');
      }, (t) async {
        await enter(t, 'hw_log2.systolic', '186');
        await enter(t, 'hw_log2.diastolic', '122');
      }, HwCrisisScreen, Routes.hwCrisis),
      ('ca_zone', Routes.caZone, (t) => enter(t, 'ca_zone.peak_flow', '310'), (t) => enter(t, 'ca_zone.peak_flow', '150'), CaRedScreen, Routes.caRed),
      ('st_log', Routes.stLog, (t) => enter(t, 'st_log.reading', '142'), (t) => enter(t, 'st_log.reading', '62'), StLowScreen, Routes.stLow),
    ];

    for (final (sid, route, normal, unsafe, safetyType, safetyRoute) in edited) {
      testWidgets('$sid: a value edited to a safety value after the tap, then another screen opened, the save succeeds: the safety screen opens on top', (tester) async {
        await _open(tester, log, route: route);
        await normal(tester);
        await _tapKey(tester, 'footer[0]'); // not a safety value: the save is in flight
        expect(api.gates, hasLength(1));
        await unsafe(tester);
        unawaited(Navigator.of(_hostContext).pushNamed(Routes.rescueActive)); // the member opens another screen
        await _settle(tester);
        expect(find.byType(safetyType, skipOffstage: false), findsNothing);
        final before = log.events.length;
        api.gates.single.complete(const TResult.ok());
        await _settle(tester);
        expect(log.events.sublist(before), ['push $safetyRoute']);
        expect(_onTop(tester, safetyType), isTrue);
        expect(find.byType(RescueActiveScreen, skipOffstage: false), findsOneWidget);
        expect(log.dismissed(Routes.rescueActive), isEmpty);
        await _drain(tester);
      });
    }

    testWidgets('an activation that reaches the covered screen during the save: the crisis screen opens on top, once', (tester) async {
      await _open(tester, log, route: Routes.eaMood);
      await _tapKey(tester, 'footer[0]'); // "No": the save is in flight
      await _selfHarm(tester);
      await _tapKey(tester, 'body[2].cta[0]'); // Start the grounding exercise
      final save = tester.widget<TButton>(find.descendant(
        of: find.byType(EaMoodScreen, skipOffstage: false),
        matching: find.byKey(const ValueKey('a:footer[0]'), skipOffstage: false),
        skipOffstage: false,
      ));
      save.onPressed!(); // ignored by the in-flight guard, but the safety rule is checked
      await _settle(tester);
      expect(api.gates, hasLength(1), reason: 'no second save');
      expect(find.byType(CrisisScreen), findsOneWidget);
      expect(_onTop(tester, CrisisScreen), isTrue);
      expect(log.dismissed(Routes.rescueActive), isEmpty);
      expect(find.byType(RescueActiveScreen, skipOffstage: false), findsOneWidget);
      api.gates.single.complete(const TResult.ok());
      await _settle(tester);
      expect(log.opened(Routes.crisis), 1);
      expect(log.dismissed(Routes.crisis), isEmpty);
      expect(find.text('Saved'), findsNothing);
      await _drain(tester);
    });

    testWidgets('a failed save while the member already has the crisis screen open: no second crisis screen, nothing dismissed', (tester) async {
      await _open(tester, log, route: Routes.eaMood);
      await _tapKey(tester, 'footer[0]'); // "No": the save is in flight
      await _selfHarm(tester);
      unawaited(Navigator.of(tester.element(find.byType(EaMoodScreen))).pushNamed(Routes.crisis)); // the member opens the crisis screen
      await _settle(tester);
      api.gates.single.complete(const TResult.failed('synthetic_code'));
      await _settle(tester);
      expect(find.byType(CrisisScreen, skipOffstage: false), findsOneWidget);
      expect(_onTop(tester, CrisisScreen), isTrue);
      expect(log.opened(Routes.crisis), 1);
      expect(log.dismissed(Routes.crisis), isEmpty);
      expect(find.text(_saveError), findsNothing, reason: 'this submit opened no screen');
      await _drain(tester);
    });

    Future<void> rePickOverBreathing(WidgetTester tester) async {
      await _open(tester, log, route: Routes.eaMood);
      await _tapKey(tester, 'footer[0]'); // "No": the save is in flight
      await _selfHarm(tester);
      await _tapKey(tester, 'body[2].cta[0]'); // Start the grounding exercise
      tester.widget<TButton>(find.descendant(
        of: find.byType(EaMoodScreen, skipOffstage: false),
        matching: find.byKey(const ValueKey('a:footer[0]'), skipOffstage: false),
        skipOffstage: false,
      )).onPressed!();
      await _settle(tester);
      expect(_onTop(tester, CrisisScreen), isTrue);
    }

    testWidgets('after a safety action opened the crisis screen on top, a failed save shows the save error with it and navigates nowhere', (tester) async {
      await rePickOverBreathing(tester);
      final before = log.events.length;
      api.gates.single.complete(const TResult.failed('synthetic_code'));
      await _settle(tester);
      expect(find.text(_saveError), findsOneWidget);
      expect(log.events.length, before);
      expect(_onTop(tester, CrisisScreen), isTrue);
      await _drain(tester);
    });

    testWidgets('after a safety action opened the crisis screen, a failed save shows no save error over a screen the member opened from it', (tester) async {
      await rePickOverBreathing(tester);
      unawaited(Navigator.of(tester.element(find.byType(CrisisScreen))).pushNamed(Routes.supportMessageCare));
      await _settle(tester);
      final before = log.events.length;
      api.gates.single.complete(const TResult.failed('synthetic_code'));
      await _settle(tester);
      expect(find.text(_saveError), findsNothing);
      expect(log.events.length, before);
      expect(_onTop(tester, SupportMessageCareScreen), isTrue);
      await _drain(tester);
    });
  });

  group('a safety action that pushes', () {
    TSafetyRoutes pushCrisis() => TSafetyRoutes('ea.selfharm', {'Yes': () => TNav.push(_hostContext, Routes.crisis)});
    void selfHarmValue() => TSession.set('ea_mood.going_on', ['Thoughts of harming myself']);

    Future<void> cover(WidgetTester tester, String route) async {
      await _open(tester, log);
      unawaited(Navigator.of(_hostContext).pushNamed(route));
      await _settle(tester);
    }

    testWidgets('at the tap, from a covered screen whose top route already is the safety screen: opens nothing', (tester) async {
      await cover(tester, Routes.crisis);
      selfHarmValue();
      unawaited(TNav.submit(_hostContext, 'POST /x', screenId: 's', safety: pushCrisis()));
      await _settle(tester);
      expect(log.opened(Routes.crisis), 1);
      api.gates.single.complete(const TResult.ok());
      await _settle(tester);
      expect(log.opened(Routes.crisis), 1);
      await _drain(tester);
    });

    testWidgets('after a successful save, from a covered screen whose top route already is the safety screen: opens nothing', (tester) async {
      await cover(tester, Routes.crisis);
      unawaited(TNav.submit(_hostContext, 'POST /x', screenId: 's', safety: pushCrisis())); // no safety value yet
      await _settle(tester);
      selfHarmValue();
      api.gates.single.complete(const TResult.ok());
      await _settle(tester);
      expect(log.opened(Routes.crisis), 1);
      expect(log.dismissed(Routes.crisis), isEmpty);
      await _drain(tester);
    });

    testWidgets('after a successful save, from a covered screen under another screen: opens the safety screen on top', (tester) async {
      await cover(tester, Routes.rescueActive);
      unawaited(TNav.submit(_hostContext, 'POST /x', screenId: 's', safety: pushCrisis()));
      await _settle(tester);
      selfHarmValue();
      api.gates.single.complete(const TResult.ok());
      await _settle(tester);
      expect(log.events.last, 'push ${Routes.crisis}');
      expect(log.dismissed(Routes.rescueActive), isEmpty);
      await _drain(tester);
    });

    testWidgets('an ordinary push to the route already on top still opens it', (tester) async {
      await cover(tester, Routes.crisis);
      unawaited(TNav.push(_hostContext, Routes.crisis));
      await _settle(tester);
      expect(log.opened(Routes.crisis), 2);
      await _drain(tester);
    });
  });

  group('TNav.replace', () {
    late BuildContext lower;

    Future<void> openTwo(WidgetTester tester) async {
      await _open(tester, log);
      lower = _hostContext;
      unawaited(Navigator.of(_hostContext).pushNamed(Routes.rescueActive));
      await _settle(tester);
    }

    testWidgets('from the top screen: replaces it', (tester) async {
      await _open(tester, log, route: Routes.supportMessageCare);
      unawaited(TNav.replace(tester.element(find.byType(SupportMessageCareScreen)), Routes.crisis));
      await _settle(tester);
      expect(log.events.last, 'replace ${Routes.supportMessageCare} -> ${Routes.crisis}');
      expect(find.byType(SupportMessageCareScreen, skipOffstage: false), findsNothing);
      await _drain(tester);
    });

    testWidgets('from a covered screen: opens the route on top and removes nothing', (tester) async {
      await openTwo(tester);
      unawaited(TNav.replace(lower, Routes.crisis));
      await _settle(tester);
      expect(log.events.last, 'push ${Routes.crisis}');
      expect(_onTop(tester, CrisisScreen), isTrue);
      expect(log.dismissed(Routes.rescueActive), isEmpty);
      expect(log.dismissed(_host), isEmpty);
      await _drain(tester);
    });

    testWidgets('from a covered screen when the route is already on top: opens nothing', (tester) async {
      await openTwo(tester);
      final before = log.events.length;
      unawaited(TNav.replace(lower, Routes.rescueActive));
      await _settle(tester);
      expect(log.events.length, before);
      await _drain(tester);
    });
  });
}
