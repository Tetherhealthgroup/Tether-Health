import 'dart:convert';

import 'package:breathefree_patient/account/account_data_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('requests an authenticated account export', () async {
    final client = HttpAccountDataApiClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/account/export');
        expect(request.headers['authorization'], 'Bearer recent-token');
        return http.Response(
          jsonEncode({
            'schemaVersion': '1.0',
            'generatedAt': '2026-09-20T00:00:00Z',
            'profile': {'id': 'user-id'},
            'quitPlan': null,
          }),
          200,
        );
      }),
    );

    final result = await client.exportData('recent-token');
    expect(result.document['schemaVersion'], '1.0');
    expect(result.formattedJson, contains('user-id'));
  });

  test('sends exact confirmation and parses the deletion receipt', () async {
    final client = HttpAccountDataApiClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/v1/account/data');
        expect(jsonDecode(request.body), {'confirmation': 'DELETE'});
        return http.Response(
          jsonEncode({
            'requestId': 'receipt-id',
            'completedAt': '2026-09-20T00:00:00Z',
            'deleted': {
              'profiles': 1,
              'quitPlans': 1,
              'avatarObjects': 0,
            },
            'authIdentityDeleted': true,
            'authIdentityStatus': 'deleted',
          }),
          200,
        );
      }),
    );

    final result = await client.deleteAppData('recent-token');
    expect(result.requestId, 'receipt-id');
    expect(result.profileRowsDeleted, 1);
    expect(result.authIdentityDeleted, isTrue);
  });

  test('retries a transient server failure with the same caller token',
      () async {
    var attempts = 0;
    final client = HttpAccountDataApiClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        attempts++;
        expect(request.headers['authorization'], 'Bearer recent-token');
        if (attempts == 1) return http.Response('', 502);
        return http.Response(
          jsonEncode({
            'requestId': 'retry-receipt-id',
            'completedAt': '2026-09-20T00:00:00Z',
            'deleted': {
              'profiles': 0,
              'quitPlans': 0,
              'avatarObjects': 0,
              'programData': 0,
            },
            'authIdentityDeleted': true,
            'authIdentityStatus': 'deleted',
          }),
          200,
        );
      }),
    );

    final result = await client.deleteAppData('recent-token');

    expect(attempts, 2);
    expect(result.requestId, 'retry-receipt-id');
    expect(result.authIdentityDeleted, isTrue);
  });

  for (final invalidResponse in <String, String>{
    'empty': '',
    'malformed': '{"requestId":',
    'schema-invalid': jsonEncode({
      'requestId': 'invalid-receipt',
      'completedAt': '2026-09-20T00:00:00Z',
      'deleted': {
        'profiles': 'one',
        'quitPlans': 1,
        'avatarObjects': 0,
      },
      'authIdentityDeleted': true,
    }),
  }.entries) {
    test('retries ${invalidResponse.key} successful deletion response once',
        () async {
      var attempts = 0;
      final client = HttpAccountDataApiClient(
        baseUrl: 'https://api.example.test',
        client: MockClient((request) async {
          attempts++;
          expect(request.headers['authorization'], 'Bearer recent-token');
          if (attempts == 1) return http.Response(invalidResponse.value, 200);
          return http.Response(
            jsonEncode({
              'requestId': 'exact-retry-receipt-id',
              'completedAt': '2026-09-20T00:00:00Z',
              'deleted': {
                'profiles': 0,
                'quitPlans': 0,
                'avatarObjects': 0,
                'programData': 0,
              },
              'authIdentityDeleted': true,
            }),
            200,
          );
        }),
      );

      final result = await client.deleteAppData('recent-token');

      expect(attempts, 2);
      expect(result.requestId, 'exact-retry-receipt-id');
    });
  }

  test('stops after one retry when successful responses remain unusable',
      () async {
    var attempts = 0;
    final client = HttpAccountDataApiClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((_) async {
        attempts++;
        return http.Response('', 200);
      }),
    );

    await expectLater(
      client.deleteAppData('recent-token'),
      throwsA(isA<AccountDataResponseException>()),
    );
    expect(attempts, 2);
  });

  test('does not expose response bodies through API exceptions', () async {
    final client = HttpAccountDataApiClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((_) async => http.Response('sensitive payload', 502)),
    );

    await expectLater(
      client.exportData('recent-token'),
      throwsA(
        isA<AccountDataApiException>().having((error) => error.toString(),
            'message', isNot(contains('sensitive'))),
      ),
    );
  });
}
