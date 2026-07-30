import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/post.dart';
import 'package:heal_setlog/domain/entities/post_comment.dart';
import 'package:heal_setlog/domain/repositories/post_repository.dart';
import 'package:heal_setlog/features/auth/application/auth_service.dart';
import 'package:heal_setlog/features/compose/presentation/capture_flow.dart';
import 'package:heal_setlog/features/compose/presentation/compose_page.dart';
import 'package:heal_setlog/features/feed/application/post_providers.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('accepts a caption and publishes the post after persistence', (
    tester,
  ) async {
    String? publishedCaption;
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authServiceProvider.overrideWithValue(const _SignedInAuthService()),
          postRepositoryProvider.overrideWithValue(
            const _SuccessPostRepository(),
          ),
        ],
        child: MaterialApp(
          theme: themeFor(AppThemeId.appleWhite),
          home: Scaffold(
            body: ComposePage(
              media: CapturedMedia(file: XFile('workout.mp4'), isVideo: true),
              onPublished: (caption) => publishedCaption = caption,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('compose-caption')),
      '오늘 운동 완료',
    );
    await tester.ensureVisible(find.byKey(const Key('publish-post')));
    await tester.tap(find.byKey(const Key('publish-post')));
    await tester.pump();
    await tester.pump();

    expect(publishedCaption, '오늘 운동 완료');
    expect(find.text('게시되었습니다'), findsOneWidget);
  });
}

class _SignedInAuthService implements AuthService {
  const _SignedInAuthService();
  @override
  String? get currentUserId => 'user-1';
  @override
  Stream<String?> authStateChanges() => Stream<String?>.value(currentUserId);
  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}
}

class _SuccessPostRepository implements PostRepository {
  const _SuccessPostRepository();
  @override
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
  }) async => Ok(
    Post(
      id: 'post-1',
      userId: 'user-1',
      caption: caption,
      mediaUrl: '',
      mediaKind: isVideo ? PostMediaKind.video : PostMediaKind.photo,
      createdAt: DateTime.now(),
    ),
  );
  @override
  Future<Result<List<Post>, Failure>> fetchPublicFeed({
    String? bodyPart,
    int limit = 20,
  }) async => const Ok(<Post>[]);
  @override
  Future<Result<void, Failure>> toggleLike(String postId) async =>
      const Ok(null);

  @override
  Future<Result<void, Failure>> toggleSave(String postId) async =>
      const Ok(null);

  @override
  Future<Result<List<PostComment>, Failure>> fetchComments(
    String postId,
  ) async => const Ok(<PostComment>[]);

  @override
  Future<Result<PostComment, Failure>> addComment(
    String postId,
    String body,
  ) async => Ok(
    PostComment(
      id: 'comment-1',
      postId: postId,
      userId: 'user-1',
      body: body,
      createdAt: DateTime.now(),
    ),
  );

  @override
  Future<Result<void, Failure>> toggleFollow(String userId) async =>
      const Ok(null);

  @override
  Future<Result<bool, Failure>> isFollowing(String userId) async =>
      const Ok(false);

  @override
  Future<Result<void, Failure>> deletePost(String postId) async =>
      const Ok(null);

  @override
  Future<Result<void, Failure>> reportPost(
    String postId,
    String reason,
  ) async => const Ok(null);

  @override
  Future<Result<void, Failure>> blockUser(String userId) async =>
      const Ok(null);
}
