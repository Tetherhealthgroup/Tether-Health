/// How a request actually leaves the device.
///
/// An interface with two implementations, chosen at compile time, for one
/// reason: `test/no_third_party_sdks_test.dart` fails the build if a second
/// runtime dependency appears, so there is no `package:http` here and
/// `dart:io`'s `HttpClient` does the work. `dart:io` does not exist on web, and
/// this app compiles for web — so importing it unconditionally would break the
/// build for a platform the sync feature simply does not run on yet.
///
/// The conditional export is the standard answer and is better than a
/// `kIsWeb` branch, which would still have to name `dart:io` in a file the web
/// compiler reads.
library;

export 'sync_transport_stub.dart'
    if (dart.library.io) 'sync_transport_io.dart';

/// One HTTP response, reduced to what the client needs.
class SyncResponse {
  const SyncResponse({required this.status, required this.body});

  /// 0 when the request never reached a server. Treated as transient rather
  /// than as a protocol error — see [SyncException.isTransient].
  final int status;

  final String body;
}

/// Sends one request and waits for the whole response.
///
/// Deliberately not streaming. A bundle is a few kilobytes of one person's
/// programme, and a streaming API here would buy nothing while making the
/// error paths harder to get right.
abstract interface class SyncTransport {
  Future<SyncResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  });

  /// Releases any pooled connections.
  void close();
}
