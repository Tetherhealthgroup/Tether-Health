// A cholesterol lab panel.
//
// Every value is nullable: missing values stay blank — NEVER zero.
// Panels are "lab or clinician provided"; the app never sets or grades
// targets from them.

class CholesterolPanel {
  const CholesterolPanel({
    required this.id,
    this.ldlMgDl,
    this.hdlMgDl,
    this.triglyceridesMgDl,
    this.totalMgDl,
    required this.recordedAt,
    this.source = defaultSource,
  });

  /// Panels come from lab results or the clinician — never invented by
  /// the app or the user from memory alone.
  static const defaultSource = 'Lab or clinician provided';

  factory CholesterolPanel.fromJson(Map<String, Object?> json) =>
      CholesterolPanel(
        id: json['id']! as String,
        ldlMgDl: (json['ldlMgDl'] as num?)?.toDouble(),
        hdlMgDl: (json['hdlMgDl'] as num?)?.toDouble(),
        triglyceridesMgDl: (json['triglyceridesMgDl'] as num?)?.toDouble(),
        totalMgDl: (json['totalMgDl'] as num?)?.toDouble(),
        recordedAt: DateTime.parse(json['recordedAt']! as String),
        source: json['source'] as String? ?? defaultSource,
      );

  final String id;
  final double? ldlMgDl;
  final double? hdlMgDl;
  final double? triglyceridesMgDl;
  final double? totalMgDl;
  final DateTime recordedAt;
  final String source;

  Map<String, Object?> toJson() => {
        'id': id,
        'ldlMgDl': ldlMgDl,
        'hdlMgDl': hdlMgDl,
        'triglyceridesMgDl': triglyceridesMgDl,
        'totalMgDl': totalMgDl,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'source': source,
      };

  /// Validates raw form input. Returns a user-facing error message, or null
  /// when the input is acceptable.
  ///
  /// The numeric bounds below are input-format sanity checks — they are NOT
  /// clinical thresholds, and the app never grades panels against them.
  static String? validate({
    required String ldlText,
    required String hdlText,
    required String triglyceridesText,
    required String totalText,
  }) {
    final values = <String, String>{
      'LDL': ldlText.trim(),
      'HDL': hdlText.trim(),
      'triglycerides': triglyceridesText.trim(),
      'total cholesterol': totalText.trim(),
    };
    if (values.values.every((text) => text.isEmpty)) {
      return 'Enter at least one panel value. Missing values stay blank — they are never treated as zero.';
    }
    for (final entry in values.entries) {
      final text = entry.value;
      if (text.isEmpty) continue;
      final value = double.tryParse(text);
      if (value == null) {
        return 'Panel values must be numbers.';
      }
      if (value < 10 || value > 1500) {
        return 'That ${entry.key} value looks out of range. Check the number and try again.';
      }
    }
    return null;
  }
}
