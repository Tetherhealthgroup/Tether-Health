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
    SyncDocumentStore? localStore,
    void Function(String code)? onCode,
  })  : api = TetherApi(backend.transport),
        local = localStore ?? const SecureSyncDocumentStore(),
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

  /// Small encrypted records on the phone: pending onboarding, deletion
  /// records, the Ease safety plan.
  final SyncDocumentStore local;
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

  /// Deletes this phone's sync document, outbox and safety plan of
  /// [accountId]. Throws when a part could not be deleted (the caller
  /// retries).
  Future<void> wipeAccount(String accountId) async {
    await sync.wipe(accountId: accountId);
    await outbox.wipe(accountId: accountId);
    await local.delete(safetyPlanScope(accountId));
  }

  /// The current document version of [purpose] in the member's language,
  /// or null when it cannot be known now.
  Future<(String, ConsentLocale)?> consentDocument(
      ConsentPurpose purpose) async {
    final source = backend;
    if (source is! ConsentDocuments) return null;
    final versions =
        await (source as ConsentDocuments).currentConsentVersions();
    if (versions == null) return null;
    final profile = await api.account.profile();
    final shown = profile.valueOrNull;
    // Without the member's language the right document is unknown.
    if (shown == null) return null;
    final locale = shown.locale == 'es' ? ConsentLocale.es : ConsentLocale.en;
    final version = versions['${purpose.wire}/${locale.wire}'];
    return version == null ? null : (version, locale);
  }
}

/// Where the Ease safety plan is kept (per account, or the guest's).
String safetyPlanScope(String? accountId) =>
    'device.ea.safety-plan.${accountId ?? 'guest'}';
