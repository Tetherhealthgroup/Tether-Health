// The session lifecycle: every way a member's session ends clears what they
// typed and saw, in order, and leaves only the entry screen.
import 'dart:async';

import 'package:breathefree_patient/app/entry.dart';
import 'package:breathefree_patient/app/screen_instances.dart';
import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/integration/data_adapter.dart';
import 'package:breathefree_patient/integration/session_lifecycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

import '../app/fakes.dart';
import '../app/source_scan.dart';

class _Harness {
  _Harness(this.account, this.lifecycle, this.entry, this.data, this.log,
      this.instances);

  final AccountController account;
  final SessionLifecycle lifecycle;
  final EntryNavigator entry;
  final AppData data;
  final List<String> log;
  final ScreenInstances instances;

  NavigatorState get navigator => entry.navigatorKey.currentState!;
}

/// Pumps a navigator owned by an [EntryNavigator], with screens open on top
/// of the entry, a session full of values and a cached display value.
Future<_Harness> _harness(
  WidgetTester tester, {
  String? signedInAs = 'synthetic-user-01',
}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final auth = FakeAuth(signedInAs: signedInAs);
  final account = fakeAccount(auth: auth);
  final data = AppData();
  final log = <String>[];
  late _Harness harness;
  final entry = EntryNavigator(
    platform: TargetPlatform.iOS,
    state: () => EntryState(
      pendingDeletionReceipt:
          account.pendingAccountDeletion != null && !account.isSignedIn,
      signedIn: account.isSignedIn,
      onboardingComplete: true,
    ),
  );
  final lifecycle = SessionLifecycle(
    account: account,
    data: data,
    resetToEntry: () {
      log.add('reset: session ${TSession.values.isEmpty ? 'empty' : 'full'}, '
          'data ${harness.data.watch('today.streak').value}');
      entry.resetToEntry();
    },
  )..start();
  final instances = ScreenInstances();
  harness = _Harness(account, lifecycle, entry, data, log, instances);
  addTearDown(lifecycle.dispose);

  await tester.pumpWidget(MaterialApp(
    navigatorKey: entry.navigatorKey,
    onGenerateRoute: entry.route,
    onGenerateInitialRoutes: (_) => entry.initialRoutes(),
    navigatorObservers: [instances],
  ));
  unawaited(harness.navigator.pushNamed(Routes.checkin));
  await tester.pumpAndSettle();
  unawaited(harness.navigator.pushNamed(Routes.crisis));
  await tester.pumpAndSettle();

  TSession.set('checkin.mood', 'synthetic');
  TSession.set('auth_signin.password', 'synthetic-password');
  (data.watch('today.streak') as ValueNotifier<Object?>).value = 3;
  data.watch('today.streak').addListener(
      () => log.add('data cleared: flow ${TFlow.onboarding}, session '
          '${TSession.values.isEmpty ? 'empty' : 'full'}'));
  TFlow.onboarding = true;
  return harness;
}

/// Route names in the navigator, bottom first.
List<String?> _routes(_Harness h) =>
    [for (final route in h.instances.stack) route.settings.name];

/// Screen id by route name.
final _screenOf = {
  for (final (id, _, _, route) in AppRouter.catalog) route: id
};

/// Checks the state after a session end with [entry] as the only screen.
Future<void> _expectCleared(
  WidgetTester tester,
  _Harness h, {
  required int epochBefore,
  required String entry,
}) async {
  await tester.pumpAndSettle();
  expect(TSession.epoch, epochBefore + 1);
  // Only the entry screen's own defaults, written as it builds, remain.
  expect(
    TSession.values.keys.where((k) => !k.startsWith('${_screenOf[entry]}.')),
    isEmpty,
  );
  expect(h.data.cachedKeys, 0);
  expect(h.data.watch('today.streak').value, isNull);
  expect(TFlow.onboarding, isFalse);
  expect(_routes(h), [entry]);
  expect(h.log, [
    'reset: session full, data 3',
    'data cleared: flow true, session empty',
  ]);
}

