// The Supabase Auth submits of the new design, end to end against the
// sandbox backend: email sign-up (18+ only), sign-in outcomes, signing in
// again, the password reset, linking a provider identity, and the session
// check after every save. Synthetic accounts only.
import 'package:breathefree_patient/auth/account_controller.dart';
import 'package:breathefree_patient/auth/backend_account.dart';
import 'package:breathefree_patient/auth/sign_in_flow.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/backend/post_auth_hooks.dart';
import 'package:breathefree_patient/integration/endpoints/auth_endpoints.dart';
import 'package:breathefree_patient/integration/registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

import '../backend/sandbox/support.dart';

const _age = 'I’m 18 or older';
const _password = 'synthetic-passphrase-1';
const _email = 'member-01@sandbox.invalid';

void main() {
  late SandboxHarness h;
  late AccountController account;
  late SignInFlow flow;
  late AppApi api;
  late List<PostAuthEvent> events;
  late List<void Function()> deferred;
  late bool guestData;
  late bool deletionPending;
  late bool deletionConfirms;
  late SessionProbe probe;
  late List<String> opened;
  late List<String> entries;
  late int expired;

  setUp(() {
    h = SandboxHarness();
    account = accountControllerFor(h.backend);
    events = [];
    deferred = [];
    guestData = false;
    deletionPending = false;
    deletionConfirms = true;
    probe = SessionProbe.alive;
    opened = [];
    entries = [];
    expired = 0;
    final hooks = PostAuthHooks()
      ..register((event) async {
        events.add(event);
        // As the real re-issue: confirmed, the account's session ends.
        if (deletionPending && deletionConfirms) {
          deletionPending = false;
          await h.backend.auth.signOut();
        }
      });
    flow = SignInFlow(
      account: account,
      auth: h.backend.auth,
      postAuthHooks: hooks,
      guestDataPresent: () async => guestData,
      // The re-issue hook below clears it when the server confirms.
      deletionPending: (_) async => deletionPending,
      probeSession: () async => probe,
      defer: deferred.add,
    )
      ..openOnTop = opened.add
      ..showEntry = entries.add
      ..onSessionExpired = () async {
        expired++;
      };
    AuthEndpoints.flow = flow;
    api = AppApi(handlers: withSessionChecks(authHandlers()));
  });

  tearDown(() {
    AuthEndpoints.flow = null;
    TSession.clear();
  });

  Future<TResult> submit(
    String endpoint,
    String screen,
    Map<String, Object?> values,
  ) {
    values.forEach((key, value) => TSession.set('$screen.$key', value));
    return api.submit(endpoint, screenId: screen);
  }

  /// Runs what the flow deferred until after the save returned.
  Future<void> settle() async {
    while (deferred.isNotEmpty) {
      deferred.removeAt(0)();
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<TResult> signUp({
    String email = _email,
    String password = _password,
    bool ticked = true,
  }) =>
      submit(signUpEndpoint, 'ob_account', {
        'email': email,
        'password': password,
        'age_18_or_older': ticked ? [_age] : <String>[],
      });

  Future<TResult> signIn(String email, String password,
          {String screen = 'auth_signin'}) =>
      submit(tokenEndpoint, screen, {'email': email, 'password': password});

  group('sign-up', () {
    test('refused until "I’m 18 or older" is ticked; nothing is created',
        () async {
      expect(await signUp(ticked: false),
          const TResult.failed(AuthCodes.ageNotConfirmed));
      expect(account.isSignedIn, isFalse);
      expect(await signIn(_email, _password),
          const TResult.outcome(SignInOutcomes.wrongPassword),
          reason: 'no account was created');
    });

    test('a password shorter than 12 characters is refused', () async {
      expect(await signUp(password: 'short-pw'),
          const TResult.failed(AuthCodes.passwordTooShort));
      expect(account.isSignedIn, isFalse);
    });

    test(
        'signs up, runs the post-auth steps as a new account, scrubs the '
        'password', () async {
      expect(await signUp(), const TResult.ok());
      expect(account.isSignedIn, isTrue);
      expect(events.single.isNewAccount, isTrue);
      expect(events.single.accountId, account.accountId);
      expect(TSession.values.containsKey('ob_account.password'), isFalse);
    });

    test(
        'a sign-up waiting for its email link commits once that account '
        'signs in', () async {
      expect(await signUp(), const TResult.ok());
      await account.signOut();
      events.clear();
      guestData = true;
      flow.awaitConfirmation(_email.toUpperCase());
      expect(await signIn(_email, _password),
          const TResult.outcome(SignInOutcomes.success),
          reason: 'a new account has nothing to merge into');
      expect(events.single.isNewAccount, isTrue);
    });
  });

  group('email sign-in', () {
    setUp(() async {
      expect(await signUp(), const TResult.ok());
      await account.signOut();
      events.clear();
      TSession.clear();
    });

    test('a wrong password takes the "Wrong password" outcome', () async {
      expect(await signIn(_email, 'not-the-passphrase'),
          const TResult.outcome(SignInOutcomes.wrongPassword));
      expect(account.isSignedIn, isFalse);
      expect(events, isEmpty);
      expect(TSession.values.containsKey('auth_signin.password'), isFalse,
          reason: 'the password leaves the session after a failure too');
    });

    test('an unknown email reads the same as a wrong password', () async {
      expect(await signIn('nobody@sandbox.invalid', _password),
          const TResult.outcome(SignInOutcomes.wrongPassword));
    });

    test('success; an existing account never commits onboarding', () async {
      expect(await signIn(_email, _password, screen: 'auth_signin_error'),
          const TResult.outcome(SignInOutcomes.success));
      expect(account.isSignedIn, isTrue);
      expect(events.single.isNewAccount, isFalse);
      expect(
          TSession.values.containsKey('auth_signin_error.password'), isFalse);
    });

    test('guest data on the phone offers the merge', () async {
      guestData = true;
      expect(await signIn(_email, _password),
          const TResult.outcome(SignInOutcomes.successGuestPlan));
    });

    test(
        'a deletion the server never confirmed is sent again and the '
        'member does not continue', () async {
      deletionPending = true;
      expect(await signIn(_email, _password),
          const TResult.failed(AuthCodes.accountDeleted));
      expect(events.single.isNewAccount, isFalse,
          reason: 'the steps ran once, as a sign-in, to re-issue it');
      await settle();
      expect(account.isSignedIn, isFalse);
      expect(account.pendingAccountDeletion, isNotNull);
    });

    test(
        'when sending the deletion again fails, the member is signed out '
        'with the generic error, not told the account is deleted', () async {
      deletionPending = true;
      deletionConfirms = false;
      expect(await signIn(_email, _password),
          const TResult.failed(AuthCodes.signInBlocked));
      await settle();
      expect(account.isSignedIn, isFalse);
      expect(account.pendingAccountDeletion, isNull);
    });
  });

  group('signing in again (auth_session)', () {
    setUp(() async {
      expect(await signUp(), const TResult.ok());
      TSession.clear();
    });

    test('the right password keeps the same account', () async {
      final id = account.accountId;
      expect(
          await submit(tokenEndpoint, 'auth_session', {'password': _password}),
          const TResult.ok());
      expect(account.accountId, id);
    });

    test('a wrong password fails and never signs the member out', () async {
      final id = account.accountId;
      expect(
          await submit(
              tokenEndpoint, 'auth_session', {'password': 'wrong-passphrase'}),
          const TResult.failed(AuthCodes.invalidCredentials));
      expect(h.backend.auth.currentIdentity?.id, id);
    });
  });

  group('password reset', () {
    setUp(() async {
      expect(await signUp(), const TResult.ok());
      await account.signOut();
      TSession.clear();
    });

    test('an unknown email gets the same answer and opens nothing', () async {
      expect(
          await submit(
              recoverEndpoint, 'auth_forgot', {'email': 'x@sandbox.invalid'}),
          const TResult.ok());
      await Future<void>.delayed(Duration.zero);
      expect(account.passwordRecoveryPending, isFalse);
    });

    test('reset link, new password (twice, 12+), then sign-in with it',
        () async {
      expect(await submit(recoverEndpoint, 'auth_forgot', {'email': _email}),
          const TResult.ok());
      await Future<void>.delayed(Duration.zero);
      expect(account.passwordRecoveryPending, isFalse,
          reason: 'nothing opens until the emailed link is used');
      expect(h.backend.auth.currentIdentity, isNull);
      // Stands in for opening the email.
      final token = await h.backend.auth.recoveryTokenFor(_email);
      expect(await h.backend.auth.completeRecovery(token!), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(account.passwordRecoveryPending, isTrue);
      expect(
          await submit(updateUserEndpoint, 'auth_newpass', {
            'new_password': 'new-passphrase-22',
            'confirm_password': 'new-passphrase-23',
          }),
          const TResult.failed(AuthCodes.passwordsDiffer));
      expect(
          await submit(updateUserEndpoint, 'auth_newpass', {
            'new_password': 'new-passphrase-22',
            'confirm_password': 'new-passphrase-22',
          }),
          const TResult.ok());
      expect(account.passwordRecoveryPending, isFalse);
      expect(TSession.values.keys.where((k) => k.startsWith('auth_newpass')),
          isEmpty);
      await account.signOut();
      expect(await signIn(_email, 'new-passphrase-22'),
          const TResult.outcome(SignInOutcomes.success));
    });

    test('without an opened link the new password is refused', () async {
      expect(
          await submit(updateUserEndpoint, 'auth_newpass', {
            'new_password': 'new-passphrase-22',
            'confirm_password': 'new-passphrase-22',
          }),
          const TResult.failed(AuthCodes.recoveryExpired));
    });
  });

  group('linking a provider identity (auth_link)', () {
    const linkedEmail = 'google-7@sandbox.invalid';

    setUp(() async {
      expect(await signUp(email: linkedEmail), const TResult.ok());
      await account.signOut();
      TSession.clear();
    });

    test('no waiting identity: refused', () async {
      expect(
          await submit(
              linkIdentityEndpoint, 'auth_link', {'password': _password}),
          const TResult.failed(AuthCodes.linkExpired));
    });

    test('the password links it; afterwards either sign-in works', () async {
      flow.pendingLink = const PendingLink(
        provider: IdTokenProvider.google,
        idToken: 'sandbox-google-7',
        email: linkedEmail,
      );
      expect(
          await submit(
              linkIdentityEndpoint, 'auth_link', {'password': _password}),
          const TResult.ok());
      expect(flow.pendingLink, isNull);
      await account.signOut();
      expect(
          await h.backend.auth
              .signInWithIdToken(IdTokenProvider.google, 'sandbox-google-7'),
          AuthOutcome.success);
    });

    test('a wrong password links nothing', () async {
      flow.pendingLink = const PendingLink(
        provider: IdTokenProvider.google,
        idToken: 'sandbox-google-7',
        email: linkedEmail,
      );
      expect(
          await submit(
              linkIdentityEndpoint, 'auth_link', {'password': 'wrong-one-123'}),
          const TResult.failed(AuthCodes.invalidCredentials));
      expect(
          await h.backend.auth
              .signInWithIdToken(IdTokenProvider.google, 'sandbox-google-7'),
          AuthOutcome.emailTaken);
    });
  });

  test('without the shell every auth submit fails closed', () async {
    AuthEndpoints.flow = null;
    expect(await signUp(), const TResult.failed(AuthCodes.notReady));
    expect(await signIn(_email, _password),
        const TResult.failed(AuthCodes.notReady));
  });

  group('after every save', () {
    late AppApi saves;

    setUp(() async {
      expect(await signUp(), const TResult.ok());
      await settle();
      saves = AppApi(
        handlers: withSessionChecks({
          'POST /v1/account/export': (_) async =>
              const TResult.failed(SessionCodes.recentAuthRequired),
          'POST /v1/records/check-ins': (_) async =>
              const TResult.failed(SessionCodes.unauthenticated),
          accountDeletionEndpoint: (_) async {
            await h.backend.auth.signOut();
            return const TResult.ok();
          },
        }),
      );
    });

    test(
        'a refusal that needs a recent sign-in asks to sign in again over '
        'the current screen, and never signs out', () async {
      await saves.submit('POST /v1/account/export', screenId: 'account_data');
      expect(opened, isEmpty, reason: 'only after the save returned');
      await settle();
      expect(opened, [Routes.authSession]);
      expect(account.isSignedIn, isTrue);
      expect(expired, 0);
    });

    test('"unauthenticated" with a live session is a recent-sign-in ask',
        () async {
      probe = SessionProbe.alive;
      await saves.submit('POST /v1/records/check-ins', screenId: 'checkin');
      await settle();
      expect(opened, [Routes.authSession]);
      expect(expired, 0);
    });

    test(
        '"unauthenticated" with a refused session ends it and asks to sign '
        'in again from the entry screen', () async {
      probe = SessionProbe.expired;
      await saves.submit('POST /v1/records/check-ins', screenId: 'checkin');
      await settle();
      expect(expired, 1);
      expect(entries, [Routes.authSession]);
    });

    test('offline decides nothing', () async {
      probe = SessionProbe.unknown;
      await saves.submit('POST /v1/records/check-ins', screenId: 'checkin');
      await settle();
      expect(expired, 0);
      expect(opened, isEmpty);
      expect(entries, isEmpty);
    });

    test('a completed deletion is passed on as a deletion', () async {
      final id = account.accountId!;
      var notified = 0;
      account.addListener(() => notified++);
      await saves.submit(accountDeletionEndpoint, screenId: 'account_delete');
      await settle();
      expect(account.pendingAccountDeletion?.accountId, id);
      expect(account.isSignedIn, isFalse);
      expect(notified, greaterThan(0));
    });

    test('an Apple account is asked to sign in again with Apple', () async {
      flow.socialProvider = () => IdTokenProvider.apple;
      await saves.submit('POST /v1/account/export', screenId: 'account_data');
      await settle();
      expect(opened, [Routes.authSessionApple]);
    });
  });
}
