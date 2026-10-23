// The outbox: programme and record event POSTs that could not be sent yet,
// kept encrypted on the phone and sent in order later.
//
// Rules:
// - It carries API event POSTs only. Enrolments, consents, account and
//   sign-in calls are never queued (they fail instead), and plans, answers
//   and lapses go through the sync document.
// - It is bounded: 200 entries and 256 KiB per account. A save that does not
//   fit fails; nothing already queued is dropped to make room.
// - Each entry keeps its Idempotency-Key, so a retry never creates a second
//   record.
// - Safety entries (moods, blood pressure, glucose, zone checks) are retried
//   until the service accepts them or the account changes; they are never
//   dropped. Other entries the service refuses for good are dropped.
// - A permanent refusal is counted in [Outbox.notices] (the app shows the
//   generic error on the next foreground) and its code is reported.
// - A guest's entries stay on the phone; they are moved into an account only
//   by [Outbox.adoptGuest], after the member agreed to merge.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../backend/backend.dart';
import '../sync/sync_store.dart';

/// One queued event POST.
@immutable
class OutboxEntry {
  const OutboxEntry({
    required this.endpoint,
    required this.path,
    required this.body,
    required this.idempotencyKey,
    this.safety = false,
    this.failedCode,
  });

  factory OutboxEntry.fromJson(Map<String, Object?> json) => OutboxEntry(
        endpoint: json['endpoint']! as String,
        path: json['path']! as String,
        body: (json['body']! as Map).cast<String, Object?>(),
        idempotencyKey: json['key']! as String,
        safety: json['safety'] == true,
        failedCode: json['failed'] as String?,
      );

  /// The spec endpoint string (for codes and tests).
  final String endpoint;

  /// The concrete API path.
  final String path;
  final Map<String, Object?> body;
  final String idempotencyKey;
  final bool safety;

  /// Set once the service refused it for good (safety entries only; they
  /// stay queued).
  final String? failedCode;

  OutboxEntry withFailure(String code) => OutboxEntry(
        endpoint: endpoint,
        path: path,
        body: body,
        idempotencyKey: idempotencyKey,
        safety: safety,
        failedCode: code,
      );

  Map<String, Object?> toJson() => {
        'endpoint': endpoint,
        'path': path,
        'body': body,
        'key': idempotencyKey,
        'safety': safety,
        if (failedCode != null) 'failed': failedCode,
      };

  BackendRequest toRequest() => BackendRequest(
        service: BackendService.api,
        method: BackendMethod.post,
        path: path,
        body: body,
        idempotencyKey: idempotencyKey,
      );

  /// Never prints the body.
  @override
  String toString() => 'OutboxEntry($endpoint)';
}

/// What [Outbox.submit] did with an entry.
sealed class OutboxResult {
  const OutboxResult();
}

/// The service stored it.
final class OutboxDelivered extends OutboxResult {
  const OutboxDelivered(this.json);
  final Object? json;
}

/// Kept on the phone, to be sent later.
final class OutboxQueued extends OutboxResult {
  const OutboxQueued();
}

/// Not saved: the service refused it, or the outbox is full.
final class OutboxFailed extends OutboxResult {
  const OutboxFailed(this.code);
  final String code;
}

/// Outbox documents in the Keychain / Android Keystore (`outbox.v1.*`).
class SecureOutboxStore implements SyncDocumentStore {
  const SecureOutboxStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;
  static const String _prefix = 'outbox.v1.';

  @override
  Future<String?> read(String scope) => _storage.read(key: '$_prefix$scope');

  @override
  Future<void> write(String scope, String document) =>
      _storage.write(key: '$_prefix$scope', value: document);

  @override
  Future<void> delete(String scope) => _storage.delete(key: '$_prefix$scope');

  @override
  Future<void> deleteAll() async {
    for (final key in (await _storage.readAll()).keys) {
      if (key.startsWith(_prefix)) await _storage.delete(key: key);
    }
  }
}

/// Codes the outbox reports.
abstract final class OutboxCodes {
  static const String full = 'outbox_full';
  static const String rejected = 'outbox_rejected';
  static const String unreadable = 'outbox_unreadable';
}

/// The stored outbox could not be read; it is left as it is.
class OutboxUnreadable implements Exception {
  const OutboxUnreadable();
}

/// The outbox of the signed-in account (or the guest's).
class Outbox {
  Outbox({
    required BackendTransport transport,
    required SyncDocumentStore store,
    required String? Function() accountId,
    void Function(String code)? onCode,
    this.maxEntries = 200,
    this.maxBytes = 256 * 1024,
  })  : _transport = transport,
        _store = store,
        _accountId = accountId,
        _onCode = onCode;

  final BackendTransport _transport;
  final SyncDocumentStore _store;
  final String? Function() _accountId;
  final void Function(String code)? _onCode;
  final int maxEntries;
  final int maxBytes;

  final ValueNotifier<int> _notices = ValueNotifier<int>(0);
  Future<void> _tail = Future<void>.value();

  /// Permanent refusals not yet shown to the member.
  ValueListenable<int> get notices => _notices;

