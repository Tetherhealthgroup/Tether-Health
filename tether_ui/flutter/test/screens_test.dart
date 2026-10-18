// Renders every screen and state from the spec on an iPhone 14-sized
// viewport at 100% and 130% text, and fails on any layout overflow or
// exception. This is the "no broken screen ships" gate.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

Future<void> _pump(WidgetTester tester, String route, double scale) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
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
}

void main() {
  test('every tab route exists', () {
    for (final r in AppRouter.tabRoutes.values) {
      expect(AppRouter.screens.containsKey(r), isTrue, reason: r);
    }
    expect(AppRouter.screens.containsKey(Routes.welcome), isTrue);
  });

  for (final scale in [1.0, 1.3]) {
    group('text ${(scale * 100).round()}%', () {
      for (final s in AppRouter.catalog) {
        testWidgets('${s.$1} renders', (tester) async {
          await _pump(tester, s.$4, scale);
          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}
