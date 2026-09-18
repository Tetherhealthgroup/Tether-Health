import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/sync/sync_client.dart';
import 'package:tether_health/tether/sync/sync_mapper.dart';
import 'package:tether_health/tether/sync/sync_models.dart';
import 'package:tether_health/tether/sync/sync_transport.dart';

/// The sync client, without a server.
///
/// The end-to-end proof lives in `tether_sync_e2e_test.dart`, which talks to a
/// real instance of the service. This file covers the two things that are
/// about *this* code rather than the protocol: that splitting a session
/// document into programmes loses nothing and mixes nothing, and that the
/// client turns the service's answers into the right outcome — including the
/// ones that must not be treated as success.

/// A transport that answers from a script and records what it was asked.
class _FakeTransport implements SyncTransport {
  _FakeTransport(this.responses);

  final List<SyncResponse> responses;
  final sent = <Map<String, Object?>>[];
  var closed = false;

  @override
  Future<SyncResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    sent.add({
      'method': method,
      'path': uri.path,
      'headers': headers,
      'body': body == null ? null : jsonDecode(body),
    });
    return responses.removeAt(0);
  }

  @override
  void close() => closed = true;
}

TetherSyncClient _client(_FakeTransport transport, {String? token = 'tok'}) =>
    TetherSyncClient(
      baseUrl: Uri.parse('https://example.invalid'),
      token: () async => token,
      transport: transport,
    );

/// A session document, schema version 2, spanning two programmes.
Map<String, Object?> _document() => {
      'version': 2,
      'enrolments': [
        {
          'area': 'tobacco',
          'status': 'active',
          'hidden': false,
          'joinedOn': '2026-09-15T07:00:00.000Z',
          'sharing': {
            'totalsAndAdherence': true,
            'notes': false,
            'recipient': null,
          },
        },
        {
          'area': 'metabolic',
          'status': 'paused',
          'hidden': true,
          'joinedOn': null,
          'sharing': {
            'totalsAndAdherence': false,
            'notes': false,
            'recipient': 'Dr Ade',
          },
        },
      ],
      'answers': {
        'tobacco/S05': {
          'chips': {
            '0': [1, 2]
          },
        },
        'tobacco/S13': {
          'slider': {'2': 90.0},
        },
        'metabolic/S05': {
          'text': {'3': 'a note'},
        },
        // Names no programme. Must be dropped, never guessed at.
        'S99': {
          'option': {'0': 1},
        },
      },
      'lapses': [
        {
          'area': 'tobacco',
          'at': '2026-09-15T07:00:00.000Z',
          'severity': 'minor',
          'context': ['stress'],
        },
      ],
    };

