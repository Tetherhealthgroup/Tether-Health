// A small in-memory stand-in for the sync service's pull and push, with its
// revision, area and lapse rules, for the client tests.
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/sync/sync_models.dart';

class _Area {
  int revision = 0;
  int seq = 0;
  final Map<String, Map<String, Object?>> answers = {};
  final List<Map<String, Object?>> lapses = [];
}

class FakeSyncServer implements BackendTransport {
  /// Programmes the caller is enrolled in.
  final Set<String> enrolled = {};

  /// Programmes without a live consent.
  final Set<String> noConsent = {};

  final Map<String, _Area> _areas = {};
  int _seq = 0;
  bool offline = false;
  bool unauthenticated = false;
  final List<String> calls = [];

  /// Stores a bundle as another phone would have (moves the revision on).
  void storeFromElsewhere(String area,
      {Map<String, ScreenAnswers> answers = const {},
      List<Lapse> lapses = const []}) {
    final a = _areas.putIfAbsent(area, _Area.new);
    a.revision++;
    a.seq = ++_seq;
    for (final e in answers.entries) {
      a.answers[e.key] = e.value.toJson();
    }
    a.lapses.addAll(lapses.map((l) => l.toJson()));
  }

  /// Deletes a programme (its enrolment and, by cascade, its area).
  void deleteProgramme(String area) {
    enrolled.remove(area);
    _areas.remove(area);
  }

  int revisionOf(String area) => _areas[area]?.revision ?? 0;
  List<Map<String, Object?>> lapsesOf(String area) =>
      _areas[area]?.lapses ?? [];
  Map<String, Object?>? answerOf(String key) =>
      _areas[key.split('/').first]?.answers[key];

  Map<String, Object?> _bundle(String code, _Area a) => {
        'area': code,
        'revision': a.revision,
        'answers': {for (final e in a.answers.entries) e.key: e.value},
        'lapses': [...a.lapses],
      };

  @override
  Future<BackendResponse> send(BackendRequest request) async {
    calls.add(request.path);
    if (offline) return const BackendUnreachable();
    if (unauthenticated) return const BackendProblem(401, 'unauthenticated');
    final body = request.body! as Map<String, Object?>;
    if (request.path == '/v1/sync/pull') {
      final cursor = (body['cursor'] as int?) ?? 0;
      if (cursor > _seq) return const BackendProblem(409, 'unknown-cursor');
      return BackendOk(200, {
        'cursor': _seq,
        'areas': [
          for (final e in _areas.entries)
            if (e.value.seq > cursor) _bundle(e.key, e.value),
        ],
        'current_areas': enrolled.toList()..sort(),
        'server_time': '2026-10-20T00:00:00.000Z',
      });
    }
    final areas = [
      for (final a in body['areas']! as List) (a as Map).cast<String, Object?>()
    ];
    final gone = [
      for (var i = 0; i < areas.length; i++)
        if (!enrolled.contains(areas[i]['area']) ||
            (!_areas.containsKey(areas[i]['area']) &&
                areas[i]['base_revision'] != null))
          i,
    ];
    if (gone.isNotEmpty) {
      return BackendProblem(409, 'area_gone', positions: gone);
    }
    final blocked = [
      for (var i = 0; i < areas.length; i++)
        if (noConsent.contains(areas[i]['area'])) i,
    ];
    if (blocked.isNotEmpty) {
      return BackendProblem(403, 'consent_required', positions: blocked);
    }
    final applied = <String>[];
    final conflicts = <Map<String, Object?>>[];
    for (var i = 0; i < areas.length; i++) {
      final b = areas[i];
      final code = b['area']! as String;
      final existing = _areas[code];
      if (existing != null && existing.revision != b['base_revision']) {
        conflicts.add({
          'area': code,
          'reason': 'stale-revision',
          'base_revision': b['base_revision'],
          'server_revision': existing.revision,
          'server': _bundle(code, existing),
        });
        continue;
      }
      final lapses = [
        for (final l in b['lapses']! as List) (l as Map).cast<String, Object?>()
      ];
      final stored = existing?.lapses ?? const [];
      for (var j = 0; j < stored.length; j++) {
        if (j >= lapses.length ||
            Lapse.fromJson(stored[j]).sameAs(Lapse.fromJson(lapses[j])) ==
                false) {
          return BackendProblem(409, 'lapse_conflict', positions: [i]);
        }
      }
      final a = _areas.putIfAbsent(code, _Area.new);
      a.revision = ((b['base_revision'] as int?) ?? 0) + 1;
      a.seq = ++_seq;
      final pushed = (b['answers']! as Map).cast<String, Object?>();
      for (final key in a.answers.keys.toList()) {
        if (!pushed.containsKey(key)) a.answers[key] = {};
      }
      for (final e in pushed.entries) {
        a.answers[e.key] = (e.value! as Map).cast<String, Object?>();
      }
      a.lapses
        ..clear()
        ..addAll(lapses);
      applied.add(code);
    }
    return BackendOk(200, {
      'cursor': _seq,
      'applied': applied,
      'conflicts': conflicts,
      'server_time': '2026-10-20T00:00:00.000Z',
    });
  }
}

/// Wraps a [FakeSyncServer] to act between a pull and a push.
class FakeSyncServerProxy implements BackendTransport {
  FakeSyncServerProxy(this.inner);

  final FakeSyncServer inner;

  /// Runs before every push reaches [inner].
  void beforePush() {}

  /// Answers a push instead of [inner] when not null.
  BackendResponse? interceptPush() => null;

  @override
  Future<BackendResponse> send(BackendRequest request) async {
    if (request.path == '/v1/sync/push') {
      beforePush();
      final answer = interceptPush();
      if (answer != null) return answer;
    }
    return inner.send(request);
  }
}
