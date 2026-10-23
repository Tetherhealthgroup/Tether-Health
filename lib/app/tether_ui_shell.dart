// The tether_ui app: hooks, entry screen, platform variants and the session
// lifecycle around the generated screens.
//
// It runs only where selectAppUi picks it (a debug build started with
// --dart-define=TETHER_UI=true, or an internal test build made with the
// release scripts' --internal-tether-ui flag). Every other build runs the
// legacy app.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

import '../api/tether_api.dart';
import '../auth/account_controller.dart';
import '../auth/backend_account.dart';
import '../auth/sign_in_flow.dart';
import '../backend/backend.dart';
import '../backend/backend_factory.dart';
import '../backend/sandbox/sandbox_backend.dart';
import '../config/app_config.dart';
import '../config/misconfigured_build_app.dart';
import '../data/app_services.dart';
import '../integration/deletion_records.dart';
import '../integration/endpoints/auth_endpoints.dart';
import '../integration/endpoints/common.dart';
import '../integration/session_lifecycle.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_localizations.dart';
import '../quit_plan/guest_quit_plan_store.dart';
import 'composition.dart';
import 'entry.dart';
import 'native_slots.dart';
import 'production_hooks.dart';
import 'route_allowlist.dart';
import 'screen_instances.dart';
import 'variants.dart';

/// Owns the tether_ui navigator's entry screen.
///
/// The entry screen is the bottom of the stack: the screen the app opens on,
/// returns to when a session ends, and shows for a runtime entry such as a
/// session expiry or a safety alert ([showEntry]).
class EntryNavigator {
  EntryNavigator({
    required EntryState Function() state,
    GlobalKey<NavigatorState>? navigatorKey,
    TargetPlatform? platform,
  })  : _state = state,
        navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        _platform = platform;

  final EntryState Function() _state;
  final GlobalKey<NavigatorState> navigatorKey;
  final TargetPlatform? _platform;

  Route<dynamic>? _entry;
  String? _entryName;

  /// The platform routes are built for.
  TargetPlatform get platform => _platform ?? defaultTargetPlatform;

  /// The current entry route's name, before any platform variant.
  String? get entryName => _entryName;

  /// Builds the route for [name], with its platform variant.
  Route<dynamic>? route(RouteSettings settings) =>
      generateAppRoute(settings, platform: platform);

  /// The routes the navigator starts with: the resolved entry screen.
  List<Route<dynamic>> initialRoutes() {
    final name = resolveEntry(_state());
    final entry = _build(name);
    _entry = entry;
    _entryName = name;
    return [entry];
  }

  /// Returns to the entry screen for the current state, removing every other
  /// screen.
  void resetToEntry() => showEntry(resolveEntry(_state()));

  /// Makes [name] the entry screen and removes every other screen.
  ///
  /// Only the entry screens and the runtime entries of route_allowlist.dart
  /// open this way; any other name opens the resolved entry screen instead.
  /// A runtime entry that is a sheet (signing in again) opens over the
  /// resolved entry screen, so closing it lands there.
  void showEntry(String name) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    final allowed = isAllowedEntry(name) ? name : resolveEntry(_state());
    final sheet = runtimeEntrySheets.contains(allowed);
    final base = sheet ? resolveEntry(_state()) : allowed;
    final entry = _build(base);
    _entry = entry;
    _entryName = base;
    navigator.pushAndRemoveUntil(entry, (_) => false);
    if (sheet) unawaited(navigator.push(_build(allowed)));
  }

  /// Re-resolves the entry screen after a late input (the profile), but only
  /// while the member is still on the entry screen: never pulls them off a
  /// screen they opened.
  void reresolveIfOnEntry() {
    final name = resolveEntry(_state());
    if (name == _entryName) return;
    final entry = _entry;
    if (entry == null || !entry.isCurrent) return;
    showEntry(name);
  }

  Route<dynamic> _build(String name) =>
      route(RouteSettings(name: name)) ??
      (throw StateError('the entry route is not registered'));
}

/// The tether_ui app widget.
class TetherUiShell extends StatefulWidget {
  const TetherUiShell({
    super.key,
    required this.entry,
    required this.account,
    required this.instances,
    this.afterFirstFrame,
    this.appLocale,
    this.onForeground,
  });

  final EntryNavigator entry;
  final AccountController account;
  final ScreenInstances instances;

  /// The app language; when null the shell follows the phone's language.
  final AppLocale? appLocale;

  /// Runs once after the first frame (loading the profile).
  final Future<void> Function()? afterFirstFrame;

  /// Runs each time the app returns to the foreground.
  final VoidCallback? onForeground;

  @override
  State<TetherUiShell> createState() => _TetherUiShellState();
}

