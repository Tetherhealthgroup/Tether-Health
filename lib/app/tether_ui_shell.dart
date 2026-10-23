// The tether_ui app: hooks, entry screen, platform variants and the session
// lifecycle around the generated screens.
//
// It runs only where selectAppUi picks it (a debug build started with
// --dart-define=TETHER_UI=true). Every profile and release build runs the
// legacy app.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tether_ui/ui/ui.dart';

import '../auth/account_controller.dart';
import '../backend/backend.dart';
import '../config/app_config.dart';
import '../integration/session_lifecycle.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_localizations.dart';
import '../quit_plan/guest_quit_plan_store.dart';
import 'composition.dart';
import 'entry.dart';
import 'native_slots.dart';
import 'production_hooks.dart';
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
  void showEntry(String name) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    final entry = _build(name);
    _entry = entry;
    _entryName = name;
    navigator.pushAndRemoveUntil(entry, (_) => false);
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
  });

  final EntryNavigator entry;
  final AccountController account;
  final ScreenInstances instances;

  /// The app language; when null the shell follows the phone's language.
  final AppLocale? appLocale;

  /// Runs once after the first frame (loading the profile).
  final Future<void> Function()? afterFirstFrame;

  @override
  State<TetherUiShell> createState() => _TetherUiShellState();
}

class _TetherUiShellState extends State<TetherUiShell> {
  late final AppLocale _appLocale;
  late final bool _ownsAppLocale;

  @override
  void initState() {
    super.initState();
    _ownsAppLocale = widget.appLocale == null;
    _appLocale = widget.appLocale ?? AppLocale(store: MemoryAppLocaleStore());
    WidgetsBinding.instance.addObserver(_appLocale);
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
    WidgetsBinding.instance.removeObserver(_appLocale);
    if (_ownsAppLocale) _appLocale.dispose();
    widget.account.removeListener(_onAccountChanged);
    super.dispose();
  }

  void _onAccountChanged() => widget.entry.reresolveIfOnEntry();

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
  });

  /// The backend and the services built on it.
  final Composition composition;
  final ProductionHooks hooks;
  final EntryNavigator entry;
  final SessionLifecycle lifecycle;
  final ScreenInstances instances;
}

/// Starts the tether_ui app: reads the local entry inputs, builds the backend
/// and its services from [config] (the build's defines by default; [backend]
/// replaces the configured one in tests), installs the hooks, starts the
/// session lifecycle, then calls [run] (runApp) with the shell. Nothing here
/// reaches the network before the first frame; the profile loads after it.
Future<TetherUiRuntime> runTetherUi({
  required AccountController account,
  required GuestQuitPlanStore guestStore,
  bool release = kReleaseMode,
  void Function(Widget app) run = runApp,
  TargetPlatform? platform,
  AppLocale? appLocale,
  AppConfig? config,
  Backend? backend,
}) async {
  // Local inputs only: the restored session is already in [account].
  await account.restorePendingAccountDeletion();
  var guestPlan = false;
  try {
    guestPlan = await guestStore.load() != null;
  } catch (_) {
    // An unreadable guest plan counts as none.
  }

  final instances = ScreenInstances();
  final composition = compose(
    config: config ?? AppConfig.fromEnvironment(),
    backend: backend,
    screenInstance: instances.instanceOf,
  );
  final hooks = installProductionHooks(
    release: release,
    api: composition.api,
    data: composition.data,
    auth: composition.auth,
  );
  registerNativeSlots();

  final entry = EntryNavigator(
    platform: platform,
    state: () => EntryState(
      pendingDeletionReceipt:
          account.pendingAccountDeletion != null && !account.isSignedIn,
      passwordRecoveryPending: account.passwordRecoveryPending,
      signedIn: account.isSignedIn,
      onboardingComplete: account.profile?.onboardingCompleted,
      guestPlanPresent: guestPlan,
    ),
  );
  final lifecycle = SessionLifecycle(
    account: account,
    data: hooks.data,
    cleaners: composition.cleaners,
    resetToEntry: () {
      // After a session ends, a guest plan read at launch may have been
      // merged into the account that ended; do not open on it.
      guestPlan = false;
      entry.resetToEntry();
    },
  )..start();

  run(TetherUiShell(
    entry: entry,
    account: account,
    instances: instances,
    appLocale: appLocale,
    afterFirstFrame: () async {
      if (account.isSignedIn) await account.initialize();
    },
  ));
  return TetherUiRuntime(
    composition: composition,
    hooks: hooks,
    entry: entry,
    lifecycle: lifecycle,
    instances: instances,
  );
}
