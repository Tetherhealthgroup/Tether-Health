import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_pkce_storage.dart';
import 'secure_session_storage.dart';

/// The only redirect the app gives Supabase for email links. The native
/// runners and `supabase/config.toml` register the same scheme and host.
const authRedirectUrl = 'io.breathefree.patient://login-callback';

final Uri _authRedirect = Uri.parse(authRedirectUrl);

/// Parameters that belong to a session or an error rather than to a PKCE code
/// callback. A link carrying any of them is not processed.
const _nonCodeCallbackParameters = <String>{
  'access_token',
  'refresh_token',
  'provider_token',
  'provider_refresh_token',
  'expires_in',
  'expires_at',
  'token_type',
  'error',
  'error_code',
  'error_description',
};

/// Whether an incoming link is processed as an auth callback.
///
/// Only the exact [authRedirectUrl] scheme and host, with no fragment and
/// exactly one non-empty `code` query parameter, is accepted. The code is then
/// exchanged with the locally stored PKCE verifier.
bool isAuthCallbackUri(Uri uri) {
  if (uri.scheme != _authRedirect.scheme ||
      uri.host != _authRedirect.host ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.hasFragment) {
    return false;
  }
  final codes = uri.queryParametersAll['code'];
  if (codes == null || codes.length != 1 || codes.single.isEmpty) {
    return false;
  }
  return !uri.queryParameters.keys.any(_nonCodeCallbackParameters.contains);
}

/// Auth options passed to `Supabase.initialize`.
FlutterAuthClientOptions breatheFreeAuthClientOptions() =>
    FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: SecureSessionStorage(),
      pkceAsyncStorage: SecurePkceStorage(),
      detectSessionInUri: true,
      detectSessionInUriPredicate: isAuthCallbackUri,
    );
