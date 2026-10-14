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
}) =>
    jsonEncode({
      if (url != null) 'SUPABASE_URL': url,
      if (api != null) 'API_BASE_URL': api,
      if (key != null) 'SUPABASE_ANON_KEY': key,
    });

final defineCases = <DefineCase>[
  DefineCase('sb_publishable_ key', _define(), []),
  DefineCase('anon JWT', _define(key: fakeJwt({'role': 'anon'})), []),
  DefineCase(
    'sb_secret_ key',
    _define(key: 'sb_secret_${canary}secret'),
    ['SUPABASE_ANON_KEY is a privileged key'],
  ),
  DefineCase(
    'SB_SECRET_ key (upper case)',
    _define(key: 'SB_SECRET_${canary}secret'),
    ['SUPABASE_ANON_KEY is a privileged key'],
  ),
  DefineCase(
    'literal service_role key',
    _define(key: 'service_role_$canary'),
    ['SUPABASE_ANON_KEY is a privileged key'],
  ),
  DefineCase(
    'service_role JWT',
    _define(key: fakeJwt({'role': 'service_role'})),
    ['SUPABASE_ANON_KEY is a JWT whose role is not "anon"'],
  ),
  DefineCase(
    'role-less JWT',
    _define(key: fakeJwt({})),
    ['SUPABASE_ANON_KEY is a JWT whose role is not "anon"'],
  ),
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
  DefineCase(
    'http API_BASE_URL',
    _define(api: 'http://api.example.org'),
    ['API_BASE_URL must be an absolute https URL'],
  ),
  DefineCase(
    'relative SUPABASE_URL',
    _define(url: 'example-project.supabase.co'),
    ['SUPABASE_URL must be an absolute https URL'],
  ),
  const DefineCase(
    'missing keys',
    '{}',
    [
      'SUPABASE_URL is missing or empty',
      'API_BASE_URL is missing or empty',
      'SUPABASE_ANON_KEY is missing or empty',
    ],
  ),
  DefineCase(
    'blank key and non-string URL',
    _define(url: 42, key: '   '),
    [
      'SUPABASE_URL is missing or empty',
      'SUPABASE_ANON_KEY is missing or empty',
    ],
  ),
  const DefineCase(
    'not JSON',
    'SUPABASE_ANON_KEY=sb_secret_$canary',
    ['cannot read define file as JSON'],
  ),
  const DefineCase(
    'JSON array',
    '["sb_secret_$canary"]',
    ['define file must be a JSON object'],
  ),
];
