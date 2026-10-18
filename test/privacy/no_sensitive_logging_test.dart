import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// Guard for TH-045: no health detail, free text, email, phone or name may
/// reach debug logs or crash output from `lib/`.
///
/// Rules (see `scanDartSource`):
///  * R1  `print(` is banned everywhere in lib/. No allow-list.
///  * R2  every other log sink is banned outside [kAllowedSinkLines].
///  * R3  the arguments of every sink call (allow-listed ones included) must
///        not mention health/identity fields (R3a), raw exception objects
///        (R3b) or message/body serialisers (R3c).
///  * R4  `toString()` overrides must not mention health/identity fields or
///        message/body serialisers.

/// The only place in lib/ allowed to write to a log. The line must match
/// exactly (after trimming) and may occur at most once in the file.
const Map<String, List<String>> kAllowedSinkLines = {
  'lib/error/privacy_safe_error_reporter.dart': [
    r"debugPrint('BreatheFree technical error: $source/${error.runtimeType}');",
  ],
};

/// Model and identity fields that must never be interpolated into a sink or a
/// `toString()`. Derived from the models under lib/ (see TH-045 ticket).
const Set<String> kHealthAndIdentityFields = {
  // Quit plan
  'dailyCigaretteUse', 'smokingTriggers', 'customSmokingTrigger',
  'readinessPath', 'quitPlanPath', 'quitDate', 'quitDayCheckIn',
  'quitReasons', 'customQuitReason', 'topQuitReason', 'supportPeople',
  'preparationTasks', 'treatmentSupport', 'careTeamReminder', 'name',
  'relationship', 'channel', 'checkIn',
  // Daily / rescue state
  'completedPreparationTasks', 'dailyMood', 'dailySmokingStatus',
  'dailySymptoms', 'dailyOtherSymptom', 'nextStepStrategyOverride',
  'copingPlanStrategies', 'stressResetHelpfulChoice', 'rescueHelpfulChoice',
  'rescueContexts', 'rescueTool', 'medicationTodayStatus',
  // Slip recovery
  'whatHappened', 'whenChoice', 'triggers', 'recoveryChoice',
  'selectedWhatHappened', 'selectedWhen',
  // ClearAir
  'zone', 'recordedBy', 'recordedAt', 'note', 'symptoms', 'peakFlow',
  'symptomLogs', 'clinicianPlan',
  // HeartWise
  'systolic', 'diastolic', 'measuredAt', 'ldlMgDl', 'hdlMgDl',
  'triglyceridesMgDl', 'totalMgDl', 'bpReadings', 'panels',
  'cholesterolPanels', 'latestBpReading', 'latestPanel',
  // Steady
  'valueMgDl', 'context', 'minMgDl', 'maxMgDl', 'setBy', 'readings',
  'latestReading', 'targetRange',
  // Program documents
  'payload', 'document', 'draft', 'local', 'remote',
  // Identity and credentials
  'email', 'accountEmail', 'confirmationEmail', 'password', 'displayName',
  'avatarPath', 'avatarUrl', 'accessToken', 'refreshToken', 'userId',
  'phone', 'phoneNumber',
  // TH-020 spec layer
  'values', 'value', 'selection', 'selectedPrograms', 'healthArea',
};

/// Names that usually hold a raw exception or stack. Only
/// `<name>.runtimeType` is safe to interpolate.
const Set<String> kRawErrorNames = {
  'e',
  'err',
  'error',
  'exception',
  'ex',
  'stack',
  'stacktrace',
  'st',
  'details',
};

const Set<String> kSerialiserTokens = {
  'tostring',
  'message',
  'body',
  'jsonencode',
};

class Violation {
  const Violation(this.path, this.line, this.rule, this.snippet);

  final String path;
  final int line;
  final String rule;
  final String snippet;

  @override
  String toString() => '$path:$line $rule  $snippet';
}

String _norm(String token) =>
    token.replaceFirst(RegExp(r'^_+'), '').toLowerCase();

