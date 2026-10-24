import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tether_health/screens/approved_screen_player.dart';
import 'package:tether_health/screens/craving_rescue_start_screen.dart';

void main() {
  testWidgets(
    'Screen 23 Save and start recovery opens Craving Rescue and preserves saved state',
    (tester) async {
      final harnessKey = GlobalKey<_NavigationHarnessState>();

      await tester.pumpWidget(
        _NavigationHarness(key: harnessKey),
      );
      await tester.pumpAndSettle();

      // Before the slip is saved, "Open after saving" must be disabled.
      final openBeforeSave = tester.widget<TextButton>(
        find.byKey(const ValueKey('slip-recovery-open-next-step')),
      );
      expect(openBeforeSave.onPressed, isNull);

      // Main CTA should save and immediately launch the Craving Rescue flow.
      final saveButton = find.byKey(const ValueKey('slip-recovery-save'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(CravingRescueStartScreen), findsOneWidget);
      expect(harnessKey.currentState!.currentIndex, 16);

      // Simulate returning to Screen 23. ApprovedScreenPlayer stays mounted,
      // so its saved-state flag must still be preserved.
      harnessKey.currentState!.goTo(22);
      await tester.pumpAndSettle();

      final openAfterSave = tester.widget<TextButton>(
        find.byKey(const ValueKey('slip-recovery-open-next-step')),
      );
      expect(openAfterSave.onPressed, isNotNull);

      // "Open after saving" should now launch Craving Rescue.
      await tester.ensureVisible(
        find.byKey(const ValueKey('slip-recovery-open-next-step')),
      );
      await tester.tap(
        find.byKey(const ValueKey('slip-recovery-open-next-step')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CravingRescueStartScreen), findsOneWidget);
      expect(harnessKey.currentState!.currentIndex, 16);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Screen 23 close and support actions route to the expected indexes',
    (tester) async {
      final harnessKey = GlobalKey<_NavigationHarnessState>();

      await tester.pumpWidget(
        _NavigationHarness(key: harnessKey),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('slip-recovery-close')),
      );
      await tester.pumpAndSettle();
      expect(harnessKey.currentState!.currentIndex, 21);

      harnessKey.currentState!.goTo(22);
      await tester.pumpAndSettle();

      final support = find.byKey(const ValueKey('slip-recovery-support'));
      await tester.ensureVisible(support);
      await tester.tap(support);
      await tester.pumpAndSettle();
      expect(harnessKey.currentState!.currentIndex, 26);

      expect(tester.takeException(), isNull);
    },
  );
}

class _NavigationHarness extends StatefulWidget {
  const _NavigationHarness({super.key});

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

class _NavigationHarnessState extends State<_NavigationHarness> {
  int currentIndex = 22;

  void goTo(int index) {
    setState(() => currentIndex = index);
  }

  void goBack() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ApprovedScreenPlayer(
        currentIndex: currentIndex,
        onSelectScreen: goTo,
        onPrevious: goBack,
        onNext: () => goTo(currentIndex + 1),
        onTarget: (_) {},
      ),
    );
  }
}
