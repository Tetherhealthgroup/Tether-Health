// Backstop for moving text into the translation files: for every file that
// has left the isSpanish list, each English and Spanish string the baseline
// inventory (test/l10n/baseline/legacy_literals.json) found in it must now be
// in lib/l10n/app_en.arb or app_es.arb byte for byte, or still be in that
// file. A string that was reworded, dropped or retranslated on the way fails
// here even if no dumped screen shows it.
//
// A literal with interpolations (`'You chose $count'`) or joined to its
// neighbours is checked piece by piece: each run of text between
// interpolations must appear in some message of the language's file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'is_spanish_ratchet_test.dart' show isSpanishFiles, languageMapping;

/// One inventoried literal that is missing: where and what.
typedef MissingText = ({String file, int line, String branch, String text});

/// The text runs of the Dart literal body [raw]: escapes decoded, split at
/// `$name` and `${...}` interpolations.
List<String> textRuns(String raw) {
  final runs = <String>[];
  final buf = StringBuffer();
  var i = 0;
  while (i < raw.length) {
    final c = raw[i];
    if (c == r'\' && i + 1 < raw.length) {
      final n = raw[i + 1];
      const esc = {
        'n': '\n',
        't': '\t',
        r'\': r'\',
        "'": "'",
        '"': '"',
        r'$': r'$'
      };
      if (esc.containsKey(n)) {
        buf.write(esc[n]);
        i += 2;
        continue;
      }
      if (n == 'u') {
        final braced = raw.startsWith('{', i + 2);
        final end = braced ? raw.indexOf('}', i) : i + 6;
        buf.writeCharCode(
            int.parse(raw.substring(i + (braced ? 3 : 2), end), radix: 16));
        i = braced ? end + 1 : end;
        continue;
      }
    }
    if (c == r'$' && i + 1 < raw.length) {
      runs.add(buf.toString());
      buf.clear();
      if (raw[i + 1] == '{') {
        var depth = 1;
        var j = i + 2;
        while (j < raw.length && depth > 0) {
          if (raw[j] == '{') depth++;
          if (raw[j] == '}') depth--;
          j++;
        }
        i = j;
      } else {
        final m = RegExp(r'[A-Za-z_]\w*').matchAsPrefix(raw, i + 1);
        i += 1 + (m?.group(0)?.length ?? 0);
      }
      continue;
    }
    buf.write(c);
    i++;
  }
  runs.add(buf.toString());
  return [
    for (final r in runs)
      if (RegExp(r'\p{L}', unicode: true).hasMatch(r)) r
  ];
}

/// Whether [text] is a whole message of [messages], or a whole case of a
/// `select`/`plural` in one.
bool isWholeMessage(String text, List<String> messages) {
  final asCase =
      RegExp('(?:^|[\\s,])(?:=\\d+|[A-Za-z]\\w*)\\{${RegExp.escape(text)}\\}');
  return messages.any((m) => m == text || asCase.hasMatch(m));
}

/// Whether [run] (text between interpolations) appears in one of
/// [messages] with a placeholder, a case brace or the message start/end on
/// each side: so "No" is not found inside "No te juzgamos".
bool isBoundedRun(String run, List<String> messages) {
  for (final m in messages) {
    for (var i = m.indexOf(run); i >= 0; i = m.indexOf(run, i + 1)) {
      final end = i + run.length;
      final left = i == 0 || m[i - 1] == '{' || m[i - 1] == '}';
      final right = end == m.length || m[end] == '{' || m[end] == '}';
      if (left && right) return true;
    }
  }
  return false;
}

/// Every en/es literal of the files in [moved] (paths) from [inventory] that
/// is neither in [messages] (language → message texts) nor still in the
/// file's [source]. Literals Dart joins (`'a' 'b'`) are checked as one text.
/// A text without interpolation must be a whole message (or a whole case of
/// one); the runs of an interpolated text must each sit between
/// placeholders, case braces or the message's ends.
List<MissingText> missingText({
  required Map<String, Object?> inventory,
  required Set<String> moved,
  required Map<String, List<String>> messages,
  required String Function(String path) source,
}) {
  final out = <MissingText>[];
  final files = inventory['files']! as Map<String, Object?>;
  for (final path in moved) {
    final rows =
        ((files[path] as List?) ?? const []).cast<Map<String, Object?>>();
    final src = source(path);
    // Group each literal with the ones Dart joins to it.
    final groups = <List<Map<String, Object?>>>[];
    for (final r in rows) {
      if (r['joined'] == true && groups.isNotEmpty) {
        groups.last.add(r);
      } else {
        groups.add([r]);
      }
    }
    for (final group in groups) {
      final shown = [
        for (final r in group)
          if (r['branch'] != 'none' &&
              r['match'] != true &&
              r['key'] != true &&
              r['directive'] != true)
            r
      ];
      if (shown.isEmpty) continue;
      final branch = shown.first['branch']! as String;
      bool inSource(Map<String, Object?> r) {
        final raw = r['text']! as String;
        return src.contains("'$raw'") || src.contains('"$raw"');
      }

      if (shown.every(inSource)) continue;
      final raw = [for (final r in group) r['text']! as String].join();
      final texts = messages[branch] ?? const [];
      final runs = textRuns(raw);
      final interpolated = group.any((r) => r['interpolated'] == true) ||
          RegExp(r'(?<!\\)\$').hasMatch(raw);
      final ok = interpolated
          ? runs.every((run) => isBoundedRun(run, texts))
          : runs.isEmpty || isWholeMessage(runs.single, texts);
      if (!ok) {
        out.add((
          file: path,
          line: shown.first['line']! as int,
          branch: branch,
          text: raw
        ));
      }
    }
  }
  return out;
}

