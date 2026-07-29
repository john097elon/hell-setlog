import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/party.dart';
import '../entities/party_member.dart';
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
