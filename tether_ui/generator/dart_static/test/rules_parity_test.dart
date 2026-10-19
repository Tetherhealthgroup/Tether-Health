// Rules parity: every TRules constant in lib/logic/rules.dart must equal the
// matching param in spec/rules.json, and every param must have a constant.
//
// CLINICAL GATE. The thresholds and lists checked here (blood pressure
// ranges and crisis levels, glucose range and default low, peak-flow range,
// zone defaults and red symptoms, self-harm triggers, manual-value ranges)
// are clinical content, not code. Changing any of them needs written sign-off
// from the clinical lead, plus the specialty that the rule's `source` in
// spec/rules.json names (for example pulmonology for ca.zone, psychiatry for
// ea.selfharm). The commit that changes a value must cite that sign-off.
// The sf.unplug.* params are product rules, not clinical; they are checked
// for parity only.
//
// If this test fails, do not edit either file to make it pass. A mismatch is
// a clinical item for human review. Until it is resolved, record it in
// [_excluded] below with the reason, so the gap stays visible.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/logic/rules.dart';

/// Explicit exclusions from the parity checks. Each key is either a
/// rules.json param path ('<rule>/<param>[/<key>]') or a TRules member
/// ('bp.sysMin', 'redSymptoms'); the value says why it is excluded.
/// An excluded key skips both the value comparison and the coverage checks.
///
/// Mark a known clinical mismatch like this, and never change the value:
///   '<rule>/<param>': 'CLINICAL MISMATCH: TRules <value>, rules.json '
///       '<value>; awaiting clinical-lead sign-off',
///
/// Empty: no mismatch and no unmatched param or constant at the time of
/// writing.
const _excluded = <String, String>{};

/// One rules.json param and the TRules member that mirrors it.
class _Pair {
  const _Pair(this.json, this.dart, this.value);

  /// rules.json path: '<rule id>/<param>' or '<rule id>/<param>/<key>'.
  final String json;

  /// TRules member: a constant, or '<record constant>.<field>'.
  final String dart;

  /// The TRules value, read through the real constant.
  final Object? value;
}

/// The parity table. Values are read from TRules directly, so renaming or
/// removing a constant breaks compilation of this test.
List<_Pair> _pairs() => [
      _Pair('hw.bp/sys_min', 'bp.sysMin', TRules.bp.sysMin),
      _Pair('hw.bp/sys_max', 'bp.sysMax', TRules.bp.sysMax),
      _Pair('hw.bp/dia_min', 'bp.diaMin', TRules.bp.diaMin),
      _Pair('hw.bp/dia_max', 'bp.diaMax', TRules.bp.diaMax),
      _Pair('hw.bp/crisis_sys', 'bp.crisisSys', TRules.bp.crisisSys),
      _Pair('hw.bp/crisis_dia', 'bp.crisisDia', TRules.bp.crisisDia),
      _Pair('st.glucose/min', 'glucose.min', TRules.glucose.min),
      _Pair('st.glucose/max', 'glucose.max', TRules.glucose.max),
      _Pair('st.glucose/default_low', 'glucose.defaultLow', TRules.glucose.defaultLow),
      _Pair('ca.zone/pef_min', 'zone.pefMin', TRules.zone.pefMin),
      _Pair('ca.zone/pef_max', 'zone.pefMax', TRules.zone.pefMax),
      _Pair('ca.zone/default_green_from', 'zone.greenFrom', TRules.zone.greenFrom),
      _Pair('ca.zone/default_red_below', 'zone.redBelow', TRules.zone.redBelow),
      _Pair('ca.zone/red_symptoms', 'redSymptoms', TRules.redSymptoms),
      _Pair('ea.selfharm/triggers', 'selfHarm', TRules.selfHarm),
      for (final e in TRules.manualRanges.entries) _Pair('rec.manual/ranges/${e.key}', 'manualRanges', [e.value.$1, e.value.$2]),
      _Pair('sf.unplug.sentence/sentence', 'unplugSentence', TRules.unplugSentence),
      _Pair('sf.unplug.sum/a', 'unplugSum.a', TRules.unplugSum.a),
      _Pair('sf.unplug.sum/b', 'unplugSum.b', TRules.unplugSum.b),
    ];

