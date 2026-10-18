import 'dart:convert';

// Synthetic release define files shared by the Play and iOS release script
// tests. Every key is a made-up canary token: none is a real Supabase key.
// Each test asserts that [canary] never appears in the script's output.

const canary = 'TH105CANARY';

/// TH-130: an obviously fake, AWS-key-ID-shaped canary used as a define KEY
/// NAME. It matches [A-Z][A-Z0-9_]{0,63}, the shape the helper once printed.
/// It must never reach stdout or stderr.
const keyCanary = 'AKIAFAKECANARY0000000';

String _segment(Map<String, Object?> json) =>
    base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

/// A JWT-shaped token (header starts with eyJ) with [payload] and a fake
/// signature. The canary sits inside the encoded payload and the signature.
String fakeJwt(Map<String, Object?> payload) => [
      _segment({'alg': 'HS256', 'typ': 'JWT'}),
      _segment({...payload, 'ref': canary}),
      '${canary}sig',
    ].join('.');

/// A JWT-shaped token built segment by segment, for shapes [fakeJwt] cannot
/// make. [header] and [payload] are a JSON map or raw JSON text (raw text
/// allows duplicate keys); [pad] keeps the base64 padding; [extra] appends
/// that many more segments; [later] are raw JSON texts encoded as segments
/// placed right after the payload (TH-137); an element that is a `List<int>`
/// is used as raw bytes instead of UTF-8 text. The canary sits in the payload
/// and signature.
String shapedJwt({
  Object header = const {'alg': 'HS256', 'typ': 'JWT'},
  required Object payload,
  bool pad = false,
  int extra = 0,
  List<Object> later = const [],
}) {
  String seg(Object json) {
    final text = json is String ? json : jsonEncode(json);
    final encoded = base64Url.encode(utf8.encode(text));
    return pad ? encoded : encoded.replaceAll('=', '');
  }

  String laterSeg(Object item) {
    if (item is! List<int>) return seg(item);
    final encoded = base64Url.encode(item);
    return pad ? encoded : encoded.replaceAll('=', '');
  }

  return [
    seg(header),
    seg(payload),
    for (final item in later) laterSeg(item),
    '${canary}sig',
    for (var i = 0; i < extra; i++) 'x$canary',
  ].join('.');
}

/// Every 8-character window of [text] (TH-137 leak check). Output that holds
/// one of these holds a fragment of the canary.
List<String> windows(String text, {int size = 8}) => [
      for (var i = 0; i + size <= text.length; i++) text.substring(i, i + size),
    ];

/// The windows of both canaries; none may appear in any script output.
final canaryWindows = [...windows(canary), ...windows(keyCanary)];

/// TH-137 (R-055): invisible characters outside Unicode Cf and Cc that the
/// helper must remove before it looks for sb_secret_ or service_role. Each is
/// written as an escape so that the source shows what it is.
const invisibleOutsideCfCc = <String, String>{
  'U+034F combining grapheme joiner': '\u034F',
  'U+115F hangul choseong filler': '\u115F',
  'U+1160 hangul jungseong filler': '\u1160',
  'U+3164 hangul filler': '\u3164',
  'U+FFA0 halfwidth hangul filler': '\uFFA0',
  'U+2800 braille pattern blank': '\u2800',
  'U+FE0F variation selector 16': '\uFE0F',
  'U+180B mongolian free variation selector': '\u180B',
  'U+E0100 variation selector 17': '\u{E0100}',
  'U+0890 arabic pound mark above': '\u0890',
  'U+13439 egyptian hieroglyph insertion': '\u{13439}',
};

/// The text of a payload with a raw control character inside a JSON string.
/// A strict JSON parser rejects it. It has a non-anon role (TH-137, F2).
const controlCharPayload =
    '{"role":"service_role","note":"a\u0001b","ref":"$canary"}';

/// UTF-16 code units of [text] as bytes, little or big endian, no BOM.
List<int> utf16Bytes(String text, {required bool bigEndian}) => [
      for (final unit in text.codeUnits)
        ...bigEndian ? [unit >> 8, unit & 0xFF] : [unit & 0xFF, unit >> 8],
    ];

