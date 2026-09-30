// Integration — choices crossing the screen/state boundary and
// surviving navigation away and back.
//
// Extracted from the original flat test/widget_test.dart; each test was
// already self-contained, so behaviour is unchanged.

import 'package:tether_health/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Screen 3 privacy choices change and persist across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 2));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      findsOneWidget,
    );

    final reminders = find.byKey(const ValueKey('consent-helpful-reminders'));
    final careTeam = find.byKey(const ValueKey('consent-share-care-team'));
    final improve = find.byKey(const ValueKey('consent-help-improve'));

    await tester.ensureVisible(reminders);
    expect(tester.widget<Switch>(reminders).value, isTrue);
    await tester.tap(reminders);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(reminders).value, isFalse);

    await tester.ensureVisible(careTeam);
    await tester.tap(careTeam);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(careTeam).value, isTrue);

    await tester.ensureVisible(improve);
    await tester.tap(improve);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(improve).value, isTrue);

    await tester.tap(find.byKey(const ValueKey('consent-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-why-breathefree-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(reminders).value, isFalse);
    await tester.ensureVisible(careTeam);
    expect(tester.widget<Switch>(careTeam).value, isTrue);
    await tester.ensureVisible(improve);
    expect(tester.widget<Switch>(improve).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 4 answer changes and persists across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 3));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-baseline-assessment-screen')),
      findsOneWidget,
    );
    expect(find.text('Selected'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('baseline-next')),
          )
          .onPressed,
      isNull,
      reason: 'Next must remain disabled until the patient answers.',
    );

    final tenOrFewer = find.byKey(const ValueKey('baseline-choice-tenOrFewer'));
    await tester.ensureVisible(tenOrFewer);
    await tester.tap(tenOrFewer);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('baseline-selected-tenOrFewer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('baseline-selected-elevenToTwenty')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('baseline-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('consent-agree-continue')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('baseline-selected-tenOrFewer')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 5 trigger choices change and persist across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 4));
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const ValueKey('trigger-continue'));
    expect(
      tester.widget<FilledButton>(continueButton).onPressed,
      isNull,
      reason: 'Continue must remain disabled until a trigger is selected.',
    );

    final stress = find.byKey(const ValueKey('trigger-choice-stress'));
    final driving = find.byKey(const ValueKey('trigger-choice-driving'));
    await tester.tap(stress);
    await tester.pumpAndSettle();
    await tester.tap(driving);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('trigger-selected-stress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trigger-selected-driving')),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('trigger-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-baseline-assessment-screen')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('baseline-choice-tenOrFewer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('trigger-selected-stress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trigger-selected-driving')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 7 quit path changes and persists across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 6));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-choose-quit-path-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quit-path-selected-setQuitDate')),
      findsOneWidget,
      reason: 'Set a quit date should be the recommended default.',
    );

    final quitToday = find.byKey(const ValueKey('quit-path-choice-quitToday'));
    await tester.ensureVisible(quitToday);
    await tester.tap(quitToday);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('quit-path-selected-quitToday')),
      findsOneWidget,
    );
    expect(
      find.text('Quit today selected · Saved automatically'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('quit-path-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-readiness-result-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('readiness-continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('quit-path-selected-quitToday')),
      findsOneWidget,
      reason: 'The chosen quit path should remain saved after going back.',
    );

    final gradual =
        find.byKey(const ValueKey('quit-path-choice-reduceGradually'));
    await tester.ensureVisible(gradual);
    await tester.tap(gradual);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('quit-path-selected-reduceGradually')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 8 date and check-in choices persist across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 7));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-select-quit-date-screen')),
      findsOneWidget,
    );
    expect(find.text('Choose a day to begin.'), findsOneWidget);
    expect(find.byKey(const ValueKey('quit-date-selected')), findsOneWidget);

    final defaultDate = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 7)),
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      defaultDate.year,
      defaultDate.month,
    );
    final alternateDate = defaultDate.day < daysInMonth
        ? defaultDate.add(const Duration(days: 1))
        : defaultDate.subtract(const Duration(days: 1));
    final month = alternateDate.month.toString().padLeft(2, '0');
    final day = alternateDate.day.toString().padLeft(2, '0');
    final alternateKey = ValueKey(
      'quit-date-day-${alternateDate.year}-$month-$day',
    );

    await tester.tap(find.byKey(alternateKey));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(alternateKey),
        matching: find.byKey(const ValueKey('quit-date-selected')),
      ),
      findsOneWidget,
    );

    final checkIn = find.byKey(const ValueKey('quit-date-check-in'));
    await tester.ensureVisible(checkIn);
    await tester.tap(checkIn);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('quit-date-check-in')))
          .value,
      isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('quit-date-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-choose-quit-path-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(alternateKey),
        matching: find.byKey(const ValueKey('quit-date-selected')),
      ),
      findsOneWidget,
      reason: 'The selected date should remain saved after going back.',
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('quit-date-check-in')))
          .value,
      isFalse,
      reason: 'The private check-in choice should remain saved.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 9 reasons and top reason change and persist',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 8));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      findsOneWidget,
    );
    expect(find.text('3 SELECTED'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reason-selected-family')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('reason-choice-saveMoney')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reason-top-saveMoney')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reason-selected-saveMoney')),
      findsOneWidget,
    );
    expect(
      find.textContaining('You chose this to save money.'),
      findsOneWidget,
    );
    expect(find.text('4 SELECTED'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reasons-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-select-quit-date-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('quit-date-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reason-selected-saveMoney')),
      findsOneWidget,
      reason: 'Selected reasons should remain saved after going back.',
    );
    expect(
      find.textContaining('You chose this to save money.'),
      findsOneWidget,
      reason: 'The top reason should remain saved after going back.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 10 support and preparation choices persist',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 9));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-support-preparation-screen')),
      findsOneWidget,
    );
    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('1 PERSON ADDED'), findsOneWidget);
    expect(find.text('2 OF 3'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('support-person-toggle-jordan')),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 PEOPLE ADDED'), findsOneWidget);

    final finalTask =
        find.byKey(const ValueKey('preparation-task-stockAlternatives'));
    await tester.ensureVisible(finalTask);
    await tester.tap(finalTask);
    await tester.pumpAndSettle();
    expect(find.text('3 OF 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('support-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reasons-save')));
    await tester.pumpAndSettle();

    expect(find.text('0 PEOPLE ADDED'), findsOneWidget);
    expect(find.text('3 OF 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 13 edits save and persist after returning from Screen 14',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 12));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
    );
    expect(find.text('6'), findsOneWidget);
    expect(find.text('6 · Moderate'), findsOneWidget);
    expect(find.text('7 / 10'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('checkin-mood-good')));
    await tester.pumpAndSettle();
    final cigarettePlus = find.byKey(const ValueKey('checkin-cigarette-plus'));
    await tester.ensureVisible(cigarettePlus);
    await tester.pumpAndSettle();
    await tester.tap(cigarettePlus);
    await tester.pumpAndSettle();
    expect(find.text('7'), findsWidgets);

    final symptoms =
        find.byKey(const ValueKey('checkin-symptom-troubleSleeping'));
    await tester.ensureVisible(symptoms);
    await tester.tap(symptoms);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkin-symptom-other')));
    await tester.pumpAndSettle();
    final otherField =
        find.byKey(const ValueKey('checkin-other-symptom-field'));
    await tester.ensureVisible(otherField);
    await tester.enterText(
      otherField,
      'Headache',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('checkin-save')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      findsOneWidget,
    );
    expect(find.text('Stress reset'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-step-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
    );
    expect(find.text('7'), findsWidgets);
    expect(find.text('Headache'), findsOneWidget);
    expect(
      tester.widget<FilterChip>(symptoms).selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 6 path choice and explanation work and persist',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 5));
    await tester.pumpAndSettle();

    final why = find.byKey(const ValueKey('readiness-why-fit'));
    await tester.ensureVisible(why);
    await tester.tap(why);
    await tester.pumpAndSettle();
    expect(find.text('Why preparation may fit'), findsOneWidget);
    expect(
      find.textContaining('not a medical assessment'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('readiness-why-done')));
    await tester.pumpAndSettle();

    final explore = find.byKey(const ValueKey('readiness-path-explore'));
    await tester.ensureVisible(explore);
    await tester.tap(explore);
    await tester.pumpAndSettle();
    expect(find.text('Explore without setting a date'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('readiness-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-trigger-map-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('trigger-choice-stress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Explore without setting a date'), findsOneWidget);

    final connect = find.byKey(const ValueKey('readiness-path-connect'));
    await tester.ensureVisible(connect);
    await tester.tap(connect);
    await tester.pumpAndSettle();
    expect(find.text('Find support options'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
