/// The platform data ceiling described in addendum §1.
///
/// On iOS, `FamilyControls` returns opaque, device-local `ApplicationToken`
/// values. They can be shielded and rendered with Apple's own label view, and
/// nothing more: they cannot be resolved to an app name and cannot leave the
/// device. The `DeviceActivityReport` extension that computes usage detail has
/// no network access by design. Android's `UsageStatsManager` returns real
/// package names and real durations.
///
/// Everything the module shows a clinician is designed to the iOS floor. The
/// Android detail is presented as a bonus and always labelled, so that two
/// platforms never tell a care team different stories about the same patient.
library;

/// The platform whose signal set is being described.
enum TrackedPlatform {
  ios('iOS'),
  android('Android');

  const TrackedPlatform(this.label);

  final String label;
}

/// How much of a signal a platform actually yields.
enum SignalAvailability {
  /// Real values, at the granularity the signal describes.
  full('Available'),

  /// Only a total across the selected set, with no per-app split.
  aggregate('Aggregate only'),

  /// Derived from a proxy, and not the number it appears to be.
  approximate('Approximate'),

  /// Not obtainable, at any effort.
  unavailable('Not available');

  const SignalAvailability(this.label);

  final String label;
}

/// One signal the module may want, and what each platform will give for it.
class PlatformSignal {
  const PlatformSignal({
    required this.name,
    required this.wanted,
    required this.ios,
    required this.iosNote,
    required this.android,
    required this.androidNote,
  });

  /// Short name for the signal.
  final String name;

  /// What the product wanted from this signal.
  final String wanted;

  final SignalAvailability ios;
  final String iosNote;

  final SignalAvailability android;
  final String androidNote;

  SignalAvailability availabilityOn(TrackedPlatform platform) =>
      switch (platform) {
        TrackedPlatform.ios => ios,
        TrackedPlatform.android => android,
      };

  String noteFor(TrackedPlatform platform) => switch (platform) {
        TrackedPlatform.ios => iosNote,
        TrackedPlatform.android => androidNote,
      };
}

/// The signal inventory from addendum §1.
const platformSignals = <PlatformSignal>[
  PlatformSignal(
    name: 'Per-app named minutes',
    wanted: 'Named apps with per-app durations in the care-team dashboard.',
    ios: SignalAvailability.unavailable,
    iosNote:
        'Tokens are opaque and device-local. Show the selected set as an '
        'aggregate, plus the groups the person labelled themselves.',
    android: SignalAvailability.full,
    androidNote:
        'UsageStatsManager returns real package names and real durations.',
  ),
  PlatformSignal(
    name: 'Baseline per-app split',
    wanted: 'A baseline report broken down app by app.',
    ios: SignalAvailability.aggregate,
    iosNote: 'Aggregate total, opens and time-of-day only.',
    android: SignalAvailability.full,
    androidNote: 'Full split, in addition to the aggregate.',
  ),
  PlatformSignal(
    name: 'Open counts',
    wanted: 'A true launch count, to drive the open-count budget.',
    ios: SignalAvailability.approximate,
    iosNote:
        'Approximated from shield-event counts. These are intercepts fired, '
        'not launches, and the two diverge once a shield is lifted.',
    android: SignalAvailability.full,
    androidNote: 'Real foreground transitions from the usage event stream.',
  ),
  PlatformSignal(
    name: 'Usage thresholds',
    wanted: 'A callback when the person crosses a time budget.',
    ios: SignalAvailability.full,
    iosNote: 'DeviceActivityMonitor fires on schedule and threshold events.',
    android: SignalAvailability.full,
    androidNote: 'Computed by the foreground service from polled usage stats.',
  ),
  PlatformSignal(
    name: 'Shield events',
    wanted: 'How often the intercept fired, and what happened next.',
    ios: SignalAvailability.full,
    iosNote: 'Shown, dismissed and overridden are all observable.',
    android: SignalAvailability.full,
    androidNote: 'The overlay reports the same three outcomes.',
  ),
  PlatformSignal(
    name: 'Self-reported context',
    wanted: 'Why the person reached for the phone.',
    ios: SignalAvailability.full,
    iosNote: 'Anything the person tells the app directly is unrestricted.',
    android: SignalAvailability.full,
    androidNote: 'Anything the person tells the app directly is unrestricted.',
  ),
];
