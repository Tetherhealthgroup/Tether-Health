import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The internal test build switch (--internal-tether-ui) of
// tool/build_play_release.sh and tool/build_ios_release.sh, and the internal
// define check in tool/release_define_check.sh. Nothing is built or signed:
// the scripts are copied into a temporary project root next to a synthetic
// pubspec.yaml, and flutter, keytool and aapt2 are fakes on a private PATH.
// STAGING_HOSTS is set in each copy (empty unless a test lists hosts), so the
// tests do not depend on the hosts the owner adds later. Every value is
// synthetic.

String join(List<String> parts) => parts.join(Platform.pathSeparator);

const appId = 'com.TetherHealthLLC.tetherhealth';
const publishable = 'sb_publishable_SyntheticStagingKey000';
const sandboxDefine = '{"TETHER_BACKEND": "sandbox"}';
const storeDefine = '{"SUPABASE_URL": "https://prodref.supabase.co", '
    '"API_BASE_URL": "https://api.example.com", '
    '"SUPABASE_ANON_KEY": "$publishable"}';
const stagingHosts = [
  'stagingref.supabase.co',
  'tether-api-staging.onrender.com',
  'tether-thsync-staging.onrender.com',
];

String httpDefine({
  String supabase = 'https://stagingref.supabase.co',
  String api = 'https://tether-api-staging.onrender.com',
  String? sync = 'https://tether-thsync-staging.onrender.com',
  String key = publishable,
}) =>
    '{"TETHER_BACKEND": "http", "SUPABASE_URL": "$supabase", '
    '"API_BASE_URL": "$api", '
    '${sync == null ? '' : '"SYNC_BASE_URL": "$sync", '}'
    '"SUPABASE_ANON_KEY": "$key"}';

const emptyHostsMessage = 'http mode is refused: STAGING_HOSTS in '
    'tool/release_define_check.sh is empty until the staging backend exists';
const flagInFile = 'TETHER_UI_INTERNAL must not be in the define file '
    '(--internal-tether-ui adds it)';

final _hostsList = RegExp(r'STAGING_HOSTS = frozenset\(\([^)]*\)\)');

/// tool/release_define_check.sh with STAGING_HOSTS replaced by [hosts].
String defineCheckWith(List<String> hosts) {
  final source = File('tool/release_define_check.sh').readAsStringSync();
  expect(_hostsList.allMatches(source), hasLength(1));
  return source.replaceFirst(
    _hostsList,
    'STAGING_HOSTS = frozenset((\n'
    '${hosts.map((h) => '    "$h",\n').join()}))',
  );
}

