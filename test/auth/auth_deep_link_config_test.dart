import 'dart:io';

import 'package:breathefree_patient/auth/auth_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const callback = 'com.tetherhealthllc.tetherhealth://login-callback';
  const previousScheme = 'io.breathefree.patient';
  final redirect = Uri.parse(authRedirectUrl);

  String read(String path) => File(path).readAsStringSync();

  test('the redirect constant is the owner-approved callback', () {
    expect(authRedirectUrl, callback);
    expect(redirect.scheme, 'com.tetherhealthllc.tetherhealth');
    expect(redirect.host, 'login-callback');
  });

  test('the auth gateway sends the redirect constant', () {
    final authGateway = read('lib/auth/auth_gateway.dart');

    expect(authGateway, contains(': authRedirectUrl'));
    expect(authGateway, contains('emailRedirectTo: _emailRedirectTo'));
  });

  test('iOS registers exactly the redirect scheme', () {
    final plist = read('ios/Runner/Info.plist');
    final schemesBlock = RegExp(
      r'<key>CFBundleURLSchemes</key>\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(plist);
    expect(schemesBlock, isNotNull);
    final schemes = RegExp(r'<string>([^<]*)</string>')
        .allMatches(schemesBlock!.group(1)!)
        .map((match) => match.group(1))
        .toList();

    expect(schemes, [redirect.scheme]);
  });

  test('Android registers exactly the redirect scheme and host', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');
    final schemes = RegExp(r'android:scheme="([^"]*)"')
        .allMatches(manifest)
        .map((match) => match.group(1))
        .toList();
    final hosts = RegExp(r'android:host="([^"]*)"')
        .allMatches(manifest)
        .map((match) => match.group(1))
        .toList();

    expect(schemes, [redirect.scheme]);
    expect(hosts, [redirect.host]);
  });

  test('local Supabase allows exactly the redirect URL', () {
    final config = read('supabase/config.toml');
    final list = RegExp(r'^additional_redirect_urls\s*=\s*\[(.*?)\]',
            multiLine: true, dotAll: true)
        .firstMatch(config);
    expect(list, isNotNull);
    final urls = RegExp(r'"([^"]*)"')
        .allMatches(list!.group(1)!)
        .map((match) => match.group(1))
        .toList();

    expect(urls, [authRedirectUrl]);
  });

  test('no platform or config file still registers the previous scheme', () {
    for (final path in const [
      'lib/auth/auth_deep_link.dart',
      'ios/Runner/Info.plist',
      'android/app/src/main/AndroidManifest.xml',
      'supabase/config.toml',
    ]) {
      expect(read(path), isNot(contains(previousScheme)), reason: path);
    }
  });
}
