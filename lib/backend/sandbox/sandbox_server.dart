// The sandbox's in-process server: the API and sync routes the app calls,
// behind the same transport interface as the real services.
import '../backend.dart';
import 'day_window.dart';
import 'sandbox_api.dart' as api;
import 'sandbox_auth.dart';
import 'sandbox_store.dart';
import 'sandbox_sync.dart' as sync;
import 'sandbox_validation.dart';

/// One route: service, method, path pattern (`:name` segments), handler,
/// and whether it changes data.
class SandboxRoute {
  const SandboxRoute(
    this.service,
    this.method,
    this.pattern,
    this.handler, {
    this.writes = false,
  });

  final BackendService service;
  final BackendMethod method;
  final String pattern;
  final api.SandboxAnswer Function(api.SandboxCall call) handler;
  final bool writes;

  /// The path parameters when [path] matches, else null.
  Map<String, String>? match(String path) {
    final want = pattern.split('/');
    final got = path.split('/');
    if (want.length != got.length) return null;
    final params = <String, String>{};
    for (var i = 0; i < want.length; i++) {
      if (want[i].startsWith(':')) {
        if (got[i].isEmpty) return null;
        params[want[i].substring(1)] = Uri.decodeComponent(got[i]);
      } else if (want[i] != got[i]) {
        return null;
      }
    }
    return params;
  }

  /// `METHOD /pattern`, with every parameter written `:id`.
  String get signature =>
      '${method.wire} ${pattern.replaceAll(RegExp(r':\w+'), ':id')}';
}

const _api = BackendService.api;
const _sync = BackendService.sync;
const _get = BackendMethod.get;
const _post = BackendMethod.post;
const _put = BackendMethod.put;
const _patch = BackendMethod.patch;
const _delete = BackendMethod.delete;

/// Every route the sandbox serves.
final List<SandboxRoute> sandboxRoutes = [
  const SandboxRoute(_api, _get, '/v1/profile', api.getProfile),
  const SandboxRoute(_api, _patch, '/v1/profile', api.patchProfile,
      writes: true),
  const SandboxRoute(_api, _get, '/v1/profile/baseline', api.getBaseline),
  const SandboxRoute(_api, _put, '/v1/profile/baseline', api.putBaseline,
      writes: true),
  const SandboxRoute(_api, _get, '/v1/quit-plan', api.getQuitPlan),
  const SandboxRoute(_api, _put, '/v1/quit-plan', api.putQuitPlan,
      writes: true),
  const SandboxRoute(
      _api, _post, '/v1/quit-plan/guest-import', api.importGuestQuitPlan,
      writes: true),
  const SandboxRoute(_api, _get, '/v1/account/export', api.exportAccount),
  const SandboxRoute(_api, _post, '/v1/account/export', api.exportAccount),
  const SandboxRoute(_api, _delete, '/v1/account/data', api.deleteAccountData,
      writes: true),
  const SandboxRoute(_api, _get, '/v1/catalogue/programmes', api.getCatalogue),
  const SandboxRoute(_api, _get, '/v1/app/config', api.getAppConfig),
  const SandboxRoute(_api, _get, '/v1/enrolments', api.listEnrolments),
  const SandboxRoute(_api, _post, '/v1/enrolments', api.createEnrolment,
      writes: true),
  const SandboxRoute(_api, _post, '/v1/enrolments/focus-swap', api.swapFocus,
      writes: true),
  const SandboxRoute(_api, _post, '/v1/enrolments/consents', api.grantConsent,
      writes: true),
  const SandboxRoute(
      _api, _patch, '/v1/enrolments/consents', api.revokeConsentByPurpose,
      writes: true),
  const SandboxRoute(
      _api, _patch, '/v1/enrolments/consents/:id', api.revokeConsentById,
      writes: true),
  const SandboxRoute(_api, _patch, '/v1/enrolments/:id', api.updateEnrolment,
      writes: true),
  const SandboxRoute(_api, _delete, '/v1/enrolments/:id', api.deleteEnrolment,
      writes: true),
  for (final route in api.sandboxEventRoutes)
    SandboxRoute(
        _api, _post, '/v1/program-data/$route', api.eventHandler(route),
        writes: true),
  const SandboxRoute(_api, _post, '/v1/records/check-ins', api.submitCheckIn,
      writes: true),
  const SandboxRoute(_api, _post, '/v1/records/rescues', api.submitRescue,
      writes: true),
  const SandboxRoute(_api, _post, '/v1/records/lessons', api.submitLesson,
      writes: true),
  const SandboxRoute(_api, _get, '/v1/today', api.getToday),
  const SandboxRoute(_api, _get, '/v1/records/summary', api.getSummary),
  const SandboxRoute(
      _api, _get, '/v1/notifications/preferences', api.getPreferences),
  const SandboxRoute(
      _api, _patch, '/v1/notifications/preferences', api.patchPreferences,
      writes: true),
  // Care team: stored, never delivered.
  const SandboxRoute(_api, _post, '/v1/care/connections', api.redeemConnection,
      writes: true),
  SandboxRoute(_api, _get, '/v1/care/connections', api.listCare('connections')),
  SandboxRoute(
      _api, _post, '/v1/care/messages', api.storeCare('messages', keyed: true),
      writes: true),
  SandboxRoute(_api, _post, '/v1/care/supporters', api.storeCare('supporters'),
      writes: true),
  SandboxRoute(_api, _get, '/v1/care/supporters', api.listCare('supporters')),
  SandboxRoute(_api, _post, '/v1/care/summaries',
      api.storeCare('summaries', keyed: true),
      writes: true),
  SandboxRoute(_api, _post, '/v1/care/caregivers', api.storeCare('caregivers'),
      writes: true),
  SandboxRoute(_api, _post, '/v1/care/referrals', api.storeCare('referrals'),
      writes: true),
  // Health records.
  const SandboxRoute(_api, _post, '/v1/records/manual', api.addManualRecord,
      writes: true),
  const SandboxRoute(_api, _get, '/v1/records/fhir/sources', api.listSources),
  const SandboxRoute(_api, _get, '/v1/records/fhir/items', api.listItems),
  SandboxRoute(
      _api, _post, '/v1/records/fhir/accept', api.storeRecords('accepted'),
      writes: true),
  SandboxRoute(
      _api, _post, '/v1/records/fhir/conflicts', api.storeRecords('conflicts'),
      writes: true),
  const SandboxRoute(
      _api, _post, '/v1/records/fhir/sources/:id/sync', api.syncSource,
      writes: true),
  const SandboxRoute(
      _api, _delete, '/v1/records/fhir/sources/:id', api.disconnectSource,
      writes: true),
  // Sync service.
  const SandboxRoute(_sync, _post, '/v1/sync/pull', sync.syncPull),
  const SandboxRoute(_sync, _post, '/v1/sync/push', sync.syncPush,
      writes: true),
];

