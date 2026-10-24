import 'action_plan.dart';

// A daily symptom check-in log.
//
// The [zone] is the action-plan zone the check-in was logged under, per
// the user's own plan. The app does not determine zones clinically.

class SymptomLog {
  const SymptomLog({
    required this.id,
    required this.date,
    required this.symptoms,
    this.peakFlow,
    required this.zone,
  });

  factory SymptomLog.fromJson(Map<String, Object?> json) => SymptomLog(
        id: json['id']! as String,
        date: DateTime.parse(json['date']! as String),
        symptoms: (json['symptoms']! as List<Object?>).cast<String>(),
        peakFlow: json['peakFlow'] as int?,
        zone: ActionPlanZone.values.byName(json['zone']! as String),
      );

  final String id;
  final DateTime date;
  final List<String> symptoms;

  /// Peak-flow meter reading, when the user has one. Missing stays null —
  /// never zero.
  final int? peakFlow;
  final ActionPlanZone zone;

  Map<String, Object?> toJson() => {
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'symptoms': symptoms,
        'peakFlow': peakFlow,
        'zone': zone.name,
      };
}
