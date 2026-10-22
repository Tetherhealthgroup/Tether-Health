"""Decision rules used by branches (`decide=`).

The same table is exported to spec/rules.json, compiled into the Flutter kit
(lib/logic/rules.dart) and the prototype (JS), and exercised by the
simulation scenarios, so the app, the prototype and the tests all decide
the same way. Thresholds are clinical placeholders until signed off.

`safety` lists the outcome ids that open a safety screen. When a save fails,
the app still routes to these outcomes (the on-device rule decides), and
stays on the screen for every other outcome. A rule without `safety` has no
safety outcome. The list is clinical content: interim, pending confirmation
by the clinical lead.
"""

RULES = {
    'hw.bp': {
        'title': 'Blood pressure reading check',
        'program': 'hw',
        'inputs': ['hw_log.systolic', 'hw_log.diastolic', 'hw_log2.systolic', 'hw_log2.diastolic'],
        'params': {'sys_min': 70, 'sys_max': 250, 'dia_min': 40, 'dia_max': 150, 'crisis_sys': 180, 'crisis_dia': 120},
        'outcomes': {'ok': 'Valid · below crisis range', 'invalid': 'Invalid value', 'crisis': '≥180 top or ≥120 bottom'},
        'safety': ['crisis'],
        'logic': 'Each reading must be sys 70–250, dia 40–150, dia < sys, else Invalid. If either reading has sys ≥ 180 or dia ≥ 120 → Crisis (symptom check). Otherwise the average is saved.',
        'source': 'ACC/AHA hypertensive crisis threshold (≥180/≥120). Needs clinical sign-off.',
    },
    'st.glucose': {
        'title': 'Glucose reading check',
        'program': 'st',
        'inputs': ['st_log.reading', 'st_range.low'],
        'params': {'min': 20, 'max': 600, 'default_low': 70},
        'outcomes': {'ok': 'In or above range', 'low': 'Below your low', 'invalid': 'Invalid (outside 20–600)'},
        'safety': ['low'],
        'logic': 'Outside 20–600 mg/dL → Invalid. Below the member’s low (from their clinician, default 70) → Low plan with 15-min timer. Otherwise saved neutrally.',
        'source': 'ADA level 1 hypoglycemia < 70 mg/dL. Needs clinical sign-off.',
    },
    'ca.zone': {
        'title': 'Asthma/COPD zone from action plan',
        'program': 'ca',
        'inputs': ['ca_zone.peak_flow', 'ca_zone.symptoms', 'ca_plan.green_from', 'ca_plan.red_below'],
        'params': {'pef_min': 50, 'pef_max': 900, 'default_green_from': 400, 'default_red_below': 200, 'red_symptoms': ['Can’t speak in full sentences']},
        'outcomes': {'green': 'Green', 'yellow': 'Yellow', 'red': 'Red', 'invalid': 'Invalid peak flow'},
        'safety': ['red'],
        'logic': 'Peak flow outside 50–900 → Invalid. A red symptom or peak flow below the plan’s red threshold → Red. Peak flow below the green threshold or any symptom → Yellow. Otherwise Green. Thresholds come only from the member’s plan.',
        'source': 'NAEPP asthma action plan zones. Needs pulmonology sign-off.',
    },
    'ea.selfharm': {
        'title': 'Self-harm signal',
        'program': 'ea',
        'inputs': ['ea_mood.going_on'],
        'params': {'triggers': ['Thoughts of harming myself']},
        'outcomes': {'yes': 'Yes', 'no': 'No'},
        'safety': ['yes'],
        'logic': 'If the member selects a self-harm option the crisis screen opens immediately (988/911).',
        'source': 'Safe messaging guidance. Needs psychiatry sign-off.',
    },
    'rec.manual': {
        'title': 'Manual health value check',
        'program': None,
        'inputs': ['records_manual.test', 'records_manual.value'],
        'params': {'ranges': {'A1C': [3, 20], 'LDL': [10, 400], 'eGFR': [1, 150], 'Glucose': [20, 600]}},
        'outcomes': {'ok': 'Valid', 'range': 'Outside expected range', 'dup': 'Matches an imported value'},
        'logic': 'Value must be within the plausible range for the chosen test, else held for review. Duplicates of an imported FHIR value (same LOINC, date, value) are not added twice.',
        'source': 'Plausibility ranges, not clinical targets.',
    },
    'ob.age': {
        'title': 'Sign-up: “I’m 18 or older” ticked',
        'program': None,
        'inputs': ['ob_account.age_18_or_older'],
        'params': {'item': 'I’m 18 or older'},
        'outcomes': {'confirmed': 'Age confirmed', 'missing': 'Age not confirmed'},
        'logic': 'Confirmed when the item is ticked. Every sign-up route on ob_account (Apple, Google, Create account, Continue on this phone only) asks this first; unticked, it shows a message and goes nowhere.',
        'source': 'Owner decisions P-68 and P-72. Product rule, not clinical.',
    },
}

