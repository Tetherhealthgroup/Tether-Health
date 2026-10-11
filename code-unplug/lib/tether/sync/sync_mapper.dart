/// Between one session document and many per-programme bundles.
///
/// The session stores a person's whole record as a single JSON document,
/// because on a phone that is one atomic write. The service stores it split by
/// programme, because 42 CFR Part 2 requires that one programme's data can be
/// handed over, withheld or destroyed without touching another's. This file is
/// the join between those two shapes, and it is the only place that knows both.
///
/// Splitting is total: every enrolment, answer and lapse in the document lands
/// in exactly one bundle, and [split] asserts that by construction rather than
/// by hope — an answer whose key names no programme cannot be attributed to one
/// and is dropped here rather than guessed at, which is the same rule
/// `TetherSession.restoreFrom` applies and the same one the server enforces.
library;

import 'sync_models.dart';

abstract final class SessionSyncMapper {
  /// Splits a session document into one bundle per programme.
  ///
  /// [revisions] is what the device last agreed with the server, and becomes
  /// each bundle's `base_revision`. An area with no entry is new to the server
  /// and sends null, which is the difference between "create this" and "I am
  /// editing revision 4" — and getting it wrong is what conflict detection
  /// exists to catch.
  ///
  /// Areas appear in the document's own order. Nothing here sorts them: the
  /// order a person joined programmes in is not information this layer should
  /// be inventing or destroying.
  static List<AreaBundle> split(
    Map<String, Object?> document, {
    Map<String, int> revisions = const {},
  }) {
    final areas = <String>[];
    final enrolments = <String, Map<String, Object?>>{};
    final answers = <String, Map<String, Object?>>{};
    final lapses = <String, List<Map<String, Object?>>>{};

    void note(String area) {
      if (!areas.contains(area)) areas.add(area);
    }

    for (final entry in _maps(document['enrolments'])) {
      final area = entry['area'];
      if (area is! String || area.isEmpty) continue;
      note(area);
      // The area is the bundle's, so it is not repeated inside the enrolment.
      // Sending it twice would create a second place for the two to disagree.
      enrolments[area] = {
        'status': entry['status'] ?? 'none',
        'hidden': entry['hidden'] == true,
        'joinedOn': entry['joinedOn'],
        'sharing': entry['sharing'] ??
            const {
              'totalsAndAdherence': false,
              'notes': false,
              'recipient': null,
            },
      };
    }

    final answersJson = document['answers'];
    if (answersJson is Map<String, Object?>) {
      for (final entry in answersJson.entries) {
        final separator = entry.key.indexOf('/');
        // No separator means the answer names no programme. Dropped, never
        // filed under a likely-looking one: attributing a health answer by
        // guesswork is exactly the segregation failure the key format exists
        // to prevent.
        if (separator <= 0 || separator == entry.key.length - 1) continue;
        final area = entry.key.substring(0, separator);
        final value = entry.value;
        if (value is! Map<String, Object?>) continue;
        note(area);
        // The full key is kept, not the bare screen id. The server checks the
        // prefix against the bundle it arrived in, and it can only do that if
        // the client sends the string it actually filed the answer under.
        (answers[area] ??= {})[entry.key] = value;
      }
    }

    for (final lapse in _maps(document['lapses'])) {
      final area = lapse['area'];
      if (area is! String || area.isEmpty) continue;
      note(area);
      (lapses[area] ??= []).add({
        'at': lapse['at'],
        'severity': lapse['severity'] ?? 'unknown',
        'context': lapse['context'] ?? const <String>[],
      });
    }

    return [
      for (final area in areas)
        AreaBundle(
          area: area,
          baseRevision: revisions[area],
          enrolment: enrolments[area],
          answers: answers[area] ?? const {},
          lapses: lapses[area] ?? const [],
        ),
    ];
  }

  /// Folds pulled bundles back into a session document.
  ///
  /// The server's copy of an area replaces the local one wholesale — bundles
  /// are the unit of agreement, so a field-level merge would invent a third
  /// version that neither device ever held. Areas the pull did not mention are
  /// left exactly as they are, which is what makes an incremental pull safe.
  ///
  /// A revoked bundle removes the area entirely. That is the point of the
  /// tombstone: the person asked for it to be gone, and a second device
  /// finding out is the only way that request reaches the copy it did not make.
  static Map<String, Object?> merge(
    Map<String, Object?> document,
    List<AreaBundle> bundles,
  ) {
    if (bundles.isEmpty) return document;

    final touched = {for (final bundle in bundles) bundle.area};
    final removed = {
      for (final bundle in bundles)
        if (bundle.revoked) bundle.area,
    };

    final enrolments = [
      for (final entry in _maps(document['enrolments']))
        if (!touched.contains(entry['area'])) entry,
      for (final bundle in bundles)
        if (!bundle.revoked && bundle.enrolment != null)
          {'area': bundle.area, ...bundle.enrolment!},
    ];

    final answers = <String, Object?>{
      for (final entry in _stringMap(document['answers']).entries)
        if (!touched.contains(_areaOf(entry.key))) entry.key: entry.value,
      for (final bundle in bundles)
        if (!bundle.revoked) ...bundle.answers,
    };

    final lapses = [
      for (final entry in _maps(document['lapses']))
        if (!touched.contains(entry['area'])) entry,
      for (final bundle in bundles)
        if (!bundle.revoked)
          for (final lapse in bundle.lapses) {'area': bundle.area, ...lapse},
    ];

    return {
      ...document,
      'enrolments': enrolments
          .where((entry) => !removed.contains(entry['area']))
          .toList(growable: false),
      'answers': answers,
      'lapses': lapses
          .where((entry) => !removed.contains(entry['area']))
          .toList(growable: false),
    };
  }

  /// A map read defensively rather than cast.
  ///
  /// The document reaching [merge] is usually `TetherSession.toJson()` or
  /// something `jsonDecode` produced, and both are `Map<String, …>`. But a
  /// caller that builds one as a Dart literal gets `Map<dynamic, dynamic>`,
  /// and a hard cast turns that into a crash at the end of a successful sync —
  /// the worst possible moment, because the data is already on the server and
  /// the device is about to record that it agreed. Widening here costs
  /// nothing; the alternative cost somebody's sync state.
  static Map<String, Object?> _stringMap(Object? value) => value is Map
      ? {
          for (final entry in value.entries)
            if (entry.key is String) entry.key as String: entry.value,
        }
      : const {};

  static String? _areaOf(String key) {
    final separator = key.indexOf('/');
    return separator <= 0 ? null : key.substring(0, separator);
  }

  static Iterable<Map<String, Object?>> _maps(Object? value) =>
      value is List ? value.whereType<Map<String, Object?>>() : const [];
}
