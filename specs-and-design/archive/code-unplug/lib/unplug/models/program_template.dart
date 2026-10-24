/// Program templates and the tier ladder, from addendum §4.2.
///
/// A template is a starting configuration for a program instance: which track
/// delivers it, which tiers it may reach, which modules are switched on, who
/// sets the limits, and how long it runs.
library;

import 'delivery_track.dart';

/// A behaviour module referenced by a template.
///
/// The addendum names M3, M5, M7 and M11 directly and refers to the rest by
/// identifier only, because their definitions live in the v2 spec. Rather than
/// invent names for the others, they carry a null [name] and the UI shows the
/// identifier alone.
class UnplugModuleRef {
  const UnplugModuleRef(this.id, [this.name]);

  /// The `M`-prefixed identifier used throughout the specification.
  final String id;

  /// The module's name, where the addendum states it.
  final String? name;

  /// True when the addendum does not define what this module is.
  bool get isUnnamed => name == null;
}

/// The modules a template can reference.
///
/// Only the four the addendum defines carry names. See [UnplugModuleRef].
const unplugModules = <String, UnplugModuleRef>{
  'M1': UnplugModuleRef('M1'),
  'M2': UnplugModuleRef('M2'),
  'M3': UnplugModuleRef('M3', 'Open-count budget'),
  'M4': UnplugModuleRef('M4'),
  'M5': UnplugModuleRef('M5', 'Effort gates'),
  'M6': UnplugModuleRef('M6'),
  'M7': UnplugModuleRef('M7', 'Physical key'),
  'M8': UnplugModuleRef('M8'),
  'M9': UnplugModuleRef('M9'),
  'M10': UnplugModuleRef('M10'),
  'M11': UnplugModuleRef('M11', 'Cross-device'),
  'M12': UnplugModuleRef('M12'),
};

/// Who may move a limit inside a program instance.
enum LimitControl {
  guardianOnly('Guardian sets all limits'),
  guardianCeiling('Guardian sets the ceiling, the person sets within it'),
  selfSet('The person sets their own limits');

  const LimitControl(this.label);

  final String label;
}

/// Whether the journal is available, and on what terms.
enum JournalPolicy {
  none('No journal'),
  optIn('Journal, opt-in'),
  on('Journal on by default');

  const JournalPolicy(this.label);

  final String label;
}

/// A starting configuration for a program instance.
class ProgramTemplate {
  const ProgramTemplate({
    required this.name,
    required this.track,
    required this.lowestTier,
    required this.highestTier,
    required this.moduleIds,
    required this.allModules,
    required this.limitControl,
    required this.journal,
    required this.weeks,
    this.assessment,
    this.humanReview = true,
  });

  final String name;
  final DeliveryTrack track;

  /// Inclusive tier range this template may operate in.
  final int lowestTier;
  final int highestTier;

  /// The modules switched on, when the template names them.
  final List<String> moduleIds;

  /// True when the template switches on every module rather than a named set.
  final bool allModules;

  final LimitControl limitControl;
  final JournalPolicy journal;
  final int weeks;

  /// A scheduled instrument, where the template specifies one.
  final String? assessment;

  /// False for templates that run without a human reviewer.
  final bool humanReview;

  String get tierRange => 'Tiers $lowestTier–$highestTier';

  List<UnplugModuleRef> get modules => allModules
      ? unplugModules.values.toList(growable: false)
      : moduleIds
          .map((id) => unplugModules[id])
          .whereType<UnplugModuleRef>()
          .toList(growable: false);
}

/// The three templates in addendum §4.2.
const programTemplates = <ProgramTemplate>[
  ProgramTemplate(
    name: 'Family Reset — under 13',
    track: DeliveryTrack.coach,
    lowestTier: 1,
    highestTier: 2,
    moduleIds: ['M1', 'M2', 'M8', 'M9'],
    allModules: false,
    limitControl: LimitControl.guardianOnly,
    journal: JournalPolicy.none,
    weeks: 6,
  ),
  ProgramTemplate(
    name: 'Teen Digital Health',
    track: DeliveryTrack.clinician,
    lowestTier: 1,
    highestTier: 4,
    moduleIds: ['M1', 'M2', 'M3', 'M5', 'M8', 'M9', 'M12'],
    allModules: false,
    limitControl: LimitControl.guardianCeiling,
    journal: JournalPolicy.optIn,
    weeks: 8,
    assessment: 'BSMAS at weeks 0, 4 and 8',
  ),
  ProgramTemplate(
    name: 'Adult Self-Guided',
    track: DeliveryTrack.selfGuided,
    lowestTier: 0,
    highestTier: 5,
    moduleIds: [],
    allModules: true,
    limitControl: LimitControl.selfSet,
    journal: JournalPolicy.on,
    weeks: 12,
    humanReview: false,
  ),
];

/// What each tier does, in the person's own terms.
///
/// The ladder runs 0–5, the range the Adult Self-Guided template spans. The
/// wording here is the module's, not the v2 spec's, and is written so that a
/// higher tier always reads as more friction rather than more punishment.
const tierDescriptions = <String>[
  'Observe only. Nothing is blocked; the module is just watching so there is '
      'a baseline to compare against.',
  'A reminder when a budget is crossed, which can be dismissed.',
  'An intercept that has to be answered before the app opens.',
  'An intercept with an effort gate: a breath, a typed commitment or a short '
      'puzzle.',
  'A hard stop for the rest of the budget window, with a limited number of '
      'overrides.',
  'A hard stop with no overrides until the window ends.',
];

/// The highest tier the ladder defines.
const int maxTier = 5;
