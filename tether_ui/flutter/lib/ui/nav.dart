// Tether Health UI kit — navigation & actions.
//
// Every button in the generated screens calls one of these helpers, so the
// behaviour of an action type (push, sheet, call, submit, branch, auth...)
// is defined in exactly one place. Replace the default [TPlatform], [TApi],
// [TAuth], [TData] (data.dart) and [TNav.branchResolver] implementations
// with real ones at startup, from app code. This package never imports app
// code, network or storage. In release builds the defaults fail closed
// ([TDefaults]); debug builds and tests get the preview defaults.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logic/rules.dart';
import '../router/app_router.dart';
import 'data.dart';
import 'tokens.dart';

/// Default hook implementations. Release builds ([kReleaseMode]) start with
/// fail-closed defaults; debug builds and tests start with the preview ones.
/// The app must install its real [TPlatform], [TApi], [TData], [TAuth] and
/// [TNav.branchResolver] at startup; the release defaults only make a
/// missing install fail safely.
///
/// | Hook | Preview default | Release default |
/// |---|---|---|
/// | [TNav.branchResolver] | [TNav.previewResolver] | [TFailClosedResolver] |
/// | [TApi.instance] | [PreviewApi] | [TUnconfiguredApi]: `failed('not_configured')` |
/// | [TData.instance] | [PreviewData] | [TEmptyData]: null for every key |
/// | [TPlatform.instance] | [PreviewPlatform] | [TInertPlatform]: does nothing, records a code |
abstract final class TDefaults {
  static TBranchResolver branchResolver({bool release = kReleaseMode}) => release ? TFailClosedResolver().resolve : TNav.previewResolver;
  static TApi api({bool release = kReleaseMode}) => release ? const TUnconfiguredApi() : PreviewApi();
  static TData data({bool release = kReleaseMode}) => release ? const TEmptyData() : PreviewData();
  static TPlatform platform({bool release = kReleaseMode}) => release ? TInertPlatform() : PreviewPlatform();

  /// Installs the release defaults (what a release build starts with).
  static void forRelease() => _install(release: true);

  /// Installs the preview defaults (what debug builds and tests start with).
  static void forPreview() => _install(release: false);

  static void _install({required bool release}) {
    TNav.branchResolver = branchResolver(release: release);
    TApi.instance = api(release: release);
    TData.instance = data(release: release);
    TPlatform.instance = platform(release: release);
  }
}

/// Flow context. While the member is in first-run setup, finishing a
/// program's plan returns to the onboarding setup hub instead of the
/// program home.
class TFlow {
  TFlow._();
  static bool onboarding = false;
}

/// Side effects that leave the app. Preview default: snackbar + record (tests
/// read [PreviewPlatform.last]). Release default: [TInertPlatform]. The app
/// must install its real implementation (url_launcher / app_settings), so
/// crisis-call buttons place the call.
abstract class TPlatform {
  static TPlatform instance = TDefaults.platform();
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

/// Release default for [TPlatform]: does nothing and shows nothing, and
/// records [code] (never the number, recipient or URL). It exists only so a
/// missing install fails safely; the app must install a real [TPlatform].
class TInertPlatform implements TPlatform {
  TInertPlatform({this.onCode});

  static const String code = 'platform_not_configured';

  /// Receives [code] for every attempted side effect.
  final void Function(String code)? onCode;

  /// Codes recorded by this platform, oldest first (at most 20).
  final List<String> recorded = <String>[];

  void _rec() {
    if (recorded.length == 20) recorded.removeAt(0);
    recorded.add(code);
    onCode?.call(code);
  }

  @override
  Future<void> call(BuildContext context, String number, String label) async => _rec();
  @override
  Future<void> sms(BuildContext context, String recipient) async => _rec();
  @override
  Future<void> openUrl(BuildContext context, String url) async => _rec();
  @override
  Future<void> openOsSettings(BuildContext context) async => _rec();
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
  String toString() => 'TResult.outcome(<redacted>)'; // the label can be health content
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
/// Preview default: succeeds immediately and records the endpoint. Release
/// default: [TUnconfiguredApi].
///
/// Adapters must make every submit idempotent, for example with an
/// idempotency key that the server uses to keep one record per entry.
/// [TNav.safeSubmit] stops waiting after [TNav.submitTimeout] and reports
/// `failed('timeout')`, but the adapter's request can still complete after
/// that; the member can then tap again after "Couldn’t save", and the retry
/// must not create a second record. [TNav.submit] ignores further taps of a
/// submit only while it is in flight.
abstract class TApi {
  static TApi instance = TDefaults.api();
  Future<TResult> submit(String endpoint, {required String screenId});
}

/// The safety outcomes of the on-device rule that decides the branch after a
/// submit, with the action for each. Generated from the rule's `safety` list
/// in the generator's rules.RULES (generator/rules.py), which is also
/// exported to spec/rules.json. [TNav.submit] runs [rule] when the member
/// taps, before the save is awaited, and again if the save fails; when the
/// result is one of [routes] it runs that action, so a safety screen opens at
/// once, whether or not the save goes through. [pick] reads only the session
/// values: the simulation hooks ([TSim]) never affect it.
class TSafetyRoutes {
  const TSafetyRoutes(this.rule, this.routes);

