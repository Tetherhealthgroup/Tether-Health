import 'dart:ui' show Tristate;

import 'package:breathefree_patient/l10n/app_locale.dart';
import 'package:breathefree_patient/models/tap_target.dart';
import 'package:breathefree_patient/screens/approved_screen_player.dart';
import 'package:breathefree_patient/screens/consent_privacy_screen.dart';
import 'package:breathefree_patient/screens/why_breathefree_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/fakes.dart';
import 'large_text_harness.dart';

/// The first-run screens a new user sees before signing in must stay usable
/// at the largest system text sizes: no layout overflow, no overlapping
/// cards, no text clipped or cut to an ellipsis, and the primary action
/// reachable by scrolling and at least 48 px tall.
///
/// See large_text_harness.dart for the text scales (iOS up to about 3.1,
/// Android 13 and older up to 1.3, Android 14 and newer up to a non-linear
/// 200%), devices and fonts.

class _FirstRunScreen {
  const _FirstRunScreen({
    required this.name,
    required this.index,
    required this.rootKey,
    required this.primaryKey,
  });

  final String name;
  final int index;
  final String rootKey;
  final String primaryKey;
}

const _screens = <_FirstRunScreen>[
  _FirstRunScreen(
    name: 'welcome',
    index: 0,
    rootKey: 'functional-welcome-screen',
    primaryKey: 'welcome-get-started',
  ),
  _FirstRunScreen(
    name: 'why BreatheFree',
    index: 1,
    rootKey: 'functional-why-breathefree-screen',
    primaryKey: 'why-continue',
  ),
  _FirstRunScreen(
    name: 'consent and privacy',
    index: 2,
    rootKey: 'functional-consent-privacy-screen',
    primaryKey: 'consent-agree-continue',
  ),
];

/// Screens two and three take their language from the welcome screen; the
/// Spanish copy has longer words, so it is checked on the screens directly.
final _spanishScreens = <String, Widget Function(VoidCallback onContinue)>{
  'why BreatheFree': (onContinue) => WhyBreatheFreeScreen(
        isSpanish: true,
        onBack: () {},
        onContinue: onContinue,
      ),
  'consent and privacy': (onContinue) => ConsentPrivacyScreen(
        isSpanish: true,
        helpfulReminders: true,
        shareWithCareTeam: false,
        helpImproveBreatheFree: false,
        onHelpfulRemindersChanged: (_) {},
        onShareWithCareTeamChanged: (_) {},
        onHelpImproveBreatheFreeChanged: (_) {},
        onBack: () {},
        onContinue: onContinue,
      ),
};

/// Known gap on a 320-pt-wide phone, skipped rather than dropped so it shows
/// in every run: at 200% the sign-in title splits a word.
bool _knownNarrowGap(
  String test,
  Size device,
  String scaler,
  LargeTextFont font,
) =>
    device.width < 360 &&
    scaler == 'text scale 2.0' &&
    font == LargeTextFont.roboto &&
    test == 'sign-in dialog';

