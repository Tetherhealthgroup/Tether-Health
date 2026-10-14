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
    'U+200B': '\u200B',
    'U+FEFF': '\uFEFF',
    'U+00AD': '\u00AD',
    'U+2060': '\u2060',
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
  /// Segments are decoded as raw bytes with NUL bytes dropped, so UTF-16 and
  /// UTF-32 payloads count; trailing characters are dropped until it decodes.
  bool carries(String value, String canary) {
    if (value.contains(canary)) return true;
    for (final segment in value.split('.')) {
      for (var cut = 0; cut < 4 && cut < segment.length; cut++) {
        try {
          final bytes = base64Url.decode(
            base64Url.normalize(segment.substring(0, segment.length - cut)),
          );
          final text = latin1.decode(bytes.where((b) => b != 0).toList());
          if (text.contains(canary)) return true;
          break;
        } catch (_) {}
      }
    }
    return false;
  }

  /// A token whose payload is a plain anon object and whose last segment is
  /// [bytes], base64url-encoded without padding (the shape of a signature).
  String anonThen(List<int> bytes) => '${b64(hs256)}.${b64('{"role":"anon"}')}.'
      '${base64Url.encode(bytes).replaceAll('=', '')}';

  List<int> utf16(String text, {required bool bigEndian}) => [
        for (final unit in text.codeUnits)
          ...bigEndian ? [unit >> 8, unit & 0xFF] : [unit & 0xFF, unit >> 8],
      ];

  List<int> utf32le(String text) => [
        for (final unit in text.codeUnits) ...[unit & 0xFF, unit >> 8, 0, 0],
      ];

  List<int> utf32be(String text) => [
        for (final unit in text.codeUnits) ...[0, 0, unit >> 8, unit & 0xFF],
      ];

  /// Base64url of [json] (padded with spaces until the length is not a multiple
  /// of three) whose last character also sets the unused low bits.
  String nonCanonical(String json) {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    var text = json;
    while (utf8.encode(text).length % 3 == 0) {
      text = '$text ';
    }
    final body = b64(text);
    final spare = body.length % 4 == 2 ? 0x0F : 0x03;
    final last = alphabet.indexOf(body[body.length - 1]) | spare;
    return '${body.substring(0, body.length - 1)}${alphabet[last]}';
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
        'service_role with inner invisible': 'service\u200B_role-$canary',
        for (final e in secretLead.entries)
          'sb_secret_ after ${e.key}': '${e.value}sb_secret_$canary',
        'sb_secret_ with inner U+200B': 'sb_\u200Bsecret_$canary',
        'sb_secret_ mixed case after U+200B': '\u200BSB_Secret_$canary',
        'escaped backslash before the closing quote': token(
          hs256,
          '{"a":"\\\\","ref":"$canary","role":"admin"}',
        ),
        'anon payload then NaN object (A)': anonThen(
          utf8.encode('{"role":"admin","ref":"$canary","x":NaN}'),
        ),
        'anon payload then NaN object, role last (B)': anonThen(
          utf8.encode('{"x":NaN,"ref":"$canary","role":"admin"}'),
        ),
        'anon payload then UTF-16LE object (C)': anonThen(
          utf16('{"role":"admin","ref":"$canary"}', bigEndian: false),
        ),
        'anon payload then UTF-16BE object': anonThen(
          utf16('{"role":"admin","ref":"$canary"}', bigEndian: true),
        ),
        'anon payload then UTF-32LE object': anonThen(
          utf32le('{"role":"admin","ref":"$canary"}'),
        ),
        'anon payload then UTF-16LE object with BOM': anonThen([
          0xFF,
          0xFE,
          ...utf16('{"role":"admin","ref":"$canary"}', bigEndian: false),
        ]),
        'anon payload then object with UTF-8 BOM (D)': anonThen([
          0xEF,
          0xBB,
          0xBF,
          ...utf8.encode('{"role":"admin","ref":"$canary"}'),
        ]),
        'anon payload then CESU surrogate bytes (E)': anonThen([
          ...utf8.encode('{"role":"admin","ref":"$canary","s":"'),
          0xED,
          0xA0,
          0x80,
          ...utf8.encode('"}'),
        ]),
        'anon payload then upper-case ROLE with -Infinity (F)': anonThen(
          utf8.encode('{"ROLE":"admin","ref":"$canary","x":-Infinity}'),
        ),
        // TH-140 (F1 of TH-138): the role key is spelled with a JSON escape
        // (backslash-u0072 is "r"), so the text has no literal "role" and only
        // the escape fallback in _pythonOnlyRoles can reject these.
        'anon payload then escaped role key with NaN (UTF-8)': anonThen(
          utf8.encode('{"\\u0072ole":"admin","ref":"$canary","x":NaN}'),
        ),
        'anon payload then escaped role key (UTF-32BE)': anonThen(
          utf32be('{"\\u0072ole":"admin","ref":"$canary","x":NaN}'),
        ),
        'anon payload then escaped role key (FE FF BOM, UTF-16BE)': anonThen([
          0xFE,
          0xFF,
          ...utf16(
            '{"\\u0072ole":"admin","ref":"$canary","x":NaN}',
            bigEndian: true,
          ),
        ]),
        'anon payload then non-canonical base64 trailing bits':
            '${b64(hs256)}.${b64('{"role":"anon"}')}.'
                '${nonCanonical('{"role":"admin","ref":"$canary"}')}',
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

    test('accepts quoted and escaped anon payloads (lexer cases)', () {
      for (final payload in [
        '{"role":"anon","x":"role"}',
        '{"role":"anon","note":"\\"role\\":\\"admin\\""}',
        '{"role":"\\u0061non"}',
        '{"\\u0072ole":"\\u0061non"}',
        '{"role":"anon","a":"\\\\"}',
      ]) {
        expect(
          AppConfig.anonKeyProblem(token(hs256, payload)),
          isNull,
          reason: payload,
        );
      }
    });

    test('accepts anon tokens whose signature is random bytes', () {
      for (final length in [32, 64]) {
        final random = Random(length);
        for (var i = 0; i < 2000; i++) {
          final signature = [
            for (var j = 0; j < length; j++) random.nextInt(256)
          ];
          expect(
            AppConfig.anonKeyProblem(anonThen(signature)),
            isNull,
            reason: 'seed $length, signature $i',
          );
        }
      }
    });

    test('accepts a decodable anon object as the last segment', () {
      expect(
        AppConfig.anonKeyProblem(anonThen(utf8.encode('{"role":"anon"}'))),
        isNull,
      );
    });

    test('removes zero-width and control characters inside an anon JWT', () {
      final anon = token(hs256, '{"role":"anon"}');
      expect(AppConfig.anonKeyProblem('\u200B$anon\uFEFF'), isNull);
    });
  });
}
