// Backstop for moving text into the translation files: for every file that
// has left the isSpanish list, each English and Spanish string the baseline
// inventory (test/l10n/baseline/legacy_literals.json) found in it is
// recorded in test/l10n/moved_keys.json with the ARB key it moved to, and
// must equal that key's English or Spanish value exactly (or the named case
// of a select/plural). A string that was reworded, dropped or retranslated
// on the way fails here even if no dumped screen shows it.
//
// A literal with interpolations (`'You chose $count'`) must have exactly the
// value's text between placeholders; literals Dart joins (`'a' 'b'`) are
// checked as one text; a literal nested in another's interpolation is its
// own text.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'is_spanish_ratchet_test.dart' show isSpanishFiles, languageMapping;

/// One inventoried literal that is missing or changed: where and what.
typedef MissingText = ({
  String file,
  int line,
  String branch,
  String text,
  String problem
});

/// The text runs of the Dart literal body [raw]: escapes decoded, split at
/// `$name` and `${...}` interpolations. Only runs with letters, unless
/// [all].
List<String> textRuns(String raw, {bool all = false}) {
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
  if (all) return runs;
  return [
    for (final r in runs)
      if (RegExp(r'\p{L}', unicode: true).hasMatch(r)) r
  ];
}

/// The text of [message] outside its `{...}` placeholders and arguments.
List<String> messageRuns(String message) {
  final runs = <String>[];
  final buf = StringBuffer();
  var depth = 0;
  for (final c in message.split('')) {
    if (c == '{') {
      if (depth == 0) {
        runs.add(buf.toString());
        buf.clear();
      }
      depth++;
    } else if (c == '}') {
      depth--;
    } else if (depth == 0) {
      buf.write(c);
    }
  }
  runs.add(buf.toString());
  return runs;
}

/// The body of case [selector] (`one`, `=1`, `january`...) of the first
/// select/plural in [message], or null.
String? caseBody(String message, String selector) {
  final m =
      RegExp('(?:^|[\\s,])${RegExp.escape(selector)}\\{').firstMatch(message);
  if (m == null) return null;
  var depth = 1;
  var j = m.end;
  while (j < message.length && depth > 0) {
    if (message[j] == '{') depth++;
    if (message[j] == '}') depth--;
    j++;
  }
  return message.substring(m.end, j - 1);
}

/// The inventory rows of a file grouped as Dart reads them: a literal with
/// the ones joined to it (`'a' 'b'`); a literal nested in another's
/// interpolation starts its own group.
List<List<int>> literalGroups(List<Map<String, Object?>> rows) {
  final groups = <List<int>>[];
  for (var i = 0; i < rows.length; i++) {
    final text = rows[i]['text']! as String;
    final nested = groups.isNotEmpty &&
        groups.last.any((j) {
          final outer = rows[j]['text']! as String;
          return outer.contains("'$text'") || outer.contains('"$text"');
        });
    if (rows[i]['joined'] == true && groups.isNotEmpty && !nested) {
      groups.last.add(i);
    } else {
      groups.add([i]);
    }
  }
  return groups;
}

bool _shown(Map<String, Object?> r) =>
    r['branch'] != 'none' &&
    r['match'] != true &&
    r['key'] != true &&
    r['directive'] != true;

/// Every en/es literal group of the files in [moved] whose recorded key
/// ([movedKeys]: file → row → `key`, `key#case` or `=source`) is missing or
/// whose value in [messages] (language → key → message) is not exactly its
/// text.
List<MissingText> missingText({
  required Map<String, Object?> inventory,
  required Set<String> moved,
  required Map<String, Map<String, Object?>> movedKeys,
  required Map<String, Map<String, String>> messages,
  required Map<String, String> keyFiles,
  required String Function(String path) source,
}) {
  final out = <MissingText>[];
  final files = inventory['files']! as Map<String, Object?>;
  for (final path in moved) {
    final rows =
        ((files[path] as List?) ?? const []).cast<Map<String, Object?>>();
    final keys = movedKeys[path] ?? const {};
    final src = source(path);
    for (final group in literalGroups(rows)) {
      final shown = [
        for (final i in group)
          if (_shown(rows[i])) i
      ];
      if (shown.isEmpty) continue;
      final first = rows[shown.first];
      final branch = first['branch']! as String;
      final raw = [for (final i in group) rows[i]['text']! as String].join();
      MissingText miss(String problem) => (
            file: path,
            line: first['line']! as int,
            branch: branch,
            text: raw,
            problem: problem
          );
      final target = keys['${group.first}'] as String?;
      if (target == null) {
        out.add(miss('no key recorded for row ${group.first}'));
        continue;
      }
      if (target == '=source') {
        final kept = shown.every((i) {
          final t = rows[i]['text']! as String;
          return src.contains("'$t'") || src.contains('"$t"');
        });
        if (!kept) {
          out.add(miss('recorded as kept in the file, but it is gone'));
        }
        continue;
      }
      final parts = target.split('#');
      if (keyFiles[parts.first] != path) {
        out.add(miss(
            '${parts.first} belongs to ${keyFiles[parts.first] ?? 'no file'}, not $path'));
        continue;
      }
      final message = messages[branch]?[parts.first];
      if (message == null) {
        out.add(miss('${parts.first} is not in app_$branch.arb'));
        continue;
      }
      final value = parts.length > 1 ? caseBody(message, parts[1]) : message;
      if (value == null) {
        out.add(miss('$target has no such case'));
        continue;
      }
      final interpolated = group.any((i) => rows[i]['interpolated'] == true) ||
          RegExp(r'(?<!\\)\$').hasMatch(raw);
      final want = textRuns(raw, all: true);
      final got = interpolated ? messageRuns(value) : [value];
      if (want.length != got.length ||
          [for (var i = 0; i < want.length; i++) want[i] == got[i]]
              .contains(false)) {
        out.add(miss('$target is "$value"'));
      }
    }
  }
  return out;
}

