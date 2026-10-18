// The store identity must be the same on both platforms and must match the
// Firebase Android app in project `tether-health-llc` (owner decision D3,
// 2026-10-12). Push notifications only reach the registered package.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String kAppId = 'com.TetherHealthLLC.tetherhealth';

void main() {
  test('Android namespace and applicationId use the shared app ID', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('namespace = "$kAppId"'));
    expect(gradle, contains('applicationId = "$kAppId"'));
  });

  test('MainActivity lives in the app ID package', () {
    final activity = File(
            'android/app/src/main/kotlin/com/TetherHealthLLC/tetherhealth/MainActivity.kt')
        .readAsStringSync();
    expect(activity, startsWith('package $kAppId\n'));
  });

  test('every iOS app target uses the shared app ID', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
        .allMatches(pbx)
        .map((m) => m[1]!)
        .toSet();
    expect(ids, {kAppId, '$kAppId.RunnerTests'});
  });

  test('no retired app ID remains in platform config', () {
    final retired = RegExp(r'hshanmug12|com\.breathefree');
    for (final path in [
      'android/app/build.gradle.kts',
      'android/app/src/main/AndroidManifest.xml',
      'ios/Runner.xcodeproj/project.pbxproj',
      'ios/Runner/Info.plist',
    ]) {
      expect(retired.hasMatch(File(path).readAsStringSync()), isFalse,
          reason: path);
    }
  });
}
