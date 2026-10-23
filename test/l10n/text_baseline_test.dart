// Baseline of the text the current app shows, before its English and
// Spanish move into translation files.
//
// Every case below starts the real app (BreatheFreeApp) on a phone-sized
// screen in English and in Spanish, as a phone set to that language would,
// optionally taps into a state, and dumps every Text, RichText and
// EditableText string and every semantics label, value, hint and tooltip in
// tree order. The dumps in test/l10n/baseline/ were generated at the
// baseline commit [baselineCommit] and must stay identical: moving text into
// translation files must not change a single shown string. A dump file is
// never edited to make this test pass, and [baselineDigest] pins all of
// them.
//
// Dates come from the phone's clock, so before comparing, only what the
// clock decides is normalised: month and weekday names become <month> and
// <weekday>, the day and year next to them <day> and <year>, numeric dates
// <date>, time since quitting <elapsed>, the time-of-day greeting
// <greeting>, a date stacked as month, day and weekday (the quit-date
// card) <month> <day> <weekday>, and a calendar's run of day numbers one
// line. Phone numbers
// and every other number stay as shown. Repeated lines are kept once. A date
// written as a literal (such as a review date) is normalised too; its words
// are still compared here, and its exact text by moved_text_test.dart. Month
// and weekday tables are checked by their own old-vs-new tests.
//
// To regenerate the dumps at a new baseline (a reviewed decision, never in a
// ticket that moves text), run with TEXT_BASELINE_WRITE=1, then update
// [baselineCommit] and [baselineDigest].
import 'dart:convert';
import 'dart:io';

import 'package:breathefree_patient/l10n/app_locale.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/models/screen_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tether_ui/approved_parity.dart' show sha256Hex;

/// The baseline label: the ticket ID of the change that last re-recorded
/// the dumps (the app's text as of that change's landing).
const baselineCommit = 'TH-1015b';

/// sha256 of every file in test/l10n/baseline/, in name order, each as
/// `<name>\n<content>`.
const baselineDigest =
    'caa60e859364b06cd360cc574ae91b1090e0365a3dbbaa8f6ad6e68fe2905a53';

const baselineDir = 'test/l10n/baseline';

