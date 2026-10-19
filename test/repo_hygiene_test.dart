// This repository is public. Internal process vocabulary (team role handles,
// paths into private workspaces, and references to private notes) must not
// appear in any tracked text file. This test scans every tracked file (plus
// untracked files that are not ignored, so a new file is caught before it is
// committed) and fails on any match outside the allowlist below.
//
// If this test fails, reword the text: say what is needed ("needs security
// review", "see the maintainers' records"), not which internal role does it.
// Add an allowlist entry only for a legitimate occurrence, with a comment
// saying why.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Terms that must not appear in tracked text, matched case-insensitively.
/// A role handle only matches when it is not preceded by a letter or digit,
/// so ordinary words that happen to end in "th" do not match.
final List<RegExp> forbiddenTerms = [
  RegExp(
    r'(?<![A-Za-z0-9])th-(?:qa|security|reviewer|architect|release|lead|'
    r'app-engineer|backend-engineer|web-engineer|chronic-engineer)\b',
    caseSensitive: false,
  ),
  RegExp(r'office-worktrees', caseSensitive: false),
  RegExp(r'Tether-Health-AI-Office', caseSensitive: false),
  RegExp(r'private\s+office', caseSensitive: false),
];

/// A legitimate occurrence. [lineContains] narrows the entry to lines that
/// contain that text; null allows the whole file.
class HygieneAllowance {
  const HygieneAllowance(this.path, {this.lineContains, this.transitional});

  final String path;
  final String? lineContains;

  /// Set for an entry that waits on a fix in another change. Such an entry is
  /// not reported as stale once the text is gone; delete it then.
  final String? transitional;
}

const List<HygieneAllowance> hygieneAllowlist = [
  // This test has to name the terms it forbids.
  HygieneAllowance('test/repo_hygiene_test.dart'),
  // Reworded by TH-984b, which is in review separately. Delete this entry
  // once TH-984b has landed.
  HygieneAllowance(
    'api/test/enrolments.e2e-spec.ts',
    lineContains: 'Stand-in fidelity (',
    transitional: 'TH-984b',
  ),
];

/// Directories never scanned by the fallback walk (build output, caches,
/// dependencies, VCS metadata, Flutter's per-machine `ephemeral` output).
const Set<String> _skippedDirNames = {
  '.git',
  '.dart_tool',
  '.gradle',
  '.idea',
  'build',
  'ephemeral',
  'node_modules',
  'Pods',
  'coverage',
  'dist',
};

/// Files skipped by the walk: lockfiles written by package managers, and
/// git-ignored files that Flutter writes with this machine's absolute paths.
const Set<String> _skippedFileNames = {
  '.flutter-plugins',
  '.flutter-plugins-dependencies',
  'Generated.xcconfig',
  'flutter_export_environment.sh',
  'local.properties',
  'pubspec.lock',
  'package-lock.json',
  'Podfile.lock',
  'yarn.lock',
  'pnpm-lock.yaml',
  'poetry.lock',
  'uv.lock',
};

/// Files to scan, relative to [root], with forward slashes. Uses git when it
/// is available; otherwise walks the tree with the exclusions above.
List<String> repoFiles(Directory root) {
  try {
    final result = Process.runSync(
      'git',
      ['ls-files', '-z', '--cached', '--others', '--exclude-standard'],
      workingDirectory: root.path,
      stdoutEncoding: utf8,
    );
    if (result.exitCode == 0) {
      final files = (result.stdout as String)
          .split('\x00')
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      if (files.isNotEmpty) return files;
    }
  } on ProcessException {
    // git is not installed; fall back to the walk.
  }
  return walkFiles(root);
}

/// The fallback file list: every file under [root] except the skipped
/// directories and lockfiles.
List<String> walkFiles(Directory root) {
  final out = <String>[];
  void visit(Directory dir) {
    for (final entity in dir.listSync(followLinks: false)) {
      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (entity is Directory) {
        if (!_skippedDirNames.contains(name)) visit(entity);
      } else if (entity is File && !_skippedFileNames.contains(name)) {
        out.add(entity.path
            .substring(root.path.length)
            .replaceAll(r'\', '/')
            .replaceFirst(RegExp(r'^/+'), ''));
      }
    }
  }

  visit(root);
  return out..sort();
}

/// One forbidden match: `path:line: text`.
class HygieneHit {
  HygieneHit(this.path, this.line, this.text);

  final String path;
  final int line;
  final String text;

  @override
  String toString() => '$path:$line: ${text.trim()}';
}

/// Returns null for a binary file (a NUL byte in the first 8 KiB).
String? decodeText(List<int> bytes) {
  final head = bytes.length < 8192 ? bytes.length : 8192;
  for (var i = 0; i < head; i++) {
    if (bytes[i] == 0) return null;
  }
  return utf8.decode(bytes, allowMalformed: true);
}

bool _allowed(String path, String line, List<HygieneAllowance> allowlist) =>
    allowlist.any((a) =>
        a.path == path &&
        (a.lineContains == null || line.contains(a.lineContains!)));

/// Forbidden matches in [text], which is the content of [path].
List<HygieneHit> scanText(
  String path,
  String text, {
  List<HygieneAllowance> allowlist = hygieneAllowlist,
}) {
  final hits = <HygieneHit>[];
  // Fast path: most files have no match at all.
  if (!forbiddenTerms.any((t) => t.hasMatch(text))) return hits;
  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!forbiddenTerms.any((t) => t.hasMatch(line))) continue;
    if (_allowed(path, line, allowlist)) continue;
    hits.add(HygieneHit(path, i + 1, line));
  }
  return hits;
}

