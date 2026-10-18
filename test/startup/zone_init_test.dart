import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Guards the startup order in lib/main.dart: the binding must be initialised
// inside the runZonedGuarded body, in the same zone that later calls runApp.
// Initialising it before the zone makes Flutter's debugCheckZone report a zone
// mismatch at runApp.
//
// This is a source-structure test, not a behavioural one. Under flutter test
// the test binding is already initialised, in the test's own zone, before any
// test code runs, so calling main() would make ensureInitialized a no-op
// wherever it sits and the zone mismatch could not be observed. The test reads
// lib/main.dart with comments and string literals blanked out, finds the body
// of main(), and checks where the calls sit.

const _ensureInitialized = 'WidgetsFlutterBinding.ensureInitialized(';

/// Returns [source] with every comment and string literal replaced by spaces,
/// so offsets are preserved and brackets inside them are not counted.
String _codeOnly(String source) {
  final out = StringBuffer();
  var i = 0;
  void blank(int end) {
    for (; i < end; i++) {
      out.write(source[i] == '\n' ? '\n' : ' ');
    }
  }

  while (i < source.length) {
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      blank(end == -1 ? source.length : end);
    } else if (source.startsWith('/*', i)) {
      final end = source.indexOf('*/', i + 2);
      blank(end == -1 ? source.length : end + 2);
    } else if (source[i] == "'" || source[i] == '"') {
      final raw = i > 0 && source[i - 1] == 'r';
      final quote =
          source.startsWith(source[i] * 3, i) ? source[i] * 3 : source[i];
      var j = i + quote.length;
      while (j < source.length && !source.startsWith(quote, j)) {
        j += !raw && source[j] == r'\' ? 2 : 1;
      }
      blank(
          j + quote.length > source.length ? source.length : j + quote.length);
    } else {
      out.write(source[i]);
      i++;
    }
  }
  return out.toString();
}

/// Index of the bracket that closes the one at [open] in [code].
int _matching(String code, int open) {
  final pairs = {'(': ')', '{': '}', '[': ']'};
  final stack = <String>[];
  for (var i = open; i < code.length; i++) {
    final c = code[i];
    if (pairs.containsKey(c)) {
      stack.add(pairs[c]!);
    } else if (pairs.containsValue(c)) {
      if (stack.isEmpty || stack.removeLast() != c) {
        throw StateError('unbalanced "$c" at offset $i');
      }
      if (stack.isEmpty) return i;
    }
  }
  throw StateError('no match for "${code[open]}" at offset $open');
}

/// Offset of the first top-level comma in code[start, end).
int _firstTopLevelComma(String code, int start, int end) {
  var depth = 0;
  for (var i = start; i < end; i++) {
    final c = code[i];
    if ('({['.contains(c)) depth++;
    if (')}]'.contains(c)) depth--;
    if (c == ',' && depth == 0) return i;
  }
  return end;
}

List<int> _allIndexes(String code, String needle, int start, int end) => [
      for (var i = code.indexOf(needle, start);
          i != -1 && i < end;
          i = code.indexOf(needle, i + 1))
        i,
    ];

void main() {
  late String code;
  late int bodyStart;
  late int bodyEnd;
  late int zoneStart;
  late int zoneEnd;
  late int zoneBodyEnd;

  setUpAll(() {
    code = _codeOnly(File('lib/main.dart').readAsStringSync());
    final header = RegExp(r'\bmain\s*\(\s*\)\s*(async\s*)?\{').firstMatch(code);
    expect(header, isNotNull, reason: 'lib/main.dart has no main() body');
    bodyStart = header!.end - 1;
    bodyEnd = _matching(code, bodyStart);

    final zone = _allIndexes(code, 'runZonedGuarded(', bodyStart, bodyEnd);
    expect(zone, hasLength(1),
        reason: 'main() must call runZonedGuarded exactly once');
    zoneStart = zone.single;
    final open = zoneStart + 'runZonedGuarded'.length;
    zoneEnd = _matching(code, open);
    zoneBodyEnd = _firstTopLevelComma(code, open + 1, zoneEnd);
  });

  test('ensureInitialized is called in the runZonedGuarded body', () {
    final inZoneBody =
        _allIndexes(code, _ensureInitialized, zoneStart, zoneBodyEnd);
    expect(inZoneBody, isNotEmpty,
        reason: 'WidgetsFlutterBinding.ensureInitialized() must be called '
            'inside the body passed to runZonedGuarded in main()');
  });

  test('main() does not initialise the binding or run the app outside the zone',
      () {
    for (final call in [_ensureInitialized, 'runApp(']) {
      final outside = [
        ..._allIndexes(code, call, bodyStart, zoneStart),
        ..._allIndexes(code, call, zoneEnd, bodyEnd),
      ];
      expect(outside, isEmpty,
          reason: '$call must not be called in main() outside '
              'runZonedGuarded');
    }
  });

  group('source reader', () {
    test('blanks comments and strings but keeps offsets', () {
      const source = "a('x(', /* ( */ b) // ) \n{ r'\\' }";
      final result = _codeOnly(source);
      expect(result.length, source.length);
      expect(result, isNot(contains('x')));
      expect(_matching(result, 1), source.indexOf(')', 15));
      expect(_matching(result, result.indexOf('{')), source.length - 1);
    });
  });
}
