// Tether Health UI kit — navigation & actions.
//
// Every button in the generated screens calls one of these helpers, so the
// behaviour of an action type (push, sheet, call, submit, branch, auth...)
// is defined in exactly one place. Replace the default [TPlatform], [TApi],
// [TAuth], [TDevice], [TData] (data.dart) and [TNav.branchResolver]
// implementations with real ones at startup, from app code. This package never imports app
// code, network or storage. In release builds the defaults fail closed
// ([TDefaults]); debug builds and tests get the preview defaults.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.g.dart';
import '../logic/rules.dart';
import '../router/app_router.dart';
import 'components.dart';
import 'data.dart';
import 'strings.dart';
import 'tokens.dart';

/// Default hook implementations. Release builds ([kReleaseMode]) start with
/// fail-closed defaults; debug builds and tests start with the preview ones.
/// The app must install its real [TPlatform], [TApi], [TData], [TAuth],
/// [TDevice] and [TNav.branchResolver] at startup; the release defaults only
/// make a missing install fail safely.
///
/// | Hook | Preview default | Release default |
/// |---|---|---|
/// | [TNav.branchResolver] | [TNav.previewResolver] | [TFailClosedResolver] |
/// | [TApi.instance] | [PreviewApi] | [TUnconfiguredApi]: `failed('not_configured')` |
/// | [TData.instance] | [PreviewData] | [TEmptyData]: null for every key |
/// | [TPlatform.instance] | [PreviewPlatform] | [TInertPlatform]: does nothing, records a code; calls and texts show [TCallFallback] |
/// | [TDevice.instance] | [PreviewDevice]: no answer, so the preview chooser runs | [TInertDevice]: no answer, records a code |
/// | [TNav.redactQuestion] | false | true: the resolver receives `''` as the question |
abstract final class TDefaults {
  static TBranchResolver branchResolver({bool release = kReleaseMode}) => release ? TFailClosedResolver().resolve : TNav.previewResolver;
  static TApi api({bool release = kReleaseMode}) => release ? const TUnconfiguredApi() : PreviewApi();
  static TData data({bool release = kReleaseMode}) => release ? const TEmptyData() : PreviewData();
  static TPlatform platform({bool release = kReleaseMode}) => release ? TInertPlatform() : PreviewPlatform();
  static TDevice device({bool release = kReleaseMode}) => release ? TInertDevice() : const PreviewDevice();

  /// Installs the release defaults (what a release build starts with).
  static void forRelease() => _install(release: true);

  /// Installs the preview defaults (what debug builds and tests start with).
  static void forPreview() => _install(release: false);

  static void _install({required bool release}) {
    TNav.branchResolver = branchResolver(release: release);
    TApi.instance = api(release: release);
    TData.instance = data(release: release);
    TPlatform.instance = platform(release: release);
    TDevice.instance = device(release: release);
    TNav.redactQuestion = release;
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
///
/// [call] and [sms] return true when the phone app or Messages opened with
/// the number, and false whenever nothing was opened (for example
/// url_launcher's `launchUrl` returning false). They must complete
/// promptly: [TNav.call] and [TNav.sms] wait at most [TNav.platformTimeout].
/// When they return false, throw or time out, [TCallFallback] shows the
/// number to dial.
abstract class TPlatform {
  static TPlatform instance = TDefaults.platform();
  Future<bool> call(BuildContext context, String number, String label);
  Future<bool> sms(BuildContext context, String recipient);
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
  Future<bool> call(BuildContext context, String number, String label) async {
    _rec(context, 'call', number, 'Would call $number');
    return true;
  }

  @override
  Future<bool> sms(BuildContext context, String recipient) async {
    _rec(context, 'sms', recipient, 'Would open Messages: $recipient');
    return true;
  }

  @override
  Future<void> openUrl(BuildContext context, String url) async => _rec(context, 'external', url, 'Would open $url');
  @override
  Future<void> openOsSettings(BuildContext context) async => _rec(context, 'os_settings', '', 'Would open phone Settings');
}

/// Release default for [TPlatform]: does nothing, and records [code] (never
/// the number, recipient or URL). [call] and [sms] return false, so
/// [TNav.call] and [TNav.sms] show [TCallFallback] with the number instead
/// of doing nothing. It exists only so a missing install fails safely; the
/// app must install a real [TPlatform].
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
  Future<bool> call(BuildContext context, String number, String label) async {
    _rec();
    return false;
  }

  @override
  Future<bool> sms(BuildContext context, String recipient) async {
    _rec();
    return false;
  }

  @override
  Future<void> openUrl(BuildContext context, String url) async => _rec();
  @override
  Future<void> openOsSettings(BuildContext context) async => _rec();
}

/// Answers a device or OS question can give ([TAsk.answers]).
enum TAnswer {
  granted,
  grantedNotificationsOff,
  denied,
  unavailable,
  supported,
  unsupported,
  approved,
  cancelled,
  failed,
  ios,
  android,
  allOn,
  notificationsOff,
  missing,
  healthy,
  failing,
}

/// Device and OS questions that decide a branch ([TDevice]), each with its
/// fixed answer set. Mirrors the generator's `ASKS` table (generator/dsl.py);
/// the generator's validator fails when the two differ.
enum TAsk {
  /// The phone's platform.
  platform(<TAnswer>{TAnswer.ios, TAnswer.android}),

  /// Asks for notification permission (OS prompt).
  notificationsRequest(<TAnswer>{TAnswer.granted, TAnswer.denied, TAnswer.unavailable}),

  /// Reads notification permission, for example on return from Settings.
  notificationsCheck(<TAnswer>{TAnswer.granted, TAnswer.denied}),

  /// Asks for health records access (HealthKit / Health Connect prompt).
  healthRecordsRequest(<TAnswer>{TAnswer.granted, TAnswer.denied, TAnswer.unavailable}),

  /// Asks for Screen Time access (iPhone).
  screenTimeRequest(<TAnswer>{TAnswer.granted, TAnswer.denied, TAnswer.unavailable}),

