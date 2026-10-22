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

  /// Incremented by every [clear]. State that belongs to the previous
  /// session (for example submits still in flight in `TNav`) compares it
  /// and drops itself.
  static int get epoch => _epoch;
  static int _epoch = 0;

  static void set(String? key, Object? value) {
    if (key == null) return;
    values.remove(key); // keep insertion order = recency
    values[key] = value;
    changes.value++;
  }

  /// Removes [keys] from the session. Call right after a submit for values
  /// that must not stay in memory (see [scrubPasswords]).
  static void scrub(Iterable<String> keys) {
    var removed = false;
    for (final key in keys.toList()) {
      _touched.remove(key);
      if (values.containsKey(key)) {
        values.remove(key);
        removed = true;
      }
    }
    if (removed) changes.value++;
  }

  // Keys the member changed on the current instance of their screen (P-71).
  static final Set<String> _touched = <String>{};

  /// The keys of [screenId] ("<screenId>.<key>") that the member changed on
  /// the screen now shown: set by a tap or by typing, and different from the
  /// value the control started from (the stored value on a settings screen).
  /// A control that the member sets back to its starting value is not
  /// touched. Every input control resets its key when it is built, so keys
  /// from an earlier visit to the screen are not included. For a
  /// consent-class settings screen (`consentSettingsScreens`) a submit
  /// carries only these keys; none means there is nothing to send.
  static Set<String> touched(String screenId) => Set<String>.unmodifiable(_touched.where((k) => k.startsWith('$screenId.')));

  /// Whether the member changed [key] on its screen (see [touched]).
  static bool isTouched(String key) => _touched.contains(key);

  /// Kit use: records whether the member has changed [key] from its
  /// starting value. Does not notify [changes].
  static void markTouched(String? key, bool touched) {
    if (key == null) return;
    touched ? _touched.add(key) : _touched.remove(key);
  }

  /// Kit use: a bound control (settings screen) is being built, or its
  /// value is not loaded. Removes [key] and its touched mark without
  /// notifying [changes], so a value from an earlier visit is neither shown
  /// as current nor submitted. A consent-class control writes [key] only when
  /// the member sets it; a plan-class one also writes its loaded value.
  static void forget(String? key) {
    if (key == null) return;
    _touched.remove(key);
    values.remove(key);
  }

  /// Password keys: `*.password` and every `auth_newpass.*` key.
  static bool isPasswordKey(String key) => key.endsWith('.password') || key.startsWith('auth_newpass.');

  /// Removes every password key. The app's API adapter calls this right
  /// after it has submitted them.
  static void scrubPasswords() => scrub(values.keys.where(isPasswordKey));

  /// Empties the whole session (and the simulation hooks). The app calls this
  /// on sign-out, account switch and account deletion, so no other account's
  /// data or password stays in memory. Submits still in flight no longer
  /// block a new tap (see `TNav.submit`). It does not reset `TData`: an
  /// app-owned TData that caches values must drop them at the same points.
  static void clear() {
    values.clear();
    _touched.clear();
    TSim.reset();
    _epoch++;
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

/// Inputs of each "chosen" rule (P-78, P-79), as in spec/rules.json: a
/// primary action on a consent, share or import screen runs only once the
/// member has selected something there. Each rule reads only its own
/// screen's keys.
const _chosenInputs = <String, List<String>>{
  'sup.programs': ['support_add_person.which_programs'],
  'rec.consent.epic': ['records_consent.resources'],
  'rec.consent.medicare': ['records_consent_bb.resources'],
  'rec.consent.device': ['records_consent_device.data_types'],
  'rec.review': ['records_review.keep_hw', 'records_review.keep_st', 'records_review.keep_ck', 'records_review.keep_bf', 'records_review.keep_re'],
  'rec.conflict': ['records_conflict.a1c', 'records_conflict.bp'],
};

/// Whether a session value holds a selection: a non-empty list (chips,
/// checklist) or a chosen item (radio). Null, an empty list and blank text
/// are not.
bool _chosen(Object? v) => v is Iterable ? v.isNotEmpty : (v != null && v.toString().trim().isNotEmpty);

List<String> _list(Object? v) => v is List ? v.map((e) => e.toString()).toList() : (v == null ? const [] : [v.toString()]);

abstract final class TRules {
  static const bp = (sysMin: 70, sysMax: 250, diaMin: 40, diaMax: 150, crisisSys: 180, crisisDia: 120);
  static const glucose = (min: 20, max: 600, defaultLow: 70);
  static const zone = (pefMin: 50, pefMax: 900, greenFrom: 400, redBelow: 200);
  static const redSymptoms = ['Can’t speak in full sentences'];
  static const selfHarm = ['Thoughts of harming myself'];
  static const manualRanges = <String, (double, double)>{'A1C': (3, 20), 'LDL': (10, 400), 'eGFR': (1, 150), 'Glucose': (20, 600)};
  static const unplugSentence = 'I can come back to this later';
  static const unplugSum = (a: 7, b: 5);
  static const ageItem = 'I’m 18 or older';

  /// Returns the outcome label for [rule], or null when inputs are missing.
  static String? decide(String rule, Map<String, Object?> v) {
    if (rule.startsWith('choice:')) {
      final sel = v[rule.substring(7)];
      return sel?.toString();
    }
    final chosenKeys = _chosenInputs[rule];
    if (chosenKeys != null) return chosenKeys.any((k) => _chosen(v[k])) ? 'Chosen' : 'Nothing chosen';
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
      case 'sf.unplug.reason':
        final note = v['sf_unplug_session_end.note']?.toString().trim() ?? '';
        return (_list(v['sf_unplug_session_end.reason']).isNotEmpty || note.isNotEmpty) ? 'Reason given' : 'No reason yet';
      case 'sf.unplug.sentence':
        String norm(Object? s) => (s?.toString() ?? '').toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[.!]+$'), '');
        return norm(v['sf_unplug_gate_commit.sentence']) == norm(unplugSentence) ? 'Step done' : 'Step not done';
      case 'sf.unplug.sum':
        return _num(v['sf_unplug_gate_sum.answer']) == (unplugSum.a + unplugSum.b) ? 'Step done' : 'Step not done';
      case 'ob.age':
        return _list(v['ob_account.age_18_or_older']).contains(ageItem) ? 'Age confirmed' : 'Age not confirmed';
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
