from dsl import *
from screens_prog_a import intro, home_hdr, settings_row

H = header

def programs_b():
    # ================================================================ STEADY
    flow('st', 'Steady', 'Diabetes & metabolic · Manage. Clinician range + own low plan, reading log, low route with 15-min timer, meal reset, patterns, A1C.', 'st')
    intro('st', [('Readings', 'meter or CGM entries'), ('Range', 'from your clinician'), ('A high reading is', 'information, not failure')], '~2 min/day',
          (go('st_q1'), 'Log readings, see patterns around meals and sleep, and follow the low plan your clinician gave you. Steady never counts calories.'))
    S('st_q1', 'Type & device', '/p/st/onboarding/1', 'st', program='st', phase='onboarding', hdr=H('About you', pill='1 of 2'), body=[
        steps(1, 2), title('Which describes you?'), text('As told by a clinician.', 'muted'),
        radio([ri('Type 2 diabetes'), ri('Prediabetes'), ri('Type 1 diabetes', 'Logging only; follow your care team for insulin'), ri('Gestational diabetes', 'Education only; talk with your care team'), ri('Not diagnosed: learn')], 0),
        seg(['Meter', 'CGM', 'Lab only'], 'Meter', label='How do you check?'),
    ], footer=[button('Next', go('st_range'))])
    S('st_range', 'Range & low plan', '/p/st/plan/range', 'st', program='st', phase='plan', hdr=H('Your range', pill='2 of 2'), body=[
        steps(2, 2), title('Enter the range your clinician gave you.'), seg(['mg/dL', 'mmol/L'], 'mg/dL'),
        fieldrow(field('Before meals from', '80', unit='mg/dL', kind='number'), field('to', '130', unit='mg/dL', kind='number')),
        field('2 h after meals below', '180', unit='mg/dL', kind='number'),
        card(field('Low below', '70', unit='mg/dL', kind='number', key='low'), field('My low steps', '15 g fast sugar, re-check in 15 min', kind='multiline'), eyebrow='Your low plan'),
        link('Import from my health record', go('records_add')),
    ], footer=[button('Save range', submit('PUT /v1/program-data/st/range', onboarding_or('st_home')))])
    S('st_home', 'Steady home', '/p/st/home', 'st', program='st', phase='daily', tabname='plans', hdr=home_hdr('st'), body=[
        card(v='dark', eyebrow='Last reading · 2 h after lunch', children=[big('142', 'mg/dL', 'Within your after-meal range (below 180)')]),
        button('Log a reading', go('st_log')),
        rows([row('Meal energy reset', '3 minutes', action=go('st_reset')), row('Patterns', '71% in range · 14 days', action=go('st_patterns')),
              row('A1C history', '7.4% · Oct 1', action=go('st_a1c')), row('My range & low plan', None, action=go('st_range')), settings_row('st')]),
        card(v='mint', text='Steady never counts calories. A high reading is information, not failure.'),
    ])
    S('st_log', 'Log reading', '/p/st/log', 'st', program='st', phase='daily', hdr=H('Log a reading'), body=[
        field('Reading', '142', unit='mg/dL', kind='number', key='reading', hint='From your meter or CGM · 20–600 mg/dL'), chips(['Fasting', 'Before meal', '2 h after meal', 'Bedtime', 'Other'], ['2 h after meal'], multi=False, label='When?'),
        chips(['Fine', 'Shaky', 'Sweaty', 'Tired', 'Thirsty'], ['Fine'], label='How do you feel?'),
        field('Note (optional)', 'Pasta lunch', hint='Never shared unless you choose'),
    ], footer=[button('Save reading', submit('POST /v1/program-data/st/readings', branch('Reading vs. your range', [('In or above range', toast('Saved', rep('st_home'))), ('Below your low', rep('st_low')), ('Invalid (outside 20–600)', toast('Check your meter reading'))], decide='st.glucose')))])
    S('st_low', 'Low reading', '/p/st/low', 'st', program='st', phase='rescue', kind='fullscreen', hdr=H('Low reading', left='close'), body=[
        banner('urgent', '62 mg/dL is below your low of 70.'),
        card(checklist([ci('Take 15 g of fast sugar', '4 glucose tablets or ½ cup juice', True), ci('Re-check in 15 minutes'), ci('Repeat if still below 70')]), v='warn', eyebrow='Your low plan'),
        timer('14:52', 'until re-check'),
        card(v='urgent', title='Confused, can’t swallow or passing out?', text='Someone should call 911 now.', children=[button('Call 911', call('911'), v='danger', arrow=False)]),
    ], footer=[button('Re-check now', rep('st_log'))], desc='Timer survives app close and fires during quiet hours.')
    S('st_reset', 'Meal energy reset', '/p/st/reset', 'st', program='st', phase='daily', hdr=H('Meal energy reset', pill='3 min'), body=[
        title('Feeling the post-meal slump?'),
        card(checklist([ci('Drink a glass of water', done=True), ci('Take a 10-minute walk if you can', done=True), ci('Take five slow breaths'), ci('Feel unwell? Contact your clinician')])),
        card(v='mint', text='Walking after meals helps some people’s readings. Check with your clinician what’s right for you.'),
    ], footer=[button('Done', toast('Nice work', back()))])
    S('st_patterns', 'Patterns', '/p/st/patterns', 'st', program='st', phase='resources', hdr=H('Patterns', pill='Steady'), body=[
        seg(['7 days', '14 days', '30 days'], '14 days'),
        line([196, 182, 175, 190, 168, 160, 172, 158, 165, 150, 162, 149], 'st', title='After meals', unit='mg/dL · range ≤ 180', band=[80, 180]),
        stats([st('In your range', '71%', 'of 38 readings'), st('Lows', '1', 'Oct 9 · treated')]),
        card(v='mint', eyebrow='Pattern', title='Readings were higher on nights with less than 6 h sleep.'),
    ])
    S('st_a1c', 'A1C', '/p/st/a1c', 'st', program='st', phase='milestone', hdr=H('A1C lab', pill='Lab day'), body=[
        title('Add your A1C'), field('A1C', '7.4', unit='%', kind='number'), field('Lab date', 'Oct 1, 2026', kind='date'),
        kv([('Previous', '7.9% · Jul 2'), ('Change', '−0.5 points')]), text('Your clinician sets your A1C goal. Steady shows history only.', 'small'),
    ], footer=[button('Save', submit('POST /v1/program-data/st/a1c', toast('Saved', back())))])

    # ================================================================ RENEW
    flow('re', 'Renew', 'Kidney & liver · Manage. Risk check, plain-language result, labs and trends, reminders, warning-symptom route.', 're')
    intro('re', [('Risk check', 'diabetes, BP, alcohol, family'), ('Labs', 'eGFR, ACR, ALT tracking'), ('Reminders', 'checks from your clinician')], '~1 min/day')
    S('re_q1', 'Risk check', '/p/re/onboarding/1', 're', program='re', phase='onboarding', hdr=H('Risk check', pill='1 of 1'), body=[
        steps(1, 1), title('Do any of these apply?'), text('These raise the chance of kidney or liver problems.', 'muted'),
        chips(['Diabetes', 'High blood pressure', 'Heart disease', 'Family history of kidney disease', 'Regular alcohol', 'Hepatitis B or C', 'None'], ['Diabetes', 'High blood pressure']),
        seg(['Kidney', 'Liver', 'Both', 'No'], 'No', label='Known condition?'),
    ], footer=[button('See what this means', go('re_result'))])
    S('re_result', 'Risk result', '/p/re/plan', 're', program='re', phase='plan', hdr=H('Your result', pill='Not a diagnosis'), body=[
        title('Worth asking about a kidney check.'),
        card(v='mint', text='People with diabetes and high blood pressure are usually advised to have yearly kidney tests: a blood test (eGFR) and a urine test (ACR).'),
        card(checklist([ci('Ask about eGFR and urine ACR at my next visit', done=True), ci('Remind me 1 week before my visit')])),
        card(title='Also see Heartwise and Steady', text='Managing BP and glucose protects your kidneys.', action=go('catalog')),
    ], footer=[button('Save my plan', submit('PUT /v1/program-data/re/plan', onboarding_or('re_home')))])
    S('re_home', 'Renew home', '/p/re/home', 're', program='re', phase='daily', tabname='plans', hdr=home_hdr('re'), body=[
        card(v='dark', eyebrow='Latest eGFR · Oct 3', children=[big('58', 'mL/min', 'Next check Apr 2027 · from your clinician')]),
        card(checklist([ci('Medicine reminder · 8:00 AM', 'As entered from your clinician', True), ci('Water reminder', 'Only if your clinician hasn’t limited fluids')]), eyebrow='Today'),
        rows([row('Add lab results', None, action=go('re_labs')), row('Lab history', '2 years', action=go('re_history')), row('Check symptoms', None, action=go('re_symptoms')), settings_row('re')]),
        card(v='mint', title='Over-the-counter pain relief?', text='Some (like ibuprofen) can affect kidneys. Ask your pharmacist.'),
    ])
    S('re_labs', 'Add labs', '/p/re/labs', 're', program='re', phase='milestone', hdr=H('Add lab results', pill='Lab'), body=[
        field('eGFR', '58', unit='mL/min/1.73m²', kind='number'), field('Urine ACR', '42', unit='mg/g', kind='number'),
        field('ALT (liver)', None, unit='U/L', placeholder='Optional', kind='number'), field('Lab date', 'Oct 3, 2026', kind='date'),
        text('Copy numbers exactly from your report. Renew shows trends; your clinician explains them.', 'small'),
        link('Import from my health record', go('records_add')),
    ], footer=[button('Save results', submit('POST /v1/program-data/re/labs', toast('Saved', rep('re_history'))))])
    S('re_history', 'Lab history', '/p/re/history', 're', program='re', phase='resources', hdr=H('Lab history', pill='Renew'), body=[
        line([72, 69, 66, 64, 61, 58], 're', title='eGFR · 2 years', unit='mL/min', caption='Lower over time. Bring this to your next visit.'),
        kv([('Latest eGFR', '58 · Oct 3'), ('Latest ACR', '42 mg/g'), ('Next check', 'Apr 2027 (from your clinician)')]),
    ], footer=[button('Create visit summary', go('hw_summary'), v='secondary')])
    S('re_symptoms', 'Symptom check', '/p/re/symptoms', 're', program='re', phase='rescue', hdr=H('Check symptoms', left='close'), body=[
        title('Do you have any of these?'), chips(['Very little urine', 'Swelling in legs or face', 'Yellow skin or eyes', 'Confusion', 'Vomiting blood', 'None'], ['Yellow skin or eyes']),
        banner('urgent', 'Yellow skin or eyes needs a clinician today.'),
    ], footer=[button('Contact my care team', go('support_message_care')), button('Vomiting blood or confused? Call 911', call('911'), v='danger', arrow=False)])

    # ================================================================ NOURISH
    flow('nu', 'Nourish', 'Obesity & nutrition · Build habits. Weight-neutral weekly habits, off-track reset, week-4 milestone, protective mode.', 'nu')
    intro('nu', [('Weekly habit', 'one at a time'), ('Weight', 'off by default'), ('Approach', 'add, don’t restrict')], '~1 min/day')
    S('nu_q1', 'Goals & screen', '/p/nu/onboarding/1', 'nu', program='nu', phase='onboarding', hdr=H('What matters', pill='1 of 1'), body=[
        steps(1, 1), title('What would you like more of?'),
        chips(['Energy', 'Easy meals', 'More plants', 'More water', 'Move more', 'Save on food', 'Feel better about food'], ['Energy', 'Easy meals', 'More water']),
        card(seg(['No', 'Yes', 'Prefer not to say'], 'No', key='eating'), title='Have you struggled with eating, like restricting, bingeing or purging?', text='If yes, we adjust Nourish and share support options.'),
    ], footer=[button('Next', branch('Eating-history answer', [('No', go('nu_habit')), ('Yes / Prefer not to say', go('nu_protect'))], on='segmented', key='eating'))])
    S('nu_habit', 'Weekly habit', '/p/nu/plan', 'nu', program='nu', phase='plan', hdr=H('This week’s habit', pill='Plan'), body=[
        title('Pick one habit for this week.'),
        radio([ri('Add a vegetable to dinner', '5 nights this week', 'Suggested'), ri('Water before each meal', 'Every day'), ri('Cook at home', '3 times this week'), ri('10-minute walk after a meal', '4 times')]),
        card(toggle('Track weight', 'Off by default · can stay off forever', False)),
    ], footer=[button('Start this habit', submit('PUT /v1/program-data/nu/habit', onboarding_or('nu_home')))])
    S('nu_home', 'Nourish home', '/p/nu/home', 'nu', program='nu', phase='daily', tabname='plans', hdr=home_hdr('nu'), body=[
        card(eyebrow='Habit · week 2', title='Add a vegetable to dinner', text='3 of 5 nights', children=[steps(3, 5)], cta=button('Done today', toast('Nice. 4 of 5 nights.'), small=True)),
        card(v='mint', eyebrow='Tip', title='Frozen vegetables count, and are often cheaper.'),
        card(eyebrow='Quick recipe · 15 min', title='Bean and veggie tacos', text='Under $2 a serving', action=go('learn_lesson')),
        rows([row('Busy week?', 'Reset without guilt', action=go('nu_reset')), row('Week 4 milestone', 'In 2 weeks', action=go('nu_week4')), row('Change habit', None, action=go('nu_habit')), settings_row('nu')]),
    ])
    S('nu_reset', 'Off-track reset', '/p/nu/reset', 'nu', program='nu', phase='rescue', hdr=H('Off track?', pill='Reset'), body=[
        title('Busy week? That’s okay.'), text('Missing days doesn’t undo the ones you did.', 'muted'),
        radio([ri('Keep this habit, start fresh today'), ri('Make it smaller', '3 nights instead of 5'), ri('Pick a different habit')], key='option'),
    ], footer=[button('Continue', branch('Selected option', [('Keep this habit', toast('Fresh start today', rep('nu_home'))), ('Make it smaller', toast('Goal set to 3 nights', rep('nu_home'))), ('Pick a different habit', rep('nu_habit'))], on='radio', key='option'))])
    S('nu_week4', 'Week 4 milestone', '/p/nu/milestone', 'nu', program='nu', phase='milestone', hdr=H('Week 4', pill='Milestone'), body=[
        illus('4'), title('Four weeks of small habits.', 'l', align='center'),
        kv([('Habits tried', '4'), ('Days done', '19'), ('Favorite', 'Water before meals')]),
        seg(['Worse', 'Same', 'Better'], 'Better', label='How do you feel about food lately?'),
    ], footer=[button('Choose next habit', rep('nu_habit'))])
    S('nu_protect', 'Protective mode', '/p/nu/support', 'nu', program='nu', phase='rescue', hdr=H('Support', pill='Private'), body=[
        title('Thanks for telling us.'), text('Nourish has turned off weight, amount goals and before/after comparisons.', 'muted'),
        card(title='Talking to someone can help', text='A clinician or eating-disorder specialist can support you. We can help you prepare what to say.', cta=button('Prepare', go('support_message_care'), small=True)),
        emergency('In crisis? Call or text 988 · Emergency 911'),
    ], footer=[button('Continue with gentle habits', onboarding_or('nu_habit', 'nu_habit'))])

    # ================================================================ STRIDE
    flow('sd', 'Stride', 'Healthy aging · Build habits. Falls check, weekly movement plan, audio-first sessions, I-fell route, home safety, scoped caregiver access.', 'sd')
    intro('sd', [('Sessions', '5–15 min, audio + video'), ('Falls', 'home safety + I fell button'), ('Caregiver', 'optional, Stride only')], '~10 min/day')
    S('sd_q1', 'Falls check', '/p/sd/onboarding/1', 'sd', program='sd', phase='onboarding', hdr=H('How you move', pill='1 of 1'), body=[
        steps(1, 1), seg(['No', 'Once', '2+ times'], 'Once', label='In the last year, have you fallen?'),
        seg(['No', 'Sometimes', 'Often'], 'Sometimes', label='Do you feel unsteady standing or walking?'),
        seg(['No', 'A little', 'A lot'], 'A little', label='Do you worry about falling?'),
        card(v='mint', text='A fall plus feeling unsteady is worth mentioning to your clinician. We’ll add it to your visit list.'),
    ], footer=[button('Next', go('sd_plan'))])
    S('sd_plan', 'Movement plan', '/p/sd/plan', 'sd', program='sd', phase='plan', hdr=H('Your movement plan', pill='Plan'), body=[
        title('Three short sessions a week'), kv([('Mon', 'Balance · 8 min'), ('Wed', 'Strength (chair) · 10 min'), ('Fri', 'Walk + balance · 12 min')]),
        card(checklist([ci('Do sessions near a sturdy chair', done=True), ci('Tell my caregiver when I finish')])),
        text('Check with your clinician before starting a new exercise program.', 'small'),
    ], footer=[button('Start plan', submit('PUT /v1/program-data/sd/plan', onboarding_or('sd_home')))])
    S('sd_home', 'Stride home', '/p/sd/home', 'sd', program='sd', phase='daily', tabname='plans', hdr=home_hdr('sd'), body=[
        card(v='dark', eyebrow='Today · Wednesday', title='Strength (chair) · 10 min', cta=button('Start', go('sd_session'), v='lime', small=True)),
        card(v='urgent', title='I fell', text='Get help or log a fall', action=go('sd_fell')),
        rows([row('Home safety checklist', '2 of 5 done', action=go('sd_safety')), row('Caregiver access', 'Rosa · Stride only', action=go('sd_caregiver')), row('Movement plan', '3 sessions a week', action=go('sd_plan')), settings_row('sd')]),
        stats([st('This week', '1 of 3', 'sessions'), st('Falls logged', '0', 'last 30 days')]),
    ])
    S('sd_session', 'Session player', '/p/sd/session', 'sd', program='sd', phase='daily', kind='fullscreen', dark=True, hdr=H('Balance · 8 min', left='close', pill='2 of 6', dark=True), body=[
        illus('⇅', 'dark'), title('Heel-to-toe stand', 'xl', align='center'), text('Hold the chair. Place one foot in front of the other. Hold 10 seconds.', align='center'),
        ring('7', palette='teal'), chips(['Audio on', 'Large text', 'Captions'], ['Audio on', 'Large text', 'Captions']),
    ], footer=[button('Next exercise', toast('Exercise 3 of 6')), button('Finish session', submit('POST /v1/program-data/sd/sessions', toast('Session saved', rep('sd_home'))), v='white')])
    S('sd_fell', 'I fell', '/p/sd/fell', 'sd', program='sd', phase='rescue', kind='fullscreen', hdr=H('I fell', left='close'), body=[
        title('Are you hurt?'), button('I hit my head or can’t get up · Call 911', call('911'), v='danger', arrow=False),
        rows([row('Call Rosa', 'Caregiver', lead=L_av('R'), action=call('(555) 010-2244', 'Call Rosa'))]),
        card(v='mint', title='How to get up safely', text='Roll to your side, crawl to a sturdy chair, kneel, then rise slowly.', action=go('learn_lesson')),
    ], footer=[button('I’m okay, log this fall', submit('POST /v1/program-data/sd/falls', toast('Fall logged. Added to your visit list.', rep('sd_home'))), v='secondary')])
    S('sd_safety', 'Home safety', '/p/sd/safety', 'sd', program='sd', phase='resources', hdr=H('Home safety', pill='Checklist'), body=[
        title('Make your home safer'),
        card(checklist([ci('Remove loose rugs', done=True), ci('Night lights in hallway and bathroom', done=True), ci('Grab bar in shower'), ci('Stair rails on both sides'), ci('Vision check this year')])),
        text('2 of 5 done', 'small'),
    ], footer=[button('Save', submit('PUT /v1/program-data/sd/safety', toast('Saved', back())))])
    S('sd_caregiver', 'Caregiver access', '/p/sd/caregiver', 'sd', program='sd', phase='account', hdr=H('Caregiver access', pill='Optional'), body=[
        title('Let someone help'), field('Name', 'Rosa'), field('Phone', '(555) 010-2244', kind='phone'),
        checklist([ci('When I finish a session', done=True), ci('If I log a fall', done=True), ci('My other programs', 'Never available to caregivers')], label='Rosa can see'),
    ], footer=[button('Send invite', submit('POST /v1/care/caregivers', toast('Invite sent to Rosa', back())))])

    # ================================================================ EASE
    flow('ea', 'Ease', 'Mental & behavioral · Support. Optional PHQ-2/GAD-2, never a diagnosis, safety plan, mood check-in, crisis route, check-back day.', 'ea')
    intro('ea', [('Mood check-in', '30 seconds'), ('Screening', 'optional, private'), ('Help now', '988 always one tap away')], '~2 min/day')
    S('ea_q1', 'Optional screener', '/p/ea/onboarding/1', 'ea', program='ea', phase='onboarding', hdr=H('Optional check', pill='1 of 4'), body=[
        steps(1, 4), text('Over the last 2 weeks, how often have you been bothered by…', 'small'), title('Little interest or pleasure in doing things?'),
        radio(['Not at all', 'Several days', 'More than half the days', 'Nearly every day'], 1), text('PHQ-2 / GAD-2 · validated questions · skippable', 'small'),
    ], footer=[button('Next', go('ea_result')), button('Skip the check', go('ea_plan'), v='secondary')], desc='4 questions in production (PHQ-2 + GAD-2); one shown.')
    S('ea_result', 'Screener result', '/p/ea/result', 'ea', program='ea', phase='onboarding', hdr=H('Your answers', pill='Not a diagnosis'), body=[
        title('Talking to someone could help.'),
        card(v='mint', text='Your answers suggest you’ve been carrying a lot lately. A doctor, counselor or therapist can help figure out what would make the biggest difference.'),
        rows([row('Find a therapist near me', 'In-network filters', action=ext('https://findtreatment.gov')), row('Talk to my primary care doctor', 'We’ll help you prepare', action=go('support_message_care')), row('Not now', 'Keep using Ease tools', action=go('ea_plan'))]),
        emergency(),
    ])
    S('ea_plan', 'Safety plan', '/p/ea/plan', 'ea', program='ea', phase='plan', hdr=H('Safety plan', pill='Private'), body=[
        title('Make a plan for hard moments'), text('Based on the Stanley-Brown safety plan. Only you can see this.', 'small'),
        field('My warning signs', 'Not sleeping, pulling away from friends', kind='multiline'), field('Things that help me', 'Walk the dog, shower, music'), field('People I can reach', 'Sam · (555) 010-3311'),
        kv([('Crisis line', '988 · call or text'), ('Emergency', '911')]),
    ], footer=[button('Save plan', submit('PUT device:encrypted/ea/safety-plan', onboarding_or('ea_home')))], desc='Stored encrypted on the device only.')
    S('ea_home', 'Ease home', '/p/ea/home', 'ea', program='ea', phase='daily', tabname='plans', hdr=home_hdr('ea'), body=[
        card(v='dark', eyebrow='How are you right now?', title='30-second mood check-in', cta=button('Start', go('ea_mood'), v='lime', small=True)),
        rows([row('My safety plan', 'Updated Oct 2', action=go('ea_plan')), row('Check-back', 'In 6 days', action=go('ea_checkback')), row('Find a professional', None, action=go('ea_result')), settings_row('ea')]),
        card(tag='ea', title='Sleep and mood: 3 small changes', text='5 min', action=go('learn_lesson')),
        emergency(),
    ])
    S('ea_mood', 'Mood check-in', '/p/ea/mood', 'ea', program='ea', phase='daily', hdr=H('Mood check-in', pill='Ease'), body=[
        seg(['Very low', 'Low', 'Okay', 'Good', 'Great'], 'Low', label='How are you right now?'),
        chips(['Work', 'Money', 'Family', 'Health', 'Lonely', 'Sleep', 'Thoughts of harming myself', 'Not sure'], ['Work', 'Sleep'], label='What’s going on?', key='going_on'),
        card(v='dark', eyebrow='Try now · 2 min', title='Grounding: 5 things you can see', cta=button('Start', go('rescue_active'), v='lime', small=True)),
    ], footer=[button('Save', submit('POST /v1/program-data/ea/moods', branch('Self-harm option selected?', [('No', toast('Saved', back())), ('Yes', rep('crisis'))], decide='ea.selfharm')))])
    S('ea_checkback', 'Check-back day', '/p/ea/check-back', 'ea', program='ea', phase='milestone', hdr=H('Check-back', pill='2 weeks'), body=[
        title('It’s been two weeks. How are things?'), seg(['Worse', 'Same', 'Better'], 'Same'),
        chips(['Yes, I have an appointment', 'Not yet', 'I don’t want to'], ['Not yet'], multi=False, label='Did you reach out to someone?'),
        card(v='mint', text='That’s okay. Would a short list of what to say help?', cta=button('Show me', go('learn_lesson'), small=True)),
    ], footer=[button('Save', submit('POST /v1/program-data/ea/check-backs', toast('Saved', back())))])

    # ================================================================ CHECKUP
    flow('ck', 'Checkup', 'Preventive · Prevent. Personal due list from USPSTF/CDC guidance, item detail with options and cost, mark done, screening-day prep.', 'ck')
    intro('ck', [('Personal list', 'USPSTF / CDC guidance'), ('Reminders', 'weekly, quiet'), ('Records', 'mark done, add dates')], '~1 min/week')
    S('ck_q1', 'About you', '/p/ck/onboarding/1', 'ck', program='ck', phase='onboarding', hdr=H('About you', pill='1 of 1'), body=[
        steps(1, 1), title('A few details to personalize'), field('Age', '52', kind='number'),
        seg(['Female', 'Male', 'Intersex', 'Skip'], 'Female', label='Sex assigned at birth'),
        chips(['Smoke or used to', 'Diabetes', 'Family history of cancer', 'Pregnant', 'None'], ['Smoke or used to'], label='Any of these?'),
        text('Used only to build your list. Change anytime.', 'small'), link('Import vaccination history', go('records_add')),
    ], footer=[button('Build my list', submit('PUT /v1/program-data/ck/profile', onboarding_or('ck_list')))])
    S('ck_list', 'Due list', '/p/ck/home', 'ck', program='ck', phase='daily', tabname='plans', hdr=home_hdr('ck'), body=[
        title('3 due, 1 to ask about'),
        card(title='Flu vaccine', text='Every year · pharmacies offer walk-ins', eyebrow='Due now', children=[buttons(button('Find a pharmacy', ext('https://www.vaccines.gov'), small=True), button('I got it', go('ck_done'), v='secondary', small=True))]),
        rows([row('Colorectal screening', 'Ages 45–75 · several options', pill='Due', action=go('ck_item')), row('Mammogram', 'Every 2 years, ages 40–74', pill='Due', action=go('ck_day')),
              row('Lung cancer screening', 'Ages 50–80 with smoking history', pill='Ask', action=go('ck_item')), settings_row('ck')]),
    ])
    S('ck_uptodate', 'Up to date', '/p/ck/home?state=empty', 'ck', program='ck', phase='daily', tabname='plans', variant_of='ck_list', state='empty', hdr=home_hdr('ck'), body=[
        illus('✓'), title('You’re up to date', 'l', align='center'), text('Next: flu vaccine in Sep 2027. We’ll remind you a month before.', 'muted', align='center'),
        button('See full schedule', rep('ck_list'), v='secondary')])
    S('ck_item', 'Item detail', '/p/ck/item/:id', 'ck', program='ck', phase='resources', hdr=H('Colorectal screening'), body=[
        title('Your options'), text('All are recommended. Talk with your clinician about which fits.', 'muted'),
        kv([('Stool test (FIT)', 'at home · yearly'), ('Stool DNA test', 'at home · every 1–3 yrs'), ('Colonoscopy', 'clinic · every 10 yrs')]),
        card(v='mint', title='Cost', text='Screening is often covered with no cost-sharing. Check with your insurer.'),
        text('Source: USPSTF 2021 · reviewed Aug 2026', 'small'),
    ], footer=[button('Message my care team', go('support_message_care')), button('Mark as done', go('ck_done'), v='secondary')])
    S('ck_done', 'Mark done', '/p/ck/done', 'ck', program='ck', phase='milestone', hdr=H('Mark as done'), body=[
        field('What', 'Flu vaccine', kind='select'), field('Date', 'Oct 12, 2026', kind='date'), field('Where (optional)', 'Main St Pharmacy'),
        checklist([ci('Remind me next year', done=True)]),
    ], footer=[button('Save', submit('POST /v1/program-data/ck/done', toast('Saved · next due Sep 2027', rep('ck_list'))))])
    S('ck_day', 'Screening day', '/p/ck/day', 'ck', program='ck', phase='milestone', hdr=H('Screening day', pill='Tomorrow'), body=[
        title('Mammogram tomorrow at 9:30 AM'),
        card(checklist([ci('Skip deodorant or powder', done=True), ci('Wear a two-piece outfit'), ci('Bring ID and insurance card')])),
        card(v='mint', title='Nervous?', text='It’s common. The scan takes about 20 minutes.', cta=button('2-min breathing', go('rescue_active'), small=True)),
    ], footer=[button('Add to calendar', toast('Added to your calendar')), button('Mark as done', go('ck_done'), v='secondary')])

    # ================================================================ BEACON
    flow('be', 'Beacon', 'Cancer · Prevent. Four journey paths: lowering risk, in treatment, after treatment, caregiver. Fever rule on the treatment path.', 'be')
    intro('be', [('Risk steps', 'smoking, sun, alcohol, activity'), ('Screening', 'linked with Checkup'), ('Treatment support', 'questions, side-effect diary')], '~1 min/week')
    S('be_q1', 'Journey stage', '/p/be/onboarding/1', 'be', program='be', phase='onboarding', hdr=H('Where are you?', pill='1 of 2'), body=[
        steps(1, 2), title('Which fits you best?'),
        radio([ri('Lowering my risk', 'Prevention and screening'), ri('Going through treatment', 'Support between appointments'), ri('After treatment', 'Survivorship'), ri('Supporting someone', 'Caregiver resources')], 0, key='stage'),
    ], footer=[button('Next', branch('Journey stage', [('Lowering my risk', go('be_q2')), ('Going through treatment', onboarding_or('be_tx')), ('After treatment', onboarding_or('be_survivor')), ('Supporting someone', tab('learn'))], on='radio', key='stage'))])
    S('be_q2', 'Family history', '/p/be/onboarding/2', 'be', program='be', phase='onboarding', hdr=H('Family history', pill='2 of 2'), body=[
        steps(2, 2), title('Has a close relative had cancer?'),
        chips(['Breast', 'Ovarian', 'Colorectal', 'Prostate', 'Pancreatic', 'Melanoma', 'None', 'Not sure'], ['Breast']), field('Relative’s age at diagnosis (if known)', '44', kind='number'),
        card(v='mint', text='A relative diagnosed before 50 may mean earlier screening or genetic counseling. We’ll add this to your visit list.'),
    ], footer=[button('See my plan', submit('PUT /v1/program-data/be/profile', onboarding_or('be_home')))])
    S('be_home', 'Beacon home', '/p/be/home', 'be', program='be', phase='daily', tabname='plans', hdr=home_hdr('be'), body=[
        title('Three steps that lower risk'),
        rows([row('Quitting smoking', 'In progress with BreatheFree', lead=L_prog('bf'), pill='Active', action=go('bf_home')), row('Monthly skin self-check', 'Guide with photos', action=go('learn_lesson')), row('Ask about genetic counseling', 'Because of family history', action=go('support_message_care'))]),
        card(title='Screenings come from Checkup', text='Mammogram due · colorectal due', cta=button('Open Checkup', go('ck_list'), v='secondary', small=True)),
        rows([row('Change my journey stage', None, action=go('be_q1')), settings_row('be')]),
    ])
    S('be_tx', 'Treatment support', '/p/be/treatment', 'be', program='be', phase='daily', tabname='plans', hdr=home_hdr('be'), body=[
        card(v='dark', eyebrow='Next appointment', title='Oct 22 · Oncology · 10:30 AM', cta=button('Questions', go('be_questions'), v='lime', small=True)),
        card(v='urgent', title='Fever of 100.4°F (38°C) or higher during chemo?', text='Call your oncology team now, day or night.', cta=button('Call', call('(555) 010-7000', 'Call oncology team'), v='danger', small=True)),
        rows([row('Today’s side-effect diary', 'About 1 minute', action=go('be_diary')), row('Feeling worried?', 'Tools in Ease', action=go('ea_intro')), settings_row('be')]),
    ])
    S('be_diary', 'Treatment diary', '/p/be/diary', 'be', program='be', phase='daily', hdr=H('Treatment diary', pill='Treatment'), body=[
        title('How are you feeling today?'), slider('Fatigue', 6, color='be'),
        chips(['Nausea', 'Pain', 'Mouth sores', 'Numbness', 'Low mood'], ['Nausea'], label='Anything else?'),
        card(v='urgent', title='Fever of 100.4°F (38°C) or higher?', text='Call your oncology team now.', cta=button('Call', call('(555) 010-7000', 'Call oncology team'), v='danger', small=True)),
    ], footer=[button('Save', submit('POST /v1/program-data/be/diary', toast('Saved', back())))])
    S('be_questions', 'Visit questions', '/p/be/questions', 'be', program='be', phase='milestone', hdr=H('Questions for my visit', pill='Oct 22'), body=[
        card(checklist([ci('What side effects should I call about?', done=True), ci('Can I keep working during treatment?'), ci('Who do I call after hours?')])),
        field('Add a question', None, placeholder='Type a question…'),
    ], footer=[button('Share with my care team', go('support_message_care'), v='secondary'), button('Done', back())])
    S('be_survivor', 'Survivorship', '/p/be/survivorship', 'be', program='be', phase='milestone', tabname='plans', hdr=home_hdr('be'), body=[
        title('How have the last 3 months been?'), seg(['Hard', 'Mixed', 'Good'], 'Mixed'),
        card(title='Worried about it coming back?', text='Very common. Ease has tools for this, and your team can help.', cta=button('Open Ease', go('ea_intro'), v='secondary', small=True)),
        kv([('Next follow-up', 'Jan 14, 2027')]), rows([row('Program settings', None, action=go('program_settings'))]),
    ], footer=[button('Save check-in', submit('POST /v1/program-data/be/survivorship', toast('Saved')))])
