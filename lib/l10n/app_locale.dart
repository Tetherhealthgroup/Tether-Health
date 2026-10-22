// The app's language: which locale both app roots run in, and the member's
// saved choice.
//
// Policy: on first launch the app follows the phone's language when it is one
// the app ships; otherwise English. A choice made in the app (the welcome
// language menu) overrides that and is saved on the device. If the phone's
// language changes after the choice was made, the phone wins and the saved
// choice is dropped: the most recent explicit choice wins. "Changes" means any
// change of the phone's first locale tag, region included: en-US to en-GB, or
// another language moved to the top of the phone's list, drops the choice even
// when the app language would stay the same.
//
// The saved value is two locale codes and nothing else. It is a device UI
// preference, not health data: it survives sign-out and is removed with the
// rest of the on-device data when the account is deleted. It is never logged.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The locales the app ships, in preference order. The first is the fallback.
const List<Locale> releaseLocales = <Locale>[Locale('en'), Locale('es')];

/// Picks the app locale: the saved [choice] when it is a release locale, else
/// the first of [deviceLocales] whose language the app ships (any `es-*` is
/// `es`), else English.
Locale resolveAppLocale({
  Locale? choice,
  required List<Locale> deviceLocales,
}) {
  final saved = choice == null ? null : _releaseLocaleFor(choice);
  if (saved != null) return saved;
  for (final device in deviceLocales) {
    final match = _releaseLocaleFor(device);
    if (match != null) return match;
  }
  return releaseLocales.first;
}

Locale? _releaseLocaleFor(Locale locale) {
  for (final release in releaseLocales) {
    if (release.languageCode == locale.languageCode) return release;
  }
  return null;
}

/// A saved language choice and the phone language at the time it was made.
@immutable
class SavedLocaleChoice {
  const SavedLocaleChoice({required this.choice, required this.deviceLocale});

  /// The chosen app language code, such as `es`.
  final String choice;

  /// The phone's first locale when the choice was made, such as `es-MX`.
  final String deviceLocale;

  static final _code = RegExp(r'^[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*$');

  /// The longest code accepted; longer stored values are discarded.
  static const maxCodeLength = 35;

  static bool _wellFormed(String code) =>
      code.length <= maxCodeLength && _code.hasMatch(code);

  /// Returns null unless [encoded] holds exactly two well-formed codes and
  /// the choice is a release locale.
  static SavedLocaleChoice? decode(String encoded) {
    if (encoded.length > 4 * maxCodeLength) return null;
    try {
      final json = jsonDecode(encoded);
      if (json is! Map || json.length != 2) return null;
      final choice = json['choice'];
      final device = json['deviceLocale'];
      if (choice is! String || device is! String) return null;
      if (!_wellFormed(choice) || !_wellFormed(device)) return null;
      if (!releaseLocales.any((release) => release.languageCode == choice)) {
        return null;
      }
      return SavedLocaleChoice(choice: choice, deviceLocale: device);
    } on FormatException {
      return null;
    }
  }

  String encode() =>
      jsonEncode({'choice': choice, 'deviceLocale': deviceLocale});
}

/// Where the language choice is kept.
abstract interface class AppLocaleStore {
  Future<SavedLocaleChoice?> load();

  Future<void> save(SavedLocaleChoice choice);

  Future<void> clear();
}

/// Keeps the choice in the Keychain / Android Keystore under one key.
class SecureAppLocaleStore implements AppLocaleStore {
  const SecureAppLocaleStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const storageKey = 'tether.app-locale.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<SavedLocaleChoice?> load() async {
    final encoded = await _storage.read(key: storageKey);
    if (encoded == null) return null;
    final choice = SavedLocaleChoice.decode(encoded);
    if (choice == null) await _storage.delete(key: storageKey);
    return choice;
  }

  @override
  Future<void> save(SavedLocaleChoice choice) =>
      _storage.write(key: storageKey, value: choice.encode());

  @override
  Future<void> clear() => _storage.delete(key: storageKey);
}

