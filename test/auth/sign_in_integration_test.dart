import 'dart:async';

import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:breathefree_patient/profile/profile_repository.dart';
import 'package:breathefree_patient/profile/user_profile.dart';
import 'package:breathefree_patient/quit_plan/guest_quit_plan_store.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_api_client.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_controller.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_repository.dart';
import 'package:breathefree_patient/screens/approved_screen_player.dart';
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

  testWidgets('account creation handles email confirmation and resend',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth(requiresConfirmation: true);
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
    await tester.tap(find.byKey(const ValueKey('account-toggle-mode')));
    await tester.pumpAndSettle();

    expect(find.text('Create your BreatheFree account'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('sign-up-confirm-password')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('sign-in-email')),
      'new-person@example.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign-in-password')),
      'short',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign-up-confirm-password')),
      'different',
    );
    await tester.tap(find.byKey(const ValueKey('sign-up-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('sign-in-password')),
      'local-password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign-up-confirm-password')),
      'local-password',
    );
    await tester.tap(find.byKey(const ValueKey('sign-up-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-up-confirmation-message')),
        findsOneWidget);
    expect(account.isSignedIn, isFalse);

    await tester.tap(find.byKey(const ValueKey('sign-up-resend')));
    await tester.pumpAndSettle();
    expect(find.text('Confirmation email requested.'), findsOneWidget);
    expect(auth.resentEmail, 'new-person@example.test');
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

  testWidgets('restored draft plan returns to review', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth(signedIn: true);
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _ProfileApi()),
    );
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _PlanApi()),
    );
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(BreatheFreeApp(
      accountController: account,
      quitPlanController: quitPlan,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('functional-review-quit-plan-screen')),
        findsOneWidget);
  });

  testWidgets('restored completed account loads its plan and opens home',
      (tester) async {
    // The quit-day Home is laid out for phone widths with real fonts; the
    // test font is wider, so this restore check uses a wider view.
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth(signedIn: true);
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(
        auth: auth,
        api: _ProfileApi(onboardingCompleted: true),
      ),
    );
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _PlanApi()),
    );
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(BreatheFreeApp(
      accountController: account,
      quitPlanController: quitPlan,
    ));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('account-connection-screen')), findsNothing);
    // Home follows the plan's quit date (2026-10-01): the countdown Home
    // before it, the quit-day Home from that date on.
    final onQuitDay = homeScreenFor(quitPlan.plan!.quitDate) == 21;
    expect(find.text('SINCE YOUR PLANNED QUIT TIME'),
        onQuitDay ? findsOneWidget : findsNothing);
    expect(find.byKey(const ValueKey('functional-home-preparation-screen')),
        onQuitDay ? findsNothing : findsOneWidget);
    expect(quitPlan.plan?.topQuitReason, 'family');
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

    await tester.pumpWidget(BreatheFreeApp(accountController: account));
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

  testWidgets('sign-out resets the journey and clears cloud plan memory',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth(signedIn: true);
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _ProfileApi()),
    );
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _PlanApi()),
    );
    await quitPlan.save(await _PlanApi().getQuitPlan('fake-access-token'));
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(BreatheFreeApp(
      initialScreen: 27,
      accountController: account,
      quitPlanController: quitPlan,
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('settings-sign-out')));
    await tester.tap(find.byKey(const ValueKey('settings-sign-out')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('functional-welcome-screen')),
        findsOneWidget);
    expect(account.isSignedIn, isFalse);
    expect(quitPlan.plan, isNull);
  });

  testWidgets(
      'sign-in with a plan on or after its quit date opens quit-day Home',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // The saved plan's quit date (2026-10-01) has passed.
    expect(homeScreenFor(DateTime(2026, 10, 1)), 21);

    final auth = _SuccessfulAuth();
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(
        auth: auth,
        api: _ProfileApi(onboardingCompleted: true),
      ),
    );
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _PlanApi()),
    );
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(BreatheFreeApp(
      accountController: account,
      quitPlanController: quitPlan,
    ));
    await tester.pumpAndSettle();
    await _signInThroughDialog(tester, 'welcome-sign-in');

    expect(find.text('SINCE YOUR PLANNED QUIT TIME'), findsOneWidget);
    expect(find.byKey(const ValueKey('functional-home-preparation-screen')),
        findsNothing);
  });

  testWidgets(
      'sign-out to a started device plan on its quit day opens quit-day Home',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth(signedIn: true);
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _ProfileApi()),
    );
    final devicePlan = await _PlanApi().getQuitPlan('fake-access-token');
    final quitPlan = QuitPlanController(
      auth: auth,
      repository: QuitPlanRepository(auth: auth, api: _PlanApi()),
      guestStore: _MemoryGuestStore(GuestQuitPlanSnapshot(
        plan: QuitPlan.fromJson({
          ...devicePlan.toLocalJson(),
          'quitDate': DateUtils.dateOnly(DateTime.now()).toIso8601String(),
        }),
        stage: GuestPlanStage.active,
        savedAt: DateTime.utc(2026, 10, 1),
      )),
    );
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(BreatheFreeApp(
      initialScreen: 27,
      accountController: account,
      quitPlanController: quitPlan,
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('settings-sign-out')));
    await tester.tap(find.byKey(const ValueKey('settings-sign-out')));
    await tester.pumpAndSettle();

    expect(account.isSignedIn, isFalse);
    expect(find.text('SINCE YOUR PLANNED QUIT TIME'), findsOneWidget);
    expect(find.byKey(const ValueKey('functional-home-preparation-screen')),
        findsNothing);
  });

  testWidgets('signing in clears a Rescue result rated before sign-in',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth();
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(
        auth: auth,
        api: _ProfileApi(onboardingCompleted: true),
      ),
    );
    addTearDown(account.dispose);

    await tester.pumpWidget(BreatheFreeApp(
      initialScreen: 19,
      accountController: account,
    ));
    await tester.pumpAndSettle();
    for (final key in const [
      'craving-recheck-number-2',
      'craving-recheck-helpful-yes',
      'craving-recheck-save',
      'screen-21-back-to-today',
      'preparation-open-rescue',
      'rescue-start-continue',
    ]) {
      await _tapKey(tester, key);
    }
    expect(
        find.byKey(const ValueKey('rescue-tool-last-result')), findsOneWidget);

    await _tapKey(tester, 'rescue-tool-back');
    await _tapKey(tester, 'preparation-profile');
    await _signInThroughDialog(tester, 'settings-sign-out');
    expect(find.byKey(const ValueKey('functional-home-preparation-screen')),
        findsOneWidget);

    await _tapKey(tester, 'preparation-open-rescue');
    await _tapKey(tester, 'rescue-start-continue');
    expect(find.byKey(const ValueKey('rescue-tool-last-result')), findsNothing);
    expect(find.text('Start with what helped before.'), findsNothing);
  });

  testWidgets('sign-in displays the specific safe authentication error',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SuccessfulAuth(
      signInFailure: const AuthFailure(AuthFailureReason.invalidCredentials),
    );
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
      find.byKey(const ValueKey('sign-in-email')),
      'person@example.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign-in-password')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const ValueKey('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(
        find.textContaining('Check your details and connection'), findsNothing);
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
  _SuccessfulAuth({
    bool signedIn = false,
    this.requiresConfirmation = false,
    this.signInFailure,
  }) {
    if (signedIn) {
      _identity = const AuthIdentity(
        id: 'user-id',
        email: 'person@example.test',
        accessToken: 'fake-access-token',
      );
    }
  }

  final bool requiresConfirmation;
  final Object? signInFailure;
  AuthIdentity? _identity;
  String? resentEmail;

  @override
  AuthIdentity? get currentIdentity => _identity;

  @override
  Future<AuthIdentity> signIn(
      {required String email, required String password}) async {
    final failure = signInFailure;
    if (failure != null) throw failure;
    return _identity = AuthIdentity(
      id: 'user-id',
      email: email,
      accessToken: 'fake-access-token',
    );
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
  Future<void> signOut() async => _identity = null;
}

