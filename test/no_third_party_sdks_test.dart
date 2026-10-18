import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Addendum §3.2: no third-party SDKs on child profiles — no analytics, no
// crash reporters that collect identifiers, no session replay — and the
// addendum warns this is easy to violate accidentally through a transitive
// dependency.
//
// An audit done once is a fact about the day it was done. These tests are the
// audit turned into something that fails the build, which is the only version
// of it that survives the next person adding a package in a hurry.

/// Vendor and SDK-family names that identify an SDK which phones home about a
/// person, serves ads to them, or tracks them for a vendor.
///
/// A package is forbidden when any `_`-separated segment of its name is one of
/// these, so `firebase_core`, `sentry_flutter` and `flutter_facebook_auth` are
/// all caught. This check runs on its own, after the allowlist: a name here
/// stays forbidden even if somebody also adds it to [allowedRuntimePackages].
const forbiddenFamilies = <String>[
  'adjust',
  'admob',
  'ads',
  'agconnect',
  'airship',
  'amplitude',
  'analytics',
  'appcenter',
  'appdynamics',
  'applovin',
  'appmetrica',
  'appsflyer',
  'branch',
  'braze',
  'bugsnag',
  'clarity',
  'clevertap',
  'countly',
  'crashlytics',
  'customerio',
  'datadog',
  'dynatrace',
  'embrace',
  'facebook',
  'firebase',
  'flurry',
  'fullstory',
  'heap',
  'hotjar',
  'instabug',
  'intercom',
  'ironsource',
  'kochava',
  'launchdarkly',
  'logrocket',
  'matomo',
  'mixpanel',
  'moengage',
  'newrelic',
  'onesignal',
  'pendo',
  'posthog',
  'purchases',
  'raygun',
  'revenuecat',
  'rollbar',
  'rudder',
  'segment',
  'sentry',
  'singular',
  'smartlook',
  'statsig',
  'telemetry',
  'umeng',
  'uxcam',
];

/// Whole package names forbidden outright, for SDKs whose name is not a single
/// vendor segment. Kept explicit so the intent is readable without the
/// segment rule.
const forbiddenPackages = <String>[
  'google_mobile_ads',
  'google_analytics',
];

/// Runtime packages this app is allowed to ship, each with the reason.
///
/// The rule this file enforces is the addendum's — no SDK that phones home
/// about a person. Adding to this list is a decision about what leaves a
/// patient device, and the reason belongs here next to the name. An entry does
/// not require the package to be a dependency; it only permits it.
const allowedRuntimePackages = <String, String>{
  'flutter': 'The Flutter SDK itself.',
  'flutter_secure_storage':
      'Keeps the session token in the Keychain / Android Keystore, not in '
          'shared preferences.',
  'flutter_tts':
      'Speaks rescue guidance aloud through the OS speech engine (vendored '
          'under third_party/); the OS may use network voices, the plugin '
          'sends nothing itself.',
  'http': 'Talks to our own API (profile, quit plan, programs, account data).',
  'image_picker':
      'Picks a profile avatar from the camera or photo library; on-device '
          'only, the upload goes to our own Supabase storage.',
  'supabase_flutter':
      'Our Supabase project (vendor/processor; BAA/DPA status to confirm).',
  'url_launcher':
      'Opens the dialer for 988, 911 and the quitlines, and support URLs; it '
          'hands a URI to the platform and has no network access of its own.',
  // Pre-approved; not yet a dependency.
  'sign_in_with_apple':
      'Owner decision P-09 (2026-10-17); th-security review pending (TH-935)',
  'google_sign_in':
      'Owner decision P-09 (2026-10-17); th-security review pending (TH-935)',
};

/// The forbidden family [package] belongs to, or `null` if it is not one.
String? forbiddenFamilyOf(String package) {
  final name = package.toLowerCase();
  if (forbiddenPackages.contains(name)) return name;
  for (final segment in name.split('_')) {
    if (forbiddenFamilies.contains(segment)) return segment;
  }
  return null;
}

String _unquote(String value) {
  final v = value.trim();
  if (v.length >= 2 &&
      ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'")))) {
    return v.substring(1, v.length - 1);
  }
  return v;
}

/// Whether [line] is the top-level YAML key [key], quoted or not, with or
/// without a space before the colon.
bool _isTopLevelKey(String line, String key) =>
    RegExp('^(["\']?)$key\\1\\s*:').hasMatch(line);

