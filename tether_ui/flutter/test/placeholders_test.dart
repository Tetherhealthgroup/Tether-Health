// GENERATED — P-31: example values are placeholder (hint) text. Every
// screen with text fields is opened and its Save / Continue elements are
// tapped without typing. Each field must start empty, show its example only
// as hint text and hold null in the session (a bound field on a settings
// screen, P-71, writes nothing at all). Whatever is submitted must hold null
// for these fields and never an example value.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

class _RecordingApi implements TApi {
  final List<(String, Map<String, Object?>)> calls = [];
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async {
    calls.add((endpoint, Map<String, Object?>.of(TSession.values)));
    return const TResult.ok();
  }
}

bool _holds(Object? value, String example) => value == example || (value is List && value.contains(example));

/// Bound fields (spec `bind`, P-71): no session write until the member types.
const _bound = <String>{'bf_meds_edit.medicine', 'bf_meds_edit.when'};

const _cases = <(String, String, String, String, String?, bool, List<String>, List<(String, String)>)>[
  ('ob_basics', Routes.obBasics, 'footer[0]', 'Continue', null, false, ['ob_basics.what_should_we_call_you', 'ob_basics.age_range'], [('ob_basics.what_should_we_call_you', 'Alex'), ('ob_basics.age_range', '35–44')]),
  ('ob_account', Routes.obAccount, 'footer[0]', 'Create account', 'Age confirmed', true, ['ob_account.email', 'ob_account.password'], [('ob_account.email', 'alex@example.com'), ('ob_account.password', '••••••••••••')]),
  ('auth_signin', Routes.authSignin, 'footer[0]', 'Sign in', 'Success', true, ['auth_signin.email', 'auth_signin.password'], [('auth_signin.email', 'alex@example.com'), ('auth_signin.password', '••••••••')]),
  ('auth_signin', Routes.authSignin, 'footer[0]', 'Sign in', 'Success · guest plan on phone', true, ['auth_signin.email', 'auth_signin.password'], [('auth_signin.email', 'alex@example.com'), ('auth_signin.password', '••••••••')]),
  ('auth_signin', Routes.authSignin, 'footer[0]', 'Sign in', 'Wrong password', true, ['auth_signin.email', 'auth_signin.password'], [('auth_signin.email', 'alex@example.com'), ('auth_signin.password', '••••••••')]),
  ('auth_signin_error', Routes.authSigninError, 'footer[0]', 'Try again', 'Success', true, ['auth_signin_error.email', 'auth_signin_error.password'], [('auth_signin_error.email', 'alex@example.com'), ('auth_signin_error.password', '••••••••')]),
  ('auth_signin_error', Routes.authSigninError, 'footer[0]', 'Try again', 'Success · guest plan on phone', true, ['auth_signin_error.email', 'auth_signin_error.password'], [('auth_signin_error.email', 'alex@example.com'), ('auth_signin_error.password', '••••••••')]),
  ('auth_signin_error', Routes.authSigninError, 'footer[0]', 'Try again', 'Wrong password', true, ['auth_signin_error.email', 'auth_signin_error.password'], [('auth_signin_error.email', 'alex@example.com'), ('auth_signin_error.password', '••••••••')]),
  ('auth_link', Routes.authLink, 'footer[0]', 'Link and sign in', null, true, ['auth_link.password'], [('auth_link.password', '••••••••••••')]),
  ('auth_forgot', Routes.authForgot, 'footer[0]', 'Send reset link', null, true, ['auth_forgot.email'], [('auth_forgot.email', 'alex@example.com')]),
  ('auth_newpass', Routes.authNewpass, 'footer[0]', 'Save password', null, true, ['auth_newpass.new_password', 'auth_newpass.confirm_password'], [('auth_newpass.new_password', '••••••••••••'), ('auth_newpass.confirm_password', '••••••••••••')]),
  ('auth_session', Routes.authSession, 'footer[0]', 'Sign in', null, true, ['auth_session.password'], [('auth_session.password', 'Password')]),
  ('learn', Routes.learn, '', 'opened, nothing tapped', null, false, ['learn.search'], [('learn.search', 'Search cravings, sleep, blood pressure…')]),
  ('support_callback', Routes.supportCallback, 'footer[0]', 'Send referral', null, true, ['support_callback.best_time_to_call'], [('support_callback.best_time_to_call', 'Weekdays after 5 PM')]),
  ('support_message_care', Routes.supportMessageCare, 'footer[0]', 'Send message', null, true, ['support_message_care.topic', 'support_message_care.message'], [('support_message_care.topic', 'Question about my plan'), ('support_message_care.message', 'I’ve been feeling dizzy in the mornings since starting the patch.')]),
  ('support_add_person', Routes.supportAddPerson, 'footer[0]', 'Save supporter', null, true, ['support_add_person.name', 'support_add_person.phone', 'support_add_person.help_phrase'], [('support_add_person.name', 'Jordan'), ('support_add_person.phone', '(555) 010-4421'), ('support_add_person.help_phrase', 'Can you stay with me for the next 10 minutes?')]),
  ('support_connect', Routes.supportConnect, 'footer[0]', 'Connect', null, true, ['support_connect.invite_code'], [('support_connect.invite_code', 'PATEL-4821')]),
  ('account_delete', Routes.accountDelete, 'footer[0]', 'Delete everything', null, true, ['account_delete.type_delete_to_confirm', 'account_delete.password'], [('account_delete.type_delete_to_confirm', 'DELETE'), ('account_delete.password', '••••••••••••')]),
  ('bf_q2', Routes.bfQ2, 'footer[0]', 'Next', null, false, ['bf_q2.add_your_own'], [('bf_q2.add_your_own', 'Type another situation…')]),
  ('bf_meds_edit', Routes.bfMedsEdit, 'footer[0]', 'Save plan', null, true, ['bf_meds_edit.medicine', 'bf_meds_edit.strength', 'bf_meds_edit.when'], [('bf_meds_edit.medicine', 'Nicotine patch'), ('bf_meds_edit.strength', '21 mg / 24 h'), ('bf_meds_edit.when', 'Every morning')]),
  ('sf_buddy', Routes.sfBuddy, 'footer[0]', 'Save and finish', null, true, ['sf_buddy.name'], [('sf_buddy.name', 'Sam')]),
  ('ca_plan', Routes.caPlan, 'footer[0]', 'Save plan', null, true, ['ca_plan.green_from', 'ca_plan.daily_medicine', 'ca_plan.peak_flow', 'ca_plan.red_below'], [('ca_plan.green_from', '400'), ('ca_plan.daily_medicine', 'Controller inhaler · 2 puffs AM/PM'), ('ca_plan.peak_flow', '200–399'), ('ca_plan.red_below', '200')]),
  ('ca_zone', Routes.caZone, 'footer[0]', 'Save and see my steps', 'Green', true, ['ca_zone.peak_flow'], [('ca_zone.peak_flow', '310')]),
  ('ca_zone', Routes.caZone, 'footer[0]', 'Save and see my steps', 'Yellow', true, ['ca_zone.peak_flow'], [('ca_zone.peak_flow', '310')]),
  ('ca_zone', Routes.caZone, 'footer[0]', 'Save and see my steps', 'Red', true, ['ca_zone.peak_flow'], [('ca_zone.peak_flow', '310')]),
  ('ca_zone', Routes.caZone, 'footer[0]', 'Save and see my steps', 'Invalid peak flow', true, ['ca_zone.peak_flow'], [('ca_zone.peak_flow', '310')]),
  ('ca_symptoms', Routes.caSymptoms, 'footer[0]', 'Save', null, true, ['ca_symptoms.note_optional'], [('ca_symptoms.note_optional', 'Anything else to tell your clinician')]),
  ('hw_targets', Routes.hwTargets, 'footer[0]', 'Save targets', null, true, ['hw_targets.top_below', 'hw_targets.bottom_below'], [('hw_targets.top_below', '130'), ('hw_targets.bottom_below', '80')]),
  ('hw_log', Routes.hwLog, 'footer[0]', 'Next reading', null, false, ['hw_log.systolic', 'hw_log.diastolic', 'hw_log.pulse_optional'], [('hw_log.systolic', '138'), ('hw_log.diastolic', '86'), ('hw_log.pulse_optional', '72')]),
  ('hw_log2', Routes.hwLog2, 'footer[0]', 'Save readings', 'Valid · below crisis range', true, ['hw_log2.systolic', 'hw_log2.diastolic', 'hw_log2.pulse_optional'], [('hw_log2.systolic', '132'), ('hw_log2.diastolic', '84'), ('hw_log2.pulse_optional', '70')]),
  ('hw_log2', Routes.hwLog2, 'footer[0]', 'Save readings', 'Invalid value', true, ['hw_log2.systolic', 'hw_log2.diastolic', 'hw_log2.pulse_optional'], [('hw_log2.systolic', '132'), ('hw_log2.diastolic', '84'), ('hw_log2.pulse_optional', '70')]),
  ('hw_log2', Routes.hwLog2, 'footer[0]', 'Save readings', '≥180 top or ≥120 bottom', true, ['hw_log2.systolic', 'hw_log2.diastolic', 'hw_log2.pulse_optional'], [('hw_log2.systolic', '132'), ('hw_log2.diastolic', '84'), ('hw_log2.pulse_optional', '70')]),
  ('hw_log_error', Routes.hwLogError, 'footer[1]', 'Edit reading', null, false, ['hw_log_error.top_systolic', 'hw_log_error.bottom_diastolic'], [('hw_log_error.top_systolic', '128'), ('hw_log_error.bottom_diastolic', '310')]),
  ('hw_lipids', Routes.hwLipids, 'footer[0]', 'Save panel', null, true, ['hw_lipids.total', 'hw_lipids.ldl', 'hw_lipids.hdl', 'hw_lipids.triglycerides', 'hw_lipids.lab_date'], [('hw_lipids.total', '212'), ('hw_lipids.ldl', '138'), ('hw_lipids.hdl', '46'), ('hw_lipids.triglycerides', 'Optional'), ('hw_lipids.lab_date', 'Sep 30, 2026')]),
  ('st_range', Routes.stRange, 'footer[0]', 'Save range', null, true, ['st_range.before_meals_from', 'st_range.to', 'st_range.2_h_after_meals_below', 'st_range.low', 'st_range.my_low_steps'], [('st_range.before_meals_from', '80'), ('st_range.to', '130'), ('st_range.2_h_after_meals_below', '180'), ('st_range.low', '70'), ('st_range.my_low_steps', '15 g fast sugar, re-check in 15 min')]),
  ('st_log', Routes.stLog, 'footer[0]', 'Save reading', 'In or above range', true, ['st_log.reading', 'st_log.note_optional'], [('st_log.reading', '142'), ('st_log.note_optional', 'Pasta lunch')]),
  ('st_log', Routes.stLog, 'footer[0]', 'Save reading', 'Below your low', true, ['st_log.reading', 'st_log.note_optional'], [('st_log.reading', '142'), ('st_log.note_optional', 'Pasta lunch')]),
  ('st_log', Routes.stLog, 'footer[0]', 'Save reading', 'Invalid (outside 20–600)', true, ['st_log.reading', 'st_log.note_optional'], [('st_log.reading', '142'), ('st_log.note_optional', 'Pasta lunch')]),
  ('st_a1c', Routes.stA1c, 'footer[0]', 'Save', null, true, ['st_a1c.a1c', 'st_a1c.lab_date'], [('st_a1c.a1c', '7.4'), ('st_a1c.lab_date', 'Oct 1, 2026')]),
  ('re_labs', Routes.reLabs, 'footer[0]', 'Save results', null, true, ['re_labs.egfr', 're_labs.urine_acr', 're_labs.alt_liver', 're_labs.lab_date'], [('re_labs.egfr', '58'), ('re_labs.urine_acr', '42'), ('re_labs.alt_liver', 'Optional'), ('re_labs.lab_date', 'Oct 3, 2026')]),
  ('sd_caregiver', Routes.sdCaregiver, 'footer[0]', 'Send invite', null, true, ['sd_caregiver.name', 'sd_caregiver.phone'], [('sd_caregiver.name', 'Rosa'), ('sd_caregiver.phone', '(555) 010-2244')]),
  ('ea_plan', Routes.eaPlan, 'footer[0]', 'Save plan', null, true, ['ea_plan.my_warning_signs', 'ea_plan.things_that_help_me', 'ea_plan.people_i_can_reach'], [('ea_plan.my_warning_signs', 'Not sleeping, pulling away from friends'), ('ea_plan.things_that_help_me', 'Walk the dog, shower, music'), ('ea_plan.people_i_can_reach', 'Sam · (555) 010-3311')]),
  ('ck_q1', Routes.ckQ1, 'footer[0]', 'Build my list', null, true, ['ck_q1.age'], [('ck_q1.age', '52')]),
  ('ck_done', Routes.ckDone, 'footer[0]', 'Save', null, true, ['ck_done.what', 'ck_done.date', 'ck_done.where_optional'], [('ck_done.what', 'Flu vaccine'), ('ck_done.date', 'Oct 12, 2026'), ('ck_done.where_optional', 'Main St Pharmacy')]),
  ('be_q2', Routes.beQ2, 'footer[0]', 'See my plan', null, true, ['be_q2.relative_s_age_at_diagnosis_if_k'], [('be_q2.relative_s_age_at_diagnosis_if_k', '44')]),
  ('be_questions', Routes.beQuestions, 'footer[0]', 'Share with my care team', null, false, ['be_questions.add_a_question'], [('be_questions.add_a_question', 'Type a question…')]),
  ('records_search', Routes.recordsSearch, '', 'opened, nothing tapped', null, false, ['records_search.query'], [('records_search.query', 'Search hospital, clinic or doctor')]),
  ('records_fhir_url', Routes.recordsFhirUrl, 'footer[0]', 'Check and continue', null, false, ['records_fhir_url.base_url'], [('records_fhir_url.base_url', 'https://fhir.example-health.org/r4')]),
  ('records_manual', Routes.recordsManual, 'footer[0]', 'Save', 'Valid', true, ['records_manual.test', 'records_manual.value', 'records_manual.date'], [('records_manual.test', 'A1C'), ('records_manual.value', '7.4'), ('records_manual.date', 'Oct 1, 2026')]),
  ('records_manual', Routes.recordsManual, 'footer[0]', 'Save', 'Outside expected range', true, ['records_manual.test', 'records_manual.value', 'records_manual.date'], [('records_manual.test', 'A1C'), ('records_manual.value', '7.4'), ('records_manual.date', 'Oct 1, 2026')]),
  ('records_manual', Routes.recordsManual, 'footer[0]', 'Save', 'Matches an imported value', true, ['records_manual.test', 'records_manual.value', 'records_manual.date'], [('records_manual.test', 'A1C'), ('records_manual.value', '7.4'), ('records_manual.date', 'Oct 1, 2026')]),
  ('records_manual_error', Routes.recordsManualError, 'footer[0]', 'Save', 'Valid', true, ['records_manual_error.test', 'records_manual_error.value', 'records_manual_error.date'], [('records_manual_error.test', 'A1C'), ('records_manual_error.value', '74'), ('records_manual_error.date', 'Oct 1, 2026')]),
  ('records_manual_error', Routes.recordsManualError, 'footer[0]', 'Save', 'Outside expected range', true, ['records_manual_error.test', 'records_manual_error.value', 'records_manual_error.date'], [('records_manual_error.test', 'A1C'), ('records_manual_error.value', '74'), ('records_manual_error.date', 'Oct 1, 2026')]),
  ('sf_unplug_apps_chosen', Routes.sfUnplugAppsChosen, 'footer[0]', 'Next: limits', null, false, ['sf_unplug_apps_chosen.group_name'], [('sf_unplug_apps_chosen.group_name', 'e.g. Games')]),
  ('sf_unplug_session_end', Routes.sfUnplugSessionEnd, 'footer[0]', 'End session', 'Reason given', true, ['sf_unplug_session_end.note'], [('sf_unplug_session_end.note', 'Optional')]),
  ('sf_unplug_gate_commit', Routes.sfUnplugGateCommit, 'footer[0]', 'Keep it closed', null, false, ['sf_unplug_gate_commit.sentence'], [('sf_unplug_gate_commit.sentence', 'I can come back to this later')]),
  ('sf_unplug_gate_commit', Routes.sfUnplugGateCommit, 'footer[1]', 'Open it for 10 minutes', null, false, ['sf_unplug_gate_commit.sentence'], [('sf_unplug_gate_commit.sentence', 'I can come back to this later')]),
  ('sf_unplug_gate_sum', Routes.sfUnplugGateSum, 'footer[0]', 'Keep it closed', null, false, ['sf_unplug_gate_sum.answer'], [('sf_unplug_gate_sum.answer', '?')]),
  ('sf_unplug_gate_sum', Routes.sfUnplugGateSum, 'footer[1]', 'Open it for 10 minutes', null, false, ['sf_unplug_gate_sum.answer'], [('sf_unplug_gate_sum.answer', '?')]),
  ('account_delete_apple', Routes.accountDeleteApple, 'footer[0]', 'Delete everything', 'Success', true, ['account_delete_apple.type_delete_to_confirm'], [('account_delete_apple.type_delete_to_confirm', 'DELETE')]),
  ('account_delete_google', Routes.accountDeleteGoogle, 'footer[0]', 'Delete everything', 'Success', true, ['account_delete_google.type_delete_to_confirm'], [('account_delete_google.type_delete_to_confirm', 'DELETE')]),
];

