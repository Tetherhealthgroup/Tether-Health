// Tether Health UI kit — live values for display.
//
// A bound element shows values from [TData.instance] in place of the spec's
// example values (P-89, R-163):
// - the member's value: shown exactly as the static component would show
//   it, with no tag;
// - no value (null = not loaded, [TData.unset] = the member has none, or a
//   value of the wrong type): the spec's example value plus the "Example"
//   tag ([TExampleTag]), so an example is never presented as the member's
//   own data;
// - [TData.example], which only [PreviewData] (debug and tests) returns: the
//   example with no tag, so the preview, prototype, scenarios and render
//   tests look exactly like the design.
// Release builds start with [TEmptyData] (see TDefaults in nav.dart): every
// bound element shows its example with the tag until the app installs its
// own [TData]. Bound display values are never written to [TSession], so an
// example never reaches a payload or a decision rule.
//
// TSession.clear() does not reset TData. An app-owned TData that caches
// values must drop them itself on sign-out, account switch and account
// deletion.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../l10n/strings.g.dart';
import 'components.dart';
import 'nav.dart';
import 'strings.dart';
import 'tokens.dart';

/// Live values for display, keyed by bind key (for example `hw.last_bp`).
///
/// `TSession.clear()` does not reset this. An app-owned implementation that
/// caches values must drop them on sign-out, account switch and account
/// deletion.
abstract class TData {
  static TData instance = TDefaults.data();

  /// Marker value meaning "preview: show the spec's example value", with no
  /// Example tag. Only [PreviewData] returns it; a real TData never does.
  static const Object example = _Example();

  /// Marker value meaning "loaded, and the member has no stored value".
  /// Null keeps meaning "not loaded yet". A bound input control on a plan
  /// screen shows the spec's starting value for it; one on a consent screen
  /// shows its empty (off) state ([TBindClass]).
  static const Object unset = _Unset();

  /// [bindKey] for a screen opened for [program]: a `:program` segment is
  /// replaced by the programme id. Null when the key needs a programme and
  /// [program] is null or not a programme id (two lower-case letters, for
  /// example `bf`); the control then has no value (not loaded).
  static String? resolve(String bindKey, String? program) {
    final parts = bindKey.split('.');
    if (!parts.contains(':program')) return bindKey;
    if (program == null || !_programId.hasMatch(program)) return null;
    return [for (final p in parts) p == ':program' ? program : p].join('.');
  }

  static final RegExp _programId = RegExp(r'^[a-z]{2}$');

  /// The current value for [bindKey]. Null means there is no value yet.
  ValueListenable<Object?> watch(String bindKey);
}

/// How a bound input control on a settings screen starts (P-71).
enum TBindClass {
  /// A consent, share, alert or notification choice: only a stored value is
  /// shown. [TData.unset] and null both show the empty (off) state and write
  /// nothing; the member's changes are listed in `TSession.touched`.
  consent,

  /// A plan or profile value: a stored value is shown and written to the
  /// session; [TData.unset] shows and writes the spec's starting value; null
  /// writes nothing.
  plan,
}

final class _Example {
  const _Example();
  @override
  String toString() => 'TData.example';
}

final class _Unset {
  const _Unset();
  @override
  String toString() => 'TData.unset';
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

/// Release default for [TData]: null (no value) for every key, so bound
/// elements show their example values with the Example tag, and bound input
/// controls their empty state.
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

/// Bound slots: one bind key each. Each watches the key in [TData.instance]
/// and builds the static component with the member's value, or with the
/// fallback (the spec's example value), tagged as in [TBoundValues]:
///
///     TBound.text('hw.last_bp', fallback: '128/82', builder: (c, v) => TBigNumber(value: v, unit: 'mmHg'))
///     TBound.series('hw.week', fallback: const [128, 131, 126], builder: (c, v) => TBarChart(values: v, color: TColors.teal))
///     TBound.list<TListRow>('records.recent', fallback: rows, builder: (c, v) => TListGroup(rows: v))
///
/// Generated screens use [TBoundValues], which binds several properties of
/// one element (spec/bindings.json).
abstract final class TBound {
  /// A text value. Strings show as they are and numbers in their default
  /// form; anything else counts as no value. Default builder: [TBody].
  static TBoundSlot<String> text(String bindKey, {Key? key, required String fallback, TBoundBuilder<String>? builder}) =>
      TBoundSlot<String>(key: key, bindKey: bindKey, fallback: fallback, convert: textOf, builder: builder ?? _body);

  /// A chart series. Only a non-empty list of numbers counts as a value.
  static TBoundSlot<List<double>> series(String bindKey, {Key? key, required List<double> fallback, required TBoundBuilder<List<double>> builder}) =>
      TBoundSlot<List<double>>(key: key, bindKey: bindKey, fallback: fallback, convert: seriesOf, builder: builder);

  /// List rows (rows, stats, tiles...). Only a non-empty list whose items
  /// are all [T] counts as a value.
  static TBoundSlot<List<T>> list<T>(String bindKey, {Key? key, required List<T> fallback, required TBoundBuilder<List<T>> builder}) =>
      TBoundSlot<List<T>>(key: key, bindKey: bindKey, fallback: fallback, convert: listOf<T>, builder: builder);

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

/// One bound slot. Shows [builder] with the converted value when TData has a
/// usable value for [bindKey]; otherwise [builder] with [fallback], and the
/// Example tag unless the answer is [TData.example] (preview).
class TBoundSlot<T> extends StatelessWidget {
  const TBoundSlot({super.key, required this.bindKey, required this.fallback, required this.convert, required this.builder});

