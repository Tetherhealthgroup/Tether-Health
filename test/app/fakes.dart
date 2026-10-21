// Synthetic fakes for the tether_ui shell tests. No real identities.
import 'dart:async';

import 'package:breathefree_patient/account/account_data_api_client.dart';
import 'package:breathefree_patient/account/account_deletion_receipt_store.dart';
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:breathefree_patient/profile/profile_repository.dart';
import 'package:breathefree_patient/profile/user_profile.dart';
import 'package:breathefree_patient/quit_plan/guest_quit_plan_store.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';

/// Auth with a settable identity. `signIn` signs in as the email's local
/// part, so `synthetic-user-02@example.test` becomes `synthetic-user-02`.
class FakeAuth implements AuthGateway, RecentAuthGateway {
  FakeAuth({String? signedInAs})
      : _identity = signedInAs == null ? null : _identityFor(signedInAs);

  AuthIdentity? _identity;

  static AuthIdentity _identityFor(String id) =>
      AuthIdentity(id: id, email: '$id@example.test', accessToken: 'token-$id');

  @override
  AuthIdentity? get currentIdentity => _identity;

  @override
  Future<AuthIdentity> signIn({
    required String email,
    required String password,
  }) async =>
      _identity = _identityFor(email.split('@').first);

  @override
  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
  }) async =>
      AuthSignUpResult.authenticated(
        _identity = _identityFor(email.split('@').first),
      );

  @override
  Future<void> resendSignUpConfirmation({required String email}) async {}

  @override
  Future<void> signOut() async => _identity = null;

  @override
  Future<AuthIdentity> reauthenticate({required String password}) async =>
      _identity ?? (throw StateError('signed out'));
}

/// Profiles whose onboarding state the test sets. While [gate] is set, a
/// load waits for it.
class FakeProfiles implements ProfileApiClient {
  FakeProfiles({this.onboardingCompleted = true});

  bool onboardingCompleted;
  Completer<void>? gate;
  int loads = 0;

  @override
  Future<UserProfile> getProfile(String accessToken) async {
    loads++;
    final wait = gate;
    if (wait != null) await wait.future;
    return _profile(accessToken);
  }

  @override
  Future<UserProfile> updateProfile(
          String accessToken, Map<String, Object?> update) async =>
      _profile(accessToken);

  UserProfile _profile(String accessToken) => UserProfile(
        id: accessToken.replaceFirst('token-', ''),
        displayName: 'Synthetic Member',
        locale: 'en',
        timeZone: 'UTC',
        onboardingCompleted: onboardingCompleted,
        avatarPath: null,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
}

class FakeAccountData implements AccountDataApiClient {
  @override
  Future<AccountDataExport> exportData(String accessToken) async =>
      const AccountDataExport(document: {'schemaVersion': '1.0'});

  @override
  Future<AccountDeletionReceipt> deleteAppData(String accessToken) async =>
      AccountDeletionReceipt(
        requestId: 'synthetic-receipt-01',
        completedAt: DateTime.utc(2026, 10, 21),
        profileRowsDeleted: 1,
        quitPlanRowsDeleted: 0,
        avatarObjectsDeleted: 0,
        authIdentityDeleted: true,
      );
}

class FakeReceipts implements AccountDeletionReceiptStore {
  FakeReceipts([this.saved]);

  PendingAccountDeletion? saved;

  @override
  Future<PendingAccountDeletion?> load() async => saved;

  @override
  Future<void> saveIntent(String accountId) async =>
      saved = PendingAccountDeletion(accountId: accountId);

  @override
  Future<void> saveReceipt(PendingAccountDeletion deletion) async =>
      saved = deletion;

  @override
  Future<void> clear() async => saved = null;
}

/// An account controller on the fakes above.
AccountController fakeAccount({
  FakeAuth? auth,
  FakeProfiles? profiles,
  FakeReceipts? receipts,
}) {
  final gateway = auth ?? FakeAuth();
  return AccountController(
    auth: gateway,
    profiles: ProfileRepository(auth: gateway, api: profiles ?? FakeProfiles()),
    accountData: FakeAccountData(),
    deletionReceipts: receipts ?? FakeReceipts(),
    signInProfileRetryDelays: const [Duration.zero],
  );
}

/// A guest plan store holding a plan or none.
class FakeGuestStore implements GuestQuitPlanStore {
  FakeGuestStore({bool hasPlan = false})
      : _snapshot = hasPlan
            ? GuestQuitPlanSnapshot(
                plan: QuitPlan(
                  userId: 'guest',
                  dailyCigaretteUse: null,
                  smokingTriggers: const [],
                  customSmokingTrigger: null,
                  readinessPath: 'ready',
                  quitPlanPath: 'date',
                  quitDate: DateTime.utc(2026, 11, 1),
                  quitDayCheckIn: false,
                  quitReasons: const [],
                  customQuitReason: null,
                  topQuitReason: null,
                  supportPeople: const [],
                  preparationTasks: const [],
                  treatmentSupport: false,
                  careTeamReminder: false,
                ),
                stage: GuestPlanStage.draft,
                savedAt: DateTime.utc(2026, 10, 21),
              )
            : null;

  final GuestQuitPlanSnapshot? _snapshot;

  @override
  bool get isPersistent => true;

  @override
  Future<GuestQuitPlanSnapshot?> load() async => _snapshot;

  @override
  Future<void> save(GuestQuitPlanSnapshot snapshot) async {}

  @override
  Future<void> clear() async {}
}