void main() {
  for (final c in _cases) {
    final name = 'no example submitted · ${c.$1} · ${c.$4}${c.$5 != null ? ' → ${c.$5}' : ''}';
    testWidgets(name, (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      TSession.clear();
      TFlow.onboarding = false;
      TSim.force = c.$5;
      TNav.branchResolver = (context, question, outcomes) async => outcomes.first;
      final api = _RecordingApi();
      TApi.instance = api;
      try {
        await tester.pumpWidget(MaterialApp(
          theme: tetherTheme(),
          onGenerateRoute: (s) => s.name == '/__host' ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: '/__host')),
            AppRouter.onGenerateRoute(RouteSettings(name: c.$2))!,
          ],
        ));
        await tester.pump(const Duration(milliseconds: 400));
        for (final key in c.$7) {
          final field = find.byKey(ValueKey('field:$key'));
          expect(field, findsOneWidget, reason: 'field $key');
          final editable = tester.widget<EditableText>(find.descendant(of: field, matching: find.byType(EditableText)));
          expect(editable.controller.text, isEmpty, reason: '$key must start empty');
          expect(TSession.values.containsKey(key), !_bound.contains(key), reason: _bound.contains(key) ? '$key is bound: nothing is written until the member types' : '$key writes to the session');
          expect(TSession.values[key], isNull, reason: '$key must be null until the member types');
        }
        for (final (key, hint) in c.$8) {
          expect(find.descendant(of: find.byKey(ValueKey('field:$key')), matching: find.text(hint)), findsOneWidget, reason: '$key shows "$hint" as hint text');
        }
        if (c.$3.isNotEmpty) {
          final finder = find.byKey(ValueKey('a:${c.$3}'));
          expect(finder, findsOneWidget, reason: 'element ${c.$3} on ${c.$1}');
          await tester.ensureVisible(finder);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(finder, warnIfMissed: false);
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 120));
          }
        }
        if (c.$6) expect(api.calls, isNotEmpty, reason: '${c.$4} submits');
        final sent = api.calls.isEmpty ? [Map<String, Object?>.of(TSession.values)] : [for (final call in api.calls) call.$2];
        for (final values in sent) {
          for (final key in c.$7) {
            expect(values[key], isNull, reason: '$key was not typed, so nothing may be sent for it');
          }
          for (final (_, hint) in c.$8) {
            for (final e in values.entries) {
              expect(_holds(e.value, hint), isFalse, reason: 'example "$hint" reached the session as ${e.key}');
            }
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      } finally {
        TSim.reset();
        TApi.instance = PreviewApi();
      }
    });
  }
}
