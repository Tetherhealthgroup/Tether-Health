// GENERATED — settings screens (P-71): screens whose submit updates
// existing state. Every input control on them that writes the session is
// bound to the member's stored value (spec `bind`), writes nothing while that
// value is unknown, and records the keys the member changed in
// TSession.touched. A submit from one of these screens must carry only
// those keys, and nothing is sent when there are none.
const Set<String> settingsScreens = <String>{
  'account_notifications',
  'account_privacy',
  'auth_newpass',
  'be_q2',
  'bf_meds_edit',
  'bf_review',
  'ca_plan',
  'ck_q1',
  'ea_plan',
  'hw_targets',
  'nu_habit',
  'program_settings',
  'program_settings_sf',
  're_result',
  'sd_caregiver',
  'sd_plan',
  'sd_safety',
  'sf_buddy',
  'sf_unplug_off',
  'st_range',
};
