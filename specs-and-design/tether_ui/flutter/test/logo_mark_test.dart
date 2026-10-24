// The header logo is the Tether Health mark: the outlined lime leaf on the
// teal disc, with the geometry of tool/brand/tether_mark.svg (the app icon's
// master artwork).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

const _frame = ValueKey('logo-frame');

Future<(ByteData, int)> _render(WidgetTester tester, double size) async {
  await tester.pumpWidget(Center(child: RepaintBoundary(key: _frame, child: TLogoMark(size: size))));
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_frame));
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
  return (bytes, image.width);
}

Color _at(ByteData b, int width, double x, double y) {
  final i = (y.floor() * width + x.floor()) * 4;
  return Color.fromARGB(b.getUint8(i + 3), b.getUint8(i), b.getUint8(i + 1), b.getUint8(i + 2));
}

void main() {
  test('the leaf is the SVG outline: an outer edge with a hole, inside the disc', () {
    final leaf = TLogoMark.leaf();
    expect(leaf.fillType, PathFillType.evenOdd);
    final bounds = leaf.getBounds();
    expect(bounds.left, greaterThan(0));
    expect(bounds.top, greaterThan(0));
    expect(bounds.right, lessThan(32));
    expect(bounds.bottom, lessThan(32));
    // Every SVG vertex lies on the outline's bounds or inside them.
    for (final p in const [Offset(11.136, 26.776), Offset(16.261, 7.651), Offset(20.764, 5.051), Offset(20.864, 5.224), Offset(15.739, 24.349), Offset(11.236, 26.949)]) {
      expect(bounds.inflate(0.01).contains(p), isTrue, reason: '$p');
    }
    expect(leaf.contains(const Offset(16, 16)), isFalse, reason: 'the centre is the hole of the outlined leaf');
  });

  testWidgets('it draws a teal disc with a lime leaf and nothing outside the disc', (tester) async {
    const size = 320.0, s = size / 32;
    final (bytes, width) = await _render(tester, size);
    expect(width, size.toInt());
    expect(_at(bytes, width, 1, 1).a, 0, reason: 'outside the disc stays clear');
    expect(_at(bytes, width, 2 * s, 16 * s), TColors.teal, reason: 'disc');
    expect(_at(bytes, width, 16 * s, 16 * s), TColors.teal, reason: 'the leaf is outlined: its centre shows the disc');
    var lime = 0;
    for (var y = 0; y < width; y += 4) {
      for (var x = 0; x < width; x += 4) {
        if (_at(bytes, width, x.toDouble(), y.toDouble()) == TColors.lime) lime++;
      }
    }
    expect(lime, greaterThan(100), reason: 'the leaf is drawn in lime');
    expect(tester.getSize(find.byType(TLogoMark)), const Size(size, size));
  });

  testWidgets('the header logo uses the mark at 32 pt and adds no semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: TLogoMark()))));
    expect(tester.getSize(find.byType(TLogoMark)), const Size(32, 32));
    expect(find.byIcon(Icons.eco_rounded), findsNothing);
    expect(tester.getSemantics(find.byType(TLogoMark)).label, isEmpty);
    handle.dispose();
  });

  testWidgets('the welcome header shows the mark and the wordmark "Tether Health"', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: tetherTheme(), home: Builder(builder: AppRouter.screens[Routes.welcome]!)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(TLogoMark), findsOneWidget);
    expect(find.text('Tether Health'), findsOneWidget, reason: 'the approved welcome PNG shows the wordmark next to the leaf');
  });

  testWidgets('a logo header with a title shows that title, not the fallback', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: tetherTheme(), home: const TScreen(header: THeader(title: 'Today', left: THeaderLeft.logo))));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tether Health'), findsNothing);
  });
}
