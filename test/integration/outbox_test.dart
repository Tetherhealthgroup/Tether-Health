// The outbox: send now, else keep encrypted and send later in order;
// bounded; safety entries never dropped; permanent refusals counted; guest
// entries kept until the member merges; wiped per account.
import 'package:breathefree_patient/backend/backend.dart';
import 'package:breathefree_patient/integration/outbox.dart';
import 'package:breathefree_patient/sync/sync_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service implements BackendTransport {
  BackendResponse answer = const BackendOk(201, {'submissionId': 's'});
  final Map<String, BackendResponse> byPath = {};
  final List<String> sent = [];

  @override
  Future<BackendResponse> send(BackendRequest request) async {
    sent.add(request.path);
    return byPath[request.path] ?? answer;
  }
}

OutboxEntry _entry(String kind, {bool safety = false, String key = 'k'}) =>
    OutboxEntry(
      endpoint: 'POST /v1/program-data/$kind',
      path: '/v1/program-data/$kind',
      body: const {'note': 'synthetic'},
      idempotencyKey: key,
      safety: safety,
    );

void main() {
  late _Service service;
  late MemorySyncDocumentStore store;
  String? account = 'acct-1';
  final codes = <String>[];

  Outbox outbox({int maxEntries = 200, int maxBytes = 256 * 1024}) => Outbox(
        transport: service,
        store: store,
        accountId: () => account,
        onCode: codes.add,
        maxEntries: maxEntries,
        maxBytes: maxBytes,
      );

  setUp(() {
    service = _Service();
    store = MemorySyncDocumentStore();
    account = 'acct-1';
    codes.clear();
  });

  test('online: delivered at once, nothing kept', () async {
    final result = await outbox().submit(_entry('sd/falls'));
    expect(result, isA<OutboxDelivered>());
    expect(store.documents, isEmpty);
  });

  test('offline save, restart, delivered in order with its key', () async {
    service.answer = const BackendUnreachable();
    final first = outbox();
    expect(
        await first.submit(_entry('sd/falls', key: 'a')), isA<OutboxQueued>());
    expect(
        await first.submit(_entry('ea/moods', key: 'b')), isA<OutboxQueued>());
    expect(store.documents.keys, ['account.acct-1']);

    service.answer = const BackendOk(201);
    service.sent.clear();
    final restarted = outbox();
    await restarted.flush();
    expect(service.sent,
        ['/v1/program-data/sd/falls', '/v1/program-data/ea/moods']);
    expect(await restarted.pending(), isEmpty);
  });

  test('a 5xx, 429 or expired session keeps the entry', () async {
    for (final answer in const [
      BackendProblem(503, 'server_error'),
      BackendProblem(429, 'rate_limited'),
      BackendProblem(401, 'unauthenticated'),
    ]) {
      service.answer = answer;
      expect(await outbox().submit(_entry('sd/falls')), isA<OutboxQueued>());
    }
    expect(await outbox().pending(), hasLength(3));
  });

  test('a refusal at the tap is a failure, not queued', () async {
    service.answer = const BackendProblem(422, 'value_out_of_range');
    final result = await outbox().submit(_entry('hw/readings', safety: true));
    expect((result as OutboxFailed).code, 'value_out_of_range');
    expect(store.documents, isEmpty);
  });

  test('later permanent refusals: others dropped, safety kept, both noticed',
      () async {
    service.answer = const BackendUnreachable();
    final box = outbox();
    await box.submit(_entry('sd/falls', key: 'a'));
    await box.submit(_entry('hw/readings', safety: true, key: 'b'));
    service.answer = const BackendProblem(409, 'enrolment_left');
    await box.flush();
    final left = await box.pending();
    expect([for (final e in left) e.endpoint],
        ['POST /v1/program-data/hw/readings']);
    expect(left.single.failedCode, 'enrolment_left');
    expect(box.takeNotices(), 2);
    expect(codes, contains(OutboxCodes.rejected));
    await box.flush();
    expect(box.takeNotices(), 0, reason: 'a kept safety entry is told once');
    service.answer = const BackendOk(201);
    await box.flush();
    expect(await box.pending(), isEmpty);
  });

  test('bounded: a save that does not fit fails; safety still fits', () async {
    service.answer = const BackendUnreachable();
    final box = outbox(maxEntries: 2);
    await box.submit(_entry('sd/falls', key: 'a'));
    await box.submit(_entry('sd/falls', key: 'b'));
    final full = await box.submit(_entry('sd/falls', key: 'c'));
    expect((full as OutboxFailed).code, OutboxCodes.full);
    expect(await box.submit(_entry('ea/moods', safety: true, key: 'd')),
        isA<OutboxQueued>());
    final tiny = outbox(maxBytes: 10);
    expect(await tiny.submit(_entry('ea/moods', safety: true, key: 'e')),
        isA<OutboxFailed>());
    expect(await box.pending(), hasLength(3), reason: 'nothing was dropped');
  });

  test('guest entries stay on the phone until adopted', () async {
    account = null;
    final box = outbox();
    expect(await box.submit(_entry('sd/falls')), isA<OutboxQueued>());
    expect(service.sent, isEmpty);
    await box.flush();
    expect(service.sent, isEmpty);
    account = 'acct-2';
    await box.adoptGuest();
    expect(store.documents.containsKey(guestSyncScope), isFalse);
    await box.flush();
    expect(service.sent, ['/v1/program-data/sd/falls']);
  });

  test('each account has its own outbox; wipe removes one', () async {
    service.answer = const BackendUnreachable();
    await outbox().submit(_entry('sd/falls'));
    account = 'acct-2';
    expect(await outbox().pending(), isEmpty);
    await outbox().submit(_entry('sd/falls'));
    await outbox().wipe(accountId: 'acct-1');
    expect(store.documents.keys, ['account.acct-2']);
    await outbox().wipeAll();
    expect(store.documents, isEmpty);
  });

  test('an entry never prints its body', () {
    expect(_entry('ea/moods').toString(), isNot(contains('synthetic')));
  });

  test('an unreadable outbox is kept as it is, never overwritten', () async {
    store.documents['account.acct-1'] = 'not json';
    final result = await outbox().submit(_entry('ea/moods', safety: true));
    expect((result as OutboxFailed).code, OutboxCodes.unreadable);
    expect(store.documents['account.acct-1'], 'not json');
    await outbox().flush();
    expect(store.documents['account.acct-1'], 'not json');
    expect(codes, contains(OutboxCodes.unreadable));
  });
}
