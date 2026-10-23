import 'package:flutter/foundation.dart';
import '../profile/profile_api_client.dart';
import '../profile/profile_repository.dart';
import '../profile/user_profile.dart';
import 'auth_gateway.dart';

class AccountController extends ChangeNotifier {
  AccountController(
      {required AuthGateway auth,
      required ProfileRepository profiles,
      this.enabled = true})
      : _auth = auth,
        _profiles = profiles;

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
  final bool enabled;
  UserProfile? profile;
  String? errorMessage;
  bool busy = false;

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
    await _auth.signOut();
    profile = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _loadProfile({bool notify = true}) async {
    profile = await _profiles.load();
    if (notify) notifyListeners();
  }
}
