import 'package:supabase_flutter/supabase_flutter.dart';

import 'row_parse.dart';

/// 게시물별 좋아요/댓글 수와 내가 누른 좋아요·저장 여부.
typedef PostReactionCounts = ({
  Map<String, int> likes,
  Map<String, int> comments,
  Set<String> likedByMe,
  Set<String> savedByMe,
});

const PostReactionCounts emptyReactionCounts = (
  likes: <String, int>{},
  comments: <String, int>{},
  likedByMe: <String>{},
  savedByMe: <String>{},
);

/// 목록 화면이 게시물마다 질의하지 않도록 반응 수를 한 번에 모아 온다.
Future<PostReactionCounts> fetchReactionCounts(
  SupabaseClient client,
  List<String> postIds, {
  String? viewerId,
}) async {
  if (postIds.isEmpty) return emptyReactionCounts;
  final responses = await Future.wait<Object?>(<Future<Object?>>[
    client
        .from('post_likes')
        .select('post_id, user_id')
        .inFilter('post_id', postIds),
    client.from('post_comments').select('post_id').inFilter('post_id', postIds),
    if (viewerId != null)
      client
          .from('post_saves')
          .select('post_id')
          .eq('user_id', viewerId)
          .inFilter('post_id', postIds),
  ]);
  final likeRows = rowList(responses[0]);
  final likes = <String, int>{};
  final likedByMe = <String>{};
  for (final row in likeRows) {
    final postId = rowString(row, 'post_id');
    likes[postId] = (likes[postId] ?? 0) + 1;
    if (viewerId != null && rowString(row, 'user_id') == viewerId) {
      likedByMe.add(postId);
    }
  }
  final comments = <String, int>{};
  for (final row in rowList(responses[1])) {
    final postId = rowString(row, 'post_id');
    comments[postId] = (comments[postId] ?? 0) + 1;
  }
  final savedByMe = <String>{
    if (responses.length > 2)
      for (final row in rowList(responses[2])) rowString(row, 'post_id'),
  };
  return (
    likes: likes,
    comments: comments,
    likedByMe: likedByMe,
    savedByMe: savedByMe,
  );
}
