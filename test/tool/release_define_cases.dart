import 'dart:convert';

// Synthetic release define files shared by the Play and iOS release script
// tests. Every key is a made-up canary token: none is a real Supabase key.
// Each test asserts that [canary] never appears in the script's output.

const canary = 'TH105CANARY';

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
/// that many more segments. The canary sits in the payload and signature.
String shapedJwt({
  Object header = const {'alg': 'HS256', 'typ': 'JWT'},
  required Object payload,
  bool pad = false,
  int extra = 0,
}) {
  String seg(Object json) {
    final text = json is String ? json : jsonEncode(json);
    final encoded = base64Url.encode(utf8.encode(text));
    return pad ? encoded : encoded.replaceAll('=', '');
  }

  return [
    seg(header),
    seg(payload),
    '${canary}sig',
    for (var i = 0; i < extra; i++) 'x$canary',
  ].join('.');
}

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
    ['SERVER_KEY holds a privileged key'],
  ),
  DefineCase(
    'zero-width sb_secret_ under another define key',
    _define(extra: {'SERVER_KEY': '\u200Bsb_secret_${canary}secret'}),
    ['SERVER_KEY holds a privileged key'],
  ),
  DefineCase(
    'service_role JWT under another define key',
    _define(
      extra: {
        'OTHER_TOKEN': fakeJwt({'role': 'service_role'}),
      },
    ),
    ['OTHER_TOKEN holds a JWT whose role is not "anon"'],
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
    ['OTHER_TOKEN holds a JWT whose role is not "anon"'],
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
    ['OTHER_TOKEN holds a JWT whose role is not "anon"'],
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
      'NESTED holds a privileged key',
      'LISTED holds a JWT whose role is not "anon"',
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
    [],
  ),
  // TH-123 send-back: key names never leak, nested key names are scanned,
  // duplicate keys are rejected.
  DefineCase(
    'privileged value under a key named like a secret',
    _define(extra: {'sb_secret_${canary}x': 'sb_secret_${canary}v'}),
    ['a define key holds a privileged key'],
  ),
  DefineCase(
    'privileged value under a key name with a space',
    _define(extra: {'bad key $canary': 'sb_secret_${canary}v'}),
    ['a define key holds a privileged key'],
  ),
  DefineCase(
    'privileged value under an upper-case secret-like key name',
    _define(extra: {'SB_SECRET_${canary}X': 'sb_secret_${canary}v'}),
    ['a define key holds a privileged key'],
  ),
  DefineCase(
    'secret-like top-level key name with a harmless value',
    _define(extra: {'sb_secret_${canary}n': 'x'}),
    ['a define key holds a privileged key'],
  ),
  DefineCase(
    'secret-like nested key name',
    _define(
      extra: {
        'NESTED_NAME': {'sb_secret_${canary}k': 1},
      },
    ),
    ['NESTED_NAME holds a privileged key'],
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
    ['a define key holds a JWT whose role is not "anon"'],
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
    ['a define key appears more than once in the define file'],
  ),
  const DefineCase(
    'duplicate nested key hiding a privileged value',
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
        '"API_BASE_URL":"https://api.example.org",'
        '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub",'
        '"NESTED":{"A":"sb_secret_${canary}s","A":"ok"}}',
    ['A appears more than once in the define file'],
  ),
];

/// A define file whose value is an array nested [depth] deep. The helper must
/// fail closed or accept it, never crash with a traceback.
String deepNestingDefine(int depth) =>
    '{"SUPABASE_URL":"https://example-project.supabase.co",'
    '"API_BASE_URL":"https://api.example.org",'
    '"SUPABASE_ANON_KEY":"sb_publishable_${canary}pub",'
    '"DEEP":${'[' * depth}${']' * depth}}';
