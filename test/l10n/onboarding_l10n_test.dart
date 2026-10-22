// The onboarding screens' text in the translation files:
// - the catalogs follow their rules (sorted keys, descriptions, Spanish
//   status, English-only list);
// - the quit-date month and weekday names, dates and ranges are identical to
//   the hand-written tables they replaced, for every day of a leap year, in
//   English and Spanish;
// - counted messages read exactly as the old string joins did;
// - a screen given a language other than the app locale's fails a debug
//   assert.
import 'dart:convert';
import 'dart:io';

import 'package:breathefree_patient/l10n/app_localizations.dart';
import 'package:breathefree_patient/screens/select_quit_date_screen.dart';
import 'package:breathefree_patient/screens/why_breathefree_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

List<String> _keys(Map<String, Object?> arb) => [
      for (final k in arb.keys)
        if (!k.startsWith('@')) k
    ];

// The tables and joins as they were at the baseline commit (97d81ce).
const _monthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];
const _monthsEs = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', //
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _shortEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _shortEs = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];
const _weekdaysEn = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', //
  'Sunday',
];
const _weekdaysEs = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String _oldLongDate(bool spanish, DateTime date) {
  final weekday = (spanish ? _weekdaysEs : _weekdaysEn)[date.weekday - 1];
  final month = (spanish ? _monthsEs : _monthsEn)[date.month - 1];
  if (spanish) return '$weekday, ${date.day} de $month de ${date.year}';
  return '$weekday, $month ${date.day}, ${date.year}';
}

