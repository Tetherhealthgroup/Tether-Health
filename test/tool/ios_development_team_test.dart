import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Every signing team in the Xcode project must be the Tether Health LLC
// Apple Developer team (docs/IOS_RELEASE.md, owner item O-2).

const expectedTeam = 'HDH9WGZQ45';

void main() {
  test('every DEVELOPMENT_TEAM in project.pbxproj is $expectedTeam', () {
    final pbxproj = File(
      ['ios', 'Runner.xcodeproj', 'project.pbxproj']
          .join(Platform.pathSeparator),
    ).readAsStringSync();

    final mentions = pbxproj
        .split('\n')
        .where((line) => line.contains('DEVELOPMENT_TEAM'))
        .toList();
    // Plain and per-SDK forms, quoted or not:
    //   DEVELOPMENT_TEAM = X;  "DEVELOPMENT_TEAM[sdk=iphoneos*]" = "X";
    final setting = RegExp(
      r'^\s*"?DEVELOPMENT_TEAM(\[[^\]]*\])?"?\s*=\s*"?([^";]*)"?\s*;\s*$',
    );
    final teams = <String>[];
    for (final line in mentions) {
      final match = setting.firstMatch(line);
      expect(match, isNotNull, reason: 'unrecognised setting: $line');
      teams.add(match!.group(2)!);
    }

    expect(teams, isNotEmpty, reason: 'no DEVELOPMENT_TEAM in project.pbxproj');
    expect(teams, everyElement(expectedTeam));
  });
}
