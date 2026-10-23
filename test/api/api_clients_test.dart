// The typed API clients: one method per route the screens and the reads
// use, checked against the endpoint registry and the published contract.

import 'package:breathefree_patient/api/tether_api.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/integration/registry.dart';
import 'package:breathefree_patient/sync/sync_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'client_calls.dart';

void main() {
  test('every api endpoint of the registry has a typed method', () async {
    final called = {for (final r in (await allRequests()).values) routeOf(r)};
    final missing = [
      for (final entry in endpointRegistry)
        if (entry.owner == OwnerService.api &&
            !called.contains(entry.endpoint.replaceAll(RegExp(r':\w+'), ':id')))
          entry.endpoint,
    ];
    expect(missing, isEmpty);
    // The Learn-only enrolment the catalogue adds.
    expect(called, contains('POST /v1/enrolments'));
  });

  test('every sync endpoint of the registry maps to one programme', () {
    final sync = [
      for (final entry in endpointRegistry)
        if (entry.owner == OwnerService.sync) entry.endpoint,
    ];
    expect(sync, isNotEmpty);
    for (final endpoint in sync) {
      expect(
        syncEndpointAreas.containsKey(endpoint) ||
            endpoint == syncLapseEndpoint,
        isTrue,
        reason: endpoint,
      );
    }
    expect(syncEndpointAreas.keys.toSet().difference(sync.toSet()), isEmpty);
  });

  test('every route the clients call is in the contract or listed as pending',
      () async {
    final contract = contractRoutes();
    expect(contract, isNotEmpty);
    final unknown = <String>{
      for (final r in (await allRequests()).values)
        if (!contract.contains(routeOf(r)) &&
            !notInContractYet.contains(routeOf(r)))
          routeOf(r),
    };
    expect(unknown, isEmpty);
  });

  test('every api request goes to the api service with an absolute path',
      () async {
    for (final MapEntry(key: name, value: r) in (await allRequests()).entries) {
      expect(r.service, BackendService.api, reason: name);
      expect(r.path, startsWith('/v1/'), reason: name);
    }
  });

  test('event and record POSTs carry the Idempotency-Key', () async {
    for (final MapEntry(key: name, value: r) in (await allRequests()).entries) {
      final isEvent = r.method == BackendMethod.post &&
          (r.path.startsWith('/v1/program-data/') ||
              const {
                '/v1/records/check-ins',
                '/v1/records/rescues',
                '/v1/records/lessons',
                '/v1/records/manual',
                '/v1/care/messages',
                '/v1/care/summaries',
              }.contains(r.path));
      if (isEvent) expect(r.idempotencyKey, 'k', reason: name);
      if (!isEvent) expect(r.idempotencyKey, isNull, reason: name);
    }
  });

  group('bodies', () {
    test('a blood pressure reading', () async {
      final t = RecordingTransport();
      await TetherApi(t).events.hwReading(
            idempotencyKey: 'k',
            systolic: 128,
            diastolic: 82,
            pulse: 70,
            measuredAt: DateTime.utc(2026, 10, 20, 7),
          );
      expect(t.requests.single.path, '/v1/program-data/hw/readings');
      expect(t.requests.single.body, {
        'systolic': 128,
        'diastolic': 82,
        'pulse': 70,
        'measuredAt': '2026-10-20T07:00:00.000Z',
      });
    });

    test('dates are sent as YYYY-MM-DD and sets as wire values', () async {
      final t = RecordingTransport();
      await TetherApi(t).events.stReading(
        idempotencyKey: 'k',
        reading: 104.5,
        when: GlucoseWhen.twoHoursAfterMeal,
        feelings: {GlucoseFeeling.shaky},
      );
      await TetherApi(t)
          .events
          .stA1c(idempotencyKey: 'k', a1c: 6, labDate: DateTime(2026, 3, 4));
      expect(t.requests.first.body, {
        'reading': 104.5,
        'when': '2_h_after_meal',
        'feelings': ['shaky'],
      });
      expect((t.requests.last.body! as Map)['labDate'], '2026-03-04');
    });

    test('the summary uses the spec range and the consent revoke its shape',
        () async {
      final t = RecordingTransport();
      final api = TetherApi(t);
      await api.records.summary(programme: 'st', range: SummaryRange.days30);
      await api.enrolments
          .revokeConsent(enrolmentId: testId, purpose: ConsentPurpose.research);
      expect(t.requests.first.query, {'programme': 'st', 'range': '30d'});
      expect(t.requests.last.body,
          {'enrolmentId': testId, 'purpose': 'research', 'revoked': true});
    });

    test('delete now sends its confirmation', () async {
      final t = RecordingTransport(const BackendOk(204));
      final result = await TetherApi(t).enrolments.delete(testId);
      expect(result.isSuccess, isTrue);
      expect(t.requests.single.body, {'confirmation': 'DELETE'});
    });

    test('a check-in nests the programme answers', () async {
      final t = RecordingTransport();
      await TetherApi(t).records.checkIn(
            idempotencyKey: 'k',
            stress: CheckInStress.some,
            smokedToday: SmokedToday.aPuff,
          );
      expect(t.requests.single.body, {
        'stress': 'some',
        'answers': {'bf': 'a_puff'},
      });
    });

    test('calls that would send nothing are refused before sending', () {
      final api = TetherApi(RecordingTransport());
      expect(
          () => api.records.checkIn(idempotencyKey: 'k'), throwsArgumentError);
      expect(() => api.events.hwLipids(idempotencyKey: 'k', labDate: testWhen),
          throwsArgumentError);
      expect(() => api.enrolments.update(testId), throwsArgumentError);
      expect(
          () => api.enrolments
              .create(programmeCode: 'bf', status: EnrolmentStatus.left),
          throwsArgumentError);
    });
  });

  group('results', () {
    test('problem codes become typed errors', () async {
      final t =
          RecordingTransport(const BackendProblem(409, 'focus_cap_reached'));
      final result = await TetherApi(t)
          .enrolments
          .create(programmeCode: 'hw', status: EnrolmentStatus.focus);
      expect(
          result.errorOrNull,
          const ApiError(
              409, ApiProblemCode.focusCapReached, 'focus_cap_reached'));
      expect(result.errorOrNull!.isRetryable, isFalse);
    });

    test('an unknown code is kept as written', () async {
      final t = RecordingTransport(const BackendProblem(409, 'brand_new'));
      final error = (await TetherApi(t).account.export()).errorOrNull!;
      expect(error.code, ApiProblemCode.unknown);
      expect(error.wire, 'brand_new');
    });

    test('unreachable, 5xx and 429 are retryable; 4xx and full are not',
        () async {
      Future<ApiError> errorFor(BackendResponse r) async =>
          (await TetherApi(RecordingTransport(r)).records.today()).errorOrNull!;
      expect((await errorFor(const BackendUnreachable())).isRetryable, isTrue);
      expect(
          (await errorFor(const BackendProblem(503, 'server_error')))
              .isRetryable,
          isTrue);
      expect(
          (await errorFor(const BackendProblem(429, 'rate_limited')))
              .isRetryable,
          isTrue);
      expect(
          (await errorFor(const BackendProblem(400, 'invalid_request')))
              .isRetryable,
          isFalse);
      expect(
          (await errorFor(const BackendProblem(507, 'sandbox_full')))
              .isRetryable,
          isFalse);
      expect(
          (await errorFor(const BackendProblem(401, 'unauthenticated')))
              .isAuthFailure,
          isTrue);
    });

    test('a 2xx body of the wrong shape is invalid_response', () async {
      final t =
          RecordingTransport(const BackendOk(200, ['not', 'an', 'object']));
      final error = (await TetherApi(t).records.today()).errorOrNull!;
      expect(error.code, ApiProblemCode.invalidResponse);
    });

    test('a transport that throws counts as unreachable', () async {
      final error =
          (await TetherApi(_ThrowingTransport()).records.today()).errorOrNull!;
      expect(error, ApiError.unreachable);
    });

    test('responses parse into typed values', () async {
      final t = RecordingTransport(const BackendOk(201, {
        'id': testId,
        'programmeCode': 'bf',
        'status': 'learn_only',
        'mode': null,
        'joinedAt': '2026-10-20T08:00:00.000Z',
        'leftAt': null,
        'createdAt': '2026-10-20T08:00:00.000Z',
        'updatedAt': '2026-10-20T08:00:00.000Z',
        'consents': <Object?>[],
        'currentCoreConsentVersion': null,
        'reconsentRequired': false,
      }));
      final enrolment = (await TetherApi(t)
              .enrolments
              .create(programmeCode: 'bf', status: EnrolmentStatus.learnOnly))
          .valueOrNull!;
      expect(enrolment.status, EnrolmentStatus.learnOnly);
      expect(enrolment.mode, isNull);
      expect(enrolment.consents, isEmpty);

      t.answer = const BackendOk(200, {
        'submissionId': 'a0a0a0a0-0000-4000-8000-000000000000',
        'replayed': true,
      });
      final receipt =
          (await TetherApi(t).events.sdFall(idempotencyKey: 'k')).valueOrNull!;
      expect(receipt.replayed, isTrue);
    });
  });
}

class _ThrowingTransport implements BackendTransport {
  @override
  Future<BackendResponse> send(BackendRequest request) =>
      Future.error(StateError('boom'));
}
