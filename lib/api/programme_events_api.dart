// Programme events (`POST /v1/program-data/<code>/<kind>`): readings, labs,
// checks, moods, sessions, falls, pauses, done items and diary entries.
//
// Every call carries an Idempotency-Key, so a retry of the same entry never
// creates a second record. Times are sent as UTC instants, lab and done dates
// as `YYYY-MM-DD` of the given date's own fields.
import 'package:flutter/foundation.dart';

import '../backend/backend.dart';
import 'api_result.dart';

/// The answer to an event POST.
@immutable
class SubmissionReceipt {
  const SubmissionReceipt({
    required this.submissionId,
    required this.replayed,
    this.entries = const <String>[],
  });

  factory SubmissionReceipt.fromJson(Map<String, Object?> json) =>
      SubmissionReceipt(
        submissionId: field<String>(json, 'submissionId'),
        replayed: json['replayed'] == true,
        entries: [
          for (final e in (json['entries'] as List<Object?>?) ?? const [])
            e is String ? e : throw const ApiShapeException(),
        ],
      );

  /// The Idempotency-Key as a UUID.
  final String submissionId;

  /// A repeat of a stored submission: nothing new was written.
  final bool replayed;

  /// Check-ins only: the programmes that hold a row of it.
  final List<String> entries;
}

enum GlucoseWhen implements WireValue {
  fasting('fasting'),
  beforeMeal('before_meal'),
  twoHoursAfterMeal('2_h_after_meal'),
  bedtime('bedtime'),
  other('other');

  const GlucoseWhen(this.wire);
  @override
  final String wire;
}

enum GlucoseFeeling implements WireValue {
  fine('fine'),
  shaky('shaky'),
  sweaty('sweaty'),
  tired('tired'),
  thirsty('thirsty');

  const GlucoseFeeling(this.wire);
  @override
  final String wire;
}

enum AsthmaZone implements WireValue {
  green('green'),
  yellow('yellow'),
  red('red');

  const AsthmaZone(this.wire);
  @override
  final String wire;
}

/// Symptoms on a zone check.
enum ZoneSymptom implements WireValue {
  coughing('coughing'),
  wheezing('wheezing'),
  shortOfBreath('short_of_breath'),
  chestTightness('chest_tightness'),
  wokeAtNight('woke_at_night'),
  cantSpeakInFullSentences('can_t_speak_in_full_sentences');

  const ZoneSymptom(this.wire);
  @override
  final String wire;
}

/// Symptoms in a symptom log.
enum AsthmaSymptom implements WireValue {
  coughing('coughing'),
  wheezing('wheezing'),
  shortOfBreath('short_of_breath'),
  chestTightness('chest_tightness'),
  wokeAtNight('woke_at_night');

  const AsthmaSymptom(this.wire);
  @override
  final String wire;
}

enum SymptomSeverity implements WireValue {
  mild('mild'),
  moderate('moderate'),
  severe('severe');

  const SymptomSeverity(this.wire);
  @override
  final String wire;
}

enum AsthmaTrigger implements WireValue {
  coldAir('cold_air'),
  smoke('smoke'),
  pollen('pollen'),
  exercise('exercise'),
  notSure('not_sure');

  const AsthmaTrigger(this.wire);
  @override
  final String wire;
}

enum Mood implements WireValue {
  veryLow('very_low'),
  low('low'),
  okay('okay'),
  good('good'),
  great('great');

  const Mood(this.wire);
  @override
  final String wire;
}

enum MoodTopic implements WireValue {
  work('work'),
  money('money'),
  family('family'),
  health('health'),
  lonely('lonely'),
  sleep('sleep'),
  thoughtsOfHarmingMyself('thoughts_of_harming_myself'),
  notSure('not_sure');

  const MoodTopic(this.wire);
  @override
  final String wire;
}

enum CheckBackChange implements WireValue {
  worse('worse'),
  same('same'),
  better('better');

  const CheckBackChange(this.wire);
  @override
  final String wire;
}

enum ReachedOut implements WireValue {
  yesIHaveAnAppointment('yes_i_have_an_appointment'),
  notYet('not_yet'),
  iDontWantTo('i_don_t_want_to');

  const ReachedOut(this.wire);
  @override
  final String wire;
}

enum SessionSetting implements WireValue {
  audioOn('audio_on'),
  largeText('large_text'),
  captions('captions');

  const SessionSetting(this.wire);
  @override
  final String wire;
}

