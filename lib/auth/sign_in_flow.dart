// What happens around a sign-in on the new design's screens, for email and
// for Apple/Google:
// - once a member is signed in, the post-sign-in steps run (a deletion the
//   server never confirmed is sent again first and stops the sign-in; after
//   sign-up, the onboarding answers kept on the phone are sent);
// - an email sign-up that waits for its confirmation link finishes when that
//   account's session appears;
// - after every save, a session that ended on the gateway is passed on to
//   the session lifecycle, a refusal that needs a recent sign-in asks the
//   member to sign in again (never signs them out), and a session the
//   server no longer accepts ends and asks the member to sign in again.
//
// Nothing here logs; no token, password or email leaves this class.
import 'dart:async';

import 'package:tether_ui/router/routes.dart';
import 'package:tether_ui/ui/ui.dart';

import '../backend/backend.dart';
import '../backend/post_auth_hooks.dart';
import 'account_controller.dart';

/// The endpoint whose success ends the account (the deletion).
const String accountDeletionEndpoint = 'DELETE /v1/account/data';

/// Problem codes that concern the session.
abstract final class SessionCodes {
  /// The action needs a recent sign-in; the session itself is fine.
  static const String recentAuthRequired = 'recent_authentication_required';

  /// The token was missing or refused (or, on some routes, not recent).
  static const String unauthenticated = 'unauthenticated';
}

/// What a check of the current session found.
enum SessionProbe {
  /// The server accepts the session.
  alive,

  /// The server refuses the session: it has ended.
  expired,

  /// No answer (offline): nothing is decided.
  unknown,
}

/// How a completed sign-in ended.
enum SignedIn {
  /// Signed in; the post-sign-in steps ran (a refused onboarding commit is
  /// kept on the phone and sent again on the next start).
  done,

  /// The account had a deletion the server never confirmed: it was sent
  /// again and confirmed; the account is gone.
  deletionReissued,

  /// The account has a deletion the server never confirmed and sending it
  /// again failed (for example offline): the member is signed out and does
  /// not continue; the deletion is sent again at the next sign-in.
  blocked,

  /// No session after all.
  failed,
}

/// An Apple or Google identity waiting to be linked to the email account
/// that already uses its email (the `auth_link` screen).
class PendingLink {
  const PendingLink({
    required this.provider,
    required this.idToken,
    this.nonce,
    this.accessToken,
    this.email,
  });

  final IdTokenProvider provider;
  final String idToken;
  final String? nonce;
  final String? accessToken;

  /// The email the provider gave, when it gave one.
  final String? email;

  /// Prints nothing of the identity.
  @override
  String toString() => 'PendingLink()';
}

/// The sign-in state and steps shared by the email handlers and the native
/// sign-in adapter.
class SignInFlow {
  SignInFlow({
    required this.account,
    required this.auth,
    required this.postAuthHooks,
    required Future<bool> Function() guestDataPresent,
    required Future<bool> Function(String accountId) deletionPending,
    required Future<SessionProbe> Function() probeSession,
    void Function(void Function() action)? defer,
  })  : _guestDataPresent = guestDataPresent,
        _deletionPending = deletionPending,
        _probeSession = probeSession,
        _defer = defer ?? ((action) => Timer.run(action));

  final AccountController account;
  final AuthBackend auth;
  final PostAuthHooks postAuthHooks;
  final Future<bool> Function() _guestDataPresent;
  final Future<bool> Function(String accountId) _deletionPending;
  final Future<SessionProbe> Function() _probeSession;

  /// Runs an action after the current save has returned to the screen, so
  /// a session change never turns that save's own result into a failure.
  final void Function(void Function() action) _defer;

  /// Opens a runtime entry (the shell's entry navigator). Null until the
  /// shell starts.
  void Function(String route)? showEntry;

  /// Opens a screen on top of the current one, keeping the member's place
  /// (signing in again for an action that needs a recent sign-in). Null
  /// until the shell starts.
  void Function(String route)? openOnTop;

  /// Ends the session because the server no longer accepts it (the session
  /// lifecycle). Null until the shell starts.
  Future<void> Function()? onSessionExpired;

  /// The provider of the signed-in account when it has no password
  /// (Apple or Google), else null. Set by native sign-in.
  IdTokenProvider? Function()? socialProvider;

