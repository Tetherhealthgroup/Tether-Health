import 'package:flutter/widgets.dart';

// Layout helpers for the largest system text sizes. iOS's accessibility
// sizes reach roughly 310%. Android 13 and older top out at 130%; Android 14
// and newer go up to 200%, scaled non-linearly.

/// Whether the text is above 140% (the iOS accessibility sizes and Android
/// 14's largest font sizes), where side-by-side pieces are stacked so text
/// can grow.
bool usesLargeTextLayout(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) > 14;

/// The text scale for [text] in [style], lowered only as far as needed for
/// its longest word to fit [width]: a word too long for a whole line scales
/// down instead of splitting. With [maxScaleFactor], the text never grows
/// past that factor either.
TextScaler wordFitScaler(
  BuildContext context,
  String text,
  TextStyle style,
  double width, {
  double? maxScaleFactor,
}) {
  final systemScaler = MediaQuery.textScalerOf(context);
  final scaler = maxScaleFactor == null
      ? systemScaler
      : systemScaler.clamp(maxScaleFactor: maxScaleFactor);
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
  );
  try {
    var fitted = scaler;
    for (var attempt = 0; attempt < 4; attempt++) {
      painter
        ..textScaler = fitted
        ..layout();
      final longestWord = painter.minIntrinsicWidth;
      if (longestWord <= width) return fitted;
      final fontSize = style.fontSize ?? 14;
      final factor = fitted.scale(fontSize) / fontSize * width / longestWord;
      fitted = scaler.clamp(maxScaleFactor: factor * 0.99);
    }
    return fitted;
  } finally {
    painter.dispose();
  }
}

/// Whether the longest word of every label, drawn in [style], fits [width]
/// at the current text size.
bool wordsFit(
  BuildContext context,
  Iterable<String> labels,
  double width,
  TextStyle style,
) {
  final painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  );
  try {
    final merged = DefaultTextStyle.of(context).style.merge(style);
    for (final label in labels) {
      painter
        ..text = TextSpan(text: label, style: merged)
        ..layout();
      if (painter.minIntrinsicWidth > width) return false;
    }
    return true;
  } finally {
    painter.dispose();
  }
}
