// GENERATED from tether_ui/spec/screens/*.json — the input fields of every
// screen that has any: key, control type, option values (stable, English),
// and the settings bind key. test/integration/screen_fields_test.dart checks
// this table against the spec, so a spec change fails until it follows.
// ignore_for_file: lines_longer_than_80_chars

/// The control type of an input.
enum FieldType {
  chips,
  segmented,
  radio,
  toggle,
  checklist,
  slider,
  tiles,
  text,
  number,
  date,
  select,
  multiline,
  password,
  email,
  phone,
  search,
}

/// One input of a screen; its session key is `<screenId>.<key>`.
class ScreenField {
  const ScreenField(this.key, this.type,
      {this.options = const [],
      this.multi = true,
      this.programs = const [],
      this.bind});

  final String key;
  final FieldType type;

  /// Option or item values, in spec order.
  final List<String> options;

  /// Chips only: whether more than one may be chosen.
  final bool multi;

  /// Tiles only: the programme of each tile (null for none).
  final List<String?> programs;

  /// The settings bind key, or null.
  final String? bind;
}

/// A screen's programme (null for shared screens) and inputs, in spec order.
class ScreenSpec {
  const ScreenSpec(this.program, this.fields);

  final String? program;
  final List<ScreenField> fields;
}

/// Every screen with inputs, by screen id.
const Map<String, ScreenSpec> screenFields = {
  'account_delete': ScreenSpec(null, [
    ScreenField('type_delete_to_confirm', FieldType.text),
    ScreenField('password', FieldType.password),
  ]),
  'account_delete_apple': ScreenSpec(null, [
    ScreenField('type_delete_to_confirm', FieldType.text),
  ]),
  'account_delete_google': ScreenSpec(null, [
    ScreenField('type_delete_to_confirm', FieldType.text),
  ]),
  'account_leave': ScreenSpec(null, [
    ScreenField('value', FieldType.radio,
        options: ['Keep my data', 'Delete BreatheFree data now']),
  ]),
  'account_notifications': ScreenSpec(null, [
    ScreenField('check_ins_and_plan_reminders', FieldType.toggle,
        bind: 'notifications.check_ins_and_plan_reminders'),
    ScreenField('show_sensitive_details', FieldType.toggle,
        bind: 'notifications.show_sensitive_details'),
    ScreenField('quiet_hours', FieldType.toggle,
        bind: 'notifications.quiet_hours'),
  ]),
  'account_privacy': ScreenSpec(null, [
    ScreenField('cross_program_insights', FieldType.toggle,
        bind: 'consents.cross_program_insights'),
    ScreenField('de_identified_research', FieldType.toggle,
        bind: 'consents.de_identified_research'),
    ScreenField('anonymous_app_diagnostics', FieldType.toggle,
        bind: 'consents.anonymous_app_diagnostics'),
  ]),
  'auth_forgot': ScreenSpec(null, [
    ScreenField('email', FieldType.email),
  ]),
  'auth_link': ScreenSpec(null, [
    ScreenField('password', FieldType.password),
  ]),
  'auth_merge': ScreenSpec(null, [
    ScreenField('value', FieldType.radio, options: [
      'Keep both, choose later',
      'Use this phone’s plan',
      'Use the account’s plan'
    ]),
  ]),
  'auth_newpass': ScreenSpec(null, [
    ScreenField('new_password', FieldType.password),
    ScreenField('confirm_password', FieldType.password),
  ]),
  'auth_session': ScreenSpec(null, [
    ScreenField('password', FieldType.password),
  ]),
  'auth_signin': ScreenSpec(null, [
    ScreenField('email', FieldType.email),
    ScreenField('password', FieldType.password),
  ]),
  'auth_signin_error': ScreenSpec(null, [
    ScreenField('email', FieldType.email),
    ScreenField('password', FieldType.password),
  ]),
  'be_diary': ScreenSpec('be', [
    ScreenField('fatigue', FieldType.slider),
    ScreenField('anything_else', FieldType.chips,
        options: ['Nausea', 'Pain', 'Mouth sores', 'Numbness', 'Low mood']),
  ]),
  'be_q1': ScreenSpec('be', [
    ScreenField('stage', FieldType.radio, options: [
      'Lowering my risk',
      'Going through treatment',
      'After treatment',
      'Supporting someone'
    ]),
  ]),
  'be_q2': ScreenSpec('be', [
    ScreenField('value', FieldType.chips,
        options: [
          'Breast',
          'Ovarian',
          'Colorectal',
          'Prostate',
          'Pancreatic',
          'Melanoma',
          'None',
          'Not sure'
        ],
        bind: 'be.profile.family_cancers'),
    ScreenField('relative_s_age_at_diagnosis_if_k', FieldType.number),
  ]),
  'be_questions': ScreenSpec('be', [
    ScreenField('add_a_question', FieldType.text),
  ]),
  'be_survivor': ScreenSpec('be', [
    ScreenField('value', FieldType.segmented,
        options: ['Hard', 'Mixed', 'Good']),
  ]),
  'bf_date': ScreenSpec('bf', [
    ScreenField('quit_date', FieldType.date),
    ScreenField('quit_day_check_in_at_7_00_am', FieldType.toggle),
  ]),
  'bf_meds_edit': ScreenSpec('bf', [
    ScreenField('medicine', FieldType.select, bind: 'bf.meds.medicine'),
    ScreenField('strength', FieldType.text),
    ScreenField('when', FieldType.select, bind: 'bf.meds.when'),
    ScreenField('private_reminder', FieldType.toggle,
        bind: 'bf.meds.private_reminder'),
  ]),
  'bf_path': ScreenSpec('bf', [
    ScreenField('path', FieldType.radio, options: [
      'Set a quit date',
      'Quit today',
      'Reduce gradually',
      'Explore first'
    ]),
  ]),
  'bf_progress': ScreenSpec('bf', [
    ScreenField('value', FieldType.segmented,
        options: ['7 days', '30 days', 'All']),
  ]),
  'bf_q1': ScreenSpec('bf', [
    ScreenField('value', FieldType.radio, options: [
      'I don’t smoke every day',
      '10 or fewer',
      '11–20',
      '21–30',
      '31 or more'
    ]),
  ]),
  'bf_q2': ScreenSpec('bf', [
    ScreenField('value', FieldType.chips, options: [
      'Stress',
      'After meals',
      'Driving',
      'With coffee',
      'Social',
      'Work breaks',
      'Alcohol',
      'Boredom',
      'Morning',
      'Scrolling'
    ]),
    ScreenField('add_your_own', FieldType.text),
  ]),
  'bf_q3': ScreenSpec('bf', [
    ScreenField('value', FieldType.chips, options: [
      'Protect my family',
      'Breathe easier',
      'Save money',
      'Feel in control',
      'My health',
      'Be there for my future'
    ]),
  ]),
  'bf_slip': ScreenSpec('bf', [
    ScreenField('what_happened', FieldType.chips,
        options: [
          'A puff or two',
          'One cigarette',
          'More',
          'Prefer not to say'
        ],
        multi: false),
    ScreenField('what_was_going_on_optional', FieldType.chips,
        options: ['Stress', 'Around smokers', 'Alcohol', 'Scrolling late']),
    ScreenField('next', FieldType.radio,
        options: ['Continue from this moment', 'Choose a new quit time']),
  ]),
  'bf_support': ScreenSpec('bf', [
    ScreenField('remind_me_to_discuss_quit_medici', FieldType.toggle),
  ]),
  'ca_plan': ScreenSpec('ca', [
    ScreenField('green_from', FieldType.number),
    ScreenField('daily_medicine', FieldType.text),
    ScreenField('peak_flow', FieldType.text),
    ScreenField('red_below', FieldType.number),
  ]),
  'ca_q1': ScreenSpec('ca', [
    ScreenField('value', FieldType.radio, options: [
      'Asthma',
      'COPD',
      'Other lung condition',
      'Not diagnosed: I want to learn'
    ]),
    ScreenField('has_plan', FieldType.segmented,
        options: ['Yes', 'No', 'Not sure']),
  ]),
  'ca_symptoms': ScreenSpec('ca', [
    ScreenField('value', FieldType.chips, options: [
      'Coughing',
      'Wheezing',
      'Short of breath',
      'Chest tightness',
      'Woke at night'
    ]),
    ScreenField('how_bad', FieldType.segmented,
        options: ['Mild', 'Moderate', 'Severe']),
    ScreenField('possible_trigger', FieldType.chips,
        options: ['Cold air', 'Smoke', 'Pollen', 'Exercise', 'Not sure']),
    ScreenField('note_optional', FieldType.multiline),
  ]),
  'ca_zone': ScreenSpec('ca', [
    ScreenField('peak_flow', FieldType.number),
    ScreenField('symptoms', FieldType.chips, options: [
      'Coughing',
      'Wheezing',
      'Short of breath',
      'Chest tightness',
      'Woke at night',
      'Can’t speak in full sentences'
    ]),
  ]),
  'checkin': ScreenSpec(null, [
    ScreenField('how_do_you_feel_today', FieldType.segmented,
        options: ['Low', 'Not great', 'Okay', 'Good', 'Great']),
    ScreenField('stress_today', FieldType.segmented,
        options: ['Low', 'Some', 'High']),
    ScreenField('value', FieldType.chips,
        options: ['No', 'A puff', 'One or more', 'Skip'], multi: false),
    ScreenField('value_2', FieldType.chips,
        options: ['Better', 'Same', 'Drained', 'Skip'], multi: false),
  ]),
  'ck_done': ScreenSpec('ck', [
    ScreenField('what', FieldType.select),
    ScreenField('date', FieldType.date),
    ScreenField('where_optional', FieldType.text),
  ]),
  'ck_q1': ScreenSpec('ck', [
    ScreenField('age', FieldType.number),
    ScreenField('sex_assigned_at_birth', FieldType.segmented,
        options: ['Female', 'Male', 'Intersex', 'Skip'],
        bind: 'ck.profile.sex_assigned_at_birth'),
    ScreenField('any_of_these', FieldType.chips,
        options: [
          'Smoke or used to',
          'Diabetes',
          'Family history of cancer',
          'Pregnant',
          'None'
        ],
        bind: 'ck.profile.any_of_these'),
  ]),
  'ea_checkback': ScreenSpec('ea', [
    ScreenField('value', FieldType.segmented,
        options: ['Worse', 'Same', 'Better']),
    ScreenField('did_you_reach_out_to_someone', FieldType.chips,
        options: ['Yes, I have an appointment', 'Not yet', 'I don’t want to'],
        multi: false),
  ]),
  'ea_mood': ScreenSpec('ea', [
    ScreenField('how_are_you_right_now', FieldType.segmented,
        options: ['Very low', 'Low', 'Okay', 'Good', 'Great']),
    ScreenField('going_on', FieldType.chips, options: [
      'Work',
      'Money',
      'Family',
      'Health',
      'Lonely',
      'Sleep',
      'Thoughts of harming myself',
      'Not sure'
    ]),
  ]),
  'ea_plan': ScreenSpec('ea', [
    ScreenField('my_warning_signs', FieldType.multiline),
    ScreenField('things_that_help_me', FieldType.text),
    ScreenField('people_i_can_reach', FieldType.text),
  ]),
  'ea_q1': ScreenSpec('ea', [
    ScreenField('value', FieldType.radio, options: [
      'Not at all',
      'Several days',
      'More than half the days',
      'Nearly every day'
    ]),
  ]),
  'focus_full': ScreenSpec(null, [
    ScreenField('option', FieldType.radio, options: [
      'Learn only for now',
      'Swap with ScrollFree',
      'Swap with BreatheFree'
    ]),
  ]),
  'hw_lipids': ScreenSpec('hw', [
    ScreenField('total', FieldType.number),
    ScreenField('ldl', FieldType.number),
    ScreenField('hdl', FieldType.number),
    ScreenField('triglycerides', FieldType.number),
    ScreenField('lab_date', FieldType.date),
  ]),
  'hw_log': ScreenSpec('hw', [
    ScreenField('systolic', FieldType.number),
    ScreenField('diastolic', FieldType.number),
    ScreenField('pulse_optional', FieldType.number),
    ScreenField('value', FieldType.chips,
        options: ['Left arm', 'Right arm'], multi: false),
  ]),
  'hw_log2': ScreenSpec('hw', [
    ScreenField('systolic', FieldType.number),
    ScreenField('diastolic', FieldType.number),
    ScreenField('pulse_optional', FieldType.number),
  ]),
  'hw_log_error': ScreenSpec('hw', [
    ScreenField('top_systolic', FieldType.number),
    ScreenField('bottom_diastolic', FieldType.number),
  ]),
  'hw_q1': ScreenSpec('hw', [
    ScreenField('value', FieldType.chips, options: [
      'High blood pressure',
      'High cholesterol',
      'Heart disease',
      'Stroke',
      'None of these'
    ]),
    ScreenField('do_you_have_a_home_bp_monitor', FieldType.segmented,
        options: ['Yes', 'No', 'Not sure']),
  ]),
  'hw_summary': ScreenSpec('hw', [
    ScreenField('include_notes', FieldType.toggle),
  ]),
  'hw_targets': ScreenSpec('hw', [
    ScreenField('top_below', FieldType.number),
    ScreenField('bottom_below', FieldType.number),
    ScreenField('value', FieldType.radio,
        options: ['I don’t have a target yet'],
        bind: 'hw.targets.no_target_yet'),
    ScreenField('when_should_we_remind_you', FieldType.chips,
        options: ['Morning', 'Evening', 'Both'],
        multi: false,
        bind: 'hw.targets.reminder_time'),
  ]),
  'hw_trends': ScreenSpec('hw', [
    ScreenField('value', FieldType.segmented,
        options: ['7 days', '30 days', '90 days']),
  ]),
  'learn': ScreenSpec(null, [
    ScreenField('search', FieldType.search),
    ScreenField('value', FieldType.chips,
        options: ['For you', 'BreatheFree', 'ScrollFree', 'ClearAir'],
        multi: false),
  ]),
  'nu_habit': ScreenSpec('nu', [
    ScreenField('value', FieldType.radio,
        options: [
          'Add a vegetable to dinner',
          'Water before each meal',
          'Cook at home',
          '10-minute walk after a meal'
        ],
        bind: 'nu.habit.habit'),
    ScreenField('track_weight', FieldType.toggle,
        bind: 'nu.habit.track_weight'),
  ]),
  'nu_q1': ScreenSpec('nu', [
    ScreenField('value', FieldType.chips, options: [
      'Energy',
      'Easy meals',
      'More plants',
      'More water',
      'Move more',
      'Save on food',
      'Feel better about food'
    ]),
    ScreenField('eating', FieldType.segmented,
        options: ['No', 'Yes', 'Prefer not to say']),
  ]),
  'nu_reset': ScreenSpec('nu', [
    ScreenField('option', FieldType.radio, options: [
      'Keep this habit, start fresh today',
      'Make it smaller',
      'Pick a different habit'
    ]),
  ]),
  'nu_week4': ScreenSpec('nu', [
    ScreenField('how_do_you_feel_about_food_latel', FieldType.segmented,
        options: ['Worse', 'Same', 'Better']),
  ]),
  'ob_account': ScreenSpec(null, [
    ScreenField('email', FieldType.email),
    ScreenField('password', FieldType.password),
    ScreenField('age_18_or_older', FieldType.checklist,
        options: ['I’m 18 or older']),
  ]),
  'ob_basics': ScreenSpec(null, [
    ScreenField('what_should_we_call_you', FieldType.text),
    ScreenField('age_range', FieldType.select),
    ScreenField('sleep_on_a_typical_night', FieldType.segmented,
        options: ['< 5 h', '5–6 h', '7–8 h', '9+ h']),
    ScreenField('usual_stress', FieldType.segmented,
        options: ['Low', 'Some', 'High']),
  ]),
  'ob_consent': ScreenSpec(null, [
    ScreenField('essential_app_data', FieldType.toggle),
    ScreenField('private_reminders', FieldType.toggle),
    ScreenField('share_summaries_with_my_care_tea', FieldType.toggle),
    ScreenField('connect_screen_time', FieldType.toggle),
    ScreenField('de_identified_research', FieldType.toggle),
  ]),
  'ob_programs': ScreenSpec(null, [
    ScreenField('programs', FieldType.tiles, options: [
      'BreatheFree',
      'ScrollFree',
      'ClearAir',
      'Heartwise',
      'Steady',
      'Ease',
      'Nourish',
      'Stride'
    ], programs: [
      'bf',
      'sf',
      'ca',
      'hw',
      'st',
      'ea',
      'nu',
      'sd'
    ]),
  ]),
  'ob_reminders': ScreenSpec(null, [
    ScreenField('quiet_hours', FieldType.toggle),
  ]),
  'ob_third': ScreenSpec(null, [
    ScreenField('value', FieldType.radio, options: [
      'Learn only for now',
      'Swap with ScrollFree',
      'Swap with BreatheFree'
    ]),
  ]),
  'program_settings': ScreenSpec(null, [
    ScreenField('status', FieldType.radio,
        options: ['Focus', 'Learn only', 'Pause'],
        bind: 'enrolment.:program.status'),
    ScreenField('care_team_sharing', FieldType.toggle,
        bind: 'enrolment.:program.care_team_sharing'),
    ScreenField('de_identified_research', FieldType.toggle,
        bind: 'enrolment.:program.de_identified_research'),
  ]),
  'program_settings_sf': ScreenSpec(null, [
    ScreenField('status', FieldType.radio,
        options: ['Focus', 'Learn only', 'Pause'],
        bind: 'enrolment.:program.status'),
    ScreenField('care_team_sharing', FieldType.toggle,
        bind: 'enrolment.:program.care_team_sharing'),
    ScreenField('de_identified_research', FieldType.toggle,
        bind: 'enrolment.:program.de_identified_research'),
  ]),
  'progress': ScreenSpec(null, [
    ScreenField('value', FieldType.segmented,
        options: ['7 days', '30 days', 'All']),
  ]),
  're_labs': ScreenSpec('re', [
    ScreenField('egfr', FieldType.number),
    ScreenField('urine_acr', FieldType.number),
    ScreenField('alt_liver', FieldType.number),
    ScreenField('lab_date', FieldType.date),
  ]),
  're_q1': ScreenSpec('re', [
    ScreenField('value', FieldType.chips, options: [
      'Diabetes',
      'High blood pressure',
      'Heart disease',
      'Family history of kidney disease',
      'Regular alcohol',
      'Hepatitis B or C',
      'None'
    ]),
    ScreenField('known_condition', FieldType.segmented,
        options: ['Kidney', 'Liver', 'Both', 'No']),
  ]),
  're_symptoms': ScreenSpec('re', [
    ScreenField('value', FieldType.chips, options: [
      'Very little urine',
      'Swelling in legs or face',
      'Yellow skin or eyes',
      'Confusion',
      'Vomiting blood',
      'None'
    ]),
  ]),
  'records_conflict': ScreenSpec(null, [
    ScreenField('a1c', FieldType.radio, options: [
      'From Patel Family Medicine (Epic): 7.6%',
      'Entered by you: 7.4%',
      'Keep both'
    ]),
    ScreenField('bp', FieldType.radio,
        options: ['Discard', 'Keep as 129/80', 'Ask my care team']),
  ]),
  'records_consent': ScreenSpec(null, [
    ScreenField('resources', FieldType.checklist, options: [
      'Conditions',
      'Vital signs',
      'Lab results',
      'Medications',
      'Immunizations',
      'Smoking status'
    ]),
  ]),
  'records_consent_bb': ScreenSpec(null, [
    ScreenField('resources', FieldType.checklist, options: [
      'Conditions',
      'Vital signs',
      'Lab results',
      'Medications',
      'Immunizations',
      'Smoking status'
    ]),
  ]),
  'records_consent_device': ScreenSpec(null, [
    ScreenField('data_types', FieldType.checklist, options: [
      'Blood pressure',
      'Blood glucose',
      'Clinical records (iPhone)'
    ]),
  ]),
  'records_disconnect': ScreenSpec(null, [
    ScreenField('keep', FieldType.radio, options: [
      'Keep imported data',
      'Delete data imported from this source'
    ]),
  ]),
  'records_fhir_url': ScreenSpec(null, [
    ScreenField('base_url', FieldType.text),
  ]),
  'records_manual': ScreenSpec(null, [
    ScreenField('type', FieldType.chips,
        options: [
          'Blood pressure',
          'Glucose',
          'Lab result',
          'Vaccine',
          'Medication',
          'Condition'
        ],
        multi: false),
    ScreenField('test', FieldType.select),
    ScreenField('value', FieldType.number),
    ScreenField('date', FieldType.date),
  ]),
  'records_manual_error': ScreenSpec(null, [
    ScreenField('test', FieldType.select),
    ScreenField('value', FieldType.number),
    ScreenField('date', FieldType.date),
  ]),
  'records_review': ScreenSpec(null, [
    ScreenField('keep_hw', FieldType.checklist,
        options: ['12 blood pressure readings', 'Lipid panel']),
    ScreenField('keep_st', FieldType.checklist, options: ['A1C 7.6%']),
    ScreenField('keep_ck', FieldType.checklist,
        options: ['Flu vaccine', 'Tdap']),
    ScreenField('keep_bf', FieldType.checklist,
        options: ['Smoking status: every day smoker']),
    ScreenField('keep_re', FieldType.checklist, options: ['eGFR 58']),
  ]),
  'records_search': ScreenSpec(null, [
    ScreenField('query', FieldType.search),
  ]),
  'rescue_active': ScreenSpec(null, [
    ScreenField('value', FieldType.chips,
        options: ['Voice on', 'Haptics on', 'Reduced motion']),
  ]),
  'rescue_result': ScreenSpec(null, [
    ScreenField('how_strong_is_it_now', FieldType.slider),
    ScreenField('did_it_help', FieldType.chips,
        options: ['Yes', 'A little', 'Not this time'], multi: false),
  ]),
  'rescue_tools': ScreenSpec(null, [
    ScreenField('value', FieldType.radio, options: [
      'Slow breathing',
      'Move for 3 minutes',
      'Change the scene',
      'Urge surfing'
    ]),
  ]),
  'sd_caregiver': ScreenSpec('sd', [
    ScreenField('name', FieldType.text),
    ScreenField('phone', FieldType.phone),
    ScreenField('caregiver_can_see', FieldType.checklist,
        options: [
          'When I finish a session',
          'If I log a fall',
          'My other programs'
        ],
        bind: 'sd.caregiver.can_see'),
  ]),
  'sd_q1': ScreenSpec('sd', [
    ScreenField('in_the_last_year_have_you_fallen', FieldType.segmented,
        options: ['No', 'Once', '2+ times']),
    ScreenField('do_you_feel_unsteady_standing_or', FieldType.segmented,
        options: ['No', 'Sometimes', 'Often']),
    ScreenField('do_you_worry_about_falling', FieldType.segmented,
        options: ['No', 'A little', 'A lot']),
  ]),
  'sd_session': ScreenSpec('sd', [
    ScreenField('value', FieldType.chips,
        options: ['Audio on', 'Large text', 'Captions']),
  ]),
  'sf_buddy': ScreenSpec('sf', [
    ScreenField('name', FieldType.text),
    ScreenField('buddy_can_see', FieldType.checklist,
        options: [
          'A weekly “I hit my goal” message',
          'My minutes per day',
          'Nothing automatic: I send each one'
        ],
        bind: 'sf.buddy.can_see'),
  ]),
  'sf_goal': ScreenSpec('sf', [
    ScreenField('daily_social_time', FieldType.slider),
    ScreenField('step_down_15_min_each_week', FieldType.toggle),
  ]),
  'sf_pause': ScreenSpec('sf', [
    ScreenField('value', FieldType.chips,
        options: [
          'Message someone',
          'Bored',
          'Avoiding something',
          'Can’t sleep'
        ],
        multi: false),
  ]),
  'sf_q1': ScreenSpec('sf', [
    ScreenField('value', FieldType.radio,
        options: ['Less than 1 hour', '1–2 hours', '3–4 hours', '5+ hours']),
    ScreenField('which_pull_hardest_categories_on', FieldType.chips,
        options: ['Short video', 'Feeds', 'Messaging', 'Games', 'News']),
  ]),
  'sf_q2': ScreenSpec('sf', [
    ScreenField('value', FieldType.chips, options: [
      'Bored',
      'Lonely',
      'In bed',
      'Avoiding work',
      'After conflict',
      'Waiting',
      'Can’t sleep',
      'First thing'
    ]),
    ScreenField('how_do_you_usually_feel_after', FieldType.segmented,
        options: ['Better', 'Same', 'Worse']),
  ]),
  'sf_slip': ScreenSpec('sf', [
    ScreenField('value', FieldType.chips,
        options: ['Couldn’t sleep', 'Bored', 'Stressed', 'Didn’t notice time']),
    ScreenField('value_2', FieldType.radio, options: [
      'Keep my goal, try again tonight',
      'Make tomorrow’s goal easier',
      'Move bedtime window 30 min earlier'
    ]),
  ]),
  'sf_unplug_apps_chosen': ScreenSpec('sf', [
    ScreenField('group_name', FieldType.text),
  ]),
  'sf_unplug_gate_commit': ScreenSpec('sf', [
    ScreenField('sentence', FieldType.text),
  ]),
  'sf_unplug_gate_sum': ScreenSpec('sf', [
    ScreenField('answer', FieldType.number),
  ]),
  'sf_unplug_limits': ScreenSpec('sf', [
    ScreenField('daily_minutes', FieldType.slider),
    ScreenField('daily_opens', FieldType.slider),
    ScreenField('level', FieldType.radio, options: [
      'Notice only',
      'Pause screen',
      'Pause and one small step',
      'Firm'
    ]),
    ScreenField('gate', FieldType.chips,
        options: ['One breath', 'Type a sentence', 'Quick sum'], multi: false),
    ScreenField('overrides', FieldType.segmented,
        options: ['0', '1', '3', '5']),
  ]),
  'sf_unplug_off': ScreenSpec('sf', [
    ScreenField('scope', FieldType.radio,
        options: ['Unplug only', 'Unplug and Screen Time access']),
  ]),
  'sf_unplug_session': ScreenSpec('sf', [
    ScreenField('duration', FieldType.chips,
        options: ['25 min', '45 min', '60 min', '90 min'], multi: false),
    ScreenField('scope', FieldType.radio,
        options: ['Only my chosen apps', 'Everything except apps I allow']),
    ScreenField('strict', FieldType.toggle),
  ]),
  'sf_unplug_session_end': ScreenSpec('sf', [
    ScreenField('reason', FieldType.chips,
        options: [
          'Need an app for work',
          'Expecting a message',
          'Changed my mind',
          'Other'
        ],
        multi: false),
    ScreenField('note', FieldType.multiline),
  ]),
  'st_a1c': ScreenSpec('st', [
    ScreenField('a1c', FieldType.number),
    ScreenField('lab_date', FieldType.date),
  ]),
  'st_log': ScreenSpec('st', [
    ScreenField('reading', FieldType.number),
    ScreenField('when', FieldType.chips,
        options: [
          'Fasting',
          'Before meal',
          '2 h after meal',
          'Bedtime',
          'Other'
        ],
        multi: false),
    ScreenField('how_do_you_feel', FieldType.chips,
        options: ['Fine', 'Shaky', 'Sweaty', 'Tired', 'Thirsty']),
    ScreenField('note_optional', FieldType.text),
  ]),
  'st_patterns': ScreenSpec('st', [
    ScreenField('value', FieldType.segmented,
        options: ['7 days', '14 days', '30 days']),
  ]),
  'st_q1': ScreenSpec('st', [
    ScreenField('value', FieldType.radio, options: [
      'Type 2 diabetes',
      'Prediabetes',
      'Type 1 diabetes',
      'Gestational diabetes',
      'Not diagnosed: learn'
    ]),
    ScreenField('how_do_you_check', FieldType.segmented,
        options: ['Meter', 'CGM', 'Lab only']),
  ]),
  'st_range': ScreenSpec('st', [
    ScreenField('value', FieldType.segmented,
        options: ['mg/dL', 'mmol/L'], bind: 'st.range.unit'),
    ScreenField('before_meals_from', FieldType.number),
    ScreenField('to', FieldType.number),
    ScreenField('2_h_after_meals_below', FieldType.number),
    ScreenField('low', FieldType.number),
    ScreenField('my_low_steps', FieldType.multiline),
  ]),
  'support_add_person': ScreenSpec(null, [
    ScreenField('name', FieldType.text),
    ScreenField('phone', FieldType.phone),
    ScreenField('which_programs', FieldType.chips,
        options: ['BreatheFree', 'ScrollFree']),
    ScreenField('help_phrase', FieldType.multiline),
  ]),
  'support_callback': ScreenSpec(null, [
    ScreenField('best_time_to_call', FieldType.select),
  ]),
  'support_connect': ScreenSpec(null, [
    ScreenField('invite_code', FieldType.text),
  ]),
  'support_message_care': ScreenSpec(null, [
    ScreenField('topic', FieldType.select),
    ScreenField('message', FieldType.multiline),
    ScreenField('attach_a_summary', FieldType.toggle),
  ]),
  'today': ScreenSpec(null, [
    ScreenField('value', FieldType.chips,
        options: ['All', 'BreatheFree', 'ScrollFree'], multi: false),
  ]),
  'welcome': ScreenSpec(null, [
    ScreenField('value', FieldType.segmented, options: ['English', 'Español']),
  ]),
};