  /// Family Controls authorisation for Unplug, then the notification check (iPhone).
  unplugAuthIos(<TAnswer>{TAnswer.granted, TAnswer.grantedNotificationsOff, TAnswer.denied, TAnswer.unavailable}),

  /// Reads usage access on return from Settings (Android).
  usageAccessSettings(<TAnswer>{TAnswer.granted, TAnswer.denied}),

  /// Reads Unplug's Android permissions on return from Settings.
  unplugAndroidCheck(<TAnswer>{TAnswer.allOn, TAnswer.notificationsOff, TAnswer.missing}),

  /// Reads Unplug's tracking checks.
  unplugTrackingCheck(<TAnswer>{TAnswer.healthy, TAnswer.failing}),

  /// SMART on FHIR sign-in in the system browser.
  smartConnect(<TAnswer>{TAnswer.approved, TAnswer.cancelled, TAnswer.failed}),

  /// Checks that an address is a SMART on FHIR R4 server (HTTPS only, with a
  /// timeout and a size cap). A transport failure is no answer (null), never
  /// [TAnswer.unsupported].
  fhirServerCheck(<TAnswer>{TAnswer.supported, TAnswer.unsupported}),

  /// A reference surface's branch: preview only, never asked in the app.
  reference(<TAnswer>{});

  const TAsk(this.answers);

  /// Every answer this question can give.
  final Set<TAnswer> answers;
}

/// The branch a [TDevice] is asked about: its stable [id] (from the spec,
/// never derived from the screen layout), the question [ask] and the screen
/// that asks. Carries no question text.
@immutable
final class TBranchRef {
  const TBranchRef(this.id, this.ask, this.screenId);

  /// Stable branch id, for example `onboarding.reminders.notifications_request`.
  final String id;
  final TAsk ask;

  /// The screen the branch is on; inputs it needs are the [TSession] keys
  /// prefixed "<screenId>." (for example the FHIR address).
  final String screenId;

  @override
  bool operator ==(Object other) => other is TBranchRef && other.id == id && other.ask == ask && other.screenId == screenId;
  @override
  int get hashCode => Object.hash(id, ask, screenId);
  @override
  String toString() => 'TBranchRef($id, ${ask.name}, $screenId)';
}

/// Answers the device and OS questions that decide branches (R-31):
/// permission prompts, permission checks on return from Settings, SMART
/// sign-in, the FHIR server check and the platform. [TNav.branch] asks it
/// after the native sign-in step ([TAuth]) and before the resolver, and maps
/// the answer to a case through the branch's `when` map.
///
/// Return one of `branch.ask.answers`, or null when there is no answer (not
/// configured, interrupted, a transport failure). Null, an answer outside
/// the set, an answer the branch does not map, or a throw decides nothing:
/// the resolver runs, which fails closed in release builds. Preview default:
/// [PreviewDevice]. Release default: [TInertDevice].
abstract class TDevice {
  static TDevice instance = TDefaults.device();
  Future<TAnswer?> ask(BuildContext context, TBranchRef branch);
}

/// Preview default for [TDevice]: never answers, so the preview chooser
/// picks the outcome as before.
class PreviewDevice implements TDevice {
  const PreviewDevice();
  @override
  Future<TAnswer?> ask(BuildContext context, TBranchRef branch) async => null;
}

/// Release default for [TDevice]: never answers and records [code] (never
/// the branch id or anything the member entered). It exists only so a
/// missing install fails safely; the app must install a real [TDevice].
class TInertDevice implements TDevice {
  TInertDevice({this.onCode});

  static const String code = 'device_not_configured';

  /// Receives [code] for every question asked.
  final void Function(String code)? onCode;

  /// Codes recorded by this device, oldest first (at most 20).
  final List<String> recorded = <String>[];

  @override
  Future<TAnswer?> ask(BuildContext context, TBranchRef branch) async {
    if (recorded.length == 20) recorded.removeAt(0);
    recorded.add(code);
    onCode?.call(code);
    return null;
  }
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

  /// Safety outcome label → its action. In generated screens every action
  /// opens a different screen with a replace or a push (the generator fails
  /// otherwise), so a safety action always leaves the submitting screen.
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
/// Only the sign-up branches on ob_account, which run after the age check,
/// may create an account. Elsewhere, for an Apple ID or Google account with
/// no Tether account, return the '… no Tether account' outcome when the
/// branch has one (it enters the normal sign-up at its start, P-73), and
/// otherwise null.
abstract class TAuth {
  static TAuth? instance;
  Future<String?> signIn(String provider, List<String> outcomes);
}

/// Decides external outcomes when no rule, server outcome, queue, force,
/// sign-in or device answer applies. Returns the picked outcome label, or
/// null to take no outcome. The preview default ([TNav.previewResolver])
/// asks the developer/tester to pick, like the HTML prototype. Production
/// installs a fail-closed resolver ([TFailClosedResolver]) and never decides
/// on [question]: release builds pass `''` ([TNav.redactQuestion]).
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

  /// Generic message shown by default, in English (the kit shows it in the
  /// app language: `kit.generic_error`). Draft copy, for owner review.
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
        TNav.toast(context, TStrings.of(context).kitGenericError);
      }
    }
    return null;
  }
}

/// Route arguments of a screen opened per programme ([TNav.push]).
@immutable
final class TRouteArgs {
  const TRouteArgs({this.program});

  /// Programme id (for example `bf`).
  final String? program;

  @override
  bool operator ==(Object other) => other is TRouteArgs && other.program == program;
  @override
  int get hashCode => program.hashCode;
  @override
  String toString() => 'TRouteArgs(program: $program)';
}

abstract final class TNav {
  /// The preview chooser ("Preview: …" sheet). Never install it in release.
  static const TBranchResolver previewResolver = _askOutcome;

  static TBranchResolver branchResolver = TDefaults.branchResolver();

  static bool _redactQuestion = kReleaseMode;

