// The sandbox's care team and health record routes, with the published
// request shapes and answers. Everything is stored; nothing is delivered
// (`delivery: stored`).
import 'sandbox_api.dart';
import 'sandbox_store.dart';
import 'sandbox_validation.dart';

Json _care(SandboxCall c) => c.data['care']! as Json;
Json _records(SandboxCall c) => c.data['records']! as Json;

List<Object?> _rows(Json group, String kind) =>
    (group[kind] ??= <Object?>[]) as List<Object?>;

final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
final RegExp _code = RegExp(r'^[a-z]{2}$');

Json _careBody(SandboxCall c, Map<String, FieldRule> fields) =>
    validated(c.body, fields, c.now, code: 'invalid_request');

/// A phone number in E.164, as the server stores it (US numbers without a
/// country code get +1). Throws 400 invalid_request otherwise.
String _phone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  final plain = digits.replaceAll('+', '');
  final e164 = digits.startsWith('+')
      ? '+$plain'
      : plain.length == 10
          ? '+1$plain'
          : '+$plain';
  if (!RegExp(r'^\+[1-9][0-9]{6,14}$').hasMatch(e164)) {
    throw const SandboxProblem(400, 'invalid_request');
  }
  return e164;
}

Json? _liveConnection(SandboxCall c, Object? id) {
  for (final r in _rows(_care(c), 'connections')) {
    final row = r! as Json;
    if (row['revokedAt'] != null) continue;
    if (id == null || row['id'] == id) return row;
  }
  return null;
}

bool _enrolled(SandboxCall c, String code) => c.list('enrolments').any((e) =>
    (e! as Json)['programmeCode'] == code && (e as Json)['status'] != 'left');

SandboxAnswer redeemConnection(SandboxCall c) {
  final body = _careBody(c, {
    'inviteCode': const StrRule(required: true, min: 1, max: 80),
  });
  final code = (body['inviteCode']! as String).trim().toUpperCase();
  if (code != sandboxInviteCode) {
    throw const SandboxProblem(400, 'care_invite_invalid');
  }
  final existing = _liveConnection(c, null);
  if (existing != null) return SandboxAnswer(201, existing);
  final row = {
    'id': c.newId(),
    'clinicId': '5a4db0c0-c1c1-4000-8000-000000000001',
    'clinicName': 'Sandbox Clinic',
    'connectedAt': c.nowText,
    'revokedAt': null,
  };
  _rows(_care(c), 'connections').add(row);
  return SandboxAnswer(201, row);
}

SandboxAnswer listConnections(SandboxCall c) =>
    SandboxAnswer(200, {'connections': _rows(_care(c), 'connections')});

SandboxAnswer createSummary(SandboxCall c) {
  final body = _careBody(c, {
    'programmeCode': StrRule(required: true, pattern: _code),
    'connectionId': StrRule(pattern: _uuid),
    'snapshot': const _ObjectRule(required: true),
  });
  final code = body['programmeCode']! as String;
  if (!_enrolled(c, code)) {
    throw const SandboxProblem(404, 'enrolment_not_found');
  }
  final connection = _liveConnection(c, body['connectionId']);
  if (connection == null) {
    throw const SandboxProblem(409, 'connection_required');
  }
  final row = {
    'id': c.newId(),
    'programmeCode': code,
    'connectionId': connection['id'],
    'kind': 'visit_summary',
    'createdAt': c.nowText,
    'expiresAt': c.now.toUtc().add(const Duration(days: 30)).toIso8601String(),
    'delivery': 'stored',
  };
  _rows(_care(c), 'summaries').add({...row, 'snapshot': body['snapshot']});
  return SandboxAnswer(201, row);
}

SandboxAnswer createMessage(SandboxCall c) {
  final body = _careBody(c, {
    'connectionId': StrRule(pattern: _uuid),
    'topic': const StrRule(required: true, min: 1, max: 80),
    'message': const StrRule(required: true, min: 1, max: 2000),
    'programmeCode': StrRule(pattern: _code),
    'attachment': const _ObjectRule(),
  });
  final connection = _liveConnection(c, body['connectionId']);
  if (connection == null) {
    throw const SandboxProblem(409, 'connection_required');
  }
  final row = {
    'id': c.newId(),
    'connectionId': connection['id'],
    'programmeCode': body['programmeCode'],
    'shareId': null,
    'createdAt': c.nowText,
    'delivery': 'stored',
  };
  _rows(_care(c), 'messages')
      .add({...row, 'topic': body['topic'], 'message': body['message']});
  return SandboxAnswer(201, row);
}

