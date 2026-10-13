import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Runs only the version checks of tool/build_play_release.sh
/// (`--check-version-only`, `--verify-aab=`). Nothing is built: the script is
/// copied into a temporary project root next to a synthetic pubspec.yaml, and
/// bundletool/aapt2 are replaced by fake executables on a private PATH.
String join(List<String> parts) => parts.join(Platform.pathSeparator);

void main() {
  late Directory root;
  late Directory fakeBin;

  setUp(() {
    root = Directory.systemTemp.createTempSync('play_release_test_');
    Directory(join([root.path, 'tool'])).createSync();
    File(
      join([Directory.current.path, 'tool', 'build_play_release.sh']),
    ).copySync(join([root.path, 'tool', 'build_play_release.sh']));
    fakeBin = Directory(join([root.path, 'bin']))..createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  void writePubspec(String version) {
    File(
      join([root.path, 'pubspec.yaml']),
    ).writeAsStringSync('name: x\nversion: $version\n');
  }

  void writeFake(String name, String body) {
    final file = File(join([fakeBin.path, name]))
      ..writeAsStringSync('#!/bin/sh\n$body\n');
    Process.runSync('chmod', ['+x', file.path]);
  }

  ProcessResult run(List<String> args, {Map<String, String> env = const {}}) {
    // A PATH holding only the fakes and the system essentials, so a real
    // bundletool or aapt2 on the developer's machine never leaks in.
    return Process.runSync(
      '/bin/bash',
      [
        join([root.path, 'tool', 'build_play_release.sh']),
        ...args
      ],
      environment: {...env, 'PATH': '${fakeBin.path}:/usr/bin:/bin'},
      includeParentEnvironment: false,
    );
  }

  String output(ProcessResult r) => '${r.stdout}${r.stderr}';

  group('--check-version-only (pubspec)', () {
    test('fails when the pubspec build number is below the default minimum',
        () {
      writePubspec('1.0.0+1');
      final r = run(['--check-version-only']);
      expect(r.exitCode, 1);
      expect(output(r), contains('below the minimum 2'));
    });

    test('passes when the build number equals the minimum', () {
      writePubspec('1.0.0+2');
      final r = run(['--check-version-only']);
      expect(r.exitCode, 0, reason: output(r));
      expect(output(r), contains('no build was run'));
    });

    test('passes when the build number is above the minimum', () {
      writePubspec('1.0.0+17');
      expect(run(['--check-version-only']).exitCode, 0);
    });

    test('honours --min-version-code in both spellings', () {
      writePubspec('1.0.0+5');
      expect(run(['--check-version-only', '--min-version-code=6']).exitCode, 1);
      expect(
        run(['--check-version-only', '--min-version-code', '6']).exitCode,
        1,
      );
      expect(run(['--check-version-only', '--min-version-code=5']).exitCode, 0);
    });

    test('fails when the pubspec has no +buildNumber', () {
      writePubspec('1.0.0');
      final r = run(['--check-version-only']);
      expect(r.exitCode, 1);
      expect(output(r), contains('no +<buildNumber>'));
    });
  });

  group('--check-version-only (--build-number)', () {
    test('fails when --build-number is below the minimum', () {
      writePubspec('1.0.0+9');
      final r = run(['--check-version-only', '--build-number=1']);
      expect(r.exitCode, 1);
      expect(output(r), contains('--build-number 1 is below the minimum 2'));
    });

    test('passes when --build-number equals or exceeds the minimum', () {
      writePubspec('1.0.0+9');
      expect(run(['--check-version-only', '--build-number=2']).exitCode, 0);
      expect(run(['--check-version-only', '--build-number', '3']).exitCode, 0);
    });
  });

  group('argument validation', () {
    test('rejects non-numeric, zero and out-of-range values', () {
      writePubspec('1.0.0+9');
      for (final bad in ['abc', '0', '-1', '', '2100000001', '99999999999']) {
        final min = run(['--check-version-only', '--min-version-code=$bad']);
        expect(min.exitCode, 2, reason: 'min-version-code=$bad');
        final bn = run(['--check-version-only', '--build-number=$bad']);
        expect(bn.exitCode, 2, reason: 'build-number=$bad');
      }
    });

    test('rejects a missing value and unknown arguments', () {
      writePubspec('1.0.0+9');
      expect(run(['--check-version-only', '--min-version-code']).exitCode, 2);
      expect(run(['--check-version-only', '--bogus']).exitCode, 2);
    });
  });

  group('--verify-aab (post-build read-back)', () {
    late File aab;
    setUp(() {
      aab = File(join([root.path, 'app.aab']))..writeAsStringSync('not a zip');
    });

    test('fails clearly when neither bundletool nor aapt2 is installed', () {
      final r = run(['--verify-aab=${aab.path}']);
      expect(r.exitCode, 1);
      expect(output(r), contains('neither bundletool nor aapt2 is installed'));
    });

    test('bundletool: below, equal and above the minimum', () {
      writeFake('bundletool', 'echo "\$FAKE_CODE"');
      ProcessResult withCode(String code) =>
          run(['--verify-aab=${aab.path}'], env: {'FAKE_CODE': code});
      expect(withCode('1').exitCode, 1);
      expect(withCode('2').exitCode, 0);
      expect(withCode('3').exitCode, 0);
      expect(withCode('garbage').exitCode, 1);
    });

    test('falls back to aapt2 when bundletool is absent', () {
      writeFake(
        'aapt2',
        'echo "      A: http://schemas.android.com/apk/res/android:versionCode(0x0101021b)=1"',
      );
      expect(run(['--verify-aab=${aab.path}']).exitCode, 1);
      writeFake(
        'aapt2',
        'echo "      A: http://schemas.android.com/apk/res/android:versionCode(0x0101021b)=2"',
      );
      expect(run(['--verify-aab=${aab.path}']).exitCode, 0);
    });
  });
}