String _oldRange(bool spanish, DateTime start, DateTime end) {
  final table = spanish ? _shortEs : _shortEn;
  final startMonth = table[start.month - 1];
  final endMonth = table[end.month - 1];
  if (start.year == end.year && start.month == end.month) {
    return '$startMonth ${start.day}–${end.day}';
  }
  return '$startMonth ${start.day} – $endMonth ${end.day}';
}

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final es = lookupAppLocalizations(const Locale('es'));

  group('catalogs', () {
    final enArb = _json('lib/l10n/app_en.arb');
    final esArb = _json('lib/l10n/app_es.arb');
    final status = _json('lib/l10n/es_status.json');

    test('keys are sorted and every English key is described', () {
      for (final arb in [enArb, esArb]) {
        final keys = _keys(arb);
        expect(keys, [...keys]..sort(), reason: arb['@@locale'] as String);
      }
      for (final k in _keys(enArb)) {
        final meta = enArb['@$k'] as Map<String, Object?>?;
        expect(meta?['description'], isA<String>(), reason: k);
        expect(meta!['description'] as String, startsWith('lib/'),
            reason: '$k names its source file');
      }
    });

    // An entry approved by clinical/legal review records the approval as
    // `approved:<record>`.
    test('every Spanish entry is shipped, derived from shipped, or approved',
        () {
      expect(status.keys.toSet(), _keys(esArb).toSet());
      for (final e in status.entries) {
        final s = e.value! as Map<String, Object?>;
        final kind = s['status'] as String;
        expect(
          kind == 'shipped-04813d0' ||
              kind == 'derived-04813d0' ||
              RegExp(r'^approved:\S+$').hasMatch(kind),
          isTrue,
          reason: '${e.key}: $kind',
        );
        expect(s['file'], isA<String>(), reason: e.key);
        if (kind == 'derived-04813d0') {
          expect(s['source'], isA<String>(),
              reason: '${e.key} names the shipped string it comes from');
        }
      }
    });

    test('drafts never reach the translation files', () {
      final arbs = {
        for (final f in Directory('lib/l10n').listSync().whereType<File>())
          if (f.path.endsWith('.arb')) f.uri.pathSegments.last,
      };
      expect(arbs, {'app_en.arb', 'app_es.arb'});
      expect(File('l10n.yaml').readAsStringSync(), isNot(contains('drafts')));
    });
  });

  group('quit-date names and dates equal the old tables', () {
    test('every day of a leap year, in English and Spanish', () {
      for (var date = DateTime(2028, 1, 1);
          date.year == 2028;
          date = DateTime(date.year, date.month, date.day + 1)) {
        expect(quitDateLongDate(en, date), _oldLongDate(false, date),
            reason: '$date en');
        expect(quitDateLongDate(es, date), _oldLongDate(true, date),
            reason: '$date es');
        expect(quitDateWeekdayName(en, date.weekday),
            _weekdaysEn[date.weekday - 1]);
        expect(quitDateWeekdayName(es, date.weekday),
            _weekdaysEs[date.weekday - 1]);
        expect(quitDateMonthName(en, date.month), _monthsEn[date.month - 1]);
        expect(quitDateMonthName(es, date.month), _monthsEs[date.month - 1]);
        expect(quitDateShortMonth(en, date.month), _shortEn[date.month - 1]);
        expect(quitDateShortMonth(es, date.month), _shortEs[date.month - 1]);
        expect(
            en.selectQuitDateMonthYear(
                quitDateMonthName(en, date.month), date.year),
            '${_monthsEn[date.month - 1]} ${date.year}');
        expect(
            es.selectQuitDateMonthYear(
                quitDateMonthName(es, date.month), date.year),
            '${_monthsEs[date.month - 1]} ${date.year}');
        for (final span in [7, 14, 30]) {
          final end = DateTime(date.year, date.month, date.day + span);
          for (final (l10n, spanish) in [(en, false), (es, true)]) {
            final startMonth = quitDateShortMonth(l10n, date.month);
            final endMonth = quitDateShortMonth(l10n, end.month);
            final now = date.year == end.year && date.month == end.month
                ? l10n.selectQuitDateRangeSameMonth(
                    startMonth, date.day, end.day)
                : l10n.selectQuitDateRange(
                    startMonth, date.day, endMonth, end.day);
            expect(now, _oldRange(spanish, date, end),
                reason: '$date +$span ${spanish ? 'es' : 'en'}');
          }
        }
      }
    });

    test('the calendar weekday initials', () {
      expect(quitDateWeekdayInitials(en), ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
      expect(quitDateWeekdayInitials(es), ['D', 'L', 'M', 'M', 'J', 'V', 'S']);
    });

    test('the unavailable-date message matches its English and Spanish source',
        () {
      expect(
          en.selectQuitDateUnavailableMessage, QuitDateCopy.unavailableEnglish);
      expect(
          es.selectQuitDateUnavailableMessage, QuitDateCopy.unavailableSpanish);
    });
  });

  test('counted messages read as the old joins did, for 0, 1, 2, 5 and 21', () {
    for (final n in [0, 1, 2, 5, 21]) {
      expect(en.triggerMapSelectionCount(n),
          '$n ${n == 1 ? 'trigger selected' : 'triggers selected'} · Saved automatically');
      expect(es.triggerMapSelectionCount(n),
          '$n ${n == 1 ? 'desencadenante elegido' : 'desencadenantes elegidos'} · Guardado automáticamente');
      expect(en.readinessResultSituationCount(n),
          'You identified $n ${n == 1 ? 'situation' : 'situations'} to prepare for');
      expect(es.readinessResultSituationCount(n),
          'Ya identificaste $n ${n == 1 ? 'situación' : 'situaciones'} para preparar');
      for (final top in [true, false]) {
        expect(en.myReasonsSelectionSummary(n, top.toString()),
            '$n reasons selected · ${top ? '1 top reason' : 'no top reason'}');
        expect(es.myReasonsSelectionSummary(n, top.toString()),
            '$n razones elegidas · ${top ? '1 razón principal' : 'sin razón principal'}');
      }
    }
  });

  testWidgets(
      'a screen whose language differs from the app locale fails an assert',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: WhyBreatheFreeScreen(
          isSpanish: true, onBack: () {}, onContinue: () {}),
    ));
    final error = tester.takeException();
    expect(error, isA<AssertionError>());
    expect('$error', contains('the screen language must match the app locale'));
  });
}
