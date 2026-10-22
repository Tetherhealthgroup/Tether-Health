import 'dart:io';

import 'package:breathefree_patient/models/tap_target.dart';
import 'package:breathefree_patient/screens/approved_screen_player.dart';
import 'package:breathefree_patient/screens/consent_privacy_screen.dart';
import 'package:breathefree_patient/screens/why_breathefree_screen.dart';
import 'package:breathefree_patient/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/fakes.dart';

/// The first-run screens a new user sees before signing in must stay usable
/// at the largest system text sizes: no layout overflow, no overlapping
/// cards, no text clipped or cut to an ellipsis, and the primary action
/// reachable by scrolling.
///
/// 1.35 is Android's largest font size; 3.1 is roughly what Flutter receives
/// for iOS Accessibility Extra Extra Extra Large.
///
/// Every case runs twice: with Roboto loaded from the Flutter SDK, so text
/// measures like a real phone, and with the square-glyph test font, which is
/// wider than any real font and so stress-tests the layout for overflow,
/// overlap and reachability. Clipped, cut-off or split text is judged with
/// the real font only.
const _scales = <double>[1.0, 1.35, 2.0, 3.1];

const _devices = <String, Size>{
  'small 375x667': Size(375, 667),
  'large 430x932': Size(430, 932),
};

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

enum _Font { roboto, wideTestGlyphs }

