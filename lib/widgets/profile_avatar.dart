import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProfileIdentity {
  const ProfileIdentity({
    this.signedIn = false,
    this.displayName,
    this.email,
    this.avatarUrl,
  });

  final bool signedIn;
  final String? displayName;
  final String? email;
  final String? avatarUrl;

  String? get preferredName {
    if (!signedIn) return null;
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final address = email?.trim();
    if (address == null || address.isEmpty) return null;
    final localPart = address.split('@').first.trim();
    return localPart.isEmpty ? null : localPart;
  }

  String? get firstName {
    final name = preferredName;
    if (name == null) return null;
    final parts = name
        .split(RegExp(r'[\s._-]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.first;
  }

  String? get initials {
    final name = preferredName;
    if (name == null) return null;
    final parts = name
        .split(RegExp(r'[\s._-]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return '$first$last'.toUpperCase();
  }

  Uri? get usableAvatarUri {
    final value = avatarUrl?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isAbsolute) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return uri;
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.identity,
    this.radius = 23,
    super.key,
  });

  final ProfileIdentity identity;
  final double radius;

  Widget _fallback() {
    final initials = identity.initials;
    if (identity.signedIn && initials != null) {
      return Center(
        child: Text(
          initials,
          key: const ValueKey('profile-avatar-initials'),
          style: TextStyle(
            color: AppColors.deepTeal,
            fontSize: radius * 0.82,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Center(
      child: Icon(
        identity.signedIn
            ? Icons.account_circle_outlined
            : Icons.person_outline_rounded,
        key: const ValueKey('profile-avatar-fallback-icon'),
        color: AppColors.deepTeal,
        size: radius * 1.05,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUri = identity.usableAvatarUri;
    final label = identity.signedIn
        ? 'Profile for ${identity.preferredName ?? 'signed-in user'}'
        : 'Guest profile';
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.deepTeal,
        child: avatarUri == null
            ? _fallback()
            : ClipOval(
                child: Image.network(
                  avatarUri.toString(),
                  key: const ValueKey('profile-avatar-image'),
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                ),
              ),
      ),
    );
  }
}
