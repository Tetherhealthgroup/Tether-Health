// Shared records (check-ins, rescues, lessons), the member's day, one
// programme's summary, and notification preferences.
import 'package:flutter/foundation.dart';

import '../backend/backend.dart';
import 'api_result.dart';
import 'programme_events_api.dart' show SubmissionReceipt;

enum CheckInFeel implements WireValue {
  low('low'),
  notGreat('not_great'),
  okay('okay'),
  good('good'),
  great('great');

  const CheckInFeel(this.wire);
  @override
  final String wire;
}

enum CheckInStress implements WireValue {
  low('low'),
  some('some'),
  high('high');

  const CheckInStress(this.wire);
  @override
  final String wire;
}

/// BreatheFree's check-in question.
enum SmokedToday implements WireValue {
  no('no'),
  aPuff('a_puff'),
  oneOrMore('one_or_more');

  const SmokedToday(this.wire);
  @override
  final String wire;
}

/// ScrollFree's check-in question.
enum ScreenTimeFeeling implements WireValue {
  better('better'),
  same('same'),
  drained('drained');

  const ScreenTimeFeeling(this.wire);
  @override
  final String wire;
}

enum RescueHelped implements WireValue {
  yes('yes'),
  aLittle('a_little'),
  no('no');

  const RescueHelped(this.wire);
  @override
  final String wire;
}

/// The window of a summary.
enum SummaryRange implements WireValue {
  days7('7d', 7),
  days30('30d', 30),
  days90('90d', 90);

  const SummaryRange(this.wire, this.days);
  @override
  final String wire;
  final int days;
}

/// One programme's block of the member's day. [fields] holds the
/// programme's own fixed fields (for example `lastBp` for hw) as sent.
@immutable
class TodayProgramme {
  const TodayProgramme({
    required this.code,
    required this.status,
    required this.mode,
    required this.reminderAt,
    required this.lessonsCompleted,
    required this.fields,
  });

  factory TodayProgramme.fromJson(Map<String, Object?> json) => TodayProgramme(
        code: field<String>(json, 'code'),
        status: field<String>(json, 'status'),
        mode: field<String?>(json, 'mode'),
        reminderAt: field<String?>(json, 'reminderAt'),
        lessonsCompleted: field<num>(json, 'lessonsCompleted').toInt(),
        fields: Map<String, Object?>.unmodifiable({
          for (final MapEntry(:key, :value) in json.entries)
            if (!_common.contains(key)) key: value,
        }),
      );

  static const _common = {
    'code',
    'status',
    'mode',
    'reminderAt',
    'lessonsCompleted',
  };

  final String code;
  final String status;
  final String? mode;

  /// `HH:MM`, or null when no reminder is set.
  final String? reminderAt;
  final int lessonsCompleted;
  final Map<String, Object?> fields;
}

/// `GET /v1/today`.
@immutable
class Today {
  const Today({
    required this.date,
    required this.checkinDoneToday,
    required this.lastHelpfulRescue,
    required this.programmes,
  });

  factory Today.fromJson(Map<String, Object?> json) => Today(
        date: field<String>(json, 'date'),
        checkinDoneToday: field<bool>(jsonObject(json['checkin']), 'doneToday'),
        lastHelpfulRescue: switch (
            jsonObject(json['account'])['lastHelpfulRescue']) {
          null => null,
          final rescue => jsonObject(rescue),
        },
        programmes: [
          for (final p in jsonObjects(json['programmes']))
            TodayProgramme.fromJson(p),
        ],
      );

  /// Today's date in the member's time zone (`YYYY-MM-DD`).
  final String date;
  final bool checkinDoneToday;

  /// `{tool, at}` of the newest shared rescue that helped, or null.
  final Map<String, Object?>? lastHelpfulRescue;
  final List<TodayProgramme> programmes;
}

