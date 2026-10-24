// GENERATED — member-data bindings (P-89, R-163). spec/bindings.json lists
// every bound value of the generated screens (generator/bindings.py). Every
// screen is opened: the bound elements it renders must be exactly the ones
// listed for it. Preview answers (TData.example) show the examples with no
// tag; with every key unset (loaded, no member value) every bound element
// shows its example with one Example tag; with the member's values none
// does. Binding never writes to the session, so an example never reaches a
// payload or a decision rule.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

/// (screen, element path + property, bind key), as generated.
const _expected = <(String, String, String)>[
  ('today', 'body[0].text', 'today.date'),
  ('today', 'body[1].text', 'today.greeting'),
  ('today', 'body[4].eyebrow', 'today.steps_heading'),
  ('today', 'body[6].items[0].value', 'bf.days_to_quit_day'),
  ('today', 'body[6].items[0].sub', 'bf.quit_date_short'),
  ('today', 'body[6].items[1].value', 'sf.minutes_yesterday'),
  ('today', 'body[6].items[1].sub', 'sf.goal_short'),
  ('today_offline', 'body[0].text', 'today.offline_banner'),
  ('today_offline', 'body[1].text', 'today.greeting'),
  ('today_empty', 'body[0].text', 'today.greeting'),
  ('today_safety', 'body[1].text', 'hw.crisis_reading_source'),
  ('checkin_done', 'body[1].text', 'checkin.thanks'),
  ('rescue_pick', 'body[4].eyebrow', 'rescue.last_helpful_result'),
  ('rescue_pick', 'body[4].title', 'rescue.last_helpful_tool'),
  ('rescue_result', 'body[2].items[0].value', 'rescue.rating_before'),
  ('rescue_result', 'body[2].items[1].value', 'rescue.rating_now'),
  ('rescue_escalate', 'body[3].rows[0].label', 'support.contact_text_action'),
  ('rescue_escalate', 'body[3].rows[0].sub', 'support.help_phrase_short'),
  ('crisis', 'body[4].title', 'ea.plan.things_that_help_line'),
  ('crisis', 'body[4].text', 'ea.plan.reach_out_line'),
  ('plans', 'body[0].title', 'plans.focus_heading'),
  ('plans', 'body[0].rows[0].sub', 'bf.plan_summary'),
  ('plans', 'body[0].rows[1].sub', 'sf.plan_summary'),
  ('plans', 'body[2].rows[0].sub', 'plans.medication_summary'),
  ('program_settings', 'body[0].rows[0].sub', 'enrolment.:program.since'),
  ('program_settings_sf', 'body[0].rows[0].sub', 'enrolment.:program.since'),
  ('program_settings_sf', 'body[3].rows[0].sub', 'enrolment.:program.unplug_summary'),
  ('progress', 'body[2].values', 'bf.cigarettes_week'),
  ('progress', 'body[2].caption', 'bf.progress_caption'),
  ('progress', 'body[3].values', 'sf.minutes_week'),
  ('progress', 'body[3].caption', 'sf.progress_caption'),
  ('progress', 'body[4].title', 'insights.cross_program'),
  ('support', 'body[1].rows[0].label', 'support.supporter_name'),
  ('support', 'body[2].rows[0].label', 'support.care_team_name'),
  ('support', 'body[2].rows[0].sub', 'support.care_team_programs'),
  ('support_message', 'body[0].text', 'support.message_title'),
  ('support_message', 'body[1].title', 'support.help_phrase_quoted'),
  ('account', 'body[0].rows[0].label', 'profile.name'),
  ('account', 'body[0].rows[0].sub', 'profile.email'),
  ('account', 'body[1].rows[0].sub', 'records.sources_summary'),
  ('account', 'body[1].rows[1].sub', 'account.signin_methods_summary'),
  ('account', 'body[2].rows[0].sub', 'account.programs_summary'),
  ('account', 'body[2].rows[1].sub', 'notifications.summary'),
  ('account', 'body[2].rows[2].sub', 'consents.reviewed_summary'),
  ('account_programs', 'body[0].text', 'account.focus_slots'),
  ('account_programs', 'body[1].rows[0].sub', 'enrolment.bf.summary'),
  ('account_programs', 'body[1].rows[1].sub', 'enrolment.sf.summary'),
  ('account_programs', 'body[1].rows[2].sub', 'enrolment.ca.summary'),
  ('account_programs', 'body[1].rows[3].sub', 'enrolment.hw.summary'),
  ('account_notifications', 'body[1].rows[0].sub', 'notifications.bf.summary'),
  ('account_notifications', 'body[1].rows[1].sub', 'notifications.sf.summary'),
  ('account_privacy', 'body[1].rows[1].sub', 'consents.history_summary'),
  ('account_delete', 'body[1].rows[0][1]', 'account.data.programs'),
  ('account_delete', 'body[1].rows[1][1]', 'account.data.check_ins'),
  ('account_delete', 'body[1].rows[2][1]', 'account.data.readings'),
  ('account_delete', 'body[1].rows[3][1]', 'account.data.shared_summaries'),
  ('account_delete_apple', 'body[1].rows[0][1]', 'account.data.programs'),
  ('account_delete_apple', 'body[1].rows[1][1]', 'account.data.check_ins'),
  ('account_delete_apple', 'body[1].rows[2][1]', 'account.data.readings'),
  ('account_delete_apple', 'body[1].rows[3][1]', 'account.data.shared_summaries'),
  ('account_delete_google', 'body[1].rows[0][1]', 'account.data.programs'),
  ('account_delete_google', 'body[1].rows[1][1]', 'account.data.check_ins'),
  ('account_delete_google', 'body[1].rows[2][1]', 'account.data.readings'),
  ('account_delete_google', 'body[1].rows[3][1]', 'account.data.shared_summaries'),
  ('account_deleted', 'body[2].rows[0][1]', 'account.deletion.receipt'),
  ('account_deleted', 'body[2].rows[1][1]', 'account.deletion.completed_at'),
  ('auth_social_new', 'body[3].rows[0][1]', 'auth.social.name'),
  ('auth_merge', 'body[2].rows[0].sub', 'auth.merge.guest_plan'),
  ('auth_merge', 'body[3].text', 'auth.merge.account_plan'),
  ('bf_stepdown', 'body[1].text', 'bf.stepdown.baseline_line'),
  ('bf_stepdown', 'body[2].rows[0][1]', 'bf.stepdown.week_1'),
  ('bf_stepdown', 'body[2].rows[1][1]', 'bf.stepdown.week_2'),
  ('bf_stepdown', 'body[2].rows[2][1]', 'bf.stepdown.week_3'),
  ('bf_stepdown', 'body[2].rows[3][1]', 'bf.stepdown.week_4'),
  ('bf_stepdown', 'body[2].rows[4][0]', 'bf.stepdown.quit_day_label'),
  ('bf_support', 'body[1].rows[0].label', 'bf.supporter_name'),
  ('bf_support', 'body[1].rows[0].sub', 'bf.supporter_detail'),
  ('bf_review', 'body[2].rows[0].sub', 'bf.review.approach'),
  ('bf_review', 'body[2].rows[1].sub', 'bf.review.quit_date'),
  ('bf_review', 'body[2].rows[2].sub', 'bf.review.top_reason'),
  ('bf_review', 'body[2].rows[3].sub', 'bf.review.support'),
  ('bf_review', 'body[2].rows[4].sub', 'bf.review.space'),
  ('bf_home', 'body[0].children[0].value', 'bf.days_to_quit_day'),
  ('bf_home', 'body[0].children[0].caption', 'bf.quit_date_caption'),
  ('bf_home', 'body[3].children[0].text', 'bf.top_reason'),
  ('bf_home', 'body[4].rows[1].sub', 'bf.meds.summary'),
  ('bf_home', 'body[4].rows[2].sub', 'bf.saved_summary'),
  ('bf_home_quitday', 'body[0].text', 'bf.quit_day_heading'),
  ('bf_home_quitday', 'body[2].children[0].value', 'bf.time_since_quit'),
  ('bf_home_quitday', 'body[2].children[0].caption', 'bf.quit_time_caption'),
  ('bf_home_quitday', 'body[6].rows[1].sub', 'bf.meds.today_summary'),
  ('bf_slip', 'body[2].rows[0][1]', 'bf.smoke_free_days'),
  ('bf_progress', 'body[1].values', 'bf.cigarettes_week'),
  ('bf_progress', 'body[2].items[0].value', 'bf.avoided'),
  ('bf_progress', 'body[2].items[1].value', 'bf.saved'),
  ('bf_progress', 'body[2].items[1].sub', 'bf.price_per_pack'),
  ('bf_progress', 'body[2].items[2].value', 'bf.cravings_eased'),
  ('bf_progress', 'body[2].items[3].value', 'bf.most_helpful_tool'),
  ('bf_progress', 'body[2].items[3].sub', 'bf.most_helpful_count'),
  ('bf_progress', 'body[3].rows[0].sub', 'bf.estimates_summary'),
  ('bf_estimates', 'body[1].rows[0][1]', 'bf.estimates.baseline'),
  ('bf_estimates', 'body[1].rows[1][1]', 'bf.estimates.price'),
  ('bf_estimates', 'body[1].rows[2][1]', 'bf.estimates.time_per_cigarette'),
  ('bf_meds', 'body[1].title', 'bf.meds.recorded_plan'),
  ('sf_goal', 'body[1].text', 'sf.baseline_line'),
  ('sf_buddy', 'body[4].children[0].text', 'sf.buddy.preview_message'),
  ('sf_home', 'body[0].children[0].value', 'sf.minutes_yesterday'),
  ('sf_home', 'body[0].children[0].caption', 'sf.goal_caption'),
  ('sf_home', 'body[4].rows[0].sub', 'sf.phone_free_nights_summary'),
  ('sf_home', 'body[4].rows[2].sub', 'sf.goal_summary'),
  ('sf_home', 'body[4].rows[3].sub', 'sf.buddy.summary'),
  ('sf_home_unplug', 'body[1].children[0].value', 'sf.minutes_yesterday'),
  ('sf_home_unplug', 'body[1].children[0].caption', 'sf.goal_caption'),
  ('sf_home_unplug', 'body[3].text', 'sf.unplug.status_line'),
  ('sf_home_unplug', 'body[5].rows[0].sub', 'sf.phone_free_nights_summary'),
  ('sf_home_unplug', 'body[5].rows[2].sub', 'sf.goal_summary'),
  ('sf_home_unplug', 'body[5].rows[3].sub', 'sf.buddy.summary'),
  ('sf_home_unplug_android', 'body[0].children[0].value', 'sf.minutes_yesterday'),
  ('sf_home_unplug_android', 'body[0].children[0].caption', 'sf.goal_caption'),
  ('sf_home_unplug_android', 'body[1].items[0].value', 'sf.minutes_today'),
  ('sf_home_unplug_android', 'body[1].items[1].value', 'sf.opens_today'),
  ('sf_home_unplug_android', 'body[4].text', 'sf.unplug.status_line'),
  ('sf_home_unplug_android', 'body[6].rows[0].sub', 'sf.phone_free_nights_summary'),
  ('sf_home_unplug_android', 'body[6].rows[2].sub', 'sf.goal_summary'),
  ('sf_home_unplug_android', 'body[6].rows[3].sub', 'sf.buddy.summary'),
  ('sf_week', 'body[1].values', 'sf.minutes_week'),
  ('sf_week', 'body[2].items[0].value', 'sf.phone_free_nights'),
  ('sf_week', 'body[2].items[1].value', 'sf.urges_paused'),
  ('sf_week', 'body[2].items[1].sub', 'sf.urges_put_down'),
  ('sf_week', 'body[3].text', 'sf.insight'),
  ('sf_week', 'body[3].children[0].text', 'sf.you_said'),
  ('sf_week', 'body[4].title', 'sf.next_week_suggestion'),
  ('sf_week_unplug', 'body[2].values', 'sf.minutes_week'),
  ('sf_week_unplug', 'body[3].items[0].value', 'sf.phone_free_nights'),
  ('sf_week_unplug', 'body[3].items[1].value', 'sf.urges_paused'),
  ('sf_week_unplug', 'body[3].items[1].sub', 'sf.urges_put_down'),
  ('sf_week_unplug', 'body[4].text', 'sf.insight'),
  ('sf_week_unplug', 'body[4].children[0].text', 'sf.you_said'),
  ('sf_week_unplug', 'body[5].title', 'sf.next_week_suggestion'),
  ('sf_unplug_apps_chosen', 'body[2].rows[0].label', 'sf.unplug.group_1_name'),
  ('sf_unplug_apps_chosen', 'body[2].rows[0].sub', 'sf.unplug.group_1_apps'),
  ('sf_unplug_apps_chosen', 'body[2].rows[1].label', 'sf.unplug.group_2_name'),
  ('sf_unplug_apps_chosen', 'body[2].rows[1].sub', 'sf.unplug.group_2_apps'),
  ('sf_unplug_home', 'body[0].text', 'sf.unplug.summary'),
  ('sf_unplug_home', 'body[2].rows[0].sub', 'sf.unplug.apps_summary'),
  ('sf_unplug_home', 'body[2].rows[1].sub', 'sf.unplug.limits_summary'),
  ('sf_unplug_session_done', 'body[1].value', 'sf.unplug.session_minutes'),
  ('sf_unplug_session_done_early', 'body[0].value', 'sf.unplug.session_minutes'),
  ('sf_unplug_session_done_early', 'body[1].rows[0][1]', 'sf.unplug.end_reason'),
  ('sf_unplug_session_done_early', 'body[2].text', 'sf.unplug.early_end_line'),
  ('ca_home', 'body[0].title', 'ca.zone_today'),
  ('ca_home', 'body[0].text', 'ca.zone_checked'),
  ('ca_home', 'body[3].rows[1].sub', 'ca.zone_counts'),
  ('ca_home', 'body[3].rows[2].sub', 'ca.plan_entered'),
  ('ca_yellow', 'body[0].text', 'ca.plan_entered_line'),
  ('ca_red', 'body[3].rows[0].label', 'ca.emergency_contact_action'),
  ('ca_zone', 'body[5].text', 'ca.zone_thresholds_line'),
  ('ca_progress', 'body[0].values', 'ca.peak_flow_series'),
  ('ca_progress', 'body[1].items[0].value', 'ca.days_green'),
  ('ca_progress', 'body[1].items[1].value', 'ca.days_yellow'),
  ('ca_progress', 'body[1].items[2].value', 'ca.days_red'),
  ('ca_progress', 'body[2].title', 'ca.top_symptom'),
  ('hw_home', 'body[0].eyebrow', 'hw.last_reading_time'),
  ('hw_home', 'body[0].children[0].value', 'hw.last_bp'),
  ('hw_home', 'body[0].children[0].caption', 'hw.last_bp_caption'),
  ('hw_home', 'body[2].rows[0].sub', 'hw.avg_30d_summary'),
  ('hw_home', 'body[2].rows[1].sub', 'hw.lipids_summary'),
  ('hw_home', 'body[2].rows[3].sub', 'hw.records_summary'),
  ('hw_home', 'body[2].rows[4].sub', 'hw.targets_summary'),
  ('hw_log2', 'body[4].rows[0][1]', 'hw.log.reading_1'),
  ('hw_log2', 'body[4].rows[1][1]', 'hw.log.average'),
  ('hw_result', 'body[1].text', 'hw.result_title'),
  ('hw_result', 'body[2].text', 'hw.result_text'),
  ('hw_crisis', 'body[0].text', 'hw.crisis_banner'),
  ('hw_trends', 'body[1].values', 'hw.systolic_series'),
  ('hw_trends', 'body[2].items[0].value', 'hw.avg_30d'),
  ('hw_trends', 'body[2].items[1].value', 'hw.readings_30d'),
  ('hw_trends', 'body[2].items[1].sub', 'hw.days_missed_30d'),
  ('hw_summary', 'body[0].text', 'hw.summary.title'),
  ('hw_summary', 'body[1].rows[0][1]', 'hw.summary.dates'),
  ('hw_summary', 'body[1].rows[1][1]', 'hw.summary.bp_average'),
  ('hw_summary', 'body[1].rows[2][1]', 'hw.summary.highest'),
  ('hw_summary', 'body[1].rows[3][1]', 'hw.summary.latest_panel'),
  ('st_home', 'body[0].eyebrow', 'st.last_reading_context'),
  ('st_home', 'body[0].children[0].value', 'st.last_glucose'),
  ('st_home', 'body[0].children[0].caption', 'st.last_glucose_caption'),
  ('st_home', 'body[2].rows[1].sub', 'st.in_range_summary'),
  ('st_home', 'body[2].rows[2].sub', 'st.a1c_latest'),
  ('st_low', 'body[0].text', 'st.low_banner'),
  ('st_patterns', 'body[1].values', 'st.after_meal_series'),
  ('st_patterns', 'body[2].items[0].value', 'st.in_range'),
  ('st_patterns', 'body[2].items[0].sub', 'st.in_range_count'),
  ('st_patterns', 'body[2].items[1].value', 'st.lows'),
  ('st_patterns', 'body[2].items[1].sub', 'st.last_low'),
  ('st_patterns', 'body[3].title', 'st.pattern_insight'),
  ('st_a1c', 'body[3].rows[0][1]', 'st.a1c_previous'),
  ('st_a1c', 'body[3].rows[1][1]', 'st.a1c_change'),
  ('re_home', 'body[0].eyebrow', 're.egfr_latest_date'),
  ('re_home', 'body[0].children[0].value', 're.egfr_latest'),
  ('re_home', 'body[0].children[0].caption', 're.next_check_caption'),
  ('re_home', 'body[2].rows[1].sub', 're.history_span'),
  ('re_history', 'body[0].values', 're.egfr_series'),
  ('re_history', 'body[1].rows[0][1]', 're.egfr_latest_summary'),
  ('re_history', 'body[1].rows[1][1]', 're.acr_latest'),
  ('re_history', 'body[1].rows[2][1]', 're.next_check'),
  ('nu_home', 'body[0].eyebrow', 'nu.habit_week'),
  ('nu_home', 'body[0].title', 'nu.habit_name'),
  ('nu_home', 'body[0].text', 'nu.habit_progress'),
  ('nu_home', 'body[3].rows[1].sub', 'nu.milestone_due'),
  ('nu_week4', 'body[2].rows[0][1]', 'nu.habits_tried'),
  ('nu_week4', 'body[2].rows[1][1]', 'nu.days_done'),
  ('nu_week4', 'body[2].rows[2][1]', 'nu.favorite_habit'),
  ('sd_plan', 'body[1].rows[0][0]', 'sd.plan.day_1'),
  ('sd_plan', 'body[1].rows[0][1]', 'sd.plan.session_1'),
  ('sd_plan', 'body[1].rows[1][0]', 'sd.plan.day_2'),
  ('sd_plan', 'body[1].rows[1][1]', 'sd.plan.session_2'),
  ('sd_plan', 'body[1].rows[2][0]', 'sd.plan.day_3'),
  ('sd_plan', 'body[1].rows[2][1]', 'sd.plan.session_3'),
  ('sd_home', 'body[0].eyebrow', 'sd.today_heading'),
  ('sd_home', 'body[0].title', 'sd.today_session'),
  ('sd_home', 'body[2].rows[0].sub', 'sd.safety_progress'),
  ('sd_home', 'body[2].rows[1].sub', 'sd.caregiver_summary'),
  ('sd_home', 'body[2].rows[2].sub', 'sd.plan_summary'),
  ('sd_home', 'body[3].items[0].value', 'sd.sessions_this_week'),
  ('sd_home', 'body[3].items[1].value', 'sd.falls_30d'),
  ('sd_fell', 'body[2].rows[0].label', 'sd.caregiver_call_action'),
  ('sd_safety', 'body[2].text', 'sd.safety_progress'),
  ('ea_home', 'body[1].rows[0].sub', 'ea.plan_updated'),
  ('ea_home', 'body[1].rows[1].sub', 'ea.check_back_due'),
  ('ck_list', 'body[0].text', 'ck.due_summary'),
  ('ck_uptodate', 'body[2].text', 'ck.next_due_line'),
  ('ck_day', 'body[0].text', 'ck.appointment_title'),
  ('be_tx', 'body[0].title', 'be.next_appointment'),
  ('be_survivor', 'body[3].rows[0][1]', 'be.next_follow_up'),
  ('records_hub', 'body[1].rows[0].label', 'records.source_1.name'),
  ('records_hub', 'body[1].rows[0].sub', 'records.source_1.status'),
  ('records_hub', 'body[1].rows[1].label', 'records.source_2.name'),
  ('records_hub', 'body[1].rows[1].sub', 'records.source_2.status'),
  ('records_hub', 'body[2].rows[0].sub', 'records.imported.blood_pressure'),
  ('records_hub', 'body[2].rows[1].sub', 'records.imported.labs'),
  ('records_hub', 'body[2].rows[2].sub', 'records.imported.immunizations'),
  ('records_hub', 'body[2].rows[3].sub', 'records.imported.smoking_status'),
  ('records_hub', 'body[3].title', 'records.review_count'),
  ('records_consent', 'body[0].text', 'records.connect_title'),
  ('records_review', 'body[2].text', 'records.review_banner'),
  ('records_review', 'body[9].rows[0][1]', 'records.review.units_converted'),
  ('records_review', 'body[9].rows[1][1]', 'records.review.duplicates_skipped'),
  ('records_review', 'body[9].rows[2][1]', 'records.review.held_as_typo'),
  ('records_review', 'body[9].rows[3][1]', 'records.review.future_dates_rejected'),
  ('records_conflict', 'body[0].eyebrow', 'records.conflict_1.heading'),
  ('records_conflict', 'body[1].eyebrow', 'records.conflict_2.heading'),
  ('records_conflict', 'body[1].title', 'records.conflict_2.title'),
  ('records_source', 'body[0].rows[0][1]', 'records.source.connection'),
  ('records_source', 'body[0].rows[1][1]', 'records.source.last_sync'),
  ('records_source', 'body[0].rows[2][1]', 'records.source.next_sync'),
  ('records_source', 'body[0].rows[3][1]', 'records.source.access'),
  ('records_source', 'body[0].rows[4][1]', 'records.source.connected_on'),
  ('records_disconnect', 'body[0].text', 'records.disconnect_title'),
  ('records_item', 'body[0].values', 'records.item.series'),
  ('records_item', 'body[1].rows[0].label', 'records.item.latest_1'),
  ('records_item', 'body[1].rows[0].sub', 'records.item.latest_1_source'),
  ('records_item', 'body[1].rows[1].label', 'records.item.latest_2'),
  ('records_item', 'body[1].rows[1].sub', 'records.item.latest_2_source'),
  ('records_item', 'body[1].rows[2].label', 'records.item.latest_3'),
  ('records_item', 'body[1].rows[2].sub', 'records.item.latest_3_source'),
];

