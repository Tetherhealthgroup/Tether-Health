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
            'authIdentityDeleted': false,
            'authIdentityStatus': 'external-action-required',
          }),
          200,
        );
      }),
    );

    final result = await client.deleteAppData('recent-token');
    expect(result.requestId, 'receipt-id');
    expect(result.profileRowsDeleted, 1);
    expect(result.authIdentityDeleted, isFalse);
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
