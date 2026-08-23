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

    final getStarted = find.byKey(const ValueKey('welcome-get-started'));
    await tester.ensureVisible(getStarted);
    await tester.tap(getStarted);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-why-breathefree-screen')),
      findsOneWidget,
    );
    expect(
      find.text('Support for the moments that matter most.'),
      findsOneWidget,
    );
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

    final getStarted = find.byKey(const ValueKey('welcome-get-started'));
    await tester.ensureVisible(getStarted);
    await tester.tap(getStarted);
    await tester.pumpAndSettle();

    expect(
      find.text('Apoyo para los momentos más importantes.'),
      findsOneWidget,
    );
    expect(find.text('Continuar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 2 back and continue controls navigate correctly',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 1));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-why-breathefree-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('why-back')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-welcome-screen')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const BreatheFreeApp(
        key: ValueKey('screen-2-continue-test'),
        initialScreen: 1,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('screen-image-3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 2 support cards explain each type of help',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 1));
    await tester.pumpAndSettle();

    final cravingCard = find.byKey(const ValueKey('why-card-craving'));
    await tester.ensureVisible(cravingCard);
    await tester.tap(cravingCard);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('why-sheet-done')), findsOneWidget);
    expect(
      find.textContaining('Essential tools will remain available offline.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('why-sheet-done')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('why-sheet-done')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 1 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;

      await tester.pumpWidget(
        BreatheFreeApp(key: ValueKey(device.name)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-welcome-screen')),
        findsOneWidget,
        reason: '${device.name} should display the functional welcome screen.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      final accountAction = find.byKey(const ValueKey('welcome-sign-in'));
      await tester.ensureVisible(accountAction);
      await tester.pumpAndSettle();

      expect(
        tester.getRect(accountAction).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep the account action reachable.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should scroll without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 2 remains usable across supported phone sizes',
      (tester) async {
    const devices = <({String name, Size size})>[
      (name: 'iPhone SE', size: Size(375, 667)),
      (name: 'iPhone 14 Pro', size: Size(393, 852)),
      (name: 'iPhone Pro Max', size: Size(430, 932)),
      (name: 'small Android', size: Size(360, 800)),
      (name: 'large Android', size: Size(412, 915)),
    ];

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final device in devices) {
      tester.view.physicalSize = device.size;

      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-2-${device.name}'),
          initialScreen: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-why-breathefree-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 2.',
      );
      expect(
        find.byKey(const ValueKey('why-continue')),
        findsOneWidget,
        reason: '${device.name} should keep Continue available.',
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('why-continue'))).overlaps(
              Offset.zero & device.size,
            ),
        isTrue,
        reason: '${device.name} should show Continue without scrolling.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      final slipCard = find.byKey(const ValueKey('why-card-slip'));
      await tester.ensureVisible(slipCard);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should scroll through all support cards.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
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
