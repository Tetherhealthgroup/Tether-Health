import 'package:breathefree_patient/programs/program.dart';
import 'package:breathefree_patient/programs/program_data_api_client.dart';
import 'package:breathefree_patient/programs/secure_program_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('encrypted local snapshots are isolated by account and program',
      () async {
    final store = SecureProgramStore();
    await store.save(
      accountScope: 'account-a',
      programId: ProgramId.steady,
      payload: {'readings': <Object?>[]},
      revision: 1,
    );

    expect(
      (await store.load(
        accountScope: 'account-a',
        programId: ProgramId.steady,
      ))
          ?.revision,
      1,
    );
    expect(
      await store.load(
        accountScope: 'account-b',
        programId: ProgramId.steady,
      ),
      isNull,
    );
    expect(
      await store.load(
        accountScope: 'account-a',
        programId: ProgramId.heartwise,
      ),
      isNull,
    );
  });

  test('offline sync keeps the encrypted local copy and reports pending sync',
      () async {
    final store = SecureProgramStore(api: _OfflineApi());
    final result = await store.save(
      accountScope: 'account-a',
      programId: ProgramId.clearAir,
      payload: {'symptomLogs': <Object?>[]},
      revision: 2,
      accessToken: 'token',
    );
    expect(result.synced, isFalse);
    expect(result.retryable, isTrue);
    final local = await store.load(
      accountScope: 'account-a',
      programId: ProgramId.clearAir,
    );
    expect(local?.revision, 2);
    expect(local?.pendingSync, isTrue);
    await expectLater(
      store.load(
        accountScope: 'account-a',
        programId: ProgramId.clearAir,
        accessToken: 'token',
      ),
      throwsA(
        isA<ProgramDataLoadException>().having(
          (error) => error.local?.revision,
          'preserved local revision',
          2,
        ),
      ),
    );
  });

  test('a committed PUT with a lost response reconciles as synchronized',
      () async {
    final api = _CommittedThenLostApi();
    final store = SecureProgramStore(api: api);
    final result = await store.save(
      accountScope: 'account-a',
      programId: ProgramId.steady,
      payload: {'readings': <Object?>[]},
      revision: 1,
      accessToken: 'token',
    );

    expect(result.synced, isTrue);
    expect(result.revision, 1);
    final local = await store.load(
      accountScope: 'account-a',
      programId: ProgramId.steady,
    );
    expect(local?.pendingSync, isFalse);
  });

  test('later offline edits survive ambiguous reconciliation and restart',
      () async {
    final store = SecureProgramStore(api: _OfflineApi());
    await store.save(
      accountScope: 'account-a',
      programId: ProgramId.heartwise,
      payload: {'bpReadings': <Object?>[]},
      revision: 1,
      accessToken: 'token',
    );
    final result = await store.save(
      accountScope: 'account-a',
      programId: ProgramId.heartwise,
      payload: {
        'bpReadings': <Object?>[
          {'id': 'bp-1'}
        ],
      },
      revision: 1,
      accessToken: 'token',
    );

    expect(result.synced, isFalse);
    final restored = await store.load(
      accountScope: 'account-a',
      programId: ProgramId.heartwise,
    );
    expect(restored?.payload['bpReadings'], [
      {'id': 'bp-1'}
    ]);
    expect(restored?.pendingSync, isTrue);
  });

  test('oversized health payload is rejected before local or network write',
      () async {
    final store = SecureProgramStore();
    await expectLater(
      store.save(
        accountScope: 'account-a',
        programId: ProgramId.heartwise,
        payload: {'note': List.filled(33000, 'x').join()},
        revision: 1,
      ),
      throwsStateError,
    );
  });
}

class _OfflineApi implements ProgramDataApiClient {
  @override
  Future<ProgramDataDocument?> get(String token, ProgramId programId) =>
      Future.error(StateError('offline'));

  @override
  Future<void> put(
    String token,
    ProgramId programId,
    ProgramDataDocument document,
  ) =>
      Future.error(StateError('offline'));
}

class _CommittedThenLostApi implements ProgramDataApiClient {
  ProgramDataDocument? remote;

  @override
  Future<ProgramDataDocument?> get(String token, ProgramId programId) async =>
      remote;

  @override
  Future<void> put(
    String token,
    ProgramId programId,
    ProgramDataDocument document,
  ) async {
    remote = ProgramDataDocument(
      payload: document.payload,
      revision: document.revision,
    );
    throw StateError('response lost');
  }
}
