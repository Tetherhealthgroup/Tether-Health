// The Supabase Auth submits of the new design's screens, served through the
// app's backend in both modes (the on-device sandbox or the real services):
// email sign-up, sign-in, signing in again, the password reset and linking
// Apple or Google to an email account. Also the check that runs after every
// save (see SignInFlow.afterSubmit).
//
// The registry removes every password from the session after the result
// and never queues these submits. Nothing here logs.
import 'package:tether_ui/ui/ui.dart';

import '../../auth/account_controller.dart';
import '../../auth/auth_gateway.dart';
import '../../auth/sign_in_flow.dart';
import '../../backend/backend.dart';
import '../registry.dart';
import 'common.dart';

const String signUpEndpoint = 'POST supabase /auth/v1/signup';
const String tokenEndpoint = 'POST supabase /auth/v1/token';
const String recoverEndpoint = 'POST supabase /auth/v1/recover';
const String updateUserEndpoint = 'PUT supabase /auth/v1/user';
const String linkIdentityEndpoint =
    'POST supabase /auth/v1/user/identities (linkIdentity)';

/// Outcome labels of the sign-in screens' "Sign-in result" branch.
abstract final class SignInOutcomes {
  static const String success = 'Success';
  static const String successGuestPlan = 'Success · guest plan on phone';
  static const String wrongPassword = 'Wrong password';
}

/// Codes of the failed results these handlers give.
abstract final class AuthCodes {
  static const String notReady = 'sign_in_not_ready';
  static const String ageNotConfirmed = 'age_not_confirmed';
  static const String invalidInput = HandlerCodes.invalidInput;
  static const String passwordTooShort = 'password_too_short';
  static const String passwordsDiffer = 'passwords_differ';
  static const String signUpFailed = 'sign_up_failed';
  static const String profileUnavailable = 'profile_unavailable';
  static const String signInFailed = 'sign_in_failed';
  static const String invalidCredentials = 'invalid_credentials';
  static const String accountDeleted = 'account_deleted';
  static const String signInBlocked = 'sign_in_blocked';
  static const String resetFailed = 'reset_failed';
  static const String recoveryExpired = 'recovery_expired';
  static const String linkExpired = 'link_expired';
  static const String linkRefused = 'link_refused';
}

/// The shortest password the design's screens accept ("At least 12
/// characters").
const int minimumPasswordLength = 12;

/// The sign-in flow the handlers use. The app shell sets it; until then
/// every auth submit fails closed.
abstract final class AuthEndpoints {
  static SignInFlow? flow;
}

/// The handlers of the five Supabase Auth submits.
Map<String, EndpointHandler> authHandlers() => {
      signUpEndpoint: _withFlow(_signUp),
      tokenEndpoint: _withFlow(_token),
      recoverEndpoint: _withFlow(_recover),
      updateUserEndpoint: _withFlow(_updatePassword),
      linkIdentityEndpoint: _withFlow(_link),
    };

/// [handlers], each followed by the session check of the sign-in flow.
Map<String, EndpointHandler> withSessionChecks(
  Map<String, EndpointHandler> handlers,
) =>
    {
      for (final MapEntry(key: endpoint, value: handler) in handlers.entries)
        endpoint: (call) async {
          final flow = AuthEndpoints.flow;
          final before = flow?.auth.currentIdentity?.id;
          final result = await handler(call);
          flow?.afterSubmit(endpoint, before, result);
          return result;
        },
    };

EndpointHandler _withFlow(
  Future<TResult> Function(SignInFlow flow, Snapshot s) body,
) =>
    (call) async {
      final flow = AuthEndpoints.flow;
      if (flow == null) return const TResult.failed(AuthCodes.notReady);
      return body(flow, Snapshot(call));
    };

String? _secret(Snapshot s, String key) {
  final value = s.raw(key);
  return value is String && value.isNotEmpty ? value : null;
}

/// `ob_account` "Create account": only after "I'm 18 or older" is ticked.
Future<TResult> _signUp(SignInFlow flow, Snapshot s) async {
  if (TRules.decide('ob.age', s.call.payload) != 'Age confirmed') {
    return const TResult.failed(AuthCodes.ageNotConfirmed);
  }
  final email = s.text('email');
  final password = _secret(s, 'password');
  if (email == null || !email.contains('@') || password == null) {
    return const TResult.failed(AuthCodes.invalidInput);
  }
  if (password.length < minimumPasswordLength) {
    return const TResult.failed(AuthCodes.passwordTooShort);
  }
  switch (await flow.account.signUp(email: email, password: password)) {
    case AccountSignUpOutcome.authenticated:
      await flow.completeSignIn(isNewAccount: true);
      return const TResult.ok();
    case AccountSignUpOutcome.emailConfirmationRequired:
      // The same answer when the email already has an account, so nothing
      // is revealed. The onboarding answers are sent once the link is
      // opened.
      flow.awaitConfirmation(email);
      return const TResult.ok();
    case AccountSignUpOutcome.accountCreatedSignInRequired:
      flow.awaitConfirmation(email);
      return const TResult.failed(AuthCodes.profileUnavailable);
    case null:
      return const TResult.failed(AuthCodes.signUpFailed);
  }
}

