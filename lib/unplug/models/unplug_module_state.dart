import 'dart:async';

import 'package:flutter/foundation.dart';

import 'delivery_track.dart';
import 'intercept_tokens.dart';
import 'platform_ceiling.dart';
import 'program_template.dart';

/// Where screen-time authorization has got to.
///
/// `blockedNoFamilySharing` is the iOS-only dead end from addendum §3.1: a
/// child device that is not in an iCloud Family cannot be shielded, and no
/// amount of engineering changes that.
enum AuthorizationState {
  notRequested('Not requested'),
  pending('Waiting for the system prompt'),
  approved('Approved'),
  denied('Denied'),
  blockedNoFamilySharing('Blocked — no Family Sharing');

  const AuthorizationState(this.label);

  final String label;

  bool get isUsable => this == AuthorizationState.approved;
}

/// Whether the guardian has Apple Family Sharing set up, per addendum §3.1.
enum FamilySharingState {
  unknown('Not checked yet'),
  configured('Family Sharing is set up'),
  missing('Family Sharing is not set up');

  const FamilySharingState(this.label);

  final String label;
}

/// What a focus session applies to.
enum SessionScope {
  selectedApps('Selected apps only'),
  everythingExceptAllowlist('Everything except the allowlist');

  const SessionScope(this.label);

  final String label;
}

/// A group of apps the person labelled themselves.
///
/// On iOS the app identities are opaque tokens, so the label is the only name
/// the module will ever have for them. Android could name them, but the module
/// keeps the same shape on both platforms so a care team sees one story.
class AppGroup {
  const AppGroup({
    required this.label,
    required this.appCount,
    this.shielded = true,
  });

  final String label;
  final int appCount;
  final bool shielded;

  AppGroup copyWith({String? label, int? appCount, bool? shielded}) => AppGroup(
        label: label ?? this.label,
        appCount: appCount ?? this.appCount,
        shielded: shielded ?? this.shielded,
      );
}

/// A running focus session.
class FocusSession {
  const FocusSession({
    required this.startedAt,
    required this.duration,
    required this.scope,
    required this.strict,
  });

  final DateTime startedAt;
  final Duration duration;
  final SessionScope scope;

  /// Strict sessions cannot be ended without a reason, which is logged.
  final bool strict;

  DateTime get endsAt => startedAt.add(duration);

  Duration remainingAt(DateTime now) {
    final left = endsAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isCompleteAt(DateTime now) => !now.isBefore(endsAt);
}

/// A pending request to loosen a limit.
///
/// Self-guided programs wait out a cool-off; clinician and coach programs wait
/// for a named reviewer. Both are represented here so screen F does not have to
/// branch on the track twice.
class LimitIncreaseRequest {
  const LimitIncreaseRequest({
    required this.requestedTier,
    required this.requestedAt,
    required this.clearsAt,
    required this.reviewer,
  });

  final int requestedTier;
  final DateTime requestedAt;

  /// When the cool-off expires. Null when a person, not a clock, decides.
  final DateTime? clearsAt;

  /// Who decides. Null when the clock decides.
  final String? reviewer;

  bool isClearedAt(DateTime now) =>
      clearsAt != null && !now.isBefore(clearsAt!);
}

/// One item in the tracking health check.
class TrackingCheck {
  const TrackingCheck({
    required this.name,
    required this.healthy,
    required this.detail,
    required this.remedy,
    required this.platforms,
  });

  final String name;

  /// False when this check is the reason tracking has stopped.
  final bool healthy;

  final String detail;

  /// What the person can actually do about it.
  final String remedy;

  /// The platforms this check applies to.
  final Set<TrackedPlatform> platforms;

  TrackingCheck copyWith({bool? healthy}) => TrackingCheck(
        name: name,
        healthy: healthy ?? this.healthy,
        detail: detail,
        remedy: remedy,
        platforms: platforms,
      );
}

/// A tag the person applied to an urge.
class UrgeTag {
  const UrgeTag(this.label, {this.distress = false});

  final String label;

