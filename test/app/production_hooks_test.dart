// The app installs its own tether_ui hooks, the same in debug and release,
// and never a preview or inert default.
import 'package:breathefree_patient/app/production_hooks.dart';
import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/error/privacy_safe_error_reporter.dart';
import 'package:breathefree_patient/integration/data_adapter.dart';
import 'package:breathefree_patient/integration/device_outcomes.dart';
import 'package:breathefree_patient/integration/platform_adapter.dart';
import 'package:breathefree_patient/integration/registry.dart';
import 'package:breathefree_patient/quit_plan/guest_quit_plan_store.dart';
import 'package:breathefree_patient/backend/stub_backend.dart';
import 'package:breathefree_patient/config/app_config.dart' show BackendMode;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

class _RecordingErrors extends PrivacySafeErrorReporter {
  final List<(Object, String)> recorded = [];

  @override
  void record(Object error, StackTrace? stack, {required String source}) =>
      recorded.add((error, source));
}

class _FakeAuth implements TAuth {
  @override
  Future<String?> signIn(String provider, List<String> outcomes) async =>
      'Success';
}

class _NoGuestPlan implements GuestQuitPlanStore {
  @override
  bool get isPersistent => true;
  @override
  Future<GuestQuitPlanSnapshot?> load() async => null;
  @override
  Future<void> save(GuestQuitPlanSnapshot snapshot) async {}
  @override
  Future<void> clear() async {}
}

/// Puts every hook in the state a debug build starts in, with simulation
/// values set, so the installer has something to replace.
void _startLikeDebug() {
  TDefaults.forPreview();
  TSim.queue.add('Allowed');
  TSim.force = 'Allowed';
  TFlow.onboarding = true;
  TAuth.instance = _FakeAuth();
  TNav.reporter = TNav.reportToFlutterError;
}

/// Checks the release configuration of the installed hooks.
void _expectProductionHooks(ProductionHooks hooks) {
  expect(TApi.instance, same(hooks.api));
  expect(TApi.instance, isA<AppApi>());
  expect(TApi.instance, isNot(isA<PreviewApi>()));
  expect(TApi.instance, isNot(isA<TUnconfiguredApi>()));

  expect(TData.instance, same(hooks.data));
  expect(TData.instance, isA<AppData>());
  expect(TData.instance, isNot(isA<PreviewData>()));
  expect(TData.instance, isNot(isA<TEmptyData>()));

  expect(TDevice.instance, same(hooks.device));
  expect(TDevice.instance, isA<AppDevice>());
  expect(TDevice.instance, isNot(isA<PreviewDevice>()));
  expect(TDevice.instance, isNot(isA<TInertDevice>()));

  expect(TPlatform.instance, same(hooks.platform));
  expect(TPlatform.instance, isA<AppPlatform>());
  expect(TPlatform.instance, isNot(isA<TInertPlatform>()));
  expect(TPlatform.instance, isNot(isA<PreviewPlatform>()));

  expect(TNav.branchResolver, hooks.resolver.resolve,
      reason: 'the resolver is the installed fail-closed tear-off');
  expect(TNav.branchResolver, isNot(TNav.previewResolver));

  expect(TNav.redactQuestion, isTrue);
  expect(TNav.reporter, hooks.reporter.report);
  expect(TSim.queue, isEmpty);
  expect(TSim.force, isNull);
  expect(TFlow.onboarding, isFalse);
  expect(TAuth.instance, isNull);
}

void main() {
  tearDown(TDefaults.forPreview);

  for (final release in [true, false]) {
    test('release: $release installs the app hooks, never a preview one', () {
      _startLikeDebug();
      final hooks = installProductionHooks(release: release);
      _expectProductionHooks(hooks);
    });
  }

  test('both release values install the same kinds of hooks', () {
    Map<String, Type> kinds() => {
          'api': TApi.instance.runtimeType,
          'data': TData.instance.runtimeType,
          'device': TDevice.instance.runtimeType,
          'platform': TPlatform.instance.runtimeType,
        };
    installProductionHooks(release: true);
    final release = kinds();
    installProductionHooks(release: false);
    expect(kinds(), release);
  });

  test('the reporter forwards error codes and counts the fallback', () {
    final errors = _RecordingErrors();
    final reporter = AppCodeReporter(errors: errors);
    installProductionHooks(release: true, reporter: reporter);

    TNav.report(TCallFallback.shownCode);
    TNav.report(TCallFallback.shownCode);
    expect(errors.recorded, isEmpty);
    expect(reporter.informationalCounts, {TCallFallback.shownCode: 2});

    TNav.report(TNav.platformTimeoutCode);
    expect(errors.recorded, hasLength(1));
    final (error, source) = errors.recorded.single;
    expect(source, 'tether_ui');
    expect(error, isA<TUiError>());
    expect((error as TUiError).code, TNav.platformTimeoutCode);
  });

  testWidgets('the resolver, device and platform report through it',
      (tester) async {
    final errors = _RecordingErrors();
    installProductionHooks(
      release: true,
      reporter: AppCodeReporter(errors: errors),
    );
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      context = c;
      return const SizedBox();
    })));
    await TNav.branchResolver(context, '', const ['A', 'B']);
    await TDevice.instance.ask(context,
        const TBranchRef('x', TAsk.notificationsRequest, 'ob_reminders'));
    await TPlatform.instance.openUrl(context, 'http://example.test/');
    await tester.pump(const Duration(seconds: 2));
    expect(
      errors.recorded.map((e) => (e.$1 as TUiError).code),
      [
        TFailClosedResolver.code,
        deviceNotConfiguredCode,
        PlatformCodes.urlRefused,
      ],
    );
  });

  testWidgets('the first frame already sees the installed hooks',
      (tester) async {
    _startLikeDebug();
    Map<String, Object?>? atRunApp;
    late Widget app;
    final runtime = await runTetherUi(
      // A stub backend: the sandbox reads secure storage, which never
      // answers in a widget test.
      backend: StubBackend(BackendMode.sandbox),
      account: AccountController.disabled(),
      guestStore: _NoGuestPlan(),
      release: true,
      run: (widget) {
        atRunApp = {
          'api': TApi.instance,
          'data': TData.instance,
          'device': TDevice.instance,
          'platform': TPlatform.instance,
          'resolver': TNav.branchResolver,
        };
        app = widget;
      },
    );
    expect(atRunApp, {
      'api': runtime.hooks.api,
      'data': runtime.hooks.data,
      'device': runtime.hooks.device,
      'platform': runtime.hooks.platform,
      'resolver': runtime.hooks.resolver.resolve,
    });
    _expectProductionHooks(runtime.hooks);

    await tester.pumpWidget(app);
    expect(runtime.entry.entryName, Routes.welcome);
    expect(find.byKey(const ValueKey('a:footer[0]')), findsOneWidget);
    _expectProductionHooks(runtime.hooks);
    runtime.lifecycle.dispose();
  });
}