/// `GET /v1/records/summary`: one programme's records.
@immutable
class RecordsSummary {
  const RecordsSummary({
    required this.programme,
    required this.days,
    required this.since,
    required this.status,
    required this.observations,
    required this.entries,
    required this.lessons,
    required this.lapses,
    required this.rescues,
  });

  factory RecordsSummary.fromJson(Map<String, Object?> json) => RecordsSummary(
        programme: field<String>(json, 'programme'),
        days: field<num>(json, 'days').toInt(),
        since: DateTime.parse(field<String>(json, 'since')),
        status: field<String>(json, 'status'),
        observations: jsonObjects(json['observations']),
        entries: jsonObjects(json['entries']),
        lessons: jsonObjects(json['lessons']),
        lapses: jsonObjects(json['lapses'] ?? const <Object?>[]),
        rescues: jsonObjects(json['rescues'] ?? const <Object?>[]),
      );

  final String programme;
  final int days;
  final DateTime since;
  final String status;
  final List<Map<String, Object?>> observations;
  final List<Map<String, Object?>> entries;
  final List<Map<String, Object?>> lessons;
  final List<Map<String, Object?>> lapses;
  final List<Map<String, Object?>> rescues;
}

/// A programme's daily reminder time.
@immutable
class ProgrammeReminder {
  const ProgrammeReminder({required this.programme, required this.remindAt});

  factory ProgrammeReminder.fromJson(Map<String, Object?> json) =>
      ProgrammeReminder(
        programme: field<String>(json, 'programme'),
        remindAt: field<String>(json, 'remindAt'),
      );

  final String programme;

  /// `HH:MM`, 24-hour.
  final String remindAt;

  Map<String, Object?> toJson() =>
      {'programme': programme, 'remindAt': remindAt};
}

/// `GET /v1/notifications/preferences`.
@immutable
class NotificationPreferences {
  const NotificationPreferences({
    required this.remindersEnabled,
    required this.sensitiveDetails,
    required this.quietHoursEnabled,
    required this.persisted,
    required this.programmeReminders,
  });

  factory NotificationPreferences.fromJson(Map<String, Object?> json) =>
      NotificationPreferences(
        remindersEnabled: field<bool>(json, 'remindersEnabled'),
        sensitiveDetails: field<bool>(json, 'sensitiveDetails'),
        quietHoursEnabled: field<bool>(json, 'quietHoursEnabled'),
        persisted: field<bool>(json, 'persisted'),
        programmeReminders: [
          for (final r in jsonObjects(json['programmeReminders']))
            ProgrammeReminder.fromJson(r),
        ],
      );

  final bool remindersEnabled;
  final bool sensitiveDetails;
  final bool quietHoursEnabled;

  /// False while the member never saved the switches.
  final bool persisted;
  final List<ProgrammeReminder> programmeReminders;
}

/// The records, Today, summary and notification preference routes.
class RecordsApi {
  const RecordsApi(this._transport);

  final BackendTransport _transport;

  Future<ApiResult<T>> _send<T>(
    BackendMethod method,
    String path,
    T Function(int status, Object? json) parse, {
    Object? body,
    Map<String, String> query = const {},
    String? idempotencyKey,
  }) =>
      callBackend(
        _transport,
        BackendRequest(
          service: BackendService.api,
          method: method,
          path: path,
          body: body,
          query: query,
          idempotencyKey: idempotencyKey,
        ),
        parse,
      );

  static SubmissionReceipt _receipt(int _, Object? json) =>
      SubmissionReceipt.fromJson(jsonObject(json));

