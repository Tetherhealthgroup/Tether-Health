import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_data_api_client.dart';

class PendingAccountDeletion {
  const PendingAccountDeletion({
    required this.accountId,
    this.receipt,
  });

  factory PendingAccountDeletion.fromJson(Map<String, Object?> json) =>
      PendingAccountDeletion(
        accountId: json['accountId'] as String,
        receipt: json['receipt'] == null
            ? null
            : AccountDeletionReceipt.fromJson(
                (json['receipt']! as Map).cast<String, Object?>(),
              ),
      );

  final String accountId;
  final AccountDeletionReceipt? receipt;

  Map<String, Object?> toJson() => {
        'accountId': accountId,
        if (receipt != null) 'receipt': receipt!.toJson(),
      };
}

abstract interface class AccountDeletionReceiptStore {
  Future<PendingAccountDeletion?> load();

  Future<void> saveIntent(String accountId);

  Future<void> saveReceipt(PendingAccountDeletion deletion);

  Future<void> clear();
}

class SecureAccountDeletionReceiptStore implements AccountDeletionReceiptStore {
  const SecureAccountDeletionReceiptStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _intentKey = 'tether.account-deletion-intent.v2';
  static const _receiptKey = 'tether.account-deletion-receipt.v2';
  static const _legacyReceiptKey = 'tether.account-deletion-receipt.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<PendingAccountDeletion?> load() async {
    final receipt = await _loadKey(_receiptKey);
    if (receipt != null && receipt.receipt != null) return receipt;

    final intent = await _loadKey(_intentKey);
    if (intent != null) {
      return PendingAccountDeletion(accountId: intent.accountId);
    }

    return _loadKey(_legacyReceiptKey);
  }

  Future<PendingAccountDeletion?> _loadKey(String key) async {
    final encoded = await _storage.read(key: key);
    if (encoded == null) return null;
    try {
      return PendingAccountDeletion.fromJson(
        (jsonDecode(encoded) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      await _storage.delete(key: key);
      return null;
    }
  }

  @override
  Future<void> saveIntent(String accountId) => _storage.write(
        key: _intentKey,
        value:
            jsonEncode(PendingAccountDeletion(accountId: accountId).toJson()),
      );

  @override
  Future<void> saveReceipt(PendingAccountDeletion deletion) {
    if (deletion.receipt == null) {
      throw ArgumentError.value(deletion, 'deletion', 'Receipt is required.');
    }
    // The intent remains in its own key until acknowledgement. A failed or
    // interrupted receipt write therefore cannot remove restart recovery.
    return _storage.write(
      key: _receiptKey,
      value: jsonEncode(deletion.toJson()),
    );
  }

  @override
  Future<void> clear() async {
    // Remove the fallback intent first. If the second delete fails, the exact
    // receipt remains available and acknowledgement can be retried.
    await _storage.delete(key: _intentKey);
    await _storage.delete(key: _legacyReceiptKey);
    await _storage.delete(key: _receiptKey);
  }
}

class DisabledAccountDeletionReceiptStore
    implements AccountDeletionReceiptStore {
  const DisabledAccountDeletionReceiptStore();

  @override
  Future<void> clear() async {}

  @override
  Future<PendingAccountDeletion?> load() async => null;

  @override
  Future<void> saveIntent(String accountId) async {}

  @override
  Future<void> saveReceipt(PendingAccountDeletion deletion) async {}
}
