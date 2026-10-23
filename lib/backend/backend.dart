// The app-side backend: one interface that the tether_ui handlers, sign-in
// and the data adapter call, whatever serves it.
//
// Two implementations exist, chosen by configuration only (TETHER_BACKEND in
// lib/config/app_config.dart):
// - http: the API, the sync service and Supabase Auth over HTTPS;
// - sandbox: an in-process server on the phone with synthetic data, with the
//   same paths, validation and problem codes as the real services.
// A build never mixes the two, so one member's data never splits between a
// server and the phone.
import 'package:flutter/foundation.dart';

import '../auth/auth_gateway.dart';
import '../config/app_config.dart' show BackendMode;

export '../config/app_config.dart' show BackendMode;

/// The service a request goes to.
enum BackendService {
  /// The app's API (`api/`), under `API_BASE_URL`.
  api,

  /// The sync service (`sync/thsync`), under `SYNC_BASE_URL`.
  sync,
}

/// The HTTP methods the services use.
enum BackendMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  const BackendMethod(this.wire);

  /// The method as sent.
  final String wire;
}

/// One request to a service. The bearer token is not part of it: the
/// transport takes it from [AuthBackend.accessToken] at send time.
@immutable
class BackendRequest {
  BackendRequest({
    required this.service,
    required this.method,
    required this.path,
    Map<String, String> query = const <String, String>{},
    this.body,
    this.idempotencyKey,
  }) : query = Map<String, String>.unmodifiable(query) {
    if (!path.startsWith('/')) {
      throw ArgumentError.value(path, 'path', 'must start with "/"');
    }
    if (path.contains('?') || path.contains('#')) {
      throw ArgumentError.value(path, 'path', 'must not hold a query');
    }
  }

  final BackendService service;
  final BackendMethod method;

  /// The path below the service's base URL, starting with "/", with every
  /// parameter already filled in (for example `/v1/enrolments/<id>`).
  final String path;

  /// Query parameters.
  final Map<String, String> query;

  /// The JSON body (maps, lists, strings, numbers, booleans, null), or null
  /// for none.
  final Object? body;

  /// Sent as `Idempotency-Key` on event POSTs, so a retry never creates a
  /// second record.
  final String? idempotencyKey;

  /// Never prints the body or the key: both may hold health content.
  @override
  String toString() => 'BackendRequest($service ${method.wire} <path>)';
}

/// The answer to a [BackendRequest].
///
/// - [BackendOk]: a 2xx status with its JSON body (null for none).
/// - [BackendProblem]: a 4xx or 5xx status with the service's problem code.
///   A 5xx body is never surfaced; its code is the generic `server_error`.
/// - [BackendUnreachable]: no answer (offline, timeout, TLS failure).
sealed class BackendResponse {
  const BackendResponse();
}

final class BackendOk extends BackendResponse {
  const BackendOk(this.status, [this.json]);

  final int status;
  final Object? json;

  /// Never prints the body.
  @override
  String toString() => 'BackendOk($status)';
}

final class BackendProblem extends BackendResponse {
  const BackendProblem(this.status, this.code, {this.positions = const []});

  final int status;

  /// A stable machine code (for example `focus_cap_reached`), never
  /// content.
  final String code;

  /// Sync push refusals only: the positions (in the pushed `areas` list) of
  /// the refused bundles. Never programme names.
  final List<int> positions;

  @override
  bool operator ==(Object other) =>
      other is BackendProblem && other.status == status && other.code == code;

  @override
  int get hashCode => Object.hash(BackendProblem, status, code);

  @override
  String toString() => 'BackendProblem($status, $code)';
}

final class BackendUnreachable extends BackendResponse {
  const BackendUnreachable();

  @override
  bool operator ==(Object other) => other is BackendUnreachable;

  @override
  int get hashCode => (BackendUnreachable).hashCode;

  @override
  String toString() => 'BackendUnreachable()';
}

/// Problem codes the backends themselves give.
abstract final class BackendCodes {
  /// The backend is not built yet for this mode.
  static const String notReady = 'backend_not_ready';

  /// A 5xx answer: the body is never surfaced.
  static const String serverError = 'server_error';

  /// The request needs a signed-in member and there is none.
  static const String unauthenticated = 'unauthenticated';

  /// The sandbox store is over its size cap; nothing was saved.
  static const String sandboxFull = 'sandbox_full';
}

/// Sends requests to the services.
abstract interface class BackendTransport {
  /// Sends [request]. Never throws: every failure is a [BackendResponse].
  Future<BackendResponse> send(BackendRequest request);
}

/// A native sign-in provider whose ID token Supabase Auth accepts.
enum IdTokenProvider { apple, google }

/// The result of a sign-in, sign-up or identity link.
enum AuthOutcome {
  /// Signed in to an existing account.
  success,

  /// Signed in to an account this call created.
  successNew,

  /// The email and password, or the token, do not match an account.
  invalidCredentials,

  /// The email already belongs to another account.
  emailTaken,

  /// The account exists but the email is not verified yet.
  needsVerification,

  /// The member cancelled.
  cancelled,

  /// Too many attempts; try later.
  rateLimited,

  /// Anything else, including offline. Shown as the generic error.
  error,
}

/// Sign-in for both modes. It is the existing gateway set, so
/// [AccountController] and the session lifecycle work unchanged, plus the
/// native-provider calls.
abstract interface class AuthBackend
    implements AuthGateway, RecentAuthGateway, PasswordRecoveryGateway {
  /// Signs in with a provider's ID token (Apple or Google), creating the
  /// account when it does not exist. [nonce] is the raw nonce whose hash the
  /// token carries.
  Future<AuthOutcome> signInWithIdToken(
    IdTokenProvider provider,
    String idToken, {
    String? nonce,
    String? accessToken,
  });

  /// Links a provider identity to the signed-in account.
  Future<AuthOutcome> linkIdentity(
    IdTokenProvider provider,
    String idToken, {
    String? nonce,
    String? accessToken,
  });

  /// The current access token, refreshed when it is about to expire; null
  /// when nobody is signed in or the session cannot be refreshed.
  Future<String?> accessToken();
}

/// Everything the app needs from a backend.
abstract interface class Backend {
  /// Which backend this is. Sandbox mode shows the environment badge.
  BackendMode get mode;

  AuthBackend get auth;

  BackendTransport get transport;

  /// Removes every local trace of the backend (the sandbox store, cached
  /// tokens). Used after account deletion and by tests.
  Future<void> wipeLocal();
}
