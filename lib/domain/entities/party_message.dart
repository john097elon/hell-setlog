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
}
