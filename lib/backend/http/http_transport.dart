// The http-mode transport: HTTPS requests to the API and the sync service.
//
// Rules for every request:
// - the bearer token comes from the auth backend at send time;
// - event POSTs carry their Idempotency-Key;
// - a 4xx answer becomes its problem code (the API's `code` field, or the
//   last segment of the sync service's problem `type`), or a generic code
//   for its status when the body has none;
// - a 5xx body is never read: it is `server_error`;
// - no body, header or URL is ever logged.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../backend.dart';

/// Sends requests over HTTP(S).
class HttpBackendTransport implements BackendTransport {
  /// [release] requires both base URLs to use HTTPS.
  HttpBackendTransport({
    required Uri apiBaseUrl,
    required Uri syncBaseUrl,
    required Future<String?> Function() accessToken,
    http.Client? client,
    required bool release,
    this.timeout = const Duration(seconds: 20),
  })  : _bases = {
          BackendService.api: _checked(apiBaseUrl, release, 'API_BASE_URL'),
          BackendService.sync: _checked(syncBaseUrl, release, 'SYNC_BASE_URL'),
        },
        _accessToken = accessToken,
        _client = client ?? http.Client();

  final Map<BackendService, Uri> _bases;
  final Future<String?> Function() _accessToken;
  final http.Client _client;

  /// How long one request may take before it counts as unreachable.
  final Duration timeout;

  static Uri _checked(Uri base, bool release, String name) {
    if (!base.hasAuthority || base.host.isEmpty) {
      throw ArgumentError('$name is not an absolute URL');
    }
    if (release && base.scheme != 'https') {
      throw ArgumentError('$name must use https in a release build');
    }
    if (base.scheme != 'https' && base.scheme != 'http') {
      throw ArgumentError('$name must be an http(s) URL');
    }
    return base;
  }

  /// The full URL of [request]: the service base path, then the request
  /// path, then the query.
  Uri urlFor(BackendRequest request) {
    final base = _bases[request.service]!;
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(
      path: '$basePath${request.path}',
      queryParameters: request.query.isEmpty ? null : request.query,
      fragment: null,
    );
  }

  @override
  Future<BackendResponse> send(BackendRequest request) async {
    try {
      final token = await _accessToken();
      final http.Request message =
          http.Request(request.method.wire, urlFor(request))
            ..headers.addAll({
              'accept': 'application/json, application/problem+json',
              if (token != null && token.isNotEmpty)
                'authorization': 'Bearer $token',
              if (request.idempotencyKey != null)
                'idempotency-key': request.idempotencyKey!,
            });
      if (request.body != null) {
        message
          ..headers['content-type'] = 'application/json'
          ..body = jsonEncode(request.body);
      }
      final streamed = await _client.send(message).timeout(timeout);
      final response =
          await http.Response.fromStream(streamed).timeout(timeout);
      return decodeResponse(
          request.service, response.statusCode, response.body);
    } on TimeoutException {
      return const BackendUnreachable();
    } catch (_) {
      // Offline, DNS, TLS, a closed connection, or a body that would not
      // encode: nothing reached the service, or nothing usable came back.
      return const BackendUnreachable();
    }
  }

  /// Turns a status and body into a [BackendResponse]. Public for tests.
  static BackendResponse decodeResponse(
    BackendService service,
    int status,
    String body,
  ) {
    if (status >= 200 && status < 300) {
      if (status == 204 || body.trim().isEmpty) return BackendOk(status);
      try {
        return BackendOk(status, jsonDecode(body));
      } catch (_) {
        // A 2xx that is not JSON is a proxy or captive portal, not the
        // service.
        return const BackendUnreachable();
      }
    }
    if (status >= 500) return BackendProblem(status, BackendCodes.serverError);
    if (status < 400) return BackendProblem(status, 'unexpected_status');
    return BackendProblem(
      status,
      _problemCode(service, status, body),
      positions:
          service == BackendService.sync ? _positions(body) : const <int>[],
    );
  }

  static List<int> _positions(String body) {
    try {
      final json = jsonDecode(body);
      final positions = json is Map ? json['positions'] : null;
      if (positions is! List) return const [];
      return List<int>.unmodifiable([
        for (final p in positions)
          if (p is int && p >= 0) p,
      ]);
    } catch (_) {
      return const [];
    }
  }

  static final RegExp _codeShape = RegExp(r'^[A-Za-z0-9_.-]{1,64}$');

  static String _problemCode(BackendService service, int status, String body) {
    Object? json;
    try {
      json = jsonDecode(body);
    } catch (_) {
      json = null;
    }
    if (json is Map) {
      final code = json['code'];
      if (code is String && _codeShape.hasMatch(code)) return code;
      final type = json['type'];
      if (service == BackendService.sync && type is String) {
        final last = type.split('/').last;
        if (_codeShape.hasMatch(last)) return last;
      }
    }
    return genericCode(status);
  }

  /// The code for a 4xx answer whose body names none.
  static String genericCode(int status) => switch (status) {
        400 => 'bad_request',
        401 => BackendCodes.unauthenticated,
        403 => 'forbidden',
        404 => 'not_found',
        409 => 'conflict',
        413 => 'payload_too_large',
        415 => 'unsupported_media_type',
        422 => 'unprocessable',
        429 => 'rate_limited',
        _ => 'request_rejected',
      };

  /// Releases pooled connections.
  void close() => _client.close();
}
