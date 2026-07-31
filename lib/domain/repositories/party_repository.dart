import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/party.dart';
import '../entities/party_member.dart';
import '../entities/party_mission.dart';
import '../entities/party_message.dart';
import '../entities/post.dart';

abstract class PartyRepository {
  Future<Result<List<Party>, Failure>> fetchMyParties();
  Future<Result<List<Party>, Failure>> explore({String? region, String? focus});
  Future<Result<Party, Failure>> createParty({
    required String name,
    String? description,
    String? region,
    String? focus,
    required int maxMembers,
    required bool isPublic,
  });
  Future<Result<void, Failure>> joinParty(String partyId);
  Future<Result<void, Failure>> joinByCode(String code);
  Future<Result<void, Failure>> leaveParty(String partyId);
  Future<Result<List<PartyMember>, Failure>> fetchMembers(String partyId);

  /// 파티의 이번 주 미션 현황과 파티원별 기여.
  Future<Result<PartyMission, Failure>> fetchMission(String partyId) =>
      Future<Result<PartyMission, Failure>>.value(
        const Err(DatabaseFailure('미션을 불러올 수 없습니다')),
      );

  /// 끝낸 운동을 내가 속한 파티들에 기록한다. 이미 올린 세션은 무시된다.
  Future<Result<void, Failure>> recordActivity({
    required String sessionId,
    required double volumeKg,
    required int xp,
  }) => Future<Result<void, Failure>>.value(const Ok(null));
  Future<Result<List<PartyMessage>, Failure>> fetchMessages(
    String partyId, {
    int limit = 50,
  });
  Future<Result<PartyMessage, Failure>> sendMessage(
    String partyId,
    String body,
  );
  Future<Result<List<Post>, Failure>> fetchPartyFeed(
    String partyId, {
    int limit = 20,
  });
}
