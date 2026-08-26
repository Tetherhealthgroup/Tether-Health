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

    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      findsOneWidget,
    );
    expect(find.text('Tu historia sigue siendo tuya.'), findsOneWidget);
    expect(find.text('Aceptar y continuar'), findsOneWidget);
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

    expect(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      findsOneWidget,
    );
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

  testWidgets('Screen 3 privacy choices change and persist across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 2));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      findsOneWidget,
    );

    final reminders = find.byKey(const ValueKey('consent-helpful-reminders'));
    final careTeam = find.byKey(const ValueKey('consent-share-care-team'));
    final improve = find.byKey(const ValueKey('consent-help-improve'));

    await tester.ensureVisible(reminders);
    expect(tester.widget<Switch>(reminders).value, isTrue);
    await tester.tap(reminders);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(reminders).value, isFalse);

    await tester.ensureVisible(careTeam);
    await tester.tap(careTeam);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(careTeam).value, isTrue);

    await tester.ensureVisible(improve);
    await tester.tap(improve);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(improve).value, isTrue);

    await tester.tap(find.byKey(const ValueKey('consent-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-why-breathefree-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(reminders).value, isFalse);
    await tester.ensureVisible(careTeam);
    expect(tester.widget<Switch>(careTeam).value, isTrue);
    await tester.ensureVisible(improve);
    expect(tester.widget<Switch>(improve).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 3 opens the privacy review and continues to Screen 4',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 2));
    await tester.pumpAndSettle();

    final review = find.byKey(const ValueKey('consent-review-privacy'));
    await tester.ensureVisible(review);
    await tester.tap(review);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('consent-sheet-done')), findsOneWidget);
    expect(
      find.textContaining('complete Terms of Use and Privacy Notice'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('consent-sheet-done')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('consent-agree-continue')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-baseline-assessment-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 4 answer changes and persists across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 3));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-baseline-assessment-screen')),
      findsOneWidget,
    );
    expect(find.text('Selected'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('baseline-next')),
          )
          .onPressed,
      isNull,
      reason: 'Next must remain disabled until the patient answers.',
    );

    final tenOrFewer = find.byKey(const ValueKey('baseline-choice-tenOrFewer'));
    await tester.ensureVisible(tenOrFewer);
    await tester.tap(tenOrFewer);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('baseline-selected-tenOrFewer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('baseline-selected-elevenToTwenty')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('baseline-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('consent-agree-continue')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('baseline-selected-tenOrFewer')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 4 Next continues to Screen 5', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 3));
    await tester.pumpAndSettle();

    final selectedChoice =
        find.byKey(const ValueKey('baseline-choice-elevenToTwenty'));
    await tester.ensureVisible(selectedChoice);
    await tester.tap(selectedChoice);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-trigger-map-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 5 trigger choices change and persist across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 4));
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const ValueKey('trigger-continue'));
    expect(
      tester.widget<FilledButton>(continueButton).onPressed,
      isNull,
      reason: 'Continue must remain disabled until a trigger is selected.',
    );

    final stress = find.byKey(const ValueKey('trigger-choice-stress'));
    final driving = find.byKey(const ValueKey('trigger-choice-driving'));
    await tester.tap(stress);
    await tester.pumpAndSettle();
    await tester.tap(driving);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('trigger-selected-stress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trigger-selected-driving')),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('trigger-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-baseline-assessment-screen')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('baseline-choice-tenOrFewer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('trigger-selected-stress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trigger-selected-driving')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 5 saves a custom trigger and continues to Screen 6',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 4));
    await tester.pumpAndSettle();

    final addOwn = find.byKey(const ValueKey('trigger-add-own'));
    await tester.ensureVisible(addOwn);
    await tester.tap(addOwn);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('trigger-custom-input')),
      'Phone calls',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-custom-save')));
    await tester.pumpAndSettle();

    expect(find.text('Phone calls'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trigger-continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-readiness-result-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 6 reflects assessment answers and continues to Screen 7',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 3));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('baseline-choice-elevenToTwenty')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trigger-choice-stress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-choice-driving')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-readiness-result-screen')),
      findsOneWidget,
    );
    expect(
      find.text('11–20 cigarettes on a typical day'),
      findsOneWidget,
    );
    expect(
      find.text('You want support for stress and driving'),
      findsOneWidget,
    );
    expect(find.text('You identified 2 situations to prepare for'),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('readiness-continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-choose-quit-path-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 7 quit path changes and persists across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 6));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-choose-quit-path-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quit-path-selected-setQuitDate')),
      findsOneWidget,
      reason: 'Set a quit date should be the recommended default.',
    );

    final quitToday = find.byKey(const ValueKey('quit-path-choice-quitToday'));
    await tester.ensureVisible(quitToday);
    await tester.tap(quitToday);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('quit-path-selected-quitToday')),
      findsOneWidget,
    );
    expect(
      find.text('Quit today selected · Saved automatically'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('quit-path-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-readiness-result-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('readiness-continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('quit-path-selected-quitToday')),
      findsOneWidget,
      reason: 'The chosen quit path should remain saved after going back.',
    );

    final gradual =
        find.byKey(const ValueKey('quit-path-choice-reduceGradually'));
    await tester.ensureVisible(gradual);
    await tester.tap(gradual);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('quit-path-selected-reduceGradually')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 7 Continue advances to Screen 8', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 6));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-select-quit-date-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 7 inherits Spanish from onboarding', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('welcome-spanish')));
    await tester.tap(find.byKey(const ValueKey('welcome-spanish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('consent-agree-continue')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('baseline-choice-tenOrFewer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-choice-stress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('readiness-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu plan'), findsOneWidget);
    expect(find.text('¿Qué te parece posible ahora mismo?'), findsOneWidget);
    expect(find.text('Elegir una fecha'), findsOneWidget);
    expect(find.text('Dejar de fumar hoy'), findsOneWidget);
    expect(find.text('Reducir gradualmente'), findsOneWidget);
    expect(find.text('RECOMENDADO'), findsOneWidget);
    expect(find.text('Continuar con este camino'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Elige tu fecha para dejarlo'), findsOneWidget);
    expect(find.text('Elige un día para comenzar.'), findsOneWidget);
    expect(find.text('Confirmar esta fecha'), findsOneWidget);
    expect(find.text('2 DE 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 7 remains usable across supported phone sizes',
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
          key: ValueKey('screen-7-${device.name}'),
          initialScreen: 6,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-choose-quit-path-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 7.',
      );
      final continueButton = find.byKey(const ValueKey('quit-path-continue'));
      expect(
        tester.getRect(continueButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Continue visible.',
      );

      final gradual =
          find.byKey(const ValueKey('quit-path-choice-reduceGradually'));
      await tester.ensureVisible(gradual);
      await tester.tap(gradual);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('quit-path-selected-reduceGradually')),
        findsOneWidget,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 8 date and check-in choices persist across navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 7));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-select-quit-date-screen')),
      findsOneWidget,
    );
    expect(find.text('Choose a day to begin.'), findsOneWidget);
    expect(find.byKey(const ValueKey('quit-date-selected')), findsOneWidget);

    final defaultDate = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 7)),
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      defaultDate.year,
      defaultDate.month,
    );
    final alternateDate = defaultDate.day < daysInMonth
        ? defaultDate.add(const Duration(days: 1))
        : defaultDate.subtract(const Duration(days: 1));
    final month = alternateDate.month.toString().padLeft(2, '0');
    final day = alternateDate.day.toString().padLeft(2, '0');
    final alternateKey = ValueKey(
      'quit-date-day-${alternateDate.year}-$month-$day',
    );

    await tester.tap(find.byKey(alternateKey));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(alternateKey),
        matching: find.byKey(const ValueKey('quit-date-selected')),
      ),
      findsOneWidget,
    );

    final checkIn = find.byKey(const ValueKey('quit-date-check-in'));
    await tester.ensureVisible(checkIn);
    await tester.tap(checkIn);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('quit-date-check-in')))
          .value,
      isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('quit-date-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-choose-quit-path-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(alternateKey),
        matching: find.byKey(const ValueKey('quit-date-selected')),
      ),
      findsOneWidget,
      reason: 'The selected date should remain saved after going back.',
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('quit-date-check-in')))
          .value,
      isFalse,
      reason: 'The private check-in choice should remain saved.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 8 adapts to Quit today and Reduce gradually paths',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 6));
    await tester.pumpAndSettle();

    final quitToday = find.byKey(const ValueKey('quit-path-choice-quitToday'));
    await tester.ensureVisible(quitToday);
    await tester.tap(quitToday);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Today is your starting point.'), findsOneWidget);
    expect(find.text('Start my quit today'), findsOneWidget);
    expect(find.text('Starting today'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quit-date-back')));
    await tester.pumpAndSettle();
    final gradual =
        find.byKey(const ValueKey('quit-path-choice-reduceGradually'));
    await tester.ensureVisible(gradual);
    await tester.tap(gradual);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose the day to become smoke-free.'),
      findsOneWidget,
    );
    expect(find.text('Confirm target date'), findsOneWidget);
    expect(find.textContaining('days to reduce gradually'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 8 calendar navigation and Confirm advance to Screen 9',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 7));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('quit-date-next-month')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('quit-date-previous-month')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('quit-date-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 8 remains usable across supported phone sizes',
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
          key: ValueKey('screen-8-${device.name}'),
          initialScreen: 7,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-select-quit-date-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 8.',
      );
      final confirm = find.byKey(const ValueKey('quit-date-confirm'));
      expect(
        tester.getRect(confirm).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Confirm visible.',
      );
      expect(find.byKey(const ValueKey('quit-date-calendar')), findsOneWidget);

      final checkIn = find.byKey(const ValueKey('quit-date-check-in'));
      await tester.ensureVisible(checkIn);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 9 reasons and top reason change and persist',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 8));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      findsOneWidget,
    );
    expect(find.text('3 SELECTED'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reason-selected-family')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('reason-choice-saveMoney')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reason-top-saveMoney')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reason-selected-saveMoney')),
      findsOneWidget,
    );
    expect(
      find.textContaining('You chose this to save money.'),
      findsOneWidget,
    );
    expect(find.text('4 SELECTED'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reasons-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-select-quit-date-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('quit-date-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reason-selected-saveMoney')),
      findsOneWidget,
      reason: 'Selected reasons should remain saved after going back.',
    );
    expect(
      find.textContaining('You chose this to save money.'),
      findsOneWidget,
      reason: 'The top reason should remain saved after going back.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 9 custom reason can become the top motivation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 8));
    await tester.pumpAndSettle();

    final customEditor = find.byKey(const ValueKey('reason-custom-editor'));
    await tester.ensureVisible(customEditor);
    await tester.tap(customEditor);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('reason-custom-text-field')),
      'I want more energy for hiking',
    );
    await tester.tap(
      find.byKey(const ValueKey('reason-custom-make-top')),
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('reason-custom-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reason-custom-card')),
      findsOneWidget,
    );
    expect(find.text('I want more energy for hiking'), findsWidgets);
    expect(
      find.textContaining('You chose this because'),
      findsOneWidget,
    );
    expect(find.text('4 SELECTED'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('reason-custom-remove')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reason-custom-editor')),
      findsOneWidget,
    );
    expect(find.text('I want more energy for hiking'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 9 inherits Spanish and Save advances to Screen 10',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('welcome-spanish')));
    await tester.tap(find.byKey(const ValueKey('welcome-spanish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('consent-agree-continue')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('baseline-choice-tenOrFewer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-choice-stress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('readiness-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quit-date-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Mis razones'), findsOneWidget);
    expect(find.text('¿Por qué quieres dejar de fumar?'), findsOneWidget);
    expect(find.text('Proteger a mi familia'), findsOneWidget);
    expect(find.text('Guardar mis razones'), findsOneWidget);
    expect(find.text('3 DE 5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reasons-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-image-10')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 9 remains usable across supported phone sizes',
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
          key: ValueKey('screen-9-${device.name}'),
          initialScreen: 8,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-my-reasons-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 9.',
      );
      final save = find.byKey(const ValueKey('reasons-save'));
      expect(
        tester.getRect(save).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Save my reasons visible.',
      );

      final customEditor = find.byKey(const ValueKey('reason-custom-editor'));
      await tester.ensureVisible(customEditor);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 6 path choice and explanation work and persist',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 5));
    await tester.pumpAndSettle();

    final why = find.byKey(const ValueKey('readiness-why-fit'));
    await tester.ensureVisible(why);
    await tester.tap(why);
    await tester.pumpAndSettle();
    expect(find.text('Why preparation may fit'), findsOneWidget);
    expect(
      find.textContaining('not a medical assessment'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('readiness-why-done')));
    await tester.pumpAndSettle();

    final explore = find.byKey(const ValueKey('readiness-path-explore'));
    await tester.ensureVisible(explore);
    await tester.tap(explore);
    await tester.pumpAndSettle();
    expect(find.text('Explore without setting a date'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('readiness-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-trigger-map-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('trigger-choice-stress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Explore without setting a date'), findsOneWidget);

    final connect = find.byKey(const ValueKey('readiness-path-connect'));
    await tester.ensureVisible(connect);
    await tester.tap(connect);
    await tester.pumpAndSettle();
    expect(find.text('Find support options'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 6 inherits Spanish from onboarding', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('welcome-spanish')));
    await tester.tap(find.byKey(const ValueKey('welcome-spanish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('consent-agree-continue')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('baseline-choice-tenOrFewer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-choice-stress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Tu punto de partida'), findsOneWidget);
    expect(
      find.text('10 cigarrillos o menos en un día habitual'),
      findsOneWidget,
    );
    expect(find.text('Quieres prepararte para estrés'), findsOneWidget);
    expect(find.text('Crear mi plan de preparación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 6 remains usable across supported phone sizes',
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
          key: ValueKey('screen-6-${device.name}'),
          initialScreen: 5,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-readiness-result-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 6.',
      );
      final continueButton = find.byKey(const ValueKey('readiness-continue'));
      expect(
        tester.getRect(continueButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep the main action visible.',
      );

      final connect = find.byKey(const ValueKey('readiness-path-connect'));
      await tester.ensureVisible(connect);
      await tester.tap(connect);
      await tester.pumpAndSettle();
      expect(find.text('Find support options'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 5 inherits Spanish from onboarding', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('welcome-spanish')));
    await tester.tap(find.byKey(const ValueKey('welcome-spanish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('consent-agree-continue')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('baseline-choice-tenOrFewer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();

    expect(
      find.text('¿Cuándo es más probable que quieras fumar?'),
      findsOneWidget,
    );
    expect(find.text('Entornos sociales'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 5 remains usable across supported phone sizes',
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
          key: ValueKey('screen-5-${device.name}'),
          initialScreen: 4,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-trigger-map-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 5.',
      );
      final continueButton = find.byKey(const ValueKey('trigger-continue'));
      expect(
        tester.getRect(continueButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Continue visible.',
      );
      expect(tester.takeException(), isNull);

      final lastChoice = find.byKey(const ValueKey('trigger-choice-beforeBed'));
      await tester.ensureVisible(lastChoice);
      await tester.tap(lastChoice);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('trigger-selected-beforeBed')),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Screen 4 inherits Spanish from onboarding', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('welcome-spanish')));
    await tester.tap(find.byKey(const ValueKey('welcome-spanish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('consent-agree-continue')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('En un día habitual, ¿cuántos cigarrillos fumas?'),
      findsOneWidget,
    );
    expect(find.text('11–20 cigarrillos'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 4 remains usable across supported phone sizes',
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
          key: ValueKey('screen-4-${device.name}'),
          initialScreen: 3,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-baseline-assessment-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 4.',
      );

      final nextButton = find.byKey(const ValueKey('baseline-next'));
      expect(nextButton, findsOneWidget);
      expect(
        tester.getRect(nextButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Next visible.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      final lastChoice =
          find.byKey(const ValueKey('baseline-choice-thirtyOneOrMore'));
      await tester.ensureVisible(lastChoice);
      await tester.pumpAndSettle();
      await tester.tap(lastChoice);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('baseline-selected-thirtyOneOrMore')),
        findsOneWidget,
        reason: '${device.name} should allow the final answer.',
      );
      expect(
        tester.widget<FilledButton>(nextButton).onPressed,
        isNotNull,
        reason: '${device.name} should enable Next after an answer.',
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

  testWidgets('forward swipes cannot bypass explicit onboarding actions',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const ValueKey('functional-welcome-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-welcome-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('welcome-get-started')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-why-breathefree-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-why-breathefree-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('why-continue')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-consent-privacy-screen')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('consent-agree-continue')),
    );
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-baseline-assessment-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-baseline-assessment-screen')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('baseline-next')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey('baseline-choice-tenOrFewer')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('baseline-next')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-trigger-map-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-trigger-map-screen')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('trigger-continue')),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('trigger-choice-stress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trigger-continue')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-readiness-result-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-readiness-result-screen')),
      findsOneWidget,
      reason: 'Screen 6 should require its explicit main action.',
    );
    await tester.tap(find.byKey(const ValueKey('readiness-continue')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-choose-quit-path-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-choose-quit-path-screen')),
      findsOneWidget,
      reason: 'Screen 7 should require its explicit Continue button.',
    );
    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-select-quit-date-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-select-quit-date-screen')),
      findsOneWidget,
      reason: 'Screen 8 should require its explicit Confirm button.',
    );
    await tester.tap(find.byKey(const ValueKey('quit-date-confirm')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      findsOneWidget,
      reason: 'Screen 9 should require its explicit Save button.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 3 remains usable across supported phone sizes',
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
          key: ValueKey('screen-3-${device.name}'),
          initialScreen: 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-consent-privacy-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 3.',
      );

      final continueButton =
          find.byKey(const ValueKey('consent-agree-continue'));
      expect(continueButton, findsOneWidget);
      expect(
        tester.getRect(continueButton).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Agree and continue visible.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      final finalChoice = find.byKey(const ValueKey('consent-help-improve'));
      await tester.ensureVisible(finalChoice);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should reach every optional choice.',
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