  /// `POST /v1/records/check-ins`: at least one of [feel], [stress] or an
  /// answer.
  Future<ApiResult<SubmissionReceipt>> checkIn({
    required String idempotencyKey,
    CheckInFeel? feel,
    CheckInStress? stress,
    SmokedToday? smokedToday,
    ScreenTimeFeeling? screenTime,
    DateTime? occurredAt,
  }) {
    if (feel == null &&
        stress == null &&
        smokedToday == null &&
        screenTime == null) {
      throw ArgumentError('a check-in needs at least one answer');
    }
    return _send(
      BackendMethod.post,
      '/v1/records/check-ins',
      _receipt,
      idempotencyKey: idempotencyKey,
      body: {
        if (feel != null) 'feel': feel.wire,
        if (stress != null) 'stress': stress.wire,
        if (smokedToday != null || screenTime != null)
          'answers': {
            if (smokedToday != null) 'bf': smokedToday.wire,
            if (screenTime != null) 'sf': screenTime.wire,
          },
        if (occurredAt != null) 'occurredAt': wireTime(occurredAt),
      },
    );
  }

  /// `POST /v1/records/rescues`. [breatheFree] files it under BreatheFree;
  /// otherwise it is a shared rescue.
  Future<ApiResult<SubmissionReceipt>> rescue({
    required String idempotencyKey,
    required String tool,
    bool breatheFree = false,
    DateTime? openedAt,
    int? intensityBefore,
    int? intensityAfter,
    RescueHelped? helped,
    bool? escalated,
  }) =>
      _send(
        BackendMethod.post,
        '/v1/records/rescues',
        _receipt,
        idempotencyKey: idempotencyKey,
        body: {
          if (breatheFree) 'programme': 'bf',
          'tool': tool,
          if (openedAt != null) 'openedAt': wireTime(openedAt),
          if (intensityBefore != null) 'intensityBefore': intensityBefore,
          if (intensityAfter != null) 'intensityAfter': intensityAfter,
          if (helped != null) 'helped': helped.wire,
          if (escalated != null) 'escalated': escalated,
        },
      );

  /// `POST /v1/records/lessons`: [lessonId] starts with `<programme>.`.
  Future<ApiResult<SubmissionReceipt>> lessonCompleted({
    required String idempotencyKey,
    required String programme,
    required String lessonId,
  }) =>
      _send(
        BackendMethod.post,
        '/v1/records/lessons',
        _receipt,
        idempotencyKey: idempotencyKey,
        body: {'programme': programme, 'lessonId': lessonId},
      );

  /// `GET /v1/today`.
  Future<ApiResult<Today>> today() => _send(
        BackendMethod.get,
        '/v1/today',
        (_, json) => Today.fromJson(jsonObject(json)),
      );

  /// `GET /v1/records/summary?programme=&range=`.
  Future<ApiResult<RecordsSummary>> summary({
    required String programme,
    required SummaryRange range,
  }) =>
      _send(
        BackendMethod.get,
        '/v1/records/summary',
        (_, json) => RecordsSummary.fromJson(jsonObject(json)),
        query: {'programme': programme, 'range': range.wire},
      );

  /// `GET /v1/notifications/preferences`.
  Future<ApiResult<NotificationPreferences>> notificationPreferences() => _send(
        BackendMethod.get,
        '/v1/notifications/preferences',
        (_, json) => NotificationPreferences.fromJson(jsonObject(json)),
      );

  /// `PATCH /v1/notifications/preferences`: changes only what is given.
  Future<ApiResult<NotificationPreferences>> updateNotificationPreferences({
    bool? remindersEnabled,
    bool? sensitiveDetails,
    bool? quietHoursEnabled,
    List<ProgrammeReminder>? programmeReminders,
  }) =>
      _send(
        BackendMethod.patch,
        '/v1/notifications/preferences',
        (_, json) => NotificationPreferences.fromJson(jsonObject(json)),
        body: {
          if (remindersEnabled != null) 'remindersEnabled': remindersEnabled,
          if (sensitiveDetails != null) 'sensitiveDetails': sensitiveDetails,
          if (quietHoursEnabled != null) 'quietHoursEnabled': quietHoursEnabled,
          if (programmeReminders != null)
            'programmeReminders': [
              for (final r in programmeReminders) r.toJson(),
            ],
        },
      );
}
