// Between a screen's session values and the sync service's screen answers.
//
// The sync service stores each screen as four maps keyed by block index
// (chips, option, slider, text). A screen's block index here is the
// position of the input in the screen's spec (`screenFields`), so the
// mapping is fixed by the spec:
// - chips, checklist, tiles: `chips[i]` = indices of the chosen options;
// - segmented, radio: `option[i]` = index of the chosen option;
// - toggle: `option[i]` = 1 for on, 0 for off;
// - slider: `slider[i]`;
// - every text-like field (number fields included, as typed): `text[i]`.
// Passwords are never stored. A value the spec does not know (an option no
// longer listed) is left out rather than guessed.
import '../integration/screen_fields.dart';
import '../sync/sync_models.dart';

/// The sync screen id and programme of each plan endpoint's screen.
const Map<String, (String area, String screen)> syncScreenOf = {
  'be_q2': ('be', 'profile'),
  'bf_meds_edit': ('bf', 'meds'),
  'ca_plan': ('ca', 'plan'),
  'ck_q1': ('ck', 'profile'),
  'hw_targets': ('hw', 'targets'),
  'nu_habit': ('nu', 'habit'),
  're_result': ('re', 'plan'),
  'sd_plan': ('sd', 'plan'),
  'sd_safety': ('sd', 'safety'),
  'sf_buddy': ('sf', 'plan'),
  'st_range': ('st', 'range'),
};

/// [values] (session values of [screenId], by field key without the screen
/// prefix) as screen answers.
ScreenAnswers encodeScreen(String screenId, Map<String, Object?> values) {
  // A screen with no inputs stores nothing.
  final spec = screenFields[screenId] ?? const ScreenSpec(null, []);
  final chips = <String, List<int>>{};
  final option = <String, int>{};
  final slider = <String, double>{};
  final text = <String, String>{};
  for (var i = 0; i < spec.fields.length; i++) {
    final field = spec.fields[i];
    final value = values[field.key];
    if (value == null) continue;
    final index = '$i';
    switch (field.type) {
      case FieldType.chips || FieldType.checklist || FieldType.tiles:
        final chosen = value is String ? [value] : value;
        if (chosen is! Iterable) continue;
        chips[index] = [
          for (final v in chosen)
            if (field.options.indexOf('$v') case final at when at >= 0) at,
        ];
      case FieldType.segmented || FieldType.radio:
        final at = field.options.indexOf('$value');
        if (at >= 0) option[index] = at;
      case FieldType.toggle:
        if (value is bool) option[index] = value ? 1 : 0;
      case FieldType.slider:
        if (value is num) slider[index] = value.toDouble();
      case FieldType.password:
        break;
      default:
        final s = '$value';
        if (s.isNotEmpty) text[index] = s;
    }
  }
  return ScreenAnswers(
      chips: chips, option: option, slider: slider, text: text);
}

/// The session values of [screenId] (by field key) stored in [answers].
Map<String, Object?> decodeScreen(String screenId, ScreenAnswers answers) {
  // A screen with no inputs stores nothing.
  final spec = screenFields[screenId] ?? const ScreenSpec(null, []);
  final out = <String, Object?>{};
  for (var i = 0; i < spec.fields.length; i++) {
    final field = spec.fields[i];
    final index = '$i';
    switch (field.type) {
      case FieldType.chips || FieldType.checklist || FieldType.tiles:
        final chosen = answers.chips[index];
        if (chosen == null) continue;
        final labels = [
          for (final at in chosen)
            if (at >= 0 && at < field.options.length) field.options[at],
        ];
        out[field.key] =
            field.type == FieldType.chips && !field.multi && labels.isNotEmpty
                ? [labels.first]
                : labels;
      case FieldType.segmented || FieldType.radio:
        final at = answers.option[index];
        if (at != null && at >= 0 && at < field.options.length) {
          out[field.key] = field.options[at];
        }
      case FieldType.toggle:
        final at = answers.option[index];
        if (at != null) out[field.key] = at == 1;
      case FieldType.slider:
        final v = answers.slider[index];
        if (v != null) out[field.key] = v;
      case FieldType.password:
        break;
      default:
        final v = answers.text[index];
        if (v != null) out[field.key] = v;
    }
  }
  return out;
}

/// The field values of [screenId] in a session snapshot (keys
/// `<screenId>.<key>`), by field key.
Map<String, Object?> screenValues(
    String screenId, Map<String, Object?> payload) {
  final prefix = '$screenId.';
  return {
    for (final MapEntry(:key, :value) in payload.entries)
      if (key.startsWith(prefix)) key.substring(prefix.length): value,
  };
}
