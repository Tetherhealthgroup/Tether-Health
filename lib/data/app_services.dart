// The data services of one backend: typed API clients, the sync document and
// the outbox, shared by the endpoint handlers and the display values.
import '../api/tether_api.dart';
import '../backend/backend.dart';
import '../integration/outbox.dart';
import '../sync/sync_client.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_store.dart';

/// The services built on one [Backend]. One instance per backend
/// ([AppServices.of]), so handlers and data sources share the same sync
/// document and outbox.
class AppServices {
  AppServices(
    this.backend, {
    SyncDocumentStore? syncStore,
    SyncDocumentStore? outboxStore,
    void Function(String code)? onCode,
  })  : api = TetherApi(backend.transport),
        sync = SyncEngine(
          client: SyncClient(backend.transport),
          store: syncStore ?? const SecureSyncDocumentStore(),
        ) {
    outbox = Outbox(
      transport: backend.transport,
      store: outboxStore ?? const SecureOutboxStore(),
      accountId: () => accountId,
      onCode: onCode,
    );
  }

  static final Expando<AppServices> _byBackend =
      Expando<AppServices>('app services');

  /// The services of [backend], created on first use.
  static AppServices of(Backend backend) =>
      _byBackend[backend] ??= AppServices(backend);

  /// Installs [services] for its backend (tests).
  static void install(AppServices services) =>
      _byBackend[services.backend] = services;

  final Backend backend;
  final TetherApi api;
  final SyncEngine sync;
  late final Outbox outbox;

  /// The signed-in account, or null for a guest.
  String? get accountId => backend.auth.currentIdentity?.id;

  bool get signedIn => accountId != null;

  /// Opens the sync document of the signed-in account (or the guest's) when
  /// another one is open. Call before reading or writing it.
  Future<void> openSync() async {
    final id = accountId;
    final scope = id == null ? guestSyncScope : accountSyncScope(id);
    if (sync.scope != scope || !_opened) {
      await sync.open(accountId: id);
      _opened = true;
    }
  }

  bool _opened = false;

  /// Deletes this phone's sync document and outbox of [accountId].
  Future<void> wipeAccount(String accountId) async {
    await sync.wipe(accountId: accountId);
    await outbox.wipe(accountId: accountId);
  }
}
