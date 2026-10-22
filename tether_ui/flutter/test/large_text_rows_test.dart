// Rows with a badge, value, tag or action beside a text (radio option
// badges, list row values and pills, chart titles with a program tag,
// slider values, banner actions). At the default text size they keep the
// designed row; with larger text, when the item beside no longer leaves room
// for the text's longest word, it moves below the text instead of
// overflowing. Left-to-right and right-to-left, with linear text scaling
// and with Android 14's non-linear 200%. Text is measured with Roboto from
// the Flutter SDK, as on a phone (see footer_text_scale_test.dart).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  expect(root, isNotNull, reason: 'FLUTTER_ROOT is not set; run with flutter test');
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    final file = File('$root/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
    expect(file.existsSync(), isTrue, reason: '${file.path} is missing (flutter precache)');
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer)));
  }
  await loader.load();
}

/// Android 14's 200% font size: small text grows more than large text and
/// 100 px text not at all. The 2.0 table of
/// `android.content.res.FontScaleConverterFactory` (API 35), interpolated
/// linearly between its points as Android does.
final class _AndroidNonLinear200 extends TextScaler {
  const _AndroidNonLinear200();

  static const _fromSp = <double>[8, 10, 12, 14, 18, 20, 24, 30, 100];
  static const _toDp = <double>[16, 20, 24, 26, 30, 34, 36, 38, 100];

  @override
  double get textScaleFactor => 2.0;

  @override
  double scale(double fontSize) {
    if (fontSize >= _fromSp.last) return fontSize * _toDp.last / _fromSp.last;
    var startSp = 0.0, startDp = 0.0;
    for (var i = 0; i < _fromSp.length; i++) {
      if (fontSize <= _fromSp[i]) return startDp + (_toDp[i] - startDp) * (fontSize - startSp) / (_fromSp[i] - startSp);
      startSp = _fromSp[i];
      startDp = _toDp[i];
    }
    return fontSize;
  }
}

Future<void> _pump(WidgetTester tester, Widget child, {double scale = 1.0, TextScaler? scaler, double width = 375, TextDirection direction = TextDirection.ltr}) async {
  tester.view.physicalSize = Size(width, 667) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: scaler ?? TextScaler.linear(scale)), child: Directionality(textDirection: direction, child: child!)),
    home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child)),
  ));
  expect(tester.takeException(), isNull, reason: 'layout error');
}

Rect _text(WidgetTester tester, String text) => tester.getRect(find.text(text));

/// Whether [b] sits beside [a] (their vertical extents overlap) rather than
/// below it.
bool _beside(Rect a, Rect b) => b.top < a.bottom && a.top < b.bottom;

