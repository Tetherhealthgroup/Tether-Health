import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'release_define_cases.dart' as cases;

// TH-135 (R-081): the Play and iOS release scripts must never echo an argument
// or a path they were given. A value typed on the command line can hold a
// pasted secret, terminal escape sequences, or a forged GitHub workflow
// command line; none of it may reach a terminal or a CI log. Every case passes
// a hostile value (a per-run random canary, ESC, CR, LF and a forged `::`
// command line) at one print site and asserts the output is clean, the fixed
// message is shown, and the exit code is the one pinned here. The exit codes
// match the scripts before TH-135 except where a path was resolved to a
// different file than the one `[ -f ]` checked (a dash-leading name or
// directory, `link/..`, a trailing newline): those now resolve to the named
// file, and the path-resolution group pins the result. Nothing is built: the
// scripts are copied next to a synthetic pubspec.yaml, and flutter,
// bundletool and keytool are fakes on a private PATH.

String join(List<String> parts) => parts.join(Platform.pathSeparator);

String randomCanary() {
  final random = Random.secure();
  final hex = List.generate(
    16,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  return 'TH135CANARY$hex';
}

void main() {
  late Directory root;
  late Directory fakeBin;
  late String canary;
  late String hostile;

  final validDefine = cases.defineCases.firstWhere((c) => c.accepted).contents;
  final secretDefine =
      cases.defineCases.firstWhere((c) => c.name == 'sb_secret_ key').contents;

  void writeFake(String name, String body) {
    final file = File(join([fakeBin.path, name]))
      ..writeAsStringSync('#!/bin/sh\n$body\n');
    final chmod = Process.runSync('chmod', ['+x', file.path]);
    expect(chmod.exitCode, 0, reason: '${chmod.stderr}');
  }

  setUp(() {
    canary = randomCanary();
    // No '/' or NUL, so it is also a legal file name. It holds the words the
    // Play certificate grep keys on (Owner:, not signed, SHA256:).
    hostile = '$canary\x1b[31m\r\n::add-mask::$canary\n'
        '::error::forged Owner: not signed SHA256: $canary';
    root = Directory.systemTemp.createTempSync('release_arg_echo_test_');
    final repo = Directory.current.path;
    for (final script in [
      'build_play_release.sh',
      'build_ios_release.sh',
      'release_define_check.sh',
    ]) {
      File(join([root.path, 'tool', script]))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(
          File(join([repo, 'tool', script])).readAsBytesSync(),
        );
    }
    File(
      join([root.path, 'pubspec.yaml']),
    ).writeAsStringSync('name: x\nversion: 1.0.0+9\n');
    fakeBin = Directory(join([root.path, 'bin']))..createSync();
    final python = Process.runSync(
      'which',
      ['python3'],
    ).stdout.toString().trim();
    expect(python, isNotEmpty, reason: 'python3 not found on PATH');
    Link(join([fakeBin.path, 'python3'])).createSync(python);
    writeFake('keytool', 'echo "Owner: CN=Upload, O=Test"');
  });

  tearDown(() => root.deleteSync(recursive: true));

  ProcessResult run(
    String shell,
    String script,
    List<String> args, {
    Map<String, String> env = const {},
    String? cwd,
  }) =>
      Process.runSync(
        shell,
        [
          join([root.path, 'tool', script]),
          ...args
        ],
        environment: {...env, 'PATH': '${fakeBin.path}:/usr/bin:/bin'},
        includeParentEnvironment: false,
        workingDirectory: cwd,
      );

  ProcessResult play(
    List<String> args, {
    Map<String, String> env = const {},
    String? cwd,
  }) =>
      run('/bin/bash', 'build_play_release.sh', args, env: env, cwd: cwd);

  ProcessResult ios(
    List<String> args, {
    Map<String, String> env = const {},
    String? cwd,
  }) =>
      run('/bin/sh', 'build_ios_release.sh', args, env: env, cwd: cwd);

  /// Output is free of the canary, ESC, CR and any line a CI runner would read
  /// as a workflow command.
  void expectClean(ProcessResult r) {
    for (final (name, text) in [
      ('stdout', '${r.stdout}'),
      ('stderr', '${r.stderr}'),
    ]) {
      expect(text, isNot(contains(canary)), reason: '$name holds the canary');
      expect(text, isNot(contains('\x1b')), reason: '$name holds ESC');
      expect(text, isNot(contains('\r')), reason: '$name holds CR');
      expect(
        text.split('\n').where((line) => line.trimLeft().startsWith('::')),
        isEmpty,
        reason: '$name has a line starting with ::',
      );
    }
  }

  void expectOutput(
    ProcessResult r,
    int exitCode, {
    String stdout = '',
    String stderr = '',
  }) {
    expectClean(r);
    expect(r.exitCode, exitCode, reason: '${r.stdout}${r.stderr}');
    expect(r.stdout, stdout);
    expect(r.stderr, stderr);
  }

  /// A zip at [path] holding [entries] (name -> content).
  File writeZipAt(String path, Map<String, String> entries) {
    File(path).parent.createSync(recursive: true);
    final result = Process.runSync('python3', [
      '-I',
      '-c',
      'import sys, zipfile\n'
          'z = zipfile.ZipFile(sys.argv[1], "w")\n'
          'a = sys.argv[2:]\n'
          'for n, v in zip(a[::2], a[1::2]): z.writestr(n, v)\n'
          'z.close()',
      path,
      for (final e in entries.entries) ...[e.key, e.value],
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    return File(path);
  }

  File writeZip(String name, Map<String, String> entries) =>
      writeZipAt(join([root.path, name]), entries);

  File hostileAab() => writeZip(hostile, {
        'base/manifest/AndroidManifest.xml': 'x',
        'base/resources.pb': 'x',
      });

  String missingPath() => '${root.path}${Platform.pathSeparator}$hostile';

  const certSection = '\n== signing certificate\n'
      'Owner: CN=Upload, O=Test\n'
      'Signing certificate is not the Android Debug certificate.\n';

  const playVersionLine =
      'pubspec.yaml version: 1.0.0+9 (versionCode 9); minimum 2\n';

  // TH-941: the Play script reads the AAB package before the versionCode and
  // fails unless it is the app ID. This fake bundletool answers the package
  // query with the app ID and the versionCode query with 5 (synthetic).
  const appId = 'com.TetherHealthLLC.tetherhealth';
  const bundletoolOk = 'case "\$*" in\n'
      '  *--xpath=/manifest/@package*) echo $appId ;;\n'
      '  *) echo 5 ;;\n'
      'esac';
  const packageLine = 'package: $appId (read from the AAB); expected $appId\n';

  group('build_play_release.sh', () {
    const notPositive = 'must be a positive integer (value not shown)';

    test('a bad --min-version-code / --build-number value is not shown', () {
      for (final args in [
        ['--min-version-code=$hostile'],
        ['--build-number=$hostile'],
        ['--min-version-code', hostile],
        ['--build-number', hostile],
        // The next argv word is taken as the value.
        ['--build-number', '--k=$hostile'],
        ['--min-version-code', '--k=$hostile'],
      ]) {
        final r = play(['--check-version-only', ...args]);
        expectOutput(
          r,
          2,
          stderr: 'build_play_release: ${args.first.split('=').first} '
              '$notPositive\n',
        );
      }
    });

    test('a missing --verify-aab path is not shown', () {
      expectOutput(
        play(['--verify-aab=${missingPath()}']),
        2,
        stderr: 'build_play_release: AAB not found '
            '(path given to --verify-aab not shown)\n',
      );
    });

    test('a missing --dart-define-from-file path is not shown', () {
      expectOutput(
        play(['--dart-define-from-file=${missingPath()}']),
        2,
        stderr: 'build_play_release: define file not found '
            '(path given to --dart-define-from-file not shown)\n',
      );
    });

    // Assumes the host has neither bundletool nor aapt2 in /usr/bin or /bin
    // (the PATH holds only the fakes and those two directories).
    test('the no-bundletool/aapt2 failure does not name the AAB path', () {
      final aab = hostileAab();
      expectOutput(
        play(['--verify-aab=${aab.path}']),
        1,
        stdout: certSection,
        stderr: 'FAIL: neither bundletool nor aapt2 is installed; cannot read '
            'the package or versionCode from the AAB. Install one and re-run with '
            '--verify-aab=<path> before uploading.\n',
      );
    });

    test('an unreadable versionCode shows neither path nor tool output', () {
      final aab = hostileAab();
      writeFake(
        'bundletool',
        'case "\$*" in\n'
            '  *--xpath=/manifest/@package*) echo $appId ;;\n'
            '  *) printf "%s\\n" "\$FAKE_OUT" ;;\n'
            'esac',
      );
      expectOutput(
        play(['--verify-aab=${aab.path}'], env: {'FAKE_OUT': hostile}),
        1,
        stdout: '$certSection$packageLine',
        stderr: 'FAIL: could not read a numeric versionCode from the AAB '
            '(path and tool output not shown).\n',
      );
    });

    test('an unreadable package shows neither path nor tool output', () {
      final aab = hostileAab();
      writeFake('bundletool', 'printf "%s\\n" "\$FAKE_OUT"');
      for (final out in [hostile, '$appId\n$canary', '$appId $canary']) {
        expectOutput(
          play(['--verify-aab=${aab.path}'], env: {'FAKE_OUT': out}),
          1,
          stdout: certSection,
          stderr: 'FAIL: could not read a valid package name from the AAB '
              '(path and tool output not shown).\n',
        );
      }
    });

    group('keytool is never given the caller path', () {
      late File argvFile;
      late File cwdFile;

      /// A keytool that records its argv and cwd, then runs [tail].
      void fakeKeytool(String tail) {
        argvFile = File(join([root.path, 'keytool_argv']));
        cwdFile = File(join([root.path, 'keytool_cwd']));
        writeFake(
          'keytool',
          'printf "%s\\n" "\$@" > "${argvFile.path}"\n'
              'pwd > "${cwdFile.path}"\n'
              '$tail',
        );
      }

      void expectArgvAndCleanup() {
        expect(argvFile.readAsLinesSync(), [
          '-printcert',
          '-jarfile',
          'bundle.aab',
        ]);
        // The private directory (and its link) is gone afterwards.
        expect(
            Directory(cwdFile.readAsStringSync().trim()).existsSync(), false);
      }

      test('an error that echoes the jar path cannot forge a certificate', () {
        final aab = hostileAab();
        // Like keytool on an unreadable jar: the error names the file. The
        // hostile name holds "Owner:", so any echo would pass the grep and
        // the Owner check.
        fakeKeytool(
          'printf "keytool error: java.io.FileNotFoundException: %s '
          '(Permission denied)\\n" "\$3"',
        );
        final r = play(['--verify-aab=${aab.path}']);
        expectOutput(
          r,
          1,
          stdout: '\n== signing certificate\n'
              'no certificate found (keytool output not shown)\n',
          stderr: 'FAIL: bundle carries no signing certificate.\n',
        );
        expect(
          r.stdout,
          isNot(contains('Signing certificate is not the Android Debug')),
        );
        expectArgvAndCleanup();
      });

      test('a "not signed" line that echoes the jar path shows no path', () {
        final aab = hostileAab();
        fakeKeytool('printf "not signed %s\\n" "\$3"');
        expectOutput(
          play(['--verify-aab=${aab.path}']),
          1,
          stdout: '\n== signing certificate\nnot signed bundle.aab\n',
          stderr: 'FAIL: bundle carries no signing certificate.\n',
        );
        expectArgvAndCleanup();
      });

      test('keytool reads the AAB through the link', () {
        final aab = hostileAab()..writeAsStringSync('named');
        final seen = File(join([root.path, 'seen']));
        fakeKeytool(
          'cat "\$3" > "${seen.path}"\necho "Owner: CN=Upload, O=Test"',
        );
        writeFake('bundletool', bundletoolOk);
        final r = play(['--verify-aab=${aab.path}']);
        expectClean(r);
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
        expect(seen.readAsStringSync(), 'named');
        expectArgvAndCleanup();
      });
    });

    /// Runs a full Play invocation. Fake flutter writes the AAB where the
    /// script expects it, relative to the repo root; keytool records what it
    /// read in [seen]; bundletool runs [bundletool].
    ProcessResult fullPlayBuild(String bundletool, File seen) {
      Directory(join([root.path, 'android'])).createSync();
      File(join([root.path, 'android', 'key.properties']))
          .writeAsStringSync('');
      File(join([root.path, 'tool', 'check_format.sh']))
          .writeAsStringSync('exit 0\n');
      final define = File(join([root.path, 'release.json']))
        ..writeAsStringSync(validDefine);
      writeFake(
        'flutter',
        'case "\$1" in build)\n'
            '  mkdir -p build/app/outputs/bundle/release\n'
            '  printf built > build/app/outputs/bundle/release/app-release.aab\n'
            '  ;; esac',
      );
      writeFake(
        'keytool',
        'cat "\$3" > "${seen.path}"\necho "Owner: CN=Upload, O=Test"',
      );
      writeFake('bundletool', bundletool);
      return play(['--dart-define-from-file=${define.path}']);
    }

    test('a full invocation checks the certificate of the relative AAB', () {
      // keytool must still find the relative AAB through the link.
      final seen = File(join([root.path, 'seen']));
      final r = fullPlayBuild(bundletoolOk, seen);
      expectClean(r);
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      expect(seen.readAsStringSync(), 'built');
      expect(
          r.stdout, contains('Signing certificate is not the Android Debug'));
      // TH-941: the full build reads the package back, then the versionCode.
      expect(
        r.stdout,
        contains('Signing certificate is not the Android Debug certificate.\n'
            '\n$packageLine'
            'versionCode: 5 (read from the AAB); minimum 2\n'),
      );
    });

    test('a full invocation fails when the AAB has another package', () {
      final seen = File(join([root.path, 'seen']));
      for (final other in [
        'com.breathefree.breathefree_patient',
        '$appId.debug',
      ]) {
        final r = fullPlayBuild(
          'case "\$*" in\n'
          '  *--xpath=/manifest/@package*) echo $other ;;\n'
          '  *) echo 5 ;;\n'
          'esac',
          seen,
        );
        expectClean(r);
        expect(r.exitCode, 1, reason: '$other: ${r.stdout}${r.stderr}');
        expect(seen.readAsStringSync(), 'built', reason: other);
        expect(
          r.stdout,
          contains('package: $other (read from the AAB); expected $appId\n'),
          reason: other,
        );
        expect(
          r.stderr,
          'FAIL: AAB package $other is not $appId; Play would reject it as a '
          'different app. Do not upload.\n',
          reason: other,
        );
        expect(r.stdout, isNot(contains('versionCode: 5')), reason: other);
      }
    });
  });

  group('build_ios_release.sh', () {
    test('a missing --inspect-ipa path is not shown', () {
      expectOutput(
        ios(['--inspect-ipa=${missingPath()}']),
        2,
        stderr: 'build_ios_release: IPA not found '
            '(path given to --inspect-ipa not shown)\n',
      );
    });

    test('a missing --dart-define-from-file path is not shown', () {
      expectOutput(
        ios(['--dart-define-from-file=${missingPath()}', '--check-only']),
        2,
        stderr: 'build_ios_release: define file not found '
            '(path given to --dart-define-from-file not shown)\n',
      );
    });

    test('an IPA without an app Info.plist does not name its path', () {
      final ipa = writeZip(hostile, {'Payload/Runner.app/Runner': 'x'});
      expectOutput(
        ios(['--inspect-ipa=${ipa.path}']),
        1,
        stderr: 'build_ios_release: expected one Payload/<app>.app/Info.plist '
            'in the IPA, found 0\n',
      );
    });

    test('an IPA with a version key missing does not name its path', () {
      final ipa = writeZip(hostile, {
        'Payload/Runner.app/Info.plist': plist(
          '1.0.0',
          '7',
        ).replaceAll('CFBundleVersion<', 'Other<'),
      });
      expectOutput(
        ios(['--inspect-ipa=${ipa.path}']),
        1,
        stderr: 'build_ios_release: CFBundleShortVersionString or '
            'CFBundleVersion missing in the IPA\n',
      );
    });

    test('guard (also passes at f1143a6): a non-zip does not name its path',
        () {
      final bad = File(join([root.path, hostile]))
        ..writeAsStringSync('not a zip');
      expectOutput(
        ios(['--inspect-ipa=${bad.path}']),
        1,
        stderr:
            "build_ios_release: cannot read the IPA's Info.plist: BadZipFile\n",
      );
    });

    test('a malformed Info.plist fails with the exception type only', () {
      final ipa = writeZip(hostile, {
        'Payload/Runner.app/Info.plist': '<plist><dict>',
      });
      expectOutput(
        ios(['--inspect-ipa=${ipa.path}']),
        1,
        stderr:
            "build_ios_release: cannot read the IPA's Info.plist: ExpatError\n",
      );
    });
  });

  group('path resolution (the named file is the one used)', () {
    late Directory work;
    late Directory home;
    late Map<String, String> env;

    setUp(() {
      work = Directory(join([root.path, 'work']))..createSync();
      home = Directory(join([root.path, 'home']))..createSync();
      // cd with no argument or "-P"/"-L" goes to HOME, "cd -" to OLDPWD.
      env = {'HOME': home.path, 'OLDPWD': home.path};
    });

    void put(String path, String content) {
      File(path).parent.createSync(recursive: true);
      File(path).writeAsStringSync(content);
    }

    /// Relative arguments that a cd/dirname/basename based resolution maps to
    /// a different file than the one named. The named file is written with
    /// `write(path, named: true)`, every decoy it could be mistaken for with
    /// `named: false`.
    List<(String, String)> hazards(
      String base,
      void Function(String path, {required bool named}) write,
    ) {
      final out = <(String, String)>[];
      write(join([home.path, base]), named: false);
      for (final dir in ['-P', '-L', '-', '-e']) {
        write(join([work.path, dir, base]), named: true);
        out.add(('directory $dir', '$dir/$base'));
      }
      // lnk/../base is other/base for the kernel, work/base logically.
      final other = Directory(join([root.path, 'other', 'sub']))
        ..createSync(recursive: true);
      Link(join([work.path, 'lnk'])).createSync(other.path);
      write(join([root.path, 'other', base]), named: true);
      write(join([work.path, base]), named: false);
      out.add(('link/..', 'lnk/../$base'));
      // $(...) would strip the newline and read work/base instead.
      write(join([work.path, '$base\n']), named: true);
      out.add(('trailing LF', '$base\n'));
      return out;
    }

    /// Dash-leading names that are valid files themselves.
    List<String> dashNames() => ['-$canary', '-\x1b$canary'];

    void writeDefineFile(String path, {required bool named}) =>
        put(path, named ? secretDefine : validDefine);

    test('Play --dart-define-from-file reads the named file', () {
      for (final (label, arg) in hazards('d.json', writeDefineFile)) {
        final r =
            play(['--dart-define-from-file=$arg'], cwd: work.path, env: env);
        expectClean(r);
        // The named file is rejected (sb_secret_); the decoy would be valid.
        expect(r.exitCode, 1, reason: '$label: ${r.stdout}${r.stderr}');
        expect(r.stderr, startsWith('build_play_release: '), reason: label);
        expect(r.stderr, isNot(contains('key.properties')), reason: label);
        expect('${r.stdout}${r.stderr}', isNot(contains(cases.canary)));
      }
    });

    test('iOS --dart-define-from-file reads the named file', () {
      for (final (label, arg) in hazards('d.json', writeDefineFile)) {
        final r = ios(
          ['--dart-define-from-file=$arg', '--check-only'],
          cwd: work.path,
          env: env,
        );
        expectClean(r);
        expect(r.exitCode, 1, reason: '$label: ${r.stdout}${r.stderr}');
        expect(r.stdout, '', reason: label);
        expect(r.stderr, startsWith('build_ios_release: '), reason: label);
        expect('${r.stdout}${r.stderr}', isNot(contains(cases.canary)));
      }
    });

    test('Play --verify-aab reads the named file', () {
      final seen = File(join([root.path, 'seen']));
      writeFake(
        'keytool',
        'cat "\$3" > "${seen.path}"\necho "Owner: CN=Upload, O=Test"',
      );
      writeFake('bundletool', bundletoolOk);
      for (final (label, arg) in hazards(
        'app.aab',
        (path, {required named}) => put(path, named ? 'named' : 'decoy'),
      )) {
        if (seen.existsSync()) seen.deleteSync();
        final r = play(['--verify-aab=$arg'], cwd: work.path, env: env);
        expectOutput(
          r,
          0,
          stdout: '$certSection$packageLine'
              'versionCode: 5 (read from the AAB); minimum 2\n',
        );
        expect(seen.readAsStringSync(), 'named', reason: label);
      }
    });

    test('iOS --inspect-ipa reads the named file', () {
      for (final (label, arg) in hazards(
        'app.ipa',
        (path, {required named}) => writeZipAt(path, {
          'Payload/Runner.app/Info.plist':
              named ? plist('1.0.0', '7') : plist('2.0.0', '8'),
        }),
      )) {
        final r = ios(['--inspect-ipa=$arg'], cwd: work.path, env: env);
        expectOutput(
          r,
          0,
          stdout: 'CFBundleShortVersionString: 1.0.0\nCFBundleVersion: 7\n',
        );
        expect(r.exitCode, 0, reason: label);
      }
    });

    test('dash-leading valid names, with and without ESC, resolve', () {
      final seen = File(join([root.path, 'seen']));
      for (final name in dashNames()) {
        // Play define file: reaches the key.properties check.
        put(join([work.path, '$name.json']), validDefine);
        expectOutput(
          play(['--dart-define-from-file=$name.json'], cwd: work.path),
          2,
          stdout: playVersionLine,
          stderr: 'build_play_release: android/key.properties not found '
              '(see docs/PLAY_RELEASE.md)\n',
        );
        // iOS define file.
        expectOutput(
          ios(['--dart-define-from-file=$name.json', '--check-only'],
              cwd: work.path),
          0,
          stdout: 'All pre-build checks passed (no build was run).\n',
        );
        // Play AAB.
        put(join([work.path, '$name.aab']), 'named');
        writeFake(
          'keytool',
          'cat "\$3" > "${seen.path}"\necho "Owner: CN=Upload, O=Test"',
        );
        writeFake('bundletool', bundletoolOk);
        expectOutput(
          play(['--verify-aab=$name.aab'], cwd: work.path),
          0,
          stdout: '$certSection$packageLine'
              'versionCode: 5 (read from the AAB); minimum 2\n',
        );
        expect(seen.readAsStringSync(), 'named');
        // iOS IPA.
        writeZipAt(join([work.path, '$name.ipa']), {
          'Payload/Runner.app/Info.plist': plist('1.0.0', '7'),
        });
        expectOutput(
          ios(['--inspect-ipa=$name.ipa'], cwd: work.path),
          0,
          stdout: 'CFBundleShortVersionString: 1.0.0\nCFBundleVersion: 7\n',
        );
      }
    });
  });
}

String plist(String shortVersion, String bundleVersion) =>
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<plist version="1.0"><dict>'
    '<key>CFBundleShortVersionString</key><string>$shortVersion</string>'
    '<key>CFBundleVersion</key><string>$bundleVersion</string>'
    '</dict></plist>\n';
