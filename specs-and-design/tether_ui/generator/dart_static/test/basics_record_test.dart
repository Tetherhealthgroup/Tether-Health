// ob_basics records what the member enters under `ob_basics.<key>`: the name
// they type, the age range they pick from the list, and the sleep and stress
// bands they tap. The age range is the stored band (`35_44`), whatever the
// language shows. Nothing is written for the examples. Synthetic values only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

const _name = 'ob_basics.what_should_we_call_you';
const _age = 'ob_basics.age_range';
const _sleep = 'ob_basics.sleep_on_a_typical_night';
const _stress = 'ob_basics.usual_stress';

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    onGenerateInitialRoutes: (_) => [AppRouter.onGenerateRoute(const RouteSettings(name: Routes.obBasics))!],
  ));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Finder _field(String key) => find.byKey(ValueKey('field:$key'));

Future<void> _pickAge(WidgetTester tester, String value) async {
  await tester.ensureVisible(_field(_age));
  await tester.tap(_field(_age));
  await _settle(tester);
  await tester.tap(find.byKey(ValueKey('option:$value')));
  await _settle(tester);
}

String _shown(WidgetTester tester, String key) => tester.widget<TextField>(find.descendant(of: _field(key), matching: find.byType(TextField))).controller!.text;

void main() {
  setUp(TSession.clear);
  tearDown(TSession.clear);

  testWidgets('before anything is entered the name and age range are empty, and the examples are not recorded', (tester) async {
    await _open(tester);
    expect(TSession.values[_name], isNull);
    expect(TSession.values[_age], isNull);
    expect(TSession.touched('ob_basics'), isEmpty);
    expect(find.text('Alex'), findsOneWidget, reason: 'the example is a placeholder');
    expect(find.text('35–44'), findsOneWidget, reason: 'the example is a placeholder');
  });

  testWidgets('the typed name is recorded, and cleared when the field is emptied', (tester) async {
    await _open(tester);
    await tester.enterText(_field(_name), 'Sam');
    await tester.pump();
    expect(TSession.values[_name], 'Sam');
    expect(TSession.touched('ob_basics'), contains(_name));
    await tester.enterText(_field(_name), '');
    await tester.pump();
    expect(TSession.values[_name], isNull);
    expect(TSession.touched('ob_basics'), isNot(contains(_name)));
  });

  testWidgets('the age range is picked from the decade bands and recorded as its band', (tester) async {
    await _open(tester);
    await tester.ensureVisible(_field(_age));
    await tester.tap(_field(_age));
    await _settle(tester);
    for (final label in ['18–24', '25–34', '35–44', '45–54', '55–64', '65–74', '75+']) {
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.text(label)), findsOneWidget, reason: label);
    }
    await tester.tap(find.byKey(const ValueKey('option:45_54')));
    await _settle(tester);
    expect(TSession.values[_age], '45_54');
    expect(_shown(tester, _age), '45–54');
    expect(TSession.touched('ob_basics'), contains(_age));
    // Another pick replaces it, including the last band.
    await _pickAge(tester, '75_plus');
    expect(TSession.values[_age], '75_plus');
    expect(_shown(tester, _age), '75+');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('closing the list without a pick records nothing', (tester) async {
    await _open(tester);
    await tester.ensureVisible(_field(_age));
    await tester.tap(_field(_age));
    await _settle(tester);
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(TSession.values[_age], isNull);
    expect(_shown(tester, _age), isEmpty);
  });

  testWidgets('the sleep and stress bands are recorded when tapped', (tester) async {
    await _open(tester);
    await tester.ensureVisible(find.text('7–8 h'));
    await tester.tap(find.text('7–8 h'));
    await tester.tap(find.text('Low'));
    await tester.pump();
    expect(TSession.values[_sleep], '7–8 h');
    expect(TSession.values[_stress], 'Low');
    expect(TSession.touched('ob_basics'), containsAll([_sleep, _stress]));
  });

  testWidgets('the age range list is available to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    await tester.ensureVisible(_field(_age));
    tester.semantics.tap(find.semantics.byLabel('Age range'));
    await _settle(tester);
    final option = find.semantics.byLabel('35–44');
    expect(option, findsOneWidget);
    final data = tester.getSemantics(find.byKey(const ValueKey('option:35_44'))).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    tester.semantics.tap(option);
    await _settle(tester);
    expect(TSession.values[_age], '35_44');
    semantics.dispose();
  });

  testWidgets('a scrubbed age range empties the field', (tester) async {
    await _open(tester);
    await _pickAge(tester, '25_34');
    expect(_shown(tester, _age), '25–34');
    TSession.scrub([_age]);
    await tester.pump();
    expect(_shown(tester, _age), isEmpty);
  });

  testWidgets('the age options are the bands the API accepts', (tester) async {
    await _open(tester);
    final field = tester.widget<TField>(find.ancestor(of: _field(_age), matching: find.byType(TField)));
    expect(field.options, ['18_24', '25_34', '35_44', '45_54', '55_64', '65_74', '75_plus']);
    expect(field.optionLabels, hasLength(7));
  });
}
