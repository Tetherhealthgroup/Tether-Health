// GENERATED — every screen in spec/screens.json, registered by route name.
import 'package:flutter/material.dart';

import 'routes.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/ob_programs_screen.dart';
import '../screens/onboarding/ob_focus_screen.dart';
import '../screens/onboarding/ob_third_screen.dart';
import '../screens/onboarding/ob_consent_screen.dart';
import '../screens/onboarding/ob_basics_screen.dart';
import '../screens/onboarding/ob_setup_screen.dart';
import '../screens/onboarding/ob_reminders_screen.dart';
import '../screens/onboarding/ob_reminders_denied_screen.dart';
import '../screens/onboarding/ob_account_screen.dart';
import '../screens/auth/auth_verify_screen.dart';
import '../screens/auth/auth_signin_screen.dart';
import '../screens/auth/auth_signin_error_screen.dart';
import '../screens/auth/auth_social_new_screen.dart';
import '../screens/auth/auth_link_screen.dart';
import '../screens/auth/auth_social_error_screen.dart';
import '../screens/auth/auth_forgot_screen.dart';
import '../screens/auth/auth_forgot_sent_screen.dart';
import '../screens/auth/auth_newpass_screen.dart';
import '../screens/auth/auth_merge_screen.dart';
import '../screens/auth/auth_session_screen.dart';
import '../screens/today/today_screen.dart';
import '../screens/today/today_loading_screen.dart';
import '../screens/today/today_offline_screen.dart';
import '../screens/today/today_empty_screen.dart';
import '../screens/today/today_safety_screen.dart';
import '../screens/today/checkin_screen.dart';
import '../screens/today/checkin_done_screen.dart';
import '../screens/rescue/rescue_pick_screen.dart';
import '../screens/rescue/rescue_active_screen.dart';
import '../screens/rescue/rescue_tools_screen.dart';
import '../screens/rescue/rescue_result_screen.dart';
import '../screens/rescue/rescue_escalate_screen.dart';
import '../screens/rescue/crisis_screen.dart';
import '../screens/plans/plans_screen.dart';
import '../screens/plans/catalog_screen.dart';
import '../screens/plans/focus_full_screen.dart';
import '../screens/plans/program_settings_screen.dart';
import '../screens/tabs/progress_screen.dart';
import '../screens/tabs/progress_empty_screen.dart';
import '../screens/tabs/progress_error_screen.dart';
import '../screens/tabs/learn_screen.dart';
import '../screens/tabs/learn_error_screen.dart';
import '../screens/tabs/learn_lesson_screen.dart';
import '../screens/tabs/support_screen.dart';
import '../screens/tabs/support_empty_screen.dart';
import '../screens/tabs/support_callback_screen.dart';
import '../screens/tabs/support_message_screen.dart';
import '../screens/tabs/support_message_care_screen.dart';
import '../screens/tabs/support_add_person_screen.dart';
import '../screens/tabs/support_connect_screen.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/account_signin_methods_screen.dart';
import '../screens/account/account_programs_screen.dart';
import '../screens/account/account_leave_screen.dart';
import '../screens/account/account_notifications_screen.dart';
import '../screens/account/account_privacy_screen.dart';
import '../screens/account/account_data_screen.dart';
import '../screens/account/account_delete_screen.dart';
import '../screens/account/account_deleted_screen.dart';
import '../screens/account/account_signout_screen.dart';
import '../screens/system/sys_update_screen.dart';
import '../screens/bf/bf_intro_screen.dart';
import '../screens/bf/bf_q1_screen.dart';
import '../screens/bf/bf_q2_screen.dart';
import '../screens/bf/bf_q3_screen.dart';
import '../screens/bf/bf_path_screen.dart';
import '../screens/bf/bf_date_screen.dart';
import '../screens/bf/bf_stepdown_screen.dart';
import '../screens/bf/bf_support_screen.dart';
import '../screens/bf/bf_review_screen.dart';
import '../screens/bf/bf_home_screen.dart';
import '../screens/bf/bf_home_quitday_screen.dart';
import '../screens/bf/bf_home_explore_screen.dart';
import '../screens/bf/bf_slip_screen.dart';
import '../screens/bf/bf_meds_screen.dart';
import '../screens/bf/bf_meds_edit_screen.dart';
import '../screens/bf/bf_progress_screen.dart';
import '../screens/bf/bf_estimates_screen.dart';
import '../screens/sf/sf_intro_screen.dart';
import '../screens/sf/sf_q1_screen.dart';
import '../screens/sf/sf_q2_screen.dart';
import '../screens/sf/sf_goal_screen.dart';
import '../screens/sf/sf_screentime_screen.dart';
import '../screens/sf/sf_screentime_denied_screen.dart';
import '../screens/sf/sf_buddy_screen.dart';
import '../screens/sf/sf_home_screen.dart';
import '../screens/sf/sf_pause_screen.dart';
import '../screens/sf/sf_slip_screen.dart';
import '../screens/sf/sf_week_screen.dart';
import '../screens/ca/ca_intro_screen.dart';
import '../screens/ca/ca_q1_screen.dart';
import '../screens/ca/ca_plan_screen.dart';
import '../screens/ca/ca_noplan_screen.dart';
import '../screens/ca/ca_home_screen.dart';
import '../screens/ca/ca_zone_screen.dart';
import '../screens/ca/ca_yellow_screen.dart';
import '../screens/ca/ca_red_screen.dart';
import '../screens/ca/ca_symptoms_screen.dart';
import '../screens/ca/ca_progress_screen.dart';
import '../screens/hw/hw_intro_screen.dart';
import '../screens/hw/hw_q1_screen.dart';
import '../screens/hw/hw_targets_screen.dart';
import '../screens/hw/hw_home_screen.dart';
import '../screens/hw/hw_log_screen.dart';
import '../screens/hw/hw_log2_screen.dart';
import '../screens/hw/hw_log_error_screen.dart';
import '../screens/hw/hw_result_screen.dart';
import '../screens/hw/hw_crisis_screen.dart';
import '../screens/hw/hw_recheck_screen.dart';
import '../screens/hw/hw_trends_screen.dart';
import '../screens/hw/hw_lipids_screen.dart';
import '../screens/hw/hw_summary_screen.dart';
import '../screens/st/st_intro_screen.dart';
import '../screens/st/st_q1_screen.dart';
import '../screens/st/st_range_screen.dart';
import '../screens/st/st_home_screen.dart';
import '../screens/st/st_log_screen.dart';
import '../screens/st/st_low_screen.dart';
import '../screens/st/st_reset_screen.dart';
import '../screens/st/st_patterns_screen.dart';
import '../screens/st/st_a1c_screen.dart';
import '../screens/re/re_intro_screen.dart';
import '../screens/re/re_q1_screen.dart';
import '../screens/re/re_result_screen.dart';
import '../screens/re/re_home_screen.dart';
import '../screens/re/re_labs_screen.dart';
import '../screens/re/re_history_screen.dart';
import '../screens/re/re_symptoms_screen.dart';
import '../screens/nu/nu_intro_screen.dart';
import '../screens/nu/nu_q1_screen.dart';
import '../screens/nu/nu_habit_screen.dart';
import '../screens/nu/nu_home_screen.dart';
import '../screens/nu/nu_reset_screen.dart';
import '../screens/nu/nu_week4_screen.dart';
import '../screens/nu/nu_protect_screen.dart';
import '../screens/sd/sd_intro_screen.dart';
import '../screens/sd/sd_q1_screen.dart';
import '../screens/sd/sd_plan_screen.dart';
import '../screens/sd/sd_home_screen.dart';
import '../screens/sd/sd_session_screen.dart';
import '../screens/sd/sd_fell_screen.dart';
import '../screens/sd/sd_safety_screen.dart';
import '../screens/sd/sd_caregiver_screen.dart';
import '../screens/ea/ea_intro_screen.dart';
import '../screens/ea/ea_q1_screen.dart';
import '../screens/ea/ea_result_screen.dart';
import '../screens/ea/ea_plan_screen.dart';
import '../screens/ea/ea_home_screen.dart';
import '../screens/ea/ea_mood_screen.dart';
import '../screens/ea/ea_checkback_screen.dart';
import '../screens/ck/ck_intro_screen.dart';
import '../screens/ck/ck_q1_screen.dart';
import '../screens/ck/ck_list_screen.dart';
import '../screens/ck/ck_uptodate_screen.dart';
import '../screens/ck/ck_item_screen.dart';
import '../screens/ck/ck_done_screen.dart';
import '../screens/ck/ck_day_screen.dart';
import '../screens/be/be_intro_screen.dart';
import '../screens/be/be_q1_screen.dart';
import '../screens/be/be_q2_screen.dart';
import '../screens/be/be_home_screen.dart';
import '../screens/be/be_tx_screen.dart';
import '../screens/be/be_diary_screen.dart';
import '../screens/be/be_questions_screen.dart';
import '../screens/be/be_survivor_screen.dart';
import '../screens/records/records_hub_screen.dart';
import '../screens/records/records_hub_empty_screen.dart';
import '../screens/records/records_add_screen.dart';
import '../screens/records/records_search_screen.dart';
import '../screens/records/records_fhir_url_screen.dart';
import '../screens/records/records_consent_screen.dart';
import '../screens/records/records_consent_bb_screen.dart';
import '../screens/records/records_consent_device_screen.dart';
import '../screens/records/records_importing_screen.dart';
import '../screens/records/records_review_screen.dart';
import '../screens/records/records_conflict_screen.dart';
import '../screens/records/records_error_screen.dart';
import '../screens/records/records_source_screen.dart';
import '../screens/records/records_disconnect_screen.dart';
import '../screens/records/records_manual_screen.dart';
import '../screens/records/records_manual_error_screen.dart';
import '../screens/records/records_item_screen.dart';
import '../screens/unplug/sf_unplug_intro_screen.dart';
import '../screens/unplug/sf_unplug_auth_screen.dart';
import '../screens/unplug/sf_unplug_auth_denied_screen.dart';
import '../screens/unplug/sf_unplug_auth_unavailable_screen.dart';
import '../screens/unplug/sf_unplug_auth_notifications_screen.dart';
import '../screens/unplug/sf_unplug_auth_android_screen.dart';
import '../screens/unplug/sf_unplug_apps_screen.dart';
import '../screens/unplug/sf_unplug_picker_ios_screen.dart';
import '../screens/unplug/sf_unplug_apps_android_screen.dart';
import '../screens/unplug/sf_unplug_apps_chosen_screen.dart';
import '../screens/unplug/sf_unplug_limits_screen.dart';
import '../screens/unplug/sf_unplug_home_screen.dart';
import '../screens/unplug/sf_unplug_session_screen.dart';
import '../screens/unplug/sf_unplug_session_active_screen.dart';
import '../screens/unplug/sf_unplug_session_end_screen.dart';
import '../screens/unplug/sf_unplug_session_done_screen.dart';
import '../screens/unplug/sf_unplug_session_done_early_screen.dart';
import '../screens/unplug/sf_unplug_shield_screen.dart';
import '../screens/unplug/sf_unplug_shield_firm_screen.dart';
import '../screens/unplug/sf_unplug_overlay_screen.dart';
import '../screens/unplug/sf_unplug_gate_screen.dart';
import '../screens/unplug/sf_unplug_gate_commit_screen.dart';
import '../screens/unplug/sf_unplug_gate_sum_screen.dart';
import '../screens/unplug/sf_unplug_health_screen.dart';
import '../screens/unplug/sf_unplug_health_notifications_screen.dart';
import '../screens/unplug/sf_unplug_health_stopped_screen.dart';
import '../screens/unplug/sf_unplug_health_android_screen.dart';
import '../screens/unplug/sf_unplug_off_screen.dart';
import '../screens/sf/sf_home_unplug_screen.dart';
import '../screens/sf/sf_week_unplug_screen.dart';
import '../screens/plans/program_settings_sf_screen.dart';
import '../screens/account/account_delete_apple_screen.dart';
import '../screens/account/account_delete_google_screen.dart';
import '../screens/auth/auth_session_apple_screen.dart';
import '../screens/auth/auth_session_google_screen.dart';
import '../screens/sf/sf_screentime_android_screen.dart';
import '../screens/sf/sf_screentime_android_denied_screen.dart';
import '../screens/system/sys_update_android_screen.dart';
import '../screens/entries/surface_widget_ios_screen.dart';
import '../screens/entries/surface_widget_android_screen.dart';
import '../screens/entries/surface_shortcuts_ios_screen.dart';
import '../screens/entries/surface_shortcuts_ios_named_screen.dart';
import '../screens/entries/surface_shortcuts_android_screen.dart';
import '../screens/entries/surface_shortcuts_android_named_screen.dart';

