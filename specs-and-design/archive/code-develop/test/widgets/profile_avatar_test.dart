import 'package:breathefree_patient/screens/quit_day_home_screen.dart';
import 'package:breathefree_patient/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile identity derives initials and first name from display name',
      () {
    const identity = ProfileIdentity(
      signedIn: true,
      displayName: 'Maya Patel',
      email: 'ignored@example.test',
    );

    expect(identity.initials, 'MP');
    expect(identity.firstName, 'Maya');
  });

  test('profile identity falls back to email when a name is unavailable', () {
    const identity = ProfileIdentity(
      signedIn: true,
      email: 'hari.shanmugam@example.test',
    );

    expect(identity.initials, 'HS');
    expect(identity.firstName, 'hari');
  });

  testWidgets('signed-in avatar renders profile initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileAvatar(
            identity: ProfileIdentity(
              signedIn: true,
              displayName: 'Maya Patel',
            ),
          ),
        ),
      ),
    );

    expect(find.text('MP'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile for Maya Patel'), findsOneWidget);
  });

  testWidgets('profile identity drives page avatar and greeting',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuitDayHomeScreen(
          isSpanish: false,
          quitDate: DateTime.now(),
          topReason: null,
          customReason: null,
          supportPeople: const [],
          treatmentSupport: false,
          onOpenRescue: () {},
          onOpenSlipRecovery: () {},
          onOpenDailyCheckIn: () {},
          onOpenPlan: () {},
          onOpenTreatmentPlan: () {},
          onOpenProgress: () {},
          onOpenLearn: () {},
          onOpenSupport: () {},
          onNotifications: () {},
          onOpenProfile: () {},
          profileIdentity: const ProfileIdentity(
            signedIn: true,
            displayName: 'Maya Patel',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('MP'), findsOneWidget);
    expect(
      find.textContaining(
        RegExp(r'^Good (morning|afternoon|evening), Maya\.$'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('signed-out avatar renders a neutral guest state',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileAvatar(identity: ProfileIdentity()),
        ),
      ),
    );

    expect(find.text('A'), findsNothing);
    expect(
      find.byKey(const ValueKey('profile-avatar-fallback-icon')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Guest profile'), findsOneWidget);
  });
}