  /// The identity waiting for `auth_link`, set by native sign-in.
  PendingLink? pendingLink;

  /// The email of a sign-up that waits for its confirmation link.
  String? _awaitingConfirmation;

  /// Whether this phone holds guest data to offer for merging. Only data
  /// recorded while nobody was signed in counts.
  Future<bool> hasGuestData() async {
    try {
      return await _guestDataPresent();
    } catch (_) {
      return false;
    }
  }

  /// Remembers that [email]'s sign-up waits for its confirmation link.
  void awaitConfirmation(String email) =>
      _awaitingConfirmation = email.trim().toLowerCase();

  /// Whether [email] is the sign-up waiting for confirmation; forgets it.
  bool takeAwaitingConfirmation(String email) {
    final waiting = _awaitingConfirmation;
    if (waiting == null || waiting != email.trim().toLowerCase()) return false;
    _awaitingConfirmation = null;
    return true;
  }

  /// Finishes a sign-up that waited for its confirmation link once that
  /// account's session is on the phone (the member opened the link). Safe
  /// to call any time.
  Future<void> finishConfirmedSignUp() async {
    final waiting = _awaitingConfirmation;
    final email = auth.currentIdentity?.email?.trim().toLowerCase();
    if (waiting == null || email == null || email != waiting) return;
    _awaitingConfirmation = null;
    await completeSignIn(isNewAccount: true);
  }

  /// Runs the post-sign-in steps for the account now signed in on the
  /// gateway. [isNewAccount] is true right after sign-up.
  Future<SignedIn> completeSignIn({required bool isNewAccount}) async {
    final id = auth.currentIdentity?.id;
    if (id == null) return SignedIn.failed;
    account.adoptSession();
    var pending = false;
    try {
      pending = await _deletionPending(id);
    } catch (_) {
      pending = false;
    }
    if (pending) {
      await postAuthHooks
          .run(PostAuthEvent(accountId: id, isNewAccount: false));
      var confirmed = false;
      try {
        confirmed = !await _deletionPending(id);
      } catch (_) {
        confirmed = false;
      }
      _defer(() {
        if (confirmed && auth.currentIdentity == null) {
          account.markAccountDeleted(id);
        } else {
          unawaited(account.signOut());
        }
      });
      return confirmed ? SignedIn.deletionReissued : SignedIn.blocked;
    }
    // A refused step keeps its data on the phone; it is sent again on the
    // next start. The member continues.
    await postAuthHooks.run(
      PostAuthEvent(accountId: id, isNewAccount: isNewAccount),
    );
    return SignedIn.done;
  }

  /// The "sign in again" screen for the signed-in account.
  String signInAgainRoute() => switch (socialProvider?.call()) {
        IdTokenProvider.apple => Routes.authSessionApple,
        IdTokenProvider.google => Routes.authSessionGoogle,
        null => Routes.authSession,
      };

  /// Called after every save with the account signed in before it and the
  /// result. Runs after the save has returned to the screen.
  void afterSubmit(String endpoint, String? accountBefore, TResult result) {
    _defer(() => unawaited(_afterSubmit(endpoint, accountBefore, result)));
  }

  Future<void> _afterSubmit(
    String endpoint,
    String? accountBefore,
    TResult result,
  ) async {
    try {
      await finishConfirmedSignUp();
      if (endpoint == accountDeletionEndpoint &&
          result is TOk &&
          accountBefore != null &&
          auth.currentIdentity == null) {
        account.markAccountDeleted(accountBefore);
        return;
      }
      account.syncSession();
      if (result is! TFailed || !account.isSignedIn) return;
      if (result.code == SessionCodes.recentAuthRequired) {
        openOnTop?.call(signInAgainRoute());
      } else if (result.code == SessionCodes.unauthenticated) {
        // The same code means "not recent enough" on some routes: ask the
        // server whether the session itself still stands before ending it.
        switch (await _probeSession()) {
          case SessionProbe.alive:
            openOnTop?.call(signInAgainRoute());
          case SessionProbe.expired:
            await onSessionExpired?.call();
            showEntry?.call(signInAgainRoute());
          case SessionProbe.unknown:
            break;
        }
      }
    } catch (_) {
      // Never surfaces; the next save checks again.
    }
  }
}