  /// When true, [branch] passes `''` instead of the question text to
  /// [branchResolver], so no resolver can decide on wording. Always true in
  /// release builds (setting it to false there has no effect); tests and
  /// debug builds start with false, and [TDefaults.forRelease] sets it.
  static bool get redactQuestion => kReleaseMode || _redactQuestion;
  static set redactQuestion(bool value) => _redactQuestion = value;

  /// Code of the [TFailed] result given for an adapter ([TApi]) that throws.
  /// The exception and its message are dropped: they can carry payload.
  static const String adapterErrorCode = 'adapter_error';

  /// Outcome label returned by the submit whose `then` is running, so the
  /// branch inside `then` can take it. Set only while `then` runs.
  static String? _serverOutcome;

  /// Opens [route] on top. While a safety action runs ([submit]), a push
  /// opens nothing when the top route already is [route], so a safety screen
  /// is not stacked on itself; every other push always opens [route].
  ///
  /// [program] is passed to a screen opened per programme (route with
  /// `:program`, for example program settings); it reads it with [programOf].
  static Future<void> push(BuildContext context, String route, {String? program}) {
    final nav = Navigator.of(context);
    if (_runningSafety && _topRoute(nav)?.settings.name == route) return Future<void>.value();
    return nav.pushNamed(route, arguments: program == null ? null : TRouteArgs(program: program));
  }

  /// The programme the screen of [context] was opened for ([push] with
  /// `program`), or null. Bound controls resolve `:program` in their bind
  /// key with it ([TData.resolve]).
  static String? programOf(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is TRouteArgs ? args.program : null;
  }

  /// Replaces the calling screen (the route [context] belongs to) with
  /// [route]. When the calling screen is not the top route, for example a
  /// safety action that runs after the member has opened another screen,
  /// [route] opens on top instead and every screen stays in place: a replace
  /// never removes a screen other than the caller. If the top route already
  /// is [route], nothing opens.
  static Future<void> replace(BuildContext context, String route) {
    final nav = Navigator.of(context);
    if (_isTop(context, ModalRoute.of(context))) return nav.pushReplacementNamed(route);
    if (_topRoute(nav)?.settings.name == route) return Future<void>.value();
    return nav.pushNamed(route);
  }

  /// Whether [route], the route of [context], is still in the navigator and
  /// is its top route. False when [context] is unmounted or has no route.
  static bool _isTop(BuildContext context, ModalRoute<dynamic>? route) => context.mounted && route != null && route.isCurrent;

  /// [nav]'s top route (reads only; nothing is popped).
  static Route<dynamic>? _topRoute(NavigatorState nav) {
    Route<dynamic>? top;
    nav.popUntil((r) {
      top = r;
      return true;
    });
    return top;
  }

  /// Runs the safety [action] for the screen of [context]. Returns the route
  /// it opened (the navigator's new top route, or null when the top route did
  /// not change) and whether the action counts as run.
  ///
  /// An [action] that throws does not stop [submit]: the exception is
  /// reported as [safetyActionErrorCode] ([report]) and the save is still
  /// sent. If it threw after opening a screen, it counts as run (a safety
  /// screen opens at most once per submit). If it threw before the top route
  /// changed, it does not count as run, so [submit] checks the rule again when
  /// the save completes.
  static ({Route<dynamic>? opened, bool ran}) _runSafety(BuildContext context, VoidCallback action) {
    final nav = Navigator.maybeOf(context);
    final before = nav == null ? null : _topRoute(nav);
    var threw = false;
    _runningSafety = true;
    try {
      action();
    } catch (_, stack) {
      threw = true;
      report(safetyActionErrorCode, stack);
    } finally {
      _runningSafety = false;
    }
    final after = nav == null || !nav.mounted ? null : _topRoute(nav);
    final opened = identical(after, before) ? null : after;
    return (opened: opened, ran: !threw || opened != null);
  }

  /// Code reported when a safety action throws ([submit]).
  static const String safetyActionErrorCode = 'safety_action_error';

  /// Code reported when [TPlatform.call] or [TPlatform.sms] throws.
  static const String platformErrorCode = 'platform_error';

  /// Code reported when a call or text failed and no [Overlay] was found to
  /// show [TCallFallback] in.
  static const String fallbackUnavailableCode = 'call_fallback_unavailable';

  /// Code reported when [TPlatform.call] or [TPlatform.sms] has not
  /// completed within [platformTimeout].
  static const String platformTimeoutCode = 'platform_timeout';

  /// Longest wait for [TPlatform.call] or [TPlatform.sms]. Opening the phone
  /// app or Messages normally completes in well under a second; 8 seconds
  /// also leaves room for a slow device or a system confirmation prompt,
  /// while a member in crisis is not left with nothing for long. When it
  /// passes, [TCallFallback] shows and a later result changes nothing.
  static Duration platformTimeout = const Duration(seconds: 8);

  /// Receives every code the UI kit reports through [report]: the error
  /// codes in [errorCodes] and the informational [TCallFallback.shownCode].
  /// It receives only the code, never content, and the stack trace exactly
  /// as the caller passed it (the stack of a caught error, or null).
  ///
  /// Default: [reportToFlutterError], which forwards only [errorCodes] to
  /// [FlutterError.reportError] and drops informational codes, so a shown
  /// fallback is not counted as an error. To receive informational codes
  /// (for example to count fallbacks in telemetry), install a reporter.
  static void Function(String code, StackTrace? stack) reporter = reportToFlutterError;

  /// Codes that report a failure. [reportToFlutterError] forwards only these.
  static const Set<String> errorCodes = {platformErrorCode, platformTimeoutCode, safetyActionErrorCode, fallbackUnavailableCode, TCallFallback.clipboardErrorCode};

  /// Reports [code] through [FlutterError.reportError] as a [TUiError] with
  /// [stack] unchanged, so the app's error reporting ([FlutterError.onError])
  /// receives it, when [code] is one of [errorCodes]. Any other code is
  /// dropped, without printing anything.
  static void reportToFlutterError(String code, StackTrace? stack) {
    if (!errorCodes.contains(code)) return;
    FlutterError.reportError(FlutterErrorDetails(exception: TUiError(code), stack: stack, library: 'tether_ui'));
  }

