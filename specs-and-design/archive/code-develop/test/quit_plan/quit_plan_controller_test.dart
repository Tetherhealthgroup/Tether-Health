import 'dart:async';

import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/quit_plan/guest_quit_plan_store.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_api_client.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_controller.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing remote plan is a valid first-onboarding state', () async {
    const auth = _Auth();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _NotFoundApi()),
    );
    addTearDown(controller.dispose);

    expect(await controller.initialize(), isTrue);
    expect(controller.plan, isNull);
    expect(controller.errorMessage, isNull);
  });

  test('configured signed-out guests keep a nonpersistent plan', () async {
    const auth = _SignedOutAuth();
    final api = _RecordingApi();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: api),
    );
    addTearDown(controller.dispose);

    expect(await controller.save(_plan()), isTrue);
    expect(controller.plan?.quitReasons, ['family']);
    expect(api.saved, isNull);
    expect(controller.errorMessage, isNull);
  });

  test('unreadable encrypted snapshot is preserved until explicit deletion',
      () async {
    const auth = _SignedOutAuth();
    final store = _CorruptGuestStore();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _RecordingApi()),
      guestStore: store,
    );
    addTearDown(controller.dispose);

    expect(await controller.initialize(), isFalse);
    expect(controller.hasGuestPlanRecoveryIssue, isTrue);
    expect(controller.hasStoredGuestPlan, isTrue);
    expect(await controller.save(_plan()), isFalse);
    expect(store.saveCount, 0);
    expect(store.cleared, isFalse);

    await controller.clearGuestPlan();
    expect(store.cleared, isTrue);
    expect(controller.hasGuestPlanRecoveryIssue, isFalse);
    expect(await controller.save(_plan()), isTrue);
    expect(store.saveCount, 1);
  });

  test('guest plan persists securely and restores its active state', () async {
    const auth = _SignedOutAuth();
    final store = _MemoryGuestStore();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _RecordingApi()),
      guestStore: store,
    );
    addTearDown(controller.dispose);

    expect(await controller.save(_plan()), isTrue);
    expect(await controller.markStarted(), isTrue);
    expect(store.snapshot?.stage, GuestPlanStage.active);

    controller.clear();
    expect(await controller.initialize(), isTrue);
    expect(controller.plan?.topQuitReason, 'family');
    expect(controller.guestPlanStarted, isTrue);
    expect(controller.savedOnDeviceOnly, isTrue);
  });

  test('guest plan uploads when the signed-in account has no cloud plan',
      () async {
    const auth = _Auth();
    final guest = GuestQuitPlanSnapshot(
      plan: _plan(topReason: 'future'),
      stage: GuestPlanStage.active,
      savedAt: DateTime.utc(2026, 9, 19),
    );
    final store = _MemoryGuestStore(snapshot: guest);
    final api = _UpsertingNotFoundApi();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: api),
      guestStore: store,
    );
    addTearDown(controller.dispose);

    expect(await controller.initialize(), isTrue);
    expect(controller.guestMergeStatus, GuestPlanMergeStatus.pendingUpload);
    expect(api.saved, isNull);
    expect(store.snapshot, isNotNull);

    expect(await controller.importGuestPlan(), isTrue);
    expect(controller.guestMergeStatus, GuestPlanMergeStatus.uploaded);
    expect(controller.migratedGuestWasStarted, isTrue);
    expect(api.saved?.topQuitReason, 'future');
    expect(store.snapshot, isNull);
  });

  test('pending guest consent blocks ordinary cloud saves', () async {
    const auth = _Auth();
    final store = _MemoryGuestStore(
      snapshot: GuestQuitPlanSnapshot(
        plan: _plan(topReason: 'future'),
        stage: GuestPlanStage.draft,
        savedAt: DateTime.utc(2026, 9, 19),
      ),
    );
    final api = _UpsertingNotFoundApi();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: api),
      guestStore: store,
    );
    addTearDown(controller.dispose);

    expect(await controller.initialize(), isTrue);
    expect(controller.guestMergeStatus, GuestPlanMergeStatus.pendingUpload);
    expect(await controller.save(_plan()), isFalse);
    expect(api.saved, isNull);
    expect(store.snapshot, isNotNull);
    expect(controller.errorMessage, contains('device plan'));
  });

  test('in-flight import cannot cross a sign-out session boundary', () async {
    final auth = _MutableAuth();
    final guest = GuestQuitPlanSnapshot(
      plan: _plan(topReason: 'future'),
      stage: GuestPlanStage.draft,
      savedAt: DateTime.utc(2026, 9, 19),
    );
    final store = _MemoryGuestStore(snapshot: guest);
    final api = _DelayedCreateApi();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: api),
      guestStore: store,
    );
    addTearDown(controller.dispose);

    expect(await controller.initialize(), isTrue);
    final import = controller.importGuestPlan();
    auth.identity = null;
    controller.clear();
    api.createResult.complete(guest.plan);

    expect(await import, isFalse);
    expect(controller.plan, isNull);
    expect(store.snapshot, isNotNull);
  });

  test('create-only guest import turns a concurrent cloud create into conflict',
      () async {
    const auth = _Auth();
    final store = _MemoryGuestStore(
      snapshot: GuestQuitPlanSnapshot(
        plan: _plan(topReason: 'future'),
        stage: GuestPlanStage.draft,
        savedAt: DateTime.utc(2026, 9, 19),
      ),
    );
    final api = _RacingApi();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: api),
      guestStore: store,
    );
    addTearDown(controller.dispose);

    expect(await controller.initialize(), isTrue);
    expect(controller.guestMergeStatus, GuestPlanMergeStatus.pendingUpload);
    expect(await controller.importGuestPlan(), isTrue);
    expect(controller.guestMergeStatus, GuestPlanMergeStatus.conflict);
    expect(controller.plan?.topQuitReason, 'family');
    expect(store.snapshot, isNotNull);
  });

  test('cloud plan wins by default when a guest plan conflicts', () async {
    const auth = _Auth();
    final store = _MemoryGuestStore(
      snapshot: GuestQuitPlanSnapshot(
        plan: _plan(topReason: 'future'),
        stage: GuestPlanStage.draft,
        savedAt: DateTime.utc(2026, 9, 19),
      ),
    );
    final api = _RecordingApi();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: api),
      guestStore: store,
    );
    addTearDown(controller.dispose);

    expect(await controller.initialize(), isTrue);
    expect(controller.guestMergeStatus, GuestPlanMergeStatus.conflict);
    expect(controller.plan?.topQuitReason, 'family');
    expect(api.saved, isNull);
    expect(store.snapshot, isNotNull);

    expect(await controller.replaceCloudWithGuestPlan(), isTrue);
    expect(api.saved?.topQuitReason, 'future');
    expect(store.snapshot, isNull);
  });

  test('saved plan becomes the controller source of truth', () async {
    const auth = _Auth();
    final api = _RecordingApi();
    final controller = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: api),
    );
    addTearDown(controller.dispose);

    expect(await controller.save(_plan()), isTrue);
    expect(api.saved?.quitReasons, ['family']);
    expect(controller.plan?.quitDate, DateTime(2026, 10));
  });
}

