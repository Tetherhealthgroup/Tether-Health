"""Spec additions proposed for owner review.

Everything here is a *proposal*. Nothing in this file changes an existing
screen: new screens are added, and changes to an existing screen are shown as
new state variants of it (``variant_of=``), so the approved screens render
exactly as before and the owner can compare current and proposed side by side.
Traceability (which decision each screen serves) is in the review notes in this folder.

What is covered:

- Unplug, the optional app-limit layer of ScrollFree: flow ``unplug`` plus
  ScrollFree variants (home, week, settings, Screen Time wording). Source:
  ``pigeons/unplug_api.dart`` and ``lib/unplug/**`` on
  ``origin/feat/unplug-v2.1-module`` (4b0d394), restyled to tether_ui
  components. Adds the ``nativeslot`` node (TNativeSlot) for native views
  Flutter cannot draw, such as the iOS DeviceActivityReport minutes view.
- Missing variants: social-account versions of ``account_delete`` and
  ``auth_session``, Android versions of ``sf_screentime`` (+ denied) and
  ``sys_update`` (Play Store URL).
- Entry surfaces outside the app: flow ``entries`` with the home-screen
  widget, Siri / App Shortcuts and Android launcher shortcuts for the entries
  the spec already names (``rescue_pick``, ``ca_red``), generic labels by
  default.

Safety rules every Unplug surface follows:
- Every pause surface (iPhone shield, Android overlay, small step) has a
  route to Rescue, and Rescue reaches Emergency (988 / 911).
- Tether itself, the phone dialer and emergency calling can never be chosen
  or paused.

All new copy needs clinical/legal review before it ships; every screen below
says so in its description and notes.
"""
import copy
from dsl import *
from rules import RULES, SCENARIOS, sc

H = header

REVIEW = 'Proposal for owner review. Copy needs clinical/legal review.'
NEVER_PAUSED = 'Tether, the phone dialer and emergency calling can never be chosen or paused.'
NATIVE_NEVER_PAUSED = ('Native requirement (iOS shield and app selection, Android overlay, picker and service): never shield or pause Tether, '
                       'the phone dialer or emergency calling, even if they are selected or a session pauses "everything". Needs device validation.')
SUPPORT_NOTIFICATION = ('A shield button cannot open Tether directly. Proposal: it posts a local notification; tapping it opens Tether. '
                        'Needs device validation.')


def nativeslot(id, label, caption=None, platform='ios', height=120):
    """A native platform view the Flutter UI cannot draw (TNativeSlot).

    In the app, a builder registered for ``id`` draws the real platform view;
    in the prototype, tests and on other platforms a labelled placeholder of
    the same size is shown instead.
    """
    return N('nativeslot', id=id, label=label, caption=caption, platform=platform, height=height)


def P(id, name, route, fl, body, source=None, native=None, desc='', **kw):
    """S() for a proposed screen: tags the description and notes for review."""
    notes = [REVIEW] + (['Source: ' + source] if source else []) + ([native] if native else [])
    return S(id, name, route, fl, body, desc=(REVIEW + ' ' + desc).strip(), notes=notes, **kw)


def _body_of(sid):
    return copy.deepcopy(SCREENS[sid]['body'])


def support_card():
    return card(v='coral', title='Need help right now?', text='Rescue opens in one tap.',
                cta=button('Get support', sheet('rescue_pick'), v='rescue', small=True))


def additions():
    rules_and_scenarios()
    unplug()
    p36_gaps()
    entry_surfaces()


# ================================================================ RULES + SCENARIOS
# Decision rules for the Unplug gates. Registered into the shared RULES table so
# they are exported to spec/rules.json; the same logic is implemented in
# dart_static/lib/logic/rules.dart and in the prototype (proto_v2.py).
UNPLUG_RULES = {
    'sf.unplug.reason': {
        'title': 'Strict session: reason before ending early',
        'program': 'sf',
        'inputs': ['sf_unplug_session_end.reason', 'sf_unplug_session_end.note'],
        'params': {},
        'outcomes': {'given': 'Reason given', 'missing': 'No reason yet'},
        'logic': 'A strict session ends early only when a reason chip is selected or a note is typed.',
        'source': 'endSession(overrideReason) in pigeons/unplug_api.dart. Product rule, not clinical.',
    },
    'sf.unplug.sentence': {
        'title': 'Small step: typed sentence',
        'program': 'sf',
        'inputs': ['sf_unplug_gate_commit.sentence'],
        'params': {'sentence': 'I can come back to this later'},
        'outcomes': {'done': 'Step done', 'not_done': 'Step not done'},
        'logic': 'Done when the typed text equals the sentence, ignoring case, extra spaces and a final full stop.',
        'source': 'PlatformEffortGate.commitment. Product rule, not clinical.',
    },
    'sf.unplug.sum': {
        'title': 'Small step: quick sum',
        'program': 'sf',
        'inputs': ['sf_unplug_gate_sum.answer'],
        'params': {'a': 7, 'b': 5},
        'outcomes': {'done': 'Step done', 'not_done': 'Step not done'},
        'logic': 'Done when the answer equals a + b.',
        'source': 'PlatformEffortGate.puzzle. Product rule, not clinical.',
    },
}

UNPLUG_SCENARIOS = [
    sc('sf_unplug_strict_end', 'sf', 'Unplug', 'Strict session needs a reason to end early', 'sf_unplug_session_active',
       [('tap', 'End early'), ('expect', 'sf_unplug_session_end'), ('tap', 'End session'), ('expect', 'sf_unplug_session_end'),
        ('tap', 'Expecting a message'), ('tap', 'End session')], 'sf_unplug_session_done_early'),
    sc('sf_unplug_gate_sum', 'sf', 'Unplug', 'Quick sum must be right before the app opens', 'sf_unplug_gate_sum',
       [('tap', 'Open it for 10 minutes'), ('expect', 'sf_unplug_gate_sum'), ('enter', 'sf_unplug_gate_sum.answer', '9'),
        ('tap', 'Open it for 10 minutes'), ('expect', 'sf_unplug_gate_sum'), ('enter', 'sf_unplug_gate_sum.answer', '12'),
        ('tap', 'Open it for 10 minutes')], 'sf_home'),
    sc('sf_unplug_gate_sentence', 'sf', 'Unplug', 'Sentence must be typed in full before the app opens', 'sf_unplug_gate_commit',
       [('tap', 'Open it for 10 minutes'), ('expect', 'sf_unplug_gate_commit'), ('enter', 'sf_unplug_gate_commit.sentence', 'I can come back'),
        ('tap', 'Open it for 10 minutes'), ('expect', 'sf_unplug_gate_commit'), ('enter', 'sf_unplug_gate_commit.sentence', 'i can come back to this later.'),
        ('tap', 'Open it for 10 minutes')], 'sf_home'),
    sc('sf_unplug_overlay_support', 'sf', 'Unplug', 'Android pause screen reaches Rescue and Emergency', 'sf_unplug_overlay',
       [('tap', 'Get support'), ('expect', 'rescue_pick'), ('tap', 'Emergency')], 'crisis'),
    sc('sf_unplug_shield_support', 'sf', 'Unplug', 'iPhone shield reaches Rescue without the small step', 'sf_unplug_shield',
       [('choose', 'Get support'), ('tap', 'Take a breath')], 'rescue_pick'),
    sc('sf_unplug_shield_firm_support', 'sf', 'Unplug', 'Firm iPhone shield reaches Rescue', 'sf_unplug_shield_firm',
       [('tap', 'Get support')], 'rescue_pick'),
]


