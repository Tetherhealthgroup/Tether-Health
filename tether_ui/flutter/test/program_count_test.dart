// "Continue" on ob_programs follows the programs chosen: "Choose at least one
// program" and disabled with none, "Continue with 1 program", then "Continue
// with N programs".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/onboarding/ob_focus_screen.dart';
import 'package:tether_ui/ui/ui.dart';

const _key = 'ob_programs.programs';

Future<void> _open(WidgetTester tester, {Locale? locale}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    locale: locale,
    supportedLocales: TStrings.supportedLocales(release: false),
    localizationsDelegates: const [TStrings.delegate, DefaultMaterialLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
    onGenerateRoute: AppRouter.onGenerateRoute,
    onGenerateInitialRoutes: (_) => [AppRouter.onGenerateRoute(const RouteSettings(name: Routes.obPrograms))!],
  ));
  await tester.pump(const Duration(milliseconds: 400));
}

Finder get _continue => find.byKey(const ValueKey('a:footer[0]'));

TButton _button(WidgetTester tester) => tester.widget<TButton>(find.descendant(of: _continue, matching: find.byType(TButton)));

Future<void> _tile(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(TSession.clear);
  tearDown(TSession.clear);

  testWidgets('with nothing chosen the button is disabled and says to choose one', (tester) async {
    await _open(tester);
    expect(TSession.values[_key], isEmpty);
    expect(_button(tester).label, 'Choose at least one program');
    expect(_button(tester).onPressed, isNull);
    expect(find.text('Continue with 2 programs'), findsNothing);
    await tester.tap(_continue, warnIfMissed: false);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(ObFocusScreen), findsNothing);
  });

  testWidgets('the label counts the programs chosen, singular for one', (tester) async {
    await _open(tester);
    await _tile(tester, 'BreatheFree');
    expect(_button(tester).label, 'Continue with 1 program');
    expect(_button(tester).onPressed, isNotNull);
    await _tile(tester, 'ScrollFree');
    expect(_button(tester).label, 'Continue with 2 programs');
    await _tile(tester, 'Heartwise');
    expect(_button(tester).label, 'Continue with 3 programs');
    expect(TSession.values[_key], ['BreatheFree', 'ScrollFree', 'Heartwise']);
    for (final p in ['BreatheFree', 'ScrollFree', 'Heartwise']) {
      await _tile(tester, p);
    }
    expect(_button(tester).label, 'Choose at least one program');
    expect(_button(tester).onPressed, isNull);
  });

  testWidgets('all eight programs', (tester) async {
    await _open(tester);
    for (final p in ['BreatheFree', 'ScrollFree', 'ClearAir', 'Heartwise', 'Steady', 'Ease', 'Nourish', 'Stride']) {
      await _tile(tester, p);
    }
    expect(_button(tester).label, 'Continue with 8 programs');
  });

  testWidgets('continue opens the next screen once a program is chosen', (tester) async {
    await _open(tester);
    await _tile(tester, 'Steady');
    await tester.tap(_continue);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(ObFocusScreen), findsOneWidget);
  });

  testWidgets('the label is translated with its plural (pseudo-locale)', (tester) async {
    await _open(tester, locale: Locale(TStrings.supportedLocales(release: false).last.languageCode, TStrings.supportedLocales(release: false).last.countryCode));
    await _tile(tester, 'BreatheFree');
    final one = _button(tester).label;
    await _tile(tester, 'ScrollFree');
    final two = _button(tester).label;
    expect(one, isNot('Continue with 1 program'));
    expect(one, contains('1'));
    expect(two, contains('2'));
    expect(one, isNot(two));
  });

  testWidgets('the gate: values that count as chosen', (tester) async {
    expect([null, '', '  ', <String>[]].map(TGatedButton.hasValue), everyElement(isFalse));
    expect(['2026-10-30', ['a'], 0, false].map(TGatedButton.hasValue), everyElement(isTrue));
  });

  testWidgets('the screen-reader label is the button label', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    expect(find.semantics.byLabel('Choose at least one program'), findsOneWidget);
    await _tile(tester, 'Ease');
    expect(find.semantics.byLabel('Continue with 1 program'), findsOneWidget);
    semantics.dispose();
  });
}
