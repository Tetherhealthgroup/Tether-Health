import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../app/ui_selection.dart';

/// Where the tether_ui screens send their data (`TETHER_BACKEND`).
enum BackendMode {
  /// An in-process server on the phone with synthetic data only. Nothing
  /// leaves the device.
  sandbox,

  /// The real services: the API, Supabase Auth and the sync service.
  http,
}

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.backend = '',
    this.syncBaseUrl = '',
    this.googleWebClientId = '',
    this.googleIosClientId = '',
    this.epicSandboxClientId = '',
  });

  /// Reads the build's defines. This is the only place in lib/ that reads
  /// service configuration.
  factory AppConfig.fromEnvironment() => const AppConfig(
        apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
        backend: String.fromEnvironment('TETHER_BACKEND'),
        syncBaseUrl: String.fromEnvironment('SYNC_BASE_URL'),
        googleWebClientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
        googleIosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
        epicSandboxClientId: String.fromEnvironment('EPIC_SANDBOX_CLIENT_ID'),
      );

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  /// `TETHER_BACKEND` as written: `sandbox`, `http`, or empty.
  final String backend;

  /// The sync service's base URL (`SYNC_BASE_URL`); http mode only.
  final String syncBaseUrl;

  /// Public OAuth client identifiers of the sign-in providers. Optional and
  /// never secrets; in http mode a provider without its IDs fails closed.
  final String googleWebClientId;
  final String googleIosClientId;
  final String epicSandboxClientId;

  bool get isConfigured =>
      apiBaseUrl.isNotEmpty &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  /// Whether any service value is set. `TETHER_BACKEND=sandbox` alone is not
  /// configuration: it asks for no service.
  bool get hasAnyConfiguration =>
      apiBaseUrl.isNotEmpty ||
      supabaseUrl.isNotEmpty ||
      supabaseAnonKey.isNotEmpty ||
      syncBaseUrl.isNotEmpty ||
      (backend.isNotEmpty && backend != _sandbox);

  static const String _sandbox = 'sandbox';
  static const String _http = 'http';

  /// The four service values http mode needs, by define name.
  Map<String, String> get _serviceValues => {
        'API_BASE_URL': apiBaseUrl,
        'SUPABASE_URL': supabaseUrl,
        'SUPABASE_ANON_KEY': supabaseAnonKey,
        'SYNC_BASE_URL': syncBaseUrl,
      };

  /// The backend mode of the tether_ui screens, or null when the defines do
  /// not name exactly one mode (the build is then misconfigured):
  /// - `sandbox` with none of the four service values set;
  /// - `http` with all four set;
  /// - nothing at all set, in a debug build only: sandbox.
  /// Anything partial is null, so one member's data never splits between a
  /// server and the phone. [debug] exists for tests.
  BackendMode? backendMode({bool debug = kDebugMode}) =>
      backendModeProblem(debug: debug) == null
          ? (_isHttp ? BackendMode.http : BackendMode.sandbox)
          : null;

  bool get _isHttp => backend.trim() == _http;

  /// Why [backendMode] is null, naming defines only (never values); null when
  /// the mode is valid.
  String? backendModeProblem({bool debug = kDebugMode}) {
    final set = _serviceValues.values.where((v) => v.trim().isNotEmpty).length;
    final names = _serviceValues.keys.join(', ');
    switch (backend.trim()) {
      case _sandbox:
        return set == 0
            ? null
            : 'TETHER_BACKEND=sandbox requires $names to be absent.';
      case _http:
        return set == _serviceValues.length
            ? null
            : 'TETHER_BACKEND=http requires all of $names.';
      case '':
        if (debug && set == 0) return null;
        return 'TETHER_BACKEND must be sandbox or http.';
      default:
        return 'TETHER_BACKEND must be sandbox or http.';
    }
  }

  /// Pure check of the two service endpoints for a release build. Returns the
  /// human-readable problems of each failing value (empty list means
  /// acceptable). Names the dart-define, never the value, so a misbuilt
  /// release is easy to diagnose. Neither URL may carry user info, a query or
  /// a fragment, and SUPABASE_URL may not have a path beyond "/", as in
  /// tool/release_define_check.sh. When [syncBaseUrl] is given (http mode of
  /// the tether_ui screens), SYNC_BASE_URL is checked with the API_BASE_URL
  /// rules.
  static List<String> releaseEndpointProblems({
    required String supabaseUrl,
    required String apiBaseUrl,
    String? syncBaseUrl,
  }) {
    final problems = <String>[];
    for (final entry in {
      'SUPABASE_URL': supabaseUrl,
      'API_BASE_URL': apiBaseUrl,
      if (syncBaseUrl != null) 'SYNC_BASE_URL': syncBaseUrl,
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
      // Only for an absolute URL; anything else is reported above.
      if (uri == null || !uri.hasAuthority || uri.host.isEmpty) continue;
      if (_rawAuthority(value).contains('@') ||
          uri.hasQuery ||
          uri.hasFragment) {
        problems.add(
          '${entry.key} must not contain user info, a query or a fragment.',
        );
      }
      if (entry.key == 'SUPABASE_URL' &&
          uri.path.isNotEmpty &&
          uri.path != '/') {
        problems
            .add('${entry.key} must be scheme and host only, without a path.');
      }
    }
    return problems;
  }

  /// The authority text of [value] as written: after "//" up to the first
  /// "/", "?" or "#". Empty if there is no "//".
  static String _rawAuthority(String value) {
    final start = value.indexOf('//');
    if (start < 0) return '';
    final rest = value.substring(start + 2);
    final end = rest.indexOf(RegExp('[/?#]'));
    return end < 0 ? rest : rest.substring(0, end);
  }

  /// Pure check that [key] is safe to embed in a client. Returns a problem
  /// description (never containing the key) or null. Follows the
  /// SUPABASE_ANON_KEY rules of tool/release_define_check.sh (TH-123, R-055).
  ///
  /// TH-904: the final verdict is an allowlist. [key],
  /// exactly as given (no trimming), must match `^sb_publishable_[A-Za-z0-9_-]+$`
  /// or be a JWT of exactly three base64url segments (optionally `=`-padded)
  /// whose payload is strict UTF-8 JSON: an object with a top-level `role` of
  /// `anon`. Anything else is rejected with `is not a publishable key or an
  /// anon JWT`. The denylist rules below run first so that the more specific
  /// problem is reported where one applies:
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
  /// The denylist only chooses the message; the allowlist decides acceptance.
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
    if (!_publishableKey.hasMatch(key) && !_isAnonJwt(key)) {
      return 'SUPABASE_ANON_KEY is not a publishable key (sb_publishable_...) '
          'or an anon JWT.';
    }
    return null;
  }

  static final _publishableKey = RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$');
  static final _jwtSegment = RegExp(r'^[A-Za-z0-9_-]+={0,2}$');

  /// True if [key] is exactly three base64url segments whose payload is strict
  /// UTF-8 JSON: an object with a top-level `role` of `anon` (TH-904).
  /// Mirrors is_anon_jwt in tool/release_define_check.sh.
  static bool _isAnonJwt(String key) {
    final segments = key.split('.');
    if (segments.length != 3 || !segments.every(_jwtSegment.hasMatch)) {
      return false;
    }
    final body = segments[1].replaceFirst(RegExp(r'=+$'), '');
    if (body.length % 4 == 1) return false;
    try {
      final bytes =
          base64Url.decode(base64Url.normalize(_clearSpareBits(body)));
      final payload = jsonDecode(utf8.decode(bytes));
      return payload is Map && payload['role'] == 'anon';
    } catch (_) {
      return false;
    }
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

  /// Throws a [FormatException] naming the failing defines when this build
  /// cannot start.
  ///
  /// The legacy app's rules are unchanged. For the tether_ui screens
  /// ([tetherUi], by default whether [selectAppUi] picks them), the backend
  /// mode must be valid first ([backendModeProblem]): sandbox mode has no
  /// service to check, and http mode also checks SYNC_BASE_URL.
  void validate({bool production = kReleaseMode, bool? tetherUi}) {
    final forTetherUi = tetherUi ?? selectAppUi() == AppUi.tetherUi;
    if (forTetherUi) {
      // Profile builds are checked like release builds.
      production = production || !kDebugMode;
      final problem = backendModeProblem(debug: !production);
      if (problem != null) {
        throw FormatException('This build is misconfigured. $problem');
      }
      if (!_isHttp) return;
    }
    if (production) {
      final problems = releaseEndpointProblems(
        supabaseUrl: supabaseUrl,
        apiBaseUrl: apiBaseUrl,
        syncBaseUrl: forTetherUi ? syncBaseUrl : null,
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
    for (final value in [
      apiBaseUrl,
      supabaseUrl,
      if (forTetherUi) syncBaseUrl,
    ]) {
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
