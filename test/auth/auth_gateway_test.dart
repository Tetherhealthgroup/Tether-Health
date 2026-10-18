import 'package:breathefree_patient/auth/auth_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('classifies invalid credentials without exposing account existence', () {
    for (final code in [
      'invalid_credentials',
      'user_not_found',
      'invalid_grant',
    ]) {
      final failure = classifyAuthFailure(
        AuthApiException('authentication failed',
            statusCode: '400', code: code),
      );
      expect(failure.reason, AuthFailureReason.invalidCredentials);
    }
  });

  test('classifies actionable Supabase authentication failures', () {
    expect(
      classifyAuthFailure(const AuthApiException(
        'confirmation required',
        statusCode: '400',
        code: 'email_not_confirmed',
      )).reason,
      AuthFailureReason.emailNotConfirmed,
    );
    expect(
      classifyAuthFailure(const AuthApiException(
        'slow down',
        statusCode: '429',
        code: 'over_request_rate_limit',
      )).reason,
      AuthFailureReason.rateLimited,
    );
    expect(
      classifyAuthFailure(const AuthApiException(
        'account unavailable',
        statusCode: '400',
        code: 'user_banned',
      )).reason,
      AuthFailureReason.accountUnavailable,
    );
  });

  test('separates retryable network and server failures', () {
    expect(
      classifyAuthFailure(AuthRetryableFetchException()).reason,
      AuthFailureReason.network,
    );
    expect(
      classifyAuthFailure(
        AuthRetryableFetchException(
          message: 'upstream unavailable',
          statusCode: '503',
        ),
      ).reason,
      AuthFailureReason.serviceUnavailable,
    );
    expect(
      classifyAuthFailure(const AuthApiException(
        'unclassified',
        statusCode: '400',
      )).reason,
      AuthFailureReason.unknown,
    );
  });
}
