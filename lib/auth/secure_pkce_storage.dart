import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the PKCE code verifier in Keychain/secure platform storage instead of
/// the library's SharedPreferences default.
class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const keyPrefix = 'breathefree.supabase.pkce.';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '$keyPrefix$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$keyPrefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '$keyPrefix$key');
}
