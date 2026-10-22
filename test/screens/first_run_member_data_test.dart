import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/quit_plan/guest_quit_plan_store.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_controller.dart';
import 'package:breathefree_patient/screens/progress_dashboard_screen.dart';
import 'package:breathefree_patient/screens/support_hub_screen.dart';
import 'package:breathefree_patient/screens/support_preparation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A brand-new member sees nothing presented as theirs that they did not
// enter, optional consents and reminders start off, and a saved plan still
// restores the member's own answers.
void main() {
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  bool switchValue(WidgetTester tester, String key) {
    final byKey = find.byKey(ValueKey(key));
    final widget = tester.widget(byKey);
    if (widget is Switch) return widget.value;
    return tester
        .widget<Switch>(
            find.descendant(of: byKey, matching: find.byType(Switch)))
        .value;
  }

  group('a new plan starts empty', () {
    testWidgets('My reasons has nothing chosen and waits for a reason',
        (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 8));
      await tester.pumpAndSettle();

      expect(find.text('0 SELECTED'), findsOneWidget);
      for (final reason in const [
        'family',
        'breatheEasier',
        'improveHealth',
        'saveMoney',
        'control',
        'future',
      ]) {
        expect(find.byKey(ValueKey('reason-selected-$reason')), findsNothing);
      }
      expect(
        find.text('Choose a reason to create your personal reminder.'),
        findsOneWidget,
      );
      // The screen's existing rule: Save needs at least one reason.
      final save = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('reasons-save')),
      );
      expect(save.onPressed, isNull);

      await tapKey(tester, 'reason-choice-saveMoney');
      expect(find.text('1 SELECTED'), findsOneWidget);
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(const ValueKey('reasons-save')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('Support and preparation has no supporter, task or option on',
        (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 9));
      await tester.pumpAndSettle();

      expect(find.text('Jordan'), findsNothing);
      expect(find.text('0 PEOPLE ADDED'), findsOneWidget);
      expect(find.byKey(const ValueKey('support-empty-state')), findsOneWidget);
      expect(find.text('0 OF 3'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('preparation-task-selected-removeSupplies')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('preparation-task-selected-smokeFreeSpaces')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('support-treatment-toggle')),
      );
      expect(switchValue(tester, 'support-treatment-toggle'), isFalse);
      expect(
        find.byKey(const ValueKey('support-care-team-reminder')),
        findsNothing,
      );

      // Skipping every optional item still moves on to the review.
      await tapKey(tester, 'support-save');
      expect(
        find.byKey(const ValueKey('functional-review-quit-plan-screen')),
        findsOneWidget,
      );
      expect(find.text('Jordan · Evening before'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home shows no supporter, ticked task or unread dot',
        (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 11));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-home-preparation-screen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('preparation-notification-dot')),
        findsNothing,
      );
      expect(find.textContaining('Jordan'), findsNothing);
      expect(find.text('0/3'), findsOneWidget);
      expect(find.text('“Protect my family.”'), findsNothing);
      expect(find.text('“My reason to quit.”'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('preparation-no-reminders')),
      );
      expect(
        find.byKey(const ValueKey('preparation-no-reminders')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Quit-day Home shows no unread dot or supporter',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 21));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('quit-day-notification-dot')),
        findsNothing,
      );
      expect(find.textContaining('Jordan'), findsNothing);
      expect(find.text('“Protect my family.”'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Progress shows an empty state instead of sample figures',
        (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 25));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-progress-dashboard-screen')),
        findsOneWidget,
      );
      for (final sample in const [
        '7 days active',
        '1 day 12 hours since your last reported cigarette',
        'One slip is included in this history\nYour earlier progress remains.',
        '61',
        r'$85',
        '5h',
        '4',
        'Baseline: 10/day',
        'Slow breathing',
        'Helpful in 3 of 4 completed rechecks',
        '−2.3',
      ]) {
        expect(find.text(sample), findsNothing, reason: sample);
      }
      expect(find.byKey(const ValueKey('progress-chart')), findsNothing);
      expect(find.byKey(const ValueKey('progress-view-slip')), findsNothing);
      expect(
          find.byKey(const ValueKey('progress-empty-state')), findsOneWidget);
      expect(find.text(emptyProgressTitle), findsOneWidget);
      expect(find.text(emptyProgressBody), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Support lists no supporter until the member adds one',
        (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 26));
      await tester.pumpAndSettle();

      expect(find.textContaining('Jordan'), findsNothing);
      expect(find.text('Evening check-in by text'), findsNothing);
      expect(find.text('No one has been added yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Support shows only the member\'s people, in either language',
        (tester) async {
      usePhone(tester);
      Widget hub(
              {required bool spanish,
              List<SupportPersonPlan> people = const []}) =>
          MaterialApp(
            home: SupportHubScreen(
              isSpanish: spanish,
              supportPeople: people,
              onBack: () {},
              onOpenSettings: () {},
              onOpenHome: () {},
              onOpenPlan: () {},
              onOpenProgress: () {},
              onOpenLearn: () {},
            ),
          );

      await tester.pumpWidget(hub(spanish: true));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no agregaste a nadie.'), findsOneWidget);
      expect(find.textContaining('Jordan'), findsNothing);

      await tester.pumpWidget(hub(spanish: false, people: const [
        SupportPersonPlan(
          id: 'synthetic-1',
          name: 'Synthetic Ana',
          relationship: 'Sister',
          channel: SupportChannel.call,
          checkIn: '',
        ),
        SupportPersonPlan(
          id: 'synthetic-2',
          name: 'Synthetic Off',
          relationship: 'Friend',
          channel: SupportChannel.text,
          checkIn: 'Weekly',
          enabled: false,
        ),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic Ana · Sister'), findsOneWidget);
      expect(find.text('Phone call'), findsOneWidget);
      expect(find.textContaining('Synthetic Off'), findsNothing);
      expect(find.text('No one has been added yet.'), findsNothing);

      await tapKey(tester, 'support-person-message-synthetic-1');
      expect(find.text('Preview message to Synthetic Ana'), findsOneWidget);
    });

    testWidgets('Daily check-in starts neutral with no cigarette count',
        (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 12));
      await tester.pumpAndSettle();

      final skip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('checkin-smoking-skipped')),
      );
      expect(skip.selected, isTrue);
      for (final status in const ['none', 'puff', 'oneOrMore']) {
        expect(
          tester
              .widget<ChoiceChip>(
                  find.byKey(ValueKey('checkin-smoking-$status')))
              .selected,
          isFalse,
          reason: status,
        );
      }
      expect(
        find.byKey(const ValueKey('checkin-cigarette-plus')),
        findsNothing,
      );
      for (final symptom in const [
        'restless',
        'irritable',
        'troubleConcentrating',
        'troubleSleeping',
        'other',
      ]) {
        final chip = find.byKey(ValueKey('checkin-symptom-$symptom'));
        await tester.ensureVisible(chip);
        expect(tester.widget<FilterChip>(chip).selected, isFalse,
            reason: symptom);
      }
      expect(find.text('5 · Moderate'), findsOneWidget);
      expect(find.text('5 / 10'), findsOneWidget);
    });

    testWidgets('Craving Rescue names no reason or supporter for the member',
        (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 16));
      await tester.pumpAndSettle();

      expect(find.text('“Protect my family.”'), findsNothing);
      expect(find.text('“My reason to quit.”'), findsOneWidget);
      expect(find.textContaining('Jordan'), findsNothing);
    });
  });

  group('optional consents and reminders start off', () {
    testWidgets('privacy choices on the consent screen', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 2));
      await tester.pumpAndSettle();

      for (final key in const [
        'consent-helpful-reminders',
        'consent-share-care-team',
        'consent-help-improve',
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        expect(switchValue(tester, key), isFalse, reason: key);
      }

      // Continue works with every optional choice left off.
      await tapKey(tester, 'consent-agree-continue');
      expect(
        find.byKey(const ValueKey('functional-baseline-assessment-screen')),
        findsOneWidget,
      );
    });

    testWidgets('settings reminders and diagnostics', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 27));
      await tester.pumpAndSettle();

      for (final key in const [
        'settings-reminders',
        'settings-sensitive-details',
        'settings-diagnostics',
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        expect(switchValue(tester, key), isFalse, reason: key);
      }
    });

    testWidgets('quit-day check-in reminder', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 7));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('quit-date-check-in')),
      );
      expect(switchValue(tester, 'quit-date-check-in'), isFalse);
    });

    testWidgets('medication reminder previews stay private (generic text)',
        (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 23));
      await tester.pumpAndSettle();

      // Not a consent: it sets how a reminder looks on the lock screen, and
      // on means the generic private text.
      await tester.ensureVisible(
        find.byKey(const ValueKey('medication-reminder-switch')),
      );
      expect(switchValue(tester, 'medication-reminder-switch'), isTrue);
    });
  });

  group('assessment progress counts the questions that exist', () {
    testWidgets('first question is 1 of 2', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 3));
      await tester.pumpAndSettle();

      expect(find.text('QUESTION 1'), findsOneWidget);
      expect(find.text('1 OF 2'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('1 OF 8'), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const ValueKey('baseline-progress')),
            )
            .value,
        .5,
      );
    });

    testWidgets('trigger question is 2 of 2', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 3));
      await tester.pumpAndSettle();
      await tapKey(tester, 'baseline-choice-tenOrFewer');
      await tapKey(tester, 'baseline-next');

      expect(
        find.byKey(const ValueKey('functional-trigger-map-screen')),
        findsOneWidget,
      );
      expect(find.text('QUESTION 2 · CHOOSE ALL THAT APPLY'), findsOneWidget);
      expect(find.text('2 OF 2'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('QUESTION 6 · CHOOSE ALL THAT APPLY'), findsNothing);
      expect(find.text('6 OF 8'), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const ValueKey('trigger-progress')),
            )
            .value,
        1,
      );
    });
  });

  testWidgets('first run with every optional item skipped reaches Home',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();

    await tapKey(tester, 'welcome-get-started');
    await tapKey(tester, 'why-continue');
    await tapKey(tester, 'consent-agree-continue');
    await tapKey(tester, 'baseline-choice-tenOrFewer');
    await tapKey(tester, 'baseline-next');
    await tapKey(tester, 'trigger-choice-stress');
    await tapKey(tester, 'trigger-continue');
    await tapKey(tester, 'readiness-continue');
    await tapKey(tester, 'quit-path-continue');
    await tapKey(tester, 'quit-date-confirm');
    // A reason is the one choice the plan asks for.
    await tapKey(tester, 'reason-choice-breatheEasier');
    await tapKey(tester, 'reasons-save');
    await tapKey(tester, 'support-save');
    await tapKey(tester, 'review-start-plan');

    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
    );
    expect(find.text('“Breathe easier.”'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    expect(find.textContaining('Jordan'), findsNothing);
    expect(
      find.byKey(const ValueKey('preparation-notification-dot')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a saved plan round-trips the member\'s own answers',
      (tester) async {
    usePhone(tester);
    final store = _MemoryGuestStore();

    await tester.pumpWidget(BreatheFreeApp(
      key: const ValueKey('first-launch'),
      quitPlanController: QuitPlanController.disabled(guestStore: store),
    ));
    await tester.pumpAndSettle();

    await tapKey(tester, 'welcome-get-started');
    await tapKey(tester, 'why-continue');
    await tapKey(tester, 'consent-agree-continue');
    await tapKey(tester, 'baseline-choice-tenOrFewer');
    await tapKey(tester, 'baseline-next');
    await tapKey(tester, 'trigger-choice-stress');
    await tapKey(tester, 'trigger-continue');
    await tapKey(tester, 'readiness-continue');
    await tapKey(tester, 'quit-path-continue');
    await tapKey(tester, 'quit-date-check-in');
    await tapKey(tester, 'quit-date-confirm');
    await tapKey(tester, 'reason-choice-saveMoney');
    await tapKey(tester, 'reasons-save');
    await tapKey(tester, 'support-add-person');
    await tester.enterText(
      find.byKey(const ValueKey('support-person-name-field')),
      'Synthetic Sam',
    );
    await tester.enterText(
      find.byKey(const ValueKey('support-person-relationship-field')),
      'Neighbour',
    );
    await tapKey(tester, 'support-person-save');
    await tapKey(tester, 'preparation-task-stockAlternatives');
    await tapKey(tester, 'support-treatment-toggle');
    await tapKey(tester, 'support-save');
    await tapKey(tester, 'review-start-plan');
    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
    );

    final saved = store.snapshot!;
    expect(saved.stage, GuestPlanStage.active);
    expect(saved.plan.quitReasons, ['saveMoney']);
    expect(saved.plan.topQuitReason, 'saveMoney');
    expect(saved.plan.supportPeople.map((p) => p.name), ['Synthetic Sam']);
    expect(saved.plan.preparationTasks, ['stockAlternatives']);
    expect(saved.plan.treatmentSupport, isTrue);
    expect(saved.plan.careTeamReminder, isFalse);
    expect(saved.plan.quitDayCheckIn, isTrue);

    // A later launch restores the same answers, not the new-plan defaults.
    await tester.pumpWidget(BreatheFreeApp(
      key: const ValueKey('second-launch'),
      quitPlanController: QuitPlanController.disabled(guestStore: store),
    ));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
    );
    expect(find.text('“Save money.”'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.textContaining('Synthetic Sam'), findsWidgets);

    await tapKey(tester, 'preparation-nav-support');
    expect(find.text('Synthetic Sam · Neighbour'), findsOneWidget);
    expect(find.text('No one has been added yet.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a restored plan shows its saved reasons and supporter',
      (tester) async {
    usePhone(tester);
    final store = _MemoryGuestStore()
      ..snapshot = GuestQuitPlanSnapshot(
        plan: QuitPlan(
          userId: '',
          dailyCigaretteUse: null,
          smokingTriggers: const [],
          customSmokingTrigger: null,
          readinessPath: 'prepare',
          quitPlanPath: 'setQuitDate',
          quitDate:
              DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 5)),
          quitDayCheckIn: true,
          quitReasons: const ['family', 'future'],
          customQuitReason: null,
          topQuitReason: 'future',
          supportPeople: const [
            QuitPlanSupportPerson(
              id: 'synthetic-1',
              name: 'Synthetic Riley',
              relationship: 'Cousin',
              channel: 'call',
              checkIn: '',
              enabled: true,
            ),
          ],
          preparationTasks: const ['removeSupplies'],
          treatmentSupport: true,
          careTeamReminder: true,
        ),
        stage: GuestPlanStage.draft,
        savedAt: DateTime.utc(2026, 10, 1),
      );

    await tester.pumpWidget(BreatheFreeApp(
      quitPlanController: QuitPlanController.disabled(guestStore: store),
    ));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );

    await tapKey(tester, 'review-edit-reasons');
    expect(find.text('2 SELECTED'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reason-selected-family')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('reason-selected-future')), findsOneWidget);
    await tapKey(tester, 'reasons-save');

    await tapKey(tester, 'review-edit-support');
    expect(find.text('Synthetic Riley'), findsOneWidget);
    expect(find.text('1 OF 3'), findsOneWidget);
    expect(switchValue(tester, 'support-treatment-toggle'), isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _MemoryGuestStore implements GuestQuitPlanStore {
  GuestQuitPlanSnapshot? snapshot;

  @override
  bool get isPersistent => true;

  @override
  Future<GuestQuitPlanSnapshot?> load() async => snapshot;

  @override
  Future<void> save(GuestQuitPlanSnapshot value) async => snapshot = value;

  @override
  Future<void> clear() async => snapshot = null;
}
