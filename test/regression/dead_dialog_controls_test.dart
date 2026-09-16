// Proof harness for the protected-action controls on screens 27 and 28.
//
// _TetherHealthAppState builds the MaterialApp, so the State's own `context`
// sits ABOVE it and carries neither a Navigator nor MaterialLocalizations.
// Every showDialog call used that context, so the quitline, call-back consent,
// data-export, account-deletion and sign-out controls threw instead of
// opening — five controls that look live and do nothing.
//
// **Why this drives keys rather than artwork coordinates.** It used to tap the
// centre of each control's rect from `tapTargetsFor`, because screens 27 and 28
// were bitmaps with invisible hit boxes over them. They are widgets now — the
// functional Support hub and Settings screens — so those coordinates land on
// whatever happens to be at that point, which is not a test of anything. The
// defect being guarded is unchanged: a protected control must open a dialog
// rather than throw. Only the way the control is reached has moved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/main.dart';

void main() {
  for (final probe in <({int screen, String key, String label})>[
    (screen: 26, key: 'support-call-quitline', label: 'Call the quitline'),
    (
      screen: 26,
      key: 'support-request-callback',
      label: 'Request a counselor call-back',
    ),
    (
      screen: 27,
      key: 'settings-download-data',
      label: 'Download a copy of your data',
    ),
    (
      screen: 27,
      key: 'settings-delete-account',
      label: 'Delete account and data',
    ),
    (screen: 27, key: 'settings-sign-out', label: 'Sign out'),
  ]) {
    testWidgets('"${probe.label}" opens its dialog instead of throwing',
        (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(TetherHealthApp(initialScreen: probe.screen));
      await tester.pumpAndSettle();

      final control = find.byKey(ValueKey(probe.key));
      expect(
        control,
        findsOneWidget,
        reason: '${probe.label} is not on screen ${probe.screen + 1}',
      );

      // These screens scroll, and a control below the fold cannot be tapped.
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();

      // The control must not throw, and a dialog must actually be on screen.
      expect(
        tester.takeException(),
        isNull,
        reason: '${probe.label} threw instead of opening its dialog',
      );
      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason: '${probe.label} opened no dialog',
      );
    });
  }
}
