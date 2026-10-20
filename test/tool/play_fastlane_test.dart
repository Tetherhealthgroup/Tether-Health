import 'dart:convert';
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

/// The fastlane version the Gemfile pins and Gemfile.lock resolves.
const String fastlaneVersion = '2.241.1';

/// A comment-only line: optional spaces or tabs, then `#`.
final RegExp commentLine = RegExp(r'^[ \t]*#');

/// A blank line: nothing but spaces or tabs.
final RegExp blankLine = RegExp(r'^[ \t]*$');

/// Ruby source with comment lines removed, so prose cannot satisfy or trip a
/// check. The files keep comments on their own lines.
String code(String source) =>
    source.split('\n').where((line) => !commentLine.hasMatch(line)).join('\n');

/// [lines] without the blank ones, in order.
List<String> nonBlank(Iterable<String> lines) =>
    lines.where((line) => !blankLine.hasMatch(line)).toList();

/// The non-blank lines of `lane :<name> do ... end`, two-space indented
/// inside `platform :android do`.
List<String> laneBody(String fastfile, String name) {
  final lines = fastfile.split('\n');
  final start = lines.indexWhere((l) => l.startsWith('  lane :$name do'));
  expect(start, isNot(-1), reason: 'lane :$name not found');
  final end = lines.indexWhere((l) => l == '  end', start + 1);
  expect(end, isNot(-1), reason: 'end of lane :$name not found');
  return nonBlank(lines.sublist(start + 1, end));
}

/// The non-blank lines of the top-level `def <signature>` up to its closing
/// `end`.
List<String> defBody(String fastfile, String signature) {
  final lines = fastfile.split('\n');
  final start = lines.indexOf('def $signature');
  expect(start, isNot(-1), reason: 'def $signature not found');
  final end = lines.indexWhere((l) => l == 'end', start + 1);
  expect(end, isNot(-1), reason: 'end of def $signature not found');
  return nonBlank(lines.sublist(start + 1, end));
}

/// True when the working directory is inside a git work tree.
bool inGitWorkTree() {
  try {
    final result =
        Process.runSync('git', ['rev-parse', '--is-inside-work-tree']);
    return result.exitCode == 0 && (result.stdout as String).trim() == 'true';
  } on ProcessException {
    return false;
  }
}

/// Directories the fallback walks never enter.
const Set<String> skippedDirs = {
  '.git',
  '.dart_tool',
  '.gradle',
  '.cxx',
  '.bundle',
  'build',
  'ephemeral',
  'node_modules',
  'Pods',
  'vendor',
  'coverage',
};

/// Files under [dir] that git tracks or would add (untracked and not
/// ignored). Walks the directory, skipping [skippedDirs], when git or the
/// repository is unavailable.
List<String> repoFiles(String dir) {
  if (inGitWorkTree()) {
    final result = Process.runSync('git', [
      'ls-files',
      '-z',
      '--cached',
      '--others',
      '--exclude-standard',
      dir,
    ]);
    if (result.exitCode == 0) {
      return (result.stdout as String)
          .split('\x00')
          .where((p) => p.isNotEmpty)
          .toList();
    }
  }
  return [
    for (final entity
        in Directory(dir).listSync(recursive: true, followLinks: false))
      if (entity is File &&
          !entity.uri.pathSegments.any((s) => skippedDirs.contains(s)))
        entity.path,
  ];
}

// The security-relevant parts of the Fastfile, pinned exactly (comment lines
// removed). A change to any of them must change this test too, in the same
// reviewed change.

