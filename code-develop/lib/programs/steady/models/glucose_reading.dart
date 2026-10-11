// A glucose reading.
//
// The value is nullable: a missed check-in is recorded as missing —
// NEVER as zero. High readings are data, not failure: the app never
// grades them.

/// When the reading was taken, in the user's own words.
enum GlucoseContext {
  fasting('Fasting'),
  beforeMeal('Before a meal'),
  afterMeal('After a meal'),
  bedtime('Bedtime');

  const GlucoseContext(this.label);
  final String label;
}

class GlucoseReading {
  const GlucoseReading({
    required this.id,
    this.valueMgDl,
    required this.context,
    required this.measuredAt,
    this.note,
  });

  factory GlucoseReading.fromJson(Map<String, Object?> json) =>
      GlucoseReading(
        id: json['id']! as String,
        valueMgDl: json['valueMgDl'] as int?,
        context: GlucoseContext.values.byName(json['context']! as String),
        measuredAt: DateTime.parse(json['measuredAt']! as String),
        note: json['note'] as String?,
      );

  final String id;

  /// mg/dL. Null means the reading was not taken or not entered — never
  /// zero.
  final int? valueMgDl;
  final GlucoseContext context;
  final DateTime measuredAt;
  final String? note;

  Map<String, Object?> toJson() => {
        'id': id,
        'valueMgDl': valueMgDl,
        'context': context.name,
        'measuredAt': measuredAt.toUtc().toIso8601String(),
        'note': note,
      };

  /// Validates a raw value field. Empty is valid — a missing reading stays
  /// missing. Returns a user-facing error message, or null when acceptable.
  ///
  /// The numeric bounds below are input-format sanity checks for a home
  /// glucose meter — they are NOT clinical thresholds, and the app never
  /// grades readings against them.
  static String? validateValue(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    if (value == null) return 'Enter a whole number.';
    if (value < 20 || value > 700) {
      return 'That value looks out of range for a home meter. Check the number and try again.';
    }
    return null;
  }
}
