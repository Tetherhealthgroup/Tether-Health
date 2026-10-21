// The tether_ui shell: entry before the first frame from local inputs only,
// a late profile re-resolves only on the entry screen, runtime entries, and
// the platform variants in the running app.
import 'dart:async';

import 'package:breathefree_patient/account/account_deletion_receipt_store.dart';
import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

import 'fakes.dart';

/// Starts the shell and pumps its first frame. Returns the runtime.
Future<TetherUiRuntime> _start(
  WidgetTester tester, {
  required AccountController account,
  bool guestPlan = false,
  TargetPlatform platform = TargetPlatform.iOS,
  void Function()? atRunApp,
}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  late Widget app;
  final runtime = await runTetherUi(
    account: account,
    guestStore: FakeGuestStore(hasPlan: guestPlan),
    platform: platform,
    run: (widget) {
      atRunApp?.call();
      app = widget;
    },
  );
  addTearDown(runtime.lifecycle.dispose);
  await tester.pumpWidget(app);
  return runtime;
}

List<String?> _stack(TetherUiRuntime runtime) =>
    [for (final route in runtime.instances.stack) route.settings.name];

void main() {
  tearDown(() {
    TDefaults.forPreview();
    TSession.values.clear();
  });

  testWidgets('a signed-out phone with no guest plan opens on welcome',
      (tester) async {
    final runtime = await _start(tester, account: fakeAccount());
    expect(_stack(runtime), [Routes.welcome]);
  });

  testWidgets('a guest plan on the phone opens on today', (tester) async {
    final runtime =
        await _start(tester, account: fakeAccount(), guestPlan: true);
    expect(_stack(runtime), [Routes.today]);
  });

  testWidgets(
      'a guest plan read at launch is dropped once a session ends: guest '
      'with a plan, first sign-in, sign-out opens welcome', (tester) async {
    final account = fakeAccount();
    final runtime = await _start(tester, account: account, guestPlan: true);
    expect(_stack(runtime), [Routes.today]);
    await account.signIn(
      email: 'synthetic-user-01@example.test',
      password: 'synthetic-password',
    );
    await tester.pumpAndSettle();
    expect(runtime.lifecycle.ended, isEmpty,
        reason: "a guest's first sign-in is not a session end");
    expect(_stack(runtime), [Routes.today]);
    await account.signOut();
    await tester.pumpAndSettle();
    expect(_stack(runtime), [Routes.welcome]);
  });

  testWidgets('a pending deletion receipt opens account_deleted',
      (tester) async {
    final account = fakeAccount(
      auth: FakeAuth(signedInAs: 'synthetic-user-01'),
      receipts: FakeReceipts(
          const PendingAccountDeletion(accountId: 'synthetic-user-01')),
    );
    final runtime = await _start(tester, account: account);
    expect(_stack(runtime), [Routes.accountDeleted]);
    expect(account.isSignedIn, isFalse);
  });

  testWidgets(
      'signed in, onboarding unknown opens today; a late incomplete '
      'profile moves the member to welcome while still on the entry',
      (tester) async {
    final profiles = FakeProfiles(onboardingCompleted: false)
      ..gate = Completer<void>();
    final account = fakeAccount(
      auth: FakeAuth(signedInAs: 'synthetic-user-01'),
      profiles: profiles,
    );
    int? loadsAtRunApp;
    final runtime = await _start(
      tester,
      account: account,
      atRunApp: () => loadsAtRunApp = profiles.loads,
    );
    expect(loadsAtRunApp, 0, reason: 'nothing reached the network before');
    expect(_stack(runtime), [Routes.today],
        reason: 'the first frame uses local inputs only');
    expect(profiles.loads, 1, reason: 'the profile loads after the frame');
    profiles.gate!.complete();
    await tester.pumpAndSettle();
    expect(_stack(runtime), [Routes.welcome]);
  });

  testWidgets('a late profile never pulls the member off a screen they opened',
      (tester) async {
    final profiles = FakeProfiles(onboardingCompleted: false)
      ..gate = Completer<void>();
    final account = fakeAccount(
      auth: FakeAuth(signedInAs: 'synthetic-user-01'),
      profiles: profiles,
    );
    final runtime = await _start(tester, account: account);
    await tester.pump();
    unawaited(
        runtime.entry.navigatorKey.currentState!.pushNamed(Routes.crisis));
    await tester.pumpAndSettle();
    profiles.gate!.complete();
    await tester.pumpAndSettle();
    expect(_stack(runtime), [Routes.today, Routes.crisis]);
  });

  testWidgets('showEntry makes a runtime entry the only screen',
      (tester) async {
    final runtime = await _start(tester, account: fakeAccount());
    unawaited(
        runtime.entry.navigatorKey.currentState!.pushNamed(Routes.obPrograms));
    await tester.pumpAndSettle();
    runtime.entry.showEntry(Routes.todaySafety);
    await tester.pumpAndSettle();
    expect(_stack(runtime), [Routes.todaySafety]);
    expect(runtime.entry.entryName, Routes.todaySafety);
  });

  testWidgets('on Android a pushed screen opens as its Android variant',
      (tester) async {
    final runtime = await _start(
      tester,
      account: fakeAccount(),
      guestPlan: true,
      platform: TargetPlatform.android,
    );
    unawaited(
        runtime.entry.navigatorKey.currentState!.pushNamed(Routes.sysUpdate));
    await tester.pumpAndSettle();
    expect(_stack(runtime), [Routes.today, Routes.sysUpdateAndroid]);
  });

  testWidgets('on iPhone the same screen is not substituted', (tester) async {
    final runtime =
        await _start(tester, account: fakeAccount(), guestPlan: true);
    unawaited(
        runtime.entry.navigatorKey.currentState!.pushNamed(Routes.sysUpdate));
    await tester.pumpAndSettle();
    expect(_stack(runtime), [Routes.today, Routes.sysUpdate]);
  });

  testWidgets('each screen instance gets its own number', (tester) async {
    final runtime = await _start(tester, account: fakeAccount());
    final nav = runtime.entry.navigatorKey.currentState!;
    final first = runtime.instances.instanceOf('welcome');
    expect(first, isNotNull);
    unawaited(nav.pushNamed(Routes.welcome));
    await tester.pumpAndSettle();
    final second = runtime.instances.instanceOf('welcome');
    expect(second, isNot(first));
    nav.pop();
    await tester.pumpAndSettle();
    expect(runtime.instances.instanceOf('welcome'), first);
    expect(runtime.instances.instanceOf('today'), isNull);
  });
}
