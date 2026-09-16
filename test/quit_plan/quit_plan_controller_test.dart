import 'package:breathefree_patient/auth/auth_gateway.dart';
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

class _NotFoundApi implements QuitPlanApiClient {
  @override
  Future<QuitPlan> getQuitPlan(String accessToken) =>
      Future.error(const QuitPlanApiException(404));

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) =>
      throw UnimplementedError();
}

class _RecordingApi implements QuitPlanApiClient {
  QuitPlan? saved;

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) async => _plan();

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) async =>
      saved = plan;
}

QuitPlan _plan() => QuitPlan(
      userId: '00000000-0000-0000-0000-000000000001',
      dailyCigaretteUse: 'tenOrFewer',
      smokingTriggers: const ['stress'],
      customSmokingTrigger: null,
      readinessPath: 'prepare',
      quitPlanPath: 'setQuitDate',
      quitDate: DateTime(2026, 10),
      quitDayCheckIn: true,
      quitReasons: const ['family'],
      customQuitReason: null,
      topQuitReason: 'family',
      supportPeople: const [],
      preparationTasks: const ['removeSupplies'],
      treatmentSupport: true,
      careTeamReminder: true,
    );
