// The screen field table matches the spec, and screen values round-trip
// through the sync service's screen answers.
import 'dart:convert';
import 'dart:io';

import 'package:breathefree_patient/data/sync_codec.dart';
import 'package:breathefree_patient/integration/screen_fields.dart';
import 'package:flutter_test/flutter_test.dart';

List<Map<String, Object?>> _inputs(Object? node) {
  final out = <Map<String, Object?>>[];
  void walk(Object? o) {
    if (o is Map) {
      if (o.containsKey('key') && o.containsKey('t')) {
        out.add(o.cast<String, Object?>());
      }
      o.values.forEach(walk);
    } else if (o is List) {
      o.forEach(walk);
    }
  }

  walk(node);
  return out;
}

void main() {
  test('the screen field table matches specs-and-design/tether_ui/spec/screens',
      () {
    final fromSpec = <String, List<String>>{};
    for (final file
        in Directory('specs-and-design/tether_ui/spec/screens').listSync()) {
      if (!file.path.endsWith('.json')) continue;
      final d = jsonDecode(File(file.path).readAsStringSync()) as Map;
      final inputs = _inputs([d['body'], d['footer'], d['over']]);
      if (inputs.isEmpty) continue;
      fromSpec[d['id'] as String] = [
        for (final i in inputs) '${i['key']}|${i['bind'] ?? ''}',
      ];
    }
    final table = {
      for (final MapEntry(key: id, value: spec) in screenFields.entries)
        id: [for (final f in spec.fields) '${f.key}|${f.bind ?? ''}'],
    };
    expect(table, fromSpec);
  });

  test('a plan screen with no inputs stores nothing', () {
    expect(screenFields['sd_plan'], isNull);
    expect(encodeScreen('sd_plan', {'x': 1}).isEmpty, isTrue);
    expect(decodeScreen('sd_plan', encodeScreen('sd_plan', {})), isEmpty);
  });

  test('values round-trip by control type', () {
    final values = {
      'medicine': 'Nicotine patch',
      'when': 'Every morning',
      'private_reminder': false,
    };
    final answers = encodeScreen('bf_meds_edit', values);
    expect(decodeScreen('bf_meds_edit', answers), values);
    final range = encodeScreen('st_range', {'value': 'mmol/L'});
    expect(range.option.values.single, 1);
    expect(decodeScreen('st_range', range)['value'], 'mmol/L');
  });

  test('unknown options and passwords are never stored', () {
    final a = encodeScreen('st_range', {'value': 'grains'});
    expect(a.isEmpty, isTrue);
    expect(screenValues('x', {'x.a': 1, 'y.b': 2}), {'a': 1});
  });
}
