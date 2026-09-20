import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/models/tap_target.dart';
import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:breathefree_patient/profile/profile_repository.dart';
import 'package:breathefree_patient/profile/user_profile.dart';
import 'package:breathefree_patient/quit_plan/guest_quit_plan_store.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_api_client.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_controller.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_repository.dart';
import 'package:breathefree_patient/screens/approved_screen_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saved guest plan restores to review after app restart',
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
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _QuitPlanApi()),
      guestStore: _GuestStore(
        GuestQuitPlanSnapshot(
          plan: _plan(),
          stage: GuestPlanStage.draft,
          savedAt: DateTime.utc(2026, 9, 19),
        ),
      ),
    );
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(BreatheFreeApp(
      accountController: account,
      quitPlanController: quitPlan,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('functional-review-quit-plan-screen')),
        findsOneWidget);
    expect(find.textContaining('Synthetic Support'), findsOneWidget);
  });

  testWidgets('started guest plan restores to home after app restart',
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
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _QuitPlanApi()),
      guestStore: _GuestStore(
        GuestQuitPlanSnapshot(
          plan: _plan(),
          stage: GuestPlanStage.active,
          savedAt: DateTime.utc(2026, 9, 19),
        ),
      ),
    );
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(BreatheFreeApp(
      accountController: account,
      quitPlanController: quitPlan,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('functional-home-preparation-screen')),
        findsOneWidget);
  });

  testWidgets('signed-in guest import requires explicit upload consent',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const auth = _Auth();
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _ProfileApi()),
    );
    final store = _GuestStore(
      GuestQuitPlanSnapshot(
        plan: _plan(),
        stage: GuestPlanStage.draft,
        savedAt: DateTime.utc(2026, 9, 19),
      ),
    );
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _EmptyQuitPlanApi()),
      guestStore: store,
    );
    expect(await quitPlan.initialize(), isTrue);
    expect(quitPlan.guestMergeStatus, GuestPlanMergeStatus.pendingUpload);
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(MaterialApp(
      home: ApprovedScreenPlayer(
        currentIndex: 27,
        accountController: account,
        quitPlanController: quitPlan,
        onSelectScreen: (_) {},
        onPrevious: () {},
        onNext: () {},
        onTarget: (AppTapTarget _) {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-device-plan-actions')),
    );
    await tester.tap(
      find.byKey(const ValueKey('settings-device-plan-actions')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings-backup-device-plan')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Back up your device plan?'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(store.snapshot, isNotNull);
    expect(quitPlan.guestMergeStatus, GuestPlanMergeStatus.pendingUpload);
  });

  testWidgets('using device plan does not perform a stale second cloud save',
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
    final guestPlan = _plan(topReason: 'future');
    final store = _GuestStore(
      GuestQuitPlanSnapshot(
        plan: guestPlan,
        stage: GuestPlanStage.draft,
        savedAt: DateTime.utc(2026, 9, 19),
      ),
    );
    final api = _ConflictQuitPlanApi();
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: api),
      guestStore: store,
    );
    expect(await quitPlan.initialize(), isTrue);
    expect(quitPlan.guestMergeStatus, GuestPlanMergeStatus.conflict);
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
    await tester.tap(find.text('Use device plan'));
    await tester.pumpAndSettle();

    expect(api.putCount, 1);
    expect(api.saved?.topQuitReason, 'future');
    expect(store.snapshot, isNull);
    expect(profileApi.update?['onboardingCompleted'], isTrue);
    expect(advanced, isTrue);
  });

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

class _GuestStore implements GuestQuitPlanStore {
  _GuestStore(this.snapshot);

  GuestQuitPlanSnapshot? snapshot;

  @override
  bool get isPersistent => true;

  @override
  Future<void> clear() async => snapshot = null;

  @override
  Future<GuestQuitPlanSnapshot?> load() async => snapshot;

  @override
  Future<void> save(GuestQuitPlanSnapshot value) async => snapshot = value;
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
  Future<AuthSignUpResult> signUp(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> resendSignUpConfirmation({required String email}) =>
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
  Future<AuthSignUpResult> signUp(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> resendSignUpConfirmation({required String email}) =>
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

class _EmptyQuitPlanApi implements QuitPlanApiClient {
  @override
  Future<QuitPlan> createQuitPlan(String accessToken, QuitPlan plan) async =>
      plan;

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) =>
      Future.error(const QuitPlanApiException(404));

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) async => plan;
}

class _ConflictQuitPlanApi implements QuitPlanApiClient {
  QuitPlan? saved;
  var putCount = 0;

  @override
  Future<QuitPlan> createQuitPlan(String accessToken, QuitPlan plan) =>
      Future.error(const QuitPlanApiException(409));

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) async => _plan();

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) async {
    putCount++;
    return saved = plan;
  }
}

class _QuitPlanApi implements QuitPlanApiClient {
  QuitPlan? saved;

  @override
  Future<QuitPlan> createQuitPlan(String accessToken, QuitPlan plan) async =>
      saved = plan;

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

QuitPlan _plan({String topReason = 'family'}) => QuitPlan(
      userId: '00000000-0000-0000-0000-000000000001',
      dailyCigaretteUse: 'tenOrFewer',
      smokingTriggers: const ['stress'],
      customSmokingTrigger: null,
      readinessPath: 'prepare',
      quitPlanPath: 'setQuitDate',
      quitDate: DateTime(2026, 10, 1),
      quitDayCheckIn: true,
      quitReasons: [topReason],
      customQuitReason: null,
      topQuitReason: topReason,
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
