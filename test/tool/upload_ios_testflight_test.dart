import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

// Checks tool/upload_ios_testflight.sh, the owner-run TestFlight upload.
//
// The static group pins the security-relevant text of the script: the single
// xcrun call, the two altool argument lists, the refusal messages, the key
// search folders, the redaction filter and the environment variables read,
// and fails on any altool option that could print credential details, take
// another credential source or send anything but the IPA.
//
// The run group executes a copy of the script. Nothing is sent anywhere:
// the PATH holds a fake xcrun that records its arguments, HOME is a temporary
// folder, and the App Store Connect key is a synthetic PEM-shaped file made
// here, holding a per-run canary that must never appear in the output.

String join(List<String> parts) => parts.join(Platform.pathSeparator);

const String scriptPath = 'tool/upload_ios_testflight.sh';
const String appBundleId = 'com.TetherHealthLLC.tetherhealth';
const String prefix = 'upload_ios_testflight: ';
const String redacted = '<key path not shown>';

/// PEM armour, assembled so this file holds no private-key marker.
const String pemBegin = '-----BEGIN '
    'PRIVATE KEY-----';
const String pemEnd = '-----END '
    'PRIVATE KEY-----';

/// A comment-only line: optional spaces or tabs, then `#`.
final RegExp commentLine = RegExp(r'^[ \t]*#');

/// The script's lines without comment lines and blank lines.
List<String> codeLines(String source) => source
    .split('\n')
    .where((l) => !commentLine.hasMatch(l) && l.trim().isNotEmpty)
    .toList();

/// The [pinned.length] lines starting at the first line equal to
/// [pinned.first].
List<String> block(List<String> lines, List<String> pinned) {
  final start = lines.indexOf(pinned.first);
  expect(start, isNot(-1), reason: 'line not found: ${pinned.first}');
  expect(
    start + pinned.length,
    lessThanOrEqualTo(lines.length),
    reason: 'the script ends inside the pinned block',
  );
  return lines.sublist(start, start + pinned.length);
}

/// Every line that runs or names xcrun.
const List<String> pinnedXcrunLines = [
  r'command -v xcrun >/dev/null 2>&1 || fail "xcrun not found on PATH (Xcode is required)."',
  r'        xcrun altool "$@" </dev/null 2>&1 || status=$?',
  r'  echo "== xcrun altool --validate-app"',
  r'  echo "== xcrun altool --upload-package"',
];

/// The mode dispatch: one altool argument list per mode.
const List<String> pinnedDispatch = [
  r'if [ "$validate" -eq 1 ]; then',
  r'  echo "== xcrun altool --validate-app"',
  r'  run_altool --validate-app "$ipa" --api-key "$key_id" --api-issuer "$issuer_id" --p8-file-path "$key_real"',
  r'  echo "Validation finished. Nothing was uploaded."',
  r'else',
  r'  echo "== xcrun altool --upload-package"',
  r'  run_altool --upload-package "$ipa" --api-key "$key_id" --api-issuer "$issuer_id" --p8-file-path "$key_real"',
  r'  echo "Upload finished. After processing, the build is listed under TestFlight in App Store Connect."',
  r'fi',
];

/// The environment refusals, which come before anything else is read.
const List<String> pinnedEnvironmentRefusals = [
  r'if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then',
  r'  fail "refusing to run: CI or GITHUB_ACTIONS is set. TestFlight uploads are run by the owner only, never by CI."',
  r'fi',
  r'if [ -n "${DEBUG:-}" ]; then',
  r'  fail "refusing to run: DEBUG is set. Debug output can expose credential details."',
  r'fi',
  r'if [ -n "${API_PRIVATE_KEYS_DIR+set}" ]; then',
  r'  fail "refusing to run: API_PRIVATE_KEYS_DIR is set. Unset it; the key is passed to altool by TETHER_ASC_KEY_PATH only."',
  r'fi',
  r'if [ -n "${CFFIXED_USER_HOME+set}" ]; then',
  r'  fail "refusing to run: CFFIXED_USER_HOME is set. It changes the home folder altool uses; unset it."',
  r'fi',
  r'check_status=0',
  r"""python3 -I -c 'import os, sys; sys.exit(3 if any(n.startswith("ALTOOL_") for n in os.environ) else 0)' 2>/dev/null ||""",
  r'  check_status=$?',
  r'case "$check_status" in',
  r'  0) ;;',
  r'  3) fail "refusing to run: an environment variable whose name starts with ALTOOL_ is set (not shown). Unset it; it can change how altool runs." ;;',
  r'  *) fail "cannot check the environment for ALTOOL_ variables." ;;',
  r'esac',
  r'[ -n "${HOME:-}" ] || fail "HOME is not set."',
  r'altool_preferences="$HOME/Library/Preferences/com.apple.itunes.altool.plist"',
  r'if [ -e "$altool_preferences" ] || [ -L "$altool_preferences" ]; then',
  r'  fail "refusing to run: ~/Library/Preferences/com.apple.itunes.altool.plist exists. It can change how altool runs; move it out of that folder first."',
  r'fi',
];

/// The folders altool searches for keys, set once and used by both checks.
const String pinnedSearchFolders =
    r'set -- "$repo_root/private_keys" "$HOME/private_keys" "$HOME/.private_keys" "$HOME/.appstoreconnect/private_keys"';

