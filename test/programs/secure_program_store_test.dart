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
    expect(
      await store.save(
        accountScope: 'account-a',
        programId: ProgramId.clearAir,
        payload: {'symptomLogs': <Object?>[]},
        revision: 2,
        accessToken: 'token',
      ),
      isFalse,
    );
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
