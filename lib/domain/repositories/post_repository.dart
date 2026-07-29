import 'dart:io';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/post.dart';

/// Boundary for public workout post persistence.
abstract class PostRepository {
  Future<Result<List<Post>, Failure>> fetchPublicFeed({
    String? bodyPart,
    int limit = 20,
  });

  Future<Result<Post, Failure>> createPost({
    required File media,
    required bool isVideo,
    required String caption,
    String? bodyPart,
  });

  Future<Result<void, Failure>> toggleLike(String postId);
}
