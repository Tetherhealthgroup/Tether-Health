// The member's calendar day, ported from the API (`api/src/today/
// day-window.ts`): today's local date, its bounds, and the last 7 days.
//
// Dart has no time-zone database, so the zone's offset is a function
// ([ZoneOffset]). The sandbox uses [deviceZoneOffset]: an empty, "UTC" or
// unknown zone is UTC, and any other zone is taken to be the phone's own
// zone (the app stores the phone's zone in the profile). The algorithm
// itself is the API's, including the two passes across a daylight-saving
// change.

/// The offset of [zone] from UTC at [instant], or null when the zone is
/// unknown (then it is UTC).
typedef ZoneOffset = Duration? Function(String zone, DateTime instant);

/// The sandbox's zone rule: UTC for an empty or "UTC" zone, otherwise the
/// phone's own offset at that instant.
Duration? deviceZoneOffset(String zone, DateTime instant) {
  if (zone.isEmpty) return null;
  if (zone == 'UTC' || zone == 'Etc/UTC') return Duration.zero;
  return instant.toLocal().timeZoneOffset;
}

/// The day window of one moment.
class DayWindow {
  const DayWindow({
    required this.zone,
    required this.date,
    required this.todayStart,
    required this.tomorrowStart,
    required this.last7Start,
  });

  final String zone;

  /// Today's local date, `YYYY-MM-DD`.
  final String date;

  /// Start of today (inclusive), UTC.
  final DateTime todayStart;

  /// Start of tomorrow (exclusive), UTC.
  final DateTime tomorrowStart;

  /// Start of the local day six days before today.
  final DateTime last7Start;
}

/// The zone if [offsetOf] knows it, else `UTC`.
String effectiveTimeZone(Object? zone, ZoneOffset offsetOf) {
  if (zone is! String || zone.isEmpty) return 'UTC';
  return offsetOf(zone, DateTime.utc(2000)) == null ? 'UTC' : zone;
}

Duration _offset(String zone, DateTime instant, ZoneOffset offsetOf) =>
    zone == 'UTC' ? Duration.zero : offsetOf(zone, instant) ?? Duration.zero;

/// The local date in [zone] at [instant].
String localDate(String zone, DateTime instant, ZoneOffset offsetOf) {
  final local = instant.toUtc().add(_offset(zone, instant, offsetOf));
  return _format(local);
}

String _format(DateTime utcFields) =>
    '${utcFields.year.toString().padLeft(4, '0')}-'
    '${utcFields.month.toString().padLeft(2, '0')}-'
    '${utcFields.day.toString().padLeft(2, '0')}';

DateTime _midnightUtc(String date) {
  final parts = date.split('-').map(int.parse).toList();
  return DateTime.utc(parts[0], parts[1], parts[2]);
}

/// The instant [date] begins in [zone].
DateTime startOfLocalDate(String zone, String date, ZoneOffset offsetOf) {
  final midnight = _midnightUtc(date);
  // Two passes settle the offset across a daylight-saving change.
  var instant = midnight.subtract(_offset(zone, midnight, offsetOf));
  instant = midnight.subtract(_offset(zone, instant, offsetOf));
  return instant;
}

/// [date] plus [days] calendar days.
String addDays(String date, int days) =>
    _format(_midnightUtc(date).add(Duration(days: days)));

/// The window of [now] in [zone].
DayWindow dayWindow(
  Object? zone,
  DateTime now, {
  ZoneOffset offsetOf = deviceZoneOffset,
}) {
  final effective = effectiveTimeZone(zone, offsetOf);
  final date = localDate(effective, now, offsetOf);
  DateTime start(String day) => startOfLocalDate(effective, day, offsetOf);
  return DayWindow(
    zone: effective,
    date: date,
    todayStart: start(date),
    tomorrowStart: start(addDays(date, 1)),
    last7Start: start(addDays(date, -6)),
  );
}