abstract final class AppRouter {
  static final Map<String, WidgetBuilder> screens = <String, WidgetBuilder>{
    Routes.welcome: (_) => const WelcomeScreen(),
    Routes.obPrograms: (_) => const ObProgramsScreen(),
    Routes.obFocus: (_) => const ObFocusScreen(),
    Routes.obThird: (_) => const ObThirdScreen(),
    Routes.obConsent: (_) => const ObConsentScreen(),
    Routes.obBasics: (_) => const ObBasicsScreen(),
    Routes.obSetup: (_) => const ObSetupScreen(),
    Routes.obReminders: (_) => const ObRemindersScreen(),
    Routes.obRemindersDenied: (_) => const ObRemindersDeniedScreen(),
    Routes.obAccount: (_) => const ObAccountScreen(),
    Routes.authVerify: (_) => const AuthVerifyScreen(),
    Routes.authSignin: (_) => const AuthSigninScreen(),
    Routes.authSigninError: (_) => const AuthSigninErrorScreen(),
    Routes.authSocialNew: (_) => const AuthSocialNewScreen(),
    Routes.authLink: (_) => const AuthLinkScreen(),
    Routes.authSocialError: (_) => const AuthSocialErrorScreen(),
    Routes.authForgot: (_) => const AuthForgotScreen(),
    Routes.authForgotSent: (_) => const AuthForgotSentScreen(),
    Routes.authNewpass: (_) => const AuthNewpassScreen(),
    Routes.authMerge: (_) => const AuthMergeScreen(),
    Routes.authSession: (_) => const AuthSessionScreen(),
    Routes.today: (_) => const TodayScreen(),
    Routes.todayLoading: (_) => const TodayLoadingScreen(),
    Routes.todayOffline: (_) => const TodayOfflineScreen(),
    Routes.todayEmpty: (_) => const TodayEmptyScreen(),
    Routes.todaySafety: (_) => const TodaySafetyScreen(),
    Routes.checkin: (_) => const CheckinScreen(),
    Routes.checkinDone: (_) => const CheckinDoneScreen(),
    Routes.rescuePick: (_) => const RescuePickScreen(),
    Routes.rescueActive: (_) => const RescueActiveScreen(),
    Routes.rescueTools: (_) => const RescueToolsScreen(),
    Routes.rescueResult: (_) => const RescueResultScreen(),
    Routes.rescueEscalate: (_) => const RescueEscalateScreen(),
    Routes.crisis: (_) => const CrisisScreen(),
    Routes.plans: (_) => const PlansScreen(),
    Routes.catalog: (_) => const CatalogScreen(),
    Routes.focusFull: (_) => const FocusFullScreen(),
    Routes.programSettings: (_) => const ProgramSettingsScreen(),
    Routes.progress: (_) => const ProgressScreen(),
    Routes.progressEmpty: (_) => const ProgressEmptyScreen(),
    Routes.progressError: (_) => const ProgressErrorScreen(),
    Routes.learn: (_) => const LearnScreen(),
    Routes.learnError: (_) => const LearnErrorScreen(),
    Routes.learnLesson: (_) => const LearnLessonScreen(),
    Routes.support: (_) => const SupportScreen(),
    Routes.supportEmpty: (_) => const SupportEmptyScreen(),
    Routes.supportCallback: (_) => const SupportCallbackScreen(),
    Routes.supportMessage: (_) => const SupportMessageScreen(),
    Routes.supportMessageCare: (_) => const SupportMessageCareScreen(),
    Routes.supportAddPerson: (_) => const SupportAddPersonScreen(),
    Routes.supportConnect: (_) => const SupportConnectScreen(),
    Routes.account: (_) => const AccountScreen(),
    Routes.accountSigninMethods: (_) => const AccountSigninMethodsScreen(),
    Routes.accountPrograms: (_) => const AccountProgramsScreen(),
    Routes.accountLeave: (_) => const AccountLeaveScreen(),
    Routes.accountNotifications: (_) => const AccountNotificationsScreen(),
    Routes.accountPrivacy: (_) => const AccountPrivacyScreen(),
    Routes.accountData: (_) => const AccountDataScreen(),
    Routes.accountDelete: (_) => const AccountDeleteScreen(),
    Routes.accountDeleted: (_) => const AccountDeletedScreen(),
    Routes.accountSignout: (_) => const AccountSignoutScreen(),
    Routes.sysUpdate: (_) => const SysUpdateScreen(),
    Routes.bfIntro: (_) => const BfIntroScreen(),
    Routes.bfQ1: (_) => const BfQ1Screen(),
    Routes.bfQ2: (_) => const BfQ2Screen(),
    Routes.bfQ3: (_) => const BfQ3Screen(),
    Routes.bfPath: (_) => const BfPathScreen(),
    Routes.bfDate: (_) => const BfDateScreen(),
    Routes.bfStepdown: (_) => const BfStepdownScreen(),
    Routes.bfSupport: (_) => const BfSupportScreen(),
    Routes.bfReview: (_) => const BfReviewScreen(),
    Routes.bfHome: (_) => const BfHomeScreen(),
    Routes.bfHomeQuitday: (_) => const BfHomeQuitdayScreen(),
    Routes.bfHomeExplore: (_) => const BfHomeExploreScreen(),
    Routes.bfSlip: (_) => const BfSlipScreen(),
    Routes.bfMeds: (_) => const BfMedsScreen(),
    Routes.bfMedsEdit: (_) => const BfMedsEditScreen(),
    Routes.bfProgress: (_) => const BfProgressScreen(),
    Routes.bfEstimates: (_) => const BfEstimatesScreen(),
    Routes.sfIntro: (_) => const SfIntroScreen(),
    Routes.sfQ1: (_) => const SfQ1Screen(),
    Routes.sfQ2: (_) => const SfQ2Screen(),
    Routes.sfGoal: (_) => const SfGoalScreen(),
    Routes.sfScreentime: (_) => const SfScreentimeScreen(),
    Routes.sfScreentimeDenied: (_) => const SfScreentimeDeniedScreen(),
    Routes.sfBuddy: (_) => const SfBuddyScreen(),
    Routes.sfHome: (_) => const SfHomeScreen(),
    Routes.sfPause: (_) => const SfPauseScreen(),
    Routes.sfSlip: (_) => const SfSlipScreen(),
    Routes.sfWeek: (_) => const SfWeekScreen(),
    Routes.caIntro: (_) => const CaIntroScreen(),
    Routes.caQ1: (_) => const CaQ1Screen(),
    Routes.caPlan: (_) => const CaPlanScreen(),
    Routes.caNoplan: (_) => const CaNoplanScreen(),
    Routes.caHome: (_) => const CaHomeScreen(),
    Routes.caZone: (_) => const CaZoneScreen(),
    Routes.caYellow: (_) => const CaYellowScreen(),
    Routes.caRed: (_) => const CaRedScreen(),
    Routes.caSymptoms: (_) => const CaSymptomsScreen(),
    Routes.caProgress: (_) => const CaProgressScreen(),
    Routes.hwIntro: (_) => const HwIntroScreen(),
    Routes.hwQ1: (_) => const HwQ1Screen(),
    Routes.hwTargets: (_) => const HwTargetsScreen(),
    Routes.hwHome: (_) => const HwHomeScreen(),
    Routes.hwLog: (_) => const HwLogScreen(),
    Routes.hwLog2: (_) => const HwLog2Screen(),
    Routes.hwLogError: (_) => const HwLogErrorScreen(),
    Routes.hwResult: (_) => const HwResultScreen(),
    Routes.hwCrisis: (_) => const HwCrisisScreen(),
    Routes.hwRecheck: (_) => const HwRecheckScreen(),
    Routes.hwTrends: (_) => const HwTrendsScreen(),
    Routes.hwLipids: (_) => const HwLipidsScreen(),
    Routes.hwSummary: (_) => const HwSummaryScreen(),
    Routes.stIntro: (_) => const StIntroScreen(),
    Routes.stQ1: (_) => const StQ1Screen(),
    Routes.stRange: (_) => const StRangeScreen(),
    Routes.stHome: (_) => const StHomeScreen(),
    Routes.stLog: (_) => const StLogScreen(),
    Routes.stLow: (_) => const StLowScreen(),
    Routes.stReset: (_) => const StResetScreen(),
    Routes.stPatterns: (_) => const StPatternsScreen(),
    Routes.stA1c: (_) => const StA1cScreen(),
    Routes.reIntro: (_) => const ReIntroScreen(),
    Routes.reQ1: (_) => const ReQ1Screen(),
    Routes.reResult: (_) => const ReResultScreen(),
    Routes.reHome: (_) => const ReHomeScreen(),
    Routes.reLabs: (_) => const ReLabsScreen(),
    Routes.reHistory: (_) => const ReHistoryScreen(),
    Routes.reSymptoms: (_) => const ReSymptomsScreen(),
    Routes.nuIntro: (_) => const NuIntroScreen(),
    Routes.nuQ1: (_) => const NuQ1Screen(),
    Routes.nuHabit: (_) => const NuHabitScreen(),
    Routes.nuHome: (_) => const NuHomeScreen(),
    Routes.nuReset: (_) => const NuResetScreen(),
    Routes.nuWeek4: (_) => const NuWeek4Screen(),
    Routes.nuProtect: (_) => const NuProtectScreen(),
    Routes.sdIntro: (_) => const SdIntroScreen(),
    Routes.sdQ1: (_) => const SdQ1Screen(),
    Routes.sdPlan: (_) => const SdPlanScreen(),
    Routes.sdHome: (_) => const SdHomeScreen(),
    Routes.sdSession: (_) => const SdSessionScreen(),
    Routes.sdFell: (_) => const SdFellScreen(),
    Routes.sdSafety: (_) => const SdSafetyScreen(),
    Routes.sdCaregiver: (_) => const SdCaregiverScreen(),
    Routes.eaIntro: (_) => const EaIntroScreen(),
    Routes.eaQ1: (_) => const EaQ1Screen(),
    Routes.eaResult: (_) => const EaResultScreen(),
    Routes.eaPlan: (_) => const EaPlanScreen(),
    Routes.eaHome: (_) => const EaHomeScreen(),
    Routes.eaMood: (_) => const EaMoodScreen(),
    Routes.eaCheckback: (_) => const EaCheckbackScreen(),
    Routes.ckIntro: (_) => const CkIntroScreen(),
    Routes.ckQ1: (_) => const CkQ1Screen(),
    Routes.ckList: (_) => const CkListScreen(),
    Routes.ckUptodate: (_) => const CkUptodateScreen(),
    Routes.ckItem: (_) => const CkItemScreen(),
    Routes.ckDone: (_) => const CkDoneScreen(),
    Routes.ckDay: (_) => const CkDayScreen(),
    Routes.beIntro: (_) => const BeIntroScreen(),
    Routes.beQ1: (_) => const BeQ1Screen(),
    Routes.beQ2: (_) => const BeQ2Screen(),
    Routes.beHome: (_) => const BeHomeScreen(),
    Routes.beTx: (_) => const BeTxScreen(),
    Routes.beDiary: (_) => const BeDiaryScreen(),
    Routes.beQuestions: (_) => const BeQuestionsScreen(),
    Routes.beSurvivor: (_) => const BeSurvivorScreen(),
    Routes.recordsHub: (_) => const RecordsHubScreen(),
    Routes.recordsHubEmpty: (_) => const RecordsHubEmptyScreen(),
    Routes.recordsAdd: (_) => const RecordsAddScreen(),
    Routes.recordsSearch: (_) => const RecordsSearchScreen(),
    Routes.recordsFhirUrl: (_) => const RecordsFhirUrlScreen(),
    Routes.recordsConsent: (_) => const RecordsConsentScreen(),
    Routes.recordsConsentBb: (_) => const RecordsConsentBbScreen(),
    Routes.recordsConsentDevice: (_) => const RecordsConsentDeviceScreen(),
    Routes.recordsImporting: (_) => const RecordsImportingScreen(),
    Routes.recordsReview: (_) => const RecordsReviewScreen(),
    Routes.recordsConflict: (_) => const RecordsConflictScreen(),
    Routes.recordsError: (_) => const RecordsErrorScreen(),
    Routes.recordsSource: (_) => const RecordsSourceScreen(),
    Routes.recordsDisconnect: (_) => const RecordsDisconnectScreen(),
    Routes.recordsManual: (_) => const RecordsManualScreen(),
    Routes.recordsManualError: (_) => const RecordsManualErrorScreen(),
    Routes.recordsItem: (_) => const RecordsItemScreen(),
    Routes.sfUnplugIntro: (_) => const SfUnplugIntroScreen(),
    Routes.sfUnplugAuth: (_) => const SfUnplugAuthScreen(),
    Routes.sfUnplugAuthDenied: (_) => const SfUnplugAuthDeniedScreen(),
    Routes.sfUnplugAuthUnavailable: (_) => const SfUnplugAuthUnavailableScreen(),
    Routes.sfUnplugAuthNotifications: (_) => const SfUnplugAuthNotificationsScreen(),
    Routes.sfUnplugAuthAndroid: (_) => const SfUnplugAuthAndroidScreen(),
    Routes.sfUnplugApps: (_) => const SfUnplugAppsScreen(),
    Routes.sfUnplugPickerIos: (_) => const SfUnplugPickerIosScreen(),
    Routes.sfUnplugAppsAndroid: (_) => const SfUnplugAppsAndroidScreen(),
    Routes.sfUnplugAppsChosen: (_) => const SfUnplugAppsChosenScreen(),
    Routes.sfUnplugLimits: (_) => const SfUnplugLimitsScreen(),
    Routes.sfUnplugHome: (_) => const SfUnplugHomeScreen(),
    Routes.sfUnplugSession: (_) => const SfUnplugSessionScreen(),
    Routes.sfUnplugSessionActive: (_) => const SfUnplugSessionActiveScreen(),
    Routes.sfUnplugSessionEnd: (_) => const SfUnplugSessionEndScreen(),
    Routes.sfUnplugSessionDone: (_) => const SfUnplugSessionDoneScreen(),
    Routes.sfUnplugSessionDoneEarly: (_) => const SfUnplugSessionDoneEarlyScreen(),
    Routes.sfUnplugShield: (_) => const SfUnplugShieldScreen(),
    Routes.sfUnplugShieldFirm: (_) => const SfUnplugShieldFirmScreen(),
    Routes.sfUnplugOverlay: (_) => const SfUnplugOverlayScreen(),
    Routes.sfUnplugGate: (_) => const SfUnplugGateScreen(),
    Routes.sfUnplugGateCommit: (_) => const SfUnplugGateCommitScreen(),
    Routes.sfUnplugGateSum: (_) => const SfUnplugGateSumScreen(),
    Routes.sfUnplugHealth: (_) => const SfUnplugHealthScreen(),
    Routes.sfUnplugHealthNotifications: (_) => const SfUnplugHealthNotificationsScreen(),
    Routes.sfUnplugHealthStopped: (_) => const SfUnplugHealthStoppedScreen(),
    Routes.sfUnplugHealthAndroid: (_) => const SfUnplugHealthAndroidScreen(),
    Routes.sfUnplugOff: (_) => const SfUnplugOffScreen(),
    Routes.sfHomeUnplug: (_) => const SfHomeUnplugScreen(),
    Routes.sfWeekUnplug: (_) => const SfWeekUnplugScreen(),
    Routes.programSettingsSf: (_) => const ProgramSettingsSfScreen(),
    Routes.accountDeleteApple: (_) => const AccountDeleteAppleScreen(),
    Routes.accountDeleteGoogle: (_) => const AccountDeleteGoogleScreen(),
    Routes.authSessionApple: (_) => const AuthSessionAppleScreen(),
    Routes.authSessionGoogle: (_) => const AuthSessionGoogleScreen(),
    Routes.sfScreentimeAndroid: (_) => const SfScreentimeAndroidScreen(),
    Routes.sfScreentimeAndroidDenied: (_) => const SfScreentimeAndroidDeniedScreen(),
    Routes.sysUpdateAndroid: (_) => const SysUpdateAndroidScreen(),
    Routes.surfaceWidgetIos: (_) => const SurfaceWidgetIosScreen(),
    Routes.surfaceWidgetAndroid: (_) => const SurfaceWidgetAndroidScreen(),
    Routes.surfaceShortcutsIos: (_) => const SurfaceShortcutsIosScreen(),
    Routes.surfaceShortcutsIosNamed: (_) => const SurfaceShortcutsIosNamedScreen(),
    Routes.surfaceShortcutsAndroid: (_) => const SurfaceShortcutsAndroidScreen(),
    Routes.surfaceShortcutsAndroidNamed: (_) => const SurfaceShortcutsAndroidNamedScreen(),
  };

