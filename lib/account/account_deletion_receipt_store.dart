import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_data_api_client.dart';

class PendingAccountDeletion {
  const PendingAccountDeletion({
    required this.accountId,
    required this.receipt,
  });

  factory PendingAccountDeletion.fromJson(Map<String, Object?> json) =>
      PendingAccountDeletion(
        accountId: json['accountId'] as String,
        receipt: AccountDeletionReceipt.fromJson(
          (json['receipt']! as Map).cast<String, Object?>(),
        ),
      );

  final String accountId;
  final AccountDeletionReceipt receipt;

  Map<String, Object?> toJson() => {
        'accountId': accountId,
        'receipt': receipt.toJson(),
      };
}

abstract interface class AccountDeletionReceiptStore {
  Future<PendingAccountDeletion?> load();

  Future<void> save(PendingAccountDeletion deletion);

  Future<void> clear();
}

class SecureAccountDeletionReceiptStore implements AccountDeletionReceiptStore {
  const SecureAccountDeletionReceiptStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _key = 'tether.account-deletion-receipt.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<PendingAccountDeletion?> load() async {
    final encoded = await _storage.read(key: _key);
    if (encoded == null) return null;
    try {
      return PendingAccountDeletion.fromJson(
        (jsonDecode(encoded) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      await _storage.delete(key: _key);
      return null;
    }
  }

  @override
  Future<void> save(PendingAccountDeletion deletion) => _storage.write(
        key: _key,
        value: jsonEncode(deletion.toJson()),
      );

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class DisabledAccountDeletionReceiptStore
    implements AccountDeletionReceiptStore {
  const DisabledAccountDeletionReceiptStore();

  @override
  Future<void> clear() async {}

  @override
  Future<PendingAccountDeletion?> load() async => null;

  @override
  Future<void> save(PendingAccountDeletion deletion) async {}
}
