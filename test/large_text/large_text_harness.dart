import 'dart:io';

import 'package:breathefree_patient/l10n/app_locale.dart';
import 'package:breathefree_patient/l10n/app_localizations.dart';
import 'package:breathefree_patient/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared helpers for the large-text layout tests.
///
/// Text sizes: iOS Accessibility Extra Extra Extra Large reaches Flutter as
/// roughly 3.1. Android 13 and older top out at 1.3 (1.35 is checked). Android
/// 14 and newer go up to 200%, but scale non-linearly: small text doubles and
/// large text grows less, so [androidNonLinear200] is checked as well as the
/// linear scales.
///
/// Every case runs with Roboto loaded from the Flutter SDK, so text measures
/// like a real phone, and with the square-glyph test font, which is wider than
/// any real font and so stress-tests the layout for overflow, overlap and
/// reachability. Clipped, cut-off or split text is judged with the real font
/// only.
const largeTextScales = <double>[1.0, 1.35, 2.0, 3.1];

/// Every scaler a case runs under: the linear [largeTextScales] and Android
/// 14's non-linear 200%.
final largeTextScalers = <String, TextScaler>{
  for (final scale in largeTextScales)
    'text scale $scale': TextScaler.linear(scale),
  'Android 14 non-linear 200%': androidNonLinear200,
};

const largeTextDevices = <String, Size>{
  'narrow 320x568': Size(320, 568),
  'small 375x667': Size(375, 667),
  'large 430x932': Size(430, 932),
};

/// The smallest tap target the screens must keep (Material's 48 dp).
const minTapTarget = 48.0;

enum LargeTextFont { roboto, wideTestGlyphs }

/// Android 14's 200% font size. Flutter's test binding only scales linearly
/// (`TestPlatformDispatcher.scaleFontSize`), so the curve Android applies is
/// reproduced here: the 2.0 table of
/// `android.content.res.FontScaleConverterFactory` (API 35), interpolated as
/// `FontScaleConverterImpl` does.
const TextScaler androidNonLinear200 = _AndroidNonLinearTextScaler();

final class _AndroidNonLinearTextScaler extends TextScaler {
  const _AndroidNonLinearTextScaler();

  static const _fromSp = <double>[8, 10, 12, 14, 18, 20, 24, 30, 100];
  static const _toDp = <double>[16, 20, 24, 26, 30, 34, 36, 38, 100];

  @override
  double get textScaleFactor => 2.0;

  @override
  double scale(double fontSize) {
    if (fontSize >= _fromSp.last) return fontSize * _toDp.last / _fromSp.last;
    var startSp = 0.0;
    var startDp = 0.0;
    for (var i = 0; i < _fromSp.length; i++) {
      final endSp = _fromSp[i];
      final endDp = _toDp[i];
      if (fontSize <= endSp) {
        final t = (fontSize - startSp) / (endSp - startSp);
        return startDp + (endDp - startDp) * t;
      }
      startSp = endSp;
      startDp = endDp;
    }
    return fontSize;
  }

  @override
  String toString() => 'Android 14 non-linear 200%';
}

ThemeData largeTextTheme(LargeTextFont font) {
  final theme = AppTheme.light();
  if (font == LargeTextFont.roboto) return theme;
  // Any family that is not loaded falls back to the square-glyph test font.
  const family = 'FlutterTest';
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: family),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: family),
  );
}

/// Loads the Roboto files that ship in every Flutter SDK, so text measures as
/// it does on Android instead of with the square-glyph test font.
Future<void> loadRoboto() async {
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

Future<void> pumpLargeText(
  WidgetTester tester, {
  required Size size,
  required TextScaler scaler,
  required LargeTextFont font,
  required Widget home,
  Locale? locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: largeTextTheme(font),
      // The app's localizations, as at the app root; [locale] should match
      // the screen's language (null: the test device's, English).
      locale: locale,
      supportedLocales: releaseLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

/// Records every FlutterError (RenderFlex overflow, unbounded constraints,
/// and so on) reported while [body] runs, instead of only the first.
Future<List<FlutterErrorDetails>> captureLayoutErrors(
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
List<String> describeErrors(List<FlutterErrorDetails> errors) => [
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

/// Whether this is a 320-pt-wide phone at iOS's largest text sizes. There,
/// some single words of body text are wider than any line the layout can
/// give them, and body text is never scaled down to fit, so such a word may
/// break across lines. Everything else is still checked.
bool wordsMayBreak(Size device, TextScaler scaler) =>
    device.width < 360 && scaler.scale(10) > 25;

/// Text that runs outside [scope], is cut to an ellipsis, is clipped by a box
/// shorter than its lines, or (unless [allowSplitWords]) is so narrow that a
/// word splits across lines.
List<String> textProblems(
  WidgetTester tester,
  Finder scope,
  LargeTextFont font, {
  bool allowSplitWords = false,
}) {
  final problems = <String>[];
  if (font != LargeTextFont.roboto) return problems;
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
    if (allowSplitWords) continue;
    final longestWord = _longestWordWidth(paragraph);
    if (longestWord > size.width + 1) {
      problems.add(
        '"$text" splits a word: needs ${longestWord.toStringAsFixed(1)} px '
        'but has ${size.width.toStringAsFixed(1)}',
      );
    }
  }
  return problems;
}

/// The width of the paragraph's longest word. Text in a family the test has
/// not loaded (no family at all when a button `textStyle` replaces the
/// theme's, or a generic family such as `serif`) is drawn with the
/// square-glyph test font, while a phone draws it with a real font, so its
/// words are measured again with Roboto.
double _longestWordWidth(RenderParagraph paragraph) {
  final style = paragraph.text.style;
  if (style?.fontFamily == 'Roboto') {
    return paragraph.getMinIntrinsicWidth(double.infinity);
  }
  final painter = TextPainter(
    text: TextSpan(
      text: paragraph.text.toPlainText(),
      style: (style ?? const TextStyle()).copyWith(fontFamily: 'Roboto'),
    ),
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
  )..layout();
  final width = painter.minIntrinsicWidth;
  painter.dispose();
  return width;
}

/// Scrolls [target] into view and checks it lands on screen and is at least
/// [minHeight] tall.
Future<void> expectReachable(
  WidgetTester tester,
  Finder target,
  Size screen, {
  double minHeight = minTapTarget,
}) async {
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
  expect(
    rect.height,
    // Non-linear scaling can leave a 48 px button a rounding error short.
    greaterThanOrEqualTo(minHeight - 0.01),
    reason: 'tap target height of $target',
  );
}

Future<void> expectReachableAndTappable(
  WidgetTester tester,
  Finder target,
  Size screen,
) async {
  await expectReachable(tester, target, screen);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
