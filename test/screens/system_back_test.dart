import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/quit_plan/guest_quit_plan_store.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Android system Back inside the single-route player: it does what each
// screen's own back control does, closes dialogs and sheets first, and only
// leaves the app from the first screen.
void main() {
  late List<String> systemNavigatorPops;

  setUp(() => systemNavigatorPops = <String>[]);

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') {
        systemNavigatorPops.add(call.method);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
  }

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder screen(String key) => find.byKey(ValueKey(key));

  testWidgets('Back on Welcome leaves the app', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();

    await systemBack(tester);

    expect(systemNavigatorPops, hasLength(1));
    expect(screen('functional-welcome-screen'), findsOneWidget);
  });

  testWidgets('Back walks the first-run screens back to Welcome',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();

    await tapKey(tester, 'welcome-get-started');
    await tapKey(tester, 'why-continue');
    await tapKey(tester, 'consent-agree-continue');
    await tapKey(tester, 'baseline-choice-tenOrFewer');
    await tapKey(tester, 'baseline-next');
    expect(screen('functional-trigger-map-screen'), findsOneWidget);

    await systemBack(tester);
    expect(screen('functional-baseline-assessment-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-consent-privacy-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-why-breathefree-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-welcome-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);

    await systemBack(tester);
    expect(systemNavigatorPops, hasLength(1));
  });

  testWidgets('Back matches the in-app back arrow on an inner screen',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();
    await tapKey(tester, 'welcome-get-started');
    await tapKey(tester, 'why-continue');

    await tapKey(tester, 'consent-back');
    expect(screen('functional-why-breathefree-screen'), findsOneWidget);
    await tapKey(tester, 'why-continue');

    await systemBack(tester);
    expect(screen('functional-why-breathefree-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);
  });

  testWidgets('Back closes an open sheet before leaving the screen',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 2));
    await tester.pumpAndSettle();

    await tapKey(tester, 'consent-review-privacy');
    expect(find.byType(BottomSheet), findsOneWidget);

    await systemBack(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(screen('functional-consent-privacy-screen'), findsOneWidget);

    await systemBack(tester);
    expect(screen('functional-why-breathefree-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);
  });

  testWidgets('Back while editing from the review cancels back to the review',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(BreatheFreeApp(
      initialScreen: 10,
      quitPlanController: _savedPlan(),
    ));
    await tester.pumpAndSettle();

    await tapKey(tester, 'review-edit-reasons');
    expect(screen('functional-my-reasons-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-review-quit-plan-screen'), findsOneWidget);

    await tapKey(tester, 'review-edit-support');
    expect(screen('functional-support-preparation-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-review-quit-plan-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);

    // Back also left edit mode, as the in-app back does: reasons opened later
    // from Home continue forward instead of returning as an edit.
    await tapKey(tester, 'review-start-plan');
    expect(screen('functional-home-preparation-screen'), findsOneWidget);
    await tapKey(tester, 'preparation-top-reason');
    expect(screen('functional-my-reasons-screen'), findsOneWidget);
    await tapKey(tester, 'reasons-save');
    expect(screen('functional-support-preparation-screen'), findsOneWidget);
  });

  testWidgets('Back from a tab returns to the screen it was opened from',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(BreatheFreeApp(
      initialScreen: 11,
      quitPlanController: _savedPlan(),
    ));
    await tester.pumpAndSettle();

    await tapKey(tester, 'preparation-nav-progress');
    expect(screen('functional-progress-dashboard-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-home-preparation-screen'), findsOneWidget);

    await tapKey(tester, 'preparation-nav-support');
    expect(screen('functional-support-hub-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-home-preparation-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);
  });

  testWidgets('a returning member restored onto Home leaves with one Back',
      (tester) async {
    usePhone(tester);
    final store = _MemoryGuestStore()
      ..snapshot = GuestQuitPlanSnapshot(
        plan: _savedPlan().plan!,
        stage: GuestPlanStage.active,
        savedAt: DateTime.utc(2026, 10, 1),
      );
    await tester.pumpWidget(BreatheFreeApp(
      quitPlanController: QuitPlanController.disabled(guestStore: store),
    ));
    await tester.pumpAndSettle();
    expect(screen('functional-home-preparation-screen'), findsOneWidget);

    await systemBack(tester);

    expect(systemNavigatorPops, hasLength(1));
    expect(screen('functional-home-preparation-screen'), findsOneWidget);
  });

  testWidgets('Back on the quit-day Home leaves the app', (tester) async {
    usePhone(tester);
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(BreatheFreeApp(
      initialScreen: 21,
      quitPlanController: _savedPlan(quitDate: _today()),
    ));
    await tester.pumpAndSettle();

    await systemBack(tester);

    expect(systemNavigatorPops, hasLength(1));
  });

  testWidgets('Back on any main tab goes to Home, not the previous tab',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(BreatheFreeApp(
      initialScreen: 11,
      quitPlanController: _savedPlan(),
    ));
    await tester.pumpAndSettle();

    await tapKey(tester, 'preparation-nav-progress');
    await tapKey(tester, 'learn-nav-support');
    expect(screen('functional-support-hub-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-home-preparation-screen'), findsOneWidget);

    await tapKey(tester, 'preparation-nav-learn');
    expect(screen('learn-library-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-home-preparation-screen'), findsOneWidget);

    // Plan is the review screen; after the plan has started it is a tab.
    await tapKey(tester, 'preparation-nav-plan');
    expect(screen('functional-review-quit-plan-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-home-preparation-screen'), findsOneWidget);

    // The in-app back arrow on a tab does the same.
    await tapKey(tester, 'preparation-nav-progress');
    await tapKey(tester, 'learn-nav-support');
    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();
    expect(screen('functional-home-preparation-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);
  });

  testWidgets('after starting the plan, Back from a tab goes to Home',
      (tester) async {
    usePhone(tester);
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
      'quit-path-continue',
      'quit-date-confirm',
      'reason-choice-future',
      'reasons-save',
      'support-save',
      'review-start-plan',
    ]) {
      await tapKey(tester, key);
    }
    expect(screen('functional-home-preparation-screen'), findsOneWidget);

    // Progress, then Plan: Back goes to Home, not to the previous tab.
    await tapKey(tester, 'preparation-nav-progress');
    await tapKey(tester, 'learn-nav-plan');
    expect(screen('functional-review-quit-plan-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-home-preparation-screen'), findsOneWidget);

    await systemBack(tester);
    expect(systemNavigatorPops, hasLength(1));
  });

  testWidgets('Back inside a flow opened from a tab returns to that tab',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(BreatheFreeApp(
      initialScreen: 11,
      quitPlanController: _savedPlan(),
    ));
    await tester.pumpAndSettle();

    await tapKey(tester, 'preparation-nav-support');
    await tapKey(tester, 'support-open-settings');
    expect(screen('functional-settings-privacy-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-support-hub-screen'), findsOneWidget);
    await systemBack(tester);
    expect(screen('functional-home-preparation-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);
  });

  testWidgets('before the plan starts, Back from the review steps back',
      (tester) async {
    usePhone(tester);
    final store = _MemoryGuestStore()
      ..snapshot = GuestQuitPlanSnapshot(
        plan: _savedPlan().plan!,
        stage: GuestPlanStage.draft,
        savedAt: DateTime.utc(2026, 10, 1),
      );
    await tester.pumpWidget(BreatheFreeApp(
      quitPlanController: QuitPlanController.disabled(guestStore: store),
    ));
    await tester.pumpAndSettle();
    expect(screen('functional-review-quit-plan-screen'), findsOneWidget);

    await systemBack(tester);
    expect(screen('functional-support-preparation-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);
  });

  testWidgets('Back in Rescue tool choice returns where Rescue was opened',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(BreatheFreeApp(
      initialScreen: 11,
      quitPlanController: _savedPlan(),
    ));
    await tester.pumpAndSettle();

    await tapKey(tester, 'preparation-open-rescue');
    expect(screen('functional-craving-rescue-start-screen'), findsOneWidget);
    await tapKey(tester, 'rescue-start-continue');
    expect(screen('functional-recommended-rescue-tool-screen'), findsOneWidget);

    await systemBack(tester);
    expect(screen('functional-home-preparation-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);
  });

  testWidgets('Back in the stress reset asks before leaving, like close',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 14));
    await tester.pumpAndSettle();

    await systemBack(tester);
    expect(screen('functional-guided-stress-reset-screen'), findsOneWidget);
    expect(find.text('Leave the exercise?'), findsOneWidget);

    // A second Back closes the question and stays in the exercise.
    await systemBack(tester);
    expect(find.text('Leave the exercise?'), findsNothing);
    expect(screen('functional-guided-stress-reset-screen'), findsOneWidget);

    await systemBack(tester);
    await tapKey(tester, 'stress-reset-exit-save');
    expect(screen('functional-guided-stress-reset-screen'), findsNothing);
    expect(systemNavigatorPops, isEmpty);
  });

  testWidgets('Back in an active Rescue asks before leaving, like close',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 18));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(screen('functional-active-craving-rescue-screen'), findsOneWidget);
    expect(screen('active-rescue-close-leave'), findsOneWidget);

    await tester.tap(screen('active-rescue-close-leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(screen('functional-recommended-rescue-tool-screen'), findsOneWidget);
    expect(systemNavigatorPops, isEmpty);
  });
}

DateTime _today() => DateUtils.dateOnly(DateTime.now());

QuitPlanController _savedPlan({DateTime? quitDate}) {
  final today = _today();
  return QuitPlanController.disabled()
    ..plan = QuitPlan(
      userId: '',
      dailyCigaretteUse: null,
      smokingTriggers: const [],
      customSmokingTrigger: null,
      readinessPath: 'prepare',
      quitPlanPath: 'setQuitDate',
      quitDate: quitDate ?? today.add(const Duration(days: 7)),
      quitDayCheckIn: false,
      quitReasons: const ['future'],
      customQuitReason: null,
      topQuitReason: 'future',
      supportPeople: const [
        QuitPlanSupportPerson(
          id: 'synthetic-1',
          name: 'Synthetic Kai',
          relationship: 'Friend',
          channel: 'text',
          checkIn: '',
          enabled: true,
        ),
      ],
      preparationTasks: const [],
      treatmentSupport: false,
      careTeamReminder: false,
    );
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
