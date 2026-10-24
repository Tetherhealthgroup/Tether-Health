// Sign-up age check (P-68, P-72, P-73). The checks fail closed, and
// validate.py runs the same checks, with the same two tables, on the
// generator spec.
//
// Walks every route in spec/screens.json from every screen (so a screen no
// route reaches yet is checked too) and from the entry points in
// spec/app.json:
//  - every submit to supabase /auth/ creates an account unless
//    [_authNotCreating] lists it, and each account-creating submit sits
//    inside the ob.age rule's "Age confirmed" case on its own screen;
//  - every native sign-in branch outside "Age confirmed" is pinned in
//    [_preAgeSignIn] with exactly its outcome labels;
//  - a native sign-in outcome for an Apple ID or Google account with no
//    Tether account enters the normal sign-up at its start (ob_programs, the
//    screen welcome "Get started" opens), so programmes and consent come
//    first and the account is created on ob_account.
//
// Back and close are not followed: they return to a screen the walk already
// reached. A variant counts as reachable from its base.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Auth endpoints that do not create an account, each with the reason. Any
/// other submit to supabase /auth/ counts as account-creating.
const _authNotCreating = <String, String>{
  'POST supabase /auth/v1/recover': 'sends a reset link for an existing account',
  'POST supabase /auth/v1/token': 'password grant: signs in an existing account',
  'POST supabase /auth/v1/user/identities (linkIdentity)': 'links an identity to the signed-in account',
  'PUT supabase /auth/v1/user': 'sets a new password on the signed-in account',
};

/// Native sign-in branches outside "Age confirmed", by screen and element
/// path, with their exact outcome labels. Each signs in, links or re-confirms
/// an existing account and has no outcome that creates one. A new branch or a
/// changed label needs the same review: a sign-in step that could create an
/// account belongs behind the age check on ob_account.
const _preAgeSignIn = <String, List<List<String>>>{
  'auth_signin body[1].items[0]': [
    ['Success', 'Success · guest plan on phone', 'New Apple ID, no Tether account', 'Cancelled', 'Error'],
  ],
  'auth_signin body[1].items[1]': [
    ['Success', 'Success · guest plan on phone', 'New Google account, no Tether account', 'Cancelled', 'Error'],
  ],
  'auth_signin_error body[2].items[0]': [
    ['Success', 'Success · guest plan on phone', 'New Apple ID, no Tether account', 'Cancelled', 'Error'],
  ],
  'auth_signin_error body[2].items[1]': [
    ['Success', 'Success · guest plan on phone', 'New Google account, no Tether account', 'Cancelled', 'Error'],
  ],
  'auth_social_error footer[0]': [
    ['Success', 'Error'],
  ],
  'account_signin_methods body[1].rows[1]': [
    ['Success', 'Email already has a Tether account', 'Cancelled', 'Error'],
  ],
  'account_delete_apple footer[0]': [
    ['Success', 'Different account', 'Cancelled', 'Error'],
  ],
  'account_delete_google footer[0]': [
    ['Success', 'Different account', 'Cancelled', 'Error'],
  ],
  'auth_session_apple footer[0].items[0]': [
    ['Success', 'Cancelled', 'Error'],
  ],
  'auth_session_google footer[0].items[0]': [
    ['Success', 'Cancelled', 'Error'],
  ],
};

const _navigations = {'push', 'replace', 'tab', 'sheet', 'reset', 'popto'};
const _signUp = 'ob_programs';

/// A submit endpoint whose path is on supabase /auth/ (dsl.is_auth_endpoint).
bool _isAuth(String endpoint) {
  final i = endpoint.indexOf(' ');
  return i > 0 && endpoint.substring(i + 1).startsWith('supabase /auth/');
}

bool _createsAccount(String endpoint) => _isAuth(endpoint) && !_authNotCreating.containsKey(endpoint);

typedef _State = (String, bool);

class _Walk {
  _Walk(this.screens);
  final Map<String, dynamic> screens;
  final via = <_State, (_State?, String?)>{};
  final unconfirmed = <String>[];
  final confirmed = <String>[];
  final authSubmits = <String>{};

  /// Native sign-in branches outside "Age confirmed": where → outcome labels.
  final native = <String, Set<String>>{};
  final newIdentity = <String, Map<String, dynamic>>{};

