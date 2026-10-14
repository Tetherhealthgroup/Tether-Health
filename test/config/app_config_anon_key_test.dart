import 'dart:convert';
import 'dart:math';

import 'package:breathefree_patient/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// TH-138 (R-055): AppConfig.anonKeyProblem must reach the same verdicts as
/// the build-time helper tool/release_define_check.sh for SUPABASE_ANON_KEY.
/// Every token is built here from synthetic JSON; no real key is used.
void main() {
  String b64(String json) =>
      base64Url.encode(utf8.encode(json)).replaceAll('=', '');

  String token(String header, String payload, {String sig = 'c2ln'}) =>
      '${b64(header)}.${b64(payload)}.$sig';

  const hs256 = '{"alg":"HS256","typ":"JWT"}';
  const secretLead = {
    'U+200B': '​',
    'U+FEFF': '﻿',
    'U+00AD': '­',
    'U+2060': '⁠',
    'U+0000': '\u0000',
    'U+0007': '\u0007',
  };

  /// A random value that exists only while the test runs.
  String newCanary() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(24, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// True if [text] holds the canary or any 8-character window of it.
  bool leaks(String text, String canary) {
    for (var i = 0; i + 8 <= canary.length; i++) {
      if (text.contains(canary.substring(i, i + 8))) return true;
    }
    return false;
  }

  /// True if the canary sits in [value] itself or in a decoded segment of it.
  bool carries(String value, String canary) {
    if (value.contains(canary)) return true;
    for (final segment in value.split('.')) {
      try {
        final text =
            utf8.decode(base64Url.decode(base64Url.normalize(segment)));
        if (text.contains(canary)) return true;
      } catch (_) {}
    }
    return false;
  }

  Map<String, String> rejected(String canary) => {
        'header not starting with eyJ (space first)': token(
          '{ "alg":"HS256"}',
          '{"role":"service_role","ref":"$canary"}',
        ),
        'header not starting with eyJ (non-anon authenticated)': token(
          '{ "alg":"HS256"}',
          '{"role":"authenticated","ref":"$canary"}',
        ),
        'whitespace-prefixed header JSON': token(
          '\n  $hs256',
          '{"role":"service_role","ref":"$canary"}',
        ),
        'four segments, non-anon payload': '${b64(hs256)}.'
            '${b64('{"role":"service_role","ref":"$canary"}')}.c2ln.c2ln',
        'four segments, anon payload then non-anon segment': '${b64(hs256)}.'
            '${b64('{"role":"anon"}')}.'
            '${b64('{"role":"service_role","ref":"$canary"}')}.c2ln',
        'duplicate role, service_role first, anon last': token(
          hs256,
          '{"role":"service_role","ref":"$canary","role":"anon"}',
        ),
        'duplicate role, nested': token(
          hs256,
          '{"role":"anon","meta":{"role":"service_role","ref":"$canary"}}',
        ),
        'duplicate role, different case': token(
          hs256,
          '{"Role":"service_role","ref":"$canary","role":"anon"}',
        ),
        'duplicate role, escaped key name': token(
          hs256,
          '{"\\u0072ole":"service_role","ref":"$canary","role":"anon"}',
        ),
        'no role in payload': token(hs256, '{"ref":"$canary"}'),
        'role is not a string': token(hs256, '{"role":null,"ref":"$canary"}'),
        'undecodable payload': '${b64(hs256)}.%%%$canary.c2ln',
        'plain sb_secret_': 'sb_secret_$canary',
        'sb_secret_ with inner whitespace': 'sb_ secret_$canary',
        'service_role literal': 'service_role-$canary',
        'service_role with inner invisible': 'service​_role-$canary',
        for (final e in secretLead.entries)
          'sb_secret_ after ${e.key}': '${e.value}sb_secret_$canary',
        'sb_secret_ with inner U+200B': 'sb_​secret_$canary',
        'sb_secret_ mixed case after U+200B': '​SB_Secret_$canary',
        'Bearer-prefixed non-anon JWT':
            'Bearer ${token(hs256, '{"role":"service_role","ref":"$canary"}')}',
      };

  group('anonKeyProblem parity with release_define_check.sh', () {
    final canary = newCanary();
    for (final entry in rejected(canary).entries) {
      test('rejects ${entry.key}', () {
        expect(AppConfig.anonKeyProblem(entry.value), isNotNull);
      });

      test('never echoes key material for ${entry.key}', () {
        expect(carries(entry.value, canary), isTrue, reason: 'canary placed');
        final problem = AppConfig.anonKeyProblem(entry.value);
        expect(problem, isNotNull);
        expect(problem!.startsWith('SUPABASE_ANON_KEY '), isTrue);
        expect(leaks(problem, canary), isFalse, reason: 'problem leaks');

        final config = AppConfig(
          apiBaseUrl: 'https://api.example.test',
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: entry.value,
        );
        Object? thrown;
        try {
          config.validate(production: true);
        } catch (e) {
          thrown = e;
        }
        expect(thrown, isA<FormatException>());
        final message = (thrown as FormatException).message;
        expect(leaks(message, canary), isFalse, reason: 'message leaks');
        expect(leaks(thrown.toString(), canary), isFalse,
            reason: 'toString leaks');
      });
    }

    test('rejects a blank key, including in validate()', () {
      for (final blank in ['', '   ', '\n\t ', '\u00A0\u3000']) {
        expect(
          AppConfig.anonKeyProblem(blank),
          'SUPABASE_ANON_KEY is missing or empty.',
        );
      }
      const config = AppConfig(
        apiBaseUrl: 'https://api.example.test',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: '   ',
      );
      expect(() => config.validate(production: false), throwsFormatException);
    });

    test('keeps accepting an anon JWT, publishable and placeholder keys', () {
      final anon = token(hs256, '{"role":"anon","iss":"synthetic","exp":1}');
      expect(AppConfig.anonKeyProblem(anon), isNull);
      expect(AppConfig.anonKeyProblem(' \n$anon\t '), isNull);
      expect(AppConfig.anonKeyProblem('Bearer $anon'), isNull);
      expect(
        AppConfig.anonKeyProblem(
          '${base64Url.encode(utf8.encode(hs256))}.'
          '${base64Url.encode(utf8.encode('{"role":"anon"}'))}.c2ln',
        ),
        isNull,
        reason: 'padded segments',
      );
      expect(
        AppConfig.anonKeyProblem(
          'sb_publishable_Ab12Cd34Ef56Gh78Ij90Kl12Mn34Op56',
        ),
        isNull,
      );
      expect(AppConfig.anonKeyProblem('public-placeholder'), isNull);
      final config = AppConfig(
        apiBaseUrl: 'https://api.example.test',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: anon,
      );
      expect(() => config.validate(production: true), returnsNormally);
    });

    test('removes zero-width and control characters inside an anon JWT', () {
      final anon = token(hs256, '{"role":"anon"}');
      expect(AppConfig.anonKeyProblem('​$anon﻿'), isNull);
    });
  });
}
