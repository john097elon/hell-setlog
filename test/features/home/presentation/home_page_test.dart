import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/post.dart';
import 'package:heal_setlog/features/feed/application/post_providers.dart';
import 'package:heal_setlog/features/feed/presentation/widgets/feed_post_card.dart';
import 'package:heal_setlog/features/home/presentation/home_page.dart';

void main() {
  testWidgets('renders overridden public feed data', (tester) async {
    await _pumpHome(tester, <Post>[
      Post(
        id: 'post-1',
        userId: 'user-1',
        caption: '실제 피드 게시물',
        mediaUrl: '',
        mediaKind: PostMediaKind.photo,
        bodyPart: '가슴',
        authorName: '테스트 회원',
        createdAt: DateTime.now(),
      ),
    ]);

    await tester.tap(find.text('공개'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedPostCard), findsOneWidget);
  });

  testWidgets('renders empty state for an empty public feed', (tester) async {
    await _pumpHome(tester, <Post>[]);

    await tester.tap(find.text('공개'));
    await tester.pumpAndSettle();

    expect(find.text('게시물이 없습니다'), findsOneWidget);
  });
}

Future<void> _pumpHome(WidgetTester tester, List<Post> posts) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        publicFeedProvider(null).overrideWith((ref) async => posts),
      ],
      child: MaterialApp(
        theme: themeFor(AppThemeId.appleWhite),
        home: const HomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
