// The sandbox's copy of the sync service (`sync/thsync`): pull and push with
// the same revision, area, consent and lapse rules and problem codes.
import 'sandbox_api.dart';
import 'sandbox_store.dart';
import 'sandbox_validation.dart';

final RegExp _screenId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.:-]{0,63}$');
const Set<String> _codes = {
  'bf', 'sf', 'ca', 'hw', 'st', 're', 'nu', 'sd', 'ea', 'ck', 'be', //
};

Json _sync(SandboxCall c) => c.data['sync']! as Json;
Json _areas(SandboxCall c) => _sync(c)['areas']! as Json;

/// The caller's enrolment per programme code.
Map<String, Json> _enrolled(SandboxCall c) => {
      for (final e in c.list('enrolments'))
        (e! as Json)['programmeCode']! as String: e as Json,
    };

bool _mayWrite(SandboxCall c, Json enrolment) {
  if (enrolment['status'] == 'left') return false;
  return c.list('consents').any((x) =>
      (x! as Json)['enrolmentId'] == enrolment['id'] &&
      (x as Json)['purpose'] == 'core' &&
      x['revokedAt'] == null);
}

Json _bundle(String code, Json area) => {
      'area': code,
      'revision': area['revision'],
      'answers': {
        for (final e in (area['answers']! as Json).entries)
          '$code/${e.key}': e.value,
      },
      'lapses': area['lapses'],
    };

const _unprocessable = SandboxProblem(422, 'invalid-request');

int? _cursor(Object? value) {
  if (value == null) return null;
  if (value is! int || value < 0) throw _unprocessable;
  return value;
}

SandboxAnswer syncPull(SandboxCall c) {
  final body = c.body;
  if (body is! Map || body.keys.any((k) => k != 'cursor' && k != 'areas')) {
    throw _unprocessable;
  }
  final cursor = _cursor(body['cursor']) ?? 0;
  List<String>? wanted;
  final filter = body['areas'];
  if (filter != null) {
    if (filter is! List ||
        filter.isEmpty ||
        filter.any((a) => a is! String || !_codes.contains(a)) ||
        filter.toSet().length != filter.length) {
      throw _unprocessable;
    }
    wanted = filter.cast<String>();
  }
  final upper = (_sync(c)['seq'] as int?) ?? 0;
  if (cursor > upper) throw const SandboxProblem(409, 'unknown-cursor');
  final changed = [
    for (final e in _areas(c).entries)
      if (((e.value! as Json)['seq']! as int) > cursor) e,
  ];
  final withheld = [
    for (final e in changed)
      if (wanted != null && !wanted.contains(e.key))
        (e.value! as Json)['seq']! as int,
  ];
  final returned =
      withheld.isEmpty ? upper : (withheld.reduce((a, b) => a < b ? a : b) - 1);
  return SandboxAnswer(200, {
    'cursor': returned,
    'areas': [
      for (final e in changed)
        if (wanted == null || wanted.contains(e.key))
          _bundle(e.key, e.value! as Json),
    ],
    'current_areas': _enrolled(c).keys.toList()..sort(),
    'server_time': c.nowText,
  });
}

/// A pushed bundle, checked as the service's pydantic models check it.
Json _checkBundle(Object? raw, DateTime now) {
  if (raw is! Map) throw _unprocessable;
  const allowed = {'area', 'revision', 'base_revision', 'answers', 'lapses'};
  if (raw.keys.any((k) => !allowed.contains(k))) throw _unprocessable;
  final area = raw['area'];
  if (area is! String || !_codes.contains(area)) throw _unprocessable;
  final base = raw['base_revision'];
  if (base != null && (base is! int || base < 0)) throw _unprocessable;
  final answers = <String, Object?>{};
  final rawAnswers = raw['answers'] ?? const <String, Object?>{};
  if (rawAnswers is! Map || rawAnswers.length > 512) throw _unprocessable;
  for (final e in rawAnswers.entries) {
    final key = e.key;
    if (key is! String) throw _unprocessable;
    final slash = key.indexOf('/');
    if (slash < 0) throw _unprocessable;
    final keyArea = key.substring(0, slash);
    final screen = key.substring(slash + 1);
    if (keyArea != area || !_screenId.hasMatch(screen)) throw _unprocessable;
    answers[screen] = _checkAnswers(e.value);
  }
  final lapses = <Object?>[];
  final rawLapses = raw['lapses'] ?? const <Object?>[];
  if (rawLapses is! List || rawLapses.length > 5000) throw _unprocessable;
  for (final l in rawLapses) {
    if (l is! Map ||
        l.keys.any((k) => !{'at', 'severity', 'context'}.contains(k))) {
      throw _unprocessable;
    }
    final at = l['at'];
    if (at is! String) throw _unprocessable;
    final parsed = DateTime.tryParse(at);
    if (parsed == null || !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(at)) {
      throw _unprocessable;
    }
    final severity = l['severity'] ?? '';
    if (severity is! String || severity.length > 64) throw _unprocessable;
    final context = l['context'] ?? const <Object?>[];
    if (context is! List ||
        context.any((s) => s is! String || s.length > 256)) {
      throw _unprocessable;
    }
    lapses.add({
      'at': parsed.toUtc().toIso8601String(),
      'severity': severity,
      'context': [...context],
    });
  }
  return {
    'area': area,
    'base_revision': base,
    'answers': answers,
    'lapses': lapses,
  };
}

