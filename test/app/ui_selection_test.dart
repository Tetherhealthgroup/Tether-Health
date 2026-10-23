// The tether_ui screens run in debug builds that ask for them and in internal
// test builds (TETHER_UI_INTERNAL, added only by the release scripts'
// --internal-tether-ui flag). Every other profile and release build runs the
// legacy app.
import 'dart:convert';
import 'dart:io';

import 'package:breathefree_patient/app/tether_ui_shell.dart';
import 'package:breathefree_patient/app/ui_selection.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/backend/backend_factory.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_backend.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_store.dart';
import 'package:breathefree_patient/config/app_config.dart';
import 'package:breathefree_patient/config/misconfigured_build_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

import 'fakes.dart';
import 'source_scan.dart';

/// The config of an internal sandbox build made from
/// tool/defines/internal-sandbox.example.json (the release scripts pass the
/// file with --dart-define-from-file; AppConfig.fromEnvironment reads it).
AppConfig _internalSandboxConfig() {
  final defines = jsonDecode(
    File('tool/defines/internal-sandbox.example.json').readAsStringSync(),
  ) as Map<String, Object?>;
  expect(defines, {'TETHER_BACKEND': 'sandbox'});
  return AppConfig(
    apiBaseUrl: '',
    supabaseUrl: '',
    supabaseAnonKey: '',
    backend: defines['TETHER_BACKEND']! as String,
  );
}

