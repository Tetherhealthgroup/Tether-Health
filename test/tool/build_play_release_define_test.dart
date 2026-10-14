import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'release_define_cases.dart';

// Pins the define-file validation of tool/build_play_release.sh so that moving
// it into tool/release_define_check.sh cannot change its behaviour. Nothing is
// built: a full invocation stops at the validation (rejected file, exit 1) or
// at the missing android/key.properties (accepted file, exit 2), before any
// flutter step. The PATH holds only python3 and a fake flutter that records
// being called.

String join(List<String> parts) => parts.join(Platform.pathSeparator);

void main() {
  late Directory root;
  late File flutterMarker;
  late String scriptPath;

  setUp(() {
    root = Directory.systemTemp.createTempSync('play_release_define_test_');
    Directory(join([root.path, 'tool'])).createSync();
    for (final entry
        in Directory(join([Directory.current.path, 'tool'])).listSync()) {
      // Copy every script so a helper the Play script sources is present too.
      if (entry is File && entry.path.endsWith('.sh')) {
        entry.copySync(join([root.path, 'tool', entry.uri.pathSegments.last]));
      }
    }
    scriptPath = join([root.path, 'tool', 'build_play_release.sh']);
    File(join([root.path, 'pubspec.yaml']))
        .writeAsStringSync('name: x\nversion: 1.0.0+2\n');
    final fakeBin = Directory(join([root.path, 'bin']))..createSync();
    final python = Process.runSync('which', ['python3']).stdout.toString();
    Link(join([fakeBin.path, 'python3'])).createSync(python.trim());
    flutterMarker = File(join([root.path, 'flutter_ran']));
    final flutter = File(join([fakeBin.path, 'flutter']))
      ..writeAsStringSync('#!/bin/sh\ntouch "${flutterMarker.path}"\nexit 1\n');
    Process.runSync('chmod', ['+x', flutter.path]);
  });

  tearDown(() => root.deleteSync(recursive: true));

  ProcessResult run(String contents) {
    final define = File(join([root.path, 'release.json']))
      ..writeAsStringSync(contents);
    return Process.runSync(
      '/bin/bash',
      [scriptPath, '--dart-define-from-file=${define.path}'],
      environment: {'PATH': '${root.path}/bin:/usr/bin:/bin'},
      includeParentEnvironment: false,
    );
  }

  for (final c in defineCases) {
    test('${c.accepted ? 'accepts' : 'rejects'} ${c.name}', () {
      final r = run(c.contents);
      final out = '${r.stdout}${r.stderr}';
      if (c.accepted) {
        // Passed validation; stopped at the signing-config check.
        expect(r.exitCode, 2, reason: out);
        expect(out, contains('android/key.properties not found'));
      } else {
        expect(r.exitCode, 1, reason: out);
        for (final fragment in c.expected) {
          expect(r.stderr, contains('build_play_release: '));
          expect(r.stderr, contains(fragment));
        }
      }
      expect(out, isNot(contains(canary)));
      for (final stream in [r.stdout, r.stderr]) {
        expect(stream, isNot(contains(keyCanary)));
      }
      if (c.keyValue case final key? when key.trim().isNotEmpty) {
        expect(out, isNot(contains(key.trim())));
      }
      expect(flutterMarker.existsSync(), isFalse);
    });
  }

  test('a define file nested too deeply fails closed without a traceback', () {
    final r = run(deepNestingDefine(2000000));
    final out = '${r.stdout}${r.stderr}';
    expect(r.exitCode, 1, reason: out);
    expect(r.stderr, contains('build_play_release: cannot check define file'));
    expect(out, isNot(contains('Traceback')));
    expect(out, isNot(contains(canary)));
    expect(flutterMarker.existsSync(), isFalse);
  });
}
