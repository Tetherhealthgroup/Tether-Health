// TEnvironment.badge: null by default (nothing is drawn); when set, every
// screen and sheet shows a small accessible pill at its top trailing edge.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

Future<void> _open(WidgetTester tester, String route, {double scale = 1, TextDirection direction = TextDirection.ltr, Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final builder = AppRouter.screens[route]!;
  final sheet = AppRouter.sheets.contains(route);
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    builder: (c, child) => Directionality(textDirection: direction, child: MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: child!)),
    home: Builder(builder: (c) => sheet ? TSheetPreview(child: builder(c)) : builder(c)),
  ));
  await tester.pump(const Duration(milliseconds: 50));
}

final _badge = find.byKey(const ValueKey('environment-badge'));

void main() {
  tearDown(() => TEnvironment.badge = null);

  test('there is no badge by default, and blank text is no badge', () {
    expect(TEnvironment.badge, isNull);
    TEnvironment.badge = '  ';
    expect(TEnvironment.badge, isNull);
    TEnvironment.badge = ' Staging ';
    expect(TEnvironment.badge, 'Staging');
    TEnvironment.badge = null;
    expect(TEnvironment.badge, isNull);
  });

  testWidgets('with no badge nothing is drawn and it takes no room', (tester) async {
    await _open(tester, Routes.welcome);
    expect(_badge, findsNothing);
    expect(tester.getSize(find.byType(TEnvironmentBadge)), Size.zero);
    final header = tester.getTopLeft(find.byType(TScreen));
    TEnvironment.badge = 'Test build';
    await tester.pump();
    expect(_badge, findsOneWidget);
    expect(tester.getTopLeft(find.byType(TScreen)), header);
  });

  testWidgets('every screen and sheet shows one badge, in the top trailing corner', (tester) async {
    TEnvironment.badge = 'Test build';
    for (final s in AppRouter.catalog) {
      await _open(tester, s.$4);
      expect(_badge, findsOneWidget, reason: s.$1);
      expect(tester.takeException(), isNull, reason: s.$1);
      final box = tester.getRect(_badge);
      expect(box.right, greaterThan(390 / 2), reason: '${s.$1}: trailing half');
      expect(box.right, lessThanOrEqualTo(390), reason: s.$1);
      if (!AppRouter.sheets.contains(s.$4)) expect(box.top, lessThan(40), reason: '${s.$1}: top');
    }
  });

  testWidgets('the badge follows the app: set and cleared after the screen is shown', (tester) async {
    await _open(tester, Routes.today);
    expect(_badge, findsNothing);
    TEnvironment.badge = 'Sandbox';
    await tester.pump();
    expect(find.descendant(of: _badge, matching: find.text('Sandbox')), findsOneWidget);
    TEnvironment.badge = 'Other text';
    await tester.pump();
    expect(find.text('Sandbox'), findsNothing);
    expect(find.text('Other text'), findsOneWidget);
    TEnvironment.badge = null;
    await tester.pump();
    expect(_badge, findsNothing);
  });

  testWidgets('screen readers hear "Environment: <text>"', (tester) async {
    final semantics = tester.ensureSemantics();
    TEnvironment.badge = 'Test build';
    await _open(tester, Routes.welcome);
    expect(find.semantics.byLabel('Environment: Test build'), findsOneWidget);
    expect(find.semantics.byLabel('Test build'), findsNothing, reason: 'the text is read once, in the label');
    semantics.dispose();
  });

  testWidgets('long text, large text, right-to-left and a small phone do not overflow', (tester) async {
    TEnvironment.badge = 'A very long environment name that goes on and on and on';
    for (final route in [Routes.welcome, Routes.today, Routes.authSignin]) {
      for (final scale in [1.0, 2.0, 3.1]) {
        await _open(tester, route, scale: scale, size: const Size(320, 568));
        expect(_badge, findsOneWidget, reason: '$route at $scale');
        expect(tester.takeException(), isNull, reason: '$route at $scale');
        expect(tester.getRect(_badge).right, lessThanOrEqualTo(320));
      }
      await _open(tester, route, direction: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      expect(tester.getRect(_badge).left, lessThan(390 / 2), reason: 'leading side in right-to-left');
    }
  });

  testWidgets('on a dark screen it is drawn for dark', (tester) async {
    TEnvironment.badge = 'Test build';
    await _open(tester, Routes.rescueActive);
    final box = tester.widget<Container>(_badge);
    expect((box.decoration! as BoxDecoration).color, TColors.tealRaised);
  });
}
