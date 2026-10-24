// This repository is public. Internal process vocabulary (team role handles,
// paths into private workspaces, and references to private notes) must not
// appear in any tracked text file. This test scans every tracked file (plus
// untracked files that are not ignored, so a new file is caught before it is
// committed) and fails on any match outside the allowlist below.
//
// If this test fails, reword the text: say what is needed ("needs security
// review", "see the maintainers' records"), not which internal role does it.
//
// This file is scanned too. Every pattern and fixture below is assembled from
// fragments, so none of the forbidden strings appears in it literally. Keep it
// that way when editing.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Prefix of the internal role handles.
const String _rolePrefix = 'th';

/// Suffixes of the internal role handles.
const List<String> _roleSuffixes = [
  'qa',
  'security',
  'reviewer',
  'architect',
  'release',
  'lead',
  'app-engineer',
  'backend-engineer',
  'web-engineer',
  'chronic-engineer',
];

/// A role handle, assembled at run time (for fixtures).
String _handle(String suffix) => '$_rolePrefix-$suffix';

/// The private workspace directory name.
const String _workspaceDir = 'office' '-worktrees';

/// The private workspace repository name.
const String _workspaceRepo = 'Tether-Health-AI' '-Office';

/// Terms that must not appear in tracked text, matched case-insensitively.
/// A role handle only matches when it is not preceded by a letter or digit,
/// so ordinary words that happen to end in those letters do not match.
final List<RegExp> forbiddenTerms = [
  RegExp(
    '(?<![A-Za-z0-9])$_rolePrefix-(?:${_roleSuffixes.join('|')})\\b',
    caseSensitive: false,
  ),
  RegExp(RegExp.escape(_workspaceDir), caseSensitive: false),
  RegExp(RegExp.escape(_workspaceRepo), caseSensitive: false),
  RegExp(r'private' r'\s+' r'office\b', caseSensitive: false),
];

/// A legitimate occurrence. [lineContains] narrows the entry to lines that
/// contain that text; null allows the whole file.
class HygieneAllowance {
  const HygieneAllowance(this.path, {this.lineContains});

  final String path;
  final String? lineContains;
}

/// Legitimate occurrences of a forbidden term. Empty today.
///
/// To add one, give the repo-relative path and, preferably, a [lineContains]
/// substring that pins the entry to the line(s) concerned, with a comment
/// saying why the text is legitimate, for example:
///
///     // Quotes a third-party licence verbatim.
///     HygieneAllowance('third_party/x/LICENSE', lineContains: 'Copyright'),
///
/// Every entry is stale-checked: once the text is gone, the stale-entry test
/// fails until the entry is removed.
const List<HygieneAllowance> hygieneAllowlist = [];

/// Directories never scanned by the fallback walk (build output, caches,
/// dependencies, VCS metadata, Flutter's per-machine `ephemeral` output,
/// Android native build output).
const Set<String> _skippedDirNames = {
  '.git',
  '.dart_tool',
  '.gradle',
  '.idea',
  '.cxx',
  'build',
  'ephemeral',
  'node_modules',
  'Pods',
  'coverage',
  'dist',
};

/// Files skipped by the walk: lockfiles written by package managers, and
/// git-ignored files that Flutter writes with this machine's absolute paths.
/// Files whose name starts with `.env` are skipped as well (see [_skipFile]),
/// so a run without git never reads or prints local secrets.
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

