from dsl import *

H = header

def shared():
    # ================================================================ ONBOARDING
    flow('onboarding', 'First run', 'Welcome → choose programs → focus → consent → basics → set up each focus program → reminders → save progress → Today.')
    S('welcome', 'Welcome', '/welcome', 'onboarding', phase='welcome', hdr=H('', left='logo', pill=None), body=[
        seg(['English', 'Español'], 'English', key='value'),
        illus('✿'),
        eyebrow('Welcome to Tether Health'), title('Care that meets you where you are.', 'xl'),
        text('Small steps, practical support and no judgment, for the parts of your health you choose.'),
        kv([('Private by design', 'No ads · never sold'), ('Help in one tap', 'No typing needed'), ('Your pace', 'Pause anytime')]),
    ], footer=[
        button('Get started', go('ob_programs')),
        link('I already have an account', sheet('auth_signin')),
        link('Terms and Privacy Notice', ext('https://www.tetherhealthgroup.com/privacy/')),
    ], desc='Language is chosen once for the whole account. No data is collected on this screen.')

    S('ob_programs', 'Choose programs', '/onboarding/programs', 'onboarding', phase='welcome', hdr=H('Choose programs', pill='1 of 5'), body=[
        steps(1, 5), title('What would you like support with?'), text('Choose any. You can add, pause or leave a program anytime.', 'muted'),
        tiles([tl(PROGRAMS[p][0], PROGRAMS[p][1], program=p, selected=p in ('bf', 'sf')) for p in ['bf', 'sf', 'ca', 'hw', 'st', 'ea', 'nu', 'sd']], key='programs'),
        link('See all 11 programs', go('catalog')),
    ], footer=[button('Continue with 2 programs', go('ob_focus'))], desc='Multi-select. Continue is disabled with 0 selected ("Choose at least one program").')

    S('ob_focus', 'Focus slots', '/onboarding/focus', 'onboarding', phase='welcome', hdr=H('Your focus', pill='2 of 5'), body=[
        steps(2, 5), title('Two at a time works best.'), text('Focus programs get daily steps and reminders. Learn only gives you lessons, with no tracking.', 'muted'),
        rows([row('BreatheFree', 'About 3 min a day', lead=L_prog('bf'), pill='Focus 1'), row('ScrollFree', 'About 1 min a day', lead=L_prog('sf'), pill='Focus 2')], title='Focus · daily support'),
        rows([row('ClearAir', 'Lessons about lung recovery', lead=L_prog('ca'), pill='Learn')], title='Learn only · no reminders'),
        card(v='mint', title='Why two?', text='People keep going with fewer daily asks. Swap anytime in Account → Programs.'),
        link('Add a third program', sheet('ob_third')),
    ], footer=[button('Continue', go('ob_consent'))])

    S('ob_third', 'Third program sheet', '/onboarding/focus/third', 'onboarding', phase='welcome', kind='sheet', over='Your focus', body=[
        eyebrow('Both focus slots are in use'), title('Add Heartwise as…'),
        radio([ri('Learn only for now', 'Lessons, no reminders. Upgrade anytime.', 'Suggested'), ri('Swap with ScrollFree', 'ScrollFree pauses. Its data and progress are kept.'), ri('Swap with BreatheFree', 'Not suggested during your quit week.')], key='value'),
    ], footer=[button('Continue', toast('Heartwise added as Learn only', close())), button('Cancel', close(), v='secondary')])

    S('ob_consent', 'Layered consent', '/onboarding/consent', 'onboarding', phase='onboarding', hdr=H('Your privacy', pill='3 of 5'), body=[
        steps(3, 5), title('Your story stays yours.'), text('Each program keeps its own data. Optional choices start off.', 'muted'),
        card(toggle('Essential app data', 'Account, plans and progress, encrypted. Required.', True, key='essential_app_data'), eyebrow='Account · required'),
        card(toggle('Private reminders', 'Lock screen: “You have a Tether reminder.”', True, key='private_reminders'), toggle('Share summaries with my care team', 'You preview every share', False, key='share_summaries_with_my_care_tea'), tag='bf', accent='bf'),
        card(toggle('Connect Screen Time', 'Optional · totals only, never content', False, key='connect_screen_time'), toggle('De-identified research', None, False, key='de_identified_research'), tag='sf', accent='sf'),
        text('No ads. No tobacco-industry funding. We never sell health information.', 'small'),
        link('Read the Privacy Notice', ext('https://www.tetherhealthgroup.com/privacy/'), align='left'),
    ], footer=[button('Agree and continue', submit('POST /v1/enrolments/consents', go('ob_basics')))], api=['POST /v1/enrolments/consents'])

    S('ob_basics', 'Shared basics', '/onboarding/basics', 'onboarding', phase='onboarding', hdr=H('About you', pill='4 of 5'), body=[
        steps(4, 5), eyebrow('Shared · asked once for all programs'), title('A few basics'),
        field('What should we call you?', 'Alex', key='what_should_we_call_you'), field('Age range', '35–44', kind='select', key='age_range'),
        seg(['< 5 h', '5–6 h', '7–8 h', '9+ h'], '5–6 h', label='Sleep on a typical night', key='sleep_on_a_typical_night'),
        seg(['Low', 'Some', 'High'], 'High', label='Usual stress', key='usual_stress'),
        card(v='mint', text='These answers are shared by your programs, so you’re never asked twice. Age range sets which lessons and screenings apply.', title='Why we ask'),
    ], footer=[button('Continue', go('ob_setup'))])

    S('ob_setup', 'Set up focus programs', '/onboarding/setup', 'onboarding', phase='onboarding', hdr=H('Set up', pill='5 of 5'), body=[
        steps(5, 5), title('Let’s set up your programs.'), text('Each takes about 3 minutes. You can stop and come back.', 'muted'),
        rows([row('BreatheFree', 'Quit plan · about 3 min', lead=L_prog('bf'), action=go('bf_q1'), pill='Start'),
              row('ScrollFree', 'Usage goal · about 2 min', lead=L_prog('sf'), action=go('sf_q1'), pill='Start')], title='Focus programs'),
        rows([row('ClearAir', 'Learn only · nothing to set up', lead=L_prog('ca'))], title='Learn only'),
        rows([row('Health records (optional)', 'Import from Epic MyChart, Medicare or another FHIR source', lead=L_icon('+'), action=go('records_add'))], title='Your data'),
        card(v='mint', text='Finishing a program setup brings you back here.', title='Tip'),
    ], footer=[button('Continue', go('ob_reminders')), link('Set up later', go('ob_reminders'))],
       desc='Hub for the onboarding context. Program setups return here (context.onboarding) instead of the program home.')

    S('ob_reminders', 'Reminder prime', '/onboarding/reminders', 'onboarding', phase='onboarding', hdr=H('Reminders'), body=[
        illus('◔'), title('Quiet, private reminders', 'l', align='center'), text('At most 2 a day, only for your focus programs.', align='center'),
        card(card(title='Tether Health', text='You have a Tether reminder.', v='flat'), eyebrow='Lock screen preview', text='Program names and health details stay hidden unless you turn them on.'),
        toggle('Quiet hours', '9:00 PM – 7:00 AM · safety alerts still come through', True, key='quiet_hours'),
    ], footer=[button('Turn on reminders', branch('System permission prompt', [('Allowed', go('ob_account')), ('Not allowed', go('ob_reminders_denied'))])), button('Not now', go('ob_account'), v='secondary')],
       desc='Shown before the OS prompt so the system dialog is expected.')
    S('ob_reminders_denied', 'Reminders denied', '/onboarding/reminders?state=denied', 'onboarding', phase='onboarding', variant_of='ob_reminders', state='permission denied', hdr=H('Reminders'), body=[
        banner('info', 'Notifications are off in your phone settings.'), title('You can still use everything.'),
        text('Today shows your steps when you open the app. To get reminders, allow notifications for Tether in Settings.', 'muted'),
    ], footer=[button('Open phone settings', settings(), v='secondary'), button('Continue without reminders', go('ob_account'))])

    S('ob_account', 'Save your progress', '/onboarding/account', 'onboarding', phase='account', hdr=H('Save your progress', left='close'), body=[
        title('Create your account'), text('Keeps your plans safe if you change phones. You can also continue on this phone only.', 'muted'),
        authbuttons(apple=auth('apple', [('Success', go('auth_merge')), ('Email already has a Tether account', go('auth_link')), ('Cancelled', toast('Sign-in cancelled')), ('Error', go('auth_social_error'))]), google=auth('google', [('Success', go('auth_merge')), ('Email already has a Tether account', go('auth_link')), ('Cancelled', toast('Sign-in cancelled')), ('Error', go('auth_social_error'))])),
        text('Sign in with Apple can hide your email: we use Apple’s private relay address.', 'small'),
        eyebrow('Or with email'),
        field('Email', 'alex@example.com', kind='email', key='email'), field('Password', '••••••••••••', hint='At least 12 characters. A passphrase works well.', kind='password', key='password'),
        checklist([ci('I’m 18 or older', done=True)], key='age_18_or_older'),
        text('Guest plans are encrypted on this phone. If you sign up later, we ask before uploading them.', 'small'),
    ], footer=[button('Create account', submit('POST supabase /auth/v1/signup', go('auth_verify'))), button('Continue on this phone only', reset('today'), v='secondary')], api=['POST supabase /auth/v1/signup'])

    # ================================================================ AUTH
    flow('auth', 'Account & sign-in', 'Sign up, verify email, sign in (with error), password reset, guest-plan merge, session expiry.')
    S('auth_verify', 'Verify email', '/auth/verify', 'auth', phase='account', hdr=H('Check your email'), body=[
        illus('@'), title('Confirm your email', 'l', align='center'), text('We sent a link to alex@example.com. Open it on this phone to finish.', align='center'),
        card(v='mint', text='Your plan is saved on this phone while you wait. Nothing is lost if you close the app.'),
    ], footer=[button('Open email app', ext('message://')), button('I’ve confirmed my email', go('auth_merge')), link('Resend link (available in 0:42)', toast('Link sent again'))])

    S('auth_signin', 'Sign in', '/auth/signin', 'auth', phase='account', kind='sheet', over='Welcome', body=[
        title('Welcome back'), authbuttons(apple=auth('apple', [('Success', reset('today')), ('Success · guest plan on phone', go('auth_merge')), ('New Apple ID, no Tether account', go('auth_social_new')), ('Cancelled', toast('Sign-in cancelled')), ('Error', go('auth_social_error'))]), google=auth('google', [('Success', reset('today')), ('Success · guest plan on phone', go('auth_merge')), ('New Google account, no Tether account', go('auth_social_new')), ('Cancelled', toast('Sign-in cancelled')), ('Error', go('auth_social_error'))])), eyebrow('Or with email'), field('Email', 'alex@example.com', kind='email', key='email'), field('Password', '••••••••', kind='password', key='password'),
        link('Forgot password?', go('auth_forgot'), align='left'),
    ], footer=[button('Sign in', branch('Sign-in result', [('Success', reset('today')), ('Success · guest plan on phone', go('auth_merge')), ('Wrong password', go('auth_signin_error'))])), button('Cancel', close(), v='secondary')], api=['POST supabase /auth/v1/token'])
    S('auth_signin_error', 'Sign-in error', '/auth/signin?state=error', 'auth', phase='account', kind='sheet', over='Welcome', variant_of='auth_signin', state='error', body=[
        title('Welcome back'), banner('error', 'That email and password don’t match. Check both and try again.'), authbuttons(apple=auth('apple', [('Success', reset('today')), ('Success · guest plan on phone', go('auth_merge')), ('New Apple ID, no Tether account', go('auth_social_new')), ('Cancelled', toast('Sign-in cancelled')), ('Error', go('auth_social_error'))]), google=auth('google', [('Success', reset('today')), ('Success · guest plan on phone', go('auth_merge')), ('New Google account, no Tether account', go('auth_social_new')), ('Cancelled', toast('Sign-in cancelled')), ('Error', go('auth_social_error'))])), eyebrow('Or with email'),
        field('Email', 'alex@example.com', kind='email', key='email'), field('Password', '••••••••', error='Password is incorrect.', kind='password', key='password'),
        link('Forgot password?', go('auth_forgot'), align='left'), text('After 5 tries we pause sign-in for 15 minutes to protect your account.', 'small'),
    ], footer=[button('Try again', branch('Sign-in result', [('Success', reset('today')), ('Wrong password', rep('auth_signin_error'))])), button('Cancel', close(), v='secondary')])

    S('auth_social_new', 'New account from Apple or Google', '/auth/social/new', 'auth', phase='account', hdr=H('Create account'), body=[
        illus('A'), title('Create your Tether account?', 'l', align='center'), text('No Tether account uses this Apple ID or Google account yet.', 'muted', align='center'),
        kv([('Name', 'Alex (shared by Apple)'), ('Email', 'Private relay · Hide My Email'), ('Password', 'None needed')]),
        text('You can add email & password or another sign-in method later in Account → Sign-in methods.', 'small'),
    ], footer=[button('Create my account', submit('POST supabase /auth/v1/token?grant_type=id_token', go('ob_programs'))), button('Use a different account', back(), v='secondary')],
       api=['POST supabase /auth/v1/token?grant_type=id_token'], desc='Supabase signInWithIdToken (provider apple|google). First sign-in creates the identity, then onboarding starts with the account attached.')
    S('auth_link', 'Link accounts', '/auth/link', 'auth', phase='account', hdr=H('Link accounts'), body=[
        illus('⇄'), title('You already have a Tether account', 'l', align='center'),
        text('alex@example.com signed up with email and password. Enter your password once to link Google. After that, either sign-in works.', 'muted', align='center'),
        field('Password', '••••••••••••', kind='password', key='password'), link('Forgot password?', go('auth_forgot')),
    ], footer=[button('Link and sign in', submit('POST supabase /auth/v1/user/identities (linkIdentity)', reset('today'))), button('Cancel', back(), v='secondary')],
       desc='Prevents duplicate accounts for the same email. Supabase manual identity linking after password re-auth.')
    S('auth_social_error', 'Apple / Google sign-in failed', '/auth/social/error', 'auth', phase='account', hdr=H('Sign in', left='close'), body=[
        illus('!', 'error'), title('Couldn’t sign in', 'l', align='center'), text('Google sign-in didn’t finish. Check your connection and try again, or use email.', 'muted', align='center'),
        text('Nothing was saved or shared.', 'small', align='center'),
    ], footer=[button('Try again', auth('google', [('Success', reset('today')), ('Error', toast('Still can’t reach Google. Try email.'))])), button('Use email instead', rep('auth_signin'), v='secondary')])

    S('auth_forgot', 'Reset password', '/auth/forgot', 'auth', phase='account', hdr=H('Reset password'), body=[
        title('Forgot your password?'), text('Enter your email and we’ll send a reset link.', 'muted'), field('Email', 'alex@example.com', kind='email', key='email'),
    ], footer=[button('Send reset link', submit('POST supabase /auth/v1/recover', rep('auth_forgot_sent')))])
    S('auth_forgot_sent', 'Reset link sent', '/auth/forgot/sent', 'auth', phase='account', hdr=H('Reset password'), body=[
        illus('✓'), title('Check your email', 'l', align='center'), text('If an account exists for that address, a reset link is on its way. It expires in 1 hour.', align='center'),
        text('We never say whether an email is registered, to protect your privacy.', 'small', align='center'),
    ], footer=[button('Back to welcome', reset('welcome'), v='secondary')])
    S('auth_newpass', 'Set new password', '/auth/reset', 'auth', phase='account', hdr=H('New password', left='close'), body=[
        title('Choose a new password'), field('New password', '••••••••••••', hint='At least 12 characters.', kind='password', key='new_password'), field('Confirm password', '••••••••••••', kind='password', key='confirm_password'),
    ], footer=[button('Save password', submit('PUT supabase /auth/v1/user', reset('today')))], desc='Opened from the reset email deep link.')

    S('auth_merge', 'Guest plan merge', '/auth/merge', 'auth', phase='account', kind='sheet', over='Today', body=[
        eyebrow('You’re signed in'), title('Upload the plan on this phone?'),
        rows([row('BreatheFree plan · this phone', 'Quit date Aug 28 · 3 reasons', lead=L_prog('bf'))]),
        text('Your account already has a BreatheFree plan from Aug 12.', 'small'),
        radio([ri('Keep both, choose later', 'Nothing is overwritten', 'Safest'), ri('Use this phone’s plan'), ri('Use the account’s plan')], key='value'),
    ], footer=[button('Continue', submit('POST /v1/quit-plan/guest-import', reset('today')))], api=['POST /v1/quit-plan/guest-import'],
       desc='Create-only import: a concurrent cloud plan returns 409 and both plans are kept.')

    S('auth_session', 'Session expired', '/auth/session', 'auth', phase='account', kind='sheet', over='Today', body=[
        title('Please sign in again'), text('For your security, sessions end after 30 days.', 'muted'),
        field('Password', None, placeholder='Password', kind='password', key='password'),
    ], footer=[button('Sign in', submit('POST supabase /auth/v1/token', close())), button('Use Face ID', close(), v='secondary')])

    # ================================================================ TODAY
    flow('today', 'Today', 'The shared home: Rescue first, one step per focus program, combined check-in, milestones and Learn-only lessons. Every state is specified.')
    today_hdr = H('Today', left='logo', avatar='A')
    S('today', 'Today', '/today', 'today', phase='daily', tabname='today', hdr=today_hdr, body=[
        eyebrow('Friday, August 21'), title('Good morning, Alex.'),
        chips(['All', 'BreatheFree', 'ScrollFree'], ['All'], multi=False, dots={'BreatheFree': 'bf', 'ScrollFree': 'sf'}, key='value'),
        card(v='coral', title='Craving or urge to scroll?', text='Help for the next few minutes', cta=button('Rescue', sheet('rescue_pick'), v='rescue', small=True)),
        card(checklist([ci('Stock gum, water or snacks', 'BreatheFree · 3 min', True), ci('Charge your phone outside the bedroom', 'ScrollFree · tonight')]), eyebrow='Today · 2 small steps'),
        card(v='dark', eyebrow='Check-in · about 90 sec', title='Covers both programs', cta=button('Start', sheet('checkin'), v='lime', small=True)),
        stats([st('Quit day', '7 days', 'Fri, Aug 28', 'bf'), st('Yesterday', '2h 10m', 'goal 90 min', 'sf')]),
        rows([row('BreatheFree home', 'Plan, medicines, progress', lead=L_prog('bf'), action=go('bf_home')), row('ScrollFree home', 'Goal, Pause 60, week', lead=L_prog('sf'), action=go('sf_home'))]),
        card(v='mint', tag='ca', tagx='Learn only', title='How your lungs recover after you quit', text='4 min read', action=go('learn_lesson')),
    ], api=['GET /v1/today'], desc='Composed from every Focus enrolment. If a program safety rule fires, its card is pinned first (see Safety state).')
    S('today_loading', 'Today · loading', '/today?state=loading', 'today', phase='daily', tabname='today', variant_of='today', state='loading', hdr=today_hdr, body=[
        skeleton(1), card(v='coral', title='Craving or urge?', text='One tap · no typing', cta=button('Rescue', sheet('rescue_pick'), v='rescue', small=True)), skeleton(3), skeleton(2),
        text('The rest of Today is still loading.', 'small')])
    S('today_offline', 'Today · offline', '/today?state=offline', 'today', phase='daily', tabname='today', variant_of='today', state='offline', hdr=today_hdr, body=[
        banner('offline', 'Offline · 3 entries will sync when you reconnect.'), title('Good morning, Alex.'),
        card(v='coral', title='Craving or urge?', text='One tap · no typing', cta=button('Rescue', sheet('rescue_pick'), v='rescue', small=True)),
        card(checklist([ci('Stock gum, water or snacks', 'Saved on this phone', True)]), eyebrow='Today'),
        text('Lessons not downloaded load when you’re back online.', 'small')])
    S('today_empty', 'Today · nothing in focus', '/today?state=empty', 'today', phase='daily', tabname='today', variant_of='today', state='empty', hdr=today_hdr, body=[
        title('Good evening, Alex.'), illus('+'), title('Nothing in focus right now', align='center'),
        text('Your programs are paused or in Learn only. Pick one for daily support, or keep exploring.', 'muted', align='center'),
        button('Choose a focus program', go('account_programs')), button('Browse lessons', tab('learn'), v='secondary'),
        card(title='Need help now?', text='Rescue and Support still work', cta=button('Support', tab('support'), v='secondary', small=True))])
    S('today_safety', 'Today · safety pinned', '/today?state=safety', 'today', phase='rescue', tabname='today', variant_of='today', state='safety', hdr=today_hdr, body=[
        banner('urgent', 'Your last blood pressure was in the crisis range.'),
        card(v='urgent', title='Any chest pain, shortness of breath, weakness, vision change or trouble speaking?', text='Heartwise · from your 8:10 AM reading',
             children=[buttons(button('Yes · call 911', call('911'), v='danger', small=True), button('No symptoms', go('hw_recheck'), v='secondary', small=True))]),
        text('Other steps are paused until you answer. Safety always comes first.', 'small'),
        card(checklist([ci('Stock gum, water or snacks'), ci('Charge phone outside the bedroom')]), eyebrow='Today · paused')])

    S('checkin', 'Daily check-in', '/check-in', 'today', phase='daily', kind='sheet', over='Today', body=[
        eyebrow('Shared · asked once'), seg(['Low', 'Not great', 'Okay', 'Good', 'Great'], 'Okay', label='How do you feel today?', key='how_do_you_feel_today'),
        seg(['Low', 'Some', 'High'], 'High', label='Stress today', key='stress_today'),
        card(chips(['No', 'A puff', 'One or more', 'Skip'], ['One or more'], multi=False, key='value'), tag='bf', accent='bf', title='Since your last check-in, did you smoke?', text='Before quit day this is expected, not a setback.'),
        card(chips(['Better', 'Same', 'Drained', 'Skip'], ['Drained'], multi=False, key='value_2'), tag='sf', accent='sf', title='How did you feel after scrolling yesterday?'),
    ], footer=[button('Save check-in', submit('POST /v1/records/check-ins', rep('checkin_done'))), text('Skip any program question', 'small', align='center')], api=['POST /v1/records/check-ins'],
       desc='Each Focus program adds at most 2 questions. Any self-harm signal routes to Crisis.')
    S('checkin_done', 'Check-in saved', '/check-in/done', 'today', phase='daily', hdr=H('Check-in saved', left='close'), body=[
        illus('✓'), title('Thanks, Alex.', 'l', align='center'), text('One small step for each program today.', align='center'),
        card(tag='bf', title='Try a 3-minute stress reset', text='You reported high stress', cta=button('Start', go('rescue_active'), small=True)),
        card(tag='sf', title='Set a 10 PM wind-down', text='You felt drained after scrolling', cta=button('Set it', go('sf_goal'), v='secondary', small=True)),
        text('Recommendations use only today’s answers · v1.0', 'small'),
    ], footer=[button('Back to Today', reset('today'), v='secondary')])

    # ================================================================ RESCUE
    flow('rescue', 'Universal Rescue', 'One entry for every Quit program. Opens the last helpful tool; offers a person when intensity stays high; distress always routes to 988.')
    S('rescue_pick', 'Rescue', '/rescue', 'rescue', phase='rescue', kind='sheet', over='Today', body=[
        eyebrow('Right now'), title('What’s pulling at you?'), text('One tap. No typing.', 'muted'),
        tiles([tl('A cigarette', 'BreatheFree', program='bf', action=rep('rescue_active')), tl('Urge to scroll', 'ScrollFree', program='sf', action=rep('sf_pause')),
               tl('Stress', 'Shared tool', glyph='~', action=rep('rescue_active')), tl('Not sure', 'We’ll suggest one', glyph='?', action=rep('rescue_active'))]),
        card(v='dark', eyebrow='Helped last time · 6 → 3', title='Slow breathing · 2 min', cta=button('Start', rep('rescue_active'), v='lime', small=True)),
        buttons(button('Talk to a person', tab('support'), v='secondary', small=True), button('Emergency', go('crisis'), v='danger', small=True)),
    ], desc='With one Quit program, the app skips this screen and opens the last helpful tool.')
    S('rescue_active', 'Active tool', '/rescue/breathing', 'rescue', phase='rescue', kind='fullscreen', dark=True, hdr=H('Slow breathing', left='close', pill='1:32 left', dark=True), body=[
        eyebrow('Breathe out · slowly'), ring('5'), text('The urge is a wave. Let it rise and pass.', align='center'),
        chips(['Voice on', 'Haptics on', 'Reduced motion'], ['Voice on', 'Haptics on'], key='value'),
        card(v='dark2', title='Still strong?', text='Switch tool or reach a person. This check-in is kept.', children=[buttons(button('Switch tool', sheet('rescue_tools'), v='lime', small=True), button('Get support', go('rescue_escalate'), v='ghostdark', small=True))]),
    ], footer=[button('I’m done', rep('rescue_result'), v='white')], desc='Timer pauses when the app is backgrounded. Reduce Motion → no scaling, countdown only.')
    S('rescue_tools', 'Switch tool', '/rescue/tools', 'rescue', phase='rescue', kind='sheet', over='Slow breathing', body=[
        title('Choose another tool'), radio([ri('Slow breathing', '2 min · voice optional', 'Helped before'), ri('Move for 3 minutes', 'Walk or stretch'), ri('Change the scene', 'Go somewhere smoke-free'), ri('Urge surfing', '3 min audio')], 1, key='value'),
    ], footer=[button('Start this tool', rep('rescue_active')), button('Cancel', close(), v='secondary')])
    S('rescue_result', 'Recheck + result', '/rescue/result', 'rescue', phase='rescue', hdr=H('Rescue done', left='close', pill='Saved'), body=[
        title('This craving eased.'), slider('How strong is it now?', 3, key='how_strong_is_it_now'), stats([st('Before', '8'), st('Now', '3', 'Your rating, not a diagnosis')]),
        chips(['Yes', 'A little', 'Not this time'], ['Yes'], multi=False, label='Did it help?', key='did_it_help'),
        card(v='mint', eyebrow='Next 10 minutes', title='Stay somewhere smoke-free and sip water.'),
        link('Still strong? Get more help', go('rescue_escalate')),
    ], footer=[button('Back to Today', submit('POST /v1/records/rescues', reset('today')))], api=['POST /v1/records/rescues'])
    S('rescue_escalate', 'Add a person', '/rescue/escalate', 'rescue', phase='rescue', hdr=H('Rescue', left='close'), body=[
        title('Let’s add a person.'), text('Strong cravings are common in the first days. You don’t have to ride this one alone.', 'muted'),
        card(v='dark', eyebrow='Free & confidential', title='Quitline counselor', text='1-800-QUIT-NOW · many states 24/7', cta=button('Call', call('1-800-784-8669', 'Call 1-800-QUIT-NOW'), v='lime', small=True)),
        rows([row('Text Jordan', '“Can you stay with me for 10 minutes?”', lead=L_av('J'), action=sheet('support_message'))]),
        emergency(),
    ], footer=[button('Try another tool', sheet('rescue_tools'), v='secondary')])
    S('crisis', 'Crisis support', '/crisis', 'rescue', phase='rescue', kind='fullscreen', hdr=H('You’re not alone', left='close'), body=[
        banner('urgent', 'If you might act on thoughts of harming yourself, get help now.'),
        button('Call 988', call('988'), v='danger', arrow=False), button('Text 988', sms('988'), v='secondary'), button('Call 911', call('911'), v='secondary'),
        card(eyebrow='Your safety plan', title='Things that help: walk the dog, shower, music', text='Reach out: Sam · (555) 010-3311', action=go('ea_plan')),
    ], desc='Global crisis screen used by every program.',
       # P-58: designer note, kept in the spec and not rendered.
       notes=['Shown whenever someone chooses “thoughts of harming myself” or types similar words anywhere. 988 is US-only; localize per region.'])

    # ================================================================ PLANS
    flow('plans', 'Plans & programs', 'My plans hub, program catalog (the 11 programs from tetherhealthgroup.com), focus-slot rules and per-program settings.')
    S('plans', 'My plans', '/plans', 'plans', phase='plan', tabname='plans', hdr=H('My plans', left='none', avatar='A'), body=[
        rows([row('BreatheFree', 'Quit date · Fri, Aug 28', lead=L_prog('bf'), pill='Focus', action=go('bf_home')),
              row('ScrollFree', '90 min/day · bedtime 10 PM–7 AM', lead=L_prog('sf'), pill='Focus', action=go('sf_home'))], title='Focus · 2 of 2'),
        rows([row('ClearAir', 'Learn only · no plan yet', lead=L_prog('ca'), pill='Learn', action=go('ca_intro'))], title='Learn only'),
        rows([row('Medication center', 'BreatheFree · nicotine patch', action=go('bf_meds')), row('Programs & sharing', 'Status, consent, data', action=go('account_programs'))], title='Manage'),
    ], footer=[button('Add a program', go('catalog'), v='secondary')])
    S('catalog', 'Add a program', '/programs', 'plans', phase='welcome', hdr=H('All programs'), body=[
        title('Choose what you want support with.'), text('Mirrors tetherhealthgroup.com. Status shows what’s available today.', 'muted'),
        rows([row(PROGRAMS[p][0], f'{PROGRAMS[p][1]} · {PROGRAMS[p][2]}', lead=L_prog(p), action=go(f'{p}_intro')) for p in ORDER[:6]], title='Quit · Manage'),
        rows([row(PROGRAMS[p][0], f'{PROGRAMS[p][1]} · {PROGRAMS[p][2]}', lead=L_prog(p), action=go(f'{p}_intro')) for p in ORDER[6:]], title='Habits · Support · Prevent'),
    ], desc='Catalog is served by the catalogue service so a program can launch without an app release.')
    S('focus_full', 'Focus slots full', '/programs/focus-full', 'plans', phase='plan', kind='sheet', over='Heartwise', body=[
        eyebrow('Both focus slots are in use'), title('Add Heartwise as…'),
        radio([ri('Learn only for now', 'Lessons, no reminders. Upgrade anytime.', 'Suggested'), ri('Swap with ScrollFree', 'ScrollFree pauses. Its data is kept.'), ri('Swap with BreatheFree', 'Not suggested during your quit week.')], key='option'),
    ], footer=[button('Continue', branch('Chosen option', [('Learn only', toast('Heartwise added as Learn only', tab('plans'))), ('Swap', rep('hw_q1'))], on='radio', key='option')), button('Cancel', close(), v='secondary')])
    S('program_settings', 'Program settings', '/p/:program/settings', 'plans', phase='account', hdr=H('BreatheFree settings'), body=[
        rows([row('BreatheFree', 'Focus since Aug 14', lead=L_prog('bf'))], flat=True),
        radio([ri('Focus', 'Daily steps and reminders'), ri('Learn only', 'Keep lessons, stop tracking'), ri('Pause', 'Stop reminders; keep everything')], 0, label='Status', key='status'),
        card(toggle('Care team · Dr. Patel’s clinic', 'Manual: you approve each summary', True, key='care_team_sharing'), toggle('De-identified research', None, False, key='de_identified_research'), eyebrow='Sharing'),
        rows([row('Export BreatheFree data', 'PDF + JSON', action=toast('Export is being prepared. We’ll notify you.')), row('Leave BreatheFree', 'Keep your data or delete it now', action=sheet('account_leave'), danger=True)], title='Data'),
    ], footer=[button('Save changes', submit('PATCH /v1/enrolments/:id', toast('Saved', back())))], api=['PATCH /v1/enrolments/:id'],
       desc='Parameterized by program. Shown here with BreatheFree data.')

    # ================================================================ PROGRESS / LEARN / SUPPORT
    flow('tabs', 'Progress, Learn & Support', 'Shared tabs that read every enrolment.')
    S('progress', 'Progress', '/progress', 'tabs', phase='resources', tabname='progress', hdr=H('Progress', left='none', avatar='A'), body=[
        seg(['7 days', '30 days', 'All'], '7 days', key='value'), text('Patterns, not grades. Missing check-ins are never counted as zero.', 'small'),
        bars([10, 7, 4, 3, 1, 1, 0], 'bf', title='Cigarettes / day', tag='bf', missing=[3], labels=list('MTWTFSS'), caption='Saved $42.70 · avoided 61', action=go('bf_progress')),
        bars([190, 160, 150, 115, 130, 95, 85], 'sf', title='Social minutes / day', tag='sf', target=90, labels=list('MTWTFSS'), caption='Goal 90 min · reclaimed 5h 40m', action=go('sf_week')),
        card(v='mint', eyebrow='Connection we noticed', title='Late scrolling came before 3 of your 4 strongest cravings.', text='Shown because both programs are yours.', cta=button('Manage', go('account_privacy'), v='secondary', small=True)),
    ], api=['GET /v1/records/summary?range=7d'])
    S('progress_empty', 'Progress · empty', '/progress?state=empty', 'tabs', phase='resources', tabname='progress', variant_of='progress', state='empty', hdr=H('Progress', left='none', avatar='A'), body=[
        illus('0'), title('Your progress shows up here', align='center'), text('After your first check-in or reading, you’ll see patterns for each program.', 'muted', align='center'),
        button('Do a check-in', sheet('checkin'))])
    S('progress_error', 'Progress · error', '/progress?state=error', 'tabs', phase='resources', tabname='progress', variant_of='progress', state='error', hdr=H('Progress', left='none', avatar='A'), body=[
        illus('!', 'error'), title('Something went wrong on our side', align='center'), text('Your data is safe on this phone. Try again in a moment.', 'muted', align='center'),
        button('Try again', rep('progress')), text('Reference 5xx-2F91 · reports never include health data', 'small', align='center')])
    S('learn', 'Learn', '/learn', 'tabs', phase='resources', tabname='learn', hdr=H('Learn', left='none', avatar='A'), body=[
        field('Search', None, placeholder='Search cravings, sleep, blood pressure…', kind='search', key='search'),
        chips(['For you', 'BreatheFree', 'ScrollFree', 'ClearAir'], ['For you'], multi=False, dots={'BreatheFree': 'bf', 'ScrollFree': 'sf', 'ClearAir': 'ca'}, key='value'),
        card(v='dark', tag='bf', tagx='For quit day', title='Cravings: what to expect today', text='4 min read · 3:12 audio · downloaded', action=go('learn_lesson')),
        card(tag='sf', tagx='2 min', title='Why “one more video” never feels like enough', action=go('learn_lesson')),
        card(tag='ca', tagx='Learn only', title='How your lungs recover after you quit', action=go('learn_lesson')),
        text('Clinically reviewed · Library v4.1 · English and Spanish', 'small'),
    ], api=['GET /v1/catalogue/lessons?enrolled=true'])
    S('learn_error', 'Learn · error', '/learn?state=error', 'tabs', phase='resources', tabname='learn', variant_of='learn', state='error', hdr=H('Learn', left='none', avatar='A'), body=[
        illus('!', 'warn'), title('Can’t load lessons', align='center'), text('Check your connection. Downloaded lessons still work.', 'muted', align='center'),
        button('Try again', rep('learn')), button('Open downloads', go('learn_lesson'), v='secondary')])
    S('learn_lesson', 'Lesson', '/learn/:lesson', 'tabs', phase='resources', hdr=H('Lesson', pill='4 min'), body=[
        progtag('bf', 'For quit day'), title('Cravings: what to expect today', 'l'),
        card(v='dark', eyebrow='Audio · 3:12', title='Listen instead', children=[buttons(button('Play', toast('Playing audio'), v='lime', small=True), button('Transcript', toast('Transcript opened'), v='ghostdark', small=True))]),
        text('Most cravings peak and fade within 3–5 minutes. Knowing that makes them easier to ride out. Today, plan what you’ll do in the first 5 minutes of each craving.'),
        quote('This feeling will pass.', 'From your plan'), text('Clinically reviewed · content v3.2 · Aug 2026', 'small'),
    ], footer=[button('Mark complete', submit('POST /v1/records/lessons', toast('Lesson complete', back()))), link('Save for offline', toast('Saved for offline'))])

    S('support', 'Support', '/support', 'tabs', phase='resources', tabname='support', hdr=H('Support', left='none', avatar='A'), body=[
        card(v='dark', eyebrow='Free & confidential · BreatheFree', title='Quitline counselor', text='1-800-QUIT-NOW · Español 1-855-335-3569',
             children=[buttons(button('Call now', call('1-800-784-8669', 'Call 1-800-QUIT-NOW'), v='lime', small=True), button('Request call-back', sheet('support_callback'), v='ghostdark', small=True))]),
        rows([row('Jordan', 'Supporter · BreatheFree only', lead=L_av('J'), action=sheet('support_message')), row('Add a ScrollFree buddy', None, lead=L_icon('+'), action=go('sf_buddy'))], title='Your people'),
        rows([row('Dr. Patel’s clinic', 'Heartwise · ClearAir', lead=L_icon('+'), action=go('support_message_care'))], title='Care team'),
        emergency(),
    ])
    S('support_empty', 'Support · empty', '/support?state=empty', 'tabs', phase='resources', tabname='support', variant_of='support', state='empty', hdr=H('Support', left='none', avatar='A'), body=[
        card(v='dark', eyebrow='Free & confidential', title='Quitline counselor', cta=button('Call', call('1-800-784-8669', 'Call 1-800-QUIT-NOW'), v='lime', small=True)),
        card(eyebrow='Your people', title='No one added yet', text='A friend or family member gets a short help phrase from you, only when you choose to send it.', cta=button('Add', go('support_add_person'), small=True)),
        card(eyebrow='Care team', title='Not connected', text='Connect a clinic to share summaries you approve.', cta=button('Connect', go('support_connect'), v='secondary', small=True)),
        emergency()])
    S('support_callback', 'Request call-back', '/support/callback', 'tabs', phase='resources', kind='sheet', over='Support', body=[
        title('Request a counselor call-back?'), text('Review exactly what will be sent before you agree.', 'muted'),
        kv([('Sent to', 'California Smokers’ Helpline'), ('Shared', 'First name, phone, preferred time'), ('Not shared', 'Your plan, check-ins, health details'), ('Consent expires', '30 days')]),
        field('Best time to call', 'Weekdays after 5 PM', kind='select', key='best_time_to_call'),
    ], footer=[button('Send referral', submit('POST /v1/care/referrals', toast('Request sent. Expect a call within 2 business days.', close()))), button('Cancel', close(), v='secondary')])
    S('support_message', 'Preview message', '/support/message', 'tabs', phase='resources', kind='sheet', over='Support', body=[
        title('Send to Jordan?'), card(v='mint', eyebrow='Preview', title='“Can you stay with me for the next 10 minutes?”', text='Sent from your phone’s Messages app. Tether never sends on its own.'),
    ], footer=[button('Open Messages', sms('Jordan')), button('Cancel', close(), v='secondary')])
    S('support_message_care', 'Message care team', '/support/care-team', 'tabs', phase='resources', hdr=H('Dr. Patel’s clinic'), body=[
        text('Secure message · usually replies within 1 business day. Not for emergencies.', 'small'),
        field('Topic', 'Question about my plan', kind='select', key='topic'), field('Message', 'I’ve been feeling dizzy in the mornings since starting the patch.', kind='multiline', key='message'),
        toggle('Attach a summary', 'You’ll preview it before sending', False, key='attach_a_summary'), emergency('Chest pain, trouble breathing or thoughts of harming yourself? Call 911 · call or text 988.'),
    ], footer=[button('Send message', submit('POST /v1/care/messages', toast('Message sent', back())))])
    S('support_add_person', 'Add a supporter', '/support/people/new', 'tabs', phase='resources', hdr=H('Add a supporter'), body=[
        title('Who can you count on?'), field('Name', 'Jordan', key='name'), field('Phone', '(555) 010-4421', kind='phone', key='phone'),
        chips(['BreatheFree', 'ScrollFree'], ['BreatheFree'], label='Which programs?', key='which_programs'),
        field('Help phrase', 'Can you stay with me for the next 10 minutes?', kind='multiline', key='help_phrase'), text('Nothing is sent until you preview and tap Send.', 'small'),
    ], footer=[button('Save supporter', submit('POST /v1/care/supporters', toast('Jordan added', back())))])
    S('support_connect', 'Connect a clinic', '/support/connect', 'tabs', phase='resources', hdr=H('Connect a clinic'), body=[
        title('Enter your clinic’s invite code'), field('Invite code', 'PATEL-4821', key='invite_code'), text('Your clinic gave you this code. Connecting shares nothing until you approve a summary.', 'muted'),
    ], footer=[button('Connect', submit('POST /v1/care/connections', toast('Connected to Dr. Patel’s clinic', back())))])

    # ================================================================ ACCOUNT
    flow('account', 'Account & data', 'Settings, programs & sharing, notifications, privacy, export, deletion with receipt, sign out.')
    S('account', 'Account', '/account', 'account', phase='account', hdr=H('Account', left='close'), body=[
        rows([row('Alex', 'alex@example.com', lead=L_av('A'))], flat=True),
        rows([row('Health records', '2 sources · Epic, Medicare', action=go('records_hub')), row('Sign-in methods', 'Apple · email', action=go('account_signin_methods'))], title='Your health data'),
        rows([row('Programs & sharing', '2 focus · 1 learn · 1 paused', action=go('account_programs')), row('Notifications', 'On · quiet hours 9 PM–7 AM', action=go('account_notifications')),
              row('Privacy & consent', 'Reviewed Aug 22, 2026', action=go('account_privacy')), row('Your data', 'Export or delete', action=go('account_data'))], title='Settings'),
        rows([row('Text size & contrast', 'Follows your phone', action=settings()), row('Language', 'English', action=toast('Language set to English')), row('Help & legal', None, action=ext('https://www.tetherhealthgroup.com/support/'))], title='App'),
        text('Tether Health 1.0.0 (100)', 'small', align='center'),
    ], footer=[button('Sign out', sheet('account_signout'), v='secondary')])
    S('account_signin_methods', 'Sign-in methods', '/account/sign-in', 'account', phase='account', hdr=H('Sign-in methods'), body=[
        text('Use any connected method to sign in. Keep at least one.', 'muted'),
        rows([row('Apple', 'Connected · Hide My Email', lead=L_icon(''), pill='Primary'),
              row('Google', 'Not connected', lead=L_icon('G'), action=auth('google', [('Success', toast('Google connected')), ('Email already has a Tether account', go('auth_link')), ('Cancelled', toast('Cancelled')), ('Error', go('auth_social_error'))])),
              row('Email & password', 'alex@example.com · set a password', lead=L_icon('@'), action=go('auth_newpass'))]),
        card(v='mint', text='To remove Apple, add another method first. Removing a method never deletes your data.'),
    ], desc='iPhone shows Apple first (App Store rule 4.8 when Google is offered); Android shows Google.')
    S('account_programs', 'Programs & sharing', '/account/programs', 'account', phase='account', hdr=H('Programs & sharing'), body=[
        text('2 of 2 focus slots used', 'small'),
        rows([row('BreatheFree', 'Focus · sharing manual', lead=L_prog('bf'), action=go('program_settings')), row('ScrollFree', 'Focus · not shared', lead=L_prog('sf'), action=go('program_settings')),
              row('ClearAir', 'Learn only · no data', lead=L_prog('ca'), action=go('program_settings')), row('Heartwise', 'Paused Sep 2 · data kept', lead=L_prog('hw'), action=go('program_settings'))]),
    ], footer=[button('Add a program', go('catalog'), v='secondary')])
    S('account_leave', 'Leave a program', '/account/programs/leave', 'account', phase='account', kind='sheet', over='Programs & sharing', body=[
        title('Leave BreatheFree?'), text('Reminders stop right away. Your other programs are not affected.', 'muted'),
        radio([ri('Keep my data', 'Kept until you delete it or delete your account. Rejoin anytime.', 'Default'), ri('Delete BreatheFree data now', '63 check-ins, 14 rescues, 1 plan')], key='value'),
    ], footer=[button('Leave BreatheFree', submit('DELETE /v1/enrolments/:id', toast('You left BreatheFree', reset('plans'))), v='danger'), button('Cancel', close(), v='secondary')])
    S('account_notifications', 'Notifications', '/account/notifications', 'account', phase='account', hdr=H('Notifications'), body=[
        card(toggle('Check-ins and plan reminders', 'At most 2 a day', True, key='check_ins_and_plan_reminders'), toggle('Show sensitive details', 'Off: program names and health data hidden', False, key='show_sensitive_details'), toggle('Quiet hours', '9:00 PM – 7:00 AM · safety alerts still come through', True, key='quiet_hours')),
        rows([row('BreatheFree', '8:00 AM check-in', lead=L_prog('bf'), action=toast('Reminder time saved')), row('ScrollFree', '9:30 PM wind-down', lead=L_prog('sf'), action=toast('Reminder time saved'))], title='Per program'),
        card(eyebrow='Lock screen preview', title='Tether Health', text='You have a Tether reminder.'),
    ], footer=[button('Save', submit('PATCH /v1/notifications/preferences', toast('Saved', back())))])
    S('account_privacy', 'Privacy & consent', '/account/privacy', 'account', phase='account', hdr=H('Privacy & consent'), body=[
        card(toggle('Cross-program insights', 'Show connections between your programs', True, key='cross_program_insights'), toggle('De-identified research', 'Per program, off by default', False, key='de_identified_research'), toggle('Anonymous app diagnostics', 'No health entries', False, key='anonymous_app_diagnostics'), eyebrow='Choices'),
        rows([row('Care-team sharing', 'Manual only · preview every share', action=go('account_programs')), row('Consent history', 'v3 · Aug 22, 2026', action=toast('Consent history opened')), row('Privacy Notice', None, action=ext('https://www.tetherhealthgroup.com/privacy/'))]),
        text('No ads. We never sell your health data.', 'small'),
    ], footer=[button('Save', submit('PATCH /v1/enrolments/consents', toast('Saved', back())))])
    S('account_data', 'Your data', '/account/data', 'account', phase='account', hdr=H('Your data'), body=[
        rows([row('Download everything', 'Every program · PDF + JSON', action=submit('POST /v1/account/export', toast('We’re preparing your file. We’ll notify you when it’s ready.'))),
              row('Export a care summary', 'Choose dates and preview every detail', action=go('hw_summary'))], title='Export'),
        rows([row('Delete account and all data', 'Permanent · requires confirmation', action=go('account_delete'), danger=True)], title='Delete'),
    ])
    S('account_delete', 'Delete account', '/account/delete', 'account', phase='account', hdr=H('Delete account'), body=[
        title('Delete your account and all data?'),
        kv([('Programs', '4'), ('Check-ins', '63'), ('Readings & logs', '118'), ('Shared with care team', '3 summaries (their copies stay with them)')]),
        text('This can’t be undone. Download a copy first if you want one.', 'small'), button('Download a copy first', go('account_data'), v='secondary'),
        field('Type DELETE to confirm', 'DELETE', key='type_delete_to_confirm'), field('Password', '••••••••••••', hint='We ask again to protect your account.', kind='password', key='password'),
    ], footer=[button('Delete everything', submit('DELETE /v1/account/data', rep('account_deleted')), v='danger')], api=['DELETE /v1/account/data'],
       desc='Encrypted deletion-intent tombstone is written before the request (develop branch design).')
    S('account_deleted', 'Deletion receipt', '/account/deleted', 'account', phase='account', hdr=H('Deleted', left='none'), body=[
        illus('✓'), title('Your data has been deleted.', 'l', align='center'),
        kv([('Receipt', 'DEL-7F3A-21C9'), ('Completed', 'Oct 17, 2026 · 9:41 AM'), ('Signed out on', 'this phone')]),
        text('Keep this receipt if you contact support. Backups are purged within 30 days.', 'small'),
    ], footer=[button('Done', reset('welcome'))])
    S('account_signout', 'Sign out', '/account/signout', 'account', phase='account', kind='sheet', over='Account', body=[
        title('Sign out of Tether?'), text('Encrypted program data on this phone is removed. Your account data stays safe in the cloud.', 'muted'),
    ], footer=[button('Sign out', reset('welcome'), v='danger'), button('Cancel', close(), v='secondary')])

    # ================================================================ SYSTEM
    flow('system', 'System states', 'App-wide events: forced update.')
    S('sys_update', 'Update required', '/system/update', 'system', phase='account', kind='fullscreen', hdr=H('Update needed', left='none'), body=[
        illus('↑', 'warn'), title('A safety update is ready', 'l', align='center'), text('This version has important fixes. Rescue and Support still work until you update.', 'muted', align='center'),
    ], footer=[button('Update now', ext('https://apps.apple.com/app/tether-health')), button('Open Rescue', sheet('rescue_pick'), v='rescue', arrow=False)])

    entry('welcome', 'First launch')
    entry('today', 'Returning launch')
    entry('checkin', 'Notification: daily check-in')
    entry('rescue_pick', 'Home-screen widget / Siri: Rescue')
    entry('auth_newpass', 'Deep link: password reset email')
    entry('auth_session', 'Event: session expired')
    entry('sys_update', 'Event: minimum version above installed')
    entry('today_safety', 'Event: program safety rule fired')
