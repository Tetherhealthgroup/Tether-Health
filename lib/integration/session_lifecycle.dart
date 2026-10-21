// Ends a member's session in the tether_ui screens.
//
// On sign-out, an account switch, a completed account deletion and an
// expired session, everything the previous member typed or was shown leaves
// memory before anything else can read it, in this order:
//   1. the navigator returns to the entry screen (nothing of theirs stays
//      open);
//   2. the session values are cleared (TSession.clear, which also moves the
//      session epoch on, so late results are dropped);
//   3. cached display values are dropped (AppData.clear);
//   4. the first-run flag is reset;
//   5. on deletion only, the registered cleaners run.
//
// A guest's first sign-in is not an event: the guest's answers are offered
// for merging into the new account.
//
// This is the only file that calls TSession.clear.
import 'dart:async';

import 'package:tether_ui/ui/ui.dart';

import '../auth/account_controller.dart';
import 'data_adapter.dart';

/// Why a session ended.
enum SessionEndReason { signOut, accountSwitch, deletionCompleted, expired }

/// Removes one account's local data after the account is deleted.
typedef DeletionCleaner = Future<void> Function(String accountId);

/// Cleaners that run after an account deletion completes. Starts empty; the
/// outbox, the sync document and Unplug register into it.
class DeletionCleaners {
  final List<DeletionCleaner> _cleaners = <DeletionCleaner>[];

  /// Number of registered cleaners.
  int get length => _cleaners.length;

  void register(DeletionCleaner cleaner) => _cleaners.add(cleaner);

  /// Runs every cleaner, each on its own: one that fails or throws does not
  /// stop the others. Nothing is logged.
  Future<void> runAll(String accountId) async {
    for (final cleaner in List<DeletionCleaner>.of(_cleaners)) {
      try {
        await cleaner(accountId);
      } catch (_) {
        // The deletion receipt flow retries local cleanup; never log here.
      }
    }
  }
}

/// Watches [AccountController] and ends the session on each event.
class SessionLifecycle {
  SessionLifecycle({
    required AccountController account,
    required void Function() resetToEntry,
    required AppData data,
    DeletionCleaners? cleaners,
  })  : _account = account,
        _resetToEntry = resetToEntry,
        _data = data,
        cleaners = cleaners ?? DeletionCleaners();

  final AccountController _account;
  final void Function() _resetToEntry;
  final AppData _data;

  /// Run on deletion only.
  final DeletionCleaners cleaners;

  /// The account signed in when last observed; null for a guest.
  String? _accountId;
  bool _started = false;

  /// Each session end, oldest first (reasons only; for tests).
  final List<SessionEndReason> ended = <SessionEndReason>[];

  /// Starts watching. The current account is the starting point, not an
  /// event.
  void start() {
    if (_started) return;
    _started = true;
    _accountId = _account.accountId;
    _account.addListener(_onAccountChanged);
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    _account.removeListener(_onAccountChanged);
  }

  /// Ends the session because the server no longer accepts it.
  Future<void> onSessionExpired() => _end(SessionEndReason.expired, _accountId);

  void _onAccountChanged() {
    final previous = _accountId;
    final current = _account.accountId;
    if (previous == current) return;
    _accountId = current;
    if (previous == null) return; // a guest's first sign-in
    if (current != null) {
      unawaited(_end(SessionEndReason.accountSwitch, previous));
    } else if (_account.pendingAccountDeletion?.accountId == previous) {
      unawaited(_end(SessionEndReason.deletionCompleted, previous));
    } else {
      unawaited(_end(SessionEndReason.signOut, previous));
    }
  }

  Future<void> _end(SessionEndReason reason, String? accountId) async {
    ended.add(reason);
    try {
      _resetToEntry();
    } catch (_) {
      // Clearing below must run even if the navigator is gone.
    }
    TSession.clear();
    _data.clear();
    TFlow.onboarding = false;
    if (reason == SessionEndReason.deletionCompleted && accountId != null) {
      await cleaners.runAll(accountId);
    }
  }
}
