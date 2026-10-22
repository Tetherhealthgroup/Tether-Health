import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../theme/app_colors.dart';
import '../widgets/large_text.dart';
import 'choose_quit_path_screen.dart';

DateTime _addCalendarDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

int _calendarDayDifference(DateTime later, DateTime earlier) {
  final laterUtc = DateTime.utc(later.year, later.month, later.day);
  final earlierUtc = DateTime.utc(earlier.year, earlier.month, earlier.day);
  return laterUtc.difference(earlierUtc).inDays;
}

/// What the selected-date card says when the saved date is outside the days
/// the quit path allows (for example, a plan reopened after its quit date
/// passed). Draft copy, pending clinical and legal review.
abstract final class QuitDateCopy {
  static const String unavailableEnglish =
      'This date is no longer available. Choose a new date.';
  static const String unavailableSpanish =
      'Esta fecha ya no está disponible. Elige una nueva fecha.';
}

const _monthKeys = <String>[
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

const _weekdayKeys = <String>[
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// The full name of [month] (1–12) in the app language.
String quitDateMonthName(AppLocalizations l10n, int month) =>
    l10n.selectQuitDateMonthName(_monthKeys[month - 1]);

/// The short name of [month] (1–12) in the app language.
String quitDateShortMonth(AppLocalizations l10n, int month) =>
    l10n.selectQuitDateMonthShort(_monthKeys[month - 1]);

/// The name of [weekday] (DateTime.monday–DateTime.sunday).
String quitDateWeekdayName(AppLocalizations l10n, int weekday) =>
    l10n.selectQuitDateWeekdayName(_weekdayKeys[weekday - 1]);

/// [date] as weekday, day, month and year in the app language.
String quitDateLongDate(AppLocalizations l10n, DateTime date) =>
    l10n.selectQuitDateLongDate(
      quitDateWeekdayName(l10n, date.weekday),
      quitDateMonthName(l10n, date.month),
      date.day,
      date.year,
    );

/// The calendar's weekday initials, Sunday first.
List<String> quitDateWeekdayInitials(AppLocalizations l10n) => [
      for (final weekday in const [
        'sunday',
        ..._weekdayKeys,
      ].take(7))
        l10n.selectQuitDateWeekdayInitial(weekday),
    ];

class SelectQuitDateScreen extends StatefulWidget {
  const SelectQuitDateScreen({
    required this.isSpanish,
    required this.quitPath,
    required this.selectedDate,
    required this.quitDayCheckIn,
    required this.onDateChanged,
    required this.onQuitDayCheckInChanged,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  final bool isSpanish;
  final QuitPlanPath quitPath;
  final DateTime? selectedDate;
  final bool quitDayCheckIn;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<bool> onQuitDayCheckInChanged;
  final VoidCallback onBack;
  final ValueChanged<DateTime> onContinue;

  @override
  State<SelectQuitDateScreen> createState() => _SelectQuitDateScreenState();
}

class _SelectQuitDateScreenState extends State<SelectQuitDateScreen> {
  late DateTime _visibleMonth;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  DateTime get _defaultDate => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate => _addCalendarDays(_today, 7),
        QuitPlanPath.quitToday => _today,
        QuitPlanPath.reduceGradually => _addCalendarDays(_today, 14),
      };

  DateTime get _effectiveDate =>
      DateUtils.dateOnly(widget.selectedDate ?? _defaultDate);

  DateTime get _minimumDate => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate => _addCalendarDays(_today, 1),
        QuitPlanPath.quitToday => _today,
        QuitPlanPath.reduceGradually => _addCalendarDays(_today, 7),
      };

  DateTime get _maximumDate => switch (widget.quitPath) {
        QuitPlanPath.quitToday => _today,
        _ => _addCalendarDays(_today, 90),
      };

  DateTime get _recommendedStart => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate => _addCalendarDays(_today, 7),
        QuitPlanPath.quitToday => _today,
        QuitPlanPath.reduceGradually => _addCalendarDays(_today, 14),
      };

  DateTime get _recommendedEnd => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate => _addCalendarDays(_today, 14),
        QuitPlanPath.quitToday => _today,
        QuitPlanPath.reduceGradually => _addCalendarDays(_today, 30),
      };

  /// Whether the date on screen can be kept. A saved date outside the quit
  /// path's window stays saved, but must be replaced before Confirm.
  bool get _dateAvailable => _isSelectable(_effectiveDate);

  String get _unavailableMessage =>
      AppLocalizations.of(context).selectQuitDateUnavailableMessage;

  DateTime get _firstAllowedMonth =>
      DateTime(_minimumDate.year, _minimumDate.month);

  DateTime get _lastAllowedMonth =>
      DateTime(_maximumDate.year, _maximumDate.month);

  /// [month] moved into the months that contain an allowed day.
  DateTime _clampToAllowedMonths(DateTime month) {
    if (month.isBefore(_firstAllowedMonth)) return _firstAllowedMonth;
    if (month.isAfter(_lastAllowedMonth)) return _lastAllowedMonth;
    return month;
  }

  /// The month of the date on screen, or the first allowed month when that
  /// date is outside the window.
  DateTime get _openingMonth {
    if (!_dateAvailable) return _firstAllowedMonth;
    final date = _effectiveDate;
    return DateTime(date.year, date.month);
  }

  /// The month shown, always one with an allowed day.
  DateTime get _shownMonth => _clampToAllowedMonths(_visibleMonth);

  @override
  void initState() {
    super.initState();
    _visibleMonth = _openingMonth;
  }

  @override
  void didUpdateWidget(covariant SelectQuitDateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quitPath != widget.quitPath) {
      _visibleMonth = _openingMonth;
    }
  }

  bool _isSelectable(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return !day.isBefore(_minimumDate) && !day.isAfter(_maximumDate);
  }

  bool _isRecommended(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return !day.isBefore(_recommendedStart) && !day.isAfter(_recommendedEnd);
  }

  void _changeMonth(int amount) {
    final shown = _shownMonth;
    final candidate = _clampToAllowedMonths(
      DateTime(shown.year, shown.month + amount),
    );
    if (candidate == shown) return;
    setState(() => _visibleMonth = candidate);
  }

  String get _headerTitle => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate =>
          AppLocalizations.of(context).selectQuitDateHeaderTitle,
        QuitPlanPath.quitToday =>
          AppLocalizations.of(context).selectQuitDateHeaderTitle2,
        QuitPlanPath.reduceGradually =>
          AppLocalizations.of(context).selectQuitDateHeaderTitle3,
      };

  String get _title => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate =>
          AppLocalizations.of(context).selectQuitDateTitle,
        QuitPlanPath.quitToday =>
          AppLocalizations.of(context).selectQuitDateTitle2,
        QuitPlanPath.reduceGradually =>
          AppLocalizations.of(context).selectQuitDateTitle3,
      };

  String get _description => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate =>
          AppLocalizations.of(context).selectQuitDateDescription,
        QuitPlanPath.quitToday =>
          AppLocalizations.of(context).selectQuitDateDescription2,
        QuitPlanPath.reduceGradually =>
          AppLocalizations.of(context).selectQuitDateDescription3,
      };

  String get _windowMessage {
    if (widget.quitPath == QuitPlanPath.quitToday) {
      return AppLocalizations.of(context).selectQuitDateWindowMessage;
    }
    final range = _formatShortRange(_recommendedStart, _recommendedEnd);
    return switch (widget.quitPath) {
      QuitPlanPath.setQuitDate =>
        AppLocalizations.of(context).selectQuitDateWindowMessage2(range),
      QuitPlanPath.reduceGradually =>
        AppLocalizations.of(context).selectQuitDateWindowMessage3(range),
      QuitPlanPath.quitToday => '',
    };
  }

  String get _dateLabel => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate =>
          AppLocalizations.of(context).selectQuitDateDateLabel,
        QuitPlanPath.quitToday =>
          AppLocalizations.of(context).selectQuitDateDateLabel2,
        QuitPlanPath.reduceGradually =>
          AppLocalizations.of(context).selectQuitDateDateLabel3,
      };

  String get _timingLabel {
    final days = _calendarDayDifference(_effectiveDate, _today);
    if (days == 0) {
      return AppLocalizations.of(context).selectQuitDateTimingLabel;
    }
    return switch (widget.quitPath) {
      QuitPlanPath.reduceGradually =>
        AppLocalizations.of(context).selectQuitDateTimingLabel2(days),
      _ => AppLocalizations.of(context).selectQuitDateTimingLabel3(days),
    };
  }

  String get _continueLabel => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate =>
          AppLocalizations.of(context).selectQuitDateContinueLabel,
        QuitPlanPath.quitToday =>
          AppLocalizations.of(context).selectQuitDateContinueLabel2,
        QuitPlanPath.reduceGradually =>
          AppLocalizations.of(context).selectQuitDateContinueLabel3,
      };

  String _formatShortRange(DateTime start, DateTime end) {
    final startMonth = _shortMonth(start.month);
    final endMonth = _shortMonth(end.month);
    if (start.year == end.year && start.month == end.month) {
      return AppLocalizations.of(context)
          .selectQuitDateRangeSameMonth(startMonth, start.day, end.day);
    }
    return AppLocalizations.of(context)
        .selectQuitDateRange(startMonth, start.day, endMonth, end.day);
  }

  String _shortMonth(int month) =>
      quitDateShortMonth(AppLocalizations.of(context), month);

  String _monthName(int month) =>
      quitDateMonthName(AppLocalizations.of(context), month);

  String _weekdayName(int weekday) =>
      quitDateWeekdayName(AppLocalizations.of(context), weekday);

  String _longDate(DateTime date) =>
      quitDateLongDate(AppLocalizations.of(context), date);

  @override
  Widget build(BuildContext context) {
    // The text comes from the app locale; the language the screen was given
    // must be the same one.
    assert(
      widget.isSpanish ==
          (Localizations.localeOf(context).languageCode == 'es'),
      'the screen language must match the app locale',
    );
    return Scaffold(
      key: const ValueKey('functional-select-quit-date-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 250) widget.onBack();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 380;
              final compact = constraints.maxHeight < 760;
              // Above 140% text the side margins narrow so long words fit, and
              // the header, progress and main action scroll with the content
              // so they never squeeze the questions out of view.
              final largeText = usesLargeTextLayout(context);
              final horizontalPadding =
                  largeText ? 12.0 : (narrow ? 18.0 : 22.0);

              final dateAvailable = _dateAvailable;
              final shownMonth = _shownMonth;
              final footer = _DateBottomAction(
                isSpanish: widget.isSpanish,
                label: _continueLabel,
                // Until a day in the window is chosen, Confirm stays
                // disabled and the saved date is left as it is.
                blockedReason: dateAvailable ? null : _unavailableMessage,
                onContinue: () {
                  final date = _effectiveDate;
                  if (_isSelectable(date)) widget.onContinue(date);
                },
                horizontalPadding: largeText ? 0 : horizontalPadding,
                compact: compact,
              );

              final header = _DateHeader(
                isSpanish: widget.isSpanish,
                title: _headerTitle,
                onBack: widget.onBack,
              );
              final progress = _DateProgress(isSpanish: widget.isSpanish);

              return Column(
                children: [
                  if (!largeText)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 5 : 9,
                        horizontalPadding,
                        0,
                      ),
                      child: header,
                    ),
                  if (!largeText)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 5 : 8,
                        horizontalPadding,
                        compact ? 7 : 10,
                      ),
                      child: progress,
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('quit-date-content-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 8 : 13,
                        horizontalPadding,
                        18,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (largeText) ...[
                                header,
                                const SizedBox(height: 10),
                                progress,
                                const SizedBox(height: 18),
                              ],
                              Text(
                                AppLocalizations.of(context).selectQuitDateText,
                                style: const TextStyle(
                                  color: AppColors.mutedTeal,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _title,
                                // Already the largest text on screen; past
                                // 180% its longest words no longer fit.
                                textScaler: MediaQuery.textScalerOf(context)
                                    .clamp(maxScaleFactor: 1.8),
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: narrow ? 29 : 33,
                                      height: 1.06,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.tealSecondary,
                                      fontSize: narrow ? 14 : 15,
                                      height: 1.35,
                                    ),
                              ),
                              SizedBox(height: compact ? 14 : 18),
                              _QuitCalendar(
                                isSpanish: widget.isSpanish,
                                visibleMonth: shownMonth,
                                // A saved day outside the window is not
                                // shown as chosen in the calendar.
                                selectedDate:
                                    dateAvailable ? _effectiveDate : null,
                                today: _today,
                                windowMessage: _windowMessage,
                                isSelectable: _isSelectable,
                                // Only days in the quit path's window can
                                // be chosen, whichever layout is shown.
                                onDateSelected: (date) {
                                  if (_isSelectable(date)) {
                                    widget.onDateChanged(date);
                                  }
                                },
                                // Each arrow is enabled only while a month
                                // with an allowed day lies that way.
                                canGoBack:
                                    shownMonth.isAfter(_firstAllowedMonth),
                                canGoForward:
                                    shownMonth.isBefore(_lastAllowedMonth),
                                onPreviousMonth: () => _changeMonth(-1),
                                onNextMonth: () => _changeMonth(1),
                                monthLabel: AppLocalizations.of(context)
                                    .selectQuitDateMonthYear(
                                        _monthName(shownMonth.month),
                                        shownMonth.year),
                                weekdayName: _weekdayName,
                              ),
                              const SizedBox(height: 12),
                              _SelectedDateCard(
                                isSpanish: widget.isSpanish,
                                date: _effectiveDate,
                                label: _dateLabel,
                                longDate: _longDate(_effectiveDate),
                                timingLabel: _timingLabel,
                                unavailableMessage:
                                    dateAvailable ? null : _unavailableMessage,
                                recommended: dateAvailable &&
                                    _isRecommended(_effectiveDate),
                                monthLabel: _shortMonth(_effectiveDate.month),
                                weekdayLabel:
                                    _weekdayName(_effectiveDate.weekday),
                              ),
                              const SizedBox(height: 12),
                              _CheckInCard(
                                isSpanish: widget.isSpanish,
                                enabled: widget.quitDayCheckIn,
                                onChanged: widget.onQuitDayCheckInChanged,
                              ),
                              const SizedBox(height: 13),
                              _FlexibleDateNote(isSpanish: widget.isSpanish),
                              if (largeText) ...[
                                const SizedBox(height: 18),
                                footer,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!largeText) footer,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.isSpanish,
    required this.title,
    required this.onBack,
  });

  final bool isSpanish;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final back = IconButton.outlined(
      key: const ValueKey('quit-date-back'),
      tooltip: AppLocalizations.of(context).selectQuitDateDateHeaderBackTooltip,
      onPressed: onBack,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.deepTeal,
        side: const BorderSide(color: AppColors.border),
      ),
      icon: const Icon(Icons.arrow_back_rounded),
    );
    const style = TextStyle(
      color: AppColors.deepTeal,
      fontSize: 15,
      fontWeight: FontWeight.w800,
    );
    // The title wraps instead of ending in "…"; a word too long for the
    // line scales down instead of splitting.
    final heading = LayoutBuilder(
      builder: (context, constraints) => Text(
        title,
        textAlign: TextAlign.center,
        textScaler: wordFitScaler(
          context,
          title,
          style,
          constraints.maxWidth,
        ),
        style: style,
      ),
    );
    final step = Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context).selectQuitDateDateHeaderText,
        style: const TextStyle(
          color: AppColors.tealSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    // Between the back button and the step, the title's words split at
    // accessibility text sizes, so it takes a line of its own.
    if (usesLargeTextLayout(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [back, step],
            ),
          ),
          const SizedBox(height: 6),
          heading,
        ],
      );
    }
    // A minimum height: larger text grows the header instead of clipping it.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          back,
          const SizedBox(width: 8),
          Expanded(child: heading),
          const SizedBox(width: 8),
          step,
        ],
      ),
    );
  }
}

