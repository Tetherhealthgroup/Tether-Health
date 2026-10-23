// The composition root: one backend per run, and the handlers, sign-in hook,
// display values and post-auth steps built on it.
import 'dart:io';

import 'package:breathefree_patient/app/composition.dart';
import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/backend/backend_factory.dart';
import 'package:breathefree_patient/backend/stub_backend.dart';
import 'package:breathefree_patient/config/app_config.dart';
import 'package:breathefree_patient/config/misconfigured_build_app.dart';
import 'package:breathefree_patient/integration/registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

import 'fakes.dart';
import 'source_scan.dart';

const _none = AppConfig(apiBaseUrl: '', supabaseUrl: '', supabaseAnonKey: '');

void main() {
  tearDown(() {
    TDefaults.forPreview();
    TSession.values.clear();
  });

  test('a debug run with nothing configured composes the sandbox mode',
      () async {
    final composition =
        await compose(config: _none, backend: StubBackend(BackendMode.sandbox));
    expect(composition.backend.mode, BackendMode.sandbox);
    expect(composition.config, same(_none));
    expect(composition.auth, isNull);
    // The local sync document and outbox are wiped after a deletion.
    expect(composition.cleaners.length, 1);
  });

  test('every registered endpoint has a handler, sign-in submits included',
      () async {
    final composition =
        await compose(config: _none, backend: StubBackend(BackendMode.sandbox));
    for (final entry in endpointRegistry) {
      expect(composition.api.entryFor(entry.endpoint), isNotNull);
      expect(composition.api.hasHandler(entry.endpoint), isTrue,
          reason: entry.endpoint);
    }
    expect(composition.postAuthHooks.length, 2,
        reason: 'a pending deletion, then the onboarding commit');
  });

  test('a given backend replaces the configured one, and is initialised',
      () async {
    final backend = _CountingBackend();
    final composition = await compose(config: _none, backend: backend);
    expect(composition.backend, same(backend));
    expect(backend.inits, 1);
  });

  test('a configuration with no backend mode is a misconfigured build', () {
    const partial = AppConfig(
        apiBaseUrl: 'https://api.example.test',
        supabaseUrl: '',
        supabaseAnonKey: '',
        backend: 'http');
    expect(
        compose(config: partial), throwsA(isA<MisconfiguredBuildException>()));
  });

  testWidgets('runTetherUi shows the misconfigured-build screen',
      (tester) async {
    const partial = AppConfig(
        apiBaseUrl: '', supabaseUrl: '', supabaseAnonKey: '', backend: 'nope');
    Widget? shown;
    await expectLater(
      runTetherUi(
        account: AccountController.disabled(),
        guestStore: FakeGuestStore(hasPlan: false),
        config: partial,
        run: (w) => shown = w,
      ),
      throwsA(isA<MisconfiguredBuildException>()),
    );
    expect(shown, isA<MisconfiguredBuildApp>());
  });

  testWidgets('runTetherUi installs the composed services', (tester) async {
    final backend = StubBackend(BackendMode.sandbox);
    final runtime = await runTetherUi(
      account: AccountController.disabled(),
      guestStore: FakeGuestStore(hasPlan: false),
      config: _none,
      backend: backend,
      run: (_) {},
    );
    addTearDown(runtime.lifecycle.dispose);
    final composition = runtime.composition;
    expect(composition.backend, same(backend));
    expect(TApi.instance, same(composition.api));
    expect(TData.instance, same(composition.data));
    expect(runtime.hooks.api, same(composition.api));
    expect(runtime.hooks.data, same(composition.data));
    expect(TAuth.instance, isNull);
    expect(runtime.lifecycle.cleaners, same(composition.cleaners));
  });

  test('only the composition root creates the backend', () {
    for (final MapEntry(key: path, value: source) in libSources().entries) {
      if (path == 'lib/app/composition.dart' ||
          path == 'lib/backend/backend_factory.dart') {
        continue;
      }
      expect(
          RegExp(r'\bcreateBackend\s*\(').hasMatch(codeOnly(source)), isFalse,
          reason: '$path builds a backend outside the composition root');
    }
    expect(
      File('lib/app/composition.dart').readAsStringSync(),
      contains('createBackend(config)'),
    );
  });
}

class _CountingBackend extends StubBackend {
  _CountingBackend() : super(BackendMode.sandbox);
  int inits = 0;

  @override
  Future<void> init() async => inits++;
}
