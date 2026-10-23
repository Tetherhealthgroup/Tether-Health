// The endpoint handlers, end to end against the sandbox backend (and the
// request shapes the http transport would send): coverage, onboarding order,
// outbox, plans through sync, settings, device-only data.
import 'package:breathefree_patient/api/tether_api.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/backend/post_auth_hooks.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_backend.dart';
import 'package:breathefree_patient/data/app_services.dart';
import 'package:breathefree_patient/data/display_source.dart';
import 'package:breathefree_patient/data/sync_codec.dart';
import 'package:breathefree_patient/integration/data_adapter.dart';
import 'package:breathefree_patient/integration/deletion_records.dart';
import 'package:breathefree_patient/integration/endpoints/common.dart';
import 'package:breathefree_patient/integration/endpoints/handlers.dart';
import 'package:breathefree_patient/integration/pending_onboarding.dart';
import 'package:breathefree_patient/integration/registry.dart';
import 'package:breathefree_patient/integration/session_lifecycle.dart';
import 'package:breathefree_patient/sync/sync_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

import '../backend/sandbox/support.dart';

/// The sandbox backend with every request recorded.
class _Recorded implements Backend, ConsentDocuments {
  _Recorded(this.inner);

  final SandboxBackend inner;
  final List<String> calls = [];
  bool offline = false;

  /// Paths that answer a server failure.
  final Set<String> failing = {};

  /// Replaces the sandbox's document versions when set.
  Map<String, String>? versions;

  @override
  Future<Map<String, String>?> currentConsentVersions() async =>
      versions ?? await inner.currentConsentVersions();

  @override
  BackendMode get mode => inner.mode;

  @override
  AuthBackend get auth => inner.auth;

  @override
  late final BackendTransport transport = _Transport(this);

  @override
  Future<void> init() => inner.init();

  @override
  Future<void> wipeLocal() => inner.wipeLocal();
}

class _Transport implements BackendTransport {
  _Transport(this.owner);

  final _Recorded owner;

  @override
  Future<BackendResponse> send(BackendRequest request) async {
    if (owner.offline) return const BackendUnreachable();
    if (owner.failing.contains(request.path)) {
      return const BackendProblem(503, 'server_error');
    }
    owner.calls.add('${request.method.wire} ${request.path}');
    return owner.inner.transport.send(request);
  }
}

