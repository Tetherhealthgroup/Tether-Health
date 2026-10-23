// Kit details that follow the prototype's CSS (render_html.py), checked by
// geometry and style rather than by pixels: small buttons are as wide as
// their text, key-value rows sit at the two edges, a left link is at the
// start, toggles in a card are divided, stat tags are grey, the timer has
// the prototype's line height, banners have a filled badge, and the tab bar
// draws the prototype's line icons. Tests draw text in the square test font,
// so the strings are short and the checks are relative.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

Future<void> _show(WidgetTester tester, Widget child, {double width = 390, double scale = 1}) async {
  tester.view.physicalSize = Size(width * 3, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
    home: Scaffold(body: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [child])))),
  ));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  tearDown(() => TData.instance = PreviewData());

  group('small buttons', () {
    testWidgets('a small button in a row is as wide as its text', (tester) async {
      await _show(tester, Row(children: [TButton(label: 'Go', small: true, onPressed: () {})]));
      expect(tester.getSize(find.byType(TButton)).width, closeTo(2 * 14 + 28, 3), reason: 'text and 14 pt padding each side');
      expect(tester.getTopLeft(find.byType(TButton)).dx, 20);
      expect(tester.getSize(find.byType(TButton)).height, 40);
    });

    testWidgets('a big button still fills the width', (tester) async {
      await _show(tester, Column(children: [TButton(label: 'Continue', onPressed: () {})]));
      expect(tester.getSize(find.byType(TButton)).width, 350);
    });

    testWidgets('a card call to action is not stretched and leaves the text the rest of the row', (tester) async {
      await _show(tester, TCard(title: 'Hello there', text: 'Ok', cta: TButton(label: 'Go', small: true, onPressed: () {})));
      final button = tester.getRect(find.byType(TButton));
      final title = tester.getRect(find.text('Hello there'));
      expect(button.width, closeTo(2 * 14 + 28, 3));
      expect(button.right, closeTo(390 - 20 - 16 - 1, 0.5), reason: 'at the card edge');
      expect(title.right, lessThanOrEqualTo(button.left));
      expect(title.height, lessThan(24), reason: 'the title (11 characters, 176 pt of 248) stays on one line: the row is not split half and half');
    });

    testWidgets('a card call to action gives way at very large text instead of overflowing', (tester) async {
      await _show(tester, TCard(title: 'Craving or urge to scroll?', text: 'Help for the next few minutes', cta: TButton(label: 'Start the check-in', small: true, onPressed: () {})), width: 320, scale: 3.1);
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byType(TButton)).width, lessThanOrEqualTo((320 - 40 - 34) * 0.6 + 0.5));
    });

    testWidgets('two small buttons in a row sit side by side at their own widths', (tester) async {
      await _show(tester, TButtonRow(children: [TButton(label: 'Go', small: true, onPressed: () {}), TButton(label: 'Stop now', small: true, onPressed: () {})]));
      final a = tester.getRect(find.widgetWithText(TButton, 'Go')), b = tester.getRect(find.widgetWithText(TButton, 'Stop now'));
      expect(a.top, b.top);
      expect(b.left, a.right + 8);
      expect(a.width, closeTo(56, 3));
      expect(b.width, closeTo(8 * 14 + 28, 3));
    });
  });

  group('key-value rows', () {
    testWidgets('the label is at the start and the value at the end, each as wide as its text', (tester) async {
      await _show(tester, const TKeyValue(rows: [('Sync', 'Today')]));
      final card = tester.getRect(find.byType(TCard));
      final label = tester.getRect(find.text('Sync')), value = tester.getRect(find.text('Today'));
      expect(label.left, card.left + 16 + 1, reason: 'card padding and border');
      expect(value.right, closeTo(card.right - 16 - 1, 0.5));
      expect(label.width, closeTo(4 * 14, 3));
      expect(value.width, closeTo(5 * 14, 3));
    });

    testWidgets('a value that fits beside its label stays on one line', (tester) async {
      await _show(tester, const TKeyValue(rows: [('Connection', 'Epic R4')]));
      expect(tester.getSize(find.text('Epic R4')).height, lessThan(22), reason: 'one line');
    });

    testWidgets('a long pair shrinks without overflowing', (tester) async {
      await _show(tester, const TKeyValue(rows: [('A fairly long label for the row', 'A fairly long value that cannot fit beside it on one line')]), width: 320, scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  });

  group('links', () {
    testWidgets('alignLeft puts the link at the start', (tester) async {
      await _show(tester, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [TLink(label: 'Skip', alignLeft: true, onTap: () {}), TLink(label: 'Later', onTap: () {})]));
      expect(tester.getRect(find.text('Skip')).left, 24, reason: '20 margin + 4 padding');
      expect(tester.getCenter(find.text('Later')).dx, closeTo(195, 1));
    });
  });

  group('toggles', () {
    testWidgets('consecutive toggle rows in a card are divided by one line', (tester) async {
      await _show(tester, TCard(children: [TToggleRow(label: 'One', value: true, onChanged: (_) {}), TToggleRow(label: 'Two', onChanged: (_) {}), TToggleRow(label: 'Three', onChanged: (_) {})]));
      expect(find.descendant(of: find.byType(TCard), matching: find.byType(Divider)), findsNWidgets(2));
    });

    testWidgets('a single toggle has no divider, and 8 pt above and below', (tester) async {
      await _show(tester, TCard(children: [TToggleRow(label: 'One', onChanged: (_) {})]));
      expect(find.byType(Divider), findsNothing);
      final padding = tester.widget<Padding>(find.descendant(of: find.byType(TToggleRow), matching: find.byType(Padding)).first);
      expect(padding.padding, const EdgeInsets.symmetric(vertical: 8));
    });
  });

  group('stat tags', () {
    testWidgets('the tag text is grey at 12.5 pt and the square keeps the programme colour', (tester) async {
      await _show(tester, const TStatGrid(stats: [TStat(label: 'Quit day', value: '7 days', program: 'bf')]));
      final text = tester.widget<Text>(find.text('BREATHEFREE · QUIT DAY'));
      expect(text.style!.color, TColors.muted);
      expect(text.style!.fontSize, 12.5);
      final square = tester.widget<Container>(find.descendant(of: find.byType(TProgramTag), matching: find.byType(Container)).first);
      expect((square.decoration! as BoxDecoration).color, TColors.program('bf'));
    });

    testWidgets('a tag outside a stat keeps its colour and size', (tester) async {
      await _show(tester, const TProgramTag(program: 'bf', extra: 'Learn only'));
      final text = tester.widget<Text>(find.text('BREATHEFREE · LEARN ONLY'));
      expect(text.style!.color, TColors.program('bf'));
      expect(text.style!.fontSize, 11.5);
    });
  });

  group('timer', () {
    testWidgets('the value has line height 1.45 and the label a 15 pt line of 1.45', (tester) async {
      await _show(tester, const TTimer(value: '4:12', label: 'until re-check'));
      expect(tester.widget<Text>(find.text('4:12')).style!.height, 1.45);
      final h = tester.getSize(find.byType(TTimer)).height;
      expect(h, closeTo(6 + 56 * 1.45 + 15 * 1.45 + 6, 0.5));
    });
  });

  group('banners', () {
    for (final (kind, glyph) in [(TBannerKind.offline, '≈'), (TBannerKind.error, '!'), (TBannerKind.success, '✓'), (TBannerKind.info, 'i'), (TBannerKind.urgent, '!')]) {
      testWidgets('${kind.name}: a filled 20 pt circle with "$glyph"', (tester) async {
        await _show(tester, TBanner(kind: kind, text: 'Message'));
        expect(find.descendant(of: find.byType(TBanner), matching: find.byType(Icon)), findsNothing);
        final badge = find.ancestor(of: find.text(glyph), matching: find.byType(Container)).first;
        expect(tester.getSize(badge), const Size(20, 20));
        expect(((tester.widget<Container>(badge)).decoration! as BoxDecoration).shape, BoxShape.circle);
      });
    }
  });

  group('tab bar', () {
    testWidgets('draws the five line icons itself, in a 44 x 28 pill', (tester) async {
      await _show(tester, const SizedBox(height: 90, child: TTabBar(active: 'learn')));
      expect(find.descendant(of: find.byType(TTabBar), matching: find.byType(Icon)), findsNothing);
      final pills = find.descendant(of: find.byType(TTabBar), matching: find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 44 && w.constraints?.maxHeight == 28));
      expect(pills, findsNWidgets(5));
      final active = tester.widget<Container>(pills.at(3));
      expect((active.decoration! as BoxDecoration).color, TColors.mint);
    });
  });

  test('the quote falls back to a serif on devices without Georgia', () {
    expect(TText.quote.fontFamily, 'Georgia');
    expect(TText.quote.fontFamilyFallback, containsAll(['Noto Serif', 'serif']));
  });
}