void main() {
  setUpAll(_loadRoboto);

  for (final font in _Font.values) {
    for (final device in _devices.entries) {
      for (final scale in _scales) {
        final variant = '${device.key} at text scale $scale (${font.name})';

        for (final screen in _screens) {
          testWidgets('${screen.name} is usable on $variant', (tester) async {
            var nextTaps = 0;
            final errors = await _captureLayoutErrors(() async {
              await _pumpFirstRun(
                tester,
                size: device.value,
                scale: scale,
                font: font,
                index: screen.index,
                onNext: () => nextTaps++,
              );
            });
            expect(_describe(errors), isEmpty, reason: 'layout errors');

            final root = find.byKey(ValueKey(screen.rootKey));
            expect(root, findsOneWidget);
            expect(_textProblems(tester, root, font), isEmpty);

            await _expectReachableAndTappable(
              tester,
              find.byKey(ValueKey(screen.primaryKey)),
              device.value,
            );
            expect(nextTaps, 1, reason: 'primary action reached the flow');
          });
        }

        testWidgets('welcome in Spanish is usable on $variant', (tester) async {
          await _pumpFirstRun(
            tester,
            size: device.value,
            scale: scale,
            font: font,
            index: 0,
          );
          final spanish = find.byKey(const ValueKey('welcome-spanish'));
          await tester.ensureVisible(spanish);
          await tester.pumpAndSettle();
          final errors = await _captureLayoutErrors(() async {
            await tester.tap(spanish);
            await tester.pumpAndSettle();
          });
          expect(_describe(errors), isEmpty, reason: 'layout errors');
          expect(find.text('Comenzar'), findsOneWidget);
          expect(
            _textProblems(
              tester,
              find.byKey(const ValueKey('functional-welcome-screen')),
              font,
            ),
            isEmpty,
          );
        });

        for (final screen in _spanishScreens.entries) {
          testWidgets('${screen.key} in Spanish is usable on $variant',
              (tester) async {
            var continued = 0;
            final errors = await _captureLayoutErrors(() async {
              await _pumpScreen(
                tester,
                size: device.value,
                scale: scale,
                font: font,
                home: screen.value(() => continued++),
              );
            });
            expect(_describe(errors), isEmpty, reason: 'layout errors');
            final root = find.byType(Scaffold).first;
            expect(_textProblems(tester, root, font), isEmpty);
            final primary = find.byKey(
              ValueKey(
                screen.key == 'why BreatheFree'
                    ? 'why-continue'
                    : 'consent-agree-continue',
              ),
            );
            await _expectReachableAndTappable(tester, primary, device.value);
            expect(continued, 1);
          });
        }

        testWidgets('welcome hero cards never overlap on $variant',
            (tester) async {
          await _pumpFirstRun(
            tester,
            size: device.value,
            scale: scale,
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
            scale: scale,
            font: font,
            index: 0,
          );
          final signIn = find.byKey(const ValueKey('welcome-sign-in'));
          await tester.ensureVisible(signIn);
          await tester.pumpAndSettle();

          final dialog = find.byKey(const ValueKey('account-dialog'));
          var errors = await _captureLayoutErrors(() async {
            await tester.tap(signIn);
            await tester.pumpAndSettle();
          });
          expect(_describe(errors), isEmpty, reason: 'sign-in layout errors');
          expect(dialog, findsOneWidget);
          expect(_textProblems(tester, dialog, font), isEmpty);
          await _expectReachable(
            tester,
            find.byKey(const ValueKey('sign-in-submit')),
            device.value,
          );
          await _expectReachable(
            tester,
            find.byKey(const ValueKey('account-toggle-mode')),
            device.value,
          );

          errors = await _captureLayoutErrors(() async {
            await tester.tap(find.byKey(const ValueKey('account-toggle-mode')));
            await tester.pumpAndSettle();
          });
          expect(_describe(errors), isEmpty, reason: 'sign-up layout errors');
          expect(
            find.byKey(const ValueKey('sign-up-confirm-password')),
            findsOneWidget,
          );
          expect(_textProblems(tester, dialog, font), isEmpty);

          // Submitting the empty form shows every validation message.
          final submit = find.byKey(const ValueKey('sign-up-submit'));
          await _expectReachable(tester, submit, device.value);
          errors = await _captureLayoutErrors(() async {
            await tester.tap(submit);
            await tester.pumpAndSettle();
          });
          expect(_describe(errors), isEmpty, reason: 'validation layout');
          expect(find.text('Enter a valid email.'), findsOneWidget);
          expect(_textProblems(tester, dialog, font), isEmpty);
          await _expectReachable(tester, submit, device.value);
        });
      }
    }
  }

  // The hero switches layout at one text scale; sweep both sides of it.
  for (final font in _Font.values) {
    for (final device in _devices.entries) {
      testWidgets(
          'welcome hero cards never overlap from 1.0 to 1.7 on '
          '${device.key} (${font.name})', (tester) async {
        for (var step = 0; step <= 14; step++) {
          final scale = 1.0 + step * 0.05;
          await _pumpFirstRun(
            tester,
            size: device.value,
            scale: scale,
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

  testWidgets('welcome keeps its side-by-side layout at default text size',
      (tester) async {
    await _pumpFirstRun(
      tester,
      size: _devices['small 375x667']!,
      scale: 1.0,
      font: _Font.roboto,
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

ThemeData _theme(_Font font) {
  final theme = AppTheme.light();
  if (font == _Font.roboto) return theme;
  // Any family that is not loaded falls back to the square-glyph test font.
  const family = 'FlutterTest';
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: family),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: family),
  );
}

/// Loads the Roboto files that ship in every Flutter SDK, so text measures as
/// it does on Android instead of with the square-glyph test font.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
  final loader = FontLoader('Roboto');
  for (final weight in ['Light', 'Regular', 'Medium', 'Bold', 'Black']) {
    final file = File('${fonts.path}/Roboto-$weight.ttf');
    expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// The card that holds a welcome hero callout title.
Finder _callout(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(Container)).first;

Future<void> _pumpFirstRun(
  WidgetTester tester, {
  required Size size,
  required double scale,
  required _Font font,
  required int index,
  VoidCallback? onNext,
}) async {
  final account = fakeAccount();
  addTearDown(account.dispose);
  await _pumpScreen(
    tester,
    size: size,
    scale: scale,
    font: font,
    home: ApprovedScreenPlayer(
      accountController: account,
      currentIndex: index,
      onSelectScreen: (_) {},
      onPrevious: () {},
      onNext: onNext ?? () {},
      onTarget: (AppTapTarget _) {},
    ),
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Size size,
  required double scale,
  required _Font font,
  required Widget home,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: _theme(font),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

/// Records every FlutterError (RenderFlex overflow, unbounded constraints,
/// and so on) reported while [body] runs, instead of only the first.
Future<List<FlutterErrorDetails>> _captureLayoutErrors(
  Future<void> Function() body,
) async {
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

/// One line per error: the message and, when Flutter names it, the widget
/// that caused it.
List<String> _describe(List<FlutterErrorDetails> errors) => [
      for (final error in errors)
        [
          error.exceptionAsString().split('\n').first,
          ...error
              .toString()
              .split('\n')
              .skipWhile(
                (line) => !line.contains('relevant error-causing widget'),
              )
              .skip(1)
              .take(1)
              .map((line) => line.trim()),
        ].join(' | '),
    ];

/// Text that runs outside [scope], is cut to an ellipsis, is clipped by a box
/// shorter than its lines, or is so narrow that a word splits across lines.
List<String> _textProblems(WidgetTester tester, Finder scope, _Font font) {
  final problems = <String>[];
  if (font != _Font.roboto) return problems;
  final bounds = tester.getRect(scope);
  final paragraphs = find.descendant(
    of: scope,
    matching: find.byType(RichText),
  );
  for (final element in paragraphs.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    if (!paragraph.attached || !paragraph.hasSize) continue;
    final text = paragraph.text.toPlainText().trim();
    if (text.isEmpty) continue;
    final size = paragraph.size;
    final rect = MatrixUtils.transformRect(
      paragraph.getTransformTo(null),
      Offset.zero & size,
    );
    if (rect.left < bounds.left - 1 || rect.right > bounds.right + 1) {
      problems.add('"$text" at $rect runs outside $bounds');
    }
    if (paragraph.didExceedMaxLines) {
      problems.add('"$text" is cut off at its line limit');
    }
    final neededHeight = paragraph.getMaxIntrinsicHeight(size.width);
    if (neededHeight > size.height + 1) {
      problems.add(
        '"$text" needs ${neededHeight.toStringAsFixed(1)} px of height '
        'but has ${size.height.toStringAsFixed(1)}',
      );
    }
    final longestWord = paragraph.getMinIntrinsicWidth(double.infinity);
    if (longestWord > size.width + 1) {
      problems.add(
        '"$text" splits a word: needs ${longestWord.toStringAsFixed(1)} px '
        'but has ${size.width.toStringAsFixed(1)}',
      );
    }
  }
  return problems;
}

Future<void> _expectReachable(
  WidgetTester tester,
  Finder target,
  Size screen,
) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  final rect = tester.getRect(target);
  final viewport = Offset.zero & screen;
  expect(
    viewport.contains(rect.center),
    isTrue,
    reason: '$target at $rect is outside the $screen screen',
  );
  expect(rect.height, greaterThanOrEqualTo(40), reason: 'tap target height');
}

Future<void> _expectReachableAndTappable(
  WidgetTester tester,
  Finder target,
  Size screen,
) async {
  await _expectReachable(tester, target, screen);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
