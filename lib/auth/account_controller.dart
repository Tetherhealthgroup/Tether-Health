import 'dart:async';
import 'package:flutter/foundation.dart';

import '../account/account_data_api_client.dart';
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

class AccountController extends ChangeNotifier {
  AccountController(
      {required AuthGateway auth,
      required ProfileRepository profiles,
      AccountDataApiClient accountData = const DisabledAccountDataApiClient(),
      AvatarStorage avatarStorage = const DisabledAvatarStorage(),
      this.enabled = true})
      : _auth = auth,
        _profiles = profiles,
        _avatarStorage = avatarStorage,
        _accountData = accountData {
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
  final AvatarStorage _avatarStorage;
  final bool enabled;
  StreamSubscription<void>? _recoverySubscription;
  Timer? _avatarRefreshTimer;
  UserProfile? profile;
  String? errorMessage;
  bool busy = false;
  bool passwordRecoveryPending = false;

  bool get isSignedIn => _auth.currentIdentity != null;
  String? get email => _auth.currentIdentity?.email;
  String? get accountId => _auth.currentIdentity?.id;
  String? get accessToken => _auth.currentIdentity?.accessToken;

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
    notifyListeners();
    try {
      await _auth.signIn(email: email.trim(), password: password);
      await _loadProfile(notify: false);
      return true;
    } catch (_) {
      try {
        await _auth.signOut();
      } catch (_) {
        // Preserve the original sign-in/profile failure for the user.
      }
      profile = null;
      _avatarRefreshTimer?.cancel();
      errorMessage = 'Sign-in failed. Check your details and connection.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

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

  Future<AccountDeletionReceipt?> deleteAppData({
    required String password,
  }) async {
    final identity = await _reauthenticate(password);
    if (identity == null) return null;
    busy = true;
    notifyListeners();
    try {
      return await _accountData.deleteAppData(identity.accessToken);
    } catch (_) {
      errorMessage = 'Account deletion could not complete. Please try again.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
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
    try {
      await _auth.signOut();
    } catch (_) {
      // The local session is cleared regardless so the user is never left
      // appearing signed in after asking to sign out. A failed remote
      // sign-out only means the server token may linger until it expires.
    }
    profile = null;
    _avatarRefreshTimer?.cancel();
    errorMessage = null;
    notifyListeners();
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
