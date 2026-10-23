// The sandbox's sign-in: email accounts and simulated Apple/Google sign-in,
// kept in the sandbox document. Nothing leaves the phone.
//
// - Sign-up verifies the email at once (there is no email to open).
// - Sign-up with an email that already has an account answers "confirm your
//   email" and creates nothing, as Supabase does, so it reveals nothing.
// - A session lasts one hour and renews itself while the account exists;
//   [SandboxAuthBackend.expireSession] ends it as a server would.
// - A password reset opens the recovery step at once.
// - ID-token sign-in is simulated: the identity is
//   `<provider>-<n>@sandbox.invalid`, where n comes from the token.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../auth/auth_gateway.dart';
import '../backend.dart';
import 'sandbox_api.dart' show newAccountData;
import 'sandbox_store.dart';
import 'sha256.dart';

/// [AuthBackend] for sandbox mode.
class SandboxAuthBackend implements AuthBackend {
  SandboxAuthBackend(
    this._store, {
    DateTime Function()? clock,
    Random? random,
  })  : _clock = clock ?? DateTime.now,
        _random = random ?? Random.secure();

  final SandboxStore _store;
  final DateTime Function() _clock;
  final Random _random;
  final StreamController<void> _recovery = StreamController<void>.broadcast();

  /// How long a session lasts before it renews.
  static const Duration sessionLength = Duration(hours: 1);

  /// How recent a sign-in must be for export and deletion (the API's
  /// default of 600 seconds minus 30).
  static const Duration recentAuthWindow = Duration(seconds: 570);

  Json? _session;
  Json? _user;
  bool _restored = false;

  /// Reads the stored session. Until it completes, nobody is signed in.
  Future<void> restore() async {
    await _store.read((state) {
      _cache(state);
    });
    _restored = true;
  }

  /// Whether [restore] has completed.
  bool get restored => _restored;

  void _cache(Json state) {
    final session = state['session'] as Json?;
    final users = state['users']! as Json;
    _session = session == null ? null : Map<String, Object?>.of(session);
    _user = session == null ? null : users[session['uid']] as Json?;
    if (_user == null) _session = null;
  }

  String _token() => hex([for (var i = 0; i < 24; i++) _random.nextInt(256)]);

  static String _hash(String salt, String password) {
    var digest = utf8.encode('$salt:$password');
    for (var i = 0; i < 1000; i++) {
      digest = sha256(digest);
    }
    return hex(digest);
  }

  Json _newSession(String uid) {
    final now = _clock().toUtc();
    return {
      'uid': uid,
      'token': _token(),
      'expiresAt': now.add(sessionLength).toIso8601String(),
      'authAt': now.toIso8601String(),
    };
  }

  AuthIdentity _identity() {
    final session = _session!;
    return AuthIdentity(
      id: session['uid']! as String,
      email: _user?['email'] as String?,
      accessToken: session['token']! as String,
    );
  }

  static String _normal(String email) => email.trim().toLowerCase();

  static MapEntry<String, Object?>? _byEmail(Json state, String email) {
    for (final e in (state['users']! as Json).entries) {
      if ((e.value! as Json)['email'] == email) return e;
    }
    return null;
  }

  /// A sign-in write: not subject to the data cap; a storage failure is
  /// the generic sign-in failure, never a crash.
  Future<T> _write<T>(T Function(Json state) change) async {
    try {
      return await _store.transact(change, capped: false);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(AuthFailureReason.serviceUnavailable);
    }
  }

  Future<void> _signInAs(String uid) async {
    await _write((state) {
      state['session'] = _newSession(uid);
      _cache(state);
    });
  }

  // AuthGateway.

  @override
  AuthIdentity? get currentIdentity => _session == null ? null : _identity();

