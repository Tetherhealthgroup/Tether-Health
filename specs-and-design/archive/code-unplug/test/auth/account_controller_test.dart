import 'package:tether_health/auth/account_controller.dart';
import 'package:tether_health/auth/auth_gateway.dart';
import 'package:tether_health/profile/profile_api_client.dart';
import 'package:tether_health/profile/profile_repository.dart';
import 'package:tether_health/profile/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sign-in loads the caller profile through replaceable abstractions',
      () async {
    final auth = _FakeAuth();
    final api = _FakeProfileApi();
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: api),
    );

    expect(
        await controller.signIn(
            email: 'person@example.test', password: 'password'),
        isTrue);
    expect(controller.isSignedIn, isTrue);
    expect(controller.profile?.displayName, 'Test Person');
    expect(api.receivedToken, 'fake-access-token');

    await controller.signOut();
    expect(controller.isSignedIn, isFalse);
    expect(controller.profile, isNull);
  });

  test('completing onboarding persists the profile flag', () async {
    final auth = _FakeAuth();
    final api = _FakeProfileApi();
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: api),
    );
    await controller.signIn(email: 'person@example.test', password: 'password');

    expect(await controller.completeOnboarding(), isTrue);
    expect(api.receivedUpdate, {'onboardingCompleted': true});
    expect(controller.profile?.onboardingCompleted, isTrue);
  });
}

class _FakeAuth implements AuthGateway {
  AuthIdentity? _identity;
  @override
  AuthIdentity? get currentIdentity => _identity;
  @override
  Future<AuthIdentity> signIn(
      {required String email, required String password}) async {
    return _identity = AuthIdentity(
        id: 'user-id', email: email, accessToken: 'fake-access-token');
  }

  @override
  Future<void> signOut() async => _identity = null;

  // The gateway hands out a token that is still valid; these fakes have no
  // expiry to model, so the current one is always the fresh one.
  @override
  Future<String?> freshAccessToken() async => _identity?.accessToken;
}

class _FakeProfileApi implements ProfileApiClient {
  String? receivedToken;
  Map<String, Object?>? receivedUpdate;

  @override
  Future<UserProfile> getProfile(String accessToken) async {
    receivedToken = accessToken;
    return _profile(onboardingCompleted: false);
  }

  @override
  Future<UserProfile> updateProfile(
      String accessToken, Map<String, Object?> update) async {
    receivedToken = accessToken;
    receivedUpdate = update;
    return _profile(
      onboardingCompleted: update['onboardingCompleted'] == true,
    );
  }

  UserProfile _profile({required bool onboardingCompleted}) => UserProfile(
        id: 'user-id',
        displayName: 'Test Person',
        locale: 'en',
        timeZone: 'UTC',
        onboardingCompleted: onboardingCompleted,
        avatarPath: null,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
}
