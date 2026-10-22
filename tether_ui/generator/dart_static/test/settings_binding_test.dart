// Settings binding (P-71). On a settings screen (`settingsScreens`) every
// input control that writes the session is bound (spec `bind`) and starts
// from the member's stored value in TData:
// - while that value is null the control shows its empty state and writes
//   nothing to TSession; the spec's starting value is never written;
// - TSession.touched lists only the keys the member changed on the screen
//   now shown, so a save without changes has nothing to send;
// - a control set back to its starting value is not touched.
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

/// The settings screens, by the rule "a submit updates existing state"
/// (PATCH, PUT, or the caregiver sharing POST). Pinned here and in
/// generator/validate.py (SETTINGS_SCREENS).
const _pinned = <String>{
  'account_notifications', 'account_privacy', 'auth_newpass', 'be_q2', 'bf_meds_edit', 'bf_review', 'ca_plan', 'ck_q1', //
  'ea_plan', 'hw_targets', 'nu_habit', 'program_settings', 'program_settings_sf', 're_result', 'sd_caregiver', 'sd_plan', //
  'sd_safety', 'sf_buddy', 'sf_unplug_off', 'st_range',
};

/// A TData backed by notifiers, standing in for the app's real one.
class _MapData implements TData {
  _MapData([Map<String, Object?> values = const {}]) : notifiers = {for (final e in values.entries) e.key: ValueNotifier<Object?>(e.value)};
  final Map<String, ValueNotifier<Object?>> notifiers;
  @override
  ValueListenable<Object?> watch(String bindKey) => notifiers.putIfAbsent(bindKey, () => ValueNotifier<Object?>(null));
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

Future<void> _open(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: (s) => s.name == '/__host' ? MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: s) : AppRouter.onGenerateRoute(s),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: '/__host')),
      AppRouter.onGenerateRoute(RouteSettings(name: route))!,
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
    test('settingsScreens is the pinned list', () {
      expect(settingsScreens, _pinned);
    });

    test('every session-writing control on a settings screen is bound, and only there', () {
      final screens = _screens();
      for (final MapEntry(key: sid, value: s) in screens.entries) {
        for (final n in _controls(s as Map<String, dynamic>)) {
          if (settingsScreens.contains(sid) && _needsBind(n)) expect(n['bind'], isA<String>(), reason: '$sid ${n['t']} ${n['key']} has no bind');
          if (n['bind'] != null) expect(settingsScreens, contains(sid), reason: '$sid ${n['key']} is bound but not a settings screen');
        }
      }
    });

    test('the six screens named by the ruling are settings screens with bound controls', () {
      final screens = _screens();
      for (final sid in ['account_notifications', 'account_privacy', 'program_settings', 'sf_unplug_off', 'sd_caregiver', 'sf_buddy']) {
        expect(settingsScreens, contains(sid));
        expect(_boundKeys(screens, sid), isNotEmpty, reason: sid);
      }
    });
  });

  group('every settings screen', () {
    final screens = _screens();
    for (final sid in _pinned) {
      final route = (screens[sid] as Map<String, dynamic>)['route'] as String;
      final bound = _boundKeys(screens, sid);
      final footer = (screens[sid] as Map<String, dynamic>)['footer'] as List;
      final submits = footer.isNotEmpty && _nodes((footer.first as Map<String, dynamic>)['action']).any((n) => n['type'] == 'submit');
      for (final (name, data) in [('no stored state', () => const TEmptyData() as TData), ('preview data', () => PreviewData() as TData)]) {
        testWidgets('$sid · $name: opening writes no bound key and an untouched save has no touched key', (tester) async {
          TData.instance = data();
          await _open(tester, route);
          for (final key in bound) {
            expect(TSession.values.containsKey(key), isFalse, reason: '$key was written on open');
          }
          expect(TSession.touched(sid), isEmpty);
          final save = find.byKey(const ValueKey('a:footer[0]'));
          if (save.evaluate().isNotEmpty) await _tap(tester, save);
          if (submits) expect(api.calls, isNotEmpty, reason: 'footer[0] submits');
          for (final (endpoint, screenId, touched, values) in api.calls) {
            expect(screenId, sid, reason: endpoint);
            expect(touched, isEmpty, reason: '$endpoint: nothing was changed');
            for (final key in bound) {
              expect(values.containsKey(key), isFalse, reason: '$endpoint carried $key');
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

    testWidgets('segmented (st_range): stored option shown; unknown shows none selected', (tester) async {
      TData.instance = _MapData({'st.range.unit': 'mmol/L'});
      await _open(tester, Routes.stRange);
      expect(_marked(tester, TSegmented, 'mmol/L'), isTrue);
      expect(_marked(tester, TSegmented, 'mg/dL'), isFalse);
      TData.instance = _MapData();
      await _open(tester, Routes.stRange);
      expect(_marked(tester, TSegmented, 'mmol/L'), isFalse);
      expect(_marked(tester, TSegmented, 'mg/dL'), isFalse);
      expect(TSession.values.containsKey('st_range.value'), isFalse);
      await _tap(tester, _in(TSegmented, 'mg/dL'));
      expect(TSession.values['st_range.value'], 'mg/dL');
      expect(TSession.touched('st_range'), {'st_range.value'});
      await _drain(tester);
    });

    testWidgets('radio (program_settings): stored status shown; unknown shows none; a tap is touched', (tester) async {
      TData.instance = _MapData({'enrolment.status': 'Pause'});
      await _open(tester, Routes.programSettings);
      expect(_marked(tester, TRadioList, 'Pause'), isTrue);
      expect(_marked(tester, TRadioList, 'Focus'), isFalse);
      expect(_switchOn(tester, 'Care team · Dr. Patel’s clinic'), isFalse);
      expect(_keysOf('program_settings'), isEmpty);
      TData.instance = _MapData();
      await _open(tester, Routes.programSettings);
      for (final label in ['Focus', 'Learn only', 'Pause']) {
        expect(_marked(tester, TRadioList, label), isFalse, reason: label);
      }
      await _tap(tester, _in(TRadioList, 'Focus'));
      expect(TSession.values['program_settings.status'], 'Focus');
      expect(TSession.touched('program_settings'), {'program_settings.status'});
      await _drain(tester);
    });

    testWidgets('chips (hw_targets): stored choice shown; a different choice is touched', (tester) async {
      TData.instance = _MapData({'hw.targets.reminder_time': ['Morning']});
      await _open(tester, Routes.hwTargets);
      expect(_marked(tester, TChips, 'Morning'), isTrue);
      expect(_marked(tester, TChips, 'Both'), isFalse);
      expect(TSession.values.containsKey('hw_targets.when_should_we_remind_you'), isFalse);
      await _tap(tester, _in(TChips, 'Evening'));
      expect(TSession.values['hw_targets.when_should_we_remind_you'], ['Evening']);
      expect(TSession.touched('hw_targets'), {'hw_targets.when_should_we_remind_you'});
      await _drain(tester);
    });

    testWidgets('select field (bf_meds_edit): stored text shown; unknown leaves it empty; neither is written', (tester) async {
      TData.instance = _MapData({'bf.meds.medicine': 'Synthetic medicine'});
      await _open(tester, Routes.bfMedsEdit);
      expect(_fieldText(tester, 'bf_meds_edit.medicine'), 'Synthetic medicine');
      expect(_fieldText(tester, 'bf_meds_edit.when'), isEmpty);
      expect(TSession.values.containsKey('bf_meds_edit.medicine'), isFalse);
      expect(TSession.values.containsKey('bf_meds_edit.when'), isFalse);
      // Another key changing does not empty the shown stored text.
      final strength = find.descendant(of: find.byKey(const ValueKey('field:bf_meds_edit.strength')), matching: find.byType(EditableText));
      await tester.enterText(strength, '1');
      await _settle(tester);
      expect(_fieldText(tester, 'bf_meds_edit.medicine'), 'Synthetic medicine');
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
