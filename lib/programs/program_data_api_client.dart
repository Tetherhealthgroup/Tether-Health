import 'dart:convert';

import 'package:http/http.dart' as http;

import 'program.dart';

class ProgramDataDocument {
  const ProgramDataDocument({
    required this.payload,
    required this.revision,
  });
  final Map<String, Object?> payload;
  final int revision;
}

abstract interface class ProgramDataApiClient {
  Future<ProgramDataDocument?> get(String token, ProgramId programId);
  Future<void> put(
    String token,
    ProgramId programId,
    ProgramDataDocument document,
  );
}

class HttpProgramDataApiClient implements ProgramDataApiClient {
  HttpProgramDataApiClient({
    required String baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUri = Uri.parse(baseUrl),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<ProgramDataDocument?> get(String token, ProgramId programId) async {
    final response = await _client.get(
      _baseUri.resolve('/v1/program-data/${programId.slug}'),
      headers: {'authorization': 'Bearer $token'},
    ).timeout(timeout);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw StateError('Program load failed.');
    final json = jsonDecode(response.body) as Map<String, Object?>;
    return ProgramDataDocument(
      payload: (json['payload']! as Map).cast<String, Object?>(),
      revision: json['revision']! as int,
    );
  }

  @override
  Future<void> put(
    String token,
    ProgramId programId,
    ProgramDataDocument document,
  ) async {
    final body = jsonEncode({
      'payload': document.payload,
      'revision': document.revision,
    });
    if (utf8.encode(body).length > 32768) {
      throw StateError('Program data exceeds the storage limit.');
    }
    final response = await _client
        .put(
          _baseUri.resolve('/v1/program-data/${programId.slug}'),
          headers: {
            'authorization': 'Bearer $token',
            'content-type': 'application/json',
          },
          body: body,
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Program save failed.');
    }
  }
}

class DisabledProgramDataApiClient implements ProgramDataApiClient {
  const DisabledProgramDataApiClient();
  @override
  Future<ProgramDataDocument?> get(String token, ProgramId programId) async =>
      null;
  @override
  Future<void> put(
    String token,
    ProgramId programId,
    ProgramDataDocument document,
  ) async {}
}
