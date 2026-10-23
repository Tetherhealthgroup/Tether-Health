// The composition root of the tether_ui app: builds the one backend of this
// run, then everything that talks to it.
//
// Each part has its own factory, filled by the work that owns it; this file
// only connects them:
// - the endpoint handlers and the bound display values
//   (lib/integration/endpoints/handlers.dart);
// - native sign-in for the kit (lib/integration/auth_adapter.dart);
// - the post-auth steps, such as sending onboarding answers recorded before
//   the account existed, which register into [Composition.postAuthHooks].
import 'package:tether_ui/ui/ui.dart';

import '../backend/backend.dart';
import '../backend/backend_factory.dart';
import '../backend/post_auth_hooks.dart';
import '../config/app_config.dart';
import '../integration/auth_adapter.dart';
import '../integration/data_adapter.dart';
import '../integration/endpoints/handlers.dart';
import '../integration/registry.dart';
import '../integration/session_lifecycle.dart';

/// What the endpoint handlers may use.
class HandlerContext {
  const HandlerContext({
    required this.config,
    required this.backend,
    required this.data,
    required this.postAuthHooks,
    required this.cleaners,
  });

  final AppConfig config;
  final Backend backend;

  /// The bound display values.
  final AppData data;

  /// Steps that run after sign-up or sign-in.
  final PostAuthHooks postAuthHooks;

  /// Local cleanup after an account deletion.
  final DeletionCleaners cleaners;
}

/// Everything [compose] built.
class Composition {
  const Composition({
    required this.config,
    required this.backend,
    required this.api,
    required this.auth,
    required this.data,
    required this.postAuthHooks,
    required this.cleaners,
  });

  final AppConfig config;
  final Backend backend;

  /// The production TApi with every handler.
  final AppApi api;

  /// Native sign-in for the kit, or null when not available.
  final TAuth? auth;

  /// The production TData.
  final AppData data;

  final PostAuthHooks postAuthHooks;

  /// Passed to the session lifecycle, which runs them after a deletion.
  final DeletionCleaners cleaners;
}

/// Builds the app's services for [config]: the backend first, which reads
/// what it keeps on the phone ([Backend.init]) before anything reads the
/// sign-in state. [backend] replaces the configured one (tests only).
/// [screenInstance] identifies the submitting screen instance for
/// idempotency keys. Throws [MisconfiguredBuildException] when the
/// configuration names no backend mode.
Future<Composition> compose({
  required AppConfig config,
  Backend? backend,
  ScreenInstanceLookup? screenInstance,
}) async {
  final built = backend ?? createBackend(config);
  await built.init();
  final data = buildAppData(built);
  final postAuthHooks = PostAuthHooks();
  final cleaners = DeletionCleaners();
  final handlers = buildHandlers(HandlerContext(
    config: config,
    backend: built,
    data: data,
    postAuthHooks: postAuthHooks,
    cleaners: cleaners,
  ));
  return Composition(
    config: config,
    backend: built,
    api: AppApi(handlers: handlers, screenInstance: screenInstance),
    auth: buildAuth(built, config),
    data: data,
    postAuthHooks: postAuthHooks,
    cleaners: cleaners,
  );
}
