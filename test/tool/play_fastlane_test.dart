import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Static checks of the owner-run Google Play upload lanes
// (android/fastlane/Fastfile and Appfile, docs/PLAY_RELEASE.md). The files are
// read as text, so this test needs no Ruby or fastlane. It pins the scope:
// two lanes, the internal track as a draft, nothing but the AAB uploaded,
// the key path only from TETHER_PLAY_JSON_KEY, no upload under CI, and the
// repo's --verify-aab checks before every upload.

const String fastfilePath = 'android/fastlane/Fastfile';
const String appfilePath = 'android/fastlane/Appfile';
const String gemfilePath = 'android/Gemfile';
const String gemfileLockPath = 'android/Gemfile.lock';

/// Ruby source with comment lines removed, so prose cannot satisfy or trip a
/// check. The files keep comments on their own lines.
String code(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('#'))
    .join('\n');

/// The body of `lane :<name> do ... end`, two-space indented inside
/// `platform :android do`.
String laneBody(String fastfile, String name) {
  final lines = fastfile.split('\n');
  final start = lines.indexWhere((l) => l.startsWith('  lane :$name do'));
  expect(start, isNot(-1), reason: 'lane :$name not found');
  final end = lines.indexWhere((l) => l == '  end', start + 1);
  expect(end, isNot(-1), reason: 'end of lane :$name not found');
  return lines.sublist(start + 1, end).join('\n');
}

/// Files under android/ that git tracks or would add (untracked and not
/// ignored). Falls back to a directory walk when git is unavailable.
List<String> androidFiles() {
  try {
    final result = Process.runSync('git', [
      'ls-files',
      '-z',
      '--cached',
      '--others',
      '--exclude-standard',
      'android',
    ]);
    if (result.exitCode == 0) {
      return (result.stdout as String)
          .split('\x00')
          .where((p) => p.isNotEmpty)
          .toList();
    }
  } on ProcessException {
    // git is not installed; fall back to the walk.
  }
  const skipped = {'.gradle', 'build', '.cxx', 'vendor', '.bundle'};
  return [
    for (final entity in Directory(
      'android',
    ).listSync(recursive: true, followLinks: false))
      if (entity is File &&
          !entity.uri.pathSegments.any((s) => skipped.contains(s)))
        entity.path,
  ];
}

