import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthIdentity {
  const AuthIdentity({
    required this.id,
    required this.email,
    required this.accessToken,
  });

  final String id;
  final String? email;
  final String accessToken;
}

enum AuthSignUpStatus { authenticated, emailConfirmationRequired }

class AuthSignUpResult {
  const AuthSignUpResult._({required this.status, this.identity});

  const AuthSignUpResult.authenticated(AuthIdentity identity)
      : this._(status: AuthSignUpStatus.authenticated, identity: identity);

  const AuthSignUpResult.emailConfirmationRequired()
      : this._(status: AuthSignUpStatus.emailConfirmationRequired);

  final AuthSignUpStatus status;
  final AuthIdentity? identity;
}

abstract interface class AuthGateway {
  AuthIdentity? get currentIdentity;

  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  });

  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  });

  Future<void> resendSignUpConfirmation({required String email});

  Future<void> signOut();
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(
    this._client, {
    String? emailRedirectTo,
  }) : _emailRedirectTo = emailRedirectTo ??
            (kIsWeb ? null : 'io.breathefree.patient://login-callback');

  final SupabaseClient _client;
  final String? _emailRedirectTo;

  @override
  AuthIdentity? get currentIdentity => _identity(_client.auth.currentSession);

  @override
  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final identity = _identity(response.session);
    if (identity == null) {
      throw const AuthException('No authenticated session was returned.');
    }
    return identity;
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      emailRedirectTo: _emailRedirectTo,
      email: email,
      password: password,
    );
    final identity = _identity(response.session);
    return identity == null
        ? const AuthSignUpResult.emailConfirmationRequired()
        : AuthSignUpResult.authenticated(identity);
  }

  @override
  Future<void> resendSignUpConfirmation({required String email}) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: _emailRedirectTo,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  AuthIdentity? _identity(Session? session) {
    if (session == null) return null;
    return AuthIdentity(
      id: session.user.id,
      email: session.user.email,
      accessToken: session.accessToken,
    );
  }
}

class DisabledAuthGateway implements AuthGateway {
  const DisabledAuthGateway();

  @override
  AuthIdentity? get currentIdentity => null;

  @override
  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  }) =>
      Future.error(
        StateError('Account services are not configured for this build.'),
      );

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) =>
      Future.error(
        StateError('Account services are not configured for this build.'),
      );

  @override
  Future<void> resendSignUpConfirmation({required String email}) =>
      Future.error(
        StateError('Account services are not configured for this build.'),
      );

  @override
  Future<void> signOut() async {}
}
