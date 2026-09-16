import 'package:flutter/foundation.dart';

import '../auth/auth_gateway.dart';
import 'quit_plan.dart';
import 'quit_plan_api_client.dart';
import 'quit_plan_repository.dart';

class QuitPlanController extends ChangeNotifier {
  QuitPlanController({
    required AuthGateway auth,
    required QuitPlanRepository repository,
    this.enabled = true,
  })  : _auth = auth,
        _repository = repository;

  factory QuitPlanController.disabled() {
    const auth = DisabledAuthGateway();
    return QuitPlanController(
      auth: auth,
      repository: const QuitPlanRepository(
        auth: auth,
        api: DisabledQuitPlanApiClient(),
      ),
      enabled: false,
    );
  }

  final AuthGateway _auth;
  final QuitPlanRepository _repository;
  final bool enabled;

  bool get persistenceAvailable => enabled && _auth.currentIdentity != null;

  QuitPlan? plan;
  String? errorMessage;
  bool busy = false;

  Future<bool> initialize() async {
    if (_auth.currentIdentity == null) return false;
    errorMessage = null;
    try {
      plan = await _repository.load();
      notifyListeners();
      return true;
    } on QuitPlanApiException catch (error) {
      if (error.statusCode == 404) {
        plan = null;
        notifyListeners();
        return true;
      }
      errorMessage = 'Your quit plan is temporarily unavailable.';
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Your quit plan is temporarily unavailable.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> save(QuitPlan value) async {
    if (!enabled || _auth.currentIdentity == null) {
      plan = value;
      errorMessage = null;
      notifyListeners();
      return true;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      plan = await _repository.save(value);
      return true;
    } catch (_) {
      errorMessage = 'Your quit plan could not be saved.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void clear() {
    plan = null;
    errorMessage = null;
    busy = false;
    notifyListeners();
  }
}
