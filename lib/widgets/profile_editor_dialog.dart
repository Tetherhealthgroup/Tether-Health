import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/account_controller.dart';
import 'profile_avatar.dart';

Future<void> showProfileEditorDialog(
  BuildContext context,
  AccountController account, {
  ImagePicker? picker,
}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProfileEditorDialog(
        account: account,
        picker: picker ?? ImagePicker(),
      ),
    );

class ProfileEditorDialog extends StatefulWidget {
  const ProfileEditorDialog({
    required this.account,
    required this.picker,
    super.key,
  });

  final AccountController account;
  final ImagePicker picker;

  @override
  State<ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends State<ProfileEditorDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.account.profile?.displayName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    try {
      final file = await widget.picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (file == null) return;
      if (await file.length() > AccountController.maxAvatarBytes) {
        widget.account.setProfileError(
          'Choose a JPEG, PNG, or WebP image no larger than 5 MB.',
        );
        return;
      }
      final Uint8List bytes = await file.readAsBytes();
      final type = switch (file.mimeType?.toLowerCase()) {
        'image/jpeg' => 'image/jpeg',
        'image/png' => 'image/png',
        'image/webp' => 'image/webp',
        _ when file.name.toLowerCase().endsWith('.png') => 'image/png',
        _ when file.name.toLowerCase().endsWith('.webp') => 'image/webp',
        _ => 'image/jpeg',
      };
      await widget.account.uploadAvatar(bytes: bytes, contentType: type);
    } catch (_) {
      widget.account.setProfileError(
        'The photo picker is unavailable. Try again from this device.',
      );
    }
  }

  Future<void> _save() async {
    if (await widget.account.updateDisplayName(_name.text) && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.account,
      builder: (context, _) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatar(
                identity: ProfileIdentity(
                  signedIn: true,
                  displayName: _name.text,
                  email: widget.account.email,
                  avatarUrl: widget.account.profile?.avatarUrl,
                ),
                radius: 40,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('profile-choose-avatar'),
                    onPressed: widget.account.busy ? null : _choosePhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose photo'),
                  ),
                  if (widget.account.profile?.avatarPath != null)
                    TextButton(
                      key: const ValueKey('profile-remove-avatar'),
                      onPressed: widget.account.busy
                          ? null
                          : widget.account.removeAvatar,
                      child: const Text('Remove photo'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('profile-display-name'),
                controller: _name,
                maxLength: 80,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.account.errorMessage != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    widget.account.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (widget.account.busy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                widget.account.busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('profile-save'),
            onPressed: widget.account.busy ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
