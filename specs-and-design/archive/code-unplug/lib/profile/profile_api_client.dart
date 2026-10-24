import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_profile.dart';

class ProfileApiException implements Exception {
  const ProfileApiException(this.statusCode);
  final int statusCode;
  @override
  String toString() => 'Profile request failed ($statusCode)';
}

abstract interface class ProfileApiClient {
  Future<UserProfile> getProfile(String accessToken);
  Future<UserProfile> updateProfile(
      String accessToken, Map<String, Object?> update);
}

class HttpProfileApiClient implements ProfileApiClient {
  HttpProfileApiClient({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 20),
  })  : _baseUri = Uri.parse(baseUrl),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<UserProfile> getProfile(String accessToken) =>
      _send('GET', accessToken, null);

  @override
  Future<UserProfile> updateProfile(
          String accessToken, Map<String, Object?> update) =>
      _send('PATCH', accessToken, update);

  Future<UserProfile> _send(
      String method, String token, Map<String, Object?>? body) async {
    final request = http.Request(method, _baseUri.resolve('/v1/profile'))
      ..headers['authorization'] = 'Bearer $token'
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
      throw ProfileApiException(response.statusCode);
    }
    return UserProfile.fromJson(
        jsonDecode(response.body) as Map<String, Object?>);
  }
}

class DisabledProfileApiClient implements ProfileApiClient {
  const DisabledProfileApiClient();
  @override
  Future<UserProfile> getProfile(String accessToken) =>
      Future.error(StateError('Profile service is not configured.'));
  @override
  Future<UserProfile> updateProfile(
          String accessToken, Map<String, Object?> update) =>
      Future.error(StateError('Profile service is not configured.'));
}
