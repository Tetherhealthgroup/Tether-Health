// Route parity: every sandbox route is in the contract (or listed as not
// published yet) with the same method and path, answers only statuses the
// contract documents, and every route the clients call is served.
import 'package:breathefree_patient/api/tether_api.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_server.dart';
import 'package:breathefree_patient/sync/sync_client.dart';
import 'package:breathefree_patient/sync/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../api/client_calls.dart';
import 'support.dart';

/// Sync routes, documented by the sync service rather than the API
/// contract.
const _syncRoutes = {'POST /v1/sync/pull', 'POST /v1/sync/push'};

/// Records the status of every answer, by route signature.
class _StatusRecorder implements BackendTransport {
  _StatusRecorder(this.inner);

  final BackendTransport inner;
  final Map<String, Set<int>> seen = {};

  @override
  Future<BackendResponse> send(BackendRequest request) async {
    final answer = await inner.send(request);
    final route = sandboxRoutes.firstWhere(
        (r) =>
            r.service == request.service &&
            r.method == request.method &&
            r.match(request.path) != null,
        orElse: () => throw StateError('unrouted ${request.method.wire}'));
    final status = switch (answer) {
      BackendOk(:final status) => status,
      BackendProblem(:final status) => status,
      BackendUnreachable() => 0,
    };
    (seen[route.signature] ??= {}).add(status);
    return answer;
  }
}