/// Top-level package names in the `dependencies:` block of a pubspec — not
/// `dev_dependencies:`, which never ship. Accepts quoted keys (`"collection":`)
/// and a space before the colon (`collection :`).
///
/// Secondary to [directRuntimeDependencies]: `pubspec.lock` is the authority.
List<String> runtimeDependencyNames(List<String> pubspec) {
  final start = pubspec.indexWhere(
    (line) => _isTopLevelKey(line, 'dependencies'),
  );
  if (start == -1) return const [];
  final names = <String>[];
  for (final line in pubspec.skip(start + 1)) {
    // The block ends at the next top-level key.
    if (RegExp(r'^[^\s#]').hasMatch(line)) break;
    // Top-level entries are indented exactly two spaces; anything deeper is a
    // constraint such as `sdk: flutter` or `path: third_party/flutter_tts`.
    final match = RegExp(
      r'''^  (["']?)([A-Za-z0-9_]+)\1\s*:''',
    ).firstMatch(line);
    if (match != null) names.add(match.group(2)!);
  }
  return names;
}

/// Whether a pubspec declares a `dependency_overrides:` block.
bool hasDependencyOverrides(List<String> pubspec) =>
    pubspec.any((line) => _isTopLevelKey(line, 'dependency_overrides'));

/// One entry of the `packages:` map in a `pubspec.lock`.
class LockedPackage {
  LockedPackage(this.name);

  final String name;
  String? dependency;
  String? source;

  /// Scalar `description:`, e.g. `flutter` for SDK packages.
  String? description;

  /// Mapping `description:` fields, e.g. `name`, `url`, `path`, `relative`.
  final Map<String, String> descriptionFields = {};

  @override
  String toString() => '$name ($dependency, $source, '
      '${description ?? descriptionFields})';
}

/// Every package resolved in a `pubspec.lock`, direct and transitive.
List<LockedPackage> parseLock(List<String> lock) {
  final start = lock.indexWhere((line) => _isTopLevelKey(line, 'packages'));
  if (start == -1) return const [];
  final packages = <LockedPackage>[];
  LockedPackage? current;
  var inDescription = false;
  for (final line in lock.skip(start + 1)) {
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    if (RegExp(r'^\S').hasMatch(line)) break;

    final entry = RegExp(r'^  (\S.*?)\s*:\s*$').firstMatch(line);
    if (entry != null) {
      current = LockedPackage(_unquote(entry.group(1)!));
      packages.add(current);
      inDescription = false;
      continue;
    }
    if (current == null) continue;

    final field = RegExp(r'^    ([A-Za-z_-]+)\s*:\s*(.*)$').firstMatch(line);
    if (field != null) {
      final key = field.group(1)!;
      final value = _unquote(field.group(2)!);
      inDescription = key == 'description' && value.isEmpty;
      switch (key) {
        case 'dependency':
          current.dependency = value;
        case 'source':
          current.source = value;
        case 'description':
          if (value.isNotEmpty) current.description = value;
      }
      continue;
    }

    final sub = RegExp(r'^      ([A-Za-z_-]+)\s*:\s*(.*)$').firstMatch(line);
    if (sub != null && inDescription) {
      current.descriptionFields[sub.group(1)!] = _unquote(sub.group(2)!);
    }
  }
  return packages;
}

/// Names of the packages the app depends on directly at runtime, as resolved.
List<String> directRuntimeDependencies(List<LockedPackage> packages) => [
      for (final package in packages)
        if (package.dependency == 'direct main' ||
            package.dependency == 'direct overridden')
          package.name,
    ];

