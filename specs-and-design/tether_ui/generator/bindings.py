"""Member-data bindings of the generated screens (P-89).

The design shows example values: a blood pressure of 128/82, "Good morning,
Alex.", a quit date of Aug 28. In the app these must be the member's own
values. Each row below names one such value on one screen: the element (its
path in the screen spec), the property of that element, the TData bind key
the app fills, and the design's example value (pinned, so a moved element
fails generation instead of binding the wrong value).

What counts as member data (bound here): the member's readings and their
times, averages, counts, streaks and chart series; dates the member set or
that come from their records (quit date, last reading, next check); names of
the member and of their own people, clinic and record sources; amounts and
estimates from their entries; their plan values, reasons and choices once
saved; progress counts on member-specific cards; account and deletion
details; sync times; insights computed from their data.

What stays static copy (not bound): instructions and explanations, content
lengths ("4 min read", "About 60 seconds"), clinical thresholds and
guidance, hotline and emergency numbers, content and app versions, product
facts ("sessions end after 30 days"), program names, directory entries
(records search results, the quitline by state) and generic suggestions that
do not depend on the member's data.

Not bound by this table, and listed for the app lane: header titles
(`support_message_care`, `records_source`, `sf_week`, `sf_week_unplug`) and
header or row avatars (the member's and contacts' initials); input controls
and their labels (settings controls bind through `bind`, P-71, TH-1008);
the structure of member-specific lists (which programmes, supporters or
records exist); running timers and breathing rings; the `bf_date` picker
card, which shows the date being chosen.

In the app a bound element shows the member's value when TData has one, and
otherwise the example value with an "Example" tag (the kit's TBoundValues);
the preview shows the example with no tag (R-163). Binding adds `data` to
the element in the spec: {property: bind key}. It changes no label,
starting value, layout or action.
"""
import re

from dsl import BIND_KEY, SCREENS, walk

# Properties the kit can bind, by element type ([j] is a row or item index).
BINDABLE_PROPS = {
    'eyebrow': ('text',),
    'title': ('text',),
    'text': ('text',),
    'banner': ('text',),
    'quote': ('text',),
    'card': ('eyebrow', 'title', 'text'),
    'big': ('value', 'caption'),
    'stats': ('items[j].label', 'items[j].value', 'items[j].sub'),
    'list': ('title', 'rows[j].label', 'rows[j].sub', 'rows[j].value'),
    'kv': ('rows[j][0]', 'rows[j][1]'),
    'chart': ('values', 'title', 'caption'),
}

# Value type of a bound property: a chart series is a list of numbers, the
# rest is display text.
def value_type(prop): return 'series' if prop == 'values' else 'text'

# What a bound value is (spec/bindings.json `kind`), inferred from its
# example: series, money, duration, date (dates and times), count, number
# or text. The app formats the value; the kind tells it what to supply.
_MONTH = r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\b'
_DAY = r'\b(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*\b'
_KINDS = (
    ('money', re.compile(r'\$\d')),
    ('date', re.compile(rf'{_MONTH}|{_DAY}|\d(:\d\d)? ?(AM|PM)\b|\b(Today|Tomorrow|today)\b|^In \d+ (days|weeks)$')),
    ('duration', re.compile(r'^\d+h( \d+m)?$|^\d+ ?(min|minutes|years|days)$|^\d+$(?#minutes)(?!)')),
    ('count', re.compile(r'^\d+( of \d+)?$|^\d+/\d+$|^\d+ of \d+ ')),
    ('number', re.compile(r'^[−+\-]?[\d.,/% ]+( ?(mg/g|points|L/min))?$')),
)

# Keys whose example the inference above misreads.
KIND = {
    'hw.last_bp': 'number', 'hw.log.reading_1': 'number', 'hw.log.average': 'number', 'hw.avg_30d': 'number',
    'st.last_glucose': 'number', 're.egfr_latest': 'number', 'rescue.rating_before': 'number', 'rescue.rating_now': 'number',
    'sf.unplug.session_minutes': 'duration',
}

def value_kind(prop, example, key=None):
    if key in KIND: return KIND[key]
    if value_type(prop) == 'series': return 'series'
    for kind, rx in _KINDS:
        if rx.search(example): return kind
    return 'text'

# Bound examples that could read as clinical advice or a clinical judgement
# if a member took them as their own (R-163, O-m7): for the clinical lead's
# review (spec/review_TH-909.md). (screen, element path.property, why)
CLINICAL_REVIEW = [
    ('ca_home', 'body[0].title', 'states a peak-flow zone ("Green") for a reading'),
    ('ca_zone', 'body[5].text', 'states zone thresholds from an action plan'),
    ('ca_yellow', 'body[0].text', 'points to a dated action plan'),
    ('ca_progress', 'body[2].title', 'names a most common symptom'),
    ('hw_home', 'body[0].children[0].caption', 'states a blood-pressure target'),
    ('hw_home', 'body[2].rows[4].sub', 'states a clinician-set target'),
    ('hw_result', 'body[2].text', 'compares a reading with a target'),
    ('hw_crisis', 'body[0].text', 'says a reading needs attention now'),
    ('hw_summary', 'body[1].rows[2][1]', 'reports a crisis-range reading and its re-check'),
    ('today_safety', 'body[1].text', 'refers to a crisis-range reading'),
    ('st_home', 'body[0].children[0].caption', 'says a glucose reading is within range'),
    ('st_low', 'body[0].text', 'says a glucose reading is below the member\'s low'),
    ('st_patterns', 'body[3].title', 'links glucose readings to sleep'),
    ('st_a1c', 'body[3].rows[1][1]', 'reports an A1C change'),
    ('re_home', 'body[0].children[0].caption', 'states the next kidney check'),
    ('re_history', 'body[1].rows[2][1]', 'states the next kidney check'),
    ('bf_stepdown', 'body[2].rows[0][1]', 'a cigarette reduction schedule'),
    ('bf_meds', 'body[1].title', 'a recorded quit-medicine plan'),
    ('records_conflict', 'body[1].title', 'judges a value outside the possible range'),
    ('ck_list', 'body[0].text', 'counts screenings due'),
    ('ck_uptodate', 'body[2].text', 'states the next vaccine due date'),
    ('progress', 'body[4].title', 'links scrolling to cravings'),
    ('sf_week', 'body[4].title', 'suggests a lower daily goal'),
]


