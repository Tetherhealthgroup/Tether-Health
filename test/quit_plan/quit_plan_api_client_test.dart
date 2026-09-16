import 'dart:convert';

import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:breathefree_patient/quit_plan/quit_plan_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads the caller quit plan with a bearer token', () async {
    final client = HttpQuitPlanApiClient(
      baseUrl: 'https://api.example.test/base',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://api.example.test/v1/quit-plan');
        expect(request.headers['authorization'], 'Bearer user-token');
        return http.Response(jsonEncode(_responseJson()), 200);
      }),
    );

    final plan = await client.getQuitPlan('user-token');
    expect(plan.quitPlanPath, 'setQuitDate');
    expect(plan.smokingTriggers, ['stress', 'afterMeals']);
    expect(plan.supportPeople.single.name, 'Test Friend');
  });

  test('puts only the complete request snapshot', () async {
    final plan = QuitPlan.fromJson(_responseJson());
    final client = HttpQuitPlanApiClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.headers['authorization'], 'Bearer user-token');
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['userId'], isNull);
        expect(body['createdAt'], isNull);
        expect(body['quitDate'], '2026-10-01');
        expect(body['topQuitReason'], 'family');
        return http.Response(jsonEncode(_responseJson()), 200);
      }),
    );

    final saved = await client.putQuitPlan('user-token', plan);
    expect(saved.userId, '00000000-0000-0000-0000-000000000001');
  });

  test('returns a typed not-found response', () async {
    final client = HttpQuitPlanApiClient(
      baseUrl: 'https://api.example.test',
      client: MockClient((_) async => http.Response('{}', 404)),
    );

    await expectLater(
      client.getQuitPlan('token'),
      throwsA(
        isA<QuitPlanApiException>()
            .having((error) => error.statusCode, 'statusCode', 404),
      ),
    );
  });
}

Map<String, Object?> _responseJson() => {
      'userId': '00000000-0000-0000-0000-000000000001',
      'dailyCigaretteUse': 'tenOrFewer',
      'smokingTriggers': ['stress', 'afterMeals'],
      'customSmokingTrigger': null,
      'readinessPath': 'prepare',
      'quitPlanPath': 'setQuitDate',
      'quitDate': '2026-10-01',
      'quitDayCheckIn': true,
      'quitReasons': ['family', 'breatheEasier'],
      'customQuitReason': null,
      'topQuitReason': 'family',
      'supportPeople': [
        {
          'id': 'test-friend',
          'name': 'Test Friend',
          'relationship': 'Friend',
          'channel': 'text',
          'checkIn': 'Check in the evening before my quit date',
          'enabled': true,
        },
      ],
      'preparationTasks': ['removeSupplies'],
      'treatmentSupport': true,
      'careTeamReminder': true,
      'createdAt': '2026-09-15T00:00:00.000Z',
      'updatedAt': '2026-09-15T00:00:00.000Z',
    };
