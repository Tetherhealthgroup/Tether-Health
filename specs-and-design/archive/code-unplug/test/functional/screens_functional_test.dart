// Functional — each feature through the API a screen actually calls.
//
// Extracted from the original flat test/widget_test.dart; each test was
// already self-contained, so behaviour is unchanged.

import 'package:tether_health/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Screen 1 language control switches to Spanish', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp());
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 1));
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
      const TetherHealthApp(
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 1));
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

  testWidgets('Screen 3 opens the privacy review and continues to Screen 4',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 2));
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

  testWidgets('Screen 4 Next continues to Screen 5', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 3));
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

  testWidgets('Screen 5 saves a custom trigger and continues to Screen 6',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 4));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 3));
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

  testWidgets('Screen 7 Continue advances to Screen 8', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 6));
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

    await tester.pumpWidget(const TetherHealthApp());
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

  testWidgets('Screen 8 adapts to Quit today and Reduce gradually paths',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 6));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 7));
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

  testWidgets('Screen 9 custom reason can become the top motivation',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 8));
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

    await tester.pumpWidget(const TetherHealthApp());
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

    final openRescue = find.byKey(const ValueKey('exercise-recheck-rescue'));
    await tester.ensureVisible(openRescue);
    await tester.tap(openRescue);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );
    expect(find.text('Rescate del antojo'), findsOneWidget);
    expect(find.text('Superemos este momento.'), findsOneWidget);
    expect(find.text('Muéstrame qué hacer'), findsOneWidget);
    expect(find.text('“Proteger a mi familia.”'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 10 can add and edit support people', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 9));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 9));
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

  testWidgets('Screen 11 reviews the saved plan and starts Screen 12',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 10));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 10));
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

  testWidgets('Screen 12 shows the activated plan and completes its next task',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 11));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 11));
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
      (
        key: 'preparation-open-rescue',
        imageKey: 'functional-craving-rescue-start-screen',
      ),
      (
        key: 'preparation-nav-progress',
        imageKey: 'functional-progress-dashboard-screen'
      ),
      (key: 'preparation-nav-learn', imageKey: 'learn-library-screen'),
      (
        key: 'preparation-nav-support',
        imageKey: 'functional-support-hub-screen'
      ),
      (
        key: 'preparation-profile',
        imageKey: 'functional-settings-privacy-screen'
      ),
    ];

    for (final destination in destinations) {
      await tester.pumpWidget(
        TetherHealthApp(
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
      const TetherHealthApp(
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

  testWidgets('Screen 12 notification opens Screen 13 and close returns home',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 11));
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

  testWidgets('Screen 13 smoking choices and Rescue navigation work',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 12));
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
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('rescue-start-close')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-daily-check-in-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Screen 14 uses the saved check-in recommendation and explains it',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 13));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 13));
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
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('rescue-start-close')));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 13));
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
    expect(find.byKey(const ValueKey('functional-support-hub-screen')),
        findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(urge);
    await tester.pumpAndSettle();
    await tester.tap(urge);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-step-open-rescue')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 14 changes its automatic suggestion with check-in data',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 12));
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

  testWidgets('Screen 6 inherits Spanish from onboarding', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp());
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

  testWidgets('Screen 5 inherits Spanish from onboarding', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp());
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

  testWidgets('Screen 4 inherits Spanish from onboarding', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp());
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 14));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 14));
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
        const ValueKey('functional-exercise-complete-recheck-screen'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 15 saves partial progress when leaving', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 14));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 14));
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
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 16 shows an honest completion recheck', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const TetherHealthApp(
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 15));
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 15));
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
      const TetherHealthApp(
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

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 15));
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
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 17 starts with an honest personalized Rescue state',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 16));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );
    expect(find.text('Craving Rescue'), findsOneWidget);
    expect(find.text('OFFLINE READY'), findsOneWidget);
    expect(find.text('Let’s get through this moment.'), findsOneWidget);
    expect(find.text('How strong is it right now?'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('MODERATE'), findsOneWidget);
    expect(find.text('“Protect my family.”'), findsOneWidget);
    expect(find.text('Contact Jordan or a trained quitline counselor.'),
        findsOneWidget);

    await tester.fling(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
      reason: 'Screen 17 should require an explicit action.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 17 rating and optional contexts update safely',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 16));
    await tester.pumpAndSettle();

    final slider = find.byKey(const ValueKey('rescue-start-intensity-slider'));
    tester.widget<Slider>(slider).onChanged!(8);
    await tester.pump();
    expect(find.text('8'), findsOneWidget);
    expect(find.text('STRONG'), findsOneWidget);

    final stress = find.byKey(const ValueKey('rescue-start-context-stress'));
    final afterMeal =
        find.byKey(const ValueKey('rescue-start-context-afterMeal'));
    await tester.ensureVisible(stress);
    await tester.pump();
    await tester.tap(stress);
    await tester.pump();
    await tester.tap(afterMeal);
    await tester.pump();
    expect(tester.widget<FilterChip>(stress).selected, isTrue);
    expect(tester.widget<FilterChip>(afterMeal).selected, isTrue);

    final notSure = find.byKey(const ValueKey('rescue-start-context-notSure'));
    await tester.tap(notSure);
    await tester.pump();
    expect(tester.widget<FilterChip>(notSure).selected, isTrue);
    expect(tester.widget<FilterChip>(stress).selected, isFalse);
    expect(tester.widget<FilterChip>(afterMeal).selected, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 17 continues explicitly and keeps choices on return',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 16));
    await tester.pumpAndSettle();

    final slider = find.byKey(const ValueKey('rescue-start-intensity-slider'));
    tester.widget<Slider>(slider).onChanged!(9);
    await tester.pump();
    final driving = find.byKey(const ValueKey('rescue-start-context-driving'));
    await tester.ensureVisible(driving);
    await tester.tap(driving);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('rescue-start-continue')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-recommended-rescue-tool-screen')),
      findsOneWidget,
    );

    final rescueToolBack = find.byKey(const ValueKey('rescue-tool-back'));
    tester.widget<IconButton>(rescueToolBack).onPressed!();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );
    expect(find.text('9'), findsOneWidget);
    expect(tester.widget<FilterChip>(driving).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 17 support and emergency guidance are explicit',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 16));
    await tester.pumpAndSettle();

    final support = find.byKey(const ValueKey('rescue-start-support'));
    await tester.ensureVisible(support);
    await tester.tap(support);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('functional-support-hub-screen')),
        findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rescue-start-emergency')));
    await tester.pumpAndSettle();
    expect(find.text('Medical emergency'), findsOneWidget);
    expect(find.textContaining('call 911 now'), findsOneWidget);
    expect(
      find.text('BreatheFree will only start a call when you tap “Call 911.”'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('rescue-start-emergency-done')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 18 shows the personalized recommended rescue tool',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 17));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-recommended-rescue-tool-screen')),
      findsOneWidget,
    );
    expect(find.text('Craving Rescue'), findsOneWidget);
    expect(find.text('2 OF 5'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Start with what helped before.'), findsOneWidget);
    expect(find.text('Slow breathing'), findsOneWidget);
    expect(find.text('2:00'), findsOneWidget);
    expect(
      find.text('Slow breathing was selected as most helpful.'),
      findsOneWidget,
    );
    expect(find.text('Start 2-minute breathing'), findsOneWidget);
    expect(find.text('Move for 3 minutes'), findsOneWidget);
    expect(find.text('Change the scene'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 18 lets the patient choose another action and keeps it',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 17));
    await tester.pumpAndSettle();

    final move = find.byKey(const ValueKey('rescue-tool-move'));
    final moveInkWell = find.descendant(
      of: move,
      matching: find.byType(InkWell),
    );
    tester.widget<InkWell>(moveInkWell).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Start 3-minute movement'), findsOneWidget);

    final rescueToolBack = find.byKey(const ValueKey('rescue-tool-back'));
    tester.widget<IconButton>(rescueToolBack).onPressed!();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-craving-rescue-start-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('rescue-start-continue')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-recommended-rescue-tool-screen')),
      findsOneWidget,
    );
    expect(find.text('Start 3-minute movement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 18 explains the match and opens support', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 17));
    await tester.pumpAndSettle();

    final why = find.byKey(const ValueKey('rescue-tool-why-match'));
    tester.widget<InkWell>(why).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Why this match?'), findsWidgets);
    expect(find.byKey(const ValueKey('rescue-tool-why-done')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rescue-tool-why-done')));
    await tester.pumpAndSettle();

    final support = find.byKey(const ValueKey('rescue-tool-support'));
    tester.widget<FilledButton>(support).onPressed!();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('functional-support-hub-screen')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 18 start action continues to active Rescue Screen 19',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 17));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rescue-tool-start')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('functional-active-craving-rescue-screen'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 19 renders the active craving rescue exercise',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 18));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('functional-active-craving-rescue-screen'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('active-rescue-time-left')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('active-rescue-breath-circle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('active-rescue-phase')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('active-rescue-countdown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('active-rescue-progress')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 19 pause and resume controls work', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 18));
    await tester.pumpAndSettle();

    final pause = find.byKey(const ValueKey('active-rescue-pause'));
    expect(pause, findsOneWidget);

    await tester.tap(pause);
    await tester.pump();

    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(pause);
    await tester.pump();

    expect(find.text('Pause'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 19 voice and haptics controls toggle', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 18));
    await tester.pumpAndSettle();

    final voice = find.byKey(const ValueKey('active-rescue-voice'));
    final haptics = find.byKey(const ValueKey('active-rescue-haptics'));

    expect(voice, findsOneWidget);
    expect(haptics, findsOneWidget);

    await tester.tap(voice);
    await tester.pump();

    await tester.tap(haptics);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 19 switch tool returns to Recommended Rescue Tool',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 18));
    await tester.pumpAndSettle();

    final switchTool = find.byKey(const ValueKey('active-rescue-switch-tool'));

    await tester.ensureVisible(switchTool);
    await tester.tap(switchTool);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('functional-recommended-rescue-tool-screen'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 20 renders the craving recheck', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 19));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-craving-recheck-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('craving-recheck-progress')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('craving-recheck-result-card')),
      findsOneWidget,
    );
    // The recheck must never read as a measurement.
    expect(find.text('Not a medical measurement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 20 rating is reachable by number and by slider',
      (tester) async {
    /* The artwork promises "Tap a number or drag the slider". Both routes are
       asserted because the number row is the accessible path: someone who
       cannot land a slider thumb precisely has no other way to answer a
       question the screen marks Required. */
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 19));
    await tester.pumpAndSettle();

    // Every number 0-10 is present, not just a representative few.
    for (var number = 0; number <= 10; number++) {
      expect(
        find.byKey(ValueKey('craving-recheck-number-$number')),
        findsOneWidget,
        reason: 'rating $number should be tappable',
      );
    }

    await tester.tap(find.byKey(const ValueKey('craving-recheck-number-8')));
    await tester.pumpAndSettle();
    expect(find.text('8 · Strong'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('craving-recheck-number-0')));
    await tester.pumpAndSettle();
    expect(find.text('0 · None'), findsOneWidget);

    // The slider drives the same value. It sits below the fold, and drag()
    // silently misses an off-screen target, so scroll to it first.
    final slider = find.byKey(const ValueKey('craving-recheck-slider'));
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    await tester.drag(slider, const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('0 · None'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 20 offers stronger support only at 7-10', (tester) async {
    /* The artwork reserves this space with "If you select 7-10, stronger
       support appears here". A high rating has to surface a route to a person,
       not merely be recorded and carried forward. */
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 19));
    await tester.pumpAndSettle();

    final support = find.byKey(
      const ValueKey('craving-recheck-stronger-support'),
    );

    // Each rating is scrolled into view before it is tapped: the card
    // appearing and ensureVisible() below both move the number row, and tap()
    // silently misses a target that has left the viewport.
    Future<void> rate(int number) async {
      final target = find.byKey(ValueKey('craving-recheck-number-$number'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await rate(6);
    expect(support, findsNothing, reason: '6 is below the threshold');

    await rate(7);
    expect(support, findsOneWidget, reason: '7 is the threshold the art names');

    await tester.ensureVisible(support);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('craving-recheck-open-support')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('craving-recheck-switch-tool')),
      findsOneWidget,
    );

    await rate(3);
    expect(support, findsNothing, reason: 'lowering the rating retires it');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 20 helpful answer is optional and can be cleared',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 19));
    await tester.pumpAndSettle();

    // Untouched, the screen states no consequence it cannot deliver.
    expect(
      find.text('You can tell us whether it helped whenever you’re ready.'),
      findsOneWidget,
    );

    final yes = find.byKey(const ValueKey('craving-recheck-helpful-yes'));
    await tester.ensureVisible(yes);
    await tester.pumpAndSettle();
    await tester.tap(yes);
    await tester.pumpAndSettle();
    expect(
      find.text('We’ll remember that slow breathing helped with stress.'),
      findsOneWidget,
    );

    // Tapping the same answer again clears it — the field is optional.
    await tester.tap(yes);
    await tester.pumpAndSettle();
    expect(
      find.text('You can tell us whether it helped whenever you’re ready.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 20 saves onward to Screen 21 and can repeat Screen 19',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Distinct keys force a fresh app state for the second leg. Without them
    // the second pumpWidget updates the existing element, initialScreen is
    // never re-read, and the app stays on Screen 19 from the Repeat above.
    await tester.pumpWidget(
      const TetherHealthApp(
          key: ValueKey('screen-20-repeat'), initialScreen: 19),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('craving-recheck-repeat')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-active-craving-rescue-screen')),
      findsOneWidget,
      reason: 'Repeat should return to the Screen 19 exercise',
    );

    await tester.pumpWidget(
      const TetherHealthApp(key: ValueKey('screen-20-save'), initialScreen: 19),
    );
    await tester.pumpAndSettle();

    final save = find.byKey(const ValueKey('craving-recheck-save'));
    expect(save, findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('functional-craving-recheck-screen')),
      findsNothing,
      reason: 'Save should advance past the recheck to Screen 21',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 20 remains usable across supported phone sizes',
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
        TetherHealthApp(
          key: ValueKey('screen-20-${device.name}'),
          initialScreen: 19,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('functional-craving-recheck-screen')),
        findsOneWidget,
        reason: '${device.name} should display functional Screen 20.',
      );

      final save = find.byKey(const ValueKey('craving-recheck-save'));
      expect(
        tester.getRect(save).overlaps(Offset.zero & device.size),
        isTrue,
        reason: '${device.name} should keep the primary action visible.',
      );

      // The rating is Required, so the extremes of the scale must be reachable
      // on the narrowest supported device, not merely present in the tree.
      for (final number in <int>[0, 10]) {
        final target = find.byKey(
          ValueKey('craving-recheck-number-$number'),
        );
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(target).overlaps(Offset.zero & device.size),
          isTrue,
          reason: '${device.name} should be able to reach rating $number.',
        );
      }

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('laptop view exposes all screens and developer navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TetherHealthApp(initialScreen: 27));
    await tester.pump();

    expect(find.text('28 approved screens'), findsOneWidget);
    expect(find.text('Screen 28 · Settings & privacy'), findsOneWidget);
    expect(find.text('Show tap areas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
