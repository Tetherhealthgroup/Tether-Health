import 'dart:async';

import 'package:tether_health/auth/account_controller.dart';
import 'package:tether_health/auth/auth_gateway.dart';
import 'package:tether_health/main.dart';
import 'package:tether_health/profile/profile_api_client.dart';
import 'package:tether_health/profile/profile_repository.dart';
import 'package:tether_health/profile/user_profile.dart';
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

    await tester.pumpWidget(const TetherHealthApp());
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

    await tester.pumpWidget(TetherHealthApp(accountController: account));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('functional-welcome-screen')), findsNothing);
    expect(find.byKey(const ValueKey('functional-why-breathefree-screen')),
        findsOneWidget);
  });

  testWidgets('restored account shows connection state while profile loads',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth(signedIn: true);
    final api = _DeferredProfileApi();
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: api),
    );
    addTearDown(account.dispose);

    await tester.pumpWidget(TetherHealthApp(accountController: account));
    await tester.pump();

    expect(find.byKey(const ValueKey('account-connection-screen')),
        findsOneWidget);
    expect(find.text('Connecting to BreatheFree'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('functional-welcome-screen')), findsNothing);

    api.complete();
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('account-connection-screen')), findsNothing);
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

    await tester.pumpWidget(TetherHealthApp(accountController: account));
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
  Future<UserProfile> getProfile(String accessToken) async => _profile();

  @override
  Future<UserProfile> updateProfile(
          String accessToken, Map<String, Object?> update) =>
      getProfile(accessToken);
}

class _DeferredProfileApi implements ProfileApiClient {
  final _completer = Completer<UserProfile>();

  void complete() => _completer.complete(_profile());

  @override
  Future<UserProfile> getProfile(String accessToken) => _completer.future;

  @override
  Future<UserProfile> updateProfile(
          String accessToken, Map<String, Object?> update) =>
      getProfile(accessToken);
}

UserProfile _profile() => UserProfile(
      id: 'user-id',
      displayName: null,
      locale: 'en',
      timeZone: 'UTC',
      onboardingCompleted: false,
      avatarPath: null,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