class _TetherUiShellState extends State<TetherUiShell>
    with WidgetsBindingObserver {
  late final AppLocale _appLocale;
  late final bool _ownsAppLocale;

  /// Takes links the platform pushes; added before the MaterialApp's own
  /// observer so a link never reaches the navigator.
  final PushedRouteGate _gate = PushedRouteGate();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_gate);
    _ownsAppLocale = widget.appLocale == null;
    _appLocale = widget.appLocale ?? AppLocale(store: MemoryAppLocaleStore());
    WidgetsBinding.instance.addObserver(_appLocale);
    WidgetsBinding.instance.addObserver(this);
    widget.account.addListener(_onAccountChanged);
    final after = widget.afterFirstFrame;
    if (after != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(after().catchError((Object _) {}));
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_gate);
    WidgetsBinding.instance.removeObserver(_appLocale);
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsAppLocale) _appLocale.dispose();
    widget.account.removeListener(_onAccountChanged);
    super.dispose();
  }

  /// A password-reset link that was opened shows the new-password screen
  /// as the entry screen, wherever the member is; otherwise a late input
  /// re-resolves the entry screen only while the member is on it.
  void _onAccountChanged() {
    final entry = widget.entry;
    if (widget.account.passwordRecoveryPending &&
        entry.entryName != Routes.authNewpass) {
      entry.showEntry(Routes.authNewpass);
      return;
    }
    entry.reresolveIfOnEntry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.onForeground?.call();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _appLocale,
        builder: (context, _) => MaterialApp(
          navigatorKey: widget.entry.navigatorKey,
          title: 'Tether Health',
          debugShowCheckedModeBanner: false,
          theme: tetherTheme(),
          locale: _appLocale.locale,
          supportedLocales: releaseLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          onGenerateRoute: widget.entry.route,
          onGenerateInitialRoutes: (_) => widget.entry.initialRoutes(),
          navigatorObservers: [widget.instances],
        ),
      );
}

/// What [runTetherUi] set up.
class TetherUiRuntime {
  const TetherUiRuntime({
    required this.composition,
    required this.hooks,
    required this.entry,
    required this.lifecycle,
    required this.instances,
    required this.account,
    required this.signIn,
  });

  /// The backend and the services built on it.
  final Composition composition;
  final ProductionHooks hooks;
  final EntryNavigator entry;
  final SessionLifecycle lifecycle;
  final ScreenInstances instances;

  /// The account the screens sign in to.
  final AccountController account;

  /// The sign-in steps shared by the email submits and native sign-in.
  final SignInFlow signIn;
}

/// Starts the tether_ui app: builds the backend and its services from
/// [config] (the build's defines by default; [backend] replaces the
/// configured one in tests), reads the local entry inputs, installs the
/// hooks, starts the session lifecycle, then calls [run] (runApp) with the
/// shell. Nothing here reaches the network before the first frame; the
/// profile loads after it.
///
/// [account] is used when it is enabled (tests, and builds where the app
/// configured Supabase itself). A disabled one (no services configured: the
/// sandbox) is replaced by an account on the backend's own sign-in.
Future<TetherUiRuntime> runTetherUi({
  required AccountController account,
  required GuestQuitPlanStore guestStore,
  bool release = kReleaseMode,
  bool debug = kDebugMode,
  void Function(Widget app) run = runApp,
  TargetPlatform? platform,
  AppLocale? appLocale,
  AppConfig? config,
  Backend? backend,
}) async {
  final instances = ScreenInstances();
  final Composition composition;
  try {
    composition = await compose(
      config: config ?? AppConfig.fromEnvironment(),
      backend: backend,
      screenInstance: instances.instanceOf,
    );
  } on MisconfiguredBuildException catch (error) {
    // Show the problem on screen rather than a blank app.
    run(MisconfiguredBuildApp(message: error.message));
    rethrow;
  }
  final built = composition.backend;
  final member =
      account.enabled ? account : accountControllerFor(composition.backend);

  // Local inputs only: the restored session is already in the backend.
  await member.restorePendingAccountDeletion();
  var guestPlan = false;
  try {
    guestPlan = await guestStore.load() != null;
  } catch (_) {
    // An unreadable guest plan counts as none.
  }

  final hooks = installProductionHooks(
    release: release,
    api: composition.api,
    data: composition.data,
    auth: composition.auth,
  );
  registerNativeSlots();
  // Outside debug builds the new screens run only in internal test builds.
  TEnvironment.badge =
      built.mode == BackendMode.sandbox || !debug ? testBuildBadge : null;
  HandlerKit.programOfScreen = (screen) => programOfScreen(instances, screen);
  HandlerKit.argumentOfScreen = (screen) => argumentOfScreen(instances, screen);

  final signIn = SignInFlow(
    account: member,
    auth: built.auth,
    postAuthHooks: composition.postAuthHooks,
    // Only the guest quit plan counts: it is written only while nobody is
    // signed in, so it is never a previous account's data.
    guestDataPresent: () async => await guestStore.load() != null,
    deletionPending: (id) => pendingServerDeletion(AppServices.of(built), id),
    probeSession: () => _probeSession(built),
  )..openResetLink = built is SandboxBackend ? _sandboxResetLink(built) : null;
  AuthEndpoints.flow = signIn;

  final entry = EntryNavigator(
    platform: platform,
    state: () => EntryState(
      pendingDeletionReceipt:
          member.pendingAccountDeletion != null && !member.isSignedIn,
      passwordRecoveryPending: member.passwordRecoveryPending,
      signedIn: member.isSignedIn,
      onboardingComplete: member.profile?.onboardingCompleted,
      guestPlanPresent: guestPlan,
    ),
  );
  final lifecycle = SessionLifecycle(
    account: member,
    data: hooks.data,
    cleaners: composition.cleaners,
    resetToEntry: () {
      // After a session ends, a guest plan read at launch may have been
      // merged into the account that ended; do not open on it.
      guestPlan = false;
      entry.resetToEntry();
    },
  )..start();
  // A queued save the server later refused for good: the generic error,
  // shown while the app is in the foreground (or on the next return).
  final outbox = AppServices.of(built).outbox;
  void showFailedSaves() {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    // The top screen's context: the toast goes over it.
    final stack = instances.stack;
    final top = stack.isEmpty ? null : stack.last;
    final context = top is ModalRoute ? top.subtreeContext : null;
    if (context == null || outbox.notices.value == 0) return;
    outbox.takeNotices();
    TNav.toast(context, TStrings.of(context).kitGenericError);
  }

  outbox.notices.addListener(showFailedSaves);
  signIn
    ..showEntry = entry.showEntry
    ..openOnTop = (route) {
      final navigator = entry.navigatorKey.currentState;
      if (navigator != null) unawaited(navigator.pushNamed(route));
    }
    ..onSessionExpired = lifecycle.onSessionExpired;

  run(TetherUiShell(
    entry: entry,
    account: member,
    instances: instances,
    appLocale: appLocale,
    afterFirstFrame: () async {
      if (member.isSignedIn) await member.initialize();
    },
    onForeground: () {
      // An opened confirmation link finishes the sign-up; a session that
      // ended elsewhere reaches the session lifecycle.
      unawaited(signIn.finishConfirmedSignUp().catchError((Object _) {}));
      member.syncSession();
      showFailedSaves();
    },
  ));
  return TetherUiRuntime(
    composition: composition,
    hooks: hooks,
    entry: entry,
    lifecycle: lifecycle,
    instances: instances,
    account: member,
    signIn: signIn,
  );
}

