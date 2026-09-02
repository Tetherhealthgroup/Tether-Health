// E2E tier — the whole app on a real device or emulator.
//
// Unlike the widget tiers, this runs against the real Flutter engine with real
// platform channels: flutter_tts and url_launcher register for real, and the
// MaterialApp supplies real MaterialLocalizations.
//
// That last point is why this tier matters here. The protected-action controls
// on screens 27 and 28 threw "No MaterialLocalizations found" because
// showDialog was called with a context above the MaterialApp. A widget test
// can catch it, but only if someone writes that test; on a device it is the
// difference between a control that opens and a control that does nothing.
//
//   flutter test integration_test/app_e2e_test.dart -d <device>
//
// Requires an attached device; there is no headless fallback.

import 'package:breathefree_patient/config/contact_info.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/models/screen_spec.dart';
import 'package:breathefree_patient/models/tap_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Taps the centre of [target]'s normalized rectangle on the live surface.
Future<void> _tapTarget(WidgetTester tester, AppTapTarget target) async {
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the app launches on device and shows the welcome screen',
      (tester) async {
    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();

    expect(find.text('Your next breath can be different.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding advances from Screen 1 to Screen 2 on device',
      (tester) async {
    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();

    final getStarted = find.byKey(const ValueKey('welcome-get-started'));
    await tester.ensureVisible(getStarted);
    await tester.tap(getStarted);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('functional-why-breathefree-screen')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'both quitline controls open their own dialog under the real '
      'engine', (tester) async {
    // The regression this tier exists for: a real MaterialApp, real
    // localizations, and a dialog that must actually appear.
    for (final quitline in ContactInfo.quitlines) {
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 26));
      await tester.pumpAndSettle();

      final target = tapTargetsFor(26).firstWhere(
        (t) =>
            t.action == TapAction.quitline &&
            t.quitline?.language == quitline.language,
      );
      await _tapTarget(tester, target);

      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason: 'the ${quitline.language} quitline opened no dialog',
      );
      expect(find.textContaining(quitline.vanityNumber), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the settings protected actions open on device', (tester) async {
    for (final label in <String>[
      'Download a copy of your data',
      'Delete account and data',
    ]) {
      await tester.pumpWidget(const BreatheFreeApp(initialScreen: 27));
      await tester.pumpAndSettle();

      final target = tapTargetsFor(27).firstWhere((t) => t.label == label);
      await _tapTarget(tester, target);

      expect(
        find.byType(AlertDialog),
        findsOneWidget,
        reason: '"$label" opened no dialog on device',
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('every approved screen mounts on device without throwing',
      (tester) async {
    // The asset pipeline is real here: each screen loads its approved bitmap
    // from the installed bundle rather than a test stub.
    for (var screen = 0; screen < approvedScreens.length; screen++) {
      await tester.pumpWidget(BreatheFreeApp(initialScreen: screen));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'screen ${screen + 1} threw while mounting on device',
      );
    }
  });
}