SandboxAnswer createSupporter(SandboxCall c) {
  final body = _careBody(c, {
    'name': const StrRule(required: true, min: 1, max: 80),
    'phone': const StrRule(required: true, min: 1, max: 32),
    'programmes': const SetRule({'bf', 'sf'}, required: true, min: 1, max: 2),
    'helpPhrase': const StrRule(min: 1, max: 200),
  });
  final programmes = (body['programmes']! as List).cast<String>();
  if (programmes.any((p) => !_enrolled(c, p))) {
    throw const SandboxProblem(409, 'programme_not_enrolled');
  }
  final row = {
    'id': c.newId(),
    'name': body['name'],
    'phone': _phone(body['phone']! as String),
    'programmes': programmes,
    'helpPhrase': body['helpPhrase'],
    'createdAt': c.nowText,
    'updatedAt': c.nowText,
  };
  _rows(_care(c), 'supporters').add(row);
  return SandboxAnswer(201, row);
}

SandboxAnswer listSupporters(SandboxCall c) =>
    SandboxAnswer(200, {'supporters': _rows(_care(c), 'supporters')});

SandboxAnswer createCaregiver(SandboxCall c) {
  final body = _careBody(c, {
    'name': const StrRule(required: true, min: 1, max: 80),
    'phone': const StrRule(required: true, min: 1, max: 32),
    'scope': const SetRule({'sd.session_finished', 'sd.fall_logged'},
        min: 1, max: 2),
  });
  if (!_enrolled(c, 'sd')) {
    throw const SandboxProblem(404, 'enrolment_not_found');
  }
  final row = {
    'id': c.newId(),
    'programmeCode': 'sd',
    'name': body['name'],
    'phone': _phone(body['phone']! as String),
    'scope': body['scope'] ?? <String>[],
    'inviteStatus': 'pending',
    'createdAt': c.nowText,
    'revokedAt': null,
  };
  _rows(_care(c), 'caregivers').add(row);
  return SandboxAnswer(201, row);
}

SandboxAnswer listCaregivers(SandboxCall c) =>
    SandboxAnswer(200, {'caregivers': _rows(_care(c), 'caregivers')});

/// Not in the published contract yet (referrals need their own schema):
/// stored as sent.
SandboxAnswer createReferral(SandboxCall c) {
  final body = c.body;
  if (body is! Map) throw const SandboxProblem(400, 'invalid_request');
  final row = {'id': c.newId(), 'createdAt': c.nowText, 'delivery': 'stored'};
  _rows(_care(c), 'referrals').add({...row, 'body': body});
  return SandboxAnswer(201, row);
}

// Health records.

Json _manualSource(SandboxCall c) {
  final sources = _rows(_records(c), 'sources');
  for (final s in sources) {
    if ((s! as Json)['kind'] == 'manual') return s as Json;
  }
  final source = {
    'id': c.newId(),
    'kind': 'manual',
    'displayName': 'Entered by you',
    'status': 'connected',
    'lastSyncedAt': null,
    'createdAt': c.nowText,
  };
  sources.add(source);
  return source;
}

const Map<String, String> _routeOfType = {
  'blood_pressure': 'hw', 'glucose': 'st', 'vaccine': 'ck', //
};
const Map<String, String> _routeOfTest = {
  'a1c': 'st', 'ldl': 'hw', 'egfr': 're', 'glucose': 'st', //
};

SandboxAnswer addManualRecord(SandboxCall c) {
  final body = _careBody(c, {
    'type': const EnumRule({
      'blood_pressure', 'glucose', 'lab_result', 'vaccine', 'medication',
      'condition', //
    }, required: true),
    'test': const EnumRule({'a1c', 'ldl', 'egfr', 'glucose'}),
    'value': const NumRule(),
    'unit': const StrRule(min: 1, max: 32),
    'systolic': const IntRule(),
    'diastolic': const IntRule(),
    'name': const StrRule(min: 1, max: 200),
    'date': StrRule(required: true, pattern: RegExp(r'^\d{4}-\d{2}-\d{2}$')),
  });
  final source = _manualSource(c);
  final type = body['type']! as String;
  final item = {
    'id': c.newId(),
    'sourceId': source['id'],
    'enteredByYou': true,
    'resourceType': const {
          'vaccine': 'Immunization',
          'medication': 'MedicationRequest',
          'condition': 'Condition'
        }[type] ??
        'Observation',
    'category': type,
    'codeSystem': 'sandbox',
    'code': body['test'] ?? type,
    'display': body['name'] ?? body['test'] ?? type,
    'value': body['value'],
    'valueText': null,
    'unit': body['unit'],
    'effectiveAt': '${body['date']}T00:00:00.000Z',
    'status': 'accepted',
  };
  _rows(_records(c), 'items').add(item);
  final programme = _routeOfTest[body['test']] ?? _routeOfType[type];
  return SandboxAnswer(201, {
    'items': [item],
    'routedTo': [
      if (programme != null && _enrolled(c, programme))
        {'programmeCode': programme, 'items': 1},
    ],
  });
}

