import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../account/account_data_api_client.dart';
import '../account/account_deletion_receipt_store.dart';
import '../profile/profile_api_client.dart';
import '../profile/avatar_storage.dart';
import '../profile/profile_repository.dart';
import '../profile/user_profile.dart';
import 'auth_gateway.dart';

enum AccountSignUpOutcome {
  authenticated,
  emailConfirmationRequired,
  accountCreatedSignInRequired,
}

class AccountDeletionCompletion {
  const AccountDeletionCompletion({
    required this.accountId,
    required this.receipt,
    required this.localCleanupComplete,
  });

  final String accountId;
  final AccountDeletionReceipt? receipt;
  final bool localCleanupComplete;
}

class AccountController extends ChangeNotifier {
  AccountController(
      {required AuthGateway auth,
      required ProfileRepository profiles,
      AccountDataApiClient accountData = const DisabledAccountDataApiClient(),
      AccountDeletionReceiptStore deletionReceipts =
          const DisabledAccountDeletionReceiptStore(),
      AvatarStorage avatarStorage = const DisabledAvatarStorage(),
      this.deletionStorageTimeout = const Duration(seconds: 2),
      this.deletionCleanupTimeout = const Duration(seconds: 5),
      this.signInProfileRetryDelays = const [
        Duration.zero,
        Duration(milliseconds: 750),
        Duration(seconds: 2),
      ],
      this.enabled = true})
      : _auth = auth,
        _profiles = profiles,
        _avatarStorage = avatarStorage,
        _accountData = accountData,
        _deletionReceipts = deletionReceipts {
    assert(signInProfileRetryDelays.isNotEmpty);
    final recovery = auth is PasswordRecoveryGateway
        ? auth as PasswordRecoveryGateway
        : null;
    _recoverySubscription = recovery?.passwordRecoveryEvents.listen((_) {
      passwordRecoveryPending = true;
      notifyListeners();
    });
  }

  factory AccountController.disabled() {
    const auth = DisabledAuthGateway();
    return AccountController(
      auth: auth,
      profiles: const ProfileRepository(
        auth: auth,
        api: DisabledProfileApiClient(),
      ),
      enabled: false,
    );
  }

  final AuthGateway _auth;
  final ProfileRepository _profiles;
  final AccountDataApiClient _accountData;
  final AccountDeletionReceiptStore _deletionReceipts;
  final AvatarStorage _avatarStorage;
  final bool enabled;
  final Duration deletionStorageTimeout;
  final Duration deletionCleanupTimeout;
  final List<Duration> signInProfileRetryDelays;
  StreamSubscription<void>? _recoverySubscription;
  Timer? _avatarRefreshTimer;
  UserProfile? profile;
  String? errorMessage;
  bool busy = false;
  bool passwordRecoveryPending = false;
  bool _sessionInvalidated = false;
  PendingAccountDeletion? pendingAccountDeletion;

  /// Why the last [signIn] failed, when the gateway said; null after a
  /// success or a failure with no reason.
  AuthFailureReason? lastSignInFailure;

  /// The account listeners were last told about ([syncSession]).
  late String? _announcedAccountId = accountId;

  /// [pendingAccountDeletion] was set by [markAccountDeleted] (in memory
  /// only), not restored from the receipt store.
  bool _deletionNoticeOnly = false;

  bool get isSignedIn => !_sessionInvalidated && _auth.currentIdentity != null;
  String? get email => isSignedIn ? _auth.currentIdentity?.email : null;
  String? get accountId => isSignedIn ? _auth.currentIdentity?.id : null;
  String? get accessToken =>
      isSignedIn ? _auth.currentIdentity?.accessToken : null;

  static const int maxAvatarBytes = 5 * 1024 * 1024;

  Future<bool> refreshProfile() => initialize();

  Future<bool> updateDisplayName(String value) async {
    final name = value.trim();
    if (name.isEmpty || name.length > 80) {
      errorMessage = 'Display name must be between 1 and 80 characters.';
      notifyListeners();
      return false;
    }
    return _updateProfile({'displayName': name},
        failure: 'Your display name could not be saved.');
  }