void main() {
  setUpAll(_loadRoboto);
  final radio = TRadioList(items: const [TRadioItem('Move for three minutes', sub: 'Walk or stretch', badge: 'Helped before'), TRadioItem('Urge surfing')]);

  for (final direction in TextDirection.values) {
    group(direction.name, () {
      bool ltr(Rect label, Rect badge) => direction == TextDirection.ltr ? badge.left >= label.right : badge.right <= label.left;

      testWidgets('a radio badge stays beside the label at 100% and moves below it at 310%', (tester) async {
        await _pump(tester, radio, direction: direction);
        var label = _text(tester, 'Move for three minutes'), badge = _text(tester, 'HELPED BEFORE');
        expect(_beside(label, badge), isTrue, reason: '100%: $label $badge');
        expect(ltr(label, badge), isTrue, reason: '100%: the badge is at the end');
        // Centred across the label and sub text, as in a Row.
        final textMiddle = (label.top + _text(tester, 'Walk or stretch').bottom) / 2;
        expect(badge.center.dy, moreOrLessEquals(textMiddle, epsilon: 0.5), reason: '100%: the badge is centred on the text');

        await _pump(tester, radio, scale: 3.1, direction: direction);
        label = _text(tester, 'Move for three minutes');
        badge = _text(tester, 'HELPED BEFORE');
        final sub = _text(tester, 'Walk or stretch');
        expect(badge.top, greaterThanOrEqualTo(sub.bottom), reason: '310%: below the label and sub text');
        final start = direction == TextDirection.ltr ? (Rect r) => r.left : (Rect r) => r.right;
        expect(start(badge), moreOrLessEquals(start(label), epsilon: 12), reason: '310%: the badge starts where the label starts');
        // The whole option is still one tap target and one announcement.
        await tester.tap(find.text('HELPED BEFORE'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('a list row value and a chart title tag stay in their row at 100% and wrap at 310%', (tester) async {
        final page = Column(children: [
          TListRow(label: 'Daily reminder', sub: 'Every morning', value: '8:00 AM', onTap: () {}),
          TBarChart(values: const [3, 4, 2], color: TColors.teal, title: 'Rescues used', unit: 'per week', tag: 'bf'),
          const TBanner(kind: TBannerKind.offline, text: 'You are offline', actionLabel: 'Try again'),
        ]);
        await _pump(tester, page, direction: direction);
        expect(_beside(_text(tester, 'Daily reminder'), _text(tester, '8:00 AM')), isTrue);
        expect(_beside(_text(tester, 'Rescues used'), _text(tester, 'BREATHEFREE')), isTrue);
        expect(_beside(_text(tester, 'You are offline'), _text(tester, 'Try again')), isTrue);
        // A banner's action is aligned with the top of its message.
        expect(tester.getRect(find.byType(TextButton)).top, moreOrLessEquals(_text(tester, 'You are offline').top, epsilon: 0.5), reason: 'banner action at the top');

        await _pump(tester, page, scale: 3.1, direction: direction);
        expect(_text(tester, '8:00 AM').top, greaterThanOrEqualTo(_text(tester, 'Every morning').bottom), reason: 'value below the label');
        expect(_text(tester, 'BREATHEFREE').bottom, lessThanOrEqualTo(_text(tester, 'Rescues used').top), reason: 'tag above the title');
        expect(_text(tester, 'Try again').top, greaterThanOrEqualTo(_text(tester, 'You are offline').bottom), reason: 'action below the message');
      });
    });
  }

  testWidgets('at 100% a badge moves below only when the row would overflow', (tester) async {
    // A row too narrow for the badge even at the default size.
    await _pump(tester, SizedBox(width: 150, child: radio));
    expect(_text(tester, 'HELPED BEFORE').top, greaterThanOrEqualTo(_text(tester, 'Walk or stretch').bottom));
    // At 100% a badge that fits stays beside a label whose longest word no
    // longer does (the designed row), and moves below at 130%.
    const word = TRadioList(items: [TRadioItem('Notifications', badge: 'Recommended')]);
    await _pump(tester, const SizedBox(width: 205, child: word));
    final label = _text(tester, 'Notifications');
    expect(_beside(label, _text(tester, 'RECOMMENDED')), isTrue, reason: '100%: the designed row');
    await _pump(tester, const SizedBox(width: 205, child: word), scale: 1.3);
    expect(_beside(_text(tester, 'Notifications'), _text(tester, 'RECOMMENDED')), isFalse, reason: '130%: below');
  });

  testWidgets("Android 14's non-linear 200% counts as large text", (tester) async {
    // 100 px text is not enlarged, body text is: the badge must move below
    // the label rather than squeeze it into a sliver that breaks the word.
    const scaler = _AndroidNonLinear200();
    expect(scaler.scale(100), 100);
    expect(scaler.scale(14), 26);
    const word = TRadioList(items: [TRadioItem('Notifications', badge: 'Recommended')]);
    await _pump(tester, word, scaler: scaler, width: 320);
    final label = _text(tester, 'Notifications');
    expect(_text(tester, 'RECOMMENDED').top, greaterThanOrEqualTo(label.bottom), reason: 'badge below the label');
    final line = TextPainter(text: TextSpan(text: 'Notifications', style: TText.optionLabel.copyWith(fontFamily: 'Roboto')), textScaler: scaler, textDirection: TextDirection.ltr)..layout();
    expect(label.height, moreOrLessEquals(line.height, epsilon: 0.5), reason: 'the label stays on one line');
    expect(label.width, greaterThanOrEqualTo(line.width - 0.5), reason: 'the label is not broken inside the word');
    line.dispose();
  });

  testWidgets('slider end labels share a row while they fit and wrap when they do not', (tester) async {
    final slider = TSliderField(fieldKey: 'test.slider', label: 'Daily limit', value: 3, minLabel: 'No limit at all', maxLabel: 'Every single hour');
    await _pump(tester, slider, width: 320);
    var start = _text(tester, 'No limit at all'), end = _text(tester, 'Every single hour');
    expect(end.top, moreOrLessEquals(start.top), reason: '100%: one row');
    expect(end.right, moreOrLessEquals(300, epsilon: 0.5), reason: '100%: the end label at the end');
    expect(start.left, moreOrLessEquals(20, epsilon: 0.5), reason: '100%: the start label at the start');
    await _pump(tester, slider, scale: 3.1, width: 320);
    start = _text(tester, 'No limit at all');
    end = _text(tester, 'Every single hour');
    expect(end.top, greaterThanOrEqualTo(start.bottom), reason: '310%: the end label on its own line');
    expect(end.right, lessThanOrEqualTo(300.5), reason: '310%: inside the row');
  });

  testWidgets('intrinsic and dry sizes match the layout in both arrangements', (tester) async {
    for (final scale in [1.0, 3.1]) {
      await _pump(tester, radio, scale: scale);
      final boxes = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Beside').evaluate().map((e) => e.renderObject! as RenderBox).toList();
      expect(boxes, isNotEmpty);
      for (final box in boxes) {
        final width = box.size.width;
        expect(box.getMinIntrinsicHeight(width), moreOrLessEquals(box.size.height, epsilon: 0.01), reason: '$scale');
        expect(box.getMaxIntrinsicHeight(width), moreOrLessEquals(box.size.height, epsilon: 0.01), reason: '$scale');
        expect(box.getDryLayout(box.constraints), box.size, reason: '$scale');
        expect(box.getMinIntrinsicWidth(double.infinity), lessThanOrEqualTo(width + 0.01));
      }
    }
  });
}