class _ProfileApi implements ProfileApiClient {
  _ProfileApi({this.onboardingCompleted = false});

  final bool onboardingCompleted;

  @override
  Future<UserProfile> getProfile(String accessToken) async =>
      _profile(onboardingCompleted: onboardingCompleted);

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

class _PlanApi implements QuitPlanApiClient {
  @override
  Future<QuitPlan> createQuitPlan(String accessToken, QuitPlan plan) async =>
      plan;

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) async => QuitPlan(
        userId: 'user-id',
        dailyCigaretteUse: 'tenOrFewer',
        smokingTriggers: const ['stress'],
        customSmokingTrigger: null,
        readinessPath: 'prepare',
        quitPlanPath: 'setQuitDate',
        quitDate: DateTime(2026, 10, 1),
        quitDayCheckIn: true,
        quitReasons: const ['family'],
        customQuitReason: null,
        topQuitReason: 'family',
        supportPeople: const [],
        preparationTasks: const ['removeSupplies'],
        treatmentSupport: true,
        careTeamReminder: true,
      );

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) async => plan;
}

UserProfile _profile({bool onboardingCompleted = false}) => UserProfile(
      id: 'user-id',
      displayName: null,
      locale: 'en',
      timeZone: 'UTC',
      onboardingCompleted: onboardingCompleted,
      avatarPath: null,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _signInThroughDialog(WidgetTester tester, String opener) async {
  await _tapKey(tester, opener);
  await tester.enterText(
      find.byKey(const ValueKey('sign-in-email')), 'person@example.test');
  await tester.enterText(
      find.byKey(const ValueKey('sign-in-password')), 'local-password');
  await tester.tap(find.byKey(const ValueKey('sign-in-submit')));
  await tester.pumpAndSettle();
}

class _MemoryGuestStore implements GuestQuitPlanStore {
  _MemoryGuestStore(this.snapshot);

  GuestQuitPlanSnapshot? snapshot;

  @override
  bool get isPersistent => true;

  @override
  Future<GuestQuitPlanSnapshot?> load() async => snapshot;

  @override
  Future<void> save(GuestQuitPlanSnapshot value) async => snapshot = value;

  @override
  Future<void> clear() async => snapshot = null;
}
