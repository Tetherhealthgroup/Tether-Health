import 'dart:io';

import 'package:breathefree_patient/auth/auth_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const callback = 'io.breathefree.patient://login-callback';

  test('native runners and Supabase use the same auth callback', () {
    final authGateway = File('lib/auth/auth_gateway.dart').readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    final androidManifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final localConfig = File('supabase/config.toml').readAsStringSync();

    expect(authRedirectUrl, callback);
    expect(authGateway, contains(': authRedirectUrl'));
    expect(authGateway, contains('emailRedirectTo: _emailRedirectTo'));
    expect(iosInfo, contains('<string>io.breathefree.patient</string>'));
    expect(
        androidManifest, contains('android:scheme="io.breathefree.patient"'));
    expect(androidManifest, contains('android:host="login-callback"'));
    expect(localConfig, contains(callback));
  });
}
