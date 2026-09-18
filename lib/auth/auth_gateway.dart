import 'package:supabase_flutter/supabase_flutter.dart';

class AuthIdentity {
  const AuthIdentity(
      {required this.id, required this.email, required this.accessToken});
  final String id;
  final String? email;
  final String accessToken;
}

abstract interface class AuthGateway {
  AuthIdentity? get currentIdentity;
  Future<AuthIdentity> signIn(
      {required String email, required String password});
  Future<void> signOut();

  /// A token that is still valid, refreshing first if it is not.
  ///
  /// Separate from `currentIdentity.accessToken`, which is whatever the last
  /// sign-in returned and is only good for about an hour. A caller sending it
  /// to a service gets a 401 that looks like a permissions problem rather than
  /// an expiry, so anything crossing the network asks for this instead.
  ///
  /// Null when nobody is signed in. Never throws for that case: "not signed
  /// in" is an ordinary state, not a failure.
  Future<String?> freshAccessToken();
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);
  final SupabaseClient _client;

  @override
  AuthIdentity? get currentIdentity => _identity(_client.auth.currentSession);

  @override
  Future<AuthIdentity> signIn(
      {required String email, required String password}) async {
    final response =
        await _client.auth.signInWithPassword(email: email, password: password);
    final identity = _identity(response.session);
    if (identity == null) {
      throw const AuthException('No authenticated session was returned.');
    }
    return identity;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<String?> freshAccessToken() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    if (!session.isExpired) return session.accessToken;

    // Expired. The SDK refreshes in the background, but a request can land in
    // the gap, so refresh here rather than send a token already known to be
    // dead. A refresh that fails means the session is gone for good — the
    // caller is told "not signed in" and signs in again, which is the honest
    // outcome and better than a 401 it cannot interpret.
    try {
      final refreshed = await _client.auth.refreshSession();
      return refreshed.session?.accessToken;
    } catch (_) {
      return null;
    }
  }

  AuthIdentity? _identity(Session? session) {
    if (session == null) return null;
    return AuthIdentity(
        id: session.user.id,
        email: session.user.email,
        accessToken: session.accessToken);
  }
}

class DisabledAuthGateway implements AuthGateway {
  const DisabledAuthGateway();
  @override
  AuthIdentity? get currentIdentity => null;
  @override
  Future<AuthIdentity> signIn(
          {required String email, required String password}) =>
      Future.error(
          StateError('Account services are not configured for this build.'));
  @override
  Future<void> signOut() async {}

  @override
  Future<String?> freshAccessToken() async => null;
}
