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

/// Every en/es literal of the files in [moved] (paths) from [inventory] that
/// is neither in [messages] (language → message texts) nor still in the
/// file's [source].
List<MissingText> missingText({
  required Map<String, Object?> inventory,
  required Set<String> moved,
  required Map<String, List<String>> messages,
  required String Function(String path) source,
}) {
  final out = <MissingText>[];
  final files = inventory['files']! as Map<String, Object?>;
  for (final path in moved) {
    final rows = (files[path] as List?) ?? const [];
    final src = source(path);
    for (final r in rows.cast<Map<String, Object?>>()) {
      final branch = r['branch']! as String;
      if (branch == 'none' ||
          r['match'] == true ||
          r['key'] == true ||
          r['directive'] == true) {
        continue;
      }
      final raw = r['text']! as String;
      if (src.contains("'$raw'") || src.contains('"$raw"')) continue;
      final texts = messages[branch] ?? const [];
      final ok =
          textRuns(raw).every((run) => texts.any((m) => m.contains(run)));
      if (!ok) {
        out.add(
            (file: path, line: r['line']! as int, branch: branch, text: raw));
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
  });
}