def rules_and_scenarios():
    RULES.update(UNPLUG_RULES)
    SCENARIOS.extend(UNPLUG_SCENARIOS)


# ================================================================ UNPLUG
def unplug():
    flow('unplug', 'ScrollFree · Unplug (proposal)',
         'Optional app limits for ScrollFree: what Unplug can see, Screen Time / Android permissions, choosing apps, limits and the pause screen, '
         'focus sessions, the iPhone shield and Android overlay, the small-step gate, tracking check and turning it off. Proposal for owner review. '
         'Every pause surface reaches Rescue. Related states elsewhere: ScrollFree home (Unplug offer, Unplug on), Weekly reflection (Unplug on), '
         'Program settings (ScrollFree with Unplug), Connect Screen Time (Android, iPhone report wording).', 'sf')
    src = 'pigeons/unplug_api.dart @ origin/feat/unplug-v2.1-module'

    # ---- intro, authorization, app selection, limits
    P('sf_unplug_intro', 'Unplug intro', '/p/sf/unplug', 'unplug', program='sf', phase='plan', hdr=H('Unplug', pill='Optional'), body=[
        progtag('sf', 'Unplug'), title('Pause the apps you choose, when you choose.', 'l'),
        text('Unplug is optional. It adds a pause screen to apps you pick, after limits you set. Pause 60 stays the same: a moment to check in, never a lock.', 'muted'),
        kv([('Can', 'Pause apps you pick, after your limits'), ('Can’t', 'See what you do inside any app'),
            ('On iPhone', 'Apple doesn’t share app names or minutes with Tether'), ('Stays', 'On this phone. Your app list never reaches Tether'),
            ('Never paused', 'Tether, phone calls and emergency calls')]),
    ], footer=[
        button('Set up Unplug', branch('Platform', [('iPhone', go('sf_unplug_auth')), ('Android', go('sf_unplug_auth_android'))])),
        button('Not now', back(), v='secondary'),
    ], source='lib/unplug/screens/unplug_screen_a.dart, lib/unplug/models/platform_ceiling.dart',
       desc='Shown before anything is switched on, so nobody later reads a number that does not exist. Keeps Pause 60 an intent check and names Unplug as the optional lock.')

    P('sf_unplug_auth', 'Allow Screen Time', '/p/sf/unplug/permission', 'unplug', program='sf', phase='plan', hdr=H('Unplug', pill='Step 1 of 3'), body=[
        illus('◷'), title('Allow Screen Time for Unplug', align='center'),
        text('Apple will ask you to let Tether Health use Screen Time. This lets Unplug pause apps. It doesn’t let Tether see what you do in them.', 'muted', align='center'),
        kv([('Lets Unplug', 'Pause apps you choose'), ('Never shares', 'App names, content, messages'), ('Turn off', 'Anytime in Account → ScrollFree')]),
    ], footer=[
        button('Continue', branch('Screen Time authorization (iOS Family Controls, individual)',
                                  [('Approved', rep('sf_unplug_apps')), ('Denied', rep('sf_unplug_auth_denied')), ('Unavailable', rep('sf_unplug_auth_unavailable'))])),
        button('Not now', back(), v='secondary'),
    ], source=src + ' requestAuthorization(individual), PlatformAuthorizationStatus',
       desc='iPhone. Continue calls requestAuthorization(individual); Apple shows its own prompt. approved → choose apps, denied → denied state, unavailable → unavailable state.')
    P('sf_unplug_auth_denied', 'Screen Time not allowed', '/p/sf/unplug/permission?state=denied', 'unplug', program='sf', phase='plan',
      variant_of='sf_unplug_auth', state='permission denied', hdr=H('Unplug', pill='Step 1 of 3'), body=[
        banner('info', 'Screen Time access was not allowed.'), title('Unplug needs Screen Time to pause apps.'),
        text('Everything else in ScrollFree works without it: your goal, Pause 60 and check-ins.', 'muted'),
    ], footer=[
        button('Try again', branch('Screen Time authorization (iOS Family Controls, individual)',
                                   [('Approved', rep('sf_unplug_apps')), ('Denied', toast('Still not allowed. You can turn it on later in Settings.'))])),
        button('Open phone settings', settings(), v='secondary'), link('Not now', back()),
    ], source=src + ' PlatformAuthorizationStatus.denied')
    P('sf_unplug_auth_unavailable', 'Screen Time unavailable', '/p/sf/unplug/permission?state=unavailable', 'unplug', program='sf', phase='plan',
      variant_of='sf_unplug_auth', state='unavailable', hdr=H('Unplug', pill='Optional'), body=[
        banner('info', 'Screen Time isn’t available on this phone.'), title('Unplug can’t run here.'),
        text('This can happen when Screen Time is managed by an organization or limited by a parent. ScrollFree still works without Unplug.', 'muted'),
    ], footer=[button('Back to ScrollFree', back())], source=src + ' PlatformAuthorizationStatus.unavailable')
    P('sf_unplug_auth_android', 'Android permissions for Unplug', '/p/sf/unplug/permission?state=android', 'unplug', program='sf', phase='plan',
      variant_of='sf_unplug_auth', state='android', hdr=H('Unplug', pill='Step 1 of 3'), body=[
        title('Two Android settings for Unplug'),
        text('Android asks for each one separately. You can turn either off later, and Unplug will tell you if it stops working.', 'muted'),
        checklist([ci('Usage access', 'On · lets Unplug see which app is open and for how long', True),
                   ci('Display over other apps', 'Off · lets Unplug show the pause screen'),
                   ci('Notifications', 'Android shows a quiet “Tether is running” notice while Unplug is on')], label='Needed'),
    ], footer=[
        button('Turn on display over apps', settings()),
        button('Turn on usage access', settings(), v='secondary'),
        link('I’ve turned them on', branch('Android permissions (checked on return)', [('All on', rep('sf_unplug_apps_android')), ('Missing', toast('Unplug still needs both settings.'))])),
    ], source='android/.../unplug/UnplugHost.kt (PACKAGE_USAGE_STATS, SYSTEM_ALERT_WINDOW, foreground service)',
       desc='Android has no single prompt: usage access and the overlay permission are separate settings pages, checked again when the person returns (authorizationStatus on resume). The foreground service needs a visible notification; its text is generic.')

    P('sf_unplug_apps', 'Choose apps', '/p/sf/unplug/apps', 'unplug', program='sf', phase='plan', hdr=H('Choose apps', pill='Step 2 of 3'), body=[
        title('Which apps should Unplug pause?'),
        text('Apple’s app picker opens next. Tether never sees which apps you pick: Apple keeps that choice on this phone.', 'muted'),
        card(v='mint', title='Start small', text='One or two apps that pull you in most is a good start. You can change this anytime.'),
        text(NEVER_PAUSED, 'small'),
    ], footer=[button('Open app picker', sheet('sf_unplug_picker_ios')), button('Not now', back(), v='secondary')],
       source=src + ' presentAppPicker()', native=NATIVE_NEVER_PAUSED,
       desc='iPhone host screen around Apple’s FamilyActivityPicker. presentAppPicker returns only a count; app identities stay as device-local tokens.')
    P('sf_unplug_picker_ios', 'Apple app picker', '/p/sf/unplug/apps/picker', 'unplug', program='sf', phase='plan', kind='sheet', over='Choose apps', body=[
        nativeslot('ios.familyActivityPicker', 'Apple’s app picker', 'System sheet drawn by iOS (FamilyActivityPicker). Tether can’t style it or read the app names.', 'ios', 320),
    ], footer=[
        button('Done', branch('System app picker result', [('Apps chosen', rep('sf_unplug_apps_chosen')), ('Cancelled', close())])),
        button('Cancel', close(), v='secondary'),
    ], source=src + ' presentAppPicker()', native=NATIVE_NEVER_PAUSED,
       desc='Placeholder for the system picker. In the app this sheet is Apple’s; the buttons stand for the picker’s own Done / Cancel.')
    P('sf_unplug_apps_android', 'Choose apps (Android)', '/p/sf/unplug/apps?state=android', 'unplug', program='sf', phase='plan',
      variant_of='sf_unplug_apps', state='android', hdr=H('Choose apps', pill='Step 2 of 3'), body=[
        title('Choose the apps to pause'), text('This choice stays on this phone. Tether never receives it.', 'muted'),
        checklist([ci('Short-video app', done=True), ci('Photo feed app', done=True), ci('Video app', done=True), ci('News app'), ci('Games app'), ci('Shopping app')], label='Apps on this phone'),
        text('Tether, the Phone app and emergency calling aren’t in this list. They can never be paused.', 'small'),
    ], footer=[button('Done · 3 apps', rep('sf_unplug_apps_chosen')), link('Cancel', back())],
       source='android/.../unplug/AppPickerActivity.kt', native=NATIVE_NEVER_PAUSED + ' On Android the picker leaves them out of the list.',
       desc='Android draws its own picker (AppPickerActivity, native layout must match this screen). App names shown here are generic examples; the real list is the phone’s launchable apps.')
    P('sf_unplug_apps_chosen', 'Name your groups', '/p/sf/unplug/apps?state=chosen', 'unplug', program='sf', phase='plan',
      variant_of='sf_unplug_apps', state='apps chosen', hdr=H('Choose apps', pill='Step 2 of 3'), body=[
        title('Name your groups'),
        text('iPhone doesn’t tell Tether the app names, so give each group a name you’ll recognize. Group names stay on this phone.', 'muted'),
        rows([row('Video apps', '3 apps'), row('Feeds', '2 apps')], title='Your groups'),
        field('New group name', placeholder='e.g. Games', key='group_name'),
        button('Add another group', sheet('sf_unplug_picker_ios'), v='secondary', small=True),
    ], footer=[button('Next: limits', go('sf_unplug_limits'))],
       source=src + ' PlatformAppSelection(groupLabels, groupAppCounts, totalApps)',
       desc='PlatformAppSelection carries only the person’s group labels and counts. Proposal: group names are device-only (not synced).')

    P('sf_unplug_limits', 'Limits & pause screen', '/p/sf/unplug/limits', 'unplug', program='sf', phase='plan', hdr=H('Limits', pill='Step 3 of 3'), body=[
        title('When should Unplug step in?'),
        card(slider('Daily time in these apps', 60, 15, 240, '15 min', '4 h', 'sf', ' min', key='daily_minutes'),
             slider('Opens a day', 20, 5, 60, '5', '60', 'sf', key='daily_opens'),
             text('On iPhone, opens are counted from pause screens shown, so the number is approximate.', 'small')),
        radio([ri('Notice only', 'Count time, no pause screen'), ri('Pause screen', 'A pause before the app opens'),
               ri('Pause and one small step', 'A breath, a typed sentence or a quick sum first', 'Suggested'), ri('Firm', 'No “open anyway” until tomorrow')],
              2, label='When you reach a limit', key='level'),
        chips(['One breath', 'Type a sentence', 'Quick sum'], ['One breath'], multi=False, label='Small step', key='gate'),
        seg(['0', '1', '3', '5'], '3', label='“Open anyway” per day', key='overrides'),
        text('Stricter limits apply now. Looser limits start tomorrow, so one hard moment doesn’t change your plan.', 'small'),
        text('Every pause screen has a Get support button. ' + NEVER_PAUSED, 'small'),
    ], footer=[button('Save limits', submit('CALL device:unplug/setThresholds+applyShield', toast('Unplug is on', rep('sf_unplug_home'))))],
       source=src + ' PlatformThresholds(minutes, opens), PlatformModuleConfig(tier, overrideAllowance, gate none|breath|commitment|puzzle, strict); lib/unplug/screens/unplug_screen_f.dart (tier, cool-off)',
       native=NATIVE_NEVER_PAUSED,
       desc='Levels map to PlatformModuleConfig.tier (Notice 1, Pause 2, Pause + step 3, Firm 5 = no overrides). Small step maps to gate breath | commitment | puzzle. Device-only: nothing here is sent to Tether. The loosening delay comes from the feat branch tier model and is a proposal.')

    # ---- Unplug settings home
    P('sf_unplug_home', 'Unplug', '/p/sf/unplug/home', 'unplug', program='sf', phase='daily', hdr=H('Unplug', pill='On'), body=[
        card(v='mint', title='Unplug is on', text='5 apps in 2 groups · pause screen after 60 min or 20 opens'),
        card(v='dark', eyebrow='Focus session', title='Need to focus?', text='Pause your chosen apps for a set time', cta=button('Start', go('sf_unplug_session'), v='lime', small=True)),
        rows([row('Apps', 'Video apps · 3, Feeds · 2', action=go('sf_unplug_apps_chosen')),
              row('Limits & pause screen', '60 min · 20 opens · one breath first', action=go('sf_unplug_limits')),
              row('Preview the pause screen', 'iPhone shield or Android overlay', action=branch('Platform', [('iPhone', go('sf_unplug_shield')), ('Android', go('sf_unplug_overlay'))])),
              row('Tracking check', 'All checks pass', action=go('sf_unplug_health'))], title='Settings'),
        rows([row('How Unplug works', 'What it can and can’t see', action=go('sf_unplug_intro')),
              row('Turn off Unplug', 'Paused apps open normally again', action=sheet('sf_unplug_off'), danger=True)]),
    ], source=src,
       desc='Reached from ScrollFree home (state "Unplug on") and ScrollFree settings. Everything shown is read from this phone.')

    # ---- sessions
    P('sf_unplug_session', 'Start a focus session', '/p/sf/unplug/session', 'unplug', program='sf', phase='rescue', hdr=H('Focus session'), body=[
        title('Pause your apps for a while.'),
        chips(['25 min', '45 min', '60 min', '90 min'], ['45 min'], multi=False, label='How long', key='duration'),
        radio([ri('Only my chosen apps', 'Video apps, Feeds'), ri('Everything except apps I allow', 'Tether, phone calls and emergency calls always stay open')], 0, label='What to pause', key='scope'),
        card(toggle('Strict', 'Ending early asks for a reason, kept on this phone', False, key='strict')),
    ], footer=[button('Start session', submit('CALL device:unplug/startSession', rep('sf_unplug_session_active')))],
       source=src + ' startSession(durationSeconds, PlatformShieldScope selectedApps|everythingExceptAllowlist, strict)', native=NATIVE_NEVER_PAUSED,
       desc='Device-only. Tether (and so Rescue and 988), the phone dialer and emergency calling are never paused.')
    P('sf_unplug_session_active', 'Focus session running', '/p/sf/unplug/session/active', 'unplug', program='sf', phase='rescue', kind='fullscreen',
      hdr=H('Focus session', left='close', pill='Strict'), body=[
        timer('32:18', 'left of 45 min · until 3:45 PM'),
        text('Video apps and Feeds are paused. Tether, phone calls and emergency calls stay open.', align='center'),
        card(v='coral', title='Urge to check?', text='Take 60 seconds first', cta=button('Pause 60', go('sf_pause'), v='rescue', small=True)),
    ], footer=[button('End early', sheet('sf_unplug_session_end'), v='secondary')],
       source='lib/unplug/screens/unplug_screen_g.dart',
       desc='Close leaves the session running. The session ends by itself at the end time (see Session complete).')
    P('sf_unplug_session_end', 'End session early', '/p/sf/unplug/session/end', 'unplug', program='sf', phase='rescue', kind='sheet', over='Focus session', body=[
        title('End your session early?'),
        text('This is a strict session. Choose or type a reason; it is kept with the session on this phone. Nothing resets.', 'muted'),
        chips(['Need an app for work', 'Expecting a message', 'Changed my mind', 'Other'], [], multi=False, label='Reason', key='reason'),
        field('Anything to add?', placeholder='Optional', kind='multiline', key='note'),
    ], footer=[
        button('End session', branch('Strict session: reason given?', [('Reason given', submit('CALL device:unplug/endSession', rep('sf_unplug_session_done_early'))),
                                                                       ('No reason yet', toast('Choose or type a reason to end a strict session.'))],
                                     decide='sf.unplug.reason'), v='danger'),
        button('Keep going', close(), v='secondary'),
    ], source=src + ' endSession(overrideReason)', desc='End session works only after a reason is chosen or typed (rule sf.unplug.reason).')
    P('sf_unplug_session_done', 'Session complete', '/p/sf/unplug/session/done', 'unplug', program='sf', phase='milestone', hdr=H('Focus session', left='none'), body=[
        illus('✓'), big('45', 'min', 'Session complete · your apps are open again'),
        text('Want to make this a habit? You can start one from ScrollFree anytime.', 'muted', align='center'),
    ], footer=[button('Done', rep('sf_unplug_home'))], source=src + ' endSession()',
       desc='Opened from the session-finished notification (generic text) or when the timer ends in the app.')
    P('sf_unplug_session_done_early', 'Session ended early', '/p/sf/unplug/session/done?state=early', 'unplug', program='sf', phase='milestone',
      variant_of='sf_unplug_session_done', state='ended early', hdr=H('Focus session', left='none'), body=[
        big('18', 'min', 'Ended early · your apps are open again'),
        kv([('Reason', 'Expecting a message'), ('Kept', 'On this phone only')]),
        text('Nothing resets. 18 focused minutes still count.', 'muted'),
    ], footer=[button('Done', rep('sf_unplug_home'))], source=src + ' endSession(overrideReason)')

    # ---- iOS shield (ShieldConfiguration: icon, title, subtitle, primary, secondary only)
    shield_desc = ('iPhone system shield (ShieldConfiguration extension). Apple allows only an icon (here the Tether app icon), a title, a subtitle and two buttons, '
                   'so this screen uses nothing else. Colors and text come from the shared intercept tokens. Not an app route: reference for the native shield.')
    P('sf_unplug_shield', 'Pause screen (iPhone shield)', '/system/unplug/shield', 'unplug', program='sf', phase='rescue', kind='fullscreen', dark=True, body=[
        spacer(60), illus('T', 'dark'), title('Paused for a moment', 'l', align='center'),
        text('You asked to slow this one down. Video apps is on your list. 2 of 3 “open anyway” left today.', align='center'),
    ], footer=[
        button('Take a breath', toast('Notification: open Tether to take your breath, or get support',
                                      branch('Notification action', [('Take my breath', go('sf_unplug_gate')), ('Get support', sheet('rescue_pick'))])),
               v='lime', arrow=False),
        link('Open anyway', toast('Opened · 1 “open anyway” left today', close())),
    ], source='ios/UnplugShield/UnplugShieldConfigurationExtension.swift, ios/UnplugShieldAction/UnplugShieldActionExtension.swift, assets/unplug/intercept_tokens.json',
       native=SUPPORT_NOTIFICATION + ' The notification has two actions: Take my breath (opens the small step) and Get support (opens Rescue directly, without the small step). ' + NATIVE_NEVER_PAUSED,
       desc=shield_desc + ' Take a breath posts a local notification with two actions: Take my breath and Get support (opens Rescue without the small step). Needs device validation.')
    P('sf_unplug_shield_firm', 'Pause screen (iPhone shield, firm)', '/system/unplug/shield?state=firm', 'unplug', program='sf', phase='rescue', kind='fullscreen', dark=True,
      variant_of='sf_unplug_shield', state='no “open anyway” left', body=[
        spacer(60), illus('T', 'dark'), title('Paused for a moment', 'l', align='center'),
        text('You asked to slow this one down. Video apps is on your list. No “open anyway” left today.', align='center'),
    ], footer=[
        button('Close the app', toast('The app stays closed.', close()), v='lime', arrow=False),
        link('Get support', toast('Notification: tap to open Rescue in Tether', sheet('rescue_pick'))),
    ], source='ios/UnplugShield/UnplugShieldConfigurationExtension.swift',
       native=SUPPORT_NOTIFICATION + ' The second shield button is always Get support when no “open anyway” is left. ' + NATIVE_NEVER_PAUSED,
       desc=shield_desc + ' The second button is Get support: it posts a local notification that opens Rescue. Needs device validation.')

    # ---- Android overlay
    P('sf_unplug_overlay', 'Pause screen (Android overlay)', '/system/unplug/overlay', 'unplug', program='sf', phase='rescue', kind='fullscreen', dark=True, body=[
        spacer(24), title('Paused for a moment', 'l', align='center'),
        text('You asked to slow this one down. Video apps is on your list.', align='center'),
        ring('30', palette='teal'), text('Breathe with the circle. 2 of 3 “open anyway” left today.', 'small', align='center'),
    ], footer=[
        button('Close the app', toast('The app stays closed.', close()), v='lime', arrow=False),
        button('Get support', sheet('rescue_pick'), v='rescue', arrow=False),
        link('Open anyway', toast('Opened · 1 “open anyway” left today', close())),
    ], source='android/.../unplug/InterceptOverlay.kt, assets/unplug/intercept_tokens.json',
       native='Native requirement: Get support opens Tether at Rescue and is always shown, whatever the level or overrides left. ' + NATIVE_NEVER_PAUSED,
       desc='Drawn over the opened app by the foreground service (SYSTEM_ALERT_WINDOW), 0.5–1.5 s after it opens. Get support opens Tether at Rescue. The typed-sentence and quick-sum steps use the same layouts as the in-app small-step states. Not an app route: reference for the native overlay.')

    # ---- effort gate (in app; the iOS shield hands off here)
    gate_open = lambda rule, missing: branch('Small step done?', [('Step done', toast('Open for 10 minutes. The pause screen comes back after.', reset('sf_home'))),
                                                                  ('Step not done', toast(missing))], decide=rule)
    P('sf_unplug_gate', 'Small step: one breath', '/p/sf/unplug/step', 'unplug', program='sf', phase='rescue', kind='fullscreen',
      hdr=H('Small step', left='close', pill='Unplug'), body=[
        title('One breath, then decide.', 'l'), ring('30'),
        text('Breathe in as the circle grows, out as it shrinks.', align='center'),
        support_card(),
    ], footer=[
        button('Keep it closed', toast('Nice. The app stays closed.', reset('sf_home'))),
        link('Open it for 10 minutes', toast('Open for 10 minutes. The pause screen comes back after.', reset('sf_home'))),
    ], source=src + ' PlatformEffortGate.breath; lib/unplug/screens/unplug_screen_d.dart',
       desc='The shield action hands off to the app because the step needs input the extension has no time or UI for. Clearing it grants the pass length the level allows. Get support opens Rescue without doing the step.')
    P('sf_unplug_gate_commit', 'Small step: type a sentence', '/p/sf/unplug/step?state=sentence', 'unplug', program='sf', phase='rescue', kind='fullscreen',
      variant_of='sf_unplug_gate', state='typed sentence', hdr=H('Small step', left='close', pill='Unplug'), body=[
        title('Type it out, then decide.', 'l'), text('“I can come back to this later”'),
        field('Type the sentence', placeholder='I can come back to this later', key='sentence'),
        support_card(),
    ], footer=[
        button('Keep it closed', toast('Nice. The app stays closed.', reset('sf_home'))),
        link('Open it for 10 minutes', gate_open('sf.unplug.sentence', 'Type the whole sentence first.')),
    ], source=src + ' PlatformEffortGate.commitment', desc='Open it works only after the sentence is typed in full (rule sf.unplug.sentence).')
    P('sf_unplug_gate_sum', 'Small step: quick sum', '/p/sf/unplug/step?state=sum', 'unplug', program='sf', phase='rescue', kind='fullscreen',
      variant_of='sf_unplug_gate', state='quick sum', hdr=H('Small step', left='close', pill='Unplug'), body=[
        title('A quick sum, then decide.', 'l'), big('7 + 5'),
        field('Answer', placeholder='?', kind='number', key='answer'),
        support_card(),
    ], footer=[
        button('Keep it closed', toast('Nice. The app stays closed.', reset('sf_home'))),
        link('Open it for 10 minutes', gate_open('sf.unplug.sum', 'Answer the sum first.')),
    ], source=src + ' PlatformEffortGate.puzzle', desc='Open it works only after the right answer is typed (rule sf.unplug.sum).')

    # ---- tracking health
    P('sf_unplug_health', 'Tracking check', '/p/sf/unplug/health', 'unplug', program='sf', phase='daily', hdr=H('Tracking check'), body=[
        banner('success', 'Unplug is working. All 3 checks pass.'),
        checklist([ci('Screen Time permission', 'Allowed', True), ci('Daily schedule', 'Running', True), ci('Settings shared with the pause screen', 'Ready', True)], label='iPhone checks'),
        text('If a check fails, Unplug stops counting and pausing. We’ll tell you instead of letting you think it’s still on.', 'small'),
    ], footer=[button('Done', back())], source=src + ' trackingHealth() (iOS: authorization, schedule, App Group)')
    P('sf_unplug_health_stopped', 'Tracking stopped', '/p/sf/unplug/health?state=stopped', 'unplug', program='sf', phase='daily',
      variant_of='sf_unplug_health', state='tracking stopped', hdr=H('Tracking check'), body=[
        banner('error', 'Unplug has stopped. Nothing is being counted or paused until this is fixed.'),
        checklist([ci('Screen Time permission', 'Turned off in Settings'), ci('Daily schedule', 'Running', True), ci('Settings shared with the pause screen', 'Ready', True)], label='iPhone checks'),
    ], footer=[
        button('Open phone settings', settings()),
        button('Check again', branch('Tracking health result', [('All pass', rep('sf_unplug_health')), ('Still failing', toast('Still not working. Turn Screen Time access on again in Settings.'))]), v='secondary'),
    ], source=src + ' UnplugFlutterApi.onTrackingStopped(checkName, detail)',
       desc='Also opened from the "Unplug needs attention" notification (generic text, no program name).')
    P('sf_unplug_health_android', 'Tracking check (Android)', '/p/sf/unplug/health?state=android', 'unplug', program='sf', phase='daily',
      variant_of='sf_unplug_health', state='android', hdr=H('Tracking check'), body=[
        banner('success', 'Unplug is working. All 3 checks pass.'),
        checklist([ci('Usage access', 'On', True), ci('Display over other apps', 'On', True), ci('Unplug running in the background', 'Checked 12 s ago', True)], label='Android checks'),
        text('Some phones stop background apps to save battery. If Unplug keeps stopping, let Tether run in the background.', 'small'),
    ], footer=[button('Battery settings', settings(), v='secondary'), button('Done', back())],
       source='android/.../unplug/UnplugHost.kt trackingHealth() (usage access, foreground service alive, overlay permission)')

    # ---- turn off
    P('sf_unplug_off', 'Turn off Unplug', '/p/sf/unplug/off', 'unplug', program='sf', phase='account', kind='sheet', over='Unplug', body=[
        title('Turn off Unplug?'),
        text('Paused apps open normally again. Your ScrollFree goal, check-ins and Pause 60 stay.', 'muted'),
        radio([ri('Unplug only', 'Removes app choices, limits and session history from this phone', 'Default'),
               ri('Unplug and Screen Time access', 'ScrollFree goes back to your own estimates')], 0, key='scope'),
    ], footer=[
        button('Turn off', branch('Chosen option', [('Unplug only', submit('CALL device:unplug/liftShield+purgeLocalData', toast('Unplug is off', reset('sf_home')))),
                                                    ('Unplug and Screen Time', submit('PATCH /v1/enrolments/consents', toast('Unplug and Screen Time are off', reset('sf_home'))))],
                                    on='radio', key='scope'), v='danger'),
        button('Cancel', close(), v='secondary'),
    ], source=src + ' liftShield(reason), purgeLocalData(0); ScrollFree screen_time consent',
       desc='Unplug only: liftShield + purgeLocalData(0). With Screen Time: also revokes the ScrollFree screen_time consent (then the same purge).')

    # ---- ScrollFree variants: entry points, native minutes slot, Screen Time wording
    home_offer = _body_of('sf_home')
    home_offer.insert(2, card(title='Want firmer limits?', text='Unplug can pause apps you choose, after limits you set. Optional.',
                              cta=button('Set up', go('sf_unplug_intro'), v='secondary', small=True)))
    P('sf_home_unplug_offer', 'ScrollFree home · Unplug offer', '/p/sf/home?state=unplug-offer', 'sf', program='sf', phase='daily', tabname='plans',
      variant_of='sf_home', state='Unplug not set up (proposal)', hdr=H(PROGRAMS['sf'][0], avatar='A'), body=home_offer,
      source='sf_home in this spec (body copied unchanged, one card added)',
      desc='Identical to ScrollFree home plus one optional card that opens Unplug setup.')

    home_on = _body_of('sf_home')
    home_on[0]['eyebrow'] = 'Yesterday · your estimate'
    home_on.insert(0, nativeslot('ios.deviceActivityReport.today', 'Screen Time today',
                                 'Shown by Apple’s Screen Time on this phone. Tether can’t read, store or share these minutes.', 'ios', 132))
    home_on.insert(3, card(v='mint', title='Unplug is on', text='2 groups · pause screen after 60 min', action=go('sf_unplug_home')))
    P('sf_home_unplug', 'ScrollFree home · Unplug on (iPhone)', '/p/sf/home?state=unplug', 'sf', program='sf', phase='daily', tabname='plans',
      variant_of='sf_home', state='Unplug on · iPhone (proposal)', hdr=H(PROGRAMS['sf'][0], avatar='A'), body=home_on,
      source='DeviceActivityReport extension (new); ios/Runner/Unplug/UnplugHost.swift readUsage (iOS returns no minutes)',
      desc='iPhone: the native slot shows Apple’s minutes; every figure Tether stores stays the person’s own estimate and is labelled so. Android keeps the default home with real totals from readUsage.')

    week_on = _body_of('sf_week')
    for n in week_on:
        if n['t'] == 'chart':
            n['title'] = 'Your estimates · minutes / day'
    week_on.insert(1, nativeslot('ios.deviceActivityReport.week', 'Screen Time this week',
                                 'Shown by Apple’s Screen Time on this phone. Tether can’t read, store or share these minutes.', 'ios', 200))
    P('sf_week_unplug', 'Weekly reflection · Unplug on (iPhone)', '/p/sf/week?state=unplug', 'sf', program='sf', phase='milestone',
      variant_of='sf_week', state='Unplug on · iPhone (proposal)', hdr=H('Week 2', pill='ScrollFree'), body=week_on,
      source='DeviceActivityReport extension (new); sf_week in this spec',
      desc='Apple’s weekly report sits above the person’s own estimates, which are what Tether stores and charts.')

    P('program_settings_sf', 'Program settings · ScrollFree with Unplug', '/p/:program/settings?state=sf-unplug', 'plans', phase='account',
      variant_of='program_settings', state='ScrollFree with Unplug (proposal)', hdr=H('ScrollFree settings'), body=[
        rows([row('ScrollFree', 'Focus since Aug 14', lead=L_prog('sf'))], flat=True),
        radio([ri('Focus', 'Daily steps and reminders'), ri('Learn only', 'Keep lessons, stop tracking'), ri('Pause', 'Stop reminders; keep everything')], 0, label='Status'),
        card(toggle('Care team sharing', 'Off · ScrollFree isn’t shared', False), toggle('De-identified research', None, False), eyebrow='Sharing'),
        rows([row('Unplug', 'On · 2 groups · 60 min limit', action=go('sf_unplug_home')),
              row('Screen Time access', 'Connected · totals only', action=go('sf_screentime')),
              row('Turn off Unplug or Screen Time', 'Anytime', action=sheet('sf_unplug_off'), danger=True)], title='Screen Time & Unplug'),
        rows([row('Export ScrollFree data', 'PDF + JSON', action=toast('Export is being prepared. We’ll notify you.')),
              row('Leave ScrollFree', 'Keep data 30 days or delete now', action=sheet('account_leave'), danger=True)], title='Data'),
    ], footer=[button('Save changes', submit('PATCH /v1/enrolments/:id', toast('Saved', back())))], api=['PATCH /v1/enrolments/:id'],
       source='program_settings in this spec (same layout, ScrollFree data); ' + src + ' purgeLocalData(0)',
       desc='Program settings shown with ScrollFree data. Leaving ScrollFree or deleting the account also runs purgeLocalData(0).')

    P('sf_screentime_report', 'Connect Screen Time · iPhone report wording', '/p/sf/screen-time?state=ios-report', 'sf', program='sf', phase='plan',
      variant_of='sf_screentime', state='iPhone report wording (proposal)', hdr=H('Screen Time', pill='Optional'), body=[
        illus('◷'), title('See your Screen Time here, if you want.', align='center'),
        text('Apple’s Screen Time shows your daily totals by category inside Tether. Tether can’t read, store or share those minutes.', 'muted', align='center'),
        kv([('Shows', 'Minutes per category, on this phone'), ('Never reads', 'Content, messages, contacts'), ('Turn off', 'Anytime in Account')]),
    ], footer=[button('Allow access', branch('iOS Screen Time permission', [('Allowed', toast('Screen Time connected', back())), ('Not allowed', rep('sf_screentime_denied'))])),
               button('Not now', back(), v='secondary')],
       source='ios/Runner/Unplug/UnplugHost.swift:239-253 @ origin/feat/unplug-v2.1-module (no API hands the app a number of minutes)',
       desc='Same layout as Connect Screen Time with "reads" changed to "shows". The owner picks this wording, or legal accepts "reads".')


