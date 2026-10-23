// The endpoint registry: one entry and one service per spec endpoint, and
// the rules every submit gets whatever its handler does.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:breathefree_patient/integration/registry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

/// Synthetic content that must never be logged or appear in a key.
const _canary = 'canary-synthetic-user-01-bp-187-121';

List<Map<String, dynamic>> _specEndpoints() =>
    (jsonDecode(File('tether_ui/spec/endpoints.json').readAsStringSync())
            as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// Every endpoint the generated screens submit.
Set<String> _generatedSubmits() {
  final submit = RegExp(r"TNav\.submit\(context, '([^']+)'");
  return {
    for (final file in Directory('tether_ui/flutter/lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart')))
      ...submit
          .allMatches(file.readAsStringSync())
          .map((match) => match.group(1)!),
  };
}

/// The service an endpoint belongs to under the route ownership table.
OwnerService _expectedOwner(String endpoint) {
  if (endpoint.startsWith('CALL device:unplug/')) return OwnerService.device;
  if (endpoint.startsWith('PUT device:encrypted/')) {
    return OwnerService.deviceEncrypted;
  }
  if (endpoint.contains(' supabase /auth/')) return OwnerService.supabaseAuth;
  if (endpoint.startsWith('PUT /v1/program-data/') ||
      endpoint == 'POST /v1/records/lapses') {
    return OwnerService.sync;
  }
  return OwnerService.api;
}

/// Collects everything printed while [body] runs.
Future<List<String>> _printed(Future<void> Function() body) async {
  final lines = <String>[];
  final previous = debugPrint;
  debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
  try {
    await runZoned(body,
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => lines.add(line),
        ));
  } finally {
    debugPrint = previous;
  }
  return lines;
}

/// A handler that records its calls and answers [result].
class _Recorder {
  TResult result = const TResult.ok();
  final List<EndpointCall> calls = [];
  Completer<void>? gate;

  Future<TResult> call(EndpointCall call) async {
    calls.add(call);
    final wait = gate;
    if (wait != null) await wait.future;
    return result;
  }
}

void _clearSession() {
  TSession.values.clear();
}

