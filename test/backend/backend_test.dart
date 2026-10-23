// The backend interface, the factory and the stub backend.
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/backend/backend_factory.dart';
import 'package:breathefree_patient/backend/post_auth_hooks.dart';
import 'package:breathefree_patient/backend/stub_backend.dart';
import 'package:breathefree_patient/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

const _none = AppConfig(apiBaseUrl: '', supabaseUrl: '', supabaseAnonKey: '');

void main() {
  group('BackendRequest', () {
    test('needs an absolute path without a query', () {
      BackendRequest make(String path) => BackendRequest(
            service: BackendService.api,
            method: BackendMethod.get,
            path: path,
          );
      expect(() => make('/v1/enrolments'), returnsNormally);
      expect(() => make('v1/enrolments'), throwsArgumentError);
      expect(() => make('/v1/today?days=7'), throwsArgumentError);
      expect(() => make('/v1/today#x'), throwsArgumentError);
    });

    test('the query is unmodifiable and nothing private is printed', () {
      final request = BackendRequest(
        service: BackendService.sync,
        method: BackendMethod.post,
        path: '/v1/sync/push',
        query: {'a': 'b'},
        body: {'note': 'private'},
        idempotencyKey: 'k-123',
      );
      expect(() => request.query['c'] = 'd', throwsUnsupportedError);
      final text = request.toString();
      expect(text, isNot(contains('private')));
      expect(text, isNot(contains('k-123')));
      expect(text, isNot(contains('/v1/sync/push')));
      expect(text, contains('BackendService.sync POST'));
    });

    test('methods carry their wire names', () {
      expect([for (final m in BackendMethod.values) m.wire],
          ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']);
    });
  });

  group('BackendResponse', () {
    test('ok never prints its body', () {
      expect(
          const BackendOk(200, {'mood': 'low'}).toString(), 'BackendOk(200)');
    });

    test('problem and unreachable compare by value', () {
      expect(const BackendProblem(409, 'x'), const BackendProblem(409, 'x'));
      expect(const BackendProblem(409, 'x'),
          isNot(const BackendProblem(409, 'y')));
      expect(const BackendUnreachable(), const BackendUnreachable());
    });
  });

  group('the stub backend', () {
    test('answers every request with problem(501, backend_not_ready)',
        () async {
      final backend = StubBackend(BackendMode.sandbox);
      for (final service in BackendService.values) {
        for (final method in BackendMethod.values) {
          expect(
            await backend.transport.send(BackendRequest(
              service: service,
              method: method,
              path: '/v1/anything',
            )),
            const BackendProblem(501, BackendCodes.notReady),
          );
        }
      }
    });

    test('nobody is signed in and nobody can sign in', () async {
      final auth = StubBackend(BackendMode.http).auth;
      expect(auth.currentIdentity, isNull);
      expect(await auth.accessToken(), isNull);
      expect(await auth.signInWithIdToken(IdTokenProvider.apple, 't'),
          AuthOutcome.error);
      expect(await auth.linkIdentity(IdTokenProvider.google, 't'),
          AuthOutcome.error);
      await expectLater(
        auth.signIn(email: 'a@sandbox.invalid', password: 'p'),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        auth.signUp(email: 'a@sandbox.invalid', password: 'p'),
        throwsA(isA<AuthFailure>()),
      );
      await auth.signOut();
      expect(await auth.passwordRecoveryEvents.isEmpty, isTrue);
    });

    test('the auth backend is the existing gateway set', () {
      final auth = StubBackend(BackendMode.sandbox).auth;
      expect(auth, isA<AuthGateway>());
      expect(auth, isA<RecentAuthGateway>());
      expect(auth, isA<PasswordRecoveryGateway>());
    });
  });

  group('createBackend', () {
    test('builds the configured mode', () {
      expect(createBackend(_none, debug: true).mode, BackendMode.sandbox);
      const http = AppConfig(
        apiBaseUrl: 'https://api.example.test',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'sb_publishable_synthetic-placeholder',
        syncBaseUrl: 'https://sync.example.test',
        backend: 'http',
      );
      expect(createBackend(http, debug: false).mode, BackendMode.http);
    });

    test('refuses a configuration with no valid mode', () {
      expect(() => createBackend(_none, debug: false),
          throwsA(isA<MisconfiguredBuildException>()));
      const partial = AppConfig(
        apiBaseUrl: 'https://api.example.test',
        supabaseUrl: '',
        supabaseAnonKey: '',
        backend: 'http',
      );
      expect(() => createBackend(partial, debug: true),
          throwsA(isA<MisconfiguredBuildException>()));
    });
  });

  group('PostAuthHooks', () {
    const event = PostAuthEvent(accountId: 'acct-1', isNewAccount: true);

    test('runs the steps in registration order, one at a time', () async {
      final order = <String>[];
      final hooks = PostAuthHooks()
        ..register((e) async {
          order.add('enrolments start');
          await Future<void>.delayed(Duration.zero);
          order.add('enrolments end');
        })
        ..register((e) async => order.add('consents ${e.isNewAccount}'));
      expect(hooks.length, 2);
      expect(await hooks.run(event), isTrue);
      expect(order, ['enrolments start', 'enrolments end', 'consents true']);
    });

    test('a failing step stops the steps after it', () async {
      final order = <String>[];
      final hooks = PostAuthHooks()
        ..register((_) async => order.add('first'))
        ..register((_) async => throw StateError('offline'))
        ..register((_) async => order.add('third'));
      expect(await hooks.run(event), isFalse);
      expect(order, ['first']);
    });

    test('the event never prints the account', () {
      expect(event.toString(), isNot(contains('acct-1')));
    });
  });
}
