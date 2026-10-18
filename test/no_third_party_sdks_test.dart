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
/// person, or serves ads to them.
///
/// A package is forbidden when any `_`-separated segment of its name is one of
/// these, so `firebase_core`, `sentry_flutter` and `flutter_facebook_auth` are
/// all caught. This check runs on its own, after the allowlist: a name here
/// stays forbidden even if somebody also adds it to [allowedRuntimePackages].
const forbiddenFamilies = <String>[
  'adjust',
  'admob',
  'ads',
  'amplitude',
  'analytics',
  'appcenter',
  'appsflyer',
  'braze',
  'bugsnag',
  'clarity',
  'clevertap',
  'countly',
  'crashlytics',
  'datadog',
  'embrace',
  'facebook',
  'firebase',
  'flurry',
  'fullstory',
  'heap',
  'hotjar',
  'instabug',
  'intercom',
  'logrocket',
  'matomo',
  'mixpanel',
  'newrelic',
  'onesignal',
  'posthog',
  'segment',
  'sentry',
  'smartlook',
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
/// not require the package to be in `pubspec.yaml`; it only permits it.
const allowedRuntimePackages = <String, String>{
  'flutter': 'The Flutter SDK itself.',
  'flutter_secure_storage':
      'Keeps the session token in the Keychain / Android Keystore, not in '
          'shared preferences.',
  'flutter_tts':
      'Speaks rescue guidance aloud with the on-device OS speech engine; '
          'sends nothing anywhere (vendored under third_party/).',
  'http': 'Talks to our own API (profile, quit plan, programs, account data).',
  'image_picker':
      'Picks a profile avatar from the camera or photo library; on-device '
          'only, the upload goes to our own Supabase storage.',
  'supabase_flutter':
      'Sign-in, session and storage on our own backend — a service the '
          'patient is a customer of, not a third party collecting them.',
  'url_launcher':
      'Opens the dialer for 988, 911 and the quitlines, and support URLs; it '
          'hands a URI to the platform and has no network access of its own.',
  // Pre-approved; not yet in pubspec.yaml.
  'sign_in_with_apple':
      'Owner decision P-09 (2026-10-17): native social sign-in; th-security '
          'reviewed',
  'google_sign_in':
      'Owner decision P-09 (2026-10-17): native social sign-in; th-security '
          'reviewed',
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

/// Top-level package names in the `dependencies:` block of a pubspec — not
/// `dev_dependencies:`, which never ship.
List<String> runtimeDependencyNames(List<String> pubspec) {
  final start = pubspec.indexWhere((line) => line.trim() == 'dependencies:');
  if (start == -1) return const [];
  final names = <String>[];
  for (final line in pubspec.skip(start + 1)) {
    // The block ends at the next top-level key.
    if (RegExp(r'^[^\s#]').hasMatch(line)) break;
    // Top-level entries are indented exactly two spaces; anything deeper is a
    // constraint such as `sdk: flutter` or `path: third_party/flutter_tts`.
    final match = RegExp(r'^  ([a-z0-9_]+):').firstMatch(line);
    if (match != null) names.add(match.group(1)!);
  }
  return names;
}

/// Every package resolved in a `pubspec.lock`, direct and transitive.
List<String> lockedPackageNames(List<String> lock) {
  final start = lock.indexWhere((line) => line.trim() == 'packages:');
  if (start == -1) return const [];
  final names = <String>[];
  for (final line in lock.skip(start + 1)) {
    if (RegExp(r'^[^\s#]').hasMatch(line)) break;
    final match = RegExp(r'^  ([a-z0-9_]+):\s*$').firstMatch(line);
    if (match != null) names.add(match.group(1)!);
  }
  return names;
}

void main() {
  test('the runtime dependency tree holds only allowed packages', () {
    final names = runtimeDependencyNames(
      File('pubspec.yaml').readAsLinesSync(),
    );
    expect(names, contains('flutter'),
        reason: 'pubspec dependencies block was not found or not parsed');

    expect(
      names.where((name) => !allowedRuntimePackages.containsKey(name)),
      isEmpty,
      reason: 'a runtime package appeared that is not on the allowlist at the '
          'top of this test. Adding one is a decision about what leaves a '
          'patient device — add it there, with the reason, or remove it here.',
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

  test('analytics, ads and crash SDKs stay forbidden, allowlist or not', () {
    final pubspecNames = runtimeDependencyNames(
      File('pubspec.yaml').readAsLinesSync(),
    );
    final lock = File('pubspec.lock');
    final lockedNames = lock.existsSync()
        ? lockedPackageNames(lock.readAsLinesSync())
        : const <String>[];
    final sources = <String, Iterable<String>>{
      'the allowlist in this test': allowedRuntimePackages.keys,
      'pubspec.yaml dependencies': pubspecNames,
      'pubspec.lock': lockedNames,
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
  });
}