# ================================================================ MISSING VARIANTS
def p36_gaps():
    # account_delete: social accounts confirm with the same provider instead of a password
    for prov, name in (('apple', 'Apple'), ('google', 'Google')):
        body = _body_of('account_delete')
        body = [n for n in body if not (n['t'] == 'field' and n.get('kind') == 'password')]
        body.append(card(v='mint', eyebrow='Confirm it’s you', title=f'Signed in with {name}',
                         text=f'When you tap Delete everything, {name} asks you to confirm. Use the same {name} account you signed in with.'))
        P(f'account_delete_{prov}', f'Delete account · {name} account', f'/account/delete?state={prov}', 'account', phase='account',
          variant_of='account_delete', state=f'{name} account', hdr=H('Delete account'), body=body,
          footer=[button('Delete everything', auth(prov, [('Success', submit('DELETE /v1/account/data', rep('account_deleted'))),
                                                          ('Different account', toast(f'That’s a different {name} account. Use the one you signed in with.')),
                                                          ('Cancelled', toast('Nothing was deleted.')),
                                                          ('Error', toast(f'Couldn’t reach {name}. Nothing was deleted.'))]), v='danger')],
          api=['DELETE /v1/account/data'],
          source='account_delete in this spec; lib/auth/auth_gateway.dart RecentAuthGateway.reauthenticate (password only today)',
          desc=f'Same as Delete account, with the password field replaced by native {name} re-auth for the same provider; the returned user id must match the signed-in user. Delete runs only after Success.')
    # auth_session: social accounts sign in again with their provider
    for prov, name in (('apple', 'Apple'), ('google', 'Google')):
        P(f'auth_session_{prov}', f'Session expired · {name} account', f'/auth/session?state={prov}', 'auth', phase='account', kind='sheet', over='Today',
          variant_of='auth_session', state=f'{name} account', body=[
            title('Please sign in again'),
            text('For your security, sessions end after 30 days. Anything you logged offline is kept and syncs after you sign in.', 'muted'),
            text(f'You signed in with {name}, so there’s no password to type.', 'small'),
          ], footer=[authbuttons(**{prov: auth(prov, [('Success', close()), ('Cancelled', toast('Still signed out. Rescue works without signing in.')),
                                                      ('Error', go('auth_social_error'))])}),
                     button('Use Face ID', close(), v='secondary')],
          api=['POST supabase /auth/v1/token?grant_type=id_token'],
          source='auth_session in this spec; Supabase signInWithIdToken',
          desc=f'Same as Session expired, with the password field and Sign in button replaced by the native {name} button.')

    # sf_screentime: Android variant (usage access) + its denied state
    P('sf_screentime_android', 'Connect usage access (Android)', '/p/sf/screen-time?state=android', 'sf', program='sf', phase='plan',
      variant_of='sf_screentime', state='android', hdr=H('Screen Time', pill='Optional'), body=[
        illus('◷'), title('See real totals, if you want.', align='center'),
        text('Tether reads daily totals by category only. Never apps’ content, messages or contacts.', 'muted', align='center'),
        kv([('Reads', 'Minutes per category'), ('Never reads', 'Content, messages, contacts'), ('Turn off', 'Anytime in Account')]),
        checklist([ci('Tap Open settings'), ci('Find Tether Health'), ci('Turn on “Permit usage access”')], label='Android asks in Settings'),
    ], footer=[button('Open settings', branch('Android usage access (checked on return)', [('Allowed', toast('Usage access on', back())), ('Not allowed', rep('sf_screentime_android_denied'))])),
               button('Not now', back(), v='secondary')],
       source='sf_screentime in this spec; android/.../unplug/UsageReader.kt (usage access, checked on resume)',
       desc='Android has no permission prompt for usage access; the person turns it on in Settings and the app checks again on return.')
    P('sf_screentime_android_denied', 'Usage access off (Android)', '/p/sf/screen-time?state=android-denied', 'sf', program='sf', phase='plan',
      variant_of='sf_screentime', state='android · not allowed', hdr=H('Screen Time', pill='Optional'), body=[
        banner('info', 'Usage access is still off.'), title('Self-report works just as well.'),
        text('We’ll ask for a quick estimate in your evening check-in. You can connect later in Account → ScrollFree.', 'muted'),
    ], footer=[button('Continue with self-report', back()), button('Open settings', settings(), v='secondary')],
       source='sf_screentime_denied in this spec (same copy, Android wording in the banner)')

    # sys_update: Play Store URL on Android
    P('sys_update_android', 'Update required (Android)', '/system/update?state=android', 'system', phase='account', kind='fullscreen',
      variant_of='sys_update', state='android', hdr=H('Update needed', left='none'), body=_body_of('sys_update'),
      footer=[button('Update now', ext('https://play.google.com/store/apps/details?id=com.TetherHealthLLC.tetherhealth')),
              button('Open Rescue', sheet('rescue_pick'), v='rescue', arrow=False)],
      source='sys_update in this spec; app ID com.TetherHealthLLC.tetherhealth',
      desc='Same as Update required; Update now opens Google Play. The iPhone App Store URL in the base screen still needs the real App Store ID.')


