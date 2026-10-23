// The result of a typed API or sync call: a value, or a typed error.
//
// Errors carry a status and a stable machine code, never a body: a 5xx body
// is never read, and no error text reaches the member or a log.
import 'package:flutter/foundation.dart';

import '../backend/backend.dart';

/// An enum value with its wire form.
abstract interface class WireValue {
  String get wire;
}

/// Every problem code the services and the backends give, by wire value.
/// A code the app does not know is [unknown]; the wire value is still kept in
/// [ApiError.wire].
enum ApiProblemCode {
  // Validation and idempotency (api).
  invalidRequest('invalid_request'),
  idempotencyKeyRequired('idempotency_key_required'),
  idempotencyKeyInvalid('idempotency_key_invalid'),
  idempotencyKeyConflict('idempotency_key_conflict'),
  valueOutOfRange('value_out_of_range'),
  invalidRecord('invalid_record'),
  recordNotAllowed('record_not_allowed'),
  noFocusProgramme('no_focus_programme'),
  // Enrolments and consents (api).
  enrolmentNotFound('enrolment_not_found'),
  alreadyEnrolled('already_enrolled'),
  programmeNotFound('programme_not_found'),
  modeNotAllowed('mode_not_allowed'),
  focusCapReached('focus_cap_reached'),
  enrolmentConflict('enrolment_conflict'),
  enrolmentLeft('enrolment_left'),
  accountDeletionInProgress('account_deletion_in_progress'),
  coreConsentRequired('core_consent_required'),
  consentAlreadyGranted('consent_already_granted'),
  consentNotFound('consent_not_found'),
  consentAlreadyRevoked('consent_already_revoked'),
  consentSuperseded('consent_superseded'),
  consentNotPermitted('consent_not_permitted'),
  consentDocumentUnavailable('consent_document_unavailable'),
  consentVersionUnchanged('consent_version_unchanged'),
  consentConflictRetry('consent_conflict_retry'),
  consentRecipientRequired('consent_recipient_required'),
  consentRecipientInvalid('consent_recipient_invalid'),
  focusSwapInvalid('focus_swap_invalid'),
  sharingNotAvailable('sharing_not_available'),
  confirmationRequired('confirmation_required'),
  recentAuthenticationRequired('recent_authentication_required'),
  // Sync service.
  areaGone('area_gone'),
  consentRequired('consent_required'),
  lapseConflict('lapse_conflict'),
  unknownCursor('unknown-cursor'),
  syncInvalidRequest('invalid-request'),
  // Generic, by status, when the body has no code.
  badRequest('bad_request'),
  unauthenticated(BackendCodes.unauthenticated),
  forbidden('forbidden'),
  notFound('not_found'),
  conflict('conflict'),
  payloadTooLarge('payload_too_large'),
  unsupportedMediaType('unsupported_media_type'),
  unprocessable('unprocessable'),
  rateLimited('rate_limited'),
  // From the backends themselves.
  serverError(BackendCodes.serverError),
  backendNotReady(BackendCodes.notReady),
  sandboxFull(BackendCodes.sandboxFull),
  unreachable('unreachable'),
  invalidResponse('invalid_response'),
  unknown('');

  const ApiProblemCode(this.wire);

  /// The code as the service writes it.
  final String wire;

  static final Map<String, ApiProblemCode> _byWire = {
    for (final code in values)
      if (code.wire.isNotEmpty) code.wire: code,
  };

  /// The code for [wire], or [unknown].
  static ApiProblemCode fromWire(String wire) => _byWire[wire] ?? unknown;
}

/// A failed call.
@immutable
class ApiError {
  const ApiError(
    this.status,
    this.code, [
    String? wire,
    this.positions = const [],
  ]) : wire = wire ?? '';

  /// From a backend problem.
  factory ApiError.fromProblem(BackendProblem problem) => ApiError(
        problem.status,
        ApiProblemCode.fromWire(problem.code),
        problem.code,
        problem.positions,
      );

  /// Sync push refusals: the positions of the refused bundles.
  final List<int> positions;

