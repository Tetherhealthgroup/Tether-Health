import '../auth/auth_gateway.dart';
import 'quit_plan.dart';
import 'quit_plan_api_client.dart';

class QuitPlanRepository {
  const QuitPlanRepository({
    required AuthGateway auth,
    required QuitPlanApiClient api,
  })  : _auth = auth,
        _api = api;

  final AuthGateway _auth;
  final QuitPlanApiClient _api;

  Future<QuitPlan> load() => _api.getQuitPlan(_requiredToken());

  Future<QuitPlan> save(QuitPlan plan) =>
      _api.putQuitPlan(_requiredToken(), plan);

  Future<QuitPlan> create(QuitPlan plan) =>
      _api.createQuitPlan(_requiredToken(), plan);

  String _requiredToken() {
    final token = _auth.currentIdentity?.accessToken;
    if (token == null) throw StateError('Authentication is required.');
    return token;
  }
}
