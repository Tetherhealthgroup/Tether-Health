// The files still allowed to choose their text with `isSpanish`. Each ticket
// that moves a file's text into the translation files removes that file
// from [isSpanishFiles] in the same change; the list only ever shrinks, and
// the last ticket empties it. The language mapping itself
// (lib/l10n/app_locale.dart) is not text selection and stays.
//
// Choosing text means using isSpanish as a condition (`isSpanish ? … : …`,
// `if (isSpanish)`, `!isSpanish`, `isSpanish &&`) or handing it to a helper
// that picks between texts (`localized(isSpanish, english, spanish)`). Until the last ticket a
// moved screen still takes an isSpanish parameter, passes it on and asserts
// it matches the app locale; none of that is a condition.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const isSpanishFiles = <String>{
  'lib/screens/approved_screen_player.dart',
  'lib/screens/craving_recheck_screen.dart',
  'lib/screens/daily_check_in_screen.dart',
  'lib/screens/exercise_complete_recheck_screen.dart',
  'lib/screens/home_preparation_screen.dart',
  'lib/screens/learn_library_screen.dart',
  'lib/screens/medication_center_screen.dart',
  'lib/screens/personalized_next_step_screen.dart',
  'lib/screens/progress_dashboard_screen.dart',
  'lib/screens/quit_day_home_screen.dart',
  'lib/screens/rescue_result_next_step_screen.dart',
  'lib/screens/resource_screen_widgets.dart',
  'lib/screens/review_quit_plan_screen.dart',
  'lib/screens/settings_privacy_screen.dart',
  'lib/screens/slip_recovery_screen.dart',
  'lib/screens/support_hub_screen.dart',
  'lib/screens/support_preparation_screen.dart',
};

/// The app language mapping: AppLocale.isSpanish says which language the
/// app runs in; it chooses no text.
const languageMapping = <String>{'lib/l10n/app_locale.dart'};

final _word = RegExp(r'\bisSpanish\b');

/// isSpanish used as a condition, across line breaks.
final _condition = RegExp(
    r'\b_?isSpanish\s*\?(?![?.\[])|if\s*\(\s*!?\s*(?:widget\.)?_?isSpanish\s*\)'
    r'|!\s*(?:widget\.)?_?isSpanish\b|\b_?isSpanish\s*(?:&&|\|\|)|(?:&&|\|\|)\s*(?:widget\.)?_?isSpanish\b'
    // A helper given the flag to pick between texts: localized(isSpanish, …).
    r'|\w\(\s*(?:widget\.)?_?isSpanish\s*,');