/// The in-process server.
class SandboxServer implements BackendTransport {
  SandboxServer(
    this._store,
    this._auth, {
    DateTime Function()? clock,
    this.offsetOf = deviceZoneOffset,
  }) : _clock = clock ?? DateTime.now;

  final SandboxStore _store;
  final SandboxAuthBackend _auth;
  final DateTime Function() _clock;
  final ZoneOffset offsetOf;

  /// Paths served without a sign-in.
  static const Set<String> _public = {'/v1/app/config'};

  @override
  Future<BackendResponse> send(BackendRequest request) async {
    try {
      return await _send(request);
    } on SandboxProblem catch (problem) {
      return BackendProblem(problem.status, problem.code,
          positions: problem.positions);
    } on SandboxFullException {
      return const BackendProblem(507, BackendCodes.sandboxFull);
    } catch (_) {
      // A sandbox bug answers like a server failure: no detail.
      return const BackendProblem(500, BackendCodes.serverError);
    }
  }

  Future<BackendResponse> _send(BackendRequest request) async {
    SandboxRoute? route;
    Map<String, String>? params;
    for (final candidate in sandboxRoutes) {
      if (candidate.service != request.service) continue;
      final found = candidate.match(request.path);
      if (found == null) continue;
      if (candidate.method == request.method) {
        route = candidate;
        params = found;
        break;
      }
    }
    final token = await _auth.accessToken();
    if (route == null) {
      // As the server: authentication first, then the unrouted path.
      final signedIn = await _store.read((state) =>
          SandboxAuthBackend.accountFor(state, token, _clock()) != null);
      return signedIn
          ? const BackendProblem(404, 'not_found')
          : BackendProblem(
              401,
              request.service == BackendService.sync
                  ? 'unauthenticated'
                  : BackendCodes.unauthenticated);
    }
    final now = _clock();
    final unauthenticated = request.service == BackendService.sync
        ? 'unauthenticated'
        : BackendCodes.unauthenticated;
    final chosen = route;
    final chosenParams = params!;
    api.SandboxAnswer run(Json state) {
      final account = SandboxAuthBackend.accountFor(state, token, now);
      if (account == null && !_public.contains(chosen.pattern)) {
        throw SandboxProblem(401, unauthenticated);
      }
      return chosen.handler(api.SandboxCall(
        state: state,
        userId: account?.$1 ?? '',
        body: request.body,
        query: request.query,
        params: chosenParams,
        idempotencyKey: request.idempotencyKey,
        now: now,
        recentAuth: account?.$2 ?? false,
        offsetOf: offsetOf,
      ));
    }

    final answer =
        chosen.writes ? await _store.transact(run) : await _store.read(run);
    if (identical(chosen.handler, api.deleteAccountData)) {
      await _store.transact((state) {
        final uid = SandboxAuthBackend.accountFor(state, token, now)?.$1;
        if (uid != null) (state['users']! as Json).remove(uid);
        state['session'] = null;
      });
      _auth.forgetSession();
    }
    return BackendOk(answer.status, answer.json);
  }
}
