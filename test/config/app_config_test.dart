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
    expect(config.validate, returnsNormally);
  });
}
