/// The client for the sync service in `sync/`.
///
/// Four calls, matching the four the service exposes: pull, push, revoke one
/// programme, erase everything. There is deliberately no `sync()` that does
/// pull-then-push-then-resolve, because resolving a conflict is a decision
/// about somebody's health record and belongs to a layer that can ask them.
library;

import 'dart:convert';

import 'sync_models.dart';
import 'sync_transport.dart';

/// Supplies a bearer token, refreshing it if it has to.
///
/// A function rather than a string: an access token outlives a sync by
/// minutes, not by the lifetime of the app, and a client holding a stale one
/// would fail every call until it was rebuilt.
typedef TokenSource = Future<String?> Function();

class TetherSyncClient {
  TetherSyncClient({
    required Uri baseUrl,
    required TokenSource token,
    SyncTransport? transport,
  })  : _base = baseUrl,
        _token = token,
        _transport = transport ?? IoSyncTransport();

  final Uri _base;
  final TokenSource _token;
  final SyncTransport _transport;

  /// Everything changed since [cursor], or everything if it is null.
  ///
  /// [areas] filters, and the service is careful about what that means: a
  /// filtered pull never advances the cursor past a change it withheld, so
  /// narrowing a pull can cost a round trip but can never lose a write.
  Future<PullResult> pull({int? cursor, List<String>? areas}) async {
    final json = await _send('POST', '/v1/sync/pull', {
      'cursor': cursor,
      if (areas != null) 'areas': areas,
    });
    return PullResult.fromJson(json);
  }

  /// Sends bundles. Returns what was applied and what conflicted.
  ///
  /// A non-empty [PushResult.conflicts] is not an error and does not throw:
  /// some areas were written and some were not, and the caller needs both
  /// lists. Only a failure of the whole request throws.
  Future<PushResult> push(List<AreaBundle> bundles, {int? baseCursor}) async {
    final json = await _send('POST', '/v1/sync/push', {
      'base_cursor': baseCursor,
      'areas': [for (final bundle in bundles) bundle.toPushJson()],
    });
    return PushResult.fromJson(json);
  }

  /// Destroys one programme's data on the server.
  ///
  /// Leaves a tombstone, which is the only way the person's other device finds
  /// out to delete its copy.
  Future<void> revoke(String area) async {
    await _send('DELETE', '/v1/sync/areas/$area', null);
  }

  /// Destroys everything for this account.
  ///
  /// The server-side half of [TetherSession.deleteEverything]. The local half
  /// must still run: this call failing is exactly the case where somebody has
  /// been told their data is gone and it is not.
  Future<void> eraseAccount() async {
    await _send('DELETE', '/v1/sync/account', null);
  }

  void close() => _transport.close();

  Future<Map<String, Object?>> _send(
    String method,
    String path,
    Map<String, Object?>? body,
  ) async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      throw const SyncException(
        status: 401,
        title: 'Not signed in',
        detail: 'No access token was available for the sync request.',
      );
    }

    final response = await _transport.send(
      method: method,
      uri: _base.resolve(path),
      headers: {
        'authorization': 'Bearer $token',
        'accept': 'application/json, application/problem+json',
        if (body != null) 'content-type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );

    if (response.status == 204 || response.body.isEmpty) {
      if (response.status >= 400 || response.status == 0) {
        throw _problem(response);
      }
      return const {};
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      // A body that is not JSON is a proxy or a captive portal answering
      // instead of the service. Reported with the status rather than the
      // body, which could be a login page several kilobytes long.
      throw SyncException(
        status: response.status,
        title: 'The sync service returned something that was not JSON.',
      );
    }

    if (response.status >= 400 || response.status == 0) {
      throw _problem(response, decoded);
    }
    if (decoded is! Map<String, Object?>) {
      throw SyncException(
        status: response.status,
        title: 'The sync service returned a ${decoded.runtimeType}, not an '
            'object.',
      );
    }
    return decoded;
  }

  /// Builds the failure from an RFC 7807 body when there is one.
  ///
  /// Falls back to the status alone rather than surfacing the raw body: the
  /// service is careful never to put PHI in an error, but anything else
  /// answering on that URL has made no such promise.
  static SyncException _problem(SyncResponse response, [Object? decoded]) {
    if (decoded is Map<String, Object?>) {
      return SyncException(
        status: (decoded['status'] as num?)?.toInt() ?? response.status,
        title: (decoded['title'] as String?) ?? 'Sync failed',
        detail: decoded['detail'] as String?,
        type: decoded['type'] as String?,
      );
    }
    return SyncException(
      status: response.status,
      title: response.status == 0
          ? 'Could not reach the sync service'
          : 'Sync failed',
    );
  }
}
