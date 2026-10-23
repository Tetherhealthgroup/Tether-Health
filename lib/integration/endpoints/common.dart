// Shared pieces of the endpoint handlers: reading a submit's snapshot,
// option codes, and turning service answers into the kit's results.
import 'package:tether_ui/ui/ui.dart';

import '../../api/tether_api.dart';
import '../../backend/backend.dart';
import '../../data/app_services.dart';
import '../data_adapter.dart';
import '../outbox.dart';
import '../registry.dart';
import '../session_lifecycle.dart';
import '../pending_onboarding.dart';
import '../../backend/post_auth_hooks.dart';

/// Codes the handlers give.
abstract final class HandlerCodes {
  /// A value the member typed is not a valid number or date.
  static const String invalidInput = 'invalid_input';

  /// The action needs a signed-in account.
  static const String signInRequired = 'sign_in_required';

  /// The screen was opened without the programme it acts on.
  static const String programUnknown = 'program_unknown';

  /// The device feature is not available in this build.
  static const String deviceUnavailable = 'device_not_available';
}

/// A submit's invalid input.
class InvalidInput implements Exception {
  const InvalidInput();
}

/// What every handler uses.
class HandlerKit {
  HandlerKit({
    required this.services,
    required this.data,
    required this.cleaners,
    required this.postAuthHooks,
    required this.pending,
  });

  final AppServices services;
  final AppData data;
  final DeletionCleaners cleaners;
  final PostAuthHooks postAuthHooks;
  final PendingOnboarding pending;

  TetherApi get api => services.api;
  Outbox get outbox => services.outbox;
  bool get sandbox => services.backend.mode == BackendMode.sandbox;

  /// The programme a programme-scoped screen was opened for. The app sets
  /// [programOfScreen] from its navigator; until then such a screen cannot
  /// say which programme it acts on.
  static String? Function(String screenId)? programOfScreen;

  /// The route argument a screen was opened with (for example a lesson id).
  static String? Function(String screenId)? argumentOfScreen;
}

/// The snapshot of one submit, read by field key.
class Snapshot {
  Snapshot(this.call);

  final EndpointCall call;

  String get screen => call.screenId;

  Object? raw(String key, {String? screen}) =>
      call.payload['${screen ?? this.screen}.$key'];

  bool has(String key, {String? screen}) =>
      call.payload.containsKey('${screen ?? this.screen}.$key');

  /// Trimmed text, or null when empty or absent.
  String? text(String key, {String? screen}) {
    final v = raw(key, screen: screen);
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  /// A typed number, or null when empty. Throws [InvalidInput] when it is
  /// not a number.
  num? number(String key, {String? screen}) {
    final v = raw(key, screen: screen);
    if (v is num) return v;
    final s = text(key, screen: screen);
    if (s == null) return null;
    final n = num.tryParse(s.replaceAll(',', ''));
    if (n == null || n.isNaN || n.isInfinite) throw const InvalidInput();
    return n;
  }

  /// A whole number, or null. Throws [InvalidInput] otherwise.
  int? integer(String key, {String? screen}) {
    final n = number(key, screen: screen);
    if (n == null) return null;
    if (n != n.roundToDouble()) throw const InvalidInput();
    return n.toInt();
  }

  bool? flag(String key, {String? screen}) {
    final v = raw(key, screen: screen);
    return v is bool ? v : null;
  }

  /// The chosen values of a list control (chips, checklist, tiles).
  List<String> list(String key, {String? screen}) {
    final v = raw(key, screen: screen);
    if (v is String) return [v];
    if (v is Iterable) return [for (final x in v) '$x'];
    return const [];
  }

  /// The one chosen value of a single-choice control, or null.
  String? one(String key, {String? screen}) {
    final v = raw(key, screen: screen);
    if (v is String) return v;
    if (v is Iterable && v.isNotEmpty) return '${v.first}';
    return null;
  }

  /// A date the member must give; never defaulted. Throws [InvalidInput]
  /// when it is missing or not a date.
  DateTime requiredDate(String key, {String? screen}) =>
      date(key, screen: screen) ?? (throw const InvalidInput());

  /// A typed date (`YYYY-MM-DD`, or as the date field writes it), or null.
  /// Throws [InvalidInput] when it is not a date.
  DateTime? date(String key, {String? screen}) {
    final s = text(key, screen: screen);
    if (s == null) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    final parsed = parseShownDate(s);
    if (parsed == null) throw const InvalidInput();
    return parsed;
  }
}

const List<String> _months = [
  'jan', 'feb', 'mar', 'apr', 'may', 'jun', //
  'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
];

/// A date as the date field shows it, for example "Oct 12, 2026".
DateTime? parseShownDate(String text) {
  final m = RegExp(r'^([A-Za-z]{3})[a-z]*\.? (\d{1,2}), (\d{4})$')
      .firstMatch(text.trim());
  if (m == null) return null;
  final month = _months.indexOf(m.group(1)!.toLowerCase()) + 1;
  if (month == 0) return null;
  final day = int.parse(m.group(2)!);
  final year = int.parse(m.group(3)!);
  final date = DateTime(year, month, day);
  return date.month == month && date.day == day ? date : null;
}

/// The option code of a spec label (the API's slug): lowercase, every run
/// of other characters one `_`, trimmed, at most 40 characters.
String slug(String label) {
  var s = label.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
  s = s.replaceAll(RegExp(r'^_+|_+$'), '');
  if (s.length > 40) s = s.substring(0, 40).replaceAll(RegExp(r'_+$'), '');
  return s;
}

/// The value of [values] whose wire code is the slug of [label], or null.
T? byLabel<T extends WireValue>(List<T> values, String? label) {
  if (label == null) return null;
  final code = slug(label);
  for (final v in values) {
    if (v.wire == code) return v;
  }
  return null;
}

/// Every value of [values] matching one of [labels]; unknown labels are left
/// out.
Set<T> allByLabel<T extends WireValue>(
        List<T> values, Iterable<String> labels) =>
    {
      for (final l in labels)
        if (byLabel(values, l) case final v?) v,
    };

/// The kit result for a service answer: success is saved; a failure gives
/// its code.
TResult resultOf(ApiResult<Object?> result) => switch (result) {
      ApiSuccess() => const TResult.ok(),
      ApiFailure(:final error) =>
        TResult.failed(error.wire.isEmpty ? error.code.wire : error.wire),
    };

/// The kit result for an outbox answer.
TResult outboxResult(OutboxResult result) => switch (result) {
      OutboxDelivered() => const TResult.ok(),
      OutboxQueued() => const TResult.queued(),
      OutboxFailed(:final code) => TResult.failed(code),
    };

/// Runs [body], turning invalid input into its failure code.
Future<TResult> guarded(Future<TResult> Function() body) async {
  try {
    return await body();
  } on InvalidInput {
    return const TResult.failed(HandlerCodes.invalidInput);
  }
}

/// Builds the request a typed client call would send, without sending it.
/// Used to put typed event bodies in the outbox.
Future<BackendRequest> requestOf(
  Future<Object?> Function(TetherApi api) call,
) async {
  final capture = _Capture();
  await call(TetherApi(capture));
  return capture.request!;
}

class _Capture implements BackendTransport {
  BackendRequest? request;

  @override
  Future<BackendResponse> send(BackendRequest request) async {
    this.request = request;
    return const BackendOk(200, <String, Object?>{});
  }
}
