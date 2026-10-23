// GENERATED from the spec (spec/l10n/en.arb) and the hand-maintained
// translations in spec/l10n/<locale>.arb. Do not edit: re-run the generator.
// ignore_for_file: lines_longer_than_80_chars
import '../ui/strings.dart';

/// Locales a release build offers: every key present, fresh and reviewed.
const List<String> tReleaseLocales = <String>['en'];

/// Locales offered in debug builds only (incomplete, stale or unreviewed).
const List<String> tDraftLocales = <String>[];

/// The pseudo-locale (debug builds and tests only).
const String tPseudoLocale = 'en-XA';

/// The catalog for [tag], or null when [release] builds do not include it.
Map<String, String>? tCatalog(String tag, {required bool release}) {
  switch (tag) {
    case 'en':
      return _en;
    case 'en-XA':
      return release ? null : _pseudo;
  }
  return null;
}

/// The plural category of [n] in [language].
String tPluralCategory(String language, num n) {
  switch (language) {
    case 'en':
    case 'es':
      return n == 1 ? 'one' : 'other';
  }
  return 'other';
}

/// Typed accessors, one per key.
extension TStringsKeys on TStrings {
  String get kitBack => get('kit.back');
  String get kitClose => get('kit.close');
  String get kitAccount => get('kit.account');
  String get kitTabToday => get('kit.tab_today');
  String get kitTabPlans => get('kit.tab_plans');
  String get kitTabProgress => get('kit.tab_progress');
  String get kitTabLearn => get('kit.tab_learn');
  String get kitTabSupport => get('kit.tab_support');
  String kitTabSemantics({required Object tab}) => format('kit.tab_semantics', {'tab': tab});
  String kitStepOf({required Object n, required Object total}) => format('kit.step_of', {'n': n, 'total': total});
  String get kitZoneGreen => get('kit.zone_green');
  String get kitZoneYellow => get('kit.zone_yellow');
  String get kitZoneRed => get('kit.zone_red');
  String kitZoneSemantics({required Object zone}) => format('kit.zone_semantics', {'zone': zone});
  String get kitChart => get('kit.chart');
  String kitChartSemantics({required Object title, required Object values}) => format('kit.chart_semantics', {'title': title, 'values': values});
  String get kitChartNoEntry => get('kit.chart_no_entry');
  String get kitSeconds => get('kit.seconds');
  String kitRingSemantics({required Object label, required Object value}) => format('kit.ring_semantics', {'label': label, 'value': value});
  String kitTimerSemantics({required Object label, required Object value}) => format('kit.timer_semantics', {'label': label, 'value': value});
  String get kitWeekdayInitials => get('kit.weekday_initials');
  String kitCalendarDay({required Object day, required Object month}) => format('kit.calendar_day', {'day': day, 'month': month});
  String get kitMonthNames => get('kit.month_names');
  String get kitWeekdayNames => get('kit.weekday_names');
  String kitCalendarTitle({required Object month, required Object year}) => format('kit.calendar_title', {'month': month, 'year': year});
  String kitDateFull({required Object day, required Object month, required Object weekday, required Object year}) => format('kit.date_full', {'day': day, 'month': month, 'weekday': weekday, 'year': year});
  String get kitCalendarPrev => get('kit.calendar_prev');
  String get kitCalendarNext => get('kit.calendar_next');
  String get kitCalendarRecommended => get('kit.calendar_recommended');
  String kitDaysToPrepare({required num n}) => format('kit.days_to_prepare', {'n': n});
  String kitEnvironment({required Object name}) => format('kit.environment', {'name': name});
  String kitQuote({required Object text}) => format('kit.quote', {'text': text});
  String get kitEmergencyHelp => get('kit.emergency_help');
  String get kitLoading => get('kit.loading');
  String get kitGenericError => get('kit.generic_error');
  String get kitExample => get('kit.example');
  String kitCallFallback({required Object number}) => format('kit.call_fallback', {'number': number});
  String kitSmsFallback({required Object number}) => format('kit.sms_fallback', {'number': number});
  String get kitCopy => get('kit.copy');
  String get kitCopied => get('kit.copied');
  String get welcomeBodyN2Text => get('welcome.body[2].text');
  String get welcomeBodyN3Text => get('welcome.body[3].text');
  String get welcomeBodyN4Text => get('welcome.body[4].text');
  String get welcomeBodyN5RowsN0N0 => get('welcome.body[5].rows[0][0]');
  String get welcomeBodyN5RowsN0N1 => get('welcome.body[5].rows[0][1]');
  String get welcomeBodyN5RowsN1N0 => get('welcome.body[5].rows[1][0]');
  String get welcomeBodyN5RowsN1N1 => get('welcome.body[5].rows[1][1]');
  String get welcomeBodyN5RowsN2N0 => get('welcome.body[5].rows[2][0]');
  String get welcomeBodyN5RowsN2N1 => get('welcome.body[5].rows[2][1]');
  String get welcomeFooterN0Label => get('welcome.footer[0].label');
  String get welcomeFooterN1Label => get('welcome.footer[1].label');
  String get welcomeFooterN2Label => get('welcome.footer[2].label');
  String get obProgramsBodyN1Text => get('ob_programs.body[1].text');
  String get obProgramsBodyN2Text => get('ob_programs.body[2].text');
  String get obProgramsBodyN3ItemsN0Sub => get('ob_programs.body[3].items[0].sub');
  String get obProgramsBodyN3ItemsN1Sub => get('ob_programs.body[3].items[1].sub');
  String get obProgramsBodyN3ItemsN2Sub => get('ob_programs.body[3].items[2].sub');
  String get obProgramsBodyN3ItemsN3Sub => get('ob_programs.body[3].items[3].sub');
  String get obProgramsBodyN3ItemsN4Sub => get('ob_programs.body[3].items[4].sub');
  String get obProgramsBodyN3ItemsN5Sub => get('ob_programs.body[3].items[5].sub');
  String get obProgramsBodyN3ItemsN6Sub => get('ob_programs.body[3].items[6].sub');
  String get obProgramsBodyN3ItemsN7Sub => get('ob_programs.body[3].items[7].sub');
  String get obProgramsBodyN4Label => get('ob_programs.body[4].label');
  String obProgramsFooterN0CountLabel({required num n}) => format('ob_programs.footer[0].countLabel', {'n': n});
  String get obProgramsFooterN0EmptyLabel => get('ob_programs.footer[0].emptyLabel');
  String get obProgramsHeaderTitle => get('ob_programs.header.title');
  String get obProgramsHeaderPill => get('ob_programs.header.pill');
  String get obFocusBodyN1Text => get('ob_focus.body[1].text');
  String get obFocusBodyN2Text => get('ob_focus.body[2].text');
  String get obFocusBodyN3RowsN0Sub => get('ob_focus.body[3].rows[0].sub');
  String get obFocusBodyN3RowsN0Pill => get('ob_focus.body[3].rows[0].pill');
  String get obFocusBodyN3RowsN1Sub => get('ob_focus.body[3].rows[1].sub');
  String get obFocusBodyN3RowsN1Pill => get('ob_focus.body[3].rows[1].pill');
  String get obFocusBodyN3Title => get('ob_focus.body[3].title');
  String get obFocusBodyN4RowsN0Sub => get('ob_focus.body[4].rows[0].sub');
  String get obFocusBodyN4RowsN0Pill => get('ob_focus.body[4].rows[0].pill');
  String get obFocusBodyN4Title => get('ob_focus.body[4].title');
  String get obFocusBodyN5Title => get('ob_focus.body[5].title');
  String get obFocusBodyN5Text => get('ob_focus.body[5].text');
  String get obFocusBodyN6Label => get('ob_focus.body[6].label');
  String get obFocusFooterN0Label => get('ob_focus.footer[0].label');
  String get obFocusHeaderTitle => get('ob_focus.header.title');
  String get obFocusHeaderPill => get('ob_focus.header.pill');
  String get obThirdBodyN0Text => get('ob_third.body[0].text');
  String get obThirdBodyN1Text => get('ob_third.body[1].text');
  String get obThirdBodyN2ItemsN0Label => get('ob_third.body[2].items[0].label');
  String get obThirdBodyN2ItemsN0Sub => get('ob_third.body[2].items[0].sub');
  String get obThirdBodyN2ItemsN0Badge => get('ob_third.body[2].items[0].badge');
  String get obThirdBodyN2ItemsN1Label => get('ob_third.body[2].items[1].label');
  String get obThirdBodyN2ItemsN1Sub => get('ob_third.body[2].items[1].sub');
  String get obThirdBodyN2ItemsN2Label => get('ob_third.body[2].items[2].label');
  String get obThirdBodyN2ItemsN2Sub => get('ob_third.body[2].items[2].sub');
  String get obThirdFooterN0ActionValue => get('ob_third.footer[0].action.value');
  String get obThirdFooterN0Label => get('ob_third.footer[0].label');
  String get obThirdFooterN1Label => get('ob_third.footer[1].label');
  String get obConsentBodyN1Text => get('ob_consent.body[1].text');
  String get obConsentBodyN2Text => get('ob_consent.body[2].text');
  String get obConsentBodyN3Eyebrow => get('ob_consent.body[3].eyebrow');
  String get obConsentBodyN3ChildrenN0Label => get('ob_consent.body[3].children[0].label');
  String get obConsentBodyN3ChildrenN0Sub => get('ob_consent.body[3].children[0].sub');
  String get obConsentBodyN4ChildrenN0Label => get('ob_consent.body[4].children[0].label');
  String get obConsentBodyN4ChildrenN0Sub => get('ob_consent.body[4].children[0].sub');
  String get obConsentBodyN4ChildrenN1Label => get('ob_consent.body[4].children[1].label');
  String get obConsentBodyN4ChildrenN1Sub => get('ob_consent.body[4].children[1].sub');
  String get obConsentBodyN5ChildrenN0Label => get('ob_consent.body[5].children[0].label');
  String get obConsentBodyN5ChildrenN0Sub => get('ob_consent.body[5].children[0].sub');
  String get obConsentBodyN5ChildrenN1Label => get('ob_consent.body[5].children[1].label');
  String get obConsentBodyN6Text => get('ob_consent.body[6].text');
  String get obConsentBodyN7Label => get('ob_consent.body[7].label');
  String get obConsentFooterN0Label => get('ob_consent.footer[0].label');
  String get obConsentHeaderTitle => get('ob_consent.header.title');
  String get obConsentHeaderPill => get('ob_consent.header.pill');
  String get obBasicsBodyN1Text => get('ob_basics.body[1].text');
  String get obBasicsBodyN2Text => get('ob_basics.body[2].text');
  String get obBasicsBodyN3Label => get('ob_basics.body[3].label');
  String get obBasicsBodyN3Placeholder => get('ob_basics.body[3].placeholder');
  String get obBasicsBodyN4Label => get('ob_basics.body[4].label');
  String get obBasicsBodyN5OptionsN0 => get('ob_basics.body[5].options[0]');
  String get obBasicsBodyN5OptionsN1 => get('ob_basics.body[5].options[1]');
  String get obBasicsBodyN5OptionsN2 => get('ob_basics.body[5].options[2]');
  String get obBasicsBodyN5OptionsN3 => get('ob_basics.body[5].options[3]');
  String get obBasicsBodyN5Label => get('ob_basics.body[5].label');
  String get obBasicsBodyN6OptionsN0 => get('ob_basics.body[6].options[0]');
  String get obBasicsBodyN6OptionsN1 => get('ob_basics.body[6].options[1]');
  String get obBasicsBodyN6OptionsN2 => get('ob_basics.body[6].options[2]');
  String get obBasicsBodyN6Label => get('ob_basics.body[6].label');
  String get obBasicsBodyN7Title => get('ob_basics.body[7].title');
  String get obBasicsBodyN7Text => get('ob_basics.body[7].text');
  String get obBasicsFooterN0Label => get('ob_basics.footer[0].label');
  String get obBasicsHeaderTitle => get('ob_basics.header.title');
  String get obBasicsHeaderPill => get('ob_basics.header.pill');
  String get obSetupBodyN1Text => get('ob_setup.body[1].text');
  String get obSetupBodyN2Text => get('ob_setup.body[2].text');
  String get obSetupBodyN3RowsN0Sub => get('ob_setup.body[3].rows[0].sub');
  String get obSetupBodyN3RowsN0Pill => get('ob_setup.body[3].rows[0].pill');
  String get obSetupBodyN3RowsN1Sub => get('ob_setup.body[3].rows[1].sub');
  String get obSetupBodyN3RowsN1Pill => get('ob_setup.body[3].rows[1].pill');
  String get obSetupBodyN3Title => get('ob_setup.body[3].title');
  String get obSetupBodyN4RowsN0Sub => get('ob_setup.body[4].rows[0].sub');
  String get obSetupBodyN4Title => get('ob_setup.body[4].title');
  String get obSetupBodyN5RowsN0Label => get('ob_setup.body[5].rows[0].label');
  String get obSetupBodyN5RowsN0Sub => get('ob_setup.body[5].rows[0].sub');
  String get obSetupBodyN5Title => get('ob_setup.body[5].title');
  String get obSetupBodyN6Title => get('ob_setup.body[6].title');
  String get obSetupBodyN6Text => get('ob_setup.body[6].text');
  String get obSetupFooterN0Label => get('ob_setup.footer[0].label');
  String get obSetupFooterN1Label => get('ob_setup.footer[1].label');
  String get obSetupHeaderTitle => get('ob_setup.header.title');
  String get obSetupHeaderPill => get('ob_setup.header.pill');
  String get obRemindersBodyN1Text => get('ob_reminders.body[1].text');
  String get obRemindersBodyN2Text => get('ob_reminders.body[2].text');
  String get obRemindersBodyN3Eyebrow => get('ob_reminders.body[3].eyebrow');
  String get obRemindersBodyN3Text => get('ob_reminders.body[3].text');
  String get obRemindersBodyN3ChildrenN0Text => get('ob_reminders.body[3].children[0].text');
  String get obRemindersBodyN4Label => get('ob_reminders.body[4].label');
  String get obRemindersBodyN4Sub => get('ob_reminders.body[4].sub');
  String get obRemindersFooterN0Label => get('ob_reminders.footer[0].label');
  String get obRemindersFooterN1Label => get('ob_reminders.footer[1].label');
  String get obRemindersHeaderTitle => get('ob_reminders.header.title');
  String get obRemindersDeniedBodyN0Text => get('ob_reminders_denied.body[0].text');
  String get obRemindersDeniedBodyN1Text => get('ob_reminders_denied.body[1].text');
  String get obRemindersDeniedBodyN2Text => get('ob_reminders_denied.body[2].text');
  String get obRemindersDeniedFooterN0Label => get('ob_reminders_denied.footer[0].label');
  String get obRemindersDeniedFooterN1Label => get('ob_reminders_denied.footer[1].label');
  String get obRemindersDeniedHeaderTitle => get('ob_reminders_denied.header.title');
  String get obAccountBodyN0Text => get('ob_account.body[0].text');
  String get obAccountBodyN1Text => get('ob_account.body[1].text');
  String get obAccountBodyN2ItemsN0Label => get('ob_account.body[2].items[0].label');
  String get obAccountBodyN2ItemsN0ActionCasesN0ActionCasesN2ActionValue => get('ob_account.body[2].items[0].action.cases[0].action.cases[2].action.value');
  String get obAccountBodyN2ItemsN0ActionCasesN1ActionValue => get('ob_account.body[2].items[0].action.cases[1].action.value');
  String get obAccountBodyN2ItemsN1Label => get('ob_account.body[2].items[1].label');
  String get obAccountBodyN2ItemsN1ActionCasesN0ActionCasesN2ActionValue => get('ob_account.body[2].items[1].action.cases[0].action.cases[2].action.value');
  String get obAccountBodyN2ItemsN1ActionCasesN1ActionValue => get('ob_account.body[2].items[1].action.cases[1].action.value');
  String get obAccountBodyN3Text => get('ob_account.body[3].text');
  String get obAccountBodyN4Text => get('ob_account.body[4].text');
  String get obAccountBodyN5Label => get('ob_account.body[5].label');
  String get obAccountBodyN5Placeholder => get('ob_account.body[5].placeholder');
  String get obAccountBodyN6Label => get('ob_account.body[6].label');
  String get obAccountBodyN6Hint => get('ob_account.body[6].hint');
  String get obAccountBodyN7ItemsN0Label => get('ob_account.body[7].items[0].label');
  String get obAccountBodyN8Text => get('ob_account.body[8].text');
  String get obAccountFooterN0ActionCasesN1ActionValue => get('ob_account.footer[0].action.cases[1].action.value');
  String get obAccountFooterN0Label => get('ob_account.footer[0].label');
  String get obAccountFooterN1ActionCasesN1ActionValue => get('ob_account.footer[1].action.cases[1].action.value');
  String get obAccountFooterN1Label => get('ob_account.footer[1].label');
  String get obAccountHeaderTitle => get('ob_account.header.title');
  String get authVerifyBodyN1Text => get('auth_verify.body[1].text');
  String get authVerifyBodyN2Text => get('auth_verify.body[2].text');
  String get authVerifyBodyN3Text => get('auth_verify.body[3].text');
  String get authVerifyFooterN0Label => get('auth_verify.footer[0].label');
  String get authVerifyFooterN1Label => get('auth_verify.footer[1].label');
  String get authVerifyFooterN2Label => get('auth_verify.footer[2].label');
  String get authVerifyFooterN2ActionValue => get('auth_verify.footer[2].action.value');
  String get authVerifyHeaderTitle => get('auth_verify.header.title');
  String get authSigninBodyN0Text => get('auth_signin.body[0].text');
  String get authSigninBodyN1ItemsN0Label => get('auth_signin.body[1].items[0].label');
  String get authSigninBodyN1ItemsN0ActionCasesN3ActionValue => get('auth_signin.body[1].items[0].action.cases[3].action.value');
  String get authSigninBodyN1ItemsN1Label => get('auth_signin.body[1].items[1].label');
  String get authSigninBodyN1ItemsN1ActionCasesN3ActionValue => get('auth_signin.body[1].items[1].action.cases[3].action.value');
  String get authSigninBodyN2Text => get('auth_signin.body[2].text');
  String get authSigninBodyN3Label => get('auth_signin.body[3].label');
  String get authSigninBodyN3Placeholder => get('auth_signin.body[3].placeholder');
  String get authSigninBodyN4Label => get('auth_signin.body[4].label');
  String get authSigninBodyN5Label => get('auth_signin.body[5].label');
  String get authSigninFooterN0Label => get('auth_signin.footer[0].label');
  String get authSigninFooterN1Label => get('auth_signin.footer[1].label');
  String get authSigninErrorBodyN0Text => get('auth_signin_error.body[0].text');
  String get authSigninErrorBodyN1Text => get('auth_signin_error.body[1].text');
  String get authSigninErrorBodyN2ItemsN0Label => get('auth_signin_error.body[2].items[0].label');
  String get authSigninErrorBodyN2ItemsN0ActionCasesN3ActionValue => get('auth_signin_error.body[2].items[0].action.cases[3].action.value');
  String get authSigninErrorBodyN2ItemsN1Label => get('auth_signin_error.body[2].items[1].label');
  String get authSigninErrorBodyN2ItemsN1ActionCasesN3ActionValue => get('auth_signin_error.body[2].items[1].action.cases[3].action.value');
  String get authSigninErrorBodyN3Text => get('auth_signin_error.body[3].text');
  String get authSigninErrorBodyN4Label => get('auth_signin_error.body[4].label');
  String get authSigninErrorBodyN4Placeholder => get('auth_signin_error.body[4].placeholder');
  String get authSigninErrorBodyN5Label => get('auth_signin_error.body[5].label');
  String get authSigninErrorBodyN5Error => get('auth_signin_error.body[5].error');
  String get authSigninErrorBodyN6Label => get('auth_signin_error.body[6].label');
  String get authSigninErrorBodyN7Text => get('auth_signin_error.body[7].text');
  String get authSigninErrorFooterN0Label => get('auth_signin_error.footer[0].label');
  String get authSigninErrorFooterN1Label => get('auth_signin_error.footer[1].label');
  String get authSocialNewBodyN1Text => get('auth_social_new.body[1].text');
  String get authSocialNewBodyN2Text => get('auth_social_new.body[2].text');
  String get authSocialNewBodyN3RowsN0N0 => get('auth_social_new.body[3].rows[0][0]');
  String get authSocialNewBodyN3RowsN0N1 => get('auth_social_new.body[3].rows[0][1]');
  String get authSocialNewBodyN3RowsN1N0 => get('auth_social_new.body[3].rows[1][0]');
  String get authSocialNewBodyN3RowsN1N1 => get('auth_social_new.body[3].rows[1][1]');
  String get authSocialNewBodyN3RowsN2N0 => get('auth_social_new.body[3].rows[2][0]');
  String get authSocialNewBodyN3RowsN2N1 => get('auth_social_new.body[3].rows[2][1]');
  String get authSocialNewBodyN4Text => get('auth_social_new.body[4].text');
  String get authSocialNewFooterN0Label => get('auth_social_new.footer[0].label');
  String get authSocialNewFooterN1Label => get('auth_social_new.footer[1].label');
  String get authSocialNewHeaderTitle => get('auth_social_new.header.title');
  String get authLinkBodyN1Text => get('auth_link.body[1].text');
  String get authLinkBodyN2Text => get('auth_link.body[2].text');
  String get authLinkBodyN3Label => get('auth_link.body[3].label');
  String get authLinkBodyN4Label => get('auth_link.body[4].label');
  String get authLinkFooterN0Label => get('auth_link.footer[0].label');
  String get authLinkFooterN1Label => get('auth_link.footer[1].label');
  String get authLinkHeaderTitle => get('auth_link.header.title');
  String get authSocialErrorBodyN1Text => get('auth_social_error.body[1].text');
  String get authSocialErrorBodyN2Text => get('auth_social_error.body[2].text');
  String get authSocialErrorBodyN3Text => get('auth_social_error.body[3].text');
  String get authSocialErrorFooterN0ActionCasesN1ActionValue => get('auth_social_error.footer[0].action.cases[1].action.value');
  String get authSocialErrorFooterN0Label => get('auth_social_error.footer[0].label');
  String get authSocialErrorFooterN1Label => get('auth_social_error.footer[1].label');
  String get authSocialErrorHeaderTitle => get('auth_social_error.header.title');
  String get authForgotBodyN0Text => get('auth_forgot.body[0].text');
  String get authForgotBodyN1Text => get('auth_forgot.body[1].text');
  String get authForgotBodyN2Label => get('auth_forgot.body[2].label');
  String get authForgotBodyN2Placeholder => get('auth_forgot.body[2].placeholder');
  String get authForgotFooterN0Label => get('auth_forgot.footer[0].label');
  String get authForgotHeaderTitle => get('auth_forgot.header.title');
  String get authForgotSentBodyN1Text => get('auth_forgot_sent.body[1].text');
  String get authForgotSentBodyN2Text => get('auth_forgot_sent.body[2].text');
  String get authForgotSentBodyN3Text => get('auth_forgot_sent.body[3].text');
  String get authForgotSentFooterN0Label => get('auth_forgot_sent.footer[0].label');
  String get authForgotSentHeaderTitle => get('auth_forgot_sent.header.title');
  String get authNewpassBodyN0Text => get('auth_newpass.body[0].text');
  String get authNewpassBodyN1Label => get('auth_newpass.body[1].label');
  String get authNewpassBodyN1Hint => get('auth_newpass.body[1].hint');
  String get authNewpassBodyN2Label => get('auth_newpass.body[2].label');
  String get authNewpassFooterN0Label => get('auth_newpass.footer[0].label');
  String get authNewpassHeaderTitle => get('auth_newpass.header.title');
  String get authMergeBodyN0Text => get('auth_merge.body[0].text');
  String get authMergeBodyN1Text => get('auth_merge.body[1].text');
  String get authMergeBodyN2RowsN0Label => get('auth_merge.body[2].rows[0].label');
  String get authMergeBodyN2RowsN0Sub => get('auth_merge.body[2].rows[0].sub');
  String get authMergeBodyN3Text => get('auth_merge.body[3].text');
  String get authMergeBodyN4ItemsN0Label => get('auth_merge.body[4].items[0].label');
  String get authMergeBodyN4ItemsN0Sub => get('auth_merge.body[4].items[0].sub');
  String get authMergeBodyN4ItemsN0Badge => get('auth_merge.body[4].items[0].badge');
  String get authMergeBodyN4ItemsN1Label => get('auth_merge.body[4].items[1].label');
  String get authMergeBodyN4ItemsN2Label => get('auth_merge.body[4].items[2].label');
  String get authMergeFooterN0Label => get('auth_merge.footer[0].label');
  String get authSessionBodyN0Text => get('auth_session.body[0].text');
  String get authSessionBodyN1Text => get('auth_session.body[1].text');
  String get authSessionBodyN2Label => get('auth_session.body[2].label');
  String get authSessionBodyN2Placeholder => get('auth_session.body[2].placeholder');
  String get authSessionFooterN0Label => get('auth_session.footer[0].label');
  String get authSessionFooterN1Label => get('auth_session.footer[1].label');
  String get todayBodyN0Text => get('today.body[0].text');
  String get todayBodyN1Text => get('today.body[1].text');
  String get todayBodyN2OptionsN0 => get('today.body[2].options[0]');
  String get todayBodyN3Title => get('today.body[3].title');
  String get todayBodyN3Text => get('today.body[3].text');
  String get todayBodyN3CtaN0Label => get('today.body[3].cta[0].label');
  String get todayBodyN4Eyebrow => get('today.body[4].eyebrow');
  String get todayBodyN4ChildrenN0ItemsN0Label => get('today.body[4].children[0].items[0].label');
  String get todayBodyN4ChildrenN0ItemsN0Sub => get('today.body[4].children[0].items[0].sub');
  String get todayBodyN4ChildrenN0ItemsN1Label => get('today.body[4].children[0].items[1].label');
  String get todayBodyN4ChildrenN0ItemsN1Sub => get('today.body[4].children[0].items[1].sub');
  String get todayBodyN5Eyebrow => get('today.body[5].eyebrow');
  String get todayBodyN5Title => get('today.body[5].title');
  String get todayBodyN5CtaN0Label => get('today.body[5].cta[0].label');
  String get todayBodyN6ItemsN0Label => get('today.body[6].items[0].label');
  String get todayBodyN6ItemsN0Value => get('today.body[6].items[0].value');
  String get todayBodyN6ItemsN0Sub => get('today.body[6].items[0].sub');
  String get todayBodyN6ItemsN1Label => get('today.body[6].items[1].label');
  String get todayBodyN6ItemsN1Value => get('today.body[6].items[1].value');
  String get todayBodyN6ItemsN1Sub => get('today.body[6].items[1].sub');
  String get todayBodyN7RowsN0Label => get('today.body[7].rows[0].label');
  String get todayBodyN7RowsN0Sub => get('today.body[7].rows[0].sub');
  String get todayBodyN7RowsN1Label => get('today.body[7].rows[1].label');
  String get todayBodyN7RowsN1Sub => get('today.body[7].rows[1].sub');
  String get todayBodyN8TagExtra => get('today.body[8].tagExtra');
  String get todayBodyN8Title => get('today.body[8].title');
  String get todayBodyN8Text => get('today.body[8].text');
  String get todayHeaderTitle => get('today.header.title');
  String get todayLoadingBodyN1Title => get('today_loading.body[1].title');
  String get todayLoadingBodyN1Text => get('today_loading.body[1].text');
  String get todayLoadingBodyN1CtaN0Label => get('today_loading.body[1].cta[0].label');
  String get todayLoadingBodyN4Text => get('today_loading.body[4].text');
  String get todayLoadingHeaderTitle => get('today_loading.header.title');
  String get todayOfflineBodyN0Text => get('today_offline.body[0].text');
  String get todayOfflineBodyN1Text => get('today_offline.body[1].text');
  String get todayOfflineBodyN2Title => get('today_offline.body[2].title');
  String get todayOfflineBodyN2Text => get('today_offline.body[2].text');
  String get todayOfflineBodyN2CtaN0Label => get('today_offline.body[2].cta[0].label');
  String get todayOfflineBodyN3Eyebrow => get('today_offline.body[3].eyebrow');
  String get todayOfflineBodyN3ChildrenN0ItemsN0Label => get('today_offline.body[3].children[0].items[0].label');
  String get todayOfflineBodyN3ChildrenN0ItemsN0Sub => get('today_offline.body[3].children[0].items[0].sub');
  String get todayOfflineBodyN4Text => get('today_offline.body[4].text');
  String get todayOfflineHeaderTitle => get('today_offline.header.title');
  String get todayEmptyBodyN0Text => get('today_empty.body[0].text');
  String get todayEmptyBodyN2Text => get('today_empty.body[2].text');
  String get todayEmptyBodyN3Text => get('today_empty.body[3].text');
  String get todayEmptyBodyN4Label => get('today_empty.body[4].label');
  String get todayEmptyBodyN5Label => get('today_empty.body[5].label');
  String get todayEmptyBodyN6Title => get('today_empty.body[6].title');
  String get todayEmptyBodyN6Text => get('today_empty.body[6].text');
  String get todayEmptyBodyN6CtaN0Label => get('today_empty.body[6].cta[0].label');
  String get todayEmptyHeaderTitle => get('today_empty.header.title');
  String get todaySafetyBodyN0Text => get('today_safety.body[0].text');
  String get todaySafetyBodyN1Title => get('today_safety.body[1].title');
  String get todaySafetyBodyN1Text => get('today_safety.body[1].text');
  String get todaySafetyBodyN1ChildrenN0ItemsN0Label => get('today_safety.body[1].children[0].items[0].label');
  String get todaySafetyBodyN1ChildrenN0ItemsN1Label => get('today_safety.body[1].children[0].items[1].label');
  String get todaySafetyBodyN2Text => get('today_safety.body[2].text');
  String get todaySafetyBodyN3Eyebrow => get('today_safety.body[3].eyebrow');
  String get todaySafetyBodyN3ChildrenN0ItemsN0Label => get('today_safety.body[3].children[0].items[0].label');
  String get todaySafetyBodyN3ChildrenN0ItemsN1Label => get('today_safety.body[3].children[0].items[1].label');
  String get todaySafetyHeaderTitle => get('today_safety.header.title');
  String get checkinBodyN0Text => get('checkin.body[0].text');
  String get checkinBodyN1OptionsN0 => get('checkin.body[1].options[0]');
  String get checkinBodyN1OptionsN1 => get('checkin.body[1].options[1]');
  String get checkinBodyN1OptionsN2 => get('checkin.body[1].options[2]');
  String get checkinBodyN1OptionsN3 => get('checkin.body[1].options[3]');
  String get checkinBodyN1OptionsN4 => get('checkin.body[1].options[4]');
  String get checkinBodyN1Label => get('checkin.body[1].label');
  String get checkinBodyN2OptionsN0 => get('checkin.body[2].options[0]');
  String get checkinBodyN2OptionsN1 => get('checkin.body[2].options[1]');
  String get checkinBodyN2OptionsN2 => get('checkin.body[2].options[2]');
  String get checkinBodyN2Label => get('checkin.body[2].label');
  String get checkinBodyN3Title => get('checkin.body[3].title');
  String get checkinBodyN3Text => get('checkin.body[3].text');
  String get checkinBodyN3ChildrenN0OptionsN0 => get('checkin.body[3].children[0].options[0]');
  String get checkinBodyN3ChildrenN0OptionsN1 => get('checkin.body[3].children[0].options[1]');
  String get checkinBodyN3ChildrenN0OptionsN2 => get('checkin.body[3].children[0].options[2]');
  String get checkinBodyN3ChildrenN0OptionsN3 => get('checkin.body[3].children[0].options[3]');
  String get checkinBodyN4Title => get('checkin.body[4].title');
  String get checkinBodyN4ChildrenN0OptionsN0 => get('checkin.body[4].children[0].options[0]');
  String get checkinBodyN4ChildrenN0OptionsN1 => get('checkin.body[4].children[0].options[1]');
  String get checkinBodyN4ChildrenN0OptionsN2 => get('checkin.body[4].children[0].options[2]');
  String get checkinBodyN4ChildrenN0OptionsN3 => get('checkin.body[4].children[0].options[3]');
  String get checkinFooterN0Label => get('checkin.footer[0].label');
  String get checkinFooterN1Text => get('checkin.footer[1].text');
  String get checkinDoneBodyN1Text => get('checkin_done.body[1].text');
  String get checkinDoneBodyN2Text => get('checkin_done.body[2].text');
  String get checkinDoneBodyN3Title => get('checkin_done.body[3].title');
  String get checkinDoneBodyN3Text => get('checkin_done.body[3].text');
  String get checkinDoneBodyN3CtaN0Label => get('checkin_done.body[3].cta[0].label');
  String get checkinDoneBodyN4Title => get('checkin_done.body[4].title');
  String get checkinDoneBodyN4Text => get('checkin_done.body[4].text');
  String get checkinDoneBodyN4CtaN0Label => get('checkin_done.body[4].cta[0].label');
  String get checkinDoneBodyN5Text => get('checkin_done.body[5].text');
  String get checkinDoneFooterN0Label => get('checkin_done.footer[0].label');
  String get checkinDoneHeaderTitle => get('checkin_done.header.title');
  String get rescuePickBodyN0Text => get('rescue_pick.body[0].text');
  String get rescuePickBodyN1Text => get('rescue_pick.body[1].text');
  String get rescuePickBodyN2Text => get('rescue_pick.body[2].text');
  String get rescuePickBodyN3ItemsN0Label => get('rescue_pick.body[3].items[0].label');
  String get rescuePickBodyN3ItemsN1Label => get('rescue_pick.body[3].items[1].label');
  String get rescuePickBodyN3ItemsN2Label => get('rescue_pick.body[3].items[2].label');
  String get rescuePickBodyN3ItemsN2Sub => get('rescue_pick.body[3].items[2].sub');
  String get rescuePickBodyN3ItemsN3Label => get('rescue_pick.body[3].items[3].label');
  String get rescuePickBodyN3ItemsN3Sub => get('rescue_pick.body[3].items[3].sub');
  String get rescuePickBodyN4Eyebrow => get('rescue_pick.body[4].eyebrow');
  String get rescuePickBodyN4Title => get('rescue_pick.body[4].title');
  String get rescuePickBodyN4CtaN0Label => get('rescue_pick.body[4].cta[0].label');
  String get rescuePickBodyN5ItemsN0Label => get('rescue_pick.body[5].items[0].label');
  String get rescuePickBodyN5ItemsN1Label => get('rescue_pick.body[5].items[1].label');
  String get rescueActiveBodyN0Text => get('rescue_active.body[0].text');
  String get rescueActiveBodyN2Text => get('rescue_active.body[2].text');
  String get rescueActiveBodyN3OptionsN0 => get('rescue_active.body[3].options[0]');
  String get rescueActiveBodyN3OptionsN1 => get('rescue_active.body[3].options[1]');
  String get rescueActiveBodyN3OptionsN2 => get('rescue_active.body[3].options[2]');
  String get rescueActiveBodyN4Title => get('rescue_active.body[4].title');
  String get rescueActiveBodyN4Text => get('rescue_active.body[4].text');
  String get rescueActiveBodyN4ChildrenN0ItemsN0Label => get('rescue_active.body[4].children[0].items[0].label');
  String get rescueActiveBodyN4ChildrenN0ItemsN1Label => get('rescue_active.body[4].children[0].items[1].label');
  String get rescueActiveFooterN0Label => get('rescue_active.footer[0].label');
  String get rescueActiveHeaderTitle => get('rescue_active.header.title');
  String get rescueActiveHeaderPill => get('rescue_active.header.pill');
  String get rescueToolsBodyN0Text => get('rescue_tools.body[0].text');
  String get rescueToolsBodyN1ItemsN0Label => get('rescue_tools.body[1].items[0].label');
  String get rescueToolsBodyN1ItemsN0Sub => get('rescue_tools.body[1].items[0].sub');
  String get rescueToolsBodyN1ItemsN0Badge => get('rescue_tools.body[1].items[0].badge');
  String get rescueToolsBodyN1ItemsN1Label => get('rescue_tools.body[1].items[1].label');
  String get rescueToolsBodyN1ItemsN1Sub => get('rescue_tools.body[1].items[1].sub');
  String get rescueToolsBodyN1ItemsN2Label => get('rescue_tools.body[1].items[2].label');
  String get rescueToolsBodyN1ItemsN2Sub => get('rescue_tools.body[1].items[2].sub');
  String get rescueToolsBodyN1ItemsN3Label => get('rescue_tools.body[1].items[3].label');
  String get rescueToolsBodyN1ItemsN3Sub => get('rescue_tools.body[1].items[3].sub');
  String get rescueToolsFooterN0Label => get('rescue_tools.footer[0].label');
  String get rescueToolsFooterN1Label => get('rescue_tools.footer[1].label');
  String get rescueResultBodyN0Text => get('rescue_result.body[0].text');
  String get rescueResultBodyN1Label => get('rescue_result.body[1].label');
  String get rescueResultBodyN2ItemsN0Label => get('rescue_result.body[2].items[0].label');
  String get rescueResultBodyN2ItemsN1Label => get('rescue_result.body[2].items[1].label');
  String get rescueResultBodyN2ItemsN1Sub => get('rescue_result.body[2].items[1].sub');
  String get rescueResultBodyN3OptionsN0 => get('rescue_result.body[3].options[0]');
  String get rescueResultBodyN3OptionsN1 => get('rescue_result.body[3].options[1]');
  String get rescueResultBodyN3OptionsN2 => get('rescue_result.body[3].options[2]');
  String get rescueResultBodyN3Label => get('rescue_result.body[3].label');
  String get rescueResultBodyN4Eyebrow => get('rescue_result.body[4].eyebrow');
  String get rescueResultBodyN4Title => get('rescue_result.body[4].title');
  String get rescueResultBodyN5Label => get('rescue_result.body[5].label');
  String get rescueResultFooterN0Label => get('rescue_result.footer[0].label');
  String get rescueResultHeaderTitle => get('rescue_result.header.title');
  String get rescueResultHeaderPill => get('rescue_result.header.pill');
  String get rescueEscalateBodyN0Text => get('rescue_escalate.body[0].text');
  String get rescueEscalateBodyN1Text => get('rescue_escalate.body[1].text');
  String get rescueEscalateBodyN2Eyebrow => get('rescue_escalate.body[2].eyebrow');
  String get rescueEscalateBodyN2Title => get('rescue_escalate.body[2].title');
  String get rescueEscalateBodyN2Text => get('rescue_escalate.body[2].text');
  String get rescueEscalateBodyN2CtaN0Label => get('rescue_escalate.body[2].cta[0].label');
  String get rescueEscalateBodyN3RowsN0Label => get('rescue_escalate.body[3].rows[0].label');
  String get rescueEscalateBodyN3RowsN0Sub => get('rescue_escalate.body[3].rows[0].sub');
  String get rescueEscalateBodyN4Text => get('rescue_escalate.body[4].text');
  String get rescueEscalateBodyN4ActionsN0Label => get('rescue_escalate.body[4].actions[0].label');
  String get rescueEscalateBodyN4ActionsN1Label => get('rescue_escalate.body[4].actions[1].label');
  String get rescueEscalateFooterN0Label => get('rescue_escalate.footer[0].label');
  String get rescueEscalateHeaderTitle => get('rescue_escalate.header.title');
  String get crisisBodyN0Text => get('crisis.body[0].text');
  String get crisisBodyN1Label => get('crisis.body[1].label');
  String get crisisBodyN2Label => get('crisis.body[2].label');
  String get crisisBodyN3Label => get('crisis.body[3].label');
  String get crisisBodyN4Eyebrow => get('crisis.body[4].eyebrow');
  String get crisisBodyN4Title => get('crisis.body[4].title');
  String get crisisBodyN4Text => get('crisis.body[4].text');
  String get crisisHeaderTitle => get('crisis.header.title');
  String get plansBodyN0RowsN0Sub => get('plans.body[0].rows[0].sub');
  String get plansBodyN0RowsN0Pill => get('plans.body[0].rows[0].pill');
  String get plansBodyN0RowsN1Sub => get('plans.body[0].rows[1].sub');
  String get plansBodyN0RowsN1Pill => get('plans.body[0].rows[1].pill');
  String get plansBodyN0Title => get('plans.body[0].title');
  String get plansBodyN1RowsN0Sub => get('plans.body[1].rows[0].sub');
  String get plansBodyN1RowsN0Pill => get('plans.body[1].rows[0].pill');
  String get plansBodyN1Title => get('plans.body[1].title');
  String get plansBodyN2RowsN0Label => get('plans.body[2].rows[0].label');
  String get plansBodyN2RowsN0Sub => get('plans.body[2].rows[0].sub');
  String get plansBodyN2RowsN1Label => get('plans.body[2].rows[1].label');
  String get plansBodyN2RowsN1Sub => get('plans.body[2].rows[1].sub');
  String get plansBodyN2Title => get('plans.body[2].title');
  String get plansFooterN0Label => get('plans.footer[0].label');
  String get plansHeaderTitle => get('plans.header.title');
  String get catalogBodyN0Text => get('catalog.body[0].text');
  String get catalogBodyN1RowsN0Sub => get('catalog.body[1].rows[0].sub');
  String get catalogBodyN1RowsN1Sub => get('catalog.body[1].rows[1].sub');
  String get catalogBodyN1RowsN2Sub => get('catalog.body[1].rows[2].sub');
  String get catalogBodyN1RowsN3Sub => get('catalog.body[1].rows[3].sub');
  String get catalogBodyN1RowsN4Sub => get('catalog.body[1].rows[4].sub');
  String get catalogBodyN1RowsN5Sub => get('catalog.body[1].rows[5].sub');
  String get catalogBodyN1Title => get('catalog.body[1].title');
  String get catalogBodyN2RowsN0Sub => get('catalog.body[2].rows[0].sub');
  String get catalogBodyN2RowsN1Sub => get('catalog.body[2].rows[1].sub');
  String get catalogBodyN2RowsN2Sub => get('catalog.body[2].rows[2].sub');
  String get catalogBodyN2RowsN3Sub => get('catalog.body[2].rows[3].sub');
  String get catalogBodyN2RowsN4Sub => get('catalog.body[2].rows[4].sub');
  String get catalogBodyN2Title => get('catalog.body[2].title');
  String get catalogHeaderTitle => get('catalog.header.title');
  String get focusFullBodyN0Text => get('focus_full.body[0].text');
  String get focusFullBodyN1Text => get('focus_full.body[1].text');
  String get focusFullBodyN2ItemsN0Label => get('focus_full.body[2].items[0].label');
  String get focusFullBodyN2ItemsN0Sub => get('focus_full.body[2].items[0].sub');
  String get focusFullBodyN2ItemsN0Badge => get('focus_full.body[2].items[0].badge');
  String get focusFullBodyN2ItemsN1Label => get('focus_full.body[2].items[1].label');
  String get focusFullBodyN2ItemsN1Sub => get('focus_full.body[2].items[1].sub');
  String get focusFullBodyN2ItemsN2Label => get('focus_full.body[2].items[2].label');
  String get focusFullBodyN2ItemsN2Sub => get('focus_full.body[2].items[2].sub');
  String get focusFullFooterN0ActionCasesN0ActionValue => get('focus_full.footer[0].action.cases[0].action.value');
  String get focusFullFooterN0Label => get('focus_full.footer[0].label');
  String get focusFullFooterN1Label => get('focus_full.footer[1].label');
  String get programSettingsBodyN0RowsN0Sub => get('program_settings.body[0].rows[0].sub');
  String get programSettingsBodyN1ItemsN0Label => get('program_settings.body[1].items[0].label');
  String get programSettingsBodyN1ItemsN0Sub => get('program_settings.body[1].items[0].sub');
  String get programSettingsBodyN1ItemsN1Label => get('program_settings.body[1].items[1].label');
  String get programSettingsBodyN1ItemsN1Sub => get('program_settings.body[1].items[1].sub');
  String get programSettingsBodyN1ItemsN2Label => get('program_settings.body[1].items[2].label');
  String get programSettingsBodyN1ItemsN2Sub => get('program_settings.body[1].items[2].sub');
  String get programSettingsBodyN1Label => get('program_settings.body[1].label');
  String get programSettingsBodyN2Eyebrow => get('program_settings.body[2].eyebrow');
  String get programSettingsBodyN2ChildrenN0Label => get('program_settings.body[2].children[0].label');
  String get programSettingsBodyN2ChildrenN0Sub => get('program_settings.body[2].children[0].sub');
  String get programSettingsBodyN2ChildrenN1Label => get('program_settings.body[2].children[1].label');
  String get programSettingsBodyN3RowsN0Label => get('program_settings.body[3].rows[0].label');
  String get programSettingsBodyN3RowsN0Sub => get('program_settings.body[3].rows[0].sub');
  String get programSettingsBodyN3RowsN0ActionValue => get('program_settings.body[3].rows[0].action.value');
  String get programSettingsBodyN3RowsN1Label => get('program_settings.body[3].rows[1].label');
  String get programSettingsBodyN3RowsN1Sub => get('program_settings.body[3].rows[1].sub');
  String get programSettingsBodyN3Title => get('program_settings.body[3].title');
  String get programSettingsFooterN0ActionThenValue => get('program_settings.footer[0].action.then.value');
  String get programSettingsFooterN0Label => get('program_settings.footer[0].label');
  String get programSettingsHeaderTitle => get('program_settings.header.title');
  String get progressBodyN0OptionsN0 => get('progress.body[0].options[0]');
  String get progressBodyN0OptionsN1 => get('progress.body[0].options[1]');
  String get progressBodyN0OptionsN2 => get('progress.body[0].options[2]');
  String get progressBodyN1Text => get('progress.body[1].text');
  String get progressBodyN2Title => get('progress.body[2].title');
  String get progressBodyN2Caption => get('progress.body[2].caption');
  String get progressBodyN2LabelsN0 => get('progress.body[2].labels[0]');
  String get progressBodyN2LabelsN1 => get('progress.body[2].labels[1]');
  String get progressBodyN2LabelsN2 => get('progress.body[2].labels[2]');
  String get progressBodyN2LabelsN3 => get('progress.body[2].labels[3]');
  String get progressBodyN2LabelsN4 => get('progress.body[2].labels[4]');
  String get progressBodyN2LabelsN5 => get('progress.body[2].labels[5]');
  String get progressBodyN2LabelsN6 => get('progress.body[2].labels[6]');
  String get progressBodyN3Title => get('progress.body[3].title');
  String get progressBodyN3Caption => get('progress.body[3].caption');
  String get progressBodyN3LabelsN0 => get('progress.body[3].labels[0]');
  String get progressBodyN3LabelsN1 => get('progress.body[3].labels[1]');
  String get progressBodyN3LabelsN2 => get('progress.body[3].labels[2]');
  String get progressBodyN3LabelsN3 => get('progress.body[3].labels[3]');
  String get progressBodyN3LabelsN4 => get('progress.body[3].labels[4]');
  String get progressBodyN3LabelsN5 => get('progress.body[3].labels[5]');
  String get progressBodyN3LabelsN6 => get('progress.body[3].labels[6]');
  String get progressBodyN4Eyebrow => get('progress.body[4].eyebrow');
  String get progressBodyN4Title => get('progress.body[4].title');
  String get progressBodyN4Text => get('progress.body[4].text');
  String get progressBodyN4CtaN0Label => get('progress.body[4].cta[0].label');
  String get progressHeaderTitle => get('progress.header.title');
  String get progressEmptyBodyN1Text => get('progress_empty.body[1].text');
  String get progressEmptyBodyN2Text => get('progress_empty.body[2].text');
  String get progressEmptyBodyN3Label => get('progress_empty.body[3].label');
  String get progressEmptyHeaderTitle => get('progress_empty.header.title');
  String get progressErrorBodyN1Text => get('progress_error.body[1].text');
  String get progressErrorBodyN2Text => get('progress_error.body[2].text');
  String get progressErrorBodyN3Label => get('progress_error.body[3].label');
  String get progressErrorBodyN4Text => get('progress_error.body[4].text');
  String get progressErrorHeaderTitle => get('progress_error.header.title');
  String get learnBodyN0Label => get('learn.body[0].label');
  String get learnBodyN0Placeholder => get('learn.body[0].placeholder');
  String get learnBodyN1OptionsN0 => get('learn.body[1].options[0]');
  String get learnBodyN2TagExtra => get('learn.body[2].tagExtra');
  String get learnBodyN2Title => get('learn.body[2].title');
  String get learnBodyN2Text => get('learn.body[2].text');
  String get learnBodyN3TagExtra => get('learn.body[3].tagExtra');
  String get learnBodyN3Title => get('learn.body[3].title');
  String get learnBodyN4TagExtra => get('learn.body[4].tagExtra');
  String get learnBodyN4Title => get('learn.body[4].title');
  String get learnBodyN5Text => get('learn.body[5].text');
  String get learnHeaderTitle => get('learn.header.title');
  String get learnErrorBodyN1Text => get('learn_error.body[1].text');
  String get learnErrorBodyN2Text => get('learn_error.body[2].text');
  String get learnErrorBodyN3Label => get('learn_error.body[3].label');
  String get learnErrorBodyN4Label => get('learn_error.body[4].label');
  String get learnErrorHeaderTitle => get('learn_error.header.title');
  String get learnLessonBodyN0Extra => get('learn_lesson.body[0].extra');
  String get learnLessonBodyN1Text => get('learn_lesson.body[1].text');
  String get learnLessonBodyN2Eyebrow => get('learn_lesson.body[2].eyebrow');
  String get learnLessonBodyN2Title => get('learn_lesson.body[2].title');
  String get learnLessonBodyN2ChildrenN0ItemsN0ActionValue => get('learn_lesson.body[2].children[0].items[0].action.value');
  String get learnLessonBodyN2ChildrenN0ItemsN0Label => get('learn_lesson.body[2].children[0].items[0].label');
  String get learnLessonBodyN2ChildrenN0ItemsN1ActionValue => get('learn_lesson.body[2].children[0].items[1].action.value');
  String get learnLessonBodyN2ChildrenN0ItemsN1Label => get('learn_lesson.body[2].children[0].items[1].label');
  String get learnLessonBodyN3Text => get('learn_lesson.body[3].text');
  String get learnLessonBodyN4Text => get('learn_lesson.body[4].text');
  String get learnLessonBodyN4Caption => get('learn_lesson.body[4].caption');
  String get learnLessonBodyN5Text => get('learn_lesson.body[5].text');
  String get learnLessonFooterN0ActionThenValue => get('learn_lesson.footer[0].action.then.value');
  String get learnLessonFooterN0Label => get('learn_lesson.footer[0].label');
  String get learnLessonFooterN1Label => get('learn_lesson.footer[1].label');
  String get learnLessonFooterN1ActionValue => get('learn_lesson.footer[1].action.value');
  String get learnLessonHeaderTitle => get('learn_lesson.header.title');
  String get learnLessonHeaderPill => get('learn_lesson.header.pill');
  String get supportBodyN0Eyebrow => get('support.body[0].eyebrow');
  String get supportBodyN0Title => get('support.body[0].title');
  String get supportBodyN0Text => get('support.body[0].text');
  String get supportBodyN0ChildrenN0ItemsN0Label => get('support.body[0].children[0].items[0].label');
  String get supportBodyN0ChildrenN0ItemsN1Label => get('support.body[0].children[0].items[1].label');
  String get supportBodyN1RowsN0Label => get('support.body[1].rows[0].label');
  String get supportBodyN1RowsN0Sub => get('support.body[1].rows[0].sub');
  String get supportBodyN1RowsN1Label => get('support.body[1].rows[1].label');
  String get supportBodyN1Title => get('support.body[1].title');
  String get supportBodyN2RowsN0Label => get('support.body[2].rows[0].label');
  String get supportBodyN2RowsN0Sub => get('support.body[2].rows[0].sub');
  String get supportBodyN2Title => get('support.body[2].title');
  String get supportBodyN3Text => get('support.body[3].text');
  String get supportBodyN3ActionsN0Label => get('support.body[3].actions[0].label');
  String get supportBodyN3ActionsN1Label => get('support.body[3].actions[1].label');
  String get supportHeaderTitle => get('support.header.title');
  String get supportEmptyBodyN0Eyebrow => get('support_empty.body[0].eyebrow');
  String get supportEmptyBodyN0Title => get('support_empty.body[0].title');
  String get supportEmptyBodyN0CtaN0Label => get('support_empty.body[0].cta[0].label');
  String get supportEmptyBodyN1Eyebrow => get('support_empty.body[1].eyebrow');
  String get supportEmptyBodyN1Title => get('support_empty.body[1].title');
  String get supportEmptyBodyN1Text => get('support_empty.body[1].text');
  String get supportEmptyBodyN1CtaN0Label => get('support_empty.body[1].cta[0].label');
  String get supportEmptyBodyN2Eyebrow => get('support_empty.body[2].eyebrow');
  String get supportEmptyBodyN2Title => get('support_empty.body[2].title');
  String get supportEmptyBodyN2Text => get('support_empty.body[2].text');
  String get supportEmptyBodyN2CtaN0Label => get('support_empty.body[2].cta[0].label');
  String get supportEmptyBodyN3Text => get('support_empty.body[3].text');
  String get supportEmptyBodyN3ActionsN0Label => get('support_empty.body[3].actions[0].label');
  String get supportEmptyBodyN3ActionsN1Label => get('support_empty.body[3].actions[1].label');
  String get supportEmptyHeaderTitle => get('support_empty.header.title');
  String get supportCallbackBodyN0Text => get('support_callback.body[0].text');
  String get supportCallbackBodyN1Text => get('support_callback.body[1].text');
  String get supportCallbackBodyN2RowsN0N0 => get('support_callback.body[2].rows[0][0]');
  String get supportCallbackBodyN2RowsN0N1 => get('support_callback.body[2].rows[0][1]');
  String get supportCallbackBodyN2RowsN1N0 => get('support_callback.body[2].rows[1][0]');
  String get supportCallbackBodyN2RowsN1N1 => get('support_callback.body[2].rows[1][1]');
  String get supportCallbackBodyN2RowsN2N0 => get('support_callback.body[2].rows[2][0]');
  String get supportCallbackBodyN2RowsN2N1 => get('support_callback.body[2].rows[2][1]');
  String get supportCallbackBodyN2RowsN3N0 => get('support_callback.body[2].rows[3][0]');
  String get supportCallbackBodyN2RowsN3N1 => get('support_callback.body[2].rows[3][1]');
  String get supportCallbackBodyN3Label => get('support_callback.body[3].label');
  String get supportCallbackBodyN3Placeholder => get('support_callback.body[3].placeholder');
  String get supportCallbackFooterN0ActionThenValue => get('support_callback.footer[0].action.then.value');
  String get supportCallbackFooterN0Label => get('support_callback.footer[0].label');
  String get supportCallbackFooterN1Label => get('support_callback.footer[1].label');
  String get supportMessageBodyN0Text => get('support_message.body[0].text');
  String get supportMessageBodyN1Eyebrow => get('support_message.body[1].eyebrow');
  String get supportMessageBodyN1Title => get('support_message.body[1].title');
  String get supportMessageBodyN1Text => get('support_message.body[1].text');
  String get supportMessageFooterN0Label => get('support_message.footer[0].label');
  String get supportMessageFooterN1Label => get('support_message.footer[1].label');
  String get supportMessageCareBodyN0Text => get('support_message_care.body[0].text');
  String get supportMessageCareBodyN1Label => get('support_message_care.body[1].label');
  String get supportMessageCareBodyN1Placeholder => get('support_message_care.body[1].placeholder');
  String get supportMessageCareBodyN2Label => get('support_message_care.body[2].label');
  String get supportMessageCareBodyN2Placeholder => get('support_message_care.body[2].placeholder');
  String get supportMessageCareBodyN3Label => get('support_message_care.body[3].label');
  String get supportMessageCareBodyN3Sub => get('support_message_care.body[3].sub');
  String get supportMessageCareBodyN4Text => get('support_message_care.body[4].text');
  String get supportMessageCareBodyN4ActionsN0Label => get('support_message_care.body[4].actions[0].label');
  String get supportMessageCareBodyN4ActionsN1Label => get('support_message_care.body[4].actions[1].label');
  String get supportMessageCareFooterN0ActionThenValue => get('support_message_care.footer[0].action.then.value');
  String get supportMessageCareFooterN0Label => get('support_message_care.footer[0].label');
  String get supportMessageCareHeaderTitle => get('support_message_care.header.title');
  String get supportAddPersonBodyN0Text => get('support_add_person.body[0].text');
  String get supportAddPersonBodyN1Label => get('support_add_person.body[1].label');
  String get supportAddPersonBodyN1Placeholder => get('support_add_person.body[1].placeholder');
  String get supportAddPersonBodyN2Label => get('support_add_person.body[2].label');
  String get supportAddPersonBodyN3Label => get('support_add_person.body[3].label');
  String get supportAddPersonBodyN4Label => get('support_add_person.body[4].label');
  String get supportAddPersonBodyN4Placeholder => get('support_add_person.body[4].placeholder');
  String get supportAddPersonBodyN5Text => get('support_add_person.body[5].text');
  String get supportAddPersonFooterN0ActionCasesN0ActionThenValue => get('support_add_person.footer[0].action.cases[0].action.then.value');
  String get supportAddPersonFooterN0ActionCasesN1ActionValue => get('support_add_person.footer[0].action.cases[1].action.value');
  String get supportAddPersonFooterN0Label => get('support_add_person.footer[0].label');
  String get supportAddPersonHeaderTitle => get('support_add_person.header.title');
  String get supportConnectBodyN0Text => get('support_connect.body[0].text');
  String get supportConnectBodyN1Label => get('support_connect.body[1].label');
  String get supportConnectBodyN1Placeholder => get('support_connect.body[1].placeholder');
  String get supportConnectBodyN2Text => get('support_connect.body[2].text');
  String get supportConnectFooterN0ActionThenValue => get('support_connect.footer[0].action.then.value');
  String get supportConnectFooterN0Label => get('support_connect.footer[0].label');
  String get supportConnectHeaderTitle => get('support_connect.header.title');
  String get accountBodyN0RowsN0Label => get('account.body[0].rows[0].label');
  String get accountBodyN0RowsN0Sub => get('account.body[0].rows[0].sub');
  String get accountBodyN1RowsN0Label => get('account.body[1].rows[0].label');
  String get accountBodyN1RowsN0Sub => get('account.body[1].rows[0].sub');
  String get accountBodyN1RowsN1Label => get('account.body[1].rows[1].label');
  String get accountBodyN1RowsN1Sub => get('account.body[1].rows[1].sub');
  String get accountBodyN1Title => get('account.body[1].title');
  String get accountBodyN2RowsN0Label => get('account.body[2].rows[0].label');
  String get accountBodyN2RowsN0Sub => get('account.body[2].rows[0].sub');
  String get accountBodyN2RowsN1Label => get('account.body[2].rows[1].label');
  String get accountBodyN2RowsN1Sub => get('account.body[2].rows[1].sub');
  String get accountBodyN2RowsN2Label => get('account.body[2].rows[2].label');
  String get accountBodyN2RowsN2Sub => get('account.body[2].rows[2].sub');
  String get accountBodyN2RowsN3Label => get('account.body[2].rows[3].label');
  String get accountBodyN2RowsN3Sub => get('account.body[2].rows[3].sub');
  String get accountBodyN2Title => get('account.body[2].title');
  String get accountBodyN3RowsN0Label => get('account.body[3].rows[0].label');
  String get accountBodyN3RowsN0Sub => get('account.body[3].rows[0].sub');
  String get accountBodyN3RowsN1Label => get('account.body[3].rows[1].label');
  String get accountBodyN3RowsN1Sub => get('account.body[3].rows[1].sub');
  String get accountBodyN3RowsN1ActionValue => get('account.body[3].rows[1].action.value');
  String get accountBodyN3RowsN2Label => get('account.body[3].rows[2].label');
  String get accountBodyN3Title => get('account.body[3].title');
  String get accountBodyN4Text => get('account.body[4].text');
  String get accountFooterN0Label => get('account.footer[0].label');
  String get accountHeaderTitle => get('account.header.title');
  String get accountSigninMethodsBodyN0Text => get('account_signin_methods.body[0].text');
  String get accountSigninMethodsBodyN1RowsN0Sub => get('account_signin_methods.body[1].rows[0].sub');
  String get accountSigninMethodsBodyN1RowsN0Pill => get('account_signin_methods.body[1].rows[0].pill');
  String get accountSigninMethodsBodyN1RowsN1Sub => get('account_signin_methods.body[1].rows[1].sub');
  String get accountSigninMethodsBodyN1RowsN1ActionCasesN0ActionValue => get('account_signin_methods.body[1].rows[1].action.cases[0].action.value');
  String get accountSigninMethodsBodyN1RowsN1ActionCasesN2ActionValue => get('account_signin_methods.body[1].rows[1].action.cases[2].action.value');
  String get accountSigninMethodsBodyN1RowsN2Label => get('account_signin_methods.body[1].rows[2].label');
  String get accountSigninMethodsBodyN1RowsN2Sub => get('account_signin_methods.body[1].rows[2].sub');
  String get accountSigninMethodsBodyN2Text => get('account_signin_methods.body[2].text');
  String get accountSigninMethodsHeaderTitle => get('account_signin_methods.header.title');
  String get accountProgramsBodyN0Text => get('account_programs.body[0].text');
  String get accountProgramsBodyN1RowsN0Sub => get('account_programs.body[1].rows[0].sub');
  String get accountProgramsBodyN1RowsN1Sub => get('account_programs.body[1].rows[1].sub');
  String get accountProgramsBodyN1RowsN2Sub => get('account_programs.body[1].rows[2].sub');
  String get accountProgramsBodyN1RowsN3Sub => get('account_programs.body[1].rows[3].sub');
  String get accountProgramsFooterN0Label => get('account_programs.footer[0].label');
  String get accountProgramsHeaderTitle => get('account_programs.header.title');
  String get accountLeaveBodyN0Text => get('account_leave.body[0].text');
  String get accountLeaveBodyN1Text => get('account_leave.body[1].text');
  String get accountLeaveBodyN2ItemsN0Label => get('account_leave.body[2].items[0].label');
  String get accountLeaveBodyN2ItemsN0Sub => get('account_leave.body[2].items[0].sub');
  String get accountLeaveBodyN2ItemsN0Badge => get('account_leave.body[2].items[0].badge');
  String get accountLeaveBodyN2ItemsN1Label => get('account_leave.body[2].items[1].label');
  String get accountLeaveBodyN2ItemsN1Sub => get('account_leave.body[2].items[1].sub');
  String get accountLeaveFooterN0ActionThenValue => get('account_leave.footer[0].action.then.value');
  String get accountLeaveFooterN0Label => get('account_leave.footer[0].label');
  String get accountLeaveFooterN1Label => get('account_leave.footer[1].label');
  String get accountNotificationsBodyN0ChildrenN0Label => get('account_notifications.body[0].children[0].label');
  String get accountNotificationsBodyN0ChildrenN0Sub => get('account_notifications.body[0].children[0].sub');
  String get accountNotificationsBodyN0ChildrenN1Label => get('account_notifications.body[0].children[1].label');
  String get accountNotificationsBodyN0ChildrenN1Sub => get('account_notifications.body[0].children[1].sub');
  String get accountNotificationsBodyN0ChildrenN2Label => get('account_notifications.body[0].children[2].label');
  String get accountNotificationsBodyN0ChildrenN2Sub => get('account_notifications.body[0].children[2].sub');
  String get accountNotificationsBodyN1RowsN0Sub => get('account_notifications.body[1].rows[0].sub');
  String get accountNotificationsBodyN1RowsN0ActionValue => get('account_notifications.body[1].rows[0].action.value');
  String get accountNotificationsBodyN1RowsN1Sub => get('account_notifications.body[1].rows[1].sub');
  String get accountNotificationsBodyN1RowsN1ActionValue => get('account_notifications.body[1].rows[1].action.value');
  String get accountNotificationsBodyN1Title => get('account_notifications.body[1].title');
  String get accountNotificationsBodyN2Eyebrow => get('account_notifications.body[2].eyebrow');
  String get accountNotificationsBodyN2Text => get('account_notifications.body[2].text');
  String get accountNotificationsFooterN0ActionThenValue => get('account_notifications.footer[0].action.then.value');
  String get accountNotificationsFooterN0Label => get('account_notifications.footer[0].label');
  String get accountNotificationsHeaderTitle => get('account_notifications.header.title');
  String get accountPrivacyBodyN0Eyebrow => get('account_privacy.body[0].eyebrow');
  String get accountPrivacyBodyN0ChildrenN0Label => get('account_privacy.body[0].children[0].label');
  String get accountPrivacyBodyN0ChildrenN0Sub => get('account_privacy.body[0].children[0].sub');
  String get accountPrivacyBodyN0ChildrenN1Label => get('account_privacy.body[0].children[1].label');
  String get accountPrivacyBodyN0ChildrenN1Sub => get('account_privacy.body[0].children[1].sub');
  String get accountPrivacyBodyN0ChildrenN2Label => get('account_privacy.body[0].children[2].label');
  String get accountPrivacyBodyN0ChildrenN2Sub => get('account_privacy.body[0].children[2].sub');
  String get accountPrivacyBodyN1RowsN0Label => get('account_privacy.body[1].rows[0].label');
  String get accountPrivacyBodyN1RowsN0Sub => get('account_privacy.body[1].rows[0].sub');
  String get accountPrivacyBodyN1RowsN1Label => get('account_privacy.body[1].rows[1].label');
  String get accountPrivacyBodyN1RowsN1Sub => get('account_privacy.body[1].rows[1].sub');
  String get accountPrivacyBodyN1RowsN1ActionValue => get('account_privacy.body[1].rows[1].action.value');
  String get accountPrivacyBodyN1RowsN2Label => get('account_privacy.body[1].rows[2].label');
  String get accountPrivacyBodyN2Text => get('account_privacy.body[2].text');
  String get accountPrivacyFooterN0ActionThenValue => get('account_privacy.footer[0].action.then.value');
  String get accountPrivacyFooterN0Label => get('account_privacy.footer[0].label');
  String get accountPrivacyHeaderTitle => get('account_privacy.header.title');
  String get accountDataBodyN0RowsN0Label => get('account_data.body[0].rows[0].label');
  String get accountDataBodyN0RowsN0Sub => get('account_data.body[0].rows[0].sub');
  String get accountDataBodyN0RowsN0ActionThenValue => get('account_data.body[0].rows[0].action.then.value');
  String get accountDataBodyN0RowsN1Label => get('account_data.body[0].rows[1].label');
  String get accountDataBodyN0RowsN1Sub => get('account_data.body[0].rows[1].sub');
  String get accountDataBodyN0Title => get('account_data.body[0].title');
  String get accountDataBodyN1RowsN0Label => get('account_data.body[1].rows[0].label');
  String get accountDataBodyN1RowsN0Sub => get('account_data.body[1].rows[0].sub');
  String get accountDataBodyN1Title => get('account_data.body[1].title');
  String get accountDataHeaderTitle => get('account_data.header.title');
  String get accountDeleteBodyN0Text => get('account_delete.body[0].text');
  String get accountDeleteBodyN1RowsN0N0 => get('account_delete.body[1].rows[0][0]');
  String get accountDeleteBodyN1RowsN1N0 => get('account_delete.body[1].rows[1][0]');
  String get accountDeleteBodyN1RowsN2N0 => get('account_delete.body[1].rows[2][0]');
  String get accountDeleteBodyN1RowsN3N0 => get('account_delete.body[1].rows[3][0]');
  String get accountDeleteBodyN1RowsN3N1 => get('account_delete.body[1].rows[3][1]');
  String get accountDeleteBodyN2Text => get('account_delete.body[2].text');
  String get accountDeleteBodyN3Label => get('account_delete.body[3].label');
  String get accountDeleteBodyN4Label => get('account_delete.body[4].label');
  String get accountDeleteBodyN4Placeholder => get('account_delete.body[4].placeholder');
  String get accountDeleteBodyN5Label => get('account_delete.body[5].label');
  String get accountDeleteBodyN5Hint => get('account_delete.body[5].hint');
  String get accountDeleteFooterN0Label => get('account_delete.footer[0].label');
  String get accountDeleteHeaderTitle => get('account_delete.header.title');
  String get accountDeletedBodyN1Text => get('account_deleted.body[1].text');
  String get accountDeletedBodyN2RowsN0N0 => get('account_deleted.body[2].rows[0][0]');
  String get accountDeletedBodyN2RowsN0N1 => get('account_deleted.body[2].rows[0][1]');
  String get accountDeletedBodyN2RowsN1N0 => get('account_deleted.body[2].rows[1][0]');
  String get accountDeletedBodyN2RowsN1N1 => get('account_deleted.body[2].rows[1][1]');
  String get accountDeletedBodyN2RowsN2N0 => get('account_deleted.body[2].rows[2][0]');
  String get accountDeletedBodyN2RowsN2N1 => get('account_deleted.body[2].rows[2][1]');
  String get accountDeletedBodyN3Text => get('account_deleted.body[3].text');
  String get accountDeletedFooterN0Label => get('account_deleted.footer[0].label');
  String get accountDeletedHeaderTitle => get('account_deleted.header.title');
  String get accountSignoutBodyN0Text => get('account_signout.body[0].text');
  String get accountSignoutBodyN1Text => get('account_signout.body[1].text');
  String get accountSignoutFooterN0Label => get('account_signout.footer[0].label');
  String get accountSignoutFooterN1Label => get('account_signout.footer[1].label');
  String get sysUpdateBodyN1Text => get('sys_update.body[1].text');
  String get sysUpdateBodyN2Text => get('sys_update.body[2].text');
  String get sysUpdateFooterN0Label => get('sys_update.footer[0].label');
  String get sysUpdateFooterN1Label => get('sys_update.footer[1].label');
  String get sysUpdateHeaderTitle => get('sys_update.header.title');
  String get bfIntroBodyN0Extra => get('bf_intro.body[0].extra');
  String get bfIntroBodyN1Text => get('bf_intro.body[1].text');
  String get bfIntroBodyN2RowsN0N0 => get('bf_intro.body[2].rows[0][0]');
  String get bfIntroBodyN2RowsN0N1 => get('bf_intro.body[2].rows[0][1]');
  String get bfIntroBodyN2RowsN1N0 => get('bf_intro.body[2].rows[1][0]');
  String get bfIntroBodyN2RowsN1N1 => get('bf_intro.body[2].rows[1][1]');
  String get bfIntroBodyN2RowsN2N0 => get('bf_intro.body[2].rows[2][0]');
  String get bfIntroBodyN2RowsN2N1 => get('bf_intro.body[2].rows[2][1]');
  String get bfIntroBodyN3Text => get('bf_intro.body[3].text');
  String get bfIntroFooterN0Label => get('bf_intro.footer[0].label');
  String get bfIntroFooterN1ActionThenValue => get('bf_intro.footer[1].action.then.value');
  String get bfIntroFooterN1Label => get('bf_intro.footer[1].label');
  String get bfIntroHeaderPill => get('bf_intro.header.pill');
  String get bfQ1BodyN1Text => get('bf_q1.body[1].text');
  String get bfQ1BodyN2Text => get('bf_q1.body[2].text');
  String get bfQ1BodyN3ItemsN0Label => get('bf_q1.body[3].items[0].label');
  String get bfQ1BodyN3ItemsN1Label => get('bf_q1.body[3].items[1].label');
  String get bfQ1BodyN3ItemsN4Label => get('bf_q1.body[3].items[4].label');
  String get bfQ1BodyN4Title => get('bf_q1.body[4].title');
  String get bfQ1BodyN4Text => get('bf_q1.body[4].text');
  String get bfQ1FooterN0Label => get('bf_q1.footer[0].label');
  String get bfQ1HeaderTitle => get('bf_q1.header.title');
  String get bfQ1HeaderPill => get('bf_q1.header.pill');
  String get bfQ2BodyN1Text => get('bf_q2.body[1].text');
  String get bfQ2BodyN2Text => get('bf_q2.body[2].text');
  String get bfQ2BodyN3OptionsN0 => get('bf_q2.body[3].options[0]');
  String get bfQ2BodyN3OptionsN1 => get('bf_q2.body[3].options[1]');
  String get bfQ2BodyN3OptionsN2 => get('bf_q2.body[3].options[2]');
  String get bfQ2BodyN3OptionsN3 => get('bf_q2.body[3].options[3]');
  String get bfQ2BodyN3OptionsN4 => get('bf_q2.body[3].options[4]');
  String get bfQ2BodyN3OptionsN5 => get('bf_q2.body[3].options[5]');
  String get bfQ2BodyN3OptionsN6 => get('bf_q2.body[3].options[6]');
  String get bfQ2BodyN3OptionsN7 => get('bf_q2.body[3].options[7]');
  String get bfQ2BodyN3OptionsN8 => get('bf_q2.body[3].options[8]');
  String get bfQ2BodyN3OptionsN9 => get('bf_q2.body[3].options[9]');
  String get bfQ2BodyN4Label => get('bf_q2.body[4].label');
  String get bfQ2BodyN4Placeholder => get('bf_q2.body[4].placeholder');
  String get bfQ2BodyN5Text => get('bf_q2.body[5].text');
  String get bfQ2FooterN0Label => get('bf_q2.footer[0].label');
  String get bfQ2HeaderTitle => get('bf_q2.header.title');
  String get bfQ2HeaderPill => get('bf_q2.header.pill');
  String get bfQ3BodyN1Text => get('bf_q3.body[1].text');
  String get bfQ3BodyN2Text => get('bf_q3.body[2].text');
  String get bfQ3BodyN3OptionsN0 => get('bf_q3.body[3].options[0]');
  String get bfQ3BodyN3OptionsN1 => get('bf_q3.body[3].options[1]');
  String get bfQ3BodyN3OptionsN2 => get('bf_q3.body[3].options[2]');
  String get bfQ3BodyN3OptionsN3 => get('bf_q3.body[3].options[3]');
  String get bfQ3BodyN3OptionsN4 => get('bf_q3.body[3].options[4]');
  String get bfQ3BodyN3OptionsN5 => get('bf_q3.body[3].options[5]');
  String get bfQ3BodyN4Eyebrow => get('bf_q3.body[4].eyebrow');
  String get bfQ3BodyN4ChildrenN0Text => get('bf_q3.body[4].children[0].text');
  String get bfQ3FooterN0Label => get('bf_q3.footer[0].label');
  String get bfQ3HeaderTitle => get('bf_q3.header.title');
  String get bfQ3HeaderPill => get('bf_q3.header.pill');
  String get bfPathBodyN0Text => get('bf_path.body[0].text');
  String get bfPathBodyN1Text => get('bf_path.body[1].text');
  String get bfPathBodyN2ItemsN0Label => get('bf_path.body[2].items[0].label');
  String get bfPathBodyN2ItemsN0Sub => get('bf_path.body[2].items[0].sub');
  String get bfPathBodyN2ItemsN0Badge => get('bf_path.body[2].items[0].badge');
  String get bfPathBodyN2ItemsN1Label => get('bf_path.body[2].items[1].label');
  String get bfPathBodyN2ItemsN1Sub => get('bf_path.body[2].items[1].sub');
  String get bfPathBodyN2ItemsN2Label => get('bf_path.body[2].items[2].label');
  String get bfPathBodyN2ItemsN2Sub => get('bf_path.body[2].items[2].sub');
  String get bfPathBodyN2ItemsN3Label => get('bf_path.body[2].items[3].label');
  String get bfPathBodyN2ItemsN3Sub => get('bf_path.body[2].items[3].sub');
  String get bfPathBodyN3Title => get('bf_path.body[3].title');
  String get bfPathBodyN3Text => get('bf_path.body[3].text');
  String get bfPathFooterN0Label => get('bf_path.footer[0].label');
  String get bfPathHeaderTitle => get('bf_path.header.title');
  String get bfPathHeaderPill => get('bf_path.header.pill');
  String get bfDateBodyN0Text => get('bf_date.body[0].text');
  String get bfDateBodyN1Text => get('bf_date.body[1].text');
  String get bfDateBodyN2Month => get('bf_date.body[2].month');
  String get bfDateBodyN3Eyebrow => get('bf_date.body[3].eyebrow');
  String get bfDateBodyN3Title => get('bf_date.body[3].title');
  String get bfDateBodyN3Text => get('bf_date.body[3].text');
  String get bfDateBodyN4Label => get('bf_date.body[4].label');
  String get bfDateBodyN4Sub => get('bf_date.body[4].sub');
  String get bfDateFooterN0Label => get('bf_date.footer[0].label');
  String get bfDateHeaderTitle => get('bf_date.header.title');
  String get bfDateHeaderPill => get('bf_date.header.pill');
  String get bfStepdownBodyN0Text => get('bf_stepdown.body[0].text');
  String get bfStepdownBodyN1Text => get('bf_stepdown.body[1].text');
  String get bfStepdownBodyN2RowsN0N0 => get('bf_stepdown.body[2].rows[0][0]');
  String get bfStepdownBodyN2RowsN0N1 => get('bf_stepdown.body[2].rows[0][1]');
  String get bfStepdownBodyN2RowsN1N0 => get('bf_stepdown.body[2].rows[1][0]');
  String get bfStepdownBodyN2RowsN1N1 => get('bf_stepdown.body[2].rows[1][1]');
  String get bfStepdownBodyN2RowsN2N0 => get('bf_stepdown.body[2].rows[2][0]');
  String get bfStepdownBodyN2RowsN2N1 => get('bf_stepdown.body[2].rows[2][1]');
  String get bfStepdownBodyN2RowsN3N0 => get('bf_stepdown.body[2].rows[3][0]');
  String get bfStepdownBodyN2RowsN3N1 => get('bf_stepdown.body[2].rows[3][1]');
  String get bfStepdownBodyN2RowsN4N0 => get('bf_stepdown.body[2].rows[4][0]');
  String get bfStepdownBodyN3Text => get('bf_stepdown.body[3].text');
  String get bfStepdownFooterN0Label => get('bf_stepdown.footer[0].label');
  String get bfStepdownHeaderTitle => get('bf_stepdown.header.title');
  String get bfStepdownHeaderPill => get('bf_stepdown.header.pill');
  String get bfSupportBodyN0Text => get('bf_support.body[0].text');
  String get bfSupportBodyN1RowsN0Label => get('bf_support.body[1].rows[0].label');
  String get bfSupportBodyN1RowsN0Sub => get('bf_support.body[1].rows[0].sub');
  String get bfSupportBodyN1RowsN1Label => get('bf_support.body[1].rows[1].label');
  String get bfSupportBodyN1Title => get('bf_support.body[1].title');
  String get bfSupportBodyN2Eyebrow => get('bf_support.body[2].eyebrow');
  String get bfSupportBodyN2ChildrenN0ItemsN0Label => get('bf_support.body[2].children[0].items[0].label');
  String get bfSupportBodyN2ChildrenN0ItemsN1Label => get('bf_support.body[2].children[0].items[1].label');
  String get bfSupportBodyN2ChildrenN0ItemsN2Label => get('bf_support.body[2].children[0].items[2].label');
  String get bfSupportBodyN3Label => get('bf_support.body[3].label');
  String get bfSupportBodyN3Sub => get('bf_support.body[3].sub');
  String get bfSupportFooterN0Label => get('bf_support.footer[0].label');
  String get bfSupportHeaderTitle => get('bf_support.header.title');
  String get bfSupportHeaderPill => get('bf_support.header.pill');
  String get bfReviewBodyN0Text => get('bf_review.body[0].text');
  String get bfReviewBodyN1Text => get('bf_review.body[1].text');
  String get bfReviewBodyN2RowsN0Label => get('bf_review.body[2].rows[0].label');
  String get bfReviewBodyN2RowsN0Sub => get('bf_review.body[2].rows[0].sub');
  String get bfReviewBodyN2RowsN1Label => get('bf_review.body[2].rows[1].label');
  String get bfReviewBodyN2RowsN1Sub => get('bf_review.body[2].rows[1].sub');
  String get bfReviewBodyN2RowsN2Label => get('bf_review.body[2].rows[2].label');
  String get bfReviewBodyN2RowsN2Sub => get('bf_review.body[2].rows[2].sub');
  String get bfReviewBodyN2RowsN3Label => get('bf_review.body[2].rows[3].label');
  String get bfReviewBodyN2RowsN3Sub => get('bf_review.body[2].rows[3].sub');
  String get bfReviewBodyN2RowsN4Label => get('bf_review.body[2].rows[4].label');
  String get bfReviewBodyN2RowsN4Sub => get('bf_review.body[2].rows[4].sub');
  String get bfReviewBodyN3Text => get('bf_review.body[3].text');
  String get bfReviewFooterN0Label => get('bf_review.footer[0].label');
  String get bfReviewFooterN1Label => get('bf_review.footer[1].label');
  String get bfReviewHeaderTitle => get('bf_review.header.title');
  String get bfReviewHeaderPill => get('bf_review.header.pill');
  String get bfHomeBodyN0Eyebrow => get('bf_home.body[0].eyebrow');
  String get bfHomeBodyN0ChildrenN0Value => get('bf_home.body[0].children[0].value');
  String get bfHomeBodyN0ChildrenN0Caption => get('bf_home.body[0].children[0].caption');
  String get bfHomeBodyN1Title => get('bf_home.body[1].title');
  String get bfHomeBodyN1Text => get('bf_home.body[1].text');
  String get bfHomeBodyN1CtaN0Label => get('bf_home.body[1].cta[0].label');
  String get bfHomeBodyN2Eyebrow => get('bf_home.body[2].eyebrow');
  String get bfHomeBodyN2ChildrenN0ItemsN0Label => get('bf_home.body[2].children[0].items[0].label');
  String get bfHomeBodyN2ChildrenN0ItemsN0Sub => get('bf_home.body[2].children[0].items[0].sub');
  String get bfHomeBodyN3Eyebrow => get('bf_home.body[3].eyebrow');
  String get bfHomeBodyN3ChildrenN0Text => get('bf_home.body[3].children[0].text');
  String get bfHomeBodyN4RowsN0Label => get('bf_home.body[4].rows[0].label');
  String get bfHomeBodyN4RowsN0Sub => get('bf_home.body[4].rows[0].sub');
  String get bfHomeBodyN4RowsN1Label => get('bf_home.body[4].rows[1].label');
  String get bfHomeBodyN4RowsN1Sub => get('bf_home.body[4].rows[1].sub');
  String get bfHomeBodyN4RowsN2Label => get('bf_home.body[4].rows[2].label');
  String get bfHomeBodyN4RowsN2Sub => get('bf_home.body[4].rows[2].sub');
  String get bfHomeBodyN4RowsN3Label => get('bf_home.body[4].rows[3].label');
  String get bfHomeBodyN4RowsN4Label => get('bf_home.body[4].rows[4].label');
  String get bfHomeBodyN4RowsN4Sub => get('bf_home.body[4].rows[4].sub');
  String get bfHomeQuitdayBodyN0Text => get('bf_home_quitday.body[0].text');
  String get bfHomeQuitdayBodyN1Text => get('bf_home_quitday.body[1].text');
  String get bfHomeQuitdayBodyN2Eyebrow => get('bf_home_quitday.body[2].eyebrow');
  String get bfHomeQuitdayBodyN2ChildrenN0Value => get('bf_home_quitday.body[2].children[0].value');
  String get bfHomeQuitdayBodyN2ChildrenN0Caption => get('bf_home_quitday.body[2].children[0].caption');
  String get bfHomeQuitdayBodyN3Title => get('bf_home_quitday.body[3].title');
  String get bfHomeQuitdayBodyN3Text => get('bf_home_quitday.body[3].text');
  String get bfHomeQuitdayBodyN3CtaN0Label => get('bf_home_quitday.body[3].cta[0].label');
  String get bfHomeQuitdayBodyN4Title => get('bf_home_quitday.body[4].title');
  String get bfHomeQuitdayBodyN4Text => get('bf_home_quitday.body[4].text');
  String get bfHomeQuitdayBodyN5Eyebrow => get('bf_home_quitday.body[5].eyebrow');
  String get bfHomeQuitdayBodyN5ChildrenN0ItemsN0Label => get('bf_home_quitday.body[5].children[0].items[0].label');
  String get bfHomeQuitdayBodyN5ChildrenN0ItemsN0Sub => get('bf_home_quitday.body[5].children[0].items[0].sub');
  String get bfHomeQuitdayBodyN6RowsN0Label => get('bf_home_quitday.body[6].rows[0].label');
  String get bfHomeQuitdayBodyN6RowsN1Label => get('bf_home_quitday.body[6].rows[1].label');
  String get bfHomeQuitdayBodyN6RowsN1Sub => get('bf_home_quitday.body[6].rows[1].sub');
  String get bfHomeExploreBodyN0Text => get('bf_home_explore.body[0].text');
  String get bfHomeExploreBodyN1Text => get('bf_home_explore.body[1].text');
  String get bfHomeExploreBodyN2Title => get('bf_home_explore.body[2].title');
  String get bfHomeExploreBodyN2Text => get('bf_home_explore.body[2].text');
  String get bfHomeExploreBodyN2CtaN0Label => get('bf_home_explore.body[2].cta[0].label');
  String get bfHomeExploreBodyN3Title => get('bf_home_explore.body[3].title');
  String get bfHomeExploreBodyN3Text => get('bf_home_explore.body[3].text');
  String get bfHomeExploreBodyN4Title => get('bf_home_explore.body[4].title');
  String get bfHomeExploreBodyN4Text => get('bf_home_explore.body[4].text');
  String get bfHomeExploreBodyN5Title => get('bf_home_explore.body[5].title');
  String get bfHomeExploreBodyN5Text => get('bf_home_explore.body[5].text');
  String get bfHomeExploreBodyN5CtaN0Label => get('bf_home_explore.body[5].cta[0].label');
  String get bfSlipBodyN0Text => get('bf_slip.body[0].text');
  String get bfSlipBodyN1Text => get('bf_slip.body[1].text');
  String get bfSlipBodyN2RowsN0N0 => get('bf_slip.body[2].rows[0][0]');
  String get bfSlipBodyN2RowsN0N1 => get('bf_slip.body[2].rows[0][1]');
  String get bfSlipBodyN3OptionsN0 => get('bf_slip.body[3].options[0]');
  String get bfSlipBodyN3OptionsN1 => get('bf_slip.body[3].options[1]');
  String get bfSlipBodyN3OptionsN2 => get('bf_slip.body[3].options[2]');
  String get bfSlipBodyN3OptionsN3 => get('bf_slip.body[3].options[3]');
  String get bfSlipBodyN3Label => get('bf_slip.body[3].label');
  String get bfSlipBodyN4OptionsN0 => get('bf_slip.body[4].options[0]');
  String get bfSlipBodyN4OptionsN1 => get('bf_slip.body[4].options[1]');
  String get bfSlipBodyN4OptionsN2 => get('bf_slip.body[4].options[2]');
  String get bfSlipBodyN4OptionsN3 => get('bf_slip.body[4].options[3]');
  String get bfSlipBodyN4Label => get('bf_slip.body[4].label');
  String get bfSlipBodyN5ItemsN0Label => get('bf_slip.body[5].items[0].label');
  String get bfSlipBodyN5ItemsN0Sub => get('bf_slip.body[5].items[0].sub');
  String get bfSlipBodyN5ItemsN0Badge => get('bf_slip.body[5].items[0].badge');
  String get bfSlipBodyN5ItemsN1Label => get('bf_slip.body[5].items[1].label');
  String get bfSlipFooterN0Label => get('bf_slip.footer[0].label');
  String get bfSlipFooterN1Label => get('bf_slip.footer[1].label');
  String get bfSlipHeaderTitle => get('bf_slip.header.title');
  String get bfSlipHeaderPill => get('bf_slip.header.pill');
  String get bfMedsBodyN0Text => get('bf_meds.body[0].text');
  String get bfMedsBodyN1Eyebrow => get('bf_meds.body[1].eyebrow');
  String get bfMedsBodyN1Title => get('bf_meds.body[1].title');
  String get bfMedsBodyN1Text => get('bf_meds.body[1].text');
  String get bfMedsBodyN1ChildrenN0ItemsN0ActionValue => get('bf_meds.body[1].children[0].items[0].action.value');
  String get bfMedsBodyN1ChildrenN0ItemsN0Label => get('bf_meds.body[1].children[0].items[0].label');
  String get bfMedsBodyN1ChildrenN0ItemsN1ActionValue => get('bf_meds.body[1].children[0].items[1].action.value');
  String get bfMedsBodyN1ChildrenN0ItemsN1Label => get('bf_meds.body[1].children[0].items[1].label');
  String get bfMedsBodyN2RowsN0Label => get('bf_meds.body[2].rows[0].label');
  String get bfMedsBodyN2RowsN0Sub => get('bf_meds.body[2].rows[0].sub');
  String get bfMedsBodyN2RowsN1Label => get('bf_meds.body[2].rows[1].label');
  String get bfMedsBodyN2RowsN1Sub => get('bf_meds.body[2].rows[1].sub');
  String get bfMedsBodyN2Title => get('bf_meds.body[2].title');
  String get bfMedsBodyN3Title => get('bf_meds.body[3].title');
  String get bfMedsBodyN3Text => get('bf_meds.body[3].text');
  String get bfMedsBodyN4Title => get('bf_meds.body[4].title');
  String get bfMedsBodyN4Text => get('bf_meds.body[4].text');
  String get bfMedsFooterN0Label => get('bf_meds.footer[0].label');
  String get bfMedsHeaderTitle => get('bf_meds.header.title');
  String get bfMedsEditBodyN0Text => get('bf_meds_edit.body[0].text');
  String get bfMedsEditBodyN1Label => get('bf_meds_edit.body[1].label');
  String get bfMedsEditBodyN1Placeholder => get('bf_meds_edit.body[1].placeholder');
  String get bfMedsEditBodyN2Label => get('bf_meds_edit.body[2].label');
  String get bfMedsEditBodyN2Placeholder => get('bf_meds_edit.body[2].placeholder');
  String get bfMedsEditBodyN3Label => get('bf_meds_edit.body[3].label');
  String get bfMedsEditBodyN3Placeholder => get('bf_meds_edit.body[3].placeholder');
  String get bfMedsEditBodyN4Label => get('bf_meds_edit.body[4].label');
  String get bfMedsEditBodyN4Sub => get('bf_meds_edit.body[4].sub');
  String get bfMedsEditBodyN5Text => get('bf_meds_edit.body[5].text');
  String get bfMedsEditFooterN0ActionThenValue => get('bf_meds_edit.footer[0].action.then.value');
  String get bfMedsEditFooterN0Label => get('bf_meds_edit.footer[0].label');
  String get bfMedsEditHeaderTitle => get('bf_meds_edit.header.title');
  String get bfProgressBodyN0OptionsN0 => get('bf_progress.body[0].options[0]');
  String get bfProgressBodyN0OptionsN1 => get('bf_progress.body[0].options[1]');
  String get bfProgressBodyN0OptionsN2 => get('bf_progress.body[0].options[2]');
  String get bfProgressBodyN1Title => get('bf_progress.body[1].title');
  String get bfProgressBodyN1Caption => get('bf_progress.body[1].caption');
  String get bfProgressBodyN1LabelsN0 => get('bf_progress.body[1].labels[0]');
  String get bfProgressBodyN1LabelsN1 => get('bf_progress.body[1].labels[1]');
  String get bfProgressBodyN1LabelsN2 => get('bf_progress.body[1].labels[2]');
  String get bfProgressBodyN1LabelsN3 => get('bf_progress.body[1].labels[3]');
  String get bfProgressBodyN1LabelsN4 => get('bf_progress.body[1].labels[4]');
  String get bfProgressBodyN1LabelsN5 => get('bf_progress.body[1].labels[5]');
  String get bfProgressBodyN1LabelsN6 => get('bf_progress.body[1].labels[6]');
  String get bfProgressBodyN2ItemsN0Label => get('bf_progress.body[2].items[0].label');
  String get bfProgressBodyN2ItemsN0Sub => get('bf_progress.body[2].items[0].sub');
  String get bfProgressBodyN2ItemsN1Label => get('bf_progress.body[2].items[1].label');
  String get bfProgressBodyN2ItemsN1Sub => get('bf_progress.body[2].items[1].sub');
  String get bfProgressBodyN2ItemsN2Label => get('bf_progress.body[2].items[2].label');
  String get bfProgressBodyN2ItemsN2Value => get('bf_progress.body[2].items[2].value');
  String get bfProgressBodyN2ItemsN2Sub => get('bf_progress.body[2].items[2].sub');
  String get bfProgressBodyN2ItemsN3Label => get('bf_progress.body[2].items[3].label');
  String get bfProgressBodyN2ItemsN3Value => get('bf_progress.body[2].items[3].value');
  String get bfProgressBodyN2ItemsN3Sub => get('bf_progress.body[2].items[3].sub');
  String get bfProgressBodyN3RowsN0Label => get('bf_progress.body[3].rows[0].label');
  String get bfProgressBodyN3RowsN0Sub => get('bf_progress.body[3].rows[0].sub');
  String get bfProgressHeaderTitle => get('bf_progress.header.title');
  String get bfEstimatesBodyN0Text => get('bf_estimates.body[0].text');
  String get bfEstimatesBodyN1RowsN0N0 => get('bf_estimates.body[1].rows[0][0]');
  String get bfEstimatesBodyN1RowsN0N1 => get('bf_estimates.body[1].rows[0][1]');
  String get bfEstimatesBodyN1RowsN1N0 => get('bf_estimates.body[1].rows[1][0]');
  String get bfEstimatesBodyN1RowsN1N1 => get('bf_estimates.body[1].rows[1][1]');
  String get bfEstimatesBodyN1RowsN2N0 => get('bf_estimates.body[1].rows[2][0]');
  String get bfEstimatesBodyN1RowsN2N1 => get('bf_estimates.body[1].rows[2][1]');
  String get bfEstimatesBodyN1RowsN3N0 => get('bf_estimates.body[1].rows[3][0]');
  String get bfEstimatesBodyN1RowsN3N1 => get('bf_estimates.body[1].rows[3][1]');
  String get bfEstimatesBodyN2Text => get('bf_estimates.body[2].text');
  String get bfEstimatesFooterN0ActionValue => get('bf_estimates.footer[0].action.value');
  String get bfEstimatesFooterN0Label => get('bf_estimates.footer[0].label');
  String get bfEstimatesFooterN1Label => get('bf_estimates.footer[1].label');
  String get sfIntroBodyN0Extra => get('sf_intro.body[0].extra');
  String get sfIntroBodyN1Text => get('sf_intro.body[1].text');
  String get sfIntroBodyN2RowsN0N0 => get('sf_intro.body[2].rows[0][0]');
  String get sfIntroBodyN2RowsN0N1 => get('sf_intro.body[2].rows[0][1]');
  String get sfIntroBodyN2RowsN1N0 => get('sf_intro.body[2].rows[1][0]');
  String get sfIntroBodyN2RowsN1N1 => get('sf_intro.body[2].rows[1][1]');
  String get sfIntroBodyN2RowsN2N0 => get('sf_intro.body[2].rows[2][0]');
  String get sfIntroBodyN2RowsN2N1 => get('sf_intro.body[2].rows[2][1]');
  String get sfIntroBodyN3Text => get('sf_intro.body[3].text');
  String get sfIntroFooterN0Label => get('sf_intro.footer[0].label');
  String get sfIntroFooterN1ActionThenValue => get('sf_intro.footer[1].action.then.value');
  String get sfIntroFooterN1Label => get('sf_intro.footer[1].label');
  String get sfIntroHeaderPill => get('sf_intro.header.pill');
  String get sfQ1BodyN1Text => get('sf_q1.body[1].text');
  String get sfQ1BodyN2Text => get('sf_q1.body[2].text');
  String get sfQ1BodyN3ItemsN0Label => get('sf_q1.body[3].items[0].label');
  String get sfQ1BodyN3ItemsN1Label => get('sf_q1.body[3].items[1].label');
  String get sfQ1BodyN3ItemsN2Label => get('sf_q1.body[3].items[2].label');
  String get sfQ1BodyN3ItemsN3Label => get('sf_q1.body[3].items[3].label');
  String get sfQ1BodyN4OptionsN0 => get('sf_q1.body[4].options[0]');
  String get sfQ1BodyN4OptionsN1 => get('sf_q1.body[4].options[1]');
  String get sfQ1BodyN4OptionsN2 => get('sf_q1.body[4].options[2]');
  String get sfQ1BodyN4OptionsN3 => get('sf_q1.body[4].options[3]');
  String get sfQ1BodyN4OptionsN4 => get('sf_q1.body[4].options[4]');
  String get sfQ1BodyN4Label => get('sf_q1.body[4].label');
  String get sfQ1FooterN0Label => get('sf_q1.footer[0].label');
  String get sfQ1HeaderTitle => get('sf_q1.header.title');
  String get sfQ1HeaderPill => get('sf_q1.header.pill');
  String get sfQ2BodyN1Text => get('sf_q2.body[1].text');
  String get sfQ2BodyN2OptionsN0 => get('sf_q2.body[2].options[0]');
  String get sfQ2BodyN2OptionsN1 => get('sf_q2.body[2].options[1]');
  String get sfQ2BodyN2OptionsN2 => get('sf_q2.body[2].options[2]');
  String get sfQ2BodyN2OptionsN3 => get('sf_q2.body[2].options[3]');
  String get sfQ2BodyN2OptionsN4 => get('sf_q2.body[2].options[4]');
  String get sfQ2BodyN2OptionsN5 => get('sf_q2.body[2].options[5]');
  String get sfQ2BodyN2OptionsN6 => get('sf_q2.body[2].options[6]');
  String get sfQ2BodyN2OptionsN7 => get('sf_q2.body[2].options[7]');
  String get sfQ2BodyN3OptionsN0 => get('sf_q2.body[3].options[0]');
  String get sfQ2BodyN3OptionsN1 => get('sf_q2.body[3].options[1]');
  String get sfQ2BodyN3OptionsN2 => get('sf_q2.body[3].options[2]');
  String get sfQ2BodyN3Label => get('sf_q2.body[3].label');
  String get sfQ2BodyN4Text => get('sf_q2.body[4].text');
  String get sfQ2FooterN0Label => get('sf_q2.footer[0].label');
  String get sfQ2HeaderTitle => get('sf_q2.header.title');
  String get sfQ2HeaderPill => get('sf_q2.header.pill');
  String get sfGoalBodyN0Text => get('sf_goal.body[0].text');
  String get sfGoalBodyN1Text => get('sf_goal.body[1].text');
  String get sfGoalBodyN2ChildrenN0Label => get('sf_goal.body[2].children[0].label');
  String get sfGoalBodyN2ChildrenN0MinLabel => get('sf_goal.body[2].children[0].minLabel');
  String get sfGoalBodyN2ChildrenN0MaxLabel => get('sf_goal.body[2].children[0].maxLabel');
  String get sfGoalBodyN2ChildrenN1Label => get('sf_goal.body[2].children[1].label');
  String get sfGoalBodyN3Eyebrow => get('sf_goal.body[3].eyebrow');
  String get sfGoalBodyN3ChildrenN0ItemsN0Label => get('sf_goal.body[3].children[0].items[0].label');
  String get sfGoalBodyN3ChildrenN0ItemsN0Sub => get('sf_goal.body[3].children[0].items[0].sub');
  String get sfGoalBodyN3ChildrenN0ItemsN1Label => get('sf_goal.body[3].children[0].items[1].label');
  String get sfGoalBodyN3ChildrenN0ItemsN1Sub => get('sf_goal.body[3].children[0].items[1].sub');
  String get sfGoalBodyN3ChildrenN0ItemsN2Label => get('sf_goal.body[3].children[0].items[2].label');
  String get sfGoalBodyN4RowsN0Label => get('sf_goal.body[4].rows[0].label');
  String get sfGoalBodyN4RowsN0Sub => get('sf_goal.body[4].rows[0].sub');
  String get sfGoalFooterN0Label => get('sf_goal.footer[0].label');
  String get sfGoalHeaderTitle => get('sf_goal.header.title');
  String get sfGoalHeaderPill => get('sf_goal.header.pill');
  String get sfScreentimeBodyN1Text => get('sf_screentime.body[1].text');
  String get sfScreentimeBodyN2Text => get('sf_screentime.body[2].text');
  String get sfScreentimeBodyN3RowsN0N0 => get('sf_screentime.body[3].rows[0][0]');
  String get sfScreentimeBodyN3RowsN0N1 => get('sf_screentime.body[3].rows[0][1]');
  String get sfScreentimeBodyN3RowsN1N0 => get('sf_screentime.body[3].rows[1][0]');
  String get sfScreentimeBodyN3RowsN1N1 => get('sf_screentime.body[3].rows[1][1]');
  String get sfScreentimeBodyN3RowsN2N0 => get('sf_screentime.body[3].rows[2][0]');
  String get sfScreentimeBodyN3RowsN2N1 => get('sf_screentime.body[3].rows[2][1]');
  String get sfScreentimeFooterN0ActionCasesN0ActionValue => get('sf_screentime.footer[0].action.cases[0].action.value');
  String get sfScreentimeFooterN0Label => get('sf_screentime.footer[0].label');
  String get sfScreentimeFooterN1Label => get('sf_screentime.footer[1].label');
  String get sfScreentimeHeaderTitle => get('sf_screentime.header.title');
  String get sfScreentimeHeaderPill => get('sf_screentime.header.pill');
  String get sfScreentimeDeniedBodyN0Text => get('sf_screentime_denied.body[0].text');
  String get sfScreentimeDeniedBodyN1Text => get('sf_screentime_denied.body[1].text');
  String get sfScreentimeDeniedBodyN2Text => get('sf_screentime_denied.body[2].text');
  String get sfScreentimeDeniedFooterN0Label => get('sf_screentime_denied.footer[0].label');
  String get sfScreentimeDeniedFooterN1Label => get('sf_screentime_denied.footer[1].label');
  String get sfScreentimeDeniedHeaderTitle => get('sf_screentime_denied.header.title');
  String get sfScreentimeDeniedHeaderPill => get('sf_screentime_denied.header.pill');
  String get sfBuddyBodyN0Text => get('sf_buddy.body[0].text');
  String get sfBuddyBodyN1Text => get('sf_buddy.body[1].text');
  String get sfBuddyBodyN2Label => get('sf_buddy.body[2].label');
  String get sfBuddyBodyN2Placeholder => get('sf_buddy.body[2].placeholder');
  String get sfBuddyBodyN3ItemsN0Label => get('sf_buddy.body[3].items[0].label');
  String get sfBuddyBodyN3ItemsN1Label => get('sf_buddy.body[3].items[1].label');
  String get sfBuddyBodyN3ItemsN2Label => get('sf_buddy.body[3].items[2].label');
  String get sfBuddyBodyN3Label => get('sf_buddy.body[3].label');
  String get sfBuddyBodyN4Eyebrow => get('sf_buddy.body[4].eyebrow');
  String get sfBuddyBodyN4ChildrenN0Text => get('sf_buddy.body[4].children[0].text');
  String get sfBuddyFooterN0Label => get('sf_buddy.footer[0].label');
  String get sfBuddyFooterN1Label => get('sf_buddy.footer[1].label');
  String get sfBuddyHeaderTitle => get('sf_buddy.header.title');
  String get sfBuddyHeaderPill => get('sf_buddy.header.pill');
  String get sfHomeBodyN0Eyebrow => get('sf_home.body[0].eyebrow');
  String get sfHomeBodyN0ChildrenN0Value => get('sf_home.body[0].children[0].value');
  String get sfHomeBodyN0ChildrenN0Caption => get('sf_home.body[0].children[0].caption');
  String get sfHomeBodyN1Title => get('sf_home.body[1].title');
  String get sfHomeBodyN1Text => get('sf_home.body[1].text');
  String get sfHomeBodyN1CtaN0Label => get('sf_home.body[1].cta[0].label');
  String get sfHomeBodyN2Title => get('sf_home.body[2].title');
  String get sfHomeBodyN2Text => get('sf_home.body[2].text');
  String get sfHomeBodyN2CtaN0Label => get('sf_home.body[2].cta[0].label');
  String get sfHomeBodyN3Eyebrow => get('sf_home.body[3].eyebrow');
  String get sfHomeBodyN3ChildrenN0ItemsN0Label => get('sf_home.body[3].children[0].items[0].label');
  String get sfHomeBodyN3ChildrenN0ItemsN0Sub => get('sf_home.body[3].children[0].items[0].sub');
  String get sfHomeBodyN4RowsN0Label => get('sf_home.body[4].rows[0].label');
  String get sfHomeBodyN4RowsN0Sub => get('sf_home.body[4].rows[0].sub');
  String get sfHomeBodyN4RowsN1Label => get('sf_home.body[4].rows[1].label');
  String get sfHomeBodyN4RowsN1Sub => get('sf_home.body[4].rows[1].sub');
  String get sfHomeBodyN4RowsN2Label => get('sf_home.body[4].rows[2].label');
  String get sfHomeBodyN4RowsN2Sub => get('sf_home.body[4].rows[2].sub');
  String get sfHomeBodyN4RowsN3Label => get('sf_home.body[4].rows[3].label');
  String get sfHomeBodyN4RowsN3Sub => get('sf_home.body[4].rows[3].sub');
  String get sfHomeBodyN4RowsN4Label => get('sf_home.body[4].rows[4].label');
  String get sfHomeBodyN4RowsN4Sub => get('sf_home.body[4].rows[4].sub');
  String get sfPauseBodyN0Text => get('sf_pause.body[0].text');
  String get sfPauseBodyN1Text => get('sf_pause.body[1].text');
  String get sfPauseBodyN3OptionsN0 => get('sf_pause.body[3].options[0]');
  String get sfPauseBodyN3OptionsN1 => get('sf_pause.body[3].options[1]');
  String get sfPauseBodyN3OptionsN2 => get('sf_pause.body[3].options[2]');
  String get sfPauseBodyN3OptionsN3 => get('sf_pause.body[3].options[3]');
  String get sfPauseBodyN4Title => get('sf_pause.body[4].title');
  String get sfPauseBodyN4Text => get('sf_pause.body[4].text');
  String get sfPauseFooterN0ActionThenValue => get('sf_pause.footer[0].action.then.value');
  String get sfPauseFooterN0Label => get('sf_pause.footer[0].label');
  String get sfPauseFooterN1Label => get('sf_pause.footer[1].label');
  String get sfPauseFooterN1ActionValue => get('sf_pause.footer[1].action.value');
  String get sfPauseHeaderTitle => get('sf_pause.header.title');
  String get sfPauseHeaderPill => get('sf_pause.header.pill');
  String get sfSlipBodyN0Text => get('sf_slip.body[0].text');
  String get sfSlipBodyN1Text => get('sf_slip.body[1].text');
  String get sfSlipBodyN2OptionsN0 => get('sf_slip.body[2].options[0]');
  String get sfSlipBodyN2OptionsN1 => get('sf_slip.body[2].options[1]');
  String get sfSlipBodyN2OptionsN2 => get('sf_slip.body[2].options[2]');
  String get sfSlipBodyN2OptionsN3 => get('sf_slip.body[2].options[3]');
  String get sfSlipBodyN3ItemsN0Label => get('sf_slip.body[3].items[0].label');
  String get sfSlipBodyN3ItemsN0Badge => get('sf_slip.body[3].items[0].badge');
  String get sfSlipBodyN3ItemsN1Label => get('sf_slip.body[3].items[1].label');
  String get sfSlipBodyN3ItemsN2Label => get('sf_slip.body[3].items[2].label');
  String get sfSlipFooterN0ActionThenValue => get('sf_slip.footer[0].action.then.value');
  String get sfSlipFooterN0Label => get('sf_slip.footer[0].label');
  String get sfSlipHeaderTitle => get('sf_slip.header.title');
  String get sfSlipHeaderPill => get('sf_slip.header.pill');
  String get sfWeekBodyN0Text => get('sf_week.body[0].text');
  String get sfWeekBodyN1Title => get('sf_week.body[1].title');
  String get sfWeekBodyN1Caption => get('sf_week.body[1].caption');
  String get sfWeekBodyN1LabelsN0 => get('sf_week.body[1].labels[0]');
  String get sfWeekBodyN1LabelsN1 => get('sf_week.body[1].labels[1]');
  String get sfWeekBodyN1LabelsN2 => get('sf_week.body[1].labels[2]');
  String get sfWeekBodyN1LabelsN3 => get('sf_week.body[1].labels[3]');
  String get sfWeekBodyN1LabelsN4 => get('sf_week.body[1].labels[4]');
  String get sfWeekBodyN1LabelsN5 => get('sf_week.body[1].labels[5]');
  String get sfWeekBodyN1LabelsN6 => get('sf_week.body[1].labels[6]');
  String get sfWeekBodyN2ItemsN0Label => get('sf_week.body[2].items[0].label');
  String get sfWeekBodyN2ItemsN1Label => get('sf_week.body[2].items[1].label');
  String get sfWeekBodyN2ItemsN1Sub => get('sf_week.body[2].items[1].sub');
  String get sfWeekBodyN3Eyebrow => get('sf_week.body[3].eyebrow');
  String get sfWeekBodyN3Text => get('sf_week.body[3].text');
  String get sfWeekBodyN3ChildrenN0Text => get('sf_week.body[3].children[0].text');
  String get sfWeekBodyN4Eyebrow => get('sf_week.body[4].eyebrow');
  String get sfWeekBodyN4Title => get('sf_week.body[4].title');
  String get sfWeekBodyN4ChildrenN0ItemsN0ActionValue => get('sf_week.body[4].children[0].items[0].action.value');
  String get sfWeekBodyN4ChildrenN0ItemsN0Label => get('sf_week.body[4].children[0].items[0].label');
  String get sfWeekBodyN4ChildrenN0ItemsN1Label => get('sf_week.body[4].children[0].items[1].label');
  String get sfWeekHeaderTitle => get('sf_week.header.title');
  String get caIntroBodyN0Extra => get('ca_intro.body[0].extra');
  String get caIntroBodyN1Text => get('ca_intro.body[1].text');
  String get caIntroBodyN2RowsN0N0 => get('ca_intro.body[2].rows[0][0]');
  String get caIntroBodyN2RowsN0N1 => get('ca_intro.body[2].rows[0][1]');
  String get caIntroBodyN2RowsN1N0 => get('ca_intro.body[2].rows[1][0]');
  String get caIntroBodyN2RowsN1N1 => get('ca_intro.body[2].rows[1][1]');
  String get caIntroBodyN2RowsN2N0 => get('ca_intro.body[2].rows[2][0]');
  String get caIntroBodyN2RowsN2N1 => get('ca_intro.body[2].rows[2][1]');
  String get caIntroBodyN3Text => get('ca_intro.body[3].text');
  String get caIntroFooterN0Label => get('ca_intro.footer[0].label');
  String get caIntroFooterN1ActionThenValue => get('ca_intro.footer[1].action.then.value');
  String get caIntroFooterN1Label => get('ca_intro.footer[1].label');
  String get caIntroHeaderPill => get('ca_intro.header.pill');
  String get caQ1BodyN1Text => get('ca_q1.body[1].text');
  String get caQ1BodyN2Text => get('ca_q1.body[2].text');
  String get caQ1BodyN3ItemsN0Label => get('ca_q1.body[3].items[0].label');
  String get caQ1BodyN3ItemsN1Label => get('ca_q1.body[3].items[1].label');
  String get caQ1BodyN3ItemsN2Label => get('ca_q1.body[3].items[2].label');
  String get caQ1BodyN3ItemsN3Label => get('ca_q1.body[3].items[3].label');
  String get caQ1BodyN4OptionsN0 => get('ca_q1.body[4].options[0]');
  String get caQ1BodyN4OptionsN1 => get('ca_q1.body[4].options[1]');
  String get caQ1BodyN4OptionsN2 => get('ca_q1.body[4].options[2]');
  String get caQ1BodyN4Label => get('ca_q1.body[4].label');
  String get caQ1FooterN0Label => get('ca_q1.footer[0].label');
  String get caQ1HeaderTitle => get('ca_q1.header.title');
  String get caQ1HeaderPill => get('ca_q1.header.pill');
  String get caPlanBodyN1Text => get('ca_plan.body[1].text');
  String get caPlanBodyN2Text => get('ca_plan.body[2].text');
  String get caPlanBodyN3Eyebrow => get('ca_plan.body[3].eyebrow');
  String get caPlanBodyN3ChildrenN0Label => get('ca_plan.body[3].children[0].label');
  String get caPlanBodyN3ChildrenN1Label => get('ca_plan.body[3].children[1].label');
  String get caPlanBodyN3ChildrenN1Placeholder => get('ca_plan.body[3].children[1].placeholder');
  String get caPlanBodyN4Eyebrow => get('ca_plan.body[4].eyebrow');
  String get caPlanBodyN4ChildrenN0Label => get('ca_plan.body[4].children[0].label');
  String get caPlanBodyN5Eyebrow => get('ca_plan.body[5].eyebrow');
  String get caPlanBodyN5ChildrenN0Label => get('ca_plan.body[5].children[0].label');
  String get caPlanBodyN6ActionValue => get('ca_plan.body[6].action.value');
  String get caPlanBodyN6Label => get('ca_plan.body[6].label');
  String get caPlanFooterN0Label => get('ca_plan.footer[0].label');
  String get caPlanHeaderTitle => get('ca_plan.header.title');
  String get caPlanHeaderPill => get('ca_plan.header.pill');
  String get caNoplanBodyN1Text => get('ca_noplan.body[1].text');
  String get caNoplanBodyN2Text => get('ca_noplan.body[2].text');
  String get caNoplanBodyN3RowsN0Label => get('ca_noplan.body[3].rows[0].label');
  String get caNoplanBodyN3RowsN0Sub => get('ca_noplan.body[3].rows[0].sub');
  String get caNoplanBodyN3RowsN1Label => get('ca_noplan.body[3].rows[1].label');
  String get caNoplanBodyN3RowsN2Label => get('ca_noplan.body[3].rows[2].label');
  String get caNoplanFooterN0Label => get('ca_noplan.footer[0].label');
  String get caNoplanHeaderTitle => get('ca_noplan.header.title');
  String get caNoplanHeaderPill => get('ca_noplan.header.pill');
  String get caHomeBodyN0Eyebrow => get('ca_home.body[0].eyebrow');
  String get caHomeBodyN0Title => get('ca_home.body[0].title');
  String get caHomeBodyN0Text => get('ca_home.body[0].text');
  String get caHomeBodyN1Label => get('ca_home.body[1].label');
  String get caHomeBodyN2Title => get('ca_home.body[2].title');
  String get caHomeBodyN2Text => get('ca_home.body[2].text');
  String get caHomeBodyN3RowsN0Label => get('ca_home.body[3].rows[0].label');
  String get caHomeBodyN3RowsN1Label => get('ca_home.body[3].rows[1].label');
  String get caHomeBodyN3RowsN1Sub => get('ca_home.body[3].rows[1].sub');
  String get caHomeBodyN3RowsN2Label => get('ca_home.body[3].rows[2].label');
  String get caHomeBodyN3RowsN2Sub => get('ca_home.body[3].rows[2].sub');
  String get caHomeBodyN3RowsN3Label => get('ca_home.body[3].rows[3].label');
  String get caHomeBodyN3RowsN3Sub => get('ca_home.body[3].rows[3].sub');
  String get caZoneBodyN0Text => get('ca_zone.body[0].text');
  String get caZoneBodyN1Label => get('ca_zone.body[1].label');
  String get caZoneBodyN1Hint => get('ca_zone.body[1].hint');
  String get caZoneBodyN2OptionsN0 => get('ca_zone.body[2].options[0]');
  String get caZoneBodyN2OptionsN1 => get('ca_zone.body[2].options[1]');
  String get caZoneBodyN2OptionsN2 => get('ca_zone.body[2].options[2]');
  String get caZoneBodyN2OptionsN3 => get('ca_zone.body[2].options[3]');
  String get caZoneBodyN2OptionsN4 => get('ca_zone.body[2].options[4]');
  String get caZoneBodyN2OptionsN5 => get('ca_zone.body[2].options[5]');
  String get caZoneBodyN2Label => get('ca_zone.body[2].label');
  String get caZoneBodyN3Text => get('ca_zone.body[3].text');
  String get caZoneBodyN5Text => get('ca_zone.body[5].text');
  String get caZoneFooterN0ActionThenCasesN0ActionValue => get('ca_zone.footer[0].action.then.cases[0].action.value');
  String get caZoneFooterN0ActionThenCasesN3ActionValue => get('ca_zone.footer[0].action.then.cases[3].action.value');
  String get caZoneFooterN0Label => get('ca_zone.footer[0].label');
  String get caZoneHeaderTitle => get('ca_zone.header.title');
  String get caZoneHeaderPill => get('ca_zone.header.pill');
  String get caYellowBodyN0Title => get('ca_yellow.body[0].title');
  String get caYellowBodyN0Text => get('ca_yellow.body[0].text');
  String get caYellowBodyN1ChildrenN0ItemsN0Label => get('ca_yellow.body[1].children[0].items[0].label');
  String get caYellowBodyN1ChildrenN0ItemsN0Sub => get('ca_yellow.body[1].children[0].items[0].sub');
  String get caYellowBodyN1ChildrenN0ItemsN1Label => get('ca_yellow.body[1].children[0].items[1].label');
  String get caYellowBodyN1ChildrenN0ItemsN1Sub => get('ca_yellow.body[1].children[0].items[1].sub');
  String get caYellowBodyN1ChildrenN0ItemsN2Label => get('ca_yellow.body[1].children[0].items[2].label');
  String get caYellowBodyN1ChildrenN0ItemsN2Sub => get('ca_yellow.body[1].children[0].items[2].sub');
  String get caYellowBodyN2Title => get('ca_yellow.body[2].title');
  String get caYellowBodyN2Text => get('ca_yellow.body[2].text');
  String get caYellowFooterN0ActionValue => get('ca_yellow.footer[0].action.value');
  String get caYellowFooterN0Label => get('ca_yellow.footer[0].label');
  String get caYellowFooterN1Label => get('ca_yellow.footer[1].label');
  String get caYellowHeaderTitle => get('ca_yellow.header.title');
  String get caYellowHeaderPill => get('ca_yellow.header.pill');
  String get caRedBodyN0Text => get('ca_red.body[0].text');
  String get caRedBodyN1Label => get('ca_red.body[1].label');
  String get caRedBodyN2Eyebrow => get('ca_red.body[2].eyebrow');
  String get caRedBodyN2ChildrenN0ItemsN0Label => get('ca_red.body[2].children[0].items[0].label');
  String get caRedBodyN2ChildrenN0ItemsN1Label => get('ca_red.body[2].children[0].items[1].label');
  String get caRedBodyN2ChildrenN0ItemsN2Label => get('ca_red.body[2].children[0].items[2].label');
  String get caRedBodyN3RowsN0Label => get('ca_red.body[3].rows[0].label');
  String get caRedBodyN3RowsN0Sub => get('ca_red.body[3].rows[0].sub');
  String get caRedBodyN4Text => get('ca_red.body[4].text');
  String get caRedHeaderTitle => get('ca_red.header.title');
  String get caSymptomsBodyN0Text => get('ca_symptoms.body[0].text');
  String get caSymptomsBodyN1OptionsN0 => get('ca_symptoms.body[1].options[0]');
  String get caSymptomsBodyN1OptionsN1 => get('ca_symptoms.body[1].options[1]');
  String get caSymptomsBodyN1OptionsN2 => get('ca_symptoms.body[1].options[2]');
  String get caSymptomsBodyN1OptionsN3 => get('ca_symptoms.body[1].options[3]');
  String get caSymptomsBodyN1OptionsN4 => get('ca_symptoms.body[1].options[4]');
  String get caSymptomsBodyN2OptionsN0 => get('ca_symptoms.body[2].options[0]');
  String get caSymptomsBodyN2OptionsN1 => get('ca_symptoms.body[2].options[1]');
  String get caSymptomsBodyN2OptionsN2 => get('ca_symptoms.body[2].options[2]');
  String get caSymptomsBodyN2Label => get('ca_symptoms.body[2].label');
  String get caSymptomsBodyN3OptionsN0 => get('ca_symptoms.body[3].options[0]');
  String get caSymptomsBodyN3OptionsN1 => get('ca_symptoms.body[3].options[1]');
  String get caSymptomsBodyN3OptionsN2 => get('ca_symptoms.body[3].options[2]');
  String get caSymptomsBodyN3OptionsN3 => get('ca_symptoms.body[3].options[3]');
  String get caSymptomsBodyN3OptionsN4 => get('ca_symptoms.body[3].options[4]');
  String get caSymptomsBodyN3Label => get('ca_symptoms.body[3].label');
  String get caSymptomsBodyN4Label => get('ca_symptoms.body[4].label');
  String get caSymptomsBodyN4Placeholder => get('ca_symptoms.body[4].placeholder');
  String get caSymptomsFooterN0ActionThenValue => get('ca_symptoms.footer[0].action.then.value');
  String get caSymptomsFooterN0Label => get('ca_symptoms.footer[0].label');
  String get caSymptomsHeaderTitle => get('ca_symptoms.header.title');
  String get caProgressBodyN0Title => get('ca_progress.body[0].title');
  String get caProgressBodyN0Caption => get('ca_progress.body[0].caption');
  String get caProgressBodyN1ItemsN0Label => get('ca_progress.body[1].items[0].label');
  String get caProgressBodyN1ItemsN1Label => get('ca_progress.body[1].items[1].label');
  String get caProgressBodyN1ItemsN2Label => get('ca_progress.body[1].items[2].label');
  String get caProgressBodyN2Eyebrow => get('ca_progress.body[2].eyebrow');
  String get caProgressBodyN2Title => get('ca_progress.body[2].title');
  String get caProgressBodyN2Text => get('ca_progress.body[2].text');
  String get caProgressFooterN0Label => get('ca_progress.footer[0].label');
  String get caProgressHeaderTitle => get('ca_progress.header.title');
  String get hwIntroBodyN0Extra => get('hw_intro.body[0].extra');
  String get hwIntroBodyN1Text => get('hw_intro.body[1].text');
  String get hwIntroBodyN2RowsN0N0 => get('hw_intro.body[2].rows[0][0]');
  String get hwIntroBodyN2RowsN0N1 => get('hw_intro.body[2].rows[0][1]');
  String get hwIntroBodyN2RowsN1N0 => get('hw_intro.body[2].rows[1][0]');
  String get hwIntroBodyN2RowsN1N1 => get('hw_intro.body[2].rows[1][1]');
  String get hwIntroBodyN2RowsN2N0 => get('hw_intro.body[2].rows[2][0]');
  String get hwIntroBodyN2RowsN2N1 => get('hw_intro.body[2].rows[2][1]');
  String get hwIntroBodyN3Text => get('hw_intro.body[3].text');
  String get hwIntroFooterN0Label => get('hw_intro.footer[0].label');
  String get hwIntroFooterN1ActionThenValue => get('hw_intro.footer[1].action.then.value');
  String get hwIntroFooterN1Label => get('hw_intro.footer[1].label');
  String get hwIntroHeaderPill => get('hw_intro.header.pill');
  String get hwQ1BodyN1Text => get('hw_q1.body[1].text');
  String get hwQ1BodyN2OptionsN0 => get('hw_q1.body[2].options[0]');
  String get hwQ1BodyN2OptionsN1 => get('hw_q1.body[2].options[1]');
  String get hwQ1BodyN2OptionsN2 => get('hw_q1.body[2].options[2]');
  String get hwQ1BodyN2OptionsN3 => get('hw_q1.body[2].options[3]');
  String get hwQ1BodyN2OptionsN4 => get('hw_q1.body[2].options[4]');
  String get hwQ1BodyN3OptionsN0 => get('hw_q1.body[3].options[0]');
  String get hwQ1BodyN3OptionsN1 => get('hw_q1.body[3].options[1]');
  String get hwQ1BodyN3OptionsN2 => get('hw_q1.body[3].options[2]');
  String get hwQ1BodyN3Label => get('hw_q1.body[3].label');
  String get hwQ1BodyN4Text => get('hw_q1.body[4].text');
  String get hwQ1FooterN0Label => get('hw_q1.footer[0].label');
  String get hwQ1HeaderTitle => get('hw_q1.header.title');
  String get hwQ1HeaderPill => get('hw_q1.header.pill');
  String get hwTargetsBodyN1Text => get('hw_targets.body[1].text');
  String get hwTargetsBodyN2FieldsN0Label => get('hw_targets.body[2].fields[0].label');
  String get hwTargetsBodyN2FieldsN1Label => get('hw_targets.body[2].fields[1].label');
  String get hwTargetsBodyN3ItemsN0Label => get('hw_targets.body[3].items[0].label');
  String get hwTargetsBodyN3ItemsN0Sub => get('hw_targets.body[3].items[0].sub');
  String get hwTargetsBodyN4OptionsN0 => get('hw_targets.body[4].options[0]');
  String get hwTargetsBodyN4OptionsN1 => get('hw_targets.body[4].options[1]');
  String get hwTargetsBodyN4OptionsN2 => get('hw_targets.body[4].options[2]');
  String get hwTargetsBodyN4Label => get('hw_targets.body[4].label');
  String get hwTargetsBodyN5Text => get('hw_targets.body[5].text');
  String get hwTargetsBodyN6Label => get('hw_targets.body[6].label');
  String get hwTargetsFooterN0Label => get('hw_targets.footer[0].label');
  String get hwTargetsHeaderTitle => get('hw_targets.header.title');
  String get hwTargetsHeaderPill => get('hw_targets.header.pill');
  String get hwHomeBodyN0Eyebrow => get('hw_home.body[0].eyebrow');
  String get hwHomeBodyN0ChildrenN0Caption => get('hw_home.body[0].children[0].caption');
  String get hwHomeBodyN1Label => get('hw_home.body[1].label');
  String get hwHomeBodyN2RowsN0Label => get('hw_home.body[2].rows[0].label');
  String get hwHomeBodyN2RowsN0Sub => get('hw_home.body[2].rows[0].sub');
  String get hwHomeBodyN2RowsN1Label => get('hw_home.body[2].rows[1].label');
  String get hwHomeBodyN2RowsN1Sub => get('hw_home.body[2].rows[1].sub');
  String get hwHomeBodyN2RowsN2Label => get('hw_home.body[2].rows[2].label');
  String get hwHomeBodyN2RowsN2Sub => get('hw_home.body[2].rows[2].sub');
  String get hwHomeBodyN2RowsN3Label => get('hw_home.body[2].rows[3].label');
  String get hwHomeBodyN2RowsN3Sub => get('hw_home.body[2].rows[3].sub');
  String get hwHomeBodyN2RowsN4Label => get('hw_home.body[2].rows[4].label');
  String get hwHomeBodyN2RowsN4Sub => get('hw_home.body[2].rows[4].sub');
  String get hwHomeBodyN2RowsN5Label => get('hw_home.body[2].rows[5].label');
  String get hwHomeBodyN2RowsN5Sub => get('hw_home.body[2].rows[5].sub');
  String get hwHomeBodyN3Text => get('hw_home.body[3].text');
  String get hwHomeBodyN3ActionsN0Label => get('hw_home.body[3].actions[0].label');
  String get hwLogBodyN0Text => get('hw_log.body[0].text');
  String get hwLogBodyN1FieldsN0Label => get('hw_log.body[1].fields[0].label');
  String get hwLogBodyN1FieldsN1Label => get('hw_log.body[1].fields[1].label');
  String get hwLogBodyN2Label => get('hw_log.body[2].label');
  String get hwLogBodyN3OptionsN0 => get('hw_log.body[3].options[0]');
  String get hwLogBodyN3OptionsN1 => get('hw_log.body[3].options[1]');
  String get hwLogBodyN4Title => get('hw_log.body[4].title');
  String get hwLogBodyN4Text => get('hw_log.body[4].text');
  String get hwLogFooterN0Label => get('hw_log.footer[0].label');
  String get hwLogHeaderTitle => get('hw_log.header.title');
  String get hwLogHeaderPill => get('hw_log.header.pill');
  String get hwLog2BodyN0Text => get('hw_log2.body[0].text');
  String get hwLog2BodyN1Text => get('hw_log2.body[1].text');
  String get hwLog2BodyN2FieldsN0Label => get('hw_log2.body[2].fields[0].label');
  String get hwLog2BodyN2FieldsN1Label => get('hw_log2.body[2].fields[1].label');
  String get hwLog2BodyN3Label => get('hw_log2.body[3].label');
  String get hwLog2BodyN4RowsN0N0 => get('hw_log2.body[4].rows[0][0]');
  String get hwLog2BodyN4RowsN1N0 => get('hw_log2.body[4].rows[1][0]');
  String get hwLog2FooterN0Label => get('hw_log2.footer[0].label');
  String get hwLog2HeaderTitle => get('hw_log2.header.title');
  String get hwLog2HeaderPill => get('hw_log2.header.pill');
  String get hwLogErrorBodyN0Text => get('hw_log_error.body[0].text');
  String get hwLogErrorBodyN1FieldsN0Label => get('hw_log_error.body[1].fields[0].label');
  String get hwLogErrorBodyN1FieldsN1Label => get('hw_log_error.body[1].fields[1].label');
  String get hwLogErrorBodyN1FieldsN1Error => get('hw_log_error.body[1].fields[1].error');
  String get hwLogErrorBodyN2Text => get('hw_log_error.body[2].text');
  String get hwLogErrorFooterN0Label => get('hw_log_error.footer[0].label');
  String get hwLogErrorFooterN1Label => get('hw_log_error.footer[1].label');
  String get hwLogErrorHeaderTitle => get('hw_log_error.header.title');
  String get hwLogErrorHeaderPill => get('hw_log_error.header.pill');
  String get hwResultBodyN1Text => get('hw_result.body[1].text');
  String get hwResultBodyN2Text => get('hw_result.body[2].text');
  String get hwResultBodyN3Text => get('hw_result.body[3].text');
  String get hwResultFooterN0Label => get('hw_result.footer[0].label');
  String get hwResultFooterN1Label => get('hw_result.footer[1].label');
  String get hwResultHeaderTitle => get('hw_result.header.title');
  String get hwCrisisBodyN0Text => get('hw_crisis.body[0].text');
  String get hwCrisisBodyN1Title => get('hw_crisis.body[1].title');
  String get hwCrisisBodyN1Text => get('hw_crisis.body[1].text');
  String get hwCrisisBodyN2Label => get('hw_crisis.body[2].label');
  String get hwCrisisBodyN3Label => get('hw_crisis.body[3].label');
  String get hwCrisisBodyN4Text => get('hw_crisis.body[4].text');
  String get hwCrisisHeaderTitle => get('hw_crisis.header.title');
  String get hwRecheckBodyN0Text => get('hw_recheck.body[0].text');
  String get hwRecheckBodyN1Label => get('hw_recheck.body[1].label');
  String get hwRecheckBodyN2ChildrenN0ItemsN0Label => get('hw_recheck.body[2].children[0].items[0].label');
  String get hwRecheckBodyN2ChildrenN0ItemsN1Label => get('hw_recheck.body[2].children[0].items[1].label');
  String get hwRecheckBodyN2ChildrenN0ItemsN2Label => get('hw_recheck.body[2].children[0].items[2].label');
  String get hwRecheckBodyN3Text => get('hw_recheck.body[3].text');
  String get hwRecheckBodyN3ActionsN0Label => get('hw_recheck.body[3].actions[0].label');
  String get hwRecheckFooterN0Label => get('hw_recheck.footer[0].label');
  String get hwRecheckFooterN1Label => get('hw_recheck.footer[1].label');
  String get hwRecheckHeaderTitle => get('hw_recheck.header.title');
  String get hwTrendsBodyN0OptionsN0 => get('hw_trends.body[0].options[0]');
  String get hwTrendsBodyN0OptionsN1 => get('hw_trends.body[0].options[1]');
  String get hwTrendsBodyN0OptionsN2 => get('hw_trends.body[0].options[2]');
  String get hwTrendsBodyN1Title => get('hw_trends.body[1].title');
  String get hwTrendsBodyN1Caption => get('hw_trends.body[1].caption');
  String get hwTrendsBodyN2ItemsN0Label => get('hw_trends.body[2].items[0].label');
  String get hwTrendsBodyN2ItemsN1Label => get('hw_trends.body[2].items[1].label');
  String get hwTrendsBodyN2ItemsN1Sub => get('hw_trends.body[2].items[1].sub');
  String get hwTrendsFooterN0Label => get('hw_trends.footer[0].label');
  String get hwTrendsHeaderTitle => get('hw_trends.header.title');
  String get hwLipidsBodyN0Text => get('hw_lipids.body[0].text');
  String get hwLipidsBodyN1Text => get('hw_lipids.body[1].text');
  String get hwLipidsBodyN2FieldsN0Label => get('hw_lipids.body[2].fields[0].label');
  String get hwLipidsBodyN2FieldsN1Label => get('hw_lipids.body[2].fields[1].label');
  String get hwLipidsBodyN3FieldsN0Label => get('hw_lipids.body[3].fields[0].label');
  String get hwLipidsBodyN3FieldsN1Label => get('hw_lipids.body[3].fields[1].label');
  String get hwLipidsBodyN3FieldsN1Placeholder => get('hw_lipids.body[3].fields[1].placeholder');
  String get hwLipidsBodyN4Label => get('hw_lipids.body[4].label');
  String get hwLipidsBodyN4Placeholder => get('hw_lipids.body[4].placeholder');
  String get hwLipidsFooterN0ActionThenValue => get('hw_lipids.footer[0].action.then.value');
  String get hwLipidsFooterN0Label => get('hw_lipids.footer[0].label');
  String get hwLipidsHeaderTitle => get('hw_lipids.header.title');
  String get hwLipidsHeaderPill => get('hw_lipids.header.pill');
  String get hwSummaryBodyN0Text => get('hw_summary.body[0].text');
  String get hwSummaryBodyN1RowsN0N0 => get('hw_summary.body[1].rows[0][0]');
  String get hwSummaryBodyN1RowsN0N1 => get('hw_summary.body[1].rows[0][1]');
  String get hwSummaryBodyN1RowsN1N0 => get('hw_summary.body[1].rows[1][0]');
  String get hwSummaryBodyN1RowsN1N1 => get('hw_summary.body[1].rows[1][1]');
  String get hwSummaryBodyN1RowsN2N0 => get('hw_summary.body[1].rows[2][0]');
  String get hwSummaryBodyN1RowsN2N1 => get('hw_summary.body[1].rows[2][1]');
  String get hwSummaryBodyN1RowsN3N0 => get('hw_summary.body[1].rows[3][0]');
  String get hwSummaryBodyN1RowsN3N1 => get('hw_summary.body[1].rows[3][1]');
  String get hwSummaryBodyN2Text => get('hw_summary.body[2].text');
  String get hwSummaryBodyN3Label => get('hw_summary.body[3].label');
  String get hwSummaryFooterN0ActionThenValue => get('hw_summary.footer[0].action.then.value');
  String get hwSummaryFooterN0Label => get('hw_summary.footer[0].label');
  String get hwSummaryFooterN1ActionValue => get('hw_summary.footer[1].action.value');
  String get hwSummaryFooterN1Label => get('hw_summary.footer[1].label');
  String get hwSummaryHeaderTitle => get('hw_summary.header.title');
  String get hwSummaryHeaderPill => get('hw_summary.header.pill');
  String get stIntroBodyN0Extra => get('st_intro.body[0].extra');
  String get stIntroBodyN1Text => get('st_intro.body[1].text');
  String get stIntroBodyN2RowsN0N0 => get('st_intro.body[2].rows[0][0]');
  String get stIntroBodyN2RowsN0N1 => get('st_intro.body[2].rows[0][1]');
  String get stIntroBodyN2RowsN1N0 => get('st_intro.body[2].rows[1][0]');
  String get stIntroBodyN2RowsN1N1 => get('st_intro.body[2].rows[1][1]');
  String get stIntroBodyN2RowsN2N0 => get('st_intro.body[2].rows[2][0]');
  String get stIntroBodyN2RowsN2N1 => get('st_intro.body[2].rows[2][1]');
  String get stIntroBodyN3Text => get('st_intro.body[3].text');
  String get stIntroFooterN0Label => get('st_intro.footer[0].label');
  String get stIntroFooterN1ActionThenValue => get('st_intro.footer[1].action.then.value');
  String get stIntroFooterN1Label => get('st_intro.footer[1].label');
  String get stIntroHeaderPill => get('st_intro.header.pill');
  String get stQ1BodyN1Text => get('st_q1.body[1].text');
  String get stQ1BodyN2Text => get('st_q1.body[2].text');
  String get stQ1BodyN3ItemsN0Label => get('st_q1.body[3].items[0].label');
  String get stQ1BodyN3ItemsN1Label => get('st_q1.body[3].items[1].label');
  String get stQ1BodyN3ItemsN2Label => get('st_q1.body[3].items[2].label');
  String get stQ1BodyN3ItemsN2Sub => get('st_q1.body[3].items[2].sub');
  String get stQ1BodyN3ItemsN3Label => get('st_q1.body[3].items[3].label');
  String get stQ1BodyN3ItemsN3Sub => get('st_q1.body[3].items[3].sub');
  String get stQ1BodyN3ItemsN4Label => get('st_q1.body[3].items[4].label');
  String get stQ1BodyN4OptionsN0 => get('st_q1.body[4].options[0]');
  String get stQ1BodyN4OptionsN1 => get('st_q1.body[4].options[1]');
  String get stQ1BodyN4OptionsN2 => get('st_q1.body[4].options[2]');
  String get stQ1BodyN4Label => get('st_q1.body[4].label');
  String get stQ1FooterN0Label => get('st_q1.footer[0].label');
  String get stQ1HeaderTitle => get('st_q1.header.title');
  String get stQ1HeaderPill => get('st_q1.header.pill');
  String get stRangeBodyN1Text => get('st_range.body[1].text');
  String get stRangeBodyN2OptionsN0 => get('st_range.body[2].options[0]');
  String get stRangeBodyN2OptionsN1 => get('st_range.body[2].options[1]');
  String get stRangeBodyN3FieldsN0Label => get('st_range.body[3].fields[0].label');
  String get stRangeBodyN3FieldsN1Label => get('st_range.body[3].fields[1].label');
  String get stRangeBodyN4Label => get('st_range.body[4].label');
  String get stRangeBodyN5Eyebrow => get('st_range.body[5].eyebrow');
  String get stRangeBodyN5ChildrenN0Label => get('st_range.body[5].children[0].label');
  String get stRangeBodyN5ChildrenN1Label => get('st_range.body[5].children[1].label');
  String get stRangeBodyN5ChildrenN1Placeholder => get('st_range.body[5].children[1].placeholder');
  String get stRangeBodyN6Label => get('st_range.body[6].label');
  String get stRangeFooterN0Label => get('st_range.footer[0].label');
  String get stRangeHeaderTitle => get('st_range.header.title');
  String get stRangeHeaderPill => get('st_range.header.pill');
  String get stHomeBodyN0Eyebrow => get('st_home.body[0].eyebrow');
  String get stHomeBodyN0ChildrenN0Caption => get('st_home.body[0].children[0].caption');
  String get stHomeBodyN1Label => get('st_home.body[1].label');
  String get stHomeBodyN2RowsN0Label => get('st_home.body[2].rows[0].label');
  String get stHomeBodyN2RowsN0Sub => get('st_home.body[2].rows[0].sub');
  String get stHomeBodyN2RowsN1Label => get('st_home.body[2].rows[1].label');
  String get stHomeBodyN2RowsN1Sub => get('st_home.body[2].rows[1].sub');
  String get stHomeBodyN2RowsN2Label => get('st_home.body[2].rows[2].label');
  String get stHomeBodyN2RowsN2Sub => get('st_home.body[2].rows[2].sub');
  String get stHomeBodyN2RowsN3Label => get('st_home.body[2].rows[3].label');
  String get stHomeBodyN2RowsN4Label => get('st_home.body[2].rows[4].label');
  String get stHomeBodyN2RowsN4Sub => get('st_home.body[2].rows[4].sub');
  String get stHomeBodyN3Text => get('st_home.body[3].text');
  String get stLogBodyN0Label => get('st_log.body[0].label');
  String get stLogBodyN0Hint => get('st_log.body[0].hint');
  String get stLogBodyN1OptionsN0 => get('st_log.body[1].options[0]');
  String get stLogBodyN1OptionsN1 => get('st_log.body[1].options[1]');
  String get stLogBodyN1OptionsN2 => get('st_log.body[1].options[2]');
  String get stLogBodyN1OptionsN3 => get('st_log.body[1].options[3]');
  String get stLogBodyN1OptionsN4 => get('st_log.body[1].options[4]');
  String get stLogBodyN1Label => get('st_log.body[1].label');
  String get stLogBodyN2OptionsN0 => get('st_log.body[2].options[0]');
  String get stLogBodyN2OptionsN1 => get('st_log.body[2].options[1]');
  String get stLogBodyN2OptionsN2 => get('st_log.body[2].options[2]');
  String get stLogBodyN2OptionsN3 => get('st_log.body[2].options[3]');
  String get stLogBodyN2OptionsN4 => get('st_log.body[2].options[4]');
  String get stLogBodyN2Label => get('st_log.body[2].label');
  String get stLogBodyN3Label => get('st_log.body[3].label');
  String get stLogBodyN3Hint => get('st_log.body[3].hint');
  String get stLogBodyN3Placeholder => get('st_log.body[3].placeholder');
  String get stLogFooterN0ActionThenCasesN0ActionValue => get('st_log.footer[0].action.then.cases[0].action.value');
  String get stLogFooterN0ActionThenCasesN2ActionValue => get('st_log.footer[0].action.then.cases[2].action.value');
  String get stLogFooterN0Label => get('st_log.footer[0].label');
  String get stLogHeaderTitle => get('st_log.header.title');
  String get stLowBodyN0Text => get('st_low.body[0].text');
  String get stLowBodyN1Eyebrow => get('st_low.body[1].eyebrow');
  String get stLowBodyN1ChildrenN0ItemsN0Label => get('st_low.body[1].children[0].items[0].label');
  String get stLowBodyN1ChildrenN0ItemsN0Sub => get('st_low.body[1].children[0].items[0].sub');
  String get stLowBodyN1ChildrenN0ItemsN1Label => get('st_low.body[1].children[0].items[1].label');
  String get stLowBodyN1ChildrenN0ItemsN2Label => get('st_low.body[1].children[0].items[2].label');
  String get stLowBodyN2Label => get('st_low.body[2].label');
  String get stLowBodyN3Title => get('st_low.body[3].title');
  String get stLowBodyN3Text => get('st_low.body[3].text');
  String get stLowBodyN3ChildrenN0Label => get('st_low.body[3].children[0].label');
  String get stLowFooterN0Label => get('st_low.footer[0].label');
  String get stLowHeaderTitle => get('st_low.header.title');
  String get stResetBodyN0Text => get('st_reset.body[0].text');
  String get stResetBodyN1ChildrenN0ItemsN0Label => get('st_reset.body[1].children[0].items[0].label');
  String get stResetBodyN1ChildrenN0ItemsN1Label => get('st_reset.body[1].children[0].items[1].label');
  String get stResetBodyN1ChildrenN0ItemsN2Label => get('st_reset.body[1].children[0].items[2].label');
  String get stResetBodyN1ChildrenN0ItemsN3Label => get('st_reset.body[1].children[0].items[3].label');
  String get stResetBodyN2Text => get('st_reset.body[2].text');
  String get stResetFooterN0ActionValue => get('st_reset.footer[0].action.value');
  String get stResetFooterN0Label => get('st_reset.footer[0].label');
  String get stResetHeaderTitle => get('st_reset.header.title');
  String get stResetHeaderPill => get('st_reset.header.pill');
  String get stPatternsBodyN0OptionsN0 => get('st_patterns.body[0].options[0]');
  String get stPatternsBodyN0OptionsN1 => get('st_patterns.body[0].options[1]');
  String get stPatternsBodyN0OptionsN2 => get('st_patterns.body[0].options[2]');
  String get stPatternsBodyN1Title => get('st_patterns.body[1].title');
  String get stPatternsBodyN2ItemsN0Label => get('st_patterns.body[2].items[0].label');
  String get stPatternsBodyN2ItemsN0Sub => get('st_patterns.body[2].items[0].sub');
  String get stPatternsBodyN2ItemsN1Label => get('st_patterns.body[2].items[1].label');
  String get stPatternsBodyN2ItemsN1Sub => get('st_patterns.body[2].items[1].sub');
  String get stPatternsBodyN3Eyebrow => get('st_patterns.body[3].eyebrow');
  String get stPatternsBodyN3Title => get('st_patterns.body[3].title');
  String get stPatternsHeaderTitle => get('st_patterns.header.title');
  String get stA1cBodyN0Text => get('st_a1c.body[0].text');
  String get stA1cBodyN1Label => get('st_a1c.body[1].label');
  String get stA1cBodyN2Label => get('st_a1c.body[2].label');
  String get stA1cBodyN2Placeholder => get('st_a1c.body[2].placeholder');
  String get stA1cBodyN3RowsN0N0 => get('st_a1c.body[3].rows[0][0]');
  String get stA1cBodyN3RowsN0N1 => get('st_a1c.body[3].rows[0][1]');
  String get stA1cBodyN3RowsN1N0 => get('st_a1c.body[3].rows[1][0]');
  String get stA1cBodyN3RowsN1N1 => get('st_a1c.body[3].rows[1][1]');
  String get stA1cBodyN4Text => get('st_a1c.body[4].text');
  String get stA1cFooterN0ActionThenValue => get('st_a1c.footer[0].action.then.value');
  String get stA1cFooterN0Label => get('st_a1c.footer[0].label');
  String get stA1cHeaderTitle => get('st_a1c.header.title');
  String get stA1cHeaderPill => get('st_a1c.header.pill');
  String get reIntroBodyN0Extra => get('re_intro.body[0].extra');
  String get reIntroBodyN1Text => get('re_intro.body[1].text');
  String get reIntroBodyN2RowsN0N0 => get('re_intro.body[2].rows[0][0]');
  String get reIntroBodyN2RowsN0N1 => get('re_intro.body[2].rows[0][1]');
  String get reIntroBodyN2RowsN1N0 => get('re_intro.body[2].rows[1][0]');
  String get reIntroBodyN2RowsN1N1 => get('re_intro.body[2].rows[1][1]');
  String get reIntroBodyN2RowsN2N0 => get('re_intro.body[2].rows[2][0]');
  String get reIntroBodyN2RowsN2N1 => get('re_intro.body[2].rows[2][1]');
  String get reIntroFooterN0Label => get('re_intro.footer[0].label');
  String get reIntroFooterN1ActionThenValue => get('re_intro.footer[1].action.then.value');
  String get reIntroFooterN1Label => get('re_intro.footer[1].label');
  String get reIntroHeaderPill => get('re_intro.header.pill');
  String get reQ1BodyN1Text => get('re_q1.body[1].text');
  String get reQ1BodyN2Text => get('re_q1.body[2].text');
  String get reQ1BodyN3OptionsN0 => get('re_q1.body[3].options[0]');
  String get reQ1BodyN3OptionsN1 => get('re_q1.body[3].options[1]');
  String get reQ1BodyN3OptionsN2 => get('re_q1.body[3].options[2]');
  String get reQ1BodyN3OptionsN3 => get('re_q1.body[3].options[3]');
  String get reQ1BodyN3OptionsN4 => get('re_q1.body[3].options[4]');
  String get reQ1BodyN3OptionsN5 => get('re_q1.body[3].options[5]');
  String get reQ1BodyN3OptionsN6 => get('re_q1.body[3].options[6]');
  String get reQ1BodyN4OptionsN0 => get('re_q1.body[4].options[0]');
  String get reQ1BodyN4OptionsN1 => get('re_q1.body[4].options[1]');
  String get reQ1BodyN4OptionsN2 => get('re_q1.body[4].options[2]');
  String get reQ1BodyN4OptionsN3 => get('re_q1.body[4].options[3]');
  String get reQ1BodyN4Label => get('re_q1.body[4].label');
  String get reQ1FooterN0Label => get('re_q1.footer[0].label');
  String get reQ1HeaderTitle => get('re_q1.header.title');
  String get reQ1HeaderPill => get('re_q1.header.pill');
  String get reResultBodyN0Text => get('re_result.body[0].text');
  String get reResultBodyN1Text => get('re_result.body[1].text');
  String get reResultBodyN2ChildrenN0ItemsN0Label => get('re_result.body[2].children[0].items[0].label');
  String get reResultBodyN2ChildrenN0ItemsN1Label => get('re_result.body[2].children[0].items[1].label');
  String get reResultBodyN3Title => get('re_result.body[3].title');
  String get reResultBodyN3Text => get('re_result.body[3].text');
  String get reResultFooterN0Label => get('re_result.footer[0].label');
  String get reResultHeaderTitle => get('re_result.header.title');
  String get reResultHeaderPill => get('re_result.header.pill');
  String get reHomeBodyN0Eyebrow => get('re_home.body[0].eyebrow');
  String get reHomeBodyN0ChildrenN0Caption => get('re_home.body[0].children[0].caption');
  String get reHomeBodyN1Eyebrow => get('re_home.body[1].eyebrow');
  String get reHomeBodyN1ChildrenN0ItemsN0Label => get('re_home.body[1].children[0].items[0].label');
  String get reHomeBodyN1ChildrenN0ItemsN0Sub => get('re_home.body[1].children[0].items[0].sub');
  String get reHomeBodyN1ChildrenN0ItemsN1Label => get('re_home.body[1].children[0].items[1].label');
  String get reHomeBodyN1ChildrenN0ItemsN1Sub => get('re_home.body[1].children[0].items[1].sub');
  String get reHomeBodyN2RowsN0Label => get('re_home.body[2].rows[0].label');
  String get reHomeBodyN2RowsN1Label => get('re_home.body[2].rows[1].label');
  String get reHomeBodyN2RowsN1Sub => get('re_home.body[2].rows[1].sub');
  String get reHomeBodyN2RowsN2Label => get('re_home.body[2].rows[2].label');
  String get reHomeBodyN2RowsN3Label => get('re_home.body[2].rows[3].label');
  String get reHomeBodyN2RowsN3Sub => get('re_home.body[2].rows[3].sub');
  String get reHomeBodyN3Title => get('re_home.body[3].title');
  String get reHomeBodyN3Text => get('re_home.body[3].text');
  String get reLabsBodyN0Label => get('re_labs.body[0].label');
  String get reLabsBodyN1Label => get('re_labs.body[1].label');
  String get reLabsBodyN2Label => get('re_labs.body[2].label');
  String get reLabsBodyN2Placeholder => get('re_labs.body[2].placeholder');
  String get reLabsBodyN3Label => get('re_labs.body[3].label');
  String get reLabsBodyN3Placeholder => get('re_labs.body[3].placeholder');
  String get reLabsBodyN4Text => get('re_labs.body[4].text');
  String get reLabsBodyN5Label => get('re_labs.body[5].label');
  String get reLabsFooterN0ActionThenValue => get('re_labs.footer[0].action.then.value');
  String get reLabsFooterN0Label => get('re_labs.footer[0].label');
  String get reLabsHeaderTitle => get('re_labs.header.title');
  String get reLabsHeaderPill => get('re_labs.header.pill');
  String get reHistoryBodyN0Title => get('re_history.body[0].title');
  String get reHistoryBodyN0Caption => get('re_history.body[0].caption');
  String get reHistoryBodyN1RowsN0N0 => get('re_history.body[1].rows[0][0]');
  String get reHistoryBodyN1RowsN0N1 => get('re_history.body[1].rows[0][1]');
  String get reHistoryBodyN1RowsN1N0 => get('re_history.body[1].rows[1][0]');
  String get reHistoryBodyN1RowsN1N1 => get('re_history.body[1].rows[1][1]');
  String get reHistoryBodyN1RowsN2N0 => get('re_history.body[1].rows[2][0]');
  String get reHistoryBodyN1RowsN2N1 => get('re_history.body[1].rows[2][1]');
  String get reHistoryFooterN0Label => get('re_history.footer[0].label');
  String get reHistoryHeaderTitle => get('re_history.header.title');
  String get reSymptomsBodyN0Text => get('re_symptoms.body[0].text');
  String get reSymptomsBodyN1OptionsN0 => get('re_symptoms.body[1].options[0]');
  String get reSymptomsBodyN1OptionsN1 => get('re_symptoms.body[1].options[1]');
  String get reSymptomsBodyN1OptionsN2 => get('re_symptoms.body[1].options[2]');
  String get reSymptomsBodyN1OptionsN3 => get('re_symptoms.body[1].options[3]');
  String get reSymptomsBodyN1OptionsN4 => get('re_symptoms.body[1].options[4]');
  String get reSymptomsBodyN1OptionsN5 => get('re_symptoms.body[1].options[5]');
  String get reSymptomsBodyN2Text => get('re_symptoms.body[2].text');
  String get reSymptomsFooterN0Label => get('re_symptoms.footer[0].label');
  String get reSymptomsFooterN1Label => get('re_symptoms.footer[1].label');
  String get reSymptomsHeaderTitle => get('re_symptoms.header.title');
  String get nuIntroBodyN0Extra => get('nu_intro.body[0].extra');
  String get nuIntroBodyN1Text => get('nu_intro.body[1].text');
  String get nuIntroBodyN2RowsN0N0 => get('nu_intro.body[2].rows[0][0]');
  String get nuIntroBodyN2RowsN0N1 => get('nu_intro.body[2].rows[0][1]');
  String get nuIntroBodyN2RowsN1N0 => get('nu_intro.body[2].rows[1][0]');
  String get nuIntroBodyN2RowsN1N1 => get('nu_intro.body[2].rows[1][1]');
  String get nuIntroBodyN2RowsN2N0 => get('nu_intro.body[2].rows[2][0]');
  String get nuIntroBodyN2RowsN2N1 => get('nu_intro.body[2].rows[2][1]');
  String get nuIntroFooterN0Label => get('nu_intro.footer[0].label');
  String get nuIntroFooterN1ActionThenValue => get('nu_intro.footer[1].action.then.value');
  String get nuIntroFooterN1Label => get('nu_intro.footer[1].label');
  String get nuIntroHeaderPill => get('nu_intro.header.pill');
  String get nuQ1BodyN1Text => get('nu_q1.body[1].text');
  String get nuQ1BodyN2OptionsN0 => get('nu_q1.body[2].options[0]');
  String get nuQ1BodyN2OptionsN1 => get('nu_q1.body[2].options[1]');
  String get nuQ1BodyN2OptionsN2 => get('nu_q1.body[2].options[2]');
  String get nuQ1BodyN2OptionsN3 => get('nu_q1.body[2].options[3]');
  String get nuQ1BodyN2OptionsN4 => get('nu_q1.body[2].options[4]');
  String get nuQ1BodyN2OptionsN5 => get('nu_q1.body[2].options[5]');
  String get nuQ1BodyN2OptionsN6 => get('nu_q1.body[2].options[6]');
  String get nuQ1BodyN3Title => get('nu_q1.body[3].title');
  String get nuQ1BodyN3Text => get('nu_q1.body[3].text');
  String get nuQ1BodyN3ChildrenN0OptionsN0 => get('nu_q1.body[3].children[0].options[0]');
  String get nuQ1BodyN3ChildrenN0OptionsN1 => get('nu_q1.body[3].children[0].options[1]');
  String get nuQ1BodyN3ChildrenN0OptionsN2 => get('nu_q1.body[3].children[0].options[2]');
  String get nuQ1FooterN0Label => get('nu_q1.footer[0].label');
  String get nuQ1HeaderTitle => get('nu_q1.header.title');
  String get nuQ1HeaderPill => get('nu_q1.header.pill');
  String get nuHabitBodyN0Text => get('nu_habit.body[0].text');
  String get nuHabitBodyN1ItemsN0Label => get('nu_habit.body[1].items[0].label');
  String get nuHabitBodyN1ItemsN0Sub => get('nu_habit.body[1].items[0].sub');
  String get nuHabitBodyN1ItemsN0Badge => get('nu_habit.body[1].items[0].badge');
  String get nuHabitBodyN1ItemsN1Label => get('nu_habit.body[1].items[1].label');
  String get nuHabitBodyN1ItemsN1Sub => get('nu_habit.body[1].items[1].sub');
  String get nuHabitBodyN1ItemsN2Label => get('nu_habit.body[1].items[2].label');
  String get nuHabitBodyN1ItemsN2Sub => get('nu_habit.body[1].items[2].sub');
  String get nuHabitBodyN1ItemsN3Label => get('nu_habit.body[1].items[3].label');
  String get nuHabitBodyN1ItemsN3Sub => get('nu_habit.body[1].items[3].sub');
  String get nuHabitBodyN2ChildrenN0Label => get('nu_habit.body[2].children[0].label');
  String get nuHabitBodyN2ChildrenN0Sub => get('nu_habit.body[2].children[0].sub');
  String get nuHabitFooterN0Label => get('nu_habit.footer[0].label');
  String get nuHabitHeaderTitle => get('nu_habit.header.title');
  String get nuHabitHeaderPill => get('nu_habit.header.pill');
  String get nuHomeBodyN0Eyebrow => get('nu_home.body[0].eyebrow');
  String get nuHomeBodyN0Title => get('nu_home.body[0].title');
  String get nuHomeBodyN0Text => get('nu_home.body[0].text');
  String get nuHomeBodyN0CtaN0ActionValue => get('nu_home.body[0].cta[0].action.value');
  String get nuHomeBodyN0CtaN0Label => get('nu_home.body[0].cta[0].label');
  String get nuHomeBodyN1Eyebrow => get('nu_home.body[1].eyebrow');
  String get nuHomeBodyN1Title => get('nu_home.body[1].title');
  String get nuHomeBodyN2Eyebrow => get('nu_home.body[2].eyebrow');
  String get nuHomeBodyN2Title => get('nu_home.body[2].title');
  String get nuHomeBodyN2Text => get('nu_home.body[2].text');
  String get nuHomeBodyN3RowsN0Label => get('nu_home.body[3].rows[0].label');
  String get nuHomeBodyN3RowsN0Sub => get('nu_home.body[3].rows[0].sub');
  String get nuHomeBodyN3RowsN1Label => get('nu_home.body[3].rows[1].label');
  String get nuHomeBodyN3RowsN1Sub => get('nu_home.body[3].rows[1].sub');
  String get nuHomeBodyN3RowsN2Label => get('nu_home.body[3].rows[2].label');
  String get nuHomeBodyN3RowsN3Label => get('nu_home.body[3].rows[3].label');
  String get nuHomeBodyN3RowsN3Sub => get('nu_home.body[3].rows[3].sub');
  String get nuResetBodyN0Text => get('nu_reset.body[0].text');
  String get nuResetBodyN1Text => get('nu_reset.body[1].text');
  String get nuResetBodyN2ItemsN0Label => get('nu_reset.body[2].items[0].label');
  String get nuResetBodyN2ItemsN1Label => get('nu_reset.body[2].items[1].label');
  String get nuResetBodyN2ItemsN1Sub => get('nu_reset.body[2].items[1].sub');
  String get nuResetBodyN2ItemsN2Label => get('nu_reset.body[2].items[2].label');
  String get nuResetFooterN0ActionCasesN0ActionValue => get('nu_reset.footer[0].action.cases[0].action.value');
  String get nuResetFooterN0ActionCasesN1ActionValue => get('nu_reset.footer[0].action.cases[1].action.value');
  String get nuResetFooterN0Label => get('nu_reset.footer[0].label');
  String get nuResetHeaderTitle => get('nu_reset.header.title');
  String get nuResetHeaderPill => get('nu_reset.header.pill');
  String get nuWeek4BodyN1Text => get('nu_week4.body[1].text');
  String get nuWeek4BodyN2RowsN0N0 => get('nu_week4.body[2].rows[0][0]');
  String get nuWeek4BodyN2RowsN1N0 => get('nu_week4.body[2].rows[1][0]');
  String get nuWeek4BodyN2RowsN2N0 => get('nu_week4.body[2].rows[2][0]');
  String get nuWeek4BodyN2RowsN2N1 => get('nu_week4.body[2].rows[2][1]');
  String get nuWeek4BodyN3OptionsN0 => get('nu_week4.body[3].options[0]');
  String get nuWeek4BodyN3OptionsN1 => get('nu_week4.body[3].options[1]');
  String get nuWeek4BodyN3OptionsN2 => get('nu_week4.body[3].options[2]');
  String get nuWeek4BodyN3Label => get('nu_week4.body[3].label');
  String get nuWeek4FooterN0Label => get('nu_week4.footer[0].label');
  String get nuWeek4HeaderTitle => get('nu_week4.header.title');
  String get nuWeek4HeaderPill => get('nu_week4.header.pill');
  String get nuProtectBodyN0Text => get('nu_protect.body[0].text');
  String get nuProtectBodyN1Text => get('nu_protect.body[1].text');
  String get nuProtectBodyN2Title => get('nu_protect.body[2].title');
  String get nuProtectBodyN2Text => get('nu_protect.body[2].text');
  String get nuProtectBodyN2CtaN0Label => get('nu_protect.body[2].cta[0].label');
  String get nuProtectBodyN3Text => get('nu_protect.body[3].text');
  String get nuProtectBodyN3ActionsN0Label => get('nu_protect.body[3].actions[0].label');
  String get nuProtectBodyN3ActionsN1Label => get('nu_protect.body[3].actions[1].label');
  String get nuProtectFooterN0Label => get('nu_protect.footer[0].label');
  String get nuProtectHeaderTitle => get('nu_protect.header.title');
  String get nuProtectHeaderPill => get('nu_protect.header.pill');
  String get sdIntroBodyN0Extra => get('sd_intro.body[0].extra');
  String get sdIntroBodyN1Text => get('sd_intro.body[1].text');
  String get sdIntroBodyN2RowsN0N0 => get('sd_intro.body[2].rows[0][0]');
  String get sdIntroBodyN2RowsN0N1 => get('sd_intro.body[2].rows[0][1]');
  String get sdIntroBodyN2RowsN1N0 => get('sd_intro.body[2].rows[1][0]');
  String get sdIntroBodyN2RowsN1N1 => get('sd_intro.body[2].rows[1][1]');
  String get sdIntroBodyN2RowsN2N0 => get('sd_intro.body[2].rows[2][0]');
  String get sdIntroBodyN2RowsN2N1 => get('sd_intro.body[2].rows[2][1]');
  String get sdIntroFooterN0Label => get('sd_intro.footer[0].label');
  String get sdIntroFooterN1ActionThenValue => get('sd_intro.footer[1].action.then.value');
  String get sdIntroFooterN1Label => get('sd_intro.footer[1].label');
  String get sdIntroHeaderPill => get('sd_intro.header.pill');
  String get sdQ1BodyN1OptionsN0 => get('sd_q1.body[1].options[0]');
  String get sdQ1BodyN1OptionsN1 => get('sd_q1.body[1].options[1]');
  String get sdQ1BodyN1OptionsN2 => get('sd_q1.body[1].options[2]');
  String get sdQ1BodyN1Label => get('sd_q1.body[1].label');
  String get sdQ1BodyN2OptionsN0 => get('sd_q1.body[2].options[0]');
  String get sdQ1BodyN2OptionsN1 => get('sd_q1.body[2].options[1]');
  String get sdQ1BodyN2OptionsN2 => get('sd_q1.body[2].options[2]');
  String get sdQ1BodyN2Label => get('sd_q1.body[2].label');
  String get sdQ1BodyN3OptionsN0 => get('sd_q1.body[3].options[0]');
  String get sdQ1BodyN3OptionsN1 => get('sd_q1.body[3].options[1]');
  String get sdQ1BodyN3OptionsN2 => get('sd_q1.body[3].options[2]');
  String get sdQ1BodyN3Label => get('sd_q1.body[3].label');
  String get sdQ1BodyN4Text => get('sd_q1.body[4].text');
  String get sdQ1FooterN0Label => get('sd_q1.footer[0].label');
  String get sdQ1HeaderTitle => get('sd_q1.header.title');
  String get sdQ1HeaderPill => get('sd_q1.header.pill');
  String get sdPlanBodyN0Text => get('sd_plan.body[0].text');
  String get sdPlanBodyN1RowsN0N0 => get('sd_plan.body[1].rows[0][0]');
  String get sdPlanBodyN1RowsN0N1 => get('sd_plan.body[1].rows[0][1]');
  String get sdPlanBodyN1RowsN1N0 => get('sd_plan.body[1].rows[1][0]');
  String get sdPlanBodyN1RowsN1N1 => get('sd_plan.body[1].rows[1][1]');
  String get sdPlanBodyN1RowsN2N0 => get('sd_plan.body[1].rows[2][0]');
  String get sdPlanBodyN1RowsN2N1 => get('sd_plan.body[1].rows[2][1]');
  String get sdPlanBodyN2ChildrenN0ItemsN0Label => get('sd_plan.body[2].children[0].items[0].label');
  String get sdPlanBodyN2ChildrenN0ItemsN1Label => get('sd_plan.body[2].children[0].items[1].label');
  String get sdPlanBodyN3Text => get('sd_plan.body[3].text');
  String get sdPlanFooterN0Label => get('sd_plan.footer[0].label');
  String get sdPlanHeaderTitle => get('sd_plan.header.title');
  String get sdPlanHeaderPill => get('sd_plan.header.pill');
  String get sdHomeBodyN0Eyebrow => get('sd_home.body[0].eyebrow');
  String get sdHomeBodyN0Title => get('sd_home.body[0].title');
  String get sdHomeBodyN0CtaN0Label => get('sd_home.body[0].cta[0].label');
  String get sdHomeBodyN1Title => get('sd_home.body[1].title');
  String get sdHomeBodyN1Text => get('sd_home.body[1].text');
  String get sdHomeBodyN2RowsN0Label => get('sd_home.body[2].rows[0].label');
  String get sdHomeBodyN2RowsN0Sub => get('sd_home.body[2].rows[0].sub');
  String get sdHomeBodyN2RowsN1Label => get('sd_home.body[2].rows[1].label');
  String get sdHomeBodyN2RowsN1Sub => get('sd_home.body[2].rows[1].sub');
  String get sdHomeBodyN2RowsN2Label => get('sd_home.body[2].rows[2].label');
  String get sdHomeBodyN2RowsN2Sub => get('sd_home.body[2].rows[2].sub');
  String get sdHomeBodyN2RowsN3Label => get('sd_home.body[2].rows[3].label');
  String get sdHomeBodyN2RowsN3Sub => get('sd_home.body[2].rows[3].sub');
  String get sdHomeBodyN3ItemsN0Label => get('sd_home.body[3].items[0].label');
  String get sdHomeBodyN3ItemsN0Value => get('sd_home.body[3].items[0].value');
  String get sdHomeBodyN3ItemsN0Sub => get('sd_home.body[3].items[0].sub');
  String get sdHomeBodyN3ItemsN1Label => get('sd_home.body[3].items[1].label');
  String get sdHomeBodyN3ItemsN1Sub => get('sd_home.body[3].items[1].sub');
  String get sdSessionBodyN1Text => get('sd_session.body[1].text');
  String get sdSessionBodyN2Text => get('sd_session.body[2].text');
  String get sdSessionBodyN4OptionsN0 => get('sd_session.body[4].options[0]');
  String get sdSessionBodyN4OptionsN1 => get('sd_session.body[4].options[1]');
  String get sdSessionBodyN4OptionsN2 => get('sd_session.body[4].options[2]');
  String get sdSessionFooterN0ActionValue => get('sd_session.footer[0].action.value');
  String get sdSessionFooterN0Label => get('sd_session.footer[0].label');
  String get sdSessionFooterN1ActionThenValue => get('sd_session.footer[1].action.then.value');
  String get sdSessionFooterN1Label => get('sd_session.footer[1].label');
  String get sdSessionHeaderTitle => get('sd_session.header.title');
  String get sdSessionHeaderPill => get('sd_session.header.pill');
  String get sdFellBodyN0Text => get('sd_fell.body[0].text');
  String get sdFellBodyN1Label => get('sd_fell.body[1].label');
  String get sdFellBodyN2RowsN0Label => get('sd_fell.body[2].rows[0].label');
  String get sdFellBodyN2RowsN0Sub => get('sd_fell.body[2].rows[0].sub');
  String get sdFellBodyN3Title => get('sd_fell.body[3].title');
  String get sdFellBodyN3Text => get('sd_fell.body[3].text');
  String get sdFellFooterN0ActionThenValue => get('sd_fell.footer[0].action.then.value');
  String get sdFellFooterN0Label => get('sd_fell.footer[0].label');
  String get sdFellHeaderTitle => get('sd_fell.header.title');
  String get sdSafetyBodyN0Text => get('sd_safety.body[0].text');
  String get sdSafetyBodyN1ChildrenN0ItemsN0Label => get('sd_safety.body[1].children[0].items[0].label');
  String get sdSafetyBodyN1ChildrenN0ItemsN1Label => get('sd_safety.body[1].children[0].items[1].label');
  String get sdSafetyBodyN1ChildrenN0ItemsN2Label => get('sd_safety.body[1].children[0].items[2].label');
  String get sdSafetyBodyN1ChildrenN0ItemsN3Label => get('sd_safety.body[1].children[0].items[3].label');
  String get sdSafetyBodyN1ChildrenN0ItemsN4Label => get('sd_safety.body[1].children[0].items[4].label');
  String get sdSafetyBodyN2Text => get('sd_safety.body[2].text');
  String get sdSafetyFooterN0ActionThenValue => get('sd_safety.footer[0].action.then.value');
  String get sdSafetyFooterN0Label => get('sd_safety.footer[0].label');
  String get sdSafetyHeaderTitle => get('sd_safety.header.title');
  String get sdSafetyHeaderPill => get('sd_safety.header.pill');
  String get sdCaregiverBodyN0Text => get('sd_caregiver.body[0].text');
  String get sdCaregiverBodyN1Label => get('sd_caregiver.body[1].label');
  String get sdCaregiverBodyN1Placeholder => get('sd_caregiver.body[1].placeholder');
  String get sdCaregiverBodyN2Label => get('sd_caregiver.body[2].label');
  String get sdCaregiverBodyN3ItemsN0Label => get('sd_caregiver.body[3].items[0].label');
  String get sdCaregiverBodyN3ItemsN1Label => get('sd_caregiver.body[3].items[1].label');
  String get sdCaregiverBodyN3ItemsN2Label => get('sd_caregiver.body[3].items[2].label');
  String get sdCaregiverBodyN3ItemsN2Sub => get('sd_caregiver.body[3].items[2].sub');
  String get sdCaregiverBodyN3Label => get('sd_caregiver.body[3].label');
  String get sdCaregiverFooterN0ActionThenValue => get('sd_caregiver.footer[0].action.then.value');
  String get sdCaregiverFooterN0Label => get('sd_caregiver.footer[0].label');
  String get sdCaregiverHeaderTitle => get('sd_caregiver.header.title');
  String get sdCaregiverHeaderPill => get('sd_caregiver.header.pill');
  String get eaIntroBodyN0Extra => get('ea_intro.body[0].extra');
  String get eaIntroBodyN1Text => get('ea_intro.body[1].text');
  String get eaIntroBodyN2RowsN0N0 => get('ea_intro.body[2].rows[0][0]');
  String get eaIntroBodyN2RowsN0N1 => get('ea_intro.body[2].rows[0][1]');
  String get eaIntroBodyN2RowsN1N0 => get('ea_intro.body[2].rows[1][0]');
  String get eaIntroBodyN2RowsN1N1 => get('ea_intro.body[2].rows[1][1]');
  String get eaIntroBodyN2RowsN2N0 => get('ea_intro.body[2].rows[2][0]');
  String get eaIntroBodyN2RowsN2N1 => get('ea_intro.body[2].rows[2][1]');
  String get eaIntroFooterN0Label => get('ea_intro.footer[0].label');
  String get eaIntroFooterN1ActionThenValue => get('ea_intro.footer[1].action.then.value');
  String get eaIntroFooterN1Label => get('ea_intro.footer[1].label');
  String get eaIntroHeaderPill => get('ea_intro.header.pill');
  String get eaQ1BodyN1Text => get('ea_q1.body[1].text');
  String get eaQ1BodyN2Text => get('ea_q1.body[2].text');
  String get eaQ1BodyN3ItemsN0Label => get('ea_q1.body[3].items[0].label');
  String get eaQ1BodyN3ItemsN1Label => get('ea_q1.body[3].items[1].label');
  String get eaQ1BodyN3ItemsN2Label => get('ea_q1.body[3].items[2].label');
  String get eaQ1BodyN3ItemsN3Label => get('ea_q1.body[3].items[3].label');
  String get eaQ1BodyN4Text => get('ea_q1.body[4].text');
  String get eaQ1FooterN0Label => get('ea_q1.footer[0].label');
  String get eaQ1FooterN1Label => get('ea_q1.footer[1].label');
  String get eaQ1HeaderTitle => get('ea_q1.header.title');
  String get eaQ1HeaderPill => get('ea_q1.header.pill');
  String get eaResultBodyN0Text => get('ea_result.body[0].text');
  String get eaResultBodyN1Text => get('ea_result.body[1].text');
  String get eaResultBodyN2RowsN0Label => get('ea_result.body[2].rows[0].label');
  String get eaResultBodyN2RowsN0Sub => get('ea_result.body[2].rows[0].sub');
  String get eaResultBodyN2RowsN1Label => get('ea_result.body[2].rows[1].label');
  String get eaResultBodyN2RowsN1Sub => get('ea_result.body[2].rows[1].sub');
  String get eaResultBodyN2RowsN2Label => get('ea_result.body[2].rows[2].label');
  String get eaResultBodyN2RowsN2Sub => get('ea_result.body[2].rows[2].sub');
  String get eaResultBodyN3Text => get('ea_result.body[3].text');
  String get eaResultBodyN3ActionsN0Label => get('ea_result.body[3].actions[0].label');
  String get eaResultBodyN3ActionsN1Label => get('ea_result.body[3].actions[1].label');
  String get eaResultHeaderTitle => get('ea_result.header.title');
  String get eaResultHeaderPill => get('ea_result.header.pill');
  String get eaPlanBodyN0Text => get('ea_plan.body[0].text');
  String get eaPlanBodyN1Text => get('ea_plan.body[1].text');
  String get eaPlanBodyN2Label => get('ea_plan.body[2].label');
  String get eaPlanBodyN2Placeholder => get('ea_plan.body[2].placeholder');
  String get eaPlanBodyN3Label => get('ea_plan.body[3].label');
  String get eaPlanBodyN3Placeholder => get('ea_plan.body[3].placeholder');
  String get eaPlanBodyN4Label => get('ea_plan.body[4].label');
  String get eaPlanBodyN4Placeholder => get('ea_plan.body[4].placeholder');
  String get eaPlanBodyN5RowsN0N0 => get('ea_plan.body[5].rows[0][0]');
  String get eaPlanBodyN5RowsN0N1 => get('ea_plan.body[5].rows[0][1]');
  String get eaPlanBodyN5RowsN1N0 => get('ea_plan.body[5].rows[1][0]');
  String get eaPlanFooterN0Label => get('ea_plan.footer[0].label');
  String get eaPlanHeaderTitle => get('ea_plan.header.title');
  String get eaPlanHeaderPill => get('ea_plan.header.pill');
  String get eaHomeBodyN0Eyebrow => get('ea_home.body[0].eyebrow');
  String get eaHomeBodyN0Title => get('ea_home.body[0].title');
  String get eaHomeBodyN0CtaN0Label => get('ea_home.body[0].cta[0].label');
  String get eaHomeBodyN1RowsN0Label => get('ea_home.body[1].rows[0].label');
  String get eaHomeBodyN1RowsN0Sub => get('ea_home.body[1].rows[0].sub');
  String get eaHomeBodyN1RowsN1Label => get('ea_home.body[1].rows[1].label');
  String get eaHomeBodyN1RowsN1Sub => get('ea_home.body[1].rows[1].sub');
  String get eaHomeBodyN1RowsN2Label => get('ea_home.body[1].rows[2].label');
  String get eaHomeBodyN1RowsN3Label => get('ea_home.body[1].rows[3].label');
  String get eaHomeBodyN1RowsN3Sub => get('ea_home.body[1].rows[3].sub');
  String get eaHomeBodyN2Title => get('ea_home.body[2].title');
  String get eaHomeBodyN2Text => get('ea_home.body[2].text');
  String get eaHomeBodyN3Text => get('ea_home.body[3].text');
  String get eaHomeBodyN3ActionsN0Label => get('ea_home.body[3].actions[0].label');
  String get eaHomeBodyN3ActionsN1Label => get('ea_home.body[3].actions[1].label');
  String get eaMoodBodyN0OptionsN0 => get('ea_mood.body[0].options[0]');
  String get eaMoodBodyN0OptionsN1 => get('ea_mood.body[0].options[1]');
  String get eaMoodBodyN0OptionsN2 => get('ea_mood.body[0].options[2]');
  String get eaMoodBodyN0OptionsN3 => get('ea_mood.body[0].options[3]');
  String get eaMoodBodyN0OptionsN4 => get('ea_mood.body[0].options[4]');
  String get eaMoodBodyN0Label => get('ea_mood.body[0].label');
  String get eaMoodBodyN1OptionsN0 => get('ea_mood.body[1].options[0]');
  String get eaMoodBodyN1OptionsN1 => get('ea_mood.body[1].options[1]');
  String get eaMoodBodyN1OptionsN2 => get('ea_mood.body[1].options[2]');
  String get eaMoodBodyN1OptionsN3 => get('ea_mood.body[1].options[3]');
  String get eaMoodBodyN1OptionsN4 => get('ea_mood.body[1].options[4]');
  String get eaMoodBodyN1OptionsN5 => get('ea_mood.body[1].options[5]');
  String get eaMoodBodyN1OptionsN6 => get('ea_mood.body[1].options[6]');
  String get eaMoodBodyN1OptionsN7 => get('ea_mood.body[1].options[7]');
  String get eaMoodBodyN1Label => get('ea_mood.body[1].label');
  String get eaMoodBodyN2Eyebrow => get('ea_mood.body[2].eyebrow');
  String get eaMoodBodyN2Title => get('ea_mood.body[2].title');
  String get eaMoodBodyN2CtaN0Label => get('ea_mood.body[2].cta[0].label');
  String get eaMoodFooterN0ActionThenCasesN0ActionValue => get('ea_mood.footer[0].action.then.cases[0].action.value');
  String get eaMoodFooterN0Label => get('ea_mood.footer[0].label');
  String get eaMoodHeaderTitle => get('ea_mood.header.title');
  String get eaCheckbackBodyN0Text => get('ea_checkback.body[0].text');
  String get eaCheckbackBodyN1OptionsN0 => get('ea_checkback.body[1].options[0]');
  String get eaCheckbackBodyN1OptionsN1 => get('ea_checkback.body[1].options[1]');
  String get eaCheckbackBodyN1OptionsN2 => get('ea_checkback.body[1].options[2]');
  String get eaCheckbackBodyN2OptionsN0 => get('ea_checkback.body[2].options[0]');
  String get eaCheckbackBodyN2OptionsN1 => get('ea_checkback.body[2].options[1]');
  String get eaCheckbackBodyN2OptionsN2 => get('ea_checkback.body[2].options[2]');
  String get eaCheckbackBodyN2Label => get('ea_checkback.body[2].label');
  String get eaCheckbackBodyN3Text => get('ea_checkback.body[3].text');
  String get eaCheckbackBodyN3CtaN0Label => get('ea_checkback.body[3].cta[0].label');
  String get eaCheckbackFooterN0ActionThenValue => get('ea_checkback.footer[0].action.then.value');
  String get eaCheckbackFooterN0Label => get('ea_checkback.footer[0].label');
  String get eaCheckbackHeaderTitle => get('ea_checkback.header.title');
  String get eaCheckbackHeaderPill => get('ea_checkback.header.pill');
  String get ckIntroBodyN0Extra => get('ck_intro.body[0].extra');
  String get ckIntroBodyN1Text => get('ck_intro.body[1].text');
  String get ckIntroBodyN2RowsN0N0 => get('ck_intro.body[2].rows[0][0]');
  String get ckIntroBodyN2RowsN0N1 => get('ck_intro.body[2].rows[0][1]');
  String get ckIntroBodyN2RowsN1N0 => get('ck_intro.body[2].rows[1][0]');
  String get ckIntroBodyN2RowsN1N1 => get('ck_intro.body[2].rows[1][1]');
  String get ckIntroBodyN2RowsN2N0 => get('ck_intro.body[2].rows[2][0]');
  String get ckIntroBodyN2RowsN2N1 => get('ck_intro.body[2].rows[2][1]');
  String get ckIntroFooterN0Label => get('ck_intro.footer[0].label');
  String get ckIntroFooterN1ActionThenValue => get('ck_intro.footer[1].action.then.value');
  String get ckIntroFooterN1Label => get('ck_intro.footer[1].label');
  String get ckIntroHeaderPill => get('ck_intro.header.pill');
  String get ckQ1BodyN1Text => get('ck_q1.body[1].text');
  String get ckQ1BodyN2Label => get('ck_q1.body[2].label');
  String get ckQ1BodyN3OptionsN0 => get('ck_q1.body[3].options[0]');
  String get ckQ1BodyN3OptionsN1 => get('ck_q1.body[3].options[1]');
  String get ckQ1BodyN3OptionsN2 => get('ck_q1.body[3].options[2]');
  String get ckQ1BodyN3OptionsN3 => get('ck_q1.body[3].options[3]');
  String get ckQ1BodyN3Label => get('ck_q1.body[3].label');
  String get ckQ1BodyN4OptionsN0 => get('ck_q1.body[4].options[0]');
  String get ckQ1BodyN4OptionsN1 => get('ck_q1.body[4].options[1]');
  String get ckQ1BodyN4OptionsN2 => get('ck_q1.body[4].options[2]');
  String get ckQ1BodyN4OptionsN3 => get('ck_q1.body[4].options[3]');
  String get ckQ1BodyN4OptionsN4 => get('ck_q1.body[4].options[4]');
  String get ckQ1BodyN4Label => get('ck_q1.body[4].label');
  String get ckQ1BodyN5Text => get('ck_q1.body[5].text');
  String get ckQ1BodyN6Label => get('ck_q1.body[6].label');
  String get ckQ1FooterN0Label => get('ck_q1.footer[0].label');
  String get ckQ1HeaderTitle => get('ck_q1.header.title');
  String get ckQ1HeaderPill => get('ck_q1.header.pill');
  String get ckListBodyN0Text => get('ck_list.body[0].text');
  String get ckListBodyN1Eyebrow => get('ck_list.body[1].eyebrow');
  String get ckListBodyN1Title => get('ck_list.body[1].title');
  String get ckListBodyN1Text => get('ck_list.body[1].text');
  String get ckListBodyN1ChildrenN0ItemsN0Label => get('ck_list.body[1].children[0].items[0].label');
  String get ckListBodyN1ChildrenN0ItemsN1Label => get('ck_list.body[1].children[0].items[1].label');
  String get ckListBodyN2RowsN0Label => get('ck_list.body[2].rows[0].label');
  String get ckListBodyN2RowsN0Sub => get('ck_list.body[2].rows[0].sub');
  String get ckListBodyN2RowsN0Pill => get('ck_list.body[2].rows[0].pill');
  String get ckListBodyN2RowsN1Label => get('ck_list.body[2].rows[1].label');
  String get ckListBodyN2RowsN1Sub => get('ck_list.body[2].rows[1].sub');
  String get ckListBodyN2RowsN1Pill => get('ck_list.body[2].rows[1].pill');
  String get ckListBodyN2RowsN2Label => get('ck_list.body[2].rows[2].label');
  String get ckListBodyN2RowsN2Sub => get('ck_list.body[2].rows[2].sub');
  String get ckListBodyN2RowsN2Pill => get('ck_list.body[2].rows[2].pill');
  String get ckListBodyN2RowsN3Label => get('ck_list.body[2].rows[3].label');
  String get ckListBodyN2RowsN3Sub => get('ck_list.body[2].rows[3].sub');
  String get ckUptodateBodyN1Text => get('ck_uptodate.body[1].text');
  String get ckUptodateBodyN2Text => get('ck_uptodate.body[2].text');
  String get ckUptodateBodyN3Label => get('ck_uptodate.body[3].label');
  String get ckItemBodyN0Text => get('ck_item.body[0].text');
  String get ckItemBodyN1Text => get('ck_item.body[1].text');
  String get ckItemBodyN2RowsN0N0 => get('ck_item.body[2].rows[0][0]');
  String get ckItemBodyN2RowsN0N1 => get('ck_item.body[2].rows[0][1]');
  String get ckItemBodyN2RowsN1N0 => get('ck_item.body[2].rows[1][0]');
  String get ckItemBodyN2RowsN1N1 => get('ck_item.body[2].rows[1][1]');
  String get ckItemBodyN2RowsN2N0 => get('ck_item.body[2].rows[2][0]');
  String get ckItemBodyN2RowsN2N1 => get('ck_item.body[2].rows[2][1]');
  String get ckItemBodyN3Title => get('ck_item.body[3].title');
  String get ckItemBodyN3Text => get('ck_item.body[3].text');
  String get ckItemBodyN4Text => get('ck_item.body[4].text');
  String get ckItemFooterN0Label => get('ck_item.footer[0].label');
  String get ckItemFooterN1Label => get('ck_item.footer[1].label');
  String get ckItemHeaderTitle => get('ck_item.header.title');
  String get ckDoneBodyN0Label => get('ck_done.body[0].label');
  String get ckDoneBodyN0Placeholder => get('ck_done.body[0].placeholder');
  String get ckDoneBodyN1Label => get('ck_done.body[1].label');
  String get ckDoneBodyN1Placeholder => get('ck_done.body[1].placeholder');
  String get ckDoneBodyN2Label => get('ck_done.body[2].label');
  String get ckDoneBodyN2Placeholder => get('ck_done.body[2].placeholder');
  String get ckDoneBodyN3ItemsN0Label => get('ck_done.body[3].items[0].label');
  String get ckDoneFooterN0ActionThenValue => get('ck_done.footer[0].action.then.value');
  String get ckDoneFooterN0Label => get('ck_done.footer[0].label');
  String get ckDoneHeaderTitle => get('ck_done.header.title');
  String get ckDayBodyN0Text => get('ck_day.body[0].text');
  String get ckDayBodyN1ChildrenN0ItemsN0Label => get('ck_day.body[1].children[0].items[0].label');
  String get ckDayBodyN1ChildrenN0ItemsN1Label => get('ck_day.body[1].children[0].items[1].label');
  String get ckDayBodyN1ChildrenN0ItemsN2Label => get('ck_day.body[1].children[0].items[2].label');
  String get ckDayBodyN2Title => get('ck_day.body[2].title');
  String get ckDayBodyN2Text => get('ck_day.body[2].text');
  String get ckDayBodyN2CtaN0Label => get('ck_day.body[2].cta[0].label');
  String get ckDayFooterN0ActionValue => get('ck_day.footer[0].action.value');
  String get ckDayFooterN0Label => get('ck_day.footer[0].label');
  String get ckDayFooterN1Label => get('ck_day.footer[1].label');
  String get ckDayHeaderTitle => get('ck_day.header.title');
  String get ckDayHeaderPill => get('ck_day.header.pill');
  String get beIntroBodyN0Extra => get('be_intro.body[0].extra');
  String get beIntroBodyN1Text => get('be_intro.body[1].text');
  String get beIntroBodyN2RowsN0N0 => get('be_intro.body[2].rows[0][0]');
  String get beIntroBodyN2RowsN0N1 => get('be_intro.body[2].rows[0][1]');
  String get beIntroBodyN2RowsN1N0 => get('be_intro.body[2].rows[1][0]');
  String get beIntroBodyN2RowsN1N1 => get('be_intro.body[2].rows[1][1]');
  String get beIntroBodyN2RowsN2N0 => get('be_intro.body[2].rows[2][0]');
  String get beIntroBodyN2RowsN2N1 => get('be_intro.body[2].rows[2][1]');
  String get beIntroFooterN0Label => get('be_intro.footer[0].label');
  String get beIntroFooterN1ActionThenValue => get('be_intro.footer[1].action.then.value');
  String get beIntroFooterN1Label => get('be_intro.footer[1].label');
  String get beIntroHeaderPill => get('be_intro.header.pill');
  String get beQ1BodyN1Text => get('be_q1.body[1].text');
  String get beQ1BodyN2ItemsN0Label => get('be_q1.body[2].items[0].label');
  String get beQ1BodyN2ItemsN0Sub => get('be_q1.body[2].items[0].sub');
  String get beQ1BodyN2ItemsN1Label => get('be_q1.body[2].items[1].label');
  String get beQ1BodyN2ItemsN1Sub => get('be_q1.body[2].items[1].sub');
  String get beQ1BodyN2ItemsN2Label => get('be_q1.body[2].items[2].label');
  String get beQ1BodyN2ItemsN2Sub => get('be_q1.body[2].items[2].sub');
  String get beQ1BodyN2ItemsN3Label => get('be_q1.body[2].items[3].label');
  String get beQ1BodyN2ItemsN3Sub => get('be_q1.body[2].items[3].sub');
  String get beQ1FooterN0Label => get('be_q1.footer[0].label');
  String get beQ1HeaderTitle => get('be_q1.header.title');
  String get beQ1HeaderPill => get('be_q1.header.pill');
  String get beQ2BodyN1Text => get('be_q2.body[1].text');
  String get beQ2BodyN2OptionsN0 => get('be_q2.body[2].options[0]');
  String get beQ2BodyN2OptionsN1 => get('be_q2.body[2].options[1]');
  String get beQ2BodyN2OptionsN2 => get('be_q2.body[2].options[2]');
  String get beQ2BodyN2OptionsN3 => get('be_q2.body[2].options[3]');
  String get beQ2BodyN2OptionsN4 => get('be_q2.body[2].options[4]');
  String get beQ2BodyN2OptionsN5 => get('be_q2.body[2].options[5]');
  String get beQ2BodyN2OptionsN6 => get('be_q2.body[2].options[6]');
  String get beQ2BodyN2OptionsN7 => get('be_q2.body[2].options[7]');
  String get beQ2BodyN3Label => get('be_q2.body[3].label');
  String get beQ2BodyN4Text => get('be_q2.body[4].text');
  String get beQ2FooterN0Label => get('be_q2.footer[0].label');
  String get beQ2HeaderTitle => get('be_q2.header.title');
  String get beQ2HeaderPill => get('be_q2.header.pill');
  String get beHomeBodyN0Text => get('be_home.body[0].text');
  String get beHomeBodyN1RowsN0Label => get('be_home.body[1].rows[0].label');
  String get beHomeBodyN1RowsN0Sub => get('be_home.body[1].rows[0].sub');
  String get beHomeBodyN1RowsN0Pill => get('be_home.body[1].rows[0].pill');
  String get beHomeBodyN1RowsN1Label => get('be_home.body[1].rows[1].label');
  String get beHomeBodyN1RowsN1Sub => get('be_home.body[1].rows[1].sub');
  String get beHomeBodyN1RowsN2Label => get('be_home.body[1].rows[2].label');
  String get beHomeBodyN1RowsN2Sub => get('be_home.body[1].rows[2].sub');
  String get beHomeBodyN2Title => get('be_home.body[2].title');
  String get beHomeBodyN2Text => get('be_home.body[2].text');
  String get beHomeBodyN2CtaN0Label => get('be_home.body[2].cta[0].label');
  String get beHomeBodyN3RowsN0Label => get('be_home.body[3].rows[0].label');
  String get beHomeBodyN3RowsN1Label => get('be_home.body[3].rows[1].label');
  String get beHomeBodyN3RowsN1Sub => get('be_home.body[3].rows[1].sub');
  String get beTxBodyN0Eyebrow => get('be_tx.body[0].eyebrow');
  String get beTxBodyN0Title => get('be_tx.body[0].title');
  String get beTxBodyN0CtaN0Label => get('be_tx.body[0].cta[0].label');
  String get beTxBodyN1Title => get('be_tx.body[1].title');
  String get beTxBodyN1Text => get('be_tx.body[1].text');
  String get beTxBodyN1CtaN0Label => get('be_tx.body[1].cta[0].label');
  String get beTxBodyN2RowsN0Label => get('be_tx.body[2].rows[0].label');
  String get beTxBodyN2RowsN0Sub => get('be_tx.body[2].rows[0].sub');
  String get beTxBodyN2RowsN1Label => get('be_tx.body[2].rows[1].label');
  String get beTxBodyN2RowsN1Sub => get('be_tx.body[2].rows[1].sub');
  String get beTxBodyN2RowsN2Label => get('be_tx.body[2].rows[2].label');
  String get beTxBodyN2RowsN2Sub => get('be_tx.body[2].rows[2].sub');
  String get beDiaryBodyN0Text => get('be_diary.body[0].text');
  String get beDiaryBodyN1Label => get('be_diary.body[1].label');
  String get beDiaryBodyN2OptionsN0 => get('be_diary.body[2].options[0]');
  String get beDiaryBodyN2OptionsN1 => get('be_diary.body[2].options[1]');
  String get beDiaryBodyN2OptionsN2 => get('be_diary.body[2].options[2]');
  String get beDiaryBodyN2OptionsN3 => get('be_diary.body[2].options[3]');
  String get beDiaryBodyN2OptionsN4 => get('be_diary.body[2].options[4]');
  String get beDiaryBodyN2Label => get('be_diary.body[2].label');
  String get beDiaryBodyN3Title => get('be_diary.body[3].title');
  String get beDiaryBodyN3Text => get('be_diary.body[3].text');
  String get beDiaryBodyN3CtaN0Label => get('be_diary.body[3].cta[0].label');
  String get beDiaryFooterN0ActionThenValue => get('be_diary.footer[0].action.then.value');
  String get beDiaryFooterN0Label => get('be_diary.footer[0].label');
  String get beDiaryHeaderTitle => get('be_diary.header.title');
  String get beDiaryHeaderPill => get('be_diary.header.pill');
  String get beQuestionsBodyN0ChildrenN0ItemsN0Label => get('be_questions.body[0].children[0].items[0].label');
  String get beQuestionsBodyN0ChildrenN0ItemsN1Label => get('be_questions.body[0].children[0].items[1].label');
  String get beQuestionsBodyN0ChildrenN0ItemsN2Label => get('be_questions.body[0].children[0].items[2].label');
  String get beQuestionsBodyN1Label => get('be_questions.body[1].label');
  String get beQuestionsBodyN1Placeholder => get('be_questions.body[1].placeholder');
  String get beQuestionsFooterN0Label => get('be_questions.footer[0].label');
  String get beQuestionsFooterN1Label => get('be_questions.footer[1].label');
  String get beQuestionsHeaderTitle => get('be_questions.header.title');
  String get beQuestionsHeaderPill => get('be_questions.header.pill');
  String get beSurvivorBodyN0Text => get('be_survivor.body[0].text');
  String get beSurvivorBodyN1OptionsN0 => get('be_survivor.body[1].options[0]');
  String get beSurvivorBodyN1OptionsN1 => get('be_survivor.body[1].options[1]');
  String get beSurvivorBodyN1OptionsN2 => get('be_survivor.body[1].options[2]');
  String get beSurvivorBodyN2Title => get('be_survivor.body[2].title');
  String get beSurvivorBodyN2Text => get('be_survivor.body[2].text');
  String get beSurvivorBodyN2CtaN0Label => get('be_survivor.body[2].cta[0].label');
  String get beSurvivorBodyN3RowsN0N0 => get('be_survivor.body[3].rows[0][0]');
  String get beSurvivorBodyN3RowsN0N1 => get('be_survivor.body[3].rows[0][1]');
  String get beSurvivorBodyN4RowsN0Label => get('be_survivor.body[4].rows[0].label');
  String get beSurvivorFooterN0ActionThenValue => get('be_survivor.footer[0].action.then.value');
  String get beSurvivorFooterN0Label => get('be_survivor.footer[0].label');
  String get recordsHubBodyN0Text => get('records_hub.body[0].text');
  String get recordsHubBodyN1RowsN0Label => get('records_hub.body[1].rows[0].label');
  String get recordsHubBodyN1RowsN0Sub => get('records_hub.body[1].rows[0].sub');
  String get recordsHubBodyN1RowsN1Sub => get('records_hub.body[1].rows[1].sub');
  String get recordsHubBodyN1Title => get('records_hub.body[1].title');
  String get recordsHubBodyN2RowsN0Label => get('records_hub.body[2].rows[0].label');
  String get recordsHubBodyN2RowsN0Sub => get('records_hub.body[2].rows[0].sub');
  String get recordsHubBodyN2RowsN1Label => get('records_hub.body[2].rows[1].label');
  String get recordsHubBodyN2RowsN1Sub => get('records_hub.body[2].rows[1].sub');
  String get recordsHubBodyN2RowsN2Label => get('records_hub.body[2].rows[2].label');
  String get recordsHubBodyN2RowsN2Sub => get('records_hub.body[2].rows[2].sub');
  String get recordsHubBodyN2RowsN3Label => get('records_hub.body[2].rows[3].label');
  String get recordsHubBodyN2RowsN3Sub => get('records_hub.body[2].rows[3].sub');
  String get recordsHubBodyN2RowsN4Label => get('records_hub.body[2].rows[4].label');
  String get recordsHubBodyN2RowsN4Sub => get('records_hub.body[2].rows[4].sub');
  String get recordsHubBodyN2Title => get('records_hub.body[2].title');
  String get recordsHubBodyN3Title => get('records_hub.body[3].title');
  String get recordsHubBodyN3Text => get('records_hub.body[3].text');
  String get recordsHubFooterN0Label => get('records_hub.footer[0].label');
  String get recordsHubFooterN1Label => get('records_hub.footer[1].label');
  String get recordsHubHeaderTitle => get('records_hub.header.title');
  String get recordsHubEmptyBodyN1Text => get('records_hub_empty.body[1].text');
  String get recordsHubEmptyBodyN2Text => get('records_hub_empty.body[2].text');
  String get recordsHubEmptyBodyN3RowsN0N1 => get('records_hub_empty.body[3].rows[0][1]');
  String get recordsHubEmptyBodyN3RowsN1N1 => get('records_hub_empty.body[3].rows[1][1]');
  String get recordsHubEmptyBodyN3RowsN2N0 => get('records_hub_empty.body[3].rows[2][0]');
  String get recordsHubEmptyBodyN3RowsN2N1 => get('records_hub_empty.body[3].rows[2][1]');
  String get recordsHubEmptyFooterN0Label => get('records_hub_empty.footer[0].label');
  String get recordsHubEmptyFooterN1Label => get('records_hub_empty.footer[1].label');
  String get recordsHubEmptyHeaderTitle => get('records_hub_empty.header.title');
  String get recordsAddBodyN0Text => get('records_add.body[0].text');
  String get recordsAddBodyN1Text => get('records_add.body[1].text');
  String get recordsAddBodyN2RowsN0Label => get('records_add.body[2].rows[0].label');
  String get recordsAddBodyN2RowsN0Sub => get('records_add.body[2].rows[0].sub');
  String get recordsAddBodyN2RowsN1Sub => get('records_add.body[2].rows[1].sub');
  String get recordsAddBodyN2RowsN2Label => get('records_add.body[2].rows[2].label');
  String get recordsAddBodyN2RowsN2Sub => get('records_add.body[2].rows[2].sub');
  String get recordsAddBodyN2RowsN3Sub => get('records_add.body[2].rows[3].sub');
  String get recordsAddBodyN2RowsN4Sub => get('records_add.body[2].rows[4].sub');
  String get recordsAddBodyN2RowsN5Label => get('records_add.body[2].rows[5].label');
  String get recordsAddBodyN2RowsN5Sub => get('records_add.body[2].rows[5].sub');
  String get recordsAddBodyN2Title => get('records_add.body[2].title');
  String get recordsAddBodyN3RowsN0Label => get('records_add.body[3].rows[0].label');
  String get recordsAddBodyN3RowsN0Sub => get('records_add.body[3].rows[0].sub');
  String get recordsAddBodyN3Title => get('records_add.body[3].title');
  String get recordsAddBodyN4Text => get('records_add.body[4].text');
  String get recordsAddHeaderTitle => get('records_add.header.title');
  String get recordsSearchBodyN0Label => get('records_search.body[0].label');
  String get recordsSearchBodyN0Placeholder => get('records_search.body[0].placeholder');
  String get recordsSearchBodyN1RowsN0Label => get('records_search.body[1].rows[0].label');
  String get recordsSearchBodyN1RowsN0Sub => get('records_search.body[1].rows[0].sub');
  String get recordsSearchBodyN1RowsN1Label => get('records_search.body[1].rows[1].label');
  String get recordsSearchBodyN1RowsN1Sub => get('records_search.body[1].rows[1].sub');
  String get recordsSearchBodyN1RowsN2Label => get('records_search.body[1].rows[2].label');
  String get recordsSearchBodyN1RowsN2Sub => get('records_search.body[1].rows[2].sub');
  String get recordsSearchBodyN1Title => get('records_search.body[1].title');
  String get recordsSearchBodyN2Label => get('records_search.body[2].label');
  String get recordsSearchHeaderTitle => get('records_search.header.title');
  String get recordsFhirUrlBodyN0Text => get('records_fhir_url.body[0].text');
  String get recordsFhirUrlBodyN1Label => get('records_fhir_url.body[1].label');
  String get recordsFhirUrlBodyN1Hint => get('records_fhir_url.body[1].hint');
  String get recordsFhirUrlBodyN2Text => get('records_fhir_url.body[2].text');
  String get recordsFhirUrlFooterN0Label => get('records_fhir_url.footer[0].label');
  String get recordsFhirUrlHeaderTitle => get('records_fhir_url.header.title');
  String get recordsConsentBodyN0Text => get('records_consent.body[0].text');
  String get recordsConsentBodyN1RowsN0N0 => get('records_consent.body[1].rows[0][0]');
  String get recordsConsentBodyN1RowsN0N1 => get('records_consent.body[1].rows[0][1]');
  String get recordsConsentBodyN1RowsN1N0 => get('records_consent.body[1].rows[1][0]');
  String get recordsConsentBodyN1RowsN1N1 => get('records_consent.body[1].rows[1][1]');
  String get recordsConsentBodyN1RowsN2N0 => get('records_consent.body[1].rows[2][0]');
  String get recordsConsentBodyN1RowsN2N1 => get('records_consent.body[1].rows[2][1]');
  String get recordsConsentBodyN1RowsN3N0 => get('records_consent.body[1].rows[3][0]');
  String get recordsConsentBodyN1RowsN3N1 => get('records_consent.body[1].rows[3][1]');
  String get recordsConsentBodyN2ItemsN0Label => get('records_consent.body[2].items[0].label');
  String get recordsConsentBodyN2ItemsN0Sub => get('records_consent.body[2].items[0].sub');
  String get recordsConsentBodyN2ItemsN1Label => get('records_consent.body[2].items[1].label');
  String get recordsConsentBodyN2ItemsN1Sub => get('records_consent.body[2].items[1].sub');
  String get recordsConsentBodyN2ItemsN2Label => get('records_consent.body[2].items[2].label');
  String get recordsConsentBodyN2ItemsN2Sub => get('records_consent.body[2].items[2].sub');
  String get recordsConsentBodyN2ItemsN3Label => get('records_consent.body[2].items[3].label');
  String get recordsConsentBodyN2ItemsN3Sub => get('records_consent.body[2].items[3].sub');
  String get recordsConsentBodyN2ItemsN4Label => get('records_consent.body[2].items[4].label');
  String get recordsConsentBodyN2ItemsN4Sub => get('records_consent.body[2].items[4].sub');
  String get recordsConsentBodyN2ItemsN5Label => get('records_consent.body[2].items[5].label');
  String get recordsConsentBodyN2ItemsN5Sub => get('records_consent.body[2].items[5].sub');
  String get recordsConsentBodyN2Label => get('records_consent.body[2].label');
  String get recordsConsentBodyN3RowsN0Label => get('records_consent.body[3].rows[0].label');
  String get recordsConsentBodyN3RowsN0Sub => get('records_consent.body[3].rows[0].sub');
  String get recordsConsentBodyN4Title => get('records_consent.body[4].title');
  String get recordsConsentBodyN4Text => get('records_consent.body[4].text');
  String get recordsConsentFooterN0ActionCasesN0ActionCasesN1ActionValue => get('records_consent.footer[0].action.cases[0].action.cases[1].action.value');
  String get recordsConsentFooterN0ActionCasesN1ActionValue => get('records_consent.footer[0].action.cases[1].action.value');
  String get recordsConsentFooterN0Label => get('records_consent.footer[0].label');
  String get recordsConsentFooterN1Label => get('records_consent.footer[1].label');
  String get recordsConsentHeaderTitle => get('records_consent.header.title');
  String get recordsConsentHeaderPill => get('records_consent.header.pill');
  String get recordsConsentBbBodyN0Text => get('records_consent_bb.body[0].text');
  String get recordsConsentBbBodyN1RowsN0N0 => get('records_consent_bb.body[1].rows[0][0]');
  String get recordsConsentBbBodyN1RowsN0N1 => get('records_consent_bb.body[1].rows[0][1]');
  String get recordsConsentBbBodyN1RowsN1N0 => get('records_consent_bb.body[1].rows[1][0]');
  String get recordsConsentBbBodyN1RowsN1N1 => get('records_consent_bb.body[1].rows[1][1]');
  String get recordsConsentBbBodyN1RowsN2N0 => get('records_consent_bb.body[1].rows[2][0]');
  String get recordsConsentBbBodyN1RowsN2N1 => get('records_consent_bb.body[1].rows[2][1]');
  String get recordsConsentBbBodyN1RowsN3N0 => get('records_consent_bb.body[1].rows[3][0]');
  String get recordsConsentBbBodyN1RowsN3N1 => get('records_consent_bb.body[1].rows[3][1]');
  String get recordsConsentBbBodyN2ItemsN0Label => get('records_consent_bb.body[2].items[0].label');
  String get recordsConsentBbBodyN2ItemsN0Sub => get('records_consent_bb.body[2].items[0].sub');
  String get recordsConsentBbBodyN2ItemsN1Label => get('records_consent_bb.body[2].items[1].label');
  String get recordsConsentBbBodyN2ItemsN1Sub => get('records_consent_bb.body[2].items[1].sub');
  String get recordsConsentBbBodyN2ItemsN2Label => get('records_consent_bb.body[2].items[2].label');
  String get recordsConsentBbBodyN2ItemsN2Sub => get('records_consent_bb.body[2].items[2].sub');
  String get recordsConsentBbBodyN2ItemsN3Label => get('records_consent_bb.body[2].items[3].label');
  String get recordsConsentBbBodyN2ItemsN3Sub => get('records_consent_bb.body[2].items[3].sub');
  String get recordsConsentBbBodyN2ItemsN4Label => get('records_consent_bb.body[2].items[4].label');
  String get recordsConsentBbBodyN2ItemsN4Sub => get('records_consent_bb.body[2].items[4].sub');
  String get recordsConsentBbBodyN2ItemsN5Label => get('records_consent_bb.body[2].items[5].label');
  String get recordsConsentBbBodyN2ItemsN5Sub => get('records_consent_bb.body[2].items[5].sub');
  String get recordsConsentBbBodyN2Label => get('records_consent_bb.body[2].label');
  String get recordsConsentBbBodyN3RowsN0Label => get('records_consent_bb.body[3].rows[0].label');
  String get recordsConsentBbBodyN3RowsN0Sub => get('records_consent_bb.body[3].rows[0].sub');
  String get recordsConsentBbBodyN4Title => get('records_consent_bb.body[4].title');
  String get recordsConsentBbBodyN4Text => get('records_consent_bb.body[4].text');
  String get recordsConsentBbFooterN0ActionCasesN0ActionCasesN1ActionValue => get('records_consent_bb.footer[0].action.cases[0].action.cases[1].action.value');
  String get recordsConsentBbFooterN0ActionCasesN1ActionValue => get('records_consent_bb.footer[0].action.cases[1].action.value');
  String get recordsConsentBbFooterN0Label => get('records_consent_bb.footer[0].label');
  String get recordsConsentBbFooterN1Label => get('records_consent_bb.footer[1].label');
  String get recordsConsentBbHeaderTitle => get('records_consent_bb.header.title');
  String get recordsConsentBbHeaderPill => get('records_consent_bb.header.pill');
  String get recordsConsentDeviceBodyN0Text => get('records_consent_device.body[0].text');
  String get recordsConsentDeviceBodyN1Text => get('records_consent_device.body[1].text');
  String get recordsConsentDeviceBodyN2ItemsN0Label => get('records_consent_device.body[2].items[0].label');
  String get recordsConsentDeviceBodyN2ItemsN1Label => get('records_consent_device.body[2].items[1].label');
  String get recordsConsentDeviceBodyN2ItemsN2Label => get('records_consent_device.body[2].items[2].label');
  String get recordsConsentDeviceBodyN2ItemsN2Sub => get('records_consent_device.body[2].items[2].sub');
  String get recordsConsentDeviceBodyN2Label => get('records_consent_device.body[2].label');
  String get recordsConsentDeviceBodyN3RowsN0Label => get('records_consent_device.body[3].rows[0].label');
  String get recordsConsentDeviceBodyN3RowsN0Sub => get('records_consent_device.body[3].rows[0].sub');
  String get recordsConsentDeviceFooterN0ActionCasesN1ActionValue => get('records_consent_device.footer[0].action.cases[1].action.value');
  String get recordsConsentDeviceFooterN0Label => get('records_consent_device.footer[0].label');
  String get recordsConsentDeviceFooterN1Label => get('records_consent_device.footer[1].label');
  String get recordsConsentDeviceHeaderTitle => get('records_consent_device.header.title');
  String get recordsConsentDeviceHeaderPill => get('records_consent_device.header.pill');
  String get recordsImportingBodyN0Text => get('records_importing.body[0].text');
  String get recordsImportingBodyN1Text => get('records_importing.body[1].text');
  String get recordsImportingBodyN2ChildrenN0ItemsN0Label => get('records_importing.body[2].children[0].items[0].label');
  String get recordsImportingBodyN2ChildrenN0ItemsN0Sub => get('records_importing.body[2].children[0].items[0].sub');
  String get recordsImportingBodyN2ChildrenN0ItemsN1Label => get('records_importing.body[2].children[0].items[1].label');
  String get recordsImportingBodyN2ChildrenN0ItemsN1Sub => get('records_importing.body[2].children[0].items[1].sub');
  String get recordsImportingBodyN2ChildrenN0ItemsN2Label => get('records_importing.body[2].children[0].items[2].label');
  String get recordsImportingBodyN2ChildrenN0ItemsN2Sub => get('records_importing.body[2].children[0].items[2].sub');
  String get recordsImportingBodyN2ChildrenN0ItemsN3Label => get('records_importing.body[2].children[0].items[3].label');
  String get recordsImportingBodyN2ChildrenN0ItemsN3Sub => get('records_importing.body[2].children[0].items[3].sub');
  String get recordsImportingBodyN2ChildrenN0ItemsN4Label => get('records_importing.body[2].children[0].items[4].label');
  String get recordsImportingBodyN2ChildrenN0ItemsN4Sub => get('records_importing.body[2].children[0].items[4].sub');
  String get recordsImportingFooterN0Label => get('records_importing.footer[0].label');
  String get recordsImportingFooterN1Label => get('records_importing.footer[1].label');
  String get recordsImportingHeaderTitle => get('records_importing.header.title');
  String get recordsReviewBodyN0Text => get('records_review.body[0].text');
  String get recordsReviewBodyN1Text => get('records_review.body[1].text');
  String get recordsReviewBodyN2Text => get('records_review.body[2].text');
  String get recordsReviewBodyN2ActionLabel => get('records_review.body[2].actionLabel');
  String get recordsReviewBodyN3ChildrenN0ItemsN0Label => get('records_review.body[3].children[0].items[0].label');
  String get recordsReviewBodyN3ChildrenN0ItemsN0Sub => get('records_review.body[3].children[0].items[0].sub');
  String get recordsReviewBodyN3ChildrenN0ItemsN1Label => get('records_review.body[3].children[0].items[1].label');
  String get recordsReviewBodyN3ChildrenN0ItemsN1Sub => get('records_review.body[3].children[0].items[1].sub');
  String get recordsReviewBodyN4ChildrenN0ItemsN0Label => get('records_review.body[4].children[0].items[0].label');
  String get recordsReviewBodyN4ChildrenN0ItemsN0Sub => get('records_review.body[4].children[0].items[0].sub');
  String get recordsReviewBodyN5ChildrenN0ItemsN0Label => get('records_review.body[5].children[0].items[0].label');
  String get recordsReviewBodyN5ChildrenN0ItemsN0Sub => get('records_review.body[5].children[0].items[0].sub');
  String get recordsReviewBodyN5ChildrenN0ItemsN1Label => get('records_review.body[5].children[0].items[1].label');
  String get recordsReviewBodyN6ChildrenN0ItemsN0Label => get('records_review.body[6].children[0].items[0].label');
  String get recordsReviewBodyN6ChildrenN0ItemsN0Sub => get('records_review.body[6].children[0].items[0].sub');
  String get recordsReviewBodyN7ChildrenN0ItemsN0Label => get('records_review.body[7].children[0].items[0].label');
  String get recordsReviewBodyN7ChildrenN0ItemsN0Sub => get('records_review.body[7].children[0].items[0].sub');
  String get recordsReviewBodyN8Text => get('records_review.body[8].text');
  String get recordsReviewBodyN9RowsN0N0 => get('records_review.body[9].rows[0][0]');
  String get recordsReviewBodyN9RowsN0N1 => get('records_review.body[9].rows[0][1]');
  String get recordsReviewBodyN9RowsN1N0 => get('records_review.body[9].rows[1][0]');
  String get recordsReviewBodyN9RowsN1N1 => get('records_review.body[9].rows[1][1]');
  String get recordsReviewBodyN9RowsN2N0 => get('records_review.body[9].rows[2][0]');
  String get recordsReviewBodyN9RowsN2N1 => get('records_review.body[9].rows[2][1]');
  String get recordsReviewBodyN9RowsN3N0 => get('records_review.body[9].rows[3][0]');
  String get recordsReviewFooterN0ActionCasesN0ActionThenValue => get('records_review.footer[0].action.cases[0].action.then.value');
  String get recordsReviewFooterN0ActionCasesN1ActionValue => get('records_review.footer[0].action.cases[1].action.value');
  String get recordsReviewFooterN0Label => get('records_review.footer[0].label');
  String get recordsReviewFooterN1Label => get('records_review.footer[1].label');
  String get recordsReviewHeaderTitle => get('records_review.header.title');
  String get recordsReviewHeaderPill => get('records_review.header.pill');
  String get recordsConflictBodyN0Eyebrow => get('records_conflict.body[0].eyebrow');
  String get recordsConflictBodyN0Title => get('records_conflict.body[0].title');
  String get recordsConflictBodyN0ChildrenN0ItemsN0Label => get('records_conflict.body[0].children[0].items[0].label');
  String get recordsConflictBodyN0ChildrenN0ItemsN0Sub => get('records_conflict.body[0].children[0].items[0].sub');
  String get recordsConflictBodyN0ChildrenN0ItemsN1Label => get('records_conflict.body[0].children[0].items[1].label');
  String get recordsConflictBodyN0ChildrenN0ItemsN1Sub => get('records_conflict.body[0].children[0].items[1].sub');
  String get recordsConflictBodyN0ChildrenN0ItemsN2Label => get('records_conflict.body[0].children[0].items[2].label');
  String get recordsConflictBodyN0ChildrenN0ItemsN2Sub => get('records_conflict.body[0].children[0].items[2].sub');
  String get recordsConflictBodyN1Eyebrow => get('records_conflict.body[1].eyebrow');
  String get recordsConflictBodyN1Title => get('records_conflict.body[1].title');
  String get recordsConflictBodyN1ChildrenN0ItemsN0Label => get('records_conflict.body[1].children[0].items[0].label');
  String get recordsConflictBodyN1ChildrenN0ItemsN0Sub => get('records_conflict.body[1].children[0].items[0].sub');
  String get recordsConflictBodyN1ChildrenN0ItemsN1Label => get('records_conflict.body[1].children[0].items[1].label');
  String get recordsConflictBodyN1ChildrenN0ItemsN1Sub => get('records_conflict.body[1].children[0].items[1].sub');
  String get recordsConflictBodyN1ChildrenN0ItemsN2Label => get('records_conflict.body[1].children[0].items[2].label');
  String get recordsConflictBodyN1ChildrenN0ItemsN2Sub => get('records_conflict.body[1].children[0].items[2].sub');
  String get recordsConflictFooterN0ActionCasesN0ActionThenValue => get('records_conflict.footer[0].action.cases[0].action.then.value');
  String get recordsConflictFooterN0ActionCasesN1ActionValue => get('records_conflict.footer[0].action.cases[1].action.value');
  String get recordsConflictFooterN0Label => get('records_conflict.footer[0].label');
  String get recordsConflictHeaderTitle => get('records_conflict.header.title');
  String get recordsConflictHeaderPill => get('records_conflict.header.pill');
  String get recordsErrorBodyN1Text => get('records_error.body[1].text');
  String get recordsErrorBodyN2Text => get('records_error.body[2].text');
  String get recordsErrorFooterN0Label => get('records_error.footer[0].label');
  String get recordsErrorFooterN1Label => get('records_error.footer[1].label');
  String get recordsErrorFooterN2Label => get('records_error.footer[2].label');
  String get recordsErrorHeaderTitle => get('records_error.header.title');
  String get recordsSourceBodyN0RowsN0N0 => get('records_source.body[0].rows[0][0]');
  String get recordsSourceBodyN0RowsN0N1 => get('records_source.body[0].rows[0][1]');
  String get recordsSourceBodyN0RowsN1N0 => get('records_source.body[0].rows[1][0]');
  String get recordsSourceBodyN0RowsN1N1 => get('records_source.body[0].rows[1][1]');
  String get recordsSourceBodyN0RowsN2N0 => get('records_source.body[0].rows[2][0]');
  String get recordsSourceBodyN0RowsN2N1 => get('records_source.body[0].rows[2][1]');
  String get recordsSourceBodyN0RowsN3N0 => get('records_source.body[0].rows[3][0]');
  String get recordsSourceBodyN0RowsN3N1 => get('records_source.body[0].rows[3][1]');
  String get recordsSourceBodyN0RowsN4N0 => get('records_source.body[0].rows[4][0]');
  String get recordsSourceBodyN0RowsN4N1 => get('records_source.body[0].rows[4][1]');
  String get recordsSourceBodyN1RowsN0Label => get('records_source.body[1].rows[0].label');
  String get recordsSourceBodyN1RowsN0ActionThenValue => get('records_source.body[1].rows[0].action.then.value');
  String get recordsSourceBodyN2RowsN0Label => get('records_source.body[2].rows[0].label');
  String get recordsSourceBodyN2RowsN0Sub => get('records_source.body[2].rows[0].sub');
  String get recordsSourceBodyN2RowsN1Label => get('records_source.body[2].rows[1].label');
  String get recordsSourceBodyN2RowsN1Sub => get('records_source.body[2].rows[1].sub');
  String get recordsSourceBodyN2RowsN2Label => get('records_source.body[2].rows[2].label');
  String get recordsSourceBodyN2RowsN2Sub => get('records_source.body[2].rows[2].sub');
  String get recordsSourceBodyN2RowsN3Label => get('records_source.body[2].rows[3].label');
  String get recordsSourceBodyN2RowsN3Sub => get('records_source.body[2].rows[3].sub');
  String get recordsSourceBodyN2RowsN4Label => get('records_source.body[2].rows[4].label');
  String get recordsSourceBodyN2RowsN4Sub => get('records_source.body[2].rows[4].sub');
  String get recordsSourceBodyN2RowsN5Label => get('records_source.body[2].rows[5].label');
  String get recordsSourceBodyN2RowsN5Sub => get('records_source.body[2].rows[5].sub');
  String get recordsSourceBodyN2Title => get('records_source.body[2].title');
  String get recordsSourceFooterN0Label => get('records_source.footer[0].label');
  String get recordsSourceHeaderTitle => get('records_source.header.title');
  String get recordsDisconnectBodyN0Text => get('records_disconnect.body[0].text');
  String get recordsDisconnectBodyN1Text => get('records_disconnect.body[1].text');
  String get recordsDisconnectBodyN2ItemsN0Label => get('records_disconnect.body[2].items[0].label');
  String get recordsDisconnectBodyN2ItemsN0Sub => get('records_disconnect.body[2].items[0].sub');
  String get recordsDisconnectBodyN2ItemsN1Label => get('records_disconnect.body[2].items[1].label');
  String get recordsDisconnectBodyN2ItemsN1Sub => get('records_disconnect.body[2].items[1].sub');
  String get recordsDisconnectFooterN0ActionThenValue => get('records_disconnect.footer[0].action.then.value');
  String get recordsDisconnectFooterN0Label => get('records_disconnect.footer[0].label');
  String get recordsDisconnectFooterN1Label => get('records_disconnect.footer[1].label');
  String get recordsManualBodyN0Text => get('records_manual.body[0].text');
  String get recordsManualBodyN1OptionsN0 => get('records_manual.body[1].options[0]');
  String get recordsManualBodyN1OptionsN1 => get('records_manual.body[1].options[1]');
  String get recordsManualBodyN1OptionsN2 => get('records_manual.body[1].options[2]');
  String get recordsManualBodyN1OptionsN3 => get('records_manual.body[1].options[3]');
  String get recordsManualBodyN1OptionsN4 => get('records_manual.body[1].options[4]');
  String get recordsManualBodyN1OptionsN5 => get('records_manual.body[1].options[5]');
  String get recordsManualBodyN1Label => get('records_manual.body[1].label');
  String get recordsManualBodyN2Label => get('records_manual.body[2].label');
  String get recordsManualBodyN2Placeholder => get('records_manual.body[2].placeholder');
  String get recordsManualBodyN3Label => get('records_manual.body[3].label');
  String get recordsManualBodyN4Label => get('records_manual.body[4].label');
  String get recordsManualBodyN4Placeholder => get('records_manual.body[4].placeholder');
  String get recordsManualBodyN5Text => get('records_manual.body[5].text');
  String get recordsManualFooterN0ActionThenCasesN0ActionValue => get('records_manual.footer[0].action.then.cases[0].action.value');
  String get recordsManualFooterN0ActionThenCasesN2ActionValue => get('records_manual.footer[0].action.then.cases[2].action.value');
  String get recordsManualFooterN0Label => get('records_manual.footer[0].label');
  String get recordsManualHeaderTitle => get('records_manual.header.title');
  String get recordsManualErrorBodyN0Text => get('records_manual_error.body[0].text');
  String get recordsManualErrorBodyN1Label => get('records_manual_error.body[1].label');
  String get recordsManualErrorBodyN1Placeholder => get('records_manual_error.body[1].placeholder');
  String get recordsManualErrorBodyN2Label => get('records_manual_error.body[2].label');
  String get recordsManualErrorBodyN2Error => get('records_manual_error.body[2].error');
  String get recordsManualErrorBodyN3Label => get('records_manual_error.body[3].label');
  String get recordsManualErrorBodyN3Placeholder => get('records_manual_error.body[3].placeholder');
  String get recordsManualErrorFooterN0ActionThenCasesN0ActionValue => get('records_manual_error.footer[0].action.then.cases[0].action.value');
  String get recordsManualErrorFooterN0ActionThenCasesN1ActionValue => get('records_manual_error.footer[0].action.then.cases[1].action.value');
  String get recordsManualErrorFooterN0Label => get('records_manual_error.footer[0].label');
  String get recordsManualErrorFooterN1Label => get('records_manual_error.footer[1].label');
  String get recordsManualErrorHeaderTitle => get('records_manual_error.header.title');
  String get recordsItemBodyN0Title => get('records_item.body[0].title');
  String get recordsItemBodyN1RowsN0Label => get('records_item.body[1].rows[0].label');
  String get recordsItemBodyN1RowsN0Sub => get('records_item.body[1].rows[0].sub');
  String get recordsItemBodyN1RowsN1Label => get('records_item.body[1].rows[1].label');
  String get recordsItemBodyN1RowsN1Sub => get('records_item.body[1].rows[1].sub');
  String get recordsItemBodyN1RowsN2Label => get('records_item.body[1].rows[2].label');
  String get recordsItemBodyN1RowsN2Sub => get('records_item.body[1].rows[2].sub');
  String get recordsItemBodyN1Title => get('records_item.body[1].title');
  String get recordsItemBodyN2RowsN0N0 => get('records_item.body[2].rows[0][0]');
  String get recordsItemBodyN2RowsN0N1 => get('records_item.body[2].rows[0][1]');
  String get recordsItemBodyN2RowsN1N0 => get('records_item.body[2].rows[1][0]');
  String get recordsItemFooterN0Label => get('records_item.footer[0].label');
  String get recordsItemHeaderTitle => get('records_item.header.title');
  String get sfUnplugIntroBodyN1Text => get('sf_unplug_intro.body[1].text');
  String get sfUnplugIntroBodyN2Text => get('sf_unplug_intro.body[2].text');
  String get sfUnplugIntroBodyN3RowsN0N0 => get('sf_unplug_intro.body[3].rows[0][0]');
  String get sfUnplugIntroBodyN3RowsN0N1 => get('sf_unplug_intro.body[3].rows[0][1]');
  String get sfUnplugIntroBodyN3RowsN1N0 => get('sf_unplug_intro.body[3].rows[1][0]');
  String get sfUnplugIntroBodyN3RowsN1N1 => get('sf_unplug_intro.body[3].rows[1][1]');
  String get sfUnplugIntroBodyN3RowsN2N0 => get('sf_unplug_intro.body[3].rows[2][0]');
  String get sfUnplugIntroBodyN3RowsN2N1 => get('sf_unplug_intro.body[3].rows[2][1]');
  String get sfUnplugIntroBodyN3RowsN3N0 => get('sf_unplug_intro.body[3].rows[3][0]');
  String get sfUnplugIntroBodyN3RowsN3N1 => get('sf_unplug_intro.body[3].rows[3][1]');
  String get sfUnplugIntroBodyN3RowsN4N0 => get('sf_unplug_intro.body[3].rows[4][0]');
  String get sfUnplugIntroBodyN3RowsN4N1 => get('sf_unplug_intro.body[3].rows[4][1]');
  String get sfUnplugIntroFooterN0Label => get('sf_unplug_intro.footer[0].label');
  String get sfUnplugIntroFooterN1Label => get('sf_unplug_intro.footer[1].label');
  String get sfUnplugIntroHeaderPill => get('sf_unplug_intro.header.pill');
  String get sfUnplugAuthBodyN1Text => get('sf_unplug_auth.body[1].text');
  String get sfUnplugAuthBodyN2Text => get('sf_unplug_auth.body[2].text');
  String get sfUnplugAuthBodyN3RowsN0N0 => get('sf_unplug_auth.body[3].rows[0][0]');
  String get sfUnplugAuthBodyN3RowsN0N1 => get('sf_unplug_auth.body[3].rows[0][1]');
  String get sfUnplugAuthBodyN3RowsN1N0 => get('sf_unplug_auth.body[3].rows[1][0]');
  String get sfUnplugAuthBodyN3RowsN1N1 => get('sf_unplug_auth.body[3].rows[1][1]');
  String get sfUnplugAuthBodyN3RowsN2N0 => get('sf_unplug_auth.body[3].rows[2][0]');
  String get sfUnplugAuthBodyN3RowsN2N1 => get('sf_unplug_auth.body[3].rows[2][1]');
  String get sfUnplugAuthFooterN0Label => get('sf_unplug_auth.footer[0].label');
  String get sfUnplugAuthFooterN1Label => get('sf_unplug_auth.footer[1].label');
  String get sfUnplugAuthHeaderPill => get('sf_unplug_auth.header.pill');
  String get sfUnplugAuthDeniedBodyN0Text => get('sf_unplug_auth_denied.body[0].text');
  String get sfUnplugAuthDeniedBodyN1Text => get('sf_unplug_auth_denied.body[1].text');
  String get sfUnplugAuthDeniedBodyN2Text => get('sf_unplug_auth_denied.body[2].text');
  String get sfUnplugAuthDeniedFooterN0ActionCasesN1ActionValue => get('sf_unplug_auth_denied.footer[0].action.cases[1].action.value');
  String get sfUnplugAuthDeniedFooterN0Label => get('sf_unplug_auth_denied.footer[0].label');
  String get sfUnplugAuthDeniedFooterN1Label => get('sf_unplug_auth_denied.footer[1].label');
  String get sfUnplugAuthDeniedFooterN2Label => get('sf_unplug_auth_denied.footer[2].label');
  String get sfUnplugAuthDeniedHeaderPill => get('sf_unplug_auth_denied.header.pill');
  String get sfUnplugAuthUnavailableBodyN0Text => get('sf_unplug_auth_unavailable.body[0].text');
  String get sfUnplugAuthUnavailableBodyN1Text => get('sf_unplug_auth_unavailable.body[1].text');
  String get sfUnplugAuthUnavailableBodyN2Text => get('sf_unplug_auth_unavailable.body[2].text');
  String get sfUnplugAuthUnavailableFooterN0Label => get('sf_unplug_auth_unavailable.footer[0].label');
  String get sfUnplugAuthUnavailableHeaderPill => get('sf_unplug_auth_unavailable.header.pill');
  String get sfUnplugAuthNotificationsBodyN0Text => get('sf_unplug_auth_notifications.body[0].text');
  String get sfUnplugAuthNotificationsBodyN1Text => get('sf_unplug_auth_notifications.body[1].text');
  String get sfUnplugAuthNotificationsBodyN2Text => get('sf_unplug_auth_notifications.body[2].text');
  String get sfUnplugAuthNotificationsFooterN0Label => get('sf_unplug_auth_notifications.footer[0].label');
  String get sfUnplugAuthNotificationsFooterN1ActionCasesN2ActionValue => get('sf_unplug_auth_notifications.footer[1].action.cases[2].action.value');
  String get sfUnplugAuthNotificationsFooterN1Label => get('sf_unplug_auth_notifications.footer[1].label');
  String get sfUnplugAuthNotificationsFooterN2Label => get('sf_unplug_auth_notifications.footer[2].label');
  String get sfUnplugAuthNotificationsHeaderPill => get('sf_unplug_auth_notifications.header.pill');
  String get sfUnplugAuthAndroidBodyN0Text => get('sf_unplug_auth_android.body[0].text');
  String get sfUnplugAuthAndroidBodyN1Text => get('sf_unplug_auth_android.body[1].text');
  String get sfUnplugAuthAndroidBodyN2ItemsN0Label => get('sf_unplug_auth_android.body[2].items[0].label');
  String get sfUnplugAuthAndroidBodyN2ItemsN0Sub => get('sf_unplug_auth_android.body[2].items[0].sub');
  String get sfUnplugAuthAndroidBodyN2ItemsN1Label => get('sf_unplug_auth_android.body[2].items[1].label');
  String get sfUnplugAuthAndroidBodyN2ItemsN1Sub => get('sf_unplug_auth_android.body[2].items[1].sub');
  String get sfUnplugAuthAndroidBodyN2ItemsN2Label => get('sf_unplug_auth_android.body[2].items[2].label');
  String get sfUnplugAuthAndroidBodyN2ItemsN2Sub => get('sf_unplug_auth_android.body[2].items[2].sub');
  String get sfUnplugAuthAndroidBodyN2Label => get('sf_unplug_auth_android.body[2].label');
  String get sfUnplugAuthAndroidFooterN0Label => get('sf_unplug_auth_android.footer[0].label');
  String get sfUnplugAuthAndroidFooterN1Label => get('sf_unplug_auth_android.footer[1].label');
  String get sfUnplugAuthAndroidFooterN2Label => get('sf_unplug_auth_android.footer[2].label');
  String get sfUnplugAuthAndroidFooterN2ActionCasesN2ActionValue => get('sf_unplug_auth_android.footer[2].action.cases[2].action.value');
  String get sfUnplugAuthAndroidHeaderPill => get('sf_unplug_auth_android.header.pill');
  String get sfUnplugAppsBodyN0Text => get('sf_unplug_apps.body[0].text');
  String get sfUnplugAppsBodyN1Text => get('sf_unplug_apps.body[1].text');
  String get sfUnplugAppsBodyN2Title => get('sf_unplug_apps.body[2].title');
  String get sfUnplugAppsBodyN2Text => get('sf_unplug_apps.body[2].text');
  String get sfUnplugAppsBodyN3Text => get('sf_unplug_apps.body[3].text');
  String get sfUnplugAppsFooterN0Label => get('sf_unplug_apps.footer[0].label');
  String get sfUnplugAppsFooterN1Label => get('sf_unplug_apps.footer[1].label');
  String get sfUnplugAppsHeaderTitle => get('sf_unplug_apps.header.title');
  String get sfUnplugAppsHeaderPill => get('sf_unplug_apps.header.pill');
  String get sfUnplugPickerIosBodyN0Label => get('sf_unplug_picker_ios.body[0].label');
  String get sfUnplugPickerIosFooterN0Label => get('sf_unplug_picker_ios.footer[0].label');
  String get sfUnplugPickerIosFooterN1Label => get('sf_unplug_picker_ios.footer[1].label');
  String get sfUnplugAppsAndroidBodyN0Text => get('sf_unplug_apps_android.body[0].text');
  String get sfUnplugAppsAndroidBodyN1Text => get('sf_unplug_apps_android.body[1].text');
  String get sfUnplugAppsAndroidBodyN2ItemsN0Label => get('sf_unplug_apps_android.body[2].items[0].label');
  String get sfUnplugAppsAndroidBodyN2ItemsN1Label => get('sf_unplug_apps_android.body[2].items[1].label');
  String get sfUnplugAppsAndroidBodyN2ItemsN2Label => get('sf_unplug_apps_android.body[2].items[2].label');
  String get sfUnplugAppsAndroidBodyN2ItemsN3Label => get('sf_unplug_apps_android.body[2].items[3].label');
  String get sfUnplugAppsAndroidBodyN2ItemsN4Label => get('sf_unplug_apps_android.body[2].items[4].label');
  String get sfUnplugAppsAndroidBodyN2ItemsN5Label => get('sf_unplug_apps_android.body[2].items[5].label');
  String get sfUnplugAppsAndroidBodyN2Label => get('sf_unplug_apps_android.body[2].label');
  String get sfUnplugAppsAndroidBodyN3Text => get('sf_unplug_apps_android.body[3].text');
  String get sfUnplugAppsAndroidFooterN0Label => get('sf_unplug_apps_android.footer[0].label');
  String get sfUnplugAppsAndroidFooterN1Label => get('sf_unplug_apps_android.footer[1].label');
  String get sfUnplugAppsAndroidHeaderTitle => get('sf_unplug_apps_android.header.title');
  String get sfUnplugAppsAndroidHeaderPill => get('sf_unplug_apps_android.header.pill');
  String get sfUnplugAppsChosenBodyN0Text => get('sf_unplug_apps_chosen.body[0].text');
  String get sfUnplugAppsChosenBodyN1Text => get('sf_unplug_apps_chosen.body[1].text');
  String get sfUnplugAppsChosenBodyN2RowsN0Label => get('sf_unplug_apps_chosen.body[2].rows[0].label');
  String get sfUnplugAppsChosenBodyN2RowsN0Sub => get('sf_unplug_apps_chosen.body[2].rows[0].sub');
  String get sfUnplugAppsChosenBodyN2RowsN1Label => get('sf_unplug_apps_chosen.body[2].rows[1].label');
  String get sfUnplugAppsChosenBodyN2RowsN1Sub => get('sf_unplug_apps_chosen.body[2].rows[1].sub');
  String get sfUnplugAppsChosenBodyN2Title => get('sf_unplug_apps_chosen.body[2].title');
  String get sfUnplugAppsChosenBodyN3Label => get('sf_unplug_apps_chosen.body[3].label');
  String get sfUnplugAppsChosenBodyN3Placeholder => get('sf_unplug_apps_chosen.body[3].placeholder');
  String get sfUnplugAppsChosenBodyN4Label => get('sf_unplug_apps_chosen.body[4].label');
  String get sfUnplugAppsChosenFooterN0Label => get('sf_unplug_apps_chosen.footer[0].label');
  String get sfUnplugAppsChosenHeaderTitle => get('sf_unplug_apps_chosen.header.title');
  String get sfUnplugAppsChosenHeaderPill => get('sf_unplug_apps_chosen.header.pill');
  String get sfUnplugLimitsBodyN0Text => get('sf_unplug_limits.body[0].text');
  String get sfUnplugLimitsBodyN1ChildrenN0Label => get('sf_unplug_limits.body[1].children[0].label');
  String get sfUnplugLimitsBodyN1ChildrenN0MinLabel => get('sf_unplug_limits.body[1].children[0].minLabel');
  String get sfUnplugLimitsBodyN1ChildrenN0MaxLabel => get('sf_unplug_limits.body[1].children[0].maxLabel');
  String get sfUnplugLimitsBodyN1ChildrenN1Label => get('sf_unplug_limits.body[1].children[1].label');
  String get sfUnplugLimitsBodyN1ChildrenN2Text => get('sf_unplug_limits.body[1].children[2].text');
  String get sfUnplugLimitsBodyN2ItemsN0Label => get('sf_unplug_limits.body[2].items[0].label');
  String get sfUnplugLimitsBodyN2ItemsN0Sub => get('sf_unplug_limits.body[2].items[0].sub');
  String get sfUnplugLimitsBodyN2ItemsN1Label => get('sf_unplug_limits.body[2].items[1].label');
  String get sfUnplugLimitsBodyN2ItemsN1Sub => get('sf_unplug_limits.body[2].items[1].sub');
  String get sfUnplugLimitsBodyN2ItemsN2Label => get('sf_unplug_limits.body[2].items[2].label');
  String get sfUnplugLimitsBodyN2ItemsN2Sub => get('sf_unplug_limits.body[2].items[2].sub');
  String get sfUnplugLimitsBodyN2ItemsN2Badge => get('sf_unplug_limits.body[2].items[2].badge');
  String get sfUnplugLimitsBodyN2ItemsN3Label => get('sf_unplug_limits.body[2].items[3].label');
  String get sfUnplugLimitsBodyN2ItemsN3Sub => get('sf_unplug_limits.body[2].items[3].sub');
  String get sfUnplugLimitsBodyN2Label => get('sf_unplug_limits.body[2].label');
  String get sfUnplugLimitsBodyN3OptionsN0 => get('sf_unplug_limits.body[3].options[0]');
  String get sfUnplugLimitsBodyN3OptionsN1 => get('sf_unplug_limits.body[3].options[1]');
  String get sfUnplugLimitsBodyN3OptionsN2 => get('sf_unplug_limits.body[3].options[2]');
  String get sfUnplugLimitsBodyN3Label => get('sf_unplug_limits.body[3].label');
  String get sfUnplugLimitsBodyN4Label => get('sf_unplug_limits.body[4].label');
  String get sfUnplugLimitsBodyN5Text => get('sf_unplug_limits.body[5].text');
  String get sfUnplugLimitsBodyN6Text => get('sf_unplug_limits.body[6].text');
  String get sfUnplugLimitsFooterN0ActionThenValue => get('sf_unplug_limits.footer[0].action.then.value');
  String get sfUnplugLimitsFooterN0Label => get('sf_unplug_limits.footer[0].label');
  String get sfUnplugLimitsHeaderTitle => get('sf_unplug_limits.header.title');
  String get sfUnplugLimitsHeaderPill => get('sf_unplug_limits.header.pill');
  String get sfUnplugHomeBodyN0Title => get('sf_unplug_home.body[0].title');
  String get sfUnplugHomeBodyN0Text => get('sf_unplug_home.body[0].text');
  String get sfUnplugHomeBodyN1Eyebrow => get('sf_unplug_home.body[1].eyebrow');
  String get sfUnplugHomeBodyN1Title => get('sf_unplug_home.body[1].title');
  String get sfUnplugHomeBodyN1Text => get('sf_unplug_home.body[1].text');
  String get sfUnplugHomeBodyN1CtaN0Label => get('sf_unplug_home.body[1].cta[0].label');
  String get sfUnplugHomeBodyN2RowsN0Label => get('sf_unplug_home.body[2].rows[0].label');
  String get sfUnplugHomeBodyN2RowsN0Sub => get('sf_unplug_home.body[2].rows[0].sub');
  String get sfUnplugHomeBodyN2RowsN1Label => get('sf_unplug_home.body[2].rows[1].label');
  String get sfUnplugHomeBodyN2RowsN1Sub => get('sf_unplug_home.body[2].rows[1].sub');
  String get sfUnplugHomeBodyN2RowsN2Label => get('sf_unplug_home.body[2].rows[2].label');
  String get sfUnplugHomeBodyN2RowsN2Sub => get('sf_unplug_home.body[2].rows[2].sub');
  String get sfUnplugHomeBodyN2RowsN3Label => get('sf_unplug_home.body[2].rows[3].label');
  String get sfUnplugHomeBodyN2RowsN3Sub => get('sf_unplug_home.body[2].rows[3].sub');
  String get sfUnplugHomeBodyN2Title => get('sf_unplug_home.body[2].title');
  String get sfUnplugHomeBodyN3RowsN0Label => get('sf_unplug_home.body[3].rows[0].label');
  String get sfUnplugHomeBodyN3RowsN0Sub => get('sf_unplug_home.body[3].rows[0].sub');
  String get sfUnplugHomeBodyN3RowsN1Label => get('sf_unplug_home.body[3].rows[1].label');
  String get sfUnplugHomeBodyN3RowsN1Sub => get('sf_unplug_home.body[3].rows[1].sub');
  String get sfUnplugHomeHeaderPill => get('sf_unplug_home.header.pill');
  String get sfUnplugSessionBodyN0Text => get('sf_unplug_session.body[0].text');
  String get sfUnplugSessionBodyN1OptionsN0 => get('sf_unplug_session.body[1].options[0]');
  String get sfUnplugSessionBodyN1OptionsN1 => get('sf_unplug_session.body[1].options[1]');
  String get sfUnplugSessionBodyN1OptionsN2 => get('sf_unplug_session.body[1].options[2]');
  String get sfUnplugSessionBodyN1OptionsN3 => get('sf_unplug_session.body[1].options[3]');
  String get sfUnplugSessionBodyN1Label => get('sf_unplug_session.body[1].label');
  String get sfUnplugSessionBodyN2ItemsN0Label => get('sf_unplug_session.body[2].items[0].label');
  String get sfUnplugSessionBodyN2ItemsN0Sub => get('sf_unplug_session.body[2].items[0].sub');
  String get sfUnplugSessionBodyN2ItemsN1Label => get('sf_unplug_session.body[2].items[1].label');
  String get sfUnplugSessionBodyN2ItemsN1Sub => get('sf_unplug_session.body[2].items[1].sub');
  String get sfUnplugSessionBodyN2Label => get('sf_unplug_session.body[2].label');
  String get sfUnplugSessionBodyN3ChildrenN0Label => get('sf_unplug_session.body[3].children[0].label');
  String get sfUnplugSessionBodyN3ChildrenN0Sub => get('sf_unplug_session.body[3].children[0].sub');
  String get sfUnplugSessionFooterN0Label => get('sf_unplug_session.footer[0].label');
  String get sfUnplugSessionHeaderTitle => get('sf_unplug_session.header.title');
  String get sfUnplugSessionActiveBodyN0Label => get('sf_unplug_session_active.body[0].label');
  String get sfUnplugSessionActiveBodyN1Text => get('sf_unplug_session_active.body[1].text');
  String get sfUnplugSessionActiveBodyN2Title => get('sf_unplug_session_active.body[2].title');
  String get sfUnplugSessionActiveBodyN2Text => get('sf_unplug_session_active.body[2].text');
  String get sfUnplugSessionActiveBodyN2CtaN0Label => get('sf_unplug_session_active.body[2].cta[0].label');
  String get sfUnplugSessionActiveFooterN0Label => get('sf_unplug_session_active.footer[0].label');
  String get sfUnplugSessionActiveHeaderTitle => get('sf_unplug_session_active.header.title');
  String get sfUnplugSessionActiveHeaderPill => get('sf_unplug_session_active.header.pill');
  String get sfUnplugSessionEndBodyN0Text => get('sf_unplug_session_end.body[0].text');
  String get sfUnplugSessionEndBodyN1Text => get('sf_unplug_session_end.body[1].text');
  String get sfUnplugSessionEndBodyN2OptionsN0 => get('sf_unplug_session_end.body[2].options[0]');
  String get sfUnplugSessionEndBodyN2OptionsN1 => get('sf_unplug_session_end.body[2].options[1]');
  String get sfUnplugSessionEndBodyN2OptionsN2 => get('sf_unplug_session_end.body[2].options[2]');
  String get sfUnplugSessionEndBodyN2OptionsN3 => get('sf_unplug_session_end.body[2].options[3]');
  String get sfUnplugSessionEndBodyN2Label => get('sf_unplug_session_end.body[2].label');
  String get sfUnplugSessionEndBodyN3Label => get('sf_unplug_session_end.body[3].label');
  String get sfUnplugSessionEndBodyN3Placeholder => get('sf_unplug_session_end.body[3].placeholder');
  String get sfUnplugSessionEndFooterN0ActionCasesN1ActionValue => get('sf_unplug_session_end.footer[0].action.cases[1].action.value');
  String get sfUnplugSessionEndFooterN0Label => get('sf_unplug_session_end.footer[0].label');
  String get sfUnplugSessionEndFooterN1Label => get('sf_unplug_session_end.footer[1].label');
  String get sfUnplugSessionDoneBodyN1Caption => get('sf_unplug_session_done.body[1].caption');
  String get sfUnplugSessionDoneBodyN2Text => get('sf_unplug_session_done.body[2].text');
  String get sfUnplugSessionDoneFooterN0Label => get('sf_unplug_session_done.footer[0].label');
  String get sfUnplugSessionDoneHeaderTitle => get('sf_unplug_session_done.header.title');
  String get sfUnplugSessionDoneEarlyBodyN0Caption => get('sf_unplug_session_done_early.body[0].caption');
  String get sfUnplugSessionDoneEarlyBodyN1RowsN0N0 => get('sf_unplug_session_done_early.body[1].rows[0][0]');
  String get sfUnplugSessionDoneEarlyBodyN1RowsN0N1 => get('sf_unplug_session_done_early.body[1].rows[0][1]');
  String get sfUnplugSessionDoneEarlyBodyN1RowsN1N0 => get('sf_unplug_session_done_early.body[1].rows[1][0]');
  String get sfUnplugSessionDoneEarlyBodyN1RowsN1N1 => get('sf_unplug_session_done_early.body[1].rows[1][1]');
  String get sfUnplugSessionDoneEarlyBodyN2Text => get('sf_unplug_session_done_early.body[2].text');
  String get sfUnplugSessionDoneEarlyFooterN0Label => get('sf_unplug_session_done_early.footer[0].label');
  String get sfUnplugSessionDoneEarlyHeaderTitle => get('sf_unplug_session_done_early.header.title');
  String get sfUnplugShieldBodyN2Text => get('sf_unplug_shield.body[2].text');
  String get sfUnplugShieldBodyN3Text => get('sf_unplug_shield.body[3].text');
  String get sfUnplugShieldFooterN0ActionValue => get('sf_unplug_shield.footer[0].action.value');
  String get sfUnplugShieldFooterN0Label => get('sf_unplug_shield.footer[0].label');
  String get sfUnplugShieldFooterN1Label => get('sf_unplug_shield.footer[1].label');
  String get sfUnplugShieldFooterN1ActionValue => get('sf_unplug_shield.footer[1].action.value');
  String get sfUnplugShieldFirmBodyN2Text => get('sf_unplug_shield_firm.body[2].text');
  String get sfUnplugShieldFirmBodyN3Text => get('sf_unplug_shield_firm.body[3].text');
  String get sfUnplugShieldFirmFooterN0ActionValue => get('sf_unplug_shield_firm.footer[0].action.value');
  String get sfUnplugShieldFirmFooterN0Label => get('sf_unplug_shield_firm.footer[0].label');
  String get sfUnplugShieldFirmFooterN1Label => get('sf_unplug_shield_firm.footer[1].label');
  String get sfUnplugShieldFirmFooterN1ActionValue => get('sf_unplug_shield_firm.footer[1].action.value');
  String get sfUnplugOverlayBodyN1Text => get('sf_unplug_overlay.body[1].text');
  String get sfUnplugOverlayBodyN2Text => get('sf_unplug_overlay.body[2].text');
  String get sfUnplugOverlayBodyN4Text => get('sf_unplug_overlay.body[4].text');
  String get sfUnplugOverlayFooterN0ActionValue => get('sf_unplug_overlay.footer[0].action.value');
  String get sfUnplugOverlayFooterN0Label => get('sf_unplug_overlay.footer[0].label');
  String get sfUnplugOverlayFooterN1Label => get('sf_unplug_overlay.footer[1].label');
  String get sfUnplugOverlayFooterN2Label => get('sf_unplug_overlay.footer[2].label');
  String get sfUnplugOverlayFooterN2ActionValue => get('sf_unplug_overlay.footer[2].action.value');
  String get sfUnplugGateBodyN0Text => get('sf_unplug_gate.body[0].text');
  String get sfUnplugGateBodyN2Text => get('sf_unplug_gate.body[2].text');
  String get sfUnplugGateBodyN3Title => get('sf_unplug_gate.body[3].title');
  String get sfUnplugGateBodyN3Text => get('sf_unplug_gate.body[3].text');
  String get sfUnplugGateBodyN3CtaN0Label => get('sf_unplug_gate.body[3].cta[0].label');
  String get sfUnplugGateFooterN0ActionValue => get('sf_unplug_gate.footer[0].action.value');
  String get sfUnplugGateFooterN0Label => get('sf_unplug_gate.footer[0].label');
  String get sfUnplugGateFooterN1Label => get('sf_unplug_gate.footer[1].label');
  String get sfUnplugGateFooterN1ActionValue => get('sf_unplug_gate.footer[1].action.value');
  String get sfUnplugGateHeaderTitle => get('sf_unplug_gate.header.title');
  String get sfUnplugGateCommitBodyN0Text => get('sf_unplug_gate_commit.body[0].text');
  String get sfUnplugGateCommitBodyN1Text => get('sf_unplug_gate_commit.body[1].text');
  String get sfUnplugGateCommitBodyN2Label => get('sf_unplug_gate_commit.body[2].label');
  String get sfUnplugGateCommitBodyN2Placeholder => get('sf_unplug_gate_commit.body[2].placeholder');
  String get sfUnplugGateCommitBodyN3Title => get('sf_unplug_gate_commit.body[3].title');
  String get sfUnplugGateCommitBodyN3Text => get('sf_unplug_gate_commit.body[3].text');
  String get sfUnplugGateCommitBodyN3CtaN0Label => get('sf_unplug_gate_commit.body[3].cta[0].label');
  String get sfUnplugGateCommitFooterN0ActionValue => get('sf_unplug_gate_commit.footer[0].action.value');
  String get sfUnplugGateCommitFooterN0Label => get('sf_unplug_gate_commit.footer[0].label');
  String get sfUnplugGateCommitFooterN1Label => get('sf_unplug_gate_commit.footer[1].label');
  String get sfUnplugGateCommitFooterN1ActionCasesN0ActionValue => get('sf_unplug_gate_commit.footer[1].action.cases[0].action.value');
  String get sfUnplugGateCommitFooterN1ActionCasesN1ActionValue => get('sf_unplug_gate_commit.footer[1].action.cases[1].action.value');
  String get sfUnplugGateCommitHeaderTitle => get('sf_unplug_gate_commit.header.title');
  String get sfUnplugGateSumBodyN0Text => get('sf_unplug_gate_sum.body[0].text');
  String get sfUnplugGateSumBodyN2Label => get('sf_unplug_gate_sum.body[2].label');
  String get sfUnplugGateSumBodyN3Title => get('sf_unplug_gate_sum.body[3].title');
  String get sfUnplugGateSumBodyN3Text => get('sf_unplug_gate_sum.body[3].text');
  String get sfUnplugGateSumBodyN3CtaN0Label => get('sf_unplug_gate_sum.body[3].cta[0].label');
  String get sfUnplugGateSumFooterN0ActionValue => get('sf_unplug_gate_sum.footer[0].action.value');
  String get sfUnplugGateSumFooterN0Label => get('sf_unplug_gate_sum.footer[0].label');
  String get sfUnplugGateSumFooterN1Label => get('sf_unplug_gate_sum.footer[1].label');
  String get sfUnplugGateSumFooterN1ActionCasesN0ActionValue => get('sf_unplug_gate_sum.footer[1].action.cases[0].action.value');
  String get sfUnplugGateSumFooterN1ActionCasesN1ActionValue => get('sf_unplug_gate_sum.footer[1].action.cases[1].action.value');
  String get sfUnplugGateSumHeaderTitle => get('sf_unplug_gate_sum.header.title');
  String get sfUnplugHealthBodyN0Text => get('sf_unplug_health.body[0].text');
  String get sfUnplugHealthBodyN1ItemsN0Label => get('sf_unplug_health.body[1].items[0].label');
  String get sfUnplugHealthBodyN1ItemsN0Sub => get('sf_unplug_health.body[1].items[0].sub');
  String get sfUnplugHealthBodyN1ItemsN1Label => get('sf_unplug_health.body[1].items[1].label');
  String get sfUnplugHealthBodyN1ItemsN1Sub => get('sf_unplug_health.body[1].items[1].sub');
  String get sfUnplugHealthBodyN1ItemsN2Label => get('sf_unplug_health.body[1].items[2].label');
  String get sfUnplugHealthBodyN1ItemsN2Sub => get('sf_unplug_health.body[1].items[2].sub');
  String get sfUnplugHealthBodyN1ItemsN3Label => get('sf_unplug_health.body[1].items[3].label');
  String get sfUnplugHealthBodyN1ItemsN3Sub => get('sf_unplug_health.body[1].items[3].sub');
  String get sfUnplugHealthBodyN1Label => get('sf_unplug_health.body[1].label');
  String get sfUnplugHealthBodyN2Text => get('sf_unplug_health.body[2].text');
  String get sfUnplugHealthFooterN0Label => get('sf_unplug_health.footer[0].label');
  String get sfUnplugHealthHeaderTitle => get('sf_unplug_health.header.title');
  String get sfUnplugHealthNotificationsBodyN0Text => get('sf_unplug_health_notifications.body[0].text');
  String get sfUnplugHealthNotificationsBodyN1ItemsN0Label => get('sf_unplug_health_notifications.body[1].items[0].label');
  String get sfUnplugHealthNotificationsBodyN1ItemsN0Sub => get('sf_unplug_health_notifications.body[1].items[0].sub');
  String get sfUnplugHealthNotificationsBodyN1ItemsN1Label => get('sf_unplug_health_notifications.body[1].items[1].label');
  String get sfUnplugHealthNotificationsBodyN1ItemsN1Sub => get('sf_unplug_health_notifications.body[1].items[1].sub');
  String get sfUnplugHealthNotificationsBodyN1ItemsN2Label => get('sf_unplug_health_notifications.body[1].items[2].label');
  String get sfUnplugHealthNotificationsBodyN1ItemsN2Sub => get('sf_unplug_health_notifications.body[1].items[2].sub');
  String get sfUnplugHealthNotificationsBodyN1ItemsN3Label => get('sf_unplug_health_notifications.body[1].items[3].label');
  String get sfUnplugHealthNotificationsBodyN1ItemsN3Sub => get('sf_unplug_health_notifications.body[1].items[3].sub');
  String get sfUnplugHealthNotificationsBodyN1Label => get('sf_unplug_health_notifications.body[1].label');
  String get sfUnplugHealthNotificationsFooterN0Label => get('sf_unplug_health_notifications.footer[0].label');
  String get sfUnplugHealthNotificationsFooterN1ActionCasesN1ActionValue => get('sf_unplug_health_notifications.footer[1].action.cases[1].action.value');
  String get sfUnplugHealthNotificationsFooterN1Label => get('sf_unplug_health_notifications.footer[1].label');
  String get sfUnplugHealthNotificationsHeaderTitle => get('sf_unplug_health_notifications.header.title');
  String get sfUnplugHealthStoppedBodyN0Text => get('sf_unplug_health_stopped.body[0].text');
  String get sfUnplugHealthStoppedBodyN1ItemsN0Label => get('sf_unplug_health_stopped.body[1].items[0].label');
  String get sfUnplugHealthStoppedBodyN1ItemsN0Sub => get('sf_unplug_health_stopped.body[1].items[0].sub');
  String get sfUnplugHealthStoppedBodyN1ItemsN1Label => get('sf_unplug_health_stopped.body[1].items[1].label');
  String get sfUnplugHealthStoppedBodyN1ItemsN1Sub => get('sf_unplug_health_stopped.body[1].items[1].sub');
  String get sfUnplugHealthStoppedBodyN1ItemsN2Label => get('sf_unplug_health_stopped.body[1].items[2].label');
  String get sfUnplugHealthStoppedBodyN1ItemsN2Sub => get('sf_unplug_health_stopped.body[1].items[2].sub');
  String get sfUnplugHealthStoppedBodyN1Label => get('sf_unplug_health_stopped.body[1].label');
  String get sfUnplugHealthStoppedFooterN0Label => get('sf_unplug_health_stopped.footer[0].label');
  String get sfUnplugHealthStoppedFooterN1ActionCasesN1ActionValue => get('sf_unplug_health_stopped.footer[1].action.cases[1].action.value');
  String get sfUnplugHealthStoppedFooterN1Label => get('sf_unplug_health_stopped.footer[1].label');
  String get sfUnplugHealthStoppedHeaderTitle => get('sf_unplug_health_stopped.header.title');
  String get sfUnplugHealthAndroidBodyN0Text => get('sf_unplug_health_android.body[0].text');
  String get sfUnplugHealthAndroidBodyN1ItemsN0Label => get('sf_unplug_health_android.body[1].items[0].label');
  String get sfUnplugHealthAndroidBodyN1ItemsN0Sub => get('sf_unplug_health_android.body[1].items[0].sub');
  String get sfUnplugHealthAndroidBodyN1ItemsN1Label => get('sf_unplug_health_android.body[1].items[1].label');
  String get sfUnplugHealthAndroidBodyN1ItemsN1Sub => get('sf_unplug_health_android.body[1].items[1].sub');
  String get sfUnplugHealthAndroidBodyN1ItemsN2Label => get('sf_unplug_health_android.body[1].items[2].label');
  String get sfUnplugHealthAndroidBodyN1ItemsN2Sub => get('sf_unplug_health_android.body[1].items[2].sub');
  String get sfUnplugHealthAndroidBodyN1ItemsN3Label => get('sf_unplug_health_android.body[1].items[3].label');
  String get sfUnplugHealthAndroidBodyN1ItemsN3Sub => get('sf_unplug_health_android.body[1].items[3].sub');
  String get sfUnplugHealthAndroidBodyN1Label => get('sf_unplug_health_android.body[1].label');
  String get sfUnplugHealthAndroidBodyN2Text => get('sf_unplug_health_android.body[2].text');
  String get sfUnplugHealthAndroidFooterN0Label => get('sf_unplug_health_android.footer[0].label');
  String get sfUnplugHealthAndroidFooterN1Label => get('sf_unplug_health_android.footer[1].label');
  String get sfUnplugHealthAndroidHeaderTitle => get('sf_unplug_health_android.header.title');
  String get sfUnplugOffBodyN0Text => get('sf_unplug_off.body[0].text');
  String get sfUnplugOffBodyN1Text => get('sf_unplug_off.body[1].text');
  String get sfUnplugOffBodyN2ItemsN0Label => get('sf_unplug_off.body[2].items[0].label');
  String get sfUnplugOffBodyN2ItemsN0Sub => get('sf_unplug_off.body[2].items[0].sub');
  String get sfUnplugOffBodyN2ItemsN0Badge => get('sf_unplug_off.body[2].items[0].badge');
  String get sfUnplugOffBodyN2ItemsN1Label => get('sf_unplug_off.body[2].items[1].label');
  String get sfUnplugOffBodyN2ItemsN1Sub => get('sf_unplug_off.body[2].items[1].sub');
  String get sfUnplugOffFooterN0ActionCasesN0ActionThenValue => get('sf_unplug_off.footer[0].action.cases[0].action.then.value');
  String get sfUnplugOffFooterN0ActionCasesN1ActionThenValue => get('sf_unplug_off.footer[0].action.cases[1].action.then.value');
  String get sfUnplugOffFooterN0Label => get('sf_unplug_off.footer[0].label');
  String get sfUnplugOffFooterN1Label => get('sf_unplug_off.footer[1].label');
  String get sfHomeUnplugBodyN0Label => get('sf_home_unplug.body[0].label');
  String get sfHomeUnplugBodyN0Caption => get('sf_home_unplug.body[0].caption');
  String get sfHomeUnplugBodyN1Eyebrow => get('sf_home_unplug.body[1].eyebrow');
  String get sfHomeUnplugBodyN1ChildrenN0Value => get('sf_home_unplug.body[1].children[0].value');
  String get sfHomeUnplugBodyN1ChildrenN0Caption => get('sf_home_unplug.body[1].children[0].caption');
  String get sfHomeUnplugBodyN2Title => get('sf_home_unplug.body[2].title');
  String get sfHomeUnplugBodyN2Text => get('sf_home_unplug.body[2].text');
  String get sfHomeUnplugBodyN2CtaN0Label => get('sf_home_unplug.body[2].cta[0].label');
  String get sfHomeUnplugBodyN3Title => get('sf_home_unplug.body[3].title');
  String get sfHomeUnplugBodyN3Text => get('sf_home_unplug.body[3].text');
  String get sfHomeUnplugBodyN4Eyebrow => get('sf_home_unplug.body[4].eyebrow');
  String get sfHomeUnplugBodyN4ChildrenN0ItemsN0Label => get('sf_home_unplug.body[4].children[0].items[0].label');
  String get sfHomeUnplugBodyN4ChildrenN0ItemsN0Sub => get('sf_home_unplug.body[4].children[0].items[0].sub');
  String get sfHomeUnplugBodyN5RowsN0Label => get('sf_home_unplug.body[5].rows[0].label');
  String get sfHomeUnplugBodyN5RowsN0Sub => get('sf_home_unplug.body[5].rows[0].sub');
  String get sfHomeUnplugBodyN5RowsN1Label => get('sf_home_unplug.body[5].rows[1].label');
  String get sfHomeUnplugBodyN5RowsN1Sub => get('sf_home_unplug.body[5].rows[1].sub');
  String get sfHomeUnplugBodyN5RowsN2Label => get('sf_home_unplug.body[5].rows[2].label');
  String get sfHomeUnplugBodyN5RowsN2Sub => get('sf_home_unplug.body[5].rows[2].sub');
  String get sfHomeUnplugBodyN5RowsN3Label => get('sf_home_unplug.body[5].rows[3].label');
  String get sfHomeUnplugBodyN5RowsN3Sub => get('sf_home_unplug.body[5].rows[3].sub');
  String get sfHomeUnplugBodyN5RowsN4Label => get('sf_home_unplug.body[5].rows[4].label');
  String get sfHomeUnplugBodyN5RowsN4Sub => get('sf_home_unplug.body[5].rows[4].sub');
  String get sfHomeUnplugAndroidBodyN0Eyebrow => get('sf_home_unplug_android.body[0].eyebrow');
  String get sfHomeUnplugAndroidBodyN0ChildrenN0Value => get('sf_home_unplug_android.body[0].children[0].value');
  String get sfHomeUnplugAndroidBodyN0ChildrenN0Caption => get('sf_home_unplug_android.body[0].children[0].caption');
  String get sfHomeUnplugAndroidBodyN1ItemsN0Label => get('sf_home_unplug_android.body[1].items[0].label');
  String get sfHomeUnplugAndroidBodyN1ItemsN0Value => get('sf_home_unplug_android.body[1].items[0].value');
  String get sfHomeUnplugAndroidBodyN1ItemsN0Sub => get('sf_home_unplug_android.body[1].items[0].sub');
  String get sfHomeUnplugAndroidBodyN1ItemsN1Label => get('sf_home_unplug_android.body[1].items[1].label');
  String get sfHomeUnplugAndroidBodyN1ItemsN1Sub => get('sf_home_unplug_android.body[1].items[1].sub');
  String get sfHomeUnplugAndroidBodyN2Text => get('sf_home_unplug_android.body[2].text');
  String get sfHomeUnplugAndroidBodyN3Title => get('sf_home_unplug_android.body[3].title');
  String get sfHomeUnplugAndroidBodyN3Text => get('sf_home_unplug_android.body[3].text');
  String get sfHomeUnplugAndroidBodyN3CtaN0Label => get('sf_home_unplug_android.body[3].cta[0].label');
  String get sfHomeUnplugAndroidBodyN4Title => get('sf_home_unplug_android.body[4].title');
  String get sfHomeUnplugAndroidBodyN4Text => get('sf_home_unplug_android.body[4].text');
  String get sfHomeUnplugAndroidBodyN5Eyebrow => get('sf_home_unplug_android.body[5].eyebrow');
  String get sfHomeUnplugAndroidBodyN5ChildrenN0ItemsN0Label => get('sf_home_unplug_android.body[5].children[0].items[0].label');
  String get sfHomeUnplugAndroidBodyN5ChildrenN0ItemsN0Sub => get('sf_home_unplug_android.body[5].children[0].items[0].sub');
  String get sfHomeUnplugAndroidBodyN6RowsN0Label => get('sf_home_unplug_android.body[6].rows[0].label');
  String get sfHomeUnplugAndroidBodyN6RowsN0Sub => get('sf_home_unplug_android.body[6].rows[0].sub');
  String get sfHomeUnplugAndroidBodyN6RowsN1Label => get('sf_home_unplug_android.body[6].rows[1].label');
  String get sfHomeUnplugAndroidBodyN6RowsN1Sub => get('sf_home_unplug_android.body[6].rows[1].sub');
  String get sfHomeUnplugAndroidBodyN6RowsN2Label => get('sf_home_unplug_android.body[6].rows[2].label');
  String get sfHomeUnplugAndroidBodyN6RowsN2Sub => get('sf_home_unplug_android.body[6].rows[2].sub');
  String get sfHomeUnplugAndroidBodyN6RowsN3Label => get('sf_home_unplug_android.body[6].rows[3].label');
  String get sfHomeUnplugAndroidBodyN6RowsN3Sub => get('sf_home_unplug_android.body[6].rows[3].sub');
  String get sfHomeUnplugAndroidBodyN6RowsN4Label => get('sf_home_unplug_android.body[6].rows[4].label');
  String get sfHomeUnplugAndroidBodyN6RowsN4Sub => get('sf_home_unplug_android.body[6].rows[4].sub');
  String get sfWeekUnplugBodyN0Text => get('sf_week_unplug.body[0].text');
  String get sfWeekUnplugBodyN1Label => get('sf_week_unplug.body[1].label');
  String get sfWeekUnplugBodyN1Caption => get('sf_week_unplug.body[1].caption');
  String get sfWeekUnplugBodyN2Title => get('sf_week_unplug.body[2].title');
  String get sfWeekUnplugBodyN2Caption => get('sf_week_unplug.body[2].caption');
  String get sfWeekUnplugBodyN2LabelsN0 => get('sf_week_unplug.body[2].labels[0]');
  String get sfWeekUnplugBodyN2LabelsN1 => get('sf_week_unplug.body[2].labels[1]');
  String get sfWeekUnplugBodyN2LabelsN2 => get('sf_week_unplug.body[2].labels[2]');
  String get sfWeekUnplugBodyN2LabelsN3 => get('sf_week_unplug.body[2].labels[3]');
  String get sfWeekUnplugBodyN2LabelsN4 => get('sf_week_unplug.body[2].labels[4]');
  String get sfWeekUnplugBodyN2LabelsN5 => get('sf_week_unplug.body[2].labels[5]');
  String get sfWeekUnplugBodyN2LabelsN6 => get('sf_week_unplug.body[2].labels[6]');
  String get sfWeekUnplugBodyN3ItemsN0Label => get('sf_week_unplug.body[3].items[0].label');
  String get sfWeekUnplugBodyN3ItemsN1Label => get('sf_week_unplug.body[3].items[1].label');
  String get sfWeekUnplugBodyN3ItemsN1Sub => get('sf_week_unplug.body[3].items[1].sub');
  String get sfWeekUnplugBodyN4Eyebrow => get('sf_week_unplug.body[4].eyebrow');
  String get sfWeekUnplugBodyN4Text => get('sf_week_unplug.body[4].text');
  String get sfWeekUnplugBodyN4ChildrenN0Text => get('sf_week_unplug.body[4].children[0].text');
  String get sfWeekUnplugBodyN5Eyebrow => get('sf_week_unplug.body[5].eyebrow');
  String get sfWeekUnplugBodyN5Title => get('sf_week_unplug.body[5].title');
  String get sfWeekUnplugBodyN5ChildrenN0ItemsN0ActionValue => get('sf_week_unplug.body[5].children[0].items[0].action.value');
  String get sfWeekUnplugBodyN5ChildrenN0ItemsN0Label => get('sf_week_unplug.body[5].children[0].items[0].label');
  String get sfWeekUnplugBodyN5ChildrenN0ItemsN1Label => get('sf_week_unplug.body[5].children[0].items[1].label');
  String get sfWeekUnplugHeaderTitle => get('sf_week_unplug.header.title');
  String get programSettingsSfBodyN0RowsN0Sub => get('program_settings_sf.body[0].rows[0].sub');
  String get programSettingsSfBodyN1ItemsN0Label => get('program_settings_sf.body[1].items[0].label');
  String get programSettingsSfBodyN1ItemsN0Sub => get('program_settings_sf.body[1].items[0].sub');
  String get programSettingsSfBodyN1ItemsN1Label => get('program_settings_sf.body[1].items[1].label');
  String get programSettingsSfBodyN1ItemsN1Sub => get('program_settings_sf.body[1].items[1].sub');
  String get programSettingsSfBodyN1ItemsN2Label => get('program_settings_sf.body[1].items[2].label');
  String get programSettingsSfBodyN1ItemsN2Sub => get('program_settings_sf.body[1].items[2].sub');
  String get programSettingsSfBodyN1Label => get('program_settings_sf.body[1].label');
  String get programSettingsSfBodyN2Eyebrow => get('program_settings_sf.body[2].eyebrow');
  String get programSettingsSfBodyN2ChildrenN0Label => get('program_settings_sf.body[2].children[0].label');
  String get programSettingsSfBodyN2ChildrenN0Sub => get('program_settings_sf.body[2].children[0].sub');
  String get programSettingsSfBodyN2ChildrenN1Label => get('program_settings_sf.body[2].children[1].label');
  String get programSettingsSfBodyN3RowsN0Sub => get('program_settings_sf.body[3].rows[0].sub');
  String get programSettingsSfBodyN3RowsN1Label => get('program_settings_sf.body[3].rows[1].label');
  String get programSettingsSfBodyN3RowsN1Sub => get('program_settings_sf.body[3].rows[1].sub');
  String get programSettingsSfBodyN3RowsN2Label => get('program_settings_sf.body[3].rows[2].label');
  String get programSettingsSfBodyN3RowsN2Sub => get('program_settings_sf.body[3].rows[2].sub');
  String get programSettingsSfBodyN3Title => get('program_settings_sf.body[3].title');
  String get programSettingsSfBodyN4RowsN0Label => get('program_settings_sf.body[4].rows[0].label');
  String get programSettingsSfBodyN4RowsN0Sub => get('program_settings_sf.body[4].rows[0].sub');
  String get programSettingsSfBodyN4RowsN0ActionValue => get('program_settings_sf.body[4].rows[0].action.value');
  String get programSettingsSfBodyN4RowsN1Label => get('program_settings_sf.body[4].rows[1].label');
  String get programSettingsSfBodyN4RowsN1Sub => get('program_settings_sf.body[4].rows[1].sub');
  String get programSettingsSfBodyN4Title => get('program_settings_sf.body[4].title');
  String get programSettingsSfFooterN0ActionThenValue => get('program_settings_sf.footer[0].action.then.value');
  String get programSettingsSfFooterN0Label => get('program_settings_sf.footer[0].label');
  String get programSettingsSfHeaderTitle => get('program_settings_sf.header.title');
  String get accountDeleteAppleBodyN0Text => get('account_delete_apple.body[0].text');
  String get accountDeleteAppleBodyN1RowsN0N0 => get('account_delete_apple.body[1].rows[0][0]');
  String get accountDeleteAppleBodyN1RowsN1N0 => get('account_delete_apple.body[1].rows[1][0]');
  String get accountDeleteAppleBodyN1RowsN2N0 => get('account_delete_apple.body[1].rows[2][0]');
  String get accountDeleteAppleBodyN1RowsN3N0 => get('account_delete_apple.body[1].rows[3][0]');
  String get accountDeleteAppleBodyN1RowsN3N1 => get('account_delete_apple.body[1].rows[3][1]');
  String get accountDeleteAppleBodyN2Text => get('account_delete_apple.body[2].text');
  String get accountDeleteAppleBodyN3Label => get('account_delete_apple.body[3].label');
  String get accountDeleteAppleBodyN4Label => get('account_delete_apple.body[4].label');
  String get accountDeleteAppleBodyN4Placeholder => get('account_delete_apple.body[4].placeholder');
  String get accountDeleteAppleBodyN5Eyebrow => get('account_delete_apple.body[5].eyebrow');
  String get accountDeleteAppleBodyN5Title => get('account_delete_apple.body[5].title');
  String get accountDeleteAppleBodyN5Text => get('account_delete_apple.body[5].text');
  String get accountDeleteAppleFooterN0ActionCasesN1ActionValue => get('account_delete_apple.footer[0].action.cases[1].action.value');
  String get accountDeleteAppleFooterN0ActionCasesN2ActionValue => get('account_delete_apple.footer[0].action.cases[2].action.value');
  String get accountDeleteAppleFooterN0ActionCasesN3ActionValue => get('account_delete_apple.footer[0].action.cases[3].action.value');
  String get accountDeleteAppleFooterN0Label => get('account_delete_apple.footer[0].label');
  String get accountDeleteAppleHeaderTitle => get('account_delete_apple.header.title');
  String get accountDeleteGoogleBodyN0Text => get('account_delete_google.body[0].text');
  String get accountDeleteGoogleBodyN1RowsN0N0 => get('account_delete_google.body[1].rows[0][0]');
  String get accountDeleteGoogleBodyN1RowsN1N0 => get('account_delete_google.body[1].rows[1][0]');
  String get accountDeleteGoogleBodyN1RowsN2N0 => get('account_delete_google.body[1].rows[2][0]');
  String get accountDeleteGoogleBodyN1RowsN3N0 => get('account_delete_google.body[1].rows[3][0]');
  String get accountDeleteGoogleBodyN1RowsN3N1 => get('account_delete_google.body[1].rows[3][1]');
  String get accountDeleteGoogleBodyN2Text => get('account_delete_google.body[2].text');
  String get accountDeleteGoogleBodyN3Label => get('account_delete_google.body[3].label');
  String get accountDeleteGoogleBodyN4Label => get('account_delete_google.body[4].label');
  String get accountDeleteGoogleBodyN4Placeholder => get('account_delete_google.body[4].placeholder');
  String get accountDeleteGoogleBodyN5Eyebrow => get('account_delete_google.body[5].eyebrow');
  String get accountDeleteGoogleBodyN5Title => get('account_delete_google.body[5].title');
  String get accountDeleteGoogleBodyN5Text => get('account_delete_google.body[5].text');
  String get accountDeleteGoogleFooterN0ActionCasesN1ActionValue => get('account_delete_google.footer[0].action.cases[1].action.value');
  String get accountDeleteGoogleFooterN0ActionCasesN2ActionValue => get('account_delete_google.footer[0].action.cases[2].action.value');
  String get accountDeleteGoogleFooterN0ActionCasesN3ActionValue => get('account_delete_google.footer[0].action.cases[3].action.value');
  String get accountDeleteGoogleFooterN0Label => get('account_delete_google.footer[0].label');
  String get accountDeleteGoogleHeaderTitle => get('account_delete_google.header.title');
  String get authSessionAppleBodyN0Text => get('auth_session_apple.body[0].text');
  String get authSessionAppleBodyN1Text => get('auth_session_apple.body[1].text');
  String get authSessionAppleBodyN2Text => get('auth_session_apple.body[2].text');
  String get authSessionAppleFooterN0ItemsN0Label => get('auth_session_apple.footer[0].items[0].label');
  String get authSessionAppleFooterN0ItemsN0ActionCasesN1ActionValue => get('auth_session_apple.footer[0].items[0].action.cases[1].action.value');
  String get authSessionAppleFooterN1Label => get('auth_session_apple.footer[1].label');
  String get authSessionGoogleBodyN0Text => get('auth_session_google.body[0].text');
  String get authSessionGoogleBodyN1Text => get('auth_session_google.body[1].text');
  String get authSessionGoogleBodyN2Text => get('auth_session_google.body[2].text');
  String get authSessionGoogleFooterN0ItemsN0Label => get('auth_session_google.footer[0].items[0].label');
  String get authSessionGoogleFooterN0ItemsN0ActionCasesN1ActionValue => get('auth_session_google.footer[0].items[0].action.cases[1].action.value');
  String get authSessionGoogleFooterN1Label => get('auth_session_google.footer[1].label');
  String get sfScreentimeAndroidBodyN1Text => get('sf_screentime_android.body[1].text');
  String get sfScreentimeAndroidBodyN2Text => get('sf_screentime_android.body[2].text');
  String get sfScreentimeAndroidBodyN3RowsN0N0 => get('sf_screentime_android.body[3].rows[0][0]');
  String get sfScreentimeAndroidBodyN3RowsN0N1 => get('sf_screentime_android.body[3].rows[0][1]');
  String get sfScreentimeAndroidBodyN3RowsN1N0 => get('sf_screentime_android.body[3].rows[1][0]');
  String get sfScreentimeAndroidBodyN3RowsN1N1 => get('sf_screentime_android.body[3].rows[1][1]');
  String get sfScreentimeAndroidBodyN3RowsN2N0 => get('sf_screentime_android.body[3].rows[2][0]');
  String get sfScreentimeAndroidBodyN3RowsN2N1 => get('sf_screentime_android.body[3].rows[2][1]');
  String get sfScreentimeAndroidBodyN4ItemsN0Label => get('sf_screentime_android.body[4].items[0].label');
  String get sfScreentimeAndroidBodyN4ItemsN1Label => get('sf_screentime_android.body[4].items[1].label');
  String get sfScreentimeAndroidBodyN4ItemsN2Label => get('sf_screentime_android.body[4].items[2].label');
  String get sfScreentimeAndroidBodyN4Label => get('sf_screentime_android.body[4].label');
  String get sfScreentimeAndroidFooterN0ActionCasesN0ActionValue => get('sf_screentime_android.footer[0].action.cases[0].action.value');
  String get sfScreentimeAndroidFooterN0Label => get('sf_screentime_android.footer[0].label');
  String get sfScreentimeAndroidFooterN1Label => get('sf_screentime_android.footer[1].label');
  String get sfScreentimeAndroidHeaderTitle => get('sf_screentime_android.header.title');
  String get sfScreentimeAndroidHeaderPill => get('sf_screentime_android.header.pill');
  String get sfScreentimeAndroidDeniedBodyN0Text => get('sf_screentime_android_denied.body[0].text');
  String get sfScreentimeAndroidDeniedBodyN1Text => get('sf_screentime_android_denied.body[1].text');
  String get sfScreentimeAndroidDeniedBodyN2Text => get('sf_screentime_android_denied.body[2].text');
  String get sfScreentimeAndroidDeniedFooterN0Label => get('sf_screentime_android_denied.footer[0].label');
  String get sfScreentimeAndroidDeniedFooterN1Label => get('sf_screentime_android_denied.footer[1].label');
  String get sfScreentimeAndroidDeniedHeaderTitle => get('sf_screentime_android_denied.header.title');
  String get sfScreentimeAndroidDeniedHeaderPill => get('sf_screentime_android_denied.header.pill');
  String get sysUpdateAndroidBodyN1Text => get('sys_update_android.body[1].text');
  String get sysUpdateAndroidBodyN2Text => get('sys_update_android.body[2].text');
  String get sysUpdateAndroidFooterN0Label => get('sys_update_android.footer[0].label');
  String get sysUpdateAndroidFooterN1Label => get('sys_update_android.footer[1].label');
  String get sysUpdateAndroidHeaderTitle => get('sys_update_android.header.title');
  String get surfaceWidgetIosBodyN0Title => get('surface_widget_ios.body[0].title');
  String get surfaceWidgetIosBodyN0Text => get('surface_widget_ios.body[0].text');
  String get surfaceWidgetIosHeaderTitle => get('surface_widget_ios.header.title');
  String get surfaceWidgetAndroidBodyN0Title => get('surface_widget_android.body[0].title');
  String get surfaceWidgetAndroidBodyN0Text => get('surface_widget_android.body[0].text');
  String get surfaceWidgetAndroidHeaderTitle => get('surface_widget_android.header.title');
  String get surfaceShortcutsIosBodyN0RowsN0Label => get('surface_shortcuts_ios.body[0].rows[0].label');
  String get surfaceShortcutsIosBodyN0RowsN0Sub => get('surface_shortcuts_ios.body[0].rows[0].sub');
  String get surfaceShortcutsIosBodyN0RowsN1Label => get('surface_shortcuts_ios.body[0].rows[1].label');
  String get surfaceShortcutsIosBodyN0RowsN1Sub => get('surface_shortcuts_ios.body[0].rows[1].sub');
  String get surfaceShortcutsIosBodyN0Title => get('surface_shortcuts_ios.body[0].title');
  String get surfaceShortcutsIosBodyN1Text => get('surface_shortcuts_ios.body[1].text');
  String get surfaceShortcutsIosHeaderTitle => get('surface_shortcuts_ios.header.title');
  String get surfaceShortcutsIosNamedBodyN0RowsN0Label => get('surface_shortcuts_ios_named.body[0].rows[0].label');
  String get surfaceShortcutsIosNamedBodyN0RowsN0Sub => get('surface_shortcuts_ios_named.body[0].rows[0].sub');
  String get surfaceShortcutsIosNamedBodyN0RowsN1Label => get('surface_shortcuts_ios_named.body[0].rows[1].label');
  String get surfaceShortcutsIosNamedBodyN0RowsN1Sub => get('surface_shortcuts_ios_named.body[0].rows[1].sub');
  String get surfaceShortcutsIosNamedBodyN0Title => get('surface_shortcuts_ios_named.body[0].title');
  String get surfaceShortcutsIosNamedHeaderTitle => get('surface_shortcuts_ios_named.header.title');
  String get surfaceShortcutsAndroidBodyN0RowsN0Label => get('surface_shortcuts_android.body[0].rows[0].label');
  String get surfaceShortcutsAndroidBodyN0RowsN1Label => get('surface_shortcuts_android.body[0].rows[1].label');
  String get surfaceShortcutsAndroidBodyN1Text => get('surface_shortcuts_android.body[1].text');
  String get surfaceShortcutsAndroidHeaderTitle => get('surface_shortcuts_android.header.title');
  String get surfaceShortcutsAndroidNamedBodyN0RowsN0Label => get('surface_shortcuts_android_named.body[0].rows[0].label');
  String get surfaceShortcutsAndroidNamedBodyN0RowsN1Label => get('surface_shortcuts_android_named.body[0].rows[1].label');
  String get surfaceShortcutsAndroidNamedHeaderTitle => get('surface_shortcuts_android_named.header.title');
}

const Map<String, String> _en = <String, String>{
  'kit.back': 'Back',
  'kit.close': 'Close',
  'kit.account': 'Account',
  'kit.tab_today': 'Today',
  'kit.tab_plans': 'Plans',
  'kit.tab_progress': 'Progress',
  'kit.tab_learn': 'Learn',
  'kit.tab_support': 'Support',
  'kit.tab_semantics': '{tab} tab',
  'kit.step_of': 'Step {n} of {total}',
  'kit.zone_green': 'Green',
  'kit.zone_yellow': 'Yellow',
  'kit.zone_red': 'Red',
  'kit.zone_semantics': '{zone} zone',
  'kit.chart': 'Chart',
  'kit.chart_semantics': '{title}: {values}',
  'kit.chart_no_entry': 'no entry',
  'kit.seconds': 'SECONDS',
  'kit.ring_semantics': '{value} {label}',
  'kit.timer_semantics': '{value} {label}',
  'kit.weekday_initials': 'S M T W T F S',
  'kit.calendar_day': '{month} {day}',
  'kit.month_names': 'January|February|March|April|May|June|July|August|September|October|November|December',
  'kit.weekday_names': 'Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday',
  'kit.calendar_title': '{month} {year}',
  'kit.date_full': '{weekday}, {month} {day}, {year}',
  'kit.calendar_prev': 'Previous month',
  'kit.calendar_next': 'Next month',
  'kit.calendar_recommended': 'Recommended',
  'kit.days_to_prepare': '{n, plural, one{# day to prepare} other{# days to prepare}}',
  'kit.environment': 'Environment: {name}',
  'kit.quote': '“{text}”',
  'kit.emergency_help': 'Emergency help',
  'kit.loading': 'Loading',
  'kit.generic_error': 'Something went wrong. Please try again.',
  'kit.example': 'Example',
  'kit.call_fallback': 'Calling isn’t available here. Dial {number} now.',
  'kit.sms_fallback': 'Texting isn’t available here. Text {number} now.',
  'kit.copy': 'Copy',
  'kit.copied': 'Copied',
  'welcome.body[2].text': 'Welcome to Tether Health',
  'welcome.body[3].text': 'Care that meets you where you are.',
  'welcome.body[4].text': 'Small steps, practical support and no judgment, for the parts of your health you choose.',
  'welcome.body[5].rows[0][0]': 'Private by design',
  'welcome.body[5].rows[0][1]': 'No ads · never sold',
  'welcome.body[5].rows[1][0]': 'Help in one tap',
  'welcome.body[5].rows[1][1]': 'No typing needed',
  'welcome.body[5].rows[2][0]': 'Your pace',
  'welcome.body[5].rows[2][1]': 'Pause anytime',
  'welcome.footer[0].label': 'Get started',
  'welcome.footer[1].label': 'I already have an account',
  'welcome.footer[2].label': 'Terms and Privacy Notice',
  'ob_programs.body[1].text': 'What would you like support with?',
  'ob_programs.body[2].text': 'Choose any. You can add, pause or leave a program anytime.',
  'ob_programs.body[3].items[0].sub': 'Tobacco & nicotine',
  'ob_programs.body[3].items[1].sub': 'Social media use',
  'ob_programs.body[3].items[2].sub': 'Respiratory health',
  'ob_programs.body[3].items[3].sub': 'Cardiovascular health',
  'ob_programs.body[3].items[4].sub': 'Diabetes & metabolic health',
  'ob_programs.body[3].items[5].sub': 'Mental & behavioral health',
  'ob_programs.body[3].items[6].sub': 'Obesity & nutrition',
  'ob_programs.body[3].items[7].sub': 'Healthy aging',
  'ob_programs.body[4].label': 'See all 11 programs',
  'ob_programs.footer[0].countLabel': '{n, plural, one{Continue with # program} other{Continue with # programs}}',
  'ob_programs.footer[0].emptyLabel': 'Choose at least one program',
  'ob_programs.header.title': 'Choose programs',
  'ob_programs.header.pill': '1 of 5',
  'ob_focus.body[1].text': 'Two at a time works best.',
  'ob_focus.body[2].text': 'Focus programs get daily steps and reminders. Learn only gives you lessons, with no tracking.',
  'ob_focus.body[3].rows[0].sub': 'About 3 min a day',
  'ob_focus.body[3].rows[0].pill': 'Focus 1',
  'ob_focus.body[3].rows[1].sub': 'About 1 min a day',
  'ob_focus.body[3].rows[1].pill': 'Focus 2',
  'ob_focus.body[3].title': 'Focus · daily support',
  'ob_focus.body[4].rows[0].sub': 'Lessons about lung recovery',
  'ob_focus.body[4].rows[0].pill': 'Learn',
  'ob_focus.body[4].title': 'Learn only · no reminders',
  'ob_focus.body[5].title': 'Why two?',
  'ob_focus.body[5].text': 'People keep going with fewer daily asks. Swap anytime in Account → Programs.',
  'ob_focus.body[6].label': 'Add a third program',
  'ob_focus.footer[0].label': 'Continue',
  'ob_focus.header.title': 'Your focus',
  'ob_focus.header.pill': '2 of 5',
  'ob_third.body[0].text': 'Both focus slots are in use',
  'ob_third.body[1].text': 'Add Heartwise as…',
  'ob_third.body[2].items[0].label': 'Learn only for now',
  'ob_third.body[2].items[0].sub': 'Lessons, no reminders. Upgrade anytime.',
  'ob_third.body[2].items[0].badge': 'Suggested',
  'ob_third.body[2].items[1].label': 'Swap with ScrollFree',
  'ob_third.body[2].items[1].sub': 'ScrollFree pauses. Its data and progress are kept.',
  'ob_third.body[2].items[2].label': 'Swap with BreatheFree',
  'ob_third.body[2].items[2].sub': 'Not suggested during your quit week.',
  'ob_third.footer[0].action.value': 'Heartwise added as Learn only',
  'ob_third.footer[0].label': 'Continue',
  'ob_third.footer[1].label': 'Cancel',
  'ob_consent.body[1].text': 'Your story stays yours.',
  'ob_consent.body[2].text': 'Each program keeps its own data. Optional choices start off.',
  'ob_consent.body[3].eyebrow': 'Account · required',
  'ob_consent.body[3].children[0].label': 'Essential app data',
  'ob_consent.body[3].children[0].sub': 'Account, plans and progress, encrypted. Required.',
  'ob_consent.body[4].children[0].label': 'Private reminders',
  'ob_consent.body[4].children[0].sub': 'Lock screen: “You have a Tether reminder.”',
  'ob_consent.body[4].children[1].label': 'Share summaries with my care team',
  'ob_consent.body[4].children[1].sub': 'You preview every share',
  'ob_consent.body[5].children[0].label': 'Connect Screen Time',
  'ob_consent.body[5].children[0].sub': 'Optional · totals only, never content',
  'ob_consent.body[5].children[1].label': 'De-identified research',
  'ob_consent.body[6].text': 'No ads. No tobacco-industry funding. We never sell health information.',
  'ob_consent.body[7].label': 'Read the Privacy Notice',
  'ob_consent.footer[0].label': 'Agree and continue',
  'ob_consent.header.title': 'Your privacy',
  'ob_consent.header.pill': '3 of 5',
  'ob_basics.body[1].text': 'Shared · asked once for all programs',
  'ob_basics.body[2].text': 'A few basics',
  'ob_basics.body[3].label': 'What should we call you?',
  'ob_basics.body[3].placeholder': 'Alex',
  'ob_basics.body[4].label': 'Age range',
  'ob_basics.body[5].options[0]': '< 5 h',
  'ob_basics.body[5].options[1]': '5–6 h',
  'ob_basics.body[5].options[2]': '7–8 h',
  'ob_basics.body[5].options[3]': '9+ h',
  'ob_basics.body[5].label': 'Sleep on a typical night',
  'ob_basics.body[6].options[0]': 'Low',
  'ob_basics.body[6].options[1]': 'Some',
  'ob_basics.body[6].options[2]': 'High',
  'ob_basics.body[6].label': 'Usual stress',
  'ob_basics.body[7].title': 'Why we ask',
  'ob_basics.body[7].text': 'These answers are shared by your programs, so you’re never asked twice. Age range sets which lessons and screenings apply.',
  'ob_basics.footer[0].label': 'Continue',
  'ob_basics.header.title': 'About you',
  'ob_basics.header.pill': '4 of 5',
  'ob_setup.body[1].text': 'Let’s set up your programs.',
  'ob_setup.body[2].text': 'Each takes about 3 minutes. You can stop and come back.',
  'ob_setup.body[3].rows[0].sub': 'Quit plan · about 3 min',
  'ob_setup.body[3].rows[0].pill': 'Start',
  'ob_setup.body[3].rows[1].sub': 'Usage goal · about 2 min',
  'ob_setup.body[3].rows[1].pill': 'Start',
  'ob_setup.body[3].title': 'Focus programs',
  'ob_setup.body[4].rows[0].sub': 'Learn only · nothing to set up',
  'ob_setup.body[4].title': 'Learn only',
  'ob_setup.body[5].rows[0].label': 'Health records (optional)',
  'ob_setup.body[5].rows[0].sub': 'Import from Epic MyChart, Medicare or another FHIR source',
  'ob_setup.body[5].title': 'Your data',
  'ob_setup.body[6].title': 'Tip',
  'ob_setup.body[6].text': 'Finishing a program setup brings you back here.',
  'ob_setup.footer[0].label': 'Continue',
  'ob_setup.footer[1].label': 'Set up later',
  'ob_setup.header.title': 'Set up',
  'ob_setup.header.pill': '5 of 5',
  'ob_reminders.body[1].text': 'Quiet, private reminders',
  'ob_reminders.body[2].text': 'At most 2 a day, only for your focus programs.',
  'ob_reminders.body[3].eyebrow': 'Lock screen preview',
  'ob_reminders.body[3].text': 'Program names and health details stay hidden unless you turn them on.',
  'ob_reminders.body[3].children[0].text': 'You have a Tether reminder.',
  'ob_reminders.body[4].label': 'Quiet hours',
  'ob_reminders.body[4].sub': '9:00 PM – 7:00 AM · safety alerts still come through',
  'ob_reminders.footer[0].label': 'Turn on reminders',
  'ob_reminders.footer[1].label': 'Not now',
  'ob_reminders.header.title': 'Reminders',
  'ob_reminders_denied.body[0].text': 'Notifications are off in your phone settings.',
  'ob_reminders_denied.body[1].text': 'You can still use everything.',
  'ob_reminders_denied.body[2].text': 'Today shows your steps when you open the app. To get reminders, allow notifications for Tether in Settings.',
  'ob_reminders_denied.footer[0].label': 'Open phone settings',
  'ob_reminders_denied.footer[1].label': 'Continue without reminders',
  'ob_reminders_denied.header.title': 'Reminders',
  'ob_account.body[0].text': 'Create your account',
  'ob_account.body[1].text': 'Keeps your plans safe if you change phones. You can also continue on this phone only.',
  'ob_account.body[2].items[0].label': 'Continue with Apple',
  'ob_account.body[2].items[0].action.cases[0].action.cases[2].action.value': 'Sign-in cancelled',
  'ob_account.body[2].items[0].action.cases[1].action.value': 'You need to be 18 or older to continue.',
  'ob_account.body[2].items[1].label': 'Continue with Google',
  'ob_account.body[2].items[1].action.cases[0].action.cases[2].action.value': 'Sign-in cancelled',
  'ob_account.body[2].items[1].action.cases[1].action.value': 'You need to be 18 or older to continue.',
  'ob_account.body[3].text': 'Sign in with Apple can hide your email: we use Apple’s private relay address.',
  'ob_account.body[4].text': 'Or with email',
  'ob_account.body[5].label': 'Email',
  'ob_account.body[5].placeholder': 'alex@example.com',
  'ob_account.body[6].label': 'Password',
  'ob_account.body[6].hint': 'At least 12 characters. A passphrase works well.',
  'ob_account.body[7].items[0].label': 'I’m 18 or older',
  'ob_account.body[8].text': 'Guest plans are encrypted on this phone. If you sign up later, we ask before uploading them.',
  'ob_account.footer[0].action.cases[1].action.value': 'You need to be 18 or older to continue.',
  'ob_account.footer[0].label': 'Create account',
  'ob_account.footer[1].action.cases[1].action.value': 'You need to be 18 or older to continue.',
  'ob_account.footer[1].label': 'Continue on this phone only',
  'ob_account.header.title': 'Save your progress',
  'auth_verify.body[1].text': 'Confirm your email',
  'auth_verify.body[2].text': 'We sent a link to alex@example.com. Open it on this phone to finish.',
  'auth_verify.body[3].text': 'Your plan is saved on this phone while you wait. Nothing is lost if you close the app.',
  'auth_verify.footer[0].label': 'Open email app',
  'auth_verify.footer[1].label': 'I’ve confirmed my email',
  'auth_verify.footer[2].label': 'Resend link (available in 0:42)',
  'auth_verify.footer[2].action.value': 'Link sent again',
  'auth_verify.header.title': 'Check your email',
  'auth_signin.body[0].text': 'Welcome back',
  'auth_signin.body[1].items[0].label': 'Continue with Apple',
  'auth_signin.body[1].items[0].action.cases[3].action.value': 'Sign-in cancelled',
  'auth_signin.body[1].items[1].label': 'Continue with Google',
  'auth_signin.body[1].items[1].action.cases[3].action.value': 'Sign-in cancelled',
  'auth_signin.body[2].text': 'Or with email',
  'auth_signin.body[3].label': 'Email',
  'auth_signin.body[3].placeholder': 'alex@example.com',
  'auth_signin.body[4].label': 'Password',
  'auth_signin.body[5].label': 'Forgot password?',
  'auth_signin.footer[0].label': 'Sign in',
  'auth_signin.footer[1].label': 'Cancel',
  'auth_signin_error.body[0].text': 'Welcome back',
  'auth_signin_error.body[1].text': 'That email and password don’t match. Check both and try again.',
  'auth_signin_error.body[2].items[0].label': 'Continue with Apple',
  'auth_signin_error.body[2].items[0].action.cases[3].action.value': 'Sign-in cancelled',
  'auth_signin_error.body[2].items[1].label': 'Continue with Google',
  'auth_signin_error.body[2].items[1].action.cases[3].action.value': 'Sign-in cancelled',
  'auth_signin_error.body[3].text': 'Or with email',
  'auth_signin_error.body[4].label': 'Email',
  'auth_signin_error.body[4].placeholder': 'alex@example.com',
  'auth_signin_error.body[5].label': 'Password',
  'auth_signin_error.body[5].error': 'Password is incorrect.',
  'auth_signin_error.body[6].label': 'Forgot password?',
  'auth_signin_error.body[7].text': 'After 5 tries we pause sign-in for 15 minutes to protect your account.',
  'auth_signin_error.footer[0].label': 'Try again',
  'auth_signin_error.footer[1].label': 'Cancel',
  'auth_social_new.body[1].text': 'Create your Tether account?',
  'auth_social_new.body[2].text': 'No Tether account uses this Apple ID or Google account yet.',
  'auth_social_new.body[3].rows[0][0]': 'Name',
  'auth_social_new.body[3].rows[0][1]': 'Alex (shared by Apple)',
  'auth_social_new.body[3].rows[1][0]': 'Email',
  'auth_social_new.body[3].rows[1][1]': 'Private relay · Hide My Email',
  'auth_social_new.body[3].rows[2][0]': 'Password',
  'auth_social_new.body[3].rows[2][1]': 'None needed',
  'auth_social_new.body[4].text': 'You can add email & password or another sign-in method later in Account → Sign-in methods.',
  'auth_social_new.footer[0].label': 'Create my account',
  'auth_social_new.footer[1].label': 'Use a different account',
  'auth_social_new.header.title': 'Create account',
  'auth_link.body[1].text': 'You already have a Tether account',
  'auth_link.body[2].text': 'alex@example.com signed up with email and password. Enter your password once to link Google. After that, either sign-in works.',
  'auth_link.body[3].label': 'Password',
  'auth_link.body[4].label': 'Forgot password?',
  'auth_link.footer[0].label': 'Link and sign in',
  'auth_link.footer[1].label': 'Cancel',
  'auth_link.header.title': 'Link accounts',
  'auth_social_error.body[1].text': 'Couldn’t sign in',
  'auth_social_error.body[2].text': 'Google sign-in didn’t finish. Check your connection and try again, or use email.',
  'auth_social_error.body[3].text': 'Nothing was saved or shared.',
  'auth_social_error.footer[0].action.cases[1].action.value': 'Still can’t reach Google. Try email.',
  'auth_social_error.footer[0].label': 'Try again',
  'auth_social_error.footer[1].label': 'Use email instead',
  'auth_social_error.header.title': 'Sign in',
  'auth_forgot.body[0].text': 'Forgot your password?',
  'auth_forgot.body[1].text': 'Enter your email and we’ll send a reset link.',
  'auth_forgot.body[2].label': 'Email',
  'auth_forgot.body[2].placeholder': 'alex@example.com',
  'auth_forgot.footer[0].label': 'Send reset link',
  'auth_forgot.header.title': 'Reset password',
  'auth_forgot_sent.body[1].text': 'Check your email',
  'auth_forgot_sent.body[2].text': 'If an account exists for that address, a reset link is on its way. It expires in 1 hour.',
  'auth_forgot_sent.body[3].text': 'We never say whether an email is registered, to protect your privacy.',
  'auth_forgot_sent.footer[0].label': 'Back to welcome',
  'auth_forgot_sent.header.title': 'Reset password',
  'auth_newpass.body[0].text': 'Choose a new password',
  'auth_newpass.body[1].label': 'New password',
  'auth_newpass.body[1].hint': 'At least 12 characters.',
  'auth_newpass.body[2].label': 'Confirm password',
  'auth_newpass.footer[0].label': 'Save password',
  'auth_newpass.header.title': 'New password',
  'auth_merge.body[0].text': 'You’re signed in',
  'auth_merge.body[1].text': 'Upload the plan on this phone?',
  'auth_merge.body[2].rows[0].label': 'BreatheFree plan · this phone',
  'auth_merge.body[2].rows[0].sub': 'Quit date Aug 28 · 3 reasons',
  'auth_merge.body[3].text': 'Your account already has a BreatheFree plan from Aug 12.',
  'auth_merge.body[4].items[0].label': 'Keep both, choose later',
  'auth_merge.body[4].items[0].sub': 'Nothing is overwritten',
  'auth_merge.body[4].items[0].badge': 'Safest',
  'auth_merge.body[4].items[1].label': 'Use this phone’s plan',
  'auth_merge.body[4].items[2].label': 'Use the account’s plan',
  'auth_merge.footer[0].label': 'Continue',
  'auth_session.body[0].text': 'Please sign in again',
  'auth_session.body[1].text': 'For your security, sessions end after 30 days.',
  'auth_session.body[2].label': 'Password',
  'auth_session.body[2].placeholder': 'Password',
  'auth_session.footer[0].label': 'Sign in',
  'auth_session.footer[1].label': 'Use Face ID',
  'today.body[0].text': 'Friday, August 21',
  'today.body[1].text': 'Good morning, Alex.',
  'today.body[2].options[0]': 'All',
  'today.body[3].title': 'Craving or urge to scroll?',
  'today.body[3].text': 'Help for the next few minutes',
  'today.body[3].cta[0].label': 'Rescue',
  'today.body[4].eyebrow': 'Today · 2 small steps',
  'today.body[4].children[0].items[0].label': 'Stock gum, water or snacks',
  'today.body[4].children[0].items[0].sub': 'BreatheFree · 3 min',
  'today.body[4].children[0].items[1].label': 'Charge your phone outside the bedroom',
  'today.body[4].children[0].items[1].sub': 'ScrollFree · tonight',
  'today.body[5].eyebrow': 'Check-in · about 90 sec',
  'today.body[5].title': 'Covers both programs',
  'today.body[5].cta[0].label': 'Start',
  'today.body[6].items[0].label': 'Quit day',
  'today.body[6].items[0].value': '7 days',
  'today.body[6].items[0].sub': 'Fri, Aug 28',
  'today.body[6].items[1].label': 'Yesterday',
  'today.body[6].items[1].value': '2h 10m',
  'today.body[6].items[1].sub': 'goal 90 min',
  'today.body[7].rows[0].label': 'BreatheFree home',
  'today.body[7].rows[0].sub': 'Plan, medicines, progress',
  'today.body[7].rows[1].label': 'ScrollFree home',
  'today.body[7].rows[1].sub': 'Goal, Pause 60, week',
  'today.body[8].tagExtra': 'Learn only',
  'today.body[8].title': 'How your lungs recover after you quit',
  'today.body[8].text': '4 min read',
  'today.header.title': 'Today',
  'today_loading.body[1].title': 'Craving or urge?',
  'today_loading.body[1].text': 'One tap · no typing',
  'today_loading.body[1].cta[0].label': 'Rescue',
  'today_loading.body[4].text': 'The rest of Today is still loading.',
  'today_loading.header.title': 'Today',
  'today_offline.body[0].text': 'Offline · 3 entries will sync when you reconnect.',
  'today_offline.body[1].text': 'Good morning, Alex.',
  'today_offline.body[2].title': 'Craving or urge?',
  'today_offline.body[2].text': 'One tap · no typing',
  'today_offline.body[2].cta[0].label': 'Rescue',
  'today_offline.body[3].eyebrow': 'Today',
  'today_offline.body[3].children[0].items[0].label': 'Stock gum, water or snacks',
  'today_offline.body[3].children[0].items[0].sub': 'Saved on this phone',
  'today_offline.body[4].text': 'Lessons not downloaded load when you’re back online.',
  'today_offline.header.title': 'Today',
  'today_empty.body[0].text': 'Good evening, Alex.',
  'today_empty.body[2].text': 'Nothing in focus right now',
  'today_empty.body[3].text': 'Your programs are paused or in Learn only. Pick one for daily support, or keep exploring.',
  'today_empty.body[4].label': 'Choose a focus program',
  'today_empty.body[5].label': 'Browse lessons',
  'today_empty.body[6].title': 'Need help now?',
  'today_empty.body[6].text': 'Rescue and Support still work',
  'today_empty.body[6].cta[0].label': 'Support',
  'today_empty.header.title': 'Today',
  'today_safety.body[0].text': 'Your last blood pressure was in the crisis range.',
  'today_safety.body[1].title': 'Any chest pain, shortness of breath, weakness, vision change or trouble speaking?',
  'today_safety.body[1].text': 'Heartwise · from your 8:10 AM reading',
  'today_safety.body[1].children[0].items[0].label': 'Yes · call 911',
  'today_safety.body[1].children[0].items[1].label': 'No symptoms',
  'today_safety.body[2].text': 'Other steps are paused until you answer. Safety always comes first.',
  'today_safety.body[3].eyebrow': 'Today · paused',
  'today_safety.body[3].children[0].items[0].label': 'Stock gum, water or snacks',
  'today_safety.body[3].children[0].items[1].label': 'Charge phone outside the bedroom',
  'today_safety.header.title': 'Today',
  'checkin.body[0].text': 'Shared · asked once',
  'checkin.body[1].options[0]': 'Low',
  'checkin.body[1].options[1]': 'Not great',
  'checkin.body[1].options[2]': 'Okay',
  'checkin.body[1].options[3]': 'Good',
  'checkin.body[1].options[4]': 'Great',
  'checkin.body[1].label': 'How do you feel today?',
  'checkin.body[2].options[0]': 'Low',
  'checkin.body[2].options[1]': 'Some',
  'checkin.body[2].options[2]': 'High',
  'checkin.body[2].label': 'Stress today',
  'checkin.body[3].title': 'Since your last check-in, did you smoke?',
  'checkin.body[3].text': 'Before quit day this is expected, not a setback.',
  'checkin.body[3].children[0].options[0]': 'No',
  'checkin.body[3].children[0].options[1]': 'A puff',
  'checkin.body[3].children[0].options[2]': 'One or more',
  'checkin.body[3].children[0].options[3]': 'Skip',
  'checkin.body[4].title': 'How did you feel after scrolling yesterday?',
  'checkin.body[4].children[0].options[0]': 'Better',
  'checkin.body[4].children[0].options[1]': 'Same',
  'checkin.body[4].children[0].options[2]': 'Drained',
  'checkin.body[4].children[0].options[3]': 'Skip',
  'checkin.footer[0].label': 'Save check-in',
  'checkin.footer[1].text': 'Skip any program question',
  'checkin_done.body[1].text': 'Thanks, Alex.',
  'checkin_done.body[2].text': 'One small step for each program today.',
  'checkin_done.body[3].title': 'Try a 3-minute stress reset',
  'checkin_done.body[3].text': 'You reported high stress',
  'checkin_done.body[3].cta[0].label': 'Start',
  'checkin_done.body[4].title': 'Set a 10 PM wind-down',
  'checkin_done.body[4].text': 'You felt drained after scrolling',
  'checkin_done.body[4].cta[0].label': 'Set it',
  'checkin_done.body[5].text': 'Recommendations use only today’s answers · v1.0',
  'checkin_done.footer[0].label': 'Back to Today',
  'checkin_done.header.title': 'Check-in saved',
  'rescue_pick.body[0].text': 'Right now',
  'rescue_pick.body[1].text': 'What’s pulling at you?',
  'rescue_pick.body[2].text': 'One tap. No typing.',
  'rescue_pick.body[3].items[0].label': 'A cigarette',
  'rescue_pick.body[3].items[1].label': 'Urge to scroll',
  'rescue_pick.body[3].items[2].label': 'Stress',
  'rescue_pick.body[3].items[2].sub': 'Shared tool',
  'rescue_pick.body[3].items[3].label': 'Not sure',
  'rescue_pick.body[3].items[3].sub': 'We’ll suggest one',
  'rescue_pick.body[4].eyebrow': 'Helped last time · 6 → 3',
  'rescue_pick.body[4].title': 'Slow breathing · 2 min',
  'rescue_pick.body[4].cta[0].label': 'Start',
  'rescue_pick.body[5].items[0].label': 'Talk to a person',
  'rescue_pick.body[5].items[1].label': 'Emergency',
  'rescue_active.body[0].text': 'Breathe out · slowly',
  'rescue_active.body[2].text': 'The urge is a wave. Let it rise and pass.',
  'rescue_active.body[3].options[0]': 'Voice on',
  'rescue_active.body[3].options[1]': 'Haptics on',
  'rescue_active.body[3].options[2]': 'Reduced motion',
  'rescue_active.body[4].title': 'Still strong?',
  'rescue_active.body[4].text': 'Switch tool or reach a person. This check-in is kept.',
  'rescue_active.body[4].children[0].items[0].label': 'Switch tool',
  'rescue_active.body[4].children[0].items[1].label': 'Get support',
  'rescue_active.footer[0].label': 'I’m done',
  'rescue_active.header.title': 'Slow breathing',
  'rescue_active.header.pill': '1:32 left',
  'rescue_tools.body[0].text': 'Choose another tool',
  'rescue_tools.body[1].items[0].label': 'Slow breathing',
  'rescue_tools.body[1].items[0].sub': '2 min · voice optional',
  'rescue_tools.body[1].items[0].badge': 'Helped before',
  'rescue_tools.body[1].items[1].label': 'Move for 3 minutes',
  'rescue_tools.body[1].items[1].sub': 'Walk or stretch',
  'rescue_tools.body[1].items[2].label': 'Change the scene',
  'rescue_tools.body[1].items[2].sub': 'Go somewhere smoke-free',
  'rescue_tools.body[1].items[3].label': 'Urge surfing',
  'rescue_tools.body[1].items[3].sub': '3 min audio',
  'rescue_tools.footer[0].label': 'Start this tool',
  'rescue_tools.footer[1].label': 'Cancel',
  'rescue_result.body[0].text': 'This craving eased.',
  'rescue_result.body[1].label': 'How strong is it now?',
  'rescue_result.body[2].items[0].label': 'Before',
  'rescue_result.body[2].items[1].label': 'Now',
  'rescue_result.body[2].items[1].sub': 'Your rating, not a diagnosis',
  'rescue_result.body[3].options[0]': 'Yes',
  'rescue_result.body[3].options[1]': 'A little',
  'rescue_result.body[3].options[2]': 'Not this time',
  'rescue_result.body[3].label': 'Did it help?',
  'rescue_result.body[4].eyebrow': 'Next 10 minutes',
  'rescue_result.body[4].title': 'Stay somewhere smoke-free and sip water.',
  'rescue_result.body[5].label': 'Still strong? Get more help',
  'rescue_result.footer[0].label': 'Back to Today',
  'rescue_result.header.title': 'Rescue done',
  'rescue_result.header.pill': 'Saved',
  'rescue_escalate.body[0].text': 'Let’s add a person.',
  'rescue_escalate.body[1].text': 'Strong cravings are common in the first days. You don’t have to ride this one alone.',
  'rescue_escalate.body[2].eyebrow': 'Free & confidential',
  'rescue_escalate.body[2].title': 'Quitline counselor',
  'rescue_escalate.body[2].text': '1-800-QUIT-NOW · many states 24/7',
  'rescue_escalate.body[2].cta[0].label': 'Call',
  'rescue_escalate.body[3].rows[0].label': 'Text Jordan',
  'rescue_escalate.body[3].rows[0].sub': '“Can you stay with me for 10 minutes?”',
  'rescue_escalate.body[4].text': 'Thoughts of harming yourself? Call or text 988. Emergency: 911.',
  'rescue_escalate.body[4].actions[0].label': 'Call or text 988',
  'rescue_escalate.body[4].actions[1].label': 'Call 911',
  'rescue_escalate.footer[0].label': 'Try another tool',
  'rescue_escalate.header.title': 'Rescue',
  'crisis.body[0].text': 'If you might act on thoughts of harming yourself, get help now.',
  'crisis.body[1].label': 'Call 988',
  'crisis.body[2].label': 'Text 988',
  'crisis.body[3].label': 'Call 911',
  'crisis.body[4].eyebrow': 'Your safety plan',
  'crisis.body[4].title': 'Things that help: walk the dog, shower, music',
  'crisis.body[4].text': 'Reach out: Sam · (555) 010-3311',
  'crisis.header.title': 'You’re not alone',
  'plans.body[0].rows[0].sub': 'Quit date · Fri, Aug 28',
  'plans.body[0].rows[0].pill': 'Focus',
  'plans.body[0].rows[1].sub': '90 min/day · bedtime 10 PM–7 AM',
  'plans.body[0].rows[1].pill': 'Focus',
  'plans.body[0].title': 'Focus · 2 of 2',
  'plans.body[1].rows[0].sub': 'Learn only · no plan yet',
  'plans.body[1].rows[0].pill': 'Learn',
  'plans.body[1].title': 'Learn only',
  'plans.body[2].rows[0].label': 'Medication center',
  'plans.body[2].rows[0].sub': 'BreatheFree · nicotine patch',
  'plans.body[2].rows[1].label': 'Programs & sharing',
  'plans.body[2].rows[1].sub': 'Status, consent, data',
  'plans.body[2].title': 'Manage',
  'plans.footer[0].label': 'Add a program',
  'plans.header.title': 'My plans',
  'catalog.body[0].text': 'Choose what you want support with.',
  'catalog.body[1].rows[0].sub': 'Tobacco & nicotine · Quit / Reduce',
  'catalog.body[1].rows[1].sub': 'Social media use · Quit / Reduce',
  'catalog.body[1].rows[2].sub': 'Respiratory health · Manage',
  'catalog.body[1].rows[3].sub': 'Cardiovascular health · Manage',
  'catalog.body[1].rows[4].sub': 'Diabetes & metabolic health · Manage',
  'catalog.body[1].rows[5].sub': 'Kidney & liver health · Manage',
  'catalog.body[1].title': 'Quit · Manage',
  'catalog.body[2].rows[0].sub': 'Obesity & nutrition · Build habits',
  'catalog.body[2].rows[1].sub': 'Healthy aging · Build habits',
  'catalog.body[2].rows[2].sub': 'Mental & behavioral health · Support',
  'catalog.body[2].rows[3].sub': 'Preventive health · Prevent',
  'catalog.body[2].rows[4].sub': 'Cancer · Prevent',
  'catalog.body[2].title': 'Habits · Support · Prevent',
  'catalog.header.title': 'All programs',
  'focus_full.body[0].text': 'Both focus slots are in use',
  'focus_full.body[1].text': 'Add Heartwise as…',
  'focus_full.body[2].items[0].label': 'Learn only for now',
  'focus_full.body[2].items[0].sub': 'Lessons, no reminders. Upgrade anytime.',
  'focus_full.body[2].items[0].badge': 'Suggested',
  'focus_full.body[2].items[1].label': 'Swap with ScrollFree',
  'focus_full.body[2].items[1].sub': 'ScrollFree pauses. Its data is kept.',
  'focus_full.body[2].items[2].label': 'Swap with BreatheFree',
  'focus_full.body[2].items[2].sub': 'Not suggested during your quit week.',
  'focus_full.footer[0].action.cases[0].action.value': 'Heartwise added as Learn only',
  'focus_full.footer[0].label': 'Continue',
  'focus_full.footer[1].label': 'Cancel',
  'program_settings.body[0].rows[0].sub': 'Focus since Aug 14',
  'program_settings.body[1].items[0].label': 'Focus',
  'program_settings.body[1].items[0].sub': 'Daily steps and reminders',
  'program_settings.body[1].items[1].label': 'Learn only',
  'program_settings.body[1].items[1].sub': 'Keep lessons, stop tracking',
  'program_settings.body[1].items[2].label': 'Pause',
  'program_settings.body[1].items[2].sub': 'Stop reminders; keep everything',
  'program_settings.body[1].label': 'Status',
  'program_settings.body[2].eyebrow': 'Sharing',
  'program_settings.body[2].children[0].label': 'Care team · Dr. Patel’s clinic',
  'program_settings.body[2].children[0].sub': 'Manual: you approve each summary',
  'program_settings.body[2].children[1].label': 'De-identified research',
  'program_settings.body[3].rows[0].label': 'Export BreatheFree data',
  'program_settings.body[3].rows[0].sub': 'PDF + JSON',
  'program_settings.body[3].rows[0].action.value': 'Export is being prepared. We’ll notify you.',
  'program_settings.body[3].rows[1].label': 'Leave BreatheFree',
  'program_settings.body[3].rows[1].sub': 'Keep your data or delete it now',
  'program_settings.body[3].title': 'Data',
  'program_settings.footer[0].action.then.value': 'Saved',
  'program_settings.footer[0].label': 'Save changes',
  'program_settings.header.title': 'BreatheFree settings',
  'progress.body[0].options[0]': '7 days',
  'progress.body[0].options[1]': '30 days',
  'progress.body[0].options[2]': 'All',
  'progress.body[1].text': 'Patterns, not grades. Missing check-ins are never counted as zero.',
  'progress.body[2].title': 'Cigarettes / day',
  'progress.body[2].caption': 'Saved \$42.70 · avoided 61',
  'progress.body[2].labels[0]': 'M',
  'progress.body[2].labels[1]': 'T',
  'progress.body[2].labels[2]': 'W',
  'progress.body[2].labels[3]': 'T',
  'progress.body[2].labels[4]': 'F',
  'progress.body[2].labels[5]': 'S',
  'progress.body[2].labels[6]': 'S',
  'progress.body[3].title': 'Social minutes / day',
  'progress.body[3].caption': 'Goal 90 min · reclaimed 5h 40m',
  'progress.body[3].labels[0]': 'M',
  'progress.body[3].labels[1]': 'T',
  'progress.body[3].labels[2]': 'W',
  'progress.body[3].labels[3]': 'T',
  'progress.body[3].labels[4]': 'F',
  'progress.body[3].labels[5]': 'S',
  'progress.body[3].labels[6]': 'S',
  'progress.body[4].eyebrow': 'Connection we noticed',
  'progress.body[4].title': 'Late scrolling came before 3 of your 4 strongest cravings.',
  'progress.body[4].text': 'Shown because both programs are yours.',
  'progress.body[4].cta[0].label': 'Manage',
  'progress.header.title': 'Progress',
  'progress_empty.body[1].text': 'Your progress shows up here',
  'progress_empty.body[2].text': 'After your first check-in or reading, you’ll see patterns for each program.',
  'progress_empty.body[3].label': 'Do a check-in',
  'progress_empty.header.title': 'Progress',
  'progress_error.body[1].text': 'Something went wrong on our side',
  'progress_error.body[2].text': 'Your data is safe on this phone. Try again in a moment.',
  'progress_error.body[3].label': 'Try again',
  'progress_error.body[4].text': 'Reference 5xx-2F91 · reports never include health data',
  'progress_error.header.title': 'Progress',
  'learn.body[0].label': 'Search',
  'learn.body[0].placeholder': 'Search cravings, sleep, blood pressure…',
  'learn.body[1].options[0]': 'For you',
  'learn.body[2].tagExtra': 'For quit day',
  'learn.body[2].title': 'Cravings: what to expect today',
  'learn.body[2].text': '4 min read · 3:12 audio · downloaded',
  'learn.body[3].tagExtra': '2 min',
  'learn.body[3].title': 'Why “one more video” never feels like enough',
  'learn.body[4].tagExtra': 'Learn only',
  'learn.body[4].title': 'How your lungs recover after you quit',
  'learn.body[5].text': 'Clinically reviewed · Library v4.1 · English and Spanish',
  'learn.header.title': 'Learn',
  'learn_error.body[1].text': 'Can’t load lessons',
  'learn_error.body[2].text': 'Check your connection. Downloaded lessons still work.',
  'learn_error.body[3].label': 'Try again',
  'learn_error.body[4].label': 'Open downloads',
  'learn_error.header.title': 'Learn',
  'learn_lesson.body[0].extra': 'For quit day',
  'learn_lesson.body[1].text': 'Cravings: what to expect today',
  'learn_lesson.body[2].eyebrow': 'Audio · 3:12',
  'learn_lesson.body[2].title': 'Listen instead',
  'learn_lesson.body[2].children[0].items[0].action.value': 'Playing audio',
  'learn_lesson.body[2].children[0].items[0].label': 'Play',
  'learn_lesson.body[2].children[0].items[1].action.value': 'Transcript opened',
  'learn_lesson.body[2].children[0].items[1].label': 'Transcript',
  'learn_lesson.body[3].text': 'Most cravings peak and fade within 3–5 minutes. Knowing that makes them easier to ride out. Today, plan what you’ll do in the first 5 minutes of each craving.',
  'learn_lesson.body[4].text': 'This feeling will pass.',
  'learn_lesson.body[4].caption': 'From your plan',
  'learn_lesson.body[5].text': 'Clinically reviewed · content v3.2 · Aug 2026',
  'learn_lesson.footer[0].action.then.value': 'Lesson complete',
  'learn_lesson.footer[0].label': 'Mark complete',
  'learn_lesson.footer[1].label': 'Save for offline',
  'learn_lesson.footer[1].action.value': 'Saved for offline',
  'learn_lesson.header.title': 'Lesson',
  'learn_lesson.header.pill': '4 min',
  'support.body[0].eyebrow': 'Free & confidential · BreatheFree',
  'support.body[0].title': 'Quitline counselor',
  'support.body[0].text': '1-800-QUIT-NOW · Español 1-855-335-3569',
  'support.body[0].children[0].items[0].label': 'Call now',
  'support.body[0].children[0].items[1].label': 'Request call-back',
  'support.body[1].rows[0].label': 'Jordan',
  'support.body[1].rows[0].sub': 'Supporter · BreatheFree only',
  'support.body[1].rows[1].label': 'Add a ScrollFree buddy',
  'support.body[1].title': 'Your people',
  'support.body[2].rows[0].label': 'Dr. Patel’s clinic',
  'support.body[2].rows[0].sub': 'Heartwise · ClearAir',
  'support.body[2].title': 'Care team',
  'support.body[3].text': 'Thoughts of harming yourself? Call or text 988. Emergency: 911.',
  'support.body[3].actions[0].label': 'Call or text 988',
  'support.body[3].actions[1].label': 'Call 911',
  'support.header.title': 'Support',
  'support_empty.body[0].eyebrow': 'Free & confidential',
  'support_empty.body[0].title': 'Quitline counselor',
  'support_empty.body[0].cta[0].label': 'Call',
  'support_empty.body[1].eyebrow': 'Your people',
  'support_empty.body[1].title': 'No one added yet',
  'support_empty.body[1].text': 'A friend or family member gets a short help phrase from you, only when you choose to send it.',
  'support_empty.body[1].cta[0].label': 'Add',
  'support_empty.body[2].eyebrow': 'Care team',
  'support_empty.body[2].title': 'Not connected',
  'support_empty.body[2].text': 'Connect a clinic to share summaries you approve.',
  'support_empty.body[2].cta[0].label': 'Connect',
  'support_empty.body[3].text': 'Thoughts of harming yourself? Call or text 988. Emergency: 911.',
  'support_empty.body[3].actions[0].label': 'Call or text 988',
  'support_empty.body[3].actions[1].label': 'Call 911',
  'support_empty.header.title': 'Support',
  'support_callback.body[0].text': 'Request a counselor call-back?',
  'support_callback.body[1].text': 'Review exactly what will be sent before you agree.',
  'support_callback.body[2].rows[0][0]': 'Sent to',
  'support_callback.body[2].rows[0][1]': 'California Smokers’ Helpline',
  'support_callback.body[2].rows[1][0]': 'Shared',
  'support_callback.body[2].rows[1][1]': 'First name, phone, preferred time',
  'support_callback.body[2].rows[2][0]': 'Not shared',
  'support_callback.body[2].rows[2][1]': 'Your plan, check-ins, health details',
  'support_callback.body[2].rows[3][0]': 'Consent expires',
  'support_callback.body[2].rows[3][1]': '30 days',
  'support_callback.body[3].label': 'Best time to call',
  'support_callback.body[3].placeholder': 'Weekdays after 5 PM',
  'support_callback.footer[0].action.then.value': 'Request sent. Expect a call within 2 business days.',
  'support_callback.footer[0].label': 'Send referral',
  'support_callback.footer[1].label': 'Cancel',
  'support_message.body[0].text': 'Send to Jordan?',
  'support_message.body[1].eyebrow': 'Preview',
  'support_message.body[1].title': '“Can you stay with me for the next 10 minutes?”',
  'support_message.body[1].text': 'Sent from your phone’s Messages app. Tether never sends on its own.',
  'support_message.footer[0].label': 'Open Messages',
  'support_message.footer[1].label': 'Cancel',
  'support_message_care.body[0].text': 'Secure message · usually replies within 1 business day. Not for emergencies.',
  'support_message_care.body[1].label': 'Topic',
  'support_message_care.body[1].placeholder': 'Question about my plan',
  'support_message_care.body[2].label': 'Message',
  'support_message_care.body[2].placeholder': 'I’ve been feeling dizzy in the mornings since starting the patch.',
  'support_message_care.body[3].label': 'Attach a summary',
  'support_message_care.body[3].sub': 'You’ll preview it before sending',
  'support_message_care.body[4].text': 'Chest pain, trouble breathing or thoughts of harming yourself? Call 911 · call or text 988.',
  'support_message_care.body[4].actions[0].label': 'Call or text 988',
  'support_message_care.body[4].actions[1].label': 'Call 911',
  'support_message_care.footer[0].action.then.value': 'Message sent',
  'support_message_care.footer[0].label': 'Send message',
  'support_message_care.header.title': 'Dr. Patel’s clinic',
  'support_add_person.body[0].text': 'Who can you count on?',
  'support_add_person.body[1].label': 'Name',
  'support_add_person.body[1].placeholder': 'Jordan',
  'support_add_person.body[2].label': 'Phone',
  'support_add_person.body[3].label': 'Which programs?',
  'support_add_person.body[4].label': 'Help phrase',
  'support_add_person.body[4].placeholder': 'Can you stay with me for the next 10 minutes?',
  'support_add_person.body[5].text': 'Nothing is sent until you preview and tap Send.',
  'support_add_person.footer[0].action.cases[0].action.then.value': 'Jordan added',
  'support_add_person.footer[0].action.cases[1].action.value': 'Select at least one program.',
  'support_add_person.footer[0].label': 'Save supporter',
  'support_add_person.header.title': 'Add a supporter',
  'support_connect.body[0].text': 'Enter your clinic’s invite code',
  'support_connect.body[1].label': 'Invite code',
  'support_connect.body[1].placeholder': 'PATEL-4821',
  'support_connect.body[2].text': 'Your clinic gave you this code. Connecting shares nothing until you approve a summary.',
  'support_connect.footer[0].action.then.value': 'Connected to Dr. Patel’s clinic',
  'support_connect.footer[0].label': 'Connect',
  'support_connect.header.title': 'Connect a clinic',
  'account.body[0].rows[0].label': 'Alex',
  'account.body[0].rows[0].sub': 'alex@example.com',
  'account.body[1].rows[0].label': 'Health records',
  'account.body[1].rows[0].sub': '2 sources · Epic, Medicare',
  'account.body[1].rows[1].label': 'Sign-in methods',
  'account.body[1].rows[1].sub': 'Apple · email',
  'account.body[1].title': 'Your health data',
  'account.body[2].rows[0].label': 'Programs & sharing',
  'account.body[2].rows[0].sub': '2 focus · 1 learn · 1 paused',
  'account.body[2].rows[1].label': 'Notifications',
  'account.body[2].rows[1].sub': 'On · quiet hours 9 PM–7 AM',
  'account.body[2].rows[2].label': 'Privacy & consent',
  'account.body[2].rows[2].sub': 'Reviewed Aug 22, 2026',
  'account.body[2].rows[3].label': 'Your data',
  'account.body[2].rows[3].sub': 'Export or delete',
  'account.body[2].title': 'Settings',
  'account.body[3].rows[0].label': 'Text size & contrast',
  'account.body[3].rows[0].sub': 'Follows your phone',
  'account.body[3].rows[1].label': 'Language',
  'account.body[3].rows[1].sub': 'English',
  'account.body[3].rows[1].action.value': 'Language set to English',
  'account.body[3].rows[2].label': 'Help & legal',
  'account.body[3].title': 'App',
  'account.body[4].text': 'Tether Health 1.0.0 (100)',
  'account.footer[0].label': 'Sign out',
  'account.header.title': 'Account',
  'account_signin_methods.body[0].text': 'Use any connected method to sign in. Keep at least one.',
  'account_signin_methods.body[1].rows[0].sub': 'Connected · Hide My Email',
  'account_signin_methods.body[1].rows[0].pill': 'Primary',
  'account_signin_methods.body[1].rows[1].sub': 'Not connected',
  'account_signin_methods.body[1].rows[1].action.cases[0].action.value': 'Google connected',
  'account_signin_methods.body[1].rows[1].action.cases[2].action.value': 'Cancelled',
  'account_signin_methods.body[1].rows[2].label': 'Email & password',
  'account_signin_methods.body[1].rows[2].sub': 'alex@example.com · set a password',
  'account_signin_methods.body[2].text': 'To remove Apple, add another method first. Removing a method never deletes your data.',
  'account_signin_methods.header.title': 'Sign-in methods',
  'account_programs.body[0].text': '2 of 2 focus slots used',
  'account_programs.body[1].rows[0].sub': 'Focus · sharing manual',
  'account_programs.body[1].rows[1].sub': 'Focus · not shared',
  'account_programs.body[1].rows[2].sub': 'Learn only · no data',
  'account_programs.body[1].rows[3].sub': 'Paused Sep 2 · data kept',
  'account_programs.footer[0].label': 'Add a program',
  'account_programs.header.title': 'Programs & sharing',
  'account_leave.body[0].text': 'Leave BreatheFree?',
  'account_leave.body[1].text': 'Reminders stop right away. Your other programs are not affected.',
  'account_leave.body[2].items[0].label': 'Keep my data',
  'account_leave.body[2].items[0].sub': 'Kept until you delete it or delete your account. Rejoin anytime.',
  'account_leave.body[2].items[0].badge': 'Default',
  'account_leave.body[2].items[1].label': 'Delete BreatheFree data now',
  'account_leave.body[2].items[1].sub': '63 check-ins, 14 rescues, 1 plan',
  'account_leave.footer[0].action.then.value': 'You left BreatheFree',
  'account_leave.footer[0].label': 'Leave BreatheFree',
  'account_leave.footer[1].label': 'Cancel',
  'account_notifications.body[0].children[0].label': 'Check-ins and plan reminders',
  'account_notifications.body[0].children[0].sub': 'At most 2 a day',
  'account_notifications.body[0].children[1].label': 'Show sensitive details',
  'account_notifications.body[0].children[1].sub': 'Off: program names and health data hidden',
  'account_notifications.body[0].children[2].label': 'Quiet hours',
  'account_notifications.body[0].children[2].sub': '9:00 PM – 7:00 AM · safety alerts still come through',
  'account_notifications.body[1].rows[0].sub': '8:00 AM check-in',
  'account_notifications.body[1].rows[0].action.value': 'Reminder time saved',
  'account_notifications.body[1].rows[1].sub': '9:30 PM wind-down',
  'account_notifications.body[1].rows[1].action.value': 'Reminder time saved',
  'account_notifications.body[1].title': 'Per program',
  'account_notifications.body[2].eyebrow': 'Lock screen preview',
  'account_notifications.body[2].text': 'You have a Tether reminder.',
  'account_notifications.footer[0].action.then.value': 'Saved',
  'account_notifications.footer[0].label': 'Save',
  'account_notifications.header.title': 'Notifications',
  'account_privacy.body[0].eyebrow': 'Choices',
  'account_privacy.body[0].children[0].label': 'Cross-program insights',
  'account_privacy.body[0].children[0].sub': 'Show connections between your programs',
  'account_privacy.body[0].children[1].label': 'De-identified research',
  'account_privacy.body[0].children[1].sub': 'Per program, off by default',
  'account_privacy.body[0].children[2].label': 'Anonymous app diagnostics',
  'account_privacy.body[0].children[2].sub': 'No health entries',
  'account_privacy.body[1].rows[0].label': 'Care-team sharing',
  'account_privacy.body[1].rows[0].sub': 'Manual only · preview every share',
  'account_privacy.body[1].rows[1].label': 'Consent history',
  'account_privacy.body[1].rows[1].sub': 'v3 · Aug 22, 2026',
  'account_privacy.body[1].rows[1].action.value': 'Consent history opened',
  'account_privacy.body[1].rows[2].label': 'Privacy Notice',
  'account_privacy.body[2].text': 'No ads. We never sell your health data.',
  'account_privacy.footer[0].action.then.value': 'Saved',
  'account_privacy.footer[0].label': 'Save',
  'account_privacy.header.title': 'Privacy & consent',
  'account_data.body[0].rows[0].label': 'Download everything',
  'account_data.body[0].rows[0].sub': 'Every program · PDF + JSON',
  'account_data.body[0].rows[0].action.then.value': 'We’re preparing your file. We’ll notify you when it’s ready.',
  'account_data.body[0].rows[1].label': 'Export a care summary',
  'account_data.body[0].rows[1].sub': 'Choose dates and preview every detail',
  'account_data.body[0].title': 'Export',
  'account_data.body[1].rows[0].label': 'Delete account and all data',
  'account_data.body[1].rows[0].sub': 'Permanent · requires confirmation',
  'account_data.body[1].title': 'Delete',
  'account_data.header.title': 'Your data',
  'account_delete.body[0].text': 'Delete your account and all data?',
  'account_delete.body[1].rows[0][0]': 'Programs',
  'account_delete.body[1].rows[1][0]': 'Check-ins',
  'account_delete.body[1].rows[2][0]': 'Readings & logs',
  'account_delete.body[1].rows[3][0]': 'Shared with care team',
  'account_delete.body[1].rows[3][1]': '3 summaries (their copies stay with them)',
  'account_delete.body[2].text': 'This can’t be undone. Download a copy first if you want one.',
  'account_delete.body[3].label': 'Download a copy first',
  'account_delete.body[4].label': 'Type DELETE to confirm',
  'account_delete.body[4].placeholder': 'DELETE',
  'account_delete.body[5].label': 'Password',
  'account_delete.body[5].hint': 'We ask again to protect your account.',
  'account_delete.footer[0].label': 'Delete everything',
  'account_delete.header.title': 'Delete account',
  'account_deleted.body[1].text': 'Your data has been deleted.',
  'account_deleted.body[2].rows[0][0]': 'Receipt',
  'account_deleted.body[2].rows[0][1]': 'DEL-7F3A-21C9',
  'account_deleted.body[2].rows[1][0]': 'Completed',
  'account_deleted.body[2].rows[1][1]': 'Oct 17, 2026 · 9:41 AM',
  'account_deleted.body[2].rows[2][0]': 'Signed out on',
  'account_deleted.body[2].rows[2][1]': 'this phone',
  'account_deleted.body[3].text': 'Keep this receipt if you contact support. Backups are purged within 30 days.',
  'account_deleted.footer[0].label': 'Done',
  'account_deleted.header.title': 'Deleted',
  'account_signout.body[0].text': 'Sign out of Tether?',
  'account_signout.body[1].text': 'Encrypted program data on this phone is removed. Your account data stays safe in the cloud.',
  'account_signout.footer[0].label': 'Sign out',
  'account_signout.footer[1].label': 'Cancel',
  'sys_update.body[1].text': 'A safety update is ready',
  'sys_update.body[2].text': 'This version has important fixes. Rescue and Support still work until you update.',
  'sys_update.footer[0].label': 'Update now',
  'sys_update.footer[1].label': 'Open Rescue',
  'sys_update.header.title': 'Update needed',
  'bf_intro.body[0].extra': 'Tobacco & nicotine',
  'bf_intro.body[1].text': 'Your next breath can be different.',
  'bf_intro.body[2].rows[0][0]': 'Help when cravings hit',
  'bf_intro.body[2].rows[0][1]': 'one tap, no typing',
  'bf_intro.body[2].rows[1][0]': 'Plan your way',
  'bf_intro.body[2].rows[1][1]': 'date · today · reduce · explore',
  'bf_intro.body[2].rows[2][0]': 'Medicines',
  'bf_intro.body[2].rows[2][1]': 'education only',
  'bf_intro.body[3].text': 'Plan, practice and get through cravings, with no judgment. A slip never erases your wins.',
  'bf_intro.footer[0].label': 'Set up BreatheFree',
  'bf_intro.footer[1].action.then.value': 'BreatheFree added as Learn only',
  'bf_intro.footer[1].label': 'Add as Learn only',
  'bf_intro.header.pill': '~3 min/day',
  'bf_q1.body[1].text': 'Question 1 of 3',
  'bf_q1.body[2].text': 'On a typical day, how many cigarettes?',
  'bf_q1.body[3].items[0].label': 'I don’t smoke every day',
  'bf_q1.body[3].items[1].label': '10 or fewer',
  'bf_q1.body[3].items[4].label': '31 or more',
  'bf_q1.body[4].title': 'Why we ask',
  'bf_q1.body[4].text': 'Tailors your plan and estimates money saved. Not a diagnosis.',
  'bf_q1.footer[0].label': 'Next',
  'bf_q1.header.title': 'About your smoking',
  'bf_q1.header.pill': '1 of 3',
  'bf_q2.body[1].text': 'Choose all that apply',
  'bf_q2.body[2].text': 'When do you most want a cigarette?',
  'bf_q2.body[3].options[0]': 'Stress',
  'bf_q2.body[3].options[1]': 'After meals',
  'bf_q2.body[3].options[2]': 'Driving',
  'bf_q2.body[3].options[3]': 'With coffee',
  'bf_q2.body[3].options[4]': 'Social',
  'bf_q2.body[3].options[5]': 'Work breaks',
  'bf_q2.body[3].options[6]': 'Alcohol',
  'bf_q2.body[3].options[7]': 'Boredom',
  'bf_q2.body[3].options[8]': 'Morning',
  'bf_q2.body[3].options[9]': 'Scrolling',
  'bf_q2.body[4].label': 'Add your own',
  'bf_q2.body[4].placeholder': 'Type another situation…',
  'bf_q2.body[5].text': 'Used to prepare, never to monitor. No background location.',
  'bf_q2.footer[0].label': 'Next',
  'bf_q2.header.title': 'Your triggers',
  'bf_q2.header.pill': '2 of 3',
  'bf_q3.body[1].text': 'What are you quitting for?',
  'bf_q3.body[2].text': 'Choose all that matter. Your top reason appears when a craving hits.',
  'bf_q3.body[3].options[0]': 'Protect my family',
  'bf_q3.body[3].options[1]': 'Breathe easier',
  'bf_q3.body[3].options[2]': 'Save money',
  'bf_q3.body[3].options[3]': 'Feel in control',
  'bf_q3.body[3].options[4]': 'My health',
  'bf_q3.body[3].options[5]': 'Be there for my future',
  'bf_q3.body[4].eyebrow': 'When a craving hits',
  'bf_q3.body[4].children[0].text': 'You chose this for your family. This feeling will pass.',
  'bf_q3.footer[0].label': 'Save my reasons',
  'bf_q3.header.title': 'Your reasons',
  'bf_q3.header.pill': '3 of 3',
  'bf_path.body[0].text': 'What feels possible right now?',
  'bf_path.body[1].text': 'There’s no wrong place to start.',
  'bf_path.body[2].items[0].label': 'Set a quit date',
  'bf_path.body[2].items[0].sub': 'Prepare 7–14 days, then stop',
  'bf_path.body[2].items[0].badge': 'Recommended',
  'bf_path.body[2].items[1].label': 'Quit today',
  'bf_path.body[2].items[1].sub': 'Skip the calendar; extra support now',
  'bf_path.body[2].items[2].label': 'Reduce gradually',
  'bf_path.body[2].items[2].sub': 'Step down to zero over 4 weeks',
  'bf_path.body[2].items[3].label': 'Explore first',
  'bf_path.body[2].items[3].sub': 'No date. Lessons and Rescue only',
  'bf_path.body[3].title': 'Talk to a person first?',
  'bf_path.body[3].text': 'Quitline counselor or your care team',
  'bf_path.footer[0].label': 'Continue with this path',
  'bf_path.header.title': 'Your path',
  'bf_path.header.pill': 'Plan 1 of 3',
  'bf_date.body[0].text': 'Choose a day to begin.',
  'bf_date.body[1].text': '7–14 days away gives you time to prepare without losing momentum.',
  'bf_date.body[2].month': 'August 2026',
  'bf_date.body[3].eyebrow': 'Your quit date',
  'bf_date.body[3].title': 'Friday, August 28, 2026',
  'bf_date.body[3].text': '7 days to prepare · Pacific Time',
  'bf_date.body[4].label': 'Quit-day check-in at 7:00 AM',
  'bf_date.body[4].sub': 'Lock screen: “You have a Tether reminder.”',
  'bf_date.footer[0].label': 'Confirm this date',
  'bf_date.header.title': 'Quit date',
  'bf_date.header.pill': 'Plan 2 of 3',
  'bf_stepdown.body[0].text': 'Cut back at your pace.',
  'bf_stepdown.body[1].text': 'From your baseline of 15 a day. Adjust any week.',
  'bf_stepdown.body[2].rows[0][0]': 'This week',
  'bf_stepdown.body[2].rows[0][1]': '15 → 12 a day',
  'bf_stepdown.body[2].rows[1][0]': 'Week 2',
  'bf_stepdown.body[2].rows[1][1]': '9 a day',
  'bf_stepdown.body[2].rows[2][0]': 'Week 3',
  'bf_stepdown.body[2].rows[2][1]': '5 a day',
  'bf_stepdown.body[2].rows[3][0]': 'Week 4',
  'bf_stepdown.body[2].rows[3][1]': '2 a day',
  'bf_stepdown.body[2].rows[4][0]': 'Quit day · Sep 18',
  'bf_stepdown.body[3].text': 'Reducing works best paired with a quit date. Ask your clinician about nicotine replacement while cutting down.',
  'bf_stepdown.footer[0].label': 'Save schedule',
  'bf_stepdown.header.title': 'Step-down schedule',
  'bf_stepdown.header.pill': 'Plan 2 of 3',
  'bf_support.body[0].text': 'You don’t have to do this alone.',
  'bf_support.body[1].rows[0].label': 'Jordan',
  'bf_support.body[1].rows[0].sub': 'Friend · text message · evening before',
  'bf_support.body[1].rows[1].label': 'Add a supporter',
  'bf_support.body[1].title': 'Your support circle',
  'bf_support.body[2].eyebrow': 'Prepare your space · 2 of 3',
  'bf_support.body[2].children[0].items[0].label': 'Remove cigarettes, lighters, ashtrays',
  'bf_support.body[2].children[0].items[1].label': 'Make home and car smoke-free',
  'bf_support.body[2].children[0].items[2].label': 'Stock gum, water or snacks',
  'bf_support.body[3].label': 'Remind me to discuss quit medicines with my care team',
  'bf_support.body[3].sub': 'Education only. The app never prescribes.',
  'bf_support.footer[0].label': 'Review my plan',
  'bf_support.header.title': 'Support',
  'bf_support.header.pill': 'Plan 3 of 3',
  'bf_review.body[0].text': 'Your plan is ready.',
  'bf_review.body[1].text': 'Tap any item to edit.',
  'bf_review.body[2].rows[0].label': 'Quit approach',
  'bf_review.body[2].rows[0].sub': 'Set a quit date',
  'bf_review.body[2].rows[1].label': 'Quit date',
  'bf_review.body[2].rows[1].sub': 'Fri, Aug 28 · 7 days to prepare',
  'bf_review.body[2].rows[2].label': 'Top reason',
  'bf_review.body[2].rows[2].sub': 'Protect my family',
  'bf_review.body[2].rows[3].label': 'Support',
  'bf_review.body[2].rows[3].sub': 'Jordan · evening before',
  'bf_review.body[2].rows[4].label': 'Space',
  'bf_review.body[2].rows[4].sub': '2 of 3 tasks done',
  'bf_review.body[3].text': 'Starting turns on your preparation tasks and reminders. Support messages always need your approval.',
  'bf_review.footer[0].label': 'Start my plan',
  'bf_review.footer[1].label': 'Save and finish later',
  'bf_review.header.title': 'Review your plan',
  'bf_review.header.pill': 'Ready',
  'bf_home.body[0].eyebrow': 'Your quit day',
  'bf_home.body[0].children[0].value': '7 days',
  'bf_home.body[0].children[0].caption': 'Friday, August 28 · Pacific Time',
  'bf_home.body[1].title': 'Craving now?',
  'bf_home.body[1].text': 'One tap · no typing',
  'bf_home.body[1].cta[0].label': 'Rescue',
  'bf_home.body[2].eyebrow': 'Today’s step',
  'bf_home.body[2].children[0].items[0].label': 'Stock gum, water or healthy snacks',
  'bf_home.body[2].children[0].items[0].sub': 'About 3 minutes',
  'bf_home.body[3].eyebrow': 'Your top reason',
  'bf_home.body[3].children[0].text': 'Protect my family.',
  'bf_home.body[4].rows[0].label': 'Daily check-in',
  'bf_home.body[4].rows[0].sub': 'About 60 seconds',
  'bf_home.body[4].rows[1].label': 'Medication center',
  'bf_home.body[4].rows[1].sub': 'Nicotine patch · recorded plan',
  'bf_home.body[4].rows[2].label': 'Progress',
  'bf_home.body[4].rows[2].sub': 'Saved \$42.70 so far',
  'bf_home.body[4].rows[3].label': 'Edit my plan',
  'bf_home.body[4].rows[4].label': 'Program settings',
  'bf_home.body[4].rows[4].sub': 'Status, sharing, export, leave',
  'bf_home_quitday.body[0].text': 'Quit day · Aug 28',
  'bf_home_quitday.body[1].text': 'Keep today simple.',
  'bf_home_quitday.body[2].eyebrow': 'Since your quit time',
  'bf_home_quitday.body[2].children[0].value': '2h 41m',
  'bf_home_quitday.body[2].children[0].caption': 'Started 7:00 AM · Pacific',
  'bf_home_quitday.body[3].title': 'I have a craving',
  'bf_home_quitday.body[3].text': 'One tap · no typing',
  'bf_home_quitday.body[3].cta[0].label': 'Rescue',
  'bf_home_quitday.body[4].title': 'I smoked or had a slip',
  'bf_home_quitday.body[4].text': 'Your progress will not be erased',
  'bf_home_quitday.body[5].eyebrow': 'Next best step',
  'bf_home_quitday.body[5].children[0].items[0].label': 'Water, then a 5-minute walk',
  'bf_home_quitday.body[5].children[0].items[0].sub': 'From your trigger plan',
  'bf_home_quitday.body[6].rows[0].label': 'Morning check-in',
  'bf_home_quitday.body[6].rows[1].label': 'Medication center',
  'bf_home_quitday.body[6].rows[1].sub': 'Patch · taken 8:07 AM',
  'bf_home_explore.body[0].text': 'Exploring · no date set',
  'bf_home_explore.body[1].text': 'Learn at your own pace.',
  'bf_home_explore.body[2].title': 'Craving now?',
  'bf_home_explore.body[2].text': 'Rescue works without a plan',
  'bf_home_explore.body[2].cta[0].label': 'Rescue',
  'bf_home_explore.body[3].title': 'Cravings: what to expect',
  'bf_home_explore.body[3].text': '4 min read',
  'bf_home_explore.body[4].title': 'What quit medicines can do',
  'bf_home_explore.body[4].text': 'Education only · 5 min',
  'bf_home_explore.body[5].title': 'Ready when you are',
  'bf_home_explore.body[5].text': 'Setting a date takes 2 minutes.',
  'bf_home_explore.body[5].cta[0].label': 'Choose a path',
  'bf_slip.body[0].text': 'Your progress is still here',
  'bf_slip.body[1].text': 'A slip is information, not the end.',
  'bf_slip.body[2].rows[0][0]': 'Smoke-free days so far',
  'bf_slip.body[2].rows[0][1]': '6 of 7 · kept',
  'bf_slip.body[3].options[0]': 'A puff or two',
  'bf_slip.body[3].options[1]': 'One cigarette',
  'bf_slip.body[3].options[2]': 'More',
  'bf_slip.body[3].options[3]': 'Prefer not to say',
  'bf_slip.body[3].label': 'What happened?',
  'bf_slip.body[4].options[0]': 'Stress',
  'bf_slip.body[4].options[1]': 'Around smokers',
  'bf_slip.body[4].options[2]': 'Alcohol',
  'bf_slip.body[4].options[3]': 'Scrolling late',
  'bf_slip.body[4].label': 'What was going on? (optional)',
  'bf_slip.body[5].items[0].label': 'Continue from this moment',
  'bf_slip.body[5].items[0].sub': 'Keep your plan',
  'bf_slip.body[5].items[0].badge': 'Recommended',
  'bf_slip.body[5].items[1].label': 'Choose a new quit time',
  'bf_slip.footer[0].label': 'Save and start a 2-min Rescue',
  'bf_slip.footer[1].label': 'Skip for now',
  'bf_slip.header.title': 'Slip recovery',
  'bf_slip.header.pill': 'Private',
  'bf_meds.body[0].text': 'Education and tracking, not prescribing. The app never selects a medicine or changes a dose.',
  'bf_meds.body[1].eyebrow': 'Your recorded plan',
  'bf_meds.body[1].title': 'Nicotine patch · morning',
  'bf_meds.body[1].text': 'Entered by you · follow your clinician’s instructions',
  'bf_meds.body[1].children[0].items[0].action.value': 'Recorded: taken at 8:07 AM',
  'bf_meds.body[1].children[0].items[0].label': 'Taken today',
  'bf_meds.body[1].children[0].items[1].action.value': 'Recorded: not taken',
  'bf_meds.body[1].children[0].items[1].label': 'Not today',
  'bf_meds.body[2].rows[0].label': 'Nicotine replacement',
  'bf_meds.body[2].rows[0].sub': 'Patch, gum, lozenge',
  'bf_meds.body[2].rows[1].label': 'Prescription options',
  'bf_meds.body[2].rows[1].sub': 'Varenicline · bupropion SR',
  'bf_meds.body[2].title': 'Learn',
  'bf_meds.body[3].title': 'Pregnant, breastfeeding or under 18?',
  'bf_meds.body[3].text': 'Talk with a doctor before using quit medicines.',
  'bf_meds.body[4].title': 'Side effect or worrying symptom?',
  'bf_meds.body[4].text': 'Contact your care team or pharmacist. Emergency: 911.',
  'bf_meds.footer[0].label': 'Add or update recorded plan',
  'bf_meds.header.title': 'Medication center',
  'bf_meds_edit.body[0].text': 'Record the plan from your clinician',
  'bf_meds_edit.body[1].label': 'Medicine',
  'bf_meds_edit.body[1].placeholder': 'Nicotine patch',
  'bf_meds_edit.body[2].label': 'Strength',
  'bf_meds_edit.body[2].placeholder': '21 mg / 24 h',
  'bf_meds_edit.body[3].label': 'When',
  'bf_meds_edit.body[3].placeholder': 'Every morning',
  'bf_meds_edit.body[4].label': 'Private reminder',
  'bf_meds_edit.body[4].sub': 'Lock screen hides the medicine name',
  'bf_meds_edit.body[5].text': 'You’re recording, not changing, your plan. Ask your clinician about any change.',
  'bf_meds_edit.footer[0].action.then.value': 'Plan saved',
  'bf_meds_edit.footer[0].label': 'Save plan',
  'bf_meds_edit.header.title': 'Recorded plan',
  'bf_progress.body[0].options[0]': '7 days',
  'bf_progress.body[0].options[1]': '30 days',
  'bf_progress.body[0].options[2]': 'All',
  'bf_progress.body[1].title': 'Cigarettes / day',
  'bf_progress.body[1].caption': 'Thursday: no check-in · not counted as zero',
  'bf_progress.body[1].labels[0]': 'M',
  'bf_progress.body[1].labels[1]': 'T',
  'bf_progress.body[1].labels[2]': 'W',
  'bf_progress.body[1].labels[3]': 'T',
  'bf_progress.body[1].labels[4]': 'F',
  'bf_progress.body[1].labels[5]': 'S',
  'bf_progress.body[1].labels[6]': 'S',
  'bf_progress.body[2].items[0].label': 'Est. avoided',
  'bf_progress.body[2].items[0].sub': 'cigarettes',
  'bf_progress.body[2].items[1].label': 'Est. saved',
  'bf_progress.body[2].items[1].sub': '\$14 per pack',
  'bf_progress.body[2].items[2].label': 'Cravings eased',
  'bf_progress.body[2].items[2].value': '4 of 6',
  'bf_progress.body[2].items[2].sub': 'after a tool',
  'bf_progress.body[2].items[3].label': 'Most helpful',
  'bf_progress.body[2].items[3].value': 'Breathing',
  'bf_progress.body[2].items[3].sub': '3 of 4 times',
  'bf_progress.body[3].rows[0].label': 'How estimates work',
  'bf_progress.body[3].rows[0].sub': '10/day · \$14/pack · 5 min each',
  'bf_progress.header.title': 'Progress',
  'bf_estimates.body[0].text': 'How estimates are calculated',
  'bf_estimates.body[1].rows[0][0]': 'Baseline',
  'bf_estimates.body[1].rows[0][1]': '10 cigarettes a day',
  'bf_estimates.body[1].rows[1][0]': 'Price',
  'bf_estimates.body[1].rows[1][1]': '\$14.00 per pack',
  'bf_estimates.body[1].rows[2][0]': 'Time per cigarette',
  'bf_estimates.body[1].rows[2][1]': '5 minutes',
  'bf_estimates.body[1].rows[3][0]': 'Avoided',
  'bf_estimates.body[1].rows[3][1]': 'baseline − reported',
  'bf_estimates.body[2].text': 'Estimates, not measurements. Missing days are left out.',
  'bf_estimates.footer[0].action.value': 'Opened baseline settings',
  'bf_estimates.footer[0].label': 'Edit numbers',
  'bf_estimates.footer[1].label': 'Done',
  'sf_intro.body[0].extra': 'Social media use',
  'sf_intro.body[1].text': 'Your attention is yours.',
  'sf_intro.body[2].rows[0][0]': 'Goal',
  'sf_intro.body[2].rows[0][1]': 'minutes a day + app-free times',
  'sf_intro.body[2].rows[1][0]': 'Pause 60',
  'sf_intro.body[2].rows[1][1]': 'intent check, not a lock',
  'sf_intro.body[2].rows[2][0]': 'Never',
  'sf_intro.body[2].rows[2][1]': 'reads messages or feeds',
  'sf_intro.body[3].text': 'Notice what pulls you in, set a goal that feels doable, and pause for 60 seconds when the urge hits.',
  'sf_intro.footer[0].label': 'Set up ScrollFree',
  'sf_intro.footer[1].action.then.value': 'ScrollFree added as Learn only',
  'sf_intro.footer[1].label': 'Add as Learn only',
  'sf_intro.header.pill': '~1 min/day',
  'sf_q1.body[1].text': 'On a typical day, how long on social apps?',
  'sf_q1.body[2].text': 'A rough guess is fine.',
  'sf_q1.body[3].items[0].label': 'Less than 1 hour',
  'sf_q1.body[3].items[1].label': '1–2 hours',
  'sf_q1.body[3].items[2].label': '3–4 hours',
  'sf_q1.body[3].items[3].label': '5+ hours',
  'sf_q1.body[4].options[0]': 'Short video',
  'sf_q1.body[4].options[1]': 'Feeds',
  'sf_q1.body[4].options[2]': 'Messaging',
  'sf_q1.body[4].options[3]': 'Games',
  'sf_q1.body[4].options[4]': 'News',
  'sf_q1.body[4].label': 'Which pull hardest? (categories only)',
  'sf_q1.footer[0].label': 'Next',
  'sf_q1.header.title': 'About your use',
  'sf_q1.header.pill': '1 of 2',
  'sf_q2.body[1].text': 'When do you reach for it?',
  'sf_q2.body[2].options[0]': 'Bored',
  'sf_q2.body[2].options[1]': 'Lonely',
  'sf_q2.body[2].options[2]': 'In bed',
  'sf_q2.body[2].options[3]': 'Avoiding work',
  'sf_q2.body[2].options[4]': 'After conflict',
  'sf_q2.body[2].options[5]': 'Waiting',
  'sf_q2.body[2].options[6]': 'Can’t sleep',
  'sf_q2.body[2].options[7]': 'First thing',
  'sf_q2.body[3].options[0]': 'Better',
  'sf_q2.body[3].options[1]': 'Same',
  'sf_q2.body[3].options[2]': 'Worse',
  'sf_q2.body[3].label': 'How do you usually feel after?',
  'sf_q2.body[4].text': 'Used for your plan only. ScrollFree never reads what you look at.',
  'sf_q2.footer[0].label': 'Next',
  'sf_q2.header.title': 'Your triggers',
  'sf_q2.header.pill': '2 of 2',
  'sf_goal.body[0].text': 'Set a goal that feels doable.',
  'sf_goal.body[1].text': 'From about 3 hours a day.',
  'sf_goal.body[2].children[0].label': 'Daily social time',
  'sf_goal.body[2].children[0].minLabel': '30 min',
  'sf_goal.body[2].children[0].maxLabel': '4 h',
  'sf_goal.body[2].children[1].label': 'Step down 15 min each week',
  'sf_goal.body[3].eyebrow': 'App-free times',
  'sf_goal.body[3].children[0].items[0].label': 'Bedtime',
  'sf_goal.body[3].children[0].items[0].sub': '10:00 PM – 7:00 AM',
  'sf_goal.body[3].children[0].items[1].label': 'Meals',
  'sf_goal.body[3].children[0].items[1].sub': 'When you mark a meal',
  'sf_goal.body[3].children[0].items[2].label': 'First hour awake',
  'sf_goal.body[4].rows[0].label': 'Connect Screen Time',
  'sf_goal.body[4].rows[0].sub': 'Optional · totals only',
  'sf_goal.footer[0].label': 'Save my goal',
  'sf_goal.header.title': 'Your goal',
  'sf_goal.header.pill': 'Plan',
  'sf_screentime.body[1].text': 'See your Screen Time here, if you want.',
  'sf_screentime.body[2].text': 'Apple’s Screen Time shows your daily totals by category inside Tether. Tether can’t read, store or share those minutes.',
  'sf_screentime.body[3].rows[0][0]': 'Shows',
  'sf_screentime.body[3].rows[0][1]': 'Minutes per category, on this phone',
  'sf_screentime.body[3].rows[1][0]': 'Never reads',
  'sf_screentime.body[3].rows[1][1]': 'Content, messages, contacts',
  'sf_screentime.body[3].rows[2][0]': 'Turn off',
  'sf_screentime.body[3].rows[2][1]': 'Anytime in Account',
  'sf_screentime.footer[0].action.cases[0].action.value': 'Screen Time connected',
  'sf_screentime.footer[0].label': 'Allow access',
  'sf_screentime.footer[1].label': 'Not now',
  'sf_screentime.header.title': 'Screen Time',
  'sf_screentime.header.pill': 'Optional',
  'sf_screentime_denied.body[0].text': 'Screen Time access was not allowed.',
  'sf_screentime_denied.body[1].text': 'Self-report works just as well.',
  'sf_screentime_denied.body[2].text': 'We’ll ask for a quick estimate in your evening check-in. You can connect later in Account → ScrollFree.',
  'sf_screentime_denied.footer[0].label': 'Continue with self-report',
  'sf_screentime_denied.footer[1].label': 'Open phone settings',
  'sf_screentime_denied.header.title': 'Screen Time',
  'sf_screentime_denied.header.pill': 'Optional',
  'sf_buddy.body[0].text': 'Want someone in your corner?',
  'sf_buddy.body[1].text': 'Your buddy only sees what you choose to send.',
  'sf_buddy.body[2].label': 'Name',
  'sf_buddy.body[2].placeholder': 'Sam',
  'sf_buddy.body[3].items[0].label': 'A weekly “I hit my goal” message',
  'sf_buddy.body[3].items[1].label': 'My minutes per day',
  'sf_buddy.body[3].items[2].label': 'Nothing automatic: I send each one',
  'sf_buddy.body[3].label': 'They can see',
  'sf_buddy.body[4].eyebrow': 'Preview',
  'sf_buddy.body[4].children[0].text': 'Phone-free nights this week: 5. Thanks for cheering me on!',
  'sf_buddy.footer[0].label': 'Save and finish',
  'sf_buddy.footer[1].label': 'Skip for now',
  'sf_buddy.header.title': 'Buddy',
  'sf_buddy.header.pill': 'Optional',
  'sf_home.body[0].eyebrow': 'Yesterday',
  'sf_home.body[0].children[0].value': '2h 10m',
  'sf_home.body[0].children[0].caption': 'Goal 90 min · down from 3h',
  'sf_home.body[1].title': 'Urge to scroll?',
  'sf_home.body[1].text': 'Take 60 seconds first',
  'sf_home.body[1].cta[0].label': 'Pause 60',
  'sf_home.body[2].title': 'Want firmer limits?',
  'sf_home.body[2].text': 'Unplug can pause apps you choose, after limits you set. Optional.',
  'sf_home.body[2].cta[0].label': 'Set up',
  'sf_home.body[3].eyebrow': 'Today’s step',
  'sf_home.body[3].children[0].items[0].label': 'Charge your phone outside the bedroom',
  'sf_home.body[3].children[0].items[0].sub': 'Tonight · bedtime window 10 PM',
  'sf_home.body[4].rows[0].label': 'This week',
  'sf_home.body[4].rows[0].sub': '5 of 7 phone-free nights',
  'sf_home.body[4].rows[1].label': 'Had a long scroll?',
  'sf_home.body[4].rows[1].sub': 'Reflect, nothing resets',
  'sf_home.body[4].rows[2].label': 'Goal & windows',
  'sf_home.body[4].rows[2].sub': '90 min · bedtime',
  'sf_home.body[4].rows[3].label': 'Buddy',
  'sf_home.body[4].rows[3].sub': 'Sam · weekly message',
  'sf_home.body[4].rows[4].label': 'Program settings',
  'sf_home.body[4].rows[4].sub': 'Status, sharing, export, leave',
  'sf_pause.body[0].text': 'Before you open it, one breath.',
  'sf_pause.body[1].text': 'What did you pick up your phone for?',
  'sf_pause.body[3].options[0]': 'Message someone',
  'sf_pause.body[3].options[1]': 'Bored',
  'sf_pause.body[3].options[2]': 'Avoiding something',
  'sf_pause.body[3].options[3]': 'Can’t sleep',
  'sf_pause.body[4].title': 'Bored? Try instead:',
  'sf_pause.body[4].text': '2-min walk · text one real person · a short lesson',
  'sf_pause.footer[0].action.then.value': 'Nice. Logged as a pause.',
  'sf_pause.footer[0].label': 'I’m good, put it down',
  'sf_pause.footer[1].label': 'Open anyway (logged as information)',
  'sf_pause.footer[1].action.value': 'Logged. No judgment.',
  'sf_pause.header.title': 'Pause 60',
  'sf_pause.header.pill': 'Urge rescue',
  'sf_slip.body[0].text': 'That happens. What pulled you in?',
  'sf_slip.body[1].text': 'Nothing resets. Your phone-free nights still count.',
  'sf_slip.body[2].options[0]': 'Couldn’t sleep',
  'sf_slip.body[2].options[1]': 'Bored',
  'sf_slip.body[2].options[2]': 'Stressed',
  'sf_slip.body[2].options[3]': 'Didn’t notice time',
  'sf_slip.body[3].items[0].label': 'Keep my goal, try again tonight',
  'sf_slip.body[3].items[0].badge': 'Recommended',
  'sf_slip.body[3].items[1].label': 'Make tomorrow’s goal easier',
  'sf_slip.body[3].items[2].label': 'Move bedtime window 30 min earlier',
  'sf_slip.footer[0].action.then.value': 'Saved',
  'sf_slip.footer[0].label': 'Save',
  'sf_slip.header.title': 'Long scroll',
  'sf_slip.header.pill': 'Private',
  'sf_week.body[0].text': 'Your week, honestly.',
  'sf_week.body[1].title': 'Social minutes / day',
  'sf_week.body[1].caption': 'Thursday: no check-in · not counted as zero',
  'sf_week.body[1].labels[0]': 'M',
  'sf_week.body[1].labels[1]': 'T',
  'sf_week.body[1].labels[2]': 'W',
  'sf_week.body[1].labels[3]': 'T',
  'sf_week.body[1].labels[4]': 'F',
  'sf_week.body[1].labels[5]': 'S',
  'sf_week.body[1].labels[6]': 'S',
  'sf_week.body[2].items[0].label': 'Phone-free nights',
  'sf_week.body[2].items[1].label': 'Urges paused',
  'sf_week.body[2].items[1].sub': '7 put down',
  'sf_week.body[3].eyebrow': 'You said',
  'sf_week.body[3].text': '“Drained” was 4× less common on phone-free nights.',
  'sf_week.body[3].children[0].text': 'I feel drained after long scrolls.',
  'sf_week.body[4].eyebrow': 'Next week',
  'sf_week.body[4].title': 'Step down to 75 min?',
  'sf_week.body[4].children[0].items[0].action.value': 'Goal set to 75 min',
  'sf_week.body[4].children[0].items[0].label': 'Yes',
  'sf_week.body[4].children[0].items[1].label': 'Stay at 90',
  'sf_week.header.title': 'Week 2',
  'ca_intro.body[0].extra': 'Respiratory health',
  'ca_intro.body[1].text': 'Follow your action plan, day by day.',
  'ca_intro.body[2].rows[0][0]': 'Zone check',
  'ca_intro.body[2].rows[0][1]': 'green · yellow · red',
  'ca_intro.body[2].rows[1][0]': 'Red zone',
  'ca_intro.body[2].rows[1][1]': 'one tap to 911',
  'ca_intro.body[2].rows[2][0]': 'Zones',
  'ca_intro.body[2].rows[2][1]': 'from your clinician only',
  'ca_intro.body[3].text': 'Check your zone, log symptoms and know exactly what to do, using the plan your clinician gave you.',
  'ca_intro.footer[0].label': 'Set up ClearAir',
  'ca_intro.footer[1].action.then.value': 'ClearAir added as Learn only',
  'ca_intro.footer[1].label': 'Add as Learn only',
  'ca_intro.header.pill': '~1 min/day',
  'ca_q1.body[1].text': 'Which applies to you?',
  'ca_q1.body[2].text': 'As told by a clinician.',
  'ca_q1.body[3].items[0].label': 'Asthma',
  'ca_q1.body[3].items[1].label': 'COPD',
  'ca_q1.body[3].items[2].label': 'Other lung condition',
  'ca_q1.body[3].items[3].label': 'Not diagnosed: I want to learn',
  'ca_q1.body[4].options[0]': 'Yes',
  'ca_q1.body[4].options[1]': 'No',
  'ca_q1.body[4].options[2]': 'Not sure',
  'ca_q1.body[4].label': 'Do you have a written action plan?',
  'ca_q1.footer[0].label': 'Next',
  'ca_q1.header.title': 'About your breathing',
  'ca_q1.header.pill': '1 of 2',
  'ca_plan.body[1].text': 'Copy your plan from your clinician.',
  'ca_plan.body[2].text': 'ClearAir never creates or changes zones.',
  'ca_plan.body[3].eyebrow': 'Green zone',
  'ca_plan.body[3].children[0].label': 'Peak flow from',
  'ca_plan.body[3].children[1].label': 'Daily medicine',
  'ca_plan.body[3].children[1].placeholder': 'Controller inhaler · 2 puffs AM/PM',
  'ca_plan.body[4].eyebrow': 'Yellow zone',
  'ca_plan.body[4].children[0].label': 'Peak flow',
  'ca_plan.body[5].eyebrow': 'Red zone',
  'ca_plan.body[5].children[0].label': 'Below',
  'ca_plan.body[6].action.value': 'Camera opened',
  'ca_plan.body[6].label': 'Add a photo of my plan',
  'ca_plan.footer[0].label': 'Save plan',
  'ca_plan.header.title': 'Your action plan',
  'ca_plan.header.pill': '2 of 2',
  'ca_noplan.body[1].text': 'Let’s get you a plan first',
  'ca_noplan.body[2].text': 'Zone checks need a plan from your clinician. Until then you can learn, log symptoms and prepare questions.',
  'ca_noplan.body[3].rows[0].label': 'Symptom diary',
  'ca_noplan.body[3].rows[0].sub': 'Shareable with your clinician',
  'ca_noplan.body[3].rows[1].label': 'Questions for my next visit',
  'ca_noplan.body[3].rows[2].label': 'Message my care team',
  'ca_noplan.footer[0].label': 'Continue to ClearAir',
  'ca_noplan.header.title': 'No action plan',
  'ca_noplan.header.pill': 'Learn',
  'ca_home.body[0].eyebrow': 'Today’s zone',
  'ca_home.body[0].title': 'Green · 410 L/min',
  'ca_home.body[0].text': 'Checked 7:40 AM · from your plan',
  'ca_home.body[1].label': 'Check my zone',
  'ca_home.body[2].title': 'Red-zone plan',
  'ca_home.body[2].text': 'Open it fast',
  'ca_home.body[3].rows[0].label': 'Log symptoms',
  'ca_home.body[3].rows[1].label': 'Progress',
  'ca_home.body[3].rows[1].sub': '10 green · 2 yellow · 0 red',
  'ca_home.body[3].rows[2].label': 'My action plan',
  'ca_home.body[3].rows[2].sub': 'Entered Sep 3',
  'ca_home.body[3].rows[3].label': 'Program settings',
  'ca_home.body[3].rows[3].sub': 'Status, sharing, export, leave',
  'ca_zone.body[0].text': 'How is your breathing?',
  'ca_zone.body[1].label': 'Peak flow (optional)',
  'ca_zone.body[1].hint': '50–900 L/min',
  'ca_zone.body[2].options[0]': 'Coughing',
  'ca_zone.body[2].options[1]': 'Wheezing',
  'ca_zone.body[2].options[2]': 'Short of breath',
  'ca_zone.body[2].options[3]': 'Chest tightness',
  'ca_zone.body[2].options[4]': 'Woke at night',
  'ca_zone.body[2].options[5]': 'Can’t speak in full sentences',
  'ca_zone.body[2].label': 'Symptoms now',
  'ca_zone.body[3].text': 'Your zone · updates as you type',
  'ca_zone.body[5].text': 'Worked out only from the plan you entered (green from 400, red below 200).',
  'ca_zone.footer[0].action.then.cases[0].action.value': 'Green zone · follow your daily routine',
  'ca_zone.footer[0].action.then.cases[3].action.value': 'Check your peak flow: 50–900 L/min',
  'ca_zone.footer[0].label': 'Save and see my steps',
  'ca_zone.header.title': 'Zone check',
  'ca_zone.header.pill': 'Today',
  'ca_yellow.body[0].title': 'Follow your yellow-zone steps',
  'ca_yellow.body[0].text': 'From the plan you entered on Sep 3',
  'ca_yellow.body[1].children[0].items[0].label': 'Reliever inhaler · 2–4 puffs',
  'ca_yellow.body[1].children[0].items[0].sub': 'As written in your plan',
  'ca_yellow.body[1].children[0].items[1].label': 'Re-check in 20 minutes',
  'ca_yellow.body[1].children[0].items[1].sub': 'We’ll remind you',
  'ca_yellow.body[1].children[0].items[2].label': 'Tell your care team if no better',
  'ca_yellow.body[1].children[0].items[2].sub': 'As your plan directs',
  'ca_yellow.body[2].title': 'Getting worse or can’t speak in full sentences?',
  'ca_yellow.body[2].text': 'Go to your red-zone plan',
  'ca_yellow.footer[0].action.value': 'Reminder set for 20 minutes',
  'ca_yellow.footer[0].label': 'Remind me in 20 min',
  'ca_yellow.footer[1].label': 'Message care team',
  'ca_yellow.header.title': 'Yellow zone',
  'ca_yellow.header.pill': 'Your plan',
  'ca_red.body[0].text': 'Follow your red-zone plan and seek urgent care now.',
  'ca_red.body[1].label': 'Call 911',
  'ca_red.body[2].eyebrow': 'Your red-zone plan',
  'ca_red.body[2].children[0].items[0].label': 'Reliever inhaler now, as written',
  'ca_red.body[2].children[0].items[1].label': 'Call your clinician or 911',
  'ca_red.body[2].children[0].items[2].label': 'Don’t drive yourself',
  'ca_red.body[3].rows[0].label': 'Tell Maria',
  'ca_red.body[3].rows[0].sub': 'Emergency contact · preview first',
  'ca_red.body[4].text': 'Stays open until you close it.',
  'ca_red.header.title': 'Red zone · act now',
  'ca_symptoms.body[0].text': 'What are you noticing?',
  'ca_symptoms.body[1].options[0]': 'Coughing',
  'ca_symptoms.body[1].options[1]': 'Wheezing',
  'ca_symptoms.body[1].options[2]': 'Short of breath',
  'ca_symptoms.body[1].options[3]': 'Chest tightness',
  'ca_symptoms.body[1].options[4]': 'Woke at night',
  'ca_symptoms.body[2].options[0]': 'Mild',
  'ca_symptoms.body[2].options[1]': 'Moderate',
  'ca_symptoms.body[2].options[2]': 'Severe',
  'ca_symptoms.body[2].label': 'How bad?',
  'ca_symptoms.body[3].options[0]': 'Cold air',
  'ca_symptoms.body[3].options[1]': 'Smoke',
  'ca_symptoms.body[3].options[2]': 'Pollen',
  'ca_symptoms.body[3].options[3]': 'Exercise',
  'ca_symptoms.body[3].options[4]': 'Not sure',
  'ca_symptoms.body[3].label': 'Possible trigger',
  'ca_symptoms.body[4].label': 'Note (optional)',
  'ca_symptoms.body[4].placeholder': 'Anything else to tell your clinician',
  'ca_symptoms.footer[0].action.then.value': 'Saved',
  'ca_symptoms.footer[0].label': 'Save',
  'ca_symptoms.header.title': 'Log symptoms',
  'ca_progress.body[0].title': 'Peak flow · 12 days',
  'ca_progress.body[0].caption': 'Shaded: your green zone, from your plan',
  'ca_progress.body[1].items[0].label': 'Green',
  'ca_progress.body[1].items[1].label': 'Yellow',
  'ca_progress.body[1].items[2].label': 'Red',
  'ca_progress.body[2].eyebrow': 'Most common symptom',
  'ca_progress.body[2].title': 'Wheezing at night (3×)',
  'ca_progress.body[2].text': 'Worth mentioning at your next visit.',
  'ca_progress.footer[0].label': 'Create visit summary',
  'ca_progress.header.title': 'Progress',
  'hw_intro.body[0].extra': 'Cardiovascular health',
  'hw_intro.body[1].text': 'Know your numbers. Share them on your terms.',
  'hw_intro.body[2].rows[0][0]': 'Readings',
  'hw_intro.body[2].rows[0][1]': 'BP + cholesterol panels',
  'hw_intro.body[2].rows[1][0]': 'Targets',
  'hw_intro.body[2].rows[1][1]': 'from your clinician',
  'hw_intro.body[2].rows[2][0]': 'A reading is',
  'hw_intro.body[2].rows[2][1]': 'information, not a grade',
  'hw_intro.body[3].text': 'Log blood pressure and cholesterol, see trends and prepare for visits. Both focus slots are in use, so you’ll choose how to add it.',
  'hw_intro.footer[0].label': 'Set up Heartwise',
  'hw_intro.footer[1].action.then.value': 'Heartwise added as Learn only',
  'hw_intro.footer[1].label': 'Add as Learn only',
  'hw_intro.header.pill': '~2 min/day',
  'hw_q1.body[1].text': 'Has a clinician talked with you about…',
  'hw_q1.body[2].options[0]': 'High blood pressure',
  'hw_q1.body[2].options[1]': 'High cholesterol',
  'hw_q1.body[2].options[2]': 'Heart disease',
  'hw_q1.body[2].options[3]': 'Stroke',
  'hw_q1.body[2].options[4]': 'None of these',
  'hw_q1.body[3].options[0]': 'Yes',
  'hw_q1.body[3].options[1]': 'No',
  'hw_q1.body[3].options[2]': 'Not sure',
  'hw_q1.body[3].label': 'Do you have a home BP monitor?',
  'hw_q1.body[4].text': 'No monitor? Many pharmacies have free kiosks. We’ll show how to measure correctly.',
  'hw_q1.footer[0].label': 'Next',
  'hw_q1.header.title': 'About you',
  'hw_q1.header.pill': '1 of 2',
  'hw_targets.body[1].text': 'What target did your clinician give you?',
  'hw_targets.body[2].fields[0].label': 'Top below',
  'hw_targets.body[2].fields[1].label': 'Bottom below',
  'hw_targets.body[3].items[0].label': 'I don’t have a target yet',
  'hw_targets.body[3].items[0].sub': 'Readings show without a target line',
  'hw_targets.body[4].options[0]': 'Morning',
  'hw_targets.body[4].options[1]': 'Evening',
  'hw_targets.body[4].options[2]': 'Both',
  'hw_targets.body[4].label': 'When should we remind you?',
  'hw_targets.body[5].text': 'Heartwise never sets or grades targets.',
  'hw_targets.body[6].label': 'Import from my health record',
  'hw_targets.footer[0].label': 'Save targets',
  'hw_targets.header.title': 'Your targets',
  'hw_targets.header.pill': '2 of 2',
  'hw_home.body[0].eyebrow': 'Last reading · 7:52 AM',
  'hw_home.body[0].children[0].caption': 'Average of 2 · target below 130/80',
  'hw_home.body[1].label': 'Log blood pressure',
  'hw_home.body[2].rows[0].label': 'Trends',
  'hw_home.body[2].rows[0].sub': '30-day average 132/82',
  'hw_home.body[2].rows[1].label': 'Cholesterol panel',
  'hw_home.body[2].rows[1].sub': 'LDL 138 · Sep 30',
  'hw_home.body[2].rows[2].label': 'Visit summary',
  'hw_home.body[2].rows[2].sub': 'Preview before sharing',
  'hw_home.body[2].rows[3].label': 'From your health record',
  'hw_home.body[2].rows[3].sub': '12 readings · Patel Family Medicine (Epic)',
  'hw_home.body[2].rows[4].label': 'My targets',
  'hw_home.body[2].rows[4].sub': '130/80 from Dr. Patel',
  'hw_home.body[2].rows[5].label': 'Program settings',
  'hw_home.body[2].rows[5].sub': 'Status, sharing, export, leave',
  'hw_home.body[3].text': 'Chest pain, pressure or trouble breathing? Call 911 now.',
  'hw_home.body[3].actions[0].label': 'Call 911',
  'hw_log.body[0].text': 'Sit quietly for 5 minutes first.',
  'hw_log.body[1].fields[0].label': 'Top (systolic)',
  'hw_log.body[1].fields[1].label': 'Bottom (diastolic)',
  'hw_log.body[2].label': 'Pulse (optional)',
  'hw_log.body[3].options[0]': 'Left arm',
  'hw_log.body[3].options[1]': 'Right arm',
  'hw_log.body[4].title': 'Tip',
  'hw_log.body[4].text': 'Take a second reading after 1 minute. We’ll average them.',
  'hw_log.footer[0].label': 'Next reading',
  'hw_log.header.title': 'Log blood pressure',
  'hw_log.header.pill': '1 of 2',
  'hw_log2.body[0].text': 'Second reading',
  'hw_log2.body[1].text': 'Same arm, 1 minute later.',
  'hw_log2.body[2].fields[0].label': 'Top (systolic)',
  'hw_log2.body[2].fields[1].label': 'Bottom (diastolic)',
  'hw_log2.body[3].label': 'Pulse (optional)',
  'hw_log2.body[4].rows[0][0]': 'Reading 1',
  'hw_log2.body[4].rows[1][0]': 'Average so far',
  'hw_log2.footer[0].label': 'Save readings',
  'hw_log2.header.title': 'Log blood pressure',
  'hw_log2.header.pill': '2 of 2',
  'hw_log_error.body[0].text': 'Let’s double-check that.',
  'hw_log_error.body[1].fields[0].label': 'Top (systolic)',
  'hw_log_error.body[1].fields[1].label': 'Bottom (diastolic)',
  'hw_log_error.body[1].fields[1].error': 'Too high for the bottom number. Did you mean 81?',
  'hw_log_error.body[2].text': 'Valid range: top 70–250, bottom 40–150, bottom lower than top.',
  'hw_log_error.footer[0].label': 'Save readings',
  'hw_log_error.footer[1].label': 'Edit reading',
  'hw_log_error.header.title': 'Log blood pressure',
  'hw_log_error.header.pill': 'Check',
  'hw_result.body[1].text': '135/85 saved',
  'hw_result.body[2].text': 'Average of 2 readings. Your clinician’s target is below 130/80.',
  'hw_result.body[3].text': 'One reading is information, not a grade. Trends over weeks matter most.',
  'hw_result.footer[0].label': 'See trends',
  'hw_result.footer[1].label': 'Back to Heartwise',
  'hw_result.header.title': 'Saved',
  'hw_crisis.body[0].text': '186/122 is in a range that needs attention now.',
  'hw_crisis.body[1].title': 'Do you have any of these right now?',
  'hw_crisis.body[1].text': 'Chest pain · shortness of breath · back pain · numbness or weakness · vision change · trouble speaking',
  'hw_crisis.body[2].label': 'Yes · call 911',
  'hw_crisis.body[3].label': 'No symptoms · re-check in 5 min',
  'hw_crisis.body[4].text': 'If it’s still this high on re-check, contact your clinician today. Heartwise doesn’t diagnose.',
  'hw_crisis.header.title': 'Check this reading',
  'hw_recheck.body[0].text': 'Rest, then measure again.',
  'hw_recheck.body[1].label': 'until re-check',
  'hw_recheck.body[2].children[0].items[0].label': 'Sit with your back supported',
  'hw_recheck.body[2].children[0].items[1].label': 'Feet flat, arm at heart level',
  'hw_recheck.body[2].children[0].items[2].label': 'No talking while measuring',
  'hw_recheck.body[3].text': 'New chest pain, weakness or trouble speaking? Call 911 now.',
  'hw_recheck.body[3].actions[0].label': 'Call 911',
  'hw_recheck.footer[0].label': 'Re-check now',
  'hw_recheck.footer[1].label': 'Contact my clinician',
  'hw_recheck.header.title': 'Re-check',
  'hw_trends.body[0].options[0]': '7 days',
  'hw_trends.body[0].options[1]': '30 days',
  'hw_trends.body[0].options[2]': '90 days',
  'hw_trends.body[1].title': 'Systolic · morning avg',
  'hw_trends.body[1].caption': 'Shaded: your clinician’s target',
  'hw_trends.body[2].items[0].label': '30-day avg',
  'hw_trends.body[2].items[1].label': 'Readings',
  'hw_trends.body[2].items[1].sub': '4 days missed',
  'hw_trends.footer[0].label': 'Create visit summary',
  'hw_trends.header.title': 'Trends',
  'hw_lipids.body[0].text': 'Add your lab results',
  'hw_lipids.body[1].text': 'Copy from your lab report. Units: mg/dL.',
  'hw_lipids.body[2].fields[0].label': 'Total',
  'hw_lipids.body[2].fields[1].label': 'LDL',
  'hw_lipids.body[3].fields[0].label': 'HDL',
  'hw_lipids.body[3].fields[1].label': 'Triglycerides',
  'hw_lipids.body[3].fields[1].placeholder': 'Optional',
  'hw_lipids.body[4].label': 'Lab date',
  'hw_lipids.body[4].placeholder': 'Sep 30, 2026',
  'hw_lipids.footer[0].action.then.value': 'Panel saved',
  'hw_lipids.footer[0].label': 'Save panel',
  'hw_lipids.header.title': 'Cholesterol panel',
  'hw_lipids.header.pill': 'Lab',
  'hw_summary.body[0].text': 'Share with Dr. Patel’s clinic?',
  'hw_summary.body[1].rows[0][0]': 'Dates',
  'hw_summary.body[1].rows[0][1]': 'Sep 17 – Oct 17',
  'hw_summary.body[1].rows[1][0]': 'BP average',
  'hw_summary.body[1].rows[1][1]': '132/82 (48 readings)',
  'hw_summary.body[1].rows[2][0]': 'Highest',
  'hw_summary.body[1].rows[2][1]': '186/122 · Oct 2 · re-checked 144/90',
  'hw_summary.body[1].rows[3][0]': 'Latest panel',
  'hw_summary.body[1].rows[3][1]': 'LDL 138 · Sep 30',
  'hw_summary.body[2].text': 'Only Heartwise data. Nothing from your other programs.',
  'hw_summary.body[3].label': 'Include notes',
  'hw_summary.footer[0].action.then.value': 'Summary sent to Dr. Patel’s clinic',
  'hw_summary.footer[0].label': 'Send summary',
  'hw_summary.footer[1].action.value': 'PDF saved to Files',
  'hw_summary.footer[1].label': 'Save as PDF',
  'hw_summary.header.title': 'Visit summary',
  'hw_summary.header.pill': 'Preview',
  'st_intro.body[0].extra': 'Diabetes & metabolic health',
  'st_intro.body[1].text': 'Notice glucose patterns, without judgment.',
  'st_intro.body[2].rows[0][0]': 'Readings',
  'st_intro.body[2].rows[0][1]': 'meter or CGM entries',
  'st_intro.body[2].rows[1][0]': 'Range',
  'st_intro.body[2].rows[1][1]': 'from your clinician',
  'st_intro.body[2].rows[2][0]': 'A high reading is',
  'st_intro.body[2].rows[2][1]': 'information, not failure',
  'st_intro.body[3].text': 'Log readings, see patterns around meals and sleep, and follow the low plan your clinician gave you. Steady never counts calories.',
  'st_intro.footer[0].label': 'Set up Steady',
  'st_intro.footer[1].action.then.value': 'Steady added as Learn only',
  'st_intro.footer[1].label': 'Add as Learn only',
  'st_intro.header.pill': '~2 min/day',
  'st_q1.body[1].text': 'Which describes you?',
  'st_q1.body[2].text': 'As told by a clinician.',
  'st_q1.body[3].items[0].label': 'Type 2 diabetes',
  'st_q1.body[3].items[1].label': 'Prediabetes',
  'st_q1.body[3].items[2].label': 'Type 1 diabetes',
  'st_q1.body[3].items[2].sub': 'Logging only; follow your care team for insulin',
  'st_q1.body[3].items[3].label': 'Gestational diabetes',
  'st_q1.body[3].items[3].sub': 'Education only; talk with your care team',
  'st_q1.body[3].items[4].label': 'Not diagnosed: learn',
  'st_q1.body[4].options[0]': 'Meter',
  'st_q1.body[4].options[1]': 'CGM',
  'st_q1.body[4].options[2]': 'Lab only',
  'st_q1.body[4].label': 'How do you check?',
  'st_q1.footer[0].label': 'Next',
  'st_q1.header.title': 'About you',
  'st_q1.header.pill': '1 of 2',
  'st_range.body[1].text': 'Enter the range your clinician gave you.',
  'st_range.body[2].options[0]': 'mg/dL',
  'st_range.body[2].options[1]': 'mmol/L',
  'st_range.body[3].fields[0].label': 'Before meals from',
  'st_range.body[3].fields[1].label': 'to',
  'st_range.body[4].label': '2 h after meals below',
  'st_range.body[5].eyebrow': 'Your low plan',
  'st_range.body[5].children[0].label': 'Low below',
  'st_range.body[5].children[1].label': 'My low steps',
  'st_range.body[5].children[1].placeholder': '15 g fast sugar, re-check in 15 min',
  'st_range.body[6].label': 'Import from my health record',
  'st_range.footer[0].label': 'Save range',
  'st_range.header.title': 'Your range',
  'st_range.header.pill': '2 of 2',
  'st_home.body[0].eyebrow': 'Last reading · 2 h after lunch',
  'st_home.body[0].children[0].caption': 'Within your after-meal range (below 180)',
  'st_home.body[1].label': 'Log a reading',
  'st_home.body[2].rows[0].label': 'Meal energy reset',
  'st_home.body[2].rows[0].sub': '3 minutes',
  'st_home.body[2].rows[1].label': 'Patterns',
  'st_home.body[2].rows[1].sub': '71% in range · 14 days',
  'st_home.body[2].rows[2].label': 'A1C history',
  'st_home.body[2].rows[2].sub': '7.4% · Oct 1',
  'st_home.body[2].rows[3].label': 'My range & low plan',
  'st_home.body[2].rows[4].label': 'Program settings',
  'st_home.body[2].rows[4].sub': 'Status, sharing, export, leave',
  'st_home.body[3].text': 'Steady never counts calories. A high reading is information, not failure.',
  'st_log.body[0].label': 'Reading',
  'st_log.body[0].hint': 'From your meter or CGM · 20–600 mg/dL',
  'st_log.body[1].options[0]': 'Fasting',
  'st_log.body[1].options[1]': 'Before meal',
  'st_log.body[1].options[2]': '2 h after meal',
  'st_log.body[1].options[3]': 'Bedtime',
  'st_log.body[1].options[4]': 'Other',
  'st_log.body[1].label': 'When?',
  'st_log.body[2].options[0]': 'Fine',
  'st_log.body[2].options[1]': 'Shaky',
  'st_log.body[2].options[2]': 'Sweaty',
  'st_log.body[2].options[3]': 'Tired',
  'st_log.body[2].options[4]': 'Thirsty',
  'st_log.body[2].label': 'How do you feel?',
  'st_log.body[3].label': 'Note (optional)',
  'st_log.body[3].hint': 'Never shared unless you choose',
  'st_log.body[3].placeholder': 'Pasta lunch',
  'st_log.footer[0].action.then.cases[0].action.value': 'Saved',
  'st_log.footer[0].action.then.cases[2].action.value': 'Check your meter reading',
  'st_log.footer[0].label': 'Save reading',
  'st_log.header.title': 'Log a reading',
  'st_low.body[0].text': '62 mg/dL is below your low of 70.',
  'st_low.body[1].eyebrow': 'Your low plan',
  'st_low.body[1].children[0].items[0].label': 'Take 15 g of fast sugar',
  'st_low.body[1].children[0].items[0].sub': '4 glucose tablets or ½ cup juice',
  'st_low.body[1].children[0].items[1].label': 'Re-check in 15 minutes',
  'st_low.body[1].children[0].items[2].label': 'Repeat if still below 70',
  'st_low.body[2].label': 'until re-check',
  'st_low.body[3].title': 'Confused, can’t swallow or passing out?',
  'st_low.body[3].text': 'Someone should call 911 now.',
  'st_low.body[3].children[0].label': 'Call 911',
  'st_low.footer[0].label': 'Re-check now',
  'st_low.header.title': 'Low reading',
  'st_reset.body[0].text': 'Feeling the post-meal slump?',
  'st_reset.body[1].children[0].items[0].label': 'Drink a glass of water',
  'st_reset.body[1].children[0].items[1].label': 'Take a 10-minute walk if you can',
  'st_reset.body[1].children[0].items[2].label': 'Take five slow breaths',
  'st_reset.body[1].children[0].items[3].label': 'Feel unwell? Contact your clinician',
  'st_reset.body[2].text': 'Walking after meals helps some people’s readings. Check with your clinician what’s right for you.',
  'st_reset.footer[0].action.value': 'Nice work',
  'st_reset.footer[0].label': 'Done',
  'st_reset.header.title': 'Meal energy reset',
  'st_reset.header.pill': '3 min',
  'st_patterns.body[0].options[0]': '7 days',
  'st_patterns.body[0].options[1]': '14 days',
  'st_patterns.body[0].options[2]': '30 days',
  'st_patterns.body[1].title': 'After meals',
  'st_patterns.body[2].items[0].label': 'In your range',
  'st_patterns.body[2].items[0].sub': 'of 38 readings',
  'st_patterns.body[2].items[1].label': 'Lows',
  'st_patterns.body[2].items[1].sub': 'Oct 9 · treated',
  'st_patterns.body[3].eyebrow': 'Pattern',
  'st_patterns.body[3].title': 'Readings were higher on nights with less than 6 h sleep.',
  'st_patterns.header.title': 'Patterns',
  'st_a1c.body[0].text': 'Add your A1C',
  'st_a1c.body[1].label': 'A1C',
  'st_a1c.body[2].label': 'Lab date',
  'st_a1c.body[2].placeholder': 'Oct 1, 2026',
  'st_a1c.body[3].rows[0][0]': 'Previous',
  'st_a1c.body[3].rows[0][1]': '7.9% · Jul 2',
  'st_a1c.body[3].rows[1][0]': 'Change',
  'st_a1c.body[3].rows[1][1]': '−0.5 points',
  'st_a1c.body[4].text': 'Your clinician sets your A1C goal. Steady shows history only.',
  'st_a1c.footer[0].action.then.value': 'Saved',
  'st_a1c.footer[0].label': 'Save',
  'st_a1c.header.title': 'A1C lab',
  'st_a1c.header.pill': 'Lab day',
  're_intro.body[0].extra': 'Kidney & liver health',
  're_intro.body[1].text': 'Look after your kidneys and liver.',
  're_intro.body[2].rows[0][0]': 'Risk check',
  're_intro.body[2].rows[0][1]': 'diabetes, BP, alcohol, family',
  're_intro.body[2].rows[1][0]': 'Labs',
  're_intro.body[2].rows[1][1]': 'eGFR, ACR, ALT tracking',
  're_intro.body[2].rows[2][0]': 'Reminders',
  're_intro.body[2].rows[2][1]': 'checks from your clinician',
  're_intro.footer[0].label': 'Set up Renew',
  're_intro.footer[1].action.then.value': 'Renew added as Learn only',
  're_intro.footer[1].label': 'Add as Learn only',
  're_intro.header.pill': '~1 min/day',
  're_q1.body[1].text': 'Do any of these apply?',
  're_q1.body[2].text': 'These raise the chance of kidney or liver problems.',
  're_q1.body[3].options[0]': 'Diabetes',
  're_q1.body[3].options[1]': 'High blood pressure',
  're_q1.body[3].options[2]': 'Heart disease',
  're_q1.body[3].options[3]': 'Family history of kidney disease',
  're_q1.body[3].options[4]': 'Regular alcohol',
  're_q1.body[3].options[5]': 'Hepatitis B or C',
  're_q1.body[3].options[6]': 'None',
  're_q1.body[4].options[0]': 'Kidney',
  're_q1.body[4].options[1]': 'Liver',
  're_q1.body[4].options[2]': 'Both',
  're_q1.body[4].options[3]': 'No',
  're_q1.body[4].label': 'Known condition?',
  're_q1.footer[0].label': 'See what this means',
  're_q1.header.title': 'Risk check',
  're_q1.header.pill': '1 of 1',
  're_result.body[0].text': 'Worth asking about a kidney check.',
  're_result.body[1].text': 'People with diabetes and high blood pressure are usually advised to have yearly kidney tests: a blood test (eGFR) and a urine test (ACR).',
  're_result.body[2].children[0].items[0].label': 'Ask about eGFR and urine ACR at my next visit',
  're_result.body[2].children[0].items[1].label': 'Remind me 1 week before my visit',
  're_result.body[3].title': 'Also see Heartwise and Steady',
  're_result.body[3].text': 'Managing BP and glucose protects your kidneys.',
  're_result.footer[0].label': 'Save my plan',
  're_result.header.title': 'Your result',
  're_result.header.pill': 'Not a diagnosis',
  're_home.body[0].eyebrow': 'Latest eGFR · Oct 3',
  're_home.body[0].children[0].caption': 'Next check Apr 2027 · from your clinician',
  're_home.body[1].eyebrow': 'Today',
  're_home.body[1].children[0].items[0].label': 'Medicine reminder · 8:00 AM',
  're_home.body[1].children[0].items[0].sub': 'As entered from your clinician',
  're_home.body[1].children[0].items[1].label': 'Water reminder',
  're_home.body[1].children[0].items[1].sub': 'Only if your clinician hasn’t limited fluids',
  're_home.body[2].rows[0].label': 'Add lab results',
  're_home.body[2].rows[1].label': 'Lab history',
  're_home.body[2].rows[1].sub': '2 years',
  're_home.body[2].rows[2].label': 'Check symptoms',
  're_home.body[2].rows[3].label': 'Program settings',
  're_home.body[2].rows[3].sub': 'Status, sharing, export, leave',
  're_home.body[3].title': 'Over-the-counter pain relief?',
  're_home.body[3].text': 'Some (like ibuprofen) can affect kidneys. Ask your pharmacist.',
  're_labs.body[0].label': 'eGFR',
  're_labs.body[1].label': 'Urine ACR',
  're_labs.body[2].label': 'ALT (liver)',
  're_labs.body[2].placeholder': 'Optional',
  're_labs.body[3].label': 'Lab date',
  're_labs.body[3].placeholder': 'Oct 3, 2026',
  're_labs.body[4].text': 'Copy numbers exactly from your report. Renew shows trends; your clinician explains them.',
  're_labs.body[5].label': 'Import from my health record',
  're_labs.footer[0].action.then.value': 'Saved',
  're_labs.footer[0].label': 'Save results',
  're_labs.header.title': 'Add lab results',
  're_labs.header.pill': 'Lab',
  're_history.body[0].title': 'eGFR · 2 years',
  're_history.body[0].caption': 'Lower over time. Bring this to your next visit.',
  're_history.body[1].rows[0][0]': 'Latest eGFR',
  're_history.body[1].rows[0][1]': '58 · Oct 3',
  're_history.body[1].rows[1][0]': 'Latest ACR',
  're_history.body[1].rows[1][1]': '42 mg/g',
  're_history.body[1].rows[2][0]': 'Next check',
  're_history.body[1].rows[2][1]': 'Apr 2027 (from your clinician)',
  're_history.footer[0].label': 'Create visit summary',
  're_history.header.title': 'Lab history',
  're_symptoms.body[0].text': 'Do you have any of these?',
  're_symptoms.body[1].options[0]': 'Very little urine',
  're_symptoms.body[1].options[1]': 'Swelling in legs or face',
  're_symptoms.body[1].options[2]': 'Yellow skin or eyes',
  're_symptoms.body[1].options[3]': 'Confusion',
  're_symptoms.body[1].options[4]': 'Vomiting blood',
  're_symptoms.body[1].options[5]': 'None',
  're_symptoms.body[2].text': 'Yellow skin or eyes needs a clinician today.',
  're_symptoms.footer[0].label': 'Contact my care team',
  're_symptoms.footer[1].label': 'Vomiting blood or confused? Call 911',
  're_symptoms.header.title': 'Check symptoms',
  'nu_intro.body[0].extra': 'Obesity & nutrition',
  'nu_intro.body[1].text': 'Food without judgment.',
  'nu_intro.body[2].rows[0][0]': 'Weekly habit',
  'nu_intro.body[2].rows[0][1]': 'one at a time',
  'nu_intro.body[2].rows[1][0]': 'Weight',
  'nu_intro.body[2].rows[1][1]': 'off by default',
  'nu_intro.body[2].rows[2][0]': 'Approach',
  'nu_intro.body[2].rows[2][1]': 'add, don’t restrict',
  'nu_intro.footer[0].label': 'Set up Nourish',
  'nu_intro.footer[1].action.then.value': 'Nourish added as Learn only',
  'nu_intro.footer[1].label': 'Add as Learn only',
  'nu_intro.header.pill': '~1 min/day',
  'nu_q1.body[1].text': 'What would you like more of?',
  'nu_q1.body[2].options[0]': 'Energy',
  'nu_q1.body[2].options[1]': 'Easy meals',
  'nu_q1.body[2].options[2]': 'More plants',
  'nu_q1.body[2].options[3]': 'More water',
  'nu_q1.body[2].options[4]': 'Move more',
  'nu_q1.body[2].options[5]': 'Save on food',
  'nu_q1.body[2].options[6]': 'Feel better about food',
  'nu_q1.body[3].title': 'Have you struggled with eating, like restricting, bingeing or purging?',
  'nu_q1.body[3].text': 'If yes, we adjust Nourish and share support options.',
  'nu_q1.body[3].children[0].options[0]': 'No',
  'nu_q1.body[3].children[0].options[1]': 'Yes',
  'nu_q1.body[3].children[0].options[2]': 'Prefer not to say',
  'nu_q1.footer[0].label': 'Next',
  'nu_q1.header.title': 'What matters',
  'nu_q1.header.pill': '1 of 1',
  'nu_habit.body[0].text': 'Pick one habit for this week.',
  'nu_habit.body[1].items[0].label': 'Add a vegetable to dinner',
  'nu_habit.body[1].items[0].sub': '5 nights this week',
  'nu_habit.body[1].items[0].badge': 'Suggested',
  'nu_habit.body[1].items[1].label': 'Water before each meal',
  'nu_habit.body[1].items[1].sub': 'Every day',
  'nu_habit.body[1].items[2].label': 'Cook at home',
  'nu_habit.body[1].items[2].sub': '3 times this week',
  'nu_habit.body[1].items[3].label': '10-minute walk after a meal',
  'nu_habit.body[1].items[3].sub': '4 times',
  'nu_habit.body[2].children[0].label': 'Track weight',
  'nu_habit.body[2].children[0].sub': 'Off by default · can stay off forever',
  'nu_habit.footer[0].label': 'Start this habit',
  'nu_habit.header.title': 'This week’s habit',
  'nu_habit.header.pill': 'Plan',
  'nu_home.body[0].eyebrow': 'Habit · week 2',
  'nu_home.body[0].title': 'Add a vegetable to dinner',
  'nu_home.body[0].text': '3 of 5 nights',
  'nu_home.body[0].cta[0].action.value': 'Nice. 4 of 5 nights.',
  'nu_home.body[0].cta[0].label': 'Done today',
  'nu_home.body[1].eyebrow': 'Tip',
  'nu_home.body[1].title': 'Frozen vegetables count, and are often cheaper.',
  'nu_home.body[2].eyebrow': 'Quick recipe · 15 min',
  'nu_home.body[2].title': 'Bean and veggie tacos',
  'nu_home.body[2].text': 'Under \$2 a serving',
  'nu_home.body[3].rows[0].label': 'Busy week?',
  'nu_home.body[3].rows[0].sub': 'Reset without guilt',
  'nu_home.body[3].rows[1].label': 'Week 4 milestone',
  'nu_home.body[3].rows[1].sub': 'In 2 weeks',
  'nu_home.body[3].rows[2].label': 'Change habit',
  'nu_home.body[3].rows[3].label': 'Program settings',
  'nu_home.body[3].rows[3].sub': 'Status, sharing, export, leave',
  'nu_reset.body[0].text': 'Busy week? That’s okay.',
  'nu_reset.body[1].text': 'Missing days doesn’t undo the ones you did.',
  'nu_reset.body[2].items[0].label': 'Keep this habit, start fresh today',
  'nu_reset.body[2].items[1].label': 'Make it smaller',
  'nu_reset.body[2].items[1].sub': '3 nights instead of 5',
  'nu_reset.body[2].items[2].label': 'Pick a different habit',
  'nu_reset.footer[0].action.cases[0].action.value': 'Fresh start today',
  'nu_reset.footer[0].action.cases[1].action.value': 'Goal set to 3 nights',
  'nu_reset.footer[0].label': 'Continue',
  'nu_reset.header.title': 'Off track?',
  'nu_reset.header.pill': 'Reset',
  'nu_week4.body[1].text': 'Four weeks of small habits.',
  'nu_week4.body[2].rows[0][0]': 'Habits tried',
  'nu_week4.body[2].rows[1][0]': 'Days done',
  'nu_week4.body[2].rows[2][0]': 'Favorite',
  'nu_week4.body[2].rows[2][1]': 'Water before meals',
  'nu_week4.body[3].options[0]': 'Worse',
  'nu_week4.body[3].options[1]': 'Same',
  'nu_week4.body[3].options[2]': 'Better',
  'nu_week4.body[3].label': 'How do you feel about food lately?',
  'nu_week4.footer[0].label': 'Choose next habit',
  'nu_week4.header.title': 'Week 4',
  'nu_week4.header.pill': 'Milestone',
  'nu_protect.body[0].text': 'Thanks for telling us.',
  'nu_protect.body[1].text': 'Nourish has turned off weight, amount goals and before/after comparisons.',
  'nu_protect.body[2].title': 'Talking to someone can help',
  'nu_protect.body[2].text': 'A clinician or eating-disorder specialist can support you. We can help you prepare what to say.',
  'nu_protect.body[2].cta[0].label': 'Prepare',
  'nu_protect.body[3].text': 'In crisis? Call or text 988 · Emergency 911',
  'nu_protect.body[3].actions[0].label': 'Call or text 988',
  'nu_protect.body[3].actions[1].label': 'Call 911',
  'nu_protect.footer[0].label': 'Continue with gentle habits',
  'nu_protect.header.title': 'Support',
  'nu_protect.header.pill': 'Private',
  'sd_intro.body[0].extra': 'Healthy aging',
  'sd_intro.body[1].text': 'Move well, stay well.',
  'sd_intro.body[2].rows[0][0]': 'Sessions',
  'sd_intro.body[2].rows[0][1]': '5–15 min, audio + video',
  'sd_intro.body[2].rows[1][0]': 'Falls',
  'sd_intro.body[2].rows[1][1]': 'home safety + I fell button',
  'sd_intro.body[2].rows[2][0]': 'Caregiver',
  'sd_intro.body[2].rows[2][1]': 'optional, Stride only',
  'sd_intro.footer[0].label': 'Set up Stride',
  'sd_intro.footer[1].action.then.value': 'Stride added as Learn only',
  'sd_intro.footer[1].label': 'Add as Learn only',
  'sd_intro.header.pill': '~10 min/day',
  'sd_q1.body[1].options[0]': 'No',
  'sd_q1.body[1].options[1]': 'Once',
  'sd_q1.body[1].options[2]': '2+ times',
  'sd_q1.body[1].label': 'In the last year, have you fallen?',
  'sd_q1.body[2].options[0]': 'No',
  'sd_q1.body[2].options[1]': 'Sometimes',
  'sd_q1.body[2].options[2]': 'Often',
  'sd_q1.body[2].label': 'Do you feel unsteady standing or walking?',
  'sd_q1.body[3].options[0]': 'No',
  'sd_q1.body[3].options[1]': 'A little',
  'sd_q1.body[3].options[2]': 'A lot',
  'sd_q1.body[3].label': 'Do you worry about falling?',
  'sd_q1.body[4].text': 'A fall plus feeling unsteady is worth mentioning to your clinician. We’ll add it to your visit list.',
  'sd_q1.footer[0].label': 'Next',
  'sd_q1.header.title': 'How you move',
  'sd_q1.header.pill': '1 of 1',
  'sd_plan.body[0].text': 'Three short sessions a week',
  'sd_plan.body[1].rows[0][0]': 'Mon',
  'sd_plan.body[1].rows[0][1]': 'Balance · 8 min',
  'sd_plan.body[1].rows[1][0]': 'Wed',
  'sd_plan.body[1].rows[1][1]': 'Strength (chair) · 10 min',
  'sd_plan.body[1].rows[2][0]': 'Fri',
  'sd_plan.body[1].rows[2][1]': 'Walk + balance · 12 min',
  'sd_plan.body[2].children[0].items[0].label': 'Do sessions near a sturdy chair',
  'sd_plan.body[2].children[0].items[1].label': 'Tell my caregiver when I finish',
  'sd_plan.body[3].text': 'Check with your clinician before starting a new exercise program.',
  'sd_plan.footer[0].label': 'Start plan',
  'sd_plan.header.title': 'Your movement plan',
  'sd_plan.header.pill': 'Plan',
  'sd_home.body[0].eyebrow': 'Today · Wednesday',
  'sd_home.body[0].title': 'Strength (chair) · 10 min',
  'sd_home.body[0].cta[0].label': 'Start',
  'sd_home.body[1].title': 'I fell',
  'sd_home.body[1].text': 'Get help or log a fall',
  'sd_home.body[2].rows[0].label': 'Home safety checklist',
  'sd_home.body[2].rows[0].sub': '2 of 5 done',
  'sd_home.body[2].rows[1].label': 'Caregiver access',
  'sd_home.body[2].rows[1].sub': 'Rosa · Stride only',
  'sd_home.body[2].rows[2].label': 'Movement plan',
  'sd_home.body[2].rows[2].sub': '3 sessions a week',
  'sd_home.body[2].rows[3].label': 'Program settings',
  'sd_home.body[2].rows[3].sub': 'Status, sharing, export, leave',
  'sd_home.body[3].items[0].label': 'This week',
  'sd_home.body[3].items[0].value': '1 of 3',
  'sd_home.body[3].items[0].sub': 'sessions',
  'sd_home.body[3].items[1].label': 'Falls logged',
  'sd_home.body[3].items[1].sub': 'last 30 days',
  'sd_session.body[1].text': 'Heel-to-toe stand',
  'sd_session.body[2].text': 'Hold the chair. Place one foot in front of the other. Hold 10 seconds.',
  'sd_session.body[4].options[0]': 'Audio on',
  'sd_session.body[4].options[1]': 'Large text',
  'sd_session.body[4].options[2]': 'Captions',
  'sd_session.footer[0].action.value': 'Exercise 3 of 6',
  'sd_session.footer[0].label': 'Next exercise',
  'sd_session.footer[1].action.then.value': 'Session saved',
  'sd_session.footer[1].label': 'Finish session',
  'sd_session.header.title': 'Balance · 8 min',
  'sd_session.header.pill': '2 of 6',
  'sd_fell.body[0].text': 'Are you hurt?',
  'sd_fell.body[1].label': 'I hit my head or can’t get up · Call 911',
  'sd_fell.body[2].rows[0].label': 'Call Rosa',
  'sd_fell.body[2].rows[0].sub': 'Caregiver',
  'sd_fell.body[3].title': 'How to get up safely',
  'sd_fell.body[3].text': 'Roll to your side, crawl to a sturdy chair, kneel, then rise slowly.',
  'sd_fell.footer[0].action.then.value': 'Fall logged. Added to your visit list.',
  'sd_fell.footer[0].label': 'I’m okay, log this fall',
  'sd_fell.header.title': 'I fell',
  'sd_safety.body[0].text': 'Make your home safer',
  'sd_safety.body[1].children[0].items[0].label': 'Remove loose rugs',
  'sd_safety.body[1].children[0].items[1].label': 'Night lights in hallway and bathroom',
  'sd_safety.body[1].children[0].items[2].label': 'Grab bar in shower',
  'sd_safety.body[1].children[0].items[3].label': 'Stair rails on both sides',
  'sd_safety.body[1].children[0].items[4].label': 'Vision check this year',
  'sd_safety.body[2].text': '2 of 5 done',
  'sd_safety.footer[0].action.then.value': 'Saved',
  'sd_safety.footer[0].label': 'Save',
  'sd_safety.header.title': 'Home safety',
  'sd_safety.header.pill': 'Checklist',
  'sd_caregiver.body[0].text': 'Let someone help',
  'sd_caregiver.body[1].label': 'Name',
  'sd_caregiver.body[1].placeholder': 'Rosa',
  'sd_caregiver.body[2].label': 'Phone',
  'sd_caregiver.body[3].items[0].label': 'When I finish a session',
  'sd_caregiver.body[3].items[1].label': 'If I log a fall',
  'sd_caregiver.body[3].items[2].label': 'My other programs',
  'sd_caregiver.body[3].items[2].sub': 'Never available to caregivers',
  'sd_caregiver.body[3].label': 'Rosa can see',
  'sd_caregiver.footer[0].action.then.value': 'Invite sent to Rosa',
  'sd_caregiver.footer[0].label': 'Send invite',
  'sd_caregiver.header.title': 'Caregiver access',
  'sd_caregiver.header.pill': 'Optional',
  'ea_intro.body[0].extra': 'Mental & behavioral health',
  'ea_intro.body[1].text': 'Support for how you feel.',
  'ea_intro.body[2].rows[0][0]': 'Mood check-in',
  'ea_intro.body[2].rows[0][1]': '30 seconds',
  'ea_intro.body[2].rows[1][0]': 'Screening',
  'ea_intro.body[2].rows[1][1]': 'optional, private',
  'ea_intro.body[2].rows[2][0]': 'Help now',
  'ea_intro.body[2].rows[2][1]': '988 always one tap away',
  'ea_intro.footer[0].label': 'Set up Ease',
  'ea_intro.footer[1].action.then.value': 'Ease added as Learn only',
  'ea_intro.footer[1].label': 'Add as Learn only',
  'ea_intro.header.pill': '~2 min/day',
  'ea_q1.body[1].text': 'Over the last 2 weeks, how often have you been bothered by…',
  'ea_q1.body[2].text': 'Little interest or pleasure in doing things?',
  'ea_q1.body[3].items[0].label': 'Not at all',
  'ea_q1.body[3].items[1].label': 'Several days',
  'ea_q1.body[3].items[2].label': 'More than half the days',
  'ea_q1.body[3].items[3].label': 'Nearly every day',
  'ea_q1.body[4].text': 'PHQ-2 / GAD-2 · validated questions · skippable',
  'ea_q1.footer[0].label': 'Next',
  'ea_q1.footer[1].label': 'Skip the check',
  'ea_q1.header.title': 'Optional check',
  'ea_q1.header.pill': '1 of 4',
  'ea_result.body[0].text': 'Talking to someone could help.',
  'ea_result.body[1].text': 'Your answers suggest you’ve been carrying a lot lately. A doctor, counselor or therapist can help figure out what would make the biggest difference.',
  'ea_result.body[2].rows[0].label': 'Find a therapist near me',
  'ea_result.body[2].rows[0].sub': 'In-network filters',
  'ea_result.body[2].rows[1].label': 'Talk to my primary care doctor',
  'ea_result.body[2].rows[1].sub': 'We’ll help you prepare',
  'ea_result.body[2].rows[2].label': 'Not now',
  'ea_result.body[2].rows[2].sub': 'Keep using Ease tools',
  'ea_result.body[3].text': 'Thoughts of harming yourself? Call or text 988. Emergency: 911.',
  'ea_result.body[3].actions[0].label': 'Call or text 988',
  'ea_result.body[3].actions[1].label': 'Call 911',
  'ea_result.header.title': 'Your answers',
  'ea_result.header.pill': 'Not a diagnosis',
  'ea_plan.body[0].text': 'Make a plan for hard moments',
  'ea_plan.body[1].text': 'Based on the Stanley-Brown safety plan. Only you can see this.',
  'ea_plan.body[2].label': 'My warning signs',
  'ea_plan.body[2].placeholder': 'Not sleeping, pulling away from friends',
  'ea_plan.body[3].label': 'Things that help me',
  'ea_plan.body[3].placeholder': 'Walk the dog, shower, music',
  'ea_plan.body[4].label': 'People I can reach',
  'ea_plan.body[4].placeholder': 'Sam · (555) 010-3311',
  'ea_plan.body[5].rows[0][0]': 'Crisis line',
  'ea_plan.body[5].rows[0][1]': '988 · call or text',
  'ea_plan.body[5].rows[1][0]': 'Emergency',
  'ea_plan.footer[0].label': 'Save plan',
  'ea_plan.header.title': 'Safety plan',
  'ea_plan.header.pill': 'Private',
  'ea_home.body[0].eyebrow': 'How are you right now?',
  'ea_home.body[0].title': '30-second mood check-in',
  'ea_home.body[0].cta[0].label': 'Start',
  'ea_home.body[1].rows[0].label': 'My safety plan',
  'ea_home.body[1].rows[0].sub': 'Updated Oct 2',
  'ea_home.body[1].rows[1].label': 'Check-back',
  'ea_home.body[1].rows[1].sub': 'In 6 days',
  'ea_home.body[1].rows[2].label': 'Find a professional',
  'ea_home.body[1].rows[3].label': 'Program settings',
  'ea_home.body[1].rows[3].sub': 'Status, sharing, export, leave',
  'ea_home.body[2].title': 'Sleep and mood: 3 small changes',
  'ea_home.body[2].text': '5 min',
  'ea_home.body[3].text': 'Thoughts of harming yourself? Call or text 988. Emergency: 911.',
  'ea_home.body[3].actions[0].label': 'Call or text 988',
  'ea_home.body[3].actions[1].label': 'Call 911',
  'ea_mood.body[0].options[0]': 'Very low',
  'ea_mood.body[0].options[1]': 'Low',
  'ea_mood.body[0].options[2]': 'Okay',
  'ea_mood.body[0].options[3]': 'Good',
  'ea_mood.body[0].options[4]': 'Great',
  'ea_mood.body[0].label': 'How are you right now?',
  'ea_mood.body[1].options[0]': 'Work',
  'ea_mood.body[1].options[1]': 'Money',
  'ea_mood.body[1].options[2]': 'Family',
  'ea_mood.body[1].options[3]': 'Health',
  'ea_mood.body[1].options[4]': 'Lonely',
  'ea_mood.body[1].options[5]': 'Sleep',
  'ea_mood.body[1].options[6]': 'Thoughts of harming myself',
  'ea_mood.body[1].options[7]': 'Not sure',
  'ea_mood.body[1].label': 'What’s going on?',
  'ea_mood.body[2].eyebrow': 'Try now · 2 min',
  'ea_mood.body[2].title': 'Grounding: 5 things you can see',
  'ea_mood.body[2].cta[0].label': 'Start',
  'ea_mood.footer[0].action.then.cases[0].action.value': 'Saved',
  'ea_mood.footer[0].label': 'Save',
  'ea_mood.header.title': 'Mood check-in',
  'ea_checkback.body[0].text': 'It’s been two weeks. How are things?',
  'ea_checkback.body[1].options[0]': 'Worse',
  'ea_checkback.body[1].options[1]': 'Same',
  'ea_checkback.body[1].options[2]': 'Better',
  'ea_checkback.body[2].options[0]': 'Yes, I have an appointment',
  'ea_checkback.body[2].options[1]': 'Not yet',
  'ea_checkback.body[2].options[2]': 'I don’t want to',
  'ea_checkback.body[2].label': 'Did you reach out to someone?',
  'ea_checkback.body[3].text': 'That’s okay. Would a short list of what to say help?',
  'ea_checkback.body[3].cta[0].label': 'Show me',
  'ea_checkback.footer[0].action.then.value': 'Saved',
  'ea_checkback.footer[0].label': 'Save',
  'ea_checkback.header.title': 'Check-back',
  'ea_checkback.header.pill': '2 weeks',
  'ck_intro.body[0].extra': 'Preventive health',
  'ck_intro.body[1].text': 'What’s due for you, in one place.',
  'ck_intro.body[2].rows[0][0]': 'Personal list',
  'ck_intro.body[2].rows[0][1]': 'USPSTF / CDC guidance',
  'ck_intro.body[2].rows[1][0]': 'Reminders',
  'ck_intro.body[2].rows[1][1]': 'weekly, quiet',
  'ck_intro.body[2].rows[2][0]': 'Records',
  'ck_intro.body[2].rows[2][1]': 'mark done, add dates',
  'ck_intro.footer[0].label': 'Set up Checkup',
  'ck_intro.footer[1].action.then.value': 'Checkup added as Learn only',
  'ck_intro.footer[1].label': 'Add as Learn only',
  'ck_intro.header.pill': '~1 min/week',
  'ck_q1.body[1].text': 'A few details to personalize',
  'ck_q1.body[2].label': 'Age',
  'ck_q1.body[3].options[0]': 'Female',
  'ck_q1.body[3].options[1]': 'Male',
  'ck_q1.body[3].options[2]': 'Intersex',
  'ck_q1.body[3].options[3]': 'Skip',
  'ck_q1.body[3].label': 'Sex assigned at birth',
  'ck_q1.body[4].options[0]': 'Smoke or used to',
  'ck_q1.body[4].options[1]': 'Diabetes',
  'ck_q1.body[4].options[2]': 'Family history of cancer',
  'ck_q1.body[4].options[3]': 'Pregnant',
  'ck_q1.body[4].options[4]': 'None',
  'ck_q1.body[4].label': 'Any of these?',
  'ck_q1.body[5].text': 'Used only to build your list. Change anytime.',
  'ck_q1.body[6].label': 'Import vaccination history',
  'ck_q1.footer[0].label': 'Build my list',
  'ck_q1.header.title': 'About you',
  'ck_q1.header.pill': '1 of 1',
  'ck_list.body[0].text': '3 due, 1 to ask about',
  'ck_list.body[1].eyebrow': 'Due now',
  'ck_list.body[1].title': 'Flu vaccine',
  'ck_list.body[1].text': 'Every year · pharmacies offer walk-ins',
  'ck_list.body[1].children[0].items[0].label': 'Find a pharmacy',
  'ck_list.body[1].children[0].items[1].label': 'I got it',
  'ck_list.body[2].rows[0].label': 'Colorectal screening',
  'ck_list.body[2].rows[0].sub': 'Ages 45–75 · several options',
  'ck_list.body[2].rows[0].pill': 'Due',
  'ck_list.body[2].rows[1].label': 'Mammogram',
  'ck_list.body[2].rows[1].sub': 'Every 2 years, ages 40–74',
  'ck_list.body[2].rows[1].pill': 'Due',
  'ck_list.body[2].rows[2].label': 'Lung cancer screening',
  'ck_list.body[2].rows[2].sub': 'Ages 50–80 with smoking history',
  'ck_list.body[2].rows[2].pill': 'Ask',
  'ck_list.body[2].rows[3].label': 'Program settings',
  'ck_list.body[2].rows[3].sub': 'Status, sharing, export, leave',
  'ck_uptodate.body[1].text': 'You’re up to date',
  'ck_uptodate.body[2].text': 'Next: flu vaccine in Sep 2027. We’ll remind you a month before.',
  'ck_uptodate.body[3].label': 'See full schedule',
  'ck_item.body[0].text': 'Your options',
  'ck_item.body[1].text': 'All are recommended. Talk with your clinician about which fits.',
  'ck_item.body[2].rows[0][0]': 'Stool test (FIT)',
  'ck_item.body[2].rows[0][1]': 'at home · yearly',
  'ck_item.body[2].rows[1][0]': 'Stool DNA test',
  'ck_item.body[2].rows[1][1]': 'at home · every 1–3 yrs',
  'ck_item.body[2].rows[2][0]': 'Colonoscopy',
  'ck_item.body[2].rows[2][1]': 'clinic · every 10 yrs',
  'ck_item.body[3].title': 'Cost',
  'ck_item.body[3].text': 'Screening is often covered with no cost-sharing. Check with your insurer.',
  'ck_item.body[4].text': 'Source: USPSTF 2021 · reviewed Aug 2026',
  'ck_item.footer[0].label': 'Message my care team',
  'ck_item.footer[1].label': 'Mark as done',
  'ck_item.header.title': 'Colorectal screening',
  'ck_done.body[0].label': 'What',
  'ck_done.body[0].placeholder': 'Flu vaccine',
  'ck_done.body[1].label': 'Date',
  'ck_done.body[1].placeholder': 'Oct 12, 2026',
  'ck_done.body[2].label': 'Where (optional)',
  'ck_done.body[2].placeholder': 'Main St Pharmacy',
  'ck_done.body[3].items[0].label': 'Remind me next year',
  'ck_done.footer[0].action.then.value': 'Saved · next due Sep 2027',
  'ck_done.footer[0].label': 'Save',
  'ck_done.header.title': 'Mark as done',
  'ck_day.body[0].text': 'Mammogram tomorrow at 9:30 AM',
  'ck_day.body[1].children[0].items[0].label': 'Skip deodorant or powder',
  'ck_day.body[1].children[0].items[1].label': 'Wear a two-piece outfit',
  'ck_day.body[1].children[0].items[2].label': 'Bring ID and insurance card',
  'ck_day.body[2].title': 'Nervous?',
  'ck_day.body[2].text': 'It’s common. The scan takes about 20 minutes.',
  'ck_day.body[2].cta[0].label': '2-min breathing',
  'ck_day.footer[0].action.value': 'Added to your calendar',
  'ck_day.footer[0].label': 'Add to calendar',
  'ck_day.footer[1].label': 'Mark as done',
  'ck_day.header.title': 'Screening day',
  'ck_day.header.pill': 'Tomorrow',
  'be_intro.body[0].extra': 'Cancer',
  'be_intro.body[1].text': 'Lower your risk. Know your options.',
  'be_intro.body[2].rows[0][0]': 'Risk steps',
  'be_intro.body[2].rows[0][1]': 'smoking, sun, alcohol, activity',
  'be_intro.body[2].rows[1][0]': 'Screening',
  'be_intro.body[2].rows[1][1]': 'linked with Checkup',
  'be_intro.body[2].rows[2][0]': 'Treatment support',
  'be_intro.body[2].rows[2][1]': 'questions, side-effect diary',
  'be_intro.footer[0].label': 'Set up Beacon',
  'be_intro.footer[1].action.then.value': 'Beacon added as Learn only',
  'be_intro.footer[1].label': 'Add as Learn only',
  'be_intro.header.pill': '~1 min/week',
  'be_q1.body[1].text': 'Which fits you best?',
  'be_q1.body[2].items[0].label': 'Lowering my risk',
  'be_q1.body[2].items[0].sub': 'Prevention and screening',
  'be_q1.body[2].items[1].label': 'Going through treatment',
  'be_q1.body[2].items[1].sub': 'Support between appointments',
  'be_q1.body[2].items[2].label': 'After treatment',
  'be_q1.body[2].items[2].sub': 'Survivorship',
  'be_q1.body[2].items[3].label': 'Supporting someone',
  'be_q1.body[2].items[3].sub': 'Caregiver resources',
  'be_q1.footer[0].label': 'Next',
  'be_q1.header.title': 'Where are you?',
  'be_q1.header.pill': '1 of 2',
  'be_q2.body[1].text': 'Has a close relative had cancer?',
  'be_q2.body[2].options[0]': 'Breast',
  'be_q2.body[2].options[1]': 'Ovarian',
  'be_q2.body[2].options[2]': 'Colorectal',
  'be_q2.body[2].options[3]': 'Prostate',
  'be_q2.body[2].options[4]': 'Pancreatic',
  'be_q2.body[2].options[5]': 'Melanoma',
  'be_q2.body[2].options[6]': 'None',
  'be_q2.body[2].options[7]': 'Not sure',
  'be_q2.body[3].label': 'Relative’s age at diagnosis (if known)',
  'be_q2.body[4].text': 'A relative diagnosed before 50 may mean earlier screening or genetic counseling. We’ll add this to your visit list.',
  'be_q2.footer[0].label': 'See my plan',
  'be_q2.header.title': 'Family history',
  'be_q2.header.pill': '2 of 2',
  'be_home.body[0].text': 'Three steps that lower risk',
  'be_home.body[1].rows[0].label': 'Quitting smoking',
  'be_home.body[1].rows[0].sub': 'In progress with BreatheFree',
  'be_home.body[1].rows[0].pill': 'Active',
  'be_home.body[1].rows[1].label': 'Monthly skin self-check',
  'be_home.body[1].rows[1].sub': 'Guide with photos',
  'be_home.body[1].rows[2].label': 'Ask about genetic counseling',
  'be_home.body[1].rows[2].sub': 'Because of family history',
  'be_home.body[2].title': 'Screenings come from Checkup',
  'be_home.body[2].text': 'Mammogram due · colorectal due',
  'be_home.body[2].cta[0].label': 'Open Checkup',
  'be_home.body[3].rows[0].label': 'Change my journey stage',
  'be_home.body[3].rows[1].label': 'Program settings',
  'be_home.body[3].rows[1].sub': 'Status, sharing, export, leave',
  'be_tx.body[0].eyebrow': 'Next appointment',
  'be_tx.body[0].title': 'Oct 22 · Oncology · 10:30 AM',
  'be_tx.body[0].cta[0].label': 'Questions',
  'be_tx.body[1].title': 'Fever of 100.4°F (38°C) or higher during chemo?',
  'be_tx.body[1].text': 'Call your oncology team now, day or night.',
  'be_tx.body[1].cta[0].label': 'Call',
  'be_tx.body[2].rows[0].label': 'Today’s side-effect diary',
  'be_tx.body[2].rows[0].sub': 'About 1 minute',
  'be_tx.body[2].rows[1].label': 'Feeling worried?',
  'be_tx.body[2].rows[1].sub': 'Tools in Ease',
  'be_tx.body[2].rows[2].label': 'Program settings',
  'be_tx.body[2].rows[2].sub': 'Status, sharing, export, leave',
  'be_diary.body[0].text': 'How are you feeling today?',
  'be_diary.body[1].label': 'Fatigue',
  'be_diary.body[2].options[0]': 'Nausea',
  'be_diary.body[2].options[1]': 'Pain',
  'be_diary.body[2].options[2]': 'Mouth sores',
  'be_diary.body[2].options[3]': 'Numbness',
  'be_diary.body[2].options[4]': 'Low mood',
  'be_diary.body[2].label': 'Anything else?',
  'be_diary.body[3].title': 'Fever of 100.4°F (38°C) or higher?',
  'be_diary.body[3].text': 'Call your oncology team now.',
  'be_diary.body[3].cta[0].label': 'Call',
  'be_diary.footer[0].action.then.value': 'Saved',
  'be_diary.footer[0].label': 'Save',
  'be_diary.header.title': 'Treatment diary',
  'be_diary.header.pill': 'Treatment',
  'be_questions.body[0].children[0].items[0].label': 'What side effects should I call about?',
  'be_questions.body[0].children[0].items[1].label': 'Can I keep working during treatment?',
  'be_questions.body[0].children[0].items[2].label': 'Who do I call after hours?',
  'be_questions.body[1].label': 'Add a question',
  'be_questions.body[1].placeholder': 'Type a question…',
  'be_questions.footer[0].label': 'Share with my care team',
  'be_questions.footer[1].label': 'Done',
  'be_questions.header.title': 'Questions for my visit',
  'be_questions.header.pill': 'Oct 22',
  'be_survivor.body[0].text': 'How have the last 3 months been?',
  'be_survivor.body[1].options[0]': 'Hard',
  'be_survivor.body[1].options[1]': 'Mixed',
  'be_survivor.body[1].options[2]': 'Good',
  'be_survivor.body[2].title': 'Worried about it coming back?',
  'be_survivor.body[2].text': 'Very common. Ease has tools for this, and your team can help.',
  'be_survivor.body[2].cta[0].label': 'Open Ease',
  'be_survivor.body[3].rows[0][0]': 'Next follow-up',
  'be_survivor.body[3].rows[0][1]': 'Jan 14, 2027',
  'be_survivor.body[4].rows[0].label': 'Program settings',
  'be_survivor.footer[0].action.then.value': 'Saved',
  'be_survivor.footer[0].label': 'Save check-in',
  'records_hub.body[0].text': 'Read-only. Tether never writes to your health record, and each program only gets the data it needs.',
  'records_hub.body[1].rows[0].label': 'Patel Family Medicine',
  'records_hub.body[1].rows[0].sub': 'Epic MyChart · synced today 7:02 AM',
  'records_hub.body[1].rows[1].sub': 'Blue Button 2.0 · synced Oct 12',
  'records_hub.body[1].title': 'Connected sources',
  'records_hub.body[2].rows[0].label': 'Blood pressure',
  'records_hub.body[2].rows[0].sub': '12 readings · Heartwise',
  'records_hub.body[2].rows[1].label': 'Lab results',
  'records_hub.body[2].rows[1].sub': 'A1C, lipids, eGFR · Steady, Heartwise, Renew',
  'records_hub.body[2].rows[2].label': 'Immunizations',
  'records_hub.body[2].rows[2].sub': '6 · Checkup',
  'records_hub.body[2].rows[3].label': 'Smoking status',
  'records_hub.body[2].rows[3].sub': 'Every day smoker (Aug 2026) · BreatheFree',
  'records_hub.body[2].rows[4].label': 'Medications & conditions',
  'records_hub.body[2].rows[4].sub': 'Shown for reference only',
  'records_hub.body[2].title': 'Imported data',
  'records_hub.body[3].title': '2 items need your review',
  'records_hub.body[3].text': 'A value that differs from what you entered, and one that looks like a typo.',
  'records_hub.footer[0].label': 'Add a source',
  'records_hub.footer[1].label': 'Enter a value manually',
  'records_hub.header.title': 'Health records',
  'records_hub_empty.body[1].text': 'No health records connected',
  'records_hub_empty.body[2].text': 'Bring in readings, labs and vaccinations from your clinic or Medicare, or type them in. Your programs work either way.',
  'records_hub_empty.body[3].rows[0][1]': 'most US hospitals and clinics',
  'records_hub_empty.body[3].rows[1][1]': 'Blue Button 2.0',
  'records_hub_empty.body[3].rows[2][0]': 'Other',
  'records_hub_empty.body[3].rows[2][1]': 'any SMART on FHIR R4 server',
  'records_hub_empty.footer[0].label': 'Connect a health system',
  'records_hub_empty.footer[1].label': 'Enter a value manually',
  'records_hub_empty.header.title': 'Health records',
  'records_add.body[0].text': 'Where is your health information?',
  'records_add.body[1].text': 'You sign in with your provider. Tether never sees that password.',
  'records_add.body[2].rows[0].label': 'Hospital or clinic',
  'records_add.body[2].rows[0].sub': 'Epic MyChart · find yours',
  'records_add.body[2].rows[1].sub': 'Patient portal',
  'records_add.body[2].rows[2].label': 'Medicare · Blue Button 2.0',
  'records_add.body[2].rows[2].sub': 'Claims, prescriptions, diagnoses',
  'records_add.body[2].rows[3].sub': 'iPhone · records you already added to Health',
  'records_add.body[2].rows[4].sub': 'Android · readings from your devices',
  'records_add.body[2].rows[5].label': 'Other FHIR server',
  'records_add.body[2].rows[5].sub': 'Enter the address your provider gave you',
  'records_add.body[2].title': 'Connect',
  'records_add.body[3].rows[0].label': 'Enter manually',
  'records_add.body[3].rows[0].sub': 'Type a value from a paper report',
  'records_add.body[3].title': 'Or',
  'records_add.body[4].text': 'Uses SMART on FHIR R4 with OAuth 2.0 + PKCE in your phone’s browser.',
  'records_add.header.title': 'Add a source',
  'records_search.body[0].label': 'Search',
  'records_search.body[0].placeholder': 'Search hospital, clinic or doctor',
  'records_search.body[1].rows[0].label': 'Patel Family Medicine',
  'records_search.body[1].rows[0].sub': 'Epic · San Jose, CA',
  'records_search.body[1].rows[1].label': 'Patel Heart Institute',
  'records_search.body[1].rows[1].sub': 'Epic · Fremont, CA',
  'records_search.body[1].rows[2].label': 'Stanford Health Care',
  'records_search.body[1].rows[2].sub': 'Epic · Palo Alto, CA',
  'records_search.body[1].title': 'Results',
  'records_search.body[2].label': 'Can’t find it? Enter a FHIR address',
  'records_search.header.title': 'Find your provider',
  'records_fhir_url.body[0].text': 'Enter your provider’s FHIR address',
  'records_fhir_url.body[1].label': 'FHIR server address',
  'records_fhir_url.body[1].hint': 'Starts with https:// · your provider gives you this',
  'records_fhir_url.body[2].text': 'We check it supports SMART on FHIR R4 (/.well-known/smart-configuration) before you sign in.',
  'records_fhir_url.footer[0].label': 'Check and continue',
  'records_fhir_url.header.title': 'Other FHIR server',
  'records_consent.body[0].text': 'Connect Patel Family Medicine?',
  'records_consent.body[1].rows[0][0]': 'Source',
  'records_consent.body[1].rows[0][1]': 'Epic MyChart · SMART on FHIR R4',
  'records_consent.body[1].rows[1][0]': 'Access',
  'records_consent.body[1].rows[1][1]': 'Read-only',
  'records_consent.body[1].rows[2][0]': 'Refresh',
  'records_consent.body[1].rows[2][1]': 'Daily while connected',
  'records_consent.body[1].rows[3][0]': 'Stop',
  'records_consent.body[1].rows[3][1]': 'Disconnect anytime',
  'records_consent.body[2].items[0].label': 'Conditions',
  'records_consent.body[2].items[0].sub': 'Condition',
  'records_consent.body[2].items[1].label': 'Vital signs',
  'records_consent.body[2].items[1].sub': 'Observation · blood pressure, weight',
  'records_consent.body[2].items[2].label': 'Lab results',
  'records_consent.body[2].items[2].sub': 'Observation · A1C, lipids, eGFR',
  'records_consent.body[2].items[3].label': 'Medications',
  'records_consent.body[2].items[3].sub': 'MedicationRequest',
  'records_consent.body[2].items[4].label': 'Immunizations',
  'records_consent.body[2].items[4].sub': 'Immunization',
  'records_consent.body[2].items[5].label': 'Smoking status',
  'records_consent.body[2].items[5].sub': 'Observation · LOINC 72166-2',
  'records_consent.body[2].label': 'What Tether will read',
  'records_consent.body[3].rows[0].label': 'Clinical notes',
  'records_consent.body[3].rows[0].sub': 'Not requested',
  'records_consent.body[4].title': 'Only the programs you joined get data',
  'records_consent.body[4].text': 'Heartwise ← blood pressure, lipids · Steady ← A1C, glucose · Renew ← eGFR · Checkup ← immunizations · BreatheFree ← smoking status. Ease and ScrollFree get nothing.',
  'records_consent.footer[0].action.cases[0].action.cases[1].action.value': 'Connection cancelled. Nothing was imported.',
  'records_consent.footer[0].action.cases[1].action.value': 'Select at least one item to continue.',
  'records_consent.footer[0].label': 'Continue to MyChart',
  'records_consent.footer[1].label': 'Not now',
  'records_consent.header.title': 'Connect',
  'records_consent.header.pill': 'Read-only',
  'records_consent_bb.body[0].text': 'Connect Medicare?',
  'records_consent_bb.body[1].rows[0][0]': 'Source',
  'records_consent_bb.body[1].rows[0][1]': 'CMS Blue Button 2.0 · FHIR R4 (claims)',
  'records_consent_bb.body[1].rows[1][0]': 'Access',
  'records_consent_bb.body[1].rows[1][1]': 'Read-only',
  'records_consent_bb.body[1].rows[2][0]': 'Refresh',
  'records_consent_bb.body[1].rows[2][1]': 'Daily while connected',
  'records_consent_bb.body[1].rows[3][0]': 'Stop',
  'records_consent_bb.body[1].rows[3][1]': 'Disconnect anytime',
  'records_consent_bb.body[2].items[0].label': 'Conditions',
  'records_consent_bb.body[2].items[0].sub': 'Condition',
  'records_consent_bb.body[2].items[1].label': 'Vital signs',
  'records_consent_bb.body[2].items[1].sub': 'Observation · blood pressure, weight',
  'records_consent_bb.body[2].items[2].label': 'Lab results',
  'records_consent_bb.body[2].items[2].sub': 'Observation · A1C, lipids, eGFR',
  'records_consent_bb.body[2].items[3].label': 'Medications',
  'records_consent_bb.body[2].items[3].sub': 'MedicationRequest',
  'records_consent_bb.body[2].items[4].label': 'Immunizations',
  'records_consent_bb.body[2].items[4].sub': 'Immunization',
  'records_consent_bb.body[2].items[5].label': 'Smoking status',
  'records_consent_bb.body[2].items[5].sub': 'Observation · LOINC 72166-2',
  'records_consent_bb.body[2].label': 'What Tether will read',
  'records_consent_bb.body[3].rows[0].label': 'Clinical notes',
  'records_consent_bb.body[3].rows[0].sub': 'Not requested',
  'records_consent_bb.body[4].title': 'Only the programs you joined get data',
  'records_consent_bb.body[4].text': 'Heartwise ← blood pressure, lipids · Steady ← A1C, glucose · Renew ← eGFR · Checkup ← immunizations · BreatheFree ← smoking status. Ease and ScrollFree get nothing.',
  'records_consent_bb.footer[0].action.cases[0].action.cases[1].action.value': 'Connection cancelled. Nothing was imported.',
  'records_consent_bb.footer[0].action.cases[1].action.value': 'Select at least one item to continue.',
  'records_consent_bb.footer[0].label': 'Continue to Medicare.gov',
  'records_consent_bb.footer[1].label': 'Not now',
  'records_consent_bb.header.title': 'Connect',
  'records_consent_bb.header.pill': 'Read-only',
  'records_consent_device.body[0].text': 'Use health data on this phone?',
  'records_consent_device.body[1].text': 'iPhone: Apple Health Records (FHIR) and readings. Android: Health Connect readings. You choose each type in the system screen next.',
  'records_consent_device.body[2].items[0].label': 'Blood pressure',
  'records_consent_device.body[2].items[1].label': 'Blood glucose',
  'records_consent_device.body[2].items[2].label': 'Clinical records (iPhone)',
  'records_consent_device.body[2].items[2].sub': 'Labs, immunizations, conditions',
  'records_consent_device.body[2].label': 'What Tether will ask for',
  'records_consent_device.body[3].rows[0].label': 'Steps and sleep',
  'records_consent_device.body[3].rows[0].sub': 'Not requested',
  'records_consent_device.footer[0].action.cases[1].action.value': 'Select at least one item to continue.',
  'records_consent_device.footer[0].label': 'Continue',
  'records_consent_device.footer[1].label': 'Not now',
  'records_consent_device.header.title': 'Connect',
  'records_consent_device.header.pill': 'Read-only',
  'records_importing.body[0].text': 'Importing your records…',
  'records_importing.body[1].text': 'Usually under a minute. You can leave this screen.',
  'records_importing.body[2].children[0].items[0].label': 'Conditions',
  'records_importing.body[2].children[0].items[0].sub': '4 found',
  'records_importing.body[2].children[0].items[1].label': 'Vital signs',
  'records_importing.body[2].children[0].items[1].sub': '12 blood pressure readings',
  'records_importing.body[2].children[0].items[2].label': 'Lab results',
  'records_importing.body[2].children[0].items[2].sub': '9 results',
  'records_importing.body[2].children[0].items[3].label': 'Immunizations',
  'records_importing.body[2].children[0].items[3].sub': 'Checking…',
  'records_importing.body[2].children[0].items[4].label': 'Smoking status',
  'records_importing.body[2].children[0].items[4].sub': 'Waiting',
  'records_importing.footer[0].label': 'Review imported data',
  'records_importing.footer[1].label': 'Cancel import',
  'records_importing.header.title': 'Importing',
  'records_review.body[0].text': 'Review before adding',
  'records_review.body[1].text': 'Nothing reaches your programs until you confirm.',
  'records_review.body[2].text': '2 items need your review.',
  'records_review.body[2].actionLabel': 'Review',
  'records_review.body[3].children[0].items[0].label': '12 blood pressure readings',
  'records_review.body[3].children[0].items[0].sub': 'Jun – Oct 2026',
  'records_review.body[3].children[0].items[1].label': 'Lipid panel',
  'records_review.body[3].children[0].items[1].sub': 'LDL 138 · Sep 30',
  'records_review.body[4].children[0].items[0].label': 'A1C 7.6%',
  'records_review.body[4].children[0].items[0].sub': 'Oct 1 · differs from your entry (7.4%)',
  'records_review.body[5].children[0].items[0].label': 'Flu vaccine',
  'records_review.body[5].children[0].items[0].sub': 'Oct 12, 2025',
  'records_review.body[5].children[0].items[1].label': 'Tdap',
  'records_review.body[6].children[0].items[0].label': 'Smoking status: every day smoker',
  'records_review.body[6].children[0].items[0].sub': 'Aug 2026 · sets your baseline',
  'records_review.body[7].children[0].items[0].label': 'eGFR 58',
  'records_review.body[7].children[0].items[0].sub': 'Oct 3',
  'records_review.body[8].text': 'Checked automatically',
  'records_review.body[9].rows[0][0]': 'Units converted',
  'records_review.body[9].rows[0][1]': '2 glucose results · mmol/L → mg/dL',
  'records_review.body[9].rows[1][0]': 'Duplicates skipped',
  'records_review.body[9].rows[1][1]': '3 readings you already entered',
  'records_review.body[9].rows[2][0]': 'Held as likely typo',
  'records_review.body[9].rows[2][1]': '1 · BP 1290/80',
  'records_review.body[9].rows[3][0]': 'Future dates rejected',
  'records_review.footer[0].action.cases[0].action.then.value': 'Added to your programs',
  'records_review.footer[0].action.cases[1].action.value': 'Select the items you want to add.',
  'records_review.footer[0].label': 'Add selected items to my programs',
  'records_review.footer[1].label': 'Review conflicts first',
  'records_review.header.title': 'Review',
  'records_review.header.pill': 'Not added yet',
  'records_conflict.body[0].eyebrow': 'A1C · Oct 1, 2026',
  'records_conflict.body[0].title': 'Two values for the same test',
  'records_conflict.body[0].children[0].items[0].label': 'From Patel Family Medicine (Epic): 7.6%',
  'records_conflict.body[0].children[0].items[0].sub': 'Lab result · final · LOINC 4548-4',
  'records_conflict.body[0].children[0].items[1].label': 'Entered by you: 7.4%',
  'records_conflict.body[0].children[0].items[1].sub': 'Oct 1, 2026',
  'records_conflict.body[0].children[0].items[2].label': 'Keep both',
  'records_conflict.body[0].children[0].items[2].sub': 'Your clinician’s value is used in summaries',
  'records_conflict.body[1].eyebrow': 'Blood pressure · Aug 4, 2026',
  'records_conflict.body[1].title': '1290/80 is outside the possible range',
  'records_conflict.body[1].children[0].items[0].label': 'Discard',
  'records_conflict.body[1].children[0].items[0].sub': 'Likely a typo in the source',
  'records_conflict.body[1].children[0].items[1].label': 'Keep as 129/80',
  'records_conflict.body[1].children[0].items[1].sub': 'Corrected by you, marked as edited',
  'records_conflict.body[1].children[0].items[2].label': 'Ask my care team',
  'records_conflict.body[1].children[0].items[2].sub': 'Sends a question with the original value',
  'records_conflict.footer[0].action.cases[0].action.then.value': 'Saved',
  'records_conflict.footer[0].action.cases[1].action.value': 'Choose an option for at least one item.',
  'records_conflict.footer[0].label': 'Save choices',
  'records_conflict.header.title': 'Needs review',
  'records_conflict.header.pill': '2 items',
  'records_error.body[1].text': 'Couldn’t connect',
  'records_error.body[2].text': 'Sign-in was cancelled, denied, or the server isn’t a SMART on FHIR R4 server. Nothing was imported.',
  'records_error.footer[0].label': 'Try again',
  'records_error.footer[1].label': 'Choose another source',
  'records_error.footer[2].label': 'Enter manually instead',
  'records_error.header.title': 'Connect',
  'records_source.body[0].rows[0][0]': 'Connection',
  'records_source.body[0].rows[0][1]': 'Epic MyChart · SMART on FHIR R4',
  'records_source.body[0].rows[1][0]': 'Last sync',
  'records_source.body[0].rows[1][1]': 'Today 7:02 AM',
  'records_source.body[0].rows[2][0]': 'Next sync',
  'records_source.body[0].rows[2][1]': 'Tomorrow',
  'records_source.body[0].rows[3][0]': 'Access',
  'records_source.body[0].rows[3][1]': 'Read-only · 6 categories',
  'records_source.body[0].rows[4][0]': 'Connected',
  'records_source.body[0].rows[4][1]': 'Oct 3, 2026',
  'records_source.body[1].rows[0].label': 'Sync now',
  'records_source.body[1].rows[0].action.then.value': 'Synced · 2 new results',
  'records_source.body[2].rows[0].label': 'Conditions',
  'records_source.body[2].rows[0].sub': 'Condition',
  'records_source.body[2].rows[1].label': 'Vital signs',
  'records_source.body[2].rows[1].sub': 'Observation · blood pressure, weight',
  'records_source.body[2].rows[2].label': 'Lab results',
  'records_source.body[2].rows[2].sub': 'Observation · A1C, lipids, eGFR',
  'records_source.body[2].rows[3].label': 'Medications',
  'records_source.body[2].rows[3].sub': 'MedicationRequest',
  'records_source.body[2].rows[4].label': 'Immunizations',
  'records_source.body[2].rows[4].sub': 'Immunization',
  'records_source.body[2].rows[5].label': 'Smoking status',
  'records_source.body[2].rows[5].sub': 'Observation · LOINC 72166-2',
  'records_source.body[2].title': 'What we read',
  'records_source.footer[0].label': 'Disconnect',
  'records_source.header.title': 'Patel Family Medicine',
  'records_disconnect.body[0].text': 'Disconnect Patel Family Medicine?',
  'records_disconnect.body[1].text': 'Tether stops reading new records and revokes its access token.',
  'records_disconnect.body[2].items[0].label': 'Keep imported data',
  'records_disconnect.body[2].items[0].sub': 'Marked “from Patel Family Medicine”',
  'records_disconnect.body[2].items[1].label': 'Delete data imported from this source',
  'records_disconnect.body[2].items[1].sub': '21 items removed from your programs',
  'records_disconnect.footer[0].action.then.value': 'Disconnected',
  'records_disconnect.footer[0].label': 'Disconnect source',
  'records_disconnect.footer[1].label': 'Cancel',
  'records_manual.body[0].text': 'Add a health value',
  'records_manual.body[1].options[0]': 'Blood pressure',
  'records_manual.body[1].options[1]': 'Glucose',
  'records_manual.body[1].options[2]': 'Lab result',
  'records_manual.body[1].options[3]': 'Vaccine',
  'records_manual.body[1].options[4]': 'Medication',
  'records_manual.body[1].options[5]': 'Condition',
  'records_manual.body[1].label': 'Type',
  'records_manual.body[2].label': 'Test',
  'records_manual.body[2].placeholder': 'A1C',
  'records_manual.body[3].label': 'Value',
  'records_manual.body[4].label': 'Date',
  'records_manual.body[4].placeholder': 'Oct 1, 2026',
  'records_manual.body[5].text': 'Checked against plausible ranges and your connected records. Manual values are labelled “Entered by you”.',
  'records_manual.footer[0].action.then.cases[0].action.value': 'Saved · shared with Steady',
  'records_manual.footer[0].action.then.cases[2].action.value': 'Already in your records from Epic. Not added twice.',
  'records_manual.footer[0].label': 'Save',
  'records_manual.header.title': 'Enter a value',
  'records_manual_error.body[0].text': 'Add a health value',
  'records_manual_error.body[1].label': 'Test',
  'records_manual_error.body[1].placeholder': 'A1C',
  'records_manual_error.body[2].label': 'Value',
  'records_manual_error.body[2].error': 'A1C is usually between 4% and 15%. Did you mean 7.4?',
  'records_manual_error.body[3].label': 'Date',
  'records_manual_error.body[3].placeholder': 'Oct 1, 2026',
  'records_manual_error.footer[0].action.then.cases[0].action.value': 'Saved · shared with Steady',
  'records_manual_error.footer[0].action.then.cases[1].action.value': 'Still outside the expected range',
  'records_manual_error.footer[0].label': 'Save',
  'records_manual_error.footer[1].label': 'Ask my care team instead',
  'records_manual_error.header.title': 'Enter a value',
  'records_item.body[0].title': 'Systolic · all sources',
  'records_item.body[1].rows[0].label': '128/82 · Oct 15',
  'records_item.body[1].rows[0].sub': 'Patel Family Medicine (Epic) · clinic reading',
  'records_item.body[1].rows[1].label': '135/85 · Oct 14',
  'records_item.body[1].rows[1].sub': 'Entered by you · home monitor',
  'records_item.body[1].rows[2].label': '131/80 · Oct 2',
  'records_item.body[1].rows[2].sub': 'Patel Family Medicine (Epic)',
  'records_item.body[1].title': 'Latest',
  'records_item.body[2].rows[0][0]': 'Coded as',
  'records_item.body[2].rows[0][1]': 'LOINC 85354-9 (8480-6 / 8462-4)',
  'records_item.body[2].rows[1][0]': 'Used by',
  'records_item.footer[0].label': 'Open in Heartwise',
  'records_item.header.title': 'Blood pressure',
  'sf_unplug_intro.body[1].text': 'Pause the apps you choose, when you choose.',
  'sf_unplug_intro.body[2].text': 'Unplug is optional. It adds a pause screen to apps you pick, after limits you set. Pause 60 stays the same: a moment to check in, never a lock.',
  'sf_unplug_intro.body[3].rows[0][0]': 'Can',
  'sf_unplug_intro.body[3].rows[0][1]': 'Pause apps you pick, after your limits',
  'sf_unplug_intro.body[3].rows[1][0]': 'Can’t',
  'sf_unplug_intro.body[3].rows[1][1]': 'See what you do inside any app',
  'sf_unplug_intro.body[3].rows[2][0]': 'On iPhone',
  'sf_unplug_intro.body[3].rows[2][1]': 'Apple doesn’t share app names or minutes with Tether',
  'sf_unplug_intro.body[3].rows[3][0]': 'Stays',
  'sf_unplug_intro.body[3].rows[3][1]': 'On this phone. Your app list never reaches Tether',
  'sf_unplug_intro.body[3].rows[4][0]': 'Never paused',
  'sf_unplug_intro.body[3].rows[4][1]': 'Tether, phone calls and emergency calls',
  'sf_unplug_intro.footer[0].label': 'Set up Unplug',
  'sf_unplug_intro.footer[1].label': 'Not now',
  'sf_unplug_intro.header.pill': 'Optional',
  'sf_unplug_auth.body[1].text': 'Allow Screen Time for Unplug',
  'sf_unplug_auth.body[2].text': 'Apple will ask you to let Tether Health use Screen Time. This lets Unplug pause apps. It doesn’t let Tether see what you do in them.',
  'sf_unplug_auth.body[3].rows[0][0]': 'Lets Unplug',
  'sf_unplug_auth.body[3].rows[0][1]': 'Pause apps you choose',
  'sf_unplug_auth.body[3].rows[1][0]': 'Never shares',
  'sf_unplug_auth.body[3].rows[1][1]': 'App names, content, messages',
  'sf_unplug_auth.body[3].rows[2][0]': 'Turn off',
  'sf_unplug_auth.body[3].rows[2][1]': 'Anytime in Account → ScrollFree',
  'sf_unplug_auth.footer[0].label': 'Continue',
  'sf_unplug_auth.footer[1].label': 'Not now',
  'sf_unplug_auth.header.pill': 'Step 1 of 3',
  'sf_unplug_auth_denied.body[0].text': 'Screen Time access was not allowed.',
  'sf_unplug_auth_denied.body[1].text': 'Unplug needs Screen Time to pause apps.',
  'sf_unplug_auth_denied.body[2].text': 'Everything else in ScrollFree works without it: your goal, Pause 60 and check-ins.',
  'sf_unplug_auth_denied.footer[0].action.cases[1].action.value': 'Still not allowed. You can turn it on later in Settings.',
  'sf_unplug_auth_denied.footer[0].label': 'Try again',
  'sf_unplug_auth_denied.footer[1].label': 'Open phone settings',
  'sf_unplug_auth_denied.footer[2].label': 'Not now',
  'sf_unplug_auth_denied.header.pill': 'Step 1 of 3',
  'sf_unplug_auth_unavailable.body[0].text': 'Screen Time isn’t available on this phone.',
  'sf_unplug_auth_unavailable.body[1].text': 'Unplug can’t run here.',
  'sf_unplug_auth_unavailable.body[2].text': 'This can happen when Screen Time is managed by an organization or limited by a parent. ScrollFree still works without Unplug.',
  'sf_unplug_auth_unavailable.footer[0].label': 'Back to ScrollFree',
  'sf_unplug_auth_unavailable.header.pill': 'Optional',
  'sf_unplug_auth_notifications.body[0].text': 'Notifications are off for Tether.',
  'sf_unplug_auth_notifications.body[1].text': 'Turn on notifications for Unplug?',
  'sf_unplug_auth_notifications.body[2].text': 'When a pause screen sends you to Tether, including Get support, it uses a notification. With notifications off, Unplug still pauses apps, and the pause screen tells you to open Tether yourself for support.',
  'sf_unplug_auth_notifications.footer[0].label': 'Open phone settings',
  'sf_unplug_auth_notifications.footer[1].action.cases[2].action.value': 'Notifications are still off. You can turn them on later in Settings.',
  'sf_unplug_auth_notifications.footer[1].label': 'Check again',
  'sf_unplug_auth_notifications.footer[2].label': 'Continue without notifications',
  'sf_unplug_auth_notifications.header.pill': 'Step 1 of 3',
  'sf_unplug_auth_android.body[0].text': 'Two Android settings for Unplug',
  'sf_unplug_auth_android.body[1].text': 'Android asks for each one separately. You can turn either off later, and Unplug will tell you if it stops working.',
  'sf_unplug_auth_android.body[2].items[0].label': 'Usage access',
  'sf_unplug_auth_android.body[2].items[0].sub': 'On · lets Unplug see which app is open and for how long',
  'sf_unplug_auth_android.body[2].items[1].label': 'Display over other apps',
  'sf_unplug_auth_android.body[2].items[1].sub': 'Off · lets Unplug show the pause screen',
  'sf_unplug_auth_android.body[2].items[2].label': 'Notifications',
  'sf_unplug_auth_android.body[2].items[2].sub': 'Android shows a quiet “Tether is running” notice while Unplug is on',
  'sf_unplug_auth_android.body[2].label': 'Needed',
  'sf_unplug_auth_android.footer[0].label': 'Turn on display over apps',
  'sf_unplug_auth_android.footer[1].label': 'Turn on usage access',
  'sf_unplug_auth_android.footer[2].label': 'I’ve turned them on',
  'sf_unplug_auth_android.footer[2].action.cases[2].action.value': 'Unplug still needs both settings.',
  'sf_unplug_auth_android.header.pill': 'Step 1 of 3',
  'sf_unplug_apps.body[0].text': 'Which apps should Unplug pause?',
  'sf_unplug_apps.body[1].text': 'Apple’s app picker opens next. Tether never sees which apps you pick: Apple keeps that choice on this phone.',
  'sf_unplug_apps.body[2].title': 'Start small',
  'sf_unplug_apps.body[2].text': 'One or two apps that pull you in most is a good start. You can change this anytime.',
  'sf_unplug_apps.body[3].text': 'Tether, the phone dialer and emergency calling can never be chosen or paused.',
  'sf_unplug_apps.footer[0].label': 'Open app picker',
  'sf_unplug_apps.footer[1].label': 'Not now',
  'sf_unplug_apps.header.title': 'Choose apps',
  'sf_unplug_apps.header.pill': 'Step 2 of 3',
  'sf_unplug_picker_ios.body[0].label': 'Apple’s app picker',
  'sf_unplug_picker_ios.footer[0].label': 'Done',
  'sf_unplug_picker_ios.footer[1].label': 'Cancel',
  'sf_unplug_apps_android.body[0].text': 'Choose the apps to pause',
  'sf_unplug_apps_android.body[1].text': 'This choice stays on this phone. Tether never receives it.',
  'sf_unplug_apps_android.body[2].items[0].label': 'Short-video app',
  'sf_unplug_apps_android.body[2].items[1].label': 'Photo feed app',
  'sf_unplug_apps_android.body[2].items[2].label': 'Video app',
  'sf_unplug_apps_android.body[2].items[3].label': 'News app',
  'sf_unplug_apps_android.body[2].items[4].label': 'Games app',
  'sf_unplug_apps_android.body[2].items[5].label': 'Shopping app',
  'sf_unplug_apps_android.body[2].label': 'Apps on this phone',
  'sf_unplug_apps_android.body[3].text': 'Tether, the Phone app and emergency calling aren’t in this list. They can never be paused.',
  'sf_unplug_apps_android.footer[0].label': 'Done · 3 apps',
  'sf_unplug_apps_android.footer[1].label': 'Cancel',
  'sf_unplug_apps_android.header.title': 'Choose apps',
  'sf_unplug_apps_android.header.pill': 'Step 2 of 3',
  'sf_unplug_apps_chosen.body[0].text': 'Name your groups',
  'sf_unplug_apps_chosen.body[1].text': 'iPhone doesn’t tell Tether the app names, so give each group a name you’ll recognize. Group names stay on this phone.',
  'sf_unplug_apps_chosen.body[2].rows[0].label': 'Video apps',
  'sf_unplug_apps_chosen.body[2].rows[0].sub': '3 apps',
  'sf_unplug_apps_chosen.body[2].rows[1].label': 'Feeds',
  'sf_unplug_apps_chosen.body[2].rows[1].sub': '2 apps',
  'sf_unplug_apps_chosen.body[2].title': 'Your groups',
  'sf_unplug_apps_chosen.body[3].label': 'New group name',
  'sf_unplug_apps_chosen.body[3].placeholder': 'e.g. Games',
  'sf_unplug_apps_chosen.body[4].label': 'Add another group',
  'sf_unplug_apps_chosen.footer[0].label': 'Next: limits',
  'sf_unplug_apps_chosen.header.title': 'Choose apps',
  'sf_unplug_apps_chosen.header.pill': 'Step 2 of 3',
  'sf_unplug_limits.body[0].text': 'When should Unplug step in?',
  'sf_unplug_limits.body[1].children[0].label': 'Daily time in these apps',
  'sf_unplug_limits.body[1].children[0].minLabel': '15 min',
  'sf_unplug_limits.body[1].children[0].maxLabel': '4 h',
  'sf_unplug_limits.body[1].children[1].label': 'Opens a day',
  'sf_unplug_limits.body[1].children[2].text': 'On iPhone, opens are counted from pause screens shown, so the number is approximate.',
  'sf_unplug_limits.body[2].items[0].label': 'Notice only',
  'sf_unplug_limits.body[2].items[0].sub': 'Count time, no pause screen',
  'sf_unplug_limits.body[2].items[1].label': 'Pause screen',
  'sf_unplug_limits.body[2].items[1].sub': 'A pause before the app opens',
  'sf_unplug_limits.body[2].items[2].label': 'Pause and one small step',
  'sf_unplug_limits.body[2].items[2].sub': 'A breath, a typed sentence or a quick sum first',
  'sf_unplug_limits.body[2].items[2].badge': 'Suggested',
  'sf_unplug_limits.body[2].items[3].label': 'Firm',
  'sf_unplug_limits.body[2].items[3].sub': 'No “open anyway” until tomorrow',
  'sf_unplug_limits.body[2].label': 'When you reach a limit',
  'sf_unplug_limits.body[3].options[0]': 'One breath',
  'sf_unplug_limits.body[3].options[1]': 'Type a sentence',
  'sf_unplug_limits.body[3].options[2]': 'Quick sum',
  'sf_unplug_limits.body[3].label': 'Small step',
  'sf_unplug_limits.body[4].label': '“Open anyway” per day',
  'sf_unplug_limits.body[5].text': 'Stricter limits apply now. Looser limits start tomorrow, so one hard moment doesn’t change your plan.',
  'sf_unplug_limits.body[6].text': 'Every pause screen has a Get support button. Tether, the phone dialer and emergency calling can never be chosen or paused.',
  'sf_unplug_limits.footer[0].action.then.value': 'Unplug is on',
  'sf_unplug_limits.footer[0].label': 'Save limits',
  'sf_unplug_limits.header.title': 'Limits',
  'sf_unplug_limits.header.pill': 'Step 3 of 3',
  'sf_unplug_home.body[0].title': 'Unplug is on',
  'sf_unplug_home.body[0].text': '5 apps in 2 groups · pause screen after 60 min or 20 opens',
  'sf_unplug_home.body[1].eyebrow': 'Focus session',
  'sf_unplug_home.body[1].title': 'Need to focus?',
  'sf_unplug_home.body[1].text': 'Pause your chosen apps for a set time',
  'sf_unplug_home.body[1].cta[0].label': 'Start',
  'sf_unplug_home.body[2].rows[0].label': 'Apps',
  'sf_unplug_home.body[2].rows[0].sub': 'Video apps · 3, Feeds · 2',
  'sf_unplug_home.body[2].rows[1].label': 'Limits & pause screen',
  'sf_unplug_home.body[2].rows[1].sub': '60 min · 20 opens · one breath first',
  'sf_unplug_home.body[2].rows[2].label': 'Preview the pause screen',
  'sf_unplug_home.body[2].rows[2].sub': 'iPhone shield or Android overlay',
  'sf_unplug_home.body[2].rows[3].label': 'Tracking check',
  'sf_unplug_home.body[2].rows[3].sub': 'All checks pass',
  'sf_unplug_home.body[2].title': 'Settings',
  'sf_unplug_home.body[3].rows[0].label': 'How Unplug works',
  'sf_unplug_home.body[3].rows[0].sub': 'What it can and can’t see',
  'sf_unplug_home.body[3].rows[1].label': 'Turn off Unplug',
  'sf_unplug_home.body[3].rows[1].sub': 'Paused apps open normally again',
  'sf_unplug_home.header.pill': 'On',
  'sf_unplug_session.body[0].text': 'Pause your apps for a while.',
  'sf_unplug_session.body[1].options[0]': '25 min',
  'sf_unplug_session.body[1].options[1]': '45 min',
  'sf_unplug_session.body[1].options[2]': '60 min',
  'sf_unplug_session.body[1].options[3]': '90 min',
  'sf_unplug_session.body[1].label': 'How long',
  'sf_unplug_session.body[2].items[0].label': 'Only my chosen apps',
  'sf_unplug_session.body[2].items[0].sub': 'Video apps, Feeds',
  'sf_unplug_session.body[2].items[1].label': 'Everything except apps I allow',
  'sf_unplug_session.body[2].items[1].sub': 'Tether, phone calls and emergency calls always stay open',
  'sf_unplug_session.body[2].label': 'What to pause',
  'sf_unplug_session.body[3].children[0].label': 'Strict',
  'sf_unplug_session.body[3].children[0].sub': 'Ending early asks for a reason, kept on this phone',
  'sf_unplug_session.footer[0].label': 'Start session',
  'sf_unplug_session.header.title': 'Focus session',
  'sf_unplug_session_active.body[0].label': 'left of 45 min · until 3:45 PM',
  'sf_unplug_session_active.body[1].text': 'Video apps and Feeds are paused. Tether, phone calls and emergency calls stay open.',
  'sf_unplug_session_active.body[2].title': 'Urge to check?',
  'sf_unplug_session_active.body[2].text': 'Take 60 seconds first',
  'sf_unplug_session_active.body[2].cta[0].label': 'Pause 60',
  'sf_unplug_session_active.footer[0].label': 'End early',
  'sf_unplug_session_active.header.title': 'Focus session',
  'sf_unplug_session_active.header.pill': 'Strict',
  'sf_unplug_session_end.body[0].text': 'End your session early?',
  'sf_unplug_session_end.body[1].text': 'This is a strict session. Choose or type a reason; it is kept with the session on this phone. Nothing resets.',
  'sf_unplug_session_end.body[2].options[0]': 'Need an app for work',
  'sf_unplug_session_end.body[2].options[1]': 'Expecting a message',
  'sf_unplug_session_end.body[2].options[2]': 'Changed my mind',
  'sf_unplug_session_end.body[2].options[3]': 'Other',
  'sf_unplug_session_end.body[2].label': 'Reason',
  'sf_unplug_session_end.body[3].label': 'Anything to add?',
  'sf_unplug_session_end.body[3].placeholder': 'Optional',
  'sf_unplug_session_end.footer[0].action.cases[1].action.value': 'Choose or type a reason to end a strict session.',
  'sf_unplug_session_end.footer[0].label': 'End session',
  'sf_unplug_session_end.footer[1].label': 'Keep going',
  'sf_unplug_session_done.body[1].caption': 'Session complete · your apps are open again',
  'sf_unplug_session_done.body[2].text': 'Want to make this a habit? You can start one from ScrollFree anytime.',
  'sf_unplug_session_done.footer[0].label': 'Done',
  'sf_unplug_session_done.header.title': 'Focus session',
  'sf_unplug_session_done_early.body[0].caption': 'Ended early · your apps are open again',
  'sf_unplug_session_done_early.body[1].rows[0][0]': 'Reason',
  'sf_unplug_session_done_early.body[1].rows[0][1]': 'Expecting a message',
  'sf_unplug_session_done_early.body[1].rows[1][0]': 'Kept',
  'sf_unplug_session_done_early.body[1].rows[1][1]': 'On this phone only',
  'sf_unplug_session_done_early.body[2].text': 'Nothing resets. 18 focused minutes still count.',
  'sf_unplug_session_done_early.footer[0].label': 'Done',
  'sf_unplug_session_done_early.header.title': 'Focus session',
  'sf_unplug_shield.body[2].text': 'Paused for a moment',
  'sf_unplug_shield.body[3].text': 'You asked to slow this one down. Video apps is on your list. 2 of 3 “open anyway” left today. Open Tether for support.',
  'sf_unplug_shield.footer[0].action.value': 'Notification: open Tether to take your breath, or get support',
  'sf_unplug_shield.footer[0].label': 'Take a breath',
  'sf_unplug_shield.footer[1].label': 'Open anyway',
  'sf_unplug_shield.footer[1].action.value': 'Opened · 1 “open anyway” left today',
  'sf_unplug_shield_firm.body[2].text': 'Paused for a moment',
  'sf_unplug_shield_firm.body[3].text': 'You asked to slow this one down. Video apps is on your list. No “open anyway” left today. Open Tether for support.',
  'sf_unplug_shield_firm.footer[0].action.value': 'The app stays closed.',
  'sf_unplug_shield_firm.footer[0].label': 'Close the app',
  'sf_unplug_shield_firm.footer[1].label': 'Get support',
  'sf_unplug_shield_firm.footer[1].action.value': 'Notification: tap to open Rescue in Tether',
  'sf_unplug_overlay.body[1].text': 'Paused for a moment',
  'sf_unplug_overlay.body[2].text': 'You asked to slow this one down. Video apps is on your list.',
  'sf_unplug_overlay.body[4].text': 'Breathe with the circle. 2 of 3 “open anyway” left today.',
  'sf_unplug_overlay.footer[0].action.value': 'The app stays closed.',
  'sf_unplug_overlay.footer[0].label': 'Close the app',
  'sf_unplug_overlay.footer[1].label': 'Get support',
  'sf_unplug_overlay.footer[2].label': 'Open anyway',
  'sf_unplug_overlay.footer[2].action.value': 'Opened · 1 “open anyway” left today',
  'sf_unplug_gate.body[0].text': 'One breath, then decide.',
  'sf_unplug_gate.body[2].text': 'Breathe in as the circle grows, out as it shrinks.',
  'sf_unplug_gate.body[3].title': 'Need help right now?',
  'sf_unplug_gate.body[3].text': 'Rescue opens in one tap.',
  'sf_unplug_gate.body[3].cta[0].label': 'Get support',
  'sf_unplug_gate.footer[0].action.value': 'Nice. The app stays closed.',
  'sf_unplug_gate.footer[0].label': 'Keep it closed',
  'sf_unplug_gate.footer[1].label': 'Open it for 10 minutes',
  'sf_unplug_gate.footer[1].action.value': 'Open for 10 minutes. The pause screen comes back after.',
  'sf_unplug_gate.header.title': 'Small step',
  'sf_unplug_gate_commit.body[0].text': 'Type it out, then decide.',
  'sf_unplug_gate_commit.body[1].text': '“I can come back to this later”',
  'sf_unplug_gate_commit.body[2].label': 'Type the sentence',
  'sf_unplug_gate_commit.body[2].placeholder': 'I can come back to this later',
  'sf_unplug_gate_commit.body[3].title': 'Need help right now?',
  'sf_unplug_gate_commit.body[3].text': 'Rescue opens in one tap.',
  'sf_unplug_gate_commit.body[3].cta[0].label': 'Get support',
  'sf_unplug_gate_commit.footer[0].action.value': 'Nice. The app stays closed.',
  'sf_unplug_gate_commit.footer[0].label': 'Keep it closed',
  'sf_unplug_gate_commit.footer[1].label': 'Open it for 10 minutes',
  'sf_unplug_gate_commit.footer[1].action.cases[0].action.value': 'Open for 10 minutes. The pause screen comes back after.',
  'sf_unplug_gate_commit.footer[1].action.cases[1].action.value': 'Type the whole sentence first.',
  'sf_unplug_gate_commit.header.title': 'Small step',
  'sf_unplug_gate_sum.body[0].text': 'A quick sum, then decide.',
  'sf_unplug_gate_sum.body[2].label': 'Answer',
  'sf_unplug_gate_sum.body[3].title': 'Need help right now?',
  'sf_unplug_gate_sum.body[3].text': 'Rescue opens in one tap.',
  'sf_unplug_gate_sum.body[3].cta[0].label': 'Get support',
  'sf_unplug_gate_sum.footer[0].action.value': 'Nice. The app stays closed.',
  'sf_unplug_gate_sum.footer[0].label': 'Keep it closed',
  'sf_unplug_gate_sum.footer[1].label': 'Open it for 10 minutes',
  'sf_unplug_gate_sum.footer[1].action.cases[0].action.value': 'Open for 10 minutes. The pause screen comes back after.',
  'sf_unplug_gate_sum.footer[1].action.cases[1].action.value': 'Answer the sum first.',
  'sf_unplug_gate_sum.header.title': 'Small step',
  'sf_unplug_health.body[0].text': 'Unplug is working. All 4 checks pass.',
  'sf_unplug_health.body[1].items[0].label': 'Screen Time permission',
  'sf_unplug_health.body[1].items[0].sub': 'Allowed',
  'sf_unplug_health.body[1].items[1].label': 'Daily schedule',
  'sf_unplug_health.body[1].items[1].sub': 'Running',
  'sf_unplug_health.body[1].items[2].label': 'Settings shared with the pause screen',
  'sf_unplug_health.body[1].items[2].sub': 'Ready',
  'sf_unplug_health.body[1].items[3].label': 'Notifications',
  'sf_unplug_health.body[1].items[3].sub': 'On · lets the pause screen open Tether for support',
  'sf_unplug_health.body[1].label': 'iPhone checks',
  'sf_unplug_health.body[2].text': 'If a check fails, Unplug stops counting and pausing. We’ll tell you instead of letting you think it’s still on.',
  'sf_unplug_health.footer[0].label': 'Done',
  'sf_unplug_health.header.title': 'Tracking check',
  'sf_unplug_health_notifications.body[0].text': 'Notifications are off. Unplug still pauses apps, but the pause screen can’t open Tether for you. Open Tether yourself for support.',
  'sf_unplug_health_notifications.body[1].items[0].label': 'Screen Time permission',
  'sf_unplug_health_notifications.body[1].items[0].sub': 'Allowed',
  'sf_unplug_health_notifications.body[1].items[1].label': 'Daily schedule',
  'sf_unplug_health_notifications.body[1].items[1].sub': 'Running',
  'sf_unplug_health_notifications.body[1].items[2].label': 'Settings shared with the pause screen',
  'sf_unplug_health_notifications.body[1].items[2].sub': 'Ready',
  'sf_unplug_health_notifications.body[1].items[3].label': 'Notifications',
  'sf_unplug_health_notifications.body[1].items[3].sub': 'Off in Settings',
  'sf_unplug_health_notifications.body[1].label': 'Checks',
  'sf_unplug_health_notifications.footer[0].label': 'Open phone settings',
  'sf_unplug_health_notifications.footer[1].action.cases[1].action.value': 'Notifications are still off.',
  'sf_unplug_health_notifications.footer[1].label': 'Check again',
  'sf_unplug_health_notifications.header.title': 'Tracking check',
  'sf_unplug_health_stopped.body[0].text': 'Unplug has stopped. Nothing is being counted or paused until this is fixed.',
  'sf_unplug_health_stopped.body[1].items[0].label': 'Screen Time permission',
  'sf_unplug_health_stopped.body[1].items[0].sub': 'Turned off in Settings',
  'sf_unplug_health_stopped.body[1].items[1].label': 'Daily schedule',
  'sf_unplug_health_stopped.body[1].items[1].sub': 'Running',
  'sf_unplug_health_stopped.body[1].items[2].label': 'Settings shared with the pause screen',
  'sf_unplug_health_stopped.body[1].items[2].sub': 'Ready',
  'sf_unplug_health_stopped.body[1].label': 'iPhone checks',
  'sf_unplug_health_stopped.footer[0].label': 'Open phone settings',
  'sf_unplug_health_stopped.footer[1].action.cases[1].action.value': 'Still not working. Turn Screen Time access on again in Settings.',
  'sf_unplug_health_stopped.footer[1].label': 'Check again',
  'sf_unplug_health_stopped.header.title': 'Tracking check',
  'sf_unplug_health_android.body[0].text': 'Unplug is working. All 4 checks pass.',
  'sf_unplug_health_android.body[1].items[0].label': 'Usage access',
  'sf_unplug_health_android.body[1].items[0].sub': 'On',
  'sf_unplug_health_android.body[1].items[1].label': 'Display over other apps',
  'sf_unplug_health_android.body[1].items[1].sub': 'On',
  'sf_unplug_health_android.body[1].items[2].label': 'Unplug running in the background',
  'sf_unplug_health_android.body[1].items[2].sub': 'Checked 12 s ago',
  'sf_unplug_health_android.body[1].items[3].label': 'Notifications',
  'sf_unplug_health_android.body[1].items[3].sub': 'On · needed for the “Tether is running” notice',
  'sf_unplug_health_android.body[1].label': 'Android checks',
  'sf_unplug_health_android.body[2].text': 'Some phones stop background apps to save battery. If Unplug keeps stopping, let Tether run in the background.',
  'sf_unplug_health_android.footer[0].label': 'Battery settings',
  'sf_unplug_health_android.footer[1].label': 'Done',
  'sf_unplug_health_android.header.title': 'Tracking check',
  'sf_unplug_off.body[0].text': 'Turn off Unplug?',
  'sf_unplug_off.body[1].text': 'Paused apps open normally again. Your ScrollFree goal, check-ins and Pause 60 stay.',
  'sf_unplug_off.body[2].items[0].label': 'Unplug only',
  'sf_unplug_off.body[2].items[0].sub': 'Removes app choices, limits and session history from this phone',
  'sf_unplug_off.body[2].items[0].badge': 'Default',
  'sf_unplug_off.body[2].items[1].label': 'Unplug and Screen Time access',
  'sf_unplug_off.body[2].items[1].sub': 'ScrollFree goes back to your own estimates',
  'sf_unplug_off.footer[0].action.cases[0].action.then.value': 'Unplug is off',
  'sf_unplug_off.footer[0].action.cases[1].action.then.value': 'Unplug and Screen Time are off',
  'sf_unplug_off.footer[0].label': 'Turn off',
  'sf_unplug_off.footer[1].label': 'Cancel',
  'sf_home_unplug.body[0].label': 'Screen Time today',
  'sf_home_unplug.body[0].caption': 'Shown by Apple’s Screen Time on this phone. Tether can’t read, store or share these minutes.',
  'sf_home_unplug.body[1].eyebrow': 'Yesterday · your estimate',
  'sf_home_unplug.body[1].children[0].value': '2h 10m',
  'sf_home_unplug.body[1].children[0].caption': 'Goal 90 min · down from 3h',
  'sf_home_unplug.body[2].title': 'Urge to scroll?',
  'sf_home_unplug.body[2].text': 'Take 60 seconds first',
  'sf_home_unplug.body[2].cta[0].label': 'Pause 60',
  'sf_home_unplug.body[3].title': 'Unplug is on',
  'sf_home_unplug.body[3].text': '2 groups · pause screen after 60 min',
  'sf_home_unplug.body[4].eyebrow': 'Today’s step',
  'sf_home_unplug.body[4].children[0].items[0].label': 'Charge your phone outside the bedroom',
  'sf_home_unplug.body[4].children[0].items[0].sub': 'Tonight · bedtime window 10 PM',
  'sf_home_unplug.body[5].rows[0].label': 'This week',
  'sf_home_unplug.body[5].rows[0].sub': '5 of 7 phone-free nights',
  'sf_home_unplug.body[5].rows[1].label': 'Had a long scroll?',
  'sf_home_unplug.body[5].rows[1].sub': 'Reflect, nothing resets',
  'sf_home_unplug.body[5].rows[2].label': 'Goal & windows',
  'sf_home_unplug.body[5].rows[2].sub': '90 min · bedtime',
  'sf_home_unplug.body[5].rows[3].label': 'Buddy',
  'sf_home_unplug.body[5].rows[3].sub': 'Sam · weekly message',
  'sf_home_unplug.body[5].rows[4].label': 'Program settings',
  'sf_home_unplug.body[5].rows[4].sub': 'Status, sharing, export, leave',
  'sf_home_unplug_android.body[0].eyebrow': 'Yesterday · measured on this phone',
  'sf_home_unplug_android.body[0].children[0].value': '2h 10m',
  'sf_home_unplug_android.body[0].children[0].caption': 'Goal 90 min · down from 3h',
  'sf_home_unplug_android.body[1].items[0].label': 'Today so far',
  'sf_home_unplug_android.body[1].items[0].value': '48 min',
  'sf_home_unplug_android.body[1].items[0].sub': 'Short video and Feeds',
  'sf_home_unplug_android.body[1].items[1].label': 'Opens today',
  'sf_home_unplug_android.body[1].items[1].sub': 'On this phone only · pause screen after 20',
  'sf_home_unplug_android.body[2].text': 'Measured by Tether on this phone with usage access. Only daily totals by category are saved to your account.',
  'sf_home_unplug_android.body[3].title': 'Urge to scroll?',
  'sf_home_unplug_android.body[3].text': 'Take 60 seconds first',
  'sf_home_unplug_android.body[3].cta[0].label': 'Pause 60',
  'sf_home_unplug_android.body[4].title': 'Unplug is on',
  'sf_home_unplug_android.body[4].text': '2 groups · pause screen after 60 min or 20 opens',
  'sf_home_unplug_android.body[5].eyebrow': 'Today’s step',
  'sf_home_unplug_android.body[5].children[0].items[0].label': 'Charge your phone outside the bedroom',
  'sf_home_unplug_android.body[5].children[0].items[0].sub': 'Tonight · bedtime window 10 PM',
  'sf_home_unplug_android.body[6].rows[0].label': 'This week',
  'sf_home_unplug_android.body[6].rows[0].sub': '5 of 7 phone-free nights',
  'sf_home_unplug_android.body[6].rows[1].label': 'Had a long scroll?',
  'sf_home_unplug_android.body[6].rows[1].sub': 'Reflect, nothing resets',
  'sf_home_unplug_android.body[6].rows[2].label': 'Goal & windows',
  'sf_home_unplug_android.body[6].rows[2].sub': '90 min · bedtime',
  'sf_home_unplug_android.body[6].rows[3].label': 'Buddy',
  'sf_home_unplug_android.body[6].rows[3].sub': 'Sam · weekly message',
  'sf_home_unplug_android.body[6].rows[4].label': 'Program settings',
  'sf_home_unplug_android.body[6].rows[4].sub': 'Status, sharing, export, leave',
  'sf_week_unplug.body[0].text': 'Your week, honestly.',
  'sf_week_unplug.body[1].label': 'Screen Time this week',
  'sf_week_unplug.body[1].caption': 'Shown by Apple’s Screen Time on this phone. Tether can’t read, store or share these minutes.',
  'sf_week_unplug.body[2].title': 'Your estimates · minutes / day',
  'sf_week_unplug.body[2].caption': 'Thursday: no check-in · not counted as zero',
  'sf_week_unplug.body[2].labels[0]': 'M',
  'sf_week_unplug.body[2].labels[1]': 'T',
  'sf_week_unplug.body[2].labels[2]': 'W',
  'sf_week_unplug.body[2].labels[3]': 'T',
  'sf_week_unplug.body[2].labels[4]': 'F',
  'sf_week_unplug.body[2].labels[5]': 'S',
  'sf_week_unplug.body[2].labels[6]': 'S',
  'sf_week_unplug.body[3].items[0].label': 'Phone-free nights',
  'sf_week_unplug.body[3].items[1].label': 'Urges paused',
  'sf_week_unplug.body[3].items[1].sub': '7 put down',
  'sf_week_unplug.body[4].eyebrow': 'You said',
  'sf_week_unplug.body[4].text': '“Drained” was 4× less common on phone-free nights.',
  'sf_week_unplug.body[4].children[0].text': 'I feel drained after long scrolls.',
  'sf_week_unplug.body[5].eyebrow': 'Next week',
  'sf_week_unplug.body[5].title': 'Step down to 75 min?',
  'sf_week_unplug.body[5].children[0].items[0].action.value': 'Goal set to 75 min',
  'sf_week_unplug.body[5].children[0].items[0].label': 'Yes',
  'sf_week_unplug.body[5].children[0].items[1].label': 'Stay at 90',
  'sf_week_unplug.header.title': 'Week 2',
  'program_settings_sf.body[0].rows[0].sub': 'Focus since Aug 14',
  'program_settings_sf.body[1].items[0].label': 'Focus',
  'program_settings_sf.body[1].items[0].sub': 'Daily steps and reminders',
  'program_settings_sf.body[1].items[1].label': 'Learn only',
  'program_settings_sf.body[1].items[1].sub': 'Keep lessons, stop tracking',
  'program_settings_sf.body[1].items[2].label': 'Pause',
  'program_settings_sf.body[1].items[2].sub': 'Stop reminders; keep everything',
  'program_settings_sf.body[1].label': 'Status',
  'program_settings_sf.body[2].eyebrow': 'Sharing',
  'program_settings_sf.body[2].children[0].label': 'Care team sharing',
  'program_settings_sf.body[2].children[0].sub': 'Off · ScrollFree isn’t shared',
  'program_settings_sf.body[2].children[1].label': 'De-identified research',
  'program_settings_sf.body[3].rows[0].sub': 'On · 2 groups · 60 min limit',
  'program_settings_sf.body[3].rows[1].label': 'Screen Time access',
  'program_settings_sf.body[3].rows[1].sub': 'Connected · totals only',
  'program_settings_sf.body[3].rows[2].label': 'Turn off Unplug or Screen Time',
  'program_settings_sf.body[3].rows[2].sub': 'Anytime',
  'program_settings_sf.body[3].title': 'Screen Time & Unplug',
  'program_settings_sf.body[4].rows[0].label': 'Export ScrollFree data',
  'program_settings_sf.body[4].rows[0].sub': 'PDF + JSON',
  'program_settings_sf.body[4].rows[0].action.value': 'Export is being prepared. We’ll notify you.',
  'program_settings_sf.body[4].rows[1].label': 'Leave ScrollFree',
  'program_settings_sf.body[4].rows[1].sub': 'Keep your data or delete it now',
  'program_settings_sf.body[4].title': 'Data',
  'program_settings_sf.footer[0].action.then.value': 'Saved',
  'program_settings_sf.footer[0].label': 'Save changes',
  'program_settings_sf.header.title': 'ScrollFree settings',
  'account_delete_apple.body[0].text': 'Delete your account and all data?',
  'account_delete_apple.body[1].rows[0][0]': 'Programs',
  'account_delete_apple.body[1].rows[1][0]': 'Check-ins',
  'account_delete_apple.body[1].rows[2][0]': 'Readings & logs',
  'account_delete_apple.body[1].rows[3][0]': 'Shared with care team',
  'account_delete_apple.body[1].rows[3][1]': '3 summaries (their copies stay with them)',
  'account_delete_apple.body[2].text': 'This can’t be undone. Download a copy first if you want one.',
  'account_delete_apple.body[3].label': 'Download a copy first',
  'account_delete_apple.body[4].label': 'Type DELETE to confirm',
  'account_delete_apple.body[4].placeholder': 'DELETE',
  'account_delete_apple.body[5].eyebrow': 'Confirm it’s you',
  'account_delete_apple.body[5].title': 'Signed in with Apple',
  'account_delete_apple.body[5].text': 'When you tap Delete everything, Apple asks you to confirm. Use the same Apple account you signed in with.',
  'account_delete_apple.footer[0].action.cases[1].action.value': 'That’s a different Apple account. Use the one you signed in with.',
  'account_delete_apple.footer[0].action.cases[2].action.value': 'Nothing was deleted.',
  'account_delete_apple.footer[0].action.cases[3].action.value': 'Couldn’t reach Apple. Nothing was deleted.',
  'account_delete_apple.footer[0].label': 'Delete everything',
  'account_delete_apple.header.title': 'Delete account',
  'account_delete_google.body[0].text': 'Delete your account and all data?',
  'account_delete_google.body[1].rows[0][0]': 'Programs',
  'account_delete_google.body[1].rows[1][0]': 'Check-ins',
  'account_delete_google.body[1].rows[2][0]': 'Readings & logs',
  'account_delete_google.body[1].rows[3][0]': 'Shared with care team',
  'account_delete_google.body[1].rows[3][1]': '3 summaries (their copies stay with them)',
  'account_delete_google.body[2].text': 'This can’t be undone. Download a copy first if you want one.',
  'account_delete_google.body[3].label': 'Download a copy first',
  'account_delete_google.body[4].label': 'Type DELETE to confirm',
  'account_delete_google.body[4].placeholder': 'DELETE',
  'account_delete_google.body[5].eyebrow': 'Confirm it’s you',
  'account_delete_google.body[5].title': 'Signed in with Google',
  'account_delete_google.body[5].text': 'When you tap Delete everything, Google asks you to confirm. Use the same Google account you signed in with.',
  'account_delete_google.footer[0].action.cases[1].action.value': 'That’s a different Google account. Use the one you signed in with.',
  'account_delete_google.footer[0].action.cases[2].action.value': 'Nothing was deleted.',
  'account_delete_google.footer[0].action.cases[3].action.value': 'Couldn’t reach Google. Nothing was deleted.',
  'account_delete_google.footer[0].label': 'Delete everything',
  'account_delete_google.header.title': 'Delete account',
  'auth_session_apple.body[0].text': 'Please sign in again',
  'auth_session_apple.body[1].text': 'For your security, sessions end after 30 days.',
  'auth_session_apple.body[2].text': 'You signed in with Apple, so there’s no password to type.',
  'auth_session_apple.footer[0].items[0].label': 'Continue with Apple',
  'auth_session_apple.footer[0].items[0].action.cases[1].action.value': 'Still signed out. Rescue works without signing in.',
  'auth_session_apple.footer[1].label': 'Use Face ID',
  'auth_session_google.body[0].text': 'Please sign in again',
  'auth_session_google.body[1].text': 'For your security, sessions end after 30 days.',
  'auth_session_google.body[2].text': 'You signed in with Google, so there’s no password to type.',
  'auth_session_google.footer[0].items[0].label': 'Continue with Google',
  'auth_session_google.footer[0].items[0].action.cases[1].action.value': 'Still signed out. Rescue works without signing in.',
  'auth_session_google.footer[1].label': 'Use Face ID',
  'sf_screentime_android.body[1].text': 'See real totals, if you want.',
  'sf_screentime_android.body[2].text': 'Tether reads daily totals by category only. Never apps’ content, messages or contacts.',
  'sf_screentime_android.body[3].rows[0][0]': 'Reads',
  'sf_screentime_android.body[3].rows[0][1]': 'Minutes per category',
  'sf_screentime_android.body[3].rows[1][0]': 'Never reads',
  'sf_screentime_android.body[3].rows[1][1]': 'Content, messages, contacts',
  'sf_screentime_android.body[3].rows[2][0]': 'Turn off',
  'sf_screentime_android.body[3].rows[2][1]': 'Anytime in Account',
  'sf_screentime_android.body[4].items[0].label': 'Tap Open settings',
  'sf_screentime_android.body[4].items[1].label': 'Find Tether Health',
  'sf_screentime_android.body[4].items[2].label': 'Turn on “Permit usage access”',
  'sf_screentime_android.body[4].label': 'Android asks in Settings',
  'sf_screentime_android.footer[0].action.cases[0].action.value': 'Usage access on',
  'sf_screentime_android.footer[0].label': 'Open settings',
  'sf_screentime_android.footer[1].label': 'Not now',
  'sf_screentime_android.header.title': 'Screen Time',
  'sf_screentime_android.header.pill': 'Optional',
  'sf_screentime_android_denied.body[0].text': 'Usage access is still off.',
  'sf_screentime_android_denied.body[1].text': 'Self-report works just as well.',
  'sf_screentime_android_denied.body[2].text': 'We’ll ask for a quick estimate in your evening check-in. You can connect later in Account → ScrollFree.',
  'sf_screentime_android_denied.footer[0].label': 'Continue with self-report',
  'sf_screentime_android_denied.footer[1].label': 'Open settings',
  'sf_screentime_android_denied.header.title': 'Screen Time',
  'sf_screentime_android_denied.header.pill': 'Optional',
  'sys_update_android.body[1].text': 'A safety update is ready',
  'sys_update_android.body[2].text': 'This version has important fixes. Rescue and Support still work until you update.',
  'sys_update_android.footer[0].label': 'Update now',
  'sys_update_android.footer[1].label': 'Open Rescue',
  'sys_update_android.header.title': 'Update needed',
  'surface_widget_ios.body[0].title': 'Rescue',
  'surface_widget_ios.body[0].text': 'Help for the next few minutes',
  'surface_widget_ios.header.title': 'iPhone widget',
  'surface_widget_android.body[0].title': 'Rescue',
  'surface_widget_android.body[0].text': 'Help for the next few minutes',
  'surface_widget_android.header.title': 'Android widget',
  'surface_shortcuts_ios.body[0].rows[0].label': 'Rescue',
  'surface_shortcuts_ios.body[0].rows[0].sub': '“Rescue in Tether” · opens Rescue',
  'surface_shortcuts_ios.body[0].rows[1].label': 'My plan',
  'surface_shortcuts_ios.body[0].rows[1].sub': '“Show my plan in Tether” · only while ClearAir is a focus program',
  'surface_shortcuts_ios.body[0].title': 'Tether Health · App Shortcuts',
  'surface_shortcuts_ios.body[1].text': 'Labels stay generic so a locked phone doesn’t reveal which programs you use. Turn on Show sensitive details to see program names.',
  'surface_shortcuts_ios.header.title': 'Siri & Shortcuts',
  'surface_shortcuts_ios_named.body[0].rows[0].label': 'Rescue',
  'surface_shortcuts_ios_named.body[0].rows[0].sub': '“Rescue in Tether” · opens Rescue',
  'surface_shortcuts_ios_named.body[0].rows[1].label': 'ClearAir red-zone plan',
  'surface_shortcuts_ios_named.body[0].rows[1].sub': '“Show my ClearAir plan in Tether”',
  'surface_shortcuts_ios_named.body[0].title': 'Tether Health · App Shortcuts',
  'surface_shortcuts_ios_named.header.title': 'Siri & Shortcuts',
  'surface_shortcuts_android.body[0].rows[0].label': 'Rescue',
  'surface_shortcuts_android.body[0].rows[1].label': 'My plan',
  'surface_shortcuts_android.body[1].text': 'Labels stay generic so the home screen doesn’t reveal which programs you use. Turn on Show sensitive details to see program names.',
  'surface_shortcuts_android.header.title': 'App shortcuts',
  'surface_shortcuts_android_named.body[0].rows[0].label': 'Rescue',
  'surface_shortcuts_android_named.body[0].rows[1].label': 'ClearAir red-zone plan',
  'surface_shortcuts_android_named.header.title': 'App shortcuts',
};

const Map<String, String> _pseudo = <String, String>{
  'kit.back': '⟦Ɓàçķ~~⟧',
  'kit.close': '⟦Çļöšé~~⟧',
  'kit.account': '⟦Àççöûñţ~~~⟧',
  'kit.tab_today': '⟦Ţöðàý~~⟧',
  'kit.tab_plans': '⟦Þļàñš~~⟧',
  'kit.tab_progress': '⟦Þŕöĝŕéšš~~~~⟧',
  'kit.tab_learn': '⟦Ļéàŕñ~~⟧',
  'kit.tab_support': '⟦Šûþþöŕţ~~~⟧',
  'kit.tab_semantics': '⟦{tab} ţàƀ~~⟧',
  'kit.step_of': '⟦Šţéþ ~~{n} öƒ ~{total}⟧',
  'kit.zone_green': '⟦Ĝŕééñ~~⟧',
  'kit.zone_yellow': '⟦Ýéļļöŵ~~~⟧',
  'kit.zone_red': '⟦Ŕéð~~⟧',
  'kit.zone_semantics': '⟦{zone} žöñé~~⟧',
  'kit.chart': '⟦Çĥàŕţ~~⟧',
  'kit.chart_semantics': '⟦{title}: {values}⟧',
  'kit.chart_no_entry': '⟦ñö éñţŕý~~~⟧',
  'kit.seconds': '⟦ŠÉÇÖÑÐŠ~~~⟧',
  'kit.ring_semantics': '⟦{value} {label}⟧',
  'kit.timer_semantics': '⟦{value} {label}⟧',
  'kit.weekday_initials': '⟦Š Ṁ Ţ Ŵ Ţ Ƒ Š~~~⟧',
  'kit.calendar_day': '⟦{month} {day}⟧',
  'kit.month_names': '⟦Ĵàñûàŕý|Ƒéƀŕûàŕý|Ṁàŕçĥ|Àþŕîļ|Ṁàý|Ĵûñé|Ĵûļý|Àûĝûšţ|Šéþţéɱƀéŕ|Öçţöƀéŕ|Ñöṽéɱƀéŕ|Ðéçéɱƀéŕ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'kit.weekday_names': '⟦Šûñðàý|Ṁöñðàý|Ţûéšðàý|Ŵéðñéšðàý|Ţĥûŕšðàý|Ƒŕîðàý|Šàţûŕðàý~~~~~~~~~~~~~~~~~~~~⟧',
  'kit.calendar_title': '⟦{month} {year}⟧',
  'kit.date_full': '⟦{weekday}, {month} {day}, {year}⟧',
  'kit.calendar_prev': '⟦Þŕéṽîöûš ɱöñţĥ~~~~~~⟧',
  'kit.calendar_next': '⟦Ñéẋţ ɱöñţĥ~~~~⟧',
  'kit.calendar_recommended': '⟦Ŕéçöɱɱéñðéð~~~~~⟧',
  'kit.days_to_prepare': '⟦{n, plural, one{# ðàý ţö þŕéþàŕé~~~~~} other{# ðàýš ţö þŕéþàŕé~~~~~~}}⟧',
  'kit.environment': '⟦Éñṽîŕöñɱéñţ: ~~~~~{name}⟧',
  'kit.quote': '⟦“{text}”⟧',
  'kit.emergency_help': '⟦Éɱéŕĝéñçý ĥéļþ~~~~~~⟧',
  'kit.loading': '⟦Ļöàðîñĝ~~~⟧',
  'kit.generic_error': '⟦Šöɱéţĥîñĝ ŵéñţ ŵŕöñĝ. Þļéàšé ţŕý àĝàîñ.~~~~~~~~~~~~~⟧',
  'kit.example': '⟦Éẋàɱþļé~~~⟧',
  'kit.call_fallback': '⟦Çàļļîñĝ îšñ’ţ àṽàîļàƀļé ĥéŕé. Ðîàļ ~~~~~~~~~~~~{number} ñöŵ.~~⟧',
  'kit.sms_fallback': '⟦Ţéẋţîñĝ îšñ’ţ àṽàîļàƀļé ĥéŕé. Ţéẋţ ~~~~~~~~~~~~{number} ñöŵ.~~⟧',
  'kit.copy': '⟦Çöþý~~⟧',
  'kit.copied': '⟦Çöþîéð~~~⟧',
  'welcome.body[2].text': '⟦Ŵéļçöɱé ţö Ţéţĥéŕ Ĥéàļţĥ~~~~~~~~~⟧',
  'welcome.body[3].text': '⟦Çàŕé ţĥàţ ɱééţš ýöû ŵĥéŕé ýöû àŕé.~~~~~~~~~~~⟧',
  'welcome.body[4].text': '⟦Šɱàļļ šţéþš, þŕàçţîçàļ šûþþöŕţ àñð ñö ĵûðĝɱéñţ, ƒöŕ ţĥé þàŕţš öƒ ýöûŕ ĥéàļţĥ ýöû çĥööšé.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'welcome.body[5].rows[0][0]': '⟦Þŕîṽàţé ƀý ðéšîĝñ~~~~~~⟧',
  'welcome.body[5].rows[0][1]': '⟦Ñö àðš · ñéṽéŕ šöļð~~~~~~⟧',
  'welcome.body[5].rows[1][0]': '⟦Ĥéļþ îñ öñé ţàþ~~~~~⟧',
  'welcome.body[5].rows[1][1]': '⟦Ñö ţýþîñĝ ñééðéð~~~~~~⟧',
  'welcome.body[5].rows[2][0]': '⟦Ýöûŕ þàçé~~~~⟧',
  'welcome.body[5].rows[2][1]': '⟦Þàûšé àñýţîɱé~~~~~⟧',
  'welcome.footer[0].label': '⟦Ĝéţ šţàŕţéð~~~~⟧',
  'welcome.footer[1].label': '⟦Î àļŕéàðý ĥàṽé àñ àççöûñţ~~~~~~~~~⟧',
  'welcome.footer[2].label': '⟦Ţéŕɱš àñð Þŕîṽàçý Ñöţîçé~~~~~~~~~⟧',
  'ob_programs.body[1].text': '⟦Ŵĥàţ ŵöûļð ýöû ļîķé šûþþöŕţ ŵîţĥ?~~~~~~~~~~~⟧',
  'ob_programs.body[2].text': '⟦Çĥööšé àñý. Ýöû çàñ àðð, þàûšé öŕ ļéàṽé à þŕöĝŕàɱ àñýţîɱé.~~~~~~~~~~~~~~~~~~⟧',
  'ob_programs.body[3].items[0].sub': '⟦Ţöƀàççö & ñîçöţîñé~~~~~~⟧',
  'ob_programs.body[3].items[1].sub': '⟦Šöçîàļ ɱéðîà ûšé~~~~~~⟧',
  'ob_programs.body[3].items[2].sub': '⟦Ŕéšþîŕàţöŕý ĥéàļţĥ~~~~~~~⟧',
  'ob_programs.body[3].items[3].sub': '⟦Çàŕðîöṽàšçûļàŕ ĥéàļţĥ~~~~~~~~⟧',
  'ob_programs.body[3].items[4].sub': '⟦Ðîàƀéţéš & ɱéţàƀöļîç ĥéàļţĥ~~~~~~~~~~⟧',
  'ob_programs.body[3].items[5].sub': '⟦Ṁéñţàļ & ƀéĥàṽîöŕàļ ĥéàļţĥ~~~~~~~~~⟧',
  'ob_programs.body[3].items[6].sub': '⟦Öƀéšîţý & ñûţŕîţîöñ~~~~~~~⟧',
  'ob_programs.body[3].items[7].sub': '⟦Ĥéàļţĥý àĝîñĝ~~~~~⟧',
  'ob_programs.body[4].label': '⟦Šéé àļļ 11 þŕöĝŕàɱš~~~~~~⟧',
  'ob_programs.footer[0].countLabel': '⟦{n, plural, one{Çöñţîñûé ŵîţĥ ~~~~~# þŕöĝŕàɱ~~~} other{Çöñţîñûé ŵîţĥ ~~~~~# þŕöĝŕàɱš~~~~}}⟧',
  'ob_programs.footer[0].emptyLabel': '⟦Çĥööšé àţ ļéàšţ öñé þŕöĝŕàɱ~~~~~~~~~~⟧',
  'ob_programs.header.title': '⟦Çĥööšé þŕöĝŕàɱš~~~~~~⟧',
  'ob_programs.header.pill': '⟦1 öƒ 5~⟧',
  'ob_focus.body[1].text': '⟦Ţŵö àţ à ţîɱé ŵöŕķš ƀéšţ.~~~~~~~~⟧',
  'ob_focus.body[2].text': '⟦Ƒöçûš þŕöĝŕàɱš ĝéţ ðàîļý šţéþš àñð ŕéɱîñðéŕš. Ļéàŕñ öñļý ĝîṽéš ýöû ļéššöñš, ŵîţĥ ñö ţŕàçķîñĝ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_focus.body[3].rows[0].sub': '⟦Àƀöûţ 3 ɱîñ à ðàý~~~~~⟧',
  'ob_focus.body[3].rows[0].pill': '⟦Ƒöçûš 1~~⟧',
  'ob_focus.body[3].rows[1].sub': '⟦Àƀöûţ 1 ɱîñ à ðàý~~~~~⟧',
  'ob_focus.body[3].rows[1].pill': '⟦Ƒöçûš 2~~⟧',
  'ob_focus.body[3].title': '⟦Ƒöçûš · ðàîļý šûþþöŕţ~~~~~~~⟧',
  'ob_focus.body[4].rows[0].sub': '⟦Ļéššöñš àƀöûţ ļûñĝ ŕéçöṽéŕý~~~~~~~~~~⟧',
  'ob_focus.body[4].rows[0].pill': '⟦Ļéàŕñ~~⟧',
  'ob_focus.body[4].title': '⟦Ļéàŕñ öñļý · ñö ŕéɱîñðéŕš~~~~~~~~⟧',
  'ob_focus.body[5].title': '⟦Ŵĥý ţŵö?~~~⟧',
  'ob_focus.body[5].text': '⟦Þéöþļé ķééþ ĝöîñĝ ŵîţĥ ƒéŵéŕ ðàîļý àšķš. Šŵàþ àñýţîɱé îñ Àççöûñţ → Þŕöĝŕàɱš.~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_focus.body[6].label': '⟦Àðð à ţĥîŕð þŕöĝŕàɱ~~~~~~~⟧',
  'ob_focus.footer[0].label': '⟦Çöñţîñûé~~~~⟧',
  'ob_focus.header.title': '⟦Ýöûŕ ƒöçûš~~~~⟧',
  'ob_focus.header.pill': '⟦2 öƒ 5~⟧',
  'ob_third.body[0].text': '⟦Ɓöţĥ ƒöçûš šļöţš àŕé îñ ûšé~~~~~~~~~⟧',
  'ob_third.body[1].text': '⟦Àðð Ĥéàŕţŵîšé àš…~~~~~~⟧',
  'ob_third.body[2].items[0].label': '⟦Ļéàŕñ öñļý ƒöŕ ñöŵ~~~~~~⟧',
  'ob_third.body[2].items[0].sub': '⟦Ļéššöñš, ñö ŕéɱîñðéŕš. Ûþĝŕàðé àñýţîɱé.~~~~~~~~~~~~~⟧',
  'ob_third.body[2].items[0].badge': '⟦Šûĝĝéšţéð~~~~⟧',
  'ob_third.body[2].items[1].label': '⟦Šŵàþ ŵîţĥ ŠçŕöļļƑŕéé~~~~~~~~⟧',
  'ob_third.body[2].items[1].sub': '⟦ŠçŕöļļƑŕéé þàûšéš. Îţš ðàţà àñð þŕöĝŕéšš àŕé ķéþţ.~~~~~~~~~~~~~~~~~⟧',
  'ob_third.body[2].items[2].label': '⟦Šŵàþ ŵîţĥ ƁŕéàţĥéƑŕéé~~~~~~~~⟧',
  'ob_third.body[2].items[2].sub': '⟦Ñöţ šûĝĝéšţéð ðûŕîñĝ ýöûŕ ǫûîţ ŵééķ.~~~~~~~~~~~~⟧',
  'ob_third.footer[0].action.value': '⟦Ĥéàŕţŵîšé àððéð àš Ļéàŕñ öñļý~~~~~~~~~~⟧',
  'ob_third.footer[0].label': '⟦Çöñţîñûé~~~~⟧',
  'ob_third.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'ob_consent.body[1].text': '⟦Ýöûŕ šţöŕý šţàýš ýöûŕš.~~~~~~~~⟧',
  'ob_consent.body[2].text': '⟦Éàçĥ þŕöĝŕàɱ ķééþš îţš öŵñ ðàţà. Öþţîöñàļ çĥöîçéš šţàŕţ öƒƒ.~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_consent.body[3].eyebrow': '⟦Àççöûñţ · ŕéǫûîŕéð~~~~~~⟧',
  'ob_consent.body[3].children[0].label': '⟦Éššéñţîàļ àþþ ðàţà~~~~~~~⟧',
  'ob_consent.body[3].children[0].sub': '⟦Àççöûñţ, þļàñš àñð þŕöĝŕéšš, éñçŕýþţéð. Ŕéǫûîŕéð.~~~~~~~~~~~~~~~~⟧',
  'ob_consent.body[4].children[0].label': '⟦Þŕîṽàţé ŕéɱîñðéŕš~~~~~~~⟧',
  'ob_consent.body[4].children[0].sub': '⟦Ļöçķ šçŕééñ: “Ýöû ĥàṽé à Ţéţĥéŕ ŕéɱîñðéŕ.”~~~~~~~~~~~~~⟧',
  'ob_consent.body[4].children[1].label': '⟦Šĥàŕé šûɱɱàŕîéš ŵîţĥ ɱý çàŕé ţéàɱ~~~~~~~~~~~~⟧',
  'ob_consent.body[4].children[1].sub': '⟦Ýöû þŕéṽîéŵ éṽéŕý šĥàŕé~~~~~~~~⟧',
  'ob_consent.body[5].children[0].label': '⟦Çöññéçţ Šçŕééñ Ţîɱé~~~~~~~⟧',
  'ob_consent.body[5].children[0].sub': '⟦Öþţîöñàļ · ţöţàļš öñļý, ñéṽéŕ çöñţéñţ~~~~~~~~~~~~⟧',
  'ob_consent.body[5].children[1].label': '⟦Ðé-îðéñţîƒîéð ŕéšéàŕçĥ~~~~~~~~⟧',
  'ob_consent.body[6].text': '⟦Ñö àðš. Ñö ţöƀàççö-îñðûšţŕý ƒûñðîñĝ. Ŵé ñéṽéŕ šéļļ ĥéàļţĥ îñƒöŕɱàţîöñ.~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_consent.body[7].label': '⟦Ŕéàð ţĥé Þŕîṽàçý Ñöţîçé~~~~~~~~⟧',
  'ob_consent.footer[0].label': '⟦Àĝŕéé àñð çöñţîñûé~~~~~~~⟧',
  'ob_consent.header.title': '⟦Ýöûŕ þŕîṽàçý~~~~~⟧',
  'ob_consent.header.pill': '⟦3 öƒ 5~⟧',
  'ob_basics.body[1].text': '⟦Šĥàŕéð · àšķéð öñçé ƒöŕ àļļ þŕöĝŕàɱš~~~~~~~~~~~~⟧',
  'ob_basics.body[2].text': '⟦À ƒéŵ ƀàšîçš~~~~⟧',
  'ob_basics.body[3].label': '⟦Ŵĥàţ šĥöûļð ŵé çàļļ ýöû?~~~~~~~~⟧',
  'ob_basics.body[3].placeholder': '⟦Àļéẋ~~⟧',
  'ob_basics.body[4].label': '⟦Àĝé ŕàñĝé~~~~⟧',
  'ob_basics.body[5].options[0]': '⟦< 5 ĥ~⟧',
  'ob_basics.body[5].options[1]': '⟦5–6 ĥ~⟧',
  'ob_basics.body[5].options[2]': '⟦7–8 ĥ~⟧',
  'ob_basics.body[5].options[3]': '⟦9+ ĥ~⟧',
  'ob_basics.body[5].label': '⟦Šļééþ öñ à ţýþîçàļ ñîĝĥţ~~~~~~~~⟧',
  'ob_basics.body[6].options[0]': '⟦Ļöŵ~~⟧',
  'ob_basics.body[6].options[1]': '⟦Šöɱé~~⟧',
  'ob_basics.body[6].options[2]': '⟦Ĥîĝĥ~~⟧',
  'ob_basics.body[6].label': '⟦Ûšûàļ šţŕéšš~~~~~⟧',
  'ob_basics.body[7].title': '⟦Ŵĥý ŵé àšķ~~~~⟧',
  'ob_basics.body[7].text': '⟦Ţĥéšé àñšŵéŕš àŕé šĥàŕéð ƀý ýöûŕ þŕöĝŕàɱš, šö ýöû’ŕé ñéṽéŕ àšķéð ţŵîçé. Àĝé ŕàñĝé šéţš ŵĥîçĥ ļéššöñš àñð šçŕééñîñĝš àþþļý.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_basics.footer[0].label': '⟦Çöñţîñûé~~~~⟧',
  'ob_basics.header.title': '⟦Àƀöûţ ýöû~~~~⟧',
  'ob_basics.header.pill': '⟦4 öƒ 5~⟧',
  'ob_setup.body[1].text': '⟦Ļéţ’š šéţ ûþ ýöûŕ þŕöĝŕàɱš.~~~~~~~~~⟧',
  'ob_setup.body[2].text': '⟦Éàçĥ ţàķéš àƀöûţ 3 ɱîñûţéš. Ýöû çàñ šţöþ àñð çöɱé ƀàçķ.~~~~~~~~~~~~~~~~~⟧',
  'ob_setup.body[3].rows[0].sub': '⟦Ǫûîţ þļàñ · àƀöûţ 3 ɱîñ~~~~~~~⟧',
  'ob_setup.body[3].rows[0].pill': '⟦Šţàŕţ~~⟧',
  'ob_setup.body[3].rows[1].sub': '⟦Ûšàĝé ĝöàļ · àƀöûţ 2 ɱîñ~~~~~~~⟧',
  'ob_setup.body[3].rows[1].pill': '⟦Šţàŕţ~~⟧',
  'ob_setup.body[3].title': '⟦Ƒöçûš þŕöĝŕàɱš~~~~~~⟧',
  'ob_setup.body[4].rows[0].sub': '⟦Ļéàŕñ öñļý · ñöţĥîñĝ ţö šéţ ûþ~~~~~~~~~~⟧',
  'ob_setup.body[4].title': '⟦Ļéàŕñ öñļý~~~~⟧',
  'ob_setup.body[5].rows[0].label': '⟦Ĥéàļţĥ ŕéçöŕðš (öþţîöñàļ)~~~~~~~~~⟧',
  'ob_setup.body[5].rows[0].sub': '⟦Îɱþöŕţ ƒŕöɱ Éþîç ṀýÇĥàŕţ, Ṁéðîçàŕé öŕ àñöţĥéŕ ƑĤÎŔ šöûŕçé~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_setup.body[5].title': '⟦Ýöûŕ ðàţà~~~~⟧',
  'ob_setup.body[6].title': '⟦Ţîþ~~⟧',
  'ob_setup.body[6].text': '⟦Ƒîñîšĥîñĝ à þŕöĝŕàɱ šéţûþ ƀŕîñĝš ýöû ƀàçķ ĥéŕé.~~~~~~~~~~~~~~~~⟧',
  'ob_setup.footer[0].label': '⟦Çöñţîñûé~~~~⟧',
  'ob_setup.footer[1].label': '⟦Šéţ ûþ ļàţéŕ~~~~⟧',
  'ob_setup.header.title': '⟦Šéţ ûþ~~⟧',
  'ob_setup.header.pill': '⟦5 öƒ 5~⟧',
  'ob_reminders.body[1].text': '⟦Ǫûîéţ, þŕîṽàţé ŕéɱîñðéŕš~~~~~~~~~⟧',
  'ob_reminders.body[2].text': '⟦Àţ ɱöšţ 2 à ðàý, öñļý ƒöŕ ýöûŕ ƒöçûš þŕöĝŕàɱš.~~~~~~~~~~~~~~⟧',
  'ob_reminders.body[3].eyebrow': '⟦Ļöçķ šçŕééñ þŕéṽîéŵ~~~~~~~⟧',
  'ob_reminders.body[3].text': '⟦Þŕöĝŕàɱ ñàɱéš àñð ĥéàļţĥ ðéţàîļš šţàý ĥîððéñ ûñļéšš ýöû ţûŕñ ţĥéɱ öñ.~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_reminders.body[3].children[0].text': '⟦Ýöû ĥàṽé à Ţéţĥéŕ ŕéɱîñðéŕ.~~~~~~~~~⟧',
  'ob_reminders.body[4].label': '⟦Ǫûîéţ ĥöûŕš~~~~⟧',
  'ob_reminders.body[4].sub': '⟦9:00 ÞṀ – 7:00 ÀṀ · šàƒéţý àļéŕţš šţîļļ çöɱé ţĥŕöûĝĥ~~~~~~~~~~~~~⟧',
  'ob_reminders.footer[0].label': '⟦Ţûŕñ öñ ŕéɱîñðéŕš~~~~~~⟧',
  'ob_reminders.footer[1].label': '⟦Ñöţ ñöŵ~~~⟧',
  'ob_reminders.header.title': '⟦Ŕéɱîñðéŕš~~~~⟧',
  'ob_reminders_denied.body[0].text': '⟦Ñöţîƒîçàţîöñš àŕé öƒƒ îñ ýöûŕ þĥöñé šéţţîñĝš.~~~~~~~~~~~~~~~~⟧',
  'ob_reminders_denied.body[1].text': '⟦Ýöû çàñ šţîļļ ûšé éṽéŕýţĥîñĝ.~~~~~~~~~~⟧',
  'ob_reminders_denied.body[2].text': '⟦Ţöðàý šĥöŵš ýöûŕ šţéþš ŵĥéñ ýöû öþéñ ţĥé àþþ. Ţö ĝéţ ŕéɱîñðéŕš, àļļöŵ ñöţîƒîçàţîöñš ƒöŕ Ţéţĥéŕ îñ Šéţţîñĝš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_reminders_denied.footer[0].label': '⟦Öþéñ þĥöñé šéţţîñĝš~~~~~~~⟧',
  'ob_reminders_denied.footer[1].label': '⟦Çöñţîñûé ŵîţĥöûţ ŕéɱîñðéŕš~~~~~~~~~~⟧',
  'ob_reminders_denied.header.title': '⟦Ŕéɱîñðéŕš~~~~⟧',
  'ob_account.body[0].text': '⟦Çŕéàţé ýöûŕ àççöûñţ~~~~~~~⟧',
  'ob_account.body[1].text': '⟦Ķééþš ýöûŕ þļàñš šàƒé îƒ ýöû çĥàñĝé þĥöñéš. Ýöû çàñ àļšö çöñţîñûé öñ ţĥîš þĥöñé öñļý.~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_account.body[2].items[0].label': '⟦Çöñţîñûé ŵîţĥ Àþþļé~~~~~~~⟧',
  'ob_account.body[2].items[0].action.cases[0].action.cases[2].action.value': '⟦Šîĝñ-îñ çàñçéļļéð~~~~~~⟧',
  'ob_account.body[2].items[0].action.cases[1].action.value': '⟦Ýöû ñééð ţö ƀé 18 öŕ öļðéŕ ţö çöñţîñûé.~~~~~~~~~~~~⟧',
  'ob_account.body[2].items[1].label': '⟦Çöñţîñûé ŵîţĥ Ĝööĝļé~~~~~~~~⟧',
  'ob_account.body[2].items[1].action.cases[0].action.cases[2].action.value': '⟦Šîĝñ-îñ çàñçéļļéð~~~~~~⟧',
  'ob_account.body[2].items[1].action.cases[1].action.value': '⟦Ýöû ñééð ţö ƀé 18 öŕ öļðéŕ ţö çöñţîñûé.~~~~~~~~~~~~⟧',
  'ob_account.body[3].text': '⟦Šîĝñ îñ ŵîţĥ Àþþļé çàñ ĥîðé ýöûŕ éɱàîļ: ŵé ûšé Àþþļé’š þŕîṽàţé ŕéļàý àððŕéšš.~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_account.body[4].text': '⟦Öŕ ŵîţĥ éɱàîļ~~~~~⟧',
  'ob_account.body[5].label': '⟦Éɱàîļ~~⟧',
  'ob_account.body[5].placeholder': '⟦àļéẋ@éẋàɱþļé.çöɱ~~~~~~⟧',
  'ob_account.body[6].label': '⟦Þàššŵöŕð~~~~⟧',
  'ob_account.body[6].hint': '⟦Àţ ļéàšţ 12 çĥàŕàçţéŕš. À þàššþĥŕàšé ŵöŕķš ŵéļļ.~~~~~~~~~~~~~~~⟧',
  'ob_account.body[7].items[0].label': '⟦Î’ɱ 18 öŕ öļðéŕ~~~~⟧',
  'ob_account.body[8].text': '⟦Ĝûéšţ þļàñš àŕé éñçŕýþţéð öñ ţĥîš þĥöñé. Îƒ ýöû šîĝñ ûþ ļàţéŕ, ŵé àšķ ƀéƒöŕé ûþļöàðîñĝ ţĥéɱ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ob_account.footer[0].action.cases[1].action.value': '⟦Ýöû ñééð ţö ƀé 18 öŕ öļðéŕ ţö çöñţîñûé.~~~~~~~~~~~~⟧',
  'ob_account.footer[0].label': '⟦Çŕéàţé àççöûñţ~~~~~~⟧',
  'ob_account.footer[1].action.cases[1].action.value': '⟦Ýöû ñééð ţö ƀé 18 öŕ öļðéŕ ţö çöñţîñûé.~~~~~~~~~~~~⟧',
  'ob_account.footer[1].label': '⟦Çöñţîñûé öñ ţĥîš þĥöñé öñļý~~~~~~~~~~⟧',
  'ob_account.header.title': '⟦Šàṽé ýöûŕ þŕöĝŕéšš~~~~~~~⟧',
  'auth_verify.body[1].text': '⟦Çöñƒîŕɱ ýöûŕ éɱàîļ~~~~~~~⟧',
  'auth_verify.body[2].text': '⟦Ŵé šéñţ à ļîñķ ţö àļéẋ@éẋàɱþļé.çöɱ. Öþéñ îţ öñ ţĥîš þĥöñé ţö ƒîñîšĥ.~~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_verify.body[3].text': '⟦Ýöûŕ þļàñ îš šàṽéð öñ ţĥîš þĥöñé ŵĥîļé ýöû ŵàîţ. Ñöţĥîñĝ îš ļöšţ îƒ ýöû çļöšé ţĥé àþþ.~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_verify.footer[0].label': '⟦Öþéñ éɱàîļ àþþ~~~~~⟧',
  'auth_verify.footer[1].label': '⟦Î’ṽé çöñƒîŕɱéð ɱý éɱàîļ~~~~~~~~⟧',
  'auth_verify.footer[2].label': '⟦Ŕéšéñð ļîñķ (àṽàîļàƀļé îñ 0:42)~~~~~~~~~⟧',
  'auth_verify.footer[2].action.value': '⟦Ļîñķ šéñţ àĝàîñ~~~~~~⟧',
  'auth_verify.header.title': '⟦Çĥéçķ ýöûŕ éɱàîļ~~~~~~⟧',
  'auth_signin.body[0].text': '⟦Ŵéļçöɱé ƀàçķ~~~~~⟧',
  'auth_signin.body[1].items[0].label': '⟦Çöñţîñûé ŵîţĥ Àþþļé~~~~~~~⟧',
  'auth_signin.body[1].items[0].action.cases[3].action.value': '⟦Šîĝñ-îñ çàñçéļļéð~~~~~~⟧',
  'auth_signin.body[1].items[1].label': '⟦Çöñţîñûé ŵîţĥ Ĝööĝļé~~~~~~~~⟧',
  'auth_signin.body[1].items[1].action.cases[3].action.value': '⟦Šîĝñ-îñ çàñçéļļéð~~~~~~⟧',
  'auth_signin.body[2].text': '⟦Öŕ ŵîţĥ éɱàîļ~~~~~⟧',
  'auth_signin.body[3].label': '⟦Éɱàîļ~~⟧',
  'auth_signin.body[3].placeholder': '⟦àļéẋ@éẋàɱþļé.çöɱ~~~~~~⟧',
  'auth_signin.body[4].label': '⟦Þàššŵöŕð~~~~⟧',
  'auth_signin.body[5].label': '⟦Ƒöŕĝöţ þàššŵöŕð?~~~~~~⟧',
  'auth_signin.footer[0].label': '⟦Šîĝñ îñ~~~⟧',
  'auth_signin.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'auth_signin_error.body[0].text': '⟦Ŵéļçöɱé ƀàçķ~~~~~⟧',
  'auth_signin_error.body[1].text': '⟦Ţĥàţ éɱàîļ àñð þàššŵöŕð ðöñ’ţ ɱàţçĥ. Çĥéçķ ƀöţĥ àñð ţŕý àĝàîñ.~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_signin_error.body[2].items[0].label': '⟦Çöñţîñûé ŵîţĥ Àþþļé~~~~~~~⟧',
  'auth_signin_error.body[2].items[0].action.cases[3].action.value': '⟦Šîĝñ-îñ çàñçéļļéð~~~~~~⟧',
  'auth_signin_error.body[2].items[1].label': '⟦Çöñţîñûé ŵîţĥ Ĝööĝļé~~~~~~~~⟧',
  'auth_signin_error.body[2].items[1].action.cases[3].action.value': '⟦Šîĝñ-îñ çàñçéļļéð~~~~~~⟧',
  'auth_signin_error.body[3].text': '⟦Öŕ ŵîţĥ éɱàîļ~~~~~⟧',
  'auth_signin_error.body[4].label': '⟦Éɱàîļ~~⟧',
  'auth_signin_error.body[4].placeholder': '⟦àļéẋ@éẋàɱþļé.çöɱ~~~~~~⟧',
  'auth_signin_error.body[5].label': '⟦Þàššŵöŕð~~~~⟧',
  'auth_signin_error.body[5].error': '⟦Þàššŵöŕð îš îñçöŕŕéçţ.~~~~~~~~⟧',
  'auth_signin_error.body[6].label': '⟦Ƒöŕĝöţ þàššŵöŕð?~~~~~~⟧',
  'auth_signin_error.body[7].text': '⟦Àƒţéŕ 5 ţŕîéš ŵé þàûšé šîĝñ-îñ ƒöŕ 15 ɱîñûţéš ţö þŕöţéçţ ýöûŕ àççöûñţ.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_signin_error.footer[0].label': '⟦Ţŕý àĝàîñ~~~~⟧',
  'auth_signin_error.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'auth_social_new.body[1].text': '⟦Çŕéàţé ýöûŕ Ţéţĥéŕ àççöûñţ?~~~~~~~~~~⟧',
  'auth_social_new.body[2].text': '⟦Ñö Ţéţĥéŕ àççöûñţ ûšéš ţĥîš Àþþļé ÎÐ öŕ Ĝööĝļé àççöûñţ ýéţ.~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_social_new.body[3].rows[0][0]': '⟦Ñàɱé~~⟧',
  'auth_social_new.body[3].rows[0][1]': '⟦Àļéẋ (šĥàŕéð ƀý Àþþļé)~~~~~~~⟧',
  'auth_social_new.body[3].rows[1][0]': '⟦Éɱàîļ~~⟧',
  'auth_social_new.body[3].rows[1][1]': '⟦Þŕîṽàţé ŕéļàý · Ĥîðé Ṁý Éɱàîļ~~~~~~~~~~⟧',
  'auth_social_new.body[3].rows[2][0]': '⟦Þàššŵöŕð~~~~⟧',
  'auth_social_new.body[3].rows[2][1]': '⟦Ñöñé ñééðéð~~~~⟧',
  'auth_social_new.body[4].text': '⟦Ýöû çàñ àðð éɱàîļ & þàššŵöŕð öŕ àñöţĥéŕ šîĝñ-îñ ɱéţĥöð ļàţéŕ îñ Àççöûñţ → Šîĝñ-îñ ɱéţĥöðš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_social_new.footer[0].label': '⟦Çŕéàţé ɱý àççöûñţ~~~~~~⟧',
  'auth_social_new.footer[1].label': '⟦Ûšé à ðîƒƒéŕéñţ àççöûñţ~~~~~~~~⟧',
  'auth_social_new.header.title': '⟦Çŕéàţé àççöûñţ~~~~~~⟧',
  'auth_link.body[1].text': '⟦Ýöû àļŕéàðý ĥàṽé à Ţéţĥéŕ àççöûñţ~~~~~~~~~~~~⟧',
  'auth_link.body[2].text': '⟦àļéẋ@éẋàɱþļé.çöɱ šîĝñéð ûþ ŵîţĥ éɱàîļ àñð þàššŵöŕð. Éñţéŕ ýöûŕ þàššŵöŕð öñçé ţö ļîñķ Ĝööĝļé. Àƒţéŕ ţĥàţ, éîţĥéŕ šîĝñ-îñ ŵöŕķš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_link.body[3].label': '⟦Þàššŵöŕð~~~~⟧',
  'auth_link.body[4].label': '⟦Ƒöŕĝöţ þàššŵöŕð?~~~~~~⟧',
  'auth_link.footer[0].label': '⟦Ļîñķ àñð šîĝñ îñ~~~~~~⟧',
  'auth_link.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'auth_link.header.title': '⟦Ļîñķ àççöûñţš~~~~~⟧',
  'auth_social_error.body[1].text': '⟦Çöûļðñ’ţ šîĝñ îñ~~~~~~⟧',
  'auth_social_error.body[2].text': '⟦Ĝööĝļé šîĝñ-îñ ðîðñ’ţ ƒîñîšĥ. Çĥéçķ ýöûŕ çöññéçţîöñ àñð ţŕý àĝàîñ, öŕ ûšé éɱàîļ.~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_social_error.body[3].text': '⟦Ñöţĥîñĝ ŵàš šàṽéð öŕ šĥàŕéð.~~~~~~~~~~⟧',
  'auth_social_error.footer[0].action.cases[1].action.value': '⟦Šţîļļ çàñ’ţ ŕéàçĥ Ĝööĝļé. Ţŕý éɱàîļ.~~~~~~~~~~~~⟧',
  'auth_social_error.footer[0].label': '⟦Ţŕý àĝàîñ~~~~⟧',
  'auth_social_error.footer[1].label': '⟦Ûšé éɱàîļ îñšţéàð~~~~~~⟧',
  'auth_social_error.header.title': '⟦Šîĝñ îñ~~~⟧',
  'auth_forgot.body[0].text': '⟦Ƒöŕĝöţ ýöûŕ þàššŵöŕð?~~~~~~~~⟧',
  'auth_forgot.body[1].text': '⟦Éñţéŕ ýöûŕ éɱàîļ àñð ŵé’ļļ šéñð à ŕéšéţ ļîñķ.~~~~~~~~~~~~~~⟧',
  'auth_forgot.body[2].label': '⟦Éɱàîļ~~⟧',
  'auth_forgot.body[2].placeholder': '⟦àļéẋ@éẋàɱþļé.çöɱ~~~~~~⟧',
  'auth_forgot.footer[0].label': '⟦Šéñð ŕéšéţ ļîñķ~~~~~~⟧',
  'auth_forgot.header.title': '⟦Ŕéšéţ þàššŵöŕð~~~~~~⟧',
  'auth_forgot_sent.body[1].text': '⟦Çĥéçķ ýöûŕ éɱàîļ~~~~~~⟧',
  'auth_forgot_sent.body[2].text': '⟦Îƒ àñ àççöûñţ éẋîšţš ƒöŕ ţĥàţ àððŕéšš, à ŕéšéţ ļîñķ îš öñ îţš ŵàý. Îţ éẋþîŕéš îñ 1 ĥöûŕ.~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_forgot_sent.body[3].text': '⟦Ŵé ñéṽéŕ šàý ŵĥéţĥéŕ àñ éɱàîļ îš ŕéĝîšţéŕéð, ţö þŕöţéçţ ýöûŕ þŕîṽàçý.~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'auth_forgot_sent.footer[0].label': '⟦Ɓàçķ ţö ŵéļçöɱé~~~~~~⟧',
  'auth_forgot_sent.header.title': '⟦Ŕéšéţ þàššŵöŕð~~~~~~⟧',
  'auth_newpass.body[0].text': '⟦Çĥööšé à ñéŵ þàššŵöŕð~~~~~~~~⟧',
  'auth_newpass.body[1].label': '⟦Ñéŵ þàššŵöŕð~~~~~⟧',
  'auth_newpass.body[1].hint': '⟦Àţ ļéàšţ 12 çĥàŕàçţéŕš.~~~~~~~⟧',
  'auth_newpass.body[2].label': '⟦Çöñƒîŕɱ þàššŵöŕð~~~~~~⟧',
  'auth_newpass.footer[0].label': '⟦Šàṽé þàššŵöŕð~~~~~⟧',
  'auth_newpass.header.title': '⟦Ñéŵ þàššŵöŕð~~~~~⟧',
  'auth_merge.body[0].text': '⟦Ýöû’ŕé šîĝñéð îñ~~~~~~⟧',
  'auth_merge.body[1].text': '⟦Ûþļöàð ţĥé þļàñ öñ ţĥîš þĥöñé?~~~~~~~~~~⟧',
  'auth_merge.body[2].rows[0].label': '⟦ƁŕéàţĥéƑŕéé þļàñ · ţĥîš þĥöñé~~~~~~~~~~⟧',
  'auth_merge.body[2].rows[0].sub': '⟦Ǫûîţ ðàţé Àûĝ 28 · 3 ŕéàšöñš~~~~~~~~⟧',
  'auth_merge.body[3].text': '⟦Ýöûŕ àççöûñţ àļŕéàðý ĥàš à ƁŕéàţĥéƑŕéé þļàñ ƒŕöɱ Àûĝ 12.~~~~~~~~~~~~~~~~~~⟧',
  'auth_merge.body[4].items[0].label': '⟦Ķééþ ƀöţĥ, çĥööšé ļàţéŕ~~~~~~~~⟧',
  'auth_merge.body[4].items[0].sub': '⟦Ñöţĥîñĝ îš öṽéŕŵŕîţţéñ~~~~~~~~⟧',
  'auth_merge.body[4].items[0].badge': '⟦Šàƒéšţ~~~⟧',
  'auth_merge.body[4].items[1].label': '⟦Ûšé ţĥîš þĥöñé’š þļàñ~~~~~~~⟧',
  'auth_merge.body[4].items[2].label': '⟦Ûšé ţĥé àççöûñţ’š þļàñ~~~~~~~~⟧',
  'auth_merge.footer[0].label': '⟦Çöñţîñûé~~~~⟧',
  'auth_session.body[0].text': '⟦Þļéàšé šîĝñ îñ àĝàîñ~~~~~~~⟧',
  'auth_session.body[1].text': '⟦Ƒöŕ ýöûŕ šéçûŕîţý, šéššîöñš éñð àƒţéŕ 30 ðàýš.~~~~~~~~~~~~~~⟧',
  'auth_session.body[2].label': '⟦Þàššŵöŕð~~~~⟧',
  'auth_session.body[2].placeholder': '⟦Þàššŵöŕð~~~~⟧',
  'auth_session.footer[0].label': '⟦Šîĝñ îñ~~~⟧',
  'auth_session.footer[1].label': '⟦Ûšé Ƒàçé ÎÐ~~~~⟧',
  'today.body[0].text': '⟦Ƒŕîðàý, Àûĝûšţ 21~~~~~⟧',
  'today.body[1].text': '⟦Ĝööð ɱöŕñîñĝ, Àļéẋ.~~~~~~⟧',
  'today.body[2].options[0]': '⟦Àļļ~~⟧',
  'today.body[3].title': '⟦Çŕàṽîñĝ öŕ ûŕĝé ţö šçŕöļļ?~~~~~~~~~⟧',
  'today.body[3].text': '⟦Ĥéļþ ƒöŕ ţĥé ñéẋţ ƒéŵ ɱîñûţéš~~~~~~~~~~⟧',
  'today.body[3].cta[0].label': '⟦Ŕéšçûé~~~⟧',
  'today.body[4].eyebrow': '⟦Ţöðàý · 2 šɱàļļ šţéþš~~~~~~⟧',
  'today.body[4].children[0].items[0].label': '⟦Šţöçķ ĝûɱ, ŵàţéŕ öŕ šñàçķš~~~~~~~~~⟧',
  'today.body[4].children[0].items[0].sub': '⟦ƁŕéàţĥéƑŕéé · 3 ɱîñ~~~~~~⟧',
  'today.body[4].children[0].items[1].label': '⟦Çĥàŕĝé ýöûŕ þĥöñé öûţšîðé ţĥé ƀéðŕööɱ~~~~~~~~~~~~~⟧',
  'today.body[4].children[0].items[1].sub': '⟦ŠçŕöļļƑŕéé · ţöñîĝĥţ~~~~~~~⟧',
  'today.body[5].eyebrow': '⟦Çĥéçķ-îñ · àƀöûţ 90 šéç~~~~~~⟧',
  'today.body[5].title': '⟦Çöṽéŕš ƀöţĥ þŕöĝŕàɱš~~~~~~~~⟧',
  'today.body[5].cta[0].label': '⟦Šţàŕţ~~⟧',
  'today.body[6].items[0].label': '⟦Ǫûîţ ðàý~~~⟧',
  'today.body[6].items[0].value': '⟦7 ðàýš~~⟧',
  'today.body[6].items[0].sub': '⟦Ƒŕî, Àûĝ 28~~~⟧',
  'today.body[6].items[1].label': '⟦Ýéšţéŕðàý~~~~⟧',
  'today.body[6].items[1].value': '⟦2ĥ 10ɱ~⟧',
  'today.body[6].items[1].sub': '⟦ĝöàļ 90 ɱîñ~~~⟧',
  'today.body[7].rows[0].label': '⟦ƁŕéàţĥéƑŕéé ĥöɱé~~~~~~⟧',
  'today.body[7].rows[0].sub': '⟦Þļàñ, ɱéðîçîñéš, þŕöĝŕéšš~~~~~~~~~⟧',
  'today.body[7].rows[1].label': '⟦ŠçŕöļļƑŕéé ĥöɱé~~~~~~⟧',
  'today.body[7].rows[1].sub': '⟦Ĝöàļ, Þàûšé 60, ŵééķ~~~~~~⟧',
  'today.body[8].tagExtra': '⟦Ļéàŕñ öñļý~~~~⟧',
  'today.body[8].title': '⟦Ĥöŵ ýöûŕ ļûñĝš ŕéçöṽéŕ àƒţéŕ ýöû ǫûîţ~~~~~~~~~~~~~⟧',
  'today.body[8].text': '⟦4 ɱîñ ŕéàð~~~⟧',
  'today.header.title': '⟦Ţöðàý~~⟧',
  'today_loading.body[1].title': '⟦Çŕàṽîñĝ öŕ ûŕĝé?~~~~~~⟧',
  'today_loading.body[1].text': '⟦Öñé ţàþ · ñö ţýþîñĝ~~~~~~⟧',
  'today_loading.body[1].cta[0].label': '⟦Ŕéšçûé~~~⟧',
  'today_loading.body[4].text': '⟦Ţĥé ŕéšţ öƒ Ţöðàý îš šţîļļ ļöàðîñĝ.~~~~~~~~~~~~⟧',
  'today_loading.header.title': '⟦Ţöðàý~~⟧',
  'today_offline.body[0].text': '⟦Öƒƒļîñé · 3 éñţŕîéš ŵîļļ šýñç ŵĥéñ ýöû ŕéçöññéçţ.~~~~~~~~~~~~~~~~⟧',
  'today_offline.body[1].text': '⟦Ĝööð ɱöŕñîñĝ, Àļéẋ.~~~~~~⟧',
  'today_offline.body[2].title': '⟦Çŕàṽîñĝ öŕ ûŕĝé?~~~~~~⟧',
  'today_offline.body[2].text': '⟦Öñé ţàþ · ñö ţýþîñĝ~~~~~~⟧',
  'today_offline.body[2].cta[0].label': '⟦Ŕéšçûé~~~⟧',
  'today_offline.body[3].eyebrow': '⟦Ţöðàý~~⟧',
  'today_offline.body[3].children[0].items[0].label': '⟦Šţöçķ ĝûɱ, ŵàţéŕ öŕ šñàçķš~~~~~~~~~⟧',
  'today_offline.body[3].children[0].items[0].sub': '⟦Šàṽéð öñ ţĥîš þĥöñé~~~~~~~⟧',
  'today_offline.body[4].text': '⟦Ļéššöñš ñöţ ðöŵñļöàðéð ļöàð ŵĥéñ ýöû’ŕé ƀàçķ öñļîñé.~~~~~~~~~~~~~~~~~~⟧',
  'today_offline.header.title': '⟦Ţöðàý~~⟧',
  'today_empty.body[0].text': '⟦Ĝööð éṽéñîñĝ, Àļéẋ.~~~~~~⟧',
  'today_empty.body[2].text': '⟦Ñöţĥîñĝ îñ ƒöçûš ŕîĝĥţ ñöŵ~~~~~~~~~⟧',
  'today_empty.body[3].text': '⟦Ýöûŕ þŕöĝŕàɱš àŕé þàûšéð öŕ îñ Ļéàŕñ öñļý. Þîçķ öñé ƒöŕ ðàîļý šûþþöŕţ, öŕ ķééþ éẋþļöŕîñĝ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'today_empty.body[4].label': '⟦Çĥööšé à ƒöçûš þŕöĝŕàɱ~~~~~~~~⟧',
  'today_empty.body[5].label': '⟦Ɓŕöŵšé ļéššöñš~~~~~~⟧',
  'today_empty.body[6].title': '⟦Ñééð ĥéļþ ñöŵ?~~~~~⟧',
  'today_empty.body[6].text': '⟦Ŕéšçûé àñð Šûþþöŕţ šţîļļ ŵöŕķ~~~~~~~~~~⟧',
  'today_empty.body[6].cta[0].label': '⟦Šûþþöŕţ~~~⟧',
  'today_empty.header.title': '⟦Ţöðàý~~⟧',
  'today_safety.body[0].text': '⟦Ýöûŕ ļàšţ ƀļööð þŕéššûŕé ŵàš îñ ţĥé çŕîšîš ŕàñĝé.~~~~~~~~~~~~~~~~⟧',
  'today_safety.body[1].title': '⟦Àñý çĥéšţ þàîñ, šĥöŕţñéšš öƒ ƀŕéàţĥ, ŵéàķñéšš, ṽîšîöñ çĥàñĝé öŕ ţŕöûƀļé šþéàķîñĝ?~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'today_safety.body[1].text': '⟦Ĥéàŕţŵîšé · ƒŕöɱ ýöûŕ 8:10 ÀṀ ŕéàðîñĝ~~~~~~~~~~~⟧',
  'today_safety.body[1].children[0].items[0].label': '⟦Ýéš · çàļļ 911~~~⟧',
  'today_safety.body[1].children[0].items[1].label': '⟦Ñö šýɱþţöɱš~~~~⟧',
  'today_safety.body[2].text': '⟦Öţĥéŕ šţéþš àŕé þàûšéð ûñţîļ ýöû àñšŵéŕ. Šàƒéţý àļŵàýš çöɱéš ƒîŕšţ.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'today_safety.body[3].eyebrow': '⟦Ţöðàý · þàûšéð~~~~~⟧',
  'today_safety.body[3].children[0].items[0].label': '⟦Šţöçķ ĝûɱ, ŵàţéŕ öŕ šñàçķš~~~~~~~~~⟧',
  'today_safety.body[3].children[0].items[1].label': '⟦Çĥàŕĝé þĥöñé öûţšîðé ţĥé ƀéðŕööɱ~~~~~~~~~~~~⟧',
  'today_safety.header.title': '⟦Ţöðàý~~⟧',
  'checkin.body[0].text': '⟦Šĥàŕéð · àšķéð öñçé~~~~~~⟧',
  'checkin.body[1].options[0]': '⟦Ļöŵ~~⟧',
  'checkin.body[1].options[1]': '⟦Ñöţ ĝŕéàţ~~~~⟧',
  'checkin.body[1].options[2]': '⟦Öķàý~~⟧',
  'checkin.body[1].options[3]': '⟦Ĝööð~~⟧',
  'checkin.body[1].options[4]': '⟦Ĝŕéàţ~~⟧',
  'checkin.body[1].label': '⟦Ĥöŵ ðö ýöû ƒééļ ţöðàý?~~~~~~~⟧',
  'checkin.body[2].options[0]': '⟦Ļöŵ~~⟧',
  'checkin.body[2].options[1]': '⟦Šöɱé~~⟧',
  'checkin.body[2].options[2]': '⟦Ĥîĝĥ~~⟧',
  'checkin.body[2].label': '⟦Šţŕéšš ţöðàý~~~~~⟧',
  'checkin.body[3].title': '⟦Šîñçé ýöûŕ ļàšţ çĥéçķ-îñ, ðîð ýöû šɱöķé?~~~~~~~~~~~~~⟧',
  'checkin.body[3].text': '⟦Ɓéƒöŕé ǫûîţ ðàý ţĥîš îš éẋþéçţéð, ñöţ à šéţƀàçķ.~~~~~~~~~~~~~~~~⟧',
  'checkin.body[3].children[0].options[0]': '⟦Ñö~⟧',
  'checkin.body[3].children[0].options[1]': '⟦À þûƒƒ~~⟧',
  'checkin.body[3].children[0].options[2]': '⟦Öñé öŕ ɱöŕé~~~~⟧',
  'checkin.body[3].children[0].options[3]': '⟦Šķîþ~~⟧',
  'checkin.body[4].title': '⟦Ĥöŵ ðîð ýöû ƒééļ àƒţéŕ šçŕöļļîñĝ ýéšţéŕðàý?~~~~~~~~~~~~~~~⟧',
  'checkin.body[4].children[0].options[0]': '⟦Ɓéţţéŕ~~~⟧',
  'checkin.body[4].children[0].options[1]': '⟦Šàɱé~~⟧',
  'checkin.body[4].children[0].options[2]': '⟦Ðŕàîñéð~~~⟧',
  'checkin.body[4].children[0].options[3]': '⟦Šķîþ~~⟧',
  'checkin.footer[0].label': '⟦Šàṽé çĥéçķ-îñ~~~~~⟧',
  'checkin.footer[1].text': '⟦Šķîþ àñý þŕöĝŕàɱ ǫûéšţîöñ~~~~~~~~~⟧',
  'checkin_done.body[1].text': '⟦Ţĥàñķš, Àļéẋ.~~~~⟧',
  'checkin_done.body[2].text': '⟦Öñé šɱàļļ šţéþ ƒöŕ éàçĥ þŕöĝŕàɱ ţöðàý.~~~~~~~~~~~~~⟧',
  'checkin_done.body[3].title': '⟦Ţŕý à 3-ɱîñûţé šţŕéšš ŕéšéţ~~~~~~~~~⟧',
  'checkin_done.body[3].text': '⟦Ýöû ŕéþöŕţéð ĥîĝĥ šţŕéšš~~~~~~~~~⟧',
  'checkin_done.body[3].cta[0].label': '⟦Šţàŕţ~~⟧',
  'checkin_done.body[4].title': '⟦Šéţ à 10 ÞṀ ŵîñð-ðöŵñ~~~~~~⟧',
  'checkin_done.body[4].text': '⟦Ýöû ƒéļţ ðŕàîñéð àƒţéŕ šçŕöļļîñĝ~~~~~~~~~~~~⟧',
  'checkin_done.body[4].cta[0].label': '⟦Šéţ îţ~~⟧',
  'checkin_done.body[5].text': '⟦Ŕéçöɱɱéñðàţîöñš ûšé öñļý ţöðàý’š àñšŵéŕš · ṽ1.0~~~~~~~~~~~~~~~⟧',
  'checkin_done.footer[0].label': '⟦Ɓàçķ ţö Ţöðàý~~~~~⟧',
  'checkin_done.header.title': '⟦Çĥéçķ-îñ šàṽéð~~~~~⟧',
  'rescue_pick.body[0].text': '⟦Ŕîĝĥţ ñöŵ~~~~⟧',
  'rescue_pick.body[1].text': '⟦Ŵĥàţ’š þûļļîñĝ àţ ýöû?~~~~~~~⟧',
  'rescue_pick.body[2].text': '⟦Öñé ţàþ. Ñö ţýþîñĝ.~~~~~~⟧',
  'rescue_pick.body[3].items[0].label': '⟦À çîĝàŕéţţé~~~~⟧',
  'rescue_pick.body[3].items[1].label': '⟦Ûŕĝé ţö šçŕöļļ~~~~~⟧',
  'rescue_pick.body[3].items[2].label': '⟦Šţŕéšš~~~⟧',
  'rescue_pick.body[3].items[2].sub': '⟦Šĥàŕéð ţööļ~~~~⟧',
  'rescue_pick.body[3].items[3].label': '⟦Ñöţ šûŕé~~~⟧',
  'rescue_pick.body[3].items[3].sub': '⟦Ŵé’ļļ šûĝĝéšţ öñé~~~~~~⟧',
  'rescue_pick.body[4].eyebrow': '⟦Ĥéļþéð ļàšţ ţîɱé · 6 → 3~~~~~~⟧',
  'rescue_pick.body[4].title': '⟦Šļöŵ ƀŕéàţĥîñĝ · 2 ɱîñ~~~~~~~⟧',
  'rescue_pick.body[4].cta[0].label': '⟦Šţàŕţ~~⟧',
  'rescue_pick.body[5].items[0].label': '⟦Ţàļķ ţö à þéŕšöñ~~~~~~⟧',
  'rescue_pick.body[5].items[1].label': '⟦Éɱéŕĝéñçý~~~~⟧',
  'rescue_active.body[0].text': '⟦Ɓŕéàţĥé öûţ · šļöŵļý~~~~~~~⟧',
  'rescue_active.body[2].text': '⟦Ţĥé ûŕĝé îš à ŵàṽé. Ļéţ îţ ŕîšé àñð þàšš.~~~~~~~~~~~~⟧',
  'rescue_active.body[3].options[0]': '⟦Ṽöîçé öñ~~~⟧',
  'rescue_active.body[3].options[1]': '⟦Ĥàþţîçš öñ~~~~⟧',
  'rescue_active.body[3].options[2]': '⟦Ŕéðûçéð ɱöţîöñ~~~~~~⟧',
  'rescue_active.body[4].title': '⟦Šţîļļ šţŕöñĝ?~~~~~⟧',
  'rescue_active.body[4].text': '⟦Šŵîţçĥ ţööļ öŕ ŕéàçĥ à þéŕšöñ. Ţĥîš çĥéçķ-îñ îš ķéþţ.~~~~~~~~~~~~~~~~~⟧',
  'rescue_active.body[4].children[0].items[0].label': '⟦Šŵîţçĥ ţööļ~~~~⟧',
  'rescue_active.body[4].children[0].items[1].label': '⟦Ĝéţ šûþþöŕţ~~~~⟧',
  'rescue_active.footer[0].label': '⟦Î’ɱ ðöñé~~~⟧',
  'rescue_active.header.title': '⟦Šļöŵ ƀŕéàţĥîñĝ~~~~~~⟧',
  'rescue_active.header.pill': '⟦1:32 ļéƒţ~~⟧',
  'rescue_tools.body[0].text': '⟦Çĥööšé àñöţĥéŕ ţööļ~~~~~~~⟧',
  'rescue_tools.body[1].items[0].label': '⟦Šļöŵ ƀŕéàţĥîñĝ~~~~~~⟧',
  'rescue_tools.body[1].items[0].sub': '⟦2 ɱîñ · ṽöîçé öþţîöñàļ~~~~~~~⟧',
  'rescue_tools.body[1].items[0].badge': '⟦Ĥéļþéð ƀéƒöŕé~~~~~⟧',
  'rescue_tools.body[1].items[1].label': '⟦Ṁöṽé ƒöŕ 3 ɱîñûţéš~~~~~~⟧',
  'rescue_tools.body[1].items[1].sub': '⟦Ŵàļķ öŕ šţŕéţçĥ~~~~~~⟧',
  'rescue_tools.body[1].items[2].label': '⟦Çĥàñĝé ţĥé šçéñé~~~~~~⟧',
  'rescue_tools.body[1].items[2].sub': '⟦Ĝö šöɱéŵĥéŕé šɱöķé-ƒŕéé~~~~~~~~⟧',
  'rescue_tools.body[1].items[3].label': '⟦Ûŕĝé šûŕƒîñĝ~~~~~⟧',
  'rescue_tools.body[1].items[3].sub': '⟦3 ɱîñ àûðîö~~~~⟧',
  'rescue_tools.footer[0].label': '⟦Šţàŕţ ţĥîš ţööļ~~~~~~⟧',
  'rescue_tools.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'rescue_result.body[0].text': '⟦Ţĥîš çŕàṽîñĝ éàšéð.~~~~~~~⟧',
  'rescue_result.body[1].label': '⟦Ĥöŵ šţŕöñĝ îš îţ ñöŵ?~~~~~~~⟧',
  'rescue_result.body[2].items[0].label': '⟦Ɓéƒöŕé~~~⟧',
  'rescue_result.body[2].items[1].label': '⟦Ñöŵ~~⟧',
  'rescue_result.body[2].items[1].sub': '⟦Ýöûŕ ŕàţîñĝ, ñöţ à ðîàĝñöšîš~~~~~~~~~~⟧',
  'rescue_result.body[3].options[0]': '⟦Ýéš~~⟧',
  'rescue_result.body[3].options[1]': '⟦À ļîţţļé~~~⟧',
  'rescue_result.body[3].options[2]': '⟦Ñöţ ţĥîš ţîɱé~~~~~⟧',
  'rescue_result.body[3].label': '⟦Ðîð îţ ĥéļþ?~~~~⟧',
  'rescue_result.body[4].eyebrow': '⟦Ñéẋţ 10 ɱîñûţéš~~~~~⟧',
  'rescue_result.body[4].title': '⟦Šţàý šöɱéŵĥéŕé šɱöķé-ƒŕéé àñð šîþ ŵàţéŕ.~~~~~~~~~~~~~~⟧',
  'rescue_result.body[5].label': '⟦Šţîļļ šţŕöñĝ? Ĝéţ ɱöŕé ĥéļþ~~~~~~~~~⟧',
  'rescue_result.footer[0].label': '⟦Ɓàçķ ţö Ţöðàý~~~~~⟧',
  'rescue_result.header.title': '⟦Ŕéšçûé ðöñé~~~~⟧',
  'rescue_result.header.pill': '⟦Šàṽéð~~⟧',
  'rescue_escalate.body[0].text': '⟦Ļéţ’š àðð à þéŕšöñ.~~~~~~⟧',
  'rescue_escalate.body[1].text': '⟦Šţŕöñĝ çŕàṽîñĝš àŕé çöɱɱöñ îñ ţĥé ƒîŕšţ ðàýš. Ýöû ðöñ’ţ ĥàṽé ţö ŕîðé ţĥîš öñé àļöñé.~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'rescue_escalate.body[2].eyebrow': '⟦Ƒŕéé & çöñƒîðéñţîàļ~~~~~~~⟧',
  'rescue_escalate.body[2].title': '⟦Ǫûîţļîñé çöûñšéļöŕ~~~~~~~⟧',
  'rescue_escalate.body[2].text': '⟦1-800-ǪÛÎŢ-ÑÖŴ · ɱàñý šţàţéš 24/7~~~~~~~⟧',
  'rescue_escalate.body[2].cta[0].label': '⟦Çàļļ~~⟧',
  'rescue_escalate.body[3].rows[0].label': '⟦Ţéẋţ Ĵöŕðàñ~~~~⟧',
  'rescue_escalate.body[3].rows[0].sub': '⟦“Çàñ ýöû šţàý ŵîţĥ ɱé ƒöŕ 10 ɱîñûţéš?”~~~~~~~~~~~⟧',
  'rescue_escalate.body[4].text': '⟦Ţĥöûĝĥţš öƒ ĥàŕɱîñĝ ýöûŕšéļƒ? Çàļļ öŕ ţéẋţ 988. Éɱéŕĝéñçý: 911.~~~~~~~~~~~~~~~~~~⟧',
  'rescue_escalate.body[4].actions[0].label': '⟦Çàļļ öŕ ţéẋţ 988~~~~⟧',
  'rescue_escalate.body[4].actions[1].label': '⟦Çàļļ 911~~⟧',
  'rescue_escalate.footer[0].label': '⟦Ţŕý àñöţĥéŕ ţööļ~~~~~~⟧',
  'rescue_escalate.header.title': '⟦Ŕéšçûé~~~⟧',
  'crisis.body[0].text': '⟦Îƒ ýöû ɱîĝĥţ àçţ öñ ţĥöûĝĥţš öƒ ĥàŕɱîñĝ ýöûŕšéļƒ, ĝéţ ĥéļþ ñöŵ.~~~~~~~~~~~~~~~~~~~~⟧',
  'crisis.body[1].label': '⟦Çàļļ 988~~⟧',
  'crisis.body[2].label': '⟦Ţéẋţ 988~~⟧',
  'crisis.body[3].label': '⟦Çàļļ 911~~⟧',
  'crisis.body[4].eyebrow': '⟦Ýöûŕ šàƒéţý þļàñ~~~~~~⟧',
  'crisis.body[4].title': '⟦Ţĥîñĝš ţĥàţ ĥéļþ: ŵàļķ ţĥé ðöĝ, šĥöŵéŕ, ɱûšîç~~~~~~~~~~~~~~⟧',
  'crisis.body[4].text': '⟦Ŕéàçĥ öûţ: Šàɱ · (555) 010-3311~~~~~⟧',
  'crisis.header.title': '⟦Ýöû’ŕé ñöţ àļöñé~~~~~~⟧',
  'plans.body[0].rows[0].sub': '⟦Ǫûîţ ðàţé · Ƒŕî, Àûĝ 28~~~~~~⟧',
  'plans.body[0].rows[0].pill': '⟦Ƒöçûš~~⟧',
  'plans.body[0].rows[1].sub': '⟦90 ɱîñ/ðàý · ƀéðţîɱé 10 ÞṀ–7 ÀṀ~~~~~~~⟧',
  'plans.body[0].rows[1].pill': '⟦Ƒöçûš~~⟧',
  'plans.body[0].title': '⟦Ƒöçûš · 2 öƒ 2~~~⟧',
  'plans.body[1].rows[0].sub': '⟦Ļéàŕñ öñļý · ñö þļàñ ýéţ~~~~~~~~⟧',
  'plans.body[1].rows[0].pill': '⟦Ļéàŕñ~~⟧',
  'plans.body[1].title': '⟦Ļéàŕñ öñļý~~~~⟧',
  'plans.body[2].rows[0].label': '⟦Ṁéðîçàţîöñ çéñţéŕ~~~~~~~⟧',
  'plans.body[2].rows[0].sub': '⟦ƁŕéàţĥéƑŕéé · ñîçöţîñé þàţçĥ~~~~~~~~~~⟧',
  'plans.body[2].rows[1].label': '⟦Þŕöĝŕàɱš & šĥàŕîñĝ~~~~~~⟧',
  'plans.body[2].rows[1].sub': '⟦Šţàţûš, çöñšéñţ, ðàţà~~~~~~~⟧',
  'plans.body[2].title': '⟦Ṁàñàĝé~~~⟧',
  'plans.footer[0].label': '⟦Àðð à þŕöĝŕàɱ~~~~~⟧',
  'plans.header.title': '⟦Ṁý þļàñš~~~⟧',
  'catalog.body[0].text': '⟦Çĥööšé ŵĥàţ ýöû ŵàñţ šûþþöŕţ ŵîţĥ.~~~~~~~~~~~~⟧',
  'catalog.body[1].rows[0].sub': '⟦Ţöƀàççö & ñîçöţîñé · Ǫûîţ / Ŕéðûçé~~~~~~~~~~⟧',
  'catalog.body[1].rows[1].sub': '⟦Šöçîàļ ɱéðîà ûšé · Ǫûîţ / Ŕéðûçé~~~~~~~~~~⟧',
  'catalog.body[1].rows[2].sub': '⟦Ŕéšþîŕàţöŕý ĥéàļţĥ · Ṁàñàĝé~~~~~~~~~~⟧',
  'catalog.body[1].rows[3].sub': '⟦Çàŕðîöṽàšçûļàŕ ĥéàļţĥ · Ṁàñàĝé~~~~~~~~~~~⟧',
  'catalog.body[1].rows[4].sub': '⟦Ðîàƀéţéš & ɱéţàƀöļîç ĥéàļţĥ · Ṁàñàĝé~~~~~~~~~~~~⟧',
  'catalog.body[1].rows[5].sub': '⟦Ķîðñéý & ļîṽéŕ ĥéàļţĥ · Ṁàñàĝé~~~~~~~~~~⟧',
  'catalog.body[1].title': '⟦Ǫûîţ · Ṁàñàĝé~~~~⟧',
  'catalog.body[2].rows[0].sub': '⟦Öƀéšîţý & ñûţŕîţîöñ · Ɓûîļð ĥàƀîţš~~~~~~~~~~~⟧',
  'catalog.body[2].rows[1].sub': '⟦Ĥéàļţĥý àĝîñĝ · Ɓûîļð ĥàƀîţš~~~~~~~~~~⟧',
  'catalog.body[2].rows[2].sub': '⟦Ṁéñţàļ & ƀéĥàṽîöŕàļ ĥéàļţĥ · Šûþþöŕţ~~~~~~~~~~~~⟧',
  'catalog.body[2].rows[3].sub': '⟦Þŕéṽéñţîṽé ĥéàļţĥ · Þŕéṽéñţ~~~~~~~~~~⟧',
  'catalog.body[2].rows[4].sub': '⟦Çàñçéŕ · Þŕéṽéñţ~~~~~~⟧',
  'catalog.body[2].title': '⟦Ĥàƀîţš · Šûþþöŕţ · Þŕéṽéñţ~~~~~~~~⟧',
  'catalog.header.title': '⟦Àļļ þŕöĝŕàɱš~~~~~⟧',
  'focus_full.body[0].text': '⟦Ɓöţĥ ƒöçûš šļöţš àŕé îñ ûšé~~~~~~~~~⟧',
  'focus_full.body[1].text': '⟦Àðð Ĥéàŕţŵîšé àš…~~~~~~⟧',
  'focus_full.body[2].items[0].label': '⟦Ļéàŕñ öñļý ƒöŕ ñöŵ~~~~~~⟧',
  'focus_full.body[2].items[0].sub': '⟦Ļéššöñš, ñö ŕéɱîñðéŕš. Ûþĝŕàðé àñýţîɱé.~~~~~~~~~~~~~⟧',
  'focus_full.body[2].items[0].badge': '⟦Šûĝĝéšţéð~~~~⟧',
  'focus_full.body[2].items[1].label': '⟦Šŵàþ ŵîţĥ ŠçŕöļļƑŕéé~~~~~~~~⟧',
  'focus_full.body[2].items[1].sub': '⟦ŠçŕöļļƑŕéé þàûšéš. Îţš ðàţà îš ķéþţ.~~~~~~~~~~~~⟧',
  'focus_full.body[2].items[2].label': '⟦Šŵàþ ŵîţĥ ƁŕéàţĥéƑŕéé~~~~~~~~⟧',
  'focus_full.body[2].items[2].sub': '⟦Ñöţ šûĝĝéšţéð ðûŕîñĝ ýöûŕ ǫûîţ ŵééķ.~~~~~~~~~~~~⟧',
  'focus_full.footer[0].action.cases[0].action.value': '⟦Ĥéàŕţŵîšé àððéð àš Ļéàŕñ öñļý~~~~~~~~~~⟧',
  'focus_full.footer[0].label': '⟦Çöñţîñûé~~~~⟧',
  'focus_full.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'program_settings.body[0].rows[0].sub': '⟦Ƒöçûš šîñçé Àûĝ 14~~~~~~⟧',
  'program_settings.body[1].items[0].label': '⟦Ƒöçûš~~⟧',
  'program_settings.body[1].items[0].sub': '⟦Ðàîļý šţéþš àñð ŕéɱîñðéŕš~~~~~~~~~⟧',
  'program_settings.body[1].items[1].label': '⟦Ļéàŕñ öñļý~~~~⟧',
  'program_settings.body[1].items[1].sub': '⟦Ķééþ ļéššöñš, šţöþ ţŕàçķîñĝ~~~~~~~~~~⟧',
  'program_settings.body[1].items[2].label': '⟦Þàûšé~~⟧',
  'program_settings.body[1].items[2].sub': '⟦Šţöþ ŕéɱîñðéŕš; ķééþ éṽéŕýţĥîñĝ~~~~~~~~~~~⟧',
  'program_settings.body[1].label': '⟦Šţàţûš~~~⟧',
  'program_settings.body[2].eyebrow': '⟦Šĥàŕîñĝ~~~⟧',
  'program_settings.body[2].children[0].label': '⟦Çàŕé ţéàɱ · Ðŕ. Þàţéļ’š çļîñîç~~~~~~~~~⟧',
  'program_settings.body[2].children[0].sub': '⟦Ṁàñûàļ: ýöû àþþŕöṽé éàçĥ šûɱɱàŕý~~~~~~~~~~~⟧',
  'program_settings.body[2].children[1].label': '⟦Ðé-îðéñţîƒîéð ŕéšéàŕçĥ~~~~~~~~⟧',
  'program_settings.body[3].rows[0].label': '⟦Éẋþöŕţ ƁŕéàţĥéƑŕéé ðàţà~~~~~~~~~⟧',
  'program_settings.body[3].rows[0].sub': '⟦ÞÐƑ + ĴŠÖÑ~~~⟧',
  'program_settings.body[3].rows[0].action.value': '⟦Éẋþöŕţ îš ƀéîñĝ þŕéþàŕéð. Ŵé’ļļ ñöţîƒý ýöû.~~~~~~~~~~~~~~⟧',
  'program_settings.body[3].rows[1].label': '⟦Ļéàṽé ƁŕéàţĥéƑŕéé~~~~~~~⟧',
  'program_settings.body[3].rows[1].sub': '⟦Ķééþ ýöûŕ ðàţà öŕ ðéļéţé îţ ñöŵ~~~~~~~~~~⟧',
  'program_settings.body[3].title': '⟦Ðàţà~~⟧',
  'program_settings.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'program_settings.footer[0].label': '⟦Šàṽé çĥàñĝéš~~~~~⟧',
  'program_settings.header.title': '⟦ƁŕéàţĥéƑŕéé šéţţîñĝš~~~~~~~~⟧',
  'progress.body[0].options[0]': '⟦7 ðàýš~~⟧',
  'progress.body[0].options[1]': '⟦30 ðàýš~~⟧',
  'progress.body[0].options[2]': '⟦Àļļ~~⟧',
  'progress.body[1].text': '⟦Þàţţéŕñš, ñöţ ĝŕàðéš. Ṁîššîñĝ çĥéçķ-îñš àŕé ñéṽéŕ çöûñţéð àš žéŕö.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'progress.body[2].title': '⟦Çîĝàŕéţţéš / ðàý~~~~~~⟧',
  'progress.body[2].caption': '⟦Šàṽéð \$42.70 · àṽöîðéð 61~~~~~⟧',
  'progress.body[2].labels[0]': '⟦Ṁ~⟧',
  'progress.body[2].labels[1]': '⟦Ţ~⟧',
  'progress.body[2].labels[2]': '⟦Ŵ~⟧',
  'progress.body[2].labels[3]': '⟦Ţ~⟧',
  'progress.body[2].labels[4]': '⟦Ƒ~⟧',
  'progress.body[2].labels[5]': '⟦Š~⟧',
  'progress.body[2].labels[6]': '⟦Š~⟧',
  'progress.body[3].title': '⟦Šöçîàļ ɱîñûţéš / ðàý~~~~~~~⟧',
  'progress.body[3].caption': '⟦Ĝöàļ 90 ɱîñ · ŕéçļàîɱéð 5ĥ 40ɱ~~~~~~~~⟧',
  'progress.body[3].labels[0]': '⟦Ṁ~⟧',
  'progress.body[3].labels[1]': '⟦Ţ~⟧',
  'progress.body[3].labels[2]': '⟦Ŵ~⟧',
  'progress.body[3].labels[3]': '⟦Ţ~⟧',
  'progress.body[3].labels[4]': '⟦Ƒ~⟧',
  'progress.body[3].labels[5]': '⟦Š~⟧',
  'progress.body[3].labels[6]': '⟦Š~⟧',
  'progress.body[4].eyebrow': '⟦Çöññéçţîöñ ŵé ñöţîçéð~~~~~~~~⟧',
  'progress.body[4].title': '⟦Ļàţé šçŕöļļîñĝ çàɱé ƀéƒöŕé 3 öƒ ýöûŕ 4 šţŕöñĝéšţ çŕàṽîñĝš.~~~~~~~~~~~~~~~~~~~⟧',
  'progress.body[4].text': '⟦Šĥöŵñ ƀéçàûšé ƀöţĥ þŕöĝŕàɱš àŕé ýöûŕš.~~~~~~~~~~~~~⟧',
  'progress.body[4].cta[0].label': '⟦Ṁàñàĝé~~~⟧',
  'progress.header.title': '⟦Þŕöĝŕéšš~~~~⟧',
  'progress_empty.body[1].text': '⟦Ýöûŕ þŕöĝŕéšš šĥöŵš ûþ ĥéŕé~~~~~~~~~~⟧',
  'progress_empty.body[2].text': '⟦Àƒţéŕ ýöûŕ ƒîŕšţ çĥéçķ-îñ öŕ ŕéàðîñĝ, ýöû’ļļ šéé þàţţéŕñš ƒöŕ éàçĥ þŕöĝŕàɱ.~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'progress_empty.body[3].label': '⟦Ðö à çĥéçķ-îñ~~~~⟧',
  'progress_empty.header.title': '⟦Þŕöĝŕéšš~~~~⟧',
  'progress_error.body[1].text': '⟦Šöɱéţĥîñĝ ŵéñţ ŵŕöñĝ öñ öûŕ šîðé~~~~~~~~~~~⟧',
  'progress_error.body[2].text': '⟦Ýöûŕ ðàţà îš šàƒé öñ ţĥîš þĥöñé. Ţŕý àĝàîñ îñ à ɱöɱéñţ.~~~~~~~~~~~~~~~~~⟧',
  'progress_error.body[3].label': '⟦Ţŕý àĝàîñ~~~~⟧',
  'progress_error.body[4].text': '⟦Ŕéƒéŕéñçé 5ẋẋ-2Ƒ91 · ŕéþöŕţš ñéṽéŕ îñçļûðé ĥéàļţĥ ðàţà~~~~~~~~~~~~~~~~~⟧',
  'progress_error.header.title': '⟦Þŕöĝŕéšš~~~~⟧',
  'learn.body[0].label': '⟦Šéàŕçĥ~~~⟧',
  'learn.body[0].placeholder': '⟦Šéàŕçĥ çŕàṽîñĝš, šļééþ, ƀļööð þŕéššûŕé…~~~~~~~~~~~~~⟧',
  'learn.body[1].options[0]': '⟦Ƒöŕ ýöû~~~⟧',
  'learn.body[2].tagExtra': '⟦Ƒöŕ ǫûîţ ðàý~~~~⟧',
  'learn.body[2].title': '⟦Çŕàṽîñĝš: ŵĥàţ ţö éẋþéçţ ţöðàý~~~~~~~~~~⟧',
  'learn.body[2].text': '⟦4 ɱîñ ŕéàð · 3:12 àûðîö · ðöŵñļöàðéð~~~~~~~~~⟧',
  'learn.body[3].tagExtra': '⟦2 ɱîñ~~⟧',
  'learn.body[3].title': '⟦Ŵĥý “öñé ɱöŕé ṽîðéö” ñéṽéŕ ƒééļš ļîķé éñöûĝĥ~~~~~~~~~~~~~~⟧',
  'learn.body[4].tagExtra': '⟦Ļéàŕñ öñļý~~~~⟧',
  'learn.body[4].title': '⟦Ĥöŵ ýöûŕ ļûñĝš ŕéçöṽéŕ àƒţéŕ ýöû ǫûîţ~~~~~~~~~~~~~⟧',
  'learn.body[5].text': '⟦Çļîñîçàļļý ŕéṽîéŵéð · Ļîƀŕàŕý ṽ4.1 · Éñĝļîšĥ àñð Šþàñîšĥ~~~~~~~~~~~~~~~~~~⟧',
  'learn.header.title': '⟦Ļéàŕñ~~⟧',
  'learn_error.body[1].text': '⟦Çàñ’ţ ļöàð ļéššöñš~~~~~~⟧',
  'learn_error.body[2].text': '⟦Çĥéçķ ýöûŕ çöññéçţîöñ. Ðöŵñļöàðéð ļéššöñš šţîļļ ŵöŕķ.~~~~~~~~~~~~~~~~~~⟧',
  'learn_error.body[3].label': '⟦Ţŕý àĝàîñ~~~~⟧',
  'learn_error.body[4].label': '⟦Öþéñ ðöŵñļöàðš~~~~~~⟧',
  'learn_error.header.title': '⟦Ļéàŕñ~~⟧',
  'learn_lesson.body[0].extra': '⟦Ƒöŕ ǫûîţ ðàý~~~~⟧',
  'learn_lesson.body[1].text': '⟦Çŕàṽîñĝš: ŵĥàţ ţö éẋþéçţ ţöðàý~~~~~~~~~~⟧',
  'learn_lesson.body[2].eyebrow': '⟦Àûðîö · 3:12~~⟧',
  'learn_lesson.body[2].title': '⟦Ļîšţéñ îñšţéàð~~~~~~⟧',
  'learn_lesson.body[2].children[0].items[0].action.value': '⟦Þļàýîñĝ àûðîö~~~~~⟧',
  'learn_lesson.body[2].children[0].items[0].label': '⟦Þļàý~~⟧',
  'learn_lesson.body[2].children[0].items[1].action.value': '⟦Ţŕàñšçŕîþţ öþéñéð~~~~~~~⟧',
  'learn_lesson.body[2].children[0].items[1].label': '⟦Ţŕàñšçŕîþţ~~~~⟧',
  'learn_lesson.body[3].text': '⟦Ṁöšţ çŕàṽîñĝš þéàķ àñð ƒàðé ŵîţĥîñ 3–5 ɱîñûţéš. Ķñöŵîñĝ ţĥàţ ɱàķéš ţĥéɱ éàšîéŕ ţö ŕîðé öûţ. Ţöðàý, þļàñ ŵĥàţ ýöû’ļļ ðö îñ ţĥé ƒîŕšţ 5 ɱîñûţéš öƒ éàçĥ çŕàṽîñĝ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'learn_lesson.body[4].text': '⟦Ţĥîš ƒééļîñĝ ŵîļļ þàšš.~~~~~~~~⟧',
  'learn_lesson.body[4].caption': '⟦Ƒŕöɱ ýöûŕ þļàñ~~~~~⟧',
  'learn_lesson.body[5].text': '⟦Çļîñîçàļļý ŕéṽîéŵéð · çöñţéñţ ṽ3.2 · Àûĝ 2026~~~~~~~~~~~~⟧',
  'learn_lesson.footer[0].action.then.value': '⟦Ļéššöñ çöɱþļéţé~~~~~~⟧',
  'learn_lesson.footer[0].label': '⟦Ṁàŕķ çöɱþļéţé~~~~~⟧',
  'learn_lesson.footer[1].label': '⟦Šàṽé ƒöŕ öƒƒļîñé~~~~~~⟧',
  'learn_lesson.footer[1].action.value': '⟦Šàṽéð ƒöŕ öƒƒļîñé~~~~~~⟧',
  'learn_lesson.header.title': '⟦Ļéššöñ~~~⟧',
  'learn_lesson.header.pill': '⟦4 ɱîñ~~⟧',
  'support.body[0].eyebrow': '⟦Ƒŕéé & çöñƒîðéñţîàļ · ƁŕéàţĥéƑŕéé~~~~~~~~~~~⟧',
  'support.body[0].title': '⟦Ǫûîţļîñé çöûñšéļöŕ~~~~~~~⟧',
  'support.body[0].text': '⟦1-800-ǪÛÎŢ-ÑÖŴ · Éšþàñöļ 1-855-335-3569~~~~~~⟧',
  'support.body[0].children[0].items[0].label': '⟦Çàļļ ñöŵ~~~⟧',
  'support.body[0].children[0].items[1].label': '⟦Ŕéǫûéšţ çàļļ-ƀàçķ~~~~~~⟧',
  'support.body[1].rows[0].label': '⟦Ĵöŕðàñ~~~⟧',
  'support.body[1].rows[0].sub': '⟦Šûþþöŕţéŕ · ƁŕéàţĥéƑŕéé öñļý~~~~~~~~~~⟧',
  'support.body[1].rows[1].label': '⟦Àðð à ŠçŕöļļƑŕéé ƀûððý~~~~~~~~⟧',
  'support.body[1].title': '⟦Ýöûŕ þéöþļé~~~~⟧',
  'support.body[2].rows[0].label': '⟦Ðŕ. Þàţéļ’š çļîñîç~~~~~~⟧',
  'support.body[2].rows[0].sub': '⟦Ĥéàŕţŵîšé · ÇļéàŕÀîŕ~~~~~~~⟧',
  'support.body[2].title': '⟦Çàŕé ţéàɱ~~~~⟧',
  'support.body[3].text': '⟦Ţĥöûĝĥţš öƒ ĥàŕɱîñĝ ýöûŕšéļƒ? Çàļļ öŕ ţéẋţ 988. Éɱéŕĝéñçý: 911.~~~~~~~~~~~~~~~~~~⟧',
  'support.body[3].actions[0].label': '⟦Çàļļ öŕ ţéẋţ 988~~~~⟧',
  'support.body[3].actions[1].label': '⟦Çàļļ 911~~⟧',
  'support.header.title': '⟦Šûþþöŕţ~~~⟧',
  'support_empty.body[0].eyebrow': '⟦Ƒŕéé & çöñƒîðéñţîàļ~~~~~~~⟧',
  'support_empty.body[0].title': '⟦Ǫûîţļîñé çöûñšéļöŕ~~~~~~~⟧',
  'support_empty.body[0].cta[0].label': '⟦Çàļļ~~⟧',
  'support_empty.body[1].eyebrow': '⟦Ýöûŕ þéöþļé~~~~⟧',
  'support_empty.body[1].title': '⟦Ñö öñé àððéð ýéţ~~~~~~⟧',
  'support_empty.body[1].text': '⟦À ƒŕîéñð öŕ ƒàɱîļý ɱéɱƀéŕ ĝéţš à šĥöŕţ ĥéļþ þĥŕàšé ƒŕöɱ ýöû, öñļý ŵĥéñ ýöû çĥööšé ţö šéñð îţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'support_empty.body[1].cta[0].label': '⟦Àðð~~⟧',
  'support_empty.body[2].eyebrow': '⟦Çàŕé ţéàɱ~~~~⟧',
  'support_empty.body[2].title': '⟦Ñöţ çöññéçţéð~~~~~⟧',
  'support_empty.body[2].text': '⟦Çöññéçţ à çļîñîç ţö šĥàŕé šûɱɱàŕîéš ýöû àþþŕöṽé.~~~~~~~~~~~~~~~~⟧',
  'support_empty.body[2].cta[0].label': '⟦Çöññéçţ~~~⟧',
  'support_empty.body[3].text': '⟦Ţĥöûĝĥţš öƒ ĥàŕɱîñĝ ýöûŕšéļƒ? Çàļļ öŕ ţéẋţ 988. Éɱéŕĝéñçý: 911.~~~~~~~~~~~~~~~~~~⟧',
  'support_empty.body[3].actions[0].label': '⟦Çàļļ öŕ ţéẋţ 988~~~~⟧',
  'support_empty.body[3].actions[1].label': '⟦Çàļļ 911~~⟧',
  'support_empty.header.title': '⟦Šûþþöŕţ~~~⟧',
  'support_callback.body[0].text': '⟦Ŕéǫûéšţ à çöûñšéļöŕ çàļļ-ƀàçķ?~~~~~~~~~~⟧',
  'support_callback.body[1].text': '⟦Ŕéṽîéŵ éẋàçţļý ŵĥàţ ŵîļļ ƀé šéñţ ƀéƒöŕé ýöû àĝŕéé.~~~~~~~~~~~~~~~~~⟧',
  'support_callback.body[2].rows[0][0]': '⟦Šéñţ ţö~~~⟧',
  'support_callback.body[2].rows[0][1]': '⟦Çàļîƒöŕñîà Šɱöķéŕš’ Ĥéļþļîñé~~~~~~~~~~⟧',
  'support_callback.body[2].rows[1][0]': '⟦Šĥàŕéð~~~⟧',
  'support_callback.body[2].rows[1][1]': '⟦Ƒîŕšţ ñàɱé, þĥöñé, þŕéƒéŕŕéð ţîɱé~~~~~~~~~~~⟧',
  'support_callback.body[2].rows[2][0]': '⟦Ñöţ šĥàŕéð~~~~⟧',
  'support_callback.body[2].rows[2][1]': '⟦Ýöûŕ þļàñ, çĥéçķ-îñš, ĥéàļţĥ ðéţàîļš~~~~~~~~~~~~⟧',
  'support_callback.body[2].rows[3][0]': '⟦Çöñšéñţ éẋþîŕéš~~~~~~⟧',
  'support_callback.body[2].rows[3][1]': '⟦30 ðàýš~~⟧',
  'support_callback.body[3].label': '⟦Ɓéšţ ţîɱé ţö çàļļ~~~~~~⟧',
  'support_callback.body[3].placeholder': '⟦Ŵééķðàýš àƒţéŕ 5 ÞṀ~~~~~~⟧',
  'support_callback.footer[0].action.then.value': '⟦Ŕéǫûéšţ šéñţ. Éẋþéçţ à çàļļ ŵîţĥîñ 2 ƀûšîñéšš ðàýš.~~~~~~~~~~~~~~~~⟧',
  'support_callback.footer[0].label': '⟦Šéñð ŕéƒéŕŕàļ~~~~~⟧',
  'support_callback.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'support_message.body[0].text': '⟦Šéñð ţö Ĵöŕðàñ?~~~~~⟧',
  'support_message.body[1].eyebrow': '⟦Þŕéṽîéŵ~~~⟧',
  'support_message.body[1].title': '⟦“Çàñ ýöû šţàý ŵîţĥ ɱé ƒöŕ ţĥé ñéẋţ 10 ɱîñûţéš?”~~~~~~~~~~~~~~⟧',
  'support_message.body[1].text': '⟦Šéñţ ƒŕöɱ ýöûŕ þĥöñé’š Ṁéššàĝéš àþþ. Ţéţĥéŕ ñéṽéŕ šéñðš öñ îţš öŵñ.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'support_message.footer[0].label': '⟦Öþéñ Ṁéššàĝéš~~~~~⟧',
  'support_message.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'support_message_care.body[0].text': '⟦Šéçûŕé ɱéššàĝé · ûšûàļļý ŕéþļîéš ŵîţĥîñ 1 ƀûšîñéšš ðàý. Ñöţ ƒöŕ éɱéŕĝéñçîéš.~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'support_message_care.body[1].label': '⟦Ţöþîç~~⟧',
  'support_message_care.body[1].placeholder': '⟦Ǫûéšţîöñ àƀöûţ ɱý þļàñ~~~~~~~~⟧',
  'support_message_care.body[2].label': '⟦Ṁéššàĝé~~~⟧',
  'support_message_care.body[2].placeholder': '⟦Î’ṽé ƀééñ ƒééļîñĝ ðîžžý îñ ţĥé ɱöŕñîñĝš šîñçé šţàŕţîñĝ ţĥé þàţçĥ.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'support_message_care.body[3].label': '⟦Àţţàçĥ à šûɱɱàŕý~~~~~~⟧',
  'support_message_care.body[3].sub': '⟦Ýöû’ļļ þŕéṽîéŵ îţ ƀéƒöŕé šéñðîñĝ~~~~~~~~~~~⟧',
  'support_message_care.body[4].text': '⟦Çĥéšţ þàîñ, ţŕöûƀļé ƀŕéàţĥîñĝ öŕ ţĥöûĝĥţš öƒ ĥàŕɱîñĝ ýöûŕšéļƒ? Çàļļ 911 · çàļļ öŕ ţéẋţ 988.~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'support_message_care.body[4].actions[0].label': '⟦Çàļļ öŕ ţéẋţ 988~~~~⟧',
  'support_message_care.body[4].actions[1].label': '⟦Çàļļ 911~~⟧',
  'support_message_care.footer[0].action.then.value': '⟦Ṁéššàĝé šéñţ~~~~~⟧',
  'support_message_care.footer[0].label': '⟦Šéñð ɱéššàĝé~~~~~⟧',
  'support_message_care.header.title': '⟦Ðŕ. Þàţéļ’š çļîñîç~~~~~~⟧',
  'support_add_person.body[0].text': '⟦Ŵĥö çàñ ýöû çöûñţ öñ?~~~~~~~⟧',
  'support_add_person.body[1].label': '⟦Ñàɱé~~⟧',
  'support_add_person.body[1].placeholder': '⟦Ĵöŕðàñ~~~⟧',
  'support_add_person.body[2].label': '⟦Þĥöñé~~⟧',
  'support_add_person.body[3].label': '⟦Ŵĥîçĥ þŕöĝŕàɱš?~~~~~~⟧',
  'support_add_person.body[4].label': '⟦Ĥéļþ þĥŕàšé~~~~⟧',
  'support_add_person.body[4].placeholder': '⟦Çàñ ýöû šţàý ŵîţĥ ɱé ƒöŕ ţĥé ñéẋţ 10 ɱîñûţéš?~~~~~~~~~~~~~~⟧',
  'support_add_person.body[5].text': '⟦Ñöţĥîñĝ îš šéñţ ûñţîļ ýöû þŕéṽîéŵ àñð ţàþ Šéñð.~~~~~~~~~~~~~~~~⟧',
  'support_add_person.footer[0].action.cases[0].action.then.value': '⟦Ĵöŕðàñ àððéð~~~~~⟧',
  'support_add_person.footer[0].action.cases[1].action.value': '⟦Šéļéçţ àţ ļéàšţ öñé þŕöĝŕàɱ.~~~~~~~~~~⟧',
  'support_add_person.footer[0].label': '⟦Šàṽé šûþþöŕţéŕ~~~~~~⟧',
  'support_add_person.header.title': '⟦Àðð à šûþþöŕţéŕ~~~~~~⟧',
  'support_connect.body[0].text': '⟦Éñţéŕ ýöûŕ çļîñîç’š îñṽîţé çöðé~~~~~~~~~~~⟧',
  'support_connect.body[1].label': '⟦Îñṽîţé çöðé~~~~⟧',
  'support_connect.body[1].placeholder': '⟦ÞÀŢÉĻ-4821~~⟧',
  'support_connect.body[2].text': '⟦Ýöûŕ çļîñîç ĝàṽé ýöû ţĥîš çöðé. Çöññéçţîñĝ šĥàŕéš ñöţĥîñĝ ûñţîļ ýöû àþþŕöṽé à šûɱɱàŕý.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'support_connect.footer[0].action.then.value': '⟦Çöññéçţéð ţö Ðŕ. Þàţéļ’š çļîñîç~~~~~~~~~~⟧',
  'support_connect.footer[0].label': '⟦Çöññéçţ~~~⟧',
  'support_connect.header.title': '⟦Çöññéçţ à çļîñîç~~~~~~⟧',
  'account.body[0].rows[0].label': '⟦Àļéẋ~~⟧',
  'account.body[0].rows[0].sub': '⟦àļéẋ@éẋàɱþļé.çöɱ~~~~~~⟧',
  'account.body[1].rows[0].label': '⟦Ĥéàļţĥ ŕéçöŕðš~~~~~~⟧',
  'account.body[1].rows[0].sub': '⟦2 šöûŕçéš · Éþîç, Ṁéðîçàŕé~~~~~~~~⟧',
  'account.body[1].rows[1].label': '⟦Šîĝñ-îñ ɱéţĥöðš~~~~~~⟧',
  'account.body[1].rows[1].sub': '⟦Àþþļé · éɱàîļ~~~~⟧',
  'account.body[1].title': '⟦Ýöûŕ ĥéàļţĥ ðàţà~~~~~~⟧',
  'account.body[2].rows[0].label': '⟦Þŕöĝŕàɱš & šĥàŕîñĝ~~~~~~⟧',
  'account.body[2].rows[0].sub': '⟦2 ƒöçûš · 1 ļéàŕñ · 1 þàûšéð~~~~~~~⟧',
  'account.body[2].rows[1].label': '⟦Ñöţîƒîçàţîöñš~~~~~~⟧',
  'account.body[2].rows[1].sub': '⟦Öñ · ǫûîéţ ĥöûŕš 9 ÞṀ–7 ÀṀ~~~~~~~⟧',
  'account.body[2].rows[2].label': '⟦Þŕîṽàçý & çöñšéñţ~~~~~~⟧',
  'account.body[2].rows[2].sub': '⟦Ŕéṽîéŵéð Àûĝ 22, 2026~~~~~⟧',
  'account.body[2].rows[3].label': '⟦Ýöûŕ ðàţà~~~~⟧',
  'account.body[2].rows[3].sub': '⟦Éẋþöŕţ öŕ ðéļéţé~~~~~~⟧',
  'account.body[2].title': '⟦Šéţţîñĝš~~~~⟧',
  'account.body[3].rows[0].label': '⟦Ţéẋţ šîžé & çöñţŕàšţ~~~~~~~⟧',
  'account.body[3].rows[0].sub': '⟦Ƒöļļöŵš ýöûŕ þĥöñé~~~~~~~⟧',
  'account.body[3].rows[1].label': '⟦Ļàñĝûàĝé~~~~⟧',
  'account.body[3].rows[1].sub': '⟦Éñĝļîšĥ~~~⟧',
  'account.body[3].rows[1].action.value': '⟦Ļàñĝûàĝé šéţ ţö Éñĝļîšĥ~~~~~~~~⟧',
  'account.body[3].rows[2].label': '⟦Ĥéļþ & ļéĝàļ~~~~⟧',
  'account.body[3].title': '⟦Àþþ~~⟧',
  'account.body[4].text': '⟦Ţéţĥéŕ Ĥéàļţĥ 1.0.0 (100)~~~~~⟧',
  'account.footer[0].label': '⟦Šîĝñ öûţ~~~⟧',
  'account.header.title': '⟦Àççöûñţ~~~⟧',
  'account_signin_methods.body[0].text': '⟦Ûšé àñý çöññéçţéð ɱéţĥöð ţö šîĝñ îñ. Ķééþ àţ ļéàšţ öñé.~~~~~~~~~~~~~~~~~~⟧',
  'account_signin_methods.body[1].rows[0].sub': '⟦Çöññéçţéð · Ĥîðé Ṁý Éɱàîļ~~~~~~~~⟧',
  'account_signin_methods.body[1].rows[0].pill': '⟦Þŕîɱàŕý~~~⟧',
  'account_signin_methods.body[1].rows[1].sub': '⟦Ñöţ çöññéçţéð~~~~~⟧',
  'account_signin_methods.body[1].rows[1].action.cases[0].action.value': '⟦Ĝööĝļé çöññéçţéð~~~~~~⟧',
  'account_signin_methods.body[1].rows[1].action.cases[2].action.value': '⟦Çàñçéļļéð~~~~⟧',
  'account_signin_methods.body[1].rows[2].label': '⟦Éɱàîļ & þàššŵöŕð~~~~~~⟧',
  'account_signin_methods.body[1].rows[2].sub': '⟦àļéẋ@éẋàɱþļé.çöɱ · šéţ à þàššŵöŕð~~~~~~~~~~~⟧',
  'account_signin_methods.body[2].text': '⟦Ţö ŕéɱöṽé Àþþļé, àðð àñöţĥéŕ ɱéţĥöð ƒîŕšţ. Ŕéɱöṽîñĝ à ɱéţĥöð ñéṽéŕ ðéļéţéš ýöûŕ ðàţà.~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'account_signin_methods.header.title': '⟦Šîĝñ-îñ ɱéţĥöðš~~~~~~⟧',
  'account_programs.body[0].text': '⟦2 öƒ 2 ƒöçûš šļöţš ûšéð~~~~~~~⟧',
  'account_programs.body[1].rows[0].sub': '⟦Ƒöçûš · šĥàŕîñĝ ɱàñûàļ~~~~~~~~⟧',
  'account_programs.body[1].rows[1].sub': '⟦Ƒöçûš · ñöţ šĥàŕéð~~~~~~⟧',
  'account_programs.body[1].rows[2].sub': '⟦Ļéàŕñ öñļý · ñö ðàţà~~~~~~⟧',
  'account_programs.body[1].rows[3].sub': '⟦Þàûšéð Šéþ 2 · ðàţà ķéþţ~~~~~~~⟧',
  'account_programs.footer[0].label': '⟦Àðð à þŕöĝŕàɱ~~~~~⟧',
  'account_programs.header.title': '⟦Þŕöĝŕàɱš & šĥàŕîñĝ~~~~~~⟧',
  'account_leave.body[0].text': '⟦Ļéàṽé ƁŕéàţĥéƑŕéé?~~~~~~~⟧',
  'account_leave.body[1].text': '⟦Ŕéɱîñðéŕš šţöþ ŕîĝĥţ àŵàý. Ýöûŕ öţĥéŕ þŕöĝŕàɱš àŕé ñöţ àƒƒéçţéð.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'account_leave.body[2].items[0].label': '⟦Ķééþ ɱý ðàţà~~~~⟧',
  'account_leave.body[2].items[0].sub': '⟦Ķéþţ ûñţîļ ýöû ðéļéţé îţ öŕ ðéļéţé ýöûŕ àççöûñţ. Ŕéĵöîñ àñýţîɱé.~~~~~~~~~~~~~~~~~~~~~⟧',
  'account_leave.body[2].items[0].badge': '⟦Ðéƒàûļţ~~~⟧',
  'account_leave.body[2].items[1].label': '⟦Ðéļéţé ƁŕéàţĥéƑŕéé ðàţà ñöŵ~~~~~~~~~~⟧',
  'account_leave.body[2].items[1].sub': '⟦63 çĥéçķ-îñš, 14 ŕéšçûéš, 1 þļàñ~~~~~~~~⟧',
  'account_leave.footer[0].action.then.value': '⟦Ýöû ļéƒţ ƁŕéàţĥéƑŕéé~~~~~~~~⟧',
  'account_leave.footer[0].label': '⟦Ļéàṽé ƁŕéàţĥéƑŕéé~~~~~~~⟧',
  'account_leave.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'account_notifications.body[0].children[0].label': '⟦Çĥéçķ-îñš àñð þļàñ ŕéɱîñðéŕš~~~~~~~~~~⟧',
  'account_notifications.body[0].children[0].sub': '⟦Àţ ɱöšţ 2 à ðàý~~~~⟧',
  'account_notifications.body[0].children[1].label': '⟦Šĥöŵ šéñšîţîṽé ðéţàîļš~~~~~~~~⟧',
  'account_notifications.body[0].children[1].sub': '⟦Öƒƒ: þŕöĝŕàɱ ñàɱéš àñð ĥéàļţĥ ðàţà ĥîððéñ~~~~~~~~~~~~~~⟧',
  'account_notifications.body[0].children[2].label': '⟦Ǫûîéţ ĥöûŕš~~~~⟧',
  'account_notifications.body[0].children[2].sub': '⟦9:00 ÞṀ – 7:00 ÀṀ · šàƒéţý àļéŕţš šţîļļ çöɱé ţĥŕöûĝĥ~~~~~~~~~~~~~⟧',
  'account_notifications.body[1].rows[0].sub': '⟦8:00 ÀṀ çĥéçķ-îñ~~~~⟧',
  'account_notifications.body[1].rows[0].action.value': '⟦Ŕéɱîñðéŕ ţîɱé šàṽéð~~~~~~~⟧',
  'account_notifications.body[1].rows[1].sub': '⟦9:30 ÞṀ ŵîñð-ðöŵñ~~~~⟧',
  'account_notifications.body[1].rows[1].action.value': '⟦Ŕéɱîñðéŕ ţîɱé šàṽéð~~~~~~~⟧',
  'account_notifications.body[1].title': '⟦Þéŕ þŕöĝŕàɱ~~~~⟧',
  'account_notifications.body[2].eyebrow': '⟦Ļöçķ šçŕééñ þŕéṽîéŵ~~~~~~~⟧',
  'account_notifications.body[2].text': '⟦Ýöû ĥàṽé à Ţéţĥéŕ ŕéɱîñðéŕ.~~~~~~~~~⟧',
  'account_notifications.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'account_notifications.footer[0].label': '⟦Šàṽé~~⟧',
  'account_notifications.header.title': '⟦Ñöţîƒîçàţîöñš~~~~~~⟧',
  'account_privacy.body[0].eyebrow': '⟦Çĥöîçéš~~~⟧',
  'account_privacy.body[0].children[0].label': '⟦Çŕöšš-þŕöĝŕàɱ îñšîĝĥţš~~~~~~~~⟧',
  'account_privacy.body[0].children[0].sub': '⟦Šĥöŵ çöññéçţîöñš ƀéţŵééñ ýöûŕ þŕöĝŕàɱš~~~~~~~~~~~~~~⟧',
  'account_privacy.body[0].children[1].label': '⟦Ðé-îðéñţîƒîéð ŕéšéàŕçĥ~~~~~~~~⟧',
  'account_privacy.body[0].children[1].sub': '⟦Þéŕ þŕöĝŕàɱ, öƒƒ ƀý ðéƒàûļţ~~~~~~~~~⟧',
  'account_privacy.body[0].children[2].label': '⟦Àñöñýɱöûš àþþ ðîàĝñöšţîçš~~~~~~~~~~⟧',
  'account_privacy.body[0].children[2].sub': '⟦Ñö ĥéàļţĥ éñţŕîéš~~~~~~⟧',
  'account_privacy.body[1].rows[0].label': '⟦Çàŕé-ţéàɱ šĥàŕîñĝ~~~~~~⟧',
  'account_privacy.body[1].rows[0].sub': '⟦Ṁàñûàļ öñļý · þŕéṽîéŵ éṽéŕý šĥàŕé~~~~~~~~~~~⟧',
  'account_privacy.body[1].rows[1].label': '⟦Çöñšéñţ ĥîšţöŕý~~~~~~⟧',
  'account_privacy.body[1].rows[1].sub': '⟦ṽ3 · Àûĝ 22, 2026~~⟧',
  'account_privacy.body[1].rows[1].action.value': '⟦Çöñšéñţ ĥîšţöŕý öþéñéð~~~~~~~~⟧',
  'account_privacy.body[1].rows[2].label': '⟦Þŕîṽàçý Ñöţîçé~~~~~~⟧',
  'account_privacy.body[2].text': '⟦Ñö àðš. Ŵé ñéṽéŕ šéļļ ýöûŕ ĥéàļţĥ ðàţà.~~~~~~~~~~~~⟧',
  'account_privacy.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'account_privacy.footer[0].label': '⟦Šàṽé~~⟧',
  'account_privacy.header.title': '⟦Þŕîṽàçý & çöñšéñţ~~~~~~⟧',
  'account_data.body[0].rows[0].label': '⟦Ðöŵñļöàð éṽéŕýţĥîñĝ~~~~~~~~⟧',
  'account_data.body[0].rows[0].sub': '⟦Éṽéŕý þŕöĝŕàɱ · ÞÐƑ + ĴŠÖÑ~~~~~~~~⟧',
  'account_data.body[0].rows[0].action.then.value': '⟦Ŵé’ŕé þŕéþàŕîñĝ ýöûŕ ƒîļé. Ŵé’ļļ ñöţîƒý ýöû ŵĥéñ îţ’š ŕéàðý.~~~~~~~~~~~~~~~~~~~⟧',
  'account_data.body[0].rows[1].label': '⟦Éẋþöŕţ à çàŕé šûɱɱàŕý~~~~~~~~⟧',
  'account_data.body[0].rows[1].sub': '⟦Çĥööšé ðàţéš àñð þŕéṽîéŵ éṽéŕý ðéţàîļ~~~~~~~~~~~~~⟧',
  'account_data.body[0].title': '⟦Éẋþöŕţ~~~⟧',
  'account_data.body[1].rows[0].label': '⟦Ðéļéţé àççöûñţ àñð àļļ ðàţà~~~~~~~~~~⟧',
  'account_data.body[1].rows[0].sub': '⟦Þéŕɱàñéñţ · ŕéǫûîŕéš çöñƒîŕɱàţîöñ~~~~~~~~~~~~⟧',
  'account_data.body[1].title': '⟦Ðéļéţé~~~⟧',
  'account_data.header.title': '⟦Ýöûŕ ðàţà~~~~⟧',
  'account_delete.body[0].text': '⟦Ðéļéţé ýöûŕ àççöûñţ àñð àļļ ðàţà?~~~~~~~~~~~⟧',
  'account_delete.body[1].rows[0][0]': '⟦Þŕöĝŕàɱš~~~~⟧',
  'account_delete.body[1].rows[1][0]': '⟦Çĥéçķ-îñš~~~~⟧',
  'account_delete.body[1].rows[2][0]': '⟦Ŕéàðîñĝš & ļöĝš~~~~~⟧',
  'account_delete.body[1].rows[3][0]': '⟦Šĥàŕéð ŵîţĥ çàŕé ţéàɱ~~~~~~~~⟧',
  'account_delete.body[1].rows[3][1]': '⟦3 šûɱɱàŕîéš (ţĥéîŕ çöþîéš šţàý ŵîţĥ ţĥéɱ)~~~~~~~~~~~~~⟧',
  'account_delete.body[2].text': '⟦Ţĥîš çàñ’ţ ƀé ûñðöñé. Ðöŵñļöàð à çöþý ƒîŕšţ îƒ ýöû ŵàñţ öñé.~~~~~~~~~~~~~~~~~~~⟧',
  'account_delete.body[3].label': '⟦Ðöŵñļöàð à çöþý ƒîŕšţ~~~~~~~~⟧',
  'account_delete.body[4].label': '⟦Ţýþé ÐÉĻÉŢÉ ţö çöñƒîŕɱ~~~~~~~~⟧',
  'account_delete.body[4].placeholder': '⟦ÐÉĻÉŢÉ~~~⟧',
  'account_delete.body[5].label': '⟦Þàššŵöŕð~~~~⟧',
  'account_delete.body[5].hint': '⟦Ŵé àšķ àĝàîñ ţö þŕöţéçţ ýöûŕ àççöûñţ.~~~~~~~~~~~~⟧',
  'account_delete.footer[0].label': '⟦Ðéļéţé éṽéŕýţĥîñĝ~~~~~~~⟧',
  'account_delete.header.title': '⟦Ðéļéţé àççöûñţ~~~~~~⟧',
  'account_deleted.body[1].text': '⟦Ýöûŕ ðàţà ĥàš ƀééñ ðéļéţéð.~~~~~~~~~⟧',
  'account_deleted.body[2].rows[0][0]': '⟦Ŕéçéîþţ~~~⟧',
  'account_deleted.body[2].rows[0][1]': '⟦ÐÉĻ-7Ƒ3À-21Ç9~~~⟧',
  'account_deleted.body[2].rows[1][0]': '⟦Çöɱþļéţéð~~~~⟧',
  'account_deleted.body[2].rows[1][1]': '⟦Öçţ 17, 2026 · 9:41 ÀṀ~~⟧',
  'account_deleted.body[2].rows[2][0]': '⟦Šîĝñéð öûţ öñ~~~~~⟧',
  'account_deleted.body[2].rows[2][1]': '⟦ţĥîš þĥöñé~~~~⟧',
  'account_deleted.body[3].text': '⟦Ķééþ ţĥîš ŕéçéîþţ îƒ ýöû çöñţàçţ šûþþöŕţ. Ɓàçķûþš àŕé þûŕĝéð ŵîţĥîñ 30 ðàýš.~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'account_deleted.footer[0].label': '⟦Ðöñé~~⟧',
  'account_deleted.header.title': '⟦Ðéļéţéð~~~⟧',
  'account_signout.body[0].text': '⟦Šîĝñ öûţ öƒ Ţéţĥéŕ?~~~~~~⟧',
  'account_signout.body[1].text': '⟦Éñçŕýþţéð þŕöĝŕàɱ ðàţà öñ ţĥîš þĥöñé îš ŕéɱöṽéð. Ýöûŕ àççöûñţ ðàţà šţàýš šàƒé îñ ţĥé çļöûð.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'account_signout.footer[0].label': '⟦Šîĝñ öûţ~~~⟧',
  'account_signout.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'sys_update.body[1].text': '⟦À šàƒéţý ûþðàţé îš ŕéàðý~~~~~~~~⟧',
  'sys_update.body[2].text': '⟦Ţĥîš ṽéŕšîöñ ĥàš îɱþöŕţàñţ ƒîẋéš. Ŕéšçûé àñð Šûþþöŕţ šţîļļ ŵöŕķ ûñţîļ ýöû ûþðàţé.~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sys_update.footer[0].label': '⟦Ûþðàţé ñöŵ~~~~⟧',
  'sys_update.footer[1].label': '⟦Öþéñ Ŕéšçûé~~~~⟧',
  'sys_update.header.title': '⟦Ûþðàţé ñééðéð~~~~~⟧',
  'bf_intro.body[0].extra': '⟦Ţöƀàççö & ñîçöţîñé~~~~~~⟧',
  'bf_intro.body[1].text': '⟦Ýöûŕ ñéẋţ ƀŕéàţĥ çàñ ƀé ðîƒƒéŕéñţ.~~~~~~~~~~~~⟧',
  'bf_intro.body[2].rows[0][0]': '⟦Ĥéļþ ŵĥéñ çŕàṽîñĝš ĥîţ~~~~~~~~⟧',
  'bf_intro.body[2].rows[0][1]': '⟦öñé ţàþ, ñö ţýþîñĝ~~~~~~⟧',
  'bf_intro.body[2].rows[1][0]': '⟦Þļàñ ýöûŕ ŵàý~~~~~⟧',
  'bf_intro.body[2].rows[1][1]': '⟦ðàţé · ţöðàý · ŕéðûçé · éẋþļöŕé~~~~~~~~~⟧',
  'bf_intro.body[2].rows[2][0]': '⟦Ṁéðîçîñéš~~~~⟧',
  'bf_intro.body[2].rows[2][1]': '⟦éðûçàţîöñ öñļý~~~~~~⟧',
  'bf_intro.body[3].text': '⟦Þļàñ, þŕàçţîçé àñð ĝéţ ţĥŕöûĝĥ çŕàṽîñĝš, ŵîţĥ ñö ĵûðĝɱéñţ. À šļîþ ñéṽéŕ éŕàšéš ýöûŕ ŵîñš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'bf_intro.footer[0].label': '⟦Šéţ ûþ ƁŕéàţĥéƑŕéé~~~~~~~⟧',
  'bf_intro.footer[1].action.then.value': '⟦ƁŕéàţĥéƑŕéé àððéð àš Ļéàŕñ öñļý~~~~~~~~~~~⟧',
  'bf_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'bf_intro.header.pill': '⟦~3 ɱîñ/ðàý~~~⟧',
  'bf_q1.body[1].text': '⟦Ǫûéšţîöñ 1 öƒ 3~~~~⟧',
  'bf_q1.body[2].text': '⟦Öñ à ţýþîçàļ ðàý, ĥöŵ ɱàñý çîĝàŕéţţéš?~~~~~~~~~~~~⟧',
  'bf_q1.body[3].items[0].label': '⟦Î ðöñ’ţ šɱöķé éṽéŕý ðàý~~~~~~~~⟧',
  'bf_q1.body[3].items[1].label': '⟦10 öŕ ƒéŵéŕ~~~⟧',
  'bf_q1.body[3].items[4].label': '⟦31 öŕ ɱöŕé~~~⟧',
  'bf_q1.body[4].title': '⟦Ŵĥý ŵé àšķ~~~~⟧',
  'bf_q1.body[4].text': '⟦Ţàîļöŕš ýöûŕ þļàñ àñð éšţîɱàţéš ɱöñéý šàṽéð. Ñöţ à ðîàĝñöšîš.~~~~~~~~~~~~~~~~~~~~⟧',
  'bf_q1.footer[0].label': '⟦Ñéẋţ~~⟧',
  'bf_q1.header.title': '⟦Àƀöûţ ýöûŕ šɱöķîñĝ~~~~~~~⟧',
  'bf_q1.header.pill': '⟦1 öƒ 3~⟧',
  'bf_q2.body[1].text': '⟦Çĥööšé àļļ ţĥàţ àþþļý~~~~~~~~⟧',
  'bf_q2.body[2].text': '⟦Ŵĥéñ ðö ýöû ɱöšţ ŵàñţ à çîĝàŕéţţé?~~~~~~~~~~~⟧',
  'bf_q2.body[3].options[0]': '⟦Šţŕéšš~~~⟧',
  'bf_q2.body[3].options[1]': '⟦Àƒţéŕ ɱéàļš~~~~⟧',
  'bf_q2.body[3].options[2]': '⟦Ðŕîṽîñĝ~~~⟧',
  'bf_q2.body[3].options[3]': '⟦Ŵîţĥ çöƒƒéé~~~~⟧',
  'bf_q2.body[3].options[4]': '⟦Šöçîàļ~~~⟧',
  'bf_q2.body[3].options[5]': '⟦Ŵöŕķ ƀŕéàķš~~~~⟧',
  'bf_q2.body[3].options[6]': '⟦Àļçöĥöļ~~~⟧',
  'bf_q2.body[3].options[7]': '⟦Ɓöŕéðöɱ~~~⟧',
  'bf_q2.body[3].options[8]': '⟦Ṁöŕñîñĝ~~~⟧',
  'bf_q2.body[3].options[9]': '⟦Šçŕöļļîñĝ~~~~⟧',
  'bf_q2.body[4].label': '⟦Àðð ýöûŕ öŵñ~~~~⟧',
  'bf_q2.body[4].placeholder': '⟦Ţýþé àñöţĥéŕ šîţûàţîöñ…~~~~~~~~⟧',
  'bf_q2.body[5].text': '⟦Ûšéð ţö þŕéþàŕé, ñéṽéŕ ţö ɱöñîţöŕ. Ñö ƀàçķĝŕöûñð ļöçàţîöñ.~~~~~~~~~~~~~~~~~~~⟧',
  'bf_q2.footer[0].label': '⟦Ñéẋţ~~⟧',
  'bf_q2.header.title': '⟦Ýöûŕ ţŕîĝĝéŕš~~~~~⟧',
  'bf_q2.header.pill': '⟦2 öƒ 3~⟧',
  'bf_q3.body[1].text': '⟦Ŵĥàţ àŕé ýöû ǫûîţţîñĝ ƒöŕ?~~~~~~~~~⟧',
  'bf_q3.body[2].text': '⟦Çĥööšé àļļ ţĥàţ ɱàţţéŕ. Ýöûŕ ţöþ ŕéàšöñ àþþéàŕš ŵĥéñ à çŕàṽîñĝ ĥîţš.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'bf_q3.body[3].options[0]': '⟦Þŕöţéçţ ɱý ƒàɱîļý~~~~~~⟧',
  'bf_q3.body[3].options[1]': '⟦Ɓŕéàţĥé éàšîéŕ~~~~~~⟧',
  'bf_q3.body[3].options[2]': '⟦Šàṽé ɱöñéý~~~~⟧',
  'bf_q3.body[3].options[3]': '⟦Ƒééļ îñ çöñţŕöļ~~~~~~⟧',
  'bf_q3.body[3].options[4]': '⟦Ṁý ĥéàļţĥ~~~~⟧',
  'bf_q3.body[3].options[5]': '⟦Ɓé ţĥéŕé ƒöŕ ɱý ƒûţûŕé~~~~~~~~⟧',
  'bf_q3.body[4].eyebrow': '⟦Ŵĥéñ à çŕàṽîñĝ ĥîţš~~~~~~~⟧',
  'bf_q3.body[4].children[0].text': '⟦Ýöû çĥöšé ţĥîš ƒöŕ ýöûŕ ƒàɱîļý. Ţĥîš ƒééļîñĝ ŵîļļ þàšš.~~~~~~~~~~~~~~~~~~⟧',
  'bf_q3.footer[0].label': '⟦Šàṽé ɱý ŕéàšöñš~~~~~~⟧',
  'bf_q3.header.title': '⟦Ýöûŕ ŕéàšöñš~~~~~⟧',
  'bf_q3.header.pill': '⟦3 öƒ 3~⟧',
  'bf_path.body[0].text': '⟦Ŵĥàţ ƒééļš þöššîƀļé ŕîĝĥţ ñöŵ?~~~~~~~~~~⟧',
  'bf_path.body[1].text': '⟦Ţĥéŕé’š ñö ŵŕöñĝ þļàçé ţö šţàŕţ.~~~~~~~~~~⟧',
  'bf_path.body[2].items[0].label': '⟦Šéţ à ǫûîţ ðàţé~~~~~⟧',
  'bf_path.body[2].items[0].sub': '⟦Þŕéþàŕé 7–14 ðàýš, ţĥéñ šţöþ~~~~~~~~⟧',
  'bf_path.body[2].items[0].badge': '⟦Ŕéçöɱɱéñðéð~~~~~⟧',
  'bf_path.body[2].items[1].label': '⟦Ǫûîţ ţöðàý~~~~⟧',
  'bf_path.body[2].items[1].sub': '⟦Šķîþ ţĥé çàļéñðàŕ; éẋţŕà šûþþöŕţ ñöŵ~~~~~~~~~~~~⟧',
  'bf_path.body[2].items[2].label': '⟦Ŕéðûçé ĝŕàðûàļļý~~~~~~⟧',
  'bf_path.body[2].items[2].sub': '⟦Šţéþ ðöŵñ ţö žéŕö öṽéŕ 4 ŵééķš~~~~~~~~~~⟧',
  'bf_path.body[2].items[3].label': '⟦Éẋþļöŕé ƒîŕšţ~~~~~⟧',
  'bf_path.body[2].items[3].sub': '⟦Ñö ðàţé. Ļéššöñš àñð Ŕéšçûé öñļý~~~~~~~~~~~⟧',
  'bf_path.body[3].title': '⟦Ţàļķ ţö à þéŕšöñ ƒîŕšţ?~~~~~~~~⟧',
  'bf_path.body[3].text': '⟦Ǫûîţļîñé çöûñšéļöŕ öŕ ýöûŕ çàŕé ţéàɱ~~~~~~~~~~~~~⟧',
  'bf_path.footer[0].label': '⟦Çöñţîñûé ŵîţĥ ţĥîš þàţĥ~~~~~~~~⟧',
  'bf_path.header.title': '⟦Ýöûŕ þàţĥ~~~~⟧',
  'bf_path.header.pill': '⟦Þļàñ 1 öƒ 3~~~⟧',
  'bf_date.body[0].text': '⟦Çĥööšé à ðàý ţö ƀéĝîñ.~~~~~~~⟧',
  'bf_date.body[1].text': '⟦7–14 ðàýš àŵàý ĝîṽéš ýöû ţîɱé ţö þŕéþàŕé ŵîţĥöûţ ļöšîñĝ ɱöɱéñţûɱ.~~~~~~~~~~~~~~~~~~~~⟧',
  'bf_date.body[2].month': '⟦Àûĝûšţ 2026~~~⟧',
  'bf_date.body[3].eyebrow': '⟦Ýöûŕ ǫûîţ ðàţé~~~~~⟧',
  'bf_date.body[3].title': '⟦Ƒŕîðàý, Àûĝûšţ 28, 2026~~~~~⟧',
  'bf_date.body[3].text': '⟦7 ðàýš ţö þŕéþàŕé · Þàçîƒîç Ţîɱé~~~~~~~~~~⟧',
  'bf_date.body[4].label': '⟦Ǫûîţ-ðàý çĥéçķ-îñ àţ 7:00 ÀṀ~~~~~~~~⟧',
  'bf_date.body[4].sub': '⟦Ļöçķ šçŕééñ: “Ýöû ĥàṽé à Ţéţĥéŕ ŕéɱîñðéŕ.”~~~~~~~~~~~~~⟧',
  'bf_date.footer[0].label': '⟦Çöñƒîŕɱ ţĥîš ðàţé~~~~~~⟧',
  'bf_date.header.title': '⟦Ǫûîţ ðàţé~~~~⟧',
  'bf_date.header.pill': '⟦Þļàñ 2 öƒ 3~~~⟧',
  'bf_stepdown.body[0].text': '⟦Çûţ ƀàçķ àţ ýöûŕ þàçé.~~~~~~~⟧',
  'bf_stepdown.body[1].text': '⟦Ƒŕöɱ ýöûŕ ƀàšéļîñé öƒ 15 à ðàý. Àðĵûšţ àñý ŵééķ.~~~~~~~~~~~~~~⟧',
  'bf_stepdown.body[2].rows[0][0]': '⟦Ţĥîš ŵééķ~~~~⟧',
  'bf_stepdown.body[2].rows[0][1]': '⟦15 → 12 à ðàý~~⟧',
  'bf_stepdown.body[2].rows[1][0]': '⟦Ŵééķ 2~~⟧',
  'bf_stepdown.body[2].rows[1][1]': '⟦9 à ðàý~~⟧',
  'bf_stepdown.body[2].rows[2][0]': '⟦Ŵééķ 3~~⟧',
  'bf_stepdown.body[2].rows[2][1]': '⟦5 à ðàý~~⟧',
  'bf_stepdown.body[2].rows[3][0]': '⟦Ŵééķ 4~~⟧',
  'bf_stepdown.body[2].rows[3][1]': '⟦2 à ðàý~~⟧',
  'bf_stepdown.body[2].rows[4][0]': '⟦Ǫûîţ ðàý · Šéþ 18~~~~⟧',
  'bf_stepdown.body[3].text': '⟦Ŕéðûçîñĝ ŵöŕķš ƀéšţ þàîŕéð ŵîţĥ à ǫûîţ ðàţé. Àšķ ýöûŕ çļîñîçîàñ àƀöûţ ñîçöţîñé ŕéþļàçéɱéñţ ŵĥîļé çûţţîñĝ ðöŵñ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'bf_stepdown.footer[0].label': '⟦Šàṽé šçĥéðûļé~~~~~⟧',
  'bf_stepdown.header.title': '⟦Šţéþ-ðöŵñ šçĥéðûļé~~~~~~~⟧',
  'bf_stepdown.header.pill': '⟦Þļàñ 2 öƒ 3~~~⟧',
  'bf_support.body[0].text': '⟦Ýöû ðöñ’ţ ĥàṽé ţö ðö ţĥîš àļöñé.~~~~~~~~~~⟧',
  'bf_support.body[1].rows[0].label': '⟦Ĵöŕðàñ~~~⟧',
  'bf_support.body[1].rows[0].sub': '⟦Ƒŕîéñð · ţéẋţ ɱéššàĝé · éṽéñîñĝ ƀéƒöŕé~~~~~~~~~~~~⟧',
  'bf_support.body[1].rows[1].label': '⟦Àðð à šûþþöŕţéŕ~~~~~~⟧',
  'bf_support.body[1].title': '⟦Ýöûŕ šûþþöŕţ çîŕçļé~~~~~~~⟧',
  'bf_support.body[2].eyebrow': '⟦Þŕéþàŕé ýöûŕ šþàçé · 2 öƒ 3~~~~~~~~⟧',
  'bf_support.body[2].children[0].items[0].label': '⟦Ŕéɱöṽé çîĝàŕéţţéš, ļîĝĥţéŕš, àšĥţŕàýš~~~~~~~~~~~~~⟧',
  'bf_support.body[2].children[0].items[1].label': '⟦Ṁàķé ĥöɱé àñð çàŕ šɱöķé-ƒŕéé~~~~~~~~~~⟧',
  'bf_support.body[2].children[0].items[2].label': '⟦Šţöçķ ĝûɱ, ŵàţéŕ öŕ šñàçķš~~~~~~~~~⟧',
  'bf_support.body[3].label': '⟦Ŕéɱîñð ɱé ţö ðîšçûšš ǫûîţ ɱéðîçîñéš ŵîţĥ ɱý çàŕé ţéàɱ~~~~~~~~~~~~~~~~~~⟧',
  'bf_support.body[3].sub': '⟦Éðûçàţîöñ öñļý. Ţĥé àþþ ñéṽéŕ þŕéšçŕîƀéš.~~~~~~~~~~~~~~⟧',
  'bf_support.footer[0].label': '⟦Ŕéṽîéŵ ɱý þļàñ~~~~~⟧',
  'bf_support.header.title': '⟦Šûþþöŕţ~~~⟧',
  'bf_support.header.pill': '⟦Þļàñ 3 öƒ 3~~~⟧',
  'bf_review.body[0].text': '⟦Ýöûŕ þļàñ îš ŕéàðý.~~~~~~⟧',
  'bf_review.body[1].text': '⟦Ţàþ àñý îţéɱ ţö éðîţ.~~~~~~~⟧',
  'bf_review.body[2].rows[0].label': '⟦Ǫûîţ àþþŕöàçĥ~~~~~⟧',
  'bf_review.body[2].rows[0].sub': '⟦Šéţ à ǫûîţ ðàţé~~~~~⟧',
  'bf_review.body[2].rows[1].label': '⟦Ǫûîţ ðàţé~~~~⟧',
  'bf_review.body[2].rows[1].sub': '⟦Ƒŕî, Àûĝ 28 · 7 ðàýš ţö þŕéþàŕé~~~~~~~~⟧',
  'bf_review.body[2].rows[2].label': '⟦Ţöþ ŕéàšöñ~~~~⟧',
  'bf_review.body[2].rows[2].sub': '⟦Þŕöţéçţ ɱý ƒàɱîļý~~~~~~⟧',
  'bf_review.body[2].rows[3].label': '⟦Šûþþöŕţ~~~⟧',
  'bf_review.body[2].rows[3].sub': '⟦Ĵöŕðàñ · éṽéñîñĝ ƀéƒöŕé~~~~~~~~⟧',
  'bf_review.body[2].rows[4].label': '⟦Šþàçé~~⟧',
  'bf_review.body[2].rows[4].sub': '⟦2 öƒ 3 ţàšķš ðöñé~~~~~⟧',
  'bf_review.body[3].text': '⟦Šţàŕţîñĝ ţûŕñš öñ ýöûŕ þŕéþàŕàţîöñ ţàšķš àñð ŕéɱîñðéŕš. Šûþþöŕţ ɱéššàĝéš àļŵàýš ñééð ýöûŕ àþþŕöṽàļ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'bf_review.footer[0].label': '⟦Šţàŕţ ɱý þļàñ~~~~~⟧',
  'bf_review.footer[1].label': '⟦Šàṽé àñð ƒîñîšĥ ļàţéŕ~~~~~~~~⟧',
  'bf_review.header.title': '⟦Ŕéṽîéŵ ýöûŕ þļàñ~~~~~~⟧',
  'bf_review.header.pill': '⟦Ŕéàðý~~⟧',
  'bf_home.body[0].eyebrow': '⟦Ýöûŕ ǫûîţ ðàý~~~~~⟧',
  'bf_home.body[0].children[0].value': '⟦7 ðàýš~~⟧',
  'bf_home.body[0].children[0].caption': '⟦Ƒŕîðàý, Àûĝûšţ 28 · Þàçîƒîç Ţîɱé~~~~~~~~~~⟧',
  'bf_home.body[1].title': '⟦Çŕàṽîñĝ ñöŵ?~~~~⟧',
  'bf_home.body[1].text': '⟦Öñé ţàþ · ñö ţýþîñĝ~~~~~~⟧',
  'bf_home.body[1].cta[0].label': '⟦Ŕéšçûé~~~⟧',
  'bf_home.body[2].eyebrow': '⟦Ţöðàý’š šţéþ~~~~⟧',
  'bf_home.body[2].children[0].items[0].label': '⟦Šţöçķ ĝûɱ, ŵàţéŕ öŕ ĥéàļţĥý šñàçķš~~~~~~~~~~~~⟧',
  'bf_home.body[2].children[0].items[0].sub': '⟦Àƀöûţ 3 ɱîñûţéš~~~~~⟧',
  'bf_home.body[3].eyebrow': '⟦Ýöûŕ ţöþ ŕéàšöñ~~~~~~⟧',
  'bf_home.body[3].children[0].text': '⟦Þŕöţéçţ ɱý ƒàɱîļý.~~~~~~⟧',
  'bf_home.body[4].rows[0].label': '⟦Ðàîļý çĥéçķ-îñ~~~~~⟧',
  'bf_home.body[4].rows[0].sub': '⟦Àƀöûţ 60 šéçöñðš~~~~~⟧',
  'bf_home.body[4].rows[1].label': '⟦Ṁéðîçàţîöñ çéñţéŕ~~~~~~~⟧',
  'bf_home.body[4].rows[1].sub': '⟦Ñîçöţîñé þàţçĥ · ŕéçöŕðéð þļàñ~~~~~~~~~~⟧',
  'bf_home.body[4].rows[2].label': '⟦Þŕöĝŕéšš~~~~⟧',
  'bf_home.body[4].rows[2].sub': '⟦Šàṽéð \$42.70 šö ƒàŕ~~~~⟧',
  'bf_home.body[4].rows[3].label': '⟦Éðîţ ɱý þļàñ~~~~⟧',
  'bf_home.body[4].rows[4].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'bf_home.body[4].rows[4].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'bf_home_quitday.body[0].text': '⟦Ǫûîţ ðàý · Àûĝ 28~~~~⟧',
  'bf_home_quitday.body[1].text': '⟦Ķééþ ţöðàý šîɱþļé.~~~~~~⟧',
  'bf_home_quitday.body[2].eyebrow': '⟦Šîñçé ýöûŕ ǫûîţ ţîɱé~~~~~~~⟧',
  'bf_home_quitday.body[2].children[0].value': '⟦2ĥ 41ɱ~⟧',
  'bf_home_quitday.body[2].children[0].caption': '⟦Šţàŕţéð 7:00 ÀṀ · Þàçîƒîç~~~~~~~⟧',
  'bf_home_quitday.body[3].title': '⟦Î ĥàṽé à çŕàṽîñĝ~~~~~~⟧',
  'bf_home_quitday.body[3].text': '⟦Öñé ţàþ · ñö ţýþîñĝ~~~~~~⟧',
  'bf_home_quitday.body[3].cta[0].label': '⟦Ŕéšçûé~~~⟧',
  'bf_home_quitday.body[4].title': '⟦Î šɱöķéð öŕ ĥàð à šļîþ~~~~~~~⟧',
  'bf_home_quitday.body[4].text': '⟦Ýöûŕ þŕöĝŕéšš ŵîļļ ñöţ ƀé éŕàšéð~~~~~~~~~~~⟧',
  'bf_home_quitday.body[5].eyebrow': '⟦Ñéẋţ ƀéšţ šţéþ~~~~~⟧',
  'bf_home_quitday.body[5].children[0].items[0].label': '⟦Ŵàţéŕ, ţĥéñ à 5-ɱîñûţé ŵàļķ~~~~~~~~⟧',
  'bf_home_quitday.body[5].children[0].items[0].sub': '⟦Ƒŕöɱ ýöûŕ ţŕîĝĝéŕ þļàñ~~~~~~~~⟧',
  'bf_home_quitday.body[6].rows[0].label': '⟦Ṁöŕñîñĝ çĥéçķ-îñ~~~~~~⟧',
  'bf_home_quitday.body[6].rows[1].label': '⟦Ṁéðîçàţîöñ çéñţéŕ~~~~~~~⟧',
  'bf_home_quitday.body[6].rows[1].sub': '⟦Þàţçĥ · ţàķéñ 8:07 ÀṀ~~~~~⟧',
  'bf_home_explore.body[0].text': '⟦Éẋþļöŕîñĝ · ñö ðàţé šéţ~~~~~~~~⟧',
  'bf_home_explore.body[1].text': '⟦Ļéàŕñ àţ ýöûŕ öŵñ þàçé.~~~~~~~~⟧',
  'bf_home_explore.body[2].title': '⟦Çŕàṽîñĝ ñöŵ?~~~~⟧',
  'bf_home_explore.body[2].text': '⟦Ŕéšçûé ŵöŕķš ŵîţĥöûţ à þļàñ~~~~~~~~~~⟧',
  'bf_home_explore.body[2].cta[0].label': '⟦Ŕéšçûé~~~⟧',
  'bf_home_explore.body[3].title': '⟦Çŕàṽîñĝš: ŵĥàţ ţö éẋþéçţ~~~~~~~~⟧',
  'bf_home_explore.body[3].text': '⟦4 ɱîñ ŕéàð~~~⟧',
  'bf_home_explore.body[4].title': '⟦Ŵĥàţ ǫûîţ ɱéðîçîñéš çàñ ðö~~~~~~~~~⟧',
  'bf_home_explore.body[4].text': '⟦Éðûçàţîöñ öñļý · 5 ɱîñ~~~~~~~⟧',
  'bf_home_explore.body[5].title': '⟦Ŕéàðý ŵĥéñ ýöû àŕé~~~~~~⟧',
  'bf_home_explore.body[5].text': '⟦Šéţţîñĝ à ðàţé ţàķéš 2 ɱîñûţéš.~~~~~~~~~~⟧',
  'bf_home_explore.body[5].cta[0].label': '⟦Çĥööšé à þàţĥ~~~~~⟧',
  'bf_slip.body[0].text': '⟦Ýöûŕ þŕöĝŕéšš îš šţîļļ ĥéŕé~~~~~~~~~~⟧',
  'bf_slip.body[1].text': '⟦À šļîþ îš îñƒöŕɱàţîöñ, ñöţ ţĥé éñð.~~~~~~~~~~~⟧',
  'bf_slip.body[2].rows[0][0]': '⟦Šɱöķé-ƒŕéé ðàýš šö ƒàŕ~~~~~~~~⟧',
  'bf_slip.body[2].rows[0][1]': '⟦6 öƒ 7 · ķéþţ~~~⟧',
  'bf_slip.body[3].options[0]': '⟦À þûƒƒ öŕ ţŵö~~~~⟧',
  'bf_slip.body[3].options[1]': '⟦Öñé çîĝàŕéţţé~~~~~⟧',
  'bf_slip.body[3].options[2]': '⟦Ṁöŕé~~⟧',
  'bf_slip.body[3].options[3]': '⟦Þŕéƒéŕ ñöţ ţö šàý~~~~~~⟧',
  'bf_slip.body[3].label': '⟦Ŵĥàţ ĥàþþéñéð?~~~~~⟧',
  'bf_slip.body[4].options[0]': '⟦Šţŕéšš~~~⟧',
  'bf_slip.body[4].options[1]': '⟦Àŕöûñð šɱöķéŕš~~~~~~⟧',
  'bf_slip.body[4].options[2]': '⟦Àļçöĥöļ~~~⟧',
  'bf_slip.body[4].options[3]': '⟦Šçŕöļļîñĝ ļàţé~~~~~~⟧',
  'bf_slip.body[4].label': '⟦Ŵĥàţ ŵàš ĝöîñĝ öñ? (öþţîöñàļ)~~~~~~~~~⟧',
  'bf_slip.body[5].items[0].label': '⟦Çöñţîñûé ƒŕöɱ ţĥîš ɱöɱéñţ~~~~~~~~~⟧',
  'bf_slip.body[5].items[0].sub': '⟦Ķééþ ýöûŕ þļàñ~~~~~⟧',
  'bf_slip.body[5].items[0].badge': '⟦Ŕéçöɱɱéñðéð~~~~~⟧',
  'bf_slip.body[5].items[1].label': '⟦Çĥööšé à ñéŵ ǫûîţ ţîɱé~~~~~~~~⟧',
  'bf_slip.footer[0].label': '⟦Šàṽé àñð šţàŕţ à 2-ɱîñ Ŕéšçûé~~~~~~~~~⟧',
  'bf_slip.footer[1].label': '⟦Šķîþ ƒöŕ ñöŵ~~~~⟧',
  'bf_slip.header.title': '⟦Šļîþ ŕéçöṽéŕý~~~~~⟧',
  'bf_slip.header.pill': '⟦Þŕîṽàţé~~~⟧',
  'bf_meds.body[0].text': '⟦Éðûçàţîöñ àñð ţŕàçķîñĝ, ñöţ þŕéšçŕîƀîñĝ. Ţĥé àþþ ñéṽéŕ šéļéçţš à ɱéðîçîñé öŕ çĥàñĝéš à ðöšé.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'bf_meds.body[1].eyebrow': '⟦Ýöûŕ ŕéçöŕðéð þļàñ~~~~~~~⟧',
  'bf_meds.body[1].title': '⟦Ñîçöţîñé þàţçĥ · ɱöŕñîñĝ~~~~~~~~⟧',
  'bf_meds.body[1].text': '⟦Éñţéŕéð ƀý ýöû · ƒöļļöŵ ýöûŕ çļîñîçîàñ’š îñšţŕûçţîöñš~~~~~~~~~~~~~~~~~~⟧',
  'bf_meds.body[1].children[0].items[0].action.value': '⟦Ŕéçöŕðéð: ţàķéñ àţ 8:07 ÀṀ~~~~~~~⟧',
  'bf_meds.body[1].children[0].items[0].label': '⟦Ţàķéñ ţöðàý~~~~⟧',
  'bf_meds.body[1].children[0].items[1].action.value': '⟦Ŕéçöŕðéð: ñöţ ţàķéñ~~~~~~~⟧',
  'bf_meds.body[1].children[0].items[1].label': '⟦Ñöţ ţöðàý~~~~⟧',
  'bf_meds.body[2].rows[0].label': '⟦Ñîçöţîñé ŕéþļàçéɱéñţ~~~~~~~~⟧',
  'bf_meds.body[2].rows[0].sub': '⟦Þàţçĥ, ĝûɱ, ļöžéñĝé~~~~~~⟧',
  'bf_meds.body[2].rows[1].label': '⟦Þŕéšçŕîþţîöñ öþţîöñš~~~~~~~~⟧',
  'bf_meds.body[2].rows[1].sub': '⟦Ṽàŕéñîçļîñé · ƀûþŕöþîöñ ŠŔ~~~~~~~~~⟧',
  'bf_meds.body[2].title': '⟦Ļéàŕñ~~⟧',
  'bf_meds.body[3].title': '⟦Þŕéĝñàñţ, ƀŕéàšţƒééðîñĝ öŕ ûñðéŕ 18?~~~~~~~~~~~~⟧',
  'bf_meds.body[3].text': '⟦Ţàļķ ŵîţĥ à ðöçţöŕ ƀéƒöŕé ûšîñĝ ǫûîţ ɱéðîçîñéš.~~~~~~~~~~~~~~~~⟧',
  'bf_meds.body[4].title': '⟦Šîðé éƒƒéçţ öŕ ŵöŕŕýîñĝ šýɱþţöɱ?~~~~~~~~~~~⟧',
  'bf_meds.body[4].text': '⟦Çöñţàçţ ýöûŕ çàŕé ţéàɱ öŕ þĥàŕɱàçîšţ. Éɱéŕĝéñçý: 911.~~~~~~~~~~~~~~~~⟧',
  'bf_meds.footer[0].label': '⟦Àðð öŕ ûþðàţé ŕéçöŕðéð þļàñ~~~~~~~~~~⟧',
  'bf_meds.header.title': '⟦Ṁéðîçàţîöñ çéñţéŕ~~~~~~~⟧',
  'bf_meds_edit.body[0].text': '⟦Ŕéçöŕð ţĥé þļàñ ƒŕöɱ ýöûŕ çļîñîçîàñ~~~~~~~~~~~~⟧',
  'bf_meds_edit.body[1].label': '⟦Ṁéðîçîñé~~~~⟧',
  'bf_meds_edit.body[1].placeholder': '⟦Ñîçöţîñé þàţçĥ~~~~~~⟧',
  'bf_meds_edit.body[2].label': '⟦Šţŕéñĝţĥ~~~~⟧',
  'bf_meds_edit.body[2].placeholder': '⟦21 ɱĝ / 24 ĥ~~⟧',
  'bf_meds_edit.body[3].label': '⟦Ŵĥéñ~~⟧',
  'bf_meds_edit.body[3].placeholder': '⟦Éṽéŕý ɱöŕñîñĝ~~~~~⟧',
  'bf_meds_edit.body[4].label': '⟦Þŕîṽàţé ŕéɱîñðéŕ~~~~~~⟧',
  'bf_meds_edit.body[4].sub': '⟦Ļöçķ šçŕééñ ĥîðéš ţĥé ɱéðîçîñé ñàɱé~~~~~~~~~~~~⟧',
  'bf_meds_edit.body[5].text': '⟦Ýöû’ŕé ŕéçöŕðîñĝ, ñöţ çĥàñĝîñĝ, ýöûŕ þļàñ. Àšķ ýöûŕ çļîñîçîàñ àƀöûţ àñý çĥàñĝé.~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'bf_meds_edit.footer[0].action.then.value': '⟦Þļàñ šàṽéð~~~~⟧',
  'bf_meds_edit.footer[0].label': '⟦Šàṽé þļàñ~~~~⟧',
  'bf_meds_edit.header.title': '⟦Ŕéçöŕðéð þļàñ~~~~~⟧',
  'bf_progress.body[0].options[0]': '⟦7 ðàýš~~⟧',
  'bf_progress.body[0].options[1]': '⟦30 ðàýš~~⟧',
  'bf_progress.body[0].options[2]': '⟦Àļļ~~⟧',
  'bf_progress.body[1].title': '⟦Çîĝàŕéţţéš / ðàý~~~~~~⟧',
  'bf_progress.body[1].caption': '⟦Ţĥûŕšðàý: ñö çĥéçķ-îñ · ñöţ çöûñţéð àš žéŕö~~~~~~~~~~~~~~⟧',
  'bf_progress.body[1].labels[0]': '⟦Ṁ~⟧',
  'bf_progress.body[1].labels[1]': '⟦Ţ~⟧',
  'bf_progress.body[1].labels[2]': '⟦Ŵ~⟧',
  'bf_progress.body[1].labels[3]': '⟦Ţ~⟧',
  'bf_progress.body[1].labels[4]': '⟦Ƒ~⟧',
  'bf_progress.body[1].labels[5]': '⟦Š~⟧',
  'bf_progress.body[1].labels[6]': '⟦Š~⟧',
  'bf_progress.body[2].items[0].label': '⟦Éšţ. àṽöîðéð~~~~⟧',
  'bf_progress.body[2].items[0].sub': '⟦çîĝàŕéţţéš~~~~⟧',
  'bf_progress.body[2].items[1].label': '⟦Éšţ. šàṽéð~~~~⟧',
  'bf_progress.body[2].items[1].sub': '⟦\$14 þéŕ þàçķ~~~⟧',
  'bf_progress.body[2].items[2].label': '⟦Çŕàṽîñĝš éàšéð~~~~~~⟧',
  'bf_progress.body[2].items[2].value': '⟦4 öƒ 6~⟧',
  'bf_progress.body[2].items[2].sub': '⟦àƒţéŕ à ţööļ~~~~⟧',
  'bf_progress.body[2].items[3].label': '⟦Ṁöšţ ĥéļþƒûļ~~~~~⟧',
  'bf_progress.body[2].items[3].value': '⟦Ɓŕéàţĥîñĝ~~~~⟧',
  'bf_progress.body[2].items[3].sub': '⟦3 öƒ 4 ţîɱéš~~~⟧',
  'bf_progress.body[3].rows[0].label': '⟦Ĥöŵ éšţîɱàţéš ŵöŕķ~~~~~~~⟧',
  'bf_progress.body[3].rows[0].sub': '⟦10/ðàý · \$14/þàçķ · 5 ɱîñ éàçĥ~~~~~~⟧',
  'bf_progress.header.title': '⟦Þŕöĝŕéšš~~~~⟧',
  'bf_estimates.body[0].text': '⟦Ĥöŵ éšţîɱàţéš àŕé çàļçûļàţéð~~~~~~~~~~⟧',
  'bf_estimates.body[1].rows[0][0]': '⟦Ɓàšéļîñé~~~~⟧',
  'bf_estimates.body[1].rows[0][1]': '⟦10 çîĝàŕéţţéš à ðàý~~~~~~⟧',
  'bf_estimates.body[1].rows[1][0]': '⟦Þŕîçé~~⟧',
  'bf_estimates.body[1].rows[1][1]': '⟦\$14.00 þéŕ þàçķ~~~⟧',
  'bf_estimates.body[1].rows[2][0]': '⟦Ţîɱé þéŕ çîĝàŕéţţé~~~~~~~⟧',
  'bf_estimates.body[1].rows[2][1]': '⟦5 ɱîñûţéš~~~⟧',
  'bf_estimates.body[1].rows[3][0]': '⟦Àṽöîðéð~~~⟧',
  'bf_estimates.body[1].rows[3][1]': '⟦ƀàšéļîñé − ŕéþöŕţéð~~~~~~~⟧',
  'bf_estimates.body[2].text': '⟦Éšţîɱàţéš, ñöţ ɱéàšûŕéɱéñţš. Ṁîššîñĝ ðàýš àŕé ļéƒţ öûţ.~~~~~~~~~~~~~~~~~~⟧',
  'bf_estimates.footer[0].action.value': '⟦Öþéñéð ƀàšéļîñé šéţţîñĝš~~~~~~~~~⟧',
  'bf_estimates.footer[0].label': '⟦Éðîţ ñûɱƀéŕš~~~~~⟧',
  'bf_estimates.footer[1].label': '⟦Ðöñé~~⟧',
  'sf_intro.body[0].extra': '⟦Šöçîàļ ɱéðîà ûšé~~~~~~⟧',
  'sf_intro.body[1].text': '⟦Ýöûŕ àţţéñţîöñ îš ýöûŕš.~~~~~~~~⟧',
  'sf_intro.body[2].rows[0][0]': '⟦Ĝöàļ~~⟧',
  'sf_intro.body[2].rows[0][1]': '⟦ɱîñûţéš à ðàý + àþþ-ƒŕéé ţîɱéš~~~~~~~~~~⟧',
  'sf_intro.body[2].rows[1][0]': '⟦Þàûšé 60~~⟧',
  'sf_intro.body[2].rows[1][1]': '⟦îñţéñţ çĥéçķ, ñöţ à ļöçķ~~~~~~~~⟧',
  'sf_intro.body[2].rows[2][0]': '⟦Ñéṽéŕ~~⟧',
  'sf_intro.body[2].rows[2][1]': '⟦ŕéàðš ɱéššàĝéš öŕ ƒééðš~~~~~~~~⟧',
  'sf_intro.body[3].text': '⟦Ñöţîçé ŵĥàţ þûļļš ýöû îñ, šéţ à ĝöàļ ţĥàţ ƒééļš ðöàƀļé, àñð þàûšé ƒöŕ 60 šéçöñðš ŵĥéñ ţĥé ûŕĝé ĥîţš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_intro.footer[0].label': '⟦Šéţ ûþ ŠçŕöļļƑŕéé~~~~~~⟧',
  'sf_intro.footer[1].action.then.value': '⟦ŠçŕöļļƑŕéé àððéð àš Ļéàŕñ öñļý~~~~~~~~~~~⟧',
  'sf_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'sf_intro.header.pill': '⟦~1 ɱîñ/ðàý~~~⟧',
  'sf_q1.body[1].text': '⟦Öñ à ţýþîçàļ ðàý, ĥöŵ ļöñĝ öñ šöçîàļ àþþš?~~~~~~~~~~~~~⟧',
  'sf_q1.body[2].text': '⟦À ŕöûĝĥ ĝûéšš îš ƒîñé.~~~~~~~⟧',
  'sf_q1.body[3].items[0].label': '⟦Ļéšš ţĥàñ 1 ĥöûŕ~~~~~⟧',
  'sf_q1.body[3].items[1].label': '⟦1–2 ĥöûŕš~~⟧',
  'sf_q1.body[3].items[2].label': '⟦3–4 ĥöûŕš~~⟧',
  'sf_q1.body[3].items[3].label': '⟦5+ ĥöûŕš~~⟧',
  'sf_q1.body[4].options[0]': '⟦Šĥöŕţ ṽîðéö~~~~⟧',
  'sf_q1.body[4].options[1]': '⟦Ƒééðš~~⟧',
  'sf_q1.body[4].options[2]': '⟦Ṁéššàĝîñĝ~~~~⟧',
  'sf_q1.body[4].options[3]': '⟦Ĝàɱéš~~⟧',
  'sf_q1.body[4].options[4]': '⟦Ñéŵš~~⟧',
  'sf_q1.body[4].label': '⟦Ŵĥîçĥ þûļļ ĥàŕðéšţ? (çàţéĝöŕîéš öñļý)~~~~~~~~~~~~⟧',
  'sf_q1.footer[0].label': '⟦Ñéẋţ~~⟧',
  'sf_q1.header.title': '⟦Àƀöûţ ýöûŕ ûšé~~~~~⟧',
  'sf_q1.header.pill': '⟦1 öƒ 2~⟧',
  'sf_q2.body[1].text': '⟦Ŵĥéñ ðö ýöû ŕéàçĥ ƒöŕ îţ?~~~~~~~~⟧',
  'sf_q2.body[2].options[0]': '⟦Ɓöŕéð~~⟧',
  'sf_q2.body[2].options[1]': '⟦Ļöñéļý~~~⟧',
  'sf_q2.body[2].options[2]': '⟦Îñ ƀéð~~⟧',
  'sf_q2.body[2].options[3]': '⟦Àṽöîðîñĝ ŵöŕķ~~~~~⟧',
  'sf_q2.body[2].options[4]': '⟦Àƒţéŕ çöñƒļîçţ~~~~~~⟧',
  'sf_q2.body[2].options[5]': '⟦Ŵàîţîñĝ~~~⟧',
  'sf_q2.body[2].options[6]': '⟦Çàñ’ţ šļééþ~~~~⟧',
  'sf_q2.body[2].options[7]': '⟦Ƒîŕšţ ţĥîñĝ~~~~⟧',
  'sf_q2.body[3].options[0]': '⟦Ɓéţţéŕ~~~⟧',
  'sf_q2.body[3].options[1]': '⟦Šàɱé~~⟧',
  'sf_q2.body[3].options[2]': '⟦Ŵöŕšé~~⟧',
  'sf_q2.body[3].label': '⟦Ĥöŵ ðö ýöû ûšûàļļý ƒééļ àƒţéŕ?~~~~~~~~~~⟧',
  'sf_q2.body[4].text': '⟦Ûšéð ƒöŕ ýöûŕ þļàñ öñļý. ŠçŕöļļƑŕéé ñéṽéŕ ŕéàðš ŵĥàţ ýöû ļööķ àţ.~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_q2.footer[0].label': '⟦Ñéẋţ~~⟧',
  'sf_q2.header.title': '⟦Ýöûŕ ţŕîĝĝéŕš~~~~~⟧',
  'sf_q2.header.pill': '⟦2 öƒ 2~⟧',
  'sf_goal.body[0].text': '⟦Šéţ à ĝöàļ ţĥàţ ƒééļš ðöàƀļé.~~~~~~~~~~⟧',
  'sf_goal.body[1].text': '⟦Ƒŕöɱ àƀöûţ 3 ĥöûŕš à ðàý.~~~~~~~~⟧',
  'sf_goal.body[2].children[0].label': '⟦Ðàîļý šöçîàļ ţîɱé~~~~~~⟧',
  'sf_goal.body[2].children[0].minLabel': '⟦30 ɱîñ~~⟧',
  'sf_goal.body[2].children[0].maxLabel': '⟦4 ĥ~⟧',
  'sf_goal.body[2].children[1].label': '⟦Šţéþ ðöŵñ 15 ɱîñ éàçĥ ŵééķ~~~~~~~~⟧',
  'sf_goal.body[3].eyebrow': '⟦Àþþ-ƒŕéé ţîɱéš~~~~~⟧',
  'sf_goal.body[3].children[0].items[0].label': '⟦Ɓéðţîɱé~~~⟧',
  'sf_goal.body[3].children[0].items[0].sub': '⟦10:00 ÞṀ – 7:00 ÀṀ~~⟧',
  'sf_goal.body[3].children[0].items[1].label': '⟦Ṁéàļš~~⟧',
  'sf_goal.body[3].children[0].items[1].sub': '⟦Ŵĥéñ ýöû ɱàŕķ à ɱéàļ~~~~~~~⟧',
  'sf_goal.body[3].children[0].items[2].label': '⟦Ƒîŕšţ ĥöûŕ àŵàķé~~~~~~⟧',
  'sf_goal.body[4].rows[0].label': '⟦Çöññéçţ Šçŕééñ Ţîɱé~~~~~~~⟧',
  'sf_goal.body[4].rows[0].sub': '⟦Öþţîöñàļ · ţöţàļš öñļý~~~~~~~~⟧',
  'sf_goal.footer[0].label': '⟦Šàṽé ɱý ĝöàļ~~~~⟧',
  'sf_goal.header.title': '⟦Ýöûŕ ĝöàļ~~~~⟧',
  'sf_goal.header.pill': '⟦Þļàñ~~⟧',
  'sf_screentime.body[1].text': '⟦Šéé ýöûŕ Šçŕééñ Ţîɱé ĥéŕé, îƒ ýöû ŵàñţ.~~~~~~~~~~~~⟧',
  'sf_screentime.body[2].text': '⟦Àþþļé’š Šçŕééñ Ţîɱé šĥöŵš ýöûŕ ðàîļý ţöţàļš ƀý çàţéĝöŕý îñšîðé Ţéţĥéŕ. Ţéţĥéŕ çàñ’ţ ŕéàð, šţöŕé öŕ šĥàŕé ţĥöšé ɱîñûţéš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_screentime.body[3].rows[0][0]': '⟦Šĥöŵš~~⟧',
  'sf_screentime.body[3].rows[0][1]': '⟦Ṁîñûţéš þéŕ çàţéĝöŕý, öñ ţĥîš þĥöñé~~~~~~~~~~~~⟧',
  'sf_screentime.body[3].rows[1][0]': '⟦Ñéṽéŕ ŕéàðš~~~~⟧',
  'sf_screentime.body[3].rows[1][1]': '⟦Çöñţéñţ, ɱéššàĝéš, çöñţàçţš~~~~~~~~~~⟧',
  'sf_screentime.body[3].rows[2][0]': '⟦Ţûŕñ öƒƒ~~~⟧',
  'sf_screentime.body[3].rows[2][1]': '⟦Àñýţîɱé îñ Àççöûñţ~~~~~~~⟧',
  'sf_screentime.footer[0].action.cases[0].action.value': '⟦Šçŕééñ Ţîɱé çöññéçţéð~~~~~~~~⟧',
  'sf_screentime.footer[0].label': '⟦Àļļöŵ àççéšš~~~~~⟧',
  'sf_screentime.footer[1].label': '⟦Ñöţ ñöŵ~~~⟧',
  'sf_screentime.header.title': '⟦Šçŕééñ Ţîɱé~~~~⟧',
  'sf_screentime.header.pill': '⟦Öþţîöñàļ~~~~⟧',
  'sf_screentime_denied.body[0].text': '⟦Šçŕééñ Ţîɱé àççéšš ŵàš ñöţ àļļöŵéð.~~~~~~~~~~~~⟧',
  'sf_screentime_denied.body[1].text': '⟦Šéļƒ-ŕéþöŕţ ŵöŕķš ĵûšţ àš ŵéļļ.~~~~~~~~~~⟧',
  'sf_screentime_denied.body[2].text': '⟦Ŵé’ļļ àšķ ƒöŕ à ǫûîçķ éšţîɱàţé îñ ýöûŕ éṽéñîñĝ çĥéçķ-îñ. Ýöû çàñ çöññéçţ ļàţéŕ îñ Àççöûñţ → ŠçŕöļļƑŕéé.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_screentime_denied.footer[0].label': '⟦Çöñţîñûé ŵîţĥ šéļƒ-ŕéþöŕţ~~~~~~~~~⟧',
  'sf_screentime_denied.footer[1].label': '⟦Öþéñ þĥöñé šéţţîñĝš~~~~~~~⟧',
  'sf_screentime_denied.header.title': '⟦Šçŕééñ Ţîɱé~~~~⟧',
  'sf_screentime_denied.header.pill': '⟦Öþţîöñàļ~~~~⟧',
  'sf_buddy.body[0].text': '⟦Ŵàñţ šöɱéöñé îñ ýöûŕ çöŕñéŕ?~~~~~~~~~~⟧',
  'sf_buddy.body[1].text': '⟦Ýöûŕ ƀûððý öñļý šééš ŵĥàţ ýöû çĥööšé ţö šéñð.~~~~~~~~~~~~~~~⟧',
  'sf_buddy.body[2].label': '⟦Ñàɱé~~⟧',
  'sf_buddy.body[2].placeholder': '⟦Šàɱ~~⟧',
  'sf_buddy.body[3].items[0].label': '⟦À ŵééķļý “Î ĥîţ ɱý ĝöàļ” ɱéššàĝé~~~~~~~~~~⟧',
  'sf_buddy.body[3].items[1].label': '⟦Ṁý ɱîñûţéš þéŕ ðàý~~~~~~⟧',
  'sf_buddy.body[3].items[2].label': '⟦Ñöţĥîñĝ àûţöɱàţîç: Î šéñð éàçĥ öñé~~~~~~~~~~~~⟧',
  'sf_buddy.body[3].label': '⟦Ţĥéý çàñ šéé~~~~⟧',
  'sf_buddy.body[4].eyebrow': '⟦Þŕéṽîéŵ~~~⟧',
  'sf_buddy.body[4].children[0].text': '⟦Þĥöñé-ƒŕéé ñîĝĥţš ţĥîš ŵééķ: 5. Ţĥàñķš ƒöŕ çĥééŕîñĝ ɱé öñ!~~~~~~~~~~~~~~~~~~⟧',
  'sf_buddy.footer[0].label': '⟦Šàṽé àñð ƒîñîšĥ~~~~~~⟧',
  'sf_buddy.footer[1].label': '⟦Šķîþ ƒöŕ ñöŵ~~~~⟧',
  'sf_buddy.header.title': '⟦Ɓûððý~~⟧',
  'sf_buddy.header.pill': '⟦Öþţîöñàļ~~~~⟧',
  'sf_home.body[0].eyebrow': '⟦Ýéšţéŕðàý~~~~⟧',
  'sf_home.body[0].children[0].value': '⟦2ĥ 10ɱ~⟧',
  'sf_home.body[0].children[0].caption': '⟦Ĝöàļ 90 ɱîñ · ðöŵñ ƒŕöɱ 3ĥ~~~~~~~⟧',
  'sf_home.body[1].title': '⟦Ûŕĝé ţö šçŕöļļ?~~~~~⟧',
  'sf_home.body[1].text': '⟦Ţàķé 60 šéçöñðš ƒîŕšţ~~~~~~~⟧',
  'sf_home.body[1].cta[0].label': '⟦Þàûšé 60~~⟧',
  'sf_home.body[2].title': '⟦Ŵàñţ ƒîŕɱéŕ ļîɱîţš?~~~~~~~⟧',
  'sf_home.body[2].text': '⟦Ûñþļûĝ çàñ þàûšé àþþš ýöû çĥööšé, àƒţéŕ ļîɱîţš ýöû šéţ. Öþţîöñàļ.~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_home.body[2].cta[0].label': '⟦Šéţ ûþ~~⟧',
  'sf_home.body[3].eyebrow': '⟦Ţöðàý’š šţéþ~~~~⟧',
  'sf_home.body[3].children[0].items[0].label': '⟦Çĥàŕĝé ýöûŕ þĥöñé öûţšîðé ţĥé ƀéðŕööɱ~~~~~~~~~~~~~⟧',
  'sf_home.body[3].children[0].items[0].sub': '⟦Ţöñîĝĥţ · ƀéðţîɱé ŵîñðöŵ 10 ÞṀ~~~~~~~~~⟧',
  'sf_home.body[4].rows[0].label': '⟦Ţĥîš ŵééķ~~~~⟧',
  'sf_home.body[4].rows[0].sub': '⟦5 öƒ 7 þĥöñé-ƒŕéé ñîĝĥţš~~~~~~~⟧',
  'sf_home.body[4].rows[1].label': '⟦Ĥàð à ļöñĝ šçŕöļļ?~~~~~~⟧',
  'sf_home.body[4].rows[1].sub': '⟦Ŕéƒļéçţ, ñöţĥîñĝ ŕéšéţš~~~~~~~~⟧',
  'sf_home.body[4].rows[2].label': '⟦Ĝöàļ & ŵîñðöŵš~~~~~⟧',
  'sf_home.body[4].rows[2].sub': '⟦90 ɱîñ · ƀéðţîɱé~~~~⟧',
  'sf_home.body[4].rows[3].label': '⟦Ɓûððý~~⟧',
  'sf_home.body[4].rows[3].sub': '⟦Šàɱ · ŵééķļý ɱéššàĝé~~~~~~~⟧',
  'sf_home.body[4].rows[4].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'sf_home.body[4].rows[4].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'sf_pause.body[0].text': '⟦Ɓéƒöŕé ýöû öþéñ îţ, öñé ƀŕéàţĥ.~~~~~~~~~~⟧',
  'sf_pause.body[1].text': '⟦Ŵĥàţ ðîð ýöû þîçķ ûþ ýöûŕ þĥöñé ƒöŕ?~~~~~~~~~~~~⟧',
  'sf_pause.body[3].options[0]': '⟦Ṁéššàĝé šöɱéöñé~~~~~~⟧',
  'sf_pause.body[3].options[1]': '⟦Ɓöŕéð~~⟧',
  'sf_pause.body[3].options[2]': '⟦Àṽöîðîñĝ šöɱéţĥîñĝ~~~~~~~⟧',
  'sf_pause.body[3].options[3]': '⟦Çàñ’ţ šļééþ~~~~⟧',
  'sf_pause.body[4].title': '⟦Ɓöŕéð? Ţŕý îñšţéàð:~~~~~~⟧',
  'sf_pause.body[4].text': '⟦2-ɱîñ ŵàļķ · ţéẋţ öñé ŕéàļ þéŕšöñ · à šĥöŕţ ļéššöñ~~~~~~~~~~~~~~~⟧',
  'sf_pause.footer[0].action.then.value': '⟦Ñîçé. Ļöĝĝéð àš à þàûšé.~~~~~~~~⟧',
  'sf_pause.footer[0].label': '⟦Î’ɱ ĝööð, þûţ îţ ðöŵñ~~~~~~⟧',
  'sf_pause.footer[1].label': '⟦Öþéñ àñýŵàý (ļöĝĝéð àš îñƒöŕɱàţîöñ)~~~~~~~~~~~~⟧',
  'sf_pause.footer[1].action.value': '⟦Ļöĝĝéð. Ñö ĵûðĝɱéñţ.~~~~~~~⟧',
  'sf_pause.header.title': '⟦Þàûšé 60~~⟧',
  'sf_pause.header.pill': '⟦Ûŕĝé ŕéšçûé~~~~⟧',
  'sf_slip.body[0].text': '⟦Ţĥàţ ĥàþþéñš. Ŵĥàţ þûļļéð ýöû îñ?~~~~~~~~~~~⟧',
  'sf_slip.body[1].text': '⟦Ñöţĥîñĝ ŕéšéţš. Ýöûŕ þĥöñé-ƒŕéé ñîĝĥţš šţîļļ çöûñţ.~~~~~~~~~~~~~~~~~⟧',
  'sf_slip.body[2].options[0]': '⟦Çöûļðñ’ţ šļééþ~~~~~⟧',
  'sf_slip.body[2].options[1]': '⟦Ɓöŕéð~~⟧',
  'sf_slip.body[2].options[2]': '⟦Šţŕéššéð~~~~⟧',
  'sf_slip.body[2].options[3]': '⟦Ðîðñ’ţ ñöţîçé ţîɱé~~~~~~⟧',
  'sf_slip.body[3].items[0].label': '⟦Ķééþ ɱý ĝöàļ, ţŕý àĝàîñ ţöñîĝĥţ~~~~~~~~~~⟧',
  'sf_slip.body[3].items[0].badge': '⟦Ŕéçöɱɱéñðéð~~~~~⟧',
  'sf_slip.body[3].items[1].label': '⟦Ṁàķé ţöɱöŕŕöŵ’š ĝöàļ éàšîéŕ~~~~~~~~~~⟧',
  'sf_slip.body[3].items[2].label': '⟦Ṁöṽé ƀéðţîɱé ŵîñðöŵ 30 ɱîñ éàŕļîéŕ~~~~~~~~~~~⟧',
  'sf_slip.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'sf_slip.footer[0].label': '⟦Šàṽé~~⟧',
  'sf_slip.header.title': '⟦Ļöñĝ šçŕöļļ~~~~⟧',
  'sf_slip.header.pill': '⟦Þŕîṽàţé~~~⟧',
  'sf_week.body[0].text': '⟦Ýöûŕ ŵééķ, ĥöñéšţļý.~~~~~~~⟧',
  'sf_week.body[1].title': '⟦Šöçîàļ ɱîñûţéš / ðàý~~~~~~~⟧',
  'sf_week.body[1].caption': '⟦Ţĥûŕšðàý: ñö çĥéçķ-îñ · ñöţ çöûñţéð àš žéŕö~~~~~~~~~~~~~~⟧',
  'sf_week.body[1].labels[0]': '⟦Ṁ~⟧',
  'sf_week.body[1].labels[1]': '⟦Ţ~⟧',
  'sf_week.body[1].labels[2]': '⟦Ŵ~⟧',
  'sf_week.body[1].labels[3]': '⟦Ţ~⟧',
  'sf_week.body[1].labels[4]': '⟦Ƒ~⟧',
  'sf_week.body[1].labels[5]': '⟦Š~⟧',
  'sf_week.body[1].labels[6]': '⟦Š~⟧',
  'sf_week.body[2].items[0].label': '⟦Þĥöñé-ƒŕéé ñîĝĥţš~~~~~~⟧',
  'sf_week.body[2].items[1].label': '⟦Ûŕĝéš þàûšéð~~~~~⟧',
  'sf_week.body[2].items[1].sub': '⟦7 þûţ ðöŵñ~~~⟧',
  'sf_week.body[3].eyebrow': '⟦Ýöû šàîð~~~⟧',
  'sf_week.body[3].text': '⟦“Ðŕàîñéð” ŵàš 4× ļéšš çöɱɱöñ öñ þĥöñé-ƒŕéé ñîĝĥţš.~~~~~~~~~~~~~~~⟧',
  'sf_week.body[3].children[0].text': '⟦Î ƒééļ ðŕàîñéð àƒţéŕ ļöñĝ šçŕöļļš.~~~~~~~~~~~~⟧',
  'sf_week.body[4].eyebrow': '⟦Ñéẋţ ŵééķ~~~~⟧',
  'sf_week.body[4].title': '⟦Šţéþ ðöŵñ ţö 75 ɱîñ?~~~~~~⟧',
  'sf_week.body[4].children[0].items[0].action.value': '⟦Ĝöàļ šéţ ţö 75 ɱîñ~~~~~⟧',
  'sf_week.body[4].children[0].items[0].label': '⟦Ýéš~~⟧',
  'sf_week.body[4].children[0].items[1].label': '⟦Šţàý àţ 90~~~⟧',
  'sf_week.header.title': '⟦Ŵééķ 2~~⟧',
  'ca_intro.body[0].extra': '⟦Ŕéšþîŕàţöŕý ĥéàļţĥ~~~~~~~⟧',
  'ca_intro.body[1].text': '⟦Ƒöļļöŵ ýöûŕ àçţîöñ þļàñ, ðàý ƀý ðàý.~~~~~~~~~~~~⟧',
  'ca_intro.body[2].rows[0][0]': '⟦Žöñé çĥéçķ~~~~⟧',
  'ca_intro.body[2].rows[0][1]': '⟦ĝŕééñ · ýéļļöŵ · ŕéð~~~~~~⟧',
  'ca_intro.body[2].rows[1][0]': '⟦Ŕéð žöñé~~~⟧',
  'ca_intro.body[2].rows[1][1]': '⟦öñé ţàþ ţö 911~~~~⟧',
  'ca_intro.body[2].rows[2][0]': '⟦Žöñéš~~⟧',
  'ca_intro.body[2].rows[2][1]': '⟦ƒŕöɱ ýöûŕ çļîñîçîàñ öñļý~~~~~~~~~⟧',
  'ca_intro.body[3].text': '⟦Çĥéçķ ýöûŕ žöñé, ļöĝ šýɱþţöɱš àñð ķñöŵ éẋàçţļý ŵĥàţ ţö ðö, ûšîñĝ ţĥé þļàñ ýöûŕ çļîñîçîàñ ĝàṽé ýöû.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ca_intro.footer[0].label': '⟦Šéţ ûþ ÇļéàŕÀîŕ~~~~~~⟧',
  'ca_intro.footer[1].action.then.value': '⟦ÇļéàŕÀîŕ àððéð àš Ļéàŕñ öñļý~~~~~~~~~~⟧',
  'ca_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'ca_intro.header.pill': '⟦~1 ɱîñ/ðàý~~~⟧',
  'ca_q1.body[1].text': '⟦Ŵĥîçĥ àþþļîéš ţö ýöû?~~~~~~~⟧',
  'ca_q1.body[2].text': '⟦Àš ţöļð ƀý à çļîñîçîàñ.~~~~~~~~⟧',
  'ca_q1.body[3].items[0].label': '⟦Àšţĥɱà~~~⟧',
  'ca_q1.body[3].items[1].label': '⟦ÇÖÞÐ~~⟧',
  'ca_q1.body[3].items[2].label': '⟦Öţĥéŕ ļûñĝ çöñðîţîöñ~~~~~~~~⟧',
  'ca_q1.body[3].items[3].label': '⟦Ñöţ ðîàĝñöšéð: Î ŵàñţ ţö ļéàŕñ~~~~~~~~~~⟧',
  'ca_q1.body[4].options[0]': '⟦Ýéš~~⟧',
  'ca_q1.body[4].options[1]': '⟦Ñö~⟧',
  'ca_q1.body[4].options[2]': '⟦Ñöţ šûŕé~~~⟧',
  'ca_q1.body[4].label': '⟦Ðö ýöû ĥàṽé à ŵŕîţţéñ àçţîöñ þļàñ?~~~~~~~~~~~⟧',
  'ca_q1.footer[0].label': '⟦Ñéẋţ~~⟧',
  'ca_q1.header.title': '⟦Àƀöûţ ýöûŕ ƀŕéàţĥîñĝ~~~~~~~~⟧',
  'ca_q1.header.pill': '⟦1 öƒ 2~⟧',
  'ca_plan.body[1].text': '⟦Çöþý ýöûŕ þļàñ ƒŕöɱ ýöûŕ çļîñîçîàñ.~~~~~~~~~~~~⟧',
  'ca_plan.body[2].text': '⟦ÇļéàŕÀîŕ ñéṽéŕ çŕéàţéš öŕ çĥàñĝéš žöñéš.~~~~~~~~~~~~~~⟧',
  'ca_plan.body[3].eyebrow': '⟦Ĝŕééñ žöñé~~~~⟧',
  'ca_plan.body[3].children[0].label': '⟦Þéàķ ƒļöŵ ƒŕöɱ~~~~~⟧',
  'ca_plan.body[3].children[1].label': '⟦Ðàîļý ɱéðîçîñé~~~~~~⟧',
  'ca_plan.body[3].children[1].placeholder': '⟦Çöñţŕöļļéŕ îñĥàļéŕ · 2 þûƒƒš ÀṀ/ÞṀ~~~~~~~~~~~⟧',
  'ca_plan.body[4].eyebrow': '⟦Ýéļļöŵ žöñé~~~~⟧',
  'ca_plan.body[4].children[0].label': '⟦Þéàķ ƒļöŵ~~~~⟧',
  'ca_plan.body[5].eyebrow': '⟦Ŕéð žöñé~~~⟧',
  'ca_plan.body[5].children[0].label': '⟦Ɓéļöŵ~~⟧',
  'ca_plan.body[6].action.value': '⟦Çàɱéŕà öþéñéð~~~~~⟧',
  'ca_plan.body[6].label': '⟦Àðð à þĥöţö öƒ ɱý þļàñ~~~~~~~⟧',
  'ca_plan.footer[0].label': '⟦Šàṽé þļàñ~~~~⟧',
  'ca_plan.header.title': '⟦Ýöûŕ àçţîöñ þļàñ~~~~~~⟧',
  'ca_plan.header.pill': '⟦2 öƒ 2~⟧',
  'ca_noplan.body[1].text': '⟦Ļéţ’š ĝéţ ýöû à þļàñ ƒîŕšţ~~~~~~~~⟧',
  'ca_noplan.body[2].text': '⟦Žöñé çĥéçķš ñééð à þļàñ ƒŕöɱ ýöûŕ çļîñîçîàñ. Ûñţîļ ţĥéñ ýöû çàñ ļéàŕñ, ļöĝ šýɱþţöɱš àñð þŕéþàŕé ǫûéšţîöñš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ca_noplan.body[3].rows[0].label': '⟦Šýɱþţöɱ ðîàŕý~~~~~⟧',
  'ca_noplan.body[3].rows[0].sub': '⟦Šĥàŕéàƀļé ŵîţĥ ýöûŕ çļîñîçîàñ~~~~~~~~~~~⟧',
  'ca_noplan.body[3].rows[1].label': '⟦Ǫûéšţîöñš ƒöŕ ɱý ñéẋţ ṽîšîţ~~~~~~~~~~⟧',
  'ca_noplan.body[3].rows[2].label': '⟦Ṁéššàĝé ɱý çàŕé ţéàɱ~~~~~~~⟧',
  'ca_noplan.footer[0].label': '⟦Çöñţîñûé ţö ÇļéàŕÀîŕ~~~~~~~~⟧',
  'ca_noplan.header.title': '⟦Ñö àçţîöñ þļàñ~~~~~⟧',
  'ca_noplan.header.pill': '⟦Ļéàŕñ~~⟧',
  'ca_home.body[0].eyebrow': '⟦Ţöðàý’š žöñé~~~~⟧',
  'ca_home.body[0].title': '⟦Ĝŕééñ · 410 Ļ/ɱîñ~~~~⟧',
  'ca_home.body[0].text': '⟦Çĥéçķéð 7:40 ÀṀ · ƒŕöɱ ýöûŕ þļàñ~~~~~~~~~⟧',
  'ca_home.body[1].label': '⟦Çĥéçķ ɱý žöñé~~~~~⟧',
  'ca_home.body[2].title': '⟦Ŕéð-žöñé þļàñ~~~~~⟧',
  'ca_home.body[2].text': '⟦Öþéñ îţ ƒàšţ~~~~⟧',
  'ca_home.body[3].rows[0].label': '⟦Ļöĝ šýɱþţöɱš~~~~~⟧',
  'ca_home.body[3].rows[1].label': '⟦Þŕöĝŕéšš~~~~⟧',
  'ca_home.body[3].rows[1].sub': '⟦10 ĝŕééñ · 2 ýéļļöŵ · 0 ŕéð~~~~~~⟧',
  'ca_home.body[3].rows[2].label': '⟦Ṁý àçţîöñ þļàñ~~~~~⟧',
  'ca_home.body[3].rows[2].sub': '⟦Éñţéŕéð Šéþ 3~~~~⟧',
  'ca_home.body[3].rows[3].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'ca_home.body[3].rows[3].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'ca_zone.body[0].text': '⟦Ĥöŵ îš ýöûŕ ƀŕéàţĥîñĝ?~~~~~~~~⟧',
  'ca_zone.body[1].label': '⟦Þéàķ ƒļöŵ (öþţîöñàļ)~~~~~~~⟧',
  'ca_zone.body[1].hint': '⟦50–900 Ļ/ɱîñ~~⟧',
  'ca_zone.body[2].options[0]': '⟦Çöûĝĥîñĝ~~~~⟧',
  'ca_zone.body[2].options[1]': '⟦Ŵĥééžîñĝ~~~~⟧',
  'ca_zone.body[2].options[2]': '⟦Šĥöŕţ öƒ ƀŕéàţĥ~~~~~~⟧',
  'ca_zone.body[2].options[3]': '⟦Çĥéšţ ţîĝĥţñéšš~~~~~~⟧',
  'ca_zone.body[2].options[4]': '⟦Ŵöķé àţ ñîĝĥţ~~~~~⟧',
  'ca_zone.body[2].options[5]': '⟦Çàñ’ţ šþéàķ îñ ƒûļļ šéñţéñçéš~~~~~~~~~~⟧',
  'ca_zone.body[2].label': '⟦Šýɱþţöɱš ñöŵ~~~~~⟧',
  'ca_zone.body[3].text': '⟦Ýöûŕ žöñé · ûþðàţéš àš ýöû ţýþé~~~~~~~~~~⟧',
  'ca_zone.body[5].text': '⟦Ŵöŕķéð öûţ öñļý ƒŕöɱ ţĥé þļàñ ýöû éñţéŕéð (ĝŕééñ ƒŕöɱ 400, ŕéð ƀéļöŵ 200).~~~~~~~~~~~~~~~~~~~~~⟧',
  'ca_zone.footer[0].action.then.cases[0].action.value': '⟦Ĝŕééñ žöñé · ƒöļļöŵ ýöûŕ ðàîļý ŕöûţîñé~~~~~~~~~~~~~⟧',
  'ca_zone.footer[0].action.then.cases[3].action.value': '⟦Çĥéçķ ýöûŕ þéàķ ƒļöŵ: 50–900 Ļ/ɱîñ~~~~~~~~~⟧',
  'ca_zone.footer[0].label': '⟦Šàṽé àñð šéé ɱý šţéþš~~~~~~~⟧',
  'ca_zone.header.title': '⟦Žöñé çĥéçķ~~~~⟧',
  'ca_zone.header.pill': '⟦Ţöðàý~~⟧',
  'ca_yellow.body[0].title': '⟦Ƒöļļöŵ ýöûŕ ýéļļöŵ-žöñé šţéþš~~~~~~~~~~⟧',
  'ca_yellow.body[0].text': '⟦Ƒŕöɱ ţĥé þļàñ ýöû éñţéŕéð öñ Šéþ 3~~~~~~~~~~~⟧',
  'ca_yellow.body[1].children[0].items[0].label': '⟦Ŕéļîéṽéŕ îñĥàļéŕ · 2–4 þûƒƒš~~~~~~~~⟧',
  'ca_yellow.body[1].children[0].items[0].sub': '⟦Àš ŵŕîţţéñ îñ ýöûŕ þļàñ~~~~~~~~⟧',
  'ca_yellow.body[1].children[0].items[1].label': '⟦Ŕé-çĥéçķ îñ 20 ɱîñûţéš~~~~~~~⟧',
  'ca_yellow.body[1].children[0].items[1].sub': '⟦Ŵé’ļļ ŕéɱîñð ýöû~~~~~~⟧',
  'ca_yellow.body[1].children[0].items[2].label': '⟦Ţéļļ ýöûŕ çàŕé ţéàɱ îƒ ñö ƀéţţéŕ~~~~~~~~~~~⟧',
  'ca_yellow.body[1].children[0].items[2].sub': '⟦Àš ýöûŕ þļàñ ðîŕéçţš~~~~~~~⟧',
  'ca_yellow.body[2].title': '⟦Ĝéţţîñĝ ŵöŕšé öŕ çàñ’ţ šþéàķ îñ ƒûļļ šéñţéñçéš?~~~~~~~~~~~~~~~~⟧',
  'ca_yellow.body[2].text': '⟦Ĝö ţö ýöûŕ ŕéð-žöñé þļàñ~~~~~~~~⟧',
  'ca_yellow.footer[0].action.value': '⟦Ŕéɱîñðéŕ šéţ ƒöŕ 20 ɱîñûţéš~~~~~~~~~⟧',
  'ca_yellow.footer[0].label': '⟦Ŕéɱîñð ɱé îñ 20 ɱîñ~~~~~~⟧',
  'ca_yellow.footer[1].label': '⟦Ṁéššàĝé çàŕé ţéàɱ~~~~~~⟧',
  'ca_yellow.header.title': '⟦Ýéļļöŵ žöñé~~~~⟧',
  'ca_yellow.header.pill': '⟦Ýöûŕ þļàñ~~~~⟧',
  'ca_red.body[0].text': '⟦Ƒöļļöŵ ýöûŕ ŕéð-žöñé þļàñ àñð šééķ ûŕĝéñţ çàŕé ñöŵ.~~~~~~~~~~~~~~~~~⟧',
  'ca_red.body[1].label': '⟦Çàļļ 911~~⟧',
  'ca_red.body[2].eyebrow': '⟦Ýöûŕ ŕéð-žöñé þļàñ~~~~~~⟧',
  'ca_red.body[2].children[0].items[0].label': '⟦Ŕéļîéṽéŕ îñĥàļéŕ ñöŵ, àš ŵŕîţţéñ~~~~~~~~~~~⟧',
  'ca_red.body[2].children[0].items[1].label': '⟦Çàļļ ýöûŕ çļîñîçîàñ öŕ 911~~~~~~~~⟧',
  'ca_red.body[2].children[0].items[2].label': '⟦Ðöñ’ţ ðŕîṽé ýöûŕšéļƒ~~~~~~~⟧',
  'ca_red.body[3].rows[0].label': '⟦Ţéļļ Ṁàŕîà~~~~⟧',
  'ca_red.body[3].rows[0].sub': '⟦Éɱéŕĝéñçý çöñţàçţ · þŕéṽîéŵ ƒîŕšţ~~~~~~~~~~~~⟧',
  'ca_red.body[4].text': '⟦Šţàýš öþéñ ûñţîļ ýöû çļöšé îţ.~~~~~~~~~~⟧',
  'ca_red.header.title': '⟦Ŕéð žöñé · àçţ ñöŵ~~~~~~⟧',
  'ca_symptoms.body[0].text': '⟦Ŵĥàţ àŕé ýöû ñöţîçîñĝ?~~~~~~~~⟧',
  'ca_symptoms.body[1].options[0]': '⟦Çöûĝĥîñĝ~~~~⟧',
  'ca_symptoms.body[1].options[1]': '⟦Ŵĥééžîñĝ~~~~⟧',
  'ca_symptoms.body[1].options[2]': '⟦Šĥöŕţ öƒ ƀŕéàţĥ~~~~~~⟧',
  'ca_symptoms.body[1].options[3]': '⟦Çĥéšţ ţîĝĥţñéšš~~~~~~⟧',
  'ca_symptoms.body[1].options[4]': '⟦Ŵöķé àţ ñîĝĥţ~~~~~⟧',
  'ca_symptoms.body[2].options[0]': '⟦Ṁîļð~~⟧',
  'ca_symptoms.body[2].options[1]': '⟦Ṁöðéŕàţé~~~~⟧',
  'ca_symptoms.body[2].options[2]': '⟦Šéṽéŕé~~~⟧',
  'ca_symptoms.body[2].label': '⟦Ĥöŵ ƀàð?~~~⟧',
  'ca_symptoms.body[3].options[0]': '⟦Çöļð àîŕ~~~⟧',
  'ca_symptoms.body[3].options[1]': '⟦Šɱöķé~~⟧',
  'ca_symptoms.body[3].options[2]': '⟦Þöļļéñ~~~⟧',
  'ca_symptoms.body[3].options[3]': '⟦Éẋéŕçîšé~~~~⟧',
  'ca_symptoms.body[3].options[4]': '⟦Ñöţ šûŕé~~~⟧',
  'ca_symptoms.body[3].label': '⟦Þöššîƀļé ţŕîĝĝéŕ~~~~~~⟧',
  'ca_symptoms.body[4].label': '⟦Ñöţé (öþţîöñàļ)~~~~~⟧',
  'ca_symptoms.body[4].placeholder': '⟦Àñýţĥîñĝ éļšé ţö ţéļļ ýöûŕ çļîñîçîàñ~~~~~~~~~~~~~⟧',
  'ca_symptoms.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'ca_symptoms.footer[0].label': '⟦Šàṽé~~⟧',
  'ca_symptoms.header.title': '⟦Ļöĝ šýɱþţöɱš~~~~~⟧',
  'ca_progress.body[0].title': '⟦Þéàķ ƒļöŵ · 12 ðàýš~~~~~⟧',
  'ca_progress.body[0].caption': '⟦Šĥàðéð: ýöûŕ ĝŕééñ žöñé, ƒŕöɱ ýöûŕ þļàñ~~~~~~~~~~~~~⟧',
  'ca_progress.body[1].items[0].label': '⟦Ĝŕééñ~~⟧',
  'ca_progress.body[1].items[1].label': '⟦Ýéļļöŵ~~~⟧',
  'ca_progress.body[1].items[2].label': '⟦Ŕéð~~⟧',
  'ca_progress.body[2].eyebrow': '⟦Ṁöšţ çöɱɱöñ šýɱþţöɱ~~~~~~~⟧',
  'ca_progress.body[2].title': '⟦Ŵĥééžîñĝ àţ ñîĝĥţ (3×)~~~~~~⟧',
  'ca_progress.body[2].text': '⟦Ŵöŕţĥ ɱéñţîöñîñĝ àţ ýöûŕ ñéẋţ ṽîšîţ.~~~~~~~~~~~~⟧',
  'ca_progress.footer[0].label': '⟦Çŕéàţé ṽîšîţ šûɱɱàŕý~~~~~~~~⟧',
  'ca_progress.header.title': '⟦Þŕöĝŕéšš~~~~⟧',
  'hw_intro.body[0].extra': '⟦Çàŕðîöṽàšçûļàŕ ĥéàļţĥ~~~~~~~~⟧',
  'hw_intro.body[1].text': '⟦Ķñöŵ ýöûŕ ñûɱƀéŕš. Šĥàŕé ţĥéɱ öñ ýöûŕ ţéŕɱš.~~~~~~~~~~~~~~⟧',
  'hw_intro.body[2].rows[0][0]': '⟦Ŕéàðîñĝš~~~~⟧',
  'hw_intro.body[2].rows[0][1]': '⟦ƁÞ + çĥöļéšţéŕöļ þàñéļš~~~~~~~~⟧',
  'hw_intro.body[2].rows[1][0]': '⟦Ţàŕĝéţš~~~⟧',
  'hw_intro.body[2].rows[1][1]': '⟦ƒŕöɱ ýöûŕ çļîñîçîàñ~~~~~~~⟧',
  'hw_intro.body[2].rows[2][0]': '⟦À ŕéàðîñĝ îš~~~~⟧',
  'hw_intro.body[2].rows[2][1]': '⟦îñƒöŕɱàţîöñ, ñöţ à ĝŕàðé~~~~~~~~⟧',
  'hw_intro.body[3].text': '⟦Ļöĝ ƀļööð þŕéššûŕé àñð çĥöļéšţéŕöļ, šéé ţŕéñðš àñð þŕéþàŕé ƒöŕ ṽîšîţš. Ɓöţĥ ƒöçûš šļöţš àŕé îñ ûšé, šö ýöû’ļļ çĥööšé ĥöŵ ţö àðð îţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'hw_intro.footer[0].label': '⟦Šéţ ûþ Ĥéàŕţŵîšé~~~~~~⟧',
  'hw_intro.footer[1].action.then.value': '⟦Ĥéàŕţŵîšé àððéð àš Ļéàŕñ öñļý~~~~~~~~~~⟧',
  'hw_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'hw_intro.header.pill': '⟦~2 ɱîñ/ðàý~~~⟧',
  'hw_q1.body[1].text': '⟦Ĥàš à çļîñîçîàñ ţàļķéð ŵîţĥ ýöû àƀöûţ…~~~~~~~~~~~~~⟧',
  'hw_q1.body[2].options[0]': '⟦Ĥîĝĥ ƀļööð þŕéššûŕé~~~~~~~⟧',
  'hw_q1.body[2].options[1]': '⟦Ĥîĝĥ çĥöļéšţéŕöļ~~~~~~⟧',
  'hw_q1.body[2].options[2]': '⟦Ĥéàŕţ ðîšéàšé~~~~~⟧',
  'hw_q1.body[2].options[3]': '⟦Šţŕöķé~~~⟧',
  'hw_q1.body[2].options[4]': '⟦Ñöñé öƒ ţĥéšé~~~~~⟧',
  'hw_q1.body[3].options[0]': '⟦Ýéš~~⟧',
  'hw_q1.body[3].options[1]': '⟦Ñö~⟧',
  'hw_q1.body[3].options[2]': '⟦Ñöţ šûŕé~~~⟧',
  'hw_q1.body[3].label': '⟦Ðö ýöû ĥàṽé à ĥöɱé ƁÞ ɱöñîţöŕ?~~~~~~~~~~⟧',
  'hw_q1.body[4].text': '⟦Ñö ɱöñîţöŕ? Ṁàñý þĥàŕɱàçîéš ĥàṽé ƒŕéé ķîöšķš. Ŵé’ļļ šĥöŵ ĥöŵ ţö ɱéàšûŕé çöŕŕéçţļý.~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'hw_q1.footer[0].label': '⟦Ñéẋţ~~⟧',
  'hw_q1.header.title': '⟦Àƀöûţ ýöû~~~~⟧',
  'hw_q1.header.pill': '⟦1 öƒ 2~⟧',
  'hw_targets.body[1].text': '⟦Ŵĥàţ ţàŕĝéţ ðîð ýöûŕ çļîñîçîàñ ĝîṽé ýöû?~~~~~~~~~~~~~~⟧',
  'hw_targets.body[2].fields[0].label': '⟦Ţöþ ƀéļöŵ~~~~⟧',
  'hw_targets.body[2].fields[1].label': '⟦Ɓöţţöɱ ƀéļöŵ~~~~~⟧',
  'hw_targets.body[3].items[0].label': '⟦Î ðöñ’ţ ĥàṽé à ţàŕĝéţ ýéţ~~~~~~~~⟧',
  'hw_targets.body[3].items[0].sub': '⟦Ŕéàðîñĝš šĥöŵ ŵîţĥöûţ à ţàŕĝéţ ļîñé~~~~~~~~~~~~⟧',
  'hw_targets.body[4].options[0]': '⟦Ṁöŕñîñĝ~~~⟧',
  'hw_targets.body[4].options[1]': '⟦Éṽéñîñĝ~~~⟧',
  'hw_targets.body[4].options[2]': '⟦Ɓöţĥ~~⟧',
  'hw_targets.body[4].label': '⟦Ŵĥéñ šĥöûļð ŵé ŕéɱîñð ýöû?~~~~~~~~~⟧',
  'hw_targets.body[5].text': '⟦Ĥéàŕţŵîšé ñéṽéŕ šéţš öŕ ĝŕàðéš ţàŕĝéţš.~~~~~~~~~~~~~~⟧',
  'hw_targets.body[6].label': '⟦Îɱþöŕţ ƒŕöɱ ɱý ĥéàļţĥ ŕéçöŕð~~~~~~~~~~⟧',
  'hw_targets.footer[0].label': '⟦Šàṽé ţàŕĝéţš~~~~~⟧',
  'hw_targets.header.title': '⟦Ýöûŕ ţàŕĝéţš~~~~~⟧',
  'hw_targets.header.pill': '⟦2 öƒ 2~⟧',
  'hw_home.body[0].eyebrow': '⟦Ļàšţ ŕéàðîñĝ · 7:52 ÀṀ~~~~~~⟧',
  'hw_home.body[0].children[0].caption': '⟦Àṽéŕàĝé öƒ 2 · ţàŕĝéţ ƀéļöŵ 130/80~~~~~~~~⟧',
  'hw_home.body[1].label': '⟦Ļöĝ ƀļööð þŕéššûŕé~~~~~~~⟧',
  'hw_home.body[2].rows[0].label': '⟦Ţŕéñðš~~~⟧',
  'hw_home.body[2].rows[0].sub': '⟦30-ðàý àṽéŕàĝé 132/82~~~~⟧',
  'hw_home.body[2].rows[1].label': '⟦Çĥöļéšţéŕöļ þàñéļ~~~~~~~⟧',
  'hw_home.body[2].rows[1].sub': '⟦ĻÐĻ 138 · Šéþ 30~~~⟧',
  'hw_home.body[2].rows[2].label': '⟦Ṽîšîţ šûɱɱàŕý~~~~~⟧',
  'hw_home.body[2].rows[2].sub': '⟦Þŕéṽîéŵ ƀéƒöŕé šĥàŕîñĝ~~~~~~~~⟧',
  'hw_home.body[2].rows[3].label': '⟦Ƒŕöɱ ýöûŕ ĥéàļţĥ ŕéçöŕð~~~~~~~~⟧',
  'hw_home.body[2].rows[3].sub': '⟦12 ŕéàðîñĝš · Þàţéļ Ƒàɱîļý Ṁéðîçîñé (Éþîç)~~~~~~~~~~~~~⟧',
  'hw_home.body[2].rows[4].label': '⟦Ṁý ţàŕĝéţš~~~~⟧',
  'hw_home.body[2].rows[4].sub': '⟦130/80 ƒŕöɱ Ðŕ. Þàţéļ~~~~~⟧',
  'hw_home.body[2].rows[5].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'hw_home.body[2].rows[5].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'hw_home.body[3].text': '⟦Çĥéšţ þàîñ, þŕéššûŕé öŕ ţŕöûƀļé ƀŕéàţĥîñĝ? Çàļļ 911 ñöŵ.~~~~~~~~~~~~~~~~~⟧',
  'hw_home.body[3].actions[0].label': '⟦Çàļļ 911~~⟧',
  'hw_log.body[0].text': '⟦Šîţ ǫûîéţļý ƒöŕ 5 ɱîñûţéš ƒîŕšţ.~~~~~~~~~~⟧',
  'hw_log.body[1].fields[0].label': '⟦Ţöþ (šýšţöļîç)~~~~~⟧',
  'hw_log.body[1].fields[1].label': '⟦Ɓöţţöɱ (ðîàšţöļîç)~~~~~~⟧',
  'hw_log.body[2].label': '⟦Þûļšé (öþţîöñàļ)~~~~~~⟧',
  'hw_log.body[3].options[0]': '⟦Ļéƒţ àŕɱ~~~⟧',
  'hw_log.body[3].options[1]': '⟦Ŕîĝĥţ àŕɱ~~~~⟧',
  'hw_log.body[4].title': '⟦Ţîþ~~⟧',
  'hw_log.body[4].text': '⟦Ţàķé à šéçöñð ŕéàðîñĝ àƒţéŕ 1 ɱîñûţé. Ŵé’ļļ àṽéŕàĝé ţĥéɱ.~~~~~~~~~~~~~~~~~~⟧',
  'hw_log.footer[0].label': '⟦Ñéẋţ ŕéàðîñĝ~~~~~⟧',
  'hw_log.header.title': '⟦Ļöĝ ƀļööð þŕéššûŕé~~~~~~~⟧',
  'hw_log.header.pill': '⟦1 öƒ 2~⟧',
  'hw_log2.body[0].text': '⟦Šéçöñð ŕéàðîñĝ~~~~~~⟧',
  'hw_log2.body[1].text': '⟦Šàɱé àŕɱ, 1 ɱîñûţé ļàţéŕ.~~~~~~~~⟧',
  'hw_log2.body[2].fields[0].label': '⟦Ţöþ (šýšţöļîç)~~~~~⟧',
  'hw_log2.body[2].fields[1].label': '⟦Ɓöţţöɱ (ðîàšţöļîç)~~~~~~⟧',
  'hw_log2.body[3].label': '⟦Þûļšé (öþţîöñàļ)~~~~~~⟧',
  'hw_log2.body[4].rows[0][0]': '⟦Ŕéàðîñĝ 1~~~⟧',
  'hw_log2.body[4].rows[1][0]': '⟦Àṽéŕàĝé šö ƒàŕ~~~~~⟧',
  'hw_log2.footer[0].label': '⟦Šàṽé ŕéàðîñĝš~~~~~⟧',
  'hw_log2.header.title': '⟦Ļöĝ ƀļööð þŕéššûŕé~~~~~~~⟧',
  'hw_log2.header.pill': '⟦2 öƒ 2~⟧',
  'hw_log_error.body[0].text': '⟦Ļéţ’š ðöûƀļé-çĥéçķ ţĥàţ.~~~~~~~~⟧',
  'hw_log_error.body[1].fields[0].label': '⟦Ţöþ (šýšţöļîç)~~~~~⟧',
  'hw_log_error.body[1].fields[1].label': '⟦Ɓöţţöɱ (ðîàšţöļîç)~~~~~~⟧',
  'hw_log_error.body[1].fields[1].error': '⟦Ţöö ĥîĝĥ ƒöŕ ţĥé ƀöţţöɱ ñûɱƀéŕ. Ðîð ýöû ɱéàñ 81?~~~~~~~~~~~~~~⟧',
  'hw_log_error.body[2].text': '⟦Ṽàļîð ŕàñĝé: ţöþ 70–250, ƀöţţöɱ 40–150, ƀöţţöɱ ļöŵéŕ ţĥàñ ţöþ.~~~~~~~~~~~~~~~⟧',
  'hw_log_error.footer[0].label': '⟦Šàṽé ŕéàðîñĝš~~~~~⟧',
  'hw_log_error.footer[1].label': '⟦Éðîţ ŕéàðîñĝ~~~~~⟧',
  'hw_log_error.header.title': '⟦Ļöĝ ƀļööð þŕéššûŕé~~~~~~~⟧',
  'hw_log_error.header.pill': '⟦Çĥéçķ~~⟧',
  'hw_result.body[1].text': '⟦135/85 šàṽéð~~⟧',
  'hw_result.body[2].text': '⟦Àṽéŕàĝé öƒ 2 ŕéàðîñĝš. Ýöûŕ çļîñîçîàñ’š ţàŕĝéţ îš ƀéļöŵ 130/80.~~~~~~~~~~~~~~~~~~⟧',
  'hw_result.body[3].text': '⟦Öñé ŕéàðîñĝ îš îñƒöŕɱàţîöñ, ñöţ à ĝŕàðé. Ţŕéñðš öṽéŕ ŵééķš ɱàţţéŕ ɱöšţ.~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'hw_result.footer[0].label': '⟦Šéé ţŕéñðš~~~~⟧',
  'hw_result.footer[1].label': '⟦Ɓàçķ ţö Ĥéàŕţŵîšé~~~~~~⟧',
  'hw_result.header.title': '⟦Šàṽéð~~⟧',
  'hw_crisis.body[0].text': '⟦186/122 îš îñ à ŕàñĝé ţĥàţ ñééðš àţţéñţîöñ ñöŵ.~~~~~~~~~~~~~⟧',
  'hw_crisis.body[1].title': '⟦Ðö ýöû ĥàṽé àñý öƒ ţĥéšé ŕîĝĥţ ñöŵ?~~~~~~~~~~~⟧',
  'hw_crisis.body[1].text': '⟦Çĥéšţ þàîñ · šĥöŕţñéšš öƒ ƀŕéàţĥ · ƀàçķ þàîñ · ñûɱƀñéšš öŕ ŵéàķñéšš · ṽîšîöñ çĥàñĝé · ţŕöûƀļé šþéàķîñĝ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'hw_crisis.body[2].label': '⟦Ýéš · çàļļ 911~~~⟧',
  'hw_crisis.body[3].label': '⟦Ñö šýɱþţöɱš · ŕé-çĥéçķ îñ 5 ɱîñ~~~~~~~~~⟧',
  'hw_crisis.body[4].text': '⟦Îƒ îţ’š šţîļļ ţĥîš ĥîĝĥ öñ ŕé-çĥéçķ, çöñţàçţ ýöûŕ çļîñîçîàñ ţöðàý. Ĥéàŕţŵîšé ðöéšñ’ţ ðîàĝñöšé.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'hw_crisis.header.title': '⟦Çĥéçķ ţĥîš ŕéàðîñĝ~~~~~~~⟧',
  'hw_recheck.body[0].text': '⟦Ŕéšţ, ţĥéñ ɱéàšûŕé àĝàîñ.~~~~~~~~⟧',
  'hw_recheck.body[1].label': '⟦ûñţîļ ŕé-çĥéçķ~~~~~⟧',
  'hw_recheck.body[2].children[0].items[0].label': '⟦Šîţ ŵîţĥ ýöûŕ ƀàçķ šûþþöŕţéð~~~~~~~~~~⟧',
  'hw_recheck.body[2].children[0].items[1].label': '⟦Ƒééţ ƒļàţ, àŕɱ àţ ĥéàŕţ ļéṽéļ~~~~~~~~~~⟧',
  'hw_recheck.body[2].children[0].items[2].label': '⟦Ñö ţàļķîñĝ ŵĥîļé ɱéàšûŕîñĝ~~~~~~~~~~⟧',
  'hw_recheck.body[3].text': '⟦Ñéŵ çĥéšţ þàîñ, ŵéàķñéšš öŕ ţŕöûƀļé šþéàķîñĝ? Çàļļ 911 ñöŵ.~~~~~~~~~~~~~~~~~~⟧',
  'hw_recheck.body[3].actions[0].label': '⟦Çàļļ 911~~⟧',
  'hw_recheck.footer[0].label': '⟦Ŕé-çĥéçķ ñöŵ~~~~⟧',
  'hw_recheck.footer[1].label': '⟦Çöñţàçţ ɱý çļîñîçîàñ~~~~~~~~⟧',
  'hw_recheck.header.title': '⟦Ŕé-çĥéçķ~~~⟧',
  'hw_trends.body[0].options[0]': '⟦7 ðàýš~~⟧',
  'hw_trends.body[0].options[1]': '⟦30 ðàýš~~⟧',
  'hw_trends.body[0].options[2]': '⟦90 ðàýš~~⟧',
  'hw_trends.body[1].title': '⟦Šýšţöļîç · ɱöŕñîñĝ àṽĝ~~~~~~~~⟧',
  'hw_trends.body[1].caption': '⟦Šĥàðéð: ýöûŕ çļîñîçîàñ’š ţàŕĝéţ~~~~~~~~~~~⟧',
  'hw_trends.body[2].items[0].label': '⟦30-ðàý àṽĝ~~~⟧',
  'hw_trends.body[2].items[1].label': '⟦Ŕéàðîñĝš~~~~⟧',
  'hw_trends.body[2].items[1].sub': '⟦4 ðàýš ɱîššéð~~~~⟧',
  'hw_trends.footer[0].label': '⟦Çŕéàţé ṽîšîţ šûɱɱàŕý~~~~~~~~⟧',
  'hw_trends.header.title': '⟦Ţŕéñðš~~~⟧',
  'hw_lipids.body[0].text': '⟦Àðð ýöûŕ ļàƀ ŕéšûļţš~~~~~~~⟧',
  'hw_lipids.body[1].text': '⟦Çöþý ƒŕöɱ ýöûŕ ļàƀ ŕéþöŕţ. Ûñîţš: ɱĝ/ðĻ.~~~~~~~~~~~~⟧',
  'hw_lipids.body[2].fields[0].label': '⟦Ţöţàļ~~⟧',
  'hw_lipids.body[2].fields[1].label': '⟦ĻÐĻ~~⟧',
  'hw_lipids.body[3].fields[0].label': '⟦ĤÐĻ~~⟧',
  'hw_lipids.body[3].fields[1].label': '⟦Ţŕîĝļýçéŕîðéš~~~~~~⟧',
  'hw_lipids.body[3].fields[1].placeholder': '⟦Öþţîöñàļ~~~~⟧',
  'hw_lipids.body[4].label': '⟦Ļàƀ ðàţé~~~⟧',
  'hw_lipids.body[4].placeholder': '⟦Šéþ 30, 2026~~⟧',
  'hw_lipids.footer[0].action.then.value': '⟦Þàñéļ šàṽéð~~~~⟧',
  'hw_lipids.footer[0].label': '⟦Šàṽé þàñéļ~~~~⟧',
  'hw_lipids.header.title': '⟦Çĥöļéšţéŕöļ þàñéļ~~~~~~~⟧',
  'hw_lipids.header.pill': '⟦Ļàƀ~~⟧',
  'hw_summary.body[0].text': '⟦Šĥàŕé ŵîţĥ Ðŕ. Þàţéļ’š çļîñîç?~~~~~~~~~~⟧',
  'hw_summary.body[1].rows[0][0]': '⟦Ðàţéš~~⟧',
  'hw_summary.body[1].rows[0][1]': '⟦Šéþ 17 – Öçţ 17~~~⟧',
  'hw_summary.body[1].rows[1][0]': '⟦ƁÞ àṽéŕàĝé~~~~⟧',
  'hw_summary.body[1].rows[1][1]': '⟦132/82 (48 ŕéàðîñĝš)~~~~⟧',
  'hw_summary.body[1].rows[2][0]': '⟦Ĥîĝĥéšţ~~~⟧',
  'hw_summary.body[1].rows[2][1]': '⟦186/122 · Öçţ 2 · ŕé-çĥéçķéð 144/90~~~~~⟧',
  'hw_summary.body[1].rows[3][0]': '⟦Ļàţéšţ þàñéļ~~~~~⟧',
  'hw_summary.body[1].rows[3][1]': '⟦ĻÐĻ 138 · Šéþ 30~~~⟧',
  'hw_summary.body[2].text': '⟦Öñļý Ĥéàŕţŵîšé ðàţà. Ñöţĥîñĝ ƒŕöɱ ýöûŕ öţĥéŕ þŕöĝŕàɱš.~~~~~~~~~~~~~~~~~~⟧',
  'hw_summary.body[3].label': '⟦Îñçļûðé ñöţéš~~~~~⟧',
  'hw_summary.footer[0].action.then.value': '⟦Šûɱɱàŕý šéñţ ţö Ðŕ. Þàţéļ’š çļîñîç~~~~~~~~~~~⟧',
  'hw_summary.footer[0].label': '⟦Šéñð šûɱɱàŕý~~~~~⟧',
  'hw_summary.footer[1].action.value': '⟦ÞÐƑ šàṽéð ţö Ƒîļéš~~~~~~⟧',
  'hw_summary.footer[1].label': '⟦Šàṽé àš ÞÐƑ~~~~⟧',
  'hw_summary.header.title': '⟦Ṽîšîţ šûɱɱàŕý~~~~~⟧',
  'hw_summary.header.pill': '⟦Þŕéṽîéŵ~~~⟧',
  'st_intro.body[0].extra': '⟦Ðîàƀéţéš & ɱéţàƀöļîç ĥéàļţĥ~~~~~~~~~~⟧',
  'st_intro.body[1].text': '⟦Ñöţîçé ĝļûçöšé þàţţéŕñš, ŵîţĥöûţ ĵûðĝɱéñţ.~~~~~~~~~~~~~~~⟧',
  'st_intro.body[2].rows[0][0]': '⟦Ŕéàðîñĝš~~~~⟧',
  'st_intro.body[2].rows[0][1]': '⟦ɱéţéŕ öŕ ÇĜṀ éñţŕîéš~~~~~~~⟧',
  'st_intro.body[2].rows[1][0]': '⟦Ŕàñĝé~~⟧',
  'st_intro.body[2].rows[1][1]': '⟦ƒŕöɱ ýöûŕ çļîñîçîàñ~~~~~~~⟧',
  'st_intro.body[2].rows[2][0]': '⟦À ĥîĝĥ ŕéàðîñĝ îš~~~~~~⟧',
  'st_intro.body[2].rows[2][1]': '⟦îñƒöŕɱàţîöñ, ñöţ ƒàîļûŕé~~~~~~~~~⟧',
  'st_intro.body[3].text': '⟦Ļöĝ ŕéàðîñĝš, šéé þàţţéŕñš àŕöûñð ɱéàļš àñð šļééþ, àñð ƒöļļöŵ ţĥé ļöŵ þļàñ ýöûŕ çļîñîçîàñ ĝàṽé ýöû. Šţéàðý ñéṽéŕ çöûñţš çàļöŕîéš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'st_intro.footer[0].label': '⟦Šéţ ûþ Šţéàðý~~~~~⟧',
  'st_intro.footer[1].action.then.value': '⟦Šţéàðý àððéð àš Ļéàŕñ öñļý~~~~~~~~~⟧',
  'st_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'st_intro.header.pill': '⟦~2 ɱîñ/ðàý~~~⟧',
  'st_q1.body[1].text': '⟦Ŵĥîçĥ ðéšçŕîƀéš ýöû?~~~~~~~⟧',
  'st_q1.body[2].text': '⟦Àš ţöļð ƀý à çļîñîçîàñ.~~~~~~~~⟧',
  'st_q1.body[3].items[0].label': '⟦Ţýþé 2 ðîàƀéţéš~~~~~⟧',
  'st_q1.body[3].items[1].label': '⟦Þŕéðîàƀéţéš~~~~~⟧',
  'st_q1.body[3].items[2].label': '⟦Ţýþé 1 ðîàƀéţéš~~~~~⟧',
  'st_q1.body[3].items[2].sub': '⟦Ļöĝĝîñĝ öñļý; ƒöļļöŵ ýöûŕ çàŕé ţéàɱ ƒöŕ îñšûļîñ~~~~~~~~~~~~~~~~⟧',
  'st_q1.body[3].items[3].label': '⟦Ĝéšţàţîöñàļ ðîàƀéţéš~~~~~~~~⟧',
  'st_q1.body[3].items[3].sub': '⟦Éðûçàţîöñ öñļý; ţàļķ ŵîţĥ ýöûŕ çàŕé ţéàɱ~~~~~~~~~~~~~~⟧',
  'st_q1.body[3].items[4].label': '⟦Ñöţ ðîàĝñöšéð: ļéàŕñ~~~~~~~⟧',
  'st_q1.body[4].options[0]': '⟦Ṁéţéŕ~~⟧',
  'st_q1.body[4].options[1]': '⟦ÇĜṀ~~⟧',
  'st_q1.body[4].options[2]': '⟦Ļàƀ öñļý~~~⟧',
  'st_q1.body[4].label': '⟦Ĥöŵ ðö ýöû çĥéçķ?~~~~~~⟧',
  'st_q1.footer[0].label': '⟦Ñéẋţ~~⟧',
  'st_q1.header.title': '⟦Àƀöûţ ýöû~~~~⟧',
  'st_q1.header.pill': '⟦1 öƒ 2~⟧',
  'st_range.body[1].text': '⟦Éñţéŕ ţĥé ŕàñĝé ýöûŕ çļîñîçîàñ ĝàṽé ýöû.~~~~~~~~~~~~~~⟧',
  'st_range.body[2].options[0]': '⟦ɱĝ/ðĻ~~⟧',
  'st_range.body[2].options[1]': '⟦ɱɱöļ/Ļ~~⟧',
  'st_range.body[3].fields[0].label': '⟦Ɓéƒöŕé ɱéàļš ƒŕöɱ~~~~~~⟧',
  'st_range.body[3].fields[1].label': '⟦ţö~⟧',
  'st_range.body[4].label': '⟦2 ĥ àƒţéŕ ɱéàļš ƀéļöŵ~~~~~~~⟧',
  'st_range.body[5].eyebrow': '⟦Ýöûŕ ļöŵ þļàñ~~~~~⟧',
  'st_range.body[5].children[0].label': '⟦Ļöŵ ƀéļöŵ~~~~⟧',
  'st_range.body[5].children[1].label': '⟦Ṁý ļöŵ šţéþš~~~~⟧',
  'st_range.body[5].children[1].placeholder': '⟦15 ĝ ƒàšţ šûĝàŕ, ŕé-çĥéçķ îñ 15 ɱîñ~~~~~~~~~⟧',
  'st_range.body[6].label': '⟦Îɱþöŕţ ƒŕöɱ ɱý ĥéàļţĥ ŕéçöŕð~~~~~~~~~~⟧',
  'st_range.footer[0].label': '⟦Šàṽé ŕàñĝé~~~~⟧',
  'st_range.header.title': '⟦Ýöûŕ ŕàñĝé~~~~⟧',
  'st_range.header.pill': '⟦2 öƒ 2~⟧',
  'st_home.body[0].eyebrow': '⟦Ļàšţ ŕéàðîñĝ · 2 ĥ àƒţéŕ ļûñçĥ~~~~~~~~~⟧',
  'st_home.body[0].children[0].caption': '⟦Ŵîţĥîñ ýöûŕ àƒţéŕ-ɱéàļ ŕàñĝé (ƀéļöŵ 180)~~~~~~~~~~~~⟧',
  'st_home.body[1].label': '⟦Ļöĝ à ŕéàðîñĝ~~~~~⟧',
  'st_home.body[2].rows[0].label': '⟦Ṁéàļ éñéŕĝý ŕéšéţ~~~~~~⟧',
  'st_home.body[2].rows[0].sub': '⟦3 ɱîñûţéš~~~⟧',
  'st_home.body[2].rows[1].label': '⟦Þàţţéŕñš~~~~⟧',
  'st_home.body[2].rows[1].sub': '⟦71% îñ ŕàñĝé · 14 ðàýš~~~~~⟧',
  'st_home.body[2].rows[2].label': '⟦À1Ç ĥîšţöŕý~~~~⟧',
  'st_home.body[2].rows[2].sub': '⟦7.4% · Öçţ 1~~⟧',
  'st_home.body[2].rows[3].label': '⟦Ṁý ŕàñĝé & ļöŵ þļàñ~~~~~~⟧',
  'st_home.body[2].rows[4].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'st_home.body[2].rows[4].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'st_home.body[3].text': '⟦Šţéàðý ñéṽéŕ çöûñţš çàļöŕîéš. À ĥîĝĥ ŕéàðîñĝ îš îñƒöŕɱàţîöñ, ñöţ ƒàîļûŕé.~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'st_log.body[0].label': '⟦Ŕéàðîñĝ~~~⟧',
  'st_log.body[0].hint': '⟦Ƒŕöɱ ýöûŕ ɱéţéŕ öŕ ÇĜṀ · 20–600 ɱĝ/ðĻ~~~~~~~~~⟧',
  'st_log.body[1].options[0]': '⟦Ƒàšţîñĝ~~~⟧',
  'st_log.body[1].options[1]': '⟦Ɓéƒöŕé ɱéàļ~~~~⟧',
  'st_log.body[1].options[2]': '⟦2 ĥ àƒţéŕ ɱéàļ~~~~⟧',
  'st_log.body[1].options[3]': '⟦Ɓéðţîɱé~~~⟧',
  'st_log.body[1].options[4]': '⟦Öţĥéŕ~~⟧',
  'st_log.body[1].label': '⟦Ŵĥéñ?~~⟧',
  'st_log.body[2].options[0]': '⟦Ƒîñé~~⟧',
  'st_log.body[2].options[1]': '⟦Šĥàķý~~⟧',
  'st_log.body[2].options[2]': '⟦Šŵéàţý~~~⟧',
  'st_log.body[2].options[3]': '⟦Ţîŕéð~~⟧',
  'st_log.body[2].options[4]': '⟦Ţĥîŕšţý~~~⟧',
  'st_log.body[2].label': '⟦Ĥöŵ ðö ýöû ƒééļ?~~~~~⟧',
  'st_log.body[3].label': '⟦Ñöţé (öþţîöñàļ)~~~~~⟧',
  'st_log.body[3].hint': '⟦Ñéṽéŕ šĥàŕéð ûñļéšš ýöû çĥööšé~~~~~~~~~~~⟧',
  'st_log.body[3].placeholder': '⟦Þàšţà ļûñçĥ~~~~⟧',
  'st_log.footer[0].action.then.cases[0].action.value': '⟦Šàṽéð~~⟧',
  'st_log.footer[0].action.then.cases[2].action.value': '⟦Çĥéçķ ýöûŕ ɱéţéŕ ŕéàðîñĝ~~~~~~~~~⟧',
  'st_log.footer[0].label': '⟦Šàṽé ŕéàðîñĝ~~~~~⟧',
  'st_log.header.title': '⟦Ļöĝ à ŕéàðîñĝ~~~~~⟧',
  'st_low.body[0].text': '⟦62 ɱĝ/ðĻ îš ƀéļöŵ ýöûŕ ļöŵ öƒ 70.~~~~~~~~⟧',
  'st_low.body[1].eyebrow': '⟦Ýöûŕ ļöŵ þļàñ~~~~~⟧',
  'st_low.body[1].children[0].items[0].label': '⟦Ţàķé 15 ĝ öƒ ƒàšţ šûĝàŕ~~~~~~~⟧',
  'st_low.body[1].children[0].items[0].sub': '⟦4 ĝļûçöšé ţàƀļéţš öŕ ½ çûþ ĵûîçé~~~~~~~~~~⟧',
  'st_low.body[1].children[0].items[1].label': '⟦Ŕé-çĥéçķ îñ 15 ɱîñûţéš~~~~~~~⟧',
  'st_low.body[1].children[0].items[2].label': '⟦Ŕéþéàţ îƒ šţîļļ ƀéļöŵ 70~~~~~~~~⟧',
  'st_low.body[2].label': '⟦ûñţîļ ŕé-çĥéçķ~~~~~⟧',
  'st_low.body[3].title': '⟦Çöñƒûšéð, çàñ’ţ šŵàļļöŵ öŕ þàššîñĝ öûţ?~~~~~~~~~~~~~⟧',
  'st_low.body[3].text': '⟦Šöɱéöñé šĥöûļð çàļļ 911 ñöŵ.~~~~~~~~⟧',
  'st_low.body[3].children[0].label': '⟦Çàļļ 911~~⟧',
  'st_low.footer[0].label': '⟦Ŕé-çĥéçķ ñöŵ~~~~⟧',
  'st_low.header.title': '⟦Ļöŵ ŕéàðîñĝ~~~~⟧',
  'st_reset.body[0].text': '⟦Ƒééļîñĝ ţĥé þöšţ-ɱéàļ šļûɱþ?~~~~~~~~~~⟧',
  'st_reset.body[1].children[0].items[0].label': '⟦Ðŕîñķ à ĝļàšš öƒ ŵàţéŕ~~~~~~~~⟧',
  'st_reset.body[1].children[0].items[1].label': '⟦Ţàķé à 10-ɱîñûţé ŵàļķ îƒ ýöû çàñ~~~~~~~~~~⟧',
  'st_reset.body[1].children[0].items[2].label': '⟦Ţàķé ƒîṽé šļöŵ ƀŕéàţĥš~~~~~~~~⟧',
  'st_reset.body[1].children[0].items[3].label': '⟦Ƒééļ ûñŵéļļ? Çöñţàçţ ýöûŕ çļîñîçîàñ~~~~~~~~~~~~⟧',
  'st_reset.body[2].text': '⟦Ŵàļķîñĝ àƒţéŕ ɱéàļš ĥéļþš šöɱé þéöþļé’š ŕéàðîñĝš. Çĥéçķ ŵîţĥ ýöûŕ çļîñîçîàñ ŵĥàţ’š ŕîĝĥţ ƒöŕ ýöû.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'st_reset.footer[0].action.value': '⟦Ñîçé ŵöŕķ~~~~⟧',
  'st_reset.footer[0].label': '⟦Ðöñé~~⟧',
  'st_reset.header.title': '⟦Ṁéàļ éñéŕĝý ŕéšéţ~~~~~~⟧',
  'st_reset.header.pill': '⟦3 ɱîñ~~⟧',
  'st_patterns.body[0].options[0]': '⟦7 ðàýš~~⟧',
  'st_patterns.body[0].options[1]': '⟦14 ðàýš~~⟧',
  'st_patterns.body[0].options[2]': '⟦30 ðàýš~~⟧',
  'st_patterns.body[1].title': '⟦Àƒţéŕ ɱéàļš~~~~⟧',
  'st_patterns.body[2].items[0].label': '⟦Îñ ýöûŕ ŕàñĝé~~~~~⟧',
  'st_patterns.body[2].items[0].sub': '⟦öƒ 38 ŕéàðîñĝš~~~~⟧',
  'st_patterns.body[2].items[1].label': '⟦Ļöŵš~~⟧',
  'st_patterns.body[2].items[1].sub': '⟦Öçţ 9 · ţŕéàţéð~~~~⟧',
  'st_patterns.body[3].eyebrow': '⟦Þàţţéŕñ~~~⟧',
  'st_patterns.body[3].title': '⟦Ŕéàðîñĝš ŵéŕé ĥîĝĥéŕ öñ ñîĝĥţš ŵîţĥ ļéšš ţĥàñ 6 ĥ šļééþ.~~~~~~~~~~~~~~~~~~⟧',
  'st_patterns.header.title': '⟦Þàţţéŕñš~~~~⟧',
  'st_a1c.body[0].text': '⟦Àðð ýöûŕ À1Ç~~~~⟧',
  'st_a1c.body[1].label': '⟦À1Ç~⟧',
  'st_a1c.body[2].label': '⟦Ļàƀ ðàţé~~~⟧',
  'st_a1c.body[2].placeholder': '⟦Öçţ 1, 2026~~⟧',
  'st_a1c.body[3].rows[0][0]': '⟦Þŕéṽîöûš~~~~⟧',
  'st_a1c.body[3].rows[0][1]': '⟦7.9% · Ĵûļ 2~~⟧',
  'st_a1c.body[3].rows[1][0]': '⟦Çĥàñĝé~~~⟧',
  'st_a1c.body[3].rows[1][1]': '⟦−0.5 þöîñţš~~~⟧',
  'st_a1c.body[4].text': '⟦Ýöûŕ çļîñîçîàñ šéţš ýöûŕ À1Ç ĝöàļ. Šţéàðý šĥöŵš ĥîšţöŕý öñļý.~~~~~~~~~~~~~~~~~~~~⟧',
  'st_a1c.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'st_a1c.footer[0].label': '⟦Šàṽé~~⟧',
  'st_a1c.header.title': '⟦À1Ç ļàƀ~~⟧',
  'st_a1c.header.pill': '⟦Ļàƀ ðàý~~~⟧',
  're_intro.body[0].extra': '⟦Ķîðñéý & ļîṽéŕ ĥéàļţĥ~~~~~~~⟧',
  're_intro.body[1].text': '⟦Ļööķ àƒţéŕ ýöûŕ ķîðñéýš àñð ļîṽéŕ.~~~~~~~~~~~~⟧',
  're_intro.body[2].rows[0][0]': '⟦Ŕîšķ çĥéçķ~~~~⟧',
  're_intro.body[2].rows[0][1]': '⟦ðîàƀéţéš, ƁÞ, àļçöĥöļ, ƒàɱîļý~~~~~~~~~~⟧',
  're_intro.body[2].rows[1][0]': '⟦Ļàƀš~~⟧',
  're_intro.body[2].rows[1][1]': '⟦éĜƑŔ, ÀÇŔ, ÀĻŢ ţŕàçķîñĝ~~~~~~~~⟧',
  're_intro.body[2].rows[2][0]': '⟦Ŕéɱîñðéŕš~~~~⟧',
  're_intro.body[2].rows[2][1]': '⟦çĥéçķš ƒŕöɱ ýöûŕ çļîñîçîàñ~~~~~~~~~~⟧',
  're_intro.footer[0].label': '⟦Šéţ ûþ Ŕéñéŵ~~~~⟧',
  're_intro.footer[1].action.then.value': '⟦Ŕéñéŵ àððéð àš Ļéàŕñ öñļý~~~~~~~~~⟧',
  're_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  're_intro.header.pill': '⟦~1 ɱîñ/ðàý~~~⟧',
  're_q1.body[1].text': '⟦Ðö àñý öƒ ţĥéšé àþþļý?~~~~~~~⟧',
  're_q1.body[2].text': '⟦Ţĥéšé ŕàîšé ţĥé çĥàñçé öƒ ķîðñéý öŕ ļîṽéŕ þŕöƀļéɱš.~~~~~~~~~~~~~~~~~⟧',
  're_q1.body[3].options[0]': '⟦Ðîàƀéţéš~~~~⟧',
  're_q1.body[3].options[1]': '⟦Ĥîĝĥ ƀļööð þŕéššûŕé~~~~~~~⟧',
  're_q1.body[3].options[2]': '⟦Ĥéàŕţ ðîšéàšé~~~~~⟧',
  're_q1.body[3].options[3]': '⟦Ƒàɱîļý ĥîšţöŕý öƒ ķîðñéý ðîšéàšé~~~~~~~~~~~~⟧',
  're_q1.body[3].options[4]': '⟦Ŕéĝûļàŕ àļçöĥöļ~~~~~~⟧',
  're_q1.body[3].options[5]': '⟦Ĥéþàţîţîš Ɓ öŕ Ç~~~~~~⟧',
  're_q1.body[3].options[6]': '⟦Ñöñé~~⟧',
  're_q1.body[4].options[0]': '⟦Ķîðñéý~~~⟧',
  're_q1.body[4].options[1]': '⟦Ļîṽéŕ~~⟧',
  're_q1.body[4].options[2]': '⟦Ɓöţĥ~~⟧',
  're_q1.body[4].options[3]': '⟦Ñö~⟧',
  're_q1.body[4].label': '⟦Ķñöŵñ çöñðîţîöñ?~~~~~~⟧',
  're_q1.footer[0].label': '⟦Šéé ŵĥàţ ţĥîš ɱéàñš~~~~~~~⟧',
  're_q1.header.title': '⟦Ŕîšķ çĥéçķ~~~~⟧',
  're_q1.header.pill': '⟦1 öƒ 1~⟧',
  're_result.body[0].text': '⟦Ŵöŕţĥ àšķîñĝ àƀöûţ à ķîðñéý çĥéçķ.~~~~~~~~~~~~⟧',
  're_result.body[1].text': '⟦Þéöþļé ŵîţĥ ðîàƀéţéš àñð ĥîĝĥ ƀļööð þŕéššûŕé àŕé ûšûàļļý àðṽîšéð ţö ĥàṽé ýéàŕļý ķîðñéý ţéšţš: à ƀļööð ţéšţ (éĜƑŔ) àñð à ûŕîñé ţéšţ (ÀÇŔ).~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  're_result.body[2].children[0].items[0].label': '⟦Àšķ àƀöûţ éĜƑŔ àñð ûŕîñé ÀÇŔ àţ ɱý ñéẋţ ṽîšîţ~~~~~~~~~~~~~~~⟧',
  're_result.body[2].children[0].items[1].label': '⟦Ŕéɱîñð ɱé 1 ŵééķ ƀéƒöŕé ɱý ṽîšîţ~~~~~~~~~~⟧',
  're_result.body[3].title': '⟦Àļšö šéé Ĥéàŕţŵîšé àñð Šţéàðý~~~~~~~~~~⟧',
  're_result.body[3].text': '⟦Ṁàñàĝîñĝ ƁÞ àñð ĝļûçöšé þŕöţéçţš ýöûŕ ķîðñéýš.~~~~~~~~~~~~~~~~⟧',
  're_result.footer[0].label': '⟦Šàṽé ɱý þļàñ~~~~⟧',
  're_result.header.title': '⟦Ýöûŕ ŕéšûļţ~~~~⟧',
  're_result.header.pill': '⟦Ñöţ à ðîàĝñöšîš~~~~~~⟧',
  're_home.body[0].eyebrow': '⟦Ļàţéšţ éĜƑŔ · Öçţ 3~~~~~~⟧',
  're_home.body[0].children[0].caption': '⟦Ñéẋţ çĥéçķ Àþŕ 2027 · ƒŕöɱ ýöûŕ çļîñîçîàñ~~~~~~~~~~~~⟧',
  're_home.body[1].eyebrow': '⟦Ţöðàý~~⟧',
  're_home.body[1].children[0].items[0].label': '⟦Ṁéðîçîñé ŕéɱîñðéŕ · 8:00 ÀṀ~~~~~~~~⟧',
  're_home.body[1].children[0].items[0].sub': '⟦Àš éñţéŕéð ƒŕöɱ ýöûŕ çļîñîçîàñ~~~~~~~~~~~⟧',
  're_home.body[1].children[0].items[1].label': '⟦Ŵàţéŕ ŕéɱîñðéŕ~~~~~~⟧',
  're_home.body[1].children[0].items[1].sub': '⟦Öñļý îƒ ýöûŕ çļîñîçîàñ ĥàšñ’ţ ļîɱîţéð ƒļûîðš~~~~~~~~~~~~~~~⟧',
  're_home.body[2].rows[0].label': '⟦Àðð ļàƀ ŕéšûļţš~~~~~~⟧',
  're_home.body[2].rows[1].label': '⟦Ļàƀ ĥîšţöŕý~~~~⟧',
  're_home.body[2].rows[1].sub': '⟦2 ýéàŕš~~⟧',
  're_home.body[2].rows[2].label': '⟦Çĥéçķ šýɱþţöɱš~~~~~~⟧',
  're_home.body[2].rows[3].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  're_home.body[2].rows[3].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  're_home.body[3].title': '⟦Öṽéŕ-ţĥé-çöûñţéŕ þàîñ ŕéļîéƒ?~~~~~~~~~~⟧',
  're_home.body[3].text': '⟦Šöɱé (ļîķé îƀûþŕöƒéñ) çàñ àƒƒéçţ ķîðñéýš. Àšķ ýöûŕ þĥàŕɱàçîšţ.~~~~~~~~~~~~~~~~~~~~⟧',
  're_labs.body[0].label': '⟦éĜƑŔ~~⟧',
  're_labs.body[1].label': '⟦Ûŕîñé ÀÇŔ~~~~⟧',
  're_labs.body[2].label': '⟦ÀĻŢ (ļîṽéŕ)~~~~⟧',
  're_labs.body[2].placeholder': '⟦Öþţîöñàļ~~~~⟧',
  're_labs.body[3].label': '⟦Ļàƀ ðàţé~~~⟧',
  're_labs.body[3].placeholder': '⟦Öçţ 3, 2026~~⟧',
  're_labs.body[4].text': '⟦Çöþý ñûɱƀéŕš éẋàçţļý ƒŕöɱ ýöûŕ ŕéþöŕţ. Ŕéñéŵ šĥöŵš ţŕéñðš; ýöûŕ çļîñîçîàñ éẋþļàîñš ţĥéɱ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  're_labs.body[5].label': '⟦Îɱþöŕţ ƒŕöɱ ɱý ĥéàļţĥ ŕéçöŕð~~~~~~~~~~⟧',
  're_labs.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  're_labs.footer[0].label': '⟦Šàṽé ŕéšûļţš~~~~~⟧',
  're_labs.header.title': '⟦Àðð ļàƀ ŕéšûļţš~~~~~~⟧',
  're_labs.header.pill': '⟦Ļàƀ~~⟧',
  're_history.body[0].title': '⟦éĜƑŔ · 2 ýéàŕš~~~~⟧',
  're_history.body[0].caption': '⟦Ļöŵéŕ öṽéŕ ţîɱé. Ɓŕîñĝ ţĥîš ţö ýöûŕ ñéẋţ ṽîšîţ.~~~~~~~~~~~~~~~⟧',
  're_history.body[1].rows[0][0]': '⟦Ļàţéšţ éĜƑŔ~~~~⟧',
  're_history.body[1].rows[0][1]': '⟦58 · Öçţ 3~~⟧',
  're_history.body[1].rows[1][0]': '⟦Ļàţéšţ ÀÇŔ~~~~⟧',
  're_history.body[1].rows[1][1]': '⟦42 ɱĝ/ĝ~~⟧',
  're_history.body[1].rows[2][0]': '⟦Ñéẋţ çĥéçķ~~~~⟧',
  're_history.body[1].rows[2][1]': '⟦Àþŕ 2027 (ƒŕöɱ ýöûŕ çļîñîçîàñ)~~~~~~~~⟧',
  're_history.footer[0].label': '⟦Çŕéàţé ṽîšîţ šûɱɱàŕý~~~~~~~~⟧',
  're_history.header.title': '⟦Ļàƀ ĥîšţöŕý~~~~⟧',
  're_symptoms.body[0].text': '⟦Ðö ýöû ĥàṽé àñý öƒ ţĥéšé?~~~~~~~~⟧',
  're_symptoms.body[1].options[0]': '⟦Ṽéŕý ļîţţļé ûŕîñé~~~~~~⟧',
  're_symptoms.body[1].options[1]': '⟦Šŵéļļîñĝ îñ ļéĝš öŕ ƒàçé~~~~~~~~⟧',
  're_symptoms.body[1].options[2]': '⟦Ýéļļöŵ šķîñ öŕ éýéš~~~~~~~⟧',
  're_symptoms.body[1].options[3]': '⟦Çöñƒûšîöñ~~~~⟧',
  're_symptoms.body[1].options[4]': '⟦Ṽöɱîţîñĝ ƀļööð~~~~~~⟧',
  're_symptoms.body[1].options[5]': '⟦Ñöñé~~⟧',
  're_symptoms.body[2].text': '⟦Ýéļļöŵ šķîñ öŕ éýéš ñééðš à çļîñîçîàñ ţöðàý.~~~~~~~~~~~~~~~⟧',
  're_symptoms.footer[0].label': '⟦Çöñţàçţ ɱý çàŕé ţéàɱ~~~~~~~⟧',
  're_symptoms.footer[1].label': '⟦Ṽöɱîţîñĝ ƀļööð öŕ çöñƒûšéð? Çàļļ 911~~~~~~~~~~~⟧',
  're_symptoms.header.title': '⟦Çĥéçķ šýɱþţöɱš~~~~~~⟧',
  'nu_intro.body[0].extra': '⟦Öƀéšîţý & ñûţŕîţîöñ~~~~~~~⟧',
  'nu_intro.body[1].text': '⟦Ƒööð ŵîţĥöûţ ĵûðĝɱéñţ.~~~~~~~~⟧',
  'nu_intro.body[2].rows[0][0]': '⟦Ŵééķļý ĥàƀîţ~~~~~⟧',
  'nu_intro.body[2].rows[0][1]': '⟦öñé àţ à ţîɱé~~~~⟧',
  'nu_intro.body[2].rows[1][0]': '⟦Ŵéîĝĥţ~~~⟧',
  'nu_intro.body[2].rows[1][1]': '⟦öƒƒ ƀý ðéƒàûļţ~~~~~⟧',
  'nu_intro.body[2].rows[2][0]': '⟦Àþþŕöàçĥ~~~~⟧',
  'nu_intro.body[2].rows[2][1]': '⟦àðð, ðöñ’ţ ŕéšţŕîçţ~~~~~~⟧',
  'nu_intro.footer[0].label': '⟦Šéţ ûþ Ñöûŕîšĥ~~~~~⟧',
  'nu_intro.footer[1].action.then.value': '⟦Ñöûŕîšĥ àððéð àš Ļéàŕñ öñļý~~~~~~~~~~⟧',
  'nu_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'nu_intro.header.pill': '⟦~1 ɱîñ/ðàý~~~⟧',
  'nu_q1.body[1].text': '⟦Ŵĥàţ ŵöûļð ýöû ļîķé ɱöŕé öƒ?~~~~~~~~~⟧',
  'nu_q1.body[2].options[0]': '⟦Éñéŕĝý~~~⟧',
  'nu_q1.body[2].options[1]': '⟦Éàšý ɱéàļš~~~~⟧',
  'nu_q1.body[2].options[2]': '⟦Ṁöŕé þļàñţš~~~~⟧',
  'nu_q1.body[2].options[3]': '⟦Ṁöŕé ŵàţéŕ~~~~⟧',
  'nu_q1.body[2].options[4]': '⟦Ṁöṽé ɱöŕé~~~~⟧',
  'nu_q1.body[2].options[5]': '⟦Šàṽé öñ ƒööð~~~~⟧',
  'nu_q1.body[2].options[6]': '⟦Ƒééļ ƀéţţéŕ àƀöûţ ƒööð~~~~~~~~⟧',
  'nu_q1.body[3].title': '⟦Ĥàṽé ýöû šţŕûĝĝļéð ŵîţĥ éàţîñĝ, ļîķé ŕéšţŕîçţîñĝ, ƀîñĝéîñĝ öŕ þûŕĝîñĝ?~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'nu_q1.body[3].text': '⟦Îƒ ýéš, ŵé àðĵûšţ Ñöûŕîšĥ àñð šĥàŕé šûþþöŕţ öþţîöñš.~~~~~~~~~~~~~~~~~⟧',
  'nu_q1.body[3].children[0].options[0]': '⟦Ñö~⟧',
  'nu_q1.body[3].children[0].options[1]': '⟦Ýéš~~⟧',
  'nu_q1.body[3].children[0].options[2]': '⟦Þŕéƒéŕ ñöţ ţö šàý~~~~~~⟧',
  'nu_q1.footer[0].label': '⟦Ñéẋţ~~⟧',
  'nu_q1.header.title': '⟦Ŵĥàţ ɱàţţéŕš~~~~~⟧',
  'nu_q1.header.pill': '⟦1 öƒ 1~⟧',
  'nu_habit.body[0].text': '⟦Þîçķ öñé ĥàƀîţ ƒöŕ ţĥîš ŵééķ.~~~~~~~~~~⟧',
  'nu_habit.body[1].items[0].label': '⟦Àðð à ṽéĝéţàƀļé ţö ðîññéŕ~~~~~~~~~⟧',
  'nu_habit.body[1].items[0].sub': '⟦5 ñîĝĥţš ţĥîš ŵééķ~~~~~~⟧',
  'nu_habit.body[1].items[0].badge': '⟦Šûĝĝéšţéð~~~~⟧',
  'nu_habit.body[1].items[1].label': '⟦Ŵàţéŕ ƀéƒöŕé éàçĥ ɱéàļ~~~~~~~~⟧',
  'nu_habit.body[1].items[1].sub': '⟦Éṽéŕý ðàý~~~~⟧',
  'nu_habit.body[1].items[2].label': '⟦Çööķ àţ ĥöɱé~~~~⟧',
  'nu_habit.body[1].items[2].sub': '⟦3 ţîɱéš ţĥîš ŵééķ~~~~~~⟧',
  'nu_habit.body[1].items[3].label': '⟦10-ɱîñûţé ŵàļķ àƒţéŕ à ɱéàļ~~~~~~~~⟧',
  'nu_habit.body[1].items[3].sub': '⟦4 ţîɱéš~~⟧',
  'nu_habit.body[2].children[0].label': '⟦Ţŕàçķ ŵéîĝĥţ~~~~~⟧',
  'nu_habit.body[2].children[0].sub': '⟦Öƒƒ ƀý ðéƒàûļţ · çàñ šţàý öƒƒ ƒöŕéṽéŕ~~~~~~~~~~~~⟧',
  'nu_habit.footer[0].label': '⟦Šţàŕţ ţĥîš ĥàƀîţ~~~~~~⟧',
  'nu_habit.header.title': '⟦Ţĥîš ŵééķ’š ĥàƀîţ~~~~~~⟧',
  'nu_habit.header.pill': '⟦Þļàñ~~⟧',
  'nu_home.body[0].eyebrow': '⟦Ĥàƀîţ · ŵééķ 2~~~~⟧',
  'nu_home.body[0].title': '⟦Àðð à ṽéĝéţàƀļé ţö ðîññéŕ~~~~~~~~~⟧',
  'nu_home.body[0].text': '⟦3 öƒ 5 ñîĝĥţš~~~~⟧',
  'nu_home.body[0].cta[0].action.value': '⟦Ñîçé. 4 öƒ 5 ñîĝĥţš.~~~~~⟧',
  'nu_home.body[0].cta[0].label': '⟦Ðöñé ţöðàý~~~~⟧',
  'nu_home.body[1].eyebrow': '⟦Ţîþ~~⟧',
  'nu_home.body[1].title': '⟦Ƒŕöžéñ ṽéĝéţàƀļéš çöûñţ, àñð àŕé öƒţéñ çĥéàþéŕ.~~~~~~~~~~~~~~~~⟧',
  'nu_home.body[2].eyebrow': '⟦Ǫûîçķ ŕéçîþé · 15 ɱîñ~~~~~~⟧',
  'nu_home.body[2].title': '⟦Ɓéàñ àñð ṽéĝĝîé ţàçöš~~~~~~~~⟧',
  'nu_home.body[2].text': '⟦Ûñðéŕ \$2 à šéŕṽîñĝ~~~~~~⟧',
  'nu_home.body[3].rows[0].label': '⟦Ɓûšý ŵééķ?~~~~⟧',
  'nu_home.body[3].rows[0].sub': '⟦Ŕéšéţ ŵîţĥöûţ ĝûîļţ~~~~~~~⟧',
  'nu_home.body[3].rows[1].label': '⟦Ŵééķ 4 ɱîļéšţöñé~~~~~~⟧',
  'nu_home.body[3].rows[1].sub': '⟦Îñ 2 ŵééķš~~~⟧',
  'nu_home.body[3].rows[2].label': '⟦Çĥàñĝé ĥàƀîţ~~~~~⟧',
  'nu_home.body[3].rows[3].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'nu_home.body[3].rows[3].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'nu_reset.body[0].text': '⟦Ɓûšý ŵééķ? Ţĥàţ’š öķàý.~~~~~~~⟧',
  'nu_reset.body[1].text': '⟦Ṁîššîñĝ ðàýš ðöéšñ’ţ ûñðö ţĥé öñéš ýöû ðîð.~~~~~~~~~~~~~~⟧',
  'nu_reset.body[2].items[0].label': '⟦Ķééþ ţĥîš ĥàƀîţ, šţàŕţ ƒŕéšĥ ţöðàý~~~~~~~~~~~~⟧',
  'nu_reset.body[2].items[1].label': '⟦Ṁàķé îţ šɱàļļéŕ~~~~~~⟧',
  'nu_reset.body[2].items[1].sub': '⟦3 ñîĝĥţš îñšţéàð öƒ 5~~~~~~⟧',
  'nu_reset.body[2].items[2].label': '⟦Þîçķ à ðîƒƒéŕéñţ ĥàƀîţ~~~~~~~~⟧',
  'nu_reset.footer[0].action.cases[0].action.value': '⟦Ƒŕéšĥ šţàŕţ ţöðàý~~~~~~⟧',
  'nu_reset.footer[0].action.cases[1].action.value': '⟦Ĝöàļ šéţ ţö 3 ñîĝĥţš~~~~~~⟧',
  'nu_reset.footer[0].label': '⟦Çöñţîñûé~~~~⟧',
  'nu_reset.header.title': '⟦Öƒƒ ţŕàçķ?~~~~⟧',
  'nu_reset.header.pill': '⟦Ŕéšéţ~~⟧',
  'nu_week4.body[1].text': '⟦Ƒöûŕ ŵééķš öƒ šɱàļļ ĥàƀîţš.~~~~~~~~~⟧',
  'nu_week4.body[2].rows[0][0]': '⟦Ĥàƀîţš ţŕîéð~~~~~⟧',
  'nu_week4.body[2].rows[1][0]': '⟦Ðàýš ðöñé~~~~⟧',
  'nu_week4.body[2].rows[2][0]': '⟦Ƒàṽöŕîţé~~~~⟧',
  'nu_week4.body[2].rows[2][1]': '⟦Ŵàţéŕ ƀéƒöŕé ɱéàļš~~~~~~~⟧',
  'nu_week4.body[3].options[0]': '⟦Ŵöŕšé~~⟧',
  'nu_week4.body[3].options[1]': '⟦Šàɱé~~⟧',
  'nu_week4.body[3].options[2]': '⟦Ɓéţţéŕ~~~⟧',
  'nu_week4.body[3].label': '⟦Ĥöŵ ðö ýöû ƒééļ àƀöûţ ƒööð ļàţéļý?~~~~~~~~~~~⟧',
  'nu_week4.footer[0].label': '⟦Çĥööšé ñéẋţ ĥàƀîţ~~~~~~⟧',
  'nu_week4.header.title': '⟦Ŵééķ 4~~⟧',
  'nu_week4.header.pill': '⟦Ṁîļéšţöñé~~~~⟧',
  'nu_protect.body[0].text': '⟦Ţĥàñķš ƒöŕ ţéļļîñĝ ûš.~~~~~~~~⟧',
  'nu_protect.body[1].text': '⟦Ñöûŕîšĥ ĥàš ţûŕñéð öƒƒ ŵéîĝĥţ, àɱöûñţ ĝöàļš àñð ƀéƒöŕé/àƒţéŕ çöɱþàŕîšöñš.~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'nu_protect.body[2].title': '⟦Ţàļķîñĝ ţö šöɱéöñé çàñ ĥéļþ~~~~~~~~~~⟧',
  'nu_protect.body[2].text': '⟦À çļîñîçîàñ öŕ éàţîñĝ-ðîšöŕðéŕ šþéçîàļîšţ çàñ šûþþöŕţ ýöû. Ŵé çàñ ĥéļþ ýöû þŕéþàŕé ŵĥàţ ţö šàý.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'nu_protect.body[2].cta[0].label': '⟦Þŕéþàŕé~~~⟧',
  'nu_protect.body[3].text': '⟦Îñ çŕîšîš? Çàļļ öŕ ţéẋţ 988 · Éɱéŕĝéñçý 911~~~~~~~~~~~⟧',
  'nu_protect.body[3].actions[0].label': '⟦Çàļļ öŕ ţéẋţ 988~~~~⟧',
  'nu_protect.body[3].actions[1].label': '⟦Çàļļ 911~~⟧',
  'nu_protect.footer[0].label': '⟦Çöñţîñûé ŵîţĥ ĝéñţļé ĥàƀîţš~~~~~~~~~~⟧',
  'nu_protect.header.title': '⟦Šûþþöŕţ~~~⟧',
  'nu_protect.header.pill': '⟦Þŕîṽàţé~~~⟧',
  'sd_intro.body[0].extra': '⟦Ĥéàļţĥý àĝîñĝ~~~~~⟧',
  'sd_intro.body[1].text': '⟦Ṁöṽé ŵéļļ, šţàý ŵéļļ.~~~~~~~⟧',
  'sd_intro.body[2].rows[0][0]': '⟦Šéššîöñš~~~~⟧',
  'sd_intro.body[2].rows[0][1]': '⟦5–15 ɱîñ, àûðîö + ṽîðéö~~~~~~⟧',
  'sd_intro.body[2].rows[1][0]': '⟦Ƒàļļš~~⟧',
  'sd_intro.body[2].rows[1][1]': '⟦ĥöɱé šàƒéţý + Î ƒéļļ ƀûţţöñ~~~~~~~~~⟧',
  'sd_intro.body[2].rows[2][0]': '⟦Çàŕéĝîṽéŕ~~~~⟧',
  'sd_intro.body[2].rows[2][1]': '⟦öþţîöñàļ, Šţŕîðé öñļý~~~~~~~~⟧',
  'sd_intro.footer[0].label': '⟦Šéţ ûþ Šţŕîðé~~~~~⟧',
  'sd_intro.footer[1].action.then.value': '⟦Šţŕîðé àððéð àš Ļéàŕñ öñļý~~~~~~~~~⟧',
  'sd_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'sd_intro.header.pill': '⟦~10 ɱîñ/ðàý~~~⟧',
  'sd_q1.body[1].options[0]': '⟦Ñö~⟧',
  'sd_q1.body[1].options[1]': '⟦Öñçé~~⟧',
  'sd_q1.body[1].options[2]': '⟦2+ ţîɱéš~~⟧',
  'sd_q1.body[1].label': '⟦Îñ ţĥé ļàšţ ýéàŕ, ĥàṽé ýöû ƒàļļéñ?~~~~~~~~~~~⟧',
  'sd_q1.body[2].options[0]': '⟦Ñö~⟧',
  'sd_q1.body[2].options[1]': '⟦Šöɱéţîɱéš~~~~⟧',
  'sd_q1.body[2].options[2]': '⟦Öƒţéñ~~⟧',
  'sd_q1.body[2].label': '⟦Ðö ýöû ƒééļ ûñšţéàðý šţàñðîñĝ öŕ ŵàļķîñĝ?~~~~~~~~~~~~~~⟧',
  'sd_q1.body[3].options[0]': '⟦Ñö~⟧',
  'sd_q1.body[3].options[1]': '⟦À ļîţţļé~~~⟧',
  'sd_q1.body[3].options[2]': '⟦À ļöţ~~⟧',
  'sd_q1.body[3].label': '⟦Ðö ýöû ŵöŕŕý àƀöûţ ƒàļļîñĝ?~~~~~~~~~⟧',
  'sd_q1.body[4].text': '⟦À ƒàļļ þļûš ƒééļîñĝ ûñšţéàðý îš ŵöŕţĥ ɱéñţîöñîñĝ ţö ýöûŕ çļîñîçîàñ. Ŵé’ļļ àðð îţ ţö ýöûŕ ṽîšîţ ļîšţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sd_q1.footer[0].label': '⟦Ñéẋţ~~⟧',
  'sd_q1.header.title': '⟦Ĥöŵ ýöû ɱöṽé~~~~⟧',
  'sd_q1.header.pill': '⟦1 öƒ 1~⟧',
  'sd_plan.body[0].text': '⟦Ţĥŕéé šĥöŕţ šéššîöñš à ŵééķ~~~~~~~~~~⟧',
  'sd_plan.body[1].rows[0][0]': '⟦Ṁöñ~~⟧',
  'sd_plan.body[1].rows[0][1]': '⟦Ɓàļàñçé · 8 ɱîñ~~~~⟧',
  'sd_plan.body[1].rows[1][0]': '⟦Ŵéð~~⟧',
  'sd_plan.body[1].rows[1][1]': '⟦Šţŕéñĝţĥ (çĥàîŕ) · 10 ɱîñ~~~~~~~⟧',
  'sd_plan.body[1].rows[2][0]': '⟦Ƒŕî~~⟧',
  'sd_plan.body[1].rows[2][1]': '⟦Ŵàļķ + ƀàļàñçé · 12 ɱîñ~~~~~~⟧',
  'sd_plan.body[2].children[0].items[0].label': '⟦Ðö šéššîöñš ñéàŕ à šţûŕðý çĥàîŕ~~~~~~~~~~~⟧',
  'sd_plan.body[2].children[0].items[1].label': '⟦Ţéļļ ɱý çàŕéĝîṽéŕ ŵĥéñ Î ƒîñîšĥ~~~~~~~~~~~⟧',
  'sd_plan.body[3].text': '⟦Çĥéçķ ŵîţĥ ýöûŕ çļîñîçîàñ ƀéƒöŕé šţàŕţîñĝ à ñéŵ éẋéŕçîšé þŕöĝŕàɱ.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sd_plan.footer[0].label': '⟦Šţàŕţ þļàñ~~~~⟧',
  'sd_plan.header.title': '⟦Ýöûŕ ɱöṽéɱéñţ þļàñ~~~~~~~⟧',
  'sd_plan.header.pill': '⟦Þļàñ~~⟧',
  'sd_home.body[0].eyebrow': '⟦Ţöðàý · Ŵéðñéšðàý~~~~~~⟧',
  'sd_home.body[0].title': '⟦Šţŕéñĝţĥ (çĥàîŕ) · 10 ɱîñ~~~~~~~⟧',
  'sd_home.body[0].cta[0].label': '⟦Šţàŕţ~~⟧',
  'sd_home.body[1].title': '⟦Î ƒéļļ~~⟧',
  'sd_home.body[1].text': '⟦Ĝéţ ĥéļþ öŕ ļöĝ à ƒàļļ~~~~~~~⟧',
  'sd_home.body[2].rows[0].label': '⟦Ĥöɱé šàƒéţý çĥéçķļîšţ~~~~~~~~⟧',
  'sd_home.body[2].rows[0].sub': '⟦2 öƒ 5 ðöñé~~~⟧',
  'sd_home.body[2].rows[1].label': '⟦Çàŕéĝîṽéŕ àççéšš~~~~~~⟧',
  'sd_home.body[2].rows[1].sub': '⟦Ŕöšà · Šţŕîðé öñļý~~~~~~⟧',
  'sd_home.body[2].rows[2].label': '⟦Ṁöṽéɱéñţ þļàñ~~~~~⟧',
  'sd_home.body[2].rows[2].sub': '⟦3 šéššîöñš à ŵééķ~~~~~~⟧',
  'sd_home.body[2].rows[3].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'sd_home.body[2].rows[3].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'sd_home.body[3].items[0].label': '⟦Ţĥîš ŵééķ~~~~⟧',
  'sd_home.body[3].items[0].value': '⟦1 öƒ 3~⟧',
  'sd_home.body[3].items[0].sub': '⟦šéššîöñš~~~~⟧',
  'sd_home.body[3].items[1].label': '⟦Ƒàļļš ļöĝĝéð~~~~~⟧',
  'sd_home.body[3].items[1].sub': '⟦ļàšţ 30 ðàýš~~~~⟧',
  'sd_session.body[1].text': '⟦Ĥééļ-ţö-ţöé šţàñð~~~~~~⟧',
  'sd_session.body[2].text': '⟦Ĥöļð ţĥé çĥàîŕ. Þļàçé öñé ƒööţ îñ ƒŕöñţ öƒ ţĥé öţĥéŕ. Ĥöļð 10 šéçöñðš.~~~~~~~~~~~~~~~~~~~~~⟧',
  'sd_session.body[4].options[0]': '⟦Àûðîö öñ~~~⟧',
  'sd_session.body[4].options[1]': '⟦Ļàŕĝé ţéẋţ~~~~⟧',
  'sd_session.body[4].options[2]': '⟦Çàþţîöñš~~~~⟧',
  'sd_session.footer[0].action.value': '⟦Éẋéŕçîšé 3 öƒ 6~~~~⟧',
  'sd_session.footer[0].label': '⟦Ñéẋţ éẋéŕçîšé~~~~~⟧',
  'sd_session.footer[1].action.then.value': '⟦Šéššîöñ šàṽéð~~~~~⟧',
  'sd_session.footer[1].label': '⟦Ƒîñîšĥ šéššîöñ~~~~~~⟧',
  'sd_session.header.title': '⟦Ɓàļàñçé · 8 ɱîñ~~~~⟧',
  'sd_session.header.pill': '⟦2 öƒ 6~⟧',
  'sd_fell.body[0].text': '⟦Àŕé ýöû ĥûŕţ?~~~~⟧',
  'sd_fell.body[1].label': '⟦Î ĥîţ ɱý ĥéàð öŕ çàñ’ţ ĝéţ ûþ · Çàļļ 911~~~~~~~~~~⟧',
  'sd_fell.body[2].rows[0].label': '⟦Çàļļ Ŕöšà~~~~⟧',
  'sd_fell.body[2].rows[0].sub': '⟦Çàŕéĝîṽéŕ~~~~⟧',
  'sd_fell.body[3].title': '⟦Ĥöŵ ţö ĝéţ ûþ šàƒéļý~~~~~~~⟧',
  'sd_fell.body[3].text': '⟦Ŕöļļ ţö ýöûŕ šîðé, çŕàŵļ ţö à šţûŕðý çĥàîŕ, ķñééļ, ţĥéñ ŕîšé šļöŵļý.~~~~~~~~~~~~~~~~~~~~~⟧',
  'sd_fell.footer[0].action.then.value': '⟦Ƒàļļ ļöĝĝéð. Àððéð ţö ýöûŕ ṽîšîţ ļîšţ.~~~~~~~~~~~~⟧',
  'sd_fell.footer[0].label': '⟦Î’ɱ öķàý, ļöĝ ţĥîš ƒàļļ~~~~~~~⟧',
  'sd_fell.header.title': '⟦Î ƒéļļ~~⟧',
  'sd_safety.body[0].text': '⟦Ṁàķé ýöûŕ ĥöɱé šàƒéŕ~~~~~~~⟧',
  'sd_safety.body[1].children[0].items[0].label': '⟦Ŕéɱöṽé ļööšé ŕûĝš~~~~~~⟧',
  'sd_safety.body[1].children[0].items[1].label': '⟦Ñîĝĥţ ļîĝĥţš îñ ĥàļļŵàý àñð ƀàţĥŕööɱ~~~~~~~~~~~~~⟧',
  'sd_safety.body[1].children[0].items[2].label': '⟦Ĝŕàƀ ƀàŕ îñ šĥöŵéŕ~~~~~~⟧',
  'sd_safety.body[1].children[0].items[3].label': '⟦Šţàîŕ ŕàîļš öñ ƀöţĥ šîðéš~~~~~~~~~⟧',
  'sd_safety.body[1].children[0].items[4].label': '⟦Ṽîšîöñ çĥéçķ ţĥîš ýéàŕ~~~~~~~~⟧',
  'sd_safety.body[2].text': '⟦2 öƒ 5 ðöñé~~~⟧',
  'sd_safety.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'sd_safety.footer[0].label': '⟦Šàṽé~~⟧',
  'sd_safety.header.title': '⟦Ĥöɱé šàƒéţý~~~~⟧',
  'sd_safety.header.pill': '⟦Çĥéçķļîšţ~~~~⟧',
  'sd_caregiver.body[0].text': '⟦Ļéţ šöɱéöñé ĥéļþ~~~~~~⟧',
  'sd_caregiver.body[1].label': '⟦Ñàɱé~~⟧',
  'sd_caregiver.body[1].placeholder': '⟦Ŕöšà~~⟧',
  'sd_caregiver.body[2].label': '⟦Þĥöñé~~⟧',
  'sd_caregiver.body[3].items[0].label': '⟦Ŵĥéñ Î ƒîñîšĥ à šéššîöñ~~~~~~~~⟧',
  'sd_caregiver.body[3].items[1].label': '⟦Îƒ Î ļöĝ à ƒàļļ~~~~~⟧',
  'sd_caregiver.body[3].items[2].label': '⟦Ṁý öţĥéŕ þŕöĝŕàɱš~~~~~~⟧',
  'sd_caregiver.body[3].items[2].sub': '⟦Ñéṽéŕ àṽàîļàƀļé ţö çàŕéĝîṽéŕš~~~~~~~~~~~⟧',
  'sd_caregiver.body[3].label': '⟦Ŕöšà çàñ šéé~~~~⟧',
  'sd_caregiver.footer[0].action.then.value': '⟦Îñṽîţé šéñţ ţö Ŕöšà~~~~~~~⟧',
  'sd_caregiver.footer[0].label': '⟦Šéñð îñṽîţé~~~~⟧',
  'sd_caregiver.header.title': '⟦Çàŕéĝîṽéŕ àççéšš~~~~~~⟧',
  'sd_caregiver.header.pill': '⟦Öþţîöñàļ~~~~⟧',
  'ea_intro.body[0].extra': '⟦Ṁéñţàļ & ƀéĥàṽîöŕàļ ĥéàļţĥ~~~~~~~~~⟧',
  'ea_intro.body[1].text': '⟦Šûþþöŕţ ƒöŕ ĥöŵ ýöû ƒééļ.~~~~~~~~⟧',
  'ea_intro.body[2].rows[0][0]': '⟦Ṁööð çĥéçķ-îñ~~~~~⟧',
  'ea_intro.body[2].rows[0][1]': '⟦30 šéçöñðš~~~⟧',
  'ea_intro.body[2].rows[1][0]': '⟦Šçŕééñîñĝ~~~~⟧',
  'ea_intro.body[2].rows[1][1]': '⟦öþţîöñàļ, þŕîṽàţé~~~~~~⟧',
  'ea_intro.body[2].rows[2][0]': '⟦Ĥéļþ ñöŵ~~~⟧',
  'ea_intro.body[2].rows[2][1]': '⟦988 àļŵàýš öñé ţàþ àŵàý~~~~~~~⟧',
  'ea_intro.footer[0].label': '⟦Šéţ ûþ Éàšé~~~~⟧',
  'ea_intro.footer[1].action.then.value': '⟦Éàšé àððéð àš Ļéàŕñ öñļý~~~~~~~~⟧',
  'ea_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'ea_intro.header.pill': '⟦~2 ɱîñ/ðàý~~~⟧',
  'ea_q1.body[1].text': '⟦Öṽéŕ ţĥé ļàšţ 2 ŵééķš, ĥöŵ öƒţéñ ĥàṽé ýöû ƀééñ ƀöţĥéŕéð ƀý…~~~~~~~~~~~~~~~~~~⟧',
  'ea_q1.body[2].text': '⟦Ļîţţļé îñţéŕéšţ öŕ þļéàšûŕé îñ ðöîñĝ ţĥîñĝš?~~~~~~~~~~~~~~~⟧',
  'ea_q1.body[3].items[0].label': '⟦Ñöţ àţ àļļ~~~~⟧',
  'ea_q1.body[3].items[1].label': '⟦Šéṽéŕàļ ðàýš~~~~~⟧',
  'ea_q1.body[3].items[2].label': '⟦Ṁöŕé ţĥàñ ĥàļƒ ţĥé ðàýš~~~~~~~~⟧',
  'ea_q1.body[3].items[3].label': '⟦Ñéàŕļý éṽéŕý ðàý~~~~~~⟧',
  'ea_q1.body[4].text': '⟦ÞĤǪ-2 / ĜÀÐ-2 · ṽàļîðàţéð ǫûéšţîöñš · šķîþþàƀļé~~~~~~~~~~~~~~⟧',
  'ea_q1.footer[0].label': '⟦Ñéẋţ~~⟧',
  'ea_q1.footer[1].label': '⟦Šķîþ ţĥé çĥéçķ~~~~~⟧',
  'ea_q1.header.title': '⟦Öþţîöñàļ çĥéçķ~~~~~~⟧',
  'ea_q1.header.pill': '⟦1 öƒ 4~⟧',
  'ea_result.body[0].text': '⟦Ţàļķîñĝ ţö šöɱéöñé çöûļð ĥéļþ.~~~~~~~~~~⟧',
  'ea_result.body[1].text': '⟦Ýöûŕ àñšŵéŕš šûĝĝéšţ ýöû’ṽé ƀééñ çàŕŕýîñĝ à ļöţ ļàţéļý. À ðöçţöŕ, çöûñšéļöŕ öŕ ţĥéŕàþîšţ çàñ ĥéļþ ƒîĝûŕé öûţ ŵĥàţ ŵöûļð ɱàķé ţĥé ƀîĝĝéšţ ðîƒƒéŕéñçé.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ea_result.body[2].rows[0].label': '⟦Ƒîñð à ţĥéŕàþîšţ ñéàŕ ɱé~~~~~~~~⟧',
  'ea_result.body[2].rows[0].sub': '⟦Îñ-ñéţŵöŕķ ƒîļţéŕš~~~~~~~⟧',
  'ea_result.body[2].rows[1].label': '⟦Ţàļķ ţö ɱý þŕîɱàŕý çàŕé ðöçţöŕ~~~~~~~~~~⟧',
  'ea_result.body[2].rows[1].sub': '⟦Ŵé’ļļ ĥéļþ ýöû þŕéþàŕé~~~~~~~~⟧',
  'ea_result.body[2].rows[2].label': '⟦Ñöţ ñöŵ~~~⟧',
  'ea_result.body[2].rows[2].sub': '⟦Ķééþ ûšîñĝ Éàšé ţööļš~~~~~~~~⟧',
  'ea_result.body[3].text': '⟦Ţĥöûĝĥţš öƒ ĥàŕɱîñĝ ýöûŕšéļƒ? Çàļļ öŕ ţéẋţ 988. Éɱéŕĝéñçý: 911.~~~~~~~~~~~~~~~~~~⟧',
  'ea_result.body[3].actions[0].label': '⟦Çàļļ öŕ ţéẋţ 988~~~~⟧',
  'ea_result.body[3].actions[1].label': '⟦Çàļļ 911~~⟧',
  'ea_result.header.title': '⟦Ýöûŕ àñšŵéŕš~~~~~⟧',
  'ea_result.header.pill': '⟦Ñöţ à ðîàĝñöšîš~~~~~~⟧',
  'ea_plan.body[0].text': '⟦Ṁàķé à þļàñ ƒöŕ ĥàŕð ɱöɱéñţš~~~~~~~~~~⟧',
  'ea_plan.body[1].text': '⟦Ɓàšéð öñ ţĥé Šţàñļéý-Ɓŕöŵñ šàƒéţý þļàñ. Öñļý ýöû çàñ šéé ţĥîš.~~~~~~~~~~~~~~~~~~~~⟧',
  'ea_plan.body[2].label': '⟦Ṁý ŵàŕñîñĝ šîĝñš~~~~~~⟧',
  'ea_plan.body[2].placeholder': '⟦Ñöţ šļééþîñĝ, þûļļîñĝ àŵàý ƒŕöɱ ƒŕîéñðš~~~~~~~~~~~~~~⟧',
  'ea_plan.body[3].label': '⟦Ţĥîñĝš ţĥàţ ĥéļþ ɱé~~~~~~~⟧',
  'ea_plan.body[3].placeholder': '⟦Ŵàļķ ţĥé ðöĝ, šĥöŵéŕ, ɱûšîç~~~~~~~~~⟧',
  'ea_plan.body[4].label': '⟦Þéöþļé Î çàñ ŕéàçĥ~~~~~~⟧',
  'ea_plan.body[4].placeholder': '⟦Šàɱ · (555) 010-3311~~⟧',
  'ea_plan.body[5].rows[0][0]': '⟦Çŕîšîš ļîñé~~~~⟧',
  'ea_plan.body[5].rows[0][1]': '⟦988 · çàļļ öŕ ţéẋţ~~~~⟧',
  'ea_plan.body[5].rows[1][0]': '⟦Éɱéŕĝéñçý~~~~⟧',
  'ea_plan.footer[0].label': '⟦Šàṽé þļàñ~~~~⟧',
  'ea_plan.header.title': '⟦Šàƒéţý þļàñ~~~~⟧',
  'ea_plan.header.pill': '⟦Þŕîṽàţé~~~⟧',
  'ea_home.body[0].eyebrow': '⟦Ĥöŵ àŕé ýöû ŕîĝĥţ ñöŵ?~~~~~~~⟧',
  'ea_home.body[0].title': '⟦30-šéçöñð ɱööð çĥéçķ-îñ~~~~~~~⟧',
  'ea_home.body[0].cta[0].label': '⟦Šţàŕţ~~⟧',
  'ea_home.body[1].rows[0].label': '⟦Ṁý šàƒéţý þļàñ~~~~~⟧',
  'ea_home.body[1].rows[0].sub': '⟦Ûþðàţéð Öçţ 2~~~~⟧',
  'ea_home.body[1].rows[1].label': '⟦Çĥéçķ-ƀàçķ~~~~⟧',
  'ea_home.body[1].rows[1].sub': '⟦Îñ 6 ðàýš~~~⟧',
  'ea_home.body[1].rows[2].label': '⟦Ƒîñð à þŕöƒéššîöñàļ~~~~~~~⟧',
  'ea_home.body[1].rows[3].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'ea_home.body[1].rows[3].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'ea_home.body[2].title': '⟦Šļééþ àñð ɱööð: 3 šɱàļļ çĥàñĝéš~~~~~~~~~~⟧',
  'ea_home.body[2].text': '⟦5 ɱîñ~~⟧',
  'ea_home.body[3].text': '⟦Ţĥöûĝĥţš öƒ ĥàŕɱîñĝ ýöûŕšéļƒ? Çàļļ öŕ ţéẋţ 988. Éɱéŕĝéñçý: 911.~~~~~~~~~~~~~~~~~~⟧',
  'ea_home.body[3].actions[0].label': '⟦Çàļļ öŕ ţéẋţ 988~~~~⟧',
  'ea_home.body[3].actions[1].label': '⟦Çàļļ 911~~⟧',
  'ea_mood.body[0].options[0]': '⟦Ṽéŕý ļöŵ~~~⟧',
  'ea_mood.body[0].options[1]': '⟦Ļöŵ~~⟧',
  'ea_mood.body[0].options[2]': '⟦Öķàý~~⟧',
  'ea_mood.body[0].options[3]': '⟦Ĝööð~~⟧',
  'ea_mood.body[0].options[4]': '⟦Ĝŕéàţ~~⟧',
  'ea_mood.body[0].label': '⟦Ĥöŵ àŕé ýöû ŕîĝĥţ ñöŵ?~~~~~~~⟧',
  'ea_mood.body[1].options[0]': '⟦Ŵöŕķ~~⟧',
  'ea_mood.body[1].options[1]': '⟦Ṁöñéý~~⟧',
  'ea_mood.body[1].options[2]': '⟦Ƒàɱîļý~~~⟧',
  'ea_mood.body[1].options[3]': '⟦Ĥéàļţĥ~~~⟧',
  'ea_mood.body[1].options[4]': '⟦Ļöñéļý~~~⟧',
  'ea_mood.body[1].options[5]': '⟦Šļééþ~~⟧',
  'ea_mood.body[1].options[6]': '⟦Ţĥöûĝĥţš öƒ ĥàŕɱîñĝ ɱýšéļƒ~~~~~~~~~~⟧',
  'ea_mood.body[1].options[7]': '⟦Ñöţ šûŕé~~~⟧',
  'ea_mood.body[1].label': '⟦Ŵĥàţ’š ĝöîñĝ öñ?~~~~~⟧',
  'ea_mood.body[2].eyebrow': '⟦Ţŕý ñöŵ · 2 ɱîñ~~~~⟧',
  'ea_mood.body[2].title': '⟦Ĝŕöûñðîñĝ: 5 ţĥîñĝš ýöû çàñ šéé~~~~~~~~~~⟧',
  'ea_mood.body[2].cta[0].label': '⟦Šţàŕţ~~⟧',
  'ea_mood.footer[0].action.then.cases[0].action.value': '⟦Šàṽéð~~⟧',
  'ea_mood.footer[0].label': '⟦Šàṽé~~⟧',
  'ea_mood.header.title': '⟦Ṁööð çĥéçķ-îñ~~~~~⟧',
  'ea_checkback.body[0].text': '⟦Îţ’š ƀééñ ţŵö ŵééķš. Ĥöŵ àŕé ţĥîñĝš?~~~~~~~~~~~⟧',
  'ea_checkback.body[1].options[0]': '⟦Ŵöŕšé~~⟧',
  'ea_checkback.body[1].options[1]': '⟦Šàɱé~~⟧',
  'ea_checkback.body[1].options[2]': '⟦Ɓéţţéŕ~~~⟧',
  'ea_checkback.body[2].options[0]': '⟦Ýéš, Î ĥàṽé àñ àþþöîñţɱéñţ~~~~~~~~~⟧',
  'ea_checkback.body[2].options[1]': '⟦Ñöţ ýéţ~~~⟧',
  'ea_checkback.body[2].options[2]': '⟦Î ðöñ’ţ ŵàñţ ţö~~~~~⟧',
  'ea_checkback.body[2].label': '⟦Ðîð ýöû ŕéàçĥ öûţ ţö šöɱéöñé?~~~~~~~~~~⟧',
  'ea_checkback.body[3].text': '⟦Ţĥàţ’š öķàý. Ŵöûļð à šĥöŕţ ļîšţ öƒ ŵĥàţ ţö šàý ĥéļþ?~~~~~~~~~~~~~~~~⟧',
  'ea_checkback.body[3].cta[0].label': '⟦Šĥöŵ ɱé~~~⟧',
  'ea_checkback.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'ea_checkback.footer[0].label': '⟦Šàṽé~~⟧',
  'ea_checkback.header.title': '⟦Çĥéçķ-ƀàçķ~~~~⟧',
  'ea_checkback.header.pill': '⟦2 ŵééķš~~⟧',
  'ck_intro.body[0].extra': '⟦Þŕéṽéñţîṽé ĥéàļţĥ~~~~~~~⟧',
  'ck_intro.body[1].text': '⟦Ŵĥàţ’š ðûé ƒöŕ ýöû, îñ öñé þļàçé.~~~~~~~~~~⟧',
  'ck_intro.body[2].rows[0][0]': '⟦Þéŕšöñàļ ļîšţ~~~~~⟧',
  'ck_intro.body[2].rows[0][1]': '⟦ÛŠÞŠŢƑ / ÇÐÇ ĝûîðàñçé~~~~~~~⟧',
  'ck_intro.body[2].rows[1][0]': '⟦Ŕéɱîñðéŕš~~~~⟧',
  'ck_intro.body[2].rows[1][1]': '⟦ŵééķļý, ǫûîéţ~~~~~⟧',
  'ck_intro.body[2].rows[2][0]': '⟦Ŕéçöŕðš~~~⟧',
  'ck_intro.body[2].rows[2][1]': '⟦ɱàŕķ ðöñé, àðð ðàţéš~~~~~~~⟧',
  'ck_intro.footer[0].label': '⟦Šéţ ûþ Çĥéçķûþ~~~~~⟧',
  'ck_intro.footer[1].action.then.value': '⟦Çĥéçķûþ àððéð àš Ļéàŕñ öñļý~~~~~~~~~~⟧',
  'ck_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'ck_intro.header.pill': '⟦~1 ɱîñ/ŵééķ~~~⟧',
  'ck_q1.body[1].text': '⟦À ƒéŵ ðéţàîļš ţö þéŕšöñàļîžé~~~~~~~~~~⟧',
  'ck_q1.body[2].label': '⟦Àĝé~~⟧',
  'ck_q1.body[3].options[0]': '⟦Ƒéɱàļé~~~⟧',
  'ck_q1.body[3].options[1]': '⟦Ṁàļé~~⟧',
  'ck_q1.body[3].options[2]': '⟦Îñţéŕšéẋ~~~~⟧',
  'ck_q1.body[3].options[3]': '⟦Šķîþ~~⟧',
  'ck_q1.body[3].label': '⟦Šéẋ àššîĝñéð àţ ƀîŕţĥ~~~~~~~~⟧',
  'ck_q1.body[4].options[0]': '⟦Šɱöķé öŕ ûšéð ţö~~~~~~⟧',
  'ck_q1.body[4].options[1]': '⟦Ðîàƀéţéš~~~~⟧',
  'ck_q1.body[4].options[2]': '⟦Ƒàɱîļý ĥîšţöŕý öƒ çàñçéŕ~~~~~~~~~⟧',
  'ck_q1.body[4].options[3]': '⟦Þŕéĝñàñţ~~~~⟧',
  'ck_q1.body[4].options[4]': '⟦Ñöñé~~⟧',
  'ck_q1.body[4].label': '⟦Àñý öƒ ţĥéšé?~~~~⟧',
  'ck_q1.body[5].text': '⟦Ûšéð öñļý ţö ƀûîļð ýöûŕ ļîšţ. Çĥàñĝé àñýţîɱé.~~~~~~~~~~~~~~~⟧',
  'ck_q1.body[6].label': '⟦Îɱþöŕţ ṽàççîñàţîöñ ĥîšţöŕý~~~~~~~~~~⟧',
  'ck_q1.footer[0].label': '⟦Ɓûîļð ɱý ļîšţ~~~~~⟧',
  'ck_q1.header.title': '⟦Àƀöûţ ýöû~~~~⟧',
  'ck_q1.header.pill': '⟦1 öƒ 1~⟧',
  'ck_list.body[0].text': '⟦3 ðûé, 1 ţö àšķ àƀöûţ~~~~~~⟧',
  'ck_list.body[1].eyebrow': '⟦Ðûé ñöŵ~~~⟧',
  'ck_list.body[1].title': '⟦Ƒļû ṽàççîñé~~~~⟧',
  'ck_list.body[1].text': '⟦Éṽéŕý ýéàŕ · þĥàŕɱàçîéš öƒƒéŕ ŵàļķ-îñš~~~~~~~~~~~~~⟧',
  'ck_list.body[1].children[0].items[0].label': '⟦Ƒîñð à þĥàŕɱàçý~~~~~~⟧',
  'ck_list.body[1].children[0].items[1].label': '⟦Î ĝöţ îţ~~~⟧',
  'ck_list.body[2].rows[0].label': '⟦Çöļöŕéçţàļ šçŕééñîñĝ~~~~~~~~⟧',
  'ck_list.body[2].rows[0].sub': '⟦Àĝéš 45–75 · šéṽéŕàļ öþţîöñš~~~~~~~~⟧',
  'ck_list.body[2].rows[0].pill': '⟦Ðûé~~⟧',
  'ck_list.body[2].rows[1].label': '⟦Ṁàɱɱöĝŕàɱ~~~~⟧',
  'ck_list.body[2].rows[1].sub': '⟦Éṽéŕý 2 ýéàŕš, àĝéš 40–74~~~~~~⟧',
  'ck_list.body[2].rows[1].pill': '⟦Ðûé~~⟧',
  'ck_list.body[2].rows[2].label': '⟦Ļûñĝ çàñçéŕ šçŕééñîñĝ~~~~~~~~⟧',
  'ck_list.body[2].rows[2].sub': '⟦Àĝéš 50–80 ŵîţĥ šɱöķîñĝ ĥîšţöŕý~~~~~~~~~⟧',
  'ck_list.body[2].rows[2].pill': '⟦Àšķ~~⟧',
  'ck_list.body[2].rows[3].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'ck_list.body[2].rows[3].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'ck_uptodate.body[1].text': '⟦Ýöû’ŕé ûþ ţö ðàţé~~~~~~⟧',
  'ck_uptodate.body[2].text': '⟦Ñéẋţ: ƒļû ṽàççîñé îñ Šéþ 2027. Ŵé’ļļ ŕéɱîñð ýöû à ɱöñţĥ ƀéƒöŕé.~~~~~~~~~~~~~~~~~~⟧',
  'ck_uptodate.body[3].label': '⟦Šéé ƒûļļ šçĥéðûļé~~~~~~⟧',
  'ck_item.body[0].text': '⟦Ýöûŕ öþţîöñš~~~~~⟧',
  'ck_item.body[1].text': '⟦Àļļ àŕé ŕéçöɱɱéñðéð. Ţàļķ ŵîţĥ ýöûŕ çļîñîçîàñ àƀöûţ ŵĥîçĥ ƒîţš.~~~~~~~~~~~~~~~~~~~~~⟧',
  'ck_item.body[2].rows[0][0]': '⟦Šţööļ ţéšţ (ƑÎŢ)~~~~~⟧',
  'ck_item.body[2].rows[0][1]': '⟦àţ ĥöɱé · ýéàŕļý~~~~~⟧',
  'ck_item.body[2].rows[1][0]': '⟦Šţööļ ÐÑÀ ţéšţ~~~~~⟧',
  'ck_item.body[2].rows[1][1]': '⟦àţ ĥöɱé · éṽéŕý 1–3 ýŕš~~~~~~⟧',
  'ck_item.body[2].rows[2][0]': '⟦Çöļöñöšçöþý~~~~~⟧',
  'ck_item.body[2].rows[2][1]': '⟦çļîñîç · éṽéŕý 10 ýŕš~~~~~~⟧',
  'ck_item.body[3].title': '⟦Çöšţ~~⟧',
  'ck_item.body[3].text': '⟦Šçŕééñîñĝ îš öƒţéñ çöṽéŕéð ŵîţĥ ñö çöšţ-šĥàŕîñĝ. Çĥéçķ ŵîţĥ ýöûŕ îñšûŕéŕ.~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'ck_item.body[4].text': '⟦Šöûŕçé: ÛŠÞŠŢƑ 2021 · ŕéṽîéŵéð Àûĝ 2026~~~~~~~~~~⟧',
  'ck_item.footer[0].label': '⟦Ṁéššàĝé ɱý çàŕé ţéàɱ~~~~~~~⟧',
  'ck_item.footer[1].label': '⟦Ṁàŕķ àš ðöñé~~~~⟧',
  'ck_item.header.title': '⟦Çöļöŕéçţàļ šçŕééñîñĝ~~~~~~~~⟧',
  'ck_done.body[0].label': '⟦Ŵĥàţ~~⟧',
  'ck_done.body[0].placeholder': '⟦Ƒļû ṽàççîñé~~~~⟧',
  'ck_done.body[1].label': '⟦Ðàţé~~⟧',
  'ck_done.body[1].placeholder': '⟦Öçţ 12, 2026~~⟧',
  'ck_done.body[2].label': '⟦Ŵĥéŕé (öþţîöñàļ)~~~~~~⟧',
  'ck_done.body[2].placeholder': '⟦Ṁàîñ Šţ Þĥàŕɱàçý~~~~~~⟧',
  'ck_done.body[3].items[0].label': '⟦Ŕéɱîñð ɱé ñéẋţ ýéàŕ~~~~~~~⟧',
  'ck_done.footer[0].action.then.value': '⟦Šàṽéð · ñéẋţ ðûé Šéþ 2027~~~~~~⟧',
  'ck_done.footer[0].label': '⟦Šàṽé~~⟧',
  'ck_done.header.title': '⟦Ṁàŕķ àš ðöñé~~~~⟧',
  'ck_day.body[0].text': '⟦Ṁàɱɱöĝŕàɱ ţöɱöŕŕöŵ àţ 9:30 ÀṀ~~~~~~~~~⟧',
  'ck_day.body[1].children[0].items[0].label': '⟦Šķîþ ðéöðöŕàñţ öŕ þöŵðéŕ~~~~~~~~~⟧',
  'ck_day.body[1].children[0].items[1].label': '⟦Ŵéàŕ à ţŵö-þîéçé öûţƒîţ~~~~~~~~⟧',
  'ck_day.body[1].children[0].items[2].label': '⟦Ɓŕîñĝ ÎÐ àñð îñšûŕàñçé çàŕð~~~~~~~~~~⟧',
  'ck_day.body[2].title': '⟦Ñéŕṽöûš?~~~⟧',
  'ck_day.body[2].text': '⟦Îţ’š çöɱɱöñ. Ţĥé šçàñ ţàķéš àƀöûţ 20 ɱîñûţéš.~~~~~~~~~~~~~~⟧',
  'ck_day.body[2].cta[0].label': '⟦2-ɱîñ ƀŕéàţĥîñĝ~~~~~⟧',
  'ck_day.footer[0].action.value': '⟦Àððéð ţö ýöûŕ çàļéñðàŕ~~~~~~~~⟧',
  'ck_day.footer[0].label': '⟦Àðð ţö çàļéñðàŕ~~~~~~⟧',
  'ck_day.footer[1].label': '⟦Ṁàŕķ àš ðöñé~~~~⟧',
  'ck_day.header.title': '⟦Šçŕééñîñĝ ðàý~~~~~⟧',
  'ck_day.header.pill': '⟦Ţöɱöŕŕöŵ~~~~⟧',
  'be_intro.body[0].extra': '⟦Çàñçéŕ~~~⟧',
  'be_intro.body[1].text': '⟦Ļöŵéŕ ýöûŕ ŕîšķ. Ķñöŵ ýöûŕ öþţîöñš.~~~~~~~~~~~~⟧',
  'be_intro.body[2].rows[0][0]': '⟦Ŕîšķ šţéþš~~~~⟧',
  'be_intro.body[2].rows[0][1]': '⟦šɱöķîñĝ, šûñ, àļçöĥöļ, àçţîṽîţý~~~~~~~~~~⟧',
  'be_intro.body[2].rows[1][0]': '⟦Šçŕééñîñĝ~~~~⟧',
  'be_intro.body[2].rows[1][1]': '⟦ļîñķéð ŵîţĥ Çĥéçķûþ~~~~~~~⟧',
  'be_intro.body[2].rows[2][0]': '⟦Ţŕéàţɱéñţ šûþþöŕţ~~~~~~~⟧',
  'be_intro.body[2].rows[2][1]': '⟦ǫûéšţîöñš, šîðé-éƒƒéçţ ðîàŕý~~~~~~~~~~⟧',
  'be_intro.footer[0].label': '⟦Šéţ ûþ Ɓéàçöñ~~~~~⟧',
  'be_intro.footer[1].action.then.value': '⟦Ɓéàçöñ àððéð àš Ļéàŕñ öñļý~~~~~~~~~⟧',
  'be_intro.footer[1].label': '⟦Àðð àš Ļéàŕñ öñļý~~~~~~⟧',
  'be_intro.header.pill': '⟦~1 ɱîñ/ŵééķ~~~⟧',
  'be_q1.body[1].text': '⟦Ŵĥîçĥ ƒîţš ýöû ƀéšţ?~~~~~~~⟧',
  'be_q1.body[2].items[0].label': '⟦Ļöŵéŕîñĝ ɱý ŕîšķ~~~~~~⟧',
  'be_q1.body[2].items[0].sub': '⟦Þŕéṽéñţîöñ àñð šçŕééñîñĝ~~~~~~~~~⟧',
  'be_q1.body[2].items[1].label': '⟦Ĝöîñĝ ţĥŕöûĝĥ ţŕéàţɱéñţ~~~~~~~~~⟧',
  'be_q1.body[2].items[1].sub': '⟦Šûþþöŕţ ƀéţŵééñ àþþöîñţɱéñţš~~~~~~~~~~~⟧',
  'be_q1.body[2].items[2].label': '⟦Àƒţéŕ ţŕéàţɱéñţ~~~~~~⟧',
  'be_q1.body[2].items[2].sub': '⟦Šûŕṽîṽöŕšĥîþ~~~~~⟧',
  'be_q1.body[2].items[3].label': '⟦Šûþþöŕţîñĝ šöɱéöñé~~~~~~~⟧',
  'be_q1.body[2].items[3].sub': '⟦Çàŕéĝîṽéŕ ŕéšöûŕçéš~~~~~~~~⟧',
  'be_q1.footer[0].label': '⟦Ñéẋţ~~⟧',
  'be_q1.header.title': '⟦Ŵĥéŕé àŕé ýöû?~~~~~⟧',
  'be_q1.header.pill': '⟦1 öƒ 2~⟧',
  'be_q2.body[1].text': '⟦Ĥàš à çļöšé ŕéļàţîṽé ĥàð çàñçéŕ?~~~~~~~~~~~⟧',
  'be_q2.body[2].options[0]': '⟦Ɓŕéàšţ~~~⟧',
  'be_q2.body[2].options[1]': '⟦Öṽàŕîàñ~~~⟧',
  'be_q2.body[2].options[2]': '⟦Çöļöŕéçţàļ~~~~⟧',
  'be_q2.body[2].options[3]': '⟦Þŕöšţàţé~~~~⟧',
  'be_q2.body[2].options[4]': '⟦Þàñçŕéàţîç~~~~⟧',
  'be_q2.body[2].options[5]': '⟦Ṁéļàñöɱà~~~~⟧',
  'be_q2.body[2].options[6]': '⟦Ñöñé~~⟧',
  'be_q2.body[2].options[7]': '⟦Ñöţ šûŕé~~~⟧',
  'be_q2.body[3].label': '⟦Ŕéļàţîṽé’š àĝé àţ ðîàĝñöšîš (îƒ ķñöŵñ)~~~~~~~~~~~~⟧',
  'be_q2.body[4].text': '⟦À ŕéļàţîṽé ðîàĝñöšéð ƀéƒöŕé 50 ɱàý ɱéàñ éàŕļîéŕ šçŕééñîñĝ öŕ ĝéñéţîç çöûñšéļîñĝ. Ŵé’ļļ àðð ţĥîš ţö ýöûŕ ṽîšîţ ļîšţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'be_q2.footer[0].label': '⟦Šéé ɱý þļàñ~~~~⟧',
  'be_q2.header.title': '⟦Ƒàɱîļý ĥîšţöŕý~~~~~~⟧',
  'be_q2.header.pill': '⟦2 öƒ 2~⟧',
  'be_home.body[0].text': '⟦Ţĥŕéé šţéþš ţĥàţ ļöŵéŕ ŕîšķ~~~~~~~~~~⟧',
  'be_home.body[1].rows[0].label': '⟦Ǫûîţţîñĝ šɱöķîñĝ~~~~~~⟧',
  'be_home.body[1].rows[0].sub': '⟦Îñ þŕöĝŕéšš ŵîţĥ ƁŕéàţĥéƑŕéé~~~~~~~~~~⟧',
  'be_home.body[1].rows[0].pill': '⟦Àçţîṽé~~~⟧',
  'be_home.body[1].rows[1].label': '⟦Ṁöñţĥļý šķîñ šéļƒ-çĥéçķ~~~~~~~~⟧',
  'be_home.body[1].rows[1].sub': '⟦Ĝûîðé ŵîţĥ þĥöţöš~~~~~~⟧',
  'be_home.body[1].rows[2].label': '⟦Àšķ àƀöûţ ĝéñéţîç çöûñšéļîñĝ~~~~~~~~~~⟧',
  'be_home.body[1].rows[2].sub': '⟦Ɓéçàûšé öƒ ƒàɱîļý ĥîšţöŕý~~~~~~~~~⟧',
  'be_home.body[2].title': '⟦Šçŕééñîñĝš çöɱé ƒŕöɱ Çĥéçķûþ~~~~~~~~~~⟧',
  'be_home.body[2].text': '⟦Ṁàɱɱöĝŕàɱ ðûé · çöļöŕéçţàļ ðûé~~~~~~~~~~⟧',
  'be_home.body[2].cta[0].label': '⟦Öþéñ Çĥéçķûþ~~~~~⟧',
  'be_home.body[3].rows[0].label': '⟦Çĥàñĝé ɱý ĵöûŕñéý šţàĝé~~~~~~~~⟧',
  'be_home.body[3].rows[1].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'be_home.body[3].rows[1].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'be_tx.body[0].eyebrow': '⟦Ñéẋţ àþþöîñţɱéñţ~~~~~~⟧',
  'be_tx.body[0].title': '⟦Öçţ 22 · Öñçöļöĝý · 10:30 ÀṀ~~~~~~⟧',
  'be_tx.body[0].cta[0].label': '⟦Ǫûéšţîöñš~~~~⟧',
  'be_tx.body[1].title': '⟦Ƒéṽéŕ öƒ 100.4°Ƒ (38°Ç) öŕ ĥîĝĥéŕ ðûŕîñĝ çĥéɱö?~~~~~~~~~~~~⟧',
  'be_tx.body[1].text': '⟦Çàļļ ýöûŕ öñçöļöĝý ţéàɱ ñöŵ, ðàý öŕ ñîĝĥţ.~~~~~~~~~~~~~~⟧',
  'be_tx.body[1].cta[0].label': '⟦Çàļļ~~⟧',
  'be_tx.body[2].rows[0].label': '⟦Ţöðàý’š šîðé-éƒƒéçţ ðîàŕý~~~~~~~~~⟧',
  'be_tx.body[2].rows[0].sub': '⟦Àƀöûţ 1 ɱîñûţé~~~~~⟧',
  'be_tx.body[2].rows[1].label': '⟦Ƒééļîñĝ ŵöŕŕîéð?~~~~~~⟧',
  'be_tx.body[2].rows[1].sub': '⟦Ţööļš îñ Éàšé~~~~~⟧',
  'be_tx.body[2].rows[2].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'be_tx.body[2].rows[2].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'be_diary.body[0].text': '⟦Ĥöŵ àŕé ýöû ƒééļîñĝ ţöðàý?~~~~~~~~~⟧',
  'be_diary.body[1].label': '⟦Ƒàţîĝûé~~~⟧',
  'be_diary.body[2].options[0]': '⟦Ñàûšéà~~~⟧',
  'be_diary.body[2].options[1]': '⟦Þàîñ~~⟧',
  'be_diary.body[2].options[2]': '⟦Ṁöûţĥ šöŕéš~~~~⟧',
  'be_diary.body[2].options[3]': '⟦Ñûɱƀñéšš~~~~⟧',
  'be_diary.body[2].options[4]': '⟦Ļöŵ ɱööð~~~⟧',
  'be_diary.body[2].label': '⟦Àñýţĥîñĝ éļšé?~~~~~⟧',
  'be_diary.body[3].title': '⟦Ƒéṽéŕ öƒ 100.4°Ƒ (38°Ç) öŕ ĥîĝĥéŕ?~~~~~~~⟧',
  'be_diary.body[3].text': '⟦Çàļļ ýöûŕ öñçöļöĝý ţéàɱ ñöŵ.~~~~~~~~~~⟧',
  'be_diary.body[3].cta[0].label': '⟦Çàļļ~~⟧',
  'be_diary.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'be_diary.footer[0].label': '⟦Šàṽé~~⟧',
  'be_diary.header.title': '⟦Ţŕéàţɱéñţ ðîàŕý~~~~~~⟧',
  'be_diary.header.pill': '⟦Ţŕéàţɱéñţ~~~~⟧',
  'be_questions.body[0].children[0].items[0].label': '⟦Ŵĥàţ šîðé éƒƒéçţš šĥöûļð Î çàļļ àƀöûţ?~~~~~~~~~~~~~⟧',
  'be_questions.body[0].children[0].items[1].label': '⟦Çàñ Î ķééþ ŵöŕķîñĝ ðûŕîñĝ ţŕéàţɱéñţ?~~~~~~~~~~~~⟧',
  'be_questions.body[0].children[0].items[2].label': '⟦Ŵĥö ðö Î çàļļ àƒţéŕ ĥöûŕš?~~~~~~~~⟧',
  'be_questions.body[1].label': '⟦Àðð à ǫûéšţîöñ~~~~~⟧',
  'be_questions.body[1].placeholder': '⟦Ţýþé à ǫûéšţîöñ…~~~~~~⟧',
  'be_questions.footer[0].label': '⟦Šĥàŕé ŵîţĥ ɱý çàŕé ţéàɱ~~~~~~~~⟧',
  'be_questions.footer[1].label': '⟦Ðöñé~~⟧',
  'be_questions.header.title': '⟦Ǫûéšţîöñš ƒöŕ ɱý ṽîšîţ~~~~~~~~⟧',
  'be_questions.header.pill': '⟦Öçţ 22~~⟧',
  'be_survivor.body[0].text': '⟦Ĥöŵ ĥàṽé ţĥé ļàšţ 3 ɱöñţĥš ƀééñ?~~~~~~~~~~⟧',
  'be_survivor.body[1].options[0]': '⟦Ĥàŕð~~⟧',
  'be_survivor.body[1].options[1]': '⟦Ṁîẋéð~~⟧',
  'be_survivor.body[1].options[2]': '⟦Ĝööð~~⟧',
  'be_survivor.body[2].title': '⟦Ŵöŕŕîéð àƀöûţ îţ çöɱîñĝ ƀàçķ?~~~~~~~~~~⟧',
  'be_survivor.body[2].text': '⟦Ṽéŕý çöɱɱöñ. Éàšé ĥàš ţööļš ƒöŕ ţĥîš, àñð ýöûŕ ţéàɱ çàñ ĥéļþ.~~~~~~~~~~~~~~~~~~~⟧',
  'be_survivor.body[2].cta[0].label': '⟦Öþéñ Éàšé~~~~⟧',
  'be_survivor.body[3].rows[0][0]': '⟦Ñéẋţ ƒöļļöŵ-ûþ~~~~~⟧',
  'be_survivor.body[3].rows[0][1]': '⟦Ĵàñ 14, 2027~~⟧',
  'be_survivor.body[4].rows[0].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'be_survivor.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'be_survivor.footer[0].label': '⟦Šàṽé çĥéçķ-îñ~~~~~⟧',
  'records_hub.body[0].text': '⟦Ŕéàð-öñļý. Ţéţĥéŕ ñéṽéŕ ŵŕîţéš ţö ýöûŕ ĥéàļţĥ ŕéçöŕð, àñð éàçĥ þŕöĝŕàɱ öñļý ĝéţš ţĥé ðàţà îţ ñééðš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_hub.body[1].rows[0].label': '⟦Þàţéļ Ƒàɱîļý Ṁéðîçîñé~~~~~~~~⟧',
  'records_hub.body[1].rows[0].sub': '⟦Éþîç ṀýÇĥàŕţ · šýñçéð ţöðàý 7:02 ÀṀ~~~~~~~~~~⟧',
  'records_hub.body[1].rows[1].sub': '⟦Ɓļûé Ɓûţţöñ 2.0 · šýñçéð Öçţ 12~~~~~~~~⟧',
  'records_hub.body[1].title': '⟦Çöññéçţéð šöûŕçéš~~~~~~~⟧',
  'records_hub.body[2].rows[0].label': '⟦Ɓļööð þŕéššûŕé~~~~~~⟧',
  'records_hub.body[2].rows[0].sub': '⟦12 ŕéàðîñĝš · Ĥéàŕţŵîšé~~~~~~~⟧',
  'records_hub.body[2].rows[1].label': '⟦Ļàƀ ŕéšûļţš~~~~⟧',
  'records_hub.body[2].rows[1].sub': '⟦À1Ç, ļîþîðš, éĜƑŔ · Šţéàðý, Ĥéàŕţŵîšé, Ŕéñéŵ~~~~~~~~~~~~~⟧',
  'records_hub.body[2].rows[2].label': '⟦Îɱɱûñîžàţîöñš~~~~~~⟧',
  'records_hub.body[2].rows[2].sub': '⟦6 · Çĥéçķûþ~~~⟧',
  'records_hub.body[2].rows[3].label': '⟦Šɱöķîñĝ šţàţûš~~~~~~⟧',
  'records_hub.body[2].rows[3].sub': '⟦Éṽéŕý ðàý šɱöķéŕ (Àûĝ 2026) · ƁŕéàţĥéƑŕéé~~~~~~~~~~~~⟧',
  'records_hub.body[2].rows[4].label': '⟦Ṁéðîçàţîöñš & çöñðîţîöñš~~~~~~~~~⟧',
  'records_hub.body[2].rows[4].sub': '⟦Šĥöŵñ ƒöŕ ŕéƒéŕéñçé öñļý~~~~~~~~~⟧',
  'records_hub.body[2].title': '⟦Îɱþöŕţéð ðàţà~~~~~⟧',
  'records_hub.body[3].title': '⟦2 îţéɱš ñééð ýöûŕ ŕéṽîéŵ~~~~~~~~⟧',
  'records_hub.body[3].text': '⟦À ṽàļûé ţĥàţ ðîƒƒéŕš ƒŕöɱ ŵĥàţ ýöû éñţéŕéð, àñð öñé ţĥàţ ļööķš ļîķé à ţýþö.~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_hub.footer[0].label': '⟦Àðð à šöûŕçé~~~~⟧',
  'records_hub.footer[1].label': '⟦Éñţéŕ à ṽàļûé ɱàñûàļļý~~~~~~~~⟧',
  'records_hub.header.title': '⟦Ĥéàļţĥ ŕéçöŕðš~~~~~~⟧',
  'records_hub_empty.body[1].text': '⟦Ñö ĥéàļţĥ ŕéçöŕðš çöññéçţéð~~~~~~~~~~⟧',
  'records_hub_empty.body[2].text': '⟦Ɓŕîñĝ îñ ŕéàðîñĝš, ļàƀš àñð ṽàççîñàţîöñš ƒŕöɱ ýöûŕ çļîñîç öŕ Ṁéðîçàŕé, öŕ ţýþé ţĥéɱ îñ. Ýöûŕ þŕöĝŕàɱš ŵöŕķ éîţĥéŕ ŵàý.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_hub_empty.body[3].rows[0][1]': '⟦ɱöšţ ÛŠ ĥöšþîţàļš àñð çļîñîçš~~~~~~~~~~⟧',
  'records_hub_empty.body[3].rows[1][1]': '⟦Ɓļûé Ɓûţţöñ 2.0~~~~⟧',
  'records_hub_empty.body[3].rows[2][0]': '⟦Öţĥéŕ~~⟧',
  'records_hub_empty.body[3].rows[2][1]': '⟦àñý ŠṀÀŔŢ öñ ƑĤÎŔ Ŕ4 šéŕṽéŕ~~~~~~~~~⟧',
  'records_hub_empty.footer[0].label': '⟦Çöññéçţ à ĥéàļţĥ šýšţéɱ~~~~~~~~⟧',
  'records_hub_empty.footer[1].label': '⟦Éñţéŕ à ṽàļûé ɱàñûàļļý~~~~~~~~⟧',
  'records_hub_empty.header.title': '⟦Ĥéàļţĥ ŕéçöŕðš~~~~~~⟧',
  'records_add.body[0].text': '⟦Ŵĥéŕé îš ýöûŕ ĥéàļţĥ îñƒöŕɱàţîöñ?~~~~~~~~~~~~⟧',
  'records_add.body[1].text': '⟦Ýöû šîĝñ îñ ŵîţĥ ýöûŕ þŕöṽîðéŕ. Ţéţĥéŕ ñéṽéŕ šééš ţĥàţ þàššŵöŕð.~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_add.body[2].rows[0].label': '⟦Ĥöšþîţàļ öŕ çļîñîç~~~~~~~⟧',
  'records_add.body[2].rows[0].sub': '⟦Éþîç ṀýÇĥàŕţ · ƒîñð ýöûŕš~~~~~~~~⟧',
  'records_add.body[2].rows[1].sub': '⟦Þàţîéñţ þöŕţàļ~~~~~~⟧',
  'records_add.body[2].rows[2].label': '⟦Ṁéðîçàŕé · Ɓļûé Ɓûţţöñ 2.0~~~~~~~~⟧',
  'records_add.body[2].rows[2].sub': '⟦Çļàîɱš, þŕéšçŕîþţîöñš, ðîàĝñöšéš~~~~~~~~~~~~⟧',
  'records_add.body[2].rows[3].sub': '⟦îÞĥöñé · ŕéçöŕðš ýöû àļŕéàðý àððéð ţö Ĥéàļţĥ~~~~~~~~~~~~~~~⟧',
  'records_add.body[2].rows[4].sub': '⟦Àñðŕöîð · ŕéàðîñĝš ƒŕöɱ ýöûŕ ðéṽîçéš~~~~~~~~~~~~⟧',
  'records_add.body[2].rows[5].label': '⟦Öţĥéŕ ƑĤÎŔ šéŕṽéŕ~~~~~~⟧',
  'records_add.body[2].rows[5].sub': '⟦Éñţéŕ ţĥé àððŕéšš ýöûŕ þŕöṽîðéŕ ĝàṽé ýöû~~~~~~~~~~~~~~⟧',
  'records_add.body[2].title': '⟦Çöññéçţ~~~⟧',
  'records_add.body[3].rows[0].label': '⟦Éñţéŕ ɱàñûàļļý~~~~~~⟧',
  'records_add.body[3].rows[0].sub': '⟦Ţýþé à ṽàļûé ƒŕöɱ à þàþéŕ ŕéþöŕţ~~~~~~~~~~~⟧',
  'records_add.body[3].title': '⟦Öŕ~⟧',
  'records_add.body[4].text': '⟦Ûšéš ŠṀÀŔŢ öñ ƑĤÎŔ Ŕ4 ŵîţĥ ÖÀûţĥ 2.0 + ÞĶÇÉ îñ ýöûŕ þĥöñé’š ƀŕöŵšéŕ.~~~~~~~~~~~~~~~~~~~~⟧',
  'records_add.header.title': '⟦Àðð à šöûŕçé~~~~⟧',
  'records_search.body[0].label': '⟦Šéàŕçĥ~~~⟧',
  'records_search.body[0].placeholder': '⟦Šéàŕçĥ ĥöšþîţàļ, çļîñîç öŕ ðöçţöŕ~~~~~~~~~~~~⟧',
  'records_search.body[1].rows[0].label': '⟦Þàţéļ Ƒàɱîļý Ṁéðîçîñé~~~~~~~~⟧',
  'records_search.body[1].rows[0].sub': '⟦Éþîç · Šàñ Ĵöšé, ÇÀ~~~~~~⟧',
  'records_search.body[1].rows[1].label': '⟦Þàţéļ Ĥéàŕţ Îñšţîţûţé~~~~~~~~⟧',
  'records_search.body[1].rows[1].sub': '⟦Éþîç · Ƒŕéɱöñţ, ÇÀ~~~~~~⟧',
  'records_search.body[1].rows[2].label': '⟦Šţàñƒöŕð Ĥéàļţĥ Çàŕé~~~~~~~~⟧',
  'records_search.body[1].rows[2].sub': '⟦Éþîç · Þàļö Àļţö, ÇÀ~~~~~~⟧',
  'records_search.body[1].title': '⟦Ŕéšûļţš~~~⟧',
  'records_search.body[2].label': '⟦Çàñ’ţ ƒîñð îţ? Éñţéŕ à ƑĤÎŔ àððŕéšš~~~~~~~~~~~⟧',
  'records_search.header.title': '⟦Ƒîñð ýöûŕ þŕöṽîðéŕ~~~~~~~⟧',
  'records_fhir_url.body[0].text': '⟦Éñţéŕ ýöûŕ þŕöṽîðéŕ’š ƑĤÎŔ àððŕéšš~~~~~~~~~~~~⟧',
  'records_fhir_url.body[1].label': '⟦ƑĤÎŔ šéŕṽéŕ àððŕéšš~~~~~~~⟧',
  'records_fhir_url.body[1].hint': '⟦Šţàŕţš ŵîţĥ ĥţţþš:// · ýöûŕ þŕöṽîðéŕ ĝîṽéš ýöû ţĥîš~~~~~~~~~~~~~~~~⟧',
  'records_fhir_url.body[2].text': '⟦Ŵé çĥéçķ îţ šûþþöŕţš ŠṀÀŔŢ öñ ƑĤÎŔ Ŕ4 (/.ŵéļļ-ķñöŵñ/šɱàŕţ-çöñƒîĝûŕàţîöñ) ƀéƒöŕé ýöû šîĝñ îñ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_fhir_url.footer[0].label': '⟦Çĥéçķ àñð çöñţîñûé~~~~~~~⟧',
  'records_fhir_url.header.title': '⟦Öţĥéŕ ƑĤÎŔ šéŕṽéŕ~~~~~~⟧',
  'records_consent.body[0].text': '⟦Çöññéçţ Þàţéļ Ƒàɱîļý Ṁéðîçîñé?~~~~~~~~~~~⟧',
  'records_consent.body[1].rows[0][0]': '⟦Šöûŕçé~~~⟧',
  'records_consent.body[1].rows[0][1]': '⟦Éþîç ṀýÇĥàŕţ · ŠṀÀŔŢ öñ ƑĤÎŔ Ŕ4~~~~~~~~~~⟧',
  'records_consent.body[1].rows[1][0]': '⟦Àççéšš~~~⟧',
  'records_consent.body[1].rows[1][1]': '⟦Ŕéàð-öñļý~~~~⟧',
  'records_consent.body[1].rows[2][0]': '⟦Ŕéƒŕéšĥ~~~⟧',
  'records_consent.body[1].rows[2][1]': '⟦Ðàîļý ŵĥîļé çöññéçţéð~~~~~~~~⟧',
  'records_consent.body[1].rows[3][0]': '⟦Šţöþ~~⟧',
  'records_consent.body[1].rows[3][1]': '⟦Ðîšçöññéçţ àñýţîɱé~~~~~~~⟧',
  'records_consent.body[2].items[0].label': '⟦Çöñðîţîöñš~~~~⟧',
  'records_consent.body[2].items[0].sub': '⟦Çöñðîţîöñ~~~~⟧',
  'records_consent.body[2].items[1].label': '⟦Ṽîţàļ šîĝñš~~~~⟧',
  'records_consent.body[2].items[1].sub': '⟦Öƀšéŕṽàţîöñ · ƀļööð þŕéššûŕé, ŵéîĝĥţ~~~~~~~~~~~~⟧',
  'records_consent.body[2].items[2].label': '⟦Ļàƀ ŕéšûļţš~~~~⟧',
  'records_consent.body[2].items[2].sub': '⟦Öƀšéŕṽàţîöñ · À1Ç, ļîþîðš, éĜƑŔ~~~~~~~~~~⟧',
  'records_consent.body[2].items[3].label': '⟦Ṁéðîçàţîöñš~~~~~⟧',
  'records_consent.body[2].items[3].sub': '⟦ṀéðîçàţîöñŔéǫûéšţ~~~~~~~⟧',
  'records_consent.body[2].items[4].label': '⟦Îɱɱûñîžàţîöñš~~~~~~⟧',
  'records_consent.body[2].items[4].sub': '⟦Îɱɱûñîžàţîöñ~~~~~⟧',
  'records_consent.body[2].items[5].label': '⟦Šɱöķîñĝ šţàţûš~~~~~~⟧',
  'records_consent.body[2].items[5].sub': '⟦Öƀšéŕṽàţîöñ · ĻÖÎÑÇ 72166-2~~~~~~~⟧',
  'records_consent.body[2].label': '⟦Ŵĥàţ Ţéţĥéŕ ŵîļļ ŕéàð~~~~~~~~⟧',
  'records_consent.body[3].rows[0].label': '⟦Çļîñîçàļ ñöţéš~~~~~~⟧',
  'records_consent.body[3].rows[0].sub': '⟦Ñöţ ŕéǫûéšţéð~~~~~⟧',
  'records_consent.body[4].title': '⟦Öñļý ţĥé þŕöĝŕàɱš ýöû ĵöîñéð ĝéţ ðàţà~~~~~~~~~~~~~⟧',
  'records_consent.body[4].text': '⟦Ĥéàŕţŵîšé ← ƀļööð þŕéššûŕé, ļîþîðš · Šţéàðý ← À1Ç, ĝļûçöšé · Ŕéñéŵ ← éĜƑŔ · Çĥéçķûþ ← îɱɱûñîžàţîöñš · ƁŕéàţĥéƑŕéé ← šɱöķîñĝ šţàţûš. Éàšé àñð ŠçŕöļļƑŕéé ĝéţ ñöţĥîñĝ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_consent.footer[0].action.cases[0].action.cases[1].action.value': '⟦Çöññéçţîöñ çàñçéļļéð. Ñöţĥîñĝ ŵàš îɱþöŕţéð.~~~~~~~~~~~~~~~⟧',
  'records_consent.footer[0].action.cases[1].action.value': '⟦Šéļéçţ àţ ļéàšţ öñé îţéɱ ţö çöñţîñûé.~~~~~~~~~~~~⟧',
  'records_consent.footer[0].label': '⟦Çöñţîñûé ţö ṀýÇĥàŕţ~~~~~~~⟧',
  'records_consent.footer[1].label': '⟦Ñöţ ñöŵ~~~⟧',
  'records_consent.header.title': '⟦Çöññéçţ~~~⟧',
  'records_consent.header.pill': '⟦Ŕéàð-öñļý~~~~⟧',
  'records_consent_bb.body[0].text': '⟦Çöññéçţ Ṁéðîçàŕé?~~~~~~⟧',
  'records_consent_bb.body[1].rows[0][0]': '⟦Šöûŕçé~~~⟧',
  'records_consent_bb.body[1].rows[0][1]': '⟦ÇṀŠ Ɓļûé Ɓûţţöñ 2.0 · ƑĤÎŔ Ŕ4 (çļàîɱš)~~~~~~~~~~⟧',
  'records_consent_bb.body[1].rows[1][0]': '⟦Àççéšš~~~⟧',
  'records_consent_bb.body[1].rows[1][1]': '⟦Ŕéàð-öñļý~~~~⟧',
  'records_consent_bb.body[1].rows[2][0]': '⟦Ŕéƒŕéšĥ~~~⟧',
  'records_consent_bb.body[1].rows[2][1]': '⟦Ðàîļý ŵĥîļé çöññéçţéð~~~~~~~~⟧',
  'records_consent_bb.body[1].rows[3][0]': '⟦Šţöþ~~⟧',
  'records_consent_bb.body[1].rows[3][1]': '⟦Ðîšçöññéçţ àñýţîɱé~~~~~~~⟧',
  'records_consent_bb.body[2].items[0].label': '⟦Çöñðîţîöñš~~~~⟧',
  'records_consent_bb.body[2].items[0].sub': '⟦Çöñðîţîöñ~~~~⟧',
  'records_consent_bb.body[2].items[1].label': '⟦Ṽîţàļ šîĝñš~~~~⟧',
  'records_consent_bb.body[2].items[1].sub': '⟦Öƀšéŕṽàţîöñ · ƀļööð þŕéššûŕé, ŵéîĝĥţ~~~~~~~~~~~~⟧',
  'records_consent_bb.body[2].items[2].label': '⟦Ļàƀ ŕéšûļţš~~~~⟧',
  'records_consent_bb.body[2].items[2].sub': '⟦Öƀšéŕṽàţîöñ · À1Ç, ļîþîðš, éĜƑŔ~~~~~~~~~~⟧',
  'records_consent_bb.body[2].items[3].label': '⟦Ṁéðîçàţîöñš~~~~~⟧',
  'records_consent_bb.body[2].items[3].sub': '⟦ṀéðîçàţîöñŔéǫûéšţ~~~~~~~⟧',
  'records_consent_bb.body[2].items[4].label': '⟦Îɱɱûñîžàţîöñš~~~~~~⟧',
  'records_consent_bb.body[2].items[4].sub': '⟦Îɱɱûñîžàţîöñ~~~~~⟧',
  'records_consent_bb.body[2].items[5].label': '⟦Šɱöķîñĝ šţàţûš~~~~~~⟧',
  'records_consent_bb.body[2].items[5].sub': '⟦Öƀšéŕṽàţîöñ · ĻÖÎÑÇ 72166-2~~~~~~~⟧',
  'records_consent_bb.body[2].label': '⟦Ŵĥàţ Ţéţĥéŕ ŵîļļ ŕéàð~~~~~~~~⟧',
  'records_consent_bb.body[3].rows[0].label': '⟦Çļîñîçàļ ñöţéš~~~~~~⟧',
  'records_consent_bb.body[3].rows[0].sub': '⟦Ñöţ ŕéǫûéšţéð~~~~~⟧',
  'records_consent_bb.body[4].title': '⟦Öñļý ţĥé þŕöĝŕàɱš ýöû ĵöîñéð ĝéţ ðàţà~~~~~~~~~~~~~⟧',
  'records_consent_bb.body[4].text': '⟦Ĥéàŕţŵîšé ← ƀļööð þŕéššûŕé, ļîþîðš · Šţéàðý ← À1Ç, ĝļûçöšé · Ŕéñéŵ ← éĜƑŔ · Çĥéçķûþ ← îɱɱûñîžàţîöñš · ƁŕéàţĥéƑŕéé ← šɱöķîñĝ šţàţûš. Éàšé àñð ŠçŕöļļƑŕéé ĝéţ ñöţĥîñĝ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_consent_bb.footer[0].action.cases[0].action.cases[1].action.value': '⟦Çöññéçţîöñ çàñçéļļéð. Ñöţĥîñĝ ŵàš îɱþöŕţéð.~~~~~~~~~~~~~~~⟧',
  'records_consent_bb.footer[0].action.cases[1].action.value': '⟦Šéļéçţ àţ ļéàšţ öñé îţéɱ ţö çöñţîñûé.~~~~~~~~~~~~⟧',
  'records_consent_bb.footer[0].label': '⟦Çöñţîñûé ţö Ṁéðîçàŕé.ĝöṽ~~~~~~~~~⟧',
  'records_consent_bb.footer[1].label': '⟦Ñöţ ñöŵ~~~⟧',
  'records_consent_bb.header.title': '⟦Çöññéçţ~~~⟧',
  'records_consent_bb.header.pill': '⟦Ŕéàð-öñļý~~~~⟧',
  'records_consent_device.body[0].text': '⟦Ûšé ĥéàļţĥ ðàţà öñ ţĥîš þĥöñé?~~~~~~~~~~⟧',
  'records_consent_device.body[1].text': '⟦îÞĥöñé: Àþþļé Ĥéàļţĥ Ŕéçöŕðš (ƑĤÎŔ) àñð ŕéàðîñĝš. Àñðŕöîð: Ĥéàļţĥ Çöññéçţ ŕéàðîñĝš. Ýöû çĥööšé éàçĥ ţýþé îñ ţĥé šýšţéɱ šçŕééñ ñéẋţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_consent_device.body[2].items[0].label': '⟦Ɓļööð þŕéššûŕé~~~~~~⟧',
  'records_consent_device.body[2].items[1].label': '⟦Ɓļööð ĝļûçöšé~~~~~⟧',
  'records_consent_device.body[2].items[2].label': '⟦Çļîñîçàļ ŕéçöŕðš (îÞĥöñé)~~~~~~~~~⟧',
  'records_consent_device.body[2].items[2].sub': '⟦Ļàƀš, îɱɱûñîžàţîöñš, çöñðîţîöñš~~~~~~~~~~~⟧',
  'records_consent_device.body[2].label': '⟦Ŵĥàţ Ţéţĥéŕ ŵîļļ àšķ ƒöŕ~~~~~~~~⟧',
  'records_consent_device.body[3].rows[0].label': '⟦Šţéþš àñð šļééþ~~~~~~⟧',
  'records_consent_device.body[3].rows[0].sub': '⟦Ñöţ ŕéǫûéšţéð~~~~~⟧',
  'records_consent_device.footer[0].action.cases[1].action.value': '⟦Šéļéçţ àţ ļéàšţ öñé îţéɱ ţö çöñţîñûé.~~~~~~~~~~~~⟧',
  'records_consent_device.footer[0].label': '⟦Çöñţîñûé~~~~⟧',
  'records_consent_device.footer[1].label': '⟦Ñöţ ñöŵ~~~⟧',
  'records_consent_device.header.title': '⟦Çöññéçţ~~~⟧',
  'records_consent_device.header.pill': '⟦Ŕéàð-öñļý~~~~⟧',
  'records_importing.body[0].text': '⟦Îɱþöŕţîñĝ ýöûŕ ŕéçöŕðš…~~~~~~~~⟧',
  'records_importing.body[1].text': '⟦Ûšûàļļý ûñðéŕ à ɱîñûţé. Ýöû çàñ ļéàṽé ţĥîš šçŕééñ.~~~~~~~~~~~~~~~~⟧',
  'records_importing.body[2].children[0].items[0].label': '⟦Çöñðîţîöñš~~~~⟧',
  'records_importing.body[2].children[0].items[0].sub': '⟦4 ƒöûñð~~⟧',
  'records_importing.body[2].children[0].items[1].label': '⟦Ṽîţàļ šîĝñš~~~~⟧',
  'records_importing.body[2].children[0].items[1].sub': '⟦12 ƀļööð þŕéššûŕé ŕéàðîñĝš~~~~~~~~~⟧',
  'records_importing.body[2].children[0].items[2].label': '⟦Ļàƀ ŕéšûļţš~~~~⟧',
  'records_importing.body[2].children[0].items[2].sub': '⟦9 ŕéšûļţš~~~⟧',
  'records_importing.body[2].children[0].items[3].label': '⟦Îɱɱûñîžàţîöñš~~~~~~⟧',
  'records_importing.body[2].children[0].items[3].sub': '⟦Çĥéçķîñĝ…~~~~⟧',
  'records_importing.body[2].children[0].items[4].label': '⟦Šɱöķîñĝ šţàţûš~~~~~~⟧',
  'records_importing.body[2].children[0].items[4].sub': '⟦Ŵàîţîñĝ~~~⟧',
  'records_importing.footer[0].label': '⟦Ŕéṽîéŵ îɱþöŕţéð ðàţà~~~~~~~~⟧',
  'records_importing.footer[1].label': '⟦Çàñçéļ îɱþöŕţ~~~~~⟧',
  'records_importing.header.title': '⟦Îɱþöŕţîñĝ~~~~⟧',
  'records_review.body[0].text': '⟦Ŕéṽîéŵ ƀéƒöŕé àððîñĝ~~~~~~~~⟧',
  'records_review.body[1].text': '⟦Ñöţĥîñĝ ŕéàçĥéš ýöûŕ þŕöĝŕàɱš ûñţîļ ýöû çöñƒîŕɱ.~~~~~~~~~~~~~~~~~⟧',
  'records_review.body[2].text': '⟦2 îţéɱš ñééð ýöûŕ ŕéṽîéŵ.~~~~~~~~⟧',
  'records_review.body[2].actionLabel': '⟦Ŕéṽîéŵ~~~⟧',
  'records_review.body[3].children[0].items[0].label': '⟦12 ƀļööð þŕéššûŕé ŕéàðîñĝš~~~~~~~~~⟧',
  'records_review.body[3].children[0].items[0].sub': '⟦Ĵûñ – Öçţ 2026~~~⟧',
  'records_review.body[3].children[0].items[1].label': '⟦Ļîþîð þàñéļ~~~~⟧',
  'records_review.body[3].children[0].items[1].sub': '⟦ĻÐĻ 138 · Šéþ 30~~~⟧',
  'records_review.body[4].children[0].items[0].label': '⟦À1Ç 7.6%~⟧',
  'records_review.body[4].children[0].items[0].sub': '⟦Öçţ 1 · ðîƒƒéŕš ƒŕöɱ ýöûŕ éñţŕý (7.4%)~~~~~~~~~~⟧',
  'records_review.body[5].children[0].items[0].label': '⟦Ƒļû ṽàççîñé~~~~⟧',
  'records_review.body[5].children[0].items[0].sub': '⟦Öçţ 12, 2025~~⟧',
  'records_review.body[5].children[0].items[1].label': '⟦Ţðàþ~~⟧',
  'records_review.body[6].children[0].items[0].label': '⟦Šɱöķîñĝ šţàţûš: éṽéŕý ðàý šɱöķéŕ~~~~~~~~~~~⟧',
  'records_review.body[6].children[0].items[0].sub': '⟦Àûĝ 2026 · šéţš ýöûŕ ƀàšéļîñé~~~~~~~~⟧',
  'records_review.body[7].children[0].items[0].label': '⟦éĜƑŔ 58~~⟧',
  'records_review.body[7].children[0].items[0].sub': '⟦Öçţ 3~~⟧',
  'records_review.body[8].text': '⟦Çĥéçķéð àûţöɱàţîçàļļý~~~~~~~~⟧',
  'records_review.body[9].rows[0][0]': '⟦Ûñîţš çöñṽéŕţéð~~~~~~⟧',
  'records_review.body[9].rows[0][1]': '⟦2 ĝļûçöšé ŕéšûļţš · ɱɱöļ/Ļ → ɱĝ/ðĻ~~~~~~~~~~⟧',
  'records_review.body[9].rows[1][0]': '⟦Ðûþļîçàţéš šķîþþéð~~~~~~~⟧',
  'records_review.body[9].rows[1][1]': '⟦3 ŕéàðîñĝš ýöû àļŕéàðý éñţéŕéð~~~~~~~~~~⟧',
  'records_review.body[9].rows[2][0]': '⟦Ĥéļð àš ļîķéļý ţýþö~~~~~~~⟧',
  'records_review.body[9].rows[2][1]': '⟦1 · ƁÞ 1290/80~⟧',
  'records_review.body[9].rows[3][0]': '⟦Ƒûţûŕé ðàţéš ŕéĵéçţéð~~~~~~~~⟧',
  'records_review.footer[0].action.cases[0].action.then.value': '⟦Àððéð ţö ýöûŕ þŕöĝŕàɱš~~~~~~~~⟧',
  'records_review.footer[0].action.cases[1].action.value': '⟦Šéļéçţ ţĥé îţéɱš ýöû ŵàñţ ţö àðð.~~~~~~~~~~~⟧',
  'records_review.footer[0].label': '⟦Àðð šéļéçţéð îţéɱš ţö ɱý þŕöĝŕàɱš~~~~~~~~~~~~⟧',
  'records_review.footer[1].label': '⟦Ŕéṽîéŵ çöñƒļîçţš ƒîŕšţ~~~~~~~~⟧',
  'records_review.header.title': '⟦Ŕéṽîéŵ~~~⟧',
  'records_review.header.pill': '⟦Ñöţ àððéð ýéţ~~~~~⟧',
  'records_conflict.body[0].eyebrow': '⟦À1Ç · Öçţ 1, 2026~~⟧',
  'records_conflict.body[0].title': '⟦Ţŵö ṽàļûéš ƒöŕ ţĥé šàɱé ţéšţ~~~~~~~~~~⟧',
  'records_conflict.body[0].children[0].items[0].label': '⟦Ƒŕöɱ Þàţéļ Ƒàɱîļý Ṁéðîçîñé (Éþîç): 7.6%~~~~~~~~~~~⟧',
  'records_conflict.body[0].children[0].items[0].sub': '⟦Ļàƀ ŕéšûļţ · ƒîñàļ · ĻÖÎÑÇ 4548-4~~~~~~~~⟧',
  'records_conflict.body[0].children[0].items[1].label': '⟦Éñţéŕéð ƀý ýöû: 7.4%~~~~~⟧',
  'records_conflict.body[0].children[0].items[1].sub': '⟦Öçţ 1, 2026~~⟧',
  'records_conflict.body[0].children[0].items[2].label': '⟦Ķééþ ƀöţĥ~~~~⟧',
  'records_conflict.body[0].children[0].items[2].sub': '⟦Ýöûŕ çļîñîçîàñ’š ṽàļûé îš ûšéð îñ šûɱɱàŕîéš~~~~~~~~~~~~~~~⟧',
  'records_conflict.body[1].eyebrow': '⟦Ɓļööð þŕéššûŕé · Àûĝ 4, 2026~~~~~~~⟧',
  'records_conflict.body[1].title': '⟦1290/80 îš öûţšîðé ţĥé þöššîƀļé ŕàñĝé~~~~~~~~~~⟧',
  'records_conflict.body[1].children[0].items[0].label': '⟦Ðîšçàŕð~~~⟧',
  'records_conflict.body[1].children[0].items[0].sub': '⟦Ļîķéļý à ţýþö îñ ţĥé šöûŕçé~~~~~~~~~⟧',
  'records_conflict.body[1].children[0].items[1].label': '⟦Ķééþ àš 129/80~~~⟧',
  'records_conflict.body[1].children[0].items[1].sub': '⟦Çöŕŕéçţéð ƀý ýöû, ɱàŕķéð àš éðîţéð~~~~~~~~~~~~⟧',
  'records_conflict.body[1].children[0].items[2].label': '⟦Àšķ ɱý çàŕé ţéàɱ~~~~~~⟧',
  'records_conflict.body[1].children[0].items[2].sub': '⟦Šéñðš à ǫûéšţîöñ ŵîţĥ ţĥé öŕîĝîñàļ ṽàļûé~~~~~~~~~~~~~~⟧',
  'records_conflict.footer[0].action.cases[0].action.then.value': '⟦Šàṽéð~~⟧',
  'records_conflict.footer[0].action.cases[1].action.value': '⟦Çĥööšé àñ öþţîöñ ƒöŕ àţ ļéàšţ öñé îţéɱ.~~~~~~~~~~~~~⟧',
  'records_conflict.footer[0].label': '⟦Šàṽé çĥöîçéš~~~~~⟧',
  'records_conflict.header.title': '⟦Ñééðš ŕéṽîéŵ~~~~~⟧',
  'records_conflict.header.pill': '⟦2 îţéɱš~~⟧',
  'records_error.body[1].text': '⟦Çöûļðñ’ţ çöññéçţ~~~~~~⟧',
  'records_error.body[2].text': '⟦Šîĝñ-îñ ŵàš çàñçéļļéð, ðéñîéð, öŕ ţĥé šéŕṽéŕ îšñ’ţ à ŠṀÀŔŢ öñ ƑĤÎŔ Ŕ4 šéŕṽéŕ. Ñöţĥîñĝ ŵàš îɱþöŕţéð.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_error.footer[0].label': '⟦Ţŕý àĝàîñ~~~~⟧',
  'records_error.footer[1].label': '⟦Çĥööšé àñöţĥéŕ šöûŕçé~~~~~~~~⟧',
  'records_error.footer[2].label': '⟦Éñţéŕ ɱàñûàļļý îñšţéàð~~~~~~~~⟧',
  'records_error.header.title': '⟦Çöññéçţ~~~⟧',
  'records_source.body[0].rows[0][0]': '⟦Çöññéçţîöñ~~~~⟧',
  'records_source.body[0].rows[0][1]': '⟦Éþîç ṀýÇĥàŕţ · ŠṀÀŔŢ öñ ƑĤÎŔ Ŕ4~~~~~~~~~~⟧',
  'records_source.body[0].rows[1][0]': '⟦Ļàšţ šýñç~~~~⟧',
  'records_source.body[0].rows[1][1]': '⟦Ţöðàý 7:02 ÀṀ~~~⟧',
  'records_source.body[0].rows[2][0]': '⟦Ñéẋţ šýñç~~~~⟧',
  'records_source.body[0].rows[2][1]': '⟦Ţöɱöŕŕöŵ~~~~⟧',
  'records_source.body[0].rows[3][0]': '⟦Àççéšš~~~⟧',
  'records_source.body[0].rows[3][1]': '⟦Ŕéàð-öñļý · 6 çàţéĝöŕîéš~~~~~~~~⟧',
  'records_source.body[0].rows[4][0]': '⟦Çöññéçţéð~~~~⟧',
  'records_source.body[0].rows[4][1]': '⟦Öçţ 3, 2026~~⟧',
  'records_source.body[1].rows[0].label': '⟦Šýñç ñöŵ~~~⟧',
  'records_source.body[1].rows[0].action.then.value': '⟦Šýñçéð · 2 ñéŵ ŕéšûļţš~~~~~~~⟧',
  'records_source.body[2].rows[0].label': '⟦Çöñðîţîöñš~~~~⟧',
  'records_source.body[2].rows[0].sub': '⟦Çöñðîţîöñ~~~~⟧',
  'records_source.body[2].rows[1].label': '⟦Ṽîţàļ šîĝñš~~~~⟧',
  'records_source.body[2].rows[1].sub': '⟦Öƀšéŕṽàţîöñ · ƀļööð þŕéššûŕé, ŵéîĝĥţ~~~~~~~~~~~~⟧',
  'records_source.body[2].rows[2].label': '⟦Ļàƀ ŕéšûļţš~~~~⟧',
  'records_source.body[2].rows[2].sub': '⟦Öƀšéŕṽàţîöñ · À1Ç, ļîþîðš, éĜƑŔ~~~~~~~~~~⟧',
  'records_source.body[2].rows[3].label': '⟦Ṁéðîçàţîöñš~~~~~⟧',
  'records_source.body[2].rows[3].sub': '⟦ṀéðîçàţîöñŔéǫûéšţ~~~~~~~⟧',
  'records_source.body[2].rows[4].label': '⟦Îɱɱûñîžàţîöñš~~~~~~⟧',
  'records_source.body[2].rows[4].sub': '⟦Îɱɱûñîžàţîöñ~~~~~⟧',
  'records_source.body[2].rows[5].label': '⟦Šɱöķîñĝ šţàţûš~~~~~~⟧',
  'records_source.body[2].rows[5].sub': '⟦Öƀšéŕṽàţîöñ · ĻÖÎÑÇ 72166-2~~~~~~~⟧',
  'records_source.body[2].title': '⟦Ŵĥàţ ŵé ŕéàð~~~~⟧',
  'records_source.footer[0].label': '⟦Ðîšçöññéçţ~~~~⟧',
  'records_source.header.title': '⟦Þàţéļ Ƒàɱîļý Ṁéðîçîñé~~~~~~~~⟧',
  'records_disconnect.body[0].text': '⟦Ðîšçöññéçţ Þàţéļ Ƒàɱîļý Ṁéðîçîñé?~~~~~~~~~~~~⟧',
  'records_disconnect.body[1].text': '⟦Ţéţĥéŕ šţöþš ŕéàðîñĝ ñéŵ ŕéçöŕðš àñð ŕéṽöķéš îţš àççéšš ţöķéñ.~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_disconnect.body[2].items[0].label': '⟦Ķééþ îɱþöŕţéð ðàţà~~~~~~~⟧',
  'records_disconnect.body[2].items[0].sub': '⟦Ṁàŕķéð “ƒŕöɱ Þàţéļ Ƒàɱîļý Ṁéðîçîñé”~~~~~~~~~~~~⟧',
  'records_disconnect.body[2].items[1].label': '⟦Ðéļéţé ðàţà îɱþöŕţéð ƒŕöɱ ţĥîš šöûŕçé~~~~~~~~~~~~~⟧',
  'records_disconnect.body[2].items[1].sub': '⟦21 îţéɱš ŕéɱöṽéð ƒŕöɱ ýöûŕ þŕöĝŕàɱš~~~~~~~~~~~~⟧',
  'records_disconnect.footer[0].action.then.value': '⟦Ðîšçöññéçţéð~~~~~⟧',
  'records_disconnect.footer[0].label': '⟦Ðîšçöññéçţ šöûŕçé~~~~~~~⟧',
  'records_disconnect.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'records_manual.body[0].text': '⟦Àðð à ĥéàļţĥ ṽàļûé~~~~~~⟧',
  'records_manual.body[1].options[0]': '⟦Ɓļööð þŕéššûŕé~~~~~~⟧',
  'records_manual.body[1].options[1]': '⟦Ĝļûçöšé~~~⟧',
  'records_manual.body[1].options[2]': '⟦Ļàƀ ŕéšûļţ~~~~⟧',
  'records_manual.body[1].options[3]': '⟦Ṽàççîñé~~~⟧',
  'records_manual.body[1].options[4]': '⟦Ṁéðîçàţîöñ~~~~⟧',
  'records_manual.body[1].options[5]': '⟦Çöñðîţîöñ~~~~⟧',
  'records_manual.body[1].label': '⟦Ţýþé~~⟧',
  'records_manual.body[2].label': '⟦Ţéšţ~~⟧',
  'records_manual.body[2].placeholder': '⟦À1Ç~⟧',
  'records_manual.body[3].label': '⟦Ṽàļûé~~⟧',
  'records_manual.body[4].label': '⟦Ðàţé~~⟧',
  'records_manual.body[4].placeholder': '⟦Öçţ 1, 2026~~⟧',
  'records_manual.body[5].text': '⟦Çĥéçķéð àĝàîñšţ þļàûšîƀļé ŕàñĝéš àñð ýöûŕ çöññéçţéð ŕéçöŕðš. Ṁàñûàļ ṽàļûéš àŕé ļàƀéļļéð “Éñţéŕéð ƀý ýöû”.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'records_manual.footer[0].action.then.cases[0].action.value': '⟦Šàṽéð · šĥàŕéð ŵîţĥ Šţéàðý~~~~~~~~~⟧',
  'records_manual.footer[0].action.then.cases[2].action.value': '⟦Àļŕéàðý îñ ýöûŕ ŕéçöŕðš ƒŕöɱ Éþîç. Ñöţ àððéð ţŵîçé.~~~~~~~~~~~~~~~~~⟧',
  'records_manual.footer[0].label': '⟦Šàṽé~~⟧',
  'records_manual.header.title': '⟦Éñţéŕ à ṽàļûé~~~~~⟧',
  'records_manual_error.body[0].text': '⟦Àðð à ĥéàļţĥ ṽàļûé~~~~~~⟧',
  'records_manual_error.body[1].label': '⟦Ţéšţ~~⟧',
  'records_manual_error.body[1].placeholder': '⟦À1Ç~⟧',
  'records_manual_error.body[2].label': '⟦Ṽàļûé~~⟧',
  'records_manual_error.body[2].error': '⟦À1Ç îš ûšûàļļý ƀéţŵééñ 4% àñð 15%. Ðîð ýöû ɱéàñ 7.4?~~~~~~~~~~~~~⟧',
  'records_manual_error.body[3].label': '⟦Ðàţé~~⟧',
  'records_manual_error.body[3].placeholder': '⟦Öçţ 1, 2026~~⟧',
  'records_manual_error.footer[0].action.then.cases[0].action.value': '⟦Šàṽéð · šĥàŕéð ŵîţĥ Šţéàðý~~~~~~~~~⟧',
  'records_manual_error.footer[0].action.then.cases[1].action.value': '⟦Šţîļļ öûţšîðé ţĥé éẋþéçţéð ŕàñĝé~~~~~~~~~~~~⟧',
  'records_manual_error.footer[0].label': '⟦Šàṽé~~⟧',
  'records_manual_error.footer[1].label': '⟦Àšķ ɱý çàŕé ţéàɱ îñšţéàð~~~~~~~~⟧',
  'records_manual_error.header.title': '⟦Éñţéŕ à ṽàļûé~~~~~⟧',
  'records_item.body[0].title': '⟦Šýšţöļîç · àļļ šöûŕçéš~~~~~~~~⟧',
  'records_item.body[1].rows[0].label': '⟦128/82 · Öçţ 15~~⟧',
  'records_item.body[1].rows[0].sub': '⟦Þàţéļ Ƒàɱîļý Ṁéðîçîñé (Éþîç) · çļîñîç ŕéàðîñĝ~~~~~~~~~~~~~~~⟧',
  'records_item.body[1].rows[1].label': '⟦135/85 · Öçţ 14~~⟧',
  'records_item.body[1].rows[1].sub': '⟦Éñţéŕéð ƀý ýöû · ĥöɱé ɱöñîţöŕ~~~~~~~~~~⟧',
  'records_item.body[1].rows[2].label': '⟦131/80 · Öçţ 2~~⟧',
  'records_item.body[1].rows[2].sub': '⟦Þàţéļ Ƒàɱîļý Ṁéðîçîñé (Éþîç)~~~~~~~~~~⟧',
  'records_item.body[1].title': '⟦Ļàţéšţ~~~⟧',
  'records_item.body[2].rows[0][0]': '⟦Çöðéð àš~~~⟧',
  'records_item.body[2].rows[0][1]': '⟦ĻÖÎÑÇ 85354-9 (8480-6 / 8462-4)~~⟧',
  'records_item.body[2].rows[1][0]': '⟦Ûšéð ƀý~~~⟧',
  'records_item.footer[0].label': '⟦Öþéñ îñ Ĥéàŕţŵîšé~~~~~~⟧',
  'records_item.header.title': '⟦Ɓļööð þŕéššûŕé~~~~~~⟧',
  'sf_unplug_intro.body[1].text': '⟦Þàûšé ţĥé àþþš ýöû çĥööšé, ŵĥéñ ýöû çĥööšé.~~~~~~~~~~~~~~⟧',
  'sf_unplug_intro.body[2].text': '⟦Ûñþļûĝ îš öþţîöñàļ. Îţ àððš à þàûšé šçŕééñ ţö àþþš ýöû þîçķ, àƒţéŕ ļîɱîţš ýöû šéţ. Þàûšé 60 šţàýš ţĥé šàɱé: à ɱöɱéñţ ţö çĥéçķ îñ, ñéṽéŕ à ļöçķ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_intro.body[3].rows[0][0]': '⟦Çàñ~~⟧',
  'sf_unplug_intro.body[3].rows[0][1]': '⟦Þàûšé àþþš ýöû þîçķ, àƒţéŕ ýöûŕ ļîɱîţš~~~~~~~~~~~~~⟧',
  'sf_unplug_intro.body[3].rows[1][0]': '⟦Çàñ’ţ~~⟧',
  'sf_unplug_intro.body[3].rows[1][1]': '⟦Šéé ŵĥàţ ýöû ðö îñšîðé àñý àþþ~~~~~~~~~~⟧',
  'sf_unplug_intro.body[3].rows[2][0]': '⟦Öñ îÞĥöñé~~~~⟧',
  'sf_unplug_intro.body[3].rows[2][1]': '⟦Àþþļé ðöéšñ’ţ šĥàŕé àþþ ñàɱéš öŕ ɱîñûţéš ŵîţĥ Ţéţĥéŕ~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_intro.body[3].rows[3][0]': '⟦Šţàýš~~⟧',
  'sf_unplug_intro.body[3].rows[3][1]': '⟦Öñ ţĥîš þĥöñé. Ýöûŕ àþþ ļîšţ ñéṽéŕ ŕéàçĥéš Ţéţĥéŕ~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_intro.body[3].rows[4][0]': '⟦Ñéṽéŕ þàûšéð~~~~~⟧',
  'sf_unplug_intro.body[3].rows[4][1]': '⟦Ţéţĥéŕ, þĥöñé çàļļš àñð éɱéŕĝéñçý çàļļš~~~~~~~~~~~~~~⟧',
  'sf_unplug_intro.footer[0].label': '⟦Šéţ ûþ Ûñþļûĝ~~~~~⟧',
  'sf_unplug_intro.footer[1].label': '⟦Ñöţ ñöŵ~~~⟧',
  'sf_unplug_intro.header.pill': '⟦Öþţîöñàļ~~~~⟧',
  'sf_unplug_auth.body[1].text': '⟦Àļļöŵ Šçŕééñ Ţîɱé ƒöŕ Ûñþļûĝ~~~~~~~~~~⟧',
  'sf_unplug_auth.body[2].text': '⟦Àþþļé ŵîļļ àšķ ýöû ţö ļéţ Ţéţĥéŕ Ĥéàļţĥ ûšé Šçŕééñ Ţîɱé. Ţĥîš ļéţš Ûñþļûĝ þàûšé àþþš. Îţ ðöéšñ’ţ ļéţ Ţéţĥéŕ šéé ŵĥàţ ýöû ðö îñ ţĥéɱ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth.body[3].rows[0][0]': '⟦Ļéţš Ûñþļûĝ~~~~⟧',
  'sf_unplug_auth.body[3].rows[0][1]': '⟦Þàûšé àþþš ýöû çĥööšé~~~~~~~~⟧',
  'sf_unplug_auth.body[3].rows[1][0]': '⟦Ñéṽéŕ šĥàŕéš~~~~~⟧',
  'sf_unplug_auth.body[3].rows[1][1]': '⟦Àþþ ñàɱéš, çöñţéñţ, ɱéššàĝéš~~~~~~~~~~⟧',
  'sf_unplug_auth.body[3].rows[2][0]': '⟦Ţûŕñ öƒƒ~~~⟧',
  'sf_unplug_auth.body[3].rows[2][1]': '⟦Àñýţîɱé îñ Àççöûñţ → ŠçŕöļļƑŕéé~~~~~~~~~~~⟧',
  'sf_unplug_auth.footer[0].label': '⟦Çöñţîñûé~~~~⟧',
  'sf_unplug_auth.footer[1].label': '⟦Ñöţ ñöŵ~~~⟧',
  'sf_unplug_auth.header.pill': '⟦Šţéþ 1 öƒ 3~~~⟧',
  'sf_unplug_auth_denied.body[0].text': '⟦Šçŕééñ Ţîɱé àççéšš ŵàš ñöţ àļļöŵéð.~~~~~~~~~~~~⟧',
  'sf_unplug_auth_denied.body[1].text': '⟦Ûñþļûĝ ñééðš Šçŕééñ Ţîɱé ţö þàûšé àþþš.~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_denied.body[2].text': '⟦Éṽéŕýţĥîñĝ éļšé îñ ŠçŕöļļƑŕéé ŵöŕķš ŵîţĥöûţ îţ: ýöûŕ ĝöàļ, Þàûšé 60 àñð çĥéçķ-îñš.~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_denied.footer[0].action.cases[1].action.value': '⟦Šţîļļ ñöţ àļļöŵéð. Ýöû çàñ ţûŕñ îţ öñ ļàţéŕ îñ Šéţţîñĝš.~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_denied.footer[0].label': '⟦Ţŕý àĝàîñ~~~~⟧',
  'sf_unplug_auth_denied.footer[1].label': '⟦Öþéñ þĥöñé šéţţîñĝš~~~~~~~⟧',
  'sf_unplug_auth_denied.footer[2].label': '⟦Ñöţ ñöŵ~~~⟧',
  'sf_unplug_auth_denied.header.pill': '⟦Šţéþ 1 öƒ 3~~~⟧',
  'sf_unplug_auth_unavailable.body[0].text': '⟦Šçŕééñ Ţîɱé îšñ’ţ àṽàîļàƀļé öñ ţĥîš þĥöñé.~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_unavailable.body[1].text': '⟦Ûñþļûĝ çàñ’ţ ŕûñ ĥéŕé.~~~~~~~⟧',
  'sf_unplug_auth_unavailable.body[2].text': '⟦Ţĥîš çàñ ĥàþþéñ ŵĥéñ Šçŕééñ Ţîɱé îš ɱàñàĝéð ƀý àñ öŕĝàñîžàţîöñ öŕ ļîɱîţéð ƀý à þàŕéñţ. ŠçŕöļļƑŕéé šţîļļ ŵöŕķš ŵîţĥöûţ Ûñþļûĝ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_unavailable.footer[0].label': '⟦Ɓàçķ ţö ŠçŕöļļƑŕéé~~~~~~~⟧',
  'sf_unplug_auth_unavailable.header.pill': '⟦Öþţîöñàļ~~~~⟧',
  'sf_unplug_auth_notifications.body[0].text': '⟦Ñöţîƒîçàţîöñš àŕé öƒƒ ƒöŕ Ţéţĥéŕ.~~~~~~~~~~~~⟧',
  'sf_unplug_auth_notifications.body[1].text': '⟦Ţûŕñ öñ ñöţîƒîçàţîöñš ƒöŕ Ûñþļûĝ?~~~~~~~~~~~~⟧',
  'sf_unplug_auth_notifications.body[2].text': '⟦Ŵĥéñ à þàûšé šçŕééñ šéñðš ýöû ţö Ţéţĥéŕ, îñçļûðîñĝ Ĝéţ šûþþöŕţ, îţ ûšéš à ñöţîƒîçàţîöñ. Ŵîţĥ ñöţîƒîçàţîöñš öƒƒ, Ûñþļûĝ šţîļļ þàûšéš àþþš, àñð ţĥé þàûšé šçŕééñ ţéļļš ýöû ţö öþéñ Ţéţĥéŕ ýöûŕšéļƒ ƒöŕ šûþþöŕţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_notifications.footer[0].label': '⟦Öþéñ þĥöñé šéţţîñĝš~~~~~~~⟧',
  'sf_unplug_auth_notifications.footer[1].action.cases[2].action.value': '⟦Ñöţîƒîçàţîöñš àŕé šţîļļ öƒƒ. Ýöû çàñ ţûŕñ ţĥéɱ öñ ļàţéŕ îñ Šéţţîñĝš.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_notifications.footer[1].label': '⟦Çĥéçķ àĝàîñ~~~~⟧',
  'sf_unplug_auth_notifications.footer[2].label': '⟦Çöñţîñûé ŵîţĥöûţ ñöţîƒîçàţîöñš~~~~~~~~~~~~⟧',
  'sf_unplug_auth_notifications.header.pill': '⟦Šţéþ 1 öƒ 3~~~⟧',
  'sf_unplug_auth_android.body[0].text': '⟦Ţŵö Àñðŕöîð šéţţîñĝš ƒöŕ Ûñþļûĝ~~~~~~~~~~~⟧',
  'sf_unplug_auth_android.body[1].text': '⟦Àñðŕöîð àšķš ƒöŕ éàçĥ öñé šéþàŕàţéļý. Ýöû çàñ ţûŕñ éîţĥéŕ öƒƒ ļàţéŕ, àñð Ûñþļûĝ ŵîļļ ţéļļ ýöû îƒ îţ šţöþš ŵöŕķîñĝ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_android.body[2].items[0].label': '⟦Ûšàĝé àççéšš~~~~~⟧',
  'sf_unplug_auth_android.body[2].items[0].sub': '⟦Öñ · ļéţš Ûñþļûĝ šéé ŵĥîçĥ àþþ îš öþéñ àñð ƒöŕ ĥöŵ ļöñĝ~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_android.body[2].items[1].label': '⟦Ðîšþļàý öṽéŕ öţĥéŕ àþþš~~~~~~~~⟧',
  'sf_unplug_auth_android.body[2].items[1].sub': '⟦Öƒƒ · ļéţš Ûñþļûĝ šĥöŵ ţĥé þàûšé šçŕééñ~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_android.body[2].items[2].label': '⟦Ñöţîƒîçàţîöñš~~~~~~⟧',
  'sf_unplug_auth_android.body[2].items[2].sub': '⟦Àñðŕöîð šĥöŵš à ǫûîéţ “Ţéţĥéŕ îš ŕûññîñĝ” ñöţîçé ŵĥîļé Ûñþļûĝ îš öñ~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_auth_android.body[2].label': '⟦Ñééðéð~~~⟧',
  'sf_unplug_auth_android.footer[0].label': '⟦Ţûŕñ öñ ðîšþļàý öṽéŕ àþþš~~~~~~~~~⟧',
  'sf_unplug_auth_android.footer[1].label': '⟦Ţûŕñ öñ ûšàĝé àççéšš~~~~~~~⟧',
  'sf_unplug_auth_android.footer[2].label': '⟦Î’ṽé ţûŕñéð ţĥéɱ öñ~~~~~~⟧',
  'sf_unplug_auth_android.footer[2].action.cases[2].action.value': '⟦Ûñþļûĝ šţîļļ ñééðš ƀöţĥ šéţţîñĝš.~~~~~~~~~~~~⟧',
  'sf_unplug_auth_android.header.pill': '⟦Šţéþ 1 öƒ 3~~~⟧',
  'sf_unplug_apps.body[0].text': '⟦Ŵĥîçĥ àþþš šĥöûļð Ûñþļûĝ þàûšé?~~~~~~~~~~~⟧',
  'sf_unplug_apps.body[1].text': '⟦Àþþļé’š àþþ þîçķéŕ öþéñš ñéẋţ. Ţéţĥéŕ ñéṽéŕ šééš ŵĥîçĥ àþþš ýöû þîçķ: Àþþļé ķééþš ţĥàţ çĥöîçé öñ ţĥîš þĥöñé.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_apps.body[2].title': '⟦Šţàŕţ šɱàļļ~~~~⟧',
  'sf_unplug_apps.body[2].text': '⟦Öñé öŕ ţŵö àþþš ţĥàţ þûļļ ýöû îñ ɱöšţ îš à ĝööð šţàŕţ. Ýöû çàñ çĥàñĝé ţĥîš àñýţîɱé.~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_apps.body[3].text': '⟦Ţéţĥéŕ, ţĥé þĥöñé ðîàļéŕ àñð éɱéŕĝéñçý çàļļîñĝ çàñ ñéṽéŕ ƀé çĥöšéñ öŕ þàûšéð.~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_apps.footer[0].label': '⟦Öþéñ àþþ þîçķéŕ~~~~~~⟧',
  'sf_unplug_apps.footer[1].label': '⟦Ñöţ ñöŵ~~~⟧',
  'sf_unplug_apps.header.title': '⟦Çĥööšé àþþš~~~~⟧',
  'sf_unplug_apps.header.pill': '⟦Šţéþ 2 öƒ 3~~~⟧',
  'sf_unplug_picker_ios.body[0].label': '⟦Àþþļé’š àþþ þîçķéŕ~~~~~~⟧',
  'sf_unplug_picker_ios.footer[0].label': '⟦Ðöñé~~⟧',
  'sf_unplug_picker_ios.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'sf_unplug_apps_android.body[0].text': '⟦Çĥööšé ţĥé àþþš ţö þàûšé~~~~~~~~⟧',
  'sf_unplug_apps_android.body[1].text': '⟦Ţĥîš çĥöîçé šţàýš öñ ţĥîš þĥöñé. Ţéţĥéŕ ñéṽéŕ ŕéçéîṽéš îţ.~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_apps_android.body[2].items[0].label': '⟦Šĥöŕţ-ṽîðéö àþþ~~~~~~⟧',
  'sf_unplug_apps_android.body[2].items[1].label': '⟦Þĥöţö ƒééð àþþ~~~~~⟧',
  'sf_unplug_apps_android.body[2].items[2].label': '⟦Ṽîðéö àþþ~~~~⟧',
  'sf_unplug_apps_android.body[2].items[3].label': '⟦Ñéŵš àþþ~~~⟧',
  'sf_unplug_apps_android.body[2].items[4].label': '⟦Ĝàɱéš àþþ~~~~⟧',
  'sf_unplug_apps_android.body[2].items[5].label': '⟦Šĥöþþîñĝ àþþ~~~~~⟧',
  'sf_unplug_apps_android.body[2].label': '⟦Àþþš öñ ţĥîš þĥöñé~~~~~~⟧',
  'sf_unplug_apps_android.body[3].text': '⟦Ţéţĥéŕ, ţĥé Þĥöñé àþþ àñð éɱéŕĝéñçý çàļļîñĝ àŕéñ’ţ îñ ţĥîš ļîšţ. Ţĥéý çàñ ñéṽéŕ ƀé þàûšéð.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_apps_android.footer[0].label': '⟦Ðöñé · 3 àþþš~~~~⟧',
  'sf_unplug_apps_android.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'sf_unplug_apps_android.header.title': '⟦Çĥööšé àþþš~~~~⟧',
  'sf_unplug_apps_android.header.pill': '⟦Šţéþ 2 öƒ 3~~~⟧',
  'sf_unplug_apps_chosen.body[0].text': '⟦Ñàɱé ýöûŕ ĝŕöûþš~~~~~~⟧',
  'sf_unplug_apps_chosen.body[1].text': '⟦îÞĥöñé ðöéšñ’ţ ţéļļ Ţéţĥéŕ ţĥé àþþ ñàɱéš, šö ĝîṽé éàçĥ ĝŕöûþ à ñàɱé ýöû’ļļ ŕéçöĝñîžé. Ĝŕöûþ ñàɱéš šţàý öñ ţĥîš þĥöñé.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_apps_chosen.body[2].rows[0].label': '⟦Ṽîðéö àþþš~~~~⟧',
  'sf_unplug_apps_chosen.body[2].rows[0].sub': '⟦3 àþþš~~⟧',
  'sf_unplug_apps_chosen.body[2].rows[1].label': '⟦Ƒééðš~~⟧',
  'sf_unplug_apps_chosen.body[2].rows[1].sub': '⟦2 àþþš~~⟧',
  'sf_unplug_apps_chosen.body[2].title': '⟦Ýöûŕ ĝŕöûþš~~~~⟧',
  'sf_unplug_apps_chosen.body[3].label': '⟦Ñéŵ ĝŕöûþ ñàɱé~~~~~⟧',
  'sf_unplug_apps_chosen.body[3].placeholder': '⟦é.ĝ. Ĝàɱéš~~~⟧',
  'sf_unplug_apps_chosen.body[4].label': '⟦Àðð àñöţĥéŕ ĝŕöûþ~~~~~~⟧',
  'sf_unplug_apps_chosen.footer[0].label': '⟦Ñéẋţ: ļîɱîţš~~~~⟧',
  'sf_unplug_apps_chosen.header.title': '⟦Çĥööšé àþþš~~~~⟧',
  'sf_unplug_apps_chosen.header.pill': '⟦Šţéþ 2 öƒ 3~~~⟧',
  'sf_unplug_limits.body[0].text': '⟦Ŵĥéñ šĥöûļð Ûñþļûĝ šţéþ îñ?~~~~~~~~~⟧',
  'sf_unplug_limits.body[1].children[0].label': '⟦Ðàîļý ţîɱé îñ ţĥéšé àþþš~~~~~~~~⟧',
  'sf_unplug_limits.body[1].children[0].minLabel': '⟦15 ɱîñ~~⟧',
  'sf_unplug_limits.body[1].children[0].maxLabel': '⟦4 ĥ~⟧',
  'sf_unplug_limits.body[1].children[1].label': '⟦Öþéñš à ðàý~~~~⟧',
  'sf_unplug_limits.body[1].children[2].text': '⟦Öñ îÞĥöñé, öþéñš àŕé çöûñţéð ƒŕöɱ þàûšé šçŕééñš šĥöŵñ, šö ţĥé ñûɱƀéŕ îš àþþŕöẋîɱàţé.~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_limits.body[2].items[0].label': '⟦Ñöţîçé öñļý~~~~⟧',
  'sf_unplug_limits.body[2].items[0].sub': '⟦Çöûñţ ţîɱé, ñö þàûšé šçŕééñ~~~~~~~~~⟧',
  'sf_unplug_limits.body[2].items[1].label': '⟦Þàûšé šçŕééñ~~~~~⟧',
  'sf_unplug_limits.body[2].items[1].sub': '⟦À þàûšé ƀéƒöŕé ţĥé àþþ öþéñš~~~~~~~~~~⟧',
  'sf_unplug_limits.body[2].items[2].label': '⟦Þàûšé àñð öñé šɱàļļ šţéþ~~~~~~~~⟧',
  'sf_unplug_limits.body[2].items[2].sub': '⟦À ƀŕéàţĥ, à ţýþéð šéñţéñçé öŕ à ǫûîçķ šûɱ ƒîŕšţ~~~~~~~~~~~~~~~⟧',
  'sf_unplug_limits.body[2].items[2].badge': '⟦Šûĝĝéšţéð~~~~⟧',
  'sf_unplug_limits.body[2].items[3].label': '⟦Ƒîŕɱ~~⟧',
  'sf_unplug_limits.body[2].items[3].sub': '⟦Ñö “öþéñ àñýŵàý” ûñţîļ ţöɱöŕŕöŵ~~~~~~~~~~⟧',
  'sf_unplug_limits.body[2].label': '⟦Ŵĥéñ ýöû ŕéàçĥ à ļîɱîţ~~~~~~~~⟧',
  'sf_unplug_limits.body[3].options[0]': '⟦Öñé ƀŕéàţĥ~~~~⟧',
  'sf_unplug_limits.body[3].options[1]': '⟦Ţýþé à šéñţéñçé~~~~~~⟧',
  'sf_unplug_limits.body[3].options[2]': '⟦Ǫûîçķ šûɱ~~~~⟧',
  'sf_unplug_limits.body[3].label': '⟦Šɱàļļ šţéþ~~~~⟧',
  'sf_unplug_limits.body[4].label': '⟦“Öþéñ àñýŵàý” þéŕ ðàý~~~~~~~⟧',
  'sf_unplug_limits.body[5].text': '⟦Šţŕîçţéŕ ļîɱîţš àþþļý ñöŵ. Ļööšéŕ ļîɱîţš šţàŕţ ţöɱöŕŕöŵ, šö öñé ĥàŕð ɱöɱéñţ ðöéšñ’ţ çĥàñĝé ýöûŕ þļàñ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_limits.body[6].text': '⟦Éṽéŕý þàûšé šçŕééñ ĥàš à Ĝéţ šûþþöŕţ ƀûţţöñ. Ţéţĥéŕ, ţĥé þĥöñé ðîàļéŕ àñð éɱéŕĝéñçý çàļļîñĝ çàñ ñéṽéŕ ƀé çĥöšéñ öŕ þàûšéð.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_limits.footer[0].action.then.value': '⟦Ûñþļûĝ îš öñ~~~~⟧',
  'sf_unplug_limits.footer[0].label': '⟦Šàṽé ļîɱîţš~~~~⟧',
  'sf_unplug_limits.header.title': '⟦Ļîɱîţš~~~⟧',
  'sf_unplug_limits.header.pill': '⟦Šţéþ 3 öƒ 3~~~⟧',
  'sf_unplug_home.body[0].title': '⟦Ûñþļûĝ îš öñ~~~~⟧',
  'sf_unplug_home.body[0].text': '⟦5 àþþš îñ 2 ĝŕöûþš · þàûšé šçŕééñ àƒţéŕ 60 ɱîñ öŕ 20 öþéñš~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_home.body[1].eyebrow': '⟦Ƒöçûš šéššîöñ~~~~~⟧',
  'sf_unplug_home.body[1].title': '⟦Ñééð ţö ƒöçûš?~~~~~⟧',
  'sf_unplug_home.body[1].text': '⟦Þàûšé ýöûŕ çĥöšéñ àþþš ƒöŕ à šéţ ţîɱé~~~~~~~~~~~~⟧',
  'sf_unplug_home.body[1].cta[0].label': '⟦Šţàŕţ~~⟧',
  'sf_unplug_home.body[2].rows[0].label': '⟦Àþþš~~⟧',
  'sf_unplug_home.body[2].rows[0].sub': '⟦Ṽîðéö àþþš · 3, Ƒééðš · 2~~~~~~⟧',
  'sf_unplug_home.body[2].rows[1].label': '⟦Ļîɱîţš & þàûšé šçŕééñ~~~~~~~⟧',
  'sf_unplug_home.body[2].rows[1].sub': '⟦60 ɱîñ · 20 öþéñš · öñé ƀŕéàţĥ ƒîŕšţ~~~~~~~~~⟧',
  'sf_unplug_home.body[2].rows[2].label': '⟦Þŕéṽîéŵ ţĥé þàûšé šçŕééñ~~~~~~~~~⟧',
  'sf_unplug_home.body[2].rows[2].sub': '⟦îÞĥöñé šĥîéļð öŕ Àñðŕöîð öṽéŕļàý~~~~~~~~~~~~⟧',
  'sf_unplug_home.body[2].rows[3].label': '⟦Ţŕàçķîñĝ çĥéçķ~~~~~~⟧',
  'sf_unplug_home.body[2].rows[3].sub': '⟦Àļļ çĥéçķš þàšš~~~~~~⟧',
  'sf_unplug_home.body[2].title': '⟦Šéţţîñĝš~~~~⟧',
  'sf_unplug_home.body[3].rows[0].label': '⟦Ĥöŵ Ûñþļûĝ ŵöŕķš~~~~~~⟧',
  'sf_unplug_home.body[3].rows[0].sub': '⟦Ŵĥàţ îţ çàñ àñð çàñ’ţ šéé~~~~~~~~⟧',
  'sf_unplug_home.body[3].rows[1].label': '⟦Ţûŕñ öƒƒ Ûñþļûĝ~~~~~~⟧',
  'sf_unplug_home.body[3].rows[1].sub': '⟦Þàûšéð àþþš öþéñ ñöŕɱàļļý àĝàîñ~~~~~~~~~~~⟧',
  'sf_unplug_home.header.pill': '⟦Öñ~⟧',
  'sf_unplug_session.body[0].text': '⟦Þàûšé ýöûŕ àþþš ƒöŕ à ŵĥîļé.~~~~~~~~~⟧',
  'sf_unplug_session.body[1].options[0]': '⟦25 ɱîñ~~⟧',
  'sf_unplug_session.body[1].options[1]': '⟦45 ɱîñ~~⟧',
  'sf_unplug_session.body[1].options[2]': '⟦60 ɱîñ~~⟧',
  'sf_unplug_session.body[1].options[3]': '⟦90 ɱîñ~~⟧',
  'sf_unplug_session.body[1].label': '⟦Ĥöŵ ļöñĝ~~~⟧',
  'sf_unplug_session.body[2].items[0].label': '⟦Öñļý ɱý çĥöšéñ àþþš~~~~~~~⟧',
  'sf_unplug_session.body[2].items[0].sub': '⟦Ṽîðéö àþþš, Ƒééðš~~~~~~⟧',
  'sf_unplug_session.body[2].items[1].label': '⟦Éṽéŕýţĥîñĝ éẋçéþţ àþþš Î àļļöŵ~~~~~~~~~~~⟧',
  'sf_unplug_session.body[2].items[1].sub': '⟦Ţéţĥéŕ, þĥöñé çàļļš àñð éɱéŕĝéñçý çàļļš àļŵàýš šţàý öþéñ~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_session.body[2].label': '⟦Ŵĥàţ ţö þàûšé~~~~~⟧',
  'sf_unplug_session.body[3].children[0].label': '⟦Šţŕîçţ~~~⟧',
  'sf_unplug_session.body[3].children[0].sub': '⟦Éñðîñĝ éàŕļý àšķš ƒöŕ à ŕéàšöñ, ķéþţ öñ ţĥîš þĥöñé~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_session.footer[0].label': '⟦Šţàŕţ šéššîöñ~~~~~⟧',
  'sf_unplug_session.header.title': '⟦Ƒöçûš šéššîöñ~~~~~⟧',
  'sf_unplug_session_active.body[0].label': '⟦ļéƒţ öƒ 45 ɱîñ · ûñţîļ 3:45 ÞṀ~~~~~~~⟧',
  'sf_unplug_session_active.body[1].text': '⟦Ṽîðéö àþþš àñð Ƒééðš àŕé þàûšéð. Ţéţĥéŕ, þĥöñé çàļļš àñð éɱéŕĝéñçý çàļļš šţàý öþéñ.~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_session_active.body[2].title': '⟦Ûŕĝé ţö çĥéçķ?~~~~~⟧',
  'sf_unplug_session_active.body[2].text': '⟦Ţàķé 60 šéçöñðš ƒîŕšţ~~~~~~~⟧',
  'sf_unplug_session_active.body[2].cta[0].label': '⟦Þàûšé 60~~⟧',
  'sf_unplug_session_active.footer[0].label': '⟦Éñð éàŕļý~~~~⟧',
  'sf_unplug_session_active.header.title': '⟦Ƒöçûš šéššîöñ~~~~~⟧',
  'sf_unplug_session_active.header.pill': '⟦Šţŕîçţ~~~⟧',
  'sf_unplug_session_end.body[0].text': '⟦Éñð ýöûŕ šéššîöñ éàŕļý?~~~~~~~~⟧',
  'sf_unplug_session_end.body[1].text': '⟦Ţĥîš îš à šţŕîçţ šéššîöñ. Çĥööšé öŕ ţýþé à ŕéàšöñ; îţ îš ķéþţ ŵîţĥ ţĥé šéššîöñ öñ ţĥîš þĥöñé. Ñöţĥîñĝ ŕéšéţš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_session_end.body[2].options[0]': '⟦Ñééð àñ àþþ ƒöŕ ŵöŕķ~~~~~~~⟧',
  'sf_unplug_session_end.body[2].options[1]': '⟦Éẋþéçţîñĝ à ɱéššàĝé~~~~~~~⟧',
  'sf_unplug_session_end.body[2].options[2]': '⟦Çĥàñĝéð ɱý ɱîñð~~~~~~⟧',
  'sf_unplug_session_end.body[2].options[3]': '⟦Öţĥéŕ~~⟧',
  'sf_unplug_session_end.body[2].label': '⟦Ŕéàšöñ~~~⟧',
  'sf_unplug_session_end.body[3].label': '⟦Àñýţĥîñĝ ţö àðð?~~~~~~⟧',
  'sf_unplug_session_end.body[3].placeholder': '⟦Öþţîöñàļ~~~~⟧',
  'sf_unplug_session_end.footer[0].action.cases[1].action.value': '⟦Çĥööšé öŕ ţýþé à ŕéàšöñ ţö éñð à šţŕîçţ šéššîöñ.~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_session_end.footer[0].label': '⟦Éñð šéššîöñ~~~~⟧',
  'sf_unplug_session_end.footer[1].label': '⟦Ķééþ ĝöîñĝ~~~~⟧',
  'sf_unplug_session_done.body[1].caption': '⟦Šéššîöñ çöɱþļéţé · ýöûŕ àþþš àŕé öþéñ àĝàîñ~~~~~~~~~~~~~~⟧',
  'sf_unplug_session_done.body[2].text': '⟦Ŵàñţ ţö ɱàķé ţĥîš à ĥàƀîţ? Ýöû çàñ šţàŕţ öñé ƒŕöɱ ŠçŕöļļƑŕéé àñýţîɱé.~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_session_done.footer[0].label': '⟦Ðöñé~~⟧',
  'sf_unplug_session_done.header.title': '⟦Ƒöçûš šéššîöñ~~~~~⟧',
  'sf_unplug_session_done_early.body[0].caption': '⟦Éñðéð éàŕļý · ýöûŕ àþþš àŕé öþéñ àĝàîñ~~~~~~~~~~~~⟧',
  'sf_unplug_session_done_early.body[1].rows[0][0]': '⟦Ŕéàšöñ~~~⟧',
  'sf_unplug_session_done_early.body[1].rows[0][1]': '⟦Éẋþéçţîñĝ à ɱéššàĝé~~~~~~~⟧',
  'sf_unplug_session_done_early.body[1].rows[1][0]': '⟦Ķéþţ~~⟧',
  'sf_unplug_session_done_early.body[1].rows[1][1]': '⟦Öñ ţĥîš þĥöñé öñļý~~~~~~⟧',
  'sf_unplug_session_done_early.body[2].text': '⟦Ñöţĥîñĝ ŕéšéţš. 18 ƒöçûšéð ɱîñûţéš šţîļļ çöûñţ.~~~~~~~~~~~~~~~⟧',
  'sf_unplug_session_done_early.footer[0].label': '⟦Ðöñé~~⟧',
  'sf_unplug_session_done_early.header.title': '⟦Ƒöçûš šéššîöñ~~~~~⟧',
  'sf_unplug_shield.body[2].text': '⟦Þàûšéð ƒöŕ à ɱöɱéñţ~~~~~~~⟧',
  'sf_unplug_shield.body[3].text': '⟦Ýöû àšķéð ţö šļöŵ ţĥîš öñé ðöŵñ. Ṽîðéö àþþš îš öñ ýöûŕ ļîšţ. 2 öƒ 3 “öþéñ àñýŵàý” ļéƒţ ţöðàý. Öþéñ Ţéţĥéŕ ƒöŕ šûþþöŕţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_shield.footer[0].action.value': '⟦Ñöţîƒîçàţîöñ: öþéñ Ţéţĥéŕ ţö ţàķé ýöûŕ ƀŕéàţĥ, öŕ ĝéţ šûþþöŕţ~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_shield.footer[0].label': '⟦Ţàķé à ƀŕéàţĥ~~~~~⟧',
  'sf_unplug_shield.footer[1].label': '⟦Öþéñ àñýŵàý~~~~⟧',
  'sf_unplug_shield.footer[1].action.value': '⟦Öþéñéð · 1 “öþéñ àñýŵàý” ļéƒţ ţöðàý~~~~~~~~~~⟧',
  'sf_unplug_shield_firm.body[2].text': '⟦Þàûšéð ƒöŕ à ɱöɱéñţ~~~~~~~⟧',
  'sf_unplug_shield_firm.body[3].text': '⟦Ýöû àšķéð ţö šļöŵ ţĥîš öñé ðöŵñ. Ṽîðéö àþþš îš öñ ýöûŕ ļîšţ. Ñö “öþéñ àñýŵàý” ļéƒţ ţöðàý. Öþéñ Ţéţĥéŕ ƒöŕ šûþþöŕţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_shield_firm.footer[0].action.value': '⟦Ţĥé àþþ šţàýš çļöšéð.~~~~~~~⟧',
  'sf_unplug_shield_firm.footer[0].label': '⟦Çļöšé ţĥé àþþ~~~~~⟧',
  'sf_unplug_shield_firm.footer[1].label': '⟦Ĝéţ šûþþöŕţ~~~~⟧',
  'sf_unplug_shield_firm.footer[1].action.value': '⟦Ñöţîƒîçàţîöñ: ţàþ ţö öþéñ Ŕéšçûé îñ Ţéţĥéŕ~~~~~~~~~~~~~~⟧',
  'sf_unplug_overlay.body[1].text': '⟦Þàûšéð ƒöŕ à ɱöɱéñţ~~~~~~~⟧',
  'sf_unplug_overlay.body[2].text': '⟦Ýöû àšķéð ţö šļöŵ ţĥîš öñé ðöŵñ. Ṽîðéö àþþš îš öñ ýöûŕ ļîšţ.~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_overlay.body[4].text': '⟦Ɓŕéàţĥé ŵîţĥ ţĥé çîŕçļé. 2 öƒ 3 “öþéñ àñýŵàý” ļéƒţ ţöðàý.~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_overlay.footer[0].action.value': '⟦Ţĥé àþþ šţàýš çļöšéð.~~~~~~~⟧',
  'sf_unplug_overlay.footer[0].label': '⟦Çļöšé ţĥé àþþ~~~~~⟧',
  'sf_unplug_overlay.footer[1].label': '⟦Ĝéţ šûþþöŕţ~~~~⟧',
  'sf_unplug_overlay.footer[2].label': '⟦Öþéñ àñýŵàý~~~~⟧',
  'sf_unplug_overlay.footer[2].action.value': '⟦Öþéñéð · 1 “öþéñ àñýŵàý” ļéƒţ ţöðàý~~~~~~~~~~⟧',
  'sf_unplug_gate.body[0].text': '⟦Öñé ƀŕéàţĥ, ţĥéñ ðéçîðé.~~~~~~~~⟧',
  'sf_unplug_gate.body[2].text': '⟦Ɓŕéàţĥé îñ àš ţĥé çîŕçļé ĝŕöŵš, öûţ àš îţ šĥŕîñķš.~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_gate.body[3].title': '⟦Ñééð ĥéļþ ŕîĝĥţ ñöŵ?~~~~~~~⟧',
  'sf_unplug_gate.body[3].text': '⟦Ŕéšçûé öþéñš îñ öñé ţàþ.~~~~~~~~⟧',
  'sf_unplug_gate.body[3].cta[0].label': '⟦Ĝéţ šûþþöŕţ~~~~⟧',
  'sf_unplug_gate.footer[0].action.value': '⟦Ñîçé. Ţĥé àþþ šţàýš çļöšéð.~~~~~~~~~⟧',
  'sf_unplug_gate.footer[0].label': '⟦Ķééþ îţ çļöšéð~~~~~⟧',
  'sf_unplug_gate.footer[1].label': '⟦Öþéñ îţ ƒöŕ 10 ɱîñûţéš~~~~~~~⟧',
  'sf_unplug_gate.footer[1].action.value': '⟦Öþéñ ƒöŕ 10 ɱîñûţéš. Ţĥé þàûšé šçŕééñ çöɱéš ƀàçķ àƒţéŕ.~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_gate.header.title': '⟦Šɱàļļ šţéþ~~~~⟧',
  'sf_unplug_gate_commit.body[0].text': '⟦Ţýþé îţ öûţ, ţĥéñ ðéçîðé.~~~~~~~~⟧',
  'sf_unplug_gate_commit.body[1].text': '⟦“Î çàñ çöɱé ƀàçķ ţö ţĥîš ļàţéŕ”~~~~~~~~~~⟧',
  'sf_unplug_gate_commit.body[2].label': '⟦Ţýþé ţĥé šéñţéñçé~~~~~~⟧',
  'sf_unplug_gate_commit.body[2].placeholder': '⟦Î çàñ çöɱé ƀàçķ ţö ţĥîš ļàţéŕ~~~~~~~~~~⟧',
  'sf_unplug_gate_commit.body[3].title': '⟦Ñééð ĥéļþ ŕîĝĥţ ñöŵ?~~~~~~~⟧',
  'sf_unplug_gate_commit.body[3].text': '⟦Ŕéšçûé öþéñš îñ öñé ţàþ.~~~~~~~~⟧',
  'sf_unplug_gate_commit.body[3].cta[0].label': '⟦Ĝéţ šûþþöŕţ~~~~⟧',
  'sf_unplug_gate_commit.footer[0].action.value': '⟦Ñîçé. Ţĥé àþþ šţàýš çļöšéð.~~~~~~~~~⟧',
  'sf_unplug_gate_commit.footer[0].label': '⟦Ķééþ îţ çļöšéð~~~~~⟧',
  'sf_unplug_gate_commit.footer[1].label': '⟦Öþéñ îţ ƒöŕ 10 ɱîñûţéš~~~~~~~⟧',
  'sf_unplug_gate_commit.footer[1].action.cases[0].action.value': '⟦Öþéñ ƒöŕ 10 ɱîñûţéš. Ţĥé þàûšé šçŕééñ çöɱéš ƀàçķ àƒţéŕ.~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_gate_commit.footer[1].action.cases[1].action.value': '⟦Ţýþé ţĥé ŵĥöļé šéñţéñçé ƒîŕšţ.~~~~~~~~~~⟧',
  'sf_unplug_gate_commit.header.title': '⟦Šɱàļļ šţéþ~~~~⟧',
  'sf_unplug_gate_sum.body[0].text': '⟦À ǫûîçķ šûɱ, ţĥéñ ðéçîðé.~~~~~~~~⟧',
  'sf_unplug_gate_sum.body[2].label': '⟦Àñšŵéŕ~~~⟧',
  'sf_unplug_gate_sum.body[3].title': '⟦Ñééð ĥéļþ ŕîĝĥţ ñöŵ?~~~~~~~⟧',
  'sf_unplug_gate_sum.body[3].text': '⟦Ŕéšçûé öþéñš îñ öñé ţàþ.~~~~~~~~⟧',
  'sf_unplug_gate_sum.body[3].cta[0].label': '⟦Ĝéţ šûþþöŕţ~~~~⟧',
  'sf_unplug_gate_sum.footer[0].action.value': '⟦Ñîçé. Ţĥé àþþ šţàýš çļöšéð.~~~~~~~~~⟧',
  'sf_unplug_gate_sum.footer[0].label': '⟦Ķééþ îţ çļöšéð~~~~~⟧',
  'sf_unplug_gate_sum.footer[1].label': '⟦Öþéñ îţ ƒöŕ 10 ɱîñûţéš~~~~~~~⟧',
  'sf_unplug_gate_sum.footer[1].action.cases[0].action.value': '⟦Öþéñ ƒöŕ 10 ɱîñûţéš. Ţĥé þàûšé šçŕééñ çöɱéš ƀàçķ àƒţéŕ.~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_gate_sum.footer[1].action.cases[1].action.value': '⟦Àñšŵéŕ ţĥé šûɱ ƒîŕšţ.~~~~~~~⟧',
  'sf_unplug_gate_sum.header.title': '⟦Šɱàļļ šţéþ~~~~⟧',
  'sf_unplug_health.body[0].text': '⟦Ûñþļûĝ îš ŵöŕķîñĝ. Àļļ 4 çĥéçķš þàšš.~~~~~~~~~~~~⟧',
  'sf_unplug_health.body[1].items[0].label': '⟦Šçŕééñ Ţîɱé þéŕɱîššîöñ~~~~~~~~⟧',
  'sf_unplug_health.body[1].items[0].sub': '⟦Àļļöŵéð~~~⟧',
  'sf_unplug_health.body[1].items[1].label': '⟦Ðàîļý šçĥéðûļé~~~~~~⟧',
  'sf_unplug_health.body[1].items[1].sub': '⟦Ŕûññîñĝ~~~⟧',
  'sf_unplug_health.body[1].items[2].label': '⟦Šéţţîñĝš šĥàŕéð ŵîţĥ ţĥé þàûšé šçŕééñ~~~~~~~~~~~~~⟧',
  'sf_unplug_health.body[1].items[2].sub': '⟦Ŕéàðý~~⟧',
  'sf_unplug_health.body[1].items[3].label': '⟦Ñöţîƒîçàţîöñš~~~~~~⟧',
  'sf_unplug_health.body[1].items[3].sub': '⟦Öñ · ļéţš ţĥé þàûšé šçŕééñ öþéñ Ţéţĥéŕ ƒöŕ šûþþöŕţ~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_health.body[1].label': '⟦îÞĥöñé çĥéçķš~~~~~⟧',
  'sf_unplug_health.body[2].text': '⟦Îƒ à çĥéçķ ƒàîļš, Ûñþļûĝ šţöþš çöûñţîñĝ àñð þàûšîñĝ. Ŵé’ļļ ţéļļ ýöû îñšţéàð öƒ ļéţţîñĝ ýöû ţĥîñķ îţ’š šţîļļ öñ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_health.footer[0].label': '⟦Ðöñé~~⟧',
  'sf_unplug_health.header.title': '⟦Ţŕàçķîñĝ çĥéçķ~~~~~~⟧',
  'sf_unplug_health_notifications.body[0].text': '⟦Ñöţîƒîçàţîöñš àŕé öƒƒ. Ûñþļûĝ šţîļļ þàûšéš àþþš, ƀûţ ţĥé þàûšé šçŕééñ çàñ’ţ öþéñ Ţéţĥéŕ ƒöŕ ýöû. Öþéñ Ţéţĥéŕ ýöûŕšéļƒ ƒöŕ šûþþöŕţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_health_notifications.body[1].items[0].label': '⟦Šçŕééñ Ţîɱé þéŕɱîššîöñ~~~~~~~~⟧',
  'sf_unplug_health_notifications.body[1].items[0].sub': '⟦Àļļöŵéð~~~⟧',
  'sf_unplug_health_notifications.body[1].items[1].label': '⟦Ðàîļý šçĥéðûļé~~~~~~⟧',
  'sf_unplug_health_notifications.body[1].items[1].sub': '⟦Ŕûññîñĝ~~~⟧',
  'sf_unplug_health_notifications.body[1].items[2].label': '⟦Šéţţîñĝš šĥàŕéð ŵîţĥ ţĥé þàûšé šçŕééñ~~~~~~~~~~~~~⟧',
  'sf_unplug_health_notifications.body[1].items[2].sub': '⟦Ŕéàðý~~⟧',
  'sf_unplug_health_notifications.body[1].items[3].label': '⟦Ñöţîƒîçàţîöñš~~~~~~⟧',
  'sf_unplug_health_notifications.body[1].items[3].sub': '⟦Öƒƒ îñ Šéţţîñĝš~~~~~~⟧',
  'sf_unplug_health_notifications.body[1].label': '⟦Çĥéçķš~~~⟧',
  'sf_unplug_health_notifications.footer[0].label': '⟦Öþéñ þĥöñé šéţţîñĝš~~~~~~~⟧',
  'sf_unplug_health_notifications.footer[1].action.cases[1].action.value': '⟦Ñöţîƒîçàţîöñš àŕé šţîļļ öƒƒ.~~~~~~~~~~⟧',
  'sf_unplug_health_notifications.footer[1].label': '⟦Çĥéçķ àĝàîñ~~~~⟧',
  'sf_unplug_health_notifications.header.title': '⟦Ţŕàçķîñĝ çĥéçķ~~~~~~⟧',
  'sf_unplug_health_stopped.body[0].text': '⟦Ûñþļûĝ ĥàš šţöþþéð. Ñöţĥîñĝ îš ƀéîñĝ çöûñţéð öŕ þàûšéð ûñţîļ ţĥîš îš ƒîẋéð.~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_health_stopped.body[1].items[0].label': '⟦Šçŕééñ Ţîɱé þéŕɱîššîöñ~~~~~~~~⟧',
  'sf_unplug_health_stopped.body[1].items[0].sub': '⟦Ţûŕñéð öƒƒ îñ Šéţţîñĝš~~~~~~~~⟧',
  'sf_unplug_health_stopped.body[1].items[1].label': '⟦Ðàîļý šçĥéðûļé~~~~~~⟧',
  'sf_unplug_health_stopped.body[1].items[1].sub': '⟦Ŕûññîñĝ~~~⟧',
  'sf_unplug_health_stopped.body[1].items[2].label': '⟦Šéţţîñĝš šĥàŕéð ŵîţĥ ţĥé þàûšé šçŕééñ~~~~~~~~~~~~~⟧',
  'sf_unplug_health_stopped.body[1].items[2].sub': '⟦Ŕéàðý~~⟧',
  'sf_unplug_health_stopped.body[1].label': '⟦îÞĥöñé çĥéçķš~~~~~⟧',
  'sf_unplug_health_stopped.footer[0].label': '⟦Öþéñ þĥöñé šéţţîñĝš~~~~~~~⟧',
  'sf_unplug_health_stopped.footer[1].action.cases[1].action.value': '⟦Šţîļļ ñöţ ŵöŕķîñĝ. Ţûŕñ Šçŕééñ Ţîɱé àççéšš öñ àĝàîñ îñ Šéţţîñĝš.~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_health_stopped.footer[1].label': '⟦Çĥéçķ àĝàîñ~~~~⟧',
  'sf_unplug_health_stopped.header.title': '⟦Ţŕàçķîñĝ çĥéçķ~~~~~~⟧',
  'sf_unplug_health_android.body[0].text': '⟦Ûñþļûĝ îš ŵöŕķîñĝ. Àļļ 4 çĥéçķš þàšš.~~~~~~~~~~~~⟧',
  'sf_unplug_health_android.body[1].items[0].label': '⟦Ûšàĝé àççéšš~~~~~⟧',
  'sf_unplug_health_android.body[1].items[0].sub': '⟦Öñ~⟧',
  'sf_unplug_health_android.body[1].items[1].label': '⟦Ðîšþļàý öṽéŕ öţĥéŕ àþþš~~~~~~~~⟧',
  'sf_unplug_health_android.body[1].items[1].sub': '⟦Öñ~⟧',
  'sf_unplug_health_android.body[1].items[2].label': '⟦Ûñþļûĝ ŕûññîñĝ îñ ţĥé ƀàçķĝŕöûñð~~~~~~~~~~~~⟧',
  'sf_unplug_health_android.body[1].items[2].sub': '⟦Çĥéçķéð 12 š àĝö~~~~~⟧',
  'sf_unplug_health_android.body[1].items[3].label': '⟦Ñöţîƒîçàţîöñš~~~~~~⟧',
  'sf_unplug_health_android.body[1].items[3].sub': '⟦Öñ · ñééðéð ƒöŕ ţĥé “Ţéţĥéŕ îš ŕûññîñĝ” ñöţîçé~~~~~~~~~~~~~~⟧',
  'sf_unplug_health_android.body[1].label': '⟦Àñðŕöîð çĥéçķš~~~~~~⟧',
  'sf_unplug_health_android.body[2].text': '⟦Šöɱé þĥöñéš šţöþ ƀàçķĝŕöûñð àþþš ţö šàṽé ƀàţţéŕý. Îƒ Ûñþļûĝ ķééþš šţöþþîñĝ, ļéţ Ţéţĥéŕ ŕûñ îñ ţĥé ƀàçķĝŕöûñð.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_health_android.footer[0].label': '⟦Ɓàţţéŕý šéţţîñĝš~~~~~~⟧',
  'sf_unplug_health_android.footer[1].label': '⟦Ðöñé~~⟧',
  'sf_unplug_health_android.header.title': '⟦Ţŕàçķîñĝ çĥéçķ~~~~~~⟧',
  'sf_unplug_off.body[0].text': '⟦Ţûŕñ öƒƒ Ûñþļûĝ?~~~~~~⟧',
  'sf_unplug_off.body[1].text': '⟦Þàûšéð àþþš öþéñ ñöŕɱàļļý àĝàîñ. Ýöûŕ ŠçŕöļļƑŕéé ĝöàļ, çĥéçķ-îñš àñð Þàûšé 60 šţàý.~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_off.body[2].items[0].label': '⟦Ûñþļûĝ öñļý~~~~⟧',
  'sf_unplug_off.body[2].items[0].sub': '⟦Ŕéɱöṽéš àþþ çĥöîçéš, ļîɱîţš àñð šéššîöñ ĥîšţöŕý ƒŕöɱ ţĥîš þĥöñé~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_unplug_off.body[2].items[0].badge': '⟦Ðéƒàûļţ~~~⟧',
  'sf_unplug_off.body[2].items[1].label': '⟦Ûñþļûĝ àñð Šçŕééñ Ţîɱé àççéšš~~~~~~~~~~⟧',
  'sf_unplug_off.body[2].items[1].sub': '⟦ŠçŕöļļƑŕéé ĝöéš ƀàçķ ţö ýöûŕ öŵñ éšţîɱàţéš~~~~~~~~~~~~~~~⟧',
  'sf_unplug_off.footer[0].action.cases[0].action.then.value': '⟦Ûñþļûĝ îš öƒƒ~~~~~⟧',
  'sf_unplug_off.footer[0].action.cases[1].action.then.value': '⟦Ûñþļûĝ àñð Šçŕééñ Ţîɱé àŕé öƒƒ~~~~~~~~~~⟧',
  'sf_unplug_off.footer[0].label': '⟦Ţûŕñ öƒƒ~~~⟧',
  'sf_unplug_off.footer[1].label': '⟦Çàñçéļ~~~⟧',
  'sf_home_unplug.body[0].label': '⟦Šçŕééñ Ţîɱé ţöðàý~~~~~~⟧',
  'sf_home_unplug.body[0].caption': '⟦Šĥöŵñ ƀý Àþþļé’š Šçŕééñ Ţîɱé öñ ţĥîš þĥöñé. Ţéţĥéŕ çàñ’ţ ŕéàð, šţöŕé öŕ šĥàŕé ţĥéšé ɱîñûţéš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_home_unplug.body[1].eyebrow': '⟦Ýéšţéŕðàý · ýöûŕ éšţîɱàţé~~~~~~~~~⟧',
  'sf_home_unplug.body[1].children[0].value': '⟦2ĥ 10ɱ~⟧',
  'sf_home_unplug.body[1].children[0].caption': '⟦Ĝöàļ 90 ɱîñ · ðöŵñ ƒŕöɱ 3ĥ~~~~~~~⟧',
  'sf_home_unplug.body[2].title': '⟦Ûŕĝé ţö šçŕöļļ?~~~~~⟧',
  'sf_home_unplug.body[2].text': '⟦Ţàķé 60 šéçöñðš ƒîŕšţ~~~~~~~⟧',
  'sf_home_unplug.body[2].cta[0].label': '⟦Þàûšé 60~~⟧',
  'sf_home_unplug.body[3].title': '⟦Ûñþļûĝ îš öñ~~~~⟧',
  'sf_home_unplug.body[3].text': '⟦2 ĝŕöûþš · þàûšé šçŕééñ àƒţéŕ 60 ɱîñ~~~~~~~~~~⟧',
  'sf_home_unplug.body[4].eyebrow': '⟦Ţöðàý’š šţéþ~~~~⟧',
  'sf_home_unplug.body[4].children[0].items[0].label': '⟦Çĥàŕĝé ýöûŕ þĥöñé öûţšîðé ţĥé ƀéðŕööɱ~~~~~~~~~~~~~⟧',
  'sf_home_unplug.body[4].children[0].items[0].sub': '⟦Ţöñîĝĥţ · ƀéðţîɱé ŵîñðöŵ 10 ÞṀ~~~~~~~~~⟧',
  'sf_home_unplug.body[5].rows[0].label': '⟦Ţĥîš ŵééķ~~~~⟧',
  'sf_home_unplug.body[5].rows[0].sub': '⟦5 öƒ 7 þĥöñé-ƒŕéé ñîĝĥţš~~~~~~~⟧',
  'sf_home_unplug.body[5].rows[1].label': '⟦Ĥàð à ļöñĝ šçŕöļļ?~~~~~~⟧',
  'sf_home_unplug.body[5].rows[1].sub': '⟦Ŕéƒļéçţ, ñöţĥîñĝ ŕéšéţš~~~~~~~~⟧',
  'sf_home_unplug.body[5].rows[2].label': '⟦Ĝöàļ & ŵîñðöŵš~~~~~⟧',
  'sf_home_unplug.body[5].rows[2].sub': '⟦90 ɱîñ · ƀéðţîɱé~~~~⟧',
  'sf_home_unplug.body[5].rows[3].label': '⟦Ɓûððý~~⟧',
  'sf_home_unplug.body[5].rows[3].sub': '⟦Šàɱ · ŵééķļý ɱéššàĝé~~~~~~~⟧',
  'sf_home_unplug.body[5].rows[4].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'sf_home_unplug.body[5].rows[4].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'sf_home_unplug_android.body[0].eyebrow': '⟦Ýéšţéŕðàý · ɱéàšûŕéð öñ ţĥîš þĥöñé~~~~~~~~~~~~⟧',
  'sf_home_unplug_android.body[0].children[0].value': '⟦2ĥ 10ɱ~⟧',
  'sf_home_unplug_android.body[0].children[0].caption': '⟦Ĝöàļ 90 ɱîñ · ðöŵñ ƒŕöɱ 3ĥ~~~~~~~⟧',
  'sf_home_unplug_android.body[1].items[0].label': '⟦Ţöðàý šö ƒàŕ~~~~⟧',
  'sf_home_unplug_android.body[1].items[0].value': '⟦48 ɱîñ~~⟧',
  'sf_home_unplug_android.body[1].items[0].sub': '⟦Šĥöŕţ ṽîðéö àñð Ƒééðš~~~~~~~~⟧',
  'sf_home_unplug_android.body[1].items[1].label': '⟦Öþéñš ţöðàý~~~~⟧',
  'sf_home_unplug_android.body[1].items[1].sub': '⟦Öñ ţĥîš þĥöñé öñļý · þàûšé šçŕééñ àƒţéŕ 20~~~~~~~~~~~~~⟧',
  'sf_home_unplug_android.body[2].text': '⟦Ṁéàšûŕéð ƀý Ţéţĥéŕ öñ ţĥîš þĥöñé ŵîţĥ ûšàĝé àççéšš. Öñļý ðàîļý ţöţàļš ƀý çàţéĝöŕý àŕé šàṽéð ţö ýöûŕ àççöûñţ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_home_unplug_android.body[3].title': '⟦Ûŕĝé ţö šçŕöļļ?~~~~~⟧',
  'sf_home_unplug_android.body[3].text': '⟦Ţàķé 60 šéçöñðš ƒîŕšţ~~~~~~~⟧',
  'sf_home_unplug_android.body[3].cta[0].label': '⟦Þàûšé 60~~⟧',
  'sf_home_unplug_android.body[4].title': '⟦Ûñþļûĝ îš öñ~~~~⟧',
  'sf_home_unplug_android.body[4].text': '⟦2 ĝŕöûþš · þàûšé šçŕééñ àƒţéŕ 60 ɱîñ öŕ 20 öþéñš~~~~~~~~~~~~~⟧',
  'sf_home_unplug_android.body[5].eyebrow': '⟦Ţöðàý’š šţéþ~~~~⟧',
  'sf_home_unplug_android.body[5].children[0].items[0].label': '⟦Çĥàŕĝé ýöûŕ þĥöñé öûţšîðé ţĥé ƀéðŕööɱ~~~~~~~~~~~~~⟧',
  'sf_home_unplug_android.body[5].children[0].items[0].sub': '⟦Ţöñîĝĥţ · ƀéðţîɱé ŵîñðöŵ 10 ÞṀ~~~~~~~~~⟧',
  'sf_home_unplug_android.body[6].rows[0].label': '⟦Ţĥîš ŵééķ~~~~⟧',
  'sf_home_unplug_android.body[6].rows[0].sub': '⟦5 öƒ 7 þĥöñé-ƒŕéé ñîĝĥţš~~~~~~~⟧',
  'sf_home_unplug_android.body[6].rows[1].label': '⟦Ĥàð à ļöñĝ šçŕöļļ?~~~~~~⟧',
  'sf_home_unplug_android.body[6].rows[1].sub': '⟦Ŕéƒļéçţ, ñöţĥîñĝ ŕéšéţš~~~~~~~~⟧',
  'sf_home_unplug_android.body[6].rows[2].label': '⟦Ĝöàļ & ŵîñðöŵš~~~~~⟧',
  'sf_home_unplug_android.body[6].rows[2].sub': '⟦90 ɱîñ · ƀéðţîɱé~~~~⟧',
  'sf_home_unplug_android.body[6].rows[3].label': '⟦Ɓûððý~~⟧',
  'sf_home_unplug_android.body[6].rows[3].sub': '⟦Šàɱ · ŵééķļý ɱéššàĝé~~~~~~~⟧',
  'sf_home_unplug_android.body[6].rows[4].label': '⟦Þŕöĝŕàɱ šéţţîñĝš~~~~~~⟧',
  'sf_home_unplug_android.body[6].rows[4].sub': '⟦Šţàţûš, šĥàŕîñĝ, éẋþöŕţ, ļéàṽé~~~~~~~~~~⟧',
  'sf_week_unplug.body[0].text': '⟦Ýöûŕ ŵééķ, ĥöñéšţļý.~~~~~~~⟧',
  'sf_week_unplug.body[1].label': '⟦Šçŕééñ Ţîɱé ţĥîš ŵééķ~~~~~~~~⟧',
  'sf_week_unplug.body[1].caption': '⟦Šĥöŵñ ƀý Àþþļé’š Šçŕééñ Ţîɱé öñ ţĥîš þĥöñé. Ţéţĥéŕ çàñ’ţ ŕéàð, šţöŕé öŕ šĥàŕé ţĥéšé ɱîñûţéš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_week_unplug.body[2].title': '⟦Ýöûŕ éšţîɱàţéš · ɱîñûţéš / ðàý~~~~~~~~~~⟧',
  'sf_week_unplug.body[2].caption': '⟦Ţĥûŕšðàý: ñö çĥéçķ-îñ · ñöţ çöûñţéð àš žéŕö~~~~~~~~~~~~~~⟧',
  'sf_week_unplug.body[2].labels[0]': '⟦Ṁ~⟧',
  'sf_week_unplug.body[2].labels[1]': '⟦Ţ~⟧',
  'sf_week_unplug.body[2].labels[2]': '⟦Ŵ~⟧',
  'sf_week_unplug.body[2].labels[3]': '⟦Ţ~⟧',
  'sf_week_unplug.body[2].labels[4]': '⟦Ƒ~⟧',
  'sf_week_unplug.body[2].labels[5]': '⟦Š~⟧',
  'sf_week_unplug.body[2].labels[6]': '⟦Š~⟧',
  'sf_week_unplug.body[3].items[0].label': '⟦Þĥöñé-ƒŕéé ñîĝĥţš~~~~~~⟧',
  'sf_week_unplug.body[3].items[1].label': '⟦Ûŕĝéš þàûšéð~~~~~⟧',
  'sf_week_unplug.body[3].items[1].sub': '⟦7 þûţ ðöŵñ~~~⟧',
  'sf_week_unplug.body[4].eyebrow': '⟦Ýöû šàîð~~~⟧',
  'sf_week_unplug.body[4].text': '⟦“Ðŕàîñéð” ŵàš 4× ļéšš çöɱɱöñ öñ þĥöñé-ƒŕéé ñîĝĥţš.~~~~~~~~~~~~~~~⟧',
  'sf_week_unplug.body[4].children[0].text': '⟦Î ƒééļ ðŕàîñéð àƒţéŕ ļöñĝ šçŕöļļš.~~~~~~~~~~~~⟧',
  'sf_week_unplug.body[5].eyebrow': '⟦Ñéẋţ ŵééķ~~~~⟧',
  'sf_week_unplug.body[5].title': '⟦Šţéþ ðöŵñ ţö 75 ɱîñ?~~~~~~⟧',
  'sf_week_unplug.body[5].children[0].items[0].action.value': '⟦Ĝöàļ šéţ ţö 75 ɱîñ~~~~~⟧',
  'sf_week_unplug.body[5].children[0].items[0].label': '⟦Ýéš~~⟧',
  'sf_week_unplug.body[5].children[0].items[1].label': '⟦Šţàý àţ 90~~~⟧',
  'sf_week_unplug.header.title': '⟦Ŵééķ 2~~⟧',
  'program_settings_sf.body[0].rows[0].sub': '⟦Ƒöçûš šîñçé Àûĝ 14~~~~~~⟧',
  'program_settings_sf.body[1].items[0].label': '⟦Ƒöçûš~~⟧',
  'program_settings_sf.body[1].items[0].sub': '⟦Ðàîļý šţéþš àñð ŕéɱîñðéŕš~~~~~~~~~⟧',
  'program_settings_sf.body[1].items[1].label': '⟦Ļéàŕñ öñļý~~~~⟧',
  'program_settings_sf.body[1].items[1].sub': '⟦Ķééþ ļéššöñš, šţöþ ţŕàçķîñĝ~~~~~~~~~~⟧',
  'program_settings_sf.body[1].items[2].label': '⟦Þàûšé~~⟧',
  'program_settings_sf.body[1].items[2].sub': '⟦Šţöþ ŕéɱîñðéŕš; ķééþ éṽéŕýţĥîñĝ~~~~~~~~~~~⟧',
  'program_settings_sf.body[1].label': '⟦Šţàţûš~~~⟧',
  'program_settings_sf.body[2].eyebrow': '⟦Šĥàŕîñĝ~~~⟧',
  'program_settings_sf.body[2].children[0].label': '⟦Çàŕé ţéàɱ šĥàŕîñĝ~~~~~~⟧',
  'program_settings_sf.body[2].children[0].sub': '⟦Öƒƒ · ŠçŕöļļƑŕéé îšñ’ţ šĥàŕéð~~~~~~~~~~⟧',
  'program_settings_sf.body[2].children[1].label': '⟦Ðé-îðéñţîƒîéð ŕéšéàŕçĥ~~~~~~~~⟧',
  'program_settings_sf.body[3].rows[0].sub': '⟦Öñ · 2 ĝŕöûþš · 60 ɱîñ ļîɱîţ~~~~~~~⟧',
  'program_settings_sf.body[3].rows[1].label': '⟦Šçŕééñ Ţîɱé àççéšš~~~~~~~⟧',
  'program_settings_sf.body[3].rows[1].sub': '⟦Çöññéçţéð · ţöţàļš öñļý~~~~~~~~⟧',
  'program_settings_sf.body[3].rows[2].label': '⟦Ţûŕñ öƒƒ Ûñþļûĝ öŕ Šçŕééñ Ţîɱé~~~~~~~~~~⟧',
  'program_settings_sf.body[3].rows[2].sub': '⟦Àñýţîɱé~~~⟧',
  'program_settings_sf.body[3].title': '⟦Šçŕééñ Ţîɱé & Ûñþļûĝ~~~~~~~⟧',
  'program_settings_sf.body[4].rows[0].label': '⟦Éẋþöŕţ ŠçŕöļļƑŕéé ðàţà~~~~~~~~⟧',
  'program_settings_sf.body[4].rows[0].sub': '⟦ÞÐƑ + ĴŠÖÑ~~~⟧',
  'program_settings_sf.body[4].rows[0].action.value': '⟦Éẋþöŕţ îš ƀéîñĝ þŕéþàŕéð. Ŵé’ļļ ñöţîƒý ýöû.~~~~~~~~~~~~~~⟧',
  'program_settings_sf.body[4].rows[1].label': '⟦Ļéàṽé ŠçŕöļļƑŕéé~~~~~~⟧',
  'program_settings_sf.body[4].rows[1].sub': '⟦Ķééþ ýöûŕ ðàţà öŕ ðéļéţé îţ ñöŵ~~~~~~~~~~⟧',
  'program_settings_sf.body[4].title': '⟦Ðàţà~~⟧',
  'program_settings_sf.footer[0].action.then.value': '⟦Šàṽéð~~⟧',
  'program_settings_sf.footer[0].label': '⟦Šàṽé çĥàñĝéš~~~~~⟧',
  'program_settings_sf.header.title': '⟦ŠçŕöļļƑŕéé šéţţîñĝš~~~~~~~~⟧',
  'account_delete_apple.body[0].text': '⟦Ðéļéţé ýöûŕ àççöûñţ àñð àļļ ðàţà?~~~~~~~~~~~⟧',
  'account_delete_apple.body[1].rows[0][0]': '⟦Þŕöĝŕàɱš~~~~⟧',
  'account_delete_apple.body[1].rows[1][0]': '⟦Çĥéçķ-îñš~~~~⟧',
  'account_delete_apple.body[1].rows[2][0]': '⟦Ŕéàðîñĝš & ļöĝš~~~~~⟧',
  'account_delete_apple.body[1].rows[3][0]': '⟦Šĥàŕéð ŵîţĥ çàŕé ţéàɱ~~~~~~~~⟧',
  'account_delete_apple.body[1].rows[3][1]': '⟦3 šûɱɱàŕîéš (ţĥéîŕ çöþîéš šţàý ŵîţĥ ţĥéɱ)~~~~~~~~~~~~~⟧',
  'account_delete_apple.body[2].text': '⟦Ţĥîš çàñ’ţ ƀé ûñðöñé. Ðöŵñļöàð à çöþý ƒîŕšţ îƒ ýöû ŵàñţ öñé.~~~~~~~~~~~~~~~~~~~⟧',
  'account_delete_apple.body[3].label': '⟦Ðöŵñļöàð à çöþý ƒîŕšţ~~~~~~~~⟧',
  'account_delete_apple.body[4].label': '⟦Ţýþé ÐÉĻÉŢÉ ţö çöñƒîŕɱ~~~~~~~~⟧',
  'account_delete_apple.body[4].placeholder': '⟦ÐÉĻÉŢÉ~~~⟧',
  'account_delete_apple.body[5].eyebrow': '⟦Çöñƒîŕɱ îţ’š ýöû~~~~~~⟧',
  'account_delete_apple.body[5].title': '⟦Šîĝñéð îñ ŵîţĥ Àþþļé~~~~~~~⟧',
  'account_delete_apple.body[5].text': '⟦Ŵĥéñ ýöû ţàþ Ðéļéţé éṽéŕýţĥîñĝ, Àþþļé àšķš ýöû ţö çöñƒîŕɱ. Ûšé ţĥé šàɱé Àþþļé àççöûñţ ýöû šîĝñéð îñ ŵîţĥ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'account_delete_apple.footer[0].action.cases[1].action.value': '⟦Ţĥàţ’š à ðîƒƒéŕéñţ Àþþļé àççöûñţ. Ûšé ţĥé öñé ýöû šîĝñéð îñ ŵîţĥ.~~~~~~~~~~~~~~~~~~~~~⟧',
  'account_delete_apple.footer[0].action.cases[2].action.value': '⟦Ñöţĥîñĝ ŵàš ðéļéţéð.~~~~~~~⟧',
  'account_delete_apple.footer[0].action.cases[3].action.value': '⟦Çöûļðñ’ţ ŕéàçĥ Àþþļé. Ñöţĥîñĝ ŵàš ðéļéţéð.~~~~~~~~~~~~~~⟧',
  'account_delete_apple.footer[0].label': '⟦Ðéļéţé éṽéŕýţĥîñĝ~~~~~~~⟧',
  'account_delete_apple.header.title': '⟦Ðéļéţé àççöûñţ~~~~~~⟧',
  'account_delete_google.body[0].text': '⟦Ðéļéţé ýöûŕ àççöûñţ àñð àļļ ðàţà?~~~~~~~~~~~⟧',
  'account_delete_google.body[1].rows[0][0]': '⟦Þŕöĝŕàɱš~~~~⟧',
  'account_delete_google.body[1].rows[1][0]': '⟦Çĥéçķ-îñš~~~~⟧',
  'account_delete_google.body[1].rows[2][0]': '⟦Ŕéàðîñĝš & ļöĝš~~~~~⟧',
  'account_delete_google.body[1].rows[3][0]': '⟦Šĥàŕéð ŵîţĥ çàŕé ţéàɱ~~~~~~~~⟧',
  'account_delete_google.body[1].rows[3][1]': '⟦3 šûɱɱàŕîéš (ţĥéîŕ çöþîéš šţàý ŵîţĥ ţĥéɱ)~~~~~~~~~~~~~⟧',
  'account_delete_google.body[2].text': '⟦Ţĥîš çàñ’ţ ƀé ûñðöñé. Ðöŵñļöàð à çöþý ƒîŕšţ îƒ ýöû ŵàñţ öñé.~~~~~~~~~~~~~~~~~~~⟧',
  'account_delete_google.body[3].label': '⟦Ðöŵñļöàð à çöþý ƒîŕšţ~~~~~~~~⟧',
  'account_delete_google.body[4].label': '⟦Ţýþé ÐÉĻÉŢÉ ţö çöñƒîŕɱ~~~~~~~~⟧',
  'account_delete_google.body[4].placeholder': '⟦ÐÉĻÉŢÉ~~~⟧',
  'account_delete_google.body[5].eyebrow': '⟦Çöñƒîŕɱ îţ’š ýöû~~~~~~⟧',
  'account_delete_google.body[5].title': '⟦Šîĝñéð îñ ŵîţĥ Ĝööĝļé~~~~~~~~⟧',
  'account_delete_google.body[5].text': '⟦Ŵĥéñ ýöû ţàþ Ðéļéţé éṽéŕýţĥîñĝ, Ĝööĝļé àšķš ýöû ţö çöñƒîŕɱ. Ûšé ţĥé šàɱé Ĝööĝļé àççöûñţ ýöû šîĝñéð îñ ŵîţĥ.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'account_delete_google.footer[0].action.cases[1].action.value': '⟦Ţĥàţ’š à ðîƒƒéŕéñţ Ĝööĝļé àççöûñţ. Ûšé ţĥé öñé ýöû šîĝñéð îñ ŵîţĥ.~~~~~~~~~~~~~~~~~~~~~⟧',
  'account_delete_google.footer[0].action.cases[2].action.value': '⟦Ñöţĥîñĝ ŵàš ðéļéţéð.~~~~~~~⟧',
  'account_delete_google.footer[0].action.cases[3].action.value': '⟦Çöûļðñ’ţ ŕéàçĥ Ĝööĝļé. Ñöţĥîñĝ ŵàš ðéļéţéð.~~~~~~~~~~~~~~⟧',
  'account_delete_google.footer[0].label': '⟦Ðéļéţé éṽéŕýţĥîñĝ~~~~~~~⟧',
  'account_delete_google.header.title': '⟦Ðéļéţé àççöûñţ~~~~~~⟧',
  'auth_session_apple.body[0].text': '⟦Þļéàšé šîĝñ îñ àĝàîñ~~~~~~~⟧',
  'auth_session_apple.body[1].text': '⟦Ƒöŕ ýöûŕ šéçûŕîţý, šéššîöñš éñð àƒţéŕ 30 ðàýš.~~~~~~~~~~~~~~⟧',
  'auth_session_apple.body[2].text': '⟦Ýöû šîĝñéð îñ ŵîţĥ Àþþļé, šö ţĥéŕé’š ñö þàššŵöŕð ţö ţýþé.~~~~~~~~~~~~~~~~~~⟧',
  'auth_session_apple.footer[0].items[0].label': '⟦Çöñţîñûé ŵîţĥ Àþþļé~~~~~~~⟧',
  'auth_session_apple.footer[0].items[0].action.cases[1].action.value': '⟦Šţîļļ šîĝñéð öûţ. Ŕéšçûé ŵöŕķš ŵîţĥöûţ šîĝñîñĝ îñ.~~~~~~~~~~~~~~~~~⟧',
  'auth_session_apple.footer[1].label': '⟦Ûšé Ƒàçé ÎÐ~~~~⟧',
  'auth_session_google.body[0].text': '⟦Þļéàšé šîĝñ îñ àĝàîñ~~~~~~~⟧',
  'auth_session_google.body[1].text': '⟦Ƒöŕ ýöûŕ šéçûŕîţý, šéššîöñš éñð àƒţéŕ 30 ðàýš.~~~~~~~~~~~~~~⟧',
  'auth_session_google.body[2].text': '⟦Ýöû šîĝñéð îñ ŵîţĥ Ĝööĝļé, šö ţĥéŕé’š ñö þàššŵöŕð ţö ţýþé.~~~~~~~~~~~~~~~~~~⟧',
  'auth_session_google.footer[0].items[0].label': '⟦Çöñţîñûé ŵîţĥ Ĝööĝļé~~~~~~~~⟧',
  'auth_session_google.footer[0].items[0].action.cases[1].action.value': '⟦Šţîļļ šîĝñéð öûţ. Ŕéšçûé ŵöŕķš ŵîţĥöûţ šîĝñîñĝ îñ.~~~~~~~~~~~~~~~~~⟧',
  'auth_session_google.footer[1].label': '⟦Ûšé Ƒàçé ÎÐ~~~~⟧',
  'sf_screentime_android.body[1].text': '⟦Šéé ŕéàļ ţöţàļš, îƒ ýöû ŵàñţ.~~~~~~~~~⟧',
  'sf_screentime_android.body[2].text': '⟦Ţéţĥéŕ ŕéàðš ðàîļý ţöţàļš ƀý çàţéĝöŕý öñļý. Ñéṽéŕ àþþš’ çöñţéñţ, ɱéššàĝéš öŕ çöñţàçţš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_screentime_android.body[3].rows[0][0]': '⟦Ŕéàðš~~⟧',
  'sf_screentime_android.body[3].rows[0][1]': '⟦Ṁîñûţéš þéŕ çàţéĝöŕý~~~~~~~~⟧',
  'sf_screentime_android.body[3].rows[1][0]': '⟦Ñéṽéŕ ŕéàðš~~~~⟧',
  'sf_screentime_android.body[3].rows[1][1]': '⟦Çöñţéñţ, ɱéššàĝéš, çöñţàçţš~~~~~~~~~~⟧',
  'sf_screentime_android.body[3].rows[2][0]': '⟦Ţûŕñ öƒƒ~~~⟧',
  'sf_screentime_android.body[3].rows[2][1]': '⟦Àñýţîɱé îñ Àççöûñţ~~~~~~~⟧',
  'sf_screentime_android.body[4].items[0].label': '⟦Ţàþ Öþéñ šéţţîñĝš~~~~~~⟧',
  'sf_screentime_android.body[4].items[1].label': '⟦Ƒîñð Ţéţĥéŕ Ĥéàļţĥ~~~~~~~⟧',
  'sf_screentime_android.body[4].items[2].label': '⟦Ţûŕñ öñ “Þéŕɱîţ ûšàĝé àççéšš”~~~~~~~~~~⟧',
  'sf_screentime_android.body[4].label': '⟦Àñðŕöîð àšķš îñ Šéţţîñĝš~~~~~~~~~⟧',
  'sf_screentime_android.footer[0].action.cases[0].action.value': '⟦Ûšàĝé àççéšš öñ~~~~~~⟧',
  'sf_screentime_android.footer[0].label': '⟦Öþéñ šéţţîñĝš~~~~~⟧',
  'sf_screentime_android.footer[1].label': '⟦Ñöţ ñöŵ~~~⟧',
  'sf_screentime_android.header.title': '⟦Šçŕééñ Ţîɱé~~~~⟧',
  'sf_screentime_android.header.pill': '⟦Öþţîöñàļ~~~~⟧',
  'sf_screentime_android_denied.body[0].text': '⟦Ûšàĝé àççéšš îš šţîļļ öƒƒ.~~~~~~~~~⟧',
  'sf_screentime_android_denied.body[1].text': '⟦Šéļƒ-ŕéþöŕţ ŵöŕķš ĵûšţ àš ŵéļļ.~~~~~~~~~~⟧',
  'sf_screentime_android_denied.body[2].text': '⟦Ŵé’ļļ àšķ ƒöŕ à ǫûîçķ éšţîɱàţé îñ ýöûŕ éṽéñîñĝ çĥéçķ-îñ. Ýöû çàñ çöññéçţ ļàţéŕ îñ Àççöûñţ → ŠçŕöļļƑŕéé.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sf_screentime_android_denied.footer[0].label': '⟦Çöñţîñûé ŵîţĥ šéļƒ-ŕéþöŕţ~~~~~~~~~⟧',
  'sf_screentime_android_denied.footer[1].label': '⟦Öþéñ šéţţîñĝš~~~~~⟧',
  'sf_screentime_android_denied.header.title': '⟦Šçŕééñ Ţîɱé~~~~⟧',
  'sf_screentime_android_denied.header.pill': '⟦Öþţîöñàļ~~~~⟧',
  'sys_update_android.body[1].text': '⟦À šàƒéţý ûþðàţé îš ŕéàðý~~~~~~~~⟧',
  'sys_update_android.body[2].text': '⟦Ţĥîš ṽéŕšîöñ ĥàš îɱþöŕţàñţ ƒîẋéš. Ŕéšçûé àñð Šûþþöŕţ šţîļļ ŵöŕķ ûñţîļ ýöû ûþðàţé.~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'sys_update_android.footer[0].label': '⟦Ûþðàţé ñöŵ~~~~⟧',
  'sys_update_android.footer[1].label': '⟦Öþéñ Ŕéšçûé~~~~⟧',
  'sys_update_android.header.title': '⟦Ûþðàţé ñééðéð~~~~~⟧',
  'surface_widget_ios.body[0].title': '⟦Ŕéšçûé~~~⟧',
  'surface_widget_ios.body[0].text': '⟦Ĥéļþ ƒöŕ ţĥé ñéẋţ ƒéŵ ɱîñûţéš~~~~~~~~~~⟧',
  'surface_widget_ios.header.title': '⟦îÞĥöñé ŵîðĝéţ~~~~~⟧',
  'surface_widget_android.body[0].title': '⟦Ŕéšçûé~~~⟧',
  'surface_widget_android.body[0].text': '⟦Ĥéļþ ƒöŕ ţĥé ñéẋţ ƒéŵ ɱîñûţéš~~~~~~~~~~⟧',
  'surface_widget_android.header.title': '⟦Àñðŕöîð ŵîðĝéţ~~~~~~⟧',
  'surface_shortcuts_ios.body[0].rows[0].label': '⟦Ŕéšçûé~~~⟧',
  'surface_shortcuts_ios.body[0].rows[0].sub': '⟦“Ŕéšçûé îñ Ţéţĥéŕ” · öþéñš Ŕéšçûé~~~~~~~~~~⟧',
  'surface_shortcuts_ios.body[0].rows[1].label': '⟦Ṁý þļàñ~~~⟧',
  'surface_shortcuts_ios.body[0].rows[1].sub': '⟦“Šĥöŵ ɱý þļàñ îñ Ţéţĥéŕ” · öñļý ŵĥîļé ÇļéàŕÀîŕ îš à ƒöçûš þŕöĝŕàɱ~~~~~~~~~~~~~~~~~~~~⟧',
  'surface_shortcuts_ios.body[0].title': '⟦Ţéţĥéŕ Ĥéàļţĥ · Àþþ Šĥöŕţçûţš~~~~~~~~~~⟧',
  'surface_shortcuts_ios.body[1].text': '⟦Ļàƀéļš šţàý ĝéñéŕîç šö à ļöçķéð þĥöñé ðöéšñ’ţ ŕéṽéàļ ŵĥîçĥ þŕöĝŕàɱš ýöû ûšé. Ţûŕñ öñ Šĥöŵ šéñšîţîṽé ðéţàîļš ţö šéé þŕöĝŕàɱ ñàɱéš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'surface_shortcuts_ios.header.title': '⟦Šîŕî & Šĥöŕţçûţš~~~~~~⟧',
  'surface_shortcuts_ios_named.body[0].rows[0].label': '⟦Ŕéšçûé~~~⟧',
  'surface_shortcuts_ios_named.body[0].rows[0].sub': '⟦“Ŕéšçûé îñ Ţéţĥéŕ” · öþéñš Ŕéšçûé~~~~~~~~~~⟧',
  'surface_shortcuts_ios_named.body[0].rows[1].label': '⟦ÇļéàŕÀîŕ ŕéð-žöñé þļàñ~~~~~~~~⟧',
  'surface_shortcuts_ios_named.body[0].rows[1].sub': '⟦“Šĥöŵ ɱý ÇļéàŕÀîŕ þļàñ îñ Ţéţĥéŕ”~~~~~~~~~~~⟧',
  'surface_shortcuts_ios_named.body[0].title': '⟦Ţéţĥéŕ Ĥéàļţĥ · Àþþ Šĥöŕţçûţš~~~~~~~~~~⟧',
  'surface_shortcuts_ios_named.header.title': '⟦Šîŕî & Šĥöŕţçûţš~~~~~~⟧',
  'surface_shortcuts_android.body[0].rows[0].label': '⟦Ŕéšçûé~~~⟧',
  'surface_shortcuts_android.body[0].rows[1].label': '⟦Ṁý þļàñ~~~⟧',
  'surface_shortcuts_android.body[1].text': '⟦Ļàƀéļš šţàý ĝéñéŕîç šö ţĥé ĥöɱé šçŕééñ ðöéšñ’ţ ŕéṽéàļ ŵĥîçĥ þŕöĝŕàɱš ýöû ûšé. Ţûŕñ öñ Šĥöŵ šéñšîţîṽé ðéţàîļš ţö šéé þŕöĝŕàɱ ñàɱéš.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~⟧',
  'surface_shortcuts_android.header.title': '⟦Àþþ šĥöŕţçûţš~~~~~⟧',
  'surface_shortcuts_android_named.body[0].rows[0].label': '⟦Ŕéšçûé~~~⟧',
  'surface_shortcuts_android_named.body[0].rows[1].label': '⟦ÇļéàŕÀîŕ ŕéð-žöñé þļàñ~~~~~~~~⟧',
  'surface_shortcuts_android_named.header.title': '⟦Àþþ šĥöŕţçûţš~~~~~⟧',
};

/// Member-visible literals shown as they are in every language (brands,
/// units, numbers, phone numbers, language names).
const Set<String> tUntranslatedLiterals = <String>{
  ' min',
  '\$42.70',
  '%',
  '(555) 010-2244',
  '(555) 010-4421',
  '0',
  '1',
  '10',
  '11',
  '118',
  '11–20',
  '12 + 36',
  '128',
  '128/82',
  '130',
  '132',
  '132/82',
  '135/85',
  '138',
  '138/86',
  '14',
  '142',
  '14:52',
  '18',
  '180',
  '18–24',
  '19',
  '2',
  '200',
  '200–399',
  '2019',
  '212',
  '21–30',
  '25–34',
  '3',
  '30',
  '310',
  '32:18',
  '35–44',
  '4',
  '400',
  '42',
  '44',
  '45',
  '45–54',
  '46',
  '48',
  '4:12',
  '5',
  '5/7',
  '52',
  '55–64',
  '58',
  '60',
  '61',
  '63',
  '65–74',
  '7',
  '7 + 5',
  '7.4',
  '70',
  '71%',
  '72',
  '74',
  '75+',
  '8',
  '80',
  '84',
  '86',
  '911',
  '?',
  'Apple',
  'Apple Health Records',
  'Beacon',
  'BreatheFree',
  'Checkup',
  'ClearAir',
  'Ease',
  'English',
  'Epic MyChart',
  'Español',
  'Google',
  'Health Connect',
  'Heartwise',
  'L/min',
  'Medicare',
  'Nourish',
  'Oracle Health (Cerner)',
  'Renew',
  'ScrollFree',
  'Steady',
  'Stride',
  'Tether Health',
  'U/L',
  'Unplug',
  'bpm',
  'https://fhir.example-health.org/r4',
  'mL/min',
  'mL/min/1.73m²',
  'mg/dL',
  'mg/dL · range ≤ 180',
  'mg/g',
  'min',
  'mmHg',
  'target < 130',
  '••••••••',
  '••••••••••••',
};