  Future<bool> uploadAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final identity = _auth.currentIdentity;
    final extension = switch (contentType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => null,
    };
    if (identity == null ||
        extension == null ||
        bytes.isEmpty ||
        bytes.length > maxAvatarBytes ||
        !_matchesImageSignature(bytes, contentType)) {
      errorMessage = 'Choose a JPEG, PNG, or WebP image no larger than 5 MB.';
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    final previousPath = profile?.avatarPath;
    // Keep one stable object per account. Replacements overwrite the same
    // object, so a failed cleanup can never create an unreferenced image.
    final path = previousPath ?? '${identity.id}/avatar';
    try {
      if (previousPath == null) {
        profile = await _profiles.update({'avatarPath': path});
      }
      await _avatarStorage.upload(
        path: path,
        bytes: bytes,
        contentType: contentType,
      );
      try {
        await _loadProfile(notify: false);
      } catch (_) {
        errorMessage =
            'Your photo was uploaded, but its preview is temporarily unavailable.';
      }
      return true;
    } catch (_) {
      if (previousPath == null && profile?.avatarPath == path) {
        try {
          profile = await _profiles.update({'avatarPath': null});
        } catch (_) {
          // A missing object is rendered as initials until the profile retries.
        }
      }
      errorMessage = 'Your photo could not be uploaded. Check your connection.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> removeAvatar() async {
    final path = profile?.avatarPath;
    if (path == null) return true;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _avatarStorage.remove(path);
      profile = await _profiles.update({'avatarPath': null});
      _scheduleAvatarRefresh();
      return true;
    } catch (_) {
      errorMessage = 'Your photo could not be removed. Check your connection.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> _updateProfile(Map<String, Object?> values,
      {required String failure}) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _profiles.update(values);
      _scheduleAvatarRefresh();
      return true;
    } catch (_) {
      errorMessage = failure;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  static bool _matchesImageSignature(Uint8List bytes, String type) {
    if (type == 'image/jpeg') {
      return bytes.length >= 3 && bytes[0] == 0xff && bytes[1] == 0xd8;
    }
    if (type == 'image/png') {
      return bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47;
    }
    return bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
  }

  Future<bool> initialize() async {
    if (!isSignedIn) return false;
    try {
      await _loadProfile();
      errorMessage = null;
      return true;
    } catch (_) {
      errorMessage = 'Your profile is temporarily unavailable.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    busy = true;
    errorMessage = null;
    lastSignInFailure = null;
    notifyListeners();
    var authenticated = false;
    try {
      await _auth.signIn(email: email.trim(), password: password);
      authenticated = true;
      _sessionInvalidated = false;
      await _loadProfileForSignIn();
      return true;
    } on AuthFailure catch (error) {
      await _discardFailedSignInSession();
      lastSignInFailure = error.reason;
      errorMessage = _signInFailureMessage(error.reason);
      return false;
    } catch (_) {
      await _discardFailedSignInSession();
      errorMessage = authenticated
          ? 'Your email and password were accepted, but your profile is '
              'temporarily unavailable. Please try again.'
          : 'Unable to reach the sign-in service. Check your connection and '
              'try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _discardFailedSignInSession() async {
    _sessionInvalidated = true;
    profile = null;
    _avatarRefreshTimer?.cancel();
    try {
      await _auth.signOut();
    } catch (_) {
      // Local invalidation remains authoritative if remote sign-out fails.
    }
  }

  String _signInFailureMessage(AuthFailureReason reason) => switch (reason) {
        AuthFailureReason.invalidCredentials =>
          'Email or password is incorrect.',
        AuthFailureReason.emailNotConfirmed =>
          'Confirm your email before signing in, then try again.',
        AuthFailureReason.rateLimited =>
          'Too many sign-in attempts. Wait a few minutes and try again.',
        AuthFailureReason.accountUnavailable =>
          'This account is temporarily unavailable. Contact support if this '
              'continues.',
        AuthFailureReason.network =>
          'Unable to reach the sign-in service. Check your connection and try '
              'again.',
        AuthFailureReason.serviceUnavailable =>
          'The sign-in service is temporarily unavailable. Try again shortly.',
        AuthFailureReason.unknown =>
          'Sign-in could not be completed. Please try again.',
      };

  Future<AccountSignUpOutcome?> signUp({
    required String email,
    required String password,
  }) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _auth.signUp(
        email: email.trim(),
        password: password,
      );
      _sessionInvalidated = false;
      if (result.status == AuthSignUpStatus.emailConfirmationRequired) {
        profile = null;
        _avatarRefreshTimer?.cancel();
        return AccountSignUpOutcome.emailConfirmationRequired;
      }

      try {
        await _loadProfile(notify: false);
        return AccountSignUpOutcome.authenticated;
      } catch (_) {
        try {
          await _auth.signOut();
        } catch (_) {
          // Preserve the profile restoration failure for the user.
        }
        profile = null;
        _avatarRefreshTimer?.cancel();
        errorMessage =
            'Your account was created, but your profile is temporarily '
            'unavailable. Sign in to continue.';
        return AccountSignUpOutcome.accountCreatedSignInRequired;
      }
    } catch (_) {
      profile = null;
      _avatarRefreshTimer?.cancel();
      errorMessage =
          'Account creation failed. Check your details and connection.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> resendSignUpConfirmation({required String email}) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _auth.resendSignUpConfirmation(email: email.trim());
      return true;
    } catch (_) {
      errorMessage = 'Confirmation email could not be sent. Please try again.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    final recovery = _auth is PasswordRecoveryGateway
        ? _auth as PasswordRecoveryGateway
        : null;
    if (recovery == null) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await recovery.requestPasswordReset(email: email.trim());
      return true;
    } catch (_) {
      errorMessage =
          'If that address can receive recovery email, try again shortly.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> updateRecoveredPassword(String newPassword) async {
    final recovery = _auth is PasswordRecoveryGateway
        ? _auth as PasswordRecoveryGateway
        : null;
    if (recovery == null || !passwordRecoveryPending) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await recovery.updatePassword(newPassword: newPassword);
      passwordRecoveryPending = false;
      return true;
    } catch (_) {
      errorMessage = 'Your password could not be updated. Request a new link.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<AccountDataExport?> exportData({required String password}) async {
    final identity = await _reauthenticate(password);
    if (identity == null) return null;
    busy = true;
    notifyListeners();
    try {
      return await _accountData.exportData(identity.accessToken);
    } catch (_) {
      errorMessage = 'Your data copy could not be prepared. Please try again.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<AccountDeletionCompletion?> deleteAppData({
    required String password,
    Future<void> Function(String accountId)? localCleanup,
  }) async {
    final identity = await _reauthenticate(password);
    if (identity == null) return null;
    busy = true;
    notifyListeners();
    try {
      try {
        await _deletionReceipts
            .saveIntent(identity.id)
            .timeout(deletionStorageTimeout);
      } catch (_) {
        errorMessage =
            'Account deletion could not start because recovery state could not be saved.';
        return null;
      }
      pendingAccountDeletion = PendingAccountDeletion(accountId: identity.id);

      AccountDeletionReceipt receipt;
      try {
        receipt = await _accountData.deleteAppData(identity.accessToken);
      } on AccountDataResponseException {
        // A 2xx proves the endpoint ran, but two unusable bodies leave no
        // receipt to retain. Complete local deletion from the durable intent.
        return await _completeLocalDeletion(
          identity: identity,
          localCleanup: localCleanup,
        );
      }
      if (!receipt.authIdentityDeleted) {
        throw StateError('The remote identity was not deleted.');
      }
      return await _completeLocalDeletion(
        identity: identity,
        receipt: receipt,
        localCleanup: localCleanup,
      );
    } catch (_) {
      errorMessage = 'Account deletion could not complete. Please try again.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<AccountDeletionCompletion> _completeLocalDeletion({
    required AuthIdentity identity,
    AccountDeletionReceipt? receipt,
    Future<void> Function(String accountId)? localCleanup,
  }) async {
    final deletion = PendingAccountDeletion(
      accountId: identity.id,
      receipt: receipt,
    );
    pendingAccountDeletion = deletion;

    // Change observable auth state synchronously, then start every fallible
    // post-success operation independently. No storage future can delay
    // session invalidation or prevent account-scoped cleanup from starting.
    final signOut = _invalidateLocalSessionImmediately();
    final cleanup = localCleanup == null
        ? Future<void>.value()
        : Future<void>.sync(() => localCleanup(identity.id));
    final persistReceipt = receipt == null
        ? Future<void>.value()
        : Future<void>.sync(() => _deletionReceipts.saveReceipt(deletion));

    var localCleanupComplete = true;
    await Future.wait<void>([
      signOut.timeout(deletionCleanupTimeout).catchError((_) {}),
      cleanup.timeout(deletionCleanupTimeout).catchError((_) {
        localCleanupComplete = false;
      }),
      persistReceipt.timeout(deletionStorageTimeout).catchError((_) {
        // The durable intent remains as a restart-safe fallback, while the
        // exact receipt remains in memory for this process until Done.
      }),
    ]);
    return AccountDeletionCompletion(
      accountId: identity.id,
      receipt: receipt,
      localCleanupComplete: localCleanupComplete,
    );
  }

  Future<PendingAccountDeletion?> restorePendingAccountDeletion() async {
    if (pendingAccountDeletion != null) return pendingAccountDeletion;
    try {
      pendingAccountDeletion =
          await _deletionReceipts.load().timeout(deletionStorageTimeout);
    } catch (_) {
      return null;
    }
    if (pendingAccountDeletion != null) {
      await _invalidateLocalSessionImmediately()
          .timeout(deletionCleanupTimeout)
          .catchError((_) {});
    }
    return pendingAccountDeletion;
  }

  Future<void> acknowledgeAccountDeletion() async {
    await _deletionReceipts.clear().timeout(deletionStorageTimeout);
    pendingAccountDeletion = null;
    notifyListeners();
  }

  Future<AuthIdentity?> _reauthenticate(String password) async {
    final recentAuth =
        _auth is RecentAuthGateway ? _auth as RecentAuthGateway : null;
    if (recentAuth == null || !isSignedIn) return null;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await recentAuth.reauthenticate(password: password);
    } catch (_) {
      errorMessage = 'Password verification failed.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Takes up a session started on the gateway without this controller (a
  /// native sign-in, signing in again, an opened email link): the member
  /// counts as signed in again, a deletion notice from [markAccountDeleted]
  /// is dropped, and listeners are told. Does nothing when the gateway has
  /// no session.
  void adoptSession() {
    if (_auth.currentIdentity == null) return;
    _sessionInvalidated = false;
    if (_deletionNoticeOnly) {
      pendingAccountDeletion = null;
      _deletionNoticeOnly = false;
    }
    notifyListeners();
  }

  /// Tells listeners when the signed-in account changed on the gateway
  /// without this controller (for example a save handler that ended the
  /// session).
  void syncSession() {
    if (accountId != _announcedAccountId) notifyListeners();
  }

  /// The account [accountId] was deleted by a save handler, which has ended
  /// its session on the gateway. Recorded in memory so the session end
  /// counts as a deletion and the entry screen shows the receipt; listeners
  /// are told.
  void markAccountDeleted(String accountId) {
    if (pendingAccountDeletion == null) {
      pendingAccountDeletion = PendingAccountDeletion(accountId: accountId);
      _deletionNoticeOnly = true;
    }
    _sessionInvalidated = true;
    profile = null;
    _avatarRefreshTimer?.cancel();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    _announcedAccountId = accountId;
    super.notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  void setProfileError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  Future<bool> completeOnboarding() async {
    if (!isSignedIn) return true;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _profiles.update({'onboardingCompleted': true});
      _scheduleAvatarRefresh();
      return true;
    } catch (_) {
      errorMessage = 'Your onboarding progress could not be saved.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _invalidateLocalSessionImmediately();
  }

  Future<void> _invalidateLocalSessionImmediately() async {
    _sessionInvalidated = true;
    profile = null;
    _avatarRefreshTimer?.cancel();
    errorMessage = null;
    notifyListeners();
    try {
      await _auth.signOut();
    } catch (_) {
      // The local session is cleared regardless so the user is never left
      // appearing signed in after asking to sign out. A failed remote
      // sign-out only means the server token may linger until it expires.
    }
  }

  @override
  void dispose() {
    _recoverySubscription?.cancel();
    _avatarRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile({bool notify = true}) async {
    profile = await _profiles.load();
    _scheduleAvatarRefresh();
    if (notify) notifyListeners();
  }

  Future<void> _loadProfileForSignIn() async {
    for (var index = 0; index < signInProfileRetryDelays.length; index++) {
      final delay = signInProfileRetryDelays[index];
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      try {
        await _loadProfile(notify: false);
        return;
      } catch (error, stackTrace) {
        final finalAttempt = index == signInProfileRetryDelays.length - 1;
        if (finalAttempt || !_isRetryableProfileLoad(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }
      }
    }
  }

  bool _isRetryableProfileLoad(Object error) {
    if (error is TimeoutException || error is http.ClientException) return true;
    if (error is! ProfileApiException) return false;
    return error.statusCode == 404 ||
        error.statusCode == 408 ||
        error.statusCode == 425 ||
        error.statusCode == 429 ||
        error.statusCode >= 500;
  }

  void _scheduleAvatarRefresh() {
    _avatarRefreshTimer?.cancel();
    final expiresAt = profile?.avatarUrlExpiresAt;
    if (expiresAt == null || profile?.avatarPath == null) return;
    final delay = expiresAt.difference(DateTime.now().toUtc()) -
        const Duration(seconds: 30);
    _avatarRefreshTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () async {
        if (!isSignedIn) return;
        try {
          await _loadProfile();
          errorMessage = null;
        } catch (_) {
          errorMessage =
              'Your profile photo is temporarily unavailable while offline.';
          notifyListeners();
        }
      },
    );
  }
}
