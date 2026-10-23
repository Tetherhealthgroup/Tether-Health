// The local sync document and how it meets the sync service.
//
// Plans, questionnaire answers and lapses are written to a local document
// first (per account, or the guest's), then pushed area by area. The rules:
// - Pull, then push. A pushed bundle is the whole area: every answer and
//   every lapse, stored ones repeated unchanged at their positions.
// - An area missing from a pull's `current_areas` is dropped, with its
//   unpushed changes (the programme was deleted). A push refused with
//   `area_gone` discards that area's pending changes.
// - A stale revision takes the server's copy as the base and re-applies this
//   phone's unpushed screens on top, then pushes again.
// - `lapse_conflict`: pull, place unpushed lapses after the server's, drop
//   any the server already holds (same instant, severity and context), push
//   again. A lapse is never lost to a conflict.
// - `consent_required` keeps the changes on the phone and pushes the other
//   areas.
// - A guest's document never leaves the phone. It is merged into an account
//   only through [SyncEngine.adoptGuest], after the member agreed.
// - An authentication failure is reported ([SyncRunStatus.authFailed]): the
//   caller signs out and wipes this account's document.
import 'dart:async';
import 'dart:convert';

import '../api/api_result.dart';
import 'sync_client.dart';
import 'sync_models.dart';
import 'sync_store.dart';

/// One programme's local copy.
class LocalArea {
  LocalArea({
    this.revision,
    Map<String, ScreenAnswers>? answers,
    List<Lapse>? lapses,
    this.storedLapses = 0,
    Set<String>? dirtyScreens,
  })  : answers = answers ?? <String, ScreenAnswers>{},
        lapses = lapses ?? <Lapse>[],
        dirtyScreens = dirtyScreens ?? <String>{};

  factory LocalArea.fromJson(Map<String, Object?> json) => LocalArea(
        revision: (json['revision'] as num?)?.toInt(),
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
        storedLapses: (json['stored'] as num?)?.toInt() ?? 0,
        dirtyScreens: {
          for (final d in (json['dirty'] as List<Object?>?) ?? const [])
            d! as String,
        },
      );

  /// The server revision this copy is based on; null if never stored there.
  int? revision;

  /// Keyed by `area/screenId`.
  final Map<String, ScreenAnswers> answers;

  /// Stored lapses first ([storedLapses] of them), then unpushed ones.
  final List<Lapse> lapses;
  int storedLapses;

  /// Screens changed on this phone since the last push.
  final Set<String> dirtyScreens;

  bool get hasPending =>
      dirtyScreens.isNotEmpty || lapses.length > storedLapses;

  List<Lapse> get pendingLapses => lapses.sublist(storedLapses);

  Map<String, Object?> toJson() => {
        'revision': revision,
        'answers': {for (final e in answers.entries) e.key: e.value.toJson()},
        'lapses': [for (final l in lapses) l.toJson()],
        'stored': storedLapses,
        'dirty': dirtyScreens.toList()..sort(),
      };

  /// Takes [server] as the base and re-applies this phone's unpushed
  /// screens and lapses on top.
  void rebaseOn(AreaBundle server) {
    final mine = {for (final key in dirtyScreens) key: answers[key]};
    final pending = pendingLapses;
    answers
      ..clear()
      ..addAll(server.answers);
    for (final MapEntry(:key, :value) in mine.entries) {
      if (value == null) {
        answers.remove(key);
      } else {
        answers[key] = value;
      }
    }
    lapses
      ..clear()
      ..addAll(server.lapses);
    storedLapses = server.lapses.length;
    for (final lapse in pending) {
      if (!lapses.any(lapse.sameAs)) lapses.add(lapse);
    }
    revision = server.revision;
    // A screen whose content now equals the server's needs no push.
    dirtyScreens.removeWhere((key) => answers[key] == server.answers[key]);
  }
}

/// The local document of one scope.
class SyncDocument {
  SyncDocument({this.cursor, Map<String, LocalArea>? areas})
      : areas = areas ?? <String, LocalArea>{};

  factory SyncDocument.fromJson(Map<String, Object?> json) => SyncDocument(
        cursor: (json['cursor'] as num?)?.toInt(),
        areas: {
          for (final MapEntry(:key, :value)
              in ((json['areas'] as Map?) ?? const {}).entries)
            key as String:
                LocalArea.fromJson((value as Map).cast<String, Object?>()),
        },
      );

