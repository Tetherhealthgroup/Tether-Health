// The wire types of the sync service (`sync/thsync/wire.py`).
//
// A bundle is one programme's sync data: its answers, keyed by the full
// `programme/screenId`, and its append-only lapses. Enrolment and consent are
// not part of it: the API owns them.
import 'package:flutter/foundation.dart';

/// The eleven programme codes.
const Set<String> programmeCodes = {
  'bf',
  'sf',
  'ca',
  'hw',
  'st',
  're',
  'nu',
  'sd',
  'ea',
  'ck',
  'be',
};

/// Screen ids as the service accepts them.
final RegExp screenIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.:-]{0,63}$');

/// Largest stored answer payload or lapse context, in bytes.
const int maxJsonBytes = 32768;

/// What a person gave on one screen, as four maps keyed by block index
/// (written as a string).
@immutable
class ScreenAnswers {
  const ScreenAnswers({
    this.chips = const {},
    this.option = const {},
    this.slider = const {},
    this.text = const {},
  });

  factory ScreenAnswers.fromJson(Map<String, Object?> json) => ScreenAnswers(
        chips: {
          for (final MapEntry(:key, :value) in _map(json['chips']).entries)
            key: [for (final i in value! as List<Object?>) (i! as num).toInt()],
        },
        option: {
          for (final MapEntry(:key, :value) in _map(json['option']).entries)
            key: (value! as num).toInt(),
        },
        slider: {
          for (final MapEntry(:key, :value) in _map(json['slider']).entries)
            key: (value! as num).toDouble(),
        },
        text: {
          for (final MapEntry(:key, :value) in _map(json['text']).entries)
            key: value! as String,
        },
      );

  static Map<String, Object?> _map(Object? value) => value is Map
      ? {
          for (final e in value.entries)
            if (e.key is String) e.key as String: e.value,
        }
      : const {};

  final Map<String, List<int>> chips;
  final Map<String, int> option;
  final Map<String, double> slider;
  final Map<String, String> text;

  bool get isEmpty =>
      chips.isEmpty && option.isEmpty && slider.isEmpty && text.isEmpty;

  /// Only the non-empty maps, as the service stores them.
  Map<String, Object?> toJson() => {
        if (chips.isNotEmpty) 'chips': chips,
        if (option.isNotEmpty) 'option': option,
        if (slider.isNotEmpty) 'slider': slider,
        if (text.isNotEmpty) 'text': text,
      };

  @override
  bool operator ==(Object other) =>
      other is ScreenAnswers &&
      mapEquals(_flat(chips), _flat(other.chips)) &&
      mapEquals(option, other.option) &&
      mapEquals(slider, other.slider) &&
      mapEquals(text, other.text);

  static Map<String, String> _flat(Map<String, List<int>> chips) =>
      {for (final e in chips.entries) e.key: e.value.join(',')};

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(
            _flat(chips).entries.map((e) => '${e.key}=${e.value}')),
        Object.hashAllUnordered(
            option.entries.map((e) => '${e.key}=${e.value}')),
        Object.hashAllUnordered(
            slider.entries.map((e) => '${e.key}=${e.value}')),
        Object.hashAllUnordered(text.keys),
      );

  /// Never prints answers.
  @override
  String toString() => 'ScreenAnswers(<redacted>)';
}

/// One recorded lapse. Append-only once stored.
@immutable
class Lapse {
  const Lapse({required this.at, this.severity = '', this.context = const []});

  factory Lapse.fromJson(Map<String, Object?> json) => Lapse(
        at: DateTime.parse(json['at']! as String).toUtc(),
        severity: (json['severity'] as String?) ?? '',
        context: [
          for (final c in (json['context'] as List<Object?>?) ?? const [])
            c! as String,
        ],
      );

  final DateTime at;
  final String severity;
  final List<String> context;

  Map<String, Object?> toJson() => {
        'at': at.toUtc().toIso8601String(),
        'severity': severity,
        'context': context,
      };

