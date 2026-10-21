// AppData has no value for any bound slot yet, never the spec's example
// value, and drops its cache on clear.
import 'package:breathefree_patient/integration/data_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tether_ui/ui/ui.dart';

/// Bind keys used in the kit's documentation and tests, plus unknown ones.
/// The generated screens bind no slot yet, so every key counts.
const _keys = [
  'hw.last_bp',
  'hw.week',
  'records.recent',
  'today.streak',
  'unknown.key',
  '',
];

void main() {
  test('every bind key has no value, and never TData.example', () {
    final data = AppData();
    for (final key in _keys) {
      final value = data.watch(key).value;
      expect(value, isNull, reason: key);
      expect(identical(value, TData.example), isFalse, reason: key);
    }
  });

  test('clear drops the cache and empties held listenables', () {
    final data = AppData();
    final held = data.watch('today.streak') as ValueNotifier<Object?>;
    held.value = 'synthetic';
    var notified = 0;
    held.addListener(() => notified++);
    data.watch('hw.last_bp');
    expect(data.cachedKeys, 2);

    data.clear();
    expect(data.cachedKeys, 0);
    expect(held.value, isNull);
    expect(notified, 1);
    final fresh = data.watch('today.streak');
    expect(fresh, isNot(same(held)));
    expect(fresh.value, isNull);
  });

  test('the same key gives the same listenable until clear', () {
    final data = AppData();
    expect(data.watch('today.streak'), same(data.watch('today.streak')));
  });
}