  /// Distress tags are the ones §4.1 governs. They never stop at a coach.
  final bool distress;
}

/// The tags offered on screen H.
const urgeTags = <UrgeTag>[
  UrgeTag('Bored'),
  UrgeTag('Habit'),
  UrgeTag('Procrastinating'),
  UrgeTag('Anxious', distress: true),
  UrgeTag('Lonely', distress: true),
  UrgeTag('Low', distress: true),
];

/// How many distress tags in a row open the escalation route.
const int distressEscalationThreshold = 2;

/// The cool-off a self-guided person waits before a limit loosens, per §4.
const Duration selfGuidedCoolOff = Duration(hours: 24);

/// The live configuration of one Unplug program instance.
///
/// Screens A–L read and write this one object, so a change made on any screen
/// is visible on every other. Nothing here is persisted or synced: this is the
/// in-app simulation of the module, and the Pigeon contract in §2.3 is where
/// the real implementation would take over.
class UnplugModuleState extends ChangeNotifier {
  UnplugModuleState({TrackedPlatform? platform})
      : _platform = platform ?? _defaultPlatform();

  static TrackedPlatform _defaultPlatform() =>
      defaultTargetPlatform == TargetPlatform.android
          ? TrackedPlatform.android
          : TrackedPlatform.ios;

  TrackedPlatform _platform;
  DeliveryTrack _track = DeliveryTrack.clinician;
  ProgramTemplate? _template;
  int _tier = 2;
  AuthorizationState _authorization = AuthorizationState.notRequested;
  FamilySharingState _familySharing = FamilySharingState.unknown;
  bool _childProfilePaired = false;
  List<AppGroup> _groups = const [
    AppGroup(label: 'Video apps', appCount: 4),
    AppGroup(label: 'Messaging', appCount: 3),
    AppGroup(label: 'News and feeds', appCount: 2, shielded: false),
  ];
  int _overridesUsed = 0;
  int _overrideAllowance = 3;
  FocusSession? _session;
  Timer? _sessionTicker;
  LimitIncreaseRequest? _limitRequest;
  final List<UrgeTag> _recentTags = <UrgeTag>[];
  bool _escalationOpened = false;
  List<TrackingCheck> _checks = _initialChecks;
  InterceptTokens? _tokens;
  Object? _tokenError;

  TrackedPlatform get platform => _platform;
  DeliveryTrack get track => _track;
  ProgramTemplate? get template => _template;
  int get tier => _tier;
  AuthorizationState get authorization => _authorization;
  FamilySharingState get familySharing => _familySharing;
  bool get childProfilePaired => _childProfilePaired;
  List<AppGroup> get groups => List.unmodifiable(_groups);
  int get overridesUsed => _overridesUsed;
  int get overrideAllowance => _overrideAllowance;
  int get overridesLeft =>
      (_overrideAllowance - _overridesUsed).clamp(0, _overrideAllowance);
  FocusSession? get session => _session;
  LimitIncreaseRequest? get limitRequest => _limitRequest;
  List<UrgeTag> get recentTags => List.unmodifiable(_recentTags);
  bool get escalationOpened => _escalationOpened;
  List<TrackingCheck> get checks => List.unmodifiable(_checks);

  /// The shared intercept tokens, once loaded. Null until then.
  InterceptTokens? get tokens => _tokens;

  /// Why the token file could not be read, when it could not.
  Object? get tokenError => _tokenError;

  void setTokens(InterceptTokens value) {
    _tokens = value;
    _tokenError = null;
    notifyListeners();
  }

  void setTokenError(Object error) {
    _tokens = null;
    _tokenError = error;
    notifyListeners();
  }

  /// The checks that apply to the platform currently selected.
  List<TrackingCheck> get applicableChecks => _checks
      .where((check) => check.platforms.contains(_platform))
      .toList(growable: false);

  /// True when every applicable check passes.
  bool get trackingHealthy => applicableChecks.every((check) => check.healthy);

  /// The number of apps across every shielded group.
  int get shieldedAppCount => _groups
      .where((group) => group.shielded)
      .fold(0, (total, group) => total + group.appCount);

  /// The highest tier this program instance may reach.
  int get tierCeiling => _template?.highestTier ?? maxTier;

  /// The lowest tier this program instance may drop to.
  int get tierFloor => _template?.lowestTier ?? 0;

  /// Whether the person may move the tier themselves on this track.
  bool get selfMayMoveTier =>
      _template?.limitControl != LimitControl.guardianOnly;

  /// A tier change that raises friction applies at once; loosening does not.
  bool wouldLoosen(int candidate) => candidate < _tier;

