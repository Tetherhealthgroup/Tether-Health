// GENERATED from generator/rules.py → SCENARIOS: end-to-end setups and
// functions for every program, with simulated data entered into real
// fields. Decisions use the same rules as the app (lib/logic/rules.dart).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';
import 'package:tether_ui/screens/account/account_deleted_screen.dart';
import 'package:tether_ui/screens/auth/auth_link_screen.dart';
import 'package:tether_ui/screens/auth/auth_merge_screen.dart';
import 'package:tether_ui/screens/auth/auth_signin_screen.dart';
import 'package:tether_ui/screens/auth/auth_signin_error_screen.dart';
import 'package:tether_ui/screens/auth/auth_social_error_screen.dart';
import 'package:tether_ui/screens/auth/auth_social_new_screen.dart';
import 'package:tether_ui/screens/auth/auth_verify_screen.dart';
import 'package:tether_ui/screens/be/be_home_screen.dart';
import 'package:tether_ui/screens/be/be_survivor_screen.dart';
import 'package:tether_ui/screens/be/be_tx_screen.dart';
import 'package:tether_ui/screens/bf/bf_date_screen.dart';
import 'package:tether_ui/screens/bf/bf_home_screen.dart';
import 'package:tether_ui/screens/bf/bf_home_explore_screen.dart';
import 'package:tether_ui/screens/bf/bf_meds_screen.dart';
import 'package:tether_ui/screens/bf/bf_stepdown_screen.dart';
import 'package:tether_ui/screens/bf/bf_support_screen.dart';
import 'package:tether_ui/screens/ca/ca_home_screen.dart';
import 'package:tether_ui/screens/ca/ca_noplan_screen.dart';
import 'package:tether_ui/screens/ca/ca_plan_screen.dart';
import 'package:tether_ui/screens/ca/ca_red_screen.dart';
import 'package:tether_ui/screens/ca/ca_yellow_screen.dart';
import 'package:tether_ui/screens/ca/ca_zone_screen.dart';
import 'package:tether_ui/screens/today/checkin_done_screen.dart';
import 'package:tether_ui/screens/ck/ck_list_screen.dart';
import 'package:tether_ui/screens/rescue/crisis_screen.dart';
import 'package:tether_ui/screens/ea/ea_home_screen.dart';
import 'package:tether_ui/screens/ea/ea_result_screen.dart';
import 'package:tether_ui/screens/hw/hw_crisis_screen.dart';
import 'package:tether_ui/screens/hw/hw_home_screen.dart';
import 'package:tether_ui/screens/hw/hw_log_error_screen.dart';
import 'package:tether_ui/screens/hw/hw_q1_screen.dart';
import 'package:tether_ui/screens/hw/hw_recheck_screen.dart';
import 'package:tether_ui/screens/hw/hw_result_screen.dart';
import 'package:tether_ui/screens/tabs/learn_screen.dart';
import 'package:tether_ui/screens/nu/nu_home_screen.dart';
import 'package:tether_ui/screens/nu/nu_protect_screen.dart';
import 'package:tether_ui/screens/onboarding/ob_programs_screen.dart';
import 'package:tether_ui/screens/onboarding/ob_setup_screen.dart';
import 'package:tether_ui/screens/plans/plans_screen.dart';
import 'package:tether_ui/screens/tabs/progress_screen.dart';
import 'package:tether_ui/screens/re/re_history_screen.dart';
import 'package:tether_ui/screens/re/re_home_screen.dart';
import 'package:tether_ui/screens/records/records_add_screen.dart';
import 'package:tether_ui/screens/records/records_error_screen.dart';
import 'package:tether_ui/screens/records/records_hub_screen.dart';
import 'package:tether_ui/screens/records/records_importing_screen.dart';
import 'package:tether_ui/screens/records/records_manual_screen.dart';
import 'package:tether_ui/screens/records/records_manual_error_screen.dart';
import 'package:tether_ui/screens/records/records_review_screen.dart';
import 'package:tether_ui/screens/rescue/rescue_active_screen.dart';
import 'package:tether_ui/screens/rescue/rescue_pick_screen.dart';
import 'package:tether_ui/screens/sd/sd_home_screen.dart';
import 'package:tether_ui/screens/sf/sf_goal_screen.dart';
import 'package:tether_ui/screens/sf/sf_home_screen.dart';
import 'package:tether_ui/screens/sf/sf_screentime_denied_screen.dart';
import 'package:tether_ui/screens/unplug/sf_unplug_apps_screen.dart';
import 'package:tether_ui/screens/unplug/sf_unplug_auth_notifications_screen.dart';
import 'package:tether_ui/screens/unplug/sf_unplug_gate_commit_screen.dart';
import 'package:tether_ui/screens/unplug/sf_unplug_gate_sum_screen.dart';
import 'package:tether_ui/screens/unplug/sf_unplug_session_done_early_screen.dart';
import 'package:tether_ui/screens/unplug/sf_unplug_session_end_screen.dart';
import 'package:tether_ui/screens/st/st_home_screen.dart';
import 'package:tether_ui/screens/st/st_log_screen.dart';
import 'package:tether_ui/screens/st/st_low_screen.dart';
import 'package:tether_ui/screens/tabs/support_screen.dart';
import 'package:tether_ui/screens/tabs/support_message_care_screen.dart';
import 'package:tether_ui/screens/today/today_screen.dart';
import 'package:tether_ui/screens/onboarding/welcome_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _start(WidgetTester tester, String route, {bool ios = false}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  TSession.clear();
  TFlow.onboarding = false;
  if (ios) debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  TNav.branchResolver = (context, question, outcomes) async => outcomes.first;
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    onGenerateRoute: (s) => s.name == '/__host' ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: '/__host')),
      AppRouter.onGenerateRoute(RouteSettings(name: route))!,
    ],
  ));
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label, skipOffstage: true);
  expect(finder, findsWidgets, reason: 'No visible "$label"');
  await tester.ensureVisible(finder.last);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder.last, warnIfMissed: false);
  await _settle(tester);
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey('field:$key'));
  expect(finder, findsOneWidget, reason: 'No field $key');
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await _settle(tester);
}

