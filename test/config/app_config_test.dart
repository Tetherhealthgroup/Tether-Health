import 'dart:convert';

import 'package:breathefree_patient/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires all account service values together', () {
    const config = AppConfig(
        apiBaseUrl: 'https://api.example.test',
        supabaseUrl: '',
        supabaseAnonKey: '');
    expect(config.hasAnyConfiguration, isTrue);
    expect(config.validate, throwsFormatException);
  });

  test('accepts absolute configured service URLs', () {
    const config = AppConfig(
      apiBaseUrl: 'https://api.example.test',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'sb_publishable_synthetic-placeholder',
    );
    expect(() => config.validate(production: true), returnsNormally);
  });

  test('production rejects insecure or placeholder endpoints', () {
    const insecure = AppConfig(
      apiBaseUrl: 'http://api.example.test',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'sb_publishable_synthetic-placeholder',
    );
    expect(() => insecure.validate(production: true), throwsFormatException);

    const placeholder = AppConfig(
      apiBaseUrl: 'https://api.example.invalid',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'sb_publishable_synthetic-placeholder',
    );
    expect(() => placeholder.validate(production: true), throwsFormatException);
  });

  test('client configuration rejects privileged Supabase keys', () {
    const config = AppConfig(
      apiBaseUrl: 'https://api.example.test',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'sb_secret_must-never-ship',
    );
    expect(() => config.validate(production: true), throwsFormatException);
  });

  group('releaseEndpointProblems', () {
    List<String> problems(String supabase, String api) =>
        AppConfig.releaseEndpointProblems(
          supabaseUrl: supabase,
          apiBaseUrl: api,
        );

    test('accepts two https URLs', () {
      expect(
        problems('https://p.supabase.co', 'https://api.example.test'),
        isEmpty,
      );
    });

    test('reports missing and blank values by variable name', () {
      expect(problems('', 'https://api.example.test'), [
        'SUPABASE_URL is missing or empty.',
      ]);
      expect(problems('https://p.supabase.co', '   '), [
        'API_BASE_URL is missing or empty.',
      ]);
      expect(problems('', '').length, 2);
    });

    test('rejects http and scheme-less values', () {
      expect(problems('http://p.supabase.co', 'https://api.example.test'), [
        'SUPABASE_URL must use https.',
      ]);
      expect(problems('https://p.supabase.co', 'api.example.test'), [
        'API_BASE_URL is not an absolute URL.',
      ]);
      expect(problems('https://', 'https://api.example.test'), [
        'SUPABASE_URL is not an absolute URL.',
      ]);
    });

    test('validate in release names the failing variable', () {
      const config = AppConfig(
        apiBaseUrl: 'http://api.example.test',
        supabaseUrl: 'https://p.supabase.co',
        supabaseAnonKey: 'sb_publishable_synthetic-placeholder',
      );
      expect(
        () => config.validate(production: true),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('API_BASE_URL'),
          ),
        ),
      );
    });

    test('rejects user info, a query or a fragment without echoing it', () {
      const canary = 'TH904URLCANARY';
      for (final url in [
        'https://postgres:$canary@db.example.test',
        'https://$canary@db.example.test',
        'https://p.supabase.co/?apikey=$canary',
        'https://p.supabase.co/?',
        'https://p.supabase.co/#$canary',
      ]) {
        final asSupabase = problems(url, 'https://api.example.test');
        expect(
            asSupabase,
            [
              'SUPABASE_URL must not contain user info, a query or a fragment.',
            ],
            reason: url);
        final asApi = problems('https://p.supabase.co', url);
        expect(
            asApi,
            [
              'API_BASE_URL must not contain user info, a query or a fragment.',
            ],
            reason: url);
        for (final (supabase, api) in [
          (url, 'https://api.example.test'),
          ('https://p.supabase.co', url),
        ]) {
          final config = AppConfig(
            apiBaseUrl: api,
            supabaseUrl: supabase,
            supabaseAnonKey: 'sb_publishable_synthetic-placeholder',
          );
          Object? thrown;
          try {
            config.validate(production: true);
          } catch (e) {
            thrown = e;
          }
          expect(thrown, isA<FormatException>(), reason: url);
          expect(thrown.toString(), isNot(contains(canary)), reason: url);
        }
        expect(asSupabase.join(), isNot(contains(canary)));
        expect(asApi.join(), isNot(contains(canary)));
      }
    });

    test('SUPABASE_URL is scheme and host only; API_BASE_URL may have a path',
        () {
      expect(problems('https://p.supabase.co/rest/v1', 'https://a.test/v1'), [
        'SUPABASE_URL must be scheme and host only, without a path.',
      ]);
      expect(problems('https://p.supabase.co:443/', 'https://a.test/v1/'),
          isEmpty);
      expect(problems('https://p.supabase.co', 'https://a.test'), isEmpty);
    });

    test('debug validation keeps accepting http endpoints', () {
      const config = AppConfig(
        apiBaseUrl: 'http://localhost:3000',
        supabaseUrl: 'http://localhost:54321',
        supabaseAnonKey: 'sb_publishable_synthetic-placeholder',
      );
      expect(() => config.validate(production: false), returnsNormally);
    });
  });

  group('anonKeyProblem', () {
    String jwt(String role) {
      String enc(Map<String, Object> m) =>
          base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      return '${enc({'alg': 'none'})}.${enc({'role': role})}.sig';
    }

    test('accepts anon JWT and publishable keys', () {
      expect(AppConfig.anonKeyProblem(jwt('anon')), isNull);
      expect(AppConfig.anonKeyProblem('sb_publishable_abc'), isNull);
    });

    test('rejects a placeholder key (TH-904 allowlist)', () {
      expect(AppConfig.anonKeyProblem('public-placeholder'), isNotNull);
    });

    test('rejects privileged keys without echoing them', () {
      final token = jwt('service_role');
      for (final key in [
        token,
        jwt('authenticated'),
        'sb_secret_x',
        'eyJabc.%%%.sig',
      ]) {
        final problem = AppConfig.anonKeyProblem(key);
        expect(problem, isNotNull);
        expect(problem, isNot(contains(key)));
      }
    });

    test('validate rejects a service-role JWT', () {
      final config = AppConfig(
        apiBaseUrl: 'https://api.example.test',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: jwt('service_role'),
      );
      expect(() => config.validate(production: true), throwsFormatException);
    });
  });
}
