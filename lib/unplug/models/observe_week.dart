/// Sample data for the Observe Week baseline report on screen E.
///
/// **This is illustrative sample data, not a measurement.** No device is being
/// read: the module has no native implementation yet, and on iOS the values
/// below could not be produced at this granularity even when it does. The
/// numbers exist so the report's shape, wording and platform labelling can be
/// reviewed before any real data is collected.
///
/// The per-app split is deliberately Android-only, matching addendum §1.
library;

/// A named slice of the day, used for the time-of-day distribution.
class DaypartUsage {
  const DaypartUsage(this.label, this.minutes);

  final String label;
  final int minutes;
}

/// One named app, with a real duration. Android only.
class AppUsage {
  const AppUsage(this.packageLabel, this.minutes, this.opens);

  final String packageLabel;
  final int minutes;
  final int opens;
}

/// The seven-day baseline both platforms can produce.
class ObserveWeek {
  const ObserveWeek({
    required this.dailyMinutes,
    required this.opens,
    required this.dayparts,
    required this.perApp,
  });

  /// Minutes on the selected set, one entry per day, oldest first.
  final List<int> dailyMinutes;

  /// Opens across the week. On iOS this is approximated from shield events.
  final int opens;

  final List<DaypartUsage> dayparts;

  /// The per-app split. Available on Android only.
  final List<AppUsage> perApp;

  int get totalMinutes => dailyMinutes.fold(0, (sum, value) => sum + value);

  int get averageMinutes =>
      dailyMinutes.isEmpty ? 0 : (totalMinutes / dailyMinutes.length).round();

  int get peakMinutes =>
      dailyMinutes.isEmpty ? 0 : dailyMinutes.reduce((a, b) => a > b ? a : b);

  int get peakDaypartMinutes => dayparts.isEmpty
      ? 0
      : dayparts.map((part) => part.minutes).reduce((a, b) => a > b ? a : b);
}

/// The sample week rendered on screen E. See the library note above.
const sampleObserveWeek = ObserveWeek(
  dailyMinutes: [188, 214, 176, 241, 268, 305, 259],
  opens: 412,
  dayparts: [
    DaypartUsage('Early morning', 62),
    DaypartUsage('Morning', 194),
    DaypartUsage('Afternoon', 331),
    DaypartUsage('Evening', 588),
    DaypartUsage('Late night', 476),
  ],
  perApp: [
    AppUsage('Short-form video', 604, 168),
    AppUsage('Social feed', 431, 121),
    AppUsage('Messaging', 288, 96),
    AppUsage('News', 182, 27),
  ],
);

/// The day labels used alongside [ObserveWeek.dailyMinutes].
const weekdayLabels = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Formats a whole number of minutes as `4h 28m`, or `48m` under an hour.
String formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${rest}m';
  return '${hours}h ${rest}m';
}
