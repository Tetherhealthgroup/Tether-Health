// UI — rendered output across every supported phone size.
//
// Extracted from the original flat test/widget_test.dart; each test was
// already self-contained, so behaviour is unchanged.

import 'package:breathefree_patient/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Screen 1 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;

      await tester.pumpWidget(
        BreatheFreeApp(key: ValueKey(device.name)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-welcome-screen')),
        findsOneWidget,
        reason: '${device.name} should display the functional welcome screen.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      final accountAction = find.byKey(const ValueKey('welcome-sign-in'));
      await tester.ensureVisible(accountAction);
      await tester.pumpAndSettle();

      expect(
        tester.getRect(accountAction).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep the account action reachable.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should scroll without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 2 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;

      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-2-${device.name}'),
          initialScreen: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-why-breathefree-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 2.',
      );
      expect(
        find.byKey(const ValueKey('why-continue')),
        findsOneWidget,
        reason: '${device.name} should keep Continue available.',
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('why-continue'))).overlaps(
              Offset.zero & device.size,
            ),
        isTrue,
        reason: '${device.name} should show Continue without scrolling.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      final slipCard = find.byKey(const ValueKey('why-card-slip'));
      await tester.ensureVisible(slipCard);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should scroll through all support cards.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 7 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-7-${device.name}'),
          initialScreen: 6,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-choose-quit-path-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 7.',
      );
      final continueButton = find.byKey(const ValueKey('quit-path-continue'));
      expect(
        tester.getRect(continueButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Continue visible.',
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
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 8 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-8-${device.name}'),
          initialScreen: 7,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-select-quit-date-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 8.',
      );
      final confirm = find.byKey(const ValueKey('quit-date-confirm'));
      expect(
        tester.getRect(confirm).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Confirm visible.',
      );
      expect(find.byKey(const ValueKey('quit-date-calendar')), findsOneWidget);

      final checkIn = find.byKey(const ValueKey('quit-date-check-in'));
      await tester.ensureVisible(checkIn);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 9 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-9-${device.name}'),
          initialScreen: 8,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-my-reasons-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 9.',
      );
      final save = find.byKey(const ValueKey('reasons-save'));
      expect(
        tester.getRect(save).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Save my reasons visible.',
      );

      final customEditor = find.byKey(const ValueKey('reason-custom-editor'));
      await tester.ensureVisible(customEditor);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 10 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-10-${device.name}'),
          initialScreen: 9,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-support-preparation-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 10.',
      );
      final save = find.byKey(const ValueKey('support-save'));
      expect(
        tester.getRect(save).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Save visible.',
      );

      final finalTask =
          find.byKey(const ValueKey('preparation-task-stockAlternatives'));
      await tester.ensureVisible(finalTask);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 11 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-11-${device.name}'),
          initialScreen: 10,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-review-quit-plan-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 11.',
      );
      for (final key in const [
        ValueKey('review-start-plan'),
        ValueKey('review-save-later'),
      ]) {
        expect(
          tester.getRect(find.byKey(key)).overlaps(Offset.zero & device.size),
          isTrue,
          reason: '${device.name} should keep both actions visible.',
        );
      }

      final treatment = find.byKey(const ValueKey('review-edit-treatment'));
      await tester.ensureVisible(treatment);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 12 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-12-${device.name}'),
          initialScreen: 11,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-home-preparation-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 12.',
      );
      expect(
        tester
            .getRect(
              find.byKey(const ValueKey('preparation-bottom-navigation')),
            )
            .overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep bottom navigation visible.',
      );

      final upcoming = find.byKey(const ValueKey('preparation-upcoming-card'));
      await tester.ensureVisible(upcoming);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 13 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-13-${device.name}'),
          initialScreen: 12,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-daily-check-in-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 13.',
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('checkin-save')))
            .overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Save check-in visible.',
      );

      final support = find.byKey(const ValueKey('checkin-open-rescue'));
      await tester.ensureVisible(support);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 14 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-14-${device.name}'),
          initialScreen: 13,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-personalized-next-step-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 14.',
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('next-step-practice')))
            .overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Practice this now visible.',
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('next-step-coping-plan')))
            .overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep the coping-plan action visible.',
      );

      final choose = find.byKey(const ValueKey('next-step-choose-strategy'));
      await tester.ensureVisible(choose);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 6 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-6-${device.name}'),
          initialScreen: 5,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-readiness-result-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 6.',
      );
      final continueButton = find.byKey(const ValueKey('readiness-continue'));
      expect(
        tester.getRect(continueButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep the main action visible.',
      );

      final connect = find.byKey(const ValueKey('readiness-path-connect'));
      await tester.ensureVisible(connect);
      await tester.tap(connect);
      await tester.pumpAndSettle();
      expect(find.text('Find support options'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 5 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-5-${device.name}'),
          initialScreen: 4,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-trigger-map-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 5.',
      );
      final continueButton = find.byKey(const ValueKey('trigger-continue'));
      expect(
        tester.getRect(continueButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Continue visible.',
      );
      expect(tester.takeException(), isNull);

      final lastChoice = find.byKey(const ValueKey('trigger-choice-beforeBed'));
      await tester.ensureVisible(lastChoice);
      await tester.tap(lastChoice);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('trigger-selected-beforeBed')),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 4 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;

      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-4-${device.name}'),
          initialScreen: 3,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-baseline-assessment-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 4.',
      );

      final nextButton = find.byKey(const ValueKey('baseline-next'));
      expect(nextButton, findsOneWidget);
      expect(
        tester.getRect(nextButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Next visible.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      final lastChoice =
          find.byKey(const ValueKey('baseline-choice-thirtyOneOrMore'));
      await tester.ensureVisible(lastChoice);
      await tester.pumpAndSettle();
      await tester.tap(lastChoice);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('baseline-selected-thirtyOneOrMore')),
        findsOneWidget,
        reason: '${device.name} should allow the final answer.',
      );
      expect(
        tester.widget<FilledButton>(nextButton).onPressed,
        isNotNull,
        reason: '${device.name} should enable Next after an answer.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should scroll without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 3 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;

      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-3-${device.name}'),
          initialScreen: 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-consent-privacy-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 3.',
      );

      final continueButton =
          find.byKey(const ValueKey('consent-agree-continue'));
      expect(continueButton, findsOneWidget);
      expect(
        tester.getRect(continueButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Agree and continue visible.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      final finalChoice = find.byKey(const ValueKey('consent-help-improve'));
      await tester.ensureVisible(finalChoice);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should reach every optional choice.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 15 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-15-${device.name}'),
          initialScreen: 14,
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 15.',
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('stress-reset-close')))
            .overlaps(Offset.zero & device.size),
        isTrue,
      );
      final end = find.byKey(const ValueKey('stress-reset-end'));
      await tester.ensureVisible(end);
      await tester.pump();
      expect(
        tester.getRect(end).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should reach End exercise.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('Screen 16 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-16-${device.name}'),
          initialScreen: 15,
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey('functional-exercise-complete-recheck-screen'),
        ),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 16.',
      );
      final save = find.byKey(const ValueKey('exercise-recheck-save'));
      expect(
        tester.getRect(save).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Save result visible.',
      );

      final rescue = find.byKey(const ValueKey('exercise-recheck-rescue'));
      await tester.ensureVisible(rescue);
      await tester.pump();
      expect(
        tester.getRect(rescue).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should reach Rescue.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('Screen 17 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-17-${device.name}'),
          initialScreen: 16,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 17.',
      );
      final continueButton =
          find.byKey(const ValueKey('rescue-start-continue'));
      expect(
        tester.getRect(continueButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep the Rescue action visible.',
      );
      final context =
          find.byKey(const ValueKey('rescue-start-context-notSure'));
      await tester.ensureVisible(context);
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('Screen 18 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-18-${device.name}'),
          initialScreen: 17,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-recommended-rescue-tool-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 18.',
      );
      final start = find.byKey(const ValueKey('rescue-tool-start'));
      expect(
        tester.getRect(start).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep the primary Rescue action visible.',
      );

      final support = find.byKey(const ValueKey('rescue-tool-support'));
      await tester.ensureVisible(support);
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
