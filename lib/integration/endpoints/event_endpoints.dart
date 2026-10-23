// Programme events, check-ins, rescues and lessons: typed API bodies sent
// through the outbox (kept on the phone and sent later when offline; safety
// entries never dropped).
import 'package:tether_ui/ui/ui.dart';

import '../../api/tether_api.dart';
import '../../data/sync_codec.dart';
import '../outbox.dart';
import '../registry.dart';
import 'common.dart';

/// The safety endpoints: kept until the service accepts them.
const Set<String> safetyEndpoints = {
  'POST /v1/program-data/ea/moods',
  'POST /v1/program-data/hw/readings',
  'POST /v1/program-data/st/readings',
  'POST /v1/program-data/ca/zone-checks',
};

typedef _Build = Future<Object?> Function(
    TetherApi api, Snapshot s, String key);

/// Handlers of the event endpoints.
Map<String, EndpointHandler> eventHandlers(HandlerKit kit) {
  EndpointHandler queued(String endpoint, _Build build) =>
      (call) => guarded(() async {
            final s = Snapshot(call);
            final request =
                await requestOf((api) => build(api, s, call.idempotencyKey));
            final result = await kit.outbox.submit(OutboxEntry(
              endpoint: endpoint,
              path: request.path,
              body: (request.body as Map?)?.cast<String, Object?>() ?? const {},
              idempotencyKey: call.idempotencyKey,
              safety: safetyEndpoints.contains(endpoint),
            ));
            if (result is! OutboxFailed) await kit.data.refresh();
            return outboxResult(result);
          });

  return {
    // BreatheFree first, then Heartwise, Steady, ClearAir, Ease, Renew,
    // Stride, Checkup, Beacon, ScrollFree.
    'POST /v1/records/rescues': queued('POST /v1/records/rescues', (api, s, k) {
      final helped = s.one('did_it_help');
      final tool = s.one('value', screen: 'rescue_tools');
      return api.records.rescue(
        idempotencyKey: k,
        tool: tool == null ? 'other' : slug(tool),
        intensityAfter: s.number('how_strong_is_it_now')?.round(),
        helped: helped == 'Not this time'
            ? RescueHelped.no
            : byLabel(RescueHelped.values, helped),
      );
    }),
    'POST /v1/program-data/hw/readings':
        queued('POST /v1/program-data/hw/readings', (api, s, k) {
      final systolic = s.integer('systolic');
      final diastolic = s.integer('diastolic');
      if (systolic == null || diastolic == null) throw const InvalidInput();
      return api.events.hwReading(
          idempotencyKey: k,
          systolic: systolic,
          diastolic: diastolic,
          pulse: s.integer('pulse_optional'));
    }),
    'POST /v1/program-data/hw/lipids':
        queued('POST /v1/program-data/hw/lipids', (api, s, k) {
      final date = s.date('lab_date') ?? DateTime.now();
      final total = s.number('total'), ldl = s.number('ldl');
      final hdl = s.number('hdl'), tg = s.number('triglycerides');
      if (total == null && ldl == null && hdl == null && tg == null) {
        throw const InvalidInput();
      }
      return api.events.hwLipids(
          idempotencyKey: k,
          labDate: date,
          total: total,
          ldl: ldl,
          hdl: hdl,
          triglycerides: tg);
    }),
    'POST /v1/program-data/st/readings':
        queued('POST /v1/program-data/st/readings', (api, s, k) {
      final reading = s.number('reading');
      if (reading == null) throw const InvalidInput();
      return api.events.stReading(
        idempotencyKey: k,
        reading: reading,
        when: byLabel(GlucoseWhen.values, s.one('when')),
        feelings: allByLabel(GlucoseFeeling.values, s.list('how_do_you_feel')),
        note: s.text('note_optional'),
      );
    }),
    'POST /v1/program-data/st/a1c':
        queued('POST /v1/program-data/st/a1c', (api, s, k) {
      final a1c = s.number('a1c');
      if (a1c == null) throw const InvalidInput();
      return api.events.stA1c(
          idempotencyKey: k,
          a1c: a1c,
          labDate: s.date('lab_date') ?? DateTime.now());
    }),
    'POST /v1/program-data/ca/zone-checks':
        queued('POST /v1/program-data/ca/zone-checks', (api, s, k) async {
      // The zone from the member's own plan (sync document), as the screen
      // decided it; never from another screen's session keys.
      await kit.services.openSync();
      final plan = kit.services.sync.answersOf('ca', 'plan');
      final values = <String, Object?>{
        ...s.call.payload,
        if (plan != null)
          for (final MapEntry(:key, :value)
              in decodeScreen('ca_plan', plan).entries)
            'ca_plan.$key': value,
      };
      final zone = TRules.zoneOf(values);
      if (zone.startsWith('Invalid')) throw const InvalidInput();
      return api.events.caZoneCheck(
        idempotencyKey: k,
        zone: byLabel(AsthmaZone.values, zone) ?? AsthmaZone.green,
        symptoms: allByLabel(ZoneSymptom.values, s.list('symptoms')),
        peakFlow: s.number('peak_flow'),
      );
    }),
    'POST /v1/program-data/ca/symptoms':
        queued('POST /v1/program-data/ca/symptoms', (api, s, k) {
      final symptoms = allByLabel(AsthmaSymptom.values, s.list('value'));
      if (symptoms.isEmpty) throw const InvalidInput();
      return api.events.caSymptoms(
        idempotencyKey: k,
        symptoms: symptoms,
        severity: byLabel(SymptomSeverity.values, s.one('how_bad')),
        triggers: allByLabel(AsthmaTrigger.values, s.list('possible_trigger')),
        note: s.text('note_optional'),
      );
    }),
    'POST /v1/program-data/ea/moods':
        queued('POST /v1/program-data/ea/moods', (api, s, k) {
      final mood = byLabel(Mood.values, s.one('how_are_you_right_now'));
      if (mood == null) throw const InvalidInput();
      return api.events.eaMood(
          idempotencyKey: k,
          mood: mood,
          topics: allByLabel(MoodTopic.values, s.list('going_on')));
    }),
    'POST /v1/program-data/ea/check-backs':
        queued('POST /v1/program-data/ea/check-backs', (api, s, k) {
      final change = byLabel(CheckBackChange.values, s.one('value'));
      if (change == null) throw const InvalidInput();
      return api.events.eaCheckBack(
          idempotencyKey: k,
          change: change,
          reachedOut: byLabel(
              ReachedOut.values, s.one('did_you_reach_out_to_someone')));
    }),
    'POST /v1/program-data/re/labs':
        queued('POST /v1/program-data/re/labs', (api, s, k) {
      final egfr = s.number('egfr'),
          acr = s.number('urine_acr'),
          alt = s.number('alt_liver');
      if (egfr == null && acr == null && alt == null) {
        throw const InvalidInput();
      }
      return api.events.reLabs(
          idempotencyKey: k,
          labDate: s.date('lab_date') ?? DateTime.now(),
          egfr: egfr,
          urineAcr: acr,
          alt: alt);
    }),
    'POST /v1/program-data/sd/sessions': queued(
        'POST /v1/program-data/sd/sessions',
        (api, s, k) => api.events.sdSession(
            idempotencyKey: k,
            settings: allByLabel(SessionSetting.values, s.list('value')))),
    'POST /v1/program-data/sd/falls': queued('POST /v1/program-data/sd/falls',
        (api, s, k) => api.events.sdFall(idempotencyKey: k)),
    'POST /v1/program-data/ck/done':
        queued('POST /v1/program-data/ck/done', (api, s, k) {
      final item = s.text('what');
      if (item == null) throw const InvalidInput();
      return api.events.ckDone(
          idempotencyKey: k,
          item: slug(item),
          doneOn: s.date('date') ?? DateTime.now(),
          place: s.text('where_optional'));
    }),
    'POST /v1/program-data/be/diary':
        queued('POST /v1/program-data/be/diary', (api, s, k) {
      final fatigue = s.number('fatigue')?.round();
      if (fatigue == null) throw const InvalidInput();
      return api.events.beDiary(
          idempotencyKey: k,
          fatigue: fatigue,
          symptoms: allByLabel(DiarySymptom.values, s.list('anything_else')));
    }),
    'POST /v1/program-data/be/survivorship':
        queued('POST /v1/program-data/be/survivorship', (api, s, k) {
      final feeling = byLabel(SurvivorshipFeeling.values, s.one('value'));
      if (feeling == null) throw const InvalidInput();
      return api.events.beSurvivorship(idempotencyKey: k, feeling: feeling);
    }),
    'POST /v1/program-data/sf/pauses':
        queued('POST /v1/program-data/sf/pauses', (api, s, k) {
      final reason = byLabel(PauseReason.values, s.one('value'));
      if (reason == null) throw const InvalidInput();
      return api.events.sfPause(idempotencyKey: k, reason: reason);
    }),
    'POST /v1/records/check-ins':
        queued('POST /v1/records/check-ins', (api, s, k) {
      final bf = s.one('value');
      final sf = s.one('value_2');
      final feel = byLabel(CheckInFeel.values, s.one('how_do_you_feel_today'));
      final stress = byLabel(CheckInStress.values, s.one('stress_today'));
      final smoked = bf == 'Skip' ? null : byLabel(SmokedToday.values, bf);
      final screen =
          sf == 'Skip' ? null : byLabel(ScreenTimeFeeling.values, sf);
      if (feel == null && stress == null && smoked == null && screen == null) {
        throw const InvalidInput();
      }
      return api.records.checkIn(
          idempotencyKey: k,
          feel: feel,
          stress: stress,
          smokedToday: smoked,
          screenTime: screen);
    }),
    'POST /v1/records/lessons': (call) async {
      final lesson = HandlerKit.argumentOfScreen?.call(call.screenId);
      final programme = lesson?.split('.').first;
      if (lesson == null || programme == null || programme.length != 2) {
        return const TResult.failed(HandlerCodes.programUnknown);
      }
      return queued(
          'POST /v1/records/lessons',
          (api, s, k) => api.records.lessonCompleted(
              idempotencyKey: k, programme: programme, lessonId: lesson))(call);
    },
  };
}
