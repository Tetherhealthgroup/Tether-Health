// The clinician-recorded asthma action plan.
//
// Zones are clinician-recorded — the app never decides them. [recordedBy]
// records who provided the plan so the source is always visible.

/// Asthma action-plan zones, from the clinician's plan.
enum ActionPlanZone {
  green('Green'),
  yellow('Yellow'),
  red('Red');

  const ActionPlanZone(this.label);
  final String label;
}

class ActionPlan {
  const ActionPlan({
    required this.zone,
    required this.recordedBy,
    required this.recordedAt,
    this.note,
  });

  factory ActionPlan.fromJson(Map<String, Object?> json) => ActionPlan(
        zone: ActionPlanZone.values.byName(json['zone']! as String),
        recordedBy: json['recordedBy']! as String,
        recordedAt: DateTime.parse(json['recordedAt']! as String),
        note: json['note'] as String?,
      );

  /// The baseline zone from the clinician's plan.
  final ActionPlanZone zone;

  /// Who recorded the plan — the clinician or care team. Required: a plan
  /// is never recorded without its source.
  final String recordedBy;
  final DateTime recordedAt;
  final String? note;

  Map<String, Object?> toJson() => {
        'zone': zone.name,
        'recordedBy': recordedBy,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'note': note,
      };
}
