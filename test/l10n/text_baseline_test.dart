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
// Dates and times come from the phone's clock, so before comparing, month
// and weekday names become <month> and <weekday>, numbers become <n>, the
// time-of-day greeting becomes <greeting>, lines that are only numbers (a
// calendar's days) are dropped, and repeated lines are kept once. Month and
// weekday tables are therefore checked by their own tests, not here.
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

/// The commit whose app the dumps were taken from.
const baselineCommit = '97d81ce';

/// sha256 of every file in test/l10n/baseline/, in name order, each as
/// `<name>\n<content>`.
const baselineDigest =
    '2d2a012d49e0139ff9b1aa3617f1521b4ec78f34b07a77d7da0987e6fd66bad6';

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

final _months = RegExp(
  r'\b(January|February|March|April|May|June|July|August|September|October|November|December'
  r'|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec'
  r'|enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre)\b',
  caseSensitive: false,
);
final _weekdays = RegExp(
  r'(?<![\p{L}])(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|Mon|Tue|Tues|Wed|Thu|Thur|Thurs|Fri|Sat|Sun'
  r'|lunes|martes|miércoles|jueves|viernes|sábado|domingo|lun|mié|jue|vie|sáb|dom)(?![\p{L}])',
  caseSensitive: false,
  unicode: true,
);
final _greeting = RegExp(
    r'Good (morning|afternoon|evening)|Buenos días|Buenas (tardes|noches)');
final _number = RegExp(r'\d+');

/// The comparable form of one dumped line (see the file comment).
String normalize(String line) => line
    .replaceAll(_greeting, '<greeting>')
    .replaceAll(_months, '<month>')
    .replaceAll(_weekdays, '<weekday>')
    .replaceAll(_number, '<n>');

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
  final out = <String>[];
  for (final line in raw) {
    final n = _esc(normalize(line));
    final body = n.substring(n.indexOf(' ') + 1);
    // Blank lines, icons (private-use glyphs), and lines of only numbers and
    // punctuation (a calendar's days, a running timer) carry no text.
    final text = body
        .replaceAll('<n>', '')
        .replaceAll(RegExp(r'[\s\p{P}\p{S}\p{Co}\p{Cf}]', unicode: true), '');
    if (text.isEmpty) continue;
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
    expect(normalize('T TODAY · OCTOBER 22'), 'T TODAY · <month> <n>');
    expect(normalize('T HOY · 22 DE OCTUBRE'), 'T HOY · <n> DE <month>');
    expect(normalize('T miércoles, 22 de octubre de 2026'),
        'T <weekday>, <n> de <month> de <n>');
    expect(normalize('T Good evening, Alex.'), 'T <greeting>, Alex.');
    expect(normalize('T Buenos días.'), 'T <greeting>.');
    expect(
        normalize('T Monitoring your progress'), 'T Monitoring your progress');
    expect(normalize('T Sundays only'), 'T Sundays only');
  });
}
