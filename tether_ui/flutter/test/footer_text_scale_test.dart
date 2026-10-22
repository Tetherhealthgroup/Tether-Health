// Large text and the footer. Every screen and state on a 375×667 phone
// (iPhone SE) at 100%, 200% and 310% text (310% is about the largest iOS
// accessibility size). For each one:
//   - no layout overflow or other exception (see _knownOverflow);
//   - every body text lies inside the scrolling body, can be scrolled into
//     view and never touches the footer; a text that would fit on screen
//     below the header is shown whole, so a pinned footer never hides part
//     of it;
//   - the footer's first action can be scrolled to and receives taps;
//   - at 100% the footer stays pinned below the body, as designed.
// Two kit tests check when TScreen and TSheet move a tall footer into the
// body and pin it again.
// Text is measured with Roboto from the Flutter SDK (on the kit's font
// fallback list) because the test font draws every glyph 1 em wide, about
// twice as wide as real text, which would wrap far more than on a phone.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/ui/ui.dart';

const _screen = Size(375, 667);

/// Screens with a component that is still too wide at 310% text, unrelated
/// to the footer and needing its own fix. Listed screens must still
/// overflow, so a fix forces this list to shrink; every other check still
/// runs on them.
const _knownOverflow = <String, String>{
  'rescue_tools': 'TRadioList option badge "Helped before"',
  'bf_path': 'TRadioList option badge "Recommended"',
  'bf_slip': 'TRadioList option badge "Recommended"',
  'sf_slip': 'TRadioList option badge "Recommended"',
  'progress': 'chart card title row with a program tag',
};

Future<void> _pump(WidgetTester tester, String route, double scale) async {
  tester.view.physicalSize = _screen * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final builder = AppRouter.screens[route]!;
  final sheet = AppRouter.sheets.contains(route);
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
    home: Builder(builder: (c) => sheet ? TSheetPreview(child: builder(c)) : builder(c)),
  ));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

Rect _rect(RenderBox box) => MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

/// The footer column of TScreen / TSheet (its GlobalKey is labelled
/// "TScreen footer" / "TSheet footer").
final _footer = find.byWidgetPredicate((w) => w.key is GlobalKey && '${w.key}'.endsWith(' footer]'));

/// The body's vertical scroll view: the outermost vertical Scrollable.
Element _bodyScrollable(WidgetTester tester) {
  final all = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).evaluate().toList();
  expect(all, isNotEmpty, reason: 'no vertical scroll view');
  return all.firstWhere((e) => e.findAncestorWidgetOfExactType<Scrollable>() == null, orElse: () => all.first);
}

/// The body scroll view's own viewport (not a nested horizontal one).
RenderAbstractViewport _viewportOf(RenderObject root) {
  if (root is RenderAbstractViewport) return root;
  RenderAbstractViewport? found;
  root.visitChildren((c) => found ??= _viewportOf(c));
  return found!;
}

bool _inside(Element e, Element? ancestor) {
  if (ancestor == null) return false;
  var found = false;
  e.visitAncestorElements((a) => !(found = identical(a, ancestor)));
  return found;
}

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

bool _footerInBody(WidgetTester tester) => find.ancestor(of: _footer, matching: find.byType(Scrollable)).evaluate().isNotEmpty;