  /// Reports [code] to [reporter]. Callers pass only a code: the original
  /// exception and its message are dropped, because they can carry payload
  /// or a phone number. A reporter that throws is ignored, so reporting never
  /// stops a fallback or a save.
  static void report(String code, [StackTrace? stack]) {
    try {
      reporter(code, stack);
    } catch (_) {}
  }

  /// True only while [_runSafety] runs a safety action ([push]).
  static bool _runningSafety = false;

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
      overlay.insert(entry, below: TCallFallback._entryIn(overlay)); // never over the call fallback
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

  /// The save failure message in English (shown in the app language:
  /// `kit.save_error`).
  static const String saveError = 'Couldn’t save. Your entry is kept on this phone.';

  /// Code of the [TFailed] result given for a [TQueued] result of a submit
  /// that must not be queued ([submit] with `queueable: false`).
  static const String notQueueableCode = 'not_queueable';

  /// Submits in flight, by (submitting screen's context, screen id,
  /// endpoint). See [submit]. Emptied when [TSession.clear] has run since
  /// the last submit ([_inFlightEpoch]).
  static final Map<(BuildContext, String, String), _Flight> _inFlight = <(BuildContext, String, String), _Flight>{};

  /// [TSession.epoch] when [_inFlight] was last checked.
  static int _inFlightEpoch = TSession.epoch;