void main() {
  group('an internal sandbox release build', () {
    tearDown(() {
      TDefaults.forPreview();
      TSession.values.clear();
    });

    test('picks tether_ui and passes the release start-up check', () {
      final config = _internalSandboxConfig();
      // Release: kDebugMode false, no TETHER_UI, TETHER_UI_INTERNAL=true.
      expect(
        selectAppUi(debug: false, requested: false, internal: true),
        AppUi.tetherUi,
      );
      // main.dart's check, as a release build runs it: no exception, so no
      // MisconfiguredBuildApp.
      expect(
        () => config.validate(production: true, tetherUi: true),
        returnsNormally,
      );
      expect(config.backendMode(debug: false), BackendMode.sandbox);
      expect(createBackend(config, debug: false), isA<SandboxBackend>());
    });

    test('without TETHER_BACKEND it would show the misconfigured screen', () {
      // Why the release scripts take the sandbox define file: the internal
      // define alone names no backend mode in a release build.
      const none =
          AppConfig(apiBaseUrl: '', supabaseUrl: '', supabaseAnonKey: '');
      expect(
        () => none.validate(production: true, tetherUi: true),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('TETHER_BACKEND must be sandbox or http'))),
      );
    });

    testWidgets('starts the tether_ui shell on the sandbox backend',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      Widget? shown;
      final runtime = await runTetherUi(
        account: AccountController.disabled(),
        guestStore: FakeGuestStore(hasPlan: false),
        release: true,
        config: _internalSandboxConfig(),
        // The real sandbox backend, kept in memory: secure storage never
        // answers in a widget test.
        backend: SandboxBackend(persistence: MemorySandboxPersistence()),
        run: (widget) => shown = widget,
      );
      addTearDown(runtime.lifecycle.dispose);
      expect(shown, isA<TetherUiShell>());
      expect(runtime.composition.backend.mode, BackendMode.sandbox);
      await tester.pumpWidget(shown!);
      await tester.pump();
      expect(find.byType(MisconfiguredBuildApp), findsNothing);
      expect(find.byType(TetherUiShell), findsOneWidget);
      expect(
        [for (final route in runtime.instances.stack) route.settings.name],
        [Routes.welcome],
      );
    });
  });

  group('selectAppUi', () {
    test('a profile or release build runs the legacy app even when asked', () {
      expect(selectAppUi(debug: false, requested: true), AppUi.legacy);
    });

    test('a debug build runs the legacy app unless asked', () {
      expect(selectAppUi(debug: true, requested: false), AppUi.legacy);
    });

    test('a debug build asked for tether_ui runs it', () {
      expect(selectAppUi(debug: true, requested: true), AppUi.tetherUi);
    });

    test('a release build not asked runs the legacy app', () {
      expect(selectAppUi(debug: false, requested: false), AppUi.legacy);
    });

    group('internal test build', () {
      test('a release build without the internal define runs legacy', () {
        expect(
          selectAppUi(debug: false, requested: false, internal: false),
          AppUi.legacy,
        );
        expect(
          selectAppUi(debug: false, requested: true, internal: false),
          AppUi.legacy,
        );
      });

      test('a release build with the internal define runs tether_ui', () {
        expect(
          selectAppUi(debug: false, requested: false, internal: true),
          AppUi.tetherUi,
        );
        expect(
          selectAppUi(debug: false, requested: true, internal: true),
          AppUi.tetherUi,
        );
      });

      test('a debug build with the internal define runs tether_ui', () {
        expect(
          selectAppUi(debug: true, requested: false, internal: true),
          AppUi.tetherUi,
        );
        expect(
          selectAppUi(debug: true, requested: true, internal: true),
          AppUi.tetherUi,
        );
      });

      test('a debug build without either define runs legacy', () {
        expect(
          selectAppUi(debug: true, requested: false, internal: false),
          AppUi.legacy,
        );
      });
    });

    test('the defaults are kDebugMode and the two defines', () {
      // This test run has neither define, so the default is legacy.
      expect(const bool.fromEnvironment('TETHER_UI'), isFalse);
      expect(const bool.fromEnvironment('TETHER_UI_INTERNAL'), isFalse);
      expect(selectAppUi(), AppUi.legacy);
      expect(kDebugMode, isTrue);
      final code = stripped(
        File('lib/app/ui_selection.dart').readAsStringSync(),
      ).replaceAll(RegExp(r'\s+'), ' ');
      expect(code, contains('bool debug = kDebugMode,'));
      expect(
        code,
        contains("bool requested = const bool.fromEnvironment('TETHER_UI'),"),
      );
      expect(
        code,
        contains(
          "bool internal = const bool.fromEnvironment('TETHER_UI_INTERNAL'),",
        ),
      );
      expect(
        code,
        contains(
          '(debug && requested) || internal ? AppUi.tetherUi : AppUi.legacy',
        ),
      );
    });
  });

  test('lib/ reads only the config defines and the two UI defines', () {
    final found = <String>[];
    final call = RegExp(
      r'\b(?:String|bool|int)\s*\.\s*(?:fromEnvironment|hasEnvironment)\s*\(',
    );
    final literal = RegExp(
      r'''\b(?:String|bool|int)\s*\.\s*(?:fromEnvironment|hasEnvironment)\s*\(\s*'([A-Za-z0-9_]+)'\s*[,)]''',
    );
    for (final MapEntry(key: path, value: source) in libSources().entries) {
      final text = stripped(source);
      final calls = call.allMatches(text).length;
      final keys = [for (final m in literal.allMatches(text)) m.group(1)!];
      expect(keys, hasLength(calls),
          reason: '$path reads a define whose key is not a plain literal');
      found.addAll(keys.map((key) => '$path:$key'));
    }
    expect(found..sort(), [
      'lib/app/ui_selection.dart:TETHER_UI',
      'lib/app/ui_selection.dart:TETHER_UI_INTERNAL',
      'lib/config/app_config.dart:API_BASE_URL',
      'lib/config/app_config.dart:EPIC_SANDBOX_CLIENT_ID',
      'lib/config/app_config.dart:GOOGLE_IOS_CLIENT_ID',
      'lib/config/app_config.dart:GOOGLE_WEB_CLIENT_ID',
      'lib/config/app_config.dart:SUPABASE_ANON_KEY',
      'lib/config/app_config.dart:SUPABASE_URL',
      'lib/config/app_config.dart:SYNC_BASE_URL',
      'lib/config/app_config.dart:TETHER_BACKEND',
    ]);
  });

  test('lib/main.dart picks the UI through selectAppUi() alone', () {
    final code = codeOnly(File('lib/main.dart').readAsStringSync());
    final selections = RegExp(r'\bselectAppUi\b').allMatches(code).toList();
    expect(selections, hasLength(1),
        reason: 'main.dart must call selectAppUi exactly once');
    final guard = RegExp(
      r'if\s*\(\s*selectAppUi\s*\(\s*\)\s*==\s*AppUi\.tetherUi\s*\)\s*\{',
    ).firstMatch(code);
    expect(guard, isNotNull,
        reason: 'main.dart must branch on selectAppUi() with no arguments, '
            'so the build mode and the defines decide');
    final blockEnd = matchingBracket(code, guard!.end - 1);

    final starts = RegExp(r'\brunTetherUi\s*\(').allMatches(code).toList();
    expect(starts, hasLength(1));
    expect(starts.single.start > guard.end && starts.single.start < blockEnd,
        isTrue,
        reason: 'the tether_ui app may start only inside that branch');
    expect(code.substring(guard.end, blockEnd), contains('return;'),
        reason: 'the tether_ui branch must not fall through to the legacy app');
    expect(RegExp(r'\bTetherUiShell\b').hasMatch(code), isFalse);

    final legacy = code.indexOf('runApp(BreatheFreeApp(');
    expect(legacy, greaterThan(blockEnd),
        reason: 'the legacy app still starts after the branch');
  });

  test('nothing else in lib/ starts the tether_ui app', () {
    for (final MapEntry(key: path, value: source) in libSources().entries) {
      if (path == 'lib/main.dart' || path == 'lib/app/tether_ui_shell.dart') {
        continue;
      }
      final code = codeOnly(source);
      expect(
          RegExp(r'\b(?:runTetherUi|TetherUiShell)\b').hasMatch(code), isFalse,
          reason: '$path starts the tether_ui app outside main.dart');
    }
  });
}
