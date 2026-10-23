// The endpoint handlers, end to end against the sandbox backend (and the
// request shapes the http transport would send): coverage, onboarding order,
// outbox, plans through sync, settings, device-only data.
import 'package:breathefree_patient/api/tether_api.dart';
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/backend/post_auth_hooks.dart';
import 'package:breathefree_patient/backend/sandbox/sandbox_backend.dart';
import 'package:breathefree_patient/data/app_services.dart';
import 'package:breathefree_patient/data/sync_codec.dart';
import 'package:breathefree_patient/integration/data_adapter.dart';
import 'package:breathefree_patient/integration/endpoints/common.dart';
import 'package:breathefree_patient/integration/endpoints/device_endpoints.dart';
import 'package:breathefree_patient/integration/endpoints/handlers.dart';
import 'package:breathefree_patient/integration/pending_onboarding.dart';
import 'package:breathefree_patient/integration/registry.dart';
import 'package:breathefree_patient/integration/session_lifecycle.dart';
import 'package:breathefree_patient/sync/sync_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

import '../backend/sandbox/support.dart';

/// The sandbox backend with every request recorded.
class _Recorded implements Backend {
  _Recorded(this.inner);

  final SandboxBackend inner;
  final List<String> calls = [];
  bool offline = false;

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
    services = AppServices(backend,
        syncStore: MemorySyncDocumentStore(),
        outboxStore: MemorySyncDocumentStore());
    kit = HandlerKit(
      services: services,
      data: AppData(),
      cleaners: DeletionCleaners(),
      postAuthHooks: PostAuthHooks(),
      pending: PendingOnboarding(MemorySyncDocumentStore()),
    );
    deviceStore = MemorySyncDocumentStore();
    api = AppApi(handlers: {
      ...handlersFor(kit),
      ...deviceHandlers(kit, store: deviceStore),
    });
    HandlerKit.programOfScreen = null;
    HandlerKit.argumentOfScreen = null;
  });

  tearDown(TSession.clear);

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

  test(
      'the quit plan: a guest keeps it, an account stores it; explore writes none',
      () async {
    await h.signUp();
    final explore = await submit(
        'PUT /v1/quit-plan', 'bf_review', {'bf_path.path': 'Explore first'});
    expect(explore, const TResult.ok());
    expect(backend.calls, isNot(contains('PUT /v1/quit-plan')));
    TSession.clear();
    final r = await submit('PUT /v1/quit-plan', 'bf_review', {
      'bf_q1.value': '10 or fewer',
      'bf_q3.value': ['Protect my family'],
      'bf_path.path': 'Set a quit date',
    });
    expect(r, const TResult.ok());
    final plan = (await h.api.account.quitPlan()).valueOrNull!;
    expect(plan.dailyCigaretteUse, 'tenOrFewer');
    expect(plan.topQuitReason, 'family');
  });

  test('the codec stores a plan the settings source can read back', () {
    final a = encodeScreen('hw_targets', {'top_below': '130'});
    expect(decodeScreen('hw_targets', a)['top_below'], '130');
  });
}
