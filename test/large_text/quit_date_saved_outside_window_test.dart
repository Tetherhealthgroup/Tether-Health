import 'dart:ui' show Tristate;

import 'package:breathefree_patient/screens/choose_quit_path_screen.dart';
import 'package:breathefree_patient/screens/select_quit_date_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'large_text_harness.dart';

/// A saved quit date can fall outside the days the quit path allows, for
/// example when a plan is reopened after its quit date passed. The calendar
/// must then open on the first allowed month, its month arrows must always
/// reach an allowed month, the selected-date card must say the saved date is
/// no longer available, and Confirm must stay disabled until a day in the
/// window is chosen. The saved date is never replaced without a choice.
const _device = Size(375, 667);

final _layouts = <String, TextScaler>{
  'grid at default size': TextScaler.noScaling,
  'list at 200%': const TextScaler.linear(2.0),
};

DateTime get _today => DateUtils.dateOnly(DateTime.now());

DateTime _plusDays(int days) =>
    DateTime(_today.year, _today.month, _today.day + days);

/// The first and last day each quit path lets the user choose.
(DateTime, DateTime) _window(QuitPlanPath path) => switch (path) {
      QuitPlanPath.setQuitDate => (_plusDays(1), _plusDays(90)),
      QuitPlanPath.quitToday => (_today, _today),
      QuitPlanPath.reduceGradually => (_plusDays(7), _plusDays(90)),
    };

bool _inWindow(QuitPlanPath path, DateTime date) {
  final (first, last) = _window(path);
  return !date.isBefore(first) && !date.isAfter(last);
}

/// A saved date inside the window, for the unchanged case.
DateTime _savedInWindow(QuitPlanPath path) => switch (path) {
      QuitPlanPath.setQuitDate => _plusDays(10),
      QuitPlanPath.quitToday => _today,
      QuitPlanPath.reduceGradually => _plusDays(20),
    };

const _monthNames = <String>[
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

const _weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String _monthLabel(DateTime month) =>
    '${_monthNames[month.month - 1]} ${month.year}';

String _longDate(DateTime date) => '${_weekdayNames[date.weekday - 1]}, '
    '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

String _dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'quit-date-day-${date.year}-$month-$day';
}

final _days = find.byWidgetPredicate(
  (widget) =>
      widget is InkWell &&
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('quit-date-day-'),
  description: 'calendar days',
);

const _previousMonth = ValueKey('quit-date-previous-month');
const _nextMonth = ValueKey('quit-date-next-month');
const _confirm = ValueKey('quit-date-confirm');
const _unavailable = ValueKey('quit-date-unavailable');

/// Stands in for the plan editor: it keeps the date the screen reports and
/// passes it back, as the real caller does.
class _Host extends StatefulWidget {
  const _Host({
    required this.path,
    required this.saved,
    required this.changes,
    required this.confirmed,
    super.key,
  });

  final QuitPlanPath path;
  final DateTime? saved;
  final List<DateTime> changes;
  final List<DateTime> confirmed;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late DateTime? _date = widget.saved;

  @override
  Widget build(BuildContext context) {
    return SelectQuitDateScreen(
      isSpanish: false,
      quitPath: widget.path,
      selectedDate: _date,
      quitDayCheckIn: true,
      onDateChanged: (date) {
        widget.changes.add(date);
        setState(() => _date = date);
      },
      onQuitDayCheckInChanged: (_) {},
      onBack: () {},
      onContinue: widget.confirmed.add,
    );
  }
}

/// The month the calendar shows, read from its heading.
DateTime _shownMonth(WidgetTester tester) {
  final heading = RegExp(r'^(\w+) (\d{4})$');
  final months = <DateTime>[
    for (final text in tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('quit-date-calendar')),
        matching: find.byType(Text),
      ),
    ))
      if (heading.firstMatch(text.data ?? '') case final match?)
        if (_monthNames.indexOf(match.group(1)!) case final index
            when index >= 0)
          DateTime(int.parse(match.group(2)!), index + 1),
  ];
  expect(months, hasLength(1), reason: 'one month heading');
  return months.single;
}

bool _enabled(WidgetTester tester, Key key) =>
    tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed != null;

