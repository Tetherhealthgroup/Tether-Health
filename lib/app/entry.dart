// The screen the tether_ui app opens on.
import 'package:flutter/foundation.dart';
import 'package:tether_ui/router/routes.dart';

/// What decides the entry screen. Before the first frame every value comes
/// from the phone only (restored session, deletion receipt, recovery link,
/// guest plan); the profile, and with it [onboardingComplete], arrives later.
@immutable
class EntryState {
  const EntryState({
    this.pendingDeletionReceipt = false,
    this.passwordRecoveryPending = false,
    this.minimumBuild,
    this.installedBuild,
    this.signedIn = false,
    this.onboardingComplete,
    this.guestPlanPresent = false,
  });

  /// A completed account deletion whose receipt the member has not yet
  /// acknowledged.
  final bool pendingDeletionReceipt;

  /// A password recovery link was opened.
  final bool passwordRecoveryPending;

  /// The lowest build the service still supports. Null until an app-config
  /// source exists, which skips the update rule.
  final int? minimumBuild;

  /// This app's build number.
  final int? installedBuild;

  final bool signedIn;

  /// Null while the profile has not loaded.
  final bool? onboardingComplete;

  /// A guest quit plan is stored on this phone.
  final bool guestPlanPresent;

  @override
  bool operator ==(Object other) =>
      other is EntryState &&
      other.pendingDeletionReceipt == pendingDeletionReceipt &&
      other.passwordRecoveryPending == passwordRecoveryPending &&
      other.minimumBuild == minimumBuild &&
      other.installedBuild == installedBuild &&
      other.signedIn == signedIn &&
      other.onboardingComplete == onboardingComplete &&
      other.guestPlanPresent == guestPlanPresent;

  @override
  int get hashCode => Object.hash(
        pendingDeletionReceipt,
        passwordRecoveryPending,
        minimumBuild,
        installedBuild,
        signedIn,
        onboardingComplete,
        guestPlanPresent,
      );
}

/// The entry route for [state]. Pure; the first rule that matches wins.
///
/// On Android the update screen opens as its Android variant through the
/// route wrapper (`variants.dart`), not here.
String resolveEntry(EntryState state) {
  if (state.pendingDeletionReceipt) return Routes.accountDeleted;
  if (state.passwordRecoveryPending) return Routes.authNewpass;
  final minimum = state.minimumBuild;
  final installed = state.installedBuild;
  if (minimum != null && installed != null && minimum > installed) {
    return Routes.sysUpdate;
  }
  // Onboarding not yet known counts as complete; known incomplete falls
  // through to welcome.
  if (state.signedIn && state.onboardingComplete != false) return Routes.today;
  if (state.guestPlanPresent) return Routes.today;
  return Routes.welcome;
}
