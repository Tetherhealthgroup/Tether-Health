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
  bool quotedIn(String text, String code) =>
      code.contains("'$text'") || code.contains('"$text"');
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
      // A text that is only interpolations has nothing to compare unless a
      // key was recorded for it.
      if (target == null && textRuns(raw).isEmpty) continue;
      if (target == null) {
        out.add(miss('no key recorded for row ${group.first}'));
        continue;
      }
      if (target == '=source' || target.startsWith('=source:')) {
        final where = target == '=source' ? path : target.substring(8);
        final code = where == path ? src : source(where);
        if (!shown.every((i) => quotedIn(rows[i]['text']! as String, code))) {
          out.add(miss('recorded as kept in $where, but it is gone'));
        }
        continue;
      }
      // A word of a composed message: it must be a whole word of the key's
      // value in its language.
      final part = target.endsWith('^');
      final parts =
          (part ? target.substring(0, target.length - 1) : target).split('#');
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
      if (part) {
        final word = textRuns(raw, all: true).join();
        final found = RegExp(
                '(?<![\\p{L}\\p{N}_])${RegExp.escape(word)}(?![\\p{L}\\p{N}_])',
                unicode: true)
            .hasMatch(message);
        if (!found) out.add(miss('${parts.first} does not contain "$word"'));
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

/// The interpolation expressions of the literal body [raw], in order, with
/// string text inside them removed (so the two languages' versions of
/// `x ? ('On') : ('Off')` compare equal) and spaces collapsed.
List<String> interpolations(String raw) {
  final out = <String>[];
  for (var i = 0; i < raw.length; i++) {
    if (raw[i] == r'\') {
      i++;
      continue;
    }
    if (raw[i] != r'$' || i + 1 >= raw.length) continue;
    String expr;
    if (raw[i + 1] == '{') {
      var depth = 1;
      var j = i + 2;
      while (j < raw.length && depth > 0) {
        if (raw[j] == '{') depth++;
        if (raw[j] == '}') depth--;
        j++;
      }
      expr = raw.substring(i + 2, j - 1);
      i = j - 1;
    } else {
      final m = RegExp(r'[A-Za-z_]\w*').matchAsPrefix(raw, i + 1);
      if (m == null) continue;
      expr = m.group(0)!;
      i = m.end - 1;
    }
    out.add(expr
        .replaceAll(RegExp(r"'[^']*'"), "''")
        .replaceAll(RegExp(r'"[^"]*"'), "''")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim());
  }
  return out;
}

/// The names of the top-level placeholders and arguments of [message], in
/// order of appearance.
List<String> placeholderOrder(String message) {
  final out = <String>[];
  var depth = 0;
  for (var i = 0; i < message.length; i++) {
    if (message[i] == '{') {
      if (depth == 0) {
        out.add(RegExp(r'\s*(\w+)').matchAsPrefix(message, i + 1)!.group(1)!);
      }
      depth++;
    } else if (message[i] == '}') {
      depth--;
    }
  }
  return out;
}

/// Problems with the composed messages in [composed] (file → key →
/// language → the old joined literal): each message must keep the old text
/// between its placeholders, its placeholders must stand where the old
/// expressions stood, and the English placeholders must appear in their
/// declared order ([declared], key → placeholder names), which is the order
/// the code passes them in.
List<String> composedProblems({
  required Map<String, Object?> composed,
  required Map<String, Map<String, String>> messages,
  required Map<String, List<String>> declared,
}) {
  final out = <String>[];
  for (final file in composed.values) {
    for (final e in (file! as Map<String, Object?>).entries) {
      final key = e.key;
      final old = (e.value! as Map).cast<String, String>();
      final en = messages['en']?[key];
      final es = messages['es']?[key];
      if (en == null || es == null) {
        out.add('$key is missing from a language');
        continue;
      }
      for (final (lang, value) in [('en', en), ('es', es)]) {
        final want = textRuns(old[lang]!, all: true);
        final got = messageRuns(value);
        if (want.length != got.length ||
            [for (var i = 0; i < want.length; i++) want[i] == got[i]]
                .contains(false)) {
          out.add('$key ($lang) "$value" no longer reads as "${old[lang]}"');
        }
      }
      final enExprs = interpolations(old['en']!);
      final enNames = placeholderOrder(en);
      if (enExprs.length != enNames.length) {
        out.add(
            '$key (en) has ${enNames.length} placeholders for ${enExprs.length} values');
        continue;
      }
      if (enNames.join(',') != (declared[key] ?? const []).join(',')) {
        out.add(
            '$key (en) placeholders $enNames are not in their declared order ${declared[key]}');
      }
      final name = {
        for (var i = 0; i < enExprs.length; i++) enExprs[i]: enNames[i]
      };
      final esWant = [
        for (final x in interpolations(old['es']!)) name[x] ?? '?$x'
      ];
      if (esWant.join(',') != placeholderOrder(es).join(',')) {
        out.add(
            '$key (es) placeholders ${placeholderOrder(es)} should be $esWant');
      }
    }
  }
  return out;
}

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

  test('composed messages keep the old composition in both languages', () {
    final recorded =
        jsonDecode(File('test/l10n/moved_keys.json').readAsStringSync())
            as Map<String, Object?>;
    final english = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, Object?>;
    final declared = {
      for (final e in english.entries)
        if (e.key.startsWith('@') && e.key != '@@locale')
          e.key.substring(1): [
            ...(((e.value as Map)['placeholders'] as Map?) ?? const {})
                .keys
                .cast<String>()
          ]
    };
    expect(
        composedProblems(
          composed: recorded['composed']! as Map<String, Object?>,
          messages: {
            'en': _messages('lib/l10n/app_en.arb'),
            'es': _messages('lib/l10n/app_es.arb')
          },
          declared: declared,
        ),
        isEmpty);
  });

  test('the composition check finds moved words and swapped placeholders', () {
    final composed = {
      'lib/x.dart': {
        'left': {'en': r'$time LEFT', 'es': r'$time RESTANTE'},
        'step': {'en': r'STEP $n OF 3 · $name', 'es': r'PASO $n DE 3 · $name'},
        'voice': {
          'en': r"Voice\n${on ? ('On') : ('Off')}",
          'es': r"Voz\n${on ? ('Sí') : ('No')}"
        },
      },
    };
    const declared = {
      'left': ['time'],
      'step': ['n', 'name'],
      'voice': ['state'],
    };
    final good = {
      'en': {
        'left': '{time} LEFT',
        'step': 'STEP {n} OF 3 · {name}',
        'voice': 'Voice\n{state}'
      },
      'es': {
        'left': '{time} RESTANTE',
        'step': 'PASO {n} DE 3 · {name}',
        'voice': 'Voz\n{state}'
      },
    };
    List<String> check(String lang, String key, String value) =>
        composedProblems(
          composed: composed,
          messages: {
            for (final e in good.entries)
              e.key: {...e.value, if (e.key == lang) key: value}
          },
          declared: declared,
        );
    expect(check('en', 'left', '{time} LEFT'), isEmpty);
    expect(check('en', 'left', 'LEFT {time}'), isNotEmpty);
    expect(check('es', 'left', '{time} RESTANTES'), isNotEmpty);
    expect(check('en', 'step', 'STEP {name} OF 3 · {n}'), isNotEmpty);
    expect(check('es', 'step', 'PASO {name} DE 3 · {n}'), isNotEmpty);
    expect(check('en', 'step', 'STEP {n} OF 4 · {name}'), isNotEmpty);
    expect(check('es', 'voice', 'Voz: {state}'), isNotEmpty);
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

    // A word of a composed message, and a literal kept in another file.
    final composed = {
      'files': {
        'lib/x.dart': [
          {'line': 1, 'branch': 'es', 'text': 'PASO'},
          {'line': 1, 'branch': 'en', 'text': 'STEP'},
          {'line': 2, 'branch': 'es', 'text': 'es-US'},
        ],
      },
    };
    List<int> composedLines(String es, {String other = "'es-US'"}) =>
        missingText(
          inventory: composed,
          moved: {'lib/x.dart'},
          movedKeys: {
            'lib/x.dart': {
              '0': 'step^',
              '1': 'step^',
              '2': '=source:lib/z.dart'
            }
          },
          messages: {
            'en': {'step': 'STEP {n} OF 3'},
            'es': {'step': es},
          },
          keyFiles: {'step': 'lib/x.dart'},
          source: (p) => p == 'lib/z.dart' ? other : '',
        ).map((m) => m.line).toList();
    expect(composedLines('PASO {n} DE 3'), isEmpty);
    expect(composedLines('PASOS {n} DE 3'), [1]);
    expect(composedLines('PASO {n} DE 3', other: ''), [2]);
    expect(
        textRuns(r'Hola ${name.trim()}, ¿qué tal?'), ['Hola ', ', ¿qué tal?']);
    expect(messageRuns('{a} y {n, plural, one{x} other{y}} más'),
        ['', ' y ', ' más']);
  });
}
