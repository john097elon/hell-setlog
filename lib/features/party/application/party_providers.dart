import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_init.dart';
import '../../../data/repositories/supabase_party_repository.dart';
import '../../../domain/entities/party.dart';
import '../../../domain/entities/party_member.dart';
import '../../../domain/entities/party_message.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/party_repository.dart';

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
final partyMessagesProvider = FutureProvider.family<List<PartyMessage>, String>(
  (ref, id) async {
    final r = await ref.watch(partyRepositoryProvider).fetchMessages(id);
    return r.when(ok: (v) => v, err: (e) => throw e);
  },
);
final partyFeedProvider = FutureProvider.family<List<Post>, String>((
  ref,
  id,
) async {
  final r = await ref.watch(partyRepositoryProvider).fetchPartyFeed(id);
  return r.when(ok: (v) => v, err: (e) => throw e);
});
