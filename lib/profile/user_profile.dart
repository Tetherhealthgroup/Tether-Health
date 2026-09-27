class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.locale,
    required this.timeZone,
    required this.onboardingCompleted,
    required this.avatarPath,
    this.avatarUrl,
    this.avatarUrlExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, Object?> json) => UserProfile(
        id: json['id']! as String,
        displayName: json['displayName'] as String?,
        locale: json['locale']! as String,
        timeZone: json['timeZone']! as String,
        onboardingCompleted: json['onboardingCompleted']! as bool,
        avatarPath: json['avatarPath'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        avatarUrlExpiresAt: json['avatarUrlExpiresAt'] == null
            ? null
            : DateTime.parse(json['avatarUrlExpiresAt']! as String),
        createdAt: DateTime.parse(json['createdAt']! as String),
        updatedAt: DateTime.parse(json['updatedAt']! as String),
      );

  final String id;
  final String? displayName;
  final String locale;
  final String timeZone;
  final bool onboardingCompleted;
  final String? avatarPath;
  final String? avatarUrl;
  final DateTime? avatarUrlExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
