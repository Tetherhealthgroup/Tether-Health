import 'package:breathefree_patient/quit_plan/guest_quit_plan_store.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('secure guest snapshot round-trips plan and active state', () async {
    final store = SecureGuestQuitPlanStore(
      now: () => DateTime.utc(2026, 9, 19, 12),
    );

    await store.savePlan(_plan(), stage: GuestPlanStage.active);
    final restored = await store.load();

    expect(restored?.stage, GuestPlanStage.active);
    expect(restored?.savedAt, DateTime.utc(2026, 9, 19, 12));
    expect(restored?.plan.topQuitReason, 'family');
    expect(restored?.plan.quitDate, DateTime(2026, 10));
  });

  test('corrupt guest snapshot is preserved for explicit recovery', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureGuestQuitPlanStore.storageKey: '{not-json',
    });
    final store = SecureGuestQuitPlanStore();

    await expectLater(
      store.load(),
      throwsA(
        isA<GuestQuitPlanStoreException>().having(
          (error) => error.failure,
          'failure',
          GuestQuitPlanStoreFailure.corrupt,
        ),
      ),
    );
    expect(
      await const FlutterSecureStorage()
          .read(key: SecureGuestQuitPlanStore.storageKey),
      '{not-json',
    );
  });
}

QuitPlan _plan() => QuitPlan(
      userId: '',
      dailyCigaretteUse: 'tenOrFewer',
      smokingTriggers: const ['stress'],
      customSmokingTrigger: null,
      readinessPath: 'prepare',
      quitPlanPath: 'setQuitDate',
      quitDate: DateTime(2026, 10),
      quitDayCheckIn: true,
      quitReasons: const ['family'],
      customQuitReason: null,
      topQuitReason: 'family',
      supportPeople: const [],
      preparationTasks: const ['removeSupplies'],
      treatmentSupport: true,
      careTeamReminder: true,
    );
