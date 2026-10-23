// Supabase Auth for http mode: the existing gateway for email accounts, plus
// native ID-token sign-in, identity linking and a fresh access token.
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_gateway.dart';
import '../backend.dart';

/// [AuthBackend] over a Supabase client.
class SupabaseAuthBackend implements AuthBackend {
  /// [client] is read when first needed, so building the backend never
  /// touches Supabase before it is initialised.
  SupabaseAuthBackend(SupabaseClient Function() client) : _clientOf = client;

  final SupabaseClient Function() _clientOf;
  SupabaseClient? _client;
  SupabaseAuthGateway? _gateway;

  SupabaseClient get _supabase => _client ??= _clientOf();
  SupabaseAuthGateway get _email => _gateway ??= SupabaseAuthGateway(_supabase);

  @override
  AuthIdentity? get currentIdentity => _email.currentIdentity;

  @override
  Stream<void> get passwordRecoveryEvents => _email.passwordRecoveryEvents;

  @override
  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  }) =>
      _email.signIn(email: email, password: password);

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) =>
      _email.signUp(email: email, password: password);

  @override
  Future<void> resendSignUpConfirmation({required String email}) =>
      _email.resendSignUpConfirmation(email: email);

  @override
  Future<AuthIdentity> reauthenticate({required String password}) =>
      _email.reauthenticate(password: password);

  @override
  Future<void> requestPasswordReset({required String email}) =>
      _email.requestPasswordReset(email: email);

  @override
  Future<void> updatePassword({required String newPassword}) =>
      _email.updatePassword(newPassword: newPassword);

  @override
  Future<void> signOut() => _email.signOut();

  static OAuthProvider _provider(IdTokenProvider provider) =>
      switch (provider) {
        IdTokenProvider.apple => OAuthProvider.apple,
        IdTokenProvider.google => OAuthProvider.google,
      };

  /// The outcome for a Supabase Auth error. Never reads the message.
  static AuthOutcome outcomeOf(AuthException error) {
    final code = error.code;
    if (code == 'email_exists' ||
        code == 'user_already_exists' ||
        code == 'identity_already_exists') {
      return AuthOutcome.emailTaken;
    }
    if (code == 'email_not_confirmed') return AuthOutcome.needsVerification;
    if (code == 'over_request_rate_limit' || error.statusCode == '429') {
      return AuthOutcome.rateLimited;
    }
    if (code == 'invalid_credentials' ||
        code == 'bad_jwt' ||
        code == 'invalid_grant') {
      return AuthOutcome.invalidCredentials;
    }
    return AuthOutcome.error;
  }

  /// A new account is one created within the last minute of its first
  /// sign-in. Supabase gives no flag for this.
  static bool _isNew(User? user) {
    if (user == null) return false;
    final created = DateTime.tryParse(user.createdAt);
    final signedIn = DateTime.tryParse(user.lastSignInAt ?? '');
    if (created == null || signedIn == null) return false;
    return signedIn.difference(created).abs() < const Duration(minutes: 1);
  }

  @override
  Future<AuthOutcome> signInWithIdToken(
    IdTokenProvider provider,
    String idToken, {
    String? nonce,
    String? accessToken,
  }) async {
    try {
      final response = await _supabase.auth.signInWithIdToken(
        provider: _provider(provider),
        idToken: idToken,
        nonce: nonce,
        accessToken: accessToken,
      );
      if (response.session == null) return AuthOutcome.error;
      return _isNew(response.user)
          ? AuthOutcome.successNew
          : AuthOutcome.success;
    } on AuthException catch (error) {
      return outcomeOf(error);
    } catch (_) {
      return AuthOutcome.error;
    }
  }

  @override
  Future<AuthOutcome> linkIdentity(
    IdTokenProvider provider,
    String idToken, {
    String? nonce,
    String? accessToken,
  }) async {
    try {
      final response = await _supabase.auth.linkIdentityWithIdToken(
        provider: _provider(provider),
        idToken: idToken,
        nonce: nonce,
        accessToken: accessToken,
      );
      return response.session == null ? AuthOutcome.error : AuthOutcome.success;
    } on AuthException catch (error) {
      return outcomeOf(error);
    } catch (_) {
      return AuthOutcome.error;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;
      if (!session.isExpired) return session.accessToken;
      // Refresh first: an expired token gives a 401 that reads like a
      // permissions problem. A refresh that fails means "sign in again".
      final refreshed = await _supabase.auth.refreshSession();
      return refreshed.session?.accessToken;
    } catch (_) {
      return null;
    }
  }
}
