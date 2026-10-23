// Quit date calendar on bf_date: a real month calendar in the app, the
// design in the preview. The chosen day is the session value
// `bf_date.quit_date` as yyyy-MM-dd; "Confirm this date" waits for it.
// Synthetic dates only.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/screens/bf/bf_support_screen.dart';
import 'package:tether_ui/ui/ui.dart';

const _key = 'bf_date.quit_date';

/// Thursday, October 22, 2026: the allowed days run from October 23 to
/// January 20, 2027.
final _now = DateTime(2026, 10, 22, 15, 30);

Future<void> _open(WidgetTester tester, {bool app = true, double scale = 1, DateTime? now}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  TData.instance = app ? const TEmptyData() : PreviewData();
  TCalendar.clock = () => now ?? _now;
  await tester.pumpWidget(MaterialApp(
    key: UniqueKey(),
    theme: tetherTheme(),
    onGenerateRoute: AppRouter.onGenerateRoute,
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
    onGenerateInitialRoutes: (_) => [AppRouter.onGenerateRoute(const RouteSettings(name: Routes.bfDate))!],
  ));
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _day(String iso) => find.byKey(ValueKey('calendar-day-$iso'));

Future<void> _tapDay(WidgetTester tester, String iso) async {
  await tester.ensureVisible(_day(iso));
  await tester.tap(_day(iso));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Finder get _confirm => find.byKey(const ValueKey('a:footer[0]'));

bool _confirmEnabled(WidgetTester tester) => tester.widget<TButton>(find.descendant(of: _confirm, matching: find.byType(TButton))).onPressed != null;

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('calendar-next')));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(TSession.clear);
  tearDown(() {
    TData.instance = PreviewData();
    TCalendar.clock = DateTime.now;
    TSession.clear();
  });

  group('preview', () {
    testWidgets('keeps the design: August 2026, the 28th chosen, the design card', (tester) async {
      await _open(tester, app: false);
      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('Friday, August 28, 2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('calendar-next')), findsNothing);
      expect(TSession.values[_key], '2026-08-28');
      expect(_confirmEnabled(tester), isTrue);
      await tester.tap(_confirm);
      await _settle(tester);
      expect(find.byType(BfSupportScreen), findsOneWidget);
    });
  });

  group('in the app', () {
    testWidgets('opens on the current month with nothing chosen', (tester) async {
      await _open(tester);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('August 2026'), findsNothing);
      expect(TSession.values.containsKey(_key), isFalse);
      expect(TSession.isTouched(_key), isFalse);
      // The design's example date is not shown as the member's.
      expect(find.text('Friday, August 28, 2026'), findsNothing);
      expect(find.text('YOUR QUIT DATE'), findsNothing);
      expect(_confirmEnabled(tester), isFalse);
      await tester.tap(_confirm, warnIfMissed: false);
      await _settle(tester);
      expect(find.byType(BfSupportScreen), findsNothing);
    });

    testWidgets('a tapped day is stored as yyyy-MM-dd and shown in full', (tester) async {
      await _open(tester);
      await _tapDay(tester, '2026-10-30');
      expect(TSession.values[_key], '2026-10-30');
      expect(TSession.isTouched(_key), isTrue);
      expect(find.text('YOUR QUIT DATE'), findsOneWidget);
      expect(find.text('Friday, October 30, 2026'), findsOneWidget);
      expect(find.text('8 days to prepare'), findsOneWidget);
      expect(_confirmEnabled(tester), isTrue);
      // Another day replaces it.
      await _tapDay(tester, '2026-10-23');
      expect(TSession.values[_key], '2026-10-23');
      expect(find.text('1 day to prepare'), findsOneWidget);
      await tester.tap(_confirm);
      await _settle(tester);
      expect(find.byType(BfSupportScreen), findsOneWidget);
    });

    testWidgets('today and earlier days cannot be chosen', (tester) async {
      await _open(tester);
      for (final iso in ['2026-10-22', '2026-10-21', '2026-10-01']) {
        await _tapDay(tester, iso);
        expect(TSession.values.containsKey(_key), isFalse, reason: iso);
      }
      expect(_confirmEnabled(tester), isFalse);
    });

    testWidgets('months: no earlier month than today, 90 days ahead at most', (tester) async {
      await _open(tester);
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('calendar-prev'))).onPressed, isNull);
      await _next(tester);
      expect(find.text('November 2026'), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('calendar-prev'))).onPressed, isNotNull);
      await _tapDay(tester, '2026-11-02');
      expect(TSession.values[_key], '2026-11-02');
      await tester.tap(find.byKey(const ValueKey('calendar-prev')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('October 2026'), findsOneWidget);
      expect(TSession.values[_key], '2026-11-02', reason: 'moving between months keeps the day');
      await _next(tester);
      await _next(tester);
      await _next(tester);
      expect(find.text('January 2027'), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('calendar-next'))).onPressed, isNull);
      await _tapDay(tester, '2027-01-21');
      expect(TSession.values[_key], '2026-11-02', reason: 'January 21 is more than 90 days ahead');
      await _tapDay(tester, '2027-01-20');
      expect(TSession.values[_key], '2027-01-20');
    });

    testWidgets('a day the session already holds is chosen when the screen opens', (tester) async {
      TSession.set(_key, '2026-11-10');
      await _open(tester);
      expect(find.text('November 2026'), findsOneWidget);
      expect(TSession.values[_key], '2026-11-10');
      expect(TSession.isTouched(_key), isFalse);
      expect(find.text('Tuesday, November 10, 2026'), findsOneWidget);
      expect(_confirmEnabled(tester), isTrue);
    });

    testWidgets('a held day that is no longer allowed is dropped', (tester) async {
      for (final held in ['2026-10-01', '2027-03-01', '2026-02-30', 'soon']) {
        TSession.set(_key, held);
        await _open(tester);
        expect(find.text('October 2026'), findsOneWidget, reason: held);
        expect(TSession.values.containsKey(_key), isFalse, reason: held);
        expect(_confirmEnabled(tester), isFalse, reason: held);
      }
    });

    testWidgets('screen readers: every day has a full date, the chosen one is selected, unavailable ones are disabled', (tester) async {
      final semantics = tester.ensureSemantics();
      await _open(tester);
      await _tapDay(tester, '2026-10-30');
      SemanticsData data(String iso) => tester.getSemantics(_day(iso)).getSemanticsData();
      expect(data('2026-10-30').label, 'Friday, October 30, 2026');
      expect(data('2026-10-30').flagsCollection.isSelected, Tristate.isTrue);
      expect(data('2026-10-30').flagsCollection.isButton, isTrue);
      expect(data('2026-10-31').label, 'Saturday, October 31, 2026');
      expect(data('2026-10-31').flagsCollection.isSelected, Tristate.isFalse);
      // October 30 is 8 days ahead, inside the recommended 7 to 14.
      expect(data('2026-10-30').hint, 'Recommended');
      expect(data('2026-10-23').hint, isEmpty);
      expect(data('2026-10-21').flagsCollection.isEnabled, Tristate.isFalse);
      expect(data('2026-10-23').flagsCollection.isEnabled, Tristate.isTrue);
      // An icon button is named by its tooltip.
      String name(String key) {
        final d = tester.getSemantics(find.byKey(ValueKey(key))).getSemanticsData();
        return d.label.isNotEmpty ? d.label : d.tooltip;
      }

      expect(name('calendar-prev'), 'Previous month');
      expect(name('calendar-next'), 'Next month');
      semantics.dispose();
    });

    testWidgets('a day can be chosen through its semantics action', (tester) async {
      final semantics = tester.ensureSemantics();
      await _open(tester);
      tester.semantics.tap(find.semantics.byLabel('Monday, October 26, 2026'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(TSession.values[_key], '2026-10-26');
      semantics.dispose();
    });

    testWidgets('a leap-year February lays out and its last day can be chosen', (tester) async {
      await _open(tester, now: DateTime(2027, 12, 20));
      // 2028-02-29 is 71 days ahead: allowed, and a real day.
      for (var i = 0; i < 2; i++) {
        await _next(tester);
      }
      expect(find.text('February 2028'), findsOneWidget);
      await _tapDay(tester, '2028-02-29');
      expect(TSession.values[_key], '2028-02-29');
      expect(find.text('Tuesday, February 29, 2028'), findsOneWidget);
      expect(_day('2028-03-01'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('large text does not overflow', (tester) async {
      await _open(tester, scale: 2);
      await _tapDay(tester, '2026-10-30');
      expect(tester.takeException(), isNull);
    });
  });

  test('dates: yyyy-MM-dd round trip, real days only', () {
    expect(TCalendar.iso(DateTime(2026, 1, 5)), '2026-01-05');
    expect(TCalendar.parseIso('2026-01-05'), DateTime(2026, 1, 5));
    for (final bad in [null, 5, '', '2026-1-5', '2026-02-30', '2026-13-01', '2026-01-05T00:00', ' 2026-01-05']) {
      expect(TCalendar.parseIso(bad), isNull, reason: '$bad');
    }
  });
}
