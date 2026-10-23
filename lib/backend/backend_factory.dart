// Builds the one backend of this run from the build's configuration.
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'backend.dart';
import 'http/http_backend.dart';
import 'sandbox/sandbox_backend.dart';

/// A configuration that names no valid backend mode. [message] names the
/// defines, never their values; the app shows it on the misconfigured-build
/// screen.
class MisconfiguredBuildException implements Exception {
  const MisconfiguredBuildException(this.message);

  final String message;

  @override
  String toString() => 'MisconfiguredBuildException()';
}

/// The backend for [config]'s mode.
///
/// Throws [MisconfiguredBuildException] when the configuration names no
/// valid mode. [debug] exists for tests.
Backend createBackend(AppConfig config, {bool debug = kDebugMode}) {
  final mode = config.backendMode(debug: debug);
  if (mode == null) {
    throw MisconfiguredBuildException(
      'This build is misconfigured. ${config.backendModeProblem(debug: debug)}',
    );
  }
  return switch (mode) {
    BackendMode.sandbox => SandboxBackend(),
    BackendMode.http => HttpBackend(config),
  };
}