void main() {
  test('every sandbox route is in the contract or listed as pending', () {
    final contract = contractRoutes();
    final unknown = [
      for (final route in sandboxRoutes)
        if (!contract.contains(route.signature) &&
            !notInContractYet.contains(route.signature) &&
            !_syncRoutes.contains(route.signature))
          route.signature,
    ];
    expect(unknown, isEmpty);
    // No route is served twice.
    final signatures = [
      for (final r in sandboxRoutes) '${r.service}${r.signature}'
    ];
    expect(signatures.toSet(), hasLength(signatures.length));
  });

  test('every route the clients call is served by the sandbox', () async {
    final missing = <String>[];
    for (final request in (await allRequests()).values) {
      final served = sandboxRoutes.any((r) =>
          r.service == request.service &&
          r.method == request.method &&
          r.match(request.path) != null);
      if (!served) missing.add(routeOf(request));
    }
    expect(missing, isEmpty);
  });

  test('the sync client\'s routes are served', () {
    for (final path in ['/v1/sync/pull', '/v1/sync/push']) {
      expect(
        sandboxRoutes.any((r) =>
            r.service == BackendService.sync &&
            r.method == BackendMethod.post &&
            r.match(path) != null),
        isTrue,
      );
    }
  });

  test('a walk through every route answers only documented statuses', () async {
    final h = SandboxHarness();
    final recorder = _StatusRecorder(h.backend.transport);
    final api = TetherApi(recorder);
    // Unauthenticated first.
    await api.records.today();
    await api.account.appConfig();
    await h.signUp();

    final bf = (await api.enrolments.create(
            programmeCode: 'bf',
            status: EnrolmentStatus.focus,
            mode: EnrolmentMode.quit))
        .valueOrNull!
        .id;
    await api.enrolments
        .create(programmeCode: 'bf', status: EnrolmentStatus.focus);
    await api.enrolments
        .create(programmeCode: 'zz', status: EnrolmentStatus.focus);
    await api.enrolments.create(
        programmeCode: 'hw',
        status: EnrolmentStatus.focus,
        mode: EnrolmentMode.quit);
    final ids = <String, String>{'bf': bf};
    for (final code in [
      'hw',
      'st',
      're',
      'ca',
      'ea',
      'sd',
      'sf',
      'ck',
      'be',
      'nu'
    ]) {
      ids[code] = (await api.enrolments.create(
              programmeCode: code,
              status: code == 'hw'
                  ? EnrolmentStatus.focus
                  : EnrolmentStatus.learnOnly))
          .valueOrNull!
          .id;
    }
    await api.enrolments
        .create(programmeCode: 'xx', status: EnrolmentStatus.focus);
    await api.records.checkIn(idempotencyKey: h.key(), feel: CheckInFeel.good);
    for (final id in ids.values) {
      await api.enrolments.grantConsent(
          enrolmentId: id,
          purpose: ConsentPurpose.core,
          consentVersion: 'sandbox-draft-1',
          locale: ConsentLocale.en);
    }
    await api.enrolments.grantConsent(
        enrolmentId: bf,
        purpose: ConsentPurpose.reminders,
        consentVersion: 'not-shown',
        locale: ConsentLocale.en);
    final reminders = await api.enrolments.grantConsent(
        enrolmentId: bf,
        purpose: ConsentPurpose.reminders,
        consentVersion: 'sandbox-draft-1',
        locale: ConsentLocale.en);
    await api.enrolments.revokeConsentById(reminders.valueOrNull!.id);
    await api.enrolments.revokeConsentById(reminders.valueOrNull!.id);
    await api.enrolments
        .revokeConsent(enrolmentId: bf, purpose: ConsentPurpose.research);
    await api.enrolments.list();
    await api.enrolments.update(ids['st']!, status: EnrolmentStatus.focus);
    await api.enrolments.swapFocus(demoteId: ids['hw']!, promoteId: ids['st']!);
    await api.enrolments.swapFocus(demoteId: ids['hw']!, promoteId: ids['st']!);

    final key = h.key();
    await api.events
        .hwReading(idempotencyKey: key, systolic: 120, diastolic: 80);
    await api.events
        .hwReading(idempotencyKey: key, systolic: 120, diastolic: 80);
    await api.events
        .hwReading(idempotencyKey: key, systolic: 121, diastolic: 80);
    await api.events
        .hwReading(idempotencyKey: h.key(), systolic: 300, diastolic: 80);
    await api.events
        .hwLipids(idempotencyKey: h.key(), labDate: h.now, ldl: 20000);
    await api.events
        .hwLipids(idempotencyKey: h.key(), labDate: h.now, ldl: 100);
    await api.events.stReading(idempotencyKey: h.key(), reading: 110);
    await api.events.stA1c(idempotencyKey: h.key(), a1c: 6.1, labDate: h.now);
    await api.events.reLabs(idempotencyKey: h.key(), labDate: h.now, egfr: 90);
    await api.events
        .caZoneCheck(idempotencyKey: h.key(), zone: AsthmaZone.green);
    await api.events.caSymptoms(
        idempotencyKey: h.key(), symptoms: {AsthmaSymptom.wheezing});
    await api.events.eaMood(idempotencyKey: h.key(), mood: Mood.okay);
    await api.events
        .eaCheckBack(idempotencyKey: h.key(), change: CheckBackChange.same);
    await api.events.sdSession(idempotencyKey: h.key());
    await api.events.sdFall(idempotencyKey: h.key());
    await api.events
        .sfPause(idempotencyKey: h.key(), reason: PauseReason.bored);
    await api.events
        .ckDone(idempotencyKey: h.key(), item: 'walk', doneOn: h.now);
    await api.events.beDiary(idempotencyKey: h.key(), fatigue: 3);
    await api.events.beSurvivorship(
        idempotencyKey: h.key(), feeling: SurvivorshipFeeling.good);
    await api.records.checkIn(idempotencyKey: h.key(), feel: CheckInFeel.good);
    await api.records.rescue(idempotencyKey: h.key(), tool: 'breathing');
    await api.records.lessonCompleted(
        idempotencyKey: h.key(), programme: 'bf', lessonId: 'bf.intro');
    await api.records.today();
    await api.records.summary(programme: 'hw', range: SummaryRange.days7);
    await api.records.summary(programme: 'zz', range: SummaryRange.days7);
    await api.records.notificationPreferences();
    await api.records.updateNotificationPreferences(remindersEnabled: true);
    await api.account.profile();
    await api.account.updateProfile(timeZone: 'UTC');
    await api.account.baseline();
    await api.account.putBaseline(const Baseline(sleepBand: '7_8'));
    await api.account.quitPlan();
    await api.account.importGuestQuitPlan(testQuitPlan());
    await api.account.importGuestQuitPlan(testQuitPlan());
    await api.account.putQuitPlan(testQuitPlan());
    await api.account.quitPlan();
    await recorder.send(BackendRequest(
        service: BackendService.api,
        method: BackendMethod.get,
        path: '/v1/account/export'));
    await api.account.programmes();
    await api.account.appConfig();
    await api.care.redeemConnection({'code': 'NOT-A-CODE'});
    await api.care.redeemConnection({'code': 'TETHER-SANDBOX-CLINIC'});
    await api.care.connections();
    await api.care.addSupporter({'name': 'Synthetic Friend'});
    await api.care.supporters();
    await api.care.sendMessage({'text': 'synthetic'}, idempotencyKey: h.key());
    await api.care
        .sendSummary({'snapshot': 'synthetic'}, idempotencyKey: h.key());
    await api.care.addCaregiver({'name': 'Synthetic Carer'});
    await api.care.requestReferral({'time': 'morning'});
    await api.care
        .addManualRecord({'kind': 'allergy'}, idempotencyKey: h.key());
    await api.care.recordSources();
    await api.care.recordItems();
    await api.care.acceptRecords({'items': <Object?>[]});
    await api.care.resolveRecordConflicts({'items': <Object?>[]});
    await api.care.syncRecordSource('5a4db0c0-0000-4000-8000-000000000999');
    await api.care
        .disconnectRecordSource('5a4db0c0-0000-4000-8000-000000000999');
    final sync = SyncClient(recorder);
    await sync.pull();
    await sync.push([
      const AreaBundle(area: 'bf', answers: {
        'bf/meds': ScreenAnswers(option: {'0': 1})
      }),
    ]);
    await api.account.export();
    await api.enrolments.delete(ids['nu']!);
    await api.account.deleteData();

    final documented = contractStatuses();
    final undocumented = <String>[];
    for (final MapEntry(key: route, value: statuses) in recorder.seen.entries) {
      final allowed = documented[route];
      if (allowed == null) continue; // pending or sync routes
      for (final status in statuses) {
        // 401 is documented on every authenticated route by reference.
        if (status == 401) continue;
        if (!allowed.contains(status)) undocumented.add('$route $status');
      }
    }
    expect(undocumented, isEmpty);
    // The walk reached every route the sandbox serves.
    final unreached = [
      for (final r in sandboxRoutes)
        if (!recorder.seen.containsKey(r.signature)) r.signature,
    ];
    expect(unreached, isEmpty);
  });
}
