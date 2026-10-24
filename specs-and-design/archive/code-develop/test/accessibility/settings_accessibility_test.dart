import 'package:breathefree_patient/models/tap_target.dart';
import 'package:breathefree_patient/screens/approved_screen_player.dart';
import 'package:breathefree_patient/screens/settings_privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings supports 200 percent text scaling and data semantics',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          home: SettingsPrivacyScreen(
            isSpanish: false,
            remindersEnabled: true,
            sensitiveDetailsEnabled: false,
            diagnosticsEnabled: false,
            reduceMotionEnabled: false,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-download-data')),
    );
    expect(
      find.bySemanticsLabel(
        'Download a copy. Your profile and saved plan · JSON. Request',
      ),
      findsOneWidget,
    );
  });

  testWidgets('reduce motion preference sets the descendant media flag',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ApprovedScreenPlayer(
          currentIndex: 27,
          onSelectScreen: (_) {},
          onPrevious: () {},
          onNext: () {},
          onTarget: (AppTapTarget _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final settings =
        find.byKey(const ValueKey('functional-settings-privacy-screen'));
    expect(MediaQuery.disableAnimationsOf(tester.element(settings)), isFalse);

    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-reduce-motion')),
    );
    await tester.tap(find.byKey(const ValueKey('settings-reduce-motion')));
    await tester.pump();

    expect(MediaQuery.disableAnimationsOf(tester.element(settings)), isTrue);
  });
}
