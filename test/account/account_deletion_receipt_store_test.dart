import 'package:breathefree_patient/account/account_data_api_client.dart';
import 'package:breathefree_patient/account/account_deletion_receipt_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('secure store survives recreation until explicit acknowledgement',
      () async {
    const store = SecureAccountDeletionReceiptStore();
    final pending = PendingAccountDeletion(
      accountId: 'account-id',
      receipt: AccountDeletionReceipt(
        requestId: 'request-id',
        completedAt: DateTime.utc(2026, 10, 4, 17, 30),
        profileRowsDeleted: 1,
        quitPlanRowsDeleted: 1,
        avatarObjectsDeleted: 3,
        programDataRowsDeleted: 2,
        authIdentityDeleted: true,
      ),
    );

    await store.saveIntent(pending.accountId);
    await store.saveReceipt(pending);
    final restored = await const SecureAccountDeletionReceiptStore().load();

    expect(restored?.accountId, 'account-id');
    expect(restored?.receipt?.requestId, 'request-id');
    expect(restored?.receipt?.completedAt, DateTime.utc(2026, 10, 4, 17, 30));
    expect(restored?.receipt?.avatarObjectsDeleted, 3);
    expect(restored?.receipt?.programDataRowsDeleted, 2);

    await store.clear();
    expect(await store.load(), isNull);
  });

  test('durable intent remains until a receipt can upgrade it', () async {
    const store = SecureAccountDeletionReceiptStore();
    await store.saveIntent('account-id');

    final restored = await const SecureAccountDeletionReceiptStore().load();

    expect(restored?.accountId, 'account-id');
    expect(restored?.receipt, isNull);
  });

  test('corrupt receipt upgrade falls back to the durable intent', () async {
    FlutterSecureStorage.setMockInitialValues({
      'tether.account-deletion-intent.v2': '{"accountId":"account-id"}',
      'tether.account-deletion-receipt.v2': '{not-json',
    });

    final restored = await const SecureAccountDeletionReceiptStore().load();

    expect(restored?.accountId, 'account-id');
    expect(restored?.receipt, isNull);
    expect(
      await const FlutterSecureStorage()
          .read(key: 'tether.account-deletion-receipt.v2'),
      isNull,
    );
  });

  test('corrupt receipt is removed instead of blocking startup', () async {
    FlutterSecureStorage.setMockInitialValues({
      'tether.account-deletion-receipt.v1': '{not-json',
    });
    const store = SecureAccountDeletionReceiptStore();

    expect(await store.load(), isNull);
    expect(
      await const FlutterSecureStorage()
          .read(key: 'tether.account-deletion-receipt.v1'),
      isNull,
    );
  });
}
