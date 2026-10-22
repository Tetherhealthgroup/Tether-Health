import 'dart:ui' show Tristate;

import 'package:breathefree_patient/screens/choose_quit_path_screen.dart';
import 'package:breathefree_patient/screens/select_quit_date_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'large_text_harness.dart';

/// The quit-date calendar draws a 7-column grid at default text sizes and
/// lists the days instead above 140% text. Both must offer exactly the same
/// days: the quit path's window, from its first to its last day, and nothing
/// outside it.
const _device = Size(375, 667);

/// The grid at default size, and the list at the largest Android and iOS
/// sizes.
final _layouts = <String, TextScaler>{
  'grid at default size': TextScaler.noScaling,
  'list at 200%': const TextScaler.linear(2.0),
  'list at Android 14 non-linear 200%': androidNonLinear200,
  'list at 310%': const TextScaler.linear(3.1),
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

Set<String> _windowKeys(QuitPlanPath path) {
  final (first, last) = _window(path);
  return {
    for (var day = first;
        !day.isAfter(last);
        day = DateTime(day.year, day.month, day.day + 1))
      _dayKey(day),
  };
}

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

Future<void> _pumpCalendar(
  WidgetTester tester, {
  required QuitPlanPath path,
  required TextScaler scaler,
  DateTime? selectedDate,
  ValueChanged<DateTime>? onDateChanged,
}) async {
  await pumpLargeText(
    tester,
    size: _device,
    scaler: scaler,
    font: LargeTextFont.roboto,
    home: SelectQuitDateScreen(
      isSpanish: false,
      quitPath: path,
      selectedDate: selectedDate,
      quitDayCheckIn: true,
      onDateChanged: onDateChanged ?? (_) {},
      onQuitDayCheckInChanged: (_) {},
      onBack: () {},
      onContinue: (_) {},
    ),
  );
}

bool _monthButtonEnabled(WidgetTester tester, Key key) =>
    tester.widget<IconButton>(find.byKey(key)).onPressed != null;

Future<void> _tapMonthButton(WidgetTester tester, Key key) async {
  final button = find.byKey(key);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// Steps back to the first month the calendar allows, then calls [visit] on
/// every month up to the last one.
Future<void> _forEachMonth(
  WidgetTester tester,
  Future<void> Function() visit,
) async {
  while (_monthButtonEnabled(tester, _previousMonth)) {
    await _tapMonthButton(tester, _previousMonth);
  }
  while (true) {
    await visit();
    if (!_monthButtonEnabled(tester, _nextMonth)) break;
    await _tapMonthButton(tester, _nextMonth);
  }
}

/// Every day drawn in every month the calendar allows, and whether it can be
/// tapped.
Future<Map<String, bool>> _drawnDays(WidgetTester tester) async {
  final drawn = <String, bool>{};
  await _forEachMonth(tester, () async {
    for (final day in tester.widgetList<InkWell>(_days)) {
      final key = (day.key! as ValueKey<String>).value;
      expect(drawn.containsKey(key), isFalse, reason: '$key drawn twice');
      drawn[key] = day.onTap != null;
    }
  });
  return drawn;
}

Set<String> _tappable(Map<String, bool> days) => {
      for (final entry in days.entries)
        if (entry.value) entry.key
    };

void main() {
  setUpAll(loadRoboto);

  for (final path in QuitPlanPath.values) {
    testWidgets(
        'large-text quit date list offers exactly the grid\'s days '
        '(${path.name})', (tester) async {
      final window = _windowKeys(path);
      final (first, last) = _window(path);

      await _pumpCalendar(tester, path: path, scaler: TextScaler.noScaling);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('quit-date-calendar')),
          matching: find.byType(GridView),
        ),
        findsOneWidget,
      );
      final grid = _tappable(await _drawnDays(tester));
      expect(grid, window, reason: 'grid taps the quit path window');

      for (final layout in _layouts.entries.skip(1)) {
        await _pumpCalendar(tester, path: path, scaler: layout.value);
        expect(find.byType(GridView), findsNothing, reason: layout.key);
        final rows = await _drawnDays(tester);
        expect(
          rows.keys.toSet(),
          grid,
          reason: '${layout.key}: one row for each day the grid can tap, '
              'and none for days outside the window',
        );
        expect(
          _tappable(rows),
          grid,
          reason: '${layout.key}: every row can be tapped',
        );
        expect(rows.keys, contains(_dayKey(first)), reason: 'first day');
        expect(rows.keys, contains(_dayKey(last)), reason: 'last day');
        expect(
          rows.keys,
          isNot(contains(_dayKey(first.subtract(const Duration(days: 1))))),
          reason: 'the day before the window',
        );
        expect(
          rows.keys,
          isNot(
              contains(_dayKey(DateTime(last.year, last.month, last.day + 1)))),
          reason: 'the day after the window',
        );
      }
    });

    testWidgets(
        'tapping calendar days reports only days in the window '
        '(${path.name})', (tester) async {
      final window = _windowKeys(path);
      for (final layout in _layouts.entries) {
        final reported = <String>[];
        await _pumpCalendar(
          tester,
          path: path,
          scaler: layout.value,
          onDateChanged: (date) => reported.add(_dayKey(date)),
        );
        await _forEachMonth(tester, () async {
          final keys = [
            for (final day in tester.widgetList<InkWell>(_days))
              (day.key! as ValueKey<String>).value,
          ];
          for (final key in keys) {
            final day = find.byKey(ValueKey(key));
            await tester.ensureVisible(day);
            await tester.pumpAndSettle();
            await tester.tap(day, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
        });
        expect(
          reported.toSet(),
          window,
          reason: '${layout.key}: every day in the window, and no other',
        );
        expect(reported, hasLength(window.length), reason: layout.key);
      }
    });
  }

  for (final layout in _layouts.entries) {
    testWidgets(
        'only the chosen day is announced as selected '
        '(${layout.key})', (tester) async {
      final semantics = tester.ensureSemantics();
      final chosen = _plusDays(10);
      await _pumpCalendar(
        tester,
        path: QuitPlanPath.setQuitDate,
        scaler: layout.value,
        selectedDate: chosen,
      );
      final dateLabel = RegExp(r'^\d{1,2}/\d{1,2}/\d{4}');
      final days = find.semantics.byPredicate(
        (node) => dateLabel.hasMatch(node.label),
        describeMatch: (_) => 'calendar days',
      );
      expect(days.evaluate().length, greaterThan(1), reason: 'days drawn');
      final selected = find.semantics.byPredicate(
        (node) =>
            dateLabel.hasMatch(node.label) &&
            node.getSemanticsData().flagsCollection.isSelected ==
                Tristate.isTrue,
        describeMatch: (_) => 'selected calendar days',
      );
      final nodes = selected.evaluate().toList();
      expect(nodes, hasLength(1), reason: 'exactly one selected day');
      expect(
        nodes.single.label,
        startsWith('${chosen.month}/${chosen.day}/${chosen.year}'),
      );
      semantics.dispose();
    });
  }
}
