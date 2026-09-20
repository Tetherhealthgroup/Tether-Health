import 'package:flutter/foundation.dart';

import '../auth/auth_gateway.dart';
import 'guest_quit_plan_store.dart';
import 'quit_plan.dart';
import 'quit_plan_api_client.dart';
import 'quit_plan_repository.dart';

enum GuestPlanMergeStatus { none, pendingUpload, uploaded, conflict }

class QuitPlanController extends ChangeNotifier {
  QuitPlanController({
    required AuthGateway auth,
    required QuitPlanRepository repository,
    GuestQuitPlanStore guestStore = const DisabledGuestQuitPlanStore(),
    this.enabled = true,
  })  : _auth = auth,
        _repository = repository,
        _guestStore = guestStore;

  factory QuitPlanController.disabled({
    GuestQuitPlanStore guestStore = const DisabledGuestQuitPlanStore(),
  }) {
    const auth = DisabledAuthGateway();
    return QuitPlanController(
      auth: auth,
      repository: const QuitPlanRepository(
        auth: auth,
        api: DisabledQuitPlanApiClient(),
      ),
      guestStore: guestStore,
      enabled: false,
    );
  }

  final AuthGateway _auth;
  final QuitPlanRepository _repository;
  final GuestQuitPlanStore _guestStore;
  final bool enabled;

  bool get cloudPersistenceAvailable =>
      enabled && _auth.currentIdentity != null;
  bool get guestPersistenceAvailable => _guestStore.isPersistent;
  bool get persistenceAvailable =>
      cloudPersistenceAvailable || guestPersistenceAvailable;
  bool get savedOnDeviceOnly =>
      !cloudPersistenceAvailable && guestPersistenceAvailable;
  bool get guestPlanNeedsUpload =>
      guestMergeStatus == GuestPlanMergeStatus.pendingUpload;
  bool get hasGuestPlanRecoveryIssue => guestStoreFailure != null;
  bool get hasStoredGuestPlan =>
      guestStoreFailure != null ||
      _pendingGuestConflict != null ||
      (_auth.currentIdentity == null &&
          guestPersistenceAvailable &&
          plan != null);

  QuitPlan? plan;
  String? errorMessage;
  bool busy = false;
  bool guestPlanStarted = false;
  bool migratedGuestWasStarted = false;
  GuestPlanMergeStatus guestMergeStatus = GuestPlanMergeStatus.none;
  GuestQuitPlanStoreFailure? guestStoreFailure;
  GuestQuitPlanSnapshot? _pendingGuestConflict;
  int _sessionGeneration = 0;

  Future<bool> initialize() async {
    _sessionGeneration++;
    errorMessage = null;
    guestStoreFailure = null;
    guestMergeStatus = GuestPlanMergeStatus.none;
    migratedGuestWasStarted = false;
    _pendingGuestConflict = null;
    if (_auth.currentIdentity == null) return _restoreGuestPlan();
    return _restoreCloudAndMergeGuest();
  }

