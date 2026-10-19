// The store identity must be the same on both platforms and must match the
// Firebase Android app in project `tether-health-llc` (owner decision D3,
// 2026-10-12; P-28). Push notifications only reach the registered package.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String kAppId = 'com.TetherHealthLLC.tetherhealth';

/// App Group shared by the Runner and the future Unplug extensions.
const String kAppGroupId = 'group.$kAppId.unplug';

void main() {
  test('Android namespace and applicationId use the shared app ID', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('namespace = "$kAppId"'));
    expect(gradle, contains('applicationId = "$kAppId"'));
    // A second applicationId (flavor, build type, or a stale template line)
    // could ship a different package than the one asserted above.
    expect(RegExp('applicationId').allMatches(gradle), hasLength(1));
    expect(gradle, isNot(contains('Specify your own unique Application ID')));
  });

  test('MainActivity lives in the app ID package', () {
    final activity = File(
      'android/app/src/main/kotlin/com/TetherHealthLLC/tetherhealth/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, startsWith('package $kAppId\n'));
  });

  test('there is exactly one MainActivity and the manifest resolves it', () {
    final activities = Directory('android/app/src/main/kotlin')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('MainActivity.kt'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toList();
    expect(activities, [
      'android/app/src/main/kotlin/com/TetherHealthLLC/tetherhealth/MainActivity.kt',
    ]);
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    // ".MainActivity" resolves against the Gradle namespace (= kAppId).
    expect(manifest, contains('android:name=".MainActivity"'));
    expect(manifest, isNot(contains('package=')));
  });

  test('every iOS app target uses the shared app ID', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final all = RegExp(
      r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);',
    ).allMatches(pbx).map((m) => m[1]!).toList();
    expect(all.toSet(), {kAppId, '$kAppId.RunnerTests'});
    // Runner and RunnerTests, each in Debug, Release and Profile.
    expect(all.where((id) => id == kAppId), hasLength(3));
    expect(all.where((id) => id == '$kAppId.RunnerTests'), hasLength(3));
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      plist,
      contains(
        '<key>CFBundleIdentifier</key>\n'
        '\t<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>',
      ),
    );
  });

  test('no xcconfig or Gradle setting overrides the app ID', () {
    // An xcconfig PRODUCT_BUNDLE_IDENTIFIER or a Gradle applicationIdSuffix
    // would silently change the ID that is built and uploaded.
    final xcconfigs = Directory('ios')
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((f) => f.path.endsWith('.xcconfig'))
        .toList();
    expect(xcconfigs.map((f) => f.path.replaceAll(r'\', '/')),
        contains('ios/Flutter/Release.xcconfig'));
    for (final file in xcconfigs) {
      expect(
          file.readAsStringSync(), isNot(contains('PRODUCT_BUNDLE_IDENTIFIER')),
          reason: file.path);
    }
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, isNot(contains('applicationIdSuffix')));
  });

  test('the App Group identifier is defined once per configuration', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final groups = RegExp(
      r'TETHER_APP_GROUP_IDENTIFIER = ([^;]+);',
    ).allMatches(pbx).map((m) => m[1]!).toList();
    expect(groups, [kAppGroupId, kAppGroupId, kAppGroupId]);
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      plist,
      contains(
        '<key>TetherAppGroupIdentifier</key>\n'
        '\t<string>\$(TETHER_APP_GROUP_IDENTIFIER)</string>',
      ),
    );
  });

  test(
    'the Play release script checks the built package against the app ID',
    () {
      final script = File('tool/build_play_release.sh').readAsStringSync();
      expect(script, contains('expected_package="$kAppId"'));
    },
  );

  test('no retired app ID remains in platform config', () {
    final retired = RegExp(r'hshanmug12|com\.breathefree');
    for (final path in [
      'android/app/build.gradle.kts',
      'android/app/src/main/AndroidManifest.xml',
      'ios/Runner.xcodeproj/project.pbxproj',
      'ios/Runner/Info.plist',
      'tool/build_play_release.sh',
    ]) {
      expect(
        retired.hasMatch(File(path).readAsStringSync()),
        isFalse,
        reason: path,
      );
    }
  });
  test('no retired app ID remains in setup docs, scripts, web or Windows', () {
    final retired = RegExp(r'hshanmug12|com\.breathefree|breathefreePatient');
    for (final path in [
      'README.md',
      'tool/setup_macos_linux.sh',
      'tool/setup_windows.bat',
      'web/index.html',
      'web/manifest.json',
      'windows/CMakeLists.txt',
      'windows/runner/Runner.rc',
      'windows/runner/main.cpp',
    ]) {
      expect(
        retired.hasMatch(File(path).readAsStringSync()),
        isFalse,
        reason: path,
      );
    }
  });

  test('web and Windows titles and binary name use the Tether name', () {
    // breathefree_patient stays only as the Dart package name (pubspec.yaml).
    for (final path in [
      'web/index.html',
      'web/manifest.json',
      'windows/CMakeLists.txt',
      'windows/runner/Runner.rc',
      'windows/runner/main.cpp',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('breathefree_patient')),
        reason: path,
      );
    }
    expect(
      File('windows/CMakeLists.txt').readAsStringSync(),
      contains('set(BINARY_NAME "tetherhealth")'),
    );
    expect(
      File('windows/runner/Runner.rc').readAsStringSync(),
      contains('VALUE "OriginalFilename", "tetherhealth.exe"'),
    );
    expect(
      File('web/index.html').readAsStringSync(),
      contains('<title>Tether Health</title>'),
    );
  });

  test('flutter create guidance yields the app ID and spares tracked runners',
      () {
    // flutter create derives the macOS/Linux app ID from --org and
    // --project-name; breathefree_patient would also add a second Android
    // MainActivity under com/TetherHealthLLC/breathefree_patient.
    for (final path in [
      'README.md',
      'tool/setup_macos_linux.sh',
      'tool/setup_windows.bat',
    ]) {
      final text = File(path).readAsStringSync();
      expect(text, isNot(contains('--project-name breathefree_patient')),
          reason: path);
      expect(text, isNot(contains('--org com.breathefree')), reason: path);
      for (final m in RegExp(r'--platforms[ =]"?([^"\s]+)').allMatches(text)) {
        final platforms = m[1]!.split(',');
        for (final tracked in ['android', 'ios', 'web', 'windows']) {
          expect(platforms, isNot(contains(tracked)), reason: '$path: ${m[0]}');
        }
      }
    }
    for (final path in ['README.md', 'tool/setup_macos_linux.sh']) {
      final text = File(path).readAsStringSync();
      expect(text, contains('--project-name tetherhealth'), reason: path);
      expect(text, contains('--org com.TetherHealthLLC'), reason: path);
    }
    final sh = shellCode(File('tool/setup_macos_linux.sh').readAsStringSync());
    expect(sh, contains('breathefree_platforms="macos"'));
    expect(sh, contains('breathefree_platforms="linux"'));
    // Every other way of setting, extending or defaulting the variable is
    // rejected, so no value can name a tracked runner.
    expect(unsafePlatformLines(sh), isEmpty);
    expect(RegExp('--platforms').allMatches(sh), hasLength(1));
    expect(sh, contains('  --platforms="\$breathefree_platforms"\n'));
    // Every runner the Windows script uses is tracked: it creates none.
    expect(
      File('tool/setup_windows.bat').readAsStringSync(),
      isNot(contains('flutter create')),
    );
  });

  test('the platform check rejects any value that could name a tracked runner',
      () {
    const unsafe = [
      'breathefree_platforms="macos, web"',
      r'breathefree_platforms="${BF_PLATFORMS:-android}"',
      'breathefree_platforms+=",web"',
      'breathefree_platforms=ios',
      "  breathefree_platforms='windows'",
      'export breathefree_platforms="macos"',
      'breathefree_platforms="macos" # web',
      'read -r breathefree_platforms',
      'breathefree_platforms="macos,linux"',
      r'  --platforms="${breathefree_platforms:-web}"',
      r'  --platforms="$breathefree_platforms,android"',
    ];
    for (final line in unsafe) {
      expect(unsafePlatformLines(line), [line], reason: line);
    }
    const safe = [
      '    breathefree_platforms="macos"',
      '    breathefree_platforms="linux"',
      r'  --platforms="$breathefree_platforms"',
      r'echo "BreatheFree setup passed for $breathefree_platforms."',
      r'  --platforms="${breathefree_platforms}"',
      '# breathefree_platforms="android"',
    ];
    for (final line in safe) {
      expect(unsafePlatformLines(shellCode(line)), isEmpty, reason: line);
    }
  });

  test('macOS/Linux setup restores pubspec.lock and .metadata before pub get',
      () {
    // flutter create . re-resolves pubspec.lock and rewrites .metadata; pub get
    // would then keep the newer versions and leave the tree changed.
    final sh = shellCode(File('tool/setup_macos_linux.sh').readAsStringSync());
    const files = '  for file in pubspec.lock .metadata; do';
    const backup = r'cp -p "$file" "$create_backup/$file"';
    const restore = r'cp -p "$create_backup/$file" "$file"';

    final restoreFn = shellFunctionBody(sh, 'restore_create_files');
    expect(restoreFn.split('\n'), contains(files));
    expect(restoreFn, contains(restore));
    final cleanupFn = shellFunctionBody(sh, 'cleanup');
    expect(cleanupFn.split('\n'), contains('    restore_create_files'));
    expect(cleanupFn.split('\n'), contains(r'  rm -rf "$create_backup"'));
    expect(
      RegExp(r'^trap cleanup EXIT$', multiLine: true).allMatches(sh),
      hasLength(1),
    );
    expect(
      RegExp(r'^create_backup="\$\(mktemp -d ', multiLine: true).allMatches(sh),
      hasLength(1),
    );

    final create = sh.indexOf('\nflutter create . ');
    final pubGet = sh.indexOf('\nflutter pub get\n');
    expect(create, greaterThan(0));
    expect(pubGet, greaterThan(create));
    expect('\nflutter create . '.allMatches(sh), hasLength(1));
    expect('\nflutter pub get\n'.allMatches(sh), hasLength(1));

    // Both files are copied aside after the trap is set and before
    // flutter create ...
    final backupLoop = sh.lastIndexOf('\n${files.trim()}', create);
    expect(backupLoop, greaterThan(sh.indexOf('\ntrap cleanup EXIT\n')));
    final beforeCreate = sh.substring(backupLoop, create);
    expect(beforeCreate, contains(backup));
    expect(beforeCreate, isNot(contains(restore)));
    expect(beforeCreate, contains('\nrestore_pending=1\n'));
    // ... and put back after it, before flutter pub get.
    final restoreCall = sh.indexOf('\nrestore_create_files\n', create);
    expect(restoreCall, greaterThan(create));
    expect(restoreCall, lessThan(pubGet));
  });

  group('macOS/Linux setup with a stub flutter', () {
    test('a failed flutter create leaves both files byte-identical', () async {
      final run = await runSetupWithStubFlutter(createExit: 3);
      expect(run.result.exitCode, 3, reason: '${run.result.stderr}');
      expect(run.lock.readAsBytesSync(), kStubLock);
      expect(run.metadata.readAsBytesSync(), kStubMetadata);
      expect(run.calls, ['create']);
      expect(run.leftoverTempDirs, isEmpty);
    });

    test('pub get, analyze and test see the original files', () async {
      final run = await runSetupWithStubFlutter(createExit: 0);
      expect(run.result.exitCode, 0, reason: '${run.result.stderr}');
      expect(run.calls, ['create', 'pub', 'analyze', 'test']);
      expect(run.lockAtPubGet.readAsBytesSync(), kStubLock);
      expect(run.metadataAtPubGet.readAsBytesSync(), kStubMetadata);
      expect(run.lock.readAsBytesSync(), kStubLock);
      expect(run.metadata.readAsBytesSync(), kStubMetadata);
      expect(run.leftoverTempDirs, isEmpty);
    });
  }, skip: Platform.isWindows ? 'the script needs bash' : false);
}

