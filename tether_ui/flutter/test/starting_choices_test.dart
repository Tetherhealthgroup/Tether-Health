// Starting choices (P-52): the optional consents on ob_consent and the
// "I’m 18 or older" attestation on ob_account start unticked, so the member
// makes each choice. Pinned in the spec and in the generated screens, with
// the footer buttons behaving as the spec says while they are unticked. On
// ob_account no sign-up route proceeds until the item is ticked (P-72).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/auth/auth_merge_screen.dart';
import 'package:tether_ui/screens/auth/auth_verify_screen.dart';
import 'package:tether_ui/screens/onboarding/ob_account_screen.dart';
import 'package:tether_ui/screens/onboarding/ob_basics_screen.dart';
import 'package:tether_ui/screens/today/today_screen.dart';
import 'package:tether_ui/ui/ui.dart';

const _age = 'I’m 18 or older';

/// Shown when a sign-up route is tapped while [_age] is unticked (P-72).
const _ageMessage = 'You need to be 18 or older to continue.';

/// The sign-up routes on ob_account: element → (key, type of the action that
/// runs once the item is ticked).
const _routes = <String, (String, String)>{
  'Continue with Apple': ('a:body[2].items[0]', 'branch'),
  'Continue with Google': ('a:body[2].items[1]', 'branch'),
  'Create account': ('a:footer[0]', 'submit'),
  'Continue on this phone only': ('a:footer[1]', 'reset'),
};

/// Optional ob_consent toggles (label → session key). "Essential app data"
/// is required and is not one of them.
const _optional = <String, String>{
  'Private reminders': 'ob_consent.private_reminders',
  'Share summaries with my care team': 'ob_consent.share_summaries_with_my_care_tea',
  'Connect Screen Time': 'ob_consent.connect_screen_time',
  'De-identified research': 'ob_consent.de_identified_research',
};

/// Records each submit and lets it succeed.
class _Api implements TApi {
  final List<(String, String)> calls = [];
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async {
    calls.add((endpoint, screenId));
    return const TResult.ok();
  }
}

/// Records each native sign-in and lets it succeed.
class _Auth implements TAuth {
  final List<String> calls = [];
  @override
  Future<String?> signIn(String provider, List<String> outcomes) async {
    calls.add(provider);
    return 'Success';
  }
}

/// The navigator's stack of route names (top last).
class _Stack extends NavigatorObserver {
  final List<String?> names = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => names.add(route.settings.name);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (names.isNotEmpty) names.removeLast();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => names.remove(route.settings.name);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = names.lastIndexOf(oldRoute?.settings.name);
    if (i >= 0) {
      names[i] = newRoute?.settings.name;
    } else {
      names.add(newRoute?.settings.name);
    }
  }
}

Map<String, dynamic> _spec(String id) => jsonDecode(File('../spec/screens/$id.json').readAsStringSync()) as Map<String, dynamic>;

/// Every node in a spec part, depth first.
Iterable<Map<String, dynamic>> _nodes(Object? v) sync* {
  if (v is Map<String, dynamic>) {
    yield v;
    for (final c in v.values) {
      yield* _nodes(c);
    }
  } else if (v is List) {
    for (final c in v) {
      yield* _nodes(c);
    }
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _open(WidgetTester tester, String route, {List<NavigatorObserver> observers = const []}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    navigatorObservers: observers,
    onGenerateRoute: AppRouter.onGenerateRoute,
    onGenerateInitialRoutes: (_) => [AppRouter.onGenerateRoute(RouteSettings(name: route))!],
  ));
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester);
}

Finder _switchOf(String label) => find.descendant(
      of: find.byWidgetPredicate((w) => w is TToggleRow && w.label == label),
      matching: find.byType(Switch),
    );

bool _switchOn(WidgetTester tester, String label) => tester.widget<Switch>(_switchOf(label)).value;

