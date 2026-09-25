import '../program.dart';
import 'models/action_plan.dart';
import 'models/symptom_log.dart';

/// Local-first controller for the ClearAir (asthma) program. All data
/// lives in memory on the device.
///
/// The current zone is derived from the clinician's recorded plan plus
/// today's symptoms: today's latest check-in wins when one exists,
/// otherwise the plan's baseline zone applies. The app never decides a
/// zone clinically. Sync is intentionally not implemented here: when cloud
/// sync ships it goes through the same gateway / repository pattern as
/// `lib/quit_plan/`.
class ClearAirController extends ProgramController {
  ActionPlan? _clinicianPlan;
  final List<SymptomLog> _symptomLogs = <SymptomLog>[];
  int _idCounter = 0;

  ActionPlan? get clinicianPlan => _clinicianPlan;
  List<SymptomLog> get symptomLogs => List.unmodifiable(_symptomLogs);

  /// Records the clinician's action plan. Zones are clinician-recorded:
  /// [recordedBy] is required and the app never decides a zone itself.
  bool recordClinicianPlan({
    required ActionPlanZone zone,
    required String recordedBy,
    String? note,
  }) {
    final clinician = recordedBy.trim();
    if (clinician.isEmpty) {
      setError(
        'Record who provided the action plan — your clinician or care team.',
      );
      return false;
    }
    final trimmedNote = note?.trim();
    _clinicianPlan = ActionPlan(
      zone: zone,
      recordedBy: clinician,
      recordedAt: DateTime.now().toUtc(),
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    );
    clearError();
    notifyListeners();
    return true;
  }

  /// The current zone: today's latest check-in when one exists, otherwise
  /// the baseline zone from the clinician's recorded plan. Null when no
  /// plan has been recorded yet.
  ActionPlanZone? get currentZone {
    final today = _dateOnly(DateTime.now());
    SymptomLog? latest;
    for (final log in _symptomLogs) {
      if (_dateOnly(log.date) == today &&
          (latest == null || log.date.isAfter(latest.date))) {
        latest = log;
      }
    }
    if (latest != null) return latest.zone;
    return _clinicianPlan?.zone;
  }

  /// Completes the daily zone check-in: logs the symptoms and records the
  /// check-in result. The zone comes from the user's own action plan — the
  /// app shows the plan's guidance for the chosen zone.
  ProgramCheckInResult completeZoneCheckIn({
    required List<String> symptoms,
    required ActionPlanZone zone,
    int? peakFlow,
  }) {
    final log = SymptomLog(
      id: 'sym-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}',
      date: DateTime.now().toUtc(),
      symptoms: List.unmodifiable(symptoms),
      peakFlow: peakFlow,
      zone: zone,
    );
    _symptomLogs.add(log);
    clearError();
    final result = CheckInCompleted(completedAt: log.date);
    recordCheckIn(result);
    return result;
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
