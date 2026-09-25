import 'package:breathefree_patient/programs/heartwise/heartwise_controller.dart';
import 'package:breathefree_patient/programs/heartwise/heartwise_safety.dart';
import 'package:breathefree_patient/programs/heartwise/screens/heartwise_home_screen.dart';
import 'package:breathefree_patient/programs/program.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder byLabel(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );

Widget buildScreen({
  required HeartwiseController controller,
  required List<Uri> launched,
}) {
  return MaterialApp(
    home: HeartwiseHomeScreen(
      controller: controller,
      onLogBp: () {},
      onOpenCholesterol: () {},
      launchEmergency: (uri) async => launched.add(uri),
    ),
  );
}

void main() {
  testWidgets('renders emergency card, navigation, and footers',
      (tester) async {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildScreen(controller: controller, launched: <Uri>[]),
    );

    expect(find.text('Heartwise'), findsOneWidget);
    // Permanent emergency card.
    expect(find.text(HeartwiseSafety.emergencyBody), findsOneWidget);
    expect(
      byLabel(HeartwiseSafety.emergencyActionLabel),
      findsOneWidget,
    );
    // Navigation with Semantics labels.
    expect(byLabel('Log blood pressure'), findsOneWidget);
    expect(byLabel('Open cholesterol panel'), findsOneWidget);
    // Safety sections and footer are lazy ListView content.
    await tester.scrollUntilVisible(
      find.text(HeartwiseSafety.whenToCallDoctorTitle),
      300,
    );
    expect(
      find.text(HeartwiseSafety.whenToCallDoctorTitle),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
        find.text(HeartwiseSafety.targetsNote), 300);
    expect(find.text(HeartwiseSafety.targetsNote), findsOneWidget);
    await tester.scrollUntilVisible(find.text(ProgramCopy.disclaimer), 300);
    expect(find.text(ProgramCopy.privacyFooter), findsOneWidget);
    expect(find.text(ProgramCopy.disclaimer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('emergency button opens the tel: link', (tester) async {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);
    final launched = <Uri>[];

    await tester.pumpWidget(
      buildScreen(controller: controller, launched: launched),
    );

    await tester.tap(byLabel(HeartwiseSafety.emergencyActionLabel));
    await tester.pump();

    expect(launched, hasLength(1));
    expect(launched.single, HeartwiseSafety.emergencyUri);
    expect(launched.single.scheme, 'tel');
    expect(tester.takeException(), isNull);
  });

  testWidgets('error state appears with retry', (tester) async {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildScreen(controller: controller, launched: <Uri>[]),
    );
    expect(find.text('Heartwise'), findsOneWidget);

    // Rejected through the public API: no values at all.
    controller.addBpReading();
    await tester.pump();

    expect(find.textContaining('Add at least one value'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(controller.errorMessage, isNull);
    expect(find.text('Heartwise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
