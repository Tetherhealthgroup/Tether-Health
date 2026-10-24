/// The wire types the sync service speaks.
///
/// These mirror `sync/thsync/wire.py` and deliberately keep its two naming
/// conventions rather than harmonising them: fields that came out of the
/// session document stay camelCase (`joinedOn`, `totalsAndAdherence`) because
/// they are copied to and from [TetherSession.toJson] verbatim, and fields the
/// service invented stay snake_case (`base_revision`, `server_time`) because
/// that is the endpoint contract. Renaming either side here would make this
/// file a second definition of a schema that already has one, and the first
/// time the two drifted the symptom would be somebody's sharing preference
/// quietly reverting.
library;

import '../state/tether_session.dart';

/// One programme's segregated record: the unit of sync.
///
/// Never the whole session document. A bundle is what a pull returns, what a
/// push sends, and what a revocation destroys — the same granularity 42 CFR
/// Part 2 requires of the storage underneath it.
class AreaBundle {
  const AreaBundle({
    required this.area,
    this.revision = 0,
    this.baseRevision,
    this.revoked = false,
    this.enrolment,
    this.answers = const {},
    this.lapses = const [],
  });

  final String area;

  /// The server's revision for this area. Meaningful on a pull; ignored on a
  /// push, where [baseRevision] is what the server compares against.
  final int revision;

  /// The revision this push is an edit of, or null for "this area is new".
  ///
  /// Sending the wrong one is the whole point of the mechanism: the server
  /// refuses the write and hands back its own copy rather than overwriting a
  /// check-in made on another phone.
  final int? baseRevision;

  /// The area's data has been destroyed at the person's request. A revoked
  /// bundle carries nothing else — it exists so a second device learns to
  /// delete its copy.
  final bool revoked;

  final Map<String, Object?>? enrolment;

  /// Keyed by the full `areaId/screenId`, exactly as the session files them.
  ///
  /// Not the bare screen id, which would be shorter. The full key is what lets
  /// the server check attribution against the string the client actually used,
  /// so a `nutrition/S02` smuggled into the `tobacco` bundle is caught by
  /// comparing two strings rather than being invisible.
  final Map<String, Object?> answers;

  /// `{at, severity, context}`. The area is not repeated on each one — it is
  /// the bundle's.
  final List<Map<String, Object?>> lapses;

  Map<String, Object?> toPushJson() => {
        'area': area,
        'base_revision': baseRevision,
        if (enrolment != null) 'enrolment': enrolment,
        'answers': answers,
        'lapses': lapses,
      };

  factory AreaBundle.fromJson(Map<String, Object?> json) => AreaBundle(
        area: json['area']! as String,
        revision: (json['revision'] as num?)?.toInt() ?? 0,
        baseRevision: (json['base_revision'] as num?)?.toInt(),
        revoked: json['revoked'] == true,
        enrolment: json['enrolment'] as Map<String, Object?>?,
        answers: (json['answers'] as Map<String, Object?>?) ?? const {},
        lapses: ((json['lapses'] as List<Object?>?) ?? const [])
            .whereType<Map<String, Object?>>()
            .toList(growable: false),
      );
}

/// A push the server refused, and why.
class SyncConflict {
  const SyncConflict({
    required this.area,
    required this.reason,
    this.baseRevision,
    this.serverRevision,
    this.server,
  });

  final String area;
  final String reason;
  final int? baseRevision;
  final int? serverRevision;

  /// The server's current bundle for the area. The client decides what to do
  /// with it; nothing is merged automatically, because a silent merge of two
  /// health records is a data-loss bug that looks like a success.
  final AreaBundle? server;

  factory SyncConflict.fromJson(Map<String, Object?> json) => SyncConflict(
        area: json['area']! as String,
        reason: (json['reason'] as String?) ?? 'conflict',
        baseRevision: (json['base_revision'] as num?)?.toInt(),
        serverRevision: (json['server_revision'] as num?)?.toInt(),
        server: json['server'] is Map<String, Object?>
            ? AreaBundle.fromJson(json['server']! as Map<String, Object?>)
            : null,
      );
}

class PullResult {
  const PullResult({
    required this.cursor,
    required this.areas,
    required this.serverTime,
  });

  final int cursor;
  final List<AreaBundle> areas;
  final DateTime serverTime;

  factory PullResult.fromJson(Map<String, Object?> json) => PullResult(
        cursor: (json['cursor'] as num).toInt(),
        areas: ((json['areas'] as List<Object?>?) ?? const [])
            .whereType<Map<String, Object?>>()
            .map(AreaBundle.fromJson)
            .toList(growable: false),
        serverTime: DateTime.parse(json['server_time']! as String),
      );
}

class PushResult {
  const PushResult({
    required this.cursor,
    required this.applied,
    required this.conflicts,
    required this.serverTime,
  });

  final int cursor;

  /// The areas that were written. A push can be partly applied: one area
  /// conflicting does not hold up the others.
  final List<String> applied;

  final List<SyncConflict> conflicts;
  final DateTime serverTime;

  bool get hasConflicts => conflicts.isNotEmpty;

  factory PushResult.fromJson(Map<String, Object?> json) => PushResult(
        cursor: (json['cursor'] as num).toInt(),
        applied: ((json['applied'] as List<Object?>?) ?? const [])
            .map((value) => value.toString())
            .toList(growable: false),
        conflicts: ((json['conflicts'] as List<Object?>?) ?? const [])
            .whereType<Map<String, Object?>>()
            .map(SyncConflict.fromJson)
            .toList(growable: false),
        serverTime: DateTime.parse(json['server_time']! as String),
      );
}

/// What the device remembers between syncs.
///
/// Held separately from the session snapshot rather than inside it. The
/// session is the person's record and is what [TetherSession.deleteEverything]
/// destroys; this is bookkeeping about a server, and a cursor surviving a
/// deletion would be the app remembering something about somebody who asked to
/// be forgotten. Erasing one erases the other — see `SyncState.empty`.
class SyncState {
  const SyncState({this.cursor, this.revisions = const {}});

  /// Everything the device has seen, as one number.
  final int? cursor;

  /// Area id to the server revision this device last agreed with.
  final Map<String, int> revisions;

  static const empty = SyncState();

  SyncState withPull(PullResult result) => SyncState(
        cursor: result.cursor,
        revisions: {
          ...revisions,
          for (final area in result.areas) area.area: area.revision,
        },
      );

  Map<String, Object?> toJson() => {
        'cursor': cursor,
        'revisions': revisions,
      };

  factory SyncState.fromJson(Map<String, Object?> json) => SyncState(
        cursor: (json['cursor'] as num?)?.toInt(),
        revisions: {
          for (final entry
              in ((json['revisions'] as Map<String, Object?>?) ?? const {})
                  .entries)
            if (entry.value is num) entry.key: (entry.value! as num).toInt(),
        },
      );
}

/// A failure the caller can act on, rather than a bare exception.
///
/// The service answers errors as RFC 7807 Problem Details, so the fields are
/// its fields. [status] is the one worth branching on: 401 means the token
/// needs refreshing, 409 means pull before pushing again, and anything 5xx
/// means try later rather than change anything.
class SyncException implements Exception {
  const SyncException({
    required this.status,
    required this.title,
    this.detail,
    this.type,
  });

  final int status;
  final String title;
  final String? detail;
  final String? type;

  bool get isAuthFailure => status == 401 || status == 403;

  /// Worth retrying unchanged: the request was fine, the far end was not.
  bool get isTransient => status == 0 || status == 429 || status >= 500;

  @override
  String toString() =>
      'SyncException($status $title${detail == null ? '' : ': $detail'})';
}
