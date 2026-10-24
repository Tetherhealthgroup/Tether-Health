import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'choose_quit_path_screen.dart';

DateTime _addCalendarDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

int _calendarDayDifference(DateTime later, DateTime earlier) {
  final laterUtc = DateTime.utc(later.year, later.month, later.day);
  final earlierUtc = DateTime.utc(earlier.year, earlier.month, earlier.day);
  return laterUtc.difference(earlierUtc).inDays;
}

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

  @override
  void initState() {
    super.initState();
    final date = _effectiveDate;
    _visibleMonth = DateTime(date.year, date.month);
  }

  @override
  void didUpdateWidget(covariant SelectQuitDateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quitPath != widget.quitPath) {
      final date = _effectiveDate;
      _visibleMonth = DateTime(date.year, date.month);
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
    final candidate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + amount,
    );
    final firstAllowed = DateTime(_minimumDate.year, _minimumDate.month);
    final lastAllowed = DateTime(_maximumDate.year, _maximumDate.month);
    if (candidate.isBefore(firstAllowed) || candidate.isAfter(lastAllowed)) {
      return;
    }
    setState(() => _visibleMonth = candidate);
  }

  String get _headerTitle => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate => widget.isSpanish
            ? 'Elige tu fecha para dejarlo'
            : 'Choose your quit date',
        QuitPlanPath.quitToday =>
          widget.isSpanish ? 'Empieza hoy' : 'Start your quit today',
        QuitPlanPath.reduceGradually => widget.isSpanish
            ? 'Elige tu fecha objetivo'
            : 'Choose your target date',
      };

  String get _title => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate => widget.isSpanish
            ? 'Elige un día para comenzar.'
            : 'Choose a day to begin.',
        QuitPlanPath.quitToday => widget.isSpanish
            ? 'Hoy es tu punto de partida.'
            : 'Today is your starting point.',
        QuitPlanPath.reduceGradually => widget.isSpanish
            ? 'Elige el día para dejarlo por completo.'
            : 'Choose the day to become smoke-free.',
      };

  String get _description => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate => widget.isSpanish
            ? 'Una fecha dentro de 7–14 días te da tiempo para prepararte sin perder el impulso.'
            : 'A date 7–14 days away gives you time to prepare without losing momentum.',
        QuitPlanPath.quitToday => widget.isSpanish
            ? 'Tu tiempo sin fumar comienza hoy. Te daremos apoyo adicional durante el primer día.'
            : 'Your smoke-free time begins today. We’ll add extra support through your first day.',
        QuitPlanPath.reduceGradually => widget.isSpanish
            ? 'Una fecha dentro de 14–30 días te da tiempo para reducir gradualmente con un objetivo claro.'
            : 'A target 14–30 days away gives you time to reduce gradually with a clear goal.',
      };

  String get _windowMessage {
    if (widget.quitPath == QuitPlanPath.quitToday) {
      return widget.isSpanish
          ? 'Hoy está seleccionado según tu camino'
          : 'Today is selected based on your path';
    }
    final range = _formatShortRange(_recommendedStart, _recommendedEnd);
    return switch (widget.quitPath) {
      QuitPlanPath.setQuitDate => widget.isSpanish
          ? 'Ventana de preparación recomendada: $range'
          : 'Recommended preparation window: $range',
      QuitPlanPath.reduceGradually => widget.isSpanish
          ? 'Ventana de reducción recomendada: $range'
          : 'Recommended reduction window: $range',
      QuitPlanPath.quitToday => '',
    };
  }

  String get _dateLabel => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate =>
          widget.isSpanish ? 'TU FECHA PARA DEJARLO' : 'YOUR QUIT DATE',
        QuitPlanPath.quitToday =>
          widget.isSpanish ? 'TU FECHA ES HOY' : 'YOUR QUIT DATE IS TODAY',
        QuitPlanPath.reduceGradually =>
          widget.isSpanish ? 'TU FECHA OBJETIVO' : 'YOUR TARGET DATE',
      };

  String get _timingLabel {
    final days = _calendarDayDifference(_effectiveDate, _today);
    if (days == 0) {
      return widget.isSpanish ? 'Comienza hoy' : 'Starting today';
    }
    return switch (widget.quitPath) {
      QuitPlanPath.reduceGradually => widget.isSpanish
          ? '$days días para reducir gradualmente'
          : '$days days to reduce gradually',
      _ => widget.isSpanish
          ? '$days días para prepararte'
          : '$days days to prepare',
    };
  }

  String get _continueLabel => switch (widget.quitPath) {
        QuitPlanPath.setQuitDate =>
          widget.isSpanish ? 'Confirmar esta fecha' : 'Confirm this date',
        QuitPlanPath.quitToday =>
          widget.isSpanish ? 'Comenzar hoy' : 'Start my quit today',
        QuitPlanPath.reduceGradually =>
          widget.isSpanish ? 'Confirmar fecha objetivo' : 'Confirm target date',
      };

  String _formatShortRange(DateTime start, DateTime end) {
    final startMonth = _shortMonth(start.month);
    final endMonth = _shortMonth(end.month);
    if (start.year == end.year && start.month == end.month) {
      return '$startMonth ${start.day}–${end.day}';
    }
    return '$startMonth ${start.day} – $endMonth ${end.day}';
  }

  String _shortMonth(int month) {
    const english = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const spanish = <String>[
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return (widget.isSpanish ? spanish : english)[month - 1];
  }

  String _monthName(int month) {
    const english = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const spanish = <String>[
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return (widget.isSpanish ? spanish : english)[month - 1];
  }

  String _weekdayName(int weekday) {
    const english = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const spanish = <String>[
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return (widget.isSpanish ? spanish : english)[weekday - 1];
  }

  String _longDate(DateTime date) {
    if (widget.isSpanish) {
      return '${_weekdayName(date.weekday)}, ${date.day} de ${_monthName(date.month)} de ${date.year}';
    }
    return '${_weekdayName(date.weekday)}, ${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
              final horizontalPadding = narrow ? 18.0 : 22.0;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 5 : 9,
                      horizontalPadding,
                      0,
                    ),
                    child: _DateHeader(
                      isSpanish: widget.isSpanish,
                      title: _headerTitle,
                      onBack: widget.onBack,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 5 : 8,
                      horizontalPadding,
                      compact ? 7 : 10,
                    ),
                    child: _DateProgress(isSpanish: widget.isSpanish),
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
                              Text(
                                widget.isSpanish ? 'TU FECHA' : 'YOUR DATE',
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
                                visibleMonth: _visibleMonth,
                                selectedDate: _effectiveDate,
                                today: _today,
                                minimumDate: _minimumDate,
                                maximumDate: _maximumDate,
                                windowMessage: _windowMessage,
                                isSelectable: _isSelectable,
                                onDateSelected: widget.onDateChanged,
                                onPreviousMonth: () => _changeMonth(-1),
                                onNextMonth: () => _changeMonth(1),
                                monthLabel:
                                    '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
                              ),
                              const SizedBox(height: 12),
                              _SelectedDateCard(
                                isSpanish: widget.isSpanish,
                                date: _effectiveDate,
                                label: _dateLabel,
                                longDate: _longDate(_effectiveDate),
                                timingLabel: _timingLabel,
                                recommended: _isRecommended(_effectiveDate),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _DateBottomAction(
                    isSpanish: widget.isSpanish,
                    label: _continueLabel,
                    onContinue: () => widget.onContinue(_effectiveDate),
                    horizontalPadding: horizontalPadding,
                    compact: compact,
                  ),
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
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton.outlined(
            key: const ValueKey('quit-date-back'),
            tooltip: isSpanish ? 'Atrás' : 'Back',
            onPressed: onBack,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.deepTeal,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              isSpanish ? '2 DE 5' : '2 OF 5',
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
          children: [
            Text(
              isSpanish ? 'PLAN PARA DEJARLO' : 'QUIT PLAN',
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
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
    required this.minimumDate,
    required this.maximumDate,
    required this.windowMessage,
    required this.isSelectable,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.monthLabel,
  });

  final bool isSpanish;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime today;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final String windowMessage;
  final bool Function(DateTime) isSelectable;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final String monthLabel;

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'quit-date-day-${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final leading = first.weekday % 7;
    final firstCell = first.subtract(Duration(days: leading));
    final canGoBack = DateTime(visibleMonth.year, visibleMonth.month)
        .isAfter(DateTime(minimumDate.year, minimumDate.month));
    final canGoForward = DateTime(visibleMonth.year, visibleMonth.month)
        .isBefore(DateTime(maximumDate.year, maximumDate.month));
    final weekdays = isSpanish
        ? const ['D', 'L', 'M', 'M', 'J', 'V', 'S']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

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
          Row(
            children: [
              IconButton.filledTonal(
                key: const ValueKey('quit-date-previous-month'),
                onPressed: canGoBack ? onPreviousMonth : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.mint.withValues(alpha: 0.65),
                  foregroundColor: AppColors.deepTeal,
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey('quit-date-next-month'),
                onPressed: canGoForward ? onNextMonth : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.mint.withValues(alpha: 0.65),
                  foregroundColor: AppColors.deepTeal,
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
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
                        color: selected ? AppColors.coral : Colors.transparent,
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
    required this.recommended,
    required this.monthLabel,
    required this.weekdayLabel,
  });

  final bool isSpanish;
  final DateTime date;
  final String label;
  final String longDate;
  final String timingLabel;
  final bool recommended;
  final String monthLabel;
  final String weekdayLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('quit-date-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mintStrong),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
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
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                  style: const TextStyle(
                    color: AppColors.deepTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timingLabel,
                  style: const TextStyle(
                    color: AppColors.tealSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.deepTeal,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                isSpanish ? 'RECOMENDADO' : 'RECOMMENDED',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.coralLight,
                child: Icon(
                  Icons.schedule_rounded,
                  color: AppColors.coral,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish
                          ? 'Registro del día de dejarlo'
                          : 'Quit-day check-in',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isSpanish
                          ? '7:00 a. m. · Notificación privada'
                          : '7:00 AM · Private notification',
                      style: const TextStyle(
                        color: AppColors.tealSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const ValueKey('quit-date-check-in'),
                value: enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.deepTeal,
                onChanged: onChanged,
              ),
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
                  isSpanish
                      ? 'La pantalla bloqueada solo muestra: “Tienes un registro”.'
                      : 'Lock screen only shows: “You have a check-in.”',
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
            isSpanish
                ? 'Puedes cambiar esta fecha después sin perder tu progreso.'
                : 'You can change this date later without losing progress.',
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
    required this.onContinue,
    required this.horizontalPadding,
    required this.compact,
  });

  final bool isSpanish;
  final String label;
  final VoidCallback onContinue;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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
                SizedBox(
                  width: double.infinity,
                  height: compact ? 54 : 58,
                  child: FilledButton(
                    key: const ValueKey('quit-date-confirm'),
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.lime,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text(
                    isSpanish
                        ? 'Fecha guardada automáticamente'
                        : 'Date saved automatically',
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
