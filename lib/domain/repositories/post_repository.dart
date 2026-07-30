import 'dart:io';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/post.dart';
import '../entities/post_comment.dart';

/// Boundary for public workout post persistence.
abstract class PostRepository {
  Future<Result<List<Post>, Failure>> fetchPublicFeed({
    String? bodyPart,
    int limit = 20,
  });

  Future<Result<Post, Failure>> createPost({
    required String caption,
    File? media,
    bool isVideo = false,
    String? bodyPart,
    String? sessionId,
    double? volumeKg,
    int? durationMin,
    String? prLabel,
    int? xp,
  });

  Future<Result<void, Failure>> toggleLike(String postId);
  Future<Result<void, Failure>> toggleSave(String postId);
  Future<Result<List<PostComment>, Failure>> fetchComments(String postId);
  Future<Result<PostComment, Failure>> addComment(String postId, String body);
  Future<Result<void, Failure>> toggleFollow(String userId);
  Future<Result<bool, Failure>> isFollowing(String userId);
  Future<Result<void, Failure>> deletePost(String postId);
  Future<Result<void, Failure>> reportPost(String postId, String reason);
  Future<Result<void, Failure>> blockUser(String userId);
}