  /// Rule id in [TRules.decide] (for example `hw.bp`).
  final String rule;

  /// Safety outcome label → its action.
  final Map<String, VoidCallback> routes;

  /// The action for the rule's current result, or null when the result is
  /// not a safety outcome (or the rule cannot decide yet).
  VoidCallback? pick() {
    final decided = TRules.decide(rule, TSession.values);
    return decided == null ? null : routes[decided];
  }
}

/// Release default for [TApi]: every submit fails with [code].
class TUnconfiguredApi implements TApi {
  const TUnconfiguredApi();

  static const String code = 'not_configured';

  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async => const TResult.failed(code);
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

  static TBranchResolver branchResolver = TDefaults.branchResolver();

  /// Code of the [TFailed] result given for an adapter ([TApi]) that throws.
  /// The exception and its message are dropped: they can carry payload.
  static const String adapterErrorCode = 'adapter_error';

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

  /// Longest wait for a save. A save that takes longer gives
  /// `TResult.failed(timeoutCode)`.
  static Duration submitTimeout = const Duration(seconds: 30);

  /// Code of the [TFailed] result given for a save that exceeds
  /// [submitTimeout].
  static const String timeoutCode = 'timeout';

  /// Calls [TApi.instance]. An adapter that throws gives
  /// `TResult.failed(adapterErrorCode)` (the exception is not kept); a save
  /// that takes longer than [submitTimeout] gives `TResult.failed(timeoutCode)`.
  static Future<TResult> safeSubmit(String endpoint, {required String screenId}) async {
    try {
      return await TApi.instance.submit(endpoint, screenId: screenId).timeout(submitTimeout);
    } on TimeoutException {
      return const TResult.failed(timeoutCode);
    } catch (_) {
      return const TResult.failed(adapterErrorCode);
    }
  }

  static const String _saveError = 'Couldn’t save. Your entry is kept on this phone.';

  /// Submits in flight, by (screen id, endpoint). See [submit].
  static final Map<(String, String), _Flight> _inFlight = <(String, String), _Flight>{};

  /// Saves through [TApi.instance] and returns the save's result, or null
  /// when this activation was ignored (see "In flight" below).
  ///
  /// When [safety]'s rule decides a safety outcome at the moment of the tap,
  /// that outcome's action runs at once, before the save is awaited; the save
  /// continues in the background. [then] does not run in this case, whatever
  /// the save's result: the safety action replaces it, so the safety screen
  /// opens exactly once and no confirmation toast from [then] is shown over
  /// it. If the save then fails, the save error is shown while the submitting
  /// screen is still mounted, and nothing navigates again.
  ///
  /// Otherwise, after the save:
  /// - ok / queued: runs [then];
  /// - outcome: runs [then], and the branch inside it may take the label;
  /// - failed (including `not_configured`, `adapter_error` and `timeout`):
  ///   shows the save error and, when [safety]'s rule now decides a safety
  ///   outcome, runs that outcome's action. Otherwise the member stays on
  ///   the screen.
  ///
  /// In flight: from the tap until the submit completes (any result,
  /// including `timeout` and `adapter_error`, and after [then] has run),
  /// further activations of the same submit ([endpoint] from [screenId]) are
  /// ignored: pointer taps and assistive-technology activations alike. The
  /// save is sent once. An ignored activation still checks [safety]: when the
  /// rule now decides a safety outcome and this submit has not run a safety
  /// action yet, that action runs at once and then replaces [then], as
  /// above. A safety screen therefore opens at most once per submit. Once the
  /// submit completes, a new tap submits again (a retry after "Couldn’t
  /// save"); adapters keep retries idempotent ([TApi]).
  static Future<TResult?> submit(BuildContext context, String endpoint, {required String screenId, VoidCallback? then, TSafetyRoutes? safety}) async {
    final key = (screenId, endpoint);
    final pending = _inFlight[key];
    if (pending != null) {
      if (!pending.safetyRan) {
        final safetyNow = safety?.pick();
        if (safetyNow != null) {
          pending.safetyRan = true;
          safetyNow();
        }
      }
      return null;
    }
    final flight = _Flight();
    _inFlight[key] = flight;
    try {
      final safetyNow = safety?.pick();
      if (safetyNow != null) {
        flight.safetyRan = true;
        safetyNow();
      }
      final result = await safeSubmit(endpoint, screenId: screenId);
      if (flight.safetyRan) {
        if (result is TFailed && context.mounted) toast(context, _saveError);
        return result;
      }
      if (!context.mounted) return result;
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
          toast(context, _saveError);
          safety?.pick()?.call();
      }
      return result;
    } finally {
      if (identical(_inFlight[key], flight)) _inFlight.remove(key);
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
      // A sign-in adapter that throws, or answers a label that is not one of
      // this branch's outcomes, decides nothing: the resolver runs.
      try {
        picked = await TAuth.instance!.signIn(provider, labels);
      } catch (_) {
        picked = null;
      }
      if (picked != null && !outcomes.containsKey(picked)) picked = null;
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

/// One submit in flight ([TNav.submit]).
class _Flight {
  /// A safety action has run for this submit, so [TNav.submit] does not run
  /// `then` or another safety action when the save completes.
  bool safetyRan = false;
}
