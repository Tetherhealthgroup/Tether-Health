// Localized text for the generated screens and the kit, with Flutter SDK
// code only (no intl).
//
// The catalogs are generated into lib/l10n/strings.g.dart from
// spec/l10n/en.arb (the English source) and the hand-maintained
// spec/l10n/<locale>.arb translations. A release build offers only release
// locales: every key present, fresh and reviewed. Draft locales and the
// pseudo-locale are available in debug builds only. A key missing from the
// active catalog throws in debug and test builds.
//
// Without a TStrings.delegate above them, screens show English, so a host
// app that has not registered the delegate is unchanged.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../l10n/strings.g.dart';

/// Localized strings. Screens read their text through the typed accessors
/// generated in lib/l10n/strings.g.dart (`TStrings.of(context).<key>`).
class TStrings {
  TStrings._(this.locale, this._table, this._release);

  /// The locale whose catalog this is.
  final Locale locale;
  final Map<String, String> _table;
  final bool _release;

  /// English, the source catalog.
  static final TStrings english = TStrings._(const Locale('en'), tCatalog('en', release: false)!, kReleaseMode);

  /// The strings for [context]: the nearest [TStrings.delegate] locale, or
  /// English when no delegate is registered.
  static TStrings of(BuildContext context) => Localizations.of<TStrings>(context, TStrings) ?? english;

  /// The delegate to register with the app's `localizationsDelegates`.
  static const LocalizationsDelegate<TStrings> delegate = _TStringsDelegate();

  /// Locales offered: the release locales, plus the draft locales and the
  /// pseudo-locale when not [release].
  static List<Locale> supportedLocales({bool release = kReleaseMode}) => [
        for (final tag in tReleaseLocales) _parse(tag),
        if (!release) ...[for (final tag in tDraftLocales) _parse(tag), _parse(tPseudoLocale)],
      ];

  /// The strings for [locale], or null when it is not offered ([release]
  /// builds offer release locales only). An exact match wins, else the
  /// first offered locale with the same language.
  static TStrings? forLocale(Locale locale, {bool release = kReleaseMode}) {
    final offered = supportedLocales(release: release);
    final match = offered.where((l) => l == locale).firstOrNull ??
        offered.where((l) => l.languageCode == locale.languageCode && l.countryCode == null).firstOrNull;
    if (match == null) return null;
    final table = tCatalog(_tag(match), release: release);
    return table == null ? null : TStrings._(match, table, release);
  }

  static Locale _parse(String tag) {
    final parts = tag.split('-');
    return parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }

  static String _tag(Locale l) => l.countryCode == null ? l.languageCode : '${l.languageCode}-${l.countryCode}';

  /// The text for [key]. A key without a (fresh) translation throws in debug
  /// and test builds; release locales have every key.
  String get(String key) {
    final value = _table[key];
    if (value != null) return value;
    if (!_release) {
      throw FlutterError('TStrings: no translation of "$key" for ${_tag(locale)} (missing or stale)');
    }
    return tCatalog('en', release: true)![key] ?? '';
  }

  /// The text for [key] with its `{placeholders}` and plurals filled from
  /// [args].
  String format(String key, Map<String, Object> args) =>
      TIcu.format(get(key), args, (n) => tPluralCategory(locale.languageCode, n));
}

class _TStringsDelegate extends LocalizationsDelegate<TStrings> {
  const _TStringsDelegate();

  @override
  bool isSupported(Locale locale) => TStrings.forLocale(locale) != null;

  @override
  Future<TStrings> load(Locale locale) => SynchronousFuture<TStrings>(TStrings.forLocale(locale)!);

  @override
  bool shouldReload(_TStringsDelegate old) => false;
}

/// Formats the ICU subset the generator accepts: `{name}` placeholders and
/// `{n, plural, =0{...} one{...} other{...}}` with `#` for the number. No
/// apostrophe quoting; a literal brace is not allowed.
abstract final class TIcu {
  /// [message] with [args] filled in; [category] gives the plural category
  /// ('one' or 'other') of a number.
  static String format(String message, Map<String, Object> args, String Function(num n) category) {
    final p = _Parser(message);
    final out = p.message(args, category, null, 0);
    if (p.pos != message.length) throw FormatException('unexpected } in message', message, p.pos);
    return out;
  }
}

class _Parser {
  _Parser(this.s);
  final String s;
  int pos = 0;

  String message(Map<String, Object> args, String Function(num) category, num? hash, int depth) {
    final out = StringBuffer();
    while (pos < s.length) {
      final c = s[pos];
      if (c == '{') {
        out.write(_argument(args, category, depth));
      } else if (c == '}') {
        if (depth == 0) throw FormatException('unmatched }', s, pos);
        break;
      } else if (c == '#' && hash != null) {
        out.write(hash);
        pos++;
      } else {
        out.write(c);
        pos++;
      }
    }
    return out.toString();
  }

  String _name() {
    _spaces();
    final start = pos;
    while (pos < s.length && RegExp(r'[A-Za-z0-9_]').hasMatch(s[pos])) {
      pos++;
    }
    if (start == pos) throw FormatException('expected a name', s, pos);
    final n = s.substring(start, pos);
    _spaces();
    return n;
  }

  void _spaces() {
    while (pos < s.length && s[pos] == ' ') {
      pos++;
    }
  }

  void _expect(String c) {
    if (pos >= s.length || s[pos] != c) throw FormatException('expected $c', s, pos);
    pos++;
  }

  String _argument(Map<String, Object> args, String Function(num) category, int depth) {
    _expect('{');
    final name = _name();
    if (pos < s.length && s[pos] == '}') {
      pos++;
      final v = args[name];
      if (v == null) throw ArgumentError('no value for {$name}');
      return '$v';
    }
    _expect(',');
    if (_name() != 'plural') throw FormatException('only plural is supported', s, pos);
    _expect(',');
    final v = args[name];
    if (v is! num) throw ArgumentError('{$name} needs a number');
    final want = '=${v is int || v == v.roundToDouble() ? v.round() : v}';
    final cat = category(v);
    String? exact, byCategory, other;
    while (true) {
      _spaces();
      if (pos < s.length && s[pos] == '}') break;
      final sel = _selector();
      _expect('{');
      final text = message(args, category, v, depth + 1);
      _expect('}');
      if (sel == want) exact ??= text;
      if (sel == cat) byCategory ??= text;
      if (sel == 'other') other = text;
    }
    _expect('}');
    final chosen = exact ?? byCategory ?? other;
    if (chosen == null) throw FormatException('plural {$name} has no other case', s, pos);
    return chosen;
  }

  String _selector() {
    _spaces();
    final start = pos;
    while (pos < s.length && s[pos] != '{' && s[pos] != ' ') {
      pos++;
    }
    final sel = s.substring(start, pos);
    _spaces();
    if (sel.isEmpty) throw FormatException('expected a plural selector', s, pos);
    return sel;
  }
}
