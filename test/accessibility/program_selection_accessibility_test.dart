import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/programs/program.dart';
import 'package:breathefree_patient/programs/program_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('program selection supports 200 percent text and keyboard focus',
      (tester) async {
    ProgramId? selected;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          home: ProgramSelectionScreen(
            account: AccountController.disabled(),
            onSelect: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Heartwise'), findsOneWidget);
    expect(find.text('Steady'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ClearAir'), 240);
    expect(find.text('ClearAir'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNotNull);

    await tester.ensureVisible(find.text('ClearAir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ClearAir'));
    expect(selected, ProgramId.clearAir);
  });
}
