import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/post.dart';
import 'package:heal_setlog/domain/entities/user_profile.dart';
import 'package:heal_setlog/domain/repositories/profile_repository.dart';
import 'package:heal_setlog/features/auth/application/auth_service.dart';
import 'package:heal_setlog/features/profile/application/profile_providers.dart';
import 'package:heal_setlog/features/profile/presentation/my_profile_page.dart';

void main() {
  testWidgets('renders overridden profile nickname and post grid', (
    tester,
  ) async {
    await _pump(tester, posts: <Post>[_post]);

    expect(find.text('테스트 회원'), findsOneWidget);
    expect(find.byType(SliverGrid), findsOneWidget);
  });

  testWidgets('썸네일을 누르면 게시물 상세로 들어가고 반응 수가 보인다', (tester) async {
    await _pump(
      tester,
      posts: <Post>[_post.copyWith(likeCount: 3, commentCount: 2)],
    );

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('post-thumb-post-1')));
    await tester.pumpAndSettle();

    expect(find.text('좋아요'), findsOneWidget);
    expect(find.text('댓글'), findsOneWidget);
  });

  testWidgets('renders empty state when there are no posts', (tester) async {
    await _pump(tester, posts: <Post>[]);

    expect(find.text('게시물이 없습니다'), findsOneWidget);
  });
}

final _profile = UserProfile(
  userId: 'user-1',
  nickname: '테스트 회원',
  bio: '운동 기록',
  createdAt: DateTime(2026),
);

final _post = Post(
  id: 'post-1',
  userId: 'user-1',
  caption: '내 게시물',
  mediaUrl: '',
  mediaKind: PostMediaKind.photo,
  createdAt: DateTime(2026),
);

Future<void> _pump(WidgetTester tester, {required List<Post> posts}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authServiceProvider.overrideWithValue(const _Auth()),
        profileRepositoryProvider.overrideWithValue(const _Repository()),
        myProfileProvider.overrideWith((ref) async => _profile),
        myPostsProvider.overrideWith((ref) async => posts),
      ],
      child: MaterialApp(
        theme: themeFor(AppThemeId.appleWhite),
        home: const MyProfilePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Auth implements AuthService {
  const _Auth();
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

class _Repository implements ProfileRepository {
  const _Repository();
  @override
  Future<Result<UserProfile, Failure>> fetchMyProfile() async => Ok(_profile);
  @override
  Future<Result<List<Post>, Failure>> fetchMyPosts() async =>
      const Ok(<Post>[]);
  @override
  Future<Result<UserProfile, Failure>> updateProfile({
    String? nickname,
    String? bio,
  }) async => Ok(_profile);
  @override
  Future<Result<String, Failure>> uploadAvatar(File image) async =>
      const Ok('');
  @override
  Future<Result<({int followers, int following}), Failure>>
  fetchFollowCounts() async => const Ok((followers: 0, following: 0));
}
