class Party {
  const Party({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.maxMembers,
    required this.isPublic,
    required this.createdAt,
    this.description,
    this.region,
    this.focus,
    this.joinCode,
    this.memberCount = 0,
  });
  final String id, ownerId, name;
  final String? description, region, focus, joinCode;
  final int maxMembers, memberCount;
  final bool isPublic;
  final DateTime createdAt;
}
