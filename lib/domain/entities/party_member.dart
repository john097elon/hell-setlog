import 'character_identity.dart';

/// 파티원. 파티방에서 서로의 캐릭터를 볼 수 있도록 성장 수치를 함께 담는다.
class PartyMember {
  const PartyMember({
    required this.userId,
    required this.nickname,
    required this.role,
    required this.joinedAt,
    this.avatarUrl,
    this.characterName,
    this.characterSpecies,
    this.characterLevel,
    this.characterStage,
  });
  final String userId, nickname, role;
  final String? avatarUrl;
  final DateTime joinedAt;

  /// 아직 캐릭터를 만들지 않았으면 비어 있다.
  final String? characterName;
  final CharacterSpecies? characterSpecies;
  final int? characterLevel;
  final int? characterStage;

  bool get hasCharacter => characterName != null && characterSpecies != null;
}
