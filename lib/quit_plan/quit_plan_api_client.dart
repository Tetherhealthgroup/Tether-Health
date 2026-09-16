import 'dart:convert';

import 'package:http/http.dart' as http;

import 'quit_plan.dart';

class QuitPlanApiException implements Exception {
  const QuitPlanApiException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Quit-plan request failed ($statusCode)';
}

abstract interface class QuitPlanApiClient {
  Future<QuitPlan> getQuitPlan(String accessToken);
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan);
}

class HttpQuitPlanApiClient implements QuitPlanApiClient {
  HttpQuitPlanApiClient({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 20),
  })  : _baseUri = Uri.parse(baseUrl),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) =>
      _send('GET', accessToken, null);

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) =>
      _send('PUT', accessToken, plan.toRequestJson());

  Future<QuitPlan> _send(
    String method,
    String accessToken,
    Map<String, Object?>? body,
  ) async {
    final request = http.Request(method, _baseUri.resolve('/v1/quit-plan'))
      ..headers['authorization'] = 'Bearer $accessToken'
      ..headers['accept'] = 'application/json';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final streamedResponse =
        await _client.send(request).timeout(requestTimeout);
    final response = await http.Response.fromStream(streamedResponse)
        .timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw QuitPlanApiException(response.statusCode);
    }
    return QuitPlan.fromJson(
      jsonDecode(response.body) as Map<String, Object?>,
    );
  }
}

class DisabledQuitPlanApiClient implements QuitPlanApiClient {
  const DisabledQuitPlanApiClient();

  @override
  Future<QuitPlan> getQuitPlan(String accessToken) =>
      Future.error(StateError('Quit-plan service is not configured.'));

  @override
  Future<QuitPlan> putQuitPlan(String accessToken, QuitPlan plan) =>
      Future.error(StateError('Quit-plan service is not configured.'));
}
