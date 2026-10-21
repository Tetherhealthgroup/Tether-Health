/// The mixed-delivery role matrix from addendum §4.
///
/// Permissions are not hardcoded to a tier. Every program instance declares a
/// delivery track, and that track decides who holds which capability.
///
/// The rule that outranks the rest of this file is §4.1: a distress signal must
/// never terminate at a non-clinical coach. The coach track routes distress to a
/// clinician and the self-guided track shows a resource card and starts a
/// documented triage. Neither may be configured to simply absorb it.
library;

/// Who delivers a program instance.
enum DeliveryTrack {
  clinician(
    'Clinician',
    'A licensed clinician holds the program and receives every flag.',
  ),
  coach(
    'Coach',
    'A non-clinical coach holds the program. Distress routes past them to a '
        'clinician.',
  ),
  selfGuided(
    'Self-guided',
    'No human reviewer. The app is not treatment and says so at enrollment.',
  );

  const DeliveryTrack(this.label, this.description);

  final String label;
  final String description;
}

/// How a capability resolves, used to colour the matrix.
enum GrantKind {
  /// Held outright.
  allowed,

  /// Held, but gated on consent, a delay or a case-by-case decision.
  conditional,

  /// Not held by this track.
  blocked,

  /// Meaningless for this track.
  notApplicable,
}

/// One cell of the role matrix.
class CapabilityGrant {
  const CapabilityGrant(this.label, this.kind);

  const CapabilityGrant.allowed(String label) : this(label, GrantKind.allowed);

  const CapabilityGrant.conditional(String label)
      : this(label, GrantKind.conditional);

  const CapabilityGrant.blocked(String label) : this(label, GrantKind.blocked);

  const CapabilityGrant.notApplicable() : this('n/a', GrantKind.notApplicable);

  final String label;
  final GrantKind kind;
}

/// One row of the role matrix.
class TrackCapability {
  const TrackCapability({
    required this.name,
    required this.clinician,
    required this.coach,
    required this.selfGuided,
    this.note,
  });

  final String name;
  final CapabilityGrant clinician;
  final CapabilityGrant coach;
  final CapabilityGrant selfGuided;

  /// Why the row resolves the way it does, where that is not obvious.
  final String? note;

  CapabilityGrant grantFor(DeliveryTrack track) => switch (track) {
        DeliveryTrack.clinician => clinician,
        DeliveryTrack.coach => coach,
        DeliveryTrack.selfGuided => selfGuided,
      };
}

/// The role matrix from addendum §4, row for row.
const trackCapabilities = <TrackCapability>[
  TrackCapability(
    name: 'View derived metrics',
    clinician: CapabilityGrant.allowed('Yes'),
    coach: CapabilityGrant.allowed('Yes'),
    selfGuided: CapabilityGrant.conditional('Self only'),
  ),
  TrackCapability(
    name: 'View journal and mood tags',
    clinician: CapabilityGrant.conditional('With consent'),
    coach: CapabilityGrant.blocked('No'),
    selfGuided: CapabilityGrant.conditional('Self only'),
    note: 'A coach never reads free text. The tags that drive escalation are '
        'evaluated by policy, not read by the coach.',
  ),
  TrackCapability(
    name: 'Set tier ceiling',
    clinician: CapabilityGrant.allowed('Yes'),
    coach: CapabilityGrant.allowed('Yes'),
    selfGuided: CapabilityGrant.allowed('Self'),
  ),
  TrackCapability(
    name: 'Approve escalation',
    clinician: CapabilityGrant.allowed('Yes'),
    coach: CapabilityGrant.allowed('Yes'),
    selfGuided: CapabilityGrant.conditional('Automatic on evidence'),
  ),
  TrackCapability(
    name: 'Approve limit increase',
    clinician: CapabilityGrant.allowed('Yes'),
    coach: CapabilityGrant.allowed('Yes'),
    selfGuided: CapabilityGrant.conditional('24h cool-off'),
    note: 'Loosening a limit is the one direction that always costs something: '
        'a reviewer, or a wait.',
  ),
  TrackCapability(
    name: 'Receive engagement flags',
    clinician: CapabilityGrant.allowed('Yes'),
    coach: CapabilityGrant.allowed('Yes'),
    selfGuided: CapabilityGrant.conditional('In-app only'),
  ),
  TrackCapability(
    name: 'Receive distress flags',
    clinician: CapabilityGrant.allowed('Yes'),
    coach: CapabilityGrant.conditional('Route to clinician'),
    selfGuided: CapabilityGrant.conditional('Resource card, then triage'),
    note:
        'Addendum §4.1. The escalation policy is owned by clinical leadership '
        'per program; it is configuration, not app logic.',
  ),
  TrackCapability(
    name: 'Override guardian settings',
    clinician: CapabilityGrant.conditional('Case-by-case, logged'),
    coach: CapabilityGrant.blocked('No'),
    selfGuided: CapabilityGrant.notApplicable(),
  ),
];

/// Where a distress signal goes on a given track.
///
/// This exists so no screen has to reimplement §4.1 for itself.
String distressRouteFor(DeliveryTrack track) => switch (track) {
      DeliveryTrack.clinician =>
        'Flagged to the clinician holding this program.',
      DeliveryTrack.coach =>
        'Routed past the coach to the on-call clinician named in this '
            "program's escalation policy.",
      DeliveryTrack.selfGuided =>
        'Resource card shown now, and a documented triage opened. If Tether '
            'offers a clinician-led program, a one-tap route into it is '
            'offered here.',
    };
