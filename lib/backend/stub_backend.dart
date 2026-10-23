// A backend that is not built yet: every request answers
// `problem(501, 'backend_not_ready')` and nobody can sign in. It holds and
// sends nothing.
import '../auth/auth_gateway.dart';
import 'backend.dart';

/// The backend for a mode whose implementation has not landed.
class StubBackend implements Backend {
  StubBackend(this.mode);

  @override
  final BackendMode mode;

  @override
  final AuthBackend auth = const StubAuthBackend();

  @override
  final BackendTransport transport = const StubTransport();

  @override
  Future<void> wipeLocal() async {}
}

/// Answers every request with `problem(501, 'backend_not_ready')`.
class StubTransport implements BackendTransport {
  const StubTransport();

  @override
  Future<BackendResponse> send(BackendRequest request) async =>
      const BackendProblem(501, BackendCodes.notReady);
}

/// Nobody is signed in and nobody can sign in.
class StubAuthBackend implements AuthBackend {
  const StubAuthBackend();

  static Future<T> _unavailable<T>() =>
      Future<T>.error(const AuthFailure(AuthFailureReason.serviceUnavailable));

  @override
  AuthIdentity? get currentIdentity => null;

  @override
  Stream<void> get passwordRecoveryEvents => const Stream<void>.empty();

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  }) =>
      _unavailable();

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) =>
      _unavailable();

  @override
  Future<void> resendSignUpConfirmation({required String email}) =>
      _unavailable();

  @override
  Future<AuthIdentity> reauthenticate({required String password}) =>
      _unavailable();

  @override
  Future<void> requestPasswordReset({required String email}) => _unavailable();

  @override
  Future<void> updatePassword({required String newPassword}) => _unavailable();

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthOutcome> signInWithIdToken(
    IdTokenProvider provider,
    String idToken, {
    String? nonce,
    String? accessToken,
  }) async =>
      AuthOutcome.error;

  @override
  Future<AuthOutcome> linkIdentity(
    IdTokenProvider provider,
    String idToken, {
    String? nonce,
    String? accessToken,
  }) async =>
      AuthOutcome.error;
}
