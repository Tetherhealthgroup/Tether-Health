// The typed API clients: one method per route the screens and the reads
// use, checked against the endpoint registry and the published contract.
import 'dart:io';

import 'package:breathefree_patient/api/tether_api.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/integration/registry.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
import 'package:breathefree_patient/sync/sync_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every request and answers each with [answer].
class RecordingTransport implements BackendTransport {
  RecordingTransport([this.answer = const BackendOk(200, <String, Object?>{})]);

  BackendResponse answer;
  final List<BackendRequest> requests = <BackendRequest>[];

  @override
  Future<BackendResponse> send(BackendRequest request) async {
    requests.add(request);
    return answer;
  }
}

const _id = 'id-0000';
final _when = DateTime.utc(2026, 10, 20, 8, 30);

QuitPlan _plan() => QuitPlan.fromJson({
      'userId': 'u-1',
      'dailyCigaretteUse': null,
      'smokingTriggers': <String>[],
      'customSmokingTrigger': null,
      'readinessPath': 'prepare',
      'quitPlanPath': 'setQuitDate',
      'quitDate': '2026-11-01',
      'quitDayCheckIn': false,
      'quitReasons': <String>[],
      'customQuitReason': null,
      'topQuitReason': null,
      'supportPeople': <Object?>[],
      'preparationTasks': <String>[],
      'treatmentSupport': false,
      'careTeamReminder': false,
    });

/// Calls every client method once.
Map<String, Future<Object?> Function(TetherApi)> _calls() => {
      'account.export': (a) => a.account.export(),
      'account.deleteData': (a) => a.account.deleteData(),
      'account.profile': (a) => a.account.profile(),
      'account.updateProfile': (a) => a.account.updateProfile(locale: 'en'),
      'account.baseline': (a) => a.account.baseline(),
      'account.putBaseline': (a) => a.account.putBaseline(const Baseline()),
      'account.quitPlan': (a) => a.account.quitPlan(),
      'account.putQuitPlan': (a) => a.account.putQuitPlan(_plan()),
      'account.importGuestQuitPlan': (a) =>
          a.account.importGuestQuitPlan(_plan()),
      'account.programmes': (a) => a.account.programmes(),
      'account.appConfig': (a) => a.account.appConfig(),
      'enrolments.list': (a) => a.enrolments.list(),
      'enrolments.create': (a) => a.enrolments
          .create(programmeCode: 'bf', status: EnrolmentStatus.learnOnly),
      'enrolments.update': (a) =>
          a.enrolments.update(_id, status: EnrolmentStatus.paused),
      'enrolments.delete': (a) => a.enrolments.delete(_id),
      'enrolments.swapFocus': (a) =>
          a.enrolments.swapFocus(demoteId: _id, promoteId: _id),
      'enrolments.grantConsent': (a) => a.enrolments.grantConsent(
            enrolmentId: _id,
            purpose: ConsentPurpose.core,
            consentVersion: 'v1',
            locale: ConsentLocale.en,
          ),
      'enrolments.revokeConsent': (a) => a.enrolments
          .revokeConsent(enrolmentId: _id, purpose: ConsentPurpose.reminders),
      'enrolments.revokeConsentById': (a) =>
          a.enrolments.revokeConsentById(_id),
      'events.hwReading': (a) =>
          a.events.hwReading(idempotencyKey: 'k', systolic: 120, diastolic: 80),
      'events.hwLipids': (a) =>
          a.events.hwLipids(idempotencyKey: 'k', labDate: _when, ldl: 100),
      'events.stReading': (a) =>
          a.events.stReading(idempotencyKey: 'k', reading: 110),
      'events.stA1c': (a) =>
          a.events.stA1c(idempotencyKey: 'k', a1c: 6.1, labDate: _when),
      'events.reLabs': (a) =>
          a.events.reLabs(idempotencyKey: 'k', labDate: _when, egfr: 90),
      'events.caZoneCheck': (a) =>
          a.events.caZoneCheck(idempotencyKey: 'k', zone: AsthmaZone.green),
      'events.caSymptoms': (a) => a.events
          .caSymptoms(idempotencyKey: 'k', symptoms: {AsthmaSymptom.coughing}),
      'events.eaMood': (a) =>
          a.events.eaMood(idempotencyKey: 'k', mood: Mood.okay),
      'events.eaCheckBack': (a) => a.events
          .eaCheckBack(idempotencyKey: 'k', change: CheckBackChange.same),
      'events.sdSession': (a) => a.events.sdSession(idempotencyKey: 'k'),
      'events.sdFall': (a) => a.events.sdFall(idempotencyKey: 'k'),
      'events.sfPause': (a) =>
          a.events.sfPause(idempotencyKey: 'k', reason: PauseReason.bored),
      'events.ckDone': (a) =>
          a.events.ckDone(idempotencyKey: 'k', item: 'walk', doneOn: _when),
      'events.beDiary': (a) =>
          a.events.beDiary(idempotencyKey: 'k', fatigue: 3),
      'events.beSurvivorship': (a) => a.events.beSurvivorship(
          idempotencyKey: 'k', feeling: SurvivorshipFeeling.mixed),
      'records.checkIn': (a) =>
          a.records.checkIn(idempotencyKey: 'k', feel: CheckInFeel.good),
      'records.rescue': (a) =>
          a.records.rescue(idempotencyKey: 'k', tool: 'breathing'),
      'records.lessonCompleted': (a) => a.records.lessonCompleted(
          idempotencyKey: 'k', programme: 'bf', lessonId: 'bf.intro'),
      'records.today': (a) => a.records.today(),
      'records.summary': (a) =>
          a.records.summary(programme: 'hw', range: SummaryRange.days7),
      'records.notificationPreferences': (a) =>
          a.records.notificationPreferences(),
      'records.updateNotificationPreferences': (a) =>
          a.records.updateNotificationPreferences(remindersEnabled: true),
      'care.redeemConnection': (a) => a.care.redeemConnection({}),
      'care.connections': (a) => a.care.connections(),
      'care.sendMessage': (a) => a.care.sendMessage({}, idempotencyKey: 'k'),
      'care.addSupporter': (a) => a.care.addSupporter({}),
      'care.supporters': (a) => a.care.supporters(),
      'care.sendSummary': (a) => a.care.sendSummary({}, idempotencyKey: 'k'),
      'care.addCaregiver': (a) => a.care.addCaregiver({}),
      'care.requestReferral': (a) => a.care.requestReferral({}),
      'care.addManualRecord': (a) =>
          a.care.addManualRecord({}, idempotencyKey: 'k'),
      'care.recordSources': (a) => a.care.recordSources(),
      'care.acceptRecords': (a) => a.care.acceptRecords({}),
      'care.resolveRecordConflicts': (a) => a.care.resolveRecordConflicts({}),
      'care.syncRecordSource': (a) => a.care.syncRecordSource(_id),
      'care.disconnectRecordSource': (a) => a.care.disconnectRecordSource(_id),
    };