enum PauseReason implements WireValue {
  messageSomeone('message_someone'),
  bored('bored'),
  avoidingSomething('avoiding_something'),
  cantSleep('can_t_sleep');

  const PauseReason(this.wire);
  @override
  final String wire;
}

enum DiarySymptom implements WireValue {
  nausea('nausea'),
  pain('pain'),
  mouthSores('mouth_sores'),
  numbness('numbness'),
  lowMood('low_mood');

  const DiarySymptom(this.wire);
  @override
  final String wire;
}

enum SurvivorshipFeeling implements WireValue {
  hard('hard'),
  mixed('mixed'),
  good('good');

  const SurvivorshipFeeling(this.wire);
  @override
  final String wire;
}

/// The event routes, one method each.
class ProgrammeEventsApi {
  const ProgrammeEventsApi(this._transport);

  final BackendTransport _transport;

  Future<ApiResult<SubmissionReceipt>> _post(
    String code,
    String kind,
    String idempotencyKey,
    Map<String, Object?> body,
  ) =>
      callBackend(
        _transport,
        BackendRequest(
          service: BackendService.api,
          method: BackendMethod.post,
          path: '/v1/program-data/$code/$kind',
          body: body,
          idempotencyKey: idempotencyKey,
        ),
        (_, json) => SubmissionReceipt.fromJson(jsonObject(json)),
      );

  static List<String> _wires(Iterable<WireValue> values) =>
      [for (final v in values) v.wire];

  /// `POST /v1/program-data/hw/readings`: a blood pressure reading. A safety
  /// endpoint.
  Future<ApiResult<SubmissionReceipt>> hwReading({
    required String idempotencyKey,
    required int systolic,
    required int diastolic,
    int? pulse,
    DateTime? measuredAt,
  }) =>
      _post('hw', 'readings', idempotencyKey, {
        'systolic': systolic,
        'diastolic': diastolic,
        if (pulse != null) 'pulse': pulse,
        if (measuredAt != null) 'measuredAt': wireTime(measuredAt),
      });

  /// `POST /v1/program-data/hw/lipids`: at least one value.
  Future<ApiResult<SubmissionReceipt>> hwLipids({
    required String idempotencyKey,
    required DateTime labDate,
    num? total,
    num? ldl,
    num? hdl,
    num? triglycerides,
  }) {
    if (total == null && ldl == null && hdl == null && triglycerides == null) {
      throw ArgumentError('a lipid panel needs at least one value');
    }
    return _post('hw', 'lipids', idempotencyKey, {
      if (total != null) 'total': total,
      if (ldl != null) 'ldl': ldl,
      if (hdl != null) 'hdl': hdl,
      if (triglycerides != null) 'triglycerides': triglycerides,
      'labDate': wireDate(labDate),
    });
  }

  /// `POST /v1/program-data/st/readings`: a glucose reading. A safety
  /// endpoint.
  Future<ApiResult<SubmissionReceipt>> stReading({
    required String idempotencyKey,
    required num reading,
    GlucoseWhen? when,
    Set<GlucoseFeeling> feelings = const {},
    String? note,
    DateTime? measuredAt,
  }) =>
      _post('st', 'readings', idempotencyKey, {
        'reading': reading,
        if (when != null) 'when': when.wire,
        if (feelings.isNotEmpty) 'feelings': _wires(feelings),
        if (note != null) 'note': note,
        if (measuredAt != null) 'measuredAt': wireTime(measuredAt),
      });

  /// `POST /v1/program-data/st/a1c`.
  Future<ApiResult<SubmissionReceipt>> stA1c({
    required String idempotencyKey,
    required num a1c,
    required DateTime labDate,
  }) =>
      _post('st', 'a1c', idempotencyKey, {
        'a1c': a1c,
        'labDate': wireDate(labDate),
      });

  /// `POST /v1/program-data/re/labs`: at least one value.
  Future<ApiResult<SubmissionReceipt>> reLabs({
    required String idempotencyKey,
    required DateTime labDate,
    num? egfr,
    num? urineAcr,
    num? alt,
  }) {
    if (egfr == null && urineAcr == null && alt == null) {
      throw ArgumentError('a lab entry needs at least one value');
    }
    return _post('re', 'labs', idempotencyKey, {
      if (egfr != null) 'egfr': egfr,
      if (urineAcr != null) 'urineAcr': urineAcr,
      if (alt != null) 'alt': alt,
      'labDate': wireDate(labDate),
    });
  }

