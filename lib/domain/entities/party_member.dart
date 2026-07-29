class PartyMember {
  const PartyMember({
    required this.userId,
    required this.nickname,
    required this.role,
    required this.joinedAt,
    this.avatarUrl,
  });
  final String userId, nickname, role;
  final String? avatarUrl;
  final DateTime joinedAt;
}