  Future<bool> _restoreGuestPlan() async {
    try {
      final snapshot = await _guestStore.load();
      plan = snapshot?.plan;
      guestPlanStarted = snapshot?.stage == GuestPlanStage.active;
      notifyListeners();
      return true;
    } on GuestQuitPlanStoreException catch (error) {
      plan = null;
      guestPlanStarted = false;
      guestStoreFailure = error.failure;
      errorMessage =
          'Your encrypted device plan could not be opened. You can remove it in Settings.';
      notifyListeners();
      return false;
    } catch (_) {
      plan = null;
      guestPlanStarted = false;
      errorMessage = 'Your on-device quit plan is temporarily unavailable.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _restoreCloudAndMergeGuest() async {
    GuestQuitPlanSnapshot? guestSnapshot;
    try {
      guestSnapshot = await _guestStore.load();
    } on GuestQuitPlanStoreException catch (error) {
      guestStoreFailure = error.failure;
      errorMessage =
          'Your encrypted device plan could not be opened. You can remove it in Settings.';
    } catch (_) {
      errorMessage = 'Your on-device quit plan is temporarily unavailable.';
    }

    try {
      QuitPlan? cloudPlan;
      try {
        cloudPlan = await _repository.load();
      } on QuitPlanApiException catch (error) {
        if (error.statusCode != 404) rethrow;
      }

      plan = cloudPlan;
      if (guestSnapshot != null) {
        _pendingGuestConflict = guestSnapshot;
        guestPlanStarted = guestSnapshot.stage == GuestPlanStage.active;
        guestMergeStatus = cloudPlan == null
            ? GuestPlanMergeStatus.pendingUpload
            : GuestPlanMergeStatus.conflict;
      } else {
        guestPlanStarted = false;
      }
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Your quit plan is temporarily unavailable.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> save(QuitPlan value) async {
    if (_auth.currentIdentity == null) {
      if (guestStoreFailure != null) {
        errorMessage =
            'Remove the unreadable encrypted device plan in Settings before saving a new one.';
        notifyListeners();
        return false;
      }
      plan = value;
      errorMessage = null;
      try {
        if (_guestStore.isPersistent) {
          await _guestStore.save(GuestQuitPlanSnapshot(
            plan: value,
            stage:
                guestPlanStarted ? GuestPlanStage.active : GuestPlanStage.draft,
            savedAt: DateTime.now().toUtc(),
          ));
        }
        notifyListeners();
        return true;
      } catch (_) {
        errorMessage = 'Your plan could not be saved on this device.';
        notifyListeners();
        return false;
      }
    }

    if (!enabled) {
      errorMessage = 'Cloud plan storage is not configured.';
      notifyListeners();
      return false;
    }

    if (guestMergeStatus == GuestPlanMergeStatus.pendingUpload ||
        guestMergeStatus == GuestPlanMergeStatus.conflict) {
      errorMessage =
          'Choose what to do with the device plan before saving to your account.';
      notifyListeners();
      return false;
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

  Future<bool> markStarted() async {
    if (_auth.currentIdentity != null) return true;
    final currentPlan = plan;
    if (currentPlan == null) return false;
    guestPlanStarted = true;
    try {
      if (_guestStore.isPersistent) {
        await _guestStore.save(GuestQuitPlanSnapshot(
          plan: currentPlan,
          stage: GuestPlanStage.active,
          savedAt: DateTime.now().toUtc(),
        ));
      }
      notifyListeners();
      return true;
    } catch (_) {
      guestPlanStarted = false;
      errorMessage = 'Your plan could not be saved on this device.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> importGuestPlan() async {
    final guestSnapshot = _pendingGuestConflict;
    final identity = _auth.currentIdentity;
    if (guestSnapshot == null || identity == null || !enabled) {
      return false;
    }
    final operationGeneration = _sessionGeneration;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final importedPlan = await _repository.create(guestSnapshot.plan);
      if (!_isCurrentSession(identity.id, operationGeneration)) return false;
      await _guestStore.clear();
      if (!_isCurrentSession(identity.id, operationGeneration)) {
        await _restoreGuestSnapshotAfterInterruptedClear(guestSnapshot);
        return false;
      }
      plan = importedPlan;
      migratedGuestWasStarted = guestSnapshot.stage == GuestPlanStage.active;
      _pendingGuestConflict = null;
      guestPlanStarted = false;
      guestMergeStatus = GuestPlanMergeStatus.uploaded;
      return true;
    } on QuitPlanApiException catch (error) {
      if (!_isCurrentSession(identity.id, operationGeneration)) return false;
      if (error.statusCode != 409) {
        errorMessage = 'The on-device plan could not be backed up.';
        return false;
      }
      try {
        final cloudPlan = await _repository.load();
        if (!_isCurrentSession(identity.id, operationGeneration)) return false;
        plan = cloudPlan;
        guestMergeStatus = GuestPlanMergeStatus.conflict;
        return true;
      } catch (_) {
        errorMessage = 'Your account plan is temporarily unavailable.';
        return false;
      }
    } catch (_) {
      if (_isCurrentSession(identity.id, operationGeneration)) {
        errorMessage = 'The on-device plan could not be backed up.';
      }
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> keepCloudPlanAndDiscardGuest() async {
    if (guestMergeStatus != GuestPlanMergeStatus.conflict) return true;
    try {
      await _guestStore.clear();
      _pendingGuestConflict = null;
      guestPlanStarted = false;
      guestMergeStatus = GuestPlanMergeStatus.none;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'The on-device plan could not be removed.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> replaceCloudWithGuestPlan() async {
    final guestSnapshot = _pendingGuestConflict;
    final identity = _auth.currentIdentity;
    if (guestSnapshot == null || identity == null || !enabled) {
      return false;
    }
    final operationGeneration = _sessionGeneration;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final replacedPlan = await _repository.save(guestSnapshot.plan);
      if (!_isCurrentSession(identity.id, operationGeneration)) return false;
      await _guestStore.clear();
      if (!_isCurrentSession(identity.id, operationGeneration)) {
        await _restoreGuestSnapshotAfterInterruptedClear(guestSnapshot);
        return false;
      }
      plan = replacedPlan;
      migratedGuestWasStarted = guestSnapshot.stage == GuestPlanStage.active;
      _pendingGuestConflict = null;
      guestPlanStarted = false;
      guestMergeStatus = GuestPlanMergeStatus.uploaded;
      return true;
    } catch (_) {
      if (_isCurrentSession(identity.id, operationGeneration)) {
        errorMessage = 'The on-device plan could not be moved to your account.';
      }
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  bool _isCurrentSession(String userId, int generation) =>
      _sessionGeneration == generation && _auth.currentIdentity?.id == userId;

  Future<void> _restoreGuestSnapshotAfterInterruptedClear(
    GuestQuitPlanSnapshot snapshot,
  ) async {
    try {
      await _guestStore.save(snapshot);
    } catch (_) {
      // Preserve the current session boundary even if recovery storage fails.
    }
  }

  void clear() {
    _sessionGeneration++;
    plan = null;
    errorMessage = null;
    busy = false;
    guestPlanStarted = false;
    migratedGuestWasStarted = false;
    guestMergeStatus = GuestPlanMergeStatus.none;
    guestStoreFailure = null;
    _pendingGuestConflict = null;
    notifyListeners();
  }

  Future<void> clearGuestPlan() async {
    await _guestStore.clear();
    guestStoreFailure = null;
    _pendingGuestConflict = null;
    guestPlanStarted = false;
    if (_auth.currentIdentity == null) {
      clear();
    } else {
      guestMergeStatus = GuestPlanMergeStatus.none;
      notifyListeners();
    }
  }
}
