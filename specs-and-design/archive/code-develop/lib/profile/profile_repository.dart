import '../auth/auth_gateway.dart';
import 'profile_api_client.dart';
import 'user_profile.dart';

class ProfileRepository {
  const ProfileRepository(
      {required AuthGateway auth, required ProfileApiClient api})
      : _auth = auth,
        _api = api;
  final AuthGateway _auth;
  final ProfileApiClient _api;

  Future<UserProfile> load() => _api.getProfile(_requiredToken());
  Future<UserProfile> update(Map<String, Object?> values) =>
      _api.updateProfile(_requiredToken(), values);

  String _requiredToken() {
    final token = _auth.currentIdentity?.accessToken;
    if (token == null) throw StateError('Authentication is required.');
    return token;
  }
}
