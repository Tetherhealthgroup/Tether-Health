// Sandbox sign-in: sign-up (verified at once), sign-in, recovery, password
// update, session expiry and renewal, simulated ID-token sign-in.
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late SandboxHarness h;
  late SandboxAuthBackend auth;

  setUp(() {
    h = SandboxHarness();
    auth = h.backend.auth;
  });

  test('sign-up signs in at once; the email is stored normalised', () async {
    final result = await auth.signUp(
        email: ' Member@Sandbox.invalid ', password: 'pass123');
    expect(result.status, AuthSignUpStatus.authenticated);
    expect(auth.currentIdentity!.email, 'member@sandbox.invalid');
    expect(await auth.accessToken(), result.identity!.accessToken);
  });

  test('sign-up with a taken email creates nothing and reveals nothing',
      () async {
    await auth.signUp(email: 'a@sandbox.invalid', password: 'pass123');
    final id = auth.currentIdentity!.id;
    await auth.signOut();
    final again =
        await auth.signUp(email: 'a@sandbox.invalid', password: 'other1');
    expect(again.status, AuthSignUpStatus.emailConfirmationRequired);
    expect(auth.currentIdentity, isNull);
    await auth.signIn(email: 'a@sandbox.invalid', password: 'pass123');
    expect(auth.currentIdentity!.id, id);
  });

  test('sign-in refuses a wrong password; no password is stored as written',
      () async {
    await auth.signUp(email: 'b@sandbox.invalid', password: 'pass123');
    await auth.signOut();
    await expectLater(
        auth.signIn(email: 'b@sandbox.invalid', password: 'nope'),
        throwsA(isA<AuthFailure>().having(
            (f) => f.reason, 'reason', AuthFailureReason.invalidCredentials)));
    expect(h.persistence.document, isNot(contains('pass123')));
  });

  test('recovery opens the update step; the new password works', () async {
    await auth.signUp(email: 'c@sandbox.invalid', password: 'pass123');
    await auth.signOut();
    final events = <void>[];
    final sub = auth.passwordRecoveryEvents.listen(events.add);
    await auth.requestPasswordReset(email: 'unknown@sandbox.invalid');
    await auth.requestPasswordReset(email: 'c@sandbox.invalid');
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    await auth.updatePassword(newPassword: 'newpass1');
    await auth.signOut();
    await auth.signIn(email: 'c@sandbox.invalid', password: 'newpass1');
    expect(auth.currentIdentity, isNotNull);
    await sub.cancel();
  });

  test('a session renews itself; an ended session is refused', () async {
    await auth.signUp(email: 'd@sandbox.invalid', password: 'pass123');
    final first = await auth.accessToken();
    h.now = h.now.add(const Duration(hours: 2));
    final renewed = await auth.accessToken();
    expect(renewed, isNot(first));
    expect(renewed, isNotNull);
    await auth.expireSession();
    final answer = await h.backend.transport.send(BackendRequest(
        service: BackendService.api,
        method: BackendMethod.get,
        path: '/v1/today'));
    expect(answer, const BackendProblem(401, 'unauthenticated'));
    h.now = h.now.add(const Duration(hours: 2));
    expect(await auth.accessToken(), isNull);
  });

  test('re-authentication refreshes the recent sign-in', () async {
    await auth.signUp(email: 'e@sandbox.invalid', password: 'pass123');
    h.now = h.now.add(const Duration(minutes: 30));
    expect((await h.api.account.export()).errorOrNull?.status, 401);
    await auth.reauthenticate(password: 'pass123');
    expect((await h.api.account.export()).isSuccess, isTrue);
  });

  group('ID-token sign-in (simulated)', () {
    test('creates <provider>-<n>@sandbox.invalid, then signs in to it',
        () async {
      expect(await auth.signInWithIdToken(IdTokenProvider.apple, 'sandbox-7'),
          AuthOutcome.successNew);
      expect(auth.currentIdentity!.email, 'apple-7@sandbox.invalid');
      await auth.signOut();
      expect(await auth.signInWithIdToken(IdTokenProvider.apple, 'sandbox-7'),
          AuthOutcome.success);
      expect(SandboxAuthBackend.simulatedEmail(IdTokenProvider.google, 'x-12'),
          'google-12@sandbox.invalid');
    });

    test('emailTaken when a password account has that email', () async {
      await auth.signUp(email: 'google-3@sandbox.invalid', password: 'pass123');
      await auth.signOut();
      expect(await auth.signInWithIdToken(IdTokenProvider.google, '3'),
          AuthOutcome.emailTaken);
      expect(auth.currentIdentity, isNull);
    });

    test('linking adds the provider; another account\'s email is taken',
        () async {
      await auth.signInWithIdToken(IdTokenProvider.apple, '1');
      await auth.signOut();
      await auth.signUp(email: 'f@sandbox.invalid', password: 'pass123');
      expect(await auth.linkIdentity(IdTokenProvider.apple, '1'),
          AuthOutcome.emailTaken);
      expect(await auth.linkIdentity(IdTokenProvider.google, '2'),
          AuthOutcome.success);
    });
  });

  test('the session survives a restart only after restore()', () async {
    await auth.signUp(email: 'g@sandbox.invalid', password: 'pass123');
    final fresh = h.build();
    expect(fresh.auth.currentIdentity, isNull);
    await fresh.restore();
    expect(fresh.auth.currentIdentity!.email, 'g@sandbox.invalid');
  });
}
