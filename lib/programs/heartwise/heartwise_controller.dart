import 'package:flutter/foundation.dart';

import '../program.dart';
import 'models/bp_reading.dart';
import 'models/cholesterol_panel.dart';

/// Local-first controller for the Heartwise program (hypertension +
/// cholesterol). All data lives in memory on the device.
///
/// Sync is intentionally not implemented here: when cloud sync ships it
/// goes through the same gateway / repository pattern as `lib/quit_plan/`
/// (auth gateway + API client + repository).
class HeartwiseController extends ProgramController {
  final List<BpReading> _bpReadings = <BpReading>[];
  final List<CholesterolPanel> _panels = <CholesterolPanel>[];
  int _idCounter = 0;

  List<BpReading> get bpReadings => List.unmodifiable(_bpReadings);
  List<CholesterolPanel> get cholesterolPanels =>
      List.unmodifiable(_panels);

  BpReading? get latestBpReading =>
      _bpReadings.isEmpty ? null : _bpReadings.last;
  CholesterolPanel? get latestPanel =>
      _panels.isEmpty ? null : _panels.last;

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  /// Adds a blood-pressure reading. Missing values stay `null` — they are
  /// never converted to zero. Returns the new reading's id, or `null` when
  /// the input is rejected (see [BpReading.validate]).
  String? addBpReading({
    int? systolic,
    int? diastolic,
    DateTime? measuredAt,
    String? note,
  }) {
    if (systolic == null && diastolic == null) {
      setError(
        'Add at least one value. Missing values stay blank — they are never treated as zero.',
      );
      return null;
    }
    final trimmedNote = note?.trim();
    final reading = BpReading(
      id: _newId('bp'),
      systolic: systolic,
      diastolic: diastolic,
      measuredAt: (measuredAt ?? DateTime.now()).toUtc(),
      note: trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
    );
    _bpReadings.add(reading);
    clearError();
    notifyListeners();
    return reading.id;
  }

  /// Removes a reading by id. Returns true when something was removed.
  bool removeBpReading(String id) {
    final before = _bpReadings.length;
    _bpReadings.removeWhere((reading) => reading.id == id);
    final removed = _bpReadings.length < before;
    if (removed) notifyListeners();
    return removed;
  }

  /// Adds a cholesterol panel. Missing values stay `null` — never zero.
  /// Returns the new panel's id, or `null` when the input is rejected.
  String? addCholesterolPanel({
    double? ldlMgDl,
    double? hdlMgDl,
    double? triglyceridesMgDl,
    double? totalMgDl,
    DateTime? recordedAt,
    String? source,
  }) {
    if (ldlMgDl == null &&
        hdlMgDl == null &&
        triglyceridesMgDl == null &&
        totalMgDl == null) {
      setError(
        'Add at least one panel value. Missing values stay blank — they are never treated as zero.',
      );
      return null;
    }
    final trimmedSource = source?.trim();
    final panel = CholesterolPanel(
      id: _newId('chol'),
      ldlMgDl: ldlMgDl,
      hdlMgDl: hdlMgDl,
      triglyceridesMgDl: triglyceridesMgDl,
      totalMgDl: totalMgDl,
      recordedAt: (recordedAt ?? DateTime.now()).toUtc(),
      source: trimmedSource == null || trimmedSource.isEmpty
          ? CholesterolPanel.defaultSource
          : trimmedSource,
    );
    _panels.add(panel);
    clearError();
    notifyListeners();
    return panel.id;
  }

  /// Removes a panel by id. Returns true when something was removed.
  bool removeCholesterolPanel(String id) {
    final before = _panels.length;
    _panels.removeWhere((panel) => panel.id == id);
    final removed = _panels.length < before;
    if (removed) notifyListeners();
    return removed;
  }
}
