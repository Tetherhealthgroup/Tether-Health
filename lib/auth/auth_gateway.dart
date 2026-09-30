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

abstract interface class RecentAuthGateway {
  Future<AuthIdentity> reauthenticate({required String password});
}

abstract interface class PasswordRecoveryGateway {
  Stream<void> get passwordRecoveryEvents;

  Future<void> requestPasswordReset({required String email});

  Future<void> updatePassword({required String newPassword});
}

class SupabaseAuthGateway
    implements AuthGateway, RecentAuthGateway, PasswordRecoveryGateway {
  SupabaseAuthGateway(
    this._client, {
    String? emailRedirectTo,
  }) : _emailRedirectTo = emailRedirectTo ??
            (kIsWeb ? null : 'io.breathefree.patient://login-callback');

  final SupabaseClient _client;
  final String? _emailRedirectTo;

  @override
  Stream<void> get passwordRecoveryEvents => _client.auth.onAuthStateChange
      .where((event) => event.event == AuthChangeEvent.passwordRecovery)
      .map((_) {});

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
  Future<AuthIdentity> reauthenticate({required String password}) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw const AuthException('A signed-in email account is required.');
    }
    return signIn(email: email, password: password);
  }

  @override
  Future<void> requestPasswordReset({required String email}) =>
      _client.auth.resetPasswordForEmail(
        email,
        redirectTo: _emailRedirectTo,
      );

  @override
  Future<void> updatePassword({required String newPassword}) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

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

  @override
  Future<String?> freshAccessToken() async => null;
}