def review_markdown(screens=None, bindings=None, review=None):
    """spec/review_TH-909.md: the CLINICAL_REVIEW examples with their text."""
    screens = SCREENS if screens is None else screens
    bindings = BINDINGS if bindings is None else bindings
    review = CLINICAL_REVIEW if review is None else review
    by_path = {(r[0], f'{r[1]}.{r[2]}'): r for r in bindings}
    lines = ['# Bound examples for clinical review (P-89)', '',
             'Generated from `generator/bindings.py` (`CLINICAL_REVIEW`); do not edit.', '',
             'In the app these example values show, with an "Example" tag, until the member has their own value.',
             'Each could read as clinical advice or a clinical judgement if taken as the member\'s own.',
             'For the clinical lead: keep, reword or replace each example.', '',
             '| Screen | Element | Example | Why it is listed |', '|---|---|---|---|']
    for sid, path, why in review:
        row = by_path.get((sid, path))
        if row is None: raise ValueError(f'CLINICAL_REVIEW {sid} {path} is not a bound value')
        lines.append(f'| `{sid}` | `{path}` | {row[4]} | {why} |')
    return '\n'.join(lines) + '\n'

# (screen, element path, property, bind key, example value)
BINDINGS = [
    # today
    ('today', 'body[0]', 'text', 'today.date', "Friday, August 21"),
    ('today', 'body[1]', 'text', 'today.greeting', "Good morning, Alex."),
    ('today', 'body[4]', 'eyebrow', 'today.steps_heading', "Today · 2 small steps"),
    ('today', 'body[6]', 'items[0].value', 'bf.days_to_quit_day', "7 days"),
    ('today', 'body[6]', 'items[0].sub', 'bf.quit_date_short', "Fri, Aug 28"),
    ('today', 'body[6]', 'items[1].value', 'sf.minutes_yesterday', "2h 10m"),
    ('today', 'body[6]', 'items[1].sub', 'sf.goal_short', "goal 90 min"),
    ('today_offline', 'body[0]', 'text', 'today.offline_banner', "Offline · 3 entries will sync when you reconnect."),
    ('today_offline', 'body[1]', 'text', 'today.greeting', "Good morning, Alex."),
    ('today_empty', 'body[0]', 'text', 'today.greeting', "Good evening, Alex."),
    ('today_safety', 'body[1]', 'text', 'hw.crisis_reading_source', "Heartwise · from your 8:10 AM reading"),
    ('checkin_done', 'body[1]', 'text', 'checkin.thanks', "Thanks, Alex."),
    # rescue
    ('rescue_pick', 'body[4]', 'eyebrow', 'rescue.last_helpful_result', "Helped last time · 6 → 3"),
    ('rescue_pick', 'body[4]', 'title', 'rescue.last_helpful_tool', "Slow breathing · 2 min"),
    ('rescue_result', 'body[2]', 'items[0].value', 'rescue.rating_before', "8"),
    ('rescue_result', 'body[2]', 'items[1].value', 'rescue.rating_now', "3"),
    ('rescue_escalate', 'body[3]', 'rows[0].label', 'support.contact_text_action', "Text Jordan"),
    ('rescue_escalate', 'body[3]', 'rows[0].sub', 'support.help_phrase_short', "“Can you stay with me for 10 minutes?”"),
    ('crisis', 'body[4]', 'title', 'ea.plan.things_that_help_line', "Things that help: walk the dog, shower, music"),
    ('crisis', 'body[4]', 'text', 'ea.plan.reach_out_line', "Reach out: Sam · (555) 010-3311"),
    # plans, progress, support, account
    ('plans', 'body[0]', 'title', 'plans.focus_heading', "Focus · 2 of 2"),
    ('plans', 'body[0]', 'rows[0].sub', 'bf.plan_summary', "Quit date · Fri, Aug 28"),
    ('plans', 'body[0]', 'rows[1].sub', 'sf.plan_summary', "90 min/day · bedtime 10 PM–7 AM"),
    ('plans', 'body[2]', 'rows[0].sub', 'plans.medication_summary', "BreatheFree · nicotine patch"),
    ('program_settings', 'body[0]', 'rows[0].sub', 'enrolment.:program.since', "Focus since Aug 14"),
    ('program_settings_sf', 'body[0]', 'rows[0].sub', 'enrolment.:program.since', "Focus since Aug 14"),
    ('program_settings_sf', 'body[3]', 'rows[0].sub', 'enrolment.:program.unplug_summary', "On · 2 groups · 60 min limit"),
    ('progress', 'body[2]', 'values', 'bf.cigarettes_week', [10, 7, 4, 3, 1, 1, 0]),
    ('progress', 'body[2]', 'caption', 'bf.progress_caption', "Saved $42.70 · avoided 61"),
    ('progress', 'body[3]', 'values', 'sf.minutes_week', [190, 160, 150, 115, 130, 95, 85]),
    ('progress', 'body[3]', 'caption', 'sf.progress_caption', "Goal 90 min · reclaimed 5h 40m"),
    ('progress', 'body[4]', 'title', 'insights.cross_program', "Late scrolling came before 3 of your 4 strongest cravings."),
    ('support', 'body[1]', 'rows[0].label', 'support.supporter_name', "Jordan"),
    ('support', 'body[2]', 'rows[0].label', 'support.care_team_name', "Dr. Patel’s clinic"),
    ('support', 'body[2]', 'rows[0].sub', 'support.care_team_programs', "Heartwise · ClearAir"),
    ('support_message', 'body[0]', 'text', 'support.message_title', "Send to Jordan?"),
    ('support_message', 'body[1]', 'title', 'support.help_phrase_quoted', "“Can you stay with me for the next 10 minutes?”"),
    ('account', 'body[0]', 'rows[0].label', 'profile.name', "Alex"),
    ('account', 'body[0]', 'rows[0].sub', 'profile.email', "alex@example.com"),
    ('account', 'body[1]', 'rows[0].sub', 'records.sources_summary', "2 sources · Epic, Medicare"),
    ('account', 'body[1]', 'rows[1].sub', 'account.signin_methods_summary', "Apple · email"),
    ('account', 'body[2]', 'rows[0].sub', 'account.programs_summary', "2 focus · 1 learn · 1 paused"),
    ('account', 'body[2]', 'rows[1].sub', 'notifications.summary', "On · quiet hours 9 PM–7 AM"),
    ('account', 'body[2]', 'rows[2].sub', 'consents.reviewed_summary', "Reviewed Aug 22, 2026"),
    ('account_programs', 'body[0]', 'text', 'account.focus_slots', "2 of 2 focus slots used"),
    ('account_programs', 'body[1]', 'rows[0].sub', 'enrolment.bf.summary', "Focus · sharing manual"),
    ('account_programs', 'body[1]', 'rows[1].sub', 'enrolment.sf.summary', "Focus · not shared"),
    ('account_programs', 'body[1]', 'rows[2].sub', 'enrolment.ca.summary', "Learn only · no data"),
    ('account_programs', 'body[1]', 'rows[3].sub', 'enrolment.hw.summary', "Paused Sep 2 · data kept"),
    ('account_notifications', 'body[1]', 'rows[0].sub', 'notifications.bf.summary', "8:00 AM check-in"),
    ('account_notifications', 'body[1]', 'rows[1].sub', 'notifications.sf.summary', "9:30 PM wind-down"),
    ('account_privacy', 'body[1]', 'rows[1].sub', 'consents.history_summary', "v3 · Aug 22, 2026"),
    ('account_delete', 'body[1]', 'rows[0][1]', 'account.data.programs', "4"),
    ('account_delete', 'body[1]', 'rows[1][1]', 'account.data.check_ins', "63"),
    ('account_delete', 'body[1]', 'rows[2][1]', 'account.data.readings', "118"),
    ('account_delete', 'body[1]', 'rows[3][1]', 'account.data.shared_summaries', "3 summaries (their copies stay with them)"),
    ('account_delete_apple', 'body[1]', 'rows[0][1]', 'account.data.programs', "4"),
    ('account_delete_apple', 'body[1]', 'rows[1][1]', 'account.data.check_ins', "63"),
    ('account_delete_apple', 'body[1]', 'rows[2][1]', 'account.data.readings', "118"),
    ('account_delete_apple', 'body[1]', 'rows[3][1]', 'account.data.shared_summaries', "3 summaries (their copies stay with them)"),
    ('account_delete_google', 'body[1]', 'rows[0][1]', 'account.data.programs', "4"),
    ('account_delete_google', 'body[1]', 'rows[1][1]', 'account.data.check_ins', "63"),
    ('account_delete_google', 'body[1]', 'rows[2][1]', 'account.data.readings', "118"),
    ('account_delete_google', 'body[1]', 'rows[3][1]', 'account.data.shared_summaries', "3 summaries (their copies stay with them)"),
    ('account_deleted', 'body[2]', 'rows[0][1]', 'account.deletion.receipt', "DEL-7F3A-21C9"),
    ('account_deleted', 'body[2]', 'rows[1][1]', 'account.deletion.completed_at', "Oct 17, 2026 · 9:41 AM"),
    ('auth_social_new', 'body[3]', 'rows[0][1]', 'auth.social.name', "Alex (shared by Apple)"),
    ('auth_merge', 'body[2]', 'rows[0].sub', 'auth.merge.guest_plan', "Quit date Aug 28 · 3 reasons"),
    ('auth_merge', 'body[3]', 'text', 'auth.merge.account_plan', "Your account already has a BreatheFree plan from Aug 12."),
    # BreatheFree
    ('bf_stepdown', 'body[1]', 'text', 'bf.stepdown.baseline_line', "From your baseline of 15 a day. Adjust any week."),
    ('bf_stepdown', 'body[2]', 'rows[0][1]', 'bf.stepdown.week_1', "15 → 12 a day"),
    ('bf_stepdown', 'body[2]', 'rows[1][1]', 'bf.stepdown.week_2', "9 a day"),
    ('bf_stepdown', 'body[2]', 'rows[2][1]', 'bf.stepdown.week_3', "5 a day"),
    ('bf_stepdown', 'body[2]', 'rows[3][1]', 'bf.stepdown.week_4', "2 a day"),
    ('bf_stepdown', 'body[2]', 'rows[4][0]', 'bf.stepdown.quit_day_label', "Quit day · Sep 18"),
    ('bf_support', 'body[1]', 'rows[0].label', 'bf.supporter_name', "Jordan"),
    ('bf_support', 'body[1]', 'rows[0].sub', 'bf.supporter_detail', "Friend · text message · evening before"),
    ('bf_review', 'body[2]', 'rows[0].sub', 'bf.review.approach', "Set a quit date"),
    ('bf_review', 'body[2]', 'rows[1].sub', 'bf.review.quit_date', "Fri, Aug 28 · 7 days to prepare"),
    ('bf_review', 'body[2]', 'rows[2].sub', 'bf.review.top_reason', "Protect my family"),
    ('bf_review', 'body[2]', 'rows[3].sub', 'bf.review.support', "Jordan · evening before"),
    ('bf_review', 'body[2]', 'rows[4].sub', 'bf.review.space', "2 of 3 tasks done"),
    ('bf_home', 'body[0].children[0]', 'value', 'bf.days_to_quit_day', "7 days"),
    ('bf_home', 'body[0].children[0]', 'caption', 'bf.quit_date_caption', "Friday, August 28 · Pacific Time"),
    ('bf_home', 'body[3].children[0]', 'text', 'bf.top_reason', "Protect my family."),
    ('bf_home', 'body[4]', 'rows[1].sub', 'bf.meds.summary', "Nicotine patch · recorded plan"),
    ('bf_home', 'body[4]', 'rows[2].sub', 'bf.saved_summary', "Saved $42.70 so far"),
    ('bf_home_quitday', 'body[0]', 'text', 'bf.quit_day_heading', "Quit day · Aug 28"),
    ('bf_home_quitday', 'body[2].children[0]', 'value', 'bf.time_since_quit', "2h 41m"),
    ('bf_home_quitday', 'body[2].children[0]', 'caption', 'bf.quit_time_caption', "Started 7:00 AM · Pacific"),
    ('bf_home_quitday', 'body[6]', 'rows[1].sub', 'bf.meds.today_summary', "Patch · taken 8:07 AM"),
    ('bf_slip', 'body[2]', 'rows[0][1]', 'bf.smoke_free_days', "6 of 7 · kept"),
    ('bf_progress', 'body[1]', 'values', 'bf.cigarettes_week', [10, 7, 4, 3, 1, 1, 0]),
    ('bf_progress', 'body[2]', 'items[0].value', 'bf.avoided', "61"),
    ('bf_progress', 'body[2]', 'items[1].value', 'bf.saved', "$42.70"),
    ('bf_progress', 'body[2]', 'items[1].sub', 'bf.price_per_pack', "$14 per pack"),
    ('bf_progress', 'body[2]', 'items[2].value', 'bf.cravings_eased', "4 of 6"),
    ('bf_progress', 'body[2]', 'items[3].value', 'bf.most_helpful_tool', "Breathing"),
    ('bf_progress', 'body[2]', 'items[3].sub', 'bf.most_helpful_count', "3 of 4 times"),
    ('bf_progress', 'body[3]', 'rows[0].sub', 'bf.estimates_summary', "10/day · $14/pack · 5 min each"),
    ('bf_estimates', 'body[1]', 'rows[0][1]', 'bf.estimates.baseline', "10 cigarettes a day"),
    ('bf_estimates', 'body[1]', 'rows[1][1]', 'bf.estimates.price', "$14.00 per pack"),
    ('bf_estimates', 'body[1]', 'rows[2][1]', 'bf.estimates.time_per_cigarette', "5 minutes"),
    ('bf_meds', 'body[1]', 'title', 'bf.meds.recorded_plan', "Nicotine patch · morning"),
    # ScrollFree
    ('sf_goal', 'body[1]', 'text', 'sf.baseline_line', "From about 3 hours a day."),
    ('sf_buddy', 'body[4].children[0]', 'text', 'sf.buddy.preview_message', "Phone-free nights this week: 5. Thanks for cheering me on!"),
    ('sf_home', 'body[0].children[0]', 'value', 'sf.minutes_yesterday', "2h 10m"),
    ('sf_home', 'body[0].children[0]', 'caption', 'sf.goal_caption', "Goal 90 min · down from 3h"),
    ('sf_home', 'body[4]', 'rows[0].sub', 'sf.phone_free_nights_summary', "5 of 7 phone-free nights"),
    ('sf_home', 'body[4]', 'rows[2].sub', 'sf.goal_summary', "90 min · bedtime"),
    ('sf_home', 'body[4]', 'rows[3].sub', 'sf.buddy.summary', "Sam · weekly message"),
    ('sf_home_unplug', 'body[1].children[0]', 'value', 'sf.minutes_yesterday', "2h 10m"),
    ('sf_home_unplug', 'body[1].children[0]', 'caption', 'sf.goal_caption', "Goal 90 min · down from 3h"),
    ('sf_home_unplug', 'body[3]', 'text', 'sf.unplug.status_line', "2 groups · pause screen after 60 min"),
    ('sf_home_unplug', 'body[5]', 'rows[0].sub', 'sf.phone_free_nights_summary', "5 of 7 phone-free nights"),
    ('sf_home_unplug', 'body[5]', 'rows[2].sub', 'sf.goal_summary', "90 min · bedtime"),
    ('sf_home_unplug', 'body[5]', 'rows[3].sub', 'sf.buddy.summary', "Sam · weekly message"),
    ('sf_home_unplug_android', 'body[0].children[0]', 'value', 'sf.minutes_yesterday', "2h 10m"),
    ('sf_home_unplug_android', 'body[0].children[0]', 'caption', 'sf.goal_caption', "Goal 90 min · down from 3h"),
    ('sf_home_unplug_android', 'body[1]', 'items[0].value', 'sf.minutes_today', "48 min"),
    ('sf_home_unplug_android', 'body[1]', 'items[1].value', 'sf.opens_today', "14"),
    ('sf_home_unplug_android', 'body[4]', 'text', 'sf.unplug.status_line', "2 groups · pause screen after 60 min or 20 opens"),
    ('sf_home_unplug_android', 'body[6]', 'rows[0].sub', 'sf.phone_free_nights_summary', "5 of 7 phone-free nights"),
    ('sf_home_unplug_android', 'body[6]', 'rows[2].sub', 'sf.goal_summary', "90 min · bedtime"),
    ('sf_home_unplug_android', 'body[6]', 'rows[3].sub', 'sf.buddy.summary', "Sam · weekly message"),
    ('sf_week', 'body[1]', 'values', 'sf.minutes_week', [190, 160, 130, 0, 110, 95, 85]),
    ('sf_week', 'body[2]', 'items[0].value', 'sf.phone_free_nights', "5/7"),
    ('sf_week', 'body[2]', 'items[1].value', 'sf.urges_paused', "11"),
    ('sf_week', 'body[2]', 'items[1].sub', 'sf.urges_put_down', "7 put down"),
    ('sf_week', 'body[3]', 'text', 'sf.insight', "“Drained” was 4× less common on phone-free nights."),
    ('sf_week', 'body[3].children[0]', 'text', 'sf.you_said', "I feel drained after long scrolls."),
    ('sf_week', 'body[4]', 'title', 'sf.next_week_suggestion', "Step down to 75 min?"),
    ('sf_week_unplug', 'body[2]', 'values', 'sf.minutes_week', [190, 160, 130, 0, 110, 95, 85]),
    ('sf_week_unplug', 'body[3]', 'items[0].value', 'sf.phone_free_nights', "5/7"),
    ('sf_week_unplug', 'body[3]', 'items[1].value', 'sf.urges_paused', "11"),
    ('sf_week_unplug', 'body[3]', 'items[1].sub', 'sf.urges_put_down', "7 put down"),
    ('sf_week_unplug', 'body[4]', 'text', 'sf.insight', "“Drained” was 4× less common on phone-free nights."),
    ('sf_week_unplug', 'body[4].children[0]', 'text', 'sf.you_said', "I feel drained after long scrolls."),
    ('sf_week_unplug', 'body[5]', 'title', 'sf.next_week_suggestion', "Step down to 75 min?"),
    ('sf_unplug_apps_chosen', 'body[2]', 'rows[0].label', 'sf.unplug.group_1_name', "Video apps"),
    ('sf_unplug_apps_chosen', 'body[2]', 'rows[0].sub', 'sf.unplug.group_1_apps', "3 apps"),
    ('sf_unplug_apps_chosen', 'body[2]', 'rows[1].label', 'sf.unplug.group_2_name', "Feeds"),
    ('sf_unplug_apps_chosen', 'body[2]', 'rows[1].sub', 'sf.unplug.group_2_apps', "2 apps"),
    ('sf_unplug_home', 'body[0]', 'text', 'sf.unplug.summary', "5 apps in 2 groups · pause screen after 60 min or 20 opens"),
    ('sf_unplug_home', 'body[2]', 'rows[0].sub', 'sf.unplug.apps_summary', "Video apps · 3, Feeds · 2"),
    ('sf_unplug_home', 'body[2]', 'rows[1].sub', 'sf.unplug.limits_summary', "60 min · 20 opens · one breath first"),
    ('sf_unplug_session_done', 'body[1]', 'value', 'sf.unplug.session_minutes', "45"),
    ('sf_unplug_session_done_early', 'body[0]', 'value', 'sf.unplug.session_minutes', "18"),
    ('sf_unplug_session_done_early', 'body[1]', 'rows[0][1]', 'sf.unplug.end_reason', "Expecting a message"),
    ('sf_unplug_session_done_early', 'body[2]', 'text', 'sf.unplug.early_end_line', "Nothing resets. 18 focused minutes still count."),
    # ClearAir
    ('ca_home', 'body[0]', 'title', 'ca.zone_today', "Green · 410 L/min"),
    ('ca_home', 'body[0]', 'text', 'ca.zone_checked', "Checked 7:40 AM · from your plan"),
    ('ca_home', 'body[3]', 'rows[1].sub', 'ca.zone_counts', "10 green · 2 yellow · 0 red"),
    ('ca_home', 'body[3]', 'rows[2].sub', 'ca.plan_entered', "Entered Sep 3"),
    ('ca_yellow', 'body[0]', 'text', 'ca.plan_entered_line', "From the plan you entered on Sep 3"),
    ('ca_red', 'body[3]', 'rows[0].label', 'ca.emergency_contact_action', "Tell Maria"),
    ('ca_zone', 'body[5]', 'text', 'ca.zone_thresholds_line', "Worked out only from the plan you entered (green from 400, red below 200)."),
    ('ca_progress', 'body[0]', 'values', 'ca.peak_flow_series', [410, 405, 398, 380, 360, 310, 330, 350, 372, 390, 401, 404]),
    ('ca_progress', 'body[1]', 'items[0].value', 'ca.days_green', "10"),
    ('ca_progress', 'body[1]', 'items[1].value', 'ca.days_yellow', "2"),
    ('ca_progress', 'body[1]', 'items[2].value', 'ca.days_red', "0"),
    ('ca_progress', 'body[2]', 'title', 'ca.top_symptom', "Wheezing at night (3×)"),
    # Heartwise
    ('hw_home', 'body[0]', 'eyebrow', 'hw.last_reading_time', "Last reading · 7:52 AM"),
    ('hw_home', 'body[0].children[0]', 'value', 'hw.last_bp', "128/82"),
    ('hw_home', 'body[0].children[0]', 'caption', 'hw.last_bp_caption', "Average of 2 · target below 130/80"),
    ('hw_home', 'body[2]', 'rows[0].sub', 'hw.avg_30d_summary', "30-day average 132/82"),
    ('hw_home', 'body[2]', 'rows[1].sub', 'hw.lipids_summary', "LDL 138 · Sep 30"),
    ('hw_home', 'body[2]', 'rows[3].sub', 'hw.records_summary', "12 readings · Patel Family Medicine (Epic)"),
    ('hw_home', 'body[2]', 'rows[4].sub', 'hw.targets_summary', "130/80 from Dr. Patel"),
    ('hw_log2', 'body[4]', 'rows[0][1]', 'hw.log.reading_1', "138/86"),
    ('hw_log2', 'body[4]', 'rows[1][1]', 'hw.log.average', "135/85"),
    ('hw_result', 'body[1]', 'text', 'hw.result_title', "135/85 saved"),
    ('hw_result', 'body[2]', 'text', 'hw.result_text', "Average of 2 readings. Your clinician’s target is below 130/80."),
    ('hw_crisis', 'body[0]', 'text', 'hw.crisis_banner', "186/122 is in a range that needs attention now."),
    ('hw_trends', 'body[1]', 'values', 'hw.systolic_series', [142, 140, 138, 139, 135, 133, 136, 131, 129, 130, 128, 127]),
    ('hw_trends', 'body[2]', 'items[0].value', 'hw.avg_30d', "132/82"),
    ('hw_trends', 'body[2]', 'items[1].value', 'hw.readings_30d', "48"),
    ('hw_trends', 'body[2]', 'items[1].sub', 'hw.days_missed_30d', "4 days missed"),
    ('hw_summary', 'body[0]', 'text', 'hw.summary.title', "Share with Dr. Patel’s clinic?"),
    ('hw_summary', 'body[1]', 'rows[0][1]', 'hw.summary.dates', "Sep 17 – Oct 17"),
    ('hw_summary', 'body[1]', 'rows[1][1]', 'hw.summary.bp_average', "132/82 (48 readings)"),
    ('hw_summary', 'body[1]', 'rows[2][1]', 'hw.summary.highest', "186/122 · Oct 2 · re-checked 144/90"),
    ('hw_summary', 'body[1]', 'rows[3][1]', 'hw.summary.latest_panel', "LDL 138 · Sep 30"),
    # Steady
    ('st_home', 'body[0]', 'eyebrow', 'st.last_reading_context', "Last reading · 2 h after lunch"),
    ('st_home', 'body[0].children[0]', 'value', 'st.last_glucose', "142"),
    ('st_home', 'body[0].children[0]', 'caption', 'st.last_glucose_caption', "Within your after-meal range (below 180)"),
    ('st_home', 'body[2]', 'rows[1].sub', 'st.in_range_summary', "71% in range · 14 days"),
    ('st_home', 'body[2]', 'rows[2].sub', 'st.a1c_latest', "7.4% · Oct 1"),
    ('st_low', 'body[0]', 'text', 'st.low_banner', "62 mg/dL is below your low of 70."),
    ('st_patterns', 'body[1]', 'values', 'st.after_meal_series', [196, 182, 175, 190, 168, 160, 172, 158, 165, 150, 162, 149]),
    ('st_patterns', 'body[2]', 'items[0].value', 'st.in_range', "71%"),
    ('st_patterns', 'body[2]', 'items[0].sub', 'st.in_range_count', "of 38 readings"),
    ('st_patterns', 'body[2]', 'items[1].value', 'st.lows', "1"),
    ('st_patterns', 'body[2]', 'items[1].sub', 'st.last_low', "Oct 9 · treated"),
    ('st_patterns', 'body[3]', 'title', 'st.pattern_insight', "Readings were higher on nights with less than 6 h sleep."),
    ('st_a1c', 'body[3]', 'rows[0][1]', 'st.a1c_previous', "7.9% · Jul 2"),
    ('st_a1c', 'body[3]', 'rows[1][1]', 'st.a1c_change', "−0.5 points"),
    # Renew
    ('re_home', 'body[0]', 'eyebrow', 're.egfr_latest_date', "Latest eGFR · Oct 3"),
    ('re_home', 'body[0].children[0]', 'value', 're.egfr_latest', "58"),
    ('re_home', 'body[0].children[0]', 'caption', 're.next_check_caption', "Next check Apr 2027 · from your clinician"),
    ('re_home', 'body[2]', 'rows[1].sub', 're.history_span', "2 years"),
    ('re_history', 'body[0]', 'values', 're.egfr_series', [72, 69, 66, 64, 61, 58]),
    ('re_history', 'body[1]', 'rows[0][1]', 're.egfr_latest_summary', "58 · Oct 3"),
    ('re_history', 'body[1]', 'rows[1][1]', 're.acr_latest', "42 mg/g"),
    ('re_history', 'body[1]', 'rows[2][1]', 're.next_check', "Apr 2027 (from your clinician)"),
    # Nourish
    ('nu_home', 'body[0]', 'eyebrow', 'nu.habit_week', "Habit · week 2"),
    ('nu_home', 'body[0]', 'title', 'nu.habit_name', "Add a vegetable to dinner"),
    ('nu_home', 'body[0]', 'text', 'nu.habit_progress', "3 of 5 nights"),
    ('nu_home', 'body[3]', 'rows[1].sub', 'nu.milestone_due', "In 2 weeks"),
    ('nu_week4', 'body[2]', 'rows[0][1]', 'nu.habits_tried', "4"),
    ('nu_week4', 'body[2]', 'rows[1][1]', 'nu.days_done', "19"),
    ('nu_week4', 'body[2]', 'rows[2][1]', 'nu.favorite_habit', "Water before meals"),
    # Stride
    ('sd_plan', 'body[1]', 'rows[0][0]', 'sd.plan.day_1', "Mon"),
    ('sd_plan', 'body[1]', 'rows[0][1]', 'sd.plan.session_1', "Balance · 8 min"),
    ('sd_plan', 'body[1]', 'rows[1][0]', 'sd.plan.day_2', "Wed"),
    ('sd_plan', 'body[1]', 'rows[1][1]', 'sd.plan.session_2', "Strength (chair) · 10 min"),
    ('sd_plan', 'body[1]', 'rows[2][0]', 'sd.plan.day_3', "Fri"),
    ('sd_plan', 'body[1]', 'rows[2][1]', 'sd.plan.session_3', "Walk + balance · 12 min"),
    ('sd_home', 'body[0]', 'eyebrow', 'sd.today_heading', "Today · Wednesday"),
    ('sd_home', 'body[0]', 'title', 'sd.today_session', "Strength (chair) · 10 min"),
    ('sd_home', 'body[2]', 'rows[0].sub', 'sd.safety_progress', "2 of 5 done"),
    ('sd_home', 'body[2]', 'rows[1].sub', 'sd.caregiver_summary', "Rosa · Stride only"),
    ('sd_home', 'body[2]', 'rows[2].sub', 'sd.plan_summary', "3 sessions a week"),
    ('sd_home', 'body[3]', 'items[0].value', 'sd.sessions_this_week', "1 of 3"),
    ('sd_home', 'body[3]', 'items[1].value', 'sd.falls_30d', "0"),
    ('sd_fell', 'body[2]', 'rows[0].label', 'sd.caregiver_call_action', "Call Rosa"),
    ('sd_safety', 'body[2]', 'text', 'sd.safety_progress', "2 of 5 done"),
    # Ease
    ('ea_home', 'body[1]', 'rows[0].sub', 'ea.plan_updated', "Updated Oct 2"),
    ('ea_home', 'body[1]', 'rows[1].sub', 'ea.check_back_due', "In 6 days"),
    # Checkup
    ('ck_list', 'body[0]', 'text', 'ck.due_summary', "3 due, 1 to ask about"),
    ('ck_uptodate', 'body[2]', 'text', 'ck.next_due_line', "Next: flu vaccine in Sep 2027. We’ll remind you a month before."),
    ('ck_day', 'body[0]', 'text', 'ck.appointment_title', "Mammogram tomorrow at 9:30 AM"),
    # Beacon
    ('be_tx', 'body[0]', 'title', 'be.next_appointment', "Oct 22 · Oncology · 10:30 AM"),
    ('be_survivor', 'body[3]', 'rows[0][1]', 'be.next_follow_up', "Jan 14, 2027"),
    # Health records
    ('records_hub', 'body[1]', 'rows[0].label', 'records.source_1.name', "Patel Family Medicine"),
    ('records_hub', 'body[1]', 'rows[0].sub', 'records.source_1.status', "Epic MyChart · synced today 7:02 AM"),
    ('records_hub', 'body[1]', 'rows[1].label', 'records.source_2.name', "Medicare"),
    ('records_hub', 'body[1]', 'rows[1].sub', 'records.source_2.status', "Blue Button 2.0 · synced Oct 12"),
    ('records_hub', 'body[2]', 'rows[0].sub', 'records.imported.blood_pressure', "12 readings · Heartwise"),
    ('records_hub', 'body[2]', 'rows[1].sub', 'records.imported.labs', "A1C, lipids, eGFR · Steady, Heartwise, Renew"),
    ('records_hub', 'body[2]', 'rows[2].sub', 'records.imported.immunizations', "6 · Checkup"),
    ('records_hub', 'body[2]', 'rows[3].sub', 'records.imported.smoking_status', "Every day smoker (Aug 2026) · BreatheFree"),
    ('records_hub', 'body[3]', 'title', 'records.review_count', "2 items need your review"),
    ('records_consent', 'body[0]', 'text', 'records.connect_title', "Connect Patel Family Medicine?"),
    ('records_review', 'body[2]', 'text', 'records.review_banner', "2 items need your review."),
    ('records_review', 'body[9]', 'rows[0][1]', 'records.review.units_converted', "2 glucose results · mmol/L → mg/dL"),
    ('records_review', 'body[9]', 'rows[1][1]', 'records.review.duplicates_skipped', "3 readings you already entered"),
    ('records_review', 'body[9]', 'rows[2][1]', 'records.review.held_as_typo', "1 · BP 1290/80"),
    ('records_review', 'body[9]', 'rows[3][1]', 'records.review.future_dates_rejected', "0"),
    ('records_conflict', 'body[0]', 'eyebrow', 'records.conflict_1.heading', "A1C · Oct 1, 2026"),
    ('records_conflict', 'body[1]', 'eyebrow', 'records.conflict_2.heading', "Blood pressure · Aug 4, 2026"),
    ('records_conflict', 'body[1]', 'title', 'records.conflict_2.title', "1290/80 is outside the possible range"),
    ('records_source', 'body[0]', 'rows[0][1]', 'records.source.connection', "Epic MyChart · SMART on FHIR R4"),
    ('records_source', 'body[0]', 'rows[1][1]', 'records.source.last_sync', "Today 7:02 AM"),
    ('records_source', 'body[0]', 'rows[2][1]', 'records.source.next_sync', "Tomorrow"),
    ('records_source', 'body[0]', 'rows[3][1]', 'records.source.access', "Read-only · 6 categories"),
    ('records_source', 'body[0]', 'rows[4][1]', 'records.source.connected_on', "Oct 3, 2026"),
    ('records_disconnect', 'body[0]', 'text', 'records.disconnect_title', "Disconnect Patel Family Medicine?"),
    ('records_item', 'body[0]', 'values', 'records.item.series', [142, 140, 138, 139, 135, 133, 136, 131, 129, 130, 128, 127]),
    ('records_item', 'body[1]', 'rows[0].label', 'records.item.latest_1', "128/82 · Oct 15"),
    ('records_item', 'body[1]', 'rows[0].sub', 'records.item.latest_1_source', "Patel Family Medicine (Epic) · clinic reading"),
    ('records_item', 'body[1]', 'rows[1].label', 'records.item.latest_2', "135/85 · Oct 14"),
    ('records_item', 'body[1]', 'rows[1].sub', 'records.item.latest_2_source', "Entered by you · home monitor"),
    ('records_item', 'body[1]', 'rows[2].label', 'records.item.latest_3', "131/80 · Oct 2"),
    ('records_item', 'body[1]', 'rows[2].sub', 'records.item.latest_3_source', "Patel Family Medicine (Epic)"),
]


