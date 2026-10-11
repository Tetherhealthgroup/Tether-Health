import 'package:breathefree_patient/programs/heartwise/heartwise_controller.dart';
import 'package:breathefree_patient/programs/heartwise/models/bp_reading.dart';
import 'package:breathefree_patient/programs/heartwise/models/cholesterol_panel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adding a reading keeps the values and notifies listeners', () {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);

    var notified = false;
    controller.addListener(() => notified = true);

    final id = controller.addBpReading(systolic: 128, diastolic: 84);
    expect(id, isNotNull);
    expect(controller.bpReadings, hasLength(1));
    expect(controller.bpReadings.single.systolic, 128);
    expect(controller.bpReadings.single.diastolic, 84);
    expect(notified, isTrue);
    expect(controller.errorMessage, isNull);
  });

  test('a missing diastolic stays null and is never zero', () {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);

    final id = controller.addBpReading(systolic: 120);
    expect(id, isNotNull);

    final reading = controller.bpReadings.single;
    expect(reading.systolic, 120);
    expect(reading.diastolic, isNull);
    expect(reading.diastolic, isNot(0));
  });

  test('a reading with no values is rejected', () {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);

    expect(controller.addBpReading(), isNull);
    expect(controller.bpReadings, isEmpty);
    expect(controller.errorMessage, isNotNull);
  });

  test('validation rejects empty, non-numeric, and out-of-range input', () {
    expect(
      BpReading.validate(systolicText: '', diastolicText: ''),
      isNotNull,
    );
    expect(
      BpReading.validate(systolicText: 'abc', diastolicText: ''),
      isNotNull,
    );
    expect(
      BpReading.validate(systolicText: '20', diastolicText: ''),
      isNotNull,
    );
    expect(
      BpReading.validate(systolicText: '', diastolicText: '500'),
      isNotNull,
    );
  });

  test('validation accepts one-sided and two-sided readings', () {
    expect(
      BpReading.validate(systolicText: '128', diastolicText: '84'),
      isNull,
    );
    expect(
      BpReading.validate(systolicText: '', diastolicText: '80'),
      isNull,
    );
    expect(
      BpReading.validate(systolicText: '120', diastolicText: ''),
      isNull,
    );
  });

  test('removing a reading deletes it by id', () {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);

    final id = controller.addBpReading(systolic: 128, diastolic: 84)!;
    expect(controller.removeBpReading(id), isTrue);
    expect(controller.bpReadings, isEmpty);
    expect(controller.removeBpReading(id), isFalse);
  });

  test('cholesterol panel keeps the lab-or-clinician source note', () {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);

    final id = controller.addCholesterolPanel(ldlMgDl: 110, hdlMgDl: 55);
    expect(id, isNotNull);

    final panel = controller.cholesterolPanels.single;
    expect(panel.ldlMgDl, 110);
    expect(panel.hdlMgDl, 55);
    expect(panel.triglyceridesMgDl, isNull);
    expect(panel.triglyceridesMgDl, isNot(0));
    expect(panel.source, CholesterolPanel.defaultSource);
  });

  test('a panel with no values is rejected', () {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);

    expect(controller.addCholesterolPanel(), isNull);
    expect(controller.cholesterolPanels, isEmpty);
    expect(controller.errorMessage, isNotNull);
  });

  test('panel validation rejects empty and non-numeric input', () {
    expect(
      CholesterolPanel.validate(
        ldlText: '',
        hdlText: '',
        triglyceridesText: '',
        totalText: '',
      ),
      isNotNull,
    );
    expect(
      CholesterolPanel.validate(
        ldlText: 'high',
        hdlText: '',
        triglyceridesText: '',
        totalText: '',
      ),
      isNotNull,
    );
    expect(
      CholesterolPanel.validate(
        ldlText: '110',
        hdlText: '',
        triglyceridesText: '',
        totalText: '',
      ),
      isNull,
    );
  });

  test('removing a panel deletes it by id', () {
    final controller = HeartwiseController();
    addTearDown(controller.dispose);

    final id = controller.addCholesterolPanel(totalMgDl: 190)!;
    expect(controller.removeCholesterolPanel(id), isTrue);
    expect(controller.cholesterolPanels, isEmpty);
  });
}
