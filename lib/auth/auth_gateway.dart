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
}