/// Ends the test after any toast has gone.
Future<void> _drain(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  late _Api api;

  setUp(() {
    TSession.clear();
    TFlow.onboarding = false;
    api = _Api();
    TApi.instance = api;
  });
  tearDown(() {
    TDefaults.forPreview();
    TSession.clear();
  });

  group('spec', () {
    test('ob_consent: every optional toggle starts off; the required one starts on', () {
      final toggles = {for (final n in _nodes(_spec('ob_consent')['body'])) if (n['t'] == 'toggle') n['label'] as String: n['on']};
      expect(toggles, {
        'Essential app data': true,
        for (final label in _optional.keys) label: false,
      });
    });

    test('ob_account: "I’m 18 or older" starts unticked', () {
      final lists = [for (final n in _nodes(_spec('ob_account')['body'])) if (n['t'] == 'checklist') n];
      expect(lists, hasLength(1));
      expect(lists.single['key'], 'age_18_or_older');
      final items = (lists.single['items'] as List).cast<Map<String, dynamic>>();
      expect(items.map((i) => i['label']), [_age]);
      expect(items.single['done'] ?? false, isFalse);
    });
  });

  group('ob_consent', () {
    testWidgets('opens with every optional toggle off, and the session holds false for each', (tester) async {
      await _open(tester, Routes.obConsent);
      expect(_switchOn(tester, 'Essential app data'), isTrue);
      expect(TSession.values['ob_consent.essential_app_data'], isTrue);
      for (final MapEntry(key: label, value: key) in _optional.entries) {
        expect(_switchOn(tester, label), isFalse, reason: label);
        expect(TSession.values[key], isFalse, reason: key);
      }
      await _drain(tester);
    });

    testWidgets('"Agree and continue" with Private reminders off submits the consents and opens the basics', (tester) async {
      await _open(tester, Routes.obConsent);
      await _tap(tester, find.byKey(const ValueKey('a:footer[0]')));
      expect(api.calls, [('POST /v1/enrolments/consents', 'ob_consent')]);
      expect(find.byType(ObBasicsScreen), findsOneWidget);
      expect(TSession.values['ob_consent.private_reminders'], isFalse);
      await _drain(tester);
    });

    testWidgets('turning Private reminders on writes true, and off again writes false', (tester) async {
      await _open(tester, Routes.obConsent);
      await _tap(tester, _switchOf('Private reminders'));
      expect(_switchOn(tester, 'Private reminders'), isTrue);
      expect(TSession.values['ob_consent.private_reminders'], isTrue);
      await _tap(tester, _switchOf('Private reminders'));
      expect(_switchOn(tester, 'Private reminders'), isFalse);
      expect(TSession.values['ob_consent.private_reminders'], isFalse);
      await _drain(tester);
    });
  });

  group('ob_account', () {
    testWidgets('opens with "I’m 18 or older" unticked, and the session holds an empty list', (tester) async {
      await _open(tester, Routes.obAccount);
      expect(find.descendant(of: find.byType(TChecklist), matching: find.byIcon(Icons.check_rounded)), findsNothing);
      expect(TSession.values['ob_account.age_18_or_older'], isEmpty);
      await _tap(tester, find.text(_age));
      expect(find.descendant(of: find.byType(TChecklist), matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
      expect(TSession.values['ob_account.age_18_or_older'], [_age]);
      await _drain(tester);
    });
  });

  // P-68 / P-72: every sign-up route on ob_account asks rule ob.age first.
  // Unticked, it shows the message and goes nowhere: no sign-up submit, no
  // native sign-in, no navigation. Ticked, it behaves as before. Release
  // defaults, so the rule (not the preview resolver) decides.
  group('ob_account sign-up needs "I’m 18 or older"', () {
    late _Auth auth;
    late TFailClosedResolver resolver;

    setUp(() {
      TDefaults.forRelease();
      resolver = TFailClosedResolver();
      TNav.branchResolver = resolver.resolve;
      api = _Api();
      TApi.instance = api;
      auth = _Auth();
      TAuth.instance = auth;
    });
    tearDown(() => TAuth.instance = null);

    test('spec: each of the four routes is a branch decided by ob.age, unticked a toast with the message', () {
      final spec = _spec('ob_account');
      final actions = {for (final a in (spec['actions'] as List).cast<Map<String, dynamic>>()) a['element'] as String: a['action'] as Map<String, dynamic>};
      for (final MapEntry(key: label, value: (_, inner)) in _routes.entries) {
        final a = actions[label]!;
        expect(a['type'], 'branch', reason: label);
        expect(a['decide'], 'ob.age', reason: label);
        final cases = (a['cases'] as List).cast<Map<String, dynamic>>();
        expect(cases.map((c) => c['label']), ['Age confirmed', 'Age not confirmed'], reason: label);
        expect(cases[0]['action']['type'], inner, reason: label);
        expect(cases[1]['action'], {'type': 'toast', 'value': _ageMessage}, reason: label);
      }
      final rule = (jsonDecode(File('../spec/rules.json').readAsStringSync()) as Map<String, dynamic>)['ob.age'] as Map<String, dynamic>;
      expect(rule['inputs'], ['ob_account.age_18_or_older']);
      expect(rule['params'], {'item': _age});
    });

    for (final MapEntry(key: label, value: (key, _)) in _routes.entries) {
      testWidgets('$label, unticked: shows the message, announced, and goes nowhere', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS; // shows the Apple button too
        final semantics = tester.ensureSemantics();
        try {
          final stack = _Stack();
          await _open(tester, Routes.obAccount, observers: [stack]);
          final before = List.of(stack.names);
          await _tap(tester, find.byKey(ValueKey(key)));
          expect(find.text(_ageMessage), findsOneWidget, reason: label);
          expect(tester.getSemantics(find.text(_ageMessage)), isSemantics(label: _ageMessage, isLiveRegion: true), reason: 'the message is announced');
          expect(stack.names, before, reason: '$label stays on ob_account');
          expect(find.byType(ObAccountScreen), findsOneWidget);
          expect(api.calls, isEmpty, reason: 'no sign-up submit');
          expect(auth.calls, isEmpty, reason: 'no native sign-in');
          expect(resolver.recorded, isEmpty, reason: 'the rule decides');
          await _drain(tester);
        } finally {
          semantics.dispose();
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('$label, ticked: proceeds as before and shows no message', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await _open(tester, Routes.obAccount);
          await _tap(tester, find.text(_age));
          await _tap(tester, find.byKey(ValueKey(key)));
          expect(find.text(_ageMessage), findsNothing, reason: label);
          expect(resolver.recorded, isEmpty);
          switch (label) {
            case 'Continue with Apple' || 'Continue with Google':
              expect(auth.calls, [label == 'Continue with Apple' ? 'apple' : 'google']);
              expect(api.calls, isEmpty);
              expect(find.byType(AuthMergeScreen), findsOneWidget);
            case 'Create account':
              expect(api.calls, [('POST supabase /auth/v1/signup', 'ob_account')]);
              expect(auth.calls, isEmpty);
              expect(find.byType(AuthVerifyScreen), findsOneWidget);
            case 'Continue on this phone only':
              expect(api.calls, isEmpty);
              expect(auth.calls, isEmpty);
              expect(find.byType(TodayScreen), findsOneWidget);
          }
          await _drain(tester);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    testWidgets('ticking and then unticking the item blocks "Create account" again', (tester) async {
      await _open(tester, Routes.obAccount);
      await _tap(tester, find.text(_age));
      await _tap(tester, find.text(_age));
      expect(TSession.values['ob_account.age_18_or_older'], isEmpty);
      await _tap(tester, find.byKey(const ValueKey('a:footer[0]')));
      expect(find.text(_ageMessage), findsOneWidget);
      expect(api.calls, isEmpty);
      expect(find.byType(ObAccountScreen), findsOneWidget);
      await _drain(tester);
    });

    test('rule ob.age: only the ticked item confirms', () {
      expect(TRules.decide('ob.age', const {}), 'Age not confirmed');
      expect(TRules.decide('ob.age', const {'ob_account.age_18_or_older': <String>[]}), 'Age not confirmed');
      expect(TRules.decide('ob.age', const {'ob_account.age_18_or_older': ['Something else']}), 'Age not confirmed');
      expect(TRules.decide('ob.age', const {'ob_account.age_18_or_older': [_age]}), 'Age confirmed');
    });
  });
}
