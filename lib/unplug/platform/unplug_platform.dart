import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/unplug_module_state.dart';
import 'unplug_api.g.dart';

/// The live end of the channel contract in addendum §2.3.
///
/// When the app is running on a build that carries the screen-time layer, this
/// forwards state changes to the platform and feeds the platform's callbacks
/// back into [UnplugModuleState]. When it is not — web, desktop, a widget test,
/// or an iOS build whose entitlement has not been granted — [attach] returns
/// null and the module keeps running on its own simulation.
///
/// Every state change is applied locally first and reconciled with the platform
/// afterwards. The UI therefore behaves identically in both modes, and a screen
/// never has to know which one it is in. What it must never do is *claim* to be
/// live when it is not, which is why [UnplugModuleState.isLive] exists and is
/// shown in the page header.
class UnplugPlatform implements UnplugFlutterApi {
  UnplugPlatform._(this._host, this._state);

  final UnplugHostApi _host;
  final UnplugModuleState _state;

  /// Connects [state] to the platform, or returns null when there is none.
  ///
  /// A throwing or absent host is treated as "no platform" rather than as an
  /// error: an app whose Unplug module has not been built for this target still
  /// has 28 cessation screens to run.
  static Future<UnplugPlatform?> attach(UnplugModuleState state) async {
    if (kIsWeb) return null;
    final target = defaultTargetPlatform;
    if (target != TargetPlatform.iOS && target != TargetPlatform.android) {
      return null;
    }

    final host = UnplugHostApi();
    try {
      if (!await host.isSupported()) return null;
    } catch (_) {
      return null;
    }

    final platform = UnplugPlatform._(host, state);
    UnplugFlutterApi.setUp(platform);
    state.bindPlatform(platform);
    await platform.refresh();
    return platform;
  }

  /// Pulls authorization and tracking health from the platform.
  Future<void> refresh() async {
    try {
      _state.applyPlatformAuthorization(await _host.authorizationStatus());
      _state.applyPlatformChecks(await _host.trackingHealth());
    } catch (error, stack) {
      _report('refresh', error, stack);
    }
  }

  Future<void> requestAuthorization({required bool forChild}) async {
    try {
      final status = await _host.requestAuthorization(
        forChild
            ? PlatformAuthorizationMode.child
            : PlatformAuthorizationMode.individual,
      );
      _state.applyPlatformAuthorization(status);
    } catch (error, stack) {
      _report('requestAuthorization', error, stack);
    }
  }

  /// Presents the system app picker and returns how many apps were chosen.
  Future<int?> presentAppPicker() async {
    try {
      return await _host.presentAppPicker();
    } catch (error, stack) {
      _report('presentAppPicker', error, stack);
      return null;
    }
  }

  Future<void> applyShield({
    required int tier,
    required int overrideAllowance,
    required int overridesUsed,
    required PlatformEffortGate gate,
    required bool strict,
    required List<AppGroup> groups,
  }) async {
    final shielded = groups.where((group) => group.shielded).toList();
    try {
      await _host.applyShield(
        PlatformModuleConfig(
          tier: tier,
          overrideAllowance: overrideAllowance,
          overridesUsed: overridesUsed,
          gate: gate,
          strict: strict,
        ),
        PlatformAppSelection(
          groupLabels: shielded.map((group) => group.label).toList(),
          groupAppCounts: shielded.map((group) => group.appCount).toList(),
          totalApps: shielded.fold(0, (sum, group) => sum + group.appCount),
        ),
      );
    } catch (error, stack) {
      _report('applyShield', error, stack);
    }
  }

  Future<void> liftShield(String reason) async {
    try {
      await _host.liftShield(reason);
    } catch (error, stack) {
      _report('liftShield', error, stack);
    }
  }

  Future<void> startSession({
    required Duration duration,
    required SessionScope scope,
    required bool strict,
  }) async {
    try {
      await _host.startSession(
        duration.inSeconds,
        scope == SessionScope.selectedApps
            ? PlatformShieldScope.selectedApps
            : PlatformShieldScope.everythingExceptAllowlist,
        strict,
      );
    } catch (error, stack) {
      _report('startSession', error, stack);
    }
  }

  Future<void> endSession(String? reason) async {
    try {
      await _host.endSession(reason);
    } catch (error, stack) {
      _report('endSession', error, stack);
    }
  }

  Future<void> setThresholds({
    required List<int> minutes,
    required List<int> opens,
  }) async {
    try {
      await _host.setThresholds(
        PlatformThresholds(minutes: minutes, opens: opens),
      );
    } catch (error, stack) {
      _report('setThresholds', error, stack);
    }
  }

  /// Reads real usage. Returns null when the platform could not supply it, so
  /// the caller shows sample data clearly labelled rather than a fabricated
  /// measurement.
  Future<PlatformUsage?> readUsage(int days) async {
    try {
      return await _host.readUsage(days);
    } catch (error, stack) {
      _report('readUsage', error, stack);
      return null;
    }
  }

  Future<void> purgeLocalData(int olderThanDays) async {
    try {
      await _host.purgeLocalData(olderThanDays);
    } catch (error, stack) {
      _report('purgeLocalData', error, stack);
    }
  }

  // --- UnplugFlutterApi: callbacks from the platform ------------------------

  @override
  void onThresholdCrossed(int minutesUsed, int opens) =>
      _state.applyThresholdCrossed(minutesUsed, opens);

  @override
  void onShieldShown(String groupLabel) =>
      _state.applyInterceptShown(groupLabel);

  @override
  void onShieldDismissed(String groupLabel) =>
      _state.applyInterceptDismissed(groupLabel);

  @override
  void onOverrideUsed(String groupLabel, int overridesRemaining) =>
      _state.applyOverrideUsed(overridesRemaining);

  @override
  void onTrackingStopped(String checkName, String detail) =>
      _state.applyTrackingStopped(checkName);

  void _report(String call, Object error, StackTrace stack) {
    // A channel failure is a real failure, not something to swallow: the module
    // is no longer doing what the UI says it is. It is reported to the error
    // handler and surfaced on screen I through the health check.
    _state.applyChannelFailure(call, error);
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'unplug',
        context: ErrorDescription('calling $call over the Unplug channel'),
      ),
    );
  }
}
