// Rows with a badge, value, tag or action beside a text (radio option
// badges, list row values and pills, chart titles with a program tag,
// slider values, banner actions). At the default text size they keep the
// designed row; with larger text, when the item beside no longer leaves room
// for the text's longest word, it moves below the text instead of
// overflowing. Left-to-right and right-to-left. Text is measured with Roboto
// from the Flutter SDK, as on a phone (see footer_text_scale_test.dart).
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

Future<void> _pump(WidgetTester tester, Widget child, {double scale = 1.0, double width = 375, TextDirection direction = TextDirection.ltr}) async {
  tester.view.physicalSize = Size(width, 667) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: Directionality(textDirection: direction, child: child!)),
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
