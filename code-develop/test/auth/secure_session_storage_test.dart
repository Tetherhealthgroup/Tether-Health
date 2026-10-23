import 'package:breathefree_patient/auth/secure_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists and removes the serialized session through secure storage',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecureSessionStorage();

    expect(await storage.hasAccessToken(), isFalse);
    await storage.persistSession('serialized-session');
    expect(await storage.accessToken(), 'serialized-session');
    expect(await storage.hasAccessToken(), isTrue);

    await storage.removePersistedSession();
    expect(await storage.accessToken(), isNull);
  });
}
