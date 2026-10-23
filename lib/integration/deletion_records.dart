// Account deletion as the phone records it, so a deletion is never half
// done without anyone knowing:
// 1. "requested" is stored before the server is asked;
// 2. a server failure removes it again (nothing is wiped);
// 3. after the server succeeded, "server_done" is stored with the receipt;
// 4. the local cleanup runs; when every part succeeded the record becomes
//    "complete" (kept for the receipt screen), otherwise the cleanup is
//    retried on the next start.
import 'dart:convert';

import '../api/tether_api.dart';
import '../data/app_services.dart';
import '../sync/sync_store.dart';
import 'data_adapter.dart';
import 'pending_onboarding.dart';
import 'session_lifecycle.dart';

/// The stored deletion records, by account id.
class DeletionRecords {
  DeletionRecords(this._store);

  final SyncDocumentStore _store;
  static const String _scope = 'deletion';

  Future<Map<String, Map<String, Object?>>> all() async {
    final text = await _store.read(_scope);
    if (text == null) return {};
    return {
      for (final MapEntry(:key, :value) in (jsonDecode(text) as Map).entries)
        key as String: (value as Map).cast<String, Object?>(),
    };
  }

  Future<void> put(String accountId, Map<String, Object?> record) async {
    final records = await all();
    records[accountId] = record;
    await _store.write(_scope, jsonEncode(records));
  }

  Future<void> remove(String accountId) async {
    final records = await all()
      ..remove(accountId);
    await _store.write(_scope, jsonEncode(records));
  }

  /// The newest record with a receipt.
  Future<Map<String, Object?>?> latestReceipt() async {
    Map<String, Object?>? latest;
    for (final record in (await all()).values) {
      final receipt = record['receipt'];
      if (receipt is! Map) continue;
      if (latest == null ||
          '${receipt['completedAt']}'
                  .compareTo('${(latest['receipt'] as Map)['completedAt']}') >
              0) {
        latest = record;
      }
    }
    return latest;
  }
}

/// Deletes the phone's data of [accountId]. True when every part of this
/// app's own cleanup succeeded; the other registered cleaners run too.
Future<bool> cleanUpAccount(
  AppServices services,
  DeletionCleaners cleaners,
  PendingOnboarding pending,
  String accountId,
) async {
  var ok = true;
  for (final step in <Future<void> Function()>[
    () => services.wipeAccount(accountId),
    pending.clear,
  ]) {
    try {
      await step();
    } catch (_) {
      ok = false;
    }
  }
  await cleaners.runAll(accountId);
  return ok;
}

/// Finishes deletions whose local cleanup did not complete. Call on start.
Future<void> retryDeletions(
  AppServices services,
  DeletionCleaners cleaners,
  PendingOnboarding pending,
) async {
  final records = DeletionRecords(services.local);
  for (final MapEntry(key: id, value: record)
      in (await records.all()).entries) {
    switch (record['state']) {
      case 'requested':
        // The server's answer was never recorded. The delete is safe to
        // repeat: ask again. A session the server no longer accepts means
        // the account is already gone. Anything else keeps the record for
        // the next start; it is never dropped before the cleanup.
        var done = !services.signedIn;
        Map<String, Object?>? receipt;
        if (!done) {
          final answer = await services.api.account.deleteData();
          receipt = answer.valueOrNull?.toJson();
          done = receipt != null ||
              answer.errorOrNull?.code == ApiProblemCode.unauthenticated;
        }
        if (!done) continue;
        final next = {
          'state': 'server_done',
          if (receipt != null) 'receipt': receipt
        };
        await records.put(id, next);
        if (await cleanUpAccount(services, cleaners, pending, id)) {
          await records.put(id, {...next, 'state': 'complete'});
        }
      case 'server_done':
        if (await cleanUpAccount(services, cleaners, pending, id)) {
          await records.put(id, {...record, 'state': 'complete'});
        }
    }
  }
}

/// The receipt shown after a deletion (`account.deletion.*`).
class DeletionSource implements DataSource {
  DeletionSource(this._services);

  final AppServices _services;

  static const Set<String> keys = {
    'account.deletion.receipt',
    'account.deletion.completed_at',
  };

  @override
  bool covers(String bindKey) => keys.contains(bindKey);

  @override
  Future<Map<String, Object?>?> load() async {
    try {
      final record = await DeletionRecords(_services.local).latestReceipt();
      final receipt = record?['receipt'] as Map?;
      if (receipt == null) return const {};
      final parsed = DeletionReceipt.fromJson(receipt.cast<String, Object?>());
      final at = parsed.completedAt.toLocal();
      final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return {
        'account.deletion.receipt': parsed.requestId,
        'account.deletion.completed_at':
            '${months[at.month - 1]} ${at.day}, ${at.year} · '
                '$hour:${at.minute.toString().padLeft(2, '0')} ${at.hour < 12 ? 'AM' : 'PM'}',
      };
    } catch (_) {
      return null;
    }
  }
}