/// A state to dump: [steps] run after the app opens on [screen].
class TextCase {
  const TextCase(this.id, {this.screen = 0, this.steps = const []});
  final String id;
  final int screen;
  final List<Future<void> Function(WidgetTester)> steps;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> Function(WidgetTester) _tapKey(String key) => (tester) async {
      final finder = find.byKey(ValueKey(key));
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await _settle(tester);
    };

Future<void> Function(WidgetTester) _tapText(String text) => (tester) async {
      final finder = find.text(text).first;
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await _settle(tester);
    };

final cases = <TextCase>[
  for (var i = 0; i < approvedScreens.length; i++)
    TextCase('screen${i.toString().padLeft(2, '0')}', screen: i),
  TextCase('welcome_language_menu', steps: [_tapKey('welcome-language-menu')]),
  TextCase('welcome_sign_in', steps: [_tapKey('welcome-sign-in')]),
  TextCase('programs', screen: 27, steps: [_tapKey('settings-programs')]),
  for (final program in ['Heartwise', 'Steady', 'ClearAir'])
    TextCase('program_${program.toLowerCase()}',
        screen: 27, steps: [_tapKey('settings-programs'), _tapText(program)]),
];

const locales = <String, Locale>{
  'en': Locale('en', 'US'),
  'es': Locale('es', 'US')
};

// Month and weekday names, as the app writes them: English capitalised or
// upper case, Spanish lower case, capitalised or upper case. Words that are
// also ordinary words ("May", "Mar", "Sun"...) and short forms count only
// next to a day number.
const _monthNames =
    'January|February|March|April|June|July|August|September|October|November|December'
    '|JANUARY|FEBRUARY|MARCH|APRIL|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER'
    '|enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre'
    '|Enero|Febrero|Marzo|Abril|Mayo|Junio|Julio|Agosto|Septiembre|Octubre|Noviembre|Diciembre'
    '|ENERO|FEBRERO|MARZO|ABRIL|MAYO|JUNIO|JULIO|AGOSTO|SEPTIEMBRE|OCTUBRE|NOVIEMBRE|DICIEMBRE';
const _monthShort = 'May|MAY|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec'
    '|JAN|FEB|MAR|APR|JUN|JUL|AUG|SEP|OCT|NOV|DEC'
    '|ene|feb|mar|abr|may|jun|jul|ago|sep|oct|nov|dic'
    '|ENE|ABR|AGO|DIC';

/// A date shown as three stacked parts, as on the quit-date card: short
/// month, day number and short weekday, each on its own line.
final _cardMonth = RegExp('^($_monthShort|<month>)\$');
final _cardDay = RegExp(r'^([1-9]|[12]\d|3[01])$');
final _cardWeekday = RegExp(
    r'^(MON|TUE|WED|THU|FRI|SAT|SUN|LUN|MAR|MIÉ|JUE|VIE|SÁB|DOM|<weekday>)$');

/// [parts] with every stacked date (month, day, weekday) normalised.
List<String> normalizeStackedDates(List<String> parts) {
  final out = [...parts];
  for (var i = 0; i + 2 < out.length; i++) {
    if (_cardMonth.hasMatch(out[i]) &&
        _cardDay.hasMatch(out[i + 1]) &&
        _cardWeekday.hasMatch(out[i + 2])) {
      out[i] = '<month>';
      out[i + 1] = '<day>';
      out[i + 2] = '<weekday>';
    }
  }
  return out;
}

const _weekdayNames = 'Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday'
    '|MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY'
    '|lunes|martes|miércoles|jueves|viernes|sábado|domingo'
    '|Lunes|Martes|Miércoles|Jueves|Viernes|Sábado|Domingo'
    '|LUNES|MARTES|MIÉRCOLES|JUEVES|VIERNES|SÁBADO|DOMINGO';

final _greeting = RegExp(
    r'Good (morning|afternoon|evening)|Buenos días|Buenas (tardes|noches)');
final _month = RegExp('(?<![\\p{L}])($_monthNames)(?![\\p{L}])', unicode: true);
final _monthNearDay = RegExp(
    '(?<![\\p{L}])($_monthShort)(?![\\p{L}])(?=\\.? \\d{1,2}(?!\\d))|(?<=\\d{1,2} )($_monthShort)(?![\\p{L}])',
    unicode: true);
final _weekday =
    RegExp('(?<![\\p{L}])($_weekdayNames)(?![\\p{L}])', unicode: true);
final _dayAfterMonth = RegExp(r'<month>(\.?) (\d{1,2})(?!\d)');
final _dayBeforeMonth = RegExp(r'(?<!\d)(\d{1,2}) ((?:de|DE) )?<month>');
final _dayRange = RegExp(r'<day>–(\d{1,2})(?!\d)');
final _year = RegExp(
    r'(<month> <day>, |de <month> de |DE <month> DE |<day> <month> |<month> )(\d{4})(?!\d)');
final _slashDate = RegExp(r'(?<!\d)\d{1,2}/\d{1,2}/\d{4}(?!\d)');
final _elapsed = RegExp(r'(?<![\w])(\d+h )?\d+m(?![\p{L}\d])', unicode: true);

/// The comparable form of one dumped line (see the file comment): only
/// clock-derived parts change; phone numbers and every other number stay.
String normalize(String line) => line
    .replaceAll(_greeting, '<greeting>')
    .replaceAll(_month, '<month>')
    .replaceAll(_monthNearDay, '<month>')
    .replaceAll(_weekday, '<weekday>')
    .replaceAllMapped(_dayAfterMonth, (m) => '<month>${m[1]} <day>')
    .replaceAllMapped(_dayBeforeMonth, (m) => '<day> ${m[2] ?? ''}<month>')
    .replaceAll(_dayRange, '<day>–<day>')
    .replaceAllMapped(_year, (m) => '${m[1]}<year>')
    .replaceAll(_slashDate, '<date>')
    .replaceAll(RegExp(r'(?<=<date>\n)\d{1,2}$'), '<day>')
    .replaceAll(_elapsed, '<elapsed>');

/// A calendar grid: seven or more lines in a row that are each a day number.
final _dayNumber = RegExp(r'^T ([1-9]|[12]\d|3[01])$');

String _esc(String s) => s.replaceAll('\\', '\\\\').replaceAll('\n', '\\n');

/// Every shown string in tree order, normalized.
List<String> dumpLines(WidgetTester tester) {
  final raw = <String>[];
  void visit(RenderObject r) {
    if (r is RenderParagraph) raw.add('T ${r.text.toPlainText()}');
    if (r is RenderEditable) raw.add('E ${r.text?.toPlainText() ?? ''}');
    r.visitChildren(visit);
  }

  for (final view in tester.binding.renderViews) {
    visit(view);
  }
  void sem(SemanticsNode n) {
    final d = n.getSemanticsData();
    for (final (tag, value) in [
      ('SL', d.label),
      ('SV', d.value),
      ('SH', d.hint),
      ('ST', d.tooltip)
    ]) {
      if (value.isNotEmpty) raw.add('$tag $value');
    }
    n.visitChildren((c) {
      sem(c);
      return true;
    });
  }

  for (final view in tester.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) sem(root);
  }
  final lines = <String>[];
  for (final line in raw) {
    final n = normalize(line);
    final body = n.substring(n.indexOf(' ') + 1);
    // Blank lines and icons (private-use glyphs) carry no text.
    final text = body.replaceAll(
        RegExp(r'[\s\p{P}\p{S}\p{Co}\p{Cf}]', unicode: true), '');
    if (text.isEmpty) continue;
    // A stacked date inside one semantics label (parts on separate lines).
    final tag = n.substring(0, n.indexOf(' '));
    lines.add('$tag ${normalizeStackedDates(body.split('\n')).join('\n')}');
  }
  // A stacked date drawn as separate texts, or read as separate labels.
  for (final tag in ['T', 'SL']) {
    final stacked = normalizeStackedDates([
      for (final l in lines)
        l.startsWith('$tag ') ? l.substring(tag.length + 1) : '\u0000$l'
    ]);
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('$tag ')) lines[i] = '$tag ${stacked[i]}';
    }
  }
  // A calendar shows the current month: its run of day numbers becomes one
  // line. Any other number line stays.
  final calendar = <String>[];
  for (var i = 0; i < lines.length;) {
    var j = i;
    while (j < lines.length && _dayNumber.hasMatch(lines[j])) {
      j++;
    }
    if (j - i >= 7) {
      calendar.add('T <calendar days>');
      i = j;
    } else {
      calendar.add(lines[i]);
      i++;
    }
  }
  final out = <String>[];
  for (final line in calendar) {
    final n = _esc(line);
    if (out.isNotEmpty && out.last == n) continue;
    out.add(n);
  }
  return out;
}