  /// The same lapse: instant, severity and context (the server's rule).
  bool sameAs(Lapse other) =>
      at.toUtc() == other.at.toUtc() &&
      severity == other.severity &&
      listEquals(context, other.context);

  @override
  String toString() => 'Lapse(<redacted>)';
}

/// One programme's sync data: the unit of sync.
@immutable
class AreaBundle {
  const AreaBundle({
    required this.area,
    this.revision = 0,
    this.baseRevision,
    this.answers = const {},
    this.lapses = const [],
  });

  factory AreaBundle.fromJson(Map<String, Object?> json) => AreaBundle(
        area: json['area']! as String,
        revision: (json['revision'] as num?)?.toInt() ?? 0,
        answers: {
          for (final MapEntry(:key, :value)
              in ((json['answers'] as Map?) ?? const {}).entries)
            key as String:
                ScreenAnswers.fromJson((value as Map).cast<String, Object?>()),
        },
        lapses: [
          for (final l in (json['lapses'] as List<Object?>?) ?? const [])
            Lapse.fromJson((l! as Map).cast<String, Object?>()),
        ],
      );

  final String area;

  /// The server's revision (on a pull).
  final int revision;

  /// The revision this push edits; null when the area is new to the server.
  final int? baseRevision;

  /// Keyed by `area/screenId`.
  final Map<String, ScreenAnswers> answers;
  final List<Lapse> lapses;

  Map<String, Object?> toPushJson() => {
        'area': area,
        'base_revision': baseRevision,
        'answers': {
          for (final e in answers.entries) e.key: e.value.toJson(),
        },
        'lapses': [for (final l in lapses) l.toJson()],
      };

  /// The pull form, as the service sends it.
  Map<String, Object?> toPullJson() => {
        'area': area,
        'revision': revision,
        'answers': {
          for (final e in answers.entries) e.key: e.value.toJson(),
        },
        'lapses': [for (final l in lapses) l.toJson()],
      };

  @override
  String toString() => 'AreaBundle($area, r$revision)';
}

/// A push the server did not apply for one area, with the server's copy.
@immutable
class SyncConflict {
  const SyncConflict({
    required this.area,
    required this.baseRevision,
    required this.serverRevision,
    required this.server,
  });

  factory SyncConflict.fromJson(Map<String, Object?> json) => SyncConflict(
        area: json['area']! as String,
        baseRevision: (json['base_revision'] as num?)?.toInt(),
        serverRevision: (json['server_revision']! as num).toInt(),
        server: AreaBundle.fromJson(
            (json['server']! as Map).cast<String, Object?>()),
      );

  final String area;
  final int? baseRevision;
  final int serverRevision;
  final AreaBundle server;
}

@immutable
class PullResult {
  const PullResult({
    required this.cursor,
    required this.areas,
    required this.currentAreas,
  });

  factory PullResult.fromJson(Map<String, Object?> json) => PullResult(
        cursor: (json['cursor']! as num).toInt(),
        areas: [
          for (final a in json['areas']! as List<Object?>)
            AreaBundle.fromJson((a! as Map).cast<String, Object?>()),
        ],
        currentAreas: {
          for (final a in json['current_areas']! as List<Object?>) a! as String,
        },
      );

  final int cursor;
  final List<AreaBundle> areas;

  /// Every programme the caller has now. A local area missing from it is
  /// dropped, with its unpushed changes.
  final Set<String> currentAreas;
}

@immutable
class PushResult {
  const PushResult({
    required this.cursor,
    required this.applied,
    required this.conflicts,
  });

  factory PushResult.fromJson(Map<String, Object?> json) => PushResult(
        cursor: (json['cursor']! as num).toInt(),
        applied: [
          for (final a in json['applied']! as List<Object?>) a! as String,
        ],
        conflicts: [
          for (final c in json['conflicts']! as List<Object?>)
            SyncConflict.fromJson((c! as Map).cast<String, Object?>()),
        ],
      );

  final int cursor;
  final List<String> applied;
  final List<SyncConflict> conflicts;
}
