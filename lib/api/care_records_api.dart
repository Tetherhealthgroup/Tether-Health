// Care team (`/v1/care/*`) and health records (`/v1/records/manual`,
// `/v1/records/fhir/*`).
//
// The request bodies of these routes are not in the published contract at
// this revision (the care routes and the records core are still being
// built), so each method takes the body as a JSON object and returns the
// answer as one. Each method still names exactly one route, so the handlers
// and the sandbox already agree on paths and status codes; the bodies get
// typed fields when the contract is published.
import '../backend/backend.dart';
import 'api_result.dart';

/// The care and records routes.
class CareRecordsApi {
  const CareRecordsApi(this._transport);

  final BackendTransport _transport;

  Future<ApiResult<Map<String, Object?>>> _send(
    BackendMethod method,
    String path, {
    Map<String, Object?>? body,
    String? idempotencyKey,
  }) =>
      callBackend(
        _transport,
        BackendRequest(
          service: BackendService.api,
          method: method,
          path: path,
          body: body,
          idempotencyKey: idempotencyKey,
        ),
        (_, json) =>
            json == null ? const <String, Object?>{} : jsonObject(json),
      );

  static String _id(String id) => Uri.encodeComponent(id);

  // Care team.

  /// `POST /v1/care/connections`: redeems a clinic invite code.
  Future<ApiResult<Map<String, Object?>>> redeemConnection(
          Map<String, Object?> body) =>
      _send(BackendMethod.post, '/v1/care/connections', body: body);

  /// `GET /v1/care/connections`.
  Future<ApiResult<Map<String, Object?>>> connections() =>
      _send(BackendMethod.get, '/v1/care/connections');

  /// `POST /v1/care/messages`.
  Future<ApiResult<Map<String, Object?>>> sendMessage(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) =>
      _send(BackendMethod.post, '/v1/care/messages',
          body: body, idempotencyKey: idempotencyKey);

  /// `POST /v1/care/supporters`.
  Future<ApiResult<Map<String, Object?>>> addSupporter(
          Map<String, Object?> body) =>
      _send(BackendMethod.post, '/v1/care/supporters', body: body);

  /// `GET /v1/care/supporters`.
  Future<ApiResult<Map<String, Object?>>> supporters() =>
      _send(BackendMethod.get, '/v1/care/supporters');

  /// `POST /v1/care/summaries`: stores the snapshot the member previewed.
  Future<ApiResult<Map<String, Object?>>> sendSummary(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) =>
      _send(BackendMethod.post, '/v1/care/summaries',
          body: body, idempotencyKey: idempotencyKey);

  /// `POST /v1/care/caregivers`.
  Future<ApiResult<Map<String, Object?>>> addCaregiver(
          Map<String, Object?> body) =>
      _send(BackendMethod.post, '/v1/care/caregivers', body: body);

  /// `POST /v1/care/referrals`.
  Future<ApiResult<Map<String, Object?>>> requestReferral(
          Map<String, Object?> body) =>
      _send(BackendMethod.post, '/v1/care/referrals', body: body);

  // Health records.

  /// `POST /v1/records/manual`: an item the member typed in.
  Future<ApiResult<Map<String, Object?>>> addManualRecord(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) =>
      _send(BackendMethod.post, '/v1/records/manual',
          body: body, idempotencyKey: idempotencyKey);

  /// `GET /v1/records/fhir/sources`.
  Future<ApiResult<Map<String, Object?>>> recordSources() =>
      _send(BackendMethod.get, '/v1/records/fhir/sources');

  /// `POST /v1/records/fhir/accept`: keeps the reviewed items.
  Future<ApiResult<Map<String, Object?>>> acceptRecords(
          Map<String, Object?> body) =>
      _send(BackendMethod.post, '/v1/records/fhir/accept', body: body);

  /// `POST /v1/records/fhir/conflicts`: resolves conflicting items.
  Future<ApiResult<Map<String, Object?>>> resolveRecordConflicts(
          Map<String, Object?> body) =>
      _send(BackendMethod.post, '/v1/records/fhir/conflicts', body: body);

  /// `POST /v1/records/fhir/sources/:id/sync`: fetches new items from a
  /// connected source.
  Future<ApiResult<Map<String, Object?>>> syncRecordSource(String sourceId) =>
      _send(
          BackendMethod.post, '/v1/records/fhir/sources/${_id(sourceId)}/sync');

  /// `DELETE /v1/records/fhir/sources/:id`: disconnects a source.
  Future<ApiResult<Map<String, Object?>>> disconnectRecordSource(
          String sourceId) =>
      _send(BackendMethod.delete, '/v1/records/fhir/sources/${_id(sourceId)}');
}
