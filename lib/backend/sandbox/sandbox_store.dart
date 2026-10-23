// The sandbox's one encrypted document: every synthetic account, session and
// row, in `flutter_secure_storage` under `sandbox.v1`, capped at 1 MiB.
//
// Every change runs as a transaction on a copy: it is written as a whole or
// not at all. A change that would take the document over the cap is
// refused (`sandbox_full`) and nothing of it is kept.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Reads and writes the stored document.
abstract interface class SandboxPersistence {
  Future<String?> read();
  Future<void> write(String document);
  Future<void> delete();
}

/// The document in the Keychain / Android Keystore.
class SecureSandboxPersistence implements SandboxPersistence {
  const SecureSandboxPersistence([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  /// The storage key.
  static const String key = 'sandbox.v1';

  @override
  Future<String?> read() => _storage.read(key: key);

  @override
  Future<void> write(String document) =>
      _storage.write(key: key, value: document);

  @override
  Future<void> delete() => _storage.delete(key: key);
}

/// In memory (tests).
class MemorySandboxPersistence implements SandboxPersistence {
  String? document;
  int writes = 0;

  @override
  Future<String?> read() async => document;

  @override
  Future<void> write(String value) async {
    writes++;
    document = value;
  }

  @override
  Future<void> delete() async => document = null;
}

/// A change refused because the document would exceed [SandboxStore.maxBytes].
class SandboxFullException implements Exception {
  const SandboxFullException();
}

/// JSON object type of the document.
typedef Json = Map<String, Object?>;

/// The loaded document and its transactions.
class SandboxStore {
  SandboxStore(this._persistence, {this.maxBytes = defaultMaxBytes});

  final SandboxPersistence _persistence;

  /// The cap, in UTF-8 bytes of the stored JSON.
  final int maxBytes;

  static const int defaultMaxBytes = 1024 * 1024;

  Json? _state;
  Future<void> _tail = Future<void>.value();

  static Json _empty() => <String, Object?>{
        'v': 1,
        'seq': 0,
        'users': <String, Object?>{},
        'session': null,
        'data': <String, Object?>{},
      };

  Future<Json> _loaded() async {
    final existing = _state;
    if (existing != null) return existing;
    Json state;
    try {
      final text = await _persistence.read();
      state = text == null ? _empty() : _deepCopy(jsonDecode(text)) as Json;
      if (state['v'] != 1) state = _empty();
    } catch (_) {
      // An unreadable document starts empty: it holds synthetic data only.
      state = _empty();
    }
    return _state = state;
  }

  static Object? _deepCopy(Object? value) => switch (value) {
        final Map<dynamic, dynamic> map => <String, Object?>{
            for (final e in map.entries) e.key as String: _deepCopy(e.value),
          },
        final List<dynamic> list => <Object?>[
            for (final item in list) _deepCopy(item),
          ],
        _ => value,
      };

  /// Runs [read] on a copy of the current document; changes to the copy
  /// are not kept.
  Future<T> read<T>(T Function(Json state) read) =>
      _serial(() async => read(_deepCopy(await _loaded()) as Json));

  /// Runs [change] on a copy of the document and stores the copy. When
  /// [change] throws, or the result is over the cap, nothing is kept.
  Future<T> transact<T>(T Function(Json state) change) => _serial(() async {
        final current = await _loaded();
        final copy = _deepCopy(current) as Json;
        final result = change(copy);
        final text = jsonEncode(copy);
        if (utf8.encode(text).length > maxBytes) {
          throw const SandboxFullException();
        }
        await _persistence.write(text);
        _state = copy;
        return result;
      });

  /// Deletes the document.
  Future<void> wipe() => _serial(() async {
        await _persistence.delete();
        _state = _empty();
      });

  /// Forgets the loaded copy, so the next call reads storage again (tests:
  /// a restart).
  void forgetLoaded() => _state = null;

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// A new id: a UUID-shaped string from the document's counter and [salt].
  static String nextId(Json state, [String salt = '']) {
    final seq = ((state['seq'] as int?) ?? 0) + 1;
    state['seq'] = seq;
    final digits = seq.toRadixString(16).padLeft(12, '0');
    final mark = (salt.hashCode & 0xffff).toRadixString(16).padLeft(4, '0');
    return '5a4db0c0-$mark-4000-8000-$digits';
  }
}