/// `auth_signin`, `auth_signin_error` (email sign-in) and `auth_session`
/// (signing in again with the password).
Future<TResult> _token(SignInFlow flow, Snapshot s) async {
  if (s.screen == 'auth_session') return _signInAgain(flow, s);
  final email = s.text('email');
  final password = _secret(s, 'password');
  if (email == null || password == null) {
    return const TResult.failed(AuthCodes.invalidInput);
  }
  // Counted before signing in: only data kept while nobody was signed in.
  final guestData = await flow.hasGuestData();
  if (!await flow.account.signIn(email: email, password: password)) {
    return switch (flow.account.lastSignInFailure) {
      // An unavailable account reads as a wrong password: the screen never
      // says whether an account exists.
      AuthFailureReason.invalidCredentials ||
      AuthFailureReason.accountUnavailable =>
        const TResult.outcome(SignInOutcomes.wrongPassword),
      _ => const TResult.failed(AuthCodes.signInFailed),
    };
  }
  final isNew = flow.takeAwaitingConfirmation(email);
  switch (await flow.completeSignIn(isNewAccount: isNew)) {
    case SignedIn.deletionReissued:
      return const TResult.failed(AuthCodes.accountDeleted);
    case SignedIn.blocked:
      return const TResult.failed(AuthCodes.signInBlocked);
    case SignedIn.failed:
      return const TResult.failed(AuthCodes.signInFailed);
    case SignedIn.done:
      return TResult.outcome(guestData && !isNew
          ? SignInOutcomes.successGuestPlan
          : SignInOutcomes.success);
  }
}

/// `auth_session`: the same account signs in again; never another one.
Future<TResult> _signInAgain(SignInFlow flow, Snapshot s) async {
  final current = flow.auth.currentIdentity?.id;
  final password = _secret(s, 'password');
  if (current == null) return const TResult.failed(HandlerCodes.signInRequired);
  if (password == null) return const TResult.failed(AuthCodes.invalidInput);
  try {
    final identity = await flow.auth.reauthenticate(password: password);
    if (identity.id != current) {
      return const TResult.failed(AuthCodes.invalidCredentials);
    }
  } on AuthFailure catch (error) {
    return TResult.failed(error.reason == AuthFailureReason.invalidCredentials
        ? AuthCodes.invalidCredentials
        : AuthCodes.signInFailed);
  } catch (_) {
    return const TResult.failed(AuthCodes.signInFailed);
  }
  flow.account.adoptSession();
  return const TResult.ok();
}

/// `auth_forgot`: the same answer whether or not the email has an account.
Future<TResult> _recover(SignInFlow flow, Snapshot s) async {
  final email = s.text('email');
  if (email == null || !email.contains('@')) {
    return const TResult.failed(AuthCodes.invalidInput);
  }
  // The new-password screen opens only from the emailed link.
  return await flow.account.requestPasswordReset(email: email)
      ? const TResult.ok()
      : const TResult.failed(AuthCodes.resetFailed);
}

/// `auth_newpass`, opened from the reset link.
Future<TResult> _updatePassword(SignInFlow flow, Snapshot s) async {
  final password = _secret(s, 'new_password');
  final confirm = _secret(s, 'confirm_password');
  if (password == null || confirm == null) {
    return const TResult.failed(AuthCodes.invalidInput);
  }
  if (password != confirm) {
    return const TResult.failed(AuthCodes.passwordsDiffer);
  }
  if (password.length < minimumPasswordLength) {
    return const TResult.failed(AuthCodes.passwordTooShort);
  }
  if (!flow.account.passwordRecoveryPending) {
    return const TResult.failed(AuthCodes.recoveryExpired);
  }
  if (!await flow.account.updateRecoveredPassword(password)) {
    return const TResult.failed(AuthCodes.resetFailed);
  }
  return switch (await flow.completeSignIn(isNewAccount: false)) {
    SignedIn.deletionReissued => const TResult.failed(AuthCodes.accountDeleted),
    SignedIn.blocked => const TResult.failed(AuthCodes.signInBlocked),
    _ => const TResult.ok(),
  };
}

/// `auth_link`: the password of the email account that already uses the
/// provider's email, then the provider identity is linked to it.
Future<TResult> _link(SignInFlow flow, Snapshot s) async {
  final link = flow.pendingLink;
  final password = _secret(s, 'password');
  if (link == null) return const TResult.failed(AuthCodes.linkExpired);
  if (password == null) return const TResult.failed(AuthCodes.invalidInput);
  final signedIn = flow.auth.currentIdentity?.email?.trim().toLowerCase();
  final email = (link.email ?? signedIn)?.trim().toLowerCase();
  if (email == null) return const TResult.failed(AuthCodes.linkExpired);
  // A signed-in member links only to their own account.
  if (signedIn != null && signedIn != email) {
    return const TResult.failed(AuthCodes.linkRefused);
  }
  if (!await flow.account.signIn(email: email, password: password)) {
    return const TResult.failed(AuthCodes.invalidCredentials);
  }
  final linked = await flow.auth.linkIdentity(
    link.provider,
    link.idToken,
    nonce: link.nonce,
    accessToken: link.accessToken,
  );
  flow.pendingLink = null;
  if (linked != AuthOutcome.success) {
    return TResult.failed('link_${linked.name}');
  }
  return switch (await flow.completeSignIn(isNewAccount: false)) {
    SignedIn.deletionReissued => const TResult.failed(AuthCodes.accountDeleted),
    SignedIn.blocked => const TResult.failed(AuthCodes.signInBlocked),
    SignedIn.failed => const TResult.failed(AuthCodes.signInFailed),
    SignedIn.done => const TResult.ok(),
  };
}