Json _checkAnswers(Object? raw) {
  if (raw is! Map) throw _unprocessable;
  const kinds = {'chips', 'option', 'slider', 'text'};
  if (raw.keys.any((k) => !kinds.contains(k))) throw _unprocessable;
  final out = <String, Object?>{};
  for (final kind in kinds) {
    final blocks = raw[kind];
    if (blocks == null) continue;
    if (blocks is! Map || blocks.length > 256) throw _unprocessable;
    for (final e in blocks.entries) {
      final index = int.tryParse('${e.key}');
      if (index == null || index < 0 || '$index' != e.key) throw _unprocessable;
      final v = e.value;
      final ok = switch (kind) {
        'chips' => v is List && v.every((i) => i is int),
        'option' => v is int,
        'slider' => v is num,
        _ => v is String && v.length <= 8192,
      };
      if (!ok) throw _unprocessable;
    }
    if (blocks.isNotEmpty) out[kind] = blocks;
  }
  if (canonicalJson(out).length > 32768) throw _unprocessable;
  return out;
}

bool _sameLapse(Object? a, Object? b) => canonicalJson(a) == canonicalJson(b);

SandboxAnswer syncPush(SandboxCall c) {
  final body = c.body;
  if (body is! Map ||
      body.keys.any((k) => k != 'base_cursor' && k != 'areas')) {
    throw _unprocessable;
  }
  final baseCursor = _cursor(body['base_cursor']);
  final raw = body['areas'];
  if (raw is! List || raw.isEmpty || raw.length > 64) throw _unprocessable;
  final bundles = [for (final b in raw) _checkBundle(b, c.now)];
  if (bundles.map((b) => b['area']).toSet().length != bundles.length) {
    throw _unprocessable;
  }
  final upper = (_sync(c)['seq'] as int?) ?? 0;
  if (baseCursor != null && baseCursor > upper) {
    throw const SandboxProblem(409, 'unknown-cursor');
  }
  final enrolled = _enrolled(c);
  final areas = _areas(c);
  List<int> positions(bool Function(Json b) refused) => [
        for (var i = 0; i < bundles.length; i++)
          if (refused(bundles[i])) i,
      ];
  final gone = positions((b) => !enrolled.containsKey(b['area']));
  if (gone.isNotEmpty) {
    throw SandboxProblem(409, 'area_gone', positions: gone);
  }
  final blocked = positions((b) => !_mayWrite(c, enrolled[b['area']]!));
  if (blocked.isNotEmpty) {
    throw SandboxProblem(403, 'consent_required', positions: blocked);
  }
  final deleted = positions(
      (b) => !areas.containsKey(b['area']) && b['base_revision'] != null);
  if (deleted.isNotEmpty) {
    throw SandboxProblem(409, 'area_gone', positions: deleted);
  }
  final applied = <String>[];
  final conflicts = <Object?>[];
  for (var i = 0; i < bundles.length; i++) {
    final b = bundles[i];
    final code = b['area']! as String;
    final existing = areas[code] as Json?;
    if (existing != null && existing['revision'] != b['base_revision']) {
      conflicts.add({
        'area': code,
        'reason': 'stale-revision',
        'base_revision': b['base_revision'],
        'server_revision': existing['revision'],
        'server': _bundle(code, existing),
      });
      continue;
    }
    final stored = (existing?['lapses'] as List<Object?>?) ?? const [];
    final pushed = b['lapses']! as List<Object?>;
    if (pushed.length < stored.length ||
        !List.generate(stored.length, (j) => _sameLapse(stored[j], pushed[j]))
            .every((same) => same)) {
      throw SandboxProblem(409, 'lapse_conflict', positions: [i]);
    }
    final seq = upper + applied.length + 1;
    final answers = <String, Object?>{
      // A stored screen the bundle no longer carries is cleared to {}.
      for (final key in ((existing?['answers'] as Json?) ?? const {}).keys)
        key: <String, Object?>{},
      ...(b['answers']! as Json),
    };
    areas[code] = {
      'revision': ((b['base_revision'] as int?) ?? 0) + 1,
      'seq': seq,
      'answers': answers,
      'lapses': pushed,
    };
    applied.add(code);
  }
  _sync(c)['seq'] = upper + applied.length;
  return SandboxAnswer(200, {
    'cursor': upper + applied.length,
    'applied': applied,
    'conflicts': conflicts,
    'server_time': c.nowText,
  });
}
