/// 게시물에 좋아요를 남긴 사람. 누가 반응했는지 보여줄 때 쓴다.
class PostReaction {
  const PostReaction({
    required this.userId,
    required this.nickname,
    required this.createdAt,
    this.avatarUrl,
  });

  final String userId;
  final String nickname;
  final DateTime createdAt;
  final String? avatarUrl;
}
