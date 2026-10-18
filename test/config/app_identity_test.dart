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
}
