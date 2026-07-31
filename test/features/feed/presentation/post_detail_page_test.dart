import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/post.dart';
import 'package:heal_setlog/domain/entities/post_comment.dart';
import 'package:heal_setlog/domain/entities/post_reaction.dart';
import 'package:heal_setlog/features/feed/application/post_providers.dart';
import 'package:heal_setlog/features/feed/presentation/post_detail_page.dart';

void main() {
  testWidgets('좋아요 누른 사람과 댓글 작성자를 이름으로 보여준다', (tester) async {
    await _pump(
      tester,
      likers: <PostReaction>[
        PostReaction(
          userId: 'u1',
          nickname: '김헬스',
          createdAt: DateTime(2026, 7, 30),
        ),
      ],
      comments: <PostComment>[
        PostComment(
          id: 'c1',
          postId: 'post-1',
          userId: 'u2',
          body: '좋은 기록이네요',
          createdAt: DateTime(2026, 7, 30),
          authorName: '박근육',
        ),
      ],
    );

    expect(find.text('김헬스'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('박근육'), findsOneWidget);
    expect(find.text('좋은 기록이네요'), findsOneWidget);
  });

  testWidgets('반응이 없으면 안내 문구를 보여준다', (tester) async {
    await _pump(tester);

    expect(find.text('아직 반응이 없습니다'), findsOneWidget);
    expect(find.text('첫 댓글을 남겨보세요'), findsOneWidget);
  });

  testWidgets('닉네임이 비어도 렌더된다', (tester) async {
    // 프로필 닉네임이 빈 문자열인 계정이 섞여도 화면이 죽지 않아야 한다.
    await _pump(
      tester,
      likers: <PostReaction>[
        PostReaction(userId: 'u1', nickname: '', createdAt: DateTime(2026)),
      ],
    );

    expect(tester.takeException(), isNull);
  });
}

final _post = Post(
  id: 'post-1',
  userId: 'me',
  caption: '오늘 가슴 끝',
  mediaUrl: '',
  mediaKind: PostMediaKind.photo,
  createdAt: DateTime(2026, 7, 30),
  volumeKg: 2700,
  durationMin: 62,
);

Future<void> _pump(
  WidgetTester tester, {
  List<PostReaction> likers = const <PostReaction>[],
  List<PostComment> comments = const <PostComment>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        postLikersProvider('post-1').overrideWith((_) async => likers),
        postCommentsProvider('post-1').overrideWith((_) async => comments),
      ],
      child: MaterialApp(
        theme: themeFor(AppThemeId.appleWhite),
        home: PostDetailPage(post: _post),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