# ================================================================ ENTRY SURFACES
def entry_surfaces():
    flow('entries', 'Home screen, Siri & shortcuts (proposal)',
         'How Tether looks outside the app: the home-screen widget, Siri and App Shortcuts on iPhone, and launcher shortcuts and the widget on Android. '
         'Labels are generic by default; program names appear only when Show sensitive details is on. These are references for the native '
         'widget and shortcut work, not app routes.')
    P('surface_widget_ios', 'Home-screen widget (iPhone)', '/surface/widget/ios', 'entries', phase='rescue', kind='fullscreen', dark=True,
      hdr=H('iPhone widget', left='close', pill='Reference', dark=True), body=[
        eyebrow('Home screen · small widget'),
        card(v='coral', title='Rescue', text='Help for the next few minutes', action=sheet('rescue_pick')),
        kv([('Label', 'Rescue (generic)'), ('Shows', 'No health data, no program names'), ('Tap', 'Opens Rescue, even when signed out'), ('Data', 'None. No App Group needed')]),
    ], source='rescue_pick entry "Home-screen widget / Siri: Rescue" in this spec; WidgetKit, static content',
       desc='WidgetKit extension, static content. The coral card stands for the widget; tapping it opens Rescue.')
    P('surface_widget_android', 'Home-screen widget (Android)', '/surface/widget/android', 'entries', phase='rescue', kind='fullscreen', dark=True,
      hdr=H('Android widget', left='close', pill='Reference', dark=True), body=[
        eyebrow('Home screen · 2×1 widget'),
        card(v='coral', title='Rescue', text='Help for the next few minutes', action=sheet('rescue_pick')),
        kv([('Label', 'Rescue (generic)'), ('Shows', 'No health data, no program names'), ('Tap', 'Opens Rescue, even when signed out'), ('Built with', 'RemoteViews, no extra library')]),
    ], source='rescue_pick entry in this spec; Android RemoteViews widget')
    P('surface_shortcuts_ios', 'Siri & App Shortcuts (iPhone)', '/surface/shortcuts/ios', 'entries', phase='rescue', hdr=H('Siri & Shortcuts', left='close', pill='Reference'), body=[
        text('What people see in the Shortcuts app and Spotlight, and can say to Siri.', 'muted'),
        rows([row('Rescue', '“Rescue in Tether” · opens Rescue', lead=L_icon('✚'), action=sheet('rescue_pick')),
              row('My plan', '“Show my plan in Tether” · only while ClearAir is a focus program', lead=L_icon('▤'), action=go('ca_red'))], title='Tether Health · App Shortcuts'),
        card(v='mint', text='Labels stay generic so a locked phone doesn’t reveal which programs you use. Turn on Show sensitive details to see program names.'),
    ], source='rescue_pick and ca_red entries in this spec; App Intents (OpenRescueIntent, OpenClearAirRedZoneIntent)',
       desc='App Intents exposed as App Shortcuts. The My plan intent is offered only while enrolled in ClearAir and opens the ClearAir red-zone plan.')
    P('surface_shortcuts_ios_named', 'Siri & App Shortcuts (sensitive details on)', '/surface/shortcuts/ios?state=named', 'entries', phase='rescue',
      variant_of='surface_shortcuts_ios', state='Show sensitive details on', hdr=H('Siri & Shortcuts', left='close', pill='Reference'), body=[
        text('With Show sensitive details on (Account → Notifications), shortcuts use program names.', 'muted'),
        rows([row('Rescue', '“Rescue in Tether” · opens Rescue', lead=L_icon('✚'), action=sheet('rescue_pick')),
              row('ClearAir red-zone plan', '“Show my ClearAir plan in Tether”', lead=L_prog('ca'), action=go('ca_red'))], title='Tether Health · App Shortcuts'),
    ], source='surface_shortcuts_ios plus the Show sensitive details toggle on account_notifications in this spec')
    P('surface_shortcuts_android', 'Launcher shortcuts (Android)', '/surface/shortcuts/android', 'entries', phase='rescue', hdr=H('App shortcuts', left='close', pill='Reference'), body=[
        text('Shown when someone long-presses the Tether icon.', 'muted'),
        rows([row('Rescue', 'Static shortcut · always there', lead=L_icon('✚'), action=sheet('rescue_pick')),
              row('My plan', 'Dynamic shortcut · only while ClearAir is a focus program', lead=L_icon('▤'), action=go('ca_red'))], title='Tether Health'),
        card(v='mint', text='Labels stay generic so the home screen doesn’t reveal which programs you use. Turn on Show sensitive details to see program names.'),
    ], source='rescue_pick and ca_red entries in this spec; Android shortcuts.xml + ShortcutManager')
    P('surface_shortcuts_android_named', 'Launcher shortcuts (sensitive details on)', '/surface/shortcuts/android?state=named', 'entries', phase='rescue',
      variant_of='surface_shortcuts_android', state='Show sensitive details on', hdr=H('App shortcuts', left='close', pill='Reference'), body=[
        text('With Show sensitive details on (Account → Notifications), shortcuts use program names.', 'muted'),
        rows([row('Rescue', 'Static shortcut · always there', lead=L_icon('✚'), action=sheet('rescue_pick')),
              row('ClearAir red-zone plan', 'Dynamic shortcut', lead=L_prog('ca'), action=go('ca_red'))], title='Tether Health'),
    ], source='surface_shortcuts_android plus the Show sensitive details toggle on account_notifications in this spec')

    # entry points: system surfaces and notifications that open the new screens
    entry('sf_unplug_shield', 'System: opening a paused app on iPhone (Unplug shield)')
    entry('sf_unplug_overlay', 'System: opening a paused app on Android (Unplug overlay)')
    entry('sf_unplug_session_done', 'Notification: focus session finished (generic text)')
    entry('sf_unplug_health_stopped', 'Notification: Unplug needs attention (generic text)')
    entry('surface_widget_ios', 'Reference: iPhone home-screen widget')
    entry('surface_widget_android', 'Reference: Android home-screen widget')
    entry('surface_shortcuts_ios', 'Reference: Siri & App Shortcuts')
    entry('surface_shortcuts_android', 'Reference: Android launcher shortcuts')
