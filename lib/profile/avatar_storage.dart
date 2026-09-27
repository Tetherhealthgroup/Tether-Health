import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AvatarStorage {
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  Future<void> remove(String path);
}

class SupabaseAvatarStorage implements AvatarStorage {
  const SupabaseAvatarStorage(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) =>
      _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

  @override
  Future<void> remove(String path) async {
    await _client.storage.from('avatars').remove([path]);
  }
}

class DisabledAvatarStorage implements AvatarStorage {
  const DisabledAvatarStorage();

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) =>
      Future.error(StateError('Avatar storage is not configured.'));

  @override
  Future<void> remove(String path) =>
      Future.error(StateError('Avatar storage is not configured.'));
}