void main() {
  tearDown(() {
    TSession.values.clear();
    TFlow.onboarding = false;
  });

  testWidgets('sign-out clears in order and leaves the entry screen',
      (tester) async {
    final h = await _harness(tester);
    final epoch = TSession.epoch;
    await h.account.signOut();
    await _expectCleared(tester, h, epochBefore: epoch, entry: Routes.welcome);
    expect(h.lifecycle.ended, [SessionEndReason.signOut]);
  });

  testWidgets('switching from A to B with no sign-out between clears',
      (tester) async {
    final h = await _harness(tester);
    final epoch = TSession.epoch;
    expect(h.account.accountId, 'synthetic-user-01');
    // A sign-in that completes for another account, for example while its
    // sheet was covered: no sign-out happens in between.
    await h.account.signIn(
      email: 'synthetic-user-02@example.test',
      password: 'synthetic-password',
    );
    expect(h.account.accountId, 'synthetic-user-02');
    await _expectCleared(tester, h, epochBefore: epoch, entry: Routes.today);
    expect(h.lifecycle.ended, [SessionEndReason.accountSwitch]);
  });

  testWidgets('a completed deletion clears, then runs the cleaners',
      (tester) async {
    final h = await _harness(tester);
    final epoch = TSession.epoch;
    final cleaned = <String>[];
    h.lifecycle.cleaners
      ..register((id) async {
        cleaned.add('outbox $id, flow ${TFlow.onboarding}, '
            'session ${TSession.values.isEmpty ? 'empty' : 'full'}');
      })
      ..register((id) async => throw StateError('synthetic failure'))
      ..register((id) async => cleaned.add('sync $id'));
    final done = await h.account.deleteAppData(password: 'synthetic-password');
    expect(done, isNotNull);
    await _expectCleared(tester, h,
        epochBefore: epoch, entry: Routes.accountDeleted);
    expect(h.lifecycle.ended, [SessionEndReason.deletionCompleted]);
    expect(cleaned, [
      'outbox synthetic-user-01, flow false, session empty',
      'sync synthetic-user-01',
    ]);
  });

  testWidgets('cleaners run on deletion only', (tester) async {
    final h = await _harness(tester);
    var runs = 0;
    h.lifecycle.cleaners.register((_) async => runs++);
    await h.account.signOut();
    await tester.pumpAndSettle();
    await h.lifecycle.onSessionExpired();
    await tester.pumpAndSettle();
    expect(runs, 0);
    expect(DeletionCleaners().length, 0, reason: 'the registry starts empty');
  });

  testWidgets('an expired session clears in order', (tester) async {
    final h = await _harness(tester);
    final epoch = TSession.epoch;
    await h.lifecycle.onSessionExpired();
    await _expectCleared(tester, h, epochBefore: epoch, entry: Routes.today);
    expect(h.lifecycle.ended, [SessionEndReason.expired]);
  });

  testWidgets("a guest's first sign-in does not clear", (tester) async {
    final h = await _harness(tester, signedInAs: null);
    final epoch = TSession.epoch;
    await h.account.signIn(
      email: 'synthetic-user-01@example.test',
      password: 'synthetic-password',
    );
    await tester.pumpAndSettle();
    expect(h.account.isSignedIn, isTrue);
    expect(TSession.epoch, epoch);
    expect(TSession.values, isNotEmpty);
    expect(h.data.watch('today.streak').value, 3);
    expect(TFlow.onboarding, isTrue);
    expect(_routes(h), [Routes.welcome, Routes.checkin, Routes.crisis]);
    expect(h.lifecycle.ended, isEmpty);
  });

  testWidgets('notifications that do not change the account do not clear',
      (tester) async {
    final h = await _harness(tester);
    final epoch = TSession.epoch;
    h.account.setProfileError('synthetic');
    h.account.clearError();
    await tester.pumpAndSettle();
    expect(TSession.epoch, epoch);
    expect(h.lifecycle.ended, isEmpty);
  });

  test('TSession.clear is called only from session_lifecycle.dart', () {
    final calls = <String>[];
    for (final MapEntry(key: path, value: source) in libSources().entries) {
      final code = codeOnly(source);
      for (final _ in RegExp(r'\bTSession\s*\.\s*clear\b').allMatches(code)) {
        calls.add(path);
      }
      if (RegExp(r'\bTSession\s*\.\s*values\s*\.\s*(?:clear|remove)')
          .hasMatch(code)) {
        calls.add('$path (values)');
      }
    }
    expect(calls, ['lib/integration/session_lifecycle.dart']);
  });
}