/// Key → the source file its English description names (`lib/…dart: …`).
Map<String, String> keyFilesOf(Map<String, Object?> englishArb) => {
      for (final e in englishArb.entries)
        if (e.key.startsWith('@') && e.key != '@@locale')
          e.key.substring(1):
              (((e.value as Map)['description'] as String?) ?? '')
                  .split(':')
                  .first
    };

Map<String, String> _messages(String path) {
  final arb = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  return {
    for (final e in arb.entries)
      if (!e.key.startsWith('@')) e.key: e.value! as String
  };
}

void main() {
  test(
      'text from every file that left the isSpanish list equals its recorded key',
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
    final recorded =
        (jsonDecode(File('test/l10n/moved_keys.json').readAsStringSync())
            as Map<String, Object?>)['files']! as Map<String, Object?>;
    expect(recorded.keys.toSet(), moved,
        reason: 'moved_keys.json lists exactly the files that left the list');
    final missing = missingText(
      inventory: inventory,
      moved: moved,
      movedKeys:
          recorded.map((k, v) => MapEntry(k, v! as Map<String, Object?>)),
      messages: {
        'en': _messages('lib/l10n/app_en.arb'),
        'es': _messages('lib/l10n/app_es.arb')
      },
      keyFiles: keyFilesOf(
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, Object?>),
      source: (p) => File(p).existsSync() ? File(p).readAsStringSync() : '',
    );
    expect(missing, isEmpty,
        reason:
            'reworded, dropped or unrecorded on the way to the translation files');
  });

  test(
      'the backstop finds a reworded, a dropped, a retranslated and an unrecorded string',
      () {
    final inventory = {
      'files': {
        'lib/x.dart': [
          {
            'line': 1,
            'branch': 'en',
            'text': r'You chose $count reasons',
            'interpolated': true
          },
          {
            'line': 2,
            'branch': 'es',
            'text': r'Elegiste $count razones',
            'interpolated': true
          },
          {'line': 3, 'branch': 'en', 'text': 'Stays in code'},
          {'line': 4, 'branch': 'es', 'text': 'caso', 'match': true},
          {'line': 5, 'branch': 'en', 'text': "It\\'s fine"},
          {'line': 6, 'branch': 'es', 'text': 'situación'},
          {'line': 7, 'branch': 'es', 'text': 'No'},
          {'line': 8, 'branch': 'en', 'text': 'Part one, '},
          {'line': 8, 'branch': 'en', 'text': 'part two', 'joined': true},
        ],
      },
    };
    const keys = {
      '0': 'chose',
      '1': 'chose',
      '2': '=source',
      '4': 'fine',
      '5': 'count#=1',
      '6': 'no',
      '7': 'parts',
    };
    final good = {
      'en': {
        'chose': 'You chose {count} reasons',
        'fine': "It's fine",
        'parts': 'Part one, part two'
      },
      'es': {
        'chose': 'Elegiste {count} razones',
        'count': '{n, plural, =1{situación} other{situaciones}}',
        'no': 'No',
      },
    };
    final ownFiles = {
      for (final k in ['chose', 'fine', 'parts', 'count', 'no', 'other'])
        k: k == 'other' ? 'lib/y.dart' : 'lib/x.dart'
    };
    List<int> lines(Map<String, Map<String, String>> messages,
            {Map<String, Object?> recorded = keys,
            String src = "'Stays in code'",
            Map<String, String>? keyFiles}) =>
        missingText(
          inventory: inventory,
          moved: {'lib/x.dart'},
          movedKeys: {'lib/x.dart': recorded},
          messages: messages,
          keyFiles: keyFiles ?? ownFiles,
          source: (_) => src,
        ).map((m) => m.line).toList();
    Map<String, Map<String, String>> edit(
            String lang, String key, String value) =>
        {
          for (final e in good.entries)
            e.key: {...e.value, if (e.key == lang) key: value}
        };
    expect(lines(good), isEmpty);
    expect(lines(edit('en', 'chose', 'You picked {count} reasons')), [1]);
    expect(lines(edit('es', 'chose', 'Escogiste {count} razones')), [2]);
    expect(lines(edit('es', 'no', 'No.')), [7]);
    expect(lines(edit('es', 'no', 'No te juzgamos')), [7]);
    expect(
        lines(edit(
            'es', 'count', '{n, plural, =1{situaciones} other{situaciones}}')),
        [6]);
    expect(lines(edit('en', 'parts', 'Part one, part 2')), [8]);
    expect(lines(good, src: ''), [3]);
    expect(lines(good, recorded: {...keys}..remove('6')), [7]);
    // A key from another screen with the same text is not accepted.
    final borrowed = {
      'en': {...good['en']!},
      'es': {...good['es']!, 'other': 'No'},
    };
    expect(lines(borrowed, recorded: {...keys, '6': 'other'}), [7]);
    expect(lines(good, keyFiles: {...ownFiles, 'no': 'lib/y.dart'}), [7]);
    expect(
        textRuns(r'Hola ${name.trim()}, ¿qué tal?'), ['Hola ', ', ¿qué tal?']);
    expect(messageRuns('{a} y {n, plural, one{x} other{y}} más'),
        ['', ' y ', ' más']);
  });
}
