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

  /// 다른 사용자의 공개 프로필.
  Future<Result<UserProfile, Failure>> fetchProfile(String userId) =>
      Future<Result<UserProfile, Failure>>.value(
        const Err(DatabaseFailure('프로필을 불러올 수 없습니다')),
      );

  /// 다른 사용자의 게시물.
  Future<Result<List<Post>, Failure>> fetchUserPosts(String userId) =>
      Future<Result<List<Post>, Failure>>.value(
        const Err(DatabaseFailure('게시물을 불러올 수 없습니다')),
      );

  /// 팔로워 또는 팔로잉 목록.
  Future<Result<List<UserProfile>, Failure>> fetchFollowList(
    String userId, {
    required bool followers,
  }) => Future<Result<List<UserProfile>, Failure>>.value(
    const Err(DatabaseFailure('목록을 불러올 수 없습니다')),
  );
  Future<Result<({int followers, int following}), Failure>> fetchFollowCounts([
    String? userId,
  ]) => Future<Result<({int followers, int following}), Failure>>.value(
    const Err(DatabaseFailure('팔로워 정보를 불러올 수 없습니다')),
  );
}
