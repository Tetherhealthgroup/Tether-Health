// The local sync document and its sync: pull then push, dropped areas,
// stale revisions, lapse conflicts that never lose a lapse, the guest scope
// and wiping.
import 'dart:convert';

import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/sync/sync_client.dart';
import 'package:breathefree_patient/sync/sync_engine.dart';
import 'package:breathefree_patient/sync/sync_models.dart';
import 'package:breathefree_patient/sync/sync_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_sync_server.dart';

const _meds = ScreenAnswers(option: {'0': 2});
const _plan = ScreenAnswers(text: {'1': 'walk after lunch'});
final _at1 = DateTime.utc(2026, 10, 18, 9);
final _at2 = DateTime.utc(2026, 10, 19, 9);

void main() {
  late FakeSyncServer server;
  late MemorySyncDocumentStore store;
  late SyncEngine engine;

  setUp(() async {
    server = FakeSyncServer()..enrolled.addAll({'bf', 'hw', 'sf'});
    store = MemorySyncDocumentStore();
    engine = SyncEngine(client: SyncClient(server), store: store);
    await engine.open(accountId: 'acct-1');
  });

  test('saves locally, then pushes the whole area with its base revision',
      () async {
    await engine.saveAnswers('bf', 'meds', _meds);
    await engine.appendLapse('bf', Lapse(at: _at1, severity: 'slip'));
    expect(engine.pendingAreas, {'bf'});
    expect(store.documents.keys, ['account.acct-1']);

    expect(await engine.sync(), SyncRunStatus.ok);
    expect(server.revisionOf('bf'), 1);
    expect(server.answerOf('bf/meds'), _meds.toJson());
    expect(server.lapsesOf('bf'), hasLength(1));
    expect(engine.pendingAreas, isEmpty);

    // A second change edits revision 1.
    await engine.saveAnswers(
        'bf', 'meds', const ScreenAnswers(option: {'0': 1}));
    expect(await engine.sync(), SyncRunStatus.ok);
    expect(server.revisionOf('bf'), 2);
  });

  test('the document survives a restart', () async {
    await engine.saveAnswers('hw', 'targets', _plan);
    final again = SyncEngine(client: SyncClient(server), store: store);
    await again.open(accountId: 'acct-1');
    expect(again.answersOf('hw', 'targets'), _plan);
    expect(again.pendingAreas, {'hw'});
  });

  test('a stale revision rebases on the server copy and pushes again',
      () async {
    await engine.saveAnswers('hw', 'targets', _plan);
    expect(await engine.sync(), SyncRunStatus.ok);
    // Another phone changes a different screen meanwhile.
    server.storeFromElsewhere('hw', answers: {
      'hw/other': const ScreenAnswers(option: {'0': 4})
    });
    await engine.saveAnswers(
        'hw', 'targets', const ScreenAnswers(text: {'1': 'swim'}));
    expect(await engine.sync(), SyncRunStatus.ok);
    expect(server.answerOf('hw/targets'), {
      'text': {'1': 'swim'}
    });
    expect(
        server.answerOf('hw/other'),
        {
          'option': {'0': 4}
        },
        reason: 'the other phone\'s screen is kept');
  });

  test('a push conflict reported in the answer is resolved the same way',
      () async {
    await engine.saveAnswers('hw', 'targets', _plan);
    expect(await engine.sync(), SyncRunStatus.ok);
    // The pull sees nothing new (cursor is current), then the server moves
    // on before the push: the push answers with a conflict.
    await engine.saveAnswers(
        'hw', 'targets', const ScreenAnswers(text: {'1': 'run'}));
    final racing = _RacingServer(server);
    final racer = SyncEngine(client: SyncClient(racing), store: store);
    await racer.open(accountId: 'acct-1');
    expect(await racer.sync(), SyncRunStatus.ok);
    expect(server.answerOf('hw/targets'), {
      'text': {'1': 'run'}
    });
    expect(server.answerOf('hw/race'), {
      'option': {'0': 1}
    });
  });

  test('lapse conflict: renumber after the server, dedupe, never lose one',
      () async {
    await engine.appendLapse('bf', Lapse(at: _at1));
    expect(await engine.sync(), SyncRunStatus.ok);
    // Offline, this phone records two lapses; another phone stores one of
    // them (same content) and a different one first.
    await engine.appendLapse('bf', Lapse(at: _at2, severity: 'puff'));
    await engine.appendLapse('bf', Lapse(at: _at2, severity: 'full'));
    final stale = _LapseRaceServer(server);
    final racer = SyncEngine(client: SyncClient(stale), store: store);
    await racer.open(accountId: 'acct-1');
    expect(await racer.sync(), SyncRunStatus.ok);
    final stored = [
      for (final l in server.lapsesOf('bf')) (l['severity'], l['at']),
    ];
    expect(stored, [
      ('', _at1.toIso8601String()),
      ('full', _at2.toIso8601String()),
      ('puff', _at2.toIso8601String()),
    ]);
  });

  test('an area missing from current_areas is dropped with its changes',
      () async {
    await engine.saveAnswers('sf', 'plan', _plan);
    expect(await engine.sync(), SyncRunStatus.ok);
    await engine.saveAnswers(
        'sf', 'plan', const ScreenAnswers(text: {'1': 'x'}));
    server.deleteProgramme('sf');
    expect(await engine.sync(), SyncRunStatus.ok);
    expect(engine.answersOf('sf', 'plan'), isNull);
    expect(engine.pendingAreas, isEmpty);
  });

  test('area_gone discards that area and pushes the others', () async {
    await engine.saveAnswers('hw', 'targets', _plan);
    expect(await engine.sync(), SyncRunStatus.ok);
    await engine.saveAnswers(
        'hw', 'targets', const ScreenAnswers(text: {'1': 'y'}));
    await engine.saveAnswers('bf', 'meds', _meds);
    final gone = _GoneOnPushServer(server, 'hw');
    final racer = SyncEngine(client: SyncClient(gone), store: store);
    await racer.open(accountId: 'acct-1');
    expect(await racer.sync(), SyncRunStatus.ok);
    expect(racer.answersOf('hw', 'targets'), isNull);
    expect(server.answerOf('bf/meds'), _meds.toJson());
  });

  test('consent_required keeps the changes and pushes the other areas',
      () async {
    server.noConsent.add('hw');
    await engine.saveAnswers('hw', 'targets', _plan);
    await engine.saveAnswers('bf', 'meds', _meds);
    expect(await engine.sync(), SyncRunStatus.consentRequired);
    expect(engine.pendingAreas, {'hw'});
    expect(server.answerOf('bf/meds'), _meds.toJson());
    server.noConsent.clear();
    expect(await engine.sync(), SyncRunStatus.ok);
    expect(engine.pendingAreas, isEmpty);
  });

  test('offline and auth failures keep everything on the phone', () async {
    await engine.saveAnswers('bf', 'meds', _meds);
    server.offline = true;
    expect(await engine.sync(), SyncRunStatus.offline);
    server
      ..offline = false
      ..unauthenticated = true;
    expect(await engine.sync(), SyncRunStatus.authFailed);
    expect(engine.pendingAreas, {'bf'});
  });

  test('an unknown cursor starts again from nothing', () async {
    await engine.saveAnswers('bf', 'meds', _meds);
    expect(await engine.sync(), SyncRunStatus.ok);
    final doc = jsonDecode(store.documents['account.acct-1']!) as Map;
    doc['cursor'] = 999;
    store.documents['account.acct-1'] = jsonEncode(doc);
    await engine.open(accountId: 'acct-1');
    expect(await engine.sync(), SyncRunStatus.ok);
    expect(engine.answersOf('bf', 'meds'), _meds);
  });

  group('guest scope', () {
    test('a guest document never leaves the phone', () async {
      await engine.open();
      await engine.saveAnswers('bf', 'meds', _meds);
      expect(await engine.sync(), SyncRunStatus.guest);
      expect(server.calls, isEmpty);
      expect(store.documents.keys, contains(guestSyncScope));
    });

    test('adopting the guest document after agreement uploads it', () async {
      await engine.open();
      await engine.saveAnswers('bf', 'meds', _meds);
      await engine.appendLapse('bf', Lapse(at: _at1));
      await engine.open(accountId: 'acct-1');
      expect(engine.answersOf('bf', 'meds'), isNull,
          reason: 'nothing is merged without agreement');
      await engine.adoptGuest();
      expect(store.documents.containsKey(guestSyncScope), isFalse);
      expect(await engine.sync(), SyncRunStatus.ok);
      expect(server.answerOf('bf/meds'), _meds.toJson());
      expect(server.lapsesOf('bf'), hasLength(1));
    });

    test('adopting needs an open account', () async {
      await engine.open();
      expect(engine.adoptGuest, throwsStateError);
    });
  });

  group('wipe', () {
    test('wipes one account and empties the open document', () async {
      await engine.saveAnswers('bf', 'meds', _meds);
      await engine.wipe(accountId: 'acct-1');
      expect(store.documents, isEmpty);
      expect(engine.answersOf('bf', 'meds'), isNull);
    });

    test('wipeAll removes every scope', () async {
      await engine.saveAnswers('bf', 'meds', _meds);
      await engine.open();
      await engine.saveAnswers('bf', 'meds', _meds);
      await engine.wipeAll();
      expect(store.documents, isEmpty);
    });
  });

  test('rejects unknown programmes and screen ids', () {
    expect(() => engine.saveAnswers('zz', 'plan', _plan), throwsArgumentError);
    expect(() => engine.saveAnswers('bf', 'a/b', _plan), throwsArgumentError);
    expect(
        () => engine.appendLapse('zz', Lapse(at: _at1)), throwsArgumentError);
  });

  test('an unreadable document counts as none', () async {
    store.documents['account.acct-2'] = 'not json';
    await engine.open(accountId: 'acct-2');
    expect(engine.pendingAreas, isEmpty);
  });

  test('nothing private is printed', () {
    expect(_plan.toString(), isNot(contains('walk')));
    expect(
        Lapse(at: _at1, severity: 'slip').toString(), isNot(contains('slip')));
  });
}