  /// Saves through [TApi.instance] and returns the save's result, or null
  /// when this activation was ignored (see "In flight" below).
  ///
  /// The submitting screen is the route of [context] ([ModalRoute.of]),
  /// taken at the tap. A result acts only on that screen: it is "on top"
  /// when that route is still in the navigator and is the top route.
  ///
  /// When [safety]'s rule decides a safety outcome at the moment of the tap,
  /// that outcome's action runs at once, before the save is awaited; the save
  /// continues in the background. [then] does not run in this case, whatever
  /// the save's result: the safety action replaces it, so the safety screen
  /// opens exactly once and no confirmation toast from [then] is shown over
  /// it. If the save then fails, nothing navigates again, and the save error
  /// is shown while the submitting screen is mounted and either it or the
  /// safety screen this submit opened is on top.
  ///
  /// Otherwise, after the save:
  /// - ok / queued: runs [then] when the submitting screen is on top;
  /// - outcome: runs [then] when the submitting screen is on top, and the
  ///   branch inside it may take the label;
  /// - ok / queued / outcome while the submitting screen is mounted but not
  ///   on top: [then] does not run; when [safety]'s rule now decides a
  ///   safety outcome, that outcome's action runs (on top, see below);
  /// - failed (including `not_configured`, `adapter_error` and `timeout`):
  ///   when [safety]'s rule now decides a safety outcome, runs that outcome's
  ///   action whether or not the submitting screen is on top. Shows the save
  ///   error when the submitting screen is on top or when that action opened
  ///   a safety screen. Otherwise the member stays where they are.
  ///
  /// When the submitting screen is mounted but not on top (the member opened
  /// another screen, such as a crisis or breathing screen, while the save was
  /// in flight), [then] does not run, so nothing is popped or replaced and
  /// no confirmation toast appears over the other screen. Unless this
  /// submit already ran a safety action, [safety]'s rule is checked again
  /// whatever the save's result, and a safety outcome's action runs: a
  /// replace or push opens the safety screen on top of the current one
  /// ([replace], [push]), so it never dismisses the screen the member
  /// opened, and nothing opens when the top route already is that safety
  /// screen. The save error is shown only with a safety screen this submit
  /// opened; over any other screen it would read as that screen's result.
  /// The save's result is still returned. When the submitting screen is no
  /// longer mounted, nothing runs after the save.
  ///
  /// In flight: from the tap until the submit completes (any result,
  /// including `timeout` and `adapter_error`, and after [then] has run),
  /// further activations of the same submit ([endpoint] from [screenId]) on
  /// the same mounted screen ([context]) are ignored: pointer taps and
  /// assistive-technology activations alike. The save is sent once. The
  /// guard belongs to that screen instance only: a screen opened again, a
  /// second instance of the screen, or any screen after [TSession.clear]
  /// (sign-out, account switch) starts its own submit, sends its own save
  /// and runs its own safety action, even while an earlier save is still in
  /// flight. An ignored activation still checks [safety]: when the
  /// rule now decides a safety outcome and this submit has not run a safety
  /// action yet, that action runs at once and then replaces [then], as
  /// above. A safety screen therefore opens at most once per submit. Once the
  /// submit completes, a new tap submits again (a retry after "Couldn’t
  /// save"); adapters keep retries idempotent ([TApi]).
  ///
  /// A safety action that throws is reported as [safetyActionErrorCode] and
  /// the save is still sent and handled as above. It counts as run only if
  /// it opened a screen before it threw; otherwise the rule is checked again
  /// as if no safety action had run.
  ///
  /// Not queueable (`queueable: false`, generated for the sign-in and account
  /// endpoints in the generator's endpoint table, spec/endpoints.json): a
  /// [TQueued] result counts as `failed(notQueueableCode)`, and every failure
  /// shows the generic [TFailClosedResolver.message] instead of the save
  /// error, which would wrongly say the entry is kept on this phone.
  static Future<TResult?> submit(BuildContext context, String endpoint, {required String screenId, bool queueable = true, VoidCallback? then, TSafetyRoutes? safety}) async {
    if (_inFlightEpoch != TSession.epoch) {
      _inFlight.clear();
      _inFlightEpoch = TSession.epoch;
    }
    _inFlight.removeWhere((k, _) => !k.$1.mounted);
    final key = (context, screenId, endpoint);
    final pending = _inFlight[key];
    if (pending != null) {
      if (!pending.safetyRan) {
        final safetyNow = safety?.pick();
        if (safetyNow != null) {
          pending.safetyRan = true;
          final run = _runSafety(context, safetyNow);
          pending.safetyRan = run.ran;
          pending.safetyRoute = run.opened;
        }
      }
      return null;
    }
    final flight = _Flight();
    _inFlight[key] = flight;
    final submitting = ModalRoute.of(context);
    final strings = TStrings.of(context);
    try {
      final safetyNow = safety?.pick();
      if (safetyNow != null) {
        flight.safetyRan = true;
        final run = _runSafety(context, safetyNow);
        flight.safetyRan = run.ran;
        flight.safetyRoute = run.opened;
      }
      var result = await safeSubmit(endpoint, screenId: screenId);
      if (!queueable && result is TQueued) result = const TResult.failed(notQueueableCode);
      final failCopy = queueable ? strings.kitSaveError : strings.kitGenericError;
      final onTop = _isTop(context, submitting);
      if (flight.safetyRan) {
        if (result is TFailed && context.mounted && (onTop || (flight.safetyRoute?.isCurrent ?? false))) toast(context, failCopy);
        return result;
      }
      if (!context.mounted) return result;
      if (!onTop && result is! TFailed) {
        final safetyNow = safety?.pick();
        if (safetyNow != null) _runSafety(context, safetyNow);
        return result;
      }
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
          final safetyNow = safety?.pick();
          final opened = safetyNow == null ? null : _runSafety(context, safetyNow).opened;
          if (onTop || opened != null) toast(context, failCopy);
      }
      return result;
    } finally {
      if (identical(_inFlight[key], flight)) _inFlight.remove(key);
    }
  }

  /// Places a call through [TPlatform.instance]. When the platform returns
  /// false or throws, [TCallFallback] shows [number] (see there).
  static Future<void> call(BuildContext context, String number, {String? label}) =>
      _callOrText(context, TFallbackKind.call, number, () => TPlatform.instance.call(context, number, label ?? number));

  /// Opens Messages through [TPlatform.instance]. When the platform returns
  /// false or throws, [TCallFallback] shows [recipient] (see there).
  static Future<void> sms(BuildContext context, String recipient) =>
      _callOrText(context, TFallbackKind.sms, recipient, () => TPlatform.instance.sms(context, recipient));

  static Future<void> _callOrText(BuildContext context, TFallbackKind kind, String value, Future<bool> Function() attempt) async {
    // Taken before the wait, so the fallback still shows when the calling
    // screen has gone by the time the platform answers.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final epoch = TSession.epoch;
    var placed = false;
    try {
      placed = await attempt().timeout(platformTimeout);
    } on TimeoutException {
      report(platformTimeoutCode);
    } catch (_, stack) {
      report(platformErrorCode, stack);
    }
    if (placed) return;
    // A session cleared during the wait (sign-out) belongs to someone else.
    if (TSession.epoch != epoch) return;
    if (overlay == null || !overlay.mounted) {
      report(fallbackUnavailableCode);
      return;
    }
    TCallFallback.show(overlay, kind, value);
  }

  static Future<void> external(BuildContext context, String url) => TPlatform.instance.openUrl(context, url);

  static Future<void> osSettings(BuildContext context) => TPlatform.instance.openOsSettings(context);

  /// Device branches being decided, by (screen's context, branch id). See
  /// [branch]. Emptied when [TSession.clear] has run since the last check.
  static final Set<(BuildContext, String)> _deviceInFlight = <(BuildContext, String)>{};

  /// [TSession.epoch] when [_deviceInFlight] was last checked.
  static int _deviceEpoch = TSession.epoch;

  /// Run the outcome of a decision. Order: forced (tests) → rule / visible
  /// choice (`decide`) → server outcome of the submit that led here →
  /// queued simulation outcome → native sign-in ([TAuth], `provider`) →
  /// device answer ([TDevice], `device`) → resolver ([branchResolver]).
  ///
  /// A device branch names its [TBranchRef] and maps each answer to a case
  /// label in [when], or per platform in [whenByPlatform] (the platform is a
  /// second [TDevice] question, [TAsk.platform]). No answer, an answer outside
  /// `device.ask.answers`, an unmapped answer, or a [TDevice] that throws
  /// decides nothing, and the resolver runs. While a device branch is being
  /// decided, further activations of the same branch on the same screen are
  /// ignored, so a double tap never raises two system prompts; after
  /// [TSession.clear] a new activation is not blocked by an earlier one.
  ///
  /// Route scope: the branch belongs to the route of [context], taken when
  /// it starts. After waiting for [TAuth], [TDevice] or the resolver, the
  /// outcome runs (and the resolver is asked) only while that route is still
  /// the top route; otherwise nothing happens, so a late answer never pops,
  /// replaces or covers a screen the member opened meanwhile (for example the
  /// crisis screen). Decisions that need no wait (forced, rule, server
  /// outcome, simulation) run at once, as before.
  ///
  /// The resolver receives `''` instead of [question] when [redactQuestion]
  /// is true (always in release builds).
  static Future<void> branch(
    BuildContext context,
    String question,
    Map<String, VoidCallback> outcomes, {
    String? decide,
    String? provider,
    TBranchRef? device,
    Map<TAnswer, String> when = const <TAnswer, String>{},
    Map<TAnswer, Map<TAnswer, String>> whenByPlatform = const <TAnswer, Map<TAnswer, String>>{},
  }) async {
    final labels = outcomes.keys.toList();
    final server = _serverOutcome;
    _serverOutcome = null; // one branch only
    final route = context.mounted ? ModalRoute.of(context) : null;
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
    if (picked != null) {
      if (context.mounted) outcomes[picked]?.call();
      return;
    }
    (BuildContext, String)? guard;
    if (device != null) {
      if (_deviceEpoch != TSession.epoch) {
        _deviceInFlight.clear();
        _deviceEpoch = TSession.epoch;
      }
      _deviceInFlight.removeWhere((k) => !k.$1.mounted);
      guard = (context, device.id);
      if (!_deviceInFlight.add(guard)) return; // already being decided
    }
    final epoch = _deviceEpoch;
    try {
      if (provider != null && TAuth.instance != null) {
        // A sign-in adapter that throws, or answers a label that is not one of
        // this branch's outcomes, decides nothing: the resolver runs.
        try {
          picked = await TAuth.instance!.signIn(provider, labels);
        } catch (_) {
          picked = null;
        }
        if (picked != null && !outcomes.containsKey(picked)) picked = null;
        if (!_isTop(context, route)) return;
      }
      if (picked == null && device != null) {
        picked = await _deviceOutcome(context, route, device, when, whenByPlatform, labels);
        if (!_isTop(context, route)) return;
      }
      if (picked == null) {
        if (!_isTop(context, route)) return;
        picked = await branchResolver(context, redactQuestion ? '' : question, labels);
        if (picked == null || !_isTop(context, route)) return;
      }
      outcomes[picked]?.call();
    } finally {
      if (guard != null && _deviceEpoch == epoch) _deviceInFlight.remove(guard);
    }
  }

  /// The case label [TDevice] decides for [ref], or null (see [branch]).
  static Future<String?> _deviceOutcome(BuildContext context, ModalRoute<dynamic>? route, TBranchRef ref, Map<TAnswer, String> when,
      Map<TAnswer, Map<TAnswer, String>> whenByPlatform, List<String> labels) async {
    if (ref.ask.answers.isEmpty) return null; // reference surface: preview only
    final answer = await _askDevice(context, ref);
    if (answer == null) return null;
    var label = when[answer];
    final byPlatform = whenByPlatform[answer];
    if (label == null && byPlatform != null) {
      if (!_isTop(context, route)) return null;
      final platform = await _askDevice(context, TBranchRef(ref.id, TAsk.platform, ref.screenId));
      label = platform == null ? null : byPlatform[platform];
    }
    return label != null && labels.contains(label) ? label : null;
  }

  /// [TDevice.instance]'s answer to [ref], or null when it gives none, gives
  /// an answer outside `ref.ask.answers`, or throws.
  static Future<TAnswer?> _askDevice(BuildContext context, TBranchRef ref) async {
    try {
      final answer = await TDevice.instance.ask(context, ref);
      return answer != null && ref.ask.answers.contains(answer) ? answer : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _askOutcome(BuildContext context, String question, List<String> outcomes) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: TColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TRadius.sheet))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 12),
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

  /// The route that safety action opened, or null when it opened none.
  Route<dynamic>? safetyRoute;
}

