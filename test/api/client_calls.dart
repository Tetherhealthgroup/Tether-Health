// The typed client calls, one per method, and the published contract's
// routes: shared by the client tests and the sandbox parity tests.
import 'dart:io';

import 'package:breathefree_patient/api/tether_api.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/quit_plan/quit_plan.dart';
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

const testId = 'id-0000';
final testWhen = DateTime.utc(2026, 10, 20, 8, 30);

QuitPlan testQuitPlan() => QuitPlan.fromJson({
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
Map<String, Future<Object?> Function(TetherApi)> clientCalls() => {
      'account.export': (a) => a.account.export(),
      'account.deleteData': (a) => a.account.deleteData(),
      'account.profile': (a) => a.account.profile(),
      'account.updateProfile': (a) => a.account.updateProfile(locale: 'en'),
      'account.baseline': (a) => a.account.baseline(),
      'account.putBaseline': (a) => a.account.putBaseline(const Baseline()),
      'account.quitPlan': (a) => a.account.quitPlan(),
      'account.putQuitPlan': (a) => a.account.putQuitPlan(testQuitPlan()),
      'account.importGuestQuitPlan': (a) =>
          a.account.importGuestQuitPlan(testQuitPlan()),
      'account.programmes': (a) => a.account.programmes(),
      'account.appConfig': (a) => a.account.appConfig(),
      'enrolments.list': (a) => a.enrolments.list(),
      'enrolments.create': (a) => a.enrolments
          .create(programmeCode: 'bf', status: EnrolmentStatus.learnOnly),
      'enrolments.update': (a) =>
          a.enrolments.update(testId, status: EnrolmentStatus.paused),
      'enrolments.delete': (a) => a.enrolments.delete(testId),
      'enrolments.swapFocus': (a) =>
          a.enrolments.swapFocus(demoteId: testId, promoteId: testId),
      'enrolments.grantConsent': (a) => a.enrolments.grantConsent(
            enrolmentId: testId,
            purpose: ConsentPurpose.core,
            consentVersion: 'v1',
            locale: ConsentLocale.en,
          ),
      'enrolments.revokeConsent': (a) => a.enrolments.revokeConsent(
          enrolmentId: testId, purpose: ConsentPurpose.reminders),
      'enrolments.revokeConsentById': (a) =>
          a.enrolments.revokeConsentById(testId),
      'events.hwReading': (a) =>
          a.events.hwReading(idempotencyKey: 'k', systolic: 120, diastolic: 80),
      'events.hwLipids': (a) =>
          a.events.hwLipids(idempotencyKey: 'k', labDate: testWhen, ldl: 100),
      'events.stReading': (a) =>
          a.events.stReading(idempotencyKey: 'k', reading: 110),
      'events.stA1c': (a) =>
          a.events.stA1c(idempotencyKey: 'k', a1c: 6.1, labDate: testWhen),
      'events.reLabs': (a) =>
          a.events.reLabs(idempotencyKey: 'k', labDate: testWhen, egfr: 90),
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
          a.events.ckDone(idempotencyKey: 'k', item: 'walk', doneOn: testWhen),
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
      'care.syncRecordSource': (a) => a.care.syncRecordSource(testId),
      'care.disconnectRecordSource': (a) =>
          a.care.disconnectRecordSource(testId),
    };

/// "METHOD /path" with the test id replaced by `:id`.
String routeOf(BackendRequest r) =>
    '${r.method.wire} ${r.path.replaceAll(testId, ':id')}';

Future<Map<String, BackendRequest>> allRequests() async {
  final found = <String, BackendRequest>{};
  for (final MapEntry(key: name, value: call) in clientCalls().entries) {
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
const notInContractYet = {
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
Set<String> contractRoutes() {
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

/// The documented response statuses of every operation in the contract, by
/// "METHOD /path".
Map<String, Set<int>> contractStatuses() {
  final statuses = <String, Set<int>>{};
  String? path;
  String? operation;
  for (final line in File('docs/contracts/openapi.yaml').readAsLinesSync()) {
    if (line.startsWith('components:')) break;
    final p = RegExp(r'^  (/\S+):\s*$').firstMatch(line);
    if (p != null) {
      path = p.group(1)!.replaceAll(RegExp(r'\{[^}]+\}'), ':id');
      operation = null;
      continue;
    }
    final m = RegExp(r'^    (get|post|put|patch|delete):').firstMatch(line);
    if (m != null && path != null) {
      operation = '${m.group(1)!.toUpperCase()} $path';
      statuses[operation] = <int>{};
      continue;
    }
    final s = RegExp(r"^        '(\d{3})':").firstMatch(line);
    if (s != null && operation != null) {
      statuses[operation]!.add(int.parse(s.group(1)!));
    }
  }
  return statuses;
}
