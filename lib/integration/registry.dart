// The app's endpoint registry: the production TApi for the tether_ui screens.
//
// Every endpoint string the generated screens submit
// (tether_ui/spec/endpoints.json) has exactly one entry here, naming the one
// service that owns it. Handlers are added by the tickets that wire each
// service; until then a registered endpoint fails with `not_implemented`.
//
// Rules this file enforces for every submit, whatever the handler does:
// - the handler gets an immutable snapshot of the submitting screen's own
//   session keys (plus the entry's declared extra keys), taken before the
//   first await, and an idempotency key for the entry;
// - sign-in and account endpoints never come back as queued;
// - a result that arrives after the session changed is dropped;
// - declared secrets (passwords, the invite code) leave the session after the
//   result;
// - nothing is logged, and a handler that throws gives a code, never the
//   exception.
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:tether_ui/ui/ui.dart';

/// The service that serves an endpoint. One per endpoint.
enum OwnerService {
  /// The app's NestJS API (`api/`).
  api,

  /// The sync service (`sync/`), through push and pull.
  sync,

  /// Supabase Auth.
  supabaseAuth,

  /// Native Unplug calls on the phone (`CALL device:unplug/*`).
  device,

  /// Encrypted storage on the phone (`PUT device:encrypted/*`).
  deviceEncrypted,
}

/// One endpoint of the spec and how the app serves it.
@immutable
class EndpointEntry {
  const EndpointEntry(
    this.endpoint,
    this.owner, {
    this.queueable = true,
    this.safety = false,
    this.extraKeys = const <String>{},
    this.scrubPasswords = false,
    this.scrubKeys = const <String>{},
  });

  /// The endpoint string exactly as the screens submit it.
  final String endpoint;

  /// The one service that serves it.
  final OwnerService owner;

  /// The spec's `queueable` flag (tether_ui/spec/endpoints.json).
  final bool queueable;

  /// A safety endpoint: its saves must be kept on the phone and retried, not
  /// lost, before the tether_ui screens ship.
  final bool safety;

  /// Session keys outside the submitting screen's own prefix that the handler
  /// may read. They never belong to another programme's screens.
  final Set<String> extraKeys;

  /// Whether every password key leaves the session after the result
  /// ([TSession.scrubPasswords]).
  final bool scrubPasswords;

  /// Other session keys that leave the session after the result.
  final Set<String> scrubKeys;

  /// Whether a queued result may stand. False for the spec's non-queueable
  /// endpoints and for every Supabase Auth submit ([isAuthEndpoint]).
  bool get acceptsQueued => queueable && !isAuthEndpoint(endpoint);
}

/// Whether [endpoint] is a Supabase Auth submit. These are never queued,
/// whatever the spec or a hand-written submit says.
bool isAuthEndpoint(String endpoint) =>
    endpoint.startsWith('POST supabase /auth/') ||
    endpoint.startsWith('PUT supabase /auth/');

/// What a handler receives for one submit.
@immutable
class EndpointCall {
  const EndpointCall({
    required this.endpoint,
    required this.screenId,
    required this.payload,
    required this.idempotencyKey,
  });

  final String endpoint;

  /// The submitting screen.
  final String screenId;

  /// The submitting screen's session values (and the entry's extra keys),
  /// copied when the member tapped. Unmodifiable.
  final Map<String, Object?> payload;

  /// The same for a repeat of the same entry from the same screen; new for
  /// changed content or another screen.
  final String idempotencyKey;
}

/// Serves one endpoint. Returns the save's result; it may throw.
typedef EndpointHandler = Future<TResult> Function(EndpointCall call);

/// Finds the screen instance that submits, as a number that is the same for
/// one screen instance and different for every other one. Null when unknown.
typedef ScreenInstanceLookup = int? Function(String screenId);

/// Codes of the failed results this registry gives.
abstract final class RegistryCodes {
  /// A registered endpoint that has no handler yet.
  static const String notImplemented = 'not_implemented';

  /// An endpoint that is not in the registry.
  static const String unregisteredEndpoint = 'unregistered_endpoint';

