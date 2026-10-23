// Shared set-up for the sandbox tests: a sandbox in memory with a settable
// clock, a signed-in synthetic account, and enrolments with core consent.
import 'package:breathefree_patient/api/tether_api.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_api.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_backend.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_store.dart';

class SandboxHarness {
  SandboxHarness({DateTime? now, int maxBytes = SandboxStore.defaultMaxBytes})
      : now = now ?? DateTime.utc(2026, 10, 22, 12) {
    backend = build(maxBytes: maxBytes);
  }

  final MemorySandboxPersistence persistence = MemorySandboxPersistence();
  DateTime now;
  late SandboxBackend backend;

  SandboxBackend build({int maxBytes = SandboxStore.defaultMaxBytes}) =>
      SandboxBackend(
        persistence: persistence,
        clock: () => now,
        offsetOf: (zone, _) => zone == 'UTC' ? Duration.zero : null,
        maxBytes: maxBytes,
      );

  /// A new backend over the same stored document, as after a restart.
  Future<SandboxBackend> restart() async {
    backend = build();
    await backend.restore();
    return backend;
  }

  TetherApi get api => TetherApi(backend.transport);

  int _keys = 0;

  /// A fresh 32-hex Idempotency-Key.
  String key() => (++_keys).toRadixString(16).padLeft(32, '0');

  Future<void> signUp([String email = 'member@sandbox.invalid']) async {
    await backend.auth.signUp(email: email, password: 'synthetic-pass');
  }

  /// Enrols in [code] with [status] and grants core consent. Returns the
  /// enrolment id.
  Future<String> enrol(
    String code, {
    EnrolmentStatus status = EnrolmentStatus.learnOnly,
    bool core = true,
  }) async {
    final enrolment = (await api.enrolments.create(
      programmeCode: code,
      status: status,
      mode: code == 'bf' ? EnrolmentMode.quit : null,
    ))
        .valueOrNull!;
    if (core) {
      final granted = await api.enrolments.grantConsent(
        enrolmentId: enrolment.id,
        purpose: ConsentPurpose.core,
        consentVersion: sandboxConsentVersion,
        locale: ConsentLocale.en,
      );
      if (!granted.isSuccess) throw StateError('core consent failed');
    }
    return enrolment.id;
  }
}
