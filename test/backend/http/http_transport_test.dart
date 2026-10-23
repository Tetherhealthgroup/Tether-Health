// The http-mode transport: URLs, headers, problem codes, 5xx bodies,
// unreachable services and HTTPS in release.
import 'dart:async';
import 'dart:convert';

import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/backend/http/http_backend.dart';
import 'package:breathefree_patient/backend/http/http_transport.dart';
import 'package:breathefree_patient/backend/http/supabase_auth_backend.dart';
import 'package:breathefree_patient/backend/stub_backend.dart';
import 'package:breathefree_patient/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

HttpBackendTransport _transport(
  MockClientHandler handler, {
  String? token = 'tok',
  bool release = false,
  String api = 'https://api.example.test',
  String sync = 'https://sync.example.test/base/',
}) =>
    HttpBackendTransport(
      apiBaseUrl: Uri.parse(api),
      syncBaseUrl: Uri.parse(sync),
      accessToken: () async => token,
      client: MockClient(handler),
      release: release,
      timeout: const Duration(milliseconds: 200),
    );

BackendRequest _get(String path,
        {BackendService service = BackendService.api}) =>
    BackendRequest(service: service, method: BackendMethod.get, path: path);

void main() {
  test('builds the URL from the service base, path and query', () async {
    final seen = <http.Request>[];
    final t = _transport((r) async {
      seen.add(r);
      return http.Response('{}', 200);
    });
    await t.send(BackendRequest(
      service: BackendService.api,
      method: BackendMethod.get,
      path: '/v1/records/summary',
      query: {'programme': 'hw', 'range': '7d'},
    ));
    await t.send(BackendRequest(
      service: BackendService.sync,
      method: BackendMethod.post,
      path: '/v1/sync/pull',
      body: {'cursor': null},
    ));
    expect(seen[0].url.toString(),
        'https://api.example.test/v1/records/summary?programme=hw&range=7d');
    expect(
        seen[1].url.toString(), 'https://sync.example.test/base/v1/sync/pull');
    expect(seen[1].method, 'POST');
    expect(jsonDecode(seen[1].body), {'cursor': null});
    expect(seen[1].headers['content-type'], startsWith('application/json'));
  });

  test('sends the bearer token and the Idempotency-Key', () async {
    late http.Request seen;
    final t = _transport((r) async {
      seen = r;
      return http.Response('{"submissionId":"x"}', 201);
    });
    final response = await t.send(BackendRequest(
      service: BackendService.api,
      method: BackendMethod.post,
      path: '/v1/program-data/sd/falls',
      body: const <String, Object?>{},
      idempotencyKey: 'abc123',
    ));
    expect(seen.headers['authorization'], 'Bearer tok');
    expect(seen.headers['idempotency-key'], 'abc123');
    expect(response, isA<BackendOk>());
    expect((response as BackendOk).status, 201);
    expect(response.json, {'submissionId': 'x'});
  });

  test('no token means no authorization header', () async {
    late http.Request seen;
    final t = _transport((r) async {
      seen = r;
      return http.Response('', 204);
    }, token: null);
    final response = await t.send(_get('/v1/today'));
    expect(seen.headers.containsKey('authorization'), isFalse);
    expect((response as BackendOk).json, isNull);
  });

  test('an api problem becomes its code', () async {
    final t = _transport((_) async => http.Response(
        jsonEncode({
          'statusCode': 409,
          'error': 'Request rejected',
          'code': 'focus_cap_reached',
          'requestId': 'r',
        }),
        409));
    expect(await t.send(_get('/v1/enrolments')),
        const BackendProblem(409, 'focus_cap_reached'));
  });

  test('a sync problem becomes the last segment of its type, with positions',
      () async {
    final t = _transport((_) async => http.Response(
        jsonEncode({
          'type': 'https://tetherhealthgroup.com/problems/area_gone',
          'title': 'Conflict',
          'status': 409,
          'detail': 'x',
          'positions': [1, 'bad', -1, 2],
        }),
        409));
    final response =
        await t.send(_get('/v1/sync/push', service: BackendService.sync))
            as BackendProblem;
    expect(response.code, 'area_gone');
    expect(response.positions, [1, 2]);
  });

  test('a problem with no code gets the generic code of its status', () async {
    for (final (status, code) in [
      (400, 'bad_request'),
      (401, 'unauthenticated'),
      (403, 'forbidden'),
      (404, 'not_found'),
      (413, 'payload_too_large'),
      (429, 'rate_limited'),
      (418, 'request_rejected'),
    ]) {
      final t = _transport((_) async => http.Response(
          '{"statusCode":$status,"error":"Request rejected"}', status));
      expect(await t.send(_get('/v1/today')), BackendProblem(status, code));
    }
  });

  test('a code that is not a plain token is not trusted', () async {
    final t = _transport(
        (_) async => http.Response(jsonEncode({'code': 'a b <script>'}), 400));
    expect(await t.send(_get('/v1/today')),
        const BackendProblem(400, 'bad_request'));
  });

  test('a 5xx body is never surfaced', () async {
    final t = _transport((_) async => http.Response(
        jsonEncode({'code': 'leaky_detail', 'message': 'patient X'}), 502));
    final response = await t.send(_get('/v1/today'));
    expect(response, const BackendProblem(502, 'server_error'));
    expect(response.toString(), isNot(contains('patient')));
  });

  test('offline, timeouts and non-JSON 2xx answers are unreachable', () async {
    final offline = _transport((_) async => throw http.ClientException('down'));
    expect(await offline.send(_get('/v1/today')), const BackendUnreachable());
    final slow = _transport((_) => Completer<http.Response>().future);
    expect(await slow.send(_get('/v1/today')), const BackendUnreachable());
    final portal =
        _transport((_) async => http.Response('<html>login</html>', 200));
    expect(await portal.send(_get('/v1/today')), const BackendUnreachable());
  });

  test('release builds refuse a base URL that is not https', () {
    expect(
        () => _transport((_) async => http.Response('', 200),
            release: true, api: 'http://api.example.test'),
        throwsArgumentError);
    expect(
        () => _transport((_) async => http.Response('', 200),
            release: true, sync: 'http://sync.example.test'),
        throwsArgumentError);
    expect(() => _transport((_) async => http.Response('', 200), release: true),
        returnsNormally);
    // Debug builds may use a local http server.
    expect(
        () => _transport((_) async => http.Response('', 200),
            api: 'http://localhost:3000'),
        returnsNormally);
    expect(
        () => _transport((_) async => http.Response('', 200),
            api: 'ftp://api.example.test'),
        throwsArgumentError);
  });

  test('the http backend uses the configured URLs and its auth token',
      () async {
    const config = AppConfig(
      apiBaseUrl: 'https://api.example.test',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'sb_publishable_synthetic-placeholder',
      syncBaseUrl: 'https://sync.example.test',
      backend: 'http',
    );
    final backend =
        HttpBackend.withAuth(config, const StubAuthBackend(), release: true);
    expect(backend.mode, BackendMode.http);
    expect(backend.transport.urlFor(_get('/v1/today')).toString(),
        'https://api.example.test/v1/today');
    expect(
        backend.transport
            .urlFor(_get('/v1/sync/pull', service: BackendService.sync))
            .toString(),
        'https://sync.example.test/v1/sync/pull');
    // Building it never touches Supabase.
    expect(() => HttpBackend(config, release: true), returnsNormally);
  });

  test('Supabase auth errors map to outcomes without reading the message', () {
    AuthOutcome of(String? code, [String? status]) =>
        SupabaseAuthBackend.outcomeOf(
            AuthException('private text', code: code, statusCode: status));
    expect(of('email_exists'), AuthOutcome.emailTaken);
    expect(of('identity_already_exists'), AuthOutcome.emailTaken);
    expect(of('email_not_confirmed'), AuthOutcome.needsVerification);
    expect(of('over_request_rate_limit'), AuthOutcome.rateLimited);
    expect(of(null, '429'), AuthOutcome.rateLimited);
    expect(of('invalid_credentials'), AuthOutcome.invalidCredentials);
    expect(of('something_else'), AuthOutcome.error);
  });
}