bool _skipFile(String name) =>
    _skippedFileNames.contains(name) || name.startsWith('.env');

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
/// directories and files.
List<String> walkFiles(Directory root) {
  final out = <String>[];
  void visit(Directory dir) {
    for (final entity in dir.listSync(followLinks: false)) {
      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (entity is Directory) {
        if (!_skippedDirNames.contains(name)) visit(entity);
      } else if (entity is File && !_skipFile(name)) {
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

/// Allowlist entries under [root] whose file is gone or no longer contains
/// any forbidden term the entry allows.
List<String> staleAllowances(
  Directory root,
  List<HygieneAllowance> allowlist,
) {
  final stale = <String>[];
  for (final entry in allowlist) {
    final file = File('${root.path}/${entry.path}');
    if (!file.existsSync() ||
        !allowanceStillUsed(entry, file.readAsStringSync())) {
      stale.add(entry.path);
    }
  }
  return stale;
}

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

  test('every allowlist entry is still needed', () {
    expect(staleAllowances(root, hygieneAllowlist), isEmpty,
        reason: 'remove these stale allowlist entries');
  });

  group('scanner self-checks', () {
    test('each forbidden term is caught, in any case', () {
      final samples = [
        for (final suffix in _roleSuffixes) 'Ask ${_handle(suffix)} first.',
        'Ask ${_handle('security').toUpperCase()} first.',
        'Ask (${_handle('qa')}) first.',
        'cd ../.$_workspaceDir/x',
        'see $_workspaceRepo/notes',
        'see ${_workspaceRepo.toLowerCase()}/notes',
        'see the private ${'office'} notes',
        'see the private\t${'office'} notes',
        'in a private ${'office'}.',
      ];
      for (final sample in samples) {
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
        'health-qa',
        '$_rolePrefix-TH locale', // the Thai locale tag
        'the office hours',
        'the office worktree',
        'Our private offices are closed on Sundays.',
      ]) {
        expect(scanText('docs/x.md', sample, allowlist: const []), isEmpty,
            reason: sample);
      }
    });

    test('reports the path and line number', () {
      final line = 'ask ${_handle('qa')}';
      final hits =
          scanText('docs/x.md', 'ok\nok\n$line\n', allowlist: const []);
      expect(hits.single.toString(), 'docs/x.md:3: $line');
    });

    test('the allowlist is exact about path and line', () {
      final term = _handle('qa');
      const allow = [
        HygieneAllowance('a.md', lineContains: 'Allowed here ('),
        HygieneAllowance('whole.md'),
      ];
      expect(
          scanText('a.md', 'Allowed here ($term)', allowlist: allow), isEmpty);
      expect(
          scanText('a.md', 'Other line $term', allowlist: allow), hasLength(1));
      expect(scanText('b.md', 'Allowed here ($term)', allowlist: allow),
          hasLength(1));
      expect(scanText('whole.md', '$term\n$term', allowlist: allow), isEmpty);
      expect(
        allowanceStillUsed(allow.first, 'Allowed here (security review)'),
        isFalse,
      );
      expect(allowanceStillUsed(allow.first, 'Allowed here ($term)'), isTrue);
    });

    test('a stale or missing allowlist entry is reported', () {
      final tmp = Directory.systemTemp.createTempSync('repo_hygiene_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      File('${tmp.path}/used.md').writeAsStringSync('x ${_handle('qa')}\n');
      File('${tmp.path}/clean.md').writeAsStringSync('needs security review\n');
      expect(
        staleAllowances(tmp, const [
          HygieneAllowance('used.md'),
          HygieneAllowance('clean.md'),
          HygieneAllowance('gone.md'),
        ]),
        ['clean.md', 'gone.md'],
      );
    });

    test('binary files are skipped, text files are decoded', () {
      expect(decodeText([0x89, 0x50, 0x4e, 0x47, 0x00, 0x01]), isNull);
      expect(decodeText(utf8.encode('hello')), 'hello');
    });

    test('the walk fallback skips build output, caches, lockfiles and .env',
        () {
      final tmp = Directory.systemTemp.createTempSync('repo_hygiene_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      for (final p in [
        'docs/a.md',
        'build/out.txt',
        '.dart_tool/x.json',
        'backend/api/node_modules/p/index.js',
        'pubspec.lock',
        'backend/api/package-lock.json',
        'ios/Flutter/Generated.xcconfig',
        'ios/Flutter/ephemeral/flutter_native_integration.env',
        '.flutter-plugins-dependencies',
        '.env',
        'backend/api/.env.local',
        'android/app/.cxx/Debug/x.txt',
      ]) {
        File('${tmp.path}/$p')
          ..createSync(recursive: true)
          ..writeAsStringSync('x');
      }
      expect(walkFiles(tmp), ['docs/a.md']);
    });
  });
}