void main() {
  late Directory root;
  late File flutterLog;

  File inRoot(String relative) =>
      File(join([root.path, ...relative.split('/')]));

  void writeExecutable(String relative, String body) {
    final file = inRoot(relative)..parent.createSync(recursive: true);
    file.writeAsStringSync(body);
    Process.runSync('chmod', ['+x', file.path]);
  }

  void useHosts(List<String> hosts) => inRoot('tool/release_define_check.sh')
      .writeAsStringSync(defineCheckWith(hosts));

  setUp(() {
    root = Directory.systemTemp.createTempSync('internal_tether_ui_test_');
    final repo = Directory.current.path;
    for (final relative in [
      'tool/build_play_release.sh',
      'tool/build_ios_release.sh',
      'ios/Runner.xcodeproj/project.pbxproj',
      'ios/Flutter/Debug.xcconfig',
      'ios/Flutter/Release.xcconfig',
    ]) {
      inRoot(relative).parent.createSync(recursive: true);
      File(join([repo, ...relative.split('/')]))
          .copySync(inRoot(relative).path);
    }
    useHosts(const []);
    inRoot('tool/check_format.sh').writeAsStringSync('exit 0\n');
    inRoot('pubspec.yaml').writeAsStringSync('name: x\nversion: 1.0.0+2\n');
    inRoot('android/key.properties')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('# synthetic, never read by the fakes\n');
    final python = Process.runSync('which', ['python3']).stdout.toString();
    inRoot('bin/python3').parent.createSync(recursive: true);
    Link(inRoot('bin/python3').path).createSync(python.trim());
    flutterLog = inRoot('flutter_log');
    final makeBundle = inRoot('make_bundle.py')
      ..writeAsStringSync(
        'import plistlib, sys, zipfile\n'
        'with zipfile.ZipFile(sys.argv[1], "w") as z:\n'
        '    if sys.argv[2] == "aab":\n'
        '        z.writestr("base/manifest/AndroidManifest.xml", "synthetic")\n'
        '        z.writestr("base/resources.pb", "synthetic")\n'
        '    else:\n'
        '        info = {"CFBundleShortVersionString": "1.0.0",'
        ' "CFBundleVersion": "2"}\n'
        '        z.writestr("Payload/Runner.app/Info.plist",'
        ' plistlib.dumps(info))\n',
      );
    // Records each call as [arg][arg]...; `build appbundle` writes an AAB and
    // records the --build-name it got (the fake aapt2 reports it as the
    // versionName) unless FAKE_IGNORE_BUILD_NAME is set; `build ipa` writes an
    // IPA. FAKE_FAIL_BUILD makes a build fail.
    writeExecutable(
        'bin/flutter',
        r'''#!/bin/sh
for a in "$@"; do printf '[%s]' "$a" >> "LOG"; done
echo >> "LOG"
if [ "$1" = build ]; then
  [ -z "${FAKE_FAIL_BUILD:-}" ] || exit 1
  if [ "$2" = appbundle ]; then
    name=1.0.0
    for a in "$@"; do
      case "$a" in
        --build-name=*) [ -n "${FAKE_IGNORE_BUILD_NAME:-}" ] || name="${a#--build-name=}" ;;
      esac
    done
    mkdir -p build/app/outputs/bundle/release
    python3 -I "MAKE" build/app/outputs/bundle/release/app-release.aab aab
    printf '%s' "$name" > "ROOT/version_name"
  else
    mkdir -p build/ios/ipa
    python3 -I "MAKE" build/ios/ipa/Runner.ipa ipa
  fi
fi
exit 0
'''
            .replaceAll('LOG', flutterLog.path)
            .replaceAll('MAKE', makeBundle.path)
            .replaceAll('ROOT', root.path));
    writeExecutable(
        'bin/keytool', '#!/bin/sh\necho "Owner: CN=Upload, O=Test"\n');
    // Real aapt2 output shape (attribute names carry the namespace URI).
    writeExecutable('bin/aapt2', '''#!/bin/sh
[ "\$1 \$2 \$3 \$4" = "dump xmltree --file AndroidManifest.xml" ] || exit 1
name="\$(cat "${root.path}/version_name")"
echo "N: android=http://schemas.android.com/apk/res/android (line=2)"
echo "  E: manifest (line=2)"
echo "    A: http://schemas.android.com/apk/res/android:versionCode(0x0101021b)=2"
echo "    A: http://schemas.android.com/apk/res/android:versionName(0x0101021c)=\\"\$name\\" (Raw: \\"\$name\\")"
echo "    A: package=\\"$appId\\" (Raw: \\"$appId\\")"
''');
  });

  tearDown(() => root.deleteSync(recursive: true));

  String define(String contents) =>
      (inRoot('define.json')..writeAsStringSync(contents)).path;

  ProcessResult run(String shell, String script, List<String> args,
          {Map<String, String> env = const {}}) =>
      Process.runSync(
        shell,
        [inRoot('tool/$script').path, ...args],
        environment: {...env, 'PATH': '${root.path}/bin:/usr/bin:/bin'},
        includeParentEnvironment: false,
      );

  ProcessResult play(List<String> args, {Map<String, String> env = const {}}) =>
      run('/bin/bash', 'build_play_release.sh', args, env: env);

  ProcessResult ios(List<String> args, {Map<String, String> env = const {}}) =>
      run('/bin/sh', 'build_ios_release.sh', args, env: env);

  String output(ProcessResult r) => '${r.stdout}${r.stderr}';

  List<String> calls() =>
      flutterLog.existsSync() ? flutterLog.readAsLinesSync() : const [];

  // The internal define check, sourced as the scripts source it.
  ProcessResult internalCheck(String contents) => Process.runSync(
        '/bin/sh',
        [
          '-c',
          '. "\$1" && check_internal_define_file t "\$2"',
          'sh',
          inRoot('tool/release_define_check.sh').path,
          define(contents),
        ],
        environment: {'PATH': '${root.path}/bin:/usr/bin:/bin'},
        includeParentEnvironment: false,
      );

  group('Play script', () {
    test('without the flag the flutter calls are exactly as before', () {
      final file = define(storeDefine);
      for (final env in [
        const <String, String>{},
        // No environment variable can turn the internal build on.
        const {
          'TETHER_UI_INTERNAL': 'true',
          'INTERNAL_TETHER_UI': '1',
          'TETHER_UI': 'true',
        },
      ]) {
        if (flutterLog.existsSync()) flutterLog.deleteSync();
        final r = play(['--dart-define-from-file=$file'], env: env);
        expect(r.exitCode, 0, reason: output(r));
        expect(calls(), [
          '[pub][get]',
          '[analyze]',
          '[test]',
          '[build][appbundle][--release][--dart-define-from-file=$file]',
        ]);
        expect(output(r), isNot(contains('INTERNAL')));
        expect(output(r), isNot(contains('versionName')));
        // (The temporary root's name contains 'internal'.)
        expect(output(r), isNot(contains('internal-ui')));
        expect(output(r), isNot(contains('TETHER_UI_INTERNAL')));
      }
    });

    test('with the flag it adds the define and the version name suffix', () {
      final file = define(sandboxDefine);
      final r = play(['--dart-define-from-file=$file', '--internal-tether-ui']);
      expect(r.exitCode, 0, reason: output(r));
      expect(calls(), [
        '[pub][get]',
        '[analyze]',
        '[test]',
        '[build][appbundle][--release][--dart-define-from-file=$file]'
            '[--dart-define=TETHER_UI_INTERNAL=true]'
            '[--build-name=1.0.0-internal-ui]',
      ]);
      expect(
        r.stdout,
        contains('versionName: 1.0.0-internal-ui (read from the AAB); '
            'expected 1.0.0-internal-ui'),
      );
      expect(
        r.stdout,
        contains(
            'Internal testing track only. Never promote it to production.'),
      );
    });

    test('with the flag and --build-number both reach flutter', () {
      final file = define(sandboxDefine);
      final r = play([
        '--dart-define-from-file=$file',
        '--build-number',
        '7',
        '--internal-tether-ui',
      ]);
      expect(r.exitCode, 0, reason: output(r));
      expect(
        calls().last,
        '[build][appbundle][--release][--dart-define-from-file=$file]'
        '[--build-number=7][--dart-define=TETHER_UI_INTERNAL=true]'
        '[--build-name=1.0.0-internal-ui]',
      );
    });

    test('fails when the AAB does not carry the internal version name', () {
      final r = play(
        [
          '--dart-define-from-file=${define(sandboxDefine)}',
          '--internal-tether-ui'
        ],
        env: {'FAKE_IGNORE_BUILD_NAME': '1'},
      );
      expect(r.exitCode, 1, reason: output(r));
      expect(
        r.stderr,
        contains('FAIL: AAB versionName 1.0.0 is not 1.0.0-internal-ui'),
      );
    });

    test('with the flag a define file holding TETHER_UI_INTERNAL is refused',
        () {
      for (final value in ['true', 'false']) {
        final r = play([
          '--dart-define-from-file='
              '${define('{"TETHER_BACKEND": "sandbox", "TETHER_UI_INTERNAL": "$value"}')}',
          '--internal-tether-ui',
        ]);
        expect(r.exitCode, 1, reason: output(r));
        expect(r.stderr, contains('build_play_release: $flagInFile'));
        expect(calls(), isEmpty);
      }
    });

    test('with the flag an http build is refused while STAGING_HOSTS is empty',
        () {
      final r = play([
        '--dart-define-from-file=${define(httpDefine())}',
        '--internal-tether-ui',
      ]);
      expect(r.exitCode, 1, reason: output(r));
      expect(r.stderr, contains(emptyHostsMessage));
      expect(output(r), isNot(contains('onrender.com')));
      expect(output(r), isNot(contains(publishable)));
      expect(calls(), isEmpty);
    });

    test('with the flag the store define file is refused', () {
      final r = play([
        '--dart-define-from-file=${define(storeDefine)}',
        '--internal-tether-ui',
      ]);
      expect(r.exitCode, 1, reason: output(r));
      expect(r.stderr, contains('TETHER_BACKEND must be "sandbox" or "http"'));
      expect(calls(), isEmpty);
    });

    group('the store build path cannot carry the internal build', () {
      test(
          'without the flag a define file holding TETHER_UI_INTERNAL is '
          'refused', () {
        final r = play([
          '--dart-define-from-file='
              '${define(storeDefine.replaceFirst('{', '{"TETHER_UI_INTERNAL": true, '))}',
        ]);
        expect(r.exitCode, 1, reason: output(r));
        expect(r.stderr, contains('is not an allowed define key'));
        expect(calls(), isEmpty);
      });

      test('without the flag an internal define file is refused', () {
        final r = play(['--dart-define-from-file=${define(sandboxDefine)}']);
        expect(r.exitCode, 1, reason: output(r));
        expect(r.stderr, contains('is not an allowed define key'));
        expect(calls(), isEmpty);
      });

      test('the define or a flag value cannot be passed as an argument', () {
        final file = define(storeDefine);
        for (final extra in [
          '--dart-define=TETHER_UI_INTERNAL=true',
          '--internal-tether-ui=true',
          '--internal-tether-ui=1',
          '--INTERNAL-TETHER-UI',
          '--internal_tether_ui',
        ]) {
          final r = play(['--dart-define-from-file=$file', extra]);
          expect(r.exitCode, 2, reason: extra);
          expect(r.stderr, contains('unknown argument'), reason: extra);
          expect(calls(), isEmpty, reason: extra);
        }
      });

      test('the flag is refused with the version-only and read-back modes', () {
        for (final args in [
          ['--check-version-only', '--internal-tether-ui'],
          ['--verify-aab=${define('x')}', '--internal-tether-ui'],
        ]) {
          final r = play(args);
          expect(r.exitCode, 2, reason: '$args');
          expect(
              r.stderr, contains('--internal-tether-ui is for a build only'));
        }
      });

      test('no upload path or release doc passes the flag or the define', () {
        for (final path in [
          'android/fastlane/Fastfile',
          'tool/upload_ios_testflight.sh',
          'docs/PLAY_RELEASE.md',
          'docs/IOS_RELEASE.md',
        ]) {
          final text = File(path).readAsStringSync();
          expect(text, isNot(contains('internal-tether-ui')), reason: path);
          expect(text, isNot(contains('TETHER_UI_INTERNAL')), reason: path);
        }
      });

      test('each release script adds the define only under the flag', () {
        for (final path in [
          'tool/build_play_release.sh',
          'tool/build_ios_release.sh',
        ]) {
          final lines = File(path).readAsLinesSync();
          var depth = 0;
          var inside = false;
          final adds = <int>[];
          for (final (i, line) in lines.indexed) {
            final code = line.trimLeft();
            if (code.startsWith('#')) continue;
            if (code.startsWith('if [ "\$internal_ui" -eq 1 ]')) {
              inside = true;
              depth = 0;
            }
            if (inside) {
              if (RegExp(r'^if\b').hasMatch(code)) depth++;
              if (code == 'fi') {
                depth--;
                if (depth == 0) inside = false;
              }
              if ((code.startsWith('elif') || code == 'else') && depth == 1) {
                inside = false;
              }
            }
            if (code.contains('TETHER_UI_INTERNAL=true') &&
                !code.startsWith('echo')) {
              adds.add(i + 1);
              expect(inside, isTrue, reason: '$path:${i + 1}');
            }
          }
          expect(adds, isNotEmpty, reason: path);
        }
      });
    });
  });

  group('iOS script', () {
    test('without the flag the flutter calls are exactly as before', () {
      final file = define(storeDefine);
      final r = ios(['--dart-define-from-file=$file'],
          env: const {'TETHER_UI_INTERNAL': 'true'});
      expect(r.exitCode, 0, reason: output(r));
      expect(calls(), [
        '[analyze]',
        '[test]',
        '[build][ipa][--release][--dart-define-from-file=$file]',
      ]);
      expect(r.stdout, contains('== flutter build ipa --release\n'));
      expect(output(r), isNot(contains('INTERNAL')));
      expect(inRoot('build/ios/INTERNAL_TETHER_UI').existsSync(), isFalse);
    });

    test('with the flag it adds the define and writes the marker', () {
      final file = define(sandboxDefine);
      final r = ios(['--dart-define-from-file=$file', '--internal-tether-ui']);
      expect(r.exitCode, 0, reason: output(r));
      expect(calls(), [
        '[analyze]',
        '[test]',
        '[build][ipa][--release][--dart-define-from-file=$file]'
            '[--dart-define=TETHER_UI_INTERNAL=true]',
      ]);
      expect(r.stdout, contains('Never submit it for App Store review.'));
      expect(r.stdout, contains('\nCFBundleShortVersionString: 1.0.0\n'));
      final marker = inRoot('build/ios/INTERNAL_TETHER_UI');
      expect(
          marker.readAsStringSync(),
          'Internal test build (--internal-tether-ui): runs the tether_ui '
          'screens.\nIPA: Runner.ipa\nTestFlight internal testing only. '
          'Never submit it for App Store review.\n');
    });

    test('with the flag and --build-number both reach flutter', () {
      final file = define(sandboxDefine);
      final r = ios([
        '--dart-define-from-file=$file',
        '--internal-tether-ui',
        '--build-number',
        '2',
      ]);
      expect(r.exitCode, 0, reason: output(r));
      expect(
        calls().last,
        '[build][ipa][--release][--dart-define-from-file=$file]'
        '[--build-number][2][--dart-define=TETHER_UI_INTERNAL=true]',
      );
    });

    test('a failed internal build leaves no marker from an earlier build', () {
      final marker = inRoot('build/ios/INTERNAL_TETHER_UI')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('stale');
      final r = ios(
        [
          '--dart-define-from-file=${define(sandboxDefine)}',
          '--internal-tether-ui'
        ],
        env: {'FAKE_FAIL_BUILD': '1'},
      );
      expect(r.exitCode, isNonZero, reason: output(r));
      expect(marker.existsSync(), isFalse);
    });

    test('--check-only with the flag runs the internal checks only', () {
      final ok = ios([
        '--dart-define-from-file=${define(sandboxDefine)}',
        '--internal-tether-ui',
        '--check-only',
      ]);
      expect(ok.exitCode, 0, reason: output(ok));
      expect(ok.stdout,
          contains('Internal build checks (--internal-tether-ui) passed.'));
      final refused = ios([
        '--dart-define-from-file=${define(httpDefine())}',
        '--internal-tether-ui',
        '--check-only',
      ]);
      expect(refused.exitCode, 1);
      expect(refused.stderr, contains('build_ios_release: $emptyHostsMessage'));
      final flag = ios([
        '--dart-define-from-file='
            '${define('{"TETHER_BACKEND": "sandbox", "TETHER_UI_INTERNAL": true}')}',
        '--internal-tether-ui',
        '--check-only',
      ]);
      expect(flag.exitCode, 1);
      expect(flag.stderr, contains(flagInFile));
      expect(calls(), isEmpty);
    });

    test('the flag is refused with --inspect-ipa and as a value', () {
      final inspect =
          ios(['--inspect-ipa=${define('x')}', '--internal-tether-ui']);
      expect(inspect.exitCode, 2);
      expect(inspect.stderr, contains('cannot be combined'));
      final value = ios([
        '--dart-define-from-file=${define(storeDefine)}',
        '--internal-tether-ui=yes',
      ]);
      expect(value.exitCode, 2);
      expect(value.stderr, contains('unknown argument'));
    });
  });

  group('internal define check', () {
    test('sandbox: TETHER_BACKEND alone, optionally with provider IDs', () {
      for (final contents in [
        sandboxDefine,
        '{"TETHER_BACKEND": "sandbox", '
            '"GOOGLE_WEB_CLIENT_ID": "123-abc.apps.googleusercontent.com", '
            '"GOOGLE_IOS_CLIENT_ID": "123-def.apps.googleusercontent.com", '
            '"EPIC_SANDBOX_CLIENT_ID": "0a1b2c3d-0000-4000-8000-000000000000"}',
      ]) {
        final r = internalCheck(contents);
        expect(r.exitCode, 0, reason: '$contents ${r.stderr}');
      }
    });

    test('sandbox: each server key must be absent', () {
      for (final key in [
        'API_BASE_URL',
        'SUPABASE_URL',
        'SUPABASE_ANON_KEY',
        'SYNC_BASE_URL',
      ]) {
        final r = internalCheck(
            '{"TETHER_BACKEND": "sandbox", "$key": "https://x.example.com"}');
        expect(r.exitCode, 1, reason: key);
        expect(r.stderr, contains('$key must be absent in sandbox mode'));
      }
    });

    test('TETHER_BACKEND is required and must be sandbox or http', () {
      for (final contents in [
        '{}',
        '{"TETHER_BACKEND": "staging"}',
        '{"TETHER_BACKEND": true}',
      ]) {
        final r = internalCheck(contents);
        expect(r.exitCode, 1, reason: contents);
        expect(
            r.stderr, contains('TETHER_BACKEND must be "sandbox" or "http"'));
      }
    });

    test('an unknown key is refused by position, never by name', () {
      final r =
          internalCheck('{"TETHER_BACKEND": "sandbox", "MY_SECRET_NAME": "x"}');
      expect(r.exitCode, 1);
      expect(
          r.stderr,
          contains('define key #2 is not an allowed define key for an '
              'internal build'));
      expect(r.stderr, isNot(contains('MY_SECRET_NAME')));
    });

    test('a provider ID must be a plain public client ID', () {
      final r = internalCheck(
          '{"TETHER_BACKEND": "sandbox", "GOOGLE_WEB_CLIENT_ID": "has space"}');
      expect(r.exitCode, 1);
      expect(r.stderr,
          contains('GOOGLE_WEB_CLIENT_ID must be a public client ID'));
      expect(r.stderr, isNot(contains('has space')));
    });

    test('a privileged value is refused in every mode', () {
      final r = internalCheck('{"TETHER_BACKEND": "sandbox", '
          '"EPIC_SANDBOX_CLIENT_ID": "sb_secret_SyntheticCanary"}');
      expect(r.exitCode, 1);
      expect(
          r.stderr, contains('EPIC_SANDBOX_CLIENT_ID holds a privileged key'));
      expect(r.stderr, isNot(contains('SyntheticCanary')));
    });

    test('http with an empty STAGING_HOSTS is refused', () {
      final r = internalCheck(httpDefine());
      expect(r.exitCode, 1);
      expect(r.stderr, contains(emptyHostsMessage));
    });

    group('with STAGING_HOSTS listed', () {
      setUp(() => useHosts(stagingHosts));

      test('http with staging hosts and a publishable key passes', () {
        final r = internalCheck(httpDefine());
        expect(r.exitCode, 0, reason: '${r.stderr}');
        final upper = internalCheck(httpDefine(
            api: 'https://TETHER-API-STAGING.onrender.com.',
            supabase: 'https://stagingref.supabase.co/'));
        expect(upper.exitCode, 0, reason: '${upper.stderr}');
      });

      test('a host that is not listed (production) is refused', () {
        for (final (key, define) in [
          ('SUPABASE_URL', httpDefine(supabase: 'https://prodref.supabase.co')),
          ('API_BASE_URL', httpDefine(api: 'https://api.example.com')),
          ('SYNC_BASE_URL', httpDefine(sync: 'https://sync.example.com')),
        ]) {
          final r = internalCheck(define);
          expect(r.exitCode, 1, reason: key);
          expect(
              r.stderr,
              contains('$key host is not in STAGING_HOSTS '
                  '(tool/release_define_check.sh)'));
          expect(r.stderr, isNot(contains('example.com')));
          expect(r.stderr, isNot(contains('prodref')));
        }
      });

      test('the release URL and key rules still apply', () {
        final cases = {
          httpDefine(api: 'http://tether-api-staging.onrender.com'):
              'API_BASE_URL must be an absolute https URL',
          httpDefine(sync: null): 'SYNC_BASE_URL is missing or empty',
          httpDefine(supabase: 'https://stagingref.supabase.co/rest'):
              'SUPABASE_URL must be scheme and host only, without a path',
          httpDefine(key: 'not-a-key'): 'SUPABASE_ANON_KEY is not a '
              'publishable key (sb_publishable_...) or an anon JWT',
          httpDefine(key: 'sb_secret_SyntheticCanary'):
              'SUPABASE_ANON_KEY is a privileged key',
        };
        for (final MapEntry(key: contents, value: message) in cases.entries) {
          final r = internalCheck(contents);
          expect(r.exitCode, 1, reason: contents);
          expect(r.stderr, contains(message), reason: contents);
        }
      });
    });

    test('the define templates: sandbox passes, staging is refused unedited',
        () {
      final sandbox =
          File('tool/defines/internal-sandbox.example.json').readAsStringSync();
      final staging =
          File('tool/defines/internal-staging.example.json').readAsStringSync();
      expect(internalCheck(sandbox).exitCode, 0);
      for (final hosts in [const <String>[], stagingHosts]) {
        useHosts(hosts);
        final r = internalCheck(staging);
        expect(r.exitCode, 1, reason: '$hosts');
        expect(r.stderr, contains('must not use a placeholder .invalid host'));
        expect(
            r.stderr, contains('SUPABASE_ANON_KEY is not a publishable key'));
      }
    });
  });
}