final Set<String> _healthTokens = kHealthAndIdentityFields.map(_norm).toSet();
final Set<String> _rawErrorTokens = kRawErrorNames.map(_norm).toSet();

final RegExp _identifier = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');
final RegExp _identChar = RegExp(r'[A-Za-z0-9_$]');

// R1. Matches the identifier `print` (calls and tear-offs such as
// `xs.forEach(print)`), but not a named argument `print: true`. `debugPrint`
// does not match because of the capital P.
final RegExp _printCall =
    RegExp(r'(?<![A-Za-z0-9_$])print(?![A-Za-z0-9_$])(?!\s*:)');

// R2 sinks matched on code with string contents masked. R3 checks the
// arguments of the call that each match opens or is followed by.
final List<RegExp> _sinkPatterns = [
  RegExp(r'(?<![A-Za-z0-9_$])debugPrint(?![A-Za-z0-9_$])(?!\s*:)'),
  RegExp(r'debugPrintSynchronously'),
  RegExp(r'debugPrintThrottled'),
  RegExp(r'debugPrintStack\s*\('),
  RegExp(r'developer\.log\s*\('),
  RegExp(r'(?<![A-Za-z0-9_.$])log\s*\('),
  RegExp(r'\bstdout\.'),
  RegExp(r'\bstderr\.'),
  RegExp(r'(?<![A-Za-z0-9_])Logger\s*\('),
  RegExp(r'FlutterError\s*\.\s*(presentError|dumpErrorToConsole)\b'),
  RegExp(r'\bdebugDump\w*\s*\('),
];

// R2 sinks that live inside import strings, so matched with strings intact.
final List<RegExp> _importSinkPatterns = [
  RegExp(r'dart:developer'),
  RegExp(r'package:logging/'),
  RegExp(r'package:logger/'),
];

// Return type is optional; the `=>` or `{` must follow so plain calls such as
// `x.toString()` do not match.
final RegExp _toStringOverride = RegExp(
  r'(?<![A-Za-z0-9_$.])(?:String\s+)?toString\s*\(\s*\)\s*(?:=>|\{)',
);

class _Span {
  const _Span(this.end, this.code, this.interpolations);

  /// Index of the closing delimiter (or of the stop character).
  final int end;

  /// Source between the delimiters with string literals removed.
  final String code;

  /// Full text of every `$name` / `${...}` interpolation in the span.
  final List<String> interpolations;
}

bool _isRawQuote(String s, int i) =>
    i > 0 && s[i - 1] == 'r' && (i < 2 || !_identChar.hasMatch(s[i - 2]));

/// Returns the index just past the string literal starting at [start],
/// appending every interpolation expression to [interps] when given.
int _skipString(String s, int start, List<String>? interps) {
  final quote = s[start];
  final triple = s.startsWith(quote * 3, start);
  final raw = _isRawQuote(s, start);
  final close = triple ? quote * 3 : quote;
  var i = start + close.length;
  while (i < s.length) {
    final c = s[i];
    if (!raw && c == r'\') {
      i += 2;
      continue;
    }
    if (s.startsWith(close, i)) {
      return i + close.length;
    }
    if (!raw && c == r'$' && i + 1 < s.length) {
      final next = s[i + 1];
      if (next == '{') {
        final span = _scan(s, i + 2);
        interps?.add(s.substring(i + 2, span.end).trim());
        interps?.addAll(span.interpolations);
        i = span.end + 1;
        continue;
      }
      if (RegExp(r'[A-Za-z_]').hasMatch(next)) {
        var j = i + 1;
        while (j < s.length && RegExp(r'[A-Za-z0-9_]').hasMatch(s[j])) {
          j++;
        }
        interps?.add(s.substring(i + 1, j));
        i = j;
        continue;
      }
    }
    i++;
  }
  return s.length;
}

