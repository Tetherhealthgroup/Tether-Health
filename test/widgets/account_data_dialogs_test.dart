import 'dart:async';

import 'package:breathefree_patient/account/account_data_api_client.dart';
import 'package:breathefree_patient/account/account_deletion_receipt_store.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/main.dart';
import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:breathefree_patient/profile/profile_repository.dart';
import 'package:breathefree_patient/profile/user_profile.dart';
import 'package:breathefree_patient/programs/secure_program_store.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_controller.dart';
import 'package:breathefree_patient/widgets/account_data_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('identity success wipes locally while receipt waits for Done', (
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

    expect(find.text('Account deleted'), findsOneWidget);
    expect(find.textContaining('receipt-request-id'), findsOneWidget);
    expect(controller.isSignedIn, isFalse);
    expect(controller.profile, isNull);
    expect(events, [
      'remote-delete',
      'sign-out',
      'local-cleanup:user-id',
    ]);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Account deleted'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Account deleted'), findsOneWidget);
    expect(controller.isSignedIn, isFalse);
    expect(events, [
      'remote-delete',
      'sign-out',
      'local-cleanup:user-id',
    ]);

    await tester.tap(find.byKey(const ValueKey('account-delete-done')));
    await tester.pumpAndSettle();

    expect(find.text('Account deleted'), findsNothing);
    expect(find.text('Welcome'), findsOneWidget);
    expect(controller.isSignedIn, isFalse);
    expect(controller.profile, isNull);
    expect(events, [
      'remote-delete',
      'sign-out',
      'local-cleanup:user-id',
      'welcome',
    ]);
  });

  testWidgets('remote deletion cannot be dismissed or submitted twice', (
    tester,
  ) async {
    final events = <String>[];
    final auth = _TestAuth(events);
    final accountData = _PendingAccountDataApi();
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _TestProfileApi()),
      accountData: accountData,
    );
    addTearDown(controller.dispose);
    await controller.signIn(email: 'person@example.test', password: 'password');

    await tester.pumpWidget(
      MaterialApp(
        home: _DeletionHarness(
          account: controller,
          onCleanup: (_) async {},
          onComplete: () {},
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
    await tester.pump();

    expect(accountData.deleteCalls, 1);
    expect(find.text('Deleting account…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('account-delete-confirm')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
          .onPressed,
      isNull,
    );

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(find.byKey(const ValueKey('account-delete-dialog')), findsOneWidget);
    expect(accountData.deleteCalls, 1);

    accountData.complete();
    await tester.pumpAndSettle();

    expect(find.text('Account deleted'), findsOneWidget);
    expect(find.textContaining('pending-receipt-id'), findsOneWidget);
  });

  testWidgets('cleanup failure keeps receipt but not the invalid session', (
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
    var cleanupAttempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: _DeletionHarness(
          account: controller,
          onCleanup: (accountId) async {
            cleanupAttempts++;
            events.add('local-cleanup:$accountId:$cleanupAttempts');
            if (cleanupAttempts == 1) throw StateError('storage unavailable');
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

    expect(find.text('Account deleted'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-delete-finish-error')),
      findsOneWidget,
    );
    expect(controller.isSignedIn, isFalse);
    expect(events, [
      'remote-delete',
      'sign-out',
      'local-cleanup:user-id:1',
    ]);

    await tester.tap(find.byKey(const ValueKey('account-delete-done')));
    await tester.pumpAndSettle();

    expect(find.text('Account deleted'), findsNothing);
    expect(find.text('Welcome'), findsOneWidget);
    expect(controller.isSignedIn, isFalse);
    expect(events, [
      'remote-delete',
      'sign-out',
      'local-cleanup:user-id:1',
      'local-cleanup:user-id:2',
      'welcome',
    ]);
  });

  testWidgets('restored receipt is visible without a deleted account session', (
    tester,
  ) async {
    final events = <String>[];
    final auth = _TestAuth(events);
    await auth.signIn(email: 'person@example.test', password: 'password');
    final store = _TestReceiptStore(
      PendingAccountDeletion(
        accountId: 'user-id',
        receipt: AccountDeletionReceipt(
          requestId: 'restored-receipt-id',
          completedAt: DateTime.utc(2026, 10, 4),
          profileRowsDeleted: 1,
          quitPlanRowsDeleted: 1,
          avatarObjectsDeleted: 1,
          authIdentityDeleted: true,
        ),
      ),
    );
    final controller = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _TestProfileApi()),
      deletionReceipts: store,
    );
    addTearDown(controller.dispose);
    await controller.restorePendingAccountDeletion();

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

    expect(find.text('Account deleted'), findsOneWidget);
    expect(find.textContaining('restored-receipt-id'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-delete-password')), findsNothing);
    expect(controller.isSignedIn, isFalse);

    await tester.tap(find.byKey(const ValueKey('account-delete-done')));
    await tester.pumpAndSettle();

    expect(store.cleared, isTrue);
    expect(events, [
      'sign-out',
      'local-cleanup:user-id',
      'welcome',
    ]);
  });

  testWidgets('app restart wipes local program data and reopens the receipt', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'tether.program.v1.user-id.steady': '{"payload":{},"revision":1}',
    });
    final events = <String>[];
    final auth = _TestAuth(events);
    await auth.signIn(email: 'person@example.test', password: 'password');
    final store = _TestReceiptStore(
      PendingAccountDeletion(
        accountId: 'user-id',
        receipt: AccountDeletionReceipt(
          requestId: 'restart-receipt-id',
          completedAt: DateTime.utc(2026, 10, 4),
          profileRowsDeleted: 1,
          quitPlanRowsDeleted: 1,
          avatarObjectsDeleted: 1,
          authIdentityDeleted: true,
        ),
      ),
    );
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _TestProfileApi()),
      deletionReceipts: store,
    );
    final quitPlan = QuitPlanController.disabled();
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(
      BreatheFreeApp(
        accountController: account,
        quitPlanController: quitPlan,
        programStore: SecureProgramStore(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account deleted'), findsOneWidget);
    expect(find.textContaining('restart-receipt-id'), findsOneWidget);
    expect(account.isSignedIn, isFalse);
    expect(
      (await const FlutterSecureStorage().readAll()).keys,
      isNot(contains('tether.program.v1.user-id.steady')),
    );

    await tester.tap(find.byKey(const ValueKey('account-delete-done')));
    await tester.pumpAndSettle();
    expect(store.cleared, isTrue);
  });

  testWidgets('app restart resumes local cleanup from deletion intent', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'tether.program.v1.user-id.steady': '{"payload":{},"revision":1}',
    });
    final auth = _TestAuth(<String>[]);
    await auth.signIn(email: 'person@example.test', password: 'password');
    final store = _TestReceiptStore(
      const PendingAccountDeletion(accountId: 'user-id'),
    );
    final account = AccountController(
      auth: auth,
      profiles: ProfileRepository(auth: auth, api: _TestProfileApi()),
      deletionReceipts: store,
    );
    final quitPlan = QuitPlanController.disabled();
    addTearDown(account.dispose);
    addTearDown(quitPlan.dispose);

    await tester.pumpWidget(
      BreatheFreeApp(
        accountController: account,
        quitPlanController: quitPlan,
        programStore: SecureProgramStore(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deletion recovery'), findsOneWidget);
    expect(find.textContaining('no server receipt'), findsOneWidget);
    expect(account.isSignedIn, isFalse);
    expect(
      (await const FlutterSecureStorage().readAll()).keys,
      isNot(contains('tether.program.v1.user-id.steady')),
    );

    await tester.tap(find.byKey(const ValueKey('account-delete-done')));
    await tester.pumpAndSettle();
    expect(store.cleared, isTrue);
  });
}

class _TestReceiptStore implements AccountDeletionReceiptStore {
  _TestReceiptStore(this.pending);

  PendingAccountDeletion? pending;
  bool cleared = false;

  @override
  Future<void> clear() async {
    pending = null;
    cleared = true;
  }

  @override
  Future<PendingAccountDeletion?> load() async => pending;

  @override
  Future<void> saveIntent(String accountId) async {
    pending = PendingAccountDeletion(accountId: accountId);
  }

  @override
  Future<void> saveReceipt(PendingAccountDeletion deletion) async {
    pending = deletion;
  }
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
    final completed = await showAccountDeletionDialog(
      context,
      widget.account,
      afterIdentityDeleted: widget.onCleanup,
    );
    if (!mounted || completed != true) return;
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
      authIdentityDeleted: true,
    );
  }

  @override
  Future<AccountDataExport> exportData(String accessToken) =>
      throw UnimplementedError();
}

class _PendingAccountDataApi implements AccountDataApiClient {
  final _deletion = Completer<AccountDeletionReceipt>();
  int deleteCalls = 0;

  void complete() => _deletion.complete(
        AccountDeletionReceipt(
          requestId: 'pending-receipt-id',
          completedAt: DateTime.utc(2026, 9, 26),
          profileRowsDeleted: 1,
          quitPlanRowsDeleted: 1,
          avatarObjectsDeleted: 0,
          authIdentityDeleted: true,
        ),
      );

  @override
  Future<AccountDeletionReceipt> deleteAppData(String accessToken) {
    deleteCalls++;
    return _deletion.future;
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
