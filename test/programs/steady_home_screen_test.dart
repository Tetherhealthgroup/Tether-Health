import 'package:breathefree_patient/programs/program.dart';
import 'package:breathefree_patient/programs/steady/screens/log_reading_screen.dart';
import 'package:breathefree_patient/programs/steady/screens/steady_home_screen.dart';
import 'package:breathefree_patient/programs/steady/steady_controller.dart';
import 'package:breathefree_patient/programs/steady/steady_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder byLabel(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );

void main() {
  testWidgets('renders focus, streak, target prompt, and footers',
      (tester) async {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SteadyHomeScreen(
          controller: controller,
          onLogReading: () {},
          onOpenReset: () {},
        ),
      ),
    );

    expect(find.text('Steady'), findsOneWidget);
    expect(byLabel('Logging streak, 0 days'), findsOneWidget);
    expect(find.text(SteadySafety.readingsAreDataNote), findsOneWidget);
    expect(
      find.textContaining('No target range recorded yet'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      byLabel('Open energy reset'),
      300,
    );
    expect(byLabel('Log a glucose reading'), findsOneWidget);
    expect(byLabel('Open energy reset'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(ProgramCopy.disclaimer), 300);
    expect(find.text(ProgramCopy.privacyFooter), findsOneWidget);
    expect(find.text(ProgramCopy.disclaimer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('records a clinician-provided target range', (tester) async {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SteadyHomeScreen(
          controller: controller,
          onLogReading: () {},
          onOpenReset: () {},
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Record target range'), 200);
    await tester.tap(find.text('Record target range'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('steady-target-min')),
      '80',
    );
    await tester.enterText(
      find.byKey(const ValueKey('steady-target-max')),
      '130',
    );
    await tester.enterText(
      find.byKey(const ValueKey('steady-target-by')),
      'Dr. Rao',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(controller.targetRange?.setBy, 'Dr. Rao');
    await tester.scrollUntilVisible(find.text('80–130 mg/dL'), 200);
    expect(find.text('80–130 mg/dL'), findsOneWidget);
    expect(find.text('Set by Dr. Rao'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('log screen has no calorie fields and saves a missing value',
      (tester) async {
    final controller = SteadyController();
    addTearDown(controller.dispose);
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LogReadingScreen(
          controller: controller,
          onSaved: () => saved = true,
        ),
      ),
    );

    // HARD RULE: no calorie counting anywhere in Steady.
    expect(
      find.textContaining(
        RegExp('calorie', caseSensitive: false),
        findRichText: true,
      ),
      findsNothing,
    );

    expect(byLabel('Save glucose reading'), findsWidgets);
    final saveButton = find.widgetWithText(FilledButton, 'Save reading');
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump();

    expect(saved, isTrue);
    expect(controller.readings, hasLength(1));
    expect(controller.readings.single.valueMgDl, isNull);
    expect(tester.takeException(), isNull);
  });
}