void main() {
  testWidgets('scenario auth-email · Create account with email, verify, keep both plans', (tester) async {
    await _start(tester, Routes.obAccount, ios: false);
    try {
        await _tap(tester, 'I’m 18 or older');
        await _tap(tester, 'Create account');
        expect(find.byType(AuthVerifyScreen), findsOneWidget, reason: 'expected auth_verify');
        await _tap(tester, 'I’ve confirmed my email');
        expect(find.byType(AuthMergeScreen), findsOneWidget, reason: 'expected auth_merge');
        await _tap(tester, 'Continue');
        expect(find.byType(TodayScreen), findsOneWidget, reason: 'expected today');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario auth-apple · Sign in with Apple (iPhone)', (tester) async {
    await _start(tester, Routes.welcome, ios: true);
    try {
        await _tap(tester, 'I already have an account');
        TSim.queue.add('Success');
        await _tap(tester, 'Continue with Apple');
        expect(find.byType(TodayScreen), findsOneWidget, reason: 'expected today');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario auth-google · Sign in with Google (Android)', (tester) async {
    await _start(tester, Routes.welcome, ios: false);
    try {
        await _tap(tester, 'I already have an account');
        TSim.queue.add('Success');
        await _tap(tester, 'Continue with Google');
        expect(find.byType(TodayScreen), findsOneWidget, reason: 'expected today');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario auth-apple-new · New Apple ID starts onboarding with an account', (tester) async {
    await _start(tester, Routes.welcome, ios: true);
    try {
        await _tap(tester, 'I already have an account');
        TSim.queue.add('New Apple ID, no Tether account');
        await _tap(tester, 'Continue with Apple');
        expect(find.byType(AuthSocialNewScreen), findsOneWidget, reason: 'expected auth_social_new');
        await _tap(tester, 'Create my account');
        expect(find.byType(ObProgramsScreen), findsOneWidget, reason: 'expected ob_programs');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario auth-google-link · Google email already used → link accounts', (tester) async {
    await _start(tester, Routes.obAccount, ios: false);
    try {
        await _tap(tester, 'I’m 18 or older');
        TSim.queue.add('Email already has a Tether account');
        await _tap(tester, 'Continue with Google');
        expect(find.byType(AuthLinkScreen), findsOneWidget, reason: 'expected auth_link');
        await _tap(tester, 'Link and sign in');
        expect(find.byType(TodayScreen), findsOneWidget, reason: 'expected today');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario auth-google-error · Google sign-in fails → error with email fallback', (tester) async {
    await _start(tester, Routes.obAccount, ios: false);
    try {
        await _tap(tester, 'I’m 18 or older');
        TSim.queue.add('Error');
        await _tap(tester, 'Continue with Google');
        expect(find.byType(AuthSocialErrorScreen), findsOneWidget, reason: 'expected auth_social_error');
        await _tap(tester, 'Use email instead');
        expect(find.byType(AuthSigninScreen), findsOneWidget, reason: 'expected auth_signin');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario auth-wrong-password · Wrong password shows inline error', (tester) async {
    await _start(tester, Routes.welcome, ios: false);
    try {
        await _tap(tester, 'I already have an account');
        TSim.queue.add('Wrong password');
        await _tap(tester, 'Sign in');
        expect(find.byType(AuthSigninErrorScreen), findsOneWidget, reason: 'expected auth_signin_error');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario onboarding · First run: 2 programs, consent, BreatheFree plan, guest', (tester) async {
    await _start(tester, Routes.welcome, ios: false);
    try {
        await _tap(tester, 'Get started');
        await _tap(tester, 'Continue with 2 programs');
        await _tap(tester, 'Continue');
        await _tap(tester, 'Agree and continue');
        await _tap(tester, 'Continue');
        expect(find.byType(ObSetupScreen), findsOneWidget, reason: 'expected ob_setup');
        await _tap(tester, 'BreatheFree');
        await _tap(tester, 'Next');
        await _tap(tester, 'Next');
        await _tap(tester, 'Save my reasons');
        await _tap(tester, 'Continue with this path');
        await _tap(tester, 'Confirm this date');
        await _tap(tester, 'Review my plan');
        await _tap(tester, 'Start my plan');
        expect(find.byType(ObSetupScreen), findsOneWidget, reason: 'expected ob_setup');
        await _tap(tester, 'Continue');
        TSim.queue.add('Allowed');
        await _tap(tester, 'Turn on reminders');
        await _tap(tester, 'I’m 18 or older');
        await _tap(tester, 'Continue on this phone only');
        expect(find.byType(TodayScreen), findsOneWidget, reason: 'expected today');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario fhir-epic · Connect Epic MyChart, review, resolve conflict, add to programs', (tester) async {
    await _start(tester, Routes.recordsHub, ios: false);
    try {
        await _tap(tester, 'Add a source');
        await _tap(tester, 'Hospital or clinic');
        await _tap(tester, 'Patel Family Medicine');
        TSim.queue.add('Approved');
        await _tap(tester, 'Continue to MyChart');
        expect(find.byType(RecordsImportingScreen), findsOneWidget, reason: 'expected records_importing');
        await _tap(tester, 'Review imported data');
        expect(find.byType(RecordsReviewScreen), findsOneWidget, reason: 'expected records_review');
        await _tap(tester, 'Review conflicts first');
        await _tap(tester, 'From Patel Family Medicine (Epic): 7.6%');
        await _tap(tester, 'Save choices');
        expect(find.byType(RecordsReviewScreen), findsOneWidget, reason: 'expected records_review');
        await _tap(tester, 'Add 21 items to my programs');
        expect(find.byType(RecordsHubScreen), findsOneWidget, reason: 'expected records_hub');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario fhir-bluebutton · Connect Medicare Blue Button 2.0', (tester) async {
    await _start(tester, Routes.recordsAdd, ios: false);
    try {
        await _tap(tester, 'Medicare · Blue Button 2.0');
        TSim.queue.add('Approved');
        await _tap(tester, 'Continue to Medicare.gov');
        await _tap(tester, 'Review imported data');
        expect(find.byType(RecordsReviewScreen), findsOneWidget, reason: 'expected records_review');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario fhir-denied · Provider sign-in denied → error with options', (tester) async {
    await _start(tester, Routes.recordsAdd, ios: false);
    try {
        await _tap(tester, 'Hospital or clinic');
        await _tap(tester, 'Patel Family Medicine');
        TSim.queue.add('Denied or error');
        await _tap(tester, 'Continue to MyChart');
        expect(find.byType(RecordsErrorScreen), findsOneWidget, reason: 'expected records_error');
        await _tap(tester, 'Enter manually instead');
        expect(find.byType(RecordsManualScreen), findsOneWidget, reason: 'expected records_manual');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario fhir-custom · Other FHIR server: capability check fails', (tester) async {
    await _start(tester, Routes.recordsAdd, ios: false);
    try {
        await _tap(tester, 'Other FHIR server');
        TSim.queue.add('Not a FHIR R4 server');
        await _tap(tester, 'Check and continue');
        expect(find.byType(RecordsErrorScreen), findsOneWidget, reason: 'expected records_error');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario fhir-manual-ok · Manual A1C within range is saved', (tester) async {
    await _start(tester, Routes.recordsManual, ios: false);
    try {
        await _enter(tester, 'records_manual.value', '7.4');
        await _tap(tester, 'Save');
        expect(find.byType(RecordsHubScreen), findsOneWidget, reason: 'expected records_hub');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario fhir-manual-range · Manual A1C 74 is held as out of range', (tester) async {
    await _start(tester, Routes.recordsManual, ios: false);
    try {
        await _enter(tester, 'records_manual.value', '74');
        await _tap(tester, 'Save');
        expect(find.byType(RecordsManualErrorScreen), findsOneWidget, reason: 'expected records_manual_error');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario fhir-disconnect · Disconnect a source and delete its data', (tester) async {
    await _start(tester, Routes.recordsHub, ios: false);
    try {
        await _tap(tester, 'Patel Family Medicine');
        await _tap(tester, 'Disconnect');
        await _tap(tester, 'Delete data imported from this source');
        await _tap(tester, 'Disconnect source');
        expect(find.byType(RecordsHubScreen), findsOneWidget, reason: 'expected records_hub');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario bf-date · Set a quit date path', (tester) async {
    await _start(tester, Routes.bfIntro, ios: false);
    try {
        await _tap(tester, 'Set up BreatheFree');
        await _tap(tester, 'Next');
        await _tap(tester, 'Next');
        await _tap(tester, 'Save my reasons');
        await _tap(tester, 'Continue with this path');
        expect(find.byType(BfDateScreen), findsOneWidget, reason: 'expected bf_date');
        await _tap(tester, 'Confirm this date');
        await _tap(tester, 'Review my plan');
        await _tap(tester, 'Start my plan');
        expect(find.byType(BfHomeScreen), findsOneWidget, reason: 'expected bf_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario bf-today · Quit today path skips the calendar', (tester) async {
    await _start(tester, Routes.bfIntro, ios: false);
    try {
        await _tap(tester, 'Set up BreatheFree');
        await _tap(tester, 'Next');
        await _tap(tester, 'Next');
        await _tap(tester, 'Save my reasons');
        await _tap(tester, 'Quit today');
        await _tap(tester, 'Continue with this path');
        expect(find.byType(BfSupportScreen), findsOneWidget, reason: 'expected bf_support');
        expect(find.byType(BfSupportScreen), findsOneWidget, reason: 'expected bf_support');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario bf-reduce · Reduce gradually path → step-down schedule', (tester) async {
    await _start(tester, Routes.bfIntro, ios: false);
    try {
        await _tap(tester, 'Set up BreatheFree');
        await _tap(tester, 'Next');
        await _tap(tester, 'Next');
        await _tap(tester, 'Save my reasons');
        await _tap(tester, 'Reduce gradually');
        await _tap(tester, 'Continue with this path');
        expect(find.byType(BfStepdownScreen), findsOneWidget, reason: 'expected bf_stepdown');
        await _tap(tester, 'Save schedule');
        expect(find.byType(BfSupportScreen), findsOneWidget, reason: 'expected bf_support');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario bf-explore · Explore first path never asks for a date', (tester) async {
    await _start(tester, Routes.bfIntro, ios: false);
    try {
        await _tap(tester, 'Set up BreatheFree');
        await _tap(tester, 'Next');
        await _tap(tester, 'Next');
        await _tap(tester, 'Save my reasons');
        await _tap(tester, 'Explore first');
        await _tap(tester, 'Continue with this path');
        expect(find.byType(BfHomeExploreScreen), findsOneWidget, reason: 'expected bf_home_explore');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario bf-rescue · Craving rescue from BreatheFree home', (tester) async {
    await _start(tester, Routes.bfHome, ios: false);
    try {
        await _tap(tester, 'Rescue');
        await _tap(tester, 'A cigarette');
        await _tap(tester, 'I’m done');
        await _tap(tester, 'Back to Today');
        expect(find.byType(TodayScreen), findsOneWidget, reason: 'expected today');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario bf-slip · Slip recovery keeps the plan and starts a rescue', (tester) async {
    await _start(tester, Routes.bfHomeQuitday, ios: false);
    try {
        await _tap(tester, 'I smoked or had a slip');
        await _tap(tester, 'Save and start a 2-min Rescue');
        expect(find.byType(RescueActiveScreen), findsOneWidget, reason: 'expected rescue_active');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario bf-slip-newdate · Slip recovery → choose a new quit time', (tester) async {
    await _start(tester, Routes.bfSlip, ios: false);
    try {
        await _tap(tester, 'Choose a new quit time');
        await _tap(tester, 'Save and start a 2-min Rescue');
        expect(find.byType(BfDateScreen), findsOneWidget, reason: 'expected bf_date');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario bf-meds · Record nicotine patch taken', (tester) async {
    await _start(tester, Routes.bfMeds, ios: false);
    try {
        await _tap(tester, 'Taken today');
        await _tap(tester, 'Add or update recorded plan');
        await _tap(tester, 'Save plan');
        expect(find.byType(BfMedsScreen), findsOneWidget, reason: 'expected bf_meds');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf-setup · ScrollFree setup with Screen Time allowed', (tester) async {
    await _start(tester, Routes.sfIntro, ios: false);
    try {
        await _tap(tester, 'Set up ScrollFree');
        await _tap(tester, 'Next');
        await _tap(tester, 'Next');
        await _tap(tester, 'Connect Screen Time');
        TSim.queue.add('Allowed');
        await _tap(tester, 'Allow access');
        expect(find.byType(SfGoalScreen), findsOneWidget, reason: 'expected sf_goal');
        await _tap(tester, 'Save my goal');
        await _tap(tester, 'Save and finish');
        expect(find.byType(SfHomeScreen), findsOneWidget, reason: 'expected sf_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf-denied · Screen Time denied → self-report fallback', (tester) async {
    await _start(tester, Routes.sfGoal, ios: false);
    try {
        await _tap(tester, 'Connect Screen Time');
        TSim.queue.add('Not allowed');
        await _tap(tester, 'Allow access');
        expect(find.byType(SfScreentimeDeniedScreen), findsOneWidget, reason: 'expected sf_screentime_denied');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf-pause · Pause 60 → put the phone down', (tester) async {
    await _start(tester, Routes.sfHome, ios: false);
    try {
        await _tap(tester, 'Pause 60');
        await _tap(tester, 'I’m good, put it down');
        expect(find.byType(TodayScreen), findsOneWidget, reason: 'expected today');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf-slip · Long-scroll recovery', (tester) async {
    await _start(tester, Routes.sfHome, ios: false);
    try {
        await _tap(tester, 'Had a long scroll?');
        await _tap(tester, 'Save');
        expect(find.byType(SfHomeScreen), findsOneWidget, reason: 'expected sf_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ca-setup · ClearAir setup with a written plan', (tester) async {
    await _start(tester, Routes.caIntro, ios: false);
    try {
        await _tap(tester, 'Set up ClearAir');
        await _tap(tester, 'Next');
        expect(find.byType(CaPlanScreen), findsOneWidget, reason: 'expected ca_plan');
        await _tap(tester, 'Save plan');
        expect(find.byType(CaHomeScreen), findsOneWidget, reason: 'expected ca_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ca-noplan · No action plan → learn route', (tester) async {
    await _start(tester, Routes.caIntro, ios: false);
    try {
        await _tap(tester, 'Set up ClearAir');
        await _tap(tester, 'No');
        await _tap(tester, 'Next');
        expect(find.byType(CaNoplanScreen), findsOneWidget, reason: 'expected ca_noplan');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ca-green · Peak flow 420, no symptoms → green', (tester) async {
    await _start(tester, Routes.caZone, ios: false);
    try {
        await _enter(tester, 'ca_zone.peak_flow', '420');
        await _tap(tester, 'Wheezing');
        await _tap(tester, 'Save and see my steps');
        expect(find.byType(CaHomeScreen), findsOneWidget, reason: 'expected ca_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ca-yellow · Peak flow 310 → yellow steps', (tester) async {
    await _start(tester, Routes.caZone, ios: false);
    try {
        await _enter(tester, 'ca_zone.peak_flow', '310');
        await _tap(tester, 'Save and see my steps');
        expect(find.byType(CaYellowScreen), findsOneWidget, reason: 'expected ca_yellow');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ca-red · Peak flow 150 → red zone', (tester) async {
    await _start(tester, Routes.caZone, ios: false);
    try {
        await _enter(tester, 'ca_zone.peak_flow', '150');
        await _tap(tester, 'Save and see my steps');
        expect(find.byType(CaRedScreen), findsOneWidget, reason: 'expected ca_red');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ca-red-symptom · Can’t speak in full sentences → red regardless of peak flow', (tester) async {
    await _start(tester, Routes.caZone, ios: false);
    try {
        await _enter(tester, 'ca_zone.peak_flow', '420');
        await _tap(tester, 'Can’t speak in full sentences');
        await _tap(tester, 'Save and see my steps');
        expect(find.byType(CaRedScreen), findsOneWidget, reason: 'expected ca_red');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ca-invalid · Peak flow 2000 is rejected', (tester) async {
    await _start(tester, Routes.caZone, ios: false);
    try {
        await _enter(tester, 'ca_zone.peak_flow', '2000');
        await _tap(tester, 'Save and see my steps');
        expect(find.byType(CaZoneScreen), findsOneWidget, reason: 'expected ca_zone');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario hw-setup · Add Heartwise by swapping a focus slot', (tester) async {
    await _start(tester, Routes.hwIntro, ios: false);
    try {
        await _tap(tester, 'Set up Heartwise');
        await _tap(tester, 'Swap with ScrollFree');
        await _tap(tester, 'Continue');
        expect(find.byType(HwQ1Screen), findsOneWidget, reason: 'expected hw_q1');
        await _tap(tester, 'Next');
        await _tap(tester, 'Save targets');
        expect(find.byType(HwHomeScreen), findsOneWidget, reason: 'expected hw_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario hw-learn · Add Heartwise as Learn only', (tester) async {
    await _start(tester, Routes.hwIntro, ios: false);
    try {
        await _tap(tester, 'Set up Heartwise');
        await _tap(tester, 'Continue');
        expect(find.byType(PlansScreen), findsOneWidget, reason: 'expected plans');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario hw-normal · Two readings 138/86 + 132/84 → saved', (tester) async {
    await _start(tester, Routes.hwHome, ios: false);
    try {
        await _tap(tester, 'Log blood pressure');
        await _enter(tester, 'hw_log.systolic', '138');
        await _enter(tester, 'hw_log.diastolic', '86');
        await _tap(tester, 'Next reading');
        await _enter(tester, 'hw_log2.systolic', '132');
        await _enter(tester, 'hw_log2.diastolic', '84');
        await _tap(tester, 'Save readings');
        expect(find.byType(HwResultScreen), findsOneWidget, reason: 'expected hw_result');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario hw-crisis · Reading 186/122 → symptom check → re-check', (tester) async {
    await _start(tester, Routes.hwHome, ios: false);
    try {
        await _tap(tester, 'Log blood pressure');
        await _enter(tester, 'hw_log.systolic', '186');
        await _enter(tester, 'hw_log.diastolic', '122');
        await _tap(tester, 'Next reading');
        await _tap(tester, 'Save readings');
        expect(find.byType(HwCrisisScreen), findsOneWidget, reason: 'expected hw_crisis');
        await _tap(tester, 'No symptoms · re-check in 5 min');
        expect(find.byType(HwRecheckScreen), findsOneWidget, reason: 'expected hw_recheck');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario hw-invalid · Diastolic 310 → fix-it message', (tester) async {
    await _start(tester, Routes.hwLog, ios: false);
    try {
        await _enter(tester, 'hw_log.systolic', '138');
        await _enter(tester, 'hw_log.diastolic', '86');
        await _tap(tester, 'Next reading');
        await _enter(tester, 'hw_log2.systolic', '132');
        await _enter(tester, 'hw_log2.diastolic', '310');
        await _tap(tester, 'Save readings');
        expect(find.byType(HwLogErrorScreen), findsOneWidget, reason: 'expected hw_log_error');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario hw-summary · Visit summary sent to care team', (tester) async {
    await _start(tester, Routes.hwHome, ios: false);
    try {
        await _tap(tester, 'Visit summary');
        await _tap(tester, 'Send summary');
        expect(find.byType(HwHomeScreen), findsOneWidget, reason: 'expected hw_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario st-setup · Steady setup with range and low plan', (tester) async {
    await _start(tester, Routes.stIntro, ios: false);
    try {
        await _tap(tester, 'Set up Steady');
        await _tap(tester, 'Next');
        await _tap(tester, 'Save range');
        expect(find.byType(StHomeScreen), findsOneWidget, reason: 'expected st_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario st-normal · Reading 142 → saved', (tester) async {
    await _start(tester, Routes.stHome, ios: false);
    try {
        await _tap(tester, 'Log a reading');
        await _enter(tester, 'st_log.reading', '142');
        await _tap(tester, 'Save reading');
        expect(find.byType(StHomeScreen), findsOneWidget, reason: 'expected st_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario st-low · Reading 62 → low plan with timer', (tester) async {
    await _start(tester, Routes.stHome, ios: false);
    try {
        await _tap(tester, 'Log a reading');
        await _enter(tester, 'st_log.reading', '62');
        await _tap(tester, 'Save reading');
        expect(find.byType(StLowScreen), findsOneWidget, reason: 'expected st_low');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario st-low-custom · Clinician low of 80: reading 75 → low plan', (tester) async {
    await _start(tester, Routes.stRange, ios: false);
    try {
        await _enter(tester, 'st_range.low', '80');
        await _tap(tester, 'Save range');
        await _tap(tester, 'Log a reading');
        await _enter(tester, 'st_log.reading', '75');
        await _tap(tester, 'Save reading');
        expect(find.byType(StLowScreen), findsOneWidget, reason: 'expected st_low');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario st-invalid · Reading 900 is rejected', (tester) async {
    await _start(tester, Routes.stLog, ios: false);
    try {
        await _enter(tester, 'st_log.reading', '900');
        await _tap(tester, 'Save reading');
        expect(find.byType(StLogScreen), findsOneWidget, reason: 'expected st_log');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario re-setup · Renew risk check and plan', (tester) async {
    await _start(tester, Routes.reIntro, ios: false);
    try {
        await _tap(tester, 'Set up Renew');
        await _tap(tester, 'See what this means');
        await _tap(tester, 'Save my plan');
        expect(find.byType(ReHomeScreen), findsOneWidget, reason: 'expected re_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario re-labs · Add labs → history', (tester) async {
    await _start(tester, Routes.reHome, ios: false);
    try {
        await _tap(tester, 'Add lab results');
        await _tap(tester, 'Save results');
        expect(find.byType(ReHistoryScreen), findsOneWidget, reason: 'expected re_history');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario re-import · Import labs from health record', (tester) async {
    await _start(tester, Routes.reLabs, ios: false);
    try {
        await _tap(tester, 'Import from my health record');
        expect(find.byType(RecordsAddScreen), findsOneWidget, reason: 'expected records_add');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario re-symptom · Yellow eyes → care team today', (tester) async {
    await _start(tester, Routes.reHome, ios: false);
    try {
        await _tap(tester, 'Check symptoms');
        await _tap(tester, 'Contact my care team');
        expect(find.byType(SupportMessageCareScreen), findsOneWidget, reason: 'expected support_message_care');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario nu-setup · Nourish weekly habit', (tester) async {
    await _start(tester, Routes.nuIntro, ios: false);
    try {
        await _tap(tester, 'Set up Nourish');
        await _tap(tester, 'Next');
        await _tap(tester, 'Start this habit');
        expect(find.byType(NuHomeScreen), findsOneWidget, reason: 'expected nu_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario nu-protect · Eating-history yes → protective mode', (tester) async {
    await _start(tester, Routes.nuIntro, ios: false);
    try {
        await _tap(tester, 'Set up Nourish');
        await _tap(tester, 'Yes');
        await _tap(tester, 'Next');
        expect(find.byType(NuProtectScreen), findsOneWidget, reason: 'expected nu_protect');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario nu-reset · Off track → make it smaller', (tester) async {
    await _start(tester, Routes.nuHome, ios: false);
    try {
        await _tap(tester, 'Busy week?');
        await _tap(tester, 'Make it smaller');
        await _tap(tester, 'Continue');
        expect(find.byType(NuHomeScreen), findsOneWidget, reason: 'expected nu_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sd-setup · Stride falls check and plan', (tester) async {
    await _start(tester, Routes.sdIntro, ios: false);
    try {
        await _tap(tester, 'Set up Stride');
        await _tap(tester, 'Next');
        await _tap(tester, 'Start plan');
        expect(find.byType(SdHomeScreen), findsOneWidget, reason: 'expected sd_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sd-session · Complete a session', (tester) async {
    await _start(tester, Routes.sdHome, ios: false);
    try {
        await _tap(tester, 'Start');
        await _tap(tester, 'Finish session');
        expect(find.byType(SdHomeScreen), findsOneWidget, reason: 'expected sd_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sd-fell · I fell → okay → fall logged', (tester) async {
    await _start(tester, Routes.sdHome, ios: false);
    try {
        await _tap(tester, 'I fell');
        await _tap(tester, 'I’m okay, log this fall');
        expect(find.byType(SdHomeScreen), findsOneWidget, reason: 'expected sd_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ea-setup · Ease screener → result', (tester) async {
    await _start(tester, Routes.eaIntro, ios: false);
    try {
        await _tap(tester, 'Set up Ease');
        await _tap(tester, 'Next');
        expect(find.byType(EaResultScreen), findsOneWidget, reason: 'expected ea_result');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ea-skip · Skip screener → safety plan → home', (tester) async {
    await _start(tester, Routes.eaIntro, ios: false);
    try {
        await _tap(tester, 'Set up Ease');
        await _tap(tester, 'Skip the check');
        await _tap(tester, 'Save plan');
        expect(find.byType(EaHomeScreen), findsOneWidget, reason: 'expected ea_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ea-mood · Mood check-in without self-harm → saved', (tester) async {
    await _start(tester, Routes.eaHome, ios: false);
    try {
        await _tap(tester, 'Start');
        await _tap(tester, 'Save');
        expect(find.byType(EaHomeScreen), findsOneWidget, reason: 'expected ea_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ea-crisis · Self-harm option → crisis screen', (tester) async {
    await _start(tester, Routes.eaHome, ios: false);
    try {
        await _tap(tester, 'Start');
        await _tap(tester, 'Thoughts of harming myself');
        await _tap(tester, 'Save');
        expect(find.byType(CrisisScreen), findsOneWidget, reason: 'expected crisis');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ck-setup · Checkup builds a due list', (tester) async {
    await _start(tester, Routes.ckIntro, ios: false);
    try {
        await _tap(tester, 'Set up Checkup');
        await _tap(tester, 'Build my list');
        expect(find.byType(CkListScreen), findsOneWidget, reason: 'expected ck_list');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario ck-done · Mark flu vaccine done', (tester) async {
    await _start(tester, Routes.ckList, ios: false);
    try {
        await _tap(tester, 'I got it');
        await _tap(tester, 'Save');
        expect(find.byType(CkListScreen), findsOneWidget, reason: 'expected ck_list');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario be-risk · Beacon: lowering my risk', (tester) async {
    await _start(tester, Routes.beIntro, ios: false);
    try {
        await _tap(tester, 'Set up Beacon');
        await _tap(tester, 'Next');
        await _tap(tester, 'See my plan');
        expect(find.byType(BeHomeScreen), findsOneWidget, reason: 'expected be_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario be-tx · Beacon: going through treatment', (tester) async {
    await _start(tester, Routes.beIntro, ios: false);
    try {
        await _tap(tester, 'Set up Beacon');
        await _tap(tester, 'Going through treatment');
        await _tap(tester, 'Next');
        expect(find.byType(BeTxScreen), findsOneWidget, reason: 'expected be_tx');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario be-survivor · Beacon: after treatment', (tester) async {
    await _start(tester, Routes.beIntro, ios: false);
    try {
        await _tap(tester, 'Set up Beacon');
        await _tap(tester, 'After treatment');
        await _tap(tester, 'Next');
        expect(find.byType(BeSurvivorScreen), findsOneWidget, reason: 'expected be_survivor');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario be-diary · Treatment diary saved', (tester) async {
    await _start(tester, Routes.beTx, ios: false);
    try {
        await _tap(tester, 'Today’s side-effect diary');
        await _tap(tester, 'Save');
        expect(find.byType(BeTxScreen), findsOneWidget, reason: 'expected be_tx');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario today-tabs · Every tab from Today', (tester) async {
    await _start(tester, Routes.today, ios: false);
    try {
        await _tap(tester, 'Plans');
        expect(find.byType(PlansScreen), findsOneWidget, reason: 'expected plans');
        await _tap(tester, 'Progress');
        expect(find.byType(ProgressScreen), findsOneWidget, reason: 'expected progress');
        await _tap(tester, 'Learn');
        expect(find.byType(LearnScreen), findsOneWidget, reason: 'expected learn');
        await _tap(tester, 'Support');
        expect(find.byType(SupportScreen), findsOneWidget, reason: 'expected support');
        await _tap(tester, 'Today');
        expect(find.byType(TodayScreen), findsOneWidget, reason: 'expected today');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario checkin · Combined check-in → one step per program', (tester) async {
    await _start(tester, Routes.today, ios: false);
    try {
        await _tap(tester, 'Start');
        await _tap(tester, 'Save check-in');
        expect(find.byType(CheckinDoneScreen), findsOneWidget, reason: 'expected checkin_done');
        await _tap(tester, 'Back to Today');
        expect(find.byType(TodayScreen), findsOneWidget, reason: 'expected today');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario delete · Delete account with receipt', (tester) async {
    await _start(tester, Routes.account, ios: false);
    try {
        await _tap(tester, 'Your data');
        await _tap(tester, 'Delete account and all data');
        await _tap(tester, 'Delete everything');
        expect(find.byType(AccountDeletedScreen), findsOneWidget, reason: 'expected account_deleted');
        await _tap(tester, 'Done');
        expect(find.byType(WelcomeScreen), findsOneWidget, reason: 'expected welcome');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf_unplug_strict_end · Strict session needs a reason to end early', (tester) async {
    await _start(tester, Routes.sfUnplugSessionActive, ios: false);
    try {
        await _tap(tester, 'End early');
        expect(find.byType(SfUnplugSessionEndScreen), findsOneWidget, reason: 'expected sf_unplug_session_end');
        await _tap(tester, 'End session');
        expect(find.byType(SfUnplugSessionEndScreen), findsOneWidget, reason: 'expected sf_unplug_session_end');
        await _tap(tester, 'Expecting a message');
        await _tap(tester, 'End session');
        expect(find.byType(SfUnplugSessionDoneEarlyScreen), findsOneWidget, reason: 'expected sf_unplug_session_done_early');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf_unplug_gate_sum · Quick sum must be right before the app opens', (tester) async {
    await _start(tester, Routes.sfUnplugGateSum, ios: false);
    try {
        await _tap(tester, 'Open it for 10 minutes');
        expect(find.byType(SfUnplugGateSumScreen), findsOneWidget, reason: 'expected sf_unplug_gate_sum');
        await _enter(tester, 'sf_unplug_gate_sum.answer', '9');
        await _tap(tester, 'Open it for 10 minutes');
        expect(find.byType(SfUnplugGateSumScreen), findsOneWidget, reason: 'expected sf_unplug_gate_sum');
        await _enter(tester, 'sf_unplug_gate_sum.answer', '12');
        await _tap(tester, 'Open it for 10 minutes');
        expect(find.byType(SfHomeScreen), findsOneWidget, reason: 'expected sf_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf_unplug_gate_sentence · Sentence must be typed in full before the app opens', (tester) async {
    await _start(tester, Routes.sfUnplugGateCommit, ios: false);
    try {
        await _tap(tester, 'Open it for 10 minutes');
        expect(find.byType(SfUnplugGateCommitScreen), findsOneWidget, reason: 'expected sf_unplug_gate_commit');
        await _enter(tester, 'sf_unplug_gate_commit.sentence', 'I can come back');
        await _tap(tester, 'Open it for 10 minutes');
        expect(find.byType(SfUnplugGateCommitScreen), findsOneWidget, reason: 'expected sf_unplug_gate_commit');
        await _enter(tester, 'sf_unplug_gate_commit.sentence', 'i can come back to this later.');
        await _tap(tester, 'Open it for 10 minutes');
        expect(find.byType(SfHomeScreen), findsOneWidget, reason: 'expected sf_home');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf_unplug_overlay_support · Android pause screen reaches Rescue and Emergency', (tester) async {
    await _start(tester, Routes.sfUnplugOverlay, ios: false);
    try {
        await _tap(tester, 'Get support');
        expect(find.byType(RescuePickScreen), findsOneWidget, reason: 'expected rescue_pick');
        await _tap(tester, 'Emergency');
        expect(find.byType(CrisisScreen), findsOneWidget, reason: 'expected crisis');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf_unplug_shield_support · iPhone shield reaches Rescue without the small step', (tester) async {
    await _start(tester, Routes.sfUnplugShield, ios: false);
    try {
        TSim.queue.add('Get support');
        await _tap(tester, 'Take a breath');
        expect(find.byType(RescuePickScreen), findsOneWidget, reason: 'expected rescue_pick');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf_unplug_shield_firm_support · Firm iPhone shield reaches Rescue', (tester) async {
    await _start(tester, Routes.sfUnplugShieldFirm, ios: false);
    try {
        await _tap(tester, 'Get support');
        expect(find.byType(RescuePickScreen), findsOneWidget, reason: 'expected rescue_pick');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('scenario sf_unplug_notifications_off · Notifications off during setup → fix and continue', (tester) async {
    await _start(tester, Routes.sfUnplugAuth, ios: false);
    try {
        TSim.queue.add('Approved · notifications off');
        await _tap(tester, 'Continue');
        expect(find.byType(SfUnplugAuthNotificationsScreen), findsOneWidget, reason: 'expected sf_unplug_auth_notifications');
        TSim.queue.add('On (iPhone)');
        await _tap(tester, 'Check again');
        expect(find.byType(SfUnplugAppsScreen), findsOneWidget, reason: 'expected sf_unplug_apps');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
