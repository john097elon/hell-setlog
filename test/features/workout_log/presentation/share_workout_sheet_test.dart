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
import 'package:heal_setlog/features/feed/application/post_providers.dart';
import 'package:heal_setlog/features/workout_log/presentation/share_workout_sheet.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('공유 시트가 실제 게시물을 저장하고 안내를 남긴다', (tester) async {
    final repository = _RecordingPostRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          postRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: themeFor(AppThemeId.appleWhite),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showShareWorkoutSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('운동 공유'), findsOneWidget);

    final shareButton = find.byKey(const Key('share-to-feed-button'));
    await tester.ensureVisible(shareButton);
    await tester.tap(shareButton);
    await tester.pumpAndSettle();

    expect(repository.created, 1);
    expect(find.text('피드에 공유했습니다.'), findsOneWidget);
  });
}

class _RecordingPostRepository implements PostRepository {
  int created = 0;

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
  }) async {
    created++;
    return Ok(
      Post(
        id: 'post-1',
        userId: 'user-1',
        caption: caption,
        mediaUrl: '',
        mediaKind: PostMediaKind.photo,
        createdAt: DateTime(2026),
      ),
    );
  }

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
      createdAt: DateTime(2026),
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
