import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'quit_plan.dart';

enum GuestPlanStage { draft, active }

enum GuestQuitPlanStoreFailure { corrupt, unsupportedVersion }

class GuestQuitPlanStoreException implements Exception {
  const GuestQuitPlanStoreException(this.failure);

  final GuestQuitPlanStoreFailure failure;
}

class GuestQuitPlanSnapshot {
  const GuestQuitPlanSnapshot({
    required this.plan,
    required this.stage,
    required this.savedAt,
  });

  final QuitPlan plan;
  final GuestPlanStage stage;
  final DateTime savedAt;
}

abstract interface class GuestQuitPlanStore {
  bool get isPersistent;

  Future<GuestQuitPlanSnapshot?> load();

  Future<void> save(GuestQuitPlanSnapshot snapshot);

  Future<void> clear();
}

class SecureGuestQuitPlanStore implements GuestQuitPlanStore {
  SecureGuestQuitPlanStore({
    FlutterSecureStorage? storage,
    DateTime Function()? now,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.unlocked_this_device,
                synchronizable: false,
                accountName: 'breathefree.guest',
              ),
              aOptions: AndroidOptions(
                migrateWithBackup: true,
                storageNamespace: 'breathefree_guest',
              ),
            ),
        _now = now ?? DateTime.now;

  static const storageKey = 'breathefree.guest.quit_plan.v1';
  static const _schemaVersion = 1;

  final FlutterSecureStorage _storage;
  final DateTime Function() _now;

  @override
  bool get isPersistent => true;

  @override
  Future<GuestQuitPlanSnapshot?> load() async {
    final value = await _storage.read(key: storageKey);
    if (value == null) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, Object?>) {
        throw const GuestQuitPlanStoreException(
          GuestQuitPlanStoreFailure.corrupt,
        );
      }
      if (decoded['schemaVersion'] != _schemaVersion) {
        throw const GuestQuitPlanStoreException(
          GuestQuitPlanStoreFailure.unsupportedVersion,
        );
      }
      final planJson = decoded['plan'];
      final stageName = decoded['stage'];
      final savedAt = decoded['savedAt'];
      if (planJson is! Map<String, Object?> ||
          stageName is! String ||
          savedAt is! String) {
        throw const GuestQuitPlanStoreException(
          GuestQuitPlanStoreFailure.corrupt,
        );
      }
      final stage = GuestPlanStage.values
          .where((value) => value.name == stageName)
          .firstOrNull;
      if (stage == null) {
        throw const GuestQuitPlanStoreException(
          GuestQuitPlanStoreFailure.corrupt,
        );
      }
      return GuestQuitPlanSnapshot(
        plan: QuitPlan.fromJson(planJson),
        stage: stage,
        savedAt: DateTime.parse(savedAt).toUtc(),
      );
    } on GuestQuitPlanStoreException {
      rethrow;
    } catch (_) {
      throw const GuestQuitPlanStoreException(
        GuestQuitPlanStoreFailure.corrupt,
      );
    }
  }

  @override
  Future<void> save(GuestQuitPlanSnapshot snapshot) => _storage.write(
        key: storageKey,
        value: jsonEncode({
          'schemaVersion': _schemaVersion,
          'savedAt': snapshot.savedAt.toUtc().toIso8601String(),
          'stage': snapshot.stage.name,
          'plan': snapshot.plan.toLocalJson(),
        }),
      );

  Future<void> savePlan(
    QuitPlan plan, {
    required GuestPlanStage stage,
  }) =>
      save(GuestQuitPlanSnapshot(
        plan: plan,
        stage: stage,
        savedAt: _now().toUtc(),
      ));

  @override
  Future<void> clear() => _storage.delete(key: storageKey);
}

class DisabledGuestQuitPlanStore implements GuestQuitPlanStore {
  const DisabledGuestQuitPlanStore();

  @override
  bool get isPersistent => false;

  @override
  Future<GuestQuitPlanSnapshot?> load() async => null;

  @override
  Future<void> save(GuestQuitPlanSnapshot snapshot) async {}

  @override
  Future<void> clear() async {}
}
