import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:breathefree_patient/profile/profile_repository.dart';
import 'package:breathefree_patient/profile/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'welcome sign-in uses the account boundary without a live backend',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BreatheFreeApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('welcome-sign-in')));
    await tester.tap(find.byKey(const ValueKey('welcome-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Account services are not configured for this build.'),
        findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('sign-in-submit')))
            .onPressed,
        isNull);
  });

  testWidgets('restored incomplete account resumes onboarding', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth(signedIn: true);
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _ProfileApi()),
    );
    addTearDown(account.dispose);

    await tester.pumpWidget(BreatheFreeApp(accountController: account));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('functional-welcome-screen')), findsNothing);
    expect(find.byKey(const ValueKey('functional-why-breathefree-screen')),
        findsOneWidget);
  });

  testWidgets('successful sign-in confirms success and starts onboarding',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth();
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _ProfileApi()),
    );
    addTearDown(account.dispose);

    await tester.pumpWidget(BreatheFreeApp(accountController: account));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('welcome-sign-in')));
    await tester.tap(find.byKey(const ValueKey('welcome-sign-in')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('sign-in-email')), 'person@example.test');
    await tester.enterText(
        find.byKey(const ValueKey('sign-in-password')), 'local-password');
    await tester.tap(find.byKey(const ValueKey('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Signed in successfully.'), findsOneWidget);
    expect(find.byKey(const ValueKey('functional-why-breathefree-screen')),
        findsOneWidget);
  });
}

class _SuccessfulAuth implements AuthGateway {
  _SuccessfulAuth({bool signedIn = false}) {
    if (signedIn) {
      _identity = const AuthIdentity(
        id: 'user-id',
        email: 'person@example.test',
        accessToken: 'fake-access-token',
      );
    }
  }

  AuthIdentity? _identity;

  @override
  AuthIdentity? get currentIdentity => _identity;

  @override
  Future<AuthIdentity> signIn(
      {required String email, required String password}) async {
    return _identity = AuthIdentity(
      id: 'user-id',
      email: email,
      accessToken: 'fake-access-token',
    );
  }

  @override
  Future<void> signOut() async => _identity = null;
}

class _ProfileApi implements ProfileApiClient {
  @override
  Future<UserProfile> getProfile(String accessToken) async => UserProfile(
        id: 'user-id',
        displayName: null,
        locale: 'en',
        timeZone: 'UTC',
        onboardingCompleted: false,
        avatarPath: null,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

  @override
  Future<UserProfile> updateProfile(
          String accessToken, Map<String, Object?> update) =>
      getProfile(accessToken);
}