SandboxAnswer listSources(SandboxCall c) =>
    SandboxAnswer(200, {'sources': _rows(_records(c), 'sources')});

SandboxAnswer listItems(SandboxCall c) =>
    SandboxAnswer(200, {'items': _rows(_records(c), 'items')});

Json _item(SandboxCall c, Object? id) {
  for (final i in _rows(_records(c), 'items')) {
    if ((i! as Json)['id'] == id) return i as Json;
  }
  throw const SandboxProblem(404, 'not_found');
}

SandboxAnswer acceptRecords(SandboxCall c) {
  final body = c.body;
  final ids = body is Map ? body['itemIds'] : null;
  if (body is! Map ||
      body.keys.any((k) => k != 'itemIds') ||
      ids is! List ||
      ids.isEmpty ||
      ids.length > 200 ||
      ids.toSet().length != ids.length ||
      ids.any((i) => i is! String || !_uuid.hasMatch(i))) {
    throw const SandboxProblem(400, 'invalid_request');
  }
  final items = [for (final id in ids) _item(c, id)];
  for (final item in items) {
    item['status'] = 'accepted';
  }
  return SandboxAnswer(
      200, {'accepted': items.length, 'routedTo': <Object?>[]});
}

SandboxAnswer resolveConflicts(SandboxCall c) {
  final body = c.body;
  final list = body is Map ? body['resolutions'] : null;
  if (body is! Map || list is! List || list.isEmpty || list.length > 100) {
    throw const SandboxProblem(400, 'invalid_request');
  }
  final accepted = <Object?>[], rejected = <Object?>[];
  for (final r in list) {
    if (r is! Map ||
        r['itemId'] is! String ||
        !const {'use_imported', 'keep_both', 'keep_mine', 'discard', 'correct'}
            .contains(r['choice'])) {
      throw const SandboxProblem(400, 'invalid_request');
    }
    final item = _item(c, r['itemId']);
    final keep = r['choice'] != 'discard' && r['choice'] != 'keep_mine';
    item['status'] = keep ? 'accepted' : 'rejected';
    (keep ? accepted : rejected).add(item['id']);
  }
  return SandboxAnswer(200, {
    'accepted': accepted,
    'rejected': rejected,
    'created': <Object?>[],
    'routedTo': <Object?>[],
  });
}

Json _source(SandboxCall c) {
  final id = (c.params['id'] ?? '').toLowerCase();
  for (final r in _rows(_records(c), 'sources')) {
    if ((r! as Json)['id'] == id) return r as Json;
  }
  throw const SandboxProblem(404, 'not_found');
}

/// Not in the published contract yet (source sync arrives with SMART
/// connect).
SandboxAnswer syncSource(SandboxCall c) {
  final source = _source(c);
  source['lastSyncedAt'] = c.nowText;
  return SandboxAnswer(200, {
    'sourceId': source['id'],
    'items': [
      for (final i in _rows(_records(c), 'items'))
        if ((i! as Json)['sourceId'] == source['id']) i,
    ],
  });
}

/// Not in the published contract yet.
SandboxAnswer disconnectSource(SandboxCall c) {
  final source = _source(c);
  _rows(_records(c), 'sources').remove(source);
  _rows(_records(c), 'items')
      .removeWhere((i) => (i! as Json)['sourceId'] == source['id']);
  return const SandboxAnswer(204);
}

class _ObjectRule extends FieldRule {
  const _ObjectRule({super.required});

  @override
  Object? check(Object? value, DateTime now) {
    if (value is! Map) throw const FormatException();
    return value;
  }
}
