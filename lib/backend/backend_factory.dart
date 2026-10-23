// Builds the one backend of this run from the build's configuration.
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'backend.dart';
import 'http/http_backend.dart';
import 'sandbox/sandbox_backend.dart';

/// The backend for [config]'s mode.
///
/// Throws an [ArgumentError] when the configuration names no valid mode; the
/// app checks this before it starts ([AppConfig.validate]) and shows the
/// misconfigured-build screen instead. [debug] exists for tests.
Backend createBackend(AppConfig config, {bool debug = kDebugMode}) {
  final mode = config.backendMode(debug: debug);
  if (mode == null) {
    throw ArgumentError(config.backendModeProblem(debug: debug));
  }
  return switch (mode) {
    BackendMode.sandbox => SandboxBackend(),
    BackendMode.http => HttpBackend(config),
  };
}