/// Scans from [from] (just after an opening delimiter) up to the unmatched
/// closing delimiter, or up to a top-level `;` when [stopAtSemicolon] is set.
_Span _scan(String s, int from, {bool stopAtSemicolon = false}) {
  final code = StringBuffer();
  final interps = <String>[];
  var depth = 0;
  var i = from;
  while (i < s.length) {
    final c = s[i];
    if (c == "'" || c == '"') {
      i = _skipString(s, i, interps);
      code.write(' ');
      continue;
    }
    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) {
        return _Span(i, code.toString(), interps);
      }
      depth--;
    } else if (stopAtSemicolon && depth == 0 && c == ';') {
      return _Span(i, code.toString(), interps);
    }
    code.write(c);
    i++;
  }
  return _Span(s.length, code.toString(), interps);
}

String _blankOut(String text) => text.replaceAll(RegExp(r'[^\n]'), ' ');

/// Appends [s] from [start] (a quote) to [out] with the literal text blanked
/// but every `${...}` body kept (and sanitised recursively), so code hidden in
/// an interpolation is still scanned. Returns the index past the literal.
int _maskString(String s, int start, StringBuffer out) {
  final quote = s[start];
  final triple = s.startsWith(quote * 3, start);
  final raw = _isRawQuote(s, start);
  final close = triple ? quote * 3 : quote;
  void blank(String text) => out.write(_blankOut(text));
  blank(close);
  var i = start + close.length;
  while (i < s.length) {
    final c = s[i];
    if (!raw && c == r'\') {
      blank(s.substring(i, math.min(i + 2, s.length)));
      i += 2;
      continue;
    }
    if (s.startsWith(close, i)) {
      blank(close);
      return i + close.length;
    }
    if (!raw && c == r'$' && i + 1 < s.length && s[i + 1] == '{') {
      blank(r'${');
      i = _sanitizeInto(s, i + 2, out, mask: true, untilBrace: true);
      blank('}');
      i++;
      continue;
    }
    blank(c);
    i++;
  }
  return s.length;
}

/// Copies code from [from] into [out] with comments replaced by spaces and,
/// when [mask] is set, string literal text too. With [untilBrace] it stops at
/// the unmatched `}` that ends an interpolation and returns its index.
int _sanitizeInto(
  String s,
  int from,
  StringBuffer out, {
  required bool mask,
  bool untilBrace = false,
}) {
  var i = from;
  var depth = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == "'" || c == '"') {
      if (mask) {
        i = _maskString(s, i, out);
      } else {
        final end = _skipString(s, i, null);
        out.write(s.substring(i, end));
        i = end;
      }
    } else if (s.startsWith('//', i)) {
      var end = s.indexOf('\n', i);
      if (end == -1) {
        end = s.length;
      }
      out.write(' ' * (end - i));
      i = end;
    } else if (s.startsWith('/*', i)) {
      var j = i + 2;
      var nesting = 1;
      while (j < s.length && nesting > 0) {
        if (s.startsWith('/*', j)) {
          nesting++;
          j += 2;
        } else if (s.startsWith('*/', j)) {
          nesting--;
          j += 2;
        } else {
          j++;
        }
      }
      out.write(_blankOut(s.substring(i, j)));
      i = j;
    } else {
      if (untilBrace) {
        if (c == '{') {
          depth++;
        } else if (c == '}') {
          if (depth == 0) {
            return i;
          }
          depth--;
        }
      }
      out.write(c);
      i++;
    }
  }
  return s.length;
}

/// Replaces comments (block, whole-line and trailing `//`) with spaces, and,
/// when [maskStrings] is set, the text of string literals too (interpolation
/// bodies are kept). Newlines are kept so line numbers stay correct.
String _sanitize(String s, {required bool maskStrings}) {
  final out = StringBuffer();
  _sanitizeInto(s, 0, out, mask: maskStrings);
  return out.toString();
}