/// [script] without its full-line comments, which never run.
String shellCode(String script) => script
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('#'))
    .join('\n');

/// Body of the shell function [name] declared as `name() {` ... `}` at the
/// start of a line; fails the test unless there is exactly one.
String shellFunctionBody(String code, String name) {
  final matches = RegExp(
    '^${RegExp.escape(name)}\\(\\) \\{\\n([\\s\\S]*?)\\n\\}\$',
    multiLine: true,
  ).allMatches(code).toList();
  expect(matches, hasLength(1), reason: '$name()');
  return matches.single[1]!;
}

/// Lines of shell [code] that set breathefree_platforms to anything but
/// exactly "macos" or "linux", or expand it in a way that can add a value.
/// Pass the script through [shellCode] first.
List<String> unsafePlatformLines(String code) {
  final exactAssignment = RegExp(r'^\s*breathefree_platforms="(macos|linux)"$');
  final plainUse = RegExp(
    r'^(\$breathefree_platforms|\$\{breathefree_platforms\})(?![\w,])',
  );
  final unsafe = <String>[];
  for (final line in code.split('\n')) {
    for (final m in RegExp('breathefree_platforms').allMatches(line)) {
      final dollar = line.lastIndexOf(r'$', m.start);
      final isUse = dollar >= 0 &&
          (dollar == m.start - 1 ||
              (dollar == m.start - 2 && line[m.start - 1] == '{'));
      final ok = isUse
          ? plainUse.hasMatch(line.substring(dollar))
          : exactAssignment.hasMatch(line);
      if (!ok) {
        unsafe.add(line);
        break;
      }
    }
  }
  return unsafe;
}

