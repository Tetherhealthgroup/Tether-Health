import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/models/screen_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains the complete ordered 28-screen experience', () {
    expect(approvedScreens, hasLength(28));
    expect(
      approvedScreens.map((screen) => screen.number),
      orderedEquals(List<int>.generate(28, (index) => index + 1)),
    );
    expect(approvedScreens.first.title, 'Welcome');
    expect(approvedScreens.last.title, 'Settings & privacy');
    expect(
      approvedScreens.map((screen) => screen.assetPath).toSet(),
      hasLength(28),
    );
  });

  testWidgets('mobile view opens functional Screen 1 and continues to Screen 2',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pump();

    expect(
      find.byKey(const ValueKey('functional-welcome-screen')),
      findsOneWidget,
    );
    expect(find.text('Your next breath can be different.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('welcome-sign-in')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('screen-image-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 1 language control switches to Spanish', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pump();

    await tester.ensureVisible(find.byKey(const ValueKey('welcome-spanish')));
    await tester.tap(find.byKey(const ValueKey('welcome-spanish')));
    await tester.pumpAndSettle();

    expect(
      find.text('Tu próxima respiración puede ser diferente.'),
      findsOneWidget,
    );
    expect(find.text('Comenzar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('laptop view exposes all screens and developer navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 27));
    await tester.pump();

    expect(find.text('28 approved screens'), findsOneWidget);
    expect(find.text('Screen 28 · Settings & privacy'), findsOneWidget);
    expect(find.text('Show tap areas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
