import 'dart:convert';

import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig(
      {required this.apiBaseUrl,
      required this.supabaseUrl,
      required this.supabaseAnonKey});

  factory AppConfig.fromEnvironment() => const AppConfig(
        apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isConfigured =>
      apiBaseUrl.isNotEmpty &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
  bool get hasAnyConfiguration =>
      apiBaseUrl.isNotEmpty ||
      supabaseUrl.isNotEmpty ||
      supabaseAnonKey.isNotEmpty;

  /// Pure check of the two service endpoints for a release build. Returns one
  /// human-readable problem per failing value (empty list means acceptable).
  /// Names the dart-define so a misbuilt release is easy to diagnose.
  static List<String> releaseEndpointProblems({
    required String supabaseUrl,
    required String apiBaseUrl,
  }) {
    final problems = <String>[];
    for (final entry in {
      'SUPABASE_URL': supabaseUrl,
      'API_BASE_URL': apiBaseUrl,
    }.entries) {
      final value = entry.value.trim();
      if (value.isEmpty) {
        problems.add('${entry.key} is missing or empty.');
        continue;
      }
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
        problems.add('${entry.key} is not an absolute URL.');
      } else if (uri.scheme != 'https') {
        problems.add('${entry.key} must use https.');
      }
    }
    return problems;
  }

  /// Pure check that [key] is safe to embed in a client. Returns a problem
  /// description (never containing the key) or null. Follows the
  /// SUPABASE_ANON_KEY rules of tool/release_define_check.sh (TH-123, R-055):
  /// - a value that is empty after removing whitespace is rejected;
  /// - after removing whitespace and Unicode Cf/Cc characters, `sb_secret_` or
  ///   `service_role` anywhere (case-insensitive) is a privileged key;
  /// - a JWT-shaped value (three or more dot-separated segments, any header,
  ///   padded or not, also after a prefix such as "Bearer ") must decode, and
  ///   every `role` key in any segment after the first, at any depth, matched
  ///   case-insensitively with every duplicate counted, must be "anon". At
  ///   least one `role` must be present.
  /// Not covered (TH-137): invisible characters outside Cf/Cc (such as U+034F),
  /// look-alike letters, and hex, percent or base64-wrapped encodings.
  static String? anonKeyProblem(String key) {
    final text = _withoutInvisible(key);
    final squeezed = _withoutSpace(text);
    if (_withoutSpace(key).isEmpty) {
      return 'SUPABASE_ANON_KEY is missing or empty.';
    }
    final squashed = squeezed.toLowerCase();
    if (squashed.contains('sb_secret_') || squashed.contains('service_role')) {
      return 'SUPABASE_ANON_KEY is a privileged key.';
    }
    var shaped = false;
    var decoded = false;
    final roles = <String?>[];
    for (final piece in _tokenCandidates(text, squeezed)) {
      final segments = piece.split('.');
      if (segments.length < 3) continue;
      shaped = true;
      for (final segment in segments.skip(1)) {
        final found = _rolesOf(segment);
        if (found == null) continue;
        decoded = true;
        roles.addAll(found);
      }
    }
    if (roles.any((role) => role != 'anon') || (decoded && roles.isEmpty)) {
      return 'SUPABASE_ANON_KEY is a JWT whose role is not "anon".';
    }
    if (shaped && !decoded) {
      return 'SUPABASE_ANON_KEY looks like a JWT but cannot be decoded.';
    }
    return null;
  }

  // Whitespace as Python's str.isspace(), which the release helper uses.
  static bool _isSpace(int c) =>
      (c >= 0x09 && c <= 0x0D) ||
      (c >= 0x1C && c <= 0x20) ||
      c == 0x85 ||
      c == 0xA0 ||
      c == 0x1680 ||
      (c >= 0x2000 && c <= 0x200A) ||
      c == 0x2028 ||
      c == 0x2029 ||
      c == 0x202F ||
      c == 0x205F ||
      c == 0x3000;

  // Unicode category Cc or Cf (Unicode 16).
  static bool _isControlOrFormat(int c) {
    if (c <= 0x1F || (c >= 0x7F && c <= 0x9F)) return true;
    for (final range in _formatRanges) {
      if (c >= range[0] && c <= range[1]) return true;
    }
    return false;
  }

  static const _formatRanges = <List<int>>[
    [0x00AD, 0x00AD],
    [0x0600, 0x0605],
    [0x061C, 0x061C],
    [0x06DD, 0x06DD],
    [0x070F, 0x070F],
    [0x0890, 0x0891],
    [0x08E2, 0x08E2],
    [0x180E, 0x180E],
    [0x200B, 0x200F],
    [0x202A, 0x202E],
    [0x2060, 0x2064],
    [0x2066, 0x206F],
    [0xFEFF, 0xFEFF],
    [0xFFF9, 0xFFFB],
    [0x110BD, 0x110BD],
    [0x110CD, 0x110CD],
    [0x13430, 0x1343F],
    [0x1BCA0, 0x1BCA3],
    [0x1D173, 0x1D17A],
    [0xE0001, 0xE0001],
    [0xE0020, 0xE007F],
  ];

  /// Removes zero-width, format and control characters (not whitespace).
  static String _withoutInvisible(String text) => String.fromCharCodes(
        text.runes.where((c) => _isSpace(c) || !_isControlOrFormat(c)),
      );

  static String _withoutSpace(String text) =>
      String.fromCharCodes(text.runes.where((c) => !_isSpace(c)));

  /// Candidate tokens: the value with and without whitespace, its
  /// whitespace-separated words, and any dotted run of base64url characters.
  static Set<String> _tokenCandidates(String text, String squeezed) {
    final runes = text.runes.toList();
    var start = 0;
    var end = runes.length;
    while (start < end && _isSpace(runes[start])) {
      start++;
    }
    while (end > start && _isSpace(runes[end - 1])) {
      end--;
    }
    final found = <String>{squeezed, String.fromCharCodes(runes, start, end)};
    final word = StringBuffer();
    for (final c in [...runes, 0x20]) {
      if (!_isSpace(c)) {
        word.writeCharCode(c);
      } else if (word.isNotEmpty) {
        found.add(word.toString());
        word.clear();
      }
    }
    final run = RegExp(
      r'(?<![A-Za-z0-9_=+/-])[A-Za-z0-9_=+/-]+(?:\.[A-Za-z0-9_=+/-]+){2,}',
    );
    for (final source in [text, squeezed]) {
      found.addAll(run.allMatches(source).map((m) => m[0]!));
    }
    return found;
  }

  /// Null if [segment] is not base64(url) JSON object, else every value of a
  /// `role` key at any depth, duplicates included (null for a non-string).
  static List<String?>? _rolesOf(String segment) {
    if (!RegExp(r'^[A-Za-z0-9_+/-]*={0,2}$').hasMatch(segment)) return null;
    final body = segment
        .replaceFirst(RegExp(r'=+$'), '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
    if (body.length % 4 == 1) return null;
    try {
      final json = utf8.decode(base64Url.decode(base64Url.normalize(body)));
      if (jsonDecode(json) is! Map) return null;
      return _roleValues(json);
    } catch (_) {
      return null;
    }
  }

  /// Every value of a `role` key (any case, any depth) in valid JSON [json].
  /// jsonDecode keeps only the last duplicate, so the text is scanned: in
  /// valid JSON a string followed by a colon is a key.
  static List<String?> _roleValues(String json) {
    final string = RegExp(r'"(?:[^"\\]|\\.)*"');
    final colon = RegExp(r'\s*:\s*');
    final roles = <String?>[];
    for (final match in string.allMatches(json)) {
      final afterKey = colon.matchAsPrefix(json, match.end);
      if (afterKey == null) continue;
      final name = jsonDecode(match[0]!) as String;
      if (name.toLowerCase() != 'role') continue;
      final value = string.matchAsPrefix(json, afterKey.end);
      roles.add(value == null ? null : jsonDecode(value[0]!) as String);
    }
    return roles;
  }

  void validate({bool production = kReleaseMode}) {
    if (production) {
      final problems = releaseEndpointProblems(
        supabaseUrl: supabaseUrl,
        apiBaseUrl: apiBaseUrl,
      );
      if (problems.isNotEmpty) {
        throw FormatException(
          'Release build is misconfigured. ${problems.join(' ')} '
          'Build with --dart-define-from-file (see docs/PLAY_RELEASE.md).',
        );
      }
    }
    if (!isConfigured) {
      throw const FormatException(
          'API_BASE_URL, SUPABASE_URL and SUPABASE_ANON_KEY must be provided together.');
    }
    for (final value in [apiBaseUrl, supabaseUrl]) {
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        throw const FormatException('Service URLs must be absolute.');
      }
      if (production && uri.scheme != 'https') {
        throw const FormatException('Production service URLs must use HTTPS.');
      }
      if (production && uri.host.endsWith('.invalid')) {
        throw const FormatException(
          'Production service URLs must not use placeholder hosts.',
        );
      }
    }
    final keyProblem = anonKeyProblem(supabaseAnonKey);
    if (keyProblem != null) {
      throw FormatException(
        '$keyProblem Flutter requires a Supabase publishable or anonymous key.',
      );
    }
  }
}
