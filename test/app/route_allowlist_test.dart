// Pushed routes: a link that opens the app never opens a screen, and app
// code opens only the entry screens and the runtime entries.
import 'dart:async';

import 'package:breathefree_patient/app/route_allowlist.dart';
import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_deep_link.dart';
import 'package:breathefree_patient/backend/stub_backend.dart';
import 'package:breathefree_patient/config/app_config.dart' show BackendMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

import 'fakes.dart';

Future<TetherUiRuntime> _start(
  WidgetTester tester, {
  AccountController? account,
}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  late Widget app;
  final runtime = await runTetherUi(
    // The sandbox reads secure storage, which never answers in a widget
    // test.
    backend: StubBackend(BackendMode.sandbox),
    account: account ?? fakeAccount(),
    guestStore: FakeGuestStore(hasPlan: false),
    platform: TargetPlatform.iOS,
    run: (widget) => app = widget,
  );
  addTearDown(runtime.lifecycle.dispose);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  return runtime;
}

List<String?> _stack(TetherUiRuntime runtime) =>
    [for (final route in runtime.instances.stack) route.settings.name];

/// Sends [location] the way the platform does when a link opens the app.
Future<void> _pushFromPlatform(WidgetTester tester, String location) async {
  final message = const JSONMethodCodec().encodeMethodCall(MethodCall(
    'pushRouteInformation',
    <String, Object?>{'location': location, 'state': null},
  ));
  await tester.binding.defaultBinaryMessenger
      .handlePlatformMessage('flutter/navigation', message, (_) {});
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    TSession.values.clear();
  });

  group('classifyPushedRoute', () {
    test('the sign-in callback, as a link or a bare path', () {
      expect(classifyPushedRoute('$authRedirectUrl?code=synthetic'),
          PushedRouteKind.authCallback);
      expect(classifyPushedRoute('/login-callback?code=synthetic'),
          PushedRouteKind.authCallback);
    });

    test('everything else is refused', () {
      for (final location in [
        Routes.authSession,
        Routes.authNewpass,
        Routes.todaySafety,
        Routes.accountDelete,
        '/',
        '',
        'https://example.test/login-callback',
        'com.tetherhealthllc.tetherhealth://records-callback?code=x',
        'other.scheme://login-callback',
        '::not a uri',
      ]) {
        expect(classifyPushedRoute(location), PushedRouteKind.refused,
            reason: location);
      }
    });
  });

  testWidgets('a pushed screen name never opens its screen', (tester) async {
    final runtime = await _start(tester);
    expect(_stack(runtime), [Routes.welcome]);
    for (final location in [
      Routes.accountDelete,
      Routes.authSession,
      Routes.authNewpass,
      Routes.todaySafety,
      Routes.obAccount,
      'com.tetherhealthllc.tetherhealth:${Routes.accountData}',
      '$authRedirectUrl?code=synthetic',
    ]) {
      await _pushFromPlatform(tester, location);
      expect(_stack(runtime), [Routes.welcome], reason: location);
    }
  });

  testWidgets('showEntry opens only allowlisted screens', (tester) async {
    final runtime = await _start(tester);
    unawaited(
        runtime.entry.navigatorKey.currentState!.pushNamed(Routes.obPrograms));
    await tester.pumpAndSettle();
    runtime.entry.showEntry(Routes.accountDelete);
    await tester.pumpAndSettle();
    expect(_stack(runtime), [Routes.welcome],
        reason: 'an unlisted name opens the resolved entry instead');
    expect(runtime.entry.entryName, Routes.welcome);
  });

  testWidgets('signing in again opens as a sheet over the entry screen',
      (tester) async {
    final runtime = await _start(
      tester,
      account: fakeAccount(auth: FakeAuth(signedInAs: 'synthetic-user-01')),
    );
    expect(_stack(runtime), [Routes.today]);
    unawaited(
        runtime.entry.navigatorKey.currentState!.pushNamed(Routes.crisis));
    await tester.pumpAndSettle();
    runtime.entry.showEntry(Routes.authSession);
    await tester.pumpAndSettle();
    expect(_stack(runtime), [Routes.today, Routes.authSession]);
    expect(runtime.entry.entryName, Routes.today);
  });

  test('the allowlists hold exactly the ruled routes', () {
    expect(runtimeEntryRoutes, {
      Routes.authSession,
      Routes.authSessionApple,
      Routes.authSessionGoogle,
      Routes.todaySafety,
    });
    expect(runtimeEntrySheets.difference(runtimeEntryRoutes), isEmpty);
    expect(entryRoutes, {
      Routes.welcome,
      Routes.today,
      Routes.accountDeleted,
      Routes.authNewpass,
      Routes.sysUpdate,
    });
  });
}
