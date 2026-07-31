/// Public workout post persisted in Supabase.
enum PostMediaKind { photo, video }

/// A public workout post and its optional presentation-only author name.
class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.caption,
    required this.mediaUrl,
    required this.mediaKind,
    required this.createdAt,
    this.bodyPart,
    this.location,
    this.sessionId,
    this.volumeKg,
    this.durationMin,
    this.prLabel,
    this.xp,
    this.authorName,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.savedByMe = false,
    this.authorAvatarUrl,
  });

  final String id;
  final String userId;
  final String caption;
  final String mediaUrl;
  final PostMediaKind mediaKind;
  final String? bodyPart;
  final String? location;
  final String? sessionId;
  final double? volumeKg;
  final int? durationMin;
  final String? prLabel;
  final int? xp;
  final DateTime createdAt;
  final String? authorName;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final bool savedByMe;
  final String? authorAvatarUrl;

  /// 저장 후 작성자 이름이나 반응 수를 채워 넣을 때 쓴다.
  Post copyWith({
    String? authorName,
    String? authorAvatarUrl,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
    bool? savedByMe,
  }) => Post(
    id: id,
    userId: userId,
    caption: caption,
    mediaUrl: mediaUrl,
    mediaKind: mediaKind,
    createdAt: createdAt,
    bodyPart: bodyPart,
    location: location,
    sessionId: sessionId,
    volumeKg: volumeKg,
    durationMin: durationMin,
    prLabel: prLabel,
    xp: xp,
    authorName: authorName ?? this.authorName,
    authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    likedByMe: likedByMe ?? this.likedByMe,
    savedByMe: savedByMe ?? this.savedByMe,
  );
}