def _element(s, path):
    """The node at `path` (body[i], footer[i], .children[j], .cta[0]) of screen `s`."""
    for n, p in walk(s['body'], 'body'):
        if p == path: return n
    for n, p in walk(s['footer'], 'footer'):
        if p == path: return n
    return None


def _prop(n, prop):
    """The value of `prop` (e.g. items[0].value, rows[2][1]) on node `n`, or KeyError."""
    cur = n
    for name, idx in re.findall(r'([A-Za-z]+)|\[(\d+)\]', prop):
        cur = cur[name] if name else cur[int(idx)]
    return cur


def _generic(prop): return re.sub(r'\[\d+\]', '[j]', prop, count=1) if prop.startswith(('items[', 'rows[')) else prop


def check(screens, bindings):
    """Error strings for `bindings` against `screens` (the spec dict)."""
    errors, seen = [], {}
    for row in bindings:
        sid, path, prop, key, example = row
        where = f'{sid} {path}.{prop}'
        s = screens.get(sid)
        if s is None:
            errors.append(f'binding {where}: no such screen'); continue
        n = _element(s, path)
        if n is None:
            errors.append(f'binding {where}: no element at {path}'); continue
        if _generic(prop) not in BINDABLE_PROPS.get(n['t'], ()):
            errors.append(f'binding {where}: the kit cannot bind {prop!r} on a {n["t"]}'); continue
        try:
            value = _prop(n, prop)
        except (KeyError, IndexError, TypeError):
            errors.append(f'binding {where}: the element has no {prop}'); continue
        if value != example:
            errors.append(f'binding {where}: example {example!r} pinned, the spec has {value!r} (the element moved or its copy changed)')
        if not isinstance(key, str) or not BIND_KEY.match(key):
            errors.append(f'binding {where}: bind key {key!r} must be dot-separated lower-case segments')
        elif ':program' in key.split('.') and ':program' not in s['route']:
            errors.append(f'binding {where}: bind key {key!r} has a :program segment, but the screen\'s route has none')
        if (sid, path, prop) in seen:
            errors.append(f'binding {where}: listed twice')
        seen[(sid, path, prop)] = key
    inputs = {n.get('bind') for s in screens.values() for part in ('body', 'footer') for n, _ in walk(s[part], part) if n.get('bind')}
    for key in sorted({r[3] for r in bindings} & inputs):
        errors.append(f'binding key {key!r} is also a settings control bind key (P-71): use a different key')
    return errors