void main() {
  late String fastfile;
  late String appfile;

  setUpAll(() {
    fastfile = code(File(fastfilePath).readAsStringSync());
    appfile = code(File(appfilePath).readAsStringSync());
  });

  test('the Appfile package matches the app and the build script', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final appId =
        RegExp(r'applicationId\s*=\s*"([^"]+)"').firstMatch(gradle)?.group(1);
    expect(appId, isNotNull, reason: 'applicationId not found');

    final packages = RegExp(r'package_name\("([^"]*)"\)')
        .allMatches(appfile)
        .map((m) => m.group(1))
        .toList();
    expect(packages, [appId]);

    final script = File('tool/build_play_release.sh').readAsStringSync();
    expect(script, contains('expected_package="$appId"'));
  });

  test('the key path comes only from TETHER_PLAY_JSON_KEY', () {
    expect(
      RegExp(
        r'^json_key_file\(ENV\["TETHER_PLAY_JSON_KEY"\]\)$',
        multiLine: true,
      ).allMatches(appfile).length,
      1,
    );
    // No other key source in either file: no inline key data, no second
    // json_key_file, no literal key path.
    for (final (name, source) in [
      ('Appfile', appfile),
      ('Fastfile', fastfile),
    ]) {
      expect(
        RegExp(r'json_key_data').hasMatch(source),
        isFalse,
        reason: '$name must not pass key content',
      );
      expect(
        RegExp(r'\.json\b').hasMatch(source),
        isFalse,
        reason: '$name must not name a key file',
      );
    }
    expect(fastfile, isNot(contains('json_key_file')));
    expect(RegExp(r'json_key:\s*(\S+)').allMatches(fastfile).map((m) => m[1]), [
      'key,',
    ]);
    expect(fastfile, contains('key = ENV["TETHER_PLAY_JSON_KEY"].to_s'));

    // The only environment variables the Fastfile reads by name.
    final envNames = RegExp(r'ENV\["([^"]+)"\]')
        .allMatches(fastfile)
        .map((m) => m[1])
        .toSet();
    expect(envNames, {
      'CI',
      'GITHUB_ACTIONS',
      'TETHER_PLAY_JSON_KEY',
      'FASTLANE_SKIP_ALL_LANE_SUMMARIES',
    });
  });

  test('the key must resolve outside the repository', () {
    expect(fastfile, contains('key = File.realpath(key)'));
    expect(fastfile, contains('if inside_repo?(key)'));
  });

  test('only the internal and validate lanes exist', () {
    final lanes = RegExp(
      r'^\s*lane\s+:(\w+)',
      multiLine: true,
    ).allMatches(fastfile).map((m) => m[1]).toList();
    expect(lanes, ['internal', 'validate']);
    expect(
      fastfile,
      isNot(matches(RegExp(r'\b(private_lane|override_lane)\b'))),
    );
    expect(
      RegExp(
        r'^platform\s+:(\w+)',
        multiLine: true,
      ).allMatches(fastfile).map((m) => m[1]),
      ['android'],
    );
  });

  test(
    'track "internal" and status "draft" are the only ones, as literals',
    () {
      expect(
        RegExp(
          r'\btrack:\s*(.+)$',
          multiLine: true,
        ).allMatches(fastfile).map((m) => m[1]),
        ['"internal",'],
      );
      expect(
        RegExp(
          r'\brelease_status:\s*(.+)$',
          multiLine: true,
        ).allMatches(fastfile).map((m) => m[1]),
        ['"draft",'],
      );
      final lower = fastfile.toLowerCase();
      for (final other in [
        'production',
        'beta',
        'alpha',
        'completed',
        'inprogress',
        'halted',
        'rollout',
        'track_promote',
        'deactivate_on_promote',
      ]) {
        expect(
          lower,
          isNot(contains(other)),
          reason: 'Fastfile names "$other"',
        );
      }
    },
  );

  test('every skip_upload_* flag is true and the AAB is not skipped', () {
    final flags = {
      for (final m in RegExp(
        r'\b(skip_upload_\w+):\s*(\w+)',
      ).allMatches(fastfile))
        m[1]!: m[2]!,
    };
    expect(flags.keys.toSet(), {
      'skip_upload_apk',
      'skip_upload_metadata',
      'skip_upload_changelogs',
      'skip_upload_images',
      'skip_upload_screenshots',
    });
    expect(flags.values.toSet(), {'true'});
  });

  test('one upload call; validate is validate-only, internal is not', () {
    expect(RegExp(r'\bupload_to_play_store\b').allMatches(fastfile).length, 1);
    expect(RegExp(r'\bsupply\b').hasMatch(fastfile), isFalse);
    expect(
      RegExp(r'validate_only:\s*(\S+)')
          .allMatches(fastfile)
          .map((m) => m[1])
          .toSet(),
      {'true)', 'false)', ')', 'validate_only'},
    );
    expect(laneBody(fastfile, 'validate'), contains('validate_only: true)'));
    expect(laneBody(fastfile, 'internal'), contains('validate_only: false)'));
    for (final lane in ['internal', 'validate']) {
      expect(laneBody(fastfile, lane), contains('checked_inputs(options)'));
    }
  });

  test('no lane builds, signs, bumps a version or touches metadata', () {
    for (final action in [
      'gradle',
      'build_android_app',
      'flutter',
      'increment_',
      'metadata_path',
      'download_from_play_store',
      'upload_to_play_store_internal_app_sharing',
      'validate_play_store_json_key',
      'sign',
    ]) {
      expect(
        fastfile,
        isNot(contains(action)),
        reason: 'Fastfile mentions "$action"',
      );
    }
    expect(
      RegExp(r'\b(version_code|version_name):').hasMatch(fastfile),
      isFalse,
    );
  });

  test('every lane refuses to run under CI', () {
    final start = fastfile.indexOf('  before_all do');
    expect(start, isNot(-1), reason: 'before_all not found');
    final block = fastfile.substring(start, fastfile.indexOf('\n  end', start));
    expect(
      block,
      contains(
        'if !ENV["CI"].to_s.empty? || '
        '!ENV["GITHUB_ACTIONS"].to_s.empty?\n'
        '      UI.user_error!(',
      ),
    );
    expect(block, contains('ENV.keys.grep(/\\ASUPPLY_/)'));
  });

  test('the AAB is checked with --verify-aab before any upload', () {
    expect(
      fastfile,
      contains(
        'verify = ["bash", "tool/build_play_release.sh", '
        '"--verify-aab=#{aab}"]',
      ),
    );
    expect(fastfile, contains('unless system(*verify, chdir: REPO_ROOT)'));
    final verifyAt = fastfile.indexOf('system(*verify');
    expect(verifyAt, lessThan(fastfile.indexOf('[aab, key]')));
  });

  test('no key, keystore or JSON file is tracked under android/', () {
    final offenders = androidFiles()
        .where(
          (p) => RegExp(
            r'\.(json|jks|keystore|p12)$',
            caseSensitive: false,
          ).hasMatch(p),
        )
        .toList();
    expect(offenders, isEmpty);
  });

  test('generated fastlane files and common key file names are ignored', () {
    final result = Process.runSync('git', ['--version']);
    expect(result.exitCode, 0, reason: 'git is needed for this check');
    for (final path in [
      'android/fastlane/report.xml',
      'android/fastlane/README.md',
      'android/vendor/bundle/gem',
      'android/.bundle/config',
      'android/play-store-key.json',
      'play-service-account.json',
      'android/app/upload-service_account.json',
    ]) {
      final ignored = Process.runSync('git', [
        'check-ignore',
        '-q',
        '--no-index',
        path,
      ]);
      expect(ignored.exitCode, 0, reason: '$path is not gitignored');
    }
  });

  test('the Gemfile pins fastlane exactly, matching Gemfile.lock', () {
    final gemfile = code(File(gemfilePath).readAsStringSync());
    expect(gemfile, contains('source "https://rubygems.org"'));
    final gems = RegExp(
      r'^gem\s+"([^"]+)"(.*)$',
      multiLine: true,
    ).allMatches(gemfile).toList();
    expect(gems.map((m) => m[1]), ['fastlane']);
    final pin =
        RegExp(r'^,\s*"(\d+\.\d+\.\d+)"\s*$').firstMatch(gems.single[2]!);
    expect(pin, isNotNull, reason: 'fastlane must be pinned to one version');
    final version = pin![1]!;

    final lock = File(gemfileLockPath).readAsStringSync();
    expect(lock, contains('\nDEPENDENCIES\n  fastlane (= $version)\n'));
    expect(lock, contains('\n    fastlane ($version)\n'));
    expect(lock, contains('\nCHECKSUMS\n'));
    expect(lock, contains('\n  fastlane ($version) sha256='));
  });
}
