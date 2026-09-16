import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/models/tap_target.dart';
import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:breathefree_patient/profile/profile_repository.dart';
import 'package:breathefree_patient/profile/user_profile.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_api_client.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_controller.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_repository.dart';
import 'package:breathefree_patient/screens/approved_screen_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('configured signed-out guest can start a nonpersistent plan',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const auth = _SignedOutAuth();
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _ProfileApi()),
    );
    final quitPlanApi = _QuitPlanApi();
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: quitPlanApi),
    );
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    var advanced = false;
    await tester.pumpWidget(MaterialApp(
      home: ApprovedScreenPlayer(
        currentIndex: 10,
        accountController: account,
        quitPlanController: quitPlan,
        onSelectScreen: (_) {},
        onPrevious: () {},
        onNext: () => advanced = true,
        onTarget: (AppTapTarget _) {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('review-start-plan')));
    await tester.tap(find.byKey(const ValueKey('review-start-plan')));
    await tester.pumpAndSettle();

    expect(quitPlanApi.saved, isNull);
    expect(quitPlan.plan, isNotNull);
    expect(advanced, isTrue);
  });

  testWidgets('Start Plan saves the full plan before completing onboarding',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const auth = _Auth();
    final profileApi = _ProfileApi();
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: profileApi),
    );
    final quitPlanApi = _QuitPlanApi();
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: quitPlanApi),
    );
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    var advanced = false;
    await tester.pumpWidget(MaterialApp(
      home: ApprovedScreenPlayer(
        currentIndex: 10,
        accountController: account,
        quitPlanController: quitPlan,
        onSelectScreen: (_) {},
        onPrevious: () {},
        onNext: () => advanced = true,
        onTarget: (AppTapTarget _) {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('review-start-plan')));
    await tester.tap(find.byKey(const ValueKey('review-start-plan')));
    await tester.pumpAndSettle();

    expect(quitPlanApi.saved, isNotNull);
    expect(quitPlanApi.saved!.quitReasons, contains('family'));
    expect(profileApi.update?['onboardingCompleted'], isTrue);
    expect(advanced, isTrue);
  });

  testWidgets('restored plan repopulates the review screen', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const auth = _Auth();
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _QuitPlanApi()),
    );
    addTearDown(quitPlan.dispose);
    expect(await quitPlan.initialize(), isTrue);

    await tester.pumpWidget(MaterialApp(
      home: ApprovedScreenPlayer(
        currentIndex: 10,
        quitPlanController: quitPlan,
        onSelectScreen: (_) {},
        onPrevious: () {},
        onNext: () {},
        onTarget: (AppTapTarget _) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Synthetic Support'), findsOneWidget);
    expect(find.textContaining('October'), findsWidgets);
  });
}

class _Auth implements AuthGateway {
  const _Auth();

  @override
  AuthIdentity? get currentIdentity => const AuthIdentity(
        id: '00000000-0000-0000-0000-000000000001',
        email: 'synthetic@example.test',
        accessToken: 'test-token',
      );

  @override
  Future<AuthIdentity> signIn(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class _SignedOutAuth implements AuthGateway {
  const _SignedOutAuth();

  @override
  AuthIdentity? get currentIdentity => null;

  @override
  Future<AuthIdentity> signIn(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class _ProfileApi implements ProfileApiClient {
  Map<String, Object?>? update;

  @override
  Future<UserProfile> getProfile(String accessToken) async => _profile(false);

  @override
  Future<UserProfile> updateProfile(
    String accessToken,
    Map<String, Object?> update,
  ) async {
    this.update = update;
    return _profile(update['onboardingCompleted'] == true);
  }
}

class _QuitPlanApi implements QuitPlanApiClient {
  QuitPlan? saved;

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) async => _plan();

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) async =>
      saved = plan;
}

UserProfile _profile(bool completed) => UserProfile(
      id: '00000000-0000-0000-0000-000000000001',
      displayName: 'Synthetic User',
      locale: 'en',
      timeZone: 'America/Los_Angeles',
      onboardingCompleted: completed,
      avatarPath: null,
      createdAt: DateTime.utc(2026, 9, 15),
      updatedAt: DateTime.utc(2026, 9, 15),
    );

QuitPlan _plan() => QuitPlan(
      userId: '00000000-0000-0000-0000-000000000001',
      dailyCigaretteUse: 'tenOrFewer',
      smokingTriggers: const ['stress'],
      customSmokingTrigger: null,
      readinessPath: 'prepare',
      quitPlanPath: 'setQuitDate',
      quitDate: DateTime(2026, 10, 1),
      quitDayCheckIn: true,
      quitReasons: const ['family'],
      customQuitReason: null,
      topQuitReason: 'family',
      supportPeople: const [
        QuitPlanSupportPerson(
          id: 'synthetic-support',
          name: 'Synthetic Support',
          relationship: 'Friend',
          channel: 'text',
          checkIn: 'Check in the evening before my quit date',
          enabled: true,
        ),
      ],
      preparationTasks: const ['removeSupplies'],
      treatmentSupport: true,
      careTeamReminder: true,
    );
