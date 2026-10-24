import 'package:breathefree_patient/programs/steady/models/glucose_reading.dart';
import 'package:breathefree_patient/programs/steady/steady_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adding a reading keeps the value, context, and note', () {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    final id = controller.addReading(
      valueMgDl: 142,
      context: GlucoseContext.afterMeal,
      note: 'after lunch',
    );
    expect(id, isNotNull);

    final reading = controller.readings.single;
    expect(reading.valueMgDl, 142);
    expect(reading.context, GlucoseContext.afterMeal);
    expect(reading.note, 'after lunch');
    expect(controller.errorMessage, isNull);
  });

  test('a missing value stays null and is never zero', () {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    final id = controller.addReading(context: GlucoseContext.fasting);
    expect(id, isNotNull);

    final reading = controller.readings.single;
    expect(reading.valueMgDl, isNull);
    expect(reading.valueMgDl, isNot(0));
  });

  test('value validation allows empty but rejects bad input', () {
    expect(GlucoseReading.validateValue(''), isNull);
    expect(GlucoseReading.validateValue('142'), isNull);
    expect(GlucoseReading.validateValue('high'), isNotNull);
    expect(GlucoseReading.validateValue('5'), isNotNull);
  });

  test('target range requires a clinician source', () {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    expect(
      controller.setTargetRange(minMgDl: 80, maxMgDl: 130, setBy: ''),
      isFalse,
    );
    expect(controller.targetRange, isNull);
    expect(controller.errorMessage, isNotNull);
  });

  test('target range rejects an invalid range', () {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    expect(
      controller.setTargetRange(
        minMgDl: 130,
        maxMgDl: 80,
        setBy: 'Dr. Rao',
      ),
      isFalse,
    );
    expect(controller.targetRange, isNull);
  });

  test('target range records the clinician source', () {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    expect(
      controller.setTargetRange(
        minMgDl: 80,
        maxMgDl: 130,
        setBy: 'Dr. Rao',
      ),
      isTrue,
    );

    final target = controller.targetRange!;
    expect(target.minMgDl, 80);
    expect(target.maxMgDl, 130);
    expect(target.setBy, 'Dr. Rao');
    expect(controller.errorMessage, isNull);
  });

  test('logging streak counts consecutive days', () {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    final now = DateTime.now();
    controller.addReading(
      valueMgDl: 110,
      context: GlucoseContext.fasting,
      measuredAt: now,
    );
    controller.addReading(
      valueMgDl: 140,
      context: GlucoseContext.afterMeal,
      measuredAt: now.subtract(const Duration(days: 1)),
    );
    expect(controller.loggingStreakDays, 2);

    controller.addReading(
      valueMgDl: 120,
      context: GlucoseContext.bedtime,
      measuredAt: now.subtract(const Duration(days: 3)),
    );
    // The gap on days-2 breaks the streak; the older reading is ignored.
    expect(controller.loggingStreakDays, 2);
  });

  test('readings are counted by context without judgment', () {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    controller.addReading(
      valueMgDl: 300,
      context: GlucoseContext.afterMeal,
    );
    controller.addReading(
      valueMgDl: 95,
      context: GlucoseContext.fasting,
    );

    final counts = controller.readingsByContext;
    expect(counts[GlucoseContext.afterMeal], 1);
    expect(counts[GlucoseContext.fasting], 1);
    expect(counts[GlucoseContext.bedtime], 0);
  });

  test('removing a reading deletes it by id', () {
    final controller = SteadyController();
    addTearDown(controller.dispose);

    final id =
        controller.addReading(valueMgDl: 120, context: GlucoseContext.fasting)!;
    expect(controller.removeReading(id), isTrue);
    expect(controller.readings, isEmpty);
  });
}
