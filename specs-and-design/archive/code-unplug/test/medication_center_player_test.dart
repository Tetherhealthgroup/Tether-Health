import 'package:tether_health/models/tap_target.dart';
import 'package:tether_health/screens/approved_screen_player.dart';
import 'package:tether_health/screens/medication_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Screen 24 is wired into ApprovedScreenPlayer at index 23',
      (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey<_PlayerHarnessState>();

    await tester.pumpWidget(_PlayerHarness(key: key));
    await tester.pumpAndSettle();

    expect(find.byType(MedicationCenterScreen), findsOneWidget);
    expect(key.currentState!.currentIndex, 23);

    await tester.tap(
      find.byKey(const ValueKey('medication-nav-home')),
    );
    expect(key.currentState!.currentIndex, 21);

    key.currentState!.goTo(23);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('medication-nav-learn')),
    );
    expect(key.currentState!.currentIndex, 24);

    key.currentState!.goTo(23);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('medication-nav-progress')),
    );
    expect(key.currentState!.currentIndex, 25);

    key.currentState!.goTo(23);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('medication-nav-support')),
    );
    expect(key.currentState!.currentIndex, 26);

    expect(tester.takeException(), isNull);
  });
}

class _PlayerHarness extends StatefulWidget {
  const _PlayerHarness({super.key});

  @override
  State<_PlayerHarness> createState() => _PlayerHarnessState();
}

class _PlayerHarnessState extends State<_PlayerHarness> {
  int currentIndex = 23;
  final List<int> history = <int>[];

  void goTo(int index) {
    if (index == currentIndex) return;
    setState(() {
      history.add(currentIndex);
      currentIndex = index;
    });
  }

  void goBack() {
    if (history.isNotEmpty) {
      setState(() => currentIndex = history.removeLast());
      return;
    }
    if (currentIndex > 0) {
      setState(() => currentIndex -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ApprovedScreenPlayer(
        currentIndex: currentIndex,
        onSelectScreen: goTo,
        onPrevious: goBack,
        onNext: () => goTo(currentIndex + 1),
        onTarget: (AppTapTarget _) {},
      ),
    );
  }
}