  int? cursor;
  final Map<String, LocalArea> areas;

  Map<String, Object?> toJson() => {
        'v': 1,
        'cursor': cursor,
        'areas': {for (final e in areas.entries) e.key: e.value.toJson()},
      };
}

/// How a [SyncEngine.sync] ended.
enum SyncRunStatus {
  /// Everything pending was stored.
  ok,

  /// A guest's document: nothing is sent.
  guest,

  /// The service was not reached; changes stay on the phone.
  offline,

  /// The token was refused: sign out and wipe this account's document.
  authFailed,

  /// Some areas lack a live consent; their changes stay on the phone.
  consentRequired,

  /// Anything else; changes stay on the phone.
  failed,
}

/// The local sync document of the current scope, and its sync.
class SyncEngine {
  SyncEngine({required SyncClient client, required SyncDocumentStore store})
      : _client = client,
        _store = store;

  final SyncClient _client;
  final SyncDocumentStore _store;

  String _scope = guestSyncScope;
  SyncDocument _doc = SyncDocument();
  Future<void> _tail = Future<void>.value();

  /// At most this many push rounds per sync (conflict, refusal, retry).
  static const int maxRounds = 4;

  /// The current scope ([guestSyncScope] or an account's).
  String get scope => _scope;

  bool get isGuest => _scope == guestSyncScope;

