import 'package:flutter/foundation.dart';

/// Which user interface the app runs.
enum AppUi {
  /// The current app ([BreatheFreeApp] in `lib/main.dart`).
  legacy,

  /// The tether_ui screens (`lib/app/tether_ui_shell.dart`), still being
  /// wired to the app's services.
  tetherUi,
}

/// Picks the user interface for this build.
///
/// The tether_ui screens run in two cases:
/// - a debug build started with `--dart-define=TETHER_UI=true`;
/// - an internal test build, which the release scripts make only when they
///   are given `--internal-tether-ui`. The script then adds
///   `--dart-define=TETHER_UI_INTERNAL=true` itself and refuses a define file
///   that holds that key, so a store build made without the flag cannot
///   carry it.
///
/// Every other profile and release build runs the legacy app: [kDebugMode] is
/// false in those builds, and the release scripts never pass `TETHER_UI`.
///
/// `lib/main.dart` calls this with no arguments; the parameters exist only so
/// tests can cover each case.
AppUi selectAppUi({
  bool debug = kDebugMode,
  bool requested = const bool.fromEnvironment('TETHER_UI'),
  bool internal = const bool.fromEnvironment('TETHER_UI_INTERNAL'),
}) =>
    (debug && requested) || internal ? AppUi.tetherUi : AppUi.legacy;
