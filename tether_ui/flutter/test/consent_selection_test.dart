// Consent-creating selections (P-78, P-79). On these screens nothing starts
// selected, so the screen shows exactly what will be sent: the supporter's
// programmes (support_add_person), what Tether may read (records_consent,
// records_consent_bb, records_consent_device), the imported items to add
// (records_review) and the conflict choices (records_conflict). Each primary
// action asks its "chosen" rule first: with nothing selected it shows a
// message and sends nothing; otherwise it does what it did. On
// records_review each item's keep/skip choice reaches the accept call under
// its programme's key, and only kept items are in it.
//
// The payload checks read the submitting screen's own session keys at the
// moment of the submit, which is what the app's endpoint registry hands its
// handler (lib/integration/registry.dart: the keys under "<screenId>.").
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/ui/ui.dart';

/// Messages shown when the primary action is tapped with nothing selected.
/// Draft wording, pending clinical/legal copy review.
const _supporterNone = 'Select at least one program.';
const _readNone = 'Select at least one item to continue.';
const _reviewNone = 'Select the items you want to add.';
const _conflictNone = 'Choose an option for at least one item.';

/// Each pinned control: screen → (key, control type, item or option labels).
const _controls = <String, List<(String, String, List<String>)>>{
  'support_add_person': [('which_programs', 'chips', ['BreatheFree', 'ScrollFree'])],
  'records_consent': [('resources', 'checklist', ['Conditions', 'Vital signs', 'Lab results', 'Medications', 'Immunizations', 'Smoking status', 'Clinical notes'])],
  'records_consent_bb': [('resources', 'checklist', ['Conditions', 'Vital signs', 'Lab results', 'Medications', 'Immunizations', 'Smoking status', 'Clinical notes'])],
  'records_consent_device': [('data_types', 'checklist', ['Blood pressure', 'Blood glucose', 'Clinical records (iPhone)', 'Steps and sleep'])],
  'records_review': [
    ('keep_hw', 'checklist', ['12 blood pressure readings', 'Lipid panel']),
    ('keep_st', 'checklist', ['A1C 7.6%']),
    ('keep_ck', 'checklist', ['Flu vaccine', 'Tdap']),
    ('keep_bf', 'checklist', ['Smoking status: every day smoker']),
    ('keep_re', 'checklist', ['eGFR 58']),
  ],
  'records_conflict': [
    ('a1c', 'radio', ['From Patel Family Medicine (Epic): 7.6%', 'Entered by you: 7.4%', 'Keep both']),
    ('bp', 'radio', ['Discard', 'Keep as 129/80', 'Ask my care team']),
  ],
};

/// Each screen's primary action: screen → (element label, rule, message,
/// type of the action the "Chosen" case runs).
const _gates = <String, (String, String, String, String)>{
  'support_add_person': ('Save supporter', 'sup.programs', _supporterNone, 'submit'),
  'records_consent': ('Continue to MyChart', 'rec.consent.epic', _readNone, 'branch'),
  'records_consent_bb': ('Continue to Medicare.gov', 'rec.consent.medicare', _readNone, 'branch'),
  'records_consent_device': ('Continue', 'rec.consent.device', _readNone, 'branch'),
  'records_review': ('Add selected items to my programs', 'rec.review', _reviewNone, 'submit'),
  'records_conflict': ('Save choices', 'rec.conflict', _conflictNone, 'submit'),
};

/// Records each submit with the screen's own session keys at that moment.
class _Api implements TApi {
  final List<(String, String)> calls = [];
  final List<Map<String, Object?>> payloads = [];
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async {
    calls.add((endpoint, screenId));
    payloads.add({
      for (final MapEntry(:key, :value) in TSession.values.entries)
        if (key.startsWith('$screenId.')) key: value is List ? List<Object?>.of(value) : value,
    });
    return const TResult.ok();
  }
}

/// Records each device question and answers it with [answer].
class _Device implements TDevice {
  _Device(this.answer);
  final TAnswer answer;
  final List<TBranchRef> asked = [];
  @override
  Future<TAnswer?> ask(BuildContext context, TBranchRef branch) async {
    asked.add(branch);
    return answer;
  }
}

final Map<String, String> _routeOf = {for (final s in AppRouter.catalog) s.$1: s.$4};

Map<String, dynamic> _spec(String id) => jsonDecode(File('../spec/screens/$id.json').readAsStringSync()) as Map<String, dynamic>;

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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _open(WidgetTester tester, String screen) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const Scaffold(), settings: const RouteSettings(name: '/__host')),
      AppRouter.onGenerateRoute(RouteSettings(name: _routeOf[screen]))!,
    ],
  ));
  await _settle(tester);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsOneWidget, reason: text);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester);
}

