// Security — gating that must not be bypassable.
//
// Extracted from the original flat test/widget_test.dart; each test was
// already self-contained, so behaviour is unchanged.

import 'package:breathefree_patient/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forward swipes cannot bypass explicit onboarding actions',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const ValueKey('functional-welcome-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-welcome-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-why-breathefree-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-why-breathefree-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('consent-agree-continue')),
    );
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-baseline-assessment-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-baseline-assessment-screen')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('baseline-next')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey('baseline-choice-tenOrFewer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-trigger-map-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-trigger-map-screen')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('trigger-continue')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('trigger-choice-stress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-continue')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-readiness-result-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-readiness-result-screen')),
      findsOneWidget,
      reason: 'Screen 6 should require its explicit main action.',
    );
    await tester.tap(find.byKey(const ValueKey('readiness-continue')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-choose-quit-path-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-choose-quit-path-screen')),
      findsOneWidget,
      reason: 'Screen 7 should require its explicit Continue button.',
    );
    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-select-quit-date-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-select-quit-date-screen')),
      findsOneWidget,
      reason: 'Screen 8 should require its explicit Confirm button.',
    );
    await tester.tap(find.byKey(const ValueKey('quit-date-confirm')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      findsOneWidget,
      reason: 'Screen 9 should require its explicit Save button.',
    );
    await tester.tap(find.byKey(const ValueKey('reasons-save')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-support-preparation-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-support-preparation-screen')),
      findsOneWidget,
      reason: 'Screen 10 should require its explicit Save button.',
    );
    await tester.tap(find.byKey(const ValueKey('support-save')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
      reason: 'Screen 11 should require its explicit Start button.',
    );
    await tester.tap(find.byKey(const ValueKey('review-start-plan')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
      reason: 'Screen 12 should not advance through a forward swipe.',
    );
    await tester.tap(
      find.byKey(const ValueKey('preparation-notifications')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('preparation-start-check-in')),
    );
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
      reason: 'Screen 13 should require its explicit Save button.',
    );
    await tester.tap(find.byKey(const ValueKey('checkin-save')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      findsOneWidget,
      reason: 'Screen 14 should require its explicit Practice action.',
    );
    await tester.tap(find.byKey(const ValueKey('next-step-practice')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
      findsOneWidget,
      reason: 'Screen 15 should require an explicit exercise action.',
    );
    expect(tester.takeException(), isNull);
  });
}
