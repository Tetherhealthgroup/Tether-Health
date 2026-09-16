import 'dart:async';

import 'package:breathefree_patient/profile/profile_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads a profile with the caller bearer token', () async {
    final client = HttpProfileApiClient(
      baseUrl: 'https://api.example.test/base',
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://api.example.test/v1/profile');
        expect(request.headers['authorization'], 'Bearer user-token');
        return http.Response(
          '{"id":"00000000-0000-0000-0000-000000000001","displayName":"Alex","locale":"en","timeZone":"America/Los_Angeles","onboardingCompleted":false,"avatarPath":null,"createdAt":"2026-09-11T00:00:00Z","updatedAt":"2026-09-11T00:00:00Z"}',
          200,
        );
      }),
    );

    final profile = await client.getProfile('user-token');
    expect(profile.displayName, 'Alex');
    expect(profile.locale, 'en');
  });

  test('returns a typed error without exposing response data', () async {
    final client = HttpProfileApiClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((_) async => http.Response('sensitive detail', 403)),
    );
    await expectLater(
        client.getProfile('token'), throwsA(isA<ProfileApiException>()));
  });

  test('times out a profile request so startup can retry', () async {
    final client = HttpProfileApiClient(
      baseUrl: 'https://api.example.test',
      requestTimeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
        client.getProfile('token'), throwsA(isA<TimeoutException>()));
  });
}