/// Error reported by [TNav.reportToFlutterError]: a code only, never content.
final class TUiError implements Exception {
  const TUiError(this.code);
  final String code;
  @override
  String toString() => 'TUiError($code)';
}

/// What a [TNav.call] or [TNav.sms] that could not be placed tried to do.
enum TFallbackKind { call, sms }

/// Every string [TCallFallback] shows or announces, in English. The fallback
/// shows them in the app language (`kit.call_fallback`, `kit.sms_fallback`,
/// `kit.copy`, `kit.copied`, `kit.close`); the English source of those keys
/// is generator/l10n.py KIT, which must match these. Draft copy, pending
/// owner and clinical approval.
abstract final class TCallFallbackCopy {
  /// Message for a call that could not be placed; [number] comes from the
  /// call action.
  static String callMessage(String number) => 'Calling isn’t available here. Dial $number now.';

  /// Message for a text that could not be opened; [recipient] comes from the
  /// text action.
  static String smsMessage(String recipient) => 'Texting isn’t available here. Text $recipient now.';

  /// Button that copies the number or recipient.
  static const String copy = 'Copy';

  /// What the [copy] button reads, and what is announced, for a moment after
  /// copying.
  static const String copied = 'Copied';

  /// Button that removes the fallback.
  static const String close = 'Close';

  static String message(TFallbackKind kind, String value) => switch (kind) {
        TFallbackKind.call => callMessage(value),
        TFallbackKind.sms => smsMessage(value),
      };
}

/// Shown when [TNav.call] or [TNav.sms] could not place the call or open
/// Messages: with [TInertPlatform] (the release default), a [TPlatform] that
/// returns false, throws, or does not answer within [TNav.platformTimeout].
/// It shows the message from [TCallFallbackCopy] and the number or recipient
/// that the action itself passed (never a separate copy of it), selectable
/// and kept on one line, with Copy and Close buttons. It is announced to
/// screen readers, takes input focus, and reports [shownCode].
///
/// It is an entry in the root [Overlay], not a [Navigator] route: popping,
/// replacing or pushing routes (a late submit result, a safety action, a
/// branch outcome, the member's own back) does not remove it, routes pushed
/// later stay below it, and [TNav.toast] inserts toasts below it. It is
/// removed by its Close button, [dismiss], a later fallback (which replaces
/// it), or [TSession.clear] (sign-out, account switch, deletion), so it never
/// shows one member's number to the next.
///
/// It takes at most [maxHeightFraction] of the safe area above the keyboard
/// and scrolls inside beyond that, but never less than the number and the
/// Copy and Close buttons need: when the keyboard leaves less room, only the
/// message shrinks (down to no visible line) and scrolls. While it shows, [inset] is the height it covers from the
/// bottom of the screen; [TScreen] and [TSheet] lay out above it, so every
/// button on the screen beneath can still be scrolled into view and tapped.
abstract final class TCallFallback {
  /// Code reported each time the fallback is shown (no number or content).
  static const String shownCode = 'call_fallback_shown';

  /// Code reported when copying to the clipboard fails.
  static const String clipboardErrorCode = 'clipboard_error';

  /// Largest share of the safe area above the keyboard the fallback covers,
  /// unless the number and the buttons alone need more.
  static const double maxHeightFraction = 0.4;

  /// Height the fallback covers from the bottom of the screen, 0 when none
  /// is shown.
  static final ValueNotifier<double> inset = ValueNotifier<double>(0);