/// redact_key and run_altool, line by line.
const List<String> pinnedAltoolRunner = [
  r'redact_key() {',
  r'  REDACT_KEY_REAL="$key_real" REDACT_KEY_GIVEN="$key" \',
  r'    REDACT_KEY_REAL_NAME="${key_real##*/}" REDACT_KEY_GIVEN_NAME="${key##*/}" \',
  r"    LC_ALL=C awk '",
  r'function hide(line, needle,    out, at) {',
  r'  if (needle == "") return line',
  r'  out = ""',
  r'  while ((at = index(line, needle)) > 0) {',
  r'    out = out substr(line, 1, at - 1) "<key path not shown>"',
  r'    line = substr(line, at + length(needle))',
  r'  }',
  r'  return out line',
  r'}',
  r'{',
  r'  line = hide($0, ENVIRON["REDACT_KEY_REAL"])',
  r'  line = hide(line, ENVIRON["REDACT_KEY_GIVEN"])',
  r'  line = hide(line, ENVIRON["REDACT_KEY_REAL_NAME"])',
  r'  line = hide(line, ENVIRON["REDACT_KEY_GIVEN_NAME"])',
  r'  print line',
  r'  fflush()',
  r"}'",
  r'}',
  r'run_altool() {',
  r'  exec 4>&1',
  r'  altool_status=$(',
  r'    {',
  r'      {',
  r'        status=0',
  r'        xcrun altool "$@" </dev/null 2>&1 || status=$?',
  r'        echo "$status" >&3',
  r'      } | redact_key >&4',
  r'    } 3>&1',
  r'  )',
  r'  exec 4>&-',
  r'  case "$altool_status" in',
  r'    0) ;;',
  "    '' | *[!0-9]*) fail \"altool did not report an exit code.\" ;;",
  r'    *) exit "$altool_status" ;;',
  r'  esac',
  r'}',
];

/// Every message passed to fail, in order of appearance.
const List<String> pinnedFailMessages = [
  r'unknown argument: ${1%%=*}=<value not shown>',
  r'unknown argument (not shown; see the usage at the top of tool/upload_ios_testflight.sh)',
  r'refusing to run: CI or GITHUB_ACTIONS is set. TestFlight uploads are run by the owner only, never by CI.',
  r'refusing to run: DEBUG is set. Debug output can expose credential details.',
  r'refusing to run: API_PRIVATE_KEYS_DIR is set. Unset it; the key is passed to altool by TETHER_ASC_KEY_PATH only.',
  r'refusing to run: CFFIXED_USER_HOME is set. It changes the home folder altool uses; unset it.',
  r'refusing to run: an environment variable whose name starts with ALTOOL_ is set (not shown). Unset it; it can change how altool runs.',
  r'cannot check the environment for ALTOOL_ variables.',
  r'HOME is not set.',
  r'refusing to run: ~/Library/Preferences/com.apple.itunes.altool.plist exists. It can change how altool runs; move it out of that folder first.',
  r'--ipa given more than once',
  r'--validate given more than once',
  r'--ipa=<path> is required',
  r'--ipa requires a path',
  r'--ipa must name a .ipa file (path not shown)',
  r'IPA not found (path given to --ipa not shown)',
  r'TETHER_ASC_KEY_ID is not set.',
  r'TETHER_ASC_KEY_ID must be 10 upper-case letters or digits (value not shown).',
  r'TETHER_ASC_KEY_ID must be 10 upper-case letters or digits (value not shown).',
  r'TETHER_ASC_ISSUER_ID is not set.',
  r'TETHER_ASC_ISSUER_ID must be a UUID (value not shown).',
  r'TETHER_ASC_KEY_PATH is not set.',
  r'TETHER_ASC_KEY_PATH does not point to an existing file (path not shown).',
  r'cannot resolve a path (not shown)',
  r'TETHER_ASC_KEY_PATH contains a line break (path not shown).',
  r'TETHER_ASC_KEY_PATH does not point to an existing file (path not shown).',
  r'TETHER_ASC_KEY_PATH points inside the repository. Keep the key outside it.',
  r'cannot check where TETHER_ASC_KEY_PATH points (path not shown).',
  r'TETHER_ASC_KEY_PATH points inside a folder altool searches for keys. Keep the key in a folder of its own.',
  r'cannot check where TETHER_ASC_KEY_PATH points (path not shown).',
  r'TETHER_ASC_KEY_PATH is accessible to group or others. Run chmod 600 on the key file.',
  r'TETHER_ASC_KEY_PATH does not point to a PEM private key file (.p8). Its contents are not shown.',
  r'cannot read the file TETHER_ASC_KEY_PATH points to (path not shown).',
  r'refusing to run: a file named AuthKey_<TETHER_ASC_KEY_ID>.p8 is in a folder altool searches for keys (not shown). Move it out.',
  r'tool/build_ios_release.sh --inspect-ipa failed. Nothing was sent to App Store Connect.',
  r"the IPA's bundle identifier is not $expected_bundle_id. Nothing was sent to App Store Connect.",
  r'cannot read the bundle identifier from the IPA. Nothing was sent to App Store Connect.',
  r'xcrun not found on PATH (Xcode is required).',
  r'altool did not report an exit code.',
];

/// altool options and credential sources the script must never use: verbose
/// or debug output, the old altool, other credential sources, waiting or
/// transport tuning, metadata, text and asset-pack uploads, and the
/// username/password flows.
const List<String> forbiddenText = [
  '--verbose',
  '--verbose-debug',
  '--use-old-altool',
  '--auth-string',
  '--generate-jwt',
  '--wait',
  '--transport',
  '@env:',
  '@keychain:',
  '--app-store-text',
  '--beta-app-store-text',
  '--upload-asset-pack',
  'store-password',
  '--username',
  '--password',
  '--app-password',
  '--upload-app',
];