# Simulation scenarios: end-to-end setups and functions for every program.
# Steps: ('tap', text) · ('enter', 'screen.key', value) · ('choose', outcome for the next external decision) · ('expect', screen)
def sc(id, program, function, title, start, steps, expect):
    return {'id': id, 'program': program, 'function': function, 'title': title, 'start': start, 'steps': steps, 'expect': expect}

SETUP_BF = [('tap', 'Set up BreatheFree'), ('tap', 'Next'), ('tap', 'Next'), ('tap', 'Save my reasons')]

SCENARIOS = [
    # ---------------- account & sign-in
    sc('auth-email', None, 'Sign-in', 'Create account with email, verify, keep both plans', 'ob_account',
       [('tap', 'I’m 18 or older'), ('tap', 'Create account'), ('expect', 'auth_verify'), ('tap', 'I’ve confirmed my email'), ('expect', 'auth_merge'), ('tap', 'Continue')], 'today'),
    sc('auth-apple', None, 'Sign-in', 'Sign in with Apple (iPhone)', 'welcome',
       [('tap', 'I already have an account'), ('choose', 'Success'), ('tap', 'Continue with Apple')], 'today'),
    sc('auth-google', None, 'Sign-in', 'Sign in with Google (Android)', 'welcome',
       [('tap', 'I already have an account'), ('choose', 'Success'), ('tap', 'Continue with Google')], 'today'),
    sc('auth-apple-new', None, 'Sign-in', 'New Apple ID goes through the normal sign-up', 'welcome',
       [('tap', 'I already have an account'), ('choose', 'New Apple ID, no Tether account'), ('tap', 'Continue with Apple')], 'ob_programs'),
    sc('auth-google-link', None, 'Sign-in', 'Google email already used → link accounts', 'ob_account',
       [('tap', 'I’m 18 or older'), ('choose', 'Email already has a Tether account'), ('tap', 'Continue with Google'), ('expect', 'auth_link'), ('tap', 'Link and sign in')], 'today'),
    sc('auth-google-error', None, 'Sign-in', 'Google sign-in fails → error with email fallback', 'ob_account',
       [('tap', 'I’m 18 or older'), ('choose', 'Error'), ('tap', 'Continue with Google'), ('expect', 'auth_social_error'), ('tap', 'Use email instead')], 'auth_signin'),
    sc('auth-wrong-password', None, 'Sign-in', 'Wrong password shows inline error', 'welcome',
       [('tap', 'I already have an account'), ('choose', 'Wrong password'), ('tap', 'Sign in')], 'auth_signin_error'),
    # ---------------- first run
    sc('onboarding', None, 'Setup', 'First run: 2 programs, consent, BreatheFree plan, guest', 'welcome',
       [('tap', 'Get started'), ('tap', 'Continue with 2 programs'), ('tap', 'Continue'), ('tap', 'Agree and continue'), ('tap', 'Continue'), ('expect', 'ob_setup'),
        ('tap', 'BreatheFree'), ('tap', 'Next'), ('tap', 'Next'), ('tap', 'Save my reasons'), ('tap', 'Continue with this path'), ('tap', 'Confirm this date'),
        ('tap', 'Review my plan'), ('tap', 'Start my plan'), ('expect', 'ob_setup'), ('tap', 'Continue'), ('choose', 'Allowed'), ('tap', 'Turn on reminders'),
        ('tap', 'I’m 18 or older'), ('tap', 'Continue on this phone only')], 'today'),
    # ---------------- health records (FHIR)
    sc('fhir-epic', None, 'Health records', 'Connect Epic MyChart, review, resolve conflict, add to programs', 'records_hub',
       [('tap', 'Add a source'), ('tap', 'Hospital or clinic'), ('tap', 'Patel Family Medicine'), ('choose', 'Approved'), ('tap', 'Continue to MyChart'),
        ('expect', 'records_importing'), ('tap', 'Review imported data'), ('expect', 'records_review'), ('tap', 'Review conflicts first'),
        ('tap', 'From Patel Family Medicine (Epic): 7.6%'), ('tap', 'Save choices'), ('expect', 'records_review'), ('tap', 'Add 21 items to my programs')], 'records_hub'),
    sc('fhir-bluebutton', None, 'Health records', 'Connect Medicare Blue Button 2.0', 'records_add',
       [('tap', 'Medicare · Blue Button 2.0'), ('choose', 'Approved'), ('tap', 'Continue to Medicare.gov'), ('tap', 'Review imported data')], 'records_review'),
    sc('fhir-denied', None, 'Health records', 'Provider sign-in denied → error with options', 'records_add',
       [('tap', 'Hospital or clinic'), ('tap', 'Patel Family Medicine'), ('choose', 'Denied or error'), ('tap', 'Continue to MyChart'), ('expect', 'records_error'), ('tap', 'Enter manually instead')], 'records_manual'),
    sc('fhir-custom', None, 'Health records', 'Other FHIR server: capability check fails', 'records_add',
       [('tap', 'Other FHIR server'), ('choose', 'Not a FHIR R4 server'), ('tap', 'Check and continue')], 'records_error'),
    sc('fhir-manual-ok', None, 'Health records', 'Manual A1C within range is saved', 'records_manual',
       [('enter', 'records_manual.value', '7.4'), ('tap', 'Save')], 'records_hub'),
    sc('fhir-manual-range', None, 'Health records', 'Manual A1C 74 is held as out of range', 'records_manual',
       [('enter', 'records_manual.value', '74'), ('tap', 'Save')], 'records_manual_error'),
    sc('fhir-disconnect', None, 'Health records', 'Disconnect a source and delete its data', 'records_hub',
       [('tap', 'Patel Family Medicine'), ('tap', 'Disconnect'), ('tap', 'Delete data imported from this source'), ('tap', 'Disconnect source')], 'records_hub'),
    # ---------------- BreatheFree
    sc('bf-date', 'bf', 'Setup', 'Set a quit date path', 'bf_intro', SETUP_BF + [('tap', 'Continue with this path'), ('expect', 'bf_date'), ('tap', 'Confirm this date'), ('tap', 'Review my plan'), ('tap', 'Start my plan')], 'bf_home'),
    sc('bf-today', 'bf', 'Setup', 'Quit today path skips the calendar', 'bf_intro', SETUP_BF + [('tap', 'Quit today'), ('tap', 'Continue with this path'), ('expect', 'bf_support')], 'bf_support'),
    sc('bf-reduce', 'bf', 'Setup', 'Reduce gradually path → step-down schedule', 'bf_intro', SETUP_BF + [('tap', 'Reduce gradually'), ('tap', 'Continue with this path'), ('expect', 'bf_stepdown'), ('tap', 'Save schedule')], 'bf_support'),
    sc('bf-explore', 'bf', 'Setup', 'Explore first path never asks for a date', 'bf_intro', SETUP_BF + [('tap', 'Explore first'), ('tap', 'Continue with this path')], 'bf_home_explore'),
    sc('bf-rescue', 'bf', 'Rescue', 'Craving rescue from BreatheFree home', 'bf_home', [('tap', 'Rescue'), ('tap', 'A cigarette'), ('tap', 'I’m done'), ('tap', 'Back to Today')], 'today'),
    sc('bf-slip', 'bf', 'Milestone', 'Slip recovery keeps the plan and starts a rescue', 'bf_home_quitday', [('tap', 'I smoked or had a slip'), ('tap', 'Save and start a 2-min Rescue')], 'rescue_active'),
    sc('bf-slip-newdate', 'bf', 'Milestone', 'Slip recovery → choose a new quit time', 'bf_slip', [('tap', 'Choose a new quit time'), ('tap', 'Save and start a 2-min Rescue')], 'bf_date'),
    sc('bf-meds', 'bf', 'Daily', 'Record nicotine patch taken', 'bf_meds', [('tap', 'Taken today'), ('tap', 'Add or update recorded plan'), ('tap', 'Save plan')], 'bf_meds'),
    # ---------------- ScrollFree
    sc('sf-setup', 'sf', 'Setup', 'ScrollFree setup with Screen Time allowed', 'sf_intro',
       [('tap', 'Set up ScrollFree'), ('tap', 'Next'), ('tap', 'Next'), ('tap', 'Connect Screen Time'), ('choose', 'Allowed'), ('tap', 'Allow access'), ('expect', 'sf_goal'), ('tap', 'Save my goal'), ('tap', 'Save and finish')], 'sf_home'),
    sc('sf-denied', 'sf', 'Setup', 'Screen Time denied → self-report fallback', 'sf_goal', [('tap', 'Connect Screen Time'), ('choose', 'Not allowed'), ('tap', 'Allow access')], 'sf_screentime_denied'),
    sc('sf-pause', 'sf', 'Rescue', 'Pause 60 → put the phone down', 'sf_home', [('tap', 'Pause 60'), ('tap', 'I’m good, put it down')], 'today'),
    sc('sf-slip', 'sf', 'Milestone', 'Long-scroll recovery', 'sf_home', [('tap', 'Had a long scroll?'), ('tap', 'Save')], 'sf_home'),
    # ---------------- ClearAir
    sc('ca-setup', 'ca', 'Setup', 'ClearAir setup with a written plan', 'ca_intro', [('tap', 'Set up ClearAir'), ('tap', 'Next'), ('expect', 'ca_plan'), ('tap', 'Save plan')], 'ca_home'),
    sc('ca-noplan', 'ca', 'Setup', 'No action plan → learn route', 'ca_intro', [('tap', 'Set up ClearAir'), ('tap', 'No'), ('tap', 'Next')], 'ca_noplan'),
    sc('ca-green', 'ca', 'Daily', 'Peak flow 420, no symptoms → green', 'ca_zone', [('enter', 'ca_zone.peak_flow', '420'), ('tap', 'Wheezing'), ('tap', 'Save and see my steps')], 'ca_home'),
    sc('ca-yellow', 'ca', 'Daily', 'Peak flow 310 → yellow steps', 'ca_zone', [('enter', 'ca_zone.peak_flow', '310'), ('tap', 'Save and see my steps')], 'ca_yellow'),
    sc('ca-red', 'ca', 'Safety', 'Peak flow 150 → red zone', 'ca_zone', [('enter', 'ca_zone.peak_flow', '150'), ('tap', 'Save and see my steps')], 'ca_red'),
    sc('ca-red-symptom', 'ca', 'Safety', 'Can’t speak in full sentences → red regardless of peak flow', 'ca_zone', [('enter', 'ca_zone.peak_flow', '420'), ('tap', 'Can’t speak in full sentences'), ('tap', 'Save and see my steps')], 'ca_red'),
    sc('ca-invalid', 'ca', 'Validation', 'Peak flow 2000 is rejected', 'ca_zone', [('enter', 'ca_zone.peak_flow', '2000'), ('tap', 'Save and see my steps')], 'ca_zone'),
    # ---------------- Heartwise
    sc('hw-setup', 'hw', 'Setup', 'Add Heartwise by swapping a focus slot', 'hw_intro', [('tap', 'Set up Heartwise'), ('tap', 'Swap with ScrollFree'), ('tap', 'Continue'), ('expect', 'hw_q1'), ('tap', 'Next'), ('tap', 'Save targets')], 'hw_home'),
    sc('hw-learn', 'hw', 'Setup', 'Add Heartwise as Learn only', 'hw_intro', [('tap', 'Set up Heartwise'), ('tap', 'Continue')], 'plans'),
    sc('hw-normal', 'hw', 'Daily', 'Two readings 138/86 + 132/84 → saved', 'hw_home',
       [('tap', 'Log blood pressure'), ('enter', 'hw_log.systolic', '138'), ('enter', 'hw_log.diastolic', '86'), ('tap', 'Next reading'),
        ('enter', 'hw_log2.systolic', '132'), ('enter', 'hw_log2.diastolic', '84'), ('tap', 'Save readings')], 'hw_result'),
    sc('hw-crisis', 'hw', 'Safety', 'Reading 186/122 → symptom check → re-check', 'hw_home',
       [('tap', 'Log blood pressure'), ('enter', 'hw_log.systolic', '186'), ('enter', 'hw_log.diastolic', '122'), ('tap', 'Next reading'), ('tap', 'Save readings'), ('expect', 'hw_crisis'), ('tap', 'No symptoms · re-check in 5 min')], 'hw_recheck'),
    sc('hw-invalid', 'hw', 'Validation', 'Diastolic 310 → fix-it message', 'hw_log',
       [('enter', 'hw_log.systolic', '138'), ('enter', 'hw_log.diastolic', '86'), ('tap', 'Next reading'),
        ('enter', 'hw_log2.systolic', '132'), ('enter', 'hw_log2.diastolic', '310'), ('tap', 'Save readings')], 'hw_log_error'),
    sc('hw-summary', 'hw', 'Resources', 'Visit summary sent to care team', 'hw_home', [('tap', 'Visit summary'), ('tap', 'Send summary')], 'hw_home'),
    # ---------------- Steady
    sc('st-setup', 'st', 'Setup', 'Steady setup with range and low plan', 'st_intro', [('tap', 'Set up Steady'), ('tap', 'Next'), ('tap', 'Save range')], 'st_home'),
    sc('st-normal', 'st', 'Daily', 'Reading 142 → saved', 'st_home', [('tap', 'Log a reading'), ('enter', 'st_log.reading', '142'), ('tap', 'Save reading')], 'st_home'),
    sc('st-low', 'st', 'Safety', 'Reading 62 → low plan with timer', 'st_home', [('tap', 'Log a reading'), ('enter', 'st_log.reading', '62'), ('tap', 'Save reading')], 'st_low'),
    sc('st-low-custom', 'st', 'Safety', 'Clinician low of 80: reading 75 → low plan', 'st_range', [('enter', 'st_range.low', '80'), ('tap', 'Save range'), ('tap', 'Log a reading'), ('enter', 'st_log.reading', '75'), ('tap', 'Save reading')], 'st_low'),
    sc('st-invalid', 'st', 'Validation', 'Reading 900 is rejected', 'st_log', [('enter', 'st_log.reading', '900'), ('tap', 'Save reading')], 'st_log'),
    # ---------------- Renew
    sc('re-setup', 're', 'Setup', 'Renew risk check and plan', 're_intro', [('tap', 'Set up Renew'), ('tap', 'See what this means'), ('tap', 'Save my plan')], 're_home'),
    sc('re-labs', 're', 'Milestone', 'Add labs → history', 're_home', [('tap', 'Add lab results'), ('tap', 'Save results')], 're_history'),
    sc('re-import', 're', 'Health records', 'Import labs from health record', 're_labs', [('tap', 'Import from my health record')], 'records_add'),
    sc('re-symptom', 're', 'Safety', 'Yellow eyes → care team today', 're_home', [('tap', 'Check symptoms'), ('tap', 'Contact my care team')], 'support_message_care'),
    # ---------------- Nourish
    sc('nu-setup', 'nu', 'Setup', 'Nourish weekly habit', 'nu_intro', [('tap', 'Set up Nourish'), ('tap', 'Next'), ('tap', 'Start this habit')], 'nu_home'),
    sc('nu-protect', 'nu', 'Safety', 'Eating-history yes → protective mode', 'nu_intro', [('tap', 'Set up Nourish'), ('tap', 'Yes'), ('tap', 'Next')], 'nu_protect'),
    sc('nu-reset', 'nu', 'Rescue', 'Off track → make it smaller', 'nu_home', [('tap', 'Busy week?'), ('tap', 'Make it smaller'), ('tap', 'Continue')], 'nu_home'),
    # ---------------- Stride
    sc('sd-setup', 'sd', 'Setup', 'Stride falls check and plan', 'sd_intro', [('tap', 'Set up Stride'), ('tap', 'Next'), ('tap', 'Start plan')], 'sd_home'),
    sc('sd-session', 'sd', 'Daily', 'Complete a session', 'sd_home', [('tap', 'Start'), ('tap', 'Finish session')], 'sd_home'),
    sc('sd-fell', 'sd', 'Safety', 'I fell → okay → fall logged', 'sd_home', [('tap', 'I fell'), ('tap', 'I’m okay, log this fall')], 'sd_home'),
    # ---------------- Ease
    sc('ea-setup', 'ea', 'Setup', 'Ease screener → result', 'ea_intro', [('tap', 'Set up Ease'), ('tap', 'Next')], 'ea_result'),
    sc('ea-skip', 'ea', 'Setup', 'Skip screener → safety plan → home', 'ea_intro', [('tap', 'Set up Ease'), ('tap', 'Skip the check'), ('tap', 'Save plan')], 'ea_home'),
    sc('ea-mood', 'ea', 'Daily', 'Mood check-in without self-harm → saved', 'ea_home', [('tap', 'Start'), ('tap', 'Save')], 'ea_home'),
    sc('ea-crisis', 'ea', 'Safety', 'Self-harm option → crisis screen', 'ea_home', [('tap', 'Start'), ('tap', 'Thoughts of harming myself'), ('tap', 'Save')], 'crisis'),
    # ---------------- Checkup
    sc('ck-setup', 'ck', 'Setup', 'Checkup builds a due list', 'ck_intro', [('tap', 'Set up Checkup'), ('tap', 'Build my list')], 'ck_list'),
    sc('ck-done', 'ck', 'Milestone', 'Mark flu vaccine done', 'ck_list', [('tap', 'I got it'), ('tap', 'Save')], 'ck_list'),
    # ---------------- Beacon
    sc('be-risk', 'be', 'Setup', 'Beacon: lowering my risk', 'be_intro', [('tap', 'Set up Beacon'), ('tap', 'Next'), ('tap', 'See my plan')], 'be_home'),
    sc('be-tx', 'be', 'Setup', 'Beacon: going through treatment', 'be_intro', [('tap', 'Set up Beacon'), ('tap', 'Going through treatment'), ('tap', 'Next')], 'be_tx'),
    sc('be-survivor', 'be', 'Setup', 'Beacon: after treatment', 'be_intro', [('tap', 'Set up Beacon'), ('tap', 'After treatment'), ('tap', 'Next')], 'be_survivor'),
    sc('be-diary', 'be', 'Daily', 'Treatment diary saved', 'be_tx', [('tap', 'Today’s side-effect diary'), ('tap', 'Save')], 'be_tx'),
    # ---------------- shell
    sc('today-tabs', None, 'Navigation', 'Every tab from Today', 'today', [('tap', 'Plans'), ('expect', 'plans'), ('tap', 'Progress'), ('expect', 'progress'), ('tap', 'Learn'), ('expect', 'learn'), ('tap', 'Support'), ('expect', 'support'), ('tap', 'Today')], 'today'),
    sc('checkin', None, 'Daily', 'Combined check-in → one step per program', 'today', [('tap', 'Start'), ('tap', 'Save check-in'), ('expect', 'checkin_done'), ('tap', 'Back to Today')], 'today'),
    sc('delete', None, 'Account', 'Delete account with receipt', 'account', [('tap', 'Your data'), ('tap', 'Delete account and all data'), ('tap', 'Delete everything'), ('expect', 'account_deleted'), ('tap', 'Done')], 'welcome'),
]