final List<int> kStubLock = [
  ...'# locked\npackages: {}\n'.codeUnits,
  0xc3,
  0xa9,
];
final List<int> kStubMetadata = 'version:\n  revision: "x"\n'.codeUnits;

const String _stubFlutter = r'''#!/bin/sh
echo "$1" >> "$STUB_DIR/calls"
case "$1" in
  create)
    printf 'bumped\n' >> pubspec.lock
    printf 'rewritten\n' >> .metadata
    exit "$STUB_CREATE_EXIT"
    ;;
  pub)
    cp pubspec.lock "$STUB_DIR/pubspec.lock.at-pub-get"
    cp .metadata "$STUB_DIR/metadata.at-pub-get"
    ;;
esac
exit 0
''';

/// Runs a copy of tool/setup_macos_linux.sh in a scratch directory, with a
/// stub `flutter` first on PATH whose `create` changes pubspec.lock and
/// .metadata and then exits [createExit]. Needs no network and no Flutter.
Future<
    ({
      ProcessResult result,
      File lock,
      File metadata,
      File lockAtPubGet,
      File metadataAtPubGet,
      List<String> calls,
      List<String> leftoverTempDirs,
    })> runSetupWithStubFlutter({required int createExit}) async {
  final sandbox = Directory.systemTemp.createTempSync('th_setup_test_');
  addTearDown(() => sandbox.deleteSync(recursive: true));
  final repo = Directory('${sandbox.path}/repo')..createSync();
  Directory('${repo.path}/tool').createSync();
  File(
    'tool/setup_macos_linux.sh',
  ).copySync('${repo.path}/tool/setup_macos_linux.sh');
  final lock = File('${repo.path}/pubspec.lock')..writeAsBytesSync(kStubLock);
  final metadata = File('${repo.path}/.metadata')
    ..writeAsBytesSync(kStubMetadata);
  final bin = Directory('${sandbox.path}/bin')..createSync();
  final tmp = Directory('${sandbox.path}/tmp')..createSync();
  final flutter = File('${bin.path}/flutter')..writeAsStringSync(_stubFlutter);
  expect(Process.runSync('chmod', ['755', flutter.path]).exitCode, 0);

  final result = await Process.run(
    'bash',
    ['${repo.path}/tool/setup_macos_linux.sh'],
    workingDirectory: sandbox.path,
    environment: {
      'PATH': '${bin.path}:${Platform.environment['PATH']}',
      'TMPDIR': tmp.path,
      'STUB_DIR': bin.path,
      'STUB_CREATE_EXIT': '$createExit',
    },
  );
  final calls = File('${bin.path}/calls');
  return (
    result: result,
    lock: lock,
    metadata: metadata,
    lockAtPubGet: File('${bin.path}/pubspec.lock.at-pub-get'),
    metadataAtPubGet: File('${bin.path}/metadata.at-pub-get'),
    calls: calls.existsSync() ? calls.readAsLinesSync() : <String>[],
    leftoverTempDirs: tmp
        .listSync()
        .map((e) => e.path.split('/').last)
        .where((name) => name.startsWith('tetherhealth-setup.'))
        .toList(),
  );
}
