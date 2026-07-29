class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });
  final String id;
  final String postId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
}