  void selectPlatform(TrackedPlatform value) {
    if (_platform == value) return;
    _platform = value;
    notifyListeners();
  }

  void selectTrack(DeliveryTrack value) {
    if (_track == value) return;
    _track = value;
    _escalationOpened = false;
    notifyListeners();
  }

  /// Applies a template, which resets the tier into the template's range and
  /// switches the track to the one the template declares.
  void applyTemplate(ProgramTemplate value) {
    _template = value;
    _track = value.track;
    _tier = _tier.clamp(value.lowestTier, value.highestTier);
    _limitRequest = null;
    _escalationOpened = false;
    notifyListeners();
  }

  void clearTemplate() {
    if (_template == null) return;
    _template = null;
    _limitRequest = null;
    notifyListeners();
  }

  /// Raises friction immediately, or opens a request when it would loosen.
  ///
  /// Addendum §4: a clinician or coach approves a loosening; a self-guided
  /// person waits out [selfGuidedCoolOff].
  void requestTier(int candidate, {DateTime? now}) {
    final target = candidate.clamp(tierFloor, tierCeiling);
    if (target == _tier) return;

    if (!wouldLoosen(target)) {
      _tier = target;
      _limitRequest = null;
      notifyListeners();
      return;
    }

    final at = now ?? DateTime.now();
    _limitRequest = switch (_track) {
      DeliveryTrack.selfGuided => LimitIncreaseRequest(
          requestedTier: target,
          requestedAt: at,
          clearsAt: at.add(selfGuidedCoolOff),
          reviewer: null,
        ),
      DeliveryTrack.clinician => LimitIncreaseRequest(
          requestedTier: target,
          requestedAt: at,
          clearsAt: null,
          reviewer: 'the clinician holding this program',
        ),
      DeliveryTrack.coach => LimitIncreaseRequest(
          requestedTier: target,
          requestedAt: at,
          clearsAt: null,
          reviewer: 'the coach holding this program',
        ),
    };
    notifyListeners();
  }

  /// Settles a pending request, either because the cool-off expired or because
  /// the named reviewer approved it.
  void settleLimitRequest({DateTime? now}) {
    final request = _limitRequest;
    if (request == null) return;
    if (request.clearsAt != null && !request.isClearedAt(now ?? DateTime.now())) {
      return;
    }
    _tier = request.requestedTier.clamp(tierFloor, tierCeiling);
    _limitRequest = null;
    notifyListeners();
  }

  void withdrawLimitRequest() {
    if (_limitRequest == null) return;
    _limitRequest = null;
    notifyListeners();
  }

  void requestAuthorization() {
    if (_authorization == AuthorizationState.approved) return;
    _authorization = _platform == TrackedPlatform.ios &&
            _familySharing == FamilySharingState.missing
        ? AuthorizationState.blockedNoFamilySharing
        : AuthorizationState.approved;
    notifyListeners();
  }

  void revokeAuthorization() {
    if (_authorization == AuthorizationState.notRequested) return;
    _authorization = AuthorizationState.denied;
    notifyListeners();
  }

  void setFamilySharing(FamilySharingState value) {
    if (_familySharing == value) return;
    _familySharing = value;
    if (value == FamilySharingState.missing) {
      _childProfilePaired = false;
      if (_platform == TrackedPlatform.ios &&
          _authorization == AuthorizationState.approved) {
        _authorization = AuthorizationState.blockedNoFamilySharing;
      }
    }
    notifyListeners();
  }

  void pairChildProfile() {
    if (_familySharing != FamilySharingState.configured) return;
    _childProfilePaired = true;
    notifyListeners();
  }

  void addGroup(String label, int appCount) {
    final trimmed = label.trim();
    if (trimmed.isEmpty || appCount <= 0) return;
    _groups = [..._groups, AppGroup(label: trimmed, appCount: appCount)];
    notifyListeners();
  }

  void removeGroup(int index) {
    if (index < 0 || index >= _groups.length) return;
    _groups = [..._groups]..removeAt(index);
    notifyListeners();
  }

  void toggleGroupShield(int index) {
    if (index < 0 || index >= _groups.length) return;
    final next = [..._groups];
    next[index] = next[index].copyWith(shielded: !next[index].shielded);
    _groups = next;
    notifyListeners();
  }

  /// Records an override of the intercept. Returns false when none are left.
  bool useOverride() {
    if (overridesLeft == 0) return false;
    _overridesUsed++;
    notifyListeners();
    return true;
  }

