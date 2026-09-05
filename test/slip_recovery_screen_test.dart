import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:breathefree_patient/screens/slip_recovery_screen.dart';

void main() {
  Widget buildScreen({
    bool isSpanish = false,
    VoidCallback? onClose,
    VoidCallback? onSave,
    VoidCallback? onNext,
    VoidCallback? onSupport,
  }) {
    return MaterialApp(
      home: SlipRecoveryScreen(
        isSpanish: isSpanish,
        onClose: onClose ?? () {},
        onSave: onSave ?? () {},
        onOpenNextStep: onNext ?? () {},
        onOpenSupport: onSupport ?? () {},
      ),
    );
  }

  Future<void> scrollTo(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders English Screen 23', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('Slip recovery'), findsOneWidget);
    expect(find.text('A slip is information—not the end.'), findsOneWidget);
    expect(find.text('What happened?'), findsOneWidget);
    expect(find.text('What was happening?'), findsOneWidget);
    expect(find.text('What feels right now?'), findsOneWidget);
    expect(find.text('Save and start recovery'), findsOneWidget);
    expect(find.text('Open after saving'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders Spanish Screen 23', (tester) async {
    await tester.pumpWidget(buildScreen(isSpanish: true));

    expect(find.text('¿Qué pasó?'), findsOneWidget);
    expect(find.text('¿Qué estaba pasando?'), findsOneWidget);
    expect(find.text('¿Qué te parece bien ahora?'), findsOneWidget);
    expect(find.text('Guardar y comenzar la recuperación'), findsOneWidget);
    expect(find.text('PRIVADO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single choice selections change', (tester) async {
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.text('A puff or two'));
    await tester.tap(find.text('Earlier today'));
    await tester.pump();

    expect(find.text('A puff or two'), findsOneWidget);
    expect(find.text('Earlier today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trigger choices allow multiple selections', (tester) async {
    await tester.pumpWidget(buildScreen());

    final aroundSmokers = find.text('Around smokers');
    final routine = find.text('Routine');

    await scrollTo(tester, aroundSmokers);
    await tester.tap(aroundSmokers);

    await scrollTo(tester, routine);
    await tester.tap(routine);

    await tester.pump();

    expect(aroundSmokers, findsOneWidget);
    expect(routine, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recovery choice changes', (tester) async {
    await tester.pumpWidget(buildScreen());

    final helpMeDecide = find.text('Help me decide');

    await scrollTo(tester, helpMeDecide);
    await tester.tap(helpMeDecide);
    await tester.pump();

    expect(helpMeDecide, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('save invokes callback once and marks saved', (tester) async {
    var saveCount = 0;

    await tester.pumpWidget(
      buildScreen(onSave: () => saveCount++),
    );

    final saveButton = find.byKey(
      const ValueKey('slip-recovery-save'),
    );

    await scrollTo(tester, saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(saveCount, 1);
    expect(find.text('Saved'), findsOneWidget);

    // The button is disabled after saving, so a second tap must not
    // invoke the callback again.
    expect(
      tester.widget<FilledButton>(saveButton).onPressed,
      isNull,
    );
  });

  testWidgets('navigation callbacks work', (tester) async {
    var closeCount = 0;
    var saveCount = 0;
    var nextCount = 0;
    var supportCount = 0;

    await tester.pumpWidget(
      buildScreen(
        onClose: () => closeCount++,
        onSave: () => saveCount++,
        onNext: () => nextCount++,
        onSupport: () => supportCount++,
      ),
    );

    final closeButton = find.byKey(
      const ValueKey('slip-recovery-close'),
    );
    final saveButton = find.byKey(
      const ValueKey('slip-recovery-save'),
    );
    final nextButton = find.byKey(
      const ValueKey('slip-recovery-open-next-step'),
    );
    final supportButton = find.byKey(
      const ValueKey('slip-recovery-support'),
    );

    // Close is at the top.
    await tester.tap(closeButton);

    // "Open after saving" must be disabled before the slip is saved.
    await scrollTo(tester, nextButton);
    expect(
      tester.widget<TextButton>(nextButton).onPressed,
      isNull,
    );
    await tester.tap(nextButton);
    await tester.pump();
    expect(nextCount, 0);

    // Save the slip. The next-step action should then become available.
    await scrollTo(tester, saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(saveCount, 1);
    expect(
      tester.widget<TextButton>(nextButton).onPressed,
      isNotNull,
    );

    await tester.tap(nextButton);

    await scrollTo(tester, supportButton);
    await tester.tap(supportButton);

    await tester.pump();

    expect(closeCount, 1);
    expect(nextCount, 1);
    expect(supportCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skip invokes close callback', (tester) async {
    var closeCount = 0;

    await tester.pumpWidget(
      buildScreen(onClose: () => closeCount++),
    );

    final skipButton = find.byKey(
      const ValueKey('slip-recovery-skip'),
    );

    await scrollTo(tester, skipButton);
    await tester.tap(skipButton);
    await tester.pump();

    expect(closeCount, 1);
    expect(tester.takeException(), isNull);
  });
}
