// Tether Health UI kit — live values for display.
//
// A bound slot shows a value from [TData.instance] in place of a spec
// literal. [PreviewData] (the debug and test default) answers [TData.example] for every
// key, so the slot shows its fallback, which is the spec's example value:
// the preview, scenarios and screenshots stay as they are. The app installs
// its own [TData] at startup, from app code. A real [TData] never returns
// [TData.example]; when it has no value it returns null and the slot shows
// its empty state, never the fallback. Release builds start with
// [TEmptyData] (see TDefaults in nav.dart).
//
// TSession.clear() does not reset TData. An app-owned TData that caches
// values must drop them itself on sign-out, account switch and account
// deletion.
//
// Binding changes data, never layout or visuals: a slot builds exactly the
// widget the static component would build with the same value, and adds no
// widget that paints or lays out.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'components.dart';
import 'nav.dart';

/// Live values for display, keyed by bind key (for example `hw.last_bp`).
///
/// `TSession.clear()` does not reset this. An app-owned implementation that
/// caches values must drop them on sign-out, account switch and account
/// deletion.
abstract class TData {
  static TData instance = TDefaults.data();

  /// Marker value meaning "show the spec's example value" (the slot's
  /// fallback). Only [PreviewData] returns it.
  static const Object example = _Example();

  /// The current value for [bindKey]. Null means there is no value yet.
  ValueListenable<Object?> watch(String bindKey);
}

final class _Example {
  const _Example();
  @override
  String toString() => 'TData.example';
}

/// Preview data: the spec's example value for every key ([TData.example]),
/// or the value given in [values] for that key.
class PreviewData implements TData {
  PreviewData([Map<String, Object?> values = const <String, Object?>{}]) : _values = Map<String, Object?>.of(values);

  final Map<String, Object?> _values;
  final Map<String, ValueListenable<Object?>> _cache = <String, ValueListenable<Object?>>{};

  static const ValueListenable<Object?> _example = _Constant(TData.example);

  @override
  ValueListenable<Object?> watch(String bindKey) {
    if (!_values.containsKey(bindKey)) return _example;
    return _cache.putIfAbsent(bindKey, () => _Constant(_values[bindKey]));
  }
}

/// Release default for [TData]: null (no value) for every key, so slots show
/// their empty state and never a fallback.
class TEmptyData implements TData {
  const TEmptyData();

  static const ValueListenable<Object?> _none = _Constant(null);

  @override
  ValueListenable<Object?> watch(String bindKey) => _none;
}

class _Constant implements ValueListenable<Object?> {
  const _Constant(this.value);
  @override
  final Object? value;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

/// Builds the static component for a bound value.
typedef TBoundBuilder<T> = Widget Function(BuildContext context, T value);

/// Bound slots. Each one watches a bind key in [TData.instance] and builds
/// the static component with the value it gets:
///
///     TBound.text('hw.last_bp', fallback: '128/82', builder: (c, v) => TBigNumber(value: v, unit: 'mmHg'))
///     TBound.series('hw.week', fallback: const [128, 131, 126], builder: (c, v) => TBarChart(values: v, color: TColors.teal))
///     TBound.list<TListRow>('records.recent', fallback: rows, builder: (c, v) => TListGroup(rows: v))
abstract final class TBound {
  /// A text value. Strings show as they are and numbers in their default
  /// form; anything else counts as no value. Default builder: [TBody].
  static TBoundSlot<String> text(String bindKey, {Key? key, required String fallback, TBoundBuilder<String>? builder, WidgetBuilder? empty}) =>
      TBoundSlot<String>(key: key, bindKey: bindKey, fallback: fallback, convert: textOf, builder: builder ?? _body, empty: empty);

  /// A chart series. Only a non-empty list of numbers counts as a value.
  static TBoundSlot<List<double>> series(String bindKey, {Key? key, required List<double> fallback, required TBoundBuilder<List<double>> builder, WidgetBuilder? empty}) =>
      TBoundSlot<List<double>>(key: key, bindKey: bindKey, fallback: fallback, convert: seriesOf, builder: builder, empty: empty);

  /// List rows (rows, stats, tiles...). Only a non-empty list whose items
  /// are all [T] counts as a value.
  static TBoundSlot<List<T>> list<T>(String bindKey, {Key? key, required List<T> fallback, required TBoundBuilder<List<T>> builder, WidgetBuilder? empty}) =>
      TBoundSlot<List<T>>(key: key, bindKey: bindKey, fallback: fallback, convert: listOf<T>, builder: builder, empty: empty);

  static Widget _body(BuildContext context, String value) => TBody(value);

  /// Text form of [raw], or null when it is not a displayable value.
  static String? textOf(Object? raw) => switch (raw) {
        final String s when s.isNotEmpty => s,
        final num n => n.toString(),
        _ => null,
      };

  /// [raw] as a series, or null when it is not a non-empty list of numbers.
  static List<double>? seriesOf(Object? raw) {
    if (raw is! List || raw.isEmpty || raw.any((v) => v is! num)) return null;
    return List<double>.unmodifiable(raw.map((v) => (v as num).toDouble()));
  }

  /// [raw] as a list of [T], or null when it is not a non-empty list of [T].
  static List<T>? listOf<T>(Object? raw) {
    if (raw is! List || raw.isEmpty || raw.any((v) => v is! T)) return null;
    return List<T>.unmodifiable(raw.cast<T>());
  }
}

/// One bound slot. Shows [fallback] for [TData.example], [builder] with the
/// converted value for a usable value, and [empty] (or nothing) otherwise.
class TBoundSlot<T> extends StatelessWidget {
  const TBoundSlot({super.key, required this.bindKey, required this.fallback, required this.convert, required this.builder, this.empty});

  final String bindKey;

  /// The spec's example value, shown only for [TData.example].
  final T fallback;

  /// Converts the raw value; null means no usable value.
  final T? Function(Object? raw) convert;

  final TBoundBuilder<T> builder;

  /// Shown when there is no usable value. Default: nothing.
  final WidgetBuilder? empty;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Object?>(
        valueListenable: TData.instance.watch(bindKey),
        builder: (context, raw, _) {
          if (identical(raw, TData.example)) return builder(context, fallback);
          final value = convert(raw);
          if (value != null) return builder(context, value);
          return empty?.call(context) ?? const SizedBox.shrink();
        },
      );
}
