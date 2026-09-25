import 'package:breathefree_patient/programs/clearair/clearair_controller.dart';
import 'package:breathefree_patient/programs/clearair/models/action_plan.dart';
import 'package:breathefree_patient/programs/program.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('current zone is null before any plan is recorded', () {
    final controller = ClearAirController();
    addTearDown(controller.dispose);

    expect(controller.clinicianPlan, isNull);
    expect(controller.currentZone, isNull);
  });

  test('recording a plan requires the clinician source', () {
    final controller = ClearAirController();
    addTearDown(controller.dispose);

    expect(
      controller.recordClinicianPlan(
        zone: ActionPlanZone.green,
        recordedBy: '',
      ),
      isFalse,
    );
    expect(controller.clinicianPlan, isNull);
    expect(controller.errorMessage, isNotNull);
  });

  test('recording a plan sets the baseline zone', () {
    final controller = ClearAirController();
    addTearDown(controller.dispose);

    expect(
      controller.recordClinicianPlan(
        zone: ActionPlanZone.green,
        recordedBy: 'Dr. Rao',
      ),
      isTrue,
    );

    expect(controller.clinicianPlan?.zone, ActionPlanZone.green);
    expect(controller.clinicianPlan?.recordedBy, 'Dr. Rao');
    expect(controller.currentZone, ActionPlanZone.green);
    expect(controller.errorMessage, isNull);
  });

  test("today's check-in overrides the plan baseline zone", () {
    final controller = ClearAirController();
    addTearDown(controller.dispose);

    controller.recordClinicianPlan(
      zone: ActionPlanZone.green,
      recordedBy: 'Dr. Rao',
    );
    controller.completeZoneCheckIn(
      symptoms: const ['Wheezing'],
      zone: ActionPlanZone.yellow,
    );

    expect(controller.currentZone, ActionPlanZone.yellow);
  });

  test('zone check-in stores the log and a completed result', () {
    final controller = ClearAirController();
    addTearDown(controller.dispose);

    final result = controller.completeZoneCheckIn(
      symptoms: const ['Coughing'],
      zone: ActionPlanZone.green,
    );

    expect(result, isA<CheckInCompleted>());
    expect(controller.lastCheckIn, isA<CheckInCompleted>());

    final log = controller.symptomLogs.single;
    expect(log.symptoms, ['Coughing']);
    expect(log.zone, ActionPlanZone.green);
    expect(log.peakFlow, isNull);
    expect(log.peakFlow, isNot(0));
  });

  test('zone check-in keeps an optional peak flow', () {
    final controller = ClearAirController();
    addTearDown(controller.dispose);

    controller.completeZoneCheckIn(
      symptoms: const [],
      zone: ActionPlanZone.green,
      peakFlow: 420,
    );

    expect(controller.symptomLogs.single.peakFlow, 420);
  });

  test('an empty symptom list is a valid no-symptom check-in', () {
    final controller = ClearAirController();
    addTearDown(controller.dispose);

    final result = controller.completeZoneCheckIn(
      symptoms: const [],
      zone: ActionPlanZone.green,
    );

    expect(result, isA<CheckInCompleted>());
    expect(controller.symptomLogs.single.symptoms, isEmpty);
  });
}