  @override
  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  }) async {
    final normal = _normal(email);
    final uid = await _store.read((state) {
      final found = _byEmail(state, normal);
      final user = found?.value as Json?;
      if (user == null || user['hash'] == null) return null;
      return _hash(user['salt']! as String, password) == user['hash']
          ? found!.key
          : null;
    });
    if (uid == null) {
      throw const AuthFailure(AuthFailureReason.invalidCredentials);
    }
    await _signInAs(uid);
    return _identity();
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    final normal = _normal(email);
    if (!normal.contains('@') || password.length < 6) {
      throw const AuthFailure(AuthFailureReason.unknown);
    }
    final created = await _write((state) {
      if (_byEmail(state, normal) != null) return false;
      final uid = SandboxStore.nextId(state, normal);
      final salt = _token();
      (state['users']! as Json)[uid] = {
        'email': normal,
        'salt': salt,
        'hash': _hash(salt, password),
        'providers': <Object?>['email'],
        'createdAt': _clock().toUtc().toIso8601String(),
      };
      (state['data']! as Json)[uid] =
          newAccountData(uid, _clock().toUtc().toIso8601String());
      state['session'] = _newSession(uid);
      _cache(state);
      return true;
    });
    if (!created) return const AuthSignUpResult.emailConfirmationRequired();
    return AuthSignUpResult.authenticated(_identity());
  }

  @override
  Future<void> resendSignUpConfirmation({required String email}) async {}

  @override
  Future<void> signOut() async {
    await _write((state) {
      state['session'] = null;
      _cache(state);
    });
  }

  // RecentAuthGateway.

  @override
  Future<AuthIdentity> reauthenticate({required String password}) async {
    final email = _user?['email'] as String?;
    if (_session == null || email == null) {
      throw const AuthFailure(AuthFailureReason.invalidCredentials);
    }
    return signIn(email: email, password: password);
  }

  // PasswordRecoveryGateway.

  @override
  Stream<void> get passwordRecoveryEvents => _recovery.stream;

  @override
  Future<void> requestPasswordReset({required String email}) async {
    final normal = _normal(email);
    // Unknown emails get the same answer and nothing happens. A known one
    // gets a one-time recovery token, as the emailed link would carry; it
    // signs nobody in until it is used ([completeRecovery]).
    await _write((state) {
      final found = _byEmail(state, normal);
      if (found == null) return;
      (found.value! as Json)['recovery'] = {
        'token': _token(),
        'expiresAt':
            _clock().toUtc().add(const Duration(hours: 1)).toIso8601String(),
      };
    });
  }

  /// The recovery token the sandbox would have emailed to [email], or null.
  /// Sandbox only: stands in for opening the email.
  Future<String?> recoveryTokenFor(String email) => _store.read((state) {
        final user = _byEmail(state, _normal(email))?.value as Json?;
        return (user?['recovery'] as Json?)?['token'] as String?;
      });

  /// Uses a recovery token: a recovery session that may set a new password
  /// but does not count as a recent sign-in. False for an unknown, used or
  /// expired token.
  Future<bool> completeRecovery(String token) async {
    final ok = await _write((state) {
      for (final e in (state['users']! as Json).entries) {
        final user = e.value! as Json;
        final recovery = user['recovery'] as Json?;
        if (recovery == null || recovery['token'] != token) continue;
        user.remove('recovery');
        final expires = DateTime.parse(recovery['expiresAt']! as String);
        if (!_clock().toUtc().isBefore(expires)) return false;
        state['session'] = _newSession(e.key)..['authAt'] = null;
        _cache(state);
        return true;
      }
      return false;
    });
    if (ok) _recovery.add(null);
    return ok;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    final session = _session;
    if (session == null) {
      throw const AuthFailure(AuthFailureReason.invalidCredentials);
    }
    if (newPassword.length < 6) {
      throw const AuthFailure(AuthFailureReason.unknown);
    }
    await _write((state) {
      final user = (state['users']! as Json)[session['uid']] as Json?;
      if (user == null) {
        throw const AuthFailure(AuthFailureReason.accountUnavailable);
      }
      final salt = _token();
      user
        ..['salt'] = salt
        ..['hash'] = _hash(salt, newPassword);
      _cache(state);
    });
  }

  // AuthBackend.

  /// The simulated email of an ID token: digits in the token are its
  /// number; any other token is numbered by its hash.
  static String simulatedEmail(IdTokenProvider provider, String idToken) {
    final digits = RegExp(r'\d+').firstMatch(idToken)?.group(0);
    final n = digits ?? (hex(sha256(utf8.encode(idToken))).substring(0, 6));
    return '${provider.name}-$n@sandbox.invalid';
  }

  @override
  Future<AuthOutcome> signInWithIdToken(
    IdTokenProvider provider,
    String idToken, {
    String? nonce,
    String? accessToken,
  }) async {
    if (idToken.isEmpty) return AuthOutcome.invalidCredentials;
    final email = simulatedEmail(provider, idToken);
    try {
      return await _write((state) {
        final found = _byEmail(state, email);
        if (found != null) {
          final user = found.value! as Json;
          final providers = (user['providers']! as List<Object?>);
          if (!providers.contains(provider.name)) return AuthOutcome.emailTaken;
          state['session'] = _newSession(found.key);
          _cache(state);
          return AuthOutcome.success;
        }
        final uid = SandboxStore.nextId(state, email);
        (state['users']! as Json)[uid] = {
          'email': email,
          'salt': null,
          'hash': null,
          'providers': <Object?>[provider.name],
          'createdAt': _clock().toUtc().toIso8601String(),
        };
        (state['data']! as Json)[uid] =
            newAccountData(uid, _clock().toUtc().toIso8601String());
        state['session'] = _newSession(uid);
        _cache(state);
        return AuthOutcome.successNew;
      });
    } on AuthFailure {
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
    final session = _session;
    if (session == null) return AuthOutcome.error;
    final email = simulatedEmail(provider, idToken);
    return _write((state) {
      final other = _byEmail(state, email);
      if (other != null && other.key != session['uid']) {
        return AuthOutcome.emailTaken;
      }
      final user = (state['users']! as Json)[session['uid']]! as Json;
      final providers = user['providers']! as List<Object?>;
      if (!providers.contains(provider.name)) providers.add(provider.name);
      _cache(state);
      return AuthOutcome.success;
    });
  }

  @override
  Future<String?> accessToken() async {
    final session = _session;
    if (session == null) return null;
    final expires = DateTime.parse(session['expiresAt']! as String);
    if (_clock().toUtc().isBefore(expires)) return session['token']! as String;
    // Renew, as a refresh token would, while the account exists. A storage
    // failure means no token ("sign in again"), never an exception.
    try {
      return await _renew(session);
    } on AuthFailure {
      return null;
    }
  }

  Future<String?> _renew(Json session) {
    return _write((state) {
      final stored = state['session'] as Json?;
      if (stored == null ||
          stored['token'] != session['token'] ||
          !(state['users']! as Json).containsKey(stored['uid'])) {
        state['session'] = null;
        _cache(state);
        return null;
      }
      stored
        ..['token'] = _token()
        ..['expiresAt'] = _clock().toUtc().add(sessionLength).toIso8601String();
      _cache(state);
      return stored['token']! as String;
    });
  }

  /// Ends the session as the server would (expired and not renewable).
  Future<void> expireSession() async {
    await _write((state) {
      state['session'] = null;
    });
    // The phone still holds the old session until it next asks: as with a
    // real server, the next request is refused.
  }

  /// The signed-in account for [token], or null; and whether the sign-in is
  /// recent. Used by the sandbox server for every request.
  static (String, bool)? accountFor(Json state, String? token, DateTime now) {
    final session = state['session'] as Json?;
    if (token == null || session == null || session['token'] != token) {
      return null;
    }
    if (!now
        .toUtc()
        .isBefore(DateTime.parse(session['expiresAt']! as String))) {
      return null;
    }
    final uid = session['uid']! as String;
    if (!(state['users']! as Json).containsKey(uid)) return null;
    final authAt = session['authAt'] as String?;
    // A recovery session is never a recent sign-in.
    final recent = authAt != null &&
        now.toUtc().difference(DateTime.parse(authAt)) <= recentAuthWindow;
    return (uid, recent);
  }

  /// After the account is deleted: forget the session in memory too.
  void forgetSession() {
    _session = null;
    _user = null;
  }
}