String _file(String id, String locale) => '$baselineDir/${id}_$locale.txt';

String _header(String id, String locale) =>
    '# baseline $baselineCommit · $id · $locale';

Future<List<String>> _run(
    WidgetTester tester, TextCase c, Locale locale) async {
  final handle = tester.ensureSemantics();
  // Layout overflows are reported by the layout tests, not here: the text is
  // dumped either way. Any other error fails the case.
  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  addTearDown(() => FlutterError.onError = previous);
  FlutterSecureStorage.setMockInitialValues({});
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BreatheFreeApp(
    initialScreen: c.screen,
    appLocale:
        AppLocale(store: MemoryAppLocaleStore(), deviceLocales: () => [locale]),
  ));
  await _settle(tester);
  for (final step in c.steps) {
    await step(tester);
  }
  final lines = dumpLines(tester);
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
  FlutterError.onError = previous;
  final other = [
    for (final e in errors)
      if (!e.exceptionAsString().startsWith('A RenderFlex overflowed'))
        e.exceptionAsString().split('\n').first,
  ];
  expect(other, isEmpty);
  handle.dispose();
  return lines;
}

/// The digest of the files in [dir] (see [baselineDigest]).
String digestOf(Directory dir) {
  final files = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final text = StringBuffer();
  for (final f in files) {
    text
      ..write(f.uri.pathSegments.last)
      ..write('\n')
      ..write(f.readAsStringSync());
  }
  return sha256Hex(utf8.encode(text.toString()));
}