class _CorruptGuestStore implements GuestQuitPlanStore {
  var cleared = false;
  var saveCount = 0;

  @override
  bool get isPersistent => true;

  @override
  Future<void> clear() async => cleared = true;

  @override
  Future<GuestQuitPlanSnapshot?> load() async {
    if (cleared) return null;
    throw const GuestQuitPlanStoreException(
      GuestQuitPlanStoreFailure.corrupt,
    );
  }

  @override
  Future<void> save(GuestQuitPlanSnapshot value) async => saveCount++;
}

class _MemoryGuestStore implements GuestQuitPlanStore {
  _MemoryGuestStore({this.snapshot});

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

class _MutableAuth implements AuthGateway {
  AuthIdentity? identity = const AuthIdentity(
    id: '00000000-0000-0000-0000-000000000001',
    email: 'synthetic@example.test',
    accessToken: 'test-token',
  );

  @override
  AuthIdentity? get currentIdentity => identity;

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
  Future<void> signOut() async => identity = null;
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

class _NotFoundApi implements QuitPlanApiClient {
  @override
  Future<QuitPlan> createQuitPlan(String accessToken, QuitPlan plan) =>
      throw UnimplementedError();

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) =>
      Future.error(const QuitPlanApiException(404));

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) =>
      throw UnimplementedError();
}

class _UpsertingNotFoundApi implements QuitPlanApiClient {
  QuitPlan? saved;

  @override
  Future<QuitPlan> createQuitPlan(String accessToken, QuitPlan plan) async =>
      saved = plan;

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) =>
      Future.error(const QuitPlanApiException(404));

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) async =>
      saved = plan;
}

class _DelayedCreateApi implements QuitPlanApiClient {
  final createResult = Completer<QuitPlan>();

  @override
  Future<QuitPlan> createQuitPlan(String accessToken, QuitPlan plan) =>
      createResult.future;

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) =>
      Future.error(const QuitPlanApiException(404));

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) =>
      throw UnimplementedError();
}

class _RacingApi implements QuitPlanApiClient {
  var getCount = 0;

  @override
  Future<QuitPlan> createQuitPlan(String accessToken, QuitPlan plan) =>
      Future.error(const QuitPlanApiException(409));

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) {
    getCount++;
    return getCount == 1
        ? Future.error(const QuitPlanApiException(404))
        : Future.value(_plan());
  }

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) =>
      throw UnimplementedError();
}

class _RecordingApi implements QuitPlanApiClient {
  QuitPlan? saved;

  @override
  Future<QuitPlan> createQuitPlan(String accessToken, QuitPlan plan) =>
      Future.error(const QuitPlanApiException(409));

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) async => _plan();

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) async =>
      saved = plan;
}

QuitPlan _plan({String topReason = 'family'}) => QuitPlan(
      userId: '00000000-0000-0000-0000-000000000001',
      dailyCigaretteUse: 'tenOrFewer',
      smokingTriggers: const ['stress'],
      customSmokingTrigger: null,
      readinessPath: 'prepare',
      quitPlanPath: 'setQuitDate',
      quitDate: DateTime(2026, 10),
      quitDayCheckIn: true,
      quitReasons: [topReason],
      customQuitReason: null,
      topQuitReason: topReason,
      supportPeople: const [],
      preparationTasks: const ['removeSupplies'],
      treatmentSupport: true,
      careTeamReminder: true,
    );