def apply(screens=SCREENS, bindings=BINDINGS):
    """Adds `data` ({property: bind key}) to every bound element. Raises
    ValueError when a row does not match the spec."""
    errors = check(screens, bindings)
    if errors: raise ValueError('\n'.join(errors))
    for sid, path, prop, key, _ in bindings:
        _element(screens[sid], path).setdefault('data', {})[prop] = key


def catalogue(screens=SCREENS, bindings=BINDINGS):
    """spec/bindings.json: every bound value, for the app to fill."""
    rows = []
    for sid, path, prop, key, example in bindings:
        s = screens[sid]
        rows.append({'screen': sid, 'program': s['program'], 'element': path, 'component': _element(s, path)['t'],
                     'property': prop, 'path': f'{path}.{prop}', 'bind': key, 'type': value_type(prop), 'kind': value_kind(prop, example, key),
                     'example': example})
    return {
        'about': ('Member values on the generated screens (P-89). The app supplies each bind key through TData: '
                  'type text as a display string, type series as a list of numbers; kind says what the value is. '
                  'Without a value (null or TData.unset) the screen shows the example with an "Example" tag; '
                  'the preview shows the example with no tag. A ":program" segment stands for the programme the screen '
                  'was opened for. Generated from generator/bindings.py; do not edit.'),
        'count': len(rows),
        'bindings': rows,
    }


