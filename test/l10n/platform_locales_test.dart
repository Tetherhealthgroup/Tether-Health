// The languages declared to iOS and Android equal the app's release locales,
// so the OS language settings offer exactly the languages the app ships.
import 'dart:io';

import 'package:breathefree_patient/l10n/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';

const _infoPlist = 'ios/Runner/Info.plist';
const _manifest = 'android/app/src/main/AndroidManifest.xml';
const _localesConfig = 'android/app/src/main/res/xml/locales_config.xml';

String _withoutComments(String xml) =>
    xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

/// The strings of the top-level CFBundleLocalizations array, or null.
List<String>? iosLocalizations(String plist) {
  final xml = _withoutComments(plist);
  final keys = RegExp(r'<key>\s*CFBundleLocalizations\s*</key>')
      .allMatches(xml)
      .toList();
  if (keys.length != 1) return null;
  final array = RegExp(r'^\s*<array>(.*?)</array>', dotAll: true)
      .firstMatch(xml.substring(keys.single.end));
  if (array == null) return null;
  final body = array.group(1)!;
  final strings = RegExp(r'<string>\s*([^<]*?)\s*</string>')
      .allMatches(body)
      .map((m) => m.group(1)!)
      .toList();
  // Anything but <string> entries makes the array malformed for this check.
  final rest = body.replaceAll(RegExp(r'<string>[^<]*</string>'), '').trim();
  return rest.isEmpty ? strings : null;
}

/// The android:name of every `<locale>` in a `<locale-config>`, or null.
List<String>? androidLocales(String xml) {
  final body =
      RegExp(r'<locale-config\b[^>]*>(.*?)</locale-config>', dotAll: true)
          .firstMatch(_withoutComments(xml))
          ?.group(1);
  if (body == null) return null;
  final names = RegExp(r'<locale\s+android:name\s*=\s*"([^"]*)"\s*/>')
      .allMatches(body)
      .map((m) => m.group(1)!)
      .toList();
  // Every <locale> element must be one parsed above; any other form (such
  // as an open/close pair) makes the file malformed for this check.
  final elements = RegExp(r'<locale(?=[\s/>])').allMatches(body).length;
  return elements == names.length ? names : null;
}

/// The android:localeConfig attribute of the `<application>` tag, or null.
String? applicationLocaleConfig(String manifest) {
  final application = RegExp(r'<application\b((?:"[^"]*"|[^">])*)>').firstMatch(
    _withoutComments(manifest),
  );
  if (application == null) return null;
  return RegExp(r'android:localeConfig\s*=\s*"([^"]*)"')
      .firstMatch(application.group(1)!)
      ?.group(1);
}

void main() {
  final release = [for (final l in releaseLocales) l.toLanguageTag()];

  test('the release locales are en and es', () {
    expect(release, ['en', 'es']);
  });

  test('iOS CFBundleLocalizations equals the release locales', () {
    expect(iosLocalizations(File(_infoPlist).readAsStringSync()), release);
  });

  test('Android locales_config.xml equals the release locales', () {
    expect(androidLocales(File(_localesConfig).readAsStringSync()), release);
  });

  test('the Android application points at locales_config.xml', () {
    expect(
      applicationLocaleConfig(File(_manifest).readAsStringSync()),
      '@xml/locales_config',
    );
  });

  group('self-check: the parsers reject what the OS would not see', () {
    test('a commented-out or duplicated iOS key does not count', () {
      expect(
        iosLocalizations('<dict><!-- <key>CFBundleLocalizations</key>'
            '<array><string>en</string></array> --></dict>'),
        isNull,
      );
      const entry = '<key>CFBundleLocalizations</key>'
          '<array><string>en</string></array>';
      expect(iosLocalizations('<dict>$entry$entry</dict>'), isNull);
      expect(
        iosLocalizations('<dict><key>CFBundleLocalizations</key>'
            '<string>en</string></dict>'),
        isNull,
      );
      expect(
        iosLocalizations('<dict><key>CFBundleLocalizations</key><array>'
            '<string>en</string><integer>1</integer></array></dict>'),
        isNull,
      );
      expect(
        iosLocalizations('<dict><key>CFBundleLocalizations</key><array>'
            '<string>es</string><string>en</string></array></dict>'),
        ['es', 'en'],
      );
    });

    test('a commented-out Android locale or attribute does not count', () {
      expect(
        androidLocales('<locale-config><locale android:name="en"/>'
            '<!-- <locale android:name="es"/> --></locale-config>'),
        ['en'],
      );
      expect(androidLocales('<resources/>'), isNull);
      expect(
        androidLocales('<locale-config><locale android:name="en"/>'
            '<locale android:name="fr"></locale></locale-config>'),
        isNull,
      );
      expect(
        applicationLocaleConfig('<manifest><application '
            'android:label="x"><!-- android:localeConfig="@xml/a" -->'
            '</application></manifest>'),
        isNull,
      );
      expect(
        applicationLocaleConfig('<manifest><application android:label="x">'
            '<activity android:localeConfig="@xml/a"/></application>'
            '</manifest>'),
        isNull,
      );
    });
  });
}