  /// A handler that threw.
  static const String adapterError = TNav.adapterErrorCode;

  /// A queued result for an endpoint that must not be queued.
  static const String notQueueable = TNav.notQueueableCode;

  /// The session changed (sign-out, account switch, deletion) while the save
  /// was in flight.
  static const String sessionChanged = 'session_changed';
}

/// Every endpoint in tether_ui/spec/endpoints.json, with its service.
const List<EndpointEntry> endpointRegistry = [
  // Native Unplug calls.
  EndpointEntry('CALL device:unplug/endSession', OwnerService.device),
  EndpointEntry(
      'CALL device:unplug/liftShield+purgeLocalData', OwnerService.device),
  EndpointEntry(
      'CALL device:unplug/setThresholds+applyShield', OwnerService.device),
  EndpointEntry('CALL device:unplug/startSession', OwnerService.device),
  // Account, enrolments and consents.
  EndpointEntry('DELETE /v1/account/data', OwnerService.api,
      scrubPasswords: true),
  EndpointEntry('POST /v1/account/export', OwnerService.api),
  EndpointEntry('DELETE /v1/enrolments/:id', OwnerService.api),
  EndpointEntry('PATCH /v1/enrolments/:id', OwnerService.api),
  EndpointEntry('PATCH /v1/enrolments/consents', OwnerService.api),
  EndpointEntry('POST /v1/enrolments/consents', OwnerService.api),
  EndpointEntry('PATCH /v1/notifications/preferences', OwnerService.api),
  // Health records.
  EndpointEntry('DELETE /v1/records/fhir/sources/:id', OwnerService.api),
  EndpointEntry('POST /v1/records/fhir/accept', OwnerService.api),
  EndpointEntry('POST /v1/records/fhir/conflicts', OwnerService.api),
  EndpointEntry('POST /v1/records/fhir/sources/:id/sync', OwnerService.api),
  EndpointEntry('POST /v1/records/manual', OwnerService.api),
  EndpointEntry('POST /v1/records/check-ins', OwnerService.api),
  EndpointEntry('POST /v1/records/lessons', OwnerService.api),
  EndpointEntry('POST /v1/records/rescues', OwnerService.api),
  // Care team.
  EndpointEntry('POST /v1/care/caregivers', OwnerService.api),
  EndpointEntry('POST /v1/care/connections', OwnerService.api,
      scrubKeys: {'support_connect.invite_code'}),
  EndpointEntry('POST /v1/care/messages', OwnerService.api),
  EndpointEntry('POST /v1/care/referrals', OwnerService.api),
  EndpointEntry('POST /v1/care/summaries', OwnerService.api),
  EndpointEntry('POST /v1/care/supporters', OwnerService.api),
  // Quit plan.
  EndpointEntry('PUT /v1/quit-plan', OwnerService.api),
  EndpointEntry('POST /v1/quit-plan/guest-import', OwnerService.api),
  // Programme events.
  EndpointEntry('POST /v1/program-data/be/diary', OwnerService.api),
  EndpointEntry('POST /v1/program-data/be/survivorship', OwnerService.api),
  EndpointEntry('POST /v1/program-data/ca/symptoms', OwnerService.api),
  EndpointEntry('POST /v1/program-data/ca/zone-checks', OwnerService.api,
      safety: true),
  EndpointEntry('POST /v1/program-data/ck/done', OwnerService.api),
  EndpointEntry('POST /v1/program-data/ea/check-backs', OwnerService.api),
  EndpointEntry('POST /v1/program-data/ea/moods', OwnerService.api,
      safety: true),
  EndpointEntry('POST /v1/program-data/hw/lipids', OwnerService.api),
  EndpointEntry('POST /v1/program-data/hw/readings', OwnerService.api,
      safety: true),
  EndpointEntry('POST /v1/program-data/re/labs', OwnerService.api),
  EndpointEntry('POST /v1/program-data/sd/falls', OwnerService.api),
  EndpointEntry('POST /v1/program-data/sd/sessions', OwnerService.api),
  EndpointEntry('POST /v1/program-data/sf/pauses', OwnerService.api),
  EndpointEntry('POST /v1/program-data/st/a1c', OwnerService.api),
  EndpointEntry('POST /v1/program-data/st/readings', OwnerService.api,
      safety: true),
  // Programme plans and answers, and lapses: the sync service.
  EndpointEntry('PUT /v1/program-data/be/profile', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/bf/meds', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/ca/plan', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/ck/profile', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/hw/targets', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/nu/habit', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/re/plan', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/sd/plan', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/sd/safety', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/sf/plan', OwnerService.sync),
  EndpointEntry('PUT /v1/program-data/st/range', OwnerService.sync),
  EndpointEntry('POST /v1/records/lapses', OwnerService.sync),
  // Encrypted on the phone only.
  EndpointEntry(
      'PUT device:encrypted/ea/safety-plan', OwnerService.deviceEncrypted),
  // Supabase Auth: never queued.
  EndpointEntry('POST supabase /auth/v1/recover', OwnerService.supabaseAuth,
      queueable: false),
  EndpointEntry('POST supabase /auth/v1/signup', OwnerService.supabaseAuth,
      queueable: false, scrubPasswords: true),
  EndpointEntry('POST supabase /auth/v1/token', OwnerService.supabaseAuth,
      queueable: false, scrubPasswords: true),
  EndpointEntry('POST supabase /auth/v1/token?grant_type=id_token',
      OwnerService.supabaseAuth,
      queueable: false),
  EndpointEntry('POST supabase /auth/v1/user/identities (linkIdentity)',
      OwnerService.supabaseAuth,
      queueable: false, scrubPasswords: true),
  EndpointEntry('PUT supabase /auth/v1/user', OwnerService.supabaseAuth,
      queueable: false, scrubPasswords: true),
];

/// The production [TApi]: routes each submit to its entry's handler.
///
/// It never throws and logs nothing. See the file comment for the rules it
/// applies to every result.
class AppApi implements TApi {
  AppApi({
    Map<String, EndpointHandler> handlers = const <String, EndpointHandler>{},
    List<EndpointEntry> entries = endpointRegistry,
    ScreenInstanceLookup? screenInstance,
    Random? random,
  })  : _entries = {for (final entry in entries) entry.endpoint: entry},
        _handlers = Map<String, EndpointHandler>.unmodifiable(handlers),
        _screenInstance = screenInstance,
        _random = random ?? Random.secure() {
    if (_entries.length != entries.length) {
      throw ArgumentError('an endpoint is registered twice');
    }
    final unknown = handlers.keys.where((e) => !_entries.containsKey(e));
    if (unknown.isNotEmpty) {
      throw ArgumentError('a handler names an unregistered endpoint');
    }
  }

  final Map<String, EndpointEntry> _entries;
  final Map<String, EndpointHandler> _handlers;
  final ScreenInstanceLookup? _screenInstance;
  final Random _random;

  /// Idempotency keys by (screen instance, screen, endpoint, content hash).
  /// Emptied when the session changes; holds no content. Entries that carry
  /// secrets (passwords, the invite code) and auth submits never enter it:
  /// nothing derived from a secret outlives the scrub.
  final Map<(int?, String, String, int), String> _keys =
      <(int?, String, String, int), String>{};
  int _keysEpoch = TSession.epoch;

  /// Largest number of keys kept before the oldest are dropped.
  static const int _maxKeys = 256;

  /// The entry for [endpoint], or null when it is not registered.
  EndpointEntry? entryFor(String endpoint) => _entries[endpoint];

  @override
  Future<TResult> submit(String endpoint, {required String screenId}) async {
    // Everything up to the handler call runs synchronously, at the tap.
    final epoch = TSession.epoch;
    final entry = _entries[endpoint];
    if (entry == null) {
      return const TResult.failed(RegistryCodes.unregisteredEndpoint);
    }
    TResult result;
    try {
      final payload = _snapshot(screenId, entry);
      final call = EndpointCall(
        endpoint: endpoint,
        screenId: screenId,
        payload: payload,
        idempotencyKey: _idempotencyKey(entry, screenId, payload, epoch),
      );
      final handler = _handlers[endpoint];
      result = handler == null
          ? const TResult.failed(RegistryCodes.notImplemented)
          : await handler(call);
    } catch (_) {
      result = const TResult.failed(RegistryCodes.adapterError);
    }
    if (result is TQueued && !entry.acceptsQueued) {
      result = const TResult.failed(RegistryCodes.notQueueable);
    }
    if (TSession.epoch != epoch) {
      // The session was cleared meanwhile, secrets included; this result
      // belongs to the previous member and must not act on the next one.
      return const TResult.failed(RegistryCodes.sessionChanged);
    }
    _scrub(entry);
    return result;
  }

  Map<String, Object?> _snapshot(String screenId, EndpointEntry entry) {
    final prefix = '$screenId.';
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final MapEntry(:key, :value) in TSession.values.entries)
        if (key.startsWith(prefix) || entry.extraKeys.contains(key))
          key: _frozen(value),
    });
  }

  static Object? _frozen(Object? value) => switch (value) {
        final List<Object?> list => List<Object?>.unmodifiable(
            list.map(_frozen),
          ),
        final Set<Object?> set => Set<Object?>.unmodifiable(set.map(_frozen)),
        final Map<Object?, Object?> map => Map<Object?, Object?>.unmodifiable({
            for (final MapEntry(:key, :value) in map.entries)
              key: _frozen(value),
          }),
        _ => value,
      };

  /// Number of cached idempotency keys (for tests).
  @visibleForTesting
  int get cachedKeyCount => _keys.length;

  String _idempotencyKey(
    EndpointEntry entry,
    String screenId,
    Map<String, Object?> payload,
    int epoch,
  ) {
    if (_keysEpoch != epoch) {
      _keys.clear();
      _keysEpoch = epoch;
    }
    // A fresh key per call for entries with secrets and for auth submits, so
    // no hash of a password or invite code is kept.
    if (entry.scrubPasswords ||
        entry.scrubKeys.isNotEmpty ||
        !entry.acceptsQueued) {
      return _randomKey();
    }
    final id = (
      _screenInstance?.call(screenId),
      screenId,
      entry.endpoint,
      contentHash(payload),
    );
    final existing = _keys[id];
    if (existing != null) return existing;
    if (_keys.length >= _maxKeys) _keys.remove(_keys.keys.first);
    final key = _randomKey();
    _keys[id] = key;
    return key;
  }

  /// 128 random bits as hex. Random, so the key reveals nothing about the
  /// content and never repeats across app launches.
  String _randomKey() => [
        for (var i = 0; i < 16; i++)
          _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join();

  void _scrub(EndpointEntry entry) {
    if (entry.scrubPasswords) TSession.scrubPasswords();
    if (entry.scrubKeys.isNotEmpty) TSession.scrub(entry.scrubKeys);
  }
}

/// A 64-bit FNV-1a hash of a canonical form of [payload], independent of key
/// order. Used only to recognise a repeat of the same content; it is never
/// sent or stored.
@visibleForTesting
int contentHash(Map<String, Object?> payload) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  for (final unit in _canonical(payload).codeUnits) {
    hash ^= unit;
    hash *= prime;
  }
  return hash;
}

/// A form of [value] in which different values never read the same: every
/// string carries its length and every map is sorted by key.
String _canonical(Object? value) => switch (value) {
      null => 'n',
      final bool b => 'b$b',
      final num n => 'd${n.runtimeType}$n',
      final String s => 's${s.length}:$s',
      final Iterable<Object?> list =>
        'l${list.length}[${list.map(_canonical).join(',')}]',
      final Map<Object?, Object?> map => () {
          final entries = [
            for (final MapEntry(:key, :value) in map.entries)
              '${_canonical(key)}=${_canonical(value)}',
          ]..sort();
          return 'm${entries.length}{${entries.join(',')}}';
        }(),
      final Object other => () {
          final text = other.toString();
          return 'o${other.runtimeType}:${text.length}:$text';
        }(),
    };
