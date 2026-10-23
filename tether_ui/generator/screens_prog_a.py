from dsl import *

H = header

def intro(p, bullets, time, setup=None, notes=None):
    name, area = PROGRAMS[p][0], PROGRAMS[p][1]
    S(f'{p}_intro', f'{name} intro', f'/p/{p}', p, program=p, phase='welcome', hdr=H(name, pill=time), body=[
        progtag(p, area), title(PROGRAMS[p][6], 'l'),
        kv(bullets),
    ] + ([text(setup[1], 'muted')] if setup and len(setup) > 1 else []), footer=[
        button(f'Set up {name}', setup[0] if setup else go(f'{p}_q1')),
        # P-88 (R-162): adding the programme as Learn only creates its
        # enrolment; the toast and the tab follow a successful save only.
        button('Add as Learn only', submit('POST /v1/enrolments', toast(f'{name} added as Learn only', tab('plans'))), v='secondary'),
    ], desc='Entry from Choose programs, Catalog or a Learn-only row.', notes=notes, api=['POST /v1/enrolments'])

def home_hdr(p): return H(PROGRAMS[p][0], avatar='A')

def settings_row(p): return row('Program settings', 'Status, sharing, export, leave', action=go('program_settings'))

def programs_a():
    # ================================================================ BREATHEFREE
    flow('bf', 'BreatheFree', 'Tobacco & nicotine · Quit / Reduce. Four real quit paths, craving rescue, slip recovery, medication education.', 'bf')
    intro('bf', [('Help when cravings hit', 'one tap, no typing'), ('Plan your way', 'date · today · reduce · explore'), ('Medicines', 'education only')], '~3 min/day',
          (go('bf_q1'), 'Plan, practice and get through cravings, with no judgment. A slip never erases your wins.'))
    S('bf_q1', 'Baseline: amount', '/p/bf/onboarding/1', 'bf', program='bf', phase='onboarding', hdr=H('About your smoking', pill='1 of 3'), body=[
        steps(1, 3), eyebrow('Question 1 of 3'), title('On a typical day, how many cigarettes?'),
        radio(['I don’t smoke every day', '10 or fewer', '11–20', '21–30', '31 or more'], 2, key='value'),
        card(v='mint', title='Why we ask', text='Tailors your plan and estimates money saved. Not a diagnosis.'),
    ], footer=[button('Next', go('bf_q2'))])
    S('bf_q2', 'Baseline: triggers', '/p/bf/onboarding/2', 'bf', program='bf', phase='onboarding', hdr=H('Your triggers', pill='2 of 3'), body=[
        steps(2, 3), eyebrow('Choose all that apply'), title('When do you most want a cigarette?'),
        chips(['Stress', 'After meals', 'Driving', 'With coffee', 'Social', 'Work breaks', 'Alcohol', 'Boredom', 'Morning', 'Scrolling'], ['Stress', 'After meals', 'Driving', 'With coffee'], key='value'),
        field('Add your own', None, placeholder='Type another situation…', key='add_your_own'), text('Used to prepare, never to monitor. No background location.', 'small'),
    ], footer=[button('Next', go('bf_q3'))])
    S('bf_q3', 'Baseline: reasons', '/p/bf/onboarding/3', 'bf', program='bf', phase='onboarding', hdr=H('Your reasons', pill='3 of 3'), body=[
        steps(3, 3), title('What are you quitting for?'), text('Choose all that matter. Your top reason appears when a craving hits.', 'muted'),
        chips(['Protect my family', 'Breathe easier', 'Save money', 'Feel in control', 'My health', 'Be there for my future'], ['Protect my family', 'Breathe easier', 'Save money'], key='value'),
        card(v='mint', eyebrow='When a craving hits', children=[quote('You chose this for your family. This feeling will pass.')]),
    ], footer=[button('Save my reasons', go('bf_path'))])
    S('bf_path', 'Choose path', '/p/bf/plan/path', 'bf', program='bf', phase='plan', hdr=H('Your path', pill='Plan 1 of 3'), body=[
        title('What feels possible right now?'), text('There’s no wrong place to start.', 'muted'),
        radio([ri('Set a quit date', 'Prepare 7–14 days, then stop', 'Recommended'), ri('Quit today', 'Skip the calendar; extra support now'), ri('Reduce gradually', 'Step down to zero over 4 weeks'), ri('Explore first', 'No date. Lessons and Rescue only')], key='path'),
        card(v='coral', title='Talk to a person first?', text='Quitline counselor or your care team', action=tab('support')),
    ], footer=[button('Continue with this path', branch('Selected path', [('Set a quit date', go('bf_date')), ('Quit today', go('bf_support')), ('Reduce gradually', go('bf_stepdown')), ('Explore first', onboarding_or('bf_home_explore'))], on='radio', key='path'))])
    S('bf_date', 'Select quit date', '/p/bf/plan/date', 'bf', program='bf', phase='plan', hdr=H('Quit date', pill='Plan 2 of 3'), body=[
        title('Choose a day to begin.'), text('7–14 days away gives you time to prepare without losing momentum.', 'muted'),
        calendar('August 2026', 28, [28, 29, 30, 31], today=21),
        card(v='dark', eyebrow='Your quit date', title='Friday, August 28, 2026', text='7 days to prepare · Pacific Time'),
        toggle('Quit-day check-in at 7:00 AM', 'Lock screen: “You have a Tether reminder.”', True, key='quit_day_check_in_at_7_00_am'),
    ], footer=[button('Confirm this date', go('bf_support'))])
    S('bf_stepdown', 'Step-down schedule', '/p/bf/plan/reduce', 'bf', program='bf', phase='plan', hdr=H('Step-down schedule', pill='Plan 2 of 3'), body=[
        title('Cut back at your pace.'), text('From your baseline of 15 a day. Adjust any week.', 'muted'),
        kv([('This week', '15 → 12 a day'), ('Week 2', '9 a day'), ('Week 3', '5 a day'), ('Week 4', '2 a day'), ('Quit day · Sep 18', '0')]),
        card(v='mint', text='Reducing works best paired with a quit date. Ask your clinician about nicotine replacement while cutting down.'),
    ], footer=[button('Save schedule', go('bf_support'))])
    S('bf_support', 'Support & preparation', '/p/bf/plan/support', 'bf', program='bf', phase='plan', hdr=H('Support', pill='Plan 3 of 3'), body=[
        title('You don’t have to do this alone.'),
        rows([row('Jordan', 'Friend · text message · evening before', lead=L_av('J'), action=go('support_add_person')), row('Add a supporter', None, lead=L_icon('+'), action=go('support_add_person'))], title='Your support circle'),
        card(checklist([ci('Remove cigarettes, lighters, ashtrays', done=True), ci('Make home and car smoke-free', done=True), ci('Stock gum, water or snacks')]), eyebrow='Prepare your space · 2 of 3'),
        toggle('Remind me to discuss quit medicines with my care team', 'Education only. The app never prescribes.', True, key='remind_me_to_discuss_quit_medici'),
    ], footer=[button('Review my plan', go('bf_review'))])
    S('bf_review', 'Review plan', '/p/bf/plan/review', 'bf', program='bf', phase='plan', hdr=H('Review your plan', pill='Ready'), body=[
        title('Your plan is ready.'), text('Tap any item to edit.', 'muted'),
        rows([row('Quit approach', 'Set a quit date', action=go('bf_path')), row('Quit date', 'Fri, Aug 28 · 7 days to prepare', action=go('bf_date')),
              row('Top reason', 'Protect my family', action=go('bf_q3')), row('Support', 'Jordan · evening before', action=go('bf_support')), row('Space', '2 of 3 tasks done', action=go('bf_support'))]),
        text('Starting turns on your preparation tasks and reminders. Support messages always need your approval.', 'small'),
    ], footer=[button('Start my plan', submit('PUT /v1/quit-plan', onboarding_or('bf_home'))), link('Save and finish later', tab('plans'))], api=['PUT /v1/quit-plan'])
    S('bf_home', 'BreatheFree home', '/p/bf/home', 'bf', program='bf', phase='daily', tabname='plans', hdr=home_hdr('bf'), body=[
        card(v='dark', eyebrow='Your quit day', children=[big('7 days', None, 'Friday, August 28 · Pacific Time')]),
        card(v='coral', title='Craving now?', text='One tap · no typing', cta=button('Rescue', sheet('rescue_pick'), v='rescue', small=True)),
        card(checklist([ci('Stock gum, water or healthy snacks', 'About 3 minutes')]), eyebrow='Today’s step'),
        card(v='mint', eyebrow='Your top reason', children=[quote('Protect my family.')]),
        rows([row('Daily check-in', 'About 60 seconds', action=sheet('checkin')), row('Medication center', 'Nicotine patch · recorded plan', action=go('bf_meds')),
              row('Progress', 'Saved $42.70 so far', action=go('bf_progress')), row('Edit my plan', None, action=go('bf_review')), settings_row('bf')]),
    ], desc='Pre-quit state. Quit-day and Explore states are variants.')
    S('bf_home_quitday', 'BreatheFree · quit day', '/p/bf/home?state=quit-day', 'bf', program='bf', phase='milestone', tabname='plans', variant_of='bf_home', state='quit day', hdr=home_hdr('bf'), body=[
        eyebrow('Quit day · Aug 28'), title('Keep today simple.'),
        card(v='dark', eyebrow='Since your quit time', children=[big('2h 41m', None, 'Started 7:00 AM · Pacific')]),
        card(v='coral', title='I have a craving', text='One tap · no typing', cta=button('Rescue', sheet('rescue_pick'), v='rescue', small=True)),
        card(title='I smoked or had a slip', text='Your progress will not be erased', action=go('bf_slip')),
        card(checklist([ci('Water, then a 5-minute walk', 'From your trigger plan')]), eyebrow='Next best step'),
        rows([row('Morning check-in', None, action=sheet('checkin')), row('Medication center', 'Patch · taken 8:07 AM', action=go('bf_meds'))]),
    ])
    S('bf_home_explore', 'BreatheFree · explore', '/p/bf/home?state=explore', 'bf', program='bf', phase='daily', tabname='plans', variant_of='bf_home', state='explore', hdr=home_hdr('bf'), body=[
        eyebrow('Exploring · no date set'), title('Learn at your own pace.'),
        card(v='coral', title='Craving now?', text='Rescue works without a plan', cta=button('Rescue', sheet('rescue_pick'), v='rescue', small=True)),
        card(tag='bf', title='Cravings: what to expect', text='4 min read', action=go('learn_lesson')),
        card(tag='bf', title='What quit medicines can do', text='Education only · 5 min', action=go('learn_lesson')),
        card(v='mint', title='Ready when you are', text='Setting a date takes 2 minutes.', cta=button('Choose a path', go('bf_path'), small=True)),
    ])
    S('bf_slip', 'Slip recovery', '/p/bf/slip', 'bf', program='bf', phase='milestone', hdr=H('Slip recovery', left='close', pill='Private'), body=[
        eyebrow('Your progress is still here'), title('A slip is information, not the end.'),
        kv([('Smoke-free days so far', '6 of 7 · kept')]),
        chips(['A puff or two', 'One cigarette', 'More', 'Prefer not to say'], ['A puff or two'], multi=False, label='What happened?', key='what_happened'),
        chips(['Stress', 'Around smokers', 'Alcohol', 'Scrolling late'], ['Stress'], label='What was going on? (optional)', key='what_was_going_on_optional'),
        radio([ri('Continue from this moment', 'Keep your plan', 'Recommended'), ri('Choose a new quit time')], key='next'),
    ], footer=[button('Save and start a 2-min Rescue', submit('POST /v1/records/lapses', branch('Selected option', [('Continue from this moment', rep('rescue_active')), ('Choose a new quit time', rep('bf_date'))], on='radio', key='next'))), link('Skip for now', back())],
       api=['POST /v1/records/lapses'], desc='Append-only lapse event. No counter decreases.')
    S('bf_meds', 'Medication center', '/p/bf/meds', 'bf', program='bf', phase='resources', hdr=H('Medication center'), body=[
        banner('info', 'Education and tracking, not prescribing. The app never selects a medicine or changes a dose.'),
        card(eyebrow='Your recorded plan', title='Nicotine patch · morning', text='Entered by you · follow your clinician’s instructions',
             children=[buttons(button('Taken today', toast('Recorded: taken at 8:07 AM'), small=True), button('Not today', toast('Recorded: not taken'), v='secondary', small=True))]),
        rows([row('Nicotine replacement', 'Patch, gum, lozenge', action=go('learn_lesson')), row('Prescription options', 'Varenicline · bupropion SR', action=go('learn_lesson'))], title='Learn'),
        card(v='warn', title='Pregnant, breastfeeding or under 18?', text='Talk with a doctor before using quit medicines.'),
        card(v='urgent', title='Side effect or worrying symptom?', text='Contact your care team or pharmacist. Emergency: 911.', action=go('support_message_care')),
    ], footer=[button('Add or update recorded plan', go('bf_meds_edit'), v='secondary')])
    S('bf_meds_edit', 'Edit recorded plan', '/p/bf/meds/edit', 'bf', program='bf', phase='resources', hdr=H('Recorded plan'), body=[
        title('Record the plan from your clinician'), field('Medicine', 'Nicotine patch', kind='select', key='medicine', bind='bf.meds.medicine'), field('Strength', '21 mg / 24 h', key='strength'), field('When', 'Every morning', kind='select', key='when', bind='bf.meds.when'),
        toggle('Private reminder', 'Lock screen hides the medicine name', True, key='private_reminder', bind='bf.meds.private_reminder'), text('You’re recording, not changing, your plan. Ask your clinician about any change.', 'small'),
    ], footer=[button('Save plan', submit('PUT /v1/program-data/bf/meds', toast('Plan saved', back())))])
    S('bf_progress', 'BreatheFree progress', '/p/bf/progress', 'bf', program='bf', phase='resources', hdr=H('Progress', pill='BreatheFree'), body=[
        seg(['7 days', '30 days', 'All'], '7 days', key='value'),
        bars([10, 7, 4, 3, 1, 1, 0], 'bf', title='Cigarettes / day', missing=[3], labels=list('MTWTFSS'), caption='Thursday: no check-in · not counted as zero'),
        stats([st('Est. avoided', '61', 'cigarettes'), st('Est. saved', '$42.70', '$14 per pack'), st('Cravings eased', '4 of 6', 'after a tool'), st('Most helpful', 'Breathing', '3 of 4 times')]),
        rows([row('How estimates work', '10/day · $14/pack · 5 min each', action=sheet('bf_estimates'))]),
    ])
    S('bf_estimates', 'How estimates work', '/p/bf/progress/estimates', 'bf', program='bf', phase='resources', kind='sheet', over='Progress', body=[
        title('How estimates are calculated'), kv([('Baseline', '10 cigarettes a day'), ('Price', '$14.00 per pack'), ('Time per cigarette', '5 minutes'), ('Avoided', 'baseline − reported')]),
        text('Estimates, not measurements. Missing days are left out.', 'small'),
    ], footer=[button('Edit numbers', toast('Opened baseline settings', close()), v='secondary'), button('Done', close())])

    # ================================================================ SCROLLFREE
    flow('sf', 'ScrollFree', 'Social media use · Quit / Reduce. Self-report first, minute goal + app-free windows, Pause 60, buddy, weekly reflection.', 'sf')
    intro('sf', [('Goal', 'minutes a day + app-free times'), ('Pause 60', 'intent check, not a lock'), ('Never', 'reads messages or feeds')], '~1 min/day',
          (go('sf_q1'), 'Notice what pulls you in, set a goal that feels doable, and pause for 60 seconds when the urge hits.'),
          notes=['Never called “addiction”.'])  # P-62: design rule, not rendered
    S('sf_q1', 'Baseline: use', '/p/sf/onboarding/1', 'sf', program='sf', phase='onboarding', hdr=H('About your use', pill='1 of 2'), body=[
        steps(1, 2), title('On a typical day, how long on social apps?'), text('A rough guess is fine.', 'muted'),
        radio(['Less than 1 hour', '1–2 hours', '3–4 hours', '5+ hours'], 2, key='value'),
        chips(['Short video', 'Feeds', 'Messaging', 'Games', 'News'], ['Short video', 'Feeds'], label='Which pull hardest? (categories only)', key='which_pull_hardest_categories_on'),
    ], footer=[button('Next', go('sf_q2'))])
    S('sf_q2', 'Baseline: triggers', '/p/sf/onboarding/2', 'sf', program='sf', phase='onboarding', hdr=H('Your triggers', pill='2 of 2'), body=[
        steps(2, 2), title('When do you reach for it?'),
        chips(['Bored', 'Lonely', 'In bed', 'Avoiding work', 'After conflict', 'Waiting', 'Can’t sleep', 'First thing'], ['Bored', 'In bed', 'Avoiding work'], key='value'),
        seg(['Better', 'Same', 'Worse'], 'Worse', label='How do you usually feel after?', key='how_do_you_usually_feel_after'),
        text('Used for your plan only. ScrollFree never reads what you look at.', 'small'),
    ], footer=[button('Next', go('sf_goal'))])
    S('sf_goal', 'Goal & windows', '/p/sf/plan/goal', 'sf', program='sf', phase='plan', hdr=H('Your goal', pill='Plan'), body=[
        title('Set a goal that feels doable.'), text('From about 3 hours a day.', 'muted'),
        card(slider('Daily social time', 90, 30, 240, '30 min', '4 h', 'sf', ' min', key='daily_social_time'), toggle('Step down 15 min each week', None, True, key='step_down_15_min_each_week')),
        card(checklist([ci('Bedtime', '10:00 PM – 7:00 AM', True), ci('Meals', 'When you mark a meal', True), ci('First hour awake')]), eyebrow='App-free times'),
        rows([row('Connect Screen Time', 'Optional · totals only', action=go('sf_screentime'))]),
    ], footer=[button('Save my goal', go('sf_buddy'))])
    S('sf_screentime', 'Connect Screen Time', '/p/sf/screen-time', 'sf', program='sf', phase='plan', hdr=H('Screen Time', pill='Optional'), body=[
        illus('◷'), title('See your Screen Time here, if you want.', align='center'), text('Apple’s Screen Time shows your daily totals by category inside Tether. Tether can’t read, store or share those minutes.', 'muted', align='center'),
        kv([('Shows', 'Minutes per category, on this phone'), ('Never reads', 'Content, messages, contacts'), ('Turn off', 'Anytime in Account')]),
    ], footer=[button('Allow access', branch('iOS Screen Time permission', [('Allowed', toast('Screen Time connected', back())), ('Not allowed', rep('sf_screentime_denied'))],
                                         id='sf.screentime.ios_request', ask='screenTimeRequest',
                                         when={'granted': 'Allowed', 'denied': 'Not allowed', 'unavailable': 'Not allowed'})), button('Not now', back(), v='secondary')])
    S('sf_screentime_denied', 'Screen Time denied', '/p/sf/screen-time?state=denied', 'sf', program='sf', phase='plan', variant_of='sf_screentime', state='permission denied', hdr=H('Screen Time', pill='Optional'), body=[
        banner('info', 'Screen Time access was not allowed.'), title('Self-report works just as well.'),
        text('We’ll ask for a quick estimate in your evening check-in. You can connect later in Account → ScrollFree.', 'muted'),
    ], footer=[button('Continue with self-report', back()), button('Open phone settings', settings(), v='secondary')])
    S('sf_buddy', 'Accountability buddy', '/p/sf/plan/buddy', 'sf', program='sf', phase='plan', hdr=H('Buddy', pill='Optional'), body=[
        title('Want someone in your corner?'), text('Your buddy only sees what you choose to send.', 'muted'), field('Name', 'Sam', key='name'),
        checklist([ci('A weekly “I hit my goal” message', done=True), ci('My minutes per day'), ci('Nothing automatic: I send each one', done=True)], label='They can see', key='buddy_can_see', bind='sf.buddy.can_see'),
        card(v='mint', eyebrow='Preview', children=[quote('Phone-free nights this week: 5. Thanks for cheering me on!')]),
    ], footer=[button('Save and finish', submit('PUT /v1/program-data/sf/plan', onboarding_or('sf_home'))), link('Skip for now', onboarding_or('sf_home'))])
    S('sf_home', 'ScrollFree home', '/p/sf/home', 'sf', program='sf', phase='daily', tabname='plans', hdr=home_hdr('sf'), body=[
        card(v='dark', eyebrow='Yesterday', children=[big('2h 10m', None, 'Goal 90 min · down from 3h')]),
        card(v='coral', title='Urge to scroll?', text='Take 60 seconds first', cta=button('Pause 60', go('sf_pause'), v='rescue', small=True)),
        card(title='Want firmer limits?', text='Unplug can pause apps you choose, after limits you set. Optional.', cta=button('Set up', go('sf_unplug_intro'), v='secondary', small=True)),
        card(checklist([ci('Charge your phone outside the bedroom', 'Tonight · bedtime window 10 PM')]), eyebrow='Today’s step'),
        rows([row('This week', '5 of 7 phone-free nights', action=go('sf_week')), row('Had a long scroll?', 'Reflect, nothing resets', action=go('sf_slip')),
              row('Goal & windows', '90 min · bedtime', action=go('sf_goal')), row('Buddy', 'Sam · weekly message', action=go('sf_buddy')), settings_row('sf')]),
    ])
    S('sf_pause', 'Pause 60', '/p/sf/pause', 'sf', program='sf', phase='rescue', kind='fullscreen', dark=True, bg='indigo', hdr=H('Pause 60', left='close', pill='Urge rescue', dark=True), body=[
        title('Before you open it, one breath.', 'l'), text('What did you pick up your phone for?'), ring('42', palette='indigo'),
        chips(['Message someone', 'Bored', 'Avoiding something', 'Can’t sleep'], ['Bored'], multi=False, key='value'),
        card(v='dark2', title='Bored? Try instead:', text='2-min walk · text one real person · a short lesson'),
    ], footer=[button('I’m good, put it down', submit('POST /v1/program-data/sf/pauses', toast('Nice. Logged as a pause.', reset('today'))), v='white'), link('Open anyway (logged as information)', toast('Logged. No judgment.', close()))])
    S('sf_slip', 'Long-scroll recovery', '/p/sf/slip', 'sf', program='sf', phase='milestone', hdr=H('Long scroll', pill='Private'), body=[
        title('That happens. What pulled you in?'), text('Nothing resets. Your phone-free nights still count.', 'muted'),
        chips(['Couldn’t sleep', 'Bored', 'Stressed', 'Didn’t notice time'], ['Couldn’t sleep'], key='value'),
        radio([ri('Keep my goal, try again tonight', None, 'Recommended'), ri('Make tomorrow’s goal easier'), ri('Move bedtime window 30 min earlier')], key='value_2'),
    ], footer=[button('Save', submit('POST /v1/records/lapses', toast('Saved', rep('sf_home'))))])
    S('sf_week', 'Weekly reflection', '/p/sf/week', 'sf', program='sf', phase='milestone', hdr=H('Week 2', pill='ScrollFree'), body=[
        title('Your week, honestly.'),
        bars([190, 160, 130, 0, 110, 95, 85], 'sf', title='Social minutes / day', missing=[3], target=90, labels=list('MTWTFSS'), caption='Thursday: no check-in · not counted as zero'),
        stats([st('Phone-free nights', '5/7'), st('Urges paused', '11', '7 put down')]),
        card(v='mint', eyebrow='You said', children=[quote('I feel drained after long scrolls.')], text='“Drained” was 4× less common on phone-free nights.'),
        card(eyebrow='Next week', title='Step down to 75 min?', children=[buttons(button('Yes', toast('Goal set to 75 min', back()), small=True), button('Stay at 90', back(), v='secondary', small=True))]),
    ])

    # ================================================================ CLEARAIR
    flow('ca', 'ClearAir', 'Respiratory · Manage. Clinician action plan, zone check, yellow-zone steps with re-check, red-zone route, progress against own zones.', 'ca')
    intro('ca', [('Zone check', 'green · yellow · red'), ('Red zone', 'one tap to 911'), ('Zones', 'from your clinician only')], '~1 min/day',
          (go('ca_q1'), 'Check your zone, log symptoms and know exactly what to do, using the plan your clinician gave you.'))
    S('ca_q1', 'Diagnosis & plan', '/p/ca/onboarding/1', 'ca', program='ca', phase='onboarding', hdr=H('About your breathing', pill='1 of 2'), body=[
        steps(1, 2), title('Which applies to you?'), text('As told by a clinician.', 'muted'),
        radio(['Asthma', 'COPD', 'Other lung condition', 'Not diagnosed: I want to learn'], 0, key='value'),
        seg(['Yes', 'No', 'Not sure'], 'Yes', label='Do you have a written action plan?', key='has_plan'),
    ], footer=[button('Next', branch('Has a written action plan?', [('Yes', go('ca_plan')), ('No / Not sure', go('ca_noplan'))], on='segmented', key='has_plan'))])
    S('ca_plan', 'Enter action plan', '/p/ca/plan', 'ca', program='ca', phase='plan', hdr=H('Your action plan', pill='2 of 2'), body=[
        steps(2, 2), title('Copy your plan from your clinician.'), text('ClearAir never creates or changes zones.', 'muted'),
        card(field('Peak flow from', '400', unit='L/min', kind='number', key='green_from'), field('Daily medicine', 'Controller inhaler · 2 puffs AM/PM', key='daily_medicine'), eyebrow='Green zone'),
        card(field('Peak flow', '200–399', unit='L/min', key='peak_flow'), eyebrow='Yellow zone'),
        card(field('Below', '200', unit='L/min', kind='number', key='red_below'), eyebrow='Red zone'),
        button('Add a photo of my plan', toast('Camera opened'), v='secondary'),
    ], footer=[button('Save plan', submit('PUT /v1/program-data/ca/plan', onboarding_or('ca_home')))])
    S('ca_noplan', 'No action plan yet', '/p/ca/plan?state=none', 'ca', program='ca', phase='plan', variant_of='ca_plan', state='empty', hdr=H('No action plan', pill='Learn'), body=[
        illus('i', 'warn'), title('Let’s get you a plan first', align='center'),
        text('Zone checks need a plan from your clinician. Until then you can learn, log symptoms and prepare questions.', 'muted', align='center'),
        rows([row('Symptom diary', 'Shareable with your clinician', action=go('ca_symptoms')), row('Questions for my next visit', None, action=go('learn_lesson')), row('Message my care team', None, action=go('support_message_care'))]),
    ], footer=[button('Continue to ClearAir', onboarding_or('ca_home'))])
    S('ca_home', 'ClearAir home', '/p/ca/home', 'ca', program='ca', phase='daily', tabname='plans', hdr=home_hdr('ca'), body=[
        card(v='dark', eyebrow='Today’s zone', title='Green · 410 L/min', text='Checked 7:40 AM · from your plan'),
        button('Check my zone', go('ca_zone')),
        card(v='urgent', title='Red-zone plan', text='Open it fast', action=go('ca_red')),
        rows([row('Log symptoms', None, action=go('ca_symptoms')), row('Progress', '10 green · 2 yellow · 0 red', action=go('ca_progress')),
              row('My action plan', 'Entered Sep 3', action=go('ca_plan')), settings_row('ca')]),
    ])
    S('ca_zone', 'Zone check', '/p/ca/zone', 'ca', program='ca', phase='daily', hdr=H('Zone check', pill='Today'), body=[
        title('How is your breathing?'), field('Peak flow (optional)', '310', unit='L/min', kind='number', key='peak_flow', hint='50–900 L/min'),
        chips(['Coughing', 'Wheezing', 'Short of breath', 'Chest tightness', 'Woke at night', 'Can’t speak in full sentences'], ['Wheezing'], label='Symptoms now', key='symptoms'),
        eyebrow('Your zone · updates as you type'), zone('yellow', rule='ca.zone'), text('Worked out only from the plan you entered (green from 400, red below 200).', 'small'),
    ], footer=[button('Save and see my steps', submit('POST /v1/program-data/ca/zone-checks', branch('Computed zone', [('Green', toast('Green zone · follow your daily routine', rep('ca_home'))), ('Yellow', rep('ca_yellow')), ('Red', rep('ca_red')), ('Invalid peak flow', toast('Check your peak flow: 50–900 L/min'))], decide='ca.zone')))],
       desc='"Can’t speak in full sentences" routes to red regardless of peak flow.')
    S('ca_yellow', 'Yellow zone', '/p/ca/zone/yellow', 'ca', program='ca', phase='rescue', hdr=H('Yellow zone', pill='Your plan'), body=[
        card(v='warn', title='Follow your yellow-zone steps', text='From the plan you entered on Sep 3'),
        card(checklist([ci('Reliever inhaler · 2–4 puffs', 'As written in your plan', True), ci('Re-check in 20 minutes', 'We’ll remind you'), ci('Tell your care team if no better', 'As your plan directs')])),
        card(v='urgent', title='Getting worse or can’t speak in full sentences?', text='Go to your red-zone plan', action=rep('ca_red')),
    ], footer=[button('Remind me in 20 min', toast('Reminder set for 20 minutes', rep('ca_home'))), button('Message care team', go('support_message_care'), v='secondary')])
    S('ca_red', 'Red zone', '/p/ca/zone/red', 'ca', program='ca', phase='rescue', kind='fullscreen', hdr=H('Red zone · act now', left='close'), body=[
        banner('urgent', 'Follow your red-zone plan and seek urgent care now.'),
        button('Call 911', call('911'), v='danger', arrow=False),
        card(checklist([ci('Reliever inhaler now, as written'), ci('Call your clinician or 911'), ci('Don’t drive yourself')]), eyebrow='Your red-zone plan'),
        rows([row('Tell Maria', 'Emergency contact · preview first', lead=L_av('M'), action=sheet('support_message'))]),
        text('Stays open until you close it.', 'small'),
    ])
    S('ca_symptoms', 'Symptom log', '/p/ca/symptoms', 'ca', program='ca', phase='daily', hdr=H('Log symptoms'), body=[
        title('What are you noticing?'), chips(['Coughing', 'Wheezing', 'Short of breath', 'Chest tightness', 'Woke at night'], ['Wheezing', 'Woke at night'], key='value'),
        seg(['Mild', 'Moderate', 'Severe'], 'Mild', label='How bad?', key='how_bad'), chips(['Cold air', 'Smoke', 'Pollen', 'Exercise', 'Not sure'], ['Cold air'], label='Possible trigger', key='possible_trigger'),
        field('Note (optional)', None, placeholder='Anything else to tell your clinician', kind='multiline', key='note_optional'),
    ], footer=[button('Save', submit('POST /v1/program-data/ca/symptoms', toast('Saved', back())))])
    S('ca_progress', 'ClearAir progress', '/p/ca/progress', 'ca', program='ca', phase='resources', hdr=H('Progress', pill='ClearAir'), body=[
        line([410, 405, 398, 380, 360, 310, 330, 350, 372, 390, 401, 404], 'ca', title='Peak flow · 12 days', unit='L/min', band=[400, 450], caption='Shaded: your green zone, from your plan'),
        stats([st('Green', '10'), st('Yellow', '2'), st('Red', '0')], cols=3),
        card(eyebrow='Most common symptom', title='Wheezing at night (3×)', text='Worth mentioning at your next visit.'),
    ], footer=[button('Create visit summary', go('hw_summary'), v='secondary')])

    # ================================================================ HEARTWISE
    flow('hw', 'Heartwise', 'Cardiovascular · Manage. Clinician targets, two-reading BP log, validation, symptom-gated crisis route, trends, lipid panel, previewed visit summary.', 'hw')
    intro('hw', [('Readings', 'BP + cholesterol panels'), ('Targets', 'from your clinician'), ('A reading is', 'information, not a grade')], '~2 min/day',
          (sheet('focus_full'), 'Log blood pressure and cholesterol, see trends and prepare for visits. Both focus slots are in use, so you’ll choose how to add it.'))
    S('hw_q1', 'Baseline', '/p/hw/onboarding/1', 'hw', program='hw', phase='onboarding', hdr=H('About you', pill='1 of 2'), body=[
        steps(1, 2), title('Has a clinician talked with you about…'),
        chips(['High blood pressure', 'High cholesterol', 'Heart disease', 'Stroke', 'None of these'], ['High blood pressure'], key='value'),
        seg(['Yes', 'No', 'Not sure'], 'Yes', label='Do you have a home BP monitor?', key='do_you_have_a_home_bp_monitor'),
        card(v='mint', text='No monitor? Many pharmacies have free kiosks. We’ll show how to measure correctly.'),
    ], footer=[button('Next', go('hw_targets'))])
    S('hw_targets', 'Clinician targets', '/p/hw/plan/targets', 'hw', program='hw', phase='plan', hdr=H('Your targets', pill='2 of 2'), body=[
        steps(2, 2), title('What target did your clinician give you?'),
        fieldrow(field('Top below', '130', unit='mmHg', kind='number', key='top_below'), field('Bottom below', '80', unit='mmHg', kind='number', key='bottom_below')),
        radio([ri('I don’t have a target yet', 'Readings show without a target line')], -1, key='value', bind='hw.targets.no_target_yet'),
        chips(['Morning', 'Evening', 'Both'], ['Both'], multi=False, label='When should we remind you?', key='when_should_we_remind_you', bind='hw.targets.reminder_time'),
        text('Heartwise never sets or grades targets.', 'small'), link('Import from my health record', go('records_add')),
    ], footer=[button('Save targets', submit('PUT /v1/program-data/hw/targets', onboarding_or('hw_home')))])
    S('hw_home', 'Heartwise home', '/p/hw/home', 'hw', program='hw', phase='daily', tabname='plans', hdr=home_hdr('hw'), body=[
        card(v='dark', eyebrow='Last reading · 7:52 AM', children=[big('128/82', 'mmHg', 'Average of 2 · target below 130/80')]),
        button('Log blood pressure', go('hw_log')),
        rows([row('Trends', '30-day average 132/82', action=go('hw_trends')), row('Cholesterol panel', 'LDL 138 · Sep 30', action=go('hw_lipids')),
              row('Visit summary', 'Preview before sharing', action=go('hw_summary')), row('From your health record', '12 readings · Patel Family Medicine (Epic)', action=go('records_item')), row('My targets', '130/80 from Dr. Patel', action=go('hw_targets')), settings_row('hw')]),
        emergency('Chest pain, pressure or trouble breathing? Call 911 now.', [button('Call 911', call('911'), v='danger', small=True)]),
    ])
    S('hw_log', 'Log BP · reading 1', '/p/hw/log', 'hw', program='hw', phase='daily', hdr=H('Log blood pressure', pill='1 of 2'), body=[
        title('Sit quietly for 5 minutes first.'),
        fieldrow(field('Top (systolic)', '138', unit='mmHg', kind='number', key='systolic'), field('Bottom (diastolic)', '86', unit='mmHg', kind='number', key='diastolic')),
        field('Pulse (optional)', '72', unit='bpm', kind='number', key='pulse_optional'), chips(['Left arm', 'Right arm'], ['Left arm'], multi=False, key='value'),
        card(v='mint', title='Tip', text='Take a second reading after 1 minute. We’ll average them.'),
    ], footer=[button('Next reading', go('hw_log2'))])
    S('hw_log2', 'Log BP · reading 2', '/p/hw/log/2', 'hw', program='hw', phase='daily', hdr=H('Log blood pressure', pill='2 of 2'), body=[
        title('Second reading'), text('Same arm, 1 minute later.', 'muted'),
        fieldrow(field('Top (systolic)', '132', unit='mmHg', kind='number', key='systolic'), field('Bottom (diastolic)', '84', unit='mmHg', kind='number', key='diastolic')),
        field('Pulse (optional)', '70', unit='bpm', kind='number', key='pulse_optional'), kv([('Reading 1', '138/86'), ('Average so far', '135/85')]),
    ], footer=[button('Save readings', submit('POST /v1/program-data/hw/readings', branch('Validated average', [('Valid · below crisis range', rep('hw_result')), ('Invalid value', rep('hw_log_error')), ('≥180 top or ≥120 bottom', rep('hw_crisis'))], decide='hw.bp')))])
    S('hw_log_error', 'Log BP · validation', '/p/hw/log/2?state=error', 'hw', program='hw', phase='daily', variant_of='hw_log2', state='error', hdr=H('Log blood pressure', pill='Check'), body=[
        title('Let’s double-check that.'),
        fieldrow(field('Top (systolic)', '128', unit='mmHg', kind='number', key='top_systolic'), field('Bottom (diastolic)', '310', unit='mmHg', error='Too high for the bottom number. Did you mean 81?', kind='number', key='bottom_diastolic')),
        text('Valid range: top 70–250, bottom 40–150, bottom lower than top.', 'small'),
    ], footer=[button('Save readings', None, state='disabled'), link('Edit reading', rep('hw_log2'))])
    S('hw_result', 'Reading saved', '/p/hw/log/result', 'hw', program='hw', phase='daily', hdr=H('Saved', left='close'), body=[
        illus('✓'), title('135/85 saved', 'l', align='center'), text('Average of 2 readings. Your clinician’s target is below 130/80.', 'muted', align='center'),
        card(v='mint', text='One reading is information, not a grade. Trends over weeks matter most.'),
    ], footer=[button('See trends', rep('hw_trends')), button('Back to Heartwise', rep('hw_home'), v='secondary')])
    S('hw_crisis', 'Crisis range', '/p/hw/crisis', 'hw', program='hw', phase='rescue', kind='fullscreen', hdr=H('Check this reading', left='close'), body=[
        banner('urgent', '186/122 is in a range that needs attention now.'),
        card(v='urgent', title='Do you have any of these right now?', text='Chest pain · shortness of breath · back pain · numbness or weakness · vision change · trouble speaking'),
        button('Yes · call 911', call('911'), v='danger', arrow=False), button('No symptoms · re-check in 5 min', rep('hw_recheck'), v='secondary'),
        text('If it’s still this high on re-check, contact your clinician today. Heartwise doesn’t diagnose.', 'small'),
    ])
    S('hw_recheck', 'Re-check timer', '/p/hw/crisis/recheck', 'hw', program='hw', phase='rescue', hdr=H('Re-check', left='close'), body=[
        title('Rest, then measure again.', align='center'), timer('4:12', 'until re-check'),
        card(checklist([ci('Sit with your back supported'), ci('Feet flat, arm at heart level'), ci('No talking while measuring')])),
        emergency('New chest pain, weakness or trouble speaking? Call 911 now.', [button('Call 911', call('911'), v='danger', small=True)]),
    ], footer=[button('Re-check now', rep('hw_log')), button('Contact my clinician', go('support_message_care'), v='secondary')])
    S('hw_trends', 'Trends', '/p/hw/trends', 'hw', program='hw', phase='resources', hdr=H('Trends', pill='Heartwise'), body=[
        seg(['7 days', '30 days', '90 days'], '30 days', key='value'),
        line([142, 140, 138, 139, 135, 133, 136, 131, 129, 130, 128, 127], 'hw', title='Systolic · morning avg', unit='target < 130', band=[110, 130], caption='Shaded: your clinician’s target'),
        stats([st('30-day avg', '132/82'), st('Readings', '48', '4 days missed')]),
    ], footer=[button('Create visit summary', go('hw_summary'), v='secondary')])
    S('hw_lipids', 'Cholesterol panel', '/p/hw/lipids', 'hw', program='hw', phase='milestone', hdr=H('Cholesterol panel', pill='Lab'), body=[
        title('Add your lab results'), text('Copy from your lab report. Units: mg/dL.', 'muted'),
        fieldrow(field('Total', '212', unit='mg/dL', kind='number', key='total'), field('LDL', '138', unit='mg/dL', kind='number', key='ldl')),
        fieldrow(field('HDL', '46', unit='mg/dL', kind='number', key='hdl'), field('Triglycerides', None, unit='mg/dL', placeholder='Optional', kind='number', key='triglycerides')),
        field('Lab date', 'Sep 30, 2026', kind='date', key='lab_date'),
    ], footer=[button('Save panel', submit('POST /v1/program-data/hw/lipids', toast('Panel saved', back())))])
    S('hw_summary', 'Visit summary', '/p/hw/summary', 'hw', program='hw', phase='resources', hdr=H('Visit summary', pill='Preview'), body=[
        title('Share with Dr. Patel’s clinic?'),
        kv([('Dates', 'Sep 17 – Oct 17'), ('BP average', '132/82 (48 readings)'), ('Highest', '186/122 · Oct 2 · re-checked 144/90'), ('Latest panel', 'LDL 138 · Sep 30')]),
        text('Only Heartwise data. Nothing from your other programs.', 'small'), toggle('Include notes', None, False, key='include_notes'),
    ], footer=[button('Send summary', submit('POST /v1/care/summaries', toast('Summary sent to Dr. Patel’s clinic', back()))), button('Save as PDF', toast('PDF saved to Files'), v='secondary')])

    entry('ca_red', 'Shortcut: ClearAir red-zone plan')