/// Why [package] comes from a source this app does not accept, or `null`.
///
/// Accepted: `hosted` on https://pub.dev, `sdk`, and a relative `path` under
/// `third_party/`. Anything else — git, another host, another path — is a
/// way to ship code the allowlist never saw.
String? sourceViolation(LockedPackage package) {
  switch (package.source) {
    case 'hosted':
      final url = package.descriptionFields['url'];
      return url == 'https://pub.dev'
          ? null
          : 'hosted on "$url", not https://pub.dev';
    case 'sdk':
      return null;
    case 'path':
      final path = package.descriptionFields['path'] ?? '';
      final relative = package.descriptionFields['relative'] == 'true';
      final segments = path.split('/');
      final underThirdParty = relative &&
          segments.length >= 2 &&
          segments.first == 'third_party' &&
          !segments.contains('..') &&
          !path.contains(r'\');
      return underThirdParty ? null : 'path "$path" is not under third_party/';
    default:
      return 'source "${package.source}" is not hosted, sdk or path';
  }
}

void main() {
  late List<LockedPackage> locked;

  setUpAll(() {
    final lock = File('pubspec.lock');
    expect(lock.existsSync(), isTrue, reason: 'pubspec.lock is missing');
    locked = parseLock(lock.readAsLinesSync());
  });

  test('every direct runtime dependency in pubspec.lock is allowlisted', () {
    final direct = directRuntimeDependencies(locked);
    expect(direct, contains('flutter'),
        reason: 'pubspec.lock was not parsed: no direct main "flutter"');

    expect(
      direct.where((name) => !allowedRuntimePackages.containsKey(name)),
      isEmpty,
      reason: 'a runtime package appeared that is not on the allowlist at the '
          'top of this test. Adding one is a decision about what leaves a '
          'patient device — add it there, with the reason, or remove it here.',
    );
  });

  test('pubspec.yaml runtime dependencies are allowlisted too', () {
    final names = runtimeDependencyNames(
      File('pubspec.yaml').readAsLinesSync(),
    );
    expect(names, contains('flutter'),
        reason: 'pubspec dependencies block was not found or not parsed');

    expect(
      names.where((name) => !allowedRuntimePackages.containsKey(name)),
      isEmpty,
      reason: 'pubspec.yaml declares a runtime package that is not on the '
          'allowlist at the top of this test.',
    );
  });

  test('every allowlist entry carries a one-line reason', () {
    for (final entry in allowedRuntimePackages.entries) {
      expect(entry.value.trim(), isNotEmpty,
          reason: '${entry.key} has no reason');
      expect(entry.value.contains('\n'), isFalse,
          reason: '${entry.key} reason is more than one line');
    }
  });

  test('every locked package comes from pub.dev, the SDK or third_party/', () {
    expect(locked, isNotEmpty, reason: 'pubspec.lock lists no packages');
    for (final package in locked) {
      expect(
        sourceViolation(package),
        isNull,
        reason: 'pubspec.lock: ${package.name} — ${sourceViolation(package)}.',
      );
    }
  });

  test('nothing overrides the resolved dependencies', () {
    expect(
      hasDependencyOverrides(File('pubspec.yaml').readAsLinesSync()),
      isFalse,
      reason: 'pubspec.yaml has a dependency_overrides block, which can swap '
          'an allowlisted package for code from anywhere.',
    );
    expect(
      File('pubspec_overrides.yaml').existsSync(),
      isFalse,
      reason: 'pubspec_overrides.yaml overrides dependencies outside '
          'pubspec.yaml.',
    );
  });

  test('analytics, ads and crash SDKs stay forbidden, allowlist or not', () {
    final sources = <String, Iterable<String>>{
      'the allowlist in this test': allowedRuntimePackages.keys,
      'pubspec.yaml dependencies': runtimeDependencyNames(
        File('pubspec.yaml').readAsLinesSync(),
      ),
      'pubspec.lock': locked.map((package) => package.name),
    };

    for (final source in sources.entries) {
      for (final name in source.value) {
        expect(
          forbiddenFamilyOf(name),
          isNull,
          reason: '${source.key} contains "$name", which is in the '
              '"${forbiddenFamilyOf(name)}" family. Addendum §3.2 forbids '
              'analytics, ads, crash reporters that collect identifiers and '
              'session replay, including through a transitive dependency. '
              'The allowlist cannot override this.',
        );
      }
    }
  });

  test('no forbidden SDK appears anywhere in the build configuration', () {
    final files = <String>[
      'pubspec.yaml',
      'pubspec.lock',
      'android/app/build.gradle.kts',
      'android/build.gradle.kts',
      'android/settings.gradle.kts',
      'android/app/src/main/AndroidManifest.xml',
      'ios/Runner/Info.plist',
    ];

    for (final path in files) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final contents = file.readAsStringSync().toLowerCase();
      for (final fragment in forbiddenFamilies) {
        // Bounded by anything that is not a letter or digit, so `_`, `.` and
        // `-` count as boundaries (`firebase_core`, `com.google.firebase`)
        // while `windowSoftInputMode="adjustResize"` is not mistaken for the
        // Adjust SDK.
        expect(
          RegExp('(?<![a-z0-9])$fragment(?![a-z0-9])').hasMatch(contents),
          isFalse,
          reason:
              '$path mentions "$fragment". Addendum §3.2 forbids analytics, '
              'crash reporters that collect identifiers and session replay on '
              'child profiles, including through a transitive dependency.',
        );
      }
    }
  });

  test('no Android library dependency outside the Kotlin runtime', () {
    // The only native dependency that may be declared is the Kotlin runtime
    // (kotlinx-coroutines, which Pigeon-generated @async channels need). It
    // collects nothing and talks to nobody; anything else is a decision.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final declared = RegExp(r'implementation\("([^"]+)"\)')
        .allMatches(gradle)
        .map((match) => match.group(1)!)
        .toList();

    expect(
      declared.every((dep) => dep.startsWith('org.jetbrains.kotlinx:')),
      isTrue,
      reason: 'an Android dependency was added outside the Kotlin runtime: '
          '$declared',
    );
  });

  group('self-check: the guard catches what it claims to', () {
    test('forbidden families are recognised by name', () {
      for (final name in [
        'firebase_core',
        'firebase_analytics',
        'firebase_crashlytics',
        'sentry_flutter',
        'amplitude_flutter',
        'mixpanel_flutter',
        'segment_analytics',
        'appsflyer_sdk',
        'facebook_app_events',
        'flutter_facebook_auth',
        'google_mobile_ads',
        'flutter_branch_sdk',
        'purchases_flutter',
        'launchdarkly_flutter_client_sdk',
        'rollbar_flutter',
        'statsig',
        'appmetrica_plugin',
        'agconnect_core',
      ]) {
        expect(forbiddenFamilyOf(name), isNotNull, reason: name);
      }
    });

    test('every allowlisted package passes the denylist', () {
      for (final name in allowedRuntimePackages.keys) {
        expect(forbiddenFamilyOf(name), isNull, reason: name);
      }
    });

    test('dev_dependencies are not read as runtime dependencies', () {
      const pubspec = '''
name: synthetic_app
dependencies:
  flutter:
    sdk: flutter
  # a comment
  local_pkg:
    path: third_party/local_pkg
  firebase_core: ^3.0.0

dev_dependencies:
  sentry_flutter: ^8.0.0
''';
      final names = runtimeDependencyNames(pubspec.split('\n'));
      expect(names, ['flutter', 'local_pkg', 'firebase_core']);
      expect(
        names.where((name) => !allowedRuntimePackages.containsKey(name)),
        ['local_pkg', 'firebase_core'],
      );
      expect(names.map(forbiddenFamilyOf).whereType<String>(), ['firebase']);
    });

    test('quoted keys, spaced colons and overrides are caught', () {
      const pubspec = '''
"dependencies" :
  flutter:
    sdk: flutter
  "collection": ^1.18.0
  'meta' : ^1.9.0
dependency_overrides:
  http: ^1.0.0
''';
      final lines = pubspec.split('\n');
      final names = runtimeDependencyNames(lines);
      expect(names, ['flutter', 'collection', 'meta']);
      expect(
        names.where((name) => !allowedRuntimePackages.containsKey(name)),
        ['collection', 'meta'],
      );
      expect(hasDependencyOverrides(lines), isTrue);
      expect(
          hasDependencyOverrides(['dependencies:', '  http: ^1.0.0']), isFalse);
    });

    test('lock parsing finds direct deps and rejects foreign sources', () {
      const lock = '''
# Generated by pub
packages:
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  http:
    dependency: "direct overridden"
    description:
      name: http
      sha256: aa
      url: "https://pub.dev"
    source: hosted
    version: "1.6.0"
  vendored:
    dependency: transitive
    description:
      path: "third_party/vendored"
      relative: true
    source: path
    version: "1.0.0"
  from_git:
    dependency: "direct main"
    description:
      path: "."
      ref: main
      resolved-ref: bb
      url: "https://github.com/example/from_git.git"
    source: git
    version: "1.0.0"
  other_host:
    dependency: transitive
    description:
      name: other_host
      sha256: cc
      url: "https://pub.example.test"
    source: hosted
    version: "1.0.0"
  escaped_path:
    dependency: transitive
    description:
      path: "third_party/../../elsewhere"
      relative: true
    source: path
    version: "1.0.0"
  absolute_path:
    dependency: transitive
    description:
      path: "/tmp/elsewhere"
      relative: false
    source: path
    version: "1.0.0"
sdks:
  dart: ">=3.4.0 <4.0.0"
''';
      final packages = parseLock(lock.split('\n'));
      expect(packages.map((package) => package.name), [
        'flutter',
        'http',
        'vendored',
        'from_git',
        'other_host',
        'escaped_path',
        'absolute_path',
      ]);
      expect(
          directRuntimeDependencies(packages), ['flutter', 'http', 'from_git']);
      expect(
        packages
            .where((package) => sourceViolation(package) != null)
            .map((package) => package.name),
        ['from_git', 'other_host', 'escaped_path', 'absolute_path'],
      );
    });
  });
}
