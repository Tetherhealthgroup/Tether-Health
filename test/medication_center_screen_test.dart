import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tether_health/screens/medication_center_screen.dart';

void main() {
  Widget buildScreen({
    bool isSpanish = false,
    bool reminderPreviews = true,
    MedicationTodayStatus todayStatus = MedicationTodayStatus.taken,
    ValueChanged<bool>? onReminderPreviewsChanged,
    ValueChanged<MedicationTodayStatus>? onTodayStatusChanged,
    VoidCallback? onBack,
    VoidCallback? onOpenLearn,
    VoidCallback? onOpenSupport,
    VoidCallback? onOpenHome,
    VoidCallback? onOpenProgress,
  }) {
    return MaterialApp(
      home: MedicationCenterScreen(
        isSpanish: isSpanish,
        reminderPreviews: reminderPreviews,
        todayStatus: todayStatus,
        onReminderPreviewsChanged: onReminderPreviewsChanged ?? (_) {},
        onTodayStatusChanged: onTodayStatusChanged ?? (_) {},
        onBack: onBack ?? () {},
        onOpenLearn: onOpenLearn ?? () {},
        onOpenSupport: onOpenSupport ?? () {},
        onOpenHome: onOpenHome ?? () {},
        onOpenProgress: onOpenProgress ?? () {},
      ),
    );
  }

  Future<void> scrollTo(
    WidgetTester tester,
    Finder finder,
  ) async {
    final pageScrollView = find.byKey(
      const ValueKey('medication-center-scroll'),
    );
    final pageScrollable = find.descendant(
      of: pageScrollView,
      matching: find.byType(Scrollable),
    );

    expect(pageScrollView, findsOneWidget);
    expect(pageScrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: pageScrollable,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(
    WidgetTester tester,
    Finder finder,
  ) async {
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  String formatTime(DateTime value) {
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  testWidgets('renders Screen 24 without Flutter exceptions', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(
      find.byKey(const ValueKey('functional-medication-center-screen')),
      findsOneWidget,
    );
    expect(find.text('Medication center'), findsOneWidget);
    expect(find.text('Nicotine patch'), findsOneWidget);
    expect(find.text('Recorded as taken'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reminder preview toggle reports the changed value',
      (tester) async {
    bool? changedValue;

    await tester.pumpWidget(
      buildScreen(
        onReminderPreviewsChanged: (value) => changedValue = value,
      ),
    );

    final toggle = find.byKey(
      const ValueKey('medication-reminder-switch'),
    );
    await scrollTo(tester, toggle);
    await tester.tap(toggle);
    await tester.pump();

    expect(changedValue, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('today status sheet records the selected status', (tester) async {
    MedicationTodayStatus? selectedStatus;

    await tester.pumpWidget(
      buildScreen(
        todayStatus: MedicationTodayStatus.taken,
        onTodayStatusChanged: (value) => selectedStatus = value,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('medication-update-status')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('medication-status-missed')),
    );
    await tester.pumpAndSettle();

    expect(selectedStatus, MedicationTodayStatus.missed);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Taken records the actual current time in the status card',
      (tester) async {
    var status = MedicationTodayStatus.notYet;
    late StateSetter setHarnessState;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setHarnessState = setState;
            return MedicationCenterScreen(
              isSpanish: false,
              reminderPreviews: true,
              todayStatus: status,
              onReminderPreviewsChanged: (_) {},
              onTodayStatusChanged: (value) {
                setHarnessState(() => status = value);
              },
              onBack: () {},
              onOpenLearn: () {},
              onOpenSupport: () {},
              onOpenHome: () {},
              onOpenProgress: () {},
            );
          },
        ),
      ),
    );

    final before = DateTime.now();

    await tester.tap(
      find.byKey(const ValueKey('medication-update-status')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('medication-status-taken')),
    );
    await tester.pumpAndSettle();

    final after = DateTime.now();
    final statusText = tester.widget<Text>(
      find.byKey(const ValueKey('medication-status-title')),
    );

    final acceptable = <String>{
      'Recorded taken at ${formatTime(before)}',
      'Recorded taken at ${formatTime(after)}',
    };

    expect(status, MedicationTodayStatus.taken);
    expect(acceptable, contains(statusText.data));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'medicine education cards open distinct topic sheets and full library callback',
      (tester) async {
    var learnCount = 0;

    await tester.pumpWidget(
      buildScreen(onOpenLearn: () => learnCount++),
    );

    final nrtCard = find.byKey(
      const ValueKey('medication-nrt-card'),
    );
    await scrollTo(tester, nrtCard);
    await tester.tap(nrtCard);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('medication-nrt-topic-sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('medication-prescription-topic-sheet')),
      findsNothing,
    );
    expect(learnCount, 0);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('medication-education-topic-close')),
    );

    final prescriptionCard = find.byKey(
      const ValueKey('medication-prescription-card'),
    );
    await scrollTo(tester, prescriptionCard);
    await tester.tap(prescriptionCard);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('medication-prescription-topic-sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('medication-nrt-topic-sheet')),
      findsNothing,
    );
    expect(learnCount, 0);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('medication-education-topic-close')),
    );

    await scrollTo(tester, nrtCard);
    await tester.tap(nrtCard);
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('medication-education-open-library')),
    );

    expect(learnCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('education support and bottom navigation callbacks work',
      (tester) async {
    var supportCount = 0;
    var homeCount = 0;
    var progressCount = 0;
    var learnCount = 0;

    await tester.pumpWidget(
      buildScreen(
        onOpenSupport: () => supportCount++,
        onOpenHome: () => homeCount++,
        onOpenProgress: () => progressCount++,
        onOpenLearn: () => learnCount++,
      ),
    );

    final pregnancy = find.byKey(
      const ValueKey('medication-pregnancy-support'),
    );
    await scrollTo(tester, pregnancy);
    await tester.tap(pregnancy);
    await tester.pump();
    expect(supportCount, 1);

    await tester.tap(
      find.byKey(const ValueKey('medication-nav-home')),
    );
    await tester.tap(
      find.byKey(const ValueKey('medication-nav-progress')),
    );
    await tester.tap(
      find.byKey(const ValueKey('medication-nav-learn')),
    );
    await tester.tap(
      find.byKey(const ValueKey('medication-nav-support')),
    );
    await tester.pump();

    expect(homeCount, 1);
    expect(progressCount, 1);
    expect(learnCount, 1);
    expect(supportCount, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add or update recorded plan is editable and saves changes',
      (tester) async {
    await tester.pumpWidget(buildScreen());

    final addPlan = find.byKey(
      const ValueKey('medication-add-update-plan'),
    );
    await scrollTo(tester, addPlan);
    await tester.tap(addPlan);
    await tester.pumpAndSettle();

    expect(find.text('Recorded medication plan'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey('medication-plan-medicine-nicotineGum'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey('medication-plan-timing-evening'),
      ),
    );
    await tester.pump();

    await tapVisible(
      tester,
      find.byKey(const ValueKey('medication-plan-sheet-done')),
    );

    expect(find.text('Nicotine gum'), findsOneWidget);
    expect(find.textContaining('Evening'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top back and top add controls work', (tester) async {
    var backCount = 0;

    await tester.pumpWidget(
      buildScreen(onBack: () => backCount++),
    );

    await tester.tap(
      find.byKey(const ValueKey('medication-back')),
    );
    expect(backCount, 1);

    await tester.tap(
      find.byKey(const ValueKey('medication-add-plan-top')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recorded medication plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
