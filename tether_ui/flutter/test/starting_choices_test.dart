// Starting choices (P-52): the optional consents on ob_consent and the
// "I’m 18 or older" attestation on ob_account start unticked, so the member
// makes each choice. Pinned in the spec and in the generated screens, with
// the footer buttons behaving as the spec says while they are unticked.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/auth/auth_verify_screen.dart';
import 'package:tether_ui/screens/onboarding/ob_basics_screen.dart';
import 'package:tether_ui/ui/ui.dart';

const _age = 'I’m 18 or older';

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

Future<void> _open(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
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

    // The spec gives "Create account" no age requirement: it submits and
    // opens auth_verify whether or not the item is ticked. This records the
    // spec as it is; a requirement would be a spec change.
    testWidgets('"Create account" with the item unticked submits the sign-up and opens auth_verify, as the spec says', (tester) async {
      await _open(tester, Routes.obAccount);
      await _tap(tester, find.byKey(const ValueKey('a:footer[0]')));
      expect(api.calls, [('POST supabase /auth/v1/signup', 'ob_account')]);
      expect(find.byType(AuthVerifyScreen), findsOneWidget);
      await _drain(tester);
    });
  });
}
