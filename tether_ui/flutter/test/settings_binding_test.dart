// Settings binding (P-71). On a settings screen every input control that
// writes the session is bound (spec `bind`) and starts from the member's
// stored value in TData, by class:
// - consent class (`consentSettingsScreens`): only a stored value is shown;
//   nothing stored (TData.unset) and not loaded (null) show the empty (off)
//   state and write nothing, so the spec's starting value is never written;
// - plan class (`planSettingsScreens`): a stored value is shown and written;
//   TData.unset shows and writes the spec's starting value; null writes
//   nothing;
// - TSession.touched lists only the keys the member changed on the screen
//   now shown, and a control set back to its starting value is not touched;
// - `:program` in a bind key is the programme the screen was opened for.
// Unbound controls (first-run and other screens) keep writing their
// starting value when built.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/router/settings_screens.dart';
import 'package:tether_ui/ui/ui.dart';

/// Pinned here and in generator/validate.py (CONSENT_SCREENS, PLAN_SCREENS).
const _consent = <String>{'account_notifications', 'account_privacy', 'program_settings', 'program_settings_sf', 'sd_caregiver', 'sf_buddy'};
const _plan = <String>{'be_q2', 'bf_meds_edit', 'bf_review', 'ca_plan', 'ck_q1', 'ea_plan', 'hw_targets', 'nu_habit', 're_result', 'sd_plan', 'sd_safety', 'st_range'};

/// Every input control on a plan-class screen: (type, session key, bind).
/// Pinned so that a new plan control, or a changed key or bind, is reviewed
/// (a plan control must never be a consent, share or caregiver choice).
const _planInventory = <String, List<(String, String?, String?)>>{
  'be_q2': [('chips', 'value', 'be.profile.family_cancers'), ('field', 'relative_s_age_at_diagnosis_if_k', null)],
  'bf_meds_edit': [('field', 'medicine', 'bf.meds.medicine'), ('field', 'strength', null), ('field', 'when', 'bf.meds.when'), ('toggle', 'private_reminder', 'bf.meds.private_reminder')],
  'bf_review': [],
  'ca_plan': [('field', 'green_from', null), ('field', 'daily_medicine', null), ('field', 'peak_flow', null), ('field', 'red_below', null)],
  'ck_q1': [('field', 'age', null), ('segmented', 'sex_assigned_at_birth', 'ck.profile.sex_assigned_at_birth'), ('chips', 'any_of_these', 'ck.profile.any_of_these')],
  'ea_plan': [('field', 'my_warning_signs', null), ('field', 'things_that_help_me', null), ('field', 'people_i_can_reach', null)],
  'hw_targets': [('field', 'top_below', null), ('field', 'bottom_below', null), ('radio', 'value', 'hw.targets.no_target_yet'), ('chips', 'when_should_we_remind_you', 'hw.targets.reminder_time')],
  'nu_habit': [('radio', 'value', 'nu.habit.habit'), ('toggle', 'track_weight', 'nu.habit.track_weight')],
  're_result': [('checklist', null, null)],
  'sd_plan': [('checklist', null, null)],
  'sd_safety': [('checklist', null, null)],
  'st_range': [('segmented', 'value', 'st.range.unit'), ('field', 'before_meals_from', null), ('field', 'to', null), ('field', '2_h_after_meals_below', null), ('field', 'low', null), ('field', 'my_low_steps', null)],
};

/// Settings screens that are not bound (validate.NOT_BOUND_SCREENS).
const _notBound = <String>{'auth_newpass', 'sf_unplug_off'};

/// A TData backed by notifiers, standing in for the app's real one.
class _MapData implements TData {
  _MapData([Map<String, Object?> values = const {}]) : notifiers = {for (final e in values.entries) e.key: ValueNotifier<Object?>(e.value)};
  final Map<String, ValueNotifier<Object?>> notifiers;
  @override
  ValueListenable<Object?> watch(String bindKey) => notifiers.putIfAbsent(bindKey, () => ValueNotifier<Object?>(null));
}