bool _monthEnabled(WidgetTester tester, Key key) =>
    tester.widget<IconButton>(find.byKey(key)).onPressed != null;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// The arrows are enabled exactly when an allowed month lies that way, and
/// the month shown is allowed and has days that can be tapped.
void _expectAllowedMonth(
  WidgetTester tester,
  DateTime month,
  DateTime firstMonth,
  DateTime lastMonth,
  String reason,
) {
  expect(
    !month.isBefore(firstMonth) && !month.isAfter(lastMonth),
    isTrue,
    reason: '$reason: ${_monthLabel(month)} is an allowed month',
  );
  expect(
    tester.widgetList<InkWell>(_days).where((day) => day.onTap != null),
    isNotEmpty,
    reason: '$reason: ${_monthLabel(month)} has days to choose',
  );
  // Grid days and list rows tell screen readers whether they can be chosen.
  for (final day in tester.widgetList<InkWell>(_days)) {
    expect(
      tester.getSemantics(find.byKey(day.key!)).flagsCollection.isEnabled,
      day.onTap != null ? Tristate.isTrue : Tristate.isFalse,
      reason: '$reason: ${(day.key! as ValueKey<String>).value} enabled',
    );
  }
  expect(
    _monthEnabled(tester, _previousMonth),
    month.isAfter(firstMonth),
    reason: '$reason: previous enabled only with an allowed month before',
  );
  expect(
    _monthEnabled(tester, _nextMonth),
    month.isBefore(lastMonth),
    reason: '$reason: next enabled only with an allowed month after',
  );
}

