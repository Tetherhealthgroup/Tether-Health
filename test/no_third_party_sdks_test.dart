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

  /// Runtime packages this app is allowed to ship, and why each is here.
  ///
  /// An allowlist rather than `['flutter']`. The rule this file enforces is
  /// the addendum's — no SDK that phones home about a person — and these two
  /// do not: neither opens a network socket, carries an identifier, or has a
  /// vendor on the other end. The stricter "Flutter only" version banned them
  /// anyway, and the cost was paid on the crisis screen, where a number could
  /// be copied to the clipboard but not dialled. Making somebody in crisis
  /// paste a phone number is a worse outcome than depending on `url_launcher`.
  ///
  /// The list is short on purpose. Adding to it is a decision about what
  /// leaves a patient device, and the reason belongs here next to the name.
  const allowedRuntimePackages = <String>[
    'flutter',
    // Opens the dialer for 988, 911 and the quitlines, and opens a support
    // URL. No network access of its own; it hands a URI to the platform.
    'url_launcher',
    // Speaks the rescue guidance aloud, on-device, for somebody who cannot
    // read a screen in the middle of a craving. Uses the OS speech engine and
    // sends nothing anywhere.
    'flutter_tts',
  ];

  test('the runtime dependency tree holds only allowed packages', () {
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
      names.where((name) => !allowedRuntimePackages.contains(name)),
      isEmpty,
      reason: 'a runtime package appeared that is not on the allowlist at the '
          'top of this test. Adding one is a decision about what leaves a '
          'patient device — add it there, with the reason, or remove it here.',
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
          reason:
              '$path mentions "$fragment". Addendum §3.2 forbids analytics, '
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