  /// Routes presented as modal bottom sheets.
  static const Set<String> sheets = {Routes.obThird, Routes.authSignin, Routes.authSigninError, Routes.authMerge, Routes.authSession, Routes.checkin, Routes.rescuePick, Routes.rescueTools, Routes.focusFull, Routes.supportCallback, Routes.supportMessage, Routes.accountLeave, Routes.accountSignout, Routes.bfEstimates, Routes.recordsDisconnect, Routes.sfUnplugPickerIos, Routes.sfUnplugSessionEnd, Routes.sfUnplugOff, Routes.authSessionApple, Routes.authSessionGoogle};

  static const Map<String, String> tabRoutes = {'today': Routes.today, 'plans': Routes.plans, 'progress': Routes.progress, 'learn': Routes.learn, 'support': Routes.support};

  /// (id, name, flow title, route) — drives the dev gallery and tests.
  static const List<(String, String, String, String)> catalog = [
    ('welcome', 'Welcome', 'First run', Routes.welcome),
    ('ob_programs', 'Choose programs', 'First run', Routes.obPrograms),
    ('ob_focus', 'Focus slots', 'First run', Routes.obFocus),
    ('ob_third', 'Third program sheet', 'First run', Routes.obThird),
    ('ob_consent', 'Layered consent', 'First run', Routes.obConsent),
    ('ob_basics', 'Shared basics', 'First run', Routes.obBasics),
    ('ob_setup', 'Set up focus programs', 'First run', Routes.obSetup),
    ('ob_reminders', 'Reminder prime', 'First run', Routes.obReminders),
    ('ob_reminders_denied', 'Reminders denied · permission denied', 'First run', Routes.obRemindersDenied),
    ('ob_account', 'Save your progress', 'First run', Routes.obAccount),
    ('auth_verify', 'Verify email', 'Account & sign-in', Routes.authVerify),
    ('auth_signin', 'Sign in', 'Account & sign-in', Routes.authSignin),
    ('auth_signin_error', 'Sign-in error · error', 'Account & sign-in', Routes.authSigninError),
    ('auth_social_new', 'New account from Apple or Google', 'Account & sign-in', Routes.authSocialNew),
    ('auth_link', 'Link accounts', 'Account & sign-in', Routes.authLink),
    ('auth_social_error', 'Apple / Google sign-in failed', 'Account & sign-in', Routes.authSocialError),
    ('auth_forgot', 'Reset password', 'Account & sign-in', Routes.authForgot),
    ('auth_forgot_sent', 'Reset link sent', 'Account & sign-in', Routes.authForgotSent),
    ('auth_newpass', 'Set new password', 'Account & sign-in', Routes.authNewpass),
    ('auth_merge', 'Guest plan merge', 'Account & sign-in', Routes.authMerge),
    ('auth_session', 'Session expired', 'Account & sign-in', Routes.authSession),
    ('today', 'Today', 'Today', Routes.today),
    ('today_loading', 'Today · loading · loading', 'Today', Routes.todayLoading),
    ('today_offline', 'Today · offline · offline', 'Today', Routes.todayOffline),
    ('today_empty', 'Today · nothing in focus · empty', 'Today', Routes.todayEmpty),
    ('today_safety', 'Today · safety pinned · safety', 'Today', Routes.todaySafety),
    ('checkin', 'Daily check-in', 'Today', Routes.checkin),
    ('checkin_done', 'Check-in saved', 'Today', Routes.checkinDone),
    ('rescue_pick', 'Rescue', 'Universal Rescue', Routes.rescuePick),
    ('rescue_active', 'Active tool', 'Universal Rescue', Routes.rescueActive),
    ('rescue_tools', 'Switch tool', 'Universal Rescue', Routes.rescueTools),
    ('rescue_result', 'Recheck + result', 'Universal Rescue', Routes.rescueResult),
    ('rescue_escalate', 'Add a person', 'Universal Rescue', Routes.rescueEscalate),
    ('crisis', 'Crisis support', 'Universal Rescue', Routes.crisis),
    ('plans', 'My plans', 'Plans & programs', Routes.plans),
    ('catalog', 'Add a program', 'Plans & programs', Routes.catalog),
    ('focus_full', 'Focus slots full', 'Plans & programs', Routes.focusFull),
    ('program_settings', 'Program settings', 'Plans & programs', Routes.programSettings),
    ('progress', 'Progress', 'Progress, Learn & Support', Routes.progress),
    ('progress_empty', 'Progress · empty · empty', 'Progress, Learn & Support', Routes.progressEmpty),
    ('progress_error', 'Progress · error · error', 'Progress, Learn & Support', Routes.progressError),
    ('learn', 'Learn', 'Progress, Learn & Support', Routes.learn),
    ('learn_error', 'Learn · error · error', 'Progress, Learn & Support', Routes.learnError),
    ('learn_lesson', 'Lesson', 'Progress, Learn & Support', Routes.learnLesson),
    ('support', 'Support', 'Progress, Learn & Support', Routes.support),
    ('support_empty', 'Support · empty · empty', 'Progress, Learn & Support', Routes.supportEmpty),
    ('support_callback', 'Request call-back', 'Progress, Learn & Support', Routes.supportCallback),
    ('support_message', 'Preview message', 'Progress, Learn & Support', Routes.supportMessage),
    ('support_message_care', 'Message care team', 'Progress, Learn & Support', Routes.supportMessageCare),
    ('support_add_person', 'Add a supporter', 'Progress, Learn & Support', Routes.supportAddPerson),
    ('support_connect', 'Connect a clinic', 'Progress, Learn & Support', Routes.supportConnect),
    ('account', 'Account', 'Account & data', Routes.account),
    ('account_signin_methods', 'Sign-in methods', 'Account & data', Routes.accountSigninMethods),
    ('account_programs', 'Programs & sharing', 'Account & data', Routes.accountPrograms),
    ('account_leave', 'Leave a program', 'Account & data', Routes.accountLeave),
    ('account_notifications', 'Notifications', 'Account & data', Routes.accountNotifications),
    ('account_privacy', 'Privacy & consent', 'Account & data', Routes.accountPrivacy),
    ('account_data', 'Your data', 'Account & data', Routes.accountData),
    ('account_delete', 'Delete account', 'Account & data', Routes.accountDelete),
    ('account_deleted', 'Deletion receipt', 'Account & data', Routes.accountDeleted),
    ('account_signout', 'Sign out', 'Account & data', Routes.accountSignout),
    ('sys_update', 'Update required', 'System states', Routes.sysUpdate),
    ('bf_intro', 'BreatheFree intro', 'BreatheFree', Routes.bfIntro),
    ('bf_q1', 'Baseline: amount', 'BreatheFree', Routes.bfQ1),
    ('bf_q2', 'Baseline: triggers', 'BreatheFree', Routes.bfQ2),
    ('bf_q3', 'Baseline: reasons', 'BreatheFree', Routes.bfQ3),
    ('bf_path', 'Choose path', 'BreatheFree', Routes.bfPath),
    ('bf_date', 'Select quit date', 'BreatheFree', Routes.bfDate),
    ('bf_stepdown', 'Step-down schedule', 'BreatheFree', Routes.bfStepdown),
    ('bf_support', 'Support & preparation', 'BreatheFree', Routes.bfSupport),
    ('bf_review', 'Review plan', 'BreatheFree', Routes.bfReview),
    ('bf_home', 'BreatheFree home', 'BreatheFree', Routes.bfHome),
    ('bf_home_quitday', 'BreatheFree · quit day · quit day', 'BreatheFree', Routes.bfHomeQuitday),
    ('bf_home_explore', 'BreatheFree · explore · explore', 'BreatheFree', Routes.bfHomeExplore),
    ('bf_slip', 'Slip recovery', 'BreatheFree', Routes.bfSlip),
    ('bf_meds', 'Medication center', 'BreatheFree', Routes.bfMeds),
    ('bf_meds_edit', 'Edit recorded plan', 'BreatheFree', Routes.bfMedsEdit),
    ('bf_progress', 'BreatheFree progress', 'BreatheFree', Routes.bfProgress),
    ('bf_estimates', 'How estimates work', 'BreatheFree', Routes.bfEstimates),
    ('sf_intro', 'ScrollFree intro', 'ScrollFree', Routes.sfIntro),
    ('sf_q1', 'Baseline: use', 'ScrollFree', Routes.sfQ1),
    ('sf_q2', 'Baseline: triggers', 'ScrollFree', Routes.sfQ2),
    ('sf_goal', 'Goal & windows', 'ScrollFree', Routes.sfGoal),
    ('sf_screentime', 'Connect Screen Time', 'ScrollFree', Routes.sfScreentime),
    ('sf_screentime_denied', 'Screen Time denied · permission denied', 'ScrollFree', Routes.sfScreentimeDenied),
    ('sf_buddy', 'Accountability buddy', 'ScrollFree', Routes.sfBuddy),
    ('sf_home', 'ScrollFree home', 'ScrollFree', Routes.sfHome),
    ('sf_pause', 'Pause 60', 'ScrollFree', Routes.sfPause),
    ('sf_slip', 'Long-scroll recovery', 'ScrollFree', Routes.sfSlip),
    ('sf_week', 'Weekly reflection', 'ScrollFree', Routes.sfWeek),
    ('ca_intro', 'ClearAir intro', 'ClearAir', Routes.caIntro),
    ('ca_q1', 'Diagnosis & plan', 'ClearAir', Routes.caQ1),
    ('ca_plan', 'Enter action plan', 'ClearAir', Routes.caPlan),
    ('ca_noplan', 'No action plan yet · empty', 'ClearAir', Routes.caNoplan),
    ('ca_home', 'ClearAir home', 'ClearAir', Routes.caHome),
    ('ca_zone', 'Zone check', 'ClearAir', Routes.caZone),
    ('ca_yellow', 'Yellow zone', 'ClearAir', Routes.caYellow),
    ('ca_red', 'Red zone', 'ClearAir', Routes.caRed),
    ('ca_symptoms', 'Symptom log', 'ClearAir', Routes.caSymptoms),
    ('ca_progress', 'ClearAir progress', 'ClearAir', Routes.caProgress),
    ('hw_intro', 'Heartwise intro', 'Heartwise', Routes.hwIntro),
    ('hw_q1', 'Baseline', 'Heartwise', Routes.hwQ1),
    ('hw_targets', 'Clinician targets', 'Heartwise', Routes.hwTargets),
    ('hw_home', 'Heartwise home', 'Heartwise', Routes.hwHome),
    ('hw_log', 'Log BP · reading 1', 'Heartwise', Routes.hwLog),
    ('hw_log2', 'Log BP · reading 2', 'Heartwise', Routes.hwLog2),
    ('hw_log_error', 'Log BP · validation · error', 'Heartwise', Routes.hwLogError),
    ('hw_result', 'Reading saved', 'Heartwise', Routes.hwResult),
    ('hw_crisis', 'Crisis range', 'Heartwise', Routes.hwCrisis),
    ('hw_recheck', 'Re-check timer', 'Heartwise', Routes.hwRecheck),
    ('hw_trends', 'Trends', 'Heartwise', Routes.hwTrends),
    ('hw_lipids', 'Cholesterol panel', 'Heartwise', Routes.hwLipids),
    ('hw_summary', 'Visit summary', 'Heartwise', Routes.hwSummary),
    ('st_intro', 'Steady intro', 'Steady', Routes.stIntro),
    ('st_q1', 'Type & device', 'Steady', Routes.stQ1),
    ('st_range', 'Range & low plan', 'Steady', Routes.stRange),
    ('st_home', 'Steady home', 'Steady', Routes.stHome),
    ('st_log', 'Log reading', 'Steady', Routes.stLog),
    ('st_low', 'Low reading', 'Steady', Routes.stLow),
    ('st_reset', 'Meal energy reset', 'Steady', Routes.stReset),
    ('st_patterns', 'Patterns', 'Steady', Routes.stPatterns),
    ('st_a1c', 'A1C', 'Steady', Routes.stA1c),
    ('re_intro', 'Renew intro', 'Renew', Routes.reIntro),
    ('re_q1', 'Risk check', 'Renew', Routes.reQ1),
    ('re_result', 'Risk result', 'Renew', Routes.reResult),
    ('re_home', 'Renew home', 'Renew', Routes.reHome),
    ('re_labs', 'Add labs', 'Renew', Routes.reLabs),
    ('re_history', 'Lab history', 'Renew', Routes.reHistory),
    ('re_symptoms', 'Symptom check', 'Renew', Routes.reSymptoms),
    ('nu_intro', 'Nourish intro', 'Nourish', Routes.nuIntro),
    ('nu_q1', 'Goals & screen', 'Nourish', Routes.nuQ1),
    ('nu_habit', 'Weekly habit', 'Nourish', Routes.nuHabit),
    ('nu_home', 'Nourish home', 'Nourish', Routes.nuHome),
    ('nu_reset', 'Off-track reset', 'Nourish', Routes.nuReset),
    ('nu_week4', 'Week 4 milestone', 'Nourish', Routes.nuWeek4),
    ('nu_protect', 'Protective mode', 'Nourish', Routes.nuProtect),
    ('sd_intro', 'Stride intro', 'Stride', Routes.sdIntro),
    ('sd_q1', 'Falls check', 'Stride', Routes.sdQ1),
    ('sd_plan', 'Movement plan', 'Stride', Routes.sdPlan),
    ('sd_home', 'Stride home', 'Stride', Routes.sdHome),
    ('sd_session', 'Session player', 'Stride', Routes.sdSession),
    ('sd_fell', 'I fell', 'Stride', Routes.sdFell),
    ('sd_safety', 'Home safety', 'Stride', Routes.sdSafety),
    ('sd_caregiver', 'Caregiver access', 'Stride', Routes.sdCaregiver),
    ('ea_intro', 'Ease intro', 'Ease', Routes.eaIntro),
    ('ea_q1', 'Optional screener', 'Ease', Routes.eaQ1),
    ('ea_result', 'Screener result', 'Ease', Routes.eaResult),
    ('ea_plan', 'Safety plan', 'Ease', Routes.eaPlan),
    ('ea_home', 'Ease home', 'Ease', Routes.eaHome),
    ('ea_mood', 'Mood check-in', 'Ease', Routes.eaMood),
    ('ea_checkback', 'Check-back day', 'Ease', Routes.eaCheckback),
    ('ck_intro', 'Checkup intro', 'Checkup', Routes.ckIntro),
    ('ck_q1', 'About you', 'Checkup', Routes.ckQ1),
    ('ck_list', 'Due list', 'Checkup', Routes.ckList),
    ('ck_uptodate', 'Up to date · empty', 'Checkup', Routes.ckUptodate),
    ('ck_item', 'Item detail', 'Checkup', Routes.ckItem),
    ('ck_done', 'Mark done', 'Checkup', Routes.ckDone),
    ('ck_day', 'Screening day', 'Checkup', Routes.ckDay),
    ('be_intro', 'Beacon intro', 'Beacon', Routes.beIntro),
    ('be_q1', 'Journey stage', 'Beacon', Routes.beQ1),
    ('be_q2', 'Family history', 'Beacon', Routes.beQ2),
    ('be_home', 'Beacon home', 'Beacon', Routes.beHome),
    ('be_tx', 'Treatment support', 'Beacon', Routes.beTx),
    ('be_diary', 'Treatment diary', 'Beacon', Routes.beDiary),
    ('be_questions', 'Visit questions', 'Beacon', Routes.beQuestions),
    ('be_survivor', 'Survivorship', 'Beacon', Routes.beSurvivor),
    ('records_hub', 'Health records', 'Health records (FHIR & manual)', Routes.recordsHub),
    ('records_hub_empty', 'Health records · empty · empty', 'Health records (FHIR & manual)', Routes.recordsHubEmpty),
    ('records_add', 'Add a source', 'Health records (FHIR & manual)', Routes.recordsAdd),
    ('records_search', 'Find your provider', 'Health records (FHIR & manual)', Routes.recordsSearch),
    ('records_fhir_url', 'Other FHIR server', 'Health records (FHIR & manual)', Routes.recordsFhirUrl),
    ('records_consent', 'Consent: Epic', 'Health records (FHIR & manual)', Routes.recordsConsent),
    ('records_consent_bb', 'Consent: Medicare · Medicare', 'Health records (FHIR & manual)', Routes.recordsConsentBb),
    ('records_consent_device', 'Consent: phone health data · Apple Health / Health Connect', 'Health records (FHIR & manual)', Routes.recordsConsentDevice),
    ('records_importing', 'Importing', 'Health records (FHIR & manual)', Routes.recordsImporting),
    ('records_review', 'Review imported data', 'Health records (FHIR & manual)', Routes.recordsReview),
    ('records_conflict', 'Resolve conflicts', 'Health records (FHIR & manual)', Routes.recordsConflict),
    ('records_error', 'Connection problem', 'Health records (FHIR & manual)', Routes.recordsError),
    ('records_source', 'Source details', 'Health records (FHIR & manual)', Routes.recordsSource),
    ('records_disconnect', 'Disconnect source', 'Health records (FHIR & manual)', Routes.recordsDisconnect),
    ('records_manual', 'Enter a value', 'Health records (FHIR & manual)', Routes.recordsManual),
    ('records_manual_error', 'Enter a value · out of range · error', 'Health records (FHIR & manual)', Routes.recordsManualError),
    ('records_item', 'Imported values', 'Health records (FHIR & manual)', Routes.recordsItem),
    ('sf_unplug_intro', 'Unplug intro', 'ScrollFree · Unplug', Routes.sfUnplugIntro),
    ('sf_unplug_auth', 'Allow Screen Time', 'ScrollFree · Unplug', Routes.sfUnplugAuth),
    ('sf_unplug_auth_denied', 'Screen Time not allowed · permission denied', 'ScrollFree · Unplug', Routes.sfUnplugAuthDenied),
    ('sf_unplug_auth_unavailable', 'Screen Time unavailable · unavailable', 'ScrollFree · Unplug', Routes.sfUnplugAuthUnavailable),
    ('sf_unplug_auth_notifications', 'Notifications off · notifications off', 'ScrollFree · Unplug', Routes.sfUnplugAuthNotifications),
    ('sf_unplug_auth_android', 'Android permissions for Unplug · android', 'ScrollFree · Unplug', Routes.sfUnplugAuthAndroid),
    ('sf_unplug_apps', 'Choose apps', 'ScrollFree · Unplug', Routes.sfUnplugApps),
    ('sf_unplug_picker_ios', 'Apple app picker', 'ScrollFree · Unplug', Routes.sfUnplugPickerIos),
    ('sf_unplug_apps_android', 'Choose apps (Android) · android', 'ScrollFree · Unplug', Routes.sfUnplugAppsAndroid),
    ('sf_unplug_apps_chosen', 'Name your groups · apps chosen', 'ScrollFree · Unplug', Routes.sfUnplugAppsChosen),
    ('sf_unplug_limits', 'Limits & pause screen', 'ScrollFree · Unplug', Routes.sfUnplugLimits),
    ('sf_unplug_home', 'Unplug', 'ScrollFree · Unplug', Routes.sfUnplugHome),
    ('sf_unplug_session', 'Start a focus session', 'ScrollFree · Unplug', Routes.sfUnplugSession),
    ('sf_unplug_session_active', 'Focus session running', 'ScrollFree · Unplug', Routes.sfUnplugSessionActive),
    ('sf_unplug_session_end', 'End session early', 'ScrollFree · Unplug', Routes.sfUnplugSessionEnd),
    ('sf_unplug_session_done', 'Session complete', 'ScrollFree · Unplug', Routes.sfUnplugSessionDone),
    ('sf_unplug_session_done_early', 'Session ended early · ended early', 'ScrollFree · Unplug', Routes.sfUnplugSessionDoneEarly),
    ('sf_unplug_shield', 'Pause screen (iPhone shield)', 'ScrollFree · Unplug', Routes.sfUnplugShield),
    ('sf_unplug_shield_firm', 'Pause screen (iPhone shield, firm) · no “open anyway” left', 'ScrollFree · Unplug', Routes.sfUnplugShieldFirm),
    ('sf_unplug_overlay', 'Pause screen (Android overlay)', 'ScrollFree · Unplug', Routes.sfUnplugOverlay),
    ('sf_unplug_gate', 'Small step: one breath', 'ScrollFree · Unplug', Routes.sfUnplugGate),
    ('sf_unplug_gate_commit', 'Small step: type a sentence · typed sentence', 'ScrollFree · Unplug', Routes.sfUnplugGateCommit),
    ('sf_unplug_gate_sum', 'Small step: quick sum · quick sum', 'ScrollFree · Unplug', Routes.sfUnplugGateSum),
    ('sf_unplug_health', 'Tracking check', 'ScrollFree · Unplug', Routes.sfUnplugHealth),
    ('sf_unplug_health_notifications', 'Tracking check · notifications off · notifications off', 'ScrollFree · Unplug', Routes.sfUnplugHealthNotifications),
    ('sf_unplug_health_stopped', 'Tracking stopped · tracking stopped', 'ScrollFree · Unplug', Routes.sfUnplugHealthStopped),
    ('sf_unplug_health_android', 'Tracking check (Android) · android', 'ScrollFree · Unplug', Routes.sfUnplugHealthAndroid),
    ('sf_unplug_off', 'Turn off Unplug', 'ScrollFree · Unplug', Routes.sfUnplugOff),
    ('sf_home_unplug', 'ScrollFree home · Unplug on (iPhone) · Unplug on · iPhone', 'ScrollFree', Routes.sfHomeUnplug),
    ('sf_week_unplug', 'Weekly reflection · Unplug on (iPhone) · Unplug on · iPhone', 'ScrollFree', Routes.sfWeekUnplug),
    ('program_settings_sf', 'Program settings · ScrollFree with Unplug · ScrollFree', 'Plans & programs', Routes.programSettingsSf),
    ('account_delete_apple', 'Delete account · Apple account · Apple account', 'Account & data', Routes.accountDeleteApple),
    ('account_delete_google', 'Delete account · Google account · Google account', 'Account & data', Routes.accountDeleteGoogle),
    ('auth_session_apple', 'Session expired · Apple account · Apple account', 'Account & sign-in', Routes.authSessionApple),
    ('auth_session_google', 'Session expired · Google account · Google account', 'Account & sign-in', Routes.authSessionGoogle),
    ('sf_screentime_android', 'Connect usage access (Android) · android', 'ScrollFree', Routes.sfScreentimeAndroid),
    ('sf_screentime_android_denied', 'Usage access off (Android) · android · not allowed', 'ScrollFree', Routes.sfScreentimeAndroidDenied),
    ('sys_update_android', 'Update required (Android) · android', 'System states', Routes.sysUpdateAndroid),
    ('surface_widget_ios', 'Home-screen widget (iPhone)', 'Home screen, Siri & shortcuts', Routes.surfaceWidgetIos),
    ('surface_widget_android', 'Home-screen widget (Android)', 'Home screen, Siri & shortcuts', Routes.surfaceWidgetAndroid),
    ('surface_shortcuts_ios', 'Siri & App Shortcuts (iPhone)', 'Home screen, Siri & shortcuts', Routes.surfaceShortcutsIos),
    ('surface_shortcuts_ios_named', 'Siri & App Shortcuts (sensitive details on) · Show sensitive details on', 'Home screen, Siri & shortcuts', Routes.surfaceShortcutsIosNamed),
    ('surface_shortcuts_android', 'Launcher shortcuts (Android)', 'Home screen, Siri & shortcuts', Routes.surfaceShortcutsAndroid),
    ('surface_shortcuts_android_named', 'Launcher shortcuts (sensitive details on) · Show sensitive details on', 'Home screen, Siri & shortcuts', Routes.surfaceShortcutsAndroidNamed),
  ];

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = screens[settings.name];
    if (builder == null) return null;
    if (sheets.contains(settings.name)) {
      return ModalBottomSheetRoute<void>(
        builder: builder,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        settings: settings,
      );
    }
    return MaterialPageRoute<void>(builder: builder, settings: settings);
  }
}