  /// Runs [action] after every earlier one: one change at a time.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<SyncDocument> _load(String scope) async {
    try {
      final text = await _store.read(scope);
      if (text == null) return SyncDocument();
      return SyncDocument.fromJson(
          (jsonDecode(text) as Map).cast<String, Object?>());
    } catch (_) {
      // An unreadable document counts as none.
      return SyncDocument();
    }
  }

  Future<void> _save() => _store.write(_scope, jsonEncode(_doc.toJson()));

  /// Opens the document of [accountId], or the guest's when null.
  Future<void> open({String? accountId}) => _serial(() async {
        _scope =
            accountId == null ? guestSyncScope : accountSyncScope(accountId);
        _doc = await _load(_scope);
      });

  static void _checkArea(String area) {
    if (!programmeCodes.contains(area)) {
      throw ArgumentError.value(area, 'area', 'is not a programme code');
    }
  }

  /// Stores [answers] for [screenId] of [area] and marks it for the next
  /// push. Empty answers clear the screen.
  Future<void> saveAnswers(
    String area,
    String screenId,
    ScreenAnswers answers,
  ) =>
      _serial(() async {
        _checkArea(area);
        if (!screenIdPattern.hasMatch(screenId)) {
          throw ArgumentError.value(screenId, 'screenId', 'is not valid');
        }
        final local = _doc.areas.putIfAbsent(area, LocalArea.new);
        final key = '$area/$screenId';
        if (answers.isEmpty) {
          local.answers.remove(key);
        } else {
          local.answers[key] = answers;
        }
        local.dirtyScreens.add(key);
        await _save();
      });

  /// Appends [lapse] to [area]. Lapses are never changed or removed.
  Future<void> appendLapse(String area, Lapse lapse) => _serial(() async {
        _checkArea(area);
        _doc.areas.putIfAbsent(area, LocalArea.new).lapses.add(lapse);
        await _save();
      });

  /// The answers of one screen, or null.
  ScreenAnswers? answersOf(String area, String screenId) =>
      _doc.areas[area]?.answers['$area/$screenId'];

  /// The lapses of [area], stored and unpushed.
  List<Lapse> lapsesOf(String area) =>
      List<Lapse>.unmodifiable(_doc.areas[area]?.lapses ?? const <Lapse>[]);

  /// The areas with changes not yet stored on the server.
  Set<String> get pendingAreas => {
        for (final e in _doc.areas.entries)
          if (e.value.hasPending) e.key,
      };

  /// Pulls, then pushes every pending area (see the file comment).
  Future<SyncRunStatus> sync() => _serial(_sync);

  Future<SyncRunStatus> _sync() async {
    if (isGuest) return SyncRunStatus.guest;
    final pulled = await _pull();
    if (pulled != null) return pulled;
    final excluded = <String>{};
    var status = SyncRunStatus.ok;
    for (var round = 0; round < maxRounds; round++) {
      final bundles = [
        for (final MapEntry(key: area, value: local) in _doc.areas.entries)
          if (local.hasPending && !excluded.contains(area))
            AreaBundle(
              area: area,
              baseRevision: local.revision,
              answers: Map.of(local.answers),
              lapses: List.of(local.lapses),
            ),
      ];
      if (bundles.isEmpty) {
        await _save();
        return status;
      }
      final result = await _client.push(bundles, baseCursor: _doc.cursor);
      switch (result) {
        case ApiSuccess(:final value):
          for (final bundle in bundles) {
            if (!value.applied.contains(bundle.area)) continue;
            final local = _doc.areas[bundle.area]!;
            local
              ..revision = (bundle.baseRevision ?? 0) + 1
              ..storedLapses = bundle.lapses.length;
            // Only what was pushed is done; a change made meanwhile stays.
            local.dirtyScreens.removeWhere(
                (key) => local.answers[key] == bundle.answers[key]);
          }
          for (final conflict in value.conflicts) {
            _doc.areas[conflict.area]?.rebaseOn(conflict.server);
          }
          await _save();
          if (value.conflicts.isEmpty) return status;
        case ApiFailure(:final error):
          final positions = [
            for (final p in error.positions)
              if (p < bundles.length) bundles[p].area,
          ];
          switch (error.code) {
            case ApiProblemCode.areaGone:
              // The programme is gone: its changes cannot be stored.
              if (positions.isEmpty) return _endWith(SyncRunStatus.failed);
              positions.forEach(_doc.areas.remove);
              await _save();
            case ApiProblemCode.consentRequired:
              if (positions.isEmpty) {
                return _endWith(SyncRunStatus.consentRequired);
              }
              excluded.addAll(positions);
              status = SyncRunStatus.consentRequired;
            case ApiProblemCode.lapseConflict:
              final again = await _pull();
              if (again != null) return again;
            default:
              return _endWith(_statusOf(error));
          }
      }
    }
    await _save();
    return SyncRunStatus.failed;
  }

  Future<SyncRunStatus> _endWith(SyncRunStatus status) async {
    await _save();
    return status;
  }

  static SyncRunStatus _statusOf(ApiError error) {
    if (error.isAuthFailure) return SyncRunStatus.authFailed;
    if (error.code == ApiProblemCode.unreachable) return SyncRunStatus.offline;
    return SyncRunStatus.failed;
  }

  /// Pulls and folds the result in. Null on success, else the status.
  Future<SyncRunStatus?> _pull() async {
    var result = await _client.pull(cursor: _doc.cursor);
    if (result case ApiFailure(:final error)
        when error.code == ApiProblemCode.unknownCursor) {
      // The server never issued this cursor: start again from nothing.
      _doc.cursor = null;
      result = await _client.pull();
    }
    switch (result) {
      case ApiFailure(:final error):
        return _statusOf(error);
      case ApiSuccess(:final value):
        _doc.areas.removeWhere((area, _) => !value.currentAreas.contains(area));
        for (final bundle in value.areas) {
          if (!value.currentAreas.contains(bundle.area)) continue;
          _doc.areas.putIfAbsent(bundle.area, LocalArea.new).rebaseOn(bundle);
        }
        _doc.cursor = value.cursor;
        await _save();
        return null;
    }
  }

  /// Moves the guest's document into the open account as unpushed changes,
  /// then deletes the guest's copy. Call only after the member agreed to
  /// merge.
  Future<void> adoptGuest() => _serial(() async {
        if (isGuest) throw StateError('no account is open');
        final guest = await _load(guestSyncScope);
        for (final MapEntry(key: area, value: theirs) in guest.areas.entries) {
          final local = _doc.areas.putIfAbsent(area, LocalArea.new);
          for (final MapEntry(:key, :value) in theirs.answers.entries) {
            local.answers[key] = value;
            local.dirtyScreens.add(key);
          }
          for (final lapse in theirs.lapses) {
            if (!local.lapses.any(lapse.sameAs)) local.lapses.add(lapse);
          }
        }
        await _save();
        await _store.delete(guestSyncScope);
      });

  /// Deletes the document of [accountId] (or the guest's when null). When
  /// it is the open one, the open document becomes empty.
  Future<void> wipe({String? accountId}) => _serial(() async {
        final scope =
            accountId == null ? guestSyncScope : accountSyncScope(accountId);
        await _store.delete(scope);
        if (scope == _scope) _doc = SyncDocument();
      });

  /// Deletes every local sync document.
  Future<void> wipeAll() => _serial(() async {
        await _store.deleteAll();
        _doc = SyncDocument();
      });
}
