import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_init.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/supabase_party_repository.dart';
import '../../../domain/entities/party.dart';
import '../../../domain/entities/party_member.dart';
import '../../../domain/entities/party_message.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/party_repository.dart';
import '../../../domain/entities/party_mission.dart';

final partyRepositoryProvider = Provider<PartyRepository>(
  (ref) => SupabasePartyRepository(ref.watch(supabaseClientProvider)),
);
final myPartiesProvider = FutureProvider<List<Party>>((ref) async {
  final r = await ref.watch(partyRepositoryProvider).fetchMyParties();
  return r.when(ok: (v) => v, err: (e) => throw e);
});
typedef PartyExploreFilter = ({String? region, String? focus});
final partyExploreProvider =
    FutureProvider.family<List<Party>, PartyExploreFilter>((ref, f) async {
      final r = await ref
          .watch(partyRepositoryProvider)
          .explore(region: f.region, focus: f.focus);
      return r.when(ok: (v) => v, err: (e) => throw e);
    });
final partyMembersProvider = FutureProvider.family<List<PartyMember>, String>((
  ref,
  id,
) async {
  final r = await ref.watch(partyRepositoryProvider).fetchMembers(id);
  return r.when(ok: (v) => v, err: (e) => throw e);
});
final partyMessagesProvider = StreamProvider.autoDispose
    .family<List<PartyMessage>, String>((ref, id) {
      final controller = StreamController<List<PartyMessage>>();
      final subscription = ref
          .watch(partyRepositoryProvider)
          .watchMessages(id)
          .listen(
            (result) =>
                result.when(ok: controller.add, err: controller.addError),
            onDone: controller.close,
          );
      ref.onDispose(() {
        unawaited(subscription.cancel());
        if (!controller.isClosed) unawaited(controller.close());
      });
      return controller.stream;
    });
final partyChatControllerProvider = Provider<PartyChatController>(
  PartyChatController.new,
);
final partyFeedProvider = FutureProvider.family<List<Post>, String>((
  ref,
  id,
) async {
  final r = await ref.watch(partyRepositoryProvider).fetchPartyFeed(id);
  return r.when(ok: (v) => v, err: (e) => throw e);
});

/// 파티의 이번 주 미션 현황.
final partyMissionProvider = FutureProvider.family<PartyMission, String>((
  ref,
  partyId,
) async {
  final result = await ref.watch(partyRepositoryProvider).fetchMission(partyId);
  return result.when(ok: (mission) => mission, err: (failure) => throw failure);
});

/// 파티 주간 목표 저장과 미션 새로고침을 한곳에서 처리한다.
final partyGoalControllerProvider = Provider<PartyGoalController>(
  (ref) => PartyGoalController(ref),
);

/// 파티 목표 변경을 저장하는 application 계층 진입점이다.
class PartyGoalController {
  const PartyGoalController(this._ref);

  final Ref _ref;

  /// null이면 인원당 주 3회의 자동 목표로 되돌린다.
  Future<Result<void, Failure>> updateWeeklyGoal(
    String partyId,
    int? goalSessions,
  ) async {
    final result = await _ref
        .read(partyRepositoryProvider)
        .updateWeeklyGoal(partyId, goalSessions);
    if (result.isOk) _ref.invalidate(partyMissionProvider(partyId));
    return result;
  }
}

/// 채팅 전송과 메시지 갱신을 application 계층에서 처리한다.
class PartyChatController {
  const PartyChatController(this._ref);

  final Ref _ref;

  Future<Result<PartyMessage, Failure>> sendMessage(
    String partyId,
    String body,
  ) async {
    final result = await _ref
        .read(partyRepositoryProvider)
        .sendMessage(partyId, body);
    if (result.isOk) _ref.invalidate(partyMessagesProvider(partyId));
    return result;
  }
}
