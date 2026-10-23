// What the tether_ui shell gives the handlers and the member around the
// screens: the programme and argument of programme screens, the test-build
// badge, and the generic error for a queued save refused for good.
import 'dart:async';

import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_backend.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_store.dart';
import 'package:breathefree_patient/backend/stub_backend.dart';
import 'package:breathefree_patient/data/app_services.dart';
import 'package:breathefree_patient/integration/endpoints/auth_endpoints.dart';
import 'package:breathefree_patient/integration/endpoints/common.dart';
import 'package:breathefree_patient/integration/outbox.dart';
import 'package:breathefree_patient/sync/sync_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

import 'fakes.dart';

/// A sandbox whose transport can be offline or refuse every request.
class _Switchable implements Backend {
  _Switchable(this.inner);

  final SandboxBackend inner;
  BackendResponse? answer;

  @override
  BackendMode get mode => inner.mode;

  @override
  AuthBackend get auth => inner.auth;

  @override
  late final BackendTransport transport = _Transport(this);

  @override
  Future<void> init() => inner.init();

  @override
  Future<void> wipeLocal() => inner.wipeLocal();
}

class _Transport implements BackendTransport {
  _Transport(this.owner);

  final _Switchable owner;

  @override
  Future<BackendResponse> send(BackendRequest request) async =>
      owner.answer ?? await owner.inner.transport.send(request);
}

Future<TetherUiRuntime> _start(
  WidgetTester tester, {
  required Backend backend,
  bool debug = true,
}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  late Widget app;
  final runtime = (await tester.runAsync(() => runTetherUi(
        account: fakeAccount(),
        guestStore: FakeGuestStore(hasPlan: false),
        backend: backend,
        debug: debug,
        platform: TargetPlatform.iOS,
        run: (widget) => app = widget,
      )))!;
  addTearDown(runtime.lifecycle.dispose);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  return runtime;
}

void main() {
  tearDown(() {
    TEnvironment.badge = null;
    HandlerKit.programOfScreen = null;
    HandlerKit.argumentOfScreen = null;
    AuthEndpoints.flow = null;
    TSession.clear();
  });

  group('test-build badge', () {
    testWidgets('sandbox mode shows it', (tester) async {
      await _start(tester, backend: StubBackend(BackendMode.sandbox));
      expect(TEnvironment.badge, testBuildBadge);
      expect(testBuildBadge, 'Test build');
    });

    testWidgets('real services in a debug build show none', (tester) async {
      await _start(tester, backend: StubBackend(BackendMode.http));
      expect(TEnvironment.badge, isNull);
    });

    testWidgets('real services in an internal build show it', (tester) async {
      await _start(tester,
          backend: StubBackend(BackendMode.http), debug: false);
      expect(TEnvironment.badge, testBuildBadge);
    });
  });

  testWidgets('programme screens know their programme and argument',
      (tester) async {
    final runtime =
        await _start(tester, backend: StubBackend(BackendMode.sandbox));
    final nav = runtime.entry.navigatorKey.currentState!;
    expect(HandlerKit.programOfScreen!('account_leave'), isNull,
        reason: 'not open');
    unawaited(nav.pushNamed(Routes.programSettings,
        arguments: const TRouteArgs(program: 'hw')));
    unawaited(nav.pushNamed(Routes.accountLeave));
    await tester.pumpAndSettle();
    expect(HandlerKit.programOfScreen!('program_settings'), 'hw');
    expect(HandlerKit.programOfScreen!('account_leave'), 'hw',
        reason: 'from the program settings below it');

    unawaited(nav.pushNamed(Routes.bfIntro));
    unawaited(nav.pushNamed(Routes.focusFull));
    await tester.pumpAndSettle();
    expect(HandlerKit.programOfScreen!('focus_full'), 'bf');

    unawaited(nav.pushNamed(Routes.learnLesson, arguments: 'bf.lesson-1'));
    await tester.pumpAndSettle();
    expect(HandlerKit.argumentOfScreen!('learn_lesson'), 'bf.lesson-1');
    expect(HandlerKit.argumentOfScreen!('records_source'), isNull);
  });

  testWidgets('a queued save refused for good shows the generic error',
      (tester) async {
    final backend =
        _Switchable(SandboxBackend(persistence: MemorySandboxPersistence()));
    final services = AppServices(
      backend,
      syncStore: MemorySyncDocumentStore(),
      outboxStore: MemorySyncDocumentStore(),
      localStore: MemorySyncDocumentStore(),
    );
    AppServices.install(services);
    await _start(tester, backend: backend);
    await tester.runAsync(() => backend.inner.auth.signUp(
        email: 'member-04@sandbox.invalid',
        password: 'synthetic-passphrase-4'));
    backend.answer = const BackendUnreachable();
    const entry = OutboxEntry(
      endpoint: 'POST /v1/records/check-ins',
      path: '/v1/records/check-ins',
      body: <String, Object?>{},
      idempotencyKey: '0123456789abcdef0123456789abcdef',
    );
    final queued = await tester.runAsync(() => services.outbox.submit(entry));
    expect(queued, isA<OutboxQueued>());
    final message = TStrings.english.kitGenericError;
    expect(find.text(message), findsNothing);

    backend.answer = const BackendProblem(422, 'invalid_record');
    await tester.runAsync(() => services.outbox.flush());
    await tester.pump();
    expect(find.text(message), findsOneWidget);
    expect(services.outbox.notices.value, 0, reason: 'shown once');
    await tester.pump(const Duration(seconds: 5));
  });
}