  void run(Iterable<String> entries) {
    final todo = <_State>[];
    void reach(_State s, _State? prev, String? label) {
      if (screens.containsKey(s.$1) && !via.containsKey(s)) {
        via[s] = (prev, label);
        todo.add(s);
      }
    }

    void visit(_State s, String element, String path, Map<String, dynamic>? a, bool ok) {
      if (a == null) return;
      final type = a['type'] as String;
      if (type == 'submit') {
        final api = a['api'] as String;
        if (_isAuth(api)) authSubmits.add(api);
        if (_createsAccount(api)) (ok ? confirmed : unconfirmed).add('${s.$1} "$element" $api; route: ${route(s)}');
      }
      if (type == 'submit' || type == 'toast') visit(s, element, path, a['then'] as Map<String, dynamic>?, ok);
      if (type == 'branch') {
        final cases = (a['cases'] as List).cast<Map<String, dynamic>>();
        if (a['provider'] != null && !ok) {
          native.putIfAbsent('${s.$1} $path', () => <String>{}).add(jsonEncode([for (final c in cases) c['label']]));
        }
        for (final c in cases) {
          final label = c['label'] as String;
          if (a['provider'] != null && label.contains('no Tether account')) newIdentity['${s.$1} $path → $label'] = c['action'] as Map<String, dynamic>;
          visit(s, element, path, c['action'] as Map<String, dynamic>, ok || (a['decide'] == 'ob.age' && label == 'Age confirmed'));
        }
      }
      if (_navigations.contains(type)) {
        for (final to in [a['to'], (a['context'] as Map<String, dynamic>?)?['onboarding']]) {
          if (to != null) reach((to as String, ok), s, element);
        }
      }
    }

    for (final e in entries) {
      reach((e, false), null, null);
    }
    while (todo.isNotEmpty) {
      final s = todo.removeAt(0);
      for (final x in (screens[s.$1]['actions'] as List).cast<Map<String, dynamic>>()) {
        visit(s, x['element'] as String, x['path'] as String, x['action'] as Map<String, dynamic>?, s.$2);
      }
      for (final MapEntry(key: id, value: v) in screens.entries) {
        if (v['variantOf'] == s.$1) reach((id, s.$2), s, null);
      }
    }
  }

  String route(_State s) {
    final out = <String>[];
    _State? at = s;
    while (at != null) {
      final (prev, label) = via[at]!;
      out.add('${label == null ? '' : '"$label" → '}${at.$1}');
      at = prev;
    }
    return out.reversed.join(' ');
  }
}

Map<String, Set<String>> _pinned() => {
      for (final MapEntry(key: where, value: sets) in _preAgeSignIn.entries) where: {for (final labels in sets) jsonEncode(labels)},
    };

