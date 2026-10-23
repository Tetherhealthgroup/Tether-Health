// The http-mode backend: the real API, sync service and Supabase Auth.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../backend.dart';
import 'http_transport.dart';
import 'supabase_auth_backend.dart';

/// [Backend] for `TETHER_BACKEND=http`.
class HttpBackend implements Backend, ConsentDocuments {
  /// [supabase] is read when first needed (Supabase is initialised by the
  /// app before the first request).
  HttpBackend(
    AppConfig config, {
    SupabaseClient Function()? supabase,
    bool release = !kDebugMode,
  }) : this.withAuth(
          config,
          SupabaseAuthBackend(supabase ?? () => Supabase.instance.client),
          release: release,
          supabase: supabase ?? () => Supabase.instance.client,
        );

  /// With a given [auth] (tests).
  HttpBackend.withAuth(
    AppConfig config,
    this.auth, {
    bool release = !kDebugMode,
    SupabaseClient Function()? supabase,
  })  : _supabase = supabase,
        transport = HttpBackendTransport(
          apiBaseUrl: Uri.parse(config.apiBaseUrl),
          syncBaseUrl: Uri.parse(config.syncBaseUrl),
          accessToken: auth.accessToken,
          release: release,
        );

  @override
  BackendMode get mode => BackendMode.http;

  @override
  final AuthBackend auth;

  @override
  final HttpBackendTransport transport;

  /// Nothing of the http backend is stored on the phone: the session is the
  /// auth gateway's and is ended by signing out.
  final SupabaseClient Function()? _supabase;

  /// Reads `public.current_consent_documents()` as the member (the same
  /// function the API checks grants against).
  @override
  Future<Map<String, String>?> currentConsentVersions() async {
    final client = _supabase;
    if (client == null) return null;
    try {
      final rows = await client()
          .rpc<List<dynamic>>('current_consent_documents')
          .select('purpose,locale,version');
      return {
        for (final row in rows)
          '${row['purpose']}/${row['locale']}': '${row['version']}',
      };
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> wipeLocal() async {}
}
