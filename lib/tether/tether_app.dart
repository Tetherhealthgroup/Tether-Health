import 'dart:async';

import 'package:flutter/material.dart';

import 'data/bundle_loader.dart';
import 'data/design_bundle.dart';
import 'router/tether_router.dart';
import 'state/session_store.dart';
import 'state/tether_scope.dart';
import 'state/tether_session.dart';
import 'theme/tether_tokens.dart';

/// The Tether patient app: one host shell, eleven health areas inside it.
///
/// The shell is the product. An area becomes a program by appearing in
/// `areas.json` with a screen list, and two of the eleven go further and pin a
/// product file. Nothing in this widget knows the name of a single area, which
/// is the property that makes the other nine buildable without touching Dart.
class TetherApp extends StatefulWidget {
  const TetherApp({super.key});

  @override
  State<TetherApp> createState() => _TetherAppState();
}

class _TetherAppState extends State<TetherApp> {
  late final Future<TetherSession> _session = _load();

  SessionStore? _store;

  /// Flushes the debounced autosave when the app leaves the foreground.
  ///
  /// Without this the debounce window is a window in which the system can
  /// reclaim the process and take the last edit with it — and backgrounding is
  /// precisely when that happens, because that is when the system goes looking
  /// for memory to reclaim.
  late final AppLifecycleListener _lifecycle;

  void _flush() {
    final store = _store;
    if (store != null) unawaited(store.flush());
  }

  /// Builds the session and gives it back whatever it had last time.
  ///
  /// The order here is the whole of the correctness argument. The bundle is
  /// parsed first because a session cannot exist without it; the snapshot is
  /// restored before the future completes, so the first frame is drawn from
  /// the restored state rather than flashing an empty shell and filling in;
  /// and persistence is bound last, so the restore cannot trigger a save of
  /// the thing it just read.
  ///
  /// Nothing here can fail the launch. [SessionStore.open] falls back to
  /// memory when there is no platform store, and [SessionStore.restore]
  /// discards a snapshot it cannot read — an app that refused to start because
  /// of a bad blob on disk could not be recovered from the device.
  Future<TetherSession> _load() async {
    final bundle = await BundleLoader.load();
    final session = TetherSession(bundle: bundle);

    final store = await SessionStore.open();
    await store.restore(session);
    session.bindPersistence(store);

    _store = store;
    return session;
  }

  @override
  void initState() {
    super.initState();
    // Registered here rather than lazily: the listener has to be in place
    // before the app can be backgrounded, which can happen while the bundle
    // is still parsing.
    _lifecycle = AppLifecycleListener(onPause: _flush, onDetach: _flush);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TetherSession>(
      future: _session,
      builder: (context, snapshot) {
        final theme = TetherTheme.light();

        if (snapshot.hasError) {
          return MaterialApp(
            title: 'Tether Health',
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: _BundleFailure(error: snapshot.error!),
          );
        }

        final session = snapshot.data;
        if (session == null) {
          return MaterialApp(
            title: 'Tether Health',
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: const _BundleLoading(),
          );
        }

        return TetherScope(
          session: session,
          child: MaterialApp(
            title: 'Tether Health',
            debugShowCheckedModeBanner: false,
            restorationScopeId: 'tetherhealth',
            theme: theme,
            onGenerateRoute: (settings) =>
                TetherRouter.onGenerateRoute(settings, session),
            // A name with no route is a bug worth seeing, not a blank screen.
            onUnknownRoute: (settings) => MaterialPageRoute<void>(
              builder: (_) => _BundleFailure(
                error: 'No route is registered for "${settings.name}".',
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The Material theme, derived from the prototype's tokens.
///
/// Material 3 is used for its controls and its accessibility behaviour, not
/// for its look: almost every surface in this app is drawn from
/// [TetherColors], so the theme's job is mainly to stop stray Material
/// defaults — a purple seed, an indigo slider — leaking through.
abstract final class TetherTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: TetherColors.ink,
      onPrimary: Colors.white,
      secondary: TetherColors.coral,
      onSecondary: Colors.white,
      surface: TetherColors.card,
      onSurface: TetherColors.ink,
      outline: TetherColors.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: TetherColors.cream,
      canvasColor: TetherColors.cream,
      dividerColor: TetherColors.line,
      sliderTheme: const SliderThemeData(
        activeTrackColor: TetherColors.coral,
        thumbColor: TetherColors.coral,
        inactiveTrackColor: TetherColors.line,
        overlayColor: Color(0x22EE6F55),
      ),
      textTheme: const TextTheme(
        titleMedium: TetherText.cardTitle,
        bodyMedium: TetherText.cardBody,
        labelLarge: TetherText.button,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

class _BundleLoading extends StatelessWidget {
  const _BundleLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: TetherColors.cream,
      body: Center(
        child: CircularProgressIndicator(color: TetherColors.ink),
      ),
    );
  }
}

/// Shown when the design bundle cannot be read.
///
/// Loudly, and with the real error. The whole app is the bundle rendered; an
/// app that started anyway would be a shell with eleven empty programs in it,
/// and that is a far more confusing thing to debug than a red screen saying
/// which asset failed to parse.
class _BundleFailure extends StatelessWidget {
  const _BundleFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TetherColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The design bundle did not load.',
                style: TetherText.headline,
              ),
              const SizedBox(height: 8),
              const Text(
                'Every screen in this app is rendered from assets/design/. '
                'Nothing can be shown until those files parse.',
                style: TetherText.sub,
              ),
              const SizedBox(height: 16),
              Container(
                padding: TetherSpace.cardPadding,
                decoration: const BoxDecoration(
                  color: TetherColors.coralPale,
                  borderRadius: TetherRadius.blockAll,
                ),
                child: Text('$error', style: TetherText.cardBody),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exposes the parsed bundle to anything that needs the catalogue without
/// needing the session's mutable half.
extension TetherBundleAccess on BuildContext {
  DesignBundle get designBundle => TetherScope.of(this).bundle;
}
