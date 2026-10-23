// Settings screens (P-71): the stored values their bound controls start
// from, and the class of each screen.
//
// Consent class: a control starts from the member's stored value only; a
// submit carries only the keys the member changed (TSession.touched), and
// with none there is nothing to send. Plan class: a stored value seeds the
// control and nothing stored seeds the designed value; a submit carries the
// whole screen and is not sent while any bound control is not loaded.
//
// Values:
// - notification switches: GET /v1/notifications/preferences (nothing stored
//   until the member saved them once);
// - `enrolment.<programme>.*`: GET /v1/enrolments (status and live
//   consents);
// - plan controls and the ScrollFree buddy switch: the sync document;
// - account-level privacy switches and the caregiver switch: no stored
//   value exists anywhere yet, so they answer "nothing stored" (off).
import '../api/tether_api.dart';
import '../data/app_services.dart';
import '../data/sync_codec.dart';
import 'data_adapter.dart';
import 'screen_fields.dart';

/// Consent-class settings screens (the kit's `consentSettingsScreens`).
const Set<String> consentSettingsScreens = {
  'account_notifications',
  'account_privacy',
  'program_settings',
  'program_settings_sf',
  'sd_caregiver',
  'sf_buddy',
};

/// Plan-class settings screens (the kit's `planSettingsScreens`).
const Set<String> planSettingsScreens = {
  'be_q2',
  'bf_meds_edit',
  'bf_review',
  'ca_plan',
  'ck_q1',
  'ea_plan',
  'hw_targets',
  'nu_habit',
  're_result',
  'sd_plan',
  'sd_safety',
  'st_range',
};

/// The session keys of [screenId]'s bound controls.
Set<String> boundKeysOf(String screenId) => {
      for (final field
          in screenFields[screenId]?.fields ?? const <ScreenField>[])
        if (field.bind != null) '$screenId.${field.key}',
    };

/// The enrolment status as the program settings radio shows it.
const Map<EnrolmentStatus, String> statusLabels = {
  EnrolmentStatus.focus: 'Focus',
  EnrolmentStatus.learnOnly: 'Learn only',
  EnrolmentStatus.paused: 'Pause',
};

/// The stored values of the settings controls.
class SettingsSource implements DataSource {
  SettingsSource(this._services);

  final AppServices _services;

  static final RegExp _enrolmentKey = RegExp(
      r'^enrolment\.([a-z]{2})\.(status|care_team_sharing|de_identified_research)$');

  /// Bound keys whose value comes from the sync document, with the screen.
  static final Map<String, (String screen, String field)> _syncKeys = {
    for (final MapEntry(key: screen, value: spec) in screenFields.entries)
      if (syncScreenOf.containsKey(screen))
        for (final field in spec.fields)
          if (field.bind != null && !field.bind!.contains(':program'))
            field.bind!: (screen, field.key),
  };

  static const Set<String> _alwaysUnset = {
    'consents.cross_program_insights',
    'consents.de_identified_research',
    'consents.anonymous_app_diagnostics',
    'sd.caregiver.can_see',
  };

  @override
  bool covers(String bindKey) =>
      bindKey.startsWith('notifications.') &&
          _notificationKeys.contains(bindKey) ||
      _enrolmentKey.hasMatch(bindKey) ||
      _syncKeys.containsKey(bindKey) ||
      _alwaysUnset.contains(bindKey);

  static const Set<String> _notificationKeys = {
    'notifications.check_ins_and_plan_reminders',
    'notifications.show_sensitive_details',
    'notifications.quiet_hours',
  };

  @override
  Future<Map<String, Object?>?> load() async {
    final out = <String, Object?>{};
    if (_services.signedIn) {
      final prefs = await _services.api.records.notificationPreferences();
      final enrolments = await _services.api.enrolments.list();
      if (!prefs.isSuccess || !enrolments.isSuccess) return null;
      final p = prefs.valueOrNull!;
      if (p.persisted) {
        out['notifications.check_ins_and_plan_reminders'] = p.remindersEnabled;
        out['notifications.show_sensitive_details'] = p.sensitiveDetails;
        out['notifications.quiet_hours'] = p.quietHoursEnabled;
      }
      for (final e in enrolments.valueOrNull!.enrolments) {
        final label = statusLabels[e.status];
        if (label == null) continue; // left: nothing to show
        final prefix = 'enrolment.${e.programmeCode}';
        out['$prefix.status'] = label;
        bool live(ConsentPurpose purpose) =>
            e.consents.any((c) => c.purpose == purpose && c.revokedAt == null);
        out['$prefix.care_team_sharing'] = live(ConsentPurpose.shareCareTeam);
        out['$prefix.de_identified_research'] = live(ConsentPurpose.research);
      }
    }
    await _services.openSync();
    for (final MapEntry(key: bind, value: (screen, field))
        in _syncKeys.entries) {
      final (area, syncScreen) = syncScreenOf[screen]!;
      final answers = _services.sync.answersOf(area, syncScreen);
      if (answers == null) continue;
      final value = decodeScreen(screen, answers)[field];
      if (value != null) out[bind] = value;
    }
    return out;
  }
}
