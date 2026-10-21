// The production TData: live values for the tether_ui screens' bound slots.
//
// No values are wired yet (the data tickets fill them), so every key has no
// value and each slot shows its empty state. It never answers TData.example,
// which would show the spec's sample values as if they were the member's.
import 'package:flutter/foundation.dart';
import 'package:tether_ui/ui/ui.dart';

/// The production [TData].
class AppData implements TData {
  final Map<String, ValueNotifier<Object?>> _values =
      <String, ValueNotifier<Object?>>{};

  @override
  ValueListenable<Object?> watch(String bindKey) =>
      _values.putIfAbsent(bindKey, () => ValueNotifier<Object?>(null));

  /// Number of keys with a cached listenable (for tests).
  @visibleForTesting
  int get cachedKeys => _values.length;

  /// Drops every cached value. Called on sign-out, account switch, account
  /// deletion and session expiry, so no value of one member reaches the next.
  void clear() {
    final values = _values.values.toList();
    _values.clear();
    for (final value in values) {
      value.value = null;
    }
  }
}
