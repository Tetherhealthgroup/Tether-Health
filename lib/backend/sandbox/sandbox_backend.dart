// The sandbox backend: an in-process server with synthetic data, persisted
// in one encrypted document on the phone. Nothing it holds leaves the
// device.
import '../backend.dart';
import 'day_window.dart';
import 'sandbox_auth.dart';
import 'sandbox_server.dart';
import 'sandbox_store.dart';

/// [Backend] for `TETHER_BACKEND=sandbox`.
class SandboxBackend implements Backend {
  /// [persistence] defaults to the encrypted store; tests pass memory.
  factory SandboxBackend({
    SandboxPersistence persistence = const SecureSandboxPersistence(),
    DateTime Function()? clock,
    ZoneOffset offsetOf = deviceZoneOffset,
    int maxBytes = SandboxStore.defaultMaxBytes,
  }) {
    final store = SandboxStore(persistence, maxBytes: maxBytes);
    final auth = SandboxAuthBackend(store, clock: clock);
    return SandboxBackend._(
      store,
      auth,
      SandboxServer(store, auth, clock: clock, offsetOf: offsetOf),
    );
  }

  SandboxBackend._(this.store, this.auth, this.transport);

  /// The sandbox document.
  final SandboxStore store;

  @override
  BackendMode get mode => BackendMode.sandbox;

  @override
  final SandboxAuthBackend auth;

  @override
  final SandboxServer transport;

  /// Reads the stored session. Call before reading
  /// [AuthBackend.currentIdentity] at startup; until then nobody is signed
  /// in. Never touches storage before it is called or a request is sent.
  Future<void> restore() => auth.restore();

  @override
  Future<void> wipeLocal() async {
    await store.wipe();
    auth.forgetSession();
  }
}