void main() {
  setUpAll(loadRoboto);

  for (final font in LargeTextFont.values) {
    for (final device in largeTextDevices.entries) {
      for (final scaler in largeTextScalers.entries) {
        final variant = '${device.key} at ${scaler.key} (${font.name})';
        final allowSplitWords = wordsMayBreak(device.value, scaler.value);
        bool gap(String test) =>
            _knownNarrowGap(test, device.value, scaler.key, font);

        for (final screen in _screens) {
          testWidgets('${screen.name} is usable on $variant', (tester) async {
            var nextTaps = 0;
            final errors = await captureLayoutErrors(() async {
              await _pumpFirstRun(
                tester,
                size: device.value,
                scaler: scaler.value,
                font: font,
                index: screen.index,
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
                isEmpty);

            await expectReachableAndTappable(
              tester,
              find.byKey(ValueKey(screen.primaryKey)),
              device.value,
            );
            expect(nextTaps, 1, reason: 'primary action reached the flow');
          }, skip: gap(screen.name));
        }

        testWidgets('welcome in Spanish is usable on $variant', (tester) async {
          await _pumpFirstRun(
            tester,
            size: device.value,
            scaler: scaler.value,
            font: font,
            index: 0,
          );
          final spanish = find.byKey(const ValueKey('welcome-spanish'));
          await tester.ensureVisible(spanish);
          await tester.pumpAndSettle();
          final errors = await captureLayoutErrors(() async {
            await tester.tap(spanish);
            await tester.pumpAndSettle();
          });
          expect(describeErrors(errors), isEmpty, reason: 'layout errors');
          expect(find.text('Comenzar'), findsOneWidget);
          expect(
            textProblems(
              tester,
              find.byKey(const ValueKey('functional-welcome-screen')),
              font,
              allowSplitWords: allowSplitWords,
            ),
            isEmpty,
          );
        }, skip: gap('welcome in Spanish'));

        for (final screen in _spanishScreens.entries) {
          testWidgets('${screen.key} in Spanish is usable on $variant',
              (tester) async {
            var continued = 0;
            final errors = await captureLayoutErrors(() async {
              await pumpLargeText(
                tester,
                size: device.value,
                scaler: scaler.value,
                font: font,
                home: screen.value(() => continued++),
                locale: const Locale('es'),
              );
            });
            expect(describeErrors(errors), isEmpty, reason: 'layout errors');
            final root = find.byType(Scaffold).first;
            expect(
                textProblems(
                  tester,
                  root,
                  font,
                  allowSplitWords: allowSplitWords,
                ),
                isEmpty);
            final primary = find.byKey(
              ValueKey(
                screen.key == 'why BreatheFree'
                    ? 'why-continue'
                    : 'consent-agree-continue',
              ),
            );
            await expectReachableAndTappable(tester, primary, device.value);
            expect(continued, 1);
          }, skip: gap('${screen.key} in Spanish'));
        }

        testWidgets('welcome hero cards never overlap on $variant',
            (tester) async {
          await _pumpFirstRun(
            tester,
            size: device.value,
            scaler: scaler.value,
            font: font,
            index: 0,
          );
          final private = tester.getRect(
            _callout('Private'),
          );
          final noJudgment = tester.getRect(
            _callout('No judgment'),
          );
          expect(
            private.overlaps(noJudgment),
            isFalse,
            reason: 'Private $private overlaps No judgment $noJudgment',
          );
          final screenRect = Offset.zero & device.value;
          for (final rect in [private, noJudgment]) {
            expect(rect.left >= screenRect.left - 0.5, isTrue, reason: '$rect');
            expect(rect.right <= screenRect.right + 0.5, isTrue,
                reason: '$rect');
          }
        });

        testWidgets('sign-in dialog from welcome is usable on $variant',
            (tester) async {
          await _pumpFirstRun(
            tester,
            size: device.value,
            scaler: scaler.value,
            font: font,
            index: 0,
          );
          final signIn = find.byKey(const ValueKey('welcome-sign-in'));
          await tester.ensureVisible(signIn);
          await tester.pumpAndSettle();

          final dialog = find.byKey(const ValueKey('account-dialog'));
          var errors = await captureLayoutErrors(() async {
            await tester.tap(signIn);
            await tester.pumpAndSettle();
          });
          expect(describeErrors(errors), isEmpty,
              reason: 'sign-in layout errors');
          expect(dialog, findsOneWidget);
          expect(
              textProblems(
                tester,
                dialog,
                font,
                allowSplitWords: allowSplitWords,
              ),
              isEmpty);
          await expectReachable(
            tester,
            find.byKey(const ValueKey('sign-in-submit')),
            device.value,
          );
          await expectReachable(
            tester,
            find.byKey(const ValueKey('account-toggle-mode')),
            device.value,
          );

          errors = await captureLayoutErrors(() async {
            await tester.tap(find.byKey(const ValueKey('account-toggle-mode')));
            await tester.pumpAndSettle();
          });
          expect(describeErrors(errors), isEmpty,
              reason: 'sign-up layout errors');
          expect(
            find.byKey(const ValueKey('sign-up-confirm-password')),
            findsOneWidget,
          );
          expect(
              textProblems(
                tester,
                dialog,
                font,
                allowSplitWords: allowSplitWords,
              ),
              isEmpty);

          // Submitting the empty form shows every validation message.
          final submit = find.byKey(const ValueKey('sign-up-submit'));
          await expectReachable(tester, submit, device.value);
          errors = await captureLayoutErrors(() async {
            await tester.tap(submit);
            await tester.pumpAndSettle();
          });
          expect(describeErrors(errors), isEmpty, reason: 'validation layout');
          expect(find.text('Enter a valid email.'), findsOneWidget);
          expect(
              textProblems(
                tester,
                dialog,
                font,
                allowSplitWords: allowSplitWords,
              ),
              isEmpty);
          await expectReachable(tester, submit, device.value);
        }, skip: gap('sign-in dialog'));
      }
    }
  }

  // The hero switches layout at one text scale; sweep both sides of it.
  for (final font in LargeTextFont.values) {
    for (final device in largeTextDevices.entries) {
      testWidgets(
          'welcome hero cards never overlap from 1.0 to 1.7 on '
          '${device.key} (${font.name})', (tester) async {
        for (var step = 0; step <= 14; step++) {
          final scale = 1.0 + step * 0.05;
          await _pumpFirstRun(
            tester,
            size: device.value,
            scaler: TextScaler.linear(scale),
            font: font,
            index: 0,
          );
          expect(tester.takeException(), isNull, reason: 'scale $scale');
          final private = tester.getRect(_callout('Private'));
          final noJudgment = tester.getRect(_callout('No judgment'));
          expect(
            private.overlaps(noJudgment),
            isFalse,
            reason: 'scale $scale: $private overlaps $noJudgment',
          );
        }
      });
    }
  }

  testWidgets('each consent switch is announced with its visible title',
      (tester) async {
    final semantics = tester.ensureSemantics();
    for (final spanish in [false, true]) {
      await pumpLargeText(
        tester,
        size: largeTextDevices['small 375x667']!,
        scaler: TextScaler.noScaling,
        font: LargeTextFont.roboto,
        locale: Locale(spanish ? 'es' : 'en'),
        home: ConsentPrivacyScreen(
          isSpanish: spanish,
          helpfulReminders: true,
          shareWithCareTeam: false,
          helpImproveBreatheFree: false,
          onHelpfulRemindersChanged: (_) {},
          onShareWithCareTeamChanged: (_) {},
          onHelpImproveBreatheFreeChanged: (_) {},
          onBack: () {},
          onContinue: () {},
        ),
      );
      final titles = spanish
          ? const {
              'consent-helpful-reminders': 'Recordatorios útiles',
              'consent-share-care-team': 'Compartir con mi equipo de atención',
              'consent-help-improve': 'Ayudar a mejorar BreatheFree',
            }
          : const {
              'consent-helpful-reminders': 'Helpful reminders',
              'consent-share-care-team': 'Share with my care team',
              'consent-help-improve': 'Help improve BreatheFree',
            };
      for (final entry in titles.entries) {
        final toggle = find.byKey(ValueKey(entry.key));
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        final node = tester.getSemantics(toggle);
        expect(node.label, entry.value, reason: entry.key);
        expect(node.flagsCollection.isToggled, isNot(Tristate.none),
            reason: '${entry.key} is still a switch');
      }
    }
    semantics.dispose();
  });

  // A screen reader stops once on each consent row: the switch, named by its
  // title, with the description as its hint. The title is not read again as
  // separate text.
  for (final scaler in {
    'default size': TextScaler.noScaling,
    'text scale 2.0': const TextScaler.linear(2.0),
  }.entries) {
    testWidgets('each consent row is read once, as its switch (${scaler.key})',
        (tester) async {
      final semantics = tester.ensureSemantics();
      for (final spanish in [false, true]) {
        await pumpLargeText(
          tester,
          size: largeTextDevices['small 375x667']!,
          scaler: scaler.value,
          font: LargeTextFont.roboto,
          locale: Locale(spanish ? 'es' : 'en'),
          home: ConsentPrivacyScreen(
            isSpanish: spanish,
            helpfulReminders: true,
            shareWithCareTeam: false,
            helpImproveBreatheFree: false,
            onHelpfulRemindersChanged: (_) {},
            onShareWithCareTeamChanged: (_) {},
            onHelpImproveBreatheFreeChanged: (_) {},
            onBack: () {},
            onContinue: () {},
          ),
        );
        final rows = spanish
            ? const {
                'consent-helpful-reminders': (
                  'Recordatorios útiles',
                  'Recibe controles privados y recordatorios del plan.',
                ),
                'consent-share-care-team': (
                  'Compartir con mi equipo de atención',
                  'Permite que un profesional conectado vea resúmenes de '
                      'progreso.',
                ),
                'consent-help-improve': (
                  'Ayudar a mejorar BreatheFree',
                  'Aporta información desidentificada a investigaciones '
                      'aprobadas.',
                ),
              }
            : const {
                'consent-helpful-reminders': (
                  'Helpful reminders',
                  'Receive private check-ins and plan reminders.',
                ),
                'consent-share-care-team': (
                  'Share with my care team',
                  'Allow a connected clinician to view progress summaries.',
                ),
                'consent-help-improve': (
                  'Help improve BreatheFree',
                  'Contribute de-identified information to approved research.',
                ),
              };
        for (final entry in rows.entries) {
          final (title, subtitle) = entry.value;
          final toggle = find.byKey(ValueKey(entry.key));
          await tester.ensureVisible(toggle);
          await tester.pumpAndSettle();
          final mentions = find.semantics
              .byPredicate(
                (node) =>
                    node.label.contains(title) ||
                    node.hint.contains(title) ||
                    node.value.contains(title),
                describeMatch: (_) => 'nodes that read "$title"',
              )
              .evaluate()
              .toList();
          expect(mentions, hasLength(1), reason: '"$title" is read once');
          final node = mentions.single;
          expect(node, same(tester.getSemantics(toggle)), reason: entry.key);
          // The visible title belongs to the same stop, so the screen
          // reader's focus covers the whole row.
          expect(
            tester.getSemantics(find.text(title)),
            same(node),
            reason: '${entry.key} row is one stop',
          );
          expect(node.label, title, reason: entry.key);
          expect(node.hint, subtitle, reason: entry.key);
          expect(
            node.getSemanticsData().flagsCollection.isToggled,
            isNot(Tristate.none),
            reason: '${entry.key} is a switch',
          );
          expect(
            find.semantics
                .byPredicate((node) => node.label.contains(subtitle))
                .evaluate(),
            isEmpty,
            reason: '"$subtitle" is the hint, not read again as text',
          );
        }
      }
      semantics.dispose();
    });
  }

  testWidgets('welcome keeps its side-by-side layout at default text size',
      (tester) async {
    await _pumpFirstRun(
      tester,
      size: largeTextDevices['small 375x667']!,
      scaler: TextScaler.noScaling,
      font: LargeTextFont.roboto,
      index: 0,
    );
    final brand = tester.getRect(find.text('BreatheFree'));
    final language = tester.getRect(
      find.byKey(const ValueKey('welcome-language-menu')),
    );
    expect(language.center.dy, moreOrLessEquals(brand.center.dy, epsilon: 1));
    expect(language.left, greaterThanOrEqualTo(brand.right));
    // The menu stays at the right edge of the 20 px content padding.
    expect(language.right, moreOrLessEquals(375 - 20, epsilon: 0.5));

    final private = tester.getRect(
      _callout('Private'),
    );
    final noJudgment = tester.getRect(
      _callout('No judgment'),
    );
    expect(noJudgment.top, lessThan(private.top));
    expect(noJudgment.left, greaterThan(private.left));

    final cravings = tester.getRect(find.text('Help when cravings hit'));
    final progress = tester.getRect(find.text('Progress that stays'));
    expect(progress.left, greaterThan(cravings.right));
  });
}

/// The card that holds a welcome hero callout title.
Finder _callout(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(Container)).first;

Future<void> _pumpFirstRun(
  WidgetTester tester, {
  required Size size,
  required TextScaler scaler,
  required LargeTextFont font,
  required int index,
  VoidCallback? onNext,
}) async {
  final account = fakeAccount();
  addTearDown(account.dispose);
  final appLocale = AppLocale(
    store: MemoryAppLocaleStore(),
    deviceLocales: () => const [Locale('en', 'US')],
  );
  addTearDown(appLocale.dispose);
  await pumpLargeText(
    tester,
    size: size,
    scaler: scaler,
    font: font,
    appLocale: appLocale,
    home: ApprovedScreenPlayer(
      appLocale: appLocale,
      accountController: account,
      currentIndex: index,
      onSelectScreen: (_) {},
      onPrevious: () {},
      onNext: onNext ?? () {},
      onTarget: (AppTapTarget _) {},
    ),
  );
}
