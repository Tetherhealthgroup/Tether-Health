import 'package:breathefree_patient/l10n/app_localizations.dart';
import 'package:breathefree_patient/l10n/app_locale.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/quit_plan/guest_quit_plan_store.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_controller.dart';
import 'package:breathefree_patient/screens/approved_screen_player.dart';
import 'package:breathefree_patient/screens/recommended_rescue_tool_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Screens show only what the member recorded: no invented Rescue results,
// sync times, reminders, preselected answers or lesson progress. Home follows
// the quit date wherever the app opens it, and the Progress and Support tab
// bar is announced as working buttons.
void main() {
  void useView(WidgetTester tester, {Size size = const Size(800, 1800)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
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

  Finder quitDayHome() => find.text('SINCE YOUR PLANNED QUIT TIME');
  Finder preparationHome() =>
      find.byKey(const ValueKey('functional-home-preparation-screen'));

  group('Rescue describes only a real past result', () {
    testWidgets('with no rated Rescue it claims no history', (tester) async {
      useView(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 17));
      await tester.pumpAndSettle();

      for (final claim in const [
        'YOUR LAST RESULT',
        'Craving changed from 6 to 3 after the exercise.',
        '6 → 3',
        'Slow breathing was selected as most helpful.',
        'Start with what helped before.',
        'Personalized match',
        'One recommended action, based on this craving and your results.',
      ]) {
        expect(find.text(claim), findsNothing, reason: claim);
      }
      expect(
          find.byKey(const ValueKey('rescue-tool-last-result')), findsNothing);
      expect(find.textContaining('previous helpful result'), findsNothing);
      expect(find.text('What feels possible right now?'), findsOneWidget);
      expect(
        find.text('One recommended action, based on this craving.'),
        findsOneWidget,
      );

      await tapKey(tester, 'rescue-tool-why-match');
      expect(find.textContaining('previously helpful'), findsNothing);
      expect(
        find.textContaining('make slow breathing a practical first step'),
        findsOneWidget,
      );
    });

    Widget tool(RescueLastResult? lastResult) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: RecommendedRescueToolScreen(
            isSpanish: false,
            intensity: 7,
            stressSelected: false,
            supportName: 'your support person',
            selectedTool: RescueTool.slowBreathing,
            onToolChanged: (_) {},
            onBack: () {},
            onStart: () {},
            onViewSupport: () {},
            lastResult: lastResult,
          ),
        );

    testWidgets('a helpful breathing result is shown with its real numbers',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(tool(const RescueLastResult(
        tool: RescueTool.slowBreathing,
        before: 8,
        after: 4,
        helpful: true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Start with what helped before.'), findsOneWidget);
      expect(find.text('YOUR LAST RESULT'), findsOneWidget);
      expect(
        find.text('Craving changed from 8 to 4 after the exercise.'),
        findsOneWidget,
      );
      expect(find.text('8 → 4'), findsOneWidget);
      // The member only answered whether it helped, not which tool helped
      // most, so no "most helpful" claim is made.
      expect(
        find.text('Slow breathing was selected as most helpful.'),
        findsNothing,
      );
      expect(find.text('Personalized match'), findsOneWidget);
    });

    testWidgets('a result that did not help is not called helpful',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(tool(const RescueLastResult(
        tool: RescueTool.slowBreathing,
        before: 5,
        after: 5,
        helpful: false,
      )));
      await tester.pumpAndSettle();

      expect(
        find.text('Craving changed from 5 to 5 after the exercise.'),
        findsOneWidget,
      );
      expect(
        find.text('Slow breathing was selected as most helpful.'),
        findsNothing,
      );
      expect(find.text('Start with what helped before.'), findsNothing);
      expect(find.textContaining('previous helpful result'), findsNothing);
    });

    testWidgets('a result from another tool is not shown on breathing',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(tool(const RescueLastResult(
        tool: RescueTool.move,
        before: 7,
        after: 2,
        helpful: true,
      )));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('rescue-tool-last-result')), findsNothing);
      expect(find.text('Start with what helped before.'), findsNothing);
    });

    testWidgets('the app records a rated Rescue and shows it next time',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 19));
      await tester.pumpAndSettle();

      await tapKey(tester, 'craving-recheck-number-2');
      await tapKey(tester, 'craving-recheck-helpful-yes');
      await tapKey(tester, 'craving-recheck-save');
      await tapKey(tester, 'screen-21-back-to-today');
      await tapKey(tester, 'preparation-open-rescue');
      await tapKey(tester, 'rescue-start-continue');

      expect(find.text('Start with what helped before.'), findsOneWidget);
      expect(find.textContaining('to 2 after the exercise.'), findsOneWidget);
      expect(find.textContaining('to 3 after the exercise.'), findsNothing);
    });

    testWidgets('"A little" is a recorded result but not "helped before"',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 19));
      await tester.pumpAndSettle();

      await tapKey(tester, 'craving-recheck-number-4');
      await tapKey(tester, 'craving-recheck-helpful-aLittle');
      await tapKey(tester, 'craving-recheck-save');
      await tapKey(tester, 'screen-21-back-to-today');
      await tapKey(tester, 'preparation-open-rescue');
      await tapKey(tester, 'rescue-start-continue');

      expect(find.textContaining('to 4 after the exercise.'), findsOneWidget);
      expect(find.text('What feels possible right now?'), findsOneWidget);
      expect(find.text('Start with what helped before.'), findsNothing);
      expect(find.text('Personalized match'), findsNothing);
      expect(find.textContaining('previous helpful result'), findsNothing);
    });
  });

  group('Home follows the quit date everywhere it opens', () {
    test('the rule: countdown Home before the date, quit-day Home from it', () {
      final today = DateTime(2026, 10, 22, 15);
      expect(homeScreenFor(DateTime(2026, 10, 23), today: today), 11);
      expect(homeScreenFor(DateTime(2026, 10, 22), today: today), 21);
      expect(homeScreenFor(DateTime(2026, 10, 1), today: today), 21);
    });

    testWidgets('a started plan restores to the quit-day Home on quit day',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(BreatheFreeApp(
        quitPlanController: _startedGuestPlan(quitDate: _today()),
      ));
      await tester.pumpAndSettle();

      expect(quitDayHome(), findsOneWidget);
      expect(preparationHome(), findsNothing);
    });

    testWidgets('a started plan restores to the countdown Home before it',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(BreatheFreeApp(
        quitPlanController: _startedGuestPlan(
          quitDate: _today().add(const Duration(days: 2)),
        ),
      ));
      await tester.pumpAndSettle();

      expect(preparationHome(), findsOneWidget);
      expect(quitDayHome(), findsNothing);
    });

    testWidgets('starting a quit-today plan opens the quit-day Home',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(const BreatheFreeApp());
      await tester.pumpAndSettle();
      for (final key in const [
        'welcome-get-started',
        'why-continue',
        'consent-agree-continue',
        'baseline-choice-tenOrFewer',
        'baseline-next',
        'trigger-choice-stress',
        'trigger-continue',
        'readiness-continue',
        'quit-path-choice-quitToday',
        'quit-path-continue',
        'quit-date-confirm',
        'reason-choice-future',
        'reasons-save',
        'support-save',
        'review-start-plan',
      ]) {
        await tapKey(tester, key);
      }

      expect(quitDayHome(), findsOneWidget);
      expect(preparationHome(), findsNothing);
    });

    testWidgets('the Home button on the countdown Home opens quit-day Home',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(BreatheFreeApp(
        initialScreen: 11,
        quitPlanController: QuitPlanController.disabled()
          ..plan = _plan(quitDate: _today()),
      ));
      await tester.pumpAndSettle();
      expect(preparationHome(), findsOneWidget);

      await tapKey(tester, 'preparation-nav-home');

      expect(quitDayHome(), findsOneWidget);
    });
  });

  group('no invented treatment, sync, reminder or slip claims', () {
    testWidgets('no fixed time zone is shown next to quit dates and times',
        (tester) async {
      useView(tester);
      for (final screen in const [10, 11, 21]) {
        for (final locale in const [Locale('en'), Locale('es')]) {
          final appLocale = AppLocale(
            store: MemoryAppLocaleStore(),
            deviceLocales: () => [locale],
          );
          await appLocale.load();
          addTearDown(appLocale.dispose);
          await tester.pumpWidget(BreatheFreeApp(
            key: ValueKey('$screen-$locale'),
            appLocale: appLocale,
            initialScreen: screen,
            quitPlanController: QuitPlanController.disabled()
              ..plan = _plan(quitDate: _today()),
          ));
          await tester.pumpAndSettle();
          expect(appLocale.isSpanish, locale.languageCode == 'es');
          expect(find.textContaining('Pacific Time'), findsNothing,
              reason: '$screen $locale');
          expect(find.textContaining('Hora del Pacífico'), findsNothing,
              reason: '$screen $locale');
        }
      }
    });

    testWidgets('quit-day Home shows the treatment row only with support on',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(BreatheFreeApp(
        initialScreen: 21,
        quitPlanController: QuitPlanController.disabled()
          ..plan = _plan(quitDate: _today()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('RECORDED TREATMENT PLAN'), findsNothing);
      expect(find.text('2 items'), findsNothing);
      expect(find.text('MORNING CHECK-IN'), findsOneWidget);
      expect(find.text('Take your planned morning action'), findsNothing);
      expect(find.text('Take your morning action'), findsOneWidget);

      await tester.pumpWidget(BreatheFreeApp(
        key: const ValueKey('treatment-on'),
        initialScreen: 21,
        quitPlanController: QuitPlanController.disabled()
          ..plan = _plan(quitDate: _today(), treatmentSupport: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('RECORDED TREATMENT PLAN'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
    });

    testWidgets('medication shows no sync time, timing or next reminder',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 23));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last synced'), findsNothing);
      expect(find.textContaining('9:12'), findsNothing);
      await tester.ensureVisible(find.text('Plan remains available offline'));
      expect(find.text('Plan remains available offline'), findsOneWidget);

      await tapKey(tester, 'medication-add-update-plan');
      for (final timing in const ['morning', 'afternoon', 'evening', 'other']) {
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(ValueKey('medication-plan-timing-$timing')),
              )
              .selected,
          isFalse,
          reason: timing,
        );
      }
      await tapKey(tester, 'medication-plan-medicine-nicotineGum');
      await tapKey(tester, 'medication-plan-sheet-done');
      expect(
        find.text('Follow the instructions in your recorded plan'),
        findsOneWidget,
      );
      expect(find.textContaining('Morning'), findsNothing);

      await tapKey(tester, 'medication-update-status');
      await tapKey(tester, 'medication-status-taken');
      expect(find.textContaining('Next reminder'), findsNothing);
      expect(find.textContaining('8:00 AM'), findsNothing);
    });

    testWidgets('slip recovery starts unanswered and claims no history',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 22));
      await tester.pumpAndSettle();

      final selected = find.byWidgetPredicate(
        (widget) =>
            const {
              '_EventChoice',
              '_WhenChoice',
              '_TriggerChoice',
              '_RecoveryChoice',
            }.contains(widget.runtimeType.toString()) &&
            (widget as dynamic).selected == true,
      );
      expect(selected, findsNothing);
      expect(find.textContaining('what helped before'), findsNothing);

      await tester.ensureVisible(find.text('A puff or two'));
      await tester.tap(find.text('A puff or two'));
      await tester.pumpAndSettle();
      expect(selected, findsOneWidget);
    });

    testWidgets('Learn shows no lesson progress the member did not make',
        (tester) async {
      useView(tester);
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 24));
      await tester.pumpAndSettle();

      expect(find.text('TRIGGERS · 2 OF 4'), findsNothing);
      expect(find.byKey(const ValueKey('learn-resume-lesson')), findsNothing);
      expect(find.textContaining('lessons saved offline'), findsNothing);
      expect(find.text('Continue learning'), findsNothing);
    });
  });

  testWidgets('Progress and Support tab bars are enabled, tappable buttons',
      (tester) async {
    useView(tester);
    final semantics = tester.ensureSemantics();
    for (final screen in const [25, 26]) {
      await tester.pumpWidget(BreatheFreeApp(
        key: ValueKey(screen),
        initialScreen: screen,
      ));
      await tester.pumpAndSettle();
      for (final item in const ['home', 'plan', 'progress', 'learn']) {
        expect(
          tester.getSemantics(find.byKey(ValueKey('learn-nav-$item'))),
          isSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
          reason: '$screen $item',
        );
      }
    }
    semantics.dispose();
  });
}

DateTime _today() => DateUtils.dateOnly(DateTime.now());

QuitPlan _plan({required DateTime quitDate, bool treatmentSupport = false}) =>
    QuitPlan(
      userId: '',
      dailyCigaretteUse: null,
      smokingTriggers: const [],
      customSmokingTrigger: null,
      readinessPath: 'prepare',
      quitPlanPath: 'setQuitDate',
      quitDate: quitDate,
      quitDayCheckIn: false,
      quitReasons: const ['future'],
      customQuitReason: null,
      topQuitReason: 'future',
      supportPeople: const [],
      preparationTasks: const [],
      treatmentSupport: treatmentSupport,
      careTeamReminder: false,
    );

QuitPlanController _startedGuestPlan({required DateTime quitDate}) =>
    QuitPlanController.disabled(
      guestStore: _MemoryGuestStore(GuestQuitPlanSnapshot(
        plan: _plan(quitDate: quitDate),
        stage: GuestPlanStage.active,
        savedAt: DateTime.utc(2026, 10, 1),
      )),
    );

class _MemoryGuestStore implements GuestQuitPlanStore {
  _MemoryGuestStore(this.snapshot);

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
