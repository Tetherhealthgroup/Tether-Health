// The day window, with the API's unit cases (api/src/today/
// today.service.spec.ts). Dart has no zone database, so the two zones of
// those cases are given as rules here.
import 'package:breathefree_patient/backend/sandbox/day_window.dart';
import 'package:flutter_test/flutter_test.dart';

/// New York (US rules for 2026) and Kolkata; anything else unknown.
Duration? _zones(String zone, DateTime instant) {
  switch (zone) {
    case 'UTC':
      return Duration.zero;
    case 'Asia/Kolkata':
      return const Duration(hours: 5, minutes: 30);
    case 'America/New_York':
      final t = instant.toUtc();
      // Daylight saving 2026: 8 March 07:00Z to 1 November 06:00Z.
      final dst = !t.isBefore(DateTime.utc(2026, 3, 8, 7)) &&
          t.isBefore(DateTime.utc(2026, 11, 1, 6));
      return Duration(hours: dst ? -4 : -5);
  }
  return null;
}

void main() {
  test('an unknown or missing zone is UTC', () {
    expect(effectiveTimeZone(null, _zones), 'UTC');
    expect(effectiveTimeZone('', _zones), 'UTC');
    expect(effectiveTimeZone('Nowhere/Synthetic', _zones), 'UTC');
    expect(effectiveTimeZone('America/New_York', _zones), 'America/New_York');
  });

  test('the date and its bounds follow the member\'s zone across the UTC day',
      () {
    final now = DateTime.parse('2026-10-22T02:30:00Z');
    final ny = dayWindow('America/New_York', now, offsetOf: _zones);
    expect(ny.zone, 'America/New_York');
    expect(ny.date, '2026-10-21');
    expect(ny.todayStart.toIso8601String(), '2026-10-21T04:00:00.000Z');
    expect(ny.tomorrowStart.toIso8601String(), '2026-10-22T04:00:00.000Z');
    expect(ny.last7Start.toIso8601String(), '2026-10-15T04:00:00.000Z');
    final kolkata = dayWindow('Asia/Kolkata', now, offsetOf: _zones);
    expect(kolkata.date, '2026-10-22');
    expect(kolkata.todayStart.toIso8601String(), '2026-10-21T18:30:00.000Z');
    expect(kolkata.tomorrowStart.toIso8601String(), '2026-10-22T18:30:00.000Z');
    final utc = dayWindow(null, now, offsetOf: _zones);
    expect(utc.zone, 'UTC');
    expect(utc.date, '2026-10-22');
    expect(utc.todayStart.toIso8601String(), '2026-10-22T00:00:00.000Z');
  });

  test('a day with a daylight-saving change is 23 or 25 hours long', () {
    final start = startOfLocalDate('America/New_York', '2026-11-01', _zones);
    final end = startOfLocalDate('America/New_York', '2026-11-02', _zones);
    expect(start.toIso8601String(), '2026-11-01T04:00:00.000Z');
    expect(end.difference(start).inHours, 25);
    expect(
        localDate('America/New_York',
            end.subtract(const Duration(milliseconds: 1)), _zones),
        '2026-11-01');
  });

  test('adds calendar days across months', () {
    expect(addDays('2026-10-28', 6), '2026-11-03');
    expect(addDays('2026-03-01', -1), '2026-02-28');
  });

  test('the sandbox rule: UTC by name or when empty, else the phone\'s zone',
      () {
    final at = DateTime.utc(2026, 1, 1);
    expect(deviceZoneOffset('', at), isNull);
    expect(deviceZoneOffset('UTC', at), Duration.zero);
    expect(
        deviceZoneOffset('Europe/Somewhere', at), at.toLocal().timeZoneOffset);
  });
}