/// True when [text] still contains a forbidden term that [entry] allows.
bool allowanceStillUsed(HygieneAllowance entry, String text) =>
    const LineSplitter().convert(text).any((line) =>
        forbiddenTerms.any((t) => t.hasMatch(line)) &&
        (entry.lineContains == null || line.contains(entry.lineContains!)));

void main() {
  final root = Directory.current;

  test('no tracked text file contains internal process terms', () {
    final files = repoFiles(root);
    expect(files.length, greaterThan(100),
        reason: 'the file list looks wrong; run the test from the repo root');
    final hits = <HygieneHit>[];
    for (final path in files) {
      final file = File('${root.path}/$path');
      if (!file.existsSync()) continue; // deleted in the working tree
      final text = decodeText(file.readAsBytesSync());
      if (text == null) continue;
      hits.addAll(scanText(path, text));
    }
    expect(
      hits.map((h) => h.toString()).toList(),
      isEmpty,
      reason: 'This repository is public. Reword these lines: describe what '
          'is needed, not which internal role does it, and do not point to '
          'private notes or workspaces.',
    );
  });

  test('every permanent allowlist entry is still needed', () {
    final stale = <String>[];
    for (final entry in hygieneAllowlist) {
      if (entry.transitional != null) continue;
      final file = File('${root.path}/${entry.path}');
      if (!file.existsSync() ||
          !allowanceStillUsed(entry, file.readAsStringSync())) {
        stale.add(entry.path);
      }
    }
    expect(stale, isEmpty, reason: 'remove these stale allowlist entries');
  });

  group('scanner self-checks', () {
    test('each forbidden term is caught, in any case', () {
      for (final sample in [
        'Needs th-qa sign-off.',
        'see TH-SECURITY L1',
        '(th-reviewer round 1)',
        'asked th-architect',
        'tell th-release',
        'for th-lead to file',
        'by th-app-engineer',
        'by th-backend-engineer',
        'by th-web-engineer',
        'by th-chronic-engineer',
        'cd ../.office-worktrees/TH-1',
        'see Tether-Health-AI-Office/LEDGER.md',
        'see the private office notes',
        'see the private\toffice notes',
      ]) {
        expect(scanText('docs/x.md', sample, allowlist: const []), hasLength(1),
            reason: sample);
      }
    });

    test('ordinary words and neutral wording are not caught', () {
      for (final sample in [
        'Needs security review.',
        'see the maintainers\' records',
        'a smooth-qa pass', // preceded by a letter
        'width-security',
        'the office hours',
        'th-TH locale',
        'health-qa',
      ]) {
        expect(scanText('docs/x.md', sample, allowlist: const []), isEmpty,
            reason: sample);
      }
    });

    test('reports the path and line number', () {
      final hits =
          scanText('docs/x.md', 'ok\nok\nask th-qa\n', allowlist: const []);
      expect(hits.single.toString(), 'docs/x.md:3: ask th-qa');
    });

    test('the allowlist is exact about path and line', () {
      const allow = [
        HygieneAllowance('a.md', lineContains: 'Allowed here ('),
        HygieneAllowance('whole.md'),
      ];
      expect(
          scanText('a.md', 'Allowed here (th-qa)', allowlist: allow), isEmpty);
      expect(
          scanText('a.md', 'Other line th-qa', allowlist: allow), hasLength(1));
      expect(scanText('b.md', 'Allowed here (th-qa)', allowlist: allow),
          hasLength(1));
      expect(scanText('whole.md', 'th-qa\nth-security', allowlist: allow),
          isEmpty);
      expect(
        allowanceStillUsed(allow.first, 'Allowed here (security review)'),
        isFalse,
      );
      expect(allowanceStillUsed(allow.first, 'Allowed here (th-qa)'), isTrue);
    });

    test('binary files are skipped, text files are decoded', () {
      expect(decodeText([0x89, 0x50, 0x4e, 0x47, 0x00, 0x01]), isNull);
      expect(decodeText(utf8.encode('th-qa')), 'th-qa');
    });

    test('the walk fallback skips build output, caches and lockfiles', () {
      final tmp = Directory.systemTemp.createTempSync('repo_hygiene_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      for (final p in [
        'docs/a.md',
        'build/out.txt',
        '.dart_tool/x.json',
        'api/node_modules/p/index.js',
        'pubspec.lock',
        'api/package-lock.json',
        'ios/Flutter/Generated.xcconfig',
        'ios/Flutter/ephemeral/flutter_native_integration.env',
        '.flutter-plugins-dependencies',
      ]) {
        File('${tmp.path}/$p')
          ..createSync(recursive: true)
          ..writeAsStringSync('x');
      }
      expect(walkFiles(tmp), ['docs/a.md']);
    });
  });
}
