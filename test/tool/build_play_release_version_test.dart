import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Runs only the version, certificate and read-back checks of
// tool/build_play_release.sh (`--check-version-only`, `--verify-aab=`, and the
// early exits of a full invocation). Nothing is built: the script is copied
// into a temporary project root next to a synthetic pubspec.yaml, and
// bundletool, aapt2 and keytool are replaced by fakes on a private PATH.

String join(List<String> parts) => parts.join(Platform.pathSeparator);

void main() {
  late Directory root;
  late Directory fakeBin;
  late String scriptPath;

  void writeFake(String name, String body) {
    final file = File(join([fakeBin.path, name]))
      ..writeAsStringSync('#!/bin/sh\n$body\n');
    Process.runSync('chmod', ['+x', file.path]);
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('play_release_test_');
    Directory(join([root.path, 'tool'])).createSync();
    scriptPath = join([root.path, 'tool', 'build_play_release.sh']);
    File(
      join([Directory.current.path, 'tool', 'build_play_release.sh']),
    ).copySync(scriptPath);
    fakeBin = Directory(join([root.path, 'bin']))..createSync();
    // The script needs python3 and keytool; give it a fake keytool that reports
    // a non-debug certificate, and the real python3 (the /usr/bin one can be a
    // stub on a machine without developer tools).
    final python = Process.runSync('which', ['python3']).stdout.toString();
    Link(join([fakeBin.path, 'python3'])).createSync(python.trim());
    writeFake('keytool', 'echo "Owner: CN=Upload, O=Test"');
  });

  tearDown(() => root.deleteSync(recursive: true));

  void writePubspec(String version) {
    File(
      join([root.path, 'pubspec.yaml']),
    ).writeAsStringSync('name: x\nversion: $version\n');
  }

  ProcessResult run(
    List<String> args, {
    Map<String, String> env = const {},
    String? cwd,
  }) {
    // A PATH holding only the fakes and the system essentials, so a real
    // bundletool, aapt2 or flutter on the developer's machine never leaks in.
    return Process.runSync(
      '/bin/bash',
      [scriptPath, ...args],
      environment: {...env, 'PATH': '${fakeBin.path}:/usr/bin:/bin'},
      includeParentEnvironment: false,
      workingDirectory: cwd,
    );
  }

  String output(ProcessResult r) => '${r.stdout}${r.stderr}';

  /// A zip with the layout of a real AAB (manifest under base/manifest/).
  File writeAab(String name, {bool withEntries = true}) {
    final path = join([root.path, name]);
    final entries = withEntries
        ? ['base/manifest/AndroidManifest.xml', 'base/resources.pb']
        : ['BUNDLE-METADATA/readme.txt'];
    final result = Process.runSync(
      'python3',
      [
        '-I',
        '-c',
        'import sys, zipfile\n'
            'z = zipfile.ZipFile(sys.argv[1], "w")\n'
            'for n in sys.argv[2:]: z.writestr(n, "x")\n'
            'z.close()',
        path,
        ...entries,
      ],
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
    return File(path);
  }

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

    test('rejects a pubspec build number that overflows or exceeds Play', () {
      writePubspec('1.0.0+99999999999999999999');
      expect(run(['--check-version-only']).exitCode, 1);
      writePubspec('1.0.0+2100000001');
      final r = run(['--check-version-only']);
      expect(r.exitCode, 1);
      expect(output(r), contains('between 1 and 2100000000'));
      writePubspec('1.0.0+2100000000');
      expect(run(['--check-version-only']).exitCode, 0);
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

    test('rejects --verify-aab with --check-version-only', () {
      writePubspec('1.0.0+9');
      final aab = writeAab('app.aab');
      final r = run(['--check-version-only', '--verify-aab=${aab.path}']);
      expect(r.exitCode, 2);
      expect(output(r), contains('exclusive'));
    });

    test('rejects an empty --verify-aab= and a missing AAB file', () {
      writePubspec('1.0.0+9');
      final empty = run(['--verify-aab=']);
      expect(empty.exitCode, 2);
      expect(output(empty), contains('requires a path'));
      final missing = run(['--verify-aab=${root.path}/nope.aab']);
      expect(missing.exitCode, 2);
      expect(output(missing), contains('AAB not found'));
    });
  });

  group('full invocation stops at the version check', () {
    test('pubspec +1 exits 1 before any build step can run', () {
      writePubspec('1.0.0+1');
      final define = File(join([root.path, 'release.json']))
        ..writeAsStringSync('{}');
      // No flutter on this PATH, so nothing could build even if reached.
      final r = run(['--dart-define-from-file=${define.path}']);
      expect(r.exitCode, 1, reason: output(r));
      expect(output(r), contains('below the minimum 2'));
      expect(output(r), isNot(contains('== flutter')));
      expect(output(r), isNot(contains('cannot read define file')));
    });

    test('a relative define path resolves against the caller cwd', () {
      writePubspec('1.0.0+1');
      final cwd = Directory(join([root.path, 'caller']))..createSync();
      File(join([cwd.path, 'release.json'])).writeAsStringSync('{}');
      // Found in cwd: reaches the version check (exit 1), not "not found".
      final found =
          run(['--dart-define-from-file=release.json'], cwd: cwd.path);
      expect(found.exitCode, 1, reason: output(found));
      expect(output(found), contains('below the minimum 2'));
      // Present only at the repo root: must NOT be picked up silently.
      File(join([root.path, 'only_at_root.json'])).writeAsStringSync('{}');
      final missing = run([
        '--dart-define-from-file=only_at_root.json',
      ], cwd: cwd.path);
      expect(missing.exitCode, 2);
      expect(output(missing), contains('define file not found'));
    });
  });

  group('--verify-aab (post-build read-back)', () {
    late File aab;
    setUp(() => aab = writeAab('app.aab'));

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

    // Fake aapt2 that behaves like the real one on an AAB: it only accepts a
    // zip with AndroidManifest.xml and resources.pb at the root, and otherwise
    // prints the real error. Prints the real output format for the code in
    // $FAKE_CODE.
    const aapt2Body = 'case "\$1 \$2 \$3 \$4" in\n'
        '  "dump xmltree --file AndroidManifest.xml") ;;\n'
        '  *) echo "error: bad invocation" >&2; exit 1 ;;\n'
        'esac\n'
        'entries="\$(unzip -Z1 "\$5" 2>/dev/null | sort | tr "\\n" " ")"\n'
        'if [ "\$entries" != "AndroidManifest.xml resources.pb " ]; then\n'
        '  echo "\$5: error: could not identify format of APK." >&2\n'
        '  exit 1\n'
        'fi\n'
        'echo "      A: http://schemas.android.com/apk/res/android:versionCode'
        '(0x0101021b)=\$FAKE_CODE (Raw: \\"\$FAKE_CODE\\")"';

    test('aapt2 fallback repackages the AAB (rejects a raw AAB)', () {
      writeFake('aapt2', aapt2Body);
      ProcessResult withCode(String code) =>
          run(['--verify-aab=${aab.path}'], env: {'FAKE_CODE': code});
      expect(withCode('1').exitCode, 1);
      final ok = withCode('2');
      expect(ok.exitCode, 0, reason: output(ok));
      expect(output(ok), contains('versionCode: 2 (read from the AAB)'));
    });

    test('aapt2 fallback fails when the AAB lacks the manifest entries', () {
      writeFake('aapt2', aapt2Body);
      final bare = writeAab('bare.aab', withEntries: false);
      final r = run(['--verify-aab=${bare.path}'], env: {'FAKE_CODE': '5'});
      expect(r.exitCode, 1);
      expect(output(r), contains('could not read a numeric versionCode'));
    });
  });

  group('signing certificate check', () {
    late File aab;
    late File marker;
    setUp(() {
      aab = writeAab('app.aab');
      marker = File(join([root.path, 'readback_ran']));
      writeFake('bundletool', 'touch "${marker.path}"; echo 5');
    });

    test('passes with a non-debug certificate and then reads back', () {
      final r = run(['--verify-aab=${aab.path}']);
      expect(r.exitCode, 0, reason: output(r));
      expect(marker.existsSync(), isTrue);
    });

    test('a debug certificate fails before the read-back runs', () {
      writeFake('keytool', 'echo "Owner: CN=Android Debug, O=Android"');
      final r = run(['--verify-aab=${aab.path}']);
      expect(r.exitCode, 1);
      expect(output(r), contains('Android Debug certificate'));
      expect(marker.existsSync(), isFalse);
    });

    test('an unsigned bundle fails before the read-back runs', () {
      writeFake('keytool', 'echo "jar is unsigned"');
      final r = run(['--verify-aab=${aab.path}']);
      expect(r.exitCode, 1);
      expect(output(r), contains('no signing certificate'));
      expect(marker.existsSync(), isFalse);
    });
  });
}