/// A screen or sheet whose text size and keyboard height can change.
Future<(ValueNotifier<double>, ValueNotifier<double>)> _pumpKit(WidgetTester tester, Widget page, {bool sheet = false}) async {
  tester.view.physicalSize = _screen * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final scale = ValueNotifier(1.0), keyboard = ValueNotifier(0.0);
  addTearDown(scale.dispose);
  addTearDown(keyboard.dispose);
  await tester.pumpWidget(MaterialApp(
    theme: tetherTheme(),
    builder: (c, child) => ListenableBuilder(
      listenable: Listenable.merge([scale, keyboard]),
      builder: (c, _) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale.value), viewInsets: EdgeInsets.only(bottom: keyboard.value)), child: child!),
    ),
    home: sheet ? TSheetPreview(child: page) : page,
  ));
  return (scale, keyboard);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(_loadRoboto);
  final footer = [
    TButton(key: const ValueKey('a:footer[0]'), label: 'Save and continue', onPressed: () {}),
    TButton(label: 'Not now', variant: TButtonVariant.secondary, onPressed: () {}),
    TLink(label: 'Read how this works', onTap: () {}),
  ];

  testWidgets('TScreen footer moves into the body only while it is too tall to pin', (tester) async {
    final (scale, keyboard) = await _pumpKit(tester, TScreen(header: const THeader(title: 'Title'), children: const [TBody('Body text')], footer: footer));
    await _settle(tester);
    expect(_footerInBody(tester), isFalse, reason: '100%: pinned');
    scale.value = 2.0;
    await _settle(tester);
    expect(_footerInBody(tester), isFalse, reason: '200%: three footer items still fit in 40%');
    scale.value = 3.1;
    await _settle(tester);
    expect(_footerInBody(tester), isTrue, reason: '310%: too tall, scrolls with the body');
    expect(find.byKey(const ValueKey('a:footer[0]')).hitTestable(), findsOneWidget);
    // The keyboard is up: the footer stays in the body even though it fits.
    keyboard.value = 300;
    scale.value = 1.0;
    await _settle(tester);
    expect(_footerInBody(tester), isTrue, reason: 'no jump while typing');
    keyboard.value = 0;
    await _settle(tester);
    expect(_footerInBody(tester), isFalse, reason: 'pinned again once the keyboard is down');
    // Opening the keyboard at 100% never moves a footer that fits.
    keyboard.value = 300;
    await _settle(tester);
    expect(_footerInBody(tester), isFalse, reason: 'keyboard alone does not unpin');
  });

  testWidgets('TSheet footer moves into the body only while it is too tall to pin', (tester) async {
    final (scale, _) = await _pumpKit(tester, TSheet(children: const [TBody('Body text')], footer: footer), sheet: true);
    await _settle(tester);
    expect(_footerInBody(tester), isFalse, reason: '100%: pinned');
    scale.value = 3.1;
    await _settle(tester);
    expect(_footerInBody(tester), isTrue, reason: '310%: too tall, scrolls with the body');
    scale.value = 1.0;
    await _settle(tester);
    expect(_footerInBody(tester), isFalse, reason: 'pinned again');
  });

  for (final scale in [1.0, 2.0, 3.1]) {
    group('text ${(scale * 100).round()}% on 375×667', () {
      for (final s in AppRouter.catalog) {
        testWidgets('${s.$1} body clear of footer', (tester) async {
          await _pump(tester, s.$4, scale);
          final known = scale > 3 ? _knownOverflow[s.$1] : null;
          if (known == null) {
            expect(tester.takeException(), isNull, reason: 'exception on first layout');
          } else {
            expect('${tester.takeException()}', contains('overflowed'), reason: 'fixed? remove ${s.$1} from _knownOverflow ($known)');
          }

          final scrollEl = _bodyScrollable(tester);
          final state = (scrollEl as StatefulElement).state as ScrollableState;
          final footerEls = _footer.evaluate().toList();
          final footerEl = footerEls.isEmpty ? null : footerEls.single;
          final footerScrolls = footerEl != null && _inside(footerEl, scrollEl);
          if (scale == 1.0 && footerEl != null) {
            expect(footerScrolls, isFalse, reason: 'at 100% text the footer must stay pinned');
          }

          // Body texts in content order.
          final texts = find.descendant(of: find.byElementPredicate((e) => identical(e, scrollEl)), matching: find.byType(RichText))
              .evaluate()
              .where((e) => !_inside(e, footerEl) && (e.widget as RichText).text.toPlainText().trim().isNotEmpty)
              .toList();
          final viewport = _viewportOf(scrollEl.renderObject!);
          double reveal(Element e, double alignment) => viewport.getOffsetToReveal(e.renderObject!, alignment).offset;
          String label(Element e) => '"${(e.widget as RichText).text.toPlainText()}"';
          texts.sort((a, b) => reveal(a, 0).compareTo(reveal(b, 0)));
          final position = state.position;
          final hidden = <String>[];

          // Each text lies inside the scrolling content, so every line of it
          // can be scrolled into view (a text spilling out of a fixed-size
          // box at the end of the body cannot).
          final pending = <Element>[];
          for (final e in texts) {
            if (reveal(e, 0) < position.minScrollExtent - 0.5 || reveal(e, 1) > position.maxScrollExtent + 0.5) {
              hidden.add('${label(e)} spills out of the scrolling body');
            } else {
              pending.add(e);
            }
          }

          // Scrolled to each text, the part on screen never touches the
          // footer, and a text no taller than the body is shown whole. A text
          // taller than the body but not than the screen below the header
          // is hidden behind a pinned footer; a text taller than that is
          // also checked scrolled to its end.
          Future<(Rect, Rect?)> jump(double offset) async {
            position.jumpTo(offset.clamp(position.minScrollExtent, position.maxScrollExtent));
            await tester.pump();
            return (_rect(scrollEl.renderObject! as RenderBox), footerEl == null ? null : _rect(footerEl.renderObject! as RenderBox));
          }

          bool clear(Rect r, Rect view, Rect? foot) {
            final shown = r.intersect(view);
            return foot == null || shown.height <= 0.5 || shown.bottom <= foot.top + 0.5 || shown.top >= foot.bottom - 0.5;
          }

          while (pending.isNotEmpty) {
            final next = pending.first;
            final (view, foot) = await jump(reveal(next, 0));
            final r = _rect(next.renderObject! as RenderBox);
            if (!clear(r, view, foot)) {
              hidden.add('${label(next)} touches the footer');
            } else if (r.height > view.height + 0.5 && !footerScrolls && foot != null && r.height <= foot.bottom - view.top) {
              hidden.add('${label(next)} never shows whole: it fits on screen but not above the pinned footer');
            } else if (r.height > view.height + 0.5) {
              final (view2, foot2) = await jump(reveal(next, 1));
              if (!clear(_rect(next.renderObject! as RenderBox), view2, foot2)) hidden.add('${label(next)} touches the footer at its end');
            } else if (r.top < view.top - 0.5 || r.bottom > view.bottom + 0.5) {
              hidden.add('${label(next)} cannot be scrolled fully into view');
            }
            pending.remove(next);
            pending.removeWhere((e) {
              final r = _rect(e.renderObject! as RenderBox);
              return r.top >= view.top - 0.5 && r.bottom <= view.bottom + 0.5 && clear(r, view, foot);
            });
          }
          expect(hidden, isEmpty, reason: '${s.$1} at ${(scale * 100).round()}%');

          // The footer's first action can be reached and receives taps.
          if (footerEl != null) {
            final actions = find.descendant(of: find.byElementPredicate((e) => identical(e, footerEl)), matching: find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('a:footer[')));
            if (actions.evaluate().isNotEmpty) {
              final primary = actions.first;
              await tester.ensureVisible(primary);
              await tester.pump();
              final r = tester.getRect(primary);
              expect(r.top >= -0.5 && r.bottom <= _screen.height + 0.5, isTrue, reason: 'footer action off screen: $r');
              expect(primary.hitTestable(), findsOneWidget, reason: 'footer action does not receive taps');
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}