  static OverlayEntry? _entry;
  static OverlayState? _overlay;
  static VoidCallback? _sessionListener;

  /// Whether the fallback listens for [TSession.clear] (only while shown).
  @visibleForTesting
  static bool get debugListensToSession => _sessionListener != null;

  /// Shows the fallback for [kind] with [value] in [overlay], replacing a
  /// fallback already shown. A replaced fallback's [inset] stays until the
  /// new card reports its own height, so the screen beneath does not lay out
  /// uncovered for a frame in between.
  static void show(OverlayState overlay, TFallbackKind kind, String value) {
    _remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _TCallFallbackCard(entry: entry, kind: kind, value: value));
    _entry = entry;
    _overlay = overlay;
    final epoch = TSession.epoch;
    void onSession() {
      if (TSession.epoch != epoch) dismiss();
    }

    _sessionListener = onSession;
    TSession.changes.addListener(onSession);
    overlay.insert(entry);
    TNav.report(shownCode);
  }

  /// Removes the fallback, if one is shown.
  static void dismiss() {
    _remove();
    inset.value = 0;
  }

  /// Removes the shown entry and its session listener; leaves [inset].
  static void _remove() {
    final listener = _sessionListener;
    _sessionListener = null;
    if (listener != null) TSession.changes.removeListener(listener);
    final entry = _entry;
    _entry = null;
    _overlay = null;
    entry?.remove();
  }

  /// The fallback's entry when it is shown in [overlay], else null.
  static OverlayEntry? _entryIn(OverlayState overlay) => identical(_overlay, overlay) && overlay.mounted ? _entry : null;

  static void _setInset(OverlayEntry entry, double value) {
    if (identical(_entry, entry)) inset.value = value;
  }

  /// The card of [entry] has left the tree without [dismiss], for example
  /// because the app or its overlay was rebuilt: the fallback no longer
  /// shows, so nothing stays laid out around it.
  static void _cardGone(OverlayEntry entry) {
    if (!identical(_entry, entry)) return;
    final listener = _sessionListener;
    _sessionListener = null;
    if (listener != null) TSession.changes.removeListener(listener);
    _entry = null;
    _overlay = null;
    inset.value = 0;
  }
}

/// Lays out [TScreen] and [TSheet] content above [TCallFallback] while it
/// shows, the way a screen makes room for the keyboard: a screen gets the
/// covered height as a bottom view inset (its [Scaffold] shrinks), a sheet
/// gets it as bottom padding. [builder] is told whether a fallback covers the
/// screen, so pinned footers can move into the scrolling body. The widget
/// tree keeps the same shape either way, so no state below is lost.
class TFallbackInset extends StatelessWidget {
  const TFallbackInset({super.key, required this.builder, this.sheet = false});
  final Widget Function(BuildContext context, bool covered) builder;
  final bool sheet;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: TCallFallback.inset,
        builder: (context, inset, _) {
          final covered = inset > 0;
          final mq = MediaQuery.of(context);
          final data = !covered
              ? mq
              : mq.copyWith(
                  padding: mq.padding.copyWith(bottom: 0),
                  viewPadding: mq.viewPadding.copyWith(bottom: 0),
                  viewInsets: sheet ? mq.viewInsets : mq.viewInsets.copyWith(bottom: math.max(mq.viewInsets.bottom, inset)),
                );
          return MediaQuery(
            data: data,
            child: Padding(padding: EdgeInsets.only(bottom: sheet && covered ? inset : 0), child: builder(context, covered)),
          );
        },
      );
}

class _TCallFallbackCard extends StatefulWidget {
  const _TCallFallbackCard({required this.entry, required this.kind, required this.value});
  final OverlayEntry entry;
  final TFallbackKind kind;
  final String value;

  @override
  State<_TCallFallbackCard> createState() => _TCallFallbackCardState();
}

class _TCallFallbackCardState extends State<_TCallFallbackCard> {
  final FocusNode _focus = FocusNode(debugLabel: 'call fallback');
  final ScrollController _messageScroll = ScrollController();
  Timer? _copiedTimer;

  /// The message is cut at the top or bottom edge of its scrolling area.
  bool _moreAbove = false, _moreBelow = false;

  void _updateEdges(ScrollMetrics m) {
    final above = m.pixels > m.minScrollExtent + 0.5;
    final below = m.pixels < m.maxScrollExtent - 0.5;
    if (above == _moreAbove && below == _moreBelow) return;
    setState(() {
      _moreAbove = above;
      _moreBelow = below;
    });
  }

  String get _message {
    final s = TStrings.of(context);
    return switch (widget.kind) {
      TFallbackKind.call => s.kitCallFallback(number: widget.value),
      TFallbackKind.sms => s.kitSmsFallback(number: widget.value),
    };
  }

  @override
  void initState() {
    super.initState();
    _messageScroll.addListener(() {
      if (_messageScroll.hasClients) _updateEdges(_messageScroll.position);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      _announce(_message, Assertiveness.assertive);
    });
  }

