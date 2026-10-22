import 'package:breathefree_patient/models/tap_target.dart';
import 'package:breathefree_patient/screens/approved_screen_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/fakes.dart';
import 'large_text_harness.dart';

/// The onboarding questions after consent (screens 3 to 10, up to the plan
/// review) must stay usable at the largest system text sizes: no layout
/// overflow, no text clipped, cut to an ellipsis or split mid-word, and the
/// screen's main action reachable by scrolling and at least 48 px tall.
/// See large_text_harness.dart for the scales, devices and fonts.
class _OnboardingScreen {
  const _OnboardingScreen({
    required this.name,
    required this.index,
    required this.rootKey,
    required this.primaryKey,
    required this.title,
    required this.backKey,
    this.choiceKey,
    this.continues = true,
  });

  final String name;
  final int index;
  final String rootKey;
  final String primaryKey;

  /// The English header title and the header's back button.
  final String title;
  final String backKey;

  /// A choice to tap before the main action, which stays disabled until
  /// something is chosen.
  final String? choiceKey;

  /// Whether the main action moves to the next screen. Starting the plan on
  /// the review screen saves it instead.
  final bool continues;
}

const _screens = <_OnboardingScreen>[
  _OnboardingScreen(
    name: 'baseline assessment',
    index: 3,
    rootKey: 'functional-baseline-assessment-screen',
    primaryKey: 'baseline-next',
    title: 'About your smoking',
    backKey: 'baseline-back',
    choiceKey: 'baseline-choice-tenOrFewer',
  ),
  _OnboardingScreen(
    name: 'trigger map',
    index: 4,
    rootKey: 'functional-trigger-map-screen',
    primaryKey: 'trigger-continue',
    title: 'Your triggers',
    backKey: 'trigger-back',
    choiceKey: 'trigger-choice-stress',
  ),
  _OnboardingScreen(
    name: 'readiness result',
    index: 5,
    rootKey: 'functional-readiness-result-screen',
    primaryKey: 'readiness-continue',
    title: 'Your starting point',
    backKey: 'readiness-back',
  ),
  _OnboardingScreen(
    name: 'choose quit path',
    index: 6,
    rootKey: 'functional-choose-quit-path-screen',
    primaryKey: 'quit-path-continue',
    title: 'Build your plan',
    backKey: 'quit-path-back',
  ),
  _OnboardingScreen(
    name: 'select quit date',
    index: 7,
    rootKey: 'functional-select-quit-date-screen',
    primaryKey: 'quit-date-confirm',
    title: 'Choose your quit date',
    backKey: 'quit-date-back',
  ),
  _OnboardingScreen(
    name: 'my reasons',
    index: 8,
    rootKey: 'functional-my-reasons-screen',
    primaryKey: 'reasons-save',
    title: 'My reasons',
    backKey: 'reasons-back',
    choiceKey: 'reason-choice-saveMoney',
  ),
  _OnboardingScreen(
    name: 'support and preparation',
    index: 9,
    rootKey: 'functional-support-preparation-screen',
    primaryKey: 'support-save',
    title: 'Support & preparation',
    backKey: 'support-back',
  ),
  _OnboardingScreen(
    name: 'review quit plan',
    index: 10,
    rootKey: 'functional-review-quit-plan-screen',
    primaryKey: 'review-start-plan',
    title: 'Review your plan',
    backKey: 'review-back',
    continues: false,
  ),
];

