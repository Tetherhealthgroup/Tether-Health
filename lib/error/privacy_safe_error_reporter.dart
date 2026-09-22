import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Local privacy boundary for uncaught errors.
///
/// It intentionally records only an error category and source. Exception
/// messages, widget diagnostics, route arguments, and health payloads are never
/// forwarded to logs or a remote service.
class PrivacySafeErrorReporter {
  void recordFlutterError(FlutterErrorDetails details) {
    record(details.exception, details.stack, source: 'flutter');
  }

  void record(Object error, StackTrace? stack, {required String source}) {
    if (kDebugMode) {
      debugPrint('BreatheFree technical error: $source/${error.runtimeType}');
    }
  }

  Widget buildErrorWidget(FlutterErrorDetails details) => Material(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Semantics(
                liveRegion: true,
                label: 'BreatheFree could not display this screen.',
                child: const Text(
                  'This screen is temporarily unavailable. Close and reopen '
                  'BreatheFree to try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
}
