import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_deep_link.dart';

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

enum AuthFailureReason {
  invalidCredentials,
  emailNotConfirmed,
  rateLimited,
  accountUnavailable,
  network,
  serviceUnavailable,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;
}

AuthFailure classifyAuthFailure(AuthException error) {
  final code = error.code;
  if (code == 'invalid_credentials' ||
      code == 'user_not_found' ||
      code == 'invalid_grant') {
    return const AuthFailure(AuthFailureReason.invalidCredentials);
  }
  if (code == 'email_not_confirmed') {
    return const AuthFailure(AuthFailureReason.emailNotConfirmed);
  }
  if (code == 'over_request_rate_limit' || error.statusCode == '429') {
    return const AuthFailure(AuthFailureReason.rateLimited);
  }
  if (code == 'user_banned') {
    return const AuthFailure(AuthFailureReason.accountUnavailable);
  }
  final status = int.tryParse(error.statusCode ?? '');
  if (status != null && status >= 500) {
    return const AuthFailure(AuthFailureReason.serviceUnavailable);
  }
  if (error is AuthRetryableFetchException || code == 'request_timeout') {
    return const AuthFailure(AuthFailureReason.network);
  }
  return const AuthFailure(AuthFailureReason.unknown);
}

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
  }) : _emailRedirectTo = emailRedirectTo ?? (kIsWeb ? null : authRedirectUrl);

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
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final identity = _identity(response.session);
      if (identity == null) {
        throw const AuthFailure(AuthFailureReason.unknown);
      }
      return identity;
    } on AuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw classifyAuthFailure(error);
    }
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
