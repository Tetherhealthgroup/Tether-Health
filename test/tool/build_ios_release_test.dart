import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'release_define_cases.dart';

// Runs the pre-build checks of tool/build_ios_release.sh (`--check-only`), the
// IPA read-back (`--inspect-ipa=`) and, with a fake flutter, the build path.
// Nothing is built: the scripts are copied into a temporary project root next
// to copies of the real iOS project files and a synthetic pubspec.yaml, and the
// PATH holds only python3 and a fake flutter that records being called. Every
// key is a synthetic canary token.

String join(List<String> parts) => parts.join(Platform.pathSeparator);

void main() {
  late Directory root;
  late File flutterMarker;
  late String scriptPath;

  File inRoot(String relative) =>
      File(join([root.path, ...relative.split('/')]));

  setUp(() {
    root = Directory.systemTemp.createTempSync('ios_release_test_');
    final repo = Directory.current.path;
    for (final relative in [
      'tool/build_ios_release.sh',
      'tool/release_define_check.sh',
      // The real project files, so the CocoaPods check is run against them.
      'ios/Runner.xcodeproj/project.pbxproj',
      'ios/Flutter/Debug.xcconfig',
      'ios/Flutter/Release.xcconfig',
    ]) {
      inRoot(relative).parent.createSync(recursive: true);
      File(join([repo, ...relative.split('/')]))
          .copySync(inRoot(relative).path);
    }
    // Synthetic, so the build-number minimum (2) does not follow the real one.
    inRoot('pubspec.yaml').writeAsStringSync('name: x\nversion: 1.0.0+2\n');
    scriptPath = inRoot('tool/build_ios_release.sh').path;
    final fakeBin = Directory(join([root.path, 'bin']))..createSync();
    final python = Process.runSync('which', ['python3']).stdout.toString();
    Link(join([fakeBin.path, 'python3'])).createSync(python.trim());
    flutterMarker = File(join([root.path, 'flutter_ran']));
    final flutter = File(join([fakeBin.path, 'flutter']))
      ..writeAsStringSync('#!/bin/sh\ntouch "${flutterMarker.path}"\nexit 1\n');
    Process.runSync('chmod', ['+x', flutter.path]);
  });

  tearDown(() => root.deleteSync(recursive: true));

  ProcessResult run(
    List<String> args, {
    String? cwd,
    Map<String, String> env = const {},
  }) =>
      Process.runSync(
        '/bin/sh',
        [scriptPath, ...args],
        environment: {...env, 'PATH': '${root.path}/bin:/usr/bin:/bin'},
        includeParentEnvironment: false,
        workingDirectory: cwd,
      );

  String output(ProcessResult r) => '${r.stdout}${r.stderr}';

  File writeDefine(String contents, {String name = 'release.json'}) =>
      File(join([root.path, name]))..writeAsStringSync(contents);

  ProcessResult checkOnly(String contents) => run([
        '--dart-define-from-file=${writeDefine(contents).path}',
        '--check-only'
      ]);

  final valid = defineCases.firstWhere((c) => c.accepted).contents;

  group('--check-only define file', () {
    for (final c in defineCases) {
      test('${c.accepted ? 'accepts' : 'rejects'} ${c.name}', () {
        final r = checkOnly(c.contents);
        final out = output(r);
        if (c.accepted) {
          expect(r.exitCode, 0, reason: out);
          expect(out, contains('no build was run'));
        } else {
          expect(r.exitCode, 1, reason: out);
          expect(r.stderr, contains('build_ios_release: '));
          for (final fragment in c.expected) {
            expect(r.stderr, contains(fragment));
          }
          expect(out, isNot(contains('no build was run')));
        }
        for (final fragment in c.absent) {
          expect(out, isNot(contains(fragment)));
        }
        expect(out, isNot(contains(canary)));
        for (final window in canaryWindows) {
          expect(out, isNot(contains(window)), reason: 'canary window leaked');
        }
        for (final stream in [r.stdout, r.stderr]) {
          expect(stream, isNot(contains(keyCanary)));
        }
        if (c.keyValue case final key? when key.trim().isNotEmpty) {
          expect(out, isNot(contains(key.trim())));
        }
        expect(flutterMarker.existsSync(), isFalse);
      });
    }
  });

  test('a define file nested too deeply fails closed without a traceback', () {
    final r = checkOnly(deepNestingDefine(2000000));
    final out = output(r);
    expect(r.exitCode, 1, reason: out);
    expect(r.stderr, contains('build_ios_release: cannot check define file'));
    expect(out, isNot(contains('Traceback')));
    expect(out, isNot(contains(canary)));
    expect(flutterMarker.existsSync(), isFalse);
  });

  group('--check-only CocoaPods guard', () {
    void expectRejected(ProcessResult r, String fragment) {
      expect(r.exitCode, 1, reason: output(r));
      expect(r.stderr, contains(fragment));
      expect(flutterMarker.existsSync(), isFalse);
    }

    test('the real project files pass', () {
      expect(checkOnly(valid).exitCode, 0);
    });

    test('rejects an ios/Podfile', () {
      inRoot('ios/Podfile').writeAsStringSync("platform :ios, '13.0'\n");
      expectRejected(checkOnly(valid), 'ios/Podfile exists');
    });

    test('rejects Pods references in project.pbxproj', () {
      final pbxproj = inRoot('ios/Runner.xcodeproj/project.pbxproj');
      final original = pbxproj.readAsStringSync();
      for (final line in [
        '/* Pods_Runner.framework */',
        '/* [CP] Check Pods Manifest.lock */',
        'path = "Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig";',
      ]) {
        pbxproj.writeAsStringSync('$original\n$line\n');
        expectRejected(
            checkOnly(valid), 'project.pbxproj references CocoaPods');
      }
    });

    test('rejects a Pods include in an xcconfig', () {
      inRoot('ios/Flutter/Release.xcconfig').writeAsStringSync(
        '#include? "Pods/Target Support Files/Pods-Runner/'
        'Pods-Runner.release.xcconfig"\n#include "Generated.xcconfig"\n',
      );
      expectRejected(checkOnly(valid), 'Release.xcconfig includes a CocoaPods');
    });

    test('the CocoaPods guard runs before the define file is read', () {
      inRoot('ios/Podfile').writeAsStringSync('');
      final r = checkOnly('{}');
      expectRejected(r, 'ios/Podfile exists');
      expect(output(r), isNot(contains('missing or empty')));
    });

    test('an unreadable project.pbxproj fails instead of passing', () {
      final pbxproj = inRoot('ios/Runner.xcodeproj/project.pbxproj');
      Process.runSync('chmod', ['000', pbxproj.path]);
      addTearDown(() => Process.runSync('chmod', ['644', pbxproj.path]));
      final readable = Process.runSync('/bin/sh', [
        '-c',
        'test -r "\$1"',
        'sh',
        pbxproj.path,
      ]);
      if (readable.exitCode == 0) {
        markTestSkipped('running as a user who can read a mode-000 file');
        return;
      }
      expectRejected(checkOnly(valid), 'cannot read ios/Runner.xcodeproj');
    });

    test('a name that merely ends in Pods is not a CocoaPods reference', () {
      final pbxproj = inRoot('ios/Runner.xcodeproj/project.pbxproj');
      pbxproj.writeAsStringSync(
        '${pbxproj.readAsStringSync()}\n/* AirPods.swift */\n',
      );
      expect(checkOnly(valid).exitCode, 0);
    });
  });

  group('argument validation', () {
    test('requires --dart-define-from-file', () {
      final r = run(['--check-only']);
      expect(r.exitCode, 2);
      expect(output(r), contains('--dart-define-from-file=<path> is required'));
    });

    test('rejects an empty or missing define file path', () {
      expect(run(['--dart-define-from-file=', '--check-only']).exitCode, 2);
      final r = run([
        '--dart-define-from-file=${root.path}/nope.json',
        '--check-only',
      ]);
      expect(r.exitCode, 2);
      expect(output(r), contains('define file not found'));
    });

    test('rejects unknown arguments, including the space-separated form', () {
      final define = writeDefine(valid).path;
      expect(run(['--check-only', '--bogus']).exitCode, 2);
      expect(
        run(['--dart-define-from-file', define, '--check-only']).exitCode,
        2,
      );
    });

    test('never prints the value of an unknown argument', () {
      const secret = 'TH121CANARY';
      final define = writeDefine(valid).path;
      for (final (arg, shown) in [
        ('--supabase-anon-key=$secret', '--supabase-anon-key'),
        ('--x=a=$secret', '--x'),
        ('--check-only=$secret', '--check-only'),
        ('=$secret', null),
        (secret, null),
        ('$secret==', null), // base64 padding: not an option name
        ('--foo\n$secret=x', null),
        ('', null),
      ]) {
        final r = run(['--dart-define-from-file=$define', '--check-only', arg]);
        expect(r.exitCode, 2, reason: arg);
        expect(r.stdout, isNot(contains(secret)), reason: arg);
        expect(r.stderr, isNot(contains(secret)), reason: arg);
        expect(
          r.stderr,
          shown == null
              ? 'build_ios_release: unknown argument (not shown; see the '
                  'usage at the top of tool/build_ios_release.sh)\n'
              : 'build_ios_release: unknown argument: '
                  '$shown=<value not shown>\n',
          reason: arg,
        );
        expect(flutterMarker.existsSync(), isFalse);
      }
    });

    test('rejects a repeated --dart-define-from-file', () {
      final define = writeDefine(valid).path;
      final r = run([
        '--dart-define-from-file=$define',
        '--dart-define-from-file=$define',
        '--check-only',
      ]);
      expect(r.exitCode, 2);
      expect(output(r), contains('given more than once'));
    });

    test('a set CDPATH does not corrupt a relative define path', () {
      final cwd = Directory(join([root.path, 'caller']))..createSync();
      File(join([cwd.path, 'release.json'])).writeAsStringSync(valid);
      // cd caller is looked up through CDPATH, which makes cd print it.
      final r = run(
        ['--dart-define-from-file=caller/release.json', '--check-only'],
        cwd: root.path,
        env: {'CDPATH': root.path},
      );
      expect(r.exitCode, 0, reason: output(r));
    });

    test('a relative define path resolves against the caller cwd', () {
      final cwd = Directory(join([root.path, 'caller']))..createSync();
      File(join([cwd.path, 'release.json'])).writeAsStringSync(valid);
      final found = run(
        ['--dart-define-from-file=release.json', '--check-only'],
        cwd: cwd.path,
      );
      expect(found.exitCode, 0, reason: output(found));
      // Present only at the repo root: must NOT be picked up silently.
      writeDefine(valid, name: 'only_at_root.json');
      final missing = run(
        ['--dart-define-from-file=only_at_root.json', '--check-only'],
        cwd: cwd.path,
      );
      expect(missing.exitCode, 2);
      expect(output(missing), contains('define file not found'));
    });

    test('--inspect-ipa cannot be combined with a build', () {
      final define = writeDefine(valid).path;
      final r = run(['--inspect-ipa=x.ipa', '--dart-define-from-file=$define']);
      expect(r.exitCode, 2);
      expect(output(r), contains('cannot be combined'));
      expect(flutterMarker.existsSync(), isFalse);
    });
  });

  group('--inspect-ipa', () {
    String plist(String shortVersion, String bundleVersion) =>
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<plist version="1.0"><dict>'
        '<key>CFBundleShortVersionString</key><string>$shortVersion</string>'
        '<key>CFBundleVersion</key><string>$bundleVersion</string>'
        '</dict></plist>\n';

    /// A zip with the layout of a real IPA, holding [entries].
    File writeIpa(Map<String, String> entries) {
      final path = join([root.path, 'app.ipa']);
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

    test("prints the app's version, not a framework's", () {
      final ipa = writeIpa({
        'Payload/Runner.app/Frameworks/Flutter.framework/Info.plist':
            plist('9.9.9', '999'),
        'Payload/Runner.app/Info.plist': plist('1.0.0', '7'),
      });
      final r = run(['--inspect-ipa=${ipa.path}']);
      expect(r.exitCode, 0, reason: output(r));
      expect(r.stdout, contains('CFBundleShortVersionString: 1.0.0'));
      expect(r.stdout, contains('CFBundleVersion: 7'));
      expect(output(r), isNot(contains('9.9.9')));
    });

    test('fails when the app Info.plist or a version key is missing', () {
      var ipa = writeIpa({'Payload/Runner.app/Runner': 'x'});
      var r = run(['--inspect-ipa=${ipa.path}']);
      expect(r.exitCode, 1);
      expect(output(r), contains('found 0'));
      ipa = writeIpa({
        'Payload/Runner.app/Info.plist':
            plist('1.0.0', '7').replaceAll('CFBundleVersion<', 'Other<'),
      });
      r = run(['--inspect-ipa=${ipa.path}']);
      expect(r.exitCode, 1);
      expect(output(r), contains('missing'));
    });

    test('fails on a file that is not a zip, and on a missing IPA', () {
      final notZip = writeDefine('not a zip', name: 'bad.ipa');
      expect(run(['--inspect-ipa=${notZip.path}']).exitCode, 1);
      final missing = run(['--inspect-ipa=${root.path}/nope.ipa']);
      expect(missing.exitCode, 2);
      expect(output(missing), contains('IPA not found'));
      expect(run(['--inspect-ipa=']).exitCode, 2);
    });
  });
  group('--build-number', () {
    const minimumError = 'build_ios_release: --build-number must be a '
        'positive integer (value not shown)\n';
    const rangeError =
        'build_ios_release: --build-number must be between 1 and 2100000000\n';

    ProcessResult checkNumber(List<String> numberArgs) => run([
          '--dart-define-from-file=${writeDefine(valid).path}',
          ...numberArgs,
          '--check-only',
        ]);

    test('accepts a positive integer at or above the pubspec number', () {
      for (final (given, shown) in [
        ('2', '2'),
        ('3', '3'),
        ('0007', '7'),
        ('2100000000', '2100000000'),
      ]) {
        for (final args in [
          ['--build-number', given],
          ['--build-number=$given'],
        ]) {
          final r = checkNumber(args);
          expect(r.exitCode, 0, reason: '$args: ${output(r)}');
          expect(
            r.stdout,
            contains('CFBundleVersion: $shown (from --build-number; '
                'overrides pubspec.yaml); minimum 2 '
                '(the pubspec.yaml build number)\n'),
            reason: '$args',
          );
          expect(r.stdout, contains('no build was run'), reason: '$args');
          expect(flutterMarker.existsSync(), isFalse);
        }
      }
    });

    test('refuses a value that is not all digits, without showing it', () {
      for (final value in [
        'abc',
        '1.2',
        '-3',
        '+3',
        ' 5',
        '5 ',
        '1e3',
        '0x10',
        '\u0663',
        '12TH1009CANARY',
        '5\n6',
      ]) {
        for (final args in [
          ['--build-number', value],
          ['--build-number=$value'],
        ]) {
          final r = checkNumber(args);
          expect(r.exitCode, 2, reason: '$args');
          expect(r.stderr, minimumError, reason: '$args');
          expect(r.stdout, '', reason: '$args');
          expect(output(r), isNot(contains('CANARY')));
          expect(flutterMarker.existsSync(), isFalse);
        }
      }
    });

    test('refuses zero and values above the limit', () {
      for (final value in [
        '0',
        '000',
        '2100000001',
        '9999999999',
        '99999999999',
        '123456789012345678901234567890',
      ]) {
        final r = checkNumber(['--build-number', value]);
        expect(r.exitCode, 2, reason: value);
        expect(r.stderr, rangeError, reason: value);
        expect(r.stdout, '', reason: value);
      }
    });

    test('refuses a number below the pubspec build number', () {
      var r = checkNumber(['--build-number', '1']);
      expect(r.exitCode, 1, reason: output(r));
      expect(
        r.stderr,
        'build_ios_release: --build-number 1 is below the minimum 2 '
        '(the pubspec.yaml build number).\n',
      );
      expect(r.stdout, isNot(contains('no build was run')));

      inRoot('pubspec.yaml').writeAsStringSync('name: x\nversion: 1.2.0+09\n');
      r = checkNumber(['--build-number=8']);
      expect(r.exitCode, 1, reason: output(r));
      expect(r.stderr, contains('below the minimum 9'));
      r = checkNumber(['--build-number=9']);
      expect(r.exitCode, 0, reason: output(r));
      expect(r.stdout, contains('CFBundleVersion: 9 (from --build-number'));
      expect(flutterMarker.existsSync(), isFalse);
    });

    test('refuses an empty value and a missing value', () {
      var r = checkNumber(['--build-number=']);
      expect(r.exitCode, 2);
      expect(r.stderr, minimumError);
      r = run([
        '--dart-define-from-file=${writeDefine(valid).path}',
        '--check-only',
        '--build-number',
      ]);
      expect(r.exitCode, 2);
      expect(r.stderr, 'build_ios_release: --build-number requires a value\n');
      r = checkNumber(['--build-number', '']);
      expect(r.exitCode, 2);
      expect(r.stderr, minimumError);
    });

    test('refuses --build-number given more than once', () {
      for (final args in [
        ['--build-number', '3', '--build-number', '3'],
        ['--build-number=3', '--build-number=4'],
        ['--build-number', '3', '--build-number=4'],
      ]) {
        final r = checkNumber(args);
        expect(r.exitCode, 2, reason: '$args');
        expect(
          r.stderr,
          'build_ios_release: --build-number given more than once\n',
          reason: '$args',
        );
      }
    });

    test('a pubspec without a build number cannot be checked against', () {
      inRoot('pubspec.yaml').writeAsStringSync('name: x\nversion: 1.0.0\n');
      var r = checkNumber(['--build-number', '5']);
      expect(r.exitCode, 1, reason: output(r));
      expect(r.stderr, contains('pubspec.yaml version has no +<build number>'));
      // Without the flag the pubspec is not read: the result is unchanged.
      r = checkOnly(valid);
      expect(r.exitCode, 0, reason: output(r));
      expect(r.stdout, 'All pre-build checks passed (no build was run).\n');
    });

    test('without the flag, --check-only output is unchanged', () {
      final r = checkOnly(valid);
      expect(r.exitCode, 0, reason: output(r));
      expect(r.stdout, 'All pre-build checks passed (no build was run).\n');
      expect(r.stderr, '');
    });

    test('is checked only after the define file passes', () {
      final r = run([
        '--dart-define-from-file=${writeDefine('{}').path}',
        '--build-number',
        '1',
        '--check-only',
      ]);
      expect(r.exitCode, 1);
      expect(r.stdout, '');
      expect(r.stderr, isNot(contains('below the minimum')));
    });

    test('cannot be combined with --inspect-ipa', () {
      for (final args in [
        ['--inspect-ipa=x.ipa', '--build-number', '5'],
        ['--build-number=5', '--inspect-ipa=x.ipa'],
      ]) {
        final r = run(args);
        expect(r.exitCode, 2, reason: '$args');
        expect(output(r), contains('cannot be combined'), reason: '$args');
      }
    });
  });

  group('build with a fake flutter', () {
    late File flutterLog;
    late String define;

    setUp(() {
      flutterLog = File(join([root.path, 'flutter_log']));
      define = writeDefine(valid).path;
      // The format gate is the repo's own script; stub it in the copy.
      inRoot('tool/check_format.sh').writeAsStringSync('exit 0\n');
      final makeIpa = inRoot('make_ipa.py')
        ..writeAsStringSync(
          'import plistlib, sys, zipfile\n'
          'info = {"CFBundleShortVersionString": "1.0.0",'
          ' "CFBundleVersion": sys.argv[2]}\n'
          'with zipfile.ZipFile(sys.argv[1], "w") as z:\n'
          '    z.writestr("Payload/Runner.app/Info.plist",'
          ' plistlib.dumps(info))\n',
        );
      // Records each call as [arg][arg]...; `build ipa` writes an IPA whose
      // CFBundleVersion is the --build-number given (or the pubspec's 2),
      // unless FAKE_IGNORE_BUILD_NUMBER is set.
      inRoot('bin/flutter').writeAsStringSync(r'''#!/bin/sh
for a in "$@"; do printf '[%s]' "$a" >> "LOG"; done
echo >> "LOG"
if [ "$1" = build ]; then
  bn=2
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --build-number) [ -n "${FAKE_IGNORE_BUILD_NUMBER:-}" ] || bn="$2" ;;
    esac
    shift
  done
  mkdir -p build/ios/ipa
  python3 -I "MAKE_IPA" build/ios/ipa/Runner.ipa "$bn"
fi
exit 0
'''
          .replaceAll('LOG', flutterLog.path)
          .replaceAll('MAKE_IPA', makeIpa.path));
    });

    List<String> calls() => flutterLog.existsSync()
        ? flutterLog.readAsLinesSync()
        : const <String>[];

    test('passes --build-number to flutter build ipa', () {
      for (final args in [
        ['--build-number', '5'],
        ['--build-number=005'],
      ]) {
        if (flutterLog.existsSync()) flutterLog.deleteSync();
        final r = run(['--dart-define-from-file=$define', ...args]);
        expect(r.exitCode, 0, reason: '$args: ${output(r)}');
        expect(calls(), [
          '[analyze]',
          '[test]',
          '[build][ipa][--release][--dart-define-from-file=$define]'
              '[--build-number][5]',
        ]);
        expect(r.stdout, contains('CFBundleVersion: 5 (from --build-number'));
        expect(r.stdout, contains('\nCFBundleVersion: 5\n'));
      }
    });

    test('without the flag the flutter invocation is unchanged', () {
      final r = run(['--dart-define-from-file=$define']);
      expect(r.exitCode, 0, reason: output(r));
      expect(calls(), [
        '[analyze]',
        '[test]',
        '[build][ipa][--release][--dart-define-from-file=$define]',
      ]);
      expect(r.stdout, contains('== flutter build ipa --release\n'));
      expect(r.stdout, contains('\nCFBundleVersion: 2\n'));
    });

    test('fails when the IPA does not carry the requested number', () {
      final r = run(
        ['--dart-define-from-file=$define', '--build-number', '5'],
        env: {'FAKE_IGNORE_BUILD_NUMBER': '1'},
      );
      expect(r.exitCode, 1, reason: output(r));
      expect(r.stdout, contains('\nCFBundleVersion: 2\n'));
      expect(
        r.stderr,
        "build_ios_release: the IPA's CFBundleVersion is not 5 "
        '(the --build-number given); do not upload it\n',
      );
    });

    test('a refused number never reaches flutter', () {
      for (final args in [
        ['--build-number', '1'],
        ['--build-number', '0'],
        ['--build-number', 'x'],
      ]) {
        final r = run(['--dart-define-from-file=$define', ...args]);
        expect(r.exitCode, isNonZero, reason: '$args');
        expect(calls(), isEmpty, reason: '$args');
      }
    });
  });
}