/// Lets the pull through, then changes the area on the server before the
/// first push, as another phone would.
class _RacingServer extends FakeSyncServerProxy {
  _RacingServer(super.inner);
  bool _raced = false;

  @override
  void beforePush() {
    if (_raced) return;
    _raced = true;
    inner.storeFromElsewhere('hw', answers: {
      'hw/race': const ScreenAnswers(option: {'0': 1})
    });
  }
}

/// The first push of bf is refused as a lapse conflict (another phone took
/// the ordinal), with the server's lapse already stored.
class _LapseRaceServer extends FakeSyncServerProxy {
  _LapseRaceServer(super.inner);
  bool _done = false;

  @override
  BackendResponse? interceptPush() {
    if (_done) return null;
    _done = true;
    inner.storeFromElsewhere('bf', lapses: [Lapse(at: _at2, severity: 'full')]);
    return const BackendProblem(409, 'lapse_conflict', positions: [0]);
  }
}

/// The first push finds [area] deleted.
class _GoneOnPushServer extends FakeSyncServerProxy {
  _GoneOnPushServer(super.inner, this.area);
  final String area;
  bool _done = false;

  @override
  void beforePush() {
    if (_done) return;
    _done = true;
    inner.deleteProgramme(area);
    inner.enrolled.add(area); // re-enrolled, but the old area is gone
  }
}
