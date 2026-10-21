// Installs the app's implementations of the tether_ui hooks.
//
// The kit starts debug builds and tests with preview hooks (a chooser for
// every branch, saves that always succeed, sample values) and release builds
// with inert ones. The app never runs on either: it installs its own, the
// same in debug and release, before the first frame.
import 'package:flutter/foundation.dart';
import 'package:tether_ui/ui/ui.dart';

import '../error/privacy_safe_error_reporter.dart';
import '../integration/data_adapter.dart';
import '../integration/device_outcomes.dart';
import '../integration/registry.dart';

/// Receives every code the tether_ui screens report. Codes only: no content,
/// no stack frames with values, and nothing leaves the phone.
class AppCodeReporter {
  AppCodeReporter({PrivacySafeErrorReporter? errors})
      : _errors = errors ?? PrivacySafeErrorReporter();

  final PrivacySafeErrorReporter _errors;

  /// Codes that report something expected rather than a failure. They are
  /// counted here and not reported as errors.
  static const Set<String> informationalCodes = {TCallFallback.shownCode};

  final Map<String, int> _counts = <String, int>{};

  /// How often each informational code was reported in this run.
  Map<String, int> get informationalCounts =>
      Map<String, int>.unmodifiable(_counts);

  /// Reports [code]: counts it when informational, otherwise records it as a
  /// technical error with the privacy-safe reporter.
  void report(String code, [StackTrace? stack]) {
    if (informationalCodes.contains(code)) {
      _counts[code] = (_counts[code] ?? 0) + 1;
      return;
    }
    _errors.record(TUiError(code), stack, source: 'tether_ui');
  }

  /// [report] without a stack, for hooks that pass only a code.
  void code(String code) => report(code);
}

/// The hooks [installProductionHooks] installed.
@immutable
class ProductionHooks {
  const ProductionHooks({
    required this.api,
    required this.data,
    required this.device,
    required this.platform,
    required this.resolver,
    required this.reporter,
  });

  final AppApi api;
  final AppData data;
  final AppDevice device;
  final TPlatform platform;
  final TFailClosedResolver resolver;
  final AppCodeReporter reporter;
}

/// Installs the app's hooks. Call before `runApp`.
///
/// [release] is whether this is a release build. The hooks are the same for
/// both values: the app never installs a preview hook. The parameter exists so
/// the release configuration can be tested in a debug test run.
ProductionHooks installProductionHooks({
  required bool release,
  AppApi? api,
  AppData? data,
  AppDevice? device,
  AppCodeReporter? reporter,
}) {
  final codes = reporter ?? AppCodeReporter();
  final hooks = ProductionHooks(
    api: api ?? AppApi(),
    data: data ?? AppData(),
    device: device ?? AppDevice(onCode: codes.code),
    // Calls, texts, links and settings: the platform adapter replaces this
    // inert placeholder (TH-924). Until then a call or text shows the number
    // to dial, and links and settings do nothing.
    platform: TInertPlatform(onCode: codes.code),
    resolver: TFailClosedResolver(onCode: codes.code),
    reporter: codes,
  );
  TApi.instance = hooks.api;
  TData.instance = hooks.data;
  TPlatform.instance = hooks.platform;
  TDevice.instance = hooks.device;
  TNav.branchResolver = hooks.resolver.resolve;
  TNav.redactQuestion = true;
  TNav.reporter = codes.report;
  // Native sign-in is not wired yet, so provider branches fail closed.
  TAuth.instance = null;
  TSim.reset();
  TFlow.onboarding = false;
  return hooks;
}
