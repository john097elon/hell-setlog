/// Signed-in user's editable public profile.
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.nickname,
    required this.createdAt,
    this.avatarUrl,
    this.bio,
  });

  final String userId;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
}