  /// Returns and resets the number of permanent refusals to show.
  int takeNotices() {
    final n = _notices.value;
    _notices.value = 0;
    return n;
  }

  String get _scope {
    final id = _accountId();
    return id == null ? guestSyncScope : accountSyncScope(id);
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<List<OutboxEntry>> _load(String scope) async {
    try {
      final text = await _store.read(scope);
      if (text == null) return <OutboxEntry>[];
      return [
        for (final e in jsonDecode(text) as List<Object?>)
          OutboxEntry.fromJson((e! as Map).cast<String, Object?>()),
      ];
    } catch (_) {
      // Never treated as empty: that would overwrite entries (safety ones
      // included) that may still be recoverable.
      throw const OutboxUnreadable();
    }
  }

  Future<void> _save(String scope, List<OutboxEntry> entries) => entries.isEmpty
      ? _store.delete(scope)
      : _store.write(scope, jsonEncode([for (final e in entries) e.toJson()]));

  static int _bytes(List<OutboxEntry> entries) =>
      utf8.encode(jsonEncode([for (final e in entries) e.toJson()])).length;

  bool _fits(List<OutboxEntry> entries, OutboxEntry entry) {
    final next = [...entries, entry];
    if (_bytes(next) > maxBytes) return false;
    return entry.safety || next.length <= maxEntries;
  }

  /// Entries queued in the current scope (tests and the badge).
  /// Throws [OutboxUnreadable] when the stored outbox cannot be read.
  Future<List<OutboxEntry>> pending() => _serial(() => _load(_scope));

  static bool _retryable(BackendResponse response) => switch (response) {
        BackendUnreachable() => true,
        BackendProblem(:final status, :final code) => status == 401 ||
            status == 429 ||
            (status >= 500 && code != BackendCodes.sandboxFull) ||
            code == BackendCodes.notReady,
        BackendOk() => false,
      };

  /// Sends [entry] now when possible; otherwise keeps it (queued) or refuses
  /// it (failed). Queued entries are sent first, in order.
  Future<OutboxResult> submit(OutboxEntry entry) => _serial(() async {
        final scope = _scope;
        final List<OutboxEntry> queue;
        try {
          queue = await _load(scope);
        } on OutboxUnreadable {
          _onCode?.call(OutboxCodes.unreadable);
          return const OutboxFailed(OutboxCodes.unreadable);
        }
        if (scope != guestSyncScope) {
          await _flushQueue(scope, queue);
          if (queue.isEmpty) {
            final response = await _transport.send(entry.toRequest());
            if (response case BackendOk(:final json)) {
              return OutboxDelivered(json);
            }
            if (!_retryable(response)) {
              final code = (response as BackendProblem).code;
              return OutboxFailed(code);
            }
          }
        }
        if (!_fits(queue, entry)) {
          _onCode?.call(OutboxCodes.full);
          return const OutboxFailed(OutboxCodes.full);
        }
        queue.add(entry);
        await _save(scope, queue);
        return const OutboxQueued();
      });

  /// Sends the queued entries of the signed-in account, in order. Call on
  /// start, on resume and after a save.
  Future<void> flush() => _serial(() async {
        final scope = _scope;
        if (scope == guestSyncScope) return;
        final List<OutboxEntry> queue;
        try {
          queue = await _load(scope);
        } on OutboxUnreadable {
          _onCode?.call(OutboxCodes.unreadable);
          return;
        }
        if (queue.isEmpty) return;
        await _flushQueue(scope, queue);
      });

  /// Delivers [queue] in order, changing it in place and saving it.
  Future<void> _flushQueue(String scope, List<OutboxEntry> queue) async {
    if (queue.isEmpty) return;
    var changed = false;
    var i = 0;
    while (i < queue.length) {
      final entry = queue[i];
      final response = await _transport.send(entry.toRequest());
      if (response is BackendOk) {
        queue.removeAt(i);
        changed = true;
        continue;
      }
      if (_retryable(response)) break;
      final code = (response as BackendProblem).code;
      _onCode?.call(OutboxCodes.rejected);
      if (entry.safety) {
        // Never dropped: kept and retried; the member is told once.
        if (entry.failedCode == null) {
          queue[i] = entry.withFailure(code);
          _notices.value++;
          changed = true;
        }
        i++;
      } else {
        queue.removeAt(i);
        _notices.value++;
        changed = true;
      }
    }
    if (changed) await _save(scope, queue);
  }

  /// Moves the guest's entries into the signed-in account, then deletes the
  /// guest's copy. Call only after the member agreed to merge.
  Future<void> adoptGuest() => _serial(() async {
        final scope = _scope;
        if (scope == guestSyncScope) throw StateError('no account is open');
        final guest = await _load(guestSyncScope);
        if (guest.isEmpty) return;
        final queue = await _load(scope)
          ..addAll(guest);
        await _save(scope, queue);
        await _store.delete(guestSyncScope);
      });

  /// Deletes the outbox of [accountId] (the guest's when null).
  Future<void> wipe({String? accountId}) => _serial(() => _store.delete(
      accountId == null ? guestSyncScope : accountSyncScope(accountId)));

  /// Deletes every outbox on the phone.
  Future<void> wipeAll() => _serial(_store.deleteAll);
}