/// A loaded TData in which the member has nothing stored.
class _UnsetData implements TData {
  static const ValueListenable<Object?> _unset = _Fixed(TData.unset);
  @override
  ValueListenable<Object?> watch(String bindKey) => _unset;
}

class _Fixed implements ValueListenable<Object?> {
  const _Fixed(this.value);
  @override
  final Object? value;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

/// Records each submit with the touched keys and the session at that time.
class _Api implements TApi {
  final List<(String, String, Set<String>, Map<String, Object?>)> calls = [];
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async {
    calls.add((endpoint, screenId, TSession.touched(screenId), Map<String, Object?>.of(TSession.values)));
    return const TResult.ok();
  }
}

Map<String, dynamic> _screens() => jsonDecode(File('../spec/screens.json').readAsStringSync()) as Map<String, dynamic>;

/// Every node in a spec part, depth first.
Iterable<Map<String, dynamic>> _nodes(Object? v) sync* {
  if (v is Map<String, dynamic>) {
    yield v;
    for (final c in v.values) {
      yield* _nodes(c);
    }
  } else if (v is List) {
    for (final c in v) {
      yield* _nodes(c);
    }
  }
}

Iterable<Map<String, dynamic>> _controls(Map<String, dynamic> screen) => [..._nodes(screen['body']), ..._nodes(screen['footer'])];

/// A control that writes the session and so must be bound on a settings
/// screen (mirrors validate.needs_bind).
bool _needsBind(Map<String, dynamic> n) {
  if (n['key'] == null) return false;
  return switch (n['t']) {
    'field' => n['kind'] == 'select',
    'chips' || 'segmented' || 'radio' || 'toggle' || 'slider' || 'checklist' || 'tiles' => true,
    _ => false,
  };
}

/// Session keys of the bound controls on [sid].
Set<String> _boundKeys(Map<String, dynamic> screens, String sid) => {
      for (final n in _controls(screens[sid] as Map<String, dynamic>))
        if (n['bind'] != null) '$sid.${n['key']}'
    };

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _open(WidgetTester tester, String route, {String? program}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: (s) => s.name == '/__host' ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: '/__host')),
      AppRouter.onGenerateRoute(RouteSettings(name: route, arguments: program == null ? null : TRouteArgs(program: program)))!,
    ],
  ));
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester);
}

Finder _switchOf(String label) => find.descendant(
      of: find.byWidgetPredicate((w) => w is TToggleRow && w.label == label),
      matching: find.byType(Switch),
    );

bool _switchOn(WidgetTester tester, String label) => tester.widget<Switch>(_switchOf(label)).value;

/// The text [label] inside the control of type [within].
Finder _in(Type within, String label) => find.descendant(of: find.byType(within), matching: find.text(label));

/// The nearest Semantics flag (selected or checked) above the text [label]
/// inside the control of type [within].
bool _marked(WidgetTester tester, Type within, String label) {
  final text = _in(within, label);
  expect(text, findsOneWidget, reason: label);
  for (final s in tester.widgetList<Semantics>(find.ancestor(of: text, matching: find.byType(Semantics)))) {
    final flag = s.properties.selected ?? s.properties.checked;
    if (flag != null) return flag;
  }
  throw StateError('no selected/checked semantics above "$label"');
}

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<EditableText>(find.descendant(of: find.byKey(ValueKey('field:$key')), matching: find.byType(EditableText))).controller.text;

Iterable<String> _keysOf(String sid) => TSession.values.keys.where((k) => k.startsWith('$sid.'));

