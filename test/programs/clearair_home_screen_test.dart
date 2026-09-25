import 'package:breathefree_patient/programs/clearair/clearair_controller.dart';
import 'package:breathefree_patient/programs/clearair/clearair_safety.dart';
import 'package:breathefree_patient/programs/clearair/models/action_plan.dart';
import 'package:breathefree_patient/programs/clearair/screens/clearair_home_screen.dart';
import 'package:breathefree_patient/programs/clearair/screens/red_zone_screen.dart';
import 'package:breathefree_patient/programs/program.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder byLabel(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );

void main() {
  testWidgets('zone banner is always visible; red route is findable',
      (tester) async {
    final controller = ClearAirController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ClearAirHomeScreen(
          controller: controller,
          onZoneCheck: () {},
          onOpenRedZone: () {},
        ),
      ),
    );

    expect(find.text('ClearAir'), findsOneWidget);
    // Zone banner always visible, even with no plan recorded.
    expect(
      find.textContaining('No action plan recorded yet'),
      findsOneWidget,
    );
    expect(byLabel('Daily zone check'), findsOneWidget);
    // The red route is always visible from home.
    expect(
      byLabel(ClearAirSafety.redZoneButtonLabel),
      findsOneWidget,
    );
    expect(find.text(ProgramCopy.privacyFooter), findsOneWidget);
    expect(find.text(ProgramCopy.disclaimer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zone banner reflects the recorded plan zone', (tester) async {
    final controller = ClearAirController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ClearAirHomeScreen(
          controller: controller,
          onZoneCheck: () {},
          onOpenRedZone: () {},
        ),
      ),
    );

    controller.recordClinicianPlan(
      zone: ActionPlanZone.yellow,
      recordedBy: 'Dr. Rao',
    );
    await tester.pump();

    expect(find.text('Your action plan zone: Yellow'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('red zone screen shows urgent guidance and contact action',
      (tester) async {
    final launched = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        home: RedZoneScreen(
          launchUrgentCare: (uri) async => launched.add(uri),
        ),
      ),
    );

    expect(find.text(ClearAirSafety.redZoneHeading), findsOneWidget);
    expect(find.text(ClearAirSafety.redZoneBody), findsOneWidget);
    expect(
      byLabel(ClearAirSafety.urgentCareActionLabel),
      findsOneWidget,
    );

    await tester.tap(byLabel(ClearAirSafety.urgentCareActionLabel));
    await tester.pump();

    expect(launched, hasLength(1));
    expect(launched.single.scheme, 'tel');
    expect(tester.takeException(), isNull);
  });
}
