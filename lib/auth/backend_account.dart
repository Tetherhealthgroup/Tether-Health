// The account controller of the new design's screens over the app's backend
// (the on-device sandbox or the real services): sign-in through the
// backend's auth, the profile through its API client. The same in both
// modes; only the backend differs.
import 'dart:async';

import '../api/tether_api.dart';
import '../backend/backend.dart';
import '../profile/profile_api_client.dart';
import '../profile/profile_repository.dart';
import '../profile/user_profile.dart';
import 'account_controller.dart';

/// [ProfileApiClient] over the backend's transport. The transport adds the
/// signed-in member's token itself, so the token argument is not sent again.
class BackendProfileApiClient implements ProfileApiClient {
  BackendProfileApiClient(BackendTransport transport)
      : _api = AccountApi(transport);

  final AccountApi _api;

  @override
  Future<UserProfile> getProfile(String accessToken) async =>
      _value(await _api.profile());

  /// Sends the fields the profile route takes. A field it does not take
  /// (the profile photo) is refused here rather than dropped silently.
  @override
  Future<UserProfile> updateProfile(
    String accessToken,
    Map<String, Object?> update,
  ) async {
    const known = {'displayName', 'onboardingCompleted', 'locale', 'timeZone'};
    if (update.isEmpty || update.keys.any((key) => !known.contains(key))) {
      throw const ProfileApiException(400);
    }
    final name = update['displayName'];
    return _value(await _api.updateProfile(
      displayName: name is String ? name : null,
      clearDisplayName: update.containsKey('displayName') && name == null,
      onboardingCompleted: update['onboardingCompleted'] as bool?,
      locale: update['locale'] as String?,
      timeZone: update['timeZone'] as String?,
    ));
  }

  /// The profile, or the error the account controller already handles: a
  /// status code, or a timeout when the service was not reached (which it
  /// retries).
  static UserProfile _value(ApiResult<UserProfile> result) => switch (result) {
        ApiSuccess(:final value) => value,
        ApiFailure(:final error) => error.status == 0
            ? throw TimeoutException('unreachable')
            : throw ProfileApiException(error.status),
      };
}

/// The account controller for [backend]: its auth for sign-in, its API for
/// the profile. Account export and deletion go through the save handlers,
/// not through this controller.
AccountController accountControllerFor(Backend backend) => AccountController(
      auth: backend.auth,
      profiles: ProfileRepository(
        auth: backend.auth,
        api: BackendProfileApiClient(backend.transport),
      ),
    );
