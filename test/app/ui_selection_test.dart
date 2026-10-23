// The tether_ui screens run only in debug builds that ask for them. Every
// profile and release build runs the legacy app.
import 'dart:io';

import 'package:breathefree_patient/app/ui_selection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

void main() {
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

    test('the defaults are kDebugMode and the TETHER_UI define', () {
      // This test run has no TETHER_UI define, so the default is legacy.
      expect(const bool.fromEnvironment('TETHER_UI'), isFalse);
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
          code, contains('debug && requested ? AppUi.tetherUi : AppUi.legacy'));
    });
  });

  test('lib/ reads only the config defines and TETHER_UI', () {
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
            'so the build mode and the define decide');
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