// TH-137 send-back R1: payloads that are not valid JSON (a raw control
// character) and reach the role check only through one branch of the helper's
// role-object fallback each. Escaped key, so no literal "role" in the text.
const _escapedKeyPayload = '{"\\u0072ole":"admin","n":"\u0001"}';

/// Raw later segments for the send-back cases: name -> bytes.
final opaqueSegments = <String, List<int>>{
  'an escaped role key and a control character (no literal role)':
      utf8.encode(_escapedKeyPayload),
  'a UTF-16LE control-character service_role payload without a BOM':
      utf16Bytes(controlCharPayload, bigEndian: false),
  'a UTF-8 BOM and a control-character service_role payload': [
    0xEF,
    0xBB,
    0xBF,
    ...utf8.encode(controlCharPayload),
  ],
  // TH-142: specifically exercise the FF FE BOM-removal branch.
  'FF FE, UTF-16LE and an escaped role key with a control character': [
    0xFF,
    0xFE,
    ...utf16Bytes(_escapedKeyPayload, bigEndian: false),
  ],
  'FE FF, UTF-16BE and an escaped role key': [
    0xFE,
    0xFF,
    ...utf16Bytes(_escapedKeyPayload, bigEndian: true),
  ],
};

class DefineCase {
  const DefineCase(this.name, this.contents, this.expected);

  final String name;

  /// Raw define file contents.
  final String contents;

  /// Message fragments the script must print on rejection; empty if the file
  /// must be accepted.
  final List<String> expected;

  bool get accepted => expected.isEmpty;

  /// The key value as written to the file, if any; must never be printed.
  String? get keyValue {
    try {
      final data = jsonDecode(contents);
      return data is Map ? data['SUPABASE_ANON_KEY'] as String? : null;
    } on FormatException {
      return null;
    }
  }
}

String _define({
  Object? url = 'https://example-project.supabase.co',
  Object? api = 'https://api.example.org',
  Object? key = 'sb_publishable_${canary}pub',
  Map<String, Object?> extra = const {},
}) =>
    jsonEncode({
      if (url != null) 'SUPABASE_URL': url,
      if (api != null) 'API_BASE_URL': api,
      if (key != null) 'SUPABASE_ANON_KEY': key,
      ...extra,
    });

const _anonRole = 'SUPABASE_ANON_KEY is a JWT whose role is not "anon"';
const _anonSecret = 'SUPABASE_ANON_KEY is a privileged key';
const _notAllowedKey =
    'SUPABASE_ANON_KEY is not a publishable key (sb_publishable_...) '
    'or an anon JWT';
const _notAllowed = 'is not an allowed define key (allowed: SUPABASE_URL, '
    'API_BASE_URL, SUPABASE_ANON_KEY)';
const _invalidHost = 'must not use a placeholder .invalid host';

