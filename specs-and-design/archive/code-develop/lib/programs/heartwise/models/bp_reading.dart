// A blood-pressure reading.
//
// Both values are nullable: a missing value is recorded as missing —
// NEVER as zero. The app never grades readings.

class BpReading {
  const BpReading({
    required this.id,
    this.systolic,
    this.diastolic,
    required this.measuredAt,
    this.note,
  });

  factory BpReading.fromJson(Map<String, Object?> json) => BpReading(
        id: json['id']! as String,
        systolic: json['systolic'] as int?,
        diastolic: json['diastolic'] as int?,
        measuredAt: DateTime.parse(json['measuredAt']! as String),
        note: json['note'] as String?,
      );

  final String id;
  final int? systolic;
  final int? diastolic;
  final DateTime measuredAt;
  final String? note;

  Map<String, Object?> toJson() => {
        'id': id,
        'systolic': systolic,
        'diastolic': diastolic,
        'measuredAt': measuredAt.toUtc().toIso8601String(),
        'note': note,
      };

  /// Validates raw form input. Returns a user-facing error message, or null
  /// when the input is acceptable.
  ///
  /// The numeric bounds below are input-format sanity checks for a home
  /// blood-pressure cuff — they are NOT clinical thresholds, and the app
  /// never grades readings against them.
  static String? validate({
    required String systolicText,
    required String diastolicText,
  }) {
    final systolicRaw = systolicText.trim();
    final diastolicRaw = diastolicText.trim();
    if (systolicRaw.isEmpty && diastolicRaw.isEmpty) {
      return 'Enter a systolic or diastolic value. Missing values stay blank — they are never treated as zero.';
    }
    final systolic = systolicRaw.isEmpty ? null : int.tryParse(systolicRaw);
    final diastolic =
        diastolicRaw.isEmpty ? null : int.tryParse(diastolicRaw);
    if ((systolicRaw.isNotEmpty && systolic == null) ||
        (diastolicRaw.isNotEmpty && diastolic == null)) {
      return 'Readings must be whole numbers.';
    }
    if (systolic != null && (systolic < 40 || systolic > 300)) {
      return 'That systolic value looks out of range for a home cuff. Check the number and try again.';
    }
    if (diastolic != null && (diastolic < 30 || diastolic > 250)) {
      return 'That diastolic value looks out of range for a home cuff. Check the number and try again.';
    }
    return null;
  }
}
