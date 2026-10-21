// Reads Dart sources for the static tests of the tether_ui shell.
import 'dart:io';

/// Every Dart file under `lib/`, by repo-relative path with forward slashes.
Map<String, String> libSources() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return {
    for (final file in files)
      file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
  };
}

/// [source] with comments replaced by spaces (offsets kept). With
/// [strings] false, string literals are blanked too, so only code remains.
String stripped(String source, {bool strings = true}) {
  final out = StringBuffer();
  var i = 0;
  void blank(int end) {
    for (; i < end; i++) {
      out.write(source[i] == '\n' ? '\n' : ' ');
    }
  }

  void keep(int end) {
    out.write(source.substring(i, end));
    i = end;
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
      final end =
          j + quote.length > source.length ? source.length : j + quote.length;
      if (strings) {
        keep(end);
      } else {
        blank(end);
      }
    } else {
      out.write(source[i]);
      i++;
    }
  }
  return out.toString();
}

/// [source] with comments and string literals blanked.
String codeOnly(String source) => stripped(source, strings: false);

/// Index of the bracket that closes the one at [open] in [code].
int matchingBracket(String code, int open) {
  const pairs = {'(': ')', '{': '}', '[': ']'};
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

/// The import and export URIs of [source].
List<String> directiveUris(String source) => [
      for (final match in RegExp(
        r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true,
      ).allMatches(stripped(source)))
        match.group(1)!,
    ];