/// Index of the `(` that opens the call following [from], or -1 if a `;` or
/// brace comes first.
int _findOpenParen(String code, int from) {
  for (var i = from; i < code.length; i++) {
    final c = code[i];
    if (c == '(') {
      return i;
    }
    if (c == ';' || c == '{' || c == '}' || c == ')') {
      return -1;
    }
  }
  return -1;
}

/// Turns `error.runtimeType` into `runtimeType` for raw-error names, which is
/// the one safe way to mention an exception.
String _stripSafeRuntimeType(String text) => text.replaceAllMapped(
      RegExp(r'(?<![A-Za-z0-9_.$])([A-Za-z_]\w*)\s*\.\s*runtimeType\b'),
      (m) => _rawErrorTokens.contains(_norm(m[1]!)) ? 'runtimeType' : m[0]!,
    );

Set<String> _tokens(String text) =>
    _identifier.allMatches(text).map((m) => _norm(m[0]!)).toSet();

String _snippet(String line) {
  final trimmed = line.trim();
  return trimmed.length <= 120 ? trimmed : trimmed.substring(0, 120);
}

List<Violation> scanDartSource(String path, String source) {
  final text = _sanitize(source, maskStrings: false);
  final code = _sanitize(source, maskStrings: true);
  final originalLines = source.split('\n');
  final textLines = text.split('\n');
  final found = <String, Violation>{};

  int lineOf(int offset) => '\n'.allMatches(text.substring(0, offset)).length;

  void add(int offset, String rule) {
    final line = lineOf(offset);
    found.putIfAbsent(
      '$line:$rule',
      () => Violation(path, line + 1, rule, _snippet(originalLines[line])),
    );
  }

  // R1
  for (final m in _printCall.allMatches(code)) {
    add(m.start, 'R1');
  }

  // R2
  final sinkMatches = <RegExpMatch>[];
  final sinkLines = <int>{};
  for (final pattern in _sinkPatterns) {
    for (final m in pattern.allMatches(code)) {
      sinkMatches.add(m);
      sinkLines.add(lineOf(m.start));
    }
  }
  for (final pattern in _importSinkPatterns) {
    for (final m in pattern.allMatches(text)) {
      sinkLines.add(lineOf(m.start));
    }
  }
  final allowed = kAllowedSinkLines[path] ?? const <String>[];
  final allowedUsed = <String>{};
  for (final line in sinkLines.toList()..sort()) {
    final trimmed = textLines[line].trim();
    if (allowed.contains(trimmed) && allowedUsed.add(trimmed)) {
      continue;
    }
    final offset =
        textLines.take(line).fold<int>(0, (sum, l) => sum + l.length + 1);
    add(offset, 'R2');
  }

  // R3, on every sink call including allow-listed ones.
  for (final m in sinkMatches) {
    // Tear-offs such as `xs.forEach(print)` have no argument span.
    final open =
        m.group(0)!.endsWith('(') ? m.end - 1 : _findOpenParen(code, m.end);
    if (open < 0) {
      continue;
    }
    final span = _scan(text, open + 1);
    final tokens = <String>{..._tokens(_stripSafeRuntimeType(span.code))};
    for (final expr in span.interpolations) {
      final safeOnly = RegExp(r'^[A-Za-z_]\w*\s*\.\s*runtimeType$');
      tokens.addAll(_tokens(
          safeOnly.hasMatch(expr) ? _stripSafeRuntimeType(expr) : expr));
    }
    if (tokens.any(_healthTokens.contains)) {
      add(m.start, 'R3a');
    }
    if (tokens.any(_rawErrorTokens.contains)) {
      add(m.start, 'R3b');
    }
    if (tokens.any(kSerialiserTokens.contains)) {
      add(m.start, 'R3c');
    }
  }

  // R4
  for (final m in _toStringOverride.allMatches(code)) {
    final _Span span = m.group(0)!.endsWith('{')
        ? _scan(text, m.end)
        : _scan(text, m.end, stopAtSemicolon: true);
    final tokens = <String>{..._tokens(span.code)};
    for (final expr in span.interpolations) {
      tokens.addAll(_tokens(expr));
    }
    if (tokens.any(_healthTokens.contains) ||
        tokens.any(kSerialiserTokens.contains)) {
      add(m.start, 'R4');
    }
  }

  final result = found.values.toList()
    ..sort((a, b) {
      final byLine = a.line.compareTo(b.line);
      return byLine != 0 ? byLine : a.rule.compareTo(b.rule);
    });
  return result;
}