void main() {
  late SandboxHarness h;
  late _Recorded backend;
  late AppServices services;
  late HandlerKit kit;
  late AppApi api;
  late MemorySyncDocumentStore deviceStore;

  setUp(() async {
    h = SandboxHarness();
    backend = _Recorded(h.backend);
    deviceStore = MemorySyncDocumentStore();
    services = AppServices(backend,
        syncStore: MemorySyncDocumentStore(),
        outboxStore: MemorySyncDocumentStore(),
        localStore: deviceStore);
    kit = HandlerKit(
      services: services,
      data: AppData(),
      cleaners: DeletionCleaners(),
      postAuthHooks: PostAuthHooks(),
      pending: PendingOnboarding(deviceStore),
    );
    api = AppApi(handlers: handlersFor(kit));
    HandlerKit.programOfScreen = null;
    HandlerKit.argumentOfScreen = null;
  });

  tearDown(TSession.clear);

  /// Grants [code]'s share_care_team consent naming the live connection.
  Future<void> shareWithClinic(String code) async {
    final list =
        (await h.api.care.connections()).valueOrNull!['connections']! as List;
    final connection = (list.single as Map)['id'] as String;
    final e = (await h.api.enrolments.list())
        .valueOrNull!
        .enrolments
        .firstWhere((e) => e.programmeCode == code);
    final granted = await h.api.enrolments.grantConsent(
        enrolmentId: e.id,
        purpose: ConsentPurpose.shareCareTeam,
        consentVersion: 'sandbox-draft-1',
        locale: ConsentLocale.en,
        recipientRef: connection);
    expect(granted.isSuccess, isTrue);
  }

  Future<TResult> submit(
      String endpoint, String screen, Map<String, Object?> values,
      {Set<String> touched = const {}}) {
    for (final MapEntry(:key, :value) in values.entries) {
      TSession.set(key, value);
    }
    for (final key in touched) {
      TSession.markTouched(key, true);
    }
    return api.submit(endpoint, screenId: screen);
  }

  test('every registered endpoint has a handler, except sign-in submits', () {
    final handlers = handlersFor(kit);
    final missing = [
      for (final entry in endpointRegistry)
        if (!handlers.containsKey(entry.endpoint) &&
            entry.owner != OwnerService.supabaseAuth)
          entry.endpoint,
    ];
    expect(missing, isEmpty);
    final auth = [
      for (final e in endpointRegistry)
        if (e.owner == OwnerService.supabaseAuth) e.endpoint,
    ];
    expect(auth, hasLength(5));
  });

  test('onboarding before an account is kept, then committed in order',
      () async {
    final result = await submit('POST /v1/enrolments/consents', 'ob_consent', {
      'ob_programs.programs': ['BreatheFree', 'Heartwise'],
      'ob_consent.essential_app_data': true,
      'ob_consent.private_reminders': true,
    });
    expect(result, const TResult.ok());
    expect(backend.calls, isEmpty, reason: 'nothing leaves before sign-up');
    // A plan and an event recorded as a guest.
    expect(
        await submit('PUT /v1/program-data/hw/targets', 'hw_targets', {
          'hw_targets.top_below': '130',
          'hw_targets.value': null,
          'hw_targets.when_should_we_remind_you': ['Morning'],
        }),
        const TResult.ok());
    expect(
        await submit('POST /v1/program-data/hw/readings', 'hw_log2', {
          'hw_log2.systolic': '128',
          'hw_log2.diastolic': '82',
        }),
        const TResult.queued());
    expect(backend.calls, isEmpty);

    await h.signUp();
    await kit.pending.commitHook(services)(
        PostAuthEvent(accountId: services.accountId!, isNewAccount: true));
    final writes = [
      for (final c in backend.calls)
        if (!c.startsWith('GET')) c,
    ];
    final firstEnrol = writes.indexOf('POST /v1/enrolments');
    final firstConsent = writes.indexOf('POST /v1/enrolments/consents');
    final firstPush = writes.indexOf('POST /v1/sync/push');
    final firstEvent = writes.indexOf('POST /v1/program-data/hw/readings');
    expect(firstEnrol, greaterThanOrEqualTo(0));
    expect(firstEnrol < firstConsent, isTrue);
    expect(firstConsent < firstPush, isTrue);
    expect(firstPush < firstEvent, isTrue);
    final list = (await h.api.enrolments.list()).valueOrNull!;
    expect({for (final e in list.enrolments) e.programmeCode}, {'bf', 'hw'});
    expect(list.enrolments.every((e) => e.consents.length == 2), isTrue);
  });

  test('a safety entry offline is queued and delivered later', () async {
    await h.signUp();
    await h.enrol('ea');
    backend.offline = true;
    expect(
        await submit('POST /v1/program-data/ea/moods', 'ea_mood', {
          'ea_mood.how_are_you_right_now': 'Low',
          'ea_mood.going_on': ['Sleep']
        }),
        const TResult.queued());
    backend.offline = false;
    await services.outbox.flush();
    expect(backend.calls, contains('POST /v1/program-data/ea/moods'));
    expect(await services.outbox.pending(), isEmpty);
  });

  test('a refused event is a failure with its code', () async {
    await h.signUp();
    await h.enrol('hw');
    final r = await submit('POST /v1/program-data/hw/readings', 'hw_log2',
        {'hw_log2.systolic': '300', 'hw_log2.diastolic': '80'});
    expect(r, const TResult.failed('value_out_of_range'));
    final bad = await submit('POST /v1/program-data/hw/readings', 'hw_log2',
        {'hw_log2.systolic': 'abc', 'hw_log2.diastolic': '80'});
    expect(bad, const TResult.failed(HandlerCodes.invalidInput));
  });

  test('a plan save creates the enrolment and stores through sync', () async {
    await h.signUp();
    final r = await submit('PUT /v1/program-data/st/range', 'st_range', {
      'st_range.value': 'mmol/L',
    });
    // No core consent yet for the new enrolment: kept on the phone.
    expect(r, const TResult.queued());
    expect(services.sync.pendingAreas, {'st'});
    final enrolments = (await h.api.enrolments.list()).valueOrNull!.enrolments;
    expect(enrolments.single.programmeCode, 'st');
    expect(backend.calls, contains('POST /v1/sync/push'));
  });

  test('check-in, lapse, catalogue Learn only', () async {
    await h.signUp();
    await h.enrol('bf', status: EnrolmentStatus.focus);
    expect(
        await submit('POST /v1/records/check-ins', 'checkin', {
          'checkin.how_do_you_feel_today': 'Okay',
          'checkin.value': ['No'],
          'checkin.value_2': ['Skip'],
        }),
        const TResult.ok());
    expect(
        await submit('POST /v1/records/lapses', 'bf_slip', {
          'bf_slip.what_happened': ['A puff or two']
        }),
        const TResult.ok());
    expect(services.sync.lapsesOf('bf'), hasLength(1));
    expect(await submit('POST /v1/enrolments', 'ca_intro', {}),
        const TResult.ok());
    final codes = {
      for (final e in (await h.api.enrolments.list()).valueOrNull!.enrolments)
        e.programmeCode: e.status,
    };
    expect(codes['ca'], EnrolmentStatus.learnOnly);
  });

  test('program settings act on the programme the screen was opened for',
      () async {
    await h.signUp();
    await h.enrol('hw', status: EnrolmentStatus.focus);
    final unknown = await submit('PATCH /v1/enrolments/:id', 'program_settings',
        {'program_settings.status': 'Pause'},
        touched: {'program_settings.status'});
    expect(unknown, const TResult.failed(HandlerCodes.programUnknown));
    HandlerKit.programOfScreen = (_) => 'hw';
    final ok = await submit('PATCH /v1/enrolments/:id', 'program_settings', {
      'program_settings.status': 'Pause',
      'program_settings.de_identified_research': true
    }, touched: {
      'program_settings.status',
      'program_settings.de_identified_research'
    });
    expect(ok, const TResult.ok());
    final hw = (await h.api.enrolments.list()).valueOrNull!.enrolments.single;
    expect(hw.status, EnrolmentStatus.paused);
    expect(
        hw.consents.map((c) => c.purpose), contains(ConsentPurpose.research));
  });

  test('notification switches send only what changed', () async {
    await h.signUp();
    final r = await submit(
        'PATCH /v1/notifications/preferences', 'account_notifications', {
      'account_notifications.quiet_hours': false,
      'account_notifications.check_ins_and_plan_reminders': true,
    },
        touched: {
          'account_notifications.check_ins_and_plan_reminders'
        });
    expect(r, const TResult.ok());
    final prefs = (await h.api.records.notificationPreferences()).valueOrNull!;
    expect(prefs.remindersEnabled, isTrue);
    expect(prefs.quietHoursEnabled, isFalse,
        reason: 'untouched: the default stays');
  });

  test('care and records need an account', () async {
    expect(
        await submit('POST /v1/care/connections', 'support_connect',
            {'support_connect.invite_code': 'TETHER-SANDBOX-CLINIC'}),
        const TResult.failed(HandlerCodes.signInRequired));
    await h.signUp();
    expect(
        await submit('POST /v1/care/connections', 'support_connect',
            {'support_connect.invite_code': 'TETHER-SANDBOX-CLINIC'}),
        const TResult.ok());
  });

  test('the Ease safety plan never leaves the phone', () async {
    await h.signUp();
    final r = await submit('PUT device:encrypted/ea/safety-plan', 'ea_plan',
        {'ea_plan.my_warning_signs': 'synthetic'});
    expect(r, const TResult.ok());
    expect(backend.calls, isEmpty);
    expect(deviceStore.documents.values.single, contains('synthetic'));
  });

  test('Unplug is simulated in sandbox mode', () async {
    expect(
        await submit(
            'CALL device:unplug/startSession', 'sf_unplug_session', {}),
        const TResult.ok());
  });

  test('the quit plan is saved only with the date the member chose', () async {
    await h.signUp();
    await h.enrol('bf', status: EnrolmentStatus.focus);
    final noDate = await submit('PUT /v1/quit-plan', 'bf_review', {
      'bf_q1.value': '10 or fewer',
      'bf_path.path': 'Set a quit date',
    });
    expect(noDate, const TResult.ok());
    expect(backend.calls, isNot(contains('PUT /v1/quit-plan')),
        reason: 'no date is invented');
    expect(services.sync.answersOf('bf', 'q1'), isNotNull,
        reason: 'the answers are kept through sync');
    final explore = await submit(
        'PUT /v1/quit-plan', 'bf_review', {'bf_path.path': 'Explore first'});
    expect(explore, const TResult.ok());
    expect(backend.calls, isNot(contains('PUT /v1/quit-plan')));
    TSession.clear();
    final r = await submit('PUT /v1/quit-plan', 'bf_review', {
      'bf_q1.value': '10 or fewer',
      'bf_q3.value': ['Protect my family'],
      'bf_path.path': 'Set a quit date',
      'bf_date.quit_date': '2026-11-02',
    });
    expect(r, const TResult.ok());
    final plan = (await h.api.account.quitPlan()).valueOrNull!;
    expect(plan.dailyCigaretteUse, 'tenOrFewer');
    expect(plan.topQuitReason, 'family');
    expect(plan.quitDate, DateTime(2026, 11, 2));
  });

  test('the codec stores a plan the settings source can read back', () {
    final a = encodeScreen('hw_targets', {'top_below': '130'});
    expect(decodeScreen('hw_targets', a)['top_below'], '130');
  });

  group('account deletion', () {
    Future<TResult> delete() =>
        submit('DELETE /v1/account/data', 'account_delete', {
          'account_delete.type_delete_to_confirm': 'DELETE',
        });

    test('removes the safety plan, sync document and outbox of the account',
        () async {
      await h.signUp();
      final id = services.accountId!;
      await submit('PUT device:encrypted/ea/safety-plan', 'ea_plan',
          {'ea_plan.my_warning_signs': 'synthetic'});
      expect(deviceStore.documents.keys, contains(safetyPlanScope(id)));
      expect(await delete(), const TResult.ok());
      expect(deviceStore.documents.keys.where((k) => k.startsWith('device.')),
          isEmpty);
      final records = await DeletionRecords(deviceStore).all();
      expect(records[id]!['state'], 'complete');
      expect((records[id]!['receipt']! as Map)['requestId'], isNotNull);
      final shown = (await DeletionSource(services).load())!;
      expect(shown['account.deletion.receipt'], isNotNull);
    });

    test('a server failure wipes nothing and keeps no record', () async {
      await h.signUp();
      final id = services.accountId!;
      await submit('PUT device:encrypted/ea/safety-plan', 'ea_plan',
          {'ea_plan.my_warning_signs': 'synthetic'});
      backend.offline = true;
      expect(await delete(), isA<TFailed>());
      expect(deviceStore.documents.keys, contains(safetyPlanScope(id)));
      expect(await DeletionRecords(deviceStore).all(), isEmpty);
    });

    test('an unfinished local cleanup is retried on the next start', () async {
      await h.signUp();
      final id = services.accountId!;
      await DeletionRecords(deviceStore).put(id, {
        'state': 'server_done',
        'receipt': {
          'requestId': 'r-1',
          'completedAt': '2026-10-22T12:00:00.000Z',
          'deleted': <String, int>{},
        },
      });
      await deviceStore.write(safetyPlanScope(id), '{}');
      await resumeUnfinished(kit);
      expect(deviceStore.documents.containsKey(safetyPlanScope(id)), isFalse);
      expect(
          (await DeletionRecords(deviceStore).all())[id]!['state'], 'complete');
    });
  });

  group('consents', () {
    test('each purpose uses its own document in the member\'s language',
        () async {
      await h.signUp();
      await h.api.account.updateProfile(locale: 'es');
      backend.versions = {
        'core/es': 'sandbox-draft-1',
        'reminders/es': 'sandbox-draft-1',
      };
      await submit('POST /v1/enrolments/consents', 'ob_consent', {
        'ob_programs.programs': ['Heartwise'],
        'ob_consent.essential_app_data': true,
        'ob_consent.private_reminders': true,
      });
      final e = (await h.api.enrolments.list()).valueOrNull!.enrolments.single;
      expect({
        for (final c in e.consents) c.purpose: c.locale
      }, {
        ConsentPurpose.core: 'es',
        ConsentPurpose.reminders: 'es',
      });
    });

    test('a refused optional grant keeps the onboarding record to retry',
        () async {
      backend.versions = {'core/en': 'sandbox-draft-1'};
      await submit('POST /v1/enrolments/consents', 'ob_consent', {
        'ob_programs.programs': ['Heartwise'],
        'ob_consent.essential_app_data': true,
        'ob_consent.de_identified_research': true,
      });
      await h.signUp();
      await expectLater(kit.pending.commit(services), throwsStateError);
      expect(await kit.pending.read(), isNotEmpty);
      backend.versions = null;
      await kit.pending.commit(services);
      expect(await kit.pending.read(), isEmpty);
      final e = (await h.api.enrolments.list()).valueOrNull!.enrolments.single;
      expect(e.consents.map((c) => c.purpose),
          containsAll([ConsentPurpose.core, ConsentPurpose.research]));
    });
  });

  group('records', () {
    Future<void> addItems(List<Map<String, Object?>> items) =>
        h.backend.store.transact((state) {
          final data = (state['data']! as Map)[services.accountId] as Map;
          (data['records'] as Map)['items'] = items;
        });

    Map<String, Object?> item(String id, String code, String status,
            {String? category}) =>
        {
          'id': id,
          'code': code,
          'category': category ?? 'lab_result',
          'status': status
        };

    test('review accepts only the programmes the member ticked', () async {
      await h.signUp();
      const a1c = '5a4db0c0-0000-4000-8000-0000000000a1';
      const ldl = '5a4db0c0-0000-4000-8000-0000000000a2';
      await addItems([
        item(a1c, 'a1c', 'pending_review'),
        item(ldl, 'ldl', 'pending_review')
      ]);
      final r = await submit('POST /v1/records/fhir/accept', 'records_review', {
        'records_review.keep_st': ['A1C 7.6%'],
        'records_review.keep_hw': <String>[],
      });
      expect(r, const TResult.ok());
      final items =
          ((await h.api.care.recordItems()).valueOrNull!['items']! as List)
              .cast<Map>();
      expect({for (final i in items) i['code']: i['status']},
          {'a1c': 'accepted', 'ldl': 'pending_review'});
    });

    test('conflict choices go to their own item', () async {
      await h.signUp();
      const bp = '5a4db0c0-0000-4000-8000-0000000000b1';
      const a1c = '5a4db0c0-0000-4000-8000-0000000000b2';
      await addItems([
        item(bp, 'bp', 'conflict', category: 'blood_pressure'),
        item(a1c, 'a1c', 'conflict'),
      ]);
      await submit('POST /v1/records/fhir/conflicts', 'records_conflict', {
        'records_conflict.a1c': 'Keep both',
        'records_conflict.bp': 'Discard',
      });
      final items =
          ((await h.api.care.recordItems()).valueOrNull!['items']! as List)
              .cast<Map>();
      expect({for (final i in items) i['code']: i['status']},
          {'bp': 'rejected', 'a1c': 'accepted'});
    });
  });

  group('Heartwise care summary', () {
    test('no readings: nothing is sent', () async {
      await h.signUp();
      await h.enrol('hw');
      await h.api.care
          .redeemConnection({'inviteCode': 'TETHER-SANDBOX-CLINIC'});
      final r = await submit('POST /v1/care/summaries', 'hw_summary', {});
      expect(r, const TResult.failed('nothing_to_share'));
      expect(backend.calls, isNot(contains('POST /v1/care/summaries')));
    });

    test('sends exactly the preview shown', () async {
      await h.signUp();
      await h.enrol('hw');
      await h.api.care
          .redeemConnection({'inviteCode': 'TETHER-SANDBOX-CLINIC'});
      await shareWithClinic('hw');
      await h.api.events
          .hwReading(idempotencyKey: h.key(), systolic: 130, diastolic: 80);
      final data = AppData(sources: [SummarySource(services, 'hw')]);
      kit = HandlerKit(
        services: services,
        data: data,
        cleaners: DeletionCleaners(),
        postAuthHooks: PostAuthHooks(),
        pending: PendingOnboarding(deviceStore),
      );
      api = AppApi(handlers: handlersFor(kit));
      for (final key in hwSummaryKeys) {
        data.watch(key);
      }
      await data.refresh();
      final preview = data.watch('hw.summary.bp_average').value;
      expect(preview, '130/80 (1 readings)');
      expect(await submit('POST /v1/care/summaries', 'hw_summary', {}),
          const TResult.ok());
      final export = (await h.api.account.export()).valueOrNull!;
      final stored =
          (((export['sandbox']! as Map)['care']! as Map)['summaries']! as List)
              .single as Map;
      expect(
          ((stored['snapshot']! as Map)['preview']!
              as Map)['hw.summary.bp_average'],
          preview);
    });
  });

  test('a zone outside the plan\'s valid range is refused, never green',
      () async {
    await h.signUp();
    await h.enrol('ca');
    final r = await submit('POST /v1/program-data/ca/zone-checks', 'ca_zone',
        {'ca_zone.peak_flow': '2000'});
    expect(r, const TResult.failed(HandlerCodes.invalidInput));
    expect(await services.outbox.pending(), isEmpty);
  });

  test('a missing lab date is refused, not set to today', () async {
    await h.signUp();
    await h.enrol('hw');
    final r = await submit('POST /v1/program-data/hw/lipids', 'hw_lipids',
        {'hw_lipids.ldl': '120'});
    expect(r, const TResult.failed(HandlerCodes.invalidInput));
  });

  test('a clinic share needs that programme\'s share consent', () async {
    await h.signUp();
    await h.enrol('hw');
    await h.api.care.redeemConnection({'inviteCode': 'TETHER-SANDBOX-CLINIC'});
    final refused = await h.api.care.sendSummary(
        {'programmeCode': 'hw', 'snapshot': <String, Object?>{}},
        idempotencyKey: h.key());
    expect(refused.errorOrNull!.wire, 'care_consent_required');
    final message = await h.api.care.sendMessage(
        {'topic': 'Plan', 'message': 'synthetic', 'programmeCode': 'hw'},
        idempotencyKey: h.key());
    expect(message.errorOrNull!.wire, 'care_consent_required');
    final general = await h.api.care.sendMessage(
        {'topic': 'Plan', 'message': 'synthetic'},
        idempotencyKey: h.key());
    expect(general.isSuccess, isTrue);
    await shareWithClinic('hw');
    final shared = await h.api.care.sendSummary(
        {'programmeCode': 'hw', 'snapshot': <String, Object?>{}},
        idempotencyKey: h.key());
    expect(shared.valueOrNull!['delivery'], 'stored');
  });

  test('a deletion interrupted before its answer was stored is finished',
      () async {
    await h.signUp();
    final id = services.accountId!;
    await deviceStore.write(safetyPlanScope(id), '{}');
    await DeletionRecords(deviceStore).put(id, {'state': 'requested'});
    backend.offline = true;
    await resumeUnfinished(kit);
    expect(
        (await DeletionRecords(deviceStore).all())[id]!['state'], 'requested',
        reason: 'never dropped before the cleanup');
    expect(deviceStore.documents.containsKey(safetyPlanScope(id)), isTrue);
    backend.offline = false;
    await resumeUnfinished(kit);
    expect(
        (await DeletionRecords(deviceStore).all())[id]!['state'], 'complete');
    expect(deviceStore.documents.containsKey(safetyPlanScope(id)), isFalse);
  });

  test('an unreadable profile fails the consent closed and keeps the record',
      () async {
    await submit('POST /v1/enrolments/consents', 'ob_consent', {
      'ob_programs.programs': ['Heartwise'],
      'ob_consent.essential_app_data': true,
    });
    await h.signUp();
    backend.failing.add('/v1/profile');
    await expectLater(kit.pending.commit(services), throwsStateError);
    expect(await kit.pending.read(), isNotEmpty);
    final e = (await h.api.enrolments.list()).valueOrNull!.enrolments.single;
    expect(e.consents, isEmpty, reason: 'no consent in a guessed language');
  });

  group('server-unconfirmed deletion', () {
    Future<void> expectState(String id, String state) async =>
        expect((await DeletionRecords(deviceStore).all())[id]!['state'], state);

    test('signed out: local data wiped, never complete', () async {
      await h.signUp();
      final id = services.accountId!;
      await deviceStore.write(safetyPlanScope(id), '{}');
      await DeletionRecords(deviceStore).put(id, {'state': 'requested'});
      await h.backend.auth.signOut();
      await resumeUnfinished(kit);
      await expectState(id, 'server_unconfirmed');
      expect(deviceStore.documents.containsKey(safetyPlanScope(id)), isFalse);
      expect(await pendingServerDeletion(services, id), isTrue);
    });

    test('an expired session never yields complete; the next sign-in does',
        () async {
      await h.signUp();
      final id = services.accountId!;
      await DeletionRecords(deviceStore).put(id, {'state': 'requested'});
      await h.backend.auth.expireSession();
      await resumeUnfinished(kit);
      await expectState(id, 'server_unconfirmed');
      // The same account signs in again: the delete is asked first.
      await h.backend.auth
          .signIn(email: 'member@sandbox.invalid', password: 'synthetic-pass');
      final hook = deletionHook(services, kit.cleaners, kit.pending);
      await expectLater(hook(PostAuthEvent(accountId: id, isNewAccount: false)),
          throwsStateError);
      await expectState(id, 'complete');
      expect(await pendingServerDeletion(services, id), isFalse);
      await expectLater(
          h.backend.auth.signIn(
              email: 'member@sandbox.invalid', password: 'synthetic-pass'),
          throwsA(anything),
          reason: 'the account is gone on the server');
    });

    test('a receipt completes it at once', () async {
      await h.signUp();
      final id = services.accountId!;
      await DeletionRecords(deviceStore).put(id, {'state': 'requested'});
      await resumeUnfinished(kit);
      await expectState(id, 'complete');
      final record = (await DeletionRecords(deviceStore).all())[id]!;
      expect(record['receipt'], isNotNull);
    });

    test('another account\'s sign-in does not run the pending deletion',
        () async {
      await h.signUp();
      final id = services.accountId!;
      await DeletionRecords(deviceStore)
          .put(id, {'state': 'server_unconfirmed', 'accountId': id});
      await h.backend.auth.signOut();
      await h.signUp('other@sandbox.invalid');
      final hook = deletionHook(services, kit.cleaners, kit.pending);
      await hook(
          PostAuthEvent(accountId: services.accountId!, isNewAccount: true));
      await expectState(id, 'server_unconfirmed');
    });
  });
}
