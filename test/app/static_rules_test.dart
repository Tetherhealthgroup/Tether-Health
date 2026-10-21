// Source rules for the app's use of the tether_ui package: no preview or
// simulation hooks, no resolver that decides on wording, and only the
// package's public entry points.
import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

/// The package files lib/ may import.
const _allowedPackageImports = {
  'package:tether_ui/ui/ui.dart',
  'package:tether_ui/router/app_router.dart',
  'package:tether_ui/router/routes.dart',
};

void main() {
  late Map<String, String> sources;

  setUpAll(() => sources = libSources());

  bool usesTetherUi(String source) =>
      directiveUris(source).any((uri) => uri.startsWith('package:tether_ui/'));

  test('lib/ imports only the public tether_ui entry points', () {
    final offenders = <String>[];
    var users = 0;
    for (final MapEntry(key: path, value: source) in sources.entries) {
      for (final uri in directiveUris(source)) {
        if (uri.startsWith('package:tether_ui/')) {
          users++;
          if (!_allowedPackageImports.contains(uri)) {
            offenders.add('$path $uri');
          }
        } else if (uri.contains('tether_ui/')) {
          offenders.add('$path $uri');
        }
      }
    }
    expect(users, greaterThan(0), reason: 'no file imports tether_ui');
    expect(offenders, isEmpty,
        reason: 'lib/ may import only ${_allowedPackageImports.join(', ')}; '
            'never the package main.dart, dev/ or testing/ code');
  });

  test('nothing in lib/ references a preview hook or the gallery', () {
    final forbidden = RegExp(
      r'\b(?:previewResolver|PreviewApi|PreviewData|PreviewPlatform|'
      r'PreviewDevice|TDefaults|GalleryScreen|TetherApp)\b',
    );
    final offenders = [
      for (final MapEntry(key: path, value: source) in sources.entries)
        for (final match in forbidden.allMatches(codeOnly(source)))
          '$path: ${match.group(0)}',
    ];
    expect(offenders, isEmpty);
  });

  test('TSim appears in lib/ only as the one TSim.reset() call', () {
    final uses = <String>[];
    for (final MapEntry(key: path, value: source) in sources.entries) {
      final code = codeOnly(source);
      for (final match in RegExp(r'\bTSim\b').allMatches(code)) {
        final rest = code.substring(match.end);
        final isReset = RegExp(r'^\s*\.\s*reset\s*\(\s*\)').hasMatch(rest);
        uses.add('$path ${isReset ? 'reset' : 'other'}');
      }
    }
    expect(uses, ['lib/app/production_hooks.dart reset']);
  });

  test('no file in lib/ defines a branch resolver', () {
    final shape = RegExp(
      r'\(\s*BuildContext\s+\w+\s*,\s*String\s+\w+\s*,\s*List\s*<\s*String\s*>',
    );
    final offenders = [
      for (final MapEntry(key: path, value: source) in sources.entries) ...[
        if (shape.hasMatch(codeOnly(source))) '$path: resolver-shaped function',
        if (RegExp(r'\bTBranchResolver\b').hasMatch(codeOnly(source)))
          '$path: TBranchResolver',
      ],
    ];
    expect(offenders, isEmpty,
        reason: 'branches are decided by rules, server outcomes and the '
            'device hook; the app installs only TFailClosedResolver');
  });

  test('the branch resolver is installed only as the fail-closed tear-off', () {
    final assignments = [
      for (final MapEntry(key: path, value: source) in sources.entries)
        for (final match in RegExp(r'branchResolver\s*=([^;]*);')
            .allMatches(codeOnly(source)))
          '$path:${match.group(1)!.trim()}',
    ];
    expect(
        assignments, ['lib/app/production_hooks.dart:hooks.resolver.resolve']);
  });

  test('code using tether_ui never reads question text', () {
    final offenders = <String>[];
    for (final MapEntry(key: path, value: source) in sources.entries) {
      if (!usesTetherUi(source)) continue;
      final code = codeOnly(source);
      if (RegExp(r'\bquestion\b', caseSensitive: false).hasMatch(code)) {
        offenders.add('$path: question');
      }
      for (final match
          in RegExp(r'redactQuestion\s*=([^;]*);').allMatches(code)) {
        if (match.group(1)!.trim() != 'true') {
          offenders.add('$path: redactQuestion = ${match.group(1)!.trim()}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
