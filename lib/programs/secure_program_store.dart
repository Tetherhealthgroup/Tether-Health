import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'program.dart';
import 'program_data_api_client.dart';

class SecureProgramStore {
  SecureProgramStore({
    FlutterSecureStorage? storage,
    ProgramDataApiClient api = const DisabledProgramDataApiClient(),
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _api = api;

  final FlutterSecureStorage _storage;
  final ProgramDataApiClient _api;

  static const _prefix = 'tether.program.v1';

  Future<ProgramDataDocument?> load({
    required String accountScope,
    required ProgramId programId,
    String? accessToken,
  }) async {
    ProgramDataDocument? local;
    final encoded = await _storage.read(key: _key(accountScope, programId));
    if (encoded != null) {
      try {
        final value = jsonDecode(encoded) as Map<String, Object?>;
        local = ProgramDataDocument(
          payload: (value['payload']! as Map).cast<String, Object?>(),
          revision: value['revision']! as int,
          pendingSync: value['pendingSync'] == true,
        );
      } catch (_) {
        await _storage.delete(key: _key(accountScope, programId));
      }
    }
    if (accessToken == null) return local;
    try {
      final remote = await _api.get(accessToken, programId);
      if (local?.pendingSync == true) {
        if (remote != null &&
            remote.revision == local!.revision &&
            jsonEncode(remote.payload) == jsonEncode(local.payload)) {
          await _writeLocal(accountScope, programId, remote);
          return remote;
        }
        try {
          await _api.put(accessToken, programId, local!);
          final synced = ProgramDataDocument(
            payload: local.payload,
            revision: local.revision,
          );
          await _writeLocal(accountScope, programId, synced);
          return synced;
        } catch (_) {
          throw ProgramDataLoadException(local);
        }
      }
      if (remote != null &&
          (local == null || remote.revision >= local.revision)) {
        await _writeLocal(accountScope, programId, remote);
        return remote;
      }
      return local;
    } catch (error) {
      if (error is ProgramDataLoadException) rethrow;
      throw ProgramDataLoadException(local);
    }
  }

  Future<bool> save({
    required String accountScope,
    required ProgramId programId,
    required Map<String, Object?> payload,
    required int revision,
    String? accessToken,
  }) async {
    final document = ProgramDataDocument(
      payload: payload,
      revision: revision,
      pendingSync: accessToken != null,
    );
    final encoded = jsonEncode({'payload': payload, 'revision': revision});
    if (utf8.encode(encoded).length > 32768) {
      throw StateError('Program data exceeds the storage limit.');
    }
    await _writeLocal(accountScope, programId, document);
    if (accessToken == null) return true;
    try {
      await _api.put(accessToken, programId, document);
      await _writeLocal(
        accountScope,
        programId,
        ProgramDataDocument(payload: payload, revision: revision),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteAccount(String accountScope) async {
    final values = await _storage.readAll();
    final prefix = '$_prefix.$accountScope.';
    for (final key in values.keys.where((key) => key.startsWith(prefix))) {
      await _storage.delete(key: key);
    }
  }

  Future<void> _writeLocal(
    String accountScope,
    ProgramId programId,
    ProgramDataDocument document,
  ) =>
      _storage.write(
        key: _key(accountScope, programId),
        value: jsonEncode({
          'payload': document.payload,
          'revision': document.revision,
          'pendingSync': document.pendingSync,
        }),
      );

  String _key(String accountScope, ProgramId programId) =>
      '$_prefix.$accountScope.${programId.slug}';
}

class ProgramDataLoadException implements Exception {
  const ProgramDataLoadException(this.local);

  final ProgramDataDocument? local;
}
