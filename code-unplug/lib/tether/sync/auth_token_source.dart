/// Joins the app's sign-in to the sync service's bearer token.
///
/// A separate file, and a function rather than a constructor argument on
/// [TetherSyncClient], so the sync layer keeps knowing nothing about Supabase.
/// `TetherSyncClient` takes a `TokenSource`; everything about *where* a token
/// comes from lives here. That is what lets the sync tests run against a fake
/// returning a literal string, and what would let the token come from
/// somewhere else later without touching the client.
library;

import '../../auth/auth_gateway.dart';
import 'sync_client.dart';

/// A [TokenSource] backed by the signed-in Supabase session.
///
/// Asks for a *fresh* token on every call rather than caching one. The cost is
/// a field read and, rarely, a refresh; the alternative is a client holding a
/// token that expired while the app was backgrounded, which is the common case
/// on a phone and fails as an unexplained 401.
TokenSource supabaseTokenSource(AuthGateway auth) => auth.freshAccessToken;

/// The sync client for a signed-in person, or null when nobody is.
///
/// Null rather than a client that always fails: "there is nobody to sync for"
/// is a state the caller should branch on once, at construction, instead of
/// discovering it on every push. A build with no account configured — no
/// dart-defines, which is the ordinary case for a reviewer — lands here too,
/// because [DisabledAuthGateway] has no identity.
TetherSyncClient? syncClientFor(
  AuthGateway auth, {
  required Uri baseUrl,
}) {
  if (auth.currentIdentity == null) return null;
  return TetherSyncClient(
    baseUrl: baseUrl,
    token: supabaseTokenSource(auth),
  );
}
