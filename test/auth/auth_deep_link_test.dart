import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_deep_link.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/auth/secure_pkce_storage.dart';
import 'package:breathefree_patient/auth/secure_session_storage.dart';
import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:breathefree_patient/profile/profile_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _sessionFields = 'access_token=synthetic-token'
    '&refresh_token=synthetic-refresh-token&expires_in=3600&token_type=bearer';

/// Links that must never be processed as an auth callback.
const _ignoredLinks = <String, String>{
  'session fields in the fragment':
      'io.breathefree.patient://login-callback#$_sessionFields',
  'session fields in the query':
      'io.breathefree.patient://login-callback?$_sessionFields',
  'recovery type with session fields in the fragment':
      'io.breathefree.patient://login-callback#$_sessionFields&type=recovery',
  'recovery type with session fields in the query':
      'io.breathefree.patient://login-callback?$_sessionFields&type=recovery',
  'recovery type without a code':
      'io.breathefree.patient://login-callback?type=recovery',
  'code together with session fields in the query':
      'io.breathefree.patient://login-callback?code=synthetic-code&$_sessionFields',
  'code together with session fields in the fragment':
      'io.breathefree.patient://login-callback?code=synthetic-code#$_sessionFields',
  'code only in the fragment':
      'io.breathefree.patient://login-callback#code=synthetic-code',
  'code with an empty fragment':
      'io.breathefree.patient://login-callback?code=synthetic-code#',
  'code with an error':
      'io.breathefree.patient://login-callback?code=synthetic-code&error=access_denied',
  'two codes':
      'io.breathefree.patient://login-callback?code=synthetic-code&code=synthetic-other',
  'empty code': 'io.breathefree.patient://login-callback?code=',
  'no parameters': 'io.breathefree.patient://login-callback',
  'wrong scheme': 'io.example.other://login-callback?code=synthetic-code',
  'wrong host': 'io.breathefree.patient://other-callback?code=synthetic-code',
  'extra path':
      'io.breathefree.patient://login-callback/extra?code=synthetic-code',
  'user info':
      'io.breathefree.patient://someone@login-callback?code=synthetic-code',
  'port': 'io.breathefree.patient://login-callback:8080?code=synthetic-code',
  'https link': 'https://example.test/login-callback?code=synthetic-code',
};

const _acceptedLinks = <String>[
  'io.breathefree.patient://login-callback?code=synthetic-code',
  'io.breathefree.patient://login-callback/?code=synthetic-code',
  'io.breathefree.patient://login-callback?code=synthetic-code&type=recovery',
];

const _verifierKey =
    '${SecurePkceStorage.keyPrefix}supabase.auth.token-code-verifier';

