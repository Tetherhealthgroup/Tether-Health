import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/models/screen_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(find.textContaining('Starting today'), findsOneWidget);

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
    expect(
      find.byKey(const ValueKey('functional-support-preparation-screen')),
      findsOneWidget,
    );
    expect(find.text('Apoyo y preparación'), findsOneWidget);
    expect(find.text('No tienes que hacer esto a solas.'), findsOneWidget);
    expect(find.text('Guardar mi plan de apoyo'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('support-save')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );
    expect(find.text('Revisa tu plan'), findsOneWidget);
    expect(find.text('5 DE 5'), findsOneWidget);
    expect(find.text('Tu plan está listo.'), findsOneWidget);
    expect(find.text('Proteger a mi familia'), findsOneWidget);
    expect(find.text('Comenzar mi plan para dejarlo'), findsOneWidget);
    expect(find.text('Guardar y terminar después'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('review-start-plan')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
    );
    expect(find.textContaining('Alex.'), findsOneWidget);
    expect(find.text('Tu preparación'), findsOneWidget);
    expect(find.text('Abrir Rescate'), findsOneWidget);
    expect(find.textContaining('Proteger a mi familia'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('preparation-notifications')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tu registro diario está listo'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('preparation-start-check-in')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
    );
    expect(find.text('Registro diario'), findsOneWidget);
    expect(find.text('¿Cómo estás hoy?'), findsOneWidget);
    expect(find.text('Guardar registro'), findsOneWidget);
    expect(find.text('Abrir Rescate'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('checkin-save')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      findsOneWidget,
    );
    expect(find.text('Tu próximo paso'), findsOneWidget);
    expect(
      find.text('Prueba un reinicio del estrés de 3 minutos.'),
      findsOneWidget,
    );
    expect(find.text('Practicar ahora'), findsOneWidget);
    expect(find.text('Agregar a mi plan de afrontamiento'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next-step-practice')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
      findsOneWidget,
    );
    expect(find.text('Reinicio del estrés'), findsOneWidget);
    expect(find.text('PASO 1 DE 3 · RESPIRA'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Abrir Rescate'), findsOneWidget);

    final stressResetSkip = find.byKey(const ValueKey('stress-reset-skip'));
    await tester.ensureVisible(stressResetSkip);
    await tester.tap(stressResetSkip);
    await tester.pump();
    await tester.tap(stressResetSkip);
    await tester.pump();
    await tester.tap(stressResetSkip);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('functional-exercise-complete-recheck-screen'),
      ),
      findsOneWidget,
    );
    expect(find.text('Le diste tiempo a la sensación para cambiar.'),
        findsOneWidget);
    expect(find.text('¿Qué tan fuerte es el antojo ahora?'), findsOneWidget);
    expect(find.text('Guardar resultado'), findsOneWidget);
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

  testWidgets('Screen 10 support and preparation choices persist',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 9));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-support-preparation-screen')),
      findsOneWidget,
    );
    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('1 PERSON ADDED'), findsOneWidget);
    expect(find.text('2 OF 3'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('support-person-toggle-jordan')),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 PEOPLE ADDED'), findsOneWidget);

    final finalTask =
        find.byKey(const ValueKey('preparation-task-stockAlternatives'));
    await tester.ensureVisible(finalTask);
    await tester.tap(finalTask);
    await tester.pumpAndSettle();
    expect(find.text('3 OF 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('support-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reasons-save')));
    await tester.pumpAndSettle();

    expect(find.text('0 PEOPLE ADDED'), findsOneWidget);
    expect(find.text('3 OF 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 10 can add and edit support people', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 9));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('support-person-edit-jordan')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('support-person-name-field')),
      'Jordan Lee',
    );
    await tester.tap(find.byKey(const ValueKey('support-person-save')));
    await tester.pumpAndSettle();
    expect(find.text('Jordan Lee'), findsOneWidget);

    final addPerson = find.byKey(const ValueKey('support-add-person'));
    await tester.ensureVisible(addPerson);
    await tester.tap(addPerson);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('support-person-name-field')),
      'Alex',
    );
    await tester.enterText(
      find.byKey(const ValueKey('support-person-relationship-field')),
      'Sibling',
    );
    await tester.tap(find.byKey(const ValueKey('support-person-save')));
    await tester.pumpAndSettle();

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Sibling · Text message'), findsOneWidget);
    expect(find.text('2 PEOPLE ADDED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 10 treatment education and Save work', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 9));
    await tester.pumpAndSettle();

    final learn = find.byKey(const ValueKey('support-treatment-learn'));
    await tester.ensureVisible(learn);
    await tester.tap(learn);
    await tester.pumpAndSettle();
    expect(find.text('Quit-smoking treatment options'), findsOneWidget);
    expect(
      find.textContaining('does not prescribe'),
      findsWidgets,
    );
    await tester.tap(
      find.byKey(const ValueKey('support-treatment-done')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('support-treatment-toggle')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('support-care-team-reminder')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('support-save')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 10 remains usable across supported phone sizes',
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
          key: ValueKey('screen-10-${device.name}'),
          initialScreen: 9,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-support-preparation-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 10.',
      );
      final save = find.byKey(const ValueKey('support-save'));
      expect(
        tester.getRect(save).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Save visible.',
      );

      final finalTask =
          find.byKey(const ValueKey('preparation-task-stockAlternatives'));
      await tester.ensureVisible(finalTask);
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

  testWidgets('Screen 11 reviews the saved plan and starts Screen 12',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 10));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );
    expect(find.text('Review your plan'), findsOneWidget);
    expect(find.text('5 OF 5'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Your plan is ready.'), findsOneWidget);
    expect(find.text('Set a quit date'), findsOneWidget);
    expect(find.text('Protect my family'), findsOneWidget);
    expect(find.text('Jordan · Evening before'), findsOneWidget);
    expect(find.text('2 of 3 tasks complete'), findsOneWidget);
    expect(
      find.text('Care-team discussion reminder on'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('review-save-later')));
    await tester.pumpAndSettle();
    expect(
      find.text('Your plan is saved. Come back whenever you are ready.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('review-start-plan')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 11 edits return to the review and keep new choices',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 10));
    await tester.pumpAndSettle();

    final reasons = find.byKey(const ValueKey('review-edit-reasons'));
    await tester.ensureVisible(reasons);
    await tester.tap(reasons);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-my-reasons-screen')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('reason-choice-saveMoney')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reason-top-saveMoney')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reasons-save')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );
    expect(find.text('Save money'), findsOneWidget);

    final approach = find.byKey(const ValueKey('review-edit-approach'));
    await tester.ensureVisible(approach);
    await tester.tap(approach);
    await tester.pumpAndSettle();
    final quitToday = find.byKey(const ValueKey('quit-path-choice-quitToday'));
    await tester.ensureVisible(quitToday);
    await tester.pumpAndSettle();
    await tester.tap(quitToday);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quit-path-continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );
    expect(find.text('Quit today'), findsOneWidget);
    expect(find.textContaining('Starting today'), findsOneWidget);

    final support = find.byKey(const ValueKey('review-edit-support'));
    await tester.ensureVisible(support);
    await tester.tap(support);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-support-preparation-screen')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('support-person-edit-jordan')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('support-person-name-field')),
      'Jordan Lee',
    );
    await tester.tap(find.byKey(const ValueKey('support-person-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('support-save')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );
    expect(find.text('Jordan Lee · Evening before'), findsOneWidget);
    expect(find.text('Save money'), findsOneWidget);
    expect(find.text('Quit today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 11 remains usable across supported phone sizes',
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
          key: ValueKey('screen-11-${device.name}'),
          initialScreen: 10,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-review-quit-plan-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 11.',
      );
      for (final key in const [
        ValueKey('review-start-plan'),
        ValueKey('review-save-later'),
      ]) {
        expect(
          tester.getRect(find.byKey(key)).overlaps(Offset.zero & device.size),
          isTrue,
          reason: '${device.name} should keep both actions visible.',
        );
      }

      final treatment = find.byKey(const ValueKey('review-edit-treatment'));
      await tester.ensureVisible(treatment);
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

  testWidgets('Screen 12 shows the activated plan and completes its next task',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 11));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
    );
    expect(find.textContaining('Alex.'), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);
    expect(find.text('Stock gum, water or healthy snacks'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.textContaining('Protect my family'), findsOneWidget);
    expect(find.text('1 supporter'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('preparation-primary-action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('Your preparation is complete'), findsOneWidget);
    expect(find.text('View plan'), findsOneWidget);

    final planCard = find.byKey(const ValueKey('preparation-plan-card'));
    await tester.ensureVisible(planCard);
    await tester.pumpAndSettle();
    await tester.tap(planCard);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('review-back')));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 12 notifications open and clear the unread indicator',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 11));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('preparation-notification-dot')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('preparation-notifications')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming reminders'), findsOneWidget);
    expect(find.text('Discuss treatment options'), findsWidgets);
    expect(
      find.textContaining('Review Jordan’s message'),
      findsWidgets,
    );
    final notificationsDone =
        find.byKey(const ValueKey('preparation-notifications-done'));
    await tester.ensureVisible(notificationsDone);
    await tester.tap(notificationsDone);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('preparation-notification-dot')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 12 rescue and bottom navigation open their destinations',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const destinations = <({String key, String imageKey})>[
      (key: 'preparation-open-rescue', imageKey: 'screen-image-17'),
      (key: 'preparation-nav-progress', imageKey: 'screen-image-26'),
      (key: 'preparation-nav-learn', imageKey: 'screen-image-25'),
      (key: 'preparation-nav-support', imageKey: 'screen-image-27'),
      (key: 'preparation-profile', imageKey: 'screen-image-28'),
    ];

    for (final destination in destinations) {
      await tester.pumpWidget(
        BreatheFreeApp(
          key: ValueKey('screen-12-${destination.key}'),
          initialScreen: 11,
        ),
      );
      await tester.pumpAndSettle();

      final action = find.byKey(ValueKey(destination.key));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey(destination.imageKey)),
        findsOneWidget,
        reason: '${destination.key} should open its approved destination.',
      );
    }

    await tester.pumpWidget(
      const BreatheFreeApp(
        key: ValueKey('screen-12-plan-navigation'),
        initialScreen: 11,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preparation-nav-plan')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 12 remains usable across supported phone sizes',
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
          key: ValueKey('screen-12-${device.name}'),
          initialScreen: 11,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-home-preparation-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 12.',
      );
      expect(
        tester
            .getRect(
              find.byKey(const ValueKey('preparation-bottom-navigation')),
            )
            .overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep bottom navigation visible.',
      );

      final upcoming = find.byKey(const ValueKey('preparation-upcoming-card'));
      await tester.ensureVisible(upcoming);
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

  testWidgets('Screen 12 notification opens Screen 13 and close returns home',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 11));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('preparation-notifications')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your daily check-in is ready'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('preparation-start-check-in')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
    );
    expect(find.text('Daily check-in'), findsOneWidget);
    expect(find.text('How are you doing today?'), findsOneWidget);
    expect(find.text('Save check-in'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('checkin-close')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 13 edits save and persist after returning from Screen 14',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 12));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
    );
    expect(find.text('6'), findsOneWidget);
    expect(find.text('6 · Moderate'), findsOneWidget);
    expect(find.text('7 / 10'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('checkin-mood-good')));
    await tester.pumpAndSettle();
    final cigarettePlus = find.byKey(const ValueKey('checkin-cigarette-plus'));
    await tester.ensureVisible(cigarettePlus);
    await tester.pumpAndSettle();
    await tester.tap(cigarettePlus);
    await tester.pumpAndSettle();
    expect(find.text('7'), findsWidgets);

    final symptoms =
        find.byKey(const ValueKey('checkin-symptom-troubleSleeping'));
    await tester.ensureVisible(symptoms);
    await tester.tap(symptoms);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkin-symptom-other')));
    await tester.pumpAndSettle();
    final otherField =
        find.byKey(const ValueKey('checkin-other-symptom-field'));
    await tester.ensureVisible(otherField);
    await tester.enterText(
      otherField,
      'Headache',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('checkin-save')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      findsOneWidget,
    );
    expect(find.text('Stress reset'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-step-back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
    );
    expect(find.text('7'), findsWidgets);
    expect(find.text('Headache'), findsOneWidget);
    expect(
      tester.widget<FilterChip>(symptoms).selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 13 smoking choices and Rescue navigation work',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 12));
    await tester.pumpAndSettle();

    final smokingNone = find.byKey(const ValueKey('checkin-smoking-none'));
    await tester.ensureVisible(smokingNone);
    await tester.pumpAndSettle();
    await tester.tap(smokingNone);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('checkin-cigarette-count')),
      findsNothing,
    );
    final smokingOneOrMore =
        find.byKey(const ValueKey('checkin-smoking-oneOrMore'));
    await tester.ensureVisible(smokingOneOrMore);
    await tester.pumpAndSettle();
    await tester.tap(smokingOneOrMore);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('checkin-cigarette-count')),
      findsOneWidget,
    );

    final rescue = find.byKey(const ValueKey('checkin-open-rescue'));
    await tester.ensureVisible(rescue);
    await tester.tap(rescue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-image-17')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 13 remains usable across supported phone sizes',
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
          key: ValueKey('screen-13-${device.name}'),
          initialScreen: 12,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-daily-check-in-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 13.',
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('checkin-save')))
            .overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Save check-in visible.',
      );

      final support = find.byKey(const ValueKey('checkin-open-rescue'));
      await tester.ensureVisible(support);
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

  testWidgets(
      'Screen 14 uses the saved check-in recommendation and explains it',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 13));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      findsOneWidget,
    );
    expect(find.text('CHECK-IN SAVED'), findsOneWidget);
    expect(find.text('Try a 3-minute stress reset.'), findsOneWidget);
    expect(find.text('Stress reset'), findsOneWidget);
    expect(find.text('Stress · High'), findsOneWidget);
    expect(find.text('Craving · 6/10'), findsOneWidget);
    expect(find.text('Confidence · 7'), findsOneWidget);

    final why = find.byKey(const ValueKey('next-step-why'));
    await tester.ensureVisible(why);
    await tester.pumpAndSettle();
    await tester.tap(why);
    await tester.pumpAndSettle();
    expect(find.text('Why this was recommended'), findsWidgets);
    expect(
        find.textContaining('only today’s check-in answers'), findsOneWidget);
    expect(find.textContaining('not a diagnosis'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next-step-why-done')));
    await tester.pumpAndSettle();
    expect(find.textContaining('not a diagnosis'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 14 changes strategy and keeps coping-plan choices',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 13));
    await tester.pumpAndSettle();

    final choose = find.byKey(const ValueKey('next-step-choose-strategy'));
    await tester.ensureVisible(choose);
    await tester.pumpAndSettle();
    await tester.tap(choose);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('next-step-strategy-cravingRescue')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Craving rescue'), findsOneWidget);
    expect(find.text('Try a quick craving rescue.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-step-coping-plan')));
    await tester.pumpAndSettle();
    expect(find.text('Added to my coping plan'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('next-step-coping-confirmation')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('next-step-practice')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-image-17')), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      findsOneWidget,
    );
    expect(find.text('Craving rescue'), findsOneWidget);
    expect(find.text('Added to my coping plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 14 hands off support and Rescue only after a choice',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 13));
    await tester.pumpAndSettle();

    final urge = find.byKey(const ValueKey('next-step-still-urge'));
    await tester.ensureVisible(urge);
    await tester.pumpAndSettle();
    await tester.tap(urge);
    await tester.pumpAndSettle();
    expect(find.textContaining('No message will be sent automatically'),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next-step-open-support')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-image-27')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(urge);
    await tester.pumpAndSettle();
    await tester.tap(urge);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-step-open-rescue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-image-17')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 14 changes its automatic suggestion with check-in data',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 12));
    await tester.pumpAndSettle();

    final craving = find.byKey(const ValueKey('checkin-craving-slider'));
    await tester.ensureVisible(craving);
    await tester.pumpAndSettle();
    final cravingRect = tester.getRect(craving);
    await tester.tapAt(Offset(cravingRect.right - 8, cravingRect.center.dy));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('checkin-save')));
    await tester.pumpAndSettle();

    expect(find.text('Craving rescue'), findsOneWidget);
    expect(find.text('Craving · 10/10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 14 remains usable across supported phone sizes',
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
          key: ValueKey('screen-14-${device.name}'),
          initialScreen: 13,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-personalized-next-step-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 14.',
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('next-step-practice')))
            .overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Practice this now visible.',
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('next-step-coping-plan')))
            .overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep the coping-plan action visible.',
      );

      final choose = find.byKey(const ValueKey('next-step-choose-strategy'));
      await tester.ensureVisible(choose);
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
    await tester.tap(find.byKey(const ValueKey('reasons-save')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-support-preparation-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-support-preparation-screen')),
      findsOneWidget,
      reason: 'Screen 10 should require its explicit Save button.',
    );
    await tester.tap(find.byKey(const ValueKey('support-save')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-review-quit-plan-screen')),
      findsOneWidget,
      reason: 'Screen 11 should require its explicit Start button.',
    );
    await tester.tap(find.byKey(const ValueKey('review-start-plan')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
      reason: 'Screen 12 should not advance through a forward swipe.',
    );
    await tester.tap(
      find.byKey(const ValueKey('preparation-notifications')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('preparation-start-check-in')),
    );
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
      reason: 'Screen 13 should require its explicit Save button.',
    );
    await tester.tap(find.byKey(const ValueKey('checkin-save')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      findsOneWidget,
      reason: 'Screen 14 should require its explicit Practice action.',
    );
    await tester.tap(find.byKey(const ValueKey('next-step-practice')));
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
      findsOneWidget,
      reason: 'Screen 15 should require an explicit exercise action.',
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

  testWidgets('Screen 15 timer pauses and resumes without losing progress',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const speechChannel = MethodChannel('flutter_tts');
    final speechCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(speechChannel, (call) async {
      speechCalls.add(call);
      return 1;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(speechChannel, null),
    );

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 14));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
      findsOneWidget,
    );
    expect(find.text('STEP 1 OF 3 · BREATHE'), findsOneWidget);
    expect(find.text('Breath 1 of 10'), findsOneWidget);
    expect(find.text('3:00 LEFT'), findsOneWidget);
    expect(
      speechCalls.any((call) => call.method == 'speak'),
      isTrue,
      reason: 'Voice guidance should speak the current breathing cue.',
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('2:59 LEFT'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stress-reset-pause')));
    await tester.pump();
    expect(find.text('Resume exercise'), findsOneWidget);
    final pausedTime = (tester.widget<Text>(
      find.byKey(const ValueKey('stress-reset-time-left')),
    )).data;
    await tester.pump(const Duration(seconds: 2));
    expect(
      (tester.widget<Text>(
        find.byKey(const ValueKey('stress-reset-time-left')),
      )).data,
      pausedTime,
    );

    await tester.tap(find.byKey(const ValueKey('stress-reset-pause')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(
      (tester.widget<Text>(
        find.byKey(const ValueKey('stress-reset-time-left')),
      )).data,
      isNot(pausedTime),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 15 preferences and three-step sequence work',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 14));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('stress-reset-voice')));
    await tester.pump();
    expect(find.text('VOICE OFF'), findsOneWidget);
    expect(find.text('Voice guidance off'), findsOneWidget);

    final motion = find.byKey(const ValueKey('stress-reset-motion'));
    await tester.ensureVisible(motion);
    await tester.pump();
    await tester.tap(motion);
    await tester.pump();
    expect(find.text('Full motion on'), findsOneWidget);

    final skip = find.byKey(const ValueKey('stress-reset-skip'));
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    await tester.pump();
    expect(find.text('STEP 2 OF 3 · WATER'), findsOneWidget);
    expect(find.text('Drink a glass of water'), findsOneWidget);

    await tester.tap(skip);
    await tester.pump();
    expect(find.text('STEP 3 OF 3 · SWITCH'), findsOneWidget);
    expect(find.text('Switch what you are doing'), findsOneWidget);

    await tester.tap(skip);
    await tester.pumpAndSettle();
    expect(
        find.byKey(
            const ValueKey('functional-exercise-complete-recheck-screen')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 15 saves partial progress when leaving', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 14));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('stress-reset-close')));
    await tester.pumpAndSettle();
    expect(find.text('Leave the exercise?'), findsOneWidget);
    expect(
        find.textContaining('partial progress will be saved'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stress-reset-exit-save')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-personalized-next-step-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('next-step-practice')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
      findsOneWidget,
    );
    expect(find.text('Resume exercise'), findsOneWidget);
    expect(find.text('2:59 LEFT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 15 end and Rescue actions require explicit choices',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 14));
    await tester.pump();

    final end = find.byKey(const ValueKey('stress-reset-end'));
    await tester.ensureVisible(end);
    await tester.pump();
    await tester.tap(end);
    await tester.pumpAndSettle();
    expect(find.text('End the exercise now?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stress-reset-end-cancel')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
      findsOneWidget,
    );

    final rescue = find.byKey(const ValueKey('stress-reset-rescue'));
    await tester.ensureVisible(rescue);
    await tester.pump();
    await tester.tap(rescue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-image-17')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 15 remains usable across supported phone sizes',
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
          key: ValueKey('screen-15-${device.name}'),
          initialScreen: 14,
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 15.',
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('stress-reset-close')))
            .overlaps(Offset.zero & device.size),
        isTrue,
      );
      final end = find.byKey(const ValueKey('stress-reset-end'));
      await tester.ensureVisible(end);
      await tester.pump();
      expect(
        tester.getRect(end).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should reach End exercise.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('Screen 16 shows an honest completion recheck', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const BreatheFreeApp(
        key: ValueKey('screen-16-save-flow'),
        initialScreen: 15,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey('functional-exercise-complete-recheck-screen'),
      ),
      findsOneWidget,
    );
    expect(find.text('COMPLETE'), findsOneWidget);
    expect(find.text('You gave the feeling time to change.'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('How strong is the craving now?'), findsOneWidget);
    expect(find.text('6 · Moderate'), findsOneWidget);
    expect(find.text('6 / 10'), findsNWidgets(2));
    expect(find.text('— 0'), findsOneWidget);
    expect(find.text('Save result'), findsOneWidget);

    await tester.fling(
      find.byKey(
        const ValueKey('functional-exercise-complete-recheck-screen'),
      ),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('functional-exercise-complete-recheck-screen'),
      ),
      findsOneWidget,
      reason: 'Screen 16 should require an explicit action.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 16 rating and helpful choice update its result',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 15));
    await tester.pump();

    final slider =
        find.byKey(const ValueKey('exercise-recheck-craving-slider'));
    await tester.ensureVisible(slider);
    await tester.pump();
    tester.widget<Slider>(slider).onChanged!(3);
    await tester.pump();

    expect(find.text('3 · Mild'), findsOneWidget);
    expect(find.text('↓ 3'), findsOneWidget);

    final water = find.byKey(const ValueKey('exercise-recheck-helpful-water'));
    await tester.ensureVisible(water);
    await tester.tap(water);
    await tester.pump();
    expect(
      find.text('We’ll prioritize a water break when stress is high.'),
      findsOneWidget,
    );
    expect(tester.widget<ChoiceChip>(water).selected, isTrue);

    final switching = find.byKey(
      const ValueKey('exercise-recheck-helpful-switchingActivities'),
    );
    await tester.tap(switching);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(water).selected, isFalse);
    expect(tester.widget<ChoiceChip>(switching).selected, isTrue);
    expect(
      find.text(
        'We’ll prioritize switching activities when stress is high.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 16 Save returns home and Repeat restarts the exercise',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 15));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('exercise-recheck-repeat')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-guided-stress-reset-screen')),
      findsOneWidget,
    );
    expect(find.text('STEP 1 OF 3 · BREATHE'), findsOneWidget);
    expect(find.text('3:00 LEFT'), findsOneWidget);

    await tester.pumpWidget(
      const BreatheFreeApp(
        key: ValueKey('screen-16-save-after-repeat'),
        initialScreen: 15,
      ),
    );
    await tester.pump();
    final slider =
        find.byKey(const ValueKey('exercise-recheck-craving-slider'));
    tester.widget<Slider>(slider).onChanged!(4);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exercise-recheck-save')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-home-preparation-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 16 protects unsaved exit and opens Rescue explicitly',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp(initialScreen: 15));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('exercise-recheck-close')));
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('exercise-recheck-exit-stay')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('functional-exercise-complete-recheck-screen'),
      ),
      findsOneWidget,
    );

    final rescue = find.byKey(const ValueKey('exercise-recheck-rescue'));
    await tester.ensureVisible(rescue);
    await tester.pump();
    await tester.tap(rescue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-image-17')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 16 remains usable across supported phone sizes',
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
          key: ValueKey('screen-16-${device.name}'),
          initialScreen: 15,
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey('functional-exercise-complete-recheck-screen'),
        ),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 16.',
      );
      final save = find.byKey(const ValueKey('exercise-recheck-save'));
      expect(
        tester.getRect(save).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep Save result visible.',
      );

      final rescue = find.byKey(const ValueKey('exercise-recheck-rescue'));
      await tester.ensureVisible(rescue);
      await tester.pump();
      expect(
        tester.getRect(rescue).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should reach Rescue.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${device.name} should render without Flutter exceptions.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
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
