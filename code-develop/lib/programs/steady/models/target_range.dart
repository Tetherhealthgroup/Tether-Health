// A clinician-provided glucose target range.
//
// Set ONLY by the clinician or care team — the app never invents one.
// [setBy] records who provided it, so the source is always visible.

class TargetRange {
  const TargetRange({
    required this.minMgDl,
    required this.maxMgDl,
    required this.setBy,
    required this.recordedAt,
  });

  factory TargetRange.fromJson(Map<String, Object?> json) => TargetRange(
        minMgDl: json['minMgDl']! as int,
        maxMgDl: json['maxMgDl']! as int,
        setBy: json['setBy']! as String,
        recordedAt: DateTime.parse(json['recordedAt']! as String),
      );

  final int minMgDl;
  final int maxMgDl;

  /// Who set the range — the clinician or care team. Required: the range
  /// is never recorded without its source.
  final String setBy;
  final DateTime recordedAt;

  Map<String, Object?> toJson() => {
        'minMgDl': minMgDl,
        'maxMgDl': maxMgDl,
        'setBy': setBy,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };
}