  /// No answer from the service.
  static const ApiError unreachable =
      ApiError(0, ApiProblemCode.unreachable, 'unreachable');

  /// A 2xx answer whose body is not the documented shape.
  static ApiError invalidResponse(int status) =>
      ApiError(status, ApiProblemCode.invalidResponse, 'invalid_response');

  /// The HTTP status; 0 when the service was not reached.
  final int status;

  final ApiProblemCode code;

  /// The code exactly as the service wrote it (for a code the app does not
  /// know yet).
  final String wire;

  /// The service was not reached, or answered that it is busy or failing:
  /// the same request may succeed later, unchanged.
  bool get isRetryable =>
      code == ApiProblemCode.unreachable ||
      status == 429 ||
      (status >= 500 && code != ApiProblemCode.sandboxFull) ||
      code == ApiProblemCode.backendNotReady;

  /// The access token was missing, expired or refused: the session is over.
  /// Not for [needsRecentAuth], where the session is fine but the action
  /// needs a fresh sign-in.
  bool get isAuthFailure =>
      status == 401 && code != ApiProblemCode.recentAuthenticationRequired;

  /// The action needs a recent sign-in (ask for the password again; never
  /// sign out).
  bool get needsRecentAuth =>
      code == ApiProblemCode.recentAuthenticationRequired;

  @override
  bool operator ==(Object other) =>
      other is ApiError &&
      other.status == status &&
      other.code == code &&
      other.wire == wire;

  @override
  int get hashCode => Object.hash(status, code, wire);

  @override
  String toString() => 'ApiError($status, ${code.wire})';
}

/// A value, or an [ApiError].
sealed class ApiResult<T> {
  const ApiResult();

  /// The value, or null on failure.
  T? get valueOrNull => switch (this) {
        ApiSuccess<T>(:final value) => value,
        ApiFailure<T>() => null,
      };

  /// The error, or null on success.
  ApiError? get errorOrNull => switch (this) {
        ApiSuccess<T>() => null,
        ApiFailure<T>(:final error) => error,
      };

  bool get isSuccess => this is ApiSuccess<T>;
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.value);

  final T value;

  /// Never prints the value: it may be health content.
  @override
  String toString() => 'ApiSuccess()';
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error);

  final ApiError error;

  @override
  String toString() => 'ApiFailure($error)';
}

/// Thrown by a response parser for a body that is not the documented shape.
class ApiShapeException implements Exception {
  const ApiShapeException();
}

/// Sends [request] on [transport] and parses a 2xx body with [parse].
/// Never throws.
Future<ApiResult<T>> callBackend<T>(
  BackendTransport transport,
  BackendRequest request,
  T Function(int status, Object? json) parse,
) async {
  final BackendResponse response;
  try {
    response = await transport.send(request);
  } catch (_) {
    return const ApiFailure(ApiError.unreachable);
  }
  switch (response) {
    case BackendOk(:final status, :final json):
      try {
        return ApiSuccess(parse(status, json));
      } catch (_) {
        return ApiFailure(ApiError.invalidResponse(status));
      }
    case final BackendProblem problem:
      return ApiFailure(ApiError.fromProblem(problem));
    case BackendUnreachable():
      return const ApiFailure(ApiError.unreachable);
  }
}

/// Reads [json] as a JSON object or throws [ApiShapeException].
Map<String, Object?> jsonObject(Object? json) {
  if (json is Map<String, Object?>) return json;
  if (json is Map) {
    return {
      for (final entry in json.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }
  throw const ApiShapeException();
}

/// Reads [json] as a JSON array of objects or throws [ApiShapeException].
List<Map<String, Object?>> jsonObjects(Object? json) {
  if (json is! List) throw const ApiShapeException();
  return [for (final item in json) jsonObject(item)];
}

/// Reads field [key] of [json] as a [T] or throws [ApiShapeException].
T field<T>(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is T) return value;
  throw const ApiShapeException();
}

/// The wire form of an instant: UTC with a `Z` offset.
String wireTime(DateTime time) => time.toUtc().toIso8601String();

/// The wire form of a calendar date: `YYYY-MM-DD` of [date]'s own fields.
String wireDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
