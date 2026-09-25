import 'dart:async';

import 'package:flutter/foundation.dart';

import '../platform/unplug_api.g.dart';
import '../platform/unplug_platform.dart';
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

/// The gates that fit inside a `ShieldAction` execution window (§2.1).
///
/// The choice lives here rather than on screen D because the intercept reads it
/// from the shared container, and the intercept is a different process.
enum EffortGateChoice {
  breath('Breath', 'A timed breath, with nothing to do but wait it out.'),
  commitment(
    'Typed commitment',
    'Type the sentence. Typing is slow enough to interrupt a reflex.',
  ),
  puzzle('Short puzzle', 'One small sum. Enough thought to break autopilot.');

  const EffortGateChoice(this.label, this.description);

  final String label;
  final String description;

  PlatformEffortGate get platformValue => switch (this) {
        EffortGateChoice.breath => PlatformEffortGate.breath,
        EffortGateChoice.commitment => PlatformEffortGate.commitment,
        EffortGateChoice.puzzle => PlatformEffortGate.puzzle,
      };
}

/// The tier at which the intercept starts offering an effort gate.
const int effortGateTier = 3;

/// The group names a child profile may choose from.
///
/// Addendum §3.2: no free-text fields anywhere on a child-facing profile — no
/// journal, no custom intentions, no names — pick-from-list only. A text field
/// that a child can type into is a text field that can contain anything, and
/// every downstream system then has to be built as though it does.
const childSafeGroupLabels = <String>[
  'Video apps',
  'Games',
  'Messaging',
  'Social',
  'Music',
  'Browsing',
];

/// The reasons a child profile may give for ending a strict session.
const childSafeSessionReasons = <String>[
  'I need it for school',
  'A grown-up asked me to',
  'I pressed it by mistake',
  'Something else',
];

/// How long the module keeps anything on a child profile (§3.2).
const int childRetentionDays = 30;

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
/// is visible on every other.
///
/// When [UnplugPlatform.attach] finds a screen-time layer, every change that
/// the intercept must respect is forwarded across the §2.3 channel and the
/// platform's callbacks are folded back in here. When it does not — on web, on
/// desktop, in a widget test, or on an iOS build whose entitlement has not been
/// granted — the same methods run against this object alone and [isLive] is
/// false. The UI is identical either way; what differs is whether the numbers
/// mean anything, which is why [isLive] is shown in the page header rather than
/// hidden.
///
/// Nothing here is persisted or synced by Dart in either mode. Retention of
/// what the platform holds is [purgeExpiredData]'s job.
class UnplugModuleState extends ChangeNotifier {
  UnplugModuleState({TrackedPlatform? platform})
      : _trackedPlatform = platform ?? _defaultPlatform();

  static TrackedPlatform _defaultPlatform() =>
      defaultTargetPlatform == TargetPlatform.android
          ? TrackedPlatform.android
          : TrackedPlatform.ios;

  TrackedPlatform _trackedPlatform;
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
  UnplugPlatform? _platform;
  EffortGateChoice _gate = EffortGateChoice.breath;
  PlatformUsage? _liveUsage;
  String? _channelFailure;
  int _interceptsShown = 0;
  int _interceptsDismissed = 0;

  TrackedPlatform get platform => _trackedPlatform;
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

  /// True when a real screen-time layer is attached.
  ///
  /// False means every number and every switch on these screens is this
  /// object's own simulation. No screen may imply otherwise.
  bool get isLive => _platform != null;

  /// The gate the intercept offers at [effortGateTier] and above.
  EffortGateChoice get gate => _gate;

  /// True when this device is running as a child profile (§3.2).
  ///
  /// Under lockdown there are no free-text fields anywhere, no journal, no
  /// streaks and nothing shareable, and retention drops to
  /// [childRetentionDays] on-device with only aggregate adherence syncing.
  bool get childLockdownActive => _childProfilePaired;

  /// The gates a child profile may be offered.
  ///
  /// The typed commitment is excluded because typing a sentence is a free-text
  /// field wearing a different hat.
  List<EffortGateChoice> get availableGates => childLockdownActive
      ? const [EffortGateChoice.breath, EffortGateChoice.puzzle]
      : EffortGateChoice.values;

