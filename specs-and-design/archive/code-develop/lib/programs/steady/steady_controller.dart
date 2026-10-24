import '../program.dart';
import 'models/glucose_reading.dart';
import 'models/target_range.dart';

/// Local-first controller for the Steady (diabetes) program. All data
/// lives in memory on the device.
///
/// Streaks and patterns are computed from the data and presented as
/// information only — never as grades. Sync is intentionally not
/// implemented here: when cloud sync ships it goes through the same
/// gateway / repository pattern as `lib/quit_plan/`.
class SteadyController extends ProgramController {
  final List<GlucoseReading> _readings = <GlucoseReading>[];
  TargetRange? _targetRange;
  int _idCounter = 0;

  List<GlucoseReading> get readings => List.unmodifiable(_readings);
  GlucoseReading? get latestReading =>
      _readings.isEmpty ? null : _readings.last;
  TargetRange? get targetRange => _targetRange;

  /// Adds a glucose reading. [valueMgDl] may be null: a missed check-in is
  /// recorded as missing, never as zero. Returns the new reading's id.
  String? addReading({
    int? valueMgDl,
    required GlucoseContext context,
    DateTime? measuredAt,
    String? note,
  }) {
    final trimmedNote = note?.trim();
    final reading = GlucoseReading(
      id: 'glu-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}',
      valueMgDl: valueMgDl,
      context: context,
      measuredAt: (measuredAt ?? DateTime.now()).toUtc(),
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    );
    _readings.add(reading);
    clearError();
    notifyListeners();
    return reading.id;
  }

  /// Removes a reading by id. Returns true when something was removed.
  bool removeReading(String id) {
    final before = _readings.length;
    _readings.removeWhere((reading) => reading.id == id);
    final removed = _readings.length < before;
    if (removed) notifyListeners();
    return removed;
  }

  /// Records the clinician-provided target range. The app never invents
  /// one: [setBy] (the clinician or care team) is required, and the range
  /// must be a valid lower/upper pair.
  bool setTargetRange({
    required int minMgDl,
    required int maxMgDl,
    required String setBy,
  }) {
    final clinician = setBy.trim();
    if (clinician.isEmpty) {
      setError(
        'Record who set the target range — your clinician or care team.',
      );
      return false;
    }
    if (minMgDl <= 0 || maxMgDl <= 0 || minMgDl >= maxMgDl) {
      setError(
        'Enter a valid range: the lower number must be below the upper number.',
      );
      return false;
    }
    _targetRange = TargetRange(
      minMgDl: minMgDl,
      maxMgDl: maxMgDl,
      setBy: clinician,
      recordedAt: DateTime.now().toUtc(),
    );
    clearError();
    notifyListeners();
    return true;
  }

  void clearTargetRange() {
    _targetRange = null;
    notifyListeners();
  }

  /// Consecutive calendar days with at least one logged reading, ending
  /// today or yesterday. Presented as information only — never as a grade.
  int get loggingStreakDays {
    final days = _readings.map((reading) => _dateOnly(reading.measuredAt)).toSet();
    var streak = 0;
    var day = _dateOnly(DateTime.now());
    if (!days.contains(day)) {
      day = day.subtract(const Duration(days: 1));
    }
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// How many readings were logged per context. Counts only — the app
  /// never judges the values.
  Map<GlucoseContext, int> get readingsByContext {
    final counts = <GlucoseContext, int>{
      for (final context in GlucoseContext.values) context: 0,
    };
    for (final reading in _readings) {
      counts[reading.context] = counts[reading.context]! + 1;
    }
    return counts;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
