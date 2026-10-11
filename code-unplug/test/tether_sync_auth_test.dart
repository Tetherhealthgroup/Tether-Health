import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/auth/auth_gateway.dart';
import 'package:tether_health/tether/sync/auth_token_source.dart';

/// The seam between sign-in and sync.
///
/// The sync client asks for a token on every request and the gateway answers
/// with one that is still valid. What matters here is the behaviour at the
/// edges — no session, an expired session, a refresh that fails — because each
/// of those reaches the sync client as a different outcome and only one of
/// them should look like "try again later".

/// A gateway with the session states under test, and no Supabase.
class _FakeGateway implements AuthGateway {
  _FakeGateway({this.identity, this.fresh, this.refreshFails = false});

  final AuthIdentity? identity;
  final String? fresh;
  final bool refreshFails;
  var freshCalls = 0;

  @override
  AuthIdentity? get currentIdentity => identity;

  @override
  Future<String?> freshAccessToken() async {
    freshCalls++;
    if (refreshFails) return null;
    return fresh;
  }

  @override
  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

const _identity = AuthIdentity(
  id: '11111111-1111-1111-1111-111111111111',
  email: 'someone@example.invalid',
  accessToken: 'stale-token-from-sign-in',
);

void main() {
  test('a signed-in person gets a client', () {
    final client = syncClientFor(
      _FakeGateway(identity: _identity, fresh: 'fresh'),
      baseUrl: Uri.parse('https://example.invalid'),
    );
    expect(client, isNotNull);
    client!.close();
  });

  test('nobody signed in means no client, not a failing one', () {
    // The caller branches once here rather than on every push.
    expect(
      syncClientFor(
        _FakeGateway(),
        baseUrl: Uri.parse('https://example.invalid'),
      ),
      isNull,
    );
  });

  test('an unconfigured build has no client', () {
    // No dart-defines is the ordinary case for a reviewer running the app.
    expect(
      syncClientFor(
        const DisabledAuthGateway(),
        baseUrl: Uri.parse('https://example.invalid'),
      ),
      isNull,
    );
  });

  test('the token asked for is the fresh one, not the sign-in one', () async {
    // The distinction this whole seam exists for: `currentIdentity` carries
    // whatever sign-in returned, which is dead about an hour later.
    final gateway = _FakeGateway(identity: _identity, fresh: 'fresh-token');
    final token = await supabaseTokenSource(gateway)();

    expect(token, 'fresh-token');
    expect(token, isNot(_identity.accessToken));
  });

  test('every call asks again rather than caching', () async {
    // A cached token is one that expired while the app was backgrounded.
    final gateway = _FakeGateway(identity: _identity, fresh: 'fresh');
    final source = supabaseTokenSource(gateway);
    await source();
    await source();
    await source();
    expect(gateway.freshCalls, 3);
  });

  test('a failed refresh reads as signed out, not as an error', () async {
    // `TetherSyncClient` turns a null token into a 401 SyncException with
    // isAuthFailure true, which tells the app to sign in again. Throwing here
    // would surface as a transport failure and get retried forever.
    final gateway = _FakeGateway(identity: _identity, refreshFails: true);
    expect(await supabaseTokenSource(gateway)(), isNull);
  });
}