final defineCases = <DefineCase>[
  DefineCase('sb_publishable_ key', _define(), []),
  DefineCase('anon JWT', _define(key: fakeJwt({'role': 'anon'})), []),
  DefineCase('sb_secret_ key', _define(key: 'sb_secret_${canary}secret'), [
    'SUPABASE_ANON_KEY is a privileged key',
  ]),
  DefineCase(
    'SB_SECRET_ key (upper case)',
    _define(key: 'SB_SECRET_${canary}secret'),
    ['SUPABASE_ANON_KEY is a privileged key'],
  ),
  DefineCase('literal service_role key', _define(key: 'service_role_$canary'), [
    'SUPABASE_ANON_KEY is a privileged key',
  ]),
  DefineCase(
    'service_role JWT',
    _define(key: fakeJwt({'role': 'service_role'})),
    ['SUPABASE_ANON_KEY is a JWT whose role is not "anon"'],
  ),
  DefineCase('role-less JWT', _define(key: fakeJwt({})), [
    'SUPABASE_ANON_KEY is a JWT whose role is not "anon"',
  ]),
  DefineCase(
    'undecodable JWT',
    _define(key: 'eyJ$canary.!!!$canary.${canary}sig'),
    ['SUPABASE_ANON_KEY looks like a JWT but cannot be decoded'],
  ),
  DefineCase(
    'http SUPABASE_URL',
    _define(url: 'http://example-project.supabase.co'),
    ['SUPABASE_URL must be an absolute https URL'],
  ),
  DefineCase('http API_BASE_URL', _define(api: 'http://api.example.org'), [
    'API_BASE_URL must be an absolute https URL',
  ]),
  DefineCase(
    'relative SUPABASE_URL',
    _define(url: 'example-project.supabase.co'),
    ['SUPABASE_URL must be an absolute https URL'],
  ),
  const DefineCase('missing keys', '{}', [
    'SUPABASE_URL is missing or empty',
    'API_BASE_URL is missing or empty',
    'SUPABASE_ANON_KEY is missing or empty',
  ]),
  DefineCase('blank key and non-string URL', _define(url: 42, key: '   '), [
    'SUPABASE_URL is missing or empty',
    'SUPABASE_ANON_KEY is missing or empty',
  ]),
  const DefineCase('not JSON', 'SUPABASE_ANON_KEY=sb_secret_$canary', [
    'cannot read define file as JSON',
  ]),
  const DefineCase('JSON array', '["sb_secret_$canary"]', [
    'define file must be a JSON object',
  ]),
  // TH-123: shapes that earlier passed the check (R-055 residuals), and
  // privileged-looking values under define keys other than SUPABASE_ANON_KEY.
  DefineCase(
    'service_role JWT with a non-eyJ header',
    _define(
      key: shapedJwt(
        header: ' {"alg":"HS256"}',
        payload: {'role': 'service_role', 'ref': canary},
      ),
    ),
    [_anonRole],
  ),
  DefineCase(
    'service_role JWT after a Bearer prefix',
    _define(key: 'Bearer ${fakeJwt({'role': 'service_role'})}'),
    [_anonRole],
  ),
  DefineCase(
    'service_role JWT after a byte order mark',
    _define(key: '\uFEFF${fakeJwt({'role': 'service_role'})}'),
    [_anonRole],
  ),
  DefineCase(
    'service_role JWT with four segments',
    _define(
      key: shapedJwt(
        payload: {'role': 'service_role', 'ref': canary},
        extra: 1,
      ),
    ),
    [_anonRole],
  ),
  DefineCase(
    'padded service_role JWT',
    _define(
      key: shapedJwt(
        payload: {'role': 'service_role', 'ref': canary},
        pad: true,
      ),
    ),
    [_anonRole],
  ),
  DefineCase(
    'duplicate role keys, service_role first',
    _define(
      key: shapedJwt(
        payload: '{"role":"service_role","role":"anon","ref":"$canary"}',
      ),
    ),
    [_anonRole],
  ),
  DefineCase(
    'duplicate role keys, service_role last',
    _define(
      key: shapedJwt(
        payload: '{"role":"anon","role":"service_role","ref":"$canary"}',
      ),
    ),
    [_anonRole],
  ),
  DefineCase(
    'upper-case Role key',
    _define(key: shapedJwt(payload: {'Role': 'service_role', 'ref': canary})),
    [_anonRole],
  ),
  DefineCase(
    'sb_secret_ after a zero-width space',
    _define(key: '\u200Bsb_secret_${canary}secret'),
    [_anonSecret],
  ),
  DefineCase(
    'sb_secret_ split by a zero-width joiner and a space',
    _define(key: 'sb_\u200D se cret_${canary}secret'),
    [_anonSecret],
  ),
  DefineCase(
    'undecodable dotted value without an eyJ header',
    _define(key: 'abc.!!!$canary.${canary}sig'),
    ['SUPABASE_ANON_KEY looks like a JWT but cannot be decoded'],
  ),
  DefineCase(
    'sb_secret_ under another define key',
    _define(extra: {'SERVER_KEY': 'sb_secret_${canary}secret'}),
    ['define key #4 holds a privileged key'],
  ),
  DefineCase(
    'zero-width sb_secret_ under another define key',
    _define(extra: {'SERVER_KEY': '\u200Bsb_secret_${canary}secret'}),
    ['define key #4 holds a privileged key'],
  ),
  DefineCase(
    'service_role JWT under another define key',
    _define(
      extra: {
        'OTHER_TOKEN': fakeJwt({'role': 'service_role'}),
      },
    ),
    ['define key #4 holds a JWT whose role is not "anon"'],
  ),
  DefineCase(
    'padded 4-segment service_role JWT with a non-eyJ header under another key',
    _define(
      extra: {
        'OTHER_TOKEN': shapedJwt(
          header: ' {"alg":"none"}',
          payload: {'role': 'service_role', 'ref': canary},
          pad: true,
          extra: 1,
        ),
      },
    ),
    ['define key #4 holds a JWT whose role is not "anon"'],
  ),
  DefineCase(
    'duplicate role keys under another define key',
    _define(
      extra: {
        'OTHER_TOKEN': shapedJwt(
          payload: '{"role":"anon","role":"service_role","ref":"$canary"}',
        ),
      },
    ),
    ['define key #4 holds a JWT whose role is not "anon"'],
  ),
  DefineCase(
    'privileged values nested in a list and an object',
    _define(
      extra: {
        'NESTED': {
          'list': ['x', 'sb_secret_${canary}secret'],
        },
        'LISTED': [
          fakeJwt({'role': 'service_role'}),
        ],
      },
    ),
    [
      'define key #4 holds a privileged key',
      'define key #5 holds a JWT whose role is not "anon"',
    ],
  ),
  DefineCase(
    'padded anon JWT',
    _define(
      key: shapedJwt(payload: {'role': 'anon', 'ref': canary}, pad: true),
    ),
    [],
  ),
  DefineCase(
    'anon JWT with a non-eyJ header',
    _define(
      key: shapedJwt(
        header: ' {"alg":"HS256"}',
        payload: {'role': 'anon', 'ref': canary},
      ),
    ),
    [],
  ),
  // TH-904 (th-security M1): accepted before; any top-level key outside the
  // three allowed ones is now rejected, whatever its value.
  DefineCase(
    'anon JWT and publishable key under another define keys',
    _define(
      extra: {
        'OTHER_TOKEN': fakeJwt({'role': 'anon'}),
        'OTHER_PUBLISHABLE': 'sb_publishable_${canary}pub',
        'FLAG': true,
        'COUNT': 3,
        'HOST': 'a.b.c',
      },
    ),
    [
      for (var n = 4; n <= 8; n++) 'define key #$n $_notAllowed',
    ],
  ),
  // TH-123 send-back: key names never leak, nested key names are scanned,
  // duplicate keys are rejected.
  DefineCase(
    'privileged value under a key named like a secret',
    _define(extra: {'sb_secret_${canary}x': 'sb_secret_${canary}v'}),
    ['define key #4 holds a privileged key'],
  ),
  DefineCase(
    'privileged value under a key name with a space',
    _define(extra: {'bad key $canary': 'sb_secret_${canary}v'}),
    ['define key #4 holds a privileged key'],
  ),
  DefineCase(
    'privileged value under an upper-case secret-like key name',
    _define(extra: {'SB_SECRET_${canary}X': 'sb_secret_${canary}v'}),
    ['define key #4 holds a privileged key'],
  ),
  DefineCase(
    'secret-like top-level key name with a harmless value',
    _define(extra: {'sb_secret_${canary}n': 'x'}),
    ['define key #4 holds a privileged key'],
  ),
  DefineCase(
    'secret-like nested key name',
    _define(
      extra: {
        'NESTED_NAME': {'sb_secret_${canary}k': 1},
      },
    ),
    ['define key #4 holds a privileged key'],
  ),
  DefineCase(
    'service_role JWT in a nested list under a key named like a secret',
    _define(
      extra: {
        'SB_SECRET_${canary}Y': [
          [
            fakeJwt({'role': 'service_role'})
          ],
        ],
      },
    ),
    ['define key #4 holds a JWT whose role is not "anon"'],
  ),
  const DefineCase(
    'duplicate SUPABASE_ANON_KEY, privileged first',
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
        '"API_BASE_URL":"https://api.example.org",'
        '"SUPABASE_ANON_KEY":"sb_secret_${canary}a",'
        '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub"}',
    ['SUPABASE_ANON_KEY appears more than once in the define file'],
  ),
  const DefineCase(
    'duplicate lower-case key',
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
        '"API_BASE_URL":"https://api.example.org",'
        '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub",'
        '"dup_$canary":"a","dup_$canary":"b"}',
    ['define key #4 (also #5) appears more than once in the define file'],
  ),
  const DefineCase(
    'duplicate nested key hiding a privileged value',
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
        '"API_BASE_URL":"https://api.example.org",'
        '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub",'
        '"NESTED":{"A":"sb_secret_${canary}s","A":"ok"}}',
    ['define key #4>#1 (also #2) appears more than once in the define file'],
  ),
  // TH-130 (R-085): a flagged key is named only if it is allowlisted; any
  // other key, here the canary, is shown by position and never by name.
  DefineCase(
    'privileged value under an allowlisted server key (R1)',
    _define(extra: {'SUPABASE_SERVICE_ROLE_KEY': 'sb_secret_${canary}s'}),
    ['SUPABASE_SERVICE_ROLE_KEY holds a privileged key'],
  ),
  DefineCase(
    'canary as a top-level key name holding a privileged value',
    _define(extra: {keyCanary: 'sb_secret_${canary}v'}),
    ['define key #4 holds a privileged key'],
  ),
  const DefineCase(
    'canary as a duplicated top-level key name',
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
        '"API_BASE_URL":"https://api.example.org",'
        '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub",'
        '"$keyCanary":"a","$keyCanary":"b"}',
    ['define key #4 (also #5) appears more than once in the define file'],
  ),
  const DefineCase(
    'canary as a duplicated nested key name',
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
        '"API_BASE_URL":"https://api.example.org",'
        '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub",'
        '"NESTED":{"$keyCanary":"a","$keyCanary":"b"}}',
    ['define key #4>#1 (also #2) appears more than once in the define file'],
  ),
  const DefineCase(
    'canary as a duplicated key name in an object inside an array',
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
        '"API_BASE_URL":"https://api.example.org",'
        '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub",'
        '"LISTED":[1,{"$keyCanary":"a","$keyCanary":"b"}]}',
    [
      'define key #4>[2]>#1 (also #2) appears more than once in the define file'
    ],
  ),
  const DefineCase(
    'allowlisted duplicate top-level key is named',
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
        '"API_BASE_URL":"https://api.example.org",'
        '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub",'
        '"API_BASE_URL":"https://api.example.org"}',
    ['API_BASE_URL appears more than once in the define file'],
  ),
  // TH-137 F2: a later segment with a raw control character and a non-anon
  // role must not hide behind an earlier anon segment.
  DefineCase(
    'anon segment, then a control-character service_role segment',
    _define(
      key: shapedJwt(
        payload: {'role': 'anon', 'ref': canary},
        later: [controlCharPayload],
      ),
    ),
    [_anonRole],
  ),
  DefineCase(
    'control-character service_role segment, then an anon segment',
    _define(
      key: shapedJwt(
        payload: controlCharPayload,
        later: ['{"role":"anon","ref":"$canary"}'],
      ),
    ),
    [_anonRole],
  ),
  DefineCase(
    'control-character service_role segment as the only payload',
    _define(key: shapedJwt(payload: controlCharPayload)),
    ['SUPABASE_ANON_KEY looks like a JWT but cannot be decoded'],
  ),
  DefineCase(
    'anon segment, then a control-character service_role segment, other key',
    _define(
      extra: {
        'OTHER_TOKEN': shapedJwt(
          payload: {'role': 'anon', 'ref': canary},
          later: [controlCharPayload],
        ),
      },
    ),
    ['define key #4 holds a JWT whose role is not "anon"'],
  ),
  DefineCase(
    'control-character segment with no role under another key',
    _define(
      extra: {
        'OTHER_TOKEN': shapedJwt(
          payload: {'role': 'anon', 'ref': canary},
          later: ['{"note":"a\u0001b","ref":"$canary"}'],
        ),
      },
    ),
    // TH-904: accepted before; OTHER_TOKEN is not an allowed key.
    ['define key #4 $_notAllowed'],
  ),
  // TH-137 send-back R1: each branch of the role-object fallback (backslash-u
  // escape, NUL removal, BOM removal) is needed by one of these. An anon
  // segment comes first, so the file is accepted without the fallback.
  for (final MapEntry(key: name, value: bytes) in opaqueSegments.entries) ...[
    DefineCase(
      'anon segment, then $name',
      _define(
        key: shapedJwt(
          payload: {'role': 'anon', 'ref': canary},
          later: [bytes],
        ),
      ),
      [_anonRole],
    ),
    DefineCase(
      'anon segment, then $name, other key',
      _define(
        extra: {
          'OTHER_TOKEN': shapedJwt(
            payload: {'role': 'anon', 'ref': canary},
            later: [bytes],
          ),
        },
      ),
      ['define key #4 holds a JWT whose role is not "anon"'],
    ),
  ],
  // TH-137 (a): invisible characters outside Cf and Cc inside the privileged
  // markers. Each must be removed before the substring checks, in a value, in
  // a nested value and in a key name.
  for (final MapEntry(key: name, value: invisible)
      in invisibleOutsideCfCc.entries) ...[
    DefineCase(
      'sb_secret_ split by $name',
      _define(key: 'sb_${invisible}secret_${canary}secret'),
      [_anonSecret],
    ),
    DefineCase(
      'service_role split by $name',
      _define(key: 'service${invisible}_role_$canary'),
      [_anonSecret],
    ),
    DefineCase(
      'sb_secret_ preceded by $name, under another define key',
      _define(extra: {'SERVER_KEY': '${invisible}sb_secret_${canary}secret'}),
      ['define key #4 holds a privileged key'],
    ),
    DefineCase(
      'sb_secret_ split by $name, under another define key',
      _define(extra: {'SERVER_KEY': 'sb_se${invisible}cret_${canary}secret'}),
      ['define key #4 holds a privileged key'],
    ),
    DefineCase(
      'sb_secret_ split by $name, nested',
      _define(
        extra: {
          'NESTED': {
            'list': ['x', 'sb_secret${invisible}_${canary}secret'],
          },
        },
      ),
      ['define key #4 holds a privileged key'],
    ),
    DefineCase(
      'sb_secret_ split by $name in a key name',
      _define(extra: {'sb_${invisible}secret_${canary}n': 'x'}),
      ['define key #4 holds a privileged key'],
    ),
  ],
  // TH-904: accepted before (only the sb_secret_/service_role markers were
  // checked); the allowlist admits only [A-Za-z0-9_-] after sb_publishable_.
  DefineCase(
    'invisible character inside an otherwise publishable key',
    _define(key: 'sb_publishable_\u3164${canary}pub'),
    [_notAllowedKey],
  ),
  // TH-904 (th-security M1): values that passed the old denylist. Each is a
  // synthetic canary, never a real key.
  DefineCase(
    'raw JWT-signing-secret-shaped string as the anon key',
    _define(key: '${canary}rawSigningSecret0123456789abcdefABCDEF+/='),
    [_notAllowedKey],
  ),
  DefineCase(
    'hex secret-shaped string as the anon key',
    _define(key: '0f1e2d3c4b5a69788796a5b4c3d2e1f0$canary'),
    [_notAllowedKey],
  ),
  DefineCase('sk_live_ key as the anon key', _define(key: 'sk_live_$canary'), [
    _notAllowedKey,
  ]),
  DefineCase(
    'publishable key with surrounding whitespace',
    _define(key: ' sb_publishable_${canary}pub '),
    [_notAllowedKey],
  ),
  DefineCase(
    'publishable key with a trailing newline',
    _define(key: 'sb_publishable_${canary}pub\n'),
    [_notAllowedKey],
  ),
  // The bare prefix 'sb_publishable_' is tested in app_config_anon_key_test:
  // here the no-echo check could not tell the value from the message.
  DefineCase(
    'sb_publishable_ prefix followed by a disallowed character',
    _define(key: 'sb_publishable_!$canary'),
    [_notAllowedKey],
  ),
  DefineCase(
    'anon JWT with four segments',
    _define(key: shapedJwt(payload: {'role': 'anon', 'ref': canary}, extra: 1)),
    [_notAllowedKey],
  ),
  DefineCase(
    'anon JWT after a Bearer prefix',
    _define(key: 'Bearer ${fakeJwt({'role': 'anon'})}'),
    [_notAllowedKey],
  ),
  DefineCase(
    'anon role only nested, not top-level',
    _define(
      key: fakeJwt({
        'claims': {'role': 'anon'},
      }),
    ),
    [_notAllowedKey],
  ),
  DefineCase(
    'anon JWT whose payload holds NaN',
    _define(key: shapedJwt(payload: '{"role":"anon","x":NaN,"ref":"$canary"}')),
    [_notAllowedKey],
  ),
  DefineCase(
    'unprefixed secret under OTHER_SECRET',
    _define(extra: {'OTHER_SECRET': 'rawServiceKey$canary'}),
    ['define key #4 $_notAllowed'],
  ),
  DefineCase(
    'unprefixed value under SUPABASE_SERVICE_ROLE_KEY',
    _define(extra: {'SUPABASE_SERVICE_ROLE_KEY': 'rawServiceKey$canary'}),
    ['SUPABASE_SERVICE_ROLE_KEY $_notAllowed'],
  ),
  DefineCase(
    'canary as an extra top-level key name with a harmless value',
    _define(extra: {keyCanary: 'x'}),
    ['define key #4 $_notAllowed'],
  ),
  const DefineCase(
    'the committed example file (config/dart_defines.example.json)',
    '{\n'
        '  "API_BASE_URL": "https://api.example.invalid",\n'
        '  "SUPABASE_URL": "https://your-project-ref.supabase.co",\n'
        '  "SUPABASE_ANON_KEY": "your-publishable-or-anonymous-key"\n'
        '}\n',
    ['API_BASE_URL $_invalidHost', _notAllowedKey],
  ),
  DefineCase(
    '.invalid SUPABASE_URL host',
    _define(url: 'https://project.example.invalid'),
    ['SUPABASE_URL $_invalidHost'],
  ),
  DefineCase(
    '.invalid host in upper case with a trailing dot and a port',
    _define(api: 'https://API.Example.INVALID.:443/v1'),
    ['API_BASE_URL $_invalidHost'],
  ),
  DefineCase(
    'a host that only contains invalid stays accepted',
    _define(api: 'https://invalid-api.example.org'),
    [],
  ),
  // TH-904 (th-security L1): Python json accepts these constants, Dart does
  // not, and Flutter would print the define content in its error.
  for (final constant in ['NaN', 'Infinity', '-Infinity'])
    DefineCase(
      '$constant as a define value',
      '{"SUPABASE_URL":"https://example-project.supabase.co",'
          '"API_BASE_URL":$constant,'
          '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub"}',
      ['cannot read define file as JSON'],
    ),
];

/// A define file whose value is an array nested [depth] deep. The helper must
/// fail closed or accept it, never crash with a traceback.
String deepNestingDefine(int depth) =>
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
    '"API_BASE_URL":"https://api.example.org",'
    '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub",'
    '"DEEP":${'[' * depth}${']' * depth}}';