def _self_test():
    """Rows that do not match the spec are rejected."""
    s = {'x': {'id': 'x', 'route': '/x', 'program': None, 'header': None, 'footer': [],
               'body': [{'t': 'big', 'value': '128/82'}, {'t': 'button', 'label': 'Go'}, {'t': 'chart', 'values': [1, 2]}]}}
    ok = [('x', 'body[0]', 'value', 'hw.last_bp', '128/82'), ('x', 'body[2]', 'values', 'hw.week', [1, 2])]
    if check(s, ok): raise AssertionError(check(s, ok))
    for bad, why in ((('x', 'body[0]', 'value', 'hw.last_bp', '120/80'), 'pinned'), (('x', 'body[5]', 'value', 'hw.a', '1'), 'no element'),
                     (('x', 'body[1]', 'label', 'hw.a', 'Go'), 'cannot bind'), (('x', 'body[0]', 'value', 'HW', '128/82'), 'lower-case'),
                     (('x', 'body[0]', 'value', 'e.:program.a', '128/82'), ':program'), (('y', 'body[0]', 'value', 'hw.a', '1'), 'no such screen')):
        errs = check(s, [bad])
        if not any(why in e for e in errs): raise AssertionError(f'{bad}: {errs}')
    if not any('listed twice' in e for e in check(s, ok + ok[:1])): raise AssertionError('duplicate row accepted')
    apply(s, ok)
    if s['x']['body'][0]['data'] != {'value': 'hw.last_bp'}: raise AssertionError(s['x']['body'][0])
    print('bindings self-test: ok')


if __name__ == '__main__':
    _self_test()
