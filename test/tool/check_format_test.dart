import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Runs tool/check_format.sh on a copy in a temporary project root that holds
// only synthetic Dart files and a synthetic package config. The real tree is
// never formatted or checked. The script uses whichever `dart` is first on
// PATH, as it does in CI.

String join(List<String> parts) => parts.join(Platform.pathSeparator);

const _formatted = "void main() {\n  print('synthetic-user-01');\n}\n";
const _unformatted = "void main(){print('synthetic-user-01');}\n";

void main() {
  late Directory root;

  File inRoot(String relative) =>
      File(join([root.path, ...relative.split('/')]));

  void write(String relative, String contents) => inRoot(relative)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(contents);

  setUp(() {
    root = Directory.systemTemp.createTempSync('check_format_test_');
    write(
      'tool/check_format.sh',
      File(join([Directory.current.path, 'tool', 'check_format.sh']))
          .readAsStringSync(),
    );
    write('pubspec.yaml', 'name: synthetic_pkg\n');
    write(
      '.dart_tool/package_config.json',
      '{"configVersion": 2, "packages": [{"name": "synthetic_pkg", '
          '"rootUri": "../", "packageUri": "lib/", "languageVersion": "3.4"}]}',
    );
    write('lib/clean.dart', _formatted);
  });

  tearDown(() => root.deleteSync(recursive: true));

  ProcessResult run() => Process.runSync(
        '/bin/sh',
        [inRoot('tool/check_format.sh').path],
        workingDirectory: root.path,
      );

  String output(ProcessResult r) => '${r.stdout}${r.stderr}';

  test('passes on a formatted tree', () {
    final r = run();
    expect(r.exitCode, 0, reason: output(r));
  });

  test('exits 1 on formatting drift in lib/ and names the file', () {
    write('lib/drift.dart', _unformatted);
    final r = run();
    expect(r.exitCode, 1, reason: output(r));
    expect(output(r), contains('drift.dart'));
  });

  for (final excluded in ['third_party', 'tether_ui']) {
    test('ignores an unformatted file under top-level $excluded/', () {
      write('$excluded/pkg/lib/unformatted.dart', _unformatted);
      final r = run();
      expect(r.exitCode, 0, reason: output(r));
      expect(output(r), isNot(contains('unformatted.dart')));
    });

    test('still checks a first-party $excluded/ dir below the root', () {
      write('lib/$excluded/unformatted.dart', _unformatted);
      final r = run();
      expect(r.exitCode, 1, reason: output(r));
      expect(output(r), contains('unformatted.dart'));
    });
  }

  test('exits 2 without .dart_tool, before formatting anything', () {
    write('lib/drift.dart', _unformatted);
    Directory(join([root.path, '.dart_tool'])).deleteSync(recursive: true);
    final r = run();
    expect(r.exitCode, 2, reason: output(r));
    expect(r.stderr, contains("run 'flutter pub get' first"));
    expect(output(r), isNot(contains('drift.dart')));
  });
}