Future<void> _tapPrimary(WidgetTester tester) async {
  final finder = find.byKey(const ValueKey('a:footer[0]'));
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester);
}

Future<void> _drain(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pump(const Duration(seconds: 3));
}

/// Whether a session value holds a selection.
bool _selected(Object? v) => v is List ? v.isNotEmpty : v != null;

void main() {
  late _Api api;
  late _Device device;
  late TFailClosedResolver resolver;

  setUp(() {
    TSession.clear();
    TDefaults.forRelease();
    resolver = TFailClosedResolver();
    TNav.branchResolver = resolver.resolve;
    api = _Api();
    TApi.instance = api;
    device = _Device(TAnswer.granted);
    TDevice.instance = device;
  });
  tearDown(() {
    TDefaults.forPreview();
    TSession.clear();
  });

  group('spec', () {
    for (final MapEntry(key: screen, value: controls) in _controls.entries) {
      test('$screen: every pinned selection starts unselected and is not bound', () {
        final spec = _spec(screen);
        for (final (key, type, labels) in controls) {
          final found = [for (final n in _nodes([spec['body'], spec['footer']])) if (n['key'] == key && n['t'] is String) n];
          expect(found, hasLength(1), reason: '$screen.$key');
          final n = found.single;
          expect(n['t'], type, reason: '$screen.$key');
          expect(n['bind'], isNull, reason: '$screen.$key');
          switch (type) {
            case 'chips':
              expect(n['options'], labels);
              expect(n['selected'], isEmpty, reason: '$screen.$key: no chip starts selected');
            case 'checklist':
              final items = (n['items'] as List).cast<Map<String, dynamic>>();
              expect(items.map((i) => i['label']), labels);
              expect(items.where((i) => i['done'] == true), isEmpty, reason: '$screen.$key: no item starts ticked');
            case 'radio':
              expect((n['items'] as List).map((i) => (i as Map)['label']), labels);
              expect(n['selected'], -1, reason: '$screen.$key: no option starts chosen');
          }
        }
      });
    }

    test('records_review: every checklist is keyed, so each choice reaches the accept call', () {
      final spec = _spec('records_review');
      final lists = [for (final n in _nodes(spec['body'])) if (n['t'] == 'checklist') n['key']];
      expect(lists, ['keep_hw', 'keep_st', 'keep_ck', 'keep_bf', 'keep_re']);
    });

    for (final MapEntry(key: screen, value: (label, rule, message, inner)) in _gates.entries) {
      test('$screen: "$label" asks $rule first; nothing chosen shows the message and does nothing else', () {
        final actions = {for (final a in (_spec(screen)['actions'] as List).cast<Map<String, dynamic>>()) a['element'] as String: a['action'] as Map<String, dynamic>};
        final a = actions[label]!;
        expect(a['type'], 'branch');
        expect(a['decide'], rule);
        final cases = (a['cases'] as List).cast<Map<String, dynamic>>();
        expect(cases.map((c) => c['label']), ['Chosen', 'Nothing chosen']);
        expect((cases[0]['action'] as Map)['type'], inner);
        expect(cases[1]['action'], {'type': 'toast', 'value': message});
      });
    }

    test('rules.json: each chosen rule reads exactly its own screen\'s pinned keys', () {
      final rules = jsonDecode(File('../spec/rules.json').readAsStringSync()) as Map<String, dynamic>;
      for (final MapEntry(key: screen, value: (_, rule, _, _)) in _gates.entries) {
        final r = rules[rule] as Map<String, dynamic>;
        expect(r['inputs'], [for (final (key, _, _) in _controls[screen]!) '$screen.$key'], reason: rule);
        expect(r['outcomes'], {'chosen': 'Chosen', 'none': 'Nothing chosen'}, reason: rule);
      }
    });
  });

  group('rules', () {
    for (final MapEntry(key: screen, value: (_, rule, _, _)) in _gates.entries) {
      test('$rule: chosen only when one of its inputs holds a selection', () {
        final keys = [for (final (key, _, _) in _controls[screen]!) '$screen.$key'];
        expect(TRules.decide(rule, const {}), 'Nothing chosen');
        expect(TRules.decide(rule, {for (final k in keys) k: <String>[]}), 'Nothing chosen');
        expect(TRules.decide(rule, {for (final k in keys) k: null}), 'Nothing chosen');
        expect(TRules.decide(rule, {for (final k in keys) k: ' '}), 'Nothing chosen');
        for (final k in keys) {
          expect(TRules.decide(rule, {for (final o in keys) o: o == k ? ['x'] : <String>[]}), 'Chosen', reason: '$rule: $k as a list');
          expect(TRules.decide(rule, {k: 'x'}), 'Chosen', reason: '$rule: $k as a chosen item');
        }
        // Another screen's selection never counts.
        expect(TRules.decide(rule, const {'other_screen.which_programs': ['BreatheFree'], 'records_consent_x.resources': ['Conditions']}), 'Nothing chosen');
      });
    }
  });

  group('screens', () {
    for (final MapEntry(key: screen, value: controls) in _controls.entries) {
      final (label, _, message, _) = _gates[screen]!;
      testWidgets('$screen opens with nothing selected; "$label" shows the message and sends nothing', (tester) async {
        await _open(tester, screen);
        for (final (key, _, _) in controls) {
          expect(_selected(TSession.values['$screen.$key']), isFalse, reason: '$screen.$key');
        }
        expect(find.byIcon(Icons.check_rounded), findsNothing, reason: 'nothing shows as selected');
        await _tapPrimary(tester);
        expect(find.text(message), findsOneWidget);
        expect(api.calls, isEmpty, reason: 'no submit');
        expect(device.asked, isEmpty, reason: 'no sign-in or permission request');
        expect(resolver.recorded, isEmpty, reason: 'the rule decides');
        expect(find.text(label), findsOneWidget, reason: 'stays on $screen');
        await _drain(tester);
      });
    }

    testWidgets('support_add_person: only the chosen programme is saved', (tester) async {
      await _open(tester, 'support_add_person');
      await _tapText(tester, 'ScrollFree');
      await _tapPrimary(tester);
      expect(api.calls, [('POST /v1/care/supporters', 'support_add_person')]);
      expect(api.payloads.single['support_add_person.which_programs'], ['ScrollFree']);
      expect(find.text(_supporterNone), findsNothing);
      await _drain(tester);
    });

    for (final (screen, item, id) in const [
      ('records_consent', 'Lab results', 'records.connect.mychart'),
      ('records_consent_bb', 'Conditions', 'records.connect.medicare'),
      ('records_consent_device', 'Blood glucose', 'records.device.health_records_request'),
    ]) {
      testWidgets('$screen: with "$item" selected Continue asks the device, and only "$item" is in the session', (tester) async {
        final key = screen == 'records_consent_device' ? '$screen.data_types' : '$screen.resources';
        await _open(tester, screen);
        await _tapText(tester, item);
        expect(TSession.values[key], [item]);
        await _tapPrimary(tester);
        expect(device.asked.map((r) => r.id), [id]);
        expect(api.calls, isEmpty);
        await _drain(tester);
      });
    }

    testWidgets('records_review: only kept items reach POST /v1/records/fhir/accept', (tester) async {
      await _open(tester, 'records_review');
      await _tapText(tester, '12 blood pressure readings');
      await _tapText(tester, 'Tdap');
      await _tapText(tester, 'eGFR 58');
      await _tapText(tester, 'Tdap'); // kept, then skipped again
      await _tapPrimary(tester);
      expect(api.calls, [('POST /v1/records/fhir/accept', 'records_review')]);
      expect(api.payloads.single, {
        'records_review.keep_hw': ['12 blood pressure readings'],
        'records_review.keep_st': <String>[],
        'records_review.keep_ck': <String>[],
        'records_review.keep_bf': <String>[],
        'records_review.keep_re': ['eGFR 58'],
      });
      final sent = {for (final v in api.payloads.single.values) ...(v! as List)};
      expect(sent, {'12 blood pressure readings', 'eGFR 58'}, reason: 'skipped items are not sent');
      await _drain(tester);
    });

    testWidgets('records_review: keeping every item sends every item', (tester) async {
      await _open(tester, 'records_review');
      final all = [for (final (_, _, labels) in _controls['records_review']!) ...labels];
      for (final item in all) {
        await _tapText(tester, item);
      }
      await _tapPrimary(tester);
      final sent = [for (final v in api.payloads.single.values) ...(v! as List)];
      expect(sent, unorderedEquals(all));
      await _drain(tester);
    });

    testWidgets('records_conflict: only the conflict the member answered is sent', (tester) async {
      await _open(tester, 'records_conflict');
      await _tapText(tester, 'Keep as 129/80');
      await _tapPrimary(tester);
      expect(api.calls, [('POST /v1/records/fhir/conflicts', 'records_conflict')]);
      expect(api.payloads.single, {'records_conflict.a1c': null, 'records_conflict.bp': 'Keep as 129/80'});
      await _drain(tester);
    });
  });
}