/// Screens with bound values: (id, route, programme it is opened for).
const _bound = <(String, String, String?)>[
  ('today', Routes.today, null),
  ('today_offline', Routes.todayOffline, null),
  ('today_empty', Routes.todayEmpty, null),
  ('today_safety', Routes.todaySafety, null),
  ('checkin_done', Routes.checkinDone, null),
  ('rescue_pick', Routes.rescuePick, null),
  ('rescue_result', Routes.rescueResult, null),
  ('rescue_escalate', Routes.rescueEscalate, null),
  ('crisis', Routes.crisis, null),
  ('plans', Routes.plans, null),
  ('program_settings', Routes.programSettings, 'bf'),
  ('program_settings_sf', Routes.programSettingsSf, 'bf'),
  ('progress', Routes.progress, null),
  ('support', Routes.support, null),
  ('support_message', Routes.supportMessage, null),
  ('account', Routes.account, null),
  ('account_programs', Routes.accountPrograms, null),
  ('account_notifications', Routes.accountNotifications, null),
  ('account_privacy', Routes.accountPrivacy, null),
  ('account_delete', Routes.accountDelete, null),
  ('account_delete_apple', Routes.accountDeleteApple, null),
  ('account_delete_google', Routes.accountDeleteGoogle, null),
  ('account_deleted', Routes.accountDeleted, null),
  ('auth_social_new', Routes.authSocialNew, null),
  ('auth_merge', Routes.authMerge, null),
  ('bf_stepdown', Routes.bfStepdown, null),
  ('bf_support', Routes.bfSupport, null),
  ('bf_review', Routes.bfReview, null),
  ('bf_home', Routes.bfHome, null),
  ('bf_home_quitday', Routes.bfHomeQuitday, null),
  ('bf_slip', Routes.bfSlip, null),
  ('bf_progress', Routes.bfProgress, null),
  ('bf_estimates', Routes.bfEstimates, null),
  ('bf_meds', Routes.bfMeds, null),
  ('sf_goal', Routes.sfGoal, null),
  ('sf_buddy', Routes.sfBuddy, null),
  ('sf_home', Routes.sfHome, null),
  ('sf_home_unplug', Routes.sfHomeUnplug, null),
  ('sf_home_unplug_android', Routes.sfHomeUnplugAndroid, null),
  ('sf_week', Routes.sfWeek, null),
  ('sf_week_unplug', Routes.sfWeekUnplug, null),
  ('sf_unplug_apps_chosen', Routes.sfUnplugAppsChosen, null),
  ('sf_unplug_home', Routes.sfUnplugHome, null),
  ('sf_unplug_session_done', Routes.sfUnplugSessionDone, null),
  ('sf_unplug_session_done_early', Routes.sfUnplugSessionDoneEarly, null),
  ('ca_home', Routes.caHome, null),
  ('ca_yellow', Routes.caYellow, null),
  ('ca_red', Routes.caRed, null),
  ('ca_zone', Routes.caZone, null),
  ('ca_progress', Routes.caProgress, null),
  ('hw_home', Routes.hwHome, null),
  ('hw_log2', Routes.hwLog2, null),
  ('hw_result', Routes.hwResult, null),
  ('hw_crisis', Routes.hwCrisis, null),
  ('hw_trends', Routes.hwTrends, null),
  ('hw_summary', Routes.hwSummary, null),
  ('st_home', Routes.stHome, null),
  ('st_low', Routes.stLow, null),
  ('st_patterns', Routes.stPatterns, null),
  ('st_a1c', Routes.stA1c, null),
  ('re_home', Routes.reHome, null),
  ('re_history', Routes.reHistory, null),
  ('nu_home', Routes.nuHome, null),
  ('nu_week4', Routes.nuWeek4, null),
  ('sd_plan', Routes.sdPlan, null),
  ('sd_home', Routes.sdHome, null),
  ('sd_fell', Routes.sdFell, null),
  ('sd_safety', Routes.sdSafety, null),
  ('ea_home', Routes.eaHome, null),
  ('ck_list', Routes.ckList, null),
  ('ck_uptodate', Routes.ckUptodate, null),
  ('ck_day', Routes.ckDay, null),
  ('be_tx', Routes.beTx, null),
  ('be_survivor', Routes.beSurvivor, null),
  ('records_hub', Routes.recordsHub, null),
  ('records_consent', Routes.recordsConsent, null),
  ('records_review', Routes.recordsReview, null),
  ('records_conflict', Routes.recordsConflict, null),
  ('records_source', Routes.recordsSource, null),
  ('records_disconnect', Routes.recordsDisconnect, null),
  ('records_item', Routes.recordsItem, null),
];

