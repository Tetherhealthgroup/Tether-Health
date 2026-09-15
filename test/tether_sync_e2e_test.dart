@Tags(['e2e'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/sync/sync_client.dart';
import 'package:tether_health/tether/sync/sync_mapper.dart';
import 'package:tether_health/tether/sync/sync_models.dart';

/// The Dart client against a running instance of the service in `sync/`.
///
/// Everything else about sync is tested against a fake. This is the only test
/// that proves the two halves agree — that the JSON this client builds is the
/// JSON that service accepts, and that what comes back reassembles into the
/// document that went in. A contract asserted on both sides separately is a
/// contract nobody has checked.
///
/// Skipped unless `TETHER_SYNC_URL` and `TETHER_SYNC_TOKEN` are set, so an
/// ordinary `flutter test` stays hermetic and offline. To run it:
///
/// ```bash
/// cd sync
/// export THSYNC_JWT_SECRET='…' THSYNC_DATABASE_URL='sqlite+pysqlite:///./e2e.db'
/// python -c 'from thsync.config import settings_from_env as s; from thsync.db import *; create_schema(create_engine_from_settings(s()))'
/// uvicorn --factory thsync.app:create_app --port 8731 &
/// cd .. && TETHER_SYNC_URL=http://127.0.0.1:8731 TETHER_SYNC_TOKEN="$(…)" \
///   flutter test test/tether_sync_e2e_test.dart
/// ```
void main() {
  final url = Platform.environment['TETHER_SYNC_URL'];
  final token = Platform.environment['TETHER_SYNC_TOKEN'];
  if (url == null || token == null) {
    test('skipped: TETHER_SYNC_URL and TETHER_SYNC_TOKEN are not set', () {},
        skip: 'no live sync service configured');
    return;
  }

  late TetherSyncClient client;

  setUp(() {
    client = TetherSyncClient(
      baseUrl: Uri.parse(url),
      token: () async => token,
    );
  });

  tearDown(() => client.close());

  /// A distinct area per test, so one test's revocation cannot decide
  /// another's outcome when they share an account.
  var counter = 0;
  String freshArea() => 'tobacco${counter++}';

  Map<String, Object?> documentFor(String area, {String note = 'a note'}) => {
        'version': 2,
        'enrolments': [
          {
            'area': area,
            'status': 'active',
            'hidden': false,
            'joinedOn': '2026-09-15T07:00:00.000Z',
            'sharing': {
              'totalsAndAdherence': true,
              'notes': false,
              'recipient': null,
            },
          },
        ],
        'answers': {
          '$area/S05': {
            'chips': {'0': [1, 2]},
            'option': {'1': 3},
            'slider': {'2': 90.0},
            'text': {'3': note},
          },
        },
        'lapses': [
          {
            'area': area,
            'at': '2026-09-15T07:00:00.000Z',
            'severity': 'minor',
            'context': ['stress'],
          },
        ],
      };

  test('the service is reachable', () async {
    final result = await client.pull();
    expect(result.cursor, isNonNegative);
  });

  test('a document survives a push and a pull unchanged', () async {
    final area = freshArea();
    final document = documentFor(area);

    final pushed = await client.push(SessionSyncMapper.split(document));
    expect(pushed.conflicts, isEmpty);
    expect(pushed.applied, contains(area));

    final pulled = await client.pull(areas: [area]);
    final bundle = pulled.areas.firstWhere((b) => b.area == area);

    // Reassembled into a document and compared to the one that went in. This
    // is the assertion that matters: not that the fields survived, but that
    // the thing the app persists is the thing it gets back.
    final restored = SessionSyncMapper.merge(
      {'version': 2, 'enrolments': [], 'answers': {}, 'lapses': []},
      [bundle],
    );

    expect(restored['enrolments'], document['enrolments']);
    expect(restored['answers'], document['answers']);
    expect(restored['lapses'], document['lapses']);
  });

  test('a stale revision conflicts instead of overwriting', () async {
    final area = freshArea();
    final document = documentFor(area, note: 'first');

    final first = await client.push(SessionSyncMapper.split(document));
    expect(first.conflicts, isEmpty);

    final state = SyncState.empty.withPull(await client.pull(areas: [area]));
    final revision = state.revisions[area];
    expect(revision, isNotNull);

    // A second device writes, moving the revision on.
    await client.push(
      SessionSyncMapper.split(
        documentFor(area, note: 'from the other phone'),
        revisions: {area: revision!},
      ),
    );

    // This device still believes the old revision. The write must be refused,
    // not merged — the other phone's note is somebody's record.
    final stale = await client.push(
      SessionSyncMapper.split(
        documentFor(area, note: 'stale'),
        revisions: {area: revision},
      ),
    );

    expect(stale.hasConflicts, isTrue);
    expect(stale.applied, isNot(contains(area)));
    final conflict = stale.conflicts.single;
    expect(conflict.area, area);
    expect(conflict.server, isNotNull);

    // And the other phone's write is what survived.
    final answers = conflict.server!.answers['$area/S05']! as Map;
    expect((answers['text']! as Map)['3'], 'from the other phone');
  });

  test('one programme can be revoked without touching another', () async {
    final keep = freshArea();
    final drop = freshArea();
    await client.push(SessionSyncMapper.split(documentFor(keep)));
    await client.push(SessionSyncMapper.split(documentFor(drop)));

    await client.revoke(drop);

    final pulled = await client.pull();
    final byArea = {for (final b in pulled.areas) b.area: b};

    // A tombstone, so the person's other device learns to delete its copy.
    expect(byArea[drop]?.revoked, isTrue);
    expect(byArea[drop]?.answers, isEmpty);

    // The untouched programme is intact. This is the 42 CFR Part 2 property.
    expect(byArea[keep]?.revoked, isFalse);
    expect(byArea[keep]?.answers, isNotEmpty);
  });

  test('erasing the account removes every programme', () async {
    final area = freshArea();
    await client.push(SessionSyncMapper.split(documentFor(area)));

    await client.eraseAccount();

    final pulled = await client.pull();
    expect(
      pulled.areas.where((b) => !b.revoked),
      isEmpty,
      reason: 'a programme survived an erasure',
    );
  });

  test('a bad token is refused', () async {
    final rejected = TetherSyncClient(
      baseUrl: Uri.parse(url),
      token: () async => '$token-tampered',
    );
    addTearDown(rejected.close);

    await expectLater(
      rejected.pull(),
      throwsA(isA<SyncException>()
          .having((e) => e.isAuthFailure, 'isAuthFailure', isTrue)),
    );
  });
}