void main() {
  group('splitting a document by programme', () {
    test('produces one bundle per area, in the document order', () {
      final bundles = SessionSyncMapper.split(_document());
      expect(bundles.map((bundle) => bundle.area), ['tobacco', 'metabolic']);
    });

    test('files every answer under the programme its key names', () {
      final bundles = SessionSyncMapper.split(_document());
      final tobacco = bundles.firstWhere((b) => b.area == 'tobacco');
      final metabolic = bundles.firstWhere((b) => b.area == 'metabolic');

      expect(tobacco.answers.keys, {'tobacco/S05', 'tobacco/S13'});
      expect(metabolic.answers.keys, {'metabolic/S05'});
    });

    test('keeps the full key, so the server can check attribution', () {
      // The bare screen id would be shorter and would make the server's
      // cross-programme check impossible — it can only compare the prefix if
      // the client sends the string it actually filed the answer under.
      final bundles = SessionSyncMapper.split(_document());
      final tobacco = bundles.firstWhere((b) => b.area == 'tobacco');
      expect(tobacco.answers.containsKey('S05'), isFalse);
      expect(tobacco.answers.containsKey('tobacco/S05'), isTrue);
    });

    test('drops an answer that names no programme', () {
      final bundles = SessionSyncMapper.split(_document());
      final everyKey = [
        for (final bundle in bundles) ...bundle.answers.keys,
      ];
      expect(everyKey, isNot(contains('S99')));
    });

    test('never lets one programme carry another programme data', () {
      // The segregation property, asserted directly. Every key in a bundle
      // must be prefixed with that bundle's own area.
      for (final bundle in SessionSyncMapper.split(_document())) {
        for (final key in bundle.answers.keys) {
          expect(key, startsWith('${bundle.area}/'), reason: bundle.area);
        }
      }
    });

    test('puts each lapse in its own area and drops the repeated field', () {
      final bundles = SessionSyncMapper.split(_document());
      final tobacco = bundles.firstWhere((b) => b.area == 'tobacco');
      expect(tobacco.lapses, hasLength(1));
      expect(tobacco.lapses.single.containsKey('area'), isFalse);
      expect(tobacco.lapses.single['severity'], 'minor');
      expect(bundles.firstWhere((b) => b.area == 'metabolic').lapses, isEmpty);
    });

    test('carries the revision the device last agreed with', () {
      final bundles = SessionSyncMapper.split(
        _document(),
        revisions: {'tobacco': 4},
      );
      expect(bundles.firstWhere((b) => b.area == 'tobacco').baseRevision, 4);
      // Unknown to the server: null means create, not "edit revision 0".
      expect(bundles.firstWhere((b) => b.area == 'metabolic').baseRevision,
          isNull);
    });
  });

  group('merging pulled bundles back', () {
    test('replaces the area it names and leaves the others alone', () {
      final merged = SessionSyncMapper.merge(_document(), [
        const AreaBundle(
          area: 'tobacco',
          revision: 7,
          enrolment: {
            'status': 'ended',
            'hidden': false,
            'joinedOn': null,
            'sharing': {
              'totalsAndAdherence': false,
              'notes': false,
              'recipient': null,
            },
          },
          answers: {
            'tobacco/S01': {
              'option': {'0': 2},
            },
          },
        ),
      ]);

      final enrolments = (merged['enrolments']! as List).cast<Map>();
      expect(
        enrolments.firstWhere((e) => e['area'] == 'tobacco')['status'],
        'ended',
      );
      // Untouched.
      expect(
        enrolments.firstWhere((e) => e['area'] == 'metabolic')['status'],
        'paused',
      );

      final answers = merged['answers']! as Map<String, Object?>;
      // The server's copy of the area replaces the local one wholesale, so the
      // old tobacco answers are gone rather than merged field by field.
      expect(
          answers.keys, containsAll(<String>['tobacco/S01', 'metabolic/S05']));
      expect(answers.containsKey('tobacco/S05'), isFalse);
    });

    test('a revoked bundle removes the programme entirely', () {
      final merged = SessionSyncMapper.merge(
        _document(),
        [const AreaBundle(area: 'tobacco', revision: 9, revoked: true)],
      );

      final enrolments = (merged['enrolments']! as List).cast<Map>();
      expect(enrolments.any((e) => e['area'] == 'tobacco'), isFalse);
      expect(enrolments.any((e) => e['area'] == 'metabolic'), isTrue);

      final answers = merged['answers']! as Map<String, Object?>;
      expect(answers.keys.any((key) => key.startsWith('tobacco/')), isFalse);
      expect(answers.containsKey('metabolic/S05'), isTrue);

      final lapses = (merged['lapses']! as List).cast<Map>();
      expect(lapses.any((l) => l['area'] == 'tobacco'), isFalse);
    });

    test('an empty pull changes nothing', () {
      final before = _document();
      expect(SessionSyncMapper.merge(before, const []), same(before));
    });

    test('a split then a merge is a round trip', () {
      final document = _document();
      final bundles = [
        for (final bundle in SessionSyncMapper.split(document))
          AreaBundle(
            area: bundle.area,
            enrolment: bundle.enrolment,
            answers: bundle.answers,
            lapses: bundle.lapses,
          ),
      ];
      final merged = SessionSyncMapper.merge(document, bundles);

      // Everything that names a programme survives unchanged — and so does
      // the answer that names none. The two halves are conservative in
      // opposite directions on purpose: `split` will not *send* an answer it
      // cannot attribute, and `merge` will not *delete* a local answer the
      // server never mentioned. Both refuse in the direction that keeps the
      // person's data, so a key the protocol cannot carry is stranded on the
      // device rather than destroyed by a sync.
      final answers = merged['answers']! as Map<String, Object?>;
      expect(
        answers.keys,
        {'S99', 'tobacco/S05', 'tobacco/S13', 'metabolic/S05'},
      );
      expect((merged['lapses']! as List), hasLength(1));
      expect((merged['enrolments']! as List), hasLength(2));
    });
  });

  group('the client', () {
    test('sends the bearer token and the right shape', () async {
      final transport = _FakeTransport([
        SyncResponse(
          status: 200,
          body: jsonEncode({
            'cursor': 3,
            'areas': <Object?>[],
            'server_time': '2026-09-15T07:00:00Z',
          }),
        ),
      ]);
      await _client(transport).pull(cursor: 2, areas: ['tobacco']);

      final request = transport.sent.single;
      expect(request['method'], 'POST');
      expect(request['path'], '/v1/sync/pull');
      expect(
        (request['headers']! as Map<String, String>)['authorization'],
        'Bearer tok',
      );
      expect(request['body'], {
        'cursor': 2,
        'areas': ['tobacco'],
      });
    });

    test('reports conflicts without throwing', () async {
      // A conflict is not a failure of the request: some areas were written.
      // Throwing would lose the applied list the caller needs.
      final transport = _FakeTransport([
        SyncResponse(
          status: 200,
          body: jsonEncode({
            'cursor': 9,
            'applied': ['metabolic'],
            'conflicts': [
              {
                'area': 'tobacco',
                'reason': 'stale_revision',
                'base_revision': 2,
                'server_revision': 5,
                'server': {'area': 'tobacco', 'revision': 5},
              },
            ],
            'server_time': '2026-09-15T07:00:00Z',
          }),
        ),
      ]);

      final result = await _client(transport)
          .push([const AreaBundle(area: 'tobacco', baseRevision: 2)]);

      expect(result.applied, ['metabolic']);
      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.single.serverRevision, 5);
      expect(result.conflicts.single.server?.revision, 5);
    });

    test('turns a problem document into a SyncException', () async {
      final transport = _FakeTransport([
        SyncResponse(
          status: 409,
          body: jsonEncode({
            'type': 'https://tetherhealthgroup.com/problems/conflict',
            'title': 'Stale revision',
            'status': 409,
            'detail': 'pull first',
          }),
        ),
      ]);

      await expectLater(
        _client(transport).pull(),
        throwsA(
          isA<SyncException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.title, 'title', 'Stale revision')
              .having((e) => e.isTransient, 'isTransient', isFalse),
        ),
      );
    });

    test('an unreachable service is transient, not a protocol error', () async {
      final transport = _FakeTransport([
        const SyncResponse(status: 0, body: 'SocketException: refused'),
      ]);
      await expectLater(
        _client(transport).pull(),
        throwsA(isA<SyncException>()
            .having((e) => e.isTransient, 'isTransient', isTrue)),
      );
    });

    test('refuses to call without a token', () async {
      // Not a request that comes back 401 — a request that is never sent.
      final transport = _FakeTransport([]);
      await expectLater(
        _client(transport, token: null).pull(),
        throwsA(isA<SyncException>()
            .having((e) => e.isAuthFailure, 'isAuthFailure', isTrue)),
      );
      expect(transport.sent, isEmpty);
    });

    test('does not surface a non-JSON body', () async {
      // A captive portal answering with a login page. Reported by status, not
      // by echoing kilobytes of somebody else's HTML.
      final transport = _FakeTransport([
        const SyncResponse(status: 200, body: '<html>sign in</html>'),
      ]);
      await expectLater(
        _client(transport).pull(),
        throwsA(isA<SyncException>()
            .having((e) => e.title, 'title', contains('not JSON'))),
      );
    });

    test('revoke and erase use DELETE and tolerate an empty body', () async {
      final transport = _FakeTransport([
        const SyncResponse(status: 204, body: ''),
        const SyncResponse(status: 204, body: ''),
      ]);
      final client = _client(transport);
      await client.revoke('tobacco');
      await client.eraseAccount();

      expect(transport.sent.map((r) => r['method']), ['DELETE', 'DELETE']);
      expect(
        transport.sent.map((r) => r['path']),
        ['/v1/sync/areas/tobacco', '/v1/sync/account'],
      );
    });
  });

  group('what the device remembers', () {
    test('a pull advances the cursor and records revisions', () {
      final state = SyncState.empty.withPull(
        PullResult(
          cursor: 12,
          areas: const [
            AreaBundle(area: 'tobacco', revision: 3),
            AreaBundle(area: 'metabolic', revision: 1),
          ],
          serverTime: DateTime.utc(2026, 9, 15),
        ),
      );
      expect(state.cursor, 12);
      expect(state.revisions, {'tobacco': 3, 'metabolic': 1});
    });

    test('survives a round trip through JSON', () {
      const before = SyncState(cursor: 4, revisions: {'tobacco': 2});
      final after = SyncState.fromJson(
        jsonDecode(jsonEncode(before.toJson())) as Map<String, Object?>,
      );
      expect(after.cursor, 4);
      expect(after.revisions, {'tobacco': 2});
    });
  });
}
