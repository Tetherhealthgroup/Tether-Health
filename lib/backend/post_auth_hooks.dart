// Work that runs once right after a member signs up or signs in, such as
// sending the onboarding answers recorded on the phone before the account
// existed (enrolments, then consents, then plans, then events).
import 'package:flutter/foundation.dart';

/// Who just signed in.
@immutable
class PostAuthEvent {
  const PostAuthEvent({required this.accountId, required this.isNewAccount});

  final String accountId;

  /// True right after sign-up; false for a sign-in to an existing account.
  final bool isNewAccount;

  /// Never prints the account ID.
  @override
  String toString() => 'PostAuthEvent(new: $isNewAccount)';
}

/// One post-auth step. Returns normally on success; throws on failure.
typedef PostAuthHook = Future<void> Function(PostAuthEvent event);

/// The post-auth steps, run in the order they were registered.
class PostAuthHooks {
  final List<PostAuthHook> _hooks = <PostAuthHook>[];

  /// Number of registered steps.
  int get length => _hooks.length;

  void register(PostAuthHook hook) => _hooks.add(hook);

  /// Runs every step in registration order, one at a time. A step that
  /// throws stops the steps after it (they may depend on it) and the result
  /// is false; the caller decides whether to retry. Nothing is logged.
  Future<bool> run(PostAuthEvent event) async {
    for (final hook in List<PostAuthHook>.of(_hooks)) {
      try {
        await hook(event);
      } catch (_) {
        return false;
      }
    }
    return true;
  }
}
