// Tether Health — session values, simulation hooks and decision rules.
//
// Inputs on every generated screen write their current value into
// [TSession] under "<screenId>.<key>" (see spec/screens/*.json → key).
// Branches with `decide:` read those values through [TRules], so the app,
// the HTML prototype and the simulation scenarios make identical decisions.
// Thresholds mirror spec/rules.json and are clinical placeholders until
// signed off.
import 'package:flutter/foundation.dart';

abstract final class TSession {
  static final Map<String, Object?> values = <String, Object?>{};
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static void set(String? key, Object? value) {
    if (key == null) return;
    values.remove(key); // keep insertion order = recency
    values[key] = value;
    changes.value++;
  }

  static void clear() {
    values.clear();
    TSim.reset();
    changes.value++;
  }
}

/// Simulation / test hooks. Production code never sets these.
abstract final class TSim {
  /// Outcomes consumed (in order) by the next external decisions
  /// (permission prompts, OAuth results, sign-in results).
  static final List<String> queue = <String>[];

  /// Forces every branch to this outcome (used by the action sweep tests).
  static String? force;

  static void reset() {
    queue.clear();
    force = null;
  }
}

double? _num(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(v.toString());
  return m == null ? null : double.tryParse(m.group(0)!);
}

/// The most recently written of [keys] (TSession keeps insertion order by recency).
Object? _latest(Map<String, Object?> v, List<String> keys) {
  Object? out;
  for (final e in v.entries) {
    if (keys.contains(e.key)) out = e.value;
  }
  return out;
}

List<String> _list(Object? v) => v is List ? v.map((e) => e.toString()).toList() : (v == null ? const [] : [v.toString()]);

abstract final class TRules {
  static const bp = (sysMin: 70, sysMax: 250, diaMin: 40, diaMax: 150, crisisSys: 180, crisisDia: 120);
  static const glucose = (min: 20, max: 600, defaultLow: 70);
  static const zone = (pefMin: 50, pefMax: 900, greenFrom: 400, redBelow: 200);
  static const redSymptoms = ['Can’t speak in full sentences'];
  static const selfHarm = ['Thoughts of harming myself'];
  static const manualRanges = <String, (double, double)>{'A1C': (3, 20), 'LDL': (10, 400), 'eGFR': (1, 150), 'Glucose': (20, 600)};

  /// Returns the outcome label for [rule], or null when inputs are missing.
  static String? decide(String rule, Map<String, Object?> v) {
    if (rule.startsWith('choice:')) {
      final sel = v[rule.substring(7)];
      return sel?.toString();
    }
    switch (rule) {
      case 'hw.bp':
        final readings = <(double, double)>[];
        for (final s in ['hw_log', 'hw_log2']) {
          final sys = _num(v['$s.systolic']), dia = _num(v['$s.diastolic']);
          if (sys == null && dia == null) continue;
          if (sys == null || dia == null) return 'Invalid value';
          readings.add((sys, dia));
        }
        if (readings.isEmpty) return null;
        for (final r in readings) {
          if (r.$1 < bp.sysMin || r.$1 > bp.sysMax || r.$2 < bp.diaMin || r.$2 > bp.diaMax || r.$2 >= r.$1) return 'Invalid value';
        }
        if (readings.any((r) => r.$1 >= bp.crisisSys || r.$2 >= bp.crisisDia)) return '≥180 top or ≥120 bottom';
        return 'Valid · below crisis range';
      case 'st.glucose':
        final g = _num(v['st_log.reading']);
        if (g == null) return null;
        if (g < glucose.min || g > glucose.max) return 'Invalid (outside 20–600)';
        final low = _num(v['st_range.low']) ?? glucose.defaultLow.toDouble();
        return g < low ? 'Below your low' : 'In or above range';
      case 'ca.zone':
        return zoneOf(v);
      case 'ea.selfharm':
        return _list(v['ea_mood.going_on']).any(selfHarm.contains) ? 'Yes' : 'No';
      case 'rec.manual':
        final test = v['records_manual.test']?.toString() ?? 'A1C';
        final value = _num(_latest(v, const ['records_manual.value', 'records_manual_error.value']));
        if (value == null) return null;
        final range = manualRanges[test] ?? (0.0, double.infinity);
        return (value < range.$1 || value > range.$2) ? 'Outside expected range' : 'Valid';
    }
    return null;
  }

  /// Zone from the member's own action-plan thresholds.
  static String zoneOf(Map<String, Object?> v) {
    final pef = _num(v['ca_zone.peak_flow']);
    final symptoms = _list(v['ca_zone.symptoms']);
    final green = _num(v['ca_plan.green_from']) ?? zone.greenFrom.toDouble();
    final red = _num(v['ca_plan.red_below']) ?? zone.redBelow.toDouble();
    if (pef != null && (pef < zone.pefMin || pef > zone.pefMax)) return 'Invalid peak flow';
    if (symptoms.any(redSymptoms.contains) || (pef != null && pef < red)) return 'Red';
    if ((pef != null && pef < green) || symptoms.isNotEmpty) return 'Yellow';
    return 'Green';
  }

  /// Fuzzy match of a selected option label to a branch case label.
  static String? match(String? selected, Iterable<String> cases) {
    if (selected == null) return null;
    final s = selected.toLowerCase();
    final list = cases.toList();
    for (final c in list) {
      if (c.toLowerCase() == s) return c;
    }
    for (final c in list) {
      final l = c.toLowerCase();
      if (s.startsWith(l) || l.startsWith(s)) return c;
    }
    for (final c in list) {
      final l = c.toLowerCase();
      if (l.contains(s) || s.contains(l.split(' ').first)) return c;
    }
    return null;
  }
}