List<Map<String, Object?>> _catalogue() {
  final json = jsonDecode(File('../spec/bindings.json').readAsStringSync()) as Map<String, Object?>;
  return [for (final r in json['bindings']! as List<Object?>) (r! as Map<Object?, Object?>).cast<String, Object?>()];
}

/// A TData for the display keys [display]: the given value per key, or
/// [fallback] (null = not loaded, TData.unset = no member value,
/// TData.example = preview). Every other key (settings controls, P-71)
/// keeps the preview answer, so only the display values change.
class _Data implements TData {
  _Data(this.values, {this.display = const <String>{}, this.fallback});
  final Map<String, Object?> values;
  final Set<String> display;
  final Object? fallback;
  @override
  ValueListenable<Object?> watch(String bindKey) => ValueNotifier<Object?>(
      values.containsKey(bindKey) ? values[bindKey] : (display.contains(bindKey) ? fallback : TData.example));
}

Future<void> _open(WidgetTester tester, String route, String? program) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  TSession.clear();
  final builder = AppRouter.screens[route]!;
  final sheet = AppRouter.sheets.contains(route);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(
        settings: RouteSettings(name: route, arguments: program == null ? null : TRouteArgs(program: program)),
        builder: (c) => sheet ? TSheetPreview(child: builder(c)) : builder(c),
      ),
    ],
  ));
  await tester.pump(const Duration(milliseconds: 50));
}

