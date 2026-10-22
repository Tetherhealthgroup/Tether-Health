// GENERATED — settings screens (P-71): screens whose submit updates
// existing state, by the class of their bound controls (spec `bind`).
//
// Consent class: a control starts from the member's stored value only.
// Nothing stored (TData.unset) and not loaded (null) both show it off and
// write nothing; TSession.touched lists what the member changed, and a
// submit must carry only those keys (nothing to send when there are none).
const Set<String> consentSettingsScreens = <String>{
  'account_notifications',
  'account_privacy',
  'program_settings',
  'program_settings_sf',
  'sd_caregiver',
  'sf_buddy',
};

// Plan class: a stored value seeds the control and is written to the
// session; nothing stored (TData.unset) seeds the designed starting value;
// not loaded (null) writes nothing. A submit carries the whole screen state,
// and must not be sent while any bound control on the screen is not loaded.
const Set<String> planSettingsScreens = <String>{
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