class _DateProgress extends StatelessWidget {
  const _DateProgress({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                AppLocalizations.of(context).selectQuitDateDateProgressText,
                style: const TextStyle(
                  color: AppColors.mutedTeal,
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '40%',
              style: TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            key: ValueKey('quit-date-progress'),
            value: 0.4,
            minHeight: 6,
            backgroundColor: Color(0xFFDCE7E1),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
      ],
    );
  }
}

class _QuitCalendar extends StatelessWidget {
  const _QuitCalendar({
    required this.isSpanish,
    required this.visibleMonth,
    required this.selectedDate,
    required this.today,
    required this.windowMessage,
    required this.isSelectable,
    required this.onDateSelected,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.monthLabel,
    required this.weekdayName,
  });

  final bool isSpanish;
  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final DateTime today;
  final String windowMessage;
  final bool Function(DateTime) isSelectable;
  final ValueChanged<DateTime> onDateSelected;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final String monthLabel;
  final String Function(int weekday) weekdayName;

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'quit-date-day-${date.year}-$month-$day';
  }

  /// One selectable day in the list shown at accessibility text sizes.
  Widget _dayRow(DateTime date) {
    final selected = DateUtils.isSameDay(date, selectedDate);
    final isToday = DateUtils.isSameDay(date, today);
    final color = selected ? Colors.white : AppColors.deepTeal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        selected: selected,
        enabled: isSelectable(date),
        label: '${date.month}/${date.day}/${date.year}',
        child: Material(
          color: selected ? AppColors.coral : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: !selected && isToday
                ? const BorderSide(color: AppColors.deepTeal, width: 1.3)
                : BorderSide.none,
          ),
          child: InkWell(
            key: ValueKey(_dateKey(date)),
            onTap: () => onDateSelected(date),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              key: selected ? const ValueKey('quit-date-selected') : null,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weekdayName(date.weekday),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: selected || isToday
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final leading = first.weekday % 7;
    final firstCell = first.subtract(Duration(days: leading));
    final weekdays = quitDateWeekdayInitials(AppLocalizations.of(context));
    final largeText = usesLargeTextLayout(context);
    final previous = IconButton.filledTonal(
      key: const ValueKey('quit-date-previous-month'),
      onPressed: canGoBack ? onPreviousMonth : null,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.mint.withValues(alpha: 0.65),
        foregroundColor: AppColors.deepTeal,
      ),
      icon: const Icon(Icons.chevron_left_rounded),
    );
    final next = IconButton.filledTonal(
      key: const ValueKey('quit-date-next-month'),
      onPressed: canGoForward ? onNextMonth : null,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.mint.withValues(alpha: 0.65),
        foregroundColor: AppColors.deepTeal,
      ),
      icon: const Icon(Icons.chevron_right_rounded),
    );
    const monthStyle = TextStyle(
      color: AppColors.deepTeal,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    );
    // A word too long for the line scales down instead of splitting.
    final month = LayoutBuilder(
      builder: (context, constraints) => Text(
        monthLabel,
        textAlign: TextAlign.center,
        textScaler: wordFitScaler(
          context,
          monthLabel,
          monthStyle,
          constraints.maxWidth,
        ),
        style: monthStyle,
      ),
    );

    return Container(
      key: const ValueKey('quit-date-calendar'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // At accessibility text sizes the month takes a line of its own
          // and the days are listed instead of drawn as a grid, so day
          // numbers keep their full size.
          if (largeText) ...[
            Row(children: [previous, const Spacer(), next]),
            const SizedBox(height: 6),
            month,
            const SizedBox(height: 10),
            for (var day = 1;
                day <= DateUtils.getDaysInMonth(first.year, first.month);
                day++)
              if (isSelectable(DateTime(first.year, first.month, day)))
                _dayRow(DateTime(first.year, first.month, day)),
          ] else ...[
            Row(
              children: [
                previous,
                Expanded(child: month),
                next,
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                for (final day in weekdays)
                  Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.mutedTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0x334A6B65)),
            const SizedBox(height: 5),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.05,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                // Calendar dates must advance by date components. Adding
                // 24-hour durations can duplicate or skip a date at daylight
                // saving time boundaries.
                final date = DateTime(
                  firstCell.year,
                  firstCell.month,
                  firstCell.day + index,
                );
                final inMonth = date.month == visibleMonth.month;
                final selectable = inMonth && isSelectable(date);
                final selected =
                    inMonth && DateUtils.isSameDay(date, selectedDate);
                final isToday = DateUtils.isSameDay(date, today);

                return Center(
                  child: Semantics(
                    selected: selected,
                    enabled: selectable,
                    label: '${date.month}/${date.day}/${date.year}',
                    child: InkWell(
                      key: inMonth ? ValueKey(_dateKey(date)) : null,
                      onTap: selectable ? () => onDateSelected(date) : null,
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        key: selected
                            ? const ValueKey('quit-date-selected')
                            : null,
                        duration: const Duration(milliseconds: 140),
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.coral : Colors.transparent,
                          shape: BoxShape.circle,
                          border: !selected && isToday
                              ? Border.all(
                                  color: AppColors.deepTeal,
                                  width: 1.3,
                                )
                              : null,
                        ),
                        child: Text(
                          inMonth ? '${date.day}' : '',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : selectable
                                    ? AppColors.deepTeal
                                    : AppColors.border,
                            fontSize: 12,
                            fontWeight: selected || isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          const Divider(height: 13, color: Color(0x334A6B65)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.deepTeal,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    windowMessage,
                    style: const TextStyle(
                      color: AppColors.deepTeal,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDateCard extends StatelessWidget {
  const _SelectedDateCard({
    required this.isSpanish,
    required this.date,
    required this.label,
    required this.longDate,
    required this.timingLabel,
    required this.unavailableMessage,
    required this.recommended,
    required this.monthLabel,
    required this.weekdayLabel,
  });

  final bool isSpanish;
  final DateTime date;
  final String label;
  final String longDate;
  final String timingLabel;

  /// Set when [date] is a saved date the quit path no longer allows.
  final String? unavailableMessage;
  final bool recommended;
  final String monthLabel;
  final String weekdayLabel;

  @override
  Widget build(BuildContext context) {
    final largeText = usesLargeTextLayout(context);
    final tileContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: AppColors.coral,
          child: Text(
            monthLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${date.day}',
          style: const TextStyle(
            color: AppColors.deepTeal,
            fontSize: 24,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            weekdayLabel.substring(0, 3).toUpperCase(),
            style: const TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
    // At accessibility text sizes the date tile grows with its text
    // instead of clipping the day number.
    final tile = Container(
      width: largeText ? null : 58,
      constraints: const BoxConstraints(minWidth: 58),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: largeText ? IntrinsicWidth(child: tileContent) : tileContent,
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedTeal,
            fontSize: 9,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          longDate,
          style: TextStyle(
            color: AppColors.deepTeal,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            decoration:
                unavailableMessage == null ? null : TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(height: 2),
        if (unavailableMessage case final message?)
          Text(
            message,
            key: const ValueKey('quit-date-unavailable'),
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          )
        else
          Text(
            timingLabel,
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 11,
            ),
          ),
      ],
    );
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.deepTeal,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        AppLocalizations.of(context)
            .selectQuitDateSelectedDateCardUnavailableText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7.5,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final narrowPhone = MediaQuery.sizeOf(context).width < 360;
    final stacked = largeText ||
        (narrowPhone && MediaQuery.textScalerOf(context).scale(10) > 10);
    return Container(
      key: const ValueKey('quit-date-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mintStrong),
      ),
      // At accessibility text sizes, and on the narrowest phones once text
      // is enlarged, the date details take the card's full width under the
      // tile and badge.
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 8,
                    children: [tile, if (recommended) badge],
                  ),
                ),
                const SizedBox(height: 10),
                text,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                tile,
                const SizedBox(width: 12),
                Expanded(child: text),
                if (recommended) badge,
              ],
            ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.isSpanish,
    required this.enabled,
    required this.onChanged,
  });

  final bool isSpanish;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final largeText = usesLargeTextLayout(context);
    const icon = CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.coralLight,
      child: Icon(
        Icons.schedule_rounded,
        color: AppColors.coral,
        size: 22,
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).selectQuitDateCheckInCardText,
          style: const TextStyle(
            color: AppColors.deepTeal,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          AppLocalizations.of(context).selectQuitDateCheckInCardText2,
          style: const TextStyle(
            color: AppColors.tealSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
    final toggle = Switch(
      key: const ValueKey('quit-date-check-in'),
      value: enabled,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.deepTeal,
      onChanged: onChanged,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment:
            largeText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // At accessibility text sizes the text takes the card's full width
          // and the switch moves to the row above it.
          if (largeText) ...[
            Row(children: [icon, const Spacer(), toggle]),
            const SizedBox(height: 8),
            text,
          ] else
            Row(
              children: [
                icon,
                const SizedBox(width: 10),
                Expanded(child: text),
                toggle,
              ],
            ),
          const Divider(height: 15, color: Color(0x334A6B65)),
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.mutedTeal,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).selectQuitDateCheckInCardText3,
                  style: const TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlexibleDateNote extends StatelessWidget {
  const _FlexibleDateNote({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.mint,
          child: Icon(Icons.check_rounded, color: AppColors.deepTeal, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppLocalizations.of(context).selectQuitDateFlexibleDateNoteText,
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateBottomAction extends StatelessWidget {
  const _DateBottomAction({
    required this.isSpanish,
    required this.label,
    required this.blockedReason,
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
  final String label;

  /// Why Confirm is disabled, or null when it can be used.
  final String? blockedReason;
  final VoidCallback onContinue;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final blocked = blockedReason != null;
    Widget button = FilledButton(
      key: const ValueKey('quit-date-confirm'),
      onPressed: blocked ? null : onContinue,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.deepTeal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.tealSecondary,
        // A minimum, not a fixed height: large text wraps and
        // grows the button instead of being clipped.
        minimumSize: Size.fromHeight(compact ? 54 : 58),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.arrow_forward_rounded,
            color: blocked ? AppColors.mutedTeal : AppColors.lime,
          ),
        ],
      ),
    );
    // Screen readers hear why the disabled button cannot be used.
    if (blockedReason case final reason?) {
      button = MergeSemantics(
        child: Semantics(hint: reason, child: button),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Color(0x1A123C37))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 8 : 10,
          horizontalPadding,
          compact ? 8 : 10,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                button,
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)
                        .selectQuitDateDateBottomActionText,
                    style: const TextStyle(
                      color: AppColors.mutedTeal,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