/// "METHOD /path" with the test id replaced by `:id`.
String _route(BackendRequest r) =>
    '${r.method.wire} ${r.path.replaceAll(_id, ':id')}';

Future<Map<String, BackendRequest>> _allRequests() async {
  final found = <String, BackendRequest>{};
  for (final MapEntry(key: name, value: call) in _calls().entries) {
    final transport = RecordingTransport();
    await call(TetherApi(transport));
    expect(transport.requests, hasLength(1), reason: name);
    found[name] = transport.requests.single;
  }
  return found;
}

/// Routes the app calls that the contract at this revision does not have
/// yet (care routes and the records core are being built), and the spec
/// shapes whose contract change is not merged here yet.
const _notInContractYet = {
  'POST /v1/account/export',
  'PATCH /v1/enrolments/consents',
  'POST /v1/care/connections',
  'GET /v1/care/connections',
  'POST /v1/care/messages',
  'POST /v1/care/supporters',
  'GET /v1/care/supporters',
  'POST /v1/care/summaries',
  'POST /v1/care/caregivers',
  'POST /v1/care/referrals',
  'POST /v1/records/manual',
  'GET /v1/records/fhir/sources',
  'POST /v1/records/fhir/accept',
  'POST /v1/records/fhir/conflicts',
  'POST /v1/records/fhir/sources/:id/sync',
  'DELETE /v1/records/fhir/sources/:id',
};

/// "METHOD /path" of every operation in docs/contracts/openapi.yaml.
Set<String> _contractRoutes() {
  final routes = <String>{};
  String? path;
  for (final line in File('docs/contracts/openapi.yaml').readAsLinesSync()) {
    final p = RegExp(r'^  (/\S+):\s*$').firstMatch(line);
    if (p != null) {
      path = p.group(1)!.replaceAll(RegExp(r'\{[^}]+\}'), ':id');
      continue;
    }
    final m = RegExp(r'^    (get|post|put|patch|delete):').firstMatch(line);
    if (m != null && path != null) {
      routes.add('${m.group(1)!.toUpperCase()} $path');
    }
  }
  return routes;
}

void main() {
  test('every api endpoint of the registry has a typed method', () async {
    final called = {for (final r in (await _allRequests()).values) _route(r)};
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
    final contract = _contractRoutes();
    expect(contract, isNotEmpty);
    final unknown = <String>{
      for (final r in (await _allRequests()).values)
        if (!contract.contains(_route(r)) &&
            !_notInContractYet.contains(_route(r)))
          _route(r),
    };
    expect(unknown, isEmpty);
  });

  test('every api request goes to the api service with an absolute path',
      () async {
    for (final MapEntry(key: name, value: r)
        in (await _allRequests()).entries) {
      expect(r.service, BackendService.api, reason: name);
      expect(r.path, startsWith('/v1/'), reason: name);
    }
  });

  test('event and record POSTs carry the Idempotency-Key', () async {
    for (final MapEntry(key: name, value: r)
        in (await _allRequests()).entries) {
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
          .revokeConsent(enrolmentId: _id, purpose: ConsentPurpose.research);
      expect(t.requests.first.query, {'programme': 'st', 'range': '30d'});
      expect(t.requests.last.body,
          {'enrolmentId': _id, 'purpose': 'research', 'revoked': true});
    });

    test('delete now sends its confirmation', () async {
      final t = RecordingTransport(const BackendOk(204));
      final result = await TetherApi(t).enrolments.delete(_id);
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
      expect(() => api.events.hwLipids(idempotencyKey: 'k', labDate: _when),
          throwsArgumentError);
      expect(() => api.enrolments.update(_id), throwsArgumentError);
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
        'id': _id,
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