List<String> _renderedKeys(WidgetTester tester) => [
      for (final w in tester.widgetList<TBoundValues>(find.byType(TBoundValues, skipOffstage: false))) ...w.keys,
    ]..sort();

Finder _tags() => find.byType(TExampleTag, skipOffstage: false);

void main() {
  tearDown(() {
    TData.instance = PreviewData();
    TSession.clear();
  });

  test('spec/bindings.json lists exactly the generated bindings', () {
    final rows = _catalogue();
    expect([for (final r in rows) (r['screen'], r['path'], r['bind'])], _expected);
    for (final r in rows) {
      expect(r['example'], isNotNull, reason: '${r['path']}');
      expect(['text', 'series'], contains(r['type']));
      expect(r['kind'], isA<String>());
    }
  });

  testWidgets('screens without bindings render no bound element and no tag', (tester) async {
    final bound = {for (final b in _bound) b.$1};
    TData.instance = _Data({}, fallback: TData.unset);
    for (final s in AppRouter.catalog) {
      if (bound.contains(s.$1)) continue;
      await _open(tester, s.$4, null);
      expect(_renderedKeys(tester), isEmpty, reason: '${s.$1} renders a bound element not in spec/bindings.json');
      expect(_tags(), findsNothing, reason: s.$1);
    }
  });

  for (final (sid, route, program) in _bound) {
    testWidgets('$sid: bound values are listed; unset values are tagged, member and preview values are not; the session is unchanged', (tester) async {
      final rows = [for (final r in _catalogue()) if (r['screen'] == sid) r];
      final keys = [for (final r in rows) r['bind']! as String];
      final display = {for (final k in keys) TData.resolve(k, program)!};

      // Preview: the examples, no tag.
      await _open(tester, route, program);
      expect(_renderedKeys(tester), (keys.toSet().toList()..sort()), reason: 'bound keys on $sid');
      expect(_tags(), findsNothing, reason: 'preview shows no tag');
      final elements = find.byType(TBoundValues, skipOffstage: false).evaluate().length;
      final session = Map<String, Object?>.of(TSession.values);

      // Loaded, no member value: every bound element carries one tag.
      for (final fallback in [TData.unset, null]) {
        TData.instance = _Data({}, display: display, fallback: fallback);
        await _open(tester, route, program);
        expect(_tags(), findsNWidgets(elements), reason: 'every bound element is tagged ($fallback)');
        expect(TSession.values, session, reason: 'examples never enter the session');
      }

      // The member's values: shown, no tag.
      final values = <String, Object?>{};
      final shown = <String>[];
      for (final (i, r) in rows.indexed) {
        final key = TData.resolve(r['bind']! as String, program)!;
        if (r['type'] == 'series') {
          values[key] = [1, 2, 3 + i];
        } else {
          // Upper case, so an eyebrow shows it unchanged; X ends it, so M1X
          // never matches inside M11X.
          values[key] = 'M${i}X';
          shown.add('M${i}X');
        }
      }
      TData.instance = _Data(values, display: display, fallback: TData.unset);
      await _open(tester, route, program);
      expect(_tags(), findsNothing, reason: 'member values carry no tag');
      for (final t in shown) {
        expect(find.textContaining(t, skipOffstage: false), findsWidgets, reason: 'member value $t on $sid');
      }
      expect(TSession.values, session, reason: 'member display values never enter the session');
      expect(tester.takeException(), isNull);
    });
  }
}
