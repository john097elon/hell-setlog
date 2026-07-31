import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../../data/repositories/supabase_post_repository.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/post_comment.dart';
import '../../../domain/entities/post_reaction.dart';
import '../../../domain/repositories/post_repository.dart';

/// Provides the remote post boundary, including local-mode failure handling.
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => SupabasePostRepository(ref.watch(supabaseClientProvider)),
);

/// 게시물에 좋아요를 남긴 사람 목록.
final postLikersProvider = FutureProvider.family<List<PostReaction>, String>((
  ref,
  postId,
) async {
  final result = await ref.watch(postRepositoryProvider).fetchLikers(postId);
  return result.when(ok: (items) => items, err: (failure) => throw failure);
});

/// 게시물 댓글 목록.
final postCommentsProvider = FutureProvider.family<List<PostComment>, String>((
  ref,
  postId,
) async {
  final result = await ref.watch(postRepositoryProvider).fetchComments(postId);
  return result.when(ok: (items) => items, err: (failure) => throw failure);
});

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
