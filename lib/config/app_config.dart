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
  /// - after removing whitespace, Unicode Cf/Cc characters and the other
  ///   invisible code points of the helper's EXTRA_INVISIBLE list (TH-141, see
  ///   [_extraInvisibleRanges]), `sb_secret_` or `service_role` anywhere
  ///   (case-insensitive) is a privileged key. These are not removed before the
  ///   JWT decoding, as in the helper;
  /// - a JWT-shaped value (three or more dot-separated segments, any header,
  ///   padded or not, also after a prefix such as "Bearer ") must decode, and
  ///   every `role` key in any segment after the first, at any depth, matched
  ///   case-insensitively with every duplicate counted, must be "anon". At
  ///   least one `role` must be present;
  /// - a segment after the first that Dart cannot decode but Python can (NaN
  ///   or Infinity, UTF-16/32, a BOM, CESU-8, unused base64 bits set) counts
  ///   as a non-anon role if it still looks like a JSON object with a role,
  ///   or with a backslash-u escape that could spell one (TH-140 tests this
  ///   for UTF-8, UTF-32BE and a BOM plus UTF-16BE); the problem is then
  ///   `role is not "anon"`.
  /// Known residuals. Only the last one can let a privileged value through;
  /// the others never accept a non-anon role:
  /// - deep nesting: a payload nested beyond the Python recursion limit with
  ///   only anon roles is accepted here and rejected by the helper;
  /// - helper-only encodings of an anon payload (for example NaN, UTF-16/32)
  ///   are rejected here with `role is not "anon"`, so Dart is stricter than
  ///   the helper;
  /// - the Cf table is Unicode 16, a superset of the Unicode data of an older
  ///   running Python (3.9 has Unicode 13);
  /// - look-alike letters, and hex, percent or base64-wrapped encodings can
  ///   let a privileged value through, here and in the helper alike; so can an
  ///   invisible character that is in neither Cf/Cc nor the mirrored list.
  static String? anonKeyProblem(String key) {
    if (_withoutSpace(key).isEmpty) {
      return 'SUPABASE_ANON_KEY is missing or empty.';
    }
    final text = _withoutInvisible(key);
    final compact = _withoutSpace(text);
    final compactLower = _withoutExtraInvisible(compact).toLowerCase();
    if (compactLower.contains('sb_secret_') ||
        compactLower.contains('service_role')) {
      return 'SUPABASE_ANON_KEY is a privileged key.';
    }
    var shaped = false;
    var decoded = false;
    final roles = <String?>[];
    for (final piece in _tokenCandidates(text, compact)) {
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

  // Invisible code points outside Cf and Cc that the helper removes before its
  // sb_secret_ and service_role checks (EXTRA_INVISIBLE in
  // tool/release_define_check.sh at a21dd15, TH-137), copied as a fixed list
  // so that Dart does not depend on a Unicode table. U+0890-0891 and
  // U+13439-1343F are in the helper list but are Cf here already
  // (_formatRanges), so they are not repeated. U+E0000-E0FFF is kept whole,
  // like the helper's range, although U+E0001 and U+E0020-E007F are also Cf.
  static const _extraInvisibleRanges = <List<int>>[
    [0x034F, 0x034F],
    [0x115F, 0x1160],
    [0x17B4, 0x17B5],
    [0x180B, 0x180D],
    [0x180F, 0x180F],
    [0x2065, 0x2065],
    [0x2800, 0x2800],
    [0x3164, 0x3164],
    [0xFE00, 0xFE0F],
    [0xFFA0, 0xFFA0],
    [0xFFF0, 0xFFF8],
    [0xE0000, 0xE0FFF],
  ];

  static bool _isExtraInvisible(int c) {
    for (final range in _extraInvisibleRanges) {
      if (c >= range[0] && c <= range[1]) return true;
    }
    return false;
  }

  /// Removes the [_extraInvisibleRanges] code points. Only for the substring
  /// checks, never for JWT decoding.
  static String _withoutExtraInvisible(String text) => String.fromCharCodes(
        text.runes.where((c) => !_isExtraInvisible(c)),
      );

  /// Removes zero-width, format and control characters (not whitespace).
  static String _withoutInvisible(String text) => String.fromCharCodes(
        text.runes.where((c) => _isSpace(c) || !_isControlOrFormat(c)),
      );

  static String _withoutSpace(String text) =>
      String.fromCharCodes(text.runes.where((c) => !_isSpace(c)));

  /// Candidate tokens: the value with and without whitespace, its
  /// whitespace-separated words, and any dotted run of base64url characters.
  static Set<String> _tokenCandidates(String text, String compact) {
    final runes = text.runes.toList();
    var start = 0;
    var end = runes.length;
    while (start < end && _isSpace(runes[start])) {
      start++;
    }
    while (end > start && _isSpace(runes[end - 1])) {
      end--;
    }
    final found = <String>{compact, String.fromCharCodes(runes, start, end)};
    final word = StringBuffer();
    for (final c in [...runes, 0x20]) {
      if (!_isSpace(c)) {
        word.writeCharCode(c);
      } else if (word.isNotEmpty) {
        found.add(word.toString());
        word.clear();
      }
    }
    for (final source in [text, compact]) {
      found.addAll(_dottedRun.allMatches(source).map((m) => m[0]!));
    }
    return found;
  }

  static final _dottedRun = RegExp(
    r'(?<![A-Za-z0-9_=+/-])[A-Za-z0-9_=+/-]+(?:\.[A-Za-z0-9_=+/-]+){2,}',
  );
  static final _segmentShape = RegExp(r'^[A-Za-z0-9_+/-]*={0,2}$');
  static final _jsonString = RegExp(r'"(?:[^"\\]|\\.)*"');
  static final _jsonColon = RegExp(r'\s*:\s*');
  static const _base64UrlAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  /// Null if [segment] is not a base64(url) JSON object, else every value of a
  /// `role` key at any depth, duplicates included (null for a non-string).
  static List<String?>? _rolesOf(String segment) {
    if (!_segmentShape.hasMatch(segment)) return null;
    final body = segment
        .replaceFirst(RegExp(r'=+$'), '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
    if (body.length % 4 == 1) return null;
    try {
      final bytes =
          base64Url.decode(base64Url.normalize(_clearSpareBits(body)));
      final String json;
      try {
        json = utf8.decode(bytes);
        if (jsonDecode(json) is! Map) return null;
      } catch (_) {
        return _pythonOnlyRoles(bytes);
      }
      return _roleValues(json);
    } catch (_) {
      return null;
    }
  }

  /// Clears the unused low bits of the last base64 character (Python ignores
  /// them, Dart may not): 4 bits when the length is 2 mod 4, 2 bits when 3.
  static String _clearSpareBits(String body) {
    final spare = switch (body.length % 4) { 2 => 0x0F, 3 => 0x03, _ => 0 };
    if (spare == 0) return body;
    final last = _base64UrlAlphabet.indexOf(body[body.length - 1]);
    return '${body.substring(0, body.length - 1)}'
        '${_base64UrlAlphabet[last & ~spare]}';
  }

  /// For bytes that are not strict UTF-8 JSON: drops NUL bytes, one leading
  /// BOM and surrounding ASCII whitespace. If what is left looks like a JSON
  /// object that has a role (or an escape that could spell one), the segment
  /// counts as a non-anon role, since the release helper may decode it.
  static List<String?>? _pythonOnlyRoles(List<int> bytes) {
    var kept = [
      for (final b in bytes)
        if (b != 0) b
    ];
    const boms = [
      [0xEF, 0xBB, 0xBF],
      [0xFE, 0xFF],
      [0xFF, 0xFE],
    ];
    for (final bom in boms) {
      if (kept.length >= bom.length &&
          [for (var i = 0; i < bom.length; i++) kept[i] == bom[i]]
              .every((same) => same)) {
        kept = kept.sublist(bom.length);
        break;
      }
    }
    bool blank(int b) => b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D;
    var start = 0;
    var end = kept.length;
    while (start < end && blank(kept[start])) {
      start++;
    }
    while (end > start && blank(kept[end - 1])) {
      end--;
    }
    final text = latin1.decode(kept.sublist(start, end)).toLowerCase();
    if (text.startsWith('{') &&
        text.endsWith('}') &&
        (text.contains('role') || text.contains(r'\u'))) {
      return [null];
    }
    return null;
  }

  /// Every value of a `role` key (any case, any depth) in valid JSON [json].
  /// jsonDecode keeps only the last duplicate, so the text is scanned: in
  /// valid JSON a string followed by a colon is a key.
  static List<String?> _roleValues(String json) {
    final roles = <String?>[];
    for (final match in _jsonString.allMatches(json)) {
      final afterKey = _jsonColon.matchAsPrefix(json, match.end);
      if (afterKey == null) continue;
      final name = jsonDecode(match[0]!) as String;
      if (name.toLowerCase() != 'role') continue;
      final value = _jsonString.matchAsPrefix(json, afterKey.end);
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
