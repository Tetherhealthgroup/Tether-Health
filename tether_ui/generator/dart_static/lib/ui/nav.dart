// Tether Health UI kit — navigation & actions.
//
// Every button in the generated screens calls one of these helpers, so the
// behaviour of an action type (push, sheet, call, submit, branch, auth...)
// is defined in exactly one place. Replace the default [TPlatform], [TApi],
// [TAuth], [TData] (data.dart) and [TNav.branchResolver] implementations
// with real ones at startup, from app code. This package never imports app
// code, network or storage.
import 'package:flutter/material.dart';

import '../logic/rules.dart';
import '../router/app_router.dart';
import 'tokens.dart';

/// Flow context. While the member is in first-run setup, finishing a
/// program's plan returns to the onboarding setup hub instead of the
/// program home.
class TFlow {
  TFlow._();
  static bool onboarding = false;
}

/// Side effects that leave the app. Default: snackbar + record (tests read
/// [last]). Production: url_launcher / app_settings.
abstract class TPlatform {
  static TPlatform instance = PreviewPlatform();
  Future<void> call(BuildContext context, String number, String label);
  Future<void> sms(BuildContext context, String recipient);
  Future<void> openUrl(BuildContext context, String url);
  Future<void> openOsSettings(BuildContext context);
}

class PreviewPlatform implements TPlatform {
  static String? last;
  void _rec(BuildContext c, String op, String v, String msg) {
    last = '$op:$v';
    TNav.toast(c, msg);
  }

  @override
  Future<void> call(BuildContext context, String number, String label) async => _rec(context, 'call', number, 'Would call $number');
  @override
  Future<void> sms(BuildContext context, String recipient) async => _rec(context, 'sms', recipient, 'Would open Messages: $recipient');
  @override
  Future<void> openUrl(BuildContext context, String url) async => _rec(context, 'external', url, 'Would open $url');
  @override
  Future<void> openOsSettings(BuildContext context) async => _rec(context, 'os_settings', '', 'Would open phone Settings');
}

/// Result of a backend call.
///
/// - [TOk]: saved; the flow continues.
/// - [TQueued]: kept on the phone and sent later (outbox); the flow continues.
/// - [TFailed]: not saved. [TFailed.code] is an error code, never content.
/// - [TOutcome]: saved, and the server decided [TOutcome.label]. The branch
///   that runs next takes that label when no on-device rule decides it.
sealed class TResult {
  const TResult();
  const factory TResult.ok() = TOk;
  const factory TResult.failed(String code) = TFailed;
  const factory TResult.outcome(String label) = TOutcome;
  const factory TResult.queued() = TQueued;
}

final class TOk extends TResult {
  const TOk();
  @override
  bool operator ==(Object other) => other is TOk;
  @override
  int get hashCode => (TOk).hashCode;
  @override
  String toString() => 'TResult.ok()';
}

final class TFailed extends TResult {
  const TFailed(this.code);
  final String code;
  @override
  bool operator ==(Object other) => other is TFailed && other.code == code;
  @override
  int get hashCode => Object.hash(TFailed, code);
  @override
  String toString() => 'TResult.failed($code)';
}

final class TOutcome extends TResult {
  const TOutcome(this.label);
  final String label;
  @override
  bool operator ==(Object other) => other is TOutcome && other.label == label;
  @override
  int get hashCode => Object.hash(TOutcome, label);
  @override
  String toString() => 'TResult.outcome($label)';
}

final class TQueued extends TResult {
  const TQueued();
  @override
  bool operator ==(Object other) => other is TQueued;
  @override
  int get hashCode => (TQueued).hashCode;
  @override
  String toString() => 'TResult.queued()';
}

/// Backend calls named in the spec (e.g. `POST /v1/records/check-ins`).
/// [screenId] is the screen that submits; the adapter reads the payload from
/// the [TSession] keys prefixed "<screenId>." (and any declared extra keys).
/// Default: succeeds immediately and records the endpoint.
abstract class TApi {
  static TApi instance = PreviewApi();
  Future<TResult> submit(String endpoint, {required String screenId});
}

class PreviewApi implements TApi {
  static final List<String> calls = <String>[];
  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async {
    calls.add(endpoint);
    return const TResult.ok();
  }
}

/// Native sign-in. Production: `sign_in_with_apple` (iOS) and
/// `google_sign_in` (Android/iOS), then Supabase `signInWithIdToken`.
/// Return the outcome label the screen expects (e.g. 'Success',
/// 'Cancelled', 'Error', 'Email already has a Tether account').
abstract class TAuth {
  static TAuth? instance;
  Future<String?> signIn(String provider, List<String> outcomes);
}

/// Decides external outcomes when no rule, server outcome, queue or force
/// applies. Returns the picked outcome label, or null to take no outcome.
/// The preview default ([TNav.previewResolver]) asks the developer/tester to
/// pick, like the HTML prototype. Production installs a fail-closed resolver
/// ([TFailClosedResolver]).
typedef TBranchResolver = Future<String?> Function(BuildContext context, String question, List<String> outcomes);

/// Production resolver: a branch that no rule or adapter decided takes no
/// outcome. It shows a generic error and records [code], and never shows the
/// preview chooser. Install it at startup, from app code:
///
///     TNav.branchResolver = TFailClosedResolver(onCode: log).resolve;
///
/// [onCode] receives only [code]: never the question or the outcome labels,
/// which can reveal what the member was doing.
class TFailClosedResolver {
  TFailClosedResolver({this.onCode, this.showError});

  /// Error code recorded for an undecided branch.
  static const String code = 'ui_branch_undecided';

  /// Generic message shown by default. Draft copy, for owner review.
  static const String message = 'Something went wrong. Please try again.';

  /// Receives [code] each time a branch is left undecided.
  final void Function(String code)? onCode;