  /// Real usage, when the platform supplied it. Null means screen E is showing
  /// clearly-labelled sample data.
  PlatformUsage? get liveUsage => _liveUsage;

  /// The last channel call that failed, if one has.
  String? get channelFailure => _channelFailure;

  /// Intercepts the platform has reported firing in this window.
  int get interceptsShown => _interceptsShown;

  /// How many of those the person closed rather than pushed through.
  int get interceptsDismissed => _interceptsDismissed;

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

  // --- Platform binding -----------------------------------------------------

  /// Attaches a live screen-time layer. Called once, by [UnplugPlatform.attach].
  void bindPlatform(UnplugPlatform platform) {
    _platform = platform;
    notifyListeners();
  }

  void selectGate(EffortGateChoice value) {
    if (_gate == value) return;
    _gate = value;
    _pushShield();
    notifyListeners();
  }

  /// Sends the current tier, allowance, gate and selection to the platform.
  ///
  /// Every change that the intercept must respect goes through here, so there
  /// is one place where Dart state becomes shared-container state rather than
  /// a dozen scattered calls.
  void _pushShield() {
    final platform = _platform;
    if (platform == null) return;
    unawaited(
      platform.applyShield(
        tier: _tier,
        overrideAllowance: _overrideAllowance,
        overridesUsed: _overridesUsed,
        gate: _tier >= effortGateTier
            ? _gate.platformValue
            : PlatformEffortGate.none,
        strict: _session?.strict ?? false,
        groups: _groups,
      ),
    );
  }

  /// Pulls a fresh usage window from the platform.
  Future<void> refreshUsage({int days = 7}) async {
    final platform = _platform;
    if (platform == null) return;
    final usage = await platform.readUsage(days);
    if (usage == null) return;
    _liveUsage = usage;
    notifyListeners();
  }

  /// Runs the retention sweep. On a child profile this is [childRetentionDays].
  Future<void> purgeExpiredData() async {
    final days = _childProfilePaired ? childRetentionDays : 365;
    await _platform?.purgeLocalData(days);
  }

  void applyPlatformAuthorization(PlatformAuthorizationStatus status) {
    final mapped = switch (status) {
      PlatformAuthorizationStatus.notRequested =>
        AuthorizationState.notRequested,
      PlatformAuthorizationStatus.approved => AuthorizationState.approved,
      PlatformAuthorizationStatus.denied => AuthorizationState.denied,
      PlatformAuthorizationStatus.blockedNoFamilySharing =>
        AuthorizationState.blockedNoFamilySharing,
      PlatformAuthorizationStatus.unavailable => AuthorizationState.denied,
    };
    if (_authorization == mapped) return;
    _authorization = mapped;
    notifyListeners();
  }

  /// Replaces the health checks with what the platform actually reports.
  void applyPlatformChecks(List<PlatformTrackingCheck> reported) {
    if (reported.isEmpty) return;
    _checks = [
      for (final check in reported)
        TrackingCheck(
          name: check.name,
          healthy: check.healthy,
          detail: check.detail,
          remedy: _remedyFor(check.name),
          platforms: {_platformOf(check.name)},
        ),
    ];
    notifyListeners();
  }

  void applyThresholdCrossed(int minutesUsed, int opens) {
    _lastThreshold = (minutes: minutesUsed, opens: opens);
    notifyListeners();
  }

  void applyInterceptShown(String groupLabel) {
    _interceptsShown++;
    notifyListeners();
  }

  void applyInterceptDismissed(String groupLabel) {
    _interceptsDismissed++;
    notifyListeners();
  }

  void applyOverrideUsed(int overridesRemaining) {
    _overridesUsed =
        (_overrideAllowance - overridesRemaining).clamp(0, _overrideAllowance);
    notifyListeners();
  }

  void applyTrackingStopped(String checkName) {
    _checks = [
      for (final check in _checks)
        if (check.name == checkName) check.copyWith(healthy: false) else check,
    ];
    notifyListeners();
  }

  void applyChannelFailure(String call, Object error) {
    _channelFailure = '$call: $error';
    notifyListeners();
  }

  ({int minutes, int opens})? _lastThreshold;

  /// The last threshold the platform reported crossing.
  ({int minutes, int opens})? get lastThreshold => _lastThreshold;

