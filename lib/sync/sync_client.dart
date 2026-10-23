// The client of the sync service: pull and push, over the backend transport
// (http or sandbox alike).
import '../api/api_result.dart';
import '../backend/backend.dart';
import 'sync_models.dart';

/// `POST /v1/sync/pull` and `POST /v1/sync/push`.
class SyncClient {
  const SyncClient(this._transport);

  final BackendTransport _transport;

  /// Bundles changed since [cursor] (everything when null), and the caller's
  /// current programmes.
  Future<ApiResult<PullResult>> pull({int? cursor, List<String>? areas}) =>
      callBackend(
        _transport,
        BackendRequest(
          service: BackendService.sync,
          method: BackendMethod.post,
          path: '/v1/sync/pull',
          body: {'cursor': cursor, if (areas != null) 'areas': areas},
        ),
        (_, json) => PullResult.fromJson(jsonObject(json)),
      );

  /// Sends whole-area bundles. Conflicts are part of a 200 answer; a refusal
  /// of the whole push (area_gone, consent_required, lapse_conflict) is an
  /// [ApiFailure].
  Future<ApiResult<PushResult>> push(
    List<AreaBundle> bundles, {
    int? baseCursor,
  }) =>
      callBackend(
        _transport,
        BackendRequest(
          service: BackendService.sync,
          method: BackendMethod.post,
          path: '/v1/sync/push',
          body: {
            'base_cursor': baseCursor,
            'areas': [for (final b in bundles) b.toPushJson()],
          },
        ),
        (_, json) => PushResult.fromJson(jsonObject(json)),
      );
}

/// The sync-owned spec endpoints and the programme each one writes to.
/// Plans and answers are stored as screen answers of that area; lapses as
/// its lapses.
const Map<String, String> syncEndpointAreas = {
  'PUT /v1/program-data/be/profile': 'be',
  'PUT /v1/program-data/bf/meds': 'bf',
  'PUT /v1/program-data/ca/plan': 'ca',
  'PUT /v1/program-data/ck/profile': 'ck',
  'PUT /v1/program-data/hw/targets': 'hw',
  'PUT /v1/program-data/nu/habit': 'nu',
  'PUT /v1/program-data/re/plan': 're',
  'PUT /v1/program-data/sd/plan': 'sd',
  'PUT /v1/program-data/sd/safety': 'sd',
  'PUT /v1/program-data/sf/plan': 'sf',
  'PUT /v1/program-data/st/range': 'st',
};

/// The lapse endpoint: its area comes from the submitting screen
/// (`bf_slip` → bf, `sf_slip` → sf).
const String syncLapseEndpoint = 'POST /v1/records/lapses';

/// The screen id a plan endpoint stores under (`PUT …/bf/meds` → `meds`).
String? syncScreenIdOf(String endpoint) {
  if (!syncEndpointAreas.containsKey(endpoint)) return null;
  return endpoint.substring(endpoint.lastIndexOf('/') + 1);
}