  @override
  void dispose() {
    final entry = widget.entry;
    // After this frame: the inset cannot change while the tree is locked.
    WidgetsBinding.instance.addPostFrameCallback((_) => TCallFallback._cardGone(entry));
    _copiedTimer?.cancel();
    _messageScroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _announce(String message, Assertiveness assertiveness) =>
      SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context), assertiveness: assertiveness);

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.value));
    } catch (_, stack) {
      TNav.report(TCallFallback.clipboardErrorCode, stack);
      return;
    }
    if (!mounted) return;
    setState(() {
      _copiedTimer?.cancel();
      _copiedTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copiedTimer = null);
      });
    });
    _announce(TStrings.of(context).kitCopied, Assertiveness.polite);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.padding.bottom + mq.viewInsets.bottom + 12;
    final safeHeight = mq.size.height - mq.padding.top - mq.padding.bottom - mq.viewInsets.bottom;
    return Positioned(
      left: TSpace.screen,
      right: TSpace.screen,
      bottom: bottom,
      child: _ReportHeight(
        extra: bottom + 8,
        onInset: (v) => TCallFallback._setInset(widget.entry, v),
        child: _FlooredMaxHeight(
          maxHeight: math.max(0, safeHeight * TCallFallback.maxHeightFraction),
          child: Focus(
            focusNode: _focus,
            child: Semantics(
              key: const ValueKey('call_fallback'),
              container: true,
              liveRegion: true,
              label: _message, // the visible message below is not read twice
              child: Material(
                color: TColors.errorFill,
                elevation: 6,
                borderRadius: BorderRadius.circular(TRadius.card),
                clipBehavior: Clip.antiAlias,
                // The number and the buttons always show; at large text on
                // small screens only the message scrolls.
                child: TCard(variant: TCardVariant.urgent, children: [
                  Flexible(
                    // When the message is cut, a fade at the cut edge and a
                    // scrollbar that stays visible show that it scrolls. It
                    // adds nothing to the card's least height, so the number
                    // and the buttons set the floor of the height cap.
                    child: _NoMinHeight(
                      child: NotificationListener<ScrollMetricsNotification>(
                      onNotification: (n) {
                        _updateEdges(n.metrics);
                        return false;
                      },
                      child: Stack(children: [
                        Scrollbar(
                          controller: _messageScroll,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _messageScroll,
                            child: ExcludeSemantics(child: Text(_message, style: TText.cardTitle.copyWith(color: TColors.errorText))),
                          ),
                        ),
                        if (_moreAbove) const PositionedDirectional(top: 0, start: 0, end: 0, child: _Fade(key: ValueKey('call_fallback.fade_top'), down: false)),
                        if (_moreBelow) const PositionedDirectional(bottom: 0, start: 0, end: 0, child: _Fade(key: ValueKey('call_fallback.fade_bottom'), down: true)),
                      ]),
                    ),
                    ),
                  ),
                  SelectionArea(
                    // Read on its own, after the message.
                    child: Semantics(
                      container: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown, // the number stays whole on one line
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(widget.value, key: const ValueKey('call_fallback.number'), maxLines: 1, softWrap: false, style: TText.stat.copyWith(color: TColors.errorText)),
                      ),
                    ),
                  ),
                  Row(children: [
                    Expanded(
                      child: TButton(
                        key: const ValueKey('call_fallback.copy'),
                        label: _copiedTimer == null ? TStrings.of(context).kitCopy : TStrings.of(context).kitCopied,
                        small: true,
                        variant: TButtonVariant.secondary,
                        onPressed: _copy,
                      ),
                    ),
                    const SizedBox(width: TSpace.s),
                    Expanded(
                      child: TButton(key: const ValueKey('call_fallback.close'), label: TStrings.of(context).kitClose, small: true, variant: TButtonVariant.secondary, onPressed: TCallFallback.dismiss),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays its child out at most [maxHeight] tall, or as tall as the child's
/// least height when that is more, so the child is never squeezed below what
/// it needs (a RenderFlex overflow that would cut off the buttons).
class _FlooredMaxHeight extends SingleChildRenderObjectWidget {
  const _FlooredMaxHeight({required this.maxHeight, super.child});
  final double maxHeight;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFlooredMaxHeight(maxHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderFlooredMaxHeight renderObject) => renderObject.maxHeight = maxHeight;
}

class _RenderFlooredMaxHeight extends RenderProxyBox {
  _RenderFlooredMaxHeight(this._maxHeight);

  double get maxHeight => _maxHeight;
  double _maxHeight;
  set maxHeight(double value) {
    if (value == _maxHeight) return;
    _maxHeight = value;
    markNeedsLayout();
  }

  // As a ConstrainedBox with this maximum height would constrain the child.
  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      BoxConstraints(maxHeight: math.max(_maxHeight, child!.getMinIntrinsicHeight(constraints.maxWidth))).enforce(constraints);

  @override
  Size computeDryLayout(BoxConstraints constraints) => child == null ? constraints.smallest : child!.getDryLayout(_childConstraints(constraints));

  @override
  void performLayout() {
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child!.layout(_childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(child!.size);
  }
}

/// Reports a least height of 0, so a [Flexible] around it does not raise
/// its [Flex]'s least height; layout and paint are its child's.
class _NoMinHeight extends SingleChildRenderObjectWidget {
  const _NoMinHeight({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNoMinHeight();
}

class _RenderNoMinHeight extends RenderProxyBox {
  @override
  double computeMinIntrinsicHeight(double width) => 0;
}

/// Calls [onInset] after layout with its child's height plus [extra] (the
/// space below the card, which grows with the keyboard) whenever that sum
/// changes.
class _ReportHeight extends SingleChildRenderObjectWidget {
  const _ReportHeight({required this.extra, required this.onInset, super.child});
  final double extra;
  final ValueChanged<double> onInset;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderReportHeight(extra, onInset);

  @override
  void updateRenderObject(BuildContext context, _RenderReportHeight renderObject) {
    renderObject
      ..onInset = onInset
      ..extra = extra;
  }
}

class _RenderReportHeight extends RenderProxyBox {
  _RenderReportHeight(this._extra, this.onInset);
  ValueChanged<double> onInset;
  double? _last;

  double get extra => _extra;
  double _extra;
  set extra(double value) {
    if (value == _extra) return;
    _extra = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();
    final v = size.height + _extra;
    if (v == _last) return;
    _last = v;
    WidgetsBinding.instance.addPostFrameCallback((_) => onInset(v));
  }
}

/// Fade from the card's colour to transparent at a cut edge of the message.
class _Fade extends StatelessWidget {
  const _Fade({super.key, required this.down});

  /// True at the bottom edge (fades in towards the bottom).
  final bool down;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: down ? Alignment.topCenter : Alignment.bottomCenter,
              end: down ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [TColors.errorFill.withValues(alpha: 0), TColors.errorFill],
            ),
          ),
        ),
      );
}
