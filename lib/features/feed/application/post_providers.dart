import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../../data/repositories/supabase_post_repository.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/post_repository.dart';

/// Provides the remote post boundary, including local-mode failure handling.
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => SupabasePostRepository(ref.watch(supabaseClientProvider)),
);

/// Loads the public feed, optionally narrowed to one body part.
final publicFeedProvider = FutureProvider.family<List<Post>, String?>((
  ref,
  bodyPart,
) async {
  final result = await ref
      .watch(postRepositoryProvider)
      .fetchPublicFeed(bodyPart: bodyPart);
  return result.when(ok: (posts) => posts, err: (failure) => throw failure);
});
