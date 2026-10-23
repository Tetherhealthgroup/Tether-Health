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
  group('sources', sourceTests);
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

class _Source implements DataSource {
  _Source(this.keys, this.values);

  final Set<String> keys;
  Map<String, Object?>? values;
  int loads = 0;

  @override
  bool covers(String bindKey) => keys.contains(bindKey);

  @override
  Future<Map<String, Object?>?> load() async {
    loads++;
    return values;
  }
}

void sourceTests() {
  test('a loaded key answers its value; a missing one TData.unset', () async {
    final source = _Source({'a', 'b', 'c'}, {'a': 'value', 'c': null});
    final data = AppData(sources: [source]);
    final a = data.watch('a');
    final b = data.watch('b');
    final c = data.watch('c');
    expect(a.value, isNull, reason: 'not loaded yet');
    await Future<void>.delayed(Duration.zero);
    expect(a.value, 'value');
    expect(identical(b.value, TData.unset), isTrue);
    expect(identical(c.value, TData.unset), isTrue);
    expect(data.watch('uncovered').value, isNull);
    expect(source.loads, 1);
  });

  test('a failed load leaves the keys not loaded', () async {
    final data = AppData(sources: [
      _Source({'a'}, null)
    ]);
    final a = data.watch('a');
    await Future<void>.delayed(Duration.zero);
    expect(a.value, isNull);
  });

  test('never answers the example marker', () async {
    final data = AppData(sources: [
      _Source({'a'}, {'a': TData.example})
    ]);
    final a = data.watch('a');
    await Future<void>.delayed(Duration.zero);
    expect(a.value, isNull);
  });

  test('refresh loads again; clear drops values and tells listeners', () async {
    final source = _Source({'a'}, {'a': 1});
    String? account = 'acct-1';
    final data = AppData(sources: [source], accountId: () => account);
    final previous = <String?>[];
    data.addClearListener(previous.add);
    final a = data.watch('a');
    await Future<void>.delayed(Duration.zero);
    source.values = {'a': 2};
    await data.refresh();
    expect(a.value, 2);
    account = null;
    data.clear();
    expect(a.value, isNull);
    expect(previous, ['acct-1']);
  });

  test('a load that ends after clear is dropped', () async {
    final source = _Source({'a'}, {'a': 'old member'});
    final data = AppData(sources: [source]);
    final a = data.watch('a');
    data.clear();
    await Future<void>.delayed(Duration.zero);
    expect(a.value, isNull);
    expect(data.watch('a').value, isNull);
  });
}
