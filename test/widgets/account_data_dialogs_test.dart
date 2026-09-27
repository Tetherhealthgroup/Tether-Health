import 'package:breathefree_patient/account/account_data_api_client.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:breathefree_patient/profile/profile_repository.dart';
import 'package:breathefree_patient/profile/user_profile.dart';
import 'package:breathefree_patient/widgets/account_data_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('receipt stays visible and session cleanup waits for Done', (
    tester,
  ) async {
    final events = <String>[];
    final auth = _TestAuth(events);
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _TestProfileApi()),
      accountData: _TestAccountDataApi(events),
    );
    addTearDown(controller.dispose);
    await controller.signIn(email: 'person@example.test', password: 'password');

    await tester.pumpWidget(
      MaterialApp(
        home: _DeletionHarness(
          account: controller,
          onCleanup: (accountId) async {
            events.add('local-cleanup:$accountId');
          },
          onComplete: () => events.add('welcome'),
        ),
      ),
    );

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('account-delete-password')),
      'password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-delete-confirmation')),
      'DELETE',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('account-delete-confirm')),
    );
    await tester.tap(find.byKey(const ValueKey('account-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('App data deleted'), findsOneWidget);
    expect(find.textContaining('receipt-request-id'), findsOneWidget);
    expect(controller.isSignedIn, isTrue);
    expect(controller.profile, isNotNull);
    expect(events, ['remote-delete']);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('App data deleted'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('App data deleted'), findsOneWidget);
    expect(controller.isSignedIn, isTrue);
    expect(events, ['remote-delete']);

    await tester.tap(find.byKey(const ValueKey('account-delete-done')));
    await tester.pumpAndSettle();

    expect(find.text('App data deleted'), findsNothing);
    expect(find.text('Welcome'), findsOneWidget);
    expect(controller.isSignedIn, isFalse);
    expect(controller.profile, isNull);
    expect(events, [
      'remote-delete',
      'local-cleanup:user-id',
      'sign-out',
      'welcome',
    ]);
  });
}

class _DeletionHarness extends StatefulWidget {
  const _DeletionHarness({
    required this.account,
    required this.onCleanup,
    required this.onComplete,
  });

  final AccountController account;
  final Future<void> Function(String accountId) onCleanup;
  final VoidCallback onComplete;

  @override
  State<_DeletionHarness> createState() => _DeletionHarnessState();
}

class _DeletionHarnessState extends State<_DeletionHarness> {
  bool _complete = false;

  Future<void> _delete() async {
    final receipt = await showAccountDeletionDialog(
      context,
      widget.account,
      afterDeletionAcknowledged: widget.onCleanup,
    );
    if (!mounted || receipt == null) return;
    widget.onComplete();
    setState(() => _complete = true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: _complete
              ? const Text('Welcome')
              : FilledButton(
                  onPressed: _delete,
                  child: const Text('Delete account'),
                ),
        ),
      );
}

class _TestAuth implements AuthGateway, RecentAuthGateway {
  _TestAuth(this.events);

  final List<String> events;
  AuthIdentity? _identity;

  @override
  AuthIdentity? get currentIdentity => _identity;

  @override
  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  }) async =>
      _identity = AuthIdentity(
        id: 'user-id',
        email: email,
        accessToken: 'access-token',
      );

  @override
  Future<AuthIdentity> reauthenticate({required String password}) async =>
      _identity = const AuthIdentity(
        id: 'user-id',
        email: 'person@example.test',
        accessToken: 'recent-access-token',
      );

  @override
  Future<void> signOut() async {
    events.add('sign-out');
    _identity = null;
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> resendSignUpConfirmation({required String email}) =>
      throw UnimplementedError();
}

class _TestAccountDataApi implements AccountDataApiClient {
  const _TestAccountDataApi(this.events);

  final List<String> events;

  @override
  Future<AccountDeletionReceipt> deleteAppData(String accessToken) async {
    events.add('remote-delete');
    return AccountDeletionReceipt(
      requestId: 'receipt-request-id',
      completedAt: DateTime.utc(2026, 9, 26),
      profileRowsDeleted: 1,
      quitPlanRowsDeleted: 1,
      avatarObjectsDeleted: 0,
      authIdentityDeleted: false,
    );
  }

  @override
  Future<AccountDataExport> exportData(String accessToken) =>
      throw UnimplementedError();
}

class _TestProfileApi implements ProfileApiClient {
  final _profile = UserProfile(
    id: 'user-id',
    displayName: 'Test Person',
    locale: 'en',
    timeZone: 'America/Los_Angeles',
    onboardingCompleted: true,
    avatarPath: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  @override
  Future<UserProfile> getProfile(String accessToken) async => _profile;

  @override
  Future<UserProfile> updateProfile(
    String accessToken,
    Map<String, Object?> update,
  ) async =>
      _profile;
}
