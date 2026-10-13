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
  /// description (never containing the key) or null. Rejects service-role
  /// keys, `sb_secret_` keys and JWTs whose payload role is not `anon`.
  static String? anonKeyProblem(String key) {
    final lower = key.trim().toLowerCase();
    if (lower.contains('service_role') || lower.startsWith('sb_secret_')) {
      return 'SUPABASE_ANON_KEY is a privileged key.';
    }
    final parts = key.trim().split('.');
    if (parts.length == 3 && parts.first.startsWith('eyJ')) {
      try {
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        if (payload is Map && payload['role'] == 'anon') return null;
        return 'SUPABASE_ANON_KEY is a JWT whose role is not "anon".';
      } catch (_) {
        return 'SUPABASE_ANON_KEY looks like a JWT but cannot be decoded.';
      }
    }
    return null;
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
