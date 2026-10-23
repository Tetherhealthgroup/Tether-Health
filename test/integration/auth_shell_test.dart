// Email sign-in in the running tether_ui shell, sandbox mode: the account is
// on the backend's own sign-in, a sign-up through the screens' submit signs
// the member in, and an opened reset link shows the new-password screen.
import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_backend.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_store.dart';
import 'package:breathefree_patient/data/app_services.dart';
import 'package:breathefree_patient/integration/endpoints/auth_endpoints.dart';
import 'package:breathefree_patient/sync/sync_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

import '../app/fakes.dart';

const _age = 'I’m 18 or older';

void main() {
  late SandboxBackend backend;

  setUp(() {
    backend = SandboxBackend(persistence: MemorySandboxPersistence());
    // Secure storage never answers in a widget test.
    AppServices.install(AppServices(
      backend,
      syncStore: MemorySyncDocumentStore(),
      outboxStore: MemorySyncDocumentStore(),
      localStore: MemorySyncDocumentStore(),
    ));
  });

  tearDown(() {
    AuthEndpoints.flow = null;
    TSession.clear();
  });

  Future<TetherUiRuntime> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    late Widget app;
    final runtime = (await tester.runAsync(() => runTetherUi(
          // What lib/main.dart passes when no services are configured.
          account: AccountController.disabled(),
          guestStore: FakeGuestStore(hasPlan: false),
          backend: backend,
          platform: TargetPlatform.iOS,
          run: (widget) => app = widget,
        )))!;
    addTearDown(runtime.lifecycle.dispose);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    return runtime;
  }

  List<String?> stack(TetherUiRuntime runtime) =>
      [for (final route in runtime.instances.stack) route.settings.name];

  testWidgets('the sandbox account signs up through the screens submit',
      (tester) async {
    final runtime = await start(tester);
    expect(runtime.account.enabled, isTrue,
        reason: 'the disabled account is replaced by the backend one');
    expect(stack(runtime), [Routes.welcome]);
    TSession.set('ob_account.email', 'member-02@sandbox.invalid');
    TSession.set('ob_account.password', 'synthetic-passphrase-2');
    TSession.set('ob_account.age_18_or_older', [_age]);
    final result = await tester.runAsync(
        () => TApi.instance.submit(signUpEndpoint, screenId: 'ob_account'));
    await tester.pumpAndSettle();
    expect(result, const TResult.ok());
    expect(runtime.account.isSignedIn, isTrue);
    expect(TSession.values.containsKey('ob_account.password'), isFalse);
  });

  testWidgets('an opened reset link shows the new-password screen',
      (tester) async {
    final runtime = await start(tester);
    await tester.runAsync(() => backend.auth.signUp(
        email: 'member-03@sandbox.invalid',
        password: 'synthetic-passphrase-3'));
    await tester.runAsync(() => runtime.account.signOut());
    await tester.pumpAndSettle();
    TSession.set('auth_forgot.email', 'member-03@sandbox.invalid');
    final result = await tester.runAsync(
        () => TApi.instance.submit(recoverEndpoint, screenId: 'auth_forgot'));
    await tester.pumpAndSettle();
    expect(result, const TResult.ok());
    expect(runtime.account.passwordRecoveryPending, isTrue);
    expect(stack(runtime).last, Routes.authNewpass);
  });
}
