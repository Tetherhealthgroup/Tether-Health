/// The Unplug v2.1 screen catalog, screens A–L.
///
/// These screens are built as native responsive Flutter views, not as approved
/// bitmap artwork. There is no approved 1290 × 2796 artwork for the Unplug
/// module — the 28 approved screens in `assets/screens/` cover the cessation
/// journey only. Each screen here states which section of
/// `design/unplug-v2.1-integration-addendum.md` it implements, so that a
/// reviewer can check the UI against the source rather than against a picture.
library;

/// The delivery phase a screen belongs to, from addendum §5.
enum UnplugPhase {
  instrument('Phase 1 · Instrument'),
  intervene('Phase 2 · Intervene'),
  escalate('Phase 3 · Escalate & minors'),
  later('Phase 4 · Later');

  const UnplugPhase(this.label);

  final String label;
}

/// One Unplug screen.
class UnplugScreenSpec {
  const UnplugScreenSpec({
    required this.letter,
    required this.title,
    required this.description,
    required this.phase,
    required this.addendumRef,
  });

  /// The screen's letter, A through L.
  final String letter;

  final String title;
  final String description;
  final UnplugPhase phase;

  /// The addendum sections this screen implements.
  final String addendumRef;
}

/// Screens A–L, in the order they are presented.
const unplugScreens = <UnplugScreenSpec>[
  UnplugScreenSpec(
    letter: 'A',
    title: 'What this can see',
    description:
        'States the platform data ceiling before anything is switched on, so '
        'nobody later reads a number that does not exist.',
    phase: UnplugPhase.instrument,
    addendumRef: '§1',
  ),
  UnplugScreenSpec(
    letter: 'B',
    title: 'Apps and authorization',
    description:
        'Requests screen-time authorization and collects the person’s own '
        'labels for the apps they picked, because iOS will not name them.',
    phase: UnplugPhase.instrument,
    addendumRef: '§1, §2.3, §3.1',
  ),
  UnplugScreenSpec(
    letter: 'C',
    title: 'Intercept preview',
    description:
        'The Dart preview of the intercept. The shipped intercept is a SwiftUI '
        'shield and an Android overlay reading the same tokens.',
    phase: UnplugPhase.intervene,
    addendumRef: '§2.1',
  ),
  UnplugScreenSpec(
    letter: 'D',
    title: 'Effort gate',
    description:
        'The three gates that fit inside a ShieldAction execution window: a '
        'breath, a typed commitment, a short puzzle.',
    phase: UnplugPhase.escalate,
    addendumRef: '§2.1',
  ),
  UnplugScreenSpec(
    letter: 'E',
    title: 'Observe Week report',
    description:
        'The baseline report, designed to the iOS floor, with Android’s '
        'per-app split shown as labelled extra detail.',
    phase: UnplugPhase.instrument,
    addendumRef: '§1, §5',
  ),
  UnplugScreenSpec(
    letter: 'F',
    title: 'Tier and limits',
    description:
        'The tier ladder inside the ceiling the track allows, and the cost of '
        'loosening a limit.',
    phase: UnplugPhase.intervene,
    addendumRef: '§4',
  ),
  UnplugScreenSpec(
    letter: 'G',
    title: 'Focus session',
    description:
        'startSession and endSession over the Pigeon contract: duration, '
        'scope, strict mode and a reason when strict is broken.',
    phase: UnplugPhase.intervene,
    addendumRef: '§2.3',
  ),
  UnplugScreenSpec(
    letter: 'H',
    title: 'Urge SOS',
    description:
        'Immediate one-handed help, and the point where a repeated distress '
        'tag leaves the app and reaches a person.',
    phase: UnplugPhase.intervene,
    addendumRef: '§4.1, §5',
  ),
  UnplugScreenSpec(
    letter: 'I',
    title: 'Tracking health',
    description:
        'The in-app check that tells the person when tracking has stopped, '
        'rather than letting them believe it is still running.',
    phase: UnplugPhase.intervene,
    addendumRef: '§2.2, §5 risk register',
  ),
  UnplugScreenSpec(
    letter: 'J',
    title: 'Guardian zone',
    description:
        'The under-13 path: Family Sharing setup with an honest failure state, '
        'and the child-profile lockdown.',
    phase: UnplugPhase.escalate,
    addendumRef: '§3',
  ),
  UnplugScreenSpec(
    letter: 'K',
    title: 'Care team',
    description:
        'The role matrix for the selected delivery track, and where a distress '
        'signal goes on that track.',
    phase: UnplugPhase.escalate,
    addendumRef: '§4, §4.1',
  ),
  UnplugScreenSpec(
    letter: 'L',
    title: 'Program templates',
    description:
        'The three starting configurations, and what applying one changes '
        'about every screen before it.',
    phase: UnplugPhase.later,
    addendumRef: '§4.2',
  ),
];
