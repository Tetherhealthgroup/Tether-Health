// Care team and health records. These need an account; nothing is queued.
// The server stores what is sent; it delivers nothing itself.
import 'package:tether_ui/ui/ui.dart';

import '../../data/display_source.dart' show hwSummaryKeys;
import '../registry.dart';
import 'common.dart';

/// The programme a record item belongs to, by its code, category or
/// resource type; null when it fits none of the review groups.
String? programmeOfItem(Map<String, Object?> item) {
  final code = '${item['code']}'.toLowerCase();
  final category = '${item['category']}'.toLowerCase();
  final display = '${item['display']}'.toLowerCase();
  if (code == 'a1c' || code == 'glucose' || category == 'glucose') return 'st';
  if (code == 'egfr' || code == 'urine_acr') return 're';
  if (code == 'ldl' ||
      code == 'hdl' ||
      code.startsWith('chol') ||
      category == 'blood_pressure') {
    return 'hw';
  }
  if (category == 'vaccine' || item['resourceType'] == 'Immunization') {
    return 'ck';
  }
  if (display.contains('smok') || code == 'smoking_status') return 'bf';
  return null;
}

/// Which conflict question (`a1c` or `bp`) an item answers, or null.
String? conflictKindOf(Map<String, Object?> item) {
  final code = '${item['code']}'.toLowerCase();
  final category = '${item['category']}'.toLowerCase();
  if (code == 'a1c') return 'a1c';
  if (category == 'blood_pressure' ||
      code == 'blood_pressure' ||
      code.startsWith('bp')) {
    return 'bp';
  }
  return null;
}

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
      // Exactly the preview the member saw: the shown values, all real. If
      // any is missing (no readings, or not loaded) nothing is sent.
      final shown = <String, String>{};
      for (final key in hwSummaryKeys) {
        final value = kit.data.watch(key).value;
        if (value is String) shown[key] = value;
      }
      if (!shown.containsKey('hw.summary.dates') ||
          !shown.containsKey('hw.summary.bp_average')) {
        return const TResult.failed('nothing_to_share');
      }
      return resultOf(await kit.api.care.sendSummary({
        'programmeCode': 'hw',
        'snapshot': {
          'preview': shown,
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
      final date = s.requiredDate('date');
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
      // Only the items of the programmes the member ticked.
      final ticked = {
        for (final code in const ['hw', 'st', 'ck', 'bf', 're'])
          if (s.list('keep_$code').isNotEmpty) code,
      };
      if (ticked.isEmpty) return const TResult.ok();
      final chosen = [
        for (final i in await items('pending_review'))
          if (ticked.contains(programmeOfItem(i))) i['id'],
      ];
      if (chosen.isEmpty) return const TResult.ok();
      return resultOf(await kit.api.care.acceptRecords({'itemIds': chosen}));
    }),
    'POST /v1/records/fhir/conflicts': signedIn((s) async {
      String? choiceOf(String? label) {
        if (label == null) return null;
        if (label.startsWith('From ')) return 'use_imported';
        if (label.startsWith('Entered by you')) return 'keep_mine';
        if (label == 'Discard') return 'discard';
        if (label == 'Keep both' || label.startsWith('Ask')) return 'keep_both';
        return null;
      }

      // Each choice goes to the conflict it was asked about, by item.
      final byKind = {
        'a1c': choiceOf(s.one('a1c')),
        'bp': choiceOf(s.one('bp'))
      };
      final resolutions = [
        for (final item in await items('conflict'))
          if (byKind[conflictKindOf(item)] case final choice?)
            {'itemId': item['id'], 'choice': choice},
      ];
      if (resolutions.isEmpty) return const TResult.ok();
      return resultOf(await kit.api.care
          .resolveRecordConflicts({'resolutions': resolutions}));
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
