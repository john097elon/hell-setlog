import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../../data/repositories/supabase_profile_repository.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/profile_repository.dart';

/// Provides the signed-in profile persistence boundary.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)),
);

/// Loads the current user's profile.
final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  final result = await ref.watch(profileRepositoryProvider).fetchMyProfile();
  return result.when(ok: (profile) => profile, err: (failure) => throw failure);
});

/// Loads the current user's posts.
final myPostsProvider = FutureProvider<List<Post>>((ref) async {
  final result = await ref.watch(profileRepositoryProvider).fetchMyPosts();
  return result.when(ok: (posts) => posts, err: (failure) => throw failure);
});

/// Loads the current user's social counts from the existing follows table.
final myFollowCountsProvider = FutureProvider<({int followers, int following})>(
  (ref) async {
    final client = ref.watch(supabaseClientProvider);
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return (followers: 0, following: 0);
    final rows = await Future.wait<List>(<Future<List>>[
      client.from('follows').select('follower_id').eq('following_id', userId),
      client.from('follows').select('following_id').eq('follower_id', userId),
    ]);
    return (followers: rows[0].length, following: rows[1].length);
  },
);
