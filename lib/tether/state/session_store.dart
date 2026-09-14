import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../platform/tether_store_api.g.dart';
import 'tether_session.dart';

/// Storage as the shell needs it: three strings and a wipe.
///
/// This exists between [SessionStore] and the generated [TetherStoreApi] for
/// one reason — the app has to run where the channel does not. Web, desktop,
/// and every widget test in this repo have no host on the other end, and the
/// alternative to an interface here is a `_host == null` branch in front of
/// each of the four calls, which is the same conditional written four times
/// and forgotten once.
///
/// It is not an extension point. If a third implementation ever appears,
/// something has gone wrong with the premise that persistence is a key/value
/// store.
abstract interface class SessionStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  /// Drops one key. Used for a snapshot this build cannot read.
  Future<void> remove(String key);

  /// Drops everything. Used when the person asked for deletion.
  Future<void> clear();
}

/// Storage that forgets when the process does.
///
/// Not a stub and not a failure mode: on web and desktop this is the correct
/// behaviour, and the app is fully usable with it. What it must never do is
/// pretend — [SessionStore.isDurable] is false when this is in use, so a
/// screen that wants to tell somebody their data will still be here tomorrow
/// can check first rather than assume.
@visibleForTesting
class MemorySessionStorage implements SessionStorage {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();
}

/// Storage backed by the platform, over `pigeons/tether_store_api.dart`.
class _ChannelStorage implements SessionStorage {
  const _ChannelStorage(this._api);

  final TetherStoreApi _api;

  @override
  Future<String?> read(String key) => _api.read(key);

  @override
  Future<void> write(String key, String value) => _api.write(key, value);

  @override
  Future<void> remove(String key) => _api.remove(key);

  @override
  Future<void> clear() => _api.clear();
}

/// Keeps a [TetherSession] on disk across launches.
///
/// One key, one JSON document, written whole. That is unusual enough to say
/// why: the session is a few kilobytes of enrolments, answers and lapses, and
/// any scheme that wrote parts of it separately would need to keep those parts
/// consistent with each other across a crash. A single document is atomic on
/// both platforms for free, and the cost — rewriting the whole thing when one
/// chip changes — is a rounding error against a `UserDefaults` write.
///
/// Writes are debounced and serialised. Debounced because [TetherSession.setText]
/// fires on every keystroke and the shell has free-text screens in it;
/// serialised because a debounced save must never be allowed to land *after*
/// the deletion that was supposed to remove it, which is exactly the race that
/// leaves a person's record on the device after they asked for it to be gone.
class SessionStore implements SessionPersistence {
  SessionStore._(this._storage, this._key, this._debounce, this.isDurable);

  /// The single key the shell owns. Versioned in the name as well as in the
  /// document, so a future format can be written alongside this one rather
  /// than over it while a migration is being worked out.
  ///
  /// The two numbers are not the same number and this one has deliberately not
  /// moved with [TetherSession.schemaVersion]. A key is a slot, and there is
  /// still one session in one slot; renaming it would leave the old document
  /// sitting in `UserDefaults` forever, unreadable and undeleted, which is a
  /// worse outcome for a health record than losing it. [restore] reads the
  /// document, finds a version this build refuses, and removes it — the
  /// deletion happens because the key stayed the same.
  static const defaultKey = 'tether.session.v1';

  /// Long enough to swallow a burst of typing, short enough that a process
  /// killed by the system loses at most the last sentence. Anything above a
  /// second or so starts trading the person's words for disk writes nobody
  /// was going to notice either way.
  static const defaultDebounce = Duration(milliseconds: 600);

  final SessionStorage _storage;
  final String _key;
  final Duration _debounce;

  /// False when the session is being kept in memory only.
  ///
  /// Not a diagnostic: any copy that offers to keep something for later has to
  /// be able to check this first.
  final bool isDurable;

  Timer? _pending;
  TetherSession? _dirty;

  /// The last document actually written. Skipping an identical rewrite matters
  /// because the seeding accessors on the session touch answers during build.
  String? _written;

  /// Serialises every storage operation, so a save queued before a wipe can
  /// never be applied after it.
  Future<void> _queue = Future<void>.value();