const String pinnedBeforeAll = r'''
    if !ENV["CI"].to_s.empty? || !ENV["GITHUB_ACTIONS"].to_s.empty?
      UI.user_error!("Refusing to run: CI or GITHUB_ACTIONS is set. Play uploads are run by the owner only, never by CI.")
    end
    if !Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::ENVIRONMENT].to_s.empty?
      UI.user_error!("Refusing to run: a fastlane environment (--env) was selected. Its .env file can override the checks.")
    end
    if FastlaneCore::Globals.verbose? || $troubleshoot
      UI.user_error!("Refusing to run with --verbose or --troubleshoot: verbose output can expose credential details.")
    end
    if !ENV["DEBUG"].to_s.empty? || !ENV["FASTLANE_DISABLE_SECRET_MASKING"].to_s.empty?
      UI.user_error!("Refusing to run: DEBUG or FASTLANE_DISABLE_SECRET_MASKING is set. Either can expose credential details.")
    end
    supply_env = ENV.keys.grep(/\ASUPPLY_/).sort
    unless supply_env.empty?
      UI.user_error!("Refusing to run: unset #{supply_env.join(', ')}. The lanes set every upload option themselves.")
    end
    fastlane_dir = File.join(REPO_ROOT, "android", "fastlane")
    unless (Dir.children(fastlane_dir) - ["Appfile", "Fastfile", "README.md", "report.xml"]).empty?
      UI.user_error!("Refusing to run: the fastlane folder holds an extra file or folder (not shown). Only the two tracked files and fastlane's own output may be there.")
    end
    env_files = [File.join(REPO_ROOT, "android"), fastlane_dir].flat_map do |dir|
      Dir.glob("*.env*", File::FNM_DOTMATCH, base: dir)
    end
    unless env_files.empty?
      UI.user_error!("Refusing to run: an environment file (not shown) is in the android or fastlane folder. Remove it before uploading.")
    end
    ENV["FASTLANE_SKIP_ALL_LANE_SUMMARIES"] = "1"''';

/// The lines before the platform block, in order (blank lines removed).
const List<String> pinnedTopLevel = [
  'ENV["FASTLANE_OPT_OUT_USAGE"] = "YES"',
  'ENV["FASTLANE_HIDE_GITHUB_ISSUES"] = "1"',
  'require "json"',
  'opt_out_usage',
  'default_platform(:android)',
  'REPO_ROOT = File.realpath(File.join(Dir.pwd, "..", ".."))',
  'LANE_OPTIONS = [:aab, :min_version_code].freeze',
];

/// The body of `lane :internal do |options| ... end`.
const List<String> pinnedInternalLane = [
  '    aab, key = checked_inputs(options)',
  '    play_upload(aab, key, validate_only: false)',
];

/// The body of `lane :validate do |options| ... end`.
const List<String> pinnedValidateLane = [
  '    aab, key = checked_inputs(options)',
  '    play_upload(aab, key, validate_only: true)',
];

/// Every non-blank line of `platform :android do ... end`, in order, so no
/// callback (error, after_all, before_each, ...) or other line can be added
/// to the block without changing this list.
final List<String> pinnedPlatformBlock = [
  'platform :android do',
  '  before_all do',
  ...pinnedBeforeAll.split('\n'),
  '  end',
  '  desc "Upload an existing, verified AAB to the internal track as a draft"',
  '  lane :internal do |options|',
  ...pinnedInternalLane,
  '  end',
  '  desc "Check an existing, verified AAB with Play without creating a release"',
  '  lane :validate do |options|',
  ...pinnedValidateLane,
  '  end',
  'end',
];

const String pinnedCheckedInputs = r'''
  unless (options.keys - LANE_OPTIONS).empty?
    UI.user_error!("Unknown lane option (not shown). Only aab: and min_version_code: are accepted.")
  end

  key = ENV["TETHER_PLAY_JSON_KEY"].to_s
  UI.user_error!("TETHER_PLAY_JSON_KEY is not set.") if key.empty?
  UI.user_error!("TETHER_PLAY_JSON_KEY does not point to an existing file.") unless File.file?(key)
  key = File.realpath(key)
  if inside_repo?(key)
    UI.user_error!("TETHER_PLAY_JSON_KEY points inside the repository. Keep the key outside it.")
  end
  service_account =
    begin
      JSON.parse(File.read(key))["type"] == "service_account"
    rescue StandardError
      false
    end
  unless service_account
    UI.user_error!("TETHER_PLAY_JSON_KEY does not point to a readable service-account JSON key.")
  end

  aab = options[:aab].to_s
  UI.user_error!("aab: is required (the bundle built by tool/build_play_release.sh).") if aab.empty?
  aab = File.expand_path(aab, REPO_ROOT) # a relative path is read from the repo root
  unless aab.downcase.end_with?(".aab") && File.file?(aab)
    UI.user_error!("aab: does not point to an existing .aab file (path not shown).")
  end
  aab = File.realpath(aab)

  verify = ["bash", "tool/build_play_release.sh", "--verify-aab=#{aab}"]
  if options.key?(:min_version_code)
    verify << "--min-version-code=#{options[:min_version_code]}"
  end
  unless system(*verify, chdir: REPO_ROOT)
    UI.user_error!("tool/build_play_release.sh --verify-aab failed. Nothing was uploaded.")
  end

  [aab, key]''';

