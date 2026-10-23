// Where the local sync document lives: one encrypted entry per scope (one
// per account, plus one for a guest who has not signed in).
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Reads and writes the local sync document of one scope.
abstract interface class SyncDocumentStore {
  Future<String?> read(String scope);
  Future<void> write(String scope, String document);
  Future<void> delete(String scope);

  /// Deletes every scope's document.
  Future<void> deleteAll();
}

/// The scope of a guest (no account).
const String guestSyncScope = 'guest';

/// The scope of [accountId].
String accountSyncScope(String accountId) => 'account.$accountId';

/// The documents in the Keychain / Android Keystore.
class SecureSyncDocumentStore implements SyncDocumentStore {
  const SecureSyncDocumentStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  static const String _prefix = 'sync.v1.';

  @override
  Future<String?> read(String scope) => _storage.read(key: '$_prefix$scope');

  @override
  Future<void> write(String scope, String document) =>
      _storage.write(key: '$_prefix$scope', value: document);

  @override
  Future<void> delete(String scope) => _storage.delete(key: '$_prefix$scope');

  @override
  Future<void> deleteAll() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith(_prefix)) await _storage.delete(key: key);
    }
  }
}

/// In memory (tests).
class MemorySyncDocumentStore implements SyncDocumentStore {
  final Map<String, String> documents = <String, String>{};

  @override
  Future<String?> read(String scope) async => documents[scope];

  @override
  Future<void> write(String scope, String document) async =>
      documents[scope] = document;

  @override
  Future<void> delete(String scope) async => documents.remove(scope);

  @override
  Future<void> deleteAll() async => documents.clear();
}