void main() {
  setUpAll(loadRoboto);

  for (final path in QuitPlanPath.values) {
    final saved = <String, DateTime>{
      'today-40': _plusDays(-40),
      'today-70': _plusDays(-70),
      'today+150': _plusDays(150),
      // In the last allowed month, so it is drawn when that month is shown.
      'the day after the window': DateTime(
        _window(path).$2.year,
        _window(path).$2.month,
        _window(path).$2.day + 1,
      ),
      'in the window': _savedInWindow(path),
    };
    for (final layout in _layouts.entries) {
      for (final entry in saved.entries) {
        testWidgets('saved date ${entry.key}: ${path.name}, ${layout.key}',
            (tester) async {
          final semantics = tester.ensureSemantics();
          final savedDate = entry.value;
          final available = _inWindow(path, savedDate);
          final (first, last) = _window(path);
          final firstMonth = _monthOf(first);
          final lastMonth = _monthOf(last);
          final changes = <DateTime>[];
          final confirmed = <DateTime>[];
          final reason = '${path.name}, ${layout.key}, saved ${entry.key}';

          await pumpLargeText(
            tester,
            size: _device,
            scaler: layout.value,
            font: LargeTextFont.roboto,
            home: _Host(
              path: path,
              saved: savedDate,
              changes: changes,
              confirmed: confirmed,
            ),
          );

          // Opens on the saved date's month, or on the first allowed month
          // when the saved date is outside the window.
          expect(
            _shownMonth(tester),
            available ? _monthOf(savedDate) : firstMonth,
            reason: '$reason: opening month',
          );
          _expectAllowedMonth(
            tester,
            _shownMonth(tester),
            firstMonth,
            lastMonth,
            '$reason, on opening',
          );

          // Confirm is disabled while the saved date is outside the window,
          // and a tap on it reports nothing.
          expect(
            _enabled(tester, _confirm),
            available,
            reason: '$reason: Confirm enabled only for a date in the window',
          );
          if (!available) {
            await _tap(tester, find.byKey(_confirm));
            expect(confirmed, isEmpty, reason: '$reason: Confirm blocked');
          }

          // The card still shows the saved date, marked as no longer
          // available.
          final summary = find.byKey(const ValueKey('quit-date-summary'));
          expect(
            find.descendant(
                of: summary, matching: find.text(_longDate(savedDate))),
            findsOneWidget,
            reason: '$reason: the saved date is shown',
          );
          expect(
            find.descendant(
              of: summary,
              matching: find.text(QuitDateCopy.unavailableEnglish),
            ),
            available ? findsNothing : findsOneWidget,
            reason: '$reason: no-longer-available message',
          );
          if (!available) {
            expect(
              find.text('RECOMMENDED'),
              findsNothing,
              reason: '$reason: an unavailable date is not recommended',
            );
          }

          // Screen readers hear that Confirm is disabled, and why.
          final confirmNode =
              tester.getSemantics(find.byKey(_confirm)).getSemanticsData();
          expect(
            confirmNode.flagsCollection.isEnabled,
            available ? Tristate.isTrue : Tristate.isFalse,
            reason: '$reason: Confirm announced as enabled or not',
          );
          expect(
            confirmNode.hint,
            available ? isEmpty : QuitDateCopy.unavailableEnglish,
            reason: '$reason: Confirm announces why it is disabled',
          );

          // The saved day is not shown as chosen anywhere in the calendar.
          void expectNoStaleChoice(String where) {
            if (available) return;
            expect(
              find.byKey(const ValueKey('quit-date-selected')),
              findsNothing,
              reason: '$reason, $where: no day is shown as chosen',
            );
          }

          expectNoStaleChoice('on opening');

          // Every arrow tap lands on a new, allowed month, and the arrows
          // stop at the window's first and last months.
          var month = _shownMonth(tester);
          while (_monthEnabled(tester, _previousMonth)) {
            await _tap(tester, find.byKey(_previousMonth));
            final next = _shownMonth(tester);
            expect(next, DateTime(month.year, month.month - 1),
                reason: '$reason: previous moves one month');
            month = next;
            _expectAllowedMonth(tester, month, firstMonth, lastMonth, reason);
            expectNoStaleChoice(_monthLabel(month));
          }
          expect(month, firstMonth, reason: '$reason: back to first month');
          while (_monthEnabled(tester, _nextMonth)) {
            await _tap(tester, find.byKey(_nextMonth));
            final next = _shownMonth(tester);
            expect(next, DateTime(month.year, month.month + 1),
                reason: '$reason: next moves one month');
            month = next;
            _expectAllowedMonth(tester, month, firstMonth, lastMonth, reason);
            expectNoStaleChoice(_monthLabel(month));
          }
          expect(month, lastMonth, reason: '$reason: on to the last month');

          // Looking around changes nothing.
          expect(changes, isEmpty, reason: '$reason: nothing was replaced');
          expect(confirmed, isEmpty, reason: '$reason: nothing confirmed');
          expect(_enabled(tester, _confirm), available, reason: reason);

          // Choosing the window's first day replaces the saved date and
          // lets Confirm through with that day.
          while (_monthEnabled(tester, _previousMonth)) {
            await _tap(tester, find.byKey(_previousMonth));
          }
          await _tap(tester, find.byKey(ValueKey(_dayKey(first))));
          expect(changes, [first], reason: '$reason: the chosen day');
          expect(find.byKey(_unavailable), findsNothing, reason: reason);
          expect(_enabled(tester, _confirm), isTrue, reason: reason);
          expect(
            tester.getSemantics(find.byKey(_confirm)).getSemanticsData().hint,
            isEmpty,
            reason: '$reason: no reason announced once a day is chosen',
          );
          await _tap(tester, find.byKey(_confirm));
          expect(confirmed, [first], reason: '$reason: confirmed day');
          for (final date in confirmed) {
            expect(_inWindow(path, date), isTrue,
                reason: '$reason: only days in the window are confirmed');
          }
          semantics.dispose();
        });
      }
    }
  }

  testWidgets('an in-window saved date confirms unchanged', (tester) async {
    for (final path in QuitPlanPath.values) {
      final savedDate = _savedInWindow(path);
      final changes = <DateTime>[];
      final confirmed = <DateTime>[];
      await pumpLargeText(
        tester,
        size: _device,
        scaler: TextScaler.noScaling,
        font: LargeTextFont.roboto,
        home: _Host(
          key: ValueKey(path),
          path: path,
          saved: savedDate,
          changes: changes,
          confirmed: confirmed,
        ),
      );
      expect(find.byKey(const ValueKey('quit-date-selected')), findsOneWidget);
      await _tap(tester, find.byKey(_confirm));
      expect(changes, isEmpty, reason: path.name);
      expect(confirmed, [savedDate], reason: path.name);
    }
  });
}
