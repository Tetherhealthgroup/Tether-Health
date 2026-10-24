import 'dart:convert';

import 'package:http/http.dart' as http;

class AccountDataApiException implements Exception {
  const AccountDataApiException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Account data request failed ($statusCode)';
}

class AccountDataExport {
  const AccountDataExport({required this.document});

  factory AccountDataExport.fromJson(Map<String, Object?> json) =>
      AccountDataExport(document: Map.unmodifiable(json));

  final Map<String, Object?> document;

  String get formattedJson =>
      const JsonEncoder.withIndent('  ').convert(document);
}

class AccountDeletionReceipt {
  const AccountDeletionReceipt({
    required this.requestId,
    required this.completedAt,
    required this.profileRowsDeleted,
    required this.quitPlanRowsDeleted,
    required this.avatarObjectsDeleted,
    required this.authIdentityDeleted,
  });

  factory AccountDeletionReceipt.fromJson(Map<String, Object?> json) {
    final deleted = json['deleted'] as Map<String, Object?>;
    return AccountDeletionReceipt(
      requestId: json['requestId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String).toUtc(),
      profileRowsDeleted: deleted['profiles'] as int,
      quitPlanRowsDeleted: deleted['quitPlans'] as int,
      avatarObjectsDeleted: deleted['avatarObjects'] as int,
      authIdentityDeleted: json['authIdentityDeleted'] as bool,
    );
  }

  final String requestId;
  final DateTime completedAt;
  final int profileRowsDeleted;
  final int quitPlanRowsDeleted;
  final int avatarObjectsDeleted;
  final bool authIdentityDeleted;
}

abstract interface class AccountDataApiClient {
  Future<AccountDataExport> exportData(String accessToken);

  Future<AccountDeletionReceipt> deleteAppData(String accessToken);
}

class HttpAccountDataApiClient implements AccountDataApiClient {
  HttpAccountDataApiClient({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 20),
  })  : _baseUri = Uri.parse(baseUrl),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<AccountDataExport> exportData(String accessToken) async {
    final json = await _send('GET', accessToken, '/v1/account/export');
    return AccountDataExport.fromJson(json);
  }

  @override
  Future<AccountDeletionReceipt> deleteAppData(String accessToken) async {
    final json = await _send(
      'DELETE',
      accessToken,
      '/v1/account/data',
      body: const {'confirmation': 'DELETE'},
    );
    return AccountDeletionReceipt.fromJson(json);
  }

  Future<Map<String, Object?>> _send(
    String method,
    String accessToken,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, _baseUri.resolve(path))
      ..headers['authorization'] = 'Bearer $accessToken'
      ..headers['accept'] = 'application/json';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final streamed = await _client.send(request).timeout(requestTimeout);
    final response =
        await http.Response.fromStream(streamed).timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AccountDataApiException(response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, Object?>;
  }
}

class DisabledAccountDataApiClient implements AccountDataApiClient {
  const DisabledAccountDataApiClient();

  @override
  Future<AccountDeletionReceipt> deleteAppData(String accessToken) =>
      Future.error(StateError('Account data service is not configured.'));

  @override
  Future<AccountDataExport> exportData(String accessToken) =>
      Future.error(StateError('Account data service is not configured.'));
}