  /// The TData key; a `:program` segment is resolved for the screen's
  /// programme ([TData.resolve]).
  final String bindKey;

  /// The spec's example value, shown when there is no usable value.
  final T fallback;

  /// Converts the raw value; null means no usable value.
  final T? Function(Object? raw) convert;

  final TBoundBuilder<T> builder;

  @override
  Widget build(BuildContext context) => TBoundValues(
        keys: [bindKey],
        builder: (context, values) => builder(context, values.value<T>(bindKey, fallback, convert)),
      );
}

/// The member's values for the bind keys of one element, read by the
/// element's builder ([TBoundValues]). Each read returns the member's value
/// or the example; [needsTag] records whether an example was shown because
/// the member has no value.
final class TValues {
  TValues._(this._raw);

  final Map<String, Object?> _raw;

  /// Whether a read returned an example because the member has no value
  /// (not loaded, [TData.unset], or a value of the wrong type). A preview
  /// answer ([TData.example]) does not count.
  bool get needsTag => _needsTag;
  bool _needsTag = false;

  /// The member's text for [bindKey], or [example].
  String text(String bindKey, String example) => value<String>(bindKey, example, TBound.textOf);

  /// The member's series for [bindKey], or [example].
  List<double> series(String bindKey, List<double> example) => value<List<double>>(bindKey, example, TBound.seriesOf);

  /// The member's value for [bindKey] converted by [convert], or [example].
  T value<T>(String bindKey, T example, T? Function(Object? raw) convert) {
    final raw = _raw[bindKey];
    if (identical(raw, TData.example)) return example;
    final v = convert(raw);
    if (v != null) return v;
    _needsTag = true;
    return example;
  }
}

/// Where the Example tag goes (R-163).
enum TExamplePlace {
  /// After a text or number element, on the same row.
  inline,

  /// At the top trailing corner of a card, chart, list, stat grid or banner,
  /// just above it.
  corner,
}

/// Builds one generated element from the member's values for [keys]
/// (spec/bindings.json; a card and everything in it is one element, so it
/// carries at most one tag). The element shows the member's values; a value
/// the member does not have shows the spec's example, and the element then
/// carries the Example tag at [place]. With all of the member's values, or
/// with preview answers, it builds exactly what [builder] returns, and
/// nothing else.
///
/// A `:program` segment in a key is resolved for the programme the screen
/// was opened for ([TNav.programOf], [TData.resolve]); with no programme the
/// key has no value. Inside an element that already shows the tag, no
/// second tag is added.
class TBoundValues extends StatelessWidget {
  const TBoundValues({super.key, required this.keys, this.place = TExamplePlace.corner, required this.builder});

  final List<String> keys;
  final TExamplePlace place;
  final Widget Function(BuildContext context, TValues values) builder;

  @override
  Widget build(BuildContext context) {
    final program = TNav.programOf(context);
    final data = TData.instance;
    final watched = <String, ValueListenable<Object?>>{
      for (final k in keys)
        if (TData.resolve(k, program) case final resolved?) k: data.watch(resolved),
    };
    return ListenableBuilder(
      listenable: Listenable.merge(watched.values.toList()),
      builder: (context, _) {
        final values = TValues._({for (final MapEntry(:key, :value) in watched.entries) key: value.value});
        final child = builder(context, values);
        if (!values.needsTag || TExampleTag.shownAround(context)) return child;
        return TExampleTag.mark(child, place);
      },
    );
  }
}

/// The "Example" tag (`kit.example`): marks a design example value shown
/// because the member has no value yet (P-89). Screen readers hear
/// "Example" first, then the value.
class TExampleTag extends StatelessWidget {
  const TExampleTag({super.key});

  /// [child] marked with the tag at [place].
  static Widget mark(Widget child, TExamplePlace place) => switch (place) {
        TExamplePlace.inline => _ExampleShown(
            child: MergeSemantics(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Read first, so the merged label is "Example", then the value.
                const _ExampleLabel(),
                Expanded(child: child),
                const SizedBox(width: 8),
                const Padding(padding: EdgeInsets.only(top: 2), child: ExcludeSemantics(child: TExampleTag())),
              ]),
            ),
          ),
        TExamplePlace.corner => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(alignment: AlignmentDirectional.centerEnd, child: _ExampleLabel(child: ExcludeSemantics(child: TExampleTag()))),
              const SizedBox(height: 4),
              _ExampleShown(child: child),
            ],
          ),
      };

  /// Whether an element around [context] already shows the tag.
  static bool shownAround(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_ExampleShown>() != null;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: TColors.warnFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: TColors.warnBorder)),
        child: Text(TStrings.of(context).kitExample.toUpperCase(), style: TText.pill.copyWith(color: TColors.warnText)),
      );
}

/// The tag's screen-reader label, "Example".
class _ExampleLabel extends StatelessWidget {
  const _ExampleLabel({this.child = const SizedBox.shrink()});
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(label: TStrings.of(context).kitExample, child: child);
}

class _ExampleShown extends InheritedWidget {
  const _ExampleShown({required super.child});
  @override
  bool updateShouldNotify(_ExampleShown oldWidget) => false;
}
