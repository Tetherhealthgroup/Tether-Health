/// The transport on platforms with no `dart:io` — that is, web.
library;

import 'sync_transport.dart';

/// Refuses, clearly.
///
/// Sync is not wired up for web: `dart:io` is unavailable and the alternative
/// (`package:http` or `dart:html`) is a second runtime dependency that
/// `test/no_third_party_sdks_test.dart` fails the build over. This exists so
/// the app still *compiles* for web, where `SessionStore` already runs in
/// memory and `isDurable` is false — a build with no persistence has nothing
/// to sync anyway.
///
/// It throws rather than silently doing nothing, because a sync that quietly
/// never happens looks exactly like one that is working.
class IoSyncTransport implements SyncTransport {
  IoSyncTransport({Duration timeout = const Duration(seconds: 20)});

  @override
  Future<SyncResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    throw UnsupportedError(
      'Sync needs dart:io and is not available on this platform.',
    );
  }

  @override
  void close() {}
}
