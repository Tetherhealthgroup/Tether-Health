// Shared foundation for Tether Health program modules.
//
// A "program" is one health area of the Tether Health app (Heartwise,
// Steady, ClearAir, ...). Every program module is local-first: health data
// lives in memory and on the device; nothing is sent anywhere unless the
// user explicitly chooses it. When cloud sync ships, it goes through the
// same gateway / repository pattern the quit-plan feature uses
// (see lib/quit_plan/).
//
// GLOBAL HARD RULES (apply to every program module):
// - Tobacco / smoking-cessation content lives ONLY in BreatheFree.
// - No credentials, keys, or secrets. No analytics.
// - Health data stays in memory / on-device only.
// - Copy is plain-language and non-judgmental; the app never diagnoses
//   or treats. Every program home surface carries the Tether disclaimer.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Programs scaffolded in this foundation round.
enum ProgramId {
  heartwise('heartwise'),
  steady('steady'),
  clearAir('clearAir');

  const ProgramId(this.slug);

  /// Stable string used for routes and storage keys.
  final String slug;
}

/// High-level journey stages shared by program modules.
enum ProgramPhase {
  welcome('Welcome'),
  onboarding('Onboarding'),
  dailySupport('Daily support'),
  rescue('Rescue'),
  progress('Progress');

  const ProgramPhase(this.label);
  final String label;
}

/// Static description of a program: identity, branding color, safety copy,
/// and route prefix. Clinical content is never invented here — safety notes
/// are plain-language pointers to the user's own clinician / care team.
class ProgramSpec {
  const ProgramSpec({
    required this.id,
    required this.name,
    required this.tagline,
    required this.primaryColor,
    required this.safetyNotes,
    required this.routePrefix,
  });

  final ProgramId id;
  final String name;
  final String tagline;

  /// From [AppColors] — programs reuse the existing palette, no new colors.
  final Color primaryColor;
  final List<String> safetyNotes;
  final String routePrefix;
}

/// Specs for every scaffolded program.
const programSpecs = <ProgramId, ProgramSpec>{
  ProgramId.heartwise: ProgramSpec(
    id: ProgramId.heartwise,
    name: 'Heartwise',
    tagline: 'Track blood pressure and cholesterol with your care team.',
    primaryColor: AppColors.coral,
    safetyNotes: <String>[
      'Target ranges come from your clinician — this app never sets or grades them.',
      'Readings are information, never a grade.',
    ],
    routePrefix: '/heartwise',
  ),
  ProgramId.steady: ProgramSpec(
    id: ProgramId.steady,
    name: 'Steady',
    tagline: 'Notice glucose patterns without judgment.',
    primaryColor: AppColors.deepTeal,
    safetyNotes: <String>[
      'Your clinician sets your target range — the app never invents one.',
      'A high reading is information, not a failure.',
      'No calorie counting here.',
    ],
    routePrefix: '/steady',
  ),
  ProgramId.clearAir: ProgramSpec(
    id: ProgramId.clearAir,
    name: 'ClearAir',
    tagline: 'Follow your asthma action plan, day by day.',
    primaryColor: AppColors.tealSecondary,
    safetyNotes: <String>[
      'Your action-plan zones are recorded from your clinician — the app does not decide them.',
      'Red zone always means: follow your red-zone plan and seek urgent care.',
    ],
    routePrefix: '/clearair',
  ),
};

/// Outcome of a program check-in flow (daily check, zone check, ...).
///
/// Sealed so UI can exhaustively handle every outcome.
sealed class ProgramCheckInResult {
  const ProgramCheckInResult();
}

/// The check-in was finished.
final class CheckInCompleted extends ProgramCheckInResult {
  const CheckInCompleted({required this.completedAt, this.note});

  final DateTime completedAt;
  final String? note;
}

/// The user chose to skip this check-in.
final class CheckInSkipped extends ProgramCheckInResult {
  const CheckInSkipped({required this.skippedAt, required this.reason});

  final DateTime skippedAt;
  final String reason;
}

/// The check-in was postponed to a later time.
final class CheckInPostponed extends ProgramCheckInResult {
  const CheckInPostponed({required this.resumeAt});

  final DateTime resumeAt;
}

/// Minimal async-state helper for program screens.
///
/// [ProgramLoading] is work in progress, [ProgramData] is ready,
/// [ProgramError] failed with a user-safe message.
sealed class ProgramState<T> {
  const ProgramState();

  const factory ProgramState.loading() = ProgramLoading<T>;
  const factory ProgramState.data(T value) = ProgramData<T>;
  const factory ProgramState.error(String message) = ProgramError<T>;
}

final class ProgramLoading<T> extends ProgramState<T> {
  const ProgramLoading();
}

final class ProgramData<T> extends ProgramState<T> {
  const ProgramData(this.value);

  final T value;
}

final class ProgramError<T> extends ProgramState<T> {
  const ProgramError(this.message);

  final String message;
}

/// Shared copy constants for every program home surface.
abstract final class ProgramCopy {
  /// The app supports self-tracking alongside professional care; it never
  /// diagnoses or treats. Shown on every program home surface.
  static const disclaimer =
      'Tether does not diagnose or treat any condition and does not replace professional care.';

  /// Privacy footer on every program home surface.
  static const privacyFooter =
      'Nothing is sent unless you choose it. Works offline.';

  /// Offline banner on every program home surface. Program modules are
  /// local-first: they work fully offline with on-device data.
  static const offlineNotice =
      'Works offline — your information stays on this device.';
}

/// Local-first base for program controllers.
///
/// Health data lives in memory (and, once wired, in the same encrypted
/// on-device store / gateway pattern the quit-plan feature uses).
/// Nothing here performs network I/O.
abstract class ProgramController extends ChangeNotifier {
  bool _loading = false;
  String? _errorMessage;
  ProgramCheckInResult? _lastCheckIn;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// The most recent check-in outcome recorded through [recordCheckIn],
  /// if any.
  ProgramCheckInResult? get lastCheckIn => _lastCheckIn;

  @protected
  void setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  @protected
  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  @protected
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Records a check-in outcome using the shared [ProgramCheckInResult]
  /// vocabulary.
  void recordCheckIn(ProgramCheckInResult result) {
    _lastCheckIn = result;
    notifyListeners();
  }

  /// Retry hook for home-screen error states. In-memory stores have nothing
  /// to refetch, so this clears the error; subclasses override it when they
  /// gain a real data source.
  Future<void> retry() async {
    clearError();
  }
}
