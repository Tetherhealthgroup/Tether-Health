// Every route the app builds itself in the tether_ui shell keeps its primary
// button reachable and tappable while the call fallback shows.
import 'package:breathefree_patient/app/app_owned_routes.dart';
import 'package:breathefree_patient/app/variants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

/// Key of a route's primary button, as on the generated screens.
const _primary = ValueKey('a:footer[0]');

/// Opens [route] in a phone-sized app, shows the call fallback over it, and
/// reports whether the primary button can be scrolled into view and tapped.
Future<bool> _primaryTappableUnderFallback(
  WidgetTester tester,
  Route<dynamic> Function() route,
) async {
  tester.view.physicalSize = const Size(390, 700) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(
    navigatorKey: navigator,
    theme: tetherTheme(),
    onGenerateRoute: (_) => null,
    onGenerateInitialRoutes: (_) => [route()],
  ));
  await tester.pumpAndSettle();
  TCallFallback.show(
    navigator.currentState!.overlay!,
    TFallbackKind.call,
    '988',
  );
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('call_fallback')), findsOneWidget);
  final button = find.byKey(_primary);
  expect(button, findsOneWidget);
  final scrollable =
      find.ancestor(of: button, matching: find.byType(Scrollable));
  if (scrollable.evaluate().isNotEmpty) {
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
  }
  final tappable = button.hitTestable().evaluate().isNotEmpty;
  TCallFallback.dismiss();
  await tester.pumpAndSettle();
  return tappable;
}

Widget _footerButton(VoidCallback onPressed) =>
    TButton(key: _primary, label: 'Continue', onPressed: onPressed);

void main() {
  for (final MapEntry(key: name, value: _) in appOwnedRoutes.entries) {
    testWidgets('$name keeps its primary button tappable under the fallback',
        (tester) async {
      final tappable = await _primaryTappableUnderFallback(
        tester,
        () => generateAppRoute(RouteSettings(name: name))!,
      );
      expect(tappable, isTrue);
    });
  }

  group('the check itself', () {
    testWidgets('passes a route built on TScreen', (tester) async {
      final tappable = await _primaryTappableUnderFallback(
        tester,
        () => MaterialPageRoute<void>(
          builder: (_) => TScreen(
            footer: [_footerButton(() {})],
            children: const [SizedBox(height: 900)],
          ),
        ),
      );
      expect(tappable, isTrue);
    });

    testWidgets('fails a route whose pinned button the fallback covers',
        (tester) async {
      final tappable = await _primaryTappableUnderFallback(
        tester,
        () => MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: Column(children: [
              const Spacer(),
              SizedBox(height: 56, child: _footerButton(() {})),
            ]),
          ),
        ),
      );
      expect(tappable, isFalse);
    });
  });
}