void main() {
  final screens = jsonDecode(File('../spec/screens.json').readAsStringSync()) as Map<String, dynamic>;
  final app = jsonDecode(File('../spec/app.json').readAsStringSync()) as Map<String, dynamic>;
  final entries = [for (final e in (app['entries'] as List).cast<Map<String, dynamic>>()) e['screen'] as String];

  group('sign-up age check', () {
    test('every account-creating submit sits inside "Age confirmed" (walk from every screen)', () {
      final walk = _Walk(screens)..run(screens.keys);
      expect(walk.unconfirmed, isEmpty);
      expect(walk.confirmed, contains(startsWith('ob_account "Create account" POST supabase /auth/v1/signup')));
    });

    test('no route from an entry point creates an account without "Age confirmed"', () {
      final walk = _Walk(screens)..run(entries);
      expect(entries, contains('welcome'));
      expect(walk.unconfirmed, isEmpty);
      expect(walk.confirmed, contains(startsWith('ob_account "Create account" POST supabase /auth/v1/signup')),
          reason: 'the normal sign-up is reachable from welcome, after the age check');
    });

    test('every auth endpoint that does not create an account is submitted somewhere', () {
      final walk = _Walk(screens)..run(screens.keys);
      expect(walk.authSubmits, containsAll(_authNotCreating.keys));
    });

    test('a new Apple ID or Google account from sign-in enters the normal sign-up at its start', () {
      final walk = _Walk(screens)..run(screens.keys);
      expect(walk.newIdentity.keys, containsAll(['auth_signin body[1].items[0] → New Apple ID, no Tether account', 'auth_signin body[1].items[1] → New Google account, no Tether account',
        'auth_signin_error body[2].items[0] → New Apple ID, no Tether account', 'auth_signin_error body[2].items[1] → New Google account, no Tether account']));
      final getStarted = (screens['welcome']['actions'] as List).cast<Map<String, dynamic>>().firstWhere((x) => x['element'] == 'Get started');
      expect(getStarted['action'], {'type': 'push', 'to': _signUp}, reason: 'welcome "Get started" starts the normal sign-up');
      for (final MapEntry(key: where, value: a) in walk.newIdentity.entries) {
        expect(_navigations, contains(a['type']), reason: where);
        expect(a['to'], _signUp, reason: where);
        expect(a['context'], isNull, reason: where);
      }
      final from = _Walk(screens)..run([_signUp]);
      for (final step in ['ob_consent', 'ob_account']) {
        expect(from.via.keys, contains((step, false)), reason: 'the normal sign-up reaches $step');
      }
    });

    test('native sign-in outside "Age confirmed" matches the pinned branches and outcome labels exactly', () {
      final walk = _Walk(screens)..run(screens.keys);
      expect(walk.native, _pinned());
    });

    test('the checks fail closed (synthetic spec)', () {
      Map<String, dynamic> scr(List<Map<String, dynamic>> actions) => {
            'actions': [for (final (i, a) in actions.indexed) {'element': 'B$i', 'path': 'footer[$i]', 'action': a}],
          };
      Map<String, dynamic> social(String to, [List<Map<String, dynamic>> more = const []]) => {
            'type': 'branch', 'provider': 'apple',
            'cases': [
              {'label': 'New Apple ID, no Tether account', 'action': {'type': 'push', 'to': to}},
              {'label': 'Cancelled', 'action': {'type': 'back'}},
              ...more,
            ],
          };
      Map<String, dynamic> gate(Map<String, dynamic> a) => {
            'type': 'branch', 'decide': 'ob.age',
            'cases': [
              {'label': 'Age confirmed', 'action': a},
              {'label': 'Age not confirmed', 'action': {'type': 'toast', 'value': 'x'}},
            ],
          };
      Map<String, dynamic> submit(String api) => {'type': 'submit', 'api': api, 'then': {'type': 'back'}};
      final old = {
        'welcome': scr([{'type': 'sheet', 'to': 'auth_signin'}]),
        'auth_signin': scr([social('auth_social_new')]),
        'auth_social_new': scr([{'type': 'submit', 'api': 'POST supabase /auth/v1/token?grant_type=id_token', 'then': {'type': 'push', 'to': 'welcome'}}]),
      };
      final walk = _Walk(old)..run(['welcome']);
      expect(walk.unconfirmed, ['auth_social_new "B0" POST supabase /auth/v1/token?grant_type=id_token; route: welcome "B0" → auth_signin "B0" → auth_social_new']);
      expect(walk.newIdentity.values.single['to'], isNot(_signUp));

      final gated = {'s': scr([gate(submit('POST supabase /auth/v1/signup')), submit('POST supabase /auth/v1/token'), gate(social(_signUp))])};
      final ok = _Walk(gated)..run(gated.keys);
      expect(ok.unconfirmed, isEmpty);
      expect(ok.confirmed, hasLength(1));
      expect(ok.native, isEmpty, reason: 'a native sign-in inside "Age confirmed" is not pre-age');

      for (final api in ['POST supabase /auth/v1/signup', 'POST supabase /auth/v1/otp', 'POST supabase /auth/v1/token?grant_type=id_token']) {
        final bare = {'s': scr([submit(api)])};
        expect((_Walk(bare)..run(bare.keys)).unconfirmed, hasLength(1), reason: '$api outside "Age confirmed"');
      }
      final unreached = {'a': scr([{'type': 'back'}]), 'b': scr([submit('POST supabase /auth/v1/signup')])};
      expect((_Walk(unreached)..run(unreached.keys)).unconfirmed, hasLength(1), reason: 'a screen no route reaches is checked');
      final labels = {'s': scr([social(_signUp, [{'label': 'Success', 'action': {'type': 'reset', 'to': 'today'}}])])};
      expect((_Walk(labels)..run(labels.keys)).native, {'s footer[0]': {jsonEncode(['New Apple ID, no Tether account', 'Cancelled', 'Success'])}});
    });
  });
}