/// spec/rules.json, relative to the package root (the flutter test cwd).
Map<String, Object?> _loadSpec() {
  final file = File('../spec/rules.json');
  expect(file.existsSync(), isTrue, reason: '${file.absolute.path} not found; run flutter test from tether_ui/flutter');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

/// Every param leaf in rules.json, keyed by path. Nested maps (such as
/// rec.manual ranges) are flattened one key at a time; lists are leaves.
Map<String, Object?> _specParams(Map<String, Object?> spec) {
  final out = <String, Object?>{};
  void walk(String path, Object? v) {
    if (v is Map) {
      for (final e in v.entries) {
        walk('$path/${e.key}', e.value);
      }
    } else {
      out[path] = v;
    }
  }

  for (final rule in spec.entries) {
    final params = (rule.value as Map<String, Object?>)['params'];
    if (params == null) continue;
    final map = params as Map<String, Object?>;
    for (final p in map.entries) {
      walk('${rule.key}/${p.key}', p.value);
    }
  }
  return out;
}

/// Every constant declared in TRules, read from the source, as members:
/// '<name>.<field>' for a record with named fields, '<name>' otherwise.
Set<String> _declaredMembers() {
  final file = File('lib/logic/rules.dart');
  expect(file.existsSync(), isTrue, reason: '${file.absolute.path} not found');
  final lines = file.readAsLinesSync();
  final start = lines.indexWhere((l) => l.startsWith('abstract final class TRules'));
  expect(start, isNonNegative, reason: 'class TRules not found in ${file.path}');
  final decl = RegExp(r'^\s*static const (\w+)\s*=\s*(.+);\s*$');
  final record = RegExp(r'^\((.*)\)$');
  final field = RegExp(r'^\s*(\w+)\s*:');
  final out = <String>{};
  for (final line in lines.skip(start + 1)) {
    if (line.startsWith('}')) break;
    final m = decl.firstMatch(line);
    if (m == null) continue;
    final name = m.group(1)!;
    final body = record.firstMatch(m.group(2)!.trim());
    final fields = body == null ? const <String>[] : body.group(1)!.split(',').map((f) => field.firstMatch(f)?.group(1)).whereType<String>().toList();
    if (fields.isEmpty) {
      out.add(name);
    } else {
      out.addAll(fields.map((f) => '$name.$f'));
    }
  }
  return out;
}

/// Numbers compare by value (JSON 3 equals Dart 3.0); lists element-wise.
bool _same(Object? a, Object? b) {
  if (a is num && b is num) return a.toDouble() == b.toDouble();
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is num || b is num || a is List || b is List) return false;
  return a == b;
}

bool _isExcluded(_Pair p) => _excluded.containsKey(p.json) || _excluded.containsKey(p.dart);

void main() {
  late Map<String, Object?> params;
  late List<_Pair> pairs;
  late Set<String> members;

  setUpAll(() {
    params = _specParams(_loadSpec());
    pairs = _pairs();
    members = _declaredMembers();
  });

  test('rules.json and rules.dart are both non-empty', () {
    expect(params, isNotEmpty);
    expect(members, isNotEmpty);
    expect(pairs, isNotEmpty);
  });

  test('every TRules constant equals its rules.json param', () {
    final diffs = <String>[];
    for (final p in pairs) {
      if (_isExcluded(p) || !params.containsKey(p.json)) continue;
      if (!_same(p.value, params[p.json])) {
        diffs.add('${p.dart} = ${p.value} but rules.json ${p.json} = ${params[p.json]}');
      }
    }
    expect(diffs, isEmpty, reason: 'Clinical thresholds differ. Do not edit a value to pass; '
        'this needs clinical sign-off (see header).\n${diffs.join('\n')}');
  });

  test('every rules.json param has a TRules constant', () {
    final mirrored = pairs.map((p) => p.json).toSet();
    final missing = params.keys.where((k) => !mirrored.contains(k) && !_excluded.containsKey(k)).toList();
    expect(missing, isEmpty, reason: 'rules.json params with no TRules constant: $missing');
  });

  test('every parity entry points at a real rules.json param', () {
    final dangling = pairs.where((p) => !_isExcluded(p) && !params.containsKey(p.json)).map((p) => '${p.dart} → ${p.json}').toList();
    expect(dangling, isEmpty, reason: 'TRules values with no rules.json param: $dangling');
  });

  test('every TRules constant is in the parity table', () {
    final mapped = pairs.map((p) => p.dart).toSet();
    final unmapped = members.where((m) => !mapped.contains(m) && !_excluded.containsKey(m)).toList();
    final unknown = mapped.where((m) => !members.contains(m)).toList();
    expect(unmapped, isEmpty, reason: 'TRules constants with no rules.json param: $unmapped');
    expect(unknown, isEmpty, reason: 'Parity table names TRules members not declared in rules.dart: $unknown');
  });

  test('every exclusion names a real param or constant', () {
    final known = {...params.keys, ...members, ...pairs.map((p) => p.json)};
    final stale = _excluded.keys.where((k) => !known.contains(k)).toList();
    expect(stale, isEmpty, reason: 'Stale exclusions: $stale');
  });
}
