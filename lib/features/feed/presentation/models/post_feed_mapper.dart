import 'package:flutter/material.dart';
import 'package:heal_setlog/core/formatting/app_format.dart';
import 'package:heal_setlog/domain/entities/post.dart';

import 'feed_post.dart';

/// Converts persisted posts to the existing feed-card view model.
FeedPost feedPostFromPost(
  Post post, {
  String? currentUserId,
  WeightUnit weightUnit = WeightUnit.kg,
}) => FeedPost(
  postId: post.id,
  authorId: post.userId,
  isMine: currentUserId != null && currentUserId == post.userId,
  author: FeedAuthor(name: post.authorName ?? '회원', level: 1),
  timeLabel: _timeLabel(post.createdAt),
  bodyPart: post.bodyPart ?? '운동',
  location: post.location,
  showFollow: true,
  media: FeedMedia(
    kind: post.mediaKind == PostMediaKind.video
        ? FeedMediaKind.video
        : FeedMediaKind.photo,
    url: post.mediaUrl,
    gradient: const <Color>[Color(0xFFECECEE), Color(0xFFDCDCE0)],
  ),
  summary: WorkoutSummary(
    metrics: <({String label, String value})>[
      if (post.volumeKg != null)
        (
          label: '볼륨',
          value: formatWeightWithUnit(post.volumeKg!, unit: weightUnit),
        ),
      if (post.durationMin != null)
        (label: '시간', value: '${post.durationMin}분'),
    ],
    prLabel: post.prLabel,
    xp: post.xp,
  ),
  likes: post.likeCount,
  comments: post.commentCount,
  likedByMe: post.likedByMe,
  savedByMe: post.savedByMe,
  caption: post.caption,
);

String _timeLabel(DateTime createdAt) {
  final difference = DateTime.now().difference(createdAt);
  if (difference.inMinutes < 1) return '방금';
  if (difference.inHours < 1) return '${difference.inMinutes}분';
  if (difference.inDays < 1) return '${difference.inHours}시간';
  return '${difference.inDays}일';
}