const _syntheticUser = <String, Object?>{
  'id': 'synthetic-user-01',
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'synthetic-user-01@example.test',
  'app_metadata': <String, Object?>{},
  'user_metadata': <String, Object?>{},
  'created_at': '2026-01-01T00:00:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isAuthCallbackUri', () {
    for (final entry in _ignoredLinks.entries) {
      test('ignores ${entry.key}', () {
        expect(isAuthCallbackUri(Uri.parse(entry.value)), isFalse);
      });
    }

    for (final link in _acceptedLinks) {
      test('accepts $link', () {
        expect(isAuthCallbackUri(Uri.parse(link)), isTrue);
      });
    }
  });

  test('auth options pin PKCE, secure storage and the callback predicate', () {
    final options = breatheFreeAuthClientOptions();

    expect(options.authFlowType, AuthFlowType.pkce);
    expect(options.detectSessionInUri, isTrue);
    expect(options.detectSessionInUriPredicate, same(isAuthCallbackUri));
    expect(options.localStorage, isA<SecureSessionStorage>());
    expect(options.pkceAsyncStorage, isA<SecurePkceStorage>());

    final mainSource = File('lib/main.dart').readAsStringSync();
    expect(mainSource, contains('authOptions: breatheFreeAuthClientOptions()'));
    expect(
      RegExp(r'authOptions:').allMatches(mainSource),
      hasLength(1),
    );
  });

  test('PKCE verifier storage reads, writes and removes secure storage',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecurePkceStorage();

    await storage.setItem(key: 'verifier', value: 'synthetic-verifier');
    expect(await storage.getItem(key: 'verifier'), 'synthetic-verifier');
    expect(
      await const FlutterSecureStorage()
          .read(key: '${SecurePkceStorage.keyPrefix}verifier'),
      'synthetic-verifier',
    );

    await storage.removeItem(key: 'verifier');
    expect(await storage.getItem(key: 'verifier'), isNull);
  });

  group('deep links delivered to an initialized Supabase client', () {
    const links = EventChannel('com.llfbandit.app_links/events');
    final requests = <http.Request>[];
    final events = <AuthChangeEvent>[];
    final errors = <Object>[];
    late MockStreamHandlerEventSink linkSink;
    late StreamSubscription<AuthState> eventSubscription;
    late SupabaseAuthGateway gateway;
    late AccountController account;

    // The fake auth server answers every endpoint successfully, so a link is
    // only ignored because the app chose not to process it.
    final server = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      if (path.endsWith('/token')) {
        return http.Response(
          jsonEncode({
            'access_token': 'synthetic-token',
            'refresh_token': 'synthetic-refresh-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': _syntheticUser,
          }),
          200,
        );
      }
      if (path.endsWith('/user') || path.endsWith('/signup')) {
        return http.Response(jsonEncode(_syntheticUser), 200);
      }
      if (path.endsWith('/recover')) return http.Response('{}', 200);
      if (path.endsWith('/logout')) return http.Response('', 204);
      return http.Response('{}', 404);
    });

    Iterable<String> authPaths() => requests
        .map((request) => request.url.path)
        .where((path) => path.endsWith('/token') || path.endsWith('/user'));

    Future<void> deliver(String link) async {
      linkSink.success(link);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    setUpAll(() async {
      FlutterSecureStorage.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        links,
        MockStreamHandler.inline(
          onListen: (_, sink) => linkSink = sink,
        ),
      );
      await Supabase.initialize(
        url: 'https://synthetic-project.example.test',
        publishableKey: 'synthetic-publishable-key',
        httpClient: server,
        authOptions: breatheFreeAuthClientOptions(),
        debug: false,
      );
      eventSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((state) => events.add(state.event), onError: errors.add);
      gateway = SupabaseAuthGateway(Supabase.instance.client);
      account = AccountController(
        auth: gateway,
        profiles: ProfileRepository(
          auth: gateway,
          api: const DisabledProfileApiClient(),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });

    tearDownAll(() async {
      account.dispose();
      await eventSubscription.cancel();
      await Supabase.instance.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(links, null);
    });

    setUp(() {
      requests.clear();
      events.clear();
      errors.clear();
    });

    tearDown(() async {
      if (Supabase.instance.client.auth.currentSession != null) {
        await gateway.signOut();
      }
      account.passwordRecoveryPending = false;
      await const FlutterSecureStorage().delete(key: _verifierKey);
    });

    void expectNoSessionChange() {
      expect(Supabase.instance.client.auth.currentSession, isNull);
      expect(gateway.currentIdentity, isNull);
      expect(account.isSignedIn, isFalse);
      expect(account.passwordRecoveryPending, isFalse);
      expect(authPaths(), isEmpty);
      expect(errors, isEmpty);
      expect(
        events,
        isNot(anyOf(
          contains(AuthChangeEvent.signedIn),
          contains(AuthChangeEvent.passwordRecovery),
        )),
      );
    }

    for (final entry in _ignoredLinks.entries) {
      test('ignores ${entry.key} with a pending sign-up', () async {
        await gateway.signUp(
          email: 'synthetic-user-01@example.test',
          password: 'synthetic-password',
        );
        expect(await const FlutterSecureStorage().read(key: _verifierKey),
            isNotNull);

        await deliver(entry.value);

        expectNoSessionChange();
      });

      test('ignores ${entry.key} with a pending password reset', () async {
        await gateway.requestPasswordReset(
          email: 'synthetic-user-01@example.test',
        );

        await deliver(entry.value);

        expectNoSessionChange();
      });
    }

    test('a code callback after sign-up exchanges the stored verifier',
        () async {
      await gateway.signUp(
        email: 'synthetic-user-01@example.test',
        password: 'synthetic-password',
      );
      final verifier =
          await const FlutterSecureStorage().read(key: _verifierKey);
      expect(verifier, isNotNull);

      await deliver(
          'io.breathefree.patient://login-callback?code=synthetic-code');

      final exchange = requests
          .singleWhere((request) => request.url.path.endsWith('/token'));
      expect(exchange.url.queryParameters['grant_type'], 'pkce');
      expect(jsonDecode(exchange.body), {
        'auth_code': 'synthetic-code',
        'code_verifier': verifier,
      });
      expect(gateway.currentIdentity?.id, 'synthetic-user-01');
      expect(gateway.currentIdentity?.accessToken, 'synthetic-token');
      expect(account.isSignedIn, isTrue);
      expect(account.passwordRecoveryPending, isFalse);
      expect(events, contains(AuthChangeEvent.signedIn));
      expect(
          await const FlutterSecureStorage().read(key: _verifierKey), isNull);
    });

    test('a code callback after a reset request opens password recovery',
        () async {
      await gateway.requestPasswordReset(
        email: 'synthetic-user-01@example.test',
      );

      await deliver(
          'io.breathefree.patient://login-callback?code=synthetic-code');

      expect(requests.where((request) => request.url.path.endsWith('/token')),
          hasLength(1));
      expect(gateway.currentIdentity?.id, 'synthetic-user-01');
      expect(account.passwordRecoveryPending, isTrue);
      expect(events, contains(AuthChangeEvent.passwordRecovery));
    });
  });
}
