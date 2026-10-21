// The native slot table lists exactly the native views the generated
// screens draw.
import 'dart:io';

import 'package:breathefree_patient/app/native_slots.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the table holds every native slot id in the generated screens', () {
    final ids = <String>{};
    final slot = RegExp(r"TNativeSlot\(\s*id:\s*'([^']+)'");
    for (final file in Directory('tether_ui/flutter/lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      ids.addAll(slot
          .allMatches(file.readAsStringSync())
          .map((match) => match.group(1)!));
    }
    expect(ids, isNotEmpty, reason: 'no native slot found; check the pattern');
    expect(nativeSlotBuilders.keys.toSet(), ids);
    expect(nativeSlotBuilders.keys.toSet(), {
      'ios.deviceActivityReport.today',
      'ios.deviceActivityReport.week',
      'ios.familyActivityPicker',
    });
  });
}