List<String> _rules(String path, String source) =>
    scanDartSource(path, source).map((v) => v.rule).toList();

void main() {
  const reporterPath = 'lib/error/privacy_safe_error_reporter.dart';
  const pinnedLine =
      r"debugPrint('BreatheFree technical error: $source/${error.runtimeType}');";

  group('scanner self-test (seeded violations)', () {
    test('print( is R1', () {
      expect(
        _rules('lib/x.dart', "void f() { print('hello'); }"),
        ['R1'],
      );
    });

    test('plain debugPrint is R2', () {
      expect(_rules('lib/x.dart', "debugPrint('x');"), ['R2']);
    });

    test('debugPrint with an interpolated exception is R2 + R3b', () {
      expect(
        _rules('lib/x.dart', r"debugPrint('failed: $e');"),
        unorderedEquals(['R2', 'R3b']),
      );
    });

    test('bare exception argument is R3b', () {
      expect(
        _rules('lib/x.dart', 'debugPrint(e);'),
        unorderedEquals(['R2', 'R3b']),
      );
    });

    test('multi-line debugPrint with a health field is R2 + R3a', () {
      const source = '''
debugPrint(
  'plan \${plan.quitDate}',
);
''';
      final violations = scanDartSource('lib/x.dart', source);
      expect(
        violations.map((v) => v.rule),
        unorderedEquals(['R2', 'R3a']),
      );
      expect(violations.every((v) => v.line == 1), isTrue);
    });

    test('dart:developer and developer.log are R2', () {
      const source = '''
import 'dart:developer' as developer;
void f() => developer.log('x');
''';
      final rules = _rules('lib/x.dart', source);
      expect(rules, contains('R2'));
      expect(rules.where((r) => r == 'R2').length, 2);
    });

    test('reporter path: any edit to the pinned line fails', () {
      expect(
        _rules(
          reporterPath,
          r"debugPrint('BreatheFree technical error: $source/${reading.systolic}');",
        ),
        unorderedEquals(['R2', 'R3a']),
      );
    });

    test('reporter path: a second sink line fails', () {
      expect(
        _rules(reporterPath, '$pinnedLine\n$pinnedLine'),
        ['R2'],
      );
    });

    test('toString override with a health field is R4', () {
      expect(
        _rules('lib/x.dart', r"String toString() => 'Reading $systolic';"),
        ['R4'],
      );
      expect(
        _rules(
          'lib/x.dart',
          "String toString() {\n  return 'Reading \${reading.diastolic}';\n}",
        ),
        ['R4'],
      );
    });

    test('collection access by a health key inside a sink is R3a', () {
      expect(
        _rules('lib/x.dart', r"debugPrint('a ${map['email']}');"),
        unorderedEquals(['R2', 'R3a']),
      );
    });

    group('tear-offs, extra sinks and interpolated code', () {
      test('print and debugPrint tear-offs are flagged', () {
        expect(_rules('lib/x.dart', 'xs.forEach(print);'), ['R1']);
        expect(_rules('lib/x.dart', 'xs.forEach(debugPrint);'), ['R2']);
        expect(
          _rules('lib/x.dart', "final say = debugPrint;\nsay('hi');"),
          ['R2'],
        );
      });

      test('FlutterError console sinks and debugDump* are R2', () {
        expect(_rules('lib/x.dart', 'FlutterError.presentError(d);'), ['R2']);
        expect(
          _rules('lib/x.dart', 'FlutterError.dumpErrorToConsole(d);'),
          ['R2'],
        );
        expect(_rules('lib/x.dart', 'debugDumpApp();'), ['R2']);
      });

      test('print inside an interpolated closure is still R1', () {
        expect(
          _rules(
            'lib/x.dart',
            r"final s = '${(() { print(email); return ''; })()}';",
          ),
          contains('R1'),
        );
      });
    });

    group('every rule has a positive self-test', () {
      test('R3c serialisers inside a sink', () {
        for (final arg in [
          'x.toString()',
          'x.message',
          'res.body',
          'jsonEncode(x)',
        ]) {
          expect(
            _rules('lib/x.dart', 'debugPrint($arg);'),
            contains('R3c'),
            reason: arg,
          );
        }
      });

      test('other log sinks are R2', () {
        for (final source in [
          "stdout.writeln('x');",
          "stderr.writeln('x');",
          "final l = Logger('x');",
          "import 'package:logging/logging.dart';",
          "import 'package:logger/logger.dart';",
          "debugPrintStack(label: 'x');",
          "debugPrintSynchronously('x');",
          "log('x');",
        ]) {
          expect(_rules('lib/x.dart', source), ['R2'], reason: source);
        }
      });

      test('R4 without a return type and with serialiser tokens', () {
        expect(
          _rules('lib/x.dart', r"toString() => 'Reading $systolic';"),
          ['R4'],
        );
        expect(
          _rules('lib/x.dart', 'String toString() => jsonEncode(toJson());'),
          ['R4'],
        );
        expect(
          _rules('lib/x.dart', 'String toString() {\n  return message;\n}'),
          ['R4'],
        );
      });
    });

    group('negative controls', () {
      test('named print argument is not a tear-off', () {
        expect(_rules('lib/x.dart', 'final f = Foo(print: true);'), isEmpty);
      });

      test('trailing comment, raw string and triple-quoted string', () {
        expect(_rules('lib/x.dart', "final x = 1; // print('x');"), isEmpty);
        expect(_rules('lib/x.dart', r"final s = r'print($x)';"), isEmpty);
        expect(
          _rules('lib/x.dart', "final s = '''\nprint(x)\n''';"),
          isEmpty,
        );
      });

      test('math.log is not a sink', () {
        expect(_rules('lib/x.dart', 'final y = math.log(2);'), isEmpty);
      });

      test('commented-out print is ignored', () {
        expect(_rules('lib/x.dart', "// print('x');"), isEmpty);
        expect(_rules('lib/x.dart', "/* print('x');\n debugPrint(e); */"),
            isEmpty);
      });

      test('print( inside a string literal is ignored', () {
        expect(_rules('lib/x.dart', "final s = 'print(x)';"), isEmpty);
      });

      test('health field outside any sink is fine', () {
        expect(_rules('lib/x.dart', r"Text('${zone.name}')"), isEmpty);
      });

      test('the exact pinned reporter line passes in the reporter path', () {
        expect(_rules(reporterPath, pinnedLine), isEmpty);
      });

      test('error.runtimeType does not trip R3', () {
        final rules =
            _rules('lib/x.dart', r"debugPrint('x ${error.runtimeType}');");
        expect(rules.where((r) => r.startsWith('R3')), isEmpty);
        expect(rules, ['R2']);
      });

      test('toString using only statusCode passes', () {
        expect(
          _rules('lib/x.dart', r"String toString() => 'Failed ($statusCode)';"),
          isEmpty,
        );
      });
    });
  });

  test('lib/ contains no sensitive logging', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    final paths = files.map((f) => f.path.replaceAll(r'\', '/')).toList();

    // Anti-vacuous checks.
    expect(files.length, greaterThan(50));
    expect(paths, contains(reporterPath));

    final violations = <Violation>[];
    for (var i = 0; i < files.length; i++) {
      violations.addAll(
        scanDartSource(paths[i], files[i].readAsStringSync()),
      );
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
