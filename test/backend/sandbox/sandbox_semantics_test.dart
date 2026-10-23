// The sandbox's rules: enrolments, consents, events, the sync service's
// revision and lapse rules, Today and summary, export and deletion, care,
// the size cap, persistence and wiping.
import 'dart:convert';

import 'package:breathefree_patient/api/tether_api.dart';
import 'package:breathefree_patient/app/composition.dart';
import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:breathefree_patient/config/app_config.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_api.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_store.dart';
import 'package:breathefree_patient/sync/sync_client.dart';
import 'package:breathefree_patient/sync/sync_engine.dart';
import 'package:breathefree_patient/sync/sync_models.dart';
import 'package:breathefree_patient/sync/sync_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

ApiProblemCode? _code(ApiResult<Object?> r) => r.errorOrNull?.code;
int? _status(ApiResult<Object?> r) => r.errorOrNull?.status;

void main() {
  late SandboxHarness h;

  setUp(() async {
    h = SandboxHarness();
    await h.signUp();
  });

  group('enrolments', () {
    test('one enrolment per programme', () async {
      await h.enrol('bf');
      final again = await h.api.enrolments
          .create(programmeCode: 'bf', status: EnrolmentStatus.learnOnly);
      expect(_status(again), 409);
      expect(_code(again), ApiProblemCode.alreadyEnrolled);
    });

    test('at most two in focus: 409 focus_cap_reached', () async {
      await h.enrol('bf', status: EnrolmentStatus.focus);
      await h.enrol('hw', status: EnrolmentStatus.focus);
      final third = await h.api.enrolments
          .create(programmeCode: 'st', status: EnrolmentStatus.focus);
      expect(_status(third), 409);
      expect(_code(third), ApiProblemCode.focusCapReached);
      final st = await h.enrol('st');
      final promote =
          await h.api.enrolments.update(st, status: EnrolmentStatus.focus);
      expect(_code(promote), ApiProblemCode.focusCapReached);
    });

    test('learn_only is a status; mode only for bf and sf', () async {
      final created = await h.api.enrolments
          .create(programmeCode: 'ea', status: EnrolmentStatus.learnOnly);
      expect(created.valueOrNull!.status, EnrolmentStatus.learnOnly);
      final mode = await h.api.enrolments.create(
          programmeCode: 'hw',
          status: EnrolmentStatus.paused,
          mode: EnrolmentMode.quit);
      expect(_code(mode), ApiProblemCode.modeNotAllowed);
      final unknown = await h.api.enrolments
          .create(programmeCode: 'zz', status: EnrolmentStatus.paused);
      expect(_code(unknown), ApiProblemCode.programmeNotFound);
    });

    test('leaving revokes the optional consents; rejoining keeps them off',
        () async {
      final bf = await h.enrol('bf');
      await h.api.enrolments.grantConsent(
          enrolmentId: bf,
          purpose: ConsentPurpose.reminders,
          consentVersion: sandboxConsentVersion,
          locale: ConsentLocale.en);
      await h.api.enrolments.update(bf, status: EnrolmentStatus.left);
      final left =
          (await h.api.enrolments.list()).valueOrNull!.enrolments.single;
      expect([for (final c in left.consents) c.purpose], [ConsentPurpose.core]);
      await h.api.enrolments.update(bf, status: EnrolmentStatus.learnOnly);
      final back =
          (await h.api.enrolments.list()).valueOrNull!.enrolments.single;
      expect(back.status, EnrolmentStatus.learnOnly);
      expect([for (final c in back.consents) c.purpose], [ConsentPurpose.core]);
    });

    test('mode is checked before the programme, as on the server', () async {
      final r = await h.api.enrolments.create(
          programmeCode: 'zz',
          status: EnrolmentStatus.paused,
          mode: EnrolmentMode.quit);
      expect(_code(r), ApiProblemCode.modeNotAllowed);
    });

    test('delete now needs its confirmation and removes the data', () async {
      final hw = await h.enrol('hw');
      await h.api.events
          .hwReading(idempotencyKey: h.key(), systolic: 120, diastolic: 80);
      final refused = await h.backend.transport.send(BackendRequest(
          service: BackendService.api,
          method: BackendMethod.delete,
          path: '/v1/enrolments/$hw'));
      expect(refused, const BackendProblem(400, 'confirmation_required'));
      expect((await h.api.enrolments.delete(hw)).isSuccess, isTrue);
      expect((await h.api.enrolments.list()).valueOrNull!.enrolments, isEmpty);
      final summary = await h.api.records
          .summary(programme: 'hw', range: SummaryRange.days7);
      expect(_code(summary), ApiProblemCode.enrolmentNotFound);
    });
  });

  group('consents', () {
    test('need a live enrolment and copy the sandbox draft version', () async {
      final bf = await h.enrol('bf', core: false);
      final reminders = await h.api.enrolments.grantConsent(
          enrolmentId: bf,
          purpose: ConsentPurpose.reminders,
          consentVersion: sandboxConsentVersion,
          locale: ConsentLocale.en);
      expect(_code(reminders), ApiProblemCode.coreConsentRequired);
      final wrongVersion = await h.api.enrolments.grantConsent(
          enrolmentId: bf,
          purpose: ConsentPurpose.core,
          consentVersion: 'v9',
          locale: ConsentLocale.en);
      expect(_code(wrongVersion), ApiProblemCode.consentDocumentUnavailable);
      final core = (await h.api.enrolments.grantConsent(
              enrolmentId: bf,
              purpose: ConsentPurpose.core,
              consentVersion: sandboxConsentVersion,
              locale: ConsentLocale.en))
          .valueOrNull!;
      expect(core.consentVersion, sandboxConsentVersion);
      await h.api.enrolments.update(bf, status: EnrolmentStatus.left);
      final afterLeaving = await h.api.enrolments.grantConsent(
          enrolmentId: bf,
          purpose: ConsentPurpose.research,
          consentVersion: sandboxConsentVersion,
          locale: ConsentLocale.en);
      expect(_code(afterLeaving), ApiProblemCode.enrolmentLeft);
    });

    test('are revoke-only; revoking core revokes them all', () async {
      final bf = await h.enrol('bf');
      await h.api.enrolments.grantConsent(
          enrolmentId: bf,
          purpose: ConsentPurpose.reminders,
          consentVersion: sandboxConsentVersion,
          locale: ConsentLocale.en);
      final grantByPatch = await h.backend.transport.send(BackendRequest(
        service: BackendService.api,
        method: BackendMethod.patch,
        path: '/v1/enrolments/consents',
        body: {'enrolmentId': bf, 'purpose': 'research', 'revoked': false},
      ));
      expect(grantByPatch, const BackendProblem(400, 'bad_request'));
      final none = await h.api.enrolments
          .revokeConsent(enrolmentId: bf, purpose: ConsentPurpose.research);
      expect(_status(none), 404);
      expect(_code(none), ApiProblemCode.consentNotFound);
      await h.api.enrolments
          .revokeConsent(enrolmentId: bf, purpose: ConsentPurpose.core);
      final list = (await h.api.enrolments.list()).valueOrNull!;
      expect(list.enrolments.single.consents, isEmpty);
      final foreign = await h.api.enrolments.revokeConsent(
          enrolmentId: '5a4db0c0-0000-4000-8000-0000000fffff',
          purpose: ConsentPurpose.core);
      expect(_code(foreign), ApiProblemCode.enrolmentNotFound);
    });
  });

  group('events', () {
    test('idempotency: required, replayed, conflicting', () async {
      await h.enrol('ea');
      final missing = await h.backend.transport.send(BackendRequest(
          service: BackendService.api,
          method: BackendMethod.post,
          path: '/v1/program-data/ea/moods',
          body: {'mood': 'okay'}));
      expect(missing, const BackendProblem(400, 'idempotency_key_required'));
      final key = h.key();
      final first =
          await h.api.events.eaMood(idempotencyKey: key, mood: Mood.low);
      expect(first.valueOrNull!.replayed, isFalse);
      final repeat = await h.api.events
          .eaMood(idempotencyKey: key, mood: Mood.low, occurredAt: h.now);
      expect(repeat.valueOrNull!.replayed, isTrue,
          reason: 'times are not compared');
      final other =
          await h.api.events.eaMood(idempotencyKey: key, mood: Mood.good);
      expect(_code(other), ApiProblemCode.idempotencyKeyConflict);
    });

    test('ranges, value bounds and unknown keys', () async {
      await h.enrol('hw');
      await h.enrol('st');
      expect(
          _code(await h.api.events.hwReading(
              idempotencyKey: h.key(), systolic: 260, diastolic: 80)),
          ApiProblemCode.valueOutOfRange);
      expect(
          _code(await h.api.events
              .hwLipids(idempotencyKey: h.key(), labDate: h.now, ldl: 10001)),
          ApiProblemCode.invalidRecord);
      expect(
          _code(await h.api.events
              .stReading(idempotencyKey: h.key(), reading: 100.1234)),
          ApiProblemCode.invalidRequest);
      final unknown = await h.backend.transport.send(BackendRequest(
          service: BackendService.api,
          method: BackendMethod.post,
          path: '/v1/program-data/hw/readings',
          idempotencyKey: h.key(),
          body: {'systolic': 120, 'diastolic': 80, 'constructor': 1}));
      expect(unknown, const BackendProblem(400, 'invalid_request'));
    });

    test('a pulse outside 0–10000 is 422 invalid_record', () async {
      await h.enrol('hw');
      final r = await h.api.events.hwReading(
          idempotencyKey: h.key(), systolic: 120, diastolic: 80, pulse: 20000);
      expect(_status(r), 422);
      expect(_code(r), ApiProblemCode.invalidRecord);
    });

    test('need an enrolment with live core consent', () async {
      expect(_code(await h.api.events.sdFall(idempotencyKey: h.key())),
          ApiProblemCode.enrolmentNotFound);
      await h.enrol('sd', core: false);
      expect(_code(await h.api.events.sdFall(idempotencyKey: h.key())),
          ApiProblemCode.coreConsentRequired);
    });

    test('a check-in needs a focus programme; answers only their own',
        () async {
      expect(
          _code(await h.api.records
              .checkIn(idempotencyKey: h.key(), feel: CheckInFeel.okay)),
          ApiProblemCode.noFocusProgramme);
      await h.enrol('hw', status: EnrolmentStatus.focus);
      expect(
          _code(await h.api.records
              .checkIn(idempotencyKey: h.key(), smokedToday: SmokedToday.no)),
          ApiProblemCode.invalidRecord);
      final ok = await h.api.records
          .checkIn(idempotencyKey: h.key(), stress: CheckInStress.low);
      expect(ok.valueOrNull!.entries, ['hw']);
    });
  });

  group('sync service', () {
    Future<SyncEngine> engine() async {
      final e = SyncEngine(
          client: SyncClient(h.backend.transport),
          store: MemorySyncDocumentStore());
      await e.open(accountId: h.backend.auth.currentIdentity!.id);
      return e;
    }

    test('push and pull through the sync client', () async {
      await h.enrol('bf');
      final e = await engine();
      await e.saveAnswers('bf', 'meds', const ScreenAnswers(option: {'0': 2}));
      await e.appendLapse(
          'bf', Lapse(at: h.now.subtract(const Duration(hours: 1))));
      expect(await e.sync(), SyncRunStatus.ok);
      final pull = (await SyncClient(h.backend.transport).pull()).valueOrNull!;
      expect(pull.currentAreas, {'bf'});
      expect(pull.areas.single.revision, 1);
      expect(pull.areas.single.answers['bf/meds'],
          const ScreenAnswers(option: {'0': 2}));
    });

    test('a stale revision is a conflict with the server copy', () async {
      await h.enrol('bf');
      final client = SyncClient(h.backend.transport);
      const answers = {
        'bf/meds': ScreenAnswers(option: {'0': 1})
      };
      await client.push([const AreaBundle(area: 'bf', answers: answers)]);
      final stale = (await client.push([
        const AreaBundle(area: 'bf', baseRevision: 0, answers: answers)
      ]))
          .valueOrNull!;
      expect(stale.applied, isEmpty);
      expect(stale.conflicts.single.serverRevision, 1);
    });

    test('lapses are append-only', () async {
      await h.enrol('bf');
      final client = SyncClient(h.backend.transport);
      final lapse = Lapse(at: DateTime.utc(2026, 10, 21, 8));
      await client.push([
        AreaBundle(area: 'bf', lapses: [lapse])
      ]);
      final dropped =
          await client.push([const AreaBundle(area: 'bf', baseRevision: 1)]);
      expect(_code(dropped), ApiProblemCode.lapseConflict);
      expect(dropped.errorOrNull!.positions, [0]);
    });

    test('area_gone and consent_required name positions', () async {
      await h.enrol('bf');
      await h.enrol('hw', core: false);
      final client = SyncClient(h.backend.transport);
      final gone = await client.push([
        const AreaBundle(area: 'bf'),
        const AreaBundle(area: 'st'),
      ]);
      expect(_code(gone), ApiProblemCode.areaGone);
      expect(gone.errorOrNull!.positions, [1]);
      final blocked = await client.push([
        const AreaBundle(area: 'bf'),
        const AreaBundle(area: 'hw'),
      ]);
      expect(_status(blocked), 403);
      expect(blocked.errorOrNull!.positions, [1]);
    });
  });

  group('today and summary', () {
    test('today counts only today, in the member\'s day', () async {
      await h.enrol('sf');
      await h.enrol('hw', status: EnrolmentStatus.focus);
      await h.api.events.sfPause(
          idempotencyKey: h.key(),
          reason: PauseReason.bored,
          occurredAt: DateTime.utc(2026, 10, 22, 1));
      await h.api.events.sfPause(
          idempotencyKey: h.key(),
          reason: PauseReason.bored,
          occurredAt: DateTime.utc(2026, 10, 21, 23));
      await h.api.events.hwReading(
          idempotencyKey: h.key(), systolic: 131, diastolic: 84, pulse: 70);
      final today = (await h.api.records.today()).valueOrNull!;
      expect(today.date, '2026-10-22');
      expect(today.checkinDoneToday, isFalse);
      final sf = today.programmes.firstWhere((p) => p.code == 'sf');
      expect(sf.fields['pausesToday'], 1);
      final hw = today.programmes.firstWhere((p) => p.code == 'hw');
      expect((hw.fields['lastBp']! as Map)['systolic'], 131);
      expect((hw.fields['lastBp']! as Map)['pulse'], 70);
    });

    test('summary parses the API query rules', () {
      expect(parseSummaryQuery({'programme': 'hw', 'days': '7'}), ('hw', 7));
      expect(
          parseSummaryQuery({'programme': 'st', 'range': '30d'}), ('st', 30));
      for (final bad in <Map<String, String>>[
        {},
        {'programme': 'hw'},
        {'days': '7'},
        {'programme': 'hw', 'days': '14'},
        {'programme': 'hw', 'days': '7', 'extra': '1'},
        {'programme': 'hw', 'range': '7'},
        {'programme': 'hw', 'range': '14d'},
        {'programme': 'hw', 'range': '7D'},
        {'programme': 'hw', 'range': 'constructor'},
        {'programme': 'hw', 'range': '7d', 'days': '7'},
      ]) {
        expect(() => parseSummaryQuery(bad), throwsA(anything), reason: '$bad');
      }
    });

    test('summary covers one programme and its window', () async {
      await h.enrol('st');
      await h.api.events.stReading(
          idempotencyKey: h.key(),
          reading: 99,
          measuredAt: DateTime.utc(2026, 10, 1));
      await h.api.events.stReading(idempotencyKey: h.key(), reading: 140);
      final week = (await h.api.records
              .summary(programme: 'st', range: SummaryRange.days7))
          .valueOrNull!;
      expect([for (final o in week.observations) o['value']], [140]);
      final month = (await h.api.records
              .summary(programme: 'st', range: SummaryRange.days30))
          .valueOrNull!;
      expect(month.observations, hasLength(2));
    });
  });

  group('account', () {
    test('export holds the account\'s rows; deletion returns the receipt keys',
        () async {
      await h.enrol('bf');
      final export = (await h.api.account.export()).valueOrNull!;
      expect(export['schemaVersion'], '1.0');
      expect(
          ((export['sandbox']! as Map)['enrolments']! as List), hasLength(1));
      final receipt = (await h.api.account.deleteData()).valueOrNull!;
      expect(receipt.deleted.keys.toSet(), deletionReceiptKeys.toSet());
      expect(h.backend.auth.currentIdentity, isNull);
      expect(_status(await h.api.records.today()), 401);
    });

    test('export and deletion need a recent sign-in', () async {
      h.now = h.now.add(const Duration(minutes: 20));
      expect(_status(await h.api.account.export()), 401);
      expect(_status(await h.api.account.deleteData()), 401);
    });
  });

  group('care', () {
    test('the sandbox invite code redeems to Sandbox Clinic', () async {
      final bad = await h.api.care.redeemConnection({'code': 'WRONG'});
      expect(_status(bad), 400);
      final good =
          (await h.api.care.redeemConnection({'code': 'tether-sandbox-clinic'}))
              .valueOrNull!;
      expect(good['clinicName'], 'Sandbox Clinic');
    });

    test('messages are stored and never delivered', () async {
      await h.api.care
          .sendMessage({'text': 'synthetic'}, idempotencyKey: h.key());
      final export = (await h.api.account.export()).valueOrNull!;
      final care = (export['sandbox']! as Map)['care']! as Map;
      expect((care['messages']! as List).single['delivery'], 'none (sandbox)');
    });
  });

  group('storage', () {
    test('over the cap: 507 sandbox_full and nothing is kept', () async {
      final small = SandboxHarness(maxBytes: 4096);
      await small.signUp();
      await small.enrol('ck');
      String? before;
      late ApiResult<Object?> result;
      for (var i = 0; i < 100; i++) {
        before = small.persistence.document;
        result = await small.api.events.ckDone(
            idempotencyKey: small.key(),
            item: 'walk',
            doneOn: small.now,
            place: 'x' * 400);
        if (!result.isSuccess) break;
      }
      expect(_status(result), 507);
      expect(_code(result), ApiProblemCode.sandboxFull);
      expect(small.persistence.document, before,
          reason: 'the refused request left nothing behind');
      expect(utf8.encode(small.persistence.document!).length,
          lessThanOrEqualTo(4096));
    });

    test('persists across a restart', () async {
      await h.enrol('bf');
      await h.restart();
      expect(h.backend.auth.currentIdentity, isNotNull);
      final list = (await h.api.enrolments.list()).valueOrNull!;
      expect(list.enrolments.single.programmeCode, 'bf');
    });

    test('wipeLocal removes only the signed-in account; wipeAll everything',
        () async {
      await h.enrol('bf');
      await h.backend.auth.signOut();
      await h.signUp('second@sandbox.invalid');
      await h.enrol('hw');
      await h.backend.wipeLocal();
      expect(h.backend.auth.currentIdentity, isNull);
      await h.restart();
      expect(h.backend.auth.currentIdentity, isNull);
      await h.backend.auth
          .signIn(email: 'member@sandbox.invalid', password: 'synthetic-pass');
      expect(
          (await h.api.enrolments.list())
              .valueOrNull!
              .enrolments
              .single
              .programmeCode,
          'bf');
      await expectLater(
          h.backend.auth.signIn(
              email: 'second@sandbox.invalid', password: 'synthetic-pass'),
          throwsA(isA<AuthFailure>()));
      await h.backend.wipeAll();
      expect(h.persistence.document, isNull);
      expect(h.backend.auth.currentIdentity, isNull);
    });

    test('the composition root restores the session at start', () async {
      await h.enrol('bf');
      final next = h.build();
      expect(next.auth.currentIdentity, isNull);
      await compose(
          config: const AppConfig(
              apiBaseUrl: '', supabaseUrl: '', supabaseAnonKey: ''),
          backend: next);
      expect(next.auth.currentIdentity, isNotNull);
    });

    test('an unrouted path asks for sign-in first, then is not found',
        () async {
      final request = BackendRequest(
          service: BackendService.api,
          method: BackendMethod.get,
          path: '/v1/nowhere');
      expect(await h.backend.transport.send(request),
          const BackendProblem(404, 'not_found'));
      await h.backend.auth.signOut();
      expect(await h.backend.transport.send(request),
          const BackendProblem(401, 'unauthenticated'));
    });

    test('the document is one entry under sandbox.v1', () {
      expect(SecureSandboxPersistence.key, 'sandbox.v1');
      expect(SandboxStore.defaultMaxBytes, 1024 * 1024);
    });
  });
}
