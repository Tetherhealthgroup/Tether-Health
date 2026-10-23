// Care team and health records. These need an account; nothing is queued.
// The server stores what is sent; it delivers nothing itself.
import 'package:tether_ui/ui/ui.dart';

import '../../api/tether_api.dart';
import '../registry.dart';
import 'common.dart';

/// Handlers of the care and records endpoints.
Map<String, EndpointHandler> careRecordsHandlers(HandlerKit kit) {
  EndpointHandler signedIn(Future<TResult> Function(Snapshot s) body) =>
      (call) => guarded(() async {
            if (!kit.services.signedIn) {
              return const TResult.failed(HandlerCodes.signInRequired);
            }
            final result = await body(Snapshot(call));
            if (result is TOk) await kit.data.refresh();
            return result;
          });

  Future<List<Map<String, Object?>>> items(String status) async {
    final list = (await kit.api.care.recordItems()).valueOrNull?['items'];
    return [
      if (list is List)
        for (final i in list)
          if (i is Map && i['status'] == status) i.cast<String, Object?>(),
    ];
  }

  return {
    'POST /v1/care/connections': signedIn((s) async {
      final code = s.text('invite_code');
      if (code == null) throw const InvalidInput();
      return resultOf(
          await kit.api.care.redeemConnection({'inviteCode': code}));
    }),
    'POST /v1/care/messages': signedIn((s) async {
      final topic = s.text('topic');
      final message = s.text('message');
      if (topic == null || message == null) throw const InvalidInput();
      return resultOf(await kit.api.care.sendMessage(
        {'topic': topic, 'message': message},
        idempotencyKey: s.call.idempotencyKey,
      ));
    }),
    'POST /v1/care/summaries': signedIn((s) async {
      // The snapshot is the member's own 30-day Heartwise data, as stored.
      final summary = await kit.api.records
          .summary(programme: 'hw', range: SummaryRange.days30);
      final data = summary.valueOrNull;
      if (data == null) return resultOf(summary);
      final readings = [
        for (final o in data.observations)
          if (o['metric'] == 'bp_systolic' || o['metric'] == 'bp_diastolic') o,
      ];
      if (readings.isEmpty) return const TResult.failed('nothing_to_share');
      return resultOf(await kit.api.care.sendSummary({
        'programmeCode': 'hw',
        'snapshot': {
          'since': data.since.toIso8601String(),
          'observations': readings,
          'includeNotes': s.flag('include_notes') ?? false,
        },
      }, idempotencyKey: s.call.idempotencyKey));
    }),
    'POST /v1/care/supporters': signedIn((s) async {
      final name = s.text('name');
      final phone = s.text('phone');
      final programmes = [
        for (final p in s.list('which_programs'))
          if (p == 'BreatheFree') 'bf' else if (p == 'ScrollFree') 'sf',
      ];
      if (name == null || phone == null || programmes.isEmpty) {
        throw const InvalidInput();
      }
      return resultOf(await kit.api.care.addSupporter({
        'name': name,
        'phone': phone,
        'programmes': programmes,
        if (s.text('help_phrase') case final phrase?) 'helpPhrase': phrase,
      }));
    }),
    'POST /v1/care/caregivers': signedIn((s) async {
      final name = s.text('name');
      final phone = s.text('phone');
      if (name == null || phone == null) throw const InvalidInput();
      final chosen = s.list('caregiver_can_see');
      final scope = [
        if (chosen.contains('When I finish a session')) 'sd.session_finished',
        if (chosen.contains('If I log a fall')) 'sd.fall_logged',
      ];
      return resultOf(await kit.api.care.addCaregiver({
        'name': name,
        'phone': phone,
        if (scope.isNotEmpty) 'scope': scope,
      }));
    }),
    'POST /v1/care/referrals': signedIn((s) async {
      final time = s.text('best_time_to_call');
      if (time == null) throw const InvalidInput();
      return resultOf(
          await kit.api.care.requestReferral({'bestTimeToCall': time}));
    }),
    'POST /v1/records/manual': signedIn((s) async {
      const types = {
        'Blood pressure': 'blood_pressure', 'Glucose': 'glucose',
        'Lab result': 'lab_result', //
        'Vaccine': 'vaccine', 'Medication': 'medication',
        'Condition': 'condition',
      };
      final type =
          types[s.one('type', screen: 'records_manual')] ?? 'lab_result';
      final test = s.text('test');
      final value = s.number('value');
      final date = s.date('date') ?? DateTime.now();
      final testCode = test == null ? null : slug(test);
      return resultOf(await kit.api.care.addManualRecord({
        'type': type,
        if (testCode != null &&
            const {'a1c', 'ldl', 'egfr', 'glucose'}.contains(testCode))
          'test': testCode,
        if (value != null) 'value': value,
        'date': '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      }, idempotencyKey: s.call.idempotencyKey));
    }),
    'POST /v1/records/fhir/accept': signedIn((s) async {
      final ticked = [
        for (final key in const [
          'keep_hw',
          'keep_st',
          'keep_ck',
          'keep_bf',
          'keep_re'
        ])
          ...s.list(key),
      ];
      if (ticked.isEmpty) return const TResult.ok();
      final pending = await items('pending_review');
      if (pending.isEmpty) return const TResult.ok();
      return resultOf(await kit.api.care.acceptRecords({
        'itemIds': [for (final i in pending) i['id']],
      }));
    }),
    'POST /v1/records/fhir/conflicts': signedIn((s) async {
      final conflicts = await items('conflict');
      if (conflicts.isEmpty) return const TResult.ok();
      String choiceOf(String? label) {
        if (label == null) return 'keep_both';
        if (label.startsWith('From ')) return 'use_imported';
        if (label.startsWith('Entered by you')) return 'keep_mine';
        if (label == 'Discard') return 'discard';
        return 'keep_both';
      }

      final choices = [choiceOf(s.one('a1c')), choiceOf(s.one('bp'))];
      return resultOf(await kit.api.care.resolveRecordConflicts({
        'resolutions': [
          for (var i = 0; i < conflicts.length; i++)
            {'itemId': conflicts[i]['id'], 'choice': choices[i < 2 ? i : 1]},
        ],
      }));
    }),
    'POST /v1/records/fhir/sources/:id/sync': signedIn((s) async {
      final source = HandlerKit.argumentOfScreen?.call(s.screen);
      if (source == null) {
        return const TResult.failed(HandlerCodes.programUnknown);
      }
      return resultOf(await kit.api.care.syncRecordSource(source));
    }),
    'DELETE /v1/records/fhir/sources/:id': signedIn((s) async {
      final source = HandlerKit.argumentOfScreen?.call(s.screen);
      if (source == null) {
        return const TResult.failed(HandlerCodes.programUnknown);
      }
      return resultOf(await kit.api.care.disconnectRecordSource(source));
    }),
  };
}