  /// Shows the error. Default: [TNav.toast] with [message].
  final void Function(BuildContext context)? showError;

  /// Codes recorded by this resolver, oldest first (at most 20).
  final List<String> recorded = <String>[];

  Future<String?> resolve(BuildContext context, String question, List<String> outcomes) async {
    if (recorded.length == 20) recorded.removeAt(0);
    recorded.add(code);
    onCode?.call(code);
    if (context.mounted) {
      final show = showError;
      if (show != null) {
        show(context);
      } else {
        TNav.toast(context, message);
      }
    }
    return null;
  }
}

abstract final class TNav {
  /// The preview chooser ("Preview: …" sheet). Never install it in release.
  static const TBranchResolver previewResolver = _askOutcome;

  static TBranchResolver branchResolver = previewResolver;

  /// Outcome label returned by the submit whose `then` is running, so the
  /// branch inside `then` can take it. Set only while `then` runs.
  static String? _serverOutcome;

  static Future<void> push(BuildContext context, String route) => Navigator.of(context).pushNamed(route);

  static Future<void> replace(BuildContext context, String route) => Navigator.of(context).pushReplacementNamed(route);

  /// Switch tab: clears the stack and shows the tab root.
  static Future<void> tab(BuildContext context, String route) => Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);

  /// Leave a flow entirely (sign out, finish onboarding, deletion done).
  static Future<void> reset(BuildContext context, String route) {
    TFlow.onboarding = false;
    return Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  /// Return to [route] if it is in the stack, otherwise open it.
  static Future<void> popTo(BuildContext context, String route) async {
    final nav = Navigator.of(context);
    Route<dynamic>? stopped;
    nav.popUntil((r) {
      if (r.settings.name == route || r.isFirst) {
        stopped = r;
        return true;
      }
      return false;
    });
    if (stopped?.settings.name != route) await nav.pushNamed(route);
  }

  static Future<void> back(BuildContext context) => Navigator.of(context).maybePop();

  static Future<void> close(BuildContext context) => Navigator.of(context).maybePop();

  static Future<void> sheet(BuildContext context, String route) => Navigator.of(context).pushNamed(route);

  static OverlayEntry? _toast;

  /// Non-blocking confirmation shown at the top of the screen, so it never
  /// covers the primary button. Announced to screen readers.
  static void toast(BuildContext context, String message, {VoidCallback? then}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay != null) {
      _toast?.remove();
      final entry = OverlayEntry(
        builder: (c) => Positioned(
          left: 20,
          right: 20,
          top: MediaQuery.paddingOf(c).top + 8,
          child: IgnorePointer(
            child: Semantics(
              liveRegion: true,
              child: Material(
                color: TColors.teal,
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(message, style: TText.label.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ),
        ),
      );
      _toast = entry;
      overlay.insert(entry);
      Future<void>.delayed(const Duration(milliseconds: 1800), () {
        if (_toast == entry) _toast = null;
        if (entry.mounted) entry.remove();
      });
    }
    if (then != null) then();
  }

  static Future<void> submit(BuildContext context, String endpoint, {required String screenId, VoidCallback? then}) async {
    final result = await TApi.instance.submit(endpoint, screenId: screenId);
    if (!context.mounted) return;
    switch (result) {
      case TOk() || TQueued():
        then?.call();
      case TOutcome(:final label):
        _serverOutcome = label;
        try {
          then?.call();
        } finally {
          _serverOutcome = null;
        }
      case TFailed():
        toast(context, 'Couldn’t save. Your entry is kept on this phone.');
    }
  }

  static Future<void> call(BuildContext context, String number, {String? label}) => TPlatform.instance.call(context, number, label ?? number);

  static Future<void> sms(BuildContext context, String recipient) => TPlatform.instance.sms(context, recipient);

  static Future<void> external(BuildContext context, String url) => TPlatform.instance.openUrl(context, url);

  static Future<void> osSettings(BuildContext context) => TPlatform.instance.openOsSettings(context);

  /// Run the outcome of a decision. Order: forced (tests) → rule / visible
  /// choice (`decide`) → server outcome of the submit that led here →
  /// queued simulation outcome → native auth → resolver.
  static Future<void> branch(BuildContext context, String question, Map<String, VoidCallback> outcomes, {String? decide, String? provider}) async {
    final labels = outcomes.keys.toList();
    final server = _serverOutcome;
    _serverOutcome = null; // one branch only
    String? picked;
    if (TSim.force != null && outcomes.containsKey(TSim.force)) {
      picked = TSim.force;
    } else if (decide != null) {
      picked = TRules.match(TRules.decide(decide, TSession.values), labels);
    }
    if (picked == null && server != null && outcomes.containsKey(server)) {
      picked = server;
    }
    if (picked == null && TSim.queue.isNotEmpty) {
      picked = TRules.match(TSim.queue.removeAt(0), labels);
    }
    if (picked == null && provider != null && TAuth.instance != null) {
      picked = await TAuth.instance!.signIn(provider, labels);
    }
    if (picked == null) {
      if (!context.mounted) return;
      picked = await branchResolver(context, question, labels);
    }
    if (picked == null || !context.mounted) return;
    outcomes[picked]?.call();
  }

  static Future<String?> _askOutcome(BuildContext context, String question, List<String> outcomes) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: TColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TRadius.sheet))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Preview: $question', style: TText.cardTitle),
              const SizedBox(height: 4),
              const Text('Real logic decides this in production.', style: TText.small),
              const SizedBox(height: 12),
              for (final o in outcomes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(onPressed: () => Navigator.of(c).pop(o), child: Text(o)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Route for a tab name (used by the tab bar).
  static String tabRoute(String tab) => AppRouter.tabRoutes[tab]!;
}