  void resetOverrides() {
    if (_overridesUsed == 0) return;
    _overridesUsed = 0;
    notifyListeners();
  }

  void setOverrideAllowance(int value) {
    final clamped = value.clamp(0, 10);
    if (clamped == _overrideAllowance) return;
    _overrideAllowance = clamped;
    if (_overridesUsed > clamped) _overridesUsed = clamped;
    notifyListeners();
  }

  void startSession({
    required Duration duration,
    required SessionScope scope,
    required bool strict,
    DateTime? now,
  }) {
    _session = FocusSession(
      startedAt: now ?? DateTime.now(),
      duration: duration,
      scope: scope,
      strict: strict,
    );
    _startTicker();
    notifyListeners();
  }

  /// Ends a session. A strict session requires a reason, which is logged.
  bool endSession({String? reason}) {
    final current = _session;
    if (current == null) return false;
    if (current.strict &&
        !current.isCompleteAt(DateTime.now()) &&
        (reason == null || reason.trim().isEmpty)) {
      return false;
    }
    _session = null;
    _stopTicker();
    notifyListeners();
    return true;
  }

  void _startTicker() {
    _stopTicker();
    _sessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_session == null) {
        _stopTicker();
        return;
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _sessionTicker?.cancel();
    _sessionTicker = null;
  }

  /// Records an urge tag and opens the escalation route when the run of
  /// distress tags reaches [distressEscalationThreshold].
  void tagUrge(UrgeTag tag) {
    _recentTags.insert(0, tag);
    if (_recentTags.length > 8) _recentTags.removeLast();

    final run = _recentTags.takeWhile((entry) => entry.distress).length;
    if (run >= distressEscalationThreshold) _escalationOpened = true;
    notifyListeners();
  }

  void clearUrgeTags() {
    if (_recentTags.isEmpty && !_escalationOpened) return;
    _recentTags.clear();
    _escalationOpened = false;
    notifyListeners();
  }

  /// Flips one health check, so the warning state can be reviewed on device.
  void toggleCheck(String name) {
    _checks = [
      for (final check in _checks)
        if (check.name == name) check.copyWith(healthy: !check.healthy) else check,
    ];
    notifyListeners();
  }

  void restoreTracking() {
    if (trackingHealthy) return;
    _checks = [for (final check in _checks) check.copyWith(healthy: true)];
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}

/// The checks a device is measured against, per addendum §2.2 and the risk
/// register in §5.
const _initialChecks = <TrackingCheck>[
  TrackingCheck(
    name: 'Screen-time authorization',
    healthy: true,
    detail: 'The system still grants this app access to screen-time data.',
    remedy: 'Re-run authorization on screen B.',
    platforms: {TrackedPlatform.ios, TrackedPlatform.android},
  ),
  TrackingCheck(
    name: 'Usage access permission',
    healthy: true,
    detail: 'Usage access is the permission that lets the service read what '
        'is in the foreground.',
    remedy: 'Settings → Apps → Special access → Usage access.',
    platforms: {TrackedPlatform.android},
  ),
  TrackingCheck(
    name: 'Foreground service alive',
    healthy: true,
    detail: 'The polling service has reported in within the last five minutes.',
    remedy:
        'Battery management on Xiaomi, Samsung, Oppo and OnePlus devices kills '
        'this service in four different ways. Exclude the app from battery '
        'optimisation on this device.',
    platforms: {TrackedPlatform.android},
  ),
  TrackingCheck(
    name: 'Overlay permission',
    healthy: true,
    detail: 'Drawing over other apps is what makes the intercept appear.',
    remedy: 'Settings → Apps → Special access → Display over other apps.',
    platforms: {TrackedPlatform.android},
  ),
  TrackingCheck(
    name: 'Device activity schedule',
    healthy: true,
    detail: 'The monitoring schedule is registered and its thresholds are set.',
    remedy: 'Re-apply the schedule from screen F.',
    platforms: {TrackedPlatform.ios},
  ),
  TrackingCheck(
    name: 'App Group container',
    healthy: true,
    detail:
        'The extensions read tier state and override counts from the shared '
        'container. Without it the intercept runs on stale configuration.',
    remedy: 'Reinstall the app so the container is recreated.',
    platforms: {TrackedPlatform.ios},
  ),
];