String randomHex(int length) {
  final random = Random.secure();
  return List.generate(
    length,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
}

String randomFrom(String alphabet, int length) {
  final random = Random.secure();
  return List.generate(
    length,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
}

void main() {
  group('static checks of tool/upload_ios_testflight.sh', () {
    late String source;
    late List<String> code;

    setUpAll(() {
      source = File(scriptPath).readAsStringSync();
      code = codeLines(source);
    });

    test('xcrun is named only on the pinned lines and run once', () {
      expect(
        code.where((l) => RegExp(r'\bxcrun\b').hasMatch(l)).toList(),
        pinnedXcrunLines,
      );
      expect(
        code.where((l) => RegExp(r'\baltool "\$@"').hasMatch(l)).length,
        1,
      );
    });

    test('one altool argument list per mode, as pinned', () {
      expect(
        code.where((l) => RegExp(r'^\s*run_altool\s').hasMatch(l)).toList(),
        [pinnedDispatch[2], pinnedDispatch[6]],
      );
      expect(
        block(code, pinnedDispatch),
        pinnedDispatch,
      );
      // The dispatch is the end of the script.
      expect(code.last, 'fi');
      expect(code.sublist(code.length - pinnedDispatch.length), pinnedDispatch);
    });

    test('altool is never run through a shell string', () {
      expect(code.where((l) => RegExp(r'\beval\b').hasMatch(l)), isEmpty);
      expect(
        code.where((l) => RegExp(r'\b(sh|bash|zsh|dash) -c\b').hasMatch(l)),
        isEmpty,
      );
      expect(code.where((l) => l.contains('/usr/bin/xcrun')), isEmpty);
    });

    test('no forbidden altool option or credential source appears', () {
      for (final text in forbiddenText) {
        expect(source, isNot(contains(text)), reason: 'script names "$text"');
      }
      expect(
        code.where((l) => RegExp(r'(?<![\w-])-[up](?![\w-])').hasMatch(l)),
        isEmpty,
        reason: 'the script passes -u or -p',
      );
    });

    test('the environment refusals come first and are pinned', () {
      expect(
        block(code, pinnedEnvironmentRefusals),
        pinnedEnvironmentRefusals,
      );
      final first = code.indexOf(pinnedEnvironmentRefusals.first);
      final parse = code.indexOf(r'for arg in "$@"; do');
      expect(parse, greaterThan(first));
    });

    test('the key search folders are pinned and used by both key checks', () {
      expect(code.where((l) => l.startsWith('set -- ')), [pinnedSearchFolders]);
      expect(
        code,
        contains(r'outside_all "$key_real" "$@" || check_status=$?'),
      );
      expect(code, contains(r'for folder in "$@"; do'));
      expect(code, contains(r'  stray="$folder/AuthKey_$key_id.p8"'));
    });

    test('the redaction filter and altool runner are pinned', () {
      expect(
        block(code, pinnedAltoolRunner),
        pinnedAltoolRunner,
      );
    });

    test('every refusal message is pinned', () {
      expect(
        RegExp(r'\bfail "([^"]*)"').allMatches(source).map((m) => m[1]),
        pinnedFailMessages,
      );
    });

    test('the script reads only the pinned environment variables', () {
      final names = RegExp(r'\$\{?([A-Z_][A-Z0-9_]*)')
          .allMatches(code.join('\n'))
          .map((m) => m[1])
          .toSet();
      expect(names, {
        'CI',
        'GITHUB_ACTIONS',
        'DEBUG',
        'API_PRIVATE_KEYS_DIR',
        'CFFIXED_USER_HOME',
        'HOME',
        'PWD',
        'TETHER_ASC_KEY_ID',
        'TETHER_ASC_ISSUER_ID',
        'TETHER_ASC_KEY_PATH',
      });
      expect(
        RegExp(r'ENVIRON\["([A-Z_]+)"\]')
            .allMatches(source)
            .map((m) => m[1])
            .toSet(),
        {
          'REDACT_KEY_REAL',
          'REDACT_KEY_GIVEN',
          'REDACT_KEY_REAL_NAME',
          'REDACT_KEY_GIVEN_NAME',
        },
      );
    });

    test('the expected bundle identifier is the app bundle identifier', () {
      expect(code, contains('expected_bundle_id="$appBundleId"'));
      final pbxproj =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(pbxproj, contains('PRODUCT_BUNDLE_IDENTIFIER = $appBundleId;'));
    });

    test('the private_keys folder is gitignored', () {
      expect(File('.gitignore').readAsLinesSync(), contains('private_keys/'));
    });

    test(
      'git ignores private_keys folders anywhere in the tree',
      () {
        for (final path in [
          'private_keys/notes.txt',
          'private_keys/AuthKey_ABCDEFGHIJ.p8',
          'android/private_keys/notes.txt',
        ]) {
          final r = Process.runSync(
            'git',
            ['check-ignore', '-q', '--no-index', path],
          );
          expect(r.exitCode, 0, reason: '$path is not gitignored');
        }
      },
      skip: Process.runSync('git', ['rev-parse', '--is-inside-work-tree'])
                  .exitCode ==
              0
          ? false
          : 'not a git work tree; the ignore file is checked as text above',
    );

    test(
      'docs/IOS_RELEASE.md describes the scripted upload and its limits',
      () {
        final doc = File('docs/IOS_RELEASE.md')
            .readAsStringSync()
            .replaceAll(RegExp(r'\s+'), ' ');
        for (final text in [
          'sh tool/upload_ios_testflight.sh --ipa=build/ios/ipa/',
          '--validate',
          'TETHER_ASC_KEY_PATH',
          'TETHER_ASC_KEY_ID',
          'TETHER_ASC_ISSUER_ID',
          '~/.appstoreconnect/private_keys',
          '~/secure/tether-health/asc/',
          'with your default HOME',
          'Xcode Organizer or Transporter',
          'internal testers only',
        ]) {
          expect(doc, contains(text));
        }
      },
    );
  });

  group('runs of tool/upload_ios_testflight.sh', () {
    late Directory base;
    late Directory repo;
    late Directory home;
    late Directory secure;
    late Directory fakeBin;
    late File record;
    late File xcrunExit;
    late String canary;
    late String keyCanary;
    late String hostile;
    late String keyId;
    late String issuerId;
    late String keyText;
    late File key;
    late File ipa;

    String inBase(String relative) => join([base.path, ...relative.split('/')]);

    void chmod(String mode, String path) {
      final r = Process.runSync('chmod', [mode, path]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
    }

    File writeKey(String path, {String? text, String mode = '600'}) {
      final file = File(path)..parent.createSync(recursive: true);
      file.writeAsStringSync(text ?? keyText);
      chmod(mode, file.path);
      return file;
    }

    String infoPlist(String bundleId, {bool versions = true}) =>
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<plist version="1.0"><dict>'
        '<key>CFBundleIdentifier</key><string>$bundleId</string>'
        '${versions ? '<key>CFBundleShortVersionString</key><string>1.2.3</string>'
            '<key>CFBundleVersion</key><string>45</string>' : ''}'
        '</dict></plist>\n';

    File writeZip(String path, Map<String, String> entries) {
      File(path).parent.createSync(recursive: true);
      final r = Process.runSync('python3', [
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
      expect(r.exitCode, 0, reason: '${r.stderr}');
      return File(path);
    }

    /// An IPA whose app Info.plist has [appId], next to a framework
    /// Info.plist with another identifier.
    File writeIpa(String path, {String appId = appBundleId}) => writeZip(path, {
          'Payload/Runner.app/Info.plist': infoPlist(appId),
          'Payload/Runner.app/Frameworks/App.framework/Info.plist': infoPlist(
            'io.flutter.flutter.app',
          ),
          'Payload/Runner.app/Runner': 'binary',
        });

    setUp(() {
      canary = 'TH1007CANARY${randomHex(16)}';
      keyCanary = 'TH1007KEY${randomHex(16)}';
      hostile = '$canary\x1b[31m\r\n::error::forged $canary';
      keyId = randomFrom('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', 10);
      issuerId = [8, 4, 4, 4, 12].map(randomHex).join('-');
      final body = (keyCanary * 20).substring(0, 192);
      keyText = '$pemBegin\n'
          '${body.substring(0, 64)}\n${body.substring(64, 128)}\n'
          '${body.substring(128)}\n$pemEnd\n';

      base = Directory.systemTemp.createTempSync('upload_ios_testflight_test_');
      repo = Directory(inBase('repo'))..createSync();
      home = Directory(inBase('home'))..createSync();
      secure = Directory(inBase('secure-$canary'))..createSync();
      final source = Directory.current.path;
      for (final script in [
        'upload_ios_testflight.sh',
        'build_ios_release.sh',
      ]) {
        File(join([repo.path, 'tool', script]))
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(
            File(join([source, 'tool', script])).readAsBytesSync(),
          );
      }

      fakeBin = Directory(inBase('bin'))..createSync();
      final python = Process.runSync('which', [
        'python3',
      ]).stdout.toString().trim();
      expect(python, isNotEmpty, reason: 'python3 not found on PATH');
      Link(join([fakeBin.path, 'python3'])).createSync(python);
      record = File(inBase('xcrun_calls'));
      xcrunExit = File(inBase('xcrun_exit'));
      // Records each call and prints the key path and file name the way some
      // altool errors do, on standard output and standard error.
      final xcrun = File(join([fakeBin.path, 'xcrun']))
        ..writeAsStringSync(
          '#!/bin/sh\n'
          '{ echo "--call--"; printf "%s\\n" "\$@"; } >> "${record.path}"\n'
          'p8=""; previous=""\n'
          'for a in "\$@"; do\n'
          '  [ "\$previous" = "--p8-file-path" ] && p8="\$a"\n'
          '  previous="\$a"\n'
          'done\n'
          'echo "fake altool: reading \$p8"\n'
          'echo "fake altool: key file \${p8##*/} too short" >&2\n'
          'if [ -f "${xcrunExit.path}" ]; then exit "\$(cat "${xcrunExit.path}")"; fi\n'
          'exit 0\n',
        );
      chmod('+x', xcrun.path);

      key = writeKey(join([secure.path, 'AuthKey_$canary.p8']));
      ipa = writeIpa(inBase('out/Runner.ipa'));
    });

    tearDown(() => base.deleteSync(recursive: true));

    ProcessResult run(
      List<String>? args, {
      Map<String, String?> env = const {},
      String? cwd,
    }) {
      final environment = <String, String?>{
        'HOME': home.path,
        'PATH': '${fakeBin.path}:/usr/bin:/bin',
        'TETHER_ASC_KEY_PATH': key.path,
        'TETHER_ASC_KEY_ID': keyId,
        'TETHER_ASC_ISSUER_ID': issuerId,
        ...env,
      };
      return Process.runSync(
        '/bin/sh',
        [
          join([repo.path, 'tool', 'upload_ios_testflight.sh']),
          ...(args ?? ['--ipa=${ipa.path}']),
        ],
        environment: {
          for (final e in environment.entries)
            if (e.value != null) e.key: e.value!,
        },
        includeParentEnvironment: false,
        workingDirectory: cwd ?? base.path,
      );
    }

    String realKey() => key.resolveSymbolicLinksSync();

    /// No canary, key text, key path or key file name, and nothing a CI
    /// runner would read as a workflow command.
    void expectNoLeak(ProcessResult r) {
      for (final (name, text) in [
        ('stdout', '${r.stdout}'),
        ('stderr', '${r.stderr}'),
      ]) {
        expect(text, isNot(contains(canary)), reason: '$name holds the canary');
        expect(
          text,
          isNot(contains(keyCanary)),
          reason: '$name holds key text',
        );
        expect(text, isNot(contains('PRIVATE KEY')), reason: '$name: PEM');
        expect(text, isNot(contains(key.path)), reason: '$name: key path');
        expect(text, isNot(contains(realKey())), reason: '$name: key path');
        expect(text, isNot(contains(keyId)), reason: '$name: key ID');
        expect(text, isNot(contains(issuerId)), reason: '$name: issuer ID');
        expect(text, isNot(contains('\x1b')), reason: '$name holds ESC');
        expect(text, isNot(contains('\r')), reason: '$name holds CR');
        expect(
          text.split('\n').where((l) => l.trimLeft().startsWith('::')),
          isEmpty,
          reason: '$name has a line starting with ::',
        );
      }
    }

    List<List<String>> xcrunCalls() {
      if (!record.existsSync()) return [];
      final calls = <List<String>>[];
      for (final line in record.readAsLinesSync()) {
        if (line == '--call--') {
          calls.add([]);
        } else {
          calls.last.add(line);
        }
      }
      return calls;
    }

    void expectRefused(ProcessResult r, int exitCode, String message) {
      expectNoLeak(r);
      expect(r.exitCode, exitCode, reason: '${r.stdout}${r.stderr}');
      expect(r.stdout, '');
      expect(r.stderr, '$prefix$message\n');
      expect(record.existsSync(), isFalse, reason: 'xcrun was called');
    }

    /// A refusal after the IPA version was printed.
    void expectRefusedAfterInspect(ProcessResult r, String message) {
      expectNoLeak(r);
      expect(r.exitCode, 1, reason: '${r.stdout}${r.stderr}');
      expect(
        '${r.stdout}',
        startsWith(
          '== IPA version (tool/build_ios_release.sh --inspect-ipa)\n',
        ),
      );
      expect('${r.stderr}', endsWith('$prefix$message\n'));
      expect(record.existsSync(), isFalse, reason: 'xcrun was called');
    }

    List<String> altoolArgs(String mode, String ipaPath) => [
          'altool',
          mode,
          ipaPath,
          '--api-key',
          keyId,
          '--api-issuer',
          issuerId,
          '--p8-file-path',
          realKey(),
        ];

    const versionSection =
        '== IPA version (tool/build_ios_release.sh --inspect-ipa)\n'
        'CFBundleShortVersionString: 1.2.3\n'
        'CFBundleVersion: 45\n';
    const fakeOutput = 'fake altool: reading $redacted\n'
        'fake altool: key file $redacted too short\n';

    group('good inputs', () {
      test('upload: one altool call with the exact argument list', () {
        final r = run(null);
        expectNoLeak(r);
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
        expect(r.stderr, '');
        expect(
          r.stdout,
          '$versionSection'
          '== xcrun altool --upload-package\n'
          '$fakeOutput'
          'Upload finished. After processing, the build is listed under '
          'TestFlight in App Store Connect.\n',
        );
        expect(xcrunCalls(), [altoolArgs('--upload-package', ipa.path)]);
      });

      test('validate: one altool call with the exact argument list', () {
        final r = run(['--validate', '--ipa=${ipa.path}']);
        expectNoLeak(r);
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
        expect(r.stderr, '');
        expect(
          r.stdout,
          '$versionSection'
          '== xcrun altool --validate-app\n'
          '$fakeOutput'
          'Validation finished. Nothing was uploaded.\n',
        );
        expect(xcrunCalls(), [altoolArgs('--validate-app', ipa.path)]);
      });

      test('relative paths are resolved against the working directory', () {
        final cwd = Directory(inBase('out')).resolveSymbolicLinksSync();
        final link = Link(join([cwd, 'key.p8']))..createSync(key.path);
        final r = run(
          ['--ipa=Runner.ipa'],
          env: {'TETHER_ASC_KEY_PATH': 'key.p8'},
          cwd: cwd,
        );
        expectNoLeak(r);
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
        // The key is passed by its real path, never through the link.
        expect(xcrunCalls(), [
          altoolArgs('--upload-package', join([cwd, 'Runner.ipa'])),
        ]);
        expect(r.stdout, isNot(contains(link.path)));
        expect(r.stdout, isNot(contains('key.p8')));
      });

      test('an upper-case .IPA extension, issuer ID and 0400 key pass', () {
        final upper = writeIpa(inBase('out/Runner.IPA'));
        chmod('400', key.path);
        final r = run(
          ['--ipa=${upper.path}'],
          env: {'TETHER_ASC_ISSUER_ID': issuerId.toUpperCase()},
        );
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
        expect(xcrunCalls().single[2], upper.path);
        expect(xcrunCalls().single[6], issuerId.toUpperCase());
      });

      test('a stray key with another key ID does not block the upload', () {
        writeKey(
          join([
            home.path,
            '.appstoreconnect',
            'private_keys',
            'AuthKey_ZZZZZZZZZZ.p8',
          ]),
        );
        final r = run(null, env: {'TETHER_ASC_KEY_ID': 'YYYYYYYYYY'});
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
        expect(xcrunCalls(), hasLength(1));
      });

      test('DEVELOPER_DIR, TOOLCHAINS, TMPDIR and near-miss names pass', () {
        final r = run(
          null,
          env: {
            'DEVELOPER_DIR': inBase('developer'),
            'TOOLCHAINS': 'com.example.toolchain',
            'TMPDIR': base.path,
            'XALTOOL_SETTING': 'x',
            'altool_setting': 'x',
          },
        );
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
        expect(xcrunCalls(), hasLength(1));
      });

      test('a CI variable set to an empty value is not a refusal', () {
        final r = run(null, env: {'CI': '', 'GITHUB_ACTIONS': '', 'DEBUG': ''});
        expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
        expect(xcrunCalls(), hasLength(1));
      });

      test('altool output is filtered and its exit code is kept', () {
        for (final code in ['7', '1', '2']) {
          xcrunExit.writeAsStringSync(code);
          for (final args in [
            ['--ipa=${ipa.path}'],
            ['--ipa=${ipa.path}', '--validate'],
          ]) {
            final r = run(args);
            expectNoLeak(r);
            expect(r.exitCode, int.parse(code), reason: '$args');
            expect(r.stderr, '');
            expect(r.stdout, contains(fakeOutput));
            expect(r.stdout, isNot(contains('finished')));
          }
        }
      });
    });

    group('environment refusals', () {
      const ciMessage = 'refusing to run: CI or GITHUB_ACTIONS is set. '
          'TestFlight uploads are run by the owner only, never by CI.';
      for (final (name, value) in [
        ('CI', 'true'),
        ('CI', '1'),
        ('GITHUB_ACTIONS', 'true'),
      ]) {
        test('refuses $name=$value', () {
          expectRefused(run(null, env: {name: value}), 1, ciMessage);
        });
      }

      test('refuses DEBUG', () {
        expectRefused(
          run(null, env: {'DEBUG': '1'}),
          1,
          'refusing to run: DEBUG is set. Debug output can expose credential '
          'details.',
        );
      });

      test('refuses API_PRIVATE_KEYS_DIR, even empty', () {
        for (final value in [secure.path, '']) {
          expectRefused(
            run(null, env: {'API_PRIVATE_KEYS_DIR': value}),
            1,
            'refusing to run: API_PRIVATE_KEYS_DIR is set. Unset it; the key '
            'is passed to altool by TETHER_ASC_KEY_PATH only.',
          );
        }
      });

      test('refuses CFFIXED_USER_HOME, even empty', () {
        for (final value in [home.path, '']) {
          expectRefused(
            run(null, env: {'CFFIXED_USER_HOME': value}),
            1,
            'refusing to run: CFFIXED_USER_HOME is set. It changes the home '
            'folder altool uses; unset it.',
          );
        }
      });

      test('refuses any variable named ALTOOL_*, without showing it', () {
        for (final (name, value) in [
          ('ALTOOL_$canary', hostile),
          ('ALTOOL_', ''),
          ('ALTOOL_DEFAULTS', 'x'),
        ]) {
          expectRefused(
            run(null, env: {name: value}),
            1,
            'refusing to run: an environment variable whose name starts with '
            'ALTOOL_ is set (not shown). Unset it; it can change how '
            'altool runs.',
          );
        }
      });

      test('refuses an unset HOME', () {
        expectRefused(run(null, env: {'HOME': null}), 1, 'HOME is not set.');
      });

      test('refuses an altool preferences file or link', () {
        const message = 'refusing to run: '
            '~/Library/Preferences/com.apple.itunes.altool.plist exists. It '
            'can change how altool runs; move it out of that folder first.';
        final prefs = join([
          home.path,
          'Library',
          'Preferences',
          'com.apple.itunes.altool.plist',
        ]);
        File(prefs)
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('x');
        expectRefused(run(null), 1, message);
        File(prefs).deleteSync();
        Link(prefs).createSync(inBase('missing'));
        expectRefused(run(null), 1, message);
      });
    });

    group('argument refusals', () {
      const unknown = 'unknown argument (not shown; see the usage at the top '
          'of tool/upload_ios_testflight.sh)';

      test('unknown arguments are rejected without echoing them', () {
        for (final args in [
          [hostile],
          ['--ipa=${ipa.path}', hostile],
          ['--ipa', ipa.path],
          ['-v', '--ipa=${ipa.path}'],
          ['--ipa=${ipa.path}', '--verbose'],
        ]) {
          expectRefused(run(args), 2, unknown);
        }
        expectRefused(
          run(['--ipa=${ipa.path}', '--key=$hostile']),
          2,
          'unknown argument: --key=<value not shown>',
        );
        expectRefused(
          run(['--IPA=${ipa.path}']),
          2,
          'unknown argument: --IPA=<value not shown>',
        );
      });

      test('--ipa and --validate are accepted once each', () {
        expectRefused(
          run(['--ipa=${ipa.path}', '--ipa=${ipa.path}']),
          2,
          '--ipa given more than once',
        );
        expectRefused(
          run(['--ipa=${ipa.path}', '--validate', '--validate']),
          2,
          '--validate given more than once',
        );
      });

      test('--ipa is required and must name an existing .ipa file', () {
        expectRefused(run([]), 2, '--ipa=<path> is required');
        expectRefused(run(['--validate']), 2, '--ipa=<path> is required');
        expectRefused(run(['--ipa=']), 2, '--ipa requires a path');
        final zip = writeIpa(inBase('out/$hostile.zip'));
        expectRefused(
          run(['--ipa=${zip.path}']),
          2,
          '--ipa must name a .ipa file (path not shown)',
        );
        expectRefused(
          run(['--ipa=${inBase('out/$hostile.ipa')}']),
          2,
          'IPA not found (path given to --ipa not shown)',
        );
        Directory(inBase('out/folder-$canary.ipa')).createSync();
        expectRefused(
          run(['--ipa=${inBase('out/folder-$canary.ipa')}']),
          2,
          'IPA not found (path given to --ipa not shown)',
        );
      });
    });

    group('key ID and issuer ID refusals', () {
      test('TETHER_ASC_KEY_ID must be 10 upper-case letters or digits', () {
        expectRefused(
          run(null, env: {'TETHER_ASC_KEY_ID': null}),
          1,
          'TETHER_ASC_KEY_ID is not set.',
        );
        expectRefused(
          run(null, env: {'TETHER_ASC_KEY_ID': ''}),
          1,
          'TETHER_ASC_KEY_ID is not set.',
        );
        for (final value in [
          keyId.toLowerCase().replaceRange(0, 1, 'a'),
          keyId.substring(0, 9),
          '${keyId}A',
          '$keyId\n',
          '${keyId.substring(0, 5)} ${keyId.substring(5, 9)}',
          '${keyId.substring(0, 9)}-',
          hostile,
        ]) {
          expectRefused(
            run(null, env: {'TETHER_ASC_KEY_ID': value}),
            1,
            'TETHER_ASC_KEY_ID must be 10 upper-case letters or digits '
            '(value not shown).',
          );
        }
      });

      test('TETHER_ASC_ISSUER_ID must be a UUID', () {
        expectRefused(
          run(null, env: {'TETHER_ASC_ISSUER_ID': null}),
          1,
          'TETHER_ASC_ISSUER_ID is not set.',
        );
        for (final value in [
          'not-a-uuid',
          '$issuerId\n',
          '${issuerId}0',
          issuerId.substring(1),
          issuerId.replaceRange(0, 1, 'g'),
          issuerId.replaceAll('-', ''),
          hostile,
        ]) {
          expectRefused(
            run(null, env: {'TETHER_ASC_ISSUER_ID': value}),
            1,
            'TETHER_ASC_ISSUER_ID must be a UUID (value not shown).',
          );
        }
      });
    });

    group('key file refusals', () {
      const notFile = 'TETHER_ASC_KEY_PATH does not point to an existing file '
          '(path not shown).';
      const inRepo = 'TETHER_ASC_KEY_PATH points inside the repository. Keep '
          'the key outside it.';
      const inSearch = 'TETHER_ASC_KEY_PATH points inside a folder altool '
          'searches for keys. Keep the key in a folder of its own.';
      const access = 'TETHER_ASC_KEY_PATH is accessible to group or others. '
          'Run chmod 600 on the key file.';
      const notPem = 'TETHER_ASC_KEY_PATH does not point to a PEM private key '
          'file (.p8). Its contents are not shown.';

      ProcessResult withKey(String path) =>
          run(null, env: {'TETHER_ASC_KEY_PATH': path});

      test('must be set and name an existing regular file', () {
        expectRefused(
          run(null, env: {'TETHER_ASC_KEY_PATH': null}),
          1,
          'TETHER_ASC_KEY_PATH is not set.',
        );
        expectRefused(withKey(join([secure.path, hostile])), 1, notFile);
        expectRefused(withKey(secure.path), 1, notFile);
      });

      test('a path holding a line break is refused', () {
        // The second name ends in a newline, which $(...) would strip.
        for (final name in ['line\nbreak.p8', 'AuthKey_$canary.p8\n']) {
          final odd = writeKey(join([secure.path, name]));
          expectRefused(
            withKey(odd.path),
            1,
            'TETHER_ASC_KEY_PATH contains a line break (path not shown).',
          );
        }
      });

      test('the real path must be outside the repository', () {
        final inside = writeKey(
          join([repo.path, 'keys', 'AuthKey_$canary.p8']),
        );
        expectRefused(withKey(inside.path), 1, inRepo);
        final link = Link(join([secure.path, 'link-$canary.p8']))
          ..createSync(inside.path);
        expectRefused(withKey(link.path), 1, inRepo);
        final repoPrivate = writeKey(
          join([repo.path, 'private_keys', 'k-$canary.p8']),
        );
        expectRefused(withKey(repoPrivate.path), 1, inRepo);
        expectRefused(
          run(
            null,
            env: {'TETHER_ASC_KEY_PATH': 'keys/AuthKey_$canary.p8'},
            cwd: repo.path,
          ),
          1,
          inRepo,
        );
      });

      test('the real path must be outside every key search folder', () {
        for (final folder in [
          'private_keys',
          '.private_keys',
          '.appstoreconnect/private_keys',
          '.appstoreconnect/private_keys/nested',
        ]) {
          final inside = writeKey(
            join([home.path, ...folder.split('/'), 'k-$canary.p8']),
          );
          expectRefused(withKey(inside.path), 1, inSearch);
          final link = Link(join([secure.path, 'link-$canary.p8']))
            ..createSync(inside.path);
          expectRefused(withKey(link.path), 1, inSearch);
          link.deleteSync();
          home.listSync().forEach((e) => e.deleteSync(recursive: true));
        }
      });

      test('search folders are compared by real path, ignoring case', () {
        final homeLink = Link(inBase('home-link'))..createSync(home.path);
        final inside = writeKey(
          join([home.path, 'private_keys', 'k-$canary.p8']),
        );
        expectRefused(
          run(
            null,
            env: {'HOME': homeLink.path, 'TETHER_ASC_KEY_PATH': inside.path},
          ),
          1,
          inSearch,
        );
        final mixed = writeKey(
          join([home.path, '.AppStoreConnect', 'Private_Keys', 'k-$canary.p8']),
        );
        expectRefused(withKey(mixed.path), 1, inSearch);
      });

      test('the file must not be accessible to group or others', () {
        for (final mode in ['640', '604', '644', '660', '602', '610']) {
          chmod(mode, key.path);
          expectRefused(run(null), 1, access);
        }
      });

      test('the file must hold one PEM private key, checked silently', () {
        final body = keyText.split('\n')[1];
        for (final text in [
          '',
          'not a key $keyCanary\n',
          '{"type": "service'
              '_account", "x": "$keyCanary"}\n',
          keyText.replaceAll(
            pemBegin,
            '-----BEGIN EC '
            'PRIVATE KEY-----',
          ),
          keyText.replaceAll('$pemEnd\n', ''),
          '$pemBegin\n$pemEnd\n',
          keyText.replaceFirst(body, '${body.substring(0, 60)}!$keyCanary'),
          keyText.replaceFirst(body, '$body$body'.substring(0, 77)),
          keyText.replaceAll('\n', '\r\n'),
          '$keyText$keyText',
          keyText.replaceFirst(body, List.filled(80, body).join('\n')),
        ]) {
          writeKey(key.path, text: text);
          expectRefused(run(null), 1, notPem);
        }
      });

      test(
        'a file named AuthKey_<key ID>.p8 in a search folder is refused',
        () {
          const message = 'refusing to run: a file named '
              'AuthKey_<TETHER_ASC_KEY_ID>.p8 is in a folder altool searches '
              'for keys (not shown). Move it out.';
          for (final folder in [
            join([repo.path, 'private_keys']),
            join([home.path, 'private_keys']),
            join([home.path, '.private_keys']),
            join([home.path, '.appstoreconnect', 'private_keys']),
          ]) {
            final stray = writeKey(join([folder, 'AuthKey_$keyId.p8']));
            expectRefused(run(null), 1, message);
            stray.deleteSync();
            Link(stray.path).createSync(inBase('missing'));
            expectRefused(run(null), 1, message);
            Link(stray.path).deleteSync();
          }
        },
      );
    });

    group('IPA refusals', () {
      test('an IPA with another bundle identifier is refused', () {
        final other = writeIpa(
          inBase('out/Other.ipa'),
          appId: 'com.example.other',
        );
        final r = run(['--ipa=${other.path}']);
        expectRefusedAfterInspect(
          r,
          "the IPA's bundle identifier is not $appBundleId. Nothing was sent "
          'to App Store Connect.',
        );
        expect(r.stdout, versionSection);
        expect(r.stderr, isNot(contains('com.example.other')));
      });

      test('the bundle identifier must match exactly', () {
        for (final id in [
          '$appBundleId.dev',
          '${appBundleId}x',
          'x$appBundleId',
        ]) {
          final near = writeIpa(inBase('out/Near.ipa'), appId: id);
          expectRefusedAfterInspect(
            run(['--ipa=${near.path}']),
            "the IPA's bundle identifier is not $appBundleId. Nothing was sent "
            'to App Store Connect.',
          );
        }
      });

      test('only the app Info.plist counts, not a framework one', () {
        final framework = writeZip(inBase('out/Framework.ipa'), {
          'Payload/Runner.app/Info.plist': infoPlist('com.example.other'),
          'Payload/Runner.app/Frameworks/App.framework/Info.plist': infoPlist(
            appBundleId,
          ),
        });
        expectRefusedAfterInspect(
          run(['--ipa=${framework.path}']),
          "the IPA's bundle identifier is not $appBundleId. Nothing was sent "
          'to App Store Connect.',
        );
      });

      test('an IPA the version read-back rejects is refused', () {
        for (final bad in [
          writeZip(inBase('out/Two.ipa'), {
            'Payload/Runner.app/Info.plist': infoPlist(appBundleId),
            'Payload/Other.app/Info.plist': infoPlist(appBundleId),
          }),
          writeZip(inBase('out/NoVersion.ipa'), {
            'Payload/Runner.app/Info.plist': infoPlist(
              appBundleId,
              versions: false,
            ),
          }),
          File(inBase('out/NotZip.ipa'))..writeAsStringSync('not a zip'),
        ]) {
          expectRefusedAfterInspect(
            run(['--ipa=${bad.path}']),
            'tool/build_ios_release.sh --inspect-ipa failed. Nothing was sent '
            'to App Store Connect.',
          );
        }
      });
    });
  });
}
