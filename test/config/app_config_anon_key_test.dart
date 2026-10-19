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

  const roleNotAnon = 'SUPABASE_ANON_KEY is a JWT whose role is not "anon".';
  const notAllowlisted =
      'SUPABASE_ANON_KEY is not a publishable key (sb_publishable_...) '
      'or an anon JWT.';
  const privilegedKey = 'SUPABASE_ANON_KEY is a privileged key.';

  /// TH-141 (R-055): the helper's EXTRA_INVISIBLE code points (a21dd15) that
  /// Dart's Cf table does not strip, so AppConfig lists them itself. Ends of
  /// each range and, for the longer ranges, a middle point.
  const mirroredInvisible = {
    'U+034F combining grapheme joiner': '\u034F',
    'U+115F hangul choseong filler': '\u115F',
    'U+1160 hangul jungseong filler': '\u1160',
    'U+17B4 khmer inherent vowel aq': '\u17B4',
    'U+17B5 khmer inherent vowel aa': '\u17B5',
    'U+180B mongolian free variation selector one': '\u180B',
    'U+180C mongolian free variation selector two': '\u180C',
    'U+180D mongolian free variation selector three': '\u180D',
    'U+180F mongolian free variation selector four': '\u180F',
    'U+2065 unassigned default-ignorable': '\u2065',
    'U+2800 braille pattern blank': '\u2800',
    'U+3164 hangul filler': '\u3164',
    'U+FE00 variation selector 1': '\uFE00',
    'U+FE08 variation selector 9': '\uFE08',
    'U+FE0F variation selector 16': '\uFE0F',
    'U+FFA0 halfwidth hangul filler': '\uFFA0',
    'U+FFF0 unassigned default-ignorable (low end)': '\uFFF0',
    'U+FFF4 unassigned default-ignorable (middle)': '\uFFF4',
    'U+FFF8 unassigned default-ignorable (high end)': '\uFFF8',
    'U+E0000 unassigned tag block start': '\u{E0000}',
    'U+E0100 variation selector 17': '\u{E0100}',
    'U+E0FFF end of variation selectors supplement': '\u{E0FFF}',
  };

  /// Helper EXTRA_INVISIBLE entries that Dart's Cf table already strips (so
  /// nothing is mirrored for them). Pinned so that a change to the table is
  /// noticed. They pass before TH-141 as well.
  const coveredByCf = {
    'U+0890 arabic pound mark above (Cf)': '\u0890',
    'U+13439 egyptian hieroglyph insertion (Cf)': '\u{13439}',
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
        for (final e in {...mirroredInvisible, ...coveredByCf}.entries) ...{
          'sb_secret_ split by ${e.key}': 'sb_${e.value}secret_$canary',
          'service_role split by ${e.key}': 'service${e.value}_role-$canary',
        },
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

  /// The exact problem text for the cases whose message is pinned: the three
  /// escape cases (TH-140) and the invisible-character cases (TH-141).
  String? pinnedProblem(String name) {
    if (name.startsWith('anon payload then escaped role key')) {
      return roleNotAnon;
    }
    if (name.startsWith('sb_secret_ split by U+') ||
        name.startsWith('service_role split by U+')) {
      return privilegedKey;
    }
    return null;
  }

  group('anonKeyProblem parity with release_define_check.sh', () {
    final canary = newCanary();
    for (final entry in rejected(canary).entries) {
      test('rejects ${entry.key}', () {
        final problem = AppConfig.anonKeyProblem(entry.value);
        expect(problem, isNotNull);
        final pinned = pinnedProblem(entry.key);
        if (pinned != null) expect(problem, pinned);
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

    test('keeps accepting an anon JWT and a publishable key', () {
      final anon = token(hs256, '{"role":"anon","iss":"synthetic","exp":1}');
      expect(AppConfig.anonKeyProblem(anon), isNull);
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

    test(
        'rejects a publishable key with an invisible character outside a '
        'marker by the allowlist, not as privileged (TH-141, TH-904)', () {
      for (final e in {...mirroredInvisible, ...coveredByCf}.entries) {
        for (final key in [
          'sb_publishable_${e.value}Ab12Cd34Ef56Gh78Ij90Kl12Mn34Op56',
          'sb_publishable_Ab12Cd34Ef56Gh78Ij90Kl12Mn34Op56${e.value}',
          '${e.value}sb_publishable_Ab12Cd34Ef56Gh78Ij90Kl12Mn34Op56',
        ]) {
          expect(AppConfig.anonKeyProblem(key), notAllowlisted, reason: e.key);
        }
      }
    });

    test('does not remove the mirrored characters inside a JWT segment', () {
      // As in the helper: stripping before decoding would turn this
      // undecodable key into an accepted one.
      final payload = b64('{"role":"anon"}');
      for (final e in mirroredInvisible.entries) {
        final key = '${b64(hs256)}.${payload.substring(0, 6)}${e.value}'
            '${payload.substring(6)}.c2ln';
        expect(
          AppConfig.anonKeyProblem(key),
          'SUPABASE_ANON_KEY looks like a JWT but cannot be decoded.',
          reason: e.key,
        );
      }
    });

    test('rejects an anon JWT wrapped in zero-width characters (TH-904)', () {
      final anon = token(hs256, '{"role":"anon"}');
      expect(AppConfig.anonKeyProblem('\u200B$anon\uFEFF'), notAllowlisted);
    });
  });

  // TH-904: SUPABASE_ANON_KEY is an allowlist, as in
  // tool/release_define_check.sh. Each value passed the old denylist.
  group('anonKeyProblem allowlist (TH-904)', () {
    final canary = newCanary();
    final anon = token(hs256, '{"role":"anon","ref":"$canary"}');
    final notAllowed = <String, String>{
      'raw JWT-signing-secret-shaped string':
          '${canary}rawSigningSecret0123456789abcdefABCDEF+/=',
      'hex secret-shaped string': '0f1e2d3c4b5a69788796a5b4c3d2e1f0$canary',
      'sk_live_ key': 'sk_live_$canary',
      'placeholder from the old tests': 'public-placeholder-$canary',
      'example file placeholder': 'your-publishable-or-anonymous-key-$canary',
      'bare sb_publishable_ prefix plus a dot': 'sb_publishable_.$canary',
      'publishable key with surrounding whitespace': ' sb_publishable_$canary ',
      'publishable key with a trailing newline': 'sb_publishable_$canary\n',
      'anon JWT with surrounding whitespace': ' \n$anon\t ',
      'anon JWT after a Bearer prefix': 'Bearer $anon',
      'anon JWT with four segments': '$anon.c2ln',
      'anon role only nested': token(
        hs256,
        '{"claims":{"role":"anon"},"ref":"$canary"}',
      ),
      'anon JWT whose payload holds NaN': token(
        hs256,
        '{"role":"anon","x":NaN,"ref":"$canary"}',
      ),
    };

    for (final MapEntry(key: name, value: key) in notAllowed.entries) {
      test('rejects $name without echoing it', () {
        expect(carries(key, canary), isTrue, reason: 'canary placed');
        final problem = AppConfig.anonKeyProblem(key);
        expect(problem, isNotNull);
        expect(leaks(problem!, canary), isFalse);
        final config = AppConfig(
          apiBaseUrl: 'https://api.example.test',
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: key,
        );
        for (final production in [true, false]) {
          Object? thrown;
          try {
            config.validate(production: production);
          } catch (e) {
            thrown = e;
          }
          expect(thrown, isA<FormatException>());
          expect(leaks(thrown.toString(), canary), isFalse);
        }
      });
    }

    test('names the allowlist when no specific problem applies', () {
      expect(AppConfig.anonKeyProblem('sk_live_$canary'), notAllowlisted);
      expect(AppConfig.anonKeyProblem('sb_publishable_'), notAllowlisted);
      expect(AppConfig.anonKeyProblem('$anon.c2ln'), notAllowlisted);
      expect(AppConfig.anonKeyProblem('Bearer $anon'), notAllowlisted);
    });

    test('accepts the allowlisted shapes', () {
      expect(AppConfig.anonKeyProblem('sb_publishable_Ab-12_cd'), isNull);
      expect(AppConfig.anonKeyProblem(anon), isNull);
    });
  });
}
