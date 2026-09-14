import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_health/tether/data/bundle_loader.dart';
import 'package:tether_health/tether/data/design_bundle.dart';
import 'package:tether_health/tether/platform/tether_store_api.g.dart';
import 'package:tether_health/tether/state/session_store.dart';
import 'package:tether_health/tether/state/tether_session.dart';

import 'tether_bundle_test.dart' show DiskAssetBundle;

/// A platform store, standing in for `UserDefaults` and `SharedPreferences`.
///
/// Extends the generated client rather than reimplementing it, so the calls
/// under test are the same four methods the real channel exposes and a change
/// to the contract breaks this file rather than passing through it.
class _FakeStore extends TetherStoreApi {
  final Map<String, String> values = <String, String>{};

  /// Counted, because "does not write on every keystroke" is a claim about
  /// how many times this was called and cannot be checked any other way.
  int writes = 0;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    writes++;
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clear() async {
    values.clear();
  }
}

/// Persistence, checked against what is actually on the other side.
///
/// The shell holds a person's enrolments, their answers and their lapse
/// history, and until now it forgot all of it when the process ended. Three
/// things have to be true of the fix and none of them are visible on screen:
/// what is written comes back identical, a delete really empties the store,
/// and a build with no platform store still runs. Each has a test here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DesignBundle bundle;

  setUpAll(() async {
    bundle = await BundleLoader.load(bundle: DiskAssetBundle());
  });

  /// A session with something of every kind in it.
  ///
  /// Two programs because the ceiling is two, one of them paused, one hidden
  /// and sharing to a named recipient, all four answer kinds on one screen,
  /// and a lapse with context tags. A round-trip test that only carried
  /// enrolments would pass while losing every note anybody wrote.
  ///
  /// The answers name `digital` rather than floating free, because a stored
  /// answer belongs to one program: see `TetherSession.answersFor`.
  TetherSession populated() {
    final session = TetherSession(bundle: bundle);

    session.join('tobacco');
    session.setHidden('tobacco', hidden: true);
    session.setSharing(
      'tobacco',
      const SharingSetting(
        totalsAndAdherence: true,
        notes: true,
        recipient: 'Dr Reed',
      ),
    );

    session.join('digital');
    session.pause('digital');

    session.toggleChip('digital', 'S12', 0, 2);
    session.toggleChip('digital', 'S12', 0, 5);
    session.chooseOption('digital', 'S12', 1, 3);
    session.setSlider('digital', 'S12', 2, 42);
    session.setText('digital', 'S12', 3, 'harder in the evenings');

    session.recordLapse(
      LapseEvent(
        areaId: 'tobacco',
        at: DateTime.utc(2026, 3, 4, 5, 6),
        severity: 'one cigarette',
        context: const ['stress', 'evening'],
      ),
    );

    return session;
  }

  /// Captures what the store reports instead of letting it fail the test.
  ///
  /// The store reports channel and snapshot failures through
  /// [FlutterError.reportError] rather than swallowing them, which is the
  /// behaviour two of the tests below are actually asserting.
  Future<List<FlutterErrorDetails>> collectingErrors(
    Future<void> Function() body,
  ) async {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    try {
      await body();
    } finally {
      FlutterError.onError = previous;
    }
    return reported;
  }

  group('a session survives the process', () {
    test('everything written comes back identical', () async {
      final host = _FakeStore();
      final store = await SessionStore.open(api: host);
      expect(store.isDurable, isTrue);

      final saved = populated();
      await store.save(saved);
      expect(host.values[SessionStore.defaultKey], isNotNull);

      final restored = TetherSession(bundle: bundle);
      await SessionStore.open(api: host).then((it) => it.restore(restored));

      // The whole document, not a sample of it. Field-by-field assertions
      // pass while quietly losing whatever nobody thought to assert on.
      expect(restored.toJson(), saved.toJson());
    });

    test('each kind of state is genuinely rehydrated', () async {
      final host = _FakeStore();
      final store = await SessionStore.open(api: host);
      await store.save(populated());

      final restored = TetherSession(bundle: bundle);
      await store.restore(restored);

      final tobacco = restored.enrolment('tobacco');
      expect(tobacco.status, EnrolmentStatus.active);
      expect(tobacco.hidden, isTrue);
      expect(tobacco.joinedOn, isNotNull);
      expect(tobacco.sharing.notes, isTrue);
      expect(tobacco.sharing.recipient, 'Dr Reed');
      expect(restored.enrolment('digital').status, EnrolmentStatus.paused);

      // Read through the seeding accessors, because those are what the screens
      // use: a restored answer that the seed overwrote would be invisible to
      // every other assertion in this file.
      expect(restored.chipSelection('digital', 'S12', 0, {9}), {2, 5});
      expect(restored.optionSelection('digital', 'S12', 1, -1), 3);
      expect(restored.sliderValue('digital', 'S12', 2, 0), 42);
      expect(
        restored.textValue('digital', 'S12', 3, ''),
        'harder in the evenings',
      );

      expect(restored.lapses, hasLength(1));
      expect(restored.lapses.single.at, DateTime.utc(2026, 3, 4, 5, 6));
      expect(restored.lapses.single.severity, 'one cigarette');
      expect(restored.lapses.single.context, ['stress', 'evening']);
    });

    test('an identical session is not rewritten', () async {
      final host = _FakeStore();
      final store = await SessionStore.open(api: host);
      final session = populated();

      await store.save(session);
      await store.save(session);

      expect(host.writes, 1);
    });
  });

  group('autosave', () {
    test('coalesces a burst of edits into one write', () async {
      final host = _FakeStore();
      final store = await SessionStore.open(
        api: host,
        debounce: const Duration(milliseconds: 30),
      );

      final session = populated();
      session.bindPersistence(store);

      session.toggleChip('digital', 'S12', 0, 7);
      session.setSlider('digital', 'S12', 2, 55);
      expect(host.writes, 0, reason: 'a change must not write synchronously');

      await Future<void>.delayed(const Duration(milliseconds: 90));
      await store.flush();

      expect(host.writes, 1);
    });

    test('saves typed text, which does not notify listeners', () async {
      // `setText` is deliberately silent so the text field keeps its cursor.
      // Routing saves through `notifyListeners` would therefore have dropped
      // every note in the product, and nothing on screen would have shown it.
      final host = _FakeStore();
      final store = await SessionStore.open(
        api: host,
        debounce: const Duration(milliseconds: 30),
      );

      final session = TetherSession(bundle: bundle);
      var notifications = 0;
      session.addListener(() => notifications++);
      session.bindPersistence(store);

      session.setText('digital', 'S12', 3, 'w');
      session.setText('digital', 'S12', 3, 'wo');
      session.setText('digital', 'S12', 3, 'worse after lunch');
      expect(notifications, 0);

      await Future<void>.delayed(const Duration(milliseconds: 90));
      await store.flush();

      expect(host.writes, 1);
      final document =
          jsonDecode(host.values[SessionStore.defaultKey]!) as Map<String, Object?>;
      final answers = document['answers']! as Map<String, Object?>;
      final screen = answers['digital/S12']! as Map<String, Object?>;
      expect((screen['text']! as Map<String, Object?>)['3'], 'worse after lunch');
    });
  });

  group('deletion is completed rather than hidden', () {
    test('deleteEverything empties the platform store', () async {
      final host = _FakeStore();
      final store = await SessionStore.open(api: host);

      final session = populated();
      session.bindPersistence(store);
      await store.save(session);
      expect(host.values, isNotEmpty);

      session.deleteEverything();
      await store.flush();

      expect(
        host.values,
        isEmpty,
        reason: 'the `export_and_delete` safeguard asks for a deletion that '
            'actually completed. A record left in the platform store is the '
            'exact failure it names.',
      );

      final afterwards = TetherSession(bundle: bundle);
      await store.restore(afterwards);
      expect(afterwards.enrolment('tobacco').isJoined, isFalse);
      expect(afterwards.lapses, isEmpty);
    });

    test('a save queued before the delete cannot land after it', () async {
      final host = _FakeStore();
      final store = await SessionStore.open(
        api: host,
        debounce: const Duration(milliseconds: 30),
      );

      final session = populated();
      session.bindPersistence(store);
      session.toggleChip('digital', 'S12', 0, 1); // Schedules a write.
      session.deleteEverything(); // Must cancel it, not race it.

      await Future<void>.delayed(const Duration(milliseconds: 90));
      await store.flush();

      expect(host.values, isEmpty);
    });
  });

  group('no platform store', () {
    test('a session with no persistence bound still works', () {
      // Most of the repo's 106 other tests construct a session this way. None
      // of them should have acquired a dependency on storage.
      final session = populated();
      expect(session.enrolment('tobacco').isActive, isTrue);
      expect(() => session.deleteEverything(), returnsNormally);
    });

    test('an absent host degrades to memory and says so', () async {
      // Android, so the store really does try the channel; nothing is
      // registered on the other end, which is the web, desktop and test case.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      late SessionStore store;
      final reported = await collectingErrors(() async {
        store = await SessionStore.open();
      });

      expect(store.isDurable, isFalse);
      expect(
        reported,
        hasLength(1),
        reason: 'falling back is correct on desktop and a bug on a phone. '
            'The only way to tell them apart afterwards is to have said '
            'something at the time.',
      );

      // And it is a working store, not a stub that throws.
      final saved = populated();
      await store.save(saved);
      final restored = TetherSession(bundle: bundle);
      await store.restore(restored);
      expect(restored.toJson(), saved.toJson());
    });

    test('the in-memory store round-trips without a binding', () async {
      final store = SessionStore.inMemory();
      expect(store.isDurable, isFalse);

      final saved = populated();
      await store.save(saved);

      final restored = TetherSession(bundle: bundle);
      await store.restore(restored);
      expect(restored.toJson(), saved.toJson());

      saved.bindPersistence(store);
      saved.deleteEverything();
      await store.flush();
      expect((store.storage as MemorySessionStorage).values, isEmpty);
    });
  });

  group('an unreadable snapshot', () {
    test('is reported, discarded, and does not stop the app', () async {
      final host = _FakeStore()
        ..values[SessionStore.defaultKey] = jsonEncode({'version': 99});

      final session = TetherSession(bundle: bundle);
      final store = await SessionStore.open(api: host);
      final reported = await collectingErrors(() => store.restore(session));

      expect(reported, hasLength(1));
      expect(session.toJson()['enrolments'], isEmpty);

      await store.flush();
      expect(
        host.values,
        isEmpty,
        reason: 'a snapshot this build cannot read is removed, or the app '
            'fails the same way on every launch until it is reinstalled.',
      );
    });

    test('malformed JSON is treated the same way', () async {
      final host = _FakeStore()
        ..values[SessionStore.defaultKey] = 'not json at all';

      final session = populated();
      final store = await SessionStore.open(api: host);
      final reported = await collectingErrors(() => store.restore(session));

      expect(reported, hasLength(1));
      // The session it was handed is untouched: a failed restore restores
      // nothing rather than half of something.
      expect(session.enrolment('tobacco').isActive, isTrue);
    });

    test('one bad entry costs one entry, not the snapshot', () async {
      // A lapse with an unparseable date is dropped; the rest survives. This
      // is the distinction the version check is not allowed to blur.
      final saved = populated();
      // Decoded rather than used directly, so this is the same shape that
      // comes back off the platform store rather than the one Dart built.
      final document =
          jsonDecode(jsonEncode(saved.toJson())) as Map<String, Object?>;
      (document['lapses']! as List<Object?>).add(<String, Object?>{
        'area': 'tobacco',
        'at': 'the day before yesterday',
        'severity': 'one cigarette',
        'context': <String>[],
      });

      final restored = TetherSession(bundle: bundle);
      restored.restoreFrom(document);

      expect(restored.lapses, hasLength(1));
      expect(restored.enrolment('tobacco').isActive, isTrue);
    });

    test('an unknown schema version is refused outright', () {
      final session = TetherSession(bundle: bundle);
      expect(
        () => session.restoreFrom(const {'version': 99}),
        throwsFormatException,
      );
    });

    test('a version 1 snapshot is refused rather than migrated', () {
      // Version 1 keyed answers by screen id alone. Two areas share the LookUp
      // product and therefore share every screen id, so `S12` below names no
      // program at all — a migration would have to pick one, and picking wrong
      // files somebody's answers under a programme they were never given in.
      // Refusing costs the answers; guessing costs the segregation.
      final session = TetherSession(bundle: bundle);
      expect(
        () => session.restoreFrom(const {
          'version': 1,
          'enrolments': <Object?>[],
          'answers': {
            'S12': {
              'chips': <String, Object?>{},
              'option': <String, Object?>{},
              'slider': {'2': 42},
              'text': <String, Object?>{},
            },
          },
          'lapses': <Object?>[],
        }),
        throwsFormatException,
      );
    });
  });
}
