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
/// The tether_ui screens run only in a debug build started with
/// `--dart-define=TETHER_UI=true`. Every profile and release build runs the
/// legacy app, whatever defines it was built with: the release scripts cannot
/// pass this define, and [kDebugMode] is false in those builds.
///
/// `lib/main.dart` calls this with no arguments; the parameters exist only so
/// tests can cover each case.
AppUi selectAppUi({
  bool debug = kDebugMode,
  bool requested = const bool.fromEnvironment('TETHER_UI'),
}) =>
    debug && requested ? AppUi.tetherUi : AppUi.legacy;