/// The environment badge of test builds (owner-approved text).
const String testBuildBadge = 'Test build';

/// The routes of the open screens of [screenId], topmost first, followed by
/// the routes below them.
Iterable<Route<dynamic>> _fromScreen(ScreenInstances instances, String id) {
  final route = _routeOfScreen[id];
  final stack = instances.stack;
  final top = route == null
      ? -1
      : stack.lastIndexWhere((open) => open.settings.name == route);
  return top < 0 ? const [] : stack.sublist(0, top + 1).reversed;
}

final Map<String, String> _routeOfScreen = {
  for (final (id, _, _, route) in AppRouter.catalog) id: route,
};

final RegExp _programmeRoute = RegExp(r'^/p/([a-z]{2})(?:[/?]|$)');

/// The programme the topmost open [screenId] acts on: the programme it was
/// opened with, else the nearest screen below it that has one (for
/// example the program settings under "Leave a program").
String? programOfScreen(ScreenInstances instances, String screenId) {
  for (final route in _fromScreen(instances, screenId)) {
    final arguments = route.settings.arguments;
    if (arguments is TRouteArgs && arguments.program != null) {
      return arguments.program;
    }
    final match = _programmeRoute.firstMatch(route.settings.name ?? '');
    if (match != null) return match.group(1);
  }
  return null;
}

/// The argument (a lesson or record source id) the topmost open
/// [screenId] was opened with, or null. The generated screens pass none
/// yet.
String? argumentOfScreen(ScreenInstances instances, String screenId) {
  final open = _fromScreen(instances, screenId);
  if (open.isEmpty) return null;
  final arguments = open.first.settings.arguments;
  return arguments is String && arguments.isNotEmpty ? arguments : null;
}

/// Opens the reset link the sandbox would have emailed (sandbox only).
Future<void> Function(String email) _sandboxResetLink(SandboxBackend sandbox) =>
    (email) async {
      final token = await sandbox.auth.recoveryTokenFor(email);
      if (token != null) await sandbox.auth.completeRecovery(token);
    };

/// Whether the server still accepts the current session: the profile
/// needs a session but not a recent sign-in.
Future<SessionProbe> _probeSession(Backend backend) async {
  final answer = await AccountApi(backend.transport).profile();
  final error = answer.errorOrNull;
  if (error == null) return SessionProbe.alive;
  if (error.isAuthFailure) return SessionProbe.expired;
  return SessionProbe.unknown;
}