/// Ends the test after any toast has gone.
Future<void> _drain(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  late _Api api;

  setUp(() {
    TSession.clear();
    TFlow.onboarding = false;
    api = _Api();
    TApi.instance = api;
    TNav.branchResolver = (context, question, outcomes) async => outcomes.first;
  });
  tearDown(() {
    TDefaults.forPreview();
    TSession.clear();
  });

  group('spec', () {
    test('the generated class lists are the pinned ones', () {
      expect(consentSettingsScreens, _consent);
      expect(planSettingsScreens, _plan);
    });

    test('every session-writing control on a consent or plan screen is bound, and only there', () {
      final screens = _screens();
      final bound = {..._consent, ..._plan};
      for (final MapEntry(key: sid, value: s) in screens.entries) {
        for (final n in _controls(s as Map<String, dynamic>)) {
          if (bound.contains(sid) && _needsBind(n)) expect(n['bind'], isA<String>(), reason: '$sid ${n['t']} ${n['key']} has no bind');
          if (n['bind'] != null) expect(bound, contains(sid), reason: '$sid ${n['key']} is bound but not a consent or plan screen');
        }
      }
    });

    test('sf_unplug_off keeps its action choice unbound; every consent screen has bound controls', () {
      final screens = _screens();
      expect(_boundKeys(screens, 'sf_unplug_off'), isEmpty);
      for (final sid in _consent) {
        expect(_boundKeys(screens, sid), isNotEmpty, reason: sid);
      }
    });

    test('the plan-screen control inventory is pinned', () {
      final screens = _screens();
      const inputs = {'field', 'chips', 'segmented', 'radio', 'toggle', 'slider', 'checklist', 'tiles'};
      expect(_planInventory.keys.toSet(), _plan);
      for (final MapEntry(key: sid, value: want) in _planInventory.entries) {
        final got = [
          for (final n in _controls(screens[sid] as Map<String, dynamic>))
            if (inputs.contains(n['t'])) (n['t'] as String, n['key'] as String?, n['bind'] as String?)
        ];
        expect(got, want, reason: sid);
      }
    });

    test('program_settings binds per programme', () {
      final screens = _screens();
      for (final sid in ['program_settings', 'program_settings_sf']) {
        for (final n in _controls(screens[sid] as Map<String, dynamic>)) {
          if (n['bind'] != null) expect((n['bind'] as String).split('.'), contains(':program'), reason: '$sid ${n['key']}');
        }
      }
    });
  });

  group('every settings screen', () {
    final screens = _screens();
    for (final sid in {..._consent, ..._plan, ..._notBound}) {
      final route = (screens[sid] as Map<String, dynamic>)['route'] as String;
      final bound = _boundKeys(screens, sid);
      // P-31: a field's starting value is empty, so a bound field never writes one.
      final fields = {
        for (final n in _controls(screens[sid] as Map<String, dynamic>))
          if (n['bind'] != null && n['t'] == 'field') '$sid.${n['key']}'
      };
      final footer = (screens[sid] as Map<String, dynamic>)['footer'] as List;
      final submits = footer.isNotEmpty && _nodes((footer.first as Map<String, dynamic>)['action']).any((n) => n['type'] == 'submit');
      final cases = <(String, TData Function(), bool)>[
        ('not loaded', () => _MapData(), false),
        ('nothing stored', () => _UnsetData(), _plan.contains(sid)),
        ('preview data', () => PreviewData(), _plan.contains(sid)),
      ];
      for (final (name, data, writes) in cases) {
        testWidgets('$sid · $name: bound keys ${writes ? 'hold the starting value' : 'are not written'}; an untouched save has no touched key', (tester) async {
          TData.instance = data();
          await _open(tester, route, program: 'bf');
          for (final key in bound) {
            expect(TSession.values.containsKey(key), writes && !fields.contains(key), reason: '$key on open');
          }
          expect(TSession.touched(sid), isEmpty);
          final save = find.byKey(const ValueKey('a:footer[0]'));
          if (save.evaluate().isNotEmpty) await _tap(tester, save);
          if (submits) expect(api.calls, isNotEmpty, reason: 'footer[0] submits');
          for (final (endpoint, screenId, touched, values) in api.calls) {
            expect(screenId, sid, reason: endpoint);
            expect(touched, isEmpty, reason: '$endpoint: nothing was changed');
            for (final key in bound) {
              expect(values.containsKey(key), writes && !fields.contains(key), reason: '$endpoint and $key');
            }
          }
          await _drain(tester);
        });
      }
    }
  });

  group('toggles (account_privacy)', () {
    testWidgets('no stored state: every toggle shows off, including the designed-on one, and nothing is written', (tester) async {
      TData.instance = _MapData();
      await _open(tester, Routes.accountPrivacy);
      for (final label in ['Cross-program insights', 'De-identified research', 'Anonymous app diagnostics']) {
        expect(_switchOn(tester, label), isFalse, reason: label);
      }
      expect(_keysOf('account_privacy'), isEmpty);
      await _drain(tester);
    });

    testWidgets('stored values are shown, not the designed ones, and are not written', (tester) async {
      TData.instance = _MapData({'consents.cross_program_insights': false, 'consents.de_identified_research': true});
      await _open(tester, Routes.accountPrivacy);
      expect(_switchOn(tester, 'Cross-program insights'), isFalse);
      expect(_switchOn(tester, 'De-identified research'), isTrue);
      expect(_switchOn(tester, 'Anonymous app diagnostics'), isFalse);
      expect(_keysOf('account_privacy'), isEmpty);
      await _drain(tester);
    });

    testWidgets('a value the toggle cannot show is treated as unknown', (tester) async {
      TData.instance = _MapData({'consents.cross_program_insights': 'yes'});
      await _open(tester, Routes.accountPrivacy);
      expect(_switchOn(tester, 'Cross-program insights'), isFalse);
      expect(_keysOf('account_privacy'), isEmpty);
      await _drain(tester);
    });

    testWidgets('preview data shows the designed values and writes nothing', (tester) async {
      TData.instance = PreviewData();
      await _open(tester, Routes.accountPrivacy);
      expect(_switchOn(tester, 'Cross-program insights'), isTrue);
      expect(_switchOn(tester, 'De-identified research'), isFalse);
      expect(_keysOf('account_privacy'), isEmpty);
      await _drain(tester);
    });

    testWidgets('the member changes one toggle: only that key is written and touched; the save carries only it', (tester) async {
      TData.instance = _MapData({'consents.cross_program_insights': true, 'consents.de_identified_research': false, 'consents.anonymous_app_diagnostics': false});
      await _open(tester, Routes.accountPrivacy);
      await _tap(tester, _switchOf('De-identified research'));
      expect(TSession.values['account_privacy.de_identified_research'], isTrue);
      expect(TSession.touched('account_privacy'), {'account_privacy.de_identified_research'});
      expect(_keysOf('account_privacy'), ['account_privacy.de_identified_research']);
      await _tap(tester, find.byKey(const ValueKey('a:footer[0]')));
      expect(api.calls, hasLength(1));
      expect(api.calls.single.$1, 'PATCH /v1/enrolments/consents');
      expect(api.calls.single.$3, {'account_privacy.de_identified_research'});
      await _drain(tester);
    });

    testWidgets('flipped and flipped back: written, but not touched', (tester) async {
      TData.instance = _MapData({'consents.cross_program_insights': true});
      await _open(tester, Routes.accountPrivacy);
      await _tap(tester, _switchOf('Cross-program insights'));
      expect(TSession.touched('account_privacy'), {'account_privacy.cross_program_insights'});
      await _tap(tester, _switchOf('Cross-program insights'));
      expect(TSession.values['account_privacy.cross_program_insights'], isTrue);
      expect(TSession.touched('account_privacy'), isEmpty);
      await _drain(tester);
    });

    testWidgets('a toggle with no stored state that the member sets is touched, even when set to off', (tester) async {
      TData.instance = _MapData();
      await _open(tester, Routes.accountPrivacy);
      await _tap(tester, _switchOf('Anonymous app diagnostics'));
      await _tap(tester, _switchOf('Anonymous app diagnostics'));
      expect(TSession.values['account_privacy.anonymous_app_diagnostics'], isFalse);
      expect(TSession.touched('account_privacy'), {'account_privacy.anonymous_app_diagnostics'});
      await _drain(tester);
    });

    testWidgets('a stored value that arrives later is shown until the member sets the toggle', (tester) async {
      final data = _MapData();
      TData.instance = data;
      await _open(tester, Routes.accountPrivacy);
      expect(_switchOn(tester, 'Cross-program insights'), isFalse);
      data.notifiers['consents.cross_program_insights']!.value = true;
      await _settle(tester);
      expect(_switchOn(tester, 'Cross-program insights'), isTrue);
      expect(_keysOf('account_privacy'), isEmpty);
      await _tap(tester, _switchOf('Cross-program insights'));
      data.notifiers['consents.cross_program_insights']!.value = true;
      await _settle(tester);
      expect(_switchOn(tester, 'Cross-program insights'), isFalse);
      expect(TSession.values['account_privacy.cross_program_insights'], isFalse);
      expect(TSession.touched('account_privacy'), {'account_privacy.cross_program_insights'});
      await _drain(tester);
    });

    testWidgets('a change left unsaved is not carried into the next visit', (tester) async {
      TData.instance = _MapData({'consents.de_identified_research': false});
      await _open(tester, Routes.accountPrivacy);
      await _tap(tester, _switchOf('De-identified research'));
      expect(TSession.touched('account_privacy'), isNotEmpty);
      await _open(tester, Routes.accountPrivacy);
      expect(_switchOn(tester, 'De-identified research'), isFalse);
      expect(_keysOf('account_privacy'), isEmpty);
      expect(TSession.touched('account_privacy'), isEmpty);
      await _drain(tester);
    });
  });

  group('other bound controls', () {
    testWidgets('checklist (sd_caregiver): stored ticks shown, nothing written; a tick is touched, unticking it again is not', (tester) async {
      TData.instance = _MapData({'sd.caregiver.can_see': ['If I log a fall']});
      await _open(tester, Routes.sdCaregiver);
      expect(_marked(tester, TChecklist, 'When I finish a session'), isFalse);
      expect(_marked(tester, TChecklist, 'If I log a fall'), isTrue);
      expect(TSession.values.containsKey('sd_caregiver.caregiver_can_see'), isFalse);
      await _tap(tester, _in(TChecklist, 'When I finish a session'));
      expect(TSession.values['sd_caregiver.caregiver_can_see'], ['When I finish a session', 'If I log a fall']);
      expect(TSession.isTouched('sd_caregiver.caregiver_can_see'), isTrue);
      await _tap(tester, _in(TChecklist, 'When I finish a session'));
      expect(TSession.values['sd_caregiver.caregiver_can_see'], ['If I log a fall']);
      expect(TSession.isTouched('sd_caregiver.caregiver_can_see'), isFalse);
      await _drain(tester);
    });

    testWidgets('checklist (sf_buddy): no stored state shows nothing ticked, though the design ticks two', (tester) async {
      TData.instance = _MapData();
      await _open(tester, Routes.sfBuddy);
      expect(_marked(tester, TChecklist, 'A weekly “I hit my goal” message'), isFalse);
      expect(_marked(tester, TChecklist, 'Nothing automatic: I send each one'), isFalse);
      expect(TSession.values.containsKey('sf_buddy.buddy_can_see'), isFalse);
      await _drain(tester);
    });

    testWidgets('typed fields on a settings screen are touched while they hold text', (tester) async {
      TData.instance = _MapData();
      await _open(tester, Routes.sdCaregiver);
      final name = find.descendant(of: find.byKey(const ValueKey('field:sd_caregiver.name')), matching: find.byType(EditableText));
      await tester.enterText(name, 'Synthetic Caregiver');
      await _settle(tester);
      expect(TSession.touched('sd_caregiver'), {'sd_caregiver.name'});
      await tester.enterText(name, '');
      await _settle(tester);
      expect(TSession.touched('sd_caregiver'), isEmpty);
      await _drain(tester);
    });

    testWidgets('typed fields on a plan screen are touched while they differ from the start', (tester) async {
      TData.instance = _MapData();
      await _open(tester, Routes.stRange);
      final low = find.descendant(of: find.byKey(const ValueKey('field:st_range.low')), matching: find.byType(EditableText));
      await tester.enterText(low, '70');
      await _settle(tester);
      expect(TSession.touched('st_range'), {'st_range.low'});
      await _drain(tester);
    });
  });

  group('class × stored value', () {
    // Consent class: account_privacy "Cross-program insights" is designed on.
    for (final (name, stored) in [('stored off', false as Object?), ('nothing stored', TData.unset), ('not loaded', null)]) {
      testWidgets('consent · $name: shows off and writes nothing', (tester) async {
        TData.instance = _MapData({'consents.cross_program_insights': stored});
        await _open(tester, Routes.accountPrivacy);
        expect(_switchOn(tester, 'Cross-program insights'), isFalse);
        expect(TSession.values.containsKey('account_privacy.cross_program_insights'), isFalse);
        expect(TSession.touched('account_privacy'), isEmpty);
        await _drain(tester);
      });
    }

    testWidgets('consent · stored on: shows on and writes nothing', (tester) async {
      TData.instance = _MapData({'consents.anonymous_app_diagnostics': true});
      await _open(tester, Routes.accountPrivacy);
      expect(_switchOn(tester, 'Anonymous app diagnostics'), isTrue);
      expect(_keysOf('account_privacy'), isEmpty);
      await _drain(tester);
    });

    // Plan class: st_range unit is designed "mg/dL".
    testWidgets('plan · stored: the stored option is shown and written', (tester) async {
      TData.instance = _MapData({'st.range.unit': 'mmol/L'});
      await _open(tester, Routes.stRange);
      expect(_marked(tester, TSegmented, 'mmol/L'), isTrue);
      expect(_marked(tester, TSegmented, 'mg/dL'), isFalse);
      expect(TSession.values['st_range.value'], 'mmol/L');
      expect(TSession.touched('st_range'), isEmpty);
      await _drain(tester);
    });

    testWidgets('plan · nothing stored: the designed option is shown and written', (tester) async {
      TData.instance = _MapData({'st.range.unit': TData.unset});
      await _open(tester, Routes.stRange);
      expect(_marked(tester, TSegmented, 'mg/dL'), isTrue);
      expect(TSession.values['st_range.value'], 'mg/dL');
      expect(TSession.touched('st_range'), isEmpty);
      await _tap(tester, _in(TSegmented, 'mmol/L'));
      expect(TSession.touched('st_range'), {'st_range.value'});
      await _tap(tester, _in(TSegmented, 'mg/dL'));
      expect(TSession.touched('st_range'), isEmpty);
      await _drain(tester);
    });

    testWidgets('plan · not loaded: nothing selected and nothing written', (tester) async {
      TData.instance = _MapData();
      await _open(tester, Routes.stRange);
      expect(_marked(tester, TSegmented, 'mg/dL'), isFalse);
      expect(_marked(tester, TSegmented, 'mmol/L'), isFalse);
      expect(TSession.values.containsKey('st_range.value'), isFalse);
      await _tap(tester, _in(TSegmented, 'mg/dL'));
      expect(TSession.values['st_range.value'], 'mg/dL');
      expect(TSession.touched('st_range'), {'st_range.value'});
      await _drain(tester);
    });

    testWidgets('plan · loaded later: not loaded writes nothing, then the stored value is written', (tester) async {
      final data = _MapData();
      TData.instance = data;
      await _open(tester, Routes.stRange);
      expect(TSession.values.containsKey('st_range.value'), isFalse);
      data.notifiers['st.range.unit']!.value = TData.unset;
      await _settle(tester);
      expect(TSession.values['st_range.value'], 'mg/dL');
      data.notifiers['st.range.unit']!.value = null;
      await _settle(tester);
      expect(TSession.values.containsKey('st_range.value'), isFalse);
      await _drain(tester);
    });

    testWidgets('plan toggle (bf_meds_edit): nothing stored keeps the designed "on"; stored off is shown and written', (tester) async {
      TData.instance = _MapData({'bf.meds.private_reminder': TData.unset});
      await _open(tester, Routes.bfMedsEdit);
      expect(_switchOn(tester, 'Private reminder'), isTrue);
      expect(TSession.values['bf_meds_edit.private_reminder'], isTrue);
      TData.instance = _MapData({'bf.meds.private_reminder': false});
      await _open(tester, Routes.bfMedsEdit);
      expect(_switchOn(tester, 'Private reminder'), isFalse);
      expect(TSession.values['bf_meds_edit.private_reminder'], isFalse);
      await _drain(tester);
    });

    testWidgets('plan chips (hw_targets): nothing stored keeps "Both"; stored "Morning" is shown and written; a new choice is touched', (tester) async {
      TData.instance = _MapData({'hw.targets.reminder_time': TData.unset});
      await _open(tester, Routes.hwTargets);
      expect(_marked(tester, TChips, 'Both'), isTrue);
      expect(TSession.values['hw_targets.when_should_we_remind_you'], ['Both']);
      TData.instance = _MapData({'hw.targets.reminder_time': ['Morning']});
      await _open(tester, Routes.hwTargets);
      expect(_marked(tester, TChips, 'Morning'), isTrue);
      expect(_marked(tester, TChips, 'Both'), isFalse);
      expect(TSession.values['hw_targets.when_should_we_remind_you'], ['Morning']);
      await _tap(tester, _in(TChips, 'Evening'));
      expect(TSession.values['hw_targets.when_should_we_remind_you'], ['Evening']);
      expect(TSession.touched('hw_targets'), {'hw_targets.when_should_we_remind_you'});
      await _drain(tester);
    });

    testWidgets('plan select field (bf_meds_edit): stored text shown and written; nothing stored or not loaded leaves it empty and unwritten', (tester) async {
      TData.instance = _MapData({'bf.meds.medicine': 'Synthetic medicine', 'bf.meds.when': TData.unset});
      await _open(tester, Routes.bfMedsEdit);
      expect(_fieldText(tester, 'bf_meds_edit.medicine'), 'Synthetic medicine');
      expect(TSession.values['bf_meds_edit.medicine'], 'Synthetic medicine');
      expect(_fieldText(tester, 'bf_meds_edit.when'), isEmpty);
      expect(TSession.values.containsKey('bf_meds_edit.when'), isFalse);
      // Another key changing does not empty the shown stored text.
      final strength = find.descendant(of: find.byKey(const ValueKey('field:bf_meds_edit.strength')), matching: find.byType(EditableText));
      await tester.enterText(strength, '1');
      await _settle(tester);
      expect(_fieldText(tester, 'bf_meds_edit.medicine'), 'Synthetic medicine');
      await _drain(tester);
    });

    testWidgets('consent radio (program_settings): nothing stored shows no status and writes nothing', (tester) async {
      TData.instance = _MapData({'enrolment.bf.status': TData.unset});
      await _open(tester, Routes.programSettings, program: 'bf');
      for (final label in ['Focus', 'Learn only', 'Pause']) {
        expect(_marked(tester, TRadioList, label), isFalse, reason: label);
      }
      expect(_keysOf('program_settings'), isEmpty);
      await _drain(tester);
    });
  });

  group('programme context (program_settings)', () {
    testWidgets('stored values are read for the programme the screen was opened for', (tester) async {
      TData.instance = _MapData({'enrolment.bf.status': 'Pause', 'enrolment.sf.status': 'Focus', 'enrolment.bf.care_team_sharing': false});
      await _open(tester, Routes.programSettings, program: 'bf');
      expect(_marked(tester, TRadioList, 'Pause'), isTrue);
      expect(_marked(tester, TRadioList, 'Focus'), isFalse);
      expect(_switchOn(tester, 'Care team · Dr. Patel’s clinic'), isFalse);
      expect(_keysOf('program_settings'), isEmpty);
      await _tap(tester, _in(TRadioList, 'Focus'));
      expect(TSession.values['program_settings.status'], 'Focus');
      expect(TSession.touched('program_settings'), {'program_settings.status'});
      await _drain(tester);
    });

    testWidgets('opened without a programme: nothing is shown or written, whatever is stored', (tester) async {
      TData.instance = _MapData({'enrolment.bf.status': 'Pause', 'enrolment.:program.status': 'Pause', 'enrolment.status': 'Pause'});
      await _open(tester, Routes.programSettings);
      for (final label in ['Focus', 'Learn only', 'Pause']) {
        expect(_marked(tester, TRadioList, label), isFalse, reason: label);
      }
      expect(_keysOf('program_settings'), isEmpty);
      await _drain(tester);
    });

    testWidgets('a programme home passes its programme to program settings', (tester) async {
      TData.instance = _MapData({'enrolment.hw.status': 'Learn only'});
      await _open(tester, Routes.hwHome);
      final row = find.text('Program settings');
      await tester.ensureVisible(row);
      await _tap(tester, row);
      expect(find.byType(TRadioList), findsOneWidget);
      expect(_marked(tester, TRadioList, 'Learn only'), isTrue);
      await _drain(tester);
    });

    testWidgets('each Programs & sharing row passes its own programme', (tester) async {
      TData.instance = _MapData({'enrolment.ca.status': 'Pause'});
      await _open(tester, Routes.accountPrograms);
      await _tap(tester, find.text('ClearAir'));
      expect(_marked(tester, TRadioList, 'Pause'), isTrue);
      await _drain(tester);
    });

    test('TData.resolve', () {
      expect(TData.resolve('enrolment.:program.status', 'bf'), 'enrolment.bf.status');
      expect(TData.resolve('enrolment.:program.status', null), isNull);
      expect(TData.resolve('enrolment.:program.status', ''), isNull);
      expect(TData.resolve('consents.de_identified_research', null), 'consents.de_identified_research');
    });

    test('TData.resolve rejects anything but a two-letter programme id', () {
      for (final bad in ['BF', 'b', 'bff', 'b1', 'bf.status', 'sf.x', '../bf', ' bf', 'bf ', '*', ':program', 'bf\n']) {
        expect(TData.resolve('enrolment.:program.status', bad), isNull, reason: bad);
      }
      expect(TData.resolve('enrolment.:program.status', 'sf'), 'enrolment.sf.status');
    });

    testWidgets('a malformed programme in the route arguments shows nothing and writes nothing', (tester) async {
      TData.instance = _MapData({'enrolment.bf.x.status': 'Pause', 'enrolment.bf.status': 'Pause'});
      await _open(tester, Routes.programSettings, program: 'bf.x');
      for (final label in ['Focus', 'Learn only', 'Pause']) {
        expect(_marked(tester, TRadioList, label), isFalse, reason: label);
      }
      expect(_keysOf('program_settings'), isEmpty);
      await _drain(tester);
    });
  });

  group('session', () {
    test('clear() and scrub() drop touched keys', () {
      TSession.set('s.a', true);
      TSession.markTouched('s.a', true);
      TSession.markTouched('s.b', true);
      expect(TSession.touched('s'), {'s.a', 's.b'});
      TSession.scrub(['s.a']);
      expect(TSession.touched('s'), {'s.b'});
      TSession.clear();
      expect(TSession.touched('s'), isEmpty);
    });

    test('touched() is per screen and read-only', () {
      TSession.markTouched('s.a', true);
      TSession.markTouched('st.a', true);
      expect(TSession.touched('s'), {'s.a'});
      expect(() => TSession.touched('s').add('s.x'), throwsUnsupportedError);
    });
  });

  group('unbound controls (not settings screens)', () {
    testWidgets('ob_consent still writes each starting value; a change is touched, a change back is not', (tester) async {
      TData.instance = _MapData();
      await _open(tester, Routes.obConsent);
      expect(TSession.values['ob_consent.essential_app_data'], isTrue);
      expect(TSession.values['ob_consent.private_reminders'], isFalse);
      expect(TSession.touched('ob_consent'), isEmpty);
      await _tap(tester, _switchOf('Private reminders'));
      expect(TSession.touched('ob_consent'), {'ob_consent.private_reminders'});
      await _tap(tester, _switchOf('Private reminders'));
      expect(TSession.touched('ob_consent'), isEmpty);
      await _drain(tester);
    });
  });
}
