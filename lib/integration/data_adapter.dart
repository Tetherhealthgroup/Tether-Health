// The production TData: live values for the tether_ui screens' bound slots
// and settings controls.
//
// Each key has one of three answers:
// - a value: the member's own;
// - TData.unset: loaded, and the member has no value (a display slot shows
//   its example with the "Example" tag; a plan control its designed value;
//   a consent control stays off);
// - null: not loaded (yet, or the load failed).
// It never answers TData.example, which only preview data gives.
//
// Values come from data sources (lib/data/), each covering a set of keys and
// loaded the first time one of its keys is watched. Everything is dropped on
// sign-out, account switch, account deletion and session expiry ([clear]),
// so no value of one member reaches the next.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tether_ui/ui/ui.dart';

/// Loads the values of one group of keys.
abstract interface class DataSource {
  /// Whether [bindKey] is one of this source's keys.
  bool covers(String bindKey);

  /// The values by bind key. A covered key that is missing from the result
  /// has no stored value ([TData.unset]). Null when the load failed: the
  /// keys stay not loaded. Must not throw.
  Future<Map<String, Object?>?> load();
}

/// Called after [AppData.clear] with the account that was signed in when
/// the cache was last filled (null for a guest or when unknown).
typedef DataClearListener = void Function(String? previousAccountId);

/// The production [TData].
class AppData implements TData {
  AppData({
    List<DataSource> sources = const <DataSource>[],
    String? Function()? accountId,
  })  : _sources = List<DataSource>.unmodifiable(sources),
        _accountId = accountId;

  final List<DataSource> _sources;
  final String? Function()? _accountId;
  final Map<String, ValueNotifier<Object?>> _values =
      <String, ValueNotifier<Object?>>{};
  final Map<DataSource, Map<String, Object?>> _loaded =
      <DataSource, Map<String, Object?>>{};
  final Map<DataSource, Future<void>> _loading = <DataSource, Future<void>>{};
  final List<DataClearListener> _clearListeners = <DataClearListener>[];
  int _generation = 0;
  String? _lastAccount;

  /// Remembers [accountId] as the account the cache belongs to, for the
  /// clear listeners.
  void noteAccount(String? accountId) {
    if (accountId != null) _lastAccount = accountId;
  }

  @override
  ValueListenable<Object?> watch(String bindKey) {
    noteAccount(_accountId?.call());
    final existing = _values[bindKey];
    if (existing != null) return existing;
    final notifier = ValueNotifier<Object?>(_answer(bindKey));
    _values[bindKey] = notifier;
    final source = _sourceFor(bindKey);
    if (source != null && !_loaded.containsKey(source)) {
      unawaited(_load(source));
    }
    return notifier;
  }

  DataSource? _sourceFor(String key) {
    for (final source in _sources) {
      if (source.covers(key)) return source;
    }
    return null;
  }

  Object? _answer(String key) {
    final source = _sourceFor(key);
    final values = source == null ? null : _loaded[source];
    if (values == null) return null;
    if (!values.containsKey(key)) return TData.unset;
    final value = values[key];
    if (identical(value, TData.example)) return null; // never the example
    return value ?? TData.unset;
  }

  Future<void> _load(DataSource source) {
    final running = _loading[source];
    if (running != null) return running;
    final generation = _generation;
    final account = _accountId?.call();
    final future = () async {
      Map<String, Object?>? values;
      try {
        values = await source.load();
      } catch (_) {
        values = null;
      }
      // A load that finishes after clear belongs to the previous member.
      if (generation != _generation) return;
      _loading.remove(source);
      if (values == null) return;
      noteAccount(account);
      _loaded[source] = values;
      for (final MapEntry(:key, value: notifier) in _values.entries) {
        if (source.covers(key)) notifier.value = _answer(key);
      }
    }();
    _loading[source] = future;
    return future;
  }

  /// Loads again every source that was loaded, and any with watched keys.
  /// Call after a save and on resume.
  Future<void> refresh() async {
    final wanted = <DataSource>{
      ..._loaded.keys,
      for (final key in _values.keys)
        if (_sourceFor(key) case final s?) s,
    };
    _loaded.removeWhere((s, _) => wanted.contains(s));
    _loading.removeWhere((s, _) => wanted.contains(s));
    await Future.wait([for (final s in wanted) _load(s)]);
  }

  /// Number of keys with a cached listenable (for tests).
  @visibleForTesting
  int get cachedKeys => _values.length;

  /// Runs [listener] after every [clear].
  void addClearListener(DataClearListener listener) =>
      _clearListeners.add(listener);

  /// Drops every cached value. Called on sign-out, account switch, account
  /// deletion and session expiry, so no value of one member reaches the next.
  void clear() {
    _generation++;
    final values = _values.values.toList();
    _values.clear();
    _loaded.clear();
    _loading.clear();
    for (final value in values) {
      value.value = null;
    }
    final previous = _lastAccount;
    _lastAccount = null;
    for (final listener in List<DataClearListener>.of(_clearListeners)) {
      try {
        listener(previous);
      } catch (_) {
        // A failing listener must not stop the others.
      }
    }
  }
}
