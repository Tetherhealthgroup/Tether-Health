/// The `dart:io` transport. Used on iOS, Android, macOS, Windows and Linux.
library;

import 'dart:convert';
import 'dart:io';

import 'sync_transport.dart';

/// Sends over `HttpClient`, with a timeout on the whole exchange.
///
/// The timeout covers connect, send and read together rather than each
/// separately: from the caller's side "the sync is hanging" is one condition,
/// and three separate budgets add up to a wait nobody chose.
class IoSyncTransport implements SyncTransport {
  IoSyncTransport({Duration timeout = const Duration(seconds: 20)})
      : _timeout = timeout,
        _client = HttpClient() {
    _client.connectionTimeout = timeout;
  }

  final HttpClient _client;
  final Duration _timeout;

  @override
  Future<SyncResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    try {
      final request = await _client.openUrl(method, uri).timeout(_timeout);
      headers.forEach(request.headers.set);
      if (body != null) {
        // Encoded here rather than by `write`, so Content-Length is the byte
        // length of UTF-8 and not the number of code units. They differ the
        // moment somebody writes a note with an accent in it.
        final bytes = utf8.encode(body);
        request.headers.contentLength = bytes.length;
        request.add(bytes);
      }
      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join().timeout(_timeout);
      return SyncResponse(status: response.statusCode, body: text);
    } on Object catch (error) {
      // Every failure to reach a server — DNS, refused, TLS, timeout — is the
      // same situation for the caller: nothing was written, try later. Status
      // 0 says that without pretending to be an HTTP code.
      return SyncResponse(status: 0, body: '$error');
    }
  }

  @override
  void close() => _client.close(force: true);
}
