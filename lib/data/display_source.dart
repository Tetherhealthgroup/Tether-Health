// Display values of the bound slots (spec/bindings.json) that are the
// member's own data as such: a reading, a count, a series, a name. Slots
// whose value is a sentence (copy around a value) are not filled here; they
// show the example with the "Example" tag until their wording is reviewed
// and translated.
import '../api/tether_api.dart';
import '../integration/data_adapter.dart';
import 'app_services.dart';

/// Bind keys filled from Today, the profile and the sign-in.
const Set<String> todayKeys = {
  'profile.name',
  'profile.email',
  'hw.last_bp',
  'st.last_glucose',
  're.egfr_latest',
};

/// Bind keys filled from a programme's 30-day summary, by programme.
const Map<String, Set<String>> summaryKeys = {
  'hw': {'hw.avg_30d', 'hw.readings_30d', 'hw.systolic_series'},
  'st': {'st.after_meal_series'},
  're': {'re.egfr_series', 're.acr_latest'},
  'ca': {
    'ca.peak_flow_series',
    'ca.days_green',
    'ca.days_yellow',
    'ca.days_red'
  },
  'sd': {'sd.falls_30d'},
};

/// A number as shown: whole numbers without decimals.
String showNumber(num value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';

/// Today, the profile and the sign-in.
class TodaySource implements DataSource {
  TodaySource(this._services);

  final AppServices _services;

  @override
  bool covers(String bindKey) => todayKeys.contains(bindKey);

  @override
  Future<Map<String, Object?>?> load() async {
    if (!_services.signedIn) return const {};
    final today = await _services.api.records.today();
    final profile = await _services.api.account.profile();
    if (!today.isSuccess) return null;
    final out = <String, Object?>{};
    final email = _services.backend.auth.currentIdentity?.email;
    if (email != null && email.isNotEmpty) out['profile.email'] = email;
    final name = profile.valueOrNull?.displayName;
    if (name != null && name.trim().isNotEmpty) {
      out['profile.name'] = name.trim();
    }
    for (final block in today.valueOrNull!.programmes) {
      final f = block.fields;
      switch (block.code) {
        case 'hw':
          final bp = f['lastBp'];
          if (bp is Map && bp['systolic'] is num) {
            final d = bp['diastolic'];
            out['hw.last_bp'] = d is num
                ? '${showNumber(bp['systolic'] as num)}/${showNumber(d)}'
                : showNumber(bp['systolic'] as num);
          }
        case 'st':
          final g = f['lastGlucose'];
          if (g is Map && g['value'] is num) {
            out['st.last_glucose'] = showNumber(g['value'] as num);
          }
        case 're':
          final labs = f['lastLabs'];
          final egfr = labs is Map ? labs['egfr'] : null;
          if (egfr is Map && egfr['value'] is num) {
            out['re.egfr_latest'] = showNumber(egfr['value'] as num);
          }
      }
    }
    return out;
  }
}

/// One programme's 30-day summary.
class SummarySource implements DataSource {
  SummarySource(this._services, this.programme);

  final AppServices _services;
  final String programme;

  @override
  bool covers(String bindKey) =>
      summaryKeys[programme]?.contains(bindKey) ?? false;

  List<num> _values(RecordsSummary s, String metric,
          [bool Function(Map<String, Object?>)? where]) =>
      [
        for (final o in s.observations)
          if (o['metric'] == metric &&
              o['value'] is num &&
              (where == null || where(o)))
            o['value']! as num,
      ];

  @override
  Future<Map<String, Object?>?> load() async {
    if (!_services.signedIn) return const {};
    final result = await _services.api.records
        .summary(programme: programme, range: SummaryRange.days30);
    if (result.errorOrNull?.code == ApiProblemCode.enrolmentNotFound) {
      return const {};
    }
    final s = result.valueOrNull;
    if (s == null) return null;
    final out = <String, Object?>{};
    switch (programme) {
      case 'hw':
        final sys = _values(s, 'bp_systolic');
        final dia = _values(s, 'bp_diastolic');
        if (sys.isNotEmpty) {
          out['hw.readings_30d'] = '${sys.length}';
          out['hw.systolic_series'] = sys;
          num avg(List<num> v) => v.reduce((a, b) => a + b) / v.length;
          out['hw.avg_30d'] = dia.isEmpty
              ? '${avg(sys).round()}'
              : '${avg(sys).round()}/${avg(dia).round()}';
        }
      case 'st':
        final afterMeal = _values(s, 'glucose', (o) {
          final a = o['attributes'];
          return a is Map && a['timing'] == '2_h_after_meal';
        });
        if (afterMeal.isNotEmpty) out['st.after_meal_series'] = afterMeal;
      case 're':
        final egfr = _values(s, 'egfr');
        if (egfr.isNotEmpty) out['re.egfr_series'] = egfr;
        final acr = _values(s, 'urine_acr');
        if (acr.isNotEmpty) {
          out['re.acr_latest'] = '${showNumber(acr.last)} mg/g';
        }
      case 'ca':
        final flow = _values(s, 'peak_flow');
        if (flow.isNotEmpty) out['ca.peak_flow_series'] = flow;
        final days = <String, Set<String>>{};
        for (final e in s.entries) {
          final payload = e['payload'];
          final at = e['at'];
          if (e['kind'] != 'ca.zone_check' ||
              payload is! Map ||
              at is! String) {
            continue;
          }
          (days[payload['zone'] as String? ?? ''] ??= {})
              .add(at.substring(0, 10));
        }
        if (days.isNotEmpty) {
          for (final zone in ['green', 'yellow', 'red']) {
            out['ca.days_$zone'] = '${days[zone]?.length ?? 0}';
          }
        }
      case 'sd':
        out['sd.falls_30d'] =
            '${s.entries.where((e) => e['kind'] == 'sd.fall').length}';
    }
    return out;
  }
}
