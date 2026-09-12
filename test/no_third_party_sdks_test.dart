import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Addendum §3.2: no third-party SDKs on child profiles — no analytics, no
/// crash reporters that collect identifiers, no session replay — and the
/// addendum warns this is easy to violate accidentally through a transitive
/// dependency.
///
/// An audit done once is a fact about the day it was done. These tests are the
/// audit turned into something that fails the build, which is the only version
/// of it that survives the next person adding a package in a hurry.
void main() {
  /// Vendor names that identify an SDK which phones home about a person.
  ///
  /// Matched on word boundaries, so `firebase_crashlytics` and `sentry_flutter`
  /// are caught by their family name while `windowSoftInputMode="adjustResize"`
  /// is not mistaken for the Adjust SDK.
  const forbidden = <String>[
    'adjust',
    'amplitude',
    'appcenter',
    'appsflyer',
    'braze',
    'bugsnag',
    'clarity',
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
    'onesignal',
    'posthog',
    'segment',
    'sentry',
    'smartlook',
    'umeng',
  ];

  test('the runtime dependency tree is Flutter SDK packages only', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();

    final start = pubspec.indexWhere((line) => line.trim() == 'dependencies:');
    expect(start, isNot(-1), reason: 'pubspec has no dependencies block');
    final end = pubspec.indexWhere(
      (line) => line.trim() == 'dev_dependencies:',
      start + 1,
    );
    expect(end, isNot(-1), reason: 'pubspec has no dev_dependencies block');

    final names = <String>[];
    for (final line in pubspec.sublist(start + 1, end)) {
      // Top-level entries are indented exactly two spaces; anything deeper is
      // a constraint such as `sdk: flutter`.
      final match = RegExp(r'^  ([a-z0-9_]+):').firstMatch(line);
      if (match != null) names.add(match.group(1)!);
    }

    expect(
      names,
      ['flutter'],
      reason: 'the app ships with no runtime package outside the Flutter SDK. '
          'Adding one is a decision about what leaves a patient device.',
    );
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
      for (final fragment in forbidden) {
        expect(
          RegExp('\\b$fragment\\b').hasMatch(contents),
          isFalse,
          reason: '$path mentions "$fragment". Addendum §3.2 forbids analytics, '
              'crash reporters that collect identifiers and session replay on '
              'child profiles, including through a transitive dependency.',
        );
      }
    }
  });

  test('the one native dependency is a language runtime, not an SDK', () {
    // kotlinx-coroutines is on the classpath because Pigeon generates suspend
    // functions for the @async methods on the channel. It collects nothing and
    // talks to nobody; it is listed here so the exception stays deliberate.
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
}
