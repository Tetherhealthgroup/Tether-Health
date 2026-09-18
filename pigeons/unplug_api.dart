// The Unplug channel contract — addendum §2.3.
//
// This file is the single source of truth for the boundary between Dart and
// the two native implementations. Run tool/generate_pigeon.sh after any change;
// the generated Dart, Swift and Kotlin are checked in and must never be edited
// by hand.
//
// Keep this surface small. Everything above it — tier logic, the role matrix,
// the escalation policy — stays in Dart. If a native implementation starts
// needing to know what a tier means, the contract has grown the wrong way.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/unplug/platform/unplug_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Unplug/UnplugApi.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/TetherHealthLLC/tetherhealth/unplug/UnplugApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.TetherHealthLLC.tetherhealth.unplug',
    ),
    dartPackageName: 'tether_health',
  ),
)
/// Which authorization iOS is being asked for.
///
/// `child` is the one that needs an iCloud Family and the guardian's Screen
/// Time passcode (§3.1). Android ignores the distinction.
enum PlatformAuthorizationMode { individual, child }

/// The outcome of asking for authorization.
enum PlatformAuthorizationStatus {
  notRequested,
  approved,
  denied,

  /// iOS only: the device is not in an iCloud Family, so a child device cannot
  /// be shielded at all. No amount of retrying changes this.
  blockedNoFamilySharing,

  /// The platform has no screen-time API this build can use.
  unavailable,
}

/// What a session or shield applies to.
enum PlatformShieldScope { selectedApps, everythingExceptAllowlist }

/// Which gate the intercept offers, when the tier calls for one.
enum PlatformEffortGate { none, breath, commitment, puzzle }

/// The live configuration the intercept reads.
///
/// This is what lands in the App Group container on iOS, where the extensions
/// pick it up; on Android it is held by the foreground service.
class PlatformModuleConfig {
  PlatformModuleConfig({
    required this.tier,
    required this.overrideAllowance,
    required this.overridesUsed,
    required this.gate,
    required this.strict,
  });

  int tier;
  int overrideAllowance;
  int overridesUsed;
  PlatformEffortGate gate;
  bool strict;
}

/// The apps the person chose, as the module is allowed to describe them.
///
/// There are no app identifiers here on purpose. iOS cannot give them, and
/// carrying them on Android only would make the two platforms tell a care team
/// different stories (§1). The native side holds the real selection privately.
class PlatformAppSelection {
  PlatformAppSelection({
    required this.groupLabels,
    required this.groupAppCounts,
    required this.totalApps,
  });

  List<String> groupLabels;
  List<int> groupAppCounts;
  int totalApps;
}

/// The budgets that fire a threshold callback.
class PlatformThresholds {
  PlatformThresholds({required this.minutes, required this.opens});

  List<int> minutes;
  List<int> opens;
}

/// One named app with a real duration. Android only — see [PlatformUsage].
class PlatformAppUsage {
  PlatformAppUsage({
    required this.label,
    required this.minutes,
    required this.opens,
  });

  String label;
  int minutes;
  int opens;
}

/// What the platform will actually report for a window of days.
///
/// [perApp] is empty on iOS and populated on Android. [opensAreApproximate] is
/// true on iOS, where the count is derived from shield events rather than real
/// launches, and every surface that shows it must say so.
class PlatformUsage {
  PlatformUsage({
    required this.dailyMinutes,
    required this.daypartMinutes,
    required this.opens,
    required this.opensAreApproximate,
    required this.perApp,
  });

  List<int> dailyMinutes;
  List<int> daypartMinutes;
  int opens;
  bool opensAreApproximate;
  List<PlatformAppUsage> perApp;
}

/// One item of the tracking health check (§2.2).
class PlatformTrackingCheck {
  PlatformTrackingCheck({
    required this.name,
    required this.healthy,
    required this.detail,
  });

  String name;
  bool healthy;
  String detail;
}

/// Calls Dart makes into the platform.
@HostApi()
abstract class UnplugHostApi {
  /// False on web, desktop, and any build without the screen-time layer. Dart
  /// falls back to its own simulation when this is false.
  bool isSupported();

  @async
  PlatformAuthorizationStatus requestAuthorization(
    PlatformAuthorizationMode mode,
  );

  PlatformAuthorizationStatus authorizationStatus();

  /// Presents the system app picker. Returns the number of apps chosen.
  ///
  /// The picker is a system component on both platforms and cannot be drawn by
  /// Flutter, which is why this returns a count and not a list.
  @async
  int presentAppPicker();

  void applyShield(
    PlatformModuleConfig config,
    PlatformAppSelection selection,
  );

  void liftShield(String reason);

  void startSession(
    int durationSeconds,
    PlatformShieldScope scope,
    bool strict,
  );

  void endSession(String? overrideReason);

  void setThresholds(PlatformThresholds thresholds);

  /// Reads the last [days] days. Shaped to the iOS floor on both platforms.
  @async
  PlatformUsage readUsage(int days);

  List<PlatformTrackingCheck> trackingHealth();

  /// Deletes everything the module holds on this device.
  ///
  /// Called by the retention sweep (§3.2) and by account deletion.
  void purgeLocalData(int olderThanDays);
}

/// Callbacks the platform makes into Dart.
@FlutterApi()
abstract class UnplugFlutterApi {
  void onThresholdCrossed(int minutesUsed, int opens);

  void onShieldShown(String groupLabel);

  void onShieldDismissed(String groupLabel);

  void onOverrideUsed(String groupLabel, int overridesRemaining);

  /// Fired when a health check starts failing, so the person is told rather
  /// than left believing the module is still running (§2.2).
  void onTrackingStopped(String checkName, String detail);
}