void main() {
  setUpAll(loadRoboto);

  // The quit-date calendar lists its days at accessibility sizes instead of
  // shrinking them into a grid; each day stays tappable at full text size.
  for (final device in largeTextDevices.entries) {
    for (final scaler in largeTextScalers.entries) {
      testWidgets(
          'quit date days are full size and tappable on ${device.key} at '
          '${scaler.key}', (tester) async {
        await _pumpOnboarding(
          tester,
          size: device.value,
          scaler: scaler.value,
          font: LargeTextFont.roboto,
          index: 7,
          spanish: false,
        );
        final listed = scaler.value.scale(10) > 14;
        final calendar = find.byKey(const ValueKey('quit-date-calendar'));
        expect(
          find.descendant(of: calendar, matching: find.byType(GridView)),
          listed ? findsNothing : findsOneWidget,
        );

        // A selectable day in the shown month other than the default date.
        final today = DateUtils.dateOnly(DateTime.now());
        final chosen = DateTime(today.year, today.month, today.day + 7);
        final next = DateTime(today.year, today.month, today.day + 8);
        final day = next.month == chosen.month
            ? next
            : DateTime(today.year, today.month, today.day + 6);
        final target = find.byKey(ValueKey(_dayKey(day)));
        // The grid's 34 px day circles are the approved default design; the
        // list's rows meet the 48 px minimum.
        await expectReachable(
          tester,
          target,
          device.value,
          minHeight: listed ? minTapTarget : 34,
        );

        final number = find.descendant(
          of: target,
          matching: find.text('${day.day}'),
        );
        final paragraph = tester.renderObject<RenderParagraph>(number);
        expect(paragraph.textScaler, scaler.value, reason: 'not shrunk');
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.getMaxIntrinsicHeight(paragraph.size.width),
          lessThanOrEqualTo(paragraph.size.height + 1),
          reason: 'day number is not clipped',
        );

        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: target,
            matching: find.byKey(const ValueKey('quit-date-selected')),
          ),
          findsOneWidget,
        );
      });
    }
  }

  for (final font in LargeTextFont.values) {
    for (final device in largeTextDevices.entries) {
      for (final scaler in largeTextScalers.entries) {
        final variant = '${device.key} at ${scaler.key} (${font.name})';
        final allowSplitWords = wordsMayBreak(device.value, scaler.value);
        for (final screen in _screens) {
          for (final spanish in [false, true]) {
            final language = spanish ? ' in Spanish' : '';
            testWidgets('${screen.name}$language is usable on $variant',
                (tester) async {
              var nextTaps = 0;
              final errors = await captureLayoutErrors(() async {
                await _pumpOnboarding(
                  tester,
                  size: device.value,
                  scaler: scaler.value,
                  font: font,
                  index: screen.index,
                  spanish: spanish,
                  onNext: () => nextTaps++,
                );
              });
              expect(describeErrors(errors), isEmpty, reason: 'layout errors');

              final root = find.byKey(ValueKey(screen.rootKey));
              expect(root, findsOneWidget);
              expect(
                textProblems(
                  tester,
                  root,
                  font,
                  allowSplitWords: allowSplitWords,
                ),
                isEmpty,
              );

              if (!spanish) {
                final title = find.descendant(
                  of: root,
                  matching: find.text(screen.title),
                );
                // Above 140% the header title takes a line of its own below
                // the back button instead of shrinking beside it.
                if (scaler.value.scale(10) > 14) {
                  expect(
                    tester.getRect(title).top,
                    greaterThanOrEqualTo(
                      tester
                              .getRect(find.byKey(ValueKey(screen.backKey)))
                              .bottom -
                          0.5,
                    ),
                    reason: 'header title has a line of its own',
                  );
                }
                if (font == LargeTextFont.roboto && device.value.width >= 360) {
                  expect(
                    tester.renderObject<RenderParagraph>(title).textScaler,
                    scaler.value,
                    reason: 'header title is drawn at the system text size',
                  );
                }
              }

              if (screen.choiceKey != null) {
                final choice = find.byKey(ValueKey<String>(screen.choiceKey!));
                await expectReachable(tester, choice, device.value);
                final choiceErrors = await captureLayoutErrors(() async {
                  await tester.tap(choice);
                  await tester.pumpAndSettle();
                });
                expect(
                  describeErrors(choiceErrors),
                  isEmpty,
                  reason: 'layout errors after choosing',
                );
                expect(
                  textProblems(
                    tester,
                    root,
                    font,
                    allowSplitWords: allowSplitWords,
                  ),
                  isEmpty,
                );
              }

              final primary = find.byKey(ValueKey(screen.primaryKey));
              if (screen.continues) {
                await expectReachableAndTappable(tester, primary, device.value);
                expect(nextTaps, 1, reason: 'main action reached the flow');
              } else {
                await expectReachable(tester, primary, device.value);
              }
            });
          }
        }
      }
    }
  }
}

String _dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'quit-date-day-${date.year}-$month-$day';
}

/// Pumps the onboarding player at the welcome screen, picks Spanish there
/// when asked (the later screens take their language from it), then moves the
/// same player to screen [index].
Future<void> _pumpOnboarding(
  WidgetTester tester, {
  required Size size,
  required TextScaler scaler,
  required LargeTextFont font,
  required int index,
  required bool spanish,
  VoidCallback? onNext,
}) async {
  final account = fakeAccount();
  addTearDown(account.dispose);
  final current = ValueNotifier<int>(spanish ? 0 : index);
  addTearDown(current.dispose);
  await pumpLargeText(
    tester,
    size: size,
    scaler: scaler,
    font: font,
    home: ValueListenableBuilder<int>(
      valueListenable: current,
      builder: (context, value, _) => ApprovedScreenPlayer(
        accountController: account,
        currentIndex: value,
        onSelectScreen: (_) {},
        onPrevious: () {},
        onNext: onNext ?? () {},
        onTarget: (AppTapTarget _) {},
      ),
    ),
  );
  if (!spanish) return;
  final choice = find.byKey(const ValueKey('welcome-spanish'));
  await tester.ensureVisible(choice);
  await tester.pumpAndSettle();
  await tester.tap(choice);
  await tester.pumpAndSettle();
  expect(find.text('Comenzar'), findsOneWidget);
  current.value = index;
  await tester.pumpAndSettle();
}