List<String> _messages(String path) {
  final arb = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return [
    for (final e in arb.entries)
      if (!e.key.startsWith('@')) e.value! as String
  ];
}

void main() {
  test(
      'text from every file that left the isSpanish list is in the translation files',
      () {
    final inventory = jsonDecode(
            File('test/l10n/baseline/legacy_literals.json').readAsStringSync())
        as Map<String, Object?>;
    final files = (inventory['files']! as Map<String, Object?>);
    final withText = {
      for (final e in files.entries)
        if ((e.value! as List)
            .any((r) => const {'en', 'es'}.contains((r as Map)['branch'])))
          e.key
    };
    final moved = withText.difference({...isSpanishFiles, ...languageMapping});
    final missing = missingText(
      inventory: inventory,
      moved: moved,
      messages: {
        'en': _messages('lib/l10n/app_en.arb'),
        'es': _messages('lib/l10n/app_es.arb')
      },
      source: (p) => File(p).existsSync() ? File(p).readAsStringSync() : '',
    );
    expect(missing, isEmpty,
        reason: 'reworded or dropped on the way to the translation files');
  });

  test('the backstop finds a reworded, a dropped and a retranslated string',
      () {
    final inventory = {
      'files': {
        'lib/x.dart': [
          {'line': 1, 'branch': 'en', 'text': r'You chose $count reasons'},
          {'line': 2, 'branch': 'es', 'text': r'Elegiste $count razones'},
          {'line': 3, 'branch': 'en', 'text': 'Stays in code'},
          {'line': 4, 'branch': 'es', 'text': 'caso', 'match': true},
          {'line': 5, 'branch': 'en', 'text': "It\\'s fine"},
        ],
      },
    };
    List<MissingText> check(List<String> en, List<String> es) => missingText(
          inventory: inventory,
          moved: {'lib/x.dart'},
          messages: {'en': en, 'es': es},
          source: (_) => "const k = 'Stays in code';",
        );
    expect(
        check(['You chose {count} reasons', "It's fine"],
            ['Elegiste {count} razones']),
        isEmpty);
    expect(
        check(['You picked {count} reasons', "It's fine"],
            ['Elegiste {count} razones']).map((m) => m.line),
        [1]);
    expect(
        check(['You chose {count} reasons', "It's fine"], [])
            .map((m) => m.line),
        [2]);
    expect(
        check(['You chose {count} reasons', "It's fine"],
            ['Escogiste {count} razones']).map((m) => m.line),
        [2]);
    expect(
        textRuns(r'Hola ${name.trim()}, ¿qué tal?'), ['Hola ', ', ¿qué tal?']);

    // The probe: short strings are not found inside longer messages.
    final probe = {
      'files': {
        'lib/y.dart': [
          {'line': 1, 'branch': 'es', 'text': 'No'},
          {'line': 2, 'branch': 'en', 'text': 'Off'},
          {'line': 3, 'branch': 'es', 'text': 'Sí'},
          {'line': 4, 'branch': 'en', 'text': 'Part one, '},
          {'line': 4, 'branch': 'en', 'text': 'part two', 'joined': true},
          {'line': 5, 'branch': 'es', 'text': 'situación'},
        ],
      },
    };
    List<int> lines(List<String> en, List<String> es) => missingText(
          inventory: probe,
          moved: {'lib/y.dart'},
          messages: {'en': en, 'es': es},
          source: (_) => '',
        ).map((m) => m.line).toList();
    expect(
        lines([
          'Office',
          'Part one, part two'
        ], [
          'No te juzgamos',
          'Sí, claro',
          '{n, plural, =1{situación} other{situaciones}}'
        ]),
        [1, 2, 3]);
    expect(
        lines(['Off', 'Part one, part two'],
            ['No', 'Sí', '{n, plural, =1{situación} other{situaciones}}']),
        isEmpty);
    expect(lines(['Off', 'Part one, '], ['No', 'Sí', 'situación']), [4]);
    expect(
        isBoundedRun(' razones elegidas · ',
            ['{count} razones elegidas · {top, select, true{a} other{b}}']),
        isTrue);
    expect(isBoundedRun('No', ['No te juzgamos']), isFalse);
  });
}