  /// `POST /v1/program-data/ca/zone-checks`. A safety endpoint.
  Future<ApiResult<SubmissionReceipt>> caZoneCheck({
    required String idempotencyKey,
    required AsthmaZone zone,
    Set<ZoneSymptom> symptoms = const {},
    num? peakFlow,
    DateTime? checkedAt,
  }) =>
      _post('ca', 'zone-checks', idempotencyKey, {
        'zone': zone.wire,
        if (symptoms.isNotEmpty) 'symptoms': _wires(symptoms),
        if (peakFlow != null) 'peakFlow': peakFlow,
        if (checkedAt != null) 'checkedAt': wireTime(checkedAt),
      });

  /// `POST /v1/program-data/ca/symptoms`: at least one symptom.
  Future<ApiResult<SubmissionReceipt>> caSymptoms({
    required String idempotencyKey,
    required Set<AsthmaSymptom> symptoms,
    SymptomSeverity? severity,
    Set<AsthmaTrigger> triggers = const {},
    String? note,
    DateTime? occurredAt,
  }) {
    if (symptoms.isEmpty) {
      throw ArgumentError('a symptom log needs at least one symptom');
    }
    return _post('ca', 'symptoms', idempotencyKey, {
      'symptoms': _wires(symptoms),
      if (severity != null) 'severity': severity.wire,
      if (triggers.isNotEmpty) 'triggers': _wires(triggers),
      if (note != null) 'note': note,
      if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
    });
  }

  /// `POST /v1/program-data/ea/moods`. A safety endpoint.
  Future<ApiResult<SubmissionReceipt>> eaMood({
    required String idempotencyKey,
    required Mood mood,
    Set<MoodTopic> topics = const {},
    DateTime? occurredAt,
  }) =>
      _post('ea', 'moods', idempotencyKey, {
        'mood': mood.wire,
        if (topics.isNotEmpty) 'topics': _wires(topics),
        if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
      });

  /// `POST /v1/program-data/ea/check-backs`.
  Future<ApiResult<SubmissionReceipt>> eaCheckBack({
    required String idempotencyKey,
    required CheckBackChange change,
    ReachedOut? reachedOut,
    DateTime? occurredAt,
  }) =>
      _post('ea', 'check-backs', idempotencyKey, {
        'change': change.wire,
        if (reachedOut != null) 'reachedOut': reachedOut.wire,
        if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
      });

  /// `POST /v1/program-data/sd/sessions`.
  Future<ApiResult<SubmissionReceipt>> sdSession({
    required String idempotencyKey,
    Set<SessionSetting> settings = const {},
    DateTime? occurredAt,
  }) =>
      _post('sd', 'sessions', idempotencyKey, {
        if (settings.isNotEmpty) 'settings': _wires(settings),
        if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
      });

  /// `POST /v1/program-data/sd/falls`.
  Future<ApiResult<SubmissionReceipt>> sdFall({
    required String idempotencyKey,
    DateTime? occurredAt,
  }) =>
      _post('sd', 'falls', idempotencyKey, {
        if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
      });

  /// `POST /v1/program-data/sf/pauses`.
  Future<ApiResult<SubmissionReceipt>> sfPause({
    required String idempotencyKey,
    required PauseReason reason,
    DateTime? occurredAt,
  }) =>
      _post('sf', 'pauses', idempotencyKey, {
        'reason': reason.wire,
        if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
      });

  /// `POST /v1/program-data/ck/done`.
  Future<ApiResult<SubmissionReceipt>> ckDone({
    required String idempotencyKey,
    required String item,
    required DateTime doneOn,
    String? place,
    DateTime? occurredAt,
  }) =>
      _post('ck', 'done', idempotencyKey, {
        'item': item,
        'doneOn': wireDate(doneOn),
        if (place != null) 'place': place,
        if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
      });

  /// `POST /v1/program-data/be/diary`.
  Future<ApiResult<SubmissionReceipt>> beDiary({
    required String idempotencyKey,
    required int fatigue,
    Set<DiarySymptom> symptoms = const {},
    DateTime? occurredAt,
  }) =>
      _post('be', 'diary', idempotencyKey, {
        'fatigue': fatigue,
        if (symptoms.isNotEmpty) 'symptoms': _wires(symptoms),
        if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
      });

  /// `POST /v1/program-data/be/survivorship`.
  Future<ApiResult<SubmissionReceipt>> beSurvivorship({
    required String idempotencyKey,
    required SurvivorshipFeeling feeling,
    DateTime? occurredAt,
  }) =>
      _post('be', 'survivorship', idempotencyKey, {
        'feeling': feeling.wire,
        if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
      });
}
