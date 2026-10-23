// The composition root: one backend per run, and the handlers, sign-in hook,
// display values and post-auth steps built on it.
import 'dart:io';

import 'package:breathefree_patient/app/composition.dart';
import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/backend/stub_backend.dart';
import 'package:breathefree_patient/config/app_config.dart';
import 'package:breathefree_patient/integration/registry.dart';
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

  test('a debug run with nothing configured composes the sandbox mode', () {
    final composition = compose(config: _none);
    expect(composition.backend.mode, BackendMode.sandbox);
    expect(composition.config, same(_none));
    expect(composition.auth, isNull);
    expect(composition.postAuthHooks.length, 0);
    expect(composition.cleaners.length, 0);
  });

  test('every registered endpoint is routed, none handled yet', () async {
    final composition = compose(config: _none);
    for (final entry in endpointRegistry) {
      expect(composition.api.entryFor(entry.endpoint), isNotNull);
      expect(
        await composition.api.submit(entry.endpoint, screenId: 'checkin'),
        const TResult.failed(RegistryCodes.notImplemented),
        reason: entry.endpoint,
      );
    }
  });

  test('a given backend replaces the configured one', () {
    final backend = StubBackend(BackendMode.http);
    expect(compose(config: _none, backend: backend).backend, same(backend));
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