const String pinnedInsideRepo = r'''
  path = path.downcase
  root = REPO_ROOT.downcase
  path == root || path.start_with?(root + File::SEPARATOR)''';

const String pinnedPlayUpload = r'''
  upload_to_play_store(
    json_key: key,
    aab: aab,
    track: "internal",
    release_status: "draft",
    skip_upload_apk: true,
    skip_upload_metadata: true,
    skip_upload_changelogs: true,
    skip_upload_images: true,
    skip_upload_screenshots: true,
    validate_only: validate_only
  )''';

/// Every non-blank line of the whole Fastfile, in order, built from the pins
/// above. fastlane also runs callbacks such as `error do` or `after_all do`
/// written outside the platform block, so nothing may be added at the top
/// level either.
final List<String> pinnedFastfile = nonBlank([
  ...pinnedTopLevel,
  ...pinnedPlatformBlock,
  'def checked_inputs(options)',
  ...pinnedCheckedInputs.split('\n'),
  'end',
  'def inside_repo?(path)',
  ...pinnedInsideRepo.split('\n'),
  'end',
  'def play_upload(aab, key, validate_only:)',
  ...pinnedPlayUpload.split('\n'),
  'end',
]);

void main() {
  late String fastfile;
  late String appfile;
  final gitWorkTree = inGitWorkTree();

  setUpAll(() {
    fastfile = code(File(fastfilePath).readAsStringSync());
    appfile = code(File(appfilePath).readAsStringSync());
  });

  test('the Appfile holds only the package, matching the app and script', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final appId =
        RegExp(r'applicationId\s*=\s*"([^"]+)"').firstMatch(gradle)?.group(1);
    expect(appId, isNotNull, reason: 'applicationId not found');

    expect(nonBlank(appfile.split('\n')), ['package_name("$appId")']);

    final script = File('tool/build_play_release.sh').readAsStringSync();
    expect(script, contains('expected_package="$appId"'));
  });

  test('the key path comes only from TETHER_PLAY_JSON_KEY', () {
    // fastlane prints Appfile values under --verbose, so no key setting may
    // live there; the lanes pass the key explicitly.
    expect(appfile, isNot(contains('json_key')));
    expect(appfile, isNot(contains('ENV')));
    expect(RegExp(r'json_key_data|json_key_file').hasMatch(fastfile), isFalse);
    expect(
      RegExp(r'\.json\b').hasMatch(fastfile),
      isFalse,
      reason: 'the Fastfile must not name a key file',
    );
    expect(
      RegExp(r'json_key:\s*(\S+)').allMatches(fastfile).map((m) => m[1]),
      ['key,'],
    );

    // The only environment variables the Fastfile names.
    final envNames = RegExp(r'ENV\["([^"]+)"\]')
        .allMatches(fastfile)
        .map((m) => m[1])
        .toSet();
    expect(envNames, {
      'CI',
      'GITHUB_ACTIONS',
      'TETHER_PLAY_JSON_KEY',
      'DEBUG',
      'FASTLANE_DISABLE_SECRET_MASKING',
      'FASTLANE_SKIP_ALL_LANE_SUMMARIES',
      'FASTLANE_HIDE_GITHUB_ISSUES',
      'FASTLANE_OPT_OUT_USAGE',
    });
  });

  test('top-level lines are pinned; metrics and issue search are off first',
      () {
    // Everything before the platform block, in order. The two ENV lines come
    // before any action call, so even a failure in the first action sends no
    // usage metrics and no GitHub issue search.
    final lines = fastfile.split('\n');
    final platformAt = lines.indexOf('platform :android do');
    expect(platformAt, isNot(-1), reason: 'platform block not found');
    expect(
      nonBlank(lines.sublist(0, platformAt)),
      pinnedTopLevel,
    );
  });

  test('only the internal and validate lanes exist', () {
    final lanes = RegExp(r'^\s*lane\s+:(\w+)', multiLine: true)
        .allMatches(fastfile)
        .map((m) => m[1])
        .toList();
    expect(lanes, ['internal', 'validate']);
    expect(
      fastfile,
      isNot(matches(RegExp(r'\b(private_lane|override_lane)\b'))),
    );
    expect(
      RegExp(r'^platform\s+:(\w+)', multiLine: true)
          .allMatches(fastfile)
          .map((m) => m[1]),
      ['android'],
    );
  });

  test('each lane checks its inputs before the upload, nothing else', () {
    expect(laneBody(fastfile, 'internal'), pinnedInternalLane);
    expect(laneBody(fastfile, 'validate'), pinnedValidateLane);
  });

  test(
      'before_all refuses CI, --env, --verbose, DEBUG, SUPPLY_* variables '
      'and extra fastlane or env files', () {
    final lines = fastfile.split('\n');
    final start = lines.indexOf('  before_all do');
    expect(start, isNot(-1), reason: 'before_all not found');
    final end = lines.indexOf('  end', start + 1);
    expect(
      nonBlank(lines.sublist(start + 1, end)),
      nonBlank(pinnedBeforeAll.split('\n')),
    );
    expect(start, lessThan(lines.indexWhere((l) => l.startsWith('  lane :'))));
  });

  test('the whole platform block is pinned, line by line', () {
    // From `platform :android do` to its `end`, the first unindented `end`
    // after it (everything inside the block is indented). Comment and blank
    // lines are dropped; every other line must match, in order.
    final lines = fastfile.split('\n');
    final start = lines.indexOf('platform :android do');
    expect(start, isNot(-1), reason: 'platform block not found');
    final end = lines.indexOf('end', start + 1);
    expect(end, isNot(-1), reason: 'end of the platform block not found');
    expect(
      nonBlank(lines.sublist(start, end + 1)),
      pinnedPlatformBlock,
    );
  });

  test('the whole Fastfile is pinned, line by line', () {
    // Comment and blank lines are dropped; every other line must match, in
    // order, so no line or block can be added anywhere in the file.
    expect(
      nonBlank(fastfile.split('\n')),
      pinnedFastfile,
    );
  });

  test(
      'inputs are checked as pinned: options, key, service account, AAB, '
      'then a fatal --verify-aab', () {
    expect(
      defBody(fastfile, 'checked_inputs(options)'),
      nonBlank(pinnedCheckedInputs.split('\n')),
    );
  });

  test(
      'the key must resolve outside the repository, compared '
      'case-insensitively', () {
    expect(
      defBody(fastfile, 'inside_repo?(path)'),
      nonBlank(pinnedInsideRepo.split('\n')),
    );
  });

  test('the single upload call is pinned: internal track, draft, skips', () {
    expect(
      defBody(fastfile, 'play_upload(aab, key, validate_only:)'),
      nonBlank(pinnedPlayUpload.split('\n')),
    );
    expect(RegExp(r'\bupload_to_play_store\b').allMatches(fastfile).length, 1);
    expect(RegExp(r'\bsupply\b').hasMatch(fastfile), isFalse);
  });

  test('track "internal" and status "draft" are the only ones, as literals',
      () {
    expect(
      RegExp(r'\btrack:\s*(.+)$', multiLine: true)
          .allMatches(fastfile)
          .map((m) => m[1]),
      ['"internal",'],
    );
    expect(
      RegExp(r'\brelease_status:\s*(.+)$', multiLine: true)
          .allMatches(fastfile)
          .map((m) => m[1]),
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
      expect(lower, isNot(contains(other)), reason: 'Fastfile names "$other"');
    }
  });

  test('every skip_upload_* flag is true and the AAB is not skipped', () {
    final flags = {
      for (final m
          in RegExp(r'\b(skip_upload_\w+):\s*(\w+)').allMatches(fastfile))
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

  test('no key, keystore or JSON file is tracked under android/', () {
    final offenders = repoFiles('android')
        .where(
          (p) => RegExp(r'\.(json|jks|keystore|p12)$', caseSensitive: false)
              .hasMatch(p),
        )
        .toList();
    expect(offenders, isEmpty);
  });

  test('no tracked file holds service-account or private-key content', () {
    // Assembled from fragments so this file does not match itself.
    final needles = [
      RegExp('"type"' r'\s*:\s*' '"service' '_account"'),
      RegExp('-----BEGIN ' r'(?:[A-Z]+ )?' 'PRIVATE ' 'KEY-----'),
    ];
    final offenders = <String>[];
    for (final path in repoFiles('.')) {
      final file = File(path);
      if (!file.existsSync()) continue; // deleted but not yet staged
      final text = latin1.decode(file.readAsBytesSync());
      if (needles.any((n) => n.hasMatch(text))) offenders.add(path);
    }
    expect(offenders, isEmpty);
  });

  test('the ignore files list the fastlane outputs and key file names', () {
    final android = File('android/.gitignore').readAsLinesSync();
    for (final line in [
      '/fastlane/report.xml',
      '/fastlane/README.md',
      '/vendor/bundle/',
      '/.bundle/',
    ]) {
      expect(android, contains(line));
    }
    final root = File('.gitignore').readAsLinesSync();
    for (final line in [
      'play-key*.json',
      '*[-_.]play-key*.json',
      'play-store-key*.json',
      '*[-_.]play-store-key*.json',
      '*service-account*.json',
      '*service_account*.json',
    ]) {
      expect(root, contains(line));
    }
  });

  test(
    'git ignores the fastlane outputs and key names, not ordinary names',
    () {
      bool ignored(String path) =>
          Process.runSync('git', ['check-ignore', '-q', '--no-index', path])
              .exitCode ==
          0;
      for (final path in [
        'android/fastlane/report.xml',
        'android/fastlane/README.md',
        'android/vendor/bundle/gem',
        'android/.bundle/config',
        'android/play-store-key.json',
        'google-play-key.json',
        'play-key.json',
        'play-service-account.json',
        'android/app/upload-service_account.json',
      ]) {
        expect(ignored(path), isTrue, reason: '$path is not gitignored');
      }
      for (final path in [
        'lib/display_keys.json',
        'lib/display-keys.json',
        'lib/replay-key.json',
      ]) {
        expect(ignored(path), isFalse, reason: '$path should not be ignored');
      }
    },
    skip: gitWorkTree
        ? false
        : 'not a git work tree; the ignore files are checked as text above',
  );

  test(
    'android/ and android/fastlane/ hold only the expected files',
    () {
      // Files git tracks or would add (ignored files such as fastlane's
      // generated README.md and report.xml are not listed).
      final files = repoFiles('android');
      expect(
        files.where((p) => p.startsWith('android/fastlane/')).toSet(),
        {'android/fastlane/Appfile', 'android/fastlane/Fastfile'},
      );
      expect(files.where((p) => p.startsWith('android/.fastlane/')), isEmpty);
      expect(
        files.where((p) => p.split('/').length == 2).toSet(),
        {
          'android/.gitignore',
          'android/Gemfile',
          'android/Gemfile.lock',
          'android/build.gradle.kts',
          'android/gradle.properties',
          'android/settings.gradle.kts',
        },
      );
    },
    skip: gitWorkTree
        ? false
        : 'not a git work tree; the file set comes from git ls-files',
  );

  test('the Gemfile is pinned line by line, matching Gemfile.lock', () {
    final gemfile = code(File(gemfilePath).readAsStringSync());
    expect(nonBlank(gemfile.split('\n')), [
      'source "https://rubygems.org"',
      'gem "fastlane", "$fastlaneVersion"',
    ]);

    final lock = File(gemfileLockPath).readAsStringSync();
    expect(lock, contains('\nDEPENDENCIES\n  fastlane (= $fastlaneVersion)\n'));
    expect(lock, contains('\n    fastlane ($fastlaneVersion)\n'));
  });

  test('Gemfile.lock has only the expected sections, in order', () {
    // Every line that does not start with a space is a section header.
    final headers = RegExp(r'^[^ \n].*$', multiLine: true)
        .allMatches(File(gemfileLockPath).readAsStringSync())
        .map((m) => m[0]);
    expect(
      headers,
      ['GEM', 'PLATFORMS', 'DEPENDENCIES', 'CHECKSUMS', 'BUNDLED WITH'],
    );
  });

  test('every locked gem has a sha256 checksum', () {
    final lock = File(gemfileLockPath).readAsStringSync();
    final specsAt = lock.indexOf('\n  specs:\n');
    expect(specsAt, isNot(-1), reason: 'GEM specs not found');
    final specsEnd = lock.indexOf('\n\n', specsAt);
    final specs = RegExp(r'^    (\S+) \(([^)]+)\)$', multiLine: true)
        .allMatches(lock.substring(specsAt, specsEnd))
        .map((m) => '${m[1]} (${m[2]})')
        .toList();
    expect(specs, isNotEmpty);

    final checksumsAt = lock.indexOf('\nCHECKSUMS\n');
    expect(checksumsAt, isNot(-1), reason: 'CHECKSUMS section not found');
    final checksumsEnd = lock.indexOf('\n\n', checksumsAt + 1);
    final checksummed = RegExp(
      r'^  (\S+ \([^)]+\)) sha256=[0-9a-f]{64}$',
      multiLine: true,
    )
        .allMatches(lock.substring(checksumsAt, checksumsEnd))
        .map((m) => m[1])
        .toSet();
    expect(specs.where((s) => !checksummed.contains(s)), isEmpty);
  });
}