/// Keeps the choice in memory only (tests and screens used on their own).
class MemoryAppLocaleStore implements AppLocaleStore {
  SavedLocaleChoice? saved;

  @override
  Future<SavedLocaleChoice?> load() async => saved;

  @override
  Future<void> save(SavedLocaleChoice choice) async => saved = choice;

  @override
  Future<void> clear() async => saved = null;
}

/// The app-wide locale. Both app roots read [locale]; the welcome language
/// menu calls [choose]. Register it with [WidgetsBinding.addObserver] so a
/// phone language change is applied while the app runs.
class AppLocale extends ChangeNotifier with WidgetsBindingObserver {
  AppLocale({
    AppLocaleStore store = const SecureAppLocaleStore(),
    List<Locale> Function()? deviceLocales,
  })  : _store = store,
        _deviceLocales = deviceLocales ?? _platformLocales {
    _locale = resolveAppLocale(deviceLocales: _deviceLocales());
  }

  static List<Locale> _platformLocales() => PlatformDispatcher.instance.locales;

  final AppLocaleStore _store;
  final List<Locale> Function() _deviceLocales;
  late Locale _locale;
  Locale? _choice;
  String? _choiceDeviceTag;

  // Bumped by every choice and clear, so a slower earlier operation never
  // overrides a newer one.
  int _generation = 0;
  Future<void> _writes = Future<void>.value();

  /// The locale the app runs in now.
  Locale get locale => _locale;

  /// Whether the app runs in Spanish.
  bool get isSpanish => _locale.languageCode == 'es';

  String get _deviceTag {
    final device = _deviceLocales();
    return device.isEmpty ? 'und' : device.first.toLanguageTag();
  }

  /// Restores the saved choice. A choice made under a different phone
  /// language is dropped. Storage that cannot be read counts as no choice.
  Future<void> load() async {
    final generation = _generation;
    SavedLocaleChoice? saved;
    try {
      saved = await _store.load();
    } catch (_) {
      saved = null;
    }
    if (generation != _generation) return;
    if (saved != null && saved.deviceLocale != _deviceTag) {
      _generation++;
      unawaited(_enqueue(_store.clear));
      saved = null;
    }
    _choice = saved == null ? null : Locale(saved.choice);
    _choiceDeviceTag = saved?.deviceLocale;
    _update();
  }

  /// Saves [locale] as the member's choice and switches to it. Completes with
  /// false if the choice could not be saved; it still applies until restart.
  Future<bool> choose(Locale locale) {
    final chosen = resolveAppLocale(choice: locale, deviceLocales: const []);
    final record = SavedLocaleChoice(
      choice: chosen.languageCode,
      deviceLocale: _deviceTag,
    );
    _generation++;
    _choice = chosen;
    _choiceDeviceTag = record.deviceLocale;
    _update();
    return _enqueue(() => _store.save(record)).then(
      (_) => true,
      onError: (Object _) => false,
    );
  }

  /// Removes the saved choice (on-device data wipe) and follows the phone.
  /// Completes with the storage error if the stored value could not be
  /// removed, so the wipe can report that cleanup did not finish.
  Future<void> clearSavedChoice() {
    _generation++;
    _choice = null;
    _choiceDeviceTag = null;
    _update();
    return _enqueue(_store.clear);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_choice != null && _choiceDeviceTag != _deviceTag) {
      // The phone language changed after the choice: the phone wins.
      _generation++;
      _choice = null;
      _choiceDeviceTag = null;
      unawaited(_enqueue(_store.clear));
    }
    _update();
  }

  // Runs storage operations one after another. The returned future carries
  // the operation's error; the queue itself carries on after a failure.
  Future<void> _enqueue(Future<void> Function() write) {
    final result = _writes.then((_) => write());
    _writes = result.catchError((Object _) {});
    return result;
  }

  void _update() {
    final next = resolveAppLocale(
      choice: _choice,
      deviceLocales: _deviceLocales(),
    );
    if (next == _locale) return;
    _locale = next;
    notifyListeners();
  }
}
