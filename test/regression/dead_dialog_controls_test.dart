// Proof harness for the protected-action controls on screens 27 and 28.
//
// _BreatheFreeAppState builds the MaterialApp, so the State's own `context`
// sits ABOVE it and carries neither a Navigator nor MaterialLocalizations.
// Every showDialog call used that context, so the quitline, call-back consent,
// data-export, account-deletion and sign-out controls threw instead of
// opening — five controls that look live and do nothing.

import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/models/tap_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Taps the centre of [target]'s normalized rect on the rendered screen.
Future<void> tapTarget(WidgetTester tester, AppTapTarget target) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.tapAt(
    Offset(
      (target.normalizedRect.left + target.normalizedRect.width / 2) *
          size.width,
      (target.normalizedRect.top + target.normalizedRect.height / 2) *
          size.height,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final probe in <({int screen, String label})>[
    (screen: 26, label: 'Call 1-800-QUIT-NOW'),
    (screen: 26, label: 'Request a counselor call-back'),
    (screen: 27, label: 'Download a copy of your data'),
    (screen: 27, label: 'Delete account and data'),
    (screen: 27, label: 'Sign out'),
  ]) {
    testWidgets('"${probe.label}" opens its dialog instead of throwing',
        (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(BreatheFreeApp(initialScreen: probe.screen));
      await tester.pumpAndSettle();

      final target =
          tapTargetsFor(probe.screen).firstWhere((t) => t.label == probe.label);
      await tapTarget(tester, target);

      // The control must not throw, and a dialog must actually be on screen.
      expect(tester.takeException(), isNull,
          reason: '${probe.label} threw instead of opening its dialog');
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: '${probe.label} opened no dialog');
    });
  }
}