Set<String> _files(RegExp pattern) => {
      for (final f
          in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') && pattern.hasMatch(f.readAsStringSync()))
          f.path.replaceAll(r'\', '/'),
    };

/// The files that choose text with isSpanish.
Set<String> filesUsingIsSpanish() => _files(_condition);

/// The isSpanish forms a file may keep once it has left the list: the
/// field, the constructor parameter, passing it on unchanged, and the debug
/// assert that it matches the app locale.
final _allowedForms = <RegExp>[
  RegExp(r'final\s+bool\s+isSpanish\s*;'),
  RegExp(r'required\s+this\.isSpanish\b'),
  RegExp(r'\bisSpanish\s*:\s*(?:widget\.)?isSpanish\b'),
  RegExp(
      r"assert\(\s*(?:widget\.)?isSpanish\s*==\s*\(\s*Localizations\.localeOf\(context\)\.languageCode\s*==\s*'es'\s*\)"),
];

/// [source] with comments and the text of string literals replaced by
/// spaces (same length and line breaks), keeping the code inside `${...}`
/// interpolations: so `'a://b'` is not read as a comment and a word in a
/// string is not read as code.
String maskStringsAndComments(String source) {
  final out = source.split('');
  void blank(int from, int to) {
    for (var k = from; k < to; k++) {
      if (out[k] != '\n') out[k] = ' ';
    }
  }

  late int Function(int) code;

  // A string literal starting at [i] (its prefix or quote); returns the
  // index after it.
  int string(int i) {
    final raw = source[i] == 'r' || source[i] == 'R';
    if (raw) i++;
    final q = source[i];
    final triple = source.startsWith(q * 3, i);
    final delim = triple ? q * 3 : q;
    i += delim.length;
    var textFrom = i;
    while (i < source.length) {
      if (!raw && source[i] == r'\') {
        i += 2;
        continue;
      }
      if (source.startsWith(delim, i)) {
        blank(textFrom, i);
        return i + delim.length;
      }
      if (!raw && source.startsWith(r'${', i)) {
        blank(textFrom, i);
        i = code(i + 2);
        textFrom = i;
        continue;
      }
      i++;
    }
    blank(textFrom, i);
    return i;
  }

  // Code from [i] up to an unmatched `}` (inside an interpolation) or the
  // end; returns the index after that `}`.
  code = (int i) {
    var depth = 0;
    while (i < source.length) {
      final c = source[i];
      if (source.startsWith('//', i)) {
        final end = source.indexOf('\n', i);
        final stop = end < 0 ? source.length : end;
        blank(i, stop);
        i = stop;
      } else if (source.startsWith('/*', i)) {
        final end = source.indexOf('*/', i + 2);
        final stop = end < 0 ? source.length : end + 2;
        blank(i, stop);
        i = stop;
      } else if (c == "'" || c == '"') {
        i = string(i);
      } else if ((c == 'r' || c == 'R') &&
          i + 1 < source.length &&
          (source[i + 1] == "'" || source[i + 1] == '"') &&
          (i == 0 || !RegExp(r'\w').hasMatch(source[i - 1]))) {
        i = string(i);
      } else if (c == '{') {
        depth++;
        i++;
      } else if (c == '}') {
        if (depth == 0) return i + 1;
        depth--;
        i++;
      } else {
        i++;
      }
    }
    return i;
  };
  code(0);
  return out.join();
}

/// Every other occurrence of isSpanish (any identifier containing it) in
/// [source], as `line: text`. Comments and string text are ignored.
List<String> otherIsSpanishUses(String source) {
  final masked = maskStringsAndComments(source);
  final allowed = [
    for (final form in _allowedForms)
      for (final m in form.allMatches(source)) (m.start, m.end)
  ];
  return [
    for (final m in RegExp(r'\w*isSpanish\w*').allMatches(masked))
      if (!allowed.any((a) => a.$1 <= m.start && m.end <= a.$2))
        '${'\n'.allMatches(masked.substring(0, m.start)).length + 1}: ${m.group(0)}'
  ];
}

/// The files with English/Spanish branches at the baseline.
Set<String> filesWithBaselineText() {
  final inventory = jsonDecode(
          File('test/l10n/baseline/legacy_literals.json').readAsStringSync())
      as Map<String, Object?>;
  return {
    for (final e in (inventory['files']! as Map<String, Object?>).entries)
      if ((e.value! as List).any((r) =>
          const {'en', 'es'}.contains((r as Map<String, Object?>)['branch'])))
        e.key
  };
}

void main() {
  test('only the listed files choose text with isSpanish', () {
    final using = filesUsingIsSpanish();
    final extra = using.difference({...isSpanishFiles, ...languageMapping});
    expect(extra, isEmpty,
        reason:
            'new isSpanish text selection; use the translation files (lib/l10n/app_*.arb)');
  });

  test('a file whose text has moved leaves the list', () {
    final using = filesUsingIsSpanish();
    final stale = isSpanishFiles.difference(using);
    expect(stale, isEmpty,
        reason:
            'remove these from isSpanishFiles: they no longer use isSpanish');
  });

  test(
      'the list only shrinks: every listed file had en/es text at the baseline',
      () {
    final inventory = jsonDecode(
            File('test/l10n/baseline/legacy_literals.json').readAsStringSync())
        as Map<String, Object?>;
    final files = (inventory['files']! as Map<String, Object?>).entries.where(
        (e) => (e.value! as List).any((r) => const {'en', 'es'}
            .contains((r as Map<String, Object?>)['branch'])));
    final withText = {for (final e in files) e.key};
    expect(isSpanishFiles.difference(withText), isEmpty,
        reason: 'a file that had no English/Spanish branches at the baseline '
            'cannot be added to the list');
  });

  test('the language mapping is still where the app reads the language', () {
    expect(_files(_word).containsAll(languageMapping), isTrue);
  });

  test('a file that left the list keeps only the allowed isSpanish forms', () {
    final moved = filesWithBaselineText()
        .difference({...isSpanishFiles, ...languageMapping});
    for (final path in moved) {
      final file = File(path);
      if (!file.existsSync()) continue;
      expect(otherIsSpanishUses(file.readAsStringSync()), isEmpty,
          reason: '$path left the isSpanish list; it may only declare, take, '
              'pass on and assert the flag');
    }
  });

  test('the allowed-forms check rejects every other use', () {
    const allowed = """
class A extends StatelessWidget {
  const A({required this.isSpanish, super.key});
  final bool isSpanish; // isSpanish in a comment is fine
  Widget build(BuildContext context) {
    assert(
      isSpanish == (Localizations.localeOf(context).languageCode == 'es'),
      'the screen language must match the app locale',
    );
    return B(isSpanish: isSpanish, other: C(isSpanish: widget.isSpanish));
  }
}
""";
    expect(otherIsSpanishUses(allowed), isEmpty);
    expect(
        otherIsSpanishUses(
            "final t = 'isSpanish in a string'; /* isSpanish */"),
        isEmpty);
    expect(maskStringsAndComments("a('x//y') // c\nb"), "a('    ')     \nb");
    for (final code in [
      "(isSpanish) ? 'a' : 'b'",
      "isSpanish == true ? 'a' : 'b'",
      "switch (isSpanish) { true => 'a', false => 'b' }",
      "final es = isSpanish; es ? 'a' : 'b'",
      "const {true: 'a', false: 'b'}[isSpanish]!",
      'bool get _isSpanish => language == spanish;',
      'B(isSpanish: true)',
      // A '//' inside a string is not a comment.
      "String get c4 => Uri.parse('a://b').path + (isSpanish == true ? 'Hola' : 'Hi');",
      "final u = 'https://x.test'; final t = isSpanish == true ? 'a' : 'b';",
      "final u = 'a//b'; final t = (isSpanish) ? 'a' : 'b';",
      "final t = '\${isSpanish ? 'a' : 'b'}';",
    ]) {
      expect(otherIsSpanishUses(code), isNotEmpty, reason: code);
    }
  });

  test('the condition check sees every form of text selection', () {
    for (final code in [
      "isSpanish ? 'a' : 'b'",
      "widget.isSpanish\n    ? 'a'\n    : 'b'",
      'if (isSpanish) {',
      'if (!widget.isSpanish) return x;',
      "final t = !_isSpanish ? 'a' : 'b';",
      'isSpanish && other',
      '_isSpanish ? WelcomeLanguage.english : WelcomeLanguage.spanish',
      "localized(widget.isSpanish, 'Home', 'Inicio')",
    ]) {
      expect(_condition.hasMatch(code), isTrue, reason: code);
    }
    for (final code in [
      'final bool isSpanish;',
      'required this.isSpanish,',
      'isSpanish: isSpanish,',
      'assert(isSpanish == (locale == es));',
    ]) {
      expect(_condition.hasMatch(code), isFalse, reason: code);
    }
  });
}