  static TrackedPlatform _platformOf(String checkName) => _initialChecks
      .firstWhere(
        (check) => check.name == checkName,
        orElse: () => _initialChecks.first,
      )
      .platforms
      .first;

  static String _remedyFor(String checkName) => _initialChecks
      .firstWhere(
        (check) => check.name == checkName,
        orElse: () => _initialChecks.first,
      )
      .remedy;

  /// The checks that apply to the platform currently selected.
  List<TrackingCheck> get applicableChecks => _checks
      .where((check) => check.platforms.contains(_trackedPlatform))
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
    if (_trackedPlatform == value) return;
    _trackedPlatform = value;
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
      _pushShield();
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
    if (request.clearsAt != null &&
        !request.isClearedAt(now ?? DateTime.now())) {
      return;
    }
    _tier = request.requestedTier.clamp(tierFloor, tierCeiling);
    _limitRequest = null;
    _pushShield();
    notifyListeners();
  }

  void withdrawLimitRequest() {
    if (_limitRequest == null) return;
    _limitRequest = null;
    notifyListeners();
  }

  void requestAuthorization() {
    if (_authorization == AuthorizationState.approved) return;

    final platform = _platform;
    if (platform != null) {
      // The system prompt decides. Nothing is assumed until it answers.
      _authorization = AuthorizationState.pending;
      notifyListeners();
      unawaited(
        platform.requestAuthorization(forChild: _childProfilePaired),
      );
      return;
    }

    _authorization = _trackedPlatform == TrackedPlatform.ios &&
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
      if (_trackedPlatform == TrackedPlatform.ios &&
          _authorization == AuthorizationState.approved) {
        _authorization = AuthorizationState.blockedNoFamilySharing;
      }
    }
    notifyListeners();
  }

  void pairChildProfile() {
    if (_familySharing != FamilySharingState.configured) return;
    _childProfilePaired = true;
    // The typed commitment is a free-text field, so it cannot be the gate on a
    // child profile. Switching here rather than at render time means the
    // intercept — a different process reading the shared container — also stops
    // offering it.
    if (!availableGates.contains(_gate)) _gate = EffortGateChoice.breath;
    _pushShield();
    notifyListeners();
  }

  void unpairChildProfile() {
    if (!_childProfilePaired) return;
    _childProfilePaired = false;
    notifyListeners();
  }

  void addGroup(String label, int appCount) {
    final trimmed = label.trim();
    if (trimmed.isEmpty || appCount <= 0) return;
    _groups = [..._groups, AppGroup(label: trimmed, appCount: appCount)];
    _pushShield();
    notifyListeners();
  }

  void removeGroup(int index) {
    if (index < 0 || index >= _groups.length) return;
    _groups = [..._groups]..removeAt(index);
    _pushShield();
    notifyListeners();
  }

  void toggleGroupShield(int index) {
    if (index < 0 || index >= _groups.length) return;
    final next = [..._groups];
    next[index] = next[index].copyWith(shielded: !next[index].shielded);
    _groups = next;
    _pushShield();
    notifyListeners();
  }

  /// Records an override of the intercept. Returns false when none are left.
  bool useOverride() {
    if (overridesLeft == 0) return false;
    _overridesUsed++;
    // The platform lifts its own shield; its errors are reported through the
    // channel failure path inside liftShield, not through this return value.
    unawaited(_platform?.liftShield('override'));
    _pushShield();
    notifyListeners();
    return true;
  }

  void resetOverrides() {
    if (_overridesUsed == 0) return;
    _overridesUsed = 0;
    _pushShield();
    notifyListeners();
  }

  void setOverrideAllowance(int value) {
    final clamped = value.clamp(0, 10);
    if (clamped == _overrideAllowance) return;
    _overrideAllowance = clamped;
    if (_overridesUsed > clamped) _overridesUsed = clamped;
    _pushShield();
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
    unawaited(
      _platform?.startSession(
            duration: duration,
            scope: scope,
            strict: strict,
          ) ??
          Future<void>.value(),
    );
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
    unawaited(_platform?.endSession(reason) ?? Future<void>.value());
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
        if (check.name == name)
          check.copyWith(healthy: !check.healthy)
        else
          check,
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