void main() {
  setUp(_clearSession);
  tearDown(_clearSession);

  group('entries', () {
    test('match the spec endpoints exactly, one entry each', () {
      final spec = _specEndpoints();
      expect(spec, hasLength(61));
      final registered = [for (final e in endpointRegistry) e.endpoint];
      expect(registered.toSet(), hasLength(registered.length),
          reason: 'an endpoint is registered twice');
      expect(registered.toSet(), {for (final e in spec) e['endpoint']});
      expect(() => AppApi(), returnsNormally);
    });

    test('match every endpoint the generated screens submit', () {
      expect(
        {for (final e in endpointRegistry) e.endpoint},
        _generatedSubmits(),
      );
    });

    test('match the submits in spec/actions.json', () {
      final actions = (jsonDecode(
        File('tether_ui/spec/actions.json').readAsStringSync(),
      ) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final summaries = actions.map((a) => a['summary'] as String).join('\n');
      for (final entry in endpointRegistry) {
        expect(summaries, contains(entry.endpoint), reason: entry.endpoint);
      }
      for (final action in actions.where((a) => a['type'] == 'submit')) {
        final endpoint = (action['summary'] as String).split(' then ').first;
        expect(AppApi().entryFor(endpoint), isNotNull, reason: endpoint);
      }
    });

    test('each endpoint has the one service the ownership table gives', () {
      for (final entry in endpointRegistry) {
        expect(entry.owner, _expectedOwner(entry.endpoint),
            reason: entry.endpoint);
      }
      expect(
        endpointRegistry.where((e) => e.owner == OwnerService.sync),
        hasLength(12),
      );
    });

    test('an endpoint registered twice is rejected', () {
      expect(
        () => AppApi(entries: const [
          EndpointEntry('POST /v1/records/check-ins', OwnerService.api),
          EndpointEntry('POST /v1/records/check-ins', OwnerService.sync),
        ]),
        throwsArgumentError,
      );
    });

    test('a handler for an unregistered endpoint is rejected', () {
      expect(
        () => AppApi(handlers: {'POST /v1/nowhere': (_) async => const TOk()}),
        throwsArgumentError,
      );
    });

    test('queueable flags match the spec; all five auth endpoints are not', () {
      final spec = {
        for (final e in _specEndpoints()) e['endpoint']: e['queueable'],
      };
      for (final entry in endpointRegistry) {
        expect(entry.queueable, spec[entry.endpoint], reason: entry.endpoint);
        expect(entry.acceptsQueued, entry.queueable,
            reason: '${entry.endpoint}: auth and enrolment endpoints only');
      }
      final auth = endpointRegistry.where((e) => isAuthEndpoint(e.endpoint));
      expect(auth, hasLength(5));
      expect(auth.every((e) => !e.acceptsQueued), isTrue);
      expect(spec.values.where((q) => q == false), hasLength(6));
    });

    test('the four safety endpoints are flagged, and only they', () {
      expect(
        {
          for (final e in endpointRegistry)
            if (e.safety) e.endpoint,
        },
        {
          'POST /v1/program-data/ea/moods',
          'POST /v1/program-data/hw/readings',
          'POST /v1/program-data/st/readings',
          'POST /v1/program-data/ca/zone-checks',
        },
      );
    });

    test('every endpoint submitted from a password screen scrubs passwords',
        () {
      final screens = jsonDecode(
        File('tether_ui/spec/screens.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      Set<String> keysOf(Object? node) => switch (node) {
            {'key': final String key} && final Map<String, dynamic> map => {
                key,
                for (final v in map.values) ...keysOf(v),
              },
            final Map<String, dynamic> map => {
                for (final v in map.values) ...keysOf(v),
              },
            final List<dynamic> list => {for (final v in list) ...keysOf(v)},
            _ => const <String>{},
          };
      final passwordScreens = {
        for (final MapEntry(:key, :value) in screens.entries)
          if (keysOf(value).map((k) => '$key.$k').any(TSession.isPasswordKey))
            key,
      };
      expect(passwordScreens, isNotEmpty);
      final api = AppApi();
      for (final spec in _specEndpoints()) {
        final fromPasswordScreen =
            (spec['screens'] as List<dynamic>).any(passwordScreens.contains);
        expect(api.entryFor(spec['endpoint'] as String)!.scrubPasswords,
            fromPasswordScreen,
            reason: spec['endpoint'] as String);
      }
      expect(api.entryFor('POST /v1/care/connections')!.scrubKeys,
          {'support_connect.invite_code'});
    });

    test("declared extra keys never belong to another programme's screen", () {
      final screens = jsonDecode(
        File('tether_ui/spec/screens.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      String? programOf(String screenId) =>
          (screens[screenId] as Map<String, dynamic>?)?['program'] as String?;
      final specScreens = {
        for (final e in _specEndpoints())
          e['endpoint']: (e['screens'] as List<dynamic>).cast<String>(),
      };
      for (final entry in endpointRegistry) {
        final programs = specScreens[entry.endpoint]!.map(programOf).toSet();
        for (final key in entry.extraKeys) {
          final screen = key.split('.').first;
          expect(screens.containsKey(screen), isTrue, reason: key);
          expect(programs, {programOf(screen)},
              reason: '${entry.endpoint} reads $key across programmes');
        }
      }
    });
  });

  group('submit', () {
    test('an unknown endpoint fails with unregistered_endpoint', () async {
      expect(
        await AppApi().submit('POST /v1/nowhere', screenId: 'checkin'),
        const TResult.failed(RegistryCodes.unregisteredEndpoint),
      );
    });

    test('a registered endpoint with no handler fails with not_implemented',
        () async {
      for (final entry in endpointRegistry) {
        expect(
          await AppApi().submit(entry.endpoint, screenId: 'checkin'),
          const TResult.failed(RegistryCodes.notImplemented),
          reason: entry.endpoint,
        );
      }
    });

    test('a handler that throws gives adapter_error and logs nothing',
        () async {
      final printed = await _printed(() async {
        final api = AppApi(handlers: {
          'POST /v1/records/check-ins': (_) async => throw StateError(_canary),
          'POST /v1/records/rescues': (_) => throw StateError(_canary),
        });
        expect(
          await api.submit('POST /v1/records/check-ins', screenId: 'checkin'),
          const TResult.failed(RegistryCodes.adapterError),
        );
        expect(
          await api.submit('POST /v1/records/rescues',
              screenId: 'rescue_result'),
          const TResult.failed(RegistryCodes.adapterError),
        );
      });
      expect(printed, isEmpty);
    });

    test('a queued result on an auth endpoint becomes not_queueable', () async {
      final handlers = {
        for (final e in endpointRegistry.where((e) => !e.acceptsQueued))
          e.endpoint: (EndpointCall _) async => const TResult.queued(),
      };
      expect(handlers, hasLength(6));
      final api = AppApi(handlers: handlers);
      for (final endpoint in handlers.keys) {
        expect(
          await api.submit(endpoint, screenId: 'auth_signin'),
          const TResult.failed(RegistryCodes.notQueueable),
          reason: endpoint,
        );
      }
    });

    test('a hand-written auth submit is never queued, whatever its flag',
        () async {
      for (final endpoint in [
        'POST supabase /auth/v1/otp',
        'PUT supabase /auth/v1/factors',
      ]) {
        final api = AppApi(
          entries: [EndpointEntry(endpoint, OwnerService.supabaseAuth)],
          handlers: {endpoint: (_) async => const TResult.queued()},
        );
        expect(api.entryFor(endpoint)!.acceptsQueued, isFalse);
        expect(
          await api.submit(endpoint, screenId: 'auth_signin'),
          const TResult.failed(RegistryCodes.notQueueable),
        );
      }
    });

    test('a queued result on a queueable endpoint stands', () async {
      final api = AppApi(handlers: {
        'POST /v1/program-data/hw/readings': (_) async => const TQueued(),
      });
      expect(
        await api.submit('POST /v1/program-data/hw/readings',
            screenId: 'hw_log2'),
        const TResult.queued(),
      );
    });

    test('ok and outcome results pass through', () async {
      final recorder = _Recorder();
      final api =
          AppApi(handlers: {'POST /v1/records/check-ins': recorder.call});
      expect(
        await api.submit('POST /v1/records/check-ins', screenId: 'checkin'),
        const TResult.ok(),
      );
      recorder.result = const TResult.outcome('Yes');
      expect(
        await api.submit('POST /v1/records/check-ins', screenId: 'checkin'),
        const TResult.outcome('Yes'),
      );
    });

    test('a result after the session changed becomes session_changed',
        () async {
      final recorder = _Recorder()..gate = Completer<void>();
      final api =
          AppApi(handlers: {'POST /v1/records/check-ins': recorder.call});
      final pending =
          api.submit('POST /v1/records/check-ins', screenId: 'checkin');
      TSession.clear();
      recorder.gate!.complete();
      expect(await pending, const TResult.failed(RegistryCodes.sessionChanged));
    });

    test('the epoch is taken at the call, not when the result arrives',
        () async {
      final recorder = _Recorder()..gate = Completer<void>();
      final api =
          AppApi(handlers: {'POST /v1/records/check-ins': recorder.call});
      TSession.clear(); // before the call: not a change for this submit
      final pending =
          api.submit('POST /v1/records/check-ins', screenId: 'checkin');
      recorder.gate!.complete();
      expect(await pending, const TResult.ok());
    });

    test('after the session changed, the new session is not scrubbed',
        () async {
      final recorder = _Recorder()..gate = Completer<void>();
      final api =
          AppApi(handlers: {'POST supabase /auth/v1/token': recorder.call});
      final pending =
          api.submit('POST supabase /auth/v1/token', screenId: 'auth_signin');
      TSession.clear();
      TSession.set('auth_signin.password', 'next-member-typing');
      recorder.gate!.complete();
      expect(await pending, const TResult.failed(RegistryCodes.sessionChanged));
      expect(TSession.values['auth_signin.password'], 'next-member-typing');
    });
  });

  group('payload snapshot', () {
    test('is taken at the call; later session changes do not reach it',
        () async {
      final recorder = _Recorder()..gate = Completer<void>();
      final api =
          AppApi(handlers: {'POST /v1/records/check-ins': recorder.call});
      TSession.set('checkin.mood', 'Okay');
      TSession.set('checkin.tags', ['Sleep']);
      final pending =
          api.submit('POST /v1/records/check-ins', screenId: 'checkin');
      // Synchronously after the call, before any await: the handler has its
      // snapshot already.
      expect(recorder.calls, hasLength(1));
      TSession.set('checkin.mood', 'Changed');
      (TSession.values['checkin.tags']! as List).add('Changed');
      TSession.set('checkin.extra', 'added later');
      recorder.gate!.complete();
      await pending;
      expect(recorder.calls.single.payload, {
        'checkin.mood': 'Okay',
        'checkin.tags': ['Sleep'],
      });
    });

    test('is unmodifiable', () async {
      final recorder = _Recorder();
      final api =
          AppApi(handlers: {'POST /v1/records/check-ins': recorder.call});
      TSession.set('checkin.tags', ['Sleep']);
      await api.submit('POST /v1/records/check-ins', screenId: 'checkin');
      final payload = recorder.calls.single.payload;
      expect(() => payload['checkin.mood'] = 'x', throwsUnsupportedError);
      expect(() => (payload['checkin.tags']! as List).add('x'),
          throwsUnsupportedError);
    });

    test("holds only the screen's own keys, never another screen's", () async {
      final recorder = _Recorder();
      final api = AppApi(handlers: {'POST /v1/records/lapses': recorder.call});
      TSession.set('bf_slip.when', 'Today');
      TSession.set('sf_slip.when', 'Yesterday');
      TSession.set('bf_slipper.x', 'similar prefix');
      TSession.set('auth_signin.password', 'not-for-this-screen');
      await api.submit('POST /v1/records/lapses', screenId: 'bf_slip');
      await api.submit('POST /v1/records/lapses', screenId: 'sf_slip');
      expect(recorder.calls[0].payload, {'bf_slip.when': 'Today'});
      expect(recorder.calls[1].payload, {'sf_slip.when': 'Yesterday'});
    });

    test('adds declared extra keys and nothing else', () async {
      final recorder = _Recorder();
      const endpoint = 'POST /v1/program-data/hw/readings';
      final api = AppApi(
        entries: const [
          EndpointEntry(endpoint, OwnerService.api,
              extraKeys: {'hw_log.systolic'}),
        ],
        handlers: {endpoint: recorder.call},
      );
      TSession.set('hw_log.systolic', 120);
      TSession.set('hw_log.diastolic', 80);
      TSession.set('hw_log2.systolic', 122);
      await api.submit(endpoint, screenId: 'hw_log2');
      expect(recorder.calls.single.payload,
          {'hw_log.systolic': 120, 'hw_log2.systolic': 122});
    });
  });

  group('scrub', () {
    final outcomes = <String, EndpointHandler?>{
      'ok': (_) async => const TResult.ok(),
      'failed': (_) async => const TResult.failed('server_error'),
      'throws': (_) async => throw StateError(_canary),
      'no handler': null,
    };
    for (final MapEntry(key: name, value: handler) in outcomes.entries) {
      test('passwords leave the session after $name', () async {
        const endpoint = 'POST supabase /auth/v1/token';
        final api = AppApi(handlers: {if (handler != null) endpoint: handler});
        TSession.set('auth_signin.email', 'synthetic-user-01@example.test');
        TSession.set('auth_signin.password', _canary);
        TSession.set('auth_newpass.new_password', _canary);
        await api.submit(endpoint, screenId: 'auth_signin');
        expect(TSession.values.keys, ['auth_signin.email']);
      });

      test('the invite code leaves the session after $name', () async {
        const endpoint = 'POST /v1/care/connections';
        final api = AppApi(handlers: {if (handler != null) endpoint: handler});
        TSession.set('support_connect.invite_code', 'SYNTH-0001');
        TSession.set('support_connect.note', 'kept');
        await api.submit(endpoint, screenId: 'support_connect');
        expect(TSession.values.keys, ['support_connect.note']);
      });
    }

    test('endpoints without secrets leave the session as it was', () async {
      final api = AppApi(handlers: {
        'POST /v1/records/check-ins': (_) async => const TResult.ok(),
      });
      TSession.set('checkin.mood', 'Okay');
      TSession.set('auth_signin.password', 'typed-elsewhere');
      await api.submit('POST /v1/records/check-ins', screenId: 'checkin');
      expect(TSession.values.keys, ['checkin.mood', 'auth_signin.password']);
    });
  });

  group('idempotency key', () {
    late Map<String, int?> instance;
    late _Recorder recorder;
    late AppApi api;

    setUp(() {
      instance = {'checkin': 1};
      recorder = _Recorder();
      api = AppApi(
        handlers: {'POST /v1/records/check-ins': recorder.call},
        screenInstance: (screenId) => instance[screenId],
        random: Random(7),
      );
    });

    Future<String> tap() async {
      await api.submit('POST /v1/records/check-ins', screenId: 'checkin');
      return recorder.calls.last.idempotencyKey;
    }

    test('is the same for a same-content re-tap on the same screen', () async {
      TSession.set('checkin.mood', 'Okay');
      final first = await tap();
      expect(await tap(), first);
    });

    test('is new for changed content', () async {
      TSession.set('checkin.mood', 'Okay');
      final first = await tap();
      TSession.set('checkin.mood', 'Good');
      expect(await tap(), isNot(first));
    });

    test('is new for another screen instance with the same content', () async {
      TSession.set('checkin.mood', 'Okay');
      final first = await tap();
      instance['checkin'] = 2;
      expect(await tap(), isNot(first));
    });

    test('is new after the session changed', () async {
      TSession.set('checkin.mood', 'Okay');
      final first = await tap();
      TSession.clear();
      TSession.set('checkin.mood', 'Okay');
      expect(await tap(), isNot(first));
    });

    test('does not depend on key order', () async {
      TSession.set('checkin.mood', 'Okay');
      TSession.set('checkin.note', 'n');
      final first = await tap();
      TSession.set('checkin.mood', 'Okay'); // moves the key to the end
      expect(await tap(), first);
    });

    test('is random hex and carries no content', () async {
      TSession.set('checkin.mood', _canary);
      final key = await tap();
      expect(key, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(key, isNot(contains('canary')));
    });

    test('no cached key is derived from a payload with secrets', () async {
      final keys = <String>[];
      final secretApi = AppApi(handlers: {
        for (final endpoint in [
          'POST supabase /auth/v1/token',
          'POST supabase /auth/v1/recover',
          'POST /v1/care/connections',
          'DELETE /v1/account/data',
        ])
          endpoint: (call) async {
            keys.add(call.idempotencyKey);
            return const TResult.ok();
          },
      });
      for (var i = 0; i < 2; i++) {
        TSession.set('auth_signin.email', 'synthetic-user-01@example.test');
        TSession.set('auth_signin.password', _canary);
        await secretApi.submit('POST supabase /auth/v1/token',
            screenId: 'auth_signin');
        TSession.set('auth_forgot.email', 'synthetic-user-01@example.test');
        await secretApi.submit('POST supabase /auth/v1/recover',
            screenId: 'auth_forgot');
        TSession.set('support_connect.invite_code', 'SYNTH-0001');
        await secretApi.submit('POST /v1/care/connections',
            screenId: 'support_connect');
        TSession.set('account_delete.password', _canary);
        await secretApi.submit('DELETE /v1/account/data',
            screenId: 'account_delete');
      }
      expect(secretApi.cachedKeyCount, 0);
      expect(keys.toSet(), hasLength(keys.length),
          reason: 'every such submit gets a fresh key');

      TSession.set('checkin.mood', 'Okay');
      await api.submit('POST /v1/records/check-ins', screenId: 'checkin');
      expect(api.cachedKeyCount, 1,
          reason: 'health saves keep their stable key');
    });

    test('content hashes tell close values apart', () {
      expect(contentHash({'a': '1'}), isNot(contentHash({'a': 1})));
      expect(
          contentHash({'a': 'b,c'}),
          isNot(contentHash({
            'a': ['b', 'c']
          })));
      expect(contentHash({'a': '', 'b': ''}),
          isNot(contentHash({'a': 'b', '': ''})));
      expect(contentHash({'a': 1, 'b': 2}), contentHash({'b': 2, 'a': 1}));
    });
  });

  test('a full set of submits prints nothing', () async {
    final printed = await _printed(() async {
      final api = AppApi(handlers: {
        for (final e in endpointRegistry)
          e.endpoint: (_) async => const TOutcome(_canary),
      });
      TSession.set('checkin.mood', _canary);
      for (final e in endpointRegistry) {
        await api.submit(e.endpoint, screenId: 'checkin');
      }
      await api.submit('POST /v1/nowhere', screenId: 'checkin');
    });
    expect(printed, isEmpty);
  });
}
