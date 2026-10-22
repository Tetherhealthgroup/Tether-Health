// The app language: resolution order, the saved choice and when it is
// dropped. Synthetic values only.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:breathefree_patient/l10n/app_locale.dart';
import 'package:breathefree_patient/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _key = SecureAppLocaleStore.storageKey;

Future<String?> _stored() => const FlutterSecureStorage().read(key: _key);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('resolveAppLocale', () {
    test('any Spanish phone locale resolves to es', () {
      for (final device in const [
        Locale('es', 'MX'),
        Locale('es', 'US'),
        Locale('es', 'ES'),
        Locale('es'),
      ]) {
        expect(resolveAppLocale(deviceLocales: [device]), const Locale('es'));
      }
    });

    test('an unsupported phone language falls back to English', () {
      expect(
        resolveAppLocale(deviceLocales: const [Locale('fr', 'FR')]),
        const Locale('en'),
      );
      expect(resolveAppLocale(deviceLocales: const []), const Locale('en'));
    });

    test('phone locales are tried in order', () {
      expect(
        resolveAppLocale(
          deviceLocales: const [Locale('fr'), Locale('es', 'MX'), Locale('en')],
        ),
        const Locale('es'),
      );
      expect(
        resolveAppLocale(
          deviceLocales: const [Locale('en', 'GB'), Locale('es')],
        ),
        const Locale('en'),
      );
    });

    test('a saved choice wins over the phone; an unsupported one is ignored',
        () {
      expect(
        resolveAppLocale(
          choice: const Locale('en'),
          deviceLocales: const [Locale('es', 'MX')],
        ),
        const Locale('en'),
      );
      expect(
        resolveAppLocale(
          choice: const Locale('de'),
          deviceLocales: const [Locale('es', 'MX')],
        ),
        const Locale('es'),
      );
    });
  });

  group('AppLocale', () {
    test('first launch follows the phone language', () async {
      final spanish =
          AppLocale(deviceLocales: () => const [Locale('es', 'MX')]);
      await spanish.load();
      expect(spanish.locale, const Locale('es'));
      expect(spanish.isSpanish, isTrue);

      final french = AppLocale(deviceLocales: () => const [Locale('fr', 'FR')]);
      await french.load();
      expect(french.locale, const Locale('en'));
    });

    test('a choice is saved as two codes and survives a restart', () async {
      final first = AppLocale(deviceLocales: () => const [Locale('en', 'US')]);
      await first.load();
      await first.choose(const Locale('es', 'MX'));
      expect(first.locale, const Locale('es'));
      expect(
        jsonDecode((await _stored())!),
        {'choice': 'es', 'deviceLocale': 'en-US'},
      );

      final restarted =
          AppLocale(deviceLocales: () => const [Locale('en', 'US')]);
      expect(restarted.locale, const Locale('en'));
      await restarted.load();
      expect(restarted.locale, const Locale('es'));
    });

    test('a phone language change at launch drops the saved choice', () async {
      FlutterSecureStorage.setMockInitialValues({
        _key: '{"choice":"es","deviceLocale":"en-US"}',
      });
      final locale = AppLocale(deviceLocales: () => const [Locale('fr', 'FR')]);
      await locale.load();
      expect(locale.locale, const Locale('en'));
      await locale.choose(const Locale('en'));
      expect(
        jsonDecode((await _stored())!),
        {'choice': 'en', 'deviceLocale': 'fr-FR'},
      );
    });

    test('a phone language change at launch removes the stored value',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        _key: '{"choice":"es","deviceLocale":"en-US"}',
      });
      final locale = AppLocale(deviceLocales: () => const [Locale('en', 'GB')]);
      await locale.load();
      await pumpEventQueue();
      expect(locale.locale, const Locale('en'));
      expect(await _stored(), isNull);
    });

    test('a phone language change while running drops the choice', () async {
      var device = const [Locale('en', 'US')];
      final locale = AppLocale(deviceLocales: () => device);
      await locale.load();
      await locale.choose(const Locale('es'));
      var notified = 0;
      locale.addListener(() => notified++);

      // Same phone language reported again: the choice stays.
      locale.didChangeLocales(device);
      expect(locale.locale, const Locale('es'));

      device = const [Locale('fr', 'FR')];
      locale.didChangeLocales(device);
      await pumpEventQueue();
      expect(locale.locale, const Locale('en'));
      expect(notified, 1);
      expect(await _stored(), isNull);
    });

    test('the choice stays while the phone language is unchanged', () async {
      FlutterSecureStorage.setMockInitialValues({
        _key: '{"choice":"es","deviceLocale":"en-US"}',
      });
      final locale = AppLocale(deviceLocales: () => const [Locale('en', 'US')]);
      await locale.load();
      expect(locale.locale, const Locale('es'));
      expect(await _stored(), isNotNull);
    });

    test('clearing removes the stored value and follows the phone', () async {
      final locale = AppLocale(deviceLocales: () => const [Locale('en', 'US')]);
      await locale.choose(const Locale('es'));
      expect(await _stored(), isNotNull);
      await locale.clearSavedChoice();
      expect(await _stored(), isNull);
      expect(locale.locale, const Locale('en'));
    });

    test('a choice made while the saved value loads is not overridden',
        () async {
      final store = _SlowStore(const SavedLocaleChoice(
        choice: 'en',
        deviceLocale: 'es-MX',
      ));
      final locale = AppLocale(
        store: store,
        deviceLocales: () => const [Locale('es', 'MX')],
      );
      final loading = locale.load();
      await locale.choose(const Locale('es'));
      store.release.complete();
      await loading;
      expect(locale.locale, const Locale('es'));
      expect(store.saved?.choice, 'es');
    });

    test('the newest of quick successive choices is the one saved', () async {
      final locale = AppLocale(deviceLocales: () => const [Locale('en', 'US')]);
      unawaited(locale.choose(const Locale('es')));
      unawaited(locale.choose(const Locale('en')));
      await locale.choose(const Locale('es'));
      expect(jsonDecode((await _stored())!)['choice'], 'es');
      unawaited(locale.choose(const Locale('en')));
      await locale.clearSavedChoice();
      expect(await _stored(), isNull);
    });

    test('a malformed stored value is ignored and removed', () async {
      for (final bad in const [
        '{not-json',
        '"es"',
        '{"choice":"es"}',
        '{"choice":"es","deviceLocale":"en-US","extra":"x"}',
        '{"choice":"es; drop","deviceLocale":"en-US"}',
      ]) {
        FlutterSecureStorage.setMockInitialValues({_key: bad});
        final locale =
            AppLocale(deviceLocales: () => const [Locale('en', 'US')]);
        await locale.load();
        expect(locale.locale, const Locale('en'), reason: bad);
        expect(await _stored(), isNull, reason: bad);
      }
    });

    test('unreadable storage counts as no choice', () async {
      final locale = AppLocale(
        store: _FailingStore(),
        deviceLocales: () => const [Locale('es', 'US')],
      );
      await locale.load();
      expect(locale.locale, const Locale('es'));
      await locale.choose(const Locale('en'));
      expect(locale.locale, const Locale('en'));
      await locale.clearSavedChoice();
      expect(locale.locale, const Locale('es'));
    });
  });

  group('catalogs', () {
    test('every release locale has app strings and Material translations', () {
      for (final locale in releaseLocales) {
        expect(AppLocalizations.delegate.isSupported(locale), isTrue);
        expect(
            GlobalMaterialLocalizations.delegate.isSupported(locale), isTrue);
        expect(
          GlobalCupertinoLocalizations.delegate.isSupported(locale),
          isTrue,
        );
      }
      expect(AppLocalizations.supportedLocales, releaseLocales);
    });

    test('the Spanish catalog has exactly the English keys', () {
      Set<String> keys(String path) =>
          (jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>)
              .keys
              .where((key) => !key.startsWith('@'))
              .toSet();
      expect(keys('lib/l10n/app_es.arb'), keys('lib/l10n/app_en.arb'));
    });
  });
}

class _SlowStore extends MemoryAppLocaleStore {
  _SlowStore(SavedLocaleChoice initial) {
    saved = initial;
  }

  final release = Completer<void>();

  @override
  Future<SavedLocaleChoice?> load() async {
    final value = saved;
    await release.future;
    return value;
  }
}

class _FailingStore implements AppLocaleStore {
  @override
  Future<SavedLocaleChoice?> load() => Future.error(StateError('locked'));

  @override
  Future<void> save(SavedLocaleChoice choice) =>
      Future.error(StateError('locked'));

  @override
  Future<void> clear() => Future.error(StateError('locked'));
}
