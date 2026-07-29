import 'dart:io';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../entities/post.dart';
import '../entities/user_profile.dart';

/// Boundary for the signed-in user's profile and posts.
abstract class ProfileRepository {
  Future<Result<UserProfile, Failure>> fetchMyProfile();

  Future<Result<UserProfile, Failure>> updateProfile({
    String? nickname,
    String? bio,
  });

  Future<Result<String, Failure>> uploadAvatar(File image);

  Future<Result<List<Post>, Failure>> fetchMyPosts();
}
