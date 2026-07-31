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

  Party copyWith({int? memberCount}) => Party(
    id: id,
    ownerId: ownerId,
    name: name,
    maxMembers: maxMembers,
    isPublic: isPublic,
    createdAt: createdAt,
    description: description,
    region: region,
    focus: focus,
    joinCode: joinCode,
    memberCount: memberCount ?? this.memberCount,
  );
}