void main() {
  final write = Platform.environment['TEXT_BASELINE_WRITE'] == '1';

  for (final c in cases) {
    for (final entry in locales.entries) {
      testWidgets('${c.id} in ${entry.key} shows the baseline text',
          (tester) async {
        final lines = await _run(tester, c, entry.value);
        final text = '${[_header(c.id, entry.key), ...lines].join('\n')}\n';
        final file = File(_file(c.id, entry.key));
        if (write) {
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(text);
          return;
        }
        expect(file.existsSync(), isTrue,
            reason: '${file.path} is missing; restore it from git');
        final want = file.readAsStringSync().split('\n');
        final got = text.split('\n');
        for (var i = 0; i < want.length || i < got.length; i++) {
          final w = i < want.length ? want[i] : '<end>';
          final g = i < got.length ? got[i] : '<end>';
          if (w != g) {
            fail(
                '${file.path} line ${i + 1} changed:\n  baseline: $w\n  now:      $g\n'
                'Shown text must not change while moving it into translation files.');
          }
        }
      });
    }
  }

  test(
      'the baseline files are exactly the cases, from the baseline commit, unedited',
      () {
    if (write) return;
    final dir = Directory(baselineDir);
    final dumps = {
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.txt')) f.uri.pathSegments.last,
    };
    final want = {
      for (final c in cases)
        for (final l in locales.keys) '${c.id}_$l.txt',
    };
    expect(dumps, want);
    for (final c in cases) {
      for (final l in locales.keys) {
        expect(File(_file(c.id, l)).readAsLinesSync().first, _header(c.id, l));
      }
    }
    final inventory =
        jsonDecode(File('$baselineDir/legacy_literals.json').readAsStringSync())
            as Map<String, Object?>;
    expect(inventory['baseCommit'], baselineCommit);
    expect(digestOf(dir), baselineDigest,
        reason:
            'a file in $baselineDir changed; baseline files are never edited');
  });

  test('normalizing hides only the clock', () {
    expect(normalize('T TODAY · OCTOBER 22'), 'T TODAY · <month> <day>');
    expect(normalize('T HOY · 22 DE OCTUBRE'), 'T HOY · <day> DE <month>');
    expect(normalize('T miércoles, 22 de octubre de 2026'),
        'T <weekday>, <day> de <month> de <year>');
    expect(normalize('T Thursday, October 22, 2026'),
        'T <weekday>, <month> <day>, <year>');
    expect(normalize('T October 2026'), 'T <month> <year>');
    expect(normalize('T Oct 22–29'), 'T <month> <day>–<day>');
    expect(normalize('T Oct 29 – Nov 3'), 'T <month> <day> – <month> <day>');
    expect(normalize('SL 10/22/2026\n22'), 'SL <date>\n<day>');
    expect(normalize('T 3h 12m'), 'T <elapsed>');
    expect(normalize('T 48m'), 'T <elapsed>');
    expect(normalize('T About 5 minutes'), 'T About 5 minutes');
    expect(normalize('T QUIT DAY · OCT 22'), 'T QUIT DAY · <month> <day>');
    expect(normalizeStackedDates(['YOUR QUIT DATE', 'OCT', '29', 'THU', 'x']),
        ['YOUR QUIT DATE', '<month>', '<day>', '<weekday>', 'x']);
    expect(normalizeStackedDates(['OCT', '29', 'JUE']),
        ['<month>', '<day>', '<weekday>']);
    expect(normalizeStackedDates(['STEP', '2', 'OF']), ['STEP', '2', 'OF']);
    expect(normalize('T revisadas el 22 ago 2026'),
        'T revisadas el <day> <month> <year>');
    expect(normalize('T Good evening, Alex.'), 'T <greeting>, Alex.');
    expect(normalize('T Buenos días.'), 'T <greeting>.');
    // Not the clock: ordinary words, phone numbers and other numbers stay.
    expect(normalize('T Hours may vary'), 'T Hours may vary');
    expect(normalize('T May I help?'), 'T May I help?');
    expect(normalize('T Call 1-800-784-8669 or 988'),
        'T Call 1-800-784-8669 or 988');
    expect(normalize('T STEP 2 OF 5'), 'T STEP 2 OF 5');
    expect(normalize('T About 5 minutes'), 'T About 5 minutes');
    expect(normalize('T Sundays only'), 'T Sundays only');
    expect(normalize('T 7:00 AM'), 'T 7:00 AM');
  });
}
