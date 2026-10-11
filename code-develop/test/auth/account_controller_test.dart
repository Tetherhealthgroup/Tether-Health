import 'dart:async';

import 'package:breathefree_patient/account/account_data_api_client.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:breathefree_patient/profile/profile_repository.dart';
import 'package:breathefree_patient/profile/user_profile.dart';
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

  test('sign-up loads the profile when confirmation is disabled', () async {
    final auth = _FakeAuth();
    final api = _FakeProfileApi();
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: api),
    );

    expect(
      await controller.signUp(
        email: 'new-person@example.test',
        password: 'local-password',
      ),
      AccountSignUpOutcome.authenticated,
    );
    expect(controller.isSignedIn, isTrue);
    expect(controller.profile?.displayName, 'Test Person');
  });

  test('created account is not mislabeled when profile loading fails',
      () async {
    final auth = _FakeAuth();
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _FailingProfileApi()),
    );

    expect(
      await controller.signUp(
        email: 'new-person@example.test',
        password: 'local-password',
      ),
      AccountSignUpOutcome.accountCreatedSignInRequired,
    );
    expect(controller.isSignedIn, isFalse);
    expect(controller.profile, isNull);
    expect(controller.errorMessage, contains('account was created'));
  });

  test('sign-up reports when email confirmation is required', () async {
    final auth = _FakeAuth(requiresConfirmation: true);
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _FakeProfileApi()),
    );

    expect(
      await controller.signUp(
        email: 'new-person@example.test',
        password: 'local-password',
      ),
      AccountSignUpOutcome.emailConfirmationRequired,
    );
    expect(controller.isSignedIn, isFalse);
    expect(controller.profile, isNull);

    expect(
      await controller.resendSignUpConfirmation(
        email: 'new-person@example.test',
      ),
      isTrue,
    );
    expect(auth.resentEmail, 'new-person@example.test');
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

  test('password recovery deep link permits a password update', () async {
    final auth = _FakeAuth();
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _FakeProfileApi()),
    );
    addTearDown(controller.dispose);

    expect(
      await controller.requestPasswordReset(email: ' person@example.test '),
      isTrue,
    );
    expect(auth.recoveryEmail, 'person@example.test');
    auth.openRecoveryLink();
    await Future<void>.delayed(Duration.zero);
    expect(controller.passwordRecoveryPending, isTrue);
    expect(await controller.updateRecoveredPassword('new-password'), isTrue);
    expect(auth.updatedPassword, 'new-password');
  });

  test('export and deletion reauthenticate and use the new token', () async {
    final auth = _FakeAuth();
    final accountData = _FakeAccountDataApi();
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _FakeProfileApi()),
      accountData: accountData,
    );
    addTearDown(controller.dispose);
    await controller.signIn(email: 'person@example.test', password: 'password');

    final exported = await controller.exportData(password: 'password');
    expect(exported?.document['schemaVersion'], '1.0');
    expect(accountData.receivedToken, 'recent-access-token');

    final receipt = await controller.deleteAppData(password: 'password');
    expect(receipt?.requestId, 'receipt-id');
    expect(controller.isSignedIn, isFalse);
  });
}

class _FakeAuth
    implements AuthGateway, RecentAuthGateway, PasswordRecoveryGateway {
  _FakeAuth({this.requiresConfirmation = false});

  final bool requiresConfirmation;
  AuthIdentity? _identity;
  String? resentEmail;
  String? recoveryEmail;
  String? updatedPassword;
  final _recoveryEvents = StreamController<void>.broadcast();
  @override
  AuthIdentity? get currentIdentity => _identity;
  @override
  Future<AuthIdentity> signIn(
      {required String email, required String password}) async {
    return _identity = AuthIdentity(
        id: 'user-id', email: email, accessToken: 'fake-access-token');
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    if (requiresConfirmation) {
      return const AuthSignUpResult.emailConfirmationRequired();
    }
    final identity = _identity = AuthIdentity(
      id: 'user-id',
      email: email,
      accessToken: 'fake-access-token',
    );
    return AuthSignUpResult.authenticated(identity);
  }

  @override
  Future<void> resendSignUpConfirmation({required String email}) async {
    resentEmail = email;
  }

  @override
  Stream<void> get passwordRecoveryEvents => _recoveryEvents.stream;

  void openRecoveryLink() => _recoveryEvents.add(null);

  @override
  Future<void> requestPasswordReset({required String email}) async {
    recoveryEmail = email;
  }

  @override
  Future<AuthIdentity> reauthenticate({required String password}) async {
    return _identity = const AuthIdentity(
      id: 'user-id',
      email: 'person@example.test',
      accessToken: 'recent-access-token',
    );
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    updatedPassword = newPassword;
  }

  @override
  Future<void> signOut() async => _identity = null;
}

class _FakeAccountDataApi implements AccountDataApiClient {
  String? receivedToken;

  @override
  Future<AccountDataExport> exportData(String accessToken) async {
    receivedToken = accessToken;
    return const AccountDataExport(document: {'schemaVersion': '1.0'});
  }

  @override
  Future<AccountDeletionReceipt> deleteAppData(String accessToken) async {
    receivedToken = accessToken;
    return AccountDeletionReceipt(
      requestId: 'receipt-id',
      completedAt: DateTime.utc(2026, 9, 20),
      profileRowsDeleted: 1,
      quitPlanRowsDeleted: 1,
      avatarObjectsDeleted: 0,
      authIdentityDeleted: false,
    );
  }
}

class _FailingProfileApi implements ProfileApiClient {
  @override
  Future<UserProfile> getProfile(String accessToken) =>
      Future.error(StateError('profile unavailable'));

  @override
  Future<UserProfile> updateProfile(
          String accessToken, Map<String, Object?> update) =>
      Future.error(StateError('profile unavailable'));
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