  /// Opens the platform store, falling back to memory when there is none.
  ///
  /// The probe is a real read of the real key. There is no `isSupported()` on
  /// this contract on purpose — a store that answers a read is present, and a
  /// store that throws, times out, or was never registered is absent, and both
  /// of those are the same situation from here. What this must not do is let
  /// the exception out: an app whose shell storage did not come up still has
  /// 236 screens to run, and refusing to start would be a worse outcome than
  /// forgetting.
  ///
  /// [api] is for tests, which have no native side to talk to.
  static Future<SessionStore> open({
    TetherStoreApi? api,
    String key = defaultKey,
    Duration debounce = defaultDebounce,
  }) async {
    final host = api ?? _hostForThisPlatform();
    if (host != null) {
      try {
        await host.read(key);
        return SessionStore._(_ChannelStorage(host), key, debounce, true);
      } catch (error, stack) {
        // Reported rather than swallowed. Falling back is the right behaviour
        // on a desktop build and a bug on a phone, and the only way to tell
        // the two apart afterwards is to have said something at the time.
        _report('open', error, stack);
      }
    }
    return SessionStore._(MemorySessionStorage(), key, debounce, false);
  }

  /// A store that never touches the platform. For tests and for callers that
  /// want the session's autosave wiring without its durability.
  @visibleForTesting
  factory SessionStore.inMemory({
    String key = defaultKey,
    Duration debounce = defaultDebounce,
  }) {
    return SessionStore._(MemorySessionStorage(), key, debounce, false);
  }

  /// The storage behind this store, so a test can assert what is really in it
  /// rather than infer it from a round trip.
  @visibleForTesting
  SessionStorage get storage => _storage;

  static TetherStoreApi? _hostForThisPlatform() {
    if (kIsWeb) return null;
    final target = defaultTargetPlatform;
    if (target != TargetPlatform.iOS && target != TargetPlatform.android) {
      return null;
    }
    return TetherStoreApi();
  }

  /// Loads the stored snapshot into [session], if there is a readable one.
  ///
  /// Call before the first frame and before [TetherSession.bindPersistence].
  /// A session restored after the UI is up would repaint programmes into
  /// existence in front of somebody, and a session bound before it is restored
  /// would race its own snapshot.
  ///
  /// An unreadable snapshot is removed and the session left empty. That is a
  /// real loss and it is still the right call: the alternative is an app that
  /// cannot be opened again until it is reinstalled, and the snapshot was
  /// already unreadable before this method touched it.
  Future<void> restore(TetherSession session) async {
    String? raw;
    try {
      raw = await _enqueue(() => _storage.read(_key));
    } catch (error, stack) {
      _report('restore', error, stack);
      return;
    }
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Session snapshot is not a JSON object.');
      }
      session.restoreFrom(decoded);
      _written = raw;
    } catch (error, stack) {
      _report('restore', error, stack);
      unawaited(_enqueue(() => _storage.remove(_key)));
    }
  }

  /// Writes [session] now, cancelling any debounce already waiting.
  Future<void> save(TetherSession session) async {
    _pending?.cancel();
    _pending = null;
    _dirty = null;

    final document = jsonEncode(session.toJson());
    if (document == _written) return;

    try {
      await _enqueue(() => _storage.write(_key, document));
      _written = document;
    } catch (error, stack) {
      // The session is still correct in memory; only the copy is stale. The
      // UI is not told, because there is nothing it could usefully offer —
      // but the error is reported, because a device that has silently stopped
      // persisting looks exactly like one that is working.
      _report('save', error, stack);
    }
  }

  /// Runs any waiting save immediately and waits for the queue to drain.
  ///
  /// The app calls this when it goes to the background, which is the moment
  /// the debounce stops being a saving of writes and starts being a window in
  /// which the system can kill the process and take the last edit with it.
  Future<void> flush() async {
    final session = _dirty;
    if (session != null) {
      await save(session);
    }
    await _queue;
  }

  // --- SessionPersistence ----------------------------------------------------

  @override
  void sessionChanged(TetherSession session) {
    _dirty = session;
    _pending?.cancel();
    _pending = Timer(_debounce, () => unawaited(save(session)));
  }

  @override
  void sessionErased(TetherSession session) {
    // Cancel first. A save scheduled a moment before the person pressed delete
    // would otherwise fire afterwards and write the record back.
    _pending?.cancel();
    _pending = null;
    _dirty = null;
    _written = null;

    unawaited(
      _enqueue(_storage.clear).catchError((Object error, StackTrace stack) {
        // A deletion that failed is the one failure here that must not pass
        // quietly: the person has been told their data is gone.
        _report('sessionErased', error, stack);
      }),
    );
  }

  /// Stops the debounce timer. Anything already queued still completes.
  void dispose() {
    _pending?.cancel();
    _pending = null;
    _dirty = null;
  }

  /// Chains [action] behind everything already queued and keeps the chain
  /// alive when it fails, so one bad write does not stall every write after it.
  Future<T> _enqueue<T>(Future<T> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then<void>((_) {}).catchError((Object _) {});
    return next;
  }

  static void _report(String call, Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'tether',
        context: ErrorDescription('$call on the Tether session store'),
      ),
    );
  }
}
