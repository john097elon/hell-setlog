class PartyMessage {
  const PartyMessage({
    required this.id,
    required this.partyId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });
  final String id, partyId, userId, body;
  final DateTime createdAt;
  final String? authorName, authorAvatarUrl;

  PartyMessage withAuthor({String? name, String? avatarUrl}) => PartyMessage(
    id: id,
    partyId: partyId,
    userId: userId,
    body: body,
    createdAt: createdAt,
    authorName: name ?? authorName,
    authorAvatarUrl: avatarUrl ?? authorAvatarUrl,
  );
}
