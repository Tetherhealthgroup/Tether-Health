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

  void validate({bool production = kReleaseMode}) {
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
    final normalizedKey = supabaseAnonKey.toLowerCase();
    if (normalizedKey.contains('service_role') ||
        normalizedKey.startsWith('sb_secret_')) {
      throw const FormatException(
        'Flutter requires a Supabase publishable or anonymous key.',
      );
    }
  }
}
