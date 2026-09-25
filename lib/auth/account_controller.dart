import 'dart:async';

import 'package:flutter/foundation.dart';

import '../account/account_data_api_client.dart';
import '../profile/profile_api_client.dart';
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
      this.enabled = true})
      : _auth = auth,
        _profiles = profiles,
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
  final bool enabled;
  StreamSubscription<void>? _recoverySubscription;
  UserProfile? profile;
  String? errorMessage;
  bool busy = false;
  bool passwordRecoveryPending = false;

  bool get isSignedIn => _auth.currentIdentity != null;
  String? get email => _auth.currentIdentity?.email;

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
        errorMessage =
            'Your account was created, but your profile is temporarily '
            'unavailable. Sign in to continue.';
        return AccountSignUpOutcome.accountCreatedSignInRequired;
      }
    } catch (_) {
      profile = null;
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
      final receipt = await _accountData.deleteAppData(identity.accessToken);
      await _auth.signOut();
      profile = null;
      return receipt;
    } catch (_) {
      errorMessage = 'Your app data was not deleted. Please try again.';
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

  Future<bool> completeOnboarding() async {
    if (!isSignedIn) return true;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _profiles.update({'onboardingCompleted': true});
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
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _recoverySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile({bool notify = true}) async {
    profile = await _profiles.load();
    if (notify) notifyListeners();
  }
}
