import 'package:breathefree_patient/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires all account service values together', () {
    const config = AppConfig(
        apiBaseUrl: 'https://api.example.test',
        supabaseUrl: '',
        supabaseAnonKey: '');
    expect(config.hasAnyConfiguration, isTrue);
    expect(config.validate, throwsFormatException);
  });

  test('accepts absolute configured service URLs', () {
    const config = AppConfig(
      apiBaseUrl: 'https://api.example.test',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'public-placeholder',
    );
    expect(() => config.validate(production: true), returnsNormally);
  });

  test('production rejects insecure or placeholder endpoints', () {
    const insecure = AppConfig(
      apiBaseUrl: 'http://api.example.test',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'public-placeholder',
    );
    expect(() => insecure.validate(production: true), throwsFormatException);

    const placeholder = AppConfig(
      apiBaseUrl: 'https://api.example.invalid',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'public-placeholder',
    );
    expect(() => placeholder.validate(production: true), throwsFormatException);
  });

  test('client configuration rejects privileged Supabase keys', () {
    const config = AppConfig(
      apiBaseUrl: 'https://api.example.test',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'sb_secret_must-never-ship',
    );
    expect(() => config.validate(production: true), throwsFormatException);
  });
}
